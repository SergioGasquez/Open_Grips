include <params.scad>
include <modules/prometheus_modules.scad>

// Native parametric Prometheus-style OpenGrips model
// Change these values, then press F5/F6 in OpenSCAD.

HAND = "left";                 // "left" or "right"
PART = "frame";                // "frame", "rollers", or "pins"
SHOW_ROLLERS = false;          // set true only for visual preview
SHOW_PIN_AXES = false;         // debug pin-hole center axes
SHOW_LABELS = false;           // set true only for visual preview
MIRROR_RIGHT_HAND = true;

if (PART == "frame") {
  prometheus_frame(
    hand = HAND,
    mirror_for_right = MIRROR_RIGHT_HAND,
    show_rollers = SHOW_ROLLERS,
    show_pin_axes = SHOW_PIN_AXES,
    show_labels = SHOW_LABELS
  );
} else if (PART == "rollers") {
  prometheus_rollers(hand = HAND);
} else if (PART == "pins") {
  prometheus_pins(hand = HAND);
}

// Useful computed values printed to OpenSCAD console
// Index, Middle, Ring, Pinky
echo("HAND", HAND);
echo("vertical_offsets", vertical_offsets(HAND));
echo("horizontal_offsets", horizontal_offsets(HAND));
echo("roof_heights", roof_heights(HAND));
