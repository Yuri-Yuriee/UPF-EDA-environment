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
# 請填入 library 的 PVT corner 名稱
  -max FILL_IN_PVT_CORNER_23_7 \
# 請填入 library 的 PVT corner 名稱
  -min FILL_IN_PVT_CORNER_24_7


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
# IO delay
#============================================================

# 請填入此 I/O timing delay 值，單位依 SDC 設定
set input_max_axi_clk {FILL_IN_TIMING_VALUE_input_max_axi_clk}
# 請填入此 I/O timing delay 值，單位依 SDC 設定
set input_min_axi_clk {FILL_IN_TIMING_VALUE_input_min_axi_clk}
# 請填入此 I/O timing delay 值，單位依 SDC 設定
set output_max_axi_clk {FILL_IN_TIMING_VALUE_output_max_axi_clk}
# 請填入此 I/O timing delay 值，單位依 SDC 設定
set output_min_axi_clk {FILL_IN_TIMING_VALUE_output_min_axi_clk}

set_input_delay  -max $input_max_axi_clk  -clock axi_clk \
  [remove_from_collection [all_inputs] [get_ports {axi_clk rom_clk dram_clk}]]

set_input_delay  -min $input_min_axi_clk  -clock axi_clk \
  [remove_from_collection [all_inputs] [get_ports {axi_clk rom_clk dram_clk}]]

set_output_delay -max $output_max_axi_clk -clock axi_clk [all_outputs]
set_output_delay -min $output_min_axi_clk -clock axi_clk [all_outputs]


# 請填入此 I/O timing delay 值，單位依 SDC 設定
set input_max_rom_clk {FILL_IN_TIMING_VALUE_input_max_rom_clk}
# 請填入此 I/O timing delay 值，單位依 SDC 設定
set input_min_rom_clk {FILL_IN_TIMING_VALUE_input_min_rom_clk}
# 請填入此 I/O timing delay 值，單位依 SDC 設定
set output_max_rom_clk {FILL_IN_TIMING_VALUE_output_max_rom_clk}
# 請填入此 I/O timing delay 值，單位依 SDC 設定
set output_min_rom_clk {FILL_IN_TIMING_VALUE_output_min_rom_clk}

set_input_delay  -max $input_max_rom_clk  -clock rom_clk \
  [remove_from_collection [all_inputs] [get_ports {axi_clk rom_clk dram_clk}]]

set_input_delay  -min $input_min_rom_clk  -clock rom_clk \
  [remove_from_collection [all_inputs] [get_ports {axi_clk rom_clk dram_clk}]]

set_output_delay -max $output_max_rom_clk -clock rom_clk [all_outputs]
set_output_delay -min $output_min_rom_clk -clock rom_clk [all_outputs]


# 請填入此 I/O timing delay 值，單位依 SDC 設定
set input_max_dram_clk {FILL_IN_TIMING_VALUE_input_max_dram_clk}
# 請填入此 I/O timing delay 值，單位依 SDC 設定
set input_min_dram_clk {FILL_IN_TIMING_VALUE_input_min_dram_clk}
# 請填入此 I/O timing delay 值，單位依 SDC 設定
set output_max_dram_clk {FILL_IN_TIMING_VALUE_output_max_dram_clk}
# 請填入此 I/O timing delay 值，單位依 SDC 設定
set output_min_dram_clk {FILL_IN_TIMING_VALUE_output_min_dram_clk}

set_input_delay  -max $input_max_dram_clk  -clock dram_clk \
  [remove_from_collection [all_inputs] [get_ports {axi_clk rom_clk dram_clk}]]

set_input_delay  -min $input_min_dram_clk  -clock dram_clk \
  [remove_from_collection [all_inputs] [get_ports {axi_clk rom_clk dram_clk}]]

set_output_delay -max $output_max_dram_clk -clock dram_clk [all_outputs]
set_output_delay -min $output_min_dram_clk -clock dram_clk [all_outputs]


# 請填入本地時序／負載限制值
set_load {FILL_IN_set_load_153} [all_outputs]

set auto_wire_load_selection
