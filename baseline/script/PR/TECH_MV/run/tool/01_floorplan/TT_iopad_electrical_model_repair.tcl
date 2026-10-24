# Runtime adapter preserves the historical logical source path.
if {[info exists ::TECH_MV_RUNTIME_ROOT]} {
    info script [file join $::TECH_MV_RUNTIME_ROOT run/tool/01_floorplan/TT_iopad_electrical_model_repair.tcl]
}
# Load the existing private value accessor only; no setup reload.
if {![llength [info commands ::tech_mv_library_value]]} {
    if {[info exists ::TOOL_DIR]} {
        source -quiet [file join $::TECH_MV_RUNTIME_ROOT .. script PR TECH_MV script 00_common private_parameter_config.tcl]
    } else {
        source -quiet [file join $::TECH_MV_RUNTIME_ROOT .. script PR TECH_MV script 00_common private_parameter_config.tcl]
    }
}
# =============================================================================
# TT_iopad_electrical_model_repair.tcl
# =============================================================================
# TECH_MV Stage00 IO-pad electrical/topology model, repair and regeneration.
#
# Seed authority:
#   Existing IO_FILE is parsed first and used to derive the current PAD-ring
#   topology / electrical-domain state.
#
# Public commands:
#   TT_IOPAD_ELEC help
#   TT_IOPAD_ELEC model
#   TT_IOPAD_ELEC check
#   TT_IOPAD_ELEC run
#
# Recommended:
#   source -quiet run/tool/01_floorplan/TT_iopad_electrical_model_repair.tcl
#   TT_IOPAD_ELEC run
#
# 'run' performs exactly:
#   1. Parse current IO_FILE.
#   2. Build topology/electrical model from IO-file ordering.
#   3. Check Innovus DB connectivity.
#   4. Repair recoverable PAD connectivity.
#   5. Use existing TT_IOPAD_RING build/generate to normalize configured
#      RTE/boundary cell/PG topology and regenerate IO_FILE.
#   6. Parse regenerated IO_FILE and perform ONE final re-check.
#
# No automatic read_io_file is performed.
#
# Electrical expectations:
#   Core-power PAD:
#       configured supply/ground pin    -> its CORE_<SUPPLY>_PG* supply
#       configured supply/ground pin    -> common ground
#
#   IO-power PAD:
#       configured supply/ground pin -> IO supply
#       configured supply/ground pin -> common ground
#
#   RTE PAD:
#       configured supply/ground pin    -> core supply derived from boundary cell segment
#       configured supply/ground pin -> IO supply
#       configured supply/ground pin    -> common ground
#       configured supply/ground pin -> common ground
#       RTE    -> configured RTE net
#
#   Signal PAD:
#       For whichever of these PG pins physically exist:
#       configured supply/ground pin    -> current boundary cell-derived core supply
#       configured supply/ground pin -> IO supply
#       configured supply/ground pin    -> common ground
#       configured supply/ground pin -> common ground
#
# boundary cell state:
#   boundary cell_<SUPPLY>_<SIDE>1 : enter that core-supply segment
#   boundary cell_<SUPPLY>_<SIDE>2 : exit back to the base core supply
#
# Repair:
#   PG pins use globalNetConnect ... -type pgpin ... -override.
#   Ordinary RTE signal pin uses attachTerm when available, otherwise
#   disconnect_pin/connect_pin.
#
# Safety:
#   - Does not create supply nets.
#   - Does not rename any existing design object.
#   - Does not route.
#   - Does not read regenerated IO_FILE back into Innovus.
#   - Does not loop final checks.
# =============================================================================

# -----------------------------------------------------------------------------
# General helpers
# -----------------------------------------------------------------------------
proc tt_iopad_elec_require_runtime {} {
    foreach v {IO_FILE TOOL_DIR SCRIPT_DIR} {
        if {![info exists ::$v] || [set ::$v] eq ""} {
            error "TT_IOPAD_ELEC: runtime variable '$v' is not initialized. Source init.setup first."
        }
    }

    if {![file isfile $::IO_FILE]} {
        error "TT_IOPAD_ELEC: IO_FILE does not exist: $::IO_FILE"
    }
}

proc tt_iopad_elec_report_path {} {
    if {[info exists ::REPORT_DIR] && $::REPORT_DIR ne ""} {
        set dir [file join $::REPORT_DIR 00_import]
    } else {
        set dir [file normalize reports/00_import]
    }
    file mkdir $dir
    return [file join $dir 00_91_iopad_electrical_model_repair.rpt]
}

proc tt_iopad_elec_local_inst_name {raw_name} {
    set n $raw_name
    regsub {^inst:} $n {} n
    set n [string trimleft $n /]

    if {[info exists ::TOP_MODULE] && $::TOP_MODULE ne ""} {
        set p "${::TOP_MODULE}/"
        if {[string first $p $n] == 0} {
            set n [string range $n [string length $p] end]
        }
    }
    return $n
}

proc tt_iopad_elec_find_inst {local_name} {
    set patterns [list $local_name "*/$local_name"]
    if {[info exists ::TOP_MODULE] && $::TOP_MODULE ne ""} {
        set patterns [linsert $patterns 1 "${::TOP_MODULE}/$local_name"]
    }

    foreach pat $patterns {
        set objs {}
        if {![catch {set objs [get_db insts $pat]}] && [llength $objs] > 0} {
            if {[llength $objs] == 1} {
                return [lindex $objs 0]
            }

            # Prefer an exact local-name match if a wildcard returns >1.
            foreach obj $objs {
                set n ""
                catch {set n [tt_iopad_elec_local_inst_name [get_db $obj .name]]}
                if {$n eq $local_name} {
                    return $obj
                }
            }
        }
    }
    return {}
}

proc tt_iopad_elec_obj_name {obj} {
    set n ""
    catch {set n [get_db $obj .name]}
    return $n
}

proc tt_iopad_elec_net_name_from_obj {net_obj} {
    if {[llength $net_obj] == 0} {
        return ""
    }

    set n ""
    if {![catch {set n [get_db [lindex $net_obj 0] .base_name]}] && $n ne ""} {
        return $n
    }
    catch {set n [get_db [lindex $net_obj 0] .name]}
    return $n
}

# Return:
#   dict create exists 0
# or
#   dict create exists 1 kind pg|signal obj <pin_obj> actual_net <name>
proc tt_iopad_elec_find_pin {inst leaf_name} {
    # PG pins first.
    set matches {}
    foreach p [get_db $inst .pg_pins] {
        set base ""
        catch {set base [get_db $p .base_name]}
        if {$base eq ""} {
            set full ""
            catch {set full [get_db $p .name]}
            set base [lindex [split $full "/"] end]
        }
        if {$base eq $leaf_name} {
            lappend matches $p
        }
    }

    if {[llength $matches] > 1} {
        error "TT_IOPAD_ELEC: instance '[tt_iopad_elec_obj_name $inst]' has multiple PG pins named '$leaf_name'."
    }
    if {[llength $matches] == 1} {
        set p [lindex $matches 0]
        set net {}
        catch {set net [get_db $p .net]}
        return [dict create \
            exists 1 kind pg obj $p \
            actual_net [tt_iopad_elec_net_name_from_obj $net]]
    }

    # Ordinary signal pins (RTE is expected here on the RTE PAD).
    set matches {}
    foreach p [get_db $inst .pins] {
        set base ""
        catch {set base [get_db $p .base_name]}
        if {$base eq ""} {
            set full ""
            catch {set full [get_db $p .name]}
            set base [lindex [split $full "/"] end]
        }
        if {$base eq $leaf_name} {
            lappend matches $p
        }
    }

    if {[llength $matches] > 1} {
        error "TT_IOPAD_ELEC: instance '[tt_iopad_elec_obj_name $inst]' has multiple signal pins named '$leaf_name'."
    }
    if {[llength $matches] == 1} {
        set p [lindex $matches 0]
        set net {}
        catch {set net [get_db $p .net]}
        return [dict create \
            exists 1 kind signal obj $p \
            actual_net [tt_iopad_elec_net_name_from_obj $net]]
    }

    return [dict create exists 0]
}

proc tt_iopad_elec_get_supply_list {} {
    foreach v {RTE_PAD_SUPPLY_NETS POWER_PORT_NETS power_port} {
        if {[info exists ::$v]} {
            set value [set ::$v]
            if {[llength $value] > 0} {
                return $value
            }
        }
    }
    error "TT_IOPAD_ELEC: cannot derive core-supply list. Expected RTE_PAD_SUPPLY_NETS or POWER_PORT_NETS."
}

proc tt_iopad_elec_get_ground_net {} {
    foreach v {IOPAD_RING_COMMON_GROUND GROUND_NET ground} {
        if {[info exists ::$v]} {
            set value [set ::$v]
            if {[llength $value] > 0} {
                return [lindex $value 0]
            }
        }
    }
    return [::tech_mv_library_value IO_ELECTRICAL_PIN_03]
}

proc tt_iopad_elec_get_io_net {} {
    foreach v {IOPAD_RING_IO_SUPPLY_NET IO_POWER_NET IO_SUPPLY_NET} {
        if {[info exists ::$v]} {
            set value [set ::$v]
            if {$value ne ""} {
                return $value
            }
        }
    }
    return [::tech_mv_library_value IO_ELECTRICAL_PIN_02]
}

proc tt_iopad_elec_get_rte_net {} {
    if {[info exists ::RTE_PAD_NET] && $::RTE_PAD_NET ne ""} {
        return $::RTE_PAD_NET
    }
    return io_rte
}

proc tt_iopad_elec_rte_template {} {
    if {[info exists ::RTE_PAD_TEMPLATE_INSTANCE] && $::RTE_PAD_TEMPLATE_INSTANCE ne ""} {
        return $::RTE_PAD_TEMPLATE_INSTANCE
    }
    return pad_RTE
}

proc tt_iopad_elec_rte_prefix {} {
    if {[info exists ::RTE_PAD_INSTANCE_PREFIX] && $::RTE_PAD_INSTANCE_PREFIX ne ""} {
        return $::RTE_PAD_INSTANCE_PREFIX
    }
    return pad_RTE
}

proc tt_iopad_elec_is_rte_name {name} {
    set template [tt_iopad_elec_rte_template]
    set prefix [tt_iopad_elec_rte_prefix]

    if {$name eq $template} {
        return 1
    }
    return [string match "${prefix}_*" $name]
}

proc tt_iopad_elec_expected_rte_name {supply} {
    set supplies [tt_iopad_elec_get_supply_list]
    set base [lindex $supplies 0]

    if {$supply eq $base} {
        return [tt_iopad_elec_rte_template]
    }
    return "[tt_iopad_elec_rte_prefix]_${supply}"
}

proc tt_iopad_elec_side_index {side} {
    switch -- $side {
        top    { return 1 }
        right  { return 2 }
        bottom { return 3 }
        left   { return 4 }
        default { error "TT_IOPAD_ELEC: unknown IO side '$side'." }
    }
}

proc tt_iopad_elec_side_token {side} {
    string toupper $side
}

# -----------------------------------------------------------------------------
# IO_FILE parser
#
# Returns a dict with:
#   entries  -> list of dicts {name side ordinal}
#   by_side  -> dict side -> ordered instance names
# -----------------------------------------------------------------------------
proc tt_iopad_elec_parse_io_file {{path ""}} {
    tt_iopad_elec_require_runtime
    if {$path eq ""} {
        set path $::IO_FILE
    }

    set fp [open $path r]
    set data [read $fp]
    close $fp

    set side ""
    set ordinal 0
    set entries {}
    set by_side [dict create top {} right {} bottom {} left {}]

    foreach line [split $data "\n"] {
        set t [string trim $line]

        if {[regexp {^\((top|right|bottom|left)\s*$} $t -> s]} {
            set side $s
            set ordinal 0
            continue
        }

        # Corner blocks are deliberately not part of the side electrical model.
        if {[regexp {^\((topright|topleft|bottomright|bottomleft)\s*$} $t]} {
            set side ""
            continue
        }

        if {$side ne "" && [regexp {^\(inst\s+name="([^"]+)"} $t -> name]} {
            lappend entries [dict create \
                name $name side $side ordinal $ordinal]
            dict lappend by_side $side $name
            incr ordinal
        }
    }

    if {[llength $entries] == 0} {
        error "TT_IOPAD_ELEC: no side PAD instances parsed from IO_FILE '$path'."
    }

    return [dict create path $path entries $entries by_side $by_side]
}

# -----------------------------------------------------------------------------
# Build topology/electrical model from parsed IO_FILE.
#
# Each model PAD entry contains:
#   name, side, role, core_supply, required_pins, optional_pins
#
# topology_errors are intentionally separate from DB connectivity errors.
# -----------------------------------------------------------------------------
proc tt_iopad_elec_build_model {parsed} {
    set supplies [tt_iopad_elec_get_supply_list]
    set base_supply [lindex $supplies 0]
    set secondary_supplies [lrange $supplies 1 end]
    set io_net [tt_iopad_elec_get_io_net]
    set gnd [tt_iopad_elec_get_ground_net]
    set rte_net [tt_iopad_elec_get_rte_net]

    set model_entries {}
    set topo_errors {}

    # Counting structures.
    set rte_count [dict create]
    foreach s $supplies {
        dict set rte_count $s 0
    }

    set railcut_count [dict create]
    foreach side {top right bottom left} {
        foreach s $secondary_supplies {
            dict set railcut_count "$side|$s|1" 0
            dict set railcut_count "$side|$s|2" 0
        }
    }

    set core_pg_count [dict create]
    set io_pg_count [dict create top 0 right 0 bottom 0 left 0]
    foreach side {top right bottom left} {
        foreach s $supplies {
            dict set core_pg_count "$side|$s" 0
        }
    }

    foreach side {top right bottom left} {
        set current_supply $base_supply
        set side_token [tt_iopad_elec_side_token $side]
        set side_index [tt_iopad_elec_side_index $side]

        set names [dict get $parsed by_side $side]
        foreach name $names {
            # -------------------------------------------------------------
            # boundary cell boundary.
            # -------------------------------------------------------------
            if {[regexp {^RAILCUT_(.+)_(TOP|RIGHT|BOTTOM|LEFT)([12])$} \
                    $name -> supply token endpoint]} {

                if {$token ne $side_token} {
                    lappend topo_errors \
                        "RAILCUT_SIDE_MISMATCH pad=$name file_side=$side token=$token"
                }

                if {[lsearch -exact $secondary_supplies $supply] < 0} {
                    lappend topo_errors \
                        "UNKNOWN_RAILCUT_SUPPLY pad=$name supply=$supply"
                } else {
                    set key "$side|$supply|$endpoint"
                    if {[dict exists $railcut_count $key]} {
                        dict incr railcut_count $key
                    }
                }

                if {$endpoint eq "1"} {
                    if {$current_supply ne $base_supply} {
                        lappend topo_errors \
                            "RAILCUT_NESTED side=$side current=$current_supply new=$supply pad=$name"
                    }
                    set current_supply $supply
                } else {
                    if {$current_supply ne $supply} {
                        lappend topo_errors \
                            "RAILCUT_EXIT_MISMATCH side=$side current=$current_supply exit=$supply pad=$name"
                    }
                    set current_supply $base_supply
                }

                lappend model_entries [dict create \
                    name $name side $side role $::TECH_MV_IO_BOUNDARY_ROLE \
                    core_supply $current_supply \
                    required_pins {} optional_pins {}]
                continue
            }

            # -------------------------------------------------------------
            # Core power PAD.
            # -------------------------------------------------------------
            if {[regexp {^CORE_(.+)_PG([1-4])$} $name -> supply idx]} {
                if {$idx != $side_index} {
                    lappend topo_errors \
                        "CORE_PG_SIDE_MISMATCH pad=$name file_side=$side suffix=PG$idx"
                }

                if {[lsearch -exact $supplies $supply] < 0} {
                    lappend topo_errors \
                        "UNKNOWN_CORE_PG_SUPPLY pad=$name supply=$supply"
                } else {
                    dict incr core_pg_count "$side|$supply"
                }

                if {$current_supply ne $supply} {
                    lappend topo_errors \
                        "CORE_PG_DOMAIN_MISMATCH pad=$name file_side=$side expected_segment=$current_supply pad_supply=$supply"
                }

                lappend model_entries [dict create \
                    name $name side $side role CORE_POWER_PAD \
                    core_supply $supply \
                    required_pins [dict create [::tech_mv_library_value IO_ELECTRICAL_PIN_01] $supply [::tech_mv_library_value IO_ELECTRICAL_PIN_03] $gnd] \
                    optional_pins {}]
                continue
            }

            # -------------------------------------------------------------
            # IO power PAD.
            # -------------------------------------------------------------
            if {[regexp {^IO_PG([1-4])$} $name -> idx]} {
                if {$idx != $side_index} {
                    lappend topo_errors \
                        "IO_PG_SIDE_MISMATCH pad=$name file_side=$side suffix=PG$idx"
                }
                dict incr io_pg_count $side

                lappend model_entries [dict create \
                    name $name side $side role IO_POWER_PAD \
                    core_supply $current_supply \
                    required_pins [dict create [::tech_mv_library_value IO_ELECTRICAL_PIN_02] $io_net [::tech_mv_library_value IO_ELECTRICAL_PIN_04] $gnd] \
                    optional_pins {}]
                continue
            }

            # -------------------------------------------------------------
            # RTE PAD.
            # -------------------------------------------------------------
            if {[tt_iopad_elec_is_rte_name $name]} {
                if {![dict exists $rte_count $current_supply]} {
                    lappend topo_errors \
                        "RTE_UNKNOWN_DOMAIN pad=$name side=$side derived_supply=$current_supply"
                } else {
                    dict incr rte_count $current_supply
                }

                set expected_name [tt_iopad_elec_expected_rte_name $current_supply]
                if {$name ne $expected_name} {
                    lappend topo_errors \
                        "RTE_NAME_DOMAIN_MISMATCH pad=$name side=$side derived_supply=$current_supply expected_name=$expected_name"
                }

                lappend model_entries [dict create \
                    name $name side $side role RTE_PAD \
                    core_supply $current_supply \
                    required_pins [dict create \
                        [::tech_mv_library_value IO_ELECTRICAL_PIN_01] $current_supply \
                        [::tech_mv_library_value IO_ELECTRICAL_PIN_02] $io_net \
                        [::tech_mv_library_value IO_ELECTRICAL_PIN_03] $gnd \
                        [::tech_mv_library_value IO_ELECTRICAL_PIN_04] $gnd \
                        RTE $rte_net] \
                    optional_pins {}]
                continue
            }

            # -------------------------------------------------------------
            # Signal PAD.
            #
            # Do not require all four PG pins because different signal PAD
            # masters can expose different PG interfaces.  If a pin exists,
            # however, its connectivity is checked and repaired.
            # -------------------------------------------------------------
            lappend model_entries [dict create \
                name $name side $side role SIGNAL_PAD \
                core_supply $current_supply \
                required_pins {} \
                optional_pins [dict create \
                    [::tech_mv_library_value IO_ELECTRICAL_PIN_01] $current_supply \
                    [::tech_mv_library_value IO_ELECTRICAL_PIN_02] $io_net \
                    [::tech_mv_library_value IO_ELECTRICAL_PIN_03] $gnd \
                    [::tech_mv_library_value IO_ELECTRICAL_PIN_04] $gnd]]
        }

        if {$current_supply ne $base_supply} {
            lappend topo_errors \
                "RAILCUT_UNCLOSED side=$side active_supply=$current_supply"
        }
    }

    # -------------------------------------------------------------------------
    # Expected topology completeness.
    # -------------------------------------------------------------------------
    foreach side {top right bottom left} {
        if {[dict get $io_pg_count $side] != 1} {
            lappend topo_errors \
                "IO_POWER_PAD_COUNT side=$side expected=1 actual=[dict get $io_pg_count $side]"
        }

        foreach s $supplies {
            set c [dict get $core_pg_count "$side|$s"]
            if {$c != 1} {
                lappend topo_errors \
                    "CORE_POWER_PAD_COUNT side=$side supply=$s expected=1 actual=$c"
            }
        }

        foreach s $secondary_supplies {
            foreach endpoint {1 2} {
                set c [dict get $railcut_count "$side|$s|$endpoint"]
                if {$c != 1} {
                    lappend topo_errors \
                        "RAILCUT_COUNT side=$side supply=$s endpoint=$endpoint expected=1 actual=$c"
                }
            }
        }
    }

    foreach s $supplies {
        set c [dict get $rte_count $s]
        if {$c != 1} {
            lappend topo_errors \
                "RTE_PAD_COUNT supply=$s expected=1 actual=$c"
        }
    }

    return [dict create \
        base_supply $base_supply \
        supplies $supplies \
        io_net $io_net \
        ground_net $gnd \
        rte_net $rte_net \
        entries $model_entries \
        topology_errors $topo_errors]
}

# -----------------------------------------------------------------------------
# DB check.
#
# Returns a list of issue dicts:
#   type MISSING_INST|MISSING_PIN|UNCONNECTED|WRONG_NET
#   pad role pin expected actual kind
# -----------------------------------------------------------------------------
proc tt_iopad_elec_check_db {model} {
    set issues {}

    foreach e [dict get $model entries] {
        set role [dict get $e role]
        if {$role eq $::TECH_MV_IO_BOUNDARY_ROLE} {
            continue
        }

        set name [dict get $e name]
        set inst [tt_iopad_elec_find_inst $name]
        if {[llength $inst] == 0} {
            lappend issues [dict create \
                type MISSING_INST pad $name role $role \
                pin "" expected "" actual "<MISSING_INST>" kind ""]
            continue
        }

        # Required pins: absence itself is an error.
        dict for {pin expected} [dict get $e required_pins] {
            set pinfo [tt_iopad_elec_find_pin $inst $pin]

            if {![dict get $pinfo exists]} {
                lappend issues [dict create \
                    type MISSING_PIN pad $name role $role \
                    pin $pin expected $expected actual "<MISSING_PIN>" kind ""]
                continue
            }

            set actual [dict get $pinfo actual_net]
            set kind [dict get $pinfo kind]
            if {$actual eq ""} {
                lappend issues [dict create \
                    type UNCONNECTED pad $name role $role \
                    pin $pin expected $expected actual "<UNCONNECTED>" kind $kind]
            } elseif {$actual ne $expected} {
                lappend issues [dict create \
                    type WRONG_NET pad $name role $role \
                    pin $pin expected $expected actual $actual kind $kind]
            }
        }

        # Optional pins: absence is fine, wrong/unconnected existing pin is not.
        dict for {pin expected} [dict get $e optional_pins] {
            set pinfo [tt_iopad_elec_find_pin $inst $pin]
            if {![dict get $pinfo exists]} {
                continue
            }

            set actual [dict get $pinfo actual_net]
            set kind [dict get $pinfo kind]
            if {$actual eq ""} {
                lappend issues [dict create \
                    type UNCONNECTED pad $name role $role \
                    pin $pin expected $expected actual "<UNCONNECTED>" kind $kind]
            } elseif {$actual ne $expected} {
                lappend issues [dict create \
                    type WRONG_NET pad $name role $role \
                    pin $pin expected $expected actual $actual kind $kind]
            }
        }
    }

    return $issues
}

proc tt_iopad_elec_print_issues {label issues} {
    puts ""
    puts "======================================================================"
    puts " $label"
    puts "======================================================================"

    if {[llength $issues] == 0} {
        puts "PASS: No PAD electrical-connectivity issue."
        puts "======================================================================"
        return
    }

    puts "Issue count: [llength $issues]"
    foreach issue $issues {
        puts [format \
            "%-12s pad=%-36s role=%-16s pin=%-8s expected=%-12s actual=%s" \
            [dict get $issue type] \
            [dict get $issue pad] \
            [dict get $issue role] \
            [dict get $issue pin] \
            [dict get $issue expected] \
            [dict get $issue actual]]
    }
    puts "======================================================================"
}

proc tt_iopad_elec_print_topology_errors {label errors} {
    puts ""
    puts "======================================================================"
    puts " $label"
    puts "======================================================================"

    if {[llength $errors] == 0} {
        puts "PASS: IO_FILE topology is consistent."
    } else {
        puts "Topology issue count: [llength $errors]"
        foreach e $errors {
            puts "ERROR: $e"
        }
    }
    puts "======================================================================"
}

# -----------------------------------------------------------------------------
# Repair helpers
# -----------------------------------------------------------------------------
proc tt_iopad_elec_require_net {net_name} {
    set nets {}
    catch {set nets [get_db nets $net_name]}
    if {[llength $nets] == 0} {
        error "TT_IOPAD_ELEC: target net '$net_name' does not exist; refusing to create/guess a supply net."
    }
}

proc tt_iopad_elec_repair_pg_pin {pad pin expected} {
    tt_iopad_elec_require_net $expected

    if {[llength [info commands globalNetConnect]] == 0} {
        error "TT_IOPAD_ELEC: globalNetConnect is unavailable; cannot repair PG pin $pad/$pin."
    }

    puts "REPAIR PG: $pad/$pin -> $expected"
    globalNetConnect $expected \
        -type pgpin \
        -pin [list $pin] \
        -sinst [list $pad] \
        -override
}

proc tt_iopad_elec_repair_signal_pin {pad pin expected actual} {
    tt_iopad_elec_require_net $expected

    # attachTerm handles hierarchy and can connect an unconnected terminal.
    if {[llength [info commands attachTerm]] > 0} {
        puts "REPAIR SIG: $pad/$pin -> $expected  (attachTerm)"
        attachTerm $pad $pin $expected
        return
    }

    if {[llength [info commands connect_pin]] == 0} {
        error "TT_IOPAD_ELEC: neither attachTerm nor connect_pin is available for $pad/$pin."
    }

    if {$actual ne "" && $actual ne "<UNCONNECTED>" &&
        [llength [info commands disconnect_pin]] > 0} {
        disconnect_pin -inst $pad -pin $pin -net $actual
    }

    puts "REPAIR SIG: $pad/$pin -> $expected  (connect_pin)"
    connect_pin -inst $pad -pin $pin -net $expected
}

# Repair only recoverable connectivity issues. Missing instances/pins are left
# to the configured ring builder / final re-check.
proc tt_iopad_elec_repair_issues {issues} {
    set repaired 0
    set skipped {}

    foreach issue $issues {
        set type [dict get $issue type]
        set pad [dict get $issue pad]
        set pin [dict get $issue pin]
        set expected [dict get $issue expected]
        set actual [dict get $issue actual]
        set kind [dict get $issue kind]

        switch -- $type {
            UNCONNECTED -
            WRONG_NET {
                if {$kind eq "pg"} {
                    tt_iopad_elec_repair_pg_pin $pad $pin $expected
                } elseif {$kind eq "signal"} {
                    tt_iopad_elec_repair_signal_pin $pad $pin $expected $actual
                } else {
                    lappend skipped $issue
                    continue
                }
                incr repaired
            }
            default {
                lappend skipped $issue
            }
        }
    }

    return [dict create repaired $repaired skipped $skipped]
}

# -----------------------------------------------------------------------------
# Existing ring model integration.
# -----------------------------------------------------------------------------
proc tt_iopad_elec_require_ring_tool {} {
    if {[llength [info commands TT_IOPAD_RING]] > 0} {
        return
    }

    set f [file join $::TOOL_DIR 01_floorplan TT_flow_iopad_ring_model.tcl]
    if {![file isfile $f]} {
        error "TT_IOPAD_ELEC: existing ring tool not found: $f"
    }

    uplevel #0 [list source -quiet $f]

    if {[llength [info commands TT_IOPAD_RING]] == 0} {
        error "TT_IOPAD_ELEC: TT_IOPAD_RING did not become available after sourcing $f."
    }
}

proc tt_iopad_elec_regenerate {} {
    tt_iopad_elec_require_ring_tool

    puts ""
    puts "======================================================================"
    puts " REGENERATE IO_FILE FROM CONFIGURED RING MODEL"
    puts "======================================================================"
    puts "Seed/target IO_FILE: $::IO_FILE"

    # generate internally builds the configured model first. This is where
    # configured missing RTE/boundary cell/IO-ring instances can be normalized.
    TT_IOPAD_RING generate

    puts "Generated: $::IO_FILE"
    puts "NOTE: read_io_file was NOT executed."
    puts "======================================================================"
}

# -----------------------------------------------------------------------------
# Report writer. All values are Tcl strings/dicts; no design pointer is stored.
# -----------------------------------------------------------------------------
proc tt_iopad_elec_write_report {phase parsed model issues repair_result} {
    set path [tt_iopad_elec_report_path]
    set mode a
    if {$phase eq "INITIAL"} {
        set mode w
    }

    set fp [open $path $mode]
    puts $fp ""
    puts $fp "======================================================================"
    puts $fp "TT_IOPAD_ELEC $phase"
    puts $fp "======================================================================"
    puts $fp "IO_FILE      : [dict get $parsed path]"
    puts $fp "Base supply  : [dict get $model base_supply]"
    puts $fp "Supplies     : [dict get $model supplies]"
    puts $fp "IO supply    : [dict get $model io_net]"
    puts $fp "Ground       : [dict get $model ground_net]"
    puts $fp "RTE net      : [dict get $model rte_net]"
    puts $fp "PAD entries  : [llength [dict get $model entries]]"
    puts $fp ""

    puts $fp "TOPOLOGY_ERRORS=[llength [dict get $model topology_errors]]"
    foreach e [dict get $model topology_errors] {
        puts $fp "TOPOLOGY_ERROR $e"
    }

    puts $fp ""
    puts $fp "DB_ISSUES=[llength $issues]"
    foreach issue $issues {
        puts $fp "DB_ISSUE [dict get $issue type] \
pad=[dict get $issue pad] \
role=[dict get $issue role] \
pin=[dict get $issue pin] \
expected=[dict get $issue expected] \
actual=[dict get $issue actual] \
kind=[dict get $issue kind]"
    }

    if {$repair_result ne ""} {
        puts $fp ""
        puts $fp "REPAIRED=[dict get $repair_result repaired]"
        puts $fp "SKIPPED_REPAIR=[llength [dict get $repair_result skipped]]"
    }

    close $fp
    puts "INFO: TT_IOPAD_ELEC report: $path"
    return $path
}

# -----------------------------------------------------------------------------
# Public operations
# -----------------------------------------------------------------------------
proc tt_iopad_elec_model_current {} {
    set parsed [tt_iopad_elec_parse_io_file]
    set model [tt_iopad_elec_build_model $parsed]

    tt_iopad_elec_print_topology_errors \
        "IOPAD ELECTRICAL MODEL: IO_FILE TOPOLOGY" \
        [dict get $model topology_errors]

    puts ""
    puts "Model PAD entries: [llength [dict get $model entries]]"
    puts "Core supplies    : [dict get $model supplies]"
    puts "Base supply      : [dict get $model base_supply]"
    puts "IO supply        : [dict get $model io_net]"
    puts "Ground           : [dict get $model ground_net]"
    puts "RTE net          : [dict get $model rte_net]"

    return [dict create parsed $parsed model $model]
}

proc tt_iopad_elec_check_current {} {
    set mm [tt_iopad_elec_model_current]
    set parsed [dict get $mm parsed]
    set model [dict get $mm model]
    set issues [tt_iopad_elec_check_db $model]

    tt_iopad_elec_print_issues \
        "IOPAD ELECTRICAL MODEL: DB CONNECTIVITY CHECK" \
        $issues

    tt_iopad_elec_write_report INITIAL $parsed $model $issues ""

    return [dict create \
        parsed $parsed model $model issues $issues]
}

proc tt_iopad_elec_run {} {
    tt_iopad_elec_require_runtime

    puts ""
    puts "######################################################################"
    puts "#  TECH_MV STAGE00 IO-FILE -> MODEL -> REPAIR -> REGENERATE -> CHECK #"
    puts "######################################################################"

    # ---------------------------------------------------------------------
    # A. Initial seed model + DB check.
    # ---------------------------------------------------------------------
    set parsed0 [tt_iopad_elec_parse_io_file]
    set model0 [tt_iopad_elec_build_model $parsed0]
    set issues0 [tt_iopad_elec_check_db $model0]

    tt_iopad_elec_print_topology_errors \
        "INITIAL IO_FILE TOPOLOGY" \
        [dict get $model0 topology_errors]
    tt_iopad_elec_print_issues \
        "INITIAL DB ELECTRICAL CONNECTIVITY" \
        $issues0

    tt_iopad_elec_write_report INITIAL $parsed0 $model0 $issues0 ""

    # ---------------------------------------------------------------------
    # B. Repair recoverable connectivity.
    # ---------------------------------------------------------------------
    puts ""
    puts "======================================================================"
    puts " REPAIR RECOVERABLE PAD CONNECTIVITY"
    puts "======================================================================"

    set repair_result [tt_iopad_elec_repair_issues $issues0]
    puts "Repaired : [dict get $repair_result repaired]"
    puts "Skipped  : [llength [dict get $repair_result skipped]]"
    puts "======================================================================"

    # Write the initial/repair state before regeneration.
    tt_iopad_elec_write_report REPAIR $parsed0 $model0 $issues0 $repair_result

    # ---------------------------------------------------------------------
    # C. Normalize topology and regenerate IO_FILE using existing ring tool.
    # ---------------------------------------------------------------------
    tt_iopad_elec_regenerate

    # ---------------------------------------------------------------------
    # D. ONE final re-check. No loop.
    # ---------------------------------------------------------------------
    set parsed1 [tt_iopad_elec_parse_io_file]
    set model1 [tt_iopad_elec_build_model $parsed1]
    set issues1 [tt_iopad_elec_check_db $model1]
    set topo1 [dict get $model1 topology_errors]

    tt_iopad_elec_print_topology_errors \
        "FINAL REGENERATED IO_FILE TOPOLOGY (ONE RE-CHECK)" \
        $topo1
    tt_iopad_elec_print_issues \
        "FINAL DB ELECTRICAL CONNECTIVITY (ONE RE-CHECK)" \
        $issues1

    tt_iopad_elec_write_report FINAL $parsed1 $model1 $issues1 ""

    puts ""
    puts "######################################################################"
    if {[llength $topo1] == 0 && [llength $issues1] == 0} {
        puts "#                    STAGE00 IOPAD ELECTRICAL PASS                   #"
        puts "######################################################################"
        puts "IO_FILE regenerated successfully: $::IO_FILE"
        puts "No read_io_file was performed."
        return 0
    }

    puts "#                    STAGE00 IOPAD ELECTRICAL FAIL                   #"
    puts "######################################################################"
    puts "Final topology errors : [llength $topo1]"
    puts "Final DB issues       : [llength $issues1]"
    puts "Report                : [tt_iopad_elec_report_path]"
    error "TT_IOPAD_ELEC: final one-time re-check failed."
}

proc tt_iopad_elec_help {} {
    puts "======================================================================"
    puts " TT_IOPAD_ELEC <action>"
    puts "======================================================================"
    puts "  help  : show this help"
    puts "  model : parse current IO_FILE and build/report domain topology"
    puts "  check : model + read-only DB electrical connectivity check"
    puts "  run   : IO_FILE -> model -> check -> repair -> regenerate -> ONE check"
    puts ""
    puts "Recommended:"
    puts "  source -quiet run/tool/01_floorplan/TT_iopad_electrical_model_repair.tcl"
    puts "  TT_IOPAD_ELEC run"
    puts ""
    puts "The tool does NOT execute read_io_file."
    puts "======================================================================"
}

proc TT_IOPAD_ELEC {{action help}} {
    switch -- [string tolower $action] {
        help  { return [tt_iopad_elec_help] }
        model { return [tt_iopad_elec_model_current] }
        check { return [tt_iopad_elec_check_current] }
        run   { return [tt_iopad_elec_run] }
        default {
            error "TT_IOPAD_ELEC: unknown action '$action'. Use: TT_IOPAD_ELEC help"
        }
    }
}

puts "INFO: Loaded TT_iopad_electrical_model_repair.tcl"
puts "INFO: Use: TT_IOPAD_ELEC run"
