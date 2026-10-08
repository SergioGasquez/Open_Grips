// Shared building blocks of the OpenGrips models (use <common.scad>).
//
// Model coordinates: X runs across the fingers along the roller axes, Y along the fingers, Z is
// depth; 2D profiles are drawn in (Y, Z) and extruded along X unless noted.

eps = 0.01;

// Extrude a 2D (Y, Z) profile along X.
module along_x(x0, x1) {
  translate([x0, 0, 0]) rotate([90, 0, 90]) linear_extrude(x1 - x0) children();
}

// Extrude a 2D (X, Z) profile along Y.
module along_y(y0, y1) {
  translate([0, y1, 0]) rotate([90, 0, 0]) linear_extrude(y1 - y0) children();
}

// Revolve a 2D (along the axis, radius) profile about the X axis through [x0, y, z].
module about_x_axis(x0, y, z) {
  translate([x0, y, z]) rotate([0, 90, 0]) rotate([0, 0, 90])
    rotate_extrude() rotate([0, 0, 90]) mirror([0, 1, 0]) children();
}

// Round convex corners (r > 0) or concave corners (r < 0) of a 2D shape. Round joins on both
// steps: delta (mitred) joins spike through the shape at tangent cusps.
module round2d(r) {
  offset(r) offset(-r) children();
}

// children() with the convex corners inside the window [p0, p1] rounded by r.
module round_corners_in(r, p0, p1) {
  difference() { children(); translate(p0) square(p1 - p0); }
  intersection() { round2d(r) children(); translate(p0) square(p1 - p0); }
}

// Rectangle from p0 to p1 with its two low-X corners rounded by r.
module front_rounded2d(p0, p1, r) {
  intersection() {
    round2d(r) translate(p0) square([p1[0] - p0[0] + r, p1[1] - p0[1]]);
    translate(p0) square(p1 - p0);
  }
}

// Sphere for rounding: polyhedral spheres fall short of r along the axes, so scale up the facets.
module ball(r) {
  scale(1 / cos(180 / 48)) sphere(r, $fn = 48);
}

// Extrude a (Y, Z) profile along X with the perimeter edges of one end face rounded by r
// (side = 1: the face at x1, side = -1: at x0). children(1), if given, is a larger profile
// whose extra area keeps the edges it covers sharp; it must reach r past those edges.
// The rounded end is the eroded profile, t thick, swept by a ball; the sharp part ends inside
// that core so the two share no faces.
module along_x_rounded(x0, x1, r, side) {
  face = side > 0 ? x1 : x0;
  t = 0.5;
  intersection() {
    along_x(x0, x1) children(0);
    union() {
      if (side > 0) along_x(x0 - 1, x1 - r - t / 2) children($children - 1);
      else along_x(x0 + r + t / 2, x1 + 1) children($children - 1);
      minkowski() {
        along_x(min(face - side * r, face - side * (r + t)), max(face - side * r, face - side * (r + t)))
          offset(-r) children($children - 1);
        ball(r);
      }
    }
  }
}

// Material to remove to round by r the edge along `axis` ("x" or "y") through point `at`, where
// the solid lies toward -sign in the two other axes (sign = [s1, s2]).
module edge_round_cutter(axis, from, to, at, r, sign) {
  module cutter2d() {
    translate(at) scale(sign) difference() {
      translate([-r, -r]) square(r + eps);
      translate([-r, -r]) circle(r);
    }
  }
  if (axis == "x") along_x(from, to) cutter2d();
  else along_y(from, to) cutter2d();
}

function arc_points(c, r, a0, a1, n = 24) =
  [for (k = [0:n]) c + r * [cos(a0 + (a1 - a0) * k / n), sin(a0 + (a1 - a0) * k / n)]];

// Intersection of the circles (c0, r0) and (c1, r1) on the left of the line from c0 to c1.
function circle_intersection(c0, r0, c1, r1) =
  let(d = norm(c1 - c0), u = (c1 - c0) / d, a = (r0 * r0 - r1 * r1 + d * d) / (2 * d))
  c0 + a * u + sqrt(r0 * r0 - a * a) * [-u[1], u[0]];

// Printed pin along X over [x0, x1] at (y, z): a cylinder with a flat on its underside so it
// prints lying down.
module pin(x0, x1, y, z, d, flat) {
  r = d / 2;
  translate([x0, y, z]) difference() {
    rotate([0, 90, 0]) cylinder(r = r, h = x1 - x0);
    translate([-1, -r, -r - 1]) cube([x1 - x0 + 2, 2 * r, 1 + flat]);
  }
}

// Post cross-section (Y, Z) from p (its low corner): a rounded square whose low corner is
// chamfered, which keys the post in its holes.
module post2d(p, size) {
  translate(p) hull() {
    for (q = [[1, size - 1], [size - 1, size - 1], [size - 1, 1]]) translate(q) circle(1);
    polygon([[0, 1], [1, 0], [1, 1]]);
    translate([0, 1]) square([eps, size - 2]);
    translate([1, 0]) square([size - 2, eps]);
  }
}

// Lock tongue / slot cross-section (Y, Z): a bar of thickness w from y0, 2w long, with round
// beads of diameter w at its end that hook the walls into the frame.
module lock2d(y0, z0, w) {
  translate([y0 - eps, z0]) square([2 * w + eps, w]);
  for (z = [z0, z0 + w]) translate([y0 + 1.5 * w, z]) circle(w / 2);
}

// Material removed to round by r the edge where a bore along X (center [y, z], radius rb)
// breaks out of the vertical end plane through p0 (in plan) with outward unit normal n. A ball
// rolls along the edge touching the bore and the plane; between the edge and its path lies the
// cut.
module bore_exit_round(center, rb, p0, n, r) {
  steps = 72;
  d = 0.05; // overshoot into the air so the cut leaves no slivers
  // x where the plane passes through bore radius rho at angle t, offset off along n.
  function x_on_plane(rho, t, off) =
    let(y = center[0] + rho * cos(t)) (n * p0 + off - n[1] * y) / n[0];
  function ring(rho, t) = center + rho * [cos(t), sin(t)];
  function corner(t) = let(
    e = concat([x_on_plane(rb, t, 0)], ring(rb, t)),
    c = concat([x_on_plane(rb + r, t, -r)], ring(rb + r, t)),
    f1 = concat([c[0]], ring(rb - d, t)),
    f2 = c + (r + d) * [n[0], n[1], 0],
    out = (e - c) / norm(e - c))
    [e + d * out, f1, f2, c];
  // Neighbouring pieces overlap slightly so they share no faces.
  for (k = [0:steps - 1]) {
    a = corner(360 * (k - 0.1) / steps);
    b = corner(360 * (k + 1.1) / steps);
    // The ball is a touch larger so its path crosses the bore and plane instead of touching
    // them, which booleans cannot resolve cleanly.
    difference() {
      hull() for (q = [a[0], a[1], a[2], b[0], b[1], b[2]]) translate(q) cube(0.01, center = true);
      hull() for (q = [a[3], b[3]]) translate(q) ball(r + 0.02);
    }
  }
}

// Mirror for a right-hand grip; the models are left-hand grips.
module hand_mirror(hand) {
  assert(hand == "left" || hand == "right", str("hand must be left or right, got ", hand));
  if (hand == "right") mirror([1, 0, 0]) children();
  else children();
}
