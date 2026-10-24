
set_db cts_buffer_cells $::TECH_CTS_BUFFER_MASTER_LIST 

set_db cts_inverter_cells $::TECH_CTS_INVERTER_MASTER_LIST

set_db cts_clock_gating_cells $::TECH_CTS_CLOCK_GATING_MASTER_LIST

# set_db cts_use_inverters true

if {[llength [get_db route_rules TrunkNDR]] == 0} {
# SENSITIVE: NDR wire widths and wire spacing; review before public export.
    create_route_rule -name TrunkNDR -width $::TECH_CTS_NDR_WIDTH_L12 -spacing $::TECH_CTS_NDR_SPACING_L12 -generate_via
} else {
# SENSITIVE: NDR wire widths and wire spacing; review before public export.
    update_route_rule -name TrunkNDR -width $::TECH_CTS_NDR_WIDTH_L15 -spacing $::TECH_CTS_NDR_SPACING_L15 -generate_via
}
if {[llength [get_db route_rules LeafNDR]] == 0} {
# SENSITIVE: NDR wire widths and wire spacing; review before public export.
    create_route_rule -name LeafNDR -width $::TECH_CTS_NDR_WIDTH_L19 -spacing $::TECH_CTS_NDR_SPACING_L19 
} else {
# SENSITIVE: NDR wire widths and wire spacing; review before public export.
    update_route_rule -name LeafNDR -width $::TECH_CTS_NDR_WIDTH_L22 -spacing $::TECH_CTS_NDR_SPACING_L22 
}
if {[llength [get_db route_types ClkTrunkNDR]] == 0} {
     create_route_type -name ClkTrunkNDR \
                       -route_rule TrunkNDR \
                       -top_preferred_layer 7 \
                       -bottom_preferred_layer 6 \
                       -min_stack_layer 5 \
                       -shield_net [::tech_mv_library_value CTS_SHIELD_NET]
} else {
    # update_route_rule -name ClkTrunkNDR \
    #                    -top_preferred_layer 7 \
    #                    -bottom_preferred_layer 6 \
    #                    -min_stack_layer 5 \
    #                    -shield_net [::tech_mv_library_value CTS_SHIELD_NET]
}
if {[llength [get_db route_types ClkLeafNDR]] == 0} {
     create_route_type -name ClkLeafNDR \
                       -route_rule LeafNDR \
                       -top_preferred_layer 5 \
                       -bottom_preferred_layer 4 \
                       -min_stack_layer 5
} else {
    # update_route_rule -name ClkLeafNDR \
    #                    -top_preferred_layer 5 \
    #                    -bottom_preferred_layer 4 \
    #                    -min_stack_layer 5
}
set_db cts_route_type_top  ClkTrunkNDR
set_db cts_route_type_trunk ClkTrunkNDR 
set_db cts_route_type_leaf ClkLeafNDR 

set_db cts_target_max_transition_time_top 150ps
set_db cts_target_max_transition_time_trunk 150ps
set_db cts_target_max_transition_time_leaf 130ps
set_db timing_enable_generated_clock_edge_based_source_latency false
set_db cts_update_clock_latency false
