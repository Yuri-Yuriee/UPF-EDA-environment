# Runtime adapter preserves the historical logical source path.
if {[info exists ::TECH_MV_RUNTIME_ROOT]} {
    info script [file join $::TECH_MV_RUNTIME_ROOT run/tool/00_common/TT_private_parameter_config.tcl]
} else {
    info script [file normalize [file join [file dirname [info script]] .. .. run/tool/00_common/TT_private_parameter_config.tcl]]
}
# Compatibility accessor: verified private data first, otherwise reviewed user config.
# Existing command names are retained; no geometry is inferred or changed here.
namespace eval ::tech_mv_private_parameters {
    variable root [file normalize [file join [file dirname [info script]] .. .. ..]]
}

# Query only attributes whose meaning matches the requested component geometry.
proc ::tech_mv_live_geometry {key} {
    if {![llength [info commands get_db]]} { return {} }
    set kind {}
    switch -exact -- $key {
        {welltap::fallback_site_pitch} -
        {run/tool/02_powerplan/TT_PR7_coordinate_guided_repair.tcl::::TT_PR7_COORD_SITE_PITCH_UM::L47} { set kind site_pitch }
        {edge_switch::fallback_inst_grid} { set kind inst_grid }
        {run/tool/02_powerplan/TT_refine_internal_gap_sdps.tcl::::TT_PR7_GAPBLK_FALLBACK_W::L245} { set kind tap_width }
        {run/tool/02_powerplan/TT_refine_internal_gap_sdps.tcl::::TT_PR7_GAPBLK_FALLBACK_H::L246} { set kind tap_height }
        default { return {} }
    }
    if {$kind eq "site_pitch" || $kind eq "inst_grid"} {
        set raw {}
        catch {set raw [get_db floorplan_finfet_inst_grid]}
        if {$kind eq "site_pitch"} { set indices {2} } else { set indices {2 3 0 1} }
        foreach i $indices {
            if {[llength $raw] > $i} {
                set v [lindex $raw $i]
                if {[string is double -strict $v] && $v > 0} {
                    return [dict create value $v source floorplan_finfet_inst_grid]
                }
            }
        }
        return {}
    }
    set master {}
    if {[info exists ::TT_2ROW_SDP_WELLTAP_MASTER] && $::TT_2ROW_SDP_WELLTAP_MASTER ne ""} {
        set master $::TT_2ROW_SDP_WELLTAP_MASTER
    } elseif {[info exists ::TECH_WT_CELL] && $::TECH_WT_CELL ne ""} {
        set master $::TECH_WT_CELL
    }
    if {$master eq ""} { return {} }
    set cells {}
    catch {set cells [get_db base_cells $master]}
    if {[llength $cells] != 1} { return {} }
    set box {}
    catch {set box [get_db [lindex $cells 0] .bbox]}
    if {[llength $box] == 1 && [llength [lindex $box 0]] == 4} { set box [lindex $box 0] }
    if {[llength $box] != 4} { return {} }
    foreach v $box { if {![string is double -strict $v]} { return {} } }
    lassign $box x1 y1 x2 y2
    if {$kind eq "tap_width"} { set v [expr {abs($x2-$x1)}] } else { set v [expr {abs($y2-$y1)}] }
    if {$v <= 0} { return {} }
    return [dict create value $v source base_cell_bbox]
}

proc ::tech_mv_private_value {key} {
    set path [file join $::tech_mv_private_parameters::root setup config private geometry_values.tcl]
    if {[info exists ::env(TECH_MV_PRIVATE_CONFIG_FILE)] && $::env(TECH_MV_PRIVATE_CONFIG_FILE) ne ""} {
        set path [file normalize $::env(TECH_MV_PRIVATE_CONFIG_FILE)]
        if {![file isfile $path]} { error "Required private parameter config is missing: $path" }
    }
    if {[file isfile $path]} {
        set values [source $path]
        if {[dict exists $values $key]} { return [dict get $values $key] }
    }
    set live [::tech_mv_live_geometry $key]
    if {$live ne ""} { return [dict get $live value] }
    set config [file join $::tech_mv_private_parameters::root setup config geometry_review.config.tcl]
    if {![file isfile $config]} { error "Required reviewed geometry config is missing: $config" }
    set values [source $config]
    if {![dict exists $values $key]} { error "Required geometry config key is missing: $key" }
    if {$key in {
        welltap::fallback_site_pitch
        edge_switch::fallback_inst_grid
        run/tool/02_powerplan/TT_PR7_coordinate_guided_repair.tcl::::TT_PR7_COORD_SITE_PITCH_UM::L47
        run/tool/02_powerplan/TT_refine_internal_gap_sdps.tcl::::TT_PR7_GAPBLK_FALLBACK_W::L245
        run/tool/02_powerplan/TT_refine_internal_gap_sdps.tcl::::TT_PR7_GAPBLK_FALLBACK_H::L246
    } && ![info exists ::tech_mv_private_parameters::warned($key)]} {
        puts stderr "WARNING: Live geometry unavailable; using the configured fallback for $key."
        set ::tech_mv_private_parameters::warned($key) 1
    }
    return [dict get $values $key]
}

# Execute an unchanged private setup assignment in the original config scope.
# The private dictionary is data; original expressions keep their source order.
proc ::tech_mv_setup_command {key} {
    set path [file join $::tech_mv_private_parameters::root setup config private setup_commands.tcl]
    if {![file isfile $path]} {
        error "Private setup is not installed. Install the authorized setup bundle before loading the flow."
    }
    set commands [source $path]
    if {![dict exists $commands $key]} {error "Required private setup key is missing: $key"}
    uplevel 1 [dict get $commands $key]
}

# Library/technology literals are data; preserve matching and caller operations.
proc ::tech_mv_library_value {key} {
    # Materialized Runtime Library config is authoritative when present.
    # Older/template setups retain the existing Runtime-private bundle fallback.
    if {[array exists ::TECH_MV_LIBRARY_VALUES]} {
        if {![info exists ::TECH_MV_LIBRARY_VALUES($key)]} {error "Required Runtime library setting is missing: $key"}
        return $::TECH_MV_LIBRARY_VALUES($key)
    }
    set path [file join $::tech_mv_private_parameters::root setup config private setup_commands.tcl]
    if {![file isfile $path]} {error "Private library settings are not installed."}
    set values [source $path]
    set entry "library_value::$key"
    if {![dict exists $values $entry]} {error "Required library setting is missing: $key"}
    return [dict get $values $entry]
}

# Internal interface index; users edit the private setup values, not this index.
proc ::tech_mv_register_library_interfaces {} {
    array set ::TECH_MV_LIBRARY_PARAMETER_KEYS {
        LIB_CELL_001 {library_value::LIB_CELL_001}
        LIB_CELL_002 {library_value::LIB_CELL_002}
        LIB_CELL_003 {library_value::LIB_CELL_003}
        LIB_CELL_004 {library_value::LIB_CELL_004}
        LIB_CELL_005 {library_value::LIB_CELL_005}
        LIB_CELL_006 {library_value::LIB_CELL_006}
        LIB_CELL_007 {library_value::LIB_CELL_007}
        LIB_CELL_008 {library_value::LIB_CELL_008}
        LIB_CELL_009 {library_value::LIB_CELL_009}
        LIB_CELL_010 {library_value::LIB_CELL_010}
        LIB_CELL_011 {library_value::LIB_CELL_011}
        LIB_MATCH_001 {library_value::LIB_MATCH_001}
        LIB_MATCH_002 {library_value::LIB_MATCH_002}
        LIB_MATCH_003 {library_value::LIB_MATCH_003}
        LIB_PIN_001 {library_value::LIB_PIN_001}
        LIB_PIN_002 {library_value::LIB_PIN_002}
        LIB_PIN_003 {library_value::LIB_PIN_003}
        LIB_PIN_004 {library_value::LIB_PIN_004}
        LIB_PIN_005 {library_value::LIB_PIN_005}
        LIB_PIN_006 {library_value::LIB_PIN_006}
        LIB_PIN_007 {library_value::LIB_PIN_007}
        LIB_PIN_008 {library_value::LIB_PIN_008}
        LIB_PIN_009 {library_value::LIB_PIN_009}
        LIB_QUERY_001 {library_value::LIB_QUERY_001}
        LIB_QUERY_002 {library_value::LIB_QUERY_002}
        LIB_TECH_001 {library_value::LIB_TECH_001}
        LIB_TECH_002 {library_value::LIB_TECH_002}
        LIB_TEXT_001 {library_value::LIB_TEXT_001}
        LIB_TEXT_002 {library_value::LIB_TEXT_002}
        LIB_TEXT_003 {library_value::LIB_TEXT_003}
        LIB_TEXT_004 {library_value::LIB_TEXT_004}
        LIB_TEXT_005 {library_value::LIB_TEXT_005}
        LIB_TECH_003 {library_value::LIB_TECH_003}
        LIB_TECH_004 {library_value::LIB_TECH_004}
        LIB_TECH_005 {library_value::LIB_TECH_005}
        LIB_TECH_006 {library_value::LIB_TECH_006}
        LIB_TECH_007 {library_value::LIB_TECH_007}
        LIB_TECH_008 {library_value::LIB_TECH_008}
        LIB_TEXT_006 {library_value::LIB_TEXT_006}
        LIB_TEXT_007 {library_value::LIB_TEXT_007}
        LIB_TEXT_008 {library_value::LIB_TEXT_008}
        LIB_TEXT_009 {library_value::LIB_TEXT_009}
        LIB_TEXT_010 {library_value::LIB_TEXT_010}
        LIB_TEXT_011 {library_value::LIB_TEXT_011}
        LIB_TEXT_012 {library_value::LIB_TEXT_012}
        LIB_TEXT_013 {library_value::LIB_TEXT_013}
        LIB_TEXT_014 {library_value::LIB_TEXT_014}
        LIB_TEXT_015 {library_value::LIB_TEXT_015}
        LIB_TEXT_016 {library_value::LIB_TEXT_016}
        LIB_TEXT_017 {library_value::LIB_TEXT_017}
        LIB_TEXT_018 {library_value::LIB_TEXT_018}
        LIB_TEXT_019 {library_value::LIB_TEXT_019}
        LP_PIN_SECONDARY_A {library_value::LP_PIN_SECONDARY_A}
        LP_PIN_SECONDARY_B {library_value::LP_PIN_SECONDARY_B}
        LP_PIN_RETENTION_AON {library_value::LP_PIN_RETENTION_AON}
        PG_LIBRARY_POWER_PIN_VALUES {library_value::PG_LIBRARY_POWER_PIN_VALUES}
        PG_LIBRARY_GROUND_PINS {library_value::PG_LIBRARY_GROUND_PINS}
        SW_LANDING_TARGET_INSTANCE {library_value::SW_LANDING_TARGET_INSTANCE}
        SW_LANDING_TARGET_NET {library_value::SW_LANDING_TARGET_NET}
        SW_LANDING_PG_PIN_PATTERN {library_value::SW_LANDING_PG_PIN_PATTERN}
        SW_LANDING_INSTANCE_PATTERN {library_value::SW_LANDING_INSTANCE_PATTERN}
        SW_LANDING_POWER_PIN {library_value::SW_LANDING_POWER_PIN}
        SW_GATE_NET_ISSUE_PATTERN {library_value::SW_GATE_NET_ISSUE_PATTERN}
        ENDCAP_DIRECTION_EXACT_1 {library_value::ENDCAP_DIRECTION_EXACT_1}
        ENDCAP_DIRECTION_EXACT_2 {library_value::ENDCAP_DIRECTION_EXACT_2}
        PURE_FILLER_MASTER_PATTERN {library_value::PURE_FILLER_MASTER_PATTERN}
        TIEOFF_MASTER_LIST {library_value::TIEOFF_MASTER_LIST}
        DESIGN_PROCESS_NODE {library_value::DESIGN_PROCESS_NODE}
        DESIGN_NATIVE_TOP_LAYER {library_value::DESIGN_NATIVE_TOP_LAYER}
        DESIGN_NATIVE_BOTTOM_LAYER {library_value::DESIGN_NATIVE_BOTTOM_LAYER}
        IO_ELECTRICAL_PIN_01 {library_value::IO_ELECTRICAL_PIN_01}
        IO_ELECTRICAL_PIN_02 {library_value::IO_ELECTRICAL_PIN_02}
        IO_ELECTRICAL_PIN_03 {library_value::IO_ELECTRICAL_PIN_03}
        IO_ELECTRICAL_PIN_04 {library_value::IO_ELECTRICAL_PIN_04}
        CTS_SHIELD_NET {library_value::CTS_SHIELD_NET}
        LIB_DIAGNOSTIC_ID_12 {library_value::LIB_DIAGNOSTIC_ID_12}
        LIB_DIAGNOSTIC_ID_13 {library_value::LIB_DIAGNOSTIC_ID_13}
        IOPAD_DISCOVERY_MASTER_FAMILIES {library_value::IOPAD_DISCOVERY_MASTER_FAMILIES}
        IOPAD_DISCOVERY_CORNER_MASTER {library_value::IOPAD_DISCOVERY_CORNER_MASTER}
        IOPAD_PG_PLACEMENT_MASTER_01 {library_value::IOPAD_PG_PLACEMENT_MASTER_01}
        IOPAD_PG_PLACEMENT_MASTER_02 {library_value::IOPAD_PG_PLACEMENT_MASTER_02}
        IOPAD_PG_PLACEMENT_MASTER_03 {library_value::IOPAD_PG_PLACEMENT_MASTER_03}
        IOPAD_PG_PLACEMENT_MASTER_04 {library_value::IOPAD_PG_PLACEMENT_MASTER_04}
        IOPAD_PG_PLACEMENT_MASTER_05 {library_value::IOPAD_PG_PLACEMENT_MASTER_05}
        IOPAD_PG_PLACEMENT_MASTER_06 {library_value::IOPAD_PG_PLACEMENT_MASTER_06}
        IOPAD_PG_PLACEMENT_MASTER_07 {library_value::IOPAD_PG_PLACEMENT_MASTER_07}
        SW_CONNECTIVITY_DIAGNOSTIC_PIN {library_value::SW_CONNECTIVITY_DIAGNOSTIC_PIN}
        DEBUG_SWITCH_CHAIN_PIN_PATTERN {library_value::DEBUG_SWITCH_CHAIN_PIN_PATTERN}
        ENDCAP_CHECKPOINT_COMPAT_NAMES {library_value::ENDCAP_CHECKPOINT_COMPAT_NAMES}
    }
}
