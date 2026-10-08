// OpenGrips Prometheus: parametric rebuild of the fork's "OpenGrips Prometheus v43.step".
//
// Coordinates follow the original FreeCAD model, a left-hand grip: X runs across the fingers
// along the roller axes (pinky at low X), Y along the fingers, Z is depth (frame bottom at 0).
// Parameter names and meanings match the VarSet of ../Original/OpenGrips_Prometheus.FCStd, so the
// output of ../prometheus-fit/measure-hand.html applies unchanged.

use <common.scad>

/* [Output] */
part = "assembly"; // [assembly, frame, pinky_roller, ring_roller, middle_roller, index_roller, ring_wall, middle_wall, index_wall, end_wall, pinky_pin, ring_pin, middle_pin, index_pin, post]
// The model is a left-hand grip; right mirrors every part.
hand = "left"; // [left, right]

/* [Fingers, relative to the pinky (mm)] */
// Roller up/down (fingertip position along the fingers)
Base_I_Height = 23;
Base_M_Height = 32;
Base_R_Height = 15;
Base_P_Height = 0;
// Roller forward/backward
Base_I_Depth = 8;
Base_M_Depth = 12;
Base_R_Depth = 12;
Base_P_Depth = 0;
// Roof height: roller top to blocker. Defaults are the v43 blocker positions (VarSet: 14, 15, 15, 12).
Base_I_To_Blocker = 14.2;
Base_M_To_Blocker = 13.9;
Base_R_To_Blocker = 12.7;
Base_P_To_Blocker = 8.8;

/* [Rollers (mm)] */
Base_I_Diameter = 19;
Base_M_Diameter = 19;
Base_R_Diameter = 19;
Base_P_Diameter = 30;
Base_I_Width = 19;
Base_M_Width = 19;
Base_R_Width = 19;
Base_P_Width = 30;

/* [Frame (mm)] */
Wall_Width = 4;
Base_Ext_Wall_Width = 6;
Base_Blocker_Height = 30;
// The original metal pole; still sets the frame thickness and rail details.
Base_Pole_Diameter = 2.6;

/* [Printed pins (mm)] */
pin_diameter = 3.3;
pin_flat = 0.2; // flat along the pin so it prints lying down
pin_end_clearance = 0.1; // to each blind hole bottom
pin_hole_diameter = 3.5;
roller_bore_diameter = 3.8;
roller_bore_chamfer = 0.5;
roller_side_clearance = 0.2; // to each wall
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
DEPTH = [Base_P_Depth, Base_R_Depth, Base_M_Depth, Base_I_Depth];
TO_BLOCKER = [Base_P_To_Blocker, Base_R_To_Blocker, Base_M_To_Blocker, Base_I_To_Blocker];
DIAMETER = [Base_P_Diameter, Base_R_Diameter, Base_M_Diameter, Base_I_Diameter];
WIDTH = [Base_P_Width, Base_R_Width, Base_M_Width, Base_I_Width];

E = Base_Ext_Wall_Width;
W = Wall_Width;
POLE = Base_Pole_Diameter;
Base_Frame_Depth = Base_M_Depth + Base_M_Diameter / 2 + 5;
Base_Frame_Height = 2 * E + Base_P_Diameter + Base_M_Height + Base_M_To_Blocker + 15;
Base_Frame_Width = 3 * W + WIDTH[P] + WIDTH[R] + WIDTH[M] + WIDTH[I] + 2 * E;
FD = Base_Frame_Depth;
FW = Base_Frame_Width;
T = FD - POLE; // thickness (Z) of the frame plate and the walls
FRAME_TOP = E + Base_Frame_Height; // Y where the anchor starts

ROLLER_WAIST = 5; // smallest roller radius
POLE_HOLE_DEPTH = 3;
EDGE_R = 3.9; // outer edge rounds (Wall_Width - 0.1 in the FreeCAD model)
BLOCKER_R = 2; // blocker tip and edge rounds
FLOOR_ABOVE_ROLLER = 1; // the floor in front of each roller sits this far above its bottom
CRADLE_SCALE = 1.05; // radial clearance of the cradle under each roller

// Rollers, walls and blockers (Y, Z in assembly coordinates).
function sum(v, n) = n <= 0 ? 0 : v[n - 1] + sum(v, n - 1);
function roller_x(f) = E + sum(WIDTH, f) + f * W;
function wall_x(f) = roller_x(f) - W; // the wall plate on the pinky side of roller f
END_WALL_X = roller_x(I) + WIDTH[I];
function axis_y(f) = E + DIAMETER[P] + HEIGHT[f] - DIAMETER[f] / 2;
function axis_z(f) = FD - DEPTH[f];
function axis(f) = [axis_y(f), axis_z(f)];
function blocker_y(f) = E + DIAMETER[P] + HEIGHT[f] + TO_BLOCKER[f];
// Roller end radii: the pinky roller is a cone-like spool, the others are symmetric.
function roller_end_radii(f) = f == P ? [DIAMETER[P] / 4, DIAMETER[P] / 2] : [DIAMETER[f] / 2, DIAMETER[f] / 2];

// Concave roller profile: a circle through both end radii with ROLLER_WAIST as its lowest point.
// Returns [center along the roller, radius] for a roller of width w.
function roller_arc(w, r0, r1) =
  let(a = r0 - ROLLER_WAIST, b = r1 - ROLLER_WAIST)
  a == b ? [w / 2, (w * w / 4 + a * a) / (2 * a)]
  : let(A = 1 - b / a, c = (2 * w - sqrt(4 * w * w - 4 * A * (w * w + b * b - a * b))) / (2 * A))
    [c, (c * c + a * a) / (2 * a)];

WALL_Y0 = E + DIAMETER[P] + HEIGHT[R] - DIAMETER[R] - 2 * W; // front of the ring, middle, index and end walls
LOCK_Y = Base_Frame_Height - E - 15 + 3 * W; // crossbar front, lock slot start
LOCK_Z = FD - 3 * W;
POST_Y = WALL_Y0 + E;
POST_Z = W;
POST_SIZE = 4;

// Anchor: tube along X behind the crossbar that a cord pulls on.
ANCHOR_Y = FRAME_TOP + 16;
ANCHOR_Z = FD - Base_M_Depth;
ANCHOR_BORE_R = 4;
ANCHOR_R = ANCHOR_BORE_R + 4.4;
ANCHOR_X0 = E + WIDTH[P]; // its 45 degree ends pass through these X at the tube top
ANCHOR_X1 = roller_x(I) + WIDTH[I] / 2;
CORD_EXIT_R = 3; // round of the bore where it breaks out of the anchor ends

for (f = [P:I])
  assert(blocker_y(f) + 2 * BLOCKER_R < LOCK_Y,
         str(FINGERS[f], " blocker (Y ", blocker_y(f), ") reaches the crossbar (Y ", LOCK_Y,
             "): the middle finger must have the largest Height + To_Blocker"));

// ---------------------------------------------------------------------------------------------
// Rollers, pins, post

// Half profile (along the axis, radius) of roller f over [u0, u1], ends rounded by [rf0, rf1].
module roller_half_profile(f, u0, u1, rf) {
  w = WIDTH[f];
  arc = roller_arc(w, roller_end_radii(f)[0], roller_end_radii(f)[1]);
  rmax = max(roller_end_radii(f)) + 1;
  // Mirror across the axis so rounding leaves the axis side alone, then keep the upper half.
  intersection() {
    translate([u0 - 1, 0]) square([u1 - u0 + 2, rmax + 1]);
    union() {
      for (k = [0, 1]) intersection() {
        round2d(rf[k]) roller_body2d();
        translate([k == 0 ? u0 - 1 : (u0 + u1) / 2, -rmax - 1]) square([(u1 - u0) / 2 + 1, 2 * rmax + 2]);
      }
    }
  }
  module roller_body2d() {
    difference() {
      translate([u0, -rmax]) square([u1 - u0, 2 * rmax]);
      for (s = [1, -1]) translate([arc[0], s * (ROLLER_WAIST + arc[1])]) circle(arc[1]);
    }
  }
}

// Solid of revolution about the roller f axis from a (along the axis, radius) profile at local u.
module about_roller_axis(f) {
  about_x_axis(roller_x(f), axis_y(f), axis_z(f)) children();
}

// The printed roller: trimmed for side clearance, ends rounded, chamfered bore for the pin.
module roller(f) {
  w = WIDTH[f];
  rf = f == P ? 0.5 : 1;
  c = roller_side_clearance;
  difference() {
    about_roller_axis(f) roller_half_profile(f, c, w - c, [rf, rf]);
    about_roller_axis(f) polygon([
      [c - eps, 0], [c - eps, roller_bore_diameter / 2 + roller_bore_chamfer + eps],
      [c + roller_bore_chamfer, roller_bore_diameter / 2], [w - c - roller_bore_chamfer, roller_bore_diameter / 2],
      [w - c + eps, roller_bore_diameter / 2 + roller_bore_chamfer + eps], [w - c + eps, 0]]);
  }
}

// Space cut under roller f: the original roller (no side clearance, its own end rounds) with
// CRADLE_SCALE radial clearance, never wider than its largest end. It reaches eps past the
// walls on both sides so its ends never coincide with their faces.
module cradle(f) {
  w = WIDTH[f];
  rf = f == P ? [0.5, 0] : [1, 1];
  about_roller_axis(f) translate([w / 2, 0]) scale([(w + 2 * eps) / w, 1]) translate([-w / 2, 0]) intersection() {
    scale([1, CRADLE_SCALE]) roller_half_profile(f, 0, w, rf);
    square([w, max(roller_end_radii(f))]);
  }
}

// Pole hole span [x0, x1] of roller f: blind holes POLE_HOLE_DEPTH deep into the walls at each end.
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
  along_x(E, FW) post2d([POST_Y + c, POST_Z + c], POST_SIZE - 2 * c);
}

module post_hole(x0, x1) {
  along_x(x0 - eps, x1 + eps) post2d([POST_Y, POST_Z], POST_SIZE);
}

// Lock tongue / slot cross-section (Y, Z) along the crossbar.
module lock() {
  lock2d(LOCK_Y, LOCK_Z, W);
}

// ---------------------------------------------------------------------------------------------
// Blockers

// Blocker (Y, Z) shape of finger f down to z = 0: vertical front face, BLOCKER_R tip and a back
// face 15 degrees off vertical (the pinky's instead passes 15 mm behind the front face at z = 0).
module blocker2d(f, inset = 0) {
  front = blocker_y(f);
  tip = [front + BLOCKER_R, FD + E - DEPTH[f] - DIAMETER[f] / 2 + Base_Blocker_Height - BLOCKER_R];
  n = [cos(15), sin(15)];
  back = f == P ? [front + 15, 0] : [(n * tip + BLOCKER_R) / n[0], 0];
  offset(-inset) hull() {
    translate(tip) circle(BLOCKER_R);
    polygon([[front, -10], [front, tip[1]], [back[0], back[1]], [back[0], -10]]);
  }
}

// Blocker of finger f over [x0, x1] with every exposed edge rounded by BLOCKER_R.
module blocker(f, x0, x1) {
  intersection() {
    minkowski() {
      along_x(x0 + BLOCKER_R, x1 - BLOCKER_R) blocker2d(f, BLOCKER_R);
      ball(BLOCKER_R);
    }
    translate([x0, 0, 0]) cube([x1 - x0, LOCK_Y, 100]);
  }
}

// Full-height block from blocker f to the crossbar over [x0, x1]. A fin as wide as the wall
// gives the block its rounded front corners, down to the floor in front of the roller; beside a
// narrower fin the block's exposed top front edge is rounded.
module blocker_block(f, x0, x1, fin) {
  front = blocker_y(f);
  if (fin[0] == x0 && fin[1] == x1) {
    translate([x0, front + 2 * BLOCKER_R, 0]) cube([x1 - x0, LOCK_Y - front - 2 * BLOCKER_R, T]);
    translate([x0, front, 0]) cube([x1 - x0, LOCK_Y - front, axis_z(f) - DIAMETER[f] / 2 + FLOOR_ABOVE_ROLLER]);
  }
  else
    along_x(x0, x1) intersection() {
      round2d(BLOCKER_R) translate([front, 0]) square([LOCK_Y + BLOCKER_R - front, T]);
      translate([front, 0]) square([LOCK_Y - front, T]);
    }
}

// ---------------------------------------------------------------------------------------------
// Walls

// Insets that carry roller f between its wall plate and the next one, cut by its cradle.
module roller_seat(f) {
  x0 = roller_x(f);
  x1 = x0 + WIDTH[f];
  a = axis(f);
  arc = roller_arc(WIDTH[f], DIAMETER[f] / 2, DIAMETER[f] / 2);
  arc_c = [x0 + arc[0], a[0] + ROLLER_WAIST + arc[1]];
  front = blocker_y(f);
  // Under the roller (overlapping the wall plate to avoid coincident faces).
  along_x(x0 - eps, x1) front_rounded2d([WALL_Y0, 0], [a[0] - POLE, a[1]], EDGE_R);
  difference() {
    translate([x0 - eps, a[0] - POLE - eps, 0]) cube([x1 - x0 + eps, arc_c[1] - a[0] + POLE, a[1] - POLE / 2 - 1]);
    translate([arc_c[0], arc_c[1], -1]) cylinder(r = arc[1], h = 100);
  }
  // Floor in front of the roller, up to the blocker.
  intersection() {
    translate([x0 - eps, a[0], 0]) cube([x1 - x0 + eps, front - a[0] + eps, a[1] - DIAMETER[f] / 2 + FLOOR_ABOVE_ROLLER]);
    union() {
      translate([arc_c[0], arc_c[1], -1]) cylinder(r = arc[1], h = 100);
      translate([x0, arc_c[1], -1]) cube([x1 - x0, 100, 100]);
    }
  }
}

// Wall plate (Y, Z) profiles. Rails are the raised arcs around the poles.
module rail2d(f) {
  translate(axis(f)) circle(DIAMETER[f] / 3);
}

// Ring wall plate: also holds the pinky pole, with a hump of radius D/3 around it whose sides
// run down to the plate top one roller radius from the axis.
module ring_plate2d() {
  a = axis(P);
  module shape() {
    translate([E, 0]) square([LOCK_Y - E, T]);
    polygon(concat([[a[0] + DIAMETER[P] / 2, T]], arc_points(a, DIAMETER[P] / 3, 0, 180), [[a[0] - DIAMETER[P] / 2, T]]));
  }
  front = E + 2 * EDGE_R;
  intersection() { round2d(EDGE_R) shape(); translate([0, -1]) square([front, 100]); }
  intersection() { shape(); translate([front, -1]) square([100, 100]); }
}

module plate2d(top, rails) {
  front_rounded2d([WALL_Y0, 0], [LOCK_Y, top], EDGE_R);
  for (f = rails) rail2d(f);
}

// Common part of the ring, middle and index walls; children() is the wall plate.
module finger_wall(f, fin) {
  x0 = wall_x(f);
  x1 = roller_x(f) + WIDTH[f];
  difference() {
    union() {
      children();
      roller_seat(f);
      blocker_block(f, x0, x1, fin);
      blocker(f, fin[0], fin[1]);
      along_x(x0, x1) lock();
    }
    cradle(f);
    pole_holes(f);
    if (f == R) pole_holes(P);
    else pole_holes(f - 1);
    post_hole(x0, x1);
  }
}

module ring_wall() {
  x0 = wall_x(R);
  x1 = x0 + W;
  a = axis(P);
  // The plate's roller-side edges are rounded beside the pinky roller and around the hump, and
  // by BLOCKER_R along its top above the ring roller.
  finger_wall(R, [x0, x1 + WIDTH[R] - 5]) difference() {
    along_x_rounded(x0, x1, EDGE_R, 1) {
      ring_plate2d();
      union() {
        ring_plate2d();
        translate([WALL_Y0, -10]) square([LOCK_Y, T + 10]);
        translate([a[0] + DIAMETER[P] / 3, -1]) square([LOCK_Y, 100]);
      }
    }
    edge_round_cutter("y", a[0] + DIAMETER[P] / 2, blocker_y(R) - eps, [x1, T], BLOCKER_R, [1, 1]);
  }
}

module middle_wall() {
  x0 = wall_x(M);
  finger_wall(M, [x0, roller_x(M) + WIDTH[M]]) {
    along_x(x0, x0 + W) plate2d(axis_z(R), [M]);
    // The ring rail stands free on the middle roller side.
    along_x_rounded(x0, x0 + W, BLOCKER_R, 1) rail2d(R);
  }
}

module index_wall() {
  x0 = wall_x(I);
  finger_wall(I, [x0, roller_x(I) + WIDTH[I]]) along_x(x0, x0 + W) plate2d(axis_z(I), [M, I]);
}

module end_wall() {
  x0 = END_WALL_X;
  difference() {
    union() {
      along_x_rounded(x0, FW, EDGE_R, 1) {
        plate2d(T, [I]);
        union() { plate2d(T, [I]); translate([LOCK_Y - EDGE_R, -10]) square([20, 100]); }
      }
      along_x(x0, FW) lock();
    }
    pole_holes(I);
    post_hole(x0, FW);
  }
}

// ---------------------------------------------------------------------------------------------
// Frame

// Anchor (Y, Z) profile: the tube plus the web joining it to the frame, without the bore. The web
// top is a radius 15 arc from the plate top tangent to the tube; its bottom an arc from the
// plate bottom tangent to the tube's lowest point.
module anchor2d() {
  c = [ANCHOR_Y, ANCHOR_Z];
  base = [FRAME_TOP, T];
  bottom = [c[0], c[1] - ANCHOR_R];
  rb = ((c[0] - FRAME_TOP) ^ 2 + bottom[1] ^ 2) / (2 * bottom[1]);
  rt = 15;
  // Top arc center: rt from the plate top corner and rt + ANCHOR_R from the tube center.
  d = norm(c - base);
  u = (c - base) / d;
  along = (rt ^ 2 - (rt + ANCHOR_R) ^ 2 + d ^ 2) / (2 * d);
  ct = base + along * u + sqrt(rt ^ 2 - along ^ 2) * [-u[1], u[0]];
  difference() {
    union() {
      translate(c) circle(ANCHOR_R);
      polygon([[FRAME_TOP, 0], base, ct + rt * (c - ct) / norm(c - ct), c, bottom, [c[0], 0]]);
    }
    translate(ct) circle(rt);
    translate([bottom[0], bottom[1] - rb]) circle(rb);
  }
}

// Crossbar and anchor (Y, Z), the web joints rounded by 3.4 as in v43.
module crossbar2d() {
  round_corners_in(3.4, [FRAME_TOP - 6, -1], [FRAME_TOP + 14, T + 1]) {
    translate([LOCK_Y, 0]) square([FRAME_TOP - LOCK_Y + eps, T]);
    anchor2d();
  }
}

// Plan (X, Y) of the anchor between its 45 degree ends, which pass through ANCHOR_X0 and ANCHOR_X1
// at the tube top.
module anchor_plan() {
  top = ANCHOR_Y + ANCHOR_R;
  polygon([[ANCHOR_X0 - (top - FRAME_TOP), FRAME_TOP], [ANCHOR_X1 + (top - FRAME_TOP), FRAME_TOP],
           [ANCHOR_X1, top], [ANCHOR_X0, top]]);
}

// Pinky column (Y, Z): the frame plate beside the pinky roller and the wall around its pole,
// joined to the plate top with POLE radius fillets.
module pinky_column2d() {
  a = axis(P);
  round2d(-POLE) union() {
    intersection() {
      round2d(3.4) translate([E, 0]) square([FRAME_TOP - E, T]);
      round2d(EDGE_R) translate([E, 0]) square([FRAME_TOP - E + 10, T]);
      translate([E, 0]) square([FRAME_TOP - E, T]);
    }
    translate([a[0] - DIAMETER[P] / 4, 0]) square([DIAMETER[P] / 2, a[1]]);
    translate(a) circle(DIAMETER[P] / 4);
  }
}

// The cord's way through the anchor: the bore, rounded where it breaks out of both ends.
module cord_path() {
  top = ANCHOR_Y + ANCHOR_R;
  translate([-1, ANCHOR_Y, ANCHOR_Z]) rotate([0, 90, 0]) cylinder(r = ANCHOR_BORE_R, h = FW + 2);
  bore_exit_round([ANCHOR_Y, ANCHOR_Z], ANCHOR_BORE_R, [ANCHOR_X0, top], [-1, 1] / sqrt(2), CORD_EXIT_R);
  bore_exit_round([ANCHOR_Y, ANCHOR_Z], ANCHOR_BORE_R, [ANCHOR_X1, top], [1, 1] / sqrt(2), CORD_EXIT_R);
}

module frame() {
  a = axis(P);
  x1 = E + WIDTH[P];
  // Where the plan fillet between the column top and the anchor end starts.
  anchor_fillet_x = ANCHOR_X0 - (ANCHOR_Y + ANCHOR_R - FRAME_TOP) - 3.4 * tan(22.5);
  difference() {
    union() {
      // Pinky column: outer face and its plan corners rounded; the wall around the pole is E thick.
      intersection() {
        union() {
          translate([-1, 0, -1]) cube([E + 1, FRAME_TOP + 1, 100]);
          translate([-1, 0, -1]) cube([x1 + 2, FRAME_TOP + 1, T + 1]);
        }
        along_x_rounded(0, x1, EDGE_R, -1) {
          pinky_column2d();
          union() { pinky_column2d(); translate([FRAME_TOP, -10]) square([20, 100]); }
        }
        translate([0, 0, -1]) linear_extrude(100) intersection() {
          round2d(E - 0.1) translate([0, E]) square([x1 + 10, FRAME_TOP]);
          round2d(3.4) translate([0, -10]) square([x1 + 10, FRAME_TOP + 10]);
          translate([0, E]) square([x1, FRAME_TOP - E]);
        }
      }
      // Crossbar and anchor, its outer end face rounded. In plan the column top meets the
      // anchor end with a 3.4 fillet; from there on the crossbar profile shapes the column top.
      // The 45 degree anchor end keeps the tube top clear of the rounded end, so the rounding
      // only needs the profile below it.
      intersection() {
        union() {
          along_x(0, FW - 3 * 3.4) crossbar2d();
          along_x_rounded(FW - 4 * 3.4, FW, 3.4, 1) {
            crossbar2d();
            intersection() {
              union() { crossbar2d(); translate([LOCK_Y - 10, -10]) square([10, 100]); }
              translate([0, -10]) square([ANCHOR_Y + 4, 100]);
            }
          }
        }
        translate([0, 0, -1]) linear_extrude(100) {
          anchor_plan();
          difference() {
            round2d(-3.4) union() { anchor_plan(); translate([0, E]) square([x1, FRAME_TOP - E]); }
            translate([0, E]) square([x1, FRAME_TOP - E]);
          }
          translate([anchor_fillet_x, LOCK_Y - 1]) square([FW, FRAME_TOP - LOCK_Y + 1]);
        }
      }
      // The pinky blocker stands on the column top, above its outer edge round.
      intersection() {
        blocker(P, 0, E + WIDTH[P] - 8);
        translate([-1, 0, T - EDGE_R]) cube([x1, FRAME_TOP, 100]);
      }
    }
    // Pocket above the pinky roller, bounded by its silhouette and the blocker.
    arc = roller_arc(WIDTH[P], roller_end_radii(P)[0], roller_end_radii(P)[1]);
    intersection() {
      translate([E, a[0], a[1] - DIAMETER[P] / 4]) cube([WIDTH[P], blocker_y(P) - a[0], 100]);
      union() {
        translate([E + arc[0], a[0] + ROLLER_WAIST + arc[1], 0]) cylinder(r = arc[1], h = 100);
        translate([E, a[0] + ROLLER_WAIST + arc[1], 0]) cube([WIDTH[P], 100, 100]);
      }
    }
    edge_round_cutter("x", E + WIDTH[P] - 8, x1 + 1, [blocker_y(P), T], BLOCKER_R, [-1, 1]);
    cradle(P);
    pole_holes(P);
    post_hole(E, x1);
    along_x(x1, FW + 1) lock();
    cord_path();
  }
}

// ---------------------------------------------------------------------------------------------
// Output

// [name, kind, finger]
PARTS = [
  ["frame", "frame"], ["ring_wall", "wall", R], ["middle_wall", "wall", M], ["index_wall", "wall", I],
  ["end_wall", "end_wall"], ["pinky_roller", "roller", P], ["ring_roller", "roller", R],
  ["middle_roller", "roller", M], ["index_roller", "roller", I], ["pinky_pin", "pin", P],
  ["ring_pin", "pin", R], ["middle_pin", "pin", M], ["index_pin", "pin", I], ["post", "post"]];
COLORS = [["frame", "gainsboro"], ["wall", "gold"], ["end_wall", "skyblue"], ["roller", "tomato"],
          ["pin", "dimgray"], ["post", "royalblue"]];

module part_in_place(p) {
  f = p[2];
  if (p[1] == "frame") frame();
  else if (p[1] == "wall") { if (f == R) ring_wall(); else if (f == M) middle_wall(); else index_wall(); }
  else if (p[1] == "end_wall") end_wall();
  else if (p[1] == "roller") roller(f);
  else if (p[1] == "pin") finger_pin(f);
  else if (p[1] == "post") post();
}

// Print pose. Frame, walls and rollers stand on their pinky-side face with the pole holes
// vertical; pins lie on their flat; the post lies on its chamfered side.
module print_pose(p) {
  f = p[2];
  if (p[1] == "post") translate([0, 0, -POST_Z - post_clearance]) children();
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
