#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# sync_build_PR_to_TECH_MV_v3.sh
#
# Synchronize latest TECH_MV runtime state from build_PR back to master.
#
# Authority / policy:
#
#   build_PR/init.setup  -> script/PR/TECH_MV/init.setup
#   build_PR/setup/      -> script/PR/TECH_MV/setup/      (full mirror)
#   build_PR/run/        -> script/PR/TECH_MV/run/        (full mirror)
#   build_PR/Makefile*   -> script/PR/TECH_MV/Makefile*
#
#   build_PR/verify/     -> script/PR/TECH_MV/verify/
#
#     VERIFY IS SPECIAL:
#       script/PR/TECH_MV/verify is the source environment from which the
#       runtime build_PR/verify tree is created.
#
#       Therefore the CURRENT MASTER verify file list is the exact allowlist.
#       Only files already belonging to the master verify environment are
#       updated from build_PR/verify.
#
#       Runtime-generated files that appear only under build_PR/verify are
#       NEVER copied back.
#
#       This deliberately excludes generated artifacts such as:
#         lvs/HCELL
#         lvs/LVSBOX
#         lvs/CHIP_inc.spi
#         lvs/CHIP.spi
#         lvs/rpt/*
#         Calibre reports/logs/results
#         dummy merged/intermediate GDS
#         DRC/Antenna result databases
#
# Protected:
#   script/PR/TECH_MV/script/
#
# Hidden files:
#   find/cp/rsync handling includes dotfiles.  No '*' wildcard is used as a
#   definition of the complete source set.
#
# Usage:
#   bash sync_build_PR_to_TECH_MV_v3.sh --dry-run
#   bash sync_build_PR_to_TECH_MV_v3.sh
#   bash sync_build_PR_to_TECH_MV_v3.sh /path/to/project
# =============================================================================

SH_PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ROOT="$SH_PROJECT_ROOT"
DRY_RUN=0

die() {
    echo "ERROR: $*" >&2
    exit 1
}

for arg in "$@"; do
    case "$arg" in
        --dry-run)
            DRY_RUN=1
            ;;
        -h|--help)
            echo "Usage: $0 [project_root] [--dry-run]"
            exit 0
            ;;
        -*)
            die "Unknown option: $arg"
            ;;
        *)
            ROOT="$arg"
            ;;
    esac
done

ROOT="$(cd "$ROOT" 2>/dev/null && pwd)" || die "Project root not found"

if [[ -f "$ROOT/tools/tech_runtime_sources.json" ]]; then
    die "Single-source runtime is enabled. Refusing to overwrite canonical Tcl with Runtime adapters. Edit script/PR/TECH_MV directly."
fi

BUILD="$ROOT/build_PR"
TN="$ROOT/script/PR/TECH_MV"
TN_SCRIPT="$TN/script"
MASTER_VERIFY="$TN/verify"
RUNTIME_VERIFY="$BUILD/verify"

[[ -d "$BUILD" ]] || die "Missing build_PR: $BUILD"
[[ -d "$TN" ]] || die "Missing TECH_MV master: $TN"
[[ -d "$TN_SCRIPT" ]] || die "Protected script directory missing: $TN_SCRIPT"
[[ -d "$MASTER_VERIFY" ]] || die "Master verify source missing: $MASTER_VERIFY"

command -v rsync >/dev/null 2>&1 || die "rsync is required"
command -v sha256sum >/dev/null 2>&1 || die "sha256sum is required"

# Reject all tool symlinks before preview, backup or synchronization.
for tool_tree in "$BUILD/run/tool" "$TN/run/tool"; do
    [[ ! -L "$tool_tree" ]] || die "Tool root must be a physical directory: $tool_tree"
    if [[ -d "$tool_tree" ]] && [[ -n "$(find "$tool_tree" -type l -print -quit)" ]]; then
        die "Tool tree contains a symlink; refusing synchronization: $tool_tree"
    fi
done

STAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP="$ROOT/.tech_mv_build_to_master_sync_backup/$STAMP"
VERIFY_MANIFEST=""

cleanup() {
    if [[ -n "${VERIFY_MANIFEST:-}" && -f "$VERIFY_MANIFEST" ]]; then
        rm -f "$VERIFY_MANIFEST"
    fi
}
trap cleanup EXIT

VERIFY_MANIFEST="$(mktemp "${TMPDIR:-/tmp}/tech_verify_manifest.XXXXXX")"

# -----------------------------------------------------------------------------
# Exact verify source allowlist.
#
# The list comes from the CURRENT source/master tree, not from file extensions.
# Hidden files are included.
# -----------------------------------------------------------------------------
(
    cd "$MASTER_VERIFY"
    find . -type f -print0 | sort -z
) > "$VERIFY_MANIFEST"

echo "======================================================================"
echo " TECH_MV BUILD_PR -> MASTER SYNC V3"
echo "======================================================================"
echo "Source runtime : $BUILD"
echo "Master target  : $TN"
echo "Protected      : $TN_SCRIPT"
echo "Mode           : $([[ $DRY_RUN -eq 1 ]] && echo DRY-RUN || echo APPLY)"
echo
echo "VERIFY POLICY:"
echo "  Exact allowlist = files already in script/PR/TECH_MV/verify"
echo "  Runtime-only generated files are NEVER copied back."
echo "======================================================================"

preview_file() {
    local src="$1"
    local dst="$2"

    if [[ ! -e "$src" && ! -L "$src" ]]; then
        echo "SKIP-MISSING : ${src#$ROOT/}"
    elif [[ ! -e "$dst" && ! -L "$dst" ]]; then
        echo "ADD          : ${dst#$ROOT/}"
    elif cmp -s "$src" "$dst" 2>/dev/null; then
        echo "SAME         : ${dst#$ROOT/}"
    else
        echo "UPDATE       : ${dst#$ROOT/}"
    fi
}

preview_dir_full() {
    local src="$1"
    local dst="$2"

    [[ -d "$src" ]] || {
        echo "SKIP-MISSING : ${src#$ROOT/}/"
        return 0
    }

    mkdir -p "$dst"
    rsync -ani --delete --exclude=/config/private/ "$src/" "$dst/"
}

preview_verify() {
    echo
    echo "--- verify/ exact master-source allowlist ---"

    local source_count=0
    local update_count=0
    local same_count=0
    local missing_count=0

    while IFS= read -r -d '' rel; do
        rel="${rel#./}"
        [[ -n "$rel" ]] || continue

        source_count=$((source_count + 1))

        local src="$RUNTIME_VERIFY/$rel"
        local dst="$MASTER_VERIFY/$rel"

        if [[ ! -e "$src" && ! -L "$src" ]]; then
            echo "VERIFY MISSING IN RUNTIME : $rel"
            missing_count=$((missing_count + 1))
        elif cmp -s "$src" "$dst" 2>/dev/null; then
            same_count=$((same_count + 1))
        else
            echo "VERIFY UPDATE             : $rel"
            update_count=$((update_count + 1))
        fi
    done < "$VERIFY_MANIFEST"

    echo
    echo "Verify source files : $source_count"
    echo "Verify updates      : $update_count"
    echo "Verify unchanged    : $same_count"
    echo "Verify missing      : $missing_count"

    if [[ -d "$RUNTIME_VERIFY" ]]; then
        echo
        echo "Runtime-only verify files (NOT synchronized):"

        local runtime_only=0

        while IFS= read -r -d '' f; do
            local rel="${f#$RUNTIME_VERIFY/}"

            if [[ ! -e "$MASTER_VERIFY/$rel" && ! -L "$MASTER_VERIFY/$rel" ]]; then
                echo "  SKIP GENERATED/RUNTIME-ONLY : $rel"
                runtime_only=$((runtime_only + 1))
            fi
        done < <(find "$RUNTIME_VERIFY" -type f -print0 | sort -z)

        echo "Runtime-only skipped: $runtime_only"
    fi
}

echo
echo "[1/6] Preview"

preview_file "$BUILD/init.setup" "$TN/init.setup"

for f in Makefile makefile GNUmakefile; do
    preview_file "$BUILD/$f" "$TN/$f"
done

for d in setup run; do
    echo
    echo "--- $d/ full mirror ---"
    preview_dir_full "$BUILD/$d" "$TN/$d"
done

preview_verify

if [[ $DRY_RUN -eq 1 ]]; then
    echo
    echo "======================================================================"
    echo " DRY-RUN PASS"
    echo "======================================================================"
    echo "No project file was modified."
    echo "======================================================================"
    exit 0
fi

# -----------------------------------------------------------------------------
# Backup current master/control state before sync.
# -----------------------------------------------------------------------------
echo
echo "[2/6] Backup current TECH_MV state"

mkdir -p "$BACKUP/script/PR/TECH_MV"

backup_one() {
    local rel="$1"
    local src="$TN/$rel"
    local dst="$BACKUP/script/PR/TECH_MV/$rel"

    if [[ -e "$src" || -L "$src" ]]; then
        mkdir -p "$(dirname "$dst")"
        cp -a "$src" "$dst"
        echo "$rel" >> "$BACKUP/BACKED_UP_PATHS.txt"
    else
        echo "$rel" >> "$BACKUP/MISSING_BEFORE_SYNC.txt"
    fi
}

for rel in init.setup setup run verify Makefile makefile GNUmakefile; do
    backup_one "$rel"
done

# Preserve exact verify allowlist used for this sync.
cp -a "$VERIFY_MANIFEST" "$BACKUP/VERIFY_SOURCE_ALLOWLIST.null"

# Hash protected script tree before sync.
(
    cd "$TN"
    find script -type f -print0 | sort -z | xargs -0 -r sha256sum
) > "$BACKUP/PROTECTED_SCRIPT_BEFORE.sha256"

# -----------------------------------------------------------------------------
# Rollback helper
# -----------------------------------------------------------------------------
cat > "$BACKUP/rollback_sync.sh" <<EOF
#!/usr/bin/env bash
set -euo pipefail

ROOT="\${1:-$ROOT}"
TN="\$ROOT/script/PR/TECH_MV"
BK="$BACKUP/script/PR/TECH_MV"
MISSING="$BACKUP/MISSING_BEFORE_SYNC.txt"

restore_one() {
    local rel="\$1"

    if [[ -e "\$BK/\$rel" || -L "\$BK/\$rel" ]]; then
        rm -rf "\$TN/\$rel"
        mkdir -p "\$(dirname "\$TN/\$rel")"
        cp -a "\$BK/\$rel" "\$TN/\$rel"
    elif [[ -f "\$MISSING" ]] && grep -Fxq "\$rel" "\$MISSING"; then
        rm -rf "\$TN/\$rel"
    fi
}

for rel in init.setup setup run verify Makefile makefile GNUmakefile; do
    restore_one "\$rel"
done

echo "Rollback PASS"
echo "Restored from: $BACKUP"
EOF

chmod +x "$BACKUP/rollback_sync.sh"

# -----------------------------------------------------------------------------
# Sync normal runtime/control trees.
# -----------------------------------------------------------------------------
echo
echo "[3/6] Synchronize init/setup/run/Makefile"

sync_file() {
    local src="$1"
    local dst="$2"

    if [[ -e "$src" || -L "$src" ]]; then
        mkdir -p "$(dirname "$dst")"
        cp -a "$src" "$dst"
        echo "SYNC FILE : ${src#$ROOT/} -> ${dst#$ROOT/}"
    else
        echo "SKIP FILE : source missing: ${src#$ROOT/}"
    fi
}

sync_dir_full() {
    local src="$1"
    local dst="$2"

    [[ -d "$src" ]] || {
        echo "SKIP DIR  : source missing: ${src#$ROOT/}/"
        return 0
    }

    mkdir -p "$dst"
    rsync -a --delete --exclude=/config/private/ "$src/" "$dst/"

    echo "SYNC DIR  : ${src#$ROOT/}/ -> ${dst#$ROOT/}/"
}

sync_file "$BUILD/init.setup" "$TN/init.setup"

for d in setup run; do
    sync_dir_full "$BUILD/$d" "$TN/$d"
done

for f in Makefile makefile GNUmakefile; do
    sync_file "$BUILD/$f" "$TN/$f"
done

# -----------------------------------------------------------------------------
# Sync verify source environment ONLY.
#
# No rsync --delete here.
# No runtime directory scanning as a source definition.
# No extension classifier.
#
# Each master-source file may be updated from the matching runtime copy.
# Anything present only in build_PR/verify is ignored.
# -----------------------------------------------------------------------------
echo
echo "[4/6] Synchronize verify source files only"

verify_synced=0
verify_missing=0

while IFS= read -r -d '' rel; do
    rel="${rel#./}"
    [[ -n "$rel" ]] || continue

    src="$RUNTIME_VERIFY/$rel"
    dst="$MASTER_VERIFY/$rel"

    if [[ ! -e "$src" && ! -L "$src" ]]; then
        echo "WARNING: Verify source missing in runtime; master retained: $rel"
        verify_missing=$((verify_missing + 1))
        continue
    fi

    mkdir -p "$(dirname "$dst")"
    cp -a "$src" "$dst"

    cmp -s "$src" "$dst" || die "Verify source copy verification failed: $rel"

    verify_synced=$((verify_synced + 1))
done < "$VERIFY_MANIFEST"

echo "Verify source files synchronized : $verify_synced"
echo "Verify source files missing       : $verify_missing"

# -----------------------------------------------------------------------------
# Verification.
# -----------------------------------------------------------------------------
echo
echo "[5/6] Verify synchronized state"

verify_file_equal() {
    local src="$1"
    local dst="$2"

    [[ -e "$src" || -L "$src" ]] || return 0

    cmp -s "$src" "$dst" \
        || die "Verification failed: $src != $dst"
}

verify_dir_equal() {
    local src="$1"
    local dst="$2"

    [[ -d "$src" ]] || return 0

    diff -qr --exclude=private "$src" "$dst" >/dev/null \
        || die "Directory verification failed: $src != $dst"
}

verify_file_equal "$BUILD/init.setup" "$TN/init.setup"

for d in setup run; do
    verify_dir_equal "$BUILD/$d" "$TN/$d"
done

for f in Makefile makefile GNUmakefile; do
    verify_file_equal "$BUILD/$f" "$TN/$f"
done

# Verify every master verify source path that exists in runtime.
while IFS= read -r -d '' rel; do
    rel="${rel#./}"
    [[ -n "$rel" ]] || continue

    src="$RUNTIME_VERIFY/$rel"
    dst="$MASTER_VERIFY/$rel"

    if [[ -e "$src" || -L "$src" ]]; then
        cmp -s "$src" "$dst" \
            || die "Verify source verification failed: $rel"
    fi
done < "$VERIFY_MANIFEST"

# Verify that the master verify PATH SET did not grow during synchronization.
MASTER_VERIFY_AFTER="$(mktemp "${TMPDIR:-/tmp}/tech_verify_after.XXXXXX")"
(
    cd "$MASTER_VERIFY"
    find . -type f -print0 | sort -z
) > "$MASTER_VERIFY_AFTER"

cmp -s "$VERIFY_MANIFEST" "$MASTER_VERIFY_AFTER" \
    || {
        rm -f "$MASTER_VERIFY_AFTER"
        die "Master verify file set changed unexpectedly during synchronization"
    }

rm -f "$MASTER_VERIFY_AFTER"

# Verify protected main script source tree is unchanged.
(
    cd "$TN"
    find script -type f -print0 | sort -z | xargs -0 -r sha256sum
) > "$BACKUP/PROTECTED_SCRIPT_AFTER.sha256"

cmp -s \
    "$BACKUP/PROTECTED_SCRIPT_BEFORE.sha256" \
    "$BACKUP/PROTECTED_SCRIPT_AFTER.sha256" \
    || die "Protected script/ tree changed unexpectedly"

# Save final source hashes.
(
    cd "$TN"

    for p in init.setup setup run verify Makefile makefile GNUmakefile; do
        if [[ -f "$p" ]]; then
            sha256sum "$p"
        elif [[ -d "$p" ]]; then
            find "$p" -type f -print0 \
                | sort -z \
                | xargs -0 -r sha256sum
        fi
    done
) > "$BACKUP/SYNCED_STATE.sha256"

echo
echo "[6/6] PASS"

echo "======================================================================"
echo " TECH_MV BUILD_PR -> MASTER SYNC V3: PASS"
echo "======================================================================"
echo "Full synchronized:"
echo "  init.setup"
echo "  setup/"
echo "  run/"
echo "  Makefile/makefile/GNUmakefile when present"
echo
echo "Verify synchronized:"
echo "  ONLY files already belonging to master verify source environment"
echo "  Runtime-only/generated verify files were ignored"
echo
echo "Protected:"
echo "  script/PR/TECH_MV/script/"
echo
echo "Backup:"
echo "  $BACKUP"
echo
echo "Rollback:"
echo "  bash \"$BACKUP/rollback_sync.sh\" \"$ROOT\""
echo "======================================================================"
