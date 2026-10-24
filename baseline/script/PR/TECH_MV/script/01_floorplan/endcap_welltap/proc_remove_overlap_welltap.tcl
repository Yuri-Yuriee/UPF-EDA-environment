# Runtime adapter preserves the historical logical source path.
if {[info exists ::TECH_MV_RUNTIME_ROOT]} {
    info script [file join $::TECH_MV_RUNTIME_ROOT run/tool/01_floorplan/endcap_welltap/TT_proc_remove_overlap_welltap.tcl]
} else {
    info script [file normalize [file join [file dirname [info script]] .. .. .. run/tool/01_floorplan/endcap_welltap/TT_proc_remove_overlap_welltap.tcl]]
}
# Load definitions only; no APR action or setup reload is performed here.
if {![llength [info commands ::tech_mv_library_value]]} {
    if {[info exists ::TOOL_DIR]} {
        source -quiet [file join $::TECH_MV_RUNTIME_ROOT .. script PR TECH_MV script 00_common private_parameter_config.tcl]
    } else {
        source -quiet [file join $::TECH_MV_RUNTIME_ROOT .. script PR TECH_MV script 00_common private_parameter_config.tcl]
    }
}
# PUBLIC_EXPORT_REVIEW_REQUIRED: residual technology candidates require manual review.
# =============================================================================
# TT_proc_remove_overlap_welltap.tcl
# =============================================================================
# Purpose:
#   Remove WellTap instances that are explicitly referenced by Innovus
#   check_place SPOverlapViolation markers.
#
# Safety policy:
#   - Source-time is definition-only. No DB modification when sourced.
#   - Marker must satisfy ALL:
#       .type       == place
#       .subtype    == SPOverlapViolation
#       .originator == check_place
#   - Only marker .objects are inspected.
#   - Only instances whose .base_cell.name == configured library cell are candidates.
#   - No bbox-neighbor search is used.
#   - Candidate instances are deduplicated before deletion.
#   - Default mode is DRY-RUN.
#
# Usage:
#   source ../script/PR/TECH_MV/script/01_floorplan/endcap_welltap/proc_remove_overlap_welltap.tcl
#
#   # Safe preview only:
#   TT_remove_overlap_welltaps -dry_run
#
#   # Actually delete overlap WellTaps:
#   TT_remove_overlap_welltaps -apply
#
#   # Print every candidate:
#   TT_remove_overlap_welltaps -dry_run -verbose
#
#   # Apply without the final check_place/re-scan:
#   TT_remove_overlap_welltaps -apply -no_recheck
# =============================================================================

proc tt_owt_get {obj attr {default ""}} {
    set value $default
    catch {set value [get_db $obj $attr]}
    return $value
}

proc tt_owt_collect_overlap_markers {} {
    set result {}

    foreach m [get_db markers] {
        set type       [tt_owt_get $m .type ""]
        set subtype    [tt_owt_get $m .subtype ""]
        set originator [tt_owt_get $m .originator ""]

        if {$type eq "place" &&
            $subtype eq "SPOverlapViolation" &&
            $originator eq "check_place"} {
            lappend result $m
        }
    }

    return $result
}

proc tt_owt_collect_overlap_welltaps {markers tap_master} {
    # Dict keyed by instance name:
    #   name -> {pointer marker_count first_marker first_marker_bbox inst_bbox}
    set taps [dict create]

    foreach m $markers {
        set marker_bbox [tt_owt_get $m .bbox ""]
        set objects [tt_owt_get $m .objects {}]

        foreach obj $objects {
            set base [tt_owt_get $obj .base_cell.name ""]
            if {$base ne $tap_master} {
                continue
            }

            set name [tt_owt_get $obj .name ""]
            if {$name eq ""} {
                continue
            }

            if {[dict exists $taps $name]} {
                set rec [dict get $taps $name]
                dict set rec marker_count [expr {[dict get $rec marker_count] + 1}]
                dict set taps $name $rec
            } else {
                dict set taps $name [dict create \
                    pointer          $obj \
                    marker_count     1 \
                    first_marker     $m \
                    first_marker_bbox $marker_bbox \
                    inst_bbox        [tt_owt_get $obj .bbox ""] \
                ]
            }
        }
    }

    return $taps
}

proc tt_owt_name_class {name} {
    if {[string match "*PD_BWT_*" $name]} {
        return PD_BOUNDARY
    }
    if {[string match "*WELLTAP_PD_*" $name]} {
        return NORMAL_PD
    }
    return OTHER_TAPCELL
}

proc tt_owt_print_summary {label markers taps} {
    set n_boundary 0
    set n_normal   0
    set n_other    0
    set total_marker_refs 0

    dict for {name rec} $taps {
        incr total_marker_refs [dict get $rec marker_count]

        switch -- [tt_owt_name_class $name] {
            PD_BOUNDARY  { incr n_boundary }
            NORMAL_PD    { incr n_normal }
            default      { incr n_other }
        }
    }

    puts ""
    puts "======================================================================"
    puts " $label"
    puts "======================================================================"
    puts "SPOverlapViolation markers : [llength $markers]"
    puts "Unique overlap WellTaps    : [dict size $taps]"
    puts "  PD_BWT_*                 : $n_boundary"
    puts "  WELLTAP_PD_*             : $n_normal"
    puts "  Other [::tech_mv_library_value LIB_DIAGNOSTIC_ID_12]    : $n_other"
    puts "Marker references to taps  : $total_marker_refs"
    puts "======================================================================"
}

proc tt_owt_help {} {
    puts "======================================================================"
    puts " TT_remove_overlap_welltaps"
    puts "======================================================================"
    puts "Usage:"
    puts "  TT_remove_overlap_welltaps -dry_run"
    puts "  TT_remove_overlap_welltaps -apply"
    puts ""
    puts "Options:"
    puts "  -dry_run     Preview only. Default."
    puts "  -apply       Delete candidate WellTap instances."
    puts "  -verbose     Print every candidate instance and bbox."
    puts "  -no_check    Do not run check_place before collecting markers."
    puts "  -no_recheck  Do not run check_place/re-scan after deletion."
    puts "  -help        Show this help."
    puts ""
    puts "Deletion criteria:"
    puts "  marker.type       == place"
    puts "  marker.subtype    == SPOverlapViolation"
    puts "  marker.originator == check_place"
    puts "  marker.objects[*].base_cell.name == [::tech_mv_library_value LIB_DIAGNOSTIC_ID_13]"
    puts "======================================================================"
}

proc TT_remove_overlap_welltaps {args} {
    set apply 0
    set verbose 0
    set run_check 1
    set run_recheck 1

    foreach arg $args {
        switch -- $arg {
            -dry_run {
                set apply 0
            }
            -apply {
                set apply 1
            }
            -verbose {
                set verbose 1
            }
            -no_check {
                set run_check 0
            }
            -no_recheck {
                set run_recheck 0
            }
            -help {
                tt_owt_help
                return
            }
            default {
                error "Unknown option '$arg'. Use: TT_remove_overlap_welltaps -help"
            }
        }
    }

    set tap_master [::tech_mv_library_value LIB_CELL_002]

    puts ""
    puts "======================================================================"
    puts " TT REMOVE OVERLAP WELLTAPS"
    puts "======================================================================"
    puts "Mode       : [expr {$apply ? "APPLY" : "DRY-RUN"}]"
    puts "Tap master : $tap_master"
    puts "======================================================================"

    # -------------------------------------------------------------------------
    # Refresh placement markers first unless explicitly disabled.
    # -------------------------------------------------------------------------
    if {$run_check} {
        puts "INFO: Running check_place before collecting overlap markers..."
        if {[llength [info commands check_place]] > 0} {
            check_place
        } elseif {[llength [info commands checkPlace]] > 0} {
            checkPlace
        } else {
            error "Neither check_place nor checkPlace is available."
        }
    }

    set markers [tt_owt_collect_overlap_markers]
    set taps [tt_owt_collect_overlap_welltaps $markers $tap_master]

    tt_owt_print_summary "OVERLAP WELLTAP SCAN - BEFORE" $markers $taps

    if {$verbose} {
        puts ""
        puts "Candidate WellTaps:"
        puts "----------------------------------------------------------------------"

        dict for {name rec} $taps {
            puts "NAME         : $name"
            puts "CLASS        : [tt_owt_name_class $name]"
            puts "MASTER       : $tap_master"
            puts "INST BBOX    : [dict get $rec inst_bbox]"
            puts "MARKER COUNT : [dict get $rec marker_count]"
            puts "FIRST MARKER : [dict get $rec first_marker]"
            puts "MARKER BBOX  : [dict get $rec first_marker_bbox]"
            puts "----------------------------------------------------------------------"
        }
    }

    if {!$apply} {
        puts ""
        puts "DRY-RUN: No instances were deleted."
        puts "Run the following only after reviewing the summary:"
        puts "  TT_remove_overlap_welltaps -apply"
        return [dict create \
            mode dry_run \
            marker_count [llength $markers] \
            candidate_count [dict size $taps] \
            deleted_count 0]
    }

    # -------------------------------------------------------------------------
    # Delete unique overlap WellTaps only.
    # delete_inst accepts instance NAME, not DB pointer.
    # -------------------------------------------------------------------------
    set deleted 0
    set failed 0

    puts ""
    puts "INFO: Deleting [dict size $taps] unique overlap WellTap candidate(s)..."

    dict for {name rec} $taps {
        set obj [dict get $rec pointer]

        # Revalidate the live DB pointer immediately before deletion.
        set live_base [tt_owt_get $obj .base_cell.name ""]
        set live_name [tt_owt_get $obj .name ""]

        if {$live_base ne $tap_master || $live_name eq ""} {
            incr failed
            puts "WARNING: Skip stale/non-WellTap candidate: $name"
            continue
        }

        if {[catch {
            delete_inst -inst $live_name
        } err]} {
            incr failed
            puts "WARNING: delete_inst failed: name=$live_name error={$err}"
            continue
        }

        incr deleted
        if {$verbose} {
            puts "DELETED: $live_name"
        }
    }

    puts ""
    puts "======================================================================"
    puts " DELETE RESULT"
    puts "======================================================================"
    puts "Candidates : [dict size $taps]"
    puts "Deleted    : $deleted"
    puts "Failed     : $failed"
    puts "======================================================================"

    # -------------------------------------------------------------------------
    # Final re-check.
    # -------------------------------------------------------------------------
    set remaining_markers {}
    set remaining_taps [dict create]

    if {$run_recheck} {
        puts ""
        puts "INFO: Running check_place after WellTap deletion..."

        if {[llength [info commands check_place]] > 0} {
            check_place
        } elseif {[llength [info commands checkPlace]] > 0} {
            checkPlace
        } else {
            error "Neither check_place nor checkPlace is available."
        }

        set remaining_markers [tt_owt_collect_overlap_markers]
        set remaining_taps [tt_owt_collect_overlap_welltaps \
            $remaining_markers $tap_master]

        tt_owt_print_summary \
            "OVERLAP WELLTAP SCAN - AFTER" \
            $remaining_markers \
            $remaining_taps
    } else {
        puts "INFO: Final check_place/re-scan skipped by -no_recheck."
    }

    return [dict create \
        mode apply \
        marker_count_before [llength $markers] \
        candidate_count [dict size $taps] \
        deleted_count $deleted \
        failed_count $failed \
        marker_count_after [llength $remaining_markers] \
        overlap_welltap_after [dict size $remaining_taps]]
}

puts "INFO: Loaded overlap-WellTap cleanup tool."
puts "INFO: Preview: TT_remove_overlap_welltaps -dry_run"
puts "INFO: Apply  : TT_remove_overlap_welltaps -apply"
