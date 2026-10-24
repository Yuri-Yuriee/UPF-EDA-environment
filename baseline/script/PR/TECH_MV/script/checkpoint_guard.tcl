# =============================================================================
# checkpoint_guard.tcl
# =============================================================================
# Checkpoint policy for placement / floorplan / EndCap inspection.
#
# Core rule:
#   - A formal checkpoint runs check_place + check_floorplan exactly ONCE.
#   - If the checkpoint suspends, native Innovus "resume" means the user has
#     accepted the current state.  The SAME checkpoint is NOT re-checked.
#   - Stage-start guards never repeat the previous stage-end formal check.
#   - Debug DB/snapshot helpers do not run formal checkers.
#   - Marker-driven repair tools may run one local check_place when markers are
#     required and are not already available.
# =============================================================================

# Load the read-only helpers this policy owns.
if {[info exists ::SCRIPT_DIR] && [info exists ::TOOL_DIR]} {
    foreach _script_file {
        track_pd_endcaps.tcl
        pd_geometry_lock.tcl
    } {
        set _script_path [file join $::SCRIPT_DIR $_script_file]
        if {[file exists $_script_path]} {
            source -quiet $_script_path
        }
    }

    set _check_file [file join $::TECH_MV_RUNTIME_ROOT .. script PR TECH_MV script 01_floorplan checks proc_check_pd_endcaps.tcl]
    if {[file exists $_check_file]} {
        source -quiet $_check_file
    }

    unset -nocomplain _script_file _script_path _check_file
}


# Print a compact formal-checkpoint summary.
proc tt_checkpoint_print_summary {stage check_result pd_result} {
    puts ""
    puts "======================================================================"
    puts " CHECKPOINT : $stage"
    puts "======================================================================"
    puts "Placement/EndCap : [expr {[dict get $check_result ok] ? {PASS} : {FAIL}}]"
    puts "Pre-route DRC    : [dict get $check_result pre_route_drc_violation]"
    if {[dict get $check_result pre_route_drc_violation] > 0} {
        puts "WARNING: Pre-route DRC is advisory and does not fail this checkpoint."
    }
    puts "Pin Access       : [dict get $check_result pin_access_violation]"
    puts "Floorplan errors : [dict get $check_result fatal_floorplan_error_count]"
    puts "EndCap problems  : [dict get $check_result endcap_problem_count]"
    puts "PD geometry lock : [expr {[dict get $pd_result ok] ? {PASS} : {FAIL}}]"
    puts "Check report     : [dict get $check_result report]"
    puts "Floorplan report : [dict get $check_result raw_report]"
    puts "PD lock report   : [dict get $pd_result report]"
    puts "======================================================================"
}

# Formal checkpoint.
#
# always_suspend=false:
#   suspend only when placement/floorplan/EndCap or PD-lock result is not clean.
#
# always_suspend=true:
#   always suspend once for manual inspection, even if the checker is clean.
#
# IMPORTANT: after native "resume", this function RETURNS immediately.  It does
# not execute check_place/check_floorplan again.  Resume itself is acceptance.
proc tech_mv_checkpoint {stage {always_suspend false}} {
    if {[llength [info commands TT_proc_check_pd_endcaps]] == 0} {
        error "tech_mv_checkpoint: TT_proc_check_pd_endcaps is unavailable."
    }
    if {[llength [info commands tech_mv_pd_lock_check]] == 0} {
        error "tech_mv_checkpoint: tech_mv_pd_lock_check is unavailable."
    }

    if {[llength [info commands TT_track_pd_endcaps]] > 0} {
        TT_track_pd_endcaps $stage
    }

    # Exactly one formal check_place + one formal check_floorplan here.
    set check_result [TT_proc_check_pd_endcaps $stage]
    set pd_result    [tech_mv_pd_lock_check $stage]

    tt_checkpoint_print_summary $stage $check_result $pd_result

    set needs_attention [expr {
        ![dict get $check_result ok] ||
        ![dict get $pd_result ok]
    }]

    set should_suspend [expr {
        $::TT_CHECKPOINT_SUSPEND_ENABLE &&
        ($always_suspend || $needs_attention)
    }]

    if {$should_suspend} {
        if {[llength [info commands suspend]] == 0} {
            error "Checkpoint '$stage' requires native Innovus suspend, but it is unavailable."
        }

        puts ""
        puts "Inspect/fix the current state if needed."
        puts "When this checkpoint is acceptable, type:"
        puts "  resume"
        puts ""
        puts "IMPORTANT: resume = ACCEPT CURRENT CHECKPOINT."
        puts "           This checkpoint will NOT run check_place/check_floorplan again."
        puts "======================================================================"

        if {[llength [info commands tech_mv_checkpoint_tools]]} { tech_mv_checkpoint_tools $stage $stage }
        suspend

        puts ""
        puts "INFO: Checkpoint '$stage' accepted by resume."
        if {[string match "01*" $stage]} { FP_save "after_manual_${stage}" 98 }
        puts "INFO: No re-check is performed for this checkpoint."
        puts "INFO: The next formal check occurs only at the next checkpoint."
    }

    return [dict create \
        stage $stage \
        accepted true \
        suspended $should_suspend \
        needs_attention $needs_attention \
        check $check_result \
        pd_lock $pd_result]
}

# Compatibility name used by older flow files.  It now obeys the single-check
# checkpoint policy above.
proc tech_mv_endcap_suspend_guard {stage {always_suspend false}} {
    return [tech_mv_checkpoint $stage $always_suspend]
}

# Stage start is NOT another formal checkpoint.  The previous stage-end
# checkpoint was already checked/accepted.  Only lightweight tracking is done.
proc tech_mv_stage_start_guard {stage} {
    puts "INFO: Stage start '$stage': no repeated check_place/check_floorplan."
    if {[llength [info commands TT_track_pd_endcaps]] > 0} {
        TT_track_pd_endcaps "${stage}_start"
    }
    return [dict create stage $stage ok true formal_check false]
}

# Stage end is the one formal placement/floorplan checkpoint for the stage.
proc tech_mv_stage_end_guard {stage next_stage} {
    if {$stage eq "02_powerplan" &&
        (!$::CHECK_ALL_ENABLE || !$::CHECK_STAGE02_FORMAL_CHECKPOINT_ENABLE)} {
        puts "INFO: CHECK SKIPPED: Stage02 formal check_place/check_floorplan checkpoint (config disabled)."
        puts "INFO: Stage '$stage' checkpoint bypassed. Next stage: $next_stage"
        return [dict create stage "${stage}_end" ok true formal_check false skipped true]
    }

    set result [tech_mv_checkpoint "${stage}_end" false]
    puts "INFO: Stage '$stage' checkpoint complete. Next stage: $next_stage"
    return $result
}

# Stage-01 manual PD-snap checkpoint.
# The user edits/snaps PD geometry WHILE suspended.  Therefore checking before
# suspend would describe the pre-edit state and checking again after resume
# would violate the acceptance rule.  We simply suspend, then capture the
# accepted geometry as the lock reference after resume.
proc tech_mv_manual_pd_snap_breakpoint {} {
    if {[llength [info commands suspend]] == 0} {
        error "Manual PD-snap checkpoint requires native Innovus suspend."
    }

    puts ""
    puts "======================================================================"
    puts " CHECKPOINT : MANUAL POWER-DOMAIN SNAP"
    puts "======================================================================"
    puts "Adjust/place/snap the Power Domains now."
    puts "When the geometry is acceptable, type:"
    puts "  resume"
    puts ""
    puts "resume = accept this manual PD geometry."
    puts "No check_place/check_floorplan re-check is executed here."
    puts "======================================================================"

    if {[llength [info commands tech_mv_checkpoint_tools]]} { tech_mv_checkpoint_tools {01_floorplan} {manual_pd_snap} }
    suspend

    puts "INFO: Manual PD geometry accepted by resume."
    FP_save after_manual_pd_snap 100

    if {[llength [info commands tech_mv_pd_lock_capture]] > 0} {
        tech_mv_pd_lock_capture manual_pd_snap_accepted
    }
    if {[llength [info commands TT_track_pd_endcaps]] > 0} {
        TT_track_pd_endcaps manual_pd_snap_accepted
    }

    return true
}
