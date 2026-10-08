"""Compare every part of the OpenSCAD models with the fork's STEP files they rebuild.

Usage (from the repository root):
    uvx --with trimesh --with manifold3d --with scipy --with rtree python openscad/check_step.py [prometheus|sisyphus]

FreeCAD's bundled Python tessellates the STEP solids; each OpenSCAD part is exported in assembly
coordinates (in_place) at the STEP's own values, and the script reports its volume difference
and the distance from its surface to the STEP part's. It fails if a part drifts beyond the
tolerances below.
"""

import os
import subprocess
import sys
import tempfile
from pathlib import Path

import numpy as np
import trimesh

ROOT = Path(__file__).resolve().parent.parent
FREECAD_PYTHON = "/Applications/FreeCAD.app/Contents/Resources/bin/python"
# Solid order in both STEP files: frame, then roller, pin and wall per finger, end wall, post (the
# TPU guard, solid 14, is not rebuilt).
SOLIDS = {
    "frame": 0,
    "pinky_roller": 1,
    "pinky_pin": 2,
    "ring_wall": 3,
    "ring_roller": 4,
    "ring_pin": 5,
    "middle_wall": 6,
    "middle_roller": 7,
    "middle_pin": 8,
    "index_wall": 9,
    "index_roller": 10,
    "index_pin": 11,
    "end_wall": 12,
    "post": 13,
}
MODELS = {
    # v43's values; it moved the blockers by hand but kept the frame length of the original blocker
    # positions.
    "prometheus": {
        "step": "OpenGrips Prometheus v43.step",
        "defines": [
            f"-DBase_{finger}_{name}={value}"
            for name, values in (("Height", (23, 32, 15)), ("Depth", (8, 12, 12)), ("To_Blocker", (14.2, 13.9, 12.7)))
            for finger, value in zip("IMR", values)
        ]
        + ["-DBase_P_To_Blocker=8.8", "-DBase_Frame_Height=104"],
        "offset": [0, 0, 0],
        "solids": SOLIDS,
    },
    # v27 also holds an all-round copy of the post (13); the printable, chamfered one is 15.
    "sisyphus": {
        "step": "OpenGrips Sisyphus v27.step",
        "defines": [],
        "offset": [-5.965, -8.069, -4.13],
        "solids": SOLIDS | {"post": 15},
    },
}
MAX_VOLUME_DIFF = 1.0  # %
MAX_P95 = 0.6  # mm

TESSELLATE = """
import sys
sys.path.append("/Applications/FreeCAD.app/Contents/Resources/lib")
import FreeCAD, MeshPart, Part  # FreeCAD first: MeshPart alone crashes
shape = Part.Shape()
shape.read(sys.argv[1])
for i, solid in enumerate(shape.Solids):
    mesh = MeshPart.meshFromShape(Shape=solid, LinearDeflection=0.02, AngularDeflection=0.1, Relative=False)
    mesh.write(f"{sys.argv[2]}/{i}.stl")
"""


def without_slivers(mesh):
    """Drop zero-volume fragments (coincident faces left by booleans) that would break the comparison."""
    return trimesh.util.concatenate([b for b in mesh.split(only_watertight=False) if abs(b.volume) >= 1e-3])


def compare(mine, ref):
    sample = mine.sample(20000)
    _, dist, _ = trimesh.proximity.closest_point(ref, sample)
    return 100 * (mine.volume / ref.volume - 1), np.percentile(dist, 95), np.percentile(dist, 99), dist.max()


def check(name, model, tmp):
    step_dir = tmp / f"{name}_step"
    step_dir.mkdir()
    # FreeCAD's interpreter must not see this script's virtualenv.
    env = {k: v for k, v in os.environ.items() if k not in ("VIRTUAL_ENV", "PYTHONHOME", "PYTHONPATH")}
    subprocess.run(
        [FREECAD_PYTHON, "-c", TESSELLATE, str(ROOT / model["step"]), str(step_dir)],
        check=True,
        capture_output=True,
        env=env,
    )
    failed = []
    print(f"{name}: part, volume %, p95 / p99 / max surface distance (mm)")
    for part, solid in model["solids"].items():
        path = tmp / f"{name}_{part}.stl"
        subprocess.run(
            [
                "openscad",
                "--backend",
                "Manifold",
                "-o",
                str(path),
                f'-Dpart="{part}"',
                "-Din_place=true",
                *model["defines"],
                str(ROOT / "openscad" / f"{name}.scad"),
            ],
            check=True,
            capture_output=True,
        )
        ref = trimesh.load(step_dir / f"{solid}.stl")
        ref.apply_translation(model["offset"])
        volume, p95, p99, worst = compare(without_slivers(trimesh.load(path)), ref)
        ok = abs(volume) <= MAX_VOLUME_DIFF and p95 <= MAX_P95
        failed += [] if ok else [part]
        print(f"  {part:14s} {volume:+6.2f}  {p95:.3f} / {p99:.3f} / {worst:.3f}{'' if ok else '  FAIL'}")
    return failed


def main():
    names = sys.argv[1:] or list(MODELS)
    with tempfile.TemporaryDirectory() as tmp:
        failed = [f"{name} {part}" for name in names for part in check(name, MODELS[name], Path(tmp))]
    if failed:
        sys.exit("beyond tolerance: " + ", ".join(failed))


if __name__ == "__main__":
    main()
