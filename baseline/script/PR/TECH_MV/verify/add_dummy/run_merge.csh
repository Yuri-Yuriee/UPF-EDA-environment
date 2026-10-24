#!/bin/tcsh
setenv VERIFY_ROOT `cd ..; pwd`
source "$VERIFY_ROOT/config.csh"

mkdir -p log output build/current .stage
rm -f "$VERIFY_ROOT/add_dummy/.stage/MERGE.done"
rm -f "$VERIFY_DUMMY_GDS"

if (! -e "$VERIFY_GDS") then
    echo "ERROR: raw GDS not found: $VERIFY_GDS"
    exit 1
endif

foreach marker (BE.done COD.done FE.done)
    if (! -e "$VERIFY_ROOT/add_dummy/.stage/$marker") then
        echo "ERROR: dummy stage is not formally complete before merge: $VERIFY_ROOT/add_dummy/.stage/$marker"
        echo "       Run the complete dummy flow: make verify_dummy"
        exit 1
    endif
end

foreach dm (BEOL.gds FEOL.gds COD.gds)
    if (! -s "build/current/$dm") then
        echo "ERROR: missing/empty dummy/COD GDS before merge: $dm"
        exit 1
    endif
end

if (-e "$CALIBRE_CSHRC") source "$CALIBRE_CSHRC"
if (-e "$CALIBRE_LICENSE_CSHRC") source "$CALIBRE_LICENSE_CSHRC"

sed "s|@RAW_GDS@|$VERIFY_GDS|g" ./scr/runset_merge.template.cmd > ./build/current/runset_merge.generated.cmd

cd "$VERIFY_ROOT/add_dummy/build/current"
if ($status != 0) exit 1

"$VERIFY_ROOT/common/run_logged.sh" "$VERIFY_ROOT/add_dummy/log/runset_merge.log" \
    calibredrv -64 ./runset_merge.generated.cmd
set rc = $status
if ($rc == 0) then
    if (! -s "$VERIFY_DUMMY_GDS") then
        echo "ERROR: merge returned success but final dummy GDS is missing/empty: $VERIFY_DUMMY_GDS"
        exit 1
    endif
    echo "stage=MERGE" >! "$VERIFY_ROOT/add_dummy/.stage/MERGE.done"
    echo "gds=$VERIFY_DUMMY_GDS" >> "$VERIFY_ROOT/add_dummy/.stage/MERGE.done"
    date >> "$VERIFY_ROOT/add_dummy/.stage/MERGE.done"
    echo "PASS: Full dummy merge completed -> $VERIFY_DUMMY_GDS"
endif
exit $rc
