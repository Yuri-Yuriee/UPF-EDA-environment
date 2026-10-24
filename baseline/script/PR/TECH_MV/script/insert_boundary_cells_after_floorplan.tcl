# =============================================================================
# Insert EndCap and WellTap cells after Power Domain / Hard-Macro floorplan lock
# =============================================================================
# This script is sourced by script/floorplan.tcl only after:
#   1. Power-Domain geometry has been finalized and validated;
#   2. every non-pad Hard Macro has been fixed;
#   3. finish_floorplan has generated the final row/blockage topology;
#   4. temporary Standard-Cell placement has been cleared.
#
# add_endcaps operates on the exposed placement-row boundaries.  With the
# final row topology, those boundaries include the core edge, Power-Domain
# region edges, and row cuts around fixed Hard Macros / macro halos.
# add_endcaps_boundary_tap also inserts the configured boundary tap cells.
# add_well_taps then fills the interior of each physical Power Domain.

puts "User script [info script]"

proc bc_get_hard_macros {} {
    return [get_db insts -if {
        .base_cell.base_class == block &&
        .is_pad == false
    }]
}

proc bc_check_hard_macros_fixed {} {
    set errors {}
    foreach inst [bc_get_hard_macros] {
        set status [get_db $inst .place_status]
        if {$status ne "fixed"} {
            lappend errors [list [get_db $inst .name] $status]
        }
    }

    if {[llength $errors] > 0} {
        foreach item $errors {
            lassign $item name status
            puts "ERROR: Hard Macro '$name' is not fixed (status=$status)."
        }
        error "Boundary-cell insertion stopped because [llength $errors] Hard Macro(s) are not fixed."
    }
    puts "PASS: All non-pad Hard Macros are fixed."
}

proc bc_get_physical_power_domains {} {
    set result {}
    foreach group [get_db groups] {
        set pd_name ""
        catch { set pd_name [get_db $group .power_domain.name] }
        if {$pd_name eq ""} {
            continue
        }

        set rects {}
        catch { set rects [get_db $group .rects] }
        if {[llength $rects] == 0} {
            continue
        }

        if {[lsearch -exact $result $pd_name] < 0} {
            lappend result $pd_name
        }
    }
    return $result
}

proc bc_check_power_domain_geometry {} {
    set pd_names [bc_get_physical_power_domains]
    if {[llength $pd_names] == 0} {
        error "Boundary-cell insertion stopped because no physical Power-Domain group with rectangles was found."
    }
    puts "PASS: Finalized physical Power Domains = $pd_names"
    return $pd_names
}


if {!$INSERT_BOUNDARY_CELLS_AFTER_FLOORPLAN} {
    puts "INFO: Boundary-cell insertion after floorplan is disabled."
} else {
    puts "INFO: Inserting boundary cells after Power Domain and Hard-Macro floorplan lock."

    if {$REQUIRE_FIXED_HARD_MACROS_BEFORE_BOUNDARY_CELLS} {
        bc_check_hard_macros_fixed
    }

    if {$REQUIRE_POWER_DOMAIN_GEOMETRY_BEFORE_BOUNDARY_CELLS} {
        bc_check_power_domain_geometry
    }

    if {$ENABLE_ENDCAP_INSERTION} {
        puts "INFO: Adding EndCap/boundary-tap cells using one global pass followed by one pass per physical Power Domain."
        source -quiet [file join $SCRIPT_DIR add_endcaps.tcl]
    } else {
        puts "INFO: EndCap insertion is disabled by ENABLE_ENDCAP_INSERTION."
    }

    if {$ENABLE_WELL_TAP_INSERTION && (!$DEFER_WELL_TAP_TO_POST_POWERPLAN)} {
        puts "INFO: Adding checkerboard WellTap cells inside each physical Power Domain."
        source -quiet [file join $SCRIPT_DIR add_well_taps.tcl]
    } elseif {$ENABLE_WELL_TAP_INSERTION && $DEFER_WELL_TAP_TO_POST_POWERPLAN} {
        puts "INFO: General WellTap insertion is deferred to post-PowerPlan Stage 02."
    } else {
        puts "INFO: WellTap insertion is disabled by ENABLE_WELL_TAP_INSERTION."
    }

    write_db [file join $DB_DIR 01_90_boundary_cells.enc]
    puts "INFO: Boundary-cell insertion completed."
}
