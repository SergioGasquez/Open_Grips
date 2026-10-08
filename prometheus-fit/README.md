# Fitting Prometheus to your hand

The original FreeCAD model (`../Original/OpenGrips_Prometheus.FCStd`) is still parametric. Two tools drive
it from a photo of your hand and export print-ready STLs. Only Prometheus is covered; Sisyphus is unchanged.

## 1. Measure

Open `measure-hand.html` in Chrome or Safari (single file, nothing to install).

- Photo: palm up, fingers straight and slightly apart, a millimetre ruler beside the fingers raised to
  palm height (e.g. on a book), phone parallel to the table and above the fingers. Use the original
  full-resolution JPEG or PNG, not a screenshot.
- Enter the distance between two ruler marks far apart (e.g. 0 and 10 cm = 100 mm) and click them.
- For each finger, from index to pinky, click the base crease, middle joint (PIP) crease, end joint
  (DIP) crease and fingertip. Scroll to zoom, drag to pan or move a point.
- Copy the text block into `params.txt` in a new folder, e.g. `examples/my-right-hand/params.txt`.

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
/Applications/FreeCAD.app/Contents/Resources/bin/python generate.py examples/right-hand/params.txt --hand right
```

This writes one STL per part next to `params.txt`, already oriented for printing. The original model is a
left-hand grip; `--hand right` mirrors it. The metal rods of the original are replaced by printed pins
sized like the fork's v43 pins. Parts: frame, ring/middle/index walls, end wall, four rollers, four pins
and the post.

If the ring and middle rollers end up too close, the generator stops and says how much to raise
`Base_M_Height` or lower `Base_R_Height`; split the difference between the two.

`examples/right-hand/` is one person's right hand, as an example.

## 3. Print

All parts in PETG (HF), 0.2 mm layers, 5 walls, 35% cubic infill, textured PEI plate. Enable supports
only for the frame (add a 5 mm brim, it stands 111 mm tall) and the index wall. Pins print lying on
their flat side. `examples/right-hand/prometheus_right_A1.3mf` is a Bambu Lab A1 project with these
settings; rebuild it whenever the STLs change (see `../AGENTS.md`).

Assemble as in `../Original/Open_Grips.pdf` section 3.2: place a roller, insert its pin, slide the next
wall onto the rails, repeat, add the end wall and push the post through the side hole.

The fit has only been checked digitally; adjust the values after a test print.
