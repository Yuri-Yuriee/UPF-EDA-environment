#####CLK PERIOD CAN BE ADJUSTED UP TO [請填入本地值] IF SYNTHESIS GOES WRONG#####
# 請填入此時脈週期，單位依 SDC／工具設定
set cpu_clk_period {FILL_IN_cpu_clk_period}
# 請填入此時脈週期，單位依 SDC／工具設定
set axi_clk_period {FILL_IN_axi_clk_period}
# 請填入此時脈週期，單位依 SDC／工具設定
set rom_clk_period {FILL_IN_rom_clk_period}
# 請填入此時脈週期，單位依 SDC／工具設定
set dram_clk_period {FILL_IN_dram_clk_period}

#create_clock -name cpu_clk  -period $cpu_clk_period  [get_ports cpu_clk]
create_clock -name axi_clk  -period $axi_clk_period  [get_ports axi_clk]
create_clock -name rom_clk  -period $rom_clk_period  [get_ports rom_clk]
create_clock -name dram_clk -period $dram_clk_period  [get_ports dram_clk]
set_clock_groups -asynchronous -group {axi_clk} -group {rom_clk} -group {dram_clk}
#-group {cpu_clk}

#set_ideal_network           [get_pins ipad_cpu_rst/C]
# set_ideal_network           [get_pins ipad_axi_rst/C]
# set_ideal_network           [get_pins ipad_rom_rst/C]
# set_ideal_network           [get_pins ipad_dram_rst/C]

set_dont_touch_network      [all_clocks]
# 請填入本地時序／負載限制值
set_clock_uncertainty  {FILL_IN_set_clock_uncertainty_20}  [all_clocks]
# 請填入本地時序／負載限制值
set_clock_latency      {FILL_IN_set_clock_latency_21}  [all_clocks]
# 請填入本地時序／負載限制值
set_input_transition   {FILL_IN_set_input_transition_22}  [all_inputs]
# 請填入本地時序／負載限制值
set_clock_transition   {FILL_IN_set_clock_transition_23}  [all_clocks]
set_ideal_network           [get_ports *clk]

set_operating_conditions \
# 請填入 library 的 PVT corner 名稱
        -max FILL_IN_PVT_CORNER_27_13 \
# 請填入 library 的 PVT corner 名稱
        -min FILL_IN_PVT_CORNER_28_13 

# cpu_clk
#set input_max_cpu_clk   [expr {double(round(1000*$cpu_clk_period * [請填入本地值]))/1000}]
#set input_min_cpu_clk   [expr {double(round(1000*$cpu_clk_period * [請填入本地值]))/1000}]
#set output_max_cpu_clk  [expr {double(round(1000*$cpu_clk_period * [請填入本地值]))/1000}]
#set output_min_cpu_clk  [expr {double(round(1000*$cpu_clk_period * [請填入本地值]))/1000}]

#set_input_delay  -max $input_max_cpu_clk  -clock cpu_clk [remove_from_collection [all_inputs] [get_ports {cpu_clk cpu_rst}]]
#set_input_delay  -min $input_min_cpu_clk  -clock cpu_clk [remove_from_collection [all_inputs] [get_ports {cpu_clk cpu_rst}]]
#set_output_delay -max $output_max_cpu_clk -clock cpu_clk [all_outputs]
#set_output_delay -min $output_min_cpu_clk -clock cpu_clk [all_outputs]

# axi_clk
# 請填入此 I/O timing delay 值，單位依 SDC 設定
set input_max_axi_clk {FILL_IN_TIMING_VALUE_input_max_axi_clk}
# 請填入此 I/O timing delay 值，單位依 SDC 設定
set input_min_axi_clk {FILL_IN_TIMING_VALUE_input_min_axi_clk}
# 請填入此 I/O timing delay 值，單位依 SDC 設定
set output_max_axi_clk {FILL_IN_TIMING_VALUE_output_max_axi_clk}
# 請填入此 I/O timing delay 值，單位依 SDC 設定
set output_min_axi_clk {FILL_IN_TIMING_VALUE_output_min_axi_clk}

set_input_delay  -max $input_max_axi_clk  -clock axi_clk [remove_from_collection [all_inputs] [get_ports {axi_clk axi_clk}]]
set_input_delay  -min $input_min_axi_clk  -clock axi_clk [remove_from_collection [all_inputs] [get_ports {axi_clk axi_clk}]]
set_output_delay -max $output_max_axi_clk -clock axi_clk [all_outputs]
set_output_delay -min $output_min_axi_clk -clock axi_clk [all_outputs]

# rom_clk
# 請填入此 I/O timing delay 值，單位依 SDC 設定
set input_max_rom_clk {FILL_IN_TIMING_VALUE_input_max_rom_clk}
# 請填入此 I/O timing delay 值，單位依 SDC 設定
set input_min_rom_clk {FILL_IN_TIMING_VALUE_input_min_rom_clk}
# 請填入此 I/O timing delay 值，單位依 SDC 設定
set output_max_rom_clk {FILL_IN_TIMING_VALUE_output_max_rom_clk}
# 請填入此 I/O timing delay 值，單位依 SDC 設定
set output_min_rom_clk {FILL_IN_TIMING_VALUE_output_min_rom_clk}

set_input_delay  -max $input_max_rom_clk  -clock rom_clk [remove_from_collection [all_inputs] [get_ports {rom_clk rom_clk}]]
set_input_delay  -min $input_min_rom_clk  -clock rom_clk [remove_from_collection [all_inputs] [get_ports {rom_clk rom_clk}]]
set_output_delay -max $output_max_rom_clk -clock rom_clk [all_outputs]
set_output_delay -min $output_min_rom_clk -clock rom_clk [all_outputs]

# dram_clk
# 請填入此 I/O timing delay 值，單位依 SDC 設定
set input_max_dram_clk {FILL_IN_TIMING_VALUE_input_max_dram_clk}
# 請填入此 I/O timing delay 值，單位依 SDC 設定
set input_min_dram_clk {FILL_IN_TIMING_VALUE_input_min_dram_clk}
# 請填入此 I/O timing delay 值，單位依 SDC 設定
set output_max_dram_clk {FILL_IN_TIMING_VALUE_output_max_dram_clk}
# 請填入此 I/O timing delay 值，單位依 SDC 設定
set output_min_dram_clk {FILL_IN_TIMING_VALUE_output_min_dram_clk}

set_input_delay  -max $input_max_dram_clk  -clock dram_clk [remove_from_collection [all_inputs] [get_ports {dram_clk dram_clk}]]
set_input_delay  -min $input_min_dram_clk  -clock dram_clk [remove_from_collection [all_inputs] [get_ports {dram_clk dram_clk}]]
set_output_delay -max $output_max_dram_clk -clock dram_clk [all_outputs]
set_output_delay -min $output_min_dram_clk -clock dram_clk [all_outputs]







# 請填入本地時序／負載限制值
set_load {FILL_IN_set_load_80} [all_outputs]

set auto_wire_load_selection
#set_timing_derate -max -late -net_delay [請填入本地值]


