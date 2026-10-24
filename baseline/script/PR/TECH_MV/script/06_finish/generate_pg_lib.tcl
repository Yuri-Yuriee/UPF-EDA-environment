if {![info exists ::TECH_MV_RUNTIME_ROOT]} {
    set ::TECH_MV_RUNTIME_ROOT [file normalize [pwd]]
}
# Runtime adapter preserves the historical logical source path.
if {[info exists ::TECH_MV_RUNTIME_ROOT]} {
    info script [file join $::TECH_MV_RUNTIME_ROOT run/generate_pg_lib.tcl]
}
# voltus -batch -file script/06_finish/generate_pg_lib.tcl
# Always reload the complete TECH_MV user setup for every run invocation.
# init.setup reloads the categorized setup/config/*.config.tcl files.
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

read_lib -lef {*}$LEF_FILES
set_pg_library_mode -celltype techonly \
                    -power_pins [::tech_mv_library_value PG_LIBRARY_POWER_PIN_VALUES] \
                    -ground_pins [::tech_mv_library_value PG_LIBRARY_GROUND_PINS] \
                    -extraction_tech_file $PG_LIBRARY_QRC_FILE \
                    -temperature -40
generate_pg_library
