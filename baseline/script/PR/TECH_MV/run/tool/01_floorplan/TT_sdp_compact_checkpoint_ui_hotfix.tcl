# Runtime adapter preserves the historical logical source path.
if {[info exists ::TECH_MV_RUNTIME_ROOT]} {
    info script [file join $::TECH_MV_RUNTIME_ROOT run/tool/01_floorplan/TT_sdp_compact_checkpoint_ui_hotfix.tcl]
}
# =============================================================================
# TT_sdp_compact_checkpoint_ui_hotfix.tcl
# V2.7 definition-only live-session override. Safe to source at an Innovus prompt.
# It does NOT move cells, create/delete blockages, run placement, or resume flow.
# =============================================================================

proc TT_SDP_PGROW_repair {{max_passes ""} {initial_result ""}} {
    # V2.4 operator mode:
    #   TT_SDP_PGROW_repair
    # performs scan + ONE validated global repair pass, prints only a compact
    # result, highlights unresolved CUSTOM-rule cells, and returns an empty Tcl
    # result so Innovus does NOT dump the full result dictionary to the console.
    # Internal callers that pass initial_result still receive the full dict.
    set operator_mode [expr {$max_passes eq "" && $initial_result eq ""}]

    if {$max_passes eq ""} { set max_passes 1 }
    if {![string is integer -strict $max_passes] || $max_passes < 1} {
        error "TT_SDP_PGROW_repair max_passes must be an integer >= 1."
    }

    TT_SDP_PGROW__ensure_slot_repair_tool

    if {$initial_result eq ""} {
        # Quiet scan for the public operator command.  The old verbose scan is
        # still available explicitly as TT_SDP_PGROW_scan true.
        set initial_result [TT_SDP_PGROW_scan false]
    }

    set before [dict get $initial_result violations]
    set map_fail false
    if {[dict exists $initial_result mapping_failure]} {
        set map_fail [dict get $initial_result mapping_failure]
    }

    if {$map_fail} {
        if {$operator_mode} {
            set _hl [TT_SDP_PGROW_highlight_bad $initial_result]
            puts ""
            puts "======================================================================"
            puts " PGROW REPAIR RESULT"
            puts "======================================================================"
            puts [format "%-10s %-28s : %d" {[CUSTOM]} {PGROW violations} $before]
            puts [format "%-10s %-28s : %s" {[CUSTOM]} {boundary-mapping failure} YES]
            puts "GUI       : [dict get $_hl marked] unresolved center ISO/CELL(s) highlighted"
            puts "NEXT      : inspect highlighted cells; automatic PGROW repair is disabled"
            puts "======================================================================"
            unset _hl
            return ""
        }
        return $initial_result
    }

    if {$before == 0} {
        if {$operator_mode} {
            TT_SDP_PGROW_clear_highlight
            puts ""
            puts "======================================================================"
            puts " PGROW REPAIR RESULT"
            puts "======================================================================"
            puts [format "%-10s %-28s : 0" {[CUSTOM]} {PGROW violations}]
            puts "NEXT      : resume"
            puts "======================================================================"
            return ""
        }
        return $initial_result
    }

    set r [TT_repair_powergate_iso_slots $initial_result $max_passes]

    if {$operator_mode} {
        set after [dict get $r violations]
        if {$after == 0} {
            TT_SDP_PGROW_clear_highlight
            set marked 0
        } else {
            set _hl [TT_SDP_PGROW_highlight_bad $r]
            set marked [dict get $_hl marked]
            unset _hl
        }

        puts ""
        puts "======================================================================"
        puts " PGROW REPAIR RESULT"
        puts "======================================================================"
        puts [format "%-10s %-28s : %d -> %d" {[CUSTOM]} {PGROW violations} $before $after]
        if {$after == 0} {
            puts "GUI       : clean"
            puts "NEXT      : resume"
        } else {
            puts "GUI       : $marked unresolved center ISO/CELL(s) highlighted"
            puts "NEXT      : inspect/fix highlighted cells; do not resume until acceptable"
        }
        puts "======================================================================"
        return ""
    }

    return $r
}

proc TT_SDP_PGROW_suspend_until_clean {phase {allow_auto_repair true}} {
    # Quiet authoritative scan.  Checkpoint UI below is intentionally compact.
    set r [TT_SDP_PGROW_scan false]
    if {![dict exists $r repair_rounds]} { dict set r repair_rounds 0 }
    if {![dict exists $r checkpoint_resumed]} { dict set r checkpoint_resumed false }

    if {[dict get $r violations] == 0} {
        puts "PASS: $phase PGROW custom rule is clean."
        return $r
    }

    set map_fail false
    if {[dict exists $r mapping_failure]} { set map_fail [dict get $r mapping_failure] }

    if {$allow_auto_repair && !$map_fail} {
        # Internal call receives/returns the dict; no interactive dict dump.
        set r [TT_SDP_PGROW_repair "" $r]
        if {[dict get $r violations] == 0} {
            puts "PASS: $phase PGROW custom rule is clean after one global repair."
            return $r
        }
    }

    catch {TT_2row_sdp__set_flat_members_fixed}
    catch {TT_2row_sdp__assert_flat_members_fixed}

    set _pgrow_hl [TT_SDP_PGROW_highlight_bad $r]
    set _vio [dict get $r violations]

    puts ""
    puts "======================================================================"
    puts " SDP CHECKPOINT"
    puts "======================================================================"
    puts "Phase     : $phase"
    puts "Tags      : TOOL=Innovus native rule, CUSTOM=flow/user-defined rule"
    puts [format "%-10s %-28s : %d" {[CUSTOM]} {PGROW violations} $_vio]
    if {$map_fail} {
        puts [format "%-10s %-28s : %s" {[CUSTOM]} {boundary-mapping failure} YES]
    }
    puts "GUI       : [dict get $_pgrow_hl marked] violating center ISO/CELL(s) highlighted"
    if {$map_fail} {
        puts "NEXT      : inspect highlighted cells; automatic repair is disabled"
    } elseif {$allow_auto_repair} {
        puts "NEXT      : TT_SDP_PGROW_repair"
        puts "THEN      : when PGROW violations = 0, type resume"
    } else {
        puts "NEXT      : inspect/fix highlighted CUSTOM-rule cells, then type resume"
    }
    puts "======================================================================"
    flush stdout
    if {[llength [info commands tech_mv_checkpoint_tools]]} { tech_mv_checkpoint_tools {02_powerplan} {TT_sdp_compact_checkpoint_ui_hotfix} }
    suspend

    puts "INFO: Native resume received for PGROW checkpoint '$phase'."
    unset _pgrow_hl
    unset _vio
    set r [TT_SDP_PGROW_scan false]
    dict set r checkpoint_resumed true
    if {![dict exists $r repair_rounds]} { dict set r repair_rounds 0 }

    if {[dict get $r violations] == 0} {
        TT_SDP_PGROW_clear_highlight
        puts "PASS: $phase PGROW custom rule is clean after resume."
    } else {
        set _pgrow_hl2 [TT_SDP_PGROW_highlight_bad $r]
        puts [format {WARN: [CUSTOM] PGROW violations after resume: %d (GUI highlighted=%d)} \
            [dict get $r violations] [dict get $_pgrow_hl2 marked]]
        unset _pgrow_hl2
    }
    return $r
}

proc TT_2row_sdp__suspend_until_switch_gap_clean {phase {allow_refine true}} {
    set result [TT_2row_sdp__scan_switch_gap false]
    set vio [dict get $result violations]
    set groups [dict get $result groups]
    if {$vio == 0} {
        set _native_now [TT_2row_sdp__check_sdps_total]
        if {$_native_now == 0 && [llength [info commands TT_SWKO_finalize_if_clean]] > 0} {
            TT_SWKO_finalize_if_clean
        }
        unset _native_now
        puts "PASS: $phase Power-Switch / SDP spacing is clean."
        return 0
    }

    if {$allow_refine && [llength [info commands TT_SWKO_ensure_all_switch_keepouts]] > 0} {
        TT_SWKO_ensure_all_switch_keepouts [dict get $result required_gap]
    }
    TT_2row_sdp__set_flat_members_fixed
    TT_2row_sdp__assert_flat_members_fixed

    set _pr7_result [TT_PR7_pre_checkpoint $phase $allow_refine]
    set result [TT_2row_sdp__scan_switch_gap false]
    set vio [dict get $result violations]
    set groups [dict get $result groups]
    set _pr7_vio [dict get $_pr7_result violations]

    puts ""
    puts "======================================================================"
    puts " SDP CHECKPOINT"
    puts "======================================================================"
    puts "Phase     : $phase"
    puts "Tags      : TOOL=Innovus native rule, CUSTOM=flow/user-defined rule"
    puts [format "%-10s %-28s : %d" {[CUSTOM]} {SW-gap pair violations} $vio]
    puts [format "%-10s %-28s : %d" {[CUSTOM]} {internal SDP violations} $_pr7_vio]
    puts "GUI       : CUSTOM internal-rule cells are highlighted RED when present"
    if {$allow_refine} {
        if {$vio > 0} {
            puts "NEXT      : TT_refine_switch_gap_sdps 5"
        }
        if {$_pr7_vio > 0} {
            puts "NEXT      : TT_refine_internal_gap_sdps"
        }
        puts "THEN      : when CUSTOM violations are 0, type resume"
    } else {
        puts "NEXT      : inspect/fix the reported CUSTOM-rule violations, then type resume"
    }
    puts "======================================================================"
    flush stdout
    if {[llength [info commands tech_mv_checkpoint_tools]]} { tech_mv_checkpoint_tools {02_powerplan} {TT_sdp_compact_checkpoint_ui_hotfix} }
    suspend

    puts "INFO: Native resume received for SDP / Power-Switch checkpoint '$phase'."
    if {$allow_refine && [info exists ::TT_2ROW_SDP_PRE_UNPLACED_SNAPSHOT]} {
        TT_2row_sdp__prepare_background_for_repair $::TT_2ROW_SDP_PRE_UNPLACED_SNAPSHOT "POST_RESUME_SW_GAP_$phase"
    }
    set result [TT_2row_sdp__scan_switch_gap false]
    set vio [dict get $result violations]
    if {$allow_refine} {
        set _pr7_after [TT_PR7_scan_internal_sdp_structure false false]
        set _pr7_after_vio [dict get $_pr7_after violations]
        unset _pr7_after
    } else {
        TT_PR7__clear_highlight
        set _pr7_after_vio 0
    }
    if {$vio == 0} {
        set _native_now [TT_2row_sdp__check_sdps_total]
        if {$_native_now == 0 && [llength [info commands TT_SWKO_finalize_if_clean]] > 0} {
            TT_SWKO_finalize_if_clean
        }
        unset _native_now
        puts "PASS: $phase SW-gap custom rule is clean after resume."
    } else {
        puts [format {WARN: [CUSTOM] SW-gap violations after resume: %d} $vio]
    }
    if {$_pr7_after_vio != 0} {
        puts [format {WARN: [CUSTOM] internal SDP violations after resume: %d} $_pr7_after_vio]
    }
    unset _pr7_after_vio
    unset _pr7_vio
    unset _pr7_result
    return $vio
}

proc TT_2row_sdp__suspend_until_clean {phase {allow_target_refine true}} {
    set vio [TT_2row_sdp__check_sdps_total]
    if {$vio == 0} {
        puts "PASS: $phase check_sdps is clean."
        return 0
    }

    TT_2row_sdp__set_flat_members_fixed
    TT_2row_sdp__assert_flat_members_fixed

    set _pr7_result [TT_PR7_pre_checkpoint $phase $allow_target_refine]
    set vio [TT_2row_sdp__check_sdps_total]
    set _pr7_vio [dict get $_pr7_result violations]

    puts ""
    puts "======================================================================"
    puts " SDP CHECKPOINT"
    puts "======================================================================"
    puts "Phase     : $phase"
    puts "Tags      : TOOL=Innovus native rule, CUSTOM=flow/user-defined rule"
    puts [format "%-10s %-28s : %d" {[TOOL]} {Innovus check_sdps} $vio]
    puts [format "%-10s %-28s : %d" {[CUSTOM]} {internal SDP violations} $_pr7_vio]
    puts "Report    : ./reports/02_powerplan/sdp/CHIP.checkSdp.rpt"
    puts "GUI       : CUSTOM internal-rule cells are highlighted RED when present"
    if {$allow_target_refine} {
        if {$vio > 0} {
            puts "NEXT      : source run/tool/02_powerplan/TT_refine_violating_sdps.tcl ; TT_refine_violating_sdps -apply -max_iter $::TT_2ROW_SDP_TARGET_REFINE_MAX_ITER"
        }
        if {$_pr7_vio > 0} {
            puts "NEXT      : TT_refine_internal_gap_sdps"
        }
        puts "THEN      : when TOOL/CUSTOM violations are 0, type resume"
    } else {
        puts "NEXT      : inspect ./reports/02_powerplan/sdp/CHIP.checkSdp.rpt and highlighted CUSTOM cells; repair manually, then type resume"
    }
    puts "======================================================================"
    flush stdout
    if {[llength [info commands tech_mv_checkpoint_tools]]} { tech_mv_checkpoint_tools {02_powerplan} {TT_sdp_compact_checkpoint_ui_hotfix} }
    suspend

    puts "INFO: Native resume received for SDP checkpoint '$phase'."
    if {$allow_target_refine && [info exists ::TT_2ROW_SDP_PRE_UNPLACED_SNAPSHOT]} {
        TT_2row_sdp__prepare_background_for_repair $::TT_2ROW_SDP_PRE_UNPLACED_SNAPSHOT "POST_RESUME_$phase"
    }
    set vio [TT_2row_sdp__check_sdps_total]
    if {$allow_target_refine} {
        set _pr7_after [TT_PR7_scan_internal_sdp_structure false false]
        set _pr7_after_vio [dict get $_pr7_after violations]
        unset _pr7_after
    } else {
        TT_PR7__clear_highlight
        set _pr7_after_vio 0
    }
    if {$vio == 0} {
        puts "PASS: $phase Innovus native check_sdps is clean after resume."
    } else {
        puts [format {WARN: [TOOL] Innovus check_sdps violations after resume: %d} $vio]
    }
    if {$_pr7_after_vio != 0} {
        puts [format {WARN: [CUSTOM] internal SDP violations after resume: %d} $_pr7_after_vio]
    }
    unset _pr7_after_vio
    unset _pr7_vio
    unset _pr7_result
    return $vio
}


puts "INFO: V2.7 compact checkpoint UI hotfix loaded."
puts "INFO: Direct PGROW repair: TT_SDP_PGROW_repair"
