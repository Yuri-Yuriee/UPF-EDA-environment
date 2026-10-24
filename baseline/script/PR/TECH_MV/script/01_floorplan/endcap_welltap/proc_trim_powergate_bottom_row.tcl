# Runtime adapter preserves the historical logical source path.
if {[info exists ::TECH_MV_RUNTIME_ROOT]} {
    info script [file join $::TECH_MV_RUNTIME_ROOT run/tool/01_floorplan/endcap_welltap/TT_proc_trim_powergate_bottom_row.tcl]
} else {
    info script [file normalize [file join [file dirname [info script]] .. .. .. run/tool/01_floorplan/endcap_welltap/TT_proc_trim_powergate_bottom_row.tcl]]
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
# =============================================================================
# TT_proc_trim_powergate_bottom_row.tcl
# =============================================================================
# TECH_MV / Innovus 21.19 Stylus / Common UI
#
# V2.0 - rail-aware pre-SW boundary-row trim
#
# Why this replaces count-only parity
# -----------------------------------
# The Power Switch is a 2-row CORE cell.  An even number of rows is not enough:
# the lower row of each legal 2-row SW lane must have the correct rail/orient
# phase.  With a wrong phase, an even row count can still leave one unusable
# row at BOTH the bottom and top of the SW-active region.
#
# Project geometry
# ----------------
# POWER_SWITCH_BOTTOM_OFFSET / TOP_OFFSET reserve one single-height row at the
# bottom and one at the top for the outer EndCap boundary.  SW lanes live INSIDE
# those two boundary rows.  This tool therefore validates the *interior* rows,
# while any repair is performed only by trimming the current OUTERMOST bottom
# and/or top row segment.  That preserves a contiguous row field: after a trim,
# the next row naturally becomes the new EndCap boundary row.
#
# Project-validated SW rail phase
# -------------------------------
# configured library cell (used by PD_WDT and PD_CPU) was runtime-validated in the
# disposable DB to start a legal 2-row switch on an MX lower row followed by an
# R0 upper row.  The default required pair is therefore:
#
#     lower = MX
#     upper = R0
#
# The values remain configurable through:
#   ::TT_SWROW_VALID_LOWER_ORIENT
#   ::TT_SWROW_VALID_UPPER_ORIENT
#
# Repair decision (minimum destructive change)
# --------------------------------------------
# For each SW-bearing PD rectangle, test these candidates in order:
#   0) KEEP
#   1) TRIM_BOTTOM
#   2) TRIM_TOP
#   3) TRIM_BOTH
#
# A candidate passes only when, AFTER reserving one current outer row on each
# side for EndCaps, every remaining interior row can be paired as contiguous
# {MX,R0} 2-row SW lanes.  This naturally handles all four cases:
#
#   correct phase + even interior rows -> KEEP
#   wrong   phase + odd  interior rows -> TRIM_BOTTOM
#   correct phase + odd  interior rows -> TRIM_TOP
#   wrong   phase + even interior rows -> TRIM_BOTH
#
# No row orientation is changed.  No rail type is rewritten.  Only the smallest
# required outer boundary row segment(s) are cut, using the existing proven
# TT_proc_pd_row_guard.tcl split_row/cutRow backend.
#
# Source behavior
# ---------------
# Definition-only. Sourcing this file does NOT modify the design.
#
# Public entries
# --------------
#   TT_SWROW_trim_rail_aware preview|apply
#   TT_SWROW_trim_bottom     preview|apply   ;# compatibility wrapper
# =============================================================================

set ::TT_SWROW_TRIM_VERSION "V2.1_RAIL_AWARE_OFFSET_PAIR_HOTFIX_20261009"
if {![info exists ::TT_SWROW_TRIM_SITE]} {
    set ::TT_SWROW_TRIM_SITE core
}
if {![info exists ::TT_SWROW_ENDCAP_RESERVE_ROWS]} {
    set ::TT_SWROW_ENDCAP_RESERVE_ROWS 1
}
if {![info exists ::TT_SWROW_VALID_LOWER_ORIENT]} {
    set ::TT_SWROW_VALID_LOWER_ORIENT mx
}
if {![info exists ::TT_SWROW_VALID_UPPER_ORIENT]} {
    set ::TT_SWROW_VALID_UPPER_ORIENT r0
}
if {![info exists ::TT_SWROW_EXPECTED_SWITCH_MASTER]} {
    set ::TT_SWROW_EXPECTED_SWITCH_MASTER [::tech_mv_library_value LIB_CELL_003]
}
if {![info exists ::TT_SWROW_OFFSET_TOL]} {
    set ::TT_SWROW_OFFSET_TOL [::tech_mv_private_value {run/tool/01_floorplan/TT_proc_trim_powergate_bottom_row.tcl::::TT_SWROW_OFFSET_TOL::L85}]
}
if {![info exists ::TT_SWROW_GEOM_TOL]} {
    set ::TT_SWROW_GEOM_TOL [::tech_mv_private_value {run/tool/01_floorplan/TT_proc_trim_powergate_bottom_row.tcl::::TT_SWROW_GEOM_TOL::L88}]
}
set ::TT_SWROW_TRIM_LAST_RESULT {}

proc TT_SWROW__rect4 {v} {
    while {[llength $v] == 1 && [llength [lindex $v 0]] > 1} {
        set v [lindex $v 0]
    }
    if {[llength $v] != 4} { return "" }
    foreach x $v {
        if {![string is double -strict $x]} { return "" }
    }
    return $v
}

proc TT_SWROW__row_rect {row} {
    foreach attr {.rect .bbox .box} {
        set raw ""
        if {![catch {set raw [get_db $row $attr]}]} {
            set r [TT_SWROW__rect4 $raw]
            if {[llength $r] == 4} { return $r }
        }
    }
    return ""
}

proc TT_SWROW__row_orient {row} {
    set o ""
    catch {set o [get_db $row .orient]}
    return [string tolower $o]
}

proc TT_SWROW__intersection {a b} {
    if {[llength $a] != 4 || [llength $b] != 4} { return "" }
    lassign $a ax1 ay1 ax2 ay2
    lassign $b bx1 by1 bx2 by2
    set x1 [expr {max(double($ax1),double($bx1))}]
    set y1 [expr {max(double($ay1),double($by1))}]
    set x2 [expr {min(double($ax2),double($bx2))}]
    set y2 [expr {min(double($ay2),double($by2))}]
    if {$x2 <= $x1+$::TT_SWROW_GEOM_TOL || $y2 <= $y1+$::TT_SWROW_GEOM_TOL} { return "" }
    return [list $x1 $y1 $x2 $y2]
}

proc TT_SWROW__row_key {r} {
    lassign $r x1 y1 x2 y2
    return [format "%.6f:%.6f" $y1 $y2]
}

proc TT_SWROW__key_y1 {key} {
    return [expr {double([lindex [split $key :] 0])}]
}

proc TT_SWROW__key_y2 {key} {
    return [expr {double([lindex [split $key :] 1])}]
}

proc TT_SWROW__key_height {key} {
    return [expr {[TT_SWROW__key_y2 $key] - [TT_SWROW__key_y1 $key]}]
}

proc TT_SWROW__key_cmp {a b} {
    set ay [TT_SWROW__key_y1 $a]
    set by [TT_SWROW__key_y1 $b]
    if {$ay < $by} { return -1 }
    if {$ay > $by} { return 1 }
    return [string compare $a $b]
}

proc TT_SWROW__domains {} {
    set out {}
    if {[info exists ::POWER_SWITCH_INSTANCE_PREFIXES]} {
        foreach prefix $::POWER_SWITCH_INSTANCE_PREFIXES {
            if {[regexp {^(PD_.+)_SW$} $prefix -> pd]} {
                if {[lsearch -exact $out $pd] < 0} { lappend out $pd }
            }
        }
    }
    if {[llength $out] == 0} {
        foreach pd {PD_WDT PD_CPU} {
            if {[info exists ::PD_CFG] && [dict exists $::PD_CFG $pd]} {
                lappend out $pd
            }
        }
    }
    if {[llength $out] == 0} {
        error "SWROW TRIM: no switch-bearing Power Domain could be resolved."
    }
    return [lsort -dictionary -unique $out]
}

proc TT_SWROW__pd_rects {pd} {
    set grps {}
    catch {set grps [get_db groups $pd]}
    if {[llength $grps] != 1} {
        catch {set grps [get_db groups -if [format {.power_domain.name == "%s"} $pd]]}
    }
    if {[llength $grps] != 1} {
        error "SWROW TRIM: Power Domain '$pd' maps to [llength $grps] physical groups."
    }
    set out {}
    set raw {}
    if {[catch {set raw [get_db [lindex $grps 0] .rects]} err]} {
        error "SWROW TRIM: cannot read rects for '$pd': $err"
    }
    foreach rr $raw {
        set r [TT_SWROW__rect4 $rr]
        if {[llength $r] == 4} { lappend out $r }
    }
    if {[llength $out] == 0} {
        error "SWROW TRIM: '$pd' has no readable physical rectangle."
    }
    return $out
}

# Return dict:
#   keys     = ordered unique physical-row Y keys intersecting one PD rectangle
#   clips    = dict row_key -> one or more clipped row rectangles
#   orients  = dict row_key -> normalized row orientation
# Conflicting orientations at the same Y are treated as unsafe and fail closed.
proc TT_SWROW__rows_in_rect {pd rect} {
    set clips [dict create]
    set orients [dict create]
    foreach row [get_db rows] {
        set site ""
        catch {set site [get_db $row .site.name]}
        if {$site ne $::TT_SWROW_TRIM_SITE} { continue }

        set rr [TT_SWROW__row_rect $row]
        if {[llength $rr] != 4} { continue }
        set clip [TT_SWROW__intersection $rr $rect]
        if {$clip eq ""} { continue }

        set key [TT_SWROW__row_key $rr]
        set orient [TT_SWROW__row_orient $row]
        if {$orient eq ""} {
            error "SWROW TRIM: pd=$pd row=$key has no readable .orient."
        }
        if {$orient ni {r0 mx}} {
            error "SWROW TRIM: pd=$pd row=$key has unsupported horizontal row orient '$orient'; expected r0/mx."
        }
        if {[dict exists $orients $key] && [dict get $orients $key] ne $orient} {
            error "SWROW TRIM: pd=$pd row=$key has conflicting orientations '[dict get $orients $key]' and '$orient'."
        }

        dict set orients $key $orient
        dict lappend clips $key $clip
    }

    set keys [lsort -command TT_SWROW__key_cmp [dict keys $clips]]
    return [dict create pd $pd rect $rect keys $keys clips $clips orients $orients]
}

proc TT_SWROW__report_path {} {
    if {[info exists ::REPORT_DIR] && $::REPORT_DIR ne ""} {
        set dir [file join $::REPORT_DIR 01_floorplan]
    } else {
        set dir reports/01_floorplan
    }
    file mkdir $dir
    return [file join $dir TT_pre_sw_rail_aware_row_trim.rpt]
}

proc TT_SWROW__ensure_cut_backend {} {
    if {[llength [info commands tt_pd_row_guard_cut_one]] > 0} { return }
    set f [file join $::TECH_MV_RUNTIME_ROOT .. script PR TECH_MV script 01_floorplan checks proc_pd_row_guard.tcl]
    if {![file isfile $f]} {
        error "SWROW TRIM: required row-cut backend helper is missing: $f"
    }
    uplevel #0 [list source -quiet $f]
    if {[llength [info commands tt_pd_row_guard_cut_one]] == 0} {
        error "SWROW TRIM: tt_pd_row_guard_cut_one was not defined by $f"
    }
}

proc TT_SWROW__validate_switch_master {} {
    # Fail closed only when the base-cell DB is readable.  This protects the
    # project-specific MX/R0 phase assumption from silently following a future
    # switch-master change.
    if {[llength [info commands get_db]] == 0} { return }
    set masters {}
    if {[catch {set masters [get_db base_cells $::TT_SWROW_EXPECTED_SWITCH_MASTER]}]} {
        return
    }
    if {[llength $masters] == 0} {
        error "SWROW TRIM: expected project Power-Switch master '$::TT_SWROW_EXPECTED_SWITCH_MASTER' is not loaded; refusing to apply the project-specific MX/R0 rail-phase repair."
    }
}

proc TT_SWROW__validate_one_row_offsets {keys pd rect_idx} {
    if {[llength $keys] < 1} { return }
    set h [TT_SWROW__key_height [lindex $keys 0]]
    if {$h <= 0.0} {
        error "SWROW TRIM: pd=$pd rect#$rect_idx has invalid row height $h."
    }

    foreach {var label} {
        POWER_SWITCH_BOTTOM_OFFSET BOTTOM
        POWER_SWITCH_TOP_OFFSET TOP
    } {
        if {![info exists ::$var]} {
            error "SWROW TRIM: $var is undefined; cannot prove the one-row EndCap reserve."
        }
        set v [set ::$var]
        if {![string is double -strict $v]} {
            error "SWROW TRIM: $var='$v' is non-numeric."
        }
        if {abs(double($v)-double($h)) > $::TT_SWROW_OFFSET_TOL} {
            error "SWROW TRIM: pd=$pd rect#$rect_idx $label offset=$v does not match one core-row height=$h (tol=$::TT_SWROW_OFFSET_TOL). Rail-aware policy assumes exactly one outer EndCap row on each side."
        }
    }
}

# Pure validator used by both runtime and package unit tests.
# Returns dict {ok bool reason string active_keys list lane_count int}.
proc TT_SWROW__validate_candidate {keys orients trim_bottom trim_top} {
    set reserve $::TT_SWROW_ENDCAP_RESERVE_ROWS
    set n [llength $keys]
    set first $trim_bottom
    set last [expr {$n - 1 - $trim_top}]
    if {$first > $last} {
        return [dict create ok 0 reason EMPTY_AFTER_TRIM active_keys {} lane_count 0]
    }

    set remain [lrange $keys $first $last]
    set rn [llength $remain]
    set min_rows [expr {2*$reserve + 2}]
    if {$rn < $min_rows} {
        return [dict create ok 0 reason TOO_FEW_ROWS_AFTER_TRIM active_keys {} lane_count 0]
    }

    set a0 $reserve
    set a1 [expr {$rn - $reserve - 1}]
    set active [lrange $remain $a0 $a1]
    set an [llength $active]
    if {$an < 2} {
        return [dict create ok 0 reason TOO_FEW_ACTIVE_ROWS active_keys $active lane_count 0]
    }
    if {[expr {$an % 2}] != 0} {
        return [dict create ok 0 reason ODD_ACTIVE_ROW_COUNT active_keys $active lane_count 0]
    }

    # The entire active row field must be contiguous, not only each 2-row pair.
    # An interior gap is not repairable by trimming only the outer boundary and
    # must fail closed instead of being hidden by a lucky pair boundary.
    for {set j 0} {$j < $an-1} {incr j} {
        set a [lindex $active $j]
        set b [lindex $active [expr {$j+1}]]
        set gap [expr {abs([TT_SWROW__key_y2 $a]-[TT_SWROW__key_y1 $b])}]
        if {$gap > $::TT_SWROW_GEOM_TOL} {
            return [dict create ok 0 reason "NONCONTIGUOUS_ACTIVE_ROWS:$gap" active_keys $active lane_count 0]
        }
    }

    set lower_req [string tolower $::TT_SWROW_VALID_LOWER_ORIENT]
    set upper_req [string tolower $::TT_SWROW_VALID_UPPER_ORIENT]
    set lanes 0
    for {set i 0} {$i < $an} {incr i 2} {
        set lo [lindex $active $i]
        set hi [lindex $active [expr {$i+1}]]
        if {![dict exists $orients $lo] || ![dict exists $orients $hi]} {
            return [dict create ok 0 reason MISSING_ORIENT active_keys $active lane_count $lanes]
        }
        set lo_o [string tolower [dict get $orients $lo]]
        set hi_o [string tolower [dict get $orients $hi]]
        if {$lo_o ne $lower_req || $hi_o ne $upper_req} {
            return [dict create ok 0 reason "BAD_PHASE:${lo_o}/${hi_o}" active_keys $active lane_count $lanes]
        }
        incr lanes
    }

    return [dict create ok 1 reason PASS active_keys $active lane_count $lanes]
}

# Minimal outer-row repair planner.  Bottom-only is tested before top-only to
# preserve the legacy preference when a one-row repair is otherwise ambiguous.
proc TT_SWROW__plan_edge_trim {keys orients} {
    foreach candidate {
        {0 0 KEEP}
        {1 0 TRIM_BOTTOM}
        {0 1 TRIM_TOP}
        {1 1 TRIM_BOTH}
    } {
        lassign $candidate b t action
        set v [TT_SWROW__validate_candidate $keys $orients $b $t]
        if {[dict get $v ok]} {
            dict set v action $action
            dict set v trim_bottom $b
            dict set v trim_top $t
            return $v
        }
    }

    set raw {}
    foreach key $keys {
        set o "?"
        if {[dict exists $orients $key]} { set o [dict get $orients $key] }
        lappend raw "$key=$o"
    }
    error "SWROW TRIM: no safe {KEEP,BOTTOM,TOP,BOTH} outer-row repair can produce contiguous [string toupper $::TT_SWROW_VALID_LOWER_ORIENT]/[string toupper $::TT_SWROW_VALID_UPPER_ORIENT] 2-row lanes. rows={$raw}"
}

proc TT_SWROW__plan_record {pd rect_idx scan} {
    set keys [dict get $scan keys]
    set orients [dict get $scan orients]
    set n [llength $keys]
    if {$n < [expr {2*$::TT_SWROW_ENDCAP_RESERVE_ROWS + 2}]} {
        error "SWROW TRIM: pd=$pd rect#$rect_idx has only $n core row(s); refusing destructive repair."
    }

    TT_SWROW__validate_one_row_offsets $keys $pd $rect_idx
    set plan [TT_SWROW__plan_edge_trim $keys $orients]
    dict set plan pd $pd
    dict set plan rect_index $rect_idx
    dict set plan rows_before $n
    dict set plan keys_before $keys

    set trim_keys {}
    if {[dict get $plan trim_bottom]} { lappend trim_keys [lindex $keys 0] }
    if {[dict get $plan trim_top]}    { lappend trim_keys [lindex $keys end] }
    dict set plan trim_keys $trim_keys
    return $plan
}

proc TT_SWROW_trim_rail_aware {{mode preview}} {
    set mode [string tolower $mode]
    if {$mode ni {preview apply}} {
        error "Usage: TT_SWROW_trim_rail_aware preview|apply"
    }

    if {$::TT_SWROW_ENDCAP_RESERVE_ROWS != 1} {
        error "SWROW TRIM: this project version requires TT_SWROW_ENDCAP_RESERVE_ROWS=1; got $::TT_SWROW_ENDCAP_RESERVE_ROWS"
    }
    TT_SWROW__validate_switch_master

    set report [TT_SWROW__report_path]
    set fp [open $report w]
    set trim_plan {}
    set planned_row_sets 0

    puts $fp "======================================================================"
    puts $fp " PRE-SW RAIL-AWARE BOUNDARY ROW TRIM"
    puts $fp "======================================================================"
    puts $fp "Version             : $::TT_SWROW_TRIM_VERSION"
    puts $fp "Mode                : $mode"
    puts $fp "Site                : $::TT_SWROW_TRIM_SITE"
    puts $fp "EndCap reserve rows : $::TT_SWROW_ENDCAP_RESERVE_ROWS bottom + $::TT_SWROW_ENDCAP_RESERVE_ROWS top"
    puts $fp "Valid SW row pair   : [string toupper $::TT_SWROW_VALID_LOWER_ORIENT] -> [string toupper $::TT_SWROW_VALID_UPPER_ORIENT]"
    puts $fp "Expected SW master  : $::TT_SWROW_EXPECTED_SWITCH_MASTER"
    puts $fp "Repair candidates   : KEEP, BOTTOM, TOP, BOTH (minimum trim)"
    puts $fp ""

    puts ""
    puts "======================================================================"
    puts " PRE-SW RAIL-AWARE BOUNDARY ROW TRIM"
    puts "======================================================================"
    puts "Mode                : $mode"
    puts "EndCap reserve      : one outer row at BOTTOM + TOP"
    puts "Valid SW lane phase : [string toupper $::TT_SWROW_VALID_LOWER_ORIENT] lower -> [string toupper $::TT_SWROW_VALID_UPPER_ORIENT] upper"
    puts "Repair              : cut only minimum OUTER boundary row(s)"
    puts "Report              : $report"
    puts "======================================================================"

    foreach pd [TT_SWROW__domains] {
        set rect_idx 0
        foreach rect [TT_SWROW__pd_rects $pd] {
            incr rect_idx
            set scan [TT_SWROW__rows_in_rect $pd $rect]
            set plan [TT_SWROW__plan_record $pd $rect_idx $scan]
            set action [dict get $plan action]
            set keys [dict get $scan keys]
            set orients [dict get $scan orients]
            set active [dict get $plan active_keys]
            set lanes [dict get $plan lane_count]
            set trims [dict get $plan trim_keys]

            puts "INFO: SWROW pd=$pd rect#$rect_idx rows=[llength $keys] action=$action lanes=$lanes rect=$rect"
            puts $fp "PD=$pd RECT_INDEX=$rect_idx RECT=$rect ROWS_BEFORE=[llength $keys] ACTION=$action LANES=$lanes"
            puts $fp "  FULL_ROWS:"
            foreach key $keys {
                puts $fp "    $key orient=[dict get $orients $key]"
            }
            puts $fp "  ACTIVE_AFTER_PLAN=$active"
            puts $fp "  TRIM_KEYS=$trims"

            if {$action ne "KEEP"} {
                set clips [dict get $scan clips]
                foreach key $trims {
                    if {![dict exists $clips $key]} {
                        close $fp
                        error "SWROW TRIM: pd=$pd rect#$rect_idx planned trim key '$key' has no clip geometry."
                    }
                    dict set plan trim_clips $key [dict get $clips $key]
                }
                incr planned_row_sets [llength $trims]
                lappend trim_plan [dict create pd $pd rect_index $rect_idx rect $rect scan $scan plan $plan]
            }
        }
    }

    if {$mode eq "preview"} {
        puts $fp ""
        puts $fp "PLANNED_BOUNDARY_ROW_SETS=$planned_row_sets"
        puts $fp "STATUS=PREVIEW"
        close $fp
        set ::TT_SWROW_TRIM_LAST_RESULT [dict create mode preview planned_row_sets $planned_row_sets report $report]
        puts "INFO: SWROW rail-aware preview planned $planned_row_sets outer boundary row-set trim(s)."
        return $planned_row_sets
    }

    if {$planned_row_sets > 0} { TT_SWROW__ensure_cut_backend }
    set trimmed_row_sets 0

    foreach rec $trim_plan {
        set pd [dict get $rec pd]
        set rect_idx [dict get $rec rect_index]
        set rect [dict get $rec rect]
        set plan [dict get $rec plan]
        set action [dict get $plan action]
        set trim_keys [dict get $plan trim_keys]

        puts "INFO: SWROW APPLY pd=$pd rect#$rect_idx action=$action trimKeys=$trim_keys"
        foreach key $trim_keys {
            set clips [dict get $plan trim_clips $key]
            puts "INFO: SWROW CUT pd=$pd rect#$rect_idx row=$key clips=[llength $clips]"
            foreach clip $clips {
                tt_pd_row_guard_cut_one $clip
            }
            incr trimmed_row_sets
        }

        # Re-read LIVE row DB and require that no further repair is needed.
        set post [TT_SWROW__rows_in_rect $pd $rect]
        set post_plan [TT_SWROW__plan_record $pd $rect_idx $post]
        set post_action [dict get $post_plan action]
        if {$post_action ne "KEEP"} {
            close $fp
            error "SWROW TRIM FAILED: pd=$pd rect#$rect_idx requires additional action '$post_action' after applying '$action'."
        }

        set before [dict get $plan rows_before]
        set after [llength [dict get $post keys]]
        set expected [expr {$before - [llength $trim_keys]}]
        if {$after != $expected} {
            close $fp
            error "SWROW TRIM FAILED: pd=$pd rect#$rect_idx row count $before -> $after, expected $expected after $action."
        }

        puts "PASS: SWROW pd=$pd rect#$rect_idx action=$action rows $before -> $after; post topology is rail-compatible."
        puts $fp "  RESULT=PASS ROWS_AFTER=$after POST_ACTION=$post_action POST_LANES=[dict get $post_plan lane_count]"
    }

    puts $fp ""
    puts $fp "TRIMMED_BOUNDARY_ROW_SETS=$trimmed_row_sets"
    puts $fp "STATUS=PASS"
    close $fp

    set ::TT_SWROW_TRIM_LAST_RESULT [dict create mode apply trimmed_row_sets $trimmed_row_sets report $report]

    puts ""
    puts "======================================================================"
    puts " PRE-SW RAIL-AWARE ROW TRIM SUMMARY"
    puts "======================================================================"
    puts "Boundary row sets cut : $trimmed_row_sets"
    puts "EndCap reserve         : one current outer row on BOTTOM + TOP"
    puts "Required SW row phase  : [string toupper $::TT_SWROW_VALID_LOWER_ORIENT] -> [string toupper $::TT_SWROW_VALID_UPPER_ORIENT]"
    puts "Report                 : $report"
    puts "STATUS                 : PASS"
    puts "======================================================================"

    return $trimmed_row_sets
}

# Compatibility entry retained so the existing add_endcaps.tcl hook does
# not need to be rewritten.  V2.0 behavior is rail-aware, not count-only.
proc TT_SWROW_trim_bottom {{mode preview}} {
    return [TT_SWROW_trim_rail_aware $mode]
}

puts "INFO: Loaded TT_proc_trim_powergate_bottom_row.tcl - $::TT_SWROW_TRIM_VERSION"
