# Runtime adapter preserves the historical logical source path.
if {[info exists ::TECH_MV_RUNTIME_ROOT]} {
    info script [file join $::TECH_MV_RUNTIME_ROOT run/tool/05_route/drc/TT_DRC_fix_via8_after_m9.tcl]
}
# Load definitions only; no APR action or setup reload is performed here.
if {![llength [info commands ::tech_mv_library_value]]} {
    if {[info exists ::TOOL_DIR]} {
        source -quiet [file join $::TECH_MV_RUNTIME_ROOT .. script PR TECH_MV script 00_common private_parameter_config.tcl]
    } else {
        source -quiet [file join $::TECH_MV_RUNTIME_ROOT .. script PR TECH_MV script 00_common private_parameter_config.tcl]
    }
}
# DRC_RULE_SPECIFIC_TOOL: named/configured DRC subtype selection is technology-dependent.
# DRC_RULE_REVIEW: Rule names, filters and repair logic are retained for manual planning.
# PUBLIC_EXPORT_REVIEW_REQUIRED: residual technology candidates require manual review.
# =============================================================================
# TT_DRC_fix_via8_after_m9.tcl
#
# TECH_MV PR6: DRC-guided cleanup for VIA8 created during M9 stripe generation.
#
# Purpose:
#   After the global M9 PG stripe is generated, run a focused DRC check and
#   remove only conflicting SPECIAL VIA objects on VIA8.
#
# This tool intentionally reuses the same marker/VIA discovery methodology as
# TT_fix_overlap_via_by_drc.tcl:
#   - DRC markers: get_db markers, .subtype, .bbox, .layer.name
#   - VIA query: get_obj_in_area -obj_type special_via -overlap_only -layers
#   - VIA geometry: .cut_rects
#   - deletion: delete_obj, with the existing floorplan-selection fallback
#
# Target DRC subtypes:
#   Adjacent_Cut_Spacing
#   Cut_Short
#   Cut_Spacing
#
# Policy:
#   1. Only markers whose layer is VIA8 are considered.
#   2. Only SPECIAL VIA objects returned inside the marker bbox are considered.
#   3. Actual CUT rectangle overlap is required before a via can be deleted.
#   4. When two overlapping VIA8 objects are found, delete only the one with
#      the strictly smaller total CUT rectangle area.
#   5. Equal-size overlapping vias are NOT guessed/deleted automatically.
#   6. The same VIA8 object is deleted at most once.
#   7. Preview is the default when called manually; APPLY is explicit.
#   8. This tool never deletes WellTap/SDP instances and never modifies wires.
#
# Commands:
#   TT_via8_drc_stats
#   TT_via8_drc_cleanup preview
#   TT_via8_drc_cleanup apply
#
# =============================================================================

set ::TT_VIA8_DRC_SUBTYPES {
    Adjacent_Cut_Spacing
    Cut_Short
    Cut_Spacing
}

proc tt_via8_normalize_rect {rect} {
    if {[catch {set n [llength $rect]}]} {
        return ""
    }
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
        set t $llx; set llx $urx; set urx $t
    }
    if {$lly > $ury} {
        set t $lly; set lly $ury; set ury $t
    }
    if {$llx >= $urx || $lly >= $ury} {
        return ""
    }
    return [list $llx $lly $urx $ury]
}

proc tt_via8_rect_area {rect} {
    set rect [tt_via8_normalize_rect $rect]
    if {$rect eq ""} { return 0.0 }
    lassign $rect llx lly urx ury
    return [expr {double($urx-$llx) * double($ury-$lly)}]
}

proc tt_via8_rect_intersection_area {a b} {
    set a [tt_via8_normalize_rect $a]
    set b [tt_via8_normalize_rect $b]
    if {$a eq "" || $b eq ""} { return 0.0 }
    lassign $a a_llx a_lly a_urx a_ury
    lassign $b b_llx b_lly b_urx b_ury
    set llx [expr {max($a_llx,$b_llx)}]
    set lly [expr {max($a_lly,$b_lly)}]
    set urx [expr {min($a_urx,$b_urx)}]
    set ury [expr {min($a_ury,$b_ury)}]
    if {$llx >= $urx || $lly >= $ury} { return 0.0 }
    return [expr {double($urx-$llx) * double($ury-$lly)}]
}

proc tt_via8_cut_rects {via} {
    set rects {}
    if {[catch {set rects [get_db $via .cut_rects]} err]} {
        puts "WARNING: Cannot read .cut_rects from $via"
        puts "WARNING: $err"
        return {}
    }
    set result {}
    foreach rect $rects {
        set nr [tt_via8_normalize_rect $rect]
        if {$nr ne ""} { lappend result $nr }
    }
    return $result
}

proc tt_via8_total_cut_area {via} {
    set area 0.0
    foreach rect [tt_via8_cut_rects $via] {
        set area [expr {$area + [tt_via8_rect_area $rect]}]
    }
    return $area
}

proc tt_via8_cut_count {via} {
    return [llength [tt_via8_cut_rects $via]]
}

proc tt_via8_vias_overlap {a b} {
    foreach ra [tt_via8_cut_rects $a] {
        foreach rb [tt_via8_cut_rects $b] {
            if {[tt_via8_rect_intersection_area $ra $rb] > 0.0} {
                return true
            }
        }
    }
    return false
}

proc tt_via8_marker_is_target {marker} {
    set subtype ""
    set layer ""
    catch {set subtype [get_db $marker .subtype]}
    catch {set layer [get_db $marker .layer.name]}
    return [expr {
        [string toupper $layer] eq "VIA8" &&
        [lsearch -exact $::TT_VIA8_DRC_SUBTYPES $subtype] >= 0
    }]
}

proc tt_via8_get_candidates {marker} {
    set bbox [get_db $marker .bbox]
    set objects {}
    set cmd [list get_obj_in_area \
        -area $bbox \
        -obj_type special_via \
        -overlap_only \
        -layers [::tech_mv_library_value LIB_TECH_005]]
    if {[catch {set objects [uplevel #0 $cmd]} err]} {
        puts "WARNING: Cannot query VIA8 special_via in marker $marker"
        puts "WARNING: $err"
        return {}
    }
    set seen [dict create]
    set result {}
    foreach via $objects {
        set key [string trim $via]
        if {$key eq "" || [dict exists $seen $key]} { continue }
        if {[llength [tt_via8_cut_rects $via]] == 0} { continue }
        dict set seen $key 1
        lappend result $via
    }
    return $result
}

proc tt_via8_delete_one {via} {
    if {![catch {delete_obj $via} err]} {
        return true
    }
    deselect_obj -all
    if {[catch {
        select_obj $via
        delete_selected_from_floorplan
        deselect_obj -all
    } err2]} {
        deselect_obj -all
        puts "ERROR: Cannot delete VIA8 $via"
        puts "ERROR: delete_obj: $err"
        puts "ERROR: fallback  : $err2"
        return false
    }
    return true
}

proc TT_via8_drc_stats {} {
    set counts [dict create]
    set via8_targets 0
    foreach marker [get_db markers] {
        set subtype ""
        set layer ""
        catch {set subtype [get_db $marker .subtype]}
        catch {set layer [get_db $marker .layer.name]}
        if {$subtype eq ""} { set subtype "<NO_SUBTYPE>" }
        if {![dict exists $counts $subtype]} { dict set counts $subtype 0 }
        dict incr counts $subtype
        if {[string toupper $layer] eq "VIA8" &&
            [lsearch -exact $::TT_VIA8_DRC_SUBTYPES $subtype] >= 0} {
            incr via8_targets
        }
    }
    puts ""
    puts "======================================================================"
    puts " VIA8 DRC Marker Statistics"
    puts "======================================================================"
    foreach subtype [lsort [dict keys $counts]] {
        puts [format "%-32s %6d" $subtype [dict get $counts $subtype]]
    }
    puts "Target VIA8 markers : $via8_targets"
    puts "======================================================================"
    puts ""
    return $via8_targets
}

proc TT_via8_drc_cleanup {{mode preview}} {
    set mode [string tolower [string trim $mode]]
    if {$mode ni {preview apply}} {
        error "Usage: TT_via8_drc_cleanup ?preview|apply?"
    }

    set markers {}
    foreach marker [get_db markers] {
        if {[tt_via8_marker_is_target $marker]} {
            lappend markers $marker
        }
    }

    set report_file ""
    if {[info exists ::TT_VIA8_DRC_REPORT_FILE] &&
        $::TT_VIA8_DRC_REPORT_FILE ne ""} {
        set report_file $::TT_VIA8_DRC_REPORT_FILE
    } elseif {[info exists ::REPORT_DIR] && $::REPORT_DIR ne ""} {
        file mkdir $::REPORT_DIR
        set report_file [file join $::REPORT_DIR "via8_after_m9_cleanup_${mode}.rpt"]
    } else {
        set report_file "via8_after_m9_cleanup_${mode}.rpt"
    }

    set fp [open $report_file w]
    puts $fp "TECH_MV PR6 VIA8 DRC cleanup"
    puts $fp "Mode           : $mode"
    puts $fp "Target layer   : VIA8"
    puts $fp "Target subtypes: $::TT_VIA8_DRC_SUBTYPES"
    puts $fp "Marker count   : [llength $markers]"
    puts $fp ""

    set delete_set [dict create]
    set overlap_pairs 0
    set equal_pairs 0

    foreach marker $markers {
        set subtype [get_db $marker .subtype]
        set bbox [get_db $marker .bbox]
        set vias [tt_via8_get_candidates $marker]
        set n [llength $vias]

        puts $fp "--------------------------------------------------------------------"
        puts $fp "Marker subtype : $subtype"
        puts $fp "Marker layer   : [get_db $marker .layer.name]"
        puts $fp "Marker bbox    : $bbox"
        puts $fp "Via candidates : $n"

        if {$n < 2} {
            puts $fp "Action         : none (<2 VIA8 special_via candidates)"
            continue
        }

        for {set i 0} {$i < $n} {incr i} {
            set via_a [lindex $vias $i]
            for {set j [expr {$i+1}]} {$j < $n} {incr j} {
                set via_b [lindex $vias $j]
                if {![tt_via8_vias_overlap $via_a $via_b]} { continue }
                incr overlap_pairs
                set area_a [tt_via8_total_cut_area $via_a]
                set area_b [tt_via8_total_cut_area $via_b]
                puts $fp ""
                puts $fp "OVERLAPPING VIA8 PAIR"
                puts $fp "  A = $via_a"
                puts $fp "      cut_count = [tt_via8_cut_count $via_a]"
                puts $fp "      cut_area  = $area_a"
                puts $fp "      cut_rects = [tt_via8_cut_rects $via_a]"
                puts $fp "  B = $via_b"
                puts $fp "      cut_count = [tt_via8_cut_count $via_b]"
                puts $fp "      cut_area  = $area_b"
                puts $fp "      cut_rects = [tt_via8_cut_rects $via_b]"

                if {$area_a < $area_b} {
                    set smaller $via_a
                } elseif {$area_b < $area_a} {
                    set smaller $via_b
                } else {
                    incr equal_pairs
                    puts $fp "  Decision = KEEP BOTH (same total cut area)"
                    continue
                }

                set key [string trim $smaller]
                dict set delete_set $key $smaller
                puts $fp "  Decision = DELETE SMALLER -> $smaller"
            }
        }
    }

    set delete_count [dict size $delete_set]
    puts $fp "===================================================================="
    puts $fp "Summary"
    puts $fp "===================================================================="
    puts $fp "Target markers     : [llength $markers]"
    puts $fp "Overlap via pairs  : $overlap_pairs"
    puts $fp "Equal-size pairs   : $equal_pairs"
    puts $fp "Unique delete vias : $delete_count"
    puts $fp "Mode               : $mode"

    if {$mode eq "preview"} {
        puts $fp "PREVIEW ONLY: nothing deleted."
        close $fp
        puts ""
        puts "======================================================================"
        puts " VIA8 AFTER-M9 DRC CLEANUP — PREVIEW"
        puts "======================================================================"
        puts "Target markers     : [llength $markers]"
        puts "Overlap via pairs  : $overlap_pairs"
        puts "Equal-size pairs   : $equal_pairs"
        puts "Unique delete vias : $delete_count"
        puts "Report             : $report_file"
        puts "PREVIEW ONLY: nothing deleted."
        puts "======================================================================"
        return $delete_count
    }

    set deleted 0
    set failed 0
    foreach key [dict keys $delete_set] {
        set via [dict get $delete_set $key]
        if {[tt_via8_delete_one $via]} {
            incr deleted
        } else {
            incr failed
        }
    }

    puts $fp "Deleted vias      : $deleted"
    puts $fp "Delete failures   : $failed"
    close $fp
    deselect_obj -all

    puts ""
    puts "======================================================================"
    puts " VIA8 AFTER-M9 DRC CLEANUP"
    puts "======================================================================"
    puts "Target markers     : [llength $markers]"
    puts "Overlap via pairs  : $overlap_pairs"
    puts "Equal-size pairs   : $equal_pairs"
    puts "Unique delete vias : $delete_count"
    puts "Deleted vias       : $deleted"
    puts "Delete failures    : $failed"
    puts "Report             : $report_file"
    puts "======================================================================"

    if {$failed > 0} {
        error "VIA8 DRC cleanup had $failed delete failure(s). See $report_file"
    }
    return $deleted
}

puts ""
puts "INFO: Loaded TT_DRC_fix_via8_after_m9.tcl"
puts "INFO: Target layer = VIA8"
puts "INFO: Target subtypes = $::TT_VIA8_DRC_SUBTYPES"
puts "INFO: Commands: TT_via8_drc_stats / TT_via8_drc_cleanup preview|apply"
puts ""
