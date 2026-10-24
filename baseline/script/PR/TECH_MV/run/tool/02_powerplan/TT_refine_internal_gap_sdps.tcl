# Runtime adapter preserves the historical logical source path.
if {[info exists ::TECH_MV_RUNTIME_ROOT]} {
    info script [file join $::TECH_MV_RUNTIME_ROOT run/tool/02_powerplan/TT_refine_internal_gap_sdps.tcl]
}
# PUBLIC_EXPORT_REVIEW_REQUIRED: residual technology candidates require manual review.
# Load private values before evaluating original parameter defaults.
if {![llength [info commands ::tech_mv_private_value]]} { source [file join $::TECH_MV_RUNTIME_ROOT .. script PR TECH_MV script 00_common private_parameter_config.tcl] }
# =============================================================================
# TT_refine_internal_gap_sdps.tcl
# PR7 proven internal-gap-only checker/refine helper - R9.4 CELL re-anchor triplet-padding
# TECH_MV / Innovus 21.19 Stylus / Common UI
#
# IMPORTANT:
#   - This helper does NOT replace check_sdps, switch-gap repair, HARD SW keepout,
#     or the existing TT_refine_violating_sdps flow.
#   - It is an extra pre-checkpoint repair/check for geometry that native
#     check_sdps/check_place can miss.
#   - R9.4 repairs the union of PR7 internal-gap violations and native
#     Overlap/PlaceLegality/Interleaving SDP violations with bounded batched
#     place_detail rounds.
#   - Temporary one-Welltap center blockages and TT_PR7_CELL_REANCHOR_PAD_SITES side padding guide CELL relocation.
#   - After each CELL move, set_sdp_origin re-anchors the SDP; WT movement is
#     allowed but CELL movement is forbidden and guarded.
#   - Exact original WT_L/CELL/WT_R padding is restored. PASS groups remove GAPBLKs
#     immediately; unresolved GAPBLKs remain through suspend for review/cleanup.
#   - TT_SDP_SWKO_* remain active through suspend. Native full check_sdps and
#     the original downstream WellTap insertion remain untouched.
# =============================================================================

set ::TT_PR7_CELL_REANCHOR_VERSION "R9.5_GAP_ONLY_NATIVE_FIRST"

if {![info exists ::TT_PR7_INTERNAL_GAP_MAX_UM]} { set ::TT_PR7_INTERNAL_GAP_MAX_UM [::tech_mv_private_value {run/tool/02_powerplan/TT_refine_internal_gap_sdps.tcl::::TT_PR7_INTERNAL_GAP_MAX_UM::L25}] }
if {![info exists ::TT_PR7_INTERNAL_GAP_TOL]} { set ::TT_PR7_INTERNAL_GAP_TOL [::tech_mv_private_value {run/tool/02_powerplan/TT_refine_internal_gap_sdps.tcl::::TT_PR7_INTERNAL_GAP_TOL::L26}] }
if {![info exists ::TT_PR7_INTERNAL_REFINE_MOVE_DISTANCE]} { set ::TT_PR7_INTERNAL_REFINE_MOVE_DISTANCE $::TECH_MV_SDP_MOVE_DEFAULTS(TT_PR7_INTERNAL_REFINE_MOVE_DISTANCE) }

proc TT_PR7__rect {obj} {
    set b [TT_2row_sdp__bbox4 [get_db $obj .bbox]]
    if {$b eq "" || [llength $b] != 4} { return {} }
    return $b
}

proc TT_PR7__cache_inst_rects {} {
    set out {}
    foreach obj [get_db insts] {
        set b [TT_PR7__rect $obj]
        if {[llength $b] != 4} { continue }
        lassign $b x1 y1 x2 y2
        lappend out [list $obj $x1 $y1 $x2 $y2]
    }
    return $out
}

proc TT_PR7__foreign_in_gap {rect_cache x1 y1 x2 y2 members} {
    set tol $::TT_PR7_INTERNAL_GAP_TOL
    if {$x2 <= $x1 + $tol || $y2 <= $y1 + $tol} { return {} }
    set foreign {}
    foreach rec $rect_cache {
        lassign $rec obj ox1 oy1 ox2 oy2
        if {[lsearch -exact $members $obj] >= 0} { continue }
        set xov [expr {min($x2,$ox2) - max($x1,$ox1)}]
        if {$xov <= $tol} { continue }
        set yov [expr {min($y2,$oy2) - max($y1,$oy1)}]
        if {$yov > $tol} { lappend foreign $obj }
    }
    return $foreign
}

proc TT_PR7__clear_highlight {} {
    if {[llength [info commands gui_clear_highlight]] > 0} {
        catch {gui_clear_highlight -all}
    }
    if {[llength [info commands gui_redraw]] > 0} { catch {gui_redraw} }
}

proc TT_PR7__highlight_result {result} {
    # PR7 rule: every refresh first removes the previous GUI highlight.
    TT_PR7__clear_highlight
    set groups [dict get $result groups]
    if {[llength $groups] == 0} {
        puts "INFO: PR7 GUI highlight cleared; no current internal-SDP violation group remains."
        return 0
    }
    if {[llength [info commands gui_highlight]] == 0} {
        puts "WARN: gui_highlight is unavailable; textual PR7 violation report remains valid."
        return 0
    }

    catch {array unset wanted}
    foreach g $groups { set wanted($g) 1 }
    catch {array unset inst_exact}
    catch {array unset inst_leaf}
    TT_2row_sdp__build_inst_lookup inst_exact inst_leaf

    set count 0
    foreach rec [TT_2row_sdp__flat_group_records] {
        lassign $rec group wt_l_name cell_name wt_r_name
        if {![info exists wanted($group)]} { continue }
        foreach n [list $wt_l_name $cell_name $wt_r_name] {
            set obj [TT_2row_sdp__resolve_inst $n inst_exact inst_leaf]
            if {$obj eq ""} { continue }
            catch {gui_highlight $obj -index 1 -color red}
            incr count
        }
    }
    if {[llength [info commands gui_redraw]] > 0} { catch {gui_redraw} }
    puts "INFO: PR7 GUI highlight refreshed: $count member(s) from [llength $groups] violating SDP group(s) highlighted RED."
    return $count
}

proc TT_PR7_scan_internal_sdp_structure {{verbose true} {highlight true} {only_groups {}}} {
    # R9.5 policy:
    #   This custom checker owns ONLY excessive internal spacing:
    #       WT_L -> CELL
    #       CELL -> WT_R
    #
    #   Native check_sdps owns:
    #       membership / order / overlap / place legality / interleaving /
    #       missing rows / foreign occupants / all other native legality.
    #
    #   Negative gap (overlap) is intentionally NOT a custom violation.
    #   check_sdps must resolve it before this custom repair is allowed to move.
    set max_gap $::TT_PR7_INTERNAL_GAP_MAX_UM
    set tol $::TT_PR7_INTERNAL_GAP_TOL
    set records [TT_2row_sdp__flat_group_records]

    catch {array unset wanted}
    if {[llength $only_groups] > 0} {
        foreach g $only_groups {
            set base [regsub {_ROW$} $g ""]
            set wanted($base) 1
        }
    }

    catch {array unset inst_exact}
    catch {array unset inst_leaf}
    TT_2row_sdp__build_inst_lookup inst_exact inst_leaf

    set bad_groups {}
    set repairable_groups {}
    set details {}
    set checked 0
    set skipped_structural 0

    foreach rec $records {
        lassign $rec group wt_l_name cell_name wt_r_name
        if {[llength $only_groups] > 0 && ![info exists wanted($group)]} { continue }
        incr checked

        set members {}
        foreach n [list $wt_l_name $cell_name $wt_r_name] {
            set obj [TT_2row_sdp__resolve_inst $n inst_exact inst_leaf]
            if {$obj ne ""} { lappend members $obj }
        }

        # Structural/member failures are native check_sdps ownership.
        if {[llength $members] != 3} {
            incr skipped_structural
            continue
        }

        set lb [TT_PR7__rect [lindex $members 0]]
        set cb [TT_PR7__rect [lindex $members 1]]
        set rb [TT_PR7__rect [lindex $members 2]]
        if {[llength $lb] != 4 || [llength $cb] != 4 || [llength $rb] != 4} {
            incr skipped_structural
            continue
        }

        lassign $lb lx1 ly1 lx2 ly2
        lassign $cb cx1 cy1 cx2 cy2
        lassign $rb rx1 ry1 rx2 ry2

        set gap_l [expr {double($cx1)-double($lx2)}]
        set gap_r [expr {double($rx1)-double($cx2)}]
        set issues {}

        # ONLY too-large positive gaps are custom violations.
        if {$gap_l > $max_gap + $tol} { lappend issues "left_gap" }
        if {$gap_r > $max_gap + $tol} { lappend issues "right_gap" }

        if {[llength $issues] != 0} {
            lappend bad_groups $group
            lappend repairable_groups $group
            # Preserve legacy detail keys for downstream consumers.
            lappend details [dict create \
                group $group issues $issues \
                gap_l $gap_l gap_r $gap_r \
                foreign_l {} foreign_r {}]

            if {$verbose} {
                puts [format "PR7_GAP_VIOLATION group=%s gap_l=%s gap_r=%s issues={%s}" \
                    $group $gap_l $gap_r [join $issues { }]]
            }
        }
    }

    set result [dict create \
        checked $checked \
        violations [llength $bad_groups] \
        groups $bad_groups \
        repairable_groups $repairable_groups \
        details $details \
        skipped_structural $skipped_structural \
        max_gap $max_gap \
        mode GAP_ONLY]

    if {$verbose} {
        puts "INFO: PR7 GAP-ONLY scan: checked=$checked gap_violations=[llength $bad_groups] structural_skipped=$skipped_structural allowed_positive_gap<=${max_gap}um"
        puts "INFO: membership/order/overlap/foreign/place-legality/interleaving are owned by native check_sdps."
    }
    if {$highlight} { TT_PR7__highlight_result $result }
    return $result
}

proc TT_PR7_verify_sdp {sdp_name} {
    set base [regsub {_ROW$} $sdp_name ""]
    set result [TT_PR7_scan_internal_sdp_structure true true [list $base]]
    if {[dict get $result checked] == 0} {
        puts "WARN: PR7 verifier did not find canonical SDP '$sdp_name'."
    }
    return $result
}

# =============================================================================
# R9.5 GAP-ONLY CELL-reanchor internal-gap repair
#
# Proven on SDP2R_00068_ROW in Innovus 21.19:
#   1) Keep TT_SDP_SWKO_* active.
#   2) Put a one-WellTap HARD TT_PR7_GAPBLK_* at each bad CELL's current center.
#   3) Temporarily enlarge member side padding to TT_PR7_CELL_REANCHOR_PAD_SITES sites
#      WT_L/WT_R stay fixed; only bad
#      middle CELLs are movable. Freeze all unrelated currently placed/soft_fixed
#      instances and run ONE place_detail for the whole round.
#   4) FIX each relocated CELL.
#   5) Re-anchor each SDP with the original flow formula:
#         origin = {CELL.x - WellTap.width, CELL.y}
#      set_sdp_origin is allowed to move WT_L/WT_R, but the CELL itself MUST NOT
#      move.  Any CELL movement is classified UNSAFE and is never rolled back by
#      set_sdp_origin.
#   6) Restore exact pre-repair padding for WT_L/CELL/WT_R, validate custom
#      WT_L/CELL/WT_R geometry and targeted native check_sdps.
#   7) PASS groups delete their own TT_PR7_GAPBLK_* immediately.  Unresolved
#      groups retain cumulative old/new-CELL-center GAPBLKs and retry next round.
#      After the bounded final round, remaining GAPBLKs stay visible through
#      suspend and are removed by the existing post-resume owned-BLK cleanup.
#
# The main SDP flow, native full check_sdps, one-time suspend, SWKO ownership,
# and original downstream add_well_taps.tcl remain unchanged.
# =============================================================================

if {![info exists ::TT_PR7_GAPBLK_PREFIX]} { set ::TT_PR7_GAPBLK_PREFIX "TT_PR7_GAPBLK_" }
if {![info exists ::TT_PR7_GAPBLK_FALLBACK_W]} { set ::TT_PR7_GAPBLK_FALLBACK_W [::tech_mv_private_value {run/tool/02_powerplan/TT_refine_internal_gap_sdps.tcl::::TT_PR7_GAPBLK_FALLBACK_W::L245}] }
if {![info exists ::TT_PR7_GAPBLK_FALLBACK_H]} { set ::TT_PR7_GAPBLK_FALLBACK_H [::tech_mv_private_value {run/tool/02_powerplan/TT_refine_internal_gap_sdps.tcl::::TT_PR7_GAPBLK_FALLBACK_H::L246}] }
if {![info exists ::TT_PR7_GAPBLK_MAX_TRIALS]} { set ::TT_PR7_GAPBLK_MAX_TRIALS [::tech_mv_private_value {run/tool/02_powerplan/TT_refine_internal_gap_sdps.tcl::::TT_PR7_GAPBLK_MAX_TRIALS::L247}] }
if {![info exists ::TT_PR7_GAPBLK_NAME_MAX_REVISIONS]} { set ::TT_PR7_GAPBLK_NAME_MAX_REVISIONS [::tech_mv_private_value {run/tool/02_powerplan/TT_refine_internal_gap_sdps.tcl::::TT_PR7_GAPBLK_NAME_MAX_REVISIONS::L248}] }
if {![info exists ::TT_PR7_CELL_REANCHOR_PAD_SITES]} { set ::TT_PR7_CELL_REANCHOR_PAD_SITES 8 }

proc TT_PR7__group_record {group_name} {
    set base [regsub {_ROW$} $group_name ""]
    foreach rec [TT_2row_sdp__flat_group_records] {
        if {[lindex $rec 0] eq $base} { return $rec }
    }
    return {}
}

proc TT_PR7__resolve_group_triplet {group_name} {
    set rec [TT_PR7__group_record $group_name]
    if {[llength $rec] != 4} {
        return [dict create ok false reason "canonical record not found" group [regsub {_ROW$} $group_name ""]]
    }

    lassign $rec group wt_l_name cell_name wt_r_name
    catch {array unset inst_exact}
    catch {array unset inst_leaf}
    TT_2row_sdp__build_inst_lookup inst_exact inst_leaf

    set wt_l [TT_2row_sdp__resolve_inst $wt_l_name inst_exact inst_leaf]
    set cell [TT_2row_sdp__resolve_inst $cell_name inst_exact inst_leaf]
    set wt_r [TT_2row_sdp__resolve_inst $wt_r_name inst_exact inst_leaf]
    if {$wt_l eq "" || $cell eq "" || $wt_r eq ""} {
        return [dict create ok false reason "cannot resolve canonical WT_L/CELL/WT_R" group $group]
    }

    set row_name "${group}_ROW"
    set sdp_obj ""
    foreach s [get_db top_sdps] {
        set n ""
        catch {set n [get_db $s .name]}
        if {$n eq $row_name} { set sdp_obj $s; break }
    }
    if {$sdp_obj eq ""} {
        return [dict create ok false reason "live SDP row not found" group $group row $row_name]
    }

    return [dict create ok true reason "" group $group row $row_name sdp $sdp_obj \
        wt_l $wt_l cell $cell wt_r $wt_r members [list $wt_l $cell $wt_r]]
}

proc TT_PR7__gapblk_geometry {group_name} {
    set t [TT_PR7__resolve_group_triplet $group_name]
    if {![dict get $t ok]} { return $t }

    set cb [TT_PR7__rect [dict get $t cell]]
    set wb [TT_PR7__rect [dict get $t wt_l]]
    if {[llength $cb] != 4} {
        dict set t ok false
        dict set t reason "CELL bbox unavailable"
        return $t
    }

    lassign $cb cx1 cy1 cx2 cy2
    set center_x [expr {($cx1 + $cx2) / 2.0}]
    set center_y [expr {($cy1 + $cy2) / 2.0}]

    set tap_w $::TT_PR7_GAPBLK_FALLBACK_W
    set tap_h $::TT_PR7_GAPBLK_FALLBACK_H
    if {[llength $wb] == 4} {
        lassign $wb wx1 wy1 wx2 wy2
        set dw [expr {$wx2 - $wx1}]
        set dh [expr {$wy2 - $wy1}]
        if {$dw > $::TT_PR7_INTERNAL_GAP_TOL} { set tap_w $dw }
        if {$dh > $::TT_PR7_INTERNAL_GAP_TOL} { set tap_h $dh }
    }

    set hx [expr {$tap_w / 2.0}]
    set hy [expr {$tap_h / 2.0}]
    set bbox [list \
        [format %.6f [expr {$center_x - $hx}]] \
        [format %.6f [expr {$center_y - $hy}]] \
        [format %.6f [expr {$center_x + $hx}]] \
        [format %.6f [expr {$center_y + $hy}]]]

    dict set t cell_bbox $cb
    dict set t cell_center [list [format %.6f $center_x] [format %.6f $center_y]]
    dict set t tap_width [format %.6f $tap_w]
    dict set t tap_height [format %.6f $tap_h]
    dict set t blockage_bbox $bbox
    dict set t blockage_name "${::TT_PR7_GAPBLK_PREFIX}[dict get $t group]"
    return $t
}

proc TT_PR7__place_blks_matching {pattern} {
    set out {}
    foreach b [get_db place_blockages] {
        set n ""
        catch {set n [get_db $b .name]}
        if {$n ne "" && [string match $pattern $n]} { lappend out $b }
    }
    return $out
}

proc TT_PR7__owned_gapblk_names {} {
    set names {}
    foreach b [TT_PR7__place_blks_matching "${::TT_PR7_GAPBLK_PREFIX}*"] {
        set n ""
        catch {set n [get_db $b .name]}
        if {$n ne ""} { lappend names $n }
    }
    return [lsort -unique $names]
}

proc TT_PR7__group_gapblk_names {group_name} {
    set g [regsub {_ROW$} $group_name ""]
    set names {}
    foreach b [TT_PR7__place_blks_matching "${::TT_PR7_GAPBLK_PREFIX}${g}_T*"] {
        set n ""
        catch {set n [get_db $b .name]}
        if {$n ne ""} { lappend names $n }
    }
    return [lsort -unique $names]
}

proc TT_PR7__unique_gapblk_name {group_name trial} {
    set g [regsub {_ROW$} $group_name ""]
    set stem "${::TT_PR7_GAPBLK_PREFIX}${g}_T[format %02d $trial]"
    set max_rev $::TT_PR7_GAPBLK_NAME_MAX_REVISIONS
    if {![string is integer -strict $max_rev] || $max_rev < 1} { set max_rev 1 }

    for {set rev 1} {$rev <= $max_rev} {incr rev} {
        if {$rev == 1} {
            set name $stem
        } else {
            set name "${stem}_R[format %02d $rev]"
        }
        set objs {}
        catch {set objs [get_db place_blockages $name]}
        if {[llength $objs] == 0} { return $name }
    }
    error "cannot allocate unique GAPBLK name for $g trial=$trial after $max_rev revisions"
}

proc TT_PR7_gap_block_preview {sdp_name} {
    set t [TT_PR7__gapblk_geometry $sdp_name]
    puts ""
    puts "======================================================================"
    puts " PR7 R9 CELL-REANCHOR GAP-BLOCK PREVIEW (READ-ONLY)"
    puts "======================================================================"
    if {![dict get $t ok]} {
        puts "ERROR: [dict get $t reason]"
        return $t
    }
    set preview_name [TT_PR7__unique_gapblk_name [dict get $t group] 1]
    puts "SDP row        : [dict get $t row]"
    puts "CELL           : [get_db [dict get $t cell] .name]"
    puts "CELL bbox      : [dict get $t cell_bbox]"
    puts "CELL center    : [dict get $t cell_center]"
    puts "WellTap size   : [dict get $t tap_width] x [dict get $t tap_height] um"
    puts "Next BLK name  : $preview_name"
    puts "Temp BLK bbox  : [dict get $t blockage_bbox]"
    puts "Temp padding   : WT_L/CELL/WT_R left/right $::TT_PR7_CELL_REANCHOR_PAD_SITES sites (exact originals restored afterward)"
    puts "R9 policy      : PASS deletes this group's GAPBLK(s); unresolved retains them until next round/suspend"
    puts "Mutation       : NONE"
    puts "======================================================================"
    dict set t preview_blockage_name $preview_name
    return $t
}

proc TT_PR7__delete_exact_gapblk {name} {
    if {![string match "${::TT_PR7_GAPBLK_PREFIX}*" $name]} {
        error "refuse to delete non-PR7 blockage '$name'"
    }
    set objs {}
    catch {set objs [get_db place_blockages $name]}
    if {[llength $objs] == 0} { return 0 }
    delete_obj $objs
    puts "INFO: deleted PR7 gap blockage: $name"
    return [llength $objs]
}

proc TT_PR7__delete_group_gapblks {group_name} {
    set names [TT_PR7__group_gapblk_names $group_name]
    set deleted 0
    foreach n $names { incr deleted [TT_PR7__delete_exact_gapblk $n] }
    set remain [TT_PR7__group_gapblk_names $group_name]
    if {[llength $remain] != 0} {
        error "group GAPBLK cleanup failed for $group_name: $remain"
    }
    return $deleted
}

proc TT_PR7__create_gapblk {name bbox} {
    if {[llength [info commands create_place_blockage]] == 0} {
        error "create_place_blockage is unavailable"
    }

    set existing {}
    catch {set existing [get_db place_blockages $name]}
    if {[llength $existing] != 0} {
        error "placement blockage '$name' already exists"
    }

    set obj ""
    set rc [catch {
        set obj [create_place_blockage -name $name -type hard -rects [list $bbox]]
    } err]
    if {$rc != 0} {
        puts "WARN: create_place_blockage -type hard failed for $name: $err"
        puts "INFO: retrying create_place_blockage without explicit -type."
        set obj [create_place_blockage -name $name -rects [list $bbox]]
    }

    set live {}
    catch {set live [get_db place_blockages $name]}
    if {[llength $live] == 0} {
        error "temporary placement blockage '$name' was not created"
    }
    puts "INFO: created PR7 CELL-relocation gap blockage: $name bbox={$bbox}"
    return $live
}

proc TT_PR7__ensure_swko {} {
    set blks [TT_PR7__place_blks_matching "TT_SDP_SWKO_*"]
    if {[llength $blks] == 0} {
        if {[llength [info commands TT_SWKO_create_all_switch_keepouts]] == 0} {
            error "TT_SDP_SWKO_* absent and TT_SWKO_create_all_switch_keepouts unavailable"
        }
        puts "INFO: no TT_SDP_SWKO_* found; creating switch keepouts before CELL relocation."
        TT_SWKO_create_all_switch_keepouts
        set blks [TT_PR7__place_blks_matching "TT_SDP_SWKO_*"]
    }
    if {[llength $blks] == 0} { error "TT_SDP_SWKO_* creation/verification failed" }
    puts "INFO: TT_SDP_SWKO_* active count=[llength $blks]"
    return [llength $blks]
}

proc TT_PR7__padding_snapshot {cell} {
    set d [dict create]
    foreach {key attr} {left .left_padding right .right_padding top .top_padding bottom .bottom_padding} {
        set v ""
        if {[catch {set v [get_db $cell $attr]} err]} {
            error "cannot read $attr for [get_db $cell .name]: $err"
        }
        if {$v eq ""} { set v 0 }
        dict set d $key $v
    }
    return $d
}

proc TT_PR7__set_padding {cell pad} {
    # Innovus 21.19 rejects zero-valued arguments to set_inst_padding.
    # To set an exact per-side padding state (including zeros), first clear any
    # existing instance-padding constraint, then re-apply only strictly-positive
    # sides.  Finally verify the live DB matches the requested snapshot exactly.
    set name [get_db $cell .name]

    foreach key {left right top bottom} {
        set v [dict get $pad $key]
        if {![string is integer -strict $v] || $v < 0} {
            error "invalid padding '$key=$v' for $name; expected non-negative integer"
        }
    }

    set current [TT_PR7__padding_snapshot $cell]
    set need_clear false
    foreach key {left right top bottom} {
        if {[dict get $current $key] > 0} {
            set need_clear true
            break
        }
    }

    if {$need_clear} {
        if {[llength [info commands delete_inst_padding]] == 0} {
            error "delete_inst_padding unavailable; cannot safely clear existing padding on $name"
        }
        # Innovus 21.19 syntax is positional: delete_inst_padding <inst>.
        # The command does NOT accept -inst.
        if {[catch {delete_inst_padding $name} derr]} {
            error "delete_inst_padding failed for $name: $derr"
        }
    }

    set cmd [list set_inst_padding -inst $name]
    set positive 0
    foreach {key opt} {
        left   -left_side
        right  -right_side
        top    -top_side
        bottom -bottom_side
    } {
        set v [dict get $pad $key]
        if {$v > 0} {
            lappend cmd $opt $v
            incr positive
        }
    }

    if {$positive > 0} {
        if {[catch {uplevel #0 $cmd} serr]} {
            error "set_inst_padding failed for $name with positive-only args '$cmd': $serr"
        }
    }

    set actual [TT_PR7__padding_snapshot $cell]
    foreach key {left right top bottom} {
        set exp [dict get $pad $key]
        set got [dict get $actual $key]
        if {$got != $exp} {
            error "padding verify failed for $name side=$key expected=$exp actual=$got"
        }
    }
    return $actual
}

proc TT_PR7__apply_temp_padding {cell original} {
    set req $::TT_PR7_CELL_REANCHOR_PAD_SITES
    if {![string is integer -strict $req] || $req < 0} {
        error "invalid ::TT_PR7_CELL_REANCHOR_PAD_SITES='$req'"
    }
    set l [dict get $original left]
    set r [dict get $original right]
    if {$l < $req} { set l $req }
    if {$r < $req} { set r $req }
    set temp [dict replace $original left $l right $r]
    TT_PR7__set_padding $cell $temp
    return $temp
}

proc TT_PR7__restore_padding {cell original} {
    TT_PR7__set_padding $cell $original
}

proc TT_PR7__triplet_padding_snapshot {info} {
    set out [dict create]
    foreach role {wt_l cell wt_r} {
        set obj [dict get $info $role]
        dict set out $role [TT_PR7__padding_snapshot $obj]
    }
    return $out
}

proc TT_PR7__apply_temp_triplet_padding {info original} {
    set out [dict create]
    set applied {}
    foreach role {wt_l cell wt_r} {
        set obj [dict get $info $role]
        if {[catch {set temp [TT_PR7__apply_temp_padding $obj [dict get $original $role]]} err]} {
            # Best-effort exact restore of every triplet member on partial apply.
            foreach rr {wt_l cell wt_r} {
                if {[dict exists $original $rr]} {
                    catch {TT_PR7__restore_padding [dict get $info $rr] [dict get $original $rr]}
                }
            }
            error "temporary triplet padding failed at $role: $err"
        }
        dict set out $role $temp
        lappend applied $role
    }
    return $out
}

proc TT_PR7__restore_triplet_padding {info original} {
    set errors {}
    foreach role {wt_l cell wt_r} {
        set obj [dict get $info $role]
        if {[catch {TT_PR7__restore_padding $obj [dict get $original $role]} err]} {
            lappend errors "$role: $err"
        }
    }
    if {[llength $errors] > 0} {
        error [join $errors " ; "]
    }
    return [TT_PR7__triplet_padding_snapshot $info]
}

proc TT_PR7__remove_objs_by_name_set {objs name_list} {
    catch {array unset skip}
    foreach n $name_list { set skip($n) 1 }
    set out {}
    foreach o $objs {
        set n ""
        if {[catch {set n [get_db $o .name]}]} { continue }
        if {![info exists skip($n)]} { lappend out $o }
    }
    return $out
}

proc TT_PR7__freeze_for_detail {target_cells} {
    set names {}
    foreach c $target_cells { lappend names [get_db $c .name] }

    set old_honor "__UNSET__"
    set old_align "__UNSET__"
    catch {set old_honor [get_db place_detail_honor_inst_pad]}
    catch {set old_align [get_db place_detail_sdp_alignment_in_refine]}

    catch {set_db place_detail_honor_inst_pad true}
    catch {set_db place_detail_sdp_alignment_in_refine false}

    set placed [get_db insts -if {.place_status == placed}]
    set soft   [get_db insts -if {.place_status == soft_fixed}]
    set frozen_placed [TT_PR7__remove_objs_by_name_set $placed $names]
    set frozen_soft   [TT_PR7__remove_objs_by_name_set $soft $names]

    if {[llength $frozen_placed] > 0} { set_db $frozen_placed .place_status fixed }
    if {[llength $frozen_soft] > 0} { set_db $frozen_soft .place_status fixed }
    if {[llength $target_cells] > 0} { set_db $target_cells .place_status placed }

    return [dict create frozen_placed $frozen_placed frozen_soft $frozen_soft \
        old_honor $old_honor old_align $old_align]
}

proc TT_PR7__restore_after_detail {state target_cells} {
    if {[llength $target_cells] > 0} { catch {set_db $target_cells .place_status fixed} }
    set p [dict get $state frozen_placed]
    set s [dict get $state frozen_soft]
    if {[llength $p] > 0} { catch {set_db $p .place_status placed} }
    if {[llength $s] > 0} { catch {set_db $s .place_status soft_fixed} }

    set old_honor [dict get $state old_honor]
    set old_align [dict get $state old_align]
    if {$old_honor ne "__UNSET__"} { catch {set_db place_detail_honor_inst_pad $old_honor} }
    if {$old_align ne "__UNSET__"} { catch {set_db place_detail_sdp_alignment_in_refine $old_align} }
}


# -----------------------------------------------------------------------------
# Native check_sdps rule helpers.
#
# R9.4 can seed the CELL-reanchor engine from native SDP violations even when
# the custom WT_L/CELL/WT_R gap checker is already clean.  Only these rules are
# auto-repair candidates:
#   - Overlap
#   - PlaceLegality
#   - Interleaving
# Other native rules remain diagnostic-only and are never silently pulled into
# this repair path.
# -----------------------------------------------------------------------------
proc TT_PR7__native_rule_counts_from_text {txt} {
    set out [dict create overlap 0 place_legality 0 interleaving 0 total -1]
    foreach {key label} {
        overlap         Overlap
        place_legality  PlaceLegality
        interleaving    Interleaving
    } {
        if {[regexp -nocase [format {%s[[:space:]]+violations:[[:space:]]*([0-9]+)} $label] $txt -> n]} {
            dict set out $key $n
        }
    }
    if {[regexp -nocase {Total[[:space:]]+violations:[[:space:]]*([0-9]+)} $txt -> n]} {
        dict set out total $n
    }
    return $out
}

proc TT_PR7__native_repair_rule_hit {native_dict} {
    foreach key {overlap place_legality interleaving} {
        if {[dict exists $native_dict $key] && [dict get $native_dict $key] > 0} {
            return true
        }
    }
    return false
}

proc TT_PR7__candidate_groups_from_native_report {{rpt "./reports/02_powerplan/sdp/CHIP.checkSdp.rpt"}} {
    set groups {}
    if {![file exists $rpt]} { return $groups }

    set fh [open $rpt r]
    set txt [read $fh]
    close $fh

    foreach rec [TT_2row_sdp__flat_group_records] {
        lassign $rec group wt_l_name cell_name wt_r_name
        set row "${group}_ROW"
        set hit false

        # Prefer the canonical row name when native report prints it.
        if {[string first $row $txt] >= 0} {
            set hit true
        }

        # Some Innovus reports identify only member instances.  Match both the
        # canonical recorded name and its leaf name without regexp expansion.
        if {!$hit} {
            foreach n [list $wt_l_name $cell_name $wt_r_name] {
                if {$n eq ""} { continue }
                if {[string first $n $txt] >= 0} {
                    set hit true
                    break
                }
                set leaf [file tail $n]
                if {$leaf ne "" && [string first $leaf $txt] >= 0} {
                    set hit true
                    break
                }
            }
        }

        if {$hit} { lappend groups $group }
    }
    return [lsort -unique $groups]
}

proc TT_PR7__all_canonical_groups {} {
    set groups {}
    foreach rec [TT_2row_sdp__flat_group_records] {
        lappend groups [lindex $rec 0]
    }
    return [lsort -unique $groups]
}

proc TT_PR7__native_overlap_seed_groups {{rpt "./reports/02_powerplan/sdp/CHIP.checkSdp.rpt"}} {
    set summary [dict create overlap 0 place_legality 0 interleaving 0 total -1]
    set report_exists [file exists $rpt]
    if {$report_exists} {
        set fh [open $rpt r]
        set txt [read $fh]
        close $fh
        set summary [TT_PR7__native_rule_counts_from_text $txt]
    }

    if {$report_exists && ![TT_PR7__native_repair_rule_hit $summary]} {
        return [dict create \
            groups {} checked_groups {} source report_no_target_rules \
            report $rpt summary $summary fallback_full_scan false]
    }

    set hints [TT_PR7__candidate_groups_from_native_report $rpt]
    set to_check $hints
    set source report_hints
    set fallback false

    # If the report has target-rule violations but does not expose any canonical
    # row/member identifier, fall back to bounded targeted checks of all 234
    # canonical SDP rows.  These are targeted check_sdps calls, not another full
    # design check_sdps.
    if {[llength $to_check] == 0} {
        set to_check [TT_PR7__all_canonical_groups]
        set source targeted_all_canonical
        set fallback true
    }

    set groups {}
    set checked {}
    foreach g $to_check {
        set row "${g}_ROW"
        set n [TT_PR7__target_native_check $row]
        lappend checked $g
        if {[dict get $n check_ok] && [TT_PR7__native_repair_rule_hit $n]} {
            lappend groups $g
        }
    }

    return [dict create \
        groups [lsort -unique $groups] \
        checked_groups $checked \
        source $source \
        report $rpt \
        summary $summary \
        fallback_full_scan $fallback]
}

proc TT_PR7__target_native_check {row_name} {
    set dir "./reports/pr7_gap_refine"
    if {[info exists ::REPORT_DIR] && $::REPORT_DIR ne ""} {
        set dir [file join $::REPORT_DIR pr7_gap_refine]
    }
    file mkdir $dir
    set safe [string map {/ _ : _ \\ _} $row_name]
    set rpt [file join $dir "${safe}.checkSdp.rpt"]
    set console ""
    set rc [catch {
        redirect console {check_sdps -sdps [list $row_name] -out_file $rpt} -variable -tee
    } err]
    if {$rc != 0} {
        return [dict create \
            check_ok false ok false total -1 \
            overlap -1 place_legality -1 interleaving -1 \
            report $rpt reason $err]
    }

    set txt $console
    if {[file exists $rpt]} {
        set fh [open $rpt r]
        append txt "\n" [read $fh]
        close $fh
    }
    set counts [TT_PR7__native_rule_counts_from_text $txt]
    set total [dict get $counts total]
    dict set counts check_ok true
    dict set counts ok [expr {$total == 0}]
    dict set counts report $rpt
    dict set counts reason ""
    return $counts
}

proc TT_refine_internal_gap_sdps {{move_distance ""}} {
    if {$move_distance ne ""} {
        puts "INFO: R9.5 GAP-ONLY CELL-reanchor method ignores legacy move_distance='$move_distance'; retained for command compatibility."
    }

    foreach cmd {place_detail set_sdp_origin set_inst_padding delete_inst_padding create_place_blockage check_sdps} {
        if {[llength [info commands $cmd]] == 0} {
            puts "WARN: required command '$cmd' unavailable; PR7 R9 internal-gap repair skipped."
            return [TT_PR7_scan_internal_sdp_structure true true]
        }
    }

    set max_trials $::TT_PR7_GAPBLK_MAX_TRIALS
    if {![string is integer -strict $max_trials] || $max_trials < 1} {
        puts "WARN: invalid ::TT_PR7_GAPBLK_MAX_TRIALS='$max_trials'; forcing 1."
        set max_trials 1
    }

    set pad_sites $::TT_PR7_CELL_REANCHOR_PAD_SITES
    if {![string is integer -strict $pad_sites] || $pad_sites < 0} {
        puts "WARN: invalid ::TT_PR7_CELL_REANCHOR_PAD_SITES='$pad_sites'; forcing 8."
        set pad_sites 8
    }
    set ::TT_PR7_CELL_REANCHOR_PAD_SITES $pad_sites

    # HARD ORDERING GATE: native legality must be clean BEFORE custom GAP repair.
    set native_gate -1
    if {[llength [info commands TT_2row_sdp__check_sdps_total]] > 0} {
        set native_gate [TT_2row_sdp__check_sdps_total]
    }
    if {$native_gate != 0} {
        puts "WARN: PR7 GAP-ONLY repair DEFERRED because native check_sdps=$native_gate."
        puts "WARN: Fix native Overlap/PlaceLegality/Interleaving/etc first; custom gap repair will not move any SDP."
        set deferred [TT_PR7_scan_internal_sdp_structure true true]
        dict set deferred r9_native_gate $native_gate
        dict set deferred r9_repair_deferred true
        dict set deferred r9_defer_reason "native_check_sdps_not_clean"
        return $deferred
    }

    set before [TT_PR7_scan_internal_sdp_structure true false]
    set internal_groups [dict get $before repairable_groups]

    # R9.5 repair set is GAP-ONLY.
    # Native violations are repaired by TT_refine_violating_sdps BEFORE this
    # function. PGROW violations are repaired by TT_repair_powergate_iso_slots.
    set native_seed [dict create source DISABLED_GAP_ONLY groups {}]
    set native_groups {}
    set external_groups {}
    set groups [lsort -dictionary -unique $internal_groups]
    catch {array unset external_target}

    if {[llength $groups] == 0} {
        puts "INFO: PR7 R9.5 GAP-ONLY repair: no excessive WT_L/CELL/WT_R gap target found."
        TT_PR7__highlight_result $before
        dict set before r9_native_seed $native_seed
        dict set before r9_native_seed_groups {}
        dict set before r9_external_seed_groups {}
        return $before
    }

    puts ""
    puts "======================================================================"
    puts " PR7 INTERNAL GAP-ONLY REPAIR - R9.5 NATIVE-FIRST"
    puts "======================================================================"
    puts "Gap target groups       : [llength $groups] {$groups}"
    puts "Native target groups    : DISABLED (owned by check_sdps / TT_refine_violating_sdps)"
    puts "PGROW external targets  : DISABLED (owned by TT_repair_powergate_iso_slots)"
    puts "Max rounds              : $max_trials"
    puts "Temp padding            : WT_L/CELL/WT_R left/right >= $pad_sites sites; exact originals restored"
    puts "Round placement         : ALL unresolved GAP target CELLs together in ONE place_detail"
    puts "SW keepouts             : TT_SDP_SWKO_* kept active"
    puts "GAPBLK policy           : current CELL center -> temporary HARD BLK while unresolved"
    puts "SDP re-anchor           : origin={CELL.x-WT.width, CELL.y}"
    puts "Movement guard          : CELL must NOT move during set_sdp_origin"
    puts "Post-move native check  : targeted check_sdps remains enabled as safety validation"
    puts "======================================================================"

    if {[catch {TT_PR7__ensure_swko} swerr]} {
        puts "CRITICAL: R9 cannot establish SW keepouts: $swerr"
        set after [TT_PR7_scan_internal_sdp_structure true true]
        dict set after r9_aborted true
        dict set after r9_abort_reason $swerr
        return $after
    }

    if {[catch {
        if {[info exists ::TT_2ROW_SDP_PRE_UNPLACED_SNAPSHOT]} {
            TT_2row_sdp__prepare_background_for_repair $::TT_2ROW_SDP_PRE_UNPLACED_SNAPSHOT "PR7_R9_CELL_REANCHOR"
        } else {
            TT_2row_sdp__force_noncanonical_lp_unplaced "PR7_R9_CELL_REANCHOR"
        }
    } bgerr]} {
        puts "WARN: R9 background preparation failed: $bgerr"
    }

    catch {TT_2row_sdp__set_flat_members_fixed}
    catch {TT_2row_sdp__assert_flat_members_fixed}

    catch {array unset status}
    catch {array unset reason}
    catch {array unset trials_used}
    catch {array unset old_cell_loc}
    catch {array unset new_cell_loc}
    catch {array unset custom_vio}
    catch {array unset native_total}
    catch {array unset native_report}
    catch {array unset external_rule_ok}
    catch {array unset external_rule_reason}
    catch {array unset created_blocks}
    catch {array unset original_padding}

    set initial_groups {}
    foreach g $groups {
        set info [TT_PR7__resolve_group_triplet $g]
        if {![dict get $info ok]} {
            set status($g) SKIP
            set reason($g) [dict get $info reason]
            set trials_used($g) 0
            set old_cell_loc($g) ""
            set new_cell_loc($g) ""
            set custom_vio($g) -1
            set native_total($g) -1
            set native_report($g) ""
            set external_rule_ok($g) -1
            set external_rule_reason($g) ""
            set created_blocks($g) {}
            puts "WARN: R9 skip $g: $reason($g)"
            continue
        }
        set c [dict get $info cell]
        if {[catch {set original_padding($g) [TT_PR7__triplet_padding_snapshot $info]} perr]} {
            set status($g) SKIP
            set reason($g) "triplet padding snapshot failed: $perr"
            set trials_used($g) 0
            set old_cell_loc($g) [get_db $c .location]
            set new_cell_loc($g) $old_cell_loc($g)
            set custom_vio($g) -1
            set native_total($g) -1
            set native_report($g) ""
            set external_rule_ok($g) -1
            set external_rule_reason($g) ""
            set created_blocks($g) {}
            puts "WARN: R9 skip $g: $reason($g)"
            continue
        }
        set status($g) UNRESOLVED
        set reason($g) ""
        set trials_used($g) 0
        set old_cell_loc($g) [get_db $c .location]
        set new_cell_loc($g) $old_cell_loc($g)
        set custom_vio($g) -1
        set native_total($g) -1
        set native_report($g) ""
        set external_rule_ok($g) -1
        set external_rule_reason($g) ""
        set created_blocks($g) {}
        lappend initial_groups $g
    }

    set unresolved $initial_groups
    set global_abort false
    set global_abort_reason ""

    for {set trial 1} {$trial <= $max_trials && [llength $unresolved] > 0} {incr trial} {
        puts ""
        puts "----------------------------------------------------------------------"
        puts "R9 ROUND $trial/$max_trials unresolved=[llength $unresolved] groups={$unresolved}"

        set round_groups {}
        set round_cells {}
        set prep_failed false
        set prep_error ""

        foreach g $unresolved {
            set geom [TT_PR7__gapblk_geometry $g]
            if {![dict get $geom ok]} {
                set status($g) UNSAFE
                set reason($g) "geometry resolve failed: [dict get $geom reason]"
                puts "CRITICAL: R9 $g $reason($g)"
                continue
            }

            set c [dict get $geom cell]
            set trials_used($g) $trial
            set new_cell_loc($g) [get_db $c .location]
            set blk_name ""
            if {[catch {set blk_name [TT_PR7__unique_gapblk_name $g $trial]} nerr]} {
                set prep_failed true
                set prep_error "$g unique GAPBLK naming failed: $nerr"
                break
            }

            puts "R9 PREP group=$g row=[dict get $geom row]"
            puts "  CELL            = [get_db $c .name]"
            puts "  current CELL loc= [get_db $c .location]"
            puts "  current center  = [dict get $geom cell_center]"
            puts "  GAP BLK         = $blk_name"
            puts "  GAP BLK bbox    = [dict get $geom blockage_bbox]"
            puts "  original triplet padding= $original_padding($g)"

            if {[catch {TT_PR7__create_gapblk $blk_name [dict get $geom blockage_bbox]} berr]} {
                set prep_failed true
                set prep_error "$g GAPBLK create failed: $berr"
                break
            }
            lappend created_blocks($g) $blk_name

            set pad_info [TT_PR7__resolve_group_triplet $g]
            if {![dict get $pad_info ok]} {
                set prep_failed true
                set prep_error "$g triplet resolve failed before temporary padding: [dict get $pad_info reason]"
                break
            }
            if {[catch {set temp_pad [TT_PR7__apply_temp_triplet_padding $pad_info $original_padding($g)]} perr]} {
                catch {TT_PR7__restore_triplet_padding $pad_info $original_padding($g)}
                set prep_failed true
                set prep_error "$g temporary triplet padding failed: $perr"
                break
            }
            puts "  temporary triplet pad = $temp_pad"
            lappend round_groups $g
            lappend round_cells $c
        }

        if {$prep_failed} {
            foreach g $round_groups {
                set info [TT_PR7__resolve_group_triplet $g]
                if {[dict get $info ok]} { catch {TT_PR7__restore_triplet_padding $info $original_padding($g)} }
            }
            set global_abort true
            set global_abort_reason $prep_error
            puts "CRITICAL: R9 round preparation failed: $prep_error"
            break
        }

        if {[llength $round_groups] == 0} {
            puts "WARN: R9 no safe group remains for round $trial."
            break
        }

        set detail_state ""
        if {[catch {set detail_state [TT_PR7__freeze_for_detail $round_cells]} ferr]} {
            foreach g $round_groups {
                set info [TT_PR7__resolve_group_triplet $g]
                if {[dict get $info ok]} { catch {TT_PR7__restore_triplet_padding $info $original_padding($g)} }
            }
            set global_abort true
            set global_abort_reason "background freeze failed: $ferr"
            puts "CRITICAL: R9 $global_abort_reason"
            break
        }

        puts "INFO: R9 place_detail round $trial: movable target CELL count=[llength $round_cells]"
        puts "INFO: frozen placed=[llength [dict get $detail_state frozen_placed]] soft_fixed=[llength [dict get $detail_state frozen_soft]]"
        set place_rc [catch {place_detail} place_err]
        TT_PR7__restore_after_detail $detail_state $round_cells

        if {$place_rc != 0} {
            foreach g $round_groups {
                set info [TT_PR7__resolve_group_triplet $g]
                if {[dict get $info ok]} { catch {TT_PR7__restore_triplet_padding $info $original_padding($g)} }
                set status($g) ABORTED
                set reason($g) "place_detail failed: $place_err"
            }
            set global_abort true
            set global_abort_reason "place_detail failed: $place_err"
            puts "CRITICAL: R9 place_detail failed; no origin rollback attempted."
            break
        }

        catch {TT_2row_sdp__set_flat_members_fixed}
        catch {TT_2row_sdp__assert_flat_members_fixed}

        set next_unresolved {}
        foreach g $round_groups {
            set info [TT_PR7__resolve_group_triplet $g]
            if {![dict get $info ok]} {
                set status($g) UNSAFE
                set reason($g) "post-place resolve failed: [dict get $info reason]"
                puts "CRITICAL: R9 $g $reason($g)"
                continue
            }

            set row [dict get $info row]
            set sdp [dict get $info sdp]
            set wl [dict get $info wt_l]
            set c [dict get $info cell]
            set wr [dict get $info wt_r]

            set cell_before [TT_PR7__point2 [get_db $c .location]]
            set cell_bbox_before [TT_PR7__rect $c]
            set wt_l_before [TT_PR7__point2 [get_db $wl .location]]
            set wt_r_before [TT_PR7__point2 [get_db $wr .location]]
            set new_cell_loc($g) $cell_before

            set wb [TT_PR7__rect $wl]
            if {[llength $wb] != 4 || [llength $cell_before] != 2} {
                catch {TT_PR7__restore_triplet_padding $info $original_padding($g)}
                set status($g) UNSAFE
                set reason($g) "cannot derive live CELL/WT geometry for re-anchor"
                puts "CRITICAL: R9 $g $reason($g)"
                continue
            }
            lassign $wb wlx1 wly1 wlx2 wly2
            set wt_w [expr {$wlx2 - $wlx1}]
            lassign $cell_before cx cy
            set target_origin [list [expr {$cx - $wt_w}] $cy]
            lassign $target_origin tx ty

            puts ""
            puts "R9 REANCHOR group=$g row=$row"
            puts "  CELL after place_detail = $cell_before"
            puts "  WT width                = $wt_w"
            puts "  old SDP origin          = [get_db $sdp .location]"
            puts "  target SDP origin       = $target_origin"

            set origin_rc [catch {set_sdp_origin -sdp $row -location $tx $ty} origin_err]

            # Re-anchor first, then restore exact original padding on all three
            # SDP members. WT_L/WT_R temporary padding participates in place_detail
            # as fixed placement spacing, but must not leak into final validation.
            if {[catch {TT_PR7__restore_triplet_padding $info $original_padding($g)} rperr]} {
                puts "CRITICAL: R9 $g failed to restore original triplet padding: $rperr"
                set status($g) UNSAFE
                set reason($g) "triplet padding restore failed: $rperr"
                set global_abort true
                if {$global_abort_reason eq ""} { set global_abort_reason $reason($g) }
                continue
            }

            if {$origin_rc != 0} {
                set status($g) UNSAFE
                set reason($g) "set_sdp_origin failed: $origin_err"
                puts "CRITICAL: R9 $g $reason($g)"
                puts "CRITICAL: no set_sdp_origin rollback attempted."
                continue
            }

            set cell_after [TT_PR7__point2 [get_db $c .location]]
            set cell_bbox_after [TT_PR7__rect $c]
            set wt_l_after [TT_PR7__point2 [get_db $wl .location]]
            set wt_r_after [TT_PR7__point2 [get_db $wr .location]]
            set actual_origin [TT_PR7__point2 [get_db $sdp .location]]

            puts "  WT_L before -> after    = $wt_l_before -> $wt_l_after"
            puts "  CELL before -> after    = $cell_before -> $cell_after"
            puts "  WT_R before -> after    = $wt_r_before -> $wt_r_after"
            puts "  actual SDP origin       = $actual_origin"
            puts "  original triplet padding restored= $original_padding($g)"

            set cell_moved [expr {![TT_PR7__same_point $cell_before $cell_after $::TT_PR7_INTERNAL_GAP_TOL] || ![TT_PR7__same_bbox $cell_bbox_before $cell_bbox_after $::TT_PR7_INTERNAL_GAP_TOL]}]
            if {$cell_moved} {
                set status($g) UNSAFE
                set reason($g) "CELL moved during set_sdp_origin"
                puts "CRITICAL: R9 $g CELL moved during set_sdp_origin."
                puts "CRITICAL: WT movement is allowed; CELL movement is NOT."
                puts "CRITICAL: no set_sdp_origin rollback attempted."
                continue
            }

            if {![TT_PR7__same_point $actual_origin $target_origin $::TT_PR7_INTERNAL_GAP_TOL]} {
                set status($g) UNSAFE
                set reason($g) "SDP origin verify failed: expected=$target_origin actual=$actual_origin"
                puts "CRITICAL: R9 $g $reason($g)"
                continue
            }

            catch {TT_2row_sdp__set_flat_members_fixed}
            catch {TT_2row_sdp__assert_flat_members_fixed}

            set custom [TT_PR7_scan_internal_sdp_structure true false [list $g]]
            set custom_vio($g) [dict get $custom violations]
            set native [TT_PR7__target_native_check $row]
            set native_total($g) [dict get $native total]
            set native_report($g) [dict get $native report]

            # Optional external PASS gate. It applies ONLY to groups explicitly
            # injected through ::TT_PR7_EXTRA_REPAIR_GROUPS.
            set external_rule_ok($g) 1
            set external_rule_reason($g) ""
            if {[info exists external_target($g)] && [info exists ::TT_PR7_EXTRA_REPAIR_CHECK_CMD] && [llength $::TT_PR7_EXTRA_REPAIR_CHECK_CMD] > 0} {
                set _ext_cmd $::TT_PR7_EXTRA_REPAIR_CHECK_CMD
                set _ext_rc [catch {
                    set external_rule_ok($g) [uplevel #0 [linsert $_ext_cmd end $g]]
                } _ext_err]
                if {$_ext_rc != 0} {
                    set external_rule_ok($g) 0
                    set external_rule_reason($g) "external rule callback failed: $_ext_err"
                } elseif {!$external_rule_ok($g)} {
                    set external_rule_reason($g) "external rule still violated"
                }
                unset -nocomplain _ext_cmd _ext_rc _ext_err
            }

            if {$custom_vio($g) == 0 && [dict get $native ok] && $external_rule_ok($g)} {
                set status($g) PASS
                set reason($g) ""
                set deleted 0
                if {[catch {set deleted [TT_PR7__delete_group_gapblks $g]} derr]} {
                    set status($g) UNSAFE
                    set reason($g) "PASS geometry but GAPBLK cleanup failed: $derr"
                    puts "CRITICAL: R9 $g $reason($g)"
                } else {
                    puts "PASS: R9 $g legal after round $trial: custom_gap=0 native_check_sdps=0"
                    puts "INFO: deleted $deleted CELL-relocation GAPBLK object(s) for PASS group $g"
                }
            } else {
                set status($g) UNRESOLVED
                set reason($g) "custom_gap=$custom_vio($g) native_total=$native_total($g) overlap=[dict get $native overlap] place_legality=[dict get $native place_legality] interleaving=[dict get $native interleaving] external_ok=$external_rule_ok($g) external_reason={$external_rule_reason($g)}"
                lappend next_unresolved $g
                puts "WARN: R9 $g round $trial unresolved: $reason($g)"
                puts "INFO: cumulative GAPBLKs retained for next round: [TT_PR7__group_gapblk_names $g]"
            }
        }

        set unresolved $next_unresolved
        if {$global_abort} {
            puts "CRITICAL: R9 stops before another placement round because a non-recoverable guard/restore failure occurred."
            break
        }
        if {[llength $unresolved] > 0 && $trial == $max_trials} {
            puts "WARN: R9 reached bounded max rounds ($max_trials); unresolved GAPBLKs remain for suspend/manual review."
        }
    }

    catch {TT_2row_sdp__set_flat_members_fixed}
    catch {TT_2row_sdp__assert_flat_members_fixed}

    if {$global_abort} {
        foreach g $unresolved {
            if {![info exists status($g)] || $status($g) eq "UNRESOLVED"} {
                set status($g) ABORTED
                set reason($g) $global_abort_reason
            }
        }
    }

    set results {}
    set repaired 0
    set unresolved_count 0
    set unsafe_count 0
    foreach g $groups {
        if {![info exists status($g)]} {
            set status($g) SKIP
            set reason($g) "no state"
            set trials_used($g) 0
            set old_cell_loc($g) ""
            set new_cell_loc($g) ""
            set custom_vio($g) -1
            set native_total($g) -1
            set native_report($g) ""
            set external_rule_ok($g) -1
            set external_rule_reason($g) ""
            set created_blocks($g) {}
        }
        if {$status($g) eq "PASS"} {
            incr repaired
        } else {
            incr unresolved_count
            if {$status($g) eq "UNSAFE" || $status($g) eq "ABORTED"} { incr unsafe_count }
        }
        set active [TT_PR7__group_gapblk_names $g]
        lappend results [dict create \
            group $g \
            status $status($g) \
            reason $reason($g) \
            trials $trials_used($g) \
            old_cell_loc $old_cell_loc($g) \
            new_cell_loc $new_cell_loc($g) \
            custom_violations $custom_vio($g) \
            native_total $native_total($g) \
            report $native_report($g) \
            external_rule_ok $external_rule_ok($g) \
            external_rule_reason $external_rule_reason($g) \
            created_blocks $created_blocks($g) \
            retained_blocks $active]
    }

    set after [TT_PR7_scan_internal_sdp_structure true true]
    set retained_all [TT_PR7__owned_gapblk_names]

    dict set after r9_cell_reanchor_results $results
    dict set after r9_native_seed $native_seed
    dict set after r9_internal_seed_groups $internal_groups
    dict set after r9_native_seed_groups $native_groups
    dict set after r9_external_seed_groups $external_groups
    dict set after r9_repaired $repaired
    dict set after r9_unresolved $unresolved_count
    dict set after r9_guard_failures $unsafe_count
    dict set after r9_aborted $global_abort
    dict set after r9_abort_reason $global_abort_reason
    dict set after r9_retained_gapblks $retained_all
    # Compatibility aliases for existing debug consumers.
    dict set after r8_gapblk_results $results
    dict set after r8_repaired $repaired
    dict set after r8_unresolved $unresolved_count
    dict set after r8_aborted $global_abort
    dict set after r8_retained_gapblks $retained_all
    dict set after r7_gapblk_results $results
    dict set after r7_repaired $repaired
    dict set after r7_unresolved $unresolved_count
    dict set after r7_aborted $global_abort

    puts ""
    puts "======================================================================"
    puts " R9 CELL-REANCHOR REPAIR SUMMARY"
    puts "======================================================================"
    puts "before internal violations : [dict get $before violations]"
    puts "native seed groups          : [llength $native_groups] {$native_groups}"
    puts "repaired          : $repaired"
    puts "unresolved/unsafe : $unresolved_count"
    puts "guard failures    : $unsafe_count"
    puts "global abort      : $global_abort"
    if {$global_abort_reason ne ""} { puts "abort reason      : $global_abort_reason" }
    puts "after violations  : [dict get $after violations]"
    puts "retained GAP BLKs : [llength $retained_all]"
    puts "SWKO lifetime     : retained through suspend; existing post-resume cleanup owns TT_SDP_SWKO_*"
    puts "GAPBLK lifetime   : PASS deletes immediately; unresolved retained through suspend"
    puts "padding policy    : WT_L/CELL/WT_R temp left/right padding; exact original triplet padding restored after every re-anchor attempt"
    puts "set_sdp_origin    : used only after CELL place_detail; WT motion allowed, CELL motion forbidden"
    puts "place_sdps        : NOT used by R9 internal-gap repair"
    puts "native full check : existing flow check_sdps remains enabled / unchanged"
    puts "======================================================================"
    return $after
}


# =============================================================================
# PR7 origin synchronization
#
# Confirmed root cause on SDP2R_00146_ROW:
#   stale SDP origin  = {old_origin_x old_origin_y}
#   actual member LL  = {member_llx member_lly}
#   DELTA Y           = member_lly - old_origin_y
#
# After set_sdp_origin to the actual member-envelope lower-left, targeted
# check_sdps returned 0 total violations / 0 interleaving violations.
#
# Policy:
#   - only canonical SDP2R_*_ROW groups from the flat [WT_L][CELL][WT_R] table
#   - origin := actual 3-member envelope lower-left
#   - never call place_sdps here
#   - snapshot and compare member .location/.bbox before/after every origin edit
#   - restore member place_status if set_sdp_origin changes only the status
#   - report ANY coordinate drift as CRITICAL before the existing suspend
#   - existing native check_sdps calls are NOT removed or bypassed
# =============================================================================

if {![info exists ::TT_PR7_ORIGIN_SYNC_TOL]} {
    set ::TT_PR7_ORIGIN_SYNC_TOL [::tech_mv_private_value {run/tool/02_powerplan/TT_refine_internal_gap_sdps.tcl::::TT_PR7_ORIGIN_SYNC_TOL::L1391}]
}

proc TT_PR7__point2 {value} {
    set p $value
    while {[llength $p] == 1} {
        set n [lindex $p 0]
        if {$n eq $p} { break }
        set p $n
    }
    if {[llength $p] != 2} { return {} }
    foreach v $p {
        if {![string is double -strict $v]} { return {} }
    }
    return $p
}

proc TT_PR7__same_point {a b {tol ""}} {
    if {$tol eq ""} { set tol $::TT_PR7_ORIGIN_SYNC_TOL }
    set a [TT_PR7__point2 $a]
    set b [TT_PR7__point2 $b]
    if {[llength $a] != 2 || [llength $b] != 2} { return false }
    lassign $a ax ay
    lassign $b bx by
    return [expr {abs($ax-$bx) <= $tol && abs($ay-$by) <= $tol}]
}

proc TT_PR7__same_bbox {a b {tol ""}} {
    if {$tol eq ""} { set tol $::TT_PR7_ORIGIN_SYNC_TOL }
    set a [TT_2row_sdp__bbox4 $a]
    set b [TT_2row_sdp__bbox4 $b]
    if {[llength $a] != 4 || [llength $b] != 4} { return false }
    for {set i 0} {$i < 4} {incr i} {
        if {abs([lindex $a $i]-[lindex $b $i]) > $tol} { return false }
    }
    return true
}

proc TT_PR7__sdp_map {} {
    set out [dict create]
    foreach s [get_db top_sdps] {
        set n ""
        catch {set n [get_db $s .name]}
        if {$n ne ""} { dict set out $n $s }
    }
    return $out
}

proc TT_PR7_scan_sdp_origin_delta {{verbose true}} {
    set tol $::TT_PR7_ORIGIN_SYNC_TOL
    set records [TT_2row_sdp__flat_group_records]
    set sdp_map [TT_PR7__sdp_map]

    catch {array unset inst_exact}
    catch {array unset inst_leaf}
    TT_2row_sdp__build_inst_lookup inst_exact inst_leaf

    set checked 0
    set mismatches 0
    set skipped 0
    set groups {}
    set details {}
    set max_abs_dx 0.0
    set max_abs_dy 0.0

    foreach rec $records {
        lassign $rec group wt_l_name cell_name wt_r_name
        set row_name "${group}_ROW"
        incr checked

        if {![dict exists $sdp_map $row_name]} {
            incr skipped
            if {$verbose} { puts "WARN: PR7 origin scan missing SDP row: $row_name" }
            continue
        }

        set members {}
        set missing false
        foreach n [list $wt_l_name $cell_name $wt_r_name] {
            set obj [TT_2row_sdp__resolve_inst $n inst_exact inst_leaf]
            if {$obj eq ""} {
                set missing true
                break
            }
            lappend members $obj
        }
        if {$missing || [llength $members] != 3} {
            incr skipped
            if {$verbose} { puts "WARN: PR7 origin scan cannot resolve all 3 canonical members: $row_name" }
            continue
        }

        set first true
        set minx 0.0
        set miny 0.0
        set maxx 0.0
        set maxy 0.0
        set bbox_ok true
        foreach obj $members {
            set b [TT_PR7__rect $obj]
            if {[llength $b] != 4} {
                set bbox_ok false
                break
            }
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
        if {!$bbox_ok || $first} {
            incr skipped
            if {$verbose} { puts "WARN: PR7 origin scan cannot read canonical member bbox: $row_name" }
            continue
        }

        set sdp_obj [dict get $sdp_map $row_name]

        # Origin sync is only valid for the canonical flat 3-member row.
        # If side-tap finalization or any other edit has changed the live SDP
        # membership, leave it completely untouched.
        set live_members [get_db $sdp_obj .insts]
        set membership_ok [expr {[llength $live_members] == 3}]
        if {$membership_ok} {
            for {set i 0} {$i < 3} {incr i} {
                if {![TT_2row_sdp__same_obj [lindex $live_members $i] [lindex $members $i]]} {
                    set membership_ok false
                    break
                }
            }
        }
        if {!$membership_ok} {
            incr skipped
            if {$verbose} { puts "INFO: PR7 origin scan skips non-canonical live membership: $row_name" }
            continue
        }

        set origin [TT_PR7__point2 [get_db $sdp_obj .location]]
        if {[llength $origin] != 2} {
            incr skipped
            if {$verbose} { puts "WARN: PR7 origin scan cannot read SDP origin: $row_name" }
            continue
        }
        lassign $origin sx sy

        set dx [expr {$minx-$sx}]
        set dy [expr {$miny-$sy}]
        set adx [expr {abs($dx)}]
        set ady [expr {abs($dy)}]
        if {$adx > $max_abs_dx} { set max_abs_dx $adx }
        if {$ady > $max_abs_dy} { set max_abs_dy $ady }

        if {$adx > $tol || $ady > $tol} {
            incr mismatches
            lappend groups $row_name
            lappend details [dict create \
                group $group \
                row $row_name \
                sdp_obj $sdp_obj \
                members $members \
                old_origin $origin \
                target_origin [list $minx $miny] \
                envelope [list $minx $miny $maxx $maxy] \
                dx $dx dy $dy]
            if {$verbose} {
                puts [format \
                    "PR7_ORIGIN_MISMATCH row=%s old={%.6f %.6f} member_ll={%.6f %.6f} delta={%.6f %.6f}" \
                    $row_name $sx $sy $minx $miny $dx $dy]
            }
        }
    }

    set result [dict create \
        checked $checked \
        mismatches $mismatches \
        skipped $skipped \
        groups $groups \
        details $details \
        max_abs_dx $max_abs_dx \
        max_abs_dy $max_abs_dy]

    if {$verbose} {
        puts "INFO: PR7 SDP origin scan: checked=$checked mismatches=$mismatches skipped=$skipped max_abs_dx=$max_abs_dx max_abs_dy=$max_abs_dy"
    }
    return $result
}

proc TT_PR7_sync_sdp_origins {} {
    set tol $::TT_PR7_ORIGIN_SYNC_TOL

    puts ""
    puts "======================================================================"
    puts " PR7 SDP ORIGIN SYNC + MEMBER COORDINATE GUARD"
    puts "======================================================================"
    puts "Policy            : SDP origin := actual canonical member-envelope LL"
    puts "Placement action  : NONE (no place_sdps / no unplace / no move command)"
    puts "Coordinate guard  : compare every member location + bbox before/after"
    puts "Status policy     : restore original member place_status if changed"
    puts "Native check_sdps : preserved by the existing caller; NOT removed"
    puts "======================================================================"

    if {[llength [info commands set_sdp_origin]] == 0} {
        puts "ERROR: set_sdp_origin is unavailable. Origin synchronization skipped."
        set r [dict create checked 0 mismatches_before 0 synchronized 0 failed 1 coordinate_shift_groups {} status_restored 0 remaining_mismatches -1]
        set ::TT_PR7_ORIGIN_SYNC_RESULT $r
        return $r
    }

    set before [TT_PR7_scan_sdp_origin_delta true]
    set details [dict get $before details]
    set synchronized 0
    set failed 0
    set status_restored 0
    set coordinate_shift_groups {}
    set synchronized_groups {}

    foreach d $details {
        set row_name [dict get $d row]
        set sdp_obj [dict get $d sdp_obj]
        set members [dict get $d members]
        set old_origin [dict get $d old_origin]
        set target_origin [dict get $d target_origin]
        lassign $target_origin tx ty

        set snapshots {}
        foreach obj $members {
            set n [get_db $obj .name]
            lappend snapshots [dict create \
                obj $obj \
                name $n \
                location [TT_PR7__point2 [get_db $obj .location]] \
                bbox [TT_PR7__rect $obj] \
                status [get_db $obj .place_status]]
        }

        puts [format \
            "INFO: PR7 origin sync %-20s old={%.6f %.6f} -> new={%.6f %.6f}" \
            $row_name [lindex $old_origin 0] [lindex $old_origin 1] $tx $ty]

        if {[catch {
            set_sdp_origin -sdp $row_name -location $tx $ty
        } err]} {
            puts "ERROR: set_sdp_origin failed for $row_name: $err"
            incr failed
            continue
        }

        # set_sdp_origin may alter place_status semantics.  Preserve the exact
        # pre-sync status, because this PR7 step is metadata synchronization,
        # not a placement ownership change.
        foreach snap $snapshots {
            set obj [dict get $snap obj]
            set old_status [dict get $snap status]
            set new_status [get_db $obj .place_status]
            if {$new_status ne $old_status} {
                if {[catch {set_db $obj .place_status $old_status} status_err]} {
                    puts "WARN: cannot restore place_status for [dict get $snap name]: $status_err"
                    incr failed
                } else {
                    incr status_restored
                }
            }
        }

        set drift false
        foreach snap $snapshots {
            set obj [dict get $snap obj]
            set n [dict get $snap name]
            set old_loc [dict get $snap location]
            set old_bbox [dict get $snap bbox]
            set new_loc [TT_PR7__point2 [get_db $obj .location]]
            set new_bbox [TT_PR7__rect $obj]

            if {![TT_PR7__same_point $old_loc $new_loc $tol] || ![TT_PR7__same_bbox $old_bbox $new_bbox $tol]} {
                puts "CRITICAL: PR7 origin sync changed physical member coordinates: $row_name / $n"
                puts "          old location = $old_loc"
                puts "          new location = $new_loc"
                puts "          old bbox     = $old_bbox"
                puts "          new bbox     = $new_bbox"
                set drift true
            }
        }

        set new_origin [TT_PR7__point2 [get_db $sdp_obj .location]]
        if {![TT_PR7__same_point $new_origin $target_origin $tol]} {
            puts "ERROR: $row_name origin verify failed: expected=$target_origin actual=$new_origin"
            incr failed
        } else {
            incr synchronized
            lappend synchronized_groups $row_name
        }

        if {$drift} {
            lappend coordinate_shift_groups $row_name
        }
    }

    set coordinate_shift_groups [lsort -unique $coordinate_shift_groups]
    set synchronized_groups [lsort -unique $synchronized_groups]
    set after [TT_PR7_scan_sdp_origin_delta true]

    set r [dict create \
        checked [dict get $before checked] \
        mismatches_before [dict get $before mismatches] \
        synchronized $synchronized \
        synchronized_groups $synchronized_groups \
        failed $failed \
        coordinate_shift_groups $coordinate_shift_groups \
        status_restored $status_restored \
        remaining_mismatches [dict get $after mismatches] \
        max_abs_dx_after [dict get $after max_abs_dx] \
        max_abs_dy_after [dict get $after max_abs_dy]]

    set ::TT_PR7_ORIGIN_SYNC_RESULT $r

    puts ""
    puts "======================================================================"
    puts " PR7 SDP ORIGIN SYNC SUMMARY"
    puts "======================================================================"
    puts "Canonical groups checked : [dict get $r checked]"
    puts "Origin mismatches before : [dict get $r mismatches_before]"
    puts "Origins synchronized     : [dict get $r synchronized]"
    puts "Origin sync failures     : [dict get $r failed]"
    puts "Status values restored   : [dict get $r status_restored]"
    puts "Coordinate-shift groups  : [llength [dict get $r coordinate_shift_groups]]"
    puts "Origin mismatches after  : [dict get $r remaining_mismatches]"
    puts "Max |delta X| after      : [dict get $r max_abs_dx_after] um"
    puts "Max |delta Y| after      : [dict get $r max_abs_dy_after] um"
    if {[llength [dict get $r coordinate_shift_groups]] == 0} {
        puts "COORDINATE GUARD         : PASS - member locations/bboxes did not move"
    } else {
        puts "COORDINATE GUARD         : CRITICAL REVIEW REQUIRED"
        puts "Shifted groups           : [dict get $r coordinate_shift_groups]"
    }
    puts "======================================================================"

    return $r
}

proc TT_PR7_pre_checkpoint {phase allow_refine} {
    puts ""
    puts "======================================================================"
    puts " PR7 PRE-CHECKPOINT GAP-ONLY CHECK - R9.5"
    puts "======================================================================"
    puts "Phase              : $phase"
    puts "Native-first gate  : custom gap movement requires check_sdps=0"
    puts "SW HARD keep-outs  : unchanged / preserved"
    puts "Custom ownership   : ONLY excessive WT_L->CELL / CELL->WT_R gap"
    puts "Native ownership   : membership/order/overlap/place-legality/interleaving/etc"

    set native_total -1
    if {[llength [info commands TT_2row_sdp__check_sdps_total]] > 0} {
        set native_total [TT_2row_sdp__check_sdps_total]
    }

    if {$allow_refine && $native_total == 0} {
        puts "Auto action #1     : native clean -> run GAP-ONLY TT_refine_internal_gap_sdps"
        set r [TT_refine_internal_gap_sdps]
    } else {
        if {$allow_refine} {
            puts "Auto action #1     : DEFER GAP repair because native check_sdps=$native_total"
        } else {
            puts "Auto action #1     : no 3-member custom re-place in this phase"
        }
        set r [TT_PR7_scan_internal_sdp_structure true true]
        dict set r r9_repair_deferred true
        dict set r r9_native_gate $native_total
    }

    # Read-only origin consistency scan only.
    set origin_scan [TT_PR7_scan_sdp_origin_delta true]
    dict set r origin_scan $origin_scan
    dict set r origin_sync [dict create mode READ_ONLY_AUTO_DISABLED scan $origin_scan]

    if {[dict get $origin_scan mismatches] != 0} {
        puts "WARN: R9.5 sees [dict get $origin_scan mismatches] SDP origin mismatch(es); inspect before resume."
    }
    if {[dict exists $r r9_guard_failures] && [dict get $r r9_guard_failures] > 0} {
        puts "CRITICAL: R9.5 recorded [dict get $r r9_guard_failures] unsafe/aborted repair group(s); inspect before resume."
    }

    dict set r coordinate_guided [dict create enabled false reason "R9.5 uses GAP-only batched CELL place_detail; coordinate auto path retired"]

    if {[llength [info commands TT_sdp_post_resume_arm]] > 0} {
        set post_resume_armed [TT_sdp_post_resume_arm]
        dict set r post_resume_cleanup_armed $post_resume_armed
    } else {
        puts "WARN: TT_sdp_post_resume_arm unavailable; automatic post-resume BLK cleanup not armed."
        dict set r post_resume_cleanup_armed false
    }

    puts "======================================================================"
    return $r
}

puts "INFO: Loaded PR7 R9.5 internal-gap-only SDP checker + triplet-padding CELL place_detail / guarded SDP re-anchor repair helper."
puts "INFO: CHECK : TT_PR7_scan_internal_sdp_structure true true"
puts "INFO: CHECK : TT_PR7_verify_sdp SDP2R_00066_ROW"
puts "INFO: CHECK : TT_PR7_scan_sdp_origin_delta true"
puts "INFO: REPAIR: TT_refine_internal_gap_sdps  ; batched CELL place_detail + guarded SDP re-anchor, max-round bounded"
puts "INFO: ORIGIN: repair re-anchors only repaired rows; global origin scan remains read-only"
puts "INFO: LATE  : coordinate-guided auto repair retired from R9 normal path"
puts "INFO: ALL   : TT_sdp_check_all (custom + native unified check, after toolbox autoload)"
puts "INFO: HELP  : TT_sdp_tools"

# =============================================================================
# PR7 manual-move origin-sync tool autoload
#
# The normal flow reaches suspend with this helper already loaded.  Source the
# sibling manual tool here so a user who moves an SDP member/group in the GUI
# can immediately resynchronize the logical SDP origin without re-running the
# placement flow.
# =============================================================================
set _tt_pr7_manual_tool [file join [file dirname [file normalize [info script]]] sdp TT_PR7_manual_sdp_origin.tcl]
if {[file exists $_tt_pr7_manual_tool]} {
    if {[llength [info commands TT_PR7_manual_sync_origin]] == 0} {
        source $_tt_pr7_manual_tool
    }
} else {
    puts "WARN: PR7 manual origin-sync tool not found: $_tt_pr7_manual_tool"
}
unset _tt_pr7_manual_tool

# =============================================================================
# PR7 late coordinate-guided custom repair autoload
# =============================================================================
set _tt_pr7_coord_tool [file join [file dirname [file normalize [info script]]] sdp TT_PR7_coordinate_guided_repair.tcl]
if {[file exists $_tt_pr7_coord_tool]} {
    if {[llength [info commands TT_PR7_coordinate_guided_auto_repair]] == 0} {
        source $_tt_pr7_coord_tool
    }
} else {
    puts "WARN: PR7 coordinate-guided repair tool not found: $_tt_pr7_coord_tool"
}
unset _tt_pr7_coord_tool


# =============================================================================
# R4 unified SDP toolbox autoload
# =============================================================================
set _tt_sdp_toolbox [file join [file dirname [file normalize [info script]]] sdp TT_sdp_toolbox.tcl]
if {[file exists $_tt_sdp_toolbox]} {
    if {[llength [info commands TT_sdp_check_all]] == 0} {
        source $_tt_sdp_toolbox
    }
} else {
    puts "WARN: unified SDP toolbox not found: $_tt_sdp_toolbox"
}
unset _tt_sdp_toolbox


# =============================================================================
# R5 post-resume cleanup autoload
# =============================================================================
set _tt_sdp_post_resume_tool [file join $::TECH_MV_RUNTIME_ROOT .. script PR TECH_MV script 02_powerplan sdp sdp_post_resume.tcl]
if {[file exists $_tt_sdp_post_resume_tool]} {
    if {[llength [info commands TT_sdp_post_resume_arm]] == 0} {
        source $_tt_sdp_post_resume_tool
    }
} else {
    puts "WARN: SDP post-resume cleanup tool not found: $_tt_sdp_post_resume_tool"
}
unset _tt_sdp_post_resume_tool
