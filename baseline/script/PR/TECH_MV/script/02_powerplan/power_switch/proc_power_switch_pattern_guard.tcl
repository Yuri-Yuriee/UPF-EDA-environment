# Runtime adapter preserves the historical logical source path.
if {[info exists ::TECH_MV_RUNTIME_ROOT]} {
    info script [file join $::TECH_MV_RUNTIME_ROOT run/tool/02_powerplan/power_switch/TT_proc_power_switch_pattern_guard.tcl]
} else {
    info script [file normalize [file join [file dirname [info script]] .. .. .. run/tool/02_powerplan/power_switch/TT_proc_power_switch_pattern_guard.tcl]]
}
# PUBLIC_EXPORT_REVIEW_REQUIRED: residual technology candidates require manual review.
# =============================================================================
# TT_proc_power_switch_pattern_guard.tcl
#
# TECH_MV Power-Switch pattern pre-decision guard
#
# V1.1 change
# -----------
# V1.0 first ran add_power_switches -checker_board as a probe and only then
# inspected the actual SW columns.  On a narrow PD, Innovus can SEGV inside
# that checkerboard command before the fallback is reached.
#
# V1.1 therefore decides BEFORE add_power_switches is called.
#
# Policy
# ------
# * Compute each physical PD rectangle's effective horizontal span.
# * effective_width = rect_width - left_offset - right_offset
# * estimated_columns = floor(effective_width / horizontal_pitch)
# * If ANY PD rectangle can accommodate <= 2 pitch slots:
#       checkerboard = OFF for that PD.
# * Checkerboard requires >= 3 estimated pitch slots.
#
# This is deliberately conservative.  Choosing non-checkerboard for a narrow
# PD is safe for the project's requirement that every legal 2-row lane has a
# chance to receive a SW.  The helper never performs a destructive probe.
#
# Source behavior
# ---------------
# Definition-only.  Sourcing this file does NOT modify the design.
#
# Public command
# --------------
#   TT_SW_PATTERN_should_checkerboard <pd> <mode> <horizontal_pitch>
#
# Returns:
#   1 -> use -checker_board
#   0 -> do NOT use -checker_board
# =============================================================================

set ::TT_SW_PATTERN_GUARD_VERSION "V1.2_PREDECIDE_MIN3_20261008"

proc TT_SW_PATTERN__rect4 {raw} {
    if {[llength $raw] == 4} {
        set ok 1
        foreach v $raw {
            if {![string is double -strict $v]} {
                set ok 0
                break
            }
        }
        if {$ok} { return $raw }
    }

    if {[llength $raw] == 1} {
        return [TT_SW_PATTERN__rect4 [lindex $raw 0]]
    }

    return {}
}

proc TT_SW_PATTERN__pd_rects {pd} {
    set grps {}

    catch {set grps [get_db groups $pd]}

    if {[llength $grps] != 1} {
        catch {
            set grps [get_db groups -if [format {.power_domain.name == "%s"} $pd]]
        }
    }

    if {[llength $grps] != 1} {
        puts "WARNING: TT_SW_PATTERN cannot uniquely resolve physical group for $pd."
        puts "WARNING: Conservatively disabling checkerboard for $pd."
        return {}
    }

    set out {}
    set raw {}
    if {[catch {set raw [get_db [lindex $grps 0] .rects]} err]} {
        puts "WARNING: TT_SW_PATTERN cannot read rects for $pd: $err"
        puts "WARNING: Conservatively disabling checkerboard for $pd."
        return {}
    }

    foreach rr $raw {
        set r [TT_SW_PATTERN__rect4 $rr]
        if {[llength $r] == 4} {
            lappend out $r
        }
    }

    return $out
}

proc TT_SW_PATTERN__edge_offsets {mode} {
    set mode [string tolower $mode]

    switch -- $mode {
        legacy {
            return [list 0.0 0.0]
        }

        tool {
            set left 0.0
            set right 0.0

            if {[info exists ::POWER_SWITCH_LEFT_OFFSET]} {
                set left $::POWER_SWITCH_LEFT_OFFSET
            }
            if {[info exists ::POWER_SWITCH_RIGHT_OFFSET]} {
                set right $::POWER_SWITCH_RIGHT_OFFSET
            }

            return [list $left $right]
        }

        default {
            puts "WARNING: TT_SW_PATTERN unknown mode '$mode'; checkerboard disabled conservatively."
            return {}
        }
    }
}

proc TT_SW_PATTERN_should_checkerboard {pd mode horizontal_pitch} {
    if {![string is double -strict $horizontal_pitch] ||
        double($horizontal_pitch) <= 0.0} {
        puts "WARNING: TT_SW_PATTERN invalid horizontal_pitch='$horizontal_pitch'."
        puts "WARNING: Checkerboard disabled conservatively for $pd."
        return 0
    }

    set rects [TT_SW_PATTERN__pd_rects $pd]
    if {[llength $rects] == 0} {
        return 0
    }

    set offsets [TT_SW_PATTERN__edge_offsets $mode]
    if {[llength $offsets] != 2} {
        return 0
    }
    lassign $offsets left_offset right_offset

    set min_columns 999999
    set details {}

    foreach rect $rects {
        lassign $rect x1 y1 x2 y2

        set raw_width [expr {double($x2) - double($x1)}]
        set effective_width [expr {
            $raw_width - double($left_offset) - double($right_offset)
        }]

        if {$effective_width < 0.0} {
            set effective_width 0.0
        }

        # Project policy:
        #   one "usable SW column interval" exists per horizontal_pitch.
        #   Available columns = floor(effective PD width / configured horizontal switch pitch).
        set columns [expr {
            int(floor(($effective_width + 1.0e-9) / double($horizontal_pitch)))
        }]

        if {$columns < $min_columns} {
            set min_columns $columns
        }

        lappend details [dict create \
            rect $rect \
            raw_width $raw_width \
            effective_width $effective_width \
            estimated_columns $columns]
    }

    puts ""
    puts "======================================================================"
    puts " POWER-SWITCH PATTERN PRE-DECISION"
    puts "======================================================================"
    puts "Power Domain       : $pd"
    puts "Mode               : $mode"
    puts "Horizontal pitch   : $horizontal_pitch"
    puts "Left offset        : $left_offset"
    puts "Right offset       : $right_offset"

    foreach d $details {
        puts "Rect               : [dict get $d rect]"
        puts "  raw width        : [format %.3f [dict get $d raw_width]]"
        puts "  effective width  : [format %.3f [dict get $d effective_width]]"
        puts "  estimated columns: [dict get $d estimated_columns]"
    }

    if {$min_columns <= 2} {
        puts "Checkerboard min   : 3 estimated pitch slots"
        puts "Decision           : NON-CHECKERBOARD"
        puts "Reason             : narrow PD; <=2 pitch slots are not safe for checkerboard"
        puts "======================================================================"
        return 0
    }

    puts "Checkerboard min   : 3 estimated pitch slots"
    puts "Decision           : CHECKERBOARD"
    puts "Reason             : every PD rectangle supports >= 3 estimated pitch slots"
    puts "======================================================================"
    return 1
}

puts "INFO: Loaded TT_proc_power_switch_pattern_guard.tcl - $::TT_SW_PATTERN_GUARD_VERSION"
