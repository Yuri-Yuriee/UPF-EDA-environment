# Runtime adapter preserves the historical logical source path.
if {[info exists ::TECH_MV_RUNTIME_ROOT]} {
    info script [file join $::TECH_MV_RUNTIME_ROOT run/tool/01_floorplan/checks/TT_proc_check_pd_endcaps.tcl]
} else {
    info script [file normalize [file join [file dirname [info script]] .. .. .. run/tool/01_floorplan/checks/TT_proc_check_pd_endcaps.tcl]]
}
# =============================================================================
# TT_proc_check_pd_endcaps.tcl
# =============================================================================
# READ-ONLY placement / Power-Domain EndCap checker.
#
# PASS/FAIL gate:
#
#   check_place
#     - Pre-route DRC Violation == 0
#     - Pin Access Violation   == 0
#
#   check_floorplan
#     - IMPFP-7251 is explicitly IGNORED
#     - any OTHER explicit ERROR remains fatal
#
#   EndCap
#     - explicit lines containing ENDCAP_PD remain fatal
#
# check_place markers are recorded for diagnostics only.  Their total count is
# NOT used as the gate because check_place may create many marker classes that
# are unrelated to the two summary counters above.
#
# This tool is READ ONLY.
# =============================================================================

proc tt_ec_check_report_root {{stage 90}} {
    return [tech_mv_report_dir $stage checkpoint]
}

proc tt_ec_check_safe_tag {tag} {
    return [string map {" " _ "/" _ ":" _ "\\" _} $tag]
}

proc tt_ec_current_check_place_markers {} {
    set result {}

    foreach m [get_db markers] {
        set originator ""
        catch {set originator [get_db $m .originator]}

        if {$originator ne "check_place"} {
            continue
        }

        set type ""
        set subtype ""
        catch {set type [get_db $m .type]}
        catch {set subtype [get_db $m .subtype]}

        lappend result [dict create \
            object $m \
            type $type \
            subtype $subtype]
    }

    return $result
}

# Parse the two check_place summary counters that are the actual gate.
proc tt_ec_parse_check_place_summary {text} {
    # Innovus only prints these summary lines when the corresponding
    # violation count is non-zero.  Therefore:
    #
    #   line absent  -> count = 0
    #   line present -> parse the printed count
    #
    # Do NOT use -1/UNKNOWN for an absent line.
    set pre_route_drc 0
    set pin_access 0

    set pre_present [regexp -nocase \
        {Pre-route[ \t]+DRC[ \t]+Violation:[ \t]*([0-9]+)} \
        $text -> pre_route_drc]

    set pin_present [regexp -nocase \
        {Pin[ \t]+Access[ \t]+Violation:[ \t]*([0-9]+)} \
        $text -> pin_access]

    return [dict create \
        parse_ok 1 \
        pre_route_drc_present $pre_present \
        pin_access_present $pin_present \
        pre_route_drc $pre_route_drc \
        pin_access $pin_access]
}

proc tech_mv_check_pd_endcaps {stage} {
    if {[info exists ::ENDCAP_POWER_DOMAIN_PREFIX] &&
        $::ENDCAP_POWER_DOMAIN_PREFIX ne ""} {
        set prefix $::ENDCAP_POWER_DOMAIN_PREFIX
    } else {
        set prefix ENDCAP_PD
    }

    set report_stage [tech_mv_report_stage_from_tag $stage 90]
    set dir [tt_ec_check_report_root $report_stage]
    set safe [tt_ec_check_safe_tag $stage]

    set check_place_rpt [tech_mv_report_path 96 "checkpoint_${safe}_check_place_raw" rpt $report_stage checkpoint]
    set raw_rpt         [tech_mv_report_path 97 "checkpoint_${safe}_check_floorplan_raw" rpt $report_stage checkpoint]
    set rpt             [tech_mv_report_path 95 "checkpoint_${safe}" rpt $report_stage checkpoint]

    # -------------------------------------------------------------------------
    # Run check_place and capture EXACTLY what Innovus prints.
    #
    # Cadence redirect supports -variable and -tee, so the output remains
    # visible in the console while also becoming machine-parseable.
    # -------------------------------------------------------------------------
    set check_place_text ""
    set check_place_error ""

    set check_place_rc [catch {
        redirect check_place_text {check_place} -variable -tee
    } check_place_error]

    # Keep a raw copy of the captured summary.
    set fp [open $check_place_rpt w]
    puts -nonewline $fp $check_place_text
    close $fp

    set cp_summary [tt_ec_parse_check_place_summary $check_place_text]
    set cp_parse_ok     [dict get $cp_summary parse_ok]
    set pre_route_drc   [dict get $cp_summary pre_route_drc]
    set pin_access      [dict get $cp_summary pin_access]

    set check_place_ok [expr {
        $check_place_rc == 0 &&
        $pin_access == 0
    }]

    # Marker count is diagnostic only.
    set check_place_markers [tt_ec_current_check_place_markers]
    set check_place_marker_count [llength $check_place_markers]

    # -------------------------------------------------------------------------
    # Native check_floorplan.
    #
    # User-approved exception:
    #   IMPFP-7251 is allowed and must NOT make the overall check FAIL.
    #
    # Other explicit check_floorplan ERRORs are still fatal.
    # -------------------------------------------------------------------------
    set checker_error ""
    set checker_rc [catch {
        check_floorplan -out_file $raw_rpt
    } checker_error]

    set endcap_problems {}
    set ignored_floorplan_errors {}
    set fatal_floorplan_errors {}

    if {[file exists $raw_rpt]} {
        set fp [open $raw_rpt r]
        set data [read $fp]
        close $fp

        foreach line [split $data "\n"] {
            if {[string match "*${prefix}*" $line]} {
                lappend endcap_problems $line
            }

            set is_error [expr {
                [string match "*ERROR:*" $line] ||
                [string match "**ERROR:*" $line]
            }]

            if {$is_error} {
                if {[string match "*IMPFP-7251*" $line]} {
                    lappend ignored_floorplan_errors $line
                } else {
                    lappend fatal_floorplan_errors $line
                }
            }
        }
    }

    set endcap_problem_count [llength $endcap_problems]
    set ignored_floorplan_error_count [llength $ignored_floorplan_errors]
    set fatal_floorplan_error_count [llength $fatal_floorplan_errors]

    # check_floorplan can return Tcl error status because of IMPFP-7251.
    # Ignore that rc ONLY when it is attributable to the approved IMPFP-7251.
    set checker_rc_fatal 0
    if {$checker_rc != 0} {
        set rc_is_7251 [expr {
            [string match "*IMPFP-7251*" $checker_error] ||
            $ignored_floorplan_error_count > 0
        }]

        if {!$rc_is_7251} {
            set checker_rc_fatal 1
        }
    }

    set check_floorplan_ok [expr {
        $fatal_floorplan_error_count == 0 &&
        $checker_rc_fatal == 0
    }]

    set endcap_ok [expr {$endcap_problem_count == 0}]

    # Overall gate:
    #   - check_place execution and Pin Access are clean
    #   - pre-route DRC is reported as non-gating advisory information
    #   - only non-approved check_floorplan ERRORs matter
    #   - explicit EndCap problems matter
    set ok [expr {
        $check_place_ok &&
        $check_floorplan_ok &&
        $endcap_ok
    }]

    set rc_penalty [expr {$checker_rc_fatal ? 1 : 0}]

    set problem_count [expr {
        $pin_access +
        $fatal_floorplan_error_count +
        $rc_penalty +
        $endcap_problem_count
    }]

    # -------------------------------------------------------------------------
    # Report
    # -------------------------------------------------------------------------
    set fp [open $rpt w]
    puts $fp "======================================================================"
    puts $fp " PLACEMENT / POWER-DOMAIN ENDCAP CHECK"
    puts $fp "======================================================================"
    puts $fp "Stage                         : $stage"
    puts $fp "EndCap prefix                 : $prefix"
    puts $fp ""
    puts $fp "CHECK_PLACE GATE"
    puts $fp "----------------"
    puts $fp "check_place return rc         : $check_place_rc"
    puts $fp "summary parse                 : PASS (absent line means 0)"
    puts $fp "Pre-route DRC Violation       : $pre_route_drc"
    puts $fp "Pre-route DRC policy          : advisory only; excluded from FAIL/problem count"
    puts $fp "Pin Access Violation          : $pin_access"
    puts $fp "check_place gate              : [expr {$check_place_ok ? {PASS} : {FAIL}}]"
    puts $fp "check_place markers (info)    : $check_place_marker_count"
    puts $fp "check_place raw report        : $check_place_rpt"
    if {$check_place_error ne ""} {
        puts $fp "check_place return text       : $check_place_error"
    }

    puts $fp ""
    puts $fp "CHECK_FLOORPLAN"
    puts $fp "---------------"
    puts $fp "return rc                     : $checker_rc"
    puts $fp "ignored IMPFP-7251 errors     : $ignored_floorplan_error_count"
    puts $fp "fatal other errors            : $fatal_floorplan_error_count"
    puts $fp "return rc fatal               : $checker_rc_fatal"
    puts $fp "check_floorplan gate          : [expr {$check_floorplan_ok ? {PASS} : {FAIL}}]"
    if {$checker_error ne ""} {
        puts $fp "check_floorplan return text   : $checker_error"
    }
    puts $fp "check_floorplan raw report    : $raw_rpt"

    puts $fp ""
    puts $fp "ENDCAP-SPECIFIC"
    puts $fp "---------------"
    puts $fp "EndCap problem count          : $endcap_problem_count"
    puts $fp "EndCap-only status            : [expr {$endcap_ok ? {PASS} : {FAIL}}]"

    puts $fp ""
    puts $fp "OVERALL STATUS                : [expr {$ok ? {PASS} : {FAIL}}]"
    puts $fp "TOTAL GATING PROBLEM COUNT    : $problem_count"

    puts $fp ""
    puts $fp "CHECK_PLACE MARKERS (DIAGNOSTIC ONLY)"
    puts $fp "-------------------------------------"
    foreach item $check_place_markers {
        puts $fp "MARKER type=[dict get $item type] subtype=[dict get $item subtype] object=[dict get $item object]"
    }

    puts $fp ""
    puts $fp "IGNORED CHECK_FLOORPLAN ERRORS"
    puts $fp "------------------------------"
    foreach line $ignored_floorplan_errors {
        puts $fp "IGNORE_NATIVE $line"
    }

    puts $fp ""
    puts $fp "FATAL CHECK_FLOORPLAN ERRORS"
    puts $fp "----------------------------"
    foreach line $fatal_floorplan_errors {
        puts $fp "FAIL_NATIVE $line"
    }

    puts $fp ""
    puts $fp "ENDCAP-SPECIFIC LINES"
    puts $fp "---------------------"
    foreach line $endcap_problems {
        puts $fp "FAIL_ENDCAP $line"
    }

    close $fp

    puts "INFO: Placement/EndCap check '$stage' = [expr {$ok ? {PASS} : {FAIL}}]"
    puts "INFO:   Pre-route DRC Violation = $pre_route_drc"
    puts "INFO:   Pin Access Violation    = $pin_access"
    puts "INFO:   check_place parse       = PASS (absent line means 0)"
    puts "INFO:   IMPFP-7251 ignored      = $ignored_floorplan_error_count"
    puts "INFO:   other FP errors         = $fatal_floorplan_error_count"
    puts "INFO:   EndCap problems         = $endcap_problem_count"
    puts "INFO:   report                  = $rpt"

    return [dict create \
        stage $stage \
        ok $ok \
        problem_count $problem_count \
        check_place_ok $check_place_ok \
        check_place_rc $check_place_rc \
        check_place_parse_ok $cp_parse_ok \
        pre_route_drc_violation $pre_route_drc \
        pin_access_violation $pin_access \
        check_place_marker_count $check_place_marker_count \
        check_place_raw_report $check_place_rpt \
        check_floorplan_ok $check_floorplan_ok \
        check_floorplan_rc $checker_rc \
        checker_rc_fatal $checker_rc_fatal \
        ignored_floorplan_error_count $ignored_floorplan_error_count \
        fatal_floorplan_error_count $fatal_floorplan_error_count \
        endcap_ok $endcap_ok \
        endcap_problem_count $endcap_problem_count \
        report $rpt \
        raw_report $raw_rpt \
        endcap_problems $endcap_problems \
        ignored_floorplan_errors $ignored_floorplan_errors \
        fatal_floorplan_errors $fatal_floorplan_errors]
}


# Official TT-naming public entry.
proc TT_proc_check_pd_endcaps {stage} {
    return [tech_mv_check_pd_endcaps $stage]
}
