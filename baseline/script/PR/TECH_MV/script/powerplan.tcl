# Load definitions only; no APR action or setup reload is performed here.
if {![llength [info commands ::tech_mv_library_value]]} {
    if {[info exists ::TOOL_DIR]} {
        source -quiet [file join $::TECH_MV_RUNTIME_ROOT .. script PR TECH_MV script 00_common private_parameter_config.tcl]
    } else {
        source -quiet [file join $::TECH_MV_RUNTIME_ROOT .. script PR TECH_MV script 00_common private_parameter_config.tcl]
    }
}
# PUBLIC_EXPORT_REVIEW_REQUIRED: residual technology candidates require manual review.
# Load the output-path helper if this stage is sourced by an older live session.
if {![llength [info commands ::tech_mv_native_report_command]]} {
    source -quiet [file join $::TOOL_DIR 00_common TT_runtime_output_helpers.tcl]
}
# Powerplan
# 2025.06.19 Thu. Rowan Lin

#===============================================================================================================================================================================#

# Step 1: load power-planning utility procedures
source [file join $SCRIPT_DIR power_proc.tcl]
source -quiet [file join $TOOL_DIR 01_floorplan geometry TT_proc_pd_geometry.tcl]
source -quiet [file join $SCRIPT_DIR powerplan_drc_checkpoint.tcl]
source -quiet [file join $SCRIPT_DIR powerplan_step_pause.tcl]

proc powerplan_ring_from_cfg {nets cfg} {
    createPowerRing $nets \
        [dict get $cfg h_layer] \
        [dict get $cfg v_layer] \
        [dict get $cfg width] \
        [dict get $cfg spacing] \
        [dict get $cfg offset] \
        [dict get $cfg wire_group]
}

proc powerplan_stripe_from_cfg {nets cfg} {
    createPowerStripe \
        [dict get $cfg direction] \
        [dict get $cfg layer] \
        $nets \
        [dict get $cfg offset] \
        [dict get $cfg width] \
        [dict get $cfg spacing] \
        [dict get $cfg pitch] \
        [dict get $cfg snap]
}

powerplan_step_pause legacy_powerplan_begin     "Input floorplan before creating any power ring or stripe."


# Real TECH PowerPlan Step 1: derive BondPadBlk from temporary bond-pad
# placement, then remove only the temporary bond-pad/RDL objects.
if {$ENABLE_BOND_PAD_ROUTE_BLOCKAGE} {
    source -quiet [file join $SCRIPT_DIR create_bond_pad_stylus.tcl]
    create_bond_pad_and_route
    create_bond_pad_blockage
    delete_bond_pad_and_route
    write_db [file join $DB_DIR 02_05_bond_pad_blockage.enc]
    powerplan_step_pause bond_pad_route_blockage \
        "Created BondPadBlk from temporary TECH FILL_IN_CELL_BOND_PAD_041 bond-pad placement."
}


# Return only user-configured Power Domains that actually own physical
# floorplan rectangles.  UPF may create logical/internal domains such as
# _internal_<power>_<ground>_; those domains must never be selected for
# physical ring/stripe/follow-pin operations.
proc powerplan_get_physical_pd_list {} {
    global PD_CFG

    if {![info exists PD_CFG]} {
        error "PD_CFG is not defined. Re-source init.setup before power planning."
    }

    set result {}

    foreach pd_name [dict keys $PD_CFG] {
        set pd_groups [get_db groups -if \
            [format {.power_domain.name == "%s"} $pd_name]]

        set has_rects false
        foreach pd_group $pd_groups {
            set rects {}
            catch { set rects [get_db $pd_group .rects] }
            if {$rects ne "" && [llength $rects] > 0} {
                set has_rects true
                break
            }
        }

        if {!$has_rects} {
            puts "WARNING: Configured Power Domain '$pd_name' has no physical rectangles; skipping physical PG operations for this domain."
            continue
        }

        lappend result $pd_name
    }

    if {[llength $result] == 0} {
        error "No configured Power Domain with physical rectangles was found."
    }

    puts "INFO: Physical Power Domains used by powerplan = $result"
    return $result
}

set powerplan_physical_pd_list [powerplan_get_physical_pd_list]

# Step 2: create core rings


puts [concat $POWER_PORT_NETS $GROUND_NET]
powerplan_ring_from_cfg [concat $POWER_PORT_NETS $GROUND_NET] $POWERPLAN_CORE_RING_LOWER
powerplan_step_pause core_ring_M6_M5     "Completed the lower core ring using horizontal M6 and vertical M5."

powerplan_ring_from_cfg [concat $POWER_PORT_NETS $GROUND_NET] $POWERPLAN_CORE_RING_UPPER
powerplan_step_pause core_ring_M8_M7     "Completed the upper core ring using horizontal M8 and vertical M7."



write_db [file join $DB_DIR 02_10_core_ring.enc]

#===============================================================================================================================================================================#

# Step 3: connect pad pins

# Since pad pin locations and layers may not perfectly align with the power ring, the tool will automatically select a connection path starting from the ring, traversing intermediate layers to reach the pad pin.
# Setting {M1(1) AP(10)} allows the tool to freely choose a legal and DRC-clean routing path across multiple layers to ensure proper connectivity to the ring.
source [file join $SETUP_DIR global_net.tcl]  
set_db route_special_via_connect_to_shape { ring }
route_special -connect pad_pin \
    -layer_change_range $POWERPLAN_PAD_PIN_LAYER_CHANGE_RANGE \
    -block_pin_target nearest_target \
    -pad_pin_port_connect $POWERPLAN_PAD_PIN_PORT_CONNECT \
    -pad_pin_target {nearest_target} \
    -pad_pin_layer_range $POWERPLAN_PAD_PIN_LAYER_RANGE \
    -allow_jogging 0 \
    -crossover_via_layer_range $POWERPLAN_PAD_PIN_LAYER_CHANGE_RANGE \
    -nets [concat $POWER_PORT_NETS $GROUND_NET] \
    -allow_layer_change 1 \
    -target_via_layer_range $POWERPLAN_PAD_PIN_LAYER_CHANGE_RANGE
powerplan_step_pause pad_pin_connection     "Completed route_special from pad power pins to the core power rings."

# Create pad pin blockage
source -quiet [file join $SCRIPT_DIR create_padpin_blockage.tcl]
powerplan_step_pause pad_pin_route_blockage     "Created the temporary pad-pin [::tech_mv_library_value LIB_PIN_004] route blockage."
write_db [file join $DB_DIR 02_20_connect_pad_pin.enc]

#===============================================================================================================================================================================#

# Step 4 : create block rings

# Core/block ring example: use configured per-side width, spacing and offset.


# write_db [file join $DB_DIR 02_25_block_ring.enc]

#===============================================================================================================================================================================#

# Step 5: create power stripes



# Place routing blockage around macros
foreach cell [get_db [get_db insts -if {.base_cell.base_class == block}] .name] {
    set llx [get_db inst:$cell .bbox.ll.x]
    set lly [get_db inst:$cell .bbox.ll.y]
    set urx [get_db inst:$cell .bbox.ur.x]
    set ury [get_db inst:$cell .bbox.ur.y]
    create_route_blockage -name $POWERPLAN_MACRO_PG_BLOCKAGE_NAME -pg_nets -layers $POWERPLAN_MACRO_PG_BLOCKAGE_LAYERS -rects [list [expr {$llx-$POWERPLAN_MACRO_PG_BLOCKAGE_CLEARANCE}] $lly $llx $ury]
    create_route_blockage -name $POWERPLAN_MACRO_PG_BLOCKAGE_NAME -pg_nets -layers $POWERPLAN_MACRO_PG_BLOCKAGE_LAYERS -rects [list $urx $lly [expr {$urx+$POWERPLAN_MACRO_PG_BLOCKAGE_CLEARANCE}] $ury]
}
powerplan_step_pause macro_pg_route_blockages_for_stripe     "Created temporary M2/M3/M4 PG route blockages beside every fixed Hard Macro."

#pitch > (width + spacing)*nets


# Shared helper for a pair of Power-Domain block rings.
proc create_power_domain_block_rings {pd_name} {
    set_db add_rings_target default
    set_db add_rings_extend_over_row 0
    set_db add_rings_ignore_rows 0
    set_db add_rings_avoid_short 0
    set_db add_rings_skip_shared_inner_ring none
    set_db add_rings_stacked_via_top_layer AP
    set_db add_rings_stacked_via_bottom_layer M1
    set_db add_rings_via_using_exact_crossover_size 1
    set_db add_rings_orthogonal_only true
    set_db add_rings_skip_via_on_pin {standardcell}
    set_db add_rings_skip_via_on_wire_shape {noshape}

    set pd_net [get_pd_nets $pd_name]
    if {$pd_net eq ""} {
        error "Cannot create block ring: no power net is configured for Power Domain '$pd_name'."
    }

    select_pd_group $pd_name
    add_rings \
        -nets [concat $pd_net $::GROUND_NET] \
        -type block_rings \
        -around power_domain \
        -layer [list top [dict get $::POWERPLAN_PD_RING_UPPER h_layer] bottom [dict get $::POWERPLAN_PD_RING_UPPER h_layer] left [dict get $::POWERPLAN_PD_RING_UPPER v_layer] right [dict get $::POWERPLAN_PD_RING_UPPER v_layer]] \
        -width [list top [dict get $::POWERPLAN_PD_RING_UPPER width] bottom [dict get $::POWERPLAN_PD_RING_UPPER width] left [dict get $::POWERPLAN_PD_RING_UPPER width] right [dict get $::POWERPLAN_PD_RING_UPPER width]] \
        -spacing [list top [dict get $::POWERPLAN_PD_RING_UPPER spacing] bottom [dict get $::POWERPLAN_PD_RING_UPPER spacing] left [dict get $::POWERPLAN_PD_RING_UPPER spacing] right [dict get $::POWERPLAN_PD_RING_UPPER spacing]] \
        -offset [list top [dict get $::POWERPLAN_PD_RING_UPPER offset] bottom [dict get $::POWERPLAN_PD_RING_UPPER offset] left [dict get $::POWERPLAN_PD_RING_UPPER offset] right [dict get $::POWERPLAN_PD_RING_UPPER offset]] \
        -center 0 \
        -threshold 0 \
        -jog_distance 0 \
        -snap_wire_center_to_grid none

    powerplan_step_pause "pd_${pd_name}_block_ring_M8_M7" \
        "Completed the M8/M7 block ring around Power Domain $pd_name."

    select_pd_group $pd_name
    add_rings \
        -nets [concat $pd_net $::GROUND_NET] \
        -type block_rings \
        -around power_domain \
        -layer [list top [dict get $::POWERPLAN_PD_RING_LOWER h_layer] bottom [dict get $::POWERPLAN_PD_RING_LOWER h_layer] left [dict get $::POWERPLAN_PD_RING_LOWER v_layer] right [dict get $::POWERPLAN_PD_RING_LOWER v_layer]] \
        -width [list top [dict get $::POWERPLAN_PD_RING_LOWER width] bottom [dict get $::POWERPLAN_PD_RING_LOWER width] left [dict get $::POWERPLAN_PD_RING_LOWER width] right [dict get $::POWERPLAN_PD_RING_LOWER width]] \
        -spacing [list top [dict get $::POWERPLAN_PD_RING_LOWER spacing] bottom [dict get $::POWERPLAN_PD_RING_LOWER spacing] left [dict get $::POWERPLAN_PD_RING_LOWER spacing] right [dict get $::POWERPLAN_PD_RING_LOWER spacing]] \
        -offset [list top [dict get $::POWERPLAN_PD_RING_LOWER offset] bottom [dict get $::POWERPLAN_PD_RING_LOWER offset] left [dict get $::POWERPLAN_PD_RING_LOWER offset] right [dict get $::POWERPLAN_PD_RING_LOWER offset]] \
        -center 0 \
        -threshold 0 \
        -jog_distance 0 \
        -snap_wire_center_to_grid none

    powerplan_step_pause "pd_${pd_name}_block_ring_M6_M5" \
        "Completed the M6/M5 block ring around Power Domain $pd_name."

    deselect_obj -all
}


# Base-domain ring helper.
#
# The base Power Domain can be rectilinear after PD_cut.  Using
# "-around power_domain" would also follow enclosed cut boundaries and can
# create unwanted internal rings.  Instead, derive only the outer bbox and
# build the two configured block rings around that user-defined rectangle.
#
# This procedure is read-only with respect to Power-Domain geometry:
# it does not call PD_fill_holes or update_floorplan_obj.
proc add_ring_pd_base {pd_name} {
    set_db add_rings_target default
    set_db add_rings_extend_over_row 0
    set_db add_rings_ignore_rows 0
    set_db add_rings_avoid_short 0
    set_db add_rings_skip_shared_inner_ring none
    set_db add_rings_stacked_via_top_layer AP
    set_db add_rings_stacked_via_bottom_layer M1
    set_db add_rings_via_using_exact_crossover_size 1
    set_db add_rings_orthogonal_only true
    set_db add_rings_skip_via_on_pin {standardcell}
    set_db add_rings_skip_via_on_wire_shape {noshape}

    set pd_net [get_pd_nets $pd_name]
    if {$pd_net eq ""} {
        error "Cannot create base-domain ring: no power net is configured for Power Domain '$pd_name'."
    }

    set pd_groups [get_db groups -if \
        [format {.power_domain.name == "%s"} $pd_name]]
    if {[llength $pd_groups] != 1} {
        error "Expected exactly one physical group for base Power Domain '$pd_name', found [llength $pd_groups]: $pd_groups"
    }

    set pd_group [lindex $pd_groups 0]
    set pd_rects [get_db $pd_group .rects]
    if {$pd_rects eq "" || [llength $pd_rects] == 0} {
        error "Base Power Domain '$pd_name' has no physical rectangles."
    }

    set pd_outer_bbox [tt_pd_bbox_from_rects $pd_rects]
    if {$pd_outer_bbox eq "" || [llength $pd_outer_bbox] != 4} {
        error "Cannot derive outer bbox for base Power Domain '$pd_name': $pd_outer_bbox"
    }

    lassign $pd_outer_bbox pd_llx pd_lly pd_urx pd_ury

    # add_rings -user_defined_region expects a rectilinear polygon point list,
    # not a four-value bbox. Trace the rectangle clockwise:
    #   LL -> LR -> UR -> UL
    set pd_outer_region [list         $pd_llx $pd_lly         $pd_urx $pd_lly         $pd_urx $pd_ury         $pd_llx $pd_ury]

    puts "======================================================================"
    puts " add_ring_pd_base"
    puts "======================================================================"
    puts "Power Domain : $pd_name"
    puts "Power net    : $pd_net"
    puts "Outer bbox   : $pd_outer_bbox"
    puts "Outer region : $pd_outer_region"
    puts "Ring method  : user_defined outer rectangle"
    puts "PD geometry  : read-only"
    puts "======================================================================"

    deselect_obj -all

    add_rings \
        -nets [concat $pd_net $::GROUND_NET] \
        -type block_rings \
        -around user_defined \
        -user_defined_region $pd_outer_region \
        -rectangle 1 \
        -layer [list top [dict get $::POWERPLAN_PD_RING_UPPER h_layer] bottom [dict get $::POWERPLAN_PD_RING_UPPER h_layer] left [dict get $::POWERPLAN_PD_RING_UPPER v_layer] right [dict get $::POWERPLAN_PD_RING_UPPER v_layer]] \
        -width [list top [dict get $::POWERPLAN_PD_RING_UPPER width] bottom [dict get $::POWERPLAN_PD_RING_UPPER width] left [dict get $::POWERPLAN_PD_RING_UPPER width] right [dict get $::POWERPLAN_PD_RING_UPPER width]] \
        -spacing [list top [dict get $::POWERPLAN_PD_RING_UPPER spacing] bottom [dict get $::POWERPLAN_PD_RING_UPPER spacing] left [dict get $::POWERPLAN_PD_RING_UPPER spacing] right [dict get $::POWERPLAN_PD_RING_UPPER spacing]] \
        -offset [list top [dict get $::POWERPLAN_PD_RING_UPPER offset] bottom [dict get $::POWERPLAN_PD_RING_UPPER offset] left [dict get $::POWERPLAN_PD_RING_UPPER offset] right [dict get $::POWERPLAN_PD_RING_UPPER offset]] \
        -center 0 \
        -threshold 0 \
        -jog_distance 0 \
        -snap_wire_center_to_grid none

    powerplan_step_pause "pd_${pd_name}_base_outer_ring_M8_M7" \
        "Completed the M8/M7 base-domain ring around the user-defined outer bbox of $pd_name."

    add_rings \
        -nets [concat $pd_net $::GROUND_NET] \
        -type block_rings \
        -around user_defined \
        -user_defined_region $pd_outer_region \
        -rectangle 1 \
        -layer [list top [dict get $::POWERPLAN_PD_RING_LOWER h_layer] bottom [dict get $::POWERPLAN_PD_RING_LOWER h_layer] left [dict get $::POWERPLAN_PD_RING_LOWER v_layer] right [dict get $::POWERPLAN_PD_RING_LOWER v_layer]] \
        -width [list top [dict get $::POWERPLAN_PD_RING_LOWER width] bottom [dict get $::POWERPLAN_PD_RING_LOWER width] left [dict get $::POWERPLAN_PD_RING_LOWER width] right [dict get $::POWERPLAN_PD_RING_LOWER width]] \
        -spacing [list top [dict get $::POWERPLAN_PD_RING_LOWER spacing] bottom [dict get $::POWERPLAN_PD_RING_LOWER spacing] left [dict get $::POWERPLAN_PD_RING_LOWER spacing] right [dict get $::POWERPLAN_PD_RING_LOWER spacing]] \
        -offset [list top [dict get $::POWERPLAN_PD_RING_LOWER offset] bottom [dict get $::POWERPLAN_PD_RING_LOWER offset] left [dict get $::POWERPLAN_PD_RING_LOWER offset] right [dict get $::POWERPLAN_PD_RING_LOWER offset]] \
        -center 0 \
        -threshold 0 \
        -jog_distance 0 \
        -snap_wire_center_to_grid none

    powerplan_step_pause "pd_${pd_name}_base_outer_ring_M6_M5" \
        "Completed the M6/M5 base-domain ring around the user-defined outer bbox of $pd_name."

    deselect_obj -all

    puts "INFO: add_ring_pd_base completed for $pd_name without modifying Power-Domain geometry."
    return $pd_outer_bbox
}


# PD_TOP/base-domain ring is created from its outer bbox only.

# The old temporary fill -> ring -> restore workaround is intentionally gone.
# add_ring_pd_base reads the current cut geometry, derives only its outer bbox,
# and creates the base ring without update_floorplan_obj.
set pd_base_name $POWERPLAN_PD_TOP_RING_DOMAIN
add_ring_pd_base $pd_base_name

powerplan_step_pause "pd_${pd_base_name}_base_ring_complete" \
    "Completed base-domain block rings from the outer bbox without changing Power-Domain geometry."

# Nested/smaller Power Domains use their final cut geometry directly.
set block_ring_list $POWERPLAN_PD_BLOCK_RING_DOMAINS
foreach pd_name $block_ring_list {
    if {$pd_name eq $pd_base_name} {
        puts "INFO: Skip generic block-ring creation for base Power Domain '$pd_name'; it was already handled by add_ring_pd_base."
        continue
    }
    create_power_domain_block_rings $pd_name
}

# Durable resume checkpoint: all base/nested block rings are complete.
set pp_resume_db [file join $DB_DIR "02_25_after_block_rings.enc"]
write_db $pp_resume_db
puts "INFO: Resume DB saved: $pp_resume_db"
puts "INFO: Quick resume: pp_restore after_block_rings"

# RESUME_POINT: after_block_rings

#createPowerStripe dir layer nets                               offset  width  spacing  pitch   snap        
powerplan_stripe_from_cfg [concat $POWER_PORT_NETS $GROUND_NET] $POWERPLAN_M9_ALL_STRIPE
powerplan_step_pause global_stripe_M9_all_nets     "Completed the global vertical M9 stripe set for power and ground."

# VIA8 cleanup stage 1: clean VIA8 DRC created by the completed M9 stripe set
# before generating the lower metal stripe sets.
source -quiet [file join $::TECH_MV_RUNTIME_ROOT .. script PR TECH_MV script 05_route drc delete_VIA8_by_DRC.tcl]
powerplan_step_pause after_M9_via8_cleanup \
    "Completed the first VIA8 DRC cleanup after M9 stripe generation."

# Durable resume checkpoint: M9 stripe and first VIA8 cleanup are complete.
set pp_resume_db [file join $DB_DIR "02_26_after_M9_via8_cleanup.enc"]
write_db $pp_resume_db
puts "INFO: Resume DB saved: $pp_resume_db"
puts "INFO: Quick resume: pp_restore after_M9_via8_cleanup"

# RESUME_POINT: after_M9_via8_cleanup

powerplan_stripe_from_cfg [list $GROUND_NET] $POWERPLAN_M8_GROUND_STRIPE
powerplan_step_pause global_stripe_M8_ground     "Completed the global horizontal M8 ground stripe set."

powerplan_stripe_from_cfg $POWER_PORT_NETS $POWERPLAN_M8_POWER_STRIPE
powerplan_step_pause global_stripe_M8_power     "Completed the global horizontal M8 power stripe set."

powerplan_stripe_from_cfg [list $GROUND_NET] $POWERPLAN_M7_GROUND_STRIPE
powerplan_step_pause global_stripe_M7_ground     "Completed the global vertical M7 ground stripe set."

powerplan_stripe_from_cfg $POWER_PORT_NETS $POWERPLAN_M7_POWER_STRIPE
powerplan_step_pause global_stripe_M7_power     "Completed the global vertical M7 power stripe set."
deselect_obj -all
foreach grp $powerplan_physical_pd_list {
deselect_obj -all
select_pd_group $grp
puts "========================================"
puts ""
puts "Power Doman: $grp"
puts ""
puts "========================================"
powerplan_stripe_from_cfg [list $GROUND_NET] $POWERPLAN_M6_GROUND_STRIPE
powerplan_step_pause "pd_${grp}_stripe_M6_ground"     "Completed the horizontal M6 ground stripe set in Power Domain $grp."

powerplan_stripe_from_cfg [get_pd_nets $grp] $POWERPLAN_M6_POWER_STRIPE
powerplan_step_pause "pd_${grp}_stripe_M6_power"     "Completed the horizontal M6 power stripe set in Power Domain $grp."

# ============================================================================
# SPECIAL_WDT_M5_COMBINED_STRIPE_V1_1_SYNC_20261007
#
# PD_WDT only:
# Interactive A/B test confirmed that WDT M5 VSS can be generated when
# {VSS WDT_prim_PG.power VDD_LEVEL_02} is passed as one multi-net stripe set.
#
# IMPORTANT:
# - All non-WDT Power Domains retain the existing split M5 GND/PWR behavior.
# - Existing global M5 configuration remains unchanged.
# - WDT uses the exact combined geometry verified interactively:
#     direction V, layer M5, configured offset and stripe width,
#     configured spacing and pitch, snapped to the placement grid.
# ============================================================================
if {$grp eq "PD_WDT"} {
    set _wdt_m5_combined_nets         [lsort -unique [concat [list $GROUND_NET] [get_pd_nets $grp]]]

    set _wdt_m5_combined_cfg [dict create         direction V         layer M5         offset [::tech_mv_private_value {powerplan::wdt_m5_combined::literal_1}]         width [::tech_mv_private_value {powerplan::wdt_m5_combined::literal_2}]         spacing [::tech_mv_private_value {powerplan::wdt_m5_combined::literal_3}]         pitch [::tech_mv_private_value {powerplan::wdt_m5_combined::literal_4}]         snap grid]

    puts "========================================"
    puts " PD_WDT M5 COMBINED STRIPE"
    puts " Nets : $_wdt_m5_combined_nets"
    puts " Cfg  : $_wdt_m5_combined_cfg"
    puts "========================================"

    powerplan_stripe_from_cfg         $_wdt_m5_combined_nets         $_wdt_m5_combined_cfg

    powerplan_step_pause "pd_${grp}_stripe_M5_combined"         "Completed the combined vertical M5 ground/power stripe set in Power Domain $grp."

    unset _wdt_m5_combined_nets
    unset _wdt_m5_combined_cfg
} else {
    powerplan_stripe_from_cfg [list $GROUND_NET] $POWERPLAN_M5_GROUND_STRIPE
    powerplan_step_pause "pd_${grp}_stripe_M5_ground"         "Completed the vertical M5 ground stripe set in Power Domain $grp."

    powerplan_stripe_from_cfg [get_pd_nets $grp] $POWERPLAN_M5_POWER_STRIPE
    powerplan_step_pause "pd_${grp}_stripe_M5_power"         "Completed the vertical M5 power stripe set in Power Domain $grp."
}
deselect_obj -all
}

# ================================================================================================================
# Phase A COMPLETE: ALL STRIPES HAVE BEEN GENERATED
#   - Global M9
#   - Global M8
#   - Global M7
#   - All Power-Domain M6
#   - All Power-Domain M5
#
# No floating-stripe SRoute is executed inside createPowerStripe.
# Floating-stripe completion starts only after this checkpoint.
# ================================================================================================================
deselect_obj -all
# TT_FPVIA_STRIPE_PAUSE_PENDING
powerplan_step_pause all_stripes_complete_before_floating     "All M9/M8/M7/M6/M5 stripe generation is complete. Floating-stripe SRoute has not started yet. Follow-pin [::tech_mv_library_value LIB_PIN_005] check: PENDING because follow-pin [::tech_mv_library_value LIB_PIN_006] runs later in Step 6."

# Durable resume checkpoint: all stripe geometry exists; floating SRoute has
# not started yet.
set pp_resume_db [file join $DB_DIR "02_27_after_all_stripes.enc"]
write_db $pp_resume_db
puts "INFO: Resume DB saved: $pp_resume_db"
puts "INFO: Quick resume: pp_restore after_all_stripes"

# RESUME_POINT: after_all_stripes

# ================================================================================================================
# Phase B: FLOATING STRIPE SROUTE
# ================================================================================================================
# Complete floating M5/M6 stripes only after every stripe set
# has been generated.
#
# IMPORTANT:
#   - Do NOT use -power_domain for this SRoute pass.
#   - Collect all PG nets once and remove duplicates.
#   - Run only one M6 pass and one M5 pass.
#   - Floating-stripe targets remain restricted to ring objects in
#     connectFloatingPowerStripe.
set floating_sroute_nets [list]

foreach grp $powerplan_physical_pd_list {

    if {$grp eq ""} {
        continue
    }

    set pd_power_net [get_pd_nets $grp]

    if {$pd_power_net eq ""} {
        continue
    }

    set floating_sroute_nets [concat $floating_sroute_nets $pd_power_net]
}

set floating_sroute_nets \
    [lsort -unique [concat $GROUND_NET $floating_sroute_nets]]

puts "========================================"
puts "Global Floating Stripe SRoute"
puts "Nets : $floating_sroute_nets"
puts "========================================"

connectFloatingPowerStripe M6 $floating_sroute_nets
powerplan_step_pause floating_stripe_M6_to_ring \
    "Completed the global M6 floating-stripe SRoute to PG rings."

connectFloatingPowerStripe M5 $floating_sroute_nets
powerplan_step_pause floating_stripe_M5_to_ring \
    "Completed the global M5 floating-stripe SRoute to PG rings."

powerplan_step_pause all_floating_stripes_complete     "Completed all global floating-stripe SRoute passes. Proceeding to stripe cleanup, via repair and DRC."

# Durable resume checkpoint: M5/M6 floating-stripe SRoute is complete; cleanup,
# via repair and DRC have not started yet.
set pp_resume_db [file join $DB_DIR "02_33_after_floating_sroute.enc"]
write_db $pp_resume_db
puts "INFO: Resume DB saved: $pp_resume_db"
puts "INFO: Quick resume: pp_restore after_floating_sroute"

# RESUME_POINT: after_floating_sroute

delete_obj [get_db route_blockages {RBKM234}]
delete_obj [get_db route_blockages RBKPADPIN]
powerplan_step_pause stripe_temporary_blockage_cleanup     "Deleted the temporary macro and pad-pin [::tech_mv_library_value LIB_PIN_007] blockages after stripe creation."

# The execution order is critical for fix_via
tech_mv_native_report_command 02 via_repair [list fix_via -short]
tech_mv_native_report_command 02 via_repair [list fix_via -min_step]
tech_mv_native_report_command 02 via_repair [list fix_via -min_cut]
tech_mv_native_report_command 02 via_repair [list fix_via -short]
tech_mv_native_report_command 02 via_repair [list fix_via -min_step]
tech_mv_native_report_command 02 via_repair [list fix_via -min_cut]
powerplan_step_pause stripe_via_repair     "Completed short, minimum-step and minimum-cut via repair after stripe creation."

# Durable resume checkpoint: stripe cleanup and via repair are complete; the
# interactive after_power_stripe DRC checkpoint has not run yet.
set pp_resume_db [file join $DB_DIR "02_34_before_power_stripe_drc.enc"]
write_db $pp_resume_db
puts "INFO: Resume DB saved: $pp_resume_db"
puts "INFO: Quick resume: pp_restore before_power_stripe_drc"

# RESUME_POINT: before_power_stripe_drc

# VIA8 cleanup stage 2: after all floating-stripe SRoute and fix_via work is
# complete, clean any VIA8 DRC that was created or reintroduced by the later
# power-plan operations before the official after_power_stripe DRC checkpoint.
source -quiet [file join $::TECH_MV_RUNTIME_ROOT .. script PR TECH_MV script 05_route drc delete_VIA8_by_DRC.tcl]
powerplan_step_pause after_power_stripe_via8_cleanup \
    "Completed the second VIA8 DRC cleanup before the after_power_stripe DRC checkpoint."

# Durable resume checkpoint: second VIA8 cleanup is complete; official DRC has
# not started yet.
set pp_resume_db [file join $DB_DIR "02_34_after_power_stripe_via8_cleanup.enc"]
write_db $pp_resume_db
puts "INFO: Resume DB saved: $pp_resume_db"
puts "INFO: Quick resume: pp_restore after_power_stripe_via8_cleanup"


# EndCap and WellTap cells were inserted during 01_floorplan after the
# Power-Domain geometry and Hard Macros were finalized.  Do not insert them
# again here; the following core-pin route will connect their PG pins.
powerplan_check_drc after_power_stripe
# RESUME_POINT_DRC: after_power_stripe_post_check
powerplan_step_pause after_power_stripe_drc     "Completed the DRC checkpoint after block rings and all stripe sets."

# Durable resume checkpoint.
# Safe meaning: all rings, stripes, floating-stripe SRoute, via repair and
# after_power_stripe DRC are already complete.
set pp_resume_db [file join $DB_DIR "02_35_after_power_stripe_drc.enc"]
write_db $pp_resume_db
puts "INFO: Resume DB saved: $pp_resume_db"
puts "INFO: Quick resume:"
puts "INFO:   source init.setup"
puts "INFO:   source [file join \$TOOL_DIR 02_powerplan TT_proc_powerplan_resume.tcl]"
puts "INFO:   pp_restore after_power_stripe_drc"

# RESUME_POINT: after_power_stripe_drc
source -quiet [file join $SCRIPT_DIR create_padpin_blockage.tcl]
powerplan_step_pause follow_pin_pad_blockage     "Recreated the pad-pin [::tech_mv_library_value LIB_PIN_007] blockage before follow-pin routing."
write_db [file join $DB_DIR 02_30_power_stripe.enc]

#===============================================================================================================================================================================#

# Step 6: connect follow pin

# Enabling route_special -connect core_pin allows stripes to connect to standard cell power pins.
# This is necessary if you want to re-execute this step because the tool only auto-detects connection points when cells are unplaced.
# set_db [get_db insts -if {.base_cell.class == core}] .place_status unplaced

# It permits the tool to trace upward from cell pins to find and connect to the power ring or stripes
set_db route_special_via_connect_to_shape { stripe }

# This is the actual step that connects the cell's VDD/VSS pins to the power distribution network.
# ============================================================
# Run route_special for each power domain
# ============================================================
source -quiet [file join $SCRIPT_DIR create_padpin_blockage.tcl]
foreach cell [get_db [get_db insts -if {.base_cell.base_class == block}] .name] {
    set llx [get_db inst:$cell .bbox.ll.x]
    set lly [get_db inst:$cell .bbox.ll.y]
    set urx [get_db inst:$cell .bbox.ur.x]
    set ury [get_db inst:$cell .bbox.ur.y]
    create_route_blockage -name $POWERPLAN_MACRO_PG_BLOCKAGE_NAME -pg_nets -layers $POWERPLAN_MACRO_PG_BLOCKAGE_LAYERS -rects [list [expr {$llx-$POWERPLAN_MACRO_PG_BLOCKAGE_CLEARANCE}] $lly $llx $ury]
    create_route_blockage -name $POWERPLAN_MACRO_PG_BLOCKAGE_NAME -pg_nets -layers $POWERPLAN_MACRO_PG_BLOCKAGE_LAYERS -rects [list $urx $lly [expr {$urx+$POWERPLAN_MACRO_PG_BLOCKAGE_CLEARANCE}] $ury]
}
powerplan_step_pause follow_pin_macro_route_blockages     "Created temporary M2/M3/M4 blockages beside Hard Macros for follow-pin routing."

foreach grp $powerplan_physical_pd_list {

    # skip empty power domain name
    if {$grp eq ""} {
        continue
    }

    set nets [get_pd_rail $grp]

    # skip if no config
    if {$nets eq ""} {
        continue
    }

    puts "========================================"
    puts "Power Domain: $grp"
    puts "Nets        : $nets"
    puts "========================================"
    set_db route_special_via_connect_to_shape { stripe }
    route_special \
        -connect core_pin \
        -layer_change_range $POWERPLAN_FOLLOW_PIN_LAYER_CHANGE_RANGE \
        -block_pin_target nearest_target \
        -core_pin_target $POWERPLAN_FOLLOW_PIN_TARGET \
        -allow_jogging 0 \
        -core_pin_layer $POWERPLAN_FOLLOW_PIN_CORE_PIN_LAYER \
        -crossover_via_layer_range $POWERPLAN_FOLLOW_PIN_LAYER_CHANGE_RANGE \
        -nets $nets \
        -allow_layer_change 1 \
        -target_via_layer_range $POWERPLAN_FOLLOW_PIN_LAYER_CHANGE_RANGE \
        -power_domain $grp

    if {$grp eq [lindex $powerplan_physical_pd_list end] && $::ENABLE_POST_POWERPLAN_FOLLOWPIN_CLEANUP} {
        source -quiet [file join $::TECH_MV_RUNTIME_ROOT .. script PR TECH_MV script 02_powerplan delete_followpin_outside_pd_boundary.tcl]
        set _tech_fp_pre [TT_delete_followpin_outside_pd_boundary -dry_run 1]
        foreach _tech_fp_key {bad_bbox bad_orient unresolved_naming} {
            if {[dict get $_tech_fp_pre $_tech_fp_key] != 0} {
                error "FollowPin V5.1 precheck failed: $_tech_fp_key=[dict get $_tech_fp_pre $_tech_fp_key]."
            }
        }
        set _tech_fp_safe [dict get $_tech_fp_pre safe_unique]
        if {$_tech_fp_safe > 0} {
            set _tech_fp_del [TT_delete_followpin_outside_pd_boundary -dry_run 0 -confirm DELETE_DIRECTIONAL_ENDCAP_STUBS]
            if {[dict get $_tech_fp_del delete_fail] != 0 || [dict get $_tech_fp_del deleted] != $_tech_fp_safe} {
                error "FollowPin V5.1 delete mismatch: expected=$_tech_fp_safe deleted=[dict get $_tech_fp_del deleted] failed=[dict get $_tech_fp_del delete_fail]."
            }
            set _tech_fp_post [TT_delete_followpin_outside_pd_boundary -dry_run 1]
            if {[dict get $_tech_fp_post safe_unique] != 0} {
                error "FollowPin V5.1 postcheck failed: residual safe_unique=[dict get $_tech_fp_post safe_unique]."
            }
            unset _tech_fp_del
            unset _tech_fp_post
        }
        unset _tech_fp_safe
        unset _tech_fp_pre
        unset _tech_fp_key
    }

    # ==================================================================
    # TT_POST_FOLLOWPIN_VIA_DRC_REPAIR_V1_0
    #
    # Run exactly once: after the LAST physical Power Domain finishes
    # follow-pin routing/cleanup, but BEFORE the existing final-PD pause.
    #
    # Sequence:
    #   fresh check_drc
    #   -> TT_via_drc_fix preview
    #   -> conditional TT_via_drc_fix apply
    #   -> fresh check_drc after deletion
    #   -> existing pd_<finalPD>_follow_pin_route pause
    #
    # The strict FollowPin special-VIA integrity checker below the loop
    # remains untouched and runs after the user resumes from this pause.
    # ==================================================================
    if {$grp eq [lindex $powerplan_physical_pd_list end]} {
        set _tt_via_drc_tool [file join $TOOL_DIR 05_route drc TT_DRC_fix_via.tcl]

        if {![file isfile $_tt_via_drc_tool]} {
            error "POST-FOLLOWPIN VIA DRC repair tool not found: $_tt_via_drc_tool"
        }

        puts ""
        puts "======================================================================"
        puts " POST-FOLLOWPIN VIA DRC REPAIR"
        puts "======================================================================"
        puts "Tool : $_tt_via_drc_tool"
        puts "Point: before final PD followpin pause"
        puts "======================================================================"

        # Source-safe: this file only defines the repair procedures.
        source -quiet $_tt_via_drc_tool

        if {[llength [info commands TT_via_drc_fix]] == 0} {
            error "POST-FOLLOWPIN VIA DRC repair: TT_via_drc_fix was not defined."
        }

        # Use only a fresh DRC marker set created after all FollowPin geometry.
        catch {delete_drc_markers}
        if {[info exists POWERPLAN_DRC_LIMIT]} {
            set_db check_drc_limit $POWERPLAN_DRC_LIMIT
        }

        puts "INFO: POST-FOLLOWPIN VIA DRC: generating fresh DRC markers..."
        tech_mv_check_drc
        TT_via_drc_stats

        set _tt_via_preview_count [TT_via_drc_fix preview]

        if {$_tt_via_preview_count > 0} {
            puts "INFO: POST-FOLLOWPIN VIA DRC: preview found $_tt_via_preview_count safe delete candidate(s)."
            puts "INFO: POST-FOLLOWPIN VIA DRC: applying repair..."

            set _tt_via_deleted_count [TT_via_drc_fix apply]

            if {$_tt_via_deleted_count != $_tt_via_preview_count} {
                error "POST-FOLLOWPIN VIA DRC repair mismatch: preview=$_tt_via_preview_count deleted=$_tt_via_deleted_count"
            }

            catch {delete_drc_markers}
            puts "INFO: POST-FOLLOWPIN VIA DRC: refreshing DRC markers after repair..."
            tech_mv_check_drc
            TT_via_drc_stats

            puts "INFO: POST-FOLLOWPIN VIA DRC: deleted $_tt_via_deleted_count special VIA object(s)."
            unset _tt_via_deleted_count
        } else {
            puts "INFO: POST-FOLLOWPIN VIA DRC: no safe overlapping special-VIA delete candidate."
        }

        puts "INFO: POST-FOLLOWPIN VIA DRC REPAIR COMPLETE"
        puts "INFO: Existing final-PD followpin pause is next."
        puts "======================================================================"
        puts ""

        unset _tt_via_preview_count
        unset _tt_via_drc_tool
    }

    powerplan_step_pause "pd_${grp}_follow_pin_route"         "Completed route_special core-pin [::tech_mv_library_value LIB_PIN_004] connection for Power Domain $grp."
}

# ======================================================================
# TT_FPVIA_POST_FOLLOWPIN_STRICT_CHECK
#
# All Power-Domain follow-pin route_special passes are complete here.
# Check that every followpin special_wire owns at least one physically
# overlapping, same-net, shape=followpin special_via.
#
# On failure:
#   - violations are written to report
#   - violating followpin special_wire objects are selected/highlighted
#   - native suspend allows inspection before cleanup/fix_via/check_drc
#   - resume accepts the checkpoint without claiming violations were fixed
# ======================================================================
set _tt_fpvia_tool ""
if {[info exists TOOL_DIR] && $TOOL_DIR ne ""} {
    set _tt_fpvia_tool [file join $TOOL_DIR 02_powerplan TT_check_followpin_special_via.tcl]
}
if {$_tt_fpvia_tool eq "" || ![file exists $_tt_fpvia_tool]} {
    set _tt_fpvia_tool         [file normalize [file join $SCRIPT_DIR .. run tool 02_powerplan TT_check_followpin_special_via.tcl]]
}
if {![file exists $_tt_fpvia_tool]} {
    error "FOLLOWPIN VIA checker not found: $_tt_fpvia_tool"
}

puts ""
puts "======================================================================"
puts " POST-FOLLOWPIN SPECIAL-VIA INTEGRITY CHECK"
puts "======================================================================"
puts "Tool : $_tt_fpvia_tool"

source $_tt_fpvia_tool

set _tt_fpvia_report [file join reports 02_powerplan TT_followpin_without_special_via.rpt]
set _tt_fpvia_result [TT_FOLLOWPIN_VIA_CHECK -highlight 1 -report $_tt_fpvia_report]
if {$_tt_fpvia_result == 0} {
    puts "INFO: POST-FOLLOWPIN SPECIAL-VIA INTEGRITY CHECK PASS"
} else {
    puts "WARNING: POST-FOLLOWPIN CHECKPOINT ACCEPTED; recorded violations=$_tt_fpvia_result (not rechecked)."
}
unset _tt_fpvia_result
puts "INFO: report = $_tt_fpvia_report"
puts "======================================================================"

unset _tt_fpvia_tool
unset _tt_fpvia_report


# delete halo
delete_obj [get_db route_blockages {RBKM234}]
delete_obj [get_db route_blockages RBKPADPIN]
powerplan_step_pause follow_pin_temporary_blockage_cleanup     "Deleted the temporary macro and pad-pin [::tech_mv_library_value LIB_PIN_009] after follow-pin routing."

tech_mv_native_report_command 02 via_repair [list fix_via -short]
tech_mv_native_report_command 02 via_repair [list fix_via -min_step]
tech_mv_native_report_command 02 via_repair [list fix_via -min_cut]
powerplan_step_pause follow_pin_via_repair     "Completed via repair after follow-pin [::tech_mv_library_value LIB_PIN_004] routing."

# Existing technology-specific ring-overlap repair; user-authorized M7 scope.
if {$ENABLE_FOLLOW_PIN_RING_OVERLAP_REPAIR} {
    set _tt_ring_pre_db [file join $DB_DIR "02_44_before_ring_overlap_[clock clicks].enc"]
    write_db $_tt_ring_pre_db
    if {![file exists $_tt_ring_pre_db]} { error "Ring-overlap repair checkpoint was not created; repair aborted." }
    source -quiet [file join $TOOL_DIR 05_route drc TT_tool_remove_ring_overlap_metal.tcl]
    TT_tool_remove_ring_overlap_metal -layers $FOLLOW_PIN_RING_OVERLAP_REPAIR_LAYERS -dry_run 0
    unset _tt_ring_pre_db
}

powerplan_check_drc after_follow_pin
# RESUME_POINT_DRC: after_follow_pin_post_check
powerplan_step_pause after_follow_pin_drc     "Completed the DRC checkpoint after follow-pin [::tech_mv_library_value LIB_PIN_004] routing."

# Durable resume checkpoint.
# Safe meaning: Follow Pin routing, follow-pin via repair and its DRC are done.
set pp_resume_db [file join $DB_DIR "02_45_after_follow_pin_drc.enc"]
write_db $pp_resume_db
puts "INFO: Resume DB saved: $pp_resume_db"
puts "INFO: Quick resume: pp_restore after_follow_pin_drc"

# RESUME_POINT: after_follow_pin_drc
# Add power mesh.tcl
tech_mv_native_report_command 02 power_color [list add_power_mesh_colors]
powerplan_step_pause power_mesh_colorization     "Applied power-mesh colors."

create_pg_model_for_macro_place -file [tech_mv_output_path temp golden_mimic_power_mesh.tcl 02 macro_model]
powerplan_step_pause macro_place_pg_model     "Generated PG model under .temp/02_powerplan/macro_model for macro placement."

write_db [file join $DB_DIR 02_40_connect_follow_pin.enc]

#===============================================================================================================================================================================#

# Step 7: check DRC

# Keep the original two DRC checkpoints around the final via repair.
powerplan_check_drc before_final_via_repair
# RESUME_POINT_DRC: before_final_via_repair_post_check
powerplan_step_pause before_final_via_repair_drc     "Completed the DRC checkpoint immediately before final minimum-step via repair."

# Durable resume checkpoint.
set pp_resume_db [file join $DB_DIR "02_70_before_final_via_repair_drc.enc"]
write_db $pp_resume_db
puts "INFO: Resume DB saved: $pp_resume_db"
puts "INFO: Quick resume: pp_restore before_final_via_repair_drc"

# RESUME_POINT: before_final_via_repair_drc
tech_mv_native_report_command 02 via_repair [list fix_via -min_step]
powerplan_step_pause final_min_step_via_repair     "Completed the final minimum-step via repair."

# Check again after the final via repair.
powerplan_check_drc after_final_via_repair
# RESUME_POINT_DRC: after_final_via_repair_post_check
powerplan_step_pause after_final_via_repair_drc     "Completed the final DRC checkpoint in script/powerplan.tcl."

# Durable resume checkpoint.
set pp_resume_db [file join $DB_DIR "02_80_after_final_via_repair_drc.enc"]
write_db $pp_resume_db
puts "INFO: Resume DB saved: $pp_resume_db"
puts "INFO: Quick resume: pp_restore after_final_via_repair_drc"

# RESUME_POINT: after_final_via_repair_drc
write_db [file join $DB_DIR 02_90_powerplan_mesh.enc]
powerplan_step_pause legacy_powerplan_database_written     "Saved 02_90_powerplan_mesh.enc after the legacy powerplan flow."
