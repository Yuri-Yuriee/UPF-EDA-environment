# =============================================================================
# 05 - Secondary PG / Signal Route / Post-route repair
# =============================================================================

# SIGNAL | SROUTE
set ::SECONDARY_PG_ROUTE_MODE SIGNAL
set ::SECONDARY_PG_DISCOVERY_STRICT 0
# 請填入本地 PDK 的金屬層／via 層名或層清單
set ::SECONDARY_PG_RAIL_LAYER   {FILL_IN_SECONDARY_PG_RAIL_LAYER}

# 請填入本地 PDK 的金屬層／via 層名或層清單
set ::SECONDARY_PG_BOTTOM_LAYER {FILL_IN_SECONDARY_PG_BOTTOM_LAYER}

# 請填入本地 PDK 的金屬層／via 層名或層清單
set ::SECONDARY_PG_TOP_LAYER    {FILL_IN_SECONDARY_PG_TOP_LAYER}

set ::ENABLE_PRE_2NDPG_BREAKPOINT 1
set ::ENABLE_POST_2NDPG_INSPECTION_BREAKPOINT 1

set ENABLE_SKIP_IOFILLER_RTE_ROUTING true

# advanced | basic
set ROUTE_MODE advanced
set ROUTE_ANTENNA_DIODE_INSERTION true
set ROUTE_TIMING_DRIVEN true
set ROUTE_ECO_ENABLE true
set ROUTE_SI_DRIVEN true
# 請填入 PDK 層名或層範圍
set ROUTE_TOP_ROUTING_LAYER {FILL_IN_ROUTE_TOP_ROUTING_LAYER}

# 請填入 PDK 層名或層範圍
set ROUTE_BOTTOM_ROUTING_LAYER {FILL_IN_ROUTE_BOTTOM_ROUTING_LAYER}

# 請填入本地設計／製程的設定值，保持原資料型別
set ROUTE_DETAIL_END_ITERATION {FILL_IN_ROUTE_DETAIL_END_ITERATION}
set ROUTE_DELAYCAL_ENABLE_SI true

set ENABLE_POST_ROUTE_OPT   false
set ENABLE_SIGNOFF_OPT      false
set ENABLE_FINAL_DRC_REPAIR true
set FINAL_DRC_LIMIT 100000

# Post-route DRC-driven Standard-Cell padding repair.
set ENABLE_INST_PADDING_REPAIR true
# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set INST_PADDING_ERROR_TYPES {FILL_IN_INST_PADDING_ERROR_TYPES}

# 請填入對應 library／PDK 資源名稱、完整路徑或清單
set INST_PADDING_LEFT {FILL_IN_INST_PADDING_LEFT}

# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set INST_PADDING_RIGHT {FILL_IN_INST_PADDING_RIGHT}


# Cleanup after route.
set ROUTE_CLEANUP_ROUTE_BLOCKAGES {BondPadBlk RBKM234 RBKPADPIN}
set ROUTE_CLEANUP_DELETE_SOFT_BLOCKAGES true


# Local reviewed repair targets; do not publish geometry records.
set METAL_COLOR_REPAIR_TARGET_MODE markers
set METAL_COLOR_REPAIR_MARKER_SUBTYPES {Metal_SameMask_Spacing}
# Optional explicit reviewed records; marker discovery is the default.
set METAL_COLOR_REPAIR_TARGETS {}
# 請填入本地確認的容差或尺寸值（單位依欄位）
set METAL_COLOR_REPAIR_BBOX_TOLERANCE {FILL_IN_METAL_COLOR_REPAIR_BBOX_TOLERANCE}
# Signal antenna: one native layer-hopping pass; no diode insertion.
set ANTENNA_ROUTE_ENABLE true
set ANTENNA_ROUTE_AUTO_REPAIR true
set ANTENNA_ROUTE_FATAL false

# Reference-script safety cap; inspect a larger batch before raising it.
# 請填入本地設計／製程的設定值，保持原資料型別
set ANTENNA_ROUTE_MAX_CANDIDATE_NETS {FILL_IN_ANTENNA_ROUTE_MAX_CANDIDATE_NETS}

