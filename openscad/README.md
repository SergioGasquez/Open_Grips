# OpenSCAD models

Parametric OpenSCAD rebuilds of the fork's printable designs: `prometheus.scad` rebuilds
`../OpenGrips Prometheus v43.step` and `sisyphus.scad` rebuilds `../OpenGrips Sisyphus v27.step`.
Every part (frame, walls, end wall, rollers, pins and post) exports print-ready, for the left or
the right hand, and all of them print in the same material: no metal rods, screws or TPU. The
only extra is the cord through the anchor. Both reproduce their STEP file at the STEP's values
(Prometheus defaults to one measured hand instead, see below), except the STEP files' TPU guard,
which is left out: nothing attaches to it, and the anchor's cord exits are rounded without it.

Requires OpenSCAD 2025 or newer (the Manifold backend; older releases take minutes per part).

## Open in OpenSCAD

Open `prometheus.scad` or `sisyphus.scad`, set the values in the Customizer (Window → Customizer),
pick a `part` and `hand`, render (F6) and export the STL. `part = "assembly"` shows all parts
in place; rendering it takes about a minute.

## Export all parts

```sh
python3 export.py prometheus ../prometheus-fit/examples/right-hand/params.txt --hand right --out my-right-hand
python3 export.py sisyphus --hand left --out sisyphus-left
```

The parameter file is optional and uses the format `../prometheus-fit/measure-hand.html` writes
(`Name = value` lines, `#` comments). The STLs are named like the FreeCAD generator's
(`prometheus_right_frame.stl`, …), so give them their own folder with `--out`.

## Parameters

### Prometheus

Names and meanings match the VarSet of `../Original/OpenGrips_Prometheus.FCStd`; see
`../prometheus-fit/README.md` for how to measure them. The finger defaults (`Height`, `Depth`,
`To_Blocker`) are one measured right hand, recorded at the top of `prometheus.scad` with the v43
values for comparison; the roller and frame sizes are the VarSet's. The frame length follows the middle finger, so its
`Base_M_Height + Base_M_To_Blocker` must be the largest; the model stops with a message if not.
Unlike the FreeCAD model, the ring and middle rails may overlap.

The outer faces of the frame and the end wall carry an engraved `crimpdeq.com` in Inter Bold, as on
the Crimpdeq case; the font is bundled in `fonts/` (SIL Open Font License). The model stops with a
message if the text does not fit between the end wall's post hole and lock.

### Sisyphus

The values of `../Original/OpenGrips_Sisyphus.FCStd`'s VarSet, renamed consistently
(`Base_<F>_height` → `Base_<F>_Height`, `Base_R_diamter` → `Base_R_Diameter`, `I_width` →
`Base_I_Width`, `Base_wall_width` → `Wall_Width`):

| Parameter | Meaning |
|---|---|
| `Base_<F>_Height` | Roller position along the fingers, relative to the pinky |
| `Base_<F>_Blocker` | How far the seat under each roller reaches past its axis (the pinky's stops short of it) |
| `Base_<F>_Diameter`, `Base_<F>_Width` | Roller size; all roller tops are level with the middle roller's |
| `Base_Frame_Height` | Wall length up to the lock slot |

The finger stops and the anchor have no counterpart in the original model and
keep v27's dimensions.

## Printing

The parts export in the orientation `../prometheus-fit/generate.py` uses: frame, walls and
rollers on their pinky-side face with the pole holes vertical, pins on their flat, the post on its
chamfered side. For Prometheus print settings see
`../prometheus-fit/README.md`.

## How faithful

`check_step.py` exports each part at the STEP's own values and compares it with the STEP solid
(run from the repository root; it tessellates the STEP files with FreeCAD's bundled Python):

```sh
uvx --with trimesh --with manifold3d --with scipy --with rtree python openscad/check_step.py
```

Every part is within 0.5% of the STEP volume and within 0.1 mm of its surface at the 95th
percentile, except the Prometheus end wall (0.26 mm) because of its engraving. Known differences:

- Prometheus blocker tips follow the original rule: v43's hand-moved tips sit 0.15–0.38 mm lower.
- Pins are centered in their holes; v43's index pin and v27's ring and index pins are 0.1 mm off.
- Sisyphus: the pinky cradle is approximated by one roller cut.
- Some exports contain a few zero-area triangles where rounded surfaces meet flat ones; slicers
  ignore them.

The comparison is geometric only; fit, strength and comfort still need a test print.
