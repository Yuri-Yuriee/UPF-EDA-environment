# Load definitions only; no APR action or setup reload is performed here.
if {![llength [info commands ::tech_mv_library_value]]} {
    if {[info exists ::TOOL_DIR]} {
        source -quiet [file join $::TECH_MV_RUNTIME_ROOT .. script PR TECH_MV script 00_common private_parameter_config.tcl]
    } else {
        source -quiet [file join $::TECH_MV_RUNTIME_ROOT .. script PR TECH_MV script 00_common private_parameter_config.tcl]
    }
}
# =============================================================================
# TECH Bond-Pad Implementation
# =============================================================================
# TECH uses FILL_IN_CELL_BOND_PAD_041 bond pads for a wire-bond package interface.
# It does NOT use the REFERENCE_PLATFORM flip-chip bump-array architecture.
#
# The original TECH Cadence helper exposes FILL_IN_CELL_BOND_PAD_041 through some Innovus API/root
# names that contain the word "bump". These API names are preserved because
# they are present in the real TECH reference flow. They describe the database
# interface used by Innovus, not the package architecture.
# =============================================================================

#This script is for Innovus stylus UI 

foreach _bond_cfg_var {
    BOND_PAD_CELL
    BOND_PAD_TOP_LAYER
    BOND_PAD_DEFAULT_PIN
    BOND_PAD_PIN_MAP
    BOND_PAD_RIGHT_DOWN
    BOND_PAD_TOP_RIGHT
    BOND_PAD_LEFT_UP
    BOND_PAD_BOTTOM_LEFT
    BOND_PAD_RDL_WIDTH
    BOND_PAD_RDL_SPACING
    BOND_PAD_GAP
    BOND_PAD_CHIP_BOUNDARY_LAYER
    BOND_PAD_CHIP_BOUNDARY_VERTICAL_EXTEND
    BOND_PAD_CHIP_BOUNDARY_HORIZONTAL_EXTEND
    RTE_PAD_SUPPLY_NETS
    RTE_PAD_TEMPLATE_INSTANCE
    RTE_PAD_INSTANCE_PREFIX
    RTE_PAD_PIN
    RTE_PAD_BOND_ASSIGN_ENABLE
    RTE_PAD_BOND_ASSIGN_SUPPLIES
} {
    if {![info exists ::$_bond_cfg_var]} {
        error "Missing bonding-pad config '$_bond_cfg_var'. Source init.setup first."
    }
}
unset _bond_cfg_var

# Reuse the Floorplan-selected inner/outer start parity when available.
# This generated file is written only after a zero-overlap floorplan preview.
if {[info exists ::BOND_PAD_PARITY_FILE] && [file isfile $::BOND_PAD_PARITY_FILE]} {
    puts "INFO: Loading generated bond-pad parity: $::BOND_PAD_PARITY_FILE"
    source $::BOND_PAD_PARITY_FILE
}

namespace eval libvar {
    set rightpad_down  $::BOND_PAD_RIGHT_DOWN
    set toppad_right   $::BOND_PAD_TOP_RIGHT
    set leftpad_up     $::BOND_PAD_LEFT_UP
    set bottompad_left $::BOND_PAD_BOTTOM_LEFT

    array unset bond_pad_pin
    dict for {cell pins} $::BOND_PAD_PIN_MAP {
        set bond_pad_pin($cell) $pins
    }

    set default_bond_pad_pin $::BOND_PAD_DEFAULT_PIN
    set bond_pad_cell       $::BOND_PAD_CELL
}


proc tech_mv_check_bond_pad_collateral {} {
    if {[llength [get_db base_cells $::BOND_PAD_CELL]] == 0} {
        error "Bond-pad base cell '$::BOND_PAD_CELL' is not loaded. Check FILL_IN_LIBRARY_0174."
    }
    if {[llength [get_db layers $::BOND_PAD_TOP_LAYER]] == 0} {
        error "Bond-pad top layer '$::BOND_PAD_TOP_LAYER' is not loaded."
    }
}

proc set_route_var {} {
    set pin_top_layer [get_db layer:[expr [get_db layer:$::BOND_PAD_TOP_LAYER .route_index ] -1] .name]
    set_db edit_wire_type special
    set_db edit_wire_layer_min {$pin_top_layer}
    set_db edit_wire_layer_max $::BOND_PAD_TOP_LAYER
    set_db edit_wire_shape {iowire}
    set_db edit_wire_layer_vertical $::BOND_PAD_TOP_LAYER
    set_db edit_wire_layer_horizontal $::BOND_PAD_TOP_LAYER
    set_db edit_wire_create_crossover_vias {0}
    set_db edit_wire_create_via_on_pin {1}
    set_db edit_wire_allow_45_degree {1}
    set_db edit_wire_width_horizontal $::BOND_PAD_RDL_WIDTH
    set_db edit_wire_width_vertical $::BOND_PAD_RDL_WIDTH
    set_db edit_wire_spacing_horizontal $::BOND_PAD_RDL_SPACING
    set_db edit_wire_spacing_vertical $::BOND_PAD_RDL_SPACING
    set_db edit_wire_drc_on {0}
    set_db edit_wire_sub_class {manual_rdl}
    set_db edit_wire_via_rows {0}
    set_db edit_wire_via_columns {0}
}

proc comparex {a b} {
    set ax [lindex [lindex $a 0] 1]
    set bx [lindex [lindex $b 0] 1]
    if {$ax < $bx} {
        return -1
    } else {
        return 1
    }
}

proc comparey {a b} {
    set ay [lindex [lindex $a 0] 2]
    set by [lindex [lindex $b 0] 2]
    if {$ay < $by} {
        return -1
    } else {
        return 1
    }
}


proc run_bond_pad_and_route {bond_pad_cx bond_pad_cy pin_llx pin_lly pin_urx pin_ury bond_pad_name port_name orient} {
    #puts "bcx bcy $bond_pad_cx $bond_pad_cy $bond_pad_name $port_name"
    if {[llength [get_db bumps $bond_pad_name]]} {
        set bond_pad_format "${bond_pad_name}_%i"
    } else {
        set bond_pad_format ${bond_pad_name}
    }
    set bond_pad_get [create_bump -orient $orient -location "$bond_pad_cx $bond_pad_cy"  -name_format $bond_pad_format -cell $::libvar::bond_pad_cell -return_bumps_name]
    if {[llength [get_db bumps $bond_pad_get]] == 0} {
        set bond_pad_get  [create_bump -orient $orient -location "$bond_pad_cx $bond_pad_cy"  -name_format $bond_pad_format -cell $::libvar::bond_pad_cell -allow_overlap_control keep_all -return_bumps_name]
        if {[llength [get_db bumps $bond_pad_get]]} {
            lappend ::libvar::overlap_bond_pads "$bond_pad_get ($bond_pad_cx $bond_pad_cy)"
        }
    }
    if {[info exists ::BOND_PAD_PREVIEW_ONLY] && $::BOND_PAD_PREVIEW_ONLY} {
        return $bond_pad_get
    }

    if {[llength [get_db nets $port_name]]} {
        assign_pg_bumps -bumps $bond_pad_get -nets $port_name
        set_db edit_wire_nets $port_name
        set_db edit_wire_width_horizontal [expr $pin_ury - $pin_lly]
        set_db edit_wire_width_vertical [expr $pin_urx - $pin_llx]
        edit_add_route_point [expr ($pin_llx + $pin_urx)/2] [expr ($pin_lly + $pin_ury)/2]
        edit_end_route_point $bond_pad_cx $bond_pad_cy
        set pin_top_layer [get_db layer:[expr [get_db layer:$::BOND_PAD_TOP_LAYER .route_index ] -1] .name]
        update_power_vias -skip_via_on_pin standardcell -bottom_layer $pin_top_layer -area "$pin_llx $pin_lly $pin_urx $pin_ury"  -add_vias 1 -top_layer $::BOND_PAD_TOP_LAYER -user_class manual_rdl
    } else {
        puts "Failed create bump $bond_pad_name at $bond_pad_cx $bond_pad_cy"
    }
}

proc delete_bond_pad_and_route {{preview_only false}} {
    set_message -id IMPSIP-7513 -suppress

    # Delete only FILL_IN_CELL_BOND_PAD_041 bond-pad objects.  Never use delete_bumps -all because
    # other package-interface objects can also appear under the bump DB root.
    set bond_names {}
    foreach bump_obj [get_db bumps] {
        set cell_name ""
        catch { set cell_name [get_db $bump_obj .base_cell.name] }
        if {$cell_name eq $::BOND_PAD_CELL} {
            set bump_name ""
            catch { set bump_name [get_db $bump_obj .name] }
            if {$bump_name ne ""} { lappend bond_names $bump_name }
        }
    }

    foreach bump_name $bond_names {
        set target ""
        foreach bump_obj [get_db bumps] {
            set name ""
            set cell_name ""
            catch { set name [get_db $bump_obj .name] }
            catch { set cell_name [get_db $bump_obj .base_cell.name] }
            if {$name eq $bump_name && $cell_name eq $::BOND_PAD_CELL} {
                set target $bump_obj
                break
            }
        }
        if {$target eq ""} { continue }

        deselect_obj -all
        select_obj $target
        # Assigned final bond pads must be unassigned before deletion.  Temporary
        # preview FILL_IN_CELL_BOND_PAD_041 objects are never assigned, so skip the very noisy
        # per-pad unassign_bumps call during preview cleanup.
        if {!$preview_only} {
            catch { unassign_bumps -selected }
        }
        deselect_obj -all

        # Re-find after unassign because the DB/selection state may change.
        set target ""
        foreach bump_obj [get_db bumps] {
            set name ""
            set cell_name ""
            catch { set name [get_db $bump_obj .name] }
            catch { set cell_name [get_db $bump_obj .base_cell.name] }
            if {$name eq $bump_name && $cell_name eq $::BOND_PAD_CELL} {
                set target $bump_obj
                break
            }
        }
        if {$target ne ""} {
            select_obj $target
            delete_bumps -selected
            deselect_obj -all
        }
    }

    delete_routes -shapes iowire -sub_class manual_rdl
    gui_redraw
}

proc tech_mv_bond_rte_safe_token {name} {
    set safe $name
    regsub -all {[^A-Za-z0-9_]+} $safe {_} safe
    return [string trim $safe _]
}

proc tech_mv_bond_find_inst_by_local_name {local_name} {
    set patterns [list $local_name "*/$local_name"]
    if {[info exists ::TOP_MODULE]} {
        set patterns [linsert $patterns 1 "${::TOP_MODULE}/$local_name"]
    }

    foreach pattern $patterns {
        if {![catch {set matches [get_db insts $pattern]}] &&
            [llength $matches] > 0} {
            return [lindex $matches 0]
        }
    }
    return ""
}

proc tech_mv_bond_rte_pad_name_for_supply {supply index} {
    if {$index == 0} {
        return $::RTE_PAD_TEMPLATE_INSTANCE
    }
    return "${::RTE_PAD_INSTANCE_PREFIX}_[tech_mv_bond_rte_safe_token $supply]"
}

proc tech_mv_append_explicit_rte_bond_targets {target_list_var} {
    upvar 1 $target_list_var all_targetpadpins

    if {!$::RTE_PAD_BOND_ASSIGN_ENABLE} {
        puts "INFO: Explicit RTE bond-pad assignment is disabled."
        return
    }

    set configured $::RTE_PAD_SUPPLY_NETS
    set selected   $::RTE_PAD_BOND_ASSIGN_SUPPLIES

    foreach supply $selected {
        if {[lsearch -exact $configured $supply] < 0} {
            error "RTE_PAD_BOND_ASSIGN_SUPPLIES contains unknown supply '$supply'"
        }
    }

    set index 0
    foreach supply $configured {
        if {[lsearch -exact $selected $supply] >= 0} {
            set inst_name [tech_mv_bond_rte_pad_name_for_supply $supply $index]
            set inst_obj [tech_mv_bond_find_inst_by_local_name $inst_name]

            # If existing RTE-pad capacity was already sufficient,
            # create_rte_pad.tcl intentionally did not create the expected
            # auto pad for this supply.  That is not an error: only genuinely
            # auto-created RTE pads need this extra FILL_IN_CELL_BOND_PAD_041 -> RTE assignment.
            if {$inst_obj eq ""} {
                puts "INFO: Skip explicit RTE bond-pad target for supply=$supply; no auto-created pad '$inst_name' exists (existing RTE capacity was reused)."
            } else {
                if {[llength [get_db $inst_obj .pins -if {.base_name == $::RTE_PAD_PIN}]] == 0 &&
                    [llength [get_db $inst_obj .pg_pins -if {.base_name == $::RTE_PAD_PIN}]] == 0} {
                    error "RTE bond-pad target '$inst_name' has no pin '$::RTE_PAD_PIN'"
                }

                lappend all_targetpadpins [list $inst_obj $::RTE_PAD_PIN]
                puts "INFO: Add explicit RTE bond-pad target: supply=$supply inst=$inst_name pin=$::RTE_PAD_PIN"
            }
        }
        incr index
    }
}

proc create_bond_pad_and_route {} {
    tech_mv_check_bond_pad_collateral
    set all_pads [get_db insts -if [::tech_mv_library_value LIB_QUERY_002]]
    
    #set_library_var
    set pin_top_layer [get_db layer:[expr [get_db layer:$::BOND_PAD_TOP_LAYER .route_index ] -1] .name]
    set BUMP_h [get_db base_cell:$::libvar::bond_pad_cell .bbox.ur.y]
    set BUMP_w [get_db base_cell:$::libvar::bond_pad_cell .bbox.ur.x] 
    set BOND_PAD_halfh [expr ($BUMP_h+1)/2]
    
    # suppress warning of delete bump
    set_message -id IMPSIP-7513 -suppress
    
    # suppress warning of out of die boundary
    set_message -id IMPSIP-9024 -suppress
    set_message -id IMPSIP-9016 -suppress
    
    # Recreate only the FILL_IN_CELL_BOND_PAD_041/manual-RDL layer; preserve non-FILL_IN_CELL_BOND_PAD_041 objects.
    set _tech_preview_cleanup [expr {[info exists ::BOND_PAD_PREVIEW_ONLY] && $::BOND_PAD_PREVIEW_ONLY}]
    delete_bond_pad_and_route $_tech_preview_cleanup
    unset _tech_preview_cleanup
    delete_obj [get_db route_blockages BondPadBlk]
    delete_obj [get_db gui_texts -if {.gui_layer_name == CUSTOM_TEXT}]
    if {![info exists ::BOND_PAD_PREVIEW_ONLY] || !$::BOND_PAD_PREVIEW_ONLY} {
        set_route_var
    }
    
    set right_pins {}
    set left_pins {}
    set top_pins {}
    set bottom_pins {}
    set all_targetpadpins {}
    foreach pad $all_pads {
        set base_cell_name [ get_db $pad .base_cell.name ] 
        set base_cell_nvh [regsub "_V$|_H$" $base_cell_name ""]
        if {[info exists  ::libvar::bond_pad_pin($base_cell_nvh)]} {   
            foreach padpin $::libvar::bond_pad_pin($base_cell_nvh) {
                lappend all_targetpadpins "$pad $padpin"
            }
        } else {
            lappend all_targetpadpins "$pad $::libvar::default_bond_pad_pin"
        }
    }

    # RTE pads remain excluded from FILL_IN_CELL_BOND_PAD_041 bond-pad targets.

    foreach targetpadpin $all_targetpadpins {
        lassign  $targetpadpin pad padpin
        set base_cell_name [ get_db $pad .base_cell.name ] 
        set base_cell_nvh [regsub "_V$|_H$" $base_cell_name ""]
        set pad_name [get_db $pad .name]
        set pad_orient [get_db $pad .orient]
        set pad_llx [get_db $pad .bbox.ll.x]
        set pad_lly [get_db $pad .bbox.ll.y]
        set pad_urx [get_db $pad .bbox.ur.x]
        set pad_ury [get_db $pad .bbox.ur.y]
        #puts "$pad_name $base_cell_name"
        
        if [llength [get_db inst:$pad_name .pg_pins -if {.base_name == $padpin}]] {
            set port_name [get_db pg_pin:$pad_name/$padpin .net.base_name]
            set pin_shapes [get_db [get_db pg_base_pin:$base_cell_name/$padpin .physical_pins.layer_shapes -if {.layer.name == $pin_top_layer}] .shapes.rect]
        } elseif [llength [get_db inst:$pad_name .pins -if {.base_name == $padpin}]] {
            set port_name [get_db pin:$pad_name/$padpin .net.base_name]
            set pin_shapes [get_db [get_db base_pin:$base_cell_name/$padpin .physical_pins.layer_shapes -if {.layer.name == $pin_top_layer}] .shapes.rect]
        } else {
            puts "Failed get pin $pad_name/$padpin"
            continue
        }
        if {$port_name == ""} {
             puts "WARNING: $pad_name/$padpin does not connect to any net"
             set port_name [::tech_mv_library_value LIB_PIN_001]
        }

        set aspect_ratio 1000
        foreach  pin_shape $pin_shapes {
            #get pin rect with smallest aspect ratio
            lassign  $pin_shape pin_llx_t pin_lly_t pin_urx_t pin_ury_t
            set pin_width [expr $pin_urx_t - $pin_llx_t]
            set pin_height [expr $pin_ury_t - $pin_lly_t]
            if {$pin_height > $pin_width} {
                   set aspect_ratio_t [expr $pin_height/$pin_width]
            } else {
                   set aspect_ratio_t [expr $pin_width/$pin_height]
            }
            if { $aspect_ratio_t < $aspect_ratio } {
                   set basepin_rect $pin_shape
                   set aspect_ratio $aspect_ratio_t
            }
        }
        set pin_rect [get_transform_shapes -inst $pad_name -local_pt $basepin_rect]
        if [regexp -nocase {\yr90\y|my90} $pad_orient] {
            lappend right_pins "{$port_name $pin_rect} {$pad_name $pad_llx $pad_lly $pad_urx $pad_ury $pad_orient}"
        } elseif [regexp -nocase {r270|mx90} $pad_orient] {
            lappend left_pins "{$port_name $pin_rect} {$pad_name $pad_llx $pad_lly $pad_urx $pad_ury $pad_orient}"
        } elseif [regexp -nocase {r180|\ymx\y} $pad_orient] {
            lappend top_pins "{$port_name $pin_rect} {$pad_name $pad_llx $pad_lly $pad_urx $pad_ury $pad_orient}"
        } else {
            lappend bottom_pins "{$port_name $pin_rect} {$pad_name $pad_llx $pad_lly $pad_urx $pad_ury $pad_orient}"
        }
    }
    
    set sort_right_pins [lsort -command comparey $right_pins ]
    set sort_left_pins [lsort -decreasing -command comparey $left_pins ]
    set sort_top_pins [lsort -decreasing -command comparex $top_pins ]
    set sort_bottom_pins [lsort -command comparex $bottom_pins ]
    set ::libvar::overlap_bond_pads {}
    #Right
    set bond_pad_turn "outer"
    if [info exists ::libvar::rightpad_down] { set bond_pad_turn $::libvar::rightpad_down }
    foreach curpin $sort_right_pins {
        lassign [lindex $curpin 0] port_name pin_llx pin_lly pin_urx pin_ury 
        lassign [lindex $curpin 1] pad_name pad_llx pad_lly pad_urx pad_ury orient 
        #puts "Right $port_name $pin_llx $pin_lly $pin_urx $pin_ury, $pad_name $pad_llx $pad_lly $pad_urx $pad_ury $orient"
        set bond_pad_name "BP_${port_name}"
        if {[llength [get_db pg_nets $port_name]]} { set bond_pad_name "BP_${port_name}_${pad_name}" } 
    
        set bond_pad_cy [expr ($pin_lly + $pin_ury)/2]
        if { $bond_pad_turn == "outer" } {
            set bond_pad_cx [expr $pad_urx + $BOND_PAD_halfh+$::BOND_PAD_GAP]
            run_bond_pad_and_route $bond_pad_cx $bond_pad_cy $pin_llx $pin_lly $pin_urx $pin_ury $bond_pad_name $port_name $orient
            set bond_pad_turn "inner"
        } else {
            set bond_pad_cx [expr $pad_llx - $BOND_PAD_halfh-$::BOND_PAD_GAP]
            run_bond_pad_and_route $bond_pad_cx $bond_pad_cy $pin_llx $pin_lly $pin_urx $pin_ury $bond_pad_name $port_name $orient
            set bond_pad_turn "outer"
        }
    }
    
    #Top
    if [info exists ::libvar::toppad_right] { 
        set bond_pad_turn $::libvar::toppad_right
    }
    foreach curpin $sort_top_pins {
        lassign [lindex $curpin 0] port_name pin_llx pin_lly pin_urx pin_ury 
        lassign [lindex $curpin 1] pad_name pad_llx pad_lly pad_urx pad_ury orient 
        #puts "Top $port_name $pin_llx $pin_lly $pin_urx $pin_ury , $pad_name $pad_llx $pad_lly $pad_urx $pad_ury $orient"
        set bond_pad_name "BP_${port_name}"
        if {[llength [get_db pg_nets $port_name]]} { set bond_pad_name "BP_${port_name}_${pad_name}" } 

        set bond_pad_cx [expr ($pin_llx + $pin_urx)/2]
        if { $bond_pad_turn == "outer" } {
            set bond_pad_cy [expr $pad_ury + $BOND_PAD_halfh+$::BOND_PAD_GAP]
            run_bond_pad_and_route $bond_pad_cx $bond_pad_cy $pin_llx $pin_lly $pin_urx $pin_ury $bond_pad_name $port_name $orient
            set bond_pad_turn "inner"
        } else {
            set bond_pad_cy [expr $pad_lly - $BOND_PAD_halfh-$::BOND_PAD_GAP]
            run_bond_pad_and_route $bond_pad_cx $bond_pad_cy $pin_llx $pin_lly $pin_urx $pin_ury $bond_pad_name $port_name $orient
            set bond_pad_turn "outer"
        }
    }
    
    #Left
    if [info exists ::libvar::leftpad_up] { set bond_pad_turn $::libvar::leftpad_up}
    foreach curpin $sort_left_pins {
        lassign [lindex $curpin 0] port_name pin_llx pin_lly pin_urx pin_ury 
        lassign [lindex $curpin 1] pad_name pad_llx pad_lly pad_urx pad_ury orient 
        #puts "Left $port_name $pin_llx $pin_lly $pin_urx $pin_ury , $pad_name $pad_llx $pad_lly $pad_urx $pad_ury $orient"
        set bond_pad_name "BP_${port_name}"
        if {[llength [get_db pg_nets $port_name]]} { set bond_pad_name "BP_${port_name}_${pad_name}" } 

        set bond_pad_cy [expr ($pin_lly + $pin_ury)/2]
        if { $bond_pad_turn == "outer" } {
            set bond_pad_cx [expr $pad_llx - $BOND_PAD_halfh-$::BOND_PAD_GAP]
            run_bond_pad_and_route $bond_pad_cx $bond_pad_cy $pin_llx $pin_lly $pin_urx $pin_ury $bond_pad_name $port_name $orient
            set bond_pad_turn "inner"
        } else {
            set bond_pad_cx [expr $pad_urx + $BOND_PAD_halfh+$::BOND_PAD_GAP]
            run_bond_pad_and_route $bond_pad_cx $bond_pad_cy $pin_llx $pin_lly $pin_urx $pin_ury $bond_pad_name $port_name $orient
            set bond_pad_turn "outer"
        }
    }
    
    
    #Bottom
    if [info exists ::libvar::bottompad_left] { set bond_pad_turn $::libvar::bottompad_left}
    foreach curpin $sort_bottom_pins {
        lassign [lindex $curpin 0] port_name pin_llx pin_lly pin_urx pin_ury 
        lassign [lindex $curpin 1] pad_name pad_llx pad_lly pad_urx pad_ury orient 
        #puts "Top $port_name $pin_llx $pin_lly $pin_urx $pin_ury , $pad_name $pad_llx $pad_lly $pad_urx $pad_ury $orient"
        set bond_pad_name "BP_${port_name}"
        if {[llength [get_db pg_nets $port_name]]} { set bond_pad_name "BP_${port_name}_${pad_name}" } 
    
        set bond_pad_cx [expr ($pin_llx + $pin_urx)/2]
        if { $bond_pad_turn == "outer" } {
            set bond_pad_cy [expr $pad_lly - $BOND_PAD_halfh-$::BOND_PAD_GAP]
            run_bond_pad_and_route $bond_pad_cx $bond_pad_cy $pin_llx $pin_lly $pin_urx $pin_ury $bond_pad_name $port_name $orient
            set bond_pad_turn "inner"
        } else {
            set bond_pad_cy [expr $pad_ury + $BOND_PAD_halfh+$::BOND_PAD_GAP]
            run_bond_pad_and_route $bond_pad_cx $bond_pad_cy $pin_llx $pin_lly $pin_urx $pin_ury $bond_pad_name $port_name $orient
            set bond_pad_turn "outer"
        }
    }

    if [llength $::libvar::overlap_bond_pads] {
        puts "\n  ERROR: These bond pads may overlap other bond-pad objects: "
        foreach overlap_info $::libvar::overlap_bond_pads {
            puts "         $overlap_info"
        }
    } else {
        puts "==ATTENTION =============================================="
        puts "= This script do not guarantee the result accuracy.      ="
        puts "= Please carefully check all bond pads are placed correctly,       ="
        puts "= all AP routed and connected with pad pins with RV via. ="
        puts "=========================================================="
    }
    
    gui_set_tool select
}

proc delete_bond_pad_blockage {} {
    delete_obj [get_db route_blockages BondPadBlk]
    gui_redraw
}


proc create_bond_pad_blockage {} {
    tech_mv_check_bond_pad_collateral
    if { [llength [get_db bumps]] == 0 } {
        puts "\nNo bond-pad object found, use create_bond_pad_and_route first\n"
        return
    }
    delete_obj [get_db route_blockages BondPadBlk]
    lassign [lindex [get_db designs .bbox] 0] left_out bottom_out right_out top_out
    lassign [lindex [get_db designs .bbox] 0] left_in bottom_in right_in top_in
    foreach bond_pad_obj [get_db bumps] {
        set orient [get_db $bond_pad_obj .orient]
        lassign [lindex [get_db $bond_pad_obj .bbox] 0] bllx blly burx bury
        if [regexp {\yr90\y|my90} $orient] {
            if { $bllx < $right_in } { set right_in $bllx }
            if { $burx > $right_out } { set right_out $burx }
        } elseif [regexp -nocase {r270|mx90} $orient] {
            if { $bllx < $left_out } { set left_out $bllx }
            if { $burx > $left_in } { set left_in $burx }
        } elseif [regexp -nocase {r180|\ymx\y} $orient] {
            if { $blly < $top_in } { set top_in $blly }
            if { $bury > $top_out } { set top_out $bury }
        } else {
            if { $blly < $bottom_out } { set bottom_out $blly }
            if { $bury > $bottom_in } { set bottom_in $bury }
        }
    }
    set layernum_AP [get_db layer:$::BOND_PAD_TOP_LAYER .route_index ]
    set block_layer "[expr $layernum_AP-1] [expr $layernum_AP-2]"
    
    if { $right_out > $right_in } {
        create_route_blockage -rect "$right_in $bottom_out $right_out $top_out" -layer $block_layer -name BondPadBlk
    }
    if { $left_in > $left_out} {
        create_route_blockage -rect "$left_out $bottom_out $left_in $top_out" -layer $block_layer -name BondPadBlk
    }
    if { $top_out> $top_in} {
        create_route_blockage -rect "$left_in $top_in $right_in $top_out" -layer $block_layer -name BondPadBlk
    }
    if { $bottom_in > $bottom_out} {
        create_route_blockage -rect "$left_in $bottom_out $right_in $bottom_in" -layer $block_layer -name BondPadBlk
    }
}

proc create_chip_boundary {} {
    tech_mv_check_bond_pad_collateral
    if { [llength [get_db bumps]] == 0 } {
        puts "\nNo bond-pad object found, use create_bond_pad_and_route first\n"
        return
    }
    delete_obj [get_db gui_rects -if [format {.gui_layer_name == "%s"} $::BOND_PAD_CHIP_BOUNDARY_LAYER]]
    lassign [lindex [get_db designs .bbox] 0] left_out bottom_out right_out top_out
    lassign [lindex [get_db designs .bbox] 0] left_in bottom_in right_in top_in
    foreach bond_pad_obj [get_db bumps] {
        set orient [get_db $bond_pad_obj .orient]
        lassign [lindex [get_db $bond_pad_obj .bbox] 0] bllx blly burx bury
        if [regexp {\yr90\y|my90} $orient] {
            if { $bllx < $right_in } { set right_in $bllx }
            if { $burx > $right_out } { set right_out $burx }
        } elseif [regexp -nocase {r180|\ymx\y} $orient] {
            if { $blly < $top_in } { set top_in $blly }
            if { $bury > $top_out } { set top_out $bury }
        } elseif [regexp -nocase {r270|mx90} $orient] {
            if { $bllx < $left_out } { set left_out $bllx }
            if { $burx > $left_in } { set left_in $burx }
        } else {
            if { $blly < $bottom_out } { set bottom_out $blly }
            if { $bury > $bottom_in } { set bottom_in $bury }
        }
    }

    set extend $::BOND_PAD_CHIP_BOUNDARY_VERTICAL_EXTEND
    set chip_org_lly [get_db designs .bbox.ll.y]
    set bottom_out_snap [expr round(($bottom_out-$extend-[::tech_mv_private_value {bond_pad_boundary::bottom_snap::literal_1}])/[::tech_mv_private_value {bond_pad_boundary::bottom_snap::literal_2}])*[::tech_mv_private_value {bond_pad_boundary::bottom_snap::literal_3}] + $chip_org_lly]
    set top_out_snap [expr round(($top_out+$extend+[::tech_mv_private_value {bond_pad_boundary::top_snap::literal_1}])/[::tech_mv_private_value {bond_pad_boundary::top_snap::literal_2}])*[::tech_mv_private_value {bond_pad_boundary::top_snap::literal_3}] + $chip_org_lly]
    set left_out_ext [expr {$left_out-$::BOND_PAD_CHIP_BOUNDARY_HORIZONTAL_EXTEND}]
    set right_out_ext [expr {$right_out+$::BOND_PAD_CHIP_BOUNDARY_HORIZONTAL_EXTEND}]
    create_gui_shape -layer $::BOND_PAD_CHIP_BOUNDARY_LAYER -rect "$left_out_ext $bottom_out_snap $right_out_ext $top_out_snap"

    set_layer_preference $::BOND_PAD_CHIP_BOUNDARY_LAYER -color red
    set_layer_preference $::BOND_PAD_CHIP_BOUNDARY_LAYER -stipple none
    puts "\n\n To stream out chip_boundary, add below line in streamOut.map\n CUSTOM_CB CUSTOM 108 250 \n\n"
}

proc create_bond_pad_label {} {
    if { [llength [get_db bumps]] == 0 } {
        puts "\nNo bond-pad object found, use create_bond_pad_and_route first\n"
    }
    delete_obj [get_db gui_texts -if {.gui_layer_name == CUSTOM_TEXT}]
    foreach bond_pad_obj [get_db bumps] {
        set bond_pad_orient [get_db $bond_pad_obj .orient]
        set bond_pad_name [get_db $bond_pad_obj .port.base_name]
        set bond_pad_center [get_db $bond_pad_obj .center]
        set orient r0
        if [regexp {r0|r180|\ymx\y|my} $bond_pad_orient] { set orient r90 }
        create_gui_text -label $bond_pad_name -layer CUSTOM_TEXT -height 10 -orient $orient -pt $bond_pad_center
    }
    gui_redraw
}

proc show_usage {} {
    puts "\n** USAGE **"
    puts "Create bond pad and route:    create_bond_pad_and_route"
    puts "                          delete_bond_pad_and_route"
    puts "Add blockage over bond pad:   create_bond_pad_blockage"
    puts "                          delete_bond_pad_blockage"
    puts "Create chip boundary:     create_chip_boundary"
    puts ""
}

show_usage
