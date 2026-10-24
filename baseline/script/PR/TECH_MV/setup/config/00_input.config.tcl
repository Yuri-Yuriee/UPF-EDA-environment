# =============================================================================
# 00 - Input / collateral paths
# =============================================================================

set TOP_MODULE CHIP

# Runtime setup files.
set GLOBAL_NET_FILE [file join $SETUP_DIR global_net.tcl]
set MMMC_FILE       [file join $SETUP_DIR mmmc.view.stylus]

# Netlist / constraints / IO.
set NETLIST_FILE [file join .. syn ${TOP_MODULE}_syn.v]

set SDC_FILE     [file join .. syn DC_out.sdc]

set IO_FILE      [file join $SETUP_DIR ${TOP_MODULE}.io]


# UPF source shared by VCS / Innovus.
set UPF_SOURCE_DIR [file join .. script MV UPF]

set UPF_FILE       [file join $UPF_SOURCE_DIR MSV.upf]

# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set UPF_SOURCE_FILES {FILL_IN_UPF_SOURCE_FILES}


# Physical LEF.
# 請填入對應 library／PDK 資源名稱、完整路徑或清單
set LEF_FILES {FILL_IN_LEF_FILES}


# MMMC / QRC.
# 請填入對應 library／PDK 資源名稱、完整路徑或清單
set MMMC_QRC_BEST_FILE {FILL_IN_MMMC_QRC_BEST_FILE}

# 請填入對應 library／PDK 資源名稱、完整路徑或清單
set MMMC_QRC_WORST_FILE {FILL_IN_MMMC_QRC_WORST_FILE}


# 請填入對應 library／PDK 資源名稱、完整路徑或清單
set MMMC_CORE_LEVEL_01_LIB_WC_FILES {FILL_IN_MMMC_CORE_LEVEL_01_LIB_WC_FILES}

# 請填入對應 library／PDK 資源名稱、完整路徑或清單
set MMMC_CORE_LEVEL_02_LIB_WC_FILES {FILL_IN_MMMC_CORE_LEVEL_02_LIB_WC_FILES}

# 請填入對應 library／PDK 資源名稱、完整路徑或清單
set MMMC_IO_LIB_WC_FILES {FILL_IN_MMMC_IO_LIB_WC_FILES}

# 請填入對應 library／PDK 資源名稱、完整路徑或清單
set MMMC_LVL_LEVEL_01_H2L_LEVEL_02_LIB_WC_FILES {FILL_IN_MMMC_LVL_LEVEL_01_H2L_LEVEL_02_LIB_WC_FILES}

# 請填入對應 library／PDK 資源名稱、完整路徑或清單
set MMMC_LVL_LEVEL_02_L2H_LEVEL_01_LIB_WC_FILES {FILL_IN_MMMC_LVL_LEVEL_02_L2H_LEVEL_01_LIB_WC_FILES}

# 請填入對應 library／PDK 資源名稱、完整路徑或清單
set MMMC_PM_LEVEL_01_LIB_WC_FILES {FILL_IN_MMMC_PM_LEVEL_01_LIB_WC_FILES}

# 請填入對應 library／PDK 資源名稱、完整路徑或清單
set MMMC_PM_LEVEL_02_LIB_WC_FILES {FILL_IN_MMMC_PM_LEVEL_02_LIB_WC_FILES}

# 請填入對應 library／PDK 資源名稱、完整路徑或清單
set MMMC_MEM_LIB_WC_FILES {FILL_IN_MMMC_MEM_LIB_WC_FILES}


# 請填入對應 library／PDK 資源名稱、完整路徑或清單
set MMMC_CORE_LEVEL_01_LIB_BC_FILES {FILL_IN_MMMC_CORE_LEVEL_01_LIB_BC_FILES}

# 請填入對應 library／PDK 資源名稱、完整路徑或清單
set MMMC_CORE_LEVEL_02_LIB_BC_FILES {FILL_IN_MMMC_CORE_LEVEL_02_LIB_BC_FILES}

# 請填入對應 library／PDK 資源名稱、完整路徑或清單
set MMMC_IO_LIB_BC_FILES {FILL_IN_MMMC_IO_LIB_BC_FILES}

# 請填入對應 library／PDK 資源名稱、完整路徑或清單
set MMMC_LVL_LEVEL_01_H2L_LEVEL_02_LIB_BC_FILES {FILL_IN_MMMC_LVL_LEVEL_01_H2L_LEVEL_02_LIB_BC_FILES}

# 請填入對應 library／PDK 資源名稱、完整路徑或清單
set MMMC_LVL_LEVEL_02_L2H_LEVEL_01_LIB_BC_FILES {FILL_IN_MMMC_LVL_LEVEL_02_L2H_LEVEL_01_LIB_BC_FILES}

# 請填入對應 library／PDK 資源名稱、完整路徑或清單
set MMMC_PM_LEVEL_01_LIB_BC_FILES {FILL_IN_MMMC_PM_LEVEL_01_LIB_BC_FILES}

# 請填入對應 library／PDK 資源名稱、完整路徑或清單
set MMMC_PM_LEVEL_02_LIB_BC_FILES {FILL_IN_MMMC_PM_LEVEL_02_LIB_BC_FILES}

# 請填入對應 library／PDK 資源名稱、完整路徑或清單
set MMMC_MEM_LIB_BC_FILES {FILL_IN_MMMC_MEM_LIB_BC_FILES}


# 請填入對應 library／PDK 資源名稱、完整路徑或清單
set PG_LIBRARY_QRC_FILE {FILL_IN_PG_LIBRARY_QRC_FILE}


# Confirmed FILL_IN_PROCESS_VARIANT stream-out collateral.
# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set STREAM_OUT_MAP_SOURCE {FILL_IN_STREAM_OUT_MAP_SOURCE}

set STREAM_OUT_MAP_FILE [file join $TEMP_DIR stream_out_map]


# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set TECH_CORE_GDS_DIR {FILL_IN_TECH_CORE_GDS_DIR}

# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set TECH_IO_GDS_DIR {FILL_IN_TECH_IO_GDS_DIR}

# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set STREAM_MERGE_GDS_FILES {FILL_IN_STREAM_MERGE_GDS_FILES}


