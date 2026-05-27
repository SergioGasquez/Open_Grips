// Common native OpenSCAD helper modules

module rounded_rect_2d(w, d, r) {
  hull() {
    translate([r, r]) circle(r = r);
    translate([w - r, r]) circle(r = r);
    translate([r, d - r]) circle(r = r);
    translate([w - r, d - r]) circle(r = r);
  }
}

module rounded_box(size = [10, 10, 10], r = 2, center = false) {
  translate(center ? [-size[0] / 2, -size[1] / 2, -size[2] / 2] : [0, 0, 0])
    linear_extrude(height = size[2])
      rounded_rect_2d(size[0], size[1], min(r, min(size[0], size[1]) / 2));
}

module x_cylinder(d, h, center = true) {
  rotate([0, 90, 0]) cylinder(d = d, h = h, center = center);
}

module y_cylinder(d, h, center = true) {
  rotate([90, 0, 0]) cylinder(d = d, h = h, center = center);
}

module z_cylinder(d, h, center = true) {
  cylinder(d = d, h = h, center = center);
}

module label_text(txt, size = 4, height = 0.6) {
  linear_extrude(height = height)
    text(txt, size = size, halign = "center", valign = "center");
}
