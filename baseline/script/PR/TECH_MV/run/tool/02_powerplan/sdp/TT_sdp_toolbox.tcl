# Runtime adapter preserves the historical logical source path.
if {[info exists ::TECH_MV_RUNTIME_ROOT]} {
    info script [file join $::TECH_MV_RUNTIME_ROOT run/tool/02_powerplan/sdp/TT_sdp_toolbox.tcl]
}
# =============================================================================
# TT_sdp_toolbox.tcl
# TECH_MV / PR7 unified SDP check + manual command menu
# Innovus 21.19 Stylus / Common UI
#
# Public commands:
#   TT_sdp_tools
#   TT_sdp_help
#   TT_sdp_check_all
#
# TT_sdp_check_all is READ-ONLY with respect to placement/database geometry.
# It may create report/snapshot files and invoke native check_sdps.
# =============================================================================

proc TT_SDP_TB__cmd_state {cmd} {
    if {[llength [info commands $cmd]] > 0} { return "OK" }
    return "MISSING"
}

proc TT_SDP_TB__report_dir {} {
    if {[info exists ::REPORT_DIR] && $::REPORT_DIR ne ""} {
        set d [file join $::REPORT_DIR sdp_check_all]
    } else {
        set d [file normalize [file join reports sdp_check_all]]
    }
    file mkdir $d
    return $d
}

proc TT_SDP_TB__write_text {path text} {
    set fp [open $path w]
    puts -nonewline $fp $text
    close $fp
}

proc TT_SDP_TB__read_text {path} {
    if {![file exists $path]} { return "" }
    set fp [open $path r]
    set s [read $fp]
    close $fp
    return $s
}

proc TT_SDP_TB__parse_native_counts {text} {
    set labels {
        Orientation
        JustifyBy
        AlignByPinName
        SkipSpace
        Overlap
        InsideParentBox
        Alignment
        PlaceLegality
        Interleaving
    }
    set d [dict create]
    foreach label $labels {
        set n -1
        regexp -nocase [format {%s[[:space:]]+violations:[[:space:]]*([0-9]+)} $label] $text -> n
        dict set d $label $n
    }
    set total -1
    regexp -nocase {Total[[:space:]]+violations:[[:space:]]*([0-9]+)} $text -> total
    dict set d Total $total
    return $d
}

proc TT_SDP_TB__native_unchecked_rules {console_text} {
    set out {}
    foreach line [split $console_text "\n"] {
        if {[regexp -nocase {was not checked|wasn't checked|not checked because} $line]} {
            lappend out [string trim $line]
        }
    }
    return [lsort -unique $out]
}

proc TT_SDP_TB__parse_switch_gap {console_text raw_result} {
    set d [dict create parsed false switches -1 violations -1 groups -1 required_gap "UNKNOWN" raw $raw_result]
    if {[regexp -nocase {switch-gap validation:[[:space:]]*switches=([0-9]+)[[:space:]]+violations=([0-9]+)[[:space:]]+groups=([0-9]+)[[:space:]]+required_gap=([0-9.]+)um} \
            $console_text -> sw vio grp gap]} {
        dict set d parsed true
        dict set d switches $sw
        dict set d violations $vio
        dict set d groups $grp
        dict set d required_gap $gap
        return $d
    }

    # Flexible fallback in case the checker returns a dict instead of printing.
    foreach key {violations gap_violations final_violations} {
        if {![catch {set v [dict get $raw_result $key]}] && [string is integer -strict $v]} {
            dict set d parsed true
            dict set d violations $v
            break
        }
    }
    foreach key {groups gap_groups final_groups} {
        if {![catch {set g [dict get $raw_result $key]}]} {
            if {[string is integer -strict $g]} {
                dict set d groups $g
            } else {
                dict set d groups [llength $g]
            }
            break
        }
    }
    foreach key {required_gap gap} {
        if {![catch {set g [dict get $raw_result $key]}]} {
            dict set d required_gap $g
            break
        }
    }
    return $d
}

proc TT_sdp_tools {} {
    puts ""
    puts "======================================================================"
    puts " TT SDP TOOLBOX / MANUAL INTERFACE"
    puts "======================================================================"
    puts ""
    puts "UNIFIED CHECK"
    puts "  TT_sdp_check_all"
    puts "    Runs one consolidated read-only check for custom PR7 rules + native"
    puts "    Innovus SDP rules, writes reports, and prints one PASS/FAIL summary."
    puts ""
    puts "CUSTOM CHECK TOOLS"
    puts [format "  %-46s (%s)" "TT_PR7_scan_internal_sdp_structure true true" [TT_SDP_TB__cmd_state TT_PR7_scan_internal_sdp_structure]]
    puts "    Checks canonical WT_L/CELL/WT_R membership/order, internal gap"
    puts "    0..0.18um, overlap, and foreign instances inside either internal gap."
    puts [format "  %-46s (%s)" "TT_PR7_verify_sdp SDP2R_00066_ROW" [TT_SDP_TB__cmd_state TT_PR7_verify_sdp]]
    puts "    Detailed single-SDP debug for the same internal structure/gap rules."
    puts [format "  %-46s (%s)" "TT_PR7_scan_sdp_origin_delta true" [TT_SDP_TB__cmd_state TT_PR7_scan_sdp_origin_delta]]
    puts "    Finds stale SDP origins after placement/re-anchor activity."
    puts [format "  %-46s (%s)" "TT_2row_sdp__scan_switch_gap true" [TT_SDP_TB__cmd_state TT_2row_sdp__scan_switch_gap]]
    puts "    Detailed SDP-to-power-switch spacing scan."
    puts [format "  %-46s (%s)" "TT_2row_sdp__validate_switch_gap" [TT_SDP_TB__cmd_state TT_2row_sdp__validate_switch_gap]]
    puts "    Validates the custom power-switch clearance rule (current flow: 0.72um)."
    puts [format "  %-46s (%s)" "TT_SDP_PGROW_scan true" [TT_SDP_TB__cmd_state TT_SDP_PGROW_scan]]
    puts "    ADDITIVE Power-Gated rules: <=1 canonical 2-row ISO per adjacent SW pair;"
    puts "    and no canonical 2-row ISO on a placement-row band with no Power Switch."
    puts ""
    puts "NATIVE INNOVUS CHECK TOOLS"
    puts [format "  %-46s (%s)" "check_sdps" [TT_SDP_TB__cmd_state check_sdps]]
    puts "    Native authority: Orientation, JustifyBy, AlignByPinName, SkipSpace,"
    puts "    Overlap, InsideParentBox, Alignment, PlaceLegality, Interleaving."
    puts "    NOTE: if Innovus says a rule was not checked, TT_sdp_check_all reports"
    puts "    the result as INCOMPLETE instead of calling it PASS."
    puts [format "  %-46s (%s)" "TT_2row_sdp__check_sdps_total" [TT_SDP_TB__cmd_state TT_2row_sdp__check_sdps_total]]
    puts "    Flow wrapper that returns native total violations. Useful as a quick gate."
    puts "    TT_sdp_check_all calls native check_sdps only once and parses that report,"
    puts "    so it does not intentionally duplicate the full native run."
    puts [format "  %-46s (%s)" "write_sdp_file ./.temp/02_powerplan/sdp/TT_checkpoint.sdp" [TT_SDP_TB__cmd_state write_sdp_file]]
    puts "    Dumps the current SDP definition for audit/debug; does not repair placement."
    puts ""
    puts "REPAIR TOOLS"
    puts [format "  %-46s (%s)" "TT_refine_internal_gap_sdps ?move_distance?" [TT_SDP_TB__cmd_state TT_refine_internal_gap_sdps]]
    puts "    R9: each round adds one-WellTap CELL-center BLKs to all unresolved groups,"
    puts "    applies temporary >=8-site CELL padding, runs ONE batched place_detail,"
    puts "    then guarded set_sdp_origin. CELL must stay fixed; WTs may follow origin."
    puts "    PASS removes that group GAPBLKs; unresolved groups retry up to max rounds."
    puts [format "  %-46s (%s)" "TT_PR7_gap_block_preview <ROW>" [TT_SDP_TB__cmd_state TT_PR7_gap_block_preview]]
    puts "    READ-ONLY: shows the next one-WellTap CELL-relocation blockage that R9 would"
    puts "    place at the current center of the target SDP CELL."
    puts [format "  %-46s (%s)" "TT_refine_switch_gap_sdps 5" [TT_SDP_TB__cmd_state TT_refine_switch_gap_sdps]]
    puts "    Repairs SDP groups that violate the custom power-switch spacing rule."
    puts [format "  %-46s (%s)" "TT_SDP_PGROW_repair" [TT_SDP_TB__cmd_state TT_SDP_PGROW_repair]]
    puts "    Repairs only PGROW violating groups by injecting them into the existing"
    puts "    TT_refine_internal_gap_sdps R9 CELL-reanchor engine."
    puts [format "  %-46s (%s)" "TT_refine_violating_sdps -dry_run 1" [TT_SDP_TB__cmd_state TT_refine_violating_sdps]]
    puts "    Preview native-SDP repair candidates without applying the repair."
    puts [format "  %-46s (%s)" "TT_refine_violating_sdps -apply -max_iter 3" [TT_SDP_TB__cmd_state TT_refine_violating_sdps]]
    puts "    Applies the existing native-SDP violation repair loop."
    puts "    If missing, source run/tool/02_powerplan/TT_refine_violating_sdps.tcl first."
    puts [format "  %-46s (%s)" "TT_PR7_coordinate_guided_preview <ROW>" [TT_SDP_TB__cmd_state TT_PR7_coordinate_guided_preview]]
    puts "    Read-only candidate search. Candidate must fit real rows + same PD +"
    puts "    ALL placement blockages + ALL placed/fixed/soft_fixed/cover cells +"
    puts "    explicit power-switch clearance before it is shown as legal."
    puts [format "  %-46s (%s)" "TT_PR7_coordinate_guided_repair <ROW>" [TT_SDP_TB__cmd_state TT_PR7_coordinate_guided_repair]]
    puts "    Legacy/R6 coordinate tool retained for debug only. R9 normal gap repair"
    puts "    does NOT invoke it; native place_detail selects CELL locations."
    puts [format "  %-46s (%s)" "TT_PR7_manual_origin_preview <ROW>" [TT_SDP_TB__cmd_state TT_PR7_manual_origin_preview]]
    puts "    After GUI/manual movement, preview origin delta without modifying anything."
    puts [format "  %-46s (%s)" "TT_PR7_manual_sync_origin <ROW>" [TT_SDP_TB__cmd_state TT_PR7_manual_sync_origin]]
    puts "    Synchronizes SDP origin to manually moved members; does NOT call place_sdps."
    puts [format "  %-46s (%s)" "TT_PR7_manual_sync_selected" [TT_SDP_TB__cmd_state TT_PR7_manual_sync_selected]]
    puts "    Same manual origin sync using currently GUI-selected SDP member(s)."
    puts [format "  %-46s (%s)" "TT_PR7_sync_sdp_origins" [TT_SDP_TB__cmd_state TT_PR7_sync_sdp_origins]]
    puts "    MANUAL bulk-sync tool only. R9 automatic repair uses only targeted guarded"
    puts "    re-anchor after CELL relocation; it does not run this broad sync helper."
    puts ""
    puts "POST-RESUME / WELLTAP HANDOFF"
    puts [format "  %-46s (%s)" "TT_sdp_post_resume_preview" [TT_SDP_TB__cmd_state TT_sdp_post_resume_preview]]
    puts "    Shows only SDP-owned temporary placement BLKs that would be removed."
    puts [format "  %-46s (%s)" "TT_sdp_post_resume_cleanup" [TT_SDP_TB__cmd_state TT_sdp_post_resume_cleanup]]
    puts "    Deletes only TT_SDP_SWKO_* + TT_PR7_GAPBLK_*; all other BLKs stay."
    puts [format "  %-46s (%s)" "TT_sdp_post_resume_arm" [TT_SDP_TB__cmd_state TT_sdp_post_resume_arm]]
    puts "    Arms one-shot suspend-leave cleanup. Cleanup must PASS before suspend"
    puts "    returns; only then can the outer flow reach its existing add_well_taps.tcl."
    puts ""
    puts "CHECKPOINT"
    puts "  resume"
    puts "    Continues the one-time inspection checkpoint; it does not loop back."
    puts ""
    puts "MANUAL LOAD"
    puts "  source run/tool/02_powerplan/sdp/TT_sdp_toolbox.tcl"
    puts "  TT_sdp_tools"
    puts "======================================================================"
    return 0
}

proc TT_sdp_help {} { return [TT_sdp_tools] }

proc TT_sdp_check_all {} {
    puts ""
    puts "======================================================================"
    puts " TT SDP CHECK ALL - CUSTOM RULES + NATIVE INNOVUS RULES"
    puts "======================================================================"
    puts "Policy: READ-ONLY for placement/geometry; report and SDP snapshot files only."

    set stamp [clock format [clock seconds] -format "%Y%m%d_%H%M%S"]
    set dir [TT_SDP_TB__report_dir]
    set prefix [file join $dir "TT_sdp_check_all_${stamp}"]
    set native_rpt "${prefix}.native_check_sdps.rpt"
    set native_console_rpt "${prefix}.native_console.rpt"
    set switch_console_rpt "${prefix}.switch_gap_console.rpt"
    set pgrow_console_rpt "${prefix}.powergate_row_console.rpt"
    set summary_rpt "${prefix}.summary.rpt"
    set snapshot "${prefix}.sdp"

    set errors {}

    # ----------------------------------------------------------------------
    # Custom rule 1: canonical structure + internal gaps + foreign-in-gap.
    # ----------------------------------------------------------------------
    set internal [dict create checked -1 violations -1 groups {}]
    if {[llength [info commands TT_PR7_scan_internal_sdp_structure]] == 0} {
        lappend errors "TT_PR7_scan_internal_sdp_structure unavailable"
    } else {
        if {[catch {set internal [TT_PR7_scan_internal_sdp_structure true false]} err]} {
            lappend errors "internal structure scan failed: $err"
        }
    }

    # ----------------------------------------------------------------------
    # Custom rule 2: SDP origin == actual canonical member envelope LL.
    # ----------------------------------------------------------------------
    set origin [dict create checked -1 mismatches -1 skipped -1 groups {}]
    if {[llength [info commands TT_PR7_scan_sdp_origin_delta]] == 0} {
        lappend errors "TT_PR7_scan_sdp_origin_delta unavailable"
    } else {
        if {[catch {set origin [TT_PR7_scan_sdp_origin_delta true]} err]} {
            lappend errors "origin delta scan failed: $err"
        }
    }

    # ----------------------------------------------------------------------
    # Custom rule 3: SDP-to-power-switch clearance.
    # Prefer validate; fall back to detailed scan if validate is unavailable.
    # ----------------------------------------------------------------------
    set switch_console ""
    set switch_raw ""
    set switch_rc 0
    if {[llength [info commands TT_2row_sdp__validate_switch_gap]] > 0} {
        set switch_rc [catch {
            redirect switch_console {TT_2row_sdp__validate_switch_gap} -variable -tee
        } switch_err]
    } elseif {[llength [info commands TT_2row_sdp__scan_switch_gap]] > 0} {
        set switch_rc [catch {
            redirect switch_console {set switch_raw [TT_2row_sdp__scan_switch_gap true]} -variable -tee
        } switch_err]
    } else {
        set switch_rc 1
        set switch_err "switch-gap checker unavailable"
    }
    if {$switch_rc} {
        lappend errors "switch-gap validation failed: $switch_err"
    }
    catch {TT_SDP_TB__write_text $switch_console_rpt $switch_console}
    set switch_result [TT_SDP_TB__parse_switch_gap $switch_console $switch_raw]
    if {![dict get $switch_result parsed]} {
        lappend errors "switch-gap result could not be parsed"
    }

    # ----------------------------------------------------------------------
    # Custom rule 4/5: Power-Gated row topology (ADDITIVE).
    #   R1: <=1 canonical 2-row ISO between one adjacent SW pair.
    #   R2: no canonical 2-row ISO on a row band with no SW.
    # Read-only here: no temporary row blockage is created/deleted.
    # ----------------------------------------------------------------------
    set pgrow_console ""
    set pgrow [dict create violations -1 checked_iso -1 no_switch_row_groups {} multi_iso_groups {} multi_iso_intervals {} repair_groups {} domains {}]
    if {[llength [info commands TT_SDP_PGROW_scan]] == 0} {
        lappend errors "TT_SDP_PGROW_scan unavailable"
    } else {
        if {[catch {
            redirect pgrow_console {set pgrow [TT_SDP_PGROW_scan true]} -variable -tee
        } pgrow_err]} {
            lappend errors "Power-Gated row-rule scan failed: $pgrow_err"
        }
    }
    catch {TT_SDP_TB__write_text $pgrow_console_rpt $pgrow_console}

    # ----------------------------------------------------------------------
    # Native authority: run FULL check_sdps exactly once in this aggregate.
    # Capture console so skipped native rules are explicit.
    # ----------------------------------------------------------------------
    set native_console ""
    set native_rc 0
    if {[llength [info commands check_sdps]] == 0} {
        set native_rc 1
        set native_err "check_sdps unavailable"
    } else {
        set native_rc [catch {
            redirect native_console [list check_sdps -out_file $native_rpt] -variable -tee
        } native_err]
    }
    if {$native_rc} {
        lappend errors "native check_sdps failed: $native_err"
    }
    catch {TT_SDP_TB__write_text $native_console_rpt $native_console}

    set native_text [TT_SDP_TB__read_text $native_rpt]
    if {$native_text eq ""} { set native_text $native_console }
    set native_counts [TT_SDP_TB__parse_native_counts $native_text]
    if {[dict get $native_counts Total] < 0} {
        lappend errors "native check_sdps total could not be parsed"
    }
    set unchecked [TT_SDP_TB__native_unchecked_rules $native_console]

    # Snapshot current SDP definition for audit/debug. Failure is reported but
    # does not change the check result itself.
    if {[llength [info commands write_sdp_file]] > 0} {
        if {[catch {write_sdp_file $snapshot} snap_err]} {
            lappend errors "write_sdp_file failed: $snap_err"
        }
    } else {
        lappend errors "write_sdp_file unavailable"
    }

    set internal_vio -1
    catch {set internal_vio [dict get $internal violations]}
    set origin_vio -1
    catch {set origin_vio [dict get $origin mismatches]}
    set switch_vio [dict get $switch_result violations]
    set pgrow_vio -1
    catch {set pgrow_vio [dict get $pgrow violations]}
    set native_total [dict get $native_counts Total]

    set custom_fail false
    foreach v [list $internal_vio $origin_vio $switch_vio $pgrow_vio] {
        if {[string is integer -strict $v] && $v > 0} { set custom_fail true }
    }
    set native_fail [expr {[string is integer -strict $native_total] && $native_total > 0}]

    if {[llength $errors] > 0} {
        set status "INCOMPLETE"
    } elseif {$custom_fail || $native_fail} {
        set status "FAIL"
    } elseif {[llength $unchecked] > 0} {
        set status "INCOMPLETE_NATIVE_RULES"
    } else {
        set status "PASS"
    }

    puts ""
    puts "----------------------------------------------------------------------"
    puts " CUSTOM RULE SUMMARY"
    puts "----------------------------------------------------------------------"
    puts [format "%-38s %s" "Canonical/internal-gap violations" $internal_vio]
    puts [format "%-38s %s" "SDP-origin mismatches" $origin_vio]
    puts [format "%-38s %s" "Switch-gap pair violations" $switch_vio]
    puts [format "%-38s %s" "Switch-gap violating groups" [dict get $switch_result groups]]
    puts [format "%-38s %s" "Required switch gap (um)" [dict get $switch_result required_gap]]
    puts [format "%-38s %s" "PGROW total violating groups" $pgrow_vio]
    puts [format "%-38s %s" "PGROW-R1 excess ISO groups" [dict get $pgrow multi_iso_groups]]
    puts [format "%-38s %s" "PGROW-R2 no-SW-row ISO groups" [dict get $pgrow no_switch_row_groups]]

    puts ""
    puts "----------------------------------------------------------------------"
    puts " NATIVE INNOVUS RULE SUMMARY"
    puts "----------------------------------------------------------------------"
    foreach label {Orientation JustifyBy AlignByPinName SkipSpace Overlap InsideParentBox Alignment PlaceLegality Interleaving Total} {
        puts [format "%-38s %s" "${label} violations" [dict get $native_counts $label]]
    }
    if {[llength $unchecked] == 0} {
        puts "Native rules explicitly skipped     : 0"
    } else {
        puts "Native rules explicitly skipped     : [llength $unchecked]"
        foreach line $unchecked { puts "  UNCHECKED: $line" }
    }

    if {[llength $errors] > 0} {
        puts ""
        puts "----------------------------------------------------------------------"
        puts " CHECK EXECUTION ISSUES"
        puts "----------------------------------------------------------------------"
        foreach e $errors { puts "  $e" }
    }

    puts ""
    puts "======================================================================"
    puts " TT SDP CHECK ALL RESULT : $status"
    puts "======================================================================"
    puts "Native report  : $native_rpt"
    puts "Native console : $native_console_rpt"
    puts "Switch console : $switch_console_rpt"
    puts "PGROW console  : $pgrow_console_rpt"
    puts "SDP snapshot   : $snapshot"
    puts "Summary report : $summary_rpt"
    if {$status eq "INCOMPLETE_NATIVE_RULES"} {
        puts "NOTE: native violation count is clean, but Innovus explicitly skipped"
        puts "      at least one native rule. This is NOT reported as full PASS."
    }
    puts "======================================================================"

    set result [dict create \
        status $status \
        custom_internal $internal \
        origin $origin \
        switch_gap $switch_result \
        powergate_row $pgrow \
        native_counts $native_counts \
        native_unchecked $unchecked \
        errors $errors \
        reports [dict create native $native_rpt native_console $native_console_rpt switch_console $switch_console_rpt powergate_row_console $pgrow_console_rpt snapshot $snapshot summary $summary_rpt]]
    set ::TT_SDP_CHECK_ALL_RESULT $result

    set sfp [open $summary_rpt w]
    puts $sfp "TT SDP CHECK ALL RESULT : $status"
    puts $sfp ""
    puts $sfp "CUSTOM"
    puts $sfp "  internal_violations = $internal_vio"
    puts $sfp "  origin_mismatches   = $origin_vio"
    puts $sfp "  switch_violations   = $switch_vio"
    puts $sfp "  switch_groups       = [dict get $switch_result groups]"
    puts $sfp "  switch_required_gap = [dict get $switch_result required_gap]"
    puts $sfp "  pgrow_violations    = $pgrow_vio"
    puts $sfp "  pgrow_r1_groups     = [dict get $pgrow multi_iso_groups]"
    puts $sfp "  pgrow_r2_groups     = [dict get $pgrow no_switch_row_groups]"
    puts $sfp ""
    puts $sfp "NATIVE"
    foreach label {Orientation JustifyBy AlignByPinName SkipSpace Overlap InsideParentBox Alignment PlaceLegality Interleaving Total} {
        puts $sfp "  $label = [dict get $native_counts $label]"
    }
    puts $sfp "  unchecked = $unchecked"
    puts $sfp ""
    puts $sfp "ERRORS"
    foreach e $errors { puts $sfp "  $e" }
    close $sfp

    return $result
}

puts "INFO: TT SDP toolbox loaded."
puts "INFO: Run TT_sdp_tools for the manual interface."
puts "INFO: Run TT_sdp_check_all for custom + native SDP verification."


# R9 repair-path status
proc TT_sdp_r9_gap_status {} {
    puts "R9 internal-gap repair status:"
    puts "  PREVIEW : TT_PR7_gap_block_preview <SDP>  (read-only)"
    puts "  REPAIR  : TT_refine_internal_gap_sdps"
    puts "  METHOD  : all unresolved CELLs -> center BLK + temp padding -> ONE place_detail/round"
    puts "            -> guarded set_sdp_origin -> restore exact padding -> custom + check_sdps"
    puts "  GUARD   : WT_L/WT_R may move with origin; CELL movement during re-anchor is UNSAFE"
    puts "  BOUND   : ::TT_PR7_GAPBLK_MAX_TRIALS rounds (default 5)"
}
# Backward-compatible aliases for scripts that learned the older status commands.
proc TT_sdp_r7_gap_status {} { return [TT_sdp_r9_gap_status] }
proc TT_sdp_r6_coordinate_status {} { return [TT_sdp_r9_gap_status] }
puts "INFO: R9 CELL-reanchor repair active; use TT_sdp_r9_gap_status."
