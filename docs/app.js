const FINGERS = ["Index", "Middle", "Ring", "Pinky"];
const FINGER_CODES = ["I", "M", "R", "P"];

const FREECAD_TEMPLATES = {
  prometheus: {
    url: "templates/OpenGrips_Prometheus.FCStd",
    label: "Prometheus",
  },
  sisyphus: {
    url: "templates/OpenGrips_Sisyphus.FCStd",
    label: "Sisyphus",
  },
};

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

const el = (id) => document.getElementById(id);
const degToRad = (deg) => (deg * Math.PI) / 180;
const round2 = (n) => Math.round(n * 100) / 100;

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

function computeValues(measurements) {
  const pinky = measurements[3];
  return measurements.map((m) => ({
    vertical: m.full - pinky.full,
    horizontal: m.pipDip - pinky.pipDip,
    roof: m.dipTip / Math.tan(degToRad(m.angle)),
  }));
}

function setStatus(message) {
  el("status").textContent = message || "";
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

function downloadBlob(filename, blob) {
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = filename;
  document.body.appendChild(a);
  a.click();
  a.remove();
  URL.revokeObjectURL(url);
}

function downloadText(filename, text, mime) {
  downloadBlob(filename, new Blob([text], { type: mime }));
}

function buildCustomizationData(measurements) {
  return {
    model: el("model").value,
    hand: el("hand").value,
    fingers: FINGERS.map((finger, i) => ({ finger, ...measurements[i] })),
    computed: computeValues(measurements),
  };
}

function downloadJson() {
  try {
    const measurements = readMeasurements();
    downloadText("open-grips-measurements.json", JSON.stringify(buildCustomizationData(measurements), null, 2), "application/json");
  } catch (err) {
    setStatus(err.message);
  }
}

function freecadVarName(model, code, suffix) {
  if (model === "prometheus") return `Base_${code}_${suffix}`;
  return `Base_${code}_${suffix.toLowerCase()}`;
}

function buildFreecadVariableMap(model, computed) {
  const values = {};
  computed.forEach((value, i) => {
    const code = FINGER_CODES[i];
    values[freecadVarName(model, code, "Height")] = value.vertical;

    if (model === "prometheus") {
      values[freecadVarName(model, code, "Depth")] = value.horizontal;
      values[freecadVarName(model, code, "To_Blocker")] = value.roof;
    } else {
      values[freecadVarName(model, code, "Blocker")] = value.horizontal;
    }
  });
  return values;
}

function escapeRegExp(text) {
  return text.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

function patchFreecadDocumentXml(xml, variables) {
  let patched = xml;
  const missing = [];

  Object.entries(variables).forEach(([name, value]) => {
    const pattern = new RegExp(`(<Property name="${escapeRegExp(name)}"[^>]*>\\s*<Float value=")([^"]*)("/>\\s*</Property>)`);
    if (!pattern.test(patched)) {
      missing.push(name);
      return;
    }
    patched = patched.replace(pattern, (_, before, __oldValue, after) => `${before}${Number(value).toFixed(6)}${after}`);
  });

  return { xml: patched, missing };
}

async function downloadFreecad() {
  try {
    if (typeof JSZip === "undefined") {
      throw new Error("Could not load JSZip. Check your internet connection and reload the page.");
    }

    const model = el("model").value;
    const hand = el("hand").value;
    const template = FREECAD_TEMPLATES[model];
    const measurements = readMeasurements();
    const computed = computeValues(measurements);
    const variables = buildFreecadVariableMap(model, computed);

    setStatus(`Loading original ${template.label} FreeCAD template...`);
    const response = await fetch(template.url);
    if (!response.ok) throw new Error(`Could not load ${template.url}`);

    const zip = await JSZip.loadAsync(await response.arrayBuffer());
    const documentFile = zip.file("Document.xml");
    if (!documentFile) throw new Error("Template is not a valid FreeCAD .FCStd document.");

    const documentXml = await documentFile.async("string");
    const patched = patchFreecadDocumentXml(documentXml, variables);
    if (patched.missing.length) {
      throw new Error(`The published template does not match the selected ${model} model. Missing variables: ${patched.missing.join(", ")}`);
    }

    zip.file("Document.xml", patched.xml);
    zip.file("open-grips-customization.json", JSON.stringify({
      ...buildCustomizationData(measurements),
      freecadVariables: variables,
      sourceTemplate: template.url,
      note: "Patched in the browser from the published FreeCAD template. Open this FCStd in FreeCAD, recompute if prompted, then export STL/STEP.",
    }, null, 2));

    setStatus("Generating customized FreeCAD file...");
    const blob = await zip.generateAsync({ type: "blob", compression: "DEFLATE" });
    const filename = `open-grips-${model}-${hand}-custom.FCStd`;
    downloadBlob(filename, blob);
    setStatus(`Downloaded ${filename}. Open it in FreeCAD and export final STL/STEP.`);
  } catch (err) {
    setStatus(err.message);
  }
}

function init() {
  buildMeasurementRows();
  loadDefaults();
  el("loadDefaults").addEventListener("click", loadDefaults);
  el("downloadFreecad").addEventListener("click", downloadFreecad);
  el("downloadJson").addEventListener("click", downloadJson);
  el("hand").addEventListener("change", loadDefaults);
  document.querySelectorAll("input, select").forEach((input) => {
    input.addEventListener("input", updateComputedTable);
    input.addEventListener("change", updateComputedTable);
  });
}

init();
