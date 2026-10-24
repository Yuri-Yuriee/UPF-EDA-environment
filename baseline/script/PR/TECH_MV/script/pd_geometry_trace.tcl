# =============================================================================
# pd_geometry_trace.tcl
# =============================================================================
# Read-only command-level Power-Domain geometry tracing.
#
# The locked reference remains the geometry captured by pd_geometry_lock.tcl
# after the manual PD-snap checkpoint. This helper never changes floorplan
# geometry, placement, rows, Power Domains, or PG objects.
#
# It records:
#   - command/operation tag
#   - PASS/FAIL against the manual lock
#   - changed-group count
#   - grid-change status
#   - detailed pd_geometry_lock report path
#   - first unexpected PASS -> FAIL transition
#
# Temporary intentional PD geometry changes can be marked EXPECTED_CHANGE.
# =============================================================================

if {[llength [info commands tech_mv_pd_lock_check]] == 0} {
    source -quiet [file join $::SCRIPT_DIR pd_geometry_lock.tcl]
}

proc tech_mv_pd_trace_safe {value} {
    set safe $value
    regsub -all {[^A-Za-z0-9_.-]+} $safe {_} safe
    return [string trim $safe _]
}

proc tech_mv_pd_trace_index_file {} {
    set stage $::TECH_MV_PD_TRACE_STAGE
    return [tech_mv_report_path 93 \
        pd_geometry_command_trace rpt $stage pd_geometry_trace]
}

proc tech_mv_pd_trace_first_drift_file {} {
    set stage $::TECH_MV_PD_TRACE_STAGE
    return [tech_mv_report_path 92 \
        pd_geometry_first_unexpected_drift rpt $stage pd_geometry_trace]
}

proc tech_mv_pd_trace_reset {stage} {
    set ::TECH_MV_PD_TRACE_STAGE $stage
    set ::TECH_MV_PD_TRACE_SEQ 0
    set ::TECH_MV_PD_TRACE_EXPECT_CHANGE false
    set ::TECH_MV_PD_TRACE_EXPECT_REASON ""
    set ::TECH_MV_PD_TRACE_LAST_STABLE_TAG ""
    set ::TECH_MV_PD_TRACE_LAST_STABLE_COMMAND ""
    set ::TECH_MV_PD_TRACE_FIRST_DRIFT_FOUND false

    set index_file [tech_mv_pd_trace_index_file]
    set fp [open $index_file w]
    puts $fp "======================================================================"
    puts $fp " TECH_MV PD GEOMETRY COMMAND TRACE"
    puts $fp "======================================================================"
    puts $fp "Stage          : $stage"
    puts $fp "Reference      : manual PD geometry lock"
    puts $fp "Trace behavior : READ-ONLY"
    puts $fp ""
    puts $fp "SEQ | EXPECTATION | STATUS | CHANGED | GRID | TAG"
    puts $fp "COMMAND"
    puts $fp "DETAIL_REPORT"
    puts $fp "----------------------------------------------------------------------"
    close $fp

    catch {file delete -force [tech_mv_pd_trace_first_drift_file]}

    puts "INFO: PD command trace initialized for stage $stage."
    puts "INFO:   index = $index_file"
    return $index_file
}

proc tech_mv_pd_trace_set_expected_change {enabled {reason ""}} {
    set ::TECH_MV_PD_TRACE_EXPECT_CHANGE [expr {$enabled ? true : false}]
    set ::TECH_MV_PD_TRACE_EXPECT_REASON $reason

    if {$::TECH_MV_PD_TRACE_EXPECT_CHANGE} {
        puts "INFO: PD trace expected-change window enabled: $reason"
    } else {
        puts "INFO: PD trace expected-change window disabled."
    }
}

proc tech_mv_pd_trace {tag {command ""}} {
    if {![info exists ::TECH_MV_PD_TRACE_STAGE]} {
        if {[info exists ::TECH_MV_REPORT_STAGE]} {
            tech_mv_pd_trace_reset $::TECH_MV_REPORT_STAGE
        } else {
            tech_mv_pd_trace_reset 90
        }
    }

    incr ::TECH_MV_PD_TRACE_SEQ
    set seq $::TECH_MV_PD_TRACE_SEQ
    set seq_text [format "%03d" $seq]

    set safe_tag [tech_mv_pd_trace_safe $tag]
    set detail_tag "${::TECH_MV_PD_TRACE_STAGE}_trace_${seq_text}_${safe_tag}"
    set result [tech_mv_pd_lock_check $detail_tag]

    set ok [dict get $result ok]
    set changed [dict get $result changed]
    set grid_changed [dict get $result grid_changed]
    set detail_report [dict get $result report]

    set expectation [expr {
        $::TECH_MV_PD_TRACE_EXPECT_CHANGE ? "EXPECTED_CHANGE" : "STABLE"
    }]
    set status [expr {$ok ? "PASS" : "FAIL"}]

    set index_file [tech_mv_pd_trace_index_file]
    set fp [open $index_file a]
    puts $fp [format "%s | %-15s | %-4s | %7d | %4d | %s" \
        $seq_text $expectation $status $changed $grid_changed $tag]
    puts $fp "COMMAND       : $command"
    if {$::TECH_MV_PD_TRACE_EXPECT_CHANGE &&
        $::TECH_MV_PD_TRACE_EXPECT_REASON ne ""} {
        puts $fp "EXPECTED WHY  : $::TECH_MV_PD_TRACE_EXPECT_REASON"
    }
    puts $fp "DETAIL_REPORT : $detail_report"
    puts $fp "----------------------------------------------------------------------"
    close $fp

    puts "INFO: PD trace $seq_text expectation=$expectation tag=$tag status=$status changed_groups=$changed grid_changed=$grid_changed"

    # Expected temporary mutations are recorded but do not participate in the
    # unexpected first-drift transition detector.
    if {!$::TECH_MV_PD_TRACE_EXPECT_CHANGE} {
        if {$ok} {
            set ::TECH_MV_PD_TRACE_LAST_STABLE_TAG $tag
            set ::TECH_MV_PD_TRACE_LAST_STABLE_COMMAND $command
        } elseif {!$::TECH_MV_PD_TRACE_FIRST_DRIFT_FOUND} {
            set first_file [tech_mv_pd_trace_first_drift_file]
            set ff [open $first_file w]
            puts $ff "======================================================================"
            puts $ff " FIRST UNEXPECTED PD GEOMETRY DRIFT"
            puts $ff "======================================================================"
            puts $ff "Stage                  : $::TECH_MV_PD_TRACE_STAGE"
            puts $ff "Current trace tag      : $tag"
            puts $ff "Current command        : $command"
            puts $ff "Current detail report  : $detail_report"
            if {$::TECH_MV_PD_TRACE_LAST_STABLE_TAG ne ""} {
                puts $ff "Previous stable tag    : $::TECH_MV_PD_TRACE_LAST_STABLE_TAG"
                puts $ff "Previous stable command: $::TECH_MV_PD_TRACE_LAST_STABLE_COMMAND"
                puts $ff ""
                puts $ff "Interpretation:"
                puts $ff "  Geometry was still locked at the previous stable tag."
                puts $ff "  The first observed unexpected drift is at the current tag."
            } else {
                puts $ff "Previous stable tag    : <NONE IN THIS STAGE>"
                puts $ff ""
                puts $ff "Interpretation:"
                puts $ff "  This stage entered with geometry already different from the manual lock."
                puts $ff "  Inspect the previous stage trace."
            }
            puts $ff "======================================================================"
            close $ff

            set ::TECH_MV_PD_TRACE_FIRST_DRIFT_FOUND true

            puts ""
            puts "======================================================================"
            puts " FIRST UNEXPECTED PD GEOMETRY DRIFT DETECTED"
            puts "======================================================================"
            puts "Current tag     : $tag"
            puts "Current command : $command"
            puts "Previous stable : [expr {$::TECH_MV_PD_TRACE_LAST_STABLE_TAG eq "" ? "<NONE IN THIS STAGE>" : $::TECH_MV_PD_TRACE_LAST_STABLE_TAG}]"
            puts "Report          : $first_file"
            puts "======================================================================"
        }
    }

    return $result
}
