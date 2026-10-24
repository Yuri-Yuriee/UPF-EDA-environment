# =============================================================================
# terminal_report_footer.tcl
# =============================================================================
# Re-print report locations and concise *.summary contents at the very end of a
# stage so important results remain visible near the bottom of the Innovus
# terminal. Existing report generation is unchanged.
# =============================================================================

if {![info exists ::TERMINAL_REPORT_FOOTER_ENABLE]} {
    set ::TERMINAL_REPORT_FOOTER_ENABLE true
}
if {![info exists ::TERMINAL_REPORT_SUMMARY_MAX_LINES]} {
    set ::TERMINAL_REPORT_SUMMARY_MAX_LINES 120
}

# Mark the stage start as soon as this helper is sourced from a run/<stage>.tcl
# entry. The footer then prefers files created/updated during this invocation so
# stale reports from older runs do not dominate the terminal summary.
if {[info exists ::TECH_MV_REPORT_STAGE] && $::TECH_MV_REPORT_STAGE ne ""} {
    set ::TECH_MV_TERMINAL_REPORT_STAGE_START($::TECH_MV_REPORT_STAGE) [clock seconds]
    unset -nocomplain ::TECH_MV_LATEST_DRC_SUMMARY($::TECH_MV_REPORT_STAGE)
}

proc tech_mv_terminal_report_collect_files {dir} {
    set out {}
    if {![file isdirectory $dir]} {
        return $out
    }

    foreach item [glob -nocomplain -directory $dir *] {
        if {[file isdirectory $item]} {
            foreach child [tech_mv_terminal_report_collect_files $item] {
                lappend out $child
            }
        } elseif {[file isfile $item]} {
            lappend out [file normalize $item]
        }
    }
    return $out
}

proc tech_mv_terminal_report_print_summary_file {path} {
    if {![file isfile $path]} {
        return
    }

    set fp [open $path r]
    set data [read $fp]
    close $fp

    set lines [split $data "\n"]
    set max_lines $::TERMINAL_REPORT_SUMMARY_MAX_LINES
    if {![string is integer -strict $max_lines] || $max_lines <= 0} {
        set max_lines 120
    }

    set count [llength $lines]
    set start 0
    if {$count > $max_lines} {
        set start [expr {$count - $max_lines}]
        puts "INFO: Showing last $max_lines line(s) of summary file."
    }

    for {set i $start} {$i < $count} {incr i} {
        puts [lindex $lines $i]
    }
}

proc tech_mv_terminal_report_footer {stage {extra_reports {}}} {
    if {!$::TERMINAL_REPORT_FOOTER_ENABLE} {
        return
    }

    if {[llength [info commands tech_mv_report_dir]] == 0} {
        puts "WARNING: Terminal report footer skipped: tech_mv_report_dir is unavailable."
        return
    }

    if {[info exists ::TECH_MV_LATEST_DRC_SUMMARY($stage)]} {
        lappend extra_reports $::TECH_MV_LATEST_DRC_SUMMARY($stage)
    }
    set stage_dir [tech_mv_report_dir $stage]
    set report_files [tech_mv_terminal_report_collect_files $stage_dir]

    # Some legacy/current tools intentionally write stage reports directly under
    # $REPORT_DIR instead of the categorized stage directory. Include those too.
    if {[info exists ::REPORT_DIR] && [file isdirectory $::REPORT_DIR]} {
        foreach path [glob -nocomplain -types f -directory $::REPORT_DIR "${stage}_*"] {
            lappend report_files [file normalize $path]
        }
    }

    foreach path $extra_reports {
        if {$path eq "" || ![file isfile $path]} {
            continue
        }
        set norm [file normalize $path]
        if {[lsearch -exact $report_files $norm] < 0} {
            lappend report_files $norm
        }
    }

    set report_files [lsort -dictionary -unique $report_files]

    # Prefer reports from this invocation. Explicit extra_reports are always kept.
    if {[info exists ::TECH_MV_TERMINAL_REPORT_STAGE_START($stage)]} {
        set _stage_start $::TECH_MV_TERMINAL_REPORT_STAGE_START($stage)
        set _extras_normalized {}
        foreach _extra $extra_reports {
            if {$_extra ne "" && [file isfile $_extra]} {
                lappend _extras_normalized [file normalize $_extra]
            }
        }
        set _fresh {}
        foreach _path $report_files {
            if {[lsearch -exact $_extras_normalized $_path] >= 0 ||
                [file mtime $_path] >= [expr {$_stage_start - 1}]} {
                lappend _fresh $_path
            }
        }
        set report_files $_fresh
        unset _stage_start _extras_normalized _fresh
    }

    puts ""
    puts "======================================================================"
    puts " TERMINAL REPORT SUMMARY : STAGE $stage"
    puts "======================================================================"

    if {[llength $report_files] == 0} {
        puts "INFO: No report files found for this stage."
        puts "======================================================================"
        return
    }

    set summary_files {}
    foreach path $report_files {
        # Keep the check history, but print only the explicitly published latest DRC summary.
        if {[file tail [file dirname $path]] eq "drc" &&
            [string match "*.summary" $path] &&
            (![info exists ::TECH_MV_LATEST_DRC_SUMMARY($stage)] ||
             $path ne $::TECH_MV_LATEST_DRC_SUMMARY($stage))} { continue }
        puts "REPORT  : $path"
        if {[string match "*.summary" [file tail $path]]} {
            lappend summary_files $path
        }
    }

    foreach path $summary_files {
        puts ""
        puts "----------------------------------------------------------------------"
        puts " SUMMARY : $path"
        puts "----------------------------------------------------------------------"
        tech_mv_terminal_report_print_summary_file $path
    }

    puts "======================================================================"
}
