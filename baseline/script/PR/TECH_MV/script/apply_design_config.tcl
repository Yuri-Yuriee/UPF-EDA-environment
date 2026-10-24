# PUBLIC_EXPORT_REVIEW_REQUIRED: residual technology candidates require manual review.

puts "User script [info script]"

delete_assigns
set_db init_no_new_assigns 1

# Process-fixed settings
set_db design_process_node [::tech_mv_library_value DESIGN_PROCESS_NODE]
set_db design_top_routing_layer [::tech_mv_library_value DESIGN_NATIVE_TOP_LAYER]
set_db design_bottom_routing_layer [::tech_mv_library_value DESIGN_NATIVE_BOTTOM_LAYER]

create_basic_path_groups -reset
create_basic_path_groups -expanded

# User-adjustable timing settings from setup/config.tcl
set_db timing_analysis_type $TIMING_ANALYSIS_TYPE
set_db timing_analysis_cppr $TIMING_CPPR_MODE

set_timing_derate -max -early $MAX_DERATE_EARLY -late $MAX_DERATE_LATE
set_timing_derate -min -early $MIN_DERATE_EARLY -late $MIN_DERATE_LATE

# Process-fixed tie cells
set_db add_tieoffs_max_fanout 10
set_db add_tieoffs_max_distance 100
set_db add_tieoffs_cells [::tech_mv_library_value TIEOFF_MASTER_LIST]

source -quiet [file join $SCRIPT_DIR set_activity.tcl]
set_db power_write_db false
set_db power_write_static_currents false

set_db design_early_clock_flow true

set_db place_detail_use_no_diffusion_one_site_filler true
set_db place_detail_no_filler_without_implant true
set_db place_detail_check_cut_spacing true
set_db place_detail_check_route true
set_db design_cong_effort high
set_db place_detail_honor_inst_pad true
set_db place_detail_color_aware_legal true
