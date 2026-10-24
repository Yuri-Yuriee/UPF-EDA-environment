# PUBLIC_EXPORT_REVIEW_REQUIRED: residual technology candidates require manual review.
# =============================================================================
# TECH_MV Power-Planning Helper Procedures
# =============================================================================
# Public procedures:
#
#   createPowerRing
#       Create the existing TECH_MV core-ring structure.
#
#   createPowerStripe
#       Create the existing TECH_MV stripe structure only.
#
#   connectFloatingPowerStripe
#       Complete floating M5/M6 stripes with one global SRoute pass per layer
#       after every Power-Domain stripe has been generated.
#
#   get_pd_nets / get_pd_rail / get_pd_power / get_pd_rail_2nd
#       Read power-domain PG configuration from PD_CFG.
#
#   select_pd_group
#       Select a Power Domain by its physical group object.
#
#   select_pd_center
#       Legacy point-selection helper retained for compatibility. The active
#       flow should prefer select_pd_group.
#
# This file only defines helper procedures. No routing is performed merely by
# sourcing this file.
# =============================================================================

# -----------------------------------------------------------------------------
# Core-ring generation
# -----------------------------------------------------------------------------
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
    set_db add_rings_skip_via_on_pin { standardcell }
    set_db add_rings_skip_via_on_wire_shape { noshape }
    add_rings -nets $nets -type core_rings -follow core -layer [list top $hlayer bottom $hlayer left $vlayer right $vlayer] -width [list top $width bottom $width left $width right $width] -spacing [list top $spacing bottom $spacing left $spacing right $spacing] -offset [list top $offset bottom $offset left $offset right $offset] -center 0 -threshold 0 -jog_distance 0 -snap_wire_center_to_grid none -use_wire_group 1 -use_wire_group_bits $wire_group -use_interleaving_wire_group 1
}

# -----------------------------------------------------------------------------
# Floating-stripe completion
# -----------------------------------------------------------------------------
# This intentionally follows the Innovus SRoute command that was verified
# interactively for the current TECH_MV design:
#
#   set_db route_special_via_connect_to_shape {noshape}
#   route_special -connect floating_stripe ...
#
# Only M5/M6 are handled here. Upper-metal global stripes keep their original
# behavior unchanged.
proc connectFloatingPowerStripe {layer nets} {
    set layer_num [get_db layer:$layer .route_index]

    # The actual TECH_MV ring/stripe topology requires SRoute to see
    # possible targets on M5, M6 and M7.  Both M5 and M6 floating-stripe
    # completion therefore use the same routing range.
    if {$layer_num ni {5 6}} { return }
    set layer_change_range $::POWERPLAN_FLOATING_STRIPE_LAYER_CHANGE_RANGE

    if {[llength $nets] == 0} {
        return
    }

    puts "========================================"
    puts "SRoute floating stripe"
    puts "Layer : $layer"
    puts "Nets  : $nets"
    puts "Range : $layer_change_range"
    puts "========================================"

    set_db route_special_via_connect_to_shape {noshape}

    # Do not use -power_domain here.
    # In this design the PD ring special-wire objects are not visible to
    # route_special when the Power-Domain scope is applied.
    #
    # Another stripe/followpin/block pin is intentionally not a target.
    route_special \
        -connect floating_stripe \
        -layer_change_range $layer_change_range \
        -floating_stripe_target $::POWERPLAN_FLOATING_STRIPE_TARGETS \
        -allow_jogging 0 \
        -crossover_via_layer_range $layer_change_range \
        -nets [concat $nets] \
        -allow_layer_change 1 \
        -target_via_layer_range $layer_change_range
}

# -----------------------------------------------------------------------------
# Stripe generation
# -----------------------------------------------------------------------------
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
    puts "========================================"
    puts ""
    puts "LayerNum: $LayerNum"
    puts "nets :$nets"
    puts ""
    puts "========================================"
    
  
    set_db add_stripes_route_over_rows_only false
    set_db add_stripes_rows_without_stripes_only false
    set_db add_stripes_extend_to_closest_target ring
    set_db add_stripes_stop_at_last_wire_for_area false
    
    set_db add_stripes_trim_antenna_back_to_shape none
    set_db add_stripes_spacing_type edge_to_edge
    set_db add_stripes_spacing_from_block 0
    set_db add_stripes_stripe_min_length stripe_width
    set_db add_stripes_stacked_via_top_layer $topLayer
    set_db add_stripes_stacked_via_bottom_layer $botLayer
    set_db add_stripes_via_using_exact_crossover_size false
    set_db add_stripes_split_vias false
    set_db add_stripes_orthogonal_only true
    set_db add_stripes_allow_jog { block_ring }
    set_db add_stripes_skip_via_on_pin {  standardcell }
    set_db add_stripes_skip_via_on_wire_shape {  noshape   }
    if {$LayerNum > 6} {
        set_db add_stripes_partial_set_through_domain true
        set_db add_stripes_ignore_block_check true
        set_db add_stripes_ignore_non_default_domains true
        set_db add_stripes_break_at none
        add_stripes -nets [concat $nets] \
            -layer $layer \
            -direction $direction \
            -width $width \
            -spacing $spacing \
            -set_to_set_distance $pitch \
            -start_from bottom -start_offset $offset \
            -switch_layer_over_obs false \
            -max_same_layer_jog_length [::tech_mv_private_value {power_proc::stripe_max_jog_length}] \
            -pad_core_ring_top_layer_limit $topLayer \
            -pad_core_ring_bottom_layer_limit $botLayer \
            -block_ring_top_layer_limit $topLayer \
            -block_ring_bottom_layer_limit $botLayer \
            -use_wire_group 0 -snap_wire_center_to_grid $snap 
    } else {
        set_db add_stripes_ignore_non_default_domains true
        set_db add_stripes_partial_set_through_domain false
        set_db add_stripes_ignore_block_check true
        set_db add_stripes_break_at {  block_ring  outer_ring  }
        add_stripes -nets [concat $nets] \
            -over_power_domain 1 \
            -layer $layer \
            -direction $direction \
            -width $width \
            -spacing $spacing \
            -set_to_set_distance $pitch \
            -start_from bottom -start_offset $offset \
            -switch_layer_over_obs false \
            -max_same_layer_jog_length [::tech_mv_private_value {power_proc::ring_connect_max_jog_length}] \
            -pad_core_ring_top_layer_limit $topLayer \
            -pad_core_ring_bottom_layer_limit $botLayer \
            -block_ring_top_layer_limit $topLayer \
            -block_ring_bottom_layer_limit $botLayer \
            -use_wire_group 0 -snap_wire_center_to_grid $snap

    }
}

# ============================================================
# Get nets by power domain name
# return format: {power_net ground_net}
# ============================================================
proc get_pd_nets {pd_name} {
    global PD_CFG

    if {![dict exists $PD_CFG $pd_name]} {
        puts "WARNING: No PD_CFG entry for power domain: $pd_name"
        return ""
    }

    set power_net  [dict get $PD_CFG $pd_name power_net]
    set ground_net [dict get $PD_CFG $pd_name ground_net]

    return [concat $power_net]
}

proc get_pd_rail {pd_name} {
    global PD_CFG

    if {![dict exists $PD_CFG $pd_name]} {
        puts "WARNING: No PD_CFG entry for power domain: $pd_name"
        return ""
    }

    set power_net  [dict get $PD_CFG $pd_name power_rail]
    set ground_net [dict get $PD_CFG $pd_name ground_net]

    return [list $power_net $ground_net]
}

proc get_pd_power {pd_name} {
    global PD_CFG

    if {![dict exists $PD_CFG $pd_name]} {
        puts "WARNING: No PD_CFG entry for power domain: $pd_name"
        return ""
    }

    set power_net  [dict get $PD_CFG $pd_name power_rail]

    return [list $power_net]
}


# Select the physical group associated with a Power Domain directly.
# This is robust for non-rectangular and multi-rectangle Power Domains because
# it does not depend on a bounding-box center point landing inside the region.
proc select_pd_group {pd_name} {
    set pd_groups [get_db groups -if \
        [format {.power_domain.name == "%s"} $pd_name]]

    if {[llength $pd_groups] == 0} {
        error "Cannot find physical group for Power Domain '$pd_name'."
    }

    if {[llength $pd_groups] > 1} {
        error "Power Domain '$pd_name' maps to multiple physical groups: $pd_groups"
    }

    set pd_group [lindex $pd_groups 0]
    set rects [get_db $pd_group .rects]

    if {[llength $rects] == 0} {
        error "Power Domain '$pd_name' has no physical rectangles."
    }

    deselect_obj -all
    select_obj $pd_group

    puts "========================================"
    puts "Selected Power Domain group"
    puts "Power Domain : $pd_name"
    puts "Group object : $pd_group"
    puts "Group name   : [get_db $pd_group .name]"
    puts "Rectangles   : $rects"
    puts "========================================"

    return $pd_group
}

# -----------------------------------------------------------------------------
# Legacy center-point selector (retained; active flow should use select_pd_group)
# -----------------------------------------------------------------------------
proc select_pd_center {pd_name} {

    # Find the group corresponding to the power domain
    set grp [get_db groups -if ".power_domain.name == $pd_name"]

    if {$grp eq ""} {
        puts "ERROR: Cannot find group for power domain: $pd_name"
        return
    }

    # Get the group rectangles
    set rects [get_db $grp .rects]

    if {$rects eq "" || [llength $rects] == 0} {
        puts "ERROR: No rects found for power domain: $pd_name"
        return
    }

    puts "Power Domain = $pd_name"
    puts "Group        = [get_db $grp .name]"
    puts "Rects        = $rects"

    # Initialize the bounding box with the first rectangle
    set first_rect [lindex $rects 0]

    set min_x [lindex $first_rect 0]
    set min_y [lindex $first_rect 1]
    set max_x [lindex $first_rect 2]
    set max_y [lindex $first_rect 3]

    # Scan all rectangles and compute the overall bounding box
    foreach rect $rects {
        set llx [lindex $rect 0]
        set lly [lindex $rect 1]
        set urx [lindex $rect 2]
        set ury [lindex $rect 3]

        if {$llx < $min_x} { set min_x $llx }
        if {$lly < $min_y} { set min_y $lly }
        if {$urx > $max_x} { set max_x $urx }
        if {$ury > $max_y} { set max_y $ury }
    }

    # Compute the center point
    set cx [expr {($min_x + $max_x) / 2.0}]
    set cy [expr {($min_y + $max_y) / 2.0}]

    set cx [format "%.5f" $cx]
    set cy [format "%.5f" $cy]

    puts "BBox   = {$min_x $min_y $max_x $max_y}"
    puts "Center = {$cx $cy}"

    # Select the center point in the GUI
    gui_select -point [list $cx $cy]
}

proc get_pd_rail_2nd {pd_name} {
    global PD_CFG

    if {![dict exists $PD_CFG $pd_name]} {
        puts "WARNING: No PD_CFG entry for power domain: $pd_name"
        return ""
    }

    set rail_2nd  [dict get $PD_CFG $pd_name rail_2nd]

    return $rail_2nd
}
