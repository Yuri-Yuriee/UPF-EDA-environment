# Runtime adapter preserves the historical logical source path.
if {[info exists ::TECH_MV_RUNTIME_ROOT]} {
    info script [file join $::TECH_MV_RUNTIME_ROOT run/04_cts.tcl]
}
# Always reload the complete TECH_MV user setup for every CTS invocation.
# Always reload the complete TECH_MV runtime/configuration for this run entry.
# Resolve build_PR/init.setup from this file; do not depend on script_search_path.
set _tech_run_file [file normalize [info script]]
set _tech_init_setup [file normalize [file join [file dirname $_tech_run_file] .. init.setup]]
if {![file isfile $_tech_init_setup]} {
    error "TECH_MV runtime init.setup not found: $_tech_init_setup"
}
source $_tech_init_setup
unset _tech_run_file
unset _tech_init_setup
set ::TECH_MV_REPORT_STAGE 04
source -quiet [file join $SCRIPT_DIR prepare_run_dirs.tcl]
source -quiet [file join $SCRIPT_DIR terminal_report_footer.tcl]
source -quiet [file join $SCRIPT_DIR place_checkpoint.tcl]
source -quiet [file join $SCRIPT_DIR checkpoint_guard.tcl]

tech_mv_stage_start_guard 04_cts

# Re-apply user CTS transition targets after every setup reload.
foreach var {
    CTS_TOP_MAX_TRANSITION
    CTS_TRUNK_MAX_TRANSITION
    CTS_LEAF_MAX_TRANSITION
} {
    if {![info exists $var]} {
        error "Required CTS setup variable '$var' is not defined in setup/config.tcl"
    }
}

set_db cts_target_max_transition_time_top   $CTS_TOP_MAX_TRANSITION
set_db cts_target_max_transition_time_trunk $CTS_TRUNK_MAX_TRANSITION
set_db cts_target_max_transition_time_leaf  $CTS_LEAF_MAX_TRANSITION

puts "INFO: CTS max transition targets:"
puts "INFO:   top   = [get_db cts_target_max_transition_time_top]"
puts "INFO:   trunk = [get_db cts_target_max_transition_time_trunk]"
puts "INFO:   leaf  = [get_db cts_target_max_transition_time_leaf]"

check_cts_config

tech_mv_place_checkpoint "04_before_cts" ""
write_db [file join $DB_DIR 04_10_pre_cts.enc]
set_interactive_constraint_modes {CM_func}
reset_clock_latency [all_clocks]

switch -- [string tolower $CTS_MODE] {
    ccopt     { ccopt_design -report_dir [tech_mv_report_dir 04 timing] }
    clock_opt { clock_opt_design }
    default   { error "Unsupported CTS_MODE '$CTS_MODE'" }
}
if {$ENABLE_POST_CTS_OPT} {
    opt_design -post_cts -report_dir [tech_mv_report_dir 04 timing]
    opt_design -post_cts -hold -report_dir [tech_mv_report_dir 04 timing]
    opt_design -post_cts -hold -setup -report_dir [tech_mv_report_dir 04 timing]
}

tech_mv_place_checkpoint "04_after_cts_before_tieoffs" "04_20_after_cts_before_tieoffs.enc"

if {[get_db add_tieoffs_cells] ne ""} {
    delete_tieoffs
    add_tieoffs -matching_power_domains true
}
tech_mv_place_checkpoint "04_after_cts_final" ""
write_db [file join $DB_DIR 04_99_cts.enc]

tech_mv_stage_end_guard 04_cts 05_route

tech_mv_terminal_report_footer 04
