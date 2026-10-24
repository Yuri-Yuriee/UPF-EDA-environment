#!/bin/tcsh
setenv VERIFY_ROOT `cd ..; pwd`
source "$VERIFY_ROOT/config.csh"

mkdir -p log output rpt build/current .stage
rm -f "$VERIFY_ROOT/add_dummy/.stage/FE.done"
rm -f "build/current/FEOL.gds"

if (! -e "$VERIFY_GDS") then
    echo "ERROR: raw GDS not found: $VERIFY_GDS"
    exit 1
endif

if (-e "$CALIBRE_CSHRC") source "$CALIBRE_CSHRC"
if (-e "$CALIBRE_LICENSE_CSHRC") source "$CALIBRE_LICENSE_CSHRC"

set deckFile = "$TECH_DUMMY_FE_DECK"
if (! -e "$deckFile") then
    echo "ERROR: TECH FEOL dummy deck not found: $deckFile"
    exit 1
endif

cp -f "$deckFile" ./build/current/Dummy_FEOL_CalibreYE
sed -i -e 's/#DEFINE WITH_SEALRING/\/\/#DEFINE WITH_SEALRING/g' ./build/current/Dummy_FEOL_CalibreYE
sed -i -e 's/#DEFINE UseprBoundary/\/\/#DEFINE UseprBoundary/g' ./build/current/Dummy_FEOL_CalibreYE

sed "s|@RAW_GDS@|$VERIFY_GDS|g" ./scr/runset_FE.template.cmd > ./build/current/runset_FE.generated.cmd

cd "$VERIFY_ROOT/add_dummy/build/current"
if ($status != 0) exit 1

"$VERIFY_ROOT/common/run_logged.sh" "$VERIFY_ROOT/add_dummy/log/runset_FE.log" \
    calibre -drc -hier -64 -turbo "$VERIFY_CPU_DUMMY" -hyper \
    -lmretry loop,maxretry:200,interval:200 \
    ./runset_FE.generated.cmd
set rc = $status
if ($rc == 0) then
    if (! -s "FEOL.gds") then
        echo "ERROR: FE dummy run returned success but output GDS is missing/empty: FEOL.gds"
        exit 1
    endif
    echo "stage=FE" >! "$VERIFY_ROOT/add_dummy/.stage/FE.done"
    echo "gds=FEOL.gds" >> "$VERIFY_ROOT/add_dummy/.stage/FE.done"
    date >> "$VERIFY_ROOT/add_dummy/.stage/FE.done"
    echo "PASS: FE dummy completed -> FEOL.gds"
endif
exit $rc
