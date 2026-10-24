# =============================================================================
# Manual Power-Domain Placement Utilities
# =============================================================================
# This file only defines procedures. It does not modify the design when sourced.


# Print an explicit operator prompt immediately before Innovus is suspended.
# flush stdout ensures the message is visible in the command console before
# execution stops at the suspend command.
proc fp_prompt_resume {stage_title instructions} {
    puts ""
    puts "######################################################################"
    puts "# ACTION REQUIRED: $stage_title"
    puts "######################################################################"
    foreach line $instructions {
        puts "# $line"
    }
    puts "#"
    puts "# The Tcl flow will now pause."
    puts "# After completing the GUI operation, enter the following command"
    puts "# in the Innovus Command Console and press Enter:"
    puts "#"
    puts "#     resume"
    puts "#"
    puts "# After completing the GUI operation, enter resume in the Innovus Command Console and press Enter."
    puts "######################################################################"
    puts ""
    flush stdout
}

proc fp_pd_bbox_numeric_tokens {value {depth 0}} {
    if {$depth > 12} { return "" }
    set value [string trim $value]
    if {$value eq ""} { return {} }
    if {[string is double -strict $value]} { return [list $value] }
    if {[catch {set count [llength $value]}]} { return "" }
    if {$count == 1} {
        set inner [lindex $value 0]
        if {$inner eq $value} { return "" }
        return [fp_pd_bbox_numeric_tokens $inner [expr {$depth + 1}]]
    }
    set tokens {}
    foreach item $value {
        set item_tokens [fp_pd_bbox_numeric_tokens $item [expr {$depth + 1}]]
        if {$item_tokens eq ""} { return "" }
        lappend tokens {*}$item_tokens
    }
    return $tokens
}

proc fp_pd_normalize_bbox {bbox} {
    set values [fp_pd_bbox_numeric_tokens $bbox]
    if {[llength $values] != 4} { return "" }
    lassign $values llx lly urx ury
    foreach value $values {
        if {![string is double -strict $value]} { return "" }
    }
    if {$llx >= $urx || $lly >= $ury} { return "" }
    return $values
}

proc fp_pd_get_group {pd_name} {
    set groups [get_db groups -if ".power_domain.name == $pd_name"]
    if {[llength $groups] == 0} {
        return ""
    }
    if {[llength $groups] > 1} {
        puts "WARNING: Multiple floorplan groups found for power domain '$pd_name'; using the first one."
    }
    return [lindex $groups 0]
}

proc fp_pd_uses_mouse_selection {configured_domains} {
    foreach item $configured_domains {
        set token [string tolower [string trim $item]]
        if {$token eq "selected" || $token eq "@selected" || $token eq "<selected>"} {
            return true
        }
    }
    return false
}

proc fp_pd_resolve_manual_domains {configured_domains} {
    if {[llength $configured_domains] == 0} {
        # Empty config means all explicit floorplan groups associated with a power domain.
        set result {}
        foreach group [get_db groups] {
            set pd_name ""
            catch { set pd_name [get_db $group .power_domain.name] }
            if {$pd_name ne "" && [lsearch -exact $result $pd_name] < 0} {
                lappend result $pd_name
            }
        }
        return $result
    }

    if {[llength [info commands tt_pd_resolve_power_domains]] == 0} {
        source -quiet [file join $::TOOL_DIR 01_floorplan geometry TT_proc_pd_geometry.tcl]
    }
    return [tt_pd_resolve_power_domains $configured_domains true]
}

proc fp_pd_validate_manual_placement {pd_names strict} {
    set core_bbox [fp_pd_normalize_bbox [get_db current_design .core_bbox]]
    if {$core_bbox eq ""} {
        error "Cannot get a valid core box from: get_db current_design .core_bbox"
    }
    lassign $core_bbox core_llx core_lly core_urx core_ury

    set error_count 0
    foreach pd_name $pd_names {
        set group [fp_pd_get_group $pd_name]
        if {$group eq ""} {
            set msg "Cannot find a floorplan group for power domain '$pd_name'."
            if {$strict} {
                puts "ERROR: $msg"
                incr error_count
            } else {
                puts "WARNING: $msg"
            }
            continue
        }

        set rects [get_db $group .rects]
        if {$rects eq "" || [llength $rects] == 0} {
            puts "ERROR: Power domain '$pd_name' has no floorplan rectangle."
            incr error_count
            continue
        }

        set rect_index 0
        foreach rect $rects {
            incr rect_index
            set flat_rect [fp_pd_normalize_bbox $rect]
            if {$flat_rect eq ""} {
                puts "ERROR: Power domain '$pd_name' rectangle #$rect_index has an unexpected format: $rect"
                incr error_count
                continue
            }

            lassign $flat_rect llx lly urx ury
            if {$llx < $core_llx || $lly < $core_lly ||
                $urx > $core_urx || $ury > $core_ury} {
                puts "ERROR: Power domain '$pd_name' rectangle #$rect_index is outside the core."
                puts "ERROR:   PD rect   = $flat_rect"
                puts "ERROR:   Core bbox = $core_bbox"
                incr error_count
            }
        }
    }

    if {$error_count > 0} {
        error "Manual power-domain placement check failed with $error_count error(s)."
    }

    puts "PASS: Manual power-domain placement check passed for: $pd_names"
}

proc fp_manual_place_power_domains {pd_names strict db_file} {
    set use_mouse_selection [fp_pd_uses_mouse_selection $pd_names]

    # Resolve fixed names before pausing. Mouse-selected names are intentionally
    # resolved only after resume because the user performs the selection in GUI.
    if {$use_mouse_selection} {
        set display_domains $pd_names
    } else {
        set display_domains [fp_pd_resolve_manual_domains $pd_names]
        if {[llength $display_domains] == 0} {
            set msg "No explicit power-domain floorplan groups were found for manual placement."
            if {$strict} { error $msg }
            puts "WARNING: $msg"
            return
        }
    }

    if {$db_file ne ""} {
        write_db $db_file
        puts "INFO: Saved checkpoint before manual power-domain placement: $db_file"
    }

    set instructions [list \
        "Power-domain target specification: $display_domains" \
        "Place or reshape the intended power-domain regions in the GUI." \
        "Do not place or fix hard macros during this stage." \
    ]
    if {$use_mouse_selection} {
        lappend instructions \
            "Before typing resume, select one or more power-domain regions/groups with the mouse."
        lappend instructions \
            "The selected power domains will be validated and used by the reshape flow after resume."
    }

    fp_prompt_resume "Manual Power-Domain Placement" $instructions
    if {[llength [info commands tech_mv_checkpoint_tools]]} { tech_mv_checkpoint_tools {01_floorplan} {manual_place_power_domain} }
    suspend

    puts "INFO: Resumed after manual power-domain placement."
    FP_save after_manual_power_domain 21
    set resolved_domains [fp_pd_resolve_manual_domains $pd_names]
    if {[llength $resolved_domains] == 0} {
        set msg "No power domain was resolved after the manual GUI stage."
        if {$strict} { error $msg }
        puts "WARNING: $msg"
        return
    }
    fp_pd_validate_manual_placement $resolved_domains $strict
}
