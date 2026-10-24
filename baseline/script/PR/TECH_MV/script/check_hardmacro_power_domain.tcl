# =============================================================================
# Check hard-macro and power-domain placement before power planning
# =============================================================================
# Checks:
#   1. Every hard macro (PAD excluded) is fully inside the core boundary.
#   2. Every explicit rectangle of the macro's Power Domain is inside the core.
#   3. The hard-macro bbox is fully covered by the UNION of all rectangles of
#      its Power Domain. The Power Domain may be rectilinear/non-rectangular.
#
# The flow stops before powerplan if any check fails.
# =============================================================================

puts "User script [info script]"

# CHECK_BBOX_TOLERANCE is configured in setup/config/01_floorplan.config.tcl.

# -----------------------------------------------------------------------------
# Normalize Innovus bbox representations into:
#   {llx lly urx ury}
# Supports flat, point-pair, and redundant outer-list forms.
# -----------------------------------------------------------------------------
proc hm_pd_bbox_numeric_tokens {value {depth 0}} {
    if {$depth > 12} {
        return {}
    }

    set value [string trim $value]
    if {$value eq ""} {
        return {}
    }

    if {[string is double -strict $value]} {
        return [list $value]
    }

    if {[catch {set count [llength $value]}]} {
        return {}
    }

    if {$count == 1} {
        set inner [lindex $value 0]
        if {$inner eq $value} {
            return {}
        }
        return [hm_pd_bbox_numeric_tokens $inner [expr {$depth + 1}]]
    }

    set tokens {}
    foreach item $value {
        lappend tokens {*}[hm_pd_bbox_numeric_tokens $item [expr {$depth + 1}]]
    }
    return $tokens
}

proc hm_pd_normalize_bbox {bbox} {
    set values [hm_pd_bbox_numeric_tokens $bbox]
    if {[llength $values] != 4} {
        return ""
    }

    lassign $values llx lly urx ury
    if {$llx >= $urx || $lly >= $ury} {
        return ""
    }

    return [list $llx $lly $urx $ury]
}

proc hm_pd_bbox_inside {inner outer tolerance} {
    set inner [hm_pd_normalize_bbox $inner]
    set outer [hm_pd_normalize_bbox $outer]

    if {$inner eq "" || $outer eq ""} {
        return 0
    }

    lassign $inner illx illy iurx iury
    lassign $outer ollx olly ourx oury

    return [expr {($illx >= ($ollx - $tolerance)) && \
                  ($illy >= ($olly - $tolerance)) && \
                  ($iurx <= ($ourx + $tolerance)) && \
                  ($iury <= ($oury + $tolerance))}]
}

proc hm_pd_unique_sorted_numbers {values tolerance} {
    set sorted [lsort -real $values]
    set result {}

    foreach value $sorted {
        if {[llength $result] == 0 || \
            abs($value - [lindex $result end]) > $tolerance} {
            lappend result $value
        }
    }

    return $result
}

# -----------------------------------------------------------------------------
# Check whether one bbox is completely covered by the UNION of rects.
#
# The algorithm decomposes the target bbox into vertical x-slabs using every
# rectangle edge. Within each slab, it merges the y intervals provided by the
# Power Domain rectangles and verifies continuous coverage from target lly to
# target ury.
#
# This correctly handles rectilinear/non-rectangular Power Domains represented
# by multiple adjacent non-overlapping rectangles.
# -----------------------------------------------------------------------------
proc hm_pd_bbox_covered_by_rect_union {target_bbox rects tolerance} {
    set target_bbox [hm_pd_normalize_bbox $target_bbox]
    if {$target_bbox eq "" || [llength $rects] == 0} {
        return 0
    }

    lassign $target_bbox tllx tlly turx tury

    set clipped_rects {}
    set x_edges [list $tllx $turx]

    foreach raw_rect $rects {
        set rect [hm_pd_normalize_bbox $raw_rect]
        if {$rect eq ""} {
            continue
        }

        lassign $rect rllx rlly rurx rury

        # Intersection between this PD rectangle and target bbox.
        set cllx [expr {max($tllx, $rllx)}]
        set clly [expr {max($tlly, $rlly)}]
        set curx [expr {min($turx, $rurx)}]
        set cury [expr {min($tury, $rury)}]

        if {$cllx < ($curx - $tolerance) && \
            $clly < ($cury - $tolerance)} {
            lappend clipped_rects [list $cllx $clly $curx $cury]
            lappend x_edges $cllx $curx
        }
    }

    if {[llength $clipped_rects] == 0} {
        return 0
    }

    set x_edges [hm_pd_unique_sorted_numbers $x_edges $tolerance]

    for {set index 0} {$index < [expr {[llength $x_edges] - 1}]} {incr index} {
        set x0 [lindex $x_edges $index]
        set x1 [lindex $x_edges [expr {$index + 1}]]

        if {$x1 <= ($x0 + $tolerance)} {
            continue
        }

        # Only slabs inside the target bbox matter.
        set slab_llx [expr {max($x0, $tllx)}]
        set slab_urx [expr {min($x1, $turx)}]
        if {$slab_urx <= ($slab_llx + $tolerance)} {
            continue
        }

        set probe_x [expr {($slab_llx + $slab_urx) / 2.0}]
        set y_intervals {}

        foreach rect $clipped_rects {
            lassign $rect rllx rlly rurx rury
            if {$probe_x >= ($rllx - $tolerance) && \
                $probe_x <= ($rurx + $tolerance)} {
                lappend y_intervals [list $rlly $rury]
            }
        }

        if {[llength $y_intervals] == 0} {
            return 0
        }

        # Sort intervals by lower y and merge them.
        set y_intervals [lsort -real -index 0 $y_intervals]
        set covered_to $tlly

        foreach interval $y_intervals {
            lassign $interval interval_lly interval_ury

            if {$interval_ury <= ($covered_to + $tolerance)} {
                continue
            }

            # A gap exists before this interval.
            if {$interval_lly > ($covered_to + $tolerance)} {
                return 0
            }

            if {$interval_ury > $covered_to} {
                set covered_to $interval_ury
            }

            if {$covered_to >= ($tury - $tolerance)} {
                break
            }
        }

        if {$covered_to < ($tury - $tolerance)} {
            return 0
        }
    }

    return 1
}

proc hm_pd_get_inst_bbox {inst_obj} {
    set llx [get_db $inst_obj .bbox.ll.x]
    set lly [get_db $inst_obj .bbox.ll.y]
    set urx [get_db $inst_obj .bbox.ur.x]
    set ury [get_db $inst_obj .bbox.ur.y]
    return [list $llx $lly $urx $ury]
}

proc hm_pd_get_power_domain_name {inst_obj} {
    set pd_name ""

    catch {
        set pd_name [get_db $inst_obj .power_domain.name]
    }

    if {$pd_name eq ""} {
        catch {
            set pd_name [get_db $inst_obj .group.power_domain.name]
        }
    }

    if {[llength $pd_name] > 1} {
        set pd_name [lindex $pd_name 0]
    }

    return $pd_name
}

# Find the physical group(s) for one Power Domain.
# Prefer exact group name because Innovus commonly creates group:TOP/PD_NAME.
# Fall back to the group's .power_domain.name attribute.
proc hm_pd_get_domain_groups {pd_name} {
    set groups {}

    set by_name_filter [format {.name == "%s"} $pd_name]
    catch { set groups [get_db groups -if $by_name_filter] }

    if {$groups eq "" || [llength $groups] == 0} {
        set by_pd_filter [format {.power_domain.name == "%s"} $pd_name]
        catch { set groups [get_db groups -if $by_pd_filter] }
    }

    return $groups
}

proc hm_pd_get_domain_rects {pd_name} {
    set all_rects {}
    set groups [hm_pd_get_domain_groups $pd_name]

    foreach group_obj $groups {
        set rects [get_db $group_obj .rects]
        foreach rect $rects {
            set normalized [hm_pd_normalize_bbox $rect]
            if {$normalized ne ""} {
                lappend all_rects $normalized
            }
        }
    }

    return $all_rects
}

set core_bbox [hm_pd_normalize_bbox [get_db current_design .core_bbox]]
if {$core_bbox eq ""} {
    error "Cannot read a valid core boundary from: get_db current_design .core_bbox"
}

if {[info exists ::TECH_MV_REPORT_STAGE]} {
    set _hm_report_stage $::TECH_MV_REPORT_STAGE
} else { set _hm_report_stage 90 }
if {[info exists ::TECH_MV_REPORT_STEP]} {
    set _hm_report_step $::TECH_MV_REPORT_STEP
} else { set _hm_report_step 50 }
set report_file [tech_mv_report_path $_hm_report_step hardmacro_power_domain_check rpt $_hm_report_stage]
set report_fp [open $report_file w]

puts $report_fp "Hard Macro / Power Domain Core Check"
puts $report_fp "Design      : $TOP_MODULE"
puts $report_fp "Core bbox   : $core_bbox"
puts $report_fp "Tolerance   : $CHECK_BBOX_TOLERANCE"
puts $report_fp "PD geometry : union of all group rectangles"
puts $report_fp ""

puts "============================================================"
puts "Hard Macro / Power Domain Core Check"
puts "Core bbox: $core_bbox"
puts "PD containment: union of all Power Domain rectangles"
puts "============================================================"

set error_count   0
set warning_count 0
set macro_count   0
set checked_pd    [dict create]
set pd_rect_cache [dict create]

# base_class == block selects hard macros. PADs are excluded explicitly below.
set hard_macros [get_db insts -if {.base_cell.base_class == block}]

foreach inst_obj $hard_macros {
    set is_pad false
    catch { set is_pad [get_db $inst_obj .is_pad] }
    if {$is_pad eq "true" || $is_pad == 1} {
        continue
    }

    incr macro_count

    set inst_name [get_db $inst_obj .name]
    set inst_bbox [hm_pd_get_inst_bbox $inst_obj]
    set pd_name   [hm_pd_get_power_domain_name $inst_obj]

    puts $report_fp "Macro       : $inst_name"
    puts $report_fp "  bbox      : $inst_bbox"
    puts $report_fp "  domain    : $pd_name"

    # Check 1: hard macro must be inside core.
    if {![hm_pd_bbox_inside $inst_bbox $core_bbox $CHECK_BBOX_TOLERANCE]} {
        incr error_count
        puts $report_fp "  ERROR     : hard macro is outside the core boundary"
        puts "ERROR: $inst_name is outside the core boundary: $inst_bbox"
    } else {
        puts $report_fp "  core      : PASS"
    }

    # A hard macro in this MV flow must belong to a Power Domain.
    if {$pd_name eq ""} {
        incr error_count
        puts $report_fp "  ERROR     : no Power Domain is assigned"
        puts "ERROR: $inst_name has no Power Domain assignment"
        puts $report_fp ""
        continue
    }

    # Cache Power Domain rectangles because several macros can share one PD.
    if {![dict exists $pd_rect_cache $pd_name]} {
        set pd_rects [hm_pd_get_domain_rects $pd_name]
        dict set pd_rect_cache $pd_name $pd_rects
    } else {
        set pd_rects [dict get $pd_rect_cache $pd_name]
    }

    # Check 2: each explicit Power Domain rectangle must be inside core.
    if {![dict exists $checked_pd $pd_name]} {
        dict set checked_pd $pd_name 1

        if {[llength $pd_rects] == 0} {
            incr warning_count
            puts $report_fp "  WARNING   : Power Domain has no explicit floorplan rectangles"
            puts "WARNING: $pd_name has no explicit floorplan rectangles; only macro/core containment is checked"
        } else {
            puts $report_fp "  pd_rects  : [llength $pd_rects]"
            set pd_rect_index 0
            foreach pd_rect $pd_rects {
                incr pd_rect_index
                if {![hm_pd_bbox_inside $pd_rect $core_bbox $CHECK_BBOX_TOLERANCE]} {
                    incr error_count
                    puts $report_fp "  ERROR     : domain rectangle $pd_rect_index is outside core: $pd_rect"
                    puts "ERROR: Power Domain $pd_name rectangle is outside core: $pd_rect"
                }
            }
        }
    }

    # Check 3: the macro bbox must be covered by the UNION of all explicit
    # Power Domain rectangles. This supports non-rectangular PD geometry.
    if {[llength $pd_rects] > 0} {
        if {![hm_pd_bbox_covered_by_rect_union \
                $inst_bbox $pd_rects $CHECK_BBOX_TOLERANCE]} {
            incr error_count
            puts $report_fp "  ERROR     : hard macro is not fully covered by Power Domain union $pd_name"
            puts "ERROR: $inst_name is not fully covered by the union of Power Domain $pd_name rectangles"
        } else {
            puts $report_fp "  domain    : PASS (rect-union coverage)"
        }
    }

    puts $report_fp ""
}

puts $report_fp "============================================================"
puts $report_fp "Hard macros checked : $macro_count"
puts $report_fp "Errors              : $error_count"
puts $report_fp "Warnings            : $warning_count"
puts $report_fp "============================================================"
close $report_fp

puts "Hard macros checked : $macro_count"
puts "Errors              : $error_count"
puts "Warnings            : $warning_count"
puts "Report              : $report_file"

if {$error_count > 0} {
    error "Hard macro / Power Domain core check failed with $error_count error(s). Powerplan is stopped."
}

puts "PASS: All hard macros are inside the core and fully covered by their Power Domain rectangle unions."

unset -nocomplain _hm_report_stage _hm_report_step
