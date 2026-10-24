#!/bin/tcsh
setenv VERIFY_ROOT `cd ..; pwd`
source "$VERIFY_ROOT/config.csh"

mkdir -p rpt log output build/current

# DRC/Antenna must NEVER run on raw APR GDS or a partial dummy result.
"$VERIFY_ROOT/common/check_dummy_ready.sh" "$VERIFY_ROOT" "$VERIFY_GDS" "$VERIFY_DUMMY_GDS"
if ($status != 0) then
    exit 1
endif

if (-e "$CALIBRE_CSHRC") source "$CALIBRE_CSHRC"
if (-e "$CALIBRE_LICENSE_CSHRC") source "$CALIBRE_LICENSE_CSHRC"

set deckFile = "$TECH_ANTENNA_DECK"
if (! -e "$deckFile") then
    echo "ERROR: TECH Antenna deck not found: $deckFile"
    exit 1
endif

cp -f "$deckFile" ./build/current/ANTENNA_DRC
sed -i -f "$VERIFY_ROOT/config/private/deck_transform_run_antenna_01.sed" ./build/current/ANTENNA_DRC
sed -i -f "$VERIFY_ROOT/config/private/deck_transform_run_antenna_02.sed" ./build/current/ANTENNA_DRC
sed -i -f "$VERIFY_ROOT/config/private/deck_transform_run_antenna_03.sed" ./build/current/ANTENNA_DRC

sed -f "$VERIFY_ROOT/config/private/runset_antenna_names.sed" -e "s|@DUMMY_GDS@|$VERIFY_DUMMY_GDS|g" ./scr/runset_ANTENNA.template.cmd > ./build/current/runset_ANTENNA.generated.cmd

cd "$VERIFY_ROOT/drc/build/current"
if ($status != 0) exit 1

"$VERIFY_ROOT/common/run_logged.sh" "$VERIFY_ROOT/drc/log/runset_ANTENNA.log" \
    calibre -drc -hier -64 -turbo "$VERIFY_CPU_ANTENNA" -hyper \
    -lmretry loop,maxretry:200,interval:200 \
    ./runset_ANTENNA.generated.cmd

set rc = $status
exit $rc
