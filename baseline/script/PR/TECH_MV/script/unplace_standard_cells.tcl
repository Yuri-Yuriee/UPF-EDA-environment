# =============================================================================
# Strict cleanup of temporary Standard-Cell placement
# =============================================================================
# place_design -concurrent_macros may place ordinary logic cells while it
# searches for a Hard-Macro floorplan.  At this point in 01_floorplan:
#
#   * all Hard Macros have already been checked and fixed;
#   * finish_floorplan has generated the final rows and row cuts;
#   * EndCap and WellTap cells have NOT been inserted yet.
#
# Therefore every non-pad instance whose base-cell class is "core" must be
# returned to UNPLACED.  Do not preserve instances by cell-name heuristics.
# This intentionally follows the behavior of the original HDL_pr flow.

proc usc_write_residual_report {residual reason report_step} {
    if {![info exists ::REPORT_DIR]} {
        return
    }

    set safe_reason [string map {
        " " "_"
        "/" "_"
        "\\" "_"
        ":" "_"
    } $reason]

    set report_file [tech_mv_report_path $report_step "stdcell_cleanup_${safe_reason}" rpt]

    set fp [open $report_file w]
    puts $fp "Strict Standard-Cell Cleanup Report"
    puts $fp "Reason: $reason"
    puts $fp "Residual placed core instances: [llength $residual]"
    puts $fp ""

    foreach inst $residual {
        set inst_name [get_db $inst .name]
        set cell_name [get_db $inst .base_cell.name]
        set status [get_db $inst .place_status]
        puts $fp "$inst_name  $cell_name  $status"
    }

    close $fp
    puts "INFO: Standard-Cell cleanup report: $report_file"
}

proc unplace_standard_cells {{reason "floorplan cleanup"} {report_step 60}} {
    # Hard Macros are base_class == block and Pads have is_pad == true, so they
    # are not part of this collection.
    set core_insts [get_db insts -if {
        .base_cell.base_class == core &&
        .is_pad == false
    }]

    set total_count [llength $core_insts]

    if {$total_count == 0} {
        puts "INFO: No non-pad core instances found for strict cleanup ($reason)."
        return 0
    }

    set initially_placed {}
    foreach inst $core_insts {
        set status [get_db $inst .place_status]
        if {$status ne "unplaced"} {
            lappend initially_placed $inst
        }
    }

    set placed_count [llength $initially_placed]
    puts "INFO: Strict Standard-Cell cleanup ($reason)."
    puts "INFO: Non-pad core instances found : $total_count"
    puts "INFO: Currently placed/fixed       : $placed_count"
    puts "INFO: Returning ALL non-pad core instances to UNPLACED."

    # Use one direct collection assignment, matching the original HDL_pr flow.
    set_db $core_insts .place_status unplaced

    # Verify every instance after the assignment.  Do not silently continue
    # when even one core instance remains placed/fixed.
    set residual {}
    foreach inst $core_insts {
        set status [get_db $inst .place_status]
        if {$status ne "unplaced"} {
            lappend residual $inst
        }
    }

    usc_write_residual_report $residual $reason $report_step

    if {[llength $residual] > 0} {
        puts "ERROR: [llength $residual] non-pad core instance(s) remain placed after strict cleanup."

        set show_limit 50
        set shown 0
        foreach inst $residual {
            if {$shown >= $show_limit} {
                break
            }

            puts "ERROR: Residual instance: [get_db $inst .name]  cell=[get_db $inst .base_cell.name]  status=[get_db $inst .place_status]"
            incr shown
        }

        if {[llength $residual] > $show_limit} {
            puts "ERROR: Additional residual instances are listed in the cleanup report."
        }

        error "Strict Standard-Cell cleanup failed."
    }

    puts "PASS: All $total_count non-pad core instances are UNPLACED ($reason)."
    return $placed_count
}
