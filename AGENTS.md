# Open_Grips

User-facing workflows are in `prometheus-fit/README.md` and `openscad/README.md`. This file holds what an
agent needs to change or rerun them.

## Layout

- Jared's and opengrips' files (`Original/`, `Images/`, the STEP files, `README.md`) stay where they are,
  so PRs to `jared` stay small; the root README only links to `prometheus-fit/` and `openscad/`.
- Everything added in this fork lives in `prometheus-fit/` (FreeCAD hand fitting) and `openscad/`
  (OpenSCAD rebuilds of the STEP files).

## Scope

- Hand measuring covers Prometheus only. The STEP/STL files themselves are untouched; `openscad/`
  rebuilds both (Prometheus v43, Sisyphus v27).
- `generate.py` does not make the TPU guard (v43's fits only the default frame); the OpenSCAD model
  derives it from the frame, so it fits any parameters.
- Remotes: `origin` is the user's fork (SergioGasquez, push here), `jared` is its parent
  (Jared-Is-Coding, base for task branches), `upstream` is the original (opengrips). Never push to `jared`
  or `upstream`.

## Files

- `prometheus-fit/measure-hand.html`: photo → parameter text. Formulas live in `measure()`; parameter
  names and defaults match the FreeCAD `VarSet`.
- `prometheus-fit/generate.py`: parameter file → STLs written next to it. Run it with FreeCAD's bundled
  Python (`/Applications/FreeCAD.app/Contents/Resources/bin/python`, FreeCAD 1.1.4); system Python has
  no FreeCAD modules.
- `prometheus-fit/examples/<hand>/`: one hand per folder: `params.txt` (comments record manual
  adjustments), generated STLs and the Bambu Lab A1 project.
- Root `*.stl` files are local exports of the STEP files and are git-ignored.
- `openscad/prometheus.scad`, `openscad/sisyphus.scad`: one model per grip, every part in assembly
  coordinates plus a print pose; `part`/`hand` select the output, the hidden `in_place` skips the pose.
  Shared helpers (extrusion and edge rounding, pins, post, lock slot, bore exit round) are in
  `openscad/common.scad`.
- `openscad/export.py`: all parts of one hand with the system Python (stdlib only); same parameter
  file format as `generate.py`, unknown names rejected.
- `openscad/check_step.py`: compares every part with its STEP solid (run with `uvx`, tessellates with
  FreeCAD's Python).

## Model facts

- `Original/OpenGrips_Prometheus.FCStd` drives everything through `VarSet` (`Base_<I|M|R|P>_<Height|Depth|To_Blocker>`,
  plus diameters, widths and wall sizes). Pinky `Height` and `Depth` are the 0 reference.
- It is a left-hand grip: facing the rollers, the pinky is on the left (low X). Right hand = mirror
  across YZ.
- Placed, finished parts: frame `Body`, rollers `Body001`–`Body004` (I, M, R, P), walls `Cut001`–`Cut003`
  (R, M, I), end wall `Body010`, post `Body011`.
- The file predates FreeCAD 1.x element maps: touch every object before the first recompute.

## Known model failures and how the generator handles them

- Changing the measurements breaks the stored edge references of `Fillet013`, `014`, `015`, `017`
  and `023`. `fix_fillets` reselects edges geometrically, in feature order, recomputing before each
  rule. At default values each rule must return exactly the original edges (except `Fillet023`).
- `Fillet023` (anchor): rounding the anchor end arcs gives an invalid solid once the frame is shallower
  than default, so only the two base edges are rounded.
- `Sketch022` (middle wall) draws the ring and middle pole rails as separate arcs. Overlapping rails
  give a non-manifold wall, so `check_rails` requires a 1 mm gap and the user spreads `M`/`R` heights.
- The original `Frame` already fails `Shape.isValid()` at default values; judge exports by the mesh
  check (single closed manifold solid), not the B-rep flag.
- `fit_pins` swaps the 2.6 mm metal poles for printed pins with the v43 fit: pin Ø3.3 with a 0.2 mm
  flat, holes Ø3.5, roller bore Ø3.8 with 0.5 mm chamfers, 0.2 mm roller side clearance.

## OpenSCAD model facts

- Coordinates as in the FreeCAD models: X along the roller axes (pinky at low X), Y along the
  fingers, Z depth. Sisyphus is shifted so its frame corner is the origin (STEP minus
  [5.965, 8.069, 4.13]).
- Both reproduce their STEP at the defaults. Prometheus: v43 moved the blockers by hand (defaults
  `To_Blocker` 8.8/12.7/13.9/14.2) but kept the frame length of the VarSet blockers, so checks pass
  `-D Base_Frame_Height=104`. Sisyphus: features absent from the original model (finger stops,
  anchor, guard outline, cradle tool offsets) are v27 constants, commented "as in v27".
- Edges rounded by `along_x_rounded` need a keep-sharp profile reaching at least r past the edges to
  keep. Use `round2d` (round joins): `offset(delta)` miters spike through profiles at tangent cusps.
- Unioned pieces must overlap (`eps`), not touch, and cuts must not end on existing faces;
  coincident faces leave internal walls or zero-area slivers. A few slivers remain where rounds meet
  faces tangentially; `check_step.py` drops zero-volume fragments before comparing.
- `render()` wraps every part: without it OpenCSG previews of the frame come out empty.

## Measuring pitfalls

- The ruler distance must match the clicked marks (a 1 cm span entered as 100 mm gives 10× values).
- Camera tilt changes the scale along the photo (~10% seen); use widely spaced ruler marks beside the
  fingers. A ruler lying below the palm reads lengths ~4% long; raise it to palm height.

## Verify after changes

1. At default `VarSet` values, the fillet rules select the original edges and nothing fails to recompute.
2. With the target parameters the generator finishes, and every exported mesh passes its solid check.
3. No placed parts overlap (pairwise `common` volume ≈ 0) and each roller axis sits where its values put it.
4. `uvx ruff check --line-length 120 prometheus-fit/generate.py openscad/*.py`.
5. Load `prometheus-fit/measure-hand.html` in a browser, place all points, confirm no console errors.
6. OpenSCAD changes: `uvx --with trimesh --with manifold3d --with scipy --with rtree python
   openscad/check_step.py` passes (each part within 1% volume and 0.6 mm at p95), and
   `openscad/export.py` for both hands gives one watertight body per STL, resting on z = 0.

Digital checks do not validate fit, strength or comfort; report the test print as pending.

## Rebuilding the Bambu Lab A1 project

There is no script; it was built with the Bambu Studio CLI
(`/Applications/BambuStudio.app/Contents/MacOS/BambuStudio`):

1. Flatten the system presets (merge each `inherits` chain) from
   `BambuStudio.app/Contents/Resources/profiles/BBL`: machine `Bambu Lab A1 0.4 nozzle`, filament
   `Bambu PETG HF @BBL A1`, and process `0.20mm Standard @BBL A1` overridden to `wall_loops 5`,
   `sparse_infill_density 35%`, `sparse_infill_pattern cubic`, `enable_support 0`,
   `curr_bed_type Textured PEI Plate` (the default Cool Plate rejects PETG). Keep `from: system`
   on the machine and filament and set `from: User` only on the renamed process
   (`0.20mm Prometheus @BBL A1`); otherwise the CLI reports the process as incompatible.
2. Import the STLs with `--orient 0 --arrange 1 --export-3mf` (no slicing).
3. In `Metadata/model_settings.config`, add per-object `enable_support 1` / `support_type normal(auto)`
   to the frame and index wall, plus `brim_type outer_only` / `brim_width 5` to the frame.
4. Re-run `--arrange 1 --orient 0` on that 3MF (supports added after arranging collide), then
   `--slice 0` to confirm no conflicts or floating-cantilever warnings. Slicing needs the same
   `--load-settings`/`--load-filaments` again; read `warning_message` in `<outputdir>/result.json`.

Use absolute output paths; the CLI also drops a `result.json` in the working directory, so run it
outside the repository.
