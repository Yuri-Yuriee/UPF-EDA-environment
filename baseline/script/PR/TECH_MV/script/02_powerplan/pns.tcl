if {![info exists ::TECH_MV_RUNTIME_ROOT]} {
    set ::TECH_MV_RUNTIME_ROOT [file normalize [pwd]]
}
# Runtime adapter preserves the historical logical source path.
if {[info exists ::TECH_MV_RUNTIME_ROOT]} {
    info script [file join $::TECH_MV_RUNTIME_ROOT run/pns.tcl]
}
# Load definitions only; no APR action or setup reload is performed here.
if {![llength [info commands ::tech_mv_library_value]]} {
    if {[info exists ::TOOL_DIR]} {
        source -quiet [file join $::TECH_MV_RUNTIME_ROOT .. script PR TECH_MV script 00_common private_parameter_config.tcl]
    } else {
        source -quiet [file join $::TECH_MV_RUNTIME_ROOT .. script PR TECH_MV script 00_common private_parameter_config.tcl]
    }
}
# PUBLIC_EXPORT_REVIEW_REQUIRED: residual technology candidates require manual review.
# TECH real flow uses temporary bond pads to derive BondPadBlk before PNS.
# Always reload the complete TECH_MV user setup for every run invocation.
# init.setup reloads the categorized setup/config/*.config.tcl files.
# Always reload the complete TECH_MV runtime/configuration for this run entry.
# Resolve build_PR/init.setup from this file; do not depend on script_search_path.
set _tech_run_file [file normalize [info script]]
set _tech_init_setup [file normalize [file join [file dirname $_tech_run_file] .. init.setup]]
if {![file isfile $_tech_init_setup]} {
    error "TECH_MV runtime init.setup not found: $_tech_init_setup"
}
source $_tech_init_setup
unset _tech_run_file
unset _tech_init_setup
source -quiet [file join $SCRIPT_DIR prepare_run_dirs.tcl]

proc createPowerStripeRail { direction layer nets offset width spacing pitch RTopLayer RBotLayer BTopLayer BBotLayer} {
    variable curRegionBKG

    set direction [expr {$direction eq "H" ? "horizontal" : "vertical" }]
   
    set_db add_stripes_ignore_block_check false
    set_db add_stripes_break_at none
    set_db add_stripes_route_over_rows_only false
    set_db add_stripes_rows_without_stripes_only false
    set_db add_stripes_extend_to_closest_target ring
    set_db add_stripes_stop_at_last_wire_for_area false
    set_db add_stripes_partial_set_through_domain false
    set_db add_stripes_ignore_non_default_domains false
    set_db add_stripes_trim_antenna_back_to_shape none
    set_db add_stripes_spacing_type edge_to_edge
    set_db add_stripes_spacing_from_block $::PNS_STRIPE_SPACING_FROM_BLOCK
    set_db add_stripes_stripe_min_length stripe_width
    set_db add_stripes_stacked_via_top_layer AP
    set_db add_stripes_stacked_via_bottom_layer M1
    set_db add_stripes_via_using_exact_crossover_size false
    set_db add_stripes_split_vias false
    set_db add_stripes_orthogonal_only true
    set_db add_stripes_allow_jog { block_ring }
    set_db add_stripes_skip_via_on_pin {  Block standardcell }
    set_db add_stripes_skip_via_on_wire_shape {  noshape Stripe  }
    add_stripes -nets $nets -layer $layer -direction $direction -width $width -spacing $spacing -set_to_set_distance $pitch  -start_from bottom -start_offset $offset -switch_layer_over_obs false -pad_core_ring_top_layer_limit $RTopLayer -pad_core_ring_bottom_layer_limit $RBotLayer -block_ring_top_layer_limit $BTopLayer -block_ring_bottom_layer_limit $BBotLayer -use_wire_group 0 -snap_wire_center_to_grid none -user_class "manual_rail"
}

proc createPowerStripe { direction layer nets offset width spacing pitch snap} {

    set LayerNum [get_db layer:$layer .route_index] 
    if {$LayerNum > 1} {
        set botLayerNum [expr $LayerNum - 1]
    }
    if {$LayerNum < 11} {
        set topLayerNum [expr $LayerNum + 1]
    }
    set botLayer    [get_db layer:$botLayerNum .name]
    set topLayer    [get_db layer:$topLayerNum .name]

    set direction [expr {$direction eq "H" ? "horizontal" : "vertical" }]
   
    set_db add_stripes_ignore_block_check false
    set_db add_stripes_break_at none
    set_db add_stripes_route_over_rows_only false
    set_db add_stripes_rows_without_stripes_only false
    set_db add_stripes_extend_to_closest_target ring
    set_db add_stripes_stop_at_last_wire_for_area false
    set_db add_stripes_partial_set_through_domain false
    set_db add_stripes_ignore_non_default_domains false
    set_db add_stripes_trim_antenna_back_to_shape none
    set_db add_stripes_spacing_type edge_to_edge
    set_db add_stripes_spacing_from_block $::PNS_STRIPE_SPACING_FROM_BLOCK
    set_db add_stripes_stripe_min_length stripe_width
    set_db add_stripes_stacked_via_top_layer $topLayer
    set_db add_stripes_stacked_via_bottom_layer $botLayer
    set_db add_stripes_via_using_exact_crossover_size false
    set_db add_stripes_split_vias false
    set_db add_stripes_orthogonal_only true
    set_db add_stripes_allow_jog { block_ring }
    set_db add_stripes_skip_via_on_pin {  standardcell }
    set_db add_stripes_skip_via_on_wire_shape {  noshape   }
    add_stripes -nets $nets -layer $layer -direction $direction -width $width -spacing $spacing -set_to_set_distance $pitch -start_from bottom -start_offset $offset -switch_layer_over_obs false -max_same_layer_jog_length $::PNS_STRIPE_MAX_SAME_LAYER_JOG_LENGTH -pad_core_ring_top_layer_limit $topLayer -pad_core_ring_bottom_layer_limit $botLayer -block_ring_top_layer_limit $topLayer -block_ring_bottom_layer_limit $botLayer -use_wire_group 0 -snap_wire_center_to_grid $snap 
}

proc createRegionStripe { direction layer nets offset width spacing pitch region} {

    if { $region == "Core" } {
        set area [get_db designs .core_bbox]
    } elseif {$region == "Die" } {
        set area [get_db designs .bbox]
    } else {
        puts "unknow region"
        return;
    }

    set LayerNum [get_db layer:$layer .route_index] 
    set botLayerNum [expr $LayerNum - 1]
    if {$botLayerNum < 1 } {
        set botLayerNum 1
    }
    set topLayerNum [expr $LayerNum + 1]
    if {$topLayerNum > 11} {
        set topLayerNum 11
    } 
    set botLayer    [get_db layer:$botLayerNum .name]
    set topLayer    [get_db layer:$topLayerNum .name]

    set direction [expr {$direction eq "H" ? "horizontal" : "vertical" }]
   
    set_db add_stripes_ignore_block_check false
    set_db add_stripes_break_at none
    set_db add_stripes_route_over_rows_only false
    set_db add_stripes_rows_without_stripes_only false
    set_db add_stripes_extend_to_closest_target none
    set_db add_stripes_stop_at_last_wire_for_area false
    set_db add_stripes_partial_set_through_domain false
    set_db add_stripes_ignore_non_default_domains false
    set_db add_stripes_trim_antenna_back_to_shape none
    set_db add_stripes_spacing_type edge_to_edge
    set_db add_stripes_spacing_from_block $::PNS_STRIPE_SPACING_FROM_BLOCK
    set_db add_stripes_stripe_min_length stripe_width
    set_db add_stripes_stacked_via_top_layer $topLayer
    set_db add_stripes_stacked_via_bottom_layer $botLayer
    set_db add_stripes_via_using_exact_crossover_size false
    set_db add_stripes_split_vias false
    set_db add_stripes_orthogonal_only true
    set_db add_stripes_allow_jog { block_ring }
    set_db add_stripes_skip_via_on_pin {  standardcell }
    set_db add_stripes_skip_via_on_wire_shape {  noshape   }
    add_stripes -nets $nets -layer $layer -direction $direction -width $width -spacing $spacing -set_to_set_distance $pitch -start_from bottom -start_offset $offset -switch_layer_over_obs false -max_same_layer_jog_length $::PNS_STRIPE_MAX_SAME_LAYER_JOG_LENGTH -pad_core_ring_top_layer_limit $topLayer -pad_core_ring_bottom_layer_limit $botLayer -block_ring_top_layer_limit $topLayer -block_ring_bottom_layer_limit $botLayer -use_wire_group 0 -snap_wire_center_to_grid none -area $area
}


proc createPowerRing { nets hlayer vlayer width spacing offset wire_group } {
    set vLayerNum [get_db layer:$vlayer .route_index] 
    set hLayerNum [get_db layer:$hlayer .route_index] 
    if { $vLayerNum > $hLayerNum } {
        set botLayerNum $hLayerNum
        set topLayerNum $vLayerNum
    } else {
        set botLayerNum $vLayerNum
        set topLayerNum $hLayerNum
    }

    if {$botLayerNum >= 1} {
        set botLayerNum [expr $botLayerNum - 1]
    }
    if {$topLayerNum < 11} {
        set topLayerNum [expr $topLayerNum + 1]
    }
    set botLayer    [get_db layer:$botLayerNum .name]

    set_db add_rings_target default
    set_db add_rings_extend_over_row 0
    set_db add_rings_ignore_rows 0
    set_db add_rings_avoid_short 0
    set_db add_rings_skip_shared_inner_ring none
    set_db add_rings_stacked_via_top_layer $topLayerNum
    set_db add_rings_stacked_via_bottom_layer $botLayerNum
    set_db add_rings_via_using_exact_crossover_size 1
    set_db add_rings_orthogonal_only true
    set_db add_rings_skip_via_on_pin {  standardcell }
    set_db add_rings_skip_via_on_wire_shape {  noshape }
    add_rings -nets $nets -type core_rings -follow core -layer [list top $hlayer bottom $hlayer left $vlayer right $vlayer] -width [list top $width bottom $width left $width right $width] -spacing [list top $spacing bottom $spacing left $spacing right $spacing] -offset [list top $offset bottom $offset left $offset right $offset] -center 0 -threshold $::PNS_RING_THRESHOLD -jog_distance $::PNS_RING_JOG_DISTANCE -snap_wire_center_to_grid none -use_wire_group 1 -use_wire_group_bits $wire_group -use_interleaving_wire_group 1
    
}

proc initializePG {} {
    editDelete -physical_pin -use POWER
    editDelete -use POWER
}

proc initializeRegionBKG {} {
    variable curRegionBKG
    array unset curRegionBKG

    set Die  [dbget top.fplan.box -e]
    set Core [dbget top.fplan.coreBox -e]
    set STD  [dbget top.fplan.rows.box -e]

    set curRegionBKG(Core) [dbshape $Die ANDNOT $Core -output rect]
    set curRegionBKG(STD)  [dbshape $Die ANDNOT [dbShape $STD SIZEY $::PNS_STD_REGION_Y_EXPANSION] -output rect]
}

proc pns_ring_from_cfg {nets cfg} {
    createPowerRing $nets [dict get $cfg h_layer] [dict get $cfg v_layer] [dict get $cfg width] [dict get $cfg spacing] [dict get $cfg offset] [dict get $cfg wire_group]
}
proc pns_stripe_from_cfg {nets cfg} {
    createPowerStripe [dict get $cfg direction] [dict get $cfg layer] $nets [dict get $cfg offset] [dict get $cfg width] [dict get $cfg spacing] [dict get $cfg pitch] [dict get $cfg snap]
}

proc runPGPlan {} {

    if {$ENABLE_BOND_PAD_ROUTE_BLOCKAGE} {
        source -quiet [file join $SCRIPT_DIR create_bond_pad_stylus.tcl]
        create_bond_pad_and_route
        create_bond_pad_blockage
        delete_bond_pad_and_route
    }
    
    
    #=== core power ring
    #createPowerRing  nets      TBlayer LRlayer width spacing offset wire_group  
    # createPowerRing $nets $h_layer $v_layer $ring_width $ring_spacing $ring_offset $wire_group
    # createPowerRing $nets $h_layer $v_layer $ring_width $ring_spacing $ring_offset $wire_group
    # createPowerRing $nets $h_layer $v_layer $ring_width $ring_spacing $ring_offset $wire_group
    pns_ring_from_cfg [list $power $ground] $PNS_CORE_RING_1
    pns_ring_from_cfg [list $power $ground] $PNS_CORE_RING_2
    
    #=== sroute pad pin
    set_db route_special_via_connect_to_shape { ring }
    route_special -connect pad_pin -layer_change_range $PNS_PAD_PIN_LAYER_CHANGE_RANGE -block_pin_target nearest_target -pad_pin_port_connect {all_port all_geom} -pad_pin_target nearest_target -pad_pin_layer_range $PNS_PAD_PIN_LAYER_RANGE -allow_jogging 0 -crossover_via_layer_range $PNS_PAD_PIN_LAYER_CHANGE_RANGE -nets [list $power_port $ground]  -allow_layer_change 1 -target_via_layer_range $PNS_PAD_PIN_LAYER_CHANGE_RANGE


    source -quiet [file join $SCRIPT_DIR create_padpin_blockage.tcl]
    pns_ring_from_cfg [list $power $ground] $PNS_CORE_RING_3

    #=== block ring , to terminate followpin
    add_rings -nets [list $power $ground] -type block_rings -around each_block -layer {top M2 bottom M2 left M3 right M3} -width $::PNS_MACRO_RING_WIDTH -spacing $::PNS_MACRO_RING_SPACING -offset $::PNS_MACRO_RING_OFFSET -center 0 -threshold $::PNS_RING_THRESHOLD -jog_distance $::PNS_RING_JOG_DISTANCE -snap_wire_center_to_grid none -skip_side {top bottom}
    
    foreach cell [get_db [get_db insts -if {.base_cell.base_class == block}] .name] {
        set llx [get_db inst:$cell .bbox.ll.x]
        set lly [get_db inst:$cell .bbox.ll.y]
        set urx [get_db inst:$cell .bbox.ur.x]
        set ury [get_db inst:$cell .bbox.ur.y]
        create_route_blockage -name RBKM234 -pg_nets -layers $PNS_MACRO_BLOCKAGE_LAYERS -rects [list [expr {$llx-$PNS_MACRO_BLOCKAGE_CLEARANCE}] $lly $llx $ury]
        create_route_blockage -name RBKM234 -pg_nets -layers $PNS_MACRO_BLOCKAGE_LAYERS -rects [list $urx $lly [expr {$urx+$PNS_MACRO_BLOCKAGE_CLEARANCE}] $ury]
    }
    
    #=== power strape
    #createPowerStripe dir layer nets           offset width spacing pitch  snap
    pns_stripe_from_cfg [list $power $ground] $PNS_M9_ALL_STRIPE
    pns_stripe_from_cfg [list $ground] $PNS_M8_GROUND_STRIPE
    pns_stripe_from_cfg [list $power] $PNS_M8_POWER_STRIPE
    pns_stripe_from_cfg [list $ground] $PNS_M7_GROUND_STRIPE
    pns_stripe_from_cfg [list $power] $PNS_M7_POWER_STRIPE
    pns_stripe_from_cfg [list $ground] $PNS_M6_GROUND_STRIPE
    pns_stripe_from_cfg [list $power] $PNS_M6_POWER_STRIPE
    pns_stripe_from_cfg [list $ground] $PNS_M5_GROUND_STRIPE
    pns_stripe_from_cfg [list $power] $PNS_M5_POWER_STRIPE

    # createPowerStripe $direction $layer $nets $stripe_offset $stripe_width $stripe_spacing $stripe_pitch $snap_mode
    # createPowerStripe $direction $layer $nets $stripe_offset $stripe_width $stripe_spacing $stripe_pitch $snap_mode
    # createPowerStripe $direction $layer $nets $stripe_offset $stripe_width $stripe_spacing $stripe_pitch $snap_mode
    # createPowerStripe $direction $layer $nets $stripe_offset $stripe_width $stripe_spacing $stripe_pitch $snap_mode

    #check_power_vias
    
   #== expand via3 ~ via6
   #set corebox [get_db designs .core_bbox]
   #select_obj [get_obj_in_area -are $corebox -obj_type special_via -layers {VIA3 VIA4 VIA5 VIA6}]
   #update_power_vias -skip_via_on_pin standardcell -bottom_layer M3 -selected_vias 1 -via_scale_height 180 -update_vias 1 -via_scale_width 180 -top_layer M7

 
    write_db [file join $DB_DIR 02_30_pns_power_stripe.enc]
    #=== followpin
    set_db [get_db insts -if {.base_cell.class == core}] .place_status unplaced
 
    set_db route_special_via_connect_to_shape { ring stripe }

    
    


    # current script --> innovus drc clean, calibre drc violation
    route_special -connect core_pin -layer_change_range $PNS_FOLLOW_PIN_LAYER_CHANGE_RANGE -block_pin_target nearest_target -core_pin_target first_after_row_end -allow_jogging 0 \
    -crossover_via_layer_range $PNS_FOLLOW_PIN_LAYER_CHANGE_RANGE -nets [list $power $ground] -allow_layer_change 1 -target_via_layer_range $PNS_FOLLOW_PIN_LAYER_CHANGE_RANGE 
    # For cell height $cell_height, a full-height VIA2 may cause DRC.
    select_routes -shapes followpin -via_cell {VIAGEN12* VIAGEN23* VIAGEN34*}
    update_power_via -bottom_layer [::tech_mv_library_value LIB_TECH_002] -top_layer [::tech_mv_library_value LIB_TECH_003] -update_vias 1 -selected_vias 1  -via_scale_height $PNS_FOLLOW_PIN_VIA_SCALE_HEIGHT -via_scale_width $PNS_FOLLOW_PIN_VIA_SCALE_WIDTH
    
    # try-out script --> innovus drc clean, calibre drc clean
    # route_special -connect core_pin -layer_change_range { M2(2) M5(5) } -block_pin_target nearest_target -core_pin_target first_after_row_end -allow_jogging 0 \
    # -crossover_via_layer_range { M2(2) M5(5) } -nets { VDD VSS } -allow_layer_change 1 -target_via_layer_range { M2(2) M5(5) }
    # For cell height $cell_height, a full-height VIA2 may cause DRC.
    # select_routes -shapes followpin -via_cell {VIAGEN23* VIAGEN34*}
    # update_power_via -bottom_layer M2 -top_layer M4 -update_vias 1 -selected_vias 1  -via_scale_height $PNS_FOLLOW_PIN_VIA_SCALE_HEIGHT -via_scale_width $PNS_FOLLOW_PIN_VIA_SCALE_WIDTH
    
    
    
    # To make standard cells easier at routing stage, need to delete power via1 first, then add the via1 back at post-route stage 
    # select_routes -shapes followpin -via_cell {VIAGEN12*}
    # update_power_via -bottom_layer M1 -top_layer M2 -selected_vias 1 -delete_vias 1



    write_db [file join $DB_DIR 02_40_pns_follow_pin.enc]

    #=== M2 rail
    #createPowerStripeRail direction layer nets  offset width spacing pitch RTopLayer RBotLayer BTopLayer BBotLayer
    createPowerStripeRail "H" "M2" [list $power] [dict get $PNS_M2_POWER_RAIL offset] [dict get $PNS_M2_POWER_RAIL width] [dict get $PNS_M2_POWER_RAIL spacing] [dict get $PNS_M2_POWER_RAIL pitch] [dict get $PNS_M2_POWER_RAIL rtop] [dict get $PNS_M2_POWER_RAIL rbot] [dict get $PNS_M2_POWER_RAIL btop] [dict get $PNS_M2_POWER_RAIL bbot]
    createPowerStripeRail "H" "M2" [list $ground] [dict get $PNS_M2_GROUND_RAIL offset] [dict get $PNS_M2_GROUND_RAIL width] [dict get $PNS_M2_GROUND_RAIL spacing] [dict get $PNS_M2_GROUND_RAIL pitch] [dict get $PNS_M2_GROUND_RAIL rtop] [dict get $PNS_M2_GROUND_RAIL rbot] [dict get $PNS_M2_GROUND_RAIL btop] [dict get $PNS_M2_GROUND_RAIL bbot]
    
    write_db [file join $DB_DIR 02_50_pns_m2_rail.enc]


    delete_obj [get_db route_blockages {RBKM234}]
    delete_obj [get_db route_blockages RBKPADPIN]
    create_pg_model_for_macro_place -file [tech_mv_output_path temp golden_mimic_power_mesh.tcl 02 macro_model]
    
    set_db check_drc_limit $POWERPLAN_DRC_LIMIT
    tech_mv_check_drc
    write_db [file join $DB_DIR 02_60_pns_post_drc.enc]
    
    tech_mv_native_report_command 02 via_repair [list fix_via -min_step]
    write_db [file join $DB_DIR 02_90_pns_powerplan_mesh.enc]
}


if {[info exists PNS_AUTO_RUN_ON_SOURCE] && $PNS_AUTO_RUN_ON_SOURCE} {
    runPGPlan
}
