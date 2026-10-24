# Runtime adapter preserves the historical logical source path.
if {[info exists ::TECH_MV_RUNTIME_ROOT]} {
    info script [file join $::TECH_MV_RUNTIME_ROOT run/tool/02_powerplan/TT_PR7_force_repack_unplace_center.tcl]
}
# PUBLIC_EXPORT_REVIEW_REQUIRED: residual technology candidates require manual review.
# =============================================================================
# TT_PR7_force_repack_unplace_all.tcl
# Manual PR7 gap-repack experiment for TECH_MV / Innovus 21.19 Common UI
#
# PURPOSE
#   Force place_sdps to reconsider a canonical [WT_L][CELL][WT_R] group by
#   explicitly UNPLACING all three SDP members before plain place_sdps.
#
# SAFETY / SCOPE
#   - Standalone manual tool. NOT integrated into the main flow.
#   - Touches only the selected/targeted canonical SDP group(s).
#   - Does NOT delete blockages, SDP objects, WellTaps, or any other instance.
#   - Does NOT use -keep_sdp_area.
#   - Restores place_sdp_max_move_distance after each command.
#   - If place_sdps fails for a group, attempts to restore that group's original
#     member locations and place_status values.
#   - Never intentionally throws an error to terminate the user's flow.
#
# COMMANDS
#   TT_PR7_force_repack_sdp SDP2R_00146_ROW ?move_distance?
#   TT_PR7_force_repack_selected ?move_distance?
#   TT_refine_internal_gap_sdps_unplace_all ?move_distance?
# =============================================================================

if {![info exists ::TT_PR7_FORCE_REPACK_MOVE_DISTANCE]} {
    set ::TT_PR7_FORCE_REPACK_MOVE_DISTANCE $::TECH_MV_SDP_MOVE_DEFAULTS(TT_PR7_FORCE_REPACK_MOVE_DISTANCE)
}

proc TT_PR7_FR__bbox4 {obj} {
    set b {}
    if {[catch {set b [get_db $obj .bbox]}]} { return {} }
    while {[llength $b] == 1} {
        set n [lindex $b 0]
        if {$n eq $b} { break }
        set b $n
    }
    if {[llength $b] != 4} { return {} }
    foreach v $b {
        if {![string is double -strict $v]} { return {} }
    }
    return $b
}

proc TT_PR7_FR__find_sdp {sdp_name} {
    set row_name $sdp_name
    if {![string match "*_ROW" $row_name]} {
        append row_name "_ROW"
    }
    foreach s [get_db top_sdps] {
        set n ""
        catch {set n [get_db $s .name]}
        if {$n eq $row_name} { return $s }
    }
    return ""
}

proc TT_PR7_FR__gaps {members} {
    if {[llength $members] != 3} {
        return [dict create valid false gap_l NA gap_r NA]
    }
    set lb [TT_PR7_FR__bbox4 [lindex $members 0]]
    set cb [TT_PR7_FR__bbox4 [lindex $members 1]]
    set rb [TT_PR7_FR__bbox4 [lindex $members 2]]
    if {[llength $lb] != 4 || [llength $cb] != 4 || [llength $rb] != 4} {
        return [dict create valid false gap_l NA gap_r NA]
    }
    set gap_l [expr {[lindex $cb 0] - [lindex $lb 2]}]
    set gap_r [expr {[lindex $rb 0] - [lindex $cb 2]}]
    return [dict create valid true gap_l $gap_l gap_r $gap_r]
}

proc TT_PR7_FR__snapshot {members} {
    set snap {}
    foreach obj $members {
        set name ""
        set status ""
        set loc {}
        set orient ""
        catch {set name   [get_db $obj .name]}
        catch {set status [get_db $obj .place_status]}
        catch {set loc    [get_db $obj .location]}
        catch {set orient [get_db $obj .orient]}
        lappend snap [dict create obj $obj name $name status $status location $loc orient $orient]
    }
    return $snap
}

proc TT_PR7_FR__restore_snapshot {snap} {
    set fail 0
    foreach rec $snap {
        set obj    [dict get $rec obj]
        set name   [dict get $rec name]
        set status [dict get $rec status]
        set loc    [dict get $rec location]
        set orient [dict get $rec orient]

        # Make the instance movable before restoring geometry.
        catch {set_db $obj .place_status placed}

        if {[llength $loc] == 2} {
            if {[catch {set_db $obj .location $loc} e]} {
                puts "WARN: restore location failed for $name: $e"
                incr fail
            }
        }
        if {$orient ne ""} {
            catch {set_db $obj .orient $orient}
        }

        if {$status ne ""} {
            if {[catch {set_db $obj .place_status $status} e]} {
                puts "WARN: restore status failed for $name: $e"
                incr fail
            }
        }
    }
    return $fail
}

proc TT_PR7_FR__fix_members {members} {
    set failed 0
    foreach obj $members {
        set name ""
        catch {set name [get_db $obj .name]}
        if {[catch {set_db $obj .place_status fixed} e]} {
            puts "WARN: failed to FIX '$name': $e"
            incr failed
        }
    }
    return $failed
}

proc TT_PR7_force_repack_sdp {sdp_name {move_distance ""} {run_verify true}} {
    if {$move_distance eq ""} {
        set move_distance $::TT_PR7_FORCE_REPACK_MOVE_DISTANCE
    }
    if {![string is double -strict $move_distance] || $move_distance <= 0.0} {
        puts "WARN: move_distance must be > 0; got '$move_distance'. No design change made."
        return [dict create success false reason bad_move_distance]
    }
    if {[llength [info commands place_sdps]] == 0} {
        puts "WARN: place_sdps is unavailable. No design change made."
        return [dict create success false reason no_place_sdps]
    }

    set s [TT_PR7_FR__find_sdp $sdp_name]
    if {$s eq ""} {
        puts "WARN: cannot find SDP '$sdp_name'. No design change made."
        return [dict create success false reason sdp_not_found]
    }

    set row_name [get_db $s .name]
    set members [get_db $s .insts]
    if {[llength $members] != 3} {
        puts "WARN: $row_name has [llength $members] member(s), expected exactly 3. No design change made."
        return [dict create success false reason member_count]
    }

    set wt_l [lindex $members 0]
    set cell [lindex $members 1]
    set wt_r [lindex $members 2]

    set before_gap [TT_PR7_FR__gaps $members]
    set snap [TT_PR7_FR__snapshot $members]

    puts ""
    puts "======================================================================"
    puts " PR7 FORCE REPACK - UNPLACE ALL 3 MEMBERS FIRST"
    puts "======================================================================"
    puts "SDP            : $row_name"
    puts "WT_L           : [get_db $wt_l .name]"
    puts "CENTER CELL    : [get_db $cell .name]"
    puts "CENTER MASTER  : [get_db $cell .base_cell.name]"
    puts "WT_R           : [get_db $wt_r .name]"
    puts "Move distance  : $move_distance"
    if {[dict get $before_gap valid]} {
        puts [format "Before gap     : L=%.6f um  R=%.6f um" [dict get $before_gap gap_l] [dict get $before_gap gap_r]]
    }
    puts "Method         : release group -> ALL 3=UNPLACED -> plain place_sdps -> FIX group"
    puts "keep_sdp_area  : NOT USED"
    puts "======================================================================"

    set old_move ""
    set old_known false
    if {![catch {set old_move [get_db place_sdp_max_move_distance]}]} {
        set old_known true
    }

    set rc [catch {
        # First remove FIX/SOFT_FIXED protection from all three members.
        foreach obj $members {
            set_db $obj .place_status placed
        }

        # Key difference from the normal PR7 fill-gap helper:
        # explicitly make ALL THREE SDP members UNPLACED so place_sdps
        # must rebuild/repack the complete [WT_L][CELL][WT_R] group instead
        # of accepting the current already-legal geometry.
        foreach obj $members {
            set_db $obj .place_status unplaced
        }

        puts "INFO: member statuses immediately before place_sdps:"
        foreach obj $members {
            puts "  [get_db $obj .name]  STATUS=[get_db $obj .place_status]"
        }

        set_db place_sdp_max_move_distance $move_distance
        puts "INFO: command: place_sdps -sdps {$row_name}"
        place_sdps -sdps [list $row_name]
    } err opts]

    # Always restore global move-distance setting first.
    if {$old_known} {
        catch {set_db place_sdp_max_move_distance $old_move}
        puts "INFO: restored place_sdp_max_move_distance = $old_move"
    }

    if {$rc != 0} {
        puts "WARN: force-repack place_sdps failed: $err"
        puts "WARN: restoring original member locations/status values for $row_name."
        set rf [TT_PR7_FR__restore_snapshot $snap]
        if {$rf == 0} {
            puts "PASS: original member state restored after failed force-repack."
        } else {
            puts "WARN: restore completed with $rf warning(s); inspect this group manually."
        }
        if {$run_verify && [llength [info commands TT_PR7_verify_sdp]] > 0} {
            catch {TT_PR7_verify_sdp $row_name}
        }
        return [dict create success false reason place_sdps_failed error $err sdp $row_name]
    }

    # Success path: leave the canonical group fixed, consistent with the PR7 flow.
    set fix_fail [TT_PR7_FR__fix_members $members]
    set after_members [get_db $s .insts]
    set after_gap [TT_PR7_FR__gaps $after_members]

    puts ""
    puts "----------------------------------------------------------------------"
    if {[dict get $after_gap valid]} {
        puts [format "After gap      : L=%.6f um  R=%.6f um" [dict get $after_gap gap_l] [dict get $after_gap gap_r]]
    }
    puts "FIX failures    : $fix_fail"
    puts "======================================================================"

    if {$run_verify && [llength [info commands TT_PR7_verify_sdp]] > 0} {
        TT_PR7_verify_sdp $row_name
    } elseif {$run_verify} {
        puts "INFO: TT_PR7_verify_sdp is not loaded; geometry summary above is still valid."
    }

    return [dict create success true sdp $row_name before $before_gap after $after_gap fix_failures $fix_fail]
}

proc TT_PR7_force_repack_selected {{move_distance ""}} {
    set selected [get_db selected]
    if {[llength $selected] != 1} {
        puts "WARN: select exactly ONE member instance of the target SDP. No design change made."
        return [dict create success false reason selection_count]
    }

    set target [lindex $selected 0]
    set target_name ""
    if {[catch {set target_name [get_db $target .name]}]} {
        puts "WARN: selected object is not a usable instance. No design change made."
        return [dict create success false reason bad_selection]
    }

    set found ""
    foreach s [get_db top_sdps] {
        foreach m [get_db $s .insts] {
            if {$m eq $target} {
                set found [get_db $s .name]
                break
            }
        }
        if {$found ne ""} { break }
    }

    if {$found eq ""} {
        puts "WARN: selected instance '$target_name' is not a member of any live SDP."
        return [dict create success false reason no_sdp]
    }

    puts "INFO: selected instance belongs to $found"
    return [TT_PR7_force_repack_sdp $found $move_distance true]
}

proc TT_refine_internal_gap_sdps_unplace_all {{move_distance ""}} {
    if {$move_distance eq ""} {
        set move_distance $::TT_PR7_FORCE_REPACK_MOVE_DISTANCE
    }
    if {[llength [info commands TT_PR7_scan_internal_sdp_structure]] == 0} {
        puts "WARN: TT_PR7_scan_internal_sdp_structure is not loaded."
        puts "WARN: source run/tool/02_powerplan/TT_refine_internal_gap_sdps.tcl first."
        return [dict create success false reason pr7_checker_not_loaded]
    }

    set before [TT_PR7_scan_internal_sdp_structure true false]
    set groups [dict get $before repairable_groups]

    puts ""
    puts "======================================================================"
    puts " PR7 FORCE REPACK ALL CURRENT INTERNAL-GAP VIOLATIONS"
    puts "======================================================================"
    puts "Violations       : [dict get $before violations]"
    puts "Repairable groups: [llength $groups]"
    puts "Move distance    : $move_distance"
    puts "Special action   : WT_L + CELL + WT_R are ALL UNPLACED before each place_sdps"
    puts "======================================================================"

    if {[llength $groups] == 0} {
        TT_PR7__highlight_result $before
        return $before
    }

    set ok 0
    set failed 0
    foreach g $groups {
        set r [TT_PR7_force_repack_sdp "${g}_ROW" $move_distance false]
        if {[dict exists $r success] && [dict get $r success]} {
            incr ok
        } else {
            incr failed
        }
    }

    set after [TT_PR7_scan_internal_sdp_structure true true]
    puts "INFO: force-repack summary: attempted=[llength $groups] success=$ok failed=$failed before=[dict get $before violations] after=[dict get $after violations]"
    return $after
}

puts "INFO: Loaded TT_PR7_force_repack_unplace_all.tcl"
puts "INFO: TARGET  : TT_PR7_force_repack_sdp SDP2R_00146_ROW ?move_distance?"
puts "INFO: SELECTED: TT_PR7_force_repack_selected ?move_distance?"
puts "INFO: BATCH   : TT_refine_internal_gap_sdps_unplace_all ?move_distance?"

# Backward-compatible alias: behavior is now ALL-3 unplace, despite the old name.
proc TT_refine_internal_gap_sdps_unplace_center {{move_distance ""}} {
    puts "INFO: legacy alias called; current behavior UNPLACES ALL THREE SDP members."
    return [TT_refine_internal_gap_sdps_unplace_all $move_distance]
}
