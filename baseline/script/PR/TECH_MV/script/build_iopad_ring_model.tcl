# =============================================================================
# Build the optional segmented IO-pad ring model.
# =============================================================================
puts "User script [info script]"

if {!$ENABLE_IOPAD_RING_MODEL} {
    set ::IOPAD_RING_MODEL_ACTIVE false
    puts "INFO: IO-pad ring model is inactive because IOPAD_RING_DOMAIN_CONFIG is empty."
} else {
    source -quiet [file join $::TECH_MV_RUNTIME_ROOT .. script PR TECH_MV script 01_floorplan proc_iopad_ring_model.tcl]

    set IO_PAD_RING [tt_iopad_ring_create $IOPAD_RING_NAME $IOPAD_RING_COMMON_GROUND]
    set seen_inst [dict create]

    foreach domain_cfg $IOPAD_RING_DOMAIN_CONFIG {
        foreach key {name side io_power_net rte_net pads} {
            if {![dict exists $domain_cfg $key]} {
                error "IOPAD ring domain entry is missing '$key': $domain_cfg"
            }
        }

        set domain_name [dict get $domain_cfg name]
        set side [string tolower [dict get $domain_cfg side]]
        if {$side ni {top right bottom left}} {
            error "IOPAD domain '$domain_name' has unsupported side '$side'"
        }

        set io_power_net [dict get $domain_cfg io_power_net]
        set rte_net [dict get $domain_cfg rte_net]
        tt_iopad_ring_add_domain IO_PAD_RING $domain_name $io_power_net $rte_net [dict create side $side]

        foreach pad_cfg [dict get $domain_cfg pads] {
            foreach key {role instance net order} {
                if {![dict exists $pad_cfg $key]} {
                    error "IOPAD domain '$domain_name' pad entry is missing '$key': $pad_cfg"
                }
            }
            set role [string toupper [dict get $pad_cfg role]]
            set inst_name [dict get $pad_cfg instance]
            set net_name [dict get $pad_cfg net]
            set order_index [dict get $pad_cfg order]

            if {[dict exists $seen_inst $inst_name]} {
                error "IOPAD instance '$inst_name' is assigned to more than one ring domain"
            }
            dict set seen_inst $inst_name $domain_name

            # Optional auto-create for local IO-power / RTE pads only.
            set inst_obj ""
            catch { set inst_obj [lindex [get_db insts $inst_name] 0] }
            if {$inst_obj eq "" && $IOPAD_RING_CREATE_MISSING_PADS && $role in {IO_POWER RTE}} {
                if {![dict exists $pad_cfg base_cell]} {
                    error "Missing IOPAD instance '$inst_name' requires pad_cfg.base_cell for auto-create"
                }
                set base_cell [dict get $pad_cfg base_cell]
                puts "INFO: Creating IOPAD ring pad: domain=$domain_name role=$role inst=$inst_name base=$base_cell"
                create_inst -name $inst_name -base_cell $base_cell
                if {[dict exists $pad_cfg pin]} {
                    connect_pin -inst $inst_name -pin [dict get $pad_cfg pin] -net $net_name
                }
                set inst_obj [lindex [get_db insts $inst_name] 0]
            }
            if {$inst_obj eq ""} {
                error "IOPAD ring instance '$inst_name' does not exist"
            }

            tt_iopad_ring_add_pad IO_PAD_RING $domain_name $role $inst_name $net_name $side $order_index
        }
    }

    tt_iopad_ring_close IO_PAD_RING

    # Add one physical configured IO family after every domain.  At a side transition the cut
    # is emitted at the end of the previous side, immediately before the corner.
    if {$IOPAD_RING_CREATE_CUTS} {
        set order [dict get $IO_PAD_RING order]
        foreach domain_name $order {
            set d [dict get $IO_PAD_RING domains $domain_name]
            set side [dict get $d segment side]
            set next [dict get $d next_domain]
            set safe "${domain_name}__${next}"
            regsub -all {[^A-Za-z0-9_]} $safe {_} safe
            set cut_name "${IOPAD_RING_CUT_PREFIX}_${safe}"
            if {$side in {top bottom}} {
                set cut_base $IOPAD_RING_CUT_BASE_VERTICAL
            } else {
                set cut_base $IOPAD_RING_CUT_BASE_HORIZONTAL
            }
            set cut_obj ""
            catch { set cut_obj [lindex [get_db insts $cut_name] 0] }
            if {$cut_obj eq ""} {
                create_inst -name $cut_name -base_cell $cut_base
            }
            dict set IO_PAD_RING cuts $cut_name [dict create \
                name $cut_name \
                left_domain $domain_name \
                right_domain $next \
                side $side \
                cut_io_power true \
                cut_rte true \
                cut_ground false \
                common_ground_net $IOPAD_RING_COMMON_GROUND]
        }
    }

    if {![tt_iopad_ring_validate $IO_PAD_RING]} {
        error "IO-pad ring model validation failed"
    }

    set ::IOPAD_RING_MODEL $IO_PAD_RING
    set ::IOPAD_RING_MODEL_ACTIVE true
    tt_iopad_ring_report $IO_PAD_RING
}
