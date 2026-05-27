include <params.scad>
include <modules/prometheus_modules.scad>

// Native parametric Sisyphus-style starter.
// README says Sisyphus uses the same roller offset concepts as Prometheus.
// This keeps the same measurement-driven stations but uses a longer base and
// hides preview rollers by default for easier body export.

HAND = "left";                 // "left" or "right"
SHOW_ROLLERS = false;
SHOW_PIN_AXES = false;
SHOW_LABELS = true;
MIRROR_RIGHT_HAND = true;

scale([1.08, 1.18, 1])
  prometheus_frame(
    hand = HAND,
    mirror_for_right = MIRROR_RIGHT_HAND,
    show_rollers = SHOW_ROLLERS,
    show_pin_axes = SHOW_PIN_AXES,
    show_labels = SHOW_LABELS
  );

echo("Sisyphus-style uses same offsets from README");
echo("HAND", HAND);
echo("vertical_offsets", vertical_offsets(HAND));
echo("horizontal_offsets", horizontal_offsets(HAND));
echo("roof_heights", roof_heights(HAND));
