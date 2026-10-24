#!/bin/tcsh
setenv VERIFY_ROOT `cd ..; pwd`
source "$VERIFY_ROOT/config.csh"

mkdir -p log output rpt build/current .stage
rm -f "$VERIFY_ROOT/add_dummy/.stage/COD.done"
rm -f "build/current/COD.gds"

if (! -e "$VERIFY_GDS") then
    echo "ERROR: raw GDS not found: $VERIFY_GDS"
    exit 1
endif

if (-e "$CALIBRE_CSHRC") source "$CALIBRE_CSHRC"
if (-e "$CALIBRE_LICENSE_CSHRC") source "$CALIBRE_LICENSE_CSHRC"

set deckFile = "$TECH_DUMMY_COD_DECK"
if (! -e "$deckFile") then
    echo "ERROR: TECH COD deck not found: $deckFile"
    exit 1
endif

cp -f "$deckFile" ./build/current/COD_AutoGen
sed -i -e 's/#DEFINE WITH_SEALRING/\/\/#DEFINE WITH_SEALRING/g' ./build/current/COD_AutoGen
sed -i -e 's/#DEFINE UseprBoundary/\/\/#DEFINE UseprBoundary/g' ./build/current/COD_AutoGen

sed "s|@RAW_GDS@|$VERIFY_GDS|g" ./scr/runset_COD.template.cmd > ./build/current/runset_COD.generated.cmd

cd "$VERIFY_ROOT/add_dummy/build/current"
if ($status != 0) exit 1

"$VERIFY_ROOT/common/run_logged.sh" "$VERIFY_ROOT/add_dummy/log/runset_COD.log" \
    calibre -drc -hier -64 -turbo "$VERIFY_CPU_DUMMY" -hyper \
    -lmretry loop,maxretry:200,interval:200 \
    ./runset_COD.generated.cmd
set rc = $status
if ($rc == 0) then
    if (! -s "COD.gds") then
        echo "ERROR: COD dummy run returned success but output GDS is missing/empty: COD.gds"
        exit 1
    endif
    echo "stage=COD" >! "$VERIFY_ROOT/add_dummy/.stage/COD.done"
    echo "gds=COD.gds" >> "$VERIFY_ROOT/add_dummy/.stage/COD.done"
    date >> "$VERIFY_ROOT/add_dummy/.stage/COD.done"
    echo "PASS: COD dummy completed -> COD.gds"
endif
exit $rc
