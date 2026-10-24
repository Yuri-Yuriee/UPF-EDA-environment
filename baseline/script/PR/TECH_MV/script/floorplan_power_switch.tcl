# =============================================================================
# floorplan_power_switch.tcl
# Stage-01 Power-Switch insertion helper.
#
# Intended call point:
#   final PD geometry / finish_floorplan / row cleanup
#       -> EndCaps
#       -> Power Switches (top/bottom clearance)
#       -> overlap/check_place checkpoint
#       -> WellTaps
# =============================================================================

source -quiet [file join $SCRIPT_DIR place_checkpoint.tcl]

proc tech_mv_power_switch_instance_count {} {
    set count 0

    if {[info exists ::POWER_SWITCH_INSTANCE_PREFIXES]} {
        foreach prefix $::POWER_SWITCH_INSTANCE_PREFIXES {
            incr count [llength [get_db insts ${prefix}*]]
        }
        return $count
    }

    incr count [llength [get_db insts PD_WDT_SW*]]
    incr count [llength [get_db insts PD_CPU_SW*]]
    return $count
}

# =============================================================================
# TT_STAGE01_SW_RECOVERY_CHECKPOINT_V1_9
# Debug/recovery DBs only. This helper never checks placement and never suspends.
# =============================================================================
proc tech_mv_sw_recovery_checkpoint {filename label} {
    if {![info exists ::DB_DIR] || $::DB_DIR eq ""} {
        puts "WARNING: Stage-01 SW recovery checkpoint skipped; DB_DIR unavailable: $label"
        return
    }
    if {[llength [info commands write_db]] == 0} {
        puts "WARNING: Stage-01 SW recovery checkpoint skipped; write_db unavailable: $label"
        return
    }

    set path [file join $::DB_DIR $filename]
    puts "INFO: Saving Stage-01 SW recovery DB ($label): $path"
    write_db $path
}

# =============================================================================
# TT_STAGE01_SW_UNIFIED_FLOW_V1_9
# One uninterrupted SW construction sequence:
#   main add_SW
#   -> clean illegal main-SW overlaps
#   -> edge reinforcement for setup-derived gated PDs
#   -> reconnect global nets
#   -> normal Stage-01 EndCap/SW inspection breakpoint later in add_endcaps
# There is NO edge-only suspend.
# =============================================================================
proc tech_mv_floorplan_insert_power_switches {} {
    if {![info exists ::ENABLE_POWER_SWITCH_INSERTION] || !$::ENABLE_POWER_SWITCH_INSERTION} {
        puts "INFO: Power-switch insertion is disabled in Stage 01 floorplan."
        return 0
    }

    set existing_count [tech_mv_power_switch_instance_count]
    if {$existing_count > 0} {
        puts "WARNING: Found $existing_count existing power-switch instances before Stage-01 insertion."
        puts "WARNING: Skip normal add_power_switches to avoid duplicate main-switch insertion."
    } else {
        puts "INFO: Inserting normal power switches in Stage 01 AFTER EndCap insertion."

        switch -- [string tolower $::POWER_SWITCH_INSERTION_MODE] {
            legacy -
            tool {
                uplevel #0 [list source -quiet [file join $::SCRIPT_DIR add_SW.tcl]]
            }
            default {
                error "Unsupported POWER_SWITCH_INSERTION_MODE '$::POWER_SWITCH_INSERTION_MODE'"
            }
        }
    }

    set inserted_count [tech_mv_power_switch_instance_count]
    puts "INFO: Stage-01 main/existing power-switch count before overlap cleanup = $inserted_count"
    if {$inserted_count == 0} {
        error "ENABLE_POWER_SWITCH_INSERTION is true, but no configured power-switch instance exists after normal insertion."
    }

    tech_mv_sw_recovery_checkpoint \
        "01_74_after_main_sw_before_overlap_cleanup.enc" \
        "after main SW / before overlap cleanup"

    # IMPORTANT: clean illegal main-SW/EndCap overlaps BEFORE edge reinforcement.
    # This lets the edge helper replace a deleted boundary column with a legal,
    # inward-shifted NON-CHECKERBOARD edge column.  Do not run auto-delete again
    # after edge insertion; final check_place is handled at the normal single
    # Stage-01 EndCap/SW breakpoint.
    if {[info exists ::POWER_SWITCH_ENDCAP_OVERLAP_CHECK_ENABLE] &&
        $::POWER_SWITCH_ENDCAP_OVERLAP_CHECK_ENABLE} {
        set _tt_swec_tool [file join $::TOOL_DIR 02_powerplan TT_proc_remove_sw_endcap_overlap.tcl]
        if {![file exists $_tt_swec_tool]} {
            error "Missing SW/EndCap marker cleanup tool: $_tt_swec_tool"
        }

        uplevel #0 [list source -quiet $_tt_swec_tool]
        set _tt_swec_deleted [uplevel #0 [list TT_SWEC_apply]]
        puts "INFO: Pre-edge SW/EndCap cleanup deleted $_tt_swec_deleted illegal switch instance(s)."
        unset _tt_swec_deleted
        unset _tt_swec_tool

        set inserted_count [tech_mv_power_switch_instance_count]
        puts "INFO: Power-switch count after pre-edge cleanup = $inserted_count"
        if {$inserted_count == 0} {
            error "All configured main power-switch instances were removed by pre-edge overlap cleanup."
        }
    }

    tech_mv_sw_recovery_checkpoint \
        "01_75_after_main_sw_overlap_cleanup_before_edge.enc" \
        "after main-SW overlap cleanup / before edge SW"

    # Additive boundary reinforcement. The helper derives gated PDs from setup
    # (PD_CFG rail_2nd + POWER_SWITCH_INSTANCE_PREFIXES); no PD list is hard-coded.
    set _tt_edge_sw_tool [file join $::TECH_MV_RUNTIME_ROOT .. script PR TECH_MV script 02_powerplan power_switch proc_power_switch_edge_reinforce.tcl]
    if {![file exists $_tt_edge_sw_tool]} {
        error "Missing required PD-edge SW reinforcement tool: $_tt_edge_sw_tool"
    }

    uplevel #0 [list source -quiet $_tt_edge_sw_tool]
    if {![info exists ::POWER_SWITCH_EDGE_REINFORCE_ENABLE] ||
        $::POWER_SWITCH_EDGE_REINFORCE_ENABLE} {
        set _tt_edge_sw_count [uplevel #0 [list TT_EDGE_SW_apply]]
        puts "INFO: Stage-01 PD-edge SW reinforcement present/created count = $_tt_edge_sw_count"
    } else {
        set _tt_edge_sw_count 0
        puts "INFO: Stage-01 PD-edge SW reinforcement disabled."
    }

    set _tt_edge_failures 0
    if {[info exists ::TT_EDGE_SW_LAST_FAILURE_COUNT]} {
        set _tt_edge_failures $::TT_EDGE_SW_LAST_FAILURE_COUNT
    }
    if {$_tt_edge_failures > 0} {
        puts "WARNING: Edge reinforcement recorded $_tt_edge_failures failure(s)."
        puts "WARNING: No edge-only suspend is used; inspect all results at the normal Stage-01 EndCap/SW breakpoint."
    }

    unset _tt_edge_sw_tool
    unset _tt_edge_sw_count

    tech_mv_sw_recovery_checkpoint \
        "01_76_after_all_edge_sw.enc" \
        "after all setup-derived gated-PD edge SW"

    # All switch creation/deletion is finished now; reconnect GNC exactly once.
    uplevel #0 [list source -quiet $::GLOBAL_NET_FILE]

    tech_mv_sw_recovery_checkpoint \
        "01_78_after_all_sw_global_net.enc" \
        "after all SW + global_net"

    set inserted_count [tech_mv_power_switch_instance_count]
    puts "INFO: Stage-01 final power-switch instance count = $inserted_count"
    if {$inserted_count == 0} {
        error "Stage-01 finished SW construction with zero configured power-switch instances."
    }

    # Debug snapshot only; this helper never suspends.  The one interactive
    # breakpoint remains the existing post-EndCap/SW block in add_endcaps.tcl.
    uplevel #0 [list tech_mv_place_checkpoint \
        "01_after_endcap_power_switch_before_welltap" \
        "01_80_after_endcap_power_switch_before_welltap.enc"]

    unset _tt_edge_failures
    return $inserted_count
}
