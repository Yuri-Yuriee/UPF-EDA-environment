# Script config 參數遮蔽

使用者設定保持原處 set／array／原命令參數填空，沒有新增 source、setup_command、PUBLIC_CFG 或動態載入。時脈、PVT、密度、RC、層名與幾何值依下表填入。一般開關、工具執行配額與程式邏輯保留。

行號為修改前位置，請優先搜尋填空代號。未填值前不能執行相關 EDA 階段。

|檔案|原行號|欄位|填空|應填內容|
|---|---:|---|---|---|
|script/DC/DC.sdc|2|cpu_clk_period|FILL_IN_cpu_clk_period|請填入此時脈週期，單位依 SDC／工具設定|
|script/DC/DC.sdc|3|axi_clk_period|FILL_IN_axi_clk_period|請填入此時脈週期，單位依 SDC／工具設定|
|script/DC/DC.sdc|4|rom_clk_period|FILL_IN_rom_clk_period|請填入此時脈週期，單位依 SDC／工具設定|
|script/DC/DC.sdc|5|dram_clk_period|FILL_IN_dram_clk_period|請填入此時脈週期，單位依 SDC／工具設定|
|script/DC/DC.sdc|16|set_clock_uncertainty_16|FILL_IN_set_clock_uncertainty_16|請填入 set_clock_uncertainty 所需的時序／負載限制，單位依工具設定|
|script/DC/DC.sdc|17|set_clock_latency_17|FILL_IN_set_clock_latency_17|請填入 set_clock_latency 所需的時序／負載限制，單位依工具設定|
|script/DC/DC.sdc|18|set_clock_transition_18|FILL_IN_set_clock_transition_18|請填入 set_clock_transition 所需的時序／負載限制，單位依工具設定|
|script/DC/DC.sdc|19|set_input_transition_19|FILL_IN_set_input_transition_19|請填入 set_input_transition 所需的時序／負載限制，單位依工具設定|
|script/DC/DC.sdc|23|PVT_CORNER_23_7|FILL_IN_PVT_CORNER_23_7|請填入 library 內的 operating condition／PVT corner 名稱|
|script/DC/DC.sdc|24|PVT_CORNER_24_7|FILL_IN_PVT_CORNER_24_7|請填入 library 內的 operating condition／PVT corner 名稱|
|script/DC/DC.sdc|153|set_load_153|FILL_IN_set_load_153|請填入 set_load 所需的時序／負載限制，單位依工具設定|
|script/DC/synopsys_dc.setup|29|PVT_CORNER_29_21|FILL_IN_PVT_CORNER_29_21|請填入 library 內的 operating condition／PVT corner 名稱|
|script/DC/synopsys_dc.setup|38|PVT_CORNER_38_21|FILL_IN_PVT_CORNER_38_21|請填入 library 內的 operating condition／PVT corner 名稱|
|script/MV/DVFS/synopsys_dc.setup|526|PVT_CORNER_526_14|FILL_IN_PVT_CORNER_526_14|請填入 library 內的 operating condition／PVT corner 名稱|
|script/MV/DVFS/synopsys_dc.setup|527|PVT_CORNER_527_14|FILL_IN_PVT_CORNER_527_14|請填入 library 內的 operating condition／PVT corner 名稱|
|script/MV/SDC/DC.sdc|2|cpu_clk_period|FILL_IN_cpu_clk_period|請填入此時脈週期，單位依 SDC／工具設定|
|script/MV/SDC/DC.sdc|3|axi_clk_period|FILL_IN_axi_clk_period|請填入此時脈週期，單位依 SDC／工具設定|
|script/MV/SDC/DC.sdc|4|rom_clk_period|FILL_IN_rom_clk_period|請填入此時脈週期，單位依 SDC／工具設定|
|script/MV/SDC/DC.sdc|5|dram_clk_period|FILL_IN_dram_clk_period|請填入此時脈週期，單位依 SDC／工具設定|
|script/MV/SDC/DC.sdc|16|set_clock_uncertainty_16|FILL_IN_set_clock_uncertainty_16|請填入 set_clock_uncertainty 所需的時序／負載限制，單位依工具設定|
|script/MV/SDC/DC.sdc|17|set_clock_latency_17|FILL_IN_set_clock_latency_17|請填入 set_clock_latency 所需的時序／負載限制，單位依工具設定|
|script/MV/SDC/DC.sdc|18|set_clock_transition_18|FILL_IN_set_clock_transition_18|請填入 set_clock_transition 所需的時序／負載限制，單位依工具設定|
|script/MV/SDC/DC.sdc|19|set_input_transition_19|FILL_IN_set_input_transition_19|請填入 set_input_transition 所需的時序／負載限制，單位依工具設定|
|script/MV/SDC/DC.sdc|26|PVT_CORNER_26_13|FILL_IN_PVT_CORNER_26_13|請填入 library 內的 operating condition／PVT corner 名稱|
|script/MV/SDC/DC.sdc|27|PVT_CORNER_27_13|FILL_IN_PVT_CORNER_27_13|請填入 library 內的 operating condition／PVT corner 名稱|
|script/MV/SDC/DC.sdc|31|PVT_CORNER_31_13|FILL_IN_PVT_CORNER_31_13|請填入 library 內的 operating condition／PVT corner 名稱|
|script/MV/SDC/DC.sdc|32|PVT_CORNER_32_13|FILL_IN_PVT_CORNER_32_13|請填入 library 內的 operating condition／PVT corner 名稱|
|script/MV/SDC/DC.sdc|237|set_load_237|FILL_IN_set_load_237|請填入 set_load 所需的時序／負載限制，單位依工具設定|
|script/PR/TECH_MV/setup/mmmc.view.stylus|89|pre_route_res_89|FILL_IN_pre_route_res_89|請填入本地設計／製程的設定值，保持原資料型別|
|script/PR/TECH_MV/setup/mmmc.view.stylus|90|post_route_res_90|FILL_IN_post_route_res_90|請填入本地設計／製程的設定值，保持原資料型別|
|script/PR/TECH_MV/setup/mmmc.view.stylus|91|pre_route_cap_91|FILL_IN_pre_route_cap_91|請填入本地設計／製程的設定值，保持原資料型別|
|script/PR/TECH_MV/setup/mmmc.view.stylus|92|post_route_cap_92|FILL_IN_post_route_cap_92|請填入本地設計／製程的設定值，保持原資料型別|
|script/PR/TECH_MV/setup/mmmc.view.stylus|93|post_route_cross_cap_93|FILL_IN_post_route_cross_cap_93|請填入本地設計／製程的設定值，保持原資料型別|
|script/PR/TECH_MV/setup/mmmc.view.stylus|94|pre_route_clock_res_94|FILL_IN_pre_route_clock_res_94|請填入本地設計／製程的設定值，保持原資料型別|
|script/PR/TECH_MV/setup/mmmc.view.stylus|95|pre_route_clock_cap_95|FILL_IN_pre_route_clock_cap_95|請填入本地設計／製程的設定值，保持原資料型別|
|script/PR/TECH_MV/setup/mmmc.view.stylus|96|temperature_96|FILL_IN_temperature_96|請填入 RC／timing corner 的溫度（依工具單位）|
|script/PR/TECH_MV/setup/mmmc.view.stylus|100|pre_route_res_100|FILL_IN_pre_route_res_100|請填入本地設計／製程的設定值，保持原資料型別|
|script/PR/TECH_MV/setup/mmmc.view.stylus|101|post_route_res_101|FILL_IN_post_route_res_101|請填入本地設計／製程的設定值，保持原資料型別|
|script/PR/TECH_MV/setup/mmmc.view.stylus|102|pre_route_cap_102|FILL_IN_pre_route_cap_102|請填入本地設計／製程的設定值，保持原資料型別|
|script/PR/TECH_MV/setup/mmmc.view.stylus|103|post_route_cap_103|FILL_IN_post_route_cap_103|請填入本地設計／製程的設定值，保持原資料型別|
|script/PR/TECH_MV/setup/mmmc.view.stylus|104|post_route_cross_cap_104|FILL_IN_post_route_cross_cap_104|請填入本地設計／製程的設定值，保持原資料型別|
|script/PR/TECH_MV/setup/mmmc.view.stylus|105|pre_route_clock_res_105|FILL_IN_pre_route_clock_res_105|請填入本地設計／製程的設定值，保持原資料型別|
|script/PR/TECH_MV/setup/mmmc.view.stylus|106|pre_route_clock_cap_106|FILL_IN_pre_route_clock_cap_106|請填入本地設計／製程的設定值，保持原資料型別|
|script/PR/TECH_MV/setup/mmmc.view.stylus|107|temperature_107|FILL_IN_temperature_107|請填入 RC／timing corner 的溫度（依工具單位）|
|script/PR/TECH_MV/setup/config/00_design.config.tcl|56|MAX_DERATE_EARLY|FILL_IN_MAX_DERATE_EARLY|請填入對應 corner 的 derate／縮放係數|
|script/PR/TECH_MV/setup/config/00_design.config.tcl|57|MAX_DERATE_LATE|FILL_IN_MAX_DERATE_LATE|請填入對應 corner 的 derate／縮放係數|
|script/PR/TECH_MV/setup/config/00_design.config.tcl|58|MIN_DERATE_EARLY|FILL_IN_MIN_DERATE_EARLY|請填入對應 corner 的 derate／縮放係數|
|script/PR/TECH_MV/setup/config/00_design.config.tcl|59|MIN_DERATE_LATE|FILL_IN_MIN_DERATE_LATE|請填入對應 corner 的 derate／縮放係數|
|script/PR/TECH_MV/setup/config/01_floorplan.config.tcl|47|FLOORPLAN_CORE_DENSITY_TARGET|FILL_IN_FLOORPLAN_CORE_DENSITY_TARGET|請填入本地 floorplan／placement 的利用率或密度比例|
|script/PR/TECH_MV/setup/config/02_powerplan.config.tcl|293|FOLLOW_PIN_RING_OVERLAP_REPAIR_LAYERS|FILL_IN_FOLLOW_PIN_RING_OVERLAP_REPAIR_LAYERS|請填入本地 PDK 的金屬層／via 層名或層清單|
|script/PR/TECH_MV/setup/config/05_route.config.tcl|8|::SECONDARY_PG_RAIL_LAYER|FILL_IN_SECONDARY_PG_RAIL_LAYER|請填入本地 PDK 的金屬層／via 層名或層清單|
|script/PR/TECH_MV/setup/config/05_route.config.tcl|10|::SECONDARY_PG_BOTTOM_LAYER|FILL_IN_SECONDARY_PG_BOTTOM_LAYER|請填入本地 PDK 的金屬層／via 層名或層清單|
|script/PR/TECH_MV/setup/config/05_route.config.tcl|12|::SECONDARY_PG_TOP_LAYER|FILL_IN_SECONDARY_PG_TOP_LAYER|請填入本地 PDK 的金屬層／via 層名或層清單|
|script/PR/TECH_MV/setup/config/05_route.config.tcl|31|ROUTE_DETAIL_END_ITERATION|FILL_IN_ROUTE_DETAIL_END_ITERATION|請填入本地設計／製程的設定值，保持原資料型別|
|script/PR/TECH_MV/setup/config/05_route.config.tcl|69|ANTENNA_ROUTE_MAX_CANDIDATE_NETS|FILL_IN_ANTENNA_ROUTE_MAX_CANDIDATE_NETS|請填入本地設計／製程的設定值，保持原資料型別|
|script/PR/TECH_MV/setup/config/90_debug.config.tcl|14|::TT_CP2_REPAIR_REROUTE_2NDPG|FILL_IN_TT_CP2_REPAIR_REROUTE_2NDPG|請填入本地設計／製程的設定值，保持原資料型別|
|script/PR/TECH_MV/setup/config/90_debug.config.tcl|74|::CHECK_STAGE02_METAL_DENSITY_LAYERS|FILL_IN_CHECK_STAGE02_METAL_DENSITY_LAYERS|請填入本地 floorplan／placement 的利用率或密度比例|
|script/PR/TECH_MV/setup/config/90_debug.config.tcl|81|::CHECK_STAGE05_METAL_DENSITY_LAYERS|FILL_IN_CHECK_STAGE05_METAL_DENSITY_LAYERS|請填入本地 floorplan／placement 的利用率或密度比例|
|script/PR/TECH_MV/setup/config/90_debug.config.tcl|88|::CHECK_STAGE06_METAL_DENSITY_LAYERS|FILL_IN_CHECK_STAGE06_METAL_DENSITY_LAYERS|請填入本地 floorplan／placement 的利用率或密度比例|
|script/PT/ptpx.sdc|2|cpu_clk_period|FILL_IN_cpu_clk_period|請填入此時脈週期，單位依 SDC／工具設定|
|script/PT/ptpx.sdc|3|axi_clk_period|FILL_IN_axi_clk_period|請填入此時脈週期，單位依 SDC／工具設定|
|script/PT/ptpx.sdc|4|rom_clk_period|FILL_IN_rom_clk_period|請填入此時脈週期，單位依 SDC／工具設定|
|script/PT/ptpx.sdc|5|dram_clk_period|FILL_IN_dram_clk_period|請填入此時脈週期，單位依 SDC／工具設定|
|script/PT/ptpx.sdc|20|set_clock_uncertainty_20|FILL_IN_set_clock_uncertainty_20|請填入 set_clock_uncertainty 所需的時序／負載限制，單位依工具設定|
|script/PT/ptpx.sdc|21|set_clock_latency_21|FILL_IN_set_clock_latency_21|請填入 set_clock_latency 所需的時序／負載限制，單位依工具設定|
|script/PT/ptpx.sdc|22|set_input_transition_22|FILL_IN_set_input_transition_22|請填入 set_input_transition 所需的時序／負載限制，單位依工具設定|
|script/PT/ptpx.sdc|23|set_clock_transition_23|FILL_IN_set_clock_transition_23|請填入 set_clock_transition 所需的時序／負載限制，單位依工具設定|
|script/PT/ptpx.sdc|27|PVT_CORNER_27_13|FILL_IN_PVT_CORNER_27_13|請填入 library 內的 operating condition／PVT corner 名稱|
|script/PT/ptpx.sdc|28|PVT_CORNER_28_13|FILL_IN_PVT_CORNER_28_13|請填入 library 內的 operating condition／PVT corner 名稱|
|script/PT/ptpx.sdc|80|set_load_80|FILL_IN_set_load_80|請填入 set_load 所需的時序／負載限制，單位依工具設定|
|script/spyglass/SDC2SGDC/case.sdc|8|config_option|FILL_IN_config_option|請填入本地設計／製程的設定值，保持原資料型別|
|script/spyglass/SDC2SGDC/case.sdc|17|CK_MUX_SEL_0|FILL_IN_CK_MUX_SEL_0|請填入本地設計／製程的設定值，保持原資料型別|
|script/spyglass/SDC2SGDC/case.sdc|18|CK_MUX_SEL_1|FILL_IN_CK_MUX_SEL_1|請填入本地設計／製程的設定值，保持原資料型別|
|script/spyglass/SDC2SGDC/case.sdc|23|CK_MUX_SEL_0|FILL_IN_CK_MUX_SEL_0|請填入本地設計／製程的設定值，保持原資料型別|
|script/spyglass/SDC2SGDC/case.sdc|24|CK_MUX_SEL_1|FILL_IN_CK_MUX_SEL_1|請填入本地設計／製程的設定值，保持原資料型別|
|script/spyglass/SDC2SGDC/case.sdc|29|CK_MUX_SEL_0|FILL_IN_CK_MUX_SEL_0|請填入本地設計／製程的設定值，保持原資料型別|
|script/spyglass/SDC2SGDC/case.sdc|30|CK_MUX_SEL_1|FILL_IN_CK_MUX_SEL_1|請填入本地設計／製程的設定值，保持原資料型別|
|script/spyglass/SDC2SGDC/case.sdc|35|CK_MUX_SEL_0|FILL_IN_CK_MUX_SEL_0|請填入本地設計／製程的設定值，保持原資料型別|
|script/spyglass/SDC2SGDC/case.sdc|36|CK_MUX_SEL_1|FILL_IN_CK_MUX_SEL_1|請填入本地設計／製程的設定值，保持原資料型別|
|script/DC/DC.sdc|118|補充電氣／時序參數|FILL_IN_TIMING_VALUE_input_max_axi_clk|請填入 I/O timing delay 值|
|script/DC/DC.sdc|119|補充電氣／時序參數|FILL_IN_TIMING_VALUE_input_min_axi_clk|請填入 I/O timing delay 值|
|script/DC/DC.sdc|120|補充電氣／時序參數|FILL_IN_TIMING_VALUE_output_max_axi_clk|請填入 I/O timing delay 值|
|script/DC/DC.sdc|121|補充電氣／時序參數|FILL_IN_TIMING_VALUE_output_min_axi_clk|請填入 I/O timing delay 值|
|script/DC/DC.sdc|133|補充電氣／時序參數|FILL_IN_TIMING_VALUE_input_max_rom_clk|請填入 I/O timing delay 值|
|script/DC/DC.sdc|134|補充電氣／時序參數|FILL_IN_TIMING_VALUE_input_min_rom_clk|請填入 I/O timing delay 值|
|script/DC/DC.sdc|135|補充電氣／時序參數|FILL_IN_TIMING_VALUE_output_max_rom_clk|請填入 I/O timing delay 值|
|script/DC/DC.sdc|136|補充電氣／時序參數|FILL_IN_TIMING_VALUE_output_min_rom_clk|請填入 I/O timing delay 值|
|script/DC/DC.sdc|148|補充電氣／時序參數|FILL_IN_TIMING_VALUE_input_max_dram_clk|請填入 I/O timing delay 值|
|script/DC/DC.sdc|149|補充電氣／時序參數|FILL_IN_TIMING_VALUE_input_min_dram_clk|請填入 I/O timing delay 值|
|script/DC/DC.sdc|150|補充電氣／時序參數|FILL_IN_TIMING_VALUE_output_max_dram_clk|請填入 I/O timing delay 值|
|script/DC/DC.sdc|151|補充電氣／時序參數|FILL_IN_TIMING_VALUE_output_min_dram_clk|請填入 I/O timing delay 值|
|script/MV/SDC/DC.sdc|48|補充電氣／時序參數|FILL_IN_PVT_CONDITION_48_9|請填入多電壓 operating condition 的 PVT corner 名稱|
|script/MV/SDC/DC.sdc|49|補充電氣／時序參數|FILL_IN_PVT_CONDITION_49_9|請填入多電壓 operating condition 的 PVT corner 名稱|
|script/MV/SDC/DC.sdc|51|補充電氣／時序參數|FILL_IN_ELECTRICAL_VALUE_51_12|請填入 voltage 或 derate 值，單位依命令定義|
|script/MV/SDC/DC.sdc|51|補充電氣／時序參數|FILL_IN_ELECTRICAL_VALUE_51_22|請填入 voltage 或 derate 值，單位依命令定義|
|script/MV/SDC/DC.sdc|53|補充電氣／時序參數|FILL_IN_ELECTRICAL_VALUE_53_12|請填入 voltage 或 derate 值，單位依命令定義|
|script/MV/SDC/DC.sdc|53|補充電氣／時序參數|FILL_IN_ELECTRICAL_VALUE_53_22|請填入 voltage 或 derate 值，單位依命令定義|
|script/MV/SDC/DC.sdc|55|補充電氣／時序參數|FILL_IN_ELECTRICAL_VALUE_55_12|請填入 voltage 或 derate 值，單位依命令定義|
|script/MV/SDC/DC.sdc|55|補充電氣／時序參數|FILL_IN_ELECTRICAL_VALUE_55_21|請填入 voltage 或 derate 值，單位依命令定義|
|script/MV/SDC/DC.sdc|57|補充電氣／時序參數|FILL_IN_ELECTRICAL_VALUE_57_12|請填入 voltage 或 derate 值，單位依命令定義|
|script/MV/SDC/DC.sdc|193|補充電氣／時序參數|FILL_IN_TIMING_VALUE_input_max_cpu_clk|請填入 I/O timing delay 值|
|script/MV/SDC/DC.sdc|194|補充電氣／時序參數|FILL_IN_TIMING_VALUE_input_min_cpu_clk|請填入 I/O timing delay 值|
|script/MV/SDC/DC.sdc|195|補充電氣／時序參數|FILL_IN_TIMING_VALUE_output_max_cpu_clk|請填入 I/O timing delay 值|
|script/MV/SDC/DC.sdc|196|補充電氣／時序參數|FILL_IN_TIMING_VALUE_output_min_cpu_clk|請填入 I/O timing delay 值|
|script/MV/SDC/DC.sdc|206|補充電氣／時序參數|FILL_IN_TIMING_VALUE_input_max_axi_clk|請填入 I/O timing delay 值|
|script/MV/SDC/DC.sdc|207|補充電氣／時序參數|FILL_IN_TIMING_VALUE_input_min_axi_clk|請填入 I/O timing delay 值|
|script/MV/SDC/DC.sdc|208|補充電氣／時序參數|FILL_IN_TIMING_VALUE_output_max_axi_clk|請填入 I/O timing delay 值|
|script/MV/SDC/DC.sdc|209|補充電氣／時序參數|FILL_IN_TIMING_VALUE_output_min_axi_clk|請填入 I/O timing delay 值|
|script/MV/SDC/DC.sdc|219|補充電氣／時序參數|FILL_IN_TIMING_VALUE_input_max_rom_clk|請填入 I/O timing delay 值|
|script/MV/SDC/DC.sdc|220|補充電氣／時序參數|FILL_IN_TIMING_VALUE_input_min_rom_clk|請填入 I/O timing delay 值|
|script/MV/SDC/DC.sdc|221|補充電氣／時序參數|FILL_IN_TIMING_VALUE_output_max_rom_clk|請填入 I/O timing delay 值|
|script/MV/SDC/DC.sdc|222|補充電氣／時序參數|FILL_IN_TIMING_VALUE_output_min_rom_clk|請填入 I/O timing delay 值|
|script/MV/SDC/DC.sdc|234|補充電氣／時序參數|FILL_IN_TIMING_VALUE_input_max_dram_clk|請填入 I/O timing delay 值|
|script/MV/SDC/DC.sdc|235|補充電氣／時序參數|FILL_IN_TIMING_VALUE_input_min_dram_clk|請填入 I/O timing delay 值|
|script/MV/SDC/DC.sdc|236|補充電氣／時序參數|FILL_IN_TIMING_VALUE_output_max_dram_clk|請填入 I/O timing delay 值|
|script/MV/SDC/DC.sdc|237|補充電氣／時序參數|FILL_IN_TIMING_VALUE_output_min_dram_clk|請填入 I/O timing delay 值|
|script/PT/ptpx.sdc|52|補充電氣／時序參數|FILL_IN_TIMING_VALUE_input_max_axi_clk|請填入 I/O timing delay 值|
|script/PT/ptpx.sdc|53|補充電氣／時序參數|FILL_IN_TIMING_VALUE_input_min_axi_clk|請填入 I/O timing delay 值|
|script/PT/ptpx.sdc|54|補充電氣／時序參數|FILL_IN_TIMING_VALUE_output_max_axi_clk|請填入 I/O timing delay 值|
|script/PT/ptpx.sdc|55|補充電氣／時序參數|FILL_IN_TIMING_VALUE_output_min_axi_clk|請填入 I/O timing delay 值|
|script/PT/ptpx.sdc|63|補充電氣／時序參數|FILL_IN_TIMING_VALUE_input_max_rom_clk|請填入 I/O timing delay 值|
|script/PT/ptpx.sdc|64|補充電氣／時序參數|FILL_IN_TIMING_VALUE_input_min_rom_clk|請填入 I/O timing delay 值|
|script/PT/ptpx.sdc|65|補充電氣／時序參數|FILL_IN_TIMING_VALUE_output_max_rom_clk|請填入 I/O timing delay 值|
|script/PT/ptpx.sdc|66|補充電氣／時序參數|FILL_IN_TIMING_VALUE_output_min_rom_clk|請填入 I/O timing delay 值|
|script/PT/ptpx.sdc|74|補充電氣／時序參數|FILL_IN_TIMING_VALUE_input_max_dram_clk|請填入 I/O timing delay 值|
|script/PT/ptpx.sdc|75|補充電氣／時序參數|FILL_IN_TIMING_VALUE_input_min_dram_clk|請填入 I/O timing delay 值|
|script/PT/ptpx.sdc|76|補充電氣／時序參數|FILL_IN_TIMING_VALUE_output_max_dram_clk|請填入 I/O timing delay 值|
|script/PT/ptpx.sdc|77|補充電氣／時序參數|FILL_IN_TIMING_VALUE_output_min_dram_clk|請填入 I/O timing delay 值|
