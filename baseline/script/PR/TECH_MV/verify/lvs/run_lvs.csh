#!/bin/tcsh
setenv VERIFY_ROOT `cd ..; pwd`
source "$VERIFY_ROOT/config.csh"

mkdir -p log output rpt temp

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
    exit 1
endif
setenv VERIFY_HCELL_MODE "$HCELL_MODE"

set LVSBOX_MODE = `echo "$VERIFY_LVSBOX_MODE" | tr '[:lower:]' '[:upper:]'`
if ("$LVSBOX_MODE" != "ON" && "$LVSBOX_MODE" != "OFF") then
    echo "ERROR: invalid VERIFY_LVSBOX_MODE='$VERIFY_LVSBOX_MODE'"
    exit 1
endif
setenv VERIFY_LVSBOX_MODE "$LVSBOX_MODE"

# Normalize/validate hierarchy extraction controls.
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

if (! -e "$VERIFY_GDS") then
    echo "ERROR: GDS not found: $VERIFY_GDS"
    exit 1
endif
if (! -e ./CHIP.spi) then
    echo "ERROR: CHIP.spi not found. Run ./run_v2lvs.csh first."
    exit 1
endif
if (! -e ./CHIP_inc.spi) then
    echo "ERROR: CHIP_inc.spi not found. Run ./run_source_inc.csh first."
    exit 1
endif
if ("$VERIFY_HCELL_MODE" == "ON") then
    if (! -e ./HCELL) then
        echo "ERROR: HCELL not found while VERIFY_HCELL_MODE=ON. Run ./run_hcell.csh first."
        exit 1
    endif
endif
if ("$VERIFY_LVSBOX_MODE" == "ON") then
    if (! -e ./LVSBOX) then
        echo "ERROR: LVSBOX not found while VERIFY_LVSBOX_MODE=ON. Run ./run_hcell.csh first."
        exit 1
    endif
endif
if (! -e "$TECH_LVS_DECK") then
    echo "ERROR: TECH LVS deck not found: $TECH_LVS_DECK"
    exit 1
endif

# TECH_verify validated method:
#   copy the project TECH Calibre LVS deck locally, then disable its own
#   POWER_NAME/GROUND_NAME declarations so this runset owns those variables.
cp -f "$TECH_LVS_DECK" ./temp/LVS_Calibre.modified
sed -i -e 's/VARIABLE POWER_NAME/\/\/VARIABLE POWER_NAME/g' ./temp/LVS_Calibre.modified
sed -i -e 's/VARIABLE GROUND_NAME/\/\/VARIABLE GROUND_NAME/g' ./temp/LVS_Calibre.modified

# Generate a self-contained runset.
# HCELL correspondence and LVS BOX remain independent.
# WELL_TEXT must be defined BEFORE the foundry deck is included.
# Full-chip and adaptive HCELL overrides are intentionally emitted AFTER the
# foundry deck include, so they override the deck defaults without editing it.
sed -f "$VERIFY_ROOT/config/private/runset_lvs_names.sed" -e "s|@LAYOUT_GDS@|$VERIFY_GDS|g" "$RUNSET_BASE" > ./temp/runset.generated.cmd
if ("$VERIFY_LVSBOX_MODE" == "ON") then
    cat ./LVSBOX >> ./temp/runset.generated.cmd
endif

echo "" >> ./temp/runset.generated.cmd
echo "// TECH_MV pre-include controls" >> ./temp/runset.generated.cmd
if ("$VERIFY_WELL_TEXT_MODE" == "ON") then
    echo "#define WELL_TEXT" >> ./temp/runset.generated.cmd
endif

echo "include ./temp/LVS_Calibre.modified" >> ./temp/runset.generated.cmd

echo "" >> ./temp/runset.generated.cmd
echo "// TECH_MV post-include full-chip/hierarchy overrides" >> ./temp/runset.generated.cmd
if ("$VERIFY_VCONNECT_COLON_MODE" == "ON") then
    echo "VIRTUAL CONNECT COLON YES" >> ./temp/runset.generated.cmd
else
    echo "VIRTUAL CONNECT COLON NO" >> ./temp/runset.generated.cmd
endif

if ("$VERIFY_EXPAND_SEED_PROMOTIONS_MODE" == "ON") then
    echo "LVS EXPAND SEED PROMOTIONS YES" >> ./temp/runset.generated.cmd
else
    echo "LVS EXPAND SEED PROMOTIONS NO" >> ./temp/runset.generated.cmd
endif

if ("$VERIFY_EXPAND_HIGH_SHORT_HCELLS_MODE" == "ON") then
    echo "LVS EXPAND AMBIGUOUSLY HIGH SHORTED HCELLS YES" >> ./temp/runset.generated.cmd
else
    echo "LVS EXPAND AMBIGUOUSLY HIGH SHORTED HCELLS NO" >> ./temp/runset.generated.cmd
endif

if ("$VERIFY_SHOW_SEED_PROMOTIONS_MODE" == "ON") then
    echo "LVS SHOW SEED PROMOTIONS YES" >> ./temp/runset.generated.cmd
    echo "LVS SHOW SEED PROMOTIONS MAXIMUM $VERIFY_SHOW_SEED_PROMOTIONS_MAX" >> ./temp/runset.generated.cmd
else
    echo "LVS SHOW SEED PROMOTIONS NO" >> ./temp/runset.generated.cmd
endif

set LVS_DIR = `pwd`
set RUNSET_ABS = `cd ./scr; pwd`/runset.base.cmd
set HCELL_CFG_ABS = `pwd`/hcell_mode.csh

echo "INFO: LVS GDS         = $VERIFY_GDS"
echo "INFO: LVS source      = ./CHIP_inc.spi"
echo "INFO: HCELL mode      = $VERIFY_HCELL_MODE"
echo "INFO: LVSBOX mode     = $VERIFY_LVSBOX_MODE"
echo "INFO: WELL_TEXT mode  = $VERIFY_WELL_TEXT_MODE"
echo "INFO: VC COLON mode   = $VERIFY_VCONNECT_COLON_MODE"
echo "INFO: EXPAND SEED     = $VERIFY_EXPAND_SEED_PROMOTIONS_MODE"
echo "INFO: EXPAND HISHORT  = $VERIFY_EXPAND_HIGH_SHORT_HCELLS_MODE"
echo "INFO: SHOW SEED       = $VERIFY_SHOW_SEED_PROMOTIONS_MODE (max=$VERIFY_SHOW_SEED_PROMOTIONS_MAX)"
echo "INFO: LVS runset base = $RUNSET_ABS"
echo "INFO: HCELL config    = $HCELL_CFG_ABS"
if ("$VERIFY_HCELL_MODE" == "ON") then
    echo "INFO: HCELL file      = $LVS_DIR/HCELL"
    echo "INFO: HCELL entries   = `wc -l < ./HCELL`"
else
    echo "INFO: HCELL file      = DISABLED"
endif
if ("$VERIFY_LVSBOX_MODE" == "ON") then
    echo "INFO: LVSBOX file     = $LVS_DIR/LVSBOX"
    echo "INFO: LVSBOX entries  = `wc -l < ./LVSBOX`"
else
    echo "INFO: LVSBOX          = DISABLED"
endif
echo "INFO: LVS deck        = $TECH_LVS_DECK"

# Leave an explicit record of what this run actually used.
rm -f ./rpt/lvs_mode.rpt
echo "VERIFY_HCELL_MODE=$VERIFY_HCELL_MODE" >> ./rpt/lvs_mode.rpt
echo "VERIFY_LVSBOX_MODE=$VERIFY_LVSBOX_MODE" >> ./rpt/lvs_mode.rpt
echo "VERIFY_WELL_TEXT_MODE=$VERIFY_WELL_TEXT_MODE" >> ./rpt/lvs_mode.rpt
echo "VERIFY_VCONNECT_COLON_MODE=$VERIFY_VCONNECT_COLON_MODE" >> ./rpt/lvs_mode.rpt
echo "VERIFY_EXPAND_SEED_PROMOTIONS_MODE=$VERIFY_EXPAND_SEED_PROMOTIONS_MODE" >> ./rpt/lvs_mode.rpt
echo "VERIFY_EXPAND_HIGH_SHORT_HCELLS_MODE=$VERIFY_EXPAND_HIGH_SHORT_HCELLS_MODE" >> ./rpt/lvs_mode.rpt
echo "VERIFY_SHOW_SEED_PROMOTIONS_MODE=$VERIFY_SHOW_SEED_PROMOTIONS_MODE" >> ./rpt/lvs_mode.rpt
echo "VERIFY_SHOW_SEED_PROMOTIONS_MAX=$VERIFY_SHOW_SEED_PROMOTIONS_MAX" >> ./rpt/lvs_mode.rpt
echo "RUNSET_BASE=$RUNSET_ABS" >> ./rpt/lvs_mode.rpt
echo "HCELL_CONFIG=$HCELL_CFG_ABS" >> ./rpt/lvs_mode.rpt
if ("$VERIFY_HCELL_MODE" == "ON") then
    echo "HCELL_FILE=$LVS_DIR/HCELL" >> ./rpt/lvs_mode.rpt
    echo "HCELL_ENTRIES=`wc -l < ./HCELL`" >> ./rpt/lvs_mode.rpt
else
    echo "HCELL_FILE=DISABLED" >> ./rpt/lvs_mode.rpt
    echo "HCELL_ENTRIES=DISABLED" >> ./rpt/lvs_mode.rpt
endif
if ("$VERIFY_LVSBOX_MODE" == "ON") then
    echo "LVSBOX_FILE=$LVS_DIR/LVSBOX" >> ./rpt/lvs_mode.rpt
    echo "LVSBOX_ENTRIES=`wc -l < ./LVSBOX`" >> ./rpt/lvs_mode.rpt
else
    echo "LVSBOX_FILE=DISABLED" >> ./rpt/lvs_mode.rpt
    echo "LVSBOX_ENTRIES=DISABLED" >> ./rpt/lvs_mode.rpt
endif

# -------------------------------------------------------------------------
# Run Calibre LVS in LOCAL scratch
# -------------------------------------------------------------------------
if ($?VERIFY_LVS_SCRATCH_ROOT) then
    set SCRATCH_ROOT = "$VERIFY_LVS_SCRATCH_ROOT"
else if ($?TMPDIR) then
    set SCRATCH_ROOT = "$TMPDIR"
else
    set SCRATCH_ROOT = "/tmp/$USER"
endif

mkdir -p "$SCRATCH_ROOT"
if ($status != 0) then
    echo "ERROR: cannot create LVS scratch root: $SCRATCH_ROOT"
    exit 1
endif

set LVS_SCRATCH = "$SCRATCH_ROOT/tech_lvs_${VERIFY_TOP}_$$"
rm -rf "$LVS_SCRATCH"
mkdir -p "$LVS_SCRATCH/temp" "$LVS_SCRATCH/output"
if ($status != 0) then
    echo "ERROR: cannot create LVS scratch directory: $LVS_SCRATCH"
    exit 1
endif

# Source-side relative references in CHIP_inc.spi and runset.generated.cmd
# require these files to be present in the scratch working directory.
cp -f ./CHIP.spi "$LVS_SCRATCH/CHIP.spi"
cp -f ./CHIP_inc.spi "$LVS_SCRATCH/CHIP_inc.spi"
cp -f ./temp/runset.generated.cmd "$LVS_SCRATCH/temp/runset.generated.cmd"
cp -f ./temp/LVS_Calibre.modified "$LVS_SCRATCH/temp/LVS_Calibre.modified"
if ("$VERIFY_HCELL_MODE" == "ON") then
    cp -f ./HCELL "$LVS_SCRATCH/HCELL"
endif

echo "INFO: LVS project dir = $LVS_DIR"
echo "INFO: LVS scratch dir = $LVS_SCRATCH"

cd "$LVS_SCRATCH"

if ("$VERIFY_HCELL_MODE" == "ON") then
    "$VERIFY_ROOT/common/run_logged.sh" "$LVS_DIR/log/runset.log" \
        calibre -lvs -64 -hier -hcell ./HCELL -turbo "$VERIFY_CPU_LVS" \
        -spice layout.spi \
        ./temp/runset.generated.cmd \
        -lmretry loop,maxretry:200,interval:180
else
    "$VERIFY_ROOT/common/run_logged.sh" "$LVS_DIR/log/runset.log" \
        calibre -lvs -64 -hier -turbo "$VERIFY_CPU_LVS" \
        -spice layout.spi \
        ./temp/runset.generated.cmd \
        -lmretry loop,maxretry:200,interval:180
endif
set rc = $status

cd "$LVS_DIR"

# Copy Calibre reports/results back even on failure when they exist.
if (-d "$LVS_SCRATCH/output") then
    rm -rf ./output
    mkdir -p ./output
    cp -a "$LVS_SCRATCH/output/." ./output/
endif

if ("$VERIFY_COPY_LVS_LAYOUT_SPICE" == "1") then
    if (-e "$LVS_SCRATCH/layout.spi") then
        cp -f "$LVS_SCRATCH/layout.spi" ./temp/layout.spi
    endif
endif

# Keep final svdb for RVE/debug, but only copy it AFTER Calibre has finished.
rm -rf ./svdb
if (-d "$LVS_SCRATCH/svdb") then
    cp -a "$LVS_SCRATCH/svdb" ./svdb
endif

if ($rc == 0) then
    if ($?VERIFY_KEEP_LVS_SCRATCH) then
        if ("$VERIFY_KEEP_LVS_SCRATCH" == "1") then
            echo "INFO: keeping successful LVS scratch: $LVS_SCRATCH"
        else
            rm -rf "$LVS_SCRATCH"
        endif
    else
        rm -rf "$LVS_SCRATCH"
    endif
else
    echo "ERROR: Calibre LVS failed with exit code $rc"
    echo "INFO : preserving local scratch for debug:"
    echo "       $LVS_SCRATCH"
endif

exit $rc
