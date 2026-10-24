#!/bin/tcsh
setenv VERIFY_ROOT `cd ..; pwd`
source "$VERIFY_ROOT/config.csh"

set RUNSET_BASE = "./scr/runset.base.cmd"
if (! -e "$RUNSET_BASE") then
    echo "ERROR: runset base not found: $RUNSET_BASE"
    exit 1
endif

set HCELL_CFG = "./hcell_mode.csh"
if (! -e "$HCELL_CFG") then
    echo "ERROR: HCELL mode config not found: $HCELL_CFG"
    exit 1
endif
source "$HCELL_CFG"

set HCELL_MODE = `echo "$VERIFY_HCELL_MODE" | tr '[:lower:]' '[:upper:]'`
if ("$HCELL_MODE" != "ON" && "$HCELL_MODE" != "OFF") then
    echo "ERROR: invalid VERIFY_HCELL_MODE='$VERIFY_HCELL_MODE'"
    echo "       Set ON or OFF in $HCELL_CFG, or export VERIFY_HCELL_MODE before make verify."
    exit 1
endif
setenv VERIFY_HCELL_MODE "$HCELL_MODE"

set LVSBOX_MODE = `echo "$VERIFY_LVSBOX_MODE" | tr '[:lower:]' '[:upper:]'`
if ("$LVSBOX_MODE" != "ON" && "$LVSBOX_MODE" != "OFF") then
    echo "ERROR: invalid VERIFY_LVSBOX_MODE='$VERIFY_LVSBOX_MODE'"
    echo "       Set ON or OFF in $HCELL_CFG, or export VERIFY_LVSBOX_MODE before make verify."
    exit 1
endif
setenv VERIFY_LVSBOX_MODE "$LVSBOX_MODE"

set WELL_TEXT_MODE = `echo "$VERIFY_WELL_TEXT_MODE" | tr '[:lower:]' '[:upper:]'`
if ("$WELL_TEXT_MODE" != "ON" && "$WELL_TEXT_MODE" != "OFF") then
    echo "ERROR: invalid VERIFY_WELL_TEXT_MODE='$VERIFY_WELL_TEXT_MODE'"
    exit 1
endif
setenv VERIFY_WELL_TEXT_MODE "$WELL_TEXT_MODE"

set VCONNECT_COLON_MODE = `echo "$VERIFY_VCONNECT_COLON_MODE" | tr '[:lower:]' '[:upper:]'`
if ("$VCONNECT_COLON_MODE" != "ON" && "$VCONNECT_COLON_MODE" != "OFF") then
    echo "ERROR: invalid VERIFY_VCONNECT_COLON_MODE='$VERIFY_VCONNECT_COLON_MODE'"
    exit 1
endif
setenv VERIFY_VCONNECT_COLON_MODE "$VCONNECT_COLON_MODE"

set EXPAND_SEED_MODE = `echo "$VERIFY_EXPAND_SEED_PROMOTIONS_MODE" | tr '[:lower:]' '[:upper:]'`
if ("$EXPAND_SEED_MODE" != "ON" && "$EXPAND_SEED_MODE" != "OFF") then
    echo "ERROR: invalid VERIFY_EXPAND_SEED_PROMOTIONS_MODE='$VERIFY_EXPAND_SEED_PROMOTIONS_MODE'"
    exit 1
endif
setenv VERIFY_EXPAND_SEED_PROMOTIONS_MODE "$EXPAND_SEED_MODE"

set EXPAND_HIGH_MODE = `echo "$VERIFY_EXPAND_HIGH_SHORT_HCELLS_MODE" | tr '[:lower:]' '[:upper:]'`
if ("$EXPAND_HIGH_MODE" != "ON" && "$EXPAND_HIGH_MODE" != "OFF") then
    echo "ERROR: invalid VERIFY_EXPAND_HIGH_SHORT_HCELLS_MODE='$VERIFY_EXPAND_HIGH_SHORT_HCELLS_MODE'"
    exit 1
endif
setenv VERIFY_EXPAND_HIGH_SHORT_HCELLS_MODE "$EXPAND_HIGH_MODE"

set SHOW_SEED_MODE = `echo "$VERIFY_SHOW_SEED_PROMOTIONS_MODE" | tr '[:lower:]' '[:upper:]'`
if ("$SHOW_SEED_MODE" != "ON" && "$SHOW_SEED_MODE" != "OFF") then
    echo "ERROR: invalid VERIFY_SHOW_SEED_PROMOTIONS_MODE='$VERIFY_SHOW_SEED_PROMOTIONS_MODE'"
    exit 1
endif
setenv VERIFY_SHOW_SEED_PROMOTIONS_MODE "$SHOW_SEED_MODE"

set RUNSET_ABS = `cd ./scr; pwd`/runset.base.cmd
set HCELL_CFG_ABS = `pwd`/hcell_mode.csh

echo "============================================================"
echo " TECH_MV LVS CONFIGURATION"
echo "============================================================"
echo " Runtime CWD : `pwd`"
echo " HCELL MODE  : $VERIFY_HCELL_MODE"
echo " LVSBOX MODE : $VERIFY_LVSBOX_MODE"
echo " WELL_TEXT   : $VERIFY_WELL_TEXT_MODE"
echo " VC COLON    : $VERIFY_VCONNECT_COLON_MODE"
echo " EXPAND SEED : $VERIFY_EXPAND_SEED_PROMOTIONS_MODE"
echo " EXPAND HIGH : $VERIFY_EXPAND_HIGH_SHORT_HCELLS_MODE"
echo " SHOW SEED   : $VERIFY_SHOW_SEED_PROMOTIONS_MODE (max=$VERIFY_SHOW_SEED_PROMOTIONS_MAX)"
echo " HCELL CONFIG: $HCELL_CFG_ABS"
echo " RUNSET      : $RUNSET_ABS"
echo "============================================================"

./run_v2lvs.csh
if ($status != 0) exit $status

# Generate hierarchical correspondence and/or explicit BOX list only when used.
if ("$VERIFY_HCELL_MODE" == "ON" || "$VERIFY_LVSBOX_MODE" == "ON") then
    ./run_hcell.csh
    if ($status != 0) exit $status
else
    echo "INFO: HCELL=OFF and LVSBOX=OFF; skip run_hcell.csh"
endif

./run_source_inc.csh
if ($status != 0) exit $status

./run_lvs.csh
exit $status
