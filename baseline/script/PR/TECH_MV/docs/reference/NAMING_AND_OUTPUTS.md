# TECH_MV Naming, Database and Report Reference

## Tool naming

Current convention:

- `TT_proc_*` — procedure libraries / callable helpers.
- `TT_flow_*` — flow scripts or flow-level helpers.
- `TT_check_*` — checks/reporting tools.
- `TT_tool_*` — standalone manual tools.

Normal flow implementation helpers live under `script/` rather than being named as TT tools.

## Stage DB naming

The project uses two-digit stage prefixes:

- `00_*` Import
- `01_*` Floorplan
- `02_*` PowerPlan
- `03_*` Place
- `04_*` CTS
- `05_*` Route
- `06_*` Finish

`*_99_*` conventionally represents a stage-complete database, while additional numbered DBs are intermediate/debug/restore checkpoints. Stage02 also uses `02_100_stage02_exit.enc` after the formal end guard.

## Reports

`script/report_utils.tcl` centralizes report directory/path creation. Reports are staged under `REPORT_DIR` with stage/category-safe names rather than relying on the current working directory.

## Important generated directories

Runtime-only under `build_PR`:

- `dbs/`
- `outputs/`
- `reports/`
- `logs/`
- `temp/`

These are not master source material and must not be synchronized into `script/PR/TECH_MV` as source.
