// OpenGrips native parametric model parameters
// Units: millimeters

// Finger order used everywhere: index, middle, ring, pinky
FINGER_NAMES = ["Index", "Middle", "Ring", "Pinky"];
FINGER_ANGLES = [57, 60, 60, 55];

// Measurement arrays are [Full finger length, PIP-to-DIP, DIP-to-tip]
LEFT_MEASUREMENTS = [
  [73, 23, 25],
  [78, 28, 25],
  [70, 25, 27],
  [60, 18, 24]
];

RIGHT_MEASUREMENTS = [
  [71, 22, 24],
  [80, 27, 25],
  [72, 25, 26],
  [60, 18, 24]
];

function measurements(hand) = hand == "right" ? RIGHT_MEASUREMENTS : LEFT_MEASUREMENTS;
function finger_full(hand, i) = measurements(hand)[i][0];
function finger_pip_dip(hand, i) = measurements(hand)[i][1];
function finger_dip_tip(hand, i) = measurements(hand)[i][2];

// README formulas
function vertical_offset(hand, i) = i == 3 ? 0 : finger_full(hand, i) - finger_full(hand, 3);
function horizontal_offset(hand, i) = i == 3 ? 0 : finger_pip_dip(hand, i) - finger_pip_dip(hand, 3);
function roof_height(hand, i) = finger_dip_tip(hand, i) / tan(FINGER_ANGLES[i]);

function vertical_offsets(hand) = [for (i = [0:3]) vertical_offset(hand, i)];
function horizontal_offsets(hand) = [for (i = [0:3]) horizontal_offset(hand, i)];
function roof_heights(hand) = [for (i = [0:3]) roof_height(hand, i)];

// Global model parameters
finger_spacing = 22;
finger_channel_width = 14;
finger_station_depth = 30;
wall_thickness = 4;
base_thickness = 7;
base_margin_x = 18;
base_margin_y = 18;
corner_radius = 4;
eps = 0.05; // tiny overlap to make unions robust for STL export

// Roller / pin geometry
roller_diameter = 10;
roller_length = 12;
pin_diameter = 4;
pin_clearance = 0.35;
pin_hole_diameter = pin_diameter + pin_clearance;
roller_center_z = base_thickness + roller_diameter / 2 + 3;
roller_center_y = 0;

// Roof / guard geometry
roof_thickness = 4;
roof_depth = 16;
roof_overhang_y = 4;
roof_support_width = wall_thickness;
roof_support_extra_height = 8;

// Optional preview helpers
show_rollers_default = true;
show_pin_axes_default = false;
$fn = 64;
