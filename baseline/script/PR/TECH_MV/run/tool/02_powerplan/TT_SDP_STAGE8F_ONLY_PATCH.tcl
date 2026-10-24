# Runtime adapter preserves the historical logical source path.
if {[info exists ::TECH_MV_RUNTIME_ROOT]} {
    info script [file join $::TECH_MV_RUNTIME_ROOT run/tool/02_powerplan/TT_SDP_STAGE8F_ONLY_PATCH.tcl]
}
# =============================================================================
# TT_SDP_STAGE8F_ONLY_PATCH.tcl
# Definition-only Stage-8F patch for V7.28 sequential delete + immediate re-fix.
# Source is DB-non-mutating.
#
# Usage:
#   source run/tool/02_powerplan/TT_SDP_STAGE8F_ONLY_PATCH.tcl
#   TT_SDP_STAGE8F_TEST       ;# READ-ONLY
#   TT_SDP_STAGE8F_APPLY      ;# MUTATING: delete verified *_ROW shells + re-fix members
# =============================================================================

proc TT_2row_sdp__stage8f_obj_name {obj} {
    set n ""
    catch {set n [get_db $obj .name]}
    return $n
}

proc TT_2row_sdp__stage8f_same_member_set {expected live} {
    if {[llength $expected] != [llength $live]} { return false }
    set a {}
    set b {}
    foreach o $expected { lappend a [TT_2row_sdp__stage8f_obj_name $o] }
    foreach o $live     { lappend b [TT_2row_sdp__stage8f_obj_name $o] }
    return [expr {[lsort -dictionary $a] eq [lsort -dictionary $b]}]
}

proc TT_2row_sdp__stage8f_precheck {} {
    if {[llength [info commands get_db]] == 0} {
        error "V7.26 Stage-8F requires Innovus get_db."
    }

    set records [TT_2row_sdp__flat_group_records]
    if {[llength $records] == 0} {
        error "V7.26 Stage-8F precheck found no canonical flat SDP groups."
    }

    catch {array unset inst_exact}
    catch {array unset inst_leaf}
    TT_2row_sdp__build_inst_lookup inst_exact inst_leaf

    set groups 0
    set live_rows 0
    set member_match_rows 0
    set resolved_members 0
    set fixed_members 0
    set bad_location_members 0
    set first_issue ""

    foreach rec $records {
        lassign $rec group wt_l_name cell_name wt_r_name
        incr groups

        set expected_objs {}
        foreach n [list $wt_l_name $cell_name $wt_r_name] {
            set inst [TT_2row_sdp__resolve_inst $n inst_exact inst_leaf]
            if {$inst eq ""} {
                if {$first_issue eq ""} { set first_issue "missing canonical member '$n'" }
                continue
            }
            lappend expected_objs $inst
            incr resolved_members

            set st ""
            catch {set st [get_db $inst .place_status]}
            if {$st eq "fixed"} { incr fixed_members }

            set raw {}
            catch {set raw [get_db $inst .location]}
            set loc [TT_2row_sdp__normalize_xy_point $raw]
            if {[llength $loc] != 2} {
                incr bad_location_members
                if {$first_issue eq ""} { set first_issue "unreadable location for '$n': '$raw'" }
            }
        }

        set row_name "${group}_ROW"
        set hits {}
        catch {set hits [get_db top_sdps -if [format {.name == "%s"} $row_name]]}
        if {[llength $hits] != 1} {
            if {$first_issue eq ""} {
                set first_issue "live SDP row '$row_name' count=[llength $hits], expected=1"
            }
            continue
        }
        incr live_rows

        set live_members {}
        catch {set live_members [get_db [lindex $hits 0] .insts]}
        if {[llength $expected_objs] == 3 &&
            [llength $live_members] == 3 &&
            [TT_2row_sdp__stage8f_same_member_set $expected_objs $live_members]} {
            incr member_match_rows
        } elseif {$first_issue eq ""} {
            set first_issue "member mismatch in live SDP row '$row_name'"
        }
    }

    set expected_members [expr {$groups * 3}]
    set ok [expr {
        $live_rows == $groups &&
        $member_match_rows == $groups &&
        $resolved_members == $expected_members &&
        $fixed_members == $expected_members &&
        $bad_location_members == 0
    }]

    return [dict create \
        ok $ok \
        groups $groups \
        live_rows $live_rows \
        member_match_rows $member_match_rows \
        expected_members $expected_members \
        resolved_members $resolved_members \
        fixed_members $fixed_members \
        bad_location_members $bad_location_members \
        first_issue $first_issue]
}

proc TT_2row_sdp__stage8f_print_precheck {r} {
    puts ""
    puts "======================================================================"
    puts " STAGE-8F PRECHECK"
    puts "======================================================================"
    puts [format "%-10s %-30s : %d/%d" {[TOOL]} {live *_ROW shells} [dict get $r live_rows] [dict get $r groups]]
    puts [format "%-10s %-30s : %d/%d" {[CUSTOM]} {3-member row matches} [dict get $r member_match_rows] [dict get $r groups]]
    puts [format "%-10s %-30s : %d/%d" {[CUSTOM]} {fixed canonical members} [dict get $r fixed_members] [dict get $r expected_members]]
    if {[dict get $r ok]} {
        puts "RESULT    : PASS"
        puts "NEXT      : automatic Stage-8F finalization"
    } else {
        puts "RESULT    : FAIL"
        puts "FIRST     : [dict get $r first_issue]"
        puts "NEXT      : stop; do not delete SDP shells"
    }
    puts "======================================================================"
    return ""
}

# Public read-only Stage-8F probe for operator testing after a definition reload.
# It does not move/fix/delete anything and intentionally returns an empty string
# so Innovus does not echo the full result dict at the interactive prompt.
proc TT_SDP_STAGE8F_TEST {} {
    set r [TT_2row_sdp__stage8f_precheck]
    TT_2row_sdp__stage8f_print_precheck $r
    return ""
}

proc TT_2row_sdp__dissolve_flat_constraints_preserve_members {} {
    if {[llength [info commands delete_sdp_rows_blockages]] == 0} {
        error "V7.28 SDP finalization requires delete_sdp_rows_blockages."
    }

    set pre [TT_2row_sdp__stage8f_precheck]
    TT_2row_sdp__stage8f_print_precheck $pre
    if {![dict get $pre ok]} {
        error "V7.28 SDP finalization precheck FAIL: [dict get $pre first_issue]"
    }

    set records [TT_2row_sdp__flat_group_records]
    catch {array unset inst_exact}
    catch {array unset inst_leaf}
    TT_2row_sdp__build_inst_lookup inst_exact inst_leaf

    catch {array unset member_loc}
    catch {array unset member_orient}
    catch {array unset member_bbox}
    catch {array unset member_obj}
    set member_names {}
    set live_delete_names {}

    # Snapshot the exact legalized geometry before deleting any SDP shell.
    foreach rec $records {
        lassign $rec group wt_l_name cell_name wt_r_name
        set row_name "${group}_ROW"
        lappend live_delete_names $row_name

        foreach n [list $wt_l_name $cell_name $wt_r_name] {
            set inst [TT_2row_sdp__resolve_inst $n inst_exact inst_leaf]
            if {$inst eq ""} {
                error "V7.28 SDP finalization lost member '$n' after precheck."
            }
            if {[lsearch -exact $member_names $n] >= 0} { continue }

            set raw {}
            catch {set raw [get_db $inst .location]}
            set loc [TT_2row_sdp__normalize_xy_point $raw]
            if {[llength $loc] != 2} {
                error "V7.28 SDP finalization cannot normalize location for '$n': '$raw'."
            }
            set orient ""
            catch {set orient [get_db $inst .orient]}
            set bbox {}
            catch {set bbox [TT_2row_sdp__bbox4 [get_db $inst .bbox]]}
            if {[llength $bbox] != 4} {
                error "V7.28 SDP finalization cannot normalize bbox for '$n'."
            }

            set member_loc($n) $loc
            set member_orient($n) $orient
            set member_bbox($n) $bbox
            set member_obj($n) $inst
            lappend member_names $n
        }
    }

    set inst_count_before [TT_2row_sdp__live_inst_count]
    set deleted 0
    set refixed 0
    set restored 0

    # V7.28 IMPORTANT:
    # Do NOT delete all 234 rows in one command.  Innovus 21.19 can downgrade
    # all members to PLACED at once, then legally re-snap later members while
    # processing the batch.  Delete exactly ONE *_ROW at a time and immediately
    # restore/refix its three members before touching the next row.
    foreach rec $records {
        lassign $rec group wt_l_name cell_name wt_r_name
        set row_name "${group}_ROW"

        set delete_cmd [list delete_sdp_rows_blockages -sdps [list $row_name] -keep_cell_placement]
        if {[catch {uplevel #0 $delete_cmd} delete_err delete_opts]} {
            return -options $delete_opts "V7.28 sequential SDP delete failed for '$row_name': $delete_err"
        }

        set hits {}
        catch {set hits [get_db top_sdps -if [format {.name == "%s"} $row_name]]}
        if {[llength $hits] != 0} {
            error "V7.28 SDP finalization incomplete: '$row_name' still exists after delete."
        }
        incr deleted

        # -keep_cell_placement is not sufficient in a bulk delete on this DB.
        # For the just-deleted row only, immediately verify exact geometry and
        # restore it if Innovus normalized the placement origin/site.  The three
        # members are FIXED again before the next SDP row is deleted.
        foreach n [list $wt_l_name $cell_name $wt_r_name] {
            set inst $member_obj($n)

            set st ""
            catch {set st [get_db $inst .place_status]}
            if {$st eq "unplaced" || $st eq ""} {
                error "V7.28 SDP finalization unplaced member '$n' while deleting '$row_name'."
            }

            set raw {}
            catch {set raw [get_db $inst .location]}
            set loc [TT_2row_sdp__normalize_xy_point $raw]
            set orient ""
            catch {set orient [get_db $inst .orient]}
            set bbox {}
            catch {set bbox [TT_2row_sdp__bbox4 [get_db $inst .bbox]]}

            set geom_changed [expr {$loc ne $member_loc($n) ||
                                    $orient ne $member_orient($n) ||
                                    $bbox ne $member_bbox($n)}]

            if {$geom_changed} {
                # Restore exact legalized placement.  .location/.orient are
                # settable Common-UI placement attributes in this flow.
                if {[catch {
                    set_db $inst .place_status placed
                    set_db $inst .location $member_loc($n)
                    if {$member_orient($n) ne ""} {
                        set_db $inst .orient $member_orient($n)
                    }
                    set_db $inst .place_status fixed
                } restore_err]} {
                    error "V7.28 could not restore '$n' after deleting '$row_name': $restore_err"
                }
                incr restored
            } elseif {$st ne "fixed"} {
                if {[catch {set_db $inst .place_status fixed} fix_err]} {
                    error "V7.28 could not re-fix '$n' after deleting '$row_name' (status='$st'): $fix_err"
                }
                incr refixed
            }

            # Hard verification after restore/refix, before the next row delete.
            set now_st ""
            catch {set now_st [get_db $inst .place_status]}
            set now_raw {}
            catch {set now_raw [get_db $inst .location]}
            set now_loc [TT_2row_sdp__normalize_xy_point $now_raw]
            set now_orient ""
            catch {set now_orient [get_db $inst .orient]}
            set now_bbox {}
            catch {set now_bbox [TT_2row_sdp__bbox4 [get_db $inst .bbox]]}

            if {$now_st ne "fixed" ||
                $now_loc ne $member_loc($n) ||
                $now_orient ne $member_orient($n) ||
                $now_bbox ne $member_bbox($n)} {
                error "V7.28 exact-placement verify failed for '$n' after deleting '$row_name': status=$now_st loc={$now_loc} expected_loc={$member_loc($n)} orient=$now_orient expected_orient=$member_orient($n) bbox={$now_bbox} expected_bbox={$member_bbox($n)}"
            }
        }
    }

    if {$deleted != [llength $records]} {
        error "V7.28 SDP finalization count mismatch: deleted=$deleted expected=[llength $records]."
    }

    # Whole-database shell verification after all sequential deletes.
    set remaining {}
    foreach row_name $live_delete_names {
        set hits {}
        catch {set hits [get_db top_sdps -if [format {.name == "%s"} $row_name]]}
        if {[llength $hits] != 0} { lappend remaining $row_name }
    }
    if {[llength $remaining] != 0} {
        error "V7.28 SDP finalization incomplete: [llength $remaining] live *_ROW shell(s) remain, first=[lindex $remaining 0]."
    }

    set inst_count_after [TT_2row_sdp__live_inst_count]
    if {$inst_count_after != $inst_count_before} {
        error "V7.28 SDP finalization changed live instance count: before=$inst_count_before after=$inst_count_after."
    }

    puts ""
    puts "======================================================================"
    puts " STAGE-8F FINALIZATION"
    puts "======================================================================"
    puts [format "%-10s %-30s : %d" {[TOOL]} {SDP shells deleted} $deleted]
    puts [format "%-10s %-30s : %d" {[CUSTOM]} {members preserved} [llength $member_names]]
    puts [format "%-10s %-30s : %d" {[CUSTOM]} {members immediately re-fixed} $refixed]
    puts [format "%-10s %-30s : %d" {[CUSTOM]} {geometry restores} $restored]
    puts "RESULT    : PASS"
    puts "======================================================================"

    catch {
        TT_2row_sdp__diag_write "FINALIZE_SDP_V7_28_SEQUENTIAL groups=$deleted members=[llength $member_names] refixed=$refixed restored=$restored inst_before=$inst_count_before inst_after=$inst_count_after"
    }
    return $deleted
}


# Public explicit APPLY wrapper. Nothing executes automatically on source.
proc TT_SDP_STAGE8F_APPLY {} {
    set n [TT_2row_sdp__dissolve_flat_constraints_preserve_members]
    puts "NEXT      : continue the outer Stage-02 flow only after this PASS"
    return ""
}

puts "INFO: TT_SDP_STAGE8F_ONLY_PATCH V7.28 loaded (definition-only; DB untouched)."
puts "INFO: READ-ONLY test : TT_SDP_STAGE8F_TEST"
puts "INFO: APPLY          : TT_SDP_STAGE8F_APPLY"
