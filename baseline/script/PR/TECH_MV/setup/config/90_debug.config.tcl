# =============================================================================
# 90 - Manual / debug tool behavior
# =============================================================================

# Generic stage/checkpoint behavior.
set ::DEBUG_PLACE_CHECKPOINT_ENABLE true
set ::DEBUG_PLACE_CHECKPOINT_SAVE_DB true
set ::TT_CHECKPOINT_SUSPEND_ENABLE true

# Post-2ndPG marker-driven repair.
set ::TT_CP2_REPAIR_SCOPE LP_ONLY
set ::TT_CP2_REPAIR_INCLUDE_ENDCAP 0

# 請填入本地設計／製程的設定值，保持原資料型別
set ::TT_CP2_REPAIR_REROUTE_2NDPG {FILL_IN_TT_CP2_REPAIR_REROUTE_2NDPG}
set ::TT_CP2_REPAIR_MAX_CELLS 2000


# PD EndCap manual legalization.
set ::PD_ENDCAP_LEGALIZE_ENABLE true
set ::PD_ENDCAP_LEGALIZE_SITE core

set ::PD_ENDCAP_LEGALIZE_TOL 0.000001

set ::PD_ENDCAP_LEGALIZE_MAX_SHIFT 0.18


# Special-via DRC cleanup.
set ::TT_VIA_DRC_SUBTYPES {
    Adjacent_Cut_Spacing
    Cut_Short
    Cut_Spacing
}

set ::TT_VIA_DRC_EQUAL_OVERLAP_RATIO 0.50


# =============================================================================
# Optional design-check control
# =============================================================================
# Default policy: every check remains enabled.  Set only the checks you do not
# want to false.  Dependency/initialization guards are intentionally NOT
# controlled by these switches.
set ::CHECK_ALL_ENABLE true

# Stage 01 Floorplan checks.
set ::CHECK_STAGE01_IO_FLOORPLAN_ENABLE      true
set ::CHECK_STAGE01_FILE_FLOORPLAN_ENABLE    true
set ::CHECK_STAGE01_HARDMACRO_PD_ENABLE      true
set ::CHECK_STAGE01_FINAL_FLOORPLAN_ENABLE   true

# Stage 02 PowerPlan checks before/following the base PG operations.
set ::CHECK_STAGE02_HARDMACRO_PD_ENABLE      true
set ::CHECK_STAGE02_DRC_AFTER_POWER_STRIPE_ENABLE       true
set ::CHECK_STAGE02_DRC_AFTER_FOLLOW_PIN_ENABLE         true
set ::CHECK_STAGE02_DRC_BEFORE_FINAL_VIA_REPAIR_ENABLE  true
set ::CHECK_STAGE02_DRC_AFTER_FINAL_VIA_REPAIR_ENABLE   true

# The Stage-02 formal end checkpoint owns check_place + check_floorplan.
set ::CHECK_STAGE02_FORMAL_CHECKPOINT_ENABLE true

# Final PowerPlan sub-checks remain individually controlled by the existing
# POWERPLAN_FINAL_CHECK_* variables in 02_powerplan.config.tcl.
# CHECK_ALL_ENABLE is a master switch over those checks as well.
# =============================================================================
# Metal-density check control
# =============================================================================
# Innovus in-design density checks are used here primarily as an EARLY max-
# density guard.  Calibre remains the signoff authority, especially for final
# minimum-density/dummy-fill rules.
#
# Stage02/Stage05 are diagnostic and non-fatal by default so the reports show
# Technology-specific selector documentation is retained in the private setup backup.
set ::CHECK_STAGE02_METAL_DENSITY_ENABLE true
# 請填入本地 floorplan／placement 的利用率或密度比例
set ::CHECK_STAGE02_METAL_DENSITY_LAYERS {FILL_IN_CHECK_STAGE02_METAL_DENSITY_LAYERS}

set ::CHECK_STAGE02_METAL_DENSITY_MIN_ENABLE false
set ::CHECK_STAGE02_METAL_DENSITY_MAX_ENABLE true
set ::CHECK_STAGE02_METAL_DENSITY_FATAL false

set ::CHECK_STAGE05_METAL_DENSITY_ENABLE true
# 請填入本地 floorplan／placement 的利用率或密度比例
set ::CHECK_STAGE05_METAL_DENSITY_LAYERS {FILL_IN_CHECK_STAGE05_METAL_DENSITY_LAYERS}

set ::CHECK_STAGE05_METAL_DENSITY_MIN_ENABLE false
set ::CHECK_STAGE05_METAL_DENSITY_MAX_ENABLE true
set ::CHECK_STAGE05_METAL_DENSITY_FATAL false

set ::CHECK_STAGE06_METAL_DENSITY_ENABLE true
# 請填入本地 floorplan／placement 的利用率或密度比例
set ::CHECK_STAGE06_METAL_DENSITY_LAYERS {FILL_IN_CHECK_STAGE06_METAL_DENSITY_LAYERS}

set ::CHECK_STAGE06_METAL_DENSITY_MIN_ENABLE false
set ::CHECK_STAGE06_METAL_DENSITY_MAX_ENABLE true
set ::CHECK_STAGE06_METAL_DENSITY_FATAL false

# Foundry/reference density table used by TT_tool_report_metal_density.tcl.
# Format: LAYER MIN_PERCENT MAX_PERCENT
# Technology-specific documentation is retained in the private setup backup.
set ::METAL_DENSITY_LIMIT_TABLE {
    M1   25.0000   37.7200
    M2   25.0100   35.1900
    M3   25.1500   35.1900
    M4   25.0200   35.1900
    M5   26.2300   64.7200
    M6   25.2400   64.8800
    M7   25.1800   64.6400
    M8   22.0900   60.6800
    M9   22.0500   50.7900
    M10  10.0200   60.5300
}



# Early rail analysis: original native argument lists, preserved in private setup.
# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set ERA_ARGS_01 {FILL_IN_ERA_ARGS_01}
# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set ERA_ARGS_02 {FILL_IN_ERA_ARGS_02}
# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set ERA_ARGS_03 {FILL_IN_ERA_ARGS_03}
# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set ERA_ARGS_04 {FILL_IN_ERA_ARGS_04}
# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set ERA_ARGS_05 {FILL_IN_ERA_ARGS_05}
# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set ERA_ARGS_06 {FILL_IN_ERA_ARGS_06}
# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set ERA_ARGS_07 {FILL_IN_ERA_ARGS_07}
# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set ERA_ARGS_08 {FILL_IN_ERA_ARGS_08}
# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set ERA_ARGS_09 {FILL_IN_ERA_ARGS_09}
# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set ERA_ARGS_10 {FILL_IN_ERA_ARGS_10}
# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set ERA_ARGS_11 {FILL_IN_ERA_ARGS_11}
# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set ERA_ARGS_12 {FILL_IN_ERA_ARGS_12}
# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set ERA_ARGS_13 {FILL_IN_ERA_ARGS_13}
set ERA_REPORT_DOMAIN PD

