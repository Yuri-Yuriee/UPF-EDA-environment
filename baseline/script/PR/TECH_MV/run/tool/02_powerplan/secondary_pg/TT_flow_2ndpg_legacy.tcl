# Runtime adapter preserves the historical logical source path.
if {[info exists ::TECH_MV_RUNTIME_ROOT]} {
    info script [file join $::TECH_MV_RUNTIME_ROOT run/tool/02_powerplan/secondary_pg/TT_flow_2ndpg_legacy.tcl]
}
# =============================================================================
# TT_flow_2ndpg_legacy.tcl
# =============================================================================
# Legacy/manual secondary-PG flow.
# The current main flow uses TT_flow_post_place_lp_2ndpg.tcl.
# This file merges the former TT_flow_2ndpg_legacy.tcl + TT_flow_2ndpg_legacy.tcl.
# =============================================================================

# =============================================================================
# TECH_MV Secondary-PG Entry
# =============================================================================
# Thin entry wrapper. Runtime setup/path handling remains unchanged.
# Implementation is kept in TT_flow_2ndpg_legacy.tcl for backward compatibility.
# =============================================================================

if {![info exists INNOVUS_WORK_DIR]} { source init.setup }
source -quiet [file join $SCRIPT_DIR prepare_run_dirs.tcl]



# ===== merged implementation =====
# =============================================================================
# TECH_MV Secondary-PG Routing Implementation
# =============================================================================
# Sourced by TT_flow_2ndpg_legacy.tcl.
# =============================================================================

source [file join $SETUP_DIR global_net.tcl]
source -quiet [file join $SCRIPT_DIR power_proc.tcl]

# Keep the secondary-PG layer policy in setup/config.tcl.
# Defaults retain a safe standalone behavior if this helper is sourced from an
# older checkpoint/environment that does not yet define the new variables.
foreach _cfg_var {SECONDARY_PG_RAIL_LAYER SECONDARY_PG_BOTTOM_LAYER SECONDARY_PG_TOP_LAYER} {
    if {![info exists ::$_cfg_var]} {
        error "Missing config variable $_cfg_var. Source init.setup first."
    }
}
unset _cfg_var

set secondary_pg_layer_range [list $SECONDARY_PG_BOTTOM_LAYER $SECONDARY_PG_TOP_LAYER]
set secondary_pg_vertical_grid [list $SECONDARY_PG_TOP_LAYER 0 0]

puts "INFO: Secondary-PG rail layer : $SECONDARY_PG_RAIL_LAYER"
puts "INFO: Secondary-PG route range: $secondary_pg_layer_range"
puts "INFO: Secondary-PG V-grid top : $SECONDARY_PG_TOP_LAYER"

foreach grp [get_db groups .power_domain.name] {
    puts "========================================"
    puts ""
    puts "Power Domain: $grp"
    puts ""
    puts "========================================"
    set 2nd_rail [get_pd_rail_2nd $grp]
    if {[llength $2nd_rail] == 0} {
        puts "no 2nd rail"
    } else {   
        route_special   -connect secondary_power_pin \
                        -layer_change_range $secondary_pg_layer_range \
                        -block_pin_target nearest_target \
                        -secondary_pin_rail_vertical_stripe_grid $secondary_pg_vertical_grid \
                        -allow_jogging 1 \
                        -power_domains $grp \
                        -crossover_via_layer_range $secondary_pg_layer_range \
                        -secondary_pin_rail_layer $SECONDARY_PG_RAIL_LAYER -nets [get_pd_rail_2nd $grp]  \
                        -allow_layer_change 1 \
                        -secondary_pin_net [get_pd_rail_2nd $grp] \
                        -target_via_layer_range $secondary_pg_layer_range
    }
}
