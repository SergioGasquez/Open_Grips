const FINGERS = ["Index", "Middle", "Ring", "Pinky"];

const DEFAULTS = {
  left: [
    { full: 73, pipDip: 23, dipTip: 25, angle: 57 },
    { full: 78, pipDip: 28, dipTip: 25, angle: 60 },
    { full: 70, pipDip: 25, dipTip: 27, angle: 60 },
    { full: 60, pipDip: 18, dipTip: 24, angle: 55 },
  ],
  right: [
    { full: 71, pipDip: 22, dipTip: 24, angle: 57 },
    { full: 80, pipDip: 27, dipTip: 25, angle: 60 },
    { full: 72, pipDip: 25, dipTip: 26, angle: 60 },
    { full: 60, pipDip: 18, dipTip: 24, angle: 55 },
  ],
};

const BASE_PARAMS = {
  stationDepth: 30,
  wallThickness: 4,
  baseThickness: 7,
  baseMarginX: 18,
  baseMarginY: 18,
  rollerLength: 12,
  pinClearance: 0.35,
  roofThickness: 4,
  roofDepth: 16,
  roofOverhangY: 4,
  roofSupportExtraHeight: 8,
};

const el = (id) => document.getElementById(id);
const degToRad = (deg) => (deg * Math.PI) / 180;
const round2 = (n) => Math.round(n * 100) / 100;

function numberValue(id) {
  const value = Number(el(id).value);
  if (!Number.isFinite(value)) throw new Error(`Invalid value for ${id}`);
  return value;
}

function buildMeasurementRows() {
  const tbody = document.querySelector("#measurements tbody");
  tbody.innerHTML = "";

  FINGERS.forEach((finger, i) => {
    const tr = document.createElement("tr");
    tr.innerHTML = `
      <td>${finger}</td>
      <td><input data-finger="${i}" data-field="full" type="number" min="30" max="140" step="0.1"></td>
      <td><input data-finger="${i}" data-field="pipDip" type="number" min="5" max="60" step="0.1"></td>
      <td><input data-finger="${i}" data-field="dipTip" type="number" min="5" max="60" step="0.1"></td>
      <td><input data-finger="${i}" data-field="angle" type="number" min="35" max="80" step="0.1"></td>
    `;
    tbody.appendChild(tr);
  });
}

function loadDefaults() {
  const hand = el("hand").value;
  DEFAULTS[hand].forEach((row, i) => {
    for (const field of ["full", "pipDip", "dipTip", "angle"]) {
      document.querySelector(`input[data-finger="${i}"][data-field="${field}"]`).value = row[field];
    }
  });
  updateComputedTable();
}

function readMeasurements() {
  return FINGERS.map((_, i) => {
    const row = {};
    for (const field of ["full", "pipDip", "dipTip", "angle"]) {
      const input = document.querySelector(`input[data-finger="${i}"][data-field="${field}"]`);
      const value = Number(input.value);
      if (!Number.isFinite(value) || value <= 0) {
        throw new Error(`Invalid ${FINGERS[i]} ${field} measurement`);
      }
      row[field] = value;
    }
    return row;
  });
}

function readParams() {
  return {
    ...BASE_PARAMS,
    fingerSpacing: numberValue("fingerSpacing"),
    channelWidth: numberValue("channelWidth"),
    rollerDiameter: numberValue("rollerDiameter"),
    pinDiameter: numberValue("pinDiameter"),
    segments: Number(el("quality").value),
  };
}

function computeValues(measurements) {
  const pinky = measurements[3];
  return measurements.map((m) => ({
    vertical: m.full - pinky.full,
    horizontal: m.pipDip - pinky.pipDip,
    roof: m.dipTip / Math.tan(degToRad(m.angle)),
  }));
}

function updateComputedTable() {
  try {
    const measurements = readMeasurements();
    const values = computeValues(measurements);
    const tbody = document.querySelector("#computed tbody");
    tbody.innerHTML = "";
    values.forEach((v, i) => {
      const tr = document.createElement("tr");
      tr.innerHTML = `
        <td>${FINGERS[i]}</td>
        <td>${round2(v.vertical)} mm</td>
        <td>${round2(v.horizontal)} mm</td>
        <td>${round2(v.roof)} mm</td>
      `;
      tbody.appendChild(tr);
    });
    setStatus("");
  } catch (err) {
    setStatus(err.message);
  }
}

function setStatus(message) {
  el("status").textContent = message || "";
}

function createMesh() {
  return { triangles: [] };
}

function addTri(mesh, a, b, c) {
  mesh.triangles.push([a, b, c]);
}

function addQuad(mesh, a, b, c, d) {
  addTri(mesh, a, b, c);
  addTri(mesh, a, c, d);
}

function addBox(mesh, min, size) {
  const [x, y, z] = min;
  const [w, d, h] = size;
  const p = [
    [x, y, z], [x + w, y, z], [x + w, y + d, z], [x, y + d, z],
    [x, y, z + h], [x + w, y, z + h], [x + w, y + d, z + h], [x, y + d, z + h],
  ];
  addQuad(mesh, p[0], p[1], p[2], p[3]);
  addQuad(mesh, p[4], p[7], p[6], p[5]);
  addQuad(mesh, p[0], p[4], p[5], p[1]);
  addQuad(mesh, p[1], p[5], p[6], p[2]);
  addQuad(mesh, p[2], p[6], p[7], p[3]);
  addQuad(mesh, p[3], p[7], p[4], p[0]);
}

function addCylinderX(mesh, center, radius, length, segments = 32) {
  const [cx, cy, cz] = center;
  const x0 = cx - length / 2;
  const x1 = cx + length / 2;
  const c0 = [x0, cy, cz];
  const c1 = [x1, cy, cz];
  for (let i = 0; i < segments; i += 1) {
    const a0 = (2 * Math.PI * i) / segments;
    const a1 = (2 * Math.PI * (i + 1)) / segments;
    const p0 = [x0, cy + radius * Math.cos(a0), cz + radius * Math.sin(a0)];
    const p1 = [x0, cy + radius * Math.cos(a1), cz + radius * Math.sin(a1)];
    const p2 = [x1, cy + radius * Math.cos(a1), cz + radius * Math.sin(a1)];
    const p3 = [x1, cy + radius * Math.cos(a0), cz + radius * Math.sin(a0)];
    addQuad(mesh, p0, p1, p2, p3);
    addTri(mesh, c0, p1, p0);
    addTri(mesh, c1, p3, p2);
  }
}

function rayToRect(cy, cz, angle, y0, y1, z0, z1) {
  const dy = Math.cos(angle);
  const dz = Math.sin(angle);
  const candidates = [];
  if (Math.abs(dy) > 1e-9) {
    candidates.push((y0 - cy) / dy, (y1 - cy) / dy);
  }
  if (Math.abs(dz) > 1e-9) {
    candidates.push((z0 - cz) / dz, (z1 - cz) / dz);
  }

  let best = Infinity;
  for (const t of candidates) {
    if (t <= 0 || t >= best) continue;
    const y = cy + t * dy;
    const z = cz + t * dz;
    if (y >= y0 - 1e-6 && y <= y1 + 1e-6 && z >= z0 - 1e-6 && z <= z1 + 1e-6) best = t;
  }
  return [cy + best * dy, cz + best * dz];
}

function uniqueSortedAngles(angles) {
  return [...new Set(angles.map((a) => {
    const normalized = ((a % (2 * Math.PI)) + 2 * Math.PI) % (2 * Math.PI);
    return Math.round(normalized * 1_000_000) / 1_000_000;
  }))].sort((a, b) => a - b);
}

function addHoledSlabX(mesh, x0, x1, y0, y1, z0, z1, cy, cz, radius, segments = 32) {
  const margin = 0.4;
  const safeRadius = Math.max(0.1, Math.min(radius, cy - y0 - margin, y1 - cy - margin, cz - z0 - margin, z1 - cz - margin));
  if (!Number.isFinite(safeRadius) || safeRadius <= 0.1) {
    addBox(mesh, [x0, y0, z0], [x1 - x0, y1 - y0, z1 - z0]);
    return;
  }

  const angles = [];
  for (let i = 0; i < segments; i += 1) angles.push((2 * Math.PI * i) / segments);
  for (const yy of [y0, y1]) {
    for (const zz of [z0, z1]) angles.push(Math.atan2(zz - cz, yy - cy));
  }
  const sorted = uniqueSortedAngles(angles);
  const inner = sorted.map((a) => [cy + safeRadius * Math.cos(a), cz + safeRadius * Math.sin(a)]);
  const outer = sorted.map((a) => rayToRect(cy, cz, a, y0, y1, z0, z1));

  for (let i = 0; i < sorted.length; i += 1) {
    const j = (i + 1) % sorted.length;
    const i0 = [x0, inner[i][0], inner[i][1]];
    const i1 = [x0, inner[j][0], inner[j][1]];
    const o0 = [x0, outer[i][0], outer[i][1]];
    const o1 = [x0, outer[j][0], outer[j][1]];
    const i0b = [x1, inner[i][0], inner[i][1]];
    const i1b = [x1, inner[j][0], inner[j][1]];
    const o0b = [x1, outer[i][0], outer[i][1]];
    const o1b = [x1, outer[j][0], outer[j][1]];

    // Annular end faces.
    addQuad(mesh, o0, o1, i1, i0);
    addQuad(mesh, o0b, i0b, i1b, o1b);
    // Outer and inner side walls.
    addQuad(mesh, o0, o0b, o1b, o1);
    addQuad(mesh, i0, i1, i1b, i0b);
  }
}

function stationX(i, p) {
  return (i - 1.5) * p.fingerSpacing;
}

function buildFrameMesh(measurements, params) {
  const mesh = createMesh();
  const computed = computeValues(measurements);
  const p = params;
  const maxHorizontal = Math.max(...computed.map((v) => v.horizontal));
  const baseWidth = 3 * p.fingerSpacing + p.channelWidth + 2 * p.wallThickness + 2 * p.baseMarginX;
  const baseDepth = p.stationDepth + maxHorizontal + 2 * p.baseMarginY;
  const stationWidth = p.channelWidth + 2 * p.wallThickness;
  const rollerCenterZBase = p.baseThickness + p.rollerDiameter / 2 + 3;

  addBox(mesh, [-baseWidth / 2, -baseDepth / 2, 0], [baseWidth, baseDepth, p.baseThickness]);

  for (let i = 0; i < FINGERS.length; i += 1) {
    const c = [stationX(i, p), computed[i].horizontal, rollerCenterZBase + computed[i].vertical];
    const roofZ = c[2] + computed[i].roof;
    const totalHeight = roofZ + p.roofThickness + p.roofSupportExtraHeight;
    const sideHeight = totalHeight - p.baseThickness;
    const x0 = c[0] - stationWidth / 2;
    const x1 = c[0] + stationWidth / 2;
    const y0 = c[1] - p.stationDepth / 2;
    const y1 = c[1] + p.stationDepth / 2;
    const z0 = p.baseThickness;
    const z1 = p.baseThickness + sideHeight;
    const holeRadius = (p.pinDiameter + p.pinClearance) / 2;

    addHoledSlabX(mesh, x0, x0 + p.wallThickness, y0, y1, z0, z1, c[1], c[2], holeRadius, p.segments);
    addHoledSlabX(mesh, x1 - p.wallThickness, x1, y0, y1, z0, z1, c[1], c[2], holeRadius, p.segments);
    addBox(mesh, [x0, y1 - p.wallThickness, z0], [stationWidth, p.wallThickness, sideHeight]);
    addBox(mesh, [x0, y0 - p.roofOverhangY, roofZ], [stationWidth, p.roofDepth, p.roofThickness]);
    addBox(mesh, [x0, y0, z0], [stationWidth, p.wallThickness, p.wallThickness]);
  }

  return mesh;
}

function buildRollersMesh(params) {
  const mesh = createMesh();
  const pitch = params.rollerDiameter + 5;
  for (let i = 0; i < 4; i += 1) {
    addCylinderX(mesh, [0, i * pitch, params.rollerDiameter / 2], params.rollerDiameter / 2, params.rollerLength, params.segments);
  }
  return mesh;
}

function buildPinsMesh(params) {
  const mesh = createMesh();
  const pinLength = params.channelWidth + 2 * params.wallThickness + 2;
  const pitch = params.pinDiameter + 5;
  for (let i = 0; i < 4; i += 1) {
    addCylinderX(mesh, [0, i * pitch, params.pinDiameter / 2], params.pinDiameter / 2, pinLength, params.segments);
  }
  return mesh;
}

function appendMesh(target, source) {
  target.triangles.push(...source.triangles);
}

function transformMesh(mesh, fn) {
  mesh.triangles = mesh.triangles.map((tri) => tri.map(fn));
  return mesh;
}

function buildSelectedMesh() {
  const measurements = readMeasurements();
  const params = readParams();
  const model = el("model").value;
  const hand = el("hand").value;
  const part = el("part").value;

  let mesh;
  if (part === "frame") mesh = buildFrameMesh(measurements, params);
  else if (part === "rollers") mesh = buildRollersMesh(params);
  else if (part === "pins") mesh = buildPinsMesh(params);
  else {
    mesh = buildFrameMesh(measurements, params);
    const rollers = transformMesh(buildRollersMesh(params), ([x, y, z]) => [x - 60, y - 10, z]);
    const pins = transformMesh(buildPinsMesh(params), ([x, y, z]) => [x + 60, y - 10, z]);
    appendMesh(mesh, rollers);
    appendMesh(mesh, pins);
  }

  if (model === "sisyphus") {
    transformMesh(mesh, ([x, y, z]) => [x * 1.08, y * 1.18, z]);
  }
  if (hand === "right") {
    transformMesh(mesh, ([x, y, z]) => [-x, y, z]);
  }

  return { mesh, measurements, params, model, hand, part };
}

function sub(a, b) {
  return [a[0] - b[0], a[1] - b[1], a[2] - b[2]];
}

function cross(a, b) {
  return [
    a[1] * b[2] - a[2] * b[1],
    a[2] * b[0] - a[0] * b[2],
    a[0] * b[1] - a[1] * b[0],
  ];
}

function normalize(v) {
  const len = Math.hypot(v[0], v[1], v[2]) || 1;
  return [v[0] / len, v[1] / len, v[2] / len];
}

function stlFromMesh(mesh, name = "open_grips") {
  const lines = [`solid ${name}`];
  for (const tri of mesh.triangles) {
    const n = normalize(cross(sub(tri[1], tri[0]), sub(tri[2], tri[0])));
    lines.push(`  facet normal ${n[0]} ${n[1]} ${n[2]}`);
    lines.push("    outer loop");
    for (const v of tri) lines.push(`      vertex ${round2(v[0])} ${round2(v[1])} ${round2(v[2])}`);
    lines.push("    endloop");
    lines.push("  endfacet");
  }
  lines.push(`endsolid ${name}`);
  return lines.join("\n");
}

function downloadText(filename, text, mime) {
  const blob = new Blob([text], { type: mime });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = filename;
  document.body.appendChild(a);
  a.click();
  a.remove();
  URL.revokeObjectURL(url);
}

function downloadStl() {
  try {
    setStatus("Generating STL...");
    const result = buildSelectedMesh();
    const name = `open-grips-${result.model}-${result.hand}-${result.part}`;
    const stl = stlFromMesh(result.mesh, name);
    downloadText(`${name}.stl`, stl, "model/stl");
    setStatus(`Downloaded ${name}.stl with ${result.mesh.triangles.length} triangles.`);
  } catch (err) {
    setStatus(err.message);
  }
}

function downloadJson() {
  try {
    const measurements = readMeasurements();
    const params = readParams();
    const data = {
      model: el("model").value,
      hand: el("hand").value,
      part: el("part").value,
      fingers: FINGERS.map((finger, i) => ({ finger, ...measurements[i] })),
      computed: computeValues(measurements),
      geometry: params,
    };
    downloadText("open-grips-measurements.json", JSON.stringify(data, null, 2), "application/json");
  } catch (err) {
    setStatus(err.message);
  }
}

function init() {
  buildMeasurementRows();
  loadDefaults();
  el("loadDefaults").addEventListener("click", loadDefaults);
  el("downloadStl").addEventListener("click", downloadStl);
  el("downloadJson").addEventListener("click", downloadJson);
  el("hand").addEventListener("change", loadDefaults);
  document.querySelectorAll("input, select").forEach((input) => {
    input.addEventListener("input", updateComputedTable);
    input.addEventListener("change", updateComputedTable);
  });
}

init();
