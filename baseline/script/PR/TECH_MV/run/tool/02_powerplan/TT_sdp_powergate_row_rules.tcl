# Runtime adapter preserves the historical logical source path.
if {[info exists ::TECH_MV_RUNTIME_ROOT]} {
    info script [file join $::TECH_MV_RUNTIME_ROOT run/tool/02_powerplan/TT_sdp_powergate_row_rules.tcl]
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
# Load private values before evaluating original parameter defaults.
if {![llength [info commands ::tech_mv_private_value]]} { source [file join $::TECH_MV_RUNTIME_ROOT .. script PR TECH_MV script 00_common private_parameter_config.tcl] }
# =============================================================================
# TT_sdp_powergate_row_rules.tcl
# TECH_MV / Innovus 21.19 Stylus / Common UI
#
# ADDITIVE Power-Gated SDP row rules.
#
# Existing SDP/native/SW-gap checks are NOT replaced or removed.
# This helper adds only these two rules for canonical 2-row ISO SDP groups in
# power-gated domains discovered from the existing CPU/WDT Power Switches:
#
#   PGROW-R1  Checking is performed on ONE LOGICAL 2-ROW LANE at a time.
#             Between one adjacent Power-Switch pair belonging to that same
#             logical 2-row lane, at most ONE canonical 2-row ISO may occupy
#             that interval.
#
#   PGROW-R2  A LOGICAL 2-ROW LANE with NO Power Switch may not contain a
#             canonical 2-row ISO.
#
# IMPORTANT
#   Power Switches are checkerboard/staggered across neighboring lanes.  A
#   single physical row is therefore NOT a legal PGROW matching unit; doing so
#   can pair switches from neighboring columns/lanes.  V2.0 derives the 2-row
#   pairing from live Power-Switch bbox coverage of adjacent physical rows.
#
# Placement policy for PGROW-R2:
#   - Before LS/ISO provisional placement, create temporary HARD blockages only
#     on 2-row-lane segments inside the power-gated domain whose logical lane
#     contains no SW.
#   - Prefix: TT_SDP_PGROW_NOSW_*
#   - Keep them active through SDP placement/refine/check.
#   - Delete only this owned prefix at final cleanup.
#
# Repair policy:
#   - Internal [WT_L][CELL][WT_R] gap repair remains owned by
#     TT_refine_internal_gap_sdps and is NOT replaced.
#   - PGROW-R1/R2 use a separate slot-reservation repair driver:
#       TT_repair_powergate_iso_slots
#   - Every already-occupied SW-to-SW interval reserves the space from
#       left SW -> keeper WT_L
#     and
#       keeper WT_R -> right SW
#     with temporary HARD blockages, leaving only the keeper SDP slot open.
#   - Excess / no-SW-row ISO centers are then moved with the SAME proven R9
#     low-level mechanics: triplet temp padding -> one batched place_detail ->
#     guarded set_sdp_origin -> restore exact padding -> targeted validation.
#   - No call to TT_refine_internal_gap_sdps is made by PGROW repair.
#
# Source behavior:
#   Definition-only.  Sourcing this file does NOT create/delete/move anything.
# =============================================================================

set ::TT_SDP_PGROW_VERSION "V2.4_COMPACT_OPERATOR_UI"
if {![info exists ::TT_SDP_PGROW_ENABLE]} { set ::TT_SDP_PGROW_ENABLE true }
if {![info exists ::TT_SDP_PGROW_BLK_PREFIX]} { set ::TT_SDP_PGROW_BLK_PREFIX "TT_SDP_PGROW_NOSW_" }
if {![info exists ::TT_SDP_PGROW_MAX_REPAIR_PASSES]} { set ::TT_SDP_PGROW_MAX_REPAIR_PASSES 1 }
if {![info exists ::TT_SDP_PGROW_TOL]} { set ::TT_SDP_PGROW_TOL [::tech_mv_private_value {run/tool/02_powerplan/TT_sdp_powergate_row_rules.tcl::::TT_SDP_PGROW_TOL::L56}] }
if {![info exists ::TT_SDP_PGROW_LAST_SCAN]} { set ::TT_SDP_PGROW_LAST_SCAN {} }
if {![info exists ::TT_SDP_PGROW_ACTIVE_BLKS]} { set ::TT_SDP_PGROW_ACTIVE_BLKS {} }
if {![info exists ::TT_SDP_PGROW_SWITCH_CACHE_READY]} { set ::TT_SDP_PGROW_SWITCH_CACHE_READY 0 }
if {![info exists ::TT_SDP_PGROW_SWITCH_CACHE]} { set ::TT_SDP_PGROW_SWITCH_CACHE {} }
if {![info exists ::TT_SDP_PGROW_SWITCH_PD_CACHE]} { set ::TT_SDP_PGROW_SWITCH_PD_CACHE [dict create] }
if {![info exists ::TT_SDP_PGROW_SWITCH_REC_CACHE]} { set ::TT_SDP_PGROW_SWITCH_REC_CACHE [dict create] }
if {![info exists ::TT_SDP_PGROW_ISO_CACHE_READY]} { set ::TT_SDP_PGROW_ISO_CACHE_READY 0 }
if {![info exists ::TT_SDP_PGROW_ISO_OBJ_CACHE]} { set ::TT_SDP_PGROW_ISO_OBJ_CACHE [dict create] }
if {![info exists ::TT_SDP_PGROW_ROW_CACHE_READY]} { set ::TT_SDP_PGROW_ROW_CACHE_READY 0 }
if {![info exists ::TT_SDP_PGROW_ROW_CACHE]} { set ::TT_SDP_PGROW_ROW_CACHE [dict create] }
if {![info exists ::TT_SDP_PGROW_BAND_SW_CACHE]} { set ::TT_SDP_PGROW_BAND_SW_CACHE [dict create] }
if {![info exists ::TT_SDP_PGROW_LANE_CACHE_READY]} { set ::TT_SDP_PGROW_LANE_CACHE_READY 0 }
if {![info exists ::TT_SDP_PGROW_LANE_CACHE]} { set ::TT_SDP_PGROW_LANE_CACHE [dict create] }
if {![info exists ::TT_SDP_PGROW_LANE_SW_CACHE]} { set ::TT_SDP_PGROW_LANE_SW_CACHE [dict create] }
set ::TT_SDP_PGROW_TOOL_DIR [file dirname [file normalize [info script]]]

# V2.1 direct-boundary policy.
# The ISO's actual bbox defines the logical two-row unit. A checkerboard SW or
# side ENDCAP belongs to that unit when it overlaps at least one physical row
# (= 50% of a 2-row ISO height).
set ::TT_SDP_PGROW_Y_COVER_FRACTION 0.50
if {![info exists ::TT_SDP_PGROW_ENDCAP_INST_PATTERNS]} {
    set ::TT_SDP_PGROW_ENDCAP_INST_PATTERNS {ENDCAP_* *ENDCAP*}
}
if {![info exists ::TT_SDP_PGROW_ENDCAP_MASTER_PATTERNS]} {
    # Only horizontal slot-side boundary cells. Do not treat NROW/NCORNER as
    # left/right slot boundaries.
    set ::TT_SDP_PGROW_ENDCAP_MASTER_PATTERNS [::tech_mv_library_value LIB_CELL_005]
}
set ::TT_SDP_PGROW_ENDCAP_CACHE_READY 0
set ::TT_SDP_PGROW_ENDCAP_PD_CACHE [dict create]
set ::TT_SDP_PGROW_MAPPING_FAILSAFE true

proc TT_SDP_PGROW__bool {v} {
    set s [string tolower [string trim $v]]
    return [expr {$s eq "true" || $s eq "1" || $s eq "yes"}]
}

proc TT_SDP_PGROW__rect4 {v} {
    if {[llength $v] == 1} { set v [lindex $v 0] }
    if {[llength $v] != 4} { return "" }
    foreach x $v {
        if {![string is double -strict $x]} { return "" }
    }
    return $v
}

proc TT_SDP_PGROW__row_rect {row} {
    foreach attr {.rect .bbox .box} {
        set raw ""
        if {![catch {set raw [get_db $row $attr]}]} {
            set r [TT_SDP_PGROW__rect4 $raw]
            if {[llength $r] == 4} { return $r }
        }
    }
    return ""
}

proc TT_SDP_PGROW__rect_intersection {a b} {
    if {[llength $a] != 4 || [llength $b] != 4} { return "" }
    lassign $a ax1 ay1 ax2 ay2
    lassign $b bx1 by1 bx2 by2
    set x1 [expr {max(double($ax1),double($bx1))}]
    set y1 [expr {max(double($ay1),double($by1))}]
    set x2 [expr {min(double($ax2),double($bx2))}]
    set y2 [expr {min(double($ay2),double($by2))}]
    if {$x2 <= $x1 + $::TT_SDP_PGROW_TOL || $y2 <= $y1 + $::TT_SDP_PGROW_TOL} { return "" }
    return [list $x1 $y1 $x2 $y2]
}

proc TT_SDP_PGROW__rect_overlap {a b} {
    return [expr {[TT_SDP_PGROW__rect_intersection $a $b] ne ""}]
}

proc TT_SDP_PGROW__y_overlap {a b} {
    if {[llength $a] != 4 || [llength $b] != 4} { return false }
    lassign $a ax1 ay1 ax2 ay2
    lassign $b bx1 by1 bx2 by2
    return [expr {double($ay1) < double($by2)-$::TT_SDP_PGROW_TOL && double($ay2) > double($by1)+$::TT_SDP_PGROW_TOL}]
}

proc TT_SDP_PGROW__row_key {rect} {
    lassign $rect x1 y1 x2 y2
    return [format "%.6f:%.6f" $y1 $y2]
}

proc TT_SDP_PGROW__sanitize {v} {
    regsub -all {[^A-Za-z0-9_]} $v "_" out
    return $out
}

proc TT_SDP_PGROW__switch_domain {sw} {
    set name ""
    catch {set name [get_db $sw .name]}
    set leaf [lindex [split $name /] end]
    # Match the exact switch families already recognized by the active SDP flow.
    if {[string match "PD_CPU_SW*" $leaf]} { return "PD_CPU" }
    if {[string match "PD_WDT_SW*" $leaf]} { return "PD_WDT" }
    set pd ""
    catch {set pd [get_db $sw .power_domain.name]}
    return $pd
}

proc TT_SDP_PGROW__discover_switches {} {
    if {[llength [info commands TT_2row_sdp__power_switches]] > 0} {
        return [TT_2row_sdp__power_switches]
    }
    set out {}
    foreach inst [get_db insts] {
        set name ""
        set master ""
        catch {set name [get_db $inst .name]}
        catch {set master [get_db $inst .base_cell.name]}
        set leaf [lindex [split $name /] end]
        if {![string match "PD_CPU_SW*" $leaf] && ![string match "PD_WDT_SW*" $leaf]} { continue }
        if {![string match [::tech_mv_library_value LIB_MATCH_001] $master]} { continue }
        lappend out $inst
    }
    return $out
}

# PERF-ONLY: discover the complete switch set once per PGROW pass, then cache
# object lists and bboxes per power domain.  No placement/blockage semantics are
# changed; this only removes repeated full-design get_db insts scans per row.
proc TT_SDP_PGROW__refresh_switch_cache {} {
    set all [TT_SDP_PGROW__discover_switches]
    set pd_cache [dict create]
    set rec_cache [dict create]
    foreach sw $all {
        set pd [TT_SDP_PGROW__switch_domain $sw]
        if {$pd eq ""} { continue }
        dict lappend pd_cache $pd $sw
        set sb ""
        catch {set sb [TT_SDP_PGROW__rect4 [get_db $sw .bbox]]}
        if {[llength $sb] != 4} { continue }
        set n ""
        catch {set n [get_db $sw .name]}
        lassign $sb x1 y1 x2 y2
        dict lappend rec_cache $pd [list $x1 $y1 $x2 $y2 $n $sw]
    }
    set ::TT_SDP_PGROW_SWITCH_CACHE $all
    set ::TT_SDP_PGROW_SWITCH_PD_CACHE $pd_cache
    set ::TT_SDP_PGROW_SWITCH_REC_CACHE $rec_cache
    set ::TT_SDP_PGROW_BAND_SW_CACHE [dict create]
    set ::TT_SDP_PGROW_LANE_SW_CACHE [dict create]
    set ::TT_SDP_PGROW_LANE_CACHE_READY 0
    set ::TT_SDP_PGROW_LANE_CACHE [dict create]
    set ::TT_SDP_PGROW_SWITCH_CACHE_READY 1
    return [llength $all]
}

proc TT_SDP_PGROW__switches {} {
    if {!$::TT_SDP_PGROW_SWITCH_CACHE_READY} { TT_SDP_PGROW__refresh_switch_cache }
    return $::TT_SDP_PGROW_SWITCH_CACHE
}

proc TT_SDP_PGROW__powergate_domains {} {
    # Hard policy: PGROW applies ONLY to power domains that contain at least one
    # live recognized Power Switch.  No static PD list is used here.
    if {!$::TT_SDP_PGROW_SWITCH_CACHE_READY} { TT_SDP_PGROW__refresh_switch_cache }
    set out {}
    dict for {pd sws} $::TT_SDP_PGROW_SWITCH_PD_CACHE {
        if {$pd eq "" || [llength $sws] == 0} { continue }
        lappend out $pd
    }
    return [lsort -dictionary -unique $out]
}

proc TT_SDP_PGROW__switches_for_pd {pd} {
    if {!$::TT_SDP_PGROW_SWITCH_CACHE_READY} { TT_SDP_PGROW__refresh_switch_cache }
    if {![dict exists $::TT_SDP_PGROW_SWITCH_PD_CACHE $pd]} { return {} }
    return [dict get $::TT_SDP_PGROW_SWITCH_PD_CACHE $pd]
}

proc TT_SDP_PGROW__switch_records_for_pd {pd} {
    if {!$::TT_SDP_PGROW_SWITCH_CACHE_READY} { TT_SDP_PGROW__refresh_switch_cache }
    if {![dict exists $::TT_SDP_PGROW_SWITCH_REC_CACHE $pd]} { return {} }
    return [dict get $::TT_SDP_PGROW_SWITCH_REC_CACHE $pd]
}

proc TT_SDP_PGROW__pd_rects {pd} {
    set grps {}
    catch {set grps [get_db groups $pd]}
    if {[llength $grps] != 1} {
        catch {set grps [get_db groups -if [format {.power_domain.name == "%s"} $pd]]}
    }
    if {[llength $grps] != 1} {
        error "TT_SDP_PGROW: Power Domain '$pd' maps to [llength $grps] physical groups; fail closed."
    }
    set out {}
    set raw {}
    if {[catch {set raw [get_db [lindex $grps 0] .rects]} err]} {
        error "TT_SDP_PGROW: cannot read physical rectangles for '$pd': $err"
    }
    foreach rr $raw {
        set r [TT_SDP_PGROW__rect4 $rr]
        if {[llength $r] == 4} { lappend out $r }
    }
    if {[llength $out] == 0} {
        error "TT_SDP_PGROW: Power Domain '$pd' has no readable physical rectangle."
    }
    return $out
}

# Returns records: {row_key clipped_row_rect original_row_rect}
# Duplicate clipped rectangles are removed.  Only the active SDP site is used.
proc TT_SDP_PGROW__pd_row_records {pd} {
    set pd_rects [TT_SDP_PGROW__pd_rects $pd]
    set site_name $::TT_2ROW_SDP_SITE
    set out {}
    catch {array unset seen}
    foreach row [get_db rows] {
        set s ""
        catch {set s [get_db $row .site.name]}
        if {$s ne $site_name} { continue }
        set rr [TT_SDP_PGROW__row_rect $row]
        if {[llength $rr] != 4} { continue }
        set key [TT_SDP_PGROW__row_key $rr]
        foreach pr $pd_rects {
            set clip [TT_SDP_PGROW__rect_intersection $rr $pr]
            if {$clip eq ""} { continue }
            set sig [format "%s|%.6f|%.6f|%.6f|%.6f" $key {*}$clip]
            if {[info exists seen($sig)]} { continue }
            set seen($sig) 1
            lappend out [list $key $clip $rr]
        }
    }
    if {[llength $out] == 0} {
        error "TT_SDP_PGROW: no '$site_name' row segment intersects Power Domain '$pd'."
    }
    return $out
}


# PERF V1.3: placement rows / PD rectangles do not move during the PGROW repair
# loop. Cache the clipped row records once per global PGROW scan/repair pass.
proc TT_SDP_PGROW__refresh_row_cache {{domains ""}} {
    if {$domains eq ""} { set domains [TT_SDP_PGROW__powergate_domains] }
    set c [dict create]
    foreach pd $domains {
        dict set c $pd [TT_SDP_PGROW__pd_row_records $pd]
    }
    set ::TT_SDP_PGROW_ROW_CACHE $c
    set ::TT_SDP_PGROW_ROW_CACHE_READY 1
    set ::TT_SDP_PGROW_LANE_CACHE_READY 0
    set ::TT_SDP_PGROW_LANE_CACHE [dict create]
    set ::TT_SDP_PGROW_LANE_SW_CACHE [dict create]
    return $c
}

proc TT_SDP_PGROW__rows_for_pd {pd} {
    if {!$::TT_SDP_PGROW_ROW_CACHE_READY} {
        TT_SDP_PGROW__refresh_row_cache
    }
    if {![dict exists $::TT_SDP_PGROW_ROW_CACHE $pd]} { return {} }
    return [dict get $::TT_SDP_PGROW_ROW_CACHE $pd]
}



# =============================================================================
# V2.1 DIRECT 2-ROW BOUNDARY MODEL
# =============================================================================

proc TT_SDP_PGROW__matches_any_nocase {value patterns} {
    foreach pat $patterns {
        if {[string match -nocase $pat $value]} { return true }
    }
    return false
}

proc TT_SDP_PGROW__endcap_domain {inst} {
    set pd ""
    catch {set pd [get_db $inst .power_domain.name]}
    if {$pd ne ""} { return $pd }

    set n ""
    catch {set n [get_db $inst .name]}
    set leaf [lindex [split $n /] end]
    if {[string match "*PD_CPU*" $leaf]} { return PD_CPU }
    if {[string match "*PD_WDT*" $leaf]} { return PD_WDT }
    return ""
}

proc TT_SDP_PGROW__is_side_endcap {inst} {
    set name ""
    set master ""
    catch {set name [get_db $inst .name]}
    catch {set master [get_db $inst .base_cell.name]}

    set name_hit [TT_SDP_PGROW__matches_any_nocase $name $::TT_SDP_PGROW_ENDCAP_INST_PATTERNS]
    set master_hit [TT_SDP_PGROW__matches_any_nocase $master $::TT_SDP_PGROW_ENDCAP_MASTER_PATTERNS]

    # Prefer explicit ENDCAP instance naming, but require side-boundary master
    # when master information is available. This excludes top/bottom NROW cells.
    if {$name_hit && $master_hit} { return true }
    if {$name_hit && $master eq ""} { return true }
    return false
}

proc TT_SDP_PGROW__refresh_endcap_cache {} {
    set domains [TT_SDP_PGROW__powergate_domains]
    catch {array unset wanted_pd}
    foreach pd $domains { set wanted_pd($pd) 1 }

    set c [dict create]
    set total 0
    set scanned 0
    foreach inst [get_db insts] {
        incr scanned

        # Cheap name filter before master lookup.
        set n ""
        catch {set n [get_db $inst .name]}
        if {![TT_SDP_PGROW__matches_any_nocase $n $::TT_SDP_PGROW_ENDCAP_INST_PATTERNS]} {
            continue
        }
        if {![TT_SDP_PGROW__is_side_endcap $inst]} { continue }

        set pd [TT_SDP_PGROW__endcap_domain $inst]
        if {$pd eq "" || ![info exists wanted_pd($pd)]} { continue }

        set b ""
        catch {set b [TT_SDP_PGROW__rect4 [get_db $inst .bbox]]}
        if {[llength $b] != 4} { continue }
        lassign $b x1 y1 x2 y2
        dict lappend c $pd [list $x1 $y1 $x2 $y2 $n $inst]
        incr total
    }

    set ::TT_SDP_PGROW_ENDCAP_PD_CACHE $c
    set ::TT_SDP_PGROW_ENDCAP_CACHE_READY 1
    puts "INFO: PGROW V2.1 side-ENDCAP cache: scanned=$scanned matched=$total SW-bearing-PDs={$domains}"
    return $total
}

proc TT_SDP_PGROW__endcap_records_for_pd {pd} {
    if {!$::TT_SDP_PGROW_ENDCAP_CACHE_READY} { TT_SDP_PGROW__refresh_endcap_cache }
    if {![dict exists $::TT_SDP_PGROW_ENDCAP_PD_CACHE $pd]} { return {} }
    return [dict get $::TT_SDP_PGROW_ENDCAP_PD_CACHE $pd]
}

proc TT_SDP_PGROW__y_overlap_amount {a b} {
    if {[llength $a] != 4 || [llength $b] != 4} { return 0.0 }
    lassign $a ax1 ay1 ax2 ay2
    lassign $b bx1 by1 bx2 by2
    set h [expr {min(double($ay2),double($by2))-max(double($ay1),double($by1))}]
    if {$h <= $::TT_SDP_PGROW_TOL} { return 0.0 }
    return $h
}

# Pure helper: build same-two-row-unit boundary records from cached geometry.
# SW input/endcap input shape:
#   {x1 y1 x2 y2 name object}
# output:
#   {x1 x2 y1 y2 name object kind y_overlap}
proc TT_SDP_PGROW__same_unit_boundaries_from_records {ibox swrecs ecrecs} {
    if {[llength $ibox] != 4} { return {} }
    lassign $ibox ix1 iy1 ix2 iy2
    set ih [expr {double($iy2)-double($iy1)}]
    if {$ih <= $::TT_SDP_PGROW_TOL} { return {} }
    set need [expr {$ih*double($::TT_SDP_PGROW_Y_COVER_FRACTION)}]

    set out {}
    foreach rec $swrecs {
        lassign $rec x1 y1 x2 y2 name obj
        set ov [TT_SDP_PGROW__y_overlap_amount $ibox [list $x1 $y1 $x2 $y2]]
        if {$ov+$::TT_SDP_PGROW_TOL < $need} { continue }
        lappend out [list $x1 $x2 $y1 $y2 $name $obj SW $ov]
    }
    foreach rec $ecrecs {
        lassign $rec x1 y1 x2 y2 name obj
        set ov [TT_SDP_PGROW__y_overlap_amount $ibox [list $x1 $y1 $x2 $y2]]
        if {$ov+$::TT_SDP_PGROW_TOL < $need} { continue }
        lappend out [list $x1 $x2 $y1 $y2 $name $obj ENDCAP $ov]
    }
    return [lsort -real -index 0 $out]
}

proc TT_SDP_PGROW__same_unit_boundaries {pd ibox} {
    return [TT_SDP_PGROW__same_unit_boundaries_from_records \
        $ibox \
        [TT_SDP_PGROW__switch_records_for_pd $pd] \
        [TT_SDP_PGROW__endcap_records_for_pd $pd]]
}

# Pure helper: find nearest LEFT and RIGHT boundary around one ISO bbox.
proc TT_SDP_PGROW__slot_from_boundaries {pd ibox bounds} {
    if {[llength $ibox] != 4} {
        return [dict create ok false reason BAD_BBOX pd $pd bbox $ibox]
    }
    lassign $ibox ix1 iy1 ix2 iy2

    set left {}
    set right {}
    set best_lx -1.0e100
    set best_rx  1.0e100

    foreach b $bounds {
        lassign $b bx1 bx2 by1 by2 bname bobj bkind bov

        if {double($bx2) <= double($ix1)+$::TT_SDP_PGROW_TOL} {
            if {double($bx2) > $best_lx} {
                set best_lx [expr {double($bx2)}]
                set left $b
            }
        }
        if {double($bx1) >= double($ix2)-$::TT_SDP_PGROW_TOL} {
            if {double($bx1) < $best_rx} {
                set best_rx [expr {double($bx1)}]
                set right $b
            }
        }
    }

    if {[llength $left] == 0 || [llength $right] == 0} {
        return [dict create \
            ok false reason MISSING_LEFT_OR_RIGHT_BOUNDARY \
            pd $pd bbox $ibox boundaries $bounds left $left right $right]
    }

    set lname [lindex $left 4]
    set lkind [lindex $left 6]
    set rname [lindex $right 4]
    set rkind [lindex $right 6]
    set lx2 [lindex $left 1]
    set rx1 [lindex $right 0]
    set row_key [format "%.6f:%.6f" $iy1 $iy2]
    set slot_key [format "%s|%s|%s:%s|%s:%s" $pd $row_key $lkind $lname $rkind $rname]

    return [dict create \
        ok true reason BOUNDED_SLOT \
        pd $pd bbox $ibox row_key $row_key slot_key $slot_key \
        left $left right $right \
        left_name $lname left_kind $lkind left_x2 $lx2 \
        right_name $rname right_kind $rkind right_x1 $rx1]
}

proc TT_SDP_PGROW__slot_for_bbox {pd ibox} {
    return [TT_SDP_PGROW__slot_from_boundaries \
        $pd $ibox [TT_SDP_PGROW__same_unit_boundaries $pd $ibox]]
}

# Select one in-place keeper for an overcrowded slot.
# Prefer the ISO whose center is closest to the usable slot center.
proc TT_SDP_PGROW__choose_keeper {groups left_x2 right_x1} {
    set slot_mid [expr {(double($left_x2)+double($right_x1))/2.0}]
    set best ""
    set best_d 1.0e100

    foreach g [lsort -dictionary -unique $groups] {
        if {![dict exists $::TT_SDP_PGROW_ISO_OBJ_CACHE $g]} { continue }
        lassign [dict get $::TT_SDP_PGROW_ISO_OBJ_CACHE $g] cell pd
        set b ""
        catch {set b [TT_SDP_PGROW__rect4 [get_db $cell .bbox]]}
        if {[llength $b] != 4} { continue }
        lassign $b x1 y1 x2 y2
        set cx [expr {(double($x1)+double($x2))/2.0}]
        set d [expr {abs($cx-$slot_mid)}]

        if {$d < $best_d-$::TT_SDP_PGROW_TOL ||
            (abs($d-$best_d) <= $::TT_SDP_PGROW_TOL &&
             ($best eq "" || [string compare $g $best] < 0))} {
            set best $g
            set best_d $d
        }
    }
    if {$best eq "" && [llength $groups] > 0} {
        set best [lindex [lsort -dictionary -unique $groups] 0]
    }
    return $best
}

# =============================================================================
# V2.0 LOGICAL 2-ROW LANE MODEL
# =============================================================================
#
# A canonical ISO and the target Power Switch family are two-row structures.
# Neighboring lanes use checkerboard/staggered switch X positions.  Therefore
# all R1/R2 matching MUST happen on a pair of adjacent physical rows, never on
# one physical row independently.
#
# Lane record:
#   {lane_key lane_clip lane_rect low_row_key high_row_key low_rr high_rr}
#
# lane_key is still "y1:y2", but now y1..y2 spans TWO physical rows.

proc TT_SDP_PGROW__row_key_y1 {key} {
    set p [split $key ":"]
    if {[llength $p] != 2} { return 0.0 }
    return [expr {double([lindex $p 0])}]
}

proc TT_SDP_PGROW__row_key_compare {a b} {
    set ay [TT_SDP_PGROW__row_key_y1 $a]
    set by [TT_SDP_PGROW__row_key_y1 $b]
    if {$ay < $by} { return -1 }
    if {$ay > $by} { return 1 }
    return [string compare $a $b]
}

proc TT_SDP_PGROW__y_overlap_amount {a b} {
    if {[llength $a] != 4 || [llength $b] != 4} { return 0.0 }
    lassign $a ax1 ay1 ax2 ay2
    lassign $b bx1 by1 bx2 by2
    set h [expr {min(double($ay2),double($by2))-max(double($ay1),double($by1))}]
    if {$h <= $::TT_SDP_PGROW_TOL} { return 0.0 }
    return $h
}

# Pure geometry helper used both by the live flow and by package self-tests.
# It determines whether logical row pairs are (0,1),(2,3)... or
# (1,2),(3,4)... from ACTUAL switch bbox coverage.
proc TT_SDP_PGROW__build_two_row_lanes_from_records {pd rows swrecs} {
    catch {array unset rr_of}
    catch {array unset clips_of}

    foreach rec $rows {
        lassign $rec key clip rr
        if {![info exists rr_of($key)]} { set rr_of($key) $rr }
        lappend clips_of($key) $clip
    }

    set keys [lsort -command TT_SDP_PGROW__row_key_compare [array names rr_of]]
    set n [llength $keys]
    if {$n < 2} {
        error "TT_SDP_PGROW V2.0: '$pd' has fewer than two physical rows; cannot form logical 2-row lanes."
    }

    set parity0 0
    set parity1 0

    # Each real two-row switch votes for the adjacent-row pair it physically
    # overlaps most strongly.  Checkerboard X staggering is irrelevant here.
    foreach swrec $swrecs {
        lassign $swrec sx1 sy1 sx2 sy2 sname sobj
        set sb [list $sx1 $sy1 $sx2 $sy2]
        set best_i -1
        set best_score 0.0

        for {set i 0} {$i < $n-1} {incr i} {
            set k0 [lindex $keys $i]
            set k1 [lindex $keys [expr {$i+1}]]
            set r0 $rr_of($k0)
            set r1 $rr_of($k1)

            lassign $r0 r0x1 r0y1 r0x2 r0y2
            lassign $r1 r1x1 r1y1 r1x2 r1y2

            # Rows in one logical pair must be physically adjacent.
            if {abs(double($r0y2)-double($r1y1)) > $::TT_SDP_PGROW_TOL} { continue }

            set o0 [TT_SDP_PGROW__y_overlap_amount $sb $r0]
            set o1 [TT_SDP_PGROW__y_overlap_amount $sb $r1]
            if {$o0 <= 0.0 || $o1 <= 0.0} { continue }

            set score [expr {$o0+$o1}]
            if {$score > $best_score+$::TT_SDP_PGROW_TOL} {
                set best_score $score
                set best_i $i
            }
        }

        if {$best_i >= 0} {
            if {[expr {$best_i % 2}] == 0} {
                incr parity0
            } else {
                incr parity1
            }
        }
    }

    if {$parity0 == 0 && $parity1 == 0} {
        error "TT_SDP_PGROW V2.0: cannot infer 2-row lane pairing for '$pd' from live Power Switch geometry."
    }
    if {$parity0 == $parity1} {
        error "TT_SDP_PGROW V2.0: ambiguous 2-row lane pairing for '$pd': parity0=$parity0 parity1=$parity1; refusing single-row guess."
    }
    set parity [expr {$parity0 > $parity1 ? 0 : 1}]

    set lanes {}
    for {set i $parity} {$i < $n-1} {incr i 2} {
        set k0 [lindex $keys $i]
        set k1 [lindex $keys [expr {$i+1}]]
        set r0 $rr_of($k0)
        set r1 $rr_of($k1)
        lassign $r0 r0x1 r0y1 r0x2 r0y2
        lassign $r1 r1x1 r1y1 r1x2 r1y2

        if {abs(double($r0y2)-double($r1y1)) > $::TT_SDP_PGROW_TOL} {
            # Do not fabricate a lane across a physical row gap.
            continue
        }

        set ly1 [expr {min(double($r0y1),double($r1y1))}]
        set ly2 [expr {max(double($r0y2),double($r1y2))}]
        set lkey [format "%.6f:%.6f" $ly1 $ly2]
        set lrect [list \
            [expr {min(double($r0x1),double($r1x1))}] $ly1 \
            [expr {max(double($r0x2),double($r1x2))}] $ly2]

        # A 2-row cell is legal only over X where BOTH physical row segments
        # exist inside the PD.  Intersect lower/upper row clips in X.
        foreach c0 $clips_of($k0) {
            foreach c1 $clips_of($k1) {
                lassign $c0 c0x1 c0y1 c0x2 c0y2
                lassign $c1 c1x1 c1y1 c1x2 c1y2
                set x1 [expr {max(double($c0x1),double($c1x1))}]
                set x2 [expr {min(double($c0x2),double($c1x2))}]
                if {$x2 <= $x1+$::TT_SDP_PGROW_TOL} { continue }
                set clip [list $x1 $ly1 $x2 $ly2]
                lappend lanes [list $lkey $clip $lrect $k0 $k1 $r0 $r1]
            }
        }
    }

    return [dict create \
        pd $pd \
        parity $parity \
        parity0_evidence $parity0 \
        parity1_evidence $parity1 \
        physical_rows $n \
        lanes $lanes]
}

proc TT_SDP_PGROW__refresh_lane_cache {{domains ""}} {
    if {$domains eq ""} { set domains [TT_SDP_PGROW__powergate_domains] }
    if {!$::TT_SDP_PGROW_ROW_CACHE_READY} { TT_SDP_PGROW__refresh_row_cache $domains }
    if {!$::TT_SDP_PGROW_SWITCH_CACHE_READY} { TT_SDP_PGROW__refresh_switch_cache }

    set c [dict create]
    foreach pd $domains {
        set built [TT_SDP_PGROW__build_two_row_lanes_from_records \
            $pd [TT_SDP_PGROW__rows_for_pd $pd] [TT_SDP_PGROW__switch_records_for_pd $pd]]
        dict set c $pd $built
        puts "INFO: PGROW V2.0 2ROW-LANE pd=$pd parity=[dict get $built parity] evidence={p0=[dict get $built parity0_evidence] p1=[dict get $built parity1_evidence]} laneSegments=[llength [dict get $built lanes]]"
    }

    set ::TT_SDP_PGROW_LANE_CACHE $c
    set ::TT_SDP_PGROW_LANE_SW_CACHE [dict create]
    set ::TT_SDP_PGROW_LANE_CACHE_READY 1
    return $c
}

proc TT_SDP_PGROW__lanes_for_pd {pd} {
    if {!$::TT_SDP_PGROW_LANE_CACHE_READY} {
        TT_SDP_PGROW__refresh_lane_cache
    }
    if {![dict exists $::TT_SDP_PGROW_LANE_CACHE $pd lanes]} { return {} }
    return [dict get $::TT_SDP_PGROW_LANE_CACHE $pd lanes]
}

# Return ONLY switches that physically overlap BOTH rows of this logical lane.
# This is the key checkerboard protection: a switch from the neighboring
# staggered lane can no longer be paired into this lane.
proc TT_SDP_PGROW__lane_switch_records {pd lane_rec} {
    lassign $lane_rec lane_key lane_clip lane_rect low_key high_key low_rr high_rr
    set out {}
    foreach rec [TT_SDP_PGROW__switch_records_for_pd $pd] {
        lassign $rec x1 y1 x2 y2 n sw
        set sb [list $x1 $y1 $x2 $y2]
        if {![TT_SDP_PGROW__y_overlap $low_rr $sb]} { continue }
        if {![TT_SDP_PGROW__y_overlap $high_rr $sb]} { continue }
        lappend out [list $x1 $x2 $n $sw]
    }
    return [lsort -real -index 0 $out]
}

proc TT_SDP_PGROW__lane_switch_records_cached {pd lane_key lane_rec} {
    set ck "${pd}|${lane_key}"
    if {[dict exists $::TT_SDP_PGROW_LANE_SW_CACHE $ck]} {
        return [dict get $::TT_SDP_PGROW_LANE_SW_CACHE $ck]
    }
    set v [TT_SDP_PGROW__lane_switch_records $pd $lane_rec]
    dict set ::TT_SDP_PGROW_LANE_SW_CACHE $ck $v
    return $v
}

# Map one 2-row ISO bbox to EXACTLY ONE logical 2-row lane.
# Multiple X clips of the same lane are accumulated; neighboring logical lanes
# do not share positive Y area. Ambiguity fails closed.
proc TT_SDP_PGROW__map_bbox_to_lane {pd bbox} {
    if {[llength $bbox] != 4} { return {} }
    catch {array unset score}
    catch {array unset meta}

    foreach lrec [TT_SDP_PGROW__lanes_for_pd $pd] {
        lassign $lrec lkey clip lane_rect low_key high_key low_rr high_rr
        set ov [TT_SDP_PGROW__rect_intersection $bbox $clip]
        if {$ov eq ""} { continue }
        lassign $ov x1 y1 x2 y2
        set a [expr {(double($x2)-double($x1))*(double($y2)-double($y1))}]
        if {![info exists score($lkey)]} { set score($lkey) 0.0 }
        set score($lkey) [expr {$score($lkey)+$a}]
        if {![info exists meta($lkey)]} { set meta($lkey) $lrec }
    }

    if {[array size score] == 0} { return {} }

    set best ""
    set best_score -1.0
    set ties {}
    foreach k [array names score] {
        if {$score($k) > $best_score+$::TT_SDP_PGROW_TOL} {
            set best $k
            set best_score $score($k)
            set ties [list $k]
        } elseif {abs($score($k)-$best_score) <= $::TT_SDP_PGROW_TOL} {
            lappend ties $k
        }
    }

    set ties [lsort -unique $ties]
    if {[llength $ties] != 1} {
        return {}
    }
    return [list $best $meta($best) $best_score]
}

proc TT_SDP_PGROW__band_has_switch {pd band_rect} {
    foreach rec [TT_SDP_PGROW__switch_records_for_pd $pd] {
        lassign $rec x1 y1 x2 y2 n sw
        if {[TT_SDP_PGROW__y_overlap $band_rect [list $x1 $y1 $x2 $y2]]} { return true }
    }
    return false
}

proc TT_SDP_PGROW__owned_blockages {} {
    set out {}
    foreach pb [get_db place_blockages] {
        set n ""
        catch {set n [get_db $pb .name]}
        if {$n ne "" && [string match "${::TT_SDP_PGROW_BLK_PREFIX}*" $n]} {
            lappend out $pb
        }
    }
    return $out
}


# V1.8 coalesced flow coordinators.
#
# PRE-LS: everything whose geometry is already known is built together.
proc TT_SDP_PGROW_prepare_known_blockages {} {
    # V2.1: only the geometrically unambiguous Power-Switch keep-outs are
    # allowed before provisional LS/ISO placement.
    #
    # The old full-row TT_SDP_PGROW_NOSW_* construction is retired because a
    # two-row ISO can straddle checkerboard SW parities; a rectangular whole-row
    # blockage can therefore block a neighboring legal two-row start.
    set swko_count [TT_SWKO_ensure_all_switch_keepouts]
    set stale [TT_SDP_PGROW_prepare_blockages]
    return [dict create \
        swko_count $swko_count \
        no_sw_blk_count 0 \
        retired_no_sw_deleted [dict get $stale deleted] \
        domains [TT_SDP_PGROW__powergate_domains] \
        custom_deferred true]
}

proc TT_SDP_PGROW_prepare_pre_place_constraints {} {
    # NATIVE-FIRST V2.1:
    # Do NOT create PGROW reservation/mover blockages before first place_sdps.
    # First let Innovus establish native SDP legality, then run gap/SW-gap, and
    # only then apply the user's custom 2-row boundary rule.
    set swko_count [TT_SWKO_ensure_all_switch_keepouts]

    # Remove stale custom-owned families if this DB was resumed from an older
    # experimental run. Fresh reruns normally delete zero objects here.
    set retired [TT_SDP_PGROW_prepare_blockages]
    set slot_deleted 0
    if {[llength [info commands TT_SDP_PGISO_cleanup]] > 0} {
        set s [TT_SDP_PGISO_cleanup]
        set slot_deleted [dict get $s deleted]
    }

    return [dict create \
        swko_count $swko_count \
        no_sw_blk_count 0 \
        occupied_intervals 0 \
        reserve_blk_count 0 \
        stale_custom_deleted [expr {[dict get $retired deleted]+$slot_deleted}] \
        domains [TT_SDP_PGROW__powergate_domains] \
        custom_deferred true]
}

proc TT_SDP_PGROW_cleanup {} {
    set deleted 0
    set failed {}
    foreach pb [TT_SDP_PGROW__owned_blockages] {
        set n ""
        catch {set n [get_db $pb .name]}
        if {[catch {delete_obj $pb} err]} {
            lappend failed [list $n $err]
            puts "WARN: TT_SDP_PGROW could not delete owned blockage '$n': $err"
        } else {
            incr deleted
        }
    }
    set remain [TT_SDP_PGROW__owned_blockages]
    set ::TT_SDP_PGROW_ACTIVE_BLKS {}

    # Additive cleanup for the PGROW slot-reservation repair tool.  Only its
    # own TT_SDP_PGISO_* prefixes are eligible for deletion.
    set slot_cleanup [dict create ok true deleted 0 remaining 0]
    if {[llength [info commands TT_SDP_PGISO_cleanup]] == 0} {
        set _slot_file [file join $::TECH_MV_RUNTIME_ROOT .. script PR TECH_MV script 02_powerplan sdp repair_powergate_iso_slots.tcl]
        if {[file isfile $_slot_file]} {
            catch {source -quiet $_slot_file}
        }
        unset -nocomplain _slot_file
    }
    if {[llength [info commands TT_SDP_PGISO_cleanup]] > 0} {
        if {[catch {set slot_cleanup [TT_SDP_PGISO_cleanup]} slot_err]} {
            puts "WARN: TT_SDP_PGROW slot-repair cleanup failed: $slot_err"
            set slot_cleanup [dict create ok false deleted 0 remaining -1 error $slot_err]
        }
    }

    set base_ok [expr {[llength $failed] == 0 && [llength $remain] == 0}]
    set slot_ok true
    if {[dict exists $slot_cleanup ok]} { set slot_ok [dict get $slot_cleanup ok] }
    puts "INFO: TT_SDP_PGROW final cleanup: noSW_deleted=$deleted noSW_failed=[llength $failed] noSW_remaining=[llength $remain] slot_ok=$slot_ok"
    return [dict create ok [expr {$base_ok && $slot_ok}] deleted $deleted failed $failed remaining [llength $remain] slot_cleanup $slot_cleanup]
}

proc TT_SDP_PGROW_prepare_blockages {} {
    # V2.1 RETIRED:
    # Whole-row / whole-2row-lane no-SW placement blockages are unsafe for this
    # checkerboard topology. Delete only stale objects owned by that old policy.
    set deleted 0
    set failed {}
    foreach pb [TT_SDP_PGROW__owned_blockages] {
        set n ""
        catch {set n [get_db $pb .name]}
        if {[catch {delete_obj $pb} err]} {
            lappend failed [list $n $err]
        } else {
            incr deleted
        }
    }
    set ::TT_SDP_PGROW_ACTIVE_BLKS {}
    puts "INFO: PGROW V2.1 retired whole-row TT_SDP_PGROW_NOSW_* policy: stale_deleted=$deleted failed=[llength $failed]"
    return [dict create created 0 deleted $deleted failed $failed domains [TT_SDP_PGROW__powergate_domains] names {} retired true]
}

proc TT_SDP_PGROW_ensure_blockages {} {
    # Compatibility entry point: old whole-row no-SW blockages are retired.
    return [TT_SDP_PGROW_prepare_blockages]
}

# Resolve/cache canonical 2-row ISO group -> live instance object once.
# The instance identity is stable while R9 moves/re-anchors the group; only bbox
# is read live on each query.
proc TT_SDP_PGROW__refresh_iso_cache {} {
    set domains [TT_SDP_PGROW__powergate_domains]
    catch {array unset is_pg}
    foreach pd $domains { set is_pg($pd) 1 }

    set c [dict create]
    catch {array unset inst_exact}
    catch {array unset inst_leaf}
    TT_2row_sdp__build_inst_lookup inst_exact inst_leaf

    foreach rec [TT_2row_sdp__flat_group_records] {
        lassign $rec group wt_l_name cell_name wt_r_name
        set cell [TT_2row_sdp__resolve_inst $cell_name inst_exact inst_leaf]
        if {$cell eq ""} { continue }
        set iso false
        catch {set iso [get_db $cell .is_isolation]}
        if {![TT_SDP_PGROW__bool $iso]} { continue }
        set pd ""
        catch {set pd [get_db $cell .power_domain.name]}
        if {$pd eq "" || ![info exists is_pg($pd)]} { continue }
        dict set c $group [list $cell $pd]
    }

    set ::TT_SDP_PGROW_ISO_OBJ_CACHE $c
    set ::TT_SDP_PGROW_ISO_CACHE_READY 1
    return [dict size $c]
}

# Live records: {group cell pd bbox}
proc TT_SDP_PGROW__iso_records {} {
    if {!$::TT_SDP_PGROW_ISO_CACHE_READY} {
        TT_SDP_PGROW__refresh_iso_cache
    }
    set out {}
    foreach group [lsort -dictionary [dict keys $::TT_SDP_PGROW_ISO_OBJ_CACHE]] {
        lassign [dict get $::TT_SDP_PGROW_ISO_OBJ_CACHE $group] cell pd
        set cb ""
        catch {set cb [TT_SDP_PGROW__rect4 [get_db $cell .bbox]]}
        if {[llength $cb] != 4} { continue }
        lappend out [list $group $cell $pd $cb]
    }
    return $out
}

# Return switches intersecting one physical row band, sorted left-to-right.
# Each record is {x1 x2 name obj}.
proc TT_SDP_PGROW__band_switch_records {pd band_rect} {
    set out {}
    foreach rec [TT_SDP_PGROW__switch_records_for_pd $pd] {
        lassign $rec x1 y1 x2 y2 n sw
        set sb [list $x1 $y1 $x2 $y2]
        if {![TT_SDP_PGROW__y_overlap $band_rect $sb]} { continue }
        lappend out [list $x1 $x2 $n $sw]
    }
    return [lsort -real -index 0 $out]
}


# PERF V1.3: switches do not move during one PGROW repair pass. Cache the sorted
# switch list for each {PD,row-band} instead of filtering/sorting 1753 switches
# again for every ISO/callback.
proc TT_SDP_PGROW__band_switch_records_cached {pd key band_rect} {
    set ck "${pd}|${key}"
    if {[dict exists $::TT_SDP_PGROW_BAND_SW_CACHE $ck]} {
        return [dict get $::TT_SDP_PGROW_BAND_SW_CACHE $ck]
    }
    set v [TT_SDP_PGROW__band_switch_records $pd $band_rect]
    dict set ::TT_SDP_PGROW_BAND_SW_CACHE $ck $v
    return $v
}


# V2.0 GLOBAL keeper/mover classification.
#
# Upstream V2.0 lane mapping guarantees one canonical 2-row ISO belongs to at
# most ONE logical 2-row SW slot.  This classifier is retained as a defensive
# global role gate so KEEP and MOVE remain mutually exclusive for the whole run.
#
# Rules:
#   - any PGROW-R2 no-SW-row group is a mandatory MOVER;
#   - groups sharing one SW-to-SW interval conflict and cannot both be KEEPERS;
#   - singleton occupied intervals are preferred KEEPERS when possible;
#   - remaining candidates use a deterministic low-conflict greedy independent
#     set, favoring a group that covers more intervals when conflict degree ties;
#   - every group not selected KEEP and participating in a crowded interval is
#     a MOVER.
proc TT_SDP_PGROW__keeper_candidate_compare {a b} {
    lassign $a adeg anegspan ag
    lassign $b bdeg bnegspan bg
    if {$adeg < $bdeg} { return -1 }
    if {$adeg > $bdeg} { return 1 }
    if {$anegspan < $bnegspan} { return -1 }
    if {$anegspan > $bnegspan} { return 1 }
    return [string compare $ag $bg]
}

proc TT_SDP_PGROW__global_classify_intervals {occupied_intervals no_sw_groups} {
    set keepers {}
    set movers [lsort -dictionary -unique $no_sw_groups]
    set global_occupied {}
    set multi_intervals {}
    set unreserved {}

    foreach rec $occupied_intervals {
        lassign $rec ikey pd row_key lname rname lx2 rx1 preferred_keeper gs
        set gs [lsort -dictionary -unique $gs]
        if {[llength $gs] == 0} { continue }

        set keeper $preferred_keeper
        if {$keeper eq "" || [lsearch -exact $gs $keeper] < 0} {
            set keeper [lindex $gs 0]
        }
        if {[lsearch -exact $movers $keeper] >= 0} {
            set keeper ""
        }

        if {$keeper ne "" && [lsearch -exact $keepers $keeper] < 0} {
            lappend keepers $keeper
        }

        lappend global_occupied [list $ikey $pd $row_key $lname $rname $lx2 $rx1 $keeper $gs]

        if {[llength $gs] > 1} {
            set extras {}
            foreach g $gs {
                if {$g eq $keeper} { continue }
                lappend extras $g
                if {[lsearch -exact $movers $g] < 0} { lappend movers $g }
            }
            lappend multi_intervals [list $ikey $keeper $extras $gs]
        }
        if {$keeper eq ""} { lappend unreserved $ikey }
    }

    set keepers [lsort -dictionary -unique $keepers]
    set movers [lsort -dictionary -unique $movers]
    foreach g $keepers {
        if {[lsearch -exact $movers $g] >= 0} {
            error "PGROW V2.1 classifier error: '$g' is both KEEP and MOVE"
        }
    }

    return [dict create \
        keeper_groups $keepers \
        mover_groups $movers \
        occupied_intervals $global_occupied \
        multi_iso_intervals $multi_intervals \
        unreserved_intervals [lsort -dictionary -unique $unreserved]]
}

proc TT_SDP_PGROW_scan {{verbose true}} {
    if {![TT_SDP_PGROW__bool $::TT_SDP_PGROW_ENABLE]} {
        set r [dict create \
            violations 0 checked_iso 0 \
            no_switch_row_groups {} keeper_groups {} mover_groups {} \
            multi_iso_groups {} multi_iso_intervals {} occupied_intervals {} \
            unreserved_intervals {} repair_groups {} domains {} \
            mapping_failure false]
        set ::TT_SDP_PGROW_LAST_SCAN $r
        return $r
    }

    if {!$::TT_SDP_PGROW_SWITCH_CACHE_READY} { TT_SDP_PGROW__refresh_switch_cache }
    set domains [TT_SDP_PGROW__powergate_domains]
    if {[llength $domains] == 0} {
        set r [dict create \
            violations 0 checked_iso 0 \
            no_switch_row_groups {} keeper_groups {} mover_groups {} \
            multi_iso_groups {} multi_iso_intervals {} occupied_intervals {} \
            unreserved_intervals {} repair_groups {} domains {} \
            mapping_failure false]
        set ::TT_SDP_PGROW_LAST_SCAN $r
        return $r
    }

    if {!$::TT_SDP_PGROW_ENDCAP_CACHE_READY} { TT_SDP_PGROW__refresh_endcap_cache }
    if {!$::TT_SDP_PGROW_ISO_CACHE_READY} { TT_SDP_PGROW__refresh_iso_cache }

    catch {array unset interval_groups}
    catch {array unset interval_desc}
    set no_boundary_groups {}
    set reasons {}
    set checked 0

    foreach irec [TT_SDP_PGROW__iso_records] {
        lassign $irec group cell pd cb
        incr checked

        set slot [TT_SDP_PGROW__slot_for_bbox $pd $cb]
        if {![dict get $slot ok]} {
            lappend no_boundary_groups $group
            dict set reasons $group [dict get $slot reason]
            continue
        }

        set ikey [dict get $slot slot_key]
        set row_key [dict get $slot row_key]
        set lname [dict get $slot left_name]
        set rname [dict get $slot right_name]
        set lx2 [dict get $slot left_x2]
        set rx1 [dict get $slot right_x1]

        if {![info exists interval_desc($ikey)]} {
            set interval_desc($ikey) [list $pd $row_key $lname $rname $lx2 $rx1]
        }
        lappend interval_groups($ikey) $group
    }

    # Raw occupied slot records keep the historical tuple layout expected by
    # TT_repair_powergate_iso_slots. "left_sw/right_sw" fields may now name an
    # ENDCAP boundary; geometry semantics are unchanged.
    set raw_occupied_intervals {}
    foreach ikey [lsort -dictionary [array names interval_groups]] {
        set gs [lsort -dictionary -unique $interval_groups($ikey)]
        if {[llength $gs] == 0} { continue }
        lassign $interval_desc($ikey) pd row_key lname rname lx2 rx1
        set preferred [TT_SDP_PGROW__choose_keeper $gs $lx2 $rx1]
        lappend raw_occupied_intervals \
            [list $ikey $pd $row_key $lname $rname $lx2 $rx1 $preferred $gs]
    }

    # Direct model invariant: one ISO can belong to at most one bounded slot.
    catch {array unset seen}
    foreach rec $raw_occupied_intervals {
        foreach g [lindex $rec 8] {
            if {[info exists seen($g)]} {
                error "PGROW V2.1 invariant failure: group '$g' belongs to >1 direct 2-row slot"
            }
            set seen($g) 1
        }
    }

    set no_boundary_groups [lsort -dictionary -unique $no_boundary_groups]
    set classified [TT_SDP_PGROW__global_classify_intervals \
        $raw_occupied_intervals $no_boundary_groups]

    set keepers [dict get $classified keeper_groups]
    set movers [dict get $classified mover_groups]
    set multi [dict get $classified multi_iso_intervals]
    set occupied [dict get $classified occupied_intervals]
    set unreserved [dict get $classified unreserved_intervals]
    set repair_groups $movers

    set mapping_failure false
    if {[TT_SDP_PGROW__bool $::TT_SDP_PGROW_MAPPING_FAILSAFE] &&
        $checked > 0 &&
        [llength $no_boundary_groups] == $checked &&
        [llength $occupied] == 0} {
        set mapping_failure true
    }

    set r [dict create \
        violations [llength $repair_groups] \
        checked_iso $checked \
        no_switch_row_groups $no_boundary_groups \
        no_boundary_reasons $reasons \
        keeper_groups $keepers \
        mover_groups $movers \
        multi_iso_groups $movers \
        multi_iso_intervals $multi \
        occupied_intervals $occupied \
        unreserved_intervals $unreserved \
        repair_groups $repair_groups \
        domains $domains \
        mapping_failure $mapping_failure]
    set ::TT_SDP_PGROW_LAST_SCAN $r

    if {$verbose} {
        puts ""
        puts "======================================================================"
        puts " POWER-GATED SDP DIRECT 2-ROW BOUNDARY CHECK - V2.1"
        puts "======================================================================"
        puts "SW-bearing power domains      : {$domains}"
        puts "Canonical 2-row ISO checked   : $checked"
        puts "Boundary Y-overlap threshold  : 50% of ISO height = one physical row"
        puts "Boundary types                : checkerboard Power Switch + LEFT/RIGHT ENDCAP"
        puts "Overcrowded bounded slots     : [llength $multi]"
        puts "KEEP groups                   : [llength $keepers] {$keepers}"
        puts "MOVE groups                   : [llength $movers] {$movers}"
        puts "Missing-boundary groups       : [llength $no_boundary_groups] {$no_boundary_groups}"
        puts "Mapping fail-safe             : $mapping_failure"
        puts "Whole-row NOSW blockages      : RETIRED"
        puts "Repair engine                 : one global TT_repair_powergate_iso_slots pass"
        if {$mapping_failure} {
            puts "CRITICAL: every checked ISO lacks a bounded slot; auto-repair is DISABLED."
            puts "CRITICAL: treat this as checker/mapping failure, not as 100% bad placement."
        }
        if {[llength $multi] > 0} {
            set shown 0
            foreach x $multi {
                if {$shown >= 20} { break }
                lassign $x ikey keeper extras all
                puts "PGROW SLOT={$ikey} keep=$keeper move={$extras} all={$all}"
                incr shown
            }
        }
        puts "======================================================================"
    }

    return $r
}

# External PASS callback consumed by the additive R9 repair hook.
#
# PERF V1.3:
#   OLD: every repaired group called TT_SDP_PGROW_scan false, causing one full
#        design/row/ISO/SW scan PER GROUP.
#   NEW: check only this group's live bbox, its touched row band(s), the adjacent
#        SW interval, and the other cached canonical ISO objects in that interval.
#        This preserves the same R1 keeper policy and R2 rule without global scan.
proc TT_SDP_PGROW_group_legal {group} {
    if {!$::TT_SDP_PGROW_SWITCH_CACHE_READY} { TT_SDP_PGROW__refresh_switch_cache }
    if {!$::TT_SDP_PGROW_ENDCAP_CACHE_READY} { TT_SDP_PGROW__refresh_endcap_cache }
    if {!$::TT_SDP_PGROW_ISO_CACHE_READY} { TT_SDP_PGROW__refresh_iso_cache }

    if {![dict exists $::TT_SDP_PGROW_ISO_OBJ_CACHE $group]} { return 0 }

    lassign [dict get $::TT_SDP_PGROW_ISO_OBJ_CACHE $group] cell pd
    set cb ""
    catch {set cb [TT_SDP_PGROW__rect4 [get_db $cell .bbox]]}
    if {[llength $cb] != 4} { return 0 }

    set slot [TT_SDP_PGROW__slot_for_bbox $pd $cb]
    if {![dict get $slot ok]} { return 0 }
    set key [dict get $slot slot_key]

    set occupants {}
    foreach irec [TT_SDP_PGROW__iso_records] {
        lassign $irec ogroup ocell opd ob
        if {$opd ne $pd} { continue }
        set oslot [TT_SDP_PGROW__slot_for_bbox $opd $ob]
        if {![dict get $oslot ok]} { continue }
        if {[dict get $oslot slot_key] eq $key} {
            lappend occupants $ogroup
        }
    }
    set occupants [lsort -dictionary -unique $occupants]
    if {[llength $occupants] <= 1} { return 1 }

    # Preserve an existing pre-repair keeper if it still occupies this slot.
    if {[info exists ::TT_SDP_PGROW_LAST_SCAN] &&
        [dict exists $::TT_SDP_PGROW_LAST_SCAN keeper_groups]} {
        foreach kg [dict get $::TT_SDP_PGROW_LAST_SCAN keeper_groups] {
            if {[lsearch -exact $occupants $kg] >= 0} {
                return [expr {$group eq $kg}]
            }
        }
    }

    # If several MOVERS collide in a previously empty slot, accept at most one
    # deterministic/current best keeper; the others remain unresolved.
    set keeper [TT_SDP_PGROW__choose_keeper \
        $occupants [dict get $slot left_x2] [dict get $slot right_x1]]
    return [expr {$group eq $keeper}]
}


# -----------------------------------------------------------------------------
# V2.2 checkpoint visualization.
# Mark ONLY the center ISO/CELL of current PGROW repair_groups.
# No placement/status/SDP/blockage mutation is performed.
# -----------------------------------------------------------------------------
proc TT_SDP_PGROW_clear_highlight {} {
    catch {gui_clear_highlight}
    catch {deselect_obj -all}
    catch {gui_redraw}
    return true
}

proc TT_SDP_PGROW_highlight_bad {{scan_result ""}} {
    if {$scan_result eq ""} {
        set scan_result [TT_SDP_PGROW_scan false]
    }
    if {![dict exists $scan_result repair_groups]} {
        error "TT_SDP_PGROW_highlight_bad: scan result has no repair_groups"
    }

    TT_SDP_PGROW_clear_highlight
    set bad [dict get $scan_result repair_groups]
    set marked 0
    set failed 0
    set names {}

    foreach g $bad {
        if {![dict exists $::TT_SDP_PGROW_ISO_OBJ_CACHE $g]} {
            puts "WARN: PGROW highlight cannot resolve '$g' in ISO cache."
            incr failed
            continue
        }

        lassign [dict get $::TT_SDP_PGROW_ISO_OBJ_CACHE $g] cell pd
        set cname ""
        catch {set cname [get_db $cell .name]}

        set ok 0
        if {[llength [info commands gui_highlight]] > 0} {
            if {![catch {gui_highlight -index 1 $cell}]} {
                set ok 1
            }
        }
        if {!$ok && [llength [info commands select_obj]] > 0} {
            if {![catch {select_obj $cell}]} {
                set ok 1
            }
        }

        if {$ok} {
            incr marked
            lappend names $cname
        } else {
            incr failed
            puts "WARN: PGROW highlight failed for group=$g cell=$cname pd=$pd"
        }
    }

    catch {gui_redraw}
    puts "INFO: PGROW bad-cell highlight: requested=[llength $bad] marked=$marked failed=$failed"
    return [dict create requested [llength $bad] marked $marked failed $failed names $names]
}

proc TT_SDP_PGROW__ensure_slot_repair_tool {} {
    if {[llength [info commands TT_repair_powergate_iso_slots]] > 0} { return true }
    set f [file join $::TECH_MV_RUNTIME_ROOT .. script PR TECH_MV script 02_powerplan sdp repair_powergate_iso_slots.tcl]
    if {![file isfile $f]} {
        error "Required PGROW slot-repair helper is missing: $f"
    }
    source -quiet $f
    if {[llength [info commands TT_repair_powergate_iso_slots]] == 0} {
        error "PGROW slot-repair helper did not define TT_repair_powergate_iso_slots: $f"
    }
    return true
}

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
    if {[llength [info commands tech_mv_checkpoint_tools]]} { tech_mv_checkpoint_tools {02_powerplan} {TT_sdp_powergate_row_rules} }
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

puts "INFO: Loaded TT_sdp_powergate_row_rules.tcl - $::TT_SDP_PGROW_VERSION"
puts "INFO: CHECK : TT_SDP_PGROW_scan true"
puts "INFO: GUI   : TT_SDP_PGROW_highlight_bad / TT_SDP_PGROW_clear_highlight"
puts "INFO: REPAIR: TT_SDP_PGROW_repair  (compact operator UI; no dict dump)"
puts "INFO: BLK   : whole-row NOSW blockages RETIRED; cleanup remains backward-compatible"
