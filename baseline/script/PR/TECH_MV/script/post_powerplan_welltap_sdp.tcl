# =============================================================================
# post_powerplan_welltap_sdp.tcl
# V2.11 order: SDP first -> general WellTap second; nonzero SDP checks SUSPEND.
# =============================================================================

if {$::ENABLE_WELL_TAP_INSERTION && $::DEFER_WELL_TAP_TO_POST_POWERPLAN} {
    set _tech_existing_general_welltap [concat [get_db insts PD_BWT_*] [get_db insts WELLTAP_PD_*]]
    if {[llength $_tech_existing_general_welltap] != 0} {
        error "General WellTap instances already exist before post-PowerPlan SDP. Restore a pre-WellTap checkpoint before continuing."
    }
    unset _tech_existing_general_welltap
}

# 1) Finish and validate SDP first.  V7.14 does not delete SDP.
if {$::ENABLE_POST_POWERPLAN_2ROW_SDP} {
    puts "INFO: Post-PowerPlan order 1/2: run clean/fixed 2-row SDP first."
    source -quiet [file join $::TOOL_DIR 02_powerplan TT_2row_sdp_welltap_after_endcap_v6.tcl]
    # Switch padding is only a temporary legalization aid.  The SDP geometry is
    # fixed now, so release that artificial padding before the general WellTap
    # fill.  The physical switch/SDP gap remains because both sides are fixed.
    if {[llength [info commands TT_2row_sdp__clear_power_switch_padding]] > 0} {
        TT_2row_sdp__clear_power_switch_padding
    }
}

# 2) Only after SDP is clean/fixed, fill the rest of each PD with the existing
#    true-boundary + checkerboard general WellTap flow.
if {$::ENABLE_WELL_TAP_INSERTION && $::DEFER_WELL_TAP_TO_POST_POWERPLAN} {
    puts "INFO: Post-PowerPlan order 2/2: insert general PD WellTaps after SDP."
    set _tech_wt_before [llength [concat [get_db insts PD_BWT_*] [get_db insts WELLTAP_PD_*]]]
    source -quiet [file join $::SCRIPT_DIR add_well_taps.tcl]
    set _tech_wt_after [llength [concat [get_db insts PD_BWT_*] [get_db insts WELLTAP_PD_*]]]
    if {$_tech_wt_after <= $_tech_wt_before} {
        error "General WellTap insertion did not increase live PD_BWT_*/WELLTAP_PD_* count: before=$_tech_wt_before after=$_tech_wt_after."
    }
    puts "INFO: General WellTap live count: before=$_tech_wt_before after=$_tech_wt_after."
    unset _tech_wt_before
    unset _tech_wt_after
    if {[info exists ::GLOBAL_NET_FILE] && [file isfile $::GLOBAL_NET_FILE]} {
        source -quiet $::GLOBAL_NET_FILE
    }
}

if {$::ENABLE_POST_POWERPLAN_2ROW_SDP && [llength [info commands check_sdps]] > 0} {
    puts "INFO: Final post-general-WellTap check_sdps inspection checkpoint."
    if {[llength [info commands TT_2row_sdp__check_sdps_total]] > 0} {
        set _tech_final_sdp_vio [TT_2row_sdp__check_sdps_total]
        if {$_tech_final_sdp_vio != 0} {
            # Side-tap SDP finalization is already complete here, so the PR7
            # 3-member targeted re-place is intentionally NOT run/advertised.
            if {[llength [info commands gui_clear_highlight]] > 0} { catch {gui_clear_highlight -all} }
            if {[llength [info commands gui_redraw]] > 0} { catch {gui_redraw} }
            puts ""
            puts "======================================================================"
            puts " POST-GENERAL-WELLTAP SDP INSPECTION CHECKPOINT"
            puts "======================================================================"
            puts "Violations : $_tech_final_sdp_vio"
            puts "Report     : ./reports/02_powerplan/sdp/CHIP.checkSdp.rpt"
            puts "State      : inspection checkpoint only; resume always continues flow"
            puts "GUI        : old PR7 highlight cleared (3-member SDP finalization already completed)"
            puts ""
            puts "Available CHECK tools:"
            puts "  TT_2row_sdp__check_sdps_total"
            puts "  check_sdps"
            puts "  TT_2row_sdp__scan_switch_gap true"
            puts "  TT_2row_sdp__validate_switch_gap"
            puts "  write_sdp_file TT_post_general_welltap.sdp"
            puts ""
            puts "Available REPAIR tools:"
            puts "  source run/tool/02_powerplan/TT_refine_violating_sdps.tcl"
            puts "  TT_refine_violating_sdps -dry_run 1"
            puts "  NOTE: PR7 3-member internal-gap re-place is intentionally unavailable after side-tap finalization."
            puts ""
            puts "Checkpoint policy:"
            puts "  - this suspend is a ONE-TIME inspection checkpoint"
            puts "  - type 'resume' whenever you want to continue"
            puts "  - resume never loops back to this checkpoint"
            puts "  - remaining violations after resume are WARN only"
            puts "======================================================================"
            flush stdout
            if {[llength [info commands tech_mv_checkpoint_tools]]} { tech_mv_checkpoint_tools {02_powerplan} {post_powerplan_welltap_sdp} }
            suspend
            puts "INFO: Native resume received after post-general-WellTap SDP inspection."
            set _tech_final_sdp_vio [TT_2row_sdp__check_sdps_total]
            if {$_tech_final_sdp_vio != 0} {
                puts "WARN: Final post-general-WellTap check_sdps still has $_tech_final_sdp_vio violation(s); continuing flow by checkpoint policy."
            } else {
                puts "PASS: Final post-general-WellTap check_sdps is clean after resume."
            }
        } else {
            puts "PASS: Final post-general-WellTap check_sdps is clean."
        }
        unset _tech_final_sdp_vio
    } else {
        check_sdps -out_file [tech_mv_native_sdp_report_path]
    }
}

