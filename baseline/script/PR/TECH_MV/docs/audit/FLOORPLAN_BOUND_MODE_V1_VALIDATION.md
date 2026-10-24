# Floorplan Bound Mode V1 Validation

Date: 2026-09-07

## Root-cause correction

The previous DIE-snap concern is retired. The observed DIE adjustment was caused by
`read_io_file` being used without `-no_die_size_adjust`.

The Stage01 flow and IO PAD GUI generated Apply Tcl now always use:

```tcl
read_io_file <IO_FILE> -no_die_size_adjust
```

## Automatic bound classification

Total design cell area authority:

```tcl
get_db current_design .area
```

PAD/ring area is computed from base-cell bbox geometry for the union of:

- all Innovus instances where `.is_pad == true`; and
- every IO_FILE side entry (so RTE/cut-style ring elements not flagged as `.is_pad` are still counted).

Then:

```text
core_cell_area = design_area - pad_area
```

IO minimum width/height are rebuilt from IO_FILE side order, explicit offset anchors,
and final side-aware PAD master WIDTH. DB instance `.location` is not used.

With a [請填入本地確認的尺寸] core margin on every side:

```text
io_usable_core_w = io_min_die_w - 600
io_usable_core_h = io_min_die_h - 600
io_floorplan_area = io_usable_core_w * io_usable_core_h
ratio = core_cell_area / io_floorplan_area
```

Selection:

```text
ratio > 0.70  -> CORE_CELL_BOUND
otherwise     -> IO_BOUND
```

## Applied floorplan commands

IO-bound:

```tcl
set_io_flow_flag 0
create_floorplan -core_margins_by die -site core \
    -die_size <recommended_w> <recommended_h> 300 300 300 300
read_io_file <IO_FILE> -no_die_size_adjust
snap_floorplan -all
check_floorplan
```

Core-cell-bound:

```tcl
set_io_flow_flag 0
create_floorplan -site core \
    -core_density_size 1 0.7 300 300 300 300
read_io_file <IO_FILE> -no_die_size_adjust
snap_floorplan -all
check_floorplan
```

## GUI

V118 adds a Floorplan Bound Mode status line on Ring View and a non-blocking
`FLOORPLAN_BOUND_MODE` INFO row in Issues. IO-bound mode also reports the suggested
DIE width/height.

## Validation performed

- Python module compiles with `py_compile`.
- Generated standalone Innovus Query Tcl parses/runs under a Tcl mock.
- New bound selector Tcl and local bridge Tcl source successfully under `tclsh`.
- Synthetic selector test exercised the IO-bound command path.
- Runtime Tcl search confirms every active `read_io_file` call uses
  `-no_die_size_adjust`.
- WellTap files were not modified.

## redo_IO parity with fresh Stage01

The Stage01 FILL_IN_CELL_BOND_PAD_041-preview `redo_IO ?new_IO_FILE?` path now performs the same
Floorplan Bound selection as a fresh Stage01 run. After deleting temporary FILL_IN_CELL_BOND_PAD_041
and unplacing all instances it executes:

```tcl
TT_floorplan_bound_create $::IO_FILE
```

before re-running the IO placement phase. Therefore a changed IO_FILE can alter:

- IO minimum DIE width/height;
- Core/IO area ratio;
- selected `IO_BOUND` / `CORE_CELL_BOUND` mode; and
- the actual `create_floorplan` command used by the redo.

The subsequent IO reload remains:

```tcl
read_io_file $::IO_FILE -no_die_size_adjust
```

`redo_IO` also returns the selected bound mode and ratio in its result dictionary.


## V1.4 minimum-gap extension

The IO-bound side-length model now reserves a configurable minimum gap between adjacent ring elements. The minimum gap is selected by FLOORPLAN_IO_PAD_MIN_GAP in the runtime stage config. For a side containing N elements, at least (N-1)*FLOORPLAN_IO_PAD_MIN_GAP is included in the packed side requirement. APR selector and GUI classifier use the same rule.
