# Runtime adapter preserves the historical logical source path.
if {[info exists ::TECH_MV_RUNTIME_ROOT]} {
    info script [file join $::TECH_MV_RUNTIME_ROOT run/tool/05_route/drc/TT_delete_VIA8_by_DRC.tcl]
} else {
    info script [file normalize [file join [file dirname [info script]] .. .. .. run/tool/05_route/drc/TT_delete_VIA8_by_DRC.tcl]]
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
# =============================================================================
# TT_delete_VIA8_by_DRC.tcl
#
# Purpose:
#   After M9 power-stripe generation, remove SPECIAL VIA objects that are
#   directly associated with DRC violations on VIA8.
#
# Usage in Innovus:
#   source ./TT_delete_VIA8_by_DRC.tcl
#
# The file is self-running: sourcing it performs the cleanup.
#
# Policy:
#   1. Run check_drc first so the marker database is current.
#   2. Only DRC markers whose .layer.name is exactly VIA8 are considered.
#   3. Search only SPECIAL VIA objects in each marker bbox.
#   4. Verify actual VIA cut geometry through .cut_rects.
#   5. Delete each matching SPECIAL VIA at most once.
#   6. Run check_drc again after deletion.
#
# This tool does NOT modify powerplan.tcl or any flow file.
# =============================================================================

namespace eval ::TT_VIA8_DRC {
    variable deleted 0
    variable failed 0
    variable marker_count 0
    variable candidate_count 0
    variable seen_vias

    proc normalize_rect {rect} {
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

        foreach v [list $llx $lly $urx $ury] {
            if {![string is double -strict $v]} {
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

    proc rect_overlap {a b} {
        set a [normalize_rect $a]
        set b [normalize_rect $b]

        if {$a eq "" || $b eq ""} {
            return 0
        }

        lassign $a a_llx a_lly a_urx a_ury
        lassign $b b_llx b_lly b_urx b_ury

        set llx [expr {max($a_llx, $b_llx)}]
        set lly [expr {max($a_lly, $b_lly)}]
        set urx [expr {min($a_urx, $b_urx)}]
        set ury [expr {min($a_ury, $b_ury)}]

        return [expr {$llx < $urx && $lly < $ury}]
    }

    proc via_cut_rects {via} {
        set rects {}
        if {[catch {set rects [get_db $via .cut_rects]} err]} {
            puts "WARN: cannot read .cut_rects from $via : $err"
            return {}
        }

        set result {}
        foreach rect $rects {
            set nr [normalize_rect $rect]
            if {$nr ne ""} {
                lappend result $nr
            }
        }
        return $result
    }

    proc via_overlaps_marker {via marker_bbox} {
        foreach rect [via_cut_rects $via] {
            if {[rect_overlap $rect $marker_bbox]} {
                return 1
            }
        }
        return 0
    }

    proc delete_via {via} {
        if {![catch {delete_obj $via} err]} {
            return 1
        }

        puts "ERROR: delete_obj failed for $via"
        puts "ERROR: $err"
        return 0
    }

    proc run {} {
        variable deleted
        variable failed
        variable marker_count
        variable candidate_count
        variable seen_vias

        set deleted 0
        set failed 0
        set marker_count 0
        set candidate_count 0
        set seen_vias [dict create]

        puts ""
        puts "======================================================================"
        puts " TT VIA8 DRC CLEANUP"
        puts "======================================================================"
        puts "Step 1: check_drc"

        # Refresh DRC markers before identifying the violating VIA8 objects.
        if {[catch {check_drc} err]} {
            error "check_drc failed: $err"
        }

        set markers {}

        foreach marker [get_db markers] {
            set layer ""
            catch {set layer [get_db $marker .layer.name]}

            if {$layer eq "VIA8"} {
                lappend markers $marker
            }
        }

        set marker_count [llength $markers]

        puts "VIA8 DRC markers : $marker_count"

        if {$marker_count == 0} {
            puts "INFO: No VIA8 DRC markers found."
            puts "======================================================================"
            return 0
        }

        foreach marker $markers {
            set marker_bbox ""
            catch {set marker_bbox [get_db $marker .bbox]}

            if {$marker_bbox eq ""} {
                puts "WARN: marker $marker has no bbox; skipped."
                continue
            }

            set vias {}

            if {[catch {
                set vias [get_obj_in_area \
                    -area $marker_bbox \
                    -obj_type special_via \
                    -overlap_only \
                    -layers [::tech_mv_library_value LIB_TECH_005]]
            } err]} {
                puts "WARN: special_via query failed for marker $marker"
                puts "WARN: $err"
                continue
            }

            foreach via $vias {
                incr candidate_count

                set key [string trim $via]

                if {$key eq "" || [dict exists $seen_vias $key]} {
                    continue
                }

                # Do not rely only on the object-area query.  Confirm that an
                # actual VIA cut rectangle intersects the DRC marker.
                if {![via_overlaps_marker $via $marker_bbox]} {
                    continue
                }

                dict set seen_vias $key 1

                set via_def ""
                catch {set via_def [get_db $via .via_def]}

                puts "DELETE VIA8 special_via:"
                puts "  via     = $via"
                puts "  via_def = $via_def"
                puts "  marker  = $marker"
                puts "  bbox    = $marker_bbox"

                if {[delete_via $via]} {
                    incr deleted
                } else {
                    incr failed
                }
            }
        }

        puts ""
        puts "======================================================================"
        puts " TT VIA8 DRC CLEANUP - DELETE SUMMARY"
        puts "======================================================================"
        puts "VIA8 DRC markers : $marker_count"
        puts "Via candidates   : $candidate_count"
        puts "Deleted vias     : $deleted"
        puts "Delete failures  : $failed"
        puts "======================================================================"

        if {$failed > 0} {
            error "VIA8 DRC cleanup finished with $failed delete failure(s)."
        }

        puts ""
        puts "Step 2: re-run check_drc"
        if {[catch {check_drc} err]} {
            error "Post-cleanup check_drc failed: $err"
        }

        set remaining 0
        foreach marker [get_db markers] {
            set layer ""
            catch {set layer [get_db $marker .layer.name]}
            if {$layer eq "VIA8"} {
                incr remaining
            }
        }

        puts ""
        puts "======================================================================"
        puts " TT VIA8 DRC CLEANUP - FINAL"
        puts "======================================================================"
        puts "Deleted vias        : $deleted"
        puts "Remaining VIA8 DRC : $remaining"
        puts "======================================================================"

        return $deleted
    }
}

# Self-running entry point.
::TT_VIA8_DRC::run
