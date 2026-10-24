# Runtime adapter preserves the historical logical source path.
if {[info exists ::TECH_MV_RUNTIME_ROOT]} {
    info script [file join $::TECH_MV_RUNTIME_ROOT run/tool/02_powerplan/TT_repair_switch_gap_hard_keepout.tcl]
}
# PUBLIC_EXPORT_REVIEW_REQUIRED: residual technology candidates require manual review.
# =============================================================================
# TT_repair_switch_gap_hard_keepout_V2_15.tcl
# =============================================================================
# Targeted Power-Switch / 2-row SDP spacing repair for TECH_MV.
#
# Intended use while the V7.18 SDP flow is natively suspended at:
#   SDP / POWER-SWITCH GAP REPAIR SUSPEND
#
# The current V7.18 flow uses set_inst_padding as a placement hint.  Innovus
# place_sdps does not reliably honor that hint for SDP legalization.  This helper
# converts the required switch gap into persistent HARD placement blockages on
# the LEFT/RIGHT/TOP/BOTTOM of EVERY power switch before SDP
# legalization/refine.  The full switch blockage set remains present across all
# refine passes and native suspend/resume checkpoints.  Only the offending
# canonical SDP rows are released.  The blockages are removed only after BOTH
# check_sdps and the custom switch-gap scan are clean.
#
# Requirements:
#   - source while TT_2row_sdp_welltap_after_endcap_v6.tcl is already loaded
#   - Common UI only
#   - does NOT move/unfix Power Switches
#   - does NOT fix non-canonical low-power cells
#   - does NOT delete SDP groups or functional cells
#
# Manual use:
#   source run/tool/02_powerplan/TT_repair_switch_gap_hard_keepout.tcl
#   TT_refine_switch_gap_sdps 5
#   # all-switch hard keep-outs persist if violations remain
#   # when final_violations == 0 and check_sdps == 0 they are removed
#   resume
# =============================================================================

set ::TT_SDP_SWKO_VERSION "V2.17_REUSE_FINAL_GATE_RESULTS"
set ::TT_SDP_SWKO_PREFIX  "TT_SDP_SWKO_"
set ::TT_SDP_SWKO_ACTIVE  {}

proc TT_SWKO__require_loaded {} {
    foreach cmd {
        TT_2row_sdp__scan_switch_gap
        TT_2row_sdp__switch_padding_sites
        TT_2row_sdp__site_geometry
        TT_2row_sdp__power_switches
        TT_2row_sdp__flat_group_records
        TT_2row_sdp__build_inst_lookup
        TT_2row_sdp__resolve_inst
        TT_2row_sdp__rect4
        TT_2row_sdp__rect_overlap
        TT_2row_sdp__prepare_background_for_repair
        TT_2row_sdp__force_noncanonical_lp_unplaced
        TT_2row_sdp__set_flat_members_fixed
        TT_2row_sdp__assert_flat_members_fixed
        TT_2row_sdp__set_selected_group_status
        TT_2row_sdp__check_sdps_total
    } {
        if {[llength [info commands $cmd]] == 0} {
            error "TT_SWKO: required SDP command '$cmd' is not loaded. Source this helper only from the active TECH_MV SDP flow."
        }
    }
    foreach cmd {create_place_blockage delete_obj place_sdps get_db set_db} {
        if {[llength [info commands $cmd]] == 0} {
            error "TT_SWKO: required Innovus command '$cmd' is unavailable."
        }
    }
}

proc TT_SWKO_cleanup {} {
    set deleted 0
    set failed 0
    set prefix $::TT_SDP_SWKO_PREFIX

    set pbs {}
    catch {set pbs [get_db place_blockages]}
    foreach pb $pbs {
        set n ""
        catch {set n [get_db $pb .name]}
        if {$n eq "" || ![string match "${prefix}*" $n]} {
            continue
        }
        if {[catch {delete_obj $pb} err]} {
            incr failed
            puts "WARNING: TT_SWKO could not delete temp placement blockage '$n': $err"
        } else {
            incr deleted
        }
    }
    set ::TT_SDP_SWKO_ACTIVE {}
    puts "INFO: TT_SWKO cleanup: deleted=$deleted failed=$failed"
    return [expr {$failed == 0}]
}

proc TT_SWKO__required_gap {} {
    set sites [TT_2row_sdp__switch_padding_sites]
    if {$sites <= 0} {
        return 0.0
    }
    lassign [TT_2row_sdp__site_geometry] site_w site_h
    return [expr {double($site_w) * double($sites)}]
}

proc TT_SWKO__group_records_by_name {} {
    set d [dict create]
    foreach rec [TT_2row_sdp__flat_group_records] {
        lassign $rec group wt_l_name cell_name wt_r_name
        dict set d $group $rec
    }
    return $d
}

proc TT_SWKO__offending_switches {groups gap} {
    set rec_by_group [TT_SWKO__group_records_by_name]
    catch {array unset inst_exact}
    catch {array unset inst_leaf}
    TT_2row_sdp__build_inst_lookup inst_exact inst_leaf
    set switches [TT_2row_sdp__power_switches]
    set hits [dict create]

    foreach group $groups {
        if {![dict exists $rec_by_group $group]} {
            error "TT_SWKO: violating SDP group '$group' is not present in the canonical flat SDP file."
        }
        lassign [dict get $rec_by_group $group] _ wt_l_name cell_name wt_r_name
        set wt_l [TT_2row_sdp__resolve_inst $wt_l_name inst_exact inst_leaf]
        set cell [TT_2row_sdp__resolve_inst $cell_name inst_exact inst_leaf]
        set wt_r [TT_2row_sdp__resolve_inst $wt_r_name inst_exact inst_leaf]
        if {$wt_l eq "" || $cell eq "" || $wt_r eq ""} {
            error "TT_SWKO: cannot resolve canonical members for '$group'."
        }

        set lb [TT_2row_sdp__rect4 $wt_l]
        set cb [TT_2row_sdp__rect4 $cell]
        set rb [TT_2row_sdp__rect4 $wt_r]
        if {[llength $lb] != 4 || [llength $cb] != 4 || [llength $rb] != 4} {
            error "TT_SWKO: invalid canonical bbox for '$group'."
        }

        # Match the checker: test the center CELL only; Welltap clearance is excluded.
        foreach sw $switches {
            set sb [TT_2row_sdp__rect4 $sw]
            if {![TT_2row_sdp__member_switch_gap_hit $cb $sb $gap]} {
                continue
            }
            set sw_name [get_db $sw .name]
            dict set hits $sw_name $sw
        }
    }

    set result {}
    dict for {k v} $hits {
        lappend result $v
    }
    return $result
}

proc TT_SWKO__live_blockages {} {
    set result {}
    set prefix $::TT_SDP_SWKO_PREFIX
    set pbs {}
    catch {set pbs [get_db place_blockages]}
    foreach pb $pbs {
        set n ""
        catch {set n [get_db $pb .name]}
        if {$n ne "" && [string match "${prefix}*" $n]} {
            lappend result $pb
        }
    }
    return $result
}

proc TT_SWKO_live_count {} {
    return [llength [TT_SWKO__live_blockages]]
}

proc TT_SWKO__all_live_are_hard {} {
    foreach pb [TT_SWKO__live_blockages] {
        set t ""
        catch {set t [get_db $pb .type]}
        if {$t ne "hard"} {
            return 0
        }
    }
    return 1
}

# Create one HARD placement-blockage object per Power Switch.  Each object owns
# four rectangles: LEFT / RIGHT / TOP / BOTTOM keep-out strips.  TOP/BOTTOM
# span x1-gap .. x2+gap so the four corner regions are protected as well.
# The fixed switch itself is never covered.  Existing partial
# TT_SDP_SWKO_* state is discarded first; this is important when upgrading a
# suspended V2.14 session that may contain only the currently offending SW set.
proc TT_SWKO_create_all_switch_keepouts {{force_rebuild 0} {gap_override ""}} {
    TT_SWKO__require_loaded

    if {$gap_override eq ""} {
        set gap [TT_SWKO__required_gap]
    } else {
        set gap [expr {double($gap_override)}]
    }
    if {$gap <= 0.0} {
        error "TT_SWKO: required Power-Switch horizontal gap must be > 0; got '$gap'."
    }

    set switches [TT_2row_sdp__power_switches]
    set expected [llength $switches]
    if {$expected == 0} {
        error "TT_SWKO: no Power Switch instances were discovered."
    }

    set live [TT_SWKO_live_count]
    if {!$force_rebuild && $live == $expected && [TT_SWKO__all_live_are_hard]} {
        set _names {}
        foreach _pb [TT_SWKO__live_blockages] {
            lappend _names [get_db $_pb .name]
        }
        set ::TT_SDP_SWKO_ACTIVE $_names
        unset _names
        unset _pb
        puts "INFO: TT_SWKO reusing complete persistent all-switch keep-out set: $live hard blockage(s)."
        return $live
    }

    if {$live != 0} {
        puts "INFO: TT_SWKO replacing incomplete/stale keep-out set: live=$live expected=$expected."
    }
    if {![TT_SWKO_cleanup]} {
        error "TT_SWKO: could not remove stale/partial TT_SDP_SWKO_* placement blockages."
    }

    set created 0
    set failed 0
    set names {}
    set idx 0

    foreach sw $switches {
        incr idx
        set sw_name [get_db $sw .name]
        set b [TT_2row_sdp__rect4 $sw]
        if {[llength $b] != 4} {
            incr failed
            puts "WARNING: TT_SWKO invalid switch bbox: $sw_name"
            continue
        }
        lassign $b x1 y1 x2 y2

        # The fixed switch itself is never covered.  One blockage object per SW
        # forms a complete four-side moat.  TOP/BOTTOM span the horizontally
        # expanded width so the corner regions are blocked too.
        set left_rect   [list [expr {$x1-$gap}] $y1 $x1 $y2]
        set right_rect  [list $x2 $y1 [expr {$x2+$gap}] $y2]
        set bottom_rect [list [expr {$x1-$gap}] [expr {$y1-$gap}] [expr {$x2+$gap}] $y1]
        set top_rect    [list [expr {$x1-$gap}] $y2 [expr {$x2+$gap}] [expr {$y2+$gap}]]
        set name [format "%s%04d" $::TT_SDP_SWKO_PREFIX $idx]

        if {[catch {
            create_place_blockage \
                -rects [list $left_rect $right_rect $bottom_rect $top_rect] \
                -name $name \
                -type hard
        } err]} {
            incr failed
            puts "ERROR: TT_SWKO create_place_blockage failed for switch '$sw_name': $err"
            continue
        }

        incr created
        lappend names $name
    }

    set ::TT_SDP_SWKO_ACTIVE $names
    set live_after [TT_SWKO_live_count]
    set hard_ok [TT_SWKO__all_live_are_hard]

    puts ""
    puts "======================================================================"
    puts " TT SDP / POWER-SWITCH PERSISTENT ALL-SW HARD KEEP-OUT"
    puts "======================================================================"
    puts "Total Power Switches       : $expected"
    puts "Required 4-side gap        : $gap um"
    puts "Hard keep-outs created     : $created"
    puts "Live TT_SWKO blockages     : $live_after"
    puts "Creation failures          : $failed"
    puts "All live blockages HARD    : $hard_ok"
    puts "Lifetime policy            : KEEP across ALL refine/suspend passes"
    puts "Removal policy             : only after check_sdps=0 AND SW-gap=0"
    puts "Geometry policy            : one SW -> one blockage object -> LEFT/RIGHT/TOP/BOTTOM moat"
    puts "======================================================================"

    if {$failed != 0 || $created != $expected || $live_after != $expected || !$hard_ok} {
        TT_SWKO_cleanup
        error "TT_SWKO: all-switch hard keep-out creation incomplete: created=$created live=$live_after expected=$expected failed=$failed hard_ok=$hard_ok."
    }
    return $created
}

proc TT_SWKO_ensure_all_switch_keepouts {{gap_override ""}} {
    set switches [TT_2row_sdp__power_switches]
    set expected [llength $switches]
    set live [TT_SWKO_live_count]
    if {$expected > 0 && $live == $expected && [TT_SWKO__all_live_are_hard]} {
        puts "INFO: TT_SWKO persistent keep-outs already complete: $live/$expected hard blockage(s); reusing them."
        return $live
    }
    return [TT_SWKO_create_all_switch_keepouts 1 $gap_override]
}

# Delete persistent all-switch keep-outs only when both legality gates are clean.
# Return 1 when cleanup was performed/already clean, 0 when keep-outs must stay.
proc TT_SWKO_finalize_if_clean {{gap_vio "__AUTO__"} {native_vio "__AUTO__"}} {
    # V2.17: final Stage-8 may pass the native/SW-gap values it has just
    # computed.  No need to repeat two expensive global checks with no mutation
    # in between.  Existing callers with no arguments preserve legacy behavior.
    if {$gap_vio eq "__AUTO__"} {
        set gap_result [TT_2row_sdp__scan_switch_gap false]
        set gap_vio [dict get $gap_result violations]
    }
    if {$native_vio eq "__AUTO__"} {
        set native_vio [TT_2row_sdp__check_sdps_total]
    }
    set live [TT_SWKO_live_count]

    if {$gap_vio == 0 && $native_vio == 0} {
        if {$live != 0} {
            puts "INFO: TT_SWKO all repair gates clean; removing $live persistent all-switch hard keep-out(s)."
            if {![TT_SWKO_cleanup]} {
                error "TT_SWKO: final persistent keep-out cleanup failed."
            }
        } else {
            puts "INFO: TT_SWKO repair gates clean; no persistent keep-outs remain."
        }
        return 1
    }

    puts "INFO: TT_SWKO keep-outs retained: check_sdps=$native_vio SW-gap=$gap_vio live_keepouts=$live."
    return 0
}


# Override the V7.18 padding-only implementation with a hard-keepout targeted
# legalizer.  The public proc name intentionally stays the same so both the
# automatic flow and the suspended manual command use identical behavior.
proc TT_refine_switch_gap_sdps {{max_iter 5}} {
    TT_SWKO__require_loaded
    if {![string is integer -strict $max_iter] || $max_iter < 1} {
        error "TT_refine_switch_gap_sdps max_iter must be an integer >= 1."
    }

    set initial [TT_2row_sdp__scan_switch_gap true]
    set result $initial
    set pass 0
    set stall_count 0
    set keepouts_created 0

    # The all-switch keep-out topology is a placement constraint, not a repair
    # artifact.  Build/reuse the FULL set once before any SDP row is released.
    if {[dict get $result violations] != 0} {
        set gap [dict get $result required_gap]
        if {$gap <= 0.0} { set gap [TT_SWKO__required_gap] }
        set keepouts_created [TT_SWKO_ensure_all_switch_keepouts $gap]
    }

    set previous_signature [join [lsort -unique [dict get $result groups]] ","]

    while {[dict get $result violations] != 0 && $pass < $max_iter} {
        incr pass
        set groups [dict get $result groups]

        if {[info exists ::TT_2ROW_SDP_PRE_UNPLACED_SNAPSHOT]} {
            TT_2row_sdp__prepare_background_for_repair                 $::TT_2ROW_SDP_PRE_UNPLACED_SNAPSHOT                 "SW_ALL_KO_REFINE_PASS_$pass"
        } else {
            TT_2row_sdp__force_noncanonical_lp_unplaced                 "SW_ALL_KO_REFINE_PASS_$pass"
        }

        # IMPORTANT: do not create/delete per-pass blockage subsets here.  The
        # same complete all-switch blockage set stays live for every iteration.
        TT_SWKO_ensure_all_switch_keepouts [dict get $result required_gap]

        TT_2row_sdp__set_flat_members_fixed
        TT_2row_sdp__assert_flat_members_fixed
        set released [TT_2row_sdp__set_selected_group_status $groups placed]
        puts "INFO: TT_SWKO pass $pass/$max_iter: released $released canonical member(s) from [llength $groups] SDP group(s); persistent_keepouts=[TT_SWKO_live_count]."

        set rc [catch {place_sdps} msg opts]

        # Never leave canonical members unfixed at a manual breakpoint, and
        # NEVER remove all-switch keep-outs on an unsuccessful/incomplete pass.
        catch {TT_2row_sdp__set_flat_members_fixed}
        catch {TT_2row_sdp__assert_flat_members_fixed}

        if {$rc} {
            puts "WARNING: TT_SWKO place_sdps failed; persistent all-switch keep-outs are intentionally retained for debug/resume."
            return -options $opts $msg
        }

        set native_vio [TT_2row_sdp__check_sdps_total]
        set result [TT_2row_sdp__scan_switch_gap true]
        puts "INFO: TT_SWKO pass $pass result: gap_violations=[dict get $result violations] gap_groups=[llength [dict get $result groups]] check_sdps=$native_vio persistent_keepouts=[TT_SWKO_live_count]."

        # Avoid burning all iterations after convergence stalls.  Two identical
        # consecutive violating-group sets with a fixed all-switch obstacle map
        # indicate that another identical place_sdps pass is not useful.
        set signature [join [lsort -unique [dict get $result groups]] ","]
        if {$signature eq $previous_signature && $signature ne ""} {
            incr stall_count
        } else {
            set stall_count 0
        }
        set previous_signature $signature
        if {$stall_count >= 2} {
            puts "WARN: TT_SWKO persistent-all-switch refine stalled for two consecutive passes; stopping automatic iteration with keep-outs ACTIVE."
            break
        }
    }

    TT_2row_sdp__set_flat_members_fixed
    TT_2row_sdp__assert_flat_members_fixed
    set final_native [TT_2row_sdp__check_sdps_total]
    set result [TT_2row_sdp__scan_switch_gap true]

    set keepout_state "retained"
    if {[dict get $result violations] == 0 && $final_native == 0} {
        TT_SWKO_finalize_if_clean
        set keepout_state "removed_after_clean"
    }

    puts ""
    puts "======================================================================"
    puts " TT SDP / POWER-SWITCH PERSISTENT ALL-SW KEEPOUT REFINE SUMMARY"
    puts "======================================================================"
    puts "Total Power Switches      : [llength [TT_2row_sdp__power_switches]]"
    puts "Persistent keep-outs live : [TT_SWKO_live_count]"
    puts "Initial pair violations   : [dict get $initial violations]"
    puts "Final pair violations     : [dict get $result violations]"
    puts "Final violating groups    : [llength [dict get $result groups]]"
    puts "Final check_sdps total    : $final_native"
    puts "Passes                    : $pass"
    puts "Canonical state           : FIXED"
    puts "Keep-out state            : $keepout_state"
    puts "Policy                    : ALL switches blocked continuously until BOTH gates are clean"
    puts "======================================================================"

    return [dict create         initial_violations [dict get $initial violations]         final_violations [dict get $result violations]         final_groups [dict get $result groups]         final_check_sdps $final_native         passes $pass         keepout_state $keepout_state         keepouts_live [TT_SWKO_live_count]]
}

puts "INFO: Loaded TT_repair_switch_gap_hard_keepout.tcl - $::TT_SDP_SWKO_VERSION"
puts "INFO: Persistent policy: ALL Power Switches receive HARD LEFT/RIGHT/TOP/BOTTOM keep-outs before any refine."
puts "INFO: Current suspended-flow command: TT_refine_switch_gap_sdps 5"
