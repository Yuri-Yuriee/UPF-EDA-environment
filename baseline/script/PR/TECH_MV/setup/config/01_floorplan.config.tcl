# =============================================================================
# 01 - Floorplan / Macro / Power Switch / EndCap / WellTap
# =============================================================================

# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set CORE_SITE {FILL_IN_CORE_SITE}

# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set FLOORPLAN_DIE_SIZE {FILL_IN_FLOORPLAN_DIE_SIZE}

# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set FLOORPLAN_BOX_SIZE {FILL_IN_FLOORPLAN_BOX_SIZE}


# =============================================================================
# Automatic floorplan bound selection
# =============================================================================
# AUTO policy:
#   core_cell_area = get_db current_design .area - PAD/ring area
#   io_min_die_w/h = packed IO_FILE minimum using explicit offsets and each
#                    final side-aware PAD master WIDTH; DB .location is ignored.
#   io_floorplan_area = (io_min_die_w - 2*margin) *
#                       (io_min_die_h - 2*margin)
# Technology-specific documentation is retained in the private setup backup.
#   otherwise                                  -> IO_BOUND
#
# FLOORPLAN_BOUND_MODE:
#   auto            : use the ratio rule above (default)
#   io_bound        : force IO-bound create_floorplan
#   core_cell_bound : force utilization-based create_floorplan
set FLOORPLAN_BOUND_MODE auto
# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set FLOORPLAN_BOUND_THRESHOLD {FILL_IN_FLOORPLAN_BOUND_THRESHOLD}

# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set FLOORPLAN_BOUND_MARGIN {FILL_IN_FLOORPLAN_BOUND_MARGIN}

# Minimum edge-to-edge spacing required between every adjacent IO-ring element
# on the same side.  This spacing is included in IO-bound minimum DIE W/H.
# Technology-specific documentation is retained in the private setup backup.
# 請填入已確認的幾何值或幾何 dict，單位依呼叫端
set FLOORPLAN_IO_PAD_MIN_GAP {FILL_IN_FLOORPLAN_IO_PAD_MIN_GAP}

# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set FLOORPLAN_CORE_DENSITY_ASPECT_RATIO {FILL_IN_FLOORPLAN_CORE_DENSITY_ASPECT_RATIO}

# 請填入本地 floorplan／placement 的利用率或密度比例
set FLOORPLAN_CORE_DENSITY_TARGET {FILL_IN_FLOORPLAN_CORE_DENSITY_TARGET}

set ENABLE_IO_SWAP    true
set ENABLE_IO_FILLERS true

# Keep side pads away from the four corner cells so adjacent FILL_IN_CELL_BOND_PAD_041 objects do
# not collide around TR/TL/BL/BR.  The IO generator writes an explicit offset
# on the first and last pad of every side.  This is a user-tunable physical
# constraint, not a loop-until-pass search.
set ENABLE_IO_CORNER_OFFSET true
# 請填入已確認的幾何值或幾何 dict，單位依呼叫端
set IO_CORNER_PAD_OFFSET {FILL_IN_IO_CORNER_PAD_OFFSET}
# =============================================================================
# RTE PAD placement
# =============================================================================
# One RTE pad is created for each external core power-supply type.
#
# Default:
#   POWER_PORT_NETS = {VDD_LEVEL_01 VDD_LEVEL_02}
#   -> 2 RTE pads total.
#
# The first supply reuses the existing logical instance "pad_RTE".
# Additional supplies clone the same base cell and are named:
#
#   pad_RTE_<SUPPLY_NAME>
#
# All RTE pads connect their RTE pin to io_rte.
#
# Placement policy:
#   - place the RTE group on the TOP side;
#   - follow the IO-file counter-clockwise traversal;
#   - for each secondary supply, put its RTE pad immediately after
#     RAILCUT_<SUPPLY>_TOP1;
#   - put the first/base-supply RTE pad immediately after the final
#     RAILCUT_<LAST_SUPPLY>_TOP2.
#
# All pad instances are fixed by the existing floorplan flow after read_io_file.
set ENABLE_SUPPLY_RTE_PADS true
set RTE_PAD_SUPPLY_NETS $POWER_PORT_NETS
set RTE_PAD_TEMPLATE_INSTANCE pad_RTE
set RTE_PAD_INSTANCE_PREFIX pad_RTE
# 請填入 library pin 名稱或接腳對應 dict
set RTE_PAD_PIN {FILL_IN_RTE_PAD_PIN}

set RTE_PAD_NET io_rte
set RTE_PAD_SIDE top
set RTE_PAD_DIRECTION counterclockwise

# Safety guard: reuse actual existing RTE-pad capacity before creating clones.
# true  : if enough compatible RTE pads already exist, create none;
#         otherwise create only the deficit.
# false : preserve only the template pad_RTE as reusable capacity.
set RTE_PAD_REUSE_EXISTING true

# Bond-pad assignment for auto-created RTE pads.
# Only supplies listed here are explicitly added as FILL_IN_CELL_BOND_PAD_041 bond-pad targets.
# Example for one supply only:
#   set RTE_PAD_BOND_ASSIGN_SUPPLIES {VDD_LEVEL_02}
# RTE pads are real pad-ring elements but do NOT receive FILL_IN_CELL_BOND_PAD_041 bond pads.
set RTE_PAD_BOND_ASSIGN_ENABLE false
# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set RTE_PAD_BOND_ASSIGN_SUPPLIES {FILL_IN_RTE_PAD_BOND_ASSIGN_SUPPLIES}



# auto | relative | file | gui
set FLOORPLAN_MODE auto
set FLOORPLAN_FILE [file join $SETUP_DIR ${TOP_MODULE}.fp]

set ENABLE_MANUAL_POWER_DOMAIN_PLACEMENT true
set MANUAL_POWER_DOMAIN_FLOORPLAN_MODES {auto gui}
set MANUAL_POWER_DOMAIN_NAMES {PD_TOP}
set MANUAL_POWER_DOMAIN_STRICT true

# Current active behavior is manual PD placement/snap.  These values replace the
# old hidden overrides that were previously hard-coded in run/01_floorplan.tcl.
set POWER_DOMAIN_RESHAPE_MODE none
set POWER_DOMAIN_RESHAPE_DOMAINS {PD_TOP}
set POWER_DOMAIN_CUT_OVERLAPS false
set POWER_DOMAIN_CUT_OVERLAP_DOMAINS {PD_TOP}
set POWER_DOMAIN_RESHAPE_STRICT true
# 請填入已確認的幾何值或幾何 dict，單位依呼叫端
set POWER_DOMAIN_CORE_OFFSET_CONFIG {FILL_IN_POWER_DOMAIN_CORE_OFFSET_CONFIG}

# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set POWER_DOMAIN_SCALE_CONFIG {FILL_IN_POWER_DOMAIN_SCALE_CONFIG}

# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set POWER_DOMAIN_ASPECT_RATIO_CONFIG {FILL_IN_POWER_DOMAIN_ASPECT_RATIO_CONFIG}

# Earlier PD placement checkpoint remains active; final duplicate pause is opt-in.
set ENABLE_MANUAL_PD_SNAP_BREAKPOINT false

# Macro placement.
# 請填入已確認的幾何值或幾何 dict，單位依呼叫端
set MACRO_PLACE_HALO {FILL_IN_MACRO_PLACE_HALO}

# 請填入已確認的幾何值或幾何 dict，單位依呼叫端
set MACRO_ROUTE_HALO_SPACE {FILL_IN_MACRO_ROUTE_HALO_SPACE}

# 請填入已確認的幾何值或幾何 dict，單位依呼叫端
set MACRO_ROUTE_HALO_BOTTOM_LAYER {FILL_IN_MACRO_ROUTE_HALO_BOTTOM_LAYER}

# 請填入已確認的幾何值或幾何 dict，單位依呼叫端
set MACRO_ROUTE_HALO_TOP_LAYER {FILL_IN_MACRO_ROUTE_HALO_TOP_LAYER}

# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set MACRO_MIN_SPACE_TO_CORE {FILL_IN_MACRO_MIN_SPACE_TO_CORE}

# Minimum hard-macro edge-to-edge channel reserved by the automatic mixed placer.
# Horizontal / vertical default = [請填入本地確認的尺寸].  An explicit refine_macro_place is run
# after place_macro_detail in FLOORPLAN_MODE auto to re-honor this constraint.
# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set MACRO_MIN_SPACE_TO_MACRO {FILL_IN_MACRO_MIN_SPACE_TO_MACRO}

# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set MACRO_CORNER_KEEPOUT {FILL_IN_MACRO_CORNER_KEEPOUT}

# 請填入已確認的幾何值或幾何 dict，單位依呼叫端
set MACRO_H_OFFSET {FILL_IN_MACRO_H_OFFSET}
# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set MACRO_H_SPACE {FILL_IN_MACRO_H_SPACE}

# 請填入已確認的幾何值或幾何 dict，單位依呼叫端
set MACRO_V_OFFSET {FILL_IN_MACRO_V_OFFSET}
# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set MACRO_V_SPACE {FILL_IN_MACRO_V_SPACE}

set DM_SRAM_ORIENT MY
# 請填入本地確認的容差或尺寸值（單位依欄位）
set CHECK_BBOX_TOLERANCE {FILL_IN_CHECK_BBOX_TOLERANCE}
# 請填入本地確認的容差或尺寸值（單位依欄位）
set FLOORPLAN_FINISH_PLACE_BLOCKAGE_SOFT_SIZE {FILL_IN_FLOORPLAN_FINISH_PLACE_BLOCKAGE_SOFT_SIZE}
# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set CLEAR_STD_CELLS_AFTER_MACRO_FLOORPLAN {FILL_IN_CLEAR_STD_CELLS_AFTER_MACRO_FLOORPLAN}

# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set CLEAR_STD_CELLS_BEFORE_POWERPLAN {FILL_IN_CLEAR_STD_CELLS_BEFORE_POWERPLAN}



# =============================================================================
# Power-Domain boundary guard
# =============================================================================
# Pre-macro phase:
#   Keep the existing macro_only placement guard so Hard Macros do not approach
#   an exposed Power-Domain boundary before finish_floorplan creates final rows.
#
# Final-row phase:
#   After finish_floorplan and temporary std-cell cleanup, physically CUT the
#   placement rows in a halo-like moat outside each exposed Power-Domain edge.
#   EndCaps are inserted only AFTER these row cuts so the newly-created row ends
#   are protected by boundary cells.
#
# A post-EndCap hard blockage is no longer needed by default because no legal
# placement rows remain in the moat.  It can still be enabled as a secondary
# safety layer if desired.
set ENABLE_PD_BOUNDARY_GUARD true
set PD_BOUNDARY_GUARD_DOMAINS auto
set PD_BOUNDARY_GUARD_EXCLUDE_DOMAINS {PD_core}
set PD_BOUNDARY_GUARD_WIDTH $MACRO_PLACE_HALO

set PD_BOUNDARY_GUARD_PRE_MACRO_ENABLE true
set PD_BOUNDARY_GUARD_POST_ENDCAP_ENABLE false
set PD_BOUNDARY_GUARD_STRICT true

# Physical row-cut guard.  Width follows the macro placement halo by default.
set ENABLE_PD_BOUNDARY_ROW_GUARD true
# 請填入已確認的幾何值或幾何 dict，單位依呼叫端
set PD_BOUNDARY_ROW_GUARD_WIDTH {FILL_IN_PD_BOUNDARY_ROW_GUARD_WIDTH}
set PD_BOUNDARY_ROW_GUARD_STRICT true
set PD_BOUNDARY_ROW_GUARD_SAVE_DB true
set PD_BOUNDARY_ROW_GUARD_DB_NAME 01_65_pd_row_guard.enc
# auto: prefer Stylus split_row, fall back to legacy cutRow through eval_legacy.
set PD_BOUNDARY_ROW_GUARD_BACKEND auto

# =============================================================================
# FILL_IN_CELL_BOND_PAD_041 preview / corner-overlap acceptance checkpoints
# =============================================================================
# Checkpoint #1 runs immediately after IO PAD placement, BEFORE IO fillers and
# BEFORE IO pads are fixed.  By default it uses the configured parity once; the
# old 16-combination brute-force parity search remains available only if
# BOND_PAD_PREVIEW_SEARCH_PARITY is explicitly enabled.
#
# Checkpoint #2 runs after the complete Stage02 PowerPlan final check.  It uses
# the same saved parity and recreates FILL_IN_CELL_BOND_PAD_041 again to prove that the PowerPlan
# flow did not invalidate the package-interface geometry.
#
# Both checkpoints create FILL_IN_CELL_BOND_PAD_041 only (no assignment / no manual AP RDL), save a
# GUI-inspection DB, suspend, re-check after resume, then delete the temporary
# FILL_IN_CELL_BOND_PAD_041 objects before the implementation flow continues.
set ENABLE_IO_BOND_PAD_PREVIEW true
# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set IO_BOND_PAD_PREVIEW_DB_NAME {FILL_IN_IO_BOND_PAD_PREVIEW_DB_NAME}

# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set IO_BOND_PAD_PREVIEW_AFTER_DB_NAME {FILL_IN_IO_BOND_PAD_PREVIEW_AFTER_DB_NAME}


set ENABLE_POWERPLAN_BOND_PAD_PREVIEW true
# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set POWERPLAN_BOND_PAD_PREVIEW_DB_NAME {FILL_IN_POWERPLAN_BOND_PAD_PREVIEW_DB_NAME}

# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set POWERPLAN_BOND_PAD_PREVIEW_AFTER_DB_NAME {FILL_IN_POWERPLAN_BOND_PAD_PREVIEW_AFTER_DB_NAME}


# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set BOND_PAD_PREVIEW_SEARCH_PARITY {FILL_IN_BOND_PAD_PREVIEW_SEARCH_PARITY}

# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set BOND_PAD_PREVIEW_STRICT_OVERLAP {FILL_IN_BOND_PAD_PREVIEW_STRICT_OVERLAP}

# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set BOND_PAD_PREVIEW_SAVE_DB {FILL_IN_BOND_PAD_PREVIEW_SAVE_DB}

set BOND_PAD_PARITY_FILE [file join $DB_DIR 01_bond_pad_parity.tcl]


# Compatibility alias for older helper/scripts.  V18 invokes the explicit
# IO and PowerPlan preview controls above.
set ENABLE_FLOORPLAN_BOND_PAD_PREVIEW $ENABLE_IO_BOND_PAD_PREVIEW
set BOND_PAD_PREVIEW_DB_NAME $IO_BOND_PAD_PREVIEW_DB_NAME


# Technology-specific selector documentation is retained in the private setup backup.
# whose marker bbox is contained by a FILL_IN_CELL_BOND_PAD_041 bbox are accepted for this package
# interface.  This does NOT globally waive Maximal_Width elsewhere.
# 請填入已確認的幾何值或幾何 dict，單位依呼叫端
set BOND_PAD_ACCEPT_INTERNAL_MAXWIDTH {FILL_IN_BOND_PAD_ACCEPT_INTERNAL_MAXWIDTH}


# =============================================================================
# IO-pad ring domain model
# =============================================================================
# The model is fully integrated into Stage00 and generate_io_file.tcl, but is
# activated only when IOPAD_RING_DOMAIN_CONFIG is populated.  No domain/net
# mapping is guessed here.
#
# Each domain entry is a dict containing:
#   name          <domain name>
#   side          top|right|bottom|left
#   io_power_net  <local IO power net>
#   rte_net       <local RTE net>
#   pads          <list of pad dictionaries>
#
# Each pad dictionary contains:
#   role          IO_POWER|RTE|GROUND|SIGNAL
#   instance      <instance name>
#   net           <net name>
#   order         <numeric order inside domain>
# Optional for auto-create of missing IO_POWER/RTE pads:
#   base_cell     <base cell>
#   pin           <pin to connect to net>
#
# A FILL_IN_CELL_IO_RAIL_CUT_052 is automatically inserted after every domain, including last->first.
# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set IOPAD_RING_NAME {FILL_IN_IOPAD_RING_NAME}

set IOPAD_RING_COMMON_GROUND $GROUND_NET

# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set IOPAD_RING_DIRECTION {FILL_IN_IOPAD_RING_DIRECTION}

# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set IOPAD_RING_DOMAIN_CONFIG {FILL_IN_IOPAD_RING_DOMAIN_CONFIG}

set ENABLE_IOPAD_RING_MODEL [expr {[llength $IOPAD_RING_DOMAIN_CONFIG] > 0}]
# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set IOPAD_RING_CREATE_MISSING_PADS {FILL_IN_IOPAD_RING_CREATE_MISSING_PADS}

# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set IOPAD_RING_CREATE_CUTS {FILL_IN_IOPAD_RING_CREATE_CUTS}

# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set IOPAD_RING_CUT_PREFIX {FILL_IN_IOPAD_RING_CUT_PREFIX}

# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set IOPAD_RING_CUT_BASE_VERTICAL {FILL_IN_IOPAD_RING_CUT_BASE_VERTICAL}

# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set IOPAD_RING_CUT_BASE_HORIZONTAL {FILL_IN_IOPAD_RING_CUT_BASE_HORIZONTAL}

# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set IOPAD_RING_STRICT {FILL_IN_IOPAD_RING_STRICT}


# Stage00 end-of-import IO/model validation.
# When the ring model is active, the checker validates the complete domain/RTE/
# IO-power/PR_CUT topology against the generated IO file.  When the model is
# inactive, it still validates the legacy IO file and configured supply RTE
# pads, and verifies that RTE pads cannot receive FILL_IN_CELL_BOND_PAD_041 bond pads.
set ENABLE_IMPORT_IOPAD_VALIDATION true
set IMPORT_IOPAD_VALIDATION_STRICT true
set IMPORT_IOPAD_REQUIRE_MODEL false
set IMPORT_IOPAD_VALIDATION_REPORT 00_90_iopad_iofile_check.rpt

# Boundary cells / EndCaps / WellTaps.
# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set INSERT_BOUNDARY_CELLS_AFTER_FLOORPLAN {FILL_IN_INSERT_BOUNDARY_CELLS_AFTER_FLOORPLAN}

set REQUIRE_FIXED_HARD_MACROS_BEFORE_BOUNDARY_CELLS true
set REQUIRE_POWER_DOMAIN_GEOMETRY_BEFORE_BOUNDARY_CELLS true
set ENABLE_ENDCAP_INSERTION true
set ENDCAP_GLOBAL_PASS_ENABLE true
set ENDCAP_POWER_DOMAIN_PASS_ENABLE true
# 請填入endcap cell 或對應設定
set ENDCAP_POWER_DOMAIN_LIST {FILL_IN_ENDCAP_POWER_DOMAIN_LIST}

# 請填入endcap cell 或對應設定
set ENDCAP_DEFAULT_POWER_DOMAIN {FILL_IN_ENDCAP_DEFAULT_POWER_DOMAIN}

# 請填入endcap cell 或對應設定
set ENDCAP_EXCLUDE_POWER_DOMAIN_PATTERNS {FILL_IN_ENDCAP_EXCLUDE_POWER_DOMAIN_PATTERNS}

# 請填入endcap cell 或對應設定
set ENDCAP_GLOBAL_PREFIX {FILL_IN_ENDCAP_GLOBAL_PREFIX}

# 請填入endcap cell 或對應設定
set ENDCAP_POWER_DOMAIN_PREFIX {FILL_IN_ENDCAP_POWER_DOMAIN_PREFIX}

set ENABLE_WELL_TAP_INSERTION true
# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set DEFER_WELL_TAP_TO_POST_POWERPLAN {FILL_IN_DEFER_WELL_TAP_TO_POST_POWERPLAN}

# Technology-specific documentation is retained in the private setup backup.
# referenced by check_place SPOverlapViolation markers, then re-run check_place.
# This is a repair switch, not a generic check switch.
set ENABLE_REMOVE_OVERLAP_WELLTAP true
set REMOVE_UNUSED_GACORE_ROWS true
# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set GACORE_SITE_NAME {FILL_IN_GACORE_SITE_NAME}


# Library-specific EndCap/WellTap candidates.
# 請填入endcap cell 或對應設定
set ENDCAP_LEFT_EDGE_CELLS {FILL_IN_ENDCAP_LEFT_EDGE_CELLS}

# 請填入endcap cell 或對應設定
set ENDCAP_RIGHT_EDGE_CELLS {FILL_IN_ENDCAP_RIGHT_EDGE_CELLS}

# 請填入endcap cell 或對應設定
set ENDCAP_LEFT_TOP_CORNER_CELLS {FILL_IN_ENDCAP_LEFT_TOP_CORNER_CELLS}

# 請填入endcap cell 或對應設定
set ENDCAP_LEFT_BOTTOM_CORNER_CELLS {FILL_IN_ENDCAP_LEFT_BOTTOM_CORNER_CELLS}

# 請填入endcap cell 或對應設定
set ENDCAP_TOP_EDGE_CELLS {FILL_IN_ENDCAP_TOP_EDGE_CELLS}

# 請填入endcap cell 或對應設定
set ENDCAP_BOTTOM_EDGE_CELLS {FILL_IN_ENDCAP_BOTTOM_EDGE_CELLS}

# 請填入endcap cell 或對應設定
set ENDCAP_CORNER_FILL_CELLS {FILL_IN_ENDCAP_CORNER_FILL_CELLS}

# 請填入endcap cell 或對應設定
set ENDCAP_TOP_TAP_CELLS {FILL_IN_ENDCAP_TOP_TAP_CELLS}

# 請填入endcap cell 或對應設定
set ENDCAP_BOTTOM_TAP_CELLS {FILL_IN_ENDCAP_BOTTOM_TAP_CELLS}

# 請填入endcap cell 或對應設定
set ENDCAP_WELL_TAP_RULE {FILL_IN_ENDCAP_WELL_TAP_RULE}


# Power Switch insertion (Stage 01).
set ENABLE_POWER_SWITCH_INSERTION true
# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set POWER_SWITCH_INSERTION_MODE {FILL_IN_POWER_SWITCH_INSERTION_MODE}

# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set POWER_SWITCH_INSTANCE_PREFIXES {FILL_IN_POWER_SWITCH_INSTANCE_PREFIXES}

# 請填入已確認的幾何值或幾何 dict，單位依呼叫端
set POWER_SWITCH_LEFT_OFFSET {FILL_IN_POWER_SWITCH_LEFT_OFFSET}
# 請填入已確認的幾何值或幾何 dict，單位依呼叫端
set POWER_SWITCH_RIGHT_OFFSET {FILL_IN_POWER_SWITCH_RIGHT_OFFSET}
# 請填入已確認的幾何值或幾何 dict，單位依呼叫端
set POWER_SWITCH_TOP_OFFSET {FILL_IN_POWER_SWITCH_TOP_OFFSET}
# 請填入已確認的幾何值或幾何 dict，單位依呼叫端
set POWER_SWITCH_BOTTOM_OFFSET {FILL_IN_POWER_SWITCH_BOTTOM_OFFSET}
# 請填入已確認的幾何值或幾何 dict，單位依呼叫端
set POWER_SWITCH_EDGE_REINFORCE_GAP {FILL_IN_POWER_SWITCH_EDGE_REINFORCE_GAP}

set POWER_SWITCH_ENDCAP_OVERLAP_CHECK_ENABLE true
# 請填入endcap cell 或對應設定
set POWER_SWITCH_ENDCAP_OVERLAP_AUTO_DELETE {FILL_IN_POWER_SWITCH_ENDCAP_OVERLAP_AUTO_DELETE}

set POWER_SWITCH_ENDCAP_OVERLAP_BREAKPOINT_ENABLE true
# 請填入endcap cell 或對應設定
set POWER_SWITCH_ENDCAP_OVERLAP_SAVE_DB {FILL_IN_POWER_SWITCH_ENDCAP_OVERLAP_SAVE_DB}


# EndCap / Power-Switch inspection point.
set ENDCAP_POST_INSERT_BREAKPOINT_ENABLE true
# 請填入endcap cell 或對應設定
set ENDCAP_POST_INSERT_RUN_CHECKS {FILL_IN_ENDCAP_POST_INSERT_RUN_CHECKS}

# 請填入endcap cell 或對應設定
set ENDCAP_POST_INSERT_SAVE_DB {FILL_IN_ENDCAP_POST_INSERT_SAVE_DB}


