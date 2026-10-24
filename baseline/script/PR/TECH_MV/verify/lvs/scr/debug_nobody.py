#!/usr/bin/env python3
"""Normalize configured body pins and MOS B terminals on copies for debug LVS.

Preserve every instance, pin interface, signal and supply/ground terminal. This is
an existing-extraction SPICE comparison, not physical verification/signoff.
"""
import json
from pathlib import Path
import re
import shlex

import os
_verify_rules_file = Path(os.environ.get("VERIFY_DEBUG_RULES_FILE", str(Path(__file__).resolve().parents[2] / "config/private/debug.rules.json")))
if not _verify_rules_file.is_file():
    raise RuntimeError("Required private Verify debug.rules.json is missing")
VERIFY_DEBUG_RULES = json.loads(_verify_rules_file.read_text())
BODY = set(VERIFY_DEBUG_RULES["body_pins"])
NODE = "__LVS_DEBUG_BODY_ONLY__"


def statements(path):
    pending = ""
    with path.open() as stream:
        for line in stream:
            line = line.strip()
            if line.startswith("+"):
                pending += " " + line[1:].strip()
            else:
                if pending:
                    yield pending
                pending = line
        if pending:
            yield pending


def prepare(root):
    out = root / "build/debug_nobody"
    required = [root / "temp/layout.spi", root / "CHIP_inc.spi",
                root / "temp/runset.generated.cmd", root / "temp/LVS_Calibre.modified"]
    # Path-only compatibility for existing extraction before staging relocation.
    legacy = [(root / "layout.spi" if (root / "layout.spi").is_file() else root / "build/extracted/layout.spi"), root / "CHIP_inc.spi",
              root / "scr/runset.generated.cmd", root / "scr/LVS_Calibre.modified"]
    required = [new if new.is_file() else old for new, old in zip(required, legacy)]
    for path in required:
        if not path.is_file():
            raise ValueError(f"Missing {path}; run LVS with VERIFY_COPY_LVS_LAYOUT_SPICE=1 and VERIFY_KEEP_LVS_STAGING=1 first.")
    # Resolve relative includes exactly as the current LVS working directory.
    documents = {}
    includes = {}

    def load(path):
        path = path.resolve(strict=True)
        if path in documents:
            return path
        documents[path] = list(statements(path))
        for i, line in enumerate(documents[path]):
            if line.upper().startswith((".INCLUDE ", ".INC ")):
                fields = shlex.split(line)
                if len(fields) != 2:
                    raise ValueError(f"Unsupported include: {line}")
                inc = Path(fields[1])
                includes[path, i] = load(inc if inc.is_absolute() else root / inc)
        return path

    layout = load(required[0])
    source = load(required[1])
    side = {}

    def mark(path, group):
        if path in side:
            return
        side[path] = group
        for (parent, _), child in includes.items():
            if parent == path:
                mark(child, group)

    mark(layout, "layout")
    mark(source, "source")
    tables = {"layout": {}, "source": {}}
    for path, lines in documents.items():
        signatures = tables[side[path]]
        for line in lines:
            fields = line.split()
            if fields and fields[0].upper() == ".SUBCKT":
                pins = []
                for pin in fields[2:]:
                    if "=" in pin or pin.upper() == "PARAMS:":
                        break
                    pins.append(pin)
                signature = (len(pins), tuple(i for i, pin in enumerate(pins)
                                             if pin.upper() in BODY))
                key = fields[1].upper()
                if key in signatures and signatures[key] != signature:
                    raise ValueError(f"Conflicting pin signatures for {fields[1]}")
                signatures[key] = signature
    # Validate all inputs before creating outputs.
    counts = {"named_body_pins": 0, "positional_body_pins": 0, "mos_bulk": 0}
    names = {path: f"netlists/{i:03d}.spi" for i, path in enumerate(documents)}
    generated = {}
    for path, lines in documents.items():
        signatures = tables[side[path]]
        result = ["* DEBUG ONLY: body connectivity normalized", f".GLOBAL {NODE}"]
        for i, line in enumerate(lines):
            if NODE in line:
                raise ValueError("Debug node name collides with an existing input")
            if (path, i) in includes:
                result.append(f'.INCLUDE "{names[includes[path, i]]}"')
                continue
            fields = line.split()
            if fields and not line.startswith(("*", "$", ".")):
                kind = fields[0][0].upper()
                if kind == "M":
                    if len(fields) < 6:
                        raise ValueError(f"Unsupported MOS statement: {line}")
                    fields[4] = NODE
                    counts["mos_bulk"] += 1
                elif kind == "X":
                    if "$PINS" in [f.upper() for f in fields]:
                        start = [f.upper() for f in fields].index("$PINS") + 1
                        for j in range(start, len(fields)):
                            pin, sep, _ = fields[j].partition("=")
                            if sep and pin.upper() in BODY:
                                fields[j] = f"{pin}={NODE}"
                                counts["named_body_pins"] += 1
                    else:
                        # Positional model precedes parameters and $ annotations.
                        end = next((j for j, f in enumerate(fields[1:], 1)
                                    if "=" in f or f.startswith("$")), len(fields))
                        model = fields[end - 1].upper()
                        if model not in signatures:
                            raise ValueError(f"Unknown positional subckt {model}: {path}")
                        n, positions = signatures[model]
                        if end - 2 != n:
                            raise ValueError(f"Pin count mismatch for {model}: {path}")
                        for j in positions:
                            fields[j + 1] = NODE
                            counts["positional_body_pins"] += 1
                line = " ".join(fields)
            result.append(line)
        generated[path] = "\n".join(result) + "\n"
    runset = required[2].read_text().replace("include ./temp/LVS_Calibre.modified",
                                                "include ./scr/LVS_Calibre.modified")
    for key, value in (("LAYOUT SYSTEM", "SPICE"),
                       ("LAYOUT PATH", f'"{names[layout]}"'),
                       ("SOURCE PATH", f'"{names[source]}"')):
        runset, n = re.subn(rf"^{key}\s+.*$", f"{key} {value}", runset, flags=re.M)
        if n != 1:
            raise ValueError(f"Expected one {key} statement")
    out.mkdir(parents=True, exist_ok=True)
    (out / "netlists").mkdir(exist_ok=True)
    (out / "scr").mkdir(exist_ok=True)
    (out / "output").mkdir(exist_ok=True)
    for path, content in generated.items():
        (out / names[path]).write_text(content)
    (out / "scr/LVS_Calibre.modified").write_bytes(required[3].read_bytes())
    (out / "runset.cmd").write_text("// DEBUG ONLY: not signoff LVS\n" + runset)
    (out / "normalization.json").write_text(json.dumps({
        "counts": counts, "inputs": {names[p]: str(p) for p in names},
        "scope": VERIFY_DEBUG_RULES["body_scope_description"]
    }, indent=2) + "\n")
    print(f"Prepared {out}: {counts}")


if __name__ == "__main__":
    try:
        prepare(Path.cwd())
    except (OSError, ValueError) as error:
        raise SystemExit(f"ERROR: {error}")
