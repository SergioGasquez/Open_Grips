include <../params.scad>
include <common.scad>

function station_x(i) = (i - 1.5) * finger_spacing;
function base_width() = (3 * finger_spacing) + finger_channel_width + (2 * wall_thickness) + (2 * base_margin_x);
function base_depth(hand) = finger_station_depth + max(horizontal_offsets(hand)) + (2 * base_margin_y);
function station_roller_center(hand, i) = [
  station_x(i),
  roller_center_y + horizontal_offset(hand, i),
  roller_center_z + vertical_offset(hand, i)
];
function station_roof_z(hand, i) = station_roller_center(hand, i)[2] + roof_height(hand, i);
function station_total_height(hand, i) = station_roof_z(hand, i) + roof_thickness + roof_support_extra_height;
function max_station_height(hand) = max([for (i = [0:3]) station_total_height(hand, i)]);

module prometheus_base(hand = "left") {
  bw = base_width();
  bd = base_depth(hand);
  translate([-bw / 2, -bd / 2, 0])
    rounded_box([bw, bd, base_thickness], r = corner_radius);
}

module roller_preview(center, color_name = "silver") {
  color(color_name)
    translate(center)
      x_cylinder(d = roller_diameter, h = roller_length);
}

module pin_axis_preview(center) {
  color("red", 0.45)
    translate(center)
      x_cylinder(d = pin_diameter, h = finger_channel_width + 2 * wall_thickness + 8);
}

module finger_station(hand = "left", i = 0) {
  c = station_roller_center(hand, i);
  x = c[0];
  y = c[1];
  z = c[2];
  roof_z = station_roof_z(hand, i);
  total_h = station_total_height(hand, i);
  station_w = finger_channel_width + 2 * wall_thickness;
  side_h = total_h - base_thickness;

  difference() {
    union() {
      // Left cheek
      translate([x - station_w / 2, y - finger_station_depth / 2, base_thickness - eps])
        rounded_box([wall_thickness, finger_station_depth, side_h + eps], r = 1.5);

      // Right cheek
      translate([x + station_w / 2 - wall_thickness, y - finger_station_depth / 2, base_thickness - eps])
        rounded_box([wall_thickness, finger_station_depth, side_h + eps], r = 1.5);

      // Rear bridge behind finger channel
      translate([x - station_w / 2, y + finger_station_depth / 2 - wall_thickness, base_thickness - eps])
        rounded_box([station_w, wall_thickness, side_h + eps], r = 1.5);

      // Roof/angle guard: its underside is the computed roof height above roller center
      translate([x - station_w / 2, y - finger_station_depth / 2 - roof_overhang_y, roof_z])
        rounded_box([station_w, roof_depth, roof_thickness], r = 1.5);

      // Small front tie bar on base for rigidity
      translate([x - station_w / 2, y - finger_station_depth / 2, base_thickness - eps])
        rounded_box([station_w, wall_thickness, wall_thickness + eps], r = 1.2);
    }

    // Roller / pin through-hole
    translate(c)
      x_cylinder(d = pin_hole_diameter, h = station_w + 4);

    // Finger clearance channel, open through the station body
    translate([x - finger_channel_width / 2, y - finger_station_depth / 2 - 1, base_thickness + wall_thickness])
      cube([finger_channel_width, finger_station_depth + 2, side_h + 2]);
  }
}

module prometheus_frame(
  hand = "left",
  mirror_for_right = true,
  show_rollers = show_rollers_default,
  show_pin_axes = show_pin_axes_default,
  show_labels = true
) {
  module core() {
    prometheus_base(hand);

    for (i = [0:3]) {
      finger_station(hand, i);

      if (show_rollers)
        roller_preview(station_roller_center(hand, i));

      if (show_pin_axes)
        pin_axis_preview(station_roller_center(hand, i));

      if (show_labels)
        translate([station_x(i), -base_depth(hand) / 2 + 6, base_thickness + 0.2])
          color("black") label_text(FINGER_NAMES[i], size = 3.5, height = 0.5);
    }
  }

  if (hand == "right" && mirror_for_right)
    mirror([1, 0, 0]) core();
  else
    core();
}

module prometheus_rollers(hand = "left") {
  // Printable roller layout on the build plate
  for (i = [0:3])
    translate([0, i * (roller_diameter + 5), roller_diameter / 2])
      x_cylinder(d = roller_diameter, h = roller_length);
}

module prometheus_pins(hand = "left") {
  // Printable pin layout on the build plate
  pin_len = finger_channel_width + 2 * wall_thickness + 2;
  for (i = [0:3])
    translate([0, i * (pin_diameter + 5), pin_diameter / 2])
      x_cylinder(d = pin_diameter, h = pin_len);
}
