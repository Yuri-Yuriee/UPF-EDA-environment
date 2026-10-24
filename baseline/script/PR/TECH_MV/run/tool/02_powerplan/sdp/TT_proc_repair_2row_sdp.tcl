# Runtime adapter preserves the historical logical source path.
if {[info exists ::TECH_MV_RUNTIME_ROOT]} {
    info script [file join $::TECH_MV_RUNTIME_ROOT run/tool/02_powerplan/sdp/TT_proc_repair_2row_sdp.tcl]
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
# TT_proc_repair_2row_sdp.tcl
# =============================================================================
# PR6 V5.4 — Manual 2-row SDP overlap repair utility
#
# IMPORTANT:
#   This tool follows the proven TECH_MV V7.6 placement sequence exactly for
#   an already-created canonical flat SDP:
#
#     existing [WT_L][2-row CELL][WT_R]
#       -> native write_db checkpoint
#       -> explicitly release ONLY the 702 SDP members FIXED -> PLACED
#       -> VERIFY 0 canonical SDP members remain FIXED
#       -> set_sdp_origin from current CELL locations
#       -> configure 2G / SW / high / pre-fixed-blockage=Y
#       -> place_sdps
#       -> validate canonical members still exist
#       -> FIX all 702 canonical SDP members
#       -> final check_sdps + check_place
#
# V5.2 deliberately DOES NOT run place_detail or perform a second origin pass.
# Those steps were not part of the proven V7.6 SDP creator flow and the
# previous V5.1 manual tool could make an already legal SDP worse.
#
# SAFETY:
#   - No WellTap creation/deletion.
#   - No LS/ISO creation/deletion.
#   - No delete_obj.
#   - No place_design.
#   - No trial-route deletion API.
#   - No power-domain / supply / strategy / net changes.
#   - Native write_db checkpoint is mandatory before mutation.
#   - If all 702 members cannot be explicitly released, STOP before place_sdps.
# =============================================================================

if {![info exists ::TT_SDP_REPAIR_SDP_FILE]} {
    set ::TT_SDP_REPAIR_SDP_FILE [tech_mv_output_path temp TT_2row_ls_iso_welltap_generated.sdp 02 sdp]
}
if {![info exists ::TT_SDP_REPAIR_WELLTAP_MASTER]} {
    set ::TT_SDP_REPAIR_WELLTAP_MASTER [::tech_mv_library_value LIB_CELL_002]
}
if {![info exists ::TT_SDP_REPAIR_CHECKPOINT_ROOT]} {
    set ::TT_SDP_REPAIR_CHECKPOINT_ROOT ./dbs/PR6_SDP_REPAIR
}

proc TT_SDP_REPAIR_help {} {
    puts ""
    puts "======================================================================"
    puts " TT_SDP_REPAIR — MANUAL 2-ROW SDP OVERLAP REPAIR V5.4"
    puts "======================================================================"
    puts "SDP file       : $::TT_SDP_REPAIR_SDP_FILE"
    puts "WellTap master : $::TT_SDP_REPAIR_WELLTAP_MASTER"
    puts ""
    puts "Preview : TT_SDP_REPAIR_preview"
    puts "Repair  : TT_SDP_REPAIR_repair"
    puts ""
    puts "V5.4 sequence:"
    puts "  1. Validate existing canonical WT_L/CELL/WT_R membership."
    puts "  2. Save native write_db checkpoint."
    puts "  3. Release ONLY canonical SDP members FIXED -> PLACED."
    puts "  4. HARD VERIFY: 0 canonical SDP members remain FIXED."
    puts "  5. Set explicit SDP origins from current CELL locations."
    puts "  6. Configure 2G / SW / high / pre-fixed-blockage=Y."
    puts "  7. Set honor_user_assign_origin=false and no-interleaving=true."
    puts "  8. Run place_sdps."
    puts "  9. Validate all canonical members remain alive."
    puts " 10. FIX all canonical members."
    puts " 11. Run final check_sdps + check_place."
    puts ""
    puts "V5.4 intentionally DOES NOT run place_detail or any WellTap delete."
    puts "======================================================================"
}

proc TT_SDP_REPAIR_require_cmds {} {
    set missing {}
    foreach cmd {get_db set_db place_sdps set_sdp_origin check_sdps check_place write_db} {
        if {[llength [info commands $cmd]] == 0} {
            lappend missing $cmd
        }
    }
    if {[llength $missing] != 0} {
        error "TT_SDP_REPAIR missing Innovus command(s): $missing"
    }
}

proc TT_SDP_REPAIR_bbox4 {v} {
    if {[llength $v] == 1} { set v [lindex $v 0] }
    if {[llength $v] != 4} { return {} }
    return $v
}

proc TT_SDP_REPAIR_point {v} {
    if {[llength $v] == 1} { set v [lindex $v 0] }
    if {[llength $v] != 2} { return {} }
    return $v
}

proc TT_SDP_REPAIR_name {inst} {
    set n ""
    catch {set n [get_db $inst .name]}
    return $n
}

proc TT_SDP_REPAIR_resolve {name} {
    set direct {}
    catch {set direct [get_db insts $name]}
    if {[llength $direct] == 1} { return [lindex $direct 0] }
    if {[llength $direct] > 1} {
        error "Ambiguous direct instance lookup: $name"
    }

    set leaf [lindex [split [string trimleft $name /] /] end]
    if {$leaf eq ""} { error "Cannot resolve empty SDP instance name: $name" }

    set hits {}
    foreach inst [get_db insts] {
        if {[TT_SDP_REPAIR_name $inst] eq $leaf} {
            lappend hits $inst
        }
    }
    if {[llength $hits] == 1} { return [lindex $hits 0] }
    if {[llength $hits] > 1} {
        error "Ambiguous leaf fallback for '$name': [llength $hits] live instances."
    }
    error "Cannot resolve SDP instance: $name"
}

proc TT_SDP_REPAIR_parse_sdp {} {
    if {![file exists $::TT_SDP_REPAIR_SDP_FILE]} {
        error "Canonical SDP file not found: $::TT_SDP_REPAIR_SDP_FILE"
    }

    set fp [open $::TT_SDP_REPAIR_SDP_FILE r]
    set groups {}
    set group ""
    set pos 0
    set role_map {}

    while {[gets $fp line] >= 0} {
        set line [string trim $line]
        if {[regexp {^datapath[ \t]+([^ \t\{]+)} $line -> g]} {
            set group $g
            set pos 0
            continue
        }
        if {![regexp {^inst[ \t]+(.+)$} $line -> inst_name]} {
            continue
        }
        set inst_name [string trim $inst_name]
        if {$pos == 0} {
            set role WT_L
        } elseif {$pos == 1} {
            set role CELL
        } elseif {$pos == 2} {
            set role WT_R
        } else {
            close $fp
            error "Malformed SDP group '$group': more than 3 instances."
        }
        dict set role_map $group $role $inst_name
        incr pos
    }
    close $fp

    foreach group [dict keys $role_map] {
        foreach role {WT_L CELL WT_R} {
            if {![dict exists $role_map $group $role]} {
                error "Malformed SDP group '$group': missing $role."
            }
        }
        lappend groups [list $group \
            [dict get $role_map $group WT_L] \
            [dict get $role_map $group CELL] \
            [dict get $role_map $group WT_R]]
    }
    return $groups
}

proc TT_SDP_REPAIR_tap_width {} {
    set b [TT_SDP_REPAIR_bbox4 [get_db base_cell:$::TT_SDP_REPAIR_WELLTAP_MASTER .bbox]]
    if {[llength $b] != 4} {
        error "Cannot read bbox of WellTap master $::TT_SDP_REPAIR_WELLTAP_MASTER"
    }
    lassign $b x1 y1 x2 y2
    set w [expr {double($x2) - double($x1)}]
    if {$w <= 0.0} { error "Invalid WellTap width: $w" }
    return $w
}

proc TT_SDP_REPAIR_validate_members {groups} {
    set cell_count 0
    set tap_count 0
    foreach rec $groups {
        lassign $rec group wt_l_name cell_name wt_r_name
        foreach item [list [list WT_L $wt_l_name] [list CELL $cell_name] [list WT_R $wt_r_name]] {
            lassign $item role name
            set inst [TT_SDP_REPAIR_resolve $name]
            if {$role eq "CELL"} {
                incr cell_count
                set master ""
                catch {set master [get_db $inst .base_cell.name]}
                if {$master eq ""} {
                    error "Cannot read base cell for $name"
                }
            } else {
                incr tap_count
                set master ""
                catch {set master [get_db $inst .base_cell.name]}
                if {$master ne $::TT_SDP_REPAIR_WELLTAP_MASTER} {
                    error "SDP $group $role '$name' has master '$master', expected '$::TT_SDP_REPAIR_WELLTAP_MASTER'."
                }
            }
        }
    }
    puts "INFO: Canonical SDP membership validated: groups=[llength $groups] cells=$cell_count taps=$tap_count"
    return [list $cell_count $tap_count]
}

proc TT_SDP_REPAIR_status_counts {groups} {
    set fixed 0
    set placed 0
    set unplaced 0
    set other 0
    foreach rec $groups {
        foreach name [lrange $rec 1 3] {
            set inst [TT_SDP_REPAIR_resolve $name]
            set st ""
            if {[catch {set st [get_db $inst .place_status]} err]} {
                error "Cannot read place_status for '$name': $err"
            }
            switch -- $st {
                fixed    { incr fixed }
                placed   { incr placed }
                unplaced { incr unplaced }
                default  { incr other }
            }
        }
    }
    return [list $fixed $placed $unplaced $other]
}

proc TT_SDP_REPAIR_print_status {groups tag} {
    lassign [TT_SDP_REPAIR_status_counts $groups] fixed placed unplaced other
    puts "INFO: SDP place_status ($tag): fixed=$fixed placed=$placed unplaced=$unplaced other=$other total=[expr {$fixed+$placed+$unplaced+$other}]"
    return [list $fixed $placed $unplaced $other]
}

proc TT_SDP_REPAIR_release_and_verify {groups} {
    set total [expr {[llength $groups] * 3}]
    lassign [TT_SDP_REPAIR_status_counts $groups] before_fixed before_placed before_unplaced before_other

    puts ""
    puts "======================================================================"
    puts " TT_SDP_REPAIR EXPLICIT SDP UNFIX"
    puts "======================================================================"
    puts "Expected canonical SDP members : $total"
    puts "Before release                 : fixed=$before_fixed placed=$before_placed unplaced=$before_unplaced other=$before_other"

    if {$before_fixed != $total} {
        error "Expected all $total canonical SDP members to be FIXED before manual repair; got fixed=$before_fixed. Refusing to guess."
    }

    set changed 0
    foreach rec $groups {
        foreach name [lrange $rec 1 3] {
            set inst [TT_SDP_REPAIR_resolve $name]
            if {[catch {set_db $inst .place_status placed} err]} {
                error "Cannot explicitly release SDP member '$name' FIXED -> PLACED: $err"
            }
            incr changed
        }
    }

    lassign [TT_SDP_REPAIR_status_counts $groups] after_fixed after_placed after_unplaced after_other
    puts "After release                  : fixed=$after_fixed placed=$after_placed unplaced=$after_unplaced other=$after_other"
    puts "Released                        : $changed"

    if {$changed != $total || $after_fixed != 0 || $after_placed != $total || $after_unplaced != 0 || $after_other != 0} {
        error "SDP UNFIX verification FAILED: expected fixed=0 placed=$total unplaced=0 other=0; got fixed=$after_fixed placed=$after_placed unplaced=$after_unplaced other=$after_other. STOP before place_sdps."
    }

    puts "PASS: All $total canonical SDP members are explicitly PLACED and none remain FIXED."
    puts "======================================================================"
}

proc TT_SDP_REPAIR_reanchor {groups} {
    set tap_w [TT_SDP_REPAIR_tap_width]
    set count 0
    foreach rec $groups {
        lassign $rec group wt_l_name cell_name wt_r_name
        set cell [TT_SDP_REPAIR_resolve $cell_name]
        set raw {}
        if {[catch {set raw [get_db $cell .location]} err]} {
            error "Cannot read CELL location '$cell_name': $err"
        }
        set loc [TT_SDP_REPAIR_point $raw]
        if {[llength $loc] != 2} {
            error "Invalid CELL location for '$cell_name': $raw"
        }
        lassign $loc cx cy
        set row "${group}_ROW"
        set ox [expr {double($cx) - $tap_w}]
        set oy [expr {double($cy)}]
        if {[catch {set_sdp_origin -sdp $row -location $ox $oy} err]} {
            error "set_sdp_origin failed for $row: $err"
        }
        incr count
    }
    puts "INFO: V7.6-style re-anchor: $count SDP rows from current 2-row CELL locations (tap_width=$tap_w)."
    return $count
}

proc TT_SDP_REPAIR_configure {} {
    set_db place_sdp_flow 2G
    set_db place_sdp_legalization SW
    set_db place_sdp_legalization_effort high
    set_db place_sdp_pre_fixed_cells_blockage_direction Y

    # The canonical SDP file generated by V7.9 contains box padding.  The
    # manual repair must also prevent the legalizer from preserving an origin
    # that has become illegal after surrounding placement changes.
    if {[catch {set_db place_sdp_honor_user_assign_origin false} err]} {
        puts "WARN: Cannot set place_sdp_honor_user_assign_origin=false: $err"
    }
    if {[catch {set_db place_sdp_enforce_no_interleaving_sdp true} err]} {
        puts "WARN: place_sdp_enforce_no_interleaving_sdp unavailable: $err"
    } else {
        puts "INFO: SDP no-interleaving enforcement = true"
    }
    puts "INFO: V5.4 SDP legalizer configured: 2G / SW / high / pre-fixed-blockage=Y / honor-origin=false / no-interleaving=true"
}


proc TT_SDP_REPAIR_report_settings {} {
    puts ""
    puts "======================================================================"
    puts " TT_SDP_REPAIR — NATIVE SDP LEGALIZER SETTINGS"
    puts "======================================================================"
    foreach attr {
        place_sdp_flow
        place_sdp_legalization
        place_sdp_legalization_effort
        place_sdp_pre_fixed_cells_blockage_direction
        place_sdp_honor_user_assign_origin
        place_sdp_enforce_no_interleaving_sdp
        place_sdp_max_move_distance
    } {
        set v "<unavailable>"
        catch {set v [get_db $attr]}
        puts [format "%-45s : %s" $attr $v]
    }
    puts "======================================================================"
}

proc TT_SDP_REPAIR_fix_and_verify {groups} {
    set total [expr {[llength $groups] * 3}]
    set fixed 0
    foreach rec $groups {
        foreach name [lrange $rec 1 3] {
            set inst [TT_SDP_REPAIR_resolve $name]
            if {[catch {set_db $inst .place_status fixed} err]} {
                error "Cannot set SDP member '$name' back to FIXED: $err"
            }
            incr fixed
        }
    }

    lassign [TT_SDP_REPAIR_status_counts $groups] after_fixed after_placed after_unplaced after_other
    puts "INFO: Final SDP status: fixed=$after_fixed placed=$after_placed unplaced=$after_unplaced other=$after_other"
    if {$fixed != $total || $after_fixed != $total || $after_placed != 0 || $after_unplaced != 0 || $after_other != 0} {
        error "Final SDP FIX verification FAILED: expected fixed=$total placed=0 unplaced=0 other=0; got fixed=$after_fixed placed=$after_placed unplaced=$after_unplaced other=$after_other."
    }
    puts "PASS: All $total canonical SDP members are FIXED after V7.6-style repair."
}

proc TT_SDP_REPAIR_run_checks {tag} {
    puts ""
    puts "======================================================================"
    puts " TT_SDP_REPAIR CHECK — $tag"
    puts "======================================================================"
    puts "INFO: check_sdps"
    check_sdps -out_file [tech_mv_native_sdp_report_path]
    puts "INFO: check_place"
    check_place
    puts "======================================================================"
}

proc TT_SDP_REPAIR_preview {} {
    TT_SDP_REPAIR_require_cmds
    set groups [TT_SDP_REPAIR_parse_sdp]
    TT_SDP_REPAIR_validate_members $groups
    TT_SDP_REPAIR_print_status $groups PREVIEW
    puts "INFO: Preview only — no DB mutation performed."
    TT_SDP_REPAIR_run_checks PREVIEW
    return [llength $groups]
}

proc TT_SDP_REPAIR_repair {} {
    TT_SDP_REPAIR_require_cmds
    set groups [TT_SDP_REPAIR_parse_sdp]
    if {[llength $groups] == 0} { error "Canonical SDP file contains no groups." }
    TT_SDP_REPAIR_validate_members $groups

    file mkdir $::TT_SDP_REPAIR_CHECKPOINT_ROOT
    set stamp [clock format [clock seconds] -format %Y%m%d_%H%M%S]
    set ckpt [file join $::TT_SDP_REPAIR_CHECKPOINT_ROOT "before_repair_${stamp}"]

    puts ""
    puts "======================================================================"
    puts " TT_SDP_REPAIR — MANUAL OVERLAP REPAIR V5.4"
    puts "======================================================================"
    puts "Canonical SDP groups : [llength $groups]"
    puts "Canonical members    : [expr {[llength $groups] * 3}]"
    puts "Checkpoint           : $ckpt"
    puts "Reference flow       : TECH_MV V7.6 exact placement sequence"
    puts "======================================================================"

    if {[catch {write_db $ckpt} err]} {
        error "Safety checkpoint failed; no SDP mutation was started: $err"
    }
    if {![file exists $ckpt]} {
        error "write_db returned without creating checkpoint '$ckpt'"
    }
    puts "PASS: Native checkpoint saved."
    puts "RESTORE IF NEEDED: read_db $ckpt"

    # The explicit unfix is a hard gate.  Do not call place_sdps unless all
    # 702 canonical members are proven PLACED in the live DB.
    TT_SDP_REPAIR_release_and_verify $groups
    TT_SDP_REPAIR_reanchor $groups
    TT_SDP_REPAIR_configure
    TT_SDP_REPAIR_report_settings

    puts "INFO: V7.6 Pass — place_sdps only (NO place_detail)."
    place_sdps

    TT_SDP_REPAIR_validate_members $groups
    TT_SDP_REPAIR_print_status $groups AFTER_PLACE_SDPS

    # Do not run place_detail here.  V7.6 creator flow goes directly from
    # place_sdps to fixing the canonical SDP members.
    TT_SDP_REPAIR_fix_and_verify $groups
    TT_SDP_REPAIR_run_checks FINAL

    puts ""
    puts "======================================================================"
    puts " TT_SDP_REPAIR COMPLETE — V5.4 / V7.9-compatible"
    puts "======================================================================"
    puts "Canonical SDP groups : [llength $groups]"
    puts "Canonical members    : [expr {[llength $groups] * 3}]"
    puts "WellTaps touched     : 0 created / 0 deleted"
    puts "place_detail         : NOT RUN"
    puts "Restore checkpoint   : $ckpt"
    puts "======================================================================"
    return $ckpt
}

TT_SDP_REPAIR_help
