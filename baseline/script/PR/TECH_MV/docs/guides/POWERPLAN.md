# TECH_MV PowerPlan Guide

## Modes

`POWERPLAN_MODE` supports `legacy`, `pns`, or `none`. The current baseline default is `legacy`.

`run/02_powerplan.tcl` performs PD/grid guards and precheck, re-sources the global-net mapping, then invokes `script/powerplan.tcl` for legacy mode or `run/pns.tcl` for PNS mode. After the base mesh it always calls `tech_mv_powerplan_stage_tail` and the formal Stage02 end guard.

## Legacy PowerPlan sequence

The current `script/powerplan.tcl` includes:

- temporary FILL_IN_CELL_BOND_PAD_041-derived `BondPadBlk`
- core ring creation
- pad-pin PG connection
- macro PG route blockages
- block rings / PD-specific ring logic
- global and PD stripe generation
- floating-stripe SRoute
- temporary blockage cleanup
- via repair
- DRC checkpoint after stripes
- follow-pin PG routing per physical PD
- follow-pin cleanup / via repair / DRC
- power-mesh colorization and PG model generation
- DRC before and after final min-step via repair
- final `02_90_powerplan_mesh.enc`

## Current durable restore points

`run/tool/TT_proc_powerplan_resume.tcl` currently advertises:

- `after_block_rings` → `02_25_after_block_rings.enc`
- `after_all_stripes` → `02_27_after_all_stripes.enc`
- `after_floating_sroute` → `02_33_after_floating_sroute.enc`
- `before_power_stripe_drc` → `02_34_before_power_stripe_drc.enc`
- `after_power_stripe_drc` → `02_35_after_power_stripe_drc.enc`
- `after_follow_pin_drc` → `02_45_after_follow_pin_drc.enc`
- `before_final_via_repair_drc` → `02_70_before_final_via_repair_drc.enc`
- `after_final_via_repair_drc` → `02_80_after_final_via_repair_drc.enc`
- `after_switch_verify` → `02_91_after_switch_verify.enc`
- `after_secondary_pg` → `02_92_after_secondary_pg.enc`
- `after_final_mesh_color` → `02_93_after_final_mesh_color.enc`
- `after_final_check` → `02_95_after_final_check.enc`
- `suspend_bond_pad_preview` → `02_97_bond_pad_powerplan_preview.enc` (SUSPEND)
- `after_bond_pad_preview` → `02_98_after_bond_pad_preview.enc`
- `stage02_complete` → `02_99_powerplan.enc`
- `stage02_exit` → `02_100_stage02_exit.enc`

Resume V1.5 uses explicit checkpoint semantics. For NORMAL points, `pp_restore <point>` reads the DB and HOLDS; inspect/edit the restored state and run `pp_continue` to execute only the continuation after that checkpoint. `pp_restore_resume <point>` retains explicit one-shot compatibility. Stage02 FILL_IN_CELL_BOND_PAD_041 also has a true SUSPEND point, `suspend_bond_pad_preview` (02_97), which reconstructs a fresh native Innovus `suspend` call stack and waits for native `resume`.

## Interactive PowerPlan step pause

`script/powerplan_step_pause.tcl` can optionally report, save a step DB, and execute native Innovus `suspend`. These step pauses are distinct from the durable restore points above and may occur inside loops; they should not automatically be treated as deterministic resume boundaries without explicit loop-state handling.

## DRC checkpoint helper

`script/powerplan_drc_checkpoint.tcl` runs `check_drc`, writes a report, optionally saves a violation DB, and can suspend on violations. Current debug DB names are separate from durable resume DB names (for example, the after-stripe violation DB is step 36 while the durable post-checkpoint DB is step 35).

## Metal density tool

`run/tool/TT_tool_report_metal_density.tcl` exists as a manual tool in this baseline. It is **not yet wired into `script/powerplan.tcl`**. Its requested future integration after stripe generation is therefore intentionally not part of this baseline.
