# Runtime adapter preserves the historical logical source path.
if {[info exists ::TECH_MV_RUNTIME_ROOT]} {
    info script [file join $::TECH_MV_RUNTIME_ROOT run/tool/01_floorplan/endcap_welltap/TT_proc_legalize_pd_endcaps.tcl]
} else {
    info script [file normalize [file join [file dirname [info script]] .. .. .. run/tool/01_floorplan/endcap_welltap/TT_proc_legalize_pd_endcaps.tcl]]
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
# TT_proc_legalize_pd_endcaps.tcl
# =============================================================================
# Direct-geometry legalization for per-Power-Domain LEFT/RIGHT EndCaps.
#
# IMPORTANT:
#   The movement/fix behavior is intentionally kept the SAME as the working V8:
#     - only X is adjusted
#     - maximum X shift is configured by PD_ENDCAP_LEGALIZE_MAX_SHIFT
#     - original place_status is restored after a successful move
#
# What changes in V10 is ONLY THE JUDGMENT:
#
#   V8/V9:
#     check_place marker
#       -> type=place
#       -> originator=check_place
#       -> subtype=SPOffGridViolation
#       -> only then inspect/move the EndCap
#
#   V10:
#     enumerate all ENDCAP_PD instances directly
#       -> require configured LEFT/RIGHT EndCap master
#       -> require site=core
#       -> find actual core-row endpoint at the EndCap center-Y
#       -> compare current bbox LLX to that legal endpoint
#       -> move only when 0 < abs(dx) <= MAX_SHIFT
#
# Markers are still counted/reported, but they are DIAGNOSTIC ONLY and are
# never used as the gate for fixing.  This lets the report expose cases where
# geometry says an EndCap is off-row while check_place has no SPOffGrid marker.
# =============================================================================

foreach _cfg_var {PD_ENDCAP_LEGALIZE_ENABLE PD_ENDCAP_LEGALIZE_SITE PD_ENDCAP_LEGALIZE_TOL PD_ENDCAP_LEGALIZE_MAX_SHIFT} {
    if {![info exists ::$_cfg_var]} {
        error "Missing config variable $_cfg_var. Source init.setup first."
    }
}
unset _cfg_var


# -----------------------------------------------------------------------------
# Geometry helpers
# -----------------------------------------------------------------------------
proc tt_pd_ec_norm_rect {raw} {
    set r $raw
    if {[llength $r] == 1 && [llength [lindex $r 0]] == 4} {
        set r [lindex $r 0]
    }
    if {[llength $r] != 4} {
        return {}
    }

    set out {}
    foreach v $r {
        if {![string is double -strict $v]} {
            return {}
        }
        lappend out [expr {double($v)}]
    }
    return $out
}

proc tt_pd_ec_norm_point {raw} {
    set p $raw
    if {[llength $p] == 1 && [llength [lindex $p 0]] == 2} {
        set p [lindex $p 0]
    }
    if {[llength $p] != 2} {
        return {}
    }

    set out {}
    foreach v $p {
        if {![string is double -strict $v]} {
            return {}
        }
        lappend out [expr {double($v)}]
    }
    return $out
}

proc tt_pd_ec_abs {v} {
    expr {$v < 0.0 ? -$v : $v}
}

# Y bucket key quantizes the coordinate using the scale in tt_pd_ec_ykey.
proc tt_pd_ec_ykey {y} {
    return [expr {wide(round(double($y) * 1000.0))}]
}

# -----------------------------------------------------------------------------
# EndCap helpers
# -----------------------------------------------------------------------------
proc tt_pd_ec_edge_master_names {} {
    set names {}

    foreach attr {add_endcaps_left_edge add_endcaps_right_edge} {
        set vals {}
        if {[catch {set vals [get_db $attr]}]} {
            continue
        }

        foreach val $vals {
            set name $val
            if {[string match "base_cell:*" $val]} {
                catch {set name [get_db $val .name]}
            }
            if {$name ne "" && [lsearch -exact $names $name] < 0} {
                lappend names $name
            }
        }
    }

    if {[llength $names] == 0} {
        set names [::tech_mv_library_value LIB_CELL_001]
    }
    return $names
}

proc tt_pd_ec_is_pd_endcap_name {name} {
    if {[info exists ::ENDCAP_POWER_DOMAIN_PREFIX] &&
        $::ENDCAP_POWER_DOMAIN_PREFIX ne ""} {
        set prefix $::ENDCAP_POWER_DOMAIN_PREFIX
    } else {
        set prefix ENDCAP_PD
    }
    return [string match "*${prefix}*" $name]
}

proc tt_pd_ec_build_core_row_index {site_name} {
    set row_index [dict create]
    set row_count 0

    foreach row [get_db rows] {
        set row_site ""
        catch {set row_site [get_db $row .site.name]}
        if {$row_site ne $site_name} {
            continue
        }

        set r [tt_pd_ec_norm_rect [get_db $row .rect]]
        if {[llength $r] != 4} {
            continue
        }

        lassign $r rllx rlly rurx rury
        set center_y [expr {($rlly + $rury) / 2.0}]
        set key [tt_pd_ec_ykey $center_y]

        dict lappend row_index $key [list $row $r]
        incr row_count
    }

    return [list $row_count $row_index]
}

# Returns:
#   {target_bbox_llx row_object row_rect side abs_dx signed_dx}
proc tt_pd_ec_find_nearest_row_endpoint {inst_bbox core_row_index tol} {
    set b [tt_pd_ec_norm_rect $inst_bbox]
    if {[llength $b] != 4} {
        return {}
    }

    lassign $b illx illy iurx iury
    set width [expr {$iurx - $illx}]
    if {$width <= $tol} {
        return {}
    }

    set center_y [expr {($illy + $iury) / 2.0}]
    set center_key [tt_pd_ec_ykey $center_y]

    set best_x ""
    set best_row ""
    set best_rect ""
    set best_side ""
    set best_dx 1.0e30
    set best_signed_dx 0.0
    set best_ydiff 1.0e30

    # Search neighboring Y buckets around the EndCap center-Y; dk defines the search radius.
    set local_rows {}
    for {set dk -1} {$dk <= 1} {incr dk} {
        set key [expr {$center_key + $dk}]
        if {[dict exists $core_row_index $key]} {
            foreach item [dict get $core_row_index $key] {
                lappend local_rows $item
            }
        }
    }

    foreach item $local_rows {
        set row [lindex $item 0]
        set r   [lindex $item 1]
        lassign $r rllx rlly rurx rury

        if {$center_y < ($rlly - $tol) || $center_y > ($rury + $tol)} {
            continue
        }

        set row_center_y [expr {($rlly + $rury) / 2.0}]
        set ydiff [tt_pd_ec_abs [expr {$center_y - $row_center_y}]]

        foreach candidate [list \
            [list left  $rllx] \
            [list right [expr {$rurx - $width}]] \
        ] {
            set side [lindex $candidate 0]
            set x    [expr {double([lindex $candidate 1])}]
            set signed_dx [expr {$x - $illx}]
            set dx [tt_pd_ec_abs $signed_dx]

            if {$dx < ($best_dx - $tol) ||
                ([tt_pd_ec_abs [expr {$dx - $best_dx}]] <= $tol &&
                 $ydiff < $best_ydiff)} {
                set best_x $x
                set best_row $row
                set best_rect $r
                set best_side $side
                set best_dx $dx
                set best_signed_dx $signed_dx
                set best_ydiff $ydiff
            }
        }
    }

    if {$best_x eq ""} {
        return {}
    }

    return [list $best_x $best_row $best_rect $best_side $best_dx $best_signed_dx]
}

# -----------------------------------------------------------------------------
# Marker helpers
# -----------------------------------------------------------------------------
proc tt_pd_ec_offgrid_marker_insts {} {
    set result {}
    set seen [dict create]

    set total_markers 0
    set check_place_markers 0
    set offgrid_markers 0

    foreach marker [get_db markers] {
        incr total_markers

        set type ""
        set originator ""
        set subtype ""

        catch {set type [get_db $marker .type]}
        catch {set originator [get_db $marker .originator]}
        catch {set subtype [get_db $marker .subtype]}

        if {$type ne "place" || $originator ne "check_place"} {
            continue
        }
        incr check_place_markers

        if {$subtype ne "SPOffGridViolation"} {
            continue
        }
        incr offgrid_markers

        set objs {}
        catch {set objs [get_db $marker .objects]}

        foreach obj $objs {
            set name ""
            set master ""
            set site ""

            catch {set name [get_db $obj .name]}
            catch {set master [get_db $obj .base_cell.name]}
            catch {set site [get_db $obj .base_cell.site.name]}

            if {$name eq ""} {
                continue
            }
            if {![tt_pd_ec_is_pd_endcap_name $name]} {
                continue
            }

            set key $name
            if {[dict exists $seen $key]} {
                continue
            }
            dict set seen $key 1

            lappend result [list $marker $obj $name $master $site]
        }
    }

    return [list $total_markers $check_place_markers $offgrid_markers $result]
}


# -----------------------------------------------------------------------------
# Direct EndCap enumeration
# -----------------------------------------------------------------------------
proc tt_pd_ec_all_pd_endcap_insts {} {
    set result {}

    foreach inst [get_db insts] {
        set name ""
        catch {set name [get_db $inst .name]}

        if {$name eq "" || ![tt_pd_ec_is_pd_endcap_name $name]} {
            continue
        }

        set master ""
        set site ""
        catch {set master [get_db $inst .base_cell.name]}
        catch {set site [get_db $inst .base_cell.site.name]}

        lappend result [list $inst $name $master $site]
    }

    return $result
}

# Convert marker-driven results to a simple instance-name dictionary.
# This is used ONLY for comparison/reporting.
proc tt_pd_ec_marker_name_dict {marker_insts} {
    set result [dict create]

    foreach item $marker_insts {
        # marker_insts entry:
        #   {marker inst inst_name master site}
        set marker    [lindex $item 0]
        set inst_name [lindex $item 2]

        if {$inst_name ne ""} {
            dict set result $inst_name $marker
        }
    }

    return $result
}

# -----------------------------------------------------------------------------
# Main procedure
# -----------------------------------------------------------------------------
proc tech_mv_legalize_pd_endcaps {} {
    if {!$::PD_ENDCAP_LEGALIZE_ENABLE} {
        puts "INFO: PD EndCap legalization is disabled."
        return 0
    }

    set tol       [expr {double($::PD_ENDCAP_LEGALIZE_TOL)}]
    set max_shift [expr {double($::PD_ENDCAP_LEGALIZE_MAX_SHIFT)}]
    set site_name $::PD_ENDCAP_LEGALIZE_SITE
    set edge_masters [tt_pd_ec_edge_master_names]

    set report_dir [tech_mv_report_dir 90 endcap_legalize]
    set report_file [tech_mv_report_path 60 pd_endcap_legalize rpt 90 endcap_legalize]
    set fp [open $report_file w]

    # Build actual site=core row geometry.
    lassign [tt_pd_ec_build_core_row_index $site_name] row_count core_row_index

    # Marker information is diagnostic only.
    lassign [tt_pd_ec_offgrid_marker_insts] \
        total_markers check_place_markers offgrid_markers marker_insts
    set marker_name_dict [tt_pd_ec_marker_name_dict $marker_insts]

    # Direct object-driven candidate universe.
    set all_pd_endcaps [tt_pd_ec_all_pd_endcap_insts]

    puts $fp "PD EndCap direct-geometry legalization V10"
    puts $fp "Fix behavior          = working V8 movement/status behavior"
    puts $fp "Judgment              = direct geometry; markers are diagnostic only"
    puts $fp "site                  = $site_name"
    puts $fp "core rows             = $row_count"
    puts $fp "core row Y buckets    = [dict size $core_row_index]"
    puts $fp "edge masters          = $edge_masters"
    puts $fp "max X shift           = $max_shift"
    puts $fp "tolerance             = $tol"
    puts $fp ""

    set total_pd_endcaps [llength $all_pd_endcaps]
    set eligible 0
    set moved 0
    set already_legal 0
    set geometry_needs_move 0
    set geometry_needs_move_no_marker 0
    set geometry_needs_move_with_marker 0
    set no_row 0
    set too_far 0
    set bad_geom 0
    set move_fail 0
    set wrong_master 0
    set wrong_site 0

    foreach item $all_pd_endcaps {
        lassign $item inst inst_name master master_site

        set marker "<NONE>"
        set has_marker 0
        if {[dict exists $marker_name_dict $inst_name]} {
            set marker [dict get $marker_name_dict $inst_name]
            set has_marker 1
        }

        if {[lsearch -exact $edge_masters $master] < 0} {
            incr wrong_master
            puts $fp "SKIP wrong_edge_master name=$inst_name master=$master marker=$marker"
            continue
        }

        if {$master_site ne $site_name} {
            incr wrong_site
            puts $fp "SKIP wrong_site name=$inst_name master=$master site=$master_site marker=$marker"
            continue
        }

        incr eligible

        set b [tt_pd_ec_norm_rect [get_db $inst .bbox]]
        set loc {}
        catch {set loc [get_db $inst .location]}
        set loc [tt_pd_ec_norm_point $loc]

        if {[llength $b] != 4 || [llength $loc] != 2} {
            incr bad_geom
            puts $fp "SKIP bad_geometry name=$inst_name bbox={$b} loc={$loc} marker=$marker"
            continue
        }

        set endpoint [tt_pd_ec_find_nearest_row_endpoint $b $core_row_index $tol]
        if {[llength $endpoint] == 0} {
            incr no_row
            puts $fp "SKIP no_core_row_at_center_y name=$inst_name bbox={$b} marker=$marker"
            continue
        }

        lassign $endpoint target_bbox_x best_row best_rect best_side best_dx signed_dx

        # Direct geometry says it is already exactly on a legal row endpoint.
        if {$best_dx <= $tol} {
            incr already_legal
            puts $fp "KEEP geometry_legal name=$inst_name bbox={$b} row=[get_db $best_row .name] side=$best_side marker=$marker"
            continue
        }

        incr geometry_needs_move
        if {$has_marker} {
            incr geometry_needs_move_with_marker
        } else {
            incr geometry_needs_move_no_marker
        }

        # Preserve the V8 safety bound.
        if {$best_dx > ($max_shift + $tol)} {
            incr too_far
            puts $fp "SKIP geometry_off_but_shift_too_large name=$inst_name master=$master oldBBox={$b} targetBBoxLLX=$target_bbox_x shift=$best_dx row=[get_db $best_row .name] rowRect={$best_rect} side=$best_side marker=$marker"
            continue
        }

        set old_status ""
        catch {set old_status [get_db $inst .place_status]}

        set old_loc_x [expr {double([lindex $loc 0])}]
        set old_loc_y [expr {double([lindex $loc 1])}]
        set new_loc_x [expr {$old_loc_x + $signed_dx}]
        set new_loc_y $old_loc_y

        # ---------------------------------------------------------------------
        # Keep the proven V8 fix behavior unchanged:
        #   placed -> move -> restore original status
        # ---------------------------------------------------------------------
        set ok 1
        if {[catch {
            set_db $inst .place_status placed
            set_db $inst .location [list $new_loc_x $new_loc_y]

            if {$old_status eq "fixed"} {
                set_db $inst .place_status fixed
            } elseif {$old_status ne ""} {
                set_db $inst .place_status $old_status
            }
        } err]} {
            set ok 0
            catch {set_db $inst .place_status $old_status}
            incr move_fail
            puts $fp "FAIL name=$inst_name error={$err} marker=$marker"
        }

        if {$ok} {
            incr moved
            puts $fp "MOVE direct_geometry name=$inst_name master=$master side=$best_side oldBBox={$b} dx=$signed_dx oldLoc={$loc} newLoc={$new_loc_x $new_loc_y} oldStatus=$old_status row=[get_db $best_row .name] rowRect={$best_rect} marker=$marker"
        }
    }

    puts $fp ""
    puts $fp "======================================================================"
    puts $fp "Summary"
    puts $fp "======================================================================"
    puts $fp "All DB markers                    : $total_markers"
    puts $fp "check_place markers               : $check_place_markers"
    puts $fp "SPOffGrid markers                 : $offgrid_markers"
    puts $fp "Marker-matched PD EndCaps         : [llength $marker_insts]"
    puts $fp "All PD EndCaps                    : $total_pd_endcaps"
    puts $fp "Eligible edge EndCaps             : $eligible"
    puts $fp "Geometry already legal            : $already_legal"
    puts $fp "Geometry needs move               : $geometry_needs_move"
    puts $fp "  with SPOffGrid marker           : $geometry_needs_move_with_marker"
    puts $fp "  WITHOUT SPOffGrid marker        : $geometry_needs_move_no_marker"
    puts $fp "Moved                             : $moved"
    puts $fp "No core row @ centerY             : $no_row"
    puts $fp "Shift too large                   : $too_far"
    puts $fp "Wrong edge master                 : $wrong_master"
    puts $fp "Wrong site                        : $wrong_site"
    puts $fp "Bad geometry                      : $bad_geom"
    puts $fp "Move failures                     : $move_fail"
    close $fp

    puts ""
    puts "======================================================================"
    puts " PD EndCap Direct-Geometry Legalization V10"
    puts "======================================================================"
    puts "All DB markers                    : $total_markers"
    puts "check_place markers               : $check_place_markers"
    puts "SPOffGrid markers                 : $offgrid_markers"
    puts "Marker-matched PD EndCaps         : [llength $marker_insts]"
    puts "All PD EndCaps                    : $total_pd_endcaps"
    puts "Eligible edge EndCaps             : $eligible"
    puts "Geometry already legal            : $already_legal"
    puts "Geometry needs move               : $geometry_needs_move"
    puts "  with SPOffGrid marker           : $geometry_needs_move_with_marker"
    puts "  WITHOUT SPOffGrid marker        : $geometry_needs_move_no_marker"
    puts "Moved                             : $moved"
    puts "No core row @ centerY             : $no_row"
    puts "Shift too large                   : $too_far"
    puts "Wrong edge master                 : $wrong_master"
    puts "Wrong site                        : $wrong_site"
    puts "Bad geometry                      : $bad_geom"
    puts "Move failures                     : $move_fail"
    puts "Report                            : $report_file"
    puts "======================================================================"

    if {$move_fail > 0} {
        error "PD EndCap legalization had $move_fail move failure(s). See $report_file"
    }

    return $moved
}

