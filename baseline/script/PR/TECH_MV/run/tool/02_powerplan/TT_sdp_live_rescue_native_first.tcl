# Runtime adapter preserves the historical logical source path.
if {[info exists ::TECH_MV_RUNTIME_ROOT]} {
    info script [file join $::TECH_MV_RUNTIME_ROOT run/tool/02_powerplan/TT_sdp_live_rescue_native_first.tcl]
}
# PUBLIC_EXPORT_REVIEW_REQUIRED: residual technology candidates require manual review.
# Load private values before evaluating original parameter defaults.
if {![llength [info commands ::tech_mv_private_value]]} { source [file join $::TECH_MV_RUNTIME_ROOT .. script PR TECH_MV script 00_common private_parameter_config.tcl] }
# =============================================================================
# TT_sdp_live_rescue_native_first.tcl
# TECH_MV / live Innovus rescue tool
#
# PURPOSE
#   Repair the CURRENT Innovus DB without pp_restore / rerunning SDP flow.
#
# ORDER (hard policy)
#   0. Remove repair-owned temporary BLKs.
#   1. Remove custom PGROW no-SW BLKs temporarily so they cannot block native repair.
#   2. Native check_sdps repair FIRST (Overlap / PlaceLegality / Interleaving / ...).
#   4. Internal GAP-ONLY repair (WT_L<->CELL and CELL<->WT_R, within configured physical gap limits).
#   4. Rebuild PGROW no-SW BLKs using the currently installed V2.0 logical 2-row lanes.
#   5. Preview/explain custom PGROW issues.
#   6. Custom PGROW repair only by explicit command, and only if native+gap are clean.
#
# SOURCE SIDE EFFECT
#   By default source immediately removes ONLY repair-owned BLKs:
#     TT_SDP_PGISO_RESERVE_*
#     TT_SDP_PGISO_MOVE_*
#     TT_PR7_GAPBLK_*
#   It NEVER removes TT_SDP_SWKO_* on source.
#   It does NOT remove TT_SDP_PGROW_NOSW_* until native-first repair is requested.
# =============================================================================

set ::TT_SDP_RESCUE_VERSION "V1.4_1_ENDCAP_COMMONUI_CACHE_FIX"

# Direct 2-row geometry policy.
# A same-lane SW must vertically cover at least this fraction of the 2-row ISO.
# Checkerboard-neighbor SWs that overlap only one of the two physical rows are
# therefore excluded.
# One logical unit contains TWO physical rows.  A checkerboard SW/ENDCAP
# boundary belongs to this unit when it overlaps at least ONE of those rows.
# FORCE this value on every source: older live-rescue versions used 0.75 and
# Tcl globals survive re-source in the same Innovus session.
set ::TT_SDP_RESCUE_SW_Y_COVER_FRACTION 0.50
if {![info exists ::TT_SDP_RESCUE_GEOM_TOL]} {
    set ::TT_SDP_RESCUE_GEOM_TOL [::tech_mv_private_value {run/tool/02_powerplan/TT_sdp_live_rescue_native_first.tcl::::TT_SDP_RESCUE_GEOM_TOL::L38}]
}

# Common-UI-safe ENDCAP recognition.
# Do NOT query unsupported end-cap boolean attributes in this Innovus schema.
if {![info exists ::TT_SDP_RESCUE_ENDCAP_INST_PATTERNS]} {
    set ::TT_SDP_RESCUE_ENDCAP_INST_PATTERNS {
        ENDCAP_PD_*
        *ENDCAP*
    }
}
if {![info exists ::TT_SDP_RESCUE_ENDCAP_MASTER_PATTERNS]} {
    set ::TT_SDP_RESCUE_ENDCAP_MASTER_PATTERNS {
        *ENDCAP*
    }
}
set ::TT_SDP_RESCUE_ENDCAP_CACHE_READY 0
set ::TT_SDP_RESCUE_ENDCAP_PD_CACHE [dict create]
set ::TT_SDP_RESCUE_TOOL_DIR [file dirname [info script]]
if {![info exists ::TT_SDP_RESCUE_AUTO_CLEAR_REPAIR_BLKS]} {
    set ::TT_SDP_RESCUE_AUTO_CLEAR_REPAIR_BLKS true
}
if {![info exists ::TT_SDP_RESCUE_NATIVE_MAX_ITER]} {
    set ::TT_SDP_RESCUE_NATIVE_MAX_ITER 3
}

proc TT_SDP_RESCUE__bool {v} {
    set s [string tolower [string trim $v]]
    return [expr {$s in {1 true yes on enable enabled}}]
}

proc TT_SDP_RESCUE__delete_prefixes {prefixes} {
    set deleted 0
    set failed {}
    set names {}
    foreach pb [get_db place_blockages] {
        set n ""
        catch {set n [get_db $pb .name]}
        if {$n eq ""} { continue }
        set hit false
        foreach p $prefixes {
            if {[string match "${p}*" $n]} { set hit true; break }
        }
        if {!$hit} { continue }
        if {[catch {delete_obj $pb} err]} {
            lappend failed [list $n $err]
        } else {
            incr deleted
            lappend names $n
        }
    }
    return [dict create deleted $deleted failed $failed names $names]
}

proc TT_SDP_RESCUE__count_prefix {prefix} {
    set n 0
    foreach pb [get_db place_blockages] {
        set name ""
        catch {set name [get_db $pb .name]}
        if {$name ne "" && [string match "${prefix}*" $name]} { incr n }
    }
    return $n
}

proc TT_SDP_RESCUE_blk_report {{max_names 12}} {
    puts ""
    puts "======================================================================"
    puts " TT SDP LIVE RESCUE / OWNED BLOCKAGE REPORT"
    puts "======================================================================"
    foreach p {
        TT_SDP_PGISO_RESERVE_
        TT_SDP_PGISO_MOVE_
        TT_PR7_GAPBLK_
        TT_SDP_PGROW_NOSW_
        TT_SDP_SWKO_
    } {
        set count 0
        set shown 0
        set examples {}
        foreach pb [get_db place_blockages] {
            set n ""
            catch {set n [get_db $pb .name]}
            if {$n eq "" || ![string match "${p}*" $n]} { continue }
            incr count
            if {$shown < $max_names} {
                set typ ""
                set rects ""
                catch {set typ [get_db $pb .type]}
                catch {set rects [get_db $pb .rects]}
                if {$rects eq ""} { catch {set rects [get_db $pb .bbox]} }
                lappend examples [list $n $typ $rects]
                incr shown
            }
        }
        puts [format "%-26s count=%d" "${p}*" $count]
        foreach e $examples {
            lassign $e n typ rects
            puts "    $n type=$typ rects={$rects}"
        }
        if {$count > $shown} { puts "    ... [expr {$count-$shown}] more" }
    }
    puts "======================================================================"
}

# -----------------------------------------------------------------------------
# Step 0: remove ONLY temporary repair-owned BLKs.
# -----------------------------------------------------------------------------
proc TT_SDP_RESCUE_clear_repair_blks {} {
    set prefixes {TT_SDP_PGISO_RESERVE_ TT_SDP_PGISO_MOVE_ TT_PR7_GAPBLK_}
    set r [TT_SDP_RESCUE__delete_prefixes $prefixes]
    puts ""
    puts "======================================================================"
    puts " TT SDP LIVE RESCUE / CLEAR REPAIR BLKS"
    puts "======================================================================"
    puts "Deleted repair BLKs : [dict get $r deleted]"
    puts "Delete failures     : [llength [dict get $r failed]]"
    puts "Protected           : TT_SDP_SWKO_*"
    puts "Not touched yet     : TT_SDP_PGROW_NOSW_*"
    if {[llength [dict get $r failed]] > 0} {
        foreach x [dict get $r failed] { puts "WARN: delete failed: $x" }
    }
    puts "======================================================================"
    return $r
}

# Custom PGROW constraints must not block native-SDP recovery.
proc TT_SDP_RESCUE_clear_custom_nosw_blks {} {
    set r [TT_SDP_RESCUE__delete_prefixes {TT_SDP_PGROW_NOSW_}]
    puts "INFO: removed custom PGROW no-SW BLKs before native repair: deleted=[dict get $r deleted] failed=[llength [dict get $r failed]]"
    return $r
}

# -----------------------------------------------------------------------------
# Gap-only wrapper.
# Keep the old public proc name so all existing R9 callers remain compatible.
# The original implementation stays available for rollback/debug.
# -----------------------------------------------------------------------------
proc TT_SDP_RESCUE_enable_gap_only_checker {} {
    if {[llength [info commands TT_PR7_scan_internal_sdp_structure__TT_RESCUE_FULL]] == 0} {
        if {[llength [info commands TT_PR7_scan_internal_sdp_structure]] == 0} {
            error "TT_PR7_scan_internal_sdp_structure is not loaded; source TT_refine_internal_gap_sdps.tcl first."
        }
        rename TT_PR7_scan_internal_sdp_structure TT_PR7_scan_internal_sdp_structure__TT_RESCUE_FULL
    } elseif {[llength [info commands TT_PR7_scan_internal_sdp_structure]] > 0} {
        # Remove an older rescue wrapper before redefining it.
        rename TT_PR7_scan_internal_sdp_structure {}
    }

    proc TT_PR7_scan_internal_sdp_structure {{verbose true} {highlight true} {only_groups ""}} {
        # Suppress the legacy checker output; this wrapper prints GAP-only data.
        set full [TT_PR7_scan_internal_sdp_structure__TT_RESCUE_FULL false false $only_groups]
        set out $full
        set details {}
        set groups {}

        if {[dict exists $full details]} {
            foreach d [dict get $full details] {
                if {![dict exists $d issues]} { continue }
                set keep_issues {}
                foreach issue [dict get $d issues] {
                    if {$issue eq "left_gap" || $issue eq "right_gap"} {
                        lappend keep_issues $issue
                    }
                }
                if {[llength $keep_issues] == 0} { continue }
                dict set d issues $keep_issues
                lappend details $d
                if {[dict exists $d group]} { lappend groups [dict get $d group] }
            }
        }

        set groups [lsort -dictionary -unique $groups]
        dict set out details $details
        dict set out groups $groups
        dict set out violations [llength $groups]
        if {[dict exists $out repairable]} { dict set out repairable [llength $groups] }

        if {$verbose} {
            puts ""
            puts "======================================================================"
            puts " PR7 INTERNAL GAP-ONLY CHECK"
            puts "======================================================================"
            foreach d $details {
                set g "UNKNOWN"
                set gl "NA"
                set gr "NA"
                set issues {}
                if {[dict exists $d group]} { set g [dict get $d group] }
                if {[dict exists $d gap_l]} { set gl [dict get $d gap_l] }
                if {[dict exists $d gap_r]} { set gr [dict get $d gap_r] }
                if {[dict exists $d issues]} { set issues [dict get $d issues] }
                puts "PR7_GAP_VIOLATION group=$g gap_l=$gl gap_r=$gr issues={$issues}"
            }
            set maxgap "UNKNOWN"
            if {[info exists ::TT_PR7_INTERNAL_GAP_MAX_UM]} { set maxgap $::TT_PR7_INTERNAL_GAP_MAX_UM }
            set checked "UNKNOWN"
            if {[dict exists $out checked]} { set checked [dict get $out checked] }
            puts "INFO: PR7 GAP-ONLY: checked=$checked violations=[llength $groups] allowed_gap=0..${maxgap}um"
            puts "INFO: membership/order/overlap/foreign/place legality are NOT counted here; native check_sdps is authority."
            puts "======================================================================"
        }

        # GUI highlighting is intentionally not duplicated here. Native
        # check_sdps and the dedicated PGROW diagnostics remain the visual tools.
        return $out
    }

    puts "INFO: TT_PR7_scan_internal_sdp_structure is now GAP-ONLY (left_gap/right_gap only)."
    return true
}

proc TT_SDP_RESCUE_restore_full_internal_checker {} {
    if {[llength [info commands TT_PR7_scan_internal_sdp_structure__TT_RESCUE_FULL]] == 0} {
        puts "INFO: no saved full checker to restore."
        return false
    }
    if {[llength [info commands TT_PR7_scan_internal_sdp_structure]] > 0} {
        rename TT_PR7_scan_internal_sdp_structure {}
    }
    rename TT_PR7_scan_internal_sdp_structure__TT_RESCUE_FULL TT_PR7_scan_internal_sdp_structure
    puts "INFO: restored original full TT_PR7_scan_internal_sdp_structure."
    return true
}

proc TT_SDP_RESCUE__source_if_needed {cmd filename} {
    if {[llength [info commands $cmd]] > 0} { return true }
    set f [file join $::TT_SDP_RESCUE_TOOL_DIR $filename]
    if {![file isfile $f]} { return false }
    source $f
    return [expr {[llength [info commands $cmd]] > 0}]
}

# Reload current on-disk PGROW/PGISO code into THIS session without restoring DB.
proc TT_SDP_RESCUE_reload_custom_tools {} {
    foreach f {TT_sdp_powergate_row_rules.tcl TT_repair_powergate_iso_slots.tcl} {
        set p [file join $::TT_SDP_RESCUE_TOOL_DIR $f]
        if {[file isfile $p]} {
            puts "INFO: live-reloading $p"
            source $p
        } else {
            puts "WARN: live tool file not found: $p"
        }
    }
    return true
}

proc TT_SDP_RESCUE__native_total {} {
    if {[llength [info commands TT_2row_sdp__check_sdps_total]] == 0} {
        error "TT_2row_sdp__check_sdps_total is unavailable."
    }
    return [TT_2row_sdp__check_sdps_total]
}

proc TT_SDP_RESCUE__gap_scan {{verbose true}} {
    if {[llength [info commands TT_PR7_scan_internal_sdp_structure]] == 0} {
        error "gap checker unavailable"
    }
    return [TT_PR7_scan_internal_sdp_structure $verbose false]
}

# -----------------------------------------------------------------------------
# Native-first recovery.
# This intentionally STOPS before custom PGROW movement. It leaves a clean,
# inspectable checkpoint and a rebuilt V2.0 2-row-lane no-SW constraint map.
# -----------------------------------------------------------------------------
proc TT_SDP_RESCUE_native_first {{native_max_iter ""}} {
    if {$native_max_iter eq ""} { set native_max_iter $::TT_SDP_RESCUE_NATIVE_MAX_ITER }
    if {![string is integer -strict $native_max_iter] || $native_max_iter < 1} {
        error "native_max_iter must be integer >=1"
    }

    puts ""
    puts "======================================================================"
    puts " TT SDP LIVE RESCUE / NATIVE FIRST"
    puts "======================================================================"
    puts "Order: clear repair BLKs -> native -> GAP-only -> rebuild 2R PGROW BLKs -> preview custom"
    puts "No pp_restore / no full-flow rerun."
    puts "======================================================================"

    # Always start from unpolluted repair space.
    TT_SDP_RESCUE_clear_repair_blks

    # Custom R2 blockage is intentionally removed during native/gap repair.
    # SW four-side keep-outs stay active.
    TT_SDP_RESCUE_clear_custom_nosw_blks

    # Make sure gap repair helper exists BEFORE installing the GAP-only wrapper.
    if {![TT_SDP_RESCUE__source_if_needed TT_refine_internal_gap_sdps TT_refine_internal_gap_sdps.tcl]} {
        error "TT_refine_internal_gap_sdps unavailable; expected [file join $::TT_SDP_RESCUE_TOOL_DIR TT_refine_internal_gap_sdps.tcl]"
    }
    TT_SDP_RESCUE_enable_gap_only_checker

    # ---------------- Native FIRST ----------------
    set native0 [TT_SDP_RESCUE__native_total]
    puts "INFO: NATIVE-FIRST initial check_sdps total=$native0"
    if {$native0 != 0} {
        if {![TT_SDP_RESCUE__source_if_needed TT_refine_violating_sdps TT_refine_violating_sdps.tcl]} {
            error "Native violations=$native0 but TT_refine_violating_sdps is unavailable. Source/install TT_refine_violating_sdps.tcl and retry."
        }
        puts "INFO: NATIVE-FIRST applying existing native repair loop: TT_refine_violating_sdps -apply -max_iter $native_max_iter"
        if {[catch {TT_refine_violating_sdps -apply -max_iter $native_max_iter} nerr]} {
            puts "ERROR: native repair command failed: $nerr"
            return [dict create ok false stage native_repair_error native_initial $native0 error $nerr]
        }
    }

    set native1 [TT_SDP_RESCUE__native_total]
    puts "INFO: NATIVE-FIRST post-native check_sdps total=$native1"
    if {$native1 != 0} {
        puts "WARN: native violations remain; STOPPING before GAP/PGROW custom repair."
        TT_SDP_RESCUE_clear_repair_blks
        return [dict create ok false stage native_remaining native_initial $native0 native_final $native1]
    }

    # ---------------- GAP only SECOND ----------------
    set gap0 [TT_SDP_RESCUE__gap_scan true]
    set gap_v0 [dict get $gap0 violations]
    puts "INFO: GAP-ONLY initial violations=$gap_v0"
    if {$gap_v0 != 0} {
        puts "INFO: GAP-ONLY invoking existing R9 gap mover only after native is clean."
        if {[catch {TT_refine_internal_gap_sdps} gerr]} {
            puts "ERROR: GAP-only repair failed: $gerr"
            TT_SDP_RESCUE_clear_repair_blks
            return [dict create ok false stage gap_repair_error native_final $native1 gap_initial $gap_v0 error $gerr]
        }
    }

    set native2 [TT_SDP_RESCUE__native_total]
    set gap1 [TT_SDP_RESCUE__gap_scan true]
    set gap_v1 [dict get $gap1 violations]
    puts "INFO: GAP-ONLY post-repair: gap=$gap_v1 native=$native2"
    if {$native2 != 0 || $gap_v1 != 0} {
        puts "WARN: native/gap not simultaneously clean; STOPPING before custom PGROW repair."
        TT_SDP_RESCUE_clear_repair_blks
        return [dict create ok false stage native_gap_remaining native_final $native2 gap_final $gap_v1]
    }

    # ---------------- Custom constraints LAST ----------------
    TT_SDP_RESCUE_reload_custom_tools
    # Re-install GAP-only wrapper in case a sourced dependency redefined it.
    if {[llength [info commands TT_PR7_scan_internal_sdp_structure__TT_RESCUE_FULL]] > 0} {
        TT_SDP_RESCUE_enable_gap_only_checker
    }

    if {![info exists ::TT_SDP_PGROW_VERSION] ||
        ![string match "V2.0_LOGICAL_2ROW_LANE_CHECKERBOARD*" $::TT_SDP_PGROW_VERSION]} {
        puts "ERROR: current PGROW version is not V2.0 logical-2-row-lane: [expr {[info exists ::TT_SDP_PGROW_VERSION] ? $::TT_SDP_PGROW_VERSION : "UNSET"}]"
        puts "ERROR: refusing to rebuild/custom-repair with the old single-row algorithm."
        return [dict create ok false stage pgrow_version_guard native_final $native2 gap_final $gap_v1]
    }

    # Force the NEW lane cache to be reconstructed by the V2.0 code.
    set ::TT_SDP_PGROW_LANE_CACHE_READY 0
    set ::TT_SDP_PGROW_LANE_CACHE [dict create]
    set ::TT_SDP_PGROW_LANE_SW_CACHE [dict create]

    set rb [TT_SDP_PGROW_prepare_blockages]
    puts "INFO: rebuilt V2.0 no-SW 2-row-lane BLKs: [dict get $rb created] domains={[dict get $rb domains]}"

    set scan [TT_SDP_PGROW_scan true]
    puts "INFO: CUSTOM PGROW preview only: violations=[dict get $scan violations]"
    puts "INFO: Native+gap are clean. Custom movement has NOT been applied yet."
    puts "INFO: Inspect with: TT_SDP_RESCUE_explain_bad 30"
    puts "INFO: Then apply custom repair with: TT_SDP_RESCUE_apply_custom"

    return [dict create ok true stage custom_preview native_final $native2 gap_final $gap_v1 pgrow_scan $scan]
}



# -----------------------------------------------------------------------------
# DIRECT 2-ROW / POWER-SWITCH GEOMETRY CHECK
#
# This intentionally does NOT use the V2.0 global lane-parity mapper.
#
# Rule:
#   1) The canonical ISO bbox itself defines the logical 2-row lane Y-span.
#   2) One logical unit is exactly TWO physical rows.  A checkerboard Power
#      Switch belongs to this unit when its bbox overlaps at least ONE complete
#      physical row of the ISO's two-row height.  Therefore the minimum Y
#      overlap is 1/2 of the ISO height.
#
#      IMPORTANT: requiring >1 row of overlap is WRONG for this checkerboard
#      placement because legal SWs may be staggered by one physical row.
#   3) Same-lane slot boundaries may be either Power Switches or ENDCAPs.
#      ENDCAP is treated exactly like SW for left/right interval boundaries.
#   4) A legal slot requires BOTH a nearest-left and nearest-right same-lane
#      boundary.  Valid pairs are SW-SW, ENDCAP-SW, SW-ENDCAP, ENDCAP-ENDCAP.
#   5) At most one canonical ISO may occupy one such same-2-row-unit slot.
#   6) No automatic "edge is legal" shortcut exists anymore.
# -----------------------------------------------------------------------------

proc TT_SDP_RESCUE__y_overlap_amount {a b} {
    if {[llength $a] != 4 || [llength $b] != 4} { return 0.0 }
    lassign $a ax1 ay1 ax2 ay2
    lassign $b bx1 by1 bx2 by2
    set h [expr {min(double($ay2),double($by2))-max(double($ay1),double($by1))}]
    if {$h <= $::TT_SDP_RESCUE_GEOM_TOL} { return 0.0 }
    return $h
}


proc TT_SDP_RESCUE__matches_any_nocase {value patterns} {
    foreach pat $patterns {
        if {[string match -nocase $pat $value]} { return true }
    }
    return false
}

proc TT_SDP_RESCUE__is_endcap_inst {inst} {
    if {$inst eq ""} { return false }

    # Common-UI-safe fields only.
    set name ""
    set master ""
    catch {set name [get_db $inst .name]}
    catch {set master [get_db $inst .base_cell.name]}

    if {[TT_SDP_RESCUE__matches_any_nocase \
            $name $::TT_SDP_RESCUE_ENDCAP_INST_PATTERNS]} {
        return true
    }
    if {[TT_SDP_RESCUE__matches_any_nocase \
            $master $::TT_SDP_RESCUE_ENDCAP_MASTER_PATTERNS]} {
        return true
    }
    return false
}

proc TT_SDP_RESCUE__refresh_endcap_cache {} {
    set c [dict create]
    set total 0
    set scanned 0

    foreach inst [get_db insts] {
        incr scanned
        if {![TT_SDP_RESCUE__is_endcap_inst $inst]} { continue }

        set pd ""
        catch {set pd [get_db $inst .power_domain.name]}
        if {$pd eq ""} { continue }

        set b ""
        catch {set b [TT_SDP_PGROW__rect4 [get_db $inst .bbox]]}
        if {[llength $b] != 4} { continue }

        set n ""
        catch {set n [get_db $inst .name]}
        lassign $b x1 y1 x2 y2

        dict lappend c $pd [list $x1 $x2 $y1 $y2 $n $inst ENDCAP]
        incr total
    }

    set ::TT_SDP_RESCUE_ENDCAP_PD_CACHE $c
    set ::TT_SDP_RESCUE_ENDCAP_CACHE_READY 1

    puts "INFO: TT SDP rescue ENDCAP cache built once: scanned=$scanned endcaps=$total PDs={[lsort -dictionary [dict keys $c]]}"
    return $total
}

proc TT_SDP_RESCUE__endcaps_for_pd {pd} {
    if {!$::TT_SDP_RESCUE_ENDCAP_CACHE_READY} {
        TT_SDP_RESCUE__refresh_endcap_cache
    }
    if {![dict exists $::TT_SDP_RESCUE_ENDCAP_PD_CACHE $pd]} {
        return {}
    }
    return [dict get $::TT_SDP_RESCUE_ENDCAP_PD_CACHE $pd]
}

proc TT_SDP_RESCUE_refresh_endcaps {} {
    set ::TT_SDP_RESCUE_ENDCAP_CACHE_READY 0
    set ::TT_SDP_RESCUE_ENDCAP_PD_CACHE [dict create]
    return [TT_SDP_RESCUE__refresh_endcap_cache]
}

proc TT_SDP_RESCUE_endcap_report {{max_show 30}} {
    if {!$::TT_SDP_RESCUE_ENDCAP_CACHE_READY} {
        TT_SDP_RESCUE__refresh_endcap_cache
    }

    puts ""
    puts "======================================================================"
    puts " TT SDP LIVE RESCUE / ENDCAP CACHE REPORT"
    puts "======================================================================"
    puts "Instance patterns : {$::TT_SDP_RESCUE_ENDCAP_INST_PATTERNS}"
    puts "Master patterns   : {$::TT_SDP_RESCUE_ENDCAP_MASTER_PATTERNS}"
    puts "---------------------------------------------------------------------"

    set shown 0
    set total 0
    dict for {pd recs} $::TT_SDP_RESCUE_ENDCAP_PD_CACHE {
        incr total [llength $recs]
        puts "PD=$pd ENDCAPs=[llength $recs]"
        foreach r $recs {
            if {$shown >= $max_show} { continue }
            lassign $r x1 x2 y1 y2 n obj kind
            puts "  $n bbox={$x1 $y1 $x2 $y2}"
            incr shown
        }
    }
    puts "---------------------------------------------------------------------"
    puts "TOTAL ENDCAPs     : $total"
    puts "Shown             : $shown"
    puts "======================================================================"
    return [dict create total $total cache $::TT_SDP_RESCUE_ENDCAP_PD_CACHE]
}

# Same logical 2-row-unit boundaries.
# Return record:
#   {x1 x2 y1 y2 name object kind y_overlap}
# where kind is SW or ENDCAP.
proc TT_SDP_RESCUE__same_2row_boundaries {pd ibox} {
    if {[llength $ibox] != 4} { return {} }
    if {[llength [info commands TT_SDP_PGROW__switch_records_for_pd]] == 0} {
        TT_SDP_RESCUE_reload_custom_tools
    }

    lassign $ibox ix1 iy1 ix2 iy2
    set ih [expr {double($iy2)-double($iy1)}]
    if {$ih <= $::TT_SDP_RESCUE_GEOM_TOL} { return {} }

    # one physical row of a 2-row ISO
    set need [expr {$ih*0.50}]
    set out {}

    foreach rec [TT_SDP_PGROW__switch_records_for_pd $pd] {
        lassign $rec sx1 sy1 sx2 sy2 sname sobj
        set ov [TT_SDP_RESCUE__y_overlap_amount $ibox [list $sx1 $sy1 $sx2 $sy2]]
        if {$ov+$::TT_SDP_RESCUE_GEOM_TOL < $need} { continue }
        lappend out [list $sx1 $sx2 $sy1 $sy2 $sname $sobj SW $ov]
    }

    foreach rec [TT_SDP_RESCUE__endcaps_for_pd $pd] {
        lassign $rec ex1 ex2 ey1 ey2 ename eobj ekind
        set ov [TT_SDP_RESCUE__y_overlap_amount $ibox [list $ex1 $ey1 $ex2 $ey2]]
        if {$ov+$::TT_SDP_RESCUE_GEOM_TOL < $need} { continue }
        lappend out [list $ex1 $ex2 $ey1 $ey2 $ename $eobj ENDCAP $ov]
    }

    return [lsort -real -index 0 $out]
}

proc TT_SDP_RESCUE__same_2row_lane_switches {pd ibox} {
    set out {}
    foreach rec [TT_SDP_RESCUE__same_2row_boundaries $pd $ibox] {
        if {[lindex $rec 6] ne "SW"} { continue }
        # Preserve old return layout:
        # {x1 x2 y1 y2 name object y_overlap}
        lappend out [list \
            [lindex $rec 0] [lindex $rec 1] \
            [lindex $rec 2] [lindex $rec 3] \
            [lindex $rec 4] [lindex $rec 5] \
            [lindex $rec 7]]
    }
    return $out
}

proc TT_SDP_RESCUE__direct_slot_for_bbox {pd ibox} {
    if {[llength $ibox] != 4} {
        return [dict create ok false reason BAD_BBOX pd $pd bbox $ibox]
    }

    lassign $ibox ix1 iy1 ix2 iy2
    set bounds [TT_SDP_RESCUE__same_2row_boundaries $pd $ibox]

    if {[llength $bounds] == 0} {
        return [dict create \
            ok false reason NO_BOUNDARY_IN_2ROW_UNIT pd $pd bbox $ibox \
            lane_y1 $iy1 lane_y2 $iy2 boundaries {}]
    }

    set left {}
    set right {}
    set best_lx -1.0e100
    set best_rx 1.0e100

    foreach b $bounds {
        lassign $b bx1 bx2 by1 by2 bname bobj bkind bov

        if {double($bx2) <= double($ix1)+$::TT_SDP_RESCUE_GEOM_TOL} {
            if {double($bx2) > $best_lx} {
                set best_lx [expr {double($bx2)}]
                set left $b
            }
        }

        if {double($bx1) >= double($ix2)-$::TT_SDP_RESCUE_GEOM_TOL} {
            if {double($bx1) < $best_rx} {
                set best_rx [expr {double($bx1)}]
                set right $b
            }
        }
    }

    if {[llength $left] == 0 || [llength $right] == 0} {
        return [dict create \
            ok false reason MISSING_LEFT_OR_RIGHT_BOUNDARY \
            bounded false pd $pd bbox $ibox \
            lane_y1 $iy1 lane_y2 $iy2 \
            boundaries $bounds left $left right $right]
    }

    set lname [lindex $left 4]
    set lkind [lindex $left 6]
    set rname [lindex $right 4]
    set rkind [lindex $right 6]

    set slot_key [format "%s|%.6f:%.6f|%s:%s|%s:%s" \
        $pd $iy1 $iy2 $lkind $lname $rkind $rname]

    return [dict create \
        ok true reason BOUNDED_2ROW_SLOT bounded true \
        pd $pd bbox $ibox lane_y1 $iy1 lane_y2 $iy2 \
        boundaries $bounds \
        left $left right $right \
        left_kind $lkind right_kind $rkind \
        left_name $lname right_name $rname \
        slot_key $slot_key]
}

proc TT_SDP_RESCUE_scan_direct_2row {{verbose true}} {
    if {[llength [info commands TT_SDP_PGROW__refresh_iso_cache]] == 0} {
        TT_SDP_RESCUE_reload_custom_tools
    }

    # Identity may have been re-sourced/changed in this live session.
    set ::TT_SDP_PGROW_ISO_CACHE_READY 0
    TT_SDP_PGROW__refresh_iso_cache

    catch {array unset slot_groups}
    catch {array unset slot_meta}

    set boundary_bad {}
    set checked 0
    set details {}

    foreach group [lsort -dictionary [dict keys $::TT_SDP_PGROW_ISO_OBJ_CACHE]] {
        lassign [dict get $::TT_SDP_PGROW_ISO_OBJ_CACHE $group] cell pd
        set ibox ""
        catch {set ibox [TT_SDP_PGROW__rect4 [get_db $cell .bbox]]}
        if {[llength $ibox] != 4} {
            lappend r2_bad $group
            lappend details [dict create group $group pd $pd reason BAD_BBOX bbox $ibox]
            continue
        }
        incr checked

        set slot [TT_SDP_RESCUE__direct_slot_for_bbox $pd $ibox]
        set reason [dict get $slot reason]

        if {$reason ne "BOUNDED_2ROW_SLOT"} {
            lappend boundary_bad $group
            lappend details [dict merge [dict create group $group] $slot]
            continue
        }

        set key [dict get $slot slot_key]
        lappend slot_groups($key) $group
        if {![info exists slot_meta($key)]} { set slot_meta($key) $slot }
    }

    set keepers {}
    set movers {}
    set overcrowded {}

    foreach key [lsort -dictionary [array names slot_groups]] {
        set gs [lsort -dictionary -unique $slot_groups($key)]
        if {[llength $gs] <= 1} {
            lappend keepers [lindex $gs 0]
            continue
        }

        # Choose ONE keeper that is already best centered in the SW slot.
        # This minimizes movement while satisfying "one stays, others move".
        set meta $slot_meta($key)
        set left [dict get $meta left]
        set right [dict get $meta right]
        set slot_mid [expr {(double([lindex $left 1])+double([lindex $right 0]))/2.0}]

        set best ""
        set best_d 1.0e100
        foreach g $gs {
            lassign [dict get $::TT_SDP_PGROW_ISO_OBJ_CACHE $g] cell pd
            set b [TT_SDP_PGROW__rect4 [get_db $cell .bbox]]
            lassign $b x1 y1 x2 y2
            set cx [expr {(double($x1)+double($x2))/2.0}]
            set d [expr {abs($cx-$slot_mid)}]
            if {$d < $best_d-$::TT_SDP_RESCUE_GEOM_TOL ||
                (abs($d-$best_d) <= $::TT_SDP_RESCUE_GEOM_TOL &&
                 ($best eq "" || [string compare $g $best] < 0))} {
                set best $g
                set best_d $d
            }
        }

        lappend keepers $best
        set excess {}
        foreach g $gs {
            if {$g eq $best} { continue }
            lappend movers $g
            lappend excess $g
        }
        lappend overcrowded [dict create \
            slot_key $key groups $gs keeper $best movers $excess \
            left_name [dict get $meta left_name] left_kind [dict get $meta left_kind] \
            right_name [dict get $meta right_name] right_kind [dict get $meta right_kind] \
            lane_y1 [dict get $meta lane_y1] lane_y2 [dict get $meta lane_y2]]
    }

    set boundary_bad [lsort -dictionary -unique $boundary_bad]
    set movers [lsort -dictionary -unique $movers]
    set keepers [lsort -dictionary -unique $keepers]
    set bad [lsort -dictionary -unique [concat $boundary_bad $movers]]

    set systematic_mapping_failure false
    if {$checked > 0 && [llength $boundary_bad] == $checked && [llength $overcrowded] == 0} {
        set systematic_mapping_failure true
    }

    set result [dict create \
        checked $checked \
        violations [llength $bad] \
        bad_groups $bad \
        boundary_bad_groups $boundary_bad \
        mover_groups $movers \
        keeper_groups $keepers \
        overcrowded_slots $overcrowded \
        systematic_mapping_failure $systematic_mapping_failure \
        details $details]

    set ::TT_SDP_RESCUE_LAST_DIRECT_SCAN $result

    if {[TT_SDP_RESCUE__bool $verbose]} {
        puts ""
        puts "======================================================================"
        puts " TT SDP DIRECT 2-ROW / SW-GEOMETRY CHECK"
        puts "======================================================================"
        puts "Checked canonical ISO       : $checked"
        puts "Y-cover fraction for SW lane: $::TT_SDP_RESCUE_SW_Y_COVER_FRACTION"
        puts "Missing 2-row boundaries    : [llength $boundary_bad]"
        puts "Overcrowded 2-row slots     : [llength $overcrowded]"
        puts "Excess/mover groups         : [llength $movers]"
        puts "ENDCAP policy               : ENDCAP is a legal slot boundary, same as SW"
        puts "TOTAL definite bad groups   : [llength $bad]"
        puts "Systematic mapping failure  : $systematic_mapping_failure"
        puts "Policy                      : one 2-row unit; SW/ENDCAP overlap >= one physical row (50%)"
        puts "Policy                      : LANE_MAP_FAIL is NOT a violation"
        puts "======================================================================"
        if {$systematic_mapping_failure} {
            puts "CRITICAL: every canonical ISO was classified NO_SW_IN_2ROW_LANE."
            puts "CRITICAL: this indicates checker geometry/mapping failure, NOT 100% bad placement."
            puts "CRITICAL: marking/repair must be refused until mapping is fixed."
        }
        foreach rec $overcrowded {
            puts "R1_BAD slot=[dict get $rec slot_key] keeper=[dict get $rec keeper] movers={[dict get $rec movers]}"
        }
        foreach g $boundary_bad {
            set d ""
            foreach dd $details {
                if {[dict exists $dd group] && [dict get $dd group] eq $g} {
                    set d $dd
                    break
                }
            }
            if {$d ne ""} {
                puts "BOUNDARY_BAD group=$g reason=[dict get $d reason]"
            } else {
                puts "BOUNDARY_BAD group=$g"
            }
        }
    }

    return $result
}


proc TT_SDP_RESCUE_show_sw_y_overlap {group {max_show 20}} {
    if {[llength [info commands TT_SDP_PGROW__refresh_iso_cache]] == 0} {
        TT_SDP_RESCUE_reload_custom_tools
    }
    if {![info exists ::TT_SDP_PGROW_ISO_CACHE_READY] || !$::TT_SDP_PGROW_ISO_CACHE_READY} {
        TT_SDP_PGROW__refresh_iso_cache
    }
    if {![dict exists $::TT_SDP_PGROW_ISO_OBJ_CACHE $group]} {
        error "Unknown canonical ISO group '$group'"
    }

    lassign [dict get $::TT_SDP_PGROW_ISO_OBJ_CACHE $group] cell pd
    set ibox [TT_SDP_PGROW__rect4 [get_db $cell .bbox]]
    lassign $ibox ix1 iy1 ix2 iy2
    set ih [expr {double($iy2)-double($iy1)}]
    set need [expr {$ih*double($::TT_SDP_RESCUE_SW_Y_COVER_FRACTION)}]

    set rows {}
    foreach rec [TT_SDP_PGROW__switch_records_for_pd $pd] {
        lassign $rec sx1 sy1 sx2 sy2 sname sobj
        set ov [TT_SDP_RESCUE__y_overlap_amount $ibox [list $sx1 $sy1 $sx2 $sy2]]
        if {$ov <= $::TT_SDP_RESCUE_GEOM_TOL} { continue }
        lappend rows [list $ov $sx1 $sx2 $sy1 $sy2 $sname]
    }
    set rows [lsort -real -decreasing -index 0 $rows]

    puts ""
    puts "======================================================================"
    puts " TT SDP / SW Y-OVERLAP DIAGNOSTIC"
    puts "======================================================================"
    puts "Group            : $group"
    puts "PD               : $pd"
    puts "ISO bbox         : {$ibox}"
    puts "ISO height       : $ih"
    puts "Required overlap : $need (= one physical row / 50% of 2-row ISO)"
    puts "Overlapping SWs  : [llength $rows]"
    puts "---------------------------------------------------------------------"

    set shown 0
    foreach r $rows {
        if {$shown >= $max_show} { break }
        lassign $r ov sx1 sx2 sy1 sy2 sname
        set frac [expr {$ih > 0.0 ? $ov/$ih : 0.0}]
        puts [format "ov=%-8.6f frac=%-6.3f SW=%s bbox={%s %s %s %s}" \
            $ov $frac $sname $sx1 $sy1 $sx2 $sy2]
        incr shown
    }
    puts "======================================================================"
    return [dict create group $group pd $pd bbox $ibox height $ih required_overlap $need sw_rows $rows]
}


proc TT_SDP_RESCUE_show_boundaries {group {max_show 30}} {
    if {[llength [info commands TT_SDP_PGROW__refresh_iso_cache]] == 0} {
        TT_SDP_RESCUE_reload_custom_tools
    }
    if {![info exists ::TT_SDP_PGROW_ISO_CACHE_READY] || !$::TT_SDP_PGROW_ISO_CACHE_READY} {
        TT_SDP_PGROW__refresh_iso_cache
    }
    if {![dict exists $::TT_SDP_PGROW_ISO_OBJ_CACHE $group]} {
        error "Unknown canonical ISO group '$group'"
    }

    lassign [dict get $::TT_SDP_PGROW_ISO_OBJ_CACHE $group] cell pd
    set ibox [TT_SDP_PGROW__rect4 [get_db $cell .bbox]]
    set bs [TT_SDP_RESCUE__same_2row_boundaries $pd $ibox]

    puts ""
    puts "======================================================================"
    puts " TT SDP / 2-ROW SLOT BOUNDARY DIAGNOSTIC"
    puts "======================================================================"
    puts "Group      : $group"
    puts "PD         : $pd"
    puts "ISO bbox   : {$ibox}"
    puts "Boundaries : [llength $bs]"
    puts "---------------------------------------------------------------------"

    set shown 0
    foreach b $bs {
        if {$shown >= $max_show} { break }
        lassign $b x1 x2 y1 y2 n obj kind ov
        puts [format "%-7s ov=%-8.6f %-70s bbox={%s %s %s %s}" \
            $kind $ov $n $x1 $y1 $x2 $y2]
        incr shown
    }

    set slot [TT_SDP_RESCUE__direct_slot_for_bbox $pd $ibox]
    puts "---------------------------------------------------------------------"
    puts "Result     : [dict get $slot reason]"
    if {[dict exists $slot left] && [llength [dict get $slot left]] > 0} {
        puts "LEFT       : [dict get $slot left_kind]:[dict get $slot left_name]"
    } else {
        puts "LEFT       : <NONE>"
    }
    if {[dict exists $slot right] && [llength [dict get $slot right]] > 0} {
        puts "RIGHT      : [dict get $slot right_kind]:[dict get $slot right_name]"
    } else {
        puts "RIGHT      : <NONE>"
    }
    puts "======================================================================"
    return $slot
}

proc TT_SDP_RESCUE_explain_direct {group} {
    set scan [TT_SDP_RESCUE_scan_direct_2row false]

    if {![dict exists $::TT_SDP_PGROW_ISO_OBJ_CACHE $group]} {
        puts "DIRECT_EXPLAIN group=$group reason=NOT_CANONICAL_ISO"
        return [dict create group $group ok false reason NOT_CANONICAL_ISO]
    }

    lassign [dict get $::TT_SDP_PGROW_ISO_OBJ_CACHE $group] cell pd
    set ibox [TT_SDP_PGROW__rect4 [get_db $cell .bbox]]
    set slot [TT_SDP_RESCUE__direct_slot_for_bbox $pd $ibox]
    set reason [dict get $slot reason]

    if {$reason ne "BOUNDED_2ROW_SLOT"} {
        puts "DIRECT_EXPLAIN group=$group pd=$pd reason=$reason bbox={$ibox}"
        if {[dict exists $slot left]} {
            set left [dict get $slot left]
            set right [dict get $slot right]
            puts "  left_boundary  = {$left}"
            puts "  right_boundary = {$right}"
        }
        return [dict merge [dict create group $group legal false] $slot]
    }

    set key [dict get $slot slot_key]
    set role CLEAN
    set occ {}
    foreach rec [dict get $scan overcrowded_slots] {
        if {[dict get $rec slot_key] ne $key} { continue }
        set occ [dict get $rec groups]
        if {$group eq [dict get $rec keeper]} {
            set role KEEP
        } elseif {[lsearch -exact [dict get $rec movers] $group] >= 0} {
            set role MOVE
        }
        break
    }

    puts "DIRECT_EXPLAIN group=$group pd=$pd role=$role"
    puts "  slot        = {$key}"
    puts "  left        = [dict get $slot left_kind]:[dict get $slot left_name]"
    puts "  right       = [dict get $slot right_kind]:[dict get $slot right_name]"
    puts "  occupants   = {$occ}"
    return [dict merge [dict create group $group role $role occupants $occ] $slot]
}

proc TT_SDP_RESCUE_clear_pgrow_nosw {} {
    set deleted 0
    set failed {}
    foreach pb [get_db place_blockages] {
        set n ""
        catch {set n [get_db $pb .name]}
        if {$n eq "" || ![string match "TT_SDP_PGROW_NOSW_*" $n]} { continue }
        if {[catch {delete_obj $pb} err]} {
            lappend failed [list $n $err]
        } else {
            incr deleted
        }
    }
    set ::TT_SDP_PGROW_ACTIVE_BLKS {}
    puts "INFO: deleted stale/custom TT_SDP_PGROW_NOSW_* = $deleted; failures=[llength $failed]"
    return [dict create deleted $deleted failed $failed]
}

# -----------------------------------------------------------------------------
# GUI marking helpers.
# Mark ONLY the canonical center ISO/CELL of currently bad PGROW groups.
# No placement, blockage, SDP origin, or place_status changes are made.
# -----------------------------------------------------------------------------
proc TT_SDP_RESCUE_clear_marks {} {
    set cleared false
    if {[llength [info commands gui_clear_highlight]] > 0} {
        if {![catch {gui_clear_highlight}]} { set cleared true }
    }
    if {!$cleared && [llength [info commands dehighlight]] > 0} {
        catch {dehighlight -all}
        set cleared true
    }
    if {[llength [info commands gui_redraw]] > 0} {
        catch {gui_redraw}
    }
    puts "INFO: TT SDP rescue GUI marks cleared=[expr {$cleared ? 1 : 0}]"
    return $cleared
}

proc TT_SDP_RESCUE__mark_inst_red {inst} {
    if {$inst eq ""} { return [dict create ok false method none reason empty_inst] }

    set name ""
    catch {set name [get_db $inst .name]}

    # Innovus Stylus/Common UI preferred path.
    if {[llength [info commands gui_highlight]] > 0} {
        if {![catch {gui_highlight -index 1 $inst} err]} {
            return [dict create ok true method gui_highlight_index1 name $name]
        }
        if {![catch {gui_highlight -color red $inst} err2]} {
            return [dict create ok true method gui_highlight_red name $name]
        }
    }

    # Legacy-compatible fallback.
    if {[llength [info commands highlight]] > 0} {
        if {![catch {highlight -color red $inst} err3]} {
            return [dict create ok true method highlight_red name $name]
        }
        if {$name ne "" && ![catch {highlight -color red $name} err4]} {
            return [dict create ok true method highlight_name_red name $name]
        }
    }

    # Last fallback: select the object so it is still visible in GUI.
    if {[llength [info commands select_obj]] > 0} {
        if {![catch {select_obj $inst} err5]} {
            return [dict create ok true method select_obj name $name]
        }
    }

    return [dict create ok false method none name $name reason "no usable GUI highlight/select command"]
}

proc TT_SDP_RESCUE_mark_groups {groups {clear_first true}} {
    if {[TT_SDP_RESCUE__bool $clear_first]} {
        TT_SDP_RESCUE_clear_marks
    }

    # Ensure the current live canonical ISO object map is available.
    if {[llength [info commands TT_SDP_PGROW__refresh_iso_cache]] == 0} {
        TT_SDP_RESCUE_reload_custom_tools
    }
    if {![info exists ::TT_SDP_PGROW_ISO_CACHE_READY] || !$::TT_SDP_PGROW_ISO_CACHE_READY} {
        TT_SDP_PGROW__refresh_iso_cache
    }

    set marked 0
    set failed {}
    set names {}
    foreach g [lsort -dictionary -unique $groups] {
        if {![dict exists $::TT_SDP_PGROW_ISO_OBJ_CACHE $g]} {
            lappend failed [list $g "not in canonical ISO cache"]
            continue
        }

        lassign [dict get $::TT_SDP_PGROW_ISO_OBJ_CACHE $g] cell pd
        set r [TT_SDP_RESCUE__mark_inst_red $cell]
        if {[dict get $r ok]} {
            incr marked
            lappend names [dict get $r name]
        } else {
            lappend failed [list $g [dict get $r reason]]
        }
    }

    if {[llength [info commands gui_redraw]] > 0} {
        catch {gui_redraw}
    }

    puts ""
    puts "======================================================================"
    puts " TT SDP LIVE RESCUE / MARK BAD CENTER CELLS"
    puts "======================================================================"
    puts "Requested groups : [llength [lsort -dictionary -unique $groups]]"
    puts "Marked RED       : $marked"
    puts "Mark failures    : [llength $failed]"
    puts "Object policy    : center ISO/CELL only; WT_L/WT_R are NOT highlighted"
    puts "Placement action : NONE"
    puts "Blockage action  : NONE"
    if {[llength $failed] > 0} {
        foreach f $failed { puts "WARN: mark failed: $f" }
    }
    puts "======================================================================"

    return [dict create marked $marked failed $failed names $names groups $groups]
}

proc TT_SDP_RESCUE_mark_bad {{limit 0}} {
    # Always remove stale marks first, even if the new checker later REFUSES.
    TT_SDP_RESCUE_clear_marks

    # Mark only DEFINITE bad groups from direct 2-row boundary geometry.
    set scan [TT_SDP_RESCUE_scan_direct_2row false]

    if {[dict exists $scan systematic_mapping_failure] &&
        [dict get $scan systematic_mapping_failure]} {
        puts "CRITICAL: TT_SDP_RESCUE_mark_bad REFUSED."
        puts "CRITICAL: checker reports systematic mapping failure; previous GUI marks WERE cleared."
        return [dict create marked 0 refused true reason SYSTEMATIC_MAPPING_FAILURE]
    }

    set bad [dict get $scan bad_groups]

    if {[string is integer -strict $limit] && $limit > 0 && [llength $bad] > $limit} {
        set bad [lrange $bad 0 [expr {$limit-1}]]
    }

    puts "INFO: direct-geometry definite bad groups to mark = [llength $bad]"
    return [TT_SDP_RESCUE_mark_groups $bad false]
}

# Mark one specific canonical SDP group's center ISO/CELL.
proc TT_SDP_RESCUE_mark_group {group} {
    return [TT_SDP_RESCUE_mark_groups [list $group] true]
}

# -----------------------------------------------------------------------------
# Explain WHY a custom PGROW group is bad, using V2.0 logical 2-row lanes.
# -----------------------------------------------------------------------------
proc TT_SDP_RESCUE_explain_group {group} {
    if {[llength [info commands TT_SDP_PGROW__refresh_iso_cache]] == 0} {
        error "PGROW V2.0 helper is not loaded"
    }
    if {!$::TT_SDP_PGROW_ISO_CACHE_READY} { TT_SDP_PGROW__refresh_iso_cache }
    if {!$::TT_SDP_PGROW_LANE_CACHE_READY} { TT_SDP_PGROW__refresh_lane_cache }

    if {![dict exists $::TT_SDP_PGROW_ISO_OBJ_CACHE $group]} {
        set r [dict create group $group ok false reason UNKNOWN_CANONICAL_GROUP]
        puts "PGROW_EXPLAIN group=$group reason=UNKNOWN_CANONICAL_GROUP"
        return $r
    }

    lassign [dict get $::TT_SDP_PGROW_ISO_OBJ_CACHE $group] cell pd
    set cb ""
    catch {set cb [TT_SDP_PGROW__rect4 [get_db $cell .bbox]]}
    if {[llength $cb] != 4} {
        set r [dict create group $group ok false reason BAD_BBOX pd $pd]
        puts "PGROW_EXPLAIN group=$group pd=$pd reason=BAD_BBOX"
        return $r
    }

    set mapped [TT_SDP_PGROW__map_bbox_to_lane $pd $cb]
    if {[llength $mapped] != 3} {
        set r [dict create group $group ok false reason LANE_MAP_FAIL pd $pd bbox $cb]
        puts "PGROW_EXPLAIN group=$group pd=$pd reason=LANE_MAP_FAIL bbox={$cb}"
        return $r
    }
    lassign $mapped lkey lrec score
    set swrecs [TT_SDP_PGROW__lane_switch_records_cached $pd $lkey $lrec]
    if {[llength $swrecs] == 0} {
        set r [dict create group $group ok false reason NO_SW_IN_2ROW_LANE pd $pd lane $lkey]
        puts "PGROW_EXPLAIN group=$group pd=$pd lane=$lkey reason=NO_SW_IN_2ROW_LANE"
        return $r
    }

    lassign $cb x1 y1 x2 y2
    set cx [expr {(double($x1)+double($x2))/2.0}]
    set found false
    set left ""
    set right ""
    set ilx2 0.0
    set irx1 0.0
    for {set i 0} {$i < [expr {[llength $swrecs]-1}]} {incr i} {
        set l [lindex $swrecs $i]
        set r [lindex $swrecs [expr {$i+1}]]
        lassign $l lx1 lx2 ln lo
        lassign $r rx1 rx2 rn ro
        if {double($rx1) <= double($lx2)+$::TT_SDP_PGROW_TOL} { continue }
        if {$cx > double($lx2)+$::TT_SDP_PGROW_TOL && $cx < double($rx1)-$::TT_SDP_PGROW_TOL} {
            set found true
            set left $ln
            set right $rn
            set ilx2 $lx2
            set irx1 $rx1
            break
        }
    }

    if {!$found} {
        set r [dict create group $group ok true reason NO_ENCLOSING_SW_PAIR_R1_NOT_APPLICABLE pd $pd lane $lkey]
        puts "PGROW_EXPLAIN group=$group pd=$pd lane=$lkey reason=NO_ENCLOSING_SW_PAIR_R1_NOT_APPLICABLE"
        return $r
    }

    set occ {}
    foreach rec [TT_SDP_PGROW__iso_records] {
        lassign $rec ogroup ocell opd ob
        if {$opd ne $pd} { continue }
        set om [TT_SDP_PGROW__map_bbox_to_lane $opd $ob]
        if {[llength $om] != 3 || [lindex $om 0] ne $lkey} { continue }
        lassign $ob ox1 oy1 ox2 oy2
        set ocx [expr {(double($ox1)+double($ox2))/2.0}]
        if {$ocx > double($ilx2)+$::TT_SDP_PGROW_TOL && $ocx < double($irx1)-$::TT_SDP_PGROW_TOL} {
            lappend occ $ogroup
        }
    }
    set occ [lsort -dictionary -unique $occ]
    if {[llength $occ] > 1} {
        set r [dict create group $group ok false reason MULTI_ISO_SAME_2ROW_SLOT pd $pd lane $lkey left_sw $left right_sw $right occupants $occ]
        puts "PGROW_EXPLAIN group=$group pd=$pd lane=$lkey SW={$left $right} reason=MULTI_ISO_SAME_2ROW_SLOT occupants={$occ}"
        return $r
    }

    set r [dict create group $group ok true reason OK pd $pd lane $lkey left_sw $left right_sw $right occupants $occ]
    puts "PGROW_EXPLAIN group=$group pd=$pd lane=$lkey SW={$left $right} reason=OK"
    return $r
}

proc TT_SDP_RESCUE_explain_bad {{limit 30}} {
    if {![string is integer -strict $limit] || $limit < 1} { set limit 30 }
    set scan [TT_SDP_PGROW_scan false]
    set bad [dict get $scan repair_groups]
    puts ""
    puts "======================================================================"
    puts " PGROW BAD-GROUP EXPLANATION"
    puts "======================================================================"
    puts "Total bad groups : [llength $bad]"
    puts "Showing          : [expr {min($limit,[llength $bad])}]"
    set n 0
    foreach g $bad {
        if {$n >= $limit} { break }
        TT_SDP_RESCUE_explain_group $g
        incr n
    }
    puts "======================================================================"
    return $scan
}

# -----------------------------------------------------------------------------
# Explicit LAST-stage custom repair.
# Hard-gated by native==0 and gap==0.
# -----------------------------------------------------------------------------
proc TT_SDP_RESCUE_apply_custom {} {
    TT_SDP_RESCUE_clear_repair_blks
    TT_SDP_RESCUE_reload_custom_tools
    if {[llength [info commands TT_PR7_scan_internal_sdp_structure__TT_RESCUE_FULL]] > 0} {
        TT_SDP_RESCUE_enable_gap_only_checker
    }

    set native [TT_SDP_RESCUE__native_total]
    set gap [TT_SDP_RESCUE__gap_scan false]
    set gapv [dict get $gap violations]
    if {$native != 0 || $gapv != 0} {
        puts "ERROR: refusing custom PGROW repair: native=$native gap=$gapv. Run TT_SDP_RESCUE_native_first first."
        return [dict create ok false stage prerequisite native $native gap $gapv]
    }

    if {![info exists ::TT_SDP_PGROW_VERSION] ||
        ![string match "V2.0_LOGICAL_2ROW_LANE_CHECKERBOARD*" $::TT_SDP_PGROW_VERSION]} {
        error "Refusing custom repair: PGROW V2.0 logical-2-row-lane tool is not loaded."
    }

    # Rebuild custom R2 blockage from the current clean geometry.
    set ::TT_SDP_PGROW_LANE_CACHE_READY 0
    set ::TT_SDP_PGROW_LANE_CACHE [dict create]
    set ::TT_SDP_PGROW_LANE_SW_CACHE [dict create]
    set rb [TT_SDP_PGROW_prepare_blockages]

    set scan [TT_SDP_PGROW_scan true]
    if {[dict get $scan violations] == 0} {
        puts "PASS: custom PGROW already clean; no place_detail needed."
        return [dict create ok true stage already_clean scan $scan]
    }

    puts "INFO: Custom PGROW is LAST stage. Applying ONE global keeper/mover repair pass."
    TT_SDP_RESCUE_explain_bad 30
    set r [TT_SDP_PGROW_repair 1 $scan]

    # Native signoff after custom movement; do not recursively custom-repair again.
    set native_after [TT_SDP_RESCUE__native_total]
    set gap_after [TT_SDP_RESCUE__gap_scan false]
    set gapv_after [dict get $gap_after violations]
    set pg_after [TT_SDP_PGROW_scan true]

    puts ""
    puts "======================================================================"
    puts " TT SDP LIVE RESCUE / CUSTOM POSTCHECK"
    puts "======================================================================"
    puts "native check_sdps : $native_after"
    puts "internal GAP-only : $gapv_after"
    puts "PGROW violations  : [dict get $pg_after violations]"
    puts "======================================================================"

    if {$native_after != 0 || $gapv_after != 0} {
        puts "WARN: custom movement introduced/left native or GAP issues. STOP; do not run another custom place_detail."
        return [dict create ok false stage custom_postcheck native $native_after gap $gapv_after pgrow [dict get $pg_after violations] result $r]
    }

    return [dict create ok [expr {[dict get $pg_after violations] == 0}] stage custom_done native $native_after gap $gapv_after pgrow [dict get $pg_after violations] result $r]
}

proc TT_SDP_RESCUE_help {} {
    puts ""
    puts "======================================================================"
    puts " TT SDP LIVE RESCUE - $::TT_SDP_RESCUE_VERSION"
    puts "======================================================================"
    puts "1) Source this file"
    puts "   -> automatically clears PGISO RESERVE/MOVE + PR7 GAPBLK repair BLKs"
    puts ""
    puts "2) Inspect current owned BLKs"
    puts "   TT_SDP_RESCUE_blk_report 12"
    puts ""
    puts "3) Repair native FIRST, then GAP-only, then rebuild V2.0 custom BLKs"
    puts "   TT_SDP_RESCUE_native_first"
    puts ""
    puts "4) Remove stale wrong no-SW BLKs from old custom checker (optional live debug)"
    puts "   TT_SDP_RESCUE_clear_pgrow_nosw"
    puts ""
    puts "5) Direct 2-row/SW geometry diagnostics (NO placement)"
    puts "   TT_SDP_RESCUE_scan_direct_2row"
    puts "   TT_SDP_RESCUE_show_sw_y_overlap SDP2R_00066"
    puts "   TT_SDP_RESCUE_endcap_report 30"
    puts "   TT_SDP_RESCUE_show_boundaries SDP2R_00066"
    puts "   TT_SDP_RESCUE_explain_direct SDP2R_00066"
    puts ""
    puts "6) Mark only DEFINITE direct-geometry bad center ISO/CELLs in RED"
    puts "   TT_SDP_RESCUE_mark_bad"
    puts "   TT_SDP_RESCUE_mark_bad 30"
    puts "   TT_SDP_RESCUE_mark_group SDP2R_00066"
    puts "   TT_SDP_RESCUE_clear_marks"
    puts ""
    puts "7) Legacy V2.0 explain (for comparison only)"
    puts "   TT_SDP_RESCUE_explain_bad 30"
    puts "   TT_SDP_RESCUE_explain_group SDP2R_00066"
    puts ""
    puts "8) Only after native=0 and gap=0, apply custom rule"
    puts "   TT_SDP_RESCUE_apply_custom"
    puts ""
    puts "Rollback checker semantics in this session:"
    puts "   TT_SDP_RESCUE_restore_full_internal_checker"
    puts "======================================================================"
}

puts "INFO: Loaded TT_sdp_live_rescue_native_first.tcl - $::TT_SDP_RESCUE_VERSION"

# User explicitly requested repair-created BLKs be cancelled first.
if {[TT_SDP_RESCUE__bool $::TT_SDP_RESCUE_AUTO_CLEAR_REPAIR_BLKS]} {
    TT_SDP_RESCUE_clear_repair_blks
}
TT_SDP_RESCUE_help
