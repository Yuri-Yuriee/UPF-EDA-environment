#!/usr/bin/env bash
set -u

VERIFY_ROOT="${1:?VERIFY_ROOT required}"
RAW_GDS="${2:?RAW GDS required}"
FINAL_GDS="${3:?FINAL DUMMY GDS required}"

DUMMY_DIR="$VERIFY_ROOT/add_dummy/build/current"
STAGE_DIR="$VERIFY_ROOT/add_dummy/.stage"

fail=0

need_file() {
    local label="$1" path="$2"
    if [[ -s "$path" ]]; then
        printf "PASS : %-12s %s\n" "$label" "$path"
    else
        printf "FAIL : %-12s %s\n" "$label" "$path"
        fail=1
    fi
}

need_marker() {
    local label="$1" path="$2"
    if [[ -f "$path" ]]; then
        printf "PASS : %-12s complete\n" "$label"
    else
        printf "FAIL : %-12s not completed\n" "$label"
        fail=1
    fi
}

echo "----------------------------------------------------------------------"
echo " DUMMY COMPLETENESS GATE"
echo "----------------------------------------------------------------------"

need_file   "RAW GDS"   "$RAW_GDS"
need_marker "BEOL"      "$STAGE_DIR/BE.done"
need_marker "COD"       "$STAGE_DIR/COD.done"
need_marker "FEOL"      "$STAGE_DIR/FE.done"
need_marker "MERGE"     "$STAGE_DIR/MERGE.done"
need_file   "BEOL GDS"  "$DUMMY_DIR/BEOL.gds"
need_file   "COD GDS"   "$DUMMY_DIR/COD.gds"
need_file   "FEOL GDS"  "$DUMMY_DIR/FEOL.gds"
need_file   "FINAL GDS" "$FINAL_GDS"

if [[ -s "$FINAL_GDS" ]]; then
    for src in "$RAW_GDS" "$DUMMY_DIR/BEOL.gds" "$DUMMY_DIR/COD.gds" "$DUMMY_DIR/FEOL.gds"; do
        if [[ -e "$src" && "$src" -nt "$FINAL_GDS" ]]; then
            echo "FAIL : FINAL GDS is older than source component: $src"
            fail=1
        fi
    done
fi

if (( fail != 0 )); then
    echo "----------------------------------------------------------------------"
    echo "DUMMY GATE: FAIL"
    echo "DRC/Antenna are BLOCKED."
    echo "Run the complete dummy flow first: make verify_dummy"
    echo "----------------------------------------------------------------------"
    exit 1
fi

echo "----------------------------------------------------------------------"
echo "DUMMY GATE: PASS"
echo "DRC/Antenna input is the fully dummy-merged GDS:"
echo "  $FINAL_GDS"
echo "----------------------------------------------------------------------"
exit 0
