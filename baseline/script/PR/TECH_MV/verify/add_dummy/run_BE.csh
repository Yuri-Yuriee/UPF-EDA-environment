#!/bin/tcsh
setenv VERIFY_ROOT `cd ..; pwd`
source "$VERIFY_ROOT/config.csh"

mkdir -p log output rpt build/current .stage
rm -f "$VERIFY_ROOT/add_dummy/.stage/BE.done"
rm -f "build/current/BEOL.gds"

if (! -e "$VERIFY_GDS") then
    echo "ERROR: raw GDS not found: $VERIFY_GDS"
    exit 1
endif

if (-e "$CALIBRE_CSHRC") source "$CALIBRE_CSHRC"
if (-e "$CALIBRE_LICENSE_CSHRC") source "$CALIBRE_LICENSE_CSHRC"

set deckFile = "$TECH_DUMMY_BE_DECK"
if (! -e "$deckFile") then
    echo "ERROR: TECH BEOL dummy deck not found: $deckFile"
    exit 1
endif

cp -f "$deckFile" ./build/current/Dummy_BEOL_CalibreYE
sed -i -e 's/#DEFINE WITH_SEALRING/\/\/#DEFINE WITH_SEALRING/g' ./build/current/Dummy_BEOL_CalibreYE
sed -i -e 's/#DEFINE UseprBoundary/\/\/#DEFINE UseprBoundary/g' ./build/current/Dummy_BEOL_CalibreYE

sed "s|@RAW_GDS@|$VERIFY_GDS|g" ./scr/runset_BE.template.cmd > ./build/current/runset_BE.generated.cmd

cd "$VERIFY_ROOT/add_dummy/build/current"
if ($status != 0) exit 1

"$VERIFY_ROOT/common/run_logged.sh" "$VERIFY_ROOT/add_dummy/log/runset_BE.log" \
    calibre -drc -hier -64 -turbo "$VERIFY_CPU_DUMMY" -hyper \
    -lmretry loop,maxretry:200,interval:200 \
    ./runset_BE.generated.cmd
set rc = $status
if ($rc == 0) then
    if (! -s "BEOL.gds") then
        echo "ERROR: BE dummy run returned success but output GDS is missing/empty: BEOL.gds"
        exit 1
    endif
    echo "stage=BE" >! "$VERIFY_ROOT/add_dummy/.stage/BE.done"
    echo "gds=BEOL.gds" >> "$VERIFY_ROOT/add_dummy/.stage/BE.done"
    date >> "$VERIFY_ROOT/add_dummy/.stage/BE.done"
    echo "PASS: BE dummy completed -> BEOL.gds"
endif
exit $rc
