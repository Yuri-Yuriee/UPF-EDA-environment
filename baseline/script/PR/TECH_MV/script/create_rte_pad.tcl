# Load definitions only; no APR action or setup reload is performed here.
if {![llength [info commands ::tech_mv_library_value]]} {
    if {[info exists ::TOOL_DIR]} {
        source -quiet [file join $::TECH_MV_RUNTIME_ROOT .. script PR TECH_MV script 00_common private_parameter_config.tcl]
    } else {
        source -quiet [file join $::TECH_MV_RUNTIME_ROOT .. script PR TECH_MV script 00_common private_parameter_config.tcl]
    }
}
# =============================================================================
# create_rte_pad.tcl
# =============================================================================
# Maintain enough RTE pads for the configured supply count.
#
# Guard behavior (default):
#   - Reuse existing RTE pads first.
#   - If existing RTE-pad capacity is already enough, create NOTHING.
#   - If capacity is short, create only the deficit.
#   - Never delete extra existing RTE pads.
#   - A reused RTE pin may be connected to RTE_PAD_NET only when unconnected.
#     If it is already connected to a different net, stop instead of hijacking it.
#
# The existing RTE pad definition is identified from RTE_PAD_TEMPLATE_INSTANCE.
# Additional auto-created RTE-pad instances clone the template base cell.
#
# This helper is sourced by create_pg_pad.tcl after the PG/CUT instances exist.
# =============================================================================

puts "User script [info script]"

proc tech_mv_rte_safe_token {name} {
    set safe $name
    regsub -all {[^A-Za-z0-9_]+} $safe {_} safe
    return [string trim $safe _]
}

proc tech_mv_find_inst_by_local_name {local_name} {
    set patterns [list $local_name "*/$local_name"]

    if {[info exists ::TOP_MODULE]} {
        set patterns [linsert $patterns 1 "${::TOP_MODULE}/$local_name"]
    }

    foreach pattern $patterns {
        if {![catch {set matches [get_db insts $pattern]}] &&
            [llength $matches] > 0} {
            return [lindex $matches 0]
        }
    }

    return ""
}

proc tech_mv_inst_local_name {inst_obj} {
    set full_name [get_db $inst_obj .name]
    if {$full_name eq ""} {
        return ""
    }
    return [lindex [split $full_name /] end]
}

proc tech_mv_rte_pad_name_for_supply {supply index} {
    if {$index == 0} {
        return $::RTE_PAD_TEMPLATE_INSTANCE
    }

    return "${::RTE_PAD_INSTANCE_PREFIX}_[tech_mv_rte_safe_token $supply]"
}

proc tech_mv_rte_pin_objects {inst_obj} {
    set pins {}

    if {![catch {
        set p [get_db $inst_obj .pins -if ".base_name == $::RTE_PAD_PIN"]
    }] && [llength $p] > 0} {
        set pins [concat $pins $p]
    }

    if {![catch {
        set p [get_db $inst_obj .pg_pins -if ".base_name == $::RTE_PAD_PIN"]
    }] && [llength $p] > 0} {
        set pins [concat $pins $p]
    }

    return $pins
}

proc tech_mv_rte_pin_net_name {inst_obj} {
    set pins [tech_mv_rte_pin_objects $inst_obj]
    if {[llength $pins] == 0} {
        return "__NO_RTE_PIN__"
    }

    set net_names {}
    foreach pin_obj $pins {
        set n ""
        catch {set n [get_db $pin_obj .net.base_name]}
        if {$n ne "" && [lsearch -exact $net_names $n] < 0} {
            lappend net_names $n
        }
    }

    if {[llength $net_names] == 0} {
        return ""
    }
    if {[llength $net_names] > 1} {
        return "__MULTIPLE__:[join $net_names ,]"
    }
    return [lindex $net_names 0]
}

proc tech_mv_rte_ensure_target_net {inst_obj} {
    set inst_name [tech_mv_inst_local_name $inst_obj]
    set current_net [tech_mv_rte_pin_net_name $inst_obj]

    if {$current_net eq "__NO_RTE_PIN__"} {
        error "RTE pad '$inst_name' has no pin '$::RTE_PAD_PIN'"
    }

    if {[string match "__MULTIPLE__:*" $current_net]} {
        error "RTE pad '$inst_name' has inconsistent '$::RTE_PAD_PIN' connectivity: $current_net"
    }

    if {$current_net eq ""} {
        puts "INFO: Reused RTE pad '$inst_name' has an unconnected $::RTE_PAD_PIN pin; connect it to $::RTE_PAD_NET"
        connect_pin \
            -inst $inst_name \
            -pin $::RTE_PAD_PIN \
            -net $::RTE_PAD_NET
        return
    }

    if {$current_net ne $::RTE_PAD_NET} {
        error "RTE pad '$inst_name/$::RTE_PAD_PIN' is already connected to '$current_net', expected '$::RTE_PAD_NET'; refusing to overwrite existing connectivity"
    }
}

proc tech_mv_collect_existing_rte_pads {template_obj template_base} {
    set result {}
    set seen [dict create]

    # Always prefer the configured template instance first.
    if {[llength [tech_mv_rte_pin_objects $template_obj]] == 0} {
        error "RTE template '$::RTE_PAD_TEMPLATE_INSTANCE' has no pin '$::RTE_PAD_PIN'"
    }
    set template_name [tech_mv_inst_local_name $template_obj]
    lappend result $template_obj
    dict set seen $template_name 1

    # Find every existing instance using the same base cell as the template.
    # This intentionally does NOT depend on the instance name, so an existing
    # user-created RTE pad can satisfy capacity without forcing another clone.
    set same_base {}
    set filter ".base_cell.name == $template_base"
    if {[catch {set same_base [get_db insts -if $filter]} err]} {
        error "Failed to query existing RTE pads using base cell '$template_base': $err"
    }

    set sortable {}
    foreach inst_obj $same_base {
        set local_name [tech_mv_inst_local_name $inst_obj]
        if {$local_name eq "" || [dict exists $seen $local_name]} {
            continue
        }
        if {[llength [tech_mv_rte_pin_objects $inst_obj]] == 0} {
            continue
        }
        lappend sortable [list $local_name $inst_obj]
    }

    foreach item [lsort -dictionary -index 0 $sortable] {
        set local_name [lindex $item 0]
        set inst_obj   [lindex $item 1]
        lappend result $inst_obj
        dict set seen $local_name 1
    }

    return $result
}

proc tech_mv_create_supply_rte_pads {} {
    if {!$::ENABLE_SUPPLY_RTE_PADS} {
        set ::AUTO_IO_RTE_PAD_NAMES {}
        set ::AUTO_IO_RTE_PAD_BY_SUPPLY [dict create]
        set ::AUTO_IO_RTE_PAD_CREATED_NAMES {}
        set ::AUTO_IO_RTE_PAD_CREATED_BY_SUPPLY [dict create]
        puts "INFO: Supply RTE-pad generation is disabled."
        return {}
    }

    set supplies $::RTE_PAD_SUPPLY_NETS
    set required_count [llength $supplies]
    if {$required_count == 0} {
        error "ENABLE_SUPPLY_RTE_PADS=true but RTE_PAD_SUPPLY_NETS is empty"
    }

    if {[string tolower $::RTE_PAD_SIDE] ne "top"} {
        error "Current supply-RTE placement supports RTE_PAD_SIDE=top only"
    }

    if {[string tolower $::RTE_PAD_DIRECTION] ne "counterclockwise"} {
        error "Current supply-RTE placement supports RTE_PAD_DIRECTION=counterclockwise only"
    }

    set template_obj [tech_mv_find_inst_by_local_name $::RTE_PAD_TEMPLATE_INSTANCE]
    if {$template_obj eq ""} {
        error "Required RTE template instance '$::RTE_PAD_TEMPLATE_INSTANCE' was not found"
    }

    set template_base [get_db $template_obj .base_cell.name]
    if {$template_base eq ""} {
        error "Cannot resolve base cell of RTE template '$::RTE_PAD_TEMPLATE_INSTANCE'"
    }

    if {![info exists ::RTE_PAD_REUSE_EXISTING]} {
        set ::RTE_PAD_REUSE_EXISTING true
    }

    set existing_objs {}
    if {$::RTE_PAD_REUSE_EXISTING} {
        set existing_objs [tech_mv_collect_existing_rte_pads $template_obj $template_base]
    } else {
        set existing_objs [list $template_obj]
    }

    set existing_names {}
    foreach inst_obj $existing_objs {
        lappend existing_names [tech_mv_inst_local_name $inst_obj]
    }

    set existing_count [llength $existing_objs]
    set deficit [expr {$required_count - $existing_count}]
    if {$deficit < 0} {
        set deficit 0
    }

    puts "INFO: RTE required count = $required_count"
    puts "INFO: Existing RTE pads = $existing_count : $existing_names"
    puts "INFO: RTE pad deficit   = $deficit"

    if {$::RTE_PAD_REUSE_EXISTING && $existing_count >= $required_count} {
        puts "INFO: Existing RTE-pad capacity is sufficient; no new RTE pad will be created."
    } elseif {$deficit > 0} {
        puts "INFO: Existing RTE-pad capacity is insufficient; create only $deficit additional RTE pad(s)."
    }

    set rte_names {}
    set rte_by_supply [dict create]
    set created_names {}
    set created_by_supply [dict create]

    # Reuse existing RTE pads first.  Only create when the required supply
    # count exceeds actual existing RTE-pad capacity.
    set index 0
    foreach supply $supplies {
        if {$index < $existing_count} {
            set inst_obj [lindex $existing_objs $index]
            set inst_name [tech_mv_inst_local_name $inst_obj]

            set current_base [get_db $inst_obj .base_cell.name]
            if {$current_base ne $template_base} {
                error "Existing RTE pad '$inst_name' uses base cell '$current_base', expected '$template_base'"
            }

            tech_mv_rte_ensure_target_net $inst_obj
            puts "INFO: Reusing existing RTE pad: supply=$supply inst=$inst_name"
        } else {
            set inst_name [tech_mv_rte_pad_name_for_supply $supply $index]

            # Refuse to silently overwrite a same-name non-RTE instance.
            set collision [tech_mv_find_inst_by_local_name $inst_name]
            if {$collision ne ""} {
                set collision_base [get_db $collision .base_cell.name]
                if {$collision_base ne $template_base ||
                    [llength [tech_mv_rte_pin_objects $collision]] == 0} {
                    error "Cannot create RTE pad '$inst_name': an existing non-matching instance with that name already exists"
                }
                set inst_obj $collision
                tech_mv_rte_ensure_target_net $inst_obj
                puts "INFO: Reusing expected-name RTE pad discovered during creation step: supply=$supply inst=$inst_name"
            } else {
                puts "INFO: Creating ONLY missing RTE pad: supply=$supply inst=$inst_name base=$template_base"
                create_inst -name $inst_name -base_cell $template_base
                connect_pin \
                    -inst $inst_name \
                    -pin $::RTE_PAD_PIN \
                    -net $::RTE_PAD_NET

                set inst_obj [tech_mv_find_inst_by_local_name $inst_name]
                if {$inst_obj eq ""} {
                    error "Failed to create RTE pad '$inst_name' for supply '$supply'"
                }

                lappend created_names $inst_name
                dict set created_by_supply $supply $inst_name
            }
        }

        dict set rte_by_supply $supply $inst_name
        lappend rte_names $inst_name
        incr index
    }

    set ::AUTO_IO_RTE_PAD_NAMES $rte_names
    set ::AUTO_IO_RTE_PAD_BY_SUPPLY $rte_by_supply
    set ::AUTO_IO_RTE_PAD_CREATED_NAMES $created_names
    set ::AUTO_IO_RTE_PAD_CREATED_BY_SUPPLY $created_by_supply

    # RTE pads do not receive FILL_IN_CELL_BOND_PAD_041 bond pads.
    set ::AUTO_RTE_BOND_PAD_TARGET_PINS {}

    puts "INFO: RTE supply types = $required_count : $supplies"
    puts "INFO: RTE pads used    = [llength $rte_names] : $rte_names"
    puts "INFO: RTE pads created = [llength $created_names] : $created_names"
    puts [::tech_mv_library_value LIB_TEXT_018]

    return $rte_names
}

tech_mv_create_supply_rte_pads
