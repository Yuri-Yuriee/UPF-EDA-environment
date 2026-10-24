# Runtime adapter preserves the historical logical source path.
if {[info exists ::TECH_MV_RUNTIME_ROOT]} {
    info script [file join $::TECH_MV_RUNTIME_ROOT run/tool/02_powerplan/secondary_pg/TT_check_lp_2ndpg.tcl]
}
# Library pin settings only; no APR actions are performed by this loader.
if {![llength [info commands ::tech_mv_library_value]]} {
    if {[info exists ::TOOL_DIR]} {
        source -quiet [file join $::TECH_MV_RUNTIME_ROOT .. script PR TECH_MV script 00_common private_parameter_config.tcl]
    } else {
        source -quiet [file join $::TECH_MV_RUNTIME_ROOT .. script PR TECH_MV script 00_common private_parameter_config.tcl]
    }
}
# =============================================================================
# TT_check_lp_2ndpg.tcl
# =============================================================================
# Read-only checker for low-power secondary PG readiness.
#
# Intended checkpoints:
#   import      : after design import / UPF commit / global-net setup
#   pre_place   : immediately before placement
#   post_place  : immediately after placement, before growing secondary PG
#
# This checker NEVER routes and NEVER fixes/moves cells.
#
# Classification:
#   LS:
#     connected configured SECONDARY_A -> secondary PG required
#     connected configured SECONDARY_B -> secondary PG required
#     neither pin exists -> single-supply LS, no 2nd PG required
#     pin exists but no .net -> FAIL
#     both configured SECONDARY_A and configured SECONDARY_B connected -> FAIL/ambiguous
#
#   ISO:
#     configured SECONDARY_A exists and connected -> secondary PG required
#     no configured SECONDARY_A -> single-supply ISO, no 2nd PG required
#     configured SECONDARY_A exists but no .net -> FAIL
#
#   RET:
#     configured RETENTION_AON must exist and be connected -> secondary PG required
#
# Return value:
#   dict with keys:
#     ok fatal_count unplaced_count report
# =============================================================================

proc TT2CHK_get_lp_insts {lp_class} {
    switch -- $lp_class {
        level_shifter { set filter_expr {is_level_shifter == true} }
        isolation     { set filter_expr {is_isolation_cell == true} }
        retention     { set filter_expr {is_retention == true} }
        default       { error "TT2CHK: unsupported LP class '$lp_class'" }
    }

    set cells [get_cells -hierarchical -filter $filter_expr]
    set names {}
    if {[llength $cells] > 0} {
        set names [get_object_name $cells]
    }

    set insts {}
    set missing_db {}
    foreach name $names {
        set dbi {}
        catch { set dbi [get_db insts $name] }
        if {[llength $dbi] == 0} {
            lappend missing_db $name
        } else {
            foreach obj $dbi {
                lappend insts $obj
            }
        }
    }
    return [list $insts $missing_db]
}

proc TT2CHK_find_pg_pin {inst leaf_name} {
    set hits {}
    foreach p [get_db $inst .pg_pins] {
        set leaf [lindex [split [get_db $p .name] "/"] end]
        if {$leaf eq $leaf_name} {
            lappend hits $p
        }
    }

    if {[llength $hits] == 0} {
        return {}
    }
    if {[llength $hits] != 1} {
        error "TT2CHK: instance '[get_db $inst .name]' has [llength $hits] PG pins named '$leaf_name'"
    }
    return [lindex $hits 0]
}

proc TT2CHK_pg_net {pg_pin} {
    if {[llength $pg_pin] == 0} {
        return {}
    }
    set n {}
    catch { set n [get_db $pg_pin .net] }
    if {[llength $n] == 0} {
        return {}
    }
    return [lindex $n 0]
}

proc TT2CHK_add_net {net_obj class role net_counts net_names} {
    upvar 1 $net_counts counts
    upvar 1 $net_names names

    set net_name ""
    catch { set net_name [get_db $net_obj .name] }
    if {$net_name eq ""} {
        set net_name "<NO_NET_NAME>"
    }

    dict incr counts "${net_obj}|ALL"
    dict incr counts "${net_obj}|${class}"
    dict incr counts "${net_obj}|${role}"
    dict set names $net_obj $net_name
}

proc TT_check_lp_2ndpg {{stage manual}} {
    puts ""
    puts "======================================================================"
    puts " 2nd-PG CHECK : $stage"
    puts "======================================================================"

    # All reports must live under the flow report directory.
    set report_dir [tech_mv_report_dir 90 2ndpg_check]
    set rpt         [tech_mv_report_path 10 "2ndpg_check_${stage}" rpt 90 2ndpg_check]
    set problem_rpt [tech_mv_report_path 11 "2ndpg_check_${stage}_problem_cells" rpt 90 2ndpg_check]

    set fp  [open $rpt w]
    set pfp [open $problem_rpt w]

    puts $pfp "2nd-PG problem-cell report"
    puts $pfp "Stage       : $stage"
    puts $pfp "Main report : $rpt"
    puts $pfp "NOTE        : only real FAIL/problem cells are listed here"
    puts $pfp ""
    puts $fp "2nd-PG readiness check"
    puts $fp "Stage : $stage"
    puts $fp "NOTE  : read-only; no routing/fixing is performed"
    puts $fp ""

    lassign [TT2CHK_get_lp_insts level_shifter] ls_insts  ls_missing
    lassign [TT2CHK_get_lp_insts isolation]     iso_insts iso_missing
    lassign [TT2CHK_get_lp_insts retention]     ret_insts ret_missing

    set missing_db_count [expr {
        [llength $ls_missing] + [llength $iso_missing] + [llength $ret_missing]
    }]

    foreach n $ls_missing  {
        puts $fp  "FAIL MISSING_DB LS  $n"
        puts $pfp "FAIL MISSING_DB LS  cell=$n"
    }
    foreach n $iso_missing {
        puts $fp  "FAIL MISSING_DB ISO $n"
        puts $pfp "FAIL MISSING_DB ISO cell=$n"
    }
    foreach n $ret_missing {
        puts $fp  "FAIL MISSING_DB RET $n"
        puts $pfp "FAIL MISSING_DB RET cell=$n"
    }

    set ls_vdds 0
    set ls_vddl 0
    set ls_single 0
    set ls_unconnected 0
    set ls_ambiguous 0

    set iso_vdds 0
    set iso_single 0
    set iso_unconnected 0

    set ret_tvdd 0
    set ret_missing_pin 0
    set ret_unconnected 0

    set unplaced_count 0
    set net_counts [dict create]
    set net_names  [dict create]

    # -------------------------------------------------------------------------
    # LS
    # -------------------------------------------------------------------------
    foreach inst $ls_insts {
        set name [get_db $inst .name]
        set status [get_db $inst .place_status]
        if {$status eq "unplaced"} {
            incr unplaced_count
            puts $fp "INFO UNPLACED LS inst=$name"
        }

        set vdds [TT2CHK_find_pg_pin $inst [::tech_mv_library_value LP_PIN_SECONDARY_A]]
        set vddl [TT2CHK_find_pg_pin $inst [::tech_mv_library_value LP_PIN_SECONDARY_B]]

        set present 0
        set connected {}

        foreach pair [list [list [::tech_mv_library_value LP_PIN_SECONDARY_A] $vdds] [list [::tech_mv_library_value LP_PIN_SECONDARY_B] $vddl]] {
            lassign $pair role pin
            if {[llength $pin] == 0} {
                continue
            }
            incr present

            set n [TT2CHK_pg_net $pin]
            if {[llength $n] > 0} {
                lappend connected [list $role $n]
            }
        }

        if {$present == 0} {
            incr ls_single
            puts $fp "OK SINGLE_SUPPLY_LS inst=$name"
            continue
        }

        if {[llength $connected] == 0} {
            incr ls_unconnected
            puts $fp  "FAIL UNCONNECTED_SEC_PIN LS inst=$name candidates=[::tech_mv_library_value LP_PIN_SECONDARY_A]/[::tech_mv_library_value LP_PIN_SECONDARY_B]"
            puts $pfp "FAIL UNCONNECTED_SEC_PIN LS cell=$name candidates=[::tech_mv_library_value LP_PIN_SECONDARY_A]/[::tech_mv_library_value LP_PIN_SECONDARY_B]"
            continue
        }

        if {[llength $connected] > 1} {
            incr ls_ambiguous
            puts $fp  "FAIL AMBIGUOUS_SEC_PIN LS inst=$name"
            puts $pfp "FAIL AMBIGUOUS_SEC_PIN LS cell=$name"
            continue
        }

        lassign [lindex $connected 0] role n
        set nname [get_db $n .name]

        if {$role eq "[::tech_mv_library_value LP_PIN_SECONDARY_A]"} {
            incr ls_vdds
        } else {
            incr ls_vddl
        }

        TT2CHK_add_net $n LS $role net_counts net_names
        puts $fp "OK SEC_PIN LS inst=$name pin=$role net=$nname"
    }

    # -------------------------------------------------------------------------
    # ISO
    # -------------------------------------------------------------------------
    foreach inst $iso_insts {
        set name [get_db $inst .name]
        set status [get_db $inst .place_status]
        if {$status eq "unplaced"} {
            incr unplaced_count
            puts $fp "INFO UNPLACED ISO inst=$name"
        }

        set pin [TT2CHK_find_pg_pin $inst [::tech_mv_library_value LP_PIN_SECONDARY_A]]

        if {[llength $pin] == 0} {
            incr iso_single
            puts $fp "OK SINGLE_SUPPLY_ISO inst=$name"
            continue
        }

        set n [TT2CHK_pg_net $pin]
        if {[llength $n] == 0} {
            incr iso_unconnected
            puts $fp  "FAIL UNCONNECTED_SEC_PIN ISO inst=$name pin=[::tech_mv_library_value LP_PIN_SECONDARY_A]"
            puts $pfp "FAIL UNCONNECTED_SEC_PIN ISO cell=$name pin=[::tech_mv_library_value LP_PIN_SECONDARY_A]"
            continue
        }

        incr iso_vdds
        set nname [get_db $n .name]
        TT2CHK_add_net $n ISO [::tech_mv_library_value LP_PIN_SECONDARY_A] net_counts net_names
        puts $fp "OK SEC_PIN ISO inst=$name pin=[::tech_mv_library_value LP_PIN_SECONDARY_A] net=$nname"
    }

    # -------------------------------------------------------------------------
    # RET
    # -------------------------------------------------------------------------
    foreach inst $ret_insts {
        set name [get_db $inst .name]
        set status [get_db $inst .place_status]
        if {$status eq "unplaced"} {
            incr unplaced_count
            puts $fp "INFO UNPLACED RET inst=$name"
        }

        set pin [TT2CHK_find_pg_pin $inst [::tech_mv_library_value LP_PIN_RETENTION_AON]]

        if {[llength $pin] == 0} {
            incr ret_missing_pin
            puts $fp  "FAIL MISSING_SEC_PIN RET inst=$name expected=[::tech_mv_library_value LP_PIN_RETENTION_AON]"
            puts $pfp "FAIL MISSING_SEC_PIN RET cell=$name expected=[::tech_mv_library_value LP_PIN_RETENTION_AON]"
            continue
        }

        set n [TT2CHK_pg_net $pin]
        if {[llength $n] == 0} {
            incr ret_unconnected
            puts $fp  "FAIL UNCONNECTED_SEC_PIN RET inst=$name pin=[::tech_mv_library_value LP_PIN_RETENTION_AON]"
            puts $pfp "FAIL UNCONNECTED_SEC_PIN RET cell=$name pin=[::tech_mv_library_value LP_PIN_RETENTION_AON]"
            continue
        }

        incr ret_tvdd
        set nname [get_db $n .name]
        TT2CHK_add_net $n RET [::tech_mv_library_value LP_PIN_RETENTION_AON] net_counts net_names
        puts $fp "OK SEC_PIN RET inst=$name pin=[::tech_mv_library_value LP_PIN_RETENTION_AON] net=$nname"
    }

    set fatal_count [expr {
        $missing_db_count +
        $ls_unconnected +
        $ls_ambiguous +
        $iso_unconnected +
        $ret_missing_pin +
        $ret_unconnected
    }]

    # At post-place, any remaining unplaced LP cell is also a hard failure.
    set post_place_unplaced_fail 0
    if {$stage eq "post_place" && $unplaced_count > 0} {
        set post_place_unplaced_fail $unplaced_count
        incr fatal_count $unplaced_count

        foreach class_insts [list             [list LS  $ls_insts]             [list ISO $iso_insts]             [list RET $ret_insts]] {
            lassign $class_insts class inst_list
            foreach inst $inst_list {
                if {[get_db $inst .place_status] eq "unplaced"} {
                    puts $pfp "FAIL UNPLACED $class cell=[get_db $inst .name]"
                }
            }
        }
    }

    puts $fp ""
    puts $fp "======================================================================"
    puts $fp "SUMMARY"
    puts $fp "======================================================================"
    puts $fp "LS total               : [llength $ls_insts]"
    puts $fp "  [::tech_mv_library_value LP_PIN_SECONDARY_A] connected       : $ls_vdds"
    puts $fp "  [::tech_mv_library_value LP_PIN_SECONDARY_B] connected       : $ls_vddl"
    puts $fp "  single-supply        : $ls_single"
    puts $fp "  unconnected          : $ls_unconnected"
    puts $fp "  ambiguous            : $ls_ambiguous"
    puts $fp "ISO total              : [llength $iso_insts]"
    puts $fp "  [::tech_mv_library_value LP_PIN_SECONDARY_A] connected       : $iso_vdds"
    puts $fp "  single-supply        : $iso_single"
    puts $fp "  unconnected          : $iso_unconnected"
    puts $fp "RET total              : [llength $ret_insts]"
    puts $fp "  [::tech_mv_library_value LP_PIN_RETENTION_AON] connected       : $ret_tvdd"
    puts $fp "  missing [::tech_mv_library_value LP_PIN_RETENTION_AON]         : $ret_missing_pin"
    puts $fp "  unconnected [::tech_mv_library_value LP_PIN_RETENTION_AON]     : $ret_unconnected"
    puts $fp "Missing DB objects     : $missing_db_count"
    puts $fp "Unplaced LP instances  : $unplaced_count"
    puts $fp "Post-place unplaced fail: $post_place_unplaced_fail"
    puts $fp "Fatal count            : $fatal_count"
    puts $fp ""

    puts $fp "ACTUAL SECONDARY PG NETS"
    puts $fp "------------------------"
    foreach net_obj [dict keys $net_names] {
        set nname [dict get $net_names $net_obj]
        set all 0
        if {[dict exists $net_counts "${net_obj}|ALL"]} {
            set all [dict get $net_counts "${net_obj}|ALL"]
        }

        set ls 0
        set iso 0
        set ret 0
        foreach pair [list [list LS ls] [list ISO iso] [list RET ret]] {
            lassign $pair class var
            if {[dict exists $net_counts "${net_obj}|${class}"]} {
                set $var [dict get $net_counts "${net_obj}|${class}"]
            }
        }

        puts $fp "NET $nname  total=$all LS=$ls ISO=$iso RET=$ret"
    }

    if {$fatal_count == 0} {
        set ok 1
        puts $fp ""
        puts $fp "CHECK_STATUS PASS"

        puts $pfp "NO PROBLEM CELLS"
    } else {
        set ok 0
        puts $fp ""
        puts $fp "CHECK_STATUS FAIL"
    }

    puts $pfp ""
    puts $pfp "======================================================================"
    puts $pfp "PROBLEM SUMMARY"
    puts $pfp "======================================================================"
    puts $pfp "Missing DB            : $missing_db_count"
    puts $pfp "LS unconnected        : $ls_unconnected"
    puts $pfp "LS ambiguous          : $ls_ambiguous"
    puts $pfp "ISO unconnected       : $iso_unconnected"
    puts $pfp "RET missing [::tech_mv_library_value LP_PIN_RETENTION_AON]      : $ret_missing_pin"
    puts $pfp "RET unconnected [::tech_mv_library_value LP_PIN_RETENTION_AON]  : $ret_unconnected"
    puts $pfp "Post-place unplaced   : $post_place_unplaced_fail"
    puts $pfp "TOTAL FATAL           : $fatal_count"

    close $fp
    close $pfp

    puts "INFO: LS  total=[llength $ls_insts] [::tech_mv_library_value LP_PIN_SECONDARY_A]=$ls_vdds [::tech_mv_library_value LP_PIN_SECONDARY_B]=$ls_vddl single=$ls_single unconn=$ls_unconnected ambiguous=$ls_ambiguous"
    puts "INFO: ISO total=[llength $iso_insts] [::tech_mv_library_value LP_PIN_SECONDARY_A]=$iso_vdds single=$iso_single unconn=$iso_unconnected"
    puts "INFO: RET total=[llength $ret_insts] [::tech_mv_library_value LP_PIN_RETENTION_AON]=$ret_tvdd missing=$ret_missing_pin unconn=$ret_unconnected"
    puts "INFO: Missing DB = $missing_db_count"
    puts "INFO: Unplaced LP = $unplaced_count"
    puts "INFO: Fatal count = $fatal_count"
    puts "INFO: Report         = $rpt"
    puts "INFO: Problem cells  = $problem_rpt"

    if {$ok} {
        puts "INFO: 2nd-PG CHECK PASS ($stage)"
    } else {
        puts "WARNING: 2nd-PG CHECK FAIL ($stage) -- inspect $rpt"
    }

    puts "======================================================================"

    return [dict create \
        ok $ok \
        fatal_count $fatal_count \
        unplaced_count $unplaced_count \
        report $rpt \
        problem_report $problem_rpt]
}