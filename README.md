Open Grips – Isolated Frictionless Ergonomic Grip Training for FDP and FDS

## Original Project

The restored `Original/` folder contains the original FreeCAD parametric source files and PDF documentation.

### Ease of printing

The original models were not set up for efficient FDM printing. Through the addition of new angled walls and the adjustment of other areas, the prints are now all sufficiently set up for FDM printing with no supports needed.

- The Sisyphus model has been completely redesigned to take on the style of the Prometheus model in terms of assembly and style, allowing simpler printing *and* assembly
- The pins may now be printed
- The pins may be printed horizontally for strength and reduced failures
- The long, structural pin may also be printed horizontally for strength and reduced failures
- The frame pieces may now be printed sideways, without supports
- The chamfers and fillets on both tools have been generally improved for FDM printing

### Additional guard top piece

I've added a top piece to be printed in TPU as a guard for the tools.

### Documentation

You're reading it! There's more work to be done, but the process of modifying the print files still needs some work.

### Simple file modification for each user

One of the core ideas advertised by a company out there is that each user's hand is a little different and requires minute adjustments to get things just right for each person. In practice, we've found this to be not majorly important (exact measurements and adjustments from person to person do not heavily impact the effectiveness of the training), but for major differences in hand/finger sizes it is definitely still relevant.

In the original models, this modification was done using parametric model variables. The Fusion/STEP exports are still useful CAD interchange files, but the restored FreeCAD files in `Original/` are the parametric source for measurement-driven customization.

Until I finish some new tooling for adjusting these files, I'll explain the gist of what we've thought through here:

#### Prometheus

##### Roller Up/Down Offset

The length of the full finger may be used for up/down placement offsets of the rollers. Using the pinky length as "0", you can then calculate the height of the offset of each roller by subtracting the height of the pinky from height of the finger.

So, if your pinky was 60mm:

(Vertical offset of 79mm Ring finger roller pin) = 79mm - 60mm = ~19mm

![Vertical offset example](Images/vertical_offset.png)

##### Roller Forward/Backward Offset

The length of the PIP joint to the DIP joint ("P->D") may be used for forward/backward offsets of the rollers. Using the pinky length as "0", you can then calculate the offset of each roller by subtracting the length of the pinky P->D from the finger P->D.

So, if your pinky P->D was 18.5mm:

(Horizontal offset of a 27mm Ring finger roller pin) = 27mm - 18.5mm = ~8.5mm

![Horizontal offset example](Images/horizontal_offset.png)

##### Roof Height

The length of the DIP joint to the tip of your finger may be used to calculate the height of the roof of each finger roller to achieve an "ideal" angle to maintain.

(Roof Height) = (DIP to Fingertip) / tan(Desired Angle)

Based on our findings, the desired angles are roughly:

Index: 57°
Middle: 60°
Ring: 60°
Pinky: 55°

So, if your Index finger DIP to Fingertip was 28mm:
(Roof Height) = 28 / tan(57) = ~18.18mm

![Roof height example](Images/roof_height.png)

#### Sisyphus

##### Roller Offset

See each "Roller Offset" area above. Apply the same concepts.

##### Roller Diameter

TBD

### Web customizer

This fork includes an experimental customizer in `docs/`. It computes the measurement-driven offsets above and downloads a customized `.FCStd` by patching the original FreeCAD template variables.

The original FreeCAD templates are published under `docs/templates/`, so the customizer does not require a backend or a local file upload. The selected template is fetched and patched locally in your browser. Open the customized `.FCStd` in FreeCAD, recompute if prompted, then export final STL/STEP for the best-quality model.

To publish it, enable GitHub Pages for this repository and choose **Deploy from a branch** → the current branch → `/docs`.
