# Runtime adapter preserves the historical logical source path.
if {[info exists ::TECH_MV_RUNTIME_ROOT]} {
    info script [file join $::TECH_MV_RUNTIME_ROOT run/tool/02_powerplan/reports/TT_early_rail_analysis.tcl]
}
# Always reload the complete TECH_MV user setup for every run invocation.
# init.setup reloads the categorized setup/config/*.config.tcl files.
# Always reload the complete TECH_MV runtime/configuration for this run entry.
# Resolve build_PR/init.setup from this file; do not depend on script_search_path.
set _tech_run_file [file normalize [info script]]
set _tech_init_setup [file join $::TECH_MV_RUNTIME_ROOT init.setup]
if {![file isfile $_tech_init_setup]} {
    error "TECH_MV runtime init.setup not found: $_tech_init_setup"
}
source $_tech_init_setup
unset _tech_run_file
unset _tech_init_setup
set ::TECH_MV_REPORT_STAGE 91
source -quiet [file join $SCRIPT_DIR prepare_run_dirs.tcl]
set_rail_analysis_config {*}$ERA_ARGS_01
write_power_pads {*}$ERA_ARGS_02
write_power_pads {*}$ERA_ARGS_03
write_power_pads {*}$ERA_ARGS_04
write_power_pads {*}$ERA_ARGS_05
set_pg_nets {*}$ERA_ARGS_06
set_pg_nets {*}$ERA_ARGS_07
set_rail_analysis_domain {*}$ERA_ARGS_08
set_power_data -reset
set_power_data {*}$ERA_ARGS_09
set_power_pads -reset
set_power_pads {*}$ERA_ARGS_10
set_power_pads {*}$ERA_ARGS_11
set_package -reset
set_package {*}$ERA_ARGS_12
set_net_group -reset
set_advanced_rail_options -reset
set_db {*}$ERA_ARGS_13
set RAIL_REPORT_DIR [file join [tech_mv_report_dir 91] 91_10_early_rail]
file mkdir $RAIL_REPORT_DIR
report_rail -type domain -results_directory $RAIL_REPORT_DIR $ERA_REPORT_DOMAIN
