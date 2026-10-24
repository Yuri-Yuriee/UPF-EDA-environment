# Runtime adapter preserves the historical logical source path.
if {[info exists ::TECH_MV_RUNTIME_ROOT]} {
    info script [file join $::TECH_MV_RUNTIME_ROOT run/tool/02_powerplan/sdp/TT_PR7_manual_sdp_origin.tcl]
}
# Load private values before evaluating original parameter defaults.
if {![llength [info commands ::tech_mv_private_value]]} { source [file join $::TECH_MV_RUNTIME_ROOT .. script PR TECH_MV script 00_common private_parameter_config.tcl] }
# =============================================================================
# TT_PR7_manual_sdp_origin.tcl
# TECH_MV / Innovus 21.19 Common UI
#
# Purpose
#   Support manual GUI movement of a canonical 3-member SDP row by
#   resynchronizing ONLY the SDP origin metadata to the final physical member
#   envelope lower-left.
#
# Safety contract
#   - DOES NOT call place_sdps.
#   - DOES NOT unplace or move any instance.
#   - DOES NOT change orientation.
#   - Snapshots member location/bbox/place_status before set_sdp_origin.
#   - Restores place_status if set_sdp_origin changes only status semantics.
#   - Reports CRITICAL if any member location/bbox changes.
#   - Optional targeted check_sdps is preserved and available.
#   - Full-design check_sdps remains a separate explicit signoff command.
#
# Typical suspend-point use after manual GUI movement
#   TT_PR7_manual_sync_origin SDP2R_00068_ROW
#
# Or select any member(s) of one or more SDP groups in the GUI:
#   TT_PR7_manual_sync_selected
#
# Read-only preview:
#   TT_PR7_manual_origin_preview SDP2R_00068_ROW
#
# Multiple groups:
#   TT_PR7_manual_sync_origin_list {
#       SDP2R_00068_ROW
#       SDP2R_00073_ROW
#   }
#
# Final full native signoff remains:
#   check_sdps -out_file TT_PR7_after_manual_sync.rpt
# =============================================================================

if {![info exists ::TT_PR7_MANUAL_ORIGIN_TOL]} {
    set ::TT_PR7_MANUAL_ORIGIN_TOL [::tech_mv_private_value {run/tool/02_powerplan/TT_PR7_manual_sdp_origin.tcl::::TT_PR7_MANUAL_ORIGIN_TOL::L40}]
}

proc TT_PR7_MANUAL__unwrap {value expected} {
    set v $value
    while {[llength $v] == 1} {
        set n [lindex $v 0]
        if {$n eq $v} { break }
        set v $n
    }
    if {[llength $v] != $expected} { return {} }
    foreach x $v {
        if {![string is double -strict $x]} { return {} }
    }
    return $v
}

proc TT_PR7_MANUAL__point2 {value} {
    return [TT_PR7_MANUAL__unwrap $value 2]
}

proc TT_PR7_MANUAL__bbox4 {value} {
    return [TT_PR7_MANUAL__unwrap $value 4]
}

proc TT_PR7_MANUAL__same_point {a b {tol ""}} {
    if {$tol eq ""} { set tol $::TT_PR7_MANUAL_ORIGIN_TOL }
    set a [TT_PR7_MANUAL__point2 $a]
    set b [TT_PR7_MANUAL__point2 $b]
    if {[llength $a] != 2 || [llength $b] != 2} { return false }
    lassign $a ax ay
    lassign $b bx by
    return [expr {abs($ax-$bx) <= $tol && abs($ay-$by) <= $tol}]
}

proc TT_PR7_MANUAL__same_bbox {a b {tol ""}} {
    if {$tol eq ""} { set tol $::TT_PR7_MANUAL_ORIGIN_TOL }
    set a [TT_PR7_MANUAL__bbox4 $a]
    set b [TT_PR7_MANUAL__bbox4 $b]
    if {[llength $a] != 4 || [llength $b] != 4} { return false }
    for {set i 0} {$i < 4} {incr i} {
        if {abs([lindex $a $i]-[lindex $b $i]) > $tol} { return false }
    }
    return true
}

proc TT_PR7_MANUAL__normalize_row_name {name} {
    set n [string trim $name]
    if {$n eq ""} { return "" }
    if {[string match "*_ROW" $n]} { return $n }
    if {[string match "SDP2R_*" $n]} { return "${n}_ROW" }
    return $n
}

proc TT_PR7_MANUAL__find_sdp {row_name} {
    foreach s [get_db top_sdps] {
        set n ""
        catch {set n [get_db $s .name]}
        if {$n eq $row_name} { return $s }
    }
    return ""
}

proc TT_PR7_MANUAL__snapshot_members {members} {
    set out {}
    foreach obj $members {
        set n ""
        set loc {}
        set bbox {}
        set status ""
        catch {set n [get_db $obj .name]}
        catch {set loc [TT_PR7_MANUAL__point2 [get_db $obj .location]]}
        catch {set bbox [TT_PR7_MANUAL__bbox4 [get_db $obj .bbox]]}
        catch {set status [get_db $obj .place_status]}
        lappend out [dict create obj $obj name $n location $loc bbox $bbox status $status]
    }
    return $out
}

proc TT_PR7_MANUAL__member_envelope {members} {
    if {[llength $members] == 0} { return {} }
    set first true
    set minx 0.0
    set miny 0.0
    set maxx 0.0
    set maxy 0.0
    foreach obj $members {
        set b [TT_PR7_MANUAL__bbox4 [get_db $obj .bbox]]
        if {[llength $b] != 4} { return {} }
        lassign $b x1 y1 x2 y2
        if {$first} {
            set minx $x1
            set miny $y1
            set maxx $x2
            set maxy $y2
            set first false
        } else {
            set minx [expr {min($minx,$x1)}]
            set miny [expr {min($miny,$y1)}]
            set maxx [expr {max($maxx,$x2)}]
            set maxy [expr {max($maxy,$y2)}]
        }
    }
    if {$first} { return {} }
    return [list $minx $miny $maxx $maxy]
}

proc TT_PR7_MANUAL__inspect {sdp_name} {
    set row_name [TT_PR7_MANUAL__normalize_row_name $sdp_name]
    set sdp [TT_PR7_MANUAL__find_sdp $row_name]
    if {$sdp eq ""} {
        return [dict create ok false reason "SDP not found: $row_name" row $row_name]
    }

    if {![string match "SDP2R_*_ROW" $row_name]} {
        return [dict create ok false reason "not a canonical SDP2R row: $row_name" row $row_name sdp $sdp]
    }

    set members [get_db $sdp .insts]
    if {[llength $members] != 3} {
        return [dict create ok false reason "expected exactly 3 live SDP members; got [llength $members]" row $row_name sdp $sdp members $members]
    }

    set envelope [TT_PR7_MANUAL__member_envelope $members]
    if {[llength $envelope] != 4} {
        return [dict create ok false reason "cannot read 3-member envelope" row $row_name sdp $sdp members $members]
    }

    set origin [TT_PR7_MANUAL__point2 [get_db $sdp .location]]
    if {[llength $origin] != 2} {
        return [dict create ok false reason "cannot read SDP origin" row $row_name sdp $sdp members $members envelope $envelope]
    }

    lassign $origin sx sy
    lassign $envelope minx miny maxx maxy
    set dx [expr {$minx-$sx}]
    set dy [expr {$miny-$sy}]

    return [dict create \
        ok true \
        row $row_name \
        sdp $sdp \
        members $members \
        origin $origin \
        target_origin [list $minx $miny] \
        envelope $envelope \
        dx $dx \
        dy $dy]
}

proc TT_PR7_manual_origin_preview {sdp_name} {
    set r [TT_PR7_MANUAL__inspect $sdp_name]
    puts ""
    puts "======================================================================"
    puts " PR7 MANUAL-MOVE SDP ORIGIN PREVIEW"
    puts "======================================================================"
    if {![dict get $r ok]} {
        puts "ERROR: [dict get $r reason]"
        puts "======================================================================"
        return $r
    }

    set row [dict get $r row]
    set members [dict get $r members]
    set origin [dict get $r origin]
    set envelope [dict get $r envelope]
    set target [dict get $r target_origin]

    puts "SDP row         : $row"
    puts "Current origin  : $origin"
    puts "Member envelope : $envelope"
    puts "Target origin   : $target"
    puts [format "DELTA X          : %.6f um" [dict get $r dx]]
    puts [format "DELTA Y          : %.6f um" [dict get $r dy]]
    puts ""
    set idx 0
    foreach m $members {
        puts "MEMBER $idx"
        puts "  NAME   = [get_db $m .name]"
        puts "  STATUS = [get_db $m .place_status]"
        puts "  LOC    = [get_db $m .location]"
        puts "  BBOX   = [get_db $m .bbox]"
        incr idx
    }
    puts "======================================================================"
    return $r
}

proc TT_PR7_manual_sync_origin {sdp_name {run_targeted_check true}} {
    set tol $::TT_PR7_MANUAL_ORIGIN_TOL
    set r [TT_PR7_manual_origin_preview $sdp_name]
    if {![dict get $r ok]} { return $r }

    set row [dict get $r row]
    set sdp [dict get $r sdp]
    set members [dict get $r members]
    set target [dict get $r target_origin]
    lassign $target tx ty

    if {[llength [info commands set_sdp_origin]] == 0} {
        puts "ERROR: set_sdp_origin is unavailable; no metadata changed."
        dict set r ok false
        dict set r reason "set_sdp_origin unavailable"
        return $r
    }

    set snapshots [TT_PR7_MANUAL__snapshot_members $members]
    set old_origin [dict get $r origin]

    if {[TT_PR7_MANUAL__same_point $old_origin $target $tol]} {
        puts "INFO: $row origin already matches the physical member envelope."
        set changed false
    } else {
        puts "INFO: Synchronizing $row origin only: $old_origin -> $target"
        if {[catch {set_sdp_origin -sdp $row -location $tx $ty} err]} {
            puts "ERROR: set_sdp_origin failed for $row: $err"
            dict set r ok false
            dict set r reason $err
            return $r
        }
        set changed true
    }

    # Preserve the place-status state that existed after the user's manual move.
    set status_restore_failures 0
    foreach snap $snapshots {
        set obj [dict get $snap obj]
        set old_status [dict get $snap status]
        set new_status ""
        catch {set new_status [get_db $obj .place_status]}
        if {$old_status ne "" && $new_status ne $old_status} {
            if {[catch {set_db $obj .place_status $old_status} status_err]} {
                puts "WARN: cannot restore place_status for [dict get $snap name]: $status_err"
                incr status_restore_failures
            } else {
                puts "INFO: restored place_status [dict get $snap name]: $new_status -> $old_status"
            }
        }
    }

    # Hard safety guard: metadata sync must not move the physical members.
    set coordinate_shift false
    foreach snap $snapshots {
        set obj [dict get $snap obj]
        set n [dict get $snap name]
        set old_loc [dict get $snap location]
        set old_bbox [dict get $snap bbox]
        set new_loc [TT_PR7_MANUAL__point2 [get_db $obj .location]]
        set new_bbox [TT_PR7_MANUAL__bbox4 [get_db $obj .bbox]]

        if {![TT_PR7_MANUAL__same_point $old_loc $new_loc $tol] || ![TT_PR7_MANUAL__same_bbox $old_bbox $new_bbox $tol]} {
            puts "CRITICAL: origin synchronization changed physical coordinates: $row / $n"
            puts "          old LOC  = $old_loc"
            puts "          new LOC  = $new_loc"
            puts "          old BBOX = $old_bbox"
            puts "          new BBOX = $new_bbox"
            set coordinate_shift true
        }
    }

    set new_origin [TT_PR7_MANUAL__point2 [get_db $sdp .location]]
    set origin_ok [TT_PR7_MANUAL__same_point $new_origin $target $tol]

    puts ""
    puts "======================================================================"
    puts " PR7 MANUAL-MOVE ORIGIN SYNC RESULT"
    puts "======================================================================"
    puts "SDP row             : $row"
    puts "Changed              : $changed"
    puts "Requested origin     : $target"
    puts "Actual origin        : $new_origin"
    if {$origin_ok} { set _origin_text "PASS" } else { set _origin_text "FAIL" }
    if {$coordinate_shift} { set _coord_text "CRITICAL SHIFT" } else { set _coord_text "PASS / UNCHANGED" }
    puts "Origin verify        : $_origin_text"
    puts "Member coordinate    : $_coord_text"
    puts "Status restore errors: $status_restore_failures"
    puts "======================================================================"

    set check_ran false
    if {$run_targeted_check} {
        if {[llength [info commands check_sdps]] == 0} {
            puts "WARN: check_sdps is unavailable; targeted native check skipped."
        } else {
            set safe_name [string map {/ _ : _ \\ _} $row]
            set rpt [tech_mv_output_path report "TT_PR7_manual_${safe_name}.checkSdp.rpt" 02 sdp]
            puts "INFO: Running targeted native check_sdps for $row"
            puts "INFO: Report = $rpt"
            check_sdps -sdps [list $row] -out_file $rpt
            set check_ran true
        }
    }

    set final_ok [expr {$origin_ok && !$coordinate_shift && $status_restore_failures == 0}]
    return [dict create \
        ok $final_ok \
        row $row \
        changed $changed \
        old_origin $old_origin \
        target_origin $target \
        actual_origin $new_origin \
        coordinate_shift $coordinate_shift \
        status_restore_failures $status_restore_failures \
        targeted_check_ran $check_ran]
}

proc TT_PR7_manual_sync_origin_list {sdp_names {run_targeted_check true}} {
    set rows {}
    foreach n $sdp_names {
        set row [TT_PR7_MANUAL__normalize_row_name $n]
        if {$row ne "" && [lsearch -exact $rows $row] < 0} { lappend rows $row }
    }

    puts ""
    puts "======================================================================"
    puts " PR7 MANUAL-MOVE ORIGIN SYNC LIST"
    puts "======================================================================"
    puts "Groups: [llength $rows]"
    puts "Targeted check_sdps: $run_targeted_check"
    puts "======================================================================"

    set results {}
    set pass 0
    set fail 0
    foreach row $rows {
        set r [TT_PR7_manual_sync_origin $row $run_targeted_check]
        lappend results $r
        if {[dict exists $r ok] && [dict get $r ok]} {
            incr pass
        } else {
            incr fail
        }
    }

    puts ""
    puts "======================================================================"
    puts " PR7 MANUAL SYNC LIST SUMMARY"
    puts "======================================================================"
    puts "Groups requested : [llength $rows]"
    puts "PASS             : $pass"
    puts "FAIL/REVIEW      : $fail"
    puts "NOTE             : run full 'check_sdps' before resume/signoff"
    puts "======================================================================"

    return [dict create requested [llength $rows] pass $pass fail $fail results $results]
}

proc TT_PR7_manual_sync_selected {{run_targeted_check true}} {
    set selected ""
    catch {set selected [get_db selected]}
    if {[llength $selected] == 0} {
        puts "ERROR: Nothing is selected."
        puts "Select one or more SDP member instances, then run:"
        puts "  TT_PR7_manual_sync_selected"
        return [dict create requested 0 pass 0 fail 1 results {}]
    }

    set rows {}
    foreach obj $selected {
        set obj_type ""
        catch {set obj_type [get_db $obj .obj_type]}

        if {$obj_type eq "inst"} {
            set row ""
            catch {set row [get_db $obj .sdp.name]}
            if {$row ne "" && [string match "SDP2R_*_ROW" $row] && [lsearch -exact $rows $row] < 0} {
                lappend rows $row
            }
        } elseif {$obj_type eq "sdp" || $obj_type eq "row"} {
            set row ""
            catch {set row [get_db $obj .name]}
            if {$row ne "" && [string match "SDP2R_*_ROW" $row] && [lsearch -exact $rows $row] < 0} {
                lappend rows $row
            }
        }
    }

    if {[llength $rows] == 0} {
        puts "ERROR: Selected object(s) do not resolve to any SDP2R_*_ROW member/group."
        puts "Select WT_L, CELL, or WT_R from the manually moved SDP group."
        return [dict create requested 0 pass 0 fail 1 results {}]
    }

    puts "INFO: Selected SDP group(s): $rows"
    return [TT_PR7_manual_sync_origin_list $rows $run_targeted_check]
}

puts "INFO: Loaded PR7 manual-move SDP origin-sync tool."
puts "INFO: PREVIEW : TT_PR7_manual_origin_preview SDP2R_00068_ROW"
puts "INFO: REPAIR  : TT_PR7_manual_sync_origin SDP2R_00068_ROW"
puts "INFO: REPAIR  : TT_PR7_manual_sync_origin_list {SDP2R_00068_ROW SDP2R_00073_ROW}"
puts "INFO: GUI     : select SDP member(s), then TT_PR7_manual_sync_selected"
puts "INFO: SIGNOFF : check_sdps -out_file TT_PR7_after_manual_sync.rpt"
