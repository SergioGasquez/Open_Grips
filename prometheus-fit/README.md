# Fitting Prometheus to your hand

The original FreeCAD model (`../Original/OpenGrips_Prometheus.FCStd`) is still parametric. Two tools drive
it from a photo of your hand and export print-ready STLs. Only Prometheus is covered; Sisyphus is unchanged.

## 1. Measure

Open `measure-hand.html` in Chrome or Safari (single file, nothing to install).

- Hands: measure one hand and use it for both (the values do not depend on which hand the photo shows),
  or measure each hand from its own photo, switching between them with the Left/Right buttons.
- Photo: palm up, fingers straight and slightly apart, a millimetre ruler beside the fingers raised to
  palm height (e.g. on a book), phone parallel to the table and above the fingers. Use the original
  full-resolution JPEG or PNG, not a screenshot.
- Enter the distance between two ruler marks far apart (e.g. 0 and 10 cm = 100 mm) and click them.
- For each finger, from index to pinky, click the base crease, middle joint (PIP) crease, end joint
  (DIP) crease and fingertip. Scroll to zoom, drag to pan or move a point.
- Copy the text block into `params.txt` in a new folder, e.g. `examples/my-right-hand/params.txt`; when
  measuring each hand, one folder per hand. Its first line says which `--hand` to export it with.

The page sets three values per finger, relative to the pinky:

| Value | Meaning | Computed from |
|---|---|---|
| `Height` | Roller up/down | Fingertip position in the claw grip from `../Original/Open_Grips.pdf` (proximal phalanx vertical, PIP and DIP flexed 55°), including how far each base crease sits along the hand |
| `Depth` | Roller forward/backward | Same claw grip, front-to-back fingertip position |
| `To_Blocker` | Roof height | `DIP→tip / tan(angle)`, with the angles from the [main README](../README.md#roof-height) |

`Height` deliberately differs from the "full finger length minus pinky length" rule in the
[main README](../README.md#roller-updown-offset): that rule ignores that the pinky starts lower on the
hand, which put the rollers 8–14 mm too low on the example hand.

## 2. Generate

With FreeCAD 1.1 installed, from this folder:

```sh
/Applications/FreeCAD.app/Contents/Resources/bin/python generate.py examples/my-right-hand/params.txt --hand right
```

This writes one STL per part next to `params.txt`, already oriented for printing. The original model is a
left-hand grip; `--hand right` mirrors it. The metal rods of the original are replaced by printed pins
sized like the fork's v43 pins. Parts: frame, ring/middle/index walls, end wall, four rollers, four pins
and the post.

If the ring and middle rollers end up too close, the generator stops and says how much to raise
`Base_M_Height` or lower `Base_R_Height`; split the difference between the two.

The same `params.txt` also drives the OpenSCAD rebuild of the fork's v43 design, without FreeCAD and
without the rail limit: see [`../openscad/`](../openscad/README.md).

`examples/right-hand/` is one person's right hand, as an example. `examples/left-hand/` uses the same
values, mirrored for the left hand, since that hand was not measured. Their ring and middle rails overlap,
so their STLs come from the OpenSCAD model:

```sh
python3 ../openscad/export.py prometheus examples/right-hand/params.txt --hand right
python3 ../openscad/export.py prometheus examples/left-hand/params.txt --hand left
```

## 3. Print

All parts in PETG (HF), 0.2 mm layers, 5 walls, 35% cubic infill, textured PEI plate. Enable supports
only for the frame and the index wall. Add a 5 mm brim to the frame (it stands 111 mm tall) and to the
ring, middle and index walls: without one, a wall can lift on its first layers and the rest of it
prints as spaghetti. Wash the plate with dish soap before printing. Pins print lying on their flat
side. `examples/right-hand/prometheus_right_A1.3mf` and `examples/left-hand/prometheus_left_A1.3mf` are
Bambu Lab A1 projects with these settings; rebuild them whenever the STLs change (see `../AGENTS.md`).

## 4. Assemble

Follow the illustrated steps in [`assembly/`](assembly/src/README.md), an mdBook (`mdbook serve assembly`
to read it in a browser).

The fit has only been checked digitally; adjust the values after a test print.
