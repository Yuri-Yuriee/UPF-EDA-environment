# =============================================================================
# 06_finish.config.tcl
# TECH_MV - Finish / Filler / Final Output Configuration
# =============================================================================

#------------------------------------------------------------------------------
# Final DRC / connectivity
# -----------------------------------------------------------------------------
set ENABLE_FINAL_DRC_REPAIR true
set FINAL_DRC_LIMIT 100000
set ENABLE_DELETE_UNPLACED    true
set ENABLE_FINAL_OUTPUTS      true
set ENABLE_CONNECTIVITY_CHECK true
set FINISH_CONNECTIVITY_ERROR_LIMIT   1000
set FINISH_CONNECTIVITY_WARNING_LIMIT 50

# -----------------------------------------------------------------------------
# Final Bond-Pad stage
# -----------------------------------------------------------------------------
set ENABLE_BOND_PAD_FLOW true
set BOND_PAD_FINAL_DRC_ENABLE true


# BEGIN TECH_MV FILLER PARAMETERS
# =============================================================================
# 06_finish.config.tcl - Filler parameters
# =============================================================================

set FILLER_PRESERVE_USER_ORDER true
# 請填入filler cell 或對應設定
set FILLER_NO_SINGLE_SITE_GAP {FILL_IN_FILLER_NO_SINGLE_SITE_GAP}

set FILLER_WITH_DRC            true
set FILLER_RUN_CHECK       true
set FILLER_RUN_SECOND_PASS false
set FILLER_RUN_FIX_DRC     false

# 請填入filler cell 或對應設定
set FILLER_CELLS {FILL_IN_FILLER_CELLS}

# END TECH_MV FILLER PARAMETERS
# Stream-out behavior. Source/merge paths are in 00_input.config.tcl.
# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set STREAM_OUT_TEXT_SIZE {FILL_IN_STREAM_OUT_TEXT_SIZE}

# 請填入對應 library／PDK 資源名稱、完整路徑或清單
set STREAM_OUT_LIB_NAME {FILL_IN_STREAM_OUT_LIB_NAME}

# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set STREAM_OUT_UNIT {FILL_IN_STREAM_OUT_UNIT}

# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set STREAM_OUT_MODE {FILL_IN_STREAM_OUT_MODE}

# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set STREAM_OUT_CUSTOM_MAP_LINES {FILL_IN_STREAM_OUT_CUSTOM_MAP_LINES}

# Fresh antenna verification; full power check is explicitly opt-in.
set ANTENNA_FINISH_ENABLE true
set ANTENNA_FINISH_POWER_ENABLE false
set ANTENNA_FINISH_FATAL false

# Ordered filler masters used by the native filler pass.
# 請填入filler cell 或對應設定
set FILLER_FLOW_CELLS {FILL_IN_FILLER_FLOW_CELLS}

