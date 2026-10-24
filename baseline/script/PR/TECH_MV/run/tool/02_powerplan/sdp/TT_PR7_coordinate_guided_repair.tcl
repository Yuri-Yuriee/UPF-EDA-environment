# Runtime adapter preserves the historical logical source path.
if {[info exists ::TECH_MV_RUNTIME_ROOT]} {
    info script [file join $::TECH_MV_RUNTIME_ROOT run/tool/02_powerplan/sdp/TT_PR7_coordinate_guided_repair.tcl]
}
# PUBLIC_EXPORT_REVIEW_REQUIRED: residual technology candidates require manual review.
# Load private values before evaluating original parameter defaults.
if {![llength [info commands ::tech_mv_private_value]]} { source [file join $::TECH_MV_RUNTIME_ROOT .. script PR TECH_MV script 00_common private_parameter_config.tcl] }
# =============================================================================
# TT_PR7_coordinate_guided_repair.tcl
# TECH_MV / PR7 late custom SDP repair
# R6 SAFE HOTFIX: coordinate search remains read-only by default; physical apply is explicitly gated
# Innovus 21.19 Stylus / Common UI
#
# PURPOSE
#   Repair ONLY the custom 3-member SDP geometry violations that remain AFTER
#   native SDP legality is already clean.
#
# HARD GATE
#   Native check_sdps total MUST be 0 before this tool is allowed to move any
#   SDP.  If native legality is not clean, this tool is read-only and returns.
#
# METHOD
#   1. Get the custom bad SDP groups from TT_PR7_scan_internal_sdp_structure.
#   2. Keep only pure geometry issues that this tool understands.
#   3. Search nearby legal candidate SDP origins on real placement rows.
#   4. Before trying a candidate, reserve enough room for
#          [WT_L] + gap + [CELL] + gap + [WT_R]
#      and require the reserved footprint to:
#        - fit real rows/site,
#        - remain inside the CELL's Power Domain,
#        - avoid ALL placement blockages (including TT_SDP_SWKO_*),
#        - avoid ALL placed/fixed/soft_fixed/cover foreign instances,
#        - keep TT_PR7_COORD_SWITCH_GAP_UM clearance from every recognized power switch.
#   5. R6 safety policy: candidate search is PREVIEW-ONLY in normal flow.
#      R5 proved that set_sdp_origin may physically move SDP members when used
#      as a remote placement anchor, and the old rollback path could move them
#      again.  Therefore no coordinate-guided physical trial runs by default.
#   6. Existing proven TT_refine_internal_gap_sdps remains the automatic gap
#      repair path. Residual groups are left for checkpoint/manual inspection.
#   7. Manual/experimental coordinate apply is hard-gated OFF unless the user
#      explicitly sets ::TT_PR7_COORD_APPLY_ENABLE true in Innovus.
#
# FAIL-SAFE POLICY
#   - Unknown/missing geometry => do not move.
#   - Structural SDP issues => do not move.
#   - No legal candidate => leave the SDP unchanged for suspend/manual review.
#   - This tool never deletes blockages, instances, SDP groups, or reports.
# =============================================================================

if {![info exists ::TT_PR7_INTERNAL_GAP_MAX_UM]} { set ::TT_PR7_INTERNAL_GAP_MAX_UM [::tech_mv_private_value {run/tool/02_powerplan/TT_PR7_coordinate_guided_repair.tcl::::TT_PR7_INTERNAL_GAP_MAX_UM::L43}] }
if {![info exists ::TT_PR7_COORD_ENABLE]} { set ::TT_PR7_COORD_ENABLE true }
if {![info exists ::TT_PR7_COORD_AUTO_ENABLE]} { set ::TT_PR7_COORD_AUTO_ENABLE false }
if {![info exists ::TT_PR7_COORD_APPLY_ENABLE]} { set ::TT_PR7_COORD_APPLY_ENABLE false }
if {![info exists ::TT_PR7_COORD_SITE_PITCH_UM]} { set ::TT_PR7_COORD_SITE_PITCH_UM [::tech_mv_private_value {run/tool/02_powerplan/TT_PR7_coordinate_guided_repair.tcl::::TT_PR7_COORD_SITE_PITCH_UM::L47}] }
if {![info exists ::TT_PR7_COORD_MAX_X_SHIFT_UM]} { set ::TT_PR7_COORD_MAX_X_SHIFT_UM 100.0 }
if {![info exists ::TT_PR7_COORD_MAX_Y_SHIFT_UM]} { set ::TT_PR7_COORD_MAX_Y_SHIFT_UM 20.0 }
if {![info exists ::TT_PR7_COORD_PLACE_SDP_MAX_MOVE_UM]} { set ::TT_PR7_COORD_PLACE_SDP_MAX_MOVE_UM 5.0 }
if {![info exists ::TT_PR7_COORD_MAX_TRIALS_PER_GROUP]} { set ::TT_PR7_COORD_MAX_TRIALS_PER_GROUP 60 }
if {![info exists ::TT_PR7_COORD_TOL]} { set ::TT_PR7_COORD_TOL [::tech_mv_private_value {run/tool/02_powerplan/TT_PR7_coordinate_guided_repair.tcl::::TT_PR7_COORD_TOL::L52}] }
if {![info exists ::TT_PR7_COORD_SWITCH_GAP_UM]} { set ::TT_PR7_COORD_SWITCH_GAP_UM [::tech_mv_private_value {run/tool/02_powerplan/TT_PR7_coordinate_guided_repair.tcl::::TT_PR7_COORD_SWITCH_GAP_UM::L53}] }
if {![info exists ::TT_PR7_COORD_ALLOWED_ISSUES]} {
    set ::TT_PR7_COORD_ALLOWED_ISSUES {
        left_gap right_gap left_overlap right_overlap left_foreign right_foreign
    }
}

proc TT_PR7_COORD__bool {v} {
    set x [string tolower [string trim $v]]
    return [expr {$x in {1 true yes on}}]
}

proc TT_PR7_COORD__point2 {raw} {
    set p $raw
    while {[llength $p] == 1} {
        set q [lindex $p 0]
        if {$q eq $p} { break }
        set p $q
    }
    if {[llength $p] != 2} { return {} }
    foreach v $p {
        if {![string is double -strict $v]} { return {} }
    }
    return [list [expr {double([lindex $p 0])}] [expr {double([lindex $p 1])}]]
}

proc TT_PR7_COORD__rect4 {raw} {
    set r $raw
    while {[llength $r] == 1} {
        set q [lindex $r 0]
        if {$q eq $r} { break }
        set r $q
    }
    if {[llength $r] == 4} {
        set out {}
        set ok true
        foreach v $r {
            if {![string is double -strict $v]} { set ok false; break }
            lappend out [expr {double($v)}]
        }
        if {$ok} { return $out }
    }

    # Common-UI rect DPO fallback.
    set llx ""; set lly ""; set urx ""; set ury ""
    if {![catch {set llx [get_db $raw .ll.x]}] &&
        ![catch {set lly [get_db $raw .ll.y]}] &&
        ![catch {set urx [get_db $raw .ur.x]}] &&
        ![catch {set ury [get_db $raw .ur.y]}]} {
        foreach v [list $llx $lly $urx $ury] {
            if {![string is double -strict $v]} { return {} }
        }
        return [list [expr {double($llx)}] [expr {double($lly)}] [expr {double($urx)}] [expr {double($ury)}]]
    }

    set ll ""; set ur ""
    if {![catch {set ll [TT_PR7_COORD__point2 [get_db $raw .ll]]}] &&
        ![catch {set ur [TT_PR7_COORD__point2 [get_db $raw .ur]]}] &&
        [llength $ll] == 2 && [llength $ur] == 2} {
        return [concat $ll $ur]
    }
    return {}
}

proc TT_PR7_COORD__positive_overlap {a b {tol ""}} {
    if {$tol eq ""} { set tol $::TT_PR7_COORD_TOL }
    set a [TT_PR7_COORD__rect4 $a]
    set b [TT_PR7_COORD__rect4 $b]
    if {[llength $a] != 4 || [llength $b] != 4} { return false }
    lassign $a ax1 ay1 ax2 ay2
    lassign $b bx1 by1 bx2 by2
    set xov [expr {min($ax2,$bx2)-max($ax1,$bx1)}]
    set yov [expr {min($ay2,$by2)-max($ay1,$by1)}]
    return [expr {$xov > $tol && $yov > $tol}]
}

proc TT_PR7_COORD__rect_inside {inner outer {tol ""}} {
    if {$tol eq ""} { set tol $::TT_PR7_COORD_TOL }
    set i [TT_PR7_COORD__rect4 $inner]
    set o [TT_PR7_COORD__rect4 $outer]
    if {[llength $i] != 4 || [llength $o] != 4} { return false }
    lassign $i ix1 iy1 ix2 iy2
    lassign $o ox1 oy1 ox2 oy2
    return [expr {$ix1 >= $ox1-$tol && $iy1 >= $oy1-$tol && $ix2 <= $ox2+$tol && $iy2 <= $oy2+$tol}]
}

proc TT_PR7_COORD__same_point {a b {tol ""}} {
    if {$tol eq ""} { set tol $::TT_PR7_COORD_TOL }
    set a [TT_PR7_COORD__point2 $a]
    set b [TT_PR7_COORD__point2 $b]
    if {[llength $a] != 2 || [llength $b] != 2} { return false }
    return [expr {abs([lindex $a 0]-[lindex $b 0]) <= $tol && abs([lindex $a 1]-[lindex $b 1]) <= $tol}]
}

proc TT_PR7_COORD__same_rect {a b {tol ""}} {
    if {$tol eq ""} { set tol $::TT_PR7_COORD_TOL }
    set a [TT_PR7_COORD__rect4 $a]
    set b [TT_PR7_COORD__rect4 $b]
    if {[llength $a] != 4 || [llength $b] != 4} { return false }
    for {set i 0} {$i < 4} {incr i} {
        if {abs([lindex $a $i]-[lindex $b $i]) > $tol} { return false }
    }
    return true
}

proc TT_PR7_COORD__inst_pd_name {inst} {
    # Innovus Common UI compatibility: some releases expose the Power Domain
    # as an object on .power_domain, while others expose a direct name.  Do
    # not require chained .power_domain.name, because that was the R4 failure
    # mode on builds where chained attributes are not accepted for inst.
    set pd {}
    if {![catch {set pd [get_db $inst .power_domain]}] && [llength $pd] > 0} {
        set pd [lindex $pd 0]
        set n ""
        if {![catch {set n [get_db $pd .name]}] && $n ne ""} { return $n }
        set raw [string trim $pd]
        if {[string match "power_domain:*" $raw]} {
            set raw [string range $raw [string length "power_domain:"] end]
            # Handles power_domain:CHIP/PD_CPU as well as power_domain:PD_CPU.
            return [lindex [split $raw "/"] end]
        }
        if {$raw ne ""} { return [lindex [split $raw "/"] end] }
    }
    set n ""
    if {![catch {set n [get_db $inst .power_domain_name]}] && $n ne ""} { return $n }
    return ""
}

proc TT_PR7_COORD__resolve_group {name} {
    set row $name
    if {![string match "*_ROW" $row]} { append row "_ROW" }
    if {![string match "SDP2R_*_ROW" $row]} {
        return [dict create ok false reason "not SDP2R_*_ROW" row $row]
    }

    set sdp ""
    foreach s [get_db top_sdps] {
        if {[get_db $s .name] eq $row} { set sdp $s; break }
    }
    if {$sdp eq ""} { return [dict create ok false reason "SDP row not found" row $row] }

    set members [get_db $sdp .insts]
    if {[llength $members] != 3} {
        return [dict create ok false reason "live SDP member count != 3" row $row]
    }

    # Verify canonical record and canonical order.  Never guess a structural SDP.
    set base [regsub {_ROW$} $row ""]
    set rec_found false
    set canon_names {}
    foreach rec [TT_2row_sdp__flat_group_records] {
        lassign $rec g wl cc wr
        if {$g eq $base} {
            set rec_found true
            set canon_names [list $wl $cc $wr]
            break
        }
    }
    if {!$rec_found} { return [dict create ok false reason "canonical flat record not found" row $row] }

    catch {array unset inst_exact}
    catch {array unset inst_leaf}
    TT_2row_sdp__build_inst_lookup inst_exact inst_leaf
    set canon {}
    foreach n $canon_names {
        set o [TT_2row_sdp__resolve_inst $n inst_exact inst_leaf]
        if {$o eq ""} { return [dict create ok false reason "canonical member missing: $n" row $row] }
        lappend canon $o
    }
    for {set i 0} {$i < 3} {incr i} {
        if {![TT_2row_sdp__same_obj [lindex $members $i] [lindex $canon $i]]} {
            return [dict create ok false reason "live member order differs from canonical WT_L/CELL/WT_R" row $row]
        }
    }

    set boxes {}
    set minx ""; set miny ""; set maxx ""; set maxy ""
    foreach o $members {
        set b [TT_PR7_COORD__rect4 [get_db $o .bbox]]
        if {[llength $b] != 4} { return [dict create ok false reason "member bbox unreadable" row $row] }
        lappend boxes $b
        lassign $b x1 y1 x2 y2
        if {$minx eq ""} {
            set minx $x1; set miny $y1; set maxx $x2; set maxy $y2
        } else {
            set minx [expr {min($minx,$x1)}]
            set miny [expr {min($miny,$y1)}]
            set maxx [expr {max($maxx,$x2)}]
            set maxy [expr {max($maxy,$y2)}]
        }
    }

    set origin [TT_PR7_COORD__point2 [get_db $sdp .location]]
    if {[llength $origin] != 2} { return [dict create ok false reason "SDP origin unreadable" row $row] }

    set pd_name [TT_PR7_COORD__inst_pd_name [lindex $members 1]]
    if {$pd_name eq ""} {
        return [dict create ok false reason "CELL Power Domain unavailable through .power_domain/.power_domain_name; fail closed" row $row]
    }
    foreach o $members {
        set op [TT_PR7_COORD__inst_pd_name $o]
        if {$op ne "" && $op ne $pd_name} {
            return [dict create ok false reason "canonical members resolve to different Power Domains" row $row]
        }
    }

    set site_name ""
    catch {set site_name [get_db [lindex $members 1] .base_cell.site.name]}
    if {$site_name eq ""} {
        return [dict create ok false reason "CELL base_cell.site.name unavailable; fail closed" row $row]
    }

    return [dict create ok true row $row group $base sdp $sdp members $members boxes $boxes \
        envelope [list $minx $miny $maxx $maxy] origin $origin pd_name $pd_name site_name $site_name]
}

proc TT_PR7_COORD__member_dimensions {ctx} {
    set widths {}
    set heights {}
    foreach b [dict get $ctx boxes] {
        lassign $b x1 y1 x2 y2
        lappend widths [expr {$x2-$x1}]
        lappend heights [expr {$y2-$y1}]
    }
    return [list $widths $heights]
}

proc TT_PR7_COORD__pd_rects {pd_name} {
    # First use the physical group name directly.  In this flow the physical
    # groups are PD_TOP / PD_CPU / PD_WDT / PD_CPU_ALWY_ON / PD_core.  This is
    # more robust than relying on nested -if {.power_domain.name == ...}.
    set grps {}
    catch {set grps [get_db groups $pd_name]}
    if {[llength $grps] != 1} {
        # Compatibility fallback for builds that support nested filters.
        catch {set grps [get_db groups -if [format {.power_domain.name == "%s"} $pd_name]]}
    }
    if {[llength $grps] != 1} {
        return [dict create ok false reason "Power Domain '$pd_name' maps to [llength $grps] physical groups" rects {}]
    }
    set rects {}
    set raw_rects ""
    if {[catch {set raw_rects [get_db [lindex $grps 0] .rects]} err]} {
        return [dict create ok false reason "Power Domain rect query failed: $err" rects {}]
    }
    foreach rr $raw_rects {
        set r [TT_PR7_COORD__rect4 $rr]
        if {[llength $r] == 4} { lappend rects $r }
    }
    if {[llength $rects] == 0} {
        return [dict create ok false reason "Power Domain '$pd_name' has no readable physical rectangles" rects {}]
    }
    return [dict create ok true reason "" rects $rects]
}

proc TT_PR7_COORD__row_rects {site_name} {
    set out {}
    set rows ""
    if {[catch {set rows [get_db rows]} err]} {
        return [dict create ok false reason "row query failed: $err" rows {}]
    }
    foreach row $rows {
        set s ""
        catch {set s [get_db $row .site.name]}
        if {$s ne $site_name} { continue }
        set r ""
        # Row geometry attribute differs across Innovus/Common-UI releases.
        # Prefer .rect, then fall back to .bbox and .box.
        foreach attr {.rect .bbox .box} {
            if {![catch {set raw [get_db $row $attr]}]} {
                set r [TT_PR7_COORD__rect4 $raw]
                if {[llength $r] == 4} { break }
            }
        }
        if {[llength $r] != 4} { continue }
        lappend out [list $row $r]
    }
    if {[llength $out] == 0} {
        return [dict create ok false reason "no readable rows for site '$site_name'" rows {}]
    }
    return [dict create ok true reason "" rows $out]
}

proc TT_PR7_COORD__inside_pd {bbox pd_rects} {
    foreach r $pd_rects {
        if {[TT_PR7_COORD__rect_inside $bbox $r]} { return true }
    }
    return false
}

proc TT_PR7_COORD__row_span_ok {bbox row_recs} {
    # Require the complete vertical footprint to be covered by real row
    # rectangles that each span the complete candidate X interval.  This works
    # for 2-row cells without assuming a hard-coded row height.
    set tol $::TT_PR7_COORD_TOL
    lassign $bbox x1 y1 x2 y2
    set intervals {}
    foreach rec $row_recs {
        lassign $rec row r
        lassign $r rx1 ry1 rx2 ry2
        if {$x1 < $rx1-$tol || $x2 > $rx2+$tol} { continue }
        if {$ry2 <= $y1+$tol || $ry1 >= $y2-$tol} { continue }
        lappend intervals [list $ry1 $ry2]
    }
    if {[llength $intervals] == 0} { return false }
    set intervals [lsort -real -index 0 $intervals]
    set covered $y1
    foreach iv $intervals {
        lassign $iv a b
        if {$a > $covered+$tol} { continue }
        if {$b > $covered} { set covered $b }
        if {$covered >= $y2-$tol} { return true }
    }
    return false
}

proc TT_PR7_COORD__blockage_hits {bbox} {
    # Use Innovus' spatial query instead of scanning every blockage for every
    # candidate.  place_blockage includes the TT_SDP_SWKO_* hard keepouts.
    set blks {}
    if {[catch {
        set blks [get_obj_in_area -area $bbox -obj_type place_blockage -overlap_only]
    } err]} {
        return [dict create ok false reason "place_blockage area query failed: $err" hits {}]
    }

    set hits {}
    foreach blk $blks {
        set name ""
        catch {set name [get_db $blk .name]}
        set raw {}
        if {[catch {set raw [get_db $blk .rects]}]} { continue }
        foreach rr $raw {
            set r [TT_PR7_COORD__rect4 $rr]
            if {[llength $r] != 4} { continue }
            if {[TT_PR7_COORD__positive_overlap $bbox $r]} {
                lappend hits [list $name $r]
            }
        }
    }
    return [dict create ok true reason "" hits $hits]
}

proc TT_PR7_COORD__foreign_hits {bbox members} {
    set hits {}
    set objs {}
    if {[catch {
        set objs [get_obj_in_area -area $bbox -obj_type inst -overlap_only]
    } err]} {
        return [dict create ok false reason "get_obj_in_area failed: $err" hits {}]
    }
    foreach o $objs {
        if {[lsearch -exact $members $o] >= 0} { continue }
        set b ""
        catch {set b [TT_PR7_COORD__rect4 [get_db $o .bbox]]}
        if {[llength $b] != 4} { continue }
        if {[TT_PR7_COORD__positive_overlap $bbox $b]} {
            lappend hits $o
        }
    }
    return [dict create ok true reason "" hits $hits]
}


# -----------------------------------------------------------------------------
# R4 strict candidate occupancy model
#
# Candidate acceptance is based on the COMPLETE placement occupancy around the
# search window, not only on a best-effort area query.  This is intentionally
# conservative because the late repair must never choose a point that overlaps
# a power switch, another placed instance, or any placement blockage.
# -----------------------------------------------------------------------------
proc TT_PR7_COORD__occupies_placement {status} {
    set s [string tolower [string trim $status]]
    return [expr {$s in {placed fixed soft_fixed cover}}]
}

proc TT_PR7_COORD__is_power_switch {inst} {
    set flag false
    if {![catch {set flag [get_db $inst .base_cell.is_power_switch]}]} {
        set f [string tolower [string trim $flag]]
        if {$f in {1 true yes on}} { return true }
    }

    set name ""
    catch {set name [get_db $inst .name]}
    set prefixes {}
    if {[info exists ::POWER_SWITCH_INSTANCE_PREFIXES] &&
        [llength $::POWER_SWITCH_INSTANCE_PREFIXES] > 0} {
        set prefixes $::POWER_SWITCH_INSTANCE_PREFIXES
    } else {
        set prefixes {PD_CPU_SW PD_WDT_SW}
    }
    foreach prefix $prefixes {
        if {[string match "*${prefix}*" $name]} { return true }
    }
    return false
}

proc TT_PR7_COORD__expand_rect {bbox margin} {
    set b [TT_PR7_COORD__rect4 $bbox]
    if {[llength $b] != 4 || ![string is double -strict $margin]} { return {} }
    lassign $b x1 y1 x2 y2
    set m [expr {double($margin)}]
    return [list [expr {$x1-$m}] [expr {$y1-$m}] [expr {$x2+$m}] [expr {$y2+$m}]]
}

proc TT_PR7_COORD__touch_or_overlap {a b {tol ""}} {
    if {$tol eq ""} { set tol $::TT_PR7_COORD_TOL }
    set a [TT_PR7_COORD__rect4 $a]
    set b [TT_PR7_COORD__rect4 $b]
    if {[llength $a] != 4 || [llength $b] != 4} { return false }
    lassign $a ax1 ay1 ax2 ay2
    lassign $b bx1 by1 bx2 by2
    return [expr {!($ax2 < $bx1-$tol || $bx2 < $ax1-$tol ||
                    $ay2 < $by1-$tol || $by2 < $ay1-$tol)}]
}

proc TT_PR7_COORD__build_local_occupancy {search_bbox} {
    set search_bbox [TT_PR7_COORD__rect4 $search_bbox]
    if {[llength $search_bbox] != 4} {
        return [dict create ok false reason "invalid occupancy search bbox"]
    }

    # ALL placement blockages, regardless of hard/soft/partial type.  The user
    # policy for this late repair is stricter than Innovus soft-blockage usage:
    # a coordinate candidate is rejected on any positive-area overlap.
    set blockage_recs {}
    set all_blks {}
    if {[catch {set all_blks [get_db place_blockages]} err]} {
        return [dict create ok false reason "cannot enumerate ALL placement blockages: $err"]
    }
    foreach blk $all_blks {
        set name ""; set type ""
        catch {set name [get_db $blk .name]}
        catch {set type [get_db $blk .type]}
        set raw {}
        if {[catch {set raw [get_db $blk .rects]}]} { continue }
        foreach rr $raw {
            set r [TT_PR7_COORD__rect4 $rr]
            if {[llength $r] != 4} { continue }
            if {[TT_PR7_COORD__positive_overlap $search_bbox $r]} {
                lappend blockage_recs [dict create obj $blk name $name type $type bbox $r]
            }
        }
    }

    # ALL instances that currently occupy placement.  This explicitly includes
    # fixed power switches and every placed/fixed/soft_fixed/cover cell.  Do not
    # trust candidate discovery alone to infer switch safety.
    set inst_recs {}
    set switch_recs {}
    set all_insts {}
    if {[catch {set all_insts [get_db insts]} err]} {
        return [dict create ok false reason "cannot enumerate ALL instances: $err"]
    }
    foreach inst $all_insts {
        set status ""
        catch {set status [get_db $inst .place_status]}
        if {![TT_PR7_COORD__occupies_placement $status]} { continue }
        set b {}
        catch {set b [TT_PR7_COORD__rect4 [get_db $inst .bbox]]}
        if {[llength $b] != 4} { continue }

        set is_sw [TT_PR7_COORD__is_power_switch $inst]
        set test_bbox $b
        if {$is_sw} {
            set e [TT_PR7_COORD__expand_rect $b $::TT_PR7_COORD_SWITCH_GAP_UM]
            if {[llength $e] == 4} { set test_bbox $e }
        }
        if {![TT_PR7_COORD__touch_or_overlap $search_bbox $test_bbox]} { continue }

        set name ""; set master ""
        catch {set name [get_db $inst .name]}
        catch {set master [get_db $inst .base_cell.name]}
        set rec [dict create obj $inst name $name master $master status $status bbox $b is_switch $is_sw]
        lappend inst_recs $rec
        if {$is_sw} {
            dict set rec keepout_bbox $test_bbox
            lappend switch_recs $rec
        }
    }

    return [dict create ok true reason "" \
        search_bbox $search_bbox \
        blockages $blockage_recs \
        insts $inst_recs \
        switches $switch_recs]
}

proc TT_PR7_COORD__cached_blockage_hits {bbox occupancy} {
    set hits {}
    foreach rec [dict get $occupancy blockages] {
        if {[TT_PR7_COORD__positive_overlap $bbox [dict get $rec bbox]]} {
            lappend hits $rec
        }
    }
    return $hits
}

proc TT_PR7_COORD__cached_foreign_hits {bbox members occupancy} {
    set hits {}
    foreach rec [dict get $occupancy insts] {
        set o [dict get $rec obj]
        if {[lsearch -exact $members $o] >= 0} { continue }
        if {[TT_PR7_COORD__positive_overlap $bbox [dict get $rec bbox]]} {
            lappend hits $rec
        }
    }
    return $hits
}

proc TT_PR7_COORD__cached_switch_gap_hits {bbox members occupancy} {
    set hits {}
    foreach rec [dict get $occupancy switches] {
        set o [dict get $rec obj]
        if {[lsearch -exact $members $o] >= 0} { continue }
        set kb [dict get $rec keepout_bbox]
        # Positive overlap with the expanded switch bbox means either an actual
        # switch overlap or clearance below the configured TT_PR7_COORD_SWITCH_GAP_UM.
        if {[TT_PR7_COORD__positive_overlap $bbox $kb]} {
            lappend hits $rec
        }
    }
    return $hits
}

proc TT_PR7_COORD__candidate_resources {ctx} {
    set pdr [TT_PR7_COORD__pd_rects [dict get $ctx pd_name]]
    if {![dict get $pdr ok]} { return [dict create ok false reason [dict get $pdr reason]] }
    set rr [TT_PR7_COORD__row_rects [dict get $ctx site_name]]
    if {![dict get $rr ok]} { return [dict create ok false reason [dict get $rr reason]] }

    # Keep only rows near the target SDP.  Include the possible place_sdps move
    # window because the actual legalized result may differ from the candidate
    # anchor and must still remain inside our pre-enumerated occupancy region.
    lassign [dict get $ctx envelope] ox oy ox2 oy2
    set xmargin [expr {$::TT_PR7_COORD_MAX_X_SHIFT_UM + $::TT_PR7_COORD_PLACE_SDP_MAX_MOVE_UM + 25.0}]
    set ymargin [expr {$::TT_PR7_COORD_MAX_Y_SHIFT_UM + $::TT_PR7_COORD_PLACE_SDP_MAX_MOVE_UM + 6.0}]
    set local_rows {}
    foreach rec [dict get $rr rows] {
        lassign $rec row r
        lassign $r x1 y1 x2 y2
        if {$x2 < $ox-$xmargin || $x1 > $ox2+$xmargin} { continue }
        if {$y2 < $oy-$ymargin || $y1 > $oy2+$ymargin} { continue }
        lappend local_rows $rec
    }
    if {[llength $local_rows] == 0} {
        return [dict create ok false reason "no nearby real rows for candidate search"]
    }

    set search_bbox [list [expr {$ox-$xmargin}] [expr {$oy-$ymargin}] \
                          [expr {$ox2+$xmargin}] [expr {$oy2+$ymargin}]]
    set occupancy [TT_PR7_COORD__build_local_occupancy $search_bbox]
    if {![dict get $occupancy ok]} {
        return [dict create ok false reason [dict get $occupancy reason]]
    }

    return [dict create ok true \
        pd_rects [dict get $pdr rects] \
        row_recs $local_rows \
        occupancy $occupancy \
        search_bbox $search_bbox]
}
proc TT_PR7_COORD__candidate_list {ctx resources {verbose false}} {
    set pitch $::TT_PR7_COORD_SITE_PITCH_UM
    set max_dx $::TT_PR7_COORD_MAX_X_SHIFT_UM
    set max_dy $::TT_PR7_COORD_MAX_Y_SHIFT_UM
    set tol $::TT_PR7_COORD_TOL
    set max_gap $::TT_PR7_INTERNAL_GAP_MAX_UM

    if {![string is double -strict $pitch] || $pitch <= 0.0} {
        return [dict create ok false reason "invalid TT_PR7_COORD_SITE_PITCH_UM" candidates {}]
    }

    lassign [TT_PR7_COORD__member_dimensions $ctx] widths heights
    if {[llength $widths] != 3 || [llength $heights] != 3} {
        return [dict create ok false reason "cannot derive 3-member dimensions" candidates {}]
    }
    set footprint_w [expr {[lindex $widths 0]+[lindex $widths 1]+[lindex $widths 2]+2.0*$max_gap}]
    set footprint_h [lindex $heights 1]
    foreach h $heights { if {$h > $footprint_h} { set footprint_h $h } }

    lassign [dict get $ctx envelope] old_x old_y old_x2 old_y2
    set base_x [expr {round($old_x/$pitch)*$pitch}]

    # Candidate Y values come only from real row lower edges near the current
    # physical group.  Duplicate Y values are removed.
    set yseen [dict create]
    set ylist {}
    foreach rec [dict get $resources row_recs] {
        lassign $rec row rr
        set y [lindex $rr 1]
        set dy [expr {abs($y-$old_y)}]
        if {$dy > $max_dy+$tol} { continue }
        set key [format "%.6f" $y]
        if {[dict exists $yseen $key]} { continue }
        dict set yseen $key 1
        lappend ylist [list $dy $y]
    }
    set ylist [lsort -real -index 0 $ylist]

    set nstep [expr {int(ceil($max_dx/$pitch))}]
    set xoffs {0}
    for {set i 1} {$i <= $nstep} {incr i} {
        lappend xoffs [expr {-$i*$pitch}] [expr {$i*$pitch}]
    }

    set prelim {}
    set tested_geom 0
    set rejected_pd 0
    set rejected_row 0
    set rejected_blk 0
    set rejected_switch 0

    foreach yr $ylist {
        lassign $yr dy y
        foreach dx $xoffs {
            set x [expr {$base_x+$dx}]
            if {abs($x-$old_x) > $max_dx+$tol} { continue }
            set bbox [list $x $y [expr {$x+$footprint_w}] [expr {$y+$footprint_h}]]
            incr tested_geom

            if {![TT_PR7_COORD__inside_pd $bbox [dict get $resources pd_rects]]} {
                incr rejected_pd
                continue
            }
            if {![TT_PR7_COORD__row_span_ok $bbox [dict get $resources row_recs]]} {
                incr rejected_row
                continue
            }
            set occ [dict get $resources occupancy]
            set bh [TT_PR7_COORD__cached_blockage_hits $bbox $occ]
            if {[llength $bh] != 0} {
                incr rejected_blk
                continue
            }
            set sh [TT_PR7_COORD__cached_switch_gap_hits $bbox [dict get $ctx members] $occ]
            if {[llength $sh] != 0} {
                incr rejected_switch
                continue
            }

            set score [expr {abs($x-$old_x)+abs($y-$old_y)}]
            lappend prelim [list $score $x $y $bbox]
        }
    }
    set prelim [lsort -real -index 0 $prelim]

    # Foreign-instance area query is more expensive, so run it only on the
    # geometrically legal candidates and in nearest-first order.
    set candidates {}
    set rejected_foreign 0
    set candidate_cap $::TT_PR7_COORD_MAX_TRIALS_PER_GROUP
    if {![string is integer -strict $candidate_cap] || $candidate_cap < 10} { set candidate_cap 10 }
    foreach rec $prelim {
        lassign $rec score x y bbox
        set fh [TT_PR7_COORD__cached_foreign_hits $bbox [dict get $ctx members] [dict get $resources occupancy]]
        if {[llength $fh] != 0} {
            incr rejected_foreign
            continue
        }
        lappend candidates [dict create score $score x $x y $y bbox $bbox]
        if {[llength $candidates] >= $candidate_cap} { break }
    }

    if {$verbose} {
        puts "INFO: coordinate candidate search [dict get $ctx row]:"
        puts "      reserved footprint = ${footprint_w}um x ${footprint_h}um"
        puts "      geometry tested    = $tested_geom"
        puts "      reject PD          = $rejected_pd"
        puts "      reject row/site    = $rejected_row"
        puts "      reject blockage    = $rejected_blk"
        puts "      reject SW clearance= $rejected_switch"
        puts "      reject placed cell = $rejected_foreign"
        puts "      local blockages    = [llength [dict get [dict get $resources occupancy] blockages]]"
        puts "      local placed cells = [llength [dict get [dict get $resources occupancy] insts]]"
        puts "      local switches     = [llength [dict get [dict get $resources occupancy] switches]]"
        puts "      legal candidates   = [llength $candidates]"
    }

    return [dict create ok true reason "" candidates $candidates footprint_w $footprint_w footprint_h $footprint_h \
        tested_geom $tested_geom rejected_pd $rejected_pd rejected_row $rejected_row         rejected_blk $rejected_blk rejected_switch $rejected_switch rejected_foreign $rejected_foreign]
}

proc TT_PR7_COORD__snapshot {ctx} {
    set snaps {}
    foreach o [dict get $ctx members] {
        set n [get_db $o .name]
        set loc [TT_PR7_COORD__point2 [get_db $o .location]]
        set bbox [TT_PR7_COORD__rect4 [get_db $o .bbox]]
        set orient ""; catch {set orient [get_db $o .orient]}
        set status ""; catch {set status [get_db $o .place_status]}
        lappend snaps [dict create obj $o name $n location $loc bbox $bbox orient $orient status $status]
    }
    return [dict create row [dict get $ctx row] sdp [dict get $ctx sdp] origin [dict get $ctx origin] members $snaps]
}

proc TT_PR7_COORD__restore_snapshot {snap} {
    set row [dict get $snap row]
    set sdp [dict get $snap sdp]
    set old_origin [dict get $snap origin]
    set failures 0

    # Release only the target members long enough to restore exact physical
    # coordinates.  .location/.orient are Common-UI settable placement attrs.
    foreach ms [dict get $snap members] {
        set o [dict get $ms obj]
        catch {set_db $o .place_status placed}
        if {[catch {set_db $o .location [dict get $ms location]} err]} {
            puts "CRITICAL: rollback location failed [dict get $ms name]: $err"
            incr failures
        }
        set orient [dict get $ms orient]
        if {$orient ne ""} {
            if {[catch {set_db $o .orient $orient} err]} {
                puts "CRITICAL: rollback orient failed [dict get $ms name]: $err"
                incr failures
            }
        }
    }

    if {[llength $old_origin] == 2} {
        if {[catch {set_sdp_origin -sdp $row -location [lindex $old_origin 0] [lindex $old_origin 1]} err]} {
            puts "CRITICAL: rollback SDP origin failed $row: $err"
            incr failures
        }
    }

    foreach ms [dict get $snap members] {
        set o [dict get $ms obj]
        set status [dict get $ms status]
        if {$status ne ""} {
            if {[catch {set_db $o .place_status $status} err]} {
                puts "CRITICAL: rollback status failed [dict get $ms name]: $err"
                incr failures
            }
        }
    }

    # Verify exact target-member coordinates are back.
    foreach ms [dict get $snap members] {
        set o [dict get $ms obj]
        set now_loc [TT_PR7_COORD__point2 [get_db $o .location]]
        set now_bbox [TT_PR7_COORD__rect4 [get_db $o .bbox]]
        if {![TT_PR7_COORD__same_point $now_loc [dict get $ms location]] ||
            ![TT_PR7_COORD__same_rect $now_bbox [dict get $ms bbox]]} {
            puts "CRITICAL: rollback coordinate verification failed: $row / [dict get $ms name]"
            incr failures
        }
    }

    if {$failures == 0} {
        puts "INFO: rollback restored exact target-member placement for $row"
        return true
    }
    return false
}

proc TT_PR7_COORD__parse_check_sdp_total {rpt} {
    if {![file exists $rpt]} { return -1 }
    set fp [open $rpt r]
    set txt [read $fp]
    close $fp
    if {[regexp {Total violations:[[:space:]]*([0-9]+)} $txt -> n]} { return $n }
    return -1
}

proc TT_PR7_COORD__actual_postcheck {ctx resources} {
    # Re-resolve live state after place_sdps.
    set cur [TT_PR7_COORD__resolve_group [dict get $ctx row]]
    if {![dict get $cur ok]} {
        return [dict create ok false reason [dict get $cur reason]]
    }
    set envelope [dict get $cur envelope]

    if {![TT_PR7_COORD__inside_pd $envelope [dict get $resources pd_rects]]} {
        return [dict create ok false reason "actual member envelope is outside target Power Domain" ctx $cur]
    }
    if {![TT_PR7_COORD__row_span_ok $envelope [dict get $resources row_recs]]} {
        return [dict create ok false reason "actual member envelope is not fully supported by real placement rows" ctx $cur]
    }
    set occ [dict get $resources occupancy]
    set bh [TT_PR7_COORD__cached_blockage_hits $envelope $occ]
    if {[llength $bh] != 0} {
        return [dict create ok false reason "actual member envelope overlaps placement blockage" blockage_hits $bh ctx $cur]
    }
    set sh [TT_PR7_COORD__cached_switch_gap_hits $envelope [dict get $cur members] $occ]
    if {[llength $sh] != 0} {
        return [dict create ok false reason "actual member envelope violates power-switch clearance" switch_hits $sh ctx $cur]
    }
    set fh [TT_PR7_COORD__cached_foreign_hits $envelope [dict get $cur members] $occ]
    if {[llength $fh] != 0} {
        return [dict create ok false reason "actual member envelope overlaps foreign placed instance" foreign_hits $fh ctx $cur]
    }

    # Exact custom topology/gap/foreign-gap rules.
    set custom [TT_PR7_scan_internal_sdp_structure false false [list [dict get $cur group]]]
    if {[dict get $custom violations] != 0} {
        return [dict create ok false reason "custom SDP rule still violated after place_sdps" custom $custom ctx $cur]
    }

    return [dict create ok true reason "" ctx $cur custom $custom]
}

proc TT_PR7_COORD__issues_are_geometry_only {issues} {
    foreach issue $issues {
        if {[lsearch -exact $::TT_PR7_COORD_ALLOWED_ISSUES $issue] < 0} { return false }
    }
    return [expr {[llength $issues] > 0}]
}

proc TT_PR7_COORD__native_gate {} {
    if {[llength [info commands TT_2row_sdp__check_sdps_total]] == 0} {
        return [dict create ok false total -1 reason "TT_2row_sdp__check_sdps_total unavailable"]
    }
    set rc [catch {set total [TT_2row_sdp__check_sdps_total]} err]
    if {$rc} { return [dict create ok false total -1 reason "native check_sdps wrapper failed: $err"] }
    if {![string is integer -strict $total]} {
        return [dict create ok false total -1 reason "native check_sdps total is non-integer: $total"]
    }
    if {$total != 0} {
        return [dict create ok false total $total reason "native SDP violations remain"]
    }
    return [dict create ok true total 0 reason "native SDP legality clean"]
}

proc TT_PR7_coordinate_guided_preview {sdp_name} {
    puts ""
    puts "======================================================================"
    puts " PR7 COORDINATE-GUIDED SDP PREVIEW (READ-ONLY)"
    puts "======================================================================"
    set ctx [TT_PR7_COORD__resolve_group $sdp_name]
    if {![dict get $ctx ok]} {
        puts "ERROR: [dict get $ctx reason]"
        return [dict create ok false reason [dict get $ctx reason]]
    }
    set resources [TT_PR7_COORD__candidate_resources $ctx]
    if {![dict get $resources ok]} {
        puts "ERROR: [dict get $resources reason]"
        return [dict create ok false reason [dict get $resources reason]]
    }
    set cr [TT_PR7_COORD__candidate_list $ctx $resources true]
    if {![dict get $cr ok]} {
        puts "ERROR: [dict get $cr reason]"
        return $cr
    }
    puts "Current envelope : [dict get $ctx envelope]"
    puts "Power Domain     : [dict get $ctx pd_name]"
    puts "Site             : [dict get $ctx site_name]"
    puts "Switch clearance : $::TT_PR7_COORD_SWITCH_GAP_UM um"
    puts "Blocked by        : ALL place_blockages + ALL placed/fixed/soft_fixed/cover insts"
    puts "Legal candidates : [llength [dict get $cr candidates]]"
    set n 0
    foreach c [dict get $cr candidates] {
        puts [format "  #%02d origin={%.6f %.6f} score=%.6f reserve_bbox=%s" \
            [expr {$n+1}] [dict get $c x] [dict get $c y] [dict get $c score] [dict get $c bbox]]
        incr n
        if {$n >= 10} { break }
    }
    puts "======================================================================"
    return [dict create ok true ctx $ctx resources $resources candidate_result $cr]
}

proc TT_PR7_COORD__try_candidate {ctx resources cand trial_index} {
    set row [dict get $ctx row]
    set members [dict get $ctx members]
    set snap [TT_PR7_COORD__snapshot $ctx]
    set x [dict get $cand x]
    set y [dict get $cand y]
    set bbox [dict get $cand bbox]

    puts ""
    puts [format "INFO: %s trial %d candidate origin={%.6f %.6f} reserve_bbox=%s" $row $trial_index $x $y $bbox]

    set old_move ""
    set old_move_known false
    if {![catch {set old_move [get_db place_sdp_max_move_distance]}]} { set old_move_known true }

    set failed_reason ""
    set success false
    set rc [catch {
        # Metadata guidance must not itself move the physical members.
        set_sdp_origin -sdp $row -location $x $y
        foreach ms [dict get $snap members] {
            set o [dict get $ms obj]
            if {![TT_PR7_COORD__same_point [get_db $o .location] [dict get $ms location]] ||
                ![TT_PR7_COORD__same_rect [get_db $o .bbox] [dict get $ms bbox]]} {
                error "set_sdp_origin unexpectedly moved physical member [dict get $ms name]"
            }
        }

        TT_2row_sdp__set_flat_members_fixed
        TT_2row_sdp__assert_flat_members_fixed
        TT_2row_sdp__set_selected_group_status [list [dict get $ctx group]] placed
        set_db place_sdp_max_move_distance $::TT_PR7_COORD_PLACE_SDP_MAX_MOVE_UM
        puts "INFO: PR7 coordinate-guided command: place_sdps -sdps {[list $row]}"
        place_sdps -sdps [list $row]
    } err opts]

    catch {TT_2row_sdp__set_flat_members_fixed}
    catch {TT_2row_sdp__assert_flat_members_fixed}
    if {$old_move_known} { catch {set_db place_sdp_max_move_distance $old_move} }

    if {$rc != 0} {
        set failed_reason "place trial failed: $err"
    } else {
        # Final metadata follows actual physical placement, never the trial anchor.
        if {[llength [info commands TT_PR7_manual_sync_origin]] == 0} {
            set failed_reason "TT_PR7_manual_sync_origin unavailable"
        } else {
            set sr [TT_PR7_manual_sync_origin $row false]
            if {![dict exists $sr ok] || ![dict get $sr ok]} {
                set failed_reason "final origin sync/coordinate guard failed"
            } else {
                set post [TT_PR7_COORD__actual_postcheck $ctx $resources]
                if {![dict get $post ok]} {
                    set failed_reason [dict get $post reason]
                } else {
                    set safe_name [string map {/ _ : _ \\ _} $row]
                    set rpt [tech_mv_output_path report "TT_PR7_coord_${safe_name}_trial${trial_index}.checkSdp.rpt" 02 sdp]
                    set crc [catch {check_sdps -sdps [list $row] -out_file $rpt} cerr]
                    if {$crc} {
                        set failed_reason "targeted check_sdps failed: $cerr"
                    } else {
                        set total [TT_PR7_COORD__parse_check_sdp_total $rpt]
                        if {$total != 0} {
                            set failed_reason "targeted native check_sdps total=$total (report=$rpt)"
                        } else {
                            set success true
                        }
                    }
                }
            }
        }
    }

    if {$success} {
        set final_ctx [TT_PR7_COORD__resolve_group $row]
        puts "PASS: coordinate-guided repair accepted for $row"
        puts "      final envelope = [dict get $final_ctx envelope]"
        return [dict create ok true row $row trial $trial_index candidate $cand final_ctx $final_ctx]
    }

    puts "WARN: candidate rejected for $row: $failed_reason"
    set rollback_ok [TT_PR7_COORD__restore_snapshot $snap]
    catch {TT_2row_sdp__set_flat_members_fixed}
    catch {TT_2row_sdp__assert_flat_members_fixed}
    if {!$rollback_ok} {
        puts "CRITICAL: exact rollback failed for $row; stop further trials for this group."
        return [dict create ok false fatal true row $row trial $trial_index reason $failed_reason rollback_ok false]
    }
    return [dict create ok false fatal false row $row trial $trial_index reason $failed_reason rollback_ok true]
}

proc TT_PR7_coordinate_guided_repair {sdp_name {require_native_clean true}} {
    if {![TT_PR7_COORD__bool $::TT_PR7_COORD_ENABLE]} {
        return [dict create ok false skipped true reason "coordinate-guided repair disabled"]
    }
    if {![TT_PR7_COORD__bool $::TT_PR7_COORD_APPLY_ENABLE]} {
        puts "SKIP: coordinate-guided physical APPLY is disabled by R6 safety hotfix."
        puts "      R5 showed set_sdp_origin can physically move members when used as a remote anchor."
        puts "      Use TT_PR7_coordinate_guided_preview <SDP> for read-only candidate inspection."
        puts "      Existing TT_refine_internal_gap_sdps remains the automatic gap repair path."
        return [dict create ok false skipped true reason "R6 coordinate physical apply safety gate is OFF"]
    }

    if {$require_native_clean} {
        set gate [TT_PR7_COORD__native_gate]
        if {![dict get $gate ok]} {
            puts "SKIP: coordinate-guided repair is locked until native check_sdps is clean."
            puts "      native total = [dict get $gate total]"
            puts "      reason       = [dict get $gate reason]"
            return [dict create ok false skipped true reason [dict get $gate reason] native_gate $gate]
        }
    }

    set ctx [TT_PR7_COORD__resolve_group $sdp_name]
    if {![dict get $ctx ok]} {
        puts "SKIP: $sdp_name: [dict get $ctx reason]"
        return [dict create ok false skipped true reason [dict get $ctx reason]]
    }

    # This tool only repairs groups that are currently failing the custom rule,
    # and only when every issue is one of the explicitly allowed geometry types.
    set scan [TT_PR7_scan_internal_sdp_structure false false [list [dict get $ctx group]]]
    if {[dict get $scan violations] == 0} {
        puts "INFO: [dict get $ctx row] has no custom SDP violation; no move."
        return [dict create ok true skipped true reason "custom clean" row [dict get $ctx row]]
    }
    set issues {}
    foreach d [dict get $scan details] {
        if {[dict get $d group] eq [dict get $ctx group]} { set issues [dict get $d issues]; break }
    }
    if {![TT_PR7_COORD__issues_are_geometry_only $issues]} {
        puts "SKIP: [dict get $ctx row] has structural/unsupported custom issues: $issues"
        return [dict create ok false skipped true reason "unsupported custom issues" issues $issues row [dict get $ctx row]]
    }

    set resources [TT_PR7_COORD__candidate_resources $ctx]
    if {![dict get $resources ok]} {
        puts "SKIP: [dict get $ctx row] candidate precheck unavailable: [dict get $resources reason]"
        return [dict create ok false skipped true reason [dict get $resources reason] row [dict get $ctx row]]
    }
    set cr [TT_PR7_COORD__candidate_list $ctx $resources true]
    if {![dict get $cr ok]} {
        puts "SKIP: [dict get $ctx row] candidate search failed: [dict get $cr reason]"
        return [dict create ok false skipped true reason [dict get $cr reason] row [dict get $ctx row]]
    }
    set candidates [dict get $cr candidates]
    if {[llength $candidates] == 0} {
        puts "UNRESOLVED: [dict get $ctx row] has no legal coordinate candidate. Physical placement left unchanged."
        return [dict create ok false skipped false unresolved true reason "no legal candidate" row [dict get $ctx row] issues $issues]
    }

    set max_trials $::TT_PR7_COORD_MAX_TRIALS_PER_GROUP
    if {![string is integer -strict $max_trials] || $max_trials < 1} { set max_trials 1 }
    set trial 0
    foreach cand $candidates {
        incr trial
        if {$trial > $max_trials} { break }
        set tr [TT_PR7_COORD__try_candidate $ctx $resources $cand $trial]
        if {[dict get $tr ok]} {
            dict set tr issues_before $issues
            return $tr
        }
        if {[dict exists $tr fatal] && [dict get $tr fatal]} {
            return $tr
        }
        # Re-resolve original state after verified rollback before next trial.
        set ctx [TT_PR7_COORD__resolve_group [dict get $ctx row]]
        if {![dict get $ctx ok]} {
            return [dict create ok false fatal true reason "cannot re-resolve group after rollback" row $sdp_name]
        }
    }

    puts "UNRESOLVED: [dict get $ctx row] exhausted $trial legal trial(s); exact rollback preserved original placement."
    return [dict create ok false skipped false unresolved true reason "legal candidates did not pass post-check" row [dict get $ctx row] issues $issues trials $trial]
}

proc TT_PR7_coordinate_guided_auto_repair {} {
    puts ""
    puts "======================================================================"
    puts " PR7 LATE COORDINATE-GUIDED CUSTOM REPAIR"
    puts "======================================================================"
    puts "Gate              : native check_sdps total MUST be 0"
    puts "Scope             : ONLY current custom geometry violations"
    puts "Candidate safety  : real rows + same PD + ALL place blockages + ALL placed cells"
    puts "Switch safety     : explicit power-switch clearance >= $::TT_PR7_COORD_SWITCH_GAP_UM um"
    puts "Placement         : set_sdp_origin guidance -> targeted plain place_sdps"
    puts "Failure policy    : exact rollback / leave unresolved for suspend"
    puts "keep_sdp_area     : NOT USED"
    puts "======================================================================"

    if {![TT_PR7_COORD__bool $::TT_PR7_COORD_ENABLE]} {
        set r [dict create enabled false native_gate [dict create ok false total -1 reason disabled] targeted 0 repaired 0 unresolved 0 skipped 0 groups {} results {}]
        set ::TT_PR7_COORD_RESULT $r
        puts "INFO: coordinate-guided tool disabled."
        return $r
    }
    if {![TT_PR7_COORD__bool $::TT_PR7_COORD_AUTO_ENABLE]} {
        set r [dict create enabled false native_gate [dict create ok false total -1 reason "R6 safe auto gate OFF"] targeted 0 repaired 0 unresolved 0 skipped 0 groups {} results {}]
        set ::TT_PR7_COORD_RESULT $r
        puts "INFO: R6 safety hotfix: automatic coordinate-guided PHYSICAL repair is disabled."
        puts "INFO: Reason: R5 proved remote set_sdp_origin may move physical SDP members and defeat exact rollback."
        puts "INFO: Read-only candidate preview remains available; residual custom gaps stay for suspend/manual review."
        return $r
    }

    # HARD GATE: this is deliberately after the earlier/native repair stages.
    set gate [TT_PR7_COORD__native_gate]
    if {![dict get $gate ok]} {
        puts "SKIP: late coordinate-guided custom repair did NOT run."
        puts "      Native SDP must be clean first."
        puts "      native total = [dict get $gate total]"
        puts "      reason       = [dict get $gate reason]"
        set r [dict create enabled true native_gate $gate targeted 0 repaired 0 unresolved 0 skipped 0 groups {} results {}]
        set ::TT_PR7_COORD_RESULT $r
        return $r
    }

    set scan [TT_PR7_scan_internal_sdp_structure true false]
    if {[dict get $scan violations] == 0} {
        puts "PASS: native SDP is clean and no custom internal SDP violation remains."
        set r [dict create enabled true native_gate $gate targeted 0 repaired 0 unresolved 0 skipped 0 groups {} results {} custom_after $scan]
        set ::TT_PR7_COORD_RESULT $r
        return $r
    }

    set targets {}
    set skipped_structural {}
    foreach d [dict get $scan details] {
        set g [dict get $d group]
        set issues [dict get $d issues]
        if {[TT_PR7_COORD__issues_are_geometry_only $issues]} {
            lappend targets "${g}_ROW"
        } else {
            lappend skipped_structural [list "${g}_ROW" $issues]
        }
    }

    puts "INFO: native-clean custom groups eligible for coordinate guidance: [llength $targets]"
    if {[llength $skipped_structural] != 0} {
        puts "INFO: structural/unsupported groups are intentionally untouched:"
        foreach s $skipped_structural { puts "      [lindex $s 0] issues={[lindex $s 1]}" }
    }

    set repaired 0
    set unresolved 0
    set skipped 0
    set results {}
    foreach row $targets {
        # Gate already checked once for this late pass.  Do NOT run a full
        # design-wide native check before every individual group.
        set rr [TT_PR7_coordinate_guided_repair $row false]
        lappend results $rr
        if {[dict exists $rr ok] && [dict get $rr ok] &&
            !([dict exists $rr skipped] && [dict get $rr skipped])} {
            incr repaired
        } elseif {[dict exists $rr unresolved] && [dict get $rr unresolved]} {
            incr unresolved
        } else {
            incr skipped
        }
    }

    # Re-scan custom rules after the single late repair pass.  The unchanged
    # caller will still execute the full native check_sdps before suspend.
    set after [TT_PR7_scan_internal_sdp_structure true true]
    set r [dict create enabled true native_gate $gate targeted [llength $targets] repaired $repaired unresolved $unresolved \
        skipped $skipped groups $targets skipped_structural $skipped_structural results $results custom_after $after]
    set ::TT_PR7_COORD_RESULT $r

    puts ""
    puts "======================================================================"
    puts " PR7 COORDINATE-GUIDED REPAIR SUMMARY"
    puts "======================================================================"
    puts "Native gate total       : [dict get $gate total]"
    puts "Eligible custom groups  : [llength $targets]"
    puts "Repaired                : $repaired"
    puts "Unresolved / unchanged  : $unresolved"
    puts "Skipped                 : $skipped"
    puts "Custom violations after : [dict get $after violations]"
    puts "NOTE                     : existing full check_sdps still runs before suspend"
    puts "======================================================================"
    return $r
}

puts "INFO: Loaded PR7 coordinate-guided late custom repair tool."
puts "INFO: PREVIEW : TT_PR7_coordinate_guided_preview SDP2R_00066_ROW"
puts "INFO: REPAIR  : DISABLED by default in R6 (experimental physical apply gate)"
puts "INFO: AUTO    : DISABLED by default in R6 safety hotfix"
puts "INFO: POLICY  : preview is safe; normal flow uses TT_refine_internal_gap_sdps and leaves residuals for checkpoint"
