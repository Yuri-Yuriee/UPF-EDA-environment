#!/bin/tcsh
./run_BE.csh
if ($status != 0) exit $status

./run_COD.csh
if ($status != 0) exit $status

./run_FE.csh
if ($status != 0) exit $status

./run_merge.csh
exit $status
