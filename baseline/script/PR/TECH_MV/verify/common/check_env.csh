#!/bin/tcsh

setenv VERIFY_ROOT `cd ..; pwd`
source "$VERIFY_ROOT/config.csh"

set errors = 0
set warnings = 0

echo ""
echo "======================================================================"
echo " TECH_MV VERIFY PRECHECK"
echo "======================================================================"
echo "TOP              : $VERIFY_TOP"
echo "PROJECT_ROOT     : $PROJECT_ROOT"
echo "VERIFY_OUTPUT_DIR: $VERIFY_OUTPUT_DIR"
echo ""

echo "APR outputs:"
echo "----------------------------------------------------------------------"

if (! -e "$VERIFY_GDS") then
    echo "ERROR: APR GDS is missing: $VERIFY_GDS"
    echo "       This is a project output, not a TECH PDK_BUNDLE file."
    if (-d "$VERIFY_OUTPUT_DIR") then
        echo "       Available GDS candidates:"
        find "$VERIFY_OUTPUT_DIR" -maxdepth 1 -type f \( -name '*.gds' -o -name '*.gds.gz' \) -print
    endif
    @ errors++
else
    echo "PASS : GDS        = $VERIFY_GDS"
endif

if (! -e "$VERIFY_PG_NETLIST") then
    echo "ERROR: APR PG netlist is missing: $VERIFY_PG_NETLIST"
    echo "       This is a project output, not a TECH PDK_BUNDLE file."
    if (-d "$VERIFY_OUTPUT_DIR") then
        echo "       Available Verilog candidates:"
        find "$VERIFY_OUTPUT_DIR" -maxdepth 1 -type f -name '*.v' -print
    endif
    @ errors++
else
    echo "PASS : PG NETLIST = $VERIFY_PG_NETLIST"
endif

echo ""
echo "TECH PDK_BUNDLE collateral:"
echo "----------------------------------------------------------------------"

foreach pair ( \
    "LVS_DECK|$TECH_LVS_DECK" \
    "LVS_SOURCE_ADDED|$TECH_LVS_SOURCE_ADDED" \
    "DRC_DECK|$TECH_DRC_DECK" \
    "ANTENNA_DECK|$TECH_ANTENNA_DECK" \
    "DUMMY_FE|$TECH_DUMMY_FE_DECK" \
    "DUMMY_BE|$TECH_DUMMY_BE_DECK" \
    "DUMMY_COD|$TECH_DUMMY_COD_DECK" \
)
    set key = `echo "$pair" | cut -d'|' -f1`
    set val = `echo "$pair" | cut -d'|' -f2-`
    if ("$val" == "" || ! -e "$val") then
        echo "ERROR: missing TECH collateral: $key = $val"
        @ errors++
    else
        echo "PASS : $key = $val"
    endif
end

if ("$TECH_PDK_CDS_LIB" == "" || ! -e "$TECH_PDK_CDS_LIB") then
    echo "WARN : TECH Virtuoso cds.lib is not configured (not required for Calibre signoff)."
    @ warnings++
else
    echo "PASS : PDK_CDS_LIB = $TECH_PDK_CDS_LIB"
endif

foreach item ( \
    "$VERIFY_HCELL_LEF_LIST" \
    "$VERIFY_SOURCE_SPICE_SPEC" \
)
    if (! -e "$item") then
        echo "ERROR: missing Verify setup file: $item"
        @ errors++
    endif
end

if (! -e "$CALIBRE_CSHRC") then
    echo "WARN : Calibre cshrc not found: $CALIBRE_CSHRC"
    @ warnings++
endif
if (! -e "$CALIBRE_LICENSE_CSHRC") then
    echo "WARN : Calibre license cshrc not found: $CALIBRE_LICENSE_CSHRC"
    @ warnings++
endif

echo "----------------------------------------------------------------------"
echo "PRECHECK: errors=$errors warnings=$warnings"
echo "======================================================================"
echo ""

if ($errors > 0) exit 1
exit 0
