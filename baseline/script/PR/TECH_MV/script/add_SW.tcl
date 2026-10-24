# =============================================================================
# TECH_MV Power-Switch Insertion
# =============================================================================
# Consolidated implementation preserving both original modes:
#
# legacy:
#   - original script/add_SW.tcl behavior
#   - no add_power_switches edge-offset options
#   - sources global_net.tcl at the end
#
# tool:
#   - original TT_add_SW.tcl behavior
#   - applies configured left/right/top/bottom offsets
# =============================================================================

if {![info exists ::POWER_SWITCH_INSERTION_MODE]} {
    error "POWER_SWITCH_INSERTION_MODE is undefined. Source init.setup first."
}

set _sw_mode [string tolower $::POWER_SWITCH_INSERTION_MODE]

# =============================================================================
# TECH_SW_PREDECIDE_SINGLE_COLUMN_V1_1
#
# Decide checkerboard BEFORE invoking add_power_switches.  This avoids the
# V1.0 destructive/probe behavior where a narrow domain could crash Innovus
# inside add_power_switches -checker_board before fallback code was reached.
# =============================================================================
set _tt_sw_pattern_tool [file join $::TECH_MV_RUNTIME_ROOT .. script PR TECH_MV script 02_powerplan power_switch proc_power_switch_pattern_guard.tcl]
if {![file isfile $_tt_sw_pattern_tool]} {
    error "Power-switch pattern pre-decision tool not found: $_tt_sw_pattern_tool"
}
uplevel #0 [list source -quiet $_tt_sw_pattern_tool]



if {$_sw_mode ni {legacy tool}} {error "Unsupported POWER_SWITCH_INSERTION_MODE '$::POWER_SWITCH_INSERTION_MODE'"}
if {![info exists ::POWER_SWITCH_DESIGN_MAP] || ![info exists ::POWER_SWITCH_HORIZONTAL_PITCH]} {
    error "Missing per-design switch mapping/pitch; source init.setup first"
}
if {![string is double -strict $::POWER_SWITCH_HORIZONTAL_PITCH] || $::POWER_SWITCH_HORIZONTAL_PITCH <= 0} {
    error "Power-switch pitch must be a positive configured length"
}
set _sw_domains {}
set _sw_prefixes {}
foreach _sw_entry $::POWER_SWITCH_DESIGN_MAP {
    foreach _sw_key {domain rule prefix enable_net} {
        if {![dict exists $_sw_entry $_sw_key] || [dict get $_sw_entry $_sw_key] eq ""} {
            error "Incomplete power-switch design mapping: $_sw_key"
        }
    }
    set _sw_domain [dict get $_sw_entry domain]
    set _sw_prefix [dict get $_sw_entry prefix]
    if {$_sw_domain in $_sw_domains || $_sw_prefix in $_sw_prefixes} {error "Duplicate switch domain or instance prefix"}
    lappend _sw_domains $_sw_domain
    lappend _sw_prefixes $_sw_prefix
}
if {$_sw_mode eq "tool"} {
    foreach _cfg_var {POWER_SWITCH_LEFT_OFFSET POWER_SWITCH_RIGHT_OFFSET POWER_SWITCH_TOP_OFFSET POWER_SWITCH_BOTTOM_OFFSET} {
        if {![info exists ::$_cfg_var]} {error "Missing Power Switch config variable $_cfg_var. Source init.setup first."}
    }
}
puts "INFO: Power-switch mode = $_sw_mode"
foreach _sw_entry $::POWER_SWITCH_DESIGN_MAP {
    set _sw_domain [dict get $_sw_entry domain]
    puts "INFO: $_sw_domain IEEE-1801 power-switch rule = [dict get $_sw_entry rule]"
    set _sw_checkerboard [TT_SW_PATTERN_should_checkerboard $_sw_domain $_sw_mode $::POWER_SWITCH_HORIZONTAL_PITCH]
    set _sw_args [list -column -power_domain $_sw_domain \
        -1801_power_switch_rule_name [dict get $_sw_entry rule] \
        -instance_prefix [dict get $_sw_entry prefix]]
    if {$_sw_checkerboard} {lappend _sw_args -checker_board}
    lappend _sw_args -horizontal_pitch $::POWER_SWITCH_HORIZONTAL_PITCH
    if {$_sw_mode eq "tool"} {
        lappend _sw_args -left_offset $::POWER_SWITCH_LEFT_OFFSET -right_offset $::POWER_SWITCH_RIGHT_OFFSET \
            -top_offset $::POWER_SWITCH_TOP_OFFSET -bottom_offset $::POWER_SWITCH_BOTTOM_OFFSET
    }
    lappend _sw_args -enable_net_out [dict get $_sw_entry enable_net]
    add_power_switches {*}${_sw_args}
}
if {$_sw_mode eq "legacy"} {source [file join $SETUP_DIR global_net.tcl]}
unset _tt_sw_pattern_tool _sw_mode _sw_domains _sw_prefixes
catch {unset _sw_entry _sw_key _sw_domain _sw_prefix _sw_checkerboard _sw_args _cfg_var}
