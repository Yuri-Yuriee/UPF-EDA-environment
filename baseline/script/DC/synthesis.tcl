#read_file -autoread -top CHIP {../src ../include ../src/AXI}
# analyze -format sverilog {../src/CHIP.v ../src/top.sv}
set define_macros "SYNTHESIS"
analyze -format sverilog -define $define_macros -vcs "-f ../src/src_clean_baseline/file_list/syn.f"
elaborate CHIP
current_design CHIP
link
uniquify
set_fix_multiple_port_nets -all -buffer_constants [get_designs *]

set hdlin_infer_mux true
set hdlin_infer_dff true
set hdlin_ff_always_sync_set_reset true
set hdlin_ff_always_async_set_reset true
set_host_options -max_core 16
if {$MV_option == 1} {
    set UPF_option 1
} else {
    set UPF_option 0
}


# ============================================================
# Preserve TD local delay chain
# ============================================================

set delay_chain_cells [get_cells -hier \
    {u_TOP/u_pmu/gen_td_local\[0\]/u_td_local/u_delay/GEN_DELAY_CHAIN\[*\]/u_delay_cell/u_delay}]

if {[sizeof_collection $delay_chain_cells] == 0} {
    echo "WARNING: Cannot find TD delay chain cells."
    echo "Try debug with:"
    echo "  get_cells -hier *u_delay*"
    echo "  get_cells -hier *GEN_DELAY_CHAIN*"
} else {
    echo "INFO: Found TD delay chain cells:"
    foreach_in_collection c $delay_chain_cells {
        echo "  [get_object_name $c]"
    }

    # 保護整條 delay chain cell，不讓 DC 移除、替換、合併
    set_dont_touch $delay_chain_cells true

    # 保護 delay cell 之間的 net，避免中間線被最佳化掉
    set delay_chain_nets [get_nets -of_objects [get_pins -of_objects $delay_chain_cells]]
    set_dont_touch $delay_chain_nets true
}


if {$UPF_option == 1} {
    set_dont_touch [get_pins u_TOP/u_cpu/u_WFI/*CPU*]
    set_dont_touch [get_pins "u_TOP/u_cpu/MEIP u_TOP/u_cpu/MTIP u_TOP/u_cpu/u_cpu/u_exe/u_CSR/CSR_mip* u_TOP/u_cpu/u_cpu/interrupt*"]
    set_dont_touch [get_nets "u_TOP/u_cpu/u_cpu/MEIP u_TOP/u_cpu/u_cpu/MTIP u_TOP/u_cpu/u_cpu/u_exe/u_CSR/CSR_mip* u_TOP/u_cpu/u_cpu/u_exe/interrupt* u_TOP/u_cpu/u_cpu/u_exe/u_CSR/interrupt* u_TOP/u_cpu/u_cpu/MEIP u_TOP/u_cpu/u_cpu/CSR_mip*"]
    set_dont_touch_network [get_nets "u_TOP/u_cpu/u_cpu/MEIP u_TOP/u_cpu/u_cpu/MTIP u_TOP/u_cpu/u_cpu/u_exe/u_CSR/CSR_mip* u_TOP/u_cpu/u_cpu/u_exe/interrupt u_TOP/u_cpu/u_cpu/u_exe/u_CSR/interrupt"] 
    set_ideal_network [get_nets "u_TOP/u_cpu/u_WFI/*CPU* u_TOP/u_cpu/u_cpu/interrupt u_TOP/u_cpu/u_cpu/MEIP u_TOP/u_cpu/u_cpu/MTIP"] -no_propagate
    set upf_allow_refer_before_define true
    load_upf ../script/MV/UPF/MSV.upf
    source ../script/MV/SDC/DC.sdc
    check_mv_design -verbose > ../syn/pre_check_mv.log
    report_power_domain -verbose > ../syn/power_domain.log
    propagate_constraints -all
    fix_hold "cpu_clk axi_clk rom_clk dram_clk"
    
    compile_ultra -no_autoungroup -gate_clock -no_boundary_optimization
    check_mv_design -verbose > ../syn/post_check_mv.log
    set mv_align_library_pg_pins true
    #optimize_registers
    #insert_level_shifter
    #analyze_mv_feasibility
    #insert_mv_cells -verbose
} else {
    #read_sdc ../script/DC/DC.sdc
    source ../script/DC/DC.sdc
    fix_hold "cpu_clk axi_clk rom_clk dram_clk"
    if {$topo_option == 1} {
        source ../script/MW.tcl
        set_fix_multiple_port_nets -all
        compile_ultra -no_autoungroup
        # optimize_registers            # optimize_registers have some problem in gate-sim

    } else {
        compile -exact_map -map_effort high
        optimize_registers   
    }
}

remove_unconnected_ports -blast_buses [get_cells * -hier]


set_max_area    0
#set_max_fanout       10 [all_inputs]
set_max_transition  0.1 [all_inputs]
#set_max_capacitance 0.1 [all_inputs]
set_fix_hold                [all_clocks]

# set bus_inference_style {%s[%d]}
# set bus_naming_style {%s[%d]}
# set hdlout_internal_busses true

# change_names -hierarchy -rule verilog

####Naming Rule#######
set bus_inference_style {%s[%d]}
set bus_naming_style {%s[%d]}
set hdlout_internal_busses true
change_names -hierarchy -rule verilog
define_name_rules name_rule -allowed "A-Z a-z 0-9 _" -max_length 255 -type cell
define_name_rules name_rule -allowed "A-Z a-z 0-9 _[]" -max_length 255 -type net
define_name_rules name_rule -map {{"\\*cell\\*" "cell"}}
define_name_rules name_rule -case_insensitive
change_names -hierarchy -rules name_rule




write_file -format verilog -hier -output ../syn/CHIP_syn.v
write_sdf -version 2.1 -context verilog -load_delay net ../syn/CHIP_syn.sdf
write_sdc -full_path_lib_names -version 2.1 ../syn/DC_out.sdc

write_file -pg -format verilog -hier -output ../syn/CHIP_syn_pg.v 

if {$UPF_option == 1} {
    save_upf ../syn/DC_out.upf
}
report_timing > ../syn/timing.log
report_area > ../syn/area.log
report_power > ../syn/power.log

report_timing -path full -delay max -nworst 1 -max_paths 1 -significant_digits 2 -sort_by group > ../syn/timing_max_rpt.txt
report_timing -path full -delay min -nworst 1 -max_paths 1 -significant_digits 2 -sort_by group > ../syn/timing_min_rpt.txt


report_timing -group cpu_clk -pba_mode exhaustive -delay_type max -path_type full -max_paths 10 -nworst 10 -input_pins -nets -capacitance -transition_time -slack_lesser_than 5.0000 -significant_digits 6 > ../log/path.rpt
# #exit


# #   Read in top module
# #read_file -autoread -top CHIP {../src/ ../include}
# set define_macros "SYNTHESIS"
# analyze -format sverilog -define $define_macros -vcs "-f ../src/src_clean_baseline/file_list/syn.f"
# elaborate CHIP

# # SET POWER INTENT and ENVIRONMENT ###################################
# current_design CHIP
# link

# #   Set Design Environment
# set_host_options -max_core 8
# source ../script/DC/DC.sdc
# report_clock -groups >> ../log/clk_g.log
# check_design
# uniquify
# set_fix_multiple_port_nets -all -buffer_constants [get_designs *]
# set_max_area 0


# #   Synthesize circuit
# compile -map_effort high -area_effort high
# #compile -map_effort high -area_effort high -inc


# ####Naming Rule#######
# set bus_inference_style {%s[%d]}
# set bus_naming_style {%s[%d]}
# set hdlout_internal_busses true
# change_names -hierarchy -rule verilog
# define_name_rules name_rule -allowed "A-Z a-z 0-9 _" -max_length 255 -type cell
# define_name_rules name_rule -allowed "A-Z a-z 0-9 _[]" -max_length 255 -type net
# define_name_rules name_rule -map {{"\\*cell\\*" "cell"}}
# define_name_rules name_rule -case_insensitive
# change_names -hierarchy -rules name_rule

# #   Create Report
# #timing report(setup time)
# report_timing -path full -delay max -nworst 1 -max_paths 1 -significant_digits 4 -sort_by group > ../syn/timing_max_rpt.txt
# #timing report(hold time)
# report_timing -path full -delay min -nworst 1 -max_paths 1 -significant_digits 4 -sort_by group > ../syn/timing_min_rpt.txt
# #area report
# report_area -nosplit > ../syn/area_rpt.txt
# #report power
# report_power -analysis_effort low > ../syn/power_rpt.txt

# #   Save syntheized file
# write -hierarchy -format verilog -output {../syn/CHIP_syn.v}
# #write_sdf -version 1.0 -context verilog {../syn/top_syn.sdf}
# write_sdf -version 3.0 -context verilog {../syn/CHIP_syn.sdf}

