// Illustrations of the assembly steps, from the in-place STLs of ../../openscad/export.py --in-place.
// render.sh sets stl and either part (one part alone) or step (1 to 9, 10 the finished grip).

stl = "/tmp/prometheus_in_place/prometheus_right_";
part = "";
step = 1;

// Parts added at each step and where they wait before moving in: walls, pins and the post come
// from the index side (-X on the right hand), rollers from above.
STEPS = [
  [["pinky_roller", [0, 0, 35]], ["pinky_pin", [-50, 0, 35]]],
  [["ring_wall", [-40, 0, 0]]],
  [["ring_roller", [0, 0, 30]], ["ring_pin", [-40, 0, 30]]],
  [["middle_wall", [-40, 0, 0]]],
  [["middle_roller", [0, 0, 30]], ["middle_pin", [-40, 0, 30]]],
  [["index_wall", [-40, 0, 0]]],
  [["index_roller", [0, 0, 30]], ["index_pin", [-40, 0, 30]]],
  [["end_wall", [-40, 0, 0]]],
  [["post", [-80, 0, 0]]],
];

module show(name, c) {
  color(c) import(str(stl, name, ".stl"));
}

if (part != "") {
  show(part, "tomato");
} else {
  show("frame", "gainsboro");
  for (i = [0:min(step, len(STEPS)) - 1], p = STEPS[i])
    if (i == step - 1) translate(p[1]) show(p[0], "tomato");
    else show(p[0], "gainsboro");
}
