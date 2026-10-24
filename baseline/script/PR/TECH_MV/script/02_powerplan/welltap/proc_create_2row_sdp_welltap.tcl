# Runtime adapter preserves the historical logical source path.
if {[info exists ::TECH_MV_RUNTIME_ROOT]} {
    info script [file join $::TECH_MV_RUNTIME_ROOT run/tool/02_powerplan/welltap/TT_proc_create_2row_sdp_welltap.tcl]
} else {
    info script [file normalize [file join [file dirname [info script]] .. .. .. run/tool/02_powerplan/welltap/TT_proc_create_2row_sdp_welltap.tcl]]
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
# TT_proc_create_2row_sdp_welltap_v4_sdp_padding.tcl
# TECH_MV / Innovus 21.19 Stylus Common UI
#
# Common UI SDP flow:
#   1) discover exactly 2-row LS/ISO by DB attributes
#   2) create PD-specific WellTap pools with add_well_taps -power_domain
#   3) unplace only the generated pool taps
#   4) emit an SDP relative-placement file
#   5) load it with read_sdp_file
#   6) place with place_sdps
#
# SDP primitive per 2-row cell:
#      [WT_L0/WT_L1 column] [2-row LS/ISO] [WT_R0/WT_R1 column]
#
# NO legacy createSdpGroup/addSdpGroupMember/placeSdpGroup is used.
# =============================================================================

set ::TT_2ROW_SDP_VERSION "V4_FLAT_ROW_2TAP_SDP_PADDING"

if {![info exists ::TT_2ROW_SDP_WELLTAP_MASTER]} { set ::TT_2ROW_SDP_WELLTAP_MASTER [::tech_mv_library_value LIB_CELL_002] }
if {![info exists ::TT_2ROW_SDP_SITE]} { set ::TT_2ROW_SDP_SITE core }
if {![info exists ::TT_2ROW_SDP_TAPS_PER_CELL]} { set ::TT_2ROW_SDP_TAPS_PER_CELL [::tech_mv_private_value {run/tool/02_powerplan/TT_proc_create_2row_sdp_welltap.tcl::::TT_2ROW_SDP_TAPS_PER_CELL::L23}] }
if {![info exists ::TT_2ROW_SDP_TRIAL_INTERVAL]} { set ::TT_2ROW_SDP_TRIAL_INTERVAL 200.0 }
if {![info exists ::TT_2ROW_SDP_POOL_MARGIN]} { set ::TT_2ROW_SDP_POOL_MARGIN [::tech_mv_private_value {run/tool/02_powerplan/TT_proc_create_2row_sdp_welltap.tcl::::TT_2ROW_SDP_POOL_MARGIN::L25}] }
if {![info exists ::TT_2ROW_SDP_MAX_POOL_RETRY]} { set ::TT_2ROW_SDP_MAX_POOL_RETRY 4 }
if {![info exists ::TT_2ROW_SDP_WT_PREFIX]} { set ::TT_2ROW_SDP_WT_PREFIX SDPWT }
if {![info exists ::TT_2ROW_SDP_GROUP_PREFIX]} { set ::TT_2ROW_SDP_GROUP_PREFIX SDP2R }
if {![info exists ::TT_2ROW_SDP_FILE]} {
    set ::TT_2ROW_SDP_FILE [tech_mv_output_path temp TT_2row_ls_iso_welltap_generated.sdp 02 sdp]
}
if {![info exists ::TT_2ROW_SDP_UNPLACE_SPECIAL]} { set ::TT_2ROW_SDP_UNPLACE_SPECIAL true }
if {![info exists ::TT_2ROW_SDP_RUN_CHECK]} { set ::TT_2ROW_SDP_RUN_CHECK true }
if {![info exists ::TT_2ROW_SDP_RUN_CHECK_PLACE]} { set ::TT_2ROW_SDP_RUN_CHECK_PLACE true }
if {![info exists ::TT_2ROW_SDP_PADDING_X_SITES]} { set ::TT_2ROW_SDP_PADDING_X_SITES 2 }
if {![info exists ::TT_2ROW_SDP_PADDING_Y_SITES]} { set ::TT_2ROW_SDP_PADDING_Y_SITES 0 }
if {![info exists ::TT_2ROW_SDP_ENFORCE_NO_INTERLEAVING]} { set ::TT_2ROW_SDP_ENFORCE_NO_INTERLEAVING true }
if {![info exists ::TT_2ROW_SDP_HONOR_USER_ASSIGN_ORIGIN]} { set ::TT_2ROW_SDP_HONOR_USER_ASSIGN_ORIGIN false }

proc TT_2row_sdp__bool {v} {
    set s [string tolower [string trim $v]]
    return [expr {$s eq "true" || $s eq "1" || $s eq "yes"}]
}

proc TT_2row_sdp__bbox4 {v} {
    if {[llength $v] == 1} { set v [lindex $v 0] }
    if {[llength $v] != 4} { return "" }
    return $v
}

proc TT_2row_sdp__size2 {v} {
    if {[llength $v] == 1} { set v [lindex $v 0] }
    if {[llength $v] != 2} { return "" }
    return $v
}

proc TT_2row_sdp__name {obj} {
    set v ""
    catch {set v [get_db $obj .name]}
    return $v
}

proc TT_2row_sdp__pd {obj} {
    set v ""
    catch {set v [get_db $obj .power_domain.name]}
    return $v
}

proc TT_2row_sdp__master {obj} {
    set v ""
    catch {set v [get_db $obj .base_cell.name]}
    return $v
}

proc TT_2row_sdp__sanitize {v} {
    regsub -all {[^A-Za-z0-9_]} $v "_" out
    return $out
}

proc TT_2row_sdp__site_geometry {} {
    set v [TT_2row_sdp__size2 [get_db site:$::TT_2ROW_SDP_SITE .size]]
    if {$v eq ""} { error "Cannot read site '$::TT_2ROW_SDP_SITE' size." }
    return $v
}

proc TT_2row_sdp__padding_geometry {} {
    lassign [TT_2row_sdp__site_geometry] site_w site_h
    if {![string is integer -strict $::TT_2ROW_SDP_PADDING_X_SITES] || $::TT_2ROW_SDP_PADDING_X_SITES < 0} {
        error "TT_2ROW_SDP_PADDING_X_SITES must be a non-negative integer."
    }
    if {![string is integer -strict $::TT_2ROW_SDP_PADDING_Y_SITES] || $::TT_2ROW_SDP_PADDING_Y_SITES < 0} {
        error "TT_2ROW_SDP_PADDING_Y_SITES must be a non-negative integer."
    }
    return [list \
        [expr {double($site_w) * $::TT_2ROW_SDP_PADDING_X_SITES}] \
        [expr {double($site_h) * $::TT_2ROW_SDP_PADDING_Y_SITES}]]
}

proc TT_2row_sdp__tap_geometry {} {
    set v [TT_2row_sdp__bbox4 [get_db base_cell:$::TT_2ROW_SDP_WELLTAP_MASTER .bbox]]
    if {$v eq ""} { error "Cannot read WellTap master '$::TT_2ROW_SDP_WELLTAP_MASTER' bbox." }
    lassign $v x1 y1 x2 y2
    return [list [expr {$x2-$x1}] [expr {$y2-$y1}]]
}

proc TT_2row_sdp__master_rows {inst site_h} {
    set master [TT_2row_sdp__master $inst]
    if {$master eq ""} { return -1 }
    set b [TT_2row_sdp__bbox4 [get_db base_cell:$master .bbox]]
    if {$b eq ""} { return -1 }
    lassign $b x1 y1 x2 y2
    return [expr {int(round(($y2-$y1)/$site_h))}]
}

proc TT_2row_sdp__check_commands {} {
    set missing {}
    foreach cmd {add_well_taps read_sdp_file} {
        if {[llength [info commands $cmd]] == 0} { lappend missing $cmd }
    }
    if {[llength $missing] != 0} { error "Missing required Common UI command(s): $missing" }
}

proc TT_2row_sdp__collect {kind_name pd_cells_name} {
    upvar 1 $kind_name kind
    upvar 1 $pd_cells_name pd_cells
    catch {array unset kind}
    catch {array unset pd_cells}

    lassign [TT_2row_sdp__site_geometry] site_w site_h
    set ls_total 0
    set iso_total 0
    set two_total 0
    set no_pd 0

    foreach inst [get_db insts] {
        set is_ls false
        set is_iso false
        catch {set is_ls  [get_db $inst .is_level_shifter]}
        catch {set is_iso [get_db $inst .is_isolation]}

        if {![TT_2row_sdp__bool $is_ls] && ![TT_2row_sdp__bool $is_iso]} { continue }

        if {[TT_2row_sdp__bool $is_ls]} {
            set kind_value LS
            incr ls_total
        } else {
            set kind_value ISO
            incr iso_total
        }

        if {[TT_2row_sdp__master_rows $inst $site_h] != 2} { continue }
        incr two_total

        set inst_name [TT_2row_sdp__name $inst]
        set pd [TT_2row_sdp__pd $inst]
        if {$pd eq ""} {
            puts "WARNING: 2-row $kind_value has no Power Domain: $inst_name"
            incr no_pd
            continue
        }

        set kind($inst_name) $kind_value
        lappend pd_cells($pd) $inst
    }

    puts ""
    puts "======================================================================"
    puts " 2-ROW LS / ISO DISCOVERY"
    puts "======================================================================"
    puts "All Level Shifters : $ls_total"
    puts "All Isolation Cells: $iso_total"
    puts "2-row LS/ISO       : $two_total"
    puts "2-row without PD   : $no_pd"
    foreach pd [lsort -dictionary [array names pd_cells]] {
        set count [llength $pd_cells($pd)]
        set need [expr {$count * $::TT_2ROW_SDP_TAPS_PER_CELL}]
        puts [format "PD %-20s : %4d cell(s), %4d SDP WellTap(s) required" $pd $count $need]
    }
    puts "======================================================================"

    if {$no_pd != 0} { error "Cannot continue: $no_pd 2-row LS/ISO cell(s) have no Power Domain." }
    return $two_total
}

proc TT_2row_sdp__pool_prefix {pd} {
    return "${::TT_2ROW_SDP_WT_PREFIX}_[TT_2row_sdp__sanitize $pd]"
}

proc TT_2row_sdp__prefix_insts {prefix} {
    set result {}
    foreach inst [get_db insts] {
        set n [TT_2row_sdp__name $inst]
        if {$n ne "" && [string match "*${prefix}*" $n]} {
            lappend result $inst
        }
    }
    return $result
}

proc TT_2row_sdp__tap_objects {} {
    set result {}
    set master $::TT_2ROW_SDP_WELLTAP_MASTER
    foreach inst [get_db insts] {
        if {[TT_2row_sdp__master $inst] eq $master} {
            lappend result $inst
        }
    }
    return $result
}

proc TT_2row_sdp__snapshot_taps {array_name} {
    upvar 1 $array_name snap
    catch {array unset snap}
    foreach inst [TT_2row_sdp__tap_objects] {
        set snap("$inst") 1
    }
}

proc TT_2row_sdp__new_taps_since {array_name} {
    upvar 1 $array_name before
    set result {}
    foreach inst [TT_2row_sdp__tap_objects] {
        if {![info exists before("$inst")]} {
            lappend result $inst
        }
    }
    return $result
}

proc TT_2row_sdp__delete_objects {objects} {
    set failed 0
    foreach inst $objects {
        set n [TT_2row_sdp__name $inst]
        if {$n eq ""} { continue }
        if {[catch {delete_inst -inst $n -verbose} err]} {
            puts "WARNING: Failed deleting temporary SDP WellTap '$n':"
            puts "         $err"
            incr failed
        }
    }
    if {$failed != 0} {
        error "Failed deleting $failed temporary SDP WellTap(s)."
    }
}

proc TT_2row_sdp__delete_prefix {prefix} {
    set names {}
    foreach inst [TT_2row_sdp__prefix_insts $prefix] {
        set n [TT_2row_sdp__name $inst]
        if {$n ne ""} { lappend names $n }
    }
    foreach n $names {
        if {[catch {delete_inst -inst $n -verbose} err]} { error "Failed deleting stale SDP WellTap '$n': $err" }
    }
    return [llength $names]
}

proc TT_2row_sdp__create_pool {pd required} {
    set master $::TT_2ROW_SDP_WELLTAP_MASTER
    set prefix [TT_2row_sdp__pool_prefix $pd]
    lassign [TT_2row_sdp__tap_geometry] tap_w tap_h

    set stale [TT_2row_sdp__delete_prefix $prefix]
    if {$stale > 0} {
        puts "INFO: Deleted $stale stale SDP pool WellTap(s) for PD=$pd."
    }

    # Sparse calibration trial.
    set trial_interval $::TT_2ROW_SDP_TRIAL_INTERVAL
    set trial_count 0

    for {set trial 0} {$trial < 6} {incr trial} {
        catch {array unset before_trial}
        TT_2row_sdp__snapshot_taps before_trial

        puts [format \
            "INFO: Calibrate pool PD=%s required=%d trial_interval=%0.3f" \
            $pd $required $trial_interval]

        if {[catch {
            add_well_taps \
                -cell $master \
                -cell_interval $trial_interval \
                -power_domain $pd \
                -prefix $prefix
        } err]} {
            error "Calibration add_well_taps failed for PD=$pd: $err"
        }

        set trial_objs [TT_2row_sdp__new_taps_since before_trial]
        set trial_count [llength $trial_objs]

        puts "INFO: PD=$pd calibration created $trial_count new WellTap(s)."

        TT_2row_sdp__delete_objects $trial_objs

        if {$trial_count > 0} {
            break
        }

        set trial_interval [expr {$trial_interval / 2.0}]
        if {$trial_interval < $tap_w} {
            set trial_interval $tap_w
        }
    }

    if {$trial_count <= 0} {
        error "PD=$pd calibration could not create any WellTap."
    }

    set interval [expr {
        $trial_interval *
        double($trial_count) /
        (double($required) * $::TT_2ROW_SDP_POOL_MARGIN)
    }]

    if {$interval < $tap_w} {
        set interval $tap_w
    }

    set final_objs {}
    set selected_interval ""

    for {set attempt 0} \
        {$attempt < $::TT_2ROW_SDP_MAX_POOL_RETRY} \
        {incr attempt} {

        catch {array unset before_final}
        TT_2row_sdp__snapshot_taps before_final

        puts [format \
            "INFO: Build pool PD=%s required=%d interval=%0.3f attempt=%d" \
            $pd $required $interval [expr {$attempt+1}]]

        if {[catch {
            add_well_taps \
                -cell $master \
                -cell_interval $interval \
                -power_domain $pd \
                -prefix $prefix
        } err]} {
            error "Final add_well_taps failed for PD=$pd: $err"
        }

        set final_objs [TT_2row_sdp__new_taps_since before_final]
        set got [llength $final_objs]

        puts "INFO: PD=$pd final attempt created $got new WellTap(s)."

        if {$got >= $required} {
            set selected_interval $interval
            break
        }

        TT_2row_sdp__delete_objects $final_objs
        set final_objs {}

        if {$got <= 0} {
            set interval [expr {$interval / 2.0}]
        } else {
            set interval [expr {
                $interval *
                double($got) /
                (double($required) * $::TT_2ROW_SDP_POOL_MARGIN)
            }]
        }

        if {$interval < $tap_w} {
            set interval $tap_w
        }
    }

    if {[llength $final_objs] < $required} {
        error "PD=$pd requires $required WellTap(s), final pool has only [llength $final_objs]."
    }

    set named {}
    foreach inst $final_objs {
        set n [TT_2row_sdp__name $inst]
        if {$n ne ""} {
            lappend named [list $n $inst]
        }
    }
    set named [lsort -dictionary -index 0 $named]

    set keep  [lrange $named 0 [expr {$required-1}]]
    set extra [lrange $named $required end]

    foreach item $extra {
        lassign $item n inst
        delete_inst -inst $n -verbose
    }

    set result {}
    foreach item $keep {
        lassign $item n inst

        set before_pd [TT_2row_sdp__pd $inst]
        if {$before_pd ne $pd} {
            error "Pool WellTap '$n' PD mismatch: expected=$pd actual=$before_pd"
        }

        set_db $inst .place_status unplaced

        set after_pd [TT_2row_sdp__pd $inst]
        if {$after_pd ne $pd} {
            error "Pool WellTap '$n' lost PD after unplace: expected=$pd actual=$after_pd"
        }

        lappend result $n
    }

    puts [format \
        "PASS: calibrated pool PD=%s kept=%d interval=%0.3f prefix=%s" \
        $pd [llength $result] $selected_interval $prefix]

    return $result
}

proc TT_2row_sdp__build_pools {pd_cells_name pools_name} {
    upvar 1 $pd_cells_name pd_cells
    upvar 1 $pools_name pools
    catch {array unset pools}

    foreach pd [lsort -dictionary [array names pd_cells]] {
        set required [expr {[llength $pd_cells($pd)] * $::TT_2ROW_SDP_TAPS_PER_CELL}]
        set pools($pd) [TT_2row_sdp__create_pool $pd $required]
    }
}

proc TT_2row_sdp__prepare_cell {inst} {
    set n [TT_2row_sdp__name $inst]
    set existing ""
    if {![catch {set existing [get_db $inst .sdp]}]} {
        if {$existing ne ""} { error "Instance '$n' already belongs to an SDP: $existing" }
    }

    if {$::TT_2ROW_SDP_UNPLACE_SPECIAL} {
        if {[catch {set_db $inst .place_status unplaced} err]} { error "Cannot unplace 2-row special cell '$n': $err" }
    }
}

proc TT_2row_sdp__emit_group {fp seq cell owned_taps} {
    if {[llength $owned_taps] != 2} {
        error "Exactly two SDP WellTaps are required per 2-row cell."
    }

    lassign $owned_taps wt_l wt_r

    set cell_name [TT_2row_sdp__name $cell]

    set root [format "%s_%05d" \
        $::TT_2ROW_SDP_GROUP_PREFIX $seq]

    set row_name "${root}_ROW"

    # Flat SDP row:
    #
    #   [ WT_L ][ 2-row LS/ISO ][ WT_R ]
    #
    # `justifyBy S` aligns the south edge of the 1-row WellTaps to the south
    # edge of the 2-row special cell.  The 2-row special cell therefore
    # determines the SDP row height instead of nested 2-tap columns.
    puts $fp "datapath $root {"
    lassign [TT_2row_sdp__padding_geometry] pad_x pad_y
    puts $fp "  row $row_name {"
    puts $fp "    justifyBy S"
    puts $fp [format "    padding %.6f %.6f" $pad_x $pad_y]
    puts $fp "    inst $wt_l"
    puts $fp "    inst $cell_name"
    puts $fp "    inst $wt_r"
    puts $fp "  }"
    puts $fp "}"
    puts $fp ""

    return $root
}

proc TT_2row_sdp__write_file {kind_name pd_cells_name pools_name} {
    upvar 1 $kind_name kind
    upvar 1 $pd_cells_name pd_cells
    upvar 1 $pools_name pools

    set fp [open $::TT_2ROW_SDP_FILE w]
    puts $fp "# Auto-generated by TT_proc_create_2row_sdp_welltap_v4_flat_row.tcl"
    puts $fp "# Version: $::TT_2ROW_SDP_VERSION"
    puts $fp ""

    set seq 0
    set group_count 0

    foreach pd [lsort -dictionary [array names pd_cells]] {
        set taps $pools($pd)
        set tap_idx 0

        foreach cell $pd_cells($pd) {
            set cell_name [TT_2row_sdp__name $cell]
            TT_2row_sdp__prepare_cell $cell

            set owned [lrange $taps $tap_idx [expr {$tap_idx+1}]]
            if {[llength $owned] != 2} {
                close $fp
                error "SDP WellTap pool underflow: PD=$pd cell=$cell_name"
            }
            incr tap_idx 2

            foreach wt_name $owned {
                set wt [get_db insts $wt_name]
                if {[llength $wt] == 0} {
                    close $fp
                    error "Missing SDP WellTap: $wt_name"
                }
                set wt_obj [lindex $wt 0]
                set wt_pd [TT_2row_sdp__pd $wt_obj]
                if {$wt_pd ne $pd} {
                    close $fp
                    error "SDP WellTap '$wt_name' PD=$wt_pd expected=$pd"
                }
            }

            set g [TT_2row_sdp__emit_group $fp $seq $cell $owned]
            puts [format "SDP %-12s PD=%-16s %-3s %-50s taps={%s}" $g $pd $kind($cell_name) $cell_name [join $owned " "]]
            incr seq
            incr group_count
        }
    }

    close $fp
    return $group_count
}


# -----------------------------------------------------------------------------
# Preflight: detect existing SDP membership BEFORE touching any WellTap pool.
# -----------------------------------------------------------------------------
proc TT_2row_sdp__preflight_existing_sdp {pd_cells_name} {
    upvar 1 $pd_cells_name pd_cells

    set total 0
    set existing 0
    set ours 0
    set foreign 0
    set examples {}

    foreach pd [array names pd_cells] {
        foreach inst $pd_cells($pd) {
            incr total

            set cell_name [TT_2row_sdp__name $inst]
            set sdp_name ""
            catch {set sdp_name [get_db $inst .sdp.name]}

            if {$sdp_name eq ""} {
                continue
            }

            incr existing

            if {[string match "${::TT_2ROW_SDP_GROUP_PREFIX}_*" $sdp_name]} {
                incr ours
            } else {
                incr foreign
            }

            if {[llength $examples] < 8} {
                lappend examples [list $cell_name $sdp_name]
            }
        }
    }

    puts ""
    puts "======================================================================"
    puts " SDP PREFLIGHT"
    puts "======================================================================"
    puts "2-row special cells : $total"
    puts "Already in any SDP  : $existing"
    puts "Already in SDP2R_*   : $ours"
    puts "Foreign SDP members  : $foreign"

    foreach x $examples {
        lassign $x cell_name sdp_name
        puts "EXISTING SDP: $cell_name -> $sdp_name"
    }

    puts "======================================================================"

    if {$existing == 0} {
        return FRESH
    }

    if {$existing == $total && $foreign == 0} {
        return COMPLETE
    }

    return PARTIAL
}

proc TT_proc_create_2row_sdp_welltap {} {
    TT_2row_sdp__check_commands

    set master $::TT_2ROW_SDP_WELLTAP_MASTER
    if {[llength [get_db base_cells $master]] == 0} { error "WellTap master not found: $master" }

    puts ""
    puts "======================================================================"
    puts " CREATE 2-ROW LS / ISO SDP WELLTAP"
    puts "======================================================================"
    puts "Version          : $::TT_2ROW_SDP_VERSION"
    puts "Common UI load   : read_sdp_file"
    puts "WellTap master   : $master"
    puts "Taps / cell      : $::TT_2ROW_SDP_TAPS_PER_CELL"
    puts "Generated SDP    : $::TT_2ROW_SDP_FILE"
    puts "======================================================================"

    catch {array unset kind}
    catch {array unset pd_cells}
    catch {array unset pools}

    set total [TT_2row_sdp__collect kind pd_cells]
    if {$total == 0} {
        puts "INFO: No 2-row LS/ISO cells found."
        return 0
    }

    # CRITICAL: preflight happens BEFORE deleting/creating any SDP WellTap pool.
    set preflight [TT_2row_sdp__preflight_existing_sdp pd_cells]

    if {$preflight eq "COMPLETE"} {
        puts "ERROR: Existing SDP2R_* groups are already loaded."
        puts "ERROR: V4 changes the topology to flat [WT][CELL][WT]."
        puts "ERROR: Restore a clean pre-SDP checkpoint before running this version."
        error "Existing SDP topology is incompatible with V4 flat-row SDP."
    }

    if {$preflight eq "PARTIAL"} {
        error "Existing SDP membership is partial/mixed. Refusing to touch WellTap pools. Restore a clean pre-SDP DB or the previously confirmed complete SDP checkpoint."
    }

    TT_2row_sdp__build_pools pd_cells pools

    puts ""
    puts "======================================================================"
    puts " GENERATE SDP RELATIVE-PLACEMENT FILE"
    puts "======================================================================"

    set group_count [TT_2row_sdp__write_file kind pd_cells pools]
    puts "INFO: Wrote SDP file: $::TT_2ROW_SDP_FILE"
    puts "INFO: SDP groups in file: $group_count"

    if {![file exists $::TT_2ROW_SDP_FILE]} { error "Generated SDP file does not exist: $::TT_2ROW_SDP_FILE" }

    puts ""
    puts "======================================================================"
    puts " LOAD SDP INTO INNOVUS"
    puts "======================================================================"
    puts "INFO: read_sdp_file $::TT_2ROW_SDP_FILE"

    if {[catch {read_sdp_file $::TT_2ROW_SDP_FILE} err]} { error "read_sdp_file failed: $err" }

    if {$::TT_2ROW_SDP_RUN_CHECK && [llength [info commands check_sdps]] > 0} {
        puts "INFO: check_sdps"
        check_sdps -out_file [tech_mv_native_sdp_report_path]
    }

    puts ""
    puts "======================================================================"
    puts " 2-ROW SDP CREATION COMPLETE"
    puts "======================================================================"
    puts "2-row LS/ISO discovered : $total"
    puts "SDP groups loaded       : $group_count"
    puts "WellTaps assigned       : [expr {$group_count*2}]"
    puts "SDP file                : $::TT_2ROW_SDP_FILE"
    puts "======================================================================"
    puts "INFO: Placement has NOT been run."
    puts "INFO: Run: TT_flow_place_2row_sdp"

    return $group_count
}

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
    place_design -sdp

    puts "INFO: Configure 2G SDP legalizer"
    set_db place_sdp_flow 2G
    set_db place_sdp_legalization SW
    set_db place_sdp_legalization_effort high
    set_db place_sdp_pre_fixed_cells_blockage_direction Y
    catch {set_db place_sdp_honor_user_assign_origin $::TT_2ROW_SDP_HONOR_USER_ASSIGN_ORIGIN}
    if {$::TT_2ROW_SDP_ENFORCE_NO_INTERLEAVING} {
        if {[catch {set_db place_sdp_enforce_no_interleaving_sdp true} err]} {
            puts "WARN: place_sdp_enforce_no_interleaving_sdp unavailable: $err"
        }
    }

    puts "INFO: Stage 2/4 - place_sdps"
    place_sdps

    if {$::TT_2ROW_SDP_RUN_CHECK &&
        [llength [info commands check_sdps]] > 0} {
        puts "INFO: Stage 3/4 - check_sdps"
        check_sdps -out_file [tech_mv_native_sdp_report_path]
    }

    if {$::TT_2ROW_SDP_RUN_CHECK_PLACE} {
        puts "INFO: Stage 4/4 - check_place"
        check_place
    }

    puts "======================================================================"
    puts " SDP placement completed."
    puts "======================================================================"
}

puts "INFO: TT_proc_create_2row_sdp_welltap_v4_flat_row.tcl loaded."
puts "INFO: VERSION = $::TT_2ROW_SDP_VERSION"
puts "INFO: Create: TT_proc_create_2row_sdp_welltap"
puts "INFO: Place : TT_flow_place_2row_sdp"
