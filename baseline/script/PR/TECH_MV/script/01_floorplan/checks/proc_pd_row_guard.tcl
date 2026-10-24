# Runtime adapter preserves the historical logical source path.
if {[info exists ::TECH_MV_RUNTIME_ROOT]} {
    info script [file join $::TECH_MV_RUNTIME_ROOT run/tool/01_floorplan/checks/TT_proc_pd_row_guard.tcl]
} else {
    info script [file normalize [file join [file dirname [info script]] .. .. .. run/tool/01_floorplan/checks/TT_proc_pd_row_guard.tcl]]
}
# =============================================================================
# TT_proc_pd_row_guard.tcl
# =============================================================================
# Power-Domain halo-like placement ROW guard.
#
# The guard is cut only on the EXPOSED OUTER side of each configured physical
# Power Domain.  The target PD's own rows are preserved up to its boundary;
# surrounding/neighbor rows are split back by PD_BOUNDARY_ROW_GUARD_WIDTH.
# EndCaps are inserted later, after these row cuts exist.
# =============================================================================

proc tt_pd_row_guard_widths {} {
    set w $::PD_BOUNDARY_ROW_GUARD_WIDTH
    if {[llength $w] == 1} {
        return [list $w $w $w $w]
    }
    if {[llength $w] != 4} {
        error "PD_BOUNDARY_ROW_GUARD_WIDTH must be one value or {left bottom right top}; got '$w'"
    }
    # Macro-halo config convention is left bottom right top.
    lassign $w left bottom right top
    return [list $top $bottom $left $right]
}

proc tt_pd_row_guard_domains {} {
    if {[llength [info commands tt_pd_outer_boundary_blockage_rects]] == 0} {
        source -quiet [file join $::TOOL_DIR 01_floorplan geometry TT_proc_pd_geometry.tcl]
    }

    set result {}
    if {$::PD_BOUNDARY_GUARD_DOMAINS eq "auto"} {
        foreach group [get_db groups] {
            set pd_name ""
            set rects {}
            catch { set pd_name [get_db $group .power_domain.name] }
            catch { set rects [get_db $group .rects] }
            if {$pd_name eq "" || [llength $rects] == 0} { continue }
            if {[lsearch -exact $::PD_BOUNDARY_GUARD_EXCLUDE_DOMAINS $pd_name] >= 0} { continue }
            if {[lsearch -exact $result $pd_name] < 0} { lappend result $pd_name }
        }
    } else {
        foreach pd_name $::PD_BOUNDARY_GUARD_DOMAINS {
            if {[lsearch -exact $::PD_BOUNDARY_GUARD_EXCLUDE_DOMAINS $pd_name] >= 0} { continue }
            lappend result $pd_name
        }
    }
    return $result
}

proc tt_pd_row_guard_normalize_bbox {bbox label} {
    while {[llength $bbox] == 1 && [llength [lindex $bbox 0]] > 1} {
        set bbox [lindex $bbox 0]
    }
    if {[llength $bbox] != 4} {
        error "Unexpected bbox for $label: $bbox"
    }
    foreach v $bbox {
        if {![string is double -strict $v]} {
            error "Non-numeric bbox for $label: $bbox"
        }
    }
    return $bbox
}

proc tt_pd_row_guard_positive_overlap {a b {tol 1.0e-6}} {
    lassign [tt_pd_row_guard_normalize_bbox $a A] ax1 ay1 ax2 ay2
    lassign [tt_pd_row_guard_normalize_bbox $b B] bx1 by1 bx2 by2
    set dx [expr {min($ax2,$bx2) - max($ax1,$bx1)}]
    set dy [expr {min($ay2,$by2) - max($ay1,$by1)}]
    return [expr {$dx > $tol && $dy > $tol}]
}

proc tt_pd_row_guard_rows_overlapping_rects {rects} {
    set bad {}
    if {[llength [info commands get_obj_in_area]] == 0} {
        error "get_obj_in_area is unavailable; cannot verify PD row guard."
    }

    foreach rect $rects {
        set candidates [get_obj_in_area -obj_type row -areas [list $rect]]
        foreach row $candidates {
            set rb ""
            catch { set rb [get_db $row .rect] }
            if {$rb eq ""} { continue }
            if {[tt_pd_row_guard_positive_overlap $rect $rb]} {
                if {[lsearch -exact $bad $row] < 0} { lappend bad $row }
            }
        }
    }
    return $bad
}

proc tt_pd_row_guard_cut_one {rect} {
    # Reuse a backend after the first successful cut so syntax probing happens
    # at most once per run.
    if {![info exists ::TECH_PD_ROW_GUARD_BACKEND_ACTIVE]} {
        set ::TECH_PD_ROW_GUARD_BACKEND_ACTIVE ""
    }

    set requested [string tolower $::PD_BOUNDARY_ROW_GUARD_BACKEND]
    if {$requested ni {auto split_row cutrow}} {
        error "Unsupported PD_BOUNDARY_ROW_GUARD_BACKEND '$requested'. Use auto, split_row, or cutrow."
    }

    set backends {}
    if {$::TECH_PD_ROW_GUARD_BACKEND_ACTIVE ne ""} {
        set backends [list $::TECH_PD_ROW_GUARD_BACKEND_ACTIVE]
    } elseif {$requested eq "auto"} {
        set backends {split_row_area split_row_areas cutrow}
    } elseif {$requested eq "split_row"} {
        set backends {split_row_area split_row_areas}
    } else {
        set backends {cutrow}
    }

    set errors {}
    foreach backend $backends {
        switch -- $backend {
            split_row_area {
                if {[llength [info commands split_row]] == 0} {
                    lappend errors "split_row command unavailable"
                    continue
                }
                if {![catch {split_row -area $rect} err]} {
                    set ::TECH_PD_ROW_GUARD_BACKEND_ACTIVE split_row_area
                    return
                }
                lappend errors "split_row -area: $err"
            }
            split_row_areas {
                if {[llength [info commands split_row]] == 0} {
                    lappend errors "split_row command unavailable"
                    continue
                }
                if {![catch {split_row -areas [list $rect]} err]} {
                    set ::TECH_PD_ROW_GUARD_BACKEND_ACTIVE split_row_areas
                    return
                }
                lappend errors "split_row -areas: $err"
            }
            cutrow {
                set legacy_cmd [format {cutRow -area {%s}} [join $rect " "]]
                if {[llength [info commands cutRow]] > 0} {
                    if {![catch {uplevel #0 $legacy_cmd} err]} {
                        set ::TECH_PD_ROW_GUARD_BACKEND_ACTIVE cutrow
                        return
                    }
                    lappend errors "cutRow: $err"
                } elseif {[llength [info commands eval_legacy]] > 0} {
                    if {![catch {eval_legacy $legacy_cmd} err]} {
                        set ::TECH_PD_ROW_GUARD_BACKEND_ACTIVE cutrow
                        return
                    }
                    lappend errors "eval_legacy cutRow: $err"
                } else {
                    lappend errors "cutRow/eval_legacy unavailable"
                }
            }
        }
    }

    error "Unable to cut placement rows in area $rect. Tried: $errors"
}

proc TT_apply_pd_boundary_row_guard {} {
    if {!$::ENABLE_PD_BOUNDARY_ROW_GUARD} {
        puts "INFO: Power-Domain boundary row guard is disabled."
        return {}
    }

    if {[llength [info commands tt_pd_outer_boundary_blockage_rects]] == 0} {
        source -quiet [file join $::TOOL_DIR 01_floorplan geometry TT_proc_pd_geometry.tcl]
    }

    catch { unset ::TECH_PD_ROW_GUARD_BACKEND_ACTIVE }
    lassign [tt_pd_row_guard_widths] top bottom left right

    set all_rects {}
    set per_domain [dict create]

    puts ""
    puts "======================================================================"
    puts " POWER-DOMAIN ROW-GUARD CUT"
    puts "======================================================================"
    puts "Width (T/B/L/R) : $top / $bottom / $left / $right"

    foreach pd_name [tt_pd_row_guard_domains] {
        set rects [tt_pd_outer_boundary_blockage_rects \
            $pd_name $top $bottom $left $right $::PD_BOUNDARY_ROW_GUARD_STRICT]
        dict set per_domain $pd_name $rects
        puts "INFO: $pd_name exposed row-guard rectangles = [llength $rects]"
        foreach rect $rects {
            lappend all_rects $rect
            tt_pd_row_guard_cut_one $rect
        }
    }

    set bad [tt_pd_row_guard_rows_overlapping_rects $all_rects]
    puts "INFO: Row-cut backend = $::TECH_PD_ROW_GUARD_BACKEND_ACTIVE"
    puts "INFO: Guard rectangles = [llength $all_rects]"
    puts "INFO: Rows with positive-area overlap after cut = [llength $bad]"

    set ::TECH_PD_ROW_GUARD_RECTS $all_rects
    set ::TECH_PD_ROW_GUARD_BY_DOMAIN $per_domain
    set ::TECH_PD_ROW_GUARD_VIOLATING_ROWS $bad

    if {[llength $bad] > 0 && $::PD_BOUNDARY_ROW_GUARD_STRICT} {
        foreach row $bad {
            set n ""
            set b ""
            catch { set n [get_db $row .name] }
            catch { set b [get_db $row .rect] }
            puts "ERROR: Row remains inside PD guard: $n rect=$b"
        }
        error "Power-Domain row guard failed: [llength $bad] row(s) still overlap the protected moat."
    }

    if {$::PD_BOUNDARY_ROW_GUARD_SAVE_DB} {
        set db [file join $::DB_DIR $::PD_BOUNDARY_ROW_GUARD_DB_NAME]
        write_db $db
        puts "INFO: PD row-guard checkpoint DB = $db"
    }

    puts "PASS: Power-Domain row guard contains no placement-row area."
    puts "======================================================================"
    return $all_rects
}
