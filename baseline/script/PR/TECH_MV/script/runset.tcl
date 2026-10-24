if {![info exists ::TECH_MV_RUNTIME_ROOT]} {
    set ::TECH_MV_RUNTIME_ROOT [file normalize [pwd]]
}
# Runtime adapter preserves the historical logical source path.
if {[info exists ::TECH_MV_RUNTIME_ROOT]} {
    info script [file join $::TECH_MV_RUNTIME_ROOT run/runset.tcl]
}

# =============================================================================
# TECH MV Full Innovus Flow
# =============================================================================

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

# 2nd-PG routing mode is configured in setup/config/05_route.config.tcl.
source -quiet [file join $SCRIPT_DIR prepare_run_dirs.tcl]

source -quiet [file join $RUN_DIR 00_import_design.tcl]
source -quiet [file join $RUN_DIR 01_floorplan.tcl]
source -quiet [file join $RUN_DIR 02_powerplan.tcl]
source -quiet [file join $RUN_DIR 03_place.tcl]
source -quiet [file join $RUN_DIR 04_cts.tcl]
source -quiet [file join $RUN_DIR 05_route.tcl]
source -quiet [file join $RUN_DIR 06_finish.tcl]
