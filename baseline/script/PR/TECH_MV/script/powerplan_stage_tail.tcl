# Load definitions only; no APR action or setup reload is performed here.
if {![llength [info commands ::tech_mv_library_value]]} {
    if {[info exists ::TOOL_DIR]} {
        source -quiet [file join $::TECH_MV_RUNTIME_ROOT .. script PR TECH_MV script 00_common private_parameter_config.tcl]
    } else {
        source -quiet [file join $::TECH_MV_RUNTIME_ROOT .. script PR TECH_MV script 00_common private_parameter_config.tcl]
    }
}
# Load the output-path helper if this stage is sourced by an older live session.
if {![llength [info commands ::tech_mv_native_report_command]]} {
    source -quiet [file join $::TOOL_DIR 00_common TT_runtime_output_helpers.tcl]
}
# =============================================================================
# powerplan_stage_tail.tcl
# Common Stage 02 tail used by normal execution and checkpoint resume.
# =============================================================================

source -quiet [file join $SCRIPT_DIR place_checkpoint.tcl]


proc tech_mv_powerplan_tail_checkpoint {point db_name} {
    set db_file [file join $::DB_DIR $db_name]
    write_db $db_file
    puts "INFO: PowerPlan late restore DB = $db_file"
    puts "INFO: Quick resume: pp_restore $point"
    return $db_file
}


proc tech_mv_powerplan_tail_next_rank {resume_from} {
    switch -- $resume_from {
        ""                     { return 10 }
        after_switch_verify    { return 15 }
        after_secondary_pg     { return 30 }
        after_final_mesh_color { return 40 }
        after_final_check      { return 45 }
        after_bond_pad_preview { return 50 }
        stage02_complete       { return 60 }
        default {
            error "Unsupported Stage-02 tail resume point '$resume_from'."
        }
    }
}


proc tech_mv_powerplan_stage_tail {{resume_from ""}} {
    set next_rank [tech_mv_powerplan_tail_next_rank $resume_from]

    puts "INFO: Entering Stage 02 post-mesh PowerPlan tail."
    if {$resume_from ne ""} {
        puts "INFO: Tail resume point = $resume_from"
    }

    if {[llength [info commands tech_mv_pd_trace]] > 0} {
        tech_mv_pd_trace "stage_tail_entry" "tech_mv_powerplan_stage_tail $resume_from"
    }

    # -------------------------------------------------------------------------
    # Phase 10: verify Stage-01 power switches before any Stage-02 secondary PG.
    # Stage 02 never inserts the switches again.
    # -------------------------------------------------------------------------
    if {$next_rank <= 10} {
        if {$::ENABLE_POWER_SWITCH_INSERTION} {
            set stage02_sw_count 0
            if {[info exists ::POWER_SWITCH_INSTANCE_PREFIXES]} {
                foreach prefix $::POWER_SWITCH_INSTANCE_PREFIXES {
                    incr stage02_sw_count [llength [get_db insts ${prefix}*]]
                }
            } else {
                incr stage02_sw_count [llength [get_db insts PD_WDT_SW*]]
                incr stage02_sw_count [llength [get_db insts PD_CPU_SW*]]
            }

            if {$stage02_sw_count == 0} {
                error "Power switches are enabled but none are present at Stage 02 input. Re-run 01_floorplan with Stage-01 switch insertion enabled."
            }
            puts "INFO: Stage 02 found $stage02_sw_count pre-inserted power-switch instances from 01_floorplan."
        } else {
            puts "INFO: Stage-02 power-switch verification is disabled."
        }

        powerplan_step_pause stage_switch_verify_complete \
            "Verified the Stage-01 power-switch population before secondary PG routing."

        tech_mv_powerplan_tail_checkpoint \
            after_switch_verify \
            02_91_after_switch_verify.enc

        # RESUME_POINT_TAIL: after_switch_verify
    }

    # -------------------------------------------------------------------------
    # Phase 15: grow the Stage-02 secondary PG before SDP placement.
    # At this point Power Switches are already placed while the deferred SDP
    # cells have not yet been temporarily placed/fixed by the SDP flow.
    # -------------------------------------------------------------------------
    if {$next_rank <= 15} {
        if {$::ENABLE_SECONDARY_PG_ROUTE} {
            puts "INFO: Growing pre-SDP Stage-02 secondary PG with the existing legacy flow."
            uplevel #0 [list source -quiet [file join $::TOOL_DIR 02_powerplan secondary_pg TT_flow_2ndpg_legacy.tcl]]
        } else {
            puts "INFO: Secondary PG routing is disabled."
        }
    }

    # -------------------------------------------------------------------------
    # Phase 20: place/validate/fix 2-row SDP, then insert general WellTaps.
    # TT_2row_sdp_welltap_after_endcap_v6.tcl fixes every legal SDP member
    # after place_sdps + validation so later placement must not move the SDP.
    # -------------------------------------------------------------------------
    if {$next_rank <= 20} {
        uplevel #0 [list source -quiet [file join $::SCRIPT_DIR post_powerplan_welltap_sdp.tcl]]

        tech_mv_powerplan_tail_checkpoint \
            after_secondary_pg \
            02_92_after_secondary_pg.enc

        # RESUME_POINT_TAIL: after_secondary_pg
    }

    # -------------------------------------------------------------------------
    # Phase 30: final coloring after all PG objects exist.
    # -------------------------------------------------------------------------
    if {$next_rank <= 30} {
        puts "INFO: Applying final power-mesh colors after all PG routing."
        tech_mv_native_report_command 02 power_color [list add_power_mesh_colors]
        powerplan_step_pause final_power_mesh_colorization \
            "Applied final power-mesh colors after secondary PG routing with Stage-01 switches present."

        tech_mv_powerplan_tail_checkpoint \
            after_final_mesh_color \
            02_93_after_final_mesh_color.enc

        # RESUME_POINT_TAIL: after_final_mesh_color
    }

    # -------------------------------------------------------------------------
    # Phase 40: final comprehensive PowerPlan checks.
    # -------------------------------------------------------------------------
    if {$next_rank <= 40} {
        if {$::CHECK_ALL_ENABLE && $::POWERPLAN_FINAL_CHECK_ENABLE} {
            uplevel #0 [list source -quiet [file join $::SCRIPT_DIR powerplan_final_check.tcl]]
            uplevel #0 [list tech_mv_powerplan_final_check]
            powerplan_step_pause stage_final_powerplan_check \
                "Completed final PowerPlan DRC/global-net/floorplan/place/PG checks."
        } else {
            puts "INFO: CHECK SKIPPED: Final comprehensive PowerPlan checks (config disabled)."
        }

        # Read-only SW path check after final PG/via/color operations.
        # Shared tail covers both normal Stage-02 execution and resume paths.
        tech_mv_powerplan_sw_pg_check

        tech_mv_powerplan_tail_checkpoint \
            after_final_check \
            02_95_after_final_check.enc

        # RESUME_POINT_TAIL: after_final_check
    }

    # -------------------------------------------------------------------------
    # Phase 45: FILL_IN_CELL_BOND_PAD_041 package-interface preview after PowerPlan is complete.
    # -------------------------------------------------------------------------
    if {$next_rank <= 45} {
        if {$::ENABLE_POWERPLAN_BOND_PAD_PREVIEW} {
            uplevel #0 [list source -quiet [file join $::TOOL_DIR 01_floorplan TT_proc_bond_pad_preview.tcl]]
            uplevel #0 [list TT_bond_pad_preview_checkpoint                 "after complete PowerPlan"                 $::POWERPLAN_BOND_PAD_PREVIEW_DB_NAME                 $::POWERPLAN_BOND_PAD_PREVIEW_AFTER_DB_NAME                 false]
        } else {
            puts [::tech_mv_library_value LIB_TEXT_019]
            write_db [file join $::DB_DIR $::POWERPLAN_BOND_PAD_PREVIEW_AFTER_DB_NAME]
        }
        puts "INFO: Quick resume: pp_restore after_bond_pad_preview"

        # RESUME_POINT_TAIL: after_bond_pad_preview
    }

    # -------------------------------------------------------------------------
    # Phase 50: final Stage-02 database before the formal stage-end guard.
    # -------------------------------------------------------------------------
    if {$next_rank <= 50} {
        uplevel #0 [list tech_mv_place_checkpoint "02_powerplan_final" ""]
        write_db [file join $::DB_DIR 02_99_powerplan.enc]
        powerplan_step_pause stage_02_database_written \
            "Saved the final 02_99_powerplan.enc database."

        puts "INFO: Quick resume: pp_restore stage02_complete"

        # RESUME_POINT_TAIL: stage02_complete
    }

    if {[llength [info commands tech_mv_pd_trace]] > 0} {
        tech_mv_pd_trace "stage_tail_exit" "tech_mv_powerplan_stage_tail $resume_from"
    }

    puts "INFO: Stage 02 PowerPlan tail completed."
}

# Formal Stage-02 check with one optional bounded repair pass and review gate.
proc tech_mv_powerplan_sw_pg_check {} {
    if {!$::CHECK_ALL_ENABLE || !$::POWERPLAN_SW_PG_CHECK_ENABLE} {
        puts "INFO: CHECK SKIPPED: Stage-02 SW PG geometry-path check (config disabled)."
        return [dict create status DISABLED]
    }
    set tool [file join $::TOOL_DIR 02_powerplan power_switch TT_check_switch_via4_m5.tcl]
    set review 0;set result {};set repair {}
    set ::POWERPLAN_SW_PG_STAGE_REPAIR_RESULT {}
    if {[catch {
        if {![file isfile $tool]} {error "SW PG checker is missing: $tool"}
        uplevel #0 [list source -quiet $tool]
        set result [uplevel #0 [list TT_SW_PG_check {} $::POWERPLAN_SW_PG_CHECK_MAX_NODES]]
        if {[info exists ::POWERPLAN_SW_PG_REPAIR_ENABLE] && $::POWERPLAN_SW_PG_REPAIR_ENABLE &&
            [dict exists $result counts] && [dict get $result counts NO_PATH_FOUND]>0} {
            if {[dict get $result counts UNKNOWN]>0 || [dict get $result counts NO_TARGET]>0} {
                puts "WARNING: Automatic SW repair skipped because target discovery/search is incomplete."
            } else {
                puts "INFO: Stage-02 SW PG repair: one preview/apply pass, with a mandatory pre-repair DB."
                set plan [uplevel #0 [list TT_SW_PG_repair_preview [dict get $result report_dir]]]
                if {[llength [dict get $plan ready]]} {
                    set repair [uplevel #0 [list TT_SW_PG_repair_apply [dict get $plan id] $::POWERPLAN_SW_PG_REPAIR_MAX_SWITCHES]]
                    set ::POWERPLAN_SW_PG_STAGE_REPAIR_RESULT $repair
                    # Recheck all configured switches after local routing edits.
                    set result [uplevel #0 [list TT_SW_PG_check {} $::POWERPLAN_SW_PG_CHECK_MAX_NODES]]
                    if {![tech_mv_powerplan_sw_pg_repair_acceptable $repair]} {
                        set review 1
                        puts "WARNING: Automatic SW repair requires native-result review; inspect its checkpoint and reports."
                    }
                } else {
                    set review 1
                    puts "WARNING: No READY automatic SW repair candidates; inspect preview BLOCKED reasons."
                }
            }
        }
        if {![dict exists $result counts] || ![dict exists $result switches] || [dict get $result switches]==0} {
            set review 1
            puts "WARNING: SW PG check has no complete target summary; no PASS is asserted."
        } else {
            foreach status {NO_PATH_FOUND UNKNOWN NO_TARGET} {
                if {[dict get $result counts $status]>0} {set review 1}
            }
        }
    } message options]} {
        set review 1
        set result [dict create status CHECK_ERROR message $message]
        puts "WARNING: Stage-02 SW PG check could not complete: $message"
    }
    set ::POWERPLAN_SW_PG_STAGE_RESULT $result
    if {!$review} {
        puts "INFO: Stage-02 SW PG geometry check found M5 routes for all discovered VIA1 seeds."
        puts "INFO: This is not switch-pin-to-source electrical connectivity signoff."
        return $result
    }
    puts "WARNING: Stage-02 SW PG findings require review; inspect checker and repair reports."
    if {$::POWERPLAN_SW_PG_CHECK_PAUSE_ON_FINDINGS} {
        set debug_db [file join $::DB_DIR "02_94_sw_pg_review_[clock clicks].enc"]
        write_db $debug_db
        puts "SW PG review DB: $debug_db"
        puts "Review highlighted SWs and reports. Rerun TT_SW_PG_check after manual changes."
        puts "Type resume to accept this review checkpoint and continue; resume does not recheck or repair."
        if {[llength [info commands tech_mv_checkpoint_tools]]} {
            tech_mv_checkpoint_tools 02_powerplan stage_final_sw_pg_review
        }
        suspend
        puts "WARNING: SW PG review checkpoint accepted; previous findings remain recorded, not cleared or rechecked."
    } else {
        puts "WARNING: Continuing with recorded SW PG findings because pause-on-findings is disabled."
    }
    return $result
}

# This gate accepts only geometric completion with fully parsed, non-increasing
# native checks and zero DRC/uncolored baseline+post counts. It is not PG signoff.
proc tech_mv_powerplan_sw_pg_repair_acceptable {repair} {
    if {![dict exists $repair status] || [dict get $repair status] ne "GEOMETRY_REPAIRED_NATIVE_REVIEW_REQUIRED"} {return 0}
    if {[dict get $repair write_error] ne {} || [llength [dict get $repair targets]]==0 ||
        [llength [dict get $repair verified_targets]]!=[llength [dict get $repair targets]]} {return 0}
    foreach label {connectivity power_vias drc metal_color} {
        if {![dict exists $repair regression $label] || [dict get $repair regression $label] ne "NOT_INCREASED"} {return 0}
    }
    foreach phase {baseline after} {
        foreach label {drc metal_color} {
            if {![dict exists $repair $phase $label count] || [dict get $repair $phase $label count] ne "0"} {return 0}
        }
    }
    return 1
}
