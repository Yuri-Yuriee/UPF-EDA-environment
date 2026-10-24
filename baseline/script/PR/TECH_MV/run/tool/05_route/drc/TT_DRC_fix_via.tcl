# Runtime adapter preserves the historical logical source path.
if {[info exists ::TECH_MV_RUNTIME_ROOT]} {
    info script [file join $::TECH_MV_RUNTIME_ROOT run/tool/05_route/drc/TT_DRC_fix_via.tcl]
}
# DRC_RULE_SPECIFIC_TOOL: named/configured DRC subtype selection is technology-dependent.
# DRC_RULE_REVIEW: Rule names, filters and repair logic are retained for manual planning.
# =============================================================================
# TT_DRC_fix_via.tcl
#
# DRC-marker-guided cleanup for overlapping SPECIAL VIA objects.
#
# Target DRC marker subtypes:
#   - Adjacent_Cut_Spacing
#   - Cut_Short
#   - Cut_Spacing
#
# Innovus special_via geometry used by this tool:
#   .cut_rects
#
# Policy:
#   1. Use the DRC marker .bbox directly as the local search window.
#   2. Search special_via objects on the marker layer.
#   3. Read each special_via's .cut_rects.
#   4. Two vias are considered overlapping only when at least one pair of
#      their actual CUT rectangles has positive intersection area.
#   5. Compare total CUT rectangle area of both vias.
#   6. Delete the strictly smaller via.
#   7. Equal-area, single-cut pairs are also removable ONLY when:
#        - both vias resolve to the same SPECIALNET net,
#        - their cuts overlap by at least TT_VIA_DRC_EQUAL_OVERLAP_RATIO, and
#        - if both via definitions are known, they are the same via definition.
#      A deterministic geometry tie-break keeps the left-most/bottom-most via.
#      Different/unknown nets are NEVER auto-deleted.
#   8. Preview is default; apply must be requested explicitly.
#   9. The same via is deleted at most once even if multiple markers find it.
#
# Commands:
#   TT_via_drc_stats
#   TT_via_drc_fix preview
#   TT_via_drc_fix apply
#
# =============================================================================

foreach _cfg_var {TT_VIA_DRC_SUBTYPES TT_VIA_DRC_EQUAL_OVERLAP_RATIO} {
    if {![info exists ::$_cfg_var]} {
        error "Missing config variable $_cfg_var. Source init.setup first."
    }
}
unset _cfg_var


# -----------------------------------------------------------------------------
# Geometry helpers
# -----------------------------------------------------------------------------

proc tt_via_drc_normalize_rect {rect} {
    if {[catch {set n [llength $rect]}]} {
        return ""
    }

    # Normal Innovus rect format:
    #   {llx lly urx ury}
    #
    # Some returned values can contain one extra list wrapper.
    if {$n == 1} {
        set rect [lindex $rect 0]
        if {[catch {set n [llength $rect]}]} {
            return ""
        }
    }

    if {$n != 4} {
        return ""
    }

    lassign $rect llx lly urx ury

    foreach value [list $llx $lly $urx $ury] {
        if {![string is double -strict $value]} {
            return ""
        }
    }

    if {$llx > $urx} {
        set t $llx
        set llx $urx
        set urx $t
    }

    if {$lly > $ury} {
        set t $lly
        set lly $ury
        set ury $t
    }

    if {$llx >= $urx || $lly >= $ury} {
        return ""
    }

    return [list $llx $lly $urx $ury]
}


proc tt_via_drc_rect_area {rect} {
    set rect [tt_via_drc_normalize_rect $rect]

    if {$rect eq ""} {
        return 0.0
    }

    lassign $rect llx lly urx ury

    return [expr {
        double($urx - $llx) * double($ury - $lly)
    }]
}


proc tt_via_drc_rect_intersection_area {a b} {
    set a [tt_via_drc_normalize_rect $a]
    set b [tt_via_drc_normalize_rect $b]

    if {$a eq "" || $b eq ""} {
        return 0.0
    }

    lassign $a a_llx a_lly a_urx a_ury
    lassign $b b_llx b_lly b_urx b_ury

    set llx [expr {max($a_llx, $b_llx)}]
    set lly [expr {max($a_lly, $b_lly)}]
    set urx [expr {min($a_urx, $b_urx)}]
    set ury [expr {min($a_ury, $b_ury)}]

    if {$llx >= $urx || $lly >= $ury} {
        return 0.0
    }

    return [expr {
        double($urx - $llx) * double($ury - $lly)
    }]
}


proc tt_via_drc_cut_rects {via} {
    set rects {}

    if {[catch {
        set rects [get_db $via .cut_rects]
    } err]} {
        puts "WARNING: Cannot read .cut_rects from $via"
        puts "WARNING: $err"
        return {}
    }

    set result {}

    foreach rect $rects {
        set nr [tt_via_drc_normalize_rect $rect]
        if {$nr ne ""} {
            lappend result $nr
        }
    }

    return $result
}


proc tt_via_drc_total_cut_area {via} {
    set area 0.0

    foreach rect [tt_via_drc_cut_rects $via] {
        set area [expr {$area + [tt_via_drc_rect_area $rect]}]
    }

    return $area
}


proc tt_via_drc_cut_count {via} {
    return [llength [tt_via_drc_cut_rects $via]]
}


proc tt_via_drc_vias_overlap {via_a via_b} {
    set rects_a [tt_via_drc_cut_rects $via_a]
    set rects_b [tt_via_drc_cut_rects $via_b]

    foreach ra $rects_a {
        foreach rb $rects_b {
            if {[tt_via_drc_rect_intersection_area $ra $rb] > 0.0} {
                return true
            }
        }
    }

    return false
}


proc tt_via_drc_marker_layer {marker} {
    set layer ""

    if {[catch {
        set layer [get_db $marker .layer.name]
    }]} {
        return ""
    }

    return $layer
}


proc tt_via_drc_marker_is_target {marker} {
    set subtype [get_db $marker .subtype]

    return [expr {
        [lsearch -exact $::TT_VIA_DRC_SUBTYPES $subtype] >= 0
    }]
}


proc tt_via_drc_obj_key {obj} {
    return [string trim $obj]
}


# -----------------------------------------------------------------------------
# Via identity / connectivity helpers
# -----------------------------------------------------------------------------

proc tt_via_drc_via_net_name {via} {
    # Common UI normally exposes special_via.net. Keep fallbacks because DB
    # attribute spellings can vary between Innovus releases.
    foreach attr {.net.name .net} {
        if {[catch {set value [get_db $via $attr]}]} {
            continue
        }

        if {$value eq ""} {
            continue
        }

        if {$attr eq ".net"} {
            if {![catch {set n [get_db $value .name]}] && $n ne ""} {
                return $n
            }
        } else {
            return $value
        }
    }

    return ""
}


proc tt_via_drc_via_def_name {via} {
    foreach attr {.via_def.name .via_def} {
        if {[catch {set value [get_db $via $attr]}]} {
            continue
        }

        if {$value eq ""} {
            continue
        }

        if {$attr eq ".via_def"} {
            if {![catch {set n [get_db $value .name]}] && $n ne ""} {
                return $n
            }
        } else {
            return $value
        }
    }

    return ""
}


proc tt_via_drc_single_cut_overlap_ratio {via_a via_b} {
    set ra [tt_via_drc_cut_rects $via_a]
    set rb [tt_via_drc_cut_rects $via_b]

    if {[llength $ra] != 1 || [llength $rb] != 1} {
        return 0.0
    }

    set ra [lindex $ra 0]
    set rb [lindex $rb 0]

    set aa [tt_via_drc_rect_area $ra]
    set ab [tt_via_drc_rect_area $rb]
    set amin [expr {min($aa, $ab)}]

    if {$amin <= 0.0} {
        return 0.0
    }

    set ai [tt_via_drc_rect_intersection_area $ra $rb]
    return [expr {$ai / $amin}]
}


proc tt_via_drc_rect_center {rect} {
    set rect [tt_via_drc_normalize_rect $rect]
    if {$rect eq ""} {
        return {}
    }

    lassign $rect llx lly urx ury
    return [list \
        [expr {0.5 * (double($llx) + double($urx))}] \
        [expr {0.5 * (double($lly) + double($ury))}]]
}


proc tt_via_drc_choose_equal_area_delete {via_a via_b} {
    # Return the via to delete, or "" when the pair is not safe for automatic
    # equal-area resolution.
    set rects_a [tt_via_drc_cut_rects $via_a]
    set rects_b [tt_via_drc_cut_rects $via_b]

    if {[llength $rects_a] != 1 || [llength $rects_b] != 1} {
        return ""
    }

    set net_a [tt_via_drc_via_net_name $via_a]
    set net_b [tt_via_drc_via_net_name $via_b]

    # Never guess across different or unresolved nets.
    if {$net_a eq "" || $net_b eq "" || $net_a ne $net_b} {
        return ""
    }

    set def_a [tt_via_drc_via_def_name $via_a]
    set def_b [tt_via_drc_via_def_name $via_b]

    # If both definitions are available and differ, do not guess.
    if {$def_a ne "" && $def_b ne "" && $def_a ne $def_b} {
        return ""
    }

    set ratio [tt_via_drc_single_cut_overlap_ratio $via_a $via_b]
    if {$ratio + 1.0e-12 < $::TT_VIA_DRC_EQUAL_OVERLAP_RATIO} {
        return ""
    }

    # Deterministic geometry tie-break: keep the left-most cut. If X centers
    # are equal, keep the bottom-most cut. If geometry is identical, keep the
    # lexicographically smaller object key.
    set ca [tt_via_drc_rect_center [lindex $rects_a 0]]
    set cb [tt_via_drc_rect_center [lindex $rects_b 0]]
    lassign $ca ax ay
    lassign $cb bx by

    set eps 1.0e-9

    if {$ax < $bx - $eps} {
        return $via_b
    } elseif {$bx < $ax - $eps} {
        return $via_a
    }

    if {$ay < $by - $eps} {
        return $via_b
    } elseif {$by < $ay - $eps} {
        return $via_a
    }

    if {[string compare [tt_via_drc_obj_key $via_a] [tt_via_drc_obj_key $via_b]] <= 0} {
        return $via_b
    }
    return $via_a
}


# -----------------------------------------------------------------------------
# Marker statistics
# -----------------------------------------------------------------------------

proc TT_via_drc_stats {} {
    set counts [dict create]

    foreach marker [get_db markers] {
        set subtype [get_db $marker .subtype]

        if {![dict exists $counts $subtype]} {
            dict set counts $subtype 0
        }

        dict incr counts $subtype
    }

    puts ""
    puts "======================================================================"
    puts " DRC Marker Statistics"
    puts "======================================================================"

    foreach subtype [lsort [dict keys $counts]] {
        set tag ""

        if {[lsearch -exact $::TT_VIA_DRC_SUBTYPES $subtype] >= 0} {
            set tag "  <-- TARGET"
        }

        puts [format "%-32s %6d%s" \
            $subtype [dict get $counts $subtype] $tag]
    }

    puts "======================================================================"
    puts ""
}


# -----------------------------------------------------------------------------
# Find special_via objects directly inside one DRC marker.
#
# -layers $layer keeps the search on the DRC marker's cut layer.
# No search expansion / margin is used.
# -----------------------------------------------------------------------------

proc tt_via_drc_get_candidates {marker} {
    set marker_bbox [get_db $marker .bbox]
    set layer       [tt_via_drc_marker_layer $marker]

    if {$marker_bbox eq "" || $layer eq ""} {
        return {}
    }

    set objects {}

    set cmd [list \
        get_obj_in_area \
        -area $marker_bbox \
        -obj_type special_via \
        -overlap_only \
        -layers $layer]

    if {[catch {
        set objects [uplevel #0 $cmd]
    } err]} {
        puts "WARNING: Cannot query special_via in marker:"
        puts "WARNING: $err"
        return {}
    }

    # Remove duplicates while preserving object handles.
    set seen [dict create]
    set result {}

    foreach via $objects {
        set key [tt_via_drc_obj_key $via]

        if {$key eq "" || [dict exists $seen $key]} {
            continue
        }

        # A usable special_via for this tool must have cut_rects.
        if {[llength [tt_via_drc_cut_rects $via]] == 0} {
            continue
        }

        dict set seen $key 1
        lappend result $via
    }

    return $result
}


# -----------------------------------------------------------------------------
# Delete helper
# -----------------------------------------------------------------------------

proc tt_via_drc_delete_one {via} {
    if {![catch {
        delete_obj $via
    } err]} {
        return true
    }

    # Fallback for Innovus builds where the special via is deleted through
    # floorplan selection instead of direct delete_obj.
    deselect_obj -all

    if {[catch {
        select_obj $via
        delete_selected_from_floorplan
        deselect_obj -all
    } err2]} {
        deselect_obj -all

        puts "ERROR: Cannot delete $via"
        puts "ERROR: delete_obj: $err"
        puts "ERROR: fallback  : $err2"

        return false
    }

    return true
}


# -----------------------------------------------------------------------------
# Main cleanup
# -----------------------------------------------------------------------------

proc TT_via_drc_fix {{mode preview}} {

    set mode [string tolower [string trim $mode]]

    if {$mode ni {preview apply}} {
        error "Usage: TT_via_drc_fix ?preview|apply?"
    }

    set markers {}

    foreach marker [get_db markers] {
        if {[tt_via_drc_marker_is_target $marker]} {
            lappend markers $marker
        }
    }

    set report_file [tech_mv_report_path 80 "overlap_via_drc_cleanup_${mode}" rpt 90 via_drc]

    set fp [open $report_file w]

    puts $fp "DRC-Guided Overlapping Special Via Cleanup"
    puts $fp "Mode           : $mode"
    puts $fp "Target subtypes: $::TT_VIA_DRC_SUBTYPES"
    puts $fp "Marker count   : [llength $markers]"
    puts $fp ""

    set delete_set [dict create]
    set overlap_pairs 0

    foreach marker $markers {

        set subtype [get_db $marker .subtype]
        set bbox    [get_db $marker .bbox]
        set layer   [tt_via_drc_marker_layer $marker]

        set vias [tt_via_drc_get_candidates $marker]
        set n    [llength $vias]

        puts $fp "--------------------------------------------------------------------"
        puts $fp "Marker subtype : $subtype"
        puts $fp "Marker layer   : $layer"
        puts $fp "Marker bbox    : $bbox"
        puts $fp "Via candidates : $n"

        if {$n < 2} {
            puts $fp "Action         : none (<2 special_via candidates)"
            puts $fp ""
            continue
        }

        for {set i 0} {$i < $n} {incr i} {
            set via_a [lindex $vias $i]

            for {set j [expr {$i + 1}]} {$j < $n} {incr j} {
                set via_b [lindex $vias $j]

                # Same marker layer is already guaranteed by get_obj_in_area.
                # Now require ACTUAL cut-rectangle overlap.
                if {![tt_via_drc_vias_overlap $via_a $via_b]} {
                    continue
                }

                incr overlap_pairs

                set area_a  [tt_via_drc_total_cut_area $via_a]
                set area_b  [tt_via_drc_total_cut_area $via_b]
                set count_a [tt_via_drc_cut_count $via_a]
                set count_b [tt_via_drc_cut_count $via_b]

                puts $fp ""
                puts $fp "OVERLAPPING SPECIAL VIA PAIR"
                set net_a [tt_via_drc_via_net_name $via_a]
                set net_b [tt_via_drc_via_net_name $via_b]
                set def_a [tt_via_drc_via_def_name $via_a]
                set def_b [tt_via_drc_via_def_name $via_b]
                set overlap_ratio [tt_via_drc_single_cut_overlap_ratio $via_a $via_b]

                puts $fp "  A = $via_a"
                puts $fp "      net       = $net_a"
                puts $fp "      via_def   = $def_a"
                puts $fp "      cut_count = $count_a"
                puts $fp "      cut_area  = $area_a"
                puts $fp "      cut_rects = [tt_via_drc_cut_rects $via_a]"
                puts $fp "  B = $via_b"
                puts $fp "      net       = $net_b"
                puts $fp "      via_def   = $def_b"
                puts $fp "      cut_count = $count_b"
                puts $fp "      cut_area  = $area_b"
                puts $fp "      cut_rects = [tt_via_drc_cut_rects $via_b]"
                puts $fp "  cut_overlap_ratio = $overlap_ratio"

                # Strictly smaller total cut area wins deletion.
                if {$area_a < $area_b} {
                    set smaller $via_a
                    set decision_reason "strictly smaller cut area"
                } elseif {$area_b < $area_a} {
                    set smaller $via_b
                    set decision_reason "strictly smaller cut area"
                } else {
                    # Equal-area pair: only resolve duplicate-like single-cut
                    # vias on the SAME net. Different/unknown nets stay intact.
                    set smaller [tt_via_drc_choose_equal_area_delete $via_a $via_b]

                    if {$smaller eq ""} {
                        puts $fp "  Decision = KEEP BOTH (equal area but not safe for same-net tie-break)"
                        continue
                    }

                    set decision_reason "equal-area same-net duplicate-like tie-break"
                }

                set key [tt_via_drc_obj_key $smaller]

                if {![dict exists $delete_set $key]} {
                    dict set delete_set $key $smaller
                }

                puts $fp "  Decision = DELETE -> $smaller"
                puts $fp "  Reason   = $decision_reason"
            }
        }

        puts $fp ""
    }

    set delete_count [dict size $delete_set]

    puts $fp "===================================================================="
    puts $fp "Summary"
    puts $fp "===================================================================="
    puts $fp "Target markers    : [llength $markers]"
    puts $fp "Overlap via pairs : $overlap_pairs"
    puts $fp "Unique delete vias: $delete_count"
    puts $fp "Mode              : $mode"

    close $fp

    puts ""
    puts "======================================================================"
    puts " DRC-Guided Overlapping Special Via Cleanup"
    puts "======================================================================"
    puts "Mode              : $mode"
    puts "Target markers    : [llength $markers]"
    puts "Overlap via pairs : $overlap_pairs"
    puts "Unique delete vias: $delete_count"
    puts "Report            : $report_file"
    puts "======================================================================"

    if {$mode eq "preview"} {
        puts "PREVIEW ONLY: nothing deleted."
        puts "Run 'TT_via_drc_fix apply' after checking the report."
        puts ""
        return $delete_count
    }

    set deleted 0
    set failed  0

    foreach key [dict keys $delete_set] {
        set via [dict get $delete_set $key]

        if {[tt_via_drc_delete_one $via]} {
            incr deleted
        } else {
            incr failed
        }
    }

    deselect_obj -all

    puts ""
    puts "Deleted : $deleted"
    puts "Failed  : $failed"
    puts "Next    : check_drc"
    puts ""

    return $deleted
}


puts ""
puts "INFO: Loaded TT_fix_overlap_via_by_drc_v6.tcl"
puts "INFO: special_via geometry source = .cut_rects"
puts "INFO: Commands:"
puts "INFO:   TT_via_drc_stats"
puts "INFO:   TT_via_drc_fix preview"
puts "INFO:   TT_via_drc_fix apply"
puts ""
