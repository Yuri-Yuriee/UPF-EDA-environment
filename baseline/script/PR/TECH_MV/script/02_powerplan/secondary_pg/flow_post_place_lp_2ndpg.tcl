# Runtime adapter preserves the historical logical source path.
if {[info exists ::TECH_MV_RUNTIME_ROOT]} {
    info script [file join $::TECH_MV_RUNTIME_ROOT run/tool/02_powerplan/secondary_pg/TT_flow_post_place_lp_2ndpg.tcl]
} else {
    info script [file normalize [file join [file dirname [info script]] .. .. .. run/tool/02_powerplan/secondary_pg/TT_flow_post_place_lp_2ndpg.tcl]]
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
# TT_flow_post_place_lp_2ndpg.tcl
# =============================================================================
# TECH / Innovus 21.19
#
# Secondary-PG routing for all non-switch LP cells.
#
# Routing mode:
#
#   set ::SECONDARY_PG_ROUTE_MODE SIGNAL
#       -> setPGPinUseSignalRoute + routePGPinUseSignalRoute
#
#   set ::SECONDARY_PG_ROUTE_MODE SROUTE
#       -> route_special -connect secondary_power_pin
#
# IMPORTANT DISCOVERY POLICY
# --------------------------
# Do NOT classify physical instances with inst .is_retention/.is_isolation/
# .is_always_on attributes.  In this design those attributes do not represent
# the physical LP-cell population and produce grossly incorrect counts.
#
# Instead:
#   LS  : logical LP classification is_level_shifter == true
#         then inspect actual connected configured SECONDARY_A/configured SECONDARY_B PG pin.
#
#   ISO : logical LP classification is_isolation_cell == true
#         then inspect actual configured SECONDARY_A PG pin.
#
#   RET / AON:
#         discover directly from physical configured RETENTION_AON PG pin.
#
# Power Switch:
#   not queried by this file and not modified.
#
# SIGNAL mode:
#   does NOT force LP cells fixed.
#
# SROUTE mode:
#   preserves the conservative fixed-after-routing policy.
#
# Discovery issues:
#   are reported and skipped by default instead of aborting the whole flow.
#   Set ::SECONDARY_PG_DISCOVERY_STRICT 1 if you want any skipped secondary
#   pin to become fatal.
# =============================================================================



# User-adjustable values are centralized in setup/config/.
foreach _cfg_var {SECONDARY_PG_ROUTE_MODE SECONDARY_PG_DISCOVERY_STRICT SECONDARY_PG_RAIL_LAYER SECONDARY_PG_BOTTOM_LAYER SECONDARY_PG_TOP_LAYER} {
    if {![info exists ::$_cfg_var]} {
        error "Missing config variable $_cfg_var. Source init.setup first."
    }
}
unset _cfg_var

# -----------------------------------------------------------------------------
# Generic helpers
# -----------------------------------------------------------------------------

proc tech_mv_add_unique {var_name value} {
    upvar 1 $var_name values

    if {[lsearch -exact $values $value] < 0} {
        lappend values $value
    }
}


proc tech_mv_layer_index {layer_spec} {
    if {[regexp {\(([0-9]+)\)$} $layer_spec -> idx]} {
        return $idx
    }

    if {[string is integer -strict $layer_spec]} {
        return $layer_spec
    }

    error "Cannot extract routing-layer index from '$layer_spec'"
}


proc tech_mv_find_pg_pin {inst leaf_name} {
    set matches {}

    foreach pg_pin [get_db $inst .pg_pins] {
        set full_name [get_db $pg_pin .name]
        set leaf [lindex [split $full_name "/"] end]

        if {$leaf eq $leaf_name} {
            lappend matches $pg_pin
        }
    }

    if {[llength $matches] == 0} {
        return {}
    }

    if {[llength $matches] != 1} {
        error "Instance '[get_db $inst .name]' has [llength $matches] PG pins '$leaf_name'; expected 1."
    }

    return [lindex $matches 0]
}


proc tech_mv_pg_pin_net {pg_pin} {
    if {[llength $pg_pin] == 0} {
        return {}
    }

    set net {}
    catch {set net [get_db $pg_pin .net]}

    if {[llength $net] == 0} {
        return {}
    }

    return [lindex $net 0]
}


proc tech_mv_pd_name {inst} {
    set pd {}

    catch {
        set pd [get_db $inst .power_domain]
    }

    if {[llength $pd] > 0} {
        set pd [lindex $pd 0]

        set n ""
        if {![catch {
            set n [get_db $pd .name]
        }] && $n ne ""} {
            return $n
        }

        set raw [string trim $pd]

        if {[string match "power_domain:*" $raw]} {
            return [string range \
                $raw \
                [string length "power_domain:"] \
                end]
        }

        if {$raw ne ""} {
            return $raw
        }
    }

    set n ""
    catch {
        set n [get_db $inst .power_domain_name]
    }

    return $n
}


# -----------------------------------------------------------------------------
# Logical classification helpers
#
# These are used ONLY for LS/ISO because the design database has proven-good
# low-power logical classifications for those classes.
# -----------------------------------------------------------------------------

proc tech_mv_get_logical_lp_names {class} {
    switch -- $class {
        LS {
            set filter_expr {is_level_shifter == true}
        }

        ISO {
            set filter_expr {is_isolation_cell == true}
        }

        default {
            error "tech_mv_get_logical_lp_names supports LS or ISO only"
        }
    }

    set cells {}

    if {[catch {
        set cells [get_cells -hierarchical -filter $filter_expr]
    } err]} {
        error "Cannot query $class cells with '$filter_expr': $err"
    }

    if {[llength $cells] == 0} {
        return {}
    }

    return [get_object_name $cells]
}


proc tech_mv_name_dict {names} {
    set d [dict create]

    foreach n $names {
        dict set d $n 1
    }

    return $d
}


# -----------------------------------------------------------------------------
# Secondary-PG record
#
# Record format:
#   {class inst_name cell_name pd_name pin_role net_name}
# -----------------------------------------------------------------------------

proc tech_mv_add_record {
    inst
    class
    pin_role
    records_var
    seen_var
    issue_count_var
    fp
} {
    upvar 1 $records_var records
    upvar 1 $seen_var seen
    upvar 1 $issue_count_var issue_count

    set inst_name [get_db $inst .name]
    set pg_pin [tech_mv_find_pg_pin $inst $pin_role]

    if {[llength $pg_pin] == 0} {
        incr issue_count

        puts $fp \
            "DISCOVERY_WARN class=$class inst=$inst_name pin=$pin_role reason=MISSING_PIN"

        return 0
    }

    set net_obj [tech_mv_pg_pin_net $pg_pin]

    if {[llength $net_obj] == 0} {
        incr issue_count

        puts $fp \
            "DISCOVERY_WARN class=$class inst=$inst_name pin=$pin_role reason=UNCONNECTED_PIN"

        return 0
    }

    set net_name [get_db $net_obj .name]
    set cell_name [get_db $inst .base_cell.name]
    set pd_name [tech_mv_pd_name $inst]

    if {$net_name eq "" ||
        $cell_name eq "" ||
        $pd_name eq ""} {

        incr issue_count

        puts $fp \
            "DISCOVERY_WARN class=$class inst=$inst_name pin=$pin_role cell=$cell_name pd=$pd_name net=$net_name reason=INCOMPLETE_RECORD"

        return 0
    }

    set key "${inst_name}|${pin_role}|${net_name}"

    if {[dict exists $seen $key]} {
        return 1
    }

    dict set seen $key 1

    lappend records [list \
        $class \
        $inst_name \
        $cell_name \
        $pd_name \
        $pin_role \
        $net_name]

    puts $fp \
        "SEC_PIN class=$class inst=$inst_name cell=$cell_name pd=$pd_name pin=$pin_role net=$net_name"

    return 1
}


# -----------------------------------------------------------------------------
# Discover all non-switch secondary PG pins.
# -----------------------------------------------------------------------------

proc tech_mv_discover_secondary_pg {fp} {
    set ls_names [tech_mv_get_logical_lp_names LS]
    set iso_names [tech_mv_get_logical_lp_names ISO]

    set ls_dict [tech_mv_name_dict $ls_names]
    set iso_dict [tech_mv_name_dict $iso_names]

    set records {}
    set seen [dict create]

    set issue_count 0
    set unplaced_count 0

    set ls_vdds_count 0
    set ls_vddl_count 0
    set ls_single_supply_count 0
    set ls_ambiguous_count 0

    set iso_vdds_count 0
    set iso_single_supply_count 0

    set tvdd_count 0

    set candidate_insts [dict create]

    foreach inst [get_db insts] {
        set inst_name [get_db $inst .name]
        set status [get_db $inst .place_status]

        # ---------------------------------------------------------------------
        # Level shifter
        # ---------------------------------------------------------------------
        if {[dict exists $ls_dict $inst_name]} {
            dict set candidate_insts $inst_name $inst

            if {$status eq "unplaced"} {
                incr unplaced_count
                incr issue_count
                puts $fp \
                    "DISCOVERY_WARN class=LS inst=$inst_name reason=UNPLACED"
            } else {
                set vdds [tech_mv_find_pg_pin $inst [::tech_mv_library_value LP_PIN_SECONDARY_A]]
                set vddl [tech_mv_find_pg_pin $inst [::tech_mv_library_value LP_PIN_SECONDARY_B]]

                set present 0
                set connected {}

                foreach role_pin [list \
                    [list [::tech_mv_library_value LP_PIN_SECONDARY_A] $vdds] \
                    [list [::tech_mv_library_value LP_PIN_SECONDARY_B] $vddl]] {

                    lassign $role_pin role pin

                    if {[llength $pin] == 0} {
                        continue
                    }

                    incr present

                    set net [tech_mv_pg_pin_net $pin]

                    if {[llength $net] > 0} {
                        lappend connected $role
                    }
                }

                if {$present == 0} {
                    incr ls_single_supply_count

                    puts $fp \
                        "SINGLE_SUPPLY class=LS inst=$inst_name"
                } elseif {[llength $connected] == 0} {
                    incr issue_count

                    puts $fp \
                        "DISCOVERY_WARN class=LS inst=$inst_name reason=NO_CONNECTED_[::tech_mv_library_value LP_PIN_SECONDARY_A]_[::tech_mv_library_value LP_PIN_SECONDARY_B]"
                } elseif {[llength $connected] > 1} {
                    incr issue_count
                    incr ls_ambiguous_count

                    puts $fp \
                        "DISCOVERY_WARN class=LS inst=$inst_name connected={$connected} reason=AMBIGUOUS_[::tech_mv_library_value LP_PIN_SECONDARY_A]_[::tech_mv_library_value LP_PIN_SECONDARY_B]"
                } else {
                    set role [lindex $connected 0]

                    if {$role eq "[::tech_mv_library_value LP_PIN_SECONDARY_A]"} {
                        incr ls_vdds_count
                    } else {
                        incr ls_vddl_count
                    }

                    tech_mv_add_record \
                        $inst \
                        LS \
                        $role \
                        records \
                        seen \
                        issue_count \
                        $fp
                }
            }
        }

        # ---------------------------------------------------------------------
        # Isolation
        # ---------------------------------------------------------------------
        if {[dict exists $iso_dict $inst_name]} {
            dict set candidate_insts $inst_name $inst

            if {$status eq "unplaced"} {
                incr unplaced_count
                incr issue_count

                puts $fp \
                    "DISCOVERY_WARN class=ISO inst=$inst_name reason=UNPLACED"
            } else {
                set vdds [tech_mv_find_pg_pin $inst [::tech_mv_library_value LP_PIN_SECONDARY_A]]

                if {[llength $vdds] == 0} {
                    incr iso_single_supply_count

                    puts $fp \
                        "SINGLE_SUPPLY class=ISO inst=$inst_name"
                } else {
                    if {[llength [tech_mv_pg_pin_net $vdds]] == 0} {
                        incr issue_count

                        puts $fp \
                            "DISCOVERY_WARN class=ISO inst=$inst_name pin=[::tech_mv_library_value LP_PIN_SECONDARY_A] reason=UNCONNECTED_PIN"
                    } else {
                        incr iso_vdds_count

                        tech_mv_add_record \
                            $inst \
                            ISO \
                            [::tech_mv_library_value LP_PIN_SECONDARY_A] \
                            records \
                            seen \
                            issue_count \
                            $fp
                    }
                }
            }
        }

        # ---------------------------------------------------------------------
        # Retention / Always-On physical secondary pin
        #
        # Any physical configured RETENTION_AON PG pin is a secondary/always-on supply pin in this
        # TECH library setup.  This avoids unreliable RET/AON inst attributes.
        # Power switches in this design do not use configured RETENTION_AON.
        # ---------------------------------------------------------------------
        set tvdd [tech_mv_find_pg_pin $inst [::tech_mv_library_value LP_PIN_RETENTION_AON]]

        if {[llength $tvdd] > 0} {
            dict set candidate_insts $inst_name $inst

            if {$status eq "unplaced"} {
                incr unplaced_count
                incr issue_count

                puts $fp \
                    "DISCOVERY_WARN class=[::tech_mv_library_value LP_PIN_RETENTION_AON] inst=$inst_name reason=UNPLACED"
            } elseif {[llength [tech_mv_pg_pin_net $tvdd]] == 0} {
                incr issue_count

                puts $fp \
                    "DISCOVERY_WARN class=[::tech_mv_library_value LP_PIN_RETENTION_AON] inst=$inst_name pin=[::tech_mv_library_value LP_PIN_RETENTION_AON] reason=UNCONNECTED_PIN"
            } else {
                incr tvdd_count

                tech_mv_add_record \
                    $inst \
                    [::tech_mv_library_value LP_PIN_RETENTION_AON] \
                    [::tech_mv_library_value LP_PIN_RETENTION_AON] \
                    records \
                    seen \
                    issue_count \
                    $fp
            }
        }
    }

    puts ""
    puts "INFO: Secondary-PG discovery:"
    puts "INFO:   Logical LS                = [llength $ls_names]"
    puts "INFO:     [::tech_mv_library_value LP_PIN_SECONDARY_A] secondary          = $ls_vdds_count"
    puts "INFO:     [::tech_mv_library_value LP_PIN_SECONDARY_B] secondary          = $ls_vddl_count"
    puts "INFO:     single-supply           = $ls_single_supply_count"
    puts "INFO:     ambiguous               = $ls_ambiguous_count"
    puts "INFO:   Logical ISO               = [llength $iso_names]"
    puts "INFO:     [::tech_mv_library_value LP_PIN_SECONDARY_A] secondary          = $iso_vdds_count"
    puts "INFO:     single-supply           = $iso_single_supply_count"
    puts "INFO:   Physical [::tech_mv_library_value LP_PIN_RETENTION_AON] pins        = $tvdd_count"
    puts "INFO:   Valid secondary records   = [llength $records]"
    puts "INFO:   Discovery warnings        = $issue_count"
    puts "INFO:   Unplaced candidates       = $unplaced_count"

    puts $fp ""
    puts $fp "DISCOVERY_SUMMARY"
    puts $fp "Logical LS              : [llength $ls_names]"
    puts $fp "LS [::tech_mv_library_value LP_PIN_SECONDARY_A]                 : $ls_vdds_count"
    puts $fp "LS [::tech_mv_library_value LP_PIN_SECONDARY_B]                 : $ls_vddl_count"
    puts $fp "LS single-supply        : $ls_single_supply_count"
    puts $fp "LS ambiguous            : $ls_ambiguous_count"
    puts $fp "Logical ISO             : [llength $iso_names]"
    puts $fp "ISO [::tech_mv_library_value LP_PIN_SECONDARY_A]                : $iso_vdds_count"
    puts $fp "ISO single-supply       : $iso_single_supply_count"
    puts $fp "Physical [::tech_mv_library_value LP_PIN_RETENTION_AON] pins      : $tvdd_count"
    puts $fp "Valid records           : [llength $records]"
    puts $fp "Discovery warnings      : $issue_count"
    puts $fp "Unplaced candidates     : $unplaced_count"

    return [dict create \
        records $records \
        candidate_insts $candidate_insts \
        issue_count $issue_count \
        unplaced_count $unplaced_count \
        ls_count [llength $ls_names] \
        iso_count [llength $iso_names] \
        tvdd_count $tvdd_count]
}


# -----------------------------------------------------------------------------
# SIGNAL routing
# -----------------------------------------------------------------------------

proc tech_mv_route_secondary_pg_signal {records fp} {
    set pairs {}
    set nets {}

    foreach rec $records {
        lassign $rec class inst_name cell_name pd_name pin_role net_name

        tech_mv_add_unique \
            pairs \
            "${cell_name}:${pin_role}"

        tech_mv_add_unique \
            nets \
            $net_name
    }

    if {[llength $pairs] == 0 ||
        [llength $nets] == 0} {

        error "SIGNAL mode: no valid secondary PG records found."
    }

    set bottom_idx \
        [tech_mv_layer_index $::SECONDARY_PG_BOTTOM_LAYER]

    set top_idx \
        [tech_mv_layer_index $::SECONDARY_PG_TOP_LAYER]

    set route_layer_range \
        "${bottom_idx}:${top_idx}"

    puts ""
    puts "INFO: 2nd-PG ROUTE MODE = SIGNAL"
    puts "INFO: layer range = $route_layer_range"
    puts "INFO: cell:pin pairs = [llength $pairs]"
    puts "INFO: nets           = $nets"

    puts $fp ""
    puts $fp "ROUTE_MODE SIGNAL"
    puts $fp "SIGNAL_LAYER_RANGE {$route_layer_range}"
    puts $fp "SIGNAL_PAIRS {$pairs}"
    puts $fp "SIGNAL_NETS {$nets}"

    foreach pair $pairs {
        if {[catch {
            eval_legacy \
                "setPGPinUseSignalRoute $pair"
        } err]} {
            error \
                "setPGPinUseSignalRoute failed for '$pair': $err"
        }
    }

    if {[catch {
        eval_legacy \
            "setNanoRouteMode -routeStripeLayerRange $route_layer_range"
    } err]} {
        error \
            "Cannot set routeStripeLayerRange '$route_layer_range': $err"
    }

    set routed 0

    foreach net_name $nets {
        puts "INFO: routePGPinUseSignalRoute net='$net_name'"
        puts $fp \
            "ROUTE_BEGIN mode=SIGNAL net=$net_name"

        if {[catch {
            eval_legacy \
                "routePGPinUseSignalRoute -nets {$net_name}"
        } err]} {
            catch {
                eval_legacy \
                    {setNanoRouteMode -routeStripeLayerRange ""}
            }

            puts $fp \
                "ROUTE_FAIL mode=SIGNAL net=$net_name error={$err}"

            error \
                "SIGNAL secondary-PG routing failed for '$net_name': $err"
        }

        incr routed

        puts $fp \
            "ROUTED mode=SIGNAL net=$net_name"
    }

    catch {
        eval_legacy \
            {setNanoRouteMode -routeStripeLayerRange ""}
    }

    return $routed
}


# -----------------------------------------------------------------------------
# SROUTE routing
# -----------------------------------------------------------------------------

proc tech_mv_route_secondary_pg_sroute {records fp} {
    set groups [dict create]

    foreach rec $records {
        lassign $rec class inst_name cell_name pd_name pin_role net_name

        dict set \
            groups \
            "${pd_name}|${net_name}" \
            [list $pd_name $net_name]
    }

    if {[dict size $groups] == 0} {
        error "SROUTE mode: no valid secondary PG PD+net groups found."
    }

    set layer_range [list \
        $::SECONDARY_PG_BOTTOM_LAYER \
        $::SECONDARY_PG_TOP_LAYER]

    set vgrid [list \
        $::SECONDARY_PG_TOP_LAYER \
        0 \
        0]

    puts ""
    puts "INFO: 2nd-PG ROUTE MODE = SROUTE"
    puts "INFO: rail layer  = $::SECONDARY_PG_RAIL_LAYER"
    puts "INFO: layer range = $layer_range"

    puts $fp ""
    puts $fp "ROUTE_MODE SROUTE"
    puts $fp "SROUTE_RAIL_LAYER $::SECONDARY_PG_RAIL_LAYER"
    puts $fp "SROUTE_LAYER_RANGE {$layer_range}"

    catch {
        eval_legacy \
            "setSrouteMode -reset"
    }

    set_db \
        route_special_via_connect_to_shape \
        {stripe}

    set routed 0

    foreach key [lsort [dict keys $groups]] {
        lassign \
            [dict get $groups $key] \
            pd_name \
            net_name

        puts \
            "INFO: route_special PD='$pd_name' NET='$net_name'"

        puts $fp \
            "ROUTE_BEGIN mode=SROUTE pd=$pd_name net=$net_name"

        if {[catch {
            route_special \
                -connect secondary_power_pin \
                -layer_change_range $layer_range \
                -secondary_pin_rail_vertical_stripe_grid $vgrid \
                -allow_jogging 1 \
                -power_domains $pd_name \
                -crossover_via_layer_range $layer_range \
                -secondary_pin_rail_layer \
                    $::SECONDARY_PG_RAIL_LAYER \
                -nets $net_name \
                -allow_layer_change 1 \
                -secondary_pin_net $net_name \
                -target_via_layer_range $layer_range
        } err]} {
            puts $fp \
                "ROUTE_FAIL mode=SROUTE pd=$pd_name net=$net_name error={$err}"

            error \
                "SROUTE secondary-PG routing failed for PD=$pd_name NET=$net_name: $err"
        }

        incr routed

        puts $fp \
            "ROUTED mode=SROUTE pd=$pd_name net=$net_name"
    }

    return $routed
}


# -----------------------------------------------------------------------------
# Manual/debug helper
#
# Release every non-switch LP instance from fixed/soft_fixed to placed.
#
# Discovery:
#   logical LS + logical ISO + any physical configured RETENTION_AON-pin instance.
#
# Power Switch is intentionally not selected.
# -----------------------------------------------------------------------------

proc TT_release_non_switch_lp_cells {} {
    set ls_names \
        [tech_mv_get_logical_lp_names LS]

    set iso_names \
        [tech_mv_get_logical_lp_names ISO]

    set target [dict create]

    foreach n $ls_names {
        dict set target $n 1
    }

    foreach n $iso_names {
        dict set target $n 1
    }

    foreach inst [get_db insts] {
        if {[llength \
            [tech_mv_find_pg_pin $inst [::tech_mv_library_value LP_PIN_RETENTION_AON]]] > 0} {

            dict set \
                target \
                [get_db $inst .name] \
                1
        }
    }

    set released 0
    set already_placed 0
    set other_status 0

    foreach name [lsort [dict keys $target]] {
        set objs [get_db insts $name]

        if {[llength $objs] != 1} {
            puts \
                "WARNING: cannot resolve LP instance '$name'"
            continue
        }

        set inst [lindex $objs 0]
        set status [get_db $inst .place_status]

        if {$status in {fixed soft_fixed}} {
            set_db \
                $inst \
                .place_status \
                placed

            incr released

            puts \
                "RELEASE: $name $status -> placed"
        } elseif {$status eq "placed"} {
            incr already_placed
        } else {
            incr other_status

            puts \
                "INFO: $name status=$status (unchanged)"
        }
    }

    puts ""
    puts "======================================================================"
    puts " NON-SW LP RELEASE SUMMARY"
    puts "======================================================================"
    puts "Released -> placed : $released"
    puts "Already placed     : $already_placed"
    puts "Other status       : $other_status"
    puts "Power Switch       : untouched"
    puts "======================================================================"

    return $released
}


# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------

proc TT_post_place_lp_2ndpg {} {
    set mode \
        [string toupper $::SECONDARY_PG_ROUTE_MODE]

    if {$mode ni {SIGNAL SROUTE}} {
        error \
            "SECONDARY_PG_ROUTE_MODE must be SIGNAL or SROUTE, got '$::SECONDARY_PG_ROUTE_MODE'"
    }

    puts ""
    puts "======================================================================"
    puts " LP 2nd-PG"
    puts " ROUTE MODE : $mode"
    puts "======================================================================"
    puts "INFO: Power Switch PG flow is unchanged."

    if {[info exists ::TECH_MV_REPORT_STAGE] && $::TECH_MV_REPORT_STAGE eq "03"} {
        set _secondary_report_stage 03
        set _secondary_report_step 80
    } else {
        set _secondary_report_stage 05
        set _secondary_report_step 10
    }
    set rpt [tech_mv_report_path $_secondary_report_step secondary_pg rpt $_secondary_report_stage]

    set fp [open $rpt w]

    puts $fp \
        "ROUTE_MODE : $mode"

    puts $fp \
        "Power Switch: unchanged"

    puts $fp \
        "Rail layer  : $::SECONDARY_PG_RAIL_LAYER"

    puts $fp \
        "Bottom layer: $::SECONDARY_PG_BOTTOM_LAYER"

    puts $fp \
        "Top layer   : $::SECONDARY_PG_TOP_LAYER"

    puts $fp \
        "Discovery strict: $::SECONDARY_PG_DISCOVERY_STRICT"

    puts $fp ""

    set discovery \
        [tech_mv_discover_secondary_pg $fp]

    set records \
        [dict get $discovery records]

    set candidate_insts \
        [dict get $discovery candidate_insts]

    set issue_count \
        [dict get $discovery issue_count]

    if {[llength $records] == 0} {
        close $fp

        error \
            "2nd-PG discovery found no valid secondary PG records. See $rpt"
    }

    if {$issue_count > 0} {
        puts ""
        puts "WARNING: 2nd-PG discovery has $issue_count warning(s)."
        puts "WARNING: Details: $rpt"

        if {$::SECONDARY_PG_DISCOVERY_STRICT} {
            close $fp

            error \
                "2nd-PG discovery strict mode: $issue_count issue(s). See $rpt"
        }

        puts \
            "INFO: Strict mode is OFF; valid secondary PG records will continue."
    }

    switch -- $mode {
        SIGNAL {
            set routed_count \
                [tech_mv_route_secondary_pg_signal \
                    $records \
                    $fp]
        }

        SROUTE {
            set routed_count \
                [tech_mv_route_secondary_pg_sroute \
                    $records \
                    $fp]
        }
    }

    # -------------------------------------------------------------------------
    # Placement-status policy
    # -------------------------------------------------------------------------

    set newly_fixed 0
    set already_fixed 0
    set fix_fail 0

    if {$mode eq "SROUTE"} {
        foreach name [dict keys $candidate_insts] {
            set inst \
                [dict get $candidate_insts $name]

            set status \
                [get_db $inst .place_status]

            if {$status eq "fixed"} {
                incr already_fixed
                continue
            }

            if {[catch {
                set_db \
                    $inst \
                    .place_status \
                    fixed
            } err]} {
                incr fix_fail

                puts $fp \
                    "FIX_FAIL inst=$name error={$err}"
            } else {
                incr newly_fixed
            }
        }
    } else {
        puts \
            "INFO: SIGNAL mode does not force LP cells FIXED."

        puts $fp \
            "PLACEMENT_STATUS_POLICY SIGNAL_KEEP_CURRENT"
    }

    puts $fp ""
    puts $fp "SUMMARY"
    puts $fp "Route mode          : $mode"
    puts $fp "Valid records       : [llength $records]"
    puts $fp "Discovery warnings  : $issue_count"
    puts $fp "Routed groups/nets  : $routed_count"
    puts $fp "Newly fixed         : $newly_fixed"
    puts $fp "Already fixed       : $already_fixed"
    puts $fp "Fix failures        : $fix_fail"

    close $fp

    puts ""
    puts "======================================================================"
    puts " LP 2nd-PG SUMMARY"
    puts "======================================================================"
    puts "Route mode          : $mode"
    puts "Valid records       : [llength $records]"
    puts "Discovery warnings  : $issue_count"
    puts "Routed groups/nets  : $routed_count"
    puts "Newly fixed         : $newly_fixed"
    puts "Already fixed       : $already_fixed"
    puts "Fix failures        : $fix_fail"
    puts "Report              : $rpt"
    puts "======================================================================"

    if {$fix_fail > 0} {
        error \
            "Failed to fix $fix_fail LP cell(s). See $rpt"
    }

    return $routed_count
}


TT_post_place_lp_2ndpg
