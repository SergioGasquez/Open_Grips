// OpenGrips Sisyphus: parametric rebuild of the fork's "OpenGrips Sisyphus v27.step".
//
// Coordinates: a left-hand grip, X across the fingers along the roller axes (pinky at low X),
// Y along the fingers, Z depth; the frame's front bottom corner is the origin (the STEP is
// offset by [5.965, 8.069, 4.13]). Parameters follow the VarSet of
// ../Original/OpenGrips_Sisyphus.FCStd under consistent names (there: Base_<F>_height,
// Base_<F>_blocker, Base_<F>_diameter, Base_R_diamter, I_width, Base_wall_width).

use <common.scad>

/* [Output] */
part = "assembly"; // [assembly, frame, pinky_roller, ring_roller, middle_roller, index_roller, ring_wall, middle_wall, index_wall, end_wall, pinky_pin, ring_pin, middle_pin, index_pin, post, guard]
// The model is a left-hand grip; right mirrors every part.
hand = "left"; // [left, right]

/* [Fingers, relative to the pinky (mm)] */
// Roller position along the fingers
Base_I_Height = 21;
Base_M_Height = 29;
Base_R_Height = 21;
Base_P_Height = 0;
// Seat under each roller: how far it reaches past the roller axis (pinky: short of it)
Base_I_Blocker = 4;
Base_M_Blocker = 9;
Base_R_Blocker = 10;
Base_P_Blocker = 1;

/* [Rollers (mm)] */
Base_I_Diameter = 30;
Base_M_Diameter = 40;
Base_R_Diameter = 38;
Base_P_Diameter = 22;
Base_I_Width = 20;
Base_M_Width = 20;
Base_R_Width = 19;
Base_P_Width = 30;

/* [Frame (mm)] */
Wall_Width = 4;
Base_Ext_Wall_Width = 6;
// Length of the walls up to the lock slot
Base_Frame_Height = 80;

/* [Printed pins (mm)] */
pin_diameter = 3.3;
pin_flat = 0.2; // flat along the pin so it prints lying down
pin_end_clearance = 0.1; // to each blind hole bottom
pin_hole_diameter = 3.5;
roller_bore_diameter = 3.8;
roller_side_clearance = 0.25; // to each wall
post_clearance = 0.15; // per side

/* [Hidden] */
in_place = false; // export a part in assembly coordinates (checks against the STEP)
$fa = 3;
$fs = 0.3;
eps = 0.01;

// Fingers in X order from the pinky side.
P = 0; R = 1; M = 2; I = 3;
FINGERS = ["pinky", "ring", "middle", "index"];
HEIGHT = [Base_P_Height, Base_R_Height, Base_M_Height, Base_I_Height];
BLOCKER = [Base_P_Blocker, Base_R_Blocker, Base_M_Blocker, Base_I_Blocker];
DIAMETER = [Base_P_Diameter, Base_R_Diameter, Base_M_Diameter, Base_I_Diameter];
WIDTH = [Base_P_Width, Base_R_Width, Base_M_Width, Base_I_Width];

E = Base_Ext_Wall_Width;
W = Wall_Width;
FW = 3 * W + WIDTH[P] + WIDTH[R] + WIDTH[M] + WIDTH[I] + 2 * E; // frame width
WH = Base_M_Diameter / 2 + W / 2; // wall and frame height (Z)

EDGE_R = 3.9; // outer edge rounds
TOP_EDGE_R = 1; // rounds along the wall plate tops
ROLLER_ARC_R = [80, 40, 40, 40]; // concave roller profile radius
ROLLER_END_R = 2;
CRADLE_SCALE = 1.05; // the cradles are cut by the original rollers scaled up by this
// v27 cuts each cradle with roller tools at these offsets from the roller slot (twice, leftovers
// of the original model; the pinky's single cut is fitted to v27).
CRADLE_TOOL_OFFSETS = [[-1], [0, -1.75], [0, -0.75], [0, 0.25]];

// Rollers (Y, Z in assembly coordinates). All roller tops are level with the middle roller's.
function sum(v, n) = n <= 0 ? 0 : v[n - 1] + sum(v, n - 1);
function roller_x(f) = E + sum(WIDTH, f) + f * W;
function wall_x(f) = roller_x(f) - W; // the wall plate on the pinky side of roller f
END_WALL_X = roller_x(I) + WIDTH[I];
function axis_y(f) = W + DIAMETER[P] + HEIGHT[f] - DIAMETER[f] / 2;
function axis_z(f) = W / 2 + Base_M_Diameter - DIAMETER[f] / 2;
function axis(f) = [axis_y(f), axis_z(f)];
function seat_end(f) = f == P ? axis_y(P) - BLOCKER[P] : axis_y(f) + BLOCKER[f];
function hump_r(f) = DIAMETER[f] / 3; // raised arc of the wall plates around each pole

LOCK_Y = Base_Frame_Height; // walls end and the lock slot starts
LOCK_Z = 10.37; // as in v27 (the Prometheus slot height, copied over)
POST_Y = E;
POST_Z = W;
POST_SIZE = 4;
POST_X0 = E + 2;
POLE_HOLE_DEPTH = 3;

// Finger stops behind each roller (as in v27): sloped front face reaching the wall top this far
// in front of the lock slot, its angle off vertical, and the round at its foot. The pinky's
// stands on a floor in the frame instead.
STOP_SETBACK = [5, 5, 1.34, 5];
STOP_ANGLE = [45, 35, 35, 35];
STOP_FOOT_R = [0, 3, 5, 3];
STOP_SIDE_R = 5; // fillet between the stop and the wall plate beside it
GAP_EDGE_R = 3; // plate bottom edge beside the open gap between seat and stop
PINKY_FLOOR_Z = 5;

// Anchor (as in v27): a bar rising at 45 degrees from the crossbar that ends in a tube; the cord
// runs along the tube bore. Its ends are 45 degree planes in plan through ANCHOR_X0 / ANCHOR_X1
// at the tube top.
ANCHOR_Y = LOCK_Y + 23.824;
ANCHOR_Z = WH + 5;
ANCHOR_R = 12.021;
ANCHOR_BORE_R = 5.242;
ANCHOR_X0 = E + WIDTH[P] + 2.255;
ANCHOR_X1 = roller_x(I) + WIDTH[I] / 2 - 2.185;
FRAME_TOP = ANCHOR_Y - ANCHOR_Z + ANCHOR_R * sqrt(2); // where the bar's underside meets the bed
CORD_EXIT_R = 3;

// TPU guard (as in v27): a sleeve around the anchor bar, open at the lock slot, clearing the
// frame by 0.2 mm (0.4 mm around the bar, none at the anchor ends), with two countersunk cord
// holes along Y.
GUARD_CLEARANCE = 0.2;
GUARD_BAR_CLEARANCE = 0.4;
GUARD_WALL = 3;
GUARD_CHAMFER = 2;
GUARD_HOLE_INSET = 5.517; // inside the anchor ends at the tube axis

for (f = [R:I])
  assert(seat_end(f) < LOCK_Y - STOP_SETBACK[f] - WH * tan(STOP_ANGLE[f]),
         str(FINGERS[f], " seat (Y ", seat_end(f), ") runs into its finger stop"));

// ---------------------------------------------------------------------------------------------
// Rollers, pins, post

// Half profile (along the axis, radius) of roller f, w long: a circle of ROLLER_ARC_R through
// both ends at the roller radius, ends rounded by r.
module roller_half_profile(f, w, r) {
  a = ROLLER_ARC_R[f];
  rr = DIAMETER[f] / 2;
  center = [w / 2, rr + sqrt(a * a - w * w / 4)];
  intersection() {
    translate([-1, 0]) square([w + 2, rr + 1]);
    round2d(r) difference() {
      translate([0, -rr - 1]) square([w, 2 * rr + 2]);
      for (s = [1, -1]) translate([center[0], s * center[1]]) circle(a);
    }
  }
}

module roller(f) {
  w = WIDTH[f] - 2 * roller_side_clearance;
  difference() {
    about_x_axis(roller_x(f) + roller_side_clearance, axis_y(f), axis_z(f)) roller_half_profile(f, w, ROLLER_END_R);
    translate([roller_x(f) - 1, axis_y(f), axis_z(f)]) rotate([0, 90, 0]) cylinder(d = roller_bore_diameter, h = WIDTH[f] + 2);
  }
}

// Space cut under roller f: the roller scaled up by CRADLE_SCALE about its pinky-side end, at
// each tool offset; it reaches eps past both walls so its ends never coincide with their faces.
module cradle(f) {
  w = WIDTH[f] - 2 * roller_side_clearance;
  intersection() {
    for (o = CRADLE_TOOL_OFFSETS[f])
      about_x_axis(roller_x(f) + o, axis_y(f), axis_z(f)) scale(CRADLE_SCALE) roller_half_profile(f, w, ROLLER_END_R);
    translate([roller_x(f) - eps, -1, -1]) cube([WIDTH[f] + 2 * eps, 200, 200]);
  }
}

function pin_span(f) = [roller_x(f) - POLE_HOLE_DEPTH, roller_x(f) + WIDTH[f] + POLE_HOLE_DEPTH];

module pole_holes(f) {
  s = pin_span(f);
  translate([s[0], axis_y(f), axis_z(f)]) rotate([0, 90, 0]) cylinder(d = pin_hole_diameter, h = s[1] - s[0]);
}

module finger_pin(f) {
  s = pin_span(f);
  pin(s[0] + pin_end_clearance, s[1] - pin_end_clearance, axis_y(f), axis_z(f), pin_diameter, pin_flat);
}

module post() {
  c = post_clearance;
  along_x(POST_X0, FW) post2d([POST_Y + c, POST_Z + c], POST_SIZE - 2 * c);
}

module post_hole(x0, x1) {
  along_x(x0 - eps, x1 + eps) post2d([POST_Y, POST_Z], POST_SIZE);
}

module lock() {
  lock2d(LOCK_Y, LOCK_Z, W);
}

// ---------------------------------------------------------------------------------------------
// Wall plates (Y, Z): WH high with raised arcs (humps) of radius D/3 around the poles they hold,
// as drawn in the original wall sketches. A slope runs from the front top corner up to the
// first hump; concave corners get EDGE_R fillets, the front corners EDGE_R rounds.

module hump2d(f) {
  translate(axis(f)) circle(hump_r(f));
}

// Plate whose slope ends at point `to`, with the humps `humps` and any extra area in children().
module plate2d(to, humps) {
  round_corners_in(EDGE_R, [-1, -1], [2 * EDGE_R, 100]) round2d(-EDGE_R) union() {
    square([LOCK_Y, WH]);
    polygon([[0, WH], to, [to[0], WH]]);
    for (f = humps) hump2d(f);
    children();
  }
}

// Ring wall: the slope reaches the pinky hump's front; the ring hump follows.
module ring_plate2d() {
  a = axis(P);
  r = hump_r(P);
  plate2d([a[0] - r, a[1]], [P, R]) translate([a[0] - r, WH]) square([2 * r, a[1] - WH]);
}

// Middle and index walls: the slope reaches the first hump where it mirrors the meeting point
// with the middle hump.
module mirrored_plate2d(first) {
  c = axis(first);
  meet = circle_intersection(c, hump_r(first), axis(M), hump_r(M));
  plate2d([2 * c[0] - meet[0], meet[1]], [first, M]);
}

// End wall: the slope reaches the index hump at 135 degrees; the hump drops vertically at 0.
module end_plate2d() {
  c = axis(I);
  r = hump_r(I);
  plate2d(c + r * [cos(135), sin(135)], []) {
    intersection() { hump2d(I); translate([c[0] - r, c[1]]) square(2 * r); }
    polygon([c + r * [cos(135), sin(135)], c, c + [r, 0], [c[0] + r, WH], [c[0] + r * cos(135), WH]]);
  }
}

// Wall plate over [x0, x0 + W] with its top edges rounded on both faces.
module rounded_plate(x0, keep_y) {
  keep = keep_y == undef ? 1000 : keep_y;
  module sharp() {
    children();
    translate([-10, -10]) square([LOCK_Y + 10 + EDGE_R, WH - TOP_EDGE_R + 10 - 0.5]);
  }
  intersection() {
    along_x_rounded(x0, x0 + W, TOP_EDGE_R, -1) { children(); sharp() children(); }
    along_x_rounded(x0, x0 + W, TOP_EDGE_R, 1) {
      children();
      union() { sharp() children(); translate([keep, -10]) square([100, 100]); }
    }
  }
}

// ---------------------------------------------------------------------------------------------
// Seats and finger stops

// Front face line of finger f's stop, as [y at z = 0, y at z = WH].
function stop_face(f) = let(top = LOCK_Y - STOP_SETBACK[f]) [top - WH * tan(STOP_ANGLE[f]), top];

// Stop (Y, Z) of finger f from its face back to the lock slot.
module stop2d(f) {
  s = stop_face(f);
  module shape() polygon([[s[0], 0], [s[1], WH], [LOCK_Y + 10, WH], [LOCK_Y + 10, 0]]);
  intersection() {
    union() {
      intersection() {
        round2d(TOP_EDGE_R) shape();
        translate([s[0] + 1, WH / 2]) square([100, 100]);
      }
      if (STOP_FOOT_R[f] > 0) intersection() {
        round2d(STOP_FOOT_R[f]) shape();
        translate([s[0] - 1, -1]) square([100, WH / 2 + 1]);
      }
      else intersection() { shape(); translate([0, -1]) square([200, WH / 2 + 1]); }
    }
    square([LOCK_Y, WH]);
  }
}

// Concave fillet of radius r along the stop face of finger f beside the wall face at x = xf,
// the stop extending toward +X (side = 1) or -X (side = -1), from z0 up to the wall top.
module stop_side_fillet(f, xf, side, r, z0 = 0) {
  a = STOP_ANGLE[f];
  dir = [0, sin(a), cos(a)];
  out = [0, -cos(a), sin(a)]; // off the face, into the gap
  s = stop_face(f);
  base = [xf, s[0] + z0 * tan(a), z0];
  intersection() {
    multmatrix([[side, out[0], dir[0], base[0]], [0, out[1], dir[1], base[1]], [0, out[2], dir[2], base[2]]])
      linear_extrude((WH - z0) / cos(a)) difference() {
        translate([-eps, -eps]) square(r + eps);
        translate([r, r]) circle(r);
      }
    translate([-1, 0, 0]) cube([FW + 2, LOCK_Y, WH]);
  }
}

// Seat under roller f from the wall front up to seat_end(f), cut by the cradle.
module seat(f) {
  along_x(roller_x(f) - eps, roller_x(f) + WIDTH[f]) front_rounded2d([0, 0], [seat_end(f), WH], EDGE_R);
}

// ---------------------------------------------------------------------------------------------
// Walls

module finger_wall(f) {
  x0 = wall_x(f);
  x1 = roller_x(f) + WIDTH[f];
  s = stop_face(f);
  difference() {
    union() {
      rounded_plate(x0, s[1] - 2 * TOP_EDGE_R) children();
      seat(f);
      along_x(roller_x(f) - eps, x1) stop2d(f);
      stop_side_fillet(f, roller_x(f), 1, STOP_SIDE_R, STOP_FOOT_R[f]);
      along_x(x0, x1) lock();
    }
    cradle(f);
    edge_round_cutter("y", seat_end(f), s[0], [roller_x(f), 0], GAP_EDGE_R, [1, -1]);
    pole_holes(f);
    pole_holes(f - 1);
    post_hole(x0, x1);
  }
}

module ring_wall() {
  finger_wall(R) ring_plate2d();
}

module middle_wall() {
  finger_wall(M) mirrored_plate2d(R);
}

module index_wall() {
  finger_wall(I) mirrored_plate2d(I);
}

// End wall: outer face edges rounded by EDGE_R, inner top edges by TOP_EDGE_R.
module end_wall() {
  x0 = END_WALL_X;
  difference() {
    union() {
      intersection() {
        along_x_rounded(x0, FW, EDGE_R, 1) {
          end_plate2d();
          union() { end_plate2d(); translate([LOCK_Y - EDGE_R, -10]) square([20, 100]); }
        }
        along_x_rounded(x0, FW, TOP_EDGE_R, -1) {
          end_plate2d();
          union() { end_plate2d(); translate([-10, -10]) square([LOCK_Y + 20, WH + 10 - 0.5]); }
        }
      }
      along_x(x0, FW) lock();
    }
    pole_holes(I);
    post_hole(x0, FW);
  }
}

// ---------------------------------------------------------------------------------------------
// Frame

// Crossbar and anchor (Y, Z): the bar between two 45 degree lines tangent to the tube.
// Its underside meets the bed with an EDGE_R round.
module crossbar2d() {
  round_corners_in(EDGE_R, [FRAME_TOP - 2 * EDGE_R, -1], [FRAME_TOP + 2 * EDGE_R, WH / 2]) {
    translate([LOCK_Y, 0]) square([FRAME_TOP - LOCK_Y, WH]);
    anchor2d();
  }
}

// The anchor bar and tube (Y, Z).
module anchor2d() {
  c = [ANCHOR_Y, ANCHOR_Z];
  d = ANCHOR_R / sqrt(2);
  top_start = [c[0] - c[1] + WH - ANCHOR_R * sqrt(2), WH];
  polygon([[FRAME_TOP, 0], c + [d, -d], c + [-d, d], top_start, [top_start[0], 0]]);
  translate(c) circle(ANCHOR_R);
}

// Plan (X, Y) of the anchor between its 45 degree ends.
module anchor_plan() {
  top = ANCHOR_Y + ANCHOR_R;
  polygon([[ANCHOR_X0 - (top - LOCK_Y), LOCK_Y], [ANCHOR_X1 + (top - LOCK_Y), LOCK_Y], [ANCHOR_X1, top], [ANCHOR_X0, top]]);
}

// Pinky column (Y, Z) at the outer frame side: the frame height plus the wall around the pinky
// pole, a hump of radius D/3 flanked by concave arcs that end at the front top corner and at
// the frame top.
module pinky_column2d() {
  a = axis(P);
  r = hump_r(P);
  rc = a[1] - WH;
  left = circle_intersection([0, WH], rc, a, r + rc);
  right = a + [r + rc, 0];
  module shape() {
    square([FRAME_TOP, WH]);
    difference() {
      hull() { translate(a) circle(r); translate([0, WH - eps]) square([right[0], eps]); }
      translate(left) circle(rc);
      translate(right) circle(rc);
    }
  }
  intersection() { round2d(EDGE_R) shape(); square([2 * EDGE_R, 100]); }
  intersection() { shape(); translate([2 * EDGE_R, -1]) square([200, 100]); }
}

module cord_path() {
  top = ANCHOR_Y + ANCHOR_R;
  translate([-1, ANCHOR_Y, ANCHOR_Z]) rotate([0, 90, 0]) cylinder(r = ANCHOR_BORE_R, h = FW + 2);
  bore_exit_round([ANCHOR_Y, ANCHOR_Z], ANCHOR_BORE_R, [ANCHOR_X0, top], [-1, 1] / sqrt(2), CORD_EXIT_R);
  bore_exit_round([ANCHOR_Y, ANCHOR_Z], ANCHOR_BORE_R, [ANCHOR_X1, top], [1, 1] / sqrt(2), CORD_EXIT_R);
}

// Plan (X, Y) of the crossbar and anchor: the column top meets the anchor end with a 3.4
// fillet, from where the crossbar profile shapes the column top.
module crossbar_plan() {
  x1 = E + WIDTH[P];
  fillet_x = ANCHOR_X0 - (ANCHOR_Y + ANCHOR_R - FRAME_TOP) - 3.4 * tan(22.5);
  anchor_plan();
  difference() {
    round2d(-3.4) union() { anchor_plan(); square([x1, FRAME_TOP]); }
    square([x1, FRAME_TOP]);
  }
  translate([fillet_x, LOCK_Y - 1]) square([FW - fillet_x, FRAME_TOP - LOCK_Y + 1]);
}

// The frame; with cord = false the anchor is left solid, which shapes the guard's cavity.
module frame(cord = true) {
  x1 = E + WIDTH[P];
  s = stop_face(P);
  difference() {
    union() {
      // Pinky column: its outer face, front and top edges rounded; the wall around the pole
      // is E thick, its inner top edges rounded by TOP_EDGE_R.
      intersection() {
        union() {
          translate([-1, -1, -1]) cube([x1 + 2, FRAME_TOP + 2, WH + 1]);
          intersection() {
            translate([-1, -1, -1]) cube([E + 1, FRAME_TOP + 2, 100]);
            along_x_rounded(0, E, TOP_EDGE_R, 1) {
              pinky_column2d();
              union() { pinky_column2d(); translate([-10, -10]) square([FRAME_TOP + 20, WH + 10 - 0.5]); }
            }
          }
        }
        along_x_rounded(0, x1, EDGE_R, -1) {
          pinky_column2d();
          union() { pinky_column2d(); translate([FRAME_TOP, -10]) square([20, 100]); }
        }
        translate([0, 0, -1]) linear_extrude(100) round2d(EDGE_R) translate([0, 0]) square([x1 + 10, FRAME_TOP]);
        along_x(-1, x1 + 1) round_corners_in(EDGE_R, [FRAME_TOP - 2 * EDGE_R, -1], [FRAME_TOP + 1, WH + 1]) {
          square([FRAME_TOP, WH]);
          translate([-1, WH - 1]) square([FRAME_TOP - 2 * EDGE_R, 100]);
        }
      }
      // Crossbar and anchor, the outer end face rounded.
      intersection() {
        union() {
          along_x(0, FW - 3 * EDGE_R) crossbar2d();
          along_x_rounded(FW - 4 * EDGE_R, FW, EDGE_R, 1) {
            crossbar2d();
            union() { crossbar2d(); translate([LOCK_Y - 10, -10]) square([10, 100]); }
          }
        }
        translate([0, 0, -1]) linear_extrude(100) crossbar_plan();
      }
    }
    // Floor between the seat and the finger stop, and the stop's fillet beside the outer wall.
    difference() {
      translate([E, seat_end(P), PINKY_FLOOR_Z]) cube([WIDTH[P] + 1, s[1] - seat_end(P), 100]);
      translate([E - 1, 0, 0]) along_x(0, WIDTH[P] + 2) stop2d(P);
      stop_side_fillet(P, E, 1, STOP_SIDE_R, PINKY_FLOOR_Z);
    }
    cradle(P);
    pole_holes(P);
    post_hole(POST_X0, x1);
    along_x(x1, FW + 1) lock();
    if (cord) cord_path();
  }
}

// ---------------------------------------------------------------------------------------------
// TPU guard

GUARD_BACK = ANCHOR_Y + ANCHOR_R + GUARD_WALL;

// Guard outline (Y, Z), as in v27: faces parallel to the anchor bar (y - z constant) above and
// below it, a back face, an end cap across the bar and a top.
module guard2d() {
  upper = ANCHOR_Y - ANCHOR_Z - ANCHOR_R * sqrt(2) - 5.28; // y - z of the face above the bar
  lower = FRAME_TOP + 3.1; // y - z of the face below it
  cap = ANCHOR_Y + ANCHOR_Z + ANCHOR_R * sqrt(2) + 3.14; // y + z of the end cap
  top = ANCHOR_Z + ANCHOR_R + 2.02;
  b = GUARD_BACK;
  polygon([[LOCK_Y, -GUARD_WALL], [lower - GUARD_WALL, -GUARD_WALL], [b, b - lower], [b, cap - b],
           [cap - top, top], [upper + top, top], [LOCK_Y, LOCK_Y - upper]]);
}

module guard() {
  g = GUARD_WALL;
  c = GUARD_CHAMFER;
  back = GUARD_BACK;
  difference() {
    hull() {
      along_x(-g, FW + g) offset(delta = c, chamfer = true) offset(delta = -c) guard2d();
      along_x(-g + c, FW + g - c) guard2d();
    }
    // Cavity: the frame behind the lock slot with clearance.
    intersection() {
      union() {
        along_x(-GUARD_CLEARANCE, FW + GUARD_CLEARANCE) offset(GUARD_CLEARANCE) crossbar2d();
        along_x(-GUARD_BAR_CLEARANCE, FW + GUARD_BAR_CLEARANCE) offset(GUARD_BAR_CLEARANCE) anchor2d();
      }
      translate([0, 0, -10]) linear_extrude(100) crossbar_plan();
    }
    // The pinky column's top part, its back edges rounded.
    intersection() {
      translate([0, 0, -10]) linear_extrude(100) offset(GUARD_CLEARANCE) round2d(EDGE_R) square([E + WIDTH[P], FRAME_TOP]);
      along_x(-1, E + WIDTH[P] + 1) offset(GUARD_CLEARANCE) round2d(EDGE_R) square([FRAME_TOP, WH]);
    }
    translate([-10, LOCK_Y - 10, -10]) cube([FW + 20, 10 + eps, WH + 30]);
    top = ANCHOR_Y + ANCHOR_R;
    for (x = [ANCHOR_X0 - (top - ANCHOR_Y) + GUARD_HOLE_INSET, ANCHOR_X1 + (top - ANCHOR_Y) - GUARD_HOLE_INSET])
      translate([x, ANCHOR_Y, ANCHOR_Z]) rotate([-90, 0, 0]) {
        cylinder(r = 4, h = back - ANCHOR_Y + 1);
        translate([0, 0, back - ANCHOR_Y - c]) cylinder(r1 = 4, r2 = 4 + c + eps, h = c + eps);
      }
  }
}

// ---------------------------------------------------------------------------------------------
// Output

// [name, kind, finger]
PARTS = [
  ["frame", "frame"], ["ring_wall", "wall", R], ["middle_wall", "wall", M], ["index_wall", "wall", I],
  ["end_wall", "end_wall"], ["pinky_roller", "roller", P], ["ring_roller", "roller", R],
  ["middle_roller", "roller", M], ["index_roller", "roller", I], ["pinky_pin", "pin", P],
  ["ring_pin", "pin", R], ["middle_pin", "pin", M], ["index_pin", "pin", I], ["post", "post"],
  ["guard", "guard"]];
COLORS = [["frame", "gainsboro"], ["wall", "gold"], ["end_wall", "skyblue"], ["roller", "tomato"],
          ["pin", "dimgray"], ["post", "royalblue"], ["guard", [0.5, 0, 0.5, 0.4]]];

module part_in_place(p) {
  f = p[2];
  if (p[1] == "frame") frame();
  else if (p[1] == "wall") { if (f == R) ring_wall(); else if (f == M) middle_wall(); else index_wall(); }
  else if (p[1] == "end_wall") end_wall();
  else if (p[1] == "roller") roller(f);
  else if (p[1] == "pin") finger_pin(f);
  else if (p[1] == "post") post();
  else if (p[1] == "guard") guard();
}

// Print pose. Frame, walls and rollers stand on their pinky-side face with the pole holes
// vertical; pins lie on their flat; the post lies on its chamfered side; the guard stands on
// its back face.
module print_pose(p) {
  f = p[2];
  if (p[1] == "guard") translate([0, 0, GUARD_BACK]) rotate([-90, 0, 0]) children();
  else if (p[1] == "post") translate([0, 0, -POST_Z - post_clearance]) children();
  else if (p[1] == "pin") translate([0, 0, -(axis_z(f) - pin_diameter / 2 + pin_flat)]) children();
  else {
    x0 = p[1] == "frame" ? 0 : p[1] == "wall" ? wall_x(f) : p[1] == "end_wall" ? END_WALL_X
       : roller_x(f) + roller_side_clearance;
    rotate([0, -90, 0]) translate([-x0, 0, 0]) children();
  }
}

// render() keeps previews (F5) fast: OpenCSG cannot normalize the frame's CSG tree.
if (part == "assembly") {
  hand_mirror(hand) for (p = PARTS) color([for (c = COLORS) if (c[0] == p[1]) c[1]][0]) render() part_in_place(p);
} else {
  p = [for (q = PARTS) if (q[0] == part) q][0];
  assert(p != undef, str("unknown part: ", part));
  if (in_place) hand_mirror(hand) render() part_in_place(p);
  else hand_mirror(hand) print_pose(p) render() part_in_place(p);
}
