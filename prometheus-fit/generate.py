"""Generate Prometheus STLs fitted to one hand from measure-hand.html output.

Usage:
    /Applications/FreeCAD.app/Contents/Resources/bin/python generate.py PARAMS --hand right

PARAMS holds `Base_<finger>_<param> = <mm>` lines; `#` lines are ignored. The STLs are written
next to it, so each hand keeps its parameters and parts in one folder. The original
FreeCAD model is a left-hand grip (pinky on the left when facing the rollers), so right-hand
parts are mirrored across the YZ plane.

The original rollers spin on cut 3 mm nails; the exported set swaps them for the printed pins of
the Jared-Is-Coding fork (see fit_pins), so every part is printed.
"""

import argparse
import math
import re
import sys
from pathlib import Path

sys.path.append("/Applications/FreeCAD.app/Contents/Resources/lib")
import FreeCAD as App
import MeshPart
import Part

MODEL = Path(__file__).resolve().parent.parent / "Original" / "OpenGrips_Prometheus.FCStd"
MEASURED = {f"Base_{f}_{p}" for f in "IMRP" for p in ("Height", "Depth", "To_Blocker")}
# The original author printed the post 0.2 mm thinner to fit through the walls.
POST_CLEARANCE = 0.2
# Flat wall face kept between the ring and middle pole rails (see check_rails).
MIN_RAIL_GAP = 1.0
# Printed pin fit, as in the fork's Prometheus v43 STEP (mm).
PIN_DIAMETER = 3.3
PIN_FLAT = 0.2  # flat along the pin so it prints lying down
PIN_END_CLEARANCE = 0.1  # to each blind hole bottom
PIN_HOLE_DIAMETER = 3.5
ROLLER_BORE_DIAMETER = 3.8
ROLLER_BORE_CHAMFER = 0.5
ROLLER_SIDE_CLEARANCE = 0.2  # to each wall
TOL = 1e-4

# Output name -> FreeCAD object holding the placed, finished part.
PARTS = {
    "frame": "Body",
    "pinky_roller": "Body004",
    "ring_roller": "Body003",
    "middle_roller": "Body002",
    "index_roller": "Body001",
    "ring_wall": "Cut001",
    "middle_wall": "Cut002",
    "index_wall": "Cut003",
    "end_wall": "Body010",
    "post": "Body011",
}


def read_params(path):
    params = {}
    for line in path.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        match = re.fullmatch(r"(\w+)\s*=\s*(-?[\d.]+)", line)
        if not match:
            raise SystemExit(f"{path}: cannot parse line: {line}")
        params[match[1]] = float(match[2])
    if set(params) != MEASURED:
        raise SystemExit(f"{path}: expected exactly {sorted(MEASURED)}, got {sorted(params)}")
    if params["Base_P_Height"] != 0 or params["Base_P_Depth"] != 0:
        raise SystemExit(f"{path}: pinky Height and Depth are the reference and must be 0")
    return params


def near(a, b):
    return abs(a - b) < TOL


def curve_type(edge):
    return None if edge.Degenerated else edge.Curve.TypeId


def is_line_along(edge, axis):
    b = edge.BoundBox
    across = {"x": (b.YLength, b.ZLength), "z": (b.XLength, b.YLength)}[axis]
    return curve_type(edge) == "Part::GeomLine" and max(across) < TOL


def edge_names(shape, edges):
    return [f"Edge{i}" for i, e in enumerate(shape.Edges, 1) if any(e.isSame(x) for x in edges)]


def expect(edges, count, what):
    if len(edges) != count:
        raise SystemExit(f"{what}: expected {count} edges, found {len(edges)}")
    return edges


def wall_bottom_edges(shape):
    """Front and back bottom edges of a finger wall."""
    y = shape.BoundBox.YMin
    bottom = [e for e in shape.Edges if is_line_along(e, "x") and near(e.BoundBox.YMin, y)]
    back, front = min(e.BoundBox.ZMin for e in bottom), max(e.BoundBox.ZMin for e in bottom)
    return expect([e for e in bottom if near(e.BoundBox.ZMin, back) or near(e.BoundBox.ZMin, front)], 2, "wall bottom")


def circles_across_x(shape, radius, x):
    """Circular edges lying in the plane at `x`, with the given radius."""
    return [
        e
        for e in shape.Edges
        if curve_type(e) == "Part::GeomCircle"
        and e.BoundBox.XLength < TOL
        and near(e.BoundBox.XMin, x)
        and near(e.Curve.Radius, radius)
    ]


def middle_wall_edges(shape, wall_width, ring_rail, face_z):
    """Blocker tip arcs on both sides of the wall plus the rail arc around the ring roller axis.

    Arc slivers behind the wall face (ring roller deeper than the middle one) are not part of
    the rail edge.
    """
    b = shape.BoundBox
    tips = [e for x in (b.XMin, b.XMax) for e in circles_across_x(shape, 2, x) if near(e.BoundBox.ZMax, b.ZMax)]
    (axis_y, axis_z), radius = ring_rail
    rail = [
        e
        for e in circles_across_x(shape, radius, wall_width)
        if near(e.Curve.Center.y, axis_y) and near(e.Curve.Center.z, axis_z) and e.BoundBox.ZMin > face_z - TOL
    ]
    return expect(tips, 2, "middle blocker tips") + expect(rail, 1, "ring rail arc")


def pinky_blocker_edges(shape, y):
    """Underside edges of the pinky blocker, in front of the frame."""
    lines = [e for e in shape.Edges if is_line_along(e, "z") and near(e.BoundBox.YMin, y)]
    front = max(e.BoundBox.ZMax for e in lines)
    return expect([e for e in lines if near(e.BoundBox.ZMax, front)], 2, "pinky blocker")


def anchor_edges(shape, y):
    """Front and back base edges of the anchor.

    The original fillet also rounded the top arc at each anchor end; OCC builds a broken solid
    from those arcs once the frame is shallower than the default, so they stay sharp.
    """
    lines = [e for e in shape.Edges if is_line_along(e, "x") and near(e.BoundBox.YMin, y)]
    longest = max(e.Length for e in lines)
    return expect([e for e in lines if near(e.Length, longest)], 2, "anchor base")


def rail(v, finger):
    """Pole axis (y, z) in wall body coordinates (they start at y = Ext_Wall_Width) and rail radius."""
    diameter = getattr(v, f"Base_{finger}_Diameter")
    y = v.Base_P_Diameter + getattr(v, f"Base_{finger}_Height") - diameter / 2
    z = v.Base_Frame_Depth - getattr(v, f"Base_{finger}_Depth")
    return (y.Value, z.Value), diameter.Value / 3


def check_rails(v):
    """The middle wall sketch (Sketch022) draws the ring and middle rails as separate arcs;
    overlapping rails make a self-intersecting profile and a non-manifold wall."""
    (ring_axis, ring_r), (middle_axis, middle_r) = rail(v, "R"), rail(v, "M")
    gap = math.dist(ring_axis, middle_axis) - ring_r - middle_r
    if gap < MIN_RAIL_GAP:
        raise SystemExit(
            f"ring and middle pole rails are {gap:.1f} mm apart (min {MIN_RAIL_GAP}): "
            f"raise Base_M_Height or lower Base_R_Height by {MIN_RAIL_GAP - gap:.1f} mm in total"
        )


def fix_fillets(doc):
    """Reselect fillet edges whose stored references break when the measurements change.

    Rules run in feature order with a recompute before each one: a failed fillet leaves the
    features after it stale, so a later rule would otherwise read outdated geometry.
    """
    v = doc.getObject("VarSet")  # read inside the rules: derived values update on recompute
    rules = {
        "Fillet013": wall_bottom_edges,
        "Fillet014": lambda s: middle_wall_edges(
            s, v.Wall_Width.Value, rail(v, "R"), (v.Base_Frame_Depth - v.Base_M_Depth).Value
        ),
        "Fillet015": wall_bottom_edges,
        "Fillet017": lambda s: pinky_blocker_edges(
            s, (v.Base_Ext_Wall_Width + v.Base_P_Diameter + v.Base_P_Height + v.Base_P_To_Blocker).Value
        ),
        "Fillet023": lambda s: anchor_edges(s, (v.Base_Frame_Height + v.Base_Ext_Wall_Width).Value),
    }
    for name, rule in rules.items():
        doc.recompute()
        fillet = doc.getObject(name)
        base = fillet.Base[0]
        fillet.Base = (base, edge_names(base.Shape, rule(base.Shape)))


def build(params):
    doc = App.openDocument(str(MODEL))
    # The file predates FreeCAD 1.x element maps; touch everything so it fully recomputes.
    for obj in doc.Objects:
        obj.touch()
    varset = doc.getObject("VarSet")
    for name, value in params.items():
        setattr(varset, name, value)
    doc.recompute()
    check_rails(varset)
    fix_fillets(doc)
    doc.recompute()
    failed = [f"{o.Name}: {o.getStatusString()}" for o in doc.Objects if not o.isValid()]
    if failed:
        raise SystemExit("recompute failed:\n  " + "\n  ".join(failed))
    return doc


def x_cylinder(radius, x0, x1, y, z):
    return Part.makeCylinder(radius, x1 - x0, App.Vector(x0, y, z), App.Vector(1, 0, 0))


def bore_tool(x0, x1, y, z):
    """Roller bore with a 45 degree chamfer at both ends, so the pin enters past elephant foot."""
    r, c = ROLLER_BORE_DIAMETER / 2, ROLLER_BORE_CHAMFER
    tool = x_cylinder(r, x0, x1, y, z)
    for start, direction in ((x0 - c, 1), (x1 + c, -1)):
        cone = Part.makeCone(r + 2 * c, r, 2 * c, App.Vector(start, y, z), App.Vector(direction, 0, 0))
        tool = tool.fuse(cone)
    return tool


def pin(x0, x1, y, z):
    r = PIN_DIAMETER / 2
    flat = Part.makeBox(x1 - x0, PIN_DIAMETER, PIN_FLAT, App.Vector(x0, y - r, z - r))
    return x_cylinder(r, x0, x1, y, z).cut(flat)


def pole_faces(shape, pole_diameter):
    """Cylindrical pole hole faces along X."""
    return [
        f
        for f in shape.Faces
        if f.Surface.TypeId == "Part::GeomCylinder"
        and near(f.Surface.Radius, pole_diameter / 2)
        and near(abs(f.Surface.Axis.x), 1)
    ]


def fit_pins(shapes, pole_diameter):
    """Replace the metal poles with printed pins, in model coordinates.

    Each roller axis passes through a blind pole hole on each side, in the frame or a wall.
    The holes keep their position and depth and widen to fit the pin; the roller bore widens
    further so the roller spins on the pin, and the roller ends clear the walls.
    """
    shapes = dict(shapes)
    for finger in ("pinky", "ring", "middle", "index"):
        roller = shapes[f"{finger}_roller"]
        bore = pole_faces(roller, pole_diameter)
        if len(bore) != 1:
            raise SystemExit(f"{finger} roller: expected 1 pole bore, found {len(bore)}")
        y, z = bore[0].Surface.Center.y, bore[0].Surface.Center.z
        holes = [
            f
            for name, shape in shapes.items()
            if not name.endswith("_roller")
            for f in pole_faces(shape, pole_diameter)
            if near(f.Surface.Center.y, y) and near(f.Surface.Center.z, z)
        ]
        if len(holes) != 2:
            raise SystemExit(f"{finger} pole: expected 2 wall holes, found {len(holes)}")
        # BoundBox is loose around curved faces (see print_pose); the optimal box is exact.
        x0 = min(f.optimalBoundingBox().XMin for f in holes)
        x1 = max(f.optimalBoundingBox().XMax for f in holes)
        hole = x_cylinder(PIN_HOLE_DIAMETER / 2, x0, x1, y, z)
        for name, shape in shapes.items():
            if any(f.isSame(h) for f in shape.Faces for h in holes):
                shapes[name] = shape.cut(hole)
        b = roller.optimalBoundingBox()
        keep = App.Vector(b.XMin + ROLLER_SIDE_CLEARANCE, b.YMin - 1, b.ZMin - 1)
        sides = Part.makeBox(b.XLength - 2 * ROLLER_SIDE_CLEARANCE, b.YLength + 2, b.ZLength + 2, keep)
        shapes[f"{finger}_roller"] = roller.common(sides).cut(bore_tool(b.XMin, b.XMax, y, z))
        shapes[f"{finger}_pin"] = pin(x0 + PIN_END_CLEARANCE, x1 - PIN_END_CLEARANCE, y, z)
    return shapes


def print_pose(name, shape, hand):
    """Pole holes vertical (as the original author printed) on the pinky-side end face, which
    has the most bed contact and least overhang for every part; post lying flat; pins lying on
    their flat, as the fork prints them for strength. Placed with the optimal bounding box, as
    BoundBox is loose around fillets and would float parts above the bed at z=0."""
    shape = shape.copy()
    if name == "post":
        shape = shape.makeOffsetShape(-POST_CLEARANCE / 2, TOL)
    elif not name.endswith("_pin"):
        # Pole axis X -> Z with the pinky side down: it is the low-X side, or high-X once mirrored.
        shape.rotate(App.Vector(), App.Vector(0, 1, 0), 90 if hand == "right" else -90)
    b = shape.optimalBoundingBox()
    shape.translate(App.Vector(-b.Center.x, -b.Center.y, -b.ZMin))
    return shape


def export(doc, hand, out_dir):
    shapes = {name: doc.getObject(obj_name).Shape for name, obj_name in PARTS.items()}
    for name, shape in fit_pins(shapes, doc.getObject("VarSet").Base_Pole_Diameter.Value).items():
        if len(shape.Solids) != 1:
            raise SystemExit(f"{name}: expected one solid, got {len(shape.Solids)}")
        if hand == "right":
            shape = shape.mirror(App.Vector(), App.Vector(1, 0, 0))
        shape = print_pose(name, shape, hand)
        mesh = MeshPart.meshFromShape(Shape=shape, LinearDeflection=0.01, AngularDeflection=0.1, Relative=False)
        if not mesh.isSolid() or mesh.hasNonManifolds() or mesh.countComponents() != 1:
            raise SystemExit(f"{name}: mesh is not a single closed manifold solid")
        path = out_dir / f"prometheus_{hand}_{name}.stl"
        mesh.write(str(path))
        print(f"{path.name}: {shape.Volume / 1000:.1f} cm3, {mesh.CountFacets} facets")


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("params", type=Path)
    parser.add_argument("--hand", choices=("left", "right"), required=True)
    args = parser.parse_args()
    export(build(read_params(args.params)), args.hand, args.params.parent)


if __name__ == "__main__":
    main()
