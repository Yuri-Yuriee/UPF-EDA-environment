# Runtime adapter preserves the historical logical source path.
if {[info exists ::TECH_MV_RUNTIME_ROOT]} {
    info script [file join $::TECH_MV_RUNTIME_ROOT run/tool/02_powerplan/TT_flow_place_2row_sdp_v3_2.tcl]
} else {
    info script [file normalize [file join [file dirname [info script]] .. .. run/tool/02_powerplan/TT_flow_place_2row_sdp_v3_2.tcl]]
}
# =============================================================================
# TT_flow_place_2row_sdp_v3_2.tcl
#
# Placement-only patch for an Innovus session where the SDP creation/load step
# has already completed successfully.
#
# Confirmed creation baseline:
#   233 2-row LS/ISO SDP groups loaded
#   932 PD-aware SDP WellTaps assigned
#
# This file DOES NOT:
#   - regenerate WellTap pools
#   - delete WellTaps
#   - reread the SDP file
#   - modify SDP membership
#
# It only overrides TT_flow_place_2row_sdp.
# =============================================================================

set ::TT_2ROW_SDP_PLACE_VERSION "V3.2_PLACE_DESIGN_THEN_PLACE_SDPS"

proc TT_flow_place_2row_sdp {} {
    foreach cmd {place_design place_sdps} {
        if {[llength [info commands $cmd]] == 0} {
            error "Required Common UI command '$cmd' is unavailable."
        }
    }

    puts ""
    puts "======================================================================"
    puts " PLACE 2-ROW SDP"
    puts "======================================================================"

    puts "INFO: Stage 1/4 - place_design -sdp"
    if {[catch {place_design -sdp} err]} {
        error "place_design -sdp failed: $err"
    }

    puts "INFO: Stage 2/4 - place_sdps"
    if {[catch {place_sdps} err]} {
        error "place_sdps failed: $err"
    }

    if {[info exists ::TT_2ROW_SDP_RUN_CHECK] &&
        $::TT_2ROW_SDP_RUN_CHECK &&
        [llength [info commands check_sdps]] > 0} {
        puts "INFO: Stage 3/4 - check_sdps"
        check_sdps -out_file [tech_mv_native_sdp_report_path]
    } else {
        puts "INFO: Stage 3/4 - check_sdps skipped"
    }

    if {![info exists ::TT_2ROW_SDP_RUN_CHECK_PLACE] ||
        $::TT_2ROW_SDP_RUN_CHECK_PLACE} {
        puts "INFO: Stage 4/4 - check_place"
        check_place
    } else {
        puts "INFO: Stage 4/4 - check_place skipped"
    }

    puts "======================================================================"
    puts " SDP placement completed."
    puts "======================================================================"
}

puts "INFO: TT_flow_place_2row_sdp_v3_2.tcl loaded."
puts "INFO: PLACE VERSION = $::TT_2ROW_SDP_PLACE_VERSION"
puts "INFO: Run: TT_flow_place_2row_sdp"
