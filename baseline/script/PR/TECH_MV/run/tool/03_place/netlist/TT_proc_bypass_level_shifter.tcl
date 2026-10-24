# Runtime adapter preserves the historical logical source path.
if {[info exists ::TECH_MV_RUNTIME_ROOT]} {
    info script [file join $::TECH_MV_RUNTIME_ROOT run/tool/03_place/netlist/TT_proc_bypass_level_shifter.tcl]
}
# Load the output-path helper if this stage is sourced by an older live session.
if {![llength [info commands ::tech_mv_native_report_command]]} {
    source -quiet [file join $::TOOL_DIR 00_common TT_runtime_output_helpers.tcl]
}
# =============================================================================
# TT_bypass_level_shifter_v5.tcl
# =============================================================================
# Purpose
#   Remove a level-shifter instance that is NOT a buffer/inverter, reconnect
#   the logical loads on its output side to the logical net on its input side,
#   then delete the LS with delete_inst.
#
# Why v5
#   ecoDeleteRepeater / eco_delete_repeater only accepts buffers/inverters.
#   Real level-shifter library cells such as LVLHLD* are not necessarily
#   classified as buffers/inverters, so v5 performs an explicit logical ECO:
#
#       input_net -> [LS] -> output_net -> loads
#
#   becomes:
#
#       input_net ---------------------> loads
#
#   and then:
#
#       delete_inst -inst <LS>
#
# Hierarchy
#   Prefer legacy attachTerm when available because Innovus can create the
#   needed hierarchical ports automatically when the destination net is in a
#   different hierarchy. In Common UI-only environments, fall back to
#   disconnect_pin/connect_pin.
#
# Safety
#   - Only cells classified by Innovus as .is_level_shifter == true.
#   - Only simple 1 logical input / 1 logical output LS cells.
#   - Aborts if another logical output driver exists on the LS output net.
#   - Does not touch .pg_pins or power-net names.
#   - Does not delete the old output net automatically.
#   - Self-contained report path; no external report helper dependency.
#
# Usage
#   source -quiet [file join $TOOL_DIR 03_place netlist TT_proc_bypass_level_shifter.tcl]
#
#   TT_LS3_debug_one u_TOP/u_WDT_wrapper/u_WDT/WDT_CG_UPF_LS
#   TT_LS3_bypass_one u_TOP/u_WDT_wrapper/u_WDT/WDT_CG_UPF_LS
#   TT_LS_bypass_matching *u_WDT_wrapper*
#
# Report
#   $REPORT_DIR/TT_bypass_level_shifter_v5.rpt
# =============================================================================

proc TT_LS3_report_path {} {
    if {[info exists ::REPORT_DIR] && $::REPORT_DIR ne ""} {
        set dir $::REPORT_DIR
    } else {
        set dir [file normalize reports]
    }
    file mkdir $dir
    return [file join $dir TT_bypass_level_shifter_v5.rpt]
}

proc TT_LS3_get_names {{pattern *}} {
    set cells [get_cells -hierarchical -filter {is_level_shifter == true}]
    if {[llength $cells] == 0} {
        return {}
    }

    set result {}
    foreach n [get_object_name $cells] {
        if {[string match $pattern $n]} {
            lappend result $n
        }
    }
    return $result
}

proc TT_LS3_get_inst {name} {
    set obj {}
    catch { set obj [get_db insts $name] }
    if {[llength $obj] != 1} {
        return {}
    }
    return [lindex $obj 0]
}

proc TT_LS3_pin_net_name {pin} {
    set n {}
    catch { set n [get_db $pin .net] }
    if {[llength $n] == 0} {
        return ""
    }

    set name ""
    catch { set name [get_db [lindex $n 0] .name] }
    return $name
}

proc TT_LS3_signal_io {inst} {
    set inputs {}
    set outputs {}
    set others {}

    foreach p [get_db $inst .pins] {
        set full [get_db $p .name]
        set leaf [lindex [split $full "/"] end]

        set dir ""
        catch { set dir [string tolower [get_db $p .direction]] }

        set net_name [TT_LS3_pin_net_name $p]

        switch -- $dir {
            in -
            input {
                lappend inputs [dict create obj $p full $full leaf $leaf net $net_name]
            }
            out -
            output {
                lappend outputs [dict create obj $p full $full leaf $leaf net $net_name]
            }
            default {
                lappend others [dict create obj $p full $full leaf $leaf dir $dir net $net_name]
            }
        }
    }

    return [dict create inputs $inputs outputs $outputs others $others]
}

proc TT_LS3_output_loads {ls_inst out_pin_obj out_net_name} {
    set net_coll [get_nets $out_net_name]
    if {[llength $net_coll] == 0} {
        error "TT_LS3: output net '$out_net_name' not found."
    }

    set conn {}
    if {[catch {set conn [all_connected -leaf $net_coll]} err]} {
        error "TT_LS3: all_connected failed for '$out_net_name': $err"
    }

    set conn_names {}
    if {[llength $conn] > 0} {
        set conn_names [get_object_name $conn]
    }

    set ls_out_full [get_db $out_pin_obj .name]
    set loads {}
    set foreign_drivers {}
    set unsupported {}

    foreach full $conn_names {
        if {$full eq $ls_out_full} {
            continue
        }

        set toks [split $full "/"]
        if {[llength $toks] < 2} {
            lappend unsupported [list $full TOP_OR_HIER_PORT]
            continue
        }

        set leaf [lindex $toks end]
        set inst_name [join [lrange $toks 0 end-1] "/"]

        set inst_obj {}
        catch {set inst_obj [get_db insts $inst_name]}
        if {[llength $inst_obj] != 1} {
            lappend unsupported [list $full INST_NOT_FOUND]
            continue
        }
        set inst_obj [lindex $inst_obj 0]

        set pin_obj {}
        foreach p [get_db $inst_obj .pins] {
            set pfull [get_db $p .name]
            if {$pfull eq $full} {
                set pin_obj $p
                break
            }

            set pleaf [lindex [split $pfull "/"] end]
            if {$pleaf eq $leaf} {
                set pin_obj $p
            }
        }

        if {[llength $pin_obj] == 0} {
            lappend unsupported [list $full PIN_NOT_FOUND]
            continue
        }

        set dir ""
        catch {set dir [string tolower [get_db $pin_obj .direction]]}

        switch -- $dir {
            in -
            input -
            inout {
                lappend loads [dict create \
                    obj $pin_obj \
                    full $full \
                    inst $inst_name \
                    leaf $leaf \
                    old_net $out_net_name]
            }
            out -
            output {
                lappend foreign_drivers [dict create \
                    full $full \
                    inst $inst_name \
                    leaf $leaf]
            }
            default {
                lappend unsupported [list $full "DIR=$dir"]
            }
        }
    }

    if {[llength $foreign_drivers] > 0} {
        error "TT_LS3: output net '$out_net_name' has another output driver: $foreign_drivers"
    }

    if {[llength $unsupported] > 0} {
        error "TT_LS3: output net '$out_net_name' has unsupported/non-leaf connections: $unsupported"
    }

    return $loads
}

proc TT_LS3_reconnect_load {load new_net_name} {
    set inst_name [dict get $load inst]
    set pin_leaf  [dict get $load leaf]
    set old_net   [dict get $load old_net]

    if {[llength [info commands attachTerm]] > 0} {
        attachTerm $inst_name $pin_leaf $new_net_name
        return
    }

    if {[llength [info commands disconnect_pin]] == 0 ||
        [llength [info commands connect_pin]] == 0} {
        error "TT_LS3: neither attachTerm nor disconnect_pin/connect_pin is available."
    }

    disconnect_pin -inst $inst_name -pin $pin_leaf -net $old_net
    connect_pin    -inst $inst_name -pin $pin_leaf -net $new_net_name
}

proc TT_LS3_is_leaf_connected {net_name full_pin_name} {
    set net_coll [get_nets $net_name]
    if {[llength $net_coll] == 0} {
        return 0
    }

    set conn {}
    catch { set conn [all_connected -leaf $net_coll] }
    if {[llength $conn] == 0} {
        return 0
    }

    set names [get_object_name $conn]
    if {[lsearch -exact $names $full_pin_name] >= 0} {
        return 1
    }
    return 0
}

proc TT_LS3_debug_output_net {inst_name} {
    set inst [TT_LS3_get_inst $inst_name]
    if {[llength $inst] == 0} {
        error "TT_LS3_debug_output_net: instance '$inst_name' not found."
    }

    set io [TT_LS3_signal_io $inst]
    set outs [dict get $io outputs]
    if {[llength $outs] != 1} {
        error "TT_LS3_debug_output_net: '$inst_name' output count=[llength $outs], expected 1."
    }

    set out_info [lindex $outs 0]
    set out_net [dict get $out_info net]

    puts "======================================================================"
    puts " LS OUTPUT-NET DEBUG"
    puts "======================================================================"
    puts "INST      : $inst_name"
    puts "OUTPUT NET: $out_net"

    set conn [all_connected -leaf [get_nets $out_net]]
    set names {}
    if {[llength $conn] > 0} {
        set names [get_object_name $conn]
    }

    puts "CONNECTED LEAF OBJECTS:"
    foreach n $names {
        puts "  $n"
    }
    puts "======================================================================"
    return $names
}

proc TT_LS3_precheck_one {inst_name} {
    set inst [TT_LS3_get_inst $inst_name]
    if {[llength $inst] == 0} {
        error "TT_LS3: instance '$inst_name' not found."
    }

    set is_ls false
    catch { set is_ls [get_db $inst .is_level_shifter] }
    if {$is_ls ne "true" && $is_ls ne "1"} {
        error "TT_LS3: '$inst_name' is not classified as a level shifter."
    }

    set io [TT_LS3_signal_io $inst]
    set ins  [dict get $io inputs]
    set outs [dict get $io outputs]

    if {[llength $ins] != 1 || [llength $outs] != 1} {
        error "TT_LS3: '$inst_name' is not simple 1-in/1-out. inputs=[llength $ins] outputs=[llength $outs]"
    }

    set in_info  [lindex $ins 0]
    set out_info [lindex $outs 0]

    set in_net  [dict get $in_info net]
    set out_net [dict get $out_info net]

    if {$in_net eq "" || $out_net eq ""} {
        error "TT_LS3: '$inst_name' has an unconnected logical input/output. input='$in_net' output='$out_net'"
    }

    if {$in_net eq $out_net} {
        error "TT_LS3: '$inst_name' input/output are already on the same net '$in_net'."
    }

    set loads [TT_LS3_output_loads $inst [dict get $out_info obj] $out_net]

    return [dict create \
        inst_obj $inst \
        input_pin [dict get $in_info full] \
        output_pin [dict get $out_info full] \
        input_net $in_net \
        output_net $out_net \
        loads $loads]
}

proc TT_LS3_debug_one {inst_name} {
    set info [TT_LS3_precheck_one $inst_name]

    puts ""
    puts "======================================================================"
    puts " LS BYPASS PRECHECK"
    puts "======================================================================"
    puts "INST      : $inst_name"
    puts "INPUT PIN : [dict get $info input_pin]"
    puts "INPUT NET : [dict get $info input_net]"
    puts "OUTPUT PIN: [dict get $info output_pin]"
    puts "OUTPUT NET: [dict get $info output_net]"
    puts "LOAD COUNT: [llength [dict get $info loads]]"

    foreach load [dict get $info loads] {
        puts "  LOAD: [dict get $load full]"
    }
    puts "======================================================================"

    return $info
}

proc TT_LS3_bypass_one {inst_name} {
    set rpt [TT_LS3_report_path]
    set fp [open $rpt a]

    set info [TT_LS3_precheck_one $inst_name]
    set in_net  [dict get $info input_net]
    set out_net [dict get $info output_net]
    set loads   [dict get $info loads]

    set before_ls_count [llength [TT_LS3_get_names *]]

    puts ""
    puts "======================================================================"
    puts " BYPASS LEVEL SHIFTER"
    puts "======================================================================"
    puts "INST       : $inst_name"
    puts "INPUT NET  : $in_net"
    puts "OUTPUT NET : $out_net"
    puts "LOADS      : [llength $loads]"
    puts "LS before  : $before_ls_count"

    puts $fp ""
    puts $fp "======================================================================"
    puts $fp "BYPASS inst=$inst_name"
    puts $fp "input_net=$in_net"
    puts $fp "output_net=$out_net"
    puts $fp "load_count=[llength $loads]"

    set moved {}
    foreach load $loads {
        set full [dict get $load full]
        puts "INFO: reconnect $full : $out_net -> $in_net"
        puts $fp "MOVE load=$full old_net=$out_net new_net=$in_net"

        if {[catch {TT_LS3_reconnect_load $load $in_net} err opts]} {
            puts $fp "FAIL reconnect load=$full error={$err}"
            close $fp
            return -options $opts $err
        }
        lappend moved $full
    }

    if {[llength [info commands delete_inst]] == 0} {
        puts $fp "FAIL delete_inst command unavailable"
        close $fp
        error "TT_LS3: delete_inst is not available."
    }

    puts "INFO: delete_inst -inst $inst_name"
    if {[catch {delete_inst -inst $inst_name -verbose} err opts]} {
        puts $fp "FAIL delete_inst inst=$inst_name error={$err}"
        close $fp
        return -options $opts $err
    }

    if {[llength [TT_LS3_get_inst $inst_name]] != 0} {
        puts $fp "FAIL inst=$inst_name reason=INSTANCE_STILL_EXISTS"
        close $fp
        error "TT_LS3: '$inst_name' still exists after delete_inst."
    }

    set verify_fail {}
    foreach full $moved {
        if {![TT_LS3_is_leaf_connected $in_net $full]} {
            lappend verify_fail $full
        }
    }

    set after_ls_count [llength [TT_LS3_get_names *]]
    set delta [expr {$before_ls_count - $after_ls_count}]

    puts "LS after   : $after_ls_count"
    puts "LS delta   : $delta"

    if {[llength $verify_fail] > 0} {
        puts $fp "FAIL inst=$inst_name reason=LOAD_CONNECTIVITY_VERIFY_FAIL loads=$verify_fail"
        close $fp
        error "TT_LS3: '$inst_name' deleted, but [llength $verify_fail] loads failed connectivity verification: $verify_fail"
    }

    puts $fp "PASS inst=$inst_name ls_before=$before_ls_count ls_after=$after_ls_count delta=$delta"
    close $fp

    puts "INFO: PASS: $inst_name removed and loads reconnected."
    puts "INFO: Old output net '$out_net' was intentionally left in DB."
    puts "======================================================================"

    return 1
}

proc TT_LS3_bypass_matching {pattern} {
    set names [TT_LS3_get_names $pattern]

    puts ""
    puts "======================================================================"
    puts " LEVEL SHIFTER BYPASS BATCH"
    puts "======================================================================"
    puts "Pattern : $pattern"
    puts "Matched : [llength $names]"

    if {[llength $names] == 0} {
        puts "INFO: Nothing to do."
        return
    }

    set bad {}
    foreach n $names {
        if {[catch {TT_LS3_precheck_one $n} err]} {
            lappend bad [list $n $err]
        }
    }

    if {[llength $bad] > 0} {
        puts "ERROR: Batch precheck failed. No LS has been removed."
        foreach item $bad {
            puts "  [lindex $item 0]"
            puts "    [lindex $item 1]"
        }
        error "TT_LS3_bypass_matching: [llength $bad] matched LS cells failed precheck."
    }

    set done 0
    foreach n $names {
        TT_LS3_bypass_one $n
        incr done
    }

    puts ""
    puts "======================================================================"
    puts "BATCH COMPLETE"
    puts "Removed/bypassed: $done"
    puts "Remaining LS    : [llength [TT_LS3_get_names *]]"
    puts "Running check_netlist..."
    tech_mv_native_report_command 03 netlist [list check_netlist -out_file [tech_mv_output_path report checknetlist.rpt 03 netlist]]
    puts "Report          : [TT_LS3_report_path]"
    puts "======================================================================"
}

proc TT_LS_debug_one {inst_name} {
    puts "INFO: TT_bypass_level_shifter_v5 active"
    return [TT_LS3_debug_one $inst_name]
}

proc TT_LS_bypass {inst_name} {
    puts "INFO: TT_bypass_level_shifter_v5 active"
    return [TT_LS3_bypass_one $inst_name]
}

proc TT_LS_bypass_matching {pattern} {
    puts "INFO: TT_bypass_level_shifter_v5 active"
    puts "INFO: Method = reconnect downstream loads + delete_inst"
    return [TT_LS3_bypass_matching $pattern]
}

puts "INFO: Loaded TT_bypass_level_shifter_v5.tcl"
puts "INFO: ecoDeleteRepeater is NOT used by this version."
puts "INFO: Old command names are redirected to the v5 implementation."
