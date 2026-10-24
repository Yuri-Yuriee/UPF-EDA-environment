# Runtime adapter preserves the historical logical source path.
if {[info exists ::TECH_MV_RUNTIME_ROOT]} {
    info script [file join $::TECH_MV_RUNTIME_ROOT run/tool/05_route/reports/TT_tool_report_metal_density.tcl]
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
# Required private rule data is installed locally; no published defaults.
if {![llength [info commands ::tech_mv_private_value]]} {
    source -quiet [file join $::TECH_MV_RUNTIME_ROOT .. script PR TECH_MV script 00_common private_parameter_config.tcl]
}
# ==============================================================================
# TT_tool_report_metal_density.tcl
#
# Stylus Common UI
#
# Purpose:
#   Run Innovus built-in metal-density engine and generate:
#     1) detailed raw density report
#     2) per-layer density summary (Min / Max / Avg over reported windows)
#
# Target debug:
#   Whole-chip / layer metal-density DRC, e.g. MAADNXX
#
# IMPORTANT:
#   This uses Innovus check_metal_density.
#   The summary Avg is the arithmetic average of Innovus-reported density
#   windows. It is NOT claimed to be numerically identical to a Calibre
#   whole-chip density rule such as:
#
#       AREA(MACx) / AREA(CHIP)
#
#   Calibre remains the signoff authority for MAADNXX.
#
# Usage:
#   source run/tool/05_route/reports/TT_tool_report_metal_density.tcl
#
#   # All routing layers, entire design
#   TT_tool_report_metal_density
#
#   # Only M7
#   TT_tool_report_metal_density -layers {M7}
#
#   # Selected layers
#   TT_tool_report_metal_density -layers {M6 M7 M8}
#
#   # Explicit report path
#   TT_tool_report_metal_density \
#       -layers {M7} \
#       -report reports/TT_M7_density.rpt
#
# Outputs:
#   <report>
#   <report>.summary
# ==============================================================================

namespace eval ::TT_METAL_DENSITY {
    variable version "2.0"

    # ======================================================================
    # USER CONFIG - PER-LAYER DENSITY LIMIT TABLE (%)
    # ======================================================================
    #
    # Format:
    #   Layer   MIN_LIMIT   MAX_LIMIT
    #
    # Check rule for EVERY listed layer:
    #
    #   reported MIN < MIN_LIMIT  -> ERROR
    #   reported MAX > MAX_LIMIT  -> ERROR
    #   otherwise                 -> PASS
    #
    # Layer limits are installed locally in private config.
    # Do not embed or duplicate rule values in tool source or comments.
    variable DENSITY_LIMIT_TABLE [::tech_mv_private_value {metal_density::DENSITY_LIMIT_TABLE}]
}

proc ::TT_METAL_DENSITY::limit_table {} {
    if {[info exists ::METAL_DENSITY_LIMIT_TABLE]} {
        return $::METAL_DENSITY_LIMIT_TABLE
    }
    variable DENSITY_LIMIT_TABLE
    return $DENSITY_LIMIT_TABLE
}

proc ::TT_METAL_DENSITY::usage {} {
    puts ""
    puts "TT_tool_report_metal_density"
    puts ""
    puts "Options:"
    puts "  -layers <list>      Routing layers to check."
    puts "                      Default: all routing layers."
    puts "                      Example: -layers [::tech_mv_library_value LIB_TECH_007]"
    puts ""
    puts "  -area <rect>        Optional check area {x1 y1 x2 y2}."
    puts "                      Default: entire design (option omitted)."
    puts ""
    puts "  -report <file>      Detailed Innovus report."
    puts "                      Default: TT_metal_density.rpt"
    puts ""
    puts "  -detailed <0|1>     Run check_metal_density -detailed."
    puts "                      Default: 1"
    puts ""
    puts "  -summary <0|1>      Parse report and create per-layer summary."
    puts "                      Default: 1"
    puts ""
    puts "  -check_min <0|1>    Enforce configured minimum density."
    puts "                      Default: 1"
    puts "  -check_max <0|1>    Enforce configured maximum density."
    puts "                      Default: 1"
    puts "  -fatal <0|1>        Raise Tcl error when configured limits fail."
    puts "                      Default: 1"
    puts ""
    puts "Examples:"
    puts "  TT_tool_report_metal_density"
    puts "  TT_tool_report_metal_density -layers [::tech_mv_library_value LIB_TECH_008]"
    puts "  TT_tool_report_metal_density -layers [::tech_mv_library_value LIB_TECH_007]"
    puts ""
}

proc ::TT_METAL_DENSITY::is_number {s} {
    return [regexp {^[+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)([eE][+-]?[0-9]+)?%?$} $s]
}

proc ::TT_METAL_DENSITY::to_number {s} {
    regsub {%$} $s "" s
    return [expr {double($s)}]
}

# ------------------------------------------------------------------------------
# Parse common density-report rows.
#
# Typical Innovus / legacy report rows are of the form:
#
#   <layer> <density_percent> (llx lly) (urx ury)
#
# The parser intentionally stays conservative:
#   - first token must look like a layer name
#   - second token must be numeric
#
# If the installed Innovus version uses a different detailed-report format,
# the raw report is still valid and the script prints a parser warning.
# ------------------------------------------------------------------------------
proc ::TT_METAL_DENSITY::make_summary {report_file summary_file requested_layers} {
    if {![file exists $report_file]} {
        puts "WARNING: Raw report does not exist: $report_file"
        return 0
    }

    set fp [open $report_file r]

    array set cnt {}
    array set sum {}
    array set minv {}
    array set maxv {}

    while {[gets $fp line] >= 0} {
        set s [string trim $line]

        if {$s eq ""} {
            continue
        }
        if {[string match "#*" $s]} {
            continue
        }

        # Strip repeated whitespace by tokenizing as a Tcl list only after
        # simple regex extraction. This avoids parentheses in report lines.
        if {![regexp {^([A-Za-z][A-Za-z0-9_./:+-]*)[ \t]+([0-9]+(?:[.][0-9]+)?%?)(?:[ \t]+|$)} \
                $s -> layer density_s]} {
            continue
        }

        if {![::TT_METAL_DENSITY::is_number $density_s]} {
            continue
        }

        # If user explicitly requested layers, only summarize those layers.
        if {[llength $requested_layers] > 0 &&
            [lsearch -exact $requested_layers $layer] < 0} {
            continue
        }

        set d [::TT_METAL_DENSITY::to_number $density_s]

        if {![info exists cnt($layer)]} {
            set cnt($layer) 0
            set sum($layer) 0.0
            set minv($layer) $d
            set maxv($layer) $d
        }

        incr cnt($layer)
        set sum($layer) [expr {$sum($layer) + $d}]

        if {$d < $minv($layer)} {
            set minv($layer) $d
        }
        if {$d > $maxv($layer)} {
            set maxv($layer) $d
        }
    }

    close $fp

    set layers [lsort -dictionary [array names cnt]]

    set sf [open $summary_file w]

    puts $sf "======================================================================"
    puts $sf " TT METAL DENSITY SUMMARY"
    puts $sf "======================================================================"
    puts $sf " Source report : $report_file"
    puts $sf " NOTE          : Min/Max/Avg are over Innovus-reported density windows."
    puts $sf "                 This is not asserted to equal Calibre whole-chip"
    puts $sf "                 AREA(Metal)/AREA(CHIP) signoff density."
    puts $sf "----------------------------------------------------------------------"
    puts $sf [format "%-14s %10s %12s %12s %12s" \
        "LAYER" "WINDOWS" "MIN(%)" "MAX(%)" "AVG(%)"]
    puts $sf "----------------------------------------------------------------------"

    puts ""
    puts "======================================================================"
    puts " TT METAL DENSITY SUMMARY"
    puts "======================================================================"
    puts [format "%-14s %10s %12s %12s %12s" \
        "LAYER" "WINDOWS" "MIN(%)" "MAX(%)" "AVG(%)"]
    puts "----------------------------------------------------------------------"

    foreach layer $layers {
        set avg [expr {$sum($layer) / double($cnt($layer))}]

        set row [format "%-14s %10d %12.4f %12.4f %12.4f" \
            $layer $cnt($layer) $minv($layer) $maxv($layer) $avg]

        puts $row
        puts $sf $row
    }

    puts $sf "======================================================================"
    close $sf

    if {[llength $layers] == 0} {
        puts "WARNING: No density rows were recognized by the summary parser."
        puts "         The raw Innovus report is still available:"
        puts "         $report_file"
        return [dict create]
    }

    puts "======================================================================"
    puts " Raw report     : $report_file"
    puts " Summary report : $summary_file"
    puts "======================================================================"

    set stats [dict create]
    foreach layer $layers {
        set avg [expr {$sum($layer) / double($cnt($layer))}]
        dict set stats $layer [dict create             windows $cnt($layer)             min $minv($layer)             max $maxv($layer)             avg $avg]
    }

    return $stats
}

proc TT_tool_report_metal_density {args} {
    set layers {}
    set area {}
    set report_file [tech_mv_output_path report TT_metal_density.rpt 05 metal_density]
    set detailed 1
    set summary_enable 1
    set check_min 1
    set check_max 1
    set fatal 1

    # --------------------------------------------------------------------------
    # Parse options.
    # --------------------------------------------------------------------------
    set i 0
    while {$i < [llength $args]} {
        set opt [lindex $args $i]

        switch -- $opt {
            -layers {
                incr i
                if {$i >= [llength $args]} {
                    error "-layers requires a Tcl list"
                }
                set layers [lindex $args $i]
            }

            -area {
                incr i
                if {$i >= [llength $args]} {
                    error "-area requires {x1 y1 x2 y2}"
                }
                set area [lindex $args $i]
                if {[llength $area] != 4} {
                    error "-area must contain exactly four coordinates"
                }
            }

            -report {
                incr i
                if {$i >= [llength $args]} {
                    error "-report requires a filename"
                }
                set report_file [lindex $args $i]
            }

            -detailed {
                incr i
                if {$i >= [llength $args]} {
                    error "-detailed requires 0 or 1"
                }
                set detailed [lindex $args $i]
                if {$detailed ni {0 1}} {
                    error "-detailed must be 0 or 1"
                }
            }

            -summary {
                incr i
                if {$i >= [llength $args]} {
                    error "-summary requires 0 or 1"
                }
                set summary_enable [lindex $args $i]
                if {$summary_enable ni {0 1}} {
                    error "-summary must be 0 or 1"
                }
            }

            -check_min {
                incr i
                if {$i >= [llength $args]} { error "-check_min requires 0 or 1" }
                set check_min [lindex $args $i]
                if {$check_min ni {0 1}} { error "-check_min must be 0 or 1" }
            }

            -check_max {
                incr i
                if {$i >= [llength $args]} { error "-check_max requires 0 or 1" }
                set check_max [lindex $args $i]
                if {$check_max ni {0 1}} { error "-check_max must be 0 or 1" }
            }

            -fatal {
                incr i
                if {$i >= [llength $args]} { error "-fatal requires 0 or 1" }
                set fatal [lindex $args $i]
                if {$fatal ni {0 1}} { error "-fatal must be 0 or 1" }
            }

            -help -
            --help {
                ::TT_METAL_DENSITY::usage
                return
            }

            default {
                error "Unknown option: $opt ; use -help"
            }
        }

        incr i
    }

    # --------------------------------------------------------------------------
    # Create report directory if necessary.
    # --------------------------------------------------------------------------
    set report_dir [file dirname $report_file]
    if {$report_dir ne "." && ![file isdirectory $report_dir]} {
        file mkdir $report_dir
    }

    set summary_file "${report_file}.summary"

    puts ""
    puts "======================================================================"
    puts " TT METAL DENSITY REPORT  v$::TT_METAL_DENSITY::version"
    puts "======================================================================"
    puts " Target DRC        : metal density / MAADNXX debug"
    puts " Density limits    : per-layer DENSITY_LIMIT_TABLE"
    if {[llength $layers] == 0} {
        puts " Layers            : ALL routing layers"
    } else {
        puts " Layers            : $layers"
    }
    if {[llength $area] == 0} {
        puts " Area              : entire design"
    } else {
        puts " Area              : $area"
    }
    puts " Detailed          : $detailed"
    puts " Check MIN         : $check_min"
    puts " Check MAX         : $check_max"
    puts " Fatal on failure  : $fatal"
    puts " Raw report        : $report_file"
    puts " Summary report    : $summary_file"
    puts "----------------------------------------------------------------------"

    # --------------------------------------------------------------------------
    # Build official Innovus command.
    # --------------------------------------------------------------------------
    set cmd [list check_metal_density]

    if {[llength $layers] > 0} {
        lappend cmd -layer $layers
    }

    if {[llength $area] == 4} {
        lappend cmd -area $area
    }

    if {$detailed} {
        lappend cmd -detailed
    }

    lappend cmd -report $report_file

    puts "CMD: $cmd"
    puts "----------------------------------------------------------------------"

    # --------------------------------------------------------------------------
    # Run Innovus density engine.
    # --------------------------------------------------------------------------
    if {[catch {uplevel #0 $cmd} err opts]} {
        puts ""
        puts "ERROR: check_metal_density failed."
        puts "       $err"
        puts ""
        puts "Try in the Innovus console:"
        puts "  man check_metal_density"
        return -options $opts $err
    }

    # --------------------------------------------------------------------------
    # Optional per-layer summary.
    # --------------------------------------------------------------------------
    if {$summary_enable} {
        set density_stats [::TT_METAL_DENSITY::make_summary \
            $report_file \
            $summary_file \
            $layers]

        # ------------------------------------------------------------------
        # PER-LAYER DENSITY LIMIT CHECK
        #
        # For every entry in DENSITY_LIMIT_TABLE:
        #
        #   reported MIN < configured MIN -> ERROR
        #   reported MAX > configured MAX -> ERROR
        #
        # All layers are checked first.  If one or more fail, a single Tcl
        # error is raised after the complete PASS/FAIL table is printed.
        # ------------------------------------------------------------------
        set limit_table [::TT_METAL_DENSITY::limit_table]

        if {[expr {[llength $limit_table] % 3}] != 0} {
            error "DENSITY_LIMIT_TABLE format error: each row must be {LAYER MIN_LIMIT MAX_LIMIT}"
        }

        puts ""
        puts "======================================================================"
        puts " PER-LAYER METAL DENSITY LIMIT CHECK"
        puts "======================================================================"
        puts [format "%-8s %12s %12s %12s %12s %10s" \
            "LAYER" "MIN_LIMIT" "REPORT_MIN" "REPORT_MAX" "MAX_LIMIT" "RESULT"]
        puts "----------------------------------------------------------------------"

        set fail_count 0
        set missing_count 0
        set fail_msgs {}

        foreach {layer min_limit max_limit} $limit_table {
            # If the caller requested selected layers, do not require density
            # data for unrelated entries in the global limit table.
            if {[llength $layers] > 0 && [lsearch -exact $layers $layer] < 0} {
                continue
            }

            if {![string is double -strict $min_limit]} {
                error "Invalid MIN limit for $layer: '$min_limit'"
            }
            if {![string is double -strict $max_limit]} {
                error "Invalid MAX limit for $layer: '$max_limit'"
            }
            if {$min_limit > $max_limit} {
                error [format \
                    "Invalid density range for %s: MIN %.4f%% > MAX %.4f%%" \
                    $layer $min_limit $max_limit]
            }

            if {![dict exists $density_stats $layer]} {
                incr missing_count
                incr fail_count
                lappend fail_msgs "$layer: density data missing"

                puts [format "%-8s %12.4f %12s %12s %12.4f %10s" \
                    $layer $min_limit "-" "-" $max_limit "ERROR"]
                continue
            }

            set report_min [dict get $density_stats $layer min]
            set report_max [dict get $density_stats $layer max]

            set fail_low  [expr {$check_min && ($report_min < $min_limit)}]
            set fail_high [expr {$check_max && ($report_max > $max_limit)}]

            if {$fail_low || $fail_high} {
                set result "ERROR"
                incr fail_count

                set reasons {}
                if {$fail_low} {
                    lappend reasons [format \
                        "MIN %.4f%% < limit %.4f%%" \
                        $report_min $min_limit]
                }
                if {$fail_high} {
                    lappend reasons [format \
                        "MAX %.4f%% > limit %.4f%%" \
                        $report_max $max_limit]
                }

                lappend fail_msgs "$layer: [join $reasons { ; }]"
            } else {
                set result "PASS"
            }

            puts [format "%-8s %12.4f %12.4f %12.4f %12.4f %10s" \
                $layer $min_limit $report_min $report_max $max_limit $result]
        }

        puts "----------------------------------------------------------------------"

        if {$fail_count > 0} {
            puts " RESULT : ERROR"
            puts " FAIL   : $fail_count layer(s)"
            if {$missing_count > 0} {
                puts " MISSING: $missing_count layer(s)"
            }
            puts ""
            puts "Failure details:"
            foreach msg $fail_msgs {
                puts "  - $msg"
            }
            puts "======================================================================"

            if {$fatal} {
                error "Metal density limit ERROR: $fail_count layer(s) outside configured enabled MIN/MAX checks"
            } else {
                puts "WARNING: Metal density violations reported, but -fatal 0 allows the flow to continue."
            }
        } else {
            puts " RESULT : PASS"
            puts " All configured layers are within MIN/MAX limits."
            puts "======================================================================"
        }

    } else {
        puts ""
        puts "DONE: $report_file"
    }

    return $report_file
}
