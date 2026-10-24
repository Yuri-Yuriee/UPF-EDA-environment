#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# TECH_MV flow sync packer
# Purpose:
#   Collect the CURRENT flow/source/config/tool files for ChatGPT review/sync.
#   This script is READ-ONLY with respect to the design database and flow data.
#
# Run from anywhere:
#   bash pack_tech_mv_sync.sh
#
# Optional:
#   BASELINE=/path/to/baseline bash pack_tech_mv_sync.sh
#   OUTDIR=/path/to/output   bash pack_tech_mv_sync.sh
# ==============================================================================

SH_PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DEFAULT_BASELINE="$SH_PROJECT_ROOT"
BASELINE="${BASELINE:-$DEFAULT_BASELINE}"
OUTDIR="${OUTDIR:-$BASELINE/temp/sync_export}"
STAMP="$(date +%Y%m%d_%H%M%S)"
PKG_NAME="TECH_MV_SYNC_${STAMP}"
TMP_ROOT="$(mktemp -d /tmp/${PKG_NAME}.XXXXXX)"
STAGE="$TMP_ROOT/$PKG_NAME"
ARCHIVE="$OUTDIR/${PKG_NAME}.tar.gz"
SHA_FILE="$ARCHIVE.sha256"

cleanup() {
    rm -rf "$TMP_ROOT"
}
trap cleanup EXIT

if [[ ! -d "$BASELINE" ]]; then
    echo "[ERROR] baseline not found: $BASELINE" >&2
    exit 1
fi

mkdir -p "$OUTDIR" "$STAGE"

# Copy helper: preserve path relative to baseline, skip missing paths.
copy_rel() {
    local rel="$1"
    local src="$BASELINE/$rel"
    if [[ ! -e "$src" ]]; then
        echo "[SKIP] missing: $rel"
        return 0
    fi

    local dst="$STAGE/$rel"
    mkdir -p "$(dirname "$dst")"
    if [[ -d "$src" ]]; then
        mkdir -p "$dst"
        rsync -a --exclude=/config/private/ "$src/" "$dst/"
    else
        cp -a "$src" "$dst"
    fi
    echo "[ADD ] $rel"
}

# ------------------------------------------------------------------------------
# Authoritative runtime / setup / main-script content.
# Intentionally excludes DBs, reports, logs, outputs, temp, backups, and large
# generated physical-design artifacts.
# ------------------------------------------------------------------------------
copy_rel "Makefile"
copy_rel "tools/organize_pr_outputs.py"
copy_rel "temp_doc/clean_root_debug.py"
copy_rel "back.tcl"

copy_rel "build_PR/init.setup"
copy_rel "build_PR/setup"

# Run Tcl entry points and runtime tools. Avoid DB/report/output payloads.
if [[ -d "$BASELINE/build_PR/run" ]]; then
    mkdir -p "$STAGE/build_PR/run"
    find "$BASELINE/build_PR/run" -maxdepth 1 -type f \
        \( -name '*.tcl' -o -name '*.setup' -o -name '*.cfg' -o -name '*.conf' -o -name 'Makefile' \) \
        -print0 | while IFS= read -r -d '' f; do
            rel="${f#$BASELINE/}"
            copy_rel "$rel"
        done
fi
copy_rel "build_PR/run/tool"

# Shared/main script authority.
copy_rel "script/PR/TECH_MV/script"

# Tool mirror, if present.
copy_rel "script/PR/TECH_MV/run/tool"

# Useful top-level flow/control files when present.
for rel in \
    "script/PR/TECH_MV/Makefile" \
    "script/PR/TECH_MV/makefile" \
    "script/PR/TECH_MV/README" \
    "script/PR/TECH_MV/README.md"
do
    copy_rel "$rel"
done

# ------------------------------------------------------------------------------
# Remove obviously generated/heavy content that may live below copied tool dirs.
# Keep source/config/scripts, but strip common transient directories/files.
# ------------------------------------------------------------------------------
find "$STAGE" -type d \( \
    -name .git -o \
    -name __pycache__ -o \
    -name .pytest_cache -o \
    -name node_modules \
\) -prune -exec rm -rf {} + 2>/dev/null || true

find "$STAGE" -type f \( \
    -name '*.log' -o \
    -name '*.fsdb' -o \
    -name '*.vcd' -o \
    -name '*.vpd' -o \
    -name '*.trn' -o \
    -name '*.dsn' -o \
    -name '*.spef' -o \
    -name '*.sdf' -o \
    -name '*.gds' -o \
    -name '*.gds.gz' -o \
    -name '*.db' -o \
    -name '*.dat' -o \
    -name 'core.*' \
\) -delete 2>/dev/null || true

# ------------------------------------------------------------------------------
# Metadata / manifest for synchronization.
# ------------------------------------------------------------------------------
{
    echo "TECH_MV FLOW SYNC PACKAGE"
    echo "created_at=$(date -Iseconds)"
    echo "hostname=$(hostname 2>/dev/null || true)"
    echo "user=$(id -un 2>/dev/null || true)"
    echo "baseline=$BASELINE"
    echo "pwd=$(pwd)"
    echo
    echo "Included authority:"
    echo "  build_PR/init.setup"
    echo "  build_PR/setup/"
    echo "  build_PR/run/*.tcl + build_PR/run/tool/"
    echo "  script/PR/TECH_MV/script/"
    echo "  script/PR/TECH_MV/run/tool/ (if present)"
    echo "  Makefile / back.tcl (if present)"
    echo
    echo "Excluded on purpose:"
    echo "  build_PR/dbs, outputs, reports, logs, temp"
    echo "  baseline/backup"
    echo "  waveform / GDS / DB / log artifacts"
} > "$STAGE/SYNC_INFO.txt"

# Git metadata only; do not package .git itself.
if command -v git >/dev/null 2>&1 && git -C "$BASELINE" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    {
        echo "git_top=$(git -C "$BASELINE" rev-parse --show-toplevel)"
        echo "git_head=$(git -C "$BASELINE" rev-parse HEAD 2>/dev/null || true)"
        echo "git_branch=$(git -C "$BASELINE" branch --show-current 2>/dev/null || true)"
        echo
        echo "--- git status --short ---"
        git -C "$BASELINE" status --short 2>/dev/null || true
    } > "$STAGE/GIT_STATUS.txt"
fi

(
    cd "$STAGE"
    find . -type f -print | LC_ALL=C sort > FILE_LIST.txt

    if command -v sha256sum >/dev/null 2>&1; then
        while IFS= read -r f; do
            f="${f#./}"
            [[ "$f" == "SHA256SUMS.txt" ]] && continue
            sha256sum "$f"
        done < FILE_LIST.txt > SHA256SUMS.txt
    fi
)

# Create archive.
tar -C "$TMP_ROOT" -czf "$ARCHIVE" "$PKG_NAME"

if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$ARCHIVE" > "$SHA_FILE"
fi

# Final report.
echo
echo "======================================================================"
echo " TECH_MV SYNC PACKAGE READY"
echo "======================================================================"
echo "Baseline : $BASELINE"
echo "Archive  : $ARCHIVE"
if [[ -f "$SHA_FILE" ]]; then
    echo "SHA256   : $SHA_FILE"
fi
printf "Files     : "
tar -tzf "$ARCHIVE" | grep -v '/$' | wc -l
echo "Size      : $(du -h "$ARCHIVE" | awk '{print $1}')"
echo "======================================================================"
echo "Upload the .tar.gz file to ChatGPT for synchronization/review."
