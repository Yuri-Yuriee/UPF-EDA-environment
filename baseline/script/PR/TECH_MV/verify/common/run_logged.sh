#!/usr/bin/env bash
# Run a command, mirror stdout/stderr to a log, and preserve the command's
# real exit status. This replaces the non-portable tcsh $pipestatus usage.
set -o pipefail

if [[ $# -lt 2 ]]; then
    echo "Usage: run_logged.sh <log-file> <command> [args...]" >&2
    exit 2
fi

log_file="$1"
shift

mkdir -p "$(dirname "$log_file")"
"$@" 2>&1 | tee "$log_file"
exit ${PIPESTATUS[0]}
