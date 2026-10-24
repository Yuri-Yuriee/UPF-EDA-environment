# =============================================================================
# TECH_MV user configuration master
# =============================================================================
# This list is intentionally explicit.
# Every init.setup invocation reloads ALL nine official TECH_MV config files.
# Backup or experimental config files must never silently become active.
# =============================================================================

set CONFIG_DIR [file join $SETUP_DIR config]

# Reload the accessor before config defaults, including in existing Innovus sessions.
source [file join $::TECH_MV_RUNTIME_ROOT .. script PR TECH_MV script 00_common private_parameter_config.tcl]

# Central library-key mapping; stage assignments retain their existing order.
source [file join $CONFIG_DIR 00_library.config.tcl]

set CONFIG_COMPONENT_FILES [list \
    [file join $CONFIG_DIR 00_input.config.tcl] \
    [file join $CONFIG_DIR 00_design.config.tcl] \
    [file join $CONFIG_DIR 01_floorplan.config.tcl] \
    [file join $CONFIG_DIR 02_powerplan.config.tcl] \
    [file join $CONFIG_DIR 03_place.config.tcl] \
    [file join $CONFIG_DIR 04_cts.config.tcl] \
    [file join $CONFIG_DIR 05_route.config.tcl] \
    [file join $CONFIG_DIR 06_finish.config.tcl] \
    [file join $CONFIG_DIR 90_debug.config.tcl] \
]

puts "INFO: Reloading all TECH_MV configuration files."

set _tech_config_loaded_count 0
foreach cfg $CONFIG_COMPONENT_FILES {
    if {![file isfile $cfg]} {
        error "Missing TECH_MV config component: $cfg"
    }
    puts "INFO: Source config: [file tail $cfg]"
    source $cfg
    incr _tech_config_loaded_count
}

if {$_tech_config_loaded_count != 9} {
    error "TECH_MV configuration reload count is invalid: $_tech_config_loaded_count"
}

puts "INFO: TECH_MV configuration reload completed: 9 files."
unset _tech_config_loaded_count
