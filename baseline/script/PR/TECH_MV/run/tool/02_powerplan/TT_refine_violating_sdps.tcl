# Runtime adapter preserves the historical logical source path.
if {[info exists ::TECH_MV_RUNTIME_ROOT]} {
    info script [file join $::TECH_MV_RUNTIME_ROOT run/tool/02_powerplan/TT_refine_violating_sdps.tcl]
}
# =============================================================================
# TT_refine_violating_sdps.tcl
# TECH_MV / Innovus 21.19 Stylus / Common UI
# V2.13: clear temporary background and keep non-canonical LP cells UNPLACED
#
# Purpose:
#   Repair only SDP groups reported by check_sdps.
#
# Policy:
#   1) Run check_sdps and parse CHIP.checkSdp.rpt.
#   2) Map reported group/member names back to canonical [WT_L][CELL][WT_R]
#      records from TT_2row_ls_iso_welltap_generated.sdp.
#   3) Before every refine pass, restore the pre-global NON-SDP background to
#      UNPLACED when the integrated V7.18 snapshot/helper is available.
#   4) Force every non-canonical LS/ISO/RET cell UNPLACED; this tool never fixes it.
#   5) Unfix ONLY members of violating canonical SDP groups (fixed -> placed).
#   6) Keep all clean SDP groups fixed and run place_sdps as a targeted refine.
#   7) Re-FIX canonical members, rerun check_sdps, and iterate.
#
# Safety:
#   - No delete_obj / dbGet / dbSet / dbDelete*.
#   - No SDP detach/delete.
#   - Apply mode requires all three canonical members to still belong to the
#     expected live SDP row.  Therefore run this tool BEFORE the V7.15 side-tap
#     finalization step.  The integrated V7.15 flow calls it at that point.
#   - If Total violations > 0 but the report cannot be mapped to any SDP group,
#     APPLY stops without moving anything.
#
# Manual usage in the same Innovus session, at the FIX-before-finalize stage:
#
#   source run/tool/02_powerplan/TT_refine_violating_sdps.tcl
#   TT_refine_violating_sdps -dry_run 1
#   TT_refine_violating_sdps -apply -max_iter 3
# =============================================================================

if {![info exists ::TT_SDPV_SDP_FILE]} {
    if {[info exists ::TT_2ROW_SDP_FILE]} {
        set ::TT_SDPV_SDP_FILE $::TT_2ROW_SDP_FILE
    } else {
        set ::TT_SDPV_SDP_FILE [tech_mv_output_path temp TT_2row_ls_iso_welltap_generated.sdp 02 sdp]
    }
}
if {![info exists ::TT_SDPV_CHECK_REPORT]} { set ::TT_SDPV_CHECK_REPORT [tech_mv_native_sdp_report_path] }
if {![info exists ::TT_SDPV_REPORT]} { set ::TT_SDPV_REPORT ./reports/TT_refine_violating_sdps.rpt }
if {![info exists ::TT_SDPV_MAX_ITER]} { set ::TT_SDPV_MAX_ITER 3 }

proc TT_SDPV__leaf {name} {
    return [lindex [split $name "/"] end]
}

proc TT_SDPV__read_text {path} {
    if {![file exists $path]} { error "Required file not found: $path" }
    set fp [open $path r]
    set txt [read $fp]
    close $fp
    return $txt
}

proc TT_SDPV__parse_total {path} {
    set txt [TT_SDPV__read_text $path]
    set total -1
    foreach line [split $txt "\n"] {
        if {[regexp {^[ \t]*Total violations:[ \t]*([0-9]+)} $line -> n]} {
            set total $n
        }
    }
    if {$total < 0} { error "Cannot parse Total violations from '$path'." }
    return $total
}

proc TT_SDPV__parse_records {path} {
    set txt [TT_SDPV__read_text $path]
    set records {}
    set group ""
    set members {}
    foreach raw [split $txt "\n"] {
        set line [string trim $raw]
        if {[regexp {^datapath[ \t]+([^ \t\{]+)[ \t]*\{} $line -> g]} {
            if {$group ne ""} { error "Nested/malformed datapath in '$path'." }
            set group $g
            set members {}
            continue
        }
        if {$group ne "" && [regexp {^inst[ \t]+(.+)$} $line -> n]} {
            lappend members [string trim $n]
            continue
        }
        if {$group ne "" && $line eq "\}" && [llength $members] >= 3} {
            if {[llength $members] != 3} {
                error "Canonical SDP '$group' has [llength $members] members; expected exactly 3."
            }
            lappend records [list $group [lindex $members 0] [lindex $members 1] [lindex $members 2]]
            set group ""
            set members {}
        }
    }
    if {[llength $records] == 0} { error "No canonical SDP records parsed from '$path'." }
    return $records
}

proc TT_SDPV__build_lookup {exact_name leaf_name} {
    upvar 1 $exact_name exact $leaf_name leaf
    catch {array unset exact}
    catch {array unset leaf}
    foreach inst [get_db insts] {
        set n [get_db $inst .name]
        set exact($n) $inst
        set l [TT_SDPV__leaf $n]
        if {![info exists leaf($l)]} {
            set leaf($l) [list $inst]
        } else {
            lappend leaf($l) $inst
        }
    }
}

proc TT_SDPV__resolve {name exact_name leaf_name} {
    upvar 1 $exact_name exact $leaf_name leaf
    if {[info exists exact($name)]} { return $exact($name) }
    set l [TT_SDPV__leaf $name]
    if {[info exists leaf($l)] && [llength $leaf($l)] == 1} {
        return [lindex $leaf($l) 0]
    }
    return ""
}

proc TT_SDPV__contains {text token} {
    if {$token eq ""} { return false }
    return [expr {[string first $token $text] >= 0}]
}

proc TT_SDPV__violating_groups {records report_path} {
    set txt [TT_SDPV__read_text $report_path]
    set lines [split $txt "\n"]

    # Restrict matching to violation-detail neighborhoods.  This avoids marking
    # every SDP merely because a report format happens to list all groups in a
    # non-error inventory section.
    set ctx ""
    set n [llength $lines]
    for {set i 0} {$i < $n} {incr i} {
        set line [lindex $lines $i]
        if {![regexp -nocase {violation|overlap|placelegality|insideparentbox|interleav|justify|align|skipspace|orient} $line]} {
            continue
        }
        set lo [expr {$i > 1 ? $i-1 : 0}]
        set hi [expr {$i+5 < $n ? $i+5 : $n-1}]
        for {set j $lo} {$j <= $hi} {incr j} {
            append ctx [lindex $lines $j] "\n"
        }
    }

    set hit {}
    foreach rec $records {
        lassign $rec group wt_l cell wt_r
        set found false
        foreach token [list $group "${group}_ROW" $wt_l $cell $wt_r \
                            [TT_SDPV__leaf $wt_l] [TT_SDPV__leaf $cell] [TT_SDPV__leaf $wt_r]] {
            if {[TT_SDPV__contains $ctx $token]} {
                set found true
                break
            }
        }
        if {$found} { lappend hit $group }
    }
    return [lsort -unique $hit]
}

proc TT_SDPV__record_for_group {records target} {
    foreach rec $records {
        if {[lindex $rec 0] eq $target} { return $rec }
    }
    return ""
}

proc TT_SDPV__assert_full_live_membership {group objs} {
    set expected "${group}_ROW"
    foreach obj $objs {
        set n [get_db $obj .name]
        set row ""
        catch {set row [get_db $obj .sdp.name]}
        if {$row ne $expected} {
            error "Targeted refine requires full live SDP membership: '$n' SDP='$row', expected='$expected'. Run before side-tap finalization."
        }
    }
}


proc TT_SDPV__force_noncanonical_lp_unplaced {records {phase "TARGET_REFINE"}} {
    # If sourced by the integrated V7.18 flow, use its authoritative guard. This
    # also restores all originally-unplaced ordinary NON-SDP cells, not only LP.
    if {[llength [info commands TT_2row_sdp__force_noncanonical_lp_unplaced]] != 0} {
        return [TT_2row_sdp__force_noncanonical_lp_unplaced $phase]
    }

    # Standalone fallback: at minimum keep every LP cell outside canonical SDP
    # centers UNPLACED so a 1-row/non-SDP LP cell can never be fixed by repair.
    catch {array unset canonical}
    catch {array unset exact}
    catch {array unset leaf}
    TT_SDPV__build_lookup exact leaf
    foreach rec $records {
        lassign $rec group wt_l cell wt_r
        set obj [TT_SDPV__resolve $cell exact leaf]
        if {$obj eq ""} { error "Cannot resolve canonical center '$cell' for '$group'." }
        set canonical($obj) 1
    }

    set changed 0
    foreach spec {
        {LS  {is_level_shifter == true}}
        {ISO {is_isolation_cell == true}}
        {RET {is_retention == true}}
    } {
        lassign $spec cls filter_expr
        set cells [get_cells -hierarchical -filter $filter_expr]
        set names {}
        if {[llength $cells] > 0} { set names [get_object_name $cells] }
        foreach n $names {
            set objs {}
            catch {set objs [get_db insts $n]}
            foreach obj $objs {
                if {[info exists canonical($obj)]} { continue }
                set st ""
                catch {set st [get_db $obj .place_status]}
                if {$st ne "unplaced"} {
                    set_db $obj .place_status unplaced
                    incr changed
                }
            }
        }
    }
    puts "INFO: V2.13 standalone LP guard forced $changed non-canonical low-power cell(s) to UNPLACED during $phase."
    return $changed
}

proc TT_SDPV__prepare_background {records {phase "TARGET_REFINE"}} {
    if {[llength [info commands TT_2row_sdp__prepare_background_for_repair]] != 0 &&
        [info exists ::TT_2ROW_SDP_PRE_UNPLACED_SNAPSHOT]} {
        TT_2row_sdp__prepare_background_for_repair $::TT_2ROW_SDP_PRE_UNPLACED_SNAPSHOT $phase
        return
    }
    TT_SDPV__force_noncanonical_lp_unplaced $records $phase
}

proc TT_SDPV__set_groups_status {records groups status} {
    catch {array unset exact}
    catch {array unset leaf}
    TT_SDPV__build_lookup exact leaf
    set count 0
    foreach group $groups {
        set rec [TT_SDPV__record_for_group $records $group]
        if {$rec eq ""} { error "Unknown canonical SDP group '$group'." }
        lassign $rec g wt_l cell wt_r
        set objs {}
        foreach n [list $wt_l $cell $wt_r] {
            set obj [TT_SDPV__resolve $n exact leaf]
            if {$obj eq ""} { error "Cannot resolve canonical SDP member '$n' for group '$group'." }
            lappend objs $obj
        }
        if {$status ne "fixed"} {
            TT_SDPV__assert_full_live_membership $group $objs
        }
        foreach obj $objs {
            set_db $obj .place_status $status
            incr count
        }
    }
    return $count
}

proc TT_SDPV__fix_all_records {records} {
    set groups {}
    foreach rec $records { lappend groups [lindex $rec 0] }
    return [TT_SDPV__set_groups_status $records $groups fixed]
}

proc TT_SDPV__write_report {mode total groups {iter 0}} {
    file mkdir [file dirname $::TT_SDPV_REPORT]
    set fp [open $::TT_SDPV_REPORT a]
    puts $fp "time=[clock format [clock seconds] -format {%Y-%m-%d %H:%M:%S}] mode=$mode iter=$iter total=$total groups=[llength $groups]"
    foreach g $groups { puts $fp "  $g" }
    close $fp
}

proc TT_SDPV__run_check {} {
    if {[llength [info commands check_sdps]] == 0} { error "check_sdps is unavailable." }
    check_sdps -out_file [tech_mv_native_sdp_report_path]
    return [TT_SDPV__parse_total $::TT_SDPV_CHECK_REPORT]
}

proc TT_refine_violating_sdps {args} {
    set apply false
    set dry_run false
    set max_iter $::TT_SDPV_MAX_ITER

    set i 0
    while {$i < [llength $args]} {
        set a [lindex $args $i]
        switch -- $a {
            -apply { set apply true }
            -dry_run {
                incr i
                if {$i >= [llength $args]} { error "-dry_run requires 0 or 1." }
                set dry_run [expr {[lindex $args $i] ? true : false}]
            }
            -max_iter {
                incr i
                if {$i >= [llength $args]} { error "-max_iter requires an integer." }
                set max_iter [lindex $args $i]
            }
            -report {
                incr i
                if {$i >= [llength $args]} { error "-report requires a path." }
                set ::TT_SDPV_CHECK_REPORT [lindex $args $i]
            }
            -sdp_file {
                incr i
                if {$i >= [llength $args]} { error "-sdp_file requires a path." }
                set ::TT_SDPV_SDP_FILE [lindex $args $i]
            }
            default { error "Unknown option '$a'. Usage: TT_refine_violating_sdps -dry_run 1 | -apply ?-max_iter N? ?-report path? ?-sdp_file path?" }
        }
        incr i
    }

    if {!$apply && !$dry_run} { set dry_run true }
    if {$apply && $dry_run} { error "Choose either -dry_run 1 or -apply, not both." }
    if {![string is integer -strict $max_iter] || $max_iter < 1} { error "-max_iter must be >= 1." }
    if {[llength [info commands place_sdps]] == 0} { error "place_sdps is unavailable." }

    set records [TT_SDPV__parse_records $::TT_SDPV_SDP_FILE]
    set total [TT_SDPV__run_check]
    set groups [TT_SDPV__violating_groups $records $::TT_SDPV_CHECK_REPORT]

    puts ""
    puts "======================================================================"
    puts " TARGETED SDP VIOLATION REFINE"
    puts "======================================================================"
    puts "Mode                  : [expr {$apply ? {APPLY} : {DRY_RUN}}]"
    puts "Canonical SDP groups  : [llength $records]"
    puts "check_sdps violations : $total"
    puts "Mapped violating SDP  : [llength $groups]"
    puts "Report                : $::TT_SDPV_CHECK_REPORT"
    puts "Group report          : $::TT_SDPV_REPORT"
    puts "======================================================================"
    foreach g $groups { puts "VIOLATING_SDP: $g" }
    TT_SDPV__write_report [expr {$apply ? {APPLY_PRE} : {DRY_RUN}}] $total $groups 0

    if {$total == 0} {
        puts "PASS: check_sdps is already clean; no SDP member changed."
        return [dict create total_before 0 total_after 0 passes 0 groups {}]
    }
    if {[llength $groups] == 0} {
        error "check_sdps reports $total violation(s), but no canonical SDP group could be mapped from '$::TT_SDPV_CHECK_REPORT'. No member was unfixed."
    }
    if {!$apply} {
        puts "INFO: Dry-run only. Use: TT_refine_violating_sdps -apply -max_iter $max_iter"
        return [dict create total_before $total total_after $total passes 0 groups $groups]
    }

    set total_before $total
    set all_touched {}
    set pass 0
    while {$total != 0 && $pass < $max_iter} {
        incr pass
        foreach g $groups { if {[lsearch -exact $all_touched $g] < 0} { lappend all_touched $g } }

        # Clear temporary background first.  Only canonical 2-row SDP members
        # are allowed to participate in this legalization/refine pass.
        TT_SDPV__prepare_background $records "NATIVE_SDP_REFINE_PASS_$pass"

        # Freeze the canonical baseline first, then release ONLY violating rows.
        TT_SDPV__fix_all_records $records
        set released [TT_SDPV__set_groups_status $records $groups placed]
        puts "INFO: Refine pass $pass/$max_iter: released $released member(s) from [llength $groups] violating SDP group(s)."

        # Clean groups remain fixed. place_sdps therefore has movement freedom
        # only in the rows selected above.
        place_sdps

        # Requirement: every pass ends FIXED, even if violations remain.
        TT_SDPV__fix_all_records $records
        set total [TT_SDPV__run_check]
        set groups [TT_SDPV__violating_groups $records $::TT_SDPV_CHECK_REPORT]
        TT_SDPV__write_report APPLY_POST $total $groups $pass
        puts "INFO: Refine pass $pass result: total_violations=$total remaining_groups=[llength $groups]."

        if {$total != 0 && [llength $groups] == 0} {
            error "Refine pass $pass left $total violation(s), but the report no longer maps to canonical SDP groups. All canonical members were re-FIXED; stopping safely."
        }
    }

    # Absolute exit invariant requested by the flow: canonical SDP members are
    # fixed whether the repair converged or not.
    set fixed_count [TT_SDPV__fix_all_records $records]
    puts "INFO: Exit invariant: re-FIXED $fixed_count canonical SDP member(s)."

    puts ""
    puts "======================================================================"
    puts " TARGETED SDP REFINE RESULT"
    puts "======================================================================"
    puts "Initial violations : $total_before"
    puts "Final violations   : $total"
    puts "Passes             : $pass"
    puts "Touched SDP groups : [llength $all_touched]"
    puts "Canonical members FIXED : YES"
    puts "Non-canonical LP fixed   : NO (forced UNPLACED during refine)"
    puts "======================================================================"

    return [dict create total_before $total_before total_after $total passes $pass groups $all_touched]
}

puts "INFO: Loaded TT_refine_violating_sdps.tcl"
puts "INFO: Preview: TT_refine_violating_sdps -dry_run 1"
puts "INFO: Apply  : TT_refine_violating_sdps -apply -max_iter $::TT_SDPV_MAX_ITER"
