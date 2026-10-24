# Runtime adapter preserves the historical logical source path.
if {[info exists ::TECH_MV_RUNTIME_ROOT]} {
    info script [file join $::TECH_MV_RUNTIME_ROOT run/tool/02_powerplan/power_switch/TT_proc_sw_ls_iso_guard.tcl]
}
# PUBLIC_EXPORT_REVIEW_REQUIRED: residual technology candidates require manual review.
# Load private values before evaluating original parameter defaults.
if {![llength [info commands ::tech_mv_private_value]]} { source [file join $::TECH_MV_RUNTIME_ROOT .. script PR TECH_MV script 00_common private_parameter_config.tcl] }
# =============================================================================
# TT_proc_sw_ls_iso_guard.tcl
# TECH_MV / Innovus 21.19 Common UI
# PR6 V3
#
# Read-only geometry validator.  It does NOT create/delete/move Power Switches,
# LS/ISO cells, or WellTaps.
#
# The 2-row SDP flow calls TT_SWLS_validate_targets with the exact canonical
# 2-row LS/ISO list.  Required horizontal clearance defaults to one
# configured library cell physical width and is overridden from live tap geometry by
# the caller.
# =============================================================================

if {![info exists ::TT_SWLS_MIN_GAP_UM]} { set ::TT_SWLS_MIN_GAP_UM [::tech_mv_private_value {run/tool/02_powerplan/TT_proc_sw_ls_iso_guard.tcl::::TT_SWLS_MIN_GAP_UM::L15}] }
if {![info exists ::TT_SWLS_STRICT]} { set ::TT_SWLS_STRICT true }

proc TT_SWLS_bool {v} {
    set x [string tolower [string trim $v]]
    return [expr {$x eq "true" || $x eq "1" || $x eq "yes" || $x eq "on"}]
}

proc TT_SWLS_bbox4 {raw} {
    set v $raw
    if {[llength $v] == 1} { set v [lindex $v 0] }
    if {[llength $v] == 2 && [llength [lindex $v 0]] == 2 && [llength [lindex $v 1]] == 2} {
        set v [concat [lindex $v 0] [lindex $v 1]]
    }
    if {[llength $v] != 4} { return {} }
    return $v
}

proc TT_SWLS_switches {} {
    set out {}

    # Preferred Common-UI property path.
    if {![catch {set q [get_db insts -if {.is_power_switch == true}]}]} {
        foreach o $q {
            if {[lsearch -exact $out $o] < 0} { lappend out $o }
        }
    }

    # Robust TECH fallback: known header-switch family uses HDR* masters.
    # Do not depend on instance names.
    if {[llength $out] == 0} {
        foreach o [get_db insts] {
            set master ""
            catch {set master [get_db $o .base_cell.name]}
            if {[string match $::HEADER_POWER_SWITCH_CELL_PATTERN $master]} {
                if {[lsearch -exact $out $o] < 0} { lappend out $o }
            }
        }
    }
    return $out
}

proc TT_SWLS_validate_targets {target_names {required_gap ""}} {
    if {$required_gap eq ""} { set required_gap $::TT_SWLS_MIN_GAP_UM }
    set switches [TT_SWLS_switches]
    set violations {}
    set checked_targets 0

    puts ""
    puts "======================================================================"
    puts " PR6 2-ROW LS/ISO <-> POWER SWITCH GAP VALIDATION"
    puts "======================================================================"
    puts "Targets          : [llength $target_names]"
    puts "Power Switches   : [llength $switches]"
    puts "Required side gap: ${required_gap} um"

    foreach name $target_names {
        set objs [get_db insts $name]
        if {[llength $objs] != 1} {
            lappend violations [list $name "<unresolved>" RESOLVE -1 {} {}]
            continue
        }
        set c [lindex $objs 0]
        set cb [TT_SWLS_bbox4 [get_db $c .bbox]]
        if {[llength $cb] != 4} {
            lappend violations [list $name "<invalid_bbox>" BBOX -1 $cb {}]
            continue
        }
        incr checked_targets
        lassign $cb cx1 cy1 cx2 cy2

        foreach sw $switches {
            set sb [TT_SWLS_bbox4 [get_db $sw .bbox]]
            if {[llength $sb] != 4} { continue }
            lassign $sb sx1 sy1 sx2 sy2

            # Only switches that vertically overlap the full 2-row target can
            # threaten its left/right tap-width corridor.
            if {$sy2 <= $cy1 || $sy1 >= $cy2} { continue }

            set side ""
            set actual 1.0e30
            if {$sx2 <= $cx1} {
                set side LEFT
                set actual [expr {$cx1 - $sx2}]
            } elseif {$sx1 >= $cx2} {
                set side RIGHT
                set actual [expr {$sx1 - $cx2}]
            } else {
                set side OVERLAP
                set actual -1.0
            }

            if {$actual < ($required_gap - 1.0e-6)} {
                set sw_name ""
                catch {set sw_name [get_db $sw .name]}
                lappend violations [list $name $sw_name $side $actual $cb $sb]
            }
        }
    }

    puts "Checked targets   : $checked_targets"
    puts "Violations        : [llength $violations]"
    foreach v $violations {
        lassign $v cn sn side actual cb sb
        puts "VIOLATION: LS/ISO=$cn  SW=$sn  side=$side  gap=$actual um"
        if {[llength $cb] != 0} { puts "           LS/ISO bbox=$cb" }
        if {[llength $sb] != 0} { puts "           SW bbox    =$sb" }
    }
    puts "======================================================================"

    if {[llength $violations] > 0 && [TT_SWLS_bool $::TT_SWLS_STRICT]} {
        error "PR6 Power-Switch gap validation failed: [llength $violations] violation(s)."
    }
    if {[llength $violations] == 0} {
        puts "PASS: Every checked 2-row target keeps at least ${required_gap}um horizontal clearance from Power Switches."
    }
    return [llength $violations]
}

puts "INFO: Loaded TT_proc_sw_ls_iso_guard.tcl (PR6 V3)."
puts "INFO: Command: TT_SWLS_validate_targets <exact_2row_names> ?gap_um?"
