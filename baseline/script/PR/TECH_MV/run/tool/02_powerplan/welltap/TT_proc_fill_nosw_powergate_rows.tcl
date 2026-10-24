# Runtime adapter preserves the historical logical source path.
if {[info exists ::TECH_MV_RUNTIME_ROOT]} {
    info script [file join $::TECH_MV_RUNTIME_ROOT run/tool/02_powerplan/welltap/TT_proc_fill_nosw_powergate_rows.tcl]
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
# =============================================================================
# RETIRED TOOL NOTICE -- TT_NOSW_ROW_FILL_RETIRED_V2_0_20261008
# =============================================================================
# STATUS: RETIRED / DO NOT ENABLE IN THE MAIN FLOW
#
# Why retired
# -----------
# This helper was a post-Power-Switch workaround: after SW insertion/cleanup it
# detected a 2-row lane with zero surviving SW and permanently filled the lane
# with fixed FILLER cells.  Although DCAP was excluded, the approach preserves
# an unusable placement row and hides the real row-parity/topology problem.
# That can create long-term maintenance risk for WellTap/SDP/placement and makes
# the physical intent harder to reason about.
#
# Replacement
# -----------
# TT_proc_trim_powergate_bottom_row.tcl fixes the topology BEFORE EndCap/SW
# insertion.  If a switch-bearing PD rectangle has an odd number of core rows,
# the project policy is to trim the BOTTOM row.  The later SW flow therefore
# sees only paired rows and no filler-based row sealing is required.
#
# This file is intentionally preserved for history/debug reference only.
# =============================================================================

# =============================================================================
# TT_proc_fill_nosw_powergate_rows.tcl
#
# TECH_MV / Innovus Common UI
#
# Purpose
# -------
# After Stage-01 Power-Switch insertion + SW/EndCap cleanup:
#
#   * derive the REAL logical 2-row lane pairing from live Power-Switch geometry;
#   * find power-gated 2-row lane segments containing ZERO Power Switches;
#   * seal those lane segments with PURE FILLER cells only;
#   * DCAP cells are explicitly forbidden;
#   * newly created row-seal fillers are fixed.
#
# IMPORTANT
# ---------
# Power Switches are 2-row cells.  A single physical row is NOT the matching
# unit.  This tool reuses TT_sdp_powergate_row_rules.tcl's proven live-SW
# 2-row lane inference, so it preserves the checkerboard/staggered SW topology.
#
# Source behavior
# ---------------
# Definition-only. Sourcing this file does NOT modify the design.
#
# Public entry:
#   TT_NOSW_ROW_FILL_apply
# =============================================================================

set ::TT_NOSW_ROW_FILL_VERSION "V1.1_20261008"
if {![info exists ::TT_NOSW_ROW_FILL_PREFIX]} {
    set ::TT_NOSW_ROW_FILL_PREFIX "TT_NOSW_ROW_FILL"
}
if {![info exists ::TT_NOSW_ROW_FILL_SITE]} {
    set ::TT_NOSW_ROW_FILL_SITE core
}
if {![info exists ::TT_NOSW_ROW_FILL_LAST_RESULT]} {
    set ::TT_NOSW_ROW_FILL_LAST_RESULT {}
}

proc TT_NOSW_ROW_FILL__report_path {} {
    if {[info exists ::REPORT_DIR] && $::REPORT_DIR ne ""} {
        set dir [file join $::REPORT_DIR 01_floorplan]
    } else {
        set dir reports/01_floorplan
    }
    file mkdir $dir
    return [file join $dir TT_no_sw_row_filler_seal.rpt]
}

proc TT_NOSW_ROW_FILL__configured_domains {} {
    set out {}

    # Primary source: configured SW instance prefixes.
    if {[info exists ::POWER_SWITCH_INSTANCE_PREFIXES]} {
        foreach prefix $::POWER_SWITCH_INSTANCE_PREFIXES {
            if {[regexp {^(PD_.+)_SW$} $prefix -> pd]} {
                if {[lsearch -exact $out $pd] < 0} {
                    lappend out $pd
                }
            }
        }
    }

    # Exact fallback matching the active Stage-01 add_SW.tcl.
    if {[llength $out] == 0} {
        foreach pd {PD_WDT PD_CPU} {
            if {[info exists ::PD_CFG] && [dict exists $::PD_CFG $pd]} {
                lappend out $pd
            }
        }
    }

    return $out
}

proc TT_NOSW_ROW_FILL__pure_filler_cells {} {
    set loaded {}
    foreach bc [get_db base_cells] {
        set n ""
        catch {set n [get_db $bc .name]}
        if {$n ne ""} {
            dict set loaded $n 1
        }
    }

    set candidates {}
    if {[info exists ::FILLER_CELLS]} {
        set candidates $::FILLER_CELLS
    } else {
        set candidates [dict keys $loaded]
    }

    set out {}
    foreach n $candidates {
        # Hard policy:
        #   - PURE FILL only
        #   - explicitly reject DCAP
        #   - use standard configured library cell filler family (no LVT/ULVT variants)
        if {[string match [::tech_mv_library_value LIB_MATCH_002] $n]} { continue }
        if {![regexp [::tech_mv_library_value PURE_FILLER_MASTER_PATTERN] $n]} { continue }
        if {![dict exists $loaded $n]} { continue }
        if {[lsearch -exact $out $n] < 0} {
            lappend out $n
        }
    }

    if {[llength $out] == 0} {
        error "NO-SW ROW FILL: no loaded configured pure filler-family cells were found."
    }

    return $out
}

proc TT_NOSW_ROW_FILL__rect_x_overlap {a b} {
    if {[llength $a] != 4 || [llength $b] != 4} { return false }
    lassign $a ax1 ay1 ax2 ay2
    lassign $b bx1 by1 bx2 by2
    return [expr {double($ax1) < double($bx2) && double($ax2) > double($bx1)}]
}

proc TT_NOSW_ROW_FILL__lane_segment_has_switch {pd lane_rec} {
    lassign $lane_rec lane_key clip lane_rect low_key high_key low_rr high_rr

    foreach rec [TT_SDP_PGROW__switch_records_for_pd $pd] {
        lassign $rec sx1 sy1 sx2 sy2 sname sw
        set sb [list $sx1 $sy1 $sx2 $sy2]

        # A valid SW for this logical lane must overlap BOTH physical rows.
        if {![TT_SDP_PGROW__y_overlap $low_rr $sb]} { continue }
        if {![TT_SDP_PGROW__y_overlap $high_rr $sb]} { continue }

        # And it must belong to THIS X clip/segment of the PD.
        if {![TT_NOSW_ROW_FILL__rect_x_overlap $clip $sb]} { continue }

        return true
    }

    return false
}

proc TT_NOSW_ROW_FILL__discover_nosw_lane_segments {} {
    set pgrow_tool [file join $::TOOL_DIR 02_powerplan TT_sdp_powergate_row_rules.tcl]
    if {![file isfile $pgrow_tool]} {
        error "NO-SW ROW FILL: required lane-model tool not found: $pgrow_tool"
    }

    # Definition-only dependency.
    uplevel #0 [list source -quiet $pgrow_tool]

    if {![info exists ::TT_2ROW_SDP_SITE]} {
        set ::TT_2ROW_SDP_SITE $::TT_NOSW_ROW_FILL_SITE
    }

    # SW cleanup has just run, therefore force all geometry caches fresh.
    set ::TT_SDP_PGROW_SWITCH_CACHE_READY 0
    set ::TT_SDP_PGROW_ROW_CACHE_READY 0
    set ::TT_SDP_PGROW_LANE_CACHE_READY 0
    set ::TT_SDP_PGROW_SWITCH_CACHE {}
    set ::TT_SDP_PGROW_SWITCH_PD_CACHE [dict create]
    set ::TT_SDP_PGROW_SWITCH_REC_CACHE [dict create]
    set ::TT_SDP_PGROW_ROW_CACHE [dict create]
    set ::TT_SDP_PGROW_LANE_CACHE [dict create]
    set ::TT_SDP_PGROW_LANE_SW_CACHE [dict create]

    TT_SDP_PGROW__refresh_switch_cache

    set domains [TT_NOSW_ROW_FILL__configured_domains]
    if {[llength $domains] == 0} {
        error "NO-SW ROW FILL: no configured power-gated domain could be resolved."
    }

    set missing {}
    foreach pd $domains {
        set sws [TT_SDP_PGROW__switches_for_pd $pd]
        if {[llength $sws] == 0} {
            # Fail closed: with zero live SW in the entire PD there is no safe
            # geometry evidence from which to infer the P-G-P 2-row parity.
            error "NO-SW ROW FILL: '$pd' has ZERO live Power Switches after cleanup; cannot safely infer 2-row rail parity."
        }

        set rows [TT_SDP_PGROW__pd_row_records $pd]
        set built [TT_SDP_PGROW__build_two_row_lanes_from_records \
            $pd $rows [TT_SDP_PGROW__switch_records_for_pd $pd]]

        set lanes [dict get $built lanes]
        puts "INFO: NO-SW ROW FILL pd=$pd parity=[dict get $built parity] laneSegments=[llength $lanes]"

        foreach lane_rec $lanes {
            if {[TT_NOSW_ROW_FILL__lane_segment_has_switch $pd $lane_rec]} {
                continue
            }
            lassign $lane_rec lane_key clip lane_rect low_key high_key low_rr high_rr
            lappend missing [dict create \
                pd $pd \
                lane_key $lane_key \
                clip $clip \
                low_row $low_rr \
                high_row $high_rr]
        }
    }

    return $missing
}

proc TT_NOSW_ROW_FILL__count_prefix {} {
    return [llength [get_db insts ${::TT_NOSW_ROW_FILL_PREFIX}*]]
}

proc TT_NOSW_ROW_FILL__assert_no_decap_prefix {} {
    set bad {}
    foreach inst [get_db insts ${::TT_NOSW_ROW_FILL_PREFIX}*] {
        set master ""
        catch {set master [get_db $inst .base_cell.name]}
        if {[string match [::tech_mv_library_value LIB_MATCH_002] $master]} {
            lappend bad [list [get_db $inst .name] $master]
        }
    }

    if {[llength $bad] > 0} {
        foreach x $bad {
            puts "ERROR: NO-SW ROW FILL created/contains forbidden DCAP: $x"
        }
        error "NO-SW ROW FILL: forbidden DCAP detected under owned prefix."
    }
}

proc TT_NOSW_ROW_FILL_apply {} {
    set report [TT_NOSW_ROW_FILL__report_path]
    set fillers [TT_NOSW_ROW_FILL__pure_filler_cells]
    set missing [TT_NOSW_ROW_FILL__discover_nosw_lane_segments]

    set fp [open $report w]
    puts $fp "======================================================================"
    puts $fp " NO-SW POWER-GATED 2-ROW LANE FILLER SEAL"
    puts $fp "======================================================================"
    puts $fp "Version              : $::TT_NOSW_ROW_FILL_VERSION"
    puts $fp "Owned prefix         : $::TT_NOSW_ROW_FILL_PREFIX"
    puts $fp "Pure filler cells    : $fillers"
    puts $fp "DCAP policy          : FORBIDDEN"
    puts $fp "Missing SW segments  : [llength $missing]"
    puts $fp ""

    puts ""
    puts "======================================================================"
    puts " NO-SW POWER-GATED 2-ROW LANE FILLER SEAL"
    puts "======================================================================"
    puts "Pure filler cells   : $fillers"
    puts [::tech_mv_library_value LIB_TEXT_001]
    puts "No-SW lane segments : [llength $missing]"
    puts "Report              : $report"
    puts "======================================================================"

    if {[llength $missing] == 0} {
        puts $fp "PASS: every discovered logical 2-row lane segment contains at least one Power Switch."
        close $fp
        set ::TT_NOSW_ROW_FILL_LAST_RESULT [dict create \
            missing_segments 0 \
            fillers_before [TT_NOSW_ROW_FILL__count_prefix] \
            fillers_after [TT_NOSW_ROW_FILL__count_prefix] \
            added_fillers 0 \
            report $report]
        puts "PASS: Every discovered power-gated 2-row lane segment has a Power Switch."
        return 0
    }

    # Save current filler-related root settings that this helper touches.
    set saved [dict create]
    foreach attr {
        add_fillers_cells
        add_fillers_preserve_user_order
        add_fillers_no_single_site_gap
        add_fillers_with_drc
    } {
        set ok 0
        set v ""
        if {![catch {set v [get_db $attr]}]} {
            set ok 1
        }
        dict set saved $attr [list $ok $v]
    }

    set before [TT_NOSW_ROW_FILL__count_prefix]

    # Hard safety: only PURE FILL cells are offered to add_fillers.
    set_db add_fillers_cells $fillers
    set_db add_fillers_preserve_user_order true
    set_db add_fillers_no_single_site_gap false
    set_db add_fillers_with_drc true

    set idx 0
    foreach rec $missing {
        incr idx
        set pd [dict get $rec pd]
        set lane_key [dict get $rec lane_key]
        set clip [dict get $rec clip]

        puts [format "INFO: NO-SW ROW FILL %d/%d pd=%s lane=%s area=%s" $idx [llength $missing] $pd $lane_key $clip]
        puts $fp "SEAL pd=$pd lane=$lane_key area=$clip"

        # add_fillers -area is intentionally used so ONLY this no-SW logical
        # lane segment is occupied.  EndCaps/blockages already present inside
        # the area are honored by Innovus; only remaining legal sites are filled.
        add_fillers \
            -base_cells $fillers \
            -prefix $::TT_NOSW_ROW_FILL_PREFIX \
            -area $clip
    }

    # Restore caller's filler settings before any validation/checkpoint.
    dict for {attr payload} $saved {
        lassign $payload ok v
        if {$ok} {
            catch {set_db $attr $v}
        }
    }

    set owned [get_db insts ${::TT_NOSW_ROW_FILL_PREFIX}*]
    if {[llength $owned] > 0} {
        # The purpose of this early filler is to permanently seal no-SW lanes
        # against later functional placement.
        set_db $owned .place_status fixed
    }

    TT_NOSW_ROW_FILL__assert_no_decap_prefix

    set after [TT_NOSW_ROW_FILL__count_prefix]
    set added [expr {$after - $before}]
    if {$added < 0} { set added 0 }

    puts $fp ""
    puts $fp "Owned fillers before : $before"
    puts $fp "Owned fillers after  : $after"
    puts $fp "New fillers added    : $added"
    puts $fp "Placement status     : fixed"
    puts $fp "STATUS               : PASS"
    close $fp

    set ::TT_NOSW_ROW_FILL_LAST_RESULT [dict create \
        missing_segments [llength $missing] \
        fillers_before $before \
        fillers_after $after \
        added_fillers $added \
        report $report]

    puts ""
    puts "======================================================================"
    puts " NO-SW ROW FILLER SEAL SUMMARY"
    puts "======================================================================"
    puts "No-SW lane segments : [llength $missing]"
    puts "Owned fillers before: $before"
    puts "Owned fillers after : $after"
    puts "New fillers added   : $added"
    puts [::tech_mv_library_value LIB_TEXT_002]
    puts "Placement status    : fixed"
    puts "Report              : $report"
    puts "======================================================================"

    return [llength $missing]
}

puts "INFO: Loaded TT_proc_fill_nosw_powergate_rows.tcl - $::TT_NOSW_ROW_FILL_VERSION"


# =============================================================================
# TT_NOSW_ROW_FILL_RETIRED_V2_0_20261008 -- hard retirement guard
# =============================================================================
# Preserve the original implementation under a legacy name for forensic/debug
# inspection, but make the public entry fail closed if somebody calls it.
if {[llength [info commands TT_NOSW_ROW_FILL_apply_RETIRED_IMPL]] == 0} {
    if {[llength [info commands TT_NOSW_ROW_FILL_apply]] > 0} {
        rename TT_NOSW_ROW_FILL_apply TT_NOSW_ROW_FILL_apply_RETIRED_IMPL
    }
} else {
    # Re-source case: discard the just-redefined public implementation before
    # reinstalling the retirement wrapper.
    if {[llength [info commands TT_NOSW_ROW_FILL_apply]] > 0} {
        rename TT_NOSW_ROW_FILL_apply {}
    }
}
proc TT_NOSW_ROW_FILL_apply {args} {
    error "TT_NOSW_ROW_FILL_apply is RETIRED. Use pre-EndCap TT_SWROW_trim_bottom from TT_proc_trim_powergate_bottom_row.tcl. Reason: fix row topology before SW insertion; do not seal no-SW rows with fixed fillers."
}
set ::TT_NOSW_ROW_FILL_RETIRED true
puts "WARNING: TT_proc_fill_nosw_powergate_rows.tcl is RETIRED; public apply is disabled."
