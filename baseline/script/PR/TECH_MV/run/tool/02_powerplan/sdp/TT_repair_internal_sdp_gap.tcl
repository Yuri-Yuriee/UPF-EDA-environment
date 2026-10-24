# Runtime adapter preserves the historical logical source path.
if {[info exists ::TECH_MV_RUNTIME_ROOT]} {
    info script [file join $::TECH_MV_RUNTIME_ROOT run/tool/02_powerplan/sdp/TT_repair_internal_sdp_gap.tcl]
}
# PUBLIC_EXPORT_REVIEW_REQUIRED: residual technology candidates require manual review.
# Load private values before evaluating original parameter defaults.
if {![llength [info commands ::tech_mv_private_value]]} { source [file join $::TECH_MV_RUNTIME_ROOT .. script PR TECH_MV script 00_common private_parameter_config.tcl] }
# =============================================================================
# TT_repair_internal_sdp_gap.tcl
# TECH_MV / Innovus 21.19 Stylus / Common UI
# V1.2 - internal [WT_L][CELL][WT_R] geometry validator / targeted repair
#
# Final policy implemented here:
#   - External Power-Switch <-> SDP distance is NOT a PASS/FAIL gate.
#   - Every canonical row must keep full WT_L -> CELL -> WT_R SDP membership.
#   - WT_L -> CELL gap must lie between abutment and the configured maximum site span.
#   - CELL -> WT_R uses the same limit: TT_2ROW_SDP_INTERNAL_GAP_MAX_SITES * site_width.
#   - No foreign instance may occupy either internal gap corridor.
#   - Native check_sdps remains an independent zero-violation gate.
#
# Repair policy:
#   - Keep clean canonical SDP rows fixed.
#   - Release only violating rows (fixed -> placed).
#   - Use plain targeted place_sdps -sdps {...}; never -keep_sdp_area.
#   - Re-fix canonical members after each pass.
# =============================================================================

set ::TT_INTERNAL_SDP_GAP_VERSION "V1.2_ADVISORY_CHECKPOINT"
if {![info exists ::TT_2ROW_SDP_INTERNAL_GAP_MAX_SITES]} {
    set ::TT_2ROW_SDP_INTERNAL_GAP_MAX_SITES [::tech_mv_private_value {run/tool/02_powerplan/TT_repair_internal_sdp_gap.tcl::::TT_2ROW_SDP_INTERNAL_GAP_MAX_SITES::L23}]
}
if {![info exists ::TT_2ROW_SDP_INTERNAL_GAP_TOL_UM]} {
    set ::TT_2ROW_SDP_INTERNAL_GAP_TOL_UM [::tech_mv_private_value {run/tool/02_powerplan/TT_repair_internal_sdp_gap.tcl::::TT_2ROW_SDP_INTERNAL_GAP_TOL_UM::L26}]
}
# KEEP means preserve the current Innovus value when it is already > 0.
# If the current value is <= 0, the bounded fallback below is applied.
if {![info exists ::TT_2ROW_SDP_REPAIR_MAX_MOVE_DISTANCE]} {
    set ::TT_2ROW_SDP_REPAIR_MAX_MOVE_DISTANCE $::TECH_MV_SDP_MOVE_DEFAULTS(TT_2ROW_SDP_REPAIR_MAX_MOVE_DISTANCE)
}

proc TT_INTERNAL_SDP__bool {v} {
    set x [string tolower [string trim $v]]
    return [expr {$x in {1 true yes on}}]
}

proc TT_INTERNAL_SDP__gap_limit_um {} {
    if {![string is integer -strict $::TT_2ROW_SDP_INTERNAL_GAP_MAX_SITES] ||
        $::TT_2ROW_SDP_INTERNAL_GAP_MAX_SITES < 0} {
        error "TT_2ROW_SDP_INTERNAL_GAP_MAX_SITES must be a non-negative integer."
    }
    lassign [TT_2row_sdp__site_geometry] site_w site_h
    if {$site_w <= 0.0} {
        error "Cannot derive internal SDP gap limit: invalid site width '$site_w'."
    }
    return [expr {double($site_w) * double($::TT_2ROW_SDP_INTERNAL_GAP_MAX_SITES)}]
}

proc TT_INTERNAL_SDP__strict_overlap {a b {tol 0.000001}} {
    if {[llength $a] != 4 || [llength $b] != 4} { return false }
    lassign $a ax1 ay1 ax2 ay2
    lassign $b bx1 by1 bx2 by2
    set xov [expr {min(double($ax2),double($bx2)) - max(double($ax1),double($bx1))}]
    set yov [expr {min(double($ay2),double($by2)) - max(double($ay1),double($by1))}]
    return [expr {$xov > $tol && $yov > $tol}]
}

proc TT_INTERNAL_SDP__foreign_in_gap {x1 y1 x2 y2 members} {
    set tol $::TT_2ROW_SDP_INTERNAL_GAP_TOL_UM
    if {$x2 <= $x1 + $tol || $y2 <= $y1 + $tol} {
        return {}
    }
    set area [list $x1 $y1 $x2 $y2]
    set candidates {}
    if {[llength [info commands get_obj_in_area]] > 0} {
        if {[catch {
            set candidates [get_obj_in_area -area $area -obj_type inst -overlap_only]
        } err]} {
            puts "WARN: internal-gap get_obj_in_area failed for $area; falling back to get_db insts: $err"
            set candidates [get_db insts]
        }
    } else {
        set candidates [get_db insts]
    }

    set foreign {}
    foreach obj $candidates {
        if {[lsearch -exact $members $obj] >= 0} { continue }
        set b {}
        catch {set b [TT_2row_sdp__rect4 $obj]}
        if {[llength $b] != 4} { continue }
        if {[TT_INTERNAL_SDP__strict_overlap $area $b $tol]} {
            lappend foreign $obj
        }
    }
    return [lsort -unique $foreign]
}

proc TT_2row_sdp__assert_full_flat_membership {} {
    set records [TT_2row_sdp__flat_group_records]
    catch {array unset inst_exact}
    catch {array unset inst_leaf}
    TT_2row_sdp__build_inst_lookup inst_exact inst_leaf
    set checked 0
    foreach rec $records {
        lassign $rec group wt_l_name cell_name wt_r_name
        foreach n [list $wt_l_name $cell_name $wt_r_name] {
            set obj [TT_2row_sdp__resolve_inst $n inst_exact inst_leaf]
            if {$obj eq ""} {
                error "Full-membership verification failed: unresolved canonical member '$n' in '$group'."
            }
            set row ""
            catch {set row [get_db $obj .sdp.name]}
            if {$row ne "${group}_ROW"} {
                error "Full-membership verification failed: '$n' SDP='$row', expected='${group}_ROW'."
            }
            incr checked
        }
    }
    puts "PASS: Full canonical SDP membership verified: $checked member(s)."
    return $checked
}

# Returns a dict:
#   violations  = number of violating groups
#   issues      = number of individual rule failures
#   groups      = canonical datapath names, e.g. SDP2R_00066
#   max_gap_um  = allowed physical gap on each side
#   records     = per-group diagnostic dicts for violating rows
proc TT_2row_sdp__scan_internal_structure {{verbose true} {require_full_membership true}} {
    set records [TT_2row_sdp__flat_group_records]
    set max_gap [TT_INTERNAL_SDP__gap_limit_um]
    set tol $::TT_2ROW_SDP_INTERNAL_GAP_TOL_UM

    catch {array unset inst_exact}
    catch {array unset inst_leaf}
    TT_2row_sdp__build_inst_lookup inst_exact inst_leaf

    set bad_groups {}
    set bad_records {}
    set issue_count 0
    set shown 0

    foreach rec $records {
        lassign $rec group wt_l_name cell_name wt_r_name
        set reasons {}
        set wt_l [TT_2row_sdp__resolve_inst $wt_l_name inst_exact inst_leaf]
        set cell [TT_2row_sdp__resolve_inst $cell_name inst_exact inst_leaf]
        set wt_r [TT_2row_sdp__resolve_inst $wt_r_name inst_exact inst_leaf]

        if {$wt_l eq "" || $cell eq "" || $wt_r eq ""} {
            lappend reasons "unresolved_member"
            set gap_l "NA"
            set gap_r "NA"
            set foreign_l {}
            set foreign_r {}
        } else {
            set members [list $wt_l $cell $wt_r]
            if {[TT_INTERNAL_SDP__bool $require_full_membership]} {
                foreach pair [list [list $wt_l $wt_l_name] [list $cell $cell_name] [list $wt_r $wt_r_name]] {
                    lassign $pair obj name
                    set row ""
                    catch {set row [get_db $obj .sdp.name]}
                    if {$row ne "${group}_ROW"} {
                        lappend reasons "membership:$name:$row"
                    }
                }
            }

            set lb [TT_2row_sdp__rect4 $wt_l]
            set cb [TT_2row_sdp__rect4 $cell]
            set rb [TT_2row_sdp__rect4 $wt_r]
            if {[llength $lb] != 4 || [llength $cb] != 4 || [llength $rb] != 4} {
                lappend reasons "invalid_bbox"
                set gap_l "NA"
                set gap_r "NA"
                set foreign_l {}
                set foreign_r {}
            } else {
                lassign $lb lx1 ly1 lx2 ly2
                lassign $cb cx1 cy1 cx2 cy2
                lassign $rb rx1 ry1 rx2 ry2
                set gap_l [expr {double($cx1) - double($lx2)}]
                set gap_r [expr {double($rx1) - double($cx2)}]

                if {$gap_l < -$tol} {
                    lappend reasons [format "left_overlap=%.6f" $gap_l]
                } elseif {$gap_l > $max_gap + $tol} {
                    lappend reasons [format "left_gap=%.6f" $gap_l]
                }
                if {$gap_r < -$tol} {
                    lappend reasons [format "right_overlap=%.6f" $gap_r]
                } elseif {$gap_r > $max_gap + $tol} {
                    lappend reasons [format "right_gap=%.6f" $gap_r]
                }

                set left_y1 [expr {max(double($ly1),double($cy1))}]
                set left_y2 [expr {min(double($ly2),double($cy2))}]
                set right_y1 [expr {max(double($cy1),double($ry1))}]
                set right_y2 [expr {min(double($cy2),double($ry2))}]

                set foreign_l {}
                set foreign_r {}
                if {$gap_l > $tol && $left_y2 > $left_y1 + $tol} {
                    set foreign_l [TT_INTERNAL_SDP__foreign_in_gap $lx2 $left_y1 $cx1 $left_y2 $members]
                    if {[llength $foreign_l] != 0} {
                        lappend reasons "left_foreign=[llength $foreign_l]"
                    }
                }
                if {$gap_r > $tol && $right_y2 > $right_y1 + $tol} {
                    set foreign_r [TT_INTERNAL_SDP__foreign_in_gap $cx2 $right_y1 $rx1 $right_y2 $members]
                    if {[llength $foreign_r] != 0} {
                        lappend reasons "right_foreign=[llength $foreign_r]"
                    }
                }
            }
        }

        if {[llength $reasons] != 0} {
            lappend bad_groups $group
            incr issue_count [llength $reasons]
            lappend bad_records [dict create \
                group $group \
                wt_l $wt_l_name \
                cell $cell_name \
                wt_r $wt_r_name \
                gap_l $gap_l \
                gap_r $gap_r \
                foreign_l [llength $foreign_l] \
                foreign_r [llength $foreign_r] \
                reasons $reasons]
            if {$verbose && $shown < 30} {
                puts "WARN: INTERNAL-SDP group=$group gap_l=$gap_l gap_r=$gap_r foreign_l=[llength $foreign_l] foreign_r=[llength $foreign_r] reasons={[join $reasons {, }]}"
                incr shown
            }
        }
    }

    set bad_groups [lsort -unique $bad_groups]
    if {$verbose} {
        puts "INFO: Internal SDP structure validation: groups=[llength $records] violations=[llength $bad_groups] issues=$issue_count max_gap=${max_gap}um full_membership=$require_full_membership"
        if {[llength $bad_groups] > 30} {
            puts "INFO: Internal SDP detail capped at first 30 violating groups."
        }
    }
    set ::TT_2ROW_SDP_LAST_INTERNAL_GAP_GROUPS $bad_groups
    set ::TT_2ROW_SDP_LAST_INTERNAL_GAP_VIOLATIONS [llength $bad_groups]
    return [dict create \
        violations [llength $bad_groups] \
        issues $issue_count \
        groups $bad_groups \
        max_gap_um $max_gap \
        records $bad_records]
}

proc TT_INTERNAL_SDP__ensure_move_distance {} {
    set current ""
    catch {set current [get_db place_sdp_max_move_distance]}
    if {[string is double -strict $current] && double($current) > 0.0} {
        puts "INFO: Keeping existing place_sdp_max_move_distance=$current (>0)."
        return $current
    }

    set fallback $::TT_2ROW_SDP_REPAIR_MAX_MOVE_DISTANCE
    if {![string is double -strict $fallback] || double($fallback) <= 0.0} {
        error "place_sdp_max_move_distance is '$current' and TT_2ROW_SDP_REPAIR_MAX_MOVE_DISTANCE='$fallback'; targeted plain place_sdps requires a positive repair ceiling."
    }
    set_db place_sdp_max_move_distance $fallback
    puts "INFO: Set place_sdp_max_move_distance=$fallback for targeted internal-SDP repair."
    return $fallback
}

proc TT_refine_internal_gap_sdps {{max_iter 3}} {
    if {![string is integer -strict $max_iter] || $max_iter < 1} {
        error "TT_refine_internal_gap_sdps max_iter must be an integer >= 1."
    }
    if {[llength [info commands place_sdps]] == 0} {
        error "place_sdps is unavailable."
    }

    TT_2row_sdp__assert_full_flat_membership
    TT_INTERNAL_SDP__ensure_move_distance

    set initial [TT_2row_sdp__scan_internal_structure true true]
    set result $initial
    set pass 0
    set previous_signature ""
    set stall_count 0

    while {[dict get $result violations] != 0 && $pass < $max_iter} {
        incr pass
        set groups [dict get $result groups]

        if {[info exists ::TT_2ROW_SDP_PRE_UNPLACED_SNAPSHOT]} {
            TT_2row_sdp__prepare_background_for_repair \
                $::TT_2ROW_SDP_PRE_UNPLACED_SNAPSHOT \
                "INTERNAL_SDP_REFINE_PASS_$pass"
        } else {
            TT_2row_sdp__force_noncanonical_lp_unplaced "INTERNAL_SDP_REFINE_PASS_$pass"
        }

        TT_2row_sdp__set_flat_members_fixed
        TT_2row_sdp__assert_flat_members_fixed
        set released [TT_2row_sdp__set_selected_group_status $groups placed]

        set rows {}
        foreach g $groups { lappend rows "${g}_ROW" }
        puts "INFO: Internal-SDP refine pass $pass/$max_iter: released=$released groups=[llength $groups] rows={[join $rows { }]}"

        TT_2row_sdp__configure_2g_legalizer
        TT_INTERNAL_SDP__ensure_move_distance

        # Confirmed repair path: plain targeted place_sdps; no -keep_sdp_area.
        set rc [catch {place_sdps -sdps $rows} msg opts]
        catch {TT_2row_sdp__set_flat_members_fixed}
        catch {TT_2row_sdp__assert_flat_members_fixed}
        if {$rc} {
            return -options $opts $msg
        }

        TT_2row_sdp__assert_full_flat_membership
        set native_vio [TT_2row_sdp__check_sdps_total]
        set result [TT_2row_sdp__scan_internal_structure true true]
        puts "INFO: Internal-SDP refine pass $pass result: structural_violations=[dict get $result violations] check_sdps=$native_vio."

        set signature [join [lsort -unique [dict get $result groups]] ","]
        if {$signature ne "" && $signature eq $previous_signature} {
            incr stall_count
        } else {
            set stall_count 0
        }
        set previous_signature $signature
        if {$stall_count >= 1} {
            puts "WARN: Internal-SDP targeted repair stalled with the same violating-group set; stopping automatic iteration for operator review."
            break
        }
    }

    TT_2row_sdp__set_flat_members_fixed
    TT_2row_sdp__assert_flat_members_fixed
    TT_2row_sdp__assert_full_flat_membership
    set final_native [TT_2row_sdp__check_sdps_total]
    set result [TT_2row_sdp__scan_internal_structure true true]

    puts ""
    puts "======================================================================"
    puts " TT INTERNAL SDP TARGETED REPAIR SUMMARY"
    puts "======================================================================"
    puts "Initial violating groups : [dict get $initial violations]"
    puts "Final violating groups   : [dict get $result violations]"
    puts "Final structural issues  : [dict get $result issues]"
    puts "Final check_sdps total   : $final_native"
    puts "Passes                   : $pass"
    puts "Max internal gap         : [dict get $result max_gap_um] um"
    puts "Repair command policy    : place_sdps -sdps <violating rows>"
    puts "keep_sdp_area            : NOT USED"
    puts "External SW-gap gate     : DISABLED"
    puts "Canonical state          : FIXED + full 3-member SDP membership"
    puts "======================================================================"

    return [dict create \
        initial_violations [dict get $initial violations] \
        final_violations [dict get $result violations] \
        final_groups [dict get $result groups] \
        final_issues [dict get $result issues] \
        final_check_sdps $final_native \
        passes $pass]
}

proc TT_2row_sdp__suspend_until_internal_structure_clean {phase {allow_refine true}} {
    set result [TT_2row_sdp__scan_internal_structure true true]
    set vio [dict get $result violations]
    if {$vio == 0} {
        puts "PASS: $phase internal \[WT_L\]\[CELL\]\[WT_R\] structure is clean."
        return 0
    }

    # Before the checkpoint, automatically try exactly one targeted internal-gap
    # repair pass when requested.  Failure is advisory and does not terminate.
    if {$allow_refine} {
        puts "INFO: V7.22R3 pre-checkpoint automatic TT_refine_internal_gap_sdps 1."
        if {[catch {
            set _tt_once [TT_refine_internal_gap_sdps 1]
        } _tt_once_err]} {
            puts "WARN: Pre-checkpoint TT_refine_internal_gap_sdps 1 returned: $_tt_once_err"
        } else {
            puts "INFO: Pre-checkpoint internal refine final_violations=[dict get $_tt_once final_violations] final_check_sdps=[dict get $_tt_once final_check_sdps]."
        }
        catch {unset _tt_once}
        catch {unset _tt_once_err}

        set result [TT_2row_sdp__scan_internal_structure true true]
        set vio [dict get $result violations]
        if {$vio == 0} {
            puts "PASS: $phase internal structure became clean after the one-pass pre-checkpoint refine; suspend skipped."
            return 0
        }
    }

    TT_2row_sdp__set_flat_members_fixed
    TT_2row_sdp__assert_flat_members_fixed
    puts ""
    puts "======================================================================"
    puts " INTERNAL 2-ROW SDP INSPECTION CHECKPOINT"
    puts "======================================================================"
    puts "Phase                  : $phase"
    puts "Violating SDP groups   : $vio"
    puts "Allowed internal gap   : 0 .. [dict get $result max_gap_um] um"
    puts "Foreign-gap intrusion  : forbidden"
    puts "External SW-gap        : not a PASS/FAIL gate"
    puts "State                  : all canonical SDP members are FIXED"
    if {$allow_refine} {
        puts "Auto step              : TT_refine_internal_gap_sdps 1 already attempted"
    } else {
        puts "Auto step              : caller already performed the one-pass refine"
    }
    puts ""
    puts "Available CHECK tools:"
    puts "  TT_2row_sdp__scan_internal_structure true true"
    puts "  TT_2row_sdp__assert_full_flat_membership"
    puts "  check_sdps"
    puts "  write_sdp_file ./.temp/02_powerplan/sdp/TT_checkpoint.sdp"
    puts ""
    puts "Available REPAIR tools:"
    puts "  TT_refine_internal_gap_sdps 1"
    puts "  source run/tool/02_powerplan/TT_refine_violating_sdps.tcl"
    puts "  TT_refine_violating_sdps -dry_run 1"
    puts "  TT_refine_violating_sdps -apply -max_iter $::TT_2ROW_SDP_TARGET_REFINE_MAX_ITER"
    puts ""
    puts "Checkpoint policy:"
    puts "  - suspend is inspection only"
    puts "  - type 'resume' whenever you want to continue the flow"
    puts "  - resume never loops back to this checkpoint"
    puts "  - remaining violations are WARN only after resume"
    puts "======================================================================"
    flush stdout

    if {[llength [info commands tech_mv_checkpoint_tools]]} { tech_mv_checkpoint_tools {02_powerplan} {TT_repair_internal_sdp_gap} }
    suspend
    puts "INFO: Native resume received for advisory internal SDP checkpoint '$phase'."

    set result [TT_2row_sdp__scan_internal_structure true true]
    set vio [dict get $result violations]
    if {$vio == 0} {
        puts "PASS: $phase internal structure is clean after resume."
    } else {
        TT_2row_sdp__set_flat_members_fixed
        TT_2row_sdp__assert_flat_members_fixed
        puts "WARN: $phase still has $vio internal SDP violating group(s) after resume."
        puts "WARN: Operator accepted this checkpoint; continuing the flow without another suspend."
    }
    return $vio
}

puts "INFO: Loaded TT_repair_internal_sdp_gap.tcl - $::TT_INTERNAL_SDP_GAP_VERSION"
puts [format "INFO: PASS policy = full \[WT_L\]\[CELL\]\[WT_R\] membership, each internal gap 0..%.6fum, no foreign instance." [TT_INTERNAL_SDP__gap_limit_um]]
