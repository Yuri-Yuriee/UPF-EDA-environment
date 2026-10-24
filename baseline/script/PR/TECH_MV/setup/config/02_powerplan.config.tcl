# =============================================================================
# 02 - PowerPlan
# =============================================================================

# legacy | pns | none
set POWERPLAN_MODE legacy
# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set PNS_AUTO_RUN_ON_SOURCE {FILL_IN_PNS_AUTO_RUN_ON_SOURCE}


# Real TECH: derive BondPadBlk from temporary FILL_IN_CELL_BOND_PAD_041 bond-pad placement.
set ENABLE_BOND_PAD_ROUTE_BLOCKAGE true

# Stage-02 legacy secondary-PG helper enable.  Kept separate from the newer
# post-CTS SIGNAL/SROUTE routing mode in 05_route.config.tcl.
set ENABLE_SECONDARY_PG_ROUTE true

# Core ring geometry.
# SENSITIVE: wire width, wire spacing. Review or replace before public export.
# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set POWERPLAN_CORE_RING_LOWER {FILL_IN_POWERPLAN_CORE_RING_LOWER}

# SENSITIVE: wire width, wire spacing. Review or replace before public export.
# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set POWERPLAN_CORE_RING_UPPER {FILL_IN_POWERPLAN_CORE_RING_UPPER}


# Pad-pin SRoute.
# 請填入 library pin 名稱或接腳對應 dict
set POWERPLAN_PAD_PIN_LAYER_CHANGE_RANGE {FILL_IN_POWERPLAN_PAD_PIN_LAYER_CHANGE_RANGE}

# 請填入 library pin 名稱或接腳對應 dict
set POWERPLAN_PAD_PIN_LAYER_RANGE {FILL_IN_POWERPLAN_PAD_PIN_LAYER_RANGE}

# 請填入 library pin 名稱或接腳對應 dict
set POWERPLAN_PAD_PIN_PORT_CONNECT {FILL_IN_POWERPLAN_PAD_PIN_PORT_CONNECT}

# 請填入 library pin 名稱或接腳對應 dict
set POWERPLAN_PAD_PIN_BLOCKAGE_NAME {FILL_IN_POWERPLAN_PAD_PIN_BLOCKAGE_NAME}

# 請填入 library pin 名稱或接腳對應 dict
set POWERPLAN_PAD_PIN_BLOCKAGE_LAYERS {FILL_IN_POWERPLAN_PAD_PIN_BLOCKAGE_LAYERS}

# 請填入 library pin 名稱或接腳對應 dict
set POWERPLAN_PAD_PIN_BLOCKAGE_INNER_OFFSET {FILL_IN_POWERPLAN_PAD_PIN_BLOCKAGE_INNER_OFFSET}
# 請填入 library pin 名稱或接腳對應 dict
set POWERPLAN_PAD_PIN_BLOCKAGE_OUTER_OFFSET {FILL_IN_POWERPLAN_PAD_PIN_BLOCKAGE_OUTER_OFFSET}
# 請填入 library pin 名稱或接腳對應 dict
set POWERPLAN_PAD_PIN_BLOCKAGE_CORE_GAP {FILL_IN_POWERPLAN_PAD_PIN_BLOCKAGE_CORE_GAP}

# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set POWERPLAN_PAD_CELL_PATTERN {FILL_IN_POWERPLAN_PAD_CELL_PATTERN}


# Power-Domain block rings.
set POWERPLAN_PD_TOP_FILL_INTERNAL_HOLES_ENABLE true
# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set POWERPLAN_PD_TOP_RING_DOMAIN {FILL_IN_POWERPLAN_PD_TOP_RING_DOMAIN}

# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set POWERPLAN_PD_BLOCK_RING_DOMAINS {FILL_IN_POWERPLAN_PD_BLOCK_RING_DOMAINS}

# SENSITIVE: wire width, wire spacing. Review or replace before public export.
# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set POWERPLAN_PD_RING_UPPER {FILL_IN_POWERPLAN_PD_RING_UPPER}

# SENSITIVE: wire width, wire spacing. Review or replace before public export.
# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set POWERPLAN_PD_RING_LOWER {FILL_IN_POWERPLAN_PD_RING_LOWER}


# Hard-macro temporary PG route blockage around the left/right edges.
set POWERPLAN_MACRO_PG_BLOCKAGE_NAME RBKM234
# 請填入 PDK 層名或層範圍
set POWERPLAN_MACRO_PG_BLOCKAGE_LAYERS {FILL_IN_POWERPLAN_MACRO_PG_BLOCKAGE_LAYERS}

# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set POWERPLAN_MACRO_PG_BLOCKAGE_CLEARANCE {FILL_IN_POWERPLAN_MACRO_PG_BLOCKAGE_CLEARANCE}


# Global stripe geometry.
# Technology-specific documentation is retained in the private setup backup.
# SENSITIVE: wire width, wire spacing, center-to-center wire spacing (pitch). Review or replace before public export.
# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set POWERPLAN_M9_ALL_STRIPE {FILL_IN_POWERPLAN_M9_ALL_STRIPE}

# SENSITIVE: wire width, wire spacing, center-to-center wire spacing (pitch). Review or replace before public export.
# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set POWERPLAN_M8_GROUND_STRIPE {FILL_IN_POWERPLAN_M8_GROUND_STRIPE}

# SENSITIVE: wire width, wire spacing, center-to-center wire spacing (pitch). Review or replace before public export.
# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set POWERPLAN_M8_POWER_STRIPE {FILL_IN_POWERPLAN_M8_POWER_STRIPE}

# SENSITIVE: wire width, wire spacing, center-to-center wire spacing (pitch). Review or replace before public export.
# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set POWERPLAN_M7_GROUND_STRIPE {FILL_IN_POWERPLAN_M7_GROUND_STRIPE}

# SENSITIVE: wire width, wire spacing, center-to-center wire spacing (pitch). Review or replace before public export.
# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set POWERPLAN_M7_POWER_STRIPE {FILL_IN_POWERPLAN_M7_POWER_STRIPE}


# Per-Power-Domain stripes.
# SENSITIVE: wire width, wire spacing, center-to-center wire spacing (pitch). Review or replace before public export.
# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set POWERPLAN_M6_GROUND_STRIPE {FILL_IN_POWERPLAN_M6_GROUND_STRIPE}

# SENSITIVE: wire width, wire spacing, center-to-center wire spacing (pitch). Review or replace before public export.
# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set POWERPLAN_M6_POWER_STRIPE {FILL_IN_POWERPLAN_M6_POWER_STRIPE}


# SENSITIVE: Wire-width and wire-spacing values in the following notes.
# Technology-specific selector documentation is retained in the private setup backup.
# Technology-specific documentation is retained in the private setup backup.
# Technology-specific documentation is retained in the private setup backup.
# Technology-specific documentation is retained in the private setup backup.
# Technology-specific documentation is retained in the private setup backup.
# Technology-specific documentation is retained in the private setup backup.
#
# Interleave:
# Technology-specific documentation is retained in the private setup backup.
# SENSITIVE: wire width, wire spacing, center-to-center wire spacing (pitch). Review or replace before public export.
# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set POWERPLAN_M5_GROUND_STRIPE {FILL_IN_POWERPLAN_M5_GROUND_STRIPE}

# SENSITIVE: wire width, wire spacing, center-to-center wire spacing (pitch). Review or replace before public export.
# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set POWERPLAN_M5_POWER_STRIPE {FILL_IN_POWERPLAN_M5_POWER_STRIPE}


# Floating-stripe SRoute.
# 請填入 PDK 層名或層範圍
set POWERPLAN_FLOATING_STRIPE_LAYER_CHANGE_RANGE {FILL_IN_POWERPLAN_FLOATING_STRIPE_LAYER_CHANGE_RANGE}

# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set POWERPLAN_FLOATING_STRIPE_TARGETS {FILL_IN_POWERPLAN_FLOATING_STRIPE_TARGETS}


# Follow-pin SRoute.
# 請填入 library pin 名稱或接腳對應 dict
set POWERPLAN_FOLLOW_PIN_LAYER_CHANGE_RANGE {FILL_IN_POWERPLAN_FOLLOW_PIN_LAYER_CHANGE_RANGE}

# 請填入 library pin 名稱或接腳對應 dict
set POWERPLAN_FOLLOW_PIN_CORE_PIN_LAYER {FILL_IN_POWERPLAN_FOLLOW_PIN_CORE_PIN_LAYER}

# 請填入 library pin 名稱或接腳對應 dict
set POWERPLAN_FOLLOW_PIN_TARGET {FILL_IN_POWERPLAN_FOLLOW_PIN_TARGET}

set ENABLE_POST_POWERPLAN_2ROW_SDP true
set ENABLE_POST_POWERPLAN_FOLLOWPIN_CLEANUP true

# Interactive step checkpoints.
set POWERPLAN_STEP_PAUSE_ENABLE false
set POWERPLAN_STEP_SAVE_DB_ENABLE false
set POWERPLAN_STEP_DB_PREFIX 02_50_step

# DRC checkpoints.
set POWERPLAN_DRC_PAUSE_ON_VIOLATION true
set POWERPLAN_DRC_REQUIRE_CLEAN_BEFORE_CONTINUE false
set POWERPLAN_DRC_SAVE_DB_ON_VIOLATION true
set POWERPLAN_DRC_LIMIT 100000
set POWERPLAN_FINAL_DRC_CHECK_ENABLE true

# Final comprehensive checks.
set POWERPLAN_FINAL_CHECK_ENABLE                 true
set POWERPLAN_FINAL_CHECK_GLOBAL_NET_ENABLE      true
set POWERPLAN_FINAL_CHECK_FLOORPLAN_ENABLE       true
set POWERPLAN_FINAL_CHECK_PLACE_ENABLE           true
set POWERPLAN_FINAL_CHECK_PG_CONNECTIVITY_ENABLE true
set POWERPLAN_FINAL_CHECK_POWER_VIA_ENABLE       true
set POWERPLAN_FINAL_CHECK_POWER_DOMAIN_ENABLE    true
set POWERPLAN_FINAL_CHECK_CONNECTIVITY_ERROR_LIMIT   10000
set POWERPLAN_FINAL_CHECK_CONNECTIVITY_WARNING_LIMIT 1000

# PNS legacy-alternate geometry. These are only used when POWERPLAN_MODE=pns.
# SENSITIVE: wire width, wire spacing. Review or replace before public export.
# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set PNS_CORE_RING_1 {FILL_IN_PNS_CORE_RING_1}

# SENSITIVE: wire width, wire spacing. Review or replace before public export.
# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set PNS_CORE_RING_2 {FILL_IN_PNS_CORE_RING_2}

# SENSITIVE: wire width, wire spacing. Review or replace before public export.
# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set PNS_CORE_RING_3 {FILL_IN_PNS_CORE_RING_3}

# 請填入 library pin 名稱或接腳對應 dict
set PNS_PAD_PIN_LAYER_CHANGE_RANGE {FILL_IN_PNS_PAD_PIN_LAYER_CHANGE_RANGE}

# 請填入 library pin 名稱或接腳對應 dict
set PNS_PAD_PIN_LAYER_RANGE {FILL_IN_PNS_PAD_PIN_LAYER_RANGE}

# 請填入 PDK 層名或層範圍
set PNS_MACRO_BLOCKAGE_LAYERS {FILL_IN_PNS_MACRO_BLOCKAGE_LAYERS}

# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set PNS_MACRO_BLOCKAGE_CLEARANCE {FILL_IN_PNS_MACRO_BLOCKAGE_CLEARANCE}

# SENSITIVE: wire width, wire spacing, center-to-center wire spacing (pitch). Review or replace before public export.
# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set PNS_M9_ALL_STRIPE {FILL_IN_PNS_M9_ALL_STRIPE}

# SENSITIVE: wire width, wire spacing, center-to-center wire spacing (pitch). Review or replace before public export.
# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set PNS_M8_GROUND_STRIPE {FILL_IN_PNS_M8_GROUND_STRIPE}

# SENSITIVE: wire width, wire spacing, center-to-center wire spacing (pitch). Review or replace before public export.
# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set PNS_M8_POWER_STRIPE {FILL_IN_PNS_M8_POWER_STRIPE}

# SENSITIVE: wire width, wire spacing, center-to-center wire spacing (pitch). Review or replace before public export.
# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set PNS_M7_GROUND_STRIPE {FILL_IN_PNS_M7_GROUND_STRIPE}

# SENSITIVE: wire width, wire spacing, center-to-center wire spacing (pitch). Review or replace before public export.
# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set PNS_M7_POWER_STRIPE {FILL_IN_PNS_M7_POWER_STRIPE}

# SENSITIVE: wire width, wire spacing, center-to-center wire spacing (pitch). Review or replace before public export.
# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set PNS_M6_GROUND_STRIPE {FILL_IN_PNS_M6_GROUND_STRIPE}

# SENSITIVE: wire width, wire spacing, center-to-center wire spacing (pitch). Review or replace before public export.
# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set PNS_M6_POWER_STRIPE {FILL_IN_PNS_M6_POWER_STRIPE}

# SENSITIVE: wire width, wire spacing, center-to-center wire spacing (pitch). Review or replace before public export.
# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set PNS_M5_GROUND_STRIPE {FILL_IN_PNS_M5_GROUND_STRIPE}

# SENSITIVE: wire width, wire spacing, center-to-center wire spacing (pitch). Review or replace before public export.
# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set PNS_M5_POWER_STRIPE {FILL_IN_PNS_M5_POWER_STRIPE}

# 請填入 library pin 名稱或接腳對應 dict
set PNS_FOLLOW_PIN_LAYER_CHANGE_RANGE {FILL_IN_PNS_FOLLOW_PIN_LAYER_CHANGE_RANGE}

# 請填入 library pin 名稱或接腳對應 dict
set PNS_FOLLOW_PIN_VIA_SCALE_HEIGHT {FILL_IN_PNS_FOLLOW_PIN_VIA_SCALE_HEIGHT}
# 請填入 library pin 名稱或接腳對應 dict
set PNS_FOLLOW_PIN_VIA_SCALE_WIDTH {FILL_IN_PNS_FOLLOW_PIN_VIA_SCALE_WIDTH}
# SENSITIVE: wire width, wire spacing, center-to-center wire spacing (pitch). Review or replace before public export.
# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set PNS_M2_POWER_RAIL {FILL_IN_PNS_M2_POWER_RAIL}

# SENSITIVE: wire width, wire spacing, center-to-center wire spacing (pitch). Review or replace before public export.
# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set PNS_M2_GROUND_RAIL {FILL_IN_PNS_M2_GROUND_RAIL}


# Per-design IEEE-1801 switch mapping; preserve the current insertion order.
# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set POWER_SWITCH_DESIGN_MAP {FILL_IN_POWER_SWITCH_DESIGN_MAP}

# 請填入已確認的幾何值或幾何 dict，單位依呼叫端
set POWER_SWITCH_HORIZONTAL_PITCH {FILL_IN_POWER_SWITCH_HORIZONTAL_PITCH}
# PNS helper geometry: user settings, preserved from the original command values.
# SENSITIVE: wire spacing / routing clearance. Review or replace before public export.
# 請填入已確認的幾何值或幾何 dict，單位依呼叫端
set PNS_STRIPE_SPACING_FROM_BLOCK {FILL_IN_PNS_STRIPE_SPACING_FROM_BLOCK}

# SENSITIVE: wire jog distance. Review or replace before public export.
# 請填入已確認的幾何值或幾何 dict，單位依呼叫端
set PNS_STRIPE_MAX_SAME_LAYER_JOG_LENGTH {FILL_IN_PNS_STRIPE_MAX_SAME_LAYER_JOG_LENGTH}

# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set PNS_STD_REGION_Y_EXPANSION {FILL_IN_PNS_STD_REGION_Y_EXPANSION}

# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set PNS_RING_THRESHOLD {FILL_IN_PNS_RING_THRESHOLD}

# SENSITIVE: wire jog distance. Review or replace before public export.
# 請填入已確認的幾何值或幾何 dict，單位依呼叫端
set PNS_RING_JOG_DISTANCE {FILL_IN_PNS_RING_JOG_DISTANCE}

# SENSITIVE: wire width. Review or replace before public export.
# 請填入已確認的幾何值或幾何 dict，單位依呼叫端
set PNS_MACRO_RING_WIDTH {FILL_IN_PNS_MACRO_RING_WIDTH}

# SENSITIVE: wire spacing / routing clearance. Review or replace before public export.
# 請填入已確認的幾何值或幾何 dict，單位依呼叫端
set PNS_MACRO_RING_SPACING {FILL_IN_PNS_MACRO_RING_SPACING}

# 請填入已確認的幾何值或幾何 dict，單位依呼叫端
set PNS_MACRO_RING_OFFSET {FILL_IN_PNS_MACRO_RING_OFFSET}


# Existing ring-overlap repair after follow-pin; restrict to this layer.
set ENABLE_FOLLOW_PIN_RING_OVERLAP_REPAIR true
# 請填入本地 PDK 的金屬層／via 層名或層清單
set FOLLOW_PIN_RING_OVERLAP_REPAIR_LAYERS {FILL_IN_FOLLOW_PIN_RING_OVERLAP_REPAIR_LAYERS}

# Manual SDP movement defaults: user choices, not inferred process rules.
# Actual values are non-public configuration. Tools retain their existing override guards.
array set ::TECH_MV_SDP_MOVE_DEFAULTS {
    TT_PR7_INTERNAL_REFINE_MOVE_DISTANCE 100.0
    TT_PR7_FORCE_REPACK_MOVE_DISTANCE 100.0
    TT_2ROW_SDP_REPAIR_MAX_MOVE_DISTANCE 100.0
}

# SW geometry-path check after final Stage-02 PG routing/checks.
# Query controls; optional repair policy follows below. No technology dimensions here.
set POWERPLAN_SW_PG_CHECK_ENABLE true
set POWERPLAN_SW_PG_CHECK_MAX_NODES 10000
set POWERPLAN_SW_PG_CHECK_PAUSE_ON_FINDINGS true

# One bounded repair pass; pre-repair DB and native checks are mandatory.
set POWERPLAN_SW_PG_REPAIR_ENABLE true
set POWERPLAN_SW_PG_REPAIR_MAX_SWITCHES 100

