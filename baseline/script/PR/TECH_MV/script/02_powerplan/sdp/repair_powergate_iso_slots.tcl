# Runtime adapter preserves the historical logical source path.
if {[info exists ::TECH_MV_RUNTIME_ROOT]} {
    info script [file join $::TECH_MV_RUNTIME_ROOT run/tool/02_powerplan/sdp/TT_repair_powergate_iso_slots.tcl]
} else {
    info script [file normalize [file join [file dirname [info script]] .. .. .. run/tool/02_powerplan/sdp/TT_repair_powergate_iso_slots.tcl]]
}
# Load private values before evaluating original parameter defaults.
if {![llength [info commands ::tech_mv_private_value]]} { source [file join $::TECH_MV_RUNTIME_ROOT .. script PR TECH_MV script 00_common private_parameter_config.tcl] }
# =============================================================================
# TT_repair_powergate_iso_slots.tcl
# TECH_MV / Innovus 21.19 Stylus / Common UI
#
# PGROW-R1/R2 dedicated repair driver.
#
# PURPOSE
#   Keep TT_refine_internal_gap_sdps focused on its original internal/native SDP
#   geometry job.  Repair Power-Gated row-rule violations with a separate driver
#   that reuses only the already-proven low-level R9 mechanics.
#
# SLOT RESERVATION POLICY
#
#     BOUNDARY_L | [WT_L][ISO_KEEP][WT_R] | BOUNDARY_R
#
#   becomes temporarily:
#
#     BOUNDARY_L |<-- HARD BLK -->|[WT_L][ISO_KEEP][WT_R]|<-- HARD BLK -->| BOUNDARY_R
#          LEFT boundary -> keeper WT_L                         keeper WT_R -> RIGHT boundary
#
#   Every already-occupied adjacent SW interval is reserved this way, even when
#   it currently has exactly one ISO.  Empty SW intervals stay open.
#
# TARGETS
#   - PGROW-R1 excess groups (all groups after deterministic keeper)
#   - PGROW-R2 ISO groups on no-SW row bands
#
# MOVEMENT METHOD
#   Same proven R9 low-level sequence, but NOT TT_refine_internal_gap_sdps:
#     1) current target center -> temporary HARD move blockage
#     2) apply temporary WT_L/CELL/WT_R padding
#     3) freeze background; release only target ISO centers
#     4) ONE batched place_detail
#     5) guarded set_sdp_origin to re-anchor WT_L/CELL/WT_R
#     6) restore exact original padding
#     7) custom GAP-only + targeted/global native + PGROW validation
#
# OWNED TEMP BLOCKAGES
#   TT_SDP_PGISO_RESERVE_*
#   TT_SDP_PGISO_MOVE_*
#
# They are kept through repair/checkpoint and deleted only by the final
# TT_SDP_PGROW_cleanup -> TT_SDP_PGISO_cleanup handoff.
#
# Source behavior: definition-only.
# =============================================================================

set ::TT_SDP_PGISO_VERSION "V1.5_BOUNDARY_SLOT_NATIVE_FIRST_ONE_PASS"
if {![info exists ::TT_SDP_PGISO_RESERVE_PREFIX]} { set ::TT_SDP_PGISO_RESERVE_PREFIX "TT_SDP_PGISO_RESERVE_" }
if {![info exists ::TT_SDP_PGISO_MOVE_PREFIX]} { set ::TT_SDP_PGISO_MOVE_PREFIX "TT_SDP_PGISO_MOVE_" }
if {![info exists ::TT_SDP_PGISO_TOL]} { set ::TT_SDP_PGISO_TOL [::tech_mv_private_value {run/tool/02_powerplan/TT_repair_powergate_iso_slots.tcl::::TT_SDP_PGISO_TOL::L51}] }
if {![info exists ::TT_SDP_PGISO_TARGET_NATIVE_LIMIT]} { set ::TT_SDP_PGISO_TARGET_NATIVE_LIMIT 10 }
if {![info exists ::TT_SDP_PGISO_ONE_PLACE_DETAIL_PER_RUN]} { set ::TT_SDP_PGISO_ONE_PLACE_DETAIL_PER_RUN 1 }

proc TT_SDP_PGISO__sanitize {v} {
    regsub -all {[^A-Za-z0-9_]} $v "_" out
    return $out
}

proc TT_SDP_PGISO__owned {{which all}} {
    set out {}
    foreach pb [get_db place_blockages] {
        set n ""
        catch {set n [get_db $pb .name]}
        if {$n eq ""} { continue }
        set hit 0
        if {$which eq "all" || $which eq "reserve"} {
            if {[string match "${::TT_SDP_PGISO_RESERVE_PREFIX}*" $n]} { set hit 1 }
        }
        if {$which eq "all" || $which eq "move"} {
            if {[string match "${::TT_SDP_PGISO_MOVE_PREFIX}*" $n]} { set hit 1 }
        }
        if {$hit} { lappend out $pb }
    }
    return $out
}

proc TT_SDP_PGISO__delete_owned {{which all}} {
    set deleted 0
    set failed {}
    foreach pb [TT_SDP_PGISO__owned $which] {
        set n ""
        catch {set n [get_db $pb .name]}
        if {[catch {delete_obj $pb} err]} {
            lappend failed [list $n $err]
        } else {
            incr deleted
        }
    }
    return [dict create deleted $deleted failed $failed remaining [llength [TT_SDP_PGISO__owned $which]]]
}

proc TT_SDP_PGISO_cleanup {} {
    set r [TT_SDP_PGISO__delete_owned all]
    set ok [expr {[llength [dict get $r failed]] == 0 && [dict get $r remaining] == 0}]
    puts "INFO: TT_SDP_PGISO final cleanup: deleted=[dict get $r deleted] failed=[llength [dict get $r failed]] remaining=[dict get $r remaining]"
    dict set r ok $ok
    return $r
}

proc TT_SDP_PGISO__create_hard {name bbox} {
    if {[llength $bbox] != 4} { error "invalid blockage bbox for $name: {$bbox}" }
    lassign $bbox x1 y1 x2 y2
    if {double($x2) <= double($x1)+$::TT_SDP_PGISO_TOL ||
        double($y2) <= double($y1)+$::TT_SDP_PGISO_TOL} {
        return ""
    }

    set old {}
    catch {set old [get_db place_blockages $name]}
    if {[llength $old] != 0} {
        error "PGISO owned blockage name already exists: $name"
    }

    set rc [catch {
        create_place_blockage -name $name -type hard -rects [list $bbox]
    } err]
    if {$rc != 0} {
        puts "WARN: PGISO create_place_blockage -type hard failed for '$name': $err"
        create_place_blockage -name $name -rects [list $bbox]
    }

    set live {}
    catch {set live [get_db place_blockages $name]}
    if {[llength $live] == 0} { error "PGISO blockage '$name' was not created" }

    set typ ""
    catch {set typ [get_db [lindex $live 0] .type]}
    if {$typ ne "" && $typ ne "hard"} {
        catch {delete_obj $live}
        error "PGISO blockage '$name' type='$typ', expected hard"
    }
    return [lindex $live 0]
}

proc TT_SDP_PGISO__row_y {row_key} {
    set p [split $row_key ":"]
    if {[llength $p] != 2} { return "" }
    set y1 [lindex $p 0]
    set y2 [lindex $p 1]
    if {![string is double -strict $y1] || ![string is double -strict $y2]} { return "" }
    return [list $y1 $y2]
}

# Build reserve BLKs for EVERY currently occupied bounded 2-row slot.
proc TT_SDP_PGISO_prepare_reservations {scan_result} {
    if {![dict exists $scan_result occupied_intervals]} {
        error "PGISO scan_result has no occupied_intervals; TT_SDP_PGROW_scan V1.4+ is required"
    }

    # Reservations follow live keeper geometry, so rebuild only THIS owned family.
    set old [TT_SDP_PGISO__delete_owned reserve]
    if {[llength [dict get $old failed]] != 0} {
        error "PGISO could not clear stale reservation blockage(s): [dict get $old failed]"
    }

    set created 0
    set skipped 0
    set idx 0
    foreach rec [dict get $scan_result occupied_intervals] {
        incr idx
        lassign $rec ikey pd row_key left_sw right_sw left_sw_x2 right_sw_x1 keeper all_groups

        if {$keeper eq ""} {
            puts "INFO: PGISO RESERVE skip interval={$ikey}: no global keeper; interval remains OPEN"
            incr skipped
            continue
        }

        set info [TT_PR7__resolve_group_triplet $keeper]
        if {![dict get $info ok]} {
            puts "WARN: PGISO reservation skip interval={$ikey}: keeper=$keeper resolve failed: [dict get $info reason]"
            incr skipped
            continue
        }

        set wl [dict get $info wt_l]
        set wr [dict get $info wt_r]
        set wlb [TT_PR7__rect $wl]
        set wrb [TT_PR7__rect $wr]
        set yy [TT_SDP_PGISO__row_y $row_key]
        if {[llength $wlb] != 4 || [llength $wrb] != 4 || [llength $yy] != 2} {
            puts "WARN: PGISO reservation skip interval={$ikey}: invalid keeper WT/row geometry"
            incr skipped
            continue
        }

        lassign $wlb wlx1 wly1 wlx2 wly2
        lassign $wrb wrx1 wry1 wrx2 wry2
        lassign $yy y1 y2

        # The exact requested policy:
        #   left SW right edge -> keeper left WellTap left edge
        #   keeper right WellTap right edge -> right SW left edge
        set left_box  [list $left_sw_x2  $y1 $wlx1 $y2]
        set right_box [list $wrx2 $y1 $right_sw_x1 $y2]

        set stem "${::TT_SDP_PGISO_RESERVE_PREFIX}[format %05d $idx]"
        if {[expr {double($wlx1) > double($left_sw_x2)+$::TT_SDP_PGISO_TOL}]} {
            TT_SDP_PGISO__create_hard "${stem}_L" $left_box
            incr created
        }
        if {[expr {double($right_sw_x1) > double($wrx2)+$::TT_SDP_PGISO_TOL}]} {
            TT_SDP_PGISO__create_hard "${stem}_R" $right_box
            incr created
        }

        puts "INFO: PGISO RESERVE interval={$ikey} keeper=$keeper groups={$all_groups}"
        puts "INFO:   LEFT  BOUNDARY=$left_sw -> WT_L=[get_db $wl .name] bbox={$left_box}"
        puts "INFO:   RIGHT WT_R=[get_db $wr .name] -> BOUNDARY=$right_sw bbox={$right_box}"
    }

    puts "INFO: PGISO occupied-slot reservation: intervals=[llength [dict get $scan_result occupied_intervals]] HARD_BLKs=$created skipped=$skipped"
    return [dict create created $created skipped $skipped]
}

proc TT_SDP_PGISO__move_name {group round} {
    return "${::TT_SDP_PGISO_MOVE_PREFIX}[TT_SDP_PGISO__sanitize $group]_R${round}"
}

proc TT_SDP_PGISO__delete_move_for_group {group} {
    set pat "${::TT_SDP_PGISO_MOVE_PREFIX}[TT_SDP_PGISO__sanitize $group]_R*"
    set deleted 0
    foreach pb [get_db place_blockages] {
        set n ""
        catch {set n [get_db $pb .name]}
        if {$n ne "" && [string match $pat $n]} {
            delete_obj $pb
            incr deleted
        }
    }
    return $deleted
}

proc TT_SDP_PGISO__dependencies {} {
    set req {
        TT_SDP_PGROW_scan
        TT_SDP_PGROW_group_legal
        TT_PR7__resolve_group_triplet
        TT_PR7__gapblk_geometry
        TT_PR7__triplet_padding_snapshot
        TT_PR7__apply_temp_triplet_padding
        TT_PR7__restore_triplet_padding
        TT_PR7__freeze_for_detail
        TT_PR7__restore_after_detail
        TT_PR7__point2
        TT_PR7__rect
        TT_PR7__same_point
        TT_PR7__same_bbox
        TT_PR7_scan_internal_sdp_structure
        TT_PR7__target_native_check
    }
    set missing {}
    foreach c $req {
        if {[llength [info commands $c]] == 0} { lappend missing $c }
    }
    foreach c {place_detail set_sdp_origin create_place_blockage check_sdps} {
        if {[llength [info commands $c]] == 0} { lappend missing $c }
    }
    return $missing
}


# Explicitly FIX every globally selected keeper BEFORE any mover is released.
# A group can never appear in both lists; fail closed if classification is bad.
proc TT_SDP_PGISO__fix_global_keepers {scan_result} {
    set keepers {}
    set movers {}
    if {[dict exists $scan_result keeper_groups]} { set keepers [dict get $scan_result keeper_groups] }
    if {[dict exists $scan_result mover_groups]} { set movers [dict get $scan_result mover_groups] }

    foreach g $keepers {
        if {[lsearch -exact $movers $g] >= 0} {
            error "PGISO global role error: group '$g' is both KEEP and MOVE"
        }
    }

    set fixed_groups 0
    set fixed_members 0
    foreach g $keepers {
        set info [TT_PR7__resolve_group_triplet $g]
        if {![dict get $info ok]} {
            error "PGISO cannot FIX global keeper '$g': [dict get $info reason]"
        }
        foreach key {wt_l cell wt_r} {
            set obj [dict get $info $key]
            set_db $obj .place_status fixed
            incr fixed_members
        }
        foreach key {wt_l cell wt_r} {
            set obj [dict get $info $key]
            set st ""
            catch {set st [get_db $obj .place_status]}
            if {$st ne "fixed"} {
                error "PGISO keeper FIX verify failed: group=$g key=$key status=$st"
            }
        }
        incr fixed_groups
    }
    puts "INFO: PGISO GLOBAL KEEPERS fixed before place_detail: groups=$fixed_groups members=$fixed_members"
    return [dict create groups $fixed_groups members $fixed_members]
}

# Large-batch FIX policy:
#   <= native-limit targets : preserve the old full canonical FIX+verify behavior.
#   >  native-limit targets : after each re-anchor, FIX+verify only that
#                             [WT_L][CELL][WT_R] triplet; run one full 702-member
#                             FIX+verify after the entire round.
proc TT_SDP_PGISO__fix_triplet_only {info} {
    foreach key {wt_l cell wt_r} {
        if {![dict exists $info $key]} {
            error "PGISO local FIX missing triplet key '$key'."
        }
        set obj [dict get $info $key]
        if {$obj eq ""} {
            error "PGISO local FIX unresolved triplet key '$key'."
        }
        set_db $obj .place_status fixed
    }
    foreach key {wt_l cell wt_r} {
        set obj [dict get $info $key]
        set st ""
        catch {set st [get_db $obj .place_status]}
        if {$st ne "fixed"} {
            error "PGISO local FIX verify failed: key=$key status=$st"
        }
    }
    return true
}

# Native validation policy:
#   <= ::TT_SDP_PGISO_TARGET_NATIVE_LIMIT targets:
#       keep existing per-group targeted native check_sdps.
#   > limit:
#       do NOT run per-group targeted check_sdps.  Run one global check_sdps
#       after the entire batched round, and only then release PASS move BLKs.
proc TT_SDP_PGISO__global_native_total {} {
    if {[llength [info commands TT_2row_sdp__check_sdps_total]] > 0} {
        return [TT_2row_sdp__check_sdps_total]
    }
    error "PGISO batch-native mode requires TT_2row_sdp__check_sdps_total"
}

proc TT_repair_powergate_iso_slots {{initial_result ""} {max_rounds ""}} {
    set missing [TT_SDP_PGISO__dependencies]
    if {[llength $missing] != 0} {
        error "TT_repair_powergate_iso_slots missing required command(s): {$missing}"
    }

    if {$max_rounds eq ""} {
        if {[info exists ::TT_SDP_PGROW_MAX_REPAIR_PASSES]} {
            set max_rounds $::TT_SDP_PGROW_MAX_REPAIR_PASSES
        } else {
            set max_rounds 3
        }
    }
    if {![string is integer -strict $max_rounds] || $max_rounds < 1} {
        error "TT_repair_powergate_iso_slots max_rounds must be integer >= 1"
    }
    if {$::TT_SDP_PGISO_ONE_PLACE_DETAIL_PER_RUN && $max_rounds > 1} {
        puts "INFO: PGISO global-batch policy caps this invocation to ONE place_detail pass (requested max_rounds=$max_rounds)."
        set max_rounds 1
    }

    # Always start from a clean PGISO-owned blockage state. This prevents a
    # previous unresolved/debug invocation from consuming legal empty space.
    set _stale_pgiso [TT_SDP_PGISO_cleanup]
    if {![dict get $_stale_pgiso ok]} {
        error "PGISO cannot clear stale owned blockages before repair: $_stale_pgiso"
    }
    unset _stale_pgiso

    if {$initial_result eq ""} {
        set result [TT_SDP_PGROW_scan true]
    } else {
        set result $initial_result
    }
    if {[dict get $result violations] == 0} {
        dict set result repair_rounds 0
        return $result
    }

    puts ""
    puts "======================================================================"
    puts " PGROW ISO SLOT-RESERVATION REPAIR"
    puts "======================================================================"
    puts "PGROW violations       : [dict get $result violations]"
    puts "GLOBAL KEEP groups      : [dict get $result keeper_groups]"
    puts "GLOBAL MOVE groups      : [dict get $result mover_groups]"
    puts "R2 missing-boundary groups: [dict get $result no_switch_row_groups]"
    puts "Occupied intervals     : [llength [dict get $result occupied_intervals]]"
    puts "Reservation policy     : LEFT boundary->keeper WT_L and keeper WT_R->RIGHT boundary HARD BLK"
    puts "Movement               : FIX all KEEPERS + BLK all MOVERS + ONE global place_detail"
    puts "Internal gap repair    : GAP-only TT_refine_internal_gap_sdps runs earlier; PGROW does not call it"
    puts "Max rounds             : $max_rounds"
    puts "Target native threshold: $::TT_SDP_PGISO_TARGET_NATIVE_LIMIT group(s)"
    puts "======================================================================"

    set repair_rounds 0
    set last_global_native ""

    set pad_sites 8
    if {[info exists ::TT_PR7_CELL_REANCHOR_PAD_SITES] &&
        [string is integer -strict $::TT_PR7_CELL_REANCHOR_PAD_SITES] &&
        $::TT_PR7_CELL_REANCHOR_PAD_SITES >= 0} {
        set pad_sites $::TT_PR7_CELL_REANCHOR_PAD_SITES
    }

    for {set round 1} {$round <= $max_rounds && [dict get $result violations] > 0} {incr round} {
        incr repair_rounds
        puts ""
        puts "----------------------------------------------------------------------"
        puts "PGISO ROUND $round/$max_rounds violations=[dict get $result violations]"

        # First establish one GLOBAL immutable KEEP/MOVE partition for this run.
        # Keepers are explicitly fixed BEFORE any mover is released.
        TT_SDP_PGISO__fix_global_keepers $result

        # Then reserve every interval that has a GLOBAL keeper. Intervals with no
        # global keeper remain open. This avoids reserving around a cell that the
        # same run later moves because it conflicted on another 2-row band.
        TT_SDP_PGISO_prepare_reservations $result

        set targets [dict get $result mover_groups]
        if {[llength $targets] == 0} { break }

        set target_count [llength $targets]
        set use_targeted_native [expr {$target_count <= $::TT_SDP_PGISO_TARGET_NATIVE_LIMIT}]
        if {$use_targeted_native} {
            puts "INFO: PGISO native validation mode=TARGETED target_count=$target_count threshold=$::TT_SDP_PGISO_TARGET_NATIVE_LIMIT"
        } else {
            puts "INFO: PGISO native validation mode=BATCH_GLOBAL target_count=$target_count threshold=$::TT_SDP_PGISO_TARGET_NATIVE_LIMIT"
            puts "INFO: per-group targeted check_sdps disabled for this round; one global check_sdps will run after all re-anchors."
        }

        set pending_native_pass {}
        catch {array unset original_padding}
        catch {array unset target_info}
        set round_groups {}
        set round_cells {}
        set prep_failed 0
        set prep_error ""

        foreach g $targets {
            set info [TT_PR7__resolve_group_triplet $g]
            if {![dict get $info ok]} {
                puts "WARN: PGISO skip target=$g: [dict get $info reason]"
                continue
            }
            set target_info($g) $info

            if {[catch {set original_padding($g) [TT_PR7__triplet_padding_snapshot $info]} perr]} {
                set prep_failed 1
                set prep_error "$g padding snapshot failed: $perr"
                break
            }

            set geom [TT_PR7__gapblk_geometry $g]
            if {![dict get $geom ok]} {
                set prep_failed 1
                set prep_error "$g move-block geometry failed: [dict get $geom reason]"
                break
            }

            set move_name [TT_SDP_PGISO__move_name $g $round]
            if {[catch {TT_SDP_PGISO__create_hard $move_name [dict get $geom blockage_bbox]} berr]} {
                set prep_failed 1
                set prep_error "$g move blockage failed: $berr"
                break
            }

            if {[catch {TT_PR7__apply_temp_triplet_padding $info $original_padding($g)} terr]} {
                catch {TT_PR7__restore_triplet_padding $info $original_padding($g)}
                set prep_failed 1
                set prep_error "$g temp triplet padding failed: $terr"
                break
            }

            set c [dict get $info cell]
            lappend round_groups $g
            lappend round_cells $c
            puts "PGISO GLOBAL MOVE PREP group=$g cell=[get_db $c .name] old-site-BLK=$move_name padSites=$pad_sites"
        }

        if {$prep_failed} {
            foreach g $round_groups {
                if {[info exists target_info($g)] && [info exists original_padding($g)]} {
                    catch {TT_PR7__restore_triplet_padding $target_info($g) $original_padding($g)}
                }
            }
            error "PGISO round $round preparation failed: $prep_error"
        }

        if {[llength $round_cells] == 0} {
            puts "WARN: PGISO no movable target remains in round $round."
            break
        }

        set detail_state [TT_PR7__freeze_for_detail $round_cells]
        puts "INFO: PGISO ONE GLOBAL place_detail: fixed_KEEP=[llength [dict get $result keeper_groups]] movable_MOVE=[llength $round_cells]"
        set prc [catch {place_detail} perr]
        TT_PR7__restore_after_detail $detail_state $round_cells
        if {$prc != 0} {
            foreach g $round_groups {
                catch {TT_PR7__restore_triplet_padding $target_info($g) $original_padding($g)}
            }
            error "PGISO place_detail failed: $perr"
        }

        catch {TT_2row_sdp__set_flat_members_fixed}
        catch {TT_2row_sdp__assert_flat_members_fixed}

        foreach g $round_groups {
            set info [TT_PR7__resolve_group_triplet $g]
            if {![dict get $info ok]} {
                puts "WARN: PGISO post-place resolve failed group=$g: [dict get $info reason]"
                continue
            }

            set row [dict get $info row]
            set sdp [dict get $info sdp]
            set wl [dict get $info wt_l]
            set c  [dict get $info cell]

            set cell_before [TT_PR7__point2 [get_db $c .location]]
            set cell_bbox_before [TT_PR7__rect $c]
            set wb [TT_PR7__rect $wl]
            if {[llength $cell_before] != 2 || [llength $wb] != 4} {
                catch {TT_PR7__restore_triplet_padding $info $original_padding($g)}
                puts "WARN: PGISO cannot derive re-anchor geometry group=$g"
                continue
            }

            lassign $wb wlx1 wly1 wlx2 wly2
            set wt_w [expr {double($wlx2)-double($wlx1)}]
            lassign $cell_before cx cy
            set target_origin [list [expr {double($cx)-$wt_w}] $cy]
            lassign $target_origin tx ty

            set orc [catch {set_sdp_origin -sdp $row -location $tx $ty} oerr]

            if {[catch {TT_PR7__restore_triplet_padding $info $original_padding($g)} rerr]} {
                error "PGISO failed to restore exact padding group=$g: $rerr"
            }
            if {$orc != 0} {
                puts "WARN: PGISO set_sdp_origin failed group=$g: $oerr"
                continue
            }

            set cell_after [TT_PR7__point2 [get_db $c .location]]
            set cell_bbox_after [TT_PR7__rect $c]
            set actual_origin [TT_PR7__point2 [get_db $sdp .location]]

            set cell_moved [expr {
                ![TT_PR7__same_point $cell_before $cell_after $::TT_PR7_INTERNAL_GAP_TOL] ||
                ![TT_PR7__same_bbox $cell_bbox_before $cell_bbox_after $::TT_PR7_INTERNAL_GAP_TOL]
            }]
            if {$cell_moved} {
                puts "CRITICAL: PGISO group=$g CELL moved during set_sdp_origin; no rollback attempted."
                continue
            }
            if {![TT_PR7__same_point $actual_origin $target_origin $::TT_PR7_INTERNAL_GAP_TOL]} {
                puts "WARN: PGISO group=$g origin verify failed expected={$target_origin} actual={$actual_origin}"
                continue
            }

            if {$use_targeted_native} {
                # Small repair set: preserve the original full canonical
                # FIX+verify behavior exactly.
                catch {TT_2row_sdp__set_flat_members_fixed}
                catch {TT_2row_sdp__assert_flat_members_fixed}
            } else {
                # Large repair set: do not re-walk all 702 canonical members
                # after every group. Protect only this repaired triplet now.
                TT_SDP_PGISO__fix_triplet_only $info
            }

            set custom [TT_PR7_scan_internal_sdp_structure false false [list $g]]
            set pgok [TT_SDP_PGROW_group_legal $g]

            if {$use_targeted_native} {
                set native [TT_PR7__target_native_check $row]
                if {[dict get $custom violations] == 0 && [dict get $native ok] && $pgok} {
                    set n [TT_SDP_PGISO__delete_move_for_group $g]
                    puts "PASS: PGISO group=$g gap=0 native=0 PGROW=0; deleted_move_BLKs=$n"
                } else {
                    puts "WARN: PGISO group=$g unresolved gap=[dict get $custom violations] native=[dict get $native total] pgrow_ok=$pgok"
                }
            } else {
                if {[dict get $custom violations] == 0 && $pgok} {
                    lappend pending_native_pass $g
                    puts "PENDING: PGISO group=$g gap=0 PGROW=0 native=DEFERRED"
                } else {
                    puts "WARN: PGISO group=$g unresolved gap=[dict get $custom violations] native=DEFERRED pgrow_ok=$pgok"
                }
            }
        }

        # When many groups are repaired together, do NOT invoke one native
        # check_sdps per group.  Validate native SDP legality once for the
        # completed batched round.
        if {!$use_targeted_native} {
            puts "INFO: PGISO large-batch canonical protection: one full FIX+verify after [llength $round_groups] group-local triplet checks."
            TT_2row_sdp__set_flat_members_fixed
            TT_2row_sdp__assert_flat_members_fixed

            puts "INFO: PGISO batch-native validation: running ONE global check_sdps for [llength $round_groups] repaired group(s)."
            set global_native_total [TT_SDP_PGISO__global_native_total]
            set last_global_native $global_native_total
            if {$global_native_total == 0} {
                set released 0
                foreach g $pending_native_pass {
                    incr released [TT_SDP_PGISO__delete_move_for_group $g]
                }
                puts "PASS: PGISO global native check_sdps=0; pending_groups=[llength $pending_native_pass] deleted_move_BLKs=$released"
            } else {
                puts "WARN: PGISO global native check_sdps=$global_native_total; pending move BLKs retained for safety."
            }
        }

        # One global PGROW re-scan after the single global placement pass.
        set result [TT_SDP_PGROW_scan true]
        if {$::TT_SDP_PGISO_ONE_PLACE_DETAIL_PER_RUN && [dict get $result violations] > 0} {
            puts "WARN: PGISO one-pass policy: [dict get $result violations] violation group(s) remain."
            puts "WARN: NOT running another place_detail in this invocation; owned BLKs stay active for checkpoint/manual inspection."
        }
    }

    dict set result repair_rounds $repair_rounds
    if {$last_global_native ne ""} {
        dict set result native_total $last_global_native
    }

    if {[dict get $result violations] == 0} {
        puts "PASS: PGROW slot-reservation repair is clean."
    } else {
        puts "WARN: PGROW slot-reservation repair stopped with [dict get $result violations] violation group(s)."
        puts "WARN: owned reserve/move BLKs are intentionally retained for checkpoint/manual inspection."
    }
    return $result
}

puts "INFO: Loaded TT_repair_powergate_iso_slots.tcl - $::TT_SDP_PGISO_VERSION"
puts "INFO: REPAIR : TT_repair_powergate_iso_slots ?scan_result? ?max_rounds? ; default policy = ONE global place_detail per invocation"
puts "INFO: CLEAN  : TT_SDP_PGISO_cleanup"
puts "INFO: NATIVE : <=limit targeted/full-FIX; >limit triplet-only per group + one full canonical FIX/verify + one global check per round"
