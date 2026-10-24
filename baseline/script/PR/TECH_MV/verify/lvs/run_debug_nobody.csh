#!/bin/tcsh
# Recompare existing extraction; do not modify normal LVS inputs/results.
setenv VERIFY_ROOT `cd ..; pwd`
source "$VERIFY_ROOT/config.csh"
python3 scr/debug_nobody.py
if ($status != 0) exit $status
cd build/debug_nobody
which calibre >& /dev/null
if ($status != 0) then
    echo "ERROR: calibre not on PATH. Source your Calibre environment, then retry."
    echo "Prepared debug inputs are in lvs/build/debug_nobody/."
    exit 1
endif
"$VERIFY_ROOT/common/run_logged.sh" runset.log calibre -lvs -64 -hier -turbo "$VERIFY_CPU_LVS" runset.cmd
set rc = $status
echo "DEBUG ONLY: body connectivity normalized; report: lvs/build/debug_nobody/output/lvs.rep"
exit $rc
