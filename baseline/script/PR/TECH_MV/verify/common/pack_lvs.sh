#!/usr/bin/env bash
# Package only the LVS environment and readable diagnostics, without running LVS.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
archive=${1:-lvs_pack.tar.gz}

# Use an explicit allowlist: never traverse DRC, add_dummy, SVDB or external
# library/tool installations. Do not dereference symlinks.
files=(Makefile config.csh common/pack_lvs.sh common/run_logged.sh common/artifacts.py)
while IFS= read -r -d '' file; do
    files+=("$file")
done < <(find lvs -maxdepth 1 -type f \( \
    -name '*.csh' -o -name '*.sh' -o -name '*.tcl' -o \
    -name '*.log' -o -name '*.txt' -o -name '*.rpt' -o \
    -name 'HCELL' -o -name 'LVSBOX' \) -print0)

for dir in lvs/scr lvs/log lvs/rpt lvs/output; do
    [[ -d "$dir" && ! -L "$dir" ]] || continue
    while IFS= read -r -d '' file; do
        case "$file" in *.generated.cmd) continue ;; esac
        files+=("$file")
    done < <(find "$dir" -type f \( \
        -name '*.csh' -o -name '*.sh' -o -name '*.tcl' -o -name '*.py' -o \
        -name '*.cmd' -o -name '*.spec' -o -name '*.list' -o \
        -name '*.log' -o -name '*.txt' -o -name '*.rpt' -o \
        -name '*.rep' -o -name '*.rep.ext' -o -name '*.sum' \) -print0)
done

# Write beside the destination, then rename so a failed pack leaves any old
# archive intact. Preserve file permissions, including executable script bits.
tmp_archive=$(mktemp "${archive}.tmp.XXXXXX")
trap 'rm -f -- "$tmp_archive"' EXIT
tar -czf "$tmp_archive" -- "${files[@]}"
mv -f -- "$tmp_archive" "$archive"
echo "Packed LVS environment and readable logs/reports: $archive (${#files[@]} files)"
echo "External Calibre/tools/PDK and design inputs must be supplied separately."
