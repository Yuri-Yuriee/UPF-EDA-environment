# Runtime adapter preserves the historical logical source path.
if {[info exists ::TECH_MV_RUNTIME_ROOT]} {
    info script [file join $::TECH_MV_RUNTIME_ROOT run/tool/01_floorplan/TT_proc_iopad_ring_model.tcl]
} else {
    info script [file normalize [file join [file dirname [info script]] .. .. run/tool/01_floorplan/TT_proc_iopad_ring_model.tcl]]
}
# =============================================================================
# TT_proc_iopad_ring_model.tcl
# =============================================================================
# Purpose:
#   Ring-topology data model for segmented IO-pad power domains.
#
# Model rules:
#   1. Domains are ordered clockwise around the die perimeter.
#   2. A PR_CUT exists between every adjacent pair of domains.
#   3. PR_CUT cuts IO power and RTE connectivity.
#   4. PR_CUT does NOT cut ground; all domains share one common ground net.
#   5. Every domain must own at least one IO-power pad and one RTE pad.
#   6. The last domain connects back to the first domain.
#
# This file defines data-model procedures only. It does not modify Innovus DB.
# =============================================================================

proc tt_iopad_ring_create {ring_name common_ground_net} {
    if {$ring_name eq ""} {
        error "Ring name must not be empty."
    }
    if {$common_ground_net eq ""} {
        error "Common ground net must not be empty."
    }

    return [dict create \
        name $ring_name \
        topology ring \
        direction $::IOPAD_RING_DIRECTION \
        common_ground_net $common_ground_net \
        order {} \
        domains [dict create] \
        cuts [dict create] \
        closed false]
}

proc tt_iopad_ring_add_domain {ring_var domain_name io_power_net rte_net {segment {}}} {
    upvar 1 $ring_var ring

    if {![dict exists $ring name]} {
        error "Invalid IO-pad ring object."
    }
    if {$domain_name eq ""} {
        error "Domain name must not be empty."
    }
    if {[dict exists $ring domains $domain_name]} {
        error "IO-pad domain '$domain_name' already exists."
    }
    if {$io_power_net eq ""} {
        error "IO power net must not be empty for domain '$domain_name'."
    }
    if {$rte_net eq ""} {
        error "RTE net must not be empty for domain '$domain_name'."
    }

    set domain [dict create \
        name $domain_name \
        io_power_net $io_power_net \
        rte_net $rte_net \
        ground_net [dict get $ring common_ground_net] \
        segment $segment \
        prev_domain "" \
        next_domain "" \
        io_power_pads {} \
        rte_pads {} \
        ground_pads {} \
        signal_pads {}]

    dict set ring domains $domain_name $domain
    dict lappend ring order $domain_name
    dict set ring closed false
}

proc tt_iopad_ring_add_pad {ring_var domain_name role instance_name net_name {side ""} {order_index ""}} {
    upvar 1 $ring_var ring

    if {![dict exists $ring domains $domain_name]} {
        error "Unknown IO-pad domain '$domain_name'."
    }

    set role [string toupper $role]
    if {$role ni {IO_POWER RTE GROUND SIGNAL}} {
        error "Unsupported IO-pad role '$role'."
    }

    set common_ground [dict get $ring common_ground_net]
    set io_power_net [dict get $ring domains $domain_name io_power_net]
    set rte_net [dict get $ring domains $domain_name rte_net]

    switch -- $role {
        IO_POWER {
            if {$net_name ne $io_power_net} {
                error "IO_POWER pad '$instance_name' must use '$io_power_net' in domain '$domain_name'; got '$net_name'."
            }
            set field io_power_pads
        }
        RTE {
            if {$net_name ne $rte_net} {
                error "RTE pad '$instance_name' must use '$rte_net' in domain '$domain_name'; got '$net_name'."
            }
            set field rte_pads
        }
        GROUND {
            if {$net_name ne $common_ground} {
                error "GROUND pad '$instance_name' must use common ground '$common_ground'; got '$net_name'."
            }
            set field ground_pads
        }
        SIGNAL {
            set field signal_pads
        }
    }

    set pad [dict create \
        instance $instance_name \
        role $role \
        net $net_name \
        side $side \
        order_index $order_index]

    set pad_list [dict get $ring domains $domain_name $field]
    lappend pad_list $pad
    dict set ring domains $domain_name $field $pad_list
}

proc tt_iopad_ring_close {ring_var} {
    upvar 1 $ring_var ring

    set order [dict get $ring order]
    set count [llength $order]

    if {$count < 2} {
        error "IO-pad ring requires at least two domains."
    }

    dict set ring cuts [dict create]

    for {set i 0} {$i < $count} {incr i} {
        set current [lindex $order $i]
        set next [lindex $order [expr {($i + 1) % $count}]]
        set prev [lindex $order [expr {($i - 1 + $count) % $count}]]

        dict set ring domains $current prev_domain $prev
        dict set ring domains $current next_domain $next

        set cut_name "PR_CUT_${current}__${next}"

        dict set ring cuts $cut_name [dict create \
            name $cut_name \
            left_domain $current \
            right_domain $next \
            cut_io_power true \
            cut_rte true \
            cut_ground false \
            common_ground_net [dict get $ring common_ground_net]]
    }

    dict set ring closed true
}

proc tt_iopad_ring_validate {ring} {
    set errors {}

    if {![dict exists $ring name] ||
        ![dict exists $ring order] ||
        ![dict exists $ring domains] ||
        ![dict exists $ring common_ground_net]} {
        error "Invalid IO-pad ring object."
    }

    if {![dict get $ring closed]} {
        lappend errors "Ring is not closed."
    }

    set order [dict get $ring order]
    set domain_count [llength $order]

    if {$domain_count < 2} {
        lappend errors "Ring must contain at least two domains."
    }

    foreach domain_name $order {
        if {![dict exists $ring domains $domain_name]} {
            lappend errors "Order references missing domain '$domain_name'."
            continue
        }

        set d [dict get $ring domains $domain_name]

        if {[llength [dict get $d io_power_pads]] < 1} {
            lappend errors "Domain '$domain_name' has no IO_POWER pad."
        }

        if {[llength [dict get $d rte_pads]] < 1} {
            lappend errors "Domain '$domain_name' has no RTE pad."
        }

        if {[dict get $d ground_net] ne [dict get $ring common_ground_net]} {
            lappend errors "Domain '$domain_name' does not use the common ground net."
        }

        if {[dict get $d prev_domain] eq "" || [dict get $d next_domain] eq ""} {
            lappend errors "Domain '$domain_name' has incomplete ring links."
        }
    }

    if {[dict exists $ring cuts]} {
        dict for {cut_name cut} [dict get $ring cuts] {
            if {![dict get $cut cut_io_power]} {
                lappend errors "$cut_name must cut IO power."
            }
            if {![dict get $cut cut_rte]} {
                lappend errors "$cut_name must cut RTE."
            }
            if {[dict get $cut cut_ground]} {
                lappend errors "$cut_name must not cut common ground."
            }
        }
    }

    if {[llength $errors] > 0} {
        puts "======================================================================"
        puts " IO PAD RING MODEL: FAIL"
        puts "======================================================================"
        foreach e $errors {
            puts "ERROR: $e"
        }
        puts "======================================================================"
        return false
    }

    puts "======================================================================"
    puts " IO PAD RING MODEL: PASS"
    puts "======================================================================"
    puts "Ring          : [dict get $ring name]"
    puts "Domains       : [join $order { -> }] -> [lindex $order 0]"
    puts "Common ground : [dict get $ring common_ground_net]"
    puts "PR_CUT count  : [dict size [dict get $ring cuts]]"
    puts "======================================================================"
    return true
}

proc tt_iopad_ring_report {ring} {
    puts "======================================================================"
    puts " IO PAD RING TOPOLOGY"
    puts "======================================================================"
    puts "Ring          : [dict get $ring name]"
    puts "Direction     : [dict get $ring direction]"
    puts "Common ground : [dict get $ring common_ground_net]"
    puts ""

    set order [dict get $ring order]

    foreach domain_name $order {
        set d [dict get $ring domains $domain_name]

        puts "Domain        : $domain_name"
        puts "  Previous    : [dict get $d prev_domain]"
        puts "  Next        : [dict get $d next_domain]"
        puts "  IO power    : [dict get $d io_power_net]"
        puts "  RTE         : [dict get $d rte_net]"
        puts "  Ground      : [dict get $d ground_net]"
        puts "  Segment     : [dict get $d segment]"
        puts "  IO_PWR pads : [llength [dict get $d io_power_pads]]"
        puts "  RTE pads    : [llength [dict get $d rte_pads]]"
        puts "  GND pads    : [llength [dict get $d ground_pads]]"
        puts "  Signal pads : [llength [dict get $d signal_pads]]"
        puts ""
    }

    puts "PR_CUT boundaries:"
    dict for {cut_name cut} [dict get $ring cuts] {
        puts "  $cut_name"
        puts "    [dict get $cut left_domain] -> [dict get $cut right_domain]"
        puts "    IO power : CUT"
        puts "    RTE      : CUT"
        puts "    Ground   : SHARED ([dict get $cut common_ground_net])"
    }

    puts "======================================================================"
}
