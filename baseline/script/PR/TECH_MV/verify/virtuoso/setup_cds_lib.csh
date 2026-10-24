#!/bin/tcsh
setenv VERIFY_ROOT `cd ..; pwd`
source "$VERIFY_ROOT/config.csh"

set out = "$VERIFY_ROOT/virtuoso/cds.lib"

echo 'DEFINE basic $CDSHOME/tools/dfII/etc/cdslib/basic' > "$out"
echo 'DEFINE analogLib $CDSHOME/tools/dfII/etc/cdslib/artist/analogLib' >> "$out"
if ("$TECH_PDK_CDS_LIB" == "") then
    echo "ERROR: TECH_PDK_CDS_LIB is not configured."
    exit 1
endif
echo "INCLUDE $TECH_PDK_CDS_LIB" >> "$out"

echo "Generated $out"
