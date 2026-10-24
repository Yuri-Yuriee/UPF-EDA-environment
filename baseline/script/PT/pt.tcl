# set company "CIC"
# set designer "Student"

# set CoreSearchPath /FILL_IN/FILL_IN_RESOURCE_0055
# set IOSearchPath /FILL_IN/FILL_IN_RESOURCE_0056
# set MemoryPath ../tech/memory/sim/SRAM
# set DefintionPath ../include

# #set search_path    "$CoreSearchPath $IOSearchPath $MemoryPath $DefintionPath $search_path"

# set target_library " FILL_IN_LIBRARY_0057 FILL_IN_LIBRARY_0058 FILL_IN_LIBRARY_0059 FILL_IN_LIBRARY_0060 SRAM_ss0p72v0p72vm40c_100a.db SRAM_ff0p88v0p88v125c_100a.db"

# #set link_library      "* $target_library "

#####################################################
# Set the Power Analysis Mode
#####################################################
set power_enable_analysis TRUE
set power_analysis_mode averaged
#set power_analysis_mode time_based
 
#####################################################
# Reading the Technology Library and Design Data (Gate-level netlist)
#####################################################
# set search_path    "$CoreSearchPath $IOSearchPath $MemoryPath $DefintionPath $search_path"
# set link_library   "* $target_library "
read_verilog ../syn/CHIP_syn.v
current_design CHIP
link_design

#####################################################
# Specifying Operating Conditions and Variables (Read SDC)
#####################################################
source ./ptpx.sdc

#####################################################
# check, update, or report the timing (optional)
#####################################################
check_timing
report_timing > ../timing.rpt
update_timing

#####################################################
# Specifying Switching Activity Data
#####################################################
read_fsdb ../build/chip.fsdb -strip_path top_tb/

#read_sdf -load_delay net ../syn/CHIP_syn.sdf
set_input_transition 0.1 [all_inputs]

set_host_options -max_core 16
#####################################################
# check or update or report power
#####################################################
check_power
#set_power_analysis_options -waveform_format fsdb -waveform_output ptpx
update_power
#report_power
#get_design
 #report_power -hierarchy 
 report_power -sort_by total_power -cell_power -leaf > ../tota_plower.rpt
 report_power -verbose > ../verbose_power.rpt
 report_power -verbose -hierarchy > ../hie_power.rpt

