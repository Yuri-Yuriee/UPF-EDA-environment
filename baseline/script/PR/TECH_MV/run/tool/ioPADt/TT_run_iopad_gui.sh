#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GUI="${SCRIPT_DIR}/TT_tool_iopad_gui.py"

choose_python() {
    local candidate=""

    if [[ -n "${TT_IOPAD_PYTHON:-}" ]]; then
        candidate="${TT_IOPAD_PYTHON}"

        if "${candidate}" - <<'PY' >/dev/null 2>&1
import sys
import tkinter
assert sys.version_info >= (3, 8)
PY
        then
            printf '%s\n' "${candidate}"
            return 0
        fi

        echo "ERROR: TT_IOPAD_PYTHON=${candidate} is not Python >=3.8 with tkinter." >&2
        return 1
    fi

    # Prefer OS Python to avoid inheriting EDA vendor Python packages.
    for candidate in /usr/bin/python3 "$(command -v python3 2>/dev/null || true)"; do
        [[ -n "${candidate}" ]] || continue
        [[ -x "${candidate}" ]] || continue

        if "${candidate}" - <<'PY' >/dev/null 2>&1
import sys
import tkinter
assert sys.version_info >= (3, 8)
PY
        then
            printf '%s\n' "${candidate}"
            return 0
        fi
    done

    return 1
}

PYTHON_BIN="$(choose_python || true)"

if [[ -z "${PYTHON_BIN}" ]]; then
    echo "ERROR: no Python >=3.8 with tkinter was found." >&2
    echo "       You may set TT_IOPAD_PYTHON=/path/to/python3." >&2
    exit 1
fi

if [[ -z "${DISPLAY:-}" ]]; then
    echo "WARNING: DISPLAY is empty. Tk GUI may not open." >&2
fi

if [[ -n "${INNOVUS_WORK_DIR:-}" ]]; then
    BRIDGE_DIR="${INNOVUS_WORK_DIR}/.tt_iopad_bridge"
else
    BRIDGE_DIR="$(pwd)/.tt_iopad_bridge"
fi

PYTHON_VERSION="$("${PYTHON_BIN}" - <<'PY'
import sys
print("%d.%d.%d" % sys.version_info[:3])
PY
)"

echo "TECH_MV IOPAD GUI"
echo "GUI       : ${GUI}"
echo "Bridge dir: ${BRIDGE_DIR}"
echo "Python    : ${PYTHON_BIN} (${PYTHON_VERSION})"

"${PYTHON_BIN}" - <<'PY'
import sys
import tkinter
print("Python preflight: PASS")
print("Executable       :", sys.executable)
print("Tk version       :", tkinter.TkVersion)
PY

exec "${PYTHON_BIN}" "${GUI}"
