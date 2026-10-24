# Runtime adapter preserves the historical logical source path.
if {[info exists ::TECH_MV_RUNTIME_ROOT]} {
    info script [file join $::TECH_MV_RUNTIME_ROOT run/01_floorplan.tcl]
}
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
set ::TECH_MV_REPORT_STAGE 01
source -quiet [file join $SCRIPT_DIR prepare_run_dirs.tcl]
source -quiet [file join $SCRIPT_DIR terminal_report_footer.tcl]


# floorplan.tcl performs the complete Stage-01 physical-floorplan flow.
# Power-switch insertion is intentionally triggered from the boundary-cell
# portion of that flow AFTER EndCap insertion and BEFORE WellTap insertion.
source -quiet [file join $SCRIPT_DIR floorplan.tcl]

# Optional manual PD snap/acceptance checkpoint.
source -quiet [file join $SCRIPT_DIR checkpoint_guard.tcl]
if {$ENABLE_MANUAL_PD_SNAP_BREAKPOINT} {
    tech_mv_manual_pd_snap_breakpoint
} else {
    puts "INFO: Final duplicate PD pause disabled; recording completed geometry."
        if {[llength [info commands tech_mv_pd_lock_capture]]} { tech_mv_pd_lock_capture floorplan_completed }
        if {[llength [info commands TT_track_pd_endcaps]]} { TT_track_pd_endcaps floorplan_completed }
}

tech_mv_terminal_report_footer 01
