# TECH_MV Verify Guide

## Purpose

The Verify environment combines TECH-specific LVS/Dummy/DRC/Antenna execution with a Makefile-driven runtime layout.

Main commands from `verify/`:

- `make check`
- `make hcell`
- `make source_inc`
- `make v2lvs`
- `make lvs`
- `make dummy`
- `make drc`
- `make antenna`
- `make signoff`
- `make status`
- `make clean`

The root Makefile exposes corresponding `verify`, `signoff`, `verify_check`, `verify_hcell`, `verify_status`, `dummy`, `lvs`, `drc`, and `antenna` targets.

## Source vs generated files

The clean baseline keeps only Verify source/environment files. Runtime-generated material found in the workstation archive was removed from this baseline, including:

- `verify/add_dummy/.stage/*.done`
- `verify/add_dummy/scr/runset_*.generated.cmd`
- copied/generated Dummy/COD decks under `verify/add_dummy/scr/`
- generated `log/`, `output/`, `rpt/`, and `lvs/svdb/` trees

These files are explicitly generated/removed by the Verify scripts and `make clean`; they are not master source collateral.

## LVS

`make hcell` generates `lvs/HCELL`, `lvs/LVSBOX` and its report from current LEFs.

`make source_inc` generates `lvs/CHIP_inc.spi`.

`make v2lvs` converts the project PG netlist to `lvs/CHIP.spi`.

`make lvs` assembles the generated runset and executes Calibre LVS in scratch space, then copies final result data back for debug.

## Dummy / COD

Expected order:

1. BEOL
2. COD
3. FEOL
4. MERGE

The final merged GDS keeps the validated project filename `add_dummy/CHIP_adddummmy.gds.gz`.

## DRC / Antenna

Both operate on the dummy-merged GDS and are gated by `common/check_dummy_ready.sh` so DRC/Antenna cannot proceed with stale/incomplete dummy stages.

## Runtime location

The intended project arrangement is:

- master Verify environment: `script/PR/TECH_MV/verify/`
- runtime copy: `build_PR/verify/`
- APR outputs: `build_PR/outputs/`, `build_PR/dbs/`

A synchronization back to the master should update only established Verify source/environment files, never runtime-only generated outputs.
