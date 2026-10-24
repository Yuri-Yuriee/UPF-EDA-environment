# 設定填寫入口

日常設定直接修改 script/PR/TECH_MV/setup/config/ 各 stage 檔案；保留 set／array 原處填值。00_library.config.tcl 的 TECH_MV_LIBRARY_VALUES 是直接填入的 library 資料，不是指向其他 Tcl 的 key 對映。已移除 stage config 的 private_parameter_config／geometry_review source 與舊 library command 對映表。

以下為逐欄提示。private/setup_commands 等只保留為舊工具相容範本，不是使用者 stage 設定入口；不需將直接設定轉成命令引用。

# 填空欄位指南

欄位為本次新包直接分析而得，未匯入舊版欄位值。行號是替換當下位置，可能因模板註解而變動，請優先搜尋填空代號。

|檔案|欄位／位置|填空代號|應填內容|
|---|---|---|---|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::00_design.config.tcl::BOND_PAD_CELL|FILL_IN_setup_00_design_config_tcl_BOND_PAD_CELL|請填入bond pad cell 或對應設定|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::00_design.config.tcl::BOND_PAD_TOP_LAYER|FILL_IN_setup_00_design_config_tcl_BOND_PAD_TOP_LAYER|請填入 PDK 層名或層範圍|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::00_design.config.tcl::BOND_PAD_DEFAULT_PIN|FILL_IN_setup_00_design_config_tcl_BOND_PAD_DEFAULT_PIN|請填入 library pin 名稱或接腳對應 dict|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::00_design.config.tcl::BOND_PAD_PIN_MAP|FILL_IN_setup_00_design_config_tcl_BOND_PAD_PIN_MAP|請填入 library pin 名稱或接腳對應 dict|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::00_design.config.tcl::BOND_PAD_RIGHT_DOWN|FILL_IN_setup_00_design_config_tcl_BOND_PAD_RIGHT_DOWN|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::00_design.config.tcl::BOND_PAD_TOP_RIGHT|FILL_IN_setup_00_design_config_tcl_BOND_PAD_TOP_RIGHT|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::00_design.config.tcl::BOND_PAD_LEFT_UP|FILL_IN_setup_00_design_config_tcl_BOND_PAD_LEFT_UP|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::00_design.config.tcl::BOND_PAD_BOTTOM_LEFT|FILL_IN_setup_00_design_config_tcl_BOND_PAD_BOTTOM_LEFT|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::00_design.config.tcl::BOND_PAD_RDL_WIDTH|FILL_IN_setup_00_design_config_tcl_BOND_PAD_RDL_WIDTH|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::00_design.config.tcl::BOND_PAD_RDL_SPACING|FILL_IN_setup_00_design_config_tcl_BOND_PAD_RDL_SPACING|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::00_design.config.tcl::BOND_PAD_GAP|FILL_IN_setup_00_design_config_tcl_BOND_PAD_GAP|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::00_design.config.tcl::BOND_PAD_CHIP_BOUNDARY_LAYER|FILL_IN_setup_00_design_config_tcl_BOND_PAD_CHIP_BOUNDARY_LAYER|請填入 PDK 層名或層範圍|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::00_design.config.tcl::BOND_PAD_CHIP_BOUNDARY_VERTICAL_EXTEND|FILL_IN_setup_00_design_config_tcl_BOND_PAD_CHIP_BOUNDARY_VERTICAL_EXTEND|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::00_design.config.tcl::BOND_PAD_CHIP_BOUNDARY_HORIZONTAL_EXTEND|FILL_IN_setup_00_design_config_tcl_BOND_PAD_CHIP_BOUNDARY_HORIZONTAL_EXTEND|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::00_input.config.tcl::NETLIST_FILE|FILL_IN_setup_00_input_config_tcl_NETLIST_FILE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::00_input.config.tcl::SDC_FILE|FILL_IN_setup_00_input_config_tcl_SDC_FILE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::00_input.config.tcl::IO_FILE|FILL_IN_setup_00_input_config_tcl_IO_FILE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::00_input.config.tcl::UPF_SOURCE_DIR|FILL_IN_setup_00_input_config_tcl_UPF_SOURCE_DIR|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::00_input.config.tcl::UPF_FILE|FILL_IN_setup_00_input_config_tcl_UPF_FILE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::00_input.config.tcl::UPF_SOURCE_FILES|FILL_IN_setup_00_input_config_tcl_UPF_SOURCE_FILES|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::00_input.config.tcl::LEF_FILES|FILL_IN_setup_00_input_config_tcl_LEF_FILES|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::00_input.config.tcl::MMMC_QRC_BEST_FILE|FILL_IN_setup_00_input_config_tcl_MMMC_QRC_BEST_FILE|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::00_input.config.tcl::MMMC_QRC_WORST_FILE|FILL_IN_setup_00_input_config_tcl_MMMC_QRC_WORST_FILE|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::00_input.config.tcl::MMMC_CORE_LEVEL_01_LIB_WC_FILES|FILL_IN_setup_00_input_config_tcl_MMMC_CORE_LEVEL_01_LIB_WC_FILES|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::00_input.config.tcl::MMMC_CORE_LEVEL_02_LIB_WC_FILES|FILL_IN_setup_00_input_config_tcl_MMMC_CORE_LEVEL_02_LIB_WC_FILES|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::00_input.config.tcl::MMMC_IO_LIB_WC_FILES|FILL_IN_setup_00_input_config_tcl_MMMC_IO_LIB_WC_FILES|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::00_input.config.tcl::MMMC_LVL_LEVEL_01_H2L_LEVEL_02_LIB_WC_FILES|FILL_IN_setup_00_input_config_tcl_MMMC_LVL_LEVEL_01_H2L_LEVEL_02_LIB_WC_FILES|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::00_input.config.tcl::MMMC_LVL_LEVEL_02_L2H_LEVEL_01_LIB_WC_FILES|FILL_IN_setup_00_input_config_tcl_MMMC_LVL_LEVEL_02_L2H_LEVEL_01_LIB_WC_FILES|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::00_input.config.tcl::MMMC_PM_LEVEL_01_LIB_WC_FILES|FILL_IN_setup_00_input_config_tcl_MMMC_PM_LEVEL_01_LIB_WC_FILES|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::00_input.config.tcl::MMMC_PM_LEVEL_02_LIB_WC_FILES|FILL_IN_setup_00_input_config_tcl_MMMC_PM_LEVEL_02_LIB_WC_FILES|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::00_input.config.tcl::MMMC_MEM_LIB_WC_FILES|FILL_IN_setup_00_input_config_tcl_MMMC_MEM_LIB_WC_FILES|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::00_input.config.tcl::MMMC_CORE_LEVEL_01_LIB_BC_FILES|FILL_IN_setup_00_input_config_tcl_MMMC_CORE_LEVEL_01_LIB_BC_FILES|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::00_input.config.tcl::MMMC_CORE_LEVEL_02_LIB_BC_FILES|FILL_IN_setup_00_input_config_tcl_MMMC_CORE_LEVEL_02_LIB_BC_FILES|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::00_input.config.tcl::MMMC_IO_LIB_BC_FILES|FILL_IN_setup_00_input_config_tcl_MMMC_IO_LIB_BC_FILES|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::00_input.config.tcl::MMMC_LVL_LEVEL_01_H2L_LEVEL_02_LIB_BC_FILES|FILL_IN_setup_00_input_config_tcl_MMMC_LVL_LEVEL_01_H2L_LEVEL_02_LIB_BC_FILES|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::00_input.config.tcl::MMMC_LVL_LEVEL_02_L2H_LEVEL_01_LIB_BC_FILES|FILL_IN_setup_00_input_config_tcl_MMMC_LVL_LEVEL_02_L2H_LEVEL_01_LIB_BC_FILES|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::00_input.config.tcl::MMMC_PM_LEVEL_01_LIB_BC_FILES|FILL_IN_setup_00_input_config_tcl_MMMC_PM_LEVEL_01_LIB_BC_FILES|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::00_input.config.tcl::MMMC_PM_LEVEL_02_LIB_BC_FILES|FILL_IN_setup_00_input_config_tcl_MMMC_PM_LEVEL_02_LIB_BC_FILES|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::00_input.config.tcl::MMMC_MEM_LIB_BC_FILES|FILL_IN_setup_00_input_config_tcl_MMMC_MEM_LIB_BC_FILES|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::00_input.config.tcl::PG_LIBRARY_QRC_FILE|FILL_IN_setup_00_input_config_tcl_PG_LIBRARY_QRC_FILE|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::00_input.config.tcl::STREAM_OUT_MAP_SOURCE|FILL_IN_setup_00_input_config_tcl_STREAM_OUT_MAP_SOURCE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::00_input.config.tcl::STREAM_OUT_MAP_FILE|FILL_IN_setup_00_input_config_tcl_STREAM_OUT_MAP_FILE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::00_input.config.tcl::TECH_CORE_GDS_DIR|FILL_IN_setup_00_input_config_tcl_TECH_CORE_GDS_DIR|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::00_input.config.tcl::TECH_IO_GDS_DIR|FILL_IN_setup_00_input_config_tcl_TECH_IO_GDS_DIR|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::00_input.config.tcl::STREAM_MERGE_GDS_FILES|FILL_IN_setup_00_input_config_tcl_STREAM_MERGE_GDS_FILES|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::01_floorplan.config.tcl::CORE_SITE|FILL_IN_setup_01_floorplan_config_tcl_CORE_SITE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::01_floorplan.config.tcl::FLOORPLAN_IO_PAD_MIN_GAP|FILL_IN_setup_01_floorplan_config_tcl_FLOORPLAN_IO_PAD_MIN_GAP|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::01_floorplan.config.tcl::IO_CORNER_PAD_OFFSET|FILL_IN_setup_01_floorplan_config_tcl_IO_CORNER_PAD_OFFSET|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::01_floorplan.config.tcl::POWER_DOMAIN_CORE_OFFSET_CONFIG|FILL_IN_setup_01_floorplan_config_tcl_POWER_DOMAIN_CORE_OFFSET_CONFIG|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::01_floorplan.config.tcl::MACRO_PLACE_HALO|FILL_IN_setup_01_floorplan_config_tcl_MACRO_PLACE_HALO|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::01_floorplan.config.tcl::MACRO_ROUTE_HALO_SPACE|FILL_IN_setup_01_floorplan_config_tcl_MACRO_ROUTE_HALO_SPACE|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::01_floorplan.config.tcl::MACRO_ROUTE_HALO_BOTTOM_LAYER|FILL_IN_setup_01_floorplan_config_tcl_MACRO_ROUTE_HALO_BOTTOM_LAYER|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::01_floorplan.config.tcl::MACRO_ROUTE_HALO_TOP_LAYER|FILL_IN_setup_01_floorplan_config_tcl_MACRO_ROUTE_HALO_TOP_LAYER|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::01_floorplan.config.tcl::MACRO_CORNER_KEEPOUT|FILL_IN_setup_01_floorplan_config_tcl_MACRO_CORNER_KEEPOUT|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::01_floorplan.config.tcl::MACRO_H_OFFSET|FILL_IN_setup_01_floorplan_config_tcl_MACRO_H_OFFSET|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::01_floorplan.config.tcl::MACRO_V_OFFSET|FILL_IN_setup_01_floorplan_config_tcl_MACRO_V_OFFSET|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::01_floorplan.config.tcl::CLEAR_STD_CELLS_AFTER_MACRO_FLOORPLAN|FILL_IN_setup_01_floorplan_config_tcl_CLEAR_STD_CELLS_AFTER_MACRO_FLOORPLAN|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::01_floorplan.config.tcl::CLEAR_STD_CELLS_BEFORE_POWERPLAN|FILL_IN_setup_01_floorplan_config_tcl_CLEAR_STD_CELLS_BEFORE_POWERPLAN|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::01_floorplan.config.tcl::PD_BOUNDARY_GUARD_WIDTH|FILL_IN_setup_01_floorplan_config_tcl_PD_BOUNDARY_GUARD_WIDTH|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::01_floorplan.config.tcl::PD_BOUNDARY_ROW_GUARD_WIDTH|FILL_IN_setup_01_floorplan_config_tcl_PD_BOUNDARY_ROW_GUARD_WIDTH|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::01_floorplan.config.tcl::IO_BOND_PAD_PREVIEW_DB_NAME|FILL_IN_setup_01_floorplan_config_tcl_IO_BOND_PAD_PREVIEW_DB_NAME|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::01_floorplan.config.tcl::IO_BOND_PAD_PREVIEW_AFTER_DB_NAME|FILL_IN_setup_01_floorplan_config_tcl_IO_BOND_PAD_PREVIEW_AFTER_DB_NAME|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::01_floorplan.config.tcl::POWERPLAN_BOND_PAD_PREVIEW_DB_NAME|FILL_IN_setup_01_floorplan_config_tcl_POWERPLAN_BOND_PAD_PREVIEW_DB_NAME|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::01_floorplan.config.tcl::POWERPLAN_BOND_PAD_PREVIEW_AFTER_DB_NAME|FILL_IN_setup_01_floorplan_config_tcl_POWERPLAN_BOND_PAD_PREVIEW_AFTER_DB_NAME|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::01_floorplan.config.tcl::BOND_PAD_PREVIEW_SEARCH_PARITY|FILL_IN_setup_01_floorplan_config_tcl_BOND_PAD_PREVIEW_SEARCH_PARITY|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::01_floorplan.config.tcl::BOND_PAD_PREVIEW_STRICT_OVERLAP|FILL_IN_setup_01_floorplan_config_tcl_BOND_PAD_PREVIEW_STRICT_OVERLAP|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::01_floorplan.config.tcl::BOND_PAD_PREVIEW_SAVE_DB|FILL_IN_setup_01_floorplan_config_tcl_BOND_PAD_PREVIEW_SAVE_DB|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::01_floorplan.config.tcl::BOND_PAD_PARITY_FILE|FILL_IN_setup_01_floorplan_config_tcl_BOND_PAD_PARITY_FILE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::01_floorplan.config.tcl::BOND_PAD_PREVIEW_DB_NAME|FILL_IN_setup_01_floorplan_config_tcl_BOND_PAD_PREVIEW_DB_NAME|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::01_floorplan.config.tcl::BOND_PAD_ACCEPT_INTERNAL_MAXWIDTH|FILL_IN_setup_01_floorplan_config_tcl_BOND_PAD_ACCEPT_INTERNAL_MAXWIDTH|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::01_floorplan.config.tcl::INSERT_BOUNDARY_CELLS_AFTER_FLOORPLAN|FILL_IN_setup_01_floorplan_config_tcl_INSERT_BOUNDARY_CELLS_AFTER_FLOORPLAN|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::01_floorplan.config.tcl::ENDCAP_POWER_DOMAIN_LIST|FILL_IN_setup_01_floorplan_config_tcl_ENDCAP_POWER_DOMAIN_LIST|請填入endcap cell 或對應設定|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::01_floorplan.config.tcl::ENDCAP_DEFAULT_POWER_DOMAIN|FILL_IN_setup_01_floorplan_config_tcl_ENDCAP_DEFAULT_POWER_DOMAIN|請填入endcap cell 或對應設定|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::01_floorplan.config.tcl::ENDCAP_EXCLUDE_POWER_DOMAIN_PATTERNS|FILL_IN_setup_01_floorplan_config_tcl_ENDCAP_EXCLUDE_POWER_DOMAIN_PATTERNS|請填入endcap cell 或對應設定|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::01_floorplan.config.tcl::ENDCAP_GLOBAL_PREFIX|FILL_IN_setup_01_floorplan_config_tcl_ENDCAP_GLOBAL_PREFIX|請填入endcap cell 或對應設定|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::01_floorplan.config.tcl::ENDCAP_POWER_DOMAIN_PREFIX|FILL_IN_setup_01_floorplan_config_tcl_ENDCAP_POWER_DOMAIN_PREFIX|請填入endcap cell 或對應設定|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::01_floorplan.config.tcl::DEFER_WELL_TAP_TO_POST_POWERPLAN|FILL_IN_setup_01_floorplan_config_tcl_DEFER_WELL_TAP_TO_POST_POWERPLAN|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::01_floorplan.config.tcl::GACORE_SITE_NAME|FILL_IN_setup_01_floorplan_config_tcl_GACORE_SITE_NAME|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::01_floorplan.config.tcl::ENDCAP_LEFT_EDGE_CELLS|FILL_IN_setup_01_floorplan_config_tcl_ENDCAP_LEFT_EDGE_CELLS|請填入endcap cell 或對應設定|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::01_floorplan.config.tcl::ENDCAP_RIGHT_EDGE_CELLS|FILL_IN_setup_01_floorplan_config_tcl_ENDCAP_RIGHT_EDGE_CELLS|請填入endcap cell 或對應設定|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::01_floorplan.config.tcl::ENDCAP_LEFT_TOP_CORNER_CELLS|FILL_IN_setup_01_floorplan_config_tcl_ENDCAP_LEFT_TOP_CORNER_CELLS|請填入endcap cell 或對應設定|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::01_floorplan.config.tcl::ENDCAP_LEFT_BOTTOM_CORNER_CELLS|FILL_IN_setup_01_floorplan_config_tcl_ENDCAP_LEFT_BOTTOM_CORNER_CELLS|請填入endcap cell 或對應設定|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::01_floorplan.config.tcl::ENDCAP_TOP_EDGE_CELLS|FILL_IN_setup_01_floorplan_config_tcl_ENDCAP_TOP_EDGE_CELLS|請填入endcap cell 或對應設定|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::01_floorplan.config.tcl::ENDCAP_BOTTOM_EDGE_CELLS|FILL_IN_setup_01_floorplan_config_tcl_ENDCAP_BOTTOM_EDGE_CELLS|請填入endcap cell 或對應設定|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::01_floorplan.config.tcl::ENDCAP_CORNER_FILL_CELLS|FILL_IN_setup_01_floorplan_config_tcl_ENDCAP_CORNER_FILL_CELLS|請填入endcap cell 或對應設定|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::01_floorplan.config.tcl::ENDCAP_TOP_TAP_CELLS|FILL_IN_setup_01_floorplan_config_tcl_ENDCAP_TOP_TAP_CELLS|請填入endcap cell 或對應設定|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::01_floorplan.config.tcl::ENDCAP_BOTTOM_TAP_CELLS|FILL_IN_setup_01_floorplan_config_tcl_ENDCAP_BOTTOM_TAP_CELLS|請填入endcap cell 或對應設定|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::01_floorplan.config.tcl::ENDCAP_WELL_TAP_RULE|FILL_IN_setup_01_floorplan_config_tcl_ENDCAP_WELL_TAP_RULE|請填入endcap cell 或對應設定|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::01_floorplan.config.tcl::POWER_SWITCH_INSERTION_MODE|FILL_IN_setup_01_floorplan_config_tcl_POWER_SWITCH_INSERTION_MODE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::01_floorplan.config.tcl::POWER_SWITCH_INSTANCE_PREFIXES|FILL_IN_setup_01_floorplan_config_tcl_POWER_SWITCH_INSTANCE_PREFIXES|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::01_floorplan.config.tcl::POWER_SWITCH_LEFT_OFFSET|FILL_IN_setup_01_floorplan_config_tcl_POWER_SWITCH_LEFT_OFFSET|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::01_floorplan.config.tcl::POWER_SWITCH_RIGHT_OFFSET|FILL_IN_setup_01_floorplan_config_tcl_POWER_SWITCH_RIGHT_OFFSET|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::01_floorplan.config.tcl::POWER_SWITCH_TOP_OFFSET|FILL_IN_setup_01_floorplan_config_tcl_POWER_SWITCH_TOP_OFFSET|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::01_floorplan.config.tcl::POWER_SWITCH_BOTTOM_OFFSET|FILL_IN_setup_01_floorplan_config_tcl_POWER_SWITCH_BOTTOM_OFFSET|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::01_floorplan.config.tcl::POWER_SWITCH_EDGE_REINFORCE_GAP|FILL_IN_setup_01_floorplan_config_tcl_POWER_SWITCH_EDGE_REINFORCE_GAP|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::01_floorplan.config.tcl::POWER_SWITCH_ENDCAP_OVERLAP_AUTO_DELETE|FILL_IN_setup_01_floorplan_config_tcl_POWER_SWITCH_ENDCAP_OVERLAP_AUTO_DELETE|請填入endcap cell 或對應設定|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::01_floorplan.config.tcl::POWER_SWITCH_ENDCAP_OVERLAP_SAVE_DB|FILL_IN_setup_01_floorplan_config_tcl_POWER_SWITCH_ENDCAP_OVERLAP_SAVE_DB|請填入endcap cell 或對應設定|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::01_floorplan.config.tcl::ENDCAP_POST_INSERT_RUN_CHECKS|FILL_IN_setup_01_floorplan_config_tcl_ENDCAP_POST_INSERT_RUN_CHECKS|請填入endcap cell 或對應設定|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::01_floorplan.config.tcl::ENDCAP_POST_INSERT_SAVE_DB|FILL_IN_setup_01_floorplan_config_tcl_ENDCAP_POST_INSERT_SAVE_DB|請填入endcap cell 或對應設定|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::02_powerplan.config.tcl::PNS_AUTO_RUN_ON_SOURCE|FILL_IN_setup_02_powerplan_config_tcl_PNS_AUTO_RUN_ON_SOURCE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::02_powerplan.config.tcl::POWERPLAN_PAD_PIN_LAYER_CHANGE_RANGE|FILL_IN_setup_02_powerplan_config_tcl_POWERPLAN_PAD_PIN_LAYER_CHANGE_RANGE|請填入 library pin 名稱或接腳對應 dict|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::02_powerplan.config.tcl::POWERPLAN_PAD_PIN_LAYER_RANGE|FILL_IN_setup_02_powerplan_config_tcl_POWERPLAN_PAD_PIN_LAYER_RANGE|請填入 library pin 名稱或接腳對應 dict|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::02_powerplan.config.tcl::POWERPLAN_PAD_PIN_BLOCKAGE_LAYERS|FILL_IN_setup_02_powerplan_config_tcl_POWERPLAN_PAD_PIN_BLOCKAGE_LAYERS|請填入 library pin 名稱或接腳對應 dict|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::02_powerplan.config.tcl::POWERPLAN_PAD_PIN_BLOCKAGE_INNER_OFFSET|FILL_IN_setup_02_powerplan_config_tcl_POWERPLAN_PAD_PIN_BLOCKAGE_INNER_OFFSET|請填入 library pin 名稱或接腳對應 dict|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::02_powerplan.config.tcl::POWERPLAN_PAD_PIN_BLOCKAGE_OUTER_OFFSET|FILL_IN_setup_02_powerplan_config_tcl_POWERPLAN_PAD_PIN_BLOCKAGE_OUTER_OFFSET|請填入 library pin 名稱或接腳對應 dict|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::02_powerplan.config.tcl::POWERPLAN_PAD_PIN_BLOCKAGE_CORE_GAP|FILL_IN_setup_02_powerplan_config_tcl_POWERPLAN_PAD_PIN_BLOCKAGE_CORE_GAP|請填入 library pin 名稱或接腳對應 dict|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::02_powerplan.config.tcl::POWERPLAN_PAD_CELL_PATTERN|FILL_IN_setup_02_powerplan_config_tcl_POWERPLAN_PAD_CELL_PATTERN|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::02_powerplan.config.tcl::POWERPLAN_MACRO_PG_BLOCKAGE_LAYERS|FILL_IN_setup_02_powerplan_config_tcl_POWERPLAN_MACRO_PG_BLOCKAGE_LAYERS|請填入 PDK 層名或層範圍|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::02_powerplan.config.tcl::POWERPLAN_FLOATING_STRIPE_LAYER_CHANGE_RANGE|FILL_IN_setup_02_powerplan_config_tcl_POWERPLAN_FLOATING_STRIPE_LAYER_CHANGE_RANGE|請填入 PDK 層名或層範圍|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::02_powerplan.config.tcl::POWERPLAN_FOLLOW_PIN_LAYER_CHANGE_RANGE|FILL_IN_setup_02_powerplan_config_tcl_POWERPLAN_FOLLOW_PIN_LAYER_CHANGE_RANGE|請填入 library pin 名稱或接腳對應 dict|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::02_powerplan.config.tcl::POWERPLAN_FOLLOW_PIN_CORE_PIN_LAYER|FILL_IN_setup_02_powerplan_config_tcl_POWERPLAN_FOLLOW_PIN_CORE_PIN_LAYER|請填入 library pin 名稱或接腳對應 dict|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::02_powerplan.config.tcl::PNS_CORE_RING_1|FILL_IN_setup_02_powerplan_config_tcl_PNS_CORE_RING_1|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::02_powerplan.config.tcl::PNS_CORE_RING_2|FILL_IN_setup_02_powerplan_config_tcl_PNS_CORE_RING_2|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::02_powerplan.config.tcl::PNS_CORE_RING_3|FILL_IN_setup_02_powerplan_config_tcl_PNS_CORE_RING_3|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::02_powerplan.config.tcl::PNS_PAD_PIN_LAYER_CHANGE_RANGE|FILL_IN_setup_02_powerplan_config_tcl_PNS_PAD_PIN_LAYER_CHANGE_RANGE|請填入 library pin 名稱或接腳對應 dict|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::02_powerplan.config.tcl::PNS_PAD_PIN_LAYER_RANGE|FILL_IN_setup_02_powerplan_config_tcl_PNS_PAD_PIN_LAYER_RANGE|請填入 library pin 名稱或接腳對應 dict|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::02_powerplan.config.tcl::PNS_MACRO_BLOCKAGE_LAYERS|FILL_IN_setup_02_powerplan_config_tcl_PNS_MACRO_BLOCKAGE_LAYERS|請填入 PDK 層名或層範圍|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::02_powerplan.config.tcl::PNS_MACRO_BLOCKAGE_CLEARANCE|FILL_IN_setup_02_powerplan_config_tcl_PNS_MACRO_BLOCKAGE_CLEARANCE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::02_powerplan.config.tcl::PNS_M9_ALL_STRIPE|FILL_IN_setup_02_powerplan_config_tcl_PNS_M9_ALL_STRIPE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::02_powerplan.config.tcl::PNS_M8_GROUND_STRIPE|FILL_IN_setup_02_powerplan_config_tcl_PNS_M8_GROUND_STRIPE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::02_powerplan.config.tcl::PNS_M8_POWER_STRIPE|FILL_IN_setup_02_powerplan_config_tcl_PNS_M8_POWER_STRIPE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::02_powerplan.config.tcl::PNS_M7_GROUND_STRIPE|FILL_IN_setup_02_powerplan_config_tcl_PNS_M7_GROUND_STRIPE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::02_powerplan.config.tcl::PNS_M7_POWER_STRIPE|FILL_IN_setup_02_powerplan_config_tcl_PNS_M7_POWER_STRIPE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::02_powerplan.config.tcl::PNS_M6_GROUND_STRIPE|FILL_IN_setup_02_powerplan_config_tcl_PNS_M6_GROUND_STRIPE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::02_powerplan.config.tcl::PNS_M6_POWER_STRIPE|FILL_IN_setup_02_powerplan_config_tcl_PNS_M6_POWER_STRIPE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::02_powerplan.config.tcl::PNS_M5_GROUND_STRIPE|FILL_IN_setup_02_powerplan_config_tcl_PNS_M5_GROUND_STRIPE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::02_powerplan.config.tcl::PNS_M5_POWER_STRIPE|FILL_IN_setup_02_powerplan_config_tcl_PNS_M5_POWER_STRIPE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::02_powerplan.config.tcl::PNS_FOLLOW_PIN_LAYER_CHANGE_RANGE|FILL_IN_setup_02_powerplan_config_tcl_PNS_FOLLOW_PIN_LAYER_CHANGE_RANGE|請填入 library pin 名稱或接腳對應 dict|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::02_powerplan.config.tcl::PNS_FOLLOW_PIN_VIA_SCALE_HEIGHT|FILL_IN_setup_02_powerplan_config_tcl_PNS_FOLLOW_PIN_VIA_SCALE_HEIGHT|請填入 library pin 名稱或接腳對應 dict|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::02_powerplan.config.tcl::PNS_FOLLOW_PIN_VIA_SCALE_WIDTH|FILL_IN_setup_02_powerplan_config_tcl_PNS_FOLLOW_PIN_VIA_SCALE_WIDTH|請填入 library pin 名稱或接腳對應 dict|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::02_powerplan.config.tcl::PNS_M2_POWER_RAIL|FILL_IN_setup_02_powerplan_config_tcl_PNS_M2_POWER_RAIL|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::02_powerplan.config.tcl::PNS_M2_GROUND_RAIL|FILL_IN_setup_02_powerplan_config_tcl_PNS_M2_GROUND_RAIL|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::02_powerplan.config.tcl::POWER_SWITCH_DESIGN_MAP|FILL_IN_setup_02_powerplan_config_tcl_POWER_SWITCH_DESIGN_MAP|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::02_powerplan.config.tcl::POWER_SWITCH_HORIZONTAL_PITCH|FILL_IN_setup_02_powerplan_config_tcl_POWER_SWITCH_HORIZONTAL_PITCH|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::02_powerplan.config.tcl::PNS_STRIPE_SPACING_FROM_BLOCK|FILL_IN_setup_02_powerplan_config_tcl_PNS_STRIPE_SPACING_FROM_BLOCK|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::02_powerplan.config.tcl::PNS_STRIPE_MAX_SAME_LAYER_JOG_LENGTH|FILL_IN_setup_02_powerplan_config_tcl_PNS_STRIPE_MAX_SAME_LAYER_JOG_LENGTH|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::02_powerplan.config.tcl::PNS_STD_REGION_Y_EXPANSION|FILL_IN_setup_02_powerplan_config_tcl_PNS_STD_REGION_Y_EXPANSION|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::02_powerplan.config.tcl::PNS_RING_THRESHOLD|FILL_IN_setup_02_powerplan_config_tcl_PNS_RING_THRESHOLD|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::02_powerplan.config.tcl::PNS_RING_JOG_DISTANCE|FILL_IN_setup_02_powerplan_config_tcl_PNS_RING_JOG_DISTANCE|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::02_powerplan.config.tcl::PNS_MACRO_RING_WIDTH|FILL_IN_setup_02_powerplan_config_tcl_PNS_MACRO_RING_WIDTH|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::02_powerplan.config.tcl::PNS_MACRO_RING_SPACING|FILL_IN_setup_02_powerplan_config_tcl_PNS_MACRO_RING_SPACING|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::02_powerplan.config.tcl::PNS_MACRO_RING_OFFSET|FILL_IN_setup_02_powerplan_config_tcl_PNS_MACRO_RING_OFFSET|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::05_route.config.tcl::ROUTE_TOP_ROUTING_LAYER|FILL_IN_setup_05_route_config_tcl_ROUTE_TOP_ROUTING_LAYER|請填入 PDK 層名或層範圍|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::05_route.config.tcl::ROUTE_BOTTOM_ROUTING_LAYER|FILL_IN_setup_05_route_config_tcl_ROUTE_BOTTOM_ROUTING_LAYER|請填入 PDK 層名或層範圍|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::05_route.config.tcl::INST_PADDING_ERROR_TYPES|FILL_IN_setup_05_route_config_tcl_INST_PADDING_ERROR_TYPES|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::05_route.config.tcl::INST_PADDING_LEFT|FILL_IN_setup_05_route_config_tcl_INST_PADDING_LEFT|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::05_route.config.tcl::INST_PADDING_RIGHT|FILL_IN_setup_05_route_config_tcl_INST_PADDING_RIGHT|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::06_finish.config.tcl::FILLER_NO_SINGLE_SITE_GAP|FILL_IN_setup_06_finish_config_tcl_FILLER_NO_SINGLE_SITE_GAP|請填入filler cell 或對應設定|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::06_finish.config.tcl::FILLER_CELLS|FILL_IN_setup_06_finish_config_tcl_FILLER_CELLS|請填入filler cell 或對應設定|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::06_finish.config.tcl::STREAM_OUT_TEXT_SIZE|FILL_IN_setup_06_finish_config_tcl_STREAM_OUT_TEXT_SIZE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::06_finish.config.tcl::STREAM_OUT_LIB_NAME|FILL_IN_setup_06_finish_config_tcl_STREAM_OUT_LIB_NAME|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::06_finish.config.tcl::STREAM_OUT_UNIT|FILL_IN_setup_06_finish_config_tcl_STREAM_OUT_UNIT|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::06_finish.config.tcl::STREAM_OUT_MODE|FILL_IN_setup_06_finish_config_tcl_STREAM_OUT_MODE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::06_finish.config.tcl::STREAM_OUT_CUSTOM_MAP_LINES|FILL_IN_setup_06_finish_config_tcl_STREAM_OUT_CUSTOM_MAP_LINES|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|library::TECH_EXPORT_DECAP_MASTER_PATTERN|FILL_IN_library_TECH_EXPORT_DECAP_MASTER_PATTERN|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|library::TECH_EXPORT_POWERPAD_MASTER_PATTERN|FILL_IN_library_TECH_EXPORT_POWERPAD_MASTER_PATTERN|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|library::TECH_EXPORT_FILLER_MASTER_PATTERN|FILL_IN_library_TECH_EXPORT_FILLER_MASTER_PATTERN|請填入filler cell 或對應設定|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|library::TECH_EXPORT_PFILLER_MASTER_PATTERN|FILL_IN_library_TECH_EXPORT_PFILLER_MASTER_PATTERN|請填入filler cell 或對應設定|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|library::TECH_EXPORT_PCORNER_MASTER_PATTERN|FILL_IN_library_TECH_EXPORT_PCORNER_MASTER_PATTERN|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::01_floorplan.config.tcl::IOPAD_RING_NAME|FILL_IN_setup_01_floorplan_config_tcl_IOPAD_RING_NAME|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::01_floorplan.config.tcl::IOPAD_RING_COMMON_GROUND|FILL_IN_setup_01_floorplan_config_tcl_IOPAD_RING_COMMON_GROUND|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::01_floorplan.config.tcl::IOPAD_RING_DIRECTION|FILL_IN_setup_01_floorplan_config_tcl_IOPAD_RING_DIRECTION|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::01_floorplan.config.tcl::IOPAD_RING_DOMAIN_CONFIG|FILL_IN_setup_01_floorplan_config_tcl_IOPAD_RING_DOMAIN_CONFIG|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::01_floorplan.config.tcl::IOPAD_RING_CREATE_MISSING_PADS|FILL_IN_setup_01_floorplan_config_tcl_IOPAD_RING_CREATE_MISSING_PADS|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::01_floorplan.config.tcl::IOPAD_RING_CREATE_CUTS|FILL_IN_setup_01_floorplan_config_tcl_IOPAD_RING_CREATE_CUTS|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::01_floorplan.config.tcl::IOPAD_RING_CUT_PREFIX|FILL_IN_setup_01_floorplan_config_tcl_IOPAD_RING_CUT_PREFIX|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::01_floorplan.config.tcl::IOPAD_RING_CUT_BASE_VERTICAL|FILL_IN_setup_01_floorplan_config_tcl_IOPAD_RING_CUT_BASE_VERTICAL|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::01_floorplan.config.tcl::IOPAD_RING_CUT_BASE_HORIZONTAL|FILL_IN_setup_01_floorplan_config_tcl_IOPAD_RING_CUT_BASE_HORIZONTAL|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::01_floorplan.config.tcl::IOPAD_RING_STRICT|FILL_IN_setup_01_floorplan_config_tcl_IOPAD_RING_STRICT|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::02_powerplan.config.tcl::POWERPLAN_CORE_RING_LOWER|FILL_IN_setup_02_powerplan_config_tcl_POWERPLAN_CORE_RING_LOWER|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::02_powerplan.config.tcl::POWERPLAN_CORE_RING_UPPER|FILL_IN_setup_02_powerplan_config_tcl_POWERPLAN_CORE_RING_UPPER|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::02_powerplan.config.tcl::POWERPLAN_PD_TOP_RING_DOMAIN|FILL_IN_setup_02_powerplan_config_tcl_POWERPLAN_PD_TOP_RING_DOMAIN|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::02_powerplan.config.tcl::POWERPLAN_PD_BLOCK_RING_DOMAINS|FILL_IN_setup_02_powerplan_config_tcl_POWERPLAN_PD_BLOCK_RING_DOMAINS|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::02_powerplan.config.tcl::POWERPLAN_PD_RING_UPPER|FILL_IN_setup_02_powerplan_config_tcl_POWERPLAN_PD_RING_UPPER|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::02_powerplan.config.tcl::POWERPLAN_PD_RING_LOWER|FILL_IN_setup_02_powerplan_config_tcl_POWERPLAN_PD_RING_LOWER|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::02_powerplan.config.tcl::POWERPLAN_M9_ALL_STRIPE|FILL_IN_setup_02_powerplan_config_tcl_POWERPLAN_M9_ALL_STRIPE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::02_powerplan.config.tcl::POWERPLAN_M8_GROUND_STRIPE|FILL_IN_setup_02_powerplan_config_tcl_POWERPLAN_M8_GROUND_STRIPE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::02_powerplan.config.tcl::POWERPLAN_M8_POWER_STRIPE|FILL_IN_setup_02_powerplan_config_tcl_POWERPLAN_M8_POWER_STRIPE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::02_powerplan.config.tcl::POWERPLAN_M7_GROUND_STRIPE|FILL_IN_setup_02_powerplan_config_tcl_POWERPLAN_M7_GROUND_STRIPE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::02_powerplan.config.tcl::POWERPLAN_M7_POWER_STRIPE|FILL_IN_setup_02_powerplan_config_tcl_POWERPLAN_M7_POWER_STRIPE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::02_powerplan.config.tcl::POWERPLAN_M6_GROUND_STRIPE|FILL_IN_setup_02_powerplan_config_tcl_POWERPLAN_M6_GROUND_STRIPE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::02_powerplan.config.tcl::POWERPLAN_M6_POWER_STRIPE|FILL_IN_setup_02_powerplan_config_tcl_POWERPLAN_M6_POWER_STRIPE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::02_powerplan.config.tcl::POWERPLAN_M5_GROUND_STRIPE|FILL_IN_setup_02_powerplan_config_tcl_POWERPLAN_M5_GROUND_STRIPE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::02_powerplan.config.tcl::POWERPLAN_M5_POWER_STRIPE|FILL_IN_setup_02_powerplan_config_tcl_POWERPLAN_M5_POWER_STRIPE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::02_powerplan.config.tcl::POWERPLAN_FLOATING_STRIPE_TARGETS|FILL_IN_setup_02_powerplan_config_tcl_POWERPLAN_FLOATING_STRIPE_TARGETS|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::03_place.config.tcl::LS_PADDING_LEFT|FILL_IN_setup_03_place_config_tcl_LS_PADDING_LEFT|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::03_place.config.tcl::LS_PADDING_RIGHT|FILL_IN_setup_03_place_config_tcl_LS_PADDING_RIGHT|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::03_place.config.tcl::LS_PADDING_REPORT_LIMIT|FILL_IN_setup_03_place_config_tcl_LS_PADDING_REPORT_LIMIT|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::05_route.config.tcl::SECONDARY_PG_RAIL_LAYER|FILL_IN_setup_05_route_config_tcl_SECONDARY_PG_RAIL_LAYER|請填入 PDK 層名或層範圍|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::05_route.config.tcl::SECONDARY_PG_BOTTOM_LAYER|FILL_IN_setup_05_route_config_tcl_SECONDARY_PG_BOTTOM_LAYER|請填入 PDK 層名或層範圍|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::05_route.config.tcl::SECONDARY_PG_TOP_LAYER|FILL_IN_setup_05_route_config_tcl_SECONDARY_PG_TOP_LAYER|請填入 PDK 層名或層範圍|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::90_debug.config.tcl::TT_CP2_REPAIR_INCLUDE_ENDCAP|FILL_IN_setup_90_debug_config_tcl_TT_CP2_REPAIR_INCLUDE_ENDCAP|請填入endcap cell 或對應設定|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::90_debug.config.tcl::TT_CP2_REPAIR_MAX_CELLS|FILL_IN_setup_90_debug_config_tcl_TT_CP2_REPAIR_MAX_CELLS|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::90_debug.config.tcl::PD_ENDCAP_LEGALIZE_SITE|FILL_IN_setup_90_debug_config_tcl_PD_ENDCAP_LEGALIZE_SITE|請填入endcap cell 或對應設定|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::90_debug.config.tcl::PD_ENDCAP_LEGALIZE_TOL|FILL_IN_setup_90_debug_config_tcl_PD_ENDCAP_LEGALIZE_TOL|請填入endcap cell 或對應設定|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::90_debug.config.tcl::PD_ENDCAP_LEGALIZE_MAX_SHIFT|FILL_IN_setup_90_debug_config_tcl_PD_ENDCAP_LEGALIZE_MAX_SHIFT|請填入endcap cell 或對應設定|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::90_debug.config.tcl::TT_VIA_DRC_SUBTYPES|FILL_IN_setup_90_debug_config_tcl_TT_VIA_DRC_SUBTYPES|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::90_debug.config.tcl::TT_VIA_DRC_EQUAL_OVERLAP_RATIO|FILL_IN_setup_90_debug_config_tcl_TT_VIA_DRC_EQUAL_OVERLAP_RATIO|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::90_debug.config.tcl::CHECK_STAGE02_METAL_DENSITY_LAYERS|FILL_IN_setup_90_debug_config_tcl_CHECK_STAGE02_METAL_DENSITY_LAYERS|請填入 PDK 層名或層範圍|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::90_debug.config.tcl::CHECK_STAGE05_METAL_DENSITY_LAYERS|FILL_IN_setup_90_debug_config_tcl_CHECK_STAGE05_METAL_DENSITY_LAYERS|請填入 PDK 層名或層範圍|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::90_debug.config.tcl::CHECK_STAGE06_METAL_DENSITY_LAYERS|FILL_IN_setup_90_debug_config_tcl_CHECK_STAGE06_METAL_DENSITY_LAYERS|請填入 PDK 層名或層範圍|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::90_debug.config.tcl::METAL_DENSITY_LIMIT_TABLE|FILL_IN_setup_90_debug_config_tcl_METAL_DENSITY_LIMIT_TABLE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::00_design.config.tcl::POWER_PORT_NETS|FILL_IN_setup_00_design_config_tcl_POWER_PORT_NETS|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::00_design.config.tcl::POWER_NETS|FILL_IN_setup_00_design_config_tcl_POWER_NETS|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::00_design.config.tcl::GROUND_NET|FILL_IN_setup_00_design_config_tcl_GROUND_NET|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::00_design.config.tcl::PD_CFG|FILL_IN_setup_00_design_config_tcl_PD_CFG|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::01_floorplan.config.tcl::FLOORPLAN_DIE_SIZE|FILL_IN_setup_01_floorplan_config_tcl_FLOORPLAN_DIE_SIZE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::01_floorplan.config.tcl::FLOORPLAN_BOX_SIZE|FILL_IN_setup_01_floorplan_config_tcl_FLOORPLAN_BOX_SIZE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::01_floorplan.config.tcl::FLOORPLAN_BOUND_THRESHOLD|FILL_IN_setup_01_floorplan_config_tcl_FLOORPLAN_BOUND_THRESHOLD|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::01_floorplan.config.tcl::FLOORPLAN_BOUND_MARGIN|FILL_IN_setup_01_floorplan_config_tcl_FLOORPLAN_BOUND_MARGIN|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::01_floorplan.config.tcl::FLOORPLAN_CORE_DENSITY_ASPECT_RATIO|FILL_IN_setup_01_floorplan_config_tcl_FLOORPLAN_CORE_DENSITY_ASPECT_RATIO|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::01_floorplan.config.tcl::RTE_PAD_PIN|FILL_IN_setup_01_floorplan_config_tcl_RTE_PAD_PIN|請填入 library pin 名稱或接腳對應 dict|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::01_floorplan.config.tcl::RTE_PAD_BOND_ASSIGN_SUPPLIES|FILL_IN_setup_01_floorplan_config_tcl_RTE_PAD_BOND_ASSIGN_SUPPLIES|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::01_floorplan.config.tcl::POWER_DOMAIN_SCALE_CONFIG|FILL_IN_setup_01_floorplan_config_tcl_POWER_DOMAIN_SCALE_CONFIG|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::01_floorplan.config.tcl::POWER_DOMAIN_ASPECT_RATIO_CONFIG|FILL_IN_setup_01_floorplan_config_tcl_POWER_DOMAIN_ASPECT_RATIO_CONFIG|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::01_floorplan.config.tcl::MACRO_MIN_SPACE_TO_CORE|FILL_IN_setup_01_floorplan_config_tcl_MACRO_MIN_SPACE_TO_CORE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::01_floorplan.config.tcl::MACRO_MIN_SPACE_TO_MACRO|FILL_IN_setup_01_floorplan_config_tcl_MACRO_MIN_SPACE_TO_MACRO|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::01_floorplan.config.tcl::MACRO_H_SPACE|FILL_IN_setup_01_floorplan_config_tcl_MACRO_H_SPACE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::01_floorplan.config.tcl::MACRO_V_SPACE|FILL_IN_setup_01_floorplan_config_tcl_MACRO_V_SPACE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::02_powerplan.config.tcl::POWERPLAN_PAD_PIN_PORT_CONNECT|FILL_IN_setup_02_powerplan_config_tcl_POWERPLAN_PAD_PIN_PORT_CONNECT|請填入 library pin 名稱或接腳對應 dict|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::02_powerplan.config.tcl::POWERPLAN_PAD_PIN_BLOCKAGE_NAME|FILL_IN_setup_02_powerplan_config_tcl_POWERPLAN_PAD_PIN_BLOCKAGE_NAME|請填入 library pin 名稱或接腳對應 dict|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::02_powerplan.config.tcl::POWERPLAN_MACRO_PG_BLOCKAGE_CLEARANCE|FILL_IN_setup_02_powerplan_config_tcl_POWERPLAN_MACRO_PG_BLOCKAGE_CLEARANCE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|setup::02_powerplan.config.tcl::POWERPLAN_FOLLOW_PIN_TARGET|FILL_IN_setup_02_powerplan_config_tcl_POWERPLAN_FOLLOW_PIN_TARGET|請填入 library pin 名稱或接腳對應 dict|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|library::TECH_CTS_BUFFER_MASTER_LIST|FILL_IN_library_TECH_CTS_BUFFER_MASTER_LIST|請填入clock buffer cell 或對應設定|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|library::TECH_CTS_INVERTER_MASTER_LIST|FILL_IN_library_TECH_CTS_INVERTER_MASTER_LIST|請填入clock inverter cell 或對應設定|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|library::TECH_CTS_CLOCK_GATING_MASTER_LIST|FILL_IN_library_TECH_CTS_CLOCK_GATING_MASTER_LIST|請填入ICG cell 或對應設定|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|cts::TECH_CTS_NDR_WIDTH_L12|FILL_IN_cts_TECH_CTS_NDR_WIDTH_L12|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|cts::TECH_CTS_NDR_SPACING_L12|FILL_IN_cts_TECH_CTS_NDR_SPACING_L12|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|cts::TECH_CTS_NDR_WIDTH_L15|FILL_IN_cts_TECH_CTS_NDR_WIDTH_L15|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|cts::TECH_CTS_NDR_SPACING_L15|FILL_IN_cts_TECH_CTS_NDR_SPACING_L15|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|cts::TECH_CTS_NDR_WIDTH_L19|FILL_IN_cts_TECH_CTS_NDR_WIDTH_L19|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|cts::TECH_CTS_NDR_SPACING_L19|FILL_IN_cts_TECH_CTS_NDR_SPACING_L19|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|cts::TECH_CTS_NDR_WIDTH_L22|FILL_IN_cts_TECH_CTS_NDR_WIDTH_L22|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|cts::TECH_CTS_NDR_SPACING_L22|FILL_IN_cts_TECH_CTS_NDR_SPACING_L22|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|library_value::LIB_QUERY_001|FILL_IN_library_value_LIB_QUERY_001|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|library_value::LIB_PIN_001|FILL_IN_library_value_LIB_PIN_001|請填入 library pin 名稱或接腳對應 dict|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|library_value::LIB_TECH_001|FILL_IN_library_value_LIB_TECH_001|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|library_value::LIB_PIN_002|FILL_IN_library_value_LIB_PIN_002|請填入 library pin 名稱或接腳對應 dict|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|library_value::LIB_CELL_001|FILL_IN_library_value_LIB_CELL_001|請填入boundary／endcap cell／cell 清單|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|library_value::LIB_CELL_002|FILL_IN_library_value_LIB_CELL_002|請填入well tap cell／cell 清單|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|library_value::LIB_CELL_003|FILL_IN_library_value_LIB_CELL_003|請填入header power switch cell／cell 清單|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|library_value::LIB_CELL_004|FILL_IN_library_value_LIB_CELL_004|請填入I/O pad、power pad、rail cut 與 corner cell／cell 清單|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|library_value::LIB_MATCH_001|FILL_IN_library_value_LIB_MATCH_001|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|library_value::LIB_TECH_002|FILL_IN_library_value_LIB_TECH_002|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|library_value::LIB_MATCH_002|FILL_IN_library_value_LIB_MATCH_002|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|library_value::LIB_TEXT_001|FILL_IN_library_value_LIB_TEXT_001|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|library_value::LIB_TEXT_002|FILL_IN_library_value_LIB_TEXT_002|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|library_value::LIB_TEXT_003|FILL_IN_library_value_LIB_TEXT_003|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|library_value::LIB_TEXT_004|FILL_IN_library_value_LIB_TEXT_004|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|library_value::LIB_CELL_005|FILL_IN_library_value_LIB_CELL_005|請填入boundary／endcap cell／cell 清單|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|library_value::LIB_MATCH_003|FILL_IN_library_value_LIB_MATCH_003|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|library_value::LIB_TEXT_005|FILL_IN_library_value_LIB_TEXT_005|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|library_value::LIB_CELL_006|FILL_IN_library_value_LIB_CELL_006|請填入I/O filler cell／cell 清單|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|library_value::LIB_CELL_007|FILL_IN_library_value_LIB_CELL_007|請填入I/O filler cell／cell 清單|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|library_value::LIB_CELL_008|FILL_IN_library_value_LIB_CELL_008|請填入I/O filler cell／cell 清單|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|library_value::LIB_CELL_009|FILL_IN_library_value_LIB_CELL_009|請填入I/O filler cell／cell 清單|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|library_value::LIB_CELL_010|FILL_IN_library_value_LIB_CELL_010|請填入右側 boundary／endcap cell／cell 清單|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|library_value::LIB_CELL_011|FILL_IN_library_value_LIB_CELL_011|請填入左側 boundary／endcap cell／cell 清單|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|library_value::LIB_QUERY_002|FILL_IN_library_value_LIB_QUERY_002|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|library_value::LIB_PIN_003|FILL_IN_library_value_LIB_PIN_003|請填入 library pin 名稱或接腳對應 dict|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|library_value::LIB_PIN_004|FILL_IN_library_value_LIB_PIN_004|請填入 library pin 名稱或接腳對應 dict|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|library_value::LIB_PIN_005|FILL_IN_library_value_LIB_PIN_005|請填入 library pin 名稱或接腳對應 dict|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|library_value::LIB_PIN_006|FILL_IN_library_value_LIB_PIN_006|請填入 library pin 名稱或接腳對應 dict|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|library_value::LIB_PIN_007|FILL_IN_library_value_LIB_PIN_007|請填入 library pin 名稱或接腳對應 dict|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|library_value::LIB_PIN_008|FILL_IN_library_value_LIB_PIN_008|請填入 library pin 名稱或接腳對應 dict|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|library_value::LIB_PIN_009|FILL_IN_library_value_LIB_PIN_009|請填入 library pin 名稱或接腳對應 dict|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|library_value::LIB_TECH_003|FILL_IN_library_value_LIB_TECH_003|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|library_value::LIB_TEXT_006|FILL_IN_library_value_LIB_TEXT_006|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|library_value::LIB_TEXT_007|FILL_IN_library_value_LIB_TEXT_007|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|library_value::LIB_TEXT_008|FILL_IN_library_value_LIB_TEXT_008|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|library_value::LIB_TEXT_009|FILL_IN_library_value_LIB_TEXT_009|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|library_value::LIB_TEXT_010|FILL_IN_library_value_LIB_TEXT_010|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|library_value::LIB_TEXT_011|FILL_IN_library_value_LIB_TEXT_011|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|library_value::LIB_TEXT_012|FILL_IN_library_value_LIB_TEXT_012|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|library_value::LIB_TEXT_013|FILL_IN_library_value_LIB_TEXT_013|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|library_value::LIB_TEXT_014|FILL_IN_library_value_LIB_TEXT_014|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|library_value::LIB_TEXT_015|FILL_IN_library_value_LIB_TEXT_015|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|library_value::LIB_TECH_004|FILL_IN_library_value_LIB_TECH_004|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|library_value::LIB_TEXT_016|FILL_IN_library_value_LIB_TEXT_016|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|library_value::LIB_TEXT_017|FILL_IN_library_value_LIB_TEXT_017|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|library_value::LIB_TECH_005|FILL_IN_library_value_LIB_TECH_005|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|library_value::LIB_TECH_006|FILL_IN_library_value_LIB_TECH_006|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|library_value::LIB_TECH_007|FILL_IN_library_value_LIB_TECH_007|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|library_value::LIB_TECH_008|FILL_IN_library_value_LIB_TECH_008|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|library_value::LIB_TEXT_018|FILL_IN_library_value_LIB_TEXT_018|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|library_value::LIB_TEXT_019|FILL_IN_library_value_LIB_TEXT_019|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|library_value::LP_PIN_SECONDARY_A|FILL_IN_library_value_LP_PIN_SECONDARY_A|請填入 library pin 名稱或接腳對應 dict|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|library_value::LP_PIN_SECONDARY_B|FILL_IN_library_value_LP_PIN_SECONDARY_B|請填入 library pin 名稱或接腳對應 dict|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|library_value::LP_PIN_RETENTION_AON|FILL_IN_library_value_LP_PIN_RETENTION_AON|請填入 library pin 名稱或接腳對應 dict|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|library_value::PG_LIBRARY_POWER_PIN_VALUES|FILL_IN_library_value_PG_LIBRARY_POWER_PIN_VALUES|請填入 library pin 名稱或接腳對應 dict|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|library_value::PG_LIBRARY_GROUND_PINS|FILL_IN_library_value_PG_LIBRARY_GROUND_PINS|請填入 library pin 名稱或接腳對應 dict|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|library_value::SW_LANDING_TARGET_INSTANCE|FILL_IN_library_value_SW_LANDING_TARGET_INSTANCE|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|library_value::SW_LANDING_TARGET_NET|FILL_IN_library_value_SW_LANDING_TARGET_NET|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|library_value::SW_LANDING_PG_PIN_PATTERN|FILL_IN_library_value_SW_LANDING_PG_PIN_PATTERN|請填入 library pin 名稱或接腳對應 dict|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|library_value::SW_LANDING_INSTANCE_PATTERN|FILL_IN_library_value_SW_LANDING_INSTANCE_PATTERN|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|library_value::SW_LANDING_POWER_PIN|FILL_IN_library_value_SW_LANDING_POWER_PIN|請填入 library pin 名稱或接腳對應 dict|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|library_value::SW_GATE_NET_ISSUE_PATTERN|FILL_IN_library_value_SW_GATE_NET_ISSUE_PATTERN|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|library::FILLER_FLOW_CELLS|FILL_IN_library_FILLER_FLOW_CELLS|請填入filler cell 或對應設定|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|early_rail::ERA_ARGS_01|FILL_IN_early_rail_ERA_ARGS_01|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|early_rail::ERA_ARGS_02|FILL_IN_early_rail_ERA_ARGS_02|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|early_rail::ERA_ARGS_03|FILL_IN_early_rail_ERA_ARGS_03|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|early_rail::ERA_ARGS_04|FILL_IN_early_rail_ERA_ARGS_04|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|early_rail::ERA_ARGS_05|FILL_IN_early_rail_ERA_ARGS_05|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|early_rail::ERA_ARGS_06|FILL_IN_early_rail_ERA_ARGS_06|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|early_rail::ERA_ARGS_07|FILL_IN_early_rail_ERA_ARGS_07|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|early_rail::ERA_ARGS_08|FILL_IN_early_rail_ERA_ARGS_08|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|early_rail::ERA_ARGS_09|FILL_IN_early_rail_ERA_ARGS_09|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|early_rail::ERA_ARGS_10|FILL_IN_early_rail_ERA_ARGS_10|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|early_rail::ERA_ARGS_11|FILL_IN_early_rail_ERA_ARGS_11|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|early_rail::ERA_ARGS_12|FILL_IN_early_rail_ERA_ARGS_12|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|early_rail::ERA_ARGS_13|FILL_IN_early_rail_ERA_ARGS_13|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|early_rail::DOMAIN|FILL_IN_early_rail_DOMAIN|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|library_value::ENDCAP_DIRECTION_EXACT_1|FILL_IN_library_value_ENDCAP_DIRECTION_EXACT_1|請填入endcap cell 或對應設定|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|library_value::ENDCAP_DIRECTION_EXACT_2|FILL_IN_library_value_ENDCAP_DIRECTION_EXACT_2|請填入endcap cell 或對應設定|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|library_value::PURE_FILLER_MASTER_PATTERN|FILL_IN_library_value_PURE_FILLER_MASTER_PATTERN|請填入filler cell 或對應設定|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|library_value::TIEOFF_MASTER_LIST|FILL_IN_library_value_TIEOFF_MASTER_LIST|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|library_value::DESIGN_PROCESS_NODE|FILL_IN_library_value_DESIGN_PROCESS_NODE|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|library_value::DESIGN_NATIVE_TOP_LAYER|FILL_IN_library_value_DESIGN_NATIVE_TOP_LAYER|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|library_value::DESIGN_NATIVE_BOTTOM_LAYER|FILL_IN_library_value_DESIGN_NATIVE_BOTTOM_LAYER|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|library_value::IO_ELECTRICAL_PIN_01|FILL_IN_library_value_IO_ELECTRICAL_PIN_01|請填入 library pin 名稱或接腳對應 dict|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|library_value::IO_ELECTRICAL_PIN_02|FILL_IN_library_value_IO_ELECTRICAL_PIN_02|請填入 library pin 名稱或接腳對應 dict|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|library_value::IO_ELECTRICAL_PIN_03|FILL_IN_library_value_IO_ELECTRICAL_PIN_03|請填入 library pin 名稱或接腳對應 dict|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|library_value::IO_ELECTRICAL_PIN_04|FILL_IN_library_value_IO_ELECTRICAL_PIN_04|請填入 library pin 名稱或接腳對應 dict|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|library_value::CTS_SHIELD_NET|FILL_IN_library_value_CTS_SHIELD_NET|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|library_value::LIB_DIAGNOSTIC_ID_12|FILL_IN_library_value_LIB_DIAGNOSTIC_ID_12|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|library_value::LIB_DIAGNOSTIC_ID_13|FILL_IN_library_value_LIB_DIAGNOSTIC_ID_13|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|library_value::DEBUG_SWITCH_CHAIN_PIN_PATTERN|FILL_IN_library_value_DEBUG_SWITCH_CHAIN_PIN_PATTERN|請填入 library pin 名稱或接腳對應 dict|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|library_value::IOPAD_DISCOVERY_MASTER_FAMILIES|FILL_IN_library_value_IOPAD_DISCOVERY_MASTER_FAMILIES|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|library_value::IOPAD_DISCOVERY_CORNER_MASTER|FILL_IN_library_value_IOPAD_DISCOVERY_CORNER_MASTER|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|library_value::IOPAD_PG_PLACEMENT_MASTER_01|FILL_IN_library_value_IOPAD_PG_PLACEMENT_MASTER_01|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|library_value::IOPAD_PG_PLACEMENT_MASTER_02|FILL_IN_library_value_IOPAD_PG_PLACEMENT_MASTER_02|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|library_value::IOPAD_PG_PLACEMENT_MASTER_03|FILL_IN_library_value_IOPAD_PG_PLACEMENT_MASTER_03|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|library_value::IOPAD_PG_PLACEMENT_MASTER_04|FILL_IN_library_value_IOPAD_PG_PLACEMENT_MASTER_04|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|library_value::IOPAD_PG_PLACEMENT_MASTER_05|FILL_IN_library_value_IOPAD_PG_PLACEMENT_MASTER_05|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|library_value::IOPAD_PG_PLACEMENT_MASTER_06|FILL_IN_library_value_IOPAD_PG_PLACEMENT_MASTER_06|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|library_value::IOPAD_PG_PLACEMENT_MASTER_07|FILL_IN_library_value_IOPAD_PG_PLACEMENT_MASTER_07|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|library_value::SW_CONNECTIVITY_DIAGNOSTIC_PIN|FILL_IN_library_value_SW_CONNECTIVITY_DIAGNOSTIC_PIN|請填入 library pin 名稱或接腳對應 dict|
|baseline/script/PR/TECH_MV/setup/config/private/setup_commands.tcl|library_value::ENDCAP_CHECKPOINT_COMPAT_NAMES|FILL_IN_library_value_ENDCAP_CHECKPOINT_COMPAT_NAMES|請填入endcap cell 或對應設定|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::00_design.config.tcl::BOND_PAD_CELL|FILL_IN_setup_00_design_config_tcl_BOND_PAD_CELL|請填入bond pad cell 或對應設定|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::00_design.config.tcl::BOND_PAD_TOP_LAYER|FILL_IN_setup_00_design_config_tcl_BOND_PAD_TOP_LAYER|請填入 PDK 層名或層範圍|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::00_design.config.tcl::BOND_PAD_DEFAULT_PIN|FILL_IN_setup_00_design_config_tcl_BOND_PAD_DEFAULT_PIN|請填入 library pin 名稱或接腳對應 dict|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::00_design.config.tcl::BOND_PAD_PIN_MAP|FILL_IN_setup_00_design_config_tcl_BOND_PAD_PIN_MAP|請填入 library pin 名稱或接腳對應 dict|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::00_design.config.tcl::BOND_PAD_RIGHT_DOWN|FILL_IN_setup_00_design_config_tcl_BOND_PAD_RIGHT_DOWN|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::00_design.config.tcl::BOND_PAD_TOP_RIGHT|FILL_IN_setup_00_design_config_tcl_BOND_PAD_TOP_RIGHT|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::00_design.config.tcl::BOND_PAD_LEFT_UP|FILL_IN_setup_00_design_config_tcl_BOND_PAD_LEFT_UP|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::00_design.config.tcl::BOND_PAD_BOTTOM_LEFT|FILL_IN_setup_00_design_config_tcl_BOND_PAD_BOTTOM_LEFT|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::00_design.config.tcl::BOND_PAD_RDL_WIDTH|FILL_IN_setup_00_design_config_tcl_BOND_PAD_RDL_WIDTH|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::00_design.config.tcl::BOND_PAD_RDL_SPACING|FILL_IN_setup_00_design_config_tcl_BOND_PAD_RDL_SPACING|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::00_design.config.tcl::BOND_PAD_GAP|FILL_IN_setup_00_design_config_tcl_BOND_PAD_GAP|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::00_design.config.tcl::BOND_PAD_CHIP_BOUNDARY_LAYER|FILL_IN_setup_00_design_config_tcl_BOND_PAD_CHIP_BOUNDARY_LAYER|請填入 PDK 層名或層範圍|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::00_design.config.tcl::BOND_PAD_CHIP_BOUNDARY_VERTICAL_EXTEND|FILL_IN_setup_00_design_config_tcl_BOND_PAD_CHIP_BOUNDARY_VERTICAL_EXTEND|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::00_design.config.tcl::BOND_PAD_CHIP_BOUNDARY_HORIZONTAL_EXTEND|FILL_IN_setup_00_design_config_tcl_BOND_PAD_CHIP_BOUNDARY_HORIZONTAL_EXTEND|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::00_input.config.tcl::NETLIST_FILE|FILL_IN_setup_00_input_config_tcl_NETLIST_FILE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::00_input.config.tcl::SDC_FILE|FILL_IN_setup_00_input_config_tcl_SDC_FILE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::00_input.config.tcl::IO_FILE|FILL_IN_setup_00_input_config_tcl_IO_FILE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::00_input.config.tcl::UPF_SOURCE_DIR|FILL_IN_setup_00_input_config_tcl_UPF_SOURCE_DIR|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::00_input.config.tcl::UPF_FILE|FILL_IN_setup_00_input_config_tcl_UPF_FILE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::00_input.config.tcl::UPF_SOURCE_FILES|FILL_IN_setup_00_input_config_tcl_UPF_SOURCE_FILES|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::00_input.config.tcl::LEF_FILES|FILL_IN_setup_00_input_config_tcl_LEF_FILES|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::00_input.config.tcl::MMMC_QRC_BEST_FILE|FILL_IN_setup_00_input_config_tcl_MMMC_QRC_BEST_FILE|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::00_input.config.tcl::MMMC_QRC_WORST_FILE|FILL_IN_setup_00_input_config_tcl_MMMC_QRC_WORST_FILE|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::00_input.config.tcl::MMMC_CORE_LEVEL_01_LIB_WC_FILES|FILL_IN_setup_00_input_config_tcl_MMMC_CORE_LEVEL_01_LIB_WC_FILES|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::00_input.config.tcl::MMMC_CORE_LEVEL_02_LIB_WC_FILES|FILL_IN_setup_00_input_config_tcl_MMMC_CORE_LEVEL_02_LIB_WC_FILES|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::00_input.config.tcl::MMMC_IO_LIB_WC_FILES|FILL_IN_setup_00_input_config_tcl_MMMC_IO_LIB_WC_FILES|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::00_input.config.tcl::MMMC_LVL_LEVEL_01_H2L_LEVEL_02_LIB_WC_FILES|FILL_IN_setup_00_input_config_tcl_MMMC_LVL_LEVEL_01_H2L_LEVEL_02_LIB_WC_FILES|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::00_input.config.tcl::MMMC_LVL_LEVEL_02_L2H_LEVEL_01_LIB_WC_FILES|FILL_IN_setup_00_input_config_tcl_MMMC_LVL_LEVEL_02_L2H_LEVEL_01_LIB_WC_FILES|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::00_input.config.tcl::MMMC_PM_LEVEL_01_LIB_WC_FILES|FILL_IN_setup_00_input_config_tcl_MMMC_PM_LEVEL_01_LIB_WC_FILES|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::00_input.config.tcl::MMMC_PM_LEVEL_02_LIB_WC_FILES|FILL_IN_setup_00_input_config_tcl_MMMC_PM_LEVEL_02_LIB_WC_FILES|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::00_input.config.tcl::MMMC_MEM_LIB_WC_FILES|FILL_IN_setup_00_input_config_tcl_MMMC_MEM_LIB_WC_FILES|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::00_input.config.tcl::MMMC_CORE_LEVEL_01_LIB_BC_FILES|FILL_IN_setup_00_input_config_tcl_MMMC_CORE_LEVEL_01_LIB_BC_FILES|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::00_input.config.tcl::MMMC_CORE_LEVEL_02_LIB_BC_FILES|FILL_IN_setup_00_input_config_tcl_MMMC_CORE_LEVEL_02_LIB_BC_FILES|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::00_input.config.tcl::MMMC_IO_LIB_BC_FILES|FILL_IN_setup_00_input_config_tcl_MMMC_IO_LIB_BC_FILES|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::00_input.config.tcl::MMMC_LVL_LEVEL_01_H2L_LEVEL_02_LIB_BC_FILES|FILL_IN_setup_00_input_config_tcl_MMMC_LVL_LEVEL_01_H2L_LEVEL_02_LIB_BC_FILES|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::00_input.config.tcl::MMMC_LVL_LEVEL_02_L2H_LEVEL_01_LIB_BC_FILES|FILL_IN_setup_00_input_config_tcl_MMMC_LVL_LEVEL_02_L2H_LEVEL_01_LIB_BC_FILES|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::00_input.config.tcl::MMMC_PM_LEVEL_01_LIB_BC_FILES|FILL_IN_setup_00_input_config_tcl_MMMC_PM_LEVEL_01_LIB_BC_FILES|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::00_input.config.tcl::MMMC_PM_LEVEL_02_LIB_BC_FILES|FILL_IN_setup_00_input_config_tcl_MMMC_PM_LEVEL_02_LIB_BC_FILES|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::00_input.config.tcl::MMMC_MEM_LIB_BC_FILES|FILL_IN_setup_00_input_config_tcl_MMMC_MEM_LIB_BC_FILES|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::00_input.config.tcl::PG_LIBRARY_QRC_FILE|FILL_IN_setup_00_input_config_tcl_PG_LIBRARY_QRC_FILE|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::00_input.config.tcl::STREAM_OUT_MAP_SOURCE|FILL_IN_setup_00_input_config_tcl_STREAM_OUT_MAP_SOURCE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::00_input.config.tcl::STREAM_OUT_MAP_FILE|FILL_IN_setup_00_input_config_tcl_STREAM_OUT_MAP_FILE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::00_input.config.tcl::TECH_CORE_GDS_DIR|FILL_IN_setup_00_input_config_tcl_TECH_CORE_GDS_DIR|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::00_input.config.tcl::TECH_IO_GDS_DIR|FILL_IN_setup_00_input_config_tcl_TECH_IO_GDS_DIR|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::00_input.config.tcl::STREAM_MERGE_GDS_FILES|FILL_IN_setup_00_input_config_tcl_STREAM_MERGE_GDS_FILES|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::01_floorplan.config.tcl::CORE_SITE|FILL_IN_setup_01_floorplan_config_tcl_CORE_SITE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::01_floorplan.config.tcl::FLOORPLAN_IO_PAD_MIN_GAP|FILL_IN_setup_01_floorplan_config_tcl_FLOORPLAN_IO_PAD_MIN_GAP|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::01_floorplan.config.tcl::IO_CORNER_PAD_OFFSET|FILL_IN_setup_01_floorplan_config_tcl_IO_CORNER_PAD_OFFSET|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::01_floorplan.config.tcl::POWER_DOMAIN_CORE_OFFSET_CONFIG|FILL_IN_setup_01_floorplan_config_tcl_POWER_DOMAIN_CORE_OFFSET_CONFIG|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::01_floorplan.config.tcl::MACRO_PLACE_HALO|FILL_IN_setup_01_floorplan_config_tcl_MACRO_PLACE_HALO|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::01_floorplan.config.tcl::MACRO_ROUTE_HALO_SPACE|FILL_IN_setup_01_floorplan_config_tcl_MACRO_ROUTE_HALO_SPACE|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::01_floorplan.config.tcl::MACRO_ROUTE_HALO_BOTTOM_LAYER|FILL_IN_setup_01_floorplan_config_tcl_MACRO_ROUTE_HALO_BOTTOM_LAYER|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::01_floorplan.config.tcl::MACRO_ROUTE_HALO_TOP_LAYER|FILL_IN_setup_01_floorplan_config_tcl_MACRO_ROUTE_HALO_TOP_LAYER|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::01_floorplan.config.tcl::MACRO_CORNER_KEEPOUT|FILL_IN_setup_01_floorplan_config_tcl_MACRO_CORNER_KEEPOUT|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::01_floorplan.config.tcl::MACRO_H_OFFSET|FILL_IN_setup_01_floorplan_config_tcl_MACRO_H_OFFSET|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::01_floorplan.config.tcl::MACRO_V_OFFSET|FILL_IN_setup_01_floorplan_config_tcl_MACRO_V_OFFSET|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::01_floorplan.config.tcl::CLEAR_STD_CELLS_AFTER_MACRO_FLOORPLAN|FILL_IN_setup_01_floorplan_config_tcl_CLEAR_STD_CELLS_AFTER_MACRO_FLOORPLAN|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::01_floorplan.config.tcl::CLEAR_STD_CELLS_BEFORE_POWERPLAN|FILL_IN_setup_01_floorplan_config_tcl_CLEAR_STD_CELLS_BEFORE_POWERPLAN|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::01_floorplan.config.tcl::PD_BOUNDARY_GUARD_WIDTH|FILL_IN_setup_01_floorplan_config_tcl_PD_BOUNDARY_GUARD_WIDTH|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::01_floorplan.config.tcl::PD_BOUNDARY_ROW_GUARD_WIDTH|FILL_IN_setup_01_floorplan_config_tcl_PD_BOUNDARY_ROW_GUARD_WIDTH|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::01_floorplan.config.tcl::IO_BOND_PAD_PREVIEW_DB_NAME|FILL_IN_setup_01_floorplan_config_tcl_IO_BOND_PAD_PREVIEW_DB_NAME|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::01_floorplan.config.tcl::IO_BOND_PAD_PREVIEW_AFTER_DB_NAME|FILL_IN_setup_01_floorplan_config_tcl_IO_BOND_PAD_PREVIEW_AFTER_DB_NAME|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::01_floorplan.config.tcl::POWERPLAN_BOND_PAD_PREVIEW_DB_NAME|FILL_IN_setup_01_floorplan_config_tcl_POWERPLAN_BOND_PAD_PREVIEW_DB_NAME|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::01_floorplan.config.tcl::POWERPLAN_BOND_PAD_PREVIEW_AFTER_DB_NAME|FILL_IN_setup_01_floorplan_config_tcl_POWERPLAN_BOND_PAD_PREVIEW_AFTER_DB_NAME|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::01_floorplan.config.tcl::BOND_PAD_PREVIEW_SEARCH_PARITY|FILL_IN_setup_01_floorplan_config_tcl_BOND_PAD_PREVIEW_SEARCH_PARITY|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::01_floorplan.config.tcl::BOND_PAD_PREVIEW_STRICT_OVERLAP|FILL_IN_setup_01_floorplan_config_tcl_BOND_PAD_PREVIEW_STRICT_OVERLAP|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::01_floorplan.config.tcl::BOND_PAD_PREVIEW_SAVE_DB|FILL_IN_setup_01_floorplan_config_tcl_BOND_PAD_PREVIEW_SAVE_DB|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::01_floorplan.config.tcl::BOND_PAD_PARITY_FILE|FILL_IN_setup_01_floorplan_config_tcl_BOND_PAD_PARITY_FILE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::01_floorplan.config.tcl::BOND_PAD_PREVIEW_DB_NAME|FILL_IN_setup_01_floorplan_config_tcl_BOND_PAD_PREVIEW_DB_NAME|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::01_floorplan.config.tcl::BOND_PAD_ACCEPT_INTERNAL_MAXWIDTH|FILL_IN_setup_01_floorplan_config_tcl_BOND_PAD_ACCEPT_INTERNAL_MAXWIDTH|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::01_floorplan.config.tcl::INSERT_BOUNDARY_CELLS_AFTER_FLOORPLAN|FILL_IN_setup_01_floorplan_config_tcl_INSERT_BOUNDARY_CELLS_AFTER_FLOORPLAN|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::01_floorplan.config.tcl::ENDCAP_POWER_DOMAIN_LIST|FILL_IN_setup_01_floorplan_config_tcl_ENDCAP_POWER_DOMAIN_LIST|請填入endcap cell 或對應設定|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::01_floorplan.config.tcl::ENDCAP_DEFAULT_POWER_DOMAIN|FILL_IN_setup_01_floorplan_config_tcl_ENDCAP_DEFAULT_POWER_DOMAIN|請填入endcap cell 或對應設定|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::01_floorplan.config.tcl::ENDCAP_EXCLUDE_POWER_DOMAIN_PATTERNS|FILL_IN_setup_01_floorplan_config_tcl_ENDCAP_EXCLUDE_POWER_DOMAIN_PATTERNS|請填入endcap cell 或對應設定|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::01_floorplan.config.tcl::ENDCAP_GLOBAL_PREFIX|FILL_IN_setup_01_floorplan_config_tcl_ENDCAP_GLOBAL_PREFIX|請填入endcap cell 或對應設定|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::01_floorplan.config.tcl::ENDCAP_POWER_DOMAIN_PREFIX|FILL_IN_setup_01_floorplan_config_tcl_ENDCAP_POWER_DOMAIN_PREFIX|請填入endcap cell 或對應設定|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::01_floorplan.config.tcl::DEFER_WELL_TAP_TO_POST_POWERPLAN|FILL_IN_setup_01_floorplan_config_tcl_DEFER_WELL_TAP_TO_POST_POWERPLAN|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::01_floorplan.config.tcl::GACORE_SITE_NAME|FILL_IN_setup_01_floorplan_config_tcl_GACORE_SITE_NAME|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::01_floorplan.config.tcl::ENDCAP_LEFT_EDGE_CELLS|FILL_IN_setup_01_floorplan_config_tcl_ENDCAP_LEFT_EDGE_CELLS|請填入endcap cell 或對應設定|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::01_floorplan.config.tcl::ENDCAP_RIGHT_EDGE_CELLS|FILL_IN_setup_01_floorplan_config_tcl_ENDCAP_RIGHT_EDGE_CELLS|請填入endcap cell 或對應設定|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::01_floorplan.config.tcl::ENDCAP_LEFT_TOP_CORNER_CELLS|FILL_IN_setup_01_floorplan_config_tcl_ENDCAP_LEFT_TOP_CORNER_CELLS|請填入endcap cell 或對應設定|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::01_floorplan.config.tcl::ENDCAP_LEFT_BOTTOM_CORNER_CELLS|FILL_IN_setup_01_floorplan_config_tcl_ENDCAP_LEFT_BOTTOM_CORNER_CELLS|請填入endcap cell 或對應設定|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::01_floorplan.config.tcl::ENDCAP_TOP_EDGE_CELLS|FILL_IN_setup_01_floorplan_config_tcl_ENDCAP_TOP_EDGE_CELLS|請填入endcap cell 或對應設定|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::01_floorplan.config.tcl::ENDCAP_BOTTOM_EDGE_CELLS|FILL_IN_setup_01_floorplan_config_tcl_ENDCAP_BOTTOM_EDGE_CELLS|請填入endcap cell 或對應設定|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::01_floorplan.config.tcl::ENDCAP_CORNER_FILL_CELLS|FILL_IN_setup_01_floorplan_config_tcl_ENDCAP_CORNER_FILL_CELLS|請填入endcap cell 或對應設定|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::01_floorplan.config.tcl::ENDCAP_TOP_TAP_CELLS|FILL_IN_setup_01_floorplan_config_tcl_ENDCAP_TOP_TAP_CELLS|請填入endcap cell 或對應設定|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::01_floorplan.config.tcl::ENDCAP_BOTTOM_TAP_CELLS|FILL_IN_setup_01_floorplan_config_tcl_ENDCAP_BOTTOM_TAP_CELLS|請填入endcap cell 或對應設定|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::01_floorplan.config.tcl::ENDCAP_WELL_TAP_RULE|FILL_IN_setup_01_floorplan_config_tcl_ENDCAP_WELL_TAP_RULE|請填入endcap cell 或對應設定|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::01_floorplan.config.tcl::POWER_SWITCH_INSERTION_MODE|FILL_IN_setup_01_floorplan_config_tcl_POWER_SWITCH_INSERTION_MODE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::01_floorplan.config.tcl::POWER_SWITCH_INSTANCE_PREFIXES|FILL_IN_setup_01_floorplan_config_tcl_POWER_SWITCH_INSTANCE_PREFIXES|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::01_floorplan.config.tcl::POWER_SWITCH_LEFT_OFFSET|FILL_IN_setup_01_floorplan_config_tcl_POWER_SWITCH_LEFT_OFFSET|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::01_floorplan.config.tcl::POWER_SWITCH_RIGHT_OFFSET|FILL_IN_setup_01_floorplan_config_tcl_POWER_SWITCH_RIGHT_OFFSET|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::01_floorplan.config.tcl::POWER_SWITCH_TOP_OFFSET|FILL_IN_setup_01_floorplan_config_tcl_POWER_SWITCH_TOP_OFFSET|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::01_floorplan.config.tcl::POWER_SWITCH_BOTTOM_OFFSET|FILL_IN_setup_01_floorplan_config_tcl_POWER_SWITCH_BOTTOM_OFFSET|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::01_floorplan.config.tcl::POWER_SWITCH_EDGE_REINFORCE_GAP|FILL_IN_setup_01_floorplan_config_tcl_POWER_SWITCH_EDGE_REINFORCE_GAP|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::01_floorplan.config.tcl::POWER_SWITCH_ENDCAP_OVERLAP_AUTO_DELETE|FILL_IN_setup_01_floorplan_config_tcl_POWER_SWITCH_ENDCAP_OVERLAP_AUTO_DELETE|請填入endcap cell 或對應設定|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::01_floorplan.config.tcl::POWER_SWITCH_ENDCAP_OVERLAP_SAVE_DB|FILL_IN_setup_01_floorplan_config_tcl_POWER_SWITCH_ENDCAP_OVERLAP_SAVE_DB|請填入endcap cell 或對應設定|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::01_floorplan.config.tcl::ENDCAP_POST_INSERT_RUN_CHECKS|FILL_IN_setup_01_floorplan_config_tcl_ENDCAP_POST_INSERT_RUN_CHECKS|請填入endcap cell 或對應設定|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::01_floorplan.config.tcl::ENDCAP_POST_INSERT_SAVE_DB|FILL_IN_setup_01_floorplan_config_tcl_ENDCAP_POST_INSERT_SAVE_DB|請填入endcap cell 或對應設定|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::02_powerplan.config.tcl::PNS_AUTO_RUN_ON_SOURCE|FILL_IN_setup_02_powerplan_config_tcl_PNS_AUTO_RUN_ON_SOURCE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::02_powerplan.config.tcl::POWERPLAN_PAD_PIN_LAYER_CHANGE_RANGE|FILL_IN_setup_02_powerplan_config_tcl_POWERPLAN_PAD_PIN_LAYER_CHANGE_RANGE|請填入 library pin 名稱或接腳對應 dict|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::02_powerplan.config.tcl::POWERPLAN_PAD_PIN_LAYER_RANGE|FILL_IN_setup_02_powerplan_config_tcl_POWERPLAN_PAD_PIN_LAYER_RANGE|請填入 library pin 名稱或接腳對應 dict|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::02_powerplan.config.tcl::POWERPLAN_PAD_PIN_BLOCKAGE_LAYERS|FILL_IN_setup_02_powerplan_config_tcl_POWERPLAN_PAD_PIN_BLOCKAGE_LAYERS|請填入 library pin 名稱或接腳對應 dict|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::02_powerplan.config.tcl::POWERPLAN_PAD_PIN_BLOCKAGE_INNER_OFFSET|FILL_IN_setup_02_powerplan_config_tcl_POWERPLAN_PAD_PIN_BLOCKAGE_INNER_OFFSET|請填入 library pin 名稱或接腳對應 dict|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::02_powerplan.config.tcl::POWERPLAN_PAD_PIN_BLOCKAGE_OUTER_OFFSET|FILL_IN_setup_02_powerplan_config_tcl_POWERPLAN_PAD_PIN_BLOCKAGE_OUTER_OFFSET|請填入 library pin 名稱或接腳對應 dict|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::02_powerplan.config.tcl::POWERPLAN_PAD_PIN_BLOCKAGE_CORE_GAP|FILL_IN_setup_02_powerplan_config_tcl_POWERPLAN_PAD_PIN_BLOCKAGE_CORE_GAP|請填入 library pin 名稱或接腳對應 dict|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::02_powerplan.config.tcl::POWERPLAN_PAD_CELL_PATTERN|FILL_IN_setup_02_powerplan_config_tcl_POWERPLAN_PAD_CELL_PATTERN|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::02_powerplan.config.tcl::POWERPLAN_MACRO_PG_BLOCKAGE_LAYERS|FILL_IN_setup_02_powerplan_config_tcl_POWERPLAN_MACRO_PG_BLOCKAGE_LAYERS|請填入 PDK 層名或層範圍|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::02_powerplan.config.tcl::POWERPLAN_FLOATING_STRIPE_LAYER_CHANGE_RANGE|FILL_IN_setup_02_powerplan_config_tcl_POWERPLAN_FLOATING_STRIPE_LAYER_CHANGE_RANGE|請填入 PDK 層名或層範圍|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::02_powerplan.config.tcl::POWERPLAN_FOLLOW_PIN_LAYER_CHANGE_RANGE|FILL_IN_setup_02_powerplan_config_tcl_POWERPLAN_FOLLOW_PIN_LAYER_CHANGE_RANGE|請填入 library pin 名稱或接腳對應 dict|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::02_powerplan.config.tcl::POWERPLAN_FOLLOW_PIN_CORE_PIN_LAYER|FILL_IN_setup_02_powerplan_config_tcl_POWERPLAN_FOLLOW_PIN_CORE_PIN_LAYER|請填入 library pin 名稱或接腳對應 dict|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::02_powerplan.config.tcl::PNS_CORE_RING_1|FILL_IN_setup_02_powerplan_config_tcl_PNS_CORE_RING_1|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::02_powerplan.config.tcl::PNS_CORE_RING_2|FILL_IN_setup_02_powerplan_config_tcl_PNS_CORE_RING_2|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::02_powerplan.config.tcl::PNS_CORE_RING_3|FILL_IN_setup_02_powerplan_config_tcl_PNS_CORE_RING_3|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::02_powerplan.config.tcl::PNS_PAD_PIN_LAYER_CHANGE_RANGE|FILL_IN_setup_02_powerplan_config_tcl_PNS_PAD_PIN_LAYER_CHANGE_RANGE|請填入 library pin 名稱或接腳對應 dict|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::02_powerplan.config.tcl::PNS_PAD_PIN_LAYER_RANGE|FILL_IN_setup_02_powerplan_config_tcl_PNS_PAD_PIN_LAYER_RANGE|請填入 library pin 名稱或接腳對應 dict|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::02_powerplan.config.tcl::PNS_MACRO_BLOCKAGE_LAYERS|FILL_IN_setup_02_powerplan_config_tcl_PNS_MACRO_BLOCKAGE_LAYERS|請填入 PDK 層名或層範圍|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::02_powerplan.config.tcl::PNS_MACRO_BLOCKAGE_CLEARANCE|FILL_IN_setup_02_powerplan_config_tcl_PNS_MACRO_BLOCKAGE_CLEARANCE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::02_powerplan.config.tcl::PNS_M9_ALL_STRIPE|FILL_IN_setup_02_powerplan_config_tcl_PNS_M9_ALL_STRIPE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::02_powerplan.config.tcl::PNS_M8_GROUND_STRIPE|FILL_IN_setup_02_powerplan_config_tcl_PNS_M8_GROUND_STRIPE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::02_powerplan.config.tcl::PNS_M8_POWER_STRIPE|FILL_IN_setup_02_powerplan_config_tcl_PNS_M8_POWER_STRIPE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::02_powerplan.config.tcl::PNS_M7_GROUND_STRIPE|FILL_IN_setup_02_powerplan_config_tcl_PNS_M7_GROUND_STRIPE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::02_powerplan.config.tcl::PNS_M7_POWER_STRIPE|FILL_IN_setup_02_powerplan_config_tcl_PNS_M7_POWER_STRIPE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::02_powerplan.config.tcl::PNS_M6_GROUND_STRIPE|FILL_IN_setup_02_powerplan_config_tcl_PNS_M6_GROUND_STRIPE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::02_powerplan.config.tcl::PNS_M6_POWER_STRIPE|FILL_IN_setup_02_powerplan_config_tcl_PNS_M6_POWER_STRIPE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::02_powerplan.config.tcl::PNS_M5_GROUND_STRIPE|FILL_IN_setup_02_powerplan_config_tcl_PNS_M5_GROUND_STRIPE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::02_powerplan.config.tcl::PNS_M5_POWER_STRIPE|FILL_IN_setup_02_powerplan_config_tcl_PNS_M5_POWER_STRIPE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::02_powerplan.config.tcl::PNS_FOLLOW_PIN_LAYER_CHANGE_RANGE|FILL_IN_setup_02_powerplan_config_tcl_PNS_FOLLOW_PIN_LAYER_CHANGE_RANGE|請填入 library pin 名稱或接腳對應 dict|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::02_powerplan.config.tcl::PNS_FOLLOW_PIN_VIA_SCALE_HEIGHT|FILL_IN_setup_02_powerplan_config_tcl_PNS_FOLLOW_PIN_VIA_SCALE_HEIGHT|請填入 library pin 名稱或接腳對應 dict|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::02_powerplan.config.tcl::PNS_FOLLOW_PIN_VIA_SCALE_WIDTH|FILL_IN_setup_02_powerplan_config_tcl_PNS_FOLLOW_PIN_VIA_SCALE_WIDTH|請填入 library pin 名稱或接腳對應 dict|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::02_powerplan.config.tcl::PNS_M2_POWER_RAIL|FILL_IN_setup_02_powerplan_config_tcl_PNS_M2_POWER_RAIL|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::02_powerplan.config.tcl::PNS_M2_GROUND_RAIL|FILL_IN_setup_02_powerplan_config_tcl_PNS_M2_GROUND_RAIL|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::02_powerplan.config.tcl::POWER_SWITCH_DESIGN_MAP|FILL_IN_setup_02_powerplan_config_tcl_POWER_SWITCH_DESIGN_MAP|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::02_powerplan.config.tcl::POWER_SWITCH_HORIZONTAL_PITCH|FILL_IN_setup_02_powerplan_config_tcl_POWER_SWITCH_HORIZONTAL_PITCH|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::02_powerplan.config.tcl::PNS_STRIPE_SPACING_FROM_BLOCK|FILL_IN_setup_02_powerplan_config_tcl_PNS_STRIPE_SPACING_FROM_BLOCK|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::02_powerplan.config.tcl::PNS_STRIPE_MAX_SAME_LAYER_JOG_LENGTH|FILL_IN_setup_02_powerplan_config_tcl_PNS_STRIPE_MAX_SAME_LAYER_JOG_LENGTH|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::02_powerplan.config.tcl::PNS_STD_REGION_Y_EXPANSION|FILL_IN_setup_02_powerplan_config_tcl_PNS_STD_REGION_Y_EXPANSION|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::02_powerplan.config.tcl::PNS_RING_THRESHOLD|FILL_IN_setup_02_powerplan_config_tcl_PNS_RING_THRESHOLD|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::02_powerplan.config.tcl::PNS_RING_JOG_DISTANCE|FILL_IN_setup_02_powerplan_config_tcl_PNS_RING_JOG_DISTANCE|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::02_powerplan.config.tcl::PNS_MACRO_RING_WIDTH|FILL_IN_setup_02_powerplan_config_tcl_PNS_MACRO_RING_WIDTH|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::02_powerplan.config.tcl::PNS_MACRO_RING_SPACING|FILL_IN_setup_02_powerplan_config_tcl_PNS_MACRO_RING_SPACING|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::02_powerplan.config.tcl::PNS_MACRO_RING_OFFSET|FILL_IN_setup_02_powerplan_config_tcl_PNS_MACRO_RING_OFFSET|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::05_route.config.tcl::ROUTE_TOP_ROUTING_LAYER|FILL_IN_setup_05_route_config_tcl_ROUTE_TOP_ROUTING_LAYER|請填入 PDK 層名或層範圍|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::05_route.config.tcl::ROUTE_BOTTOM_ROUTING_LAYER|FILL_IN_setup_05_route_config_tcl_ROUTE_BOTTOM_ROUTING_LAYER|請填入 PDK 層名或層範圍|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::05_route.config.tcl::INST_PADDING_ERROR_TYPES|FILL_IN_setup_05_route_config_tcl_INST_PADDING_ERROR_TYPES|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::05_route.config.tcl::INST_PADDING_LEFT|FILL_IN_setup_05_route_config_tcl_INST_PADDING_LEFT|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::05_route.config.tcl::INST_PADDING_RIGHT|FILL_IN_setup_05_route_config_tcl_INST_PADDING_RIGHT|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::06_finish.config.tcl::FILLER_NO_SINGLE_SITE_GAP|FILL_IN_setup_06_finish_config_tcl_FILLER_NO_SINGLE_SITE_GAP|請填入filler cell 或對應設定|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::06_finish.config.tcl::FILLER_CELLS|FILL_IN_setup_06_finish_config_tcl_FILLER_CELLS|請填入filler cell 或對應設定|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::06_finish.config.tcl::STREAM_OUT_TEXT_SIZE|FILL_IN_setup_06_finish_config_tcl_STREAM_OUT_TEXT_SIZE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::06_finish.config.tcl::STREAM_OUT_LIB_NAME|FILL_IN_setup_06_finish_config_tcl_STREAM_OUT_LIB_NAME|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::06_finish.config.tcl::STREAM_OUT_UNIT|FILL_IN_setup_06_finish_config_tcl_STREAM_OUT_UNIT|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::06_finish.config.tcl::STREAM_OUT_MODE|FILL_IN_setup_06_finish_config_tcl_STREAM_OUT_MODE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::06_finish.config.tcl::STREAM_OUT_CUSTOM_MAP_LINES|FILL_IN_setup_06_finish_config_tcl_STREAM_OUT_CUSTOM_MAP_LINES|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|library::TECH_EXPORT_DECAP_MASTER_PATTERN|FILL_IN_library_TECH_EXPORT_DECAP_MASTER_PATTERN|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/.private_config/TECH_MV/setup_commands.tcl|library::TECH_EXPORT_POWERPAD_MASTER_PATTERN|FILL_IN_library_TECH_EXPORT_POWERPAD_MASTER_PATTERN|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/.private_config/TECH_MV/setup_commands.tcl|library::TECH_EXPORT_FILLER_MASTER_PATTERN|FILL_IN_library_TECH_EXPORT_FILLER_MASTER_PATTERN|請填入filler cell 或對應設定|
|baseline/.private_config/TECH_MV/setup_commands.tcl|library::TECH_EXPORT_PFILLER_MASTER_PATTERN|FILL_IN_library_TECH_EXPORT_PFILLER_MASTER_PATTERN|請填入filler cell 或對應設定|
|baseline/.private_config/TECH_MV/setup_commands.tcl|library::TECH_EXPORT_PCORNER_MASTER_PATTERN|FILL_IN_library_TECH_EXPORT_PCORNER_MASTER_PATTERN|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::01_floorplan.config.tcl::IOPAD_RING_NAME|FILL_IN_setup_01_floorplan_config_tcl_IOPAD_RING_NAME|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::01_floorplan.config.tcl::IOPAD_RING_COMMON_GROUND|FILL_IN_setup_01_floorplan_config_tcl_IOPAD_RING_COMMON_GROUND|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::01_floorplan.config.tcl::IOPAD_RING_DIRECTION|FILL_IN_setup_01_floorplan_config_tcl_IOPAD_RING_DIRECTION|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::01_floorplan.config.tcl::IOPAD_RING_DOMAIN_CONFIG|FILL_IN_setup_01_floorplan_config_tcl_IOPAD_RING_DOMAIN_CONFIG|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::01_floorplan.config.tcl::IOPAD_RING_CREATE_MISSING_PADS|FILL_IN_setup_01_floorplan_config_tcl_IOPAD_RING_CREATE_MISSING_PADS|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::01_floorplan.config.tcl::IOPAD_RING_CREATE_CUTS|FILL_IN_setup_01_floorplan_config_tcl_IOPAD_RING_CREATE_CUTS|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::01_floorplan.config.tcl::IOPAD_RING_CUT_PREFIX|FILL_IN_setup_01_floorplan_config_tcl_IOPAD_RING_CUT_PREFIX|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::01_floorplan.config.tcl::IOPAD_RING_CUT_BASE_VERTICAL|FILL_IN_setup_01_floorplan_config_tcl_IOPAD_RING_CUT_BASE_VERTICAL|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::01_floorplan.config.tcl::IOPAD_RING_CUT_BASE_HORIZONTAL|FILL_IN_setup_01_floorplan_config_tcl_IOPAD_RING_CUT_BASE_HORIZONTAL|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::01_floorplan.config.tcl::IOPAD_RING_STRICT|FILL_IN_setup_01_floorplan_config_tcl_IOPAD_RING_STRICT|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::02_powerplan.config.tcl::POWERPLAN_CORE_RING_LOWER|FILL_IN_setup_02_powerplan_config_tcl_POWERPLAN_CORE_RING_LOWER|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::02_powerplan.config.tcl::POWERPLAN_CORE_RING_UPPER|FILL_IN_setup_02_powerplan_config_tcl_POWERPLAN_CORE_RING_UPPER|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::02_powerplan.config.tcl::POWERPLAN_PD_TOP_RING_DOMAIN|FILL_IN_setup_02_powerplan_config_tcl_POWERPLAN_PD_TOP_RING_DOMAIN|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::02_powerplan.config.tcl::POWERPLAN_PD_BLOCK_RING_DOMAINS|FILL_IN_setup_02_powerplan_config_tcl_POWERPLAN_PD_BLOCK_RING_DOMAINS|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::02_powerplan.config.tcl::POWERPLAN_PD_RING_UPPER|FILL_IN_setup_02_powerplan_config_tcl_POWERPLAN_PD_RING_UPPER|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::02_powerplan.config.tcl::POWERPLAN_PD_RING_LOWER|FILL_IN_setup_02_powerplan_config_tcl_POWERPLAN_PD_RING_LOWER|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::02_powerplan.config.tcl::POWERPLAN_M9_ALL_STRIPE|FILL_IN_setup_02_powerplan_config_tcl_POWERPLAN_M9_ALL_STRIPE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::02_powerplan.config.tcl::POWERPLAN_M8_GROUND_STRIPE|FILL_IN_setup_02_powerplan_config_tcl_POWERPLAN_M8_GROUND_STRIPE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::02_powerplan.config.tcl::POWERPLAN_M8_POWER_STRIPE|FILL_IN_setup_02_powerplan_config_tcl_POWERPLAN_M8_POWER_STRIPE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::02_powerplan.config.tcl::POWERPLAN_M7_GROUND_STRIPE|FILL_IN_setup_02_powerplan_config_tcl_POWERPLAN_M7_GROUND_STRIPE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::02_powerplan.config.tcl::POWERPLAN_M7_POWER_STRIPE|FILL_IN_setup_02_powerplan_config_tcl_POWERPLAN_M7_POWER_STRIPE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::02_powerplan.config.tcl::POWERPLAN_M6_GROUND_STRIPE|FILL_IN_setup_02_powerplan_config_tcl_POWERPLAN_M6_GROUND_STRIPE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::02_powerplan.config.tcl::POWERPLAN_M6_POWER_STRIPE|FILL_IN_setup_02_powerplan_config_tcl_POWERPLAN_M6_POWER_STRIPE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::02_powerplan.config.tcl::POWERPLAN_M5_GROUND_STRIPE|FILL_IN_setup_02_powerplan_config_tcl_POWERPLAN_M5_GROUND_STRIPE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::02_powerplan.config.tcl::POWERPLAN_M5_POWER_STRIPE|FILL_IN_setup_02_powerplan_config_tcl_POWERPLAN_M5_POWER_STRIPE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::02_powerplan.config.tcl::POWERPLAN_FLOATING_STRIPE_TARGETS|FILL_IN_setup_02_powerplan_config_tcl_POWERPLAN_FLOATING_STRIPE_TARGETS|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::03_place.config.tcl::LS_PADDING_LEFT|FILL_IN_setup_03_place_config_tcl_LS_PADDING_LEFT|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::03_place.config.tcl::LS_PADDING_RIGHT|FILL_IN_setup_03_place_config_tcl_LS_PADDING_RIGHT|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::03_place.config.tcl::LS_PADDING_REPORT_LIMIT|FILL_IN_setup_03_place_config_tcl_LS_PADDING_REPORT_LIMIT|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::05_route.config.tcl::SECONDARY_PG_RAIL_LAYER|FILL_IN_setup_05_route_config_tcl_SECONDARY_PG_RAIL_LAYER|請填入 PDK 層名或層範圍|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::05_route.config.tcl::SECONDARY_PG_BOTTOM_LAYER|FILL_IN_setup_05_route_config_tcl_SECONDARY_PG_BOTTOM_LAYER|請填入 PDK 層名或層範圍|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::05_route.config.tcl::SECONDARY_PG_TOP_LAYER|FILL_IN_setup_05_route_config_tcl_SECONDARY_PG_TOP_LAYER|請填入 PDK 層名或層範圍|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::90_debug.config.tcl::TT_CP2_REPAIR_INCLUDE_ENDCAP|FILL_IN_setup_90_debug_config_tcl_TT_CP2_REPAIR_INCLUDE_ENDCAP|請填入endcap cell 或對應設定|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::90_debug.config.tcl::TT_CP2_REPAIR_MAX_CELLS|FILL_IN_setup_90_debug_config_tcl_TT_CP2_REPAIR_MAX_CELLS|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::90_debug.config.tcl::PD_ENDCAP_LEGALIZE_SITE|FILL_IN_setup_90_debug_config_tcl_PD_ENDCAP_LEGALIZE_SITE|請填入endcap cell 或對應設定|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::90_debug.config.tcl::PD_ENDCAP_LEGALIZE_TOL|FILL_IN_setup_90_debug_config_tcl_PD_ENDCAP_LEGALIZE_TOL|請填入endcap cell 或對應設定|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::90_debug.config.tcl::PD_ENDCAP_LEGALIZE_MAX_SHIFT|FILL_IN_setup_90_debug_config_tcl_PD_ENDCAP_LEGALIZE_MAX_SHIFT|請填入endcap cell 或對應設定|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::90_debug.config.tcl::TT_VIA_DRC_SUBTYPES|FILL_IN_setup_90_debug_config_tcl_TT_VIA_DRC_SUBTYPES|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::90_debug.config.tcl::TT_VIA_DRC_EQUAL_OVERLAP_RATIO|FILL_IN_setup_90_debug_config_tcl_TT_VIA_DRC_EQUAL_OVERLAP_RATIO|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::90_debug.config.tcl::CHECK_STAGE02_METAL_DENSITY_LAYERS|FILL_IN_setup_90_debug_config_tcl_CHECK_STAGE02_METAL_DENSITY_LAYERS|請填入 PDK 層名或層範圍|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::90_debug.config.tcl::CHECK_STAGE05_METAL_DENSITY_LAYERS|FILL_IN_setup_90_debug_config_tcl_CHECK_STAGE05_METAL_DENSITY_LAYERS|請填入 PDK 層名或層範圍|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::90_debug.config.tcl::CHECK_STAGE06_METAL_DENSITY_LAYERS|FILL_IN_setup_90_debug_config_tcl_CHECK_STAGE06_METAL_DENSITY_LAYERS|請填入 PDK 層名或層範圍|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::90_debug.config.tcl::METAL_DENSITY_LIMIT_TABLE|FILL_IN_setup_90_debug_config_tcl_METAL_DENSITY_LIMIT_TABLE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::00_design.config.tcl::POWER_PORT_NETS|FILL_IN_setup_00_design_config_tcl_POWER_PORT_NETS|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::00_design.config.tcl::POWER_NETS|FILL_IN_setup_00_design_config_tcl_POWER_NETS|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::00_design.config.tcl::GROUND_NET|FILL_IN_setup_00_design_config_tcl_GROUND_NET|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::00_design.config.tcl::PD_CFG|FILL_IN_setup_00_design_config_tcl_PD_CFG|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::01_floorplan.config.tcl::FLOORPLAN_DIE_SIZE|FILL_IN_setup_01_floorplan_config_tcl_FLOORPLAN_DIE_SIZE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::01_floorplan.config.tcl::FLOORPLAN_BOX_SIZE|FILL_IN_setup_01_floorplan_config_tcl_FLOORPLAN_BOX_SIZE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::01_floorplan.config.tcl::FLOORPLAN_BOUND_THRESHOLD|FILL_IN_setup_01_floorplan_config_tcl_FLOORPLAN_BOUND_THRESHOLD|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::01_floorplan.config.tcl::FLOORPLAN_BOUND_MARGIN|FILL_IN_setup_01_floorplan_config_tcl_FLOORPLAN_BOUND_MARGIN|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::01_floorplan.config.tcl::FLOORPLAN_CORE_DENSITY_ASPECT_RATIO|FILL_IN_setup_01_floorplan_config_tcl_FLOORPLAN_CORE_DENSITY_ASPECT_RATIO|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::01_floorplan.config.tcl::RTE_PAD_PIN|FILL_IN_setup_01_floorplan_config_tcl_RTE_PAD_PIN|請填入 library pin 名稱或接腳對應 dict|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::01_floorplan.config.tcl::RTE_PAD_BOND_ASSIGN_SUPPLIES|FILL_IN_setup_01_floorplan_config_tcl_RTE_PAD_BOND_ASSIGN_SUPPLIES|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::01_floorplan.config.tcl::POWER_DOMAIN_SCALE_CONFIG|FILL_IN_setup_01_floorplan_config_tcl_POWER_DOMAIN_SCALE_CONFIG|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::01_floorplan.config.tcl::POWER_DOMAIN_ASPECT_RATIO_CONFIG|FILL_IN_setup_01_floorplan_config_tcl_POWER_DOMAIN_ASPECT_RATIO_CONFIG|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::01_floorplan.config.tcl::MACRO_MIN_SPACE_TO_CORE|FILL_IN_setup_01_floorplan_config_tcl_MACRO_MIN_SPACE_TO_CORE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::01_floorplan.config.tcl::MACRO_MIN_SPACE_TO_MACRO|FILL_IN_setup_01_floorplan_config_tcl_MACRO_MIN_SPACE_TO_MACRO|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::01_floorplan.config.tcl::MACRO_H_SPACE|FILL_IN_setup_01_floorplan_config_tcl_MACRO_H_SPACE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::01_floorplan.config.tcl::MACRO_V_SPACE|FILL_IN_setup_01_floorplan_config_tcl_MACRO_V_SPACE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::02_powerplan.config.tcl::POWERPLAN_PAD_PIN_PORT_CONNECT|FILL_IN_setup_02_powerplan_config_tcl_POWERPLAN_PAD_PIN_PORT_CONNECT|請填入 library pin 名稱或接腳對應 dict|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::02_powerplan.config.tcl::POWERPLAN_PAD_PIN_BLOCKAGE_NAME|FILL_IN_setup_02_powerplan_config_tcl_POWERPLAN_PAD_PIN_BLOCKAGE_NAME|請填入 library pin 名稱或接腳對應 dict|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::02_powerplan.config.tcl::POWERPLAN_MACRO_PG_BLOCKAGE_CLEARANCE|FILL_IN_setup_02_powerplan_config_tcl_POWERPLAN_MACRO_PG_BLOCKAGE_CLEARANCE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|setup::02_powerplan.config.tcl::POWERPLAN_FOLLOW_PIN_TARGET|FILL_IN_setup_02_powerplan_config_tcl_POWERPLAN_FOLLOW_PIN_TARGET|請填入 library pin 名稱或接腳對應 dict|
|baseline/.private_config/TECH_MV/setup_commands.tcl|library::TECH_CTS_BUFFER_MASTER_LIST|FILL_IN_library_TECH_CTS_BUFFER_MASTER_LIST|請填入clock buffer cell 或對應設定|
|baseline/.private_config/TECH_MV/setup_commands.tcl|library::TECH_CTS_INVERTER_MASTER_LIST|FILL_IN_library_TECH_CTS_INVERTER_MASTER_LIST|請填入clock inverter cell 或對應設定|
|baseline/.private_config/TECH_MV/setup_commands.tcl|library::TECH_CTS_CLOCK_GATING_MASTER_LIST|FILL_IN_library_TECH_CTS_CLOCK_GATING_MASTER_LIST|請填入ICG cell 或對應設定|
|baseline/.private_config/TECH_MV/setup_commands.tcl|cts::TECH_CTS_NDR_WIDTH_L12|FILL_IN_cts_TECH_CTS_NDR_WIDTH_L12|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/.private_config/TECH_MV/setup_commands.tcl|cts::TECH_CTS_NDR_SPACING_L12|FILL_IN_cts_TECH_CTS_NDR_SPACING_L12|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/.private_config/TECH_MV/setup_commands.tcl|cts::TECH_CTS_NDR_WIDTH_L15|FILL_IN_cts_TECH_CTS_NDR_WIDTH_L15|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/.private_config/TECH_MV/setup_commands.tcl|cts::TECH_CTS_NDR_SPACING_L15|FILL_IN_cts_TECH_CTS_NDR_SPACING_L15|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/.private_config/TECH_MV/setup_commands.tcl|cts::TECH_CTS_NDR_WIDTH_L19|FILL_IN_cts_TECH_CTS_NDR_WIDTH_L19|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/.private_config/TECH_MV/setup_commands.tcl|cts::TECH_CTS_NDR_SPACING_L19|FILL_IN_cts_TECH_CTS_NDR_SPACING_L19|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/.private_config/TECH_MV/setup_commands.tcl|cts::TECH_CTS_NDR_WIDTH_L22|FILL_IN_cts_TECH_CTS_NDR_WIDTH_L22|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/.private_config/TECH_MV/setup_commands.tcl|cts::TECH_CTS_NDR_SPACING_L22|FILL_IN_cts_TECH_CTS_NDR_SPACING_L22|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/.private_config/TECH_MV/setup_commands.tcl|library_value::LIB_QUERY_001|FILL_IN_library_value_LIB_QUERY_001|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/.private_config/TECH_MV/setup_commands.tcl|library_value::LIB_PIN_001|FILL_IN_library_value_LIB_PIN_001|請填入 library pin 名稱或接腳對應 dict|
|baseline/.private_config/TECH_MV/setup_commands.tcl|library_value::LIB_TECH_001|FILL_IN_library_value_LIB_TECH_001|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/.private_config/TECH_MV/setup_commands.tcl|library_value::LIB_PIN_002|FILL_IN_library_value_LIB_PIN_002|請填入 library pin 名稱或接腳對應 dict|
|baseline/.private_config/TECH_MV/setup_commands.tcl|library_value::LIB_CELL_001|FILL_IN_library_value_LIB_CELL_001|請填入boundary／endcap cell／cell 清單|
|baseline/.private_config/TECH_MV/setup_commands.tcl|library_value::LIB_CELL_002|FILL_IN_library_value_LIB_CELL_002|請填入well tap cell／cell 清單|
|baseline/.private_config/TECH_MV/setup_commands.tcl|library_value::LIB_CELL_003|FILL_IN_library_value_LIB_CELL_003|請填入header power switch cell／cell 清單|
|baseline/.private_config/TECH_MV/setup_commands.tcl|library_value::LIB_CELL_004|FILL_IN_library_value_LIB_CELL_004|請填入I/O pad、power pad、rail cut 與 corner cell／cell 清單|
|baseline/.private_config/TECH_MV/setup_commands.tcl|library_value::LIB_MATCH_001|FILL_IN_library_value_LIB_MATCH_001|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/.private_config/TECH_MV/setup_commands.tcl|library_value::LIB_TECH_002|FILL_IN_library_value_LIB_TECH_002|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/.private_config/TECH_MV/setup_commands.tcl|library_value::LIB_MATCH_002|FILL_IN_library_value_LIB_MATCH_002|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/.private_config/TECH_MV/setup_commands.tcl|library_value::LIB_TEXT_001|FILL_IN_library_value_LIB_TEXT_001|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/.private_config/TECH_MV/setup_commands.tcl|library_value::LIB_TEXT_002|FILL_IN_library_value_LIB_TEXT_002|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/.private_config/TECH_MV/setup_commands.tcl|library_value::LIB_TEXT_003|FILL_IN_library_value_LIB_TEXT_003|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/.private_config/TECH_MV/setup_commands.tcl|library_value::LIB_TEXT_004|FILL_IN_library_value_LIB_TEXT_004|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/.private_config/TECH_MV/setup_commands.tcl|library_value::LIB_CELL_005|FILL_IN_library_value_LIB_CELL_005|請填入boundary／endcap cell／cell 清單|
|baseline/.private_config/TECH_MV/setup_commands.tcl|library_value::LIB_MATCH_003|FILL_IN_library_value_LIB_MATCH_003|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/.private_config/TECH_MV/setup_commands.tcl|library_value::LIB_TEXT_005|FILL_IN_library_value_LIB_TEXT_005|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/.private_config/TECH_MV/setup_commands.tcl|library_value::LIB_CELL_006|FILL_IN_library_value_LIB_CELL_006|請填入I/O filler cell／cell 清單|
|baseline/.private_config/TECH_MV/setup_commands.tcl|library_value::LIB_CELL_007|FILL_IN_library_value_LIB_CELL_007|請填入I/O filler cell／cell 清單|
|baseline/.private_config/TECH_MV/setup_commands.tcl|library_value::LIB_CELL_008|FILL_IN_library_value_LIB_CELL_008|請填入I/O filler cell／cell 清單|
|baseline/.private_config/TECH_MV/setup_commands.tcl|library_value::LIB_CELL_009|FILL_IN_library_value_LIB_CELL_009|請填入I/O filler cell／cell 清單|
|baseline/.private_config/TECH_MV/setup_commands.tcl|library_value::LIB_CELL_010|FILL_IN_library_value_LIB_CELL_010|請填入右側 boundary／endcap cell／cell 清單|
|baseline/.private_config/TECH_MV/setup_commands.tcl|library_value::LIB_CELL_011|FILL_IN_library_value_LIB_CELL_011|請填入左側 boundary／endcap cell／cell 清單|
|baseline/.private_config/TECH_MV/setup_commands.tcl|library_value::LIB_QUERY_002|FILL_IN_library_value_LIB_QUERY_002|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/.private_config/TECH_MV/setup_commands.tcl|library_value::LIB_PIN_003|FILL_IN_library_value_LIB_PIN_003|請填入 library pin 名稱或接腳對應 dict|
|baseline/.private_config/TECH_MV/setup_commands.tcl|library_value::LIB_PIN_004|FILL_IN_library_value_LIB_PIN_004|請填入 library pin 名稱或接腳對應 dict|
|baseline/.private_config/TECH_MV/setup_commands.tcl|library_value::LIB_PIN_005|FILL_IN_library_value_LIB_PIN_005|請填入 library pin 名稱或接腳對應 dict|
|baseline/.private_config/TECH_MV/setup_commands.tcl|library_value::LIB_PIN_006|FILL_IN_library_value_LIB_PIN_006|請填入 library pin 名稱或接腳對應 dict|
|baseline/.private_config/TECH_MV/setup_commands.tcl|library_value::LIB_PIN_007|FILL_IN_library_value_LIB_PIN_007|請填入 library pin 名稱或接腳對應 dict|
|baseline/.private_config/TECH_MV/setup_commands.tcl|library_value::LIB_PIN_008|FILL_IN_library_value_LIB_PIN_008|請填入 library pin 名稱或接腳對應 dict|
|baseline/.private_config/TECH_MV/setup_commands.tcl|library_value::LIB_PIN_009|FILL_IN_library_value_LIB_PIN_009|請填入 library pin 名稱或接腳對應 dict|
|baseline/.private_config/TECH_MV/setup_commands.tcl|library_value::LIB_TECH_003|FILL_IN_library_value_LIB_TECH_003|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/.private_config/TECH_MV/setup_commands.tcl|library_value::LIB_TEXT_006|FILL_IN_library_value_LIB_TEXT_006|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/.private_config/TECH_MV/setup_commands.tcl|library_value::LIB_TEXT_007|FILL_IN_library_value_LIB_TEXT_007|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/.private_config/TECH_MV/setup_commands.tcl|library_value::LIB_TEXT_008|FILL_IN_library_value_LIB_TEXT_008|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/.private_config/TECH_MV/setup_commands.tcl|library_value::LIB_TEXT_009|FILL_IN_library_value_LIB_TEXT_009|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/.private_config/TECH_MV/setup_commands.tcl|library_value::LIB_TEXT_010|FILL_IN_library_value_LIB_TEXT_010|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/.private_config/TECH_MV/setup_commands.tcl|library_value::LIB_TEXT_011|FILL_IN_library_value_LIB_TEXT_011|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/.private_config/TECH_MV/setup_commands.tcl|library_value::LIB_TEXT_012|FILL_IN_library_value_LIB_TEXT_012|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/.private_config/TECH_MV/setup_commands.tcl|library_value::LIB_TEXT_013|FILL_IN_library_value_LIB_TEXT_013|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/.private_config/TECH_MV/setup_commands.tcl|library_value::LIB_TEXT_014|FILL_IN_library_value_LIB_TEXT_014|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/.private_config/TECH_MV/setup_commands.tcl|library_value::LIB_TEXT_015|FILL_IN_library_value_LIB_TEXT_015|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/.private_config/TECH_MV/setup_commands.tcl|library_value::LIB_TECH_004|FILL_IN_library_value_LIB_TECH_004|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/.private_config/TECH_MV/setup_commands.tcl|library_value::LIB_TEXT_016|FILL_IN_library_value_LIB_TEXT_016|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/.private_config/TECH_MV/setup_commands.tcl|library_value::LIB_TEXT_017|FILL_IN_library_value_LIB_TEXT_017|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/.private_config/TECH_MV/setup_commands.tcl|library_value::LIB_TECH_005|FILL_IN_library_value_LIB_TECH_005|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/.private_config/TECH_MV/setup_commands.tcl|library_value::LIB_TECH_006|FILL_IN_library_value_LIB_TECH_006|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/.private_config/TECH_MV/setup_commands.tcl|library_value::LIB_TECH_007|FILL_IN_library_value_LIB_TECH_007|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/.private_config/TECH_MV/setup_commands.tcl|library_value::LIB_TECH_008|FILL_IN_library_value_LIB_TECH_008|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/.private_config/TECH_MV/setup_commands.tcl|library_value::LIB_TEXT_018|FILL_IN_library_value_LIB_TEXT_018|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/.private_config/TECH_MV/setup_commands.tcl|library_value::LIB_TEXT_019|FILL_IN_library_value_LIB_TEXT_019|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/.private_config/TECH_MV/setup_commands.tcl|library_value::LP_PIN_SECONDARY_A|FILL_IN_library_value_LP_PIN_SECONDARY_A|請填入 library pin 名稱或接腳對應 dict|
|baseline/.private_config/TECH_MV/setup_commands.tcl|library_value::LP_PIN_SECONDARY_B|FILL_IN_library_value_LP_PIN_SECONDARY_B|請填入 library pin 名稱或接腳對應 dict|
|baseline/.private_config/TECH_MV/setup_commands.tcl|library_value::LP_PIN_RETENTION_AON|FILL_IN_library_value_LP_PIN_RETENTION_AON|請填入 library pin 名稱或接腳對應 dict|
|baseline/.private_config/TECH_MV/setup_commands.tcl|library_value::PG_LIBRARY_POWER_PIN_VALUES|FILL_IN_library_value_PG_LIBRARY_POWER_PIN_VALUES|請填入 library pin 名稱或接腳對應 dict|
|baseline/.private_config/TECH_MV/setup_commands.tcl|library_value::PG_LIBRARY_GROUND_PINS|FILL_IN_library_value_PG_LIBRARY_GROUND_PINS|請填入 library pin 名稱或接腳對應 dict|
|baseline/.private_config/TECH_MV/setup_commands.tcl|library_value::SW_LANDING_TARGET_INSTANCE|FILL_IN_library_value_SW_LANDING_TARGET_INSTANCE|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/.private_config/TECH_MV/setup_commands.tcl|library_value::SW_LANDING_TARGET_NET|FILL_IN_library_value_SW_LANDING_TARGET_NET|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/.private_config/TECH_MV/setup_commands.tcl|library_value::SW_LANDING_PG_PIN_PATTERN|FILL_IN_library_value_SW_LANDING_PG_PIN_PATTERN|請填入 library pin 名稱或接腳對應 dict|
|baseline/.private_config/TECH_MV/setup_commands.tcl|library_value::SW_LANDING_INSTANCE_PATTERN|FILL_IN_library_value_SW_LANDING_INSTANCE_PATTERN|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/.private_config/TECH_MV/setup_commands.tcl|library_value::SW_LANDING_POWER_PIN|FILL_IN_library_value_SW_LANDING_POWER_PIN|請填入 library pin 名稱或接腳對應 dict|
|baseline/.private_config/TECH_MV/setup_commands.tcl|library_value::SW_GATE_NET_ISSUE_PATTERN|FILL_IN_library_value_SW_GATE_NET_ISSUE_PATTERN|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/.private_config/TECH_MV/setup_commands.tcl|library::FILLER_FLOW_CELLS|FILL_IN_library_FILLER_FLOW_CELLS|請填入filler cell 或對應設定|
|baseline/.private_config/TECH_MV/setup_commands.tcl|early_rail::ERA_ARGS_01|FILL_IN_early_rail_ERA_ARGS_01|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|early_rail::ERA_ARGS_02|FILL_IN_early_rail_ERA_ARGS_02|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|early_rail::ERA_ARGS_03|FILL_IN_early_rail_ERA_ARGS_03|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|early_rail::ERA_ARGS_04|FILL_IN_early_rail_ERA_ARGS_04|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|early_rail::ERA_ARGS_05|FILL_IN_early_rail_ERA_ARGS_05|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|early_rail::ERA_ARGS_06|FILL_IN_early_rail_ERA_ARGS_06|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|early_rail::ERA_ARGS_07|FILL_IN_early_rail_ERA_ARGS_07|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|early_rail::ERA_ARGS_08|FILL_IN_early_rail_ERA_ARGS_08|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|early_rail::ERA_ARGS_09|FILL_IN_early_rail_ERA_ARGS_09|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|early_rail::ERA_ARGS_10|FILL_IN_early_rail_ERA_ARGS_10|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|early_rail::ERA_ARGS_11|FILL_IN_early_rail_ERA_ARGS_11|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|early_rail::ERA_ARGS_12|FILL_IN_early_rail_ERA_ARGS_12|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|early_rail::ERA_ARGS_13|FILL_IN_early_rail_ERA_ARGS_13|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|early_rail::DOMAIN|FILL_IN_early_rail_DOMAIN|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/setup_commands.tcl|library_value::ENDCAP_DIRECTION_EXACT_1|FILL_IN_library_value_ENDCAP_DIRECTION_EXACT_1|請填入endcap cell 或對應設定|
|baseline/.private_config/TECH_MV/setup_commands.tcl|library_value::ENDCAP_DIRECTION_EXACT_2|FILL_IN_library_value_ENDCAP_DIRECTION_EXACT_2|請填入endcap cell 或對應設定|
|baseline/.private_config/TECH_MV/setup_commands.tcl|library_value::PURE_FILLER_MASTER_PATTERN|FILL_IN_library_value_PURE_FILLER_MASTER_PATTERN|請填入filler cell 或對應設定|
|baseline/.private_config/TECH_MV/setup_commands.tcl|library_value::TIEOFF_MASTER_LIST|FILL_IN_library_value_TIEOFF_MASTER_LIST|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/.private_config/TECH_MV/setup_commands.tcl|library_value::DESIGN_PROCESS_NODE|FILL_IN_library_value_DESIGN_PROCESS_NODE|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/.private_config/TECH_MV/setup_commands.tcl|library_value::DESIGN_NATIVE_TOP_LAYER|FILL_IN_library_value_DESIGN_NATIVE_TOP_LAYER|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/.private_config/TECH_MV/setup_commands.tcl|library_value::DESIGN_NATIVE_BOTTOM_LAYER|FILL_IN_library_value_DESIGN_NATIVE_BOTTOM_LAYER|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/.private_config/TECH_MV/setup_commands.tcl|library_value::IO_ELECTRICAL_PIN_01|FILL_IN_library_value_IO_ELECTRICAL_PIN_01|請填入 library pin 名稱或接腳對應 dict|
|baseline/.private_config/TECH_MV/setup_commands.tcl|library_value::IO_ELECTRICAL_PIN_02|FILL_IN_library_value_IO_ELECTRICAL_PIN_02|請填入 library pin 名稱或接腳對應 dict|
|baseline/.private_config/TECH_MV/setup_commands.tcl|library_value::IO_ELECTRICAL_PIN_03|FILL_IN_library_value_IO_ELECTRICAL_PIN_03|請填入 library pin 名稱或接腳對應 dict|
|baseline/.private_config/TECH_MV/setup_commands.tcl|library_value::IO_ELECTRICAL_PIN_04|FILL_IN_library_value_IO_ELECTRICAL_PIN_04|請填入 library pin 名稱或接腳對應 dict|
|baseline/.private_config/TECH_MV/setup_commands.tcl|library_value::CTS_SHIELD_NET|FILL_IN_library_value_CTS_SHIELD_NET|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/.private_config/TECH_MV/setup_commands.tcl|library_value::LIB_DIAGNOSTIC_ID_12|FILL_IN_library_value_LIB_DIAGNOSTIC_ID_12|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/.private_config/TECH_MV/setup_commands.tcl|library_value::LIB_DIAGNOSTIC_ID_13|FILL_IN_library_value_LIB_DIAGNOSTIC_ID_13|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/.private_config/TECH_MV/setup_commands.tcl|library_value::DEBUG_SWITCH_CHAIN_PIN_PATTERN|FILL_IN_library_value_DEBUG_SWITCH_CHAIN_PIN_PATTERN|請填入 library pin 名稱或接腳對應 dict|
|baseline/.private_config/TECH_MV/setup_commands.tcl|library_value::IOPAD_DISCOVERY_MASTER_FAMILIES|FILL_IN_library_value_IOPAD_DISCOVERY_MASTER_FAMILIES|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/.private_config/TECH_MV/setup_commands.tcl|library_value::IOPAD_DISCOVERY_CORNER_MASTER|FILL_IN_library_value_IOPAD_DISCOVERY_CORNER_MASTER|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/.private_config/TECH_MV/setup_commands.tcl|library_value::IOPAD_PG_PLACEMENT_MASTER_01|FILL_IN_library_value_IOPAD_PG_PLACEMENT_MASTER_01|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/.private_config/TECH_MV/setup_commands.tcl|library_value::IOPAD_PG_PLACEMENT_MASTER_02|FILL_IN_library_value_IOPAD_PG_PLACEMENT_MASTER_02|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/.private_config/TECH_MV/setup_commands.tcl|library_value::IOPAD_PG_PLACEMENT_MASTER_03|FILL_IN_library_value_IOPAD_PG_PLACEMENT_MASTER_03|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/.private_config/TECH_MV/setup_commands.tcl|library_value::IOPAD_PG_PLACEMENT_MASTER_04|FILL_IN_library_value_IOPAD_PG_PLACEMENT_MASTER_04|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/.private_config/TECH_MV/setup_commands.tcl|library_value::IOPAD_PG_PLACEMENT_MASTER_05|FILL_IN_library_value_IOPAD_PG_PLACEMENT_MASTER_05|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/.private_config/TECH_MV/setup_commands.tcl|library_value::IOPAD_PG_PLACEMENT_MASTER_06|FILL_IN_library_value_IOPAD_PG_PLACEMENT_MASTER_06|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/.private_config/TECH_MV/setup_commands.tcl|library_value::IOPAD_PG_PLACEMENT_MASTER_07|FILL_IN_library_value_IOPAD_PG_PLACEMENT_MASTER_07|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/.private_config/TECH_MV/setup_commands.tcl|library_value::SW_CONNECTIVITY_DIAGNOSTIC_PIN|FILL_IN_library_value_SW_CONNECTIVITY_DIAGNOSTIC_PIN|請填入 library pin 名稱或接腳對應 dict|
|baseline/.private_config/TECH_MV/setup_commands.tcl|library_value::ENDCAP_CHECKPOINT_COMPAT_NAMES|FILL_IN_library_value_ENDCAP_CHECKPOINT_COMPAT_NAMES|請填入endcap cell 或對應設定|
|baseline/script/PR/TECH_MV/setup/config/00_design.config.tcl|POWER_PORT_NETS|FILL_IN_POWER_PORT_NETS|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/00_design.config.tcl|POWER_NETS|FILL_IN_POWER_NETS|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/00_design.config.tcl|GROUND_NET|FILL_IN_GROUND_NET|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/00_design.config.tcl|PD_CFG|FILL_IN_PD_CFG|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/00_design.config.tcl|BOND_PAD_CELL|FILL_IN_BOND_PAD_CELL|請填入bond pad cell 或對應設定|
|baseline/script/PR/TECH_MV/setup/config/00_design.config.tcl|BOND_PAD_TOP_LAYER|FILL_IN_BOND_PAD_TOP_LAYER|請填入 PDK 層名或層範圍|
|baseline/script/PR/TECH_MV/setup/config/00_design.config.tcl|BOND_PAD_DEFAULT_PIN|FILL_IN_BOND_PAD_DEFAULT_PIN|請填入 library pin 名稱或接腳對應 dict|
|baseline/script/PR/TECH_MV/setup/config/00_design.config.tcl|BOND_PAD_PIN_MAP|FILL_IN_BOND_PAD_PIN_MAP|請填入 library pin 名稱或接腳對應 dict|
|baseline/script/PR/TECH_MV/setup/config/00_design.config.tcl|BOND_PAD_RIGHT_DOWN|FILL_IN_BOND_PAD_RIGHT_DOWN|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/00_design.config.tcl|BOND_PAD_TOP_RIGHT|FILL_IN_BOND_PAD_TOP_RIGHT|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/00_design.config.tcl|BOND_PAD_LEFT_UP|FILL_IN_BOND_PAD_LEFT_UP|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/script/PR/TECH_MV/setup/config/00_design.config.tcl|BOND_PAD_BOTTOM_LEFT|FILL_IN_BOND_PAD_BOTTOM_LEFT|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/script/PR/TECH_MV/setup/config/00_design.config.tcl|BOND_PAD_RDL_WIDTH|FILL_IN_BOND_PAD_RDL_WIDTH|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/00_design.config.tcl|BOND_PAD_RDL_SPACING|FILL_IN_BOND_PAD_RDL_SPACING|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/00_design.config.tcl|BOND_PAD_GAP|FILL_IN_BOND_PAD_GAP|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/00_design.config.tcl|BOND_PAD_CHIP_BOUNDARY_LAYER|FILL_IN_BOND_PAD_CHIP_BOUNDARY_LAYER|請填入 PDK 層名或層範圍|
|baseline/script/PR/TECH_MV/setup/config/00_design.config.tcl|BOND_PAD_CHIP_BOUNDARY_VERTICAL_EXTEND|FILL_IN_BOND_PAD_CHIP_BOUNDARY_VERTICAL_EXTEND|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/00_design.config.tcl|BOND_PAD_CHIP_BOUNDARY_HORIZONTAL_EXTEND|FILL_IN_BOND_PAD_CHIP_BOUNDARY_HORIZONTAL_EXTEND|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/00_input.config.tcl|UPF_SOURCE_FILES|FILL_IN_UPF_SOURCE_FILES|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/00_input.config.tcl|LEF_FILES|FILL_IN_LEF_FILES|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/script/PR/TECH_MV/setup/config/00_input.config.tcl|MMMC_QRC_BEST_FILE|FILL_IN_MMMC_QRC_BEST_FILE|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/script/PR/TECH_MV/setup/config/00_input.config.tcl|MMMC_QRC_WORST_FILE|FILL_IN_MMMC_QRC_WORST_FILE|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/script/PR/TECH_MV/setup/config/00_input.config.tcl|MMMC_CORE_LEVEL_01_LIB_WC_FILES|FILL_IN_MMMC_CORE_LEVEL_01_LIB_WC_FILES|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/script/PR/TECH_MV/setup/config/00_input.config.tcl|MMMC_CORE_LEVEL_02_LIB_WC_FILES|FILL_IN_MMMC_CORE_LEVEL_02_LIB_WC_FILES|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/script/PR/TECH_MV/setup/config/00_input.config.tcl|MMMC_IO_LIB_WC_FILES|FILL_IN_MMMC_IO_LIB_WC_FILES|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/script/PR/TECH_MV/setup/config/00_input.config.tcl|MMMC_LVL_LEVEL_01_H2L_LEVEL_02_LIB_WC_FILES|FILL_IN_MMMC_LVL_LEVEL_01_H2L_LEVEL_02_LIB_WC_FILES|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/script/PR/TECH_MV/setup/config/00_input.config.tcl|MMMC_LVL_LEVEL_02_L2H_LEVEL_01_LIB_WC_FILES|FILL_IN_MMMC_LVL_LEVEL_02_L2H_LEVEL_01_LIB_WC_FILES|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/script/PR/TECH_MV/setup/config/00_input.config.tcl|MMMC_PM_LEVEL_01_LIB_WC_FILES|FILL_IN_MMMC_PM_LEVEL_01_LIB_WC_FILES|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/script/PR/TECH_MV/setup/config/00_input.config.tcl|MMMC_PM_LEVEL_02_LIB_WC_FILES|FILL_IN_MMMC_PM_LEVEL_02_LIB_WC_FILES|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/script/PR/TECH_MV/setup/config/00_input.config.tcl|MMMC_MEM_LIB_WC_FILES|FILL_IN_MMMC_MEM_LIB_WC_FILES|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/script/PR/TECH_MV/setup/config/00_input.config.tcl|MMMC_CORE_LEVEL_01_LIB_BC_FILES|FILL_IN_MMMC_CORE_LEVEL_01_LIB_BC_FILES|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/script/PR/TECH_MV/setup/config/00_input.config.tcl|MMMC_CORE_LEVEL_02_LIB_BC_FILES|FILL_IN_MMMC_CORE_LEVEL_02_LIB_BC_FILES|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/script/PR/TECH_MV/setup/config/00_input.config.tcl|MMMC_IO_LIB_BC_FILES|FILL_IN_MMMC_IO_LIB_BC_FILES|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/script/PR/TECH_MV/setup/config/00_input.config.tcl|MMMC_LVL_LEVEL_01_H2L_LEVEL_02_LIB_BC_FILES|FILL_IN_MMMC_LVL_LEVEL_01_H2L_LEVEL_02_LIB_BC_FILES|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/script/PR/TECH_MV/setup/config/00_input.config.tcl|MMMC_LVL_LEVEL_02_L2H_LEVEL_01_LIB_BC_FILES|FILL_IN_MMMC_LVL_LEVEL_02_L2H_LEVEL_01_LIB_BC_FILES|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/script/PR/TECH_MV/setup/config/00_input.config.tcl|MMMC_PM_LEVEL_01_LIB_BC_FILES|FILL_IN_MMMC_PM_LEVEL_01_LIB_BC_FILES|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/script/PR/TECH_MV/setup/config/00_input.config.tcl|MMMC_PM_LEVEL_02_LIB_BC_FILES|FILL_IN_MMMC_PM_LEVEL_02_LIB_BC_FILES|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/script/PR/TECH_MV/setup/config/00_input.config.tcl|MMMC_MEM_LIB_BC_FILES|FILL_IN_MMMC_MEM_LIB_BC_FILES|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/script/PR/TECH_MV/setup/config/00_input.config.tcl|PG_LIBRARY_QRC_FILE|FILL_IN_PG_LIBRARY_QRC_FILE|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/script/PR/TECH_MV/setup/config/00_input.config.tcl|STREAM_OUT_MAP_SOURCE|FILL_IN_STREAM_OUT_MAP_SOURCE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/00_input.config.tcl|TECH_CORE_GDS_DIR|FILL_IN_TECH_CORE_GDS_DIR|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/00_input.config.tcl|TECH_IO_GDS_DIR|FILL_IN_TECH_IO_GDS_DIR|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/00_input.config.tcl|STREAM_MERGE_GDS_FILES|FILL_IN_STREAM_MERGE_GDS_FILES|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/00_library.config.tcl|::TECH_EXPORT_DECAP_MASTER_PATTERN|FILL_IN_TECH_EXPORT_DECAP_MASTER_PATTERN|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/00_library.config.tcl|::TECH_EXPORT_POWERPAD_MASTER_PATTERN|FILL_IN_TECH_EXPORT_POWERPAD_MASTER_PATTERN|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/00_library.config.tcl|::TECH_EXPORT_FILLER_MASTER_PATTERN|FILL_IN_TECH_EXPORT_FILLER_MASTER_PATTERN|請填入filler cell 或對應設定|
|baseline/script/PR/TECH_MV/setup/config/00_library.config.tcl|::TECH_EXPORT_PFILLER_MASTER_PATTERN|FILL_IN_TECH_EXPORT_PFILLER_MASTER_PATTERN|請填入filler cell 或對應設定|
|baseline/script/PR/TECH_MV/setup/config/00_library.config.tcl|::TECH_EXPORT_PCORNER_MASTER_PATTERN|FILL_IN_TECH_EXPORT_PCORNER_MASTER_PATTERN|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/00_library.config.tcl|::TECH_MV_IO_BOUNDARY_ROLE|FILL_IN_TECH_MV_IO_BOUNDARY_ROLE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/01_floorplan.config.tcl|CORE_SITE|FILL_IN_CORE_SITE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/01_floorplan.config.tcl|FLOORPLAN_DIE_SIZE|FILL_IN_FLOORPLAN_DIE_SIZE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/01_floorplan.config.tcl|FLOORPLAN_BOX_SIZE|FILL_IN_FLOORPLAN_BOX_SIZE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/01_floorplan.config.tcl|FLOORPLAN_BOUND_THRESHOLD|FILL_IN_FLOORPLAN_BOUND_THRESHOLD|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/01_floorplan.config.tcl|FLOORPLAN_BOUND_MARGIN|FILL_IN_FLOORPLAN_BOUND_MARGIN|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/01_floorplan.config.tcl|FLOORPLAN_IO_PAD_MIN_GAP|FILL_IN_FLOORPLAN_IO_PAD_MIN_GAP|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/01_floorplan.config.tcl|FLOORPLAN_CORE_DENSITY_ASPECT_RATIO|FILL_IN_FLOORPLAN_CORE_DENSITY_ASPECT_RATIO|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/01_floorplan.config.tcl|IO_CORNER_PAD_OFFSET|FILL_IN_IO_CORNER_PAD_OFFSET|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/01_floorplan.config.tcl|RTE_PAD_PIN|FILL_IN_RTE_PAD_PIN|請填入 library pin 名稱或接腳對應 dict|
|baseline/script/PR/TECH_MV/setup/config/01_floorplan.config.tcl|RTE_PAD_BOND_ASSIGN_SUPPLIES|FILL_IN_RTE_PAD_BOND_ASSIGN_SUPPLIES|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/01_floorplan.config.tcl|POWER_DOMAIN_CORE_OFFSET_CONFIG|FILL_IN_POWER_DOMAIN_CORE_OFFSET_CONFIG|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/01_floorplan.config.tcl|POWER_DOMAIN_SCALE_CONFIG|FILL_IN_POWER_DOMAIN_SCALE_CONFIG|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/01_floorplan.config.tcl|POWER_DOMAIN_ASPECT_RATIO_CONFIG|FILL_IN_POWER_DOMAIN_ASPECT_RATIO_CONFIG|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/01_floorplan.config.tcl|MACRO_PLACE_HALO|FILL_IN_MACRO_PLACE_HALO|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/01_floorplan.config.tcl|MACRO_ROUTE_HALO_SPACE|FILL_IN_MACRO_ROUTE_HALO_SPACE|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/01_floorplan.config.tcl|MACRO_ROUTE_HALO_BOTTOM_LAYER|FILL_IN_MACRO_ROUTE_HALO_BOTTOM_LAYER|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/01_floorplan.config.tcl|MACRO_ROUTE_HALO_TOP_LAYER|FILL_IN_MACRO_ROUTE_HALO_TOP_LAYER|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/01_floorplan.config.tcl|MACRO_MIN_SPACE_TO_CORE|FILL_IN_MACRO_MIN_SPACE_TO_CORE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/01_floorplan.config.tcl|MACRO_MIN_SPACE_TO_MACRO|FILL_IN_MACRO_MIN_SPACE_TO_MACRO|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/01_floorplan.config.tcl|MACRO_CORNER_KEEPOUT|FILL_IN_MACRO_CORNER_KEEPOUT|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/01_floorplan.config.tcl|MACRO_H_OFFSET|FILL_IN_MACRO_H_OFFSET|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/01_floorplan.config.tcl|MACRO_H_SPACE|FILL_IN_MACRO_H_SPACE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/01_floorplan.config.tcl|MACRO_V_OFFSET|FILL_IN_MACRO_V_OFFSET|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/01_floorplan.config.tcl|MACRO_V_SPACE|FILL_IN_MACRO_V_SPACE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/01_floorplan.config.tcl|CLEAR_STD_CELLS_AFTER_MACRO_FLOORPLAN|FILL_IN_CLEAR_STD_CELLS_AFTER_MACRO_FLOORPLAN|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/01_floorplan.config.tcl|CLEAR_STD_CELLS_BEFORE_POWERPLAN|FILL_IN_CLEAR_STD_CELLS_BEFORE_POWERPLAN|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/01_floorplan.config.tcl|PD_BOUNDARY_ROW_GUARD_WIDTH|FILL_IN_PD_BOUNDARY_ROW_GUARD_WIDTH|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/01_floorplan.config.tcl|IO_BOND_PAD_PREVIEW_DB_NAME|FILL_IN_IO_BOND_PAD_PREVIEW_DB_NAME|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/01_floorplan.config.tcl|IO_BOND_PAD_PREVIEW_AFTER_DB_NAME|FILL_IN_IO_BOND_PAD_PREVIEW_AFTER_DB_NAME|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/01_floorplan.config.tcl|POWERPLAN_BOND_PAD_PREVIEW_DB_NAME|FILL_IN_POWERPLAN_BOND_PAD_PREVIEW_DB_NAME|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/01_floorplan.config.tcl|POWERPLAN_BOND_PAD_PREVIEW_AFTER_DB_NAME|FILL_IN_POWERPLAN_BOND_PAD_PREVIEW_AFTER_DB_NAME|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/01_floorplan.config.tcl|BOND_PAD_PREVIEW_SEARCH_PARITY|FILL_IN_BOND_PAD_PREVIEW_SEARCH_PARITY|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/01_floorplan.config.tcl|BOND_PAD_PREVIEW_STRICT_OVERLAP|FILL_IN_BOND_PAD_PREVIEW_STRICT_OVERLAP|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/01_floorplan.config.tcl|BOND_PAD_PREVIEW_SAVE_DB|FILL_IN_BOND_PAD_PREVIEW_SAVE_DB|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/01_floorplan.config.tcl|BOND_PAD_ACCEPT_INTERNAL_MAXWIDTH|FILL_IN_BOND_PAD_ACCEPT_INTERNAL_MAXWIDTH|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/01_floorplan.config.tcl|IOPAD_RING_NAME|FILL_IN_IOPAD_RING_NAME|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/01_floorplan.config.tcl|IOPAD_RING_DIRECTION|FILL_IN_IOPAD_RING_DIRECTION|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/01_floorplan.config.tcl|IOPAD_RING_DOMAIN_CONFIG|FILL_IN_IOPAD_RING_DOMAIN_CONFIG|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/01_floorplan.config.tcl|IOPAD_RING_CREATE_MISSING_PADS|FILL_IN_IOPAD_RING_CREATE_MISSING_PADS|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/01_floorplan.config.tcl|IOPAD_RING_CREATE_CUTS|FILL_IN_IOPAD_RING_CREATE_CUTS|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/01_floorplan.config.tcl|IOPAD_RING_CUT_PREFIX|FILL_IN_IOPAD_RING_CUT_PREFIX|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/01_floorplan.config.tcl|IOPAD_RING_CUT_BASE_VERTICAL|FILL_IN_IOPAD_RING_CUT_BASE_VERTICAL|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/01_floorplan.config.tcl|IOPAD_RING_CUT_BASE_HORIZONTAL|FILL_IN_IOPAD_RING_CUT_BASE_HORIZONTAL|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/01_floorplan.config.tcl|IOPAD_RING_STRICT|FILL_IN_IOPAD_RING_STRICT|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/01_floorplan.config.tcl|INSERT_BOUNDARY_CELLS_AFTER_FLOORPLAN|FILL_IN_INSERT_BOUNDARY_CELLS_AFTER_FLOORPLAN|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/01_floorplan.config.tcl|ENDCAP_POWER_DOMAIN_LIST|FILL_IN_ENDCAP_POWER_DOMAIN_LIST|請填入endcap cell 或對應設定|
|baseline/script/PR/TECH_MV/setup/config/01_floorplan.config.tcl|ENDCAP_DEFAULT_POWER_DOMAIN|FILL_IN_ENDCAP_DEFAULT_POWER_DOMAIN|請填入endcap cell 或對應設定|
|baseline/script/PR/TECH_MV/setup/config/01_floorplan.config.tcl|ENDCAP_EXCLUDE_POWER_DOMAIN_PATTERNS|FILL_IN_ENDCAP_EXCLUDE_POWER_DOMAIN_PATTERNS|請填入endcap cell 或對應設定|
|baseline/script/PR/TECH_MV/setup/config/01_floorplan.config.tcl|ENDCAP_GLOBAL_PREFIX|FILL_IN_ENDCAP_GLOBAL_PREFIX|請填入endcap cell 或對應設定|
|baseline/script/PR/TECH_MV/setup/config/01_floorplan.config.tcl|ENDCAP_POWER_DOMAIN_PREFIX|FILL_IN_ENDCAP_POWER_DOMAIN_PREFIX|請填入endcap cell 或對應設定|
|baseline/script/PR/TECH_MV/setup/config/01_floorplan.config.tcl|DEFER_WELL_TAP_TO_POST_POWERPLAN|FILL_IN_DEFER_WELL_TAP_TO_POST_POWERPLAN|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/01_floorplan.config.tcl|GACORE_SITE_NAME|FILL_IN_GACORE_SITE_NAME|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/01_floorplan.config.tcl|ENDCAP_LEFT_EDGE_CELLS|FILL_IN_ENDCAP_LEFT_EDGE_CELLS|請填入endcap cell 或對應設定|
|baseline/script/PR/TECH_MV/setup/config/01_floorplan.config.tcl|ENDCAP_RIGHT_EDGE_CELLS|FILL_IN_ENDCAP_RIGHT_EDGE_CELLS|請填入endcap cell 或對應設定|
|baseline/script/PR/TECH_MV/setup/config/01_floorplan.config.tcl|ENDCAP_LEFT_TOP_CORNER_CELLS|FILL_IN_ENDCAP_LEFT_TOP_CORNER_CELLS|請填入endcap cell 或對應設定|
|baseline/script/PR/TECH_MV/setup/config/01_floorplan.config.tcl|ENDCAP_LEFT_BOTTOM_CORNER_CELLS|FILL_IN_ENDCAP_LEFT_BOTTOM_CORNER_CELLS|請填入endcap cell 或對應設定|
|baseline/script/PR/TECH_MV/setup/config/01_floorplan.config.tcl|ENDCAP_TOP_EDGE_CELLS|FILL_IN_ENDCAP_TOP_EDGE_CELLS|請填入endcap cell 或對應設定|
|baseline/script/PR/TECH_MV/setup/config/01_floorplan.config.tcl|ENDCAP_BOTTOM_EDGE_CELLS|FILL_IN_ENDCAP_BOTTOM_EDGE_CELLS|請填入endcap cell 或對應設定|
|baseline/script/PR/TECH_MV/setup/config/01_floorplan.config.tcl|ENDCAP_CORNER_FILL_CELLS|FILL_IN_ENDCAP_CORNER_FILL_CELLS|請填入endcap cell 或對應設定|
|baseline/script/PR/TECH_MV/setup/config/01_floorplan.config.tcl|ENDCAP_TOP_TAP_CELLS|FILL_IN_ENDCAP_TOP_TAP_CELLS|請填入endcap cell 或對應設定|
|baseline/script/PR/TECH_MV/setup/config/01_floorplan.config.tcl|ENDCAP_BOTTOM_TAP_CELLS|FILL_IN_ENDCAP_BOTTOM_TAP_CELLS|請填入endcap cell 或對應設定|
|baseline/script/PR/TECH_MV/setup/config/01_floorplan.config.tcl|ENDCAP_WELL_TAP_RULE|FILL_IN_ENDCAP_WELL_TAP_RULE|請填入endcap cell 或對應設定|
|baseline/script/PR/TECH_MV/setup/config/01_floorplan.config.tcl|POWER_SWITCH_INSERTION_MODE|FILL_IN_POWER_SWITCH_INSERTION_MODE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/01_floorplan.config.tcl|POWER_SWITCH_INSTANCE_PREFIXES|FILL_IN_POWER_SWITCH_INSTANCE_PREFIXES|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/01_floorplan.config.tcl|POWER_SWITCH_LEFT_OFFSET|FILL_IN_POWER_SWITCH_LEFT_OFFSET|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/01_floorplan.config.tcl|POWER_SWITCH_RIGHT_OFFSET|FILL_IN_POWER_SWITCH_RIGHT_OFFSET|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/01_floorplan.config.tcl|POWER_SWITCH_TOP_OFFSET|FILL_IN_POWER_SWITCH_TOP_OFFSET|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/01_floorplan.config.tcl|POWER_SWITCH_BOTTOM_OFFSET|FILL_IN_POWER_SWITCH_BOTTOM_OFFSET|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/01_floorplan.config.tcl|POWER_SWITCH_EDGE_REINFORCE_GAP|FILL_IN_POWER_SWITCH_EDGE_REINFORCE_GAP|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/01_floorplan.config.tcl|POWER_SWITCH_ENDCAP_OVERLAP_AUTO_DELETE|FILL_IN_POWER_SWITCH_ENDCAP_OVERLAP_AUTO_DELETE|請填入endcap cell 或對應設定|
|baseline/script/PR/TECH_MV/setup/config/01_floorplan.config.tcl|POWER_SWITCH_ENDCAP_OVERLAP_SAVE_DB|FILL_IN_POWER_SWITCH_ENDCAP_OVERLAP_SAVE_DB|請填入endcap cell 或對應設定|
|baseline/script/PR/TECH_MV/setup/config/01_floorplan.config.tcl|ENDCAP_POST_INSERT_RUN_CHECKS|FILL_IN_ENDCAP_POST_INSERT_RUN_CHECKS|請填入endcap cell 或對應設定|
|baseline/script/PR/TECH_MV/setup/config/01_floorplan.config.tcl|ENDCAP_POST_INSERT_SAVE_DB|FILL_IN_ENDCAP_POST_INSERT_SAVE_DB|請填入endcap cell 或對應設定|
|baseline/script/PR/TECH_MV/setup/config/02_powerplan.config.tcl|PNS_AUTO_RUN_ON_SOURCE|FILL_IN_PNS_AUTO_RUN_ON_SOURCE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/02_powerplan.config.tcl|POWERPLAN_CORE_RING_LOWER|FILL_IN_POWERPLAN_CORE_RING_LOWER|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/02_powerplan.config.tcl|POWERPLAN_CORE_RING_UPPER|FILL_IN_POWERPLAN_CORE_RING_UPPER|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/02_powerplan.config.tcl|POWERPLAN_PAD_PIN_LAYER_CHANGE_RANGE|FILL_IN_POWERPLAN_PAD_PIN_LAYER_CHANGE_RANGE|請填入 library pin 名稱或接腳對應 dict|
|baseline/script/PR/TECH_MV/setup/config/02_powerplan.config.tcl|POWERPLAN_PAD_PIN_LAYER_RANGE|FILL_IN_POWERPLAN_PAD_PIN_LAYER_RANGE|請填入 library pin 名稱或接腳對應 dict|
|baseline/script/PR/TECH_MV/setup/config/02_powerplan.config.tcl|POWERPLAN_PAD_PIN_PORT_CONNECT|FILL_IN_POWERPLAN_PAD_PIN_PORT_CONNECT|請填入 library pin 名稱或接腳對應 dict|
|baseline/script/PR/TECH_MV/setup/config/02_powerplan.config.tcl|POWERPLAN_PAD_PIN_BLOCKAGE_NAME|FILL_IN_POWERPLAN_PAD_PIN_BLOCKAGE_NAME|請填入 library pin 名稱或接腳對應 dict|
|baseline/script/PR/TECH_MV/setup/config/02_powerplan.config.tcl|POWERPLAN_PAD_PIN_BLOCKAGE_LAYERS|FILL_IN_POWERPLAN_PAD_PIN_BLOCKAGE_LAYERS|請填入 library pin 名稱或接腳對應 dict|
|baseline/script/PR/TECH_MV/setup/config/02_powerplan.config.tcl|POWERPLAN_PAD_PIN_BLOCKAGE_INNER_OFFSET|FILL_IN_POWERPLAN_PAD_PIN_BLOCKAGE_INNER_OFFSET|請填入 library pin 名稱或接腳對應 dict|
|baseline/script/PR/TECH_MV/setup/config/02_powerplan.config.tcl|POWERPLAN_PAD_PIN_BLOCKAGE_OUTER_OFFSET|FILL_IN_POWERPLAN_PAD_PIN_BLOCKAGE_OUTER_OFFSET|請填入 library pin 名稱或接腳對應 dict|
|baseline/script/PR/TECH_MV/setup/config/02_powerplan.config.tcl|POWERPLAN_PAD_PIN_BLOCKAGE_CORE_GAP|FILL_IN_POWERPLAN_PAD_PIN_BLOCKAGE_CORE_GAP|請填入 library pin 名稱或接腳對應 dict|
|baseline/script/PR/TECH_MV/setup/config/02_powerplan.config.tcl|POWERPLAN_PAD_CELL_PATTERN|FILL_IN_POWERPLAN_PAD_CELL_PATTERN|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/02_powerplan.config.tcl|POWERPLAN_PD_TOP_RING_DOMAIN|FILL_IN_POWERPLAN_PD_TOP_RING_DOMAIN|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/02_powerplan.config.tcl|POWERPLAN_PD_BLOCK_RING_DOMAINS|FILL_IN_POWERPLAN_PD_BLOCK_RING_DOMAINS|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/02_powerplan.config.tcl|POWERPLAN_PD_RING_UPPER|FILL_IN_POWERPLAN_PD_RING_UPPER|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/02_powerplan.config.tcl|POWERPLAN_PD_RING_LOWER|FILL_IN_POWERPLAN_PD_RING_LOWER|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/02_powerplan.config.tcl|POWERPLAN_MACRO_PG_BLOCKAGE_LAYERS|FILL_IN_POWERPLAN_MACRO_PG_BLOCKAGE_LAYERS|請填入 PDK 層名或層範圍|
|baseline/script/PR/TECH_MV/setup/config/02_powerplan.config.tcl|POWERPLAN_MACRO_PG_BLOCKAGE_CLEARANCE|FILL_IN_POWERPLAN_MACRO_PG_BLOCKAGE_CLEARANCE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/02_powerplan.config.tcl|POWERPLAN_M9_ALL_STRIPE|FILL_IN_POWERPLAN_M9_ALL_STRIPE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/02_powerplan.config.tcl|POWERPLAN_M8_GROUND_STRIPE|FILL_IN_POWERPLAN_M8_GROUND_STRIPE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/02_powerplan.config.tcl|POWERPLAN_M8_POWER_STRIPE|FILL_IN_POWERPLAN_M8_POWER_STRIPE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/02_powerplan.config.tcl|POWERPLAN_M7_GROUND_STRIPE|FILL_IN_POWERPLAN_M7_GROUND_STRIPE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/02_powerplan.config.tcl|POWERPLAN_M7_POWER_STRIPE|FILL_IN_POWERPLAN_M7_POWER_STRIPE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/02_powerplan.config.tcl|POWERPLAN_M6_GROUND_STRIPE|FILL_IN_POWERPLAN_M6_GROUND_STRIPE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/02_powerplan.config.tcl|POWERPLAN_M6_POWER_STRIPE|FILL_IN_POWERPLAN_M6_POWER_STRIPE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/02_powerplan.config.tcl|POWERPLAN_M5_GROUND_STRIPE|FILL_IN_POWERPLAN_M5_GROUND_STRIPE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/02_powerplan.config.tcl|POWERPLAN_M5_POWER_STRIPE|FILL_IN_POWERPLAN_M5_POWER_STRIPE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/02_powerplan.config.tcl|POWERPLAN_FLOATING_STRIPE_LAYER_CHANGE_RANGE|FILL_IN_POWERPLAN_FLOATING_STRIPE_LAYER_CHANGE_RANGE|請填入 PDK 層名或層範圍|
|baseline/script/PR/TECH_MV/setup/config/02_powerplan.config.tcl|POWERPLAN_FLOATING_STRIPE_TARGETS|FILL_IN_POWERPLAN_FLOATING_STRIPE_TARGETS|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/02_powerplan.config.tcl|POWERPLAN_FOLLOW_PIN_LAYER_CHANGE_RANGE|FILL_IN_POWERPLAN_FOLLOW_PIN_LAYER_CHANGE_RANGE|請填入 library pin 名稱或接腳對應 dict|
|baseline/script/PR/TECH_MV/setup/config/02_powerplan.config.tcl|POWERPLAN_FOLLOW_PIN_CORE_PIN_LAYER|FILL_IN_POWERPLAN_FOLLOW_PIN_CORE_PIN_LAYER|請填入 library pin 名稱或接腳對應 dict|
|baseline/script/PR/TECH_MV/setup/config/02_powerplan.config.tcl|POWERPLAN_FOLLOW_PIN_TARGET|FILL_IN_POWERPLAN_FOLLOW_PIN_TARGET|請填入 library pin 名稱或接腳對應 dict|
|baseline/script/PR/TECH_MV/setup/config/02_powerplan.config.tcl|PNS_CORE_RING_1|FILL_IN_PNS_CORE_RING_1|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/02_powerplan.config.tcl|PNS_CORE_RING_2|FILL_IN_PNS_CORE_RING_2|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/02_powerplan.config.tcl|PNS_CORE_RING_3|FILL_IN_PNS_CORE_RING_3|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/02_powerplan.config.tcl|PNS_PAD_PIN_LAYER_CHANGE_RANGE|FILL_IN_PNS_PAD_PIN_LAYER_CHANGE_RANGE|請填入 library pin 名稱或接腳對應 dict|
|baseline/script/PR/TECH_MV/setup/config/02_powerplan.config.tcl|PNS_PAD_PIN_LAYER_RANGE|FILL_IN_PNS_PAD_PIN_LAYER_RANGE|請填入 library pin 名稱或接腳對應 dict|
|baseline/script/PR/TECH_MV/setup/config/02_powerplan.config.tcl|PNS_MACRO_BLOCKAGE_LAYERS|FILL_IN_PNS_MACRO_BLOCKAGE_LAYERS|請填入 PDK 層名或層範圍|
|baseline/script/PR/TECH_MV/setup/config/02_powerplan.config.tcl|PNS_MACRO_BLOCKAGE_CLEARANCE|FILL_IN_PNS_MACRO_BLOCKAGE_CLEARANCE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/02_powerplan.config.tcl|PNS_M9_ALL_STRIPE|FILL_IN_PNS_M9_ALL_STRIPE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/02_powerplan.config.tcl|PNS_M8_GROUND_STRIPE|FILL_IN_PNS_M8_GROUND_STRIPE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/02_powerplan.config.tcl|PNS_M8_POWER_STRIPE|FILL_IN_PNS_M8_POWER_STRIPE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/02_powerplan.config.tcl|PNS_M7_GROUND_STRIPE|FILL_IN_PNS_M7_GROUND_STRIPE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/02_powerplan.config.tcl|PNS_M7_POWER_STRIPE|FILL_IN_PNS_M7_POWER_STRIPE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/02_powerplan.config.tcl|PNS_M6_GROUND_STRIPE|FILL_IN_PNS_M6_GROUND_STRIPE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/02_powerplan.config.tcl|PNS_M6_POWER_STRIPE|FILL_IN_PNS_M6_POWER_STRIPE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/02_powerplan.config.tcl|PNS_M5_GROUND_STRIPE|FILL_IN_PNS_M5_GROUND_STRIPE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/02_powerplan.config.tcl|PNS_M5_POWER_STRIPE|FILL_IN_PNS_M5_POWER_STRIPE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/02_powerplan.config.tcl|PNS_FOLLOW_PIN_LAYER_CHANGE_RANGE|FILL_IN_PNS_FOLLOW_PIN_LAYER_CHANGE_RANGE|請填入 library pin 名稱或接腳對應 dict|
|baseline/script/PR/TECH_MV/setup/config/02_powerplan.config.tcl|PNS_FOLLOW_PIN_VIA_SCALE_HEIGHT|FILL_IN_PNS_FOLLOW_PIN_VIA_SCALE_HEIGHT|請填入 library pin 名稱或接腳對應 dict|
|baseline/script/PR/TECH_MV/setup/config/02_powerplan.config.tcl|PNS_FOLLOW_PIN_VIA_SCALE_WIDTH|FILL_IN_PNS_FOLLOW_PIN_VIA_SCALE_WIDTH|請填入 library pin 名稱或接腳對應 dict|
|baseline/script/PR/TECH_MV/setup/config/02_powerplan.config.tcl|PNS_M2_POWER_RAIL|FILL_IN_PNS_M2_POWER_RAIL|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/02_powerplan.config.tcl|PNS_M2_GROUND_RAIL|FILL_IN_PNS_M2_GROUND_RAIL|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/02_powerplan.config.tcl|POWER_SWITCH_DESIGN_MAP|FILL_IN_POWER_SWITCH_DESIGN_MAP|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/02_powerplan.config.tcl|POWER_SWITCH_HORIZONTAL_PITCH|FILL_IN_POWER_SWITCH_HORIZONTAL_PITCH|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/02_powerplan.config.tcl|PNS_STRIPE_SPACING_FROM_BLOCK|FILL_IN_PNS_STRIPE_SPACING_FROM_BLOCK|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/02_powerplan.config.tcl|PNS_STRIPE_MAX_SAME_LAYER_JOG_LENGTH|FILL_IN_PNS_STRIPE_MAX_SAME_LAYER_JOG_LENGTH|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/02_powerplan.config.tcl|PNS_STD_REGION_Y_EXPANSION|FILL_IN_PNS_STD_REGION_Y_EXPANSION|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/02_powerplan.config.tcl|PNS_RING_THRESHOLD|FILL_IN_PNS_RING_THRESHOLD|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/02_powerplan.config.tcl|PNS_RING_JOG_DISTANCE|FILL_IN_PNS_RING_JOG_DISTANCE|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/02_powerplan.config.tcl|PNS_MACRO_RING_WIDTH|FILL_IN_PNS_MACRO_RING_WIDTH|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/02_powerplan.config.tcl|PNS_MACRO_RING_SPACING|FILL_IN_PNS_MACRO_RING_SPACING|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/02_powerplan.config.tcl|PNS_MACRO_RING_OFFSET|FILL_IN_PNS_MACRO_RING_OFFSET|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/05_route.config.tcl|ROUTE_TOP_ROUTING_LAYER|FILL_IN_ROUTE_TOP_ROUTING_LAYER|請填入 PDK 層名或層範圍|
|baseline/script/PR/TECH_MV/setup/config/05_route.config.tcl|ROUTE_BOTTOM_ROUTING_LAYER|FILL_IN_ROUTE_BOTTOM_ROUTING_LAYER|請填入 PDK 層名或層範圍|
|baseline/script/PR/TECH_MV/setup/config/05_route.config.tcl|INST_PADDING_ERROR_TYPES|FILL_IN_INST_PADDING_ERROR_TYPES|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/05_route.config.tcl|INST_PADDING_LEFT|FILL_IN_INST_PADDING_LEFT|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/script/PR/TECH_MV/setup/config/05_route.config.tcl|INST_PADDING_RIGHT|FILL_IN_INST_PADDING_RIGHT|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/06_finish.config.tcl|FILLER_NO_SINGLE_SITE_GAP|FILL_IN_FILLER_NO_SINGLE_SITE_GAP|請填入filler cell 或對應設定|
|baseline/script/PR/TECH_MV/setup/config/06_finish.config.tcl|FILLER_CELLS|FILL_IN_FILLER_CELLS|請填入filler cell 或對應設定|
|baseline/script/PR/TECH_MV/setup/config/06_finish.config.tcl|STREAM_OUT_TEXT_SIZE|FILL_IN_STREAM_OUT_TEXT_SIZE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/06_finish.config.tcl|STREAM_OUT_LIB_NAME|FILL_IN_STREAM_OUT_LIB_NAME|請填入對應 library／PDK 資源名稱、完整路徑或清單|
|baseline/script/PR/TECH_MV/setup/config/06_finish.config.tcl|STREAM_OUT_UNIT|FILL_IN_STREAM_OUT_UNIT|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/06_finish.config.tcl|STREAM_OUT_MODE|FILL_IN_STREAM_OUT_MODE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/06_finish.config.tcl|STREAM_OUT_CUSTOM_MAP_LINES|FILL_IN_STREAM_OUT_CUSTOM_MAP_LINES|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/06_finish.config.tcl|FILLER_FLOW_CELLS|FILL_IN_FILLER_FLOW_CELLS|請填入filler cell 或對應設定|
|baseline/script/PR/TECH_MV/setup/config/90_debug.config.tcl|ERA_ARGS_01|FILL_IN_ERA_ARGS_01|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/90_debug.config.tcl|ERA_ARGS_02|FILL_IN_ERA_ARGS_02|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/90_debug.config.tcl|ERA_ARGS_03|FILL_IN_ERA_ARGS_03|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/90_debug.config.tcl|ERA_ARGS_04|FILL_IN_ERA_ARGS_04|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/90_debug.config.tcl|ERA_ARGS_05|FILL_IN_ERA_ARGS_05|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/90_debug.config.tcl|ERA_ARGS_06|FILL_IN_ERA_ARGS_06|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/90_debug.config.tcl|ERA_ARGS_07|FILL_IN_ERA_ARGS_07|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/90_debug.config.tcl|ERA_ARGS_08|FILL_IN_ERA_ARGS_08|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/90_debug.config.tcl|ERA_ARGS_09|FILL_IN_ERA_ARGS_09|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/90_debug.config.tcl|ERA_ARGS_10|FILL_IN_ERA_ARGS_10|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/90_debug.config.tcl|ERA_ARGS_11|FILL_IN_ERA_ARGS_11|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/90_debug.config.tcl|ERA_ARGS_12|FILL_IN_ERA_ARGS_12|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/90_debug.config.tcl|ERA_ARGS_13|FILL_IN_ERA_ARGS_13|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/geometry_review.config.tcl|run/tool/02_powerplan/TT_2row_sdp_welltap_after_endcap_v6.tcl::::TT_2ROW_SDP_TAPS_PER_CELL::L71|FILL_IN_run_tool_02_powerplan_TT_2row_sdp_welltap_after_endcap_v6_tcl_TT_2ROW_SDP_TAPS_PER_CELL_L71|請填入well tap cell 或對應設定|
|baseline/script/PR/TECH_MV/setup/config/geometry_review.config.tcl|run/tool/02_powerplan/TT_2row_sdp_welltap_after_endcap_v6.tcl::::TT_2ROW_SDP_POOL_MARGIN::L73|FILL_IN_run_tool_02_powerplan_TT_2row_sdp_welltap_after_endcap_v6_tcl_TT_2ROW_SDP_POOL_MARGIN_L73|請填入well tap cell 或對應設定|
|baseline/script/PR/TECH_MV/setup/config/geometry_review.config.tcl|run/tool/02_powerplan/TT_2row_sdp_welltap_source_run_v5.tcl::::TT_2ROW_SDP_TAPS_PER_CELL::L37|FILL_IN_run_tool_02_powerplan_TT_2row_sdp_welltap_source_run_v5_tcl_TT_2ROW_SDP_TAPS_PER_CELL_L37|請填入well tap cell 或對應設定|
|baseline/script/PR/TECH_MV/setup/config/geometry_review.config.tcl|run/tool/02_powerplan/TT_2row_sdp_welltap_source_run_v5.tcl::::TT_2ROW_SDP_POOL_MARGIN::L39|FILL_IN_run_tool_02_powerplan_TT_2row_sdp_welltap_source_run_v5_tcl_TT_2ROW_SDP_POOL_MARGIN_L39|請填入well tap cell 或對應設定|
|baseline/script/PR/TECH_MV/setup/config/geometry_review.config.tcl|run/tool/02_powerplan/TT_PR7_coordinate_guided_repair.tcl::::TT_PR7_INTERNAL_GAP_MAX_UM::L43|FILL_IN_run_tool_02_powerplan_TT_PR7_coordinate_guided_repair_tcl_TT_PR7_INTERNAL_GAP_MAX_UM_L43|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/geometry_review.config.tcl|run/tool/02_powerplan/TT_PR7_coordinate_guided_repair.tcl::::TT_PR7_COORD_SITE_PITCH_UM::L47|FILL_IN_run_tool_02_powerplan_TT_PR7_coordinate_guided_repair_tcl_TT_PR7_COORD_SITE_PITCH_UM_L47|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/geometry_review.config.tcl|run/tool/02_powerplan/TT_PR7_coordinate_guided_repair.tcl::::TT_PR7_COORD_TOL::L52|FILL_IN_run_tool_02_powerplan_TT_PR7_coordinate_guided_repair_tcl_TT_PR7_COORD_TOL_L52|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/geometry_review.config.tcl|run/tool/02_powerplan/TT_PR7_coordinate_guided_repair.tcl::::TT_PR7_COORD_SWITCH_GAP_UM::L53|FILL_IN_run_tool_02_powerplan_TT_PR7_coordinate_guided_repair_tcl_TT_PR7_COORD_SWITCH_GAP_UM_L53|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/geometry_review.config.tcl|run/tool/02_powerplan/TT_PR7_manual_sdp_origin.tcl::::TT_PR7_MANUAL_ORIGIN_TOL::L40|FILL_IN_run_tool_02_powerplan_TT_PR7_manual_sdp_origin_tcl_TT_PR7_MANUAL_ORIGIN_TOL_L40|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/geometry_review.config.tcl|run/tool/02_powerplan/TT_proc_create_2row_sdp_welltap.tcl::::TT_2ROW_SDP_TAPS_PER_CELL::L23|FILL_IN_run_tool_02_powerplan_TT_proc_create_2row_sdp_welltap_tcl_TT_2ROW_SDP_TAPS_PER_CELL_L23|請填入well tap cell 或對應設定|
|baseline/script/PR/TECH_MV/setup/config/geometry_review.config.tcl|run/tool/02_powerplan/TT_proc_create_2row_sdp_welltap.tcl::::TT_2ROW_SDP_POOL_MARGIN::L25|FILL_IN_run_tool_02_powerplan_TT_proc_create_2row_sdp_welltap_tcl_TT_2ROW_SDP_POOL_MARGIN_L25|請填入well tap cell 或對應設定|
|baseline/script/PR/TECH_MV/setup/config/geometry_review.config.tcl|run/tool/02_powerplan/TT_proc_power_switch_edge_reinforce.tcl::::POWER_SWITCH_EDGE_REINFORCE_PITCH::L61|FILL_IN_run_tool_02_powerplan_TT_proc_power_switch_edge_reinforce_tcl_POWER_SWITCH_EDGE_REINFORCE_PITCH_L61|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/geometry_review.config.tcl|run/tool/02_powerplan/TT_proc_power_switch_edge_reinforce.tcl::::POWER_SWITCH_EDGE_REINFORCE_GAP::L67|FILL_IN_run_tool_02_powerplan_TT_proc_power_switch_edge_reinforce_tcl_POWER_SWITCH_EDGE_REINFORCE_GAP_L67|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/geometry_review.config.tcl|run/tool/02_powerplan/TT_proc_sw_ls_iso_guard.tcl::::TT_SWLS_MIN_GAP_UM::L15|FILL_IN_run_tool_02_powerplan_TT_proc_sw_ls_iso_guard_tcl_TT_SWLS_MIN_GAP_UM_L15|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/geometry_review.config.tcl|run/tool/02_powerplan/TT_refine_internal_gap_sdps.tcl::::TT_PR7_INTERNAL_GAP_MAX_UM::L25|FILL_IN_run_tool_02_powerplan_TT_refine_internal_gap_sdps_tcl_TT_PR7_INTERNAL_GAP_MAX_UM_L25|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/geometry_review.config.tcl|run/tool/02_powerplan/TT_refine_internal_gap_sdps.tcl::::TT_PR7_INTERNAL_GAP_TOL::L26|FILL_IN_run_tool_02_powerplan_TT_refine_internal_gap_sdps_tcl_TT_PR7_INTERNAL_GAP_TOL_L26|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/geometry_review.config.tcl|run/tool/02_powerplan/TT_refine_internal_gap_sdps.tcl::::TT_PR7_GAPBLK_FALLBACK_W::L245|FILL_IN_run_tool_02_powerplan_TT_refine_internal_gap_sdps_tcl_TT_PR7_GAPBLK_FALLBACK_W_L245|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/geometry_review.config.tcl|run/tool/02_powerplan/TT_refine_internal_gap_sdps.tcl::::TT_PR7_GAPBLK_FALLBACK_H::L246|FILL_IN_run_tool_02_powerplan_TT_refine_internal_gap_sdps_tcl_TT_PR7_GAPBLK_FALLBACK_H_L246|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/geometry_review.config.tcl|run/tool/02_powerplan/TT_refine_internal_gap_sdps.tcl::::TT_PR7_GAPBLK_MAX_TRIALS::L247|FILL_IN_run_tool_02_powerplan_TT_refine_internal_gap_sdps_tcl_TT_PR7_GAPBLK_MAX_TRIALS_L247|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/geometry_review.config.tcl|run/tool/02_powerplan/TT_refine_internal_gap_sdps.tcl::::TT_PR7_GAPBLK_NAME_MAX_REVISIONS::L248|FILL_IN_run_tool_02_powerplan_TT_refine_internal_gap_sdps_tcl_TT_PR7_GAPBLK_NAME_MAX_REVISIONS_L248|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/geometry_review.config.tcl|run/tool/02_powerplan/TT_refine_internal_gap_sdps.tcl::::TT_PR7_ORIGIN_SYNC_TOL::L1391|FILL_IN_run_tool_02_powerplan_TT_refine_internal_gap_sdps_tcl_TT_PR7_ORIGIN_SYNC_TOL_L1391|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/geometry_review.config.tcl|run/tool/02_powerplan/TT_repair_internal_sdp_gap.tcl::::TT_2ROW_SDP_INTERNAL_GAP_MAX_SITES::L23|FILL_IN_run_tool_02_powerplan_TT_repair_internal_sdp_gap_tcl_TT_2ROW_SDP_INTERNAL_GAP_MAX_SITES_L23|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/geometry_review.config.tcl|run/tool/02_powerplan/TT_repair_internal_sdp_gap.tcl::::TT_2ROW_SDP_INTERNAL_GAP_TOL_UM::L26|FILL_IN_run_tool_02_powerplan_TT_repair_internal_sdp_gap_tcl_TT_2ROW_SDP_INTERNAL_GAP_TOL_UM_L26|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/geometry_review.config.tcl|run/tool/02_powerplan/TT_repair_powergate_iso_slots.tcl::::TT_SDP_PGISO_TOL::L51|FILL_IN_run_tool_02_powerplan_TT_repair_powergate_iso_slots_tcl_TT_SDP_PGISO_TOL_L51|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/geometry_review.config.tcl|run/tool/02_powerplan/TT_sdp_live_rescue_native_first.tcl::::TT_SDP_RESCUE_GEOM_TOL::L38|FILL_IN_run_tool_02_powerplan_TT_sdp_live_rescue_native_first_tcl_TT_SDP_RESCUE_GEOM_TOL_L38|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/geometry_review.config.tcl|run/tool/02_powerplan/TT_sdp_powergate_row_rules.tcl::::TT_SDP_PGROW_TOL::L56|FILL_IN_run_tool_02_powerplan_TT_sdp_powergate_row_rules_tcl_TT_SDP_PGROW_TOL_L56|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/geometry_review.config.tcl|run/tool/01_floorplan/TT_proc_floorplan_bound_selector.tcl::::FLOORPLAN_IO_PAD_MIN_GAP::L158|FILL_IN_run_tool_01_floorplan_TT_proc_floorplan_bound_selector_tcl_FLOORPLAN_IO_PAD_MIN_GAP_L158|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/geometry_review.config.tcl|run/tool/01_floorplan/TT_proc_floorplan_bound_selector.tcl::::FLOORPLAN_BOUND_MARGIN::L290|FILL_IN_run_tool_01_floorplan_TT_proc_floorplan_bound_selector_tcl_FLOORPLAN_BOUND_MARGIN_L290|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/geometry_review.config.tcl|run/tool/01_floorplan/TT_proc_floorplan_bound_selector.tcl::::FLOORPLAN_IO_PAD_MIN_GAP::L292|FILL_IN_run_tool_01_floorplan_TT_proc_floorplan_bound_selector_tcl_FLOORPLAN_IO_PAD_MIN_GAP_L292|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/geometry_review.config.tcl|run/tool/01_floorplan/TT_proc_trim_powergate_bottom_row.tcl::::TT_SWROW_OFFSET_TOL::L85|FILL_IN_run_tool_01_floorplan_TT_proc_trim_powergate_bottom_row_tcl_TT_SWROW_OFFSET_TOL_L85|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/geometry_review.config.tcl|run/tool/01_floorplan/TT_proc_trim_powergate_bottom_row.tcl::::TT_SWROW_GEOM_TOL::L88|FILL_IN_run_tool_01_floorplan_TT_proc_trim_powergate_bottom_row_tcl_TT_SWROW_GEOM_TOL_L88|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/geometry_review.config.tcl|setup/config/00_design.config.tcl::BOND_PAD_RDL_WIDTH::L87|FILL_IN_setup_config_00_design_config_tcl_BOND_PAD_RDL_WIDTH_L87|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/geometry_review.config.tcl|setup/config/00_design.config.tcl::BOND_PAD_RDL_SPACING::L88|FILL_IN_setup_config_00_design_config_tcl_BOND_PAD_RDL_SPACING_L88|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/geometry_review.config.tcl|setup/config/01_floorplan.config.tcl::IO_CORNER_PAD_OFFSET::L47|FILL_IN_setup_config_01_floorplan_config_tcl_IO_CORNER_PAD_OFFSET_L47|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/geometry_review.config.tcl|setup/config/01_floorplan.config.tcl::MACRO_H_OFFSET::L132|FILL_IN_setup_config_01_floorplan_config_tcl_MACRO_H_OFFSET_L132|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/geometry_review.config.tcl|setup/config/01_floorplan.config.tcl::MACRO_V_OFFSET::L134|FILL_IN_setup_config_01_floorplan_config_tcl_MACRO_V_OFFSET_L134|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/geometry_review.config.tcl|setup/config/01_floorplan.config.tcl::PD_BOUNDARY_ROW_GUARD_WIDTH::L169|FILL_IN_setup_config_01_floorplan_config_tcl_PD_BOUNDARY_ROW_GUARD_WIDTH_L169|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/geometry_review.config.tcl|setup/config/01_floorplan.config.tcl::POWER_SWITCH_LEFT_OFFSET::L303|FILL_IN_setup_config_01_floorplan_config_tcl_POWER_SWITCH_LEFT_OFFSET_L303|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/geometry_review.config.tcl|setup/config/01_floorplan.config.tcl::POWER_SWITCH_RIGHT_OFFSET::L304|FILL_IN_setup_config_01_floorplan_config_tcl_POWER_SWITCH_RIGHT_OFFSET_L304|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/geometry_review.config.tcl|setup/config/01_floorplan.config.tcl::POWER_SWITCH_TOP_OFFSET::L305|FILL_IN_setup_config_01_floorplan_config_tcl_POWER_SWITCH_TOP_OFFSET_L305|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/geometry_review.config.tcl|setup/config/01_floorplan.config.tcl::POWER_SWITCH_BOTTOM_OFFSET::L306|FILL_IN_setup_config_01_floorplan_config_tcl_POWER_SWITCH_BOTTOM_OFFSET_L306|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/geometry_review.config.tcl|setup/config/02_powerplan.config.tcl::POWERPLAN_PAD_PIN_BLOCKAGE_INNER_OFFSET::L26|FILL_IN_setup_config_02_powerplan_config_tcl_POWERPLAN_PAD_PIN_BLOCKAGE_INNER_OFFSET_L26|請填入 library pin 名稱或接腳對應 dict|
|baseline/script/PR/TECH_MV/setup/config/geometry_review.config.tcl|setup/config/02_powerplan.config.tcl::POWERPLAN_PAD_PIN_BLOCKAGE_OUTER_OFFSET::L27|FILL_IN_setup_config_02_powerplan_config_tcl_POWERPLAN_PAD_PIN_BLOCKAGE_OUTER_OFFSET_L27|請填入 library pin 名稱或接腳對應 dict|
|baseline/script/PR/TECH_MV/setup/config/geometry_review.config.tcl|setup/config/02_powerplan.config.tcl::PNS_FOLLOW_PIN_VIA_SCALE_HEIGHT::L119|FILL_IN_setup_config_02_powerplan_config_tcl_PNS_FOLLOW_PIN_VIA_SCALE_HEIGHT_L119|請填入 library pin 名稱或接腳對應 dict|
|baseline/script/PR/TECH_MV/setup/config/geometry_review.config.tcl|setup/config/02_powerplan.config.tcl::PNS_FOLLOW_PIN_VIA_SCALE_WIDTH::L120|FILL_IN_setup_config_02_powerplan_config_tcl_PNS_FOLLOW_PIN_VIA_SCALE_WIDTH_L120|請填入 library pin 名稱或接腳對應 dict|
|baseline/script/PR/TECH_MV/setup/config/geometry_review.config.tcl|run/tool/02_powerplan/TT_delete_followpin_outside_pd_boundary.tcl::edge_tol::L36|FILL_IN_run_tool_02_powerplan_TT_delete_followpin_outside_pd_boundary_tcl_edge_tol_L36|請填入 library pin 名稱或接腳對應 dict|
|baseline/script/PR/TECH_MV/setup/config/geometry_review.config.tcl|run/tool/02_powerplan/TT_delete_followpin_outside_pd_boundary.tcl::join_tol::L37|FILL_IN_run_tool_02_powerplan_TT_delete_followpin_outside_pd_boundary_tcl_join_tol_L37|請填入 library pin 名稱或接腳對應 dict|
|baseline/script/PR/TECH_MV/setup/config/geometry_review.config.tcl|run/tool/02_powerplan/TT_delete_followpin_outside_pd_boundary.tcl::y_tol::L38|FILL_IN_run_tool_02_powerplan_TT_delete_followpin_outside_pd_boundary_tcl_y_tol_L38|請填入 library pin 名稱或接腳對應 dict|
|baseline/script/PR/TECH_MV/setup/config/geometry_review.config.tcl|run/tool/02_powerplan/TT_delete_followpin_outside_pd_boundary.tcl::query_margin::L39|FILL_IN_run_tool_02_powerplan_TT_delete_followpin_outside_pd_boundary_tcl_query_margin_L39|請填入 library pin 名稱或接腳對應 dict|
|baseline/script/PR/TECH_MV/setup/config/geometry_review.config.tcl|generic_design::POWER_SWITCH_HORIZONTAL_PITCH|FILL_IN_generic_design_POWER_SWITCH_HORIZONTAL_PITCH|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/geometry_review.config.tcl|generic_design::METAL_COLOR_BBOX_TOLERANCE|FILL_IN_generic_design_METAL_COLOR_BBOX_TOLERANCE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/geometry_review.config.tcl|generic_design::METAL_COLOR_TARGETS|FILL_IN_generic_design_METAL_COLOR_TARGETS|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/geometry_review.config.tcl|metal_density::DENSITY_LIMIT_TABLE|FILL_IN_metal_density_DENSITY_LIMIT_TABLE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/geometry_review.config.tcl|sw_m4_landing::search_margin|FILL_IN_sw_m4_landing_search_margin|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/geometry_review.config.tcl|sw_m4_landing::scan_area_margin|FILL_IN_sw_m4_landing_scan_area_margin|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/geometry_review.config.tcl|sw_m4_landing::verify_area_margin|FILL_IN_sw_m4_landing_verify_area_margin|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/geometry_review.config.tcl|sw_m4_landing::patch_wire_scan_margin|FILL_IN_sw_m4_landing_patch_wire_scan_margin|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/geometry_review.config.tcl|sw_m4_landing::max_patch_width|FILL_IN_sw_m4_landing_max_patch_width|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/geometry_review.config.tcl|sw_m4_landing::max_patch_height|FILL_IN_sw_m4_landing_max_patch_height|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/geometry_review.config.tcl|sw_m4_landing::landing_area_margin|FILL_IN_sw_m4_landing_landing_area_margin|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/geometry_review.config.tcl|edge_switch::fallback_inst_grid|FILL_IN_edge_switch_fallback_inst_grid|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/geometry_review.config.tcl|welltap::normal_interval|FILL_IN_welltap_normal_interval|請填入well tap cell 或對應設定|
|baseline/script/PR/TECH_MV/setup/config/geometry_review.config.tcl|welltap::fallback_site_pitch|FILL_IN_welltap_fallback_site_pitch|請填入well tap cell 或對應設定|
|baseline/script/PR/TECH_MV/setup/config/geometry_review.config.tcl|welltap::fallback_macro_halo|FILL_IN_welltap_fallback_macro_halo|請填入well tap cell 或對應設定|
|baseline/script/PR/TECH_MV/setup/config/geometry_review.config.tcl|bond_pad_boundary::bottom_snap::literal_3|FILL_IN_bond_pad_boundary_bottom_snap_literal_3|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/geometry_review.config.tcl|bond_pad_boundary::bottom_snap::literal_2|FILL_IN_bond_pad_boundary_bottom_snap_literal_2|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/geometry_review.config.tcl|bond_pad_boundary::bottom_snap::literal_1|FILL_IN_bond_pad_boundary_bottom_snap_literal_1|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/geometry_review.config.tcl|bond_pad_boundary::top_snap::literal_3|FILL_IN_bond_pad_boundary_top_snap_literal_3|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/geometry_review.config.tcl|bond_pad_boundary::top_snap::literal_2|FILL_IN_bond_pad_boundary_top_snap_literal_2|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/geometry_review.config.tcl|bond_pad_boundary::top_snap::literal_1|FILL_IN_bond_pad_boundary_top_snap_literal_1|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/geometry_review.config.tcl|power_proc::stripe_max_jog_length|FILL_IN_power_proc_stripe_max_jog_length|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/geometry_review.config.tcl|power_proc::ring_connect_max_jog_length|FILL_IN_power_proc_ring_connect_max_jog_length|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/geometry_review.config.tcl|powerplan::wdt_m5_combined::literal_4|FILL_IN_powerplan_wdt_m5_combined_literal_4|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/geometry_review.config.tcl|powerplan::wdt_m5_combined::literal_3|FILL_IN_powerplan_wdt_m5_combined_literal_3|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/geometry_review.config.tcl|powerplan::wdt_m5_combined::literal_2|FILL_IN_powerplan_wdt_m5_combined_literal_2|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/geometry_review.config.tcl|powerplan::wdt_m5_combined::literal_1|FILL_IN_powerplan_wdt_m5_combined_literal_1|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/ioPADt.rules.template.json|root.rail_defs.CORE POWER.label|FILL_IN_root_rail_defs_CORE_POWER_label|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/ioPADt.rules.template.json|root.rail_defs.IO POWER.label|FILL_IN_root_rail_defs_IO_POWER_label|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/ioPADt.rules.template.json|root.rail_defs.RTE.label|FILL_IN_root_rail_defs_RTE_label|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/ioPADt.rules.json|root.corner_master_family|FILL_IN_root_corner_master_family|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/ioPADt.rules.json|root.master_roles_MASTER_1|FILL_IN_root_master_roles_MASTER_1|請填入對應 I/O／power pad／rail cut cell 名稱作為 JSON key|
|baseline/script/PR/TECH_MV/setup/config/private/ioPADt.rules.json|root.master_roles_MASTER_2|FILL_IN_root_master_roles_MASTER_2|請填入對應 I/O／power pad／rail cut cell 名稱作為 JSON key|
|baseline/script/PR/TECH_MV/setup/config/private/ioPADt.rules.json|root.master_roles_MASTER_3|FILL_IN_root_master_roles_MASTER_3|請填入對應 I/O／power pad／rail cut cell 名稱作為 JSON key|
|baseline/script/PR/TECH_MV/setup/config/private/ioPADt.rules.json|root.master_roles_MASTER_4|FILL_IN_root_master_roles_MASTER_4|請填入對應 I/O／power pad／rail cut cell 名稱作為 JSON key|
|baseline/script/PR/TECH_MV/setup/config/private/ioPADt.rules.json|root.master_roles_MASTER_5|FILL_IN_root_master_roles_MASTER_5|請填入對應 I/O／power pad／rail cut cell 名稱作為 JSON key|
|baseline/script/PR/TECH_MV/setup/config/private/ioPADt.rules.json|root.master_normalization_pattern|FILL_IN_root_master_normalization_pattern|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/ioPADt.rules.json|root.query_master_families.item1|FILL_IN_root_query_master_families_item1|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/ioPADt.rules.json|root.query_master_families.item2|FILL_IN_root_query_master_families_item2|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/ioPADt.rules.json|root.query_master_families.item3|FILL_IN_root_query_master_families_item3|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/ioPADt.rules.json|root.query_master_families.item4|FILL_IN_root_query_master_families_item4|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/ioPADt.rules.json|root.query_master_families.item5|FILL_IN_root_query_master_families_item5|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/ioPADt.rules.json|root.query_master_families.item6|FILL_IN_root_query_master_families_item6|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/ioPADt.rules.json|root.query_confirmed_families.item1|FILL_IN_root_query_confirmed_families_item1|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/ioPADt.rules.json|root.query_confirmed_families.item2|FILL_IN_root_query_confirmed_families_item2|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/ioPADt.rules.json|root.query_confirmed_families.item3|FILL_IN_root_query_confirmed_families_item3|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/ioPADt.rules.json|root.query_confirmed_families.item4|FILL_IN_root_query_confirmed_families_item4|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/ioPADt.rules.json|root.query_confirmed_families.item5|FILL_IN_root_query_confirmed_families_item5|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/ioPADt.rules.json|root.signatures.boundary_pg_exact.item1|FILL_IN_root_signatures_boundary_pg_exact_item1|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/ioPADt.rules.json|root.signatures.boundary_pg_exact.item2|FILL_IN_root_signatures_boundary_pg_exact_item2|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/ioPADt.rules.json|root.signatures.boundary_pg_exact.item3|FILL_IN_root_signatures_boundary_pg_exact_item3|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/ioPADt.rules.json|root.signatures.rte_signal_exact.item1|FILL_IN_root_signatures_rte_signal_exact_item1|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/ioPADt.rules.json|root.signatures.rte_signal_exact.item2|FILL_IN_root_signatures_rte_signal_exact_item2|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/ioPADt.rules.json|root.signatures.signal_required.item1|FILL_IN_root_signatures_signal_required_item1|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/ioPADt.rules.json|root.signatures.signal_required.item2|FILL_IN_root_signatures_signal_required_item2|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/ioPADt.rules.json|root.signatures.power_signal_exact.item1|FILL_IN_root_signatures_power_signal_exact_item1|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/ioPADt.rules.json|root.signatures.power_pg_required.item1|FILL_IN_root_signatures_power_pg_required_item1|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/ioPADt.rules.json|root.signatures.power_pg_required.item2|FILL_IN_root_signatures_power_pg_required_item2|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/ioPADt.rules.json|root.signatures.power_pg_required.item3|FILL_IN_root_signatures_power_pg_required_item3|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/ioPADt.rules.json|root.signatures.power_pg_required.item4|FILL_IN_root_signatures_power_pg_required_item4|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/ioPADt.rules.json|root.rail_defs.CORE POWER.carrier_pin|FILL_IN_root_rail_defs_CORE_POWER_carrier_pin|請填入 library pin 名稱或接腳對應 dict|
|baseline/script/PR/TECH_MV/setup/config/private/ioPADt.rules.json|root.rail_defs.CORE POWER.label|FILL_IN_root_rail_defs_CORE_POWER_label|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/ioPADt.rules.json|root.rail_defs.IO POWER.carrier_pin|FILL_IN_root_rail_defs_IO_POWER_carrier_pin|請填入 library pin 名稱或接腳對應 dict|
|baseline/script/PR/TECH_MV/setup/config/private/ioPADt.rules.json|root.rail_defs.IO POWER.label|FILL_IN_root_rail_defs_IO_POWER_label|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/ioPADt.rules.json|root.rail_defs.RTE.carrier_pin|FILL_IN_root_rail_defs_RTE_carrier_pin|請填入 library pin 名稱或接腳對應 dict|
|baseline/script/PR/TECH_MV/setup/config/private/ioPADt.rules.json|root.rail_defs.RTE.label|FILL_IN_root_rail_defs_RTE_label|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/ioPADt.rules.json|root.domain_exclusive_pins.item1|FILL_IN_root_domain_exclusive_pins_item1|請填入 library pin 名稱或接腳對應 dict|
|baseline/script/PR/TECH_MV/setup/config/private/ioPADt.rules.json|root.domain_exclusive_pins.item2|FILL_IN_root_domain_exclusive_pins_item2|請填入 library pin 名稱或接腳對應 dict|
|baseline/script/PR/TECH_MV/setup/config/private/ioPADt.rules.json|root.domain_exclusive_pins.item3|FILL_IN_root_domain_exclusive_pins_item3|請填入 library pin 名稱或接腳對應 dict|
|baseline/script/PR/TECH_MV/setup/config/private/ioPADt.rules.json|root.domain_exclusive_pins.item4|FILL_IN_root_domain_exclusive_pins_item4|請填入 library pin 名稱或接腳對應 dict|
|baseline/script/PR/TECH_MV/setup/config/private/ioPADt.rules.json|root.domain_exclusive_pins.item5|FILL_IN_root_domain_exclusive_pins_item5|請填入 library pin 名稱或接腳對應 dict|
|baseline/script/PR/TECH_MV/setup/config/private/ioPADt.rules.json|root.domain_consistent_pins.item1|FILL_IN_root_domain_consistent_pins_item1|請填入 library pin 名稱或接腳對應 dict|
|baseline/script/PR/TECH_MV/setup/config/private/ioPADt.rules.json|root.domain_column_pins.vddpst|FILL_IN_root_domain_column_pins_vddpst|請填入 library pin 名稱或接腳對應 dict|
|baseline/script/PR/TECH_MV/setup/config/private/ioPADt.rules.json|root.domain_column_pins.vsspst|FILL_IN_root_domain_column_pins_vsspst|請填入 library pin 名稱或接腳對應 dict|
|baseline/script/PR/TECH_MV/setup/config/private/ioPADt.rules.json|root.domain_column_pins.esd|FILL_IN_root_domain_column_pins_esd|請填入 library pin 名稱或接腳對應 dict|
|baseline/script/PR/TECH_MV/setup/config/private/ioPADt.rules.json|root.domain_column_pins.pocctrl|FILL_IN_root_domain_column_pins_pocctrl|請填入 library pin 名稱或接腳對應 dict|
|baseline/script/PR/TECH_MV/setup/config/private/ioPADt.rules.json|root.domain_column_pins.rte_net|FILL_IN_root_domain_column_pins_rte_net|請填入 library pin 名稱或接腳對應 dict|
|baseline/script/PR/TECH_MV/setup/config/private/ioPADt.rules.json|root.domain_column_pins.vdd|FILL_IN_root_domain_column_pins_vdd|請填入 library pin 名稱或接腳對應 dict|
|baseline/script/PR/TECH_MV/setup/config/private/ioPADt.rules.json|root.expected_rail_pins.CORE POWER|FILL_IN_root_expected_rail_pins_CORE_POWER|請填入 library pin 名稱或接腳對應 dict|
|baseline/script/PR/TECH_MV/setup/config/private/ioPADt.rules.json|root.expected_rail_pins.IO POWER|FILL_IN_root_expected_rail_pins_IO_POWER|請填入 library pin 名稱或接腳對應 dict|
|baseline/script/PR/TECH_MV/setup/config/private/ioPADt.rules.json|root.expected_rail_pins.RTE|FILL_IN_root_expected_rail_pins_RTE|請填入 library pin 名稱或接腳對應 dict|
|baseline/script/PR/TECH_MV/setup/config/private/ioPADt.rules.json|root.ground_expectations.VSS|FILL_IN_root_ground_expectations_VSS|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/ioPADt.rules.json|root.ground_expectations.VSSPST|FILL_IN_root_ground_expectations_VSSPST|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/setup/config/private/ioPADt.rules.json|root.literal_tokens.LITERAL_001|FILL_IN_root_literal_tokens_LITERAL_001|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/private/ioPADt.rules.json|root.literal_tokens.LITERAL_002|FILL_IN_root_literal_tokens_LITERAL_002|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/private/ioPADt.rules.json|root.literal_tokens.LITERAL_003|FILL_IN_root_literal_tokens_LITERAL_003|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/private/ioPADt.rules.json|root.literal_tokens.LITERAL_004|FILL_IN_root_literal_tokens_LITERAL_004|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/private/ioPADt.rules.json|root.literal_tokens.LITERAL_005|FILL_IN_root_literal_tokens_LITERAL_005|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/private/ioPADt.rules.json|root.literal_tokens.LITERAL_006|FILL_IN_root_literal_tokens_LITERAL_006|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/private/ioPADt.rules.json|root.literal_tokens.LITERAL_007|FILL_IN_root_literal_tokens_LITERAL_007|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/private/ioPADt.rules.json|root.literal_tokens.LITERAL_008|FILL_IN_root_literal_tokens_LITERAL_008|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/private/ioPADt.rules.json|root.literal_tokens.LITERAL_009|FILL_IN_root_literal_tokens_LITERAL_009|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/private/ioPADt.rules.json|root.literal_tokens.LITERAL_010|FILL_IN_root_literal_tokens_LITERAL_010|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/private/ioPADt.rules.json|root.literal_tokens.LITERAL_011|FILL_IN_root_literal_tokens_LITERAL_011|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/private/ioPADt.rules.json|root.literal_tokens.LITERAL_012|FILL_IN_root_literal_tokens_LITERAL_012|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/private/ioPADt.rules.json|root.literal_tokens.LITERAL_013|FILL_IN_root_literal_tokens_LITERAL_013|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/private/ioPADt.rules.json|root.literal_tokens.LITERAL_014|FILL_IN_root_literal_tokens_LITERAL_014|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/private/ioPADt.rules.json|root.literal_tokens.LITERAL_015|FILL_IN_root_literal_tokens_LITERAL_015|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/private/ioPADt.rules.json|root.literal_tokens.LITERAL_016|FILL_IN_root_literal_tokens_LITERAL_016|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/private/ioPADt.rules.json|root.literal_tokens.LITERAL_017|FILL_IN_root_literal_tokens_LITERAL_017|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/script/PR/TECH_MV/setup/config/examples/IOPAD_RING_CONFIG_EXAMPLE.tcl|IOPAD_RING_DOMAIN_CONFIG|FILL_IN_IOPAD_RING_DOMAIN_CONFIG|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/verify/config/private/debug.rules.json|root.source_statement_file|FILL_IN_root_source_statement_file|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/verify/config/private/debug.rules.json|root.switch_master_pattern|FILL_IN_root_switch_master_pattern|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/verify/config/private/debug.rules.json|root.switch_pin_pair_pattern|FILL_IN_root_switch_pin_pair_pattern|請填入 library pin 名稱或接腳對應 dict|
|baseline/script/PR/TECH_MV/verify/config/private/debug.rules.json|root.switch_roles.input|FILL_IN_root_switch_roles_input|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/verify/config/private/debug.rules.json|root.switch_roles.output|FILL_IN_root_switch_roles_output|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/verify/config/private/debug.rules.json|root.switch_roles.switched_power|FILL_IN_root_switch_roles_switched_power|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/verify/config/private/debug.rules.json|root.switch_roles.primary_power|FILL_IN_root_switch_roles_primary_power|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/verify/config/private/debug.rules.json|root.body_pins.item1|FILL_IN_root_body_pins_item1|請填入 library pin 名稱或接腳對應 dict|
|baseline/script/PR/TECH_MV/verify/config/private/debug.rules.json|root.body_pins.item2|FILL_IN_root_body_pins_item2|請填入 library pin 名稱或接腳對應 dict|
|baseline/script/PR/TECH_MV/verify/config/private/debug.rules.json|root.body_pins.item3|FILL_IN_root_body_pins_item3|請填入 library pin 名稱或接腳對應 dict|
|baseline/script/PR/TECH_MV/verify/config/private/debug.rules.json|root.body_pins.item4|FILL_IN_root_body_pins_item4|請填入 library pin 名稱或接腳對應 dict|
|baseline/script/PR/TECH_MV/verify/config/private/debug.rules.json|root.body_pins.item5|FILL_IN_root_body_pins_item5|請填入 library pin 名稱或接腳對應 dict|
|baseline/script/PR/TECH_MV/verify/config/private/debug.rules.json|root.body_scope_description|FILL_IN_root_body_scope_description|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/script/PR/TECH_MV/verify/config/private/hcell_exclude.list|LIST_ITEM_9|FILL_IN_LIST_ITEM_9|請填入此清單所需的 cell 名稱或模型路徑；一行一筆|
|baseline/script/PR/TECH_MV/verify/config/private/hcell_exclude.list|LIST_ITEM_10|FILL_IN_LIST_ITEM_10|請填入此清單所需的 cell 名稱或模型路徑；一行一筆|
|baseline/script/PR/TECH_MV/verify/config/private/hcell_exclude.list|LIST_ITEM_11|FILL_IN_LIST_ITEM_11|請填入此清單所需的 cell 名稱或模型路徑；一行一筆|
|baseline/script/PR/TECH_MV/verify/config/private/hcell_exclude.list|LIST_ITEM_12|FILL_IN_LIST_ITEM_12|請填入此清單所需的 cell 名稱或模型路徑；一行一筆|
|baseline/script/PR/TECH_MV/verify/config/private/hcell_lef.list|LIST_ITEM_4|FILL_IN_LIST_ITEM_4|請填入此清單所需的 cell 名稱或模型路徑；一行一筆|
|baseline/script/PR/TECH_MV/verify/config/private/hcell_lef.list|LIST_ITEM_5|FILL_IN_LIST_ITEM_5|請填入此清單所需的 cell 名稱或模型路徑；一行一筆|
|baseline/script/PR/TECH_MV/verify/config/private/hcell_lef.list|LIST_ITEM_6|FILL_IN_LIST_ITEM_6|請填入此清單所需的 cell 名稱或模型路徑；一行一筆|
|baseline/script/PR/TECH_MV/verify/config/private/hcell_lef.list|LIST_ITEM_7|FILL_IN_LIST_ITEM_7|請填入此清單所需的 cell 名稱或模型路徑；一行一筆|
|baseline/script/PR/TECH_MV/verify/config/private/hcell_lef.list|LIST_ITEM_8|FILL_IN_LIST_ITEM_8|請填入此清單所需的 cell 名稱或模型路徑；一行一筆|
|baseline/script/PR/TECH_MV/verify/config/private/hcell_lef.list|LIST_ITEM_9|FILL_IN_LIST_ITEM_9|請填入此清單所需的 cell 名稱或模型路徑；一行一筆|
|baseline/script/PR/TECH_MV/verify/config/private/hcell_lef.list|LIST_ITEM_10|FILL_IN_LIST_ITEM_10|請填入此清單所需的 cell 名稱或模型路徑；一行一筆|
|baseline/script/PR/TECH_MV/verify/config/private/hcell_lef.list|LIST_ITEM_11|FILL_IN_LIST_ITEM_11|請填入此清單所需的 cell 名稱或模型路徑；一行一筆|
|baseline/script/PR/TECH_MV/verify/config/private/hcell_lef.list|LIST_ITEM_12|FILL_IN_LIST_ITEM_12|請填入此清單所需的 cell 名稱或模型路徑；一行一筆|
|baseline/script/PR/TECH_MV/verify/config/private/hcell_lef.list|LIST_ITEM_13|FILL_IN_LIST_ITEM_13|請填入此清單所需的 cell 名稱或模型路徑；一行一筆|
|baseline/script/PR/TECH_MV/verify/config/private/source_spice.spec|SRAM_SEARCH_21|FILL_IN_SRAM_SEARCH_21|請填入 SRAM cell 模型 subckt 的搜尋關鍵字|
|baseline/script/PR/TECH_MV/verify/config/private/source_spice.spec|SRAM_SEARCH_22|FILL_IN_SRAM_SEARCH_22|請填入 SRAM cell 模型 subckt 的搜尋關鍵字|
|baseline/script/PR/TECH_MV/verify/config/private/source_spice.spec|SRAM_SEARCH_23|FILL_IN_SRAM_SEARCH_23|請填入 SRAM cell 模型 subckt 的搜尋關鍵字|
|baseline/.private_config/TECH_MV/geometry_review.config.tcl|run/tool/02_powerplan/TT_2row_sdp_welltap_after_endcap_v6.tcl::::TT_2ROW_SDP_TAPS_PER_CELL::L71|FILL_IN_run_tool_02_powerplan_TT_2row_sdp_welltap_after_endcap_v6_tcl_TT_2ROW_SDP_TAPS_PER_CELL_L71|請填入well tap cell 或對應設定|
|baseline/.private_config/TECH_MV/geometry_review.config.tcl|run/tool/02_powerplan/TT_2row_sdp_welltap_after_endcap_v6.tcl::::TT_2ROW_SDP_POOL_MARGIN::L73|FILL_IN_run_tool_02_powerplan_TT_2row_sdp_welltap_after_endcap_v6_tcl_TT_2ROW_SDP_POOL_MARGIN_L73|請填入well tap cell 或對應設定|
|baseline/.private_config/TECH_MV/geometry_review.config.tcl|run/tool/02_powerplan/TT_2row_sdp_welltap_source_run_v5.tcl::::TT_2ROW_SDP_TAPS_PER_CELL::L37|FILL_IN_run_tool_02_powerplan_TT_2row_sdp_welltap_source_run_v5_tcl_TT_2ROW_SDP_TAPS_PER_CELL_L37|請填入well tap cell 或對應設定|
|baseline/.private_config/TECH_MV/geometry_review.config.tcl|run/tool/02_powerplan/TT_2row_sdp_welltap_source_run_v5.tcl::::TT_2ROW_SDP_POOL_MARGIN::L39|FILL_IN_run_tool_02_powerplan_TT_2row_sdp_welltap_source_run_v5_tcl_TT_2ROW_SDP_POOL_MARGIN_L39|請填入well tap cell 或對應設定|
|baseline/.private_config/TECH_MV/geometry_review.config.tcl|run/tool/02_powerplan/TT_PR7_coordinate_guided_repair.tcl::::TT_PR7_INTERNAL_GAP_MAX_UM::L43|FILL_IN_run_tool_02_powerplan_TT_PR7_coordinate_guided_repair_tcl_TT_PR7_INTERNAL_GAP_MAX_UM_L43|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/.private_config/TECH_MV/geometry_review.config.tcl|run/tool/02_powerplan/TT_PR7_coordinate_guided_repair.tcl::::TT_PR7_COORD_SITE_PITCH_UM::L47|FILL_IN_run_tool_02_powerplan_TT_PR7_coordinate_guided_repair_tcl_TT_PR7_COORD_SITE_PITCH_UM_L47|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/.private_config/TECH_MV/geometry_review.config.tcl|run/tool/02_powerplan/TT_PR7_coordinate_guided_repair.tcl::::TT_PR7_COORD_TOL::L52|FILL_IN_run_tool_02_powerplan_TT_PR7_coordinate_guided_repair_tcl_TT_PR7_COORD_TOL_L52|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/geometry_review.config.tcl|run/tool/02_powerplan/TT_PR7_coordinate_guided_repair.tcl::::TT_PR7_COORD_SWITCH_GAP_UM::L53|FILL_IN_run_tool_02_powerplan_TT_PR7_coordinate_guided_repair_tcl_TT_PR7_COORD_SWITCH_GAP_UM_L53|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/.private_config/TECH_MV/geometry_review.config.tcl|run/tool/02_powerplan/TT_PR7_manual_sdp_origin.tcl::::TT_PR7_MANUAL_ORIGIN_TOL::L40|FILL_IN_run_tool_02_powerplan_TT_PR7_manual_sdp_origin_tcl_TT_PR7_MANUAL_ORIGIN_TOL_L40|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/geometry_review.config.tcl|run/tool/02_powerplan/TT_proc_create_2row_sdp_welltap.tcl::::TT_2ROW_SDP_TAPS_PER_CELL::L23|FILL_IN_run_tool_02_powerplan_TT_proc_create_2row_sdp_welltap_tcl_TT_2ROW_SDP_TAPS_PER_CELL_L23|請填入well tap cell 或對應設定|
|baseline/.private_config/TECH_MV/geometry_review.config.tcl|run/tool/02_powerplan/TT_proc_create_2row_sdp_welltap.tcl::::TT_2ROW_SDP_POOL_MARGIN::L25|FILL_IN_run_tool_02_powerplan_TT_proc_create_2row_sdp_welltap_tcl_TT_2ROW_SDP_POOL_MARGIN_L25|請填入well tap cell 或對應設定|
|baseline/.private_config/TECH_MV/geometry_review.config.tcl|run/tool/02_powerplan/TT_proc_power_switch_edge_reinforce.tcl::::POWER_SWITCH_EDGE_REINFORCE_PITCH::L61|FILL_IN_run_tool_02_powerplan_TT_proc_power_switch_edge_reinforce_tcl_POWER_SWITCH_EDGE_REINFORCE_PITCH_L61|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/.private_config/TECH_MV/geometry_review.config.tcl|run/tool/02_powerplan/TT_proc_power_switch_edge_reinforce.tcl::::POWER_SWITCH_EDGE_REINFORCE_GAP::L67|FILL_IN_run_tool_02_powerplan_TT_proc_power_switch_edge_reinforce_tcl_POWER_SWITCH_EDGE_REINFORCE_GAP_L67|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/.private_config/TECH_MV/geometry_review.config.tcl|run/tool/02_powerplan/TT_proc_sw_ls_iso_guard.tcl::::TT_SWLS_MIN_GAP_UM::L15|FILL_IN_run_tool_02_powerplan_TT_proc_sw_ls_iso_guard_tcl_TT_SWLS_MIN_GAP_UM_L15|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/.private_config/TECH_MV/geometry_review.config.tcl|run/tool/02_powerplan/TT_refine_internal_gap_sdps.tcl::::TT_PR7_INTERNAL_GAP_MAX_UM::L25|FILL_IN_run_tool_02_powerplan_TT_refine_internal_gap_sdps_tcl_TT_PR7_INTERNAL_GAP_MAX_UM_L25|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/.private_config/TECH_MV/geometry_review.config.tcl|run/tool/02_powerplan/TT_refine_internal_gap_sdps.tcl::::TT_PR7_INTERNAL_GAP_TOL::L26|FILL_IN_run_tool_02_powerplan_TT_refine_internal_gap_sdps_tcl_TT_PR7_INTERNAL_GAP_TOL_L26|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/.private_config/TECH_MV/geometry_review.config.tcl|run/tool/02_powerplan/TT_refine_internal_gap_sdps.tcl::::TT_PR7_GAPBLK_FALLBACK_W::L245|FILL_IN_run_tool_02_powerplan_TT_refine_internal_gap_sdps_tcl_TT_PR7_GAPBLK_FALLBACK_W_L245|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/.private_config/TECH_MV/geometry_review.config.tcl|run/tool/02_powerplan/TT_refine_internal_gap_sdps.tcl::::TT_PR7_GAPBLK_FALLBACK_H::L246|FILL_IN_run_tool_02_powerplan_TT_refine_internal_gap_sdps_tcl_TT_PR7_GAPBLK_FALLBACK_H_L246|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/.private_config/TECH_MV/geometry_review.config.tcl|run/tool/02_powerplan/TT_refine_internal_gap_sdps.tcl::::TT_PR7_GAPBLK_MAX_TRIALS::L247|FILL_IN_run_tool_02_powerplan_TT_refine_internal_gap_sdps_tcl_TT_PR7_GAPBLK_MAX_TRIALS_L247|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/.private_config/TECH_MV/geometry_review.config.tcl|run/tool/02_powerplan/TT_refine_internal_gap_sdps.tcl::::TT_PR7_GAPBLK_NAME_MAX_REVISIONS::L248|FILL_IN_run_tool_02_powerplan_TT_refine_internal_gap_sdps_tcl_TT_PR7_GAPBLK_NAME_MAX_REVISIONS_L248|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/.private_config/TECH_MV/geometry_review.config.tcl|run/tool/02_powerplan/TT_refine_internal_gap_sdps.tcl::::TT_PR7_ORIGIN_SYNC_TOL::L1391|FILL_IN_run_tool_02_powerplan_TT_refine_internal_gap_sdps_tcl_TT_PR7_ORIGIN_SYNC_TOL_L1391|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/.private_config/TECH_MV/geometry_review.config.tcl|run/tool/02_powerplan/TT_repair_internal_sdp_gap.tcl::::TT_2ROW_SDP_INTERNAL_GAP_MAX_SITES::L23|FILL_IN_run_tool_02_powerplan_TT_repair_internal_sdp_gap_tcl_TT_2ROW_SDP_INTERNAL_GAP_MAX_SITES_L23|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/.private_config/TECH_MV/geometry_review.config.tcl|run/tool/02_powerplan/TT_repair_internal_sdp_gap.tcl::::TT_2ROW_SDP_INTERNAL_GAP_TOL_UM::L26|FILL_IN_run_tool_02_powerplan_TT_repair_internal_sdp_gap_tcl_TT_2ROW_SDP_INTERNAL_GAP_TOL_UM_L26|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/.private_config/TECH_MV/geometry_review.config.tcl|run/tool/02_powerplan/TT_repair_powergate_iso_slots.tcl::::TT_SDP_PGISO_TOL::L51|FILL_IN_run_tool_02_powerplan_TT_repair_powergate_iso_slots_tcl_TT_SDP_PGISO_TOL_L51|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/geometry_review.config.tcl|run/tool/02_powerplan/TT_sdp_live_rescue_native_first.tcl::::TT_SDP_RESCUE_GEOM_TOL::L38|FILL_IN_run_tool_02_powerplan_TT_sdp_live_rescue_native_first_tcl_TT_SDP_RESCUE_GEOM_TOL_L38|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/geometry_review.config.tcl|run/tool/02_powerplan/TT_sdp_powergate_row_rules.tcl::::TT_SDP_PGROW_TOL::L56|FILL_IN_run_tool_02_powerplan_TT_sdp_powergate_row_rules_tcl_TT_SDP_PGROW_TOL_L56|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/geometry_review.config.tcl|run/tool/01_floorplan/TT_proc_floorplan_bound_selector.tcl::::FLOORPLAN_IO_PAD_MIN_GAP::L158|FILL_IN_run_tool_01_floorplan_TT_proc_floorplan_bound_selector_tcl_FLOORPLAN_IO_PAD_MIN_GAP_L158|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/.private_config/TECH_MV/geometry_review.config.tcl|run/tool/01_floorplan/TT_proc_floorplan_bound_selector.tcl::::FLOORPLAN_BOUND_MARGIN::L290|FILL_IN_run_tool_01_floorplan_TT_proc_floorplan_bound_selector_tcl_FLOORPLAN_BOUND_MARGIN_L290|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/geometry_review.config.tcl|run/tool/01_floorplan/TT_proc_floorplan_bound_selector.tcl::::FLOORPLAN_IO_PAD_MIN_GAP::L292|FILL_IN_run_tool_01_floorplan_TT_proc_floorplan_bound_selector_tcl_FLOORPLAN_IO_PAD_MIN_GAP_L292|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/.private_config/TECH_MV/geometry_review.config.tcl|run/tool/01_floorplan/TT_proc_trim_powergate_bottom_row.tcl::::TT_SWROW_OFFSET_TOL::L85|FILL_IN_run_tool_01_floorplan_TT_proc_trim_powergate_bottom_row_tcl_TT_SWROW_OFFSET_TOL_L85|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/.private_config/TECH_MV/geometry_review.config.tcl|run/tool/01_floorplan/TT_proc_trim_powergate_bottom_row.tcl::::TT_SWROW_GEOM_TOL::L88|FILL_IN_run_tool_01_floorplan_TT_proc_trim_powergate_bottom_row_tcl_TT_SWROW_GEOM_TOL_L88|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/geometry_review.config.tcl|setup/config/00_design.config.tcl::BOND_PAD_RDL_WIDTH::L87|FILL_IN_setup_config_00_design_config_tcl_BOND_PAD_RDL_WIDTH_L87|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/.private_config/TECH_MV/geometry_review.config.tcl|setup/config/00_design.config.tcl::BOND_PAD_RDL_SPACING::L88|FILL_IN_setup_config_00_design_config_tcl_BOND_PAD_RDL_SPACING_L88|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/.private_config/TECH_MV/geometry_review.config.tcl|setup/config/01_floorplan.config.tcl::IO_CORNER_PAD_OFFSET::L47|FILL_IN_setup_config_01_floorplan_config_tcl_IO_CORNER_PAD_OFFSET_L47|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/.private_config/TECH_MV/geometry_review.config.tcl|setup/config/01_floorplan.config.tcl::MACRO_H_OFFSET::L132|FILL_IN_setup_config_01_floorplan_config_tcl_MACRO_H_OFFSET_L132|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/.private_config/TECH_MV/geometry_review.config.tcl|setup/config/01_floorplan.config.tcl::MACRO_V_OFFSET::L134|FILL_IN_setup_config_01_floorplan_config_tcl_MACRO_V_OFFSET_L134|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/.private_config/TECH_MV/geometry_review.config.tcl|setup/config/01_floorplan.config.tcl::PD_BOUNDARY_ROW_GUARD_WIDTH::L169|FILL_IN_setup_config_01_floorplan_config_tcl_PD_BOUNDARY_ROW_GUARD_WIDTH_L169|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/.private_config/TECH_MV/geometry_review.config.tcl|setup/config/01_floorplan.config.tcl::POWER_SWITCH_LEFT_OFFSET::L303|FILL_IN_setup_config_01_floorplan_config_tcl_POWER_SWITCH_LEFT_OFFSET_L303|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/.private_config/TECH_MV/geometry_review.config.tcl|setup/config/01_floorplan.config.tcl::POWER_SWITCH_RIGHT_OFFSET::L304|FILL_IN_setup_config_01_floorplan_config_tcl_POWER_SWITCH_RIGHT_OFFSET_L304|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/.private_config/TECH_MV/geometry_review.config.tcl|setup/config/01_floorplan.config.tcl::POWER_SWITCH_TOP_OFFSET::L305|FILL_IN_setup_config_01_floorplan_config_tcl_POWER_SWITCH_TOP_OFFSET_L305|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/.private_config/TECH_MV/geometry_review.config.tcl|setup/config/01_floorplan.config.tcl::POWER_SWITCH_BOTTOM_OFFSET::L306|FILL_IN_setup_config_01_floorplan_config_tcl_POWER_SWITCH_BOTTOM_OFFSET_L306|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/.private_config/TECH_MV/geometry_review.config.tcl|setup/config/02_powerplan.config.tcl::POWERPLAN_PAD_PIN_BLOCKAGE_INNER_OFFSET::L26|FILL_IN_setup_config_02_powerplan_config_tcl_POWERPLAN_PAD_PIN_BLOCKAGE_INNER_OFFSET_L26|請填入 library pin 名稱或接腳對應 dict|
|baseline/.private_config/TECH_MV/geometry_review.config.tcl|setup/config/02_powerplan.config.tcl::POWERPLAN_PAD_PIN_BLOCKAGE_OUTER_OFFSET::L27|FILL_IN_setup_config_02_powerplan_config_tcl_POWERPLAN_PAD_PIN_BLOCKAGE_OUTER_OFFSET_L27|請填入 library pin 名稱或接腳對應 dict|
|baseline/.private_config/TECH_MV/geometry_review.config.tcl|setup/config/02_powerplan.config.tcl::PNS_FOLLOW_PIN_VIA_SCALE_HEIGHT::L119|FILL_IN_setup_config_02_powerplan_config_tcl_PNS_FOLLOW_PIN_VIA_SCALE_HEIGHT_L119|請填入 library pin 名稱或接腳對應 dict|
|baseline/.private_config/TECH_MV/geometry_review.config.tcl|setup/config/02_powerplan.config.tcl::PNS_FOLLOW_PIN_VIA_SCALE_WIDTH::L120|FILL_IN_setup_config_02_powerplan_config_tcl_PNS_FOLLOW_PIN_VIA_SCALE_WIDTH_L120|請填入 library pin 名稱或接腳對應 dict|
|baseline/.private_config/TECH_MV/geometry_review.config.tcl|run/tool/02_powerplan/TT_delete_followpin_outside_pd_boundary.tcl::edge_tol::L36|FILL_IN_run_tool_02_powerplan_TT_delete_followpin_outside_pd_boundary_tcl_edge_tol_L36|請填入 library pin 名稱或接腳對應 dict|
|baseline/.private_config/TECH_MV/geometry_review.config.tcl|run/tool/02_powerplan/TT_delete_followpin_outside_pd_boundary.tcl::join_tol::L37|FILL_IN_run_tool_02_powerplan_TT_delete_followpin_outside_pd_boundary_tcl_join_tol_L37|請填入 library pin 名稱或接腳對應 dict|
|baseline/.private_config/TECH_MV/geometry_review.config.tcl|run/tool/02_powerplan/TT_delete_followpin_outside_pd_boundary.tcl::y_tol::L38|FILL_IN_run_tool_02_powerplan_TT_delete_followpin_outside_pd_boundary_tcl_y_tol_L38|請填入 library pin 名稱或接腳對應 dict|
|baseline/.private_config/TECH_MV/geometry_review.config.tcl|run/tool/02_powerplan/TT_delete_followpin_outside_pd_boundary.tcl::query_margin::L39|FILL_IN_run_tool_02_powerplan_TT_delete_followpin_outside_pd_boundary_tcl_query_margin_L39|請填入 library pin 名稱或接腳對應 dict|
|baseline/.private_config/TECH_MV/geometry_review.config.tcl|generic_design::POWER_SWITCH_HORIZONTAL_PITCH|FILL_IN_generic_design_POWER_SWITCH_HORIZONTAL_PITCH|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/.private_config/TECH_MV/geometry_review.config.tcl|generic_design::METAL_COLOR_BBOX_TOLERANCE|FILL_IN_generic_design_METAL_COLOR_BBOX_TOLERANCE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/geometry_review.config.tcl|generic_design::METAL_COLOR_TARGETS|FILL_IN_generic_design_METAL_COLOR_TARGETS|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/geometry_review.config.tcl|metal_density::DENSITY_LIMIT_TABLE|FILL_IN_metal_density_DENSITY_LIMIT_TABLE|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/geometry_review.config.tcl|sw_m4_landing::search_margin|FILL_IN_sw_m4_landing_search_margin|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/geometry_review.config.tcl|sw_m4_landing::scan_area_margin|FILL_IN_sw_m4_landing_scan_area_margin|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/geometry_review.config.tcl|sw_m4_landing::verify_area_margin|FILL_IN_sw_m4_landing_verify_area_margin|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/geometry_review.config.tcl|sw_m4_landing::patch_wire_scan_margin|FILL_IN_sw_m4_landing_patch_wire_scan_margin|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/geometry_review.config.tcl|sw_m4_landing::max_patch_width|FILL_IN_sw_m4_landing_max_patch_width|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/.private_config/TECH_MV/geometry_review.config.tcl|sw_m4_landing::max_patch_height|FILL_IN_sw_m4_landing_max_patch_height|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/geometry_review.config.tcl|sw_m4_landing::landing_area_margin|FILL_IN_sw_m4_landing_landing_area_margin|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/geometry_review.config.tcl|edge_switch::fallback_inst_grid|FILL_IN_edge_switch_fallback_inst_grid|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/.private_config/TECH_MV/geometry_review.config.tcl|welltap::normal_interval|FILL_IN_welltap_normal_interval|請填入well tap cell 或對應設定|
|baseline/.private_config/TECH_MV/geometry_review.config.tcl|welltap::fallback_site_pitch|FILL_IN_welltap_fallback_site_pitch|請填入well tap cell 或對應設定|
|baseline/.private_config/TECH_MV/geometry_review.config.tcl|welltap::fallback_macro_halo|FILL_IN_welltap_fallback_macro_halo|請填入well tap cell 或對應設定|
|baseline/.private_config/TECH_MV/geometry_review.config.tcl|bond_pad_boundary::bottom_snap::literal_3|FILL_IN_bond_pad_boundary_bottom_snap_literal_3|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/.private_config/TECH_MV/geometry_review.config.tcl|bond_pad_boundary::bottom_snap::literal_2|FILL_IN_bond_pad_boundary_bottom_snap_literal_2|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/.private_config/TECH_MV/geometry_review.config.tcl|bond_pad_boundary::bottom_snap::literal_1|FILL_IN_bond_pad_boundary_bottom_snap_literal_1|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/.private_config/TECH_MV/geometry_review.config.tcl|bond_pad_boundary::top_snap::literal_3|FILL_IN_bond_pad_boundary_top_snap_literal_3|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/.private_config/TECH_MV/geometry_review.config.tcl|bond_pad_boundary::top_snap::literal_2|FILL_IN_bond_pad_boundary_top_snap_literal_2|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/.private_config/TECH_MV/geometry_review.config.tcl|bond_pad_boundary::top_snap::literal_1|FILL_IN_bond_pad_boundary_top_snap_literal_1|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/.private_config/TECH_MV/geometry_review.config.tcl|power_proc::stripe_max_jog_length|FILL_IN_power_proc_stripe_max_jog_length|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/.private_config/TECH_MV/geometry_review.config.tcl|power_proc::ring_connect_max_jog_length|FILL_IN_power_proc_ring_connect_max_jog_length|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/.private_config/TECH_MV/geometry_review.config.tcl|powerplan::wdt_m5_combined::literal_4|FILL_IN_powerplan_wdt_m5_combined_literal_4|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/.private_config/TECH_MV/geometry_review.config.tcl|powerplan::wdt_m5_combined::literal_3|FILL_IN_powerplan_wdt_m5_combined_literal_3|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/.private_config/TECH_MV/geometry_review.config.tcl|powerplan::wdt_m5_combined::literal_2|FILL_IN_powerplan_wdt_m5_combined_literal_2|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/.private_config/TECH_MV/geometry_review.config.tcl|powerplan::wdt_m5_combined::literal_1|FILL_IN_powerplan_wdt_m5_combined_literal_1|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/.private_config/TECH_MV/ioPADt.rules.json|root.corner_master_family|FILL_IN_root_corner_master_family|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/ioPADt.rules.json|root.master_roles_MASTER_1|FILL_IN_root_master_roles_MASTER_1|請填入對應 I/O／power pad／rail cut cell 名稱作為 JSON key|
|baseline/.private_config/TECH_MV/ioPADt.rules.json|root.master_roles_MASTER_2|FILL_IN_root_master_roles_MASTER_2|請填入對應 I/O／power pad／rail cut cell 名稱作為 JSON key|
|baseline/.private_config/TECH_MV/ioPADt.rules.json|root.master_roles_MASTER_3|FILL_IN_root_master_roles_MASTER_3|請填入對應 I/O／power pad／rail cut cell 名稱作為 JSON key|
|baseline/.private_config/TECH_MV/ioPADt.rules.json|root.master_roles_MASTER_4|FILL_IN_root_master_roles_MASTER_4|請填入對應 I/O／power pad／rail cut cell 名稱作為 JSON key|
|baseline/.private_config/TECH_MV/ioPADt.rules.json|root.master_roles_MASTER_5|FILL_IN_root_master_roles_MASTER_5|請填入對應 I/O／power pad／rail cut cell 名稱作為 JSON key|
|baseline/.private_config/TECH_MV/ioPADt.rules.json|root.master_normalization_pattern|FILL_IN_root_master_normalization_pattern|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/ioPADt.rules.json|root.query_master_families.item1|FILL_IN_root_query_master_families_item1|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/ioPADt.rules.json|root.query_master_families.item2|FILL_IN_root_query_master_families_item2|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/ioPADt.rules.json|root.query_master_families.item3|FILL_IN_root_query_master_families_item3|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/ioPADt.rules.json|root.query_master_families.item4|FILL_IN_root_query_master_families_item4|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/ioPADt.rules.json|root.query_master_families.item5|FILL_IN_root_query_master_families_item5|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/ioPADt.rules.json|root.query_master_families.item6|FILL_IN_root_query_master_families_item6|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/ioPADt.rules.json|root.query_confirmed_families.item1|FILL_IN_root_query_confirmed_families_item1|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/ioPADt.rules.json|root.query_confirmed_families.item2|FILL_IN_root_query_confirmed_families_item2|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/ioPADt.rules.json|root.query_confirmed_families.item3|FILL_IN_root_query_confirmed_families_item3|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/ioPADt.rules.json|root.query_confirmed_families.item4|FILL_IN_root_query_confirmed_families_item4|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/ioPADt.rules.json|root.query_confirmed_families.item5|FILL_IN_root_query_confirmed_families_item5|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/ioPADt.rules.json|root.signatures.boundary_pg_exact.item1|FILL_IN_root_signatures_boundary_pg_exact_item1|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/ioPADt.rules.json|root.signatures.boundary_pg_exact.item2|FILL_IN_root_signatures_boundary_pg_exact_item2|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/ioPADt.rules.json|root.signatures.boundary_pg_exact.item3|FILL_IN_root_signatures_boundary_pg_exact_item3|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/ioPADt.rules.json|root.signatures.rte_signal_exact.item1|FILL_IN_root_signatures_rte_signal_exact_item1|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/ioPADt.rules.json|root.signatures.rte_signal_exact.item2|FILL_IN_root_signatures_rte_signal_exact_item2|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/ioPADt.rules.json|root.signatures.signal_required.item1|FILL_IN_root_signatures_signal_required_item1|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/ioPADt.rules.json|root.signatures.signal_required.item2|FILL_IN_root_signatures_signal_required_item2|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/ioPADt.rules.json|root.signatures.power_signal_exact.item1|FILL_IN_root_signatures_power_signal_exact_item1|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/ioPADt.rules.json|root.signatures.power_pg_required.item1|FILL_IN_root_signatures_power_pg_required_item1|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/ioPADt.rules.json|root.signatures.power_pg_required.item2|FILL_IN_root_signatures_power_pg_required_item2|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/ioPADt.rules.json|root.signatures.power_pg_required.item3|FILL_IN_root_signatures_power_pg_required_item3|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/ioPADt.rules.json|root.signatures.power_pg_required.item4|FILL_IN_root_signatures_power_pg_required_item4|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/ioPADt.rules.json|root.rail_defs.CORE POWER.carrier_pin|FILL_IN_root_rail_defs_CORE_POWER_carrier_pin|請填入 library pin 名稱或接腳對應 dict|
|baseline/.private_config/TECH_MV/ioPADt.rules.json|root.rail_defs.CORE POWER.label|FILL_IN_root_rail_defs_CORE_POWER_label|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/ioPADt.rules.json|root.rail_defs.IO POWER.carrier_pin|FILL_IN_root_rail_defs_IO_POWER_carrier_pin|請填入 library pin 名稱或接腳對應 dict|
|baseline/.private_config/TECH_MV/ioPADt.rules.json|root.rail_defs.IO POWER.label|FILL_IN_root_rail_defs_IO_POWER_label|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/ioPADt.rules.json|root.rail_defs.RTE.carrier_pin|FILL_IN_root_rail_defs_RTE_carrier_pin|請填入 library pin 名稱或接腳對應 dict|
|baseline/.private_config/TECH_MV/ioPADt.rules.json|root.rail_defs.RTE.label|FILL_IN_root_rail_defs_RTE_label|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/ioPADt.rules.json|root.domain_exclusive_pins.item1|FILL_IN_root_domain_exclusive_pins_item1|請填入 library pin 名稱或接腳對應 dict|
|baseline/.private_config/TECH_MV/ioPADt.rules.json|root.domain_exclusive_pins.item2|FILL_IN_root_domain_exclusive_pins_item2|請填入 library pin 名稱或接腳對應 dict|
|baseline/.private_config/TECH_MV/ioPADt.rules.json|root.domain_exclusive_pins.item3|FILL_IN_root_domain_exclusive_pins_item3|請填入 library pin 名稱或接腳對應 dict|
|baseline/.private_config/TECH_MV/ioPADt.rules.json|root.domain_exclusive_pins.item4|FILL_IN_root_domain_exclusive_pins_item4|請填入 library pin 名稱或接腳對應 dict|
|baseline/.private_config/TECH_MV/ioPADt.rules.json|root.domain_exclusive_pins.item5|FILL_IN_root_domain_exclusive_pins_item5|請填入 library pin 名稱或接腳對應 dict|
|baseline/.private_config/TECH_MV/ioPADt.rules.json|root.domain_consistent_pins.item1|FILL_IN_root_domain_consistent_pins_item1|請填入 library pin 名稱或接腳對應 dict|
|baseline/.private_config/TECH_MV/ioPADt.rules.json|root.domain_column_pins.vddpst|FILL_IN_root_domain_column_pins_vddpst|請填入 library pin 名稱或接腳對應 dict|
|baseline/.private_config/TECH_MV/ioPADt.rules.json|root.domain_column_pins.vsspst|FILL_IN_root_domain_column_pins_vsspst|請填入 library pin 名稱或接腳對應 dict|
|baseline/.private_config/TECH_MV/ioPADt.rules.json|root.domain_column_pins.esd|FILL_IN_root_domain_column_pins_esd|請填入 library pin 名稱或接腳對應 dict|
|baseline/.private_config/TECH_MV/ioPADt.rules.json|root.domain_column_pins.pocctrl|FILL_IN_root_domain_column_pins_pocctrl|請填入 library pin 名稱或接腳對應 dict|
|baseline/.private_config/TECH_MV/ioPADt.rules.json|root.domain_column_pins.rte_net|FILL_IN_root_domain_column_pins_rte_net|請填入 library pin 名稱或接腳對應 dict|
|baseline/.private_config/TECH_MV/ioPADt.rules.json|root.domain_column_pins.vdd|FILL_IN_root_domain_column_pins_vdd|請填入 library pin 名稱或接腳對應 dict|
|baseline/.private_config/TECH_MV/ioPADt.rules.json|root.expected_rail_pins.CORE POWER|FILL_IN_root_expected_rail_pins_CORE_POWER|請填入 library pin 名稱或接腳對應 dict|
|baseline/.private_config/TECH_MV/ioPADt.rules.json|root.expected_rail_pins.IO POWER|FILL_IN_root_expected_rail_pins_IO_POWER|請填入 library pin 名稱或接腳對應 dict|
|baseline/.private_config/TECH_MV/ioPADt.rules.json|root.expected_rail_pins.RTE|FILL_IN_root_expected_rail_pins_RTE|請填入 library pin 名稱或接腳對應 dict|
|baseline/.private_config/TECH_MV/ioPADt.rules.json|root.ground_expectations.VSS|FILL_IN_root_ground_expectations_VSS|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/ioPADt.rules.json|root.ground_expectations.VSSPST|FILL_IN_root_ground_expectations_VSSPST|請依原欄位語意填入本地設定，保留 Tcl／JSON 資料型別|
|baseline/.private_config/TECH_MV/ioPADt.rules.json|root.literal_tokens.LITERAL_001|FILL_IN_root_literal_tokens_LITERAL_001|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/.private_config/TECH_MV/ioPADt.rules.json|root.literal_tokens.LITERAL_002|FILL_IN_root_literal_tokens_LITERAL_002|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/.private_config/TECH_MV/ioPADt.rules.json|root.literal_tokens.LITERAL_003|FILL_IN_root_literal_tokens_LITERAL_003|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/.private_config/TECH_MV/ioPADt.rules.json|root.literal_tokens.LITERAL_004|FILL_IN_root_literal_tokens_LITERAL_004|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/.private_config/TECH_MV/ioPADt.rules.json|root.literal_tokens.LITERAL_005|FILL_IN_root_literal_tokens_LITERAL_005|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/.private_config/TECH_MV/ioPADt.rules.json|root.literal_tokens.LITERAL_006|FILL_IN_root_literal_tokens_LITERAL_006|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/.private_config/TECH_MV/ioPADt.rules.json|root.literal_tokens.LITERAL_007|FILL_IN_root_literal_tokens_LITERAL_007|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/.private_config/TECH_MV/ioPADt.rules.json|root.literal_tokens.LITERAL_008|FILL_IN_root_literal_tokens_LITERAL_008|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/.private_config/TECH_MV/ioPADt.rules.json|root.literal_tokens.LITERAL_009|FILL_IN_root_literal_tokens_LITERAL_009|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/.private_config/TECH_MV/ioPADt.rules.json|root.literal_tokens.LITERAL_010|FILL_IN_root_literal_tokens_LITERAL_010|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/.private_config/TECH_MV/ioPADt.rules.json|root.literal_tokens.LITERAL_011|FILL_IN_root_literal_tokens_LITERAL_011|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/.private_config/TECH_MV/ioPADt.rules.json|root.literal_tokens.LITERAL_012|FILL_IN_root_literal_tokens_LITERAL_012|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/.private_config/TECH_MV/ioPADt.rules.json|root.literal_tokens.LITERAL_013|FILL_IN_root_literal_tokens_LITERAL_013|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/.private_config/TECH_MV/ioPADt.rules.json|root.literal_tokens.LITERAL_014|FILL_IN_root_literal_tokens_LITERAL_014|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/.private_config/TECH_MV/ioPADt.rules.json|root.literal_tokens.LITERAL_015|FILL_IN_root_literal_tokens_LITERAL_015|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/.private_config/TECH_MV/ioPADt.rules.json|root.literal_tokens.LITERAL_016|FILL_IN_root_literal_tokens_LITERAL_016|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/.private_config/TECH_MV/ioPADt.rules.json|root.literal_tokens.LITERAL_017|FILL_IN_root_literal_tokens_LITERAL_017|請填入已確認的幾何值或幾何 dict，單位依呼叫端|
|baseline/Makefile|line 31|FILL_IN_RESOURCE_0001|請填入本地授權資源完整路徑|
|baseline/Makefile|line 150|FILL_IN_RESOURCE_0002|請填入本地授權資源完整路徑|
|baseline/Makefile|line 151|FILL_IN_RESOURCE_0003|請填入本地授權資源完整路徑|
|baseline/Makefile|line 154|FILL_IN_RESOURCE_0004|請填入本地授權資源完整路徑|
|baseline/Makefile|line 158|FILL_IN_RESOURCE_0005|請填入本地授權資源完整路徑|
|baseline/Makefile|line 159|FILL_IN_RESOURCE_0006|請填入本地授權資源完整路徑|
|baseline/Makefile|line 465|FILL_IN_RESOURCE_0007|請填入本地授權資源完整路徑|
|baseline/Makefile|line 467|FILL_IN_RESOURCE_0008|請填入本地授權資源完整路徑|
|baseline/Makefile|line 1052|FILL_IN_RESOURCE_0009|請填入本地授權資源完整路徑|
|baseline/Makefile|line 1053|FILL_IN_RESOURCE_0010|請填入本地授權資源完整路徑|
|baseline/src/src_clean_baseline/CPU/pref/D_Cache.sv|line 529|FILL_IN_CELL_SRAM_001|請填入SRAM（32×32） cell；SRAM 宏實例與模型引用；深度與位寬依名稱，pin、電壓與讀寫行為須核對|
|baseline/src/src_clean_baseline/CPU/pref/D_Cache.sv|line 539|FILL_IN_CELL_SRAM_002|請填入SRAM（32×64） cell；SRAM 宏實例與模型引用；深度與位寬依名稱，pin、電壓與讀寫行為須核對|
|baseline/src/src_clean_baseline/CPU/pref/D_Cache.sv|line 540|FILL_IN_CELL_SRAM_003|請填入SRAM（128×64） cell；SRAM 宏實例與模型引用；深度與位寬依名稱，pin、電壓與讀寫行為須核對|
|baseline/src/src_clean_baseline/CPU/pref/D_Cache.sv|line 550|FILL_IN_CELL_SRAM_002|請填入SRAM（32×64） cell；SRAM 宏實例與模型引用；深度與位寬依名稱，pin、電壓與讀寫行為須核對|
|baseline/src/src_clean_baseline/CPU/pref/D_Cache.sv|line 551|FILL_IN_CELL_SRAM_003|請填入SRAM（128×64） cell；SRAM 宏實例與模型引用；深度與位寬依名稱，pin、電壓與讀寫行為須核對|
|baseline/src/src_clean_baseline/CPU/pref/D_Cache.sv|line 562|FILL_IN_CELL_SRAM_001|請填入SRAM（32×32） cell；SRAM 宏實例與模型引用；深度與位寬依名稱，pin、電壓與讀寫行為須核對|
|baseline/src/src_clean_baseline/CPU/pref/D_Cache.sv|line 573|FILL_IN_CELL_SRAM_002|請填入SRAM（32×64） cell；SRAM 宏實例與模型引用；深度與位寬依名稱，pin、電壓與讀寫行為須核對|
|baseline/src/src_clean_baseline/CPU/pref/D_Cache.sv|line 574|FILL_IN_CELL_SRAM_003|請填入SRAM（128×64） cell；SRAM 宏實例與模型引用；深度與位寬依名稱，pin、電壓與讀寫行為須核對|
|baseline/src/src_clean_baseline/CPU/pref/D_Cache.sv|line 583|FILL_IN_CELL_SRAM_002|請填入SRAM（32×64） cell；SRAM 宏實例與模型引用；深度與位寬依名稱，pin、電壓與讀寫行為須核對|
|baseline/src/src_clean_baseline/CPU/pref/D_Cache.sv|line 584|FILL_IN_CELL_SRAM_003|請填入SRAM（128×64） cell；SRAM 宏實例與模型引用；深度與位寬依名稱，pin、電壓與讀寫行為須核對|
|baseline/src/src_clean_baseline/CPU/pref/D_Cache.sv|line 594|FILL_IN_CELL_SRAM_004|請填入SRAM（32×32） cell；SRAM 宏實例與模型引用；深度與位寬依名稱，pin、電壓與讀寫行為須核對|
|baseline/src/src_clean_baseline/CPU/pref/D_Cache.sv|line 603|FILL_IN_CELL_SRAM_005|請填入SRAM（32×64） cell；SRAM 宏實例與模型引用；深度與位寬依名稱，pin、電壓與讀寫行為須核對|
|baseline/src/src_clean_baseline/CPU/pref/D_Cache.sv|line 604|FILL_IN_CELL_SRAM_003|請填入SRAM（128×64） cell；SRAM 宏實例與模型引用；深度與位寬依名稱，pin、電壓與讀寫行為須核對|
|baseline/src/src_clean_baseline/CPU/pref/D_Cache.sv|line 613|FILL_IN_CELL_SRAM_005|請填入SRAM（32×64） cell；SRAM 宏實例與模型引用；深度與位寬依名稱，pin、電壓與讀寫行為須核對|
|baseline/src/src_clean_baseline/CPU/pref/D_Cache.sv|line 614|FILL_IN_CELL_SRAM_003|請填入SRAM（128×64） cell；SRAM 宏實例與模型引用；深度與位寬依名稱，pin、電壓與讀寫行為須核對|
|baseline/src/src_clean_baseline/CPU/pref/D_Cache.sv|line 624|FILL_IN_CELL_SRAM_004|請填入SRAM（32×32） cell；SRAM 宏實例與模型引用；深度與位寬依名稱，pin、電壓與讀寫行為須核對|
|baseline/src/src_clean_baseline/CPU/pref/D_Cache.sv|line 634|FILL_IN_CELL_SRAM_005|請填入SRAM（32×64） cell；SRAM 宏實例與模型引用；深度與位寬依名稱，pin、電壓與讀寫行為須核對|
|baseline/src/src_clean_baseline/CPU/pref/D_Cache.sv|line 635|FILL_IN_CELL_SRAM_003|請填入SRAM（128×64） cell；SRAM 宏實例與模型引用；深度與位寬依名稱，pin、電壓與讀寫行為須核對|
|baseline/src/src_clean_baseline/CPU/pref/D_Cache.sv|line 643|FILL_IN_CELL_SRAM_005|請填入SRAM（32×64） cell；SRAM 宏實例與模型引用；深度與位寬依名稱，pin、電壓與讀寫行為須核對|
|baseline/src/src_clean_baseline/CPU/pref/D_Cache.sv|line 644|FILL_IN_CELL_SRAM_003|請填入SRAM（128×64） cell；SRAM 宏實例與模型引用；深度與位寬依名稱，pin、電壓與讀寫行為須核對|
|baseline/src/src_clean_baseline/CPU/pref/I_Cache.sv|line 516|FILL_IN_CELL_SRAM_001|請填入SRAM（32×32） cell；SRAM 宏實例與模型引用；深度與位寬依名稱，pin、電壓與讀寫行為須核對|
|baseline/src/src_clean_baseline/CPU/pref/I_Cache.sv|line 526|FILL_IN_CELL_SRAM_002|請填入SRAM（32×64） cell；SRAM 宏實例與模型引用；深度與位寬依名稱，pin、電壓與讀寫行為須核對|
|baseline/src/src_clean_baseline/CPU/pref/I_Cache.sv|line 536|FILL_IN_CELL_SRAM_002|請填入SRAM（32×64） cell；SRAM 宏實例與模型引用；深度與位寬依名稱，pin、電壓與讀寫行為須核對|
|baseline/src/src_clean_baseline/CPU/pref/I_Cache.sv|line 547|FILL_IN_CELL_SRAM_001|請填入SRAM（32×32） cell；SRAM 宏實例與模型引用；深度與位寬依名稱，pin、電壓與讀寫行為須核對|
|baseline/src/src_clean_baseline/CPU/pref/I_Cache.sv|line 558|FILL_IN_CELL_SRAM_002|請填入SRAM（32×64） cell；SRAM 宏實例與模型引用；深度與位寬依名稱，pin、電壓與讀寫行為須核對|
|baseline/src/src_clean_baseline/CPU/pref/I_Cache.sv|line 568|FILL_IN_CELL_SRAM_002|請填入SRAM（32×64） cell；SRAM 宏實例與模型引用；深度與位寬依名稱，pin、電壓與讀寫行為須核對|
|baseline/src/src_clean_baseline/CPU/pref/I_Cache.sv|line 580|FILL_IN_CELL_SRAM_004|請填入SRAM（32×32） cell；SRAM 宏實例與模型引用；深度與位寬依名稱，pin、電壓與讀寫行為須核對|
|baseline/src/src_clean_baseline/CPU/pref/I_Cache.sv|line 589|FILL_IN_CELL_SRAM_005|請填入SRAM（32×64） cell；SRAM 宏實例與模型引用；深度與位寬依名稱，pin、電壓與讀寫行為須核對|
|baseline/src/src_clean_baseline/CPU/pref/I_Cache.sv|line 598|FILL_IN_CELL_SRAM_005|請填入SRAM（32×64） cell；SRAM 宏實例與模型引用；深度與位寬依名稱，pin、電壓與讀寫行為須核對|
|baseline/src/src_clean_baseline/CPU/pref/I_Cache.sv|line 607|FILL_IN_CELL_SRAM_004|請填入SRAM（32×32） cell；SRAM 宏實例與模型引用；深度與位寬依名稱，pin、電壓與讀寫行為須核對|
|baseline/src/src_clean_baseline/CPU/pref/I_Cache.sv|line 617|FILL_IN_CELL_SRAM_005|請填入SRAM（32×64） cell；SRAM 宏實例與模型引用；深度與位寬依名稱，pin、電壓與讀寫行為須核對|
|baseline/src/src_clean_baseline/CPU/pref/I_Cache.sv|line 626|FILL_IN_CELL_SRAM_005|請填入SRAM（32×64） cell；SRAM 宏實例與模型引用；深度與位寬依名稱，pin、電壓與讀寫行為須核對|
|baseline/src/src_clean_baseline/IP/MEM/SRAM_wrapper.sv|line 94|FILL_IN_CELL_SRAM_006|請填入SRAM（16384×32） cell；SRAM 宏實例與模型引用；深度與位寬依名稱，pin、電壓與讀寫行為須核對|
|baseline/src/src_clean_baseline/IP/MEM/SRAM_wrapper.sv|line 113|FILL_IN_CELL_SRAM_007|請填入SRAM（16384×32） cell；SRAM 宏實例與模型引用；深度與位寬依名稱，pin、電壓與讀寫行為須核對|
|baseline/src/src_clean_baseline/IP/TD/DVFS_unit.sv|line 67|FILL_IN_CELL_CLOCK_MUX_008|請填入clock mux cell；依 I0/I1/S/Z 連接與時脈選擇用途判定|
|baseline/src/src_clean_baseline/IP/TD/DVFS_unit.sv|line 68|FILL_IN_CELL_ICG_009|請填入integrated clock gating（ICG）cell；依 TE/E/CP/Q 連接與 ICG 實例用途判定|
|baseline/src/src_clean_baseline/IP/TD/DVFS_unit.sv|line 726|FILL_IN_CELL_ICG_009|請填入integrated clock gating（ICG）cell；依 TE/E/CP/Q 連接與 ICG 實例用途判定|
|baseline/src/src_clean_baseline/IP/TD/DVFS_unit.sv|line 734|FILL_IN_CELL_ICG_009|請填入integrated clock gating（ICG）cell；依 TE/E/CP/Q 連接與 ICG 實例用途判定|
|baseline/src/src_clean_baseline/IP/TD/DVFS_unit.sv|line 742|FILL_IN_CELL_ICG_009|請填入integrated clock gating（ICG）cell；依 TE/E/CP/Q 連接與 ICG 實例用途判定|
|baseline/src/src_clean_baseline/IP/TD/DVFS_unit.sv|line 750|FILL_IN_CELL_ICG_009|請填入integrated clock gating（ICG）cell；依 TE/E/CP/Q 連接與 ICG 實例用途判定|
|baseline/src/src_clean_baseline/IP/TD/DVFS_unit.sv|line 765|FILL_IN_CELL_CLOCK_MUX_008|請填入clock mux cell；依 I0/I1/S/Z 連接與時脈選擇用途判定|
|baseline/src/src_clean_baseline/IP/TD/DVFS_unit.sv|line 773|FILL_IN_CELL_CLOCK_MUX_008|請填入clock mux cell；依 I0/I1/S/Z 連接與時脈選擇用途判定|
|baseline/src/src_clean_baseline/IP/TD/DVFS_unit.sv|line 781|FILL_IN_CELL_CLOCK_MUX_008|請填入clock mux cell；依 I0/I1/S/Z 連接與時脈選擇用途判定|
|baseline/src/src_clean_baseline/IP/TD/TD_loacal_unit.sv|line 101|FILL_IN_CELL_DFF_ASYNC_SET_RESET_010|請填入具非同步 set/reset 的 D flip-flop cell；依 D/CP/CDN/SDN 接腳與程式註解判定；控制極性須核對模型|
|baseline/src/src_clean_baseline/IP/TD/TD_loacal_unit.sv|line 108|FILL_IN_CELL_DFF_ASYNC_SET_RESET_010|請填入具非同步 set/reset 的 D flip-flop cell；依 D/CP/CDN/SDN 接腳與程式註解判定；控制極性須核對模型|
|baseline/src/src_clean_baseline/IP/TD/TD_loacal_unit.sv|line 120|FILL_IN_CELL_DELAY_011|請填入delay cell；依 delay chain 中的 I/Z 連接判定；不可從名稱推定實際延遲|
|baseline/src/src_clean_baseline/IP/TD/TD_loacal_unit.sv|line 151|FILL_IN_CELL_DFF_ASYNC_SET_RESET_010|請填入具非同步 set/reset 的 D flip-flop cell；依 D/CP/CDN/SDN 接腳與程式註解判定；控制極性須核對模型|
|baseline/src/src_clean_baseline/IP/TD/TD_loacal_unit.sv|line 414|FILL_IN_CELL_DELAY_011|請填入delay cell；依 delay chain 中的 I/Z 連接判定；不可從名稱推定實際延遲|
|baseline/src/src_clean_baseline/IP/TD/TD_local_unit_behavior.sv|line 101|FILL_IN_CELL_DFF_ASYNC_SET_RESET_010|請填入具非同步 set/reset 的 D flip-flop cell；依 D/CP/CDN/SDN 接腳與程式註解判定；控制極性須核對模型|
|baseline/src/src_clean_baseline/IP/TD/TD_local_unit_behavior.sv|line 108|FILL_IN_CELL_DFF_ASYNC_SET_RESET_010|請填入具非同步 set/reset 的 D flip-flop cell；依 D/CP/CDN/SDN 接腳與程式註解判定；控制極性須核對模型|
|baseline/src/src_clean_baseline/IP/TD/TD_local_unit_behavior.sv|line 120|FILL_IN_CELL_DELAY_011|請填入delay cell；依 delay chain 中的 I/Z 連接判定；不可從名稱推定實際延遲|
|baseline/src/src_clean_baseline/IP/TD/TD_local_unit_behavior.sv|line 151|FILL_IN_CELL_DFF_ASYNC_SET_RESET_010|請填入具非同步 set/reset 的 D flip-flop cell；依 D/CP/CDN/SDN 接腳與程式註解判定；控制極性須核對模型|
|baseline/src/src_clean_baseline/IP/TD/TD_local_unit_behavior.sv|line 414|FILL_IN_CELL_DELAY_011|請填入delay cell；依 delay chain 中的 I/Z 連接判定；不可從名稱推定實際延遲|
|baseline/src/src_clean_baseline/IP/TD/delay_chain.sv|line 73|FILL_IN_CELL_DELAY_011|請填入delay cell；依 delay chain 中的 I/Z 連接判定；不可從名稱推定實際延遲|
|baseline/src/src_clean_baseline/IP/WDT/WDT_wrapper.sv|line 5|FILL_IN_CELL_SRAM_012|請填入SRAM（512×45） cell；SRAM 宏實例與模型引用；深度與位寬依名稱，pin、電壓與讀寫行為須核對|
|baseline/src/src_clean_baseline/TU/CHIP.v|line 79|FILL_IN_CELL_RTE_BOUNDARY_PAD_013|請填入RTE 邊界 pad cell；依 boundary／RTE rail 操作用途推定；精確電氣功能待 library 確認|
|baseline/src/src_clean_baseline/TU/CHIP.v|line 80|FILL_IN_CELL_IO_POWER_PAD_014|請填入I/O power pad cell；依 VDDPST/VSSPST pin map 判定；POC 型號附加功能須確認|
|baseline/src/src_clean_baseline/TU/CHIP.v|line 85|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/src/src_clean_baseline/TU/CHIP.v|line 89|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/src/src_clean_baseline/TU/CHIP.v|line 93|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/src/src_clean_baseline/TU/CHIP.v|line 97|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/src/src_clean_baseline/TU/CHIP.v|line 106|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/src/src_clean_baseline/TU/CHIP.v|line 119|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/src/src_clean_baseline/TU/CHIP.v|line 132|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/src/src_clean_baseline/TU/CHIP.v|line 148|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/src/src_clean_baseline/TU/CHIP.v|line 164|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/src/src_clean_baseline/TU/CHIP.v|line 180|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/src/src_clean_baseline/TU/CHIP.v|line 196|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/src/src_clean_baseline/TU/CHIP.v|line 212|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/src/src_clean_baseline/TU/CHIP.v|line 226|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/src/src_clean_baseline/TU/CHIP.v|line 236|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/src/src_clean_baseline/TU/CHIP.v|line 246|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/src/src_clean_baseline/TU/CHIP.v|line 256|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/src/src_clean_baseline/TU/CHIP.v|line 266|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/src/src_clean_baseline/TU/CHIP.v|line 276|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/src/src_clean_baseline/TU/CHIP.v|line 290|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/src/src_clean_baseline/TU/CHIP.v|line 300|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/src/src_clean_baseline/TU/CHIP.v|line 309|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/src/src_clean_baseline/TU/CHIP.v|line 318|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/src/src_clean_baseline/TU/CHIP.v|line 339|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/src/src_clean_baseline/TU/CHIP.v|line 355|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/src/src_clean_baseline/TU/CHIP.v|line 365|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/src/src_clean_baseline/TU/CHIP.v|line 374|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/src/src_clean_baseline/TU/CHIP.v|line 383|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/src/src_clean_baseline/file_list/lib.f|line 1|FILL_IN_RESOURCE_0011|請填入本地授權資源完整路徑|
|baseline/src/src_clean_baseline/file_list/lib.f|line 2|FILL_IN_RESOURCE_0012|請填入本地授權資源完整路徑|
|baseline/src/src_clean_baseline/file_list/lib.f|line 3|FILL_IN_RESOURCE_0013|請填入本地授權資源完整路徑|
|baseline/src/src_clean_baseline/file_list/lib.f|line 4|FILL_IN_RESOURCE_0014|請填入本地授權資源完整路徑|
|baseline/src/src_clean_baseline/file_list/lib.f|line 5|FILL_IN_RESOURCE_0015|請填入本地授權資源完整路徑|
|baseline/src/src_clean_baseline/file_list/lib.f|line 6|FILL_IN_RESOURCE_0016|請填入本地授權資源完整路徑|
|baseline/src/src_clean_baseline/file_list/lib.f|line 7|FILL_IN_RESOURCE_0017|請填入本地授權資源完整路徑|
|baseline/src/src_clean_baseline/file_list/lib.f|line 8|FILL_IN_RESOURCE_0018|請填入本地授權資源完整路徑|
|baseline/src/src_clean_baseline/file_list/lib.f|line 9|FILL_IN_RESOURCE_0019|請填入本地授權資源完整路徑|
|baseline/src/src_clean_baseline/file_list/lib.f|line 10|FILL_IN_RESOURCE_0020|請填入本地授權資源完整路徑|
|baseline/src/src_clean_baseline/file_list/lib.f|line 11|FILL_IN_RESOURCE_0021|請填入本地授權資源完整路徑|
|baseline/src/src_clean_baseline/file_list/lib.f|line 12|FILL_IN_RESOURCE_0022|請填入本地授權資源完整路徑|
|baseline/src/src_clean_baseline/file_list/lib.f|line 13|FILL_IN_RESOURCE_0023|請填入本地授權資源完整路徑|
|baseline/src/src_clean_baseline/file_list/lib.f|line 14|FILL_IN_RESOURCE_0024|請填入本地授權資源完整路徑|
|baseline/src/src_clean_baseline/file_list/lib.f|line 15|FILL_IN_RESOURCE_0025|請填入本地授權資源完整路徑|
|baseline/src/src_clean_baseline/file_list/lib.f|line 16|FILL_IN_RESOURCE_0026|請填入本地授權資源完整路徑|
|baseline/src/src_clean_baseline/file_list/lib.f|line 17|FILL_IN_RESOURCE_0027|請填入本地授權資源完整路徑|
|baseline/src/src_clean_baseline/file_list/lib.f|line 18|FILL_IN_RESOURCE_0028|請填入本地授權資源完整路徑|
|baseline/src/src_clean_baseline/file_list/lib.f|line 19|FILL_IN_RESOURCE_0029|請填入本地授權資源完整路徑|
|baseline/src/src_clean_baseline/file_list/lib.f|line 20|FILL_IN_RESOURCE_0030|請填入本地授權資源完整路徑|
|baseline/src/src_clean_baseline/file_list/lib.f|line 21|FILL_IN_RESOURCE_0031|請填入本地授權資源完整路徑|
|baseline/src/src_clean_baseline/file_list/lib.f|line 22|FILL_IN_RESOURCE_0032|請填入本地授權資源完整路徑|
|baseline/src/src_clean_baseline/file_list/lib.f|line 23|FILL_IN_RESOURCE_0033|請填入本地授權資源完整路徑|
|baseline/src/src_clean_baseline/file_list/lib.f|line 24|FILL_IN_RESOURCE_0034|請填入本地授權資源完整路徑|
|baseline/src/src_clean_baseline/file_list/lib.f|line 25|FILL_IN_RESOURCE_0035|請填入本地授權資源完整路徑|
|baseline/src/src_clean_baseline/file_list/lib.f|line 26|FILL_IN_RESOURCE_0036|請填入本地授權資源完整路徑|
|baseline/src/src_clean_baseline/file_list/lib.f|line 27|FILL_IN_RESOURCE_0037|請填入本地授權資源完整路徑|
|baseline/src/src_clean_baseline/file_list/mem.f|line 2|FILL_IN_RESOURCE_0038|請填入本地授權資源完整路徑|
|baseline/src/src_clean_baseline/file_list/mem.f|line 3|FILL_IN_RESOURCE_0039|請填入本地授權資源完整路徑|
|baseline/src/src_clean_baseline/file_list/mem.f|line 4|FILL_IN_RESOURCE_0040|請填入本地授權資源完整路徑|
|baseline/src/src_clean_baseline/file_list/rtl_dram.f|line 1|FILL_IN_RESOURCE_0041|請填入本地授權資源完整路徑|
|baseline/src/src_clean_baseline/file_list/rtl_dram.f|line 2|FILL_IN_RESOURCE_0042|請填入本地授權資源完整路徑|
|baseline/sim/filelist/cell.f|line 6|FILL_IN_RESOURCE_0043|請填入本地授權資源完整路徑|
|baseline/sim/filelist/cell.f|line 8|FILL_IN_RESOURCE_0044|請填入本地授權資源完整路徑|
|baseline/sim/filelist/cell.f|line 10|FILL_IN_RESOURCE_0045|請填入本地授權資源完整路徑|
|baseline/sim/filelist/cell.f|line 12|FILL_IN_RESOURCE_0046|請填入本地授權資源完整路徑|
|baseline/sim/filelist/cell.f|line 14|FILL_IN_RESOURCE_0047|請填入本地授權資源完整路徑|
|baseline/sim/filelist/cell.f|line 16|FILL_IN_RESOURCE_0048|請填入本地授權資源完整路徑|
|baseline/sim/filelist/cell.f|line 22|FILL_IN_RESOURCE_0049|請填入本地授權資源完整路徑|
|baseline/sim/filelist/cell.f|line 23|FILL_IN_RESOURCE_0050|請填入本地授權資源完整路徑|
|baseline/sim/filelist/cell.f|line 24|FILL_IN_RESOURCE_0043|請填入本地授權資源完整路徑|
|baseline/sim/filelist/cell.f|line 25|FILL_IN_RESOURCE_0046|請填入本地授權資源完整路徑|
|baseline/sim/filelist/cell.f|line 29|FILL_IN_RESOURCE_0046|請填入本地授權資源完整路徑|
|baseline/sim/filelist/cell.f|line 31|FILL_IN_RESOURCE_0043|請填入本地授權資源完整路徑|
|baseline/sim/filelist/cell.f|line 37|FILL_IN_RESOURCE_0043|請填入本地授權資源完整路徑|
|baseline/sim/filelist/cell.f|line 38|FILL_IN_RESOURCE_0046|請填入本地授權資源完整路徑|
|baseline/sim/filelist/cell.f|line 43|FILL_IN_RESOURCE_0004|請填入本地授權資源完整路徑|
|baseline/sim/filelist/cell.f|line 44|FILL_IN_RESOURCE_0051|請填入本地授權資源完整路徑|
|baseline/sim/filelist/cell.f|line 45|FILL_IN_RESOURCE_0043|請填入本地授權資源完整路徑|
|baseline/sim/filelist/cell.f|line 46|FILL_IN_RESOURCE_0046|請填入本地授權資源完整路徑|
|baseline/sim/filelist/cell.f|line 49|FILL_IN_RESOURCE_0046|請填入本地授權資源完整路徑|
|baseline/sim/filelist/cell.f|line 51|FILL_IN_RESOURCE_0043|請填入本地授權資源完整路徑|
|baseline/sim/filelist/mem.f|line 2|FILL_IN_LIBRARY_0052|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/sim/filelist/mem.f|line 3|FILL_IN_LIBRARY_0053|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/sim/filelist/mem.f|line 4|FILL_IN_LIBRARY_0054|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/sim/tb/tb_testTD.sv|line 17|FILL_IN_RESOURCE_0043|請填入本地授權資源完整路徑|
|baseline/script/DC/synopsys_dc.setup|line 10|FILL_IN_RESOURCE_0055|請填入本地授權資源完整路徑|
|baseline/script/DC/synopsys_dc.setup|line 11|FILL_IN_RESOURCE_0056|請填入本地授權資源完整路徑|
|baseline/script/DC/synopsys_dc.setup|line 16|FILL_IN_LIBRARY_0057|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/DC/synopsys_dc.setup|line 16|FILL_IN_LIBRARY_0058|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/DC/synopsys_dc.setup|line 16|FILL_IN_LIBRARY_0059|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/DC/synopsys_dc.setup|line 16|FILL_IN_LIBRARY_0060|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/DC/synopsys_dc.setup|line 23|FILL_IN_LIBRARY_0061|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/DC/synopsys_dc.setup|line 32|FILL_IN_LIBRARY_0062|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/DC/synopsys_dc.setup|line 47|FILL_IN_RESOURCE_0063|請填入本地授權資源完整路徑|
|baseline/script/DC/synopsys_dc.setup|line 48|FILL_IN_RESOURCE_0064|請填入本地授權資源完整路徑|
|baseline/script/DC/synopsys_dc.setup|line 49|FILL_IN_RESOURCE_0065|請填入本地授權資源完整路徑|
|baseline/script/DC/synopsys_dc.setup|line 51|FILL_IN_RESOURCE_0066|請填入本地授權資源完整路徑|
|baseline/script/DC/synopsys_dc.setup|line 52|FILL_IN_RESOURCE_0067|請填入本地授權資源完整路徑|
|baseline/script/DC/synopsys_dc.setup|line 53|FILL_IN_RESOURCE_0068|請填入本地授權資源完整路徑|
|baseline/script/DC/synopsys_dc.setup|line 54|FILL_IN_RESOURCE_0069|請填入本地授權資源完整路徑|
|baseline/script/DC/synopsys_dc.setup|line 56|FILL_IN_RESOURCE_0070|請填入本地授權資源完整路徑|
|baseline/script/DC/synopsys_dc.setup|line 57|FILL_IN_RESOURCE_0071|請填入本地授權資源完整路徑|
|baseline/script/DC/synopsys_dc.setup|line 59|FILL_IN_RESOURCE_0072|請填入本地授權資源完整路徑|
|baseline/script/DC/synopsys_dc.setup|line 59|FILL_IN_RESOURCE_0073|請填入本地授權資源完整路徑|
|baseline/script/DC/synopsys_dc.setup|line 73|FILL_IN_LIBRARY_0074|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/DC/synopsys_dc.setup|line 74|FILL_IN_LIBRARY_0075|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/DC/synopsys_dc.setup|line 75|FILL_IN_LIBRARY_0076|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/DC/synopsys_dc.setup|line 76|FILL_IN_LIBRARY_0077|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/DC/synopsys_dc.setup|line 77|FILL_IN_LIBRARY_0078|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/DC/synopsys_dc.setup|line 78|FILL_IN_LIBRARY_0079|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/DC/synopsys_dc.setup|line 79|FILL_IN_LIBRARY_0080|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/DC/synopsys_dc.setup|line 80|FILL_IN_LIBRARY_0081|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/DC/synopsys_dc.setup|line 85|FILL_IN_LIBRARY_0082|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/DC/synopsys_dc.setup|line 86|FILL_IN_LIBRARY_0083|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/DC/synopsys_dc.setup|line 87|FILL_IN_LIBRARY_0084|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/DC/synopsys_dc.setup|line 88|FILL_IN_LIBRARY_0085|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/DC/synopsys_dc.setup|line 91|FILL_IN_LIBRARY_0074|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/DC/synopsys_dc.setup|line 92|FILL_IN_LIBRARY_0075|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/DC/synopsys_dc.setup|line 93|FILL_IN_LIBRARY_0076|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/DC/synopsys_dc.setup|line 95|FILL_IN_LIBRARY_0074|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/DC/synopsys_dc.setup|line 96|FILL_IN_LIBRARY_0075|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/DC/synopsys_dc.setup|line 97|FILL_IN_LIBRARY_0076|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/DC/synopsys_dc.setup|line 98|FILL_IN_LIBRARY_0082|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/DC/synopsys_dc.setup|line 99|FILL_IN_LIBRARY_0086|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/DC/synopsys_dc.setup|line 100|FILL_IN_LIBRARY_0087|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/DC/synopsys_dc.setup|line 101|FILL_IN_LIBRARY_0088|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/DC/synopsys_dc.setup|line 109|FILL_IN_LIBRARY_0089|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/DC/synopsys_dc.setup|line 110|FILL_IN_LIBRARY_0090|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/DC/synopsys_dc.setup|line 111|FILL_IN_LIBRARY_0091|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/DC/synopsys_dc.setup|line 112|FILL_IN_LIBRARY_0092|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/DC/synopsys_dc.setup|line 120|FILL_IN_LIBRARY_0074|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/DC/synopsys_dc.setup|line 121|FILL_IN_LIBRARY_0093|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/DC/synopsys_dc.setup|line 123|FILL_IN_LIBRARY_0076|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/DC/synopsys_dc.setup|line 124|FILL_IN_LIBRARY_0094|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/DC/synopsys_dc.setup|line 126|FILL_IN_LIBRARY_0075|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/DC/synopsys_dc.setup|line 127|FILL_IN_LIBRARY_0095|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/DC/synopsys_dc.setup|line 131|FILL_IN_LIBRARY_0081|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/DC/synopsys_dc.setup|line 132|FILL_IN_LIBRARY_0096|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/DC/synopsys_dc.setup|line 134|FILL_IN_LIBRARY_0082|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/DC/synopsys_dc.setup|line 135|FILL_IN_LIBRARY_0097|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/DC/synopsys_dc.setup|line 138|FILL_IN_LIBRARY_0083|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/DC/synopsys_dc.setup|line 139|FILL_IN_LIBRARY_0098|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/DC/synopsys_dc.setup|line 141|FILL_IN_LIBRARY_0084|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/DC/synopsys_dc.setup|line 142|FILL_IN_LIBRARY_0099|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/DC/synopsys_dc.setup|line 144|FILL_IN_LIBRARY_0085|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/DC/synopsys_dc.setup|line 145|FILL_IN_LIBRARY_0100|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/DC/synopsys_dc.setup|line 148|FILL_IN_LIBRARY_0077|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/DC/synopsys_dc.setup|line 149|FILL_IN_LIBRARY_0101|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/DC/synopsys_dc.setup|line 151|FILL_IN_LIBRARY_0078|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/DC/synopsys_dc.setup|line 152|FILL_IN_LIBRARY_0102|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/DC/synopsys_dc.setup|line 155|FILL_IN_LIBRARY_0079|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/DC/synopsys_dc.setup|line 156|FILL_IN_LIBRARY_0103|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/DC/synopsys_dc.setup|line 158|FILL_IN_LIBRARY_0080|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/DC/synopsys_dc.setup|line 159|FILL_IN_LIBRARY_0104|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/DC/synopsys_dc.setup|line 162|FILL_IN_LIBRARY_0074|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/DC/synopsys_dc.setup|line 163|FILL_IN_LIBRARY_0093|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/DC/synopsys_dc.setup|line 165|FILL_IN_LIBRARY_0076|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/DC/synopsys_dc.setup|line 166|FILL_IN_LIBRARY_0094|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/DC/synopsys_dc.setup|line 168|FILL_IN_LIBRARY_0075|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/DC/synopsys_dc.setup|line 169|FILL_IN_LIBRARY_0095|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/DC/standalone/synopsys_dc.setup|line 4|FILL_IN_RESOURCE_0063|請填入本地授權資源完整路徑|
|baseline/script/DC/standalone/synopsys_dc.setup|line 5|FILL_IN_RESOURCE_0064|請填入本地授權資源完整路徑|
|baseline/script/DC/standalone/synopsys_dc.setup|line 6|FILL_IN_RESOURCE_0065|請填入本地授權資源完整路徑|
|baseline/script/DC/standalone/synopsys_dc.setup|line 8|FILL_IN_RESOURCE_0066|請填入本地授權資源完整路徑|
|baseline/script/DC/standalone/synopsys_dc.setup|line 9|FILL_IN_RESOURCE_0105|請填入本地授權資源完整路徑|
|baseline/script/DC/standalone/synopsys_dc.setup|line 10|FILL_IN_RESOURCE_0106|請填入本地授權資源完整路徑|
|baseline/script/DC/standalone/synopsys_dc.setup|line 11|FILL_IN_RESOURCE_0107|請填入本地授權資源完整路徑|
|baseline/script/DC/standalone/synopsys_dc.setup|line 25|FILL_IN_LIBRARY_0081|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/DC/standalone/synopsys_dc.setup|line 30|FILL_IN_LIBRARY_0082|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/DC/standalone/synopsys_dc.setup|line 31|FILL_IN_LIBRARY_0083|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/DC/standalone/synopsys_dc.setup|line 32|FILL_IN_LIBRARY_0084|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/DC/standalone/synopsys_dc.setup|line 33|FILL_IN_LIBRARY_0085|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/DC/standalone/synopsys_dc.setup|line 38|FILL_IN_LIBRARY_0081|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/DC/standalone/synopsys_dc.setup|line 39|FILL_IN_LIBRARY_0096|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/DC/standalone/synopsys_dc.setup|line 41|FILL_IN_LIBRARY_0082|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/DC/standalone/synopsys_dc.setup|line 42|FILL_IN_LIBRARY_0097|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/DC/standalone/synopsys_dc.setup|line 45|FILL_IN_LIBRARY_0083|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/DC/standalone/synopsys_dc.setup|line 46|FILL_IN_LIBRARY_0098|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/DC/standalone/synopsys_dc.setup|line 48|FILL_IN_LIBRARY_0084|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/DC/standalone/synopsys_dc.setup|line 49|FILL_IN_LIBRARY_0099|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/DC/standalone/synopsys_dc.setup|line 51|FILL_IN_LIBRARY_0085|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/DC/standalone/synopsys_dc.setup|line 52|FILL_IN_LIBRARY_0100|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/MV/DVFS/synopsys_dc.setup|line 71|FILL_IN_RESOURCE_0108|請填入本地授權資源完整路徑|
|baseline/script/MV/DVFS/synopsys_dc.setup|line 73|FILL_IN_RESOURCE_0109|請填入本地授權資源完整路徑|
|baseline/script/MV/DVFS/synopsys_dc.setup|line 75|FILL_IN_LIBRARY_0110|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/MV/DVFS/synopsys_dc.setup|line 76|FILL_IN_LIBRARY_0111|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/MV/DVFS/synopsys_dc.setup|line 77|FILL_IN_LIBRARY_0112|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/MV/DVFS/synopsys_dc.setup|line 78|FILL_IN_LIBRARY_0113|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/MV/DVFS/synopsys_dc.setup|line 79|FILL_IN_LIBRARY_0114|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/MV/DVFS/synopsys_dc.setup|line 81|FILL_IN_LIBRARY_0115|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/MV/DVFS/synopsys_dc.setup|line 84|FILL_IN_RESOURCE_0116|請填入本地授權資源完整路徑|
|baseline/script/MV/DVFS/synopsys_dc.setup|line 85|FILL_IN_RESOURCE_0117|請填入本地授權資源完整路徑|
|baseline/script/MV/DVFS/synopsys_dc.setup|line 86|FILL_IN_RESOURCE_0118|請填入本地授權資源完整路徑|
|baseline/script/MV/DVFS/synopsys_dc.setup|line 103|FILL_IN_RESOURCE_0119|請填入本地授權資源完整路徑|
|baseline/script/MV/DVFS/synopsys_dc.setup|line 104|FILL_IN_RESOURCE_0120|請填入本地授權資源完整路徑|
|baseline/script/MV/DVFS/synopsys_dc.setup|line 126|FILL_IN_LIBRARY_0121|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/MV/DVFS/synopsys_dc.setup|line 127|FILL_IN_LIBRARY_0074|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/MV/DVFS/synopsys_dc.setup|line 128|FILL_IN_LIBRARY_0122|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/MV/DVFS/synopsys_dc.setup|line 129|FILL_IN_LIBRARY_0081|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/MV/DVFS/synopsys_dc.setup|line 133|FILL_IN_LIBRARY_0123|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/MV/DVFS/synopsys_dc.setup|line 134|FILL_IN_LIBRARY_0076|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/MV/DVFS/synopsys_dc.setup|line 135|FILL_IN_LIBRARY_0124|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/MV/DVFS/synopsys_dc.setup|line 136|FILL_IN_LIBRARY_0125|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/MV/DVFS/synopsys_dc.setup|line 140|FILL_IN_LIBRARY_0126|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/MV/DVFS/synopsys_dc.setup|line 141|FILL_IN_LIBRARY_0075|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/MV/DVFS/synopsys_dc.setup|line 142|FILL_IN_LIBRARY_0127|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/MV/DVFS/synopsys_dc.setup|line 143|FILL_IN_LIBRARY_0128|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/MV/DVFS/synopsys_dc.setup|line 151|FILL_IN_LIBRARY_0082|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/MV/DVFS/synopsys_dc.setup|line 154|FILL_IN_LIBRARY_0086|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/MV/DVFS/synopsys_dc.setup|line 155|FILL_IN_LIBRARY_0087|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/MV/DVFS/synopsys_dc.setup|line 156|FILL_IN_LIBRARY_0088|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/MV/DVFS/synopsys_dc.setup|line 167|FILL_IN_LIBRARY_0077|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/MV/DVFS/synopsys_dc.setup|line 168|FILL_IN_LIBRARY_0078|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/MV/DVFS/synopsys_dc.setup|line 170|FILL_IN_LIBRARY_0080|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/MV/DVFS/synopsys_dc.setup|line 171|FILL_IN_LIBRARY_0079|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/MV/DVFS/synopsys_dc.setup|line 285|FILL_IN_LIBRARY_0129|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/MV/DVFS/synopsys_dc.setup|line 288|FILL_IN_LIBRARY_0130|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/MV/DVFS/synopsys_dc.setup|line 291|FILL_IN_LIBRARY_0131|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/MV/DVFS/synopsys_dc.setup|line 295|FILL_IN_LIBRARY_0093|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/MV/DVFS/synopsys_dc.setup|line 298|FILL_IN_LIBRARY_0094|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/MV/DVFS/synopsys_dc.setup|line 301|FILL_IN_LIBRARY_0095|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/MV/DVFS/synopsys_dc.setup|line 305|FILL_IN_LIBRARY_0132|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/MV/DVFS/synopsys_dc.setup|line 308|FILL_IN_LIBRARY_0133|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/MV/DVFS/synopsys_dc.setup|line 311|FILL_IN_LIBRARY_0134|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/MV/DVFS/synopsys_dc.setup|line 315|FILL_IN_LIBRARY_0096|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/MV/DVFS/synopsys_dc.setup|line 318|FILL_IN_LIBRARY_0135|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/MV/DVFS/synopsys_dc.setup|line 321|FILL_IN_LIBRARY_0136|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/MV/DVFS/synopsys_dc.setup|line 329|FILL_IN_LIBRARY_0097|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/MV/DVFS/synopsys_dc.setup|line 336|FILL_IN_LIBRARY_0086|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/MV/DVFS/synopsys_dc.setup|line 337|FILL_IN_LIBRARY_0137|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/MV/DVFS/synopsys_dc.setup|line 339|FILL_IN_LIBRARY_0087|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/MV/DVFS/synopsys_dc.setup|line 340|FILL_IN_LIBRARY_0138|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/MV/DVFS/synopsys_dc.setup|line 342|FILL_IN_LIBRARY_0088|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/MV/DVFS/synopsys_dc.setup|line 343|FILL_IN_LIBRARY_0139|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/MV/DVFS/synopsys_dc.setup|line 351|FILL_IN_LIBRARY_0101|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/MV/DVFS/synopsys_dc.setup|line 354|FILL_IN_LIBRARY_0102|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/MV/DVFS/synopsys_dc.setup|line 357|FILL_IN_LIBRARY_0104|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/MV/DVFS/synopsys_dc.setup|line 360|FILL_IN_LIBRARY_0103|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/MV/DVFS/synopsys_dc.setup|line 501|FILL_IN_LIBRARY_0089|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/MV/DVFS/synopsys_dc.setup|line 502|FILL_IN_LIBRARY_0090|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/MV/DVFS/synopsys_dc.setup|line 503|FILL_IN_LIBRARY_0091|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/MV/DVFS/synopsys_dc.setup|line 504|FILL_IN_LIBRARY_0092|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/MV/DVFS/synopsys_dc.setup|line 513|FILL_IN_LIBRARY_0140|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/MV/DVFS/synopsys_dc.setup|line 514|FILL_IN_LIBRARY_0141|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/MV/DVFS/synopsys_dc.setup|line 515|FILL_IN_LIBRARY_0142|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/MV/DVFS/synopsys_dc.setup|line 516|FILL_IN_LIBRARY_0143|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/MV/DVFS/synopsys_dc.setup|line 520|FILL_IN_LIBRARY_0144|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/MV/DVFS/synopsys_dc.setup|line 521|FILL_IN_LIBRARY_0145|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/MV/DVFS/synopsys_dc.setup|line 522|FILL_IN_LIBRARY_0146|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/MV/DVFS/synopsys_dc.setup|line 523|FILL_IN_LIBRARY_0147|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/MV/UPF/CPU_DVFS.sv|line 241|FILL_IN_CELL_RETENTION_DFF_017|請填入retention flip-flop cell；依 UPF retention library 清單判定；scan、控制極性與 save/restore 行為須核對|
|baseline/script/MV/UPF/CPU_DVFS.sv|line 242|FILL_IN_CELL_RETENTION_DFF_018|請填入retention flip-flop cell；依 UPF retention library 清單判定；scan、控制極性與 save/restore 行為須核對|
|baseline/script/MV/UPF/CPU_DVFS.sv|line 243|FILL_IN_CELL_RETENTION_DFF_019|請填入retention flip-flop cell；依 UPF retention library 清單判定；scan、控制極性與 save/restore 行為須核對|
|baseline/script/MV/UPF/CPU_DVFS.sv|line 244|FILL_IN_CELL_RETENTION_DFF_020|請填入retention flip-flop cell；依 UPF retention library 清單判定；scan、控制極性與 save/restore 行為須核對|
|baseline/script/MV/UPF/CPU_DVFS.sv|line 245|FILL_IN_CELL_RETENTION_DFF_021|請填入retention flip-flop cell；依 UPF retention library 清單判定；scan、控制極性與 save/restore 行為須核對|
|baseline/script/MV/UPF/CPU_DVFS.sv|line 246|FILL_IN_CELL_RETENTION_DFF_022|請填入retention flip-flop cell；依 UPF retention library 清單判定；scan、控制極性與 save/restore 行為須核對|
|baseline/script/MV/UPF/CPU_DVFS.sv|line 247|FILL_IN_CELL_RETENTION_DFF_023|請填入retention flip-flop cell；依 UPF retention library 清單判定；scan、控制極性與 save/restore 行為須核對|
|baseline/script/MV/UPF/CPU_DVFS.sv|line 248|FILL_IN_CELL_RETENTION_DFF_024|請填入retention flip-flop cell；依 UPF retention library 清單判定；scan、控制極性與 save/restore 行為須核對|
|baseline/script/MV/UPF/CPU_DVFS.sv|line 249|FILL_IN_CELL_RETENTION_DFF_025|請填入retention flip-flop cell；依 UPF retention library 清單判定；scan、控制極性與 save/restore 行為須核對|
|baseline/script/MV/UPF/CPU_DVFS.sv|line 250|FILL_IN_CELL_RETENTION_DFF_026|請填入retention flip-flop cell；依 UPF retention library 清單判定；scan、控制極性與 save/restore 行為須核對|
|baseline/script/MV/UPF/CPU_DVFS.sv|line 251|FILL_IN_CELL_RETENTION_DFF_027|請填入retention flip-flop cell；依 UPF retention library 清單判定；scan、控制極性與 save/restore 行為須核對|
|baseline/script/MV/UPF/CPU_DVFS.sv|line 252|FILL_IN_CELL_RETENTION_DFF_028|請填入retention flip-flop cell；依 UPF retention library 清單判定；scan、控制極性與 save/restore 行為須核對|
|baseline/script/MV/UPF/CPU_DVFS.sv|line 258|FILL_IN_CELL_POWER_SWITCH_029|請填入header power switch cell；依 power gating／switch chain 用途判定；容量與控制接腳須核對|
|baseline/script/MV/UPF/CPU_DVFS.sv|line 259|FILL_IN_CELL_POWER_SWITCH_030|請填入header power switch cell；依 power gating／switch chain 用途判定；容量與控制接腳須核對|
|baseline/script/MV/UPF/CPU_DVFS.sv|line 260|FILL_IN_CELL_POWER_SWITCH_031|請填入header power switch cell；依 power gating／switch chain 用途判定；容量與控制接腳須核對|
|baseline/script/MV/UPF/CPU_DVFS.sv|line 261|FILL_IN_CELL_POWER_SWITCH_032|請填入header power switch cell；依 power gating／switch chain 用途判定；容量與控制接腳須核對|
|baseline/script/MV/UPF/CPU_DVFS.sv|line 262|FILL_IN_CELL_POWER_SWITCH_033|請填入header power switch cell；依 power gating／switch chain 用途判定；容量與控制接腳須核對|
|baseline/script/MV/UPF/CPU_DVFS.sv|line 263|FILL_IN_CELL_POWER_SWITCH_034|請填入header power switch cell；依 power gating／switch chain 用途判定；容量與控制接腳須核對|
|baseline/script/MV/UPF/CPU_DVFS.sv|line 264|FILL_IN_CELL_POWER_SWITCH_035|請填入header power switch cell；依 power gating／switch chain 用途判定；容量與控制接腳須核對|
|baseline/script/MV/UPF/CPU_DVFS.sv|line 265|FILL_IN_CELL_POWER_SWITCH_036|請填入header power switch cell；依 power gating／switch chain 用途判定；容量與控制接腳須核對|
|baseline/script/MV/UPF/CPU_DVFS.sv|line 266|FILL_IN_CELL_POWER_SWITCH_037|請填入header power switch cell；依 power gating／switch chain 用途判定；容量與控制接腳須核對|
|baseline/script/MV/UPF/CPU_DVFS.sv|line 267|FILL_IN_CELL_POWER_SWITCH_038|請填入header power switch cell；依 power gating／switch chain 用途判定；容量與控制接腳須核對|
|baseline/script/MV/UPF/CPU_DVFS.sv|line 268|FILL_IN_CELL_POWER_SWITCH_039|請填入header power switch cell；依 power gating／switch chain 用途判定；容量與控制接腳須核對|
|baseline/script/MV/UPF/CPU_DVFS.sv|line 269|FILL_IN_CELL_POWER_SWITCH_040|請填入header power switch cell；依 power gating／switch chain 用途判定；容量與控制接腳須核對|
|baseline/script/MV/UPF/CPU_PG.upf|line 139|FILL_IN_CELL_RETENTION_DFF_017|請填入retention flip-flop cell；依 UPF retention library 清單判定；scan、控制極性與 save/restore 行為須核對|
|baseline/script/MV/UPF/CPU_PG.upf|line 140|FILL_IN_CELL_RETENTION_DFF_018|請填入retention flip-flop cell；依 UPF retention library 清單判定；scan、控制極性與 save/restore 行為須核對|
|baseline/script/MV/UPF/CPU_PG.upf|line 141|FILL_IN_CELL_RETENTION_DFF_019|請填入retention flip-flop cell；依 UPF retention library 清單判定；scan、控制極性與 save/restore 行為須核對|
|baseline/script/MV/UPF/CPU_PG.upf|line 142|FILL_IN_CELL_RETENTION_DFF_020|請填入retention flip-flop cell；依 UPF retention library 清單判定；scan、控制極性與 save/restore 行為須核對|
|baseline/script/MV/UPF/CPU_PG.upf|line 143|FILL_IN_CELL_RETENTION_DFF_021|請填入retention flip-flop cell；依 UPF retention library 清單判定；scan、控制極性與 save/restore 行為須核對|
|baseline/script/MV/UPF/CPU_PG.upf|line 144|FILL_IN_CELL_RETENTION_DFF_022|請填入retention flip-flop cell；依 UPF retention library 清單判定；scan、控制極性與 save/restore 行為須核對|
|baseline/script/MV/UPF/CPU_PG.upf|line 145|FILL_IN_CELL_RETENTION_DFF_023|請填入retention flip-flop cell；依 UPF retention library 清單判定；scan、控制極性與 save/restore 行為須核對|
|baseline/script/MV/UPF/CPU_PG.upf|line 146|FILL_IN_CELL_RETENTION_DFF_024|請填入retention flip-flop cell；依 UPF retention library 清單判定；scan、控制極性與 save/restore 行為須核對|
|baseline/script/MV/UPF/CPU_PG.upf|line 147|FILL_IN_CELL_RETENTION_DFF_025|請填入retention flip-flop cell；依 UPF retention library 清單判定；scan、控制極性與 save/restore 行為須核對|
|baseline/script/MV/UPF/CPU_PG.upf|line 148|FILL_IN_CELL_RETENTION_DFF_026|請填入retention flip-flop cell；依 UPF retention library 清單判定；scan、控制極性與 save/restore 行為須核對|
|baseline/script/MV/UPF/CPU_PG.upf|line 149|FILL_IN_CELL_RETENTION_DFF_027|請填入retention flip-flop cell；依 UPF retention library 清單判定；scan、控制極性與 save/restore 行為須核對|
|baseline/script/MV/UPF/CPU_PG.upf|line 150|FILL_IN_CELL_RETENTION_DFF_028|請填入retention flip-flop cell；依 UPF retention library 清單判定；scan、控制極性與 save/restore 行為須核對|
|baseline/script/MV/UPF/CPU_PG.upf|line 155|FILL_IN_CELL_POWER_SWITCH_029|請填入header power switch cell；依 power gating／switch chain 用途判定；容量與控制接腳須核對|
|baseline/script/MV/UPF/CPU_PG.upf|line 156|FILL_IN_CELL_POWER_SWITCH_030|請填入header power switch cell；依 power gating／switch chain 用途判定；容量與控制接腳須核對|
|baseline/script/MV/UPF/CPU_PG.upf|line 157|FILL_IN_CELL_POWER_SWITCH_031|請填入header power switch cell；依 power gating／switch chain 用途判定；容量與控制接腳須核對|
|baseline/script/MV/UPF/CPU_PG.upf|line 158|FILL_IN_CELL_POWER_SWITCH_032|請填入header power switch cell；依 power gating／switch chain 用途判定；容量與控制接腳須核對|
|baseline/script/MV/UPF/CPU_PG.upf|line 159|FILL_IN_CELL_POWER_SWITCH_033|請填入header power switch cell；依 power gating／switch chain 用途判定；容量與控制接腳須核對|
|baseline/script/MV/UPF/CPU_PG.upf|line 160|FILL_IN_CELL_POWER_SWITCH_034|請填入header power switch cell；依 power gating／switch chain 用途判定；容量與控制接腳須核對|
|baseline/script/MV/UPF/CPU_PG.upf|line 161|FILL_IN_CELL_POWER_SWITCH_035|請填入header power switch cell；依 power gating／switch chain 用途判定；容量與控制接腳須核對|
|baseline/script/MV/UPF/CPU_PG.upf|line 162|FILL_IN_CELL_POWER_SWITCH_036|請填入header power switch cell；依 power gating／switch chain 用途判定；容量與控制接腳須核對|
|baseline/script/MV/UPF/CPU_PG.upf|line 163|FILL_IN_CELL_POWER_SWITCH_037|請填入header power switch cell；依 power gating／switch chain 用途判定；容量與控制接腳須核對|
|baseline/script/MV/UPF/CPU_PG.upf|line 164|FILL_IN_CELL_POWER_SWITCH_038|請填入header power switch cell；依 power gating／switch chain 用途判定；容量與控制接腳須核對|
|baseline/script/MV/UPF/CPU_PG.upf|line 165|FILL_IN_CELL_POWER_SWITCH_039|請填入header power switch cell；依 power gating／switch chain 用途判定；容量與控制接腳須核對|
|baseline/script/MV/UPF/CPU_PG.upf|line 166|FILL_IN_CELL_POWER_SWITCH_040|請填入header power switch cell；依 power gating／switch chain 用途判定；容量與控制接腳須核對|
|baseline/script/MV/UPF/WDT_PG.upf|line 91|FILL_IN_CELL_RETENTION_DFF_017|請填入retention flip-flop cell；依 UPF retention library 清單判定；scan、控制極性與 save/restore 行為須核對|
|baseline/script/MV/UPF/WDT_PG.upf|line 91|FILL_IN_CELL_RETENTION_DFF_018|請填入retention flip-flop cell；依 UPF retention library 清單判定；scan、控制極性與 save/restore 行為須核對|
|baseline/script/MV/UPF/WDT_PG.upf|line 91|FILL_IN_CELL_RETENTION_DFF_019|請填入retention flip-flop cell；依 UPF retention library 清單判定；scan、控制極性與 save/restore 行為須核對|
|baseline/script/MV/UPF/WDT_PG.upf|line 91|FILL_IN_CELL_RETENTION_DFF_020|請填入retention flip-flop cell；依 UPF retention library 清單判定；scan、控制極性與 save/restore 行為須核對|
|baseline/script/MV/UPF/WDT_PG.upf|line 91|FILL_IN_CELL_RETENTION_DFF_021|請填入retention flip-flop cell；依 UPF retention library 清單判定；scan、控制極性與 save/restore 行為須核對|
|baseline/script/MV/UPF/WDT_PG.upf|line 91|FILL_IN_CELL_RETENTION_DFF_022|請填入retention flip-flop cell；依 UPF retention library 清單判定；scan、控制極性與 save/restore 行為須核對|
|baseline/script/MV/UPF/WDT_PG.upf|line 91|FILL_IN_CELL_RETENTION_DFF_023|請填入retention flip-flop cell；依 UPF retention library 清單判定；scan、控制極性與 save/restore 行為須核對|
|baseline/script/MV/UPF/WDT_PG.upf|line 91|FILL_IN_CELL_RETENTION_DFF_024|請填入retention flip-flop cell；依 UPF retention library 清單判定；scan、控制極性與 save/restore 行為須核對|
|baseline/script/MV/UPF/WDT_PG.upf|line 91|FILL_IN_CELL_RETENTION_DFF_025|請填入retention flip-flop cell；依 UPF retention library 清單判定；scan、控制極性與 save/restore 行為須核對|
|baseline/script/MV/UPF/WDT_PG.upf|line 91|FILL_IN_CELL_RETENTION_DFF_026|請填入retention flip-flop cell；依 UPF retention library 清單判定；scan、控制極性與 save/restore 行為須核對|
|baseline/script/MV/UPF/WDT_PG.upf|line 91|FILL_IN_CELL_RETENTION_DFF_027|請填入retention flip-flop cell；依 UPF retention library 清單判定；scan、控制極性與 save/restore 行為須核對|
|baseline/script/MV/UPF/WDT_PG.upf|line 91|FILL_IN_CELL_RETENTION_DFF_028|請填入retention flip-flop cell；依 UPF retention library 清單判定；scan、控制極性與 save/restore 行為須核對|
|baseline/script/MV/UPF/WDT_PG.upf|line 119|FILL_IN_CELL_RETENTION_DFF_017|請填入retention flip-flop cell；依 UPF retention library 清單判定；scan、控制極性與 save/restore 行為須核對|
|baseline/script/MV/UPF/WDT_PG.upf|line 120|FILL_IN_CELL_RETENTION_DFF_018|請填入retention flip-flop cell；依 UPF retention library 清單判定；scan、控制極性與 save/restore 行為須核對|
|baseline/script/MV/UPF/WDT_PG.upf|line 121|FILL_IN_CELL_RETENTION_DFF_019|請填入retention flip-flop cell；依 UPF retention library 清單判定；scan、控制極性與 save/restore 行為須核對|
|baseline/script/MV/UPF/WDT_PG.upf|line 122|FILL_IN_CELL_RETENTION_DFF_020|請填入retention flip-flop cell；依 UPF retention library 清單判定；scan、控制極性與 save/restore 行為須核對|
|baseline/script/MV/UPF/WDT_PG.upf|line 123|FILL_IN_CELL_RETENTION_DFF_021|請填入retention flip-flop cell；依 UPF retention library 清單判定；scan、控制極性與 save/restore 行為須核對|
|baseline/script/MV/UPF/WDT_PG.upf|line 124|FILL_IN_CELL_RETENTION_DFF_022|請填入retention flip-flop cell；依 UPF retention library 清單判定；scan、控制極性與 save/restore 行為須核對|
|baseline/script/MV/UPF/WDT_PG.upf|line 125|FILL_IN_CELL_RETENTION_DFF_023|請填入retention flip-flop cell；依 UPF retention library 清單判定；scan、控制極性與 save/restore 行為須核對|
|baseline/script/MV/UPF/WDT_PG.upf|line 126|FILL_IN_CELL_RETENTION_DFF_024|請填入retention flip-flop cell；依 UPF retention library 清單判定；scan、控制極性與 save/restore 行為須核對|
|baseline/script/MV/UPF/WDT_PG.upf|line 127|FILL_IN_CELL_RETENTION_DFF_025|請填入retention flip-flop cell；依 UPF retention library 清單判定；scan、控制極性與 save/restore 行為須核對|
|baseline/script/MV/UPF/WDT_PG.upf|line 128|FILL_IN_CELL_RETENTION_DFF_026|請填入retention flip-flop cell；依 UPF retention library 清單判定；scan、控制極性與 save/restore 行為須核對|
|baseline/script/MV/UPF/WDT_PG.upf|line 129|FILL_IN_CELL_RETENTION_DFF_027|請填入retention flip-flop cell；依 UPF retention library 清單判定；scan、控制極性與 save/restore 行為須核對|
|baseline/script/MV/UPF/WDT_PG.upf|line 130|FILL_IN_CELL_RETENTION_DFF_028|請填入retention flip-flop cell；依 UPF retention library 清單判定；scan、控制極性與 save/restore 行為須核對|
|baseline/script/MV/UPF/WDT_PG.upf|line 135|FILL_IN_CELL_POWER_SWITCH_029|請填入header power switch cell；依 power gating／switch chain 用途判定；容量與控制接腳須核對|
|baseline/script/MV/UPF/WDT_PG.upf|line 136|FILL_IN_CELL_POWER_SWITCH_030|請填入header power switch cell；依 power gating／switch chain 用途判定；容量與控制接腳須核對|
|baseline/script/MV/UPF/WDT_PG.upf|line 137|FILL_IN_CELL_POWER_SWITCH_031|請填入header power switch cell；依 power gating／switch chain 用途判定；容量與控制接腳須核對|
|baseline/script/MV/UPF/WDT_PG.upf|line 138|FILL_IN_CELL_POWER_SWITCH_032|請填入header power switch cell；依 power gating／switch chain 用途判定；容量與控制接腳須核對|
|baseline/script/MV/UPF/WDT_PG.upf|line 139|FILL_IN_CELL_POWER_SWITCH_033|請填入header power switch cell；依 power gating／switch chain 用途判定；容量與控制接腳須核對|
|baseline/script/MV/UPF/WDT_PG.upf|line 140|FILL_IN_CELL_POWER_SWITCH_034|請填入header power switch cell；依 power gating／switch chain 用途判定；容量與控制接腳須核對|
|baseline/script/MV/UPF/WDT_PG.upf|line 141|FILL_IN_CELL_POWER_SWITCH_035|請填入header power switch cell；依 power gating／switch chain 用途判定；容量與控制接腳須核對|
|baseline/script/MV/UPF/WDT_PG.upf|line 142|FILL_IN_CELL_POWER_SWITCH_036|請填入header power switch cell；依 power gating／switch chain 用途判定；容量與控制接腳須核對|
|baseline/script/MV/UPF/WDT_PG.upf|line 143|FILL_IN_CELL_POWER_SWITCH_037|請填入header power switch cell；依 power gating／switch chain 用途判定；容量與控制接腳須核對|
|baseline/script/MV/UPF/WDT_PG.upf|line 144|FILL_IN_CELL_POWER_SWITCH_038|請填入header power switch cell；依 power gating／switch chain 用途判定；容量與控制接腳須核對|
|baseline/script/MV/UPF/WDT_PG.upf|line 145|FILL_IN_CELL_POWER_SWITCH_039|請填入header power switch cell；依 power gating／switch chain 用途判定；容量與控制接腳須核對|
|baseline/script/MV/UPF/WDT_PG.upf|line 146|FILL_IN_CELL_POWER_SWITCH_040|請填入header power switch cell；依 power gating／switch chain 用途判定；容量與控制接腳須核對|
|baseline/script/PR/innovus_startup.tcl|line 5|FILL_IN_RESOURCE_0148|請填入本地授權資源完整路徑|
|baseline/script/PR/TECH_MV/docs/audit/FLOORPLAN_BOUND_MODE_V1_VALIDATION.md|line 96|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/docs/audit/FLOORPLAN_BOUND_MODE_V1_VALIDATION.md|line 97|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/docs/audit/private/FLOORPLAN_UPDATE_V1_VALIDATION.md|line 13|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/docs/audit/private/FLOORPLAN_UPDATE_V1_VALIDATION.md|line 15|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/docs/audit/private/FLOORPLAN_UPDATE_V1_VALIDATION.md|line 16|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/docs/audit/private/FLOORPLAN_UPDATE_V1_VALIDATION.md|line 18|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/docs/audit/private/FLOORPLAN_UPDATE_V1_VALIDATION.md|line 32|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/docs/audit/private/FLOORPLAN_UPDATE_V1_VALIDATION.md|line 38|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/docs/audit/private/FLOORPLAN_UPDATE_V1_VALIDATION.md|line 65|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/docs/audit/private/PARITY_AUDITS.md|line 183|FILL_IN_RESOURCE_0149|請填入本地授權資源完整路徑|
|baseline/script/PR/TECH_MV/docs/audit/private/PARITY_AUDITS.md|line 297|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/docs/audit/private/PARITY_AUDITS.md|line 335|FILL_IN_RESOURCE_0150|請填入本地授權資源完整路徑|
|baseline/script/PR/TECH_MV/docs/audit/private/PARITY_AUDITS.md|line 336|FILL_IN_RESOURCE_0151|請填入本地授權資源完整路徑|
|baseline/script/PR/TECH_MV/docs/audit/private/PARITY_AUDITS.md|line 337|FILL_IN_RESOURCE_0152|請填入本地授權資源完整路徑|
|baseline/script/PR/TECH_MV/docs/audit/private/PARITY_AUDITS.md|line 338|FILL_IN_RESOURCE_0153|請填入本地授權資源完整路徑|
|baseline/script/PR/TECH_MV/docs/audit/private/PARITY_AUDITS.md|line 339|FILL_IN_RESOURCE_0154|請填入本地授權資源完整路徑|
|baseline/script/PR/TECH_MV/docs/audit/private/PARITY_AUDITS.md|line 340|FILL_IN_RESOURCE_0155|請填入本地授權資源完整路徑|
|baseline/script/PR/TECH_MV/docs/audit/private/PARITY_AUDITS.md|line 341|FILL_IN_RESOURCE_0156|請填入本地授權資源完整路徑|
|baseline/script/PR/TECH_MV/docs/audit/private/PARITY_AUDITS.md|line 343|FILL_IN_LIBRARY_0157|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/PR/TECH_MV/docs/audit/private/PARITY_AUDITS.md|line 344|FILL_IN_LIBRARY_0158|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/PR/TECH_MV/docs/audit/private/PARITY_AUDITS.md|line 345|FILL_IN_LIBRARY_0159|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/PR/TECH_MV/docs/audit/private/PARITY_AUDITS.md|line 346|FILL_IN_LIBRARY_0160|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/PR/TECH_MV/docs/audit/private/PARITY_AUDITS.md|line 347|FILL_IN_LIBRARY_0161|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/PR/TECH_MV/docs/audit/private/PARITY_AUDITS.md|line 348|FILL_IN_RESOURCE_0162|請填入本地授權資源完整路徑|
|baseline/script/PR/TECH_MV/docs/audit/private/PARITY_AUDITS.md|line 349|FILL_IN_RESOURCE_0163|請填入本地授權資源完整路徑|
|baseline/script/PR/TECH_MV/docs/audit/private/PARITY_AUDITS.md|line 367|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/docs/audit/private/PARITY_AUDITS.md|line 368|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/docs/audit/private/PARITY_AUDITS.md|line 373|FILL_IN_CELL_CORE_POWER_PAD_042|請填入core power pad cell；依 VDD/VSS pin map 判定|
|baseline/script/PR/TECH_MV/docs/audit/private/PARITY_AUDITS.md|line 374|FILL_IN_CELL_IO_POWER_PAD_043|請填入I/O power pad cell；依 VDDPST/VSSPST pin map 判定；POC 型號附加功能須確認|
|baseline/script/PR/TECH_MV/docs/audit/private/PARITY_AUDITS.md|line 375|FILL_IN_CELL_IO_POWER_PAD_044|請填入I/O power pad cell；依 VDDPST/VSSPST pin map 判定；POC 型號附加功能須確認|
|baseline/script/PR/TECH_MV/docs/audit/private/PARITY_AUDITS.md|line 376|FILL_IN_CELL_ANALOG_POWER_PAD_045|請填入analog power pad cell；依 TACVDD/TACVSS 或 TAVDD/TAVSS pin map 推定|
|baseline/script/PR/TECH_MV/docs/audit/private/PARITY_AUDITS.md|line 377|FILL_IN_CELL_ANALOG_POWER_PAD_046|請填入analog power pad cell；依 TACVDD/TACVSS 或 TAVDD/TAVSS pin map 推定|
|baseline/script/PR/TECH_MV/docs/audit/private/PARITY_AUDITS.md|line 378|FILL_IN_CELL_ANALOG_IO_PAD_047|請填入analog I/O pad cell；依 AIO pin map 推定；確切能力須核對|
|baseline/script/PR/TECH_MV/docs/audit/private/PARITY_AUDITS.md|line 379|FILL_IN_CELL_ANALOG_IO_PAD_048|請填入analog I/O pad cell；依 AIO pin map 推定；確切能力須核對|
|baseline/script/PR/TECH_MV/docs/audit/private/PARITY_AUDITS.md|line 380|FILL_IN_CELL_ANALOG_IO_PAD_049|請填入analog I/O pad cell；依 AIO pin map 推定；確切能力須核對|
|baseline/script/PR/TECH_MV/docs/audit/private/PARITY_AUDITS.md|line 445|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/docs/audit/private/PARITY_AUDITS.md|line 462|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/docs/audit/private/PARITY_AUDITS.md|line 525|FILL_IN_RESOURCE_0164|請填入本地授權資源完整路徑|
|baseline/script/PR/TECH_MV/docs/audit/private/PARITY_AUDITS.md|line 526|FILL_IN_LIBRARY_0165|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/PR/TECH_MV/docs/audit/private/PARITY_AUDITS.md|line 527|FILL_IN_LIBRARY_0166|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/PR/TECH_MV/docs/audit/private/PARITY_AUDITS.md|line 530|FILL_IN_LIBRARY_0167|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/PR/TECH_MV/docs/audit/private/PARITY_AUDITS.md|line 564|FILL_IN_RESOURCE_0164|請填入本地授權資源完整路徑|
|baseline/script/PR/TECH_MV/docs/audit/private/PARITY_AUDITS.md|line 565|FILL_IN_RESOURCE_0168|請填入本地授權資源完整路徑|
|baseline/script/PR/TECH_MV/docs/audit/private/PARITY_AUDITS.md|line 566|FILL_IN_RESOURCE_0169|請填入本地授權資源完整路徑|
|baseline/script/PR/TECH_MV/docs/audit/private/PARITY_AUDITS.md|line 567|FILL_IN_RESOURCE_0170|請填入本地授權資源完整路徑|
|baseline/script/PR/TECH_MV/docs/audit/private/PARITY_AUDITS.md|line 568|FILL_IN_RESOURCE_0171|請填入本地授權資源完整路徑|
|baseline/script/PR/TECH_MV/docs/audit/private/PARITY_AUDITS.md|line 569|FILL_IN_RESOURCE_0172|請填入本地授權資源完整路徑|
|baseline/script/PR/TECH_MV/docs/audit/private/PARITY_AUDITS.md|line 570|FILL_IN_RESOURCE_0173|請填入本地授權資源完整路徑|
|baseline/script/PR/TECH_MV/docs/guides/FLOORPLAN_IO_BONDPAD.md|line 15|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/docs/guides/FLOORPLAN_IO_BONDPAD.md|line 32|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/docs/guides/FLOORPLAN_IO_BONDPAD.md|line 37|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/docs/guides/FLOORPLAN_IO_BONDPAD.md|line 49|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/docs/guides/FLOORPLAN_IO_BONDPAD.md|line 55|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/docs/guides/FLOORPLAN_IO_BONDPAD.md|line 56|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/docs/guides/FLOORPLAN_IO_BONDPAD.md|line 59|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/docs/guides/FLOORPLAN_IO_BONDPAD.md|line 65|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/docs/guides/FLOORPLAN_IO_BONDPAD.md|line 72|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/docs/guides/FLOORPLAN_IO_BONDPAD.md|line 74|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/docs/guides/FLOORPLAN_IO_BONDPAD.md|line 82|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/docs/guides/FLOW_AND_CONFIG.md|line 56|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/docs/guides/FLOW_AND_CONFIG.md|line 60|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/docs/guides/FLOW_AND_CONFIG.md|line 76|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/docs/guides/POWERPLAN.md|line 13|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/docs/guides/POWERPLAN.md|line 50|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/docs/reference/private/FILE_ARCHITECTURE_AND_COMMAND_MAP.md|line 129|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/run/06_finish.tcl|line 48|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/run/06_finish.tcl|line 66|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/run/tool/ioPADt/MANIFEST|line 10|FILL_IN_CELL_DIGITAL_IO_PAD_050|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/run/tool/ioPADt/MANIFEST|line 10|FILL_IN_CELL_RTE_BOUNDARY_PAD_051|請填入RTE 邊界 pad cell；依 boundary／RTE rail 操作用途推定；精確電氣功能待 library 確認|
|baseline/script/PR/TECH_MV/run/tool/ioPADt/MANIFEST|line 10|FILL_IN_CELL_CORE_POWER_PAD_042|請填入core power pad cell；依 VDD/VSS pin map 判定|
|baseline/script/PR/TECH_MV/run/tool/ioPADt/MANIFEST|line 10|FILL_IN_CELL_IO_POWER_PAD_043|請填入I/O power pad cell；依 VDDPST/VSSPST pin map 判定；POC 型號附加功能須確認|
|baseline/script/PR/TECH_MV/run/tool/ioPADt/MANIFEST|line 10|FILL_IN_CELL_IO_RAIL_CUT_052|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/run/tool/ioPADt/MANIFEST|line 11|FILL_IN_CELL_IO_CORNER_053|請填入I/O corner cell；依 pad ring 角落設定判定|
|baseline/script/PR/TECH_MV/run/tool/ioPADt/TT_tool_iopad_gui.py|line 1037|FILL_IN_CELL_RTE_BOUNDARY_PAD_054|請填入RTE 邊界 pad cell；依 boundary／RTE rail 操作用途推定；精確電氣功能待 library 確認|
|baseline/script/PR/TECH_MV/run/tool/ioPADt/TT_tool_iopad_gui.py|line 15402|FILL_IN_CELL_IO_POWER_PAD_055|請填入I/O power pad cell；依 VDDPST/VSSPST pin map 判定；POC 型號附加功能須確認|
|baseline/script/PR/TECH_MV/run/tool/ioPADt/TT_tool_iopad_gui.py|line 17697|FILL_IN_CELL_IO_POWER_PAD_055|請填入I/O power pad cell；依 VDDPST/VSSPST pin map 判定；POC 型號附加功能須確認|
|baseline/script/PR/TECH_MV/run/tool/ioPADt/TT_tool_iopad_gui.py|line 34960|FILL_IN_CELL_RTE_BOUNDARY_PAD_054|請填入RTE 邊界 pad cell；依 boundary／RTE rail 操作用途推定；精確電氣功能待 library 確認|
|baseline/script/PR/TECH_MV/run/tool/ioPADt/private/FORMAL_FLOW_INTEGRATION.txt|line 7|FILL_IN_CELL_DIGITAL_IO_PAD_050|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/run/tool/ioPADt/private/FORMAL_FLOW_INTEGRATION.txt|line 7|FILL_IN_CELL_RTE_BOUNDARY_PAD_051|請填入RTE 邊界 pad cell；依 boundary／RTE rail 操作用途推定；精確電氣功能待 library 確認|
|baseline/script/PR/TECH_MV/run/tool/ioPADt/private/FORMAL_FLOW_INTEGRATION.txt|line 7|FILL_IN_CELL_CORE_POWER_PAD_042|請填入core power pad cell；依 VDD/VSS pin map 判定|
|baseline/script/PR/TECH_MV/run/tool/ioPADt/private/FORMAL_FLOW_INTEGRATION.txt|line 7|FILL_IN_CELL_IO_POWER_PAD_043|請填入I/O power pad cell；依 VDDPST/VSSPST pin map 判定；POC 型號附加功能須確認|
|baseline/script/PR/TECH_MV/run/tool/ioPADt/private/FORMAL_FLOW_INTEGRATION.txt|line 8|FILL_IN_CELL_IO_RAIL_CUT_052|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/run/tool/ioPADt/private/FORMAL_FLOW_INTEGRATION.txt|line 8|FILL_IN_CELL_IO_CORNER_053|請填入I/O corner cell；依 pad ring 角落設定判定|
|baseline/script/PR/TECH_MV/run/tool/ioPADt/private/FORMAL_FLOW_INTEGRATION.txt|line 30|FILL_IN_CELL_IO_RAIL_CUT_052|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/run/tool/ioPADt/private/INSTALL_GUIDE.txt|line 7|FILL_IN_CELL_DIGITAL_IO_PAD_050|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/run/tool/ioPADt/private/INSTALL_GUIDE.txt|line 7|FILL_IN_CELL_RTE_BOUNDARY_PAD_051|請填入RTE 邊界 pad cell；依 boundary／RTE rail 操作用途推定；精確電氣功能待 library 確認|
|baseline/script/PR/TECH_MV/run/tool/ioPADt/private/INSTALL_GUIDE.txt|line 7|FILL_IN_CELL_CORE_POWER_PAD_042|請填入core power pad cell；依 VDD/VSS pin map 判定|
|baseline/script/PR/TECH_MV/run/tool/ioPADt/private/INSTALL_GUIDE.txt|line 7|FILL_IN_CELL_IO_POWER_PAD_043|請填入I/O power pad cell；依 VDDPST/VSSPST pin map 判定；POC 型號附加功能須確認|
|baseline/script/PR/TECH_MV/run/tool/ioPADt/private/INSTALL_GUIDE.txt|line 8|FILL_IN_CELL_IO_RAIL_CUT_052|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/run/tool/ioPADt/private/INSTALL_GUIDE.txt|line 8|FILL_IN_CELL_IO_CORNER_053|請填入I/O corner cell；依 pad ring 角落設定判定|
|baseline/script/PR/TECH_MV/run/tool/ioPADt/private/INSTALL_GUIDE.txt|line 30|FILL_IN_CELL_IO_RAIL_CUT_052|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/run/tool/ioPADt/private/IOPAD#U7a2e#U985e#U4ecb#U7d39.md|line 9|FILL_IN_CELL_IO_RAIL_CUT_052|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/run/tool/ioPADt/private/IOPAD#U7a2e#U985e#U4ecb#U7d39.md|line 210|FILL_IN_CELL_IO_RAIL_CUT_052|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/run/tool/ioPADt/private/IOPAD#U7a2e#U985e#U4ecb#U7d39.md|line 224|FILL_IN_CELL_IO_RAIL_CUT_052|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/run/tool/ioPADt/private/IOPAD#U7a2e#U985e#U4ecb#U7d39.md|line 229|FILL_IN_CELL_IO_RAIL_CUT_052|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/run/tool/ioPADt/private/IOPAD#U7a2e#U985e#U4ecb#U7d39.md|line 233|FILL_IN_CELL_IO_RAIL_CUT_052|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/run/tool/ioPADt/private/IOPAD#U7a2e#U985e#U4ecb#U7d39.md|line 240|FILL_IN_CELL_IO_RAIL_CUT_052|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/run/tool/ioPADt/private/IOPAD#U7a2e#U985e#U4ecb#U7d39.md|line 245|FILL_IN_CELL_IO_RAIL_CUT_052|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/run/tool/ioPADt/private/IOPAD#U7a2e#U985e#U4ecb#U7d39.md|line 253|FILL_IN_CELL_IO_RAIL_CUT_052|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/run/tool/ioPADt/private/IOPAD#U7a2e#U985e#U4ecb#U7d39.md|line 268|FILL_IN_CELL_IO_RAIL_CUT_052|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/run/tool/ioPADt/private/IOPAD#U7a2e#U985e#U4ecb#U7d39.md|line 272|FILL_IN_CELL_IO_RAIL_CUT_052|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/run/tool/ioPADt/private/IOPAD#U7a2e#U985e#U4ecb#U7d39.md|line 339|FILL_IN_CELL_IO_RAIL_CUT_052|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/run/tool/ioPADt/private/IOPAD#U7a2e#U985e#U4ecb#U7d39.md|line 390|FILL_IN_CELL_IO_RAIL_CUT_052|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/run/tool/ioPADt/private/IOPAD#U8aaa#U660e.md|line 9|FILL_IN_CELL_IO_RAIL_CUT_052|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/run/tool/ioPADt/private/IOPAD#U8aaa#U660e.md|line 76|FILL_IN_CELL_IO_RAIL_CUT_052|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/run/tool/ioPADt/private/IOPAD#U8aaa#U660e.md|line 107|FILL_IN_CELL_IO_RAIL_CUT_052|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/run/tool/ioPADt/private/IOPAD#U8aaa#U660e.md|line 487|FILL_IN_CELL_IO_RAIL_CUT_052|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/run/tool/ioPADt/private/IOPAD#U8aaa#U660e.md|line 488|FILL_IN_CELL_IO_RAIL_CUT_052|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/run/tool/ioPADt/private/IOPAD#U8aaa#U660e.md|line 544|FILL_IN_CELL_IO_RAIL_CUT_052|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/run/tool/ioPADt/private/IOPAD#U8aaa#U660e.md|line 545|FILL_IN_CELL_IO_RAIL_CUT_052|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/run/tool/ioPADt/private/IOPAD#U8aaa#U660e.md|line 635|FILL_IN_CELL_IO_RAIL_CUT_052|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/run/tool/ioPADt/private/IOPAD#U8aaa#U660e.md|line 658|FILL_IN_CELL_IO_RAIL_CUT_052|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/run/tool/ioPADt/private/IOPAD#U8aaa#U660e.md|line 676|FILL_IN_CELL_IO_RAIL_CUT_052|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/run/tool/ioPADt/private/IOPAD#U8aaa#U660e.md|line 701|FILL_IN_CELL_IO_RAIL_CUT_052|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/run/tool/ioPADt/private/IOPAD#U8aaa#U660e.md|line 749|FILL_IN_CELL_IO_RAIL_CUT_052|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/run/tool/ioPADt/private/IOPAD#U8aaa#U660e.md|line 1622|FILL_IN_CELL_IO_RAIL_CUT_052|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/run/tool/ioPADt/private/IOPAD#U8aaa#U660e.md|line 1919|FILL_IN_CELL_IO_RAIL_CUT_052|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/run/tool/ioPADt/private/IOPAD#U8aaa#U660e.md|line 4687|FILL_IN_CELL_IO_RAIL_CUT_052|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/run/tool/ioPADt/private/IOPAD#U8aaa#U660e.md|line 4726|FILL_IN_CELL_IO_RAIL_CUT_052|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/run/tool/ioPADt/private/IOPAD#U8aaa#U660e.md|line 4881|FILL_IN_CELL_IO_RAIL_CUT_052|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/run/tool/ioPADt/private/IOPAD#U8aaa#U660e.md|line 5557|FILL_IN_CELL_IO_RAIL_CUT_052|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/run/tool/ioPADt/private/IOPAD_GUIDE.txt|line 7|FILL_IN_CELL_DIGITAL_IO_PAD_050|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/run/tool/ioPADt/private/IOPAD_GUIDE.txt|line 7|FILL_IN_CELL_RTE_BOUNDARY_PAD_051|請填入RTE 邊界 pad cell；依 boundary／RTE rail 操作用途推定；精確電氣功能待 library 確認|
|baseline/script/PR/TECH_MV/run/tool/ioPADt/private/IOPAD_GUIDE.txt|line 7|FILL_IN_CELL_CORE_POWER_PAD_042|請填入core power pad cell；依 VDD/VSS pin map 判定|
|baseline/script/PR/TECH_MV/run/tool/ioPADt/private/IOPAD_GUIDE.txt|line 7|FILL_IN_CELL_IO_POWER_PAD_043|請填入I/O power pad cell；依 VDDPST/VSSPST pin map 判定；POC 型號附加功能須確認|
|baseline/script/PR/TECH_MV/run/tool/ioPADt/private/IOPAD_GUIDE.txt|line 8|FILL_IN_CELL_IO_RAIL_CUT_052|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/run/tool/ioPADt/private/IOPAD_GUIDE.txt|line 8|FILL_IN_CELL_IO_CORNER_053|請填入I/O corner cell；依 pad ring 角落設定判定|
|baseline/script/PR/TECH_MV/run/tool/ioPADt/private/IOPAD_GUIDE.txt|line 30|FILL_IN_CELL_IO_RAIL_CUT_052|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/run/tool/ioPADt/private/IOPAD種類介紹.md|line 199|FILL_IN_CELL_IO_RAIL_CUT_052|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/run/tool/ioPADt/private/IOPAD種類介紹.md|line 213|FILL_IN_CELL_IO_RAIL_CUT_052|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/run/tool/ioPADt/private/IOPAD種類介紹.md|line 218|FILL_IN_CELL_IO_RAIL_CUT_052|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/run/tool/ioPADt/private/IOPAD種類介紹.md|line 222|FILL_IN_CELL_IO_RAIL_CUT_052|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/run/tool/ioPADt/private/IOPAD種類介紹.md|line 229|FILL_IN_CELL_IO_RAIL_CUT_052|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/run/tool/ioPADt/private/IOPAD種類介紹.md|line 234|FILL_IN_CELL_IO_RAIL_CUT_052|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/run/tool/ioPADt/private/IOPAD種類介紹.md|line 242|FILL_IN_CELL_IO_RAIL_CUT_052|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/run/tool/ioPADt/private/IOPAD種類介紹.md|line 257|FILL_IN_CELL_IO_RAIL_CUT_052|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/run/tool/ioPADt/private/IOPAD種類介紹.md|line 261|FILL_IN_CELL_IO_RAIL_CUT_052|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/run/tool/ioPADt/private/IOPAD種類介紹.md|line 328|FILL_IN_CELL_IO_RAIL_CUT_052|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/run/tool/ioPADt/private/IOPAD種類介紹.md|line 379|FILL_IN_CELL_IO_RAIL_CUT_052|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/run/tool/ioPADt/private/IOPAD說明.md|line 65|FILL_IN_CELL_IO_RAIL_CUT_052|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/run/tool/ioPADt/private/IOPAD說明.md|line 96|FILL_IN_CELL_IO_RAIL_CUT_052|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/run/tool/ioPADt/private/IOPAD說明.md|line 476|FILL_IN_CELL_IO_RAIL_CUT_052|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/run/tool/ioPADt/private/IOPAD說明.md|line 477|FILL_IN_CELL_IO_RAIL_CUT_052|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/run/tool/ioPADt/private/IOPAD說明.md|line 533|FILL_IN_CELL_IO_RAIL_CUT_052|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/run/tool/ioPADt/private/IOPAD說明.md|line 534|FILL_IN_CELL_IO_RAIL_CUT_052|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/run/tool/ioPADt/private/IOPAD說明.md|line 624|FILL_IN_CELL_IO_RAIL_CUT_052|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/run/tool/ioPADt/private/IOPAD說明.md|line 647|FILL_IN_CELL_IO_RAIL_CUT_052|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/run/tool/ioPADt/private/IOPAD說明.md|line 665|FILL_IN_CELL_IO_RAIL_CUT_052|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/run/tool/ioPADt/private/IOPAD說明.md|line 690|FILL_IN_CELL_IO_RAIL_CUT_052|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/run/tool/ioPADt/private/IOPAD說明.md|line 738|FILL_IN_CELL_IO_RAIL_CUT_052|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/run/tool/ioPADt/private/IOPAD說明.md|line 1611|FILL_IN_CELL_IO_RAIL_CUT_052|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/run/tool/ioPADt/private/IOPAD說明.md|line 1908|FILL_IN_CELL_IO_RAIL_CUT_052|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/run/tool/ioPADt/private/IOPAD說明.md|line 4676|FILL_IN_CELL_IO_RAIL_CUT_052|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/run/tool/ioPADt/private/IOPAD說明.md|line 4715|FILL_IN_CELL_IO_RAIL_CUT_052|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/run/tool/ioPADt/private/IOPAD說明.md|line 4870|FILL_IN_CELL_IO_RAIL_CUT_052|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/run/tool/ioPADt/private/IOPAD說明.md|line 5546|FILL_IN_CELL_IO_RAIL_CUT_052|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/run/tool/ioPADt/private/README.md|line 7|FILL_IN_CELL_DIGITAL_IO_PAD_050|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/run/tool/ioPADt/private/README.md|line 7|FILL_IN_CELL_RTE_BOUNDARY_PAD_051|請填入RTE 邊界 pad cell；依 boundary／RTE rail 操作用途推定；精確電氣功能待 library 確認|
|baseline/script/PR/TECH_MV/run/tool/ioPADt/private/README.md|line 7|FILL_IN_CELL_CORE_POWER_PAD_042|請填入core power pad cell；依 VDD/VSS pin map 判定|
|baseline/script/PR/TECH_MV/run/tool/ioPADt/private/README.md|line 7|FILL_IN_CELL_IO_POWER_PAD_043|請填入I/O power pad cell；依 VDDPST/VSSPST pin map 判定；POC 型號附加功能須確認|
|baseline/script/PR/TECH_MV/run/tool/ioPADt/private/README.md|line 7|FILL_IN_CELL_IO_RAIL_CUT_052|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/run/tool/ioPADt/private/README.md|line 7|FILL_IN_CELL_IO_CORNER_053|請填入I/O corner cell；依 pad ring 角落設定判定|
|baseline/script/PR/TECH_MV/run/tool/ioPADt/private/README.md|line 34|FILL_IN_CELL_IO_RAIL_CUT_052|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/run/tool/ioPADt/private/README.md|line 858|FILL_IN_CELL_IO_RAIL_CUT_052|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/run/tool/02_powerplan/TT_proc_powerplan_resume.tcl|line 33|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/run/tool/02_powerplan/TT_proc_powerplan_resume.tcl|line 434|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/run/tool/02_powerplan/TT_proc_powerplan_resume.tcl|line 455|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/run/tool/02_powerplan/TT_proc_powerplan_resume.tcl|line 456|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/run/tool/01_floorplan/TT_flow_check_bond_pad.tcl|line 11|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/run/tool/01_floorplan/TT_flow_check_bond_pad.tcl|line 23|FILL_IN_LIBRARY_0174|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/PR/TECH_MV/run/tool/01_floorplan/TT_flow_iopad_interface_start.tcl|line 33|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/run/tool/01_floorplan/TT_proc_bond_pad_preview.tcl|line 17|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/run/tool/01_floorplan/TT_proc_bond_pad_preview.tcl|line 20|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/run/tool/01_floorplan/TT_proc_bond_pad_preview.tcl|line 27|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/run/tool/01_floorplan/TT_proc_bond_pad_preview.tcl|line 42|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/run/tool/01_floorplan/TT_proc_bond_pad_preview.tcl|line 53|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/run/tool/01_floorplan/TT_proc_bond_pad_preview.tcl|line 80|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/run/tool/01_floorplan/TT_proc_bond_pad_preview.tcl|line 97|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/run/tool/01_floorplan/TT_proc_bond_pad_preview.tcl|line 136|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/run/tool/01_floorplan/TT_proc_bond_pad_preview.tcl|line 178|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/run/tool/01_floorplan/TT_proc_bond_pad_preview.tcl|line 194|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/run/tool/01_floorplan/TT_proc_bond_pad_preview.tcl|line 364|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/run/tool/01_floorplan/TT_proc_bond_pad_preview.tcl|line 368|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/run/tool/01_floorplan/TT_proc_bond_pad_preview.tcl|line 373|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/run/tool/01_floorplan/TT_proc_bond_pad_preview.tcl|line 443|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/run/tool/01_floorplan/TT_proc_bond_pad_preview.tcl|line 499|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/run/tool/01_floorplan/TT_proc_bond_pad_preview.tcl|line 523|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/run/tool/01_floorplan/TT_proc_bond_pad_preview.tcl|line 528|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/run/tool/01_floorplan/TT_proc_bond_pad_preview.tcl|line 531|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/run/tool/01_floorplan/TT_proc_bond_pad_preview.tcl|line 537|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/run/tool/01_floorplan/TT_proc_bond_pad_preview.tcl|line 550|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/run/tool/01_floorplan/TT_proc_bond_pad_preview.tcl|line 576|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/run/tool/01_floorplan/TT_proc_floorplan_resume.tcl|line 33|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/run/tool/01_floorplan/TT_proc_floorplan_resume.tcl|line 280|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/run/tool/01_floorplan/TT_proc_iopad_iofile_check.tcl|line 12|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/run/tool/01_floorplan/TT_proc_iopad_iofile_check.tcl|line 94|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/run/tool/01_floorplan/TT_proc_iopad_iofile_check.tcl|line 96|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/run/tool/01_floorplan/TT_proc_read_gnetpkg.tcl|line 18|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/run/tool/01_floorplan/TT_proc_read_gnetpkg.tcl|line 23|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/script/create_bond_pad_stylus.tcl|line 12|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/script/create_bond_pad_stylus.tcl|line 15|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/script/create_bond_pad_stylus.tcl|line 76|FILL_IN_LIBRARY_0174|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/PR/TECH_MV/script/create_bond_pad_stylus.tcl|line 160|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/script/create_bond_pad_stylus.tcl|line 190|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/script/create_bond_pad_stylus.tcl|line 274|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/script/create_bond_pad_stylus.tcl|line 308|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/script/create_bond_pad_stylus.tcl|line 335|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/script/create_rte_pad.tcl|line 308|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/script/floorplan.tcl|line 424|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/script/floorplan.tcl|line 452|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/script/powerplan.tcl|line 59|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/script/powerplan_stage_tail.tcl|line 162|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/setup/CHIP.io|line 2|FILL_IN_RESOURCE_0175|請填入本地授權資源完整路徑|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED.io|line 11|FILL_IN_RESOURCE_0175|請填入本地授權資源完整路徑|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 23|FILL_IN_RESOURCE_0176|請填入本地授權資源完整路徑|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 141|FILL_IN_CELL_CORE_POWER_PAD_056|請填入core power pad cell；依 VDD/VSS pin map 判定|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 141|FILL_IN_CELL_CORE_POWER_PAD_057|請填入core power pad cell；依 VDD/VSS pin map 判定|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 142|FILL_IN_CELL_IO_POWER_PAD_055|請填入I/O power pad cell；依 VDDPST/VSSPST pin map 判定；POC 型號附加功能須確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 142|FILL_IN_CELL_IO_POWER_PAD_058|請填入I/O power pad cell；依 VDDPST/VSSPST pin map 判定；POC 型號附加功能須確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 143|FILL_IN_CELL_IO_POWER_PAD_058|請填入I/O power pad cell；依 VDDPST/VSSPST pin map 判定；POC 型號附加功能須確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 143|FILL_IN_CELL_IO_POWER_PAD_055|請填入I/O power pad cell；依 VDDPST/VSSPST pin map 判定；POC 型號附加功能須確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 144|FILL_IN_CELL_IO_POWER_PAD_058|請填入I/O power pad cell；依 VDDPST/VSSPST pin map 判定；POC 型號附加功能須確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 144|FILL_IN_CELL_IO_POWER_PAD_055|請填入I/O power pad cell；依 VDDPST/VSSPST pin map 判定；POC 型號附加功能須確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 145|FILL_IN_CELL_IO_POWER_PAD_055|請填入I/O power pad cell；依 VDDPST/VSSPST pin map 判定；POC 型號附加功能須確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 145|FILL_IN_CELL_IO_POWER_PAD_058|請填入I/O power pad cell；依 VDDPST/VSSPST pin map 判定；POC 型號附加功能須確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 146|FILL_IN_CELL_IO_POWER_PAD_058|請填入I/O power pad cell；依 VDDPST/VSSPST pin map 判定；POC 型號附加功能須確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 146|FILL_IN_CELL_IO_POWER_PAD_055|請填入I/O power pad cell；依 VDDPST/VSSPST pin map 判定；POC 型號附加功能須確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 147|FILL_IN_CELL_RTE_BOUNDARY_PAD_054|請填入RTE 邊界 pad cell；依 boundary／RTE rail 操作用途推定；精確電氣功能待 library 確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 147|FILL_IN_CELL_RTE_BOUNDARY_PAD_013|請填入RTE 邊界 pad cell；依 boundary／RTE rail 操作用途推定；精確電氣功能待 library 確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 148|FILL_IN_CELL_RTE_BOUNDARY_PAD_054|請填入RTE 邊界 pad cell；依 boundary／RTE rail 操作用途推定；精確電氣功能待 library 確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 148|FILL_IN_CELL_RTE_BOUNDARY_PAD_013|請填入RTE 邊界 pad cell；依 boundary／RTE rail 操作用途推定；精確電氣功能待 library 確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 149|FILL_IN_CELL_RTE_BOUNDARY_PAD_054|請填入RTE 邊界 pad cell；依 boundary／RTE rail 操作用途推定；精確電氣功能待 library 確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 149|FILL_IN_CELL_RTE_BOUNDARY_PAD_013|請填入RTE 邊界 pad cell；依 boundary／RTE rail 操作用途推定；精確電氣功能待 library 確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 150|FILL_IN_CELL_RTE_BOUNDARY_PAD_013|請填入RTE 邊界 pad cell；依 boundary／RTE rail 操作用途推定；精確電氣功能待 library 確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 150|FILL_IN_CELL_RTE_BOUNDARY_PAD_054|請填入RTE 邊界 pad cell；依 boundary／RTE rail 操作用途推定；精確電氣功能待 library 確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 151|FILL_IN_CELL_RTE_BOUNDARY_PAD_054|請填入RTE 邊界 pad cell；依 boundary／RTE rail 操作用途推定；精確電氣功能待 library 確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 151|FILL_IN_CELL_RTE_BOUNDARY_PAD_013|請填入RTE 邊界 pad cell；依 boundary／RTE rail 操作用途推定；精確電氣功能待 library 確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 152|FILL_IN_CELL_RTE_BOUNDARY_PAD_054|請填入RTE 邊界 pad cell；依 boundary／RTE rail 操作用途推定；精確電氣功能待 library 確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 152|FILL_IN_CELL_RTE_BOUNDARY_PAD_013|請填入RTE 邊界 pad cell；依 boundary／RTE rail 操作用途推定；精確電氣功能待 library 確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 170|FILL_IN_CELL_IO_RAIL_CUT_052|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 176|FILL_IN_CELL_CORE_POWER_PAD_056|請填入core power pad cell；依 VDD/VSS pin map 判定|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 176|FILL_IN_CELL_CORE_POWER_PAD_057|請填入core power pad cell；依 VDD/VSS pin map 判定|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 182|FILL_IN_CELL_IO_POWER_PAD_055|請填入I/O power pad cell；依 VDDPST/VSSPST pin map 判定；POC 型號附加功能須確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 182|FILL_IN_CELL_IO_POWER_PAD_058|請填入I/O power pad cell；依 VDDPST/VSSPST pin map 判定；POC 型號附加功能須確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 188|FILL_IN_CELL_IO_POWER_PAD_058|請填入I/O power pad cell；依 VDDPST/VSSPST pin map 判定；POC 型號附加功能須確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 188|FILL_IN_CELL_IO_POWER_PAD_055|請填入I/O power pad cell；依 VDDPST/VSSPST pin map 判定；POC 型號附加功能須確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 194|FILL_IN_CELL_IO_POWER_PAD_058|請填入I/O power pad cell；依 VDDPST/VSSPST pin map 判定；POC 型號附加功能須確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 194|FILL_IN_CELL_IO_POWER_PAD_055|請填入I/O power pad cell；依 VDDPST/VSSPST pin map 判定；POC 型號附加功能須確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 200|FILL_IN_CELL_IO_POWER_PAD_055|請填入I/O power pad cell；依 VDDPST/VSSPST pin map 判定；POC 型號附加功能須確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 200|FILL_IN_CELL_IO_POWER_PAD_058|請填入I/O power pad cell；依 VDDPST/VSSPST pin map 判定；POC 型號附加功能須確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 206|FILL_IN_CELL_IO_POWER_PAD_058|請填入I/O power pad cell；依 VDDPST/VSSPST pin map 判定；POC 型號附加功能須確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 206|FILL_IN_CELL_IO_POWER_PAD_055|請填入I/O power pad cell；依 VDDPST/VSSPST pin map 判定；POC 型號附加功能須確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 212|FILL_IN_CELL_RTE_BOUNDARY_PAD_054|請填入RTE 邊界 pad cell；依 boundary／RTE rail 操作用途推定；精確電氣功能待 library 確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 212|FILL_IN_CELL_RTE_BOUNDARY_PAD_013|請填入RTE 邊界 pad cell；依 boundary／RTE rail 操作用途推定；精確電氣功能待 library 確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 218|FILL_IN_CELL_RTE_BOUNDARY_PAD_054|請填入RTE 邊界 pad cell；依 boundary／RTE rail 操作用途推定；精確電氣功能待 library 確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 218|FILL_IN_CELL_RTE_BOUNDARY_PAD_013|請填入RTE 邊界 pad cell；依 boundary／RTE rail 操作用途推定；精確電氣功能待 library 確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 224|FILL_IN_CELL_RTE_BOUNDARY_PAD_054|請填入RTE 邊界 pad cell；依 boundary／RTE rail 操作用途推定；精確電氣功能待 library 確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 224|FILL_IN_CELL_RTE_BOUNDARY_PAD_013|請填入RTE 邊界 pad cell；依 boundary／RTE rail 操作用途推定；精確電氣功能待 library 確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 230|FILL_IN_CELL_RTE_BOUNDARY_PAD_013|請填入RTE 邊界 pad cell；依 boundary／RTE rail 操作用途推定；精確電氣功能待 library 確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 230|FILL_IN_CELL_RTE_BOUNDARY_PAD_054|請填入RTE 邊界 pad cell；依 boundary／RTE rail 操作用途推定；精確電氣功能待 library 確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 236|FILL_IN_CELL_RTE_BOUNDARY_PAD_054|請填入RTE 邊界 pad cell；依 boundary／RTE rail 操作用途推定；精確電氣功能待 library 確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 236|FILL_IN_CELL_RTE_BOUNDARY_PAD_013|請填入RTE 邊界 pad cell；依 boundary／RTE rail 操作用途推定；精確電氣功能待 library 確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 242|FILL_IN_CELL_RTE_BOUNDARY_PAD_054|請填入RTE 邊界 pad cell；依 boundary／RTE rail 操作用途推定；精確電氣功能待 library 確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 242|FILL_IN_CELL_RTE_BOUNDARY_PAD_013|請填入RTE 邊界 pad cell；依 boundary／RTE rail 操作用途推定；精確電氣功能待 library 確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 274|FILL_IN_CELL_CORE_POWER_PAD_056|請填入core power pad cell；依 VDD/VSS pin map 判定|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 278|FILL_IN_CELL_CORE_POWER_PAD_056|請填入core power pad cell；依 VDD/VSS pin map 判定|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 281|FILL_IN_CELL_CORE_POWER_PAD_056|請填入core power pad cell；依 VDD/VSS pin map 判定|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 285|FILL_IN_CELL_IO_POWER_PAD_055|請填入I/O power pad cell；依 VDDPST/VSSPST pin map 判定；POC 型號附加功能須確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 289|FILL_IN_CELL_IO_POWER_PAD_055|請填入I/O power pad cell；依 VDDPST/VSSPST pin map 判定；POC 型號附加功能須確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 292|FILL_IN_CELL_IO_POWER_PAD_055|請填入I/O power pad cell；依 VDDPST/VSSPST pin map 判定；POC 型號附加功能須確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 296|FILL_IN_CELL_IO_POWER_PAD_058|請填入I/O power pad cell；依 VDDPST/VSSPST pin map 判定；POC 型號附加功能須確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 300|FILL_IN_CELL_IO_POWER_PAD_058|請填入I/O power pad cell；依 VDDPST/VSSPST pin map 判定；POC 型號附加功能須確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 303|FILL_IN_CELL_IO_POWER_PAD_058|請填入I/O power pad cell；依 VDDPST/VSSPST pin map 判定；POC 型號附加功能須確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 307|FILL_IN_CELL_IO_POWER_PAD_058|請填入I/O power pad cell；依 VDDPST/VSSPST pin map 判定；POC 型號附加功能須確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 311|FILL_IN_CELL_IO_POWER_PAD_058|請填入I/O power pad cell；依 VDDPST/VSSPST pin map 判定；POC 型號附加功能須確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 314|FILL_IN_CELL_IO_POWER_PAD_058|請填入I/O power pad cell；依 VDDPST/VSSPST pin map 判定；POC 型號附加功能須確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 318|FILL_IN_CELL_IO_POWER_PAD_055|請填入I/O power pad cell；依 VDDPST/VSSPST pin map 判定；POC 型號附加功能須確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 322|FILL_IN_CELL_IO_POWER_PAD_055|請填入I/O power pad cell；依 VDDPST/VSSPST pin map 判定；POC 型號附加功能須確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 325|FILL_IN_CELL_IO_POWER_PAD_055|請填入I/O power pad cell；依 VDDPST/VSSPST pin map 判定；POC 型號附加功能須確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 329|FILL_IN_CELL_IO_POWER_PAD_058|請填入I/O power pad cell；依 VDDPST/VSSPST pin map 判定；POC 型號附加功能須確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 333|FILL_IN_CELL_IO_POWER_PAD_058|請填入I/O power pad cell；依 VDDPST/VSSPST pin map 判定；POC 型號附加功能須確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 336|FILL_IN_CELL_IO_POWER_PAD_058|請填入I/O power pad cell；依 VDDPST/VSSPST pin map 判定；POC 型號附加功能須確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 340|FILL_IN_CELL_RTE_BOUNDARY_PAD_013|請填入RTE 邊界 pad cell；依 boundary／RTE rail 操作用途推定；精確電氣功能待 library 確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 344|FILL_IN_CELL_RTE_BOUNDARY_PAD_013|請填入RTE 邊界 pad cell；依 boundary／RTE rail 操作用途推定；精確電氣功能待 library 確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 347|FILL_IN_CELL_RTE_BOUNDARY_PAD_013|請填入RTE 邊界 pad cell；依 boundary／RTE rail 操作用途推定；精確電氣功能待 library 確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 351|FILL_IN_CELL_RTE_BOUNDARY_PAD_054|請填入RTE 邊界 pad cell；依 boundary／RTE rail 操作用途推定；精確電氣功能待 library 確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 355|FILL_IN_CELL_RTE_BOUNDARY_PAD_054|請填入RTE 邊界 pad cell；依 boundary／RTE rail 操作用途推定；精確電氣功能待 library 確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 358|FILL_IN_CELL_RTE_BOUNDARY_PAD_054|請填入RTE 邊界 pad cell；依 boundary／RTE rail 操作用途推定；精確電氣功能待 library 確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 362|FILL_IN_CELL_RTE_BOUNDARY_PAD_013|請填入RTE 邊界 pad cell；依 boundary／RTE rail 操作用途推定；精確電氣功能待 library 確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 366|FILL_IN_CELL_RTE_BOUNDARY_PAD_013|請填入RTE 邊界 pad cell；依 boundary／RTE rail 操作用途推定；精確電氣功能待 library 確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 369|FILL_IN_CELL_RTE_BOUNDARY_PAD_013|請填入RTE 邊界 pad cell；依 boundary／RTE rail 操作用途推定；精確電氣功能待 library 確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 373|FILL_IN_CELL_RTE_BOUNDARY_PAD_013|請填入RTE 邊界 pad cell；依 boundary／RTE rail 操作用途推定；精確電氣功能待 library 確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 377|FILL_IN_CELL_RTE_BOUNDARY_PAD_013|請填入RTE 邊界 pad cell；依 boundary／RTE rail 操作用途推定；精確電氣功能待 library 確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 380|FILL_IN_CELL_RTE_BOUNDARY_PAD_013|請填入RTE 邊界 pad cell；依 boundary／RTE rail 操作用途推定；精確電氣功能待 library 確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 384|FILL_IN_CELL_RTE_BOUNDARY_PAD_054|請填入RTE 邊界 pad cell；依 boundary／RTE rail 操作用途推定；精確電氣功能待 library 確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 388|FILL_IN_CELL_RTE_BOUNDARY_PAD_054|請填入RTE 邊界 pad cell；依 boundary／RTE rail 操作用途推定；精確電氣功能待 library 確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 391|FILL_IN_CELL_RTE_BOUNDARY_PAD_054|請填入RTE 邊界 pad cell；依 boundary／RTE rail 操作用途推定；精確電氣功能待 library 確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 395|FILL_IN_CELL_RTE_BOUNDARY_PAD_054|請填入RTE 邊界 pad cell；依 boundary／RTE rail 操作用途推定；精確電氣功能待 library 確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 399|FILL_IN_CELL_RTE_BOUNDARY_PAD_054|請填入RTE 邊界 pad cell；依 boundary／RTE rail 操作用途推定；精確電氣功能待 library 確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 402|FILL_IN_CELL_RTE_BOUNDARY_PAD_054|請填入RTE 邊界 pad cell；依 boundary／RTE rail 操作用途推定；精確電氣功能待 library 確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 406|FILL_IN_CELL_CORE_POWER_PAD_057|請填入core power pad cell；依 VDD/VSS pin map 判定|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 410|FILL_IN_CELL_CORE_POWER_PAD_057|請填入core power pad cell；依 VDD/VSS pin map 判定|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 413|FILL_IN_CELL_CORE_POWER_PAD_057|請填入core power pad cell；依 VDD/VSS pin map 判定|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 417|FILL_IN_CELL_CORE_POWER_PAD_056|請填入core power pad cell；依 VDD/VSS pin map 判定|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 421|FILL_IN_CELL_CORE_POWER_PAD_056|請填入core power pad cell；依 VDD/VSS pin map 判定|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 424|FILL_IN_CELL_CORE_POWER_PAD_056|請填入core power pad cell；依 VDD/VSS pin map 判定|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 428|FILL_IN_CELL_CORE_POWER_PAD_057|請填入core power pad cell；依 VDD/VSS pin map 判定|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 432|FILL_IN_CELL_CORE_POWER_PAD_057|請填入core power pad cell；依 VDD/VSS pin map 判定|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 435|FILL_IN_CELL_CORE_POWER_PAD_057|請填入core power pad cell；依 VDD/VSS pin map 判定|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 439|FILL_IN_CELL_CORE_POWER_PAD_056|請填入core power pad cell；依 VDD/VSS pin map 判定|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 443|FILL_IN_CELL_CORE_POWER_PAD_056|請填入core power pad cell；依 VDD/VSS pin map 判定|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 446|FILL_IN_CELL_CORE_POWER_PAD_056|請填入core power pad cell；依 VDD/VSS pin map 判定|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 450|FILL_IN_CELL_CORE_POWER_PAD_057|請填入core power pad cell；依 VDD/VSS pin map 判定|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 454|FILL_IN_CELL_CORE_POWER_PAD_057|請填入core power pad cell；依 VDD/VSS pin map 判定|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 457|FILL_IN_CELL_CORE_POWER_PAD_057|請填入core power pad cell；依 VDD/VSS pin map 判定|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 461|FILL_IN_CELL_CORE_POWER_PAD_056|請填入core power pad cell；依 VDD/VSS pin map 判定|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 465|FILL_IN_CELL_CORE_POWER_PAD_056|請填入core power pad cell；依 VDD/VSS pin map 判定|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 468|FILL_IN_CELL_CORE_POWER_PAD_056|請填入core power pad cell；依 VDD/VSS pin map 判定|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 472|FILL_IN_CELL_CORE_POWER_PAD_056|請填入core power pad cell；依 VDD/VSS pin map 判定|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 476|FILL_IN_CELL_CORE_POWER_PAD_056|請填入core power pad cell；依 VDD/VSS pin map 判定|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 479|FILL_IN_CELL_CORE_POWER_PAD_056|請填入core power pad cell；依 VDD/VSS pin map 判定|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 483|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 487|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 490|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 494|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 498|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 501|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 505|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 509|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 512|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 516|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 520|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 523|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 527|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 531|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 534|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 538|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 542|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 545|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 549|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 553|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 556|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 560|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 564|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 567|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 571|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 575|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 578|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 582|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 586|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 589|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 593|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 597|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 600|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 604|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 608|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 611|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 615|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 619|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 622|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 626|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 630|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 633|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 637|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 641|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 644|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 648|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 652|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 655|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 659|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 663|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 666|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 670|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 674|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 677|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 681|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 685|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 688|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 692|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 696|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 699|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 703|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 707|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 710|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 714|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 718|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 721|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 725|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 729|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 732|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 736|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 740|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 743|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 747|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 751|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 754|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 758|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 762|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 765|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 769|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 773|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 776|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 780|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 784|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 787|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 791|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 795|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 798|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 802|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 806|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 809|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 813|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 817|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 820|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 824|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 828|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 831|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 835|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 839|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 842|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 846|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 850|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 853|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 857|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 861|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 864|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 868|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 872|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 875|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 879|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 883|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 886|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 890|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 894|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 897|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 901|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 905|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 908|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 912|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 916|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 919|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 923|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 927|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 930|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 934|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 938|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 941|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 945|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 949|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 952|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 956|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 960|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 963|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 967|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 971|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 974|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 978|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 982|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 985|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 989|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 993|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 996|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1000|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1004|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1007|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1011|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1015|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1018|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1022|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1026|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1029|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1033|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1037|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1040|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1044|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1048|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1051|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1055|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1059|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1062|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1066|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1070|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1073|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1077|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1081|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1084|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1088|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1092|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1095|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1099|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1103|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1106|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1110|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1114|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1117|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1121|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1125|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1128|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1132|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1136|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1139|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1143|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1147|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1150|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1154|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1158|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1161|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1165|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1169|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1172|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1176|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1180|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1183|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1187|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1191|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1194|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1198|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1202|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1205|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1209|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1213|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1216|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1220|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1224|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1227|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1231|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1235|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1238|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1242|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1246|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1249|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1253|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1257|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1260|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1264|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1268|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1271|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1275|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1279|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1282|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1286|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1290|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1293|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1297|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1301|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1304|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1308|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1312|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1315|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1319|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1323|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1326|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1330|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1334|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1337|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1341|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1345|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1348|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1352|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1356|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1359|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1363|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1367|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1370|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1374|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1378|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1381|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1385|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1389|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1392|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1396|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1400|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1403|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1407|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1411|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1414|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1418|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1422|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1425|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1429|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1433|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1436|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1440|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1444|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1447|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1451|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1455|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1458|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1462|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1466|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1469|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1473|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1477|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1480|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1484|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1488|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1491|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1495|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1499|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1502|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1506|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1510|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1513|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1517|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1521|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1524|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1528|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1532|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1535|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1539|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1543|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1546|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1550|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1554|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1557|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1561|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1565|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1568|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1572|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1576|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1579|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1583|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1587|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1590|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1594|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1598|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1601|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1605|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1609|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1612|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1616|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1620|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1623|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1627|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1631|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1634|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1638|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1642|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1645|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1649|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1653|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1656|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1660|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1664|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1667|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1671|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1675|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1678|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1682|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1686|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1689|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1693|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1697|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1700|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1704|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1708|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1711|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1715|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1719|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1722|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1726|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1730|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1733|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1737|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1741|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1744|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1748|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1752|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1755|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1759|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1763|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1766|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1770|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1774|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1777|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1781|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1785|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1788|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1792|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1796|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1799|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1803|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1807|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1810|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1814|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1818|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1821|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1825|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1829|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1832|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1836|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1840|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1843|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1847|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1851|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1854|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1858|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1862|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1865|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1869|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1873|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1876|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1880|FILL_IN_CELL_IO_POWER_PAD_055|請填入I/O power pad cell；依 VDDPST/VSSPST pin map 判定；POC 型號附加功能須確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1884|FILL_IN_CELL_IO_POWER_PAD_055|請填入I/O power pad cell；依 VDDPST/VSSPST pin map 判定；POC 型號附加功能須確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1887|FILL_IN_CELL_IO_POWER_PAD_055|請填入I/O power pad cell；依 VDDPST/VSSPST pin map 判定；POC 型號附加功能須確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1891|FILL_IN_CELL_IO_POWER_PAD_058|請填入I/O power pad cell；依 VDDPST/VSSPST pin map 判定；POC 型號附加功能須確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1895|FILL_IN_CELL_IO_POWER_PAD_058|請填入I/O power pad cell；依 VDDPST/VSSPST pin map 判定；POC 型號附加功能須確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1898|FILL_IN_CELL_IO_POWER_PAD_058|請填入I/O power pad cell；依 VDDPST/VSSPST pin map 判定；POC 型號附加功能須確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1902|FILL_IN_CELL_IO_POWER_PAD_058|請填入I/O power pad cell；依 VDDPST/VSSPST pin map 判定；POC 型號附加功能須確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1906|FILL_IN_CELL_IO_POWER_PAD_058|請填入I/O power pad cell；依 VDDPST/VSSPST pin map 判定；POC 型號附加功能須確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1909|FILL_IN_CELL_IO_POWER_PAD_058|請填入I/O power pad cell；依 VDDPST/VSSPST pin map 判定；POC 型號附加功能須確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1913|FILL_IN_CELL_IO_RAIL_CUT_059|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1917|FILL_IN_CELL_IO_RAIL_CUT_059|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1920|FILL_IN_CELL_IO_RAIL_CUT_059|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1924|FILL_IN_CELL_IO_RAIL_CUT_059|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1928|FILL_IN_CELL_IO_RAIL_CUT_059|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1931|FILL_IN_CELL_IO_RAIL_CUT_059|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1935|FILL_IN_CELL_IO_RAIL_CUT_060|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1939|FILL_IN_CELL_IO_RAIL_CUT_060|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1942|FILL_IN_CELL_IO_RAIL_CUT_060|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1946|FILL_IN_CELL_IO_RAIL_CUT_060|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1950|FILL_IN_CELL_IO_RAIL_CUT_060|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1953|FILL_IN_CELL_IO_RAIL_CUT_060|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1957|FILL_IN_CELL_IO_RAIL_CUT_060|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1961|FILL_IN_CELL_IO_RAIL_CUT_060|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1964|FILL_IN_CELL_IO_RAIL_CUT_060|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1968|FILL_IN_CELL_IO_RAIL_CUT_060|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1972|FILL_IN_CELL_IO_RAIL_CUT_060|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1975|FILL_IN_CELL_IO_RAIL_CUT_060|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1979|FILL_IN_CELL_IO_RAIL_CUT_059|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1983|FILL_IN_CELL_IO_RAIL_CUT_059|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1986|FILL_IN_CELL_IO_RAIL_CUT_059|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1990|FILL_IN_CELL_IO_RAIL_CUT_059|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1994|FILL_IN_CELL_IO_RAIL_CUT_059|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1997|FILL_IN_CELL_IO_RAIL_CUT_059|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 2001|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 2005|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 2008|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 2012|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 2016|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 2019|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 2023|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 2027|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 2030|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 2034|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 2038|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 2041|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 2045|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 2049|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 2052|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 2056|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 2060|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 2063|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 2067|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 2071|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 2074|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 2078|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 2082|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 2085|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 2089|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 2093|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 2096|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 2100|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 2104|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 2107|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 2111|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 2115|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 2118|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 2122|FILL_IN_CELL_RTE_BOUNDARY_PAD_013|請填入RTE 邊界 pad cell；依 boundary／RTE rail 操作用途推定；精確電氣功能待 library 確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 2126|FILL_IN_CELL_RTE_BOUNDARY_PAD_013|請填入RTE 邊界 pad cell；依 boundary／RTE rail 操作用途推定；精確電氣功能待 library 確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 2129|FILL_IN_CELL_RTE_BOUNDARY_PAD_013|請填入RTE 邊界 pad cell；依 boundary／RTE rail 操作用途推定；精確電氣功能待 library 確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 2133|FILL_IN_CELL_RTE_BOUNDARY_PAD_013|請填入RTE 邊界 pad cell；依 boundary／RTE rail 操作用途推定；精確電氣功能待 library 確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 2137|FILL_IN_CELL_RTE_BOUNDARY_PAD_013|請填入RTE 邊界 pad cell；依 boundary／RTE rail 操作用途推定；精確電氣功能待 library 確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 2140|FILL_IN_CELL_RTE_BOUNDARY_PAD_013|請填入RTE 邊界 pad cell；依 boundary／RTE rail 操作用途推定；精確電氣功能待 library 確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED.io|line 20|FILL_IN_RESOURCE_0175|請填入本地授權資源完整路徑|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 23|FILL_IN_RESOURCE_0177|請填入本地授權資源完整路徑|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 156|FILL_IN_CELL_IO_RAIL_CUT_052|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 184|FILL_IN_CELL_CORE_POWER_PAD_056|請填入core power pad cell；依 VDD/VSS pin map 判定|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 188|FILL_IN_CELL_CORE_POWER_PAD_056|請填入core power pad cell；依 VDD/VSS pin map 判定|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 191|FILL_IN_CELL_CORE_POWER_PAD_056|請填入core power pad cell；依 VDD/VSS pin map 判定|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 195|FILL_IN_CELL_IO_POWER_PAD_055|請填入I/O power pad cell；依 VDDPST/VSSPST pin map 判定；POC 型號附加功能須確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 199|FILL_IN_CELL_IO_POWER_PAD_055|請填入I/O power pad cell；依 VDDPST/VSSPST pin map 判定；POC 型號附加功能須確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 202|FILL_IN_CELL_IO_POWER_PAD_055|請填入I/O power pad cell；依 VDDPST/VSSPST pin map 判定；POC 型號附加功能須確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 206|FILL_IN_CELL_IO_POWER_PAD_058|請填入I/O power pad cell；依 VDDPST/VSSPST pin map 判定；POC 型號附加功能須確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 210|FILL_IN_CELL_IO_POWER_PAD_058|請填入I/O power pad cell；依 VDDPST/VSSPST pin map 判定；POC 型號附加功能須確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 213|FILL_IN_CELL_IO_POWER_PAD_058|請填入I/O power pad cell；依 VDDPST/VSSPST pin map 判定；POC 型號附加功能須確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 217|FILL_IN_CELL_IO_POWER_PAD_058|請填入I/O power pad cell；依 VDDPST/VSSPST pin map 判定；POC 型號附加功能須確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 221|FILL_IN_CELL_IO_POWER_PAD_058|請填入I/O power pad cell；依 VDDPST/VSSPST pin map 判定；POC 型號附加功能須確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 224|FILL_IN_CELL_IO_POWER_PAD_058|請填入I/O power pad cell；依 VDDPST/VSSPST pin map 判定；POC 型號附加功能須確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 228|FILL_IN_CELL_IO_POWER_PAD_055|請填入I/O power pad cell；依 VDDPST/VSSPST pin map 判定；POC 型號附加功能須確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 232|FILL_IN_CELL_IO_POWER_PAD_055|請填入I/O power pad cell；依 VDDPST/VSSPST pin map 判定；POC 型號附加功能須確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 235|FILL_IN_CELL_IO_POWER_PAD_055|請填入I/O power pad cell；依 VDDPST/VSSPST pin map 判定；POC 型號附加功能須確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 239|FILL_IN_CELL_IO_POWER_PAD_058|請填入I/O power pad cell；依 VDDPST/VSSPST pin map 判定；POC 型號附加功能須確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 243|FILL_IN_CELL_IO_POWER_PAD_058|請填入I/O power pad cell；依 VDDPST/VSSPST pin map 判定；POC 型號附加功能須確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 246|FILL_IN_CELL_IO_POWER_PAD_058|請填入I/O power pad cell；依 VDDPST/VSSPST pin map 判定；POC 型號附加功能須確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 250|FILL_IN_CELL_RTE_BOUNDARY_PAD_054|請填入RTE 邊界 pad cell；依 boundary／RTE rail 操作用途推定；精確電氣功能待 library 確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 254|FILL_IN_CELL_RTE_BOUNDARY_PAD_054|請填入RTE 邊界 pad cell；依 boundary／RTE rail 操作用途推定；精確電氣功能待 library 確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 257|FILL_IN_CELL_RTE_BOUNDARY_PAD_054|請填入RTE 邊界 pad cell；依 boundary／RTE rail 操作用途推定；精確電氣功能待 library 確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 261|FILL_IN_CELL_RTE_BOUNDARY_PAD_054|請填入RTE 邊界 pad cell；依 boundary／RTE rail 操作用途推定；精確電氣功能待 library 確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 265|FILL_IN_CELL_RTE_BOUNDARY_PAD_054|請填入RTE 邊界 pad cell；依 boundary／RTE rail 操作用途推定；精確電氣功能待 library 確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 268|FILL_IN_CELL_RTE_BOUNDARY_PAD_054|請填入RTE 邊界 pad cell；依 boundary／RTE rail 操作用途推定；精確電氣功能待 library 確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 272|FILL_IN_CELL_RTE_BOUNDARY_PAD_054|請填入RTE 邊界 pad cell；依 boundary／RTE rail 操作用途推定；精確電氣功能待 library 確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 276|FILL_IN_CELL_RTE_BOUNDARY_PAD_054|請填入RTE 邊界 pad cell；依 boundary／RTE rail 操作用途推定；精確電氣功能待 library 確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 279|FILL_IN_CELL_RTE_BOUNDARY_PAD_054|請填入RTE 邊界 pad cell；依 boundary／RTE rail 操作用途推定；精確電氣功能待 library 確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 283|FILL_IN_CELL_RTE_BOUNDARY_PAD_013|請填入RTE 邊界 pad cell；依 boundary／RTE rail 操作用途推定；精確電氣功能待 library 確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 287|FILL_IN_CELL_RTE_BOUNDARY_PAD_013|請填入RTE 邊界 pad cell；依 boundary／RTE rail 操作用途推定；精確電氣功能待 library 確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 290|FILL_IN_CELL_RTE_BOUNDARY_PAD_013|請填入RTE 邊界 pad cell；依 boundary／RTE rail 操作用途推定；精確電氣功能待 library 確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 294|FILL_IN_CELL_RTE_BOUNDARY_PAD_054|請填入RTE 邊界 pad cell；依 boundary／RTE rail 操作用途推定；精確電氣功能待 library 確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 298|FILL_IN_CELL_RTE_BOUNDARY_PAD_054|請填入RTE 邊界 pad cell；依 boundary／RTE rail 操作用途推定；精確電氣功能待 library 確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 301|FILL_IN_CELL_RTE_BOUNDARY_PAD_054|請填入RTE 邊界 pad cell；依 boundary／RTE rail 操作用途推定；精確電氣功能待 library 確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 305|FILL_IN_CELL_RTE_BOUNDARY_PAD_054|請填入RTE 邊界 pad cell；依 boundary／RTE rail 操作用途推定；精確電氣功能待 library 確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 309|FILL_IN_CELL_RTE_BOUNDARY_PAD_054|請填入RTE 邊界 pad cell；依 boundary／RTE rail 操作用途推定；精確電氣功能待 library 確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 312|FILL_IN_CELL_RTE_BOUNDARY_PAD_054|請填入RTE 邊界 pad cell；依 boundary／RTE rail 操作用途推定；精確電氣功能待 library 確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 316|FILL_IN_CELL_CORE_POWER_PAD_057|請填入core power pad cell；依 VDD/VSS pin map 判定|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 320|FILL_IN_CELL_CORE_POWER_PAD_057|請填入core power pad cell；依 VDD/VSS pin map 判定|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 323|FILL_IN_CELL_CORE_POWER_PAD_057|請填入core power pad cell；依 VDD/VSS pin map 判定|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 327|FILL_IN_CELL_CORE_POWER_PAD_056|請填入core power pad cell；依 VDD/VSS pin map 判定|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 331|FILL_IN_CELL_CORE_POWER_PAD_056|請填入core power pad cell；依 VDD/VSS pin map 判定|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 334|FILL_IN_CELL_CORE_POWER_PAD_056|請填入core power pad cell；依 VDD/VSS pin map 判定|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 338|FILL_IN_CELL_CORE_POWER_PAD_057|請填入core power pad cell；依 VDD/VSS pin map 判定|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 342|FILL_IN_CELL_CORE_POWER_PAD_057|請填入core power pad cell；依 VDD/VSS pin map 判定|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 345|FILL_IN_CELL_CORE_POWER_PAD_057|請填入core power pad cell；依 VDD/VSS pin map 判定|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 349|FILL_IN_CELL_CORE_POWER_PAD_056|請填入core power pad cell；依 VDD/VSS pin map 判定|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 353|FILL_IN_CELL_CORE_POWER_PAD_056|請填入core power pad cell；依 VDD/VSS pin map 判定|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 356|FILL_IN_CELL_CORE_POWER_PAD_056|請填入core power pad cell；依 VDD/VSS pin map 判定|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 360|FILL_IN_CELL_CORE_POWER_PAD_056|請填入core power pad cell；依 VDD/VSS pin map 判定|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 364|FILL_IN_CELL_CORE_POWER_PAD_056|請填入core power pad cell；依 VDD/VSS pin map 判定|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 367|FILL_IN_CELL_CORE_POWER_PAD_056|請填入core power pad cell；依 VDD/VSS pin map 判定|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 371|FILL_IN_CELL_CORE_POWER_PAD_056|請填入core power pad cell；依 VDD/VSS pin map 判定|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 375|FILL_IN_CELL_CORE_POWER_PAD_056|請填入core power pad cell；依 VDD/VSS pin map 判定|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 378|FILL_IN_CELL_CORE_POWER_PAD_056|請填入core power pad cell；依 VDD/VSS pin map 判定|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 382|FILL_IN_CELL_CORE_POWER_PAD_056|請填入core power pad cell；依 VDD/VSS pin map 判定|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 386|FILL_IN_CELL_CORE_POWER_PAD_056|請填入core power pad cell；依 VDD/VSS pin map 判定|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 389|FILL_IN_CELL_CORE_POWER_PAD_056|請填入core power pad cell；依 VDD/VSS pin map 判定|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 393|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 397|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 400|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 404|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 408|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 411|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 415|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 419|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 422|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 426|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 430|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 433|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 437|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 441|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 444|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 448|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 452|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 455|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 459|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 463|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 466|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 470|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 474|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 477|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 481|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 485|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 488|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 492|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 496|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 499|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 503|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 507|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 510|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 514|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 518|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 521|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 525|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 529|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 532|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 536|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 540|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 543|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 547|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 551|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 554|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 558|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 562|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 565|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 569|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 573|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 576|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 580|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 584|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 587|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 591|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 595|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 598|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 602|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 606|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 609|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 613|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 617|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 620|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 624|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 628|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 631|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 635|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 639|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 642|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 646|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 650|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 653|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 657|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 661|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 664|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 668|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 672|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 675|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 679|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 683|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 686|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 690|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 694|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 697|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 701|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 705|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 708|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 712|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 716|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 719|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 723|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 727|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 730|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 734|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 738|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 741|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 745|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 749|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 752|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 756|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 760|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 763|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 767|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 771|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 774|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 778|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 782|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 785|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 789|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 793|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 796|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 800|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 804|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 807|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 811|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 815|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 818|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 822|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 826|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 829|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 833|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 837|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 840|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 844|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 848|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 851|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 855|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 859|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 862|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 866|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 870|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 873|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 877|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 881|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 884|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 888|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 892|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 895|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 899|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 903|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 906|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 910|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 914|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 917|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 921|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 925|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 928|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 932|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 936|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 939|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 943|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 947|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 950|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 954|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 958|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 961|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 965|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 969|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 972|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 976|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 980|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 983|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 987|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 991|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 994|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 998|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1002|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1005|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1009|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1013|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1016|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1020|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1024|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1027|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1031|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1035|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1038|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1042|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1046|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1049|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1053|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1057|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1060|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1064|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1068|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1071|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1075|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1079|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1082|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1086|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1090|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1093|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1097|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1101|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1104|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1108|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1112|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1115|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1119|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1123|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1126|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1130|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1134|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1137|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1141|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1145|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1148|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1152|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1156|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1159|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1163|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1167|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1170|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1174|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1178|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1181|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1185|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1189|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1192|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1196|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1200|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1203|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1207|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1211|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1214|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1218|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1222|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1225|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1229|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1233|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1236|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1240|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1244|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1247|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1251|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1255|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1258|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1262|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1266|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1269|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1273|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1277|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1280|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1284|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1288|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1291|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1295|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1299|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1302|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1306|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1310|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1313|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1317|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1321|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1324|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1328|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1332|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1335|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1339|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1343|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1346|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1350|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1354|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1357|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1361|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1365|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1368|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1372|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1376|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1379|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1383|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1387|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1390|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1394|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1398|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1401|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1405|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1409|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1412|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1416|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1420|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1423|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1427|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1431|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1434|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1438|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1442|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1445|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1449|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1453|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1456|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1460|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1464|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1467|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1471|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1475|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1478|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1482|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1486|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1489|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1493|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1497|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1500|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1504|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1508|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1511|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1515|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1519|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1522|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1526|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1530|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1533|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1537|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1541|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1544|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1548|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1552|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1555|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1559|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1563|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1566|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1570|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1574|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1577|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1581|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1585|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1588|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1592|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1596|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1599|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1603|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1607|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1610|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1614|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1618|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1621|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1625|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1629|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1632|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1636|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1640|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1643|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1647|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1651|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1654|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1658|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1662|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1665|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1669|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1673|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1676|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1680|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1684|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1687|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1691|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1695|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1698|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1702|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1706|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1709|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1713|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1717|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1720|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1724|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1728|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1731|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1735|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1739|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1742|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1746|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1750|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1753|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1757|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1761|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1764|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1768|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1772|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1775|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1779|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1783|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1786|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1790|FILL_IN_CELL_IO_POWER_PAD_058|請填入I/O power pad cell；依 VDDPST/VSSPST pin map 判定；POC 型號附加功能須確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1794|FILL_IN_CELL_IO_POWER_PAD_058|請填入I/O power pad cell；依 VDDPST/VSSPST pin map 判定；POC 型號附加功能須確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1797|FILL_IN_CELL_IO_POWER_PAD_058|請填入I/O power pad cell；依 VDDPST/VSSPST pin map 判定；POC 型號附加功能須確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1801|FILL_IN_CELL_IO_POWER_PAD_058|請填入I/O power pad cell；依 VDDPST/VSSPST pin map 判定；POC 型號附加功能須確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1805|FILL_IN_CELL_IO_POWER_PAD_058|請填入I/O power pad cell；依 VDDPST/VSSPST pin map 判定；POC 型號附加功能須確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1808|FILL_IN_CELL_IO_POWER_PAD_058|請填入I/O power pad cell；依 VDDPST/VSSPST pin map 判定；POC 型號附加功能須確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1812|FILL_IN_CELL_IO_POWER_PAD_058|請填入I/O power pad cell；依 VDDPST/VSSPST pin map 判定；POC 型號附加功能須確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1816|FILL_IN_CELL_IO_POWER_PAD_058|請填入I/O power pad cell；依 VDDPST/VSSPST pin map 判定；POC 型號附加功能須確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1819|FILL_IN_CELL_IO_POWER_PAD_058|請填入I/O power pad cell；依 VDDPST/VSSPST pin map 判定；POC 型號附加功能須確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1823|FILL_IN_CELL_IO_RAIL_CUT_059|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1827|FILL_IN_CELL_IO_RAIL_CUT_059|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1830|FILL_IN_CELL_IO_RAIL_CUT_059|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1834|FILL_IN_CELL_IO_RAIL_CUT_059|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1838|FILL_IN_CELL_IO_RAIL_CUT_059|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1841|FILL_IN_CELL_IO_RAIL_CUT_059|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1845|FILL_IN_CELL_IO_RAIL_CUT_060|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1849|FILL_IN_CELL_IO_RAIL_CUT_060|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1852|FILL_IN_CELL_IO_RAIL_CUT_060|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1856|FILL_IN_CELL_IO_RAIL_CUT_060|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1860|FILL_IN_CELL_IO_RAIL_CUT_060|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1863|FILL_IN_CELL_IO_RAIL_CUT_060|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1867|FILL_IN_CELL_IO_RAIL_CUT_060|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1871|FILL_IN_CELL_IO_RAIL_CUT_060|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1874|FILL_IN_CELL_IO_RAIL_CUT_060|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1878|FILL_IN_CELL_IO_RAIL_CUT_060|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1882|FILL_IN_CELL_IO_RAIL_CUT_060|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1885|FILL_IN_CELL_IO_RAIL_CUT_060|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1889|FILL_IN_CELL_IO_RAIL_CUT_059|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1893|FILL_IN_CELL_IO_RAIL_CUT_059|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1896|FILL_IN_CELL_IO_RAIL_CUT_059|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1900|FILL_IN_CELL_IO_RAIL_CUT_059|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1904|FILL_IN_CELL_IO_RAIL_CUT_059|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1907|FILL_IN_CELL_IO_RAIL_CUT_059|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1911|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1915|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1918|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1922|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1926|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1929|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1933|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1937|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1940|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1944|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1948|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1951|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1955|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1959|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1962|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1966|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1970|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1973|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1977|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1981|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1984|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1988|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1992|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1995|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 1999|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 2003|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 2006|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 2010|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 2014|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 2017|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 2021|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 2025|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 2028|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 2032|FILL_IN_CELL_RTE_BOUNDARY_PAD_054|請填入RTE 邊界 pad cell；依 boundary／RTE rail 操作用途推定；精確電氣功能待 library 確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 2036|FILL_IN_CELL_RTE_BOUNDARY_PAD_054|請填入RTE 邊界 pad cell；依 boundary／RTE rail 操作用途推定；精確電氣功能待 library 確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 2039|FILL_IN_CELL_RTE_BOUNDARY_PAD_054|請填入RTE 邊界 pad cell；依 boundary／RTE rail 操作用途推定；精確電氣功能待 library 確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 2043|FILL_IN_CELL_RTE_BOUNDARY_PAD_013|請填入RTE 邊界 pad cell；依 boundary／RTE rail 操作用途推定；精確電氣功能待 library 確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 2047|FILL_IN_CELL_RTE_BOUNDARY_PAD_013|請填入RTE 邊界 pad cell；依 boundary／RTE rail 操作用途推定；精確電氣功能待 library 確認|
|baseline/script/PR/TECH_MV/setup/CHIP_IOPAD_EDITED_CHECKED_IOPAD_EDITED_CHECKED_DB_PATCH.tcl|line 2050|FILL_IN_CELL_RTE_BOUNDARY_PAD_013|請填入RTE 邊界 pad cell；依 boundary／RTE rail 操作用途推定；精確電氣功能待 library 確認|
|baseline/script/PR/TECH_MV/setup/config/00_design.config.tcl|line 76|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/setup/config/00_library.config.tcl|line 9|FILL_IN_CELL_IO_RAIL_CUT_052|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/setup/config/00_library.config.tcl|line 10|FILL_IN_CELL_RTE_BOUNDARY_PAD_051|請填入RTE 邊界 pad cell；依 boundary／RTE rail 操作用途推定；精確電氣功能待 library 確認|
|baseline/script/PR/TECH_MV/setup/config/00_library.config.tcl|line 16|FILL_IN_CELL_WELL_TAP_061|請填入well tap cell；依 welltap 設定與名稱判定|
|baseline/script/PR/TECH_MV/setup/config/00_library.config.tcl|line 17|FILL_IN_CELL_POWER_SWITCH_029|請填入header power switch cell；依 power gating／switch chain 用途判定；容量與控制接腳須核對|
|baseline/script/PR/TECH_MV/setup/config/00_library.config.tcl|line 18|FILL_IN_CELL_DIGITAL_IO_PAD_050|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/config/00_library.config.tcl|line 18|FILL_IN_CELL_RTE_BOUNDARY_PAD_051|請填入RTE 邊界 pad cell；依 boundary／RTE rail 操作用途推定；精確電氣功能待 library 確認|
|baseline/script/PR/TECH_MV/setup/config/00_library.config.tcl|line 18|FILL_IN_CELL_CORE_POWER_PAD_042|請填入core power pad cell；依 VDD/VSS pin map 判定|
|baseline/script/PR/TECH_MV/setup/config/00_library.config.tcl|line 18|FILL_IN_CELL_IO_POWER_PAD_043|請填入I/O power pad cell；依 VDDPST/VSSPST pin map 判定；POC 型號附加功能須確認|
|baseline/script/PR/TECH_MV/setup/config/00_library.config.tcl|line 18|FILL_IN_CELL_IO_RAIL_CUT_052|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/setup/config/00_library.config.tcl|line 18|FILL_IN_CELL_IO_CORNER_053|請填入I/O corner cell；依 pad ring 角落設定判定|
|baseline/script/PR/TECH_MV/setup/config/00_library.config.tcl|line 19|FILL_IN_CELL_POWER_SWITCH_062|請填入header power switch cell；依 power gating／switch chain 用途判定；容量與控制接腳須核對|
|baseline/script/PR/TECH_MV/setup/config/00_library.config.tcl|line 32|FILL_IN_CELL_IO_FILLER_063|請填入I/O filler cell；依 pad ring filler 設定判定；尺寸須核對|
|baseline/script/PR/TECH_MV/setup/config/00_library.config.tcl|line 33|FILL_IN_CELL_IO_FILLER_064|請填入I/O filler cell；依 pad ring filler 設定判定；尺寸須核對|
|baseline/script/PR/TECH_MV/setup/config/00_library.config.tcl|line 34|FILL_IN_CELL_IO_FILLER_065|請填入I/O filler cell；依 pad ring filler 設定判定；尺寸須核對|
|baseline/script/PR/TECH_MV/setup/config/00_library.config.tcl|line 35|FILL_IN_CELL_IO_FILLER_066|請填入I/O filler cell；依 pad ring filler 設定判定；尺寸須核對|
|baseline/script/PR/TECH_MV/setup/config/00_library.config.tcl|line 40|FILL_IN_CELL_IO_RAIL_CUT_052|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/setup/config/00_library.config.tcl|line 41|FILL_IN_CELL_RTE_BOUNDARY_PAD_051|請填入RTE 邊界 pad cell；依 boundary／RTE rail 操作用途推定；精確電氣功能待 library 確認|
|baseline/script/PR/TECH_MV/setup/config/00_library.config.tcl|line 50|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/setup/config/00_library.config.tcl|line 51|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/setup/config/00_library.config.tcl|line 52|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/setup/config/00_library.config.tcl|line 53|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/setup/config/00_library.config.tcl|line 54|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/setup/config/00_library.config.tcl|line 55|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/setup/config/00_library.config.tcl|line 56|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/setup/config/00_library.config.tcl|line 57|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/setup/config/00_library.config.tcl|line 58|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/setup/config/00_library.config.tcl|line 59|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/setup/config/00_library.config.tcl|line 61|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/setup/config/00_library.config.tcl|line 62|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/setup/config/00_library.config.tcl|line 67|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/setup/config/00_library.config.tcl|line 68|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/setup/config/00_library.config.tcl|line 77|FILL_IN_CELL_POWER_SWITCH_029|請填入header power switch cell；依 power gating／switch chain 用途判定；容量與控制接腳須核對|
|baseline/script/PR/TECH_MV/setup/config/00_library.config.tcl|line 83|FILL_IN_CELL_TIE_HIGH_067|請填入tie-high cell；依名稱推定；須確認常數輸出與 library 定義|
|baseline/script/PR/TECH_MV/setup/config/00_library.config.tcl|line 83|FILL_IN_CELL_TIE_LOW_068|請填入tie-low cell；依名稱推定；須確認常數輸出與 library 定義|
|baseline/script/PR/TECH_MV/setup/config/00_library.config.tcl|line 92|FILL_IN_CELL_WELL_TAP_061|請填入well tap cell；依 welltap 設定與名稱判定|
|baseline/script/PR/TECH_MV/setup/config/00_library.config.tcl|line 93|FILL_IN_CELL_WELL_TAP_061|請填入well tap cell；依 welltap 設定與名稱判定|
|baseline/script/PR/TECH_MV/setup/config/00_library.config.tcl|line 95|FILL_IN_CELL_DIGITAL_IO_PAD_050|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/PR/TECH_MV/setup/config/00_library.config.tcl|line 95|FILL_IN_CELL_RTE_BOUNDARY_PAD_051|請填入RTE 邊界 pad cell；依 boundary／RTE rail 操作用途推定；精確電氣功能待 library 確認|
|baseline/script/PR/TECH_MV/setup/config/00_library.config.tcl|line 95|FILL_IN_CELL_CORE_POWER_PAD_042|請填入core power pad cell；依 VDD/VSS pin map 判定|
|baseline/script/PR/TECH_MV/setup/config/00_library.config.tcl|line 95|FILL_IN_CELL_IO_POWER_PAD_043|請填入I/O power pad cell；依 VDDPST/VSSPST pin map 判定；POC 型號附加功能須確認|
|baseline/script/PR/TECH_MV/setup/config/00_library.config.tcl|line 95|FILL_IN_CELL_IO_RAIL_CUT_052|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/setup/config/00_library.config.tcl|line 96|FILL_IN_CELL_IO_CORNER_053|請填入I/O corner cell；依 pad ring 角落設定判定|
|baseline/script/PR/TECH_MV/setup/config/00_library.config.tcl|line 97|FILL_IN_CELL_IO_CORNER_053|請填入I/O corner cell；依 pad ring 角落設定判定|
|baseline/script/PR/TECH_MV/setup/config/00_library.config.tcl|line 98|FILL_IN_CELL_IO_RAIL_CUT_060|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/setup/config/00_library.config.tcl|line 99|FILL_IN_CELL_IO_RAIL_CUT_059|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/setup/config/00_library.config.tcl|line 100|FILL_IN_CELL_CORE_POWER_PAD_056|請填入core power pad cell；依 VDD/VSS pin map 判定|
|baseline/script/PR/TECH_MV/setup/config/00_library.config.tcl|line 101|FILL_IN_CELL_CORE_POWER_PAD_057|請填入core power pad cell；依 VDD/VSS pin map 判定|
|baseline/script/PR/TECH_MV/setup/config/00_library.config.tcl|line 102|FILL_IN_CELL_IO_POWER_PAD_058|請填入I/O power pad cell；依 VDDPST/VSSPST pin map 判定；POC 型號附加功能須確認|
|baseline/script/PR/TECH_MV/setup/config/00_library.config.tcl|line 103|FILL_IN_CELL_IO_POWER_PAD_055|請填入I/O power pad cell；依 VDDPST/VSSPST pin map 判定；POC 型號附加功能須確認|
|baseline/script/PR/TECH_MV/setup/config/00_library.config.tcl|line 148|FILL_IN_CELL_UNCONFIRMED_069|請填入待確認類型的 cell；僅能識別為元件名稱；需查本地 library 定義|
|baseline/script/PR/TECH_MV/setup/config/00_library.config.tcl|line 148|FILL_IN_CELL_UNCONFIRMED_070|請填入待確認類型的 cell；僅能識別為元件名稱；需查本地 library 定義|
|baseline/script/PR/TECH_MV/setup/config/00_library.config.tcl|line 148|FILL_IN_CELL_UNCONFIRMED_071|請填入待確認類型的 cell；僅能識別為元件名稱；需查本地 library 定義|
|baseline/script/PR/TECH_MV/setup/config/00_library.config.tcl|line 148|FILL_IN_CELL_UNCONFIRMED_072|請填入待確認類型的 cell；僅能識別為元件名稱；需查本地 library 定義|
|baseline/script/PR/TECH_MV/setup/config/00_library.config.tcl|line 148|FILL_IN_CELL_UNCONFIRMED_073|請填入待確認類型的 cell；僅能識別為元件名稱；需查本地 library 定義|
|baseline/script/PR/TECH_MV/setup/config/00_library.config.tcl|line 148|FILL_IN_CELL_UNCONFIRMED_074|請填入待確認類型的 cell；僅能識別為元件名稱；需查本地 library 定義|
|baseline/script/PR/TECH_MV/setup/config/00_library.config.tcl|line 148|FILL_IN_CELL_UNCONFIRMED_075|請填入待確認類型的 cell；僅能識別為元件名稱；需查本地 library 定義|
|baseline/script/PR/TECH_MV/setup/config/00_library.config.tcl|line 148|FILL_IN_CELL_UNCONFIRMED_076|請填入待確認類型的 cell；僅能識別為元件名稱；需查本地 library 定義|
|baseline/script/PR/TECH_MV/setup/config/00_library.config.tcl|line 148|FILL_IN_CELL_UNCONFIRMED_077|請填入待確認類型的 cell；僅能識別為元件名稱；需查本地 library 定義|
|baseline/script/PR/TECH_MV/setup/config/00_library.config.tcl|line 148|FILL_IN_CELL_UNCONFIRMED_078|請填入待確認類型的 cell；僅能識別為元件名稱；需查本地 library 定義|
|baseline/script/PR/TECH_MV/setup/config/00_library.config.tcl|line 150|FILL_IN_CELL_UNCONFIRMED_079|請填入待確認類型的 cell；僅能識別為元件名稱；需查本地 library 定義|
|baseline/script/PR/TECH_MV/setup/config/00_library.config.tcl|line 150|FILL_IN_CELL_UNCONFIRMED_080|請填入待確認類型的 cell；僅能識別為元件名稱；需查本地 library 定義|
|baseline/script/PR/TECH_MV/setup/config/00_library.config.tcl|line 150|FILL_IN_CELL_UNCONFIRMED_081|請填入待確認類型的 cell；僅能識別為元件名稱；需查本地 library 定義|
|baseline/script/PR/TECH_MV/setup/config/00_library.config.tcl|line 150|FILL_IN_CELL_UNCONFIRMED_082|請填入待確認類型的 cell；僅能識別為元件名稱；需查本地 library 定義|
|baseline/script/PR/TECH_MV/setup/config/00_library.config.tcl|line 150|FILL_IN_CELL_UNCONFIRMED_083|請填入待確認類型的 cell；僅能識別為元件名稱；需查本地 library 定義|
|baseline/script/PR/TECH_MV/setup/config/00_library.config.tcl|line 150|FILL_IN_CELL_UNCONFIRMED_084|請填入待確認類型的 cell；僅能識別為元件名稱；需查本地 library 定義|
|baseline/script/PR/TECH_MV/setup/config/00_library.config.tcl|line 150|FILL_IN_CELL_UNCONFIRMED_085|請填入待確認類型的 cell；僅能識別為元件名稱；需查本地 library 定義|
|baseline/script/PR/TECH_MV/setup/config/00_library.config.tcl|line 150|FILL_IN_CELL_UNCONFIRMED_086|請填入待確認類型的 cell；僅能識別為元件名稱；需查本地 library 定義|
|baseline/script/PR/TECH_MV/setup/config/00_library.config.tcl|line 150|FILL_IN_CELL_UNCONFIRMED_087|請填入待確認類型的 cell；僅能識別為元件名稱；需查本地 library 定義|
|baseline/script/PR/TECH_MV/setup/config/00_library.config.tcl|line 150|FILL_IN_CELL_UNCONFIRMED_088|請填入待確認類型的 cell；僅能識別為元件名稱；需查本地 library 定義|
|baseline/script/PR/TECH_MV/setup/config/00_library.config.tcl|line 150|FILL_IN_CELL_UNCONFIRMED_089|請填入待確認類型的 cell；僅能識別為元件名稱；需查本地 library 定義|
|baseline/script/PR/TECH_MV/setup/config/00_library.config.tcl|line 152|FILL_IN_CELL_ICG_090|請填入integrated clock gating（ICG）cell；依 TE/E/CP/Q 連接與 ICG 實例用途判定|
|baseline/script/PR/TECH_MV/setup/config/01_floorplan.config.tcl|line 54|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/setup/config/01_floorplan.config.tcl|line 104|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/setup/config/01_floorplan.config.tcl|line 107|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/setup/config/01_floorplan.config.tcl|line 224|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/setup/config/01_floorplan.config.tcl|line 232|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/setup/config/01_floorplan.config.tcl|line 235|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/setup/config/01_floorplan.config.tcl|line 237|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/setup/config/01_floorplan.config.tcl|line 273|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/setup/config/01_floorplan.config.tcl|line 302|FILL_IN_CELL_IO_RAIL_CUT_052|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/setup/config/01_floorplan.config.tcl|line 338|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/setup/config/02_powerplan.config.tcl|line 13|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/setup/config/private/ioPADt.rules.json|line 10|FILL_IN_CELL_IO_RAIL_CUT_052|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|
|baseline/script/PR/TECH_MV/verify/README.md|line 100|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/verify/README.md|line 160|FILL_IN_LIBRARY_0165|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/PR/TECH_MV/verify/README.md|line 167|FILL_IN_LIBRARY_0166|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/PR/TECH_MV/verify/extract_hdr.sh|line 4|FILL_IN_CELL_POWER_SWITCH_029|請填入header power switch cell；依 power gating／switch chain 用途判定；容量與控制接腳須核對|
|baseline/script/PR/TECH_MV/verify/extract_hdr.sh|line 5|FILL_IN_RESOURCE_0178|請填入本地授權資源完整路徑|
|baseline/script/PR/TECH_MV/verify/temp.sh|line 5|FILL_IN_CELL_POWER_SWITCH_029|請填入header power switch cell；依 power gating／switch chain 用途判定；容量與控制接腳須核對|
|baseline/script/PR/TECH_MV/verify/temp.sh|line 6|FILL_IN_RESOURCE_0178|請填入本地授權資源完整路徑|
|baseline/script/PR/TECH_MV/verify/config/hcell_policy.tcl|line 1|FILL_IN_CELL_BOND_PAD_041|請填入bond pad cell；依 BOND_PAD_CELL 與封裝接點流程判定|
|baseline/script/PR/TECH_MV/verify/config/hcell_policy.tcl|line 1|FILL_IN_CELL_IO_CORNER_053|請填入I/O corner cell；依 pad ring 角落設定判定|
|baseline/script/PR/TECH_MV/verify/config/verify_path.cfg|line 28|FILL_IN_RESOURCE_0164|請填入本地授權資源完整路徑|
|baseline/script/PR/TECH_MV/verify/config/verify_path.cfg|line 32|FILL_IN_RESOURCE_0168|請填入本地授權資源完整路徑|
|baseline/script/PR/TECH_MV/verify/config/verify_path.cfg|line 36|FILL_IN_RESOURCE_0169|請填入本地授權資源完整路徑|
|baseline/script/PR/TECH_MV/verify/config/verify_path.cfg|line 40|FILL_IN_RESOURCE_0170|請填入本地授權資源完整路徑|
|baseline/script/PR/TECH_MV/verify/config/verify_path.cfg|line 44|FILL_IN_RESOURCE_0171|請填入本地授權資源完整路徑|
|baseline/script/PR/TECH_MV/verify/config/verify_path.cfg|line 48|FILL_IN_RESOURCE_0172|請填入本地授權資源完整路徑|
|baseline/script/PR/TECH_MV/verify/config/verify_path.cfg|line 52|FILL_IN_RESOURCE_0173|請填入本地授權資源完整路徑|
|baseline/script/PR/TECH_MV/verify/config/verify_path.cfg|line 62|FILL_IN_RESOURCE_0179|請填入本地授權資源完整路徑|
|baseline/script/PR/TECH_MV/verify/config/verify_path.cfg|line 66|FILL_IN_RESOURCE_0180|請填入本地授權資源完整路徑|
|baseline/script/PR/TECH_MV/verify/config/verify_path.cfg|line 73|FILL_IN_RESOURCE_0181|請填入本地授權資源完整路徑|
|baseline/script/PR/TECH_MV/verify/config/verify_path.cfg|line 76|FILL_IN_RESOURCE_0182|請填入本地授權資源完整路徑|
|baseline/script/PR/TECH_MV/verify/config/verify_path.cfg|line 79|FILL_IN_RESOURCE_0183|請填入本地授權資源完整路徑|
|baseline/script/PR/TECH_MV/verify/config/verify_path.cfg|line 83|FILL_IN_RESOURCE_0151|請填入本地授權資源完整路徑|
|baseline/script/PR/TECH_MV/verify/config/verify_path.cfg|line 87|FILL_IN_RESOURCE_0150|請填入本地授權資源完整路徑|
|baseline/script/PR/TECH_MV/verify/config/verify_path.cfg|line 91|FILL_IN_RESOURCE_0184|請填入本地授權資源完整路徑|
|baseline/script/PR/TECH_MV/verify/config/verify_path.cfg|line 95|FILL_IN_RESOURCE_0154|請填入本地授權資源完整路徑|
|baseline/script/PR/TECH_MV/verify/config/verify_path.cfg|line 99|FILL_IN_RESOURCE_0155|請填入本地授權資源完整路徑|
|baseline/script/PR/TECH_MV/verify/config/verify_path.cfg|line 103|FILL_IN_RESOURCE_0152|請填入本地授權資源完整路徑|
|baseline/script/PR/TECH_MV/verify/config/verify_path.cfg|line 107|FILL_IN_RESOURCE_0153|請填入本地授權資源完整路徑|
|baseline/script/PR/TECH_MV/verify/config/verify_path.cfg|line 111|FILL_IN_RESOURCE_0156|請填入本地授權資源完整路徑|
|baseline/script/PR/TECH_MV/verify/config/verify_path.cfg|line 115|FILL_IN_RESOURCE_0185|請填入本地授權資源完整路徑|
|baseline/script/PR/TECH_MV/verify/config/verify_path.cfg|line 119|FILL_IN_RESOURCE_0186|請填入本地授權資源完整路徑|
|baseline/script/PR/TECH_MV/verify/config/verify_path.cfg|line 123|FILL_IN_RESOURCE_0187|請填入本地授權資源完整路徑|
|baseline/script/PR/TECH_MV/verify/config/verify_path.cfg|line 127|FILL_IN_RESOURCE_0188|請填入本地授權資源完整路徑|
|baseline/script/PR/TECH_MV/verify/config/verify_path.cfg|line 131|FILL_IN_RESOURCE_0189|請填入本地授權資源完整路徑|
|baseline/script/PR/TECH_MV/verify/config/verify_path.cfg|line 135|FILL_IN_RESOURCE_0190|請填入本地授權資源完整路徑|
|baseline/script/PR/TECH_MV/verify/config/verify_path.cfg|line 139|FILL_IN_RESOURCE_0191|請填入本地授權資源完整路徑|
|baseline/script/PR/TECH_MV/verify/config/verify_path.cfg|line 143|FILL_IN_RESOURCE_0192|請填入本地授權資源完整路徑|
|baseline/script/PR/TECH_MV/verify/config/verify_path.cfg|line 147|FILL_IN_RESOURCE_0193|請填入本地授權資源完整路徑|
|baseline/script/PR/TECH_MV/verify/config/verify_path.cfg|line 151|FILL_IN_RESOURCE_0194|請填入本地授權資源完整路徑|
|baseline/script/PR/TECH_MV/verify/config/verify_path.cfg|line 155|FILL_IN_RESOURCE_0195|請填入本地授權資源完整路徑|
|baseline/script/VCS_NLP/lib.cfg|line 1|FILL_IN_RESOURCE_0063|請填入本地授權資源完整路徑|
|baseline/script/VCS_NLP/lib.cfg|line 2|FILL_IN_RESOURCE_0064|請填入本地授權資源完整路徑|
|baseline/script/VCS_NLP/lib.cfg|line 3|FILL_IN_RESOURCE_0065|請填入本地授權資源完整路徑|
|baseline/script/VCS_NLP/lib.cfg|line 4|FILL_IN_RESOURCE_0066|請填入本地授權資源完整路徑|
|baseline/script/VCS_NLP/lib.cfg|line 5|FILL_IN_RESOURCE_0105|請填入本地授權資源完整路徑|
|baseline/script/VCS_NLP/lib.cfg|line 6|FILL_IN_RESOURCE_0106|請填入本地授權資源完整路徑|
|baseline/script/VCS_NLP/lib.cfg|line 7|FILL_IN_RESOURCE_0107|請填入本地授權資源完整路徑|
|baseline/script/VCS_NLP/lib.cfg|line 8|FILL_IN_RESOURCE_0070|請填入本地授權資源完整路徑|
|baseline/script/VCS_NLP/lib.cfg|line 9|FILL_IN_RESOURCE_0071|請填入本地授權資源完整路徑|
|baseline/script/VCS_NLP/lib.cfg|line 10|FILL_IN_LIBRARY_0074|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/VCS_NLP/lib.cfg|line 10|FILL_IN_LIBRARY_0075|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/VCS_NLP/lib.cfg|line 10|FILL_IN_LIBRARY_0076|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/VCS_NLP/lib.cfg|line 10|FILL_IN_LIBRARY_0081|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/VCS_NLP/lib.cfg|line 10|FILL_IN_LIBRARY_0077|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/VCS_NLP/lib.cfg|line 10|FILL_IN_LIBRARY_0078|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/VCS_NLP/lib.cfg|line 10|FILL_IN_LIBRARY_0079|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/spyglass/SDC2SGDC/sdc2sgdc.prj|line 24|FILL_IN_RESOURCE_0196|請填入本地授權資源完整路徑|
|baseline/script/spyglass/SDC2SGDC/sdc2sgdc.prj|line 26|FILL_IN_RESOURCE_0197|請填入本地授權資源完整路徑|
|baseline/script/spyglass/SDC2SGDC/sdc2sgdc.prj|line 28|FILL_IN_RESOURCE_0198|請填入本地授權資源完整路徑|
|baseline/script/spyglass/SDC2SGDC/sdc2sgdc.prj|line 41|FILL_IN_CELL_SRAM_002|請填入SRAM（32×64） cell；SRAM 宏實例與模型引用；深度與位寬依名稱，pin、電壓與讀寫行為須核對|
|baseline/script/spyglass/SDC2SGDC/sdc2sgdc.prj|line 41|FILL_IN_CELL_SRAM_001|請填入SRAM（32×32） cell；SRAM 宏實例與模型引用；深度與位寬依名稱，pin、電壓與讀寫行為須核對|
|baseline/script/spyglass/SDC2SGDC/sdc2sgdc.prj|line 41|FILL_IN_CELL_SRAM_006|請填入SRAM（16384×32） cell；SRAM 宏實例與模型引用；深度與位寬依名稱，pin、電壓與讀寫行為須核對|
|baseline/script/spyglass/SDC2SGDC/sdc2sgdc.prj|line 41|FILL_IN_CELL_ICG_009|請填入integrated clock gating（ICG）cell；依 TE/E/CP/Q 連接與 ICG 實例用途判定|
|baseline/script/spyglass/SDC2SGDC/sdc2sgdc.prj|line 41|FILL_IN_CELL_CLOCK_MUX_008|請填入clock mux cell；依 I0/I1/S/Z 連接與時脈選擇用途判定|
|baseline/script/spyglass/SDC2SGDC/sdc2sgdc.prj|line 41|FILL_IN_CELL_RTE_BOUNDARY_PAD_013|請填入RTE 邊界 pad cell；依 boundary／RTE rail 操作用途推定；精確電氣功能待 library 確認|
|baseline/script/spyglass/SDC2SGDC/sdc2sgdc.prj|line 41|FILL_IN_CELL_IO_POWER_PAD_014|請填入I/O power pad cell；依 VDDPST/VSSPST pin map 判定；POC 型號附加功能須確認|
|baseline/script/spyglass/SDC2SGDC/sdc2sgdc.prj|line 41|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/spyglass/SDC2SGDC/sdc2sgdc.prj|line 41|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/spyglass/SDC2SGDC/sdc2sgdc.prj|line 41|FILL_IN_CELL_DFF_ASYNC_SET_RESET_010|請填入具非同步 set/reset 的 D flip-flop cell；依 D/CP/CDN/SDN 接腳與程式註解判定；控制極性須核對模型|
|baseline/script/spyglass/SDC2SGDC/sdc2sgdc.prj|line 41|FILL_IN_CELL_DELAY_011|請填入delay cell；依 delay chain 中的 I/Z 連接判定；不可從名稱推定實際延遲|
|baseline/script/spyglass/system/Spyglass.sgdc|line 17|FILL_IN_CELL_SRAM_012|請填入SRAM（512×45） cell；SRAM 宏實例與模型引用；深度與位寬依名稱，pin、電壓與讀寫行為須核對|
|baseline/script/spyglass/system/Spyglass_CDC.tcl|line 9|FILL_IN_RESOURCE_0196|請填入本地授權資源完整路徑|
|baseline/script/spyglass/system/Spyglass_CDC.tcl|line 10|FILL_IN_RESOURCE_0197|請填入本地授權資源完整路徑|
|baseline/script/spyglass/system/Spyglass_CDC.tcl|line 11|FILL_IN_RESOURCE_0198|請填入本地授權資源完整路徑|
|baseline/script/spyglass/system/Spyglass_CDC.tcl|line 18|FILL_IN_CELL_SRAM_002|請填入SRAM（32×64） cell；SRAM 宏實例與模型引用；深度與位寬依名稱，pin、電壓與讀寫行為須核對|
|baseline/script/spyglass/system/Spyglass_CDC.tcl|line 18|FILL_IN_CELL_SRAM_001|請填入SRAM（32×32） cell；SRAM 宏實例與模型引用；深度與位寬依名稱，pin、電壓與讀寫行為須核對|
|baseline/script/spyglass/system/Spyglass_CDC.tcl|line 18|FILL_IN_CELL_SRAM_006|請填入SRAM（16384×32） cell；SRAM 宏實例與模型引用；深度與位寬依名稱，pin、電壓與讀寫行為須核對|
|baseline/script/spyglass/system/Spyglass_CDC.tcl|line 18|FILL_IN_CELL_ICG_009|請填入integrated clock gating（ICG）cell；依 TE/E/CP/Q 連接與 ICG 實例用途判定|
|baseline/script/spyglass/system/Spyglass_CDC.tcl|line 18|FILL_IN_CELL_CLOCK_MUX_008|請填入clock mux cell；依 I0/I1/S/Z 連接與時脈選擇用途判定|
|baseline/script/spyglass/system/Spyglass_CDC.tcl|line 18|FILL_IN_CELL_RTE_BOUNDARY_PAD_013|請填入RTE 邊界 pad cell；依 boundary／RTE rail 操作用途推定；精確電氣功能待 library 確認|
|baseline/script/spyglass/system/Spyglass_CDC.tcl|line 18|FILL_IN_CELL_IO_POWER_PAD_014|請填入I/O power pad cell；依 VDDPST/VSSPST pin map 判定；POC 型號附加功能須確認|
|baseline/script/spyglass/system/Spyglass_CDC.tcl|line 18|FILL_IN_CELL_DIGITAL_IO_PAD_015|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/spyglass/system/Spyglass_CDC.tcl|line 18|FILL_IN_CELL_DIGITAL_IO_PAD_016|請填入digital I/O pad cell；依 IO pad 分類與信號 pad 使用位置判定；方向及能力須核對|
|baseline/script/spyglass/system/Spyglass_CDC.tcl|line 18|FILL_IN_CELL_DFF_ASYNC_SET_RESET_010|請填入具非同步 set/reset 的 D flip-flop cell；依 D/CP/CDN/SDN 接腳與程式註解判定；控制極性須核對模型|
|baseline/script/spyglass/system/Spyglass_CDC.tcl|line 18|FILL_IN_CELL_DELAY_011|請填入delay cell；依 delay chain 中的 I/Z 連接判定；不可從名稱推定實際延遲|
|baseline/script/spyglass/system/Spyglass_RDC.tcl|line 11|FILL_IN_RESOURCE_0196|請填入本地授權資源完整路徑|
|baseline/script/spyglass/system/Spyglass_RDC.tcl|line 12|FILL_IN_RESOURCE_0197|請填入本地授權資源完整路徑|
|baseline/script/spyglass/system/Spyglass_RDC.tcl|line 13|FILL_IN_RESOURCE_0198|請填入本地授權資源完整路徑|
|baseline/script/spyglass/system/Spyglass_RDC.tcl|line 22|FILL_IN_CELL_SRAM_002|請填入SRAM（32×64） cell；SRAM 宏實例與模型引用；深度與位寬依名稱，pin、電壓與讀寫行為須核對|
|baseline/script/spyglass/system/Spyglass_RDC.tcl|line 22|FILL_IN_CELL_SRAM_001|請填入SRAM（32×32） cell；SRAM 宏實例與模型引用；深度與位寬依名稱，pin、電壓與讀寫行為須核對|
|baseline/script/spyglass/system/Spyglass_RDC.tcl|line 22|FILL_IN_CELL_SRAM_006|請填入SRAM（16384×32） cell；SRAM 宏實例與模型引用；深度與位寬依名稱，pin、電壓與讀寫行為須核對|
|baseline/script/PT/pt.tcl|line 4|FILL_IN_RESOURCE_0055|請填入本地授權資源完整路徑|
|baseline/script/PT/pt.tcl|line 5|FILL_IN_RESOURCE_0056|請填入本地授權資源完整路徑|
|baseline/script/PT/pt.tcl|line 11|FILL_IN_LIBRARY_0057|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/PT/pt.tcl|line 11|FILL_IN_LIBRARY_0058|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/PT/pt.tcl|line 11|FILL_IN_LIBRARY_0059|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/PT/pt.tcl|line 11|FILL_IN_LIBRARY_0060|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/script/formal/superlint.tcl|line 15|FILL_IN_CELL_SRAM_012|請填入SRAM（512×45） cell；SRAM 宏實例與模型引用；深度與位寬依名稱，pin、電壓與讀寫行為須核對|
|baseline/tools/audit_tech_public_release.py|line 21|FILL_IN_RESOURCE_0199|請填入本地授權資源完整路徑|
|baseline/tools/audit_tech_public_release.py|line 21|FILL_IN_RESOURCE_0200|請填入本地授權資源完整路徑|
|baseline/tools/sh/private/TT_extract_lowpower_spice_safe.sh|line 4|FILL_IN_RESOURCE_0201|請填入本地授權資源完整路徑|
|baseline/tools/sh/private/TT_extract_lowpower_spice_safe.sh|line 7|FILL_IN_LIBRARY_0202|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/tools/sh/private/TT_extract_lowpower_spice_safe.sh|line 9|FILL_IN_LIBRARY_0203|請填入對應 library／SRAM／LEF／deck 的檔名或搜尋名稱|
|baseline/tools/sh/private/TT_extract_spice_cells.sh|line 25|FILL_IN_RESOURCE_0201|請填入本地授權資源完整路徑|
|baseline/tools/sh/private/TT_extract_spice_cells.sh|line 32|FILL_IN_CELL_WELL_TAP_061|請填入well tap cell；依 welltap 設定與名稱判定|
|baseline/tools/sh/private/TT_extract_spice_cells.sh|line 33|FILL_IN_CELL_RETENTION_DFF_018|請填入retention flip-flop cell；依 UPF retention library 清單判定；scan、控制極性與 save/restore 行為須核對|
|baseline/tools/sh/private/TT_extract_spice_cells.sh|line 34|FILL_IN_CELL_POWER_SWITCH_029|請填入header power switch cell；依 power gating／switch chain 用途判定；容量與控制接腳須核對|
|baseline/.private_config/TECH_MV/ioPADt.rules.json|line 10|FILL_IN_CELL_IO_RAIL_CUT_052|請填入I/O power rail cut cell；依 domain rail 分段與 boundary 角色判定|

## materialized library 欄位補充

00_library.config.tcl 的 TECH_MV_LIBRARY_VALUES 每個值皆為填空；LIB_CELL 為 cell 名稱／清單，LIB_PIN 為 pin，LIB_TECH 為層名，LIB_MATCH 為 glob，LIB_QUERY 為查詢條件。

## Header switch family

00_library.config.tcl 的 HEADER_POWER_SWITCH_CELL_PATTERN：請填入 header power switch cell glob pattern。工具只讀此直接設定，不新增 source 或 setup_command。

## IO 設定

setup/CHIP.io 已改成原處填寫的最小範本，不含實際 pad 名稱或 offset。請填入本地 pad instance 與各邊座標。工具產生的 IOPAD_EDITED／DB_PATCH 已排除，不要重新加入。
