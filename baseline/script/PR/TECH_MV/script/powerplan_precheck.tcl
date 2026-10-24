# =============================================================================
# powerplan_precheck.tcl
# Early validation before Stage 02 power planning.
# =============================================================================

proc tech_mv_powerplan_precheck {} {
    set required_vars {
        TOP_MODULE DB_DIR SCRIPT_DIR TOOL_DIR GLOBAL_NET_FILE
        POWERPLAN_MODE CLEAR_STD_CELLS_BEFORE_POWERPLAN
        ENABLE_POWER_SWITCH_INSERTION POWER_SWITCH_INSERTION_MODE
        ENABLE_SECONDARY_PG_ROUTE POWER_PORT_NETS POWER_NETS GROUND_NET PD_CFG
    }

    set missing_vars {}
    foreach var_name $required_vars {
        if {![info exists ::$var_name]} {
            lappend missing_vars $var_name
        }
    }

    if {[llength $missing_vars] != 0} {
        error "PowerPlan setup variable(s) are missing: $missing_vars. Re-source init.setup."
    }

    set required_nets [concat $::POWER_PORT_NETS $::POWER_NETS [list $::GROUND_NET]]

    foreach pd_name [dict keys $::PD_CFG] {
        foreach key {power_net power_rail ground_net rail_2nd} {
            if {[dict exists $::PD_CFG $pd_name $key]} {
                set value [dict get $::PD_CFG $pd_name $key]
                if {$value ne ""} {
                    set required_nets [concat $required_nets $value]
                }
            }
        }
    }

    set missing_nets {}
    foreach net_name [lsort -unique $required_nets] {
        if {$net_name eq ""} {
            continue
        }
        if {[llength [get_db nets $net_name]] == 0} {
            lappend missing_nets $net_name
        }
    }

    if {[llength $missing_nets] != 0} {
        puts "ERROR: Stage 02 is using a design DB that does not contain the current PG nets."
        puts "ERROR: Missing PG net(s): $missing_nets"
        puts "ERROR: Current setup expects:"
        puts "ERROR:   POWER_PORT_NETS = $::POWER_PORT_NETS"
        puts "ERROR:   POWER_NETS      = $::POWER_NETS"
        puts "ERROR:   GROUND_NET     = $::GROUND_NET"
        error "PowerPlan precheck failed. Re-run 00_import_design.tcl with the current UPF/setup instead of using an old .enc database."
    }

    puts "INFO: PowerPlan precheck passed."
    puts "INFO: POWER_PORT_NETS = $::POWER_PORT_NETS"
    puts "INFO: POWER_NETS      = $::POWER_NETS"
    puts "INFO: GROUND_NET     = $::GROUND_NET"
}
