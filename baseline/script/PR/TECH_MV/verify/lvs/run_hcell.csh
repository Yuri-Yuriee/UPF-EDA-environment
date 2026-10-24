#!/bin/tcsh
setenv VERIFY_ROOT `cd ..; pwd`
source "$VERIFY_ROOT/config.csh"

mkdir -p rpt
tclsh ./scr/genHcell.tcl
if ($status != 0) exit $status
