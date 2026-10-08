"""Export every part of an OpenGrips OpenSCAD model as print-ready STLs.

Usage:
    python3 export.py prometheus PARAMS --hand right
    python3 export.py sisyphus --hand left --out DIR

PARAMS (optional) holds `Name = value` lines, `#` lines ignored, e.g. the output of
../prometheus-fit/measure-hand.html; names must be parameters of the model. The STLs, named
<model>_<hand>_<part>.stl, go to --out, by default next to PARAMS (or the current directory).
"""

import argparse
import re
import shutil
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

HERE = Path(__file__).resolve().parent
PARTS = [
    "frame",
    "ring_wall",
    "middle_wall",
    "index_wall",
    "end_wall",
    "pinky_roller",
    "ring_roller",
    "middle_roller",
    "index_roller",
    "pinky_pin",
    "ring_pin",
    "middle_pin",
    "index_pin",
    "post",
]


def model_parameters(scad):
    """Names assigned at the top of the model, before its hidden section."""
    text = scad.read_text().split("/* [Hidden] */")[0]
    return set(re.findall(r"^(\w+)\s*=", text, re.MULTILINE))


def read_params(path, allowed):
    params = {}
    for line in path.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        match = re.fullmatch(r"(\w+)\s*=\s*(-?[\d.]+)", line)
        if not match:
            raise SystemExit(f"{path}: cannot parse line: {line}")
        if match[1] not in allowed:
            raise SystemExit(f"{path}: {match[1]} is not a parameter of the model")
        params[match[1]] = match[2]
    return params


def export(openscad, scad, part, hand, params, path):
    defines = [f"-D{k}={v}" for k, v in params.items()] + [f'-Dpart="{part}"', f'-Dhand="{hand}"']
    result = subprocess.run(
        [openscad, "--backend", "Manifold", "-o", str(path), *defines, str(scad)],
        capture_output=True,
        text=True,
        check=False,
    )
    errors = [line for line in result.stderr.splitlines() if line.startswith(("ERROR", "WARNING"))]
    if result.returncode or errors:
        raise SystemExit(f"{part}: openscad failed:\n" + "\n".join(errors or result.stderr.splitlines()[-5:]))
    return path


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("model", choices=("prometheus", "sisyphus"))
    parser.add_argument("params", type=Path, nargs="?")
    parser.add_argument("--hand", choices=("left", "right"), required=True)
    parser.add_argument("--out", type=Path)
    args = parser.parse_args()

    openscad = shutil.which("openscad") or "/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD"
    if not Path(openscad).exists():
        sys.exit("openscad not found; install OpenSCAD (2025 or newer, for the Manifold backend)")
    scad = HERE / f"{args.model}.scad"
    params = read_params(args.params, model_parameters(scad)) if args.params else {}
    out = args.out or (args.params.parent if args.params else Path.cwd())
    out.mkdir(parents=True, exist_ok=True)
    with ThreadPoolExecutor() as pool:
        jobs = [
            pool.submit(export, openscad, scad, part, args.hand, params, out / f"{args.model}_{args.hand}_{part}.stl")
            for part in PARTS
        ]
        for job in jobs:
            print(job.result())


if __name__ == "__main__":
    main()
