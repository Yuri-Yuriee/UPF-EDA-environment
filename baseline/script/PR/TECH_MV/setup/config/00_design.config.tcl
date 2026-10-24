# =============================================================================
# 00 - Design / power-intent mapping / timing analysis
# =============================================================================

# Canonical power-net variable names.
# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set POWER_PORT_NETS {FILL_IN_POWER_PORT_NETS}

# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set POWER_NETS {FILL_IN_POWER_NETS}

# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set GROUND_NET {FILL_IN_GROUND_NET}


# Compatibility aliases used by legacy/PNS helpers. Do not edit these aliases;
# edit POWER_PORT_NETS / POWER_NETS / GROUND_NET above.
set power_port $POWER_PORT_NETS
set power      $POWER_NETS
set ground     $GROUND_NET

# Existing Power Domain names and supply/net names are intentionally preserved.
# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set PD_CFG {FILL_IN_PD_CFG}

dict set PD_CFG PD_core power_net   VDD_LEVEL_01
dict set PD_CFG PD_core power_rail  VDD_LEVEL_01
dict set PD_CFG PD_core ground_net  VSS
dict set PD_CFG PD_core rail_2nd    {}

dict set PD_CFG PD_TOP power_net    VDD_LEVEL_02
dict set PD_CFG PD_TOP power_rail   VDD_LEVEL_02
dict set PD_CFG PD_TOP ground_net   VSS
dict set PD_CFG PD_TOP rail_2nd     {}

dict set PD_CFG PD_CPU power_net    {CPU_prim_PG.power VDD_LEVEL_01}
dict set PD_CFG PD_CPU power_rail   CPU_prim_PG.power
dict set PD_CFG PD_CPU ground_net   VSS
dict set PD_CFG PD_CPU rail_2nd     VDD_LEVEL_01

dict set PD_CFG PD_WDT power_net    {WDT_prim_PG.power VDD_LEVEL_02}
dict set PD_CFG PD_WDT power_rail   WDT_prim_PG.power
dict set PD_CFG PD_WDT ground_net   VSS
dict set PD_CFG PD_WDT rail_2nd     VDD_LEVEL_02

dict set PD_CFG PD_CPU_ALWY_ON power_net   VDD_LEVEL_01
dict set PD_CFG PD_CPU_ALWY_ON power_rail  VDD_LEVEL_01
dict set PD_CFG PD_CPU_ALWY_ON ground_net  VSS
dict set PD_CFG PD_CPU_ALWY_ON rail_2nd    {}

set ENABLE_AUTO_GENERATE_IO true

# Timing analysis applied by script/apply_design_config.tcl.
set TIMING_ANALYSIS_TYPE ocv
set TIMING_CPPR_MODE     both
# 請填入對應 corner 的 derate／縮放係數
set MAX_DERATE_EARLY {FILL_IN_MAX_DERATE_EARLY}
# 請填入對應 corner 的 derate／縮放係數
set MAX_DERATE_LATE  {FILL_IN_MAX_DERATE_LATE}
# 請填入對應 corner 的 derate／縮放係數
set MIN_DERATE_EARLY {FILL_IN_MIN_DERATE_EARLY}
# 請填入對應 corner 的 derate／縮放係數
set MIN_DERATE_LATE  {FILL_IN_MIN_DERATE_LATE}

# Runtime analysis-view names used by SDF output after read_db.
set ::MMMC_SETUP_VIEW AV_func_max_rcw
set ::MMMC_HOLD_VIEW  AV_func_min_rcb

# =============================================================================
# Package interface
# =============================================================================
# TECH package interface: wire bond + bond pad.
set PACKAGE_INTERFACE_MODE bond_pad

# =============================================================================
# TECH bond-pad definition
# =============================================================================
# From the real TECH lab flow. FILL_IN_CELL_BOND_PAD_041 is the TECH bond-pad cell.
# 請填入bond pad cell 或對應設定
set BOND_PAD_CELL {FILL_IN_BOND_PAD_CELL}

# 請填入 PDK 層名或層範圍
set BOND_PAD_TOP_LAYER {FILL_IN_BOND_PAD_TOP_LAYER}

# 請填入 library pin 名稱或接腳對應 dict
set BOND_PAD_DEFAULT_PIN {FILL_IN_BOND_PAD_DEFAULT_PIN}


# 請填入 library pin 名稱或接腳對應 dict
set BOND_PAD_PIN_MAP {FILL_IN_BOND_PAD_PIN_MAP}


# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set BOND_PAD_RIGHT_DOWN {FILL_IN_BOND_PAD_RIGHT_DOWN}

# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set BOND_PAD_TOP_RIGHT {FILL_IN_BOND_PAD_TOP_RIGHT}

# 請填入對應 library／PDK 資源名稱、完整路徑或清單
set BOND_PAD_LEFT_UP {FILL_IN_BOND_PAD_LEFT_UP}

# 請填入對應 library／PDK 資源名稱、完整路徑或清單
set BOND_PAD_BOTTOM_LEFT {FILL_IN_BOND_PAD_BOTTOM_LEFT}


# Preserve the existing reviewed-geometry provenance warning.

# SENSITIVE: wire width. Review or replace before public export.
# 請填入已確認的幾何值或幾何 dict，單位依呼叫端
set BOND_PAD_RDL_WIDTH {FILL_IN_BOND_PAD_RDL_WIDTH}
# SENSITIVE: wire spacing. Review or replace before public export.
# 請填入已確認的幾何值或幾何 dict，單位依呼叫端
set BOND_PAD_RDL_SPACING {FILL_IN_BOND_PAD_RDL_SPACING}
# 請填入已確認的幾何值或幾何 dict，單位依呼叫端
set BOND_PAD_GAP {FILL_IN_BOND_PAD_GAP}


# 請填入 PDK 層名或層範圍
set BOND_PAD_CHIP_BOUNDARY_LAYER {FILL_IN_BOND_PAD_CHIP_BOUNDARY_LAYER}

# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set BOND_PAD_CHIP_BOUNDARY_VERTICAL_EXTEND {FILL_IN_BOND_PAD_CHIP_BOUNDARY_VERTICAL_EXTEND}

# 請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別
set BOND_PAD_CHIP_BOUNDARY_HORIZONTAL_EXTEND {FILL_IN_BOND_PAD_CHIP_BOUNDARY_HORIZONTAL_EXTEND}



