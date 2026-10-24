# Runtime adapter preserves the historical logical source path.
if {[info exists ::TECH_MV_RUNTIME_ROOT]} {
    info script [file join $::TECH_MV_RUNTIME_ROOT run/tool/02_powerplan/TT_delete_followpin_outside_pd_boundary.tcl]
} else {
    info script [file normalize [file join [file dirname [info script]] .. .. run/tool/02_powerplan/TT_delete_followpin_outside_pd_boundary.tcl]]
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
# Load private values before evaluating original parameter defaults.
if {![llength [info commands ::tech_mv_private_value]]} { source [file join $::TECH_MV_RUNTIME_ROOT .. script PR TECH_MV script 00_common private_parameter_config.tcl] }
# ==============================================================================
# TT_delete_followpin_outside_pd_boundary.tcl
# Version : V5.1
# UI      : Innovus Common UI (get_db / get_obj_in_area / delete_obj)
# Purpose : EndCap-direction based cleanup of split M1 outside stubs.
#
# DESIGN INTENT:
#   The physical Power Domain may extend beyond the EndCap.  Therefore the trim
#   boundary is NOT the PD group boundary.  The trim boundary is the physical
#   LEFT/RIGHT EndCap edge itself.
#
# V5.1 TARGET SELECTION:
#   1) Use ENDCAP_PD_* + BOUNDARY_LEFT/RIGHT master to find lateral EndCaps.
#   2) Use instance orientation to derive the physical OUTSIDE side.
#      r0/mx   : master LEFT/RIGHT is unchanged.
#      my/r180 : physical LEFT/RIGHT is swapped.
#      other orientations are skipped conservatively.
#   3) Search only horizontal M1 special_wire objects touching the OUTSIDE side.
#   4) A delete candidate must be a DISTINCT outside object that terminates at
#      the EndCap cut and has exactly one geometrically matching inside mate.
#   5) Net equality is DIAGNOSTIC ONLY.  Geometry + direction + split DB objects
#      determine safety.
#
# HARD SAFETY RULES:
#   - If ONE special_wire object spans across the EndCap cut on the same rail,
#     classify CONTINUOUS_SKIP and NEVER delete the outside candidate.
#   - If there is no unique inside mate on the same rail geometry, do not delete.
#   - Only horizontal M1 special_wire shape=corewire/followpin is eligible.
#   - Only the OUTSIDE object is submitted to delete_obj.
#   - Default is dry-run. Destructive mode requires explicit confirmation token.
# ==============================================================================

proc TT_delete_followpin_outside_pd_boundary {args} {
    set dry_run 1
    set confirm ""
    set edge_tol [::tech_mv_private_value {run/tool/02_powerplan/TT_delete_followpin_outside_pd_boundary.tcl::edge_tol::L36}]
    set join_tol [::tech_mv_private_value {run/tool/02_powerplan/TT_delete_followpin_outside_pd_boundary.tcl::join_tol::L37}]
    set y_tol [::tech_mv_private_value {run/tool/02_powerplan/TT_delete_followpin_outside_pd_boundary.tcl::y_tol::L38}]
    set query_margin [::tech_mv_private_value {run/tool/02_powerplan/TT_delete_followpin_outside_pd_boundary.tcl::query_margin::L39}]
    set max_stub_len 5.0
    set target_layer [::tech_mv_library_value LIB_TECH_002]
    set report_file "./reports/TT_delete_followpin_outside_pd_boundary.rpt"

    set argc [llength $args]
    for {set i 0} {$i < $argc} {incr i} {
        set a [lindex $args $i]
        switch -- $a {
            -dry_run {
                incr i
                if {$i >= $argc} { error "-dry_run requires 0 or 1" }
                set dry_run [lindex $args $i]
            }
            -confirm {
                incr i
                if {$i >= $argc} { error "-confirm requires a token" }
                set confirm [lindex $args $i]
            }
            -edge_tol {
                incr i
                if {$i >= $argc} { error "-edge_tol requires a value" }
                set edge_tol [lindex $args $i]
            }
            -join_tol {
                incr i
                if {$i >= $argc} { error "-join_tol requires a value" }
                set join_tol [lindex $args $i]
            }
            -y_tol {
                incr i
                if {$i >= $argc} { error "-y_tol requires a value" }
                set y_tol [lindex $args $i]
            }
            -query_margin {
                incr i
                if {$i >= $argc} { error "-query_margin requires a value" }
                set query_margin [lindex $args $i]
            }
            -max_stub_len {
                incr i
                if {$i >= $argc} { error "-max_stub_len requires a value" }
                set max_stub_len [lindex $args $i]
            }
            -layer {
                incr i
                if {$i >= $argc} { error "-layer requires a layer name" }
                set target_layer [lindex $args $i]
            }
            -report {
                incr i
                if {$i >= $argc} { error "-report requires a path" }
                set report_file [lindex $args $i]
            }
            default { error "Unknown option: $a" }
        }
    }

    if {$dry_run != 0 && $dry_run != 1} { error "-dry_run must be 0 or 1" }
    if {$dry_run == 0 && $confirm ne "DELETE_DIRECTIONAL_ENDCAP_STUBS"} {
        puts "ERROR: destructive V5.1 requires explicit confirmation."
        puts "Use: TT_delete_followpin_outside_pd_boundary -dry_run 0 -confirm DELETE_DIRECTIONAL_ENDCAP_STUBS"
        puts "No DB object was modified."
        return -code error "missing destructive confirmation token"
    }
    foreach {n v} [list edge_tol $edge_tol join_tol $join_tol y_tol $y_tol query_margin $query_margin max_stub_len $max_stub_len] {
        if {$v < 0.0} { error "-$n must be >= 0" }
    }
    if {$query_margin <= 0.0} { error "-query_margin must be > 0" }
    if {$max_stub_len <= 0.0} { error "-max_stub_len must be > 0" }

    set pd_list {PD_core PD_TOP PD_CPU PD_WDT PD_CPU_ALWY_ON}
    set allowed_shapes {corewire followpin}

    file mkdir [file dirname $report_file]
    set fp [open $report_file w]

    proc TT_V51_LOG {fp msg} { puts $msg; puts $fp $msg }

    proc TT_V51_RECT4 {raw} {
        set v $raw
        for {set depth 0} {$depth < 4} {incr depth} {
            if {[llength $v] != 1} { break }
            set next [lindex $v 0]
            if {$next eq $v} { break }
            set v $next
        }
        if {[llength $v] == 4} { return $v }
        if {[llength $v] == 2 && [llength [lindex $v 0]] == 2 && [llength [lindex $v 1]] == 2} {
            return [concat [lindex $v 0] [lindex $v 1]]
        }
        return {}
    }

    proc TT_V51_OBJKEY {obj} { return "$obj" }

    proc TT_V51_NETNAME {sw} {
        if {[catch {set n [get_db $sw .net]}] || [llength $n] == 0} { return "" }
        if {[catch {set nm [get_db $n .name]}]} { return "" }
        return $nm
    }

    proc TT_V51_LAYERNAME {sw} {
        if {[catch {set l [get_db $sw .layer]}] || [llength $l] == 0} { return "" }
        if {[catch {set nm [get_db $l .name]}]} { return "" }
        return $nm
    }

    proc TT_V51_SHAPE {sw} {
        if {[catch {set s [get_db $sw .shape]}]} { return "" }
        return [string tolower "$s"]
    }

    proc TT_V51_ORIENT {inst} {
        if {[catch {set o [get_db $inst .orient]}] || $o eq ""} { return "unknown" }
        return [string tolower "$o"]
    }

    proc TT_V51_PHYSICAL_SIDE {nominal orient} {
        switch -- [string tolower $orient] {
            r0 -
            mx { return $nominal }
            my -
            r180 {
                if {$nominal eq "LEFT"} { return "RIGHT" }
                return "LEFT"
            }
            default { return "" }
        }
    }

    proc TT_V51_SAME_RAIL {r1 r2 tol} {
        lassign $r1 a1 b1 a2 b2
        lassign $r2 c1 d1 c2 d2
        set cy1 [expr {($b1+$b2)/2.0}]
        set cy2 [expr {($d1+$d2)/2.0}]
        set h1 [expr {$b2-$b1}]
        set h2 [expr {$d2-$d1}]
        return [expr {abs($cy1-$cy2) <= $tol && abs($h1-$h2) <= $tol}]
    }

    proc TT_V51_Y_OVERLAP {wire_rect endcap_rect tol} {
        lassign $wire_rect wx1 wy1 wx2 wy2
        lassign $endcap_rect ex1 ey1 ex2 ey2
        return [expr {!($wy2 < $ey1-$tol || $wy1 > $ey2+$tol)}]
    }

    set ::TT_V51_LAYER_FILTER_FALLBACK 0
    proc TT_V51_QUERY_SPECIAL_WIRES {area layer_name} {
        if {!$::TT_V51_LAYER_FILTER_FALLBACK} {
            if {![catch {set objs [get_obj_in_area -area $area -obj_type special_wire -layers [list $layer_name]]}]} {
                return $objs
            }
            set ::TT_V51_LAYER_FILTER_FALLBACK 1
        }
        return [get_obj_in_area -area $area -obj_type special_wire]
    }

    TT_V51_LOG $fp ""
    TT_V51_LOG $fp "======================================================================"
    TT_V51_LOG $fp " TT ENDCAP-DIRECTION M1 OUTSIDE-STUB CLEANUP V5.1"
    TT_V51_LOG $fp "======================================================================"
    TT_V51_LOG $fp "UI            : Innovus Common UI"
    TT_V51_LOG $fp "Dry run       : $dry_run"
    TT_V51_LOG $fp "Cut reference : physical LEFT/RIGHT EndCap edge (NOT PD boundary)"
    TT_V51_LOG $fp "Direction     : EndCap master + instance orientation"
    TT_V51_LOG $fp "Target layer  : $target_layer"
    TT_V51_LOG $fp "Outer shapes  : [join $allowed_shapes { / }]"
    TT_V51_LOG $fp "Inner mate    : same-rail distinct M1 corewire/followpin object"
    TT_V51_LOG $fp "Edge tol      : $edge_tol um"
    TT_V51_LOG $fp "Join tol      : $join_tol um"
    TT_V51_LOG $fp "Y/width tol   : $y_tol um"
    TT_V51_LOG $fp "Query margin  : $query_margin um around EndCap edge"
    TT_V51_LOG $fp "Max stub len  : $max_stub_len um"
    TT_V51_LOG $fp "Net rule      : diagnostic only; NOT used to select/delete"
    TT_V51_LOG $fp "Safety        : same-rail continuous object is NEVER deleted"
    TT_V51_LOG $fp "Report        : $report_file"
    TT_V51_LOG $fp "======================================================================"

    foreach pd $pd_list {
        foreach side {LEFT RIGHT} {
            set anchors($pd,$side) {}
        }
        foreach k {SAFE_OBS CONTINUOUS NO_OUTER NO_INNER MULTI_INNER OUTER_LONG BAD_ORIENT} {
            set stat($pd,$k) 0
        }
    }

    set total_candidates 0
    set usable_anchors 0
    set unresolved_naming 0
    set bad_bbox 0
    set bad_orient_total 0

    foreach inst [get_db insts] {
        set name [get_db $inst .name]
        set leaf [lindex [split $name "/"] end]
        if {![string match "ENDCAP_PD_*" $leaf]} { continue }

        set master [get_db [get_db $inst .base_cell] .name]
        if {$master eq [::tech_mv_library_value ENDCAP_DIRECTION_EXACT_1]} {
            set nominal_side LEFT
        } elseif {$master eq [::tech_mv_library_value ENDCAP_DIRECTION_EXACT_2]} {
            set nominal_side RIGHT
        } else {
            continue
        }

        set pd ""
        foreach p $pd_list {
            if {[string match "ENDCAP_PD_${p}_${p}_*" $leaf]} {
                set pd $p
                break
            }
        }
        if {$pd eq ""} {
            incr unresolved_naming
            continue
        }

        incr total_candidates
        set bbox [TT_V51_RECT4 [get_db $inst .bbox]]
        if {[llength $bbox] != 4} {
            incr bad_bbox
            continue
        }

        set orient [TT_V51_ORIENT $inst]
        set physical_side [TT_V51_PHYSICAL_SIDE $nominal_side $orient]
        if {$physical_side eq ""} {
            incr stat($pd,BAD_ORIENT)
            incr bad_orient_total
            continue
        }

        lappend anchors($pd,$physical_side) [list $inst $bbox $nominal_side $orient]
        incr usable_anchors
    }

    TT_V51_LOG $fp ""
    TT_V51_LOG $fp "INFO: lateral ENDCAP_PD_* candidates = $total_candidates"
    TT_V51_LOG $fp "INFO: usable directional anchors      = $usable_anchors"
    TT_V51_LOG $fp "INFO: bad EndCap bbox                 = $bad_bbox"
    TT_V51_LOG $fp "INFO: unsupported orientation         = $bad_orient_total"
    TT_V51_LOG $fp "INFO: unresolved naming               = $unresolved_naming"

    array unset safe_obj; array set safe_obj {}
    array unset safe_meta; array set safe_meta {}
    array unset continuous_obj; array set continuous_obj {}
    array unset safe_shape_hist; array set safe_shape_hist {}
    array unset safe_pd_side_hist; array set safe_pd_side_hist {}

    set safe_net_match 0
    set safe_net_diff 0
    set safe_net_blank 0
    set sample_safe {}
    set sample_cont {}
    set sample_skip {}

    foreach pd $pd_list {
        foreach physical_side {LEFT RIGHT} {
            foreach rec $anchors($pd,$physical_side) {
                lassign $rec inst eb nominal_side orient
                lassign $eb ex1 ey1 ex2 ey2
                if {$physical_side eq "LEFT"} { set cut_x $ex1 } else { set cut_x $ex2 }

                set area [list \
                    [expr {$cut_x-$query_margin}] \
                    [expr {$ey1-$y_tol}] \
                    [expr {$cut_x+$query_margin}] \
                    [expr {$ey2+$y_tol}]]

                set objs [TT_V51_QUERY_SPECIAL_WIRES $area $target_layer]
                set outer {}
                set inner {}
                set continuous {}

                foreach sw $objs {
                    set r [TT_V51_RECT4 [get_db $sw .rect]]
                    if {[llength $r] != 4} { continue }
                    lassign $r wx1 wy1 wx2 wy2

                    # M1 followpin/corewire rails of interest are horizontal.
                    if {($wx2-$wx1) < ($wy2-$wy1)} { continue }
                    if {![TT_V51_Y_OVERLAP $r $eb $y_tol]} { continue }

                    set layer [TT_V51_LAYERNAME $sw]
                    if {$layer ne "" && $layer ne $target_layer} { continue }

                    set shape [TT_V51_SHAPE $sw]
                    if {[lsearch -exact $allowed_shapes $shape] < 0} { continue }
                    set net [TT_V51_NETNAME $sw]

                    # One DB object spanning both sides of the EndCap cut is
                    # protected unconditionally.
                    if {$wx1 < $cut_x-$edge_tol && $wx2 > $cut_x+$edge_tol} {
                        lappend continuous [list $sw $r $shape $net]
                        continue
                    }

                    if {$physical_side eq "LEFT"} {
                        if {$wx1 < $cut_x-$edge_tol && abs($wx2-$cut_x) <= $join_tol} {
                            lappend outer [list $sw $r $shape $net]
                        }
                        if {$wx2 > $cut_x+$edge_tol && abs($wx1-$cut_x) <= $join_tol} {
                            lappend inner [list $sw $r $shape $net]
                        }
                    } else {
                        if {$wx2 > $cut_x+$edge_tol && abs($wx1-$cut_x) <= $join_tol} {
                            lappend outer [list $sw $r $shape $net]
                        }
                        if {$wx1 < $cut_x-$edge_tol && abs($wx2-$cut_x) <= $join_tol} {
                            lappend inner [list $sw $r $shape $net]
                        }
                    }
                }

                if {[llength $outer] == 0} {
                    incr stat($pd,NO_OUTER)
                    if {[llength $sample_skip] < 30} {
                        lappend sample_skip [list NO_OUTER $pd $physical_side [get_db $inst .name] orient=$orient cut=$cut_x]
                    }
                    continue
                }

                foreach o $outer {
                    lassign $o osw or osh onet
                    lassign $or ox1 oy1 ox2 oy2
                    set olen [expr {$ox2-$ox1}]
                    if {$olen > $max_stub_len+$edge_tol} {
                        incr stat($pd,OUTER_LONG)
                        if {[llength $sample_skip] < 30} {
                            lappend sample_skip [list OUTER_LONG $pd $physical_side [get_db $inst .name] $osw $or len=$olen]
                        }
                        continue
                    }

                    # If the same rail has one continuous object spanning the cut,
                    # the target is not safely split. Never delete this outer.
                    set cont_match {}
                    foreach c $continuous {
                        lassign $c csw cr csh cnet
                        if {[TT_V51_SAME_RAIL $or $cr $y_tol]} {
                            lappend cont_match $c
                            set continuous_obj([TT_V51_OBJKEY $csw]) $csw
                        }
                    }
                    if {[llength $cont_match] > 0} {
                        incr stat($pd,CONTINUOUS)
                        if {[llength $sample_cont] < 30} {
                            lappend sample_cont [list $pd $physical_side [get_db $inst .name] orient=$orient cut=$cut_x OUTER $osw $or CONTINUOUS [lindex $cont_match 0]]
                        }
                        continue
                    }

                    # Require a distinct inside object on the SAME rail geometry.
                    # This proves the EndCap location is actually split into two
                    # DB objects. Net name is deliberately not part of selection.
                    set inner_match {}
                    foreach in $inner {
                        lassign $in isw ir ish inet
                        if {$isw eq $osw} { continue }
                        if {![TT_V51_SAME_RAIL $or $ir $y_tol]} { continue }

                        lassign $ir ix1 iy1 ix2 iy2
                        if {$physical_side eq "LEFT"} {
                            set gap [expr {abs($ox2-$ix1)}]
                        } else {
                            set gap [expr {abs($ox1-$ix2)}]
                        }
                        if {$gap <= $join_tol} {
                            lappend inner_match $in
                        }
                    }

                    if {[llength $inner_match] == 0} {
                        incr stat($pd,NO_INNER)
                        if {[llength $sample_skip] < 30} {
                            lappend sample_skip [list NO_INNER $pd $physical_side [get_db $inst .name] $osw $or $osh $onet]
                        }
                        continue
                    }
                    if {[llength $inner_match] != 1} {
                        incr stat($pd,MULTI_INNER)
                        if {[llength $sample_skip] < 30} {
                            lappend sample_skip [list MULTI_INNER $pd $physical_side [get_db $inst .name] $osw $or matches=[llength $inner_match]]
                        }
                        continue
                    }

                    set in [lindex $inner_match 0]
                    lassign $in isw ir ish inet

                    set key [TT_V51_OBJKEY $osw]
                    set safe_obj($key) $osw
                    set safe_meta($key) [list $pd $physical_side [get_db $inst .name] $orient $cut_x $or $osh $onet $isw $ir $ish $inet]
                    incr stat($pd,SAFE_OBS)

                    set hk "$pd|$physical_side"
                    if {![info exists safe_pd_side_hist($hk)]} { set safe_pd_side_hist($hk) 0 }
                    incr safe_pd_side_hist($hk)
                    if {![info exists safe_shape_hist($osh)]} { set safe_shape_hist($osh) 0 }
                    incr safe_shape_hist($osh)

                    if {$onet eq "" || $inet eq ""} {
                        incr safe_net_blank
                    } elseif {$onet eq $inet} {
                        incr safe_net_match
                    } else {
                        incr safe_net_diff
                    }

                    if {[llength $sample_safe] < 40} {
                        lappend sample_safe [list \
                            $pd $physical_side [get_db $inst .name] orient=$orient cut=$cut_x \
                            OUTER $osw $or $osh $onet \
                            INNER $isw $ir $ish $inet]
                    }
                }
            }
        }
    }

    TT_V51_LOG $fp ""
    TT_V51_LOG $fp "======================================================================"
    TT_V51_LOG $fp " ENDCAP-DIRECTION SAFETY SUMMARY V5.1"
    TT_V51_LOG $fp "======================================================================"
    TT_V51_LOG $fp [format "%-20s %10s %11s %9s %9s %11s %10s %10s" \
        "POWER_DOMAIN" "SAFE_OBS" "CONTINUOUS" "NO_OUTER" "NO_INNER" "MULTI_INNER" "OUTER_LONG" "BAD_ORIENT"]
    TT_V51_LOG $fp "------------------------------------------------------------------------------------------------------"
    foreach pd $pd_list {
        TT_V51_LOG $fp [format "%-20s %10d %11d %9d %9d %11d %10d %10d" \
            $pd $stat($pd,SAFE_OBS) $stat($pd,CONTINUOUS) $stat($pd,NO_OUTER) $stat($pd,NO_INNER) \
            $stat($pd,MULTI_INNER) $stat($pd,OUTER_LONG) $stat($pd,BAD_ORIENT)]
    }
    TT_V51_LOG $fp "------------------------------------------------------------------------------------------------------"
    TT_V51_LOG $fp "Unique SAFE_DELETE outside objects = [llength [array names safe_obj]]"
    TT_V51_LOG $fp "Unique CONTINUOUS_SKIP objects      = [llength [array names continuous_obj]]"
    TT_V51_LOG $fp "Layer-filter fallback               = $::TT_V51_LAYER_FILTER_FALLBACK"
    TT_V51_LOG $fp "SAFE net-match observations         = $safe_net_match"
    TT_V51_LOG $fp "SAFE net-diff observations          = $safe_net_diff"
    TT_V51_LOG $fp "SAFE blank-net observations         = $safe_net_blank"

    TT_V51_LOG $fp ""
    TT_V51_LOG $fp "---------------- SAFE OUTER SHAPE HISTOGRAM ----------------"
    if {[llength [array names safe_shape_hist]] == 0} {
        TT_V51_LOG $fp "<none>"
    } else {
        foreach k [lsort [array names safe_shape_hist]] {
            TT_V51_LOG $fp [format "%-20s %8d" $k $safe_shape_hist($k)]
        }
    }

    TT_V51_LOG $fp ""
    TT_V51_LOG $fp "---------------- SAFE PD/SIDE HISTOGRAM ----------------"
    if {[llength [array names safe_pd_side_hist]] == 0} {
        TT_V51_LOG $fp "<none>"
    } else {
        foreach k [lsort [array names safe_pd_side_hist]] {
            TT_V51_LOG $fp [format "%-30s %8d" $k $safe_pd_side_hist($k)]
        }
    }

    TT_V51_LOG $fp ""
    TT_V51_LOG $fp "---------------- FIRST [llength $sample_safe] SAFE_DELETE OBJECTS ----------------"
    foreach x $sample_safe { TT_V51_LOG $fp $x }

    TT_V51_LOG $fp ""
    TT_V51_LOG $fp "---------------- FIRST [llength $sample_cont] CONTINUOUS_SKIP ----------------"
    foreach x $sample_cont { TT_V51_LOG $fp $x }

    TT_V51_LOG $fp ""
    TT_V51_LOG $fp "---------------- FIRST [llength $sample_skip] OTHER SKIPS ----------------"
    foreach x $sample_skip { TT_V51_LOG $fp $x }

    set deleted 0
    set delete_fail 0
    if {$dry_run == 0} {
        TT_V51_LOG $fp ""
        TT_V51_LOG $fp "======================================================================"
        TT_V51_LOG $fp " DESTRUCTIVE DELETE PHASE V5.1"
        TT_V51_LOG $fp "======================================================================"
        foreach key [array names safe_obj] {
            set sw $safe_obj($key)
            if {[catch {delete_obj $sw} err]} {
                incr delete_fail
                TT_V51_LOG $fp "DELETE_FAIL $sw : $err"
            } else {
                incr deleted
            }
        }
        TT_V51_LOG $fp "Deleted unique directional outside objects = $deleted"
        TT_V51_LOG $fp "Delete failures                            = $delete_fail"
        TT_V51_LOG $fp "CONTINUOUS / unmatched / ambiguous objects were NEVER submitted to delete_obj."
    } else {
        TT_V51_LOG $fp ""
        TT_V51_LOG $fp "INFO: DRY RUN. No DB object was modified."
        TT_V51_LOG $fp "INFO: Review SAFE_DELETE samples first."
        TT_V51_LOG $fp "INFO: Destructive command:"
        TT_V51_LOG $fp "      TT_delete_followpin_outside_pd_boundary -dry_run 0 -confirm DELETE_DIRECTIONAL_ENDCAP_STUBS"
    }

    close $fp
    return [list \
        candidates $total_candidates \
        anchors $usable_anchors \
        safe_unique [llength [array names safe_obj]] \
        continuous_unique [llength [array names continuous_obj]] \
        net_match $safe_net_match \
        net_diff $safe_net_diff \
        net_blank $safe_net_blank \
        bad_bbox $bad_bbox \
        bad_orient $bad_orient_total \
        unresolved_naming $unresolved_naming \
        deleted $deleted \
        delete_fail $delete_fail \
        report $report_file]
}
