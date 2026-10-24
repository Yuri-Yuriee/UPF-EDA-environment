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
# add_well_taps.tcl
# =============================================================================
# TECH_MV WellTap insertion
#
# Policy:
#   1. Add dedicated configured library cell cells immediately INSIDE LEFT/RIGHT
#      per-Power-Domain EndCaps when a legal site is available.
#   2. If the adjacent site is occupied, search inward on the FinFET/site grid.
#   3. Never move/delete an EndCap or Power Switch.
#   4. Keep every boundary WellTap fully inside the same physical Power Domain.
#   5. Then run the normal per-Power-Domain checkerboard WellTap insertion with
#      the globally configured denser WellTap interval.
#
# Intended call point:
#   EndCaps -> Power Switches -> EndCap/SW overlap cleanup/checkpoint
#   -> THIS SCRIPT -> remaining Stage-01 floorplan tail
#
# This script intentionally does NOT modify PD_blk_outer, filler, IO PAD,
# routing, stream-out, or Power-Switch placement.
# =============================================================================

puts "User script [info script]"
puts "INFO: TECH_MV WellTap V6 = true-PD boundary every-row + 40.0um interior checkerboard"

# -----------------------------------------------------------------------------
# Local WellTap policy
# -----------------------------------------------------------------------------
# IMPORTANT:
#   This V5 script intentionally does NOT require any new variables to be added
#   to build_PR/setup/config/01_floorplan.config.tcl.
#
#   The user's repaired Floorplan/config flow is authoritative and untouched.
#   Existing Floorplan values are read when available; TECH_MV-safe fallbacks
#   are used only for this script when a value is absent.
#
# Normal/interior WellTap:
#   - configured library cell
#   - insertion interval configured by TECH_WT_INTERVAL
#   - checkerboard
#
# Dedicated true-PD-boundary WellTap:
#   - EVERY eligible row/endcap endpoint
#   - NON-CHECKERBOARD
#   - direct create_inst
#   - only on the actual PD-interior side
#   - hard-macro placement halo is forbidden
# -----------------------------------------------------------------------------
set TECH_WT_CELL                  [::tech_mv_library_value LIB_CELL_002]
set TECH_WT_INTERVAL              [::tech_mv_private_value {welltap::normal_interval}]
set TECH_WT_PREFIX                WELLTAP

set TECH_BWT_ENABLE               true
set TECH_BWT_PREFIX               PD_BWT
set TECH_BWT_MAX_SEARCH_SITES     32
set TECH_BWT_FALLBACK_SITE_PITCH  [::tech_mv_private_value {welltap::fallback_site_pitch}]
set TECH_BWT_TOL                  0.0005
set TECH_BWT_PATTERN              EVERY_ROW

# Use the repaired/current Floorplan EndCap definitions if they exist.
if {[info exists ::ENDCAP_POWER_DOMAIN_PREFIX] && $::ENDCAP_POWER_DOMAIN_PREFIX ne ""} {
    set TECH_ENDCAP_PD_PREFIX $::ENDCAP_POWER_DOMAIN_PREFIX
} else {
    set TECH_ENDCAP_PD_PREFIX ENDCAP_PD
}

if {[info exists ::ENDCAP_LEFT_EDGE_CELLS] && [llength $::ENDCAP_LEFT_EDGE_CELLS] > 0} {
    set TECH_ENDCAP_LEFT_EDGE_CELLS $::ENDCAP_LEFT_EDGE_CELLS
} else {
    set TECH_ENDCAP_LEFT_EDGE_CELLS [::tech_mv_library_value LIB_CELL_010]
}

if {[info exists ::ENDCAP_RIGHT_EDGE_CELLS] && [llength $::ENDCAP_RIGHT_EDGE_CELLS] > 0} {
    set TECH_ENDCAP_RIGHT_EDGE_CELLS $::ENDCAP_RIGHT_EDGE_CELLS
} else {
    set TECH_ENDCAP_RIGHT_EDGE_CELLS [::tech_mv_library_value LIB_CELL_011]
}

# Use the actual repaired Floorplan macro halo when available.
if {[info exists ::MACRO_PLACE_HALO] && [llength $::MACRO_PLACE_HALO] == 4} {
    set TECH_MACRO_PLACE_HALO $::MACRO_PLACE_HALO
} else {
    set TECH_MACRO_PLACE_HALO [::tech_mv_private_value {welltap::fallback_macro_halo}]
}

puts "INFO: TECH_MV WellTap local policy"
puts "INFO:   normal cell/interval = $TECH_WT_CELL / $TECH_WT_INTERVAL um"
puts "INFO:   boundary pattern     = $TECH_BWT_PATTERN (NON-CHECKERBOARD)"
puts "INFO:   PD EndCap prefix     = $TECH_ENDCAP_PD_PREFIX"
puts "INFO:   macro place halo     = $TECH_MACRO_PLACE_HALO"

# -----------------------------------------------------------------------------
# Safe get_db helper.
# -----------------------------------------------------------------------------
proc tech_wt_get {obj attr {default ""}} {
    set v $default
    catch {set v [get_db $obj $attr]}
    return $v
}

# Normalize a DB rectangle to {llx lly urx ury}.
proc tech_wt_norm_rect {raw} {
    if {[catch {set n [llength $raw]}]} {
        return ""
    }

    while {$n == 1} {
        set one [lindex $raw 0]
        if {[catch {set n2 [llength $one]}]} {
            break
        }
        if {$n2 == 4} {
            set raw $one
            set n 4
            break
        }
        if {$n2 <= 1} {
            break
        }
        set raw $one
        set n $n2
    }

    if {$n != 4} {
        return ""
    }

    lassign $raw llx lly urx ury
    foreach v [list $llx $lly $urx $ury] {
        if {![string is double -strict $v]} {
            return ""
        }
    }

    set llx [expr {double($llx)}]
    set lly [expr {double($lly)}]
    set urx [expr {double($urx)}]
    set ury [expr {double($ury)}]

    if {$llx > $urx} {
        set t $llx
        set llx $urx
        set urx $t
    }
    if {$lly > $ury} {
        set t $lly
        set lly $ury
        set ury $t
    }

    if {$llx >= $urx || $lly >= $ury} {
        return ""
    }

    return [list $llx $lly $urx $ury]
}

proc tech_wt_positive_overlap {a b tol} {
    set a [tech_wt_norm_rect $a]
    set b [tech_wt_norm_rect $b]
    if {$a eq "" || $b eq ""} {
        return 0
    }

    lassign $a allx ally aurx aury
    lassign $b bllx blly burx bury

    set dx [expr {min($aurx,$burx) - max($allx,$bllx)}]
    set dy [expr {min($aury,$bury) - max($ally,$blly)}]
    return [expr {$dx > $tol && $dy > $tol}]
}

proc tech_wt_unique_sorted_numbers {values tol} {
    set result {}
    foreach v [lsort -real $values] {
        if {[llength $result] == 0 ||
            abs($v - [lindex $result end]) > $tol} {
            lappend result $v
        }
    }
    return $result
}

# Return true only when target_bbox is fully covered by the UNION of all
# rectangles belonging to one physical Power Domain.
proc tech_wt_bbox_in_rect_union {target_bbox rects tol} {
    set target_bbox [tech_wt_norm_rect $target_bbox]
    if {$target_bbox eq "" || [llength $rects] == 0} {
        return 0
    }

    lassign $target_bbox tllx tlly turx tury
    set clipped {}
    set x_edges [list $tllx $turx]

    foreach raw $rects {
        set r [tech_wt_norm_rect $raw]
        if {$r eq ""} {
            continue
        }

        lassign $r rllx rlly rurx rury
        set cllx [expr {max($tllx,$rllx)}]
        set clly [expr {max($tlly,$rlly)}]
        set curx [expr {min($turx,$rurx)}]
        set cury [expr {min($tury,$rury)}]

        if {$cllx < ($curx - $tol) && $clly < ($cury - $tol)} {
            lappend clipped [list $cllx $clly $curx $cury]
            lappend x_edges $cllx $curx
        }
    }

    if {[llength $clipped] == 0} {
        return 0
    }

    set x_edges [tech_wt_unique_sorted_numbers $x_edges $tol]

    for {set i 0} {$i < [expr {[llength $x_edges]-1}]} {incr i} {
        set x0 [lindex $x_edges $i]
        set x1 [lindex $x_edges [expr {$i+1}]]

        if {($x1-$x0) <= $tol} {
            continue
        }

        set xm [expr {($x0+$x1)/2.0}]
        set intervals {}

        foreach r $clipped {
            lassign $r rllx rlly rurx rury
            if {$xm >= ($rllx-$tol) && $xm <= ($rurx+$tol)} {
                lappend intervals [list $rlly $rury]
            }
        }

        if {[llength $intervals] == 0} {
            return 0
        }

        set intervals [lsort -real -index 0 $intervals]
        set cover_low ""
        set cover_high ""

        foreach iv $intervals {
            lassign $iv y0 y1
            if {$cover_low eq ""} {
                set cover_low $y0
                set cover_high $y1
                continue
            }

            if {$y0 <= ($cover_high+$tol)} {
                if {$y1 > $cover_high} {
                    set cover_high $y1
                }
            } else {
                if {$cover_low <= ($tlly+$tol) &&
                    $cover_high >= ($tury-$tol)} {
                    break
                }
                set cover_low $y0
                set cover_high $y1
            }
        }

        if {$cover_low eq "" ||
            $cover_low > ($tlly+$tol) ||
            $cover_high < ($tury-$tol)} {
            return 0
        }
    }

    return 1
}

proc tech_wt_rect_area_sum {rects} {
    set a 0.0
    foreach raw $rects {
        set r [tech_wt_norm_rect $raw]
        if {$r eq ""} {
            continue
        }
        lassign $r llx lly urx ury
        set a [expr {$a + ($urx-$llx)*($ury-$lly)}]
    }
    return $a
}

# Gather physical PD rectangles from Innovus groups.
# Returns:
#   {pd_order <list> pd_rects <dict>}
proc tech_wt_collect_pd_geometry {} {
    set order {}
    set d [dict create]

    foreach g [get_db groups] {
        set pd [tech_wt_get $g .power_domain.name ""]
        if {$pd eq ""} {
            continue
        }

        set raw [tech_wt_get $g .rects {}]
        set rs {}

        # A single rectangle may be returned flat.
        set one [tech_wt_norm_rect $raw]
        if {$one ne ""} {
            lappend rs $one
        } else {
            foreach x $raw {
                set r [tech_wt_norm_rect $x]
                if {$r ne ""} {
                    lappend rs $r
                }
            }
        }

        if {[llength $rs] == 0} {
            continue
        }

        if {![dict exists $d $pd]} {
            lappend order $pd
            dict set d $pd {}
        }

        set cur [dict get $d $pd]
        foreach r $rs {
            if {[lsearch -exact $cur $r] < 0} {
                lappend cur $r
            }
        }
        dict set d $pd $cur
    }

    return [dict create pd_order $order pd_rects $d]
}

# Resolve the physical PD for an EndCap. Direct DB power-domain attributes are
# preferred; geometry is the safe fallback. When nested PDs both geometrically
# contain the object, the smallest physical-domain area wins.
proc tech_wt_resolve_pd {inst pd_rects tol} {
    foreach attr {.power_domain.name .parent.power_domain.name} {
        set pd [tech_wt_get $inst $attr ""]
        if {$pd ne "" && [dict exists $pd_rects $pd]} {
            return $pd
        }
    }

    set b [tech_wt_norm_rect [tech_wt_get $inst .bbox {}]]
    if {$b eq ""} {
        return ""
    }

    set best ""
    set best_area 1.0e99

    dict for {pd rects} $pd_rects {
        if {![tech_wt_bbox_in_rect_union $b $rects $tol]} {
            continue
        }

        set a [tech_wt_rect_area_sum $rects]
        if {$a < $best_area} {
            set best $pd
            set best_area $a
        }
    }

    return $best
}

proc tech_wt_site_pitch_x {} {
    set pitch $::TECH_BWT_FALLBACK_SITE_PITCH
    set grid {}
    catch {set grid [get_db floorplan_finfet_inst_grid]}

    if {[llength $grid] >= 4 &&
        [string is double -strict [lindex $grid 2]] &&
        [lindex $grid 2] > 0} {
        set pitch [expr {double([lindex $grid 2])}]
    }

    return $pitch
}

proc tech_wt_orient_to_location {bbox orient} {
    set bbox [tech_wt_norm_rect $bbox]
    if {$bbox eq ""} {
        return ""
    }

    lassign $bbox llx lly urx ury
    set o [string tolower $orient]

    switch -- $o {
        r0 {
            return [list $llx $lly]
        }
        mx {
            return [list $llx $ury]
        }
        my {
            return [list $urx $lly]
        }
        r180 {
            return [list $urx $ury]
        }
        default {
            return ""
        }
    }
}

# Check occupancy using actual positive bbox overlap.
# Return:
#   CLEAR
#   COVERED       an existing configured library cell already occupies the site
#   BLOCKED       another instance occupies the site
proc tech_wt_candidate_state {bbox tap_cell tol} {
    set objs {}
    if {[catch {
        set objs [get_obj_in_area -area $bbox -obj_type inst -overlap_only]
    } err]} {
        error "TECH_MV WellTap: get_obj_in_area failed for bbox=$bbox : $err"
    }

    set saw_tap 0
    set saw_other 0

    foreach obj $objs {
        set ob [tech_wt_norm_rect [tech_wt_get $obj .bbox {}]]
        if {$ob eq "" || ![tech_wt_positive_overlap $bbox $ob $tol]} {
            # Touching the EndCap edge is legal; only positive-area overlap
            # blocks the candidate.
            continue
        }

        set master [tech_wt_get $obj .base_cell.name ""]
        if {$master eq $tap_cell} {
            set saw_tap 1
        } else {
            set saw_other 1
        }
    }

    if {$saw_other} {
        return BLOCKED
    }
    if {$saw_tap} {
        return COVERED
    }
    return CLEAR
}

proc tech_wt_next_leaf_name {parent pd side seq} {
    set clean_pd $pd
    regsub -all {[^A-Za-z0-9_]} $clean_pd {_} clean_pd

    set base "${::TECH_BWT_PREFIX}_${clean_pd}_${side}_${seq}"
    set leaf $base
    set suffix 0

    set parent_name [tech_wt_get $parent .name ""]
    while {1} {
        if {$parent_name eq ""} {
            set full $leaf
        } else {
            set full "${parent_name}/${leaf}"
        }

        set exists {}
        catch {set exists [get_db insts $full]}
        if {[llength $exists] == 0} {
            return $leaf
        }

        incr suffix
        set leaf "${base}_${suffix}"
    }
}

# -----------------------------------------------------------------------------
# Hard-Macro placement halo exclusion.
# -----------------------------------------------------------------------------
proc tech_wt_collect_macro_halos {} {
    if {![info exists ::TECH_MACRO_PLACE_HALO] ||
        [llength $::TECH_MACRO_PLACE_HALO] != 4} {
        error "TECH_MV WellTap: internal macro halo policy is invalid."
    }

    lassign $::TECH_MACRO_PLACE_HALO halo_left halo_bottom halo_right halo_top
    foreach v [list $halo_left $halo_bottom $halo_right $halo_top] {
        if {![string is double -strict $v]} {
            error "TECH_MV WellTap: invalid macro halo value '$v'."
        }
    }

    set halos {}
    foreach inst [get_db insts -if {
        .base_cell.base_class == block &&
        .is_pad == false
    }] {
        set b [tech_wt_norm_rect [tech_wt_get $inst .bbox {}]]
        if {$b eq ""} {
            continue
        }

        lassign $b llx lly urx ury
        lappend halos [list \
            [expr {$llx-double($halo_left)}] \
            [expr {$lly-double($halo_bottom)}] \
            [expr {$urx+double($halo_right)}] \
            [expr {$ury+double($halo_top)}] \
        ]
    }

    return $halos
}

proc tech_wt_bbox_hits_any {bbox rects tol} {
    foreach r $rects {
        if {[tech_wt_positive_overlap $bbox $r $tol]} {
            return 1
        }
    }
    return 0
}

# Classify a horizontal EndCap by actual Power-Domain geometry, not by master
# name alone.
#
# Return:
#   {1 LEFT  <probe>}   -> PD interior is on the LEFT side of EndCap
#   {1 RIGHT <probe>}   -> PD interior is on the RIGHT side of EndCap
#   {0 INTERNAL ""}     -> both sides are inside PD (macro/halo/internal row cut)
#   {0 OUTSIDE  ""}     -> neither side is a legal PD interior probe
proc tech_wt_classify_pd_boundary {endcap_bbox pd_rects tap_w tap_h tol} {
    set b [tech_wt_norm_rect $endcap_bbox]
    if {$b eq ""} {
        return [list 0 OUTSIDE ""]
    }

    lassign $b llx lly urx ury

    set left_probe  [list [expr {$llx-$tap_w}] $lly $llx [expr {$lly+$tap_h}]]
    set right_probe [list $urx $lly [expr {$urx+$tap_w}] [expr {$lly+$tap_h}]]

    set left_in  [tech_wt_bbox_in_rect_union $left_probe  $pd_rects $tol]
    set right_in [tech_wt_bbox_in_rect_union $right_probe $pd_rects $tol]

    if {$left_in && !$right_in} {
        return [list 1 LEFT $left_probe]
    }
    if {$right_in && !$left_in} {
        return [list 1 RIGHT $right_probe]
    }
    if {$left_in && $right_in} {
        return [list 0 INTERNAL ""]
    }

    return [list 0 OUTSIDE ""]
}

# -----------------------------------------------------------------------------
# Dedicated LEFT/RIGHT Power-Domain boundary WellTaps.
# -----------------------------------------------------------------------------
proc tech_wt_add_pd_boundary_taps {pd_info} {
    if {!$::TECH_BWT_ENABLE} {
        puts "INFO: PD boundary WellTap insertion is disabled."
        return [dict create \
            candidates 0 \
            true_boundary 0 \
            internal_skipped 0 \
            outside_skipped 0 \
            macro_halo_rejected 0 \
            covered 0 \
            inserted 0 \
            unresolved 0]
    }

    set pd_rects [dict get $pd_info pd_rects]

    set tap_base [get_db base_cells $::TECH_WT_CELL]
    if {[llength $tap_base] != 1} {
        error "TECH_MV WellTap: expected one base cell '$::TECH_WT_CELL', got: $tap_base"
    }
    set tap_base [lindex $tap_base 0]

    set tap_bbox [tech_wt_norm_rect [tech_wt_get $tap_base .bbox {}]]
    if {$tap_bbox eq ""} {
        error "TECH_MV WellTap: cannot read bbox of $::TECH_WT_CELL."
    }

    lassign $tap_bbox bllx blly burx bury
    if {abs($bllx) > $::TECH_BWT_TOL || abs($blly) > $::TECH_BWT_TOL} {
        error "TECH_MV WellTap: $::TECH_WT_CELL base-cell bbox does not start at {0 0}: $tap_bbox"
    }

    set tap_w [expr {$burx-$bllx}]
    set tap_h [expr {$bury-$blly}]
    set pitch [tech_wt_site_pitch_x]
    set macro_halos [tech_wt_collect_macro_halos]

    puts ""
    puts "======================================================================"
    puts " TRUE PD-BOUNDARY WELLTAP INSERTION"
    puts "======================================================================"
    puts "Cell                 : $::TECH_WT_CELL"
    puts "Boundary pattern     : $::TECH_BWT_PATTERN (NON-CHECKERBOARD)"
    puts "Search pitch X       : $pitch"
    puts "Max search sites     : $::TECH_BWT_MAX_SEARCH_SITES"
    puts "Hard-macro halos     : [llength $macro_halos]"
    puts "Macro halo config    : $::TECH_MACRO_PLACE_HALO"
    puts "PD EndCap prefix     : $::TECH_ENDCAP_PD_PREFIX"
    puts "Eligible edge masters: $::TECH_ENDCAP_LEFT_EDGE_CELLS $::TECH_ENDCAP_RIGHT_EDGE_CELLS"
    puts ""
    puts "Boundary rule:"
    puts "  EVERY eligible true-PD-boundary row is processed."
    puts "  Boundary placement uses direct create_inst only; no checkerboard."
    puts "  exactly ONE adjacent tap-sized side must be inside the same PD."
    puts "  both sides inside PD  => internal row-cut/macro-halo EndCap, SKIP."
    puts "  neither side inside   => unresolved geometry, SKIP."
    puts "======================================================================"

    set records {}
    set seen [dict create]

    set candidates 0
    set true_boundary 0
    set internal_skipped 0
    set outside_skipped 0
    set macro_halo_rejected 0

    foreach inst [get_db insts] {
        set inst_name [tech_wt_get $inst .name ""]
        if {$inst_name eq "" ||
            ![string match "*${::ENDCAP_POWER_DOMAIN_PREFIX}*" $inst_name]} {
            continue
        }

        set master [tech_wt_get $inst .base_cell.name ""]
        if {[lsearch -exact $::TECH_ENDCAP_LEFT_EDGE_CELLS $master] < 0 &&
            [lsearch -exact $::TECH_ENDCAP_RIGHT_EDGE_CELLS $master] < 0} {
            continue
        }

        incr candidates

        set eb [tech_wt_norm_rect [tech_wt_get $inst .bbox {}]]
        if {$eb eq ""} {
            incr outside_skipped
            continue
        }

        set pd [tech_wt_resolve_pd $inst $pd_rects $::TECH_BWT_TOL]
        if {$pd eq "" || ![dict exists $pd_rects $pd]} {
            incr outside_skipped
            puts "WARNING: PD boundary WellTap: cannot resolve physical PD for $inst_name; skip."
            continue
        }

        set cls [tech_wt_classify_pd_boundary \
            $eb [dict get $pd_rects $pd] $tap_w $tap_h $::TECH_BWT_TOL]

        lassign $cls is_boundary inside_dir immediate_probe

        if {!$is_boundary} {
            if {$inside_dir eq "INTERNAL"} {
                incr internal_skipped
            } else {
                incr outside_skipped
            }
            continue
        }

        incr true_boundary

        # The physical PD edge side is opposite to the direction of its interior.
        if {$inside_dir eq "RIGHT"} {
            set edge_side LEFT
        } else {
            set edge_side RIGHT
        }

        lassign $eb ellx elly eurx eury
        if {$edge_side eq "LEFT"} {
            set edge $ellx
        } else {
            set edge $eurx
        }

        set key [format "%s|%s|%.4f|%.4f" $pd $edge_side $elly $edge]
        if {[dict exists $seen $key]} {
            continue
        }
        dict set seen $key 1

        lappend records [list $inst $pd $edge_side $inside_dir $eb]
    }

    set covered 0
    set inserted 0
    set unresolved 0
    set seq 0

    foreach rec $records {
        lassign $rec endcap pd edge_side inside_dir eb

        set endcap_name [tech_wt_get $endcap .name "<unknown>"]
        set orient [tech_wt_get $endcap .orient ""]
        set parent [tech_wt_get $endcap .parent ""]
        if {$parent eq ""} {
            set parent [get_db current_design]
        }

        lassign $eb ellx elly eurx eury

        set solved 0
        for {set step 0} {$step <= $::TECH_BWT_MAX_SEARCH_SITES} {incr step} {
            set delta [expr {$step*$pitch}]

            if {$inside_dir eq "RIGHT"} {
                set cllx [expr {$eurx+$delta}]
                set curx [expr {$cllx+$tap_w}]
            } else {
                set curx [expr {$ellx-$delta}]
                set cllx [expr {$curx-$tap_w}]
            }

            set clly $elly
            set cury [expr {$clly+$tap_h}]
            set cb [list $cllx $clly $curx $cury]

            # Must stay completely in the same physical PD.
            if {![tech_wt_bbox_in_rect_union \
                    $cb [dict get $pd_rects $pd] $::TECH_BWT_TOL]} {
                continue
            }

            # Must never enter a hard-macro placement halo.
            if {[tech_wt_bbox_hits_any $cb $macro_halos $::TECH_BWT_TOL]} {
                incr macro_halo_rejected
                continue
            }

            set state [tech_wt_candidate_state \
                $cb $::TECH_WT_CELL $::TECH_BWT_TOL]

            if {$state eq "COVERED"} {
                incr covered
                set solved 1
                puts "INFO: True PD-boundary WellTap already covered: PD=$pd edge=$edge_side endcap=$endcap_name bbox=$cb"
                break
            }

            if {$state eq "BLOCKED"} {
                continue
            }

            set loc [tech_wt_orient_to_location $cb $orient]
            if {$loc eq ""} {
                puts "WARNING: PD boundary WellTap: unsupported EndCap orientation '$orient' for $endcap_name."
                break
            }

            incr seq
            set leaf [tech_wt_next_leaf_name $parent $pd $edge_side $seq]

            set new_inst ""
            if {[catch {
                set new_inst [create_inst \
                    -base_cell $tap_base \
                    -name $leaf \
                    -parent $parent \
                    -location $loc \
                    -orient $orient \
                    -physical \
                    -place_status fixed]
            } err]} {
                puts "WARNING: True PD-boundary WellTap create failed: PD=$pd edge=$edge_side endcap=$endcap_name site=$step error={$err}"
                continue
            }

            if {[llength $new_inst] > 0} {
                set new_inst [lindex $new_inst 0]
                set actual [tech_wt_norm_rect [tech_wt_get $new_inst .bbox {}]]

                if {$actual eq "" ||
                    ![tech_wt_bbox_in_rect_union \
                        $actual [dict get $pd_rects $pd] $::TECH_BWT_TOL] ||
                    [tech_wt_bbox_hits_any \
                        $actual $macro_halos $::TECH_BWT_TOL]} {
                    catch {delete_obj $new_inst}
                    puts "WARNING: PD-boundary WellTap post-create geometry validation failed; removed $leaf."
                    continue
                }
            }

            incr inserted
            set solved 1
            puts "INFO: True PD-boundary WellTap inserted: PD=$pd edge=$edge_side inside=$inside_dir endcap=$endcap_name name=$leaf search_site=$step bbox=$cb"
            break
        }

        if {!$solved} {
            incr unresolved
            puts "WARNING: No legal true-PD-boundary WellTap site found: PD=$pd edge=$edge_side inside=$inside_dir endcap=$endcap_name"
        }
    }

    puts ""
    puts "======================================================================"
    puts " TRUE PD-BOUNDARY WELLTAP SUMMARY"
    puts "======================================================================"
    puts "PD EndCap candidates   : $candidates"
    puts "True PD boundaries     : $true_boundary"
    puts "Internal row-cut skip  : $internal_skipped"
    puts "Outside/unresolved skip: $outside_skipped"
    puts "Macro-halo rejects     : $macro_halo_rejected"
    puts "Already covered        : $covered"
    puts "Inserted               : $inserted"
    puts "Unresolved true edges  : $unresolved"
    puts "======================================================================"

    return [dict create \
        candidates $candidates \
        true_boundary $true_boundary \
        internal_skipped $internal_skipped \
        outside_skipped $outside_skipped \
        macro_halo_rejected $macro_halo_rejected \
        covered $covered \
        inserted $inserted \
        unresolved $unresolved]
}

# -----------------------------------------------------------------------------
# Guard against accidental double insertion from a post-WellTap DB.
# The normal intended entry is the saved checkpoint immediately before
# WellTap insertion.
# -----------------------------------------------------------------------------
set _tech_existing_generated 0
foreach _tech_i [get_db insts] {
    set _tech_n [tech_wt_get $_tech_i .name ""]
    if {[string match "*WELLTAP_PD_*" $_tech_n] ||
        [string match "*PD_BWT_*" $_tech_n]} {
        incr _tech_existing_generated
    }
}
if {$_tech_existing_generated > 0} {
    error "TECH_MV WellTap: found $_tech_existing_generated previously generated WELLTAP_PD_/PD_BWT_ instance(s). Restore the pre-WellTap checkpoint before re-running this script."
}
unset _tech_i
unset _tech_n
unset _tech_existing_generated

# -----------------------------------------------------------------------------
# Build physical PD geometry once and place dedicated boundary taps first.
# -----------------------------------------------------------------------------
set _tech_pd_info [tech_wt_collect_pd_geometry]
set _tech_pd_order [dict get $_tech_pd_info pd_order]

if {[llength $_tech_pd_order] == 0} {
    error "TECH_MV WellTap: no physical Power Domain geometry found in Innovus groups."
}

set _tech_bwt_result [tech_wt_add_pd_boundary_taps $_tech_pd_info]

# -----------------------------------------------------------------------------
# Normal globally denser INTERIOR WellTap insertion.
#
# Checkerboard applies ONLY to this normal interior pass.
# Dedicated true-PD-boundary WellTaps above are EVERY_ROW / NON-CHECKERBOARD.
# -----------------------------------------------------------------------------
puts ""
puts "======================================================================"
puts " NORMAL POWER-DOMAIN WELLTAP INSERTION"
puts "======================================================================"
puts "Cell          : $TECH_WT_CELL"
puts "Cell interval : $TECH_WT_INTERVAL um"
puts "Pattern       : checkerboard (INTERIOR PASS ONLY)"
puts "Power Domains : $_tech_pd_order"
puts "======================================================================"

# Keep the DB mode consistent with the explicit insertion policy.
set_db add_well_taps_cell $TECH_WT_CELL
set_db add_well_taps_rule $TECH_WT_INTERVAL

foreach _tech_pd $_tech_pd_order {
    set _tech_clean_pd $_tech_pd
    regsub -all {[^A-Za-z0-9_]} $_tech_clean_pd {_} _tech_clean_pd
    set _tech_prefix "${TECH_WT_PREFIX}_${_tech_clean_pd}"

    puts "INFO: WellTap insertion for Power Domain = $_tech_pd"
    add_well_taps \
        -cell $TECH_WT_CELL \
        -cell_interval $TECH_WT_INTERVAL \
        -power_domain $_tech_pd \
        -prefix $_tech_prefix \
        -checker_board
}

puts ""
puts "INFO: Running check_place after PD-boundary + normal WellTap insertion."
if {[llength [info commands check_place]] > 0} {
    check_place
} elseif {[llength [info commands checkPlace]] > 0} {
    checkPlace
} else {
    puts "WARNING: check_place/checkPlace command is unavailable."
}

# -----------------------------------------------------------------------------
# Marker-driven overlap cleanup.
#
# add_well_taps.tcl has just refreshed check_place markers above.  Reuse
# those markers to remove ONLY configured library cell instances that are explicitly
# attached to check_place SPOverlapViolation markers.  The cleanup tool performs
# its own post-delete check_place/re-scan.
# -----------------------------------------------------------------------------
if {[info exists ::ENABLE_REMOVE_OVERLAP_WELLTAP] && $::ENABLE_REMOVE_OVERLAP_WELLTAP} {
    set _tech_owt_tool [file join $::TECH_MV_RUNTIME_ROOT .. script PR TECH_MV script 01_floorplan endcap_welltap proc_remove_overlap_welltap.tcl]
    if {![file isfile $_tech_owt_tool]} {
        error "Overlap-WellTap cleanup tool not found: $_tech_owt_tool"
    }

    puts "INFO: Running marker-driven overlap-WellTap cleanup."
    uplevel #0 [list source -quiet $_tech_owt_tool]
    set _tech_owt_result [TT_remove_overlap_welltaps -apply -no_check]
    puts "INFO: Overlap-WellTap cleanup deleted [dict get $_tech_owt_result deleted_count] instance(s); remaining overlap WellTaps = [dict get $_tech_owt_result overlap_welltap_after]."

    unset _tech_owt_result
    unset _tech_owt_tool
} else {
    puts "INFO: Overlap-WellTap cleanup is disabled by ENABLE_REMOVE_OVERLAP_WELLTAP."
}

puts ""
puts "======================================================================"
puts " TECH_MV WELLTAP INSERTION COMPLETE"
puts "======================================================================"
puts "Boundary pattern      : $TECH_BWT_PATTERN (NON-CHECKERBOARD)"
puts "Normal interval       : $TECH_WT_INTERVAL um"
puts "Normal pattern        : checkerboard (INTERIOR ONLY)"
puts "Boundary candidates   : [dict get $_tech_bwt_result candidates]"
puts "True PD boundaries    : [dict get $_tech_bwt_result true_boundary]"
puts "Internal row-cut skip : [dict get $_tech_bwt_result internal_skipped]"
puts "Macro-halo rejects    : [dict get $_tech_bwt_result macro_halo_rejected]"
puts "Boundary covered      : [dict get $_tech_bwt_result covered]"
puts "Boundary inserted     : [dict get $_tech_bwt_result inserted]"
puts "Boundary unresolved   : [dict get $_tech_bwt_result unresolved]"
puts "PD_blk_outer          : untouched (must remain macro_only)"
puts "Filler flow           : untouched"
puts "======================================================================"

unset _tech_pd
unset _tech_clean_pd
unset _tech_prefix
unset _tech_pd_info
unset _tech_pd_order
unset _tech_bwt_result
unset TECH_WT_CELL
unset TECH_WT_INTERVAL
unset TECH_WT_PREFIX
unset TECH_BWT_ENABLE
unset TECH_BWT_PREFIX
unset TECH_BWT_MAX_SEARCH_SITES
unset TECH_BWT_FALLBACK_SITE_PITCH
unset TECH_BWT_TOL
unset TECH_BWT_PATTERN
unset TECH_ENDCAP_PD_PREFIX
unset TECH_ENDCAP_LEFT_EDGE_CELLS
unset TECH_ENDCAP_RIGHT_EDGE_CELLS
unset TECH_MACRO_PLACE_HALO
