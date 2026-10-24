#!/bin/tcsh
setenv VERIFY_ROOT `cd ..; pwd`
source "$VERIFY_ROOT/config.csh"

mkdir -p log output rpt

if (! -e "$VERIFY_PG_NETLIST") then
    echo "ERROR: PG netlist not found: $VERIFY_PG_NETLIST"
    exit 1
endif

echo "INFO: v2lvs input = $VERIFY_PG_NETLIST"
"$VERIFY_ROOT/common/run_logged.sh" log/v2lvs.log \
    v2lvs -v "$VERIFY_PG_NETLIST" -o ./CHIP.spi
set rc = $status
exit $rc
