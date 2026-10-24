##### CLK PERIOD #####
# 請填入此時脈週期，單位依 SDC／工具設定
set cpu_clk_period  {FILL_IN_cpu_clk_period}
# 請填入此時脈週期，單位依 SDC／工具設定
set axi_clk_period  {FILL_IN_axi_clk_period}
# 請填入此時脈週期，單位依 SDC／工具設定
set rom_clk_period  {FILL_IN_rom_clk_period}
# 請填入此時脈週期，單位依 SDC／工具設定
set dram_clk_period {FILL_IN_dram_clk_period}

create_clock -name cpu_clk  -period $cpu_clk_period  [get_ports cpu_clk]
create_clock -name axi_clk  -period $axi_clk_period  [get_ports axi_clk]
create_clock -name rom_clk  -period $rom_clk_period  [get_ports rom_clk]
create_clock -name dram_clk -period $dram_clk_period [get_ports dram_clk]
set DVFS_PATH u_TOP/u_pmu/u_dvfs



set_dont_touch_network [all_clocks]
# 請填入本地時序／負載限制值
set_clock_uncertainty  {FILL_IN_set_clock_uncertainty_16} [all_clocks]
# 請填入本地時序／負載限制值
set_clock_latency      {FILL_IN_set_clock_latency_17} [all_clocks]
# 請填入本地時序／負載限制值
set_clock_transition   {FILL_IN_set_clock_transition_18} [all_clocks]
# 請填入本地時序／負載限制值
set_input_transition {FILL_IN_set_input_transition_19} [remove_from_collection [all_inputs] [get_ports -quiet {cpu_clk axi_clk rom_clk dram_clk}]]
set_ideal_network      [get_ports *clk]



set_operating_conditions \
        -analysis_type bc_wc \
# 請填入 library 的 PVT corner 名稱
        -max FILL_IN_PVT_CORNER_26_13 \
# 請填入 library 的 PVT corner 名稱
        -min FILL_IN_PVT_CORNER_27_13 

set_operating_conditions \
        -analysis_type bc_wc \
# 請填入 library 的 PVT corner 名稱
        -max FILL_IN_PVT_CORNER_31_13 \
# 請填入 library 的 PVT corner 名稱
        -min FILL_IN_PVT_CORNER_32_13 

set_operating_conditions \
    -analysis_type bc_wc \
    -max FILL_IN_PVT_CONDITION_48_9 \
    -min FILL_IN_PVT_CONDITION_49_9  

set_voltage {FILL_IN_ELECTRICAL_VALUE_51_12} -min {FILL_IN_ELECTRICAL_VALUE_51_22} -object_list {VDDPST}

set_voltage {FILL_IN_ELECTRICAL_VALUE_53_12} -min {FILL_IN_ELECTRICAL_VALUE_53_22} -object_list {VDD_LEVEL_01 PD_core.primary.power PD_CPU_ALWY_ON.primary.power CPU_source_power.power CPU_prim_PG.power CPU_retention.power CPU_isolation.power}

set_voltage {FILL_IN_ELECTRICAL_VALUE_55_12} -min {FILL_IN_ELECTRICAL_VALUE_55_21} -object_list {VDD_LEVEL_02 PD_TOP.primary.power WDT_source_power.power WDT_prim_PG.power WDT_retention.power WDT_isolation.power}

set_voltage {FILL_IN_ELECTRICAL_VALUE_57_12} -object_list {VSS CPU_source_power.ground CPU_prim_PG.ground CPU_retention.ground CPU_isolation.ground WDT_source_power.ground WDT_prim_PG.ground WDT_retention.ground WDT_isolation.ground}

#============================================================
# DVFS clk mux generated clocks
#============================================================
#rom dram mux
create_generated_clock -add -name dvfs_l0_0_from_rom \
  -combinational -master_clock rom_clk \
  -source [get_pins ${DVFS_PATH}/u_dvfs_ckmux_l0_0/I0] \
  [get_pins ${DVFS_PATH}/u_dvfs_ckmux_l0_0/Z]

create_generated_clock -add -name dvfs_l0_0_from_dram \
  -combinational -master_clock dram_clk \
  -source [get_pins ${DVFS_PATH}/u_dvfs_ckmux_l0_0/I1] \
  [get_pins ${DVFS_PATH}/u_dvfs_ckmux_l0_0/Z]

set_clock_groups -logically_exclusive \
  -group {dvfs_l0_0_from_rom} \
  -group {dvfs_l0_0_from_dram}

#axi cpu mux 
create_generated_clock -add -name dvfs_l0_1_from_axi \
  -combinational -master_clock axi_clk \
  -source [get_pins ${DVFS_PATH}/u_dvfs_ckmux_l0_1/I0] \
  [get_pins ${DVFS_PATH}/u_dvfs_ckmux_l0_1/Z]

create_generated_clock -add -name dvfs_l0_1_from_cpu \
  -combinational -master_clock cpu_clk \
  -source [get_pins ${DVFS_PATH}/u_dvfs_ckmux_l0_1/I1] \
  [get_pins ${DVFS_PATH}/u_dvfs_ckmux_l0_1/Z]

set_clock_groups -logically_exclusive \
  -group {dvfs_l0_1_from_axi} \
  -group {dvfs_l0_1_from_cpu}

#l2 mux
create_generated_clock -add -name dvfs_cpu_from_rom \
  -combinational -master_clock dvfs_l0_0_from_rom \
  -source [get_pins ${DVFS_PATH}/u_dvfs_ckmux_l1/I0] \
  [get_pins ${DVFS_PATH}/u_dvfs_ckmux_l1/Z]

create_generated_clock -add -name dvfs_cpu_from_dram \
  -combinational -master_clock dvfs_l0_0_from_dram \
  -source [get_pins ${DVFS_PATH}/u_dvfs_ckmux_l1/I0] \
  [get_pins ${DVFS_PATH}/u_dvfs_ckmux_l1/Z]

create_generated_clock -add -name dvfs_cpu_from_axi \
  -combinational -master_clock dvfs_l0_1_from_axi \
  -source [get_pins ${DVFS_PATH}/u_dvfs_ckmux_l1/I1] \
  [get_pins ${DVFS_PATH}/u_dvfs_ckmux_l1/Z]

create_generated_clock -add -name dvfs_cpu_from_cpu \
  -combinational -master_clock dvfs_l0_1_from_cpu \
  -source [get_pins ${DVFS_PATH}/u_dvfs_ckmux_l1/I1] \
  [get_pins ${DVFS_PATH}/u_dvfs_ckmux_l1/Z]

set_clock_groups -logically_exclusive \
  -group {dvfs_cpu_from_rom} \
  -group {dvfs_cpu_from_dram} \
  -group {dvfs_cpu_from_axi} \
  -group {dvfs_cpu_from_cpu}

set_ideal_network [get_pins ${DVFS_PATH}/u_dvfs_ckmux_l0_0/Z]
set_ideal_network [get_pins ${DVFS_PATH}/u_dvfs_ckmux_l0_1/Z]
set_ideal_network [get_pins ${DVFS_PATH}/u_dvfs_ckmux_l1/Z]

set_clock_groups -asynchronous \
  -group [get_clocks cpu_clk] \
  -group [get_clocks axi_clk] \
  -group [get_clocks rom_clk] \
  -group [get_clocks dram_clk] \
  -group [get_clocks dvfs_l0_0_from_rom] \
  -group [get_clocks dvfs_l0_0_from_dram] \
  -group [get_clocks dvfs_l0_1_from_axi] \
  -group [get_clocks dvfs_l0_1_from_cpu] \
  -group [get_clocks dvfs_cpu_from_rom] \
  -group [get_clocks dvfs_cpu_from_dram] \
  -group [get_clocks dvfs_cpu_from_axi] \
  -group [get_clocks dvfs_cpu_from_cpu]


#============================================================
# IO Port Groups
#============================================================

# CPU interface
# set cpu_input_ports [get_ports {
#     cpu_rst
# }]

# set cpu_output_ports [get_ports {
# }]

# AXI interface
# set axi_input_ports [get_ports {
#     axi_rst
# }]

set axi_output_ports [get_ports {
    v_ctrl_idx[*] 
    v_ctrl 
}]

# ROM interface
set rom_input_ports [get_ports {
    ROM_out[*]
}]

set rom_output_ports [get_ports {
    ROM_read
    ROM_enable 
    ROM_address[*]
}]

# DRAM interface
set dram_input_ports [get_ports {
    DRAM_Q[*]
    DRAM_valid
}]

set dram_output_ports [get_ports {
    DRAM_CSn
    DRAM_WEn[*]
    DRAM_RASn
    DRAM_CASn
    DRAM_A[*]
    DRAM_D[*]
}]




#============================================================
# CPU Interface IO Delay
#============================================================

# 請填入此 I/O timing delay 值，單位依 SDC 設定
set input_max_cpu_clk {FILL_IN_TIMING_VALUE_input_max_cpu_clk}
# 請填入此 I/O timing delay 值，單位依 SDC 設定
set input_min_cpu_clk {FILL_IN_TIMING_VALUE_input_min_cpu_clk}
# 請填入此 I/O timing delay 值，單位依 SDC 設定
set output_max_cpu_clk {FILL_IN_TIMING_VALUE_output_max_cpu_clk}
# 請填入此 I/O timing delay 值，單位依 SDC 設定
set output_min_cpu_clk {FILL_IN_TIMING_VALUE_output_min_cpu_clk}
#set_input_delay  -max $input_max_cpu_clk  -clock cpu_clk $cpu_input_ports
#set_input_delay  -min $input_min_cpu_clk  -clock cpu_clk $cpu_input_ports
# set_output_delay -max $output_max_cpu_clk -clock cpu_clk $cpu_output_ports
# set_output_delay -min $output_min_cpu_clk -clock cpu_clk $cpu_output_ports

#============================================================
# AXI Interface IO Delay
#============================================================

# 請填入此 I/O timing delay 值，單位依 SDC 設定
set input_max_axi_clk {FILL_IN_TIMING_VALUE_input_max_axi_clk}
# 請填入此 I/O timing delay 值，單位依 SDC 設定
set input_min_axi_clk {FILL_IN_TIMING_VALUE_input_min_axi_clk}
# 請填入此 I/O timing delay 值，單位依 SDC 設定
set output_max_axi_clk {FILL_IN_TIMING_VALUE_output_max_axi_clk}
# 請填入此 I/O timing delay 值，單位依 SDC 設定
set output_min_axi_clk {FILL_IN_TIMING_VALUE_output_min_axi_clk}
#set_input_delay  -max $input_max_axi_clk  -clock axi_clk $axi_input_ports
#set_input_delay  -min $input_min_axi_clk  -clock axi_clk $axi_input_ports
set_output_delay -max $output_max_axi_clk -clock axi_clk $axi_output_ports
set_output_delay -min $output_min_axi_clk -clock axi_clk $axi_output_ports

#============================================================
# ROM Interface IO Delay
#============================================================

# 請填入此 I/O timing delay 值，單位依 SDC 設定
set input_max_rom_clk {FILL_IN_TIMING_VALUE_input_max_rom_clk}
# 請填入此 I/O timing delay 值，單位依 SDC 設定
set input_min_rom_clk {FILL_IN_TIMING_VALUE_input_min_rom_clk}
# 請填入此 I/O timing delay 值，單位依 SDC 設定
set output_max_rom_clk {FILL_IN_TIMING_VALUE_output_max_rom_clk}
# 請填入此 I/O timing delay 值，單位依 SDC 設定
set output_min_rom_clk {FILL_IN_TIMING_VALUE_output_min_rom_clk}

set_input_delay  -max $input_max_rom_clk  -clock rom_clk $rom_input_ports
set_input_delay  -min $input_min_rom_clk  -clock rom_clk $rom_input_ports
set_output_delay -max $output_max_rom_clk -clock rom_clk $rom_output_ports
set_output_delay -min $output_min_rom_clk -clock rom_clk $rom_output_ports


#============================================================
# DRAM Interface IO Delay
#============================================================

# 請填入此 I/O timing delay 值，單位依 SDC 設定
set input_max_dram_clk {FILL_IN_TIMING_VALUE_input_max_dram_clk}
# 請填入此 I/O timing delay 值，單位依 SDC 設定
set input_min_dram_clk {FILL_IN_TIMING_VALUE_input_min_dram_clk}
# 請填入此 I/O timing delay 值，單位依 SDC 設定
set output_max_dram_clk {FILL_IN_TIMING_VALUE_output_max_dram_clk}
# 請填入此 I/O timing delay 值，單位依 SDC 設定
set output_min_dram_clk {FILL_IN_TIMING_VALUE_output_min_dram_clk}

set_input_delay  -max $input_max_dram_clk  -clock dram_clk $dram_input_ports
set_input_delay  -min $input_min_dram_clk  -clock dram_clk $dram_input_ports
set_output_delay -max $output_max_dram_clk -clock dram_clk $dram_output_ports
set_output_delay -min $output_min_dram_clk -clock dram_clk $dram_output_ports


#============================================================
# Output Load
#============================================================

# 請填入本地時序／負載限制值
set_load {FILL_IN_set_load_237} [all_outputs]



# set auto_wire_load_selection

