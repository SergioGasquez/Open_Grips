# Native Parametric OpenSCAD Rebuild

This folder contains a native OpenSCAD rebuild driven by the measurement formulas in the project `README.md`.

## Main files

- `prometheus.scad` - main native Prometheus-style parametric model
- `sisyphus.scad` - Sisyphus-style starter using the same measurement-driven offsets
- `params.scad` - measurements, formulas, and global dimensions
- `modules/common.scad` - shared geometry helpers
- `modules/prometheus_modules.scad` - reusable parametric model modules
- `converted/` - triangle/polyhedron conversions from STEP; kept only as reference

## How to use

Open `openscad/prometheus.scad` in OpenSCAD.

At the top, choose:

```scad
HAND = "left";       // "left" or "right"
PART = "frame";      // "frame", "rollers", or "pins"
SHOW_ROLLERS = false; // keep false for frame STL export
SHOW_LABELS = false;  // keep false for clean printable STL
```

Then:

1. Press `F5` to preview.
2. Press `F6` to render.
3. Export STL.

For right hand output, leave:

```scad
MIRROR_RIGHT_HAND = true;
```

## Measurement formulas

From the project README:

- Vertical offset vs pinky = finger full length - pinky full length
- Horizontal offset vs pinky = finger PIP-to-DIP - pinky PIP-to-DIP
- Prometheus roof height = DIP-to-tip / tan(desired angle)

Desired angles:

- Index: 57°
- Middle: 60°
- Ring: 60°
- Pinky: 55°

## Current computed values

### Left

| Finger | Vertical offset | Horizontal offset | Roof height |
|---|---:|---:|---:|
| Index | 13 mm | 5 mm | 16.24 mm |
| Middle | 18 mm | 10 mm | 14.43 mm |
| Ring | 10 mm | 7 mm | 15.59 mm |
| Pinky | 0 mm | 0 mm | 16.80 mm |

### Right

| Finger | Vertical offset | Horizontal offset | Roof height |
|---|---:|---:|---:|
| Index | 11 mm | 4 mm | 15.59 mm |
| Middle | 20 mm | 9 mm | 14.43 mm |
| Ring | 12 mm | 7 mm | 15.01 mm |
| Pinky | 0 mm | 0 mm | 16.80 mm |

## Important note

This is native parametric OpenSCAD geometry, not a mesh conversion. It is intended to be editable and measurement-driven. It is not yet guaranteed to be a 1:1 clone of the original STEP silhouette; use the files in `converted/` as visual references if needed.
