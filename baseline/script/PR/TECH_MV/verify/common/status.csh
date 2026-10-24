#!/bin/tcsh

setenv VERIFY_ROOT `cd ..; pwd`
source "$VERIFY_ROOT/config.csh"

set scope = "all"
if ($#argv > 0) then
    set scope = "$argv[1]"
endif

echo ""
echo "======================================================================"
echo " TECH_MV VERIFY SUMMARY"
echo "======================================================================"
echo "TOP       : $VERIFY_TOP"
echo "RAW GDS   : $VERIFY_GDS"
echo ""

set lvs_state = "NOT RUN"
set lvs_detail = ""
set lvs_report = "$VERIFY_ROOT/lvs/output/lvs.rep"
if (-e "$lvs_report") then
    set lvs_line = `grep -E "CORRECT|INCORRECT|NOT COMPARED" "$lvs_report" | tail -1`
    if ("$lvs_line" != "") then
        set lvs_detail = "$lvs_line"
        if ("$lvs_line" =~ *INCORRECT*) then
            set lvs_state = "INCORRECT"
        else if ("$lvs_line" =~ *CORRECT*) then
            set lvs_state = "CORRECT"
        else if ("$lvs_line" =~ *"NOT COMPARED"*) then
            set lvs_state = "NOT COMPARED"
        else
            set lvs_state = "DONE"
        endif
    else
        set lvs_state = "DONE / CHECK REPORT"
    endif
endif

if ("$scope" == "lvs") then
    echo "LVS"
    echo "----------------------------------------------------------------------"
    echo "Result    : $lvs_state"
    echo "Report    : $lvs_report"
    if ("$lvs_detail" != "") echo "Detail    : $lvs_detail"
    echo "----------------------------------------------------------------------"
    echo "NOTE: LVS tool completion does not mean LVS CORRECT."
    echo "======================================================================"
    echo ""
    exit 0
endif

echo "SIGNOFF STATUS"
echo "----------------------------------------------------------------------"
printf "%-12s : %s\n" "LVS" "$lvs_state"

set stage_dir = "$VERIFY_ROOT/add_dummy/.stage"
foreach pair ("BEOL BE.done" "COD COD.done" "FEOL FE.done" "MERGE MERGE.done")
    set label = `echo "$pair" | awk '{print $1}'`
    set file  = `echo "$pair" | awk '{print $2}'`
    if (-e "$stage_dir/$file") then
        printf "%-12s : PASS\n" "DUMMY-$label"
    else
        printf "%-12s : NOT COMPLETE\n" "DUMMY-$label"
    endif
end

"$VERIFY_ROOT/common/check_dummy_ready.sh" "$VERIFY_ROOT" "$VERIFY_GDS" "$VERIFY_DUMMY_GDS" >& /tmp/tech_dummy_status_$$
set dummy_rc = $status
if ($dummy_rc == 0) then
    printf "%-12s : READY\n" "DRC INPUT"
else
    printf "%-12s : BLOCKED - dummy flow incomplete/stale\n" "DRC INPUT"
endif
rm -f /tmp/tech_dummy_status_$$

set drc_report = "$VERIFY_ROOT/drc/rpt/DRC.rep"
if (-e "$drc_report") then
    set drc_line = `grep -E "TOTAL DRC Results Generated|TOTAL Result Count" "$drc_report" | tail -1`
    if ("$drc_line" == "") set drc_line = "DONE / CHECK REPORT"
    printf "%-12s : %s\n" "DRC" "$drc_line"
else
    printf "%-12s : NOT RUN\n" "DRC"
endif

set ant_report = "$VERIFY_ROOT/drc/rpt/ANTENNA.rep"
if (-e "$ant_report") then
    set ant_line = `grep -E "TOTAL DRC Results Generated|TOTAL Result Count" "$ant_report" | tail -1`
    if ("$ant_line" == "") set ant_line = "DONE / CHECK REPORT"
    printf "%-12s : %s\n" "ANTENNA" "$ant_line"
else
    printf "%-12s : NOT RUN\n" "ANTENNA"
endif

echo "----------------------------------------------------------------------"
echo "LVS report : $lvs_report"
echo "DRC report : $drc_report"
echo "ANT report : $ant_report"
echo "Final GDS  : $VERIFY_DUMMY_GDS"
echo "----------------------------------------------------------------------"
if ("$lvs_state" == "INCORRECT") then
    echo "FINAL NOTE : Flow completed, but LVS is INCORRECT. Inspect output/lvs.rep."
else
    echo "FINAL NOTE : Always judge signoff from the reports above, not tool exit code alone."
endif
echo "======================================================================"
echo ""
