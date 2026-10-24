# Runtime adapter preserves the historical logical source path.
if {[info exists ::TECH_MV_RUNTIME_ROOT]} {
    info script [file join $::TECH_MV_RUNTIME_ROOT run/02_powerplan.tcl]
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
set ::TECH_MV_REPORT_STAGE 02
source -quiet [file join $SCRIPT_DIR prepare_run_dirs.tcl]
source -quiet [file join $SCRIPT_DIR terminal_report_footer.tcl]
source -quiet [file join $SCRIPT_DIR pd_geometry_trace.tcl]
tech_mv_pd_trace_reset 02
tech_mv_pd_trace "stage_entry" "source run/02_powerplan.tcl"
source -quiet [file join $SCRIPT_DIR powerplan_step_pause.tcl]
source -quiet [file join $SCRIPT_DIR powerplan_precheck.tcl]
source -quiet [file join $SCRIPT_DIR powerplan_stage_tail.tcl]
source -quiet [file join $SCRIPT_DIR checkpoint_guard.tcl]

# Verify the manually captured PD geometry/grid and EndCaps before any PG work.
tech_mv_stage_start_guard 02_powerplan
tech_mv_pd_trace "after_stage_start_guard" "tech_mv_stage_start_guard 02_powerplan"

# Validate required setup variables and PG-net presence before any power planning.
# This is a dependency guard, not an optional physical check, so it is never
# bypassed by CHECK_ALL_ENABLE.
tech_mv_powerplan_precheck
tech_mv_pd_trace "after_powerplan_precheck" "tech_mv_powerplan_precheck"

# Re-apply the latest global-net mapping every time Stage 02 starts.
source -quiet $GLOBAL_NET_FILE
tech_mv_pd_trace "after_global_net_mapping" "source $GLOBAL_NET_FILE"

powerplan_step_reset
powerplan_step_pause stage_02_input_database     "02_powerplan input database before any PG operation."

# The normal flow keeps this disabled because 01_floorplan has already inserted
# EndCap and WellTap cells.  Strict cleanup treats every non-pad core instance
# alike and would unplace those physical cells as well.
if {$CLEAR_STD_CELLS_BEFORE_POWERPLAN} {
    puts "WARNING: CLEAR_STD_CELLS_BEFORE_POWERPLAN is enabled."
    puts "WARNING: This strict cleanup also unplaces existing EndCap/WellTap cells."
    source -quiet [file join $SCRIPT_DIR unplace_standard_cells.tcl]
    unplace_standard_cells "before 02_powerplan" 5
    error "Boundary cells must be reinserted after strict cleanup. Restart from 01_floorplan or disable CLEAR_STD_CELLS_BEFORE_POWERPLAN."
}

# Re-check immediately before power planning. No hard macro is fixed by this check.
if {$::CHECK_ALL_ENABLE && $::CHECK_STAGE02_HARDMACRO_PD_ENABLE} {
    set ::TECH_MV_REPORT_STEP 8
    source -quiet [file join $SCRIPT_DIR check_hardmacro_power_domain.tcl]
    unset ::TECH_MV_REPORT_STEP
    tech_mv_pd_trace "after_hardmacro_pd_check" "source check_hardmacro_power_domain.tcl"
} else {
    puts "INFO: CHECK SKIPPED: Stage02 hard-macro / Power-Domain check (config disabled)."
    tech_mv_pd_trace "after_hardmacro_pd_check_skipped" "Hard-macro / Power-Domain check disabled by config"
}

set powerplan_mode [string tolower $POWERPLAN_MODE]
puts "INFO: POWERPLAN_MODE = $powerplan_mode"
switch -- $powerplan_mode {
    legacy {
        tech_mv_pd_trace "before_legacy_powerplan" "source script/powerplan.tcl"
        source -quiet [file join $SCRIPT_DIR powerplan.tcl]
        tech_mv_pd_trace "after_legacy_powerplan" "source script/powerplan.tcl"
        # EndCap/WellTap cells already exist in the 01_floorplan database.
    }
    pns {
        source -quiet [file join $SCRIPT_DIR 02_powerplan pns.tcl]
        if {!$PNS_AUTO_RUN_ON_SOURCE} { runPGPlan }
        powerplan_step_pause pns_powerplan_complete             "Completed runPGPlan in PNS mode."
    }
    none {
        puts "INFO: skip power planning"
    }
    default { error "Unsupported POWERPLAN_MODE '$POWERPLAN_MODE'" }
}

# Complete the Stage 02 operations that must happen after the base mesh.
# The same helper is also called by TT_proc_powerplan_resume.tcl, so checkpoint
# restore and normal execution now finish the exact same Stage 02 flow.
tech_mv_pd_trace "before_powerplan_stage_tail" "tech_mv_powerplan_stage_tail"
tech_mv_powerplan_stage_tail
tech_mv_pd_trace "after_powerplan_stage_tail" "tech_mv_powerplan_stage_tail"

# Detect any PD/grid drift caused during PowerPlan and stop on EndCap problems.
tech_mv_pd_trace "before_stage_end_guard" "tech_mv_stage_end_guard 02_powerplan 03_place"
tech_mv_stage_end_guard 02_powerplan 03_place

# Final Stage-02 exit restore point.  This database is written only after the
# formal stage-end guard has completed/been accepted.
set _pp_stage02_exit_db [file join $DB_DIR 02_100_stage02_exit.enc]
write_db $_pp_stage02_exit_db
puts "INFO: PowerPlan final exit restore DB = $_pp_stage02_exit_db"
puts "INFO: Quick restore: pp_restore stage02_exit"
unset _pp_stage02_exit_db

# Keep important reports visible at the bottom of the terminal.
tech_mv_terminal_report_footer 02
# RESUME_POINT_RUN02: stage02_exit
