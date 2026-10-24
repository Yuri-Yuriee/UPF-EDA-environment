# TECH_MV Flow and Configuration Guide

## 1. Master/runtime architecture

The package contains the master copy of the TECH_MV environment. At runtime, APR executes from `build_PR/`.

Runtime paths established by `init.setup`:

- `SETUP_DIR = build_PR/setup`
- `RUN_DIR = build_PR/run`
- `TOOL_DIR = build_PR/run/tool`
- `SCRIPT_DIR = ../script/PR/TECH_MV/script`
- generated state: `build_PR/dbs`, `outputs`, `reports`, `logs`, `temp`

`init.setup` intentionally rejects execution when its own directory is not named `build_PR`. Therefore the root `Makefile` in this package is a runtime template when used for APR; the master package itself is not the direct APR working directory.

## 2. Configuration loading

`setup/config.tcl` explicitly loads exactly nine configuration components on every `init.setup`:

1. `00_input.config.tcl` — collateral paths, IO, netlist, SDC, UPF source, LEFs, MMMC/QRC, GDS stream merge inputs.
2. `00_design.config.tcl` — design/power-domain identity and shared design settings.
3. `01_floorplan.config.tcl` — floorplan, IO, PD, EndCap/WellTap, bond-pad preview controls.
4. `02_powerplan.config.tcl` — PowerPlan mode, rings/stripes, DRC/checkpoint and Stage02 options.
5. `03_place.config.tcl` — placement behavior.
6. `04_cts.config.tcl` — CTS behavior.
7. `05_route.config.tcl` — route and secondary-PG behavior.
8. `06_finish.config.tcl` — filler/final output/signoff behavior.
9. `90_debug.config.tcl` — debug-only switches.

The package-local `setup/UPF/` directory is not used by the current config. UPF is resolved from `../script/MV/UPF` via `UPF_SOURCE_DIR`.

## 3. Stage entry points

Normal APR entry files are under `run/`:

- Stage00: `run/00_import_design.tcl`
- Stage01: `run/01_floorplan.tcl`
- Stage02: `run/02_powerplan.tcl`
- Stage03: `run/03_place.tcl`
- Stage04: `run/04_cts.tcl`
- Stage05: `run/05_route.tcl`
- Stage06: `run/06_finish.tcl`
- Complete sequence: `run/runset.tcl`

Every stage reloads `init.setup`, which reloads all nine config files.

## 4. Stage summary

### Stage00 — Import

Import design/collateral, commit MSV, apply config, create PG/RTE pads, optional IOPAD ring model, optional IO generation, global-net mapping, IO-file consistency gate, read-only 2nd-PG readiness check, then save `00_99_import.enc`.

### Stage01 — Floorplan

Create floorplan, snap die/core grid, read/swap/snap IO, perform FILL_IN_CELL_BOND_PAD_041 preview gate, place/reshape PDs and hard macros, finish floorplan, create PD boundary row guard, insert EndCap/Power Switch/WellTap cells, final floorplan check, then save `01_99_floorplan.enc`.

### Stage02 — PowerPlan

Precheck PD/grid state, re-apply global-net mapping, execute legacy or PNS power planning, then common Stage02 tail (switch verification, secondary PG, mesh color/final check, FILL_IN_CELL_BOND_PAD_041 preview), stage-end guard, and `02_100_stage02_exit.enc`.

### Stage03 — Place

Placement, optimization, checkpointing, optional SROUTE-mode secondary-PG handling, and stage guards.

### Stage04 — CTS

Clock-tree configuration/build/optimization with placement checkpoints and guards.

### Stage05 — Route

Optional SIGNAL secondary-PG routing before route, route design, padding/same-mask repair, post-route optimization, final DRC/via repair and `05_99_route.enc`.

### Stage06 — Finish

Add fillers, optional final FILL_IN_CELL_BOND_PAD_041/RDL/boundary, final DRC/via cleanup, connectivity check, save `06_99_finish.enc`, and optionally emit GDS/netlist/SDF.

## 5. Global-net file

`setup/global_net.tcl` is the active mapping file. Stage00 sources it and Stage02 re-sources it before PG work. It currently uses compatibility/legacy global-net commands through the Innovus environment.

## 6. External collateral

The baseline references workstation/site paths for PDK LEF/lib/QRC/GDS and project-relative synthesis/UPF files. Static package validation can verify the path expressions and source layout, but cannot confirm those workstation paths from this container.
