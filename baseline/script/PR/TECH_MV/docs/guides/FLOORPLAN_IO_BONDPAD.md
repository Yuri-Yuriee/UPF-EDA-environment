# Floorplan, IO, Bond Pad, Power Domain, EndCap and WellTap Guide

## Stage01 order after Floorplan Update V1

`script/floorplan.tcl` is now split into explicit re-entrant phases so restore and
interactive IO redo do not re-source the complete Stage01 flow.

1. `create_floorplan`
2. `fp_run_io_placement_phase`
   - FinFET-grid die/core snap check
   - `read_io_file $IO_FILE -no_die_size_adjust`
   - `snap_floorplan -all`
   - optional `do_swap_io`
   - final `snap_floorplan -all`
3. Stage01 final pre-IO-filler FILL_IN_CELL_BOND_PAD_041 preview
4. fix IO pads / optional IO filler insertion
5. save `01_10_place_io.enc`
6. macro/PD setup according to `FLOORPLAN_MODE`
7. hard-macro placement / validation / fix
8. `finish_floorplan`
9. clear temporary standard-cell placement
10. optional PD row guard
11. EndCap + Power-Switch + WellTap boundary phase
12. final full `check_floorplan`
13. write floorplan and `01_99_floorplan.enc`

The old early full `check_floorplan` immediately after IO placement is removed.
At that time logical UPF groups can exist before physical PD geometry is valid,
which can create invalid/sentinel fence-bbox messages.  The full checker remains
at the completed Stage01 floorplan tail.

## FILL_IN_CELL_BOND_PAD_041 preview and `redo_IO`

At the Stage01 message:

```text
ACTION REQUIRED: FILL_IN_CELL_BOND_PAD_041 PREVIEW - final pre-IO-filler geometry gate
```

the Tcl flow is inside native Innovus `suspend`.  Two commands are available:

```tcl
redo_IO
redo_IO /path/to/new.io
```

`redo_IO` performs the following without creating a nested suspend:

1. delete temporary FILL_IN_CELL_BOND_PAD_041 preview objects;
2. set every current design instance to `unplaced`;
3. optionally replace the runtime `IO_FILE` with the supplied path;
4. re-run the Floorplan Bound selector against that IO_FILE;
5. recreate the floorplan using the newly selected IO_BOUND or CORE_CELL_BOUND mode;
6. re-run the same Stage01 IO placement/snap/HV-swap sub-flow using `read_io_file -no_die_size_adjust`;
7. recreate FILL_IN_CELL_BOND_PAD_041 preview using the configured parity policy;
8. overwrite the FILL_IN_CELL_BOND_PAD_041 preview DB with the new state;
9. return to the **same** `[SUSPEND]innovus>` prompt.

When the new IO/FILL_IN_CELL_BOND_PAD_041 state is accepted, type native Innovus:

```tcl
resume
```

Native Innovus `resume` **does not** re-read `IO_FILE` and **does not** rebuild the floorplan. It accepts the current in-memory IO/PAD placement at the suspend checkpoint, re-verifies the FILL_IN_CELL_BOND_PAD_041 preview, removes temporary FILL_IN_CELL_BOND_PAD_041 objects, writes the accepted checkpoint, and then continues the unfinished Stage01 Tcl flow. If the IO file was edited on disk and those edits must be applied, run `redo_IO` explicitly before typing `resume`.

The optional path supplied to `redo_IO` changes only the runtime `IO_FILE`
variable for the current Innovus session. It does not rewrite the setup config.
Because the IO file can change PAD count/order/offset/master usage, `redo_IO` also
recomputes IO minimum DIE W/H and the 70% Core/IO area ratio before reloading IO.

## Manual Global Net review at FILL_IN_CELL_BOND_PAD_041 preview

Both Stage01/Stage02 FILL_IN_CELL_BOND_PAD_041 action messages now remind the user to manually inspect
POWER/GROUND global nets before acceptance.  Suggested Stylus queries are:

```tcl
get_db nets -if {.is_power == true} .name
get_db nets -if {.is_ground == true} .name
```

This is a review reminder only.  The FILL_IN_CELL_BOND_PAD_041 helper does not automatically change
global-net connectivity.

## Floorplan restore semantics

Source:

```tcl
source run/tool/TT_proc_floorplan_resume.tcl
fp_points
```

Two checkpoint types are used.

### NORMAL

```tcl
fp_restore after_io
# inspect/edit restored DB
fp_continue
```

`fp_restore` reads the DB and stops.  It does not automatically continue.

### SUSPEND

```tcl
fp_restore suspend_bond_pad_preview
```

The helper reads the pre-suspend DB and reconstructs a new native Innovus
`suspend` call stack.  The console returns to:

```text
[SUSPEND]innovus>
```

Use native:

```tcl
resume
```

to continue the unfinished Stage01 script.

Formal points include:

- `suspend_bond_pad_preview`
- `after_bond_pad_preview`
- `after_io`
- `suspend_manual_power_domain`
- `suspend_manual_macro`
- `after_pd_row_guard`
- `before_boundary_cells`
- `after_endcap_power_switch_before_welltap`
- `suspend_after_endcap_power_switch_before_welltap`
- `after_boundary_cells`
- `stage01_complete`

The EndCap/Power-Switch checkpoint filenames are intentionally separated:

- `01_80_after_endcap_power_switch_before_welltap.enc` — NORMAL snapshot
- `01_81_suspend_after_endcap_power_switch_before_welltap.enc` — pre-suspend snapshot

This prevents one filename from having two restore meanings.

## TT naming applied in this Floorplan update

Canonical names:

- `TT_flow_check_bond_pad.tcl` — executable read-only bond-pad check
- `TT_proc_check_pd_endcaps.tcl` — procedure library used by checkpoint guard
- `TT_proc_bond_pad_preview.tcl`
- `TT_proc_floorplan_resume.tcl`
- `TT_flow_snap_die.tcl`

The old files `TT_check_bond_pad.tcl` and `TT_check_pd_endcaps.tcl` are removed by
the installer after backup.  The legacy Tcl command `TT_check_bond_pad` remains
as a compatibility alias inside the new flow file.

## WellTap state

WellTap is deliberately **not modified** by Floorplan Update V1.  The installer
records its SHA256 before installation and verifies the exact same file after
installation.


## Floorplan Bound minimum IO-ring gap (V1.4)

IO-bound sizing reserves a minimum edge-to-edge gap between every adjacent IO-ring element on each side. The default is configured in `setup/config/01_floorplan.config.tcl`:

Set `FLOORPLAN_IO_PAD_MIN_GAP` to the required minimum gap in the runtime config.

For N elements on one side, at least `(N-1) * FLOORPLAN_IO_PAD_MIN_GAP` is included in the side-length requirement. Explicit offsets are treated as anchors, but an anchor smaller than `previous_end + min_gap` is reported as a spacing/offset conflict and the conservative legal packed coordinate is used for floorplan sizing. `redo_IO` re-runs the same selector and therefore inherits this rule automatically.
