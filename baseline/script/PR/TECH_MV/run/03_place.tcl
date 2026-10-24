# Runtime adapter preserves the historical logical source path.
if {[info exists ::TECH_MV_RUNTIME_ROOT]} {
    info script [file join $::TECH_MV_RUNTIME_ROOT run/03_place.tcl]
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
set ::TECH_MV_REPORT_STAGE 03
source -quiet [file join $SCRIPT_DIR prepare_run_dirs.tcl]
source -quiet [file join $SCRIPT_DIR terminal_report_footer.tcl]
source -quiet [file join $SCRIPT_DIR pd_geometry_trace.tcl]
tech_mv_pd_trace_reset 03
tech_mv_pd_trace "stage_entry_before_apply_design_config"     "source run/03_place.tcl"

source -quiet [file join $SCRIPT_DIR apply_design_config.tcl]
tech_mv_pd_trace "after_apply_design_config"     "source script/apply_design_config.tcl"

source -quiet [file join $SCRIPT_DIR place_checkpoint.tcl]
source -quiet [file join $TOOL_DIR 02_powerplan secondary_pg TT_check_lp_2ndpg.tcl]
source -quiet [file join $::TECH_MV_RUNTIME_ROOT .. script PR TECH_MV script 03_place padding proc_ls_padding.tcl]
source -quiet [file join $::TECH_MV_RUNTIME_ROOT .. script PR TECH_MV script 03_place padding proc_ls_iso_padding.tcl]

# -----------------------------------------------------------------------------
# Read-only 2nd-PG readiness check before placement.
# -----------------------------------------------------------------------------
set TT2ND_PRE_PLACE_CHECK [TT_check_lp_2ndpg pre_place]
tech_mv_pd_trace "after_pre_place_2ndpg_check" "TT_check_lp_2ndpg pre_place"

# -----------------------------------------------------------------------------
# Read-only PD geometry/grid + EndCap guard.
#
# IMPORTANT: no EndCap legalization/move is performed automatically here.
# -----------------------------------------------------------------------------
source -quiet [file join $SCRIPT_DIR checkpoint_guard.tcl]
tech_mv_stage_start_guard 03_place
tech_mv_pd_trace "after_stage_start_guard" "tech_mv_stage_start_guard 03_place"

# Existing placement legality checkpoint, plus EndCap location tracking.
tech_mv_place_checkpoint "03_pre_place_endcap_checked" ""

eval_legacy "setOptMode -holdTargetSlack $PLACE_HOLD_TARGET_SLACK -setupTargetSlack $PLACE_SETUP_TARGET_SLACK"
tech_mv_pd_trace "after_setOptMode" "setOptMode -holdTargetSlack/-setupTargetSlack"
eval_legacy "setAnalysisMode -usefulSkew $ENABLE_USEFUL_SKEW"
tech_mv_pd_trace "after_setAnalysisMode" "setAnalysisMode -usefulSkew"


# -----------------------------------------------------------------------------
# Level-Shifter padding must be armed before the first placement operation.
# This is an instance-placement constraint only; no LS is moved here.
# -----------------------------------------------------------------------------
set TT_LS_ISO_PADDING_RESULT [TT_proc_apply_ls_iso_padding]
tech_mv_pd_trace "after_ls_iso_padding" "TT_proc_apply_ls_iso_padding"

set TT_LS_PADDING_RESULT [TT_apply_ls_padding]
tech_mv_pd_trace "after_ls_padding" "TT_apply_ls_padding"

# -----------------------------------------------------------------------------
# Placement
#
# place_opt_design behaves as an incremental placement optimization when the
# design has already entered a placement state.  It cannot be used as the
# first placement operation while a large number of instances are still
# unplaced.  Guard the place_opt flow explicitly:
#
#   unplaced > 0 -> place_design -> verify -> place_opt_design
#
# This keeps PLACEMENT_MODE=place_opt usable as the normal optimized-placement
# mode while preventing IMPSP-9533.
# -----------------------------------------------------------------------------

proc tech_mv_get_unplaced_insts {} {
    return [get_db insts -if {.place_status == unplaced}]
}

proc tech_mv_run_initial_place_if_needed {} {
    set unplaced_insts [tech_mv_get_unplaced_insts]
    set unplaced_count [llength $unplaced_insts]

    puts "INFO: Unplaced instances before placement = $unplaced_count"

    if {$unplaced_count == 0} {
        puts "INFO: Initial placement is already complete."
        return
    }

    puts "INFO: Running initial place_design before placement optimization ..."
    place_design
    tech_mv_pd_trace "after_initial_place_design" "place_design"

    set remaining_insts [tech_mv_get_unplaced_insts]
    set remaining_count [llength $remaining_insts]

    puts "INFO: Remaining unplaced instances after place_design = $remaining_count"

    if {$remaining_count != 0} {
        puts "ERROR: Initial place_design did not place all instances."
        puts "ERROR: Remaining unplaced count = $remaining_count"

        # Print a limited sample for debug without flooding the terminal.
        set sample_count [expr {min($remaining_count, 20)}]

        puts "ERROR: First $sample_count remaining unplaced instance(s):"
        for {set i 0} {$i < $sample_count} {incr i} {
            set inst [lindex $remaining_insts $i]
            puts "ERROR:   [get_db $inst .name]  [get_db $inst .base_cell.name]"
        }

        error "Placement aborted: $remaining_count instance(s) remain unplaced after place_design."
    }
}

switch -- [string tolower $PLACEMENT_MODE] {
    place {
        place_design
        tech_mv_pd_trace "after_place_design_place_mode" "place_design"
    }

    place_opt {
        tech_mv_run_initial_place_if_needed

        puts "INFO: Initial placement completed."
        puts "INFO: Running pre-CTS optimization ..."
        opt_design -pre_cts -report_dir [tech_mv_report_dir 03 timing]
        tech_mv_pd_trace "after_opt_design_pre_cts" "opt_design -pre_cts"
    }

    place_then_opt {
        tech_mv_run_initial_place_if_needed
        puts "INFO: Running place_opt_design ..."
        place_opt_design -report_dir [tech_mv_report_dir 03 timing]
        tech_mv_pd_trace "after_place_opt_design" "place_opt_design"
    }

    default {
        error "Unsupported PLACEMENT_MODE '$PLACEMENT_MODE'"
    }
}

# -----------------------------------------------------------------------------
# Post-placement detail legalization.
#
# Do NOT run check_place before and after place_detail here.  These were debug
# checks, not separate manual checkpoints, and only repeated the same checker
# inside one checkpoint interval.
# -----------------------------------------------------------------------------
puts ""
puts "======================================================================"
puts " PLACE_DETAIL"
puts "======================================================================"
place_detail
tech_mv_pd_trace "after_place_detail" "place_detail"

# Debug snapshot only: tracks EndCap movement; no formal checker.
tech_mv_place_checkpoint "03_after_place_detail" ""

# -----------------------------------------------------------------------------
# Post-placement 2nd-PG readiness check.
# This checker is independent of check_place/check_floorplan.
# -----------------------------------------------------------------------------
set TT2ND_POST_PLACE_CHECK [TT_check_lp_2ndpg post_place]
tech_mv_pd_trace "after_post_place_2ndpg_check" "TT_check_lp_2ndpg post_place"

# Save the exact pre-2ndPG database before entering the manual checkpoint.
write_db [file join $DB_DIR 03_10_post_place_pre_2ndpg.enc]


puts ""
puts "======================================================================"
puts " POST-PLACE / PRE-2nd-PG STATUS"
puts "======================================================================"
puts "2nd-PG readiness : [expr {[dict get $TT2ND_POST_PLACE_CHECK ok] ? {PASS} : {FAIL}}]"
puts "Check report     : [dict get $TT2ND_POST_PLACE_CHECK report]"
puts "Problem cells    : [dict get $TT2ND_POST_PLACE_CHECK problem_report]"
puts "Breakpoint DB    : [file join $DB_DIR 03_10_post_place_pre_2ndpg.enc]"
puts "======================================================================"

# If the deliberate breakpoint is disabled, a real 2nd-PG readiness failure
# remains fatal because there is no human acceptance step.
if {!$::ENABLE_POST_PLACE_2NDPG_BREAKPOINT &&
    ![dict get $TT2ND_POST_PLACE_CHECK ok]} {
    error "Post-place 2nd-PG readiness FAIL with breakpoint disabled. See [dict get $TT2ND_POST_PLACE_CHECK report]"
}

# ONE formal check_place + check_floorplan for this checkpoint.
# If suspended, resume means the current state is accepted; no re-check follows.
tech_mv_pd_trace "before_post_place_checkpoint" "tech_mv_checkpoint 03_post_place_pre_2ndpg"
set TT_PRE_2NDPG_CHECKPOINT \
    [tech_mv_checkpoint \
        "03_post_place_pre_2ndpg" \
        $::ENABLE_POST_PLACE_2NDPG_BREAKPOINT]
tech_mv_pd_trace "after_post_place_checkpoint_resume" "returned from tech_mv_checkpoint 03_post_place_pre_2ndpg"

# Fresh rollback point after any manual edits accepted at the checkpoint.
set TT_PRE_2NDPG_RESTORE_DB \
    [file join $DB_DIR 03_20_pre_2ndpg_restore.enc]
puts "INFO: Saving accepted pre-2ndPG rollback DB: $TT_PRE_2NDPG_RESTORE_DB"
write_db $TT_PRE_2NDPG_RESTORE_DB

set TT_2NDPG_MODE [string toupper $::SECONDARY_PG_ROUTE_MODE]

switch -- $TT_2NDPG_MODE {
    SIGNAL {
        # SIGNAL-mode secondary PG is intentionally deferred until after CTS
        # and post-CTS optimization.  LP/AON cells remain movable here.
        puts ""
        puts "======================================================================"
        puts " 2nd-PG DEFERRED"
        puts "======================================================================"
        puts "Mode           : SIGNAL"
        puts "Current stage  : 03_place"
        puts "Action         : No 2nd-PG routing here."
        puts "Next action    : Route secondary PG in 05_route before route_design."
        puts "LP/AON status  : unchanged; no forced FIXED."
        puts "======================================================================"

        # No post-2ndPG checkpoint exists here because the database has not
        # changed by secondary-PG routing yet.
    }

    SROUTE {
        # Preserve the original placement-time SROUTE flow.
        tech_mv_pd_trace "before_placement_secondary_pg" "source TT_flow_post_place_lp_2ndpg.tcl"
        source -quiet [file join $::TECH_MV_RUNTIME_ROOT .. script PR TECH_MV script 02_powerplan secondary_pg flow_post_place_lp_2ndpg.tcl]
        tech_mv_pd_trace "after_placement_secondary_pg" "source TT_flow_post_place_lp_2ndpg.tcl"

        set TT_POST_2NDPG_CHECKPOINT \
            [tech_mv_checkpoint \
                "03_after_2ndpg" \
                $::ENABLE_POST_2NDPG_INSPECTION_BREAKPOINT]

        puts "INFO: SROUTE secondary PG completed during 03_place."
        puts "INFO: Resume accepts this checkpoint; no same-checkpoint re-check."
    }

    default {
        error "SECONDARY_PG_ROUTE_MODE must be SIGNAL or SROUTE, got '$::SECONDARY_PG_ROUTE_MODE'"
    }
}

# Debug snapshot only; no repeated checker.
tech_mv_place_checkpoint "03_after_placement" ""
tech_mv_pd_trace "stage_exit" "03_place completion before final DB"
write_db [file join $DB_DIR 03_99_placement.enc]

puts "INFO: Placement DB written: [file join $DB_DIR 03_99_placement.enc]"
puts "INFO: 2nd-PG route mode = $TT_2NDPG_MODE"


puts ""
puts "======================================================================"
puts " FINAL PLACEMENT REPORT SUMMARY"
puts "======================================================================"
if {[info exists TT2ND_POST_PLACE_CHECK]} {
    puts "2nd-PG readiness : [expr {[dict get $TT2ND_POST_PLACE_CHECK ok] ? {PASS} : {FAIL}}]"
    puts "Check report     : [dict get $TT2ND_POST_PLACE_CHECK report]"
    puts "Problem cells    : [dict get $TT2ND_POST_PLACE_CHECK problem_report]"
}
puts "Placement DB     : [file join $DB_DIR 03_99_placement.enc]"
puts "2nd-PG route mode: $TT_2NDPG_MODE"
if {[info exists TT_LS_ISO_PADDING_RESULT]} {
    puts "LS/ISO padding    : [expr {[dict get $TT_LS_ISO_PADDING_RESULT enabled] ? {ENABLED} : {DISABLED}}]"
    puts "LS/ISO padded     : [dict get $TT_LS_ISO_PADDING_RESULT applied]"
    puts "ISO targets       : [dict get $TT_LS_ISO_PADDING_RESULT iso]"
    puts "LS/ISO pad sites  : left=$::LS_ISO_PADDING_SITES right=$::LS_ISO_PADDING_SITES"
}
if {[info exists TT_LS_PADDING_RESULT]} {
    puts "LS padding       : [expr {[dict get $TT_LS_PADDING_RESULT enabled] ? {ENABLED} : {DISABLED}}]"
    puts "LS padded insts  : [dict get $TT_LS_PADDING_RESULT applied_count]"
    puts "LS pad sites     : left=$::LS_PADDING_LEFT right=$::LS_PADDING_RIGHT"
}
puts "======================================================================"

set _stage03_extra_reports {}
if {[info exists TT2ND_POST_PLACE_CHECK]} {
    lappend _stage03_extra_reports [dict get $TT2ND_POST_PLACE_CHECK report]
    lappend _stage03_extra_reports [dict get $TT2ND_POST_PLACE_CHECK problem_report]
}
tech_mv_terminal_report_footer 03 $_stage03_extra_reports
unset _stage03_extra_reports
