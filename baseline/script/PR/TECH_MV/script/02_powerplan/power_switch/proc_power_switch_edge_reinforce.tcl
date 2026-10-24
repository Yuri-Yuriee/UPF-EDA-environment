# Runtime adapter preserves the historical logical source path.
if {[info exists ::TECH_MV_RUNTIME_ROOT]} {
    info script [file join $::TECH_MV_RUNTIME_ROOT run/tool/02_powerplan/power_switch/TT_proc_power_switch_edge_reinforce.tcl]
} else {
    info script [file normalize [file join [file dirname [info script]] .. .. .. run/tool/02_powerplan/power_switch/TT_proc_power_switch_edge_reinforce.tcl]]
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
# TT_proc_power_switch_edge_reinforce.tcl
#
# TECH_MV ADDITIVE PD-edge Power-Switch reinforcement
# V2.1_EXACT_SW_FOOTPRINT_20261009
#
# CRITICAL POLICY
# ---------------
# The normal add_SW.tcl behavior is NOT replaced:
#
#   existing narrow/wide decision
#   existing checkerboard/non-checkerboard decision
#   existing main Power-Switch placement
#
# remain unchanged.
#
# AFTER the normal SW insertion, this helper:
#
#   1. discovers gated PDs from PD_CFG/POWER_SWITCH_INSTANCE_PREFIXES and requires live main SW instances,
#   2. finds that PD's EndCaps using the exact V5-confirmed leaf-name rule,
#   3. resolves PHYSICAL LEFT/RIGHT from EndCap master + orientation,
#   4. mirrors the runtime-validated WDT golden geometry:
#        LEFT  SW starts at LEFT EndCap x2 and grows +X,
#        RIGHT SW ends   at RIGHT EndCap x1 and grows -X,
#   5. adds one incremental NON-CHECKERBOARD edge strip on BOTH sides.
#
# Runtime validation on the disposable WDT DB confirmed:
#   LEFT: measured EndCap edge and switch-column origin were compared.
#   RIGHT: measured EndCap edge and switch-column origin were compared.
#   Switch width was measured from the authorized runtime library/DB.
#
# Exact EndCap naming rule (confirmed by V5 highlight):
#
#   PD_WDT -> ENDCAP_PD_PD_WDT_PD_WDT_*
#   PD_CPU -> ENDCAP_PD_PD_CPU_PD_CPU_*
#
# IMPORTANT:
# ENDCAP_LEFT_EDGE_CELLS / ENDCAP_RIGHT_EDGE_CELLS are NOT reused here.
# Their add_endcaps API semantics are different from the physical master-side
# meaning observed in the live DB.  This helper defaults to:
#
#   nominal LEFT  master = configured library cell
#   nominal RIGHT master = configured library cell
#
# Instance orientation is then applied exactly like the existing
# TT_delete_followpin_outside_pd_boundary.tcl physical-side rule:
#   r0/mx   -> nominal side unchanged
#   my/r180 -> LEFT/RIGHT swapped
#
# Sourcing this file does not mutate the design; it only defines procedures
# and initializes edge-tool configuration defaults.
# =============================================================================

set ::TT_EDGE_SW_VERSION "V2.1_EXACT_SW_FOOTPRINT_20261009"

if {![info exists ::POWER_SWITCH_EDGE_REINFORCE_ENABLE]} {
    set ::POWER_SWITCH_EDGE_REINFORCE_ENABLE true
}

if {![info exists ::POWER_SWITCH_EDGE_REINFORCE_PITCH]} {
    set ::POWER_SWITCH_EDGE_REINFORCE_PITCH [::tech_mv_private_value {run/tool/02_powerplan/TT_proc_power_switch_edge_reinforce.tcl::::POWER_SWITCH_EDGE_REINFORCE_PITCH::L61}]
}

# V2.1 exact-footprint policy: horizontal gap/padding is zero.
# The variable remains only for backward-compatible setup loading.
if {![info exists ::POWER_SWITCH_EDGE_REINFORCE_GAP]} {
    set ::POWER_SWITCH_EDGE_REINFORCE_GAP [::tech_mv_private_value {run/tool/02_powerplan/TT_proc_power_switch_edge_reinforce.tcl::::POWER_SWITCH_EDGE_REINFORCE_GAP::L67}]
}

proc TT_EDGE_SW__bool {v} {
    set x [string tolower [string trim $v]]
    return [expr {$x in {1 true yes on}}]
}

proc TT_EDGE_SW__get {obj attr {default ""}} {
    set v $default
    catch {set v [get_db $obj $attr]}
    return $v
}

proc TT_EDGE_SW__leaf {name} {
    if {$name eq ""} {
        return ""
    }
    return [lindex [split $name "/"] end]
}

proc TT_EDGE_SW__rect4 {raw} {
    if {[catch {set n [llength $raw]}]} {
        return {}
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
        return {}
    }

    lassign $raw x1 y1 x2 y2

    foreach v [list $x1 $y1 $x2 $y2] {
        if {![string is double -strict $v]} {
            return {}
        }
    }

    set x1 [expr {double($x1)}]
    set y1 [expr {double($y1)}]
    set x2 [expr {double($x2)}]
    set y2 [expr {double($y2)}]

    if {$x1 > $x2} {
        set t $x1
        set x1 $x2
        set x2 $t
    }

    if {$y1 > $y2} {
        set t $y1
        set y1 $y2
        set y2 $t
    }

    if {$x1 >= $x2 || $y1 >= $y2} {
        return {}
    }

    return [list $x1 $y1 $x2 $y2]
}

proc TT_EDGE_SW__sanitize_pd {pd} {
    set clean $pd
    regsub -all {[^[:alnum:]]+} $clean {_} clean
    set clean [string trim $clean {_}]
    if {$clean eq ""} {
        set clean PD
    }
    return $clean
}

proc TT_EDGE_SW__configured_specs {} {
    # Canonical target discovery comes from setup, not a hard-coded PD list.
    # In this TECH flow a gated domain has a non-empty PD_CFG/rail_2nd and a
    # configured POWER_SWITCH_INSTANCE_PREFIXES entry named ${PD}_SW.
    if {![info exists ::PD_CFG]} {
        error "TT_EDGE_SW: PD_CFG is undefined; source init.setup first."
    }
    if {![info exists ::POWER_SWITCH_INSTANCE_PREFIXES]} {
        error "TT_EDGE_SW: POWER_SWITCH_INSTANCE_PREFIXES is undefined; source init.setup first."
    }

    set specs {}
    foreach pd [dict keys $::PD_CFG] {
        if {![dict exists $::PD_CFG $pd rail_2nd]} {
            continue
        }

        set rail_2nd [dict get $::PD_CFG $pd rail_2nd]
        if {[string trim $rail_2nd] eq "" || [llength $rail_2nd] == 0} {
            continue
        }

        set prefix "${pd}_SW"
        if {[lsearch -exact $::POWER_SWITCH_INSTANCE_PREFIXES $prefix] < 0} {
            puts "WARNING: TT_EDGE_SW gated domain $pd has rail_2nd='$rail_2nd' but no configured prefix '$prefix'; skip."
            continue
        }

        if {![string match "PD_*" $prefix]} {
            puts "WARNING: TT_EDGE_SW cannot derive IEEE-1801 rule from prefix '$prefix'; skip."
            continue
        }

        # Existing project naming convention, derived from setup prefix:
        #   PD_WDT_SW -> WDT_SW -> WDT_SW_OUT
        #   PD_CPU_SW -> CPU_SW -> CPU_SW_OUT
        set rule [string range $prefix 3 end]
        set enable_out "${rule}_OUT"
        lappend specs [list $pd $rule $prefix $enable_out]
    }

    return $specs
}

proc TT_EDGE_SW__endcap_base_prefix {} {
    if {[info exists ::ENDCAP_POWER_DOMAIN_PREFIX] &&
        $::ENDCAP_POWER_DOMAIN_PREFIX ne ""} {
        return $::ENDCAP_POWER_DOMAIN_PREFIX
    }

    return ENDCAP_PD
}

proc TT_EDGE_SW__exact_endcap_leaf_pattern {pd} {
    set clean [TT_EDGE_SW__sanitize_pd $pd]
    set base [TT_EDGE_SW__endcap_base_prefix]

    # This is the V5-confirmed naming pattern.
    return "${base}_${clean}_${clean}_*"
}

proc TT_EDGE_SW__nominal_left_masters {} {
    if {[info exists ::POWER_SWITCH_EDGE_NOMINAL_LEFT_ENDCAP_MASTERS] &&
        [llength $::POWER_SWITCH_EDGE_NOMINAL_LEFT_ENDCAP_MASTERS] > 0} {
        return $::POWER_SWITCH_EDGE_NOMINAL_LEFT_ENDCAP_MASTERS
    }

    return [::tech_mv_library_value LIB_TEXT_003]
}

proc TT_EDGE_SW__nominal_right_masters {} {
    if {[info exists ::POWER_SWITCH_EDGE_NOMINAL_RIGHT_ENDCAP_MASTERS] &&
        [llength $::POWER_SWITCH_EDGE_NOMINAL_RIGHT_ENDCAP_MASTERS] > 0} {
        return $::POWER_SWITCH_EDGE_NOMINAL_RIGHT_ENDCAP_MASTERS
    }

    return [::tech_mv_library_value LIB_TEXT_004]
}

proc TT_EDGE_SW__orient {inst} {
    set o [string tolower [TT_EDGE_SW__get $inst .orient ""]]
    if {$o eq ""} {
        return unknown
    }
    return $o
}

proc TT_EDGE_SW__physical_side {nominal orient} {
    switch -- [string tolower $orient] {
        r0 -
        mx {
            return $nominal
        }
        my -
        r180 {
            if {$nominal eq "LEFT"} {
                return RIGHT
            }
            if {$nominal eq "RIGHT"} {
                return LEFT
            }
            return ""
        }
        default {
            return ""
        }
    }
}

proc TT_EDGE_SW__pd_rects {pd} {
    set groups {}

    catch {set groups [get_db groups $pd]}

    if {[llength $groups] != 1} {
        catch {
            set groups [get_db groups -if [format {.power_domain.name == "%s"} $pd]]
        }
    }

    if {[llength $groups] != 1} {
        puts "WARNING: TT_EDGE_SW cannot uniquely resolve physical group for $pd."
        return {}
    }

    set raw [TT_EDGE_SW__get [lindex $groups 0] .rects {}]
    set out {}

    set one [TT_EDGE_SW__rect4 $raw]
    if {[llength $one] == 4} {
        lappend out $one
        return $out
    }

    foreach rr $raw {
        set r [TT_EDGE_SW__rect4 $rr]
        if {[llength $r] == 4} {
            lappend out $r
        }
    }

    return $out
}

proc TT_EDGE_SW__vertical_overlap {a1 a2 b1 b2} {
    return [expr {min(double($a2),double($b2)) >
                  max(double($a1),double($b1))}]
}

proc TT_EDGE_SW__inst_grid {} {
    set raw {}
    catch {set raw [get_db floorplan_finfet_inst_grid]}

    foreach idx {2 0 1 3} {
        if {[llength $raw] > $idx} {
            set v [lindex $raw $idx]
            if {[string is double -strict $v] && double($v) > 0.0} {
                return [expr {double($v)}]
            }
        }
    }

    return [::tech_mv_private_value {edge_switch::fallback_inst_grid}]
}

proc TT_EDGE_SW__scan_live_prefix {prefix {exclude_edge 0}} {
    set out {}

    foreach inst [get_db insts] {
        set name [TT_EDGE_SW__get $inst .name ""]
        set leaf [TT_EDGE_SW__leaf $name]

        if {![string match "${prefix}*" $leaf]} {
            continue
        }

        if {$exclude_edge && [string match "${prefix}_EDGE_*" $leaf]} {
            continue
        }

        lappend out $inst
    }

    return $out
}

proc TT_EDGE_SW__main_switch_width {prefix} {
    set best ""

    foreach inst [TT_EDGE_SW__scan_live_prefix $prefix 1] {
        set bbox [TT_EDGE_SW__rect4 [TT_EDGE_SW__get $inst .bbox {}]]
        if {[llength $bbox] != 4} {
            continue
        }

        lassign $bbox x1 y1 x2 y2
        set w [expr {$x2-$x1}]

        if {$w > 0.0 && ($best eq "" || $w < $best)} {
            set best $w
        }
    }

    return $best
}

proc TT_EDGE_SW__main_switch_master {prefix} {
    foreach inst [TT_EDGE_SW__scan_live_prefix $prefix 1] {
        set master [TT_EDGE_SW__get $inst .base_cell.name ""]
        if {$master ne ""} {
            return $master
        }
    }
    return ""
}

proc TT_EDGE_SW__count_master_at_x {master target_x rect tol} {
    if {$master eq ""} {
        return 0
    }

    lassign $rect rx1 ry1 rx2 ry2
    set count 0

    foreach inst [get_db insts] {
        if {[TT_EDGE_SW__get $inst .base_cell.name ""] ne $master} {
            continue
        }

        set bbox [TT_EDGE_SW__rect4 [TT_EDGE_SW__get $inst .bbox {}]]
        if {[llength $bbox] != 4} {
            continue
        }

        lassign $bbox x1 y1 x2 y2
        if {![TT_EDGE_SW__vertical_overlap $y1 $y2 $ry1 $ry2]} {
            continue
        }

        if {abs(double($x1)-double($target_x)) <= double($tol)} {
            incr count
        }
    }

    return $count
}

proc TT_EDGE_SW__collect_endcaps {pd} {
    set pattern [TT_EDGE_SW__exact_endcap_leaf_pattern $pd]
    set left_masters [TT_EDGE_SW__nominal_left_masters]
    set right_masters [TT_EDGE_SW__nominal_right_masters]

    set left {}
    set right {}
    set other {}
    set exact_count 0

    foreach inst [get_db insts] {
        set name [TT_EDGE_SW__get $inst .name ""]
        set leaf [TT_EDGE_SW__leaf $name]

        if {![string match $pattern $leaf]} {
            continue
        }

        incr exact_count

        set master [TT_EDGE_SW__get $inst .base_cell.name ""]
        set bbox [TT_EDGE_SW__rect4 [TT_EDGE_SW__get $inst .bbox {}]]

        if {[llength $bbox] != 4} {
            continue
        }

        set orient [TT_EDGE_SW__orient $inst]
        set nominal ""

        if {[lsearch -exact $left_masters $master] >= 0} {
            set nominal LEFT
        } elseif {[lsearch -exact $right_masters $master] >= 0} {
            set nominal RIGHT
        }

        set physical ""
        if {$nominal ne ""} {
            set physical [TT_EDGE_SW__physical_side $nominal $orient]
        }

        set rec [dict create \
            inst $inst \
            name $name \
            leaf $leaf \
            master $master \
            orient $orient \
            nominal_side $nominal \
            physical_side $physical \
            bbox $bbox]

        if {$physical eq "LEFT"} {
            lappend left $rec
        } elseif {$physical eq "RIGHT"} {
            lappend right $rec
        } else {
            lappend other $rec
        }
    }

    return [dict create \
        pd $pd \
        pattern $pattern \
        exact_count $exact_count \
        left $left \
        right $right \
        other $other]
}

proc TT_EDGE_SW__select_rect_endcap {side rect records} {
    lassign $rect rx1 ry1 rx2 ry2

    set best {}
    set best_score ""

    foreach rec $records {
        set bbox [dict get $rec bbox]
        lassign $bbox x1 y1 x2 y2

        if {![TT_EDGE_SW__vertical_overlap $y1 $y2 $ry1 $ry2]} {
            continue
        }

        # Physical R/L was already decided by master + orientation.
        # Geometry is used only to map the EndCap to this PD rectangle and to
        # obtain the row-facing inner X coordinate.
        if {$side eq "LEFT"} {
            set score [expr {abs(double($x1)-double($rx1))}]
            set inner_x $x2
        } else {
            set score [expr {abs(double($x2)-double($rx2))}]
            set inner_x $x1
        }

        if {$best_score eq "" || $score < $best_score} {
            set best_score $score
            set best $rec
            dict set best inner_x $inner_x
            dict set best boundary_distance $score
        }
    }

    return $best
}

proc TT_EDGE_SW__report_path {} {
    if {[info exists ::REPORT_DIR] && $::REPORT_DIR ne ""} {
        set dir [file join $::REPORT_DIR 01_floorplan floorplan]
    } else {
        set dir [pwd]
    }

    file mkdir $dir
    return [file join $dir 01_78_edge_sw_reinforce.rpt]
}

proc TT_EDGE_SW__suspend_attention {title details} {
    # V1.9 policy: record the failure and continue.  There is NO edge-only
    # suspend. Stage-01 performs one existing EndCap/SW inspection breakpoint
    # only after main SW, overlap cleanup, edge reinforcement and final checks.
    if {![info exists ::TT_EDGE_SW_LAST_FAILURES]} {
        set ::TT_EDGE_SW_LAST_FAILURES {}
    }

    lappend ::TT_EDGE_SW_LAST_FAILURES [list $title $details]
    set ::TT_EDGE_SW_LAST_FAILURE_COUNT [llength $::TT_EDGE_SW_LAST_FAILURES]

    puts ""
    puts "======================================================================"
    puts " $title"
    puts "======================================================================"
    foreach line $details {
        puts $line
    }
    puts ""
    puts "INFO: Failure recorded; V2.0 continues with remaining gated PDs/sides."
    puts "INFO: No edge-only suspend is issued; inspect at the normal Stage-01 breakpoint."
    puts "======================================================================"
    puts ""
}

proc TT_EDGE_SW__run_area {
    pd rule main_prefix enable_out mode rect_index side area report_fp \
    sw_master target_x raw_target_x rect target_tol
} {
    set side [string toupper $side]
    set edge_prefix "${main_prefix}_EDGE_${side}_R${rect_index}_"

    set existing [TT_EDGE_SW__scan_live_prefix $edge_prefix 0]
    if {[llength $existing] > 0} {
        puts "INFO: TT_EDGE_SW $pd $side rect#$rect_index already has [llength $existing] dedicated edge SW(s); skip duplicate pass."
        puts $report_fp "$pd | rect=$rect_index | side=$side | area={$area} | preexisting=[llength $existing] | action=SKIP_EXISTING"
        return [llength $existing]
    }

    # First accept a surviving raw-abut column. The main-overlap cleanup has
    # already run before this helper; therefore any raw column still present
    # is legal and must not be duplicated.
    set occupied_raw [TT_EDGE_SW__count_master_at_x $sw_master $raw_target_x $rect $target_tol]
    if {$occupied_raw > 0} {
        puts "INFO: TT_EDGE_SW $pd $side raw edge X=$raw_target_x already has $occupied_raw legal live '$sw_master' SW(s); skip duplicate pass."
        puts $report_fp "$pd | rect=$rect_index | side=$side | raw_target_x=$raw_target_x | preexisting_raw=$occupied_raw | action=SKIP_LEGAL_RAW_TARGET"
        return $occupied_raw
    }

    set occupied [TT_EDGE_SW__count_master_at_x $sw_master $target_x $rect $target_tol]
    if {$occupied > 0} {
        puts "INFO: TT_EDGE_SW $pd $side exact target X=$target_x already has $occupied live '$sw_master' SW(s); skip duplicate pass."
        puts $report_fp "$pd | rect=$rect_index | side=$side | target_x=$target_x | preexisting_target=$occupied | action=SKIP_EXACT_TARGET_OCCUPIED"
        return $occupied
    }

    set cmd [list \
        add_power_switches \
        -incremental \
        -column \
        -power_domain $pd \
        -1801_power_switch_rule_name $rule \
        -instance_prefix $edge_prefix \
        -horizontal_pitch $::POWER_SWITCH_EDGE_REINFORCE_PITCH \
        -area $area]

    # Preserve only the normal vertical top/bottom exclusion policy.
    # Do NOT add checkerboard and do NOT reuse main left/right offsets here;
    # the area itself is anchored to the EndCap interior edge.
    if {[string tolower $mode] eq "tool"} {
        if {[info exists ::POWER_SWITCH_TOP_OFFSET]} {
            lappend cmd -top_offset $::POWER_SWITCH_TOP_OFFSET
        }
        if {[info exists ::POWER_SWITCH_BOTTOM_OFFSET]} {
            lappend cmd -bottom_offset $::POWER_SWITCH_BOTTOM_OFFSET
        }
    }

    lappend cmd -enable_net_out $enable_out

    puts ""
    puts "INFO: TT_EDGE_SW APPLY:"
    puts "INFO:   PD       = $pd"
    puts "INFO:   side     = $side"
    puts "INFO:   area     = $area"
    puts "INFO:   prefix   = $edge_prefix"
    puts "INFO:   pattern  = NON-CHECKERBOARD"
    puts "INFO:   command  = $cmd"

    set rc [catch {uplevel #0 $cmd} err opts]
    if {$rc} {
        TT_EDGE_SW__suspend_attention \
            "EDGE POWER-SWITCH COMMAND FAILED" \
            [list \
                "Power Domain : $pd" \
                "Side         : $side" \
                "Area         : $area" \
                "Message      : $err"]
        puts $report_fp "$pd | rect=$rect_index | side=$side | area={$area} | action=COMMAND_FAILED | message={$err}"
        return 0
    }

    set after [TT_EDGE_SW__scan_live_prefix $edge_prefix 0]
    set count [llength $after]

    puts "INFO: TT_EDGE_SW $pd $side dedicated edge SW count = $count"
    puts $report_fp "$pd | rect=$rect_index | side=$side | area={$area} | prefix=$edge_prefix | count=$count | pattern=NON_CHECKERBOARD_INCREMENTAL"

    if {$count == 0} {
        TT_EDGE_SW__suspend_attention \
            "EDGE POWER-SWITCH INSERTION PRODUCED ZERO INSTANCES" \
            [list \
                "Power Domain : $pd" \
                "Side         : $side" \
                "Area         : $area" \
                "Prefix       : $edge_prefix"]
        return 0
    }

    return $count
}

proc TT_EDGE_SW_apply {} {
    set ::TT_EDGE_SW_LAST_FAILURES {}
    set ::TT_EDGE_SW_LAST_FAILURE_COUNT 0

    if {![TT_EDGE_SW__bool $::POWER_SWITCH_EDGE_REINFORCE_ENABLE]} {
        puts "INFO: TT_EDGE_SW edge reinforcement disabled."
        return 0
    }

    if {![info exists ::POWER_SWITCH_INSERTION_MODE]} {
        puts "WARNING: TT_EDGE_SW POWER_SWITCH_INSERTION_MODE undefined; skip."
        return 0
    }

    set mode [string tolower $::POWER_SWITCH_INSERTION_MODE]
    if {$mode ni {legacy tool}} {
        puts "WARNING: TT_EDGE_SW unsupported POWER_SWITCH_INSERTION_MODE='$mode'; skip."
        return 0
    }

    set grid [TT_EDGE_SW__inst_grid]

    if {![string is double -strict $::POWER_SWITCH_EDGE_REINFORCE_GAP]} {
        error "TT_EDGE_SW: POWER_SWITCH_EDGE_REINFORCE_GAP must be numeric; got '$::POWER_SWITCH_EDGE_REINFORCE_GAP'."
    }
    # Exact footprint only. Ignore any stale nonzero V1.9 value.
    set gap 0.0

    set specs [TT_EDGE_SW__configured_specs]
    if {[llength $specs] == 0} {
        error "TT_EDGE_SW: setup-derived gated-domain spec list is empty."
    }

    set extra 0.0

    set rpt [TT_EDGE_SW__report_path]
    set fp [open $rpt w]

    puts $fp "======================================================================"
    puts $fp " PD EDGE POWER-SWITCH REINFORCEMENT V2.0"
    puts $fp "======================================================================"
    puts $fp "Main SW policy      : UNCHANGED"
    puts $fp "EndCap matching     : V5 exact leaf-name pattern"
    puts $fp "LEFT/RIGHT decision : physical side from master + orientation"
    puts $fp "Geometry            : runtime-validated golden mirror"
    puts $fp "  LEFT              : EndCap x2 -> SW grows +X"
    puts $fp "  RIGHT             : SW grows -X -> EndCap x1"
    puts $fp "Edge pattern        : incremental NON-CHECKERBOARD"
    puts $fp "Pitch               : $::POWER_SWITCH_EDGE_REINFORCE_PITCH"
    puts $fp "Target source       : PD_CFG rail_2nd + POWER_SWITCH_INSTANCE_PREFIXES"
    puts $fp "Configured specs    : $specs"
    puts $fp "Horizontal gap      : 0.0 (exact SW footprint)"
    puts $fp ""

    set grand_total 0
    set sw_pd_count 0

    foreach spec $specs {
        if {[llength $spec] != 4} {
            puts "WARNING: TT_EDGE_SW malformed spec '$spec'; expected {PD RULE PREFIX ENABLE_OUT}."
            puts $fp "SPEC | action=SKIP_MALFORMED | value={$spec}"
            continue
        }

        lassign $spec pd rule prefix enable_out

        # "All SW-bearing PDs": only process a configured PD when live main
        # SW instances are really present.
        set main_sw [TT_EDGE_SW__scan_live_prefix $prefix 1]
        if {[llength $main_sw] == 0} {
            puts "INFO: TT_EDGE_SW $pd has no live main SW matching '$prefix*'; skip."
            puts $fp "$pd | main_prefix=$prefix | action=SKIP_NO_LIVE_SW"
            continue
        }

        incr sw_pd_count

        set rects [TT_EDGE_SW__pd_rects $pd]
        if {[llength $rects] == 0} {
            TT_EDGE_SW__suspend_attention \
                "EDGE SW: NO PHYSICAL PD RECTANGLE" \
                [list "Power Domain : $pd"]

            if {![TT_EDGE_SW__bool $::POWER_SWITCH_EDGE_REINFORCE_ENABLE]} {
                continue
            }

            set rects [TT_EDGE_SW__pd_rects $pd]
            if {[llength $rects] == 0} {
                continue
            }
        }

        set ec [TT_EDGE_SW__collect_endcaps $pd]
        set left_records [dict get $ec left]
        set right_records [dict get $ec right]

        puts ""
        puts "======================================================================"
        puts " EDGE POWER-SWITCH REINFORCEMENT V2.0"
        puts "======================================================================"
        puts "Power Domain         : $pd"
        puts "Live main SW         : [llength $main_sw]"
        puts "Main prefix          : $prefix"
        puts "Exact EndCap pattern : [dict get $ec pattern]"
        puts "Exact EndCaps        : [dict get $ec exact_count]"
        puts "LEFT EndCaps         : [llength $left_records]"
        puts "RIGHT EndCaps        : [llength $right_records]"
        puts "Nominal LEFT masters : [TT_EDGE_SW__nominal_left_masters]"
        puts "Nominal RIGHT masters: [TT_EDGE_SW__nominal_right_masters]"
        puts "Main SW policy       : UNCHANGED"
        puts "Edge pattern         : NON-CHECKERBOARD incremental"
        puts "======================================================================"

        puts $fp "$pd | live_main_sw=[llength $main_sw] | main_prefix=$prefix | exact_pattern={[dict get $ec pattern]} | exact_endcaps=[dict get $ec exact_count] | left_endcaps=[llength $left_records] | right_endcaps=[llength $right_records]"

        if {[llength $left_records] == 0 ||
            [llength $right_records] == 0} {
            TT_EDGE_SW__suspend_attention \
                "EDGE SW: V5 ENDCAP MATCH MISSING ONE SIDE" \
                [list \
                    "Power Domain : $pd" \
                    "Pattern      : [dict get $ec pattern]" \
                    "LEFT count   : [llength $left_records]" \
                    "RIGHT count  : [llength $right_records]"]

            if {![TT_EDGE_SW__bool $::POWER_SWITCH_EDGE_REINFORCE_ENABLE]} {
                continue
            }

            set ec [TT_EDGE_SW__collect_endcaps $pd]
            set left_records [dict get $ec left]
            set right_records [dict get $ec right]

            if {[llength $left_records] == 0 ||
                [llength $right_records] == 0} {
                continue
            }
        }

        set sw_w [TT_EDGE_SW__main_switch_width $prefix]
        if {$sw_w eq ""} {
            TT_EDGE_SW__suspend_attention \
                "EDGE SW: CANNOT MEASURE MAIN SW WIDTH" \
                [list \
                    "Power Domain : $pd" \
                    "Prefix       : $prefix"]

            if {![TT_EDGE_SW__bool $::POWER_SWITCH_EDGE_REINFORCE_ENABLE]} {
                continue
            }

            set sw_w [TT_EDGE_SW__main_switch_width $prefix]
            if {$sw_w eq ""} {
                continue
            }
        }

        set sw_master [TT_EDGE_SW__main_switch_master $prefix]
        if {$sw_master eq ""} {
            TT_EDGE_SW__suspend_attention \
                "EDGE SW: CANNOT RESOLVE MAIN SW MASTER" \
                [list \
                    "Power Domain : $pd" \
                    "Prefix       : $prefix"]
            continue
        }

        set target_tol [expr {max(0.06,6.0*$grid)}]

        # V2.0 exact geometry: band width is exactly the measured SW width.
        # No horizontal padding and no EndCap gap.
        set band_w [expr {double($sw_w)}]

        if {$band_w >= double($::POWER_SWITCH_EDGE_REINFORCE_PITCH)} {
            TT_EDGE_SW__suspend_attention \
                "EDGE SW: EDGE AREA IS NOT SINGLE-COLUMN WIDTH" \
                [list \
                    "Power Domain : $pd" \
                    "SW width     : $sw_w" \
                    "Band width   : $band_w" \
                    "Pitch        : $::POWER_SWITCH_EDGE_REINFORCE_PITCH"]

            if {![TT_EDGE_SW__bool $::POWER_SWITCH_EDGE_REINFORCE_ENABLE]} {
                continue
            }
            # Deferred-failure mode cannot pause for an interactive correction;
            # do not continue with an invalid multi-column edge band.
            continue
        }

        set ridx 0

        foreach rect $rects {
            lassign $rect rx1 ry1 rx2 ry2

            set left_hit [TT_EDGE_SW__select_rect_endcap LEFT $rect $left_records]
            set right_hit [TT_EDGE_SW__select_rect_endcap RIGHT $rect $right_records]

            if {[llength $left_hit] == 0 ||
                [llength $right_hit] == 0} {
                TT_EDGE_SW__suspend_attention \
                    "EDGE SW: CANNOT MAP ENDCAP TYPE TO PD RECTANGLE" \
                    [list \
                        "Power Domain : $pd" \
                        "PD rect      : $rect" \
                        "LEFT found   : [expr {[llength $left_hit] > 0}]" \
                        "RIGHT found  : [expr {[llength $right_hit] > 0}]"]

                if {![TT_EDGE_SW__bool $::POWER_SWITCH_EDGE_REINFORCE_ENABLE]} {
                    incr ridx
                    continue
                }
            }

            if {[llength $left_hit] > 0} {
                set left_inner [dict get $left_hit inner_x]
                set left_raw_target_x [expr {double($left_inner)}]
                set left_target_x $left_raw_target_x
                set ax1 $left_target_x
                set ax2 [expr {$ax1+double($sw_w)}]
                set area [list $ax1 $ry1 $ax2 $ry2]

                puts "INFO: TT_EDGE_SW LEFT selected:"
                puts "INFO:   EndCap = [dict get $left_hit name]"
                puts "INFO:   Master = [dict get $left_hit master]"
                puts "INFO:   Orient = [dict get $left_hit orient]"
                puts "INFO:   BBox   = [dict get $left_hit bbox]"
                puts "INFO:   InnerX = $left_inner"
                puts "INFO:   Area   = $area"

                puts $fp "$pd | rect=$ridx | side=LEFT | endcap={[dict get $left_hit name]} | master=[dict get $left_hit master] | orient=[dict get $left_hit orient] | bbox={[dict get $left_hit bbox]} | inner_x=$left_inner | raw_target_x=$left_raw_target_x | target_x=$left_target_x | area={$area}"

                if {$ax2 < double($rx2)} {
                    incr grand_total [TT_EDGE_SW__run_area \
                        $pd $rule $prefix $enable_out $mode \
                        $ridx LEFT $area $fp $sw_master $left_target_x $left_raw_target_x $rect $target_tol]
                } else {
                    TT_EDGE_SW__suspend_attention \
                        "EDGE SW: LEFT AREA EXCEEDS PD RECTANGLE" \
                        [list \
                            "Power Domain : $pd" \
                            "PD rect      : $rect" \
                            "Area         : $area"]
                }
            }

            if {[llength $right_hit] > 0} {
                set right_inner [dict get $right_hit inner_x]
                set right_raw_target_x [expr {double($right_inner)-double($sw_w)}]
                set right_target_x $right_raw_target_x
                set ax1 $right_target_x
                set ax2 [expr {double($right_inner)}]
                set area [list $ax1 $ry1 $ax2 $ry2]

                puts "INFO: TT_EDGE_SW RIGHT selected:"
                puts "INFO:   EndCap = [dict get $right_hit name]"
                puts "INFO:   Master = [dict get $right_hit master]"
                puts "INFO:   Orient = [dict get $right_hit orient]"
                puts "INFO:   BBox   = [dict get $right_hit bbox]"
                puts "INFO:   InnerX = $right_inner"
                puts "INFO:   Area   = $area"

                puts $fp "$pd | rect=$ridx | side=RIGHT | endcap={[dict get $right_hit name]} | master=[dict get $right_hit master] | orient=[dict get $right_hit orient] | bbox={[dict get $right_hit bbox]} | inner_x=$right_inner | raw_target_x=$right_raw_target_x | target_x=$right_target_x | area={$area}"

                if {$ax1 > double($rx1)} {
                    incr grand_total [TT_EDGE_SW__run_area \
                        $pd $rule $prefix $enable_out $mode \
                        $ridx RIGHT $area $fp $sw_master $right_target_x $right_raw_target_x $rect $target_tol]
                } else {
                    TT_EDGE_SW__suspend_attention \
                        "EDGE SW: RIGHT AREA EXCEEDS PD RECTANGLE" \
                        [list \
                            "Power Domain : $pd" \
                            "PD rect      : $rect" \
                            "Area         : $area"]
                }
            }

            incr ridx
        }
    }

    puts $fp ""
    puts $fp "SW-BEARING PD COUNT: $sw_pd_count"
    puts $fp "TOTAL EDGE SW PRESENT/CREATED: $grand_total"
    puts $fp "EDGE FAILURE COUNT: $::TT_EDGE_SW_LAST_FAILURE_COUNT"
    if {$::TT_EDGE_SW_LAST_FAILURE_COUNT > 0} {
        set _tt_fidx 0
        foreach _tt_failure $::TT_EDGE_SW_LAST_FAILURES {
            incr _tt_fidx
            puts $fp "FAILURE $_tt_fidx: $_tt_failure"
        }
        unset _tt_fidx
    }
    close $fp

    puts ""
    puts "======================================================================"
    puts " EDGE POWER-SWITCH REINFORCEMENT SUMMARY"
    puts "======================================================================"
    puts "Setup-gated PDs processed: $sw_pd_count"
    puts "Edge SW present/created  : $grand_total"
    puts "Edge failures recorded   : $::TT_EDGE_SW_LAST_FAILURE_COUNT"
    puts "Report                    : $rpt"
    puts "Main SW policy            : UNCHANGED"
    puts "Edge pattern              : NON-CHECKERBOARD"
    puts "======================================================================"

    return $grand_total
}

puts "INFO: Loaded TT_proc_power_switch_edge_reinforce.tcl - $::TT_EDGE_SW_VERSION"
