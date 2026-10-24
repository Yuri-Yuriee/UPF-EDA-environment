# =============================================================================
# Floorplan
# =============================================================================
puts "User script [info script]"

# Helper used to discard temporary Standard-Cell locations created by
# place_design -concurrent_macros while preserving Hard-Macro placement.
source -quiet [file join $SCRIPT_DIR unplace_standard_cells.tcl]

proc fp_get_unplaced_hard_macros {} {
    set result {}
    foreach inst [get_db insts -if {
        .base_cell.base_class == block &&
        .is_pad == false
    }] {
        if {[get_db $inst .place_status] eq "unplaced"} {
            lappend result [get_db $inst .name]
        }
    }
    return $result
}

proc fp_mode_requires_manual_pd {floorplan_mode} {
    if {!$::ENABLE_MANUAL_POWER_DOMAIN_PLACEMENT} {
        return false
    }
    return [expr {
        [lsearch -exact $::MANUAL_POWER_DOMAIN_FLOORPLAN_MODES $floorplan_mode] >= 0
    }]
}

proc fp_run_power_domain_geometry_flow {} {
    # Apply configured reshape/snap/cut only after the power-domain geometry is
    # available, and before automatic/manual hard-macro placement begins.
    # Source the tool script in global scope because its config variables are
    # defined by init.setup and setup/config/01_floorplan.config.tcl at global scope.
    set pd_flow_file [file join $::SCRIPT_DIR pd_reshape_flow.tcl]

    if {![file exists $pd_flow_file]} {
        error "Power-domain geometry flow file does not exist: $pd_flow_file"
    }

    uplevel #0 [list source -quiet $pd_flow_file]
}

# Remove only PD geometry-tool inner/legacy-inner blockages after macro placement.
# Existing mode-specific deletion protects outer and unrelated blockages.
proc fp_remove_inner_pd_blockages_after_macro {} {
    if {![llength [info commands tt_pd_delete_boundary_blockages_by_mode]] ||
        ![llength [info commands tt_pd_get_all_power_domains]]} {
        uplevel #0 [list source -quiet [file join $::TOOL_DIR 01_floorplan geometry TT_proc_pd_geometry.tcl]]
    }
    set removed 0
    foreach pd [tt_pd_get_all_power_domains false] {
        incr removed [llength [tt_pd_delete_boundary_blockages_by_mode $pd inner true]]
    }
    puts "INFO: Post-macro cleanup removed $removed PD inner blockage(s)."
    return $removed
}

proc fp_apply_pd_macro_guard {} {
    if {$::ENABLE_PD_BOUNDARY_GUARD && $::PD_BOUNDARY_GUARD_PRE_MACRO_ENABLE} {
        uplevel #0 [list source -quiet [file join $::TECH_MV_RUNTIME_ROOT .. script PR TECH_MV script 01_floorplan checks proc_pd_guard.tcl]]
        tt_pd_guard_apply macro
    }
}

# Re-enforce automatic hard-macro spacing after place_macro_detail.
# The spacing value itself remains authoritative in 01_floorplan.config.tcl as
# MACRO_MIN_SPACE_TO_MACRO.  This helper only runs in FLOORPLAN_MODE auto.
proc fp_enforce_auto_macro_spacing {} {
    if {![info exists ::MACRO_MIN_SPACE_TO_MACRO]} {
        error "MACRO_MIN_SPACE_TO_MACRO is not defined."
    }
    if {[llength [info commands refine_macro_place]] == 0} {
        error "Required Innovus command refine_macro_place is unavailable."
    }

    puts ""
    puts "======================================================================"
    puts " AUTO HARD-MACRO MINIMUM SPACING"
    puts "======================================================================"
    puts "Requested macro-to-macro spacing = $::MACRO_MIN_SPACE_TO_MACRO"
    puts "INFO: Re-running refine_macro_place after place_macro_detail."

    refine_macro_place

    if {[info exists ::CHECK_ALL_ENABLE] && !$::CHECK_ALL_ENABLE} {
        puts "INFO: CHECK SKIPPED: check_macro_place_constraint (CHECK_ALL_ENABLE=false)."
    } elseif {[llength [info commands check_macro_place_constraint]] > 0} {
        puts "INFO: Checking final hard-macro placement constraints."
        check_macro_place_constraint
    } else {
        puts "WARNING: check_macro_place_constraint is unavailable; spacing refinement was still executed."
    }

    puts "INFO: Automatic hard-macro spacing refinement completed."
    puts "======================================================================"
}

# -----------------------------------------------------------------------------
# Re-entrant Stage-01 helpers
# -----------------------------------------------------------------------------
# These procedures make formal restore/redo operations deterministic.  A restore
# never re-sources the complete physical flow; it calls only the continuation
# that belongs to the restored checkpoint.

proc fp_normalize_existing_io_file {io_file} {
    if {$io_file eq ""} {
        error "IO_FILE is empty."
    }

    set resolved [file normalize $io_file]
    if {![file isfile $resolved]} {
        error "IO file does not exist: $resolved"
    }
    return $resolved
}

proc fp_run_io_placement_phase {{io_file ""}} {
    if {$io_file eq ""} {
        set io_file $::IO_FILE
    }

    set io_file [fp_normalize_existing_io_file $io_file]
    set ::IO_FILE $io_file

    puts ""
    puts "======================================================================"
    puts " STAGE-01 IO PLACEMENT PHASE"
    puts "======================================================================"
    puts "IO_FILE : $::IO_FILE"
    puts "======================================================================"

    # The DIE/core geometry is established by the selected floorplan bound
    # mode before IO placement. read_io_file MUST NOT resize the DIE; the
    # previous apparent "die snap" issue was caused by omitting this option.
    read_io_file $::IO_FILE -no_die_size_adjust
    snap_floorplan -all
    if {$::CHECK_ALL_ENABLE && $::CHECK_STAGE01_IO_FLOORPLAN_ENABLE} {
        check_floorplan -out_file [tech_mv_output_path report "01_floorplan_[clock clicks -microseconds].rpt" 01 native]
    } else {
        puts "INFO: CHECK SKIPPED: Stage01 IO check_floorplan (config disabled)."
    }

    if {$::ENABLE_IO_SWAP} {
        uplevel #0 [list source -quiet [file join $::SCRIPT_DIR swap_io_hv.tcl]]
        do_swap_io
    }

    # H/V replacement can change PAD physical geometry, so re-snap after swap.
    # The full Stage-01 tail will run check_floorplan again after PD geometry.
    snap_floorplan -all

    puts "INFO: Stage-01 IO placement phase completed."
    return $::IO_FILE
}

proc fp_run_post_boundary_tail {} {
    # Optional secondary safety blockage. Disabled by default because the moat
    # contains no legal placement rows.
    if {$::ENABLE_PD_BOUNDARY_GUARD && $::PD_BOUNDARY_GUARD_POST_ENDCAP_ENABLE} {
        uplevel #0 [list source -quiet [file join $::TECH_MV_RUNTIME_ROOT .. script PR TECH_MV script 01_floorplan checks proc_pd_guard.tcl]]
        tt_pd_guard_apply hard
    }

    if {$::CHECK_ALL_ENABLE && $::CHECK_STAGE01_FINAL_FLOORPLAN_ENABLE} {
        check_floorplan -out_file [tech_mv_output_path report "01_floorplan_[clock clicks -microseconds].rpt" 01 native]
    } else {
        puts "INFO: CHECK SKIPPED: Stage01 final check_floorplan (config disabled)."
    }

    write_floorplan [file join $::OUTPUT_DIR ${::TOP_MODULE}.fp]
    write_db [file join $::DB_DIR 01_99_floorplan.enc]
    puts "INFO: Stage-01 completed DB = [file join $::DB_DIR 01_99_floorplan.enc]"
}

proc fp_run_boundary_phase {} {
    # Insert EndCap, boundary-tap, and WellTap cells only after the PD row moat
    # is physically present, so EndCaps protect the newly exposed row edges.
    uplevel #0 [list source -quiet [file join $::SCRIPT_DIR insert_boundary_cells_after_floorplan.tcl]]
    fp_run_post_boundary_tail
}

proc fp_run_welltap_from_post_switch_checkpoint {} {
    # Dedicated continuation used by both NORMAL 01_80 restore and the restored
    # EndCap/SW suspend checkpoint.  EndCaps and switches already exist.
    if {$::ENABLE_WELL_TAP_INSERTION && (!$::DEFER_WELL_TAP_TO_POST_POWERPLAN)} {
        puts "INFO: Continuing Stage-01 with existing WellTap implementation."
        uplevel #0 [list source -quiet [file join $::SCRIPT_DIR add_well_taps.tcl]]
    } elseif {$::ENABLE_WELL_TAP_INSERTION && $::DEFER_WELL_TAP_TO_POST_POWERPLAN} {
        puts "INFO: General WellTap insertion is deferred to post-PowerPlan Stage 02."
    } else {
        puts "INFO: WellTap insertion is disabled by ENABLE_WELL_TAP_INSERTION."
    }

    set boundary_db [file join $::DB_DIR 01_90_boundary_cells.enc]
    write_db $boundary_db
    puts "INFO: Boundary-cell continuation DB = $boundary_db"

    fp_run_post_boundary_tail
}

proc fp_run_post_macro_floorplan {} {
    set unplaced [fp_get_unplaced_hard_macros]
    if {[llength $unplaced] > 0} {
        foreach name $unplaced {
            puts "ERROR: Unplaced hard macro: $name"
        }
        error "Floorplan stopped because [llength $unplaced] hard macro(s) remain unplaced."
    }

    # Check placement and power-domain containment before fixing hard macros.
    #
    # Stage-01 policy:
    #   A geometry/Power-Domain validation failure is an operator inspection
    #   condition, not a fatal Tcl error.  Suspend in Innovus, let the user fix
    #   the Floorplan/PD geometry, and automatically re-run the same checker
    #   after native "resume".  Unexpected Tcl/tool failures are still fatal.
    if {$::CHECK_ALL_ENABLE && $::CHECK_STAGE01_HARDMACRO_PD_ENABLE} {
        set ::TECH_MV_REPORT_STEP 50

        while {1} {
            set _hm_pd_rc [catch {
                uplevel #0 [list source -quiet [file join $::SCRIPT_DIR check_hardmacro_power_domain.tcl]]
            } _hm_pd_msg _hm_pd_opts]

            if {!$_hm_pd_rc} {
                puts "INFO: FLOORPLAN hard-macro / Power-Domain check PASS."
                break
            }

            # Only convert the checker's known validation failure into a
            # Floorplan suspend.  Syntax/tool/runtime errors must remain fatal
            # so real bugs are never hidden as an operator checkpoint.
            if {![regexp {^Hard macro / Power Domain core check failed with ([0-9]+) error\(s\)\. Powerplan is stopped\.$} \
                    $_hm_pd_msg -> _hm_pd_error_count]} {
                unset -nocomplain ::TECH_MV_REPORT_STEP
                return -options $_hm_pd_opts $_hm_pd_msg
            }

            puts ""
            puts "======================================================================"
            puts " FLOORPLAN HARD-MACRO / POWER-DOMAIN CHECK NEEDS ATTENTION"
            puts "======================================================================"
            puts "Errors : $_hm_pd_error_count"
            puts "Action : SUSPEND (Floorplan is NOT aborted)"
            puts ""
            puts "Fix the Hard-Macro / Power-Domain geometry in the Innovus GUI."
            puts "Then run native 'resume'."
            puts "The same Floorplan check will run again automatically."
            puts "The flow continues only after the check becomes clean."
            puts "======================================================================"
            puts ""

            if {[llength [info commands suspend]] == 0} {
                unset -nocomplain ::TECH_MV_REPORT_STEP
                error "Floorplan hard-macro / Power-Domain check requires suspend, but native Innovus suspend is unavailable."
            }

            if {[llength [info commands tech_mv_checkpoint_tools]]} { tech_mv_checkpoint_tools {01_floorplan} {floorplan} }
            suspend

            puts ""
            puts "INFO: Resumed Stage-01 Floorplan."
            FP_save after_manual_macro_pd_repair 51
            puts "INFO: Re-running hard-macro / Power-Domain check before continuing."
        }

        unset -nocomplain _hm_pd_rc _hm_pd_msg _hm_pd_opts _hm_pd_error_count
        unset ::TECH_MV_REPORT_STEP
    } else {
        puts "INFO: CHECK SKIPPED: Stage01 hard-macro / Power-Domain check (config disabled)."
    }

    set_instance_placement_status -all_hard_macros -status fixed
    delete_relative_floorplan -all

    set_db finish_floorplan_active_objs [list core macro macro_halo soft_blockage]
    finish_floorplan -fill_place_blockage soft $::FLOORPLAN_FINISH_PLACE_BLOCKAGE_SOFT_SIZE

    # The original HDL_pr auto-macro flow discarded every temporary non-pad core
    # placement after finish_floorplan. Run strict cleanup before EndCap/WellTap.
    if {$::CLEAR_STD_CELLS_AFTER_MACRO_FLOORPLAN} {
        unplace_standard_cells "after concurrent Hard-Macro floorplan" 60
    }

    # Cut the configured placement-row moat before EndCap insertion.
    if {$::ENABLE_PD_BOUNDARY_ROW_GUARD} {
        uplevel #0 [list source -quiet [file join $::TECH_MV_RUNTIME_ROOT .. script PR TECH_MV script 01_floorplan checks proc_pd_row_guard.tcl]]
        TT_apply_pd_boundary_row_guard
    }

    fp_run_boundary_phase
}

proc fp_run_gui_manual_macro_stage {} {
    set db [file join $::DB_DIR 01_30_before_manual_macro.enc]
    write_db $db
    puts "INFO: Saved checkpoint before manual hard-macro placement: $db"

    fp_prompt_resume \
        "Manual GUI Hard-Macro Placement" \
        [list \
            "Power-domain placement is complete." \
            "Place all non-pad hard macros in the GUI." \
            "Do not fix the hard macros manually; the flow will check them first." \
        ]
    if {[llength [info commands tech_mv_checkpoint_tools]]} { tech_mv_checkpoint_tools {01_floorplan} {floorplan} }
    suspend
    puts "INFO: Resumed after manual hard-macro placement."
    fp_remove_inner_pd_blockages_after_macro
    FP_save after_manual_macro 31
}

proc fp_continue_after_manual_power_domain {} {
    FP_save restored_manual_power_domain 21
    set floorplan_mode [string tolower $::FLOORPLAN_MODE]

    set resolved_domains [fp_pd_resolve_manual_domains $::MANUAL_POWER_DOMAIN_NAMES]
    if {[llength $resolved_domains] == 0} {
        set msg "No power domain was resolved after the manual GUI stage."
        if {$::MANUAL_POWER_DOMAIN_STRICT} { error $msg }
        puts "WARNING: $msg"
        return
    }
    fp_pd_validate_manual_placement $resolved_domains $::MANUAL_POWER_DOMAIN_STRICT

    switch -- $floorplan_mode {
        auto {
            fp_run_power_domain_geometry_flow
            fp_apply_pd_macro_guard
            place_design -concurrent_macros
            place_macro_detail
            fp_enforce_auto_macro_spacing
            fp_remove_inner_pd_blockages_after_macro
        }
        gui {
            fp_run_power_domain_geometry_flow
            fp_apply_pd_macro_guard
            fp_run_gui_manual_macro_stage
        }
        default {
            error "Manual-PD restore continuation is valid only for FLOORPLAN_MODE auto/gui; current mode=$floorplan_mode"
        }
    }

    fp_run_post_macro_floorplan
}

proc fp_run_floorplan_mode_and_tail {} {
    set floorplan_mode [string tolower $::FLOORPLAN_MODE]
    puts "INFO: FLOORPLAN_MODE = $floorplan_mode"

    switch -- $floorplan_mode {
        auto {
            if {[fp_mode_requires_manual_pd $floorplan_mode]} {
                fp_manual_place_power_domains \
                    $::MANUAL_POWER_DOMAIN_NAMES \
                    $::MANUAL_POWER_DOMAIN_STRICT \
                    [file join $::DB_DIR 01_20_before_manual_power_domain.enc]
            }

            fp_run_power_domain_geometry_flow
            fp_apply_pd_macro_guard
            place_design -concurrent_macros
            place_macro_detail
            fp_enforce_auto_macro_spacing
            fp_remove_inner_pd_blockages_after_macro
        }

        relative {
            uplevel #0 [list source -quiet [file join $::SCRIPT_DIR place_hard_macro.tcl]]
            fp_run_power_domain_geometry_flow
            fp_apply_pd_macro_guard
            place_design -concurrent_macros
            place_macro_detail
            fp_remove_inner_pd_blockages_after_macro
        }

        file {
            if {![file exists $::FLOORPLAN_FILE]} {
                error "Floorplan file does not exist: $::FLOORPLAN_FILE"
            }
            read_floorplan $::FLOORPLAN_FILE
            snap_floorplan -all
            if {$::CHECK_ALL_ENABLE && $::CHECK_STAGE01_FILE_FLOORPLAN_ENABLE} {
                check_floorplan -out_file [tech_mv_output_path report "01_floorplan_[clock clicks -microseconds].rpt" 01 native]
            } else {
                puts "INFO: CHECK SKIPPED: Stage01 file-mode check_floorplan (config disabled)."
            }
            fp_run_power_domain_geometry_flow
            fp_apply_pd_macro_guard
        }

        gui {
            if {[fp_mode_requires_manual_pd $floorplan_mode]} {
                fp_manual_place_power_domains \
                    $::MANUAL_POWER_DOMAIN_NAMES \
                    $::MANUAL_POWER_DOMAIN_STRICT \
                    [file join $::DB_DIR 01_20_before_manual_power_domain.enc]
            }

            fp_run_power_domain_geometry_flow
            fp_apply_pd_macro_guard
            fp_run_gui_manual_macro_stage
        }

        default {
            error "Unsupported FLOORPLAN_MODE '$::FLOORPLAN_MODE'. Use auto, relative, file, or gui."
        }
    }

    fp_run_post_macro_floorplan
}

proc fp_run_after_io {} {
    uplevel #0 [list source -quiet [file join $::SCRIPT_DIR set_macro_place_constraint.tcl]]
    uplevel #0 [list source -quiet [file join $::SCRIPT_DIR manual_place_power_domain.tcl]]
    fp_run_floorplan_mode_and_tail
}

proc fp_run_after_bond_pad_preview {} {
    # Only after FILL_IN_CELL_BOND_PAD_041/corner geometry is accepted do we freeze the IO ring and
    # fill the remaining physical gaps.
    set_db [get_db insts -if {.base_cell.base_class == pad}] .place_status fixed

    if {$::ENABLE_IO_FILLERS} {
        uplevel #0 [list source -quiet [file join $::SCRIPT_DIR add_io_fillers.tcl]]
    }

    set io_db [file join $::DB_DIR 01_10_place_io.enc]
    write_db $io_db
    puts "INFO: IO placement checkpoint DB = $io_db"

    fp_run_after_io
}

# Establish the final die/IO/core boxes before IO-pad placement.
# Establish the floorplan from the two-mode bound selector before IO placement.
#   IO_BOUND        -> -die_size <IO-min-W/H> 300 300 300 300
#   CORE_CELL_BOUND -> -core_density_size <aspect_ratio> <density> <left_margin> <bottom_margin> <right_margin> <top_margin>
# The selector uses current_design .area minus pad/ring area, and derives the
# minimum IO-ring W/H from IO_FILE order + offsets + final PAD master WIDTH.
source -quiet [file join $TOOL_DIR 01_floorplan geometry TT_proc_floorplan_bound_selector.tcl]
set ::TECH_MV_FLOORPLAN_BOUND_RESULT [TT_floorplan_bound_create $IO_FILE]

# Run the re-entrant IO placement phase once for the normal Stage-01 flow.
fp_run_io_placement_phase $IO_FILE

# FINAL PRE-FILLER PACKAGE GEOMETRY GATE.
# FILL_IN_CELL_BOND_PAD_041 is preview-only here; IO fillers have not been inserted and pads are not
# fixed yet.  While suspended, redo_IO can re-run this IO placement sub-flow
# without leaving the current native Innovus suspend prompt.
if {$ENABLE_IO_BOND_PAD_PREVIEW} {
    source -quiet [file join $TOOL_DIR 01_floorplan TT_proc_bond_pad_preview.tcl]
    TT_bond_pad_preview_checkpoint \
        "final pre-IO-filler geometry gate" \
        $IO_BOND_PAD_PREVIEW_DB_NAME \
        $IO_BOND_PAD_PREVIEW_AFTER_DB_NAME \
        $BOND_PAD_PREVIEW_SEARCH_PARITY \
        true
}

fp_run_after_bond_pad_preview
