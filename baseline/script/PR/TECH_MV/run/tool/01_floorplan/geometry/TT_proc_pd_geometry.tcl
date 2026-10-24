# Runtime adapter preserves the historical logical source path.
if {[info exists ::TECH_MV_RUNTIME_ROOT]} {
    info script [file join $::TECH_MV_RUNTIME_ROOT run/tool/01_floorplan/geometry/TT_proc_pd_geometry.tcl]
}
# PUBLIC_EXPORT_REVIEW_REQUIRED: residual technology candidates require manual review.
# =============================================================================
# TT_proc_pd_geometry.tcl
# =============================================================================
# Manual Power-Domain geometry procedure library.
#
# Merged from the former:
#   TT_proc_pd_geometry.tcl
#   TT_proc_pd_geometry.tcl
#   TT_proc_pd_geometry.tcl
#
# Sourcing this file defines procedures only; it does not modify the design.
# =============================================================================

# =============================================================================
# TECH_MV Power-Domain Reshape Utilities
# =============================================================================
# This file only defines procedures. It does not modify the design when sourced.
#
# Simple public procedures:
#   PD_merge ?target? ?strict?
#   PD_fill_holes ?target? ?strict?
#   PD_base <top> <bottom> <left> <right> ?target? ?strict?
#   PD_reshape <width_scale> <height_scale> ?target? ?anchor? ?strict?
#   PD_size <width> <height> ?target? ?anchor? ?strict?
#   PD_ratio <width_to_height> ?target? ?preserve? ?anchor? ?strict?
#   PD_blk <inner|outer> <top> <bottom> <left> <right> ?target? ?strict?
#   PD_blk_inner <top> <bottom> <left> <right> ?target? ?strict?
#   PD_blk_outer <top> <bottom> <left> <right> ?target? ?strict?
#   PD_snap ?target? ?strict?
#   PD_cut ?target? ?strict?
#   PD_select ?strict?
#   PD_bbox ?target? ?strict?
#   PD_core ?strict?
#
# target may be a power-domain name, a list of names, or "selected".
# When target is omitted, the currently mouse-selected power domain(s) are used.
#
# The original tt_pd_* procedures remain available for backward compatibility
# and are used internally by the simplified PD_* interface.
#
# Config target token:
#   selected   Resolve one or more power domains selected with the GUI mouse.
#
# Supported anchors:
#   center lower_left lower_right upper_left upper_right
# =============================================================================

proc tt_pd_bbox_numeric_tokens {value {object_name "object"} {depth 0}} {
    if {$depth > 12} {
        error "Bounding-box nesting is too deep for $object_name: $value"
    }

    set value [string trim $value]
    if {$value eq ""} {
        return {}
    }

    # A numeric scalar is a terminal bbox coordinate.
    if {[string is double -strict $value]} {
        return [list $value]
    }

    if {[catch {set count [llength $value]}]} {
        error "Invalid Tcl-list bounding-box value for $object_name: $value"
    }

    # A non-numeric scalar cannot be decomposed any further.
    if {$count == 1} {
        set inner [lindex $value 0]
        if {$inner eq $value} {
            error "Non-numeric bounding-box value for $object_name: $value"
        }
        return [tt_pd_bbox_numeric_tokens $inner $object_name [expr {$depth + 1}]]
    }

    set tokens {}
    foreach item $value {
        set item_tokens [tt_pd_bbox_numeric_tokens \
            $item $object_name [expr {$depth + 1}]]
        lappend tokens {*}$item_tokens
    }
    return $tokens
}

proc tt_pd_normalize_bbox {bbox {object_name "object"}} {
    if {[string trim $bbox] eq ""} {
        error "Cannot get bounding box for $object_name."
    }

    # Innovus can return the same bbox with different nesting levels, e.g.:
    #   llx lly urx ury
    #   {llx lly urx ury}
    #   {{llx lly} {urx ury}}
    #   {{{llx lly urx ury}}}
    # Recursively collect numeric leaves instead of depending on one exact
    # list representation.
    set bbox_values [tt_pd_bbox_numeric_tokens $bbox $object_name]

    if {[llength $bbox_values] != 4} {
        error "Unexpected bounding-box format for $object_name: $bbox"
    }

    lassign $bbox_values llx lly urx ury

    if {$llx >= $urx || $lly >= $ury} {
        error "Invalid bounding box for $object_name: $bbox_values"
    }

    return [list $llx $lly $urx $ury]
}

proc tt_pd_bbox_from_rects {rects} {
    if {$rects eq "" || [llength $rects] == 0} {
        return ""
    }

    set first [tt_pd_normalize_bbox [lindex $rects 0] "power-domain rectangle"]
    lassign $first min_x min_y max_x max_y

    foreach rect $rects {
        lassign [tt_pd_normalize_bbox $rect "power-domain rectangle"] llx lly urx ury
        if {$llx < $min_x} { set min_x $llx }
        if {$lly < $min_y} { set min_y $lly }
        if {$urx > $max_x} { set max_x $urx }
        if {$ury > $max_y} { set max_y $ury }
    }

    return [list $min_x $min_y $max_x $max_y]
}

proc tt_pd_get_group {pd_name} {
    set groups {}
    catch { set groups [get_db groups] }

    # Prefer the floorplan group name because some UPF-created groups expose
    # the Power Domain only through their group name.
    foreach group $groups {
        set group_name ""
        catch { set group_name [get_db $group .name] }
        if {$group_name eq $pd_name} {
            return $group
        }
    }

    # Fallback to the associated Power Domain object name.
    set matches {}
    foreach group $groups {
        set group_pd_name ""
        catch { set group_pd_name [get_db $group .power_domain.name] }
        if {$group_pd_name eq $pd_name} {
            lappend matches $group
        }
    }

    if {[llength $matches] == 0} {
        return ""
    }
    if {[llength $matches] > 1} {
        puts "WARNING: Multiple groups found for $pd_name; using the first one."
    }
    return [lindex $matches 0]
}

# -----------------------------------------------------------------------------
# GUI mouse-selection helpers
# -----------------------------------------------------------------------------
# The user may select either a power-domain region or its floorplan group.
# Innovus selection objects are resolved back to .power_domain.name.
proc tt_pd_is_selection_token {value} {
    set token [string tolower [string trim $value]]
    return [expr {
        $token eq "selected" ||
        $token eq "@selected" ||
        $token eq "<selected>"
    }]
}

proc tt_pd_is_all_token {value} {
    set token [string tolower [string trim $value]]
    return [expr {
        $token eq "all" ||
        $token eq "@all" ||
        $token eq "<all>"
    }]
}

proc tt_pd_unique_list {values} {
    set result {}
    foreach value $values {
        if {$value eq "" || [string equal -nocase $value "NULL"]} {
            continue
        }
        if {[lsearch -exact $result $value] < 0} {
            lappend result $value
        }
    }
    return $result
}

proc tt_pd_get_selected_power_domains {{strict true}} {
    if {[llength [info commands get_db]] == 0} {
        set msg "Innovus command 'get_db' is unavailable."
        if {$strict} { error $msg }
        puts "WARNING: $msg"
        return {}
    }

    set selected_objects {}
    catch { set selected_objects [get_db selected] }

    if {$selected_objects eq "" || [llength $selected_objects] == 0} {
        set msg "No GUI object is selected. Select one or more power-domain regions/groups with the mouse, then run the command again."
        if {$strict} { error $msg }
        puts "WARNING: $msg"
        return {}
    }

    set result {}

    # Fast path supported by Innovus for selected groups/regions.
    set selected_pd_names {}
    catch { set selected_pd_names [get_db selected .power_domain.name] }
    foreach pd_name $selected_pd_names {
        if {$pd_name ne "" && ![string equal -nocase $pd_name "NULL"]} {
            lappend result $pd_name
        }
    }

    # Resolve every selected object independently. This also supports selecting
    # a floorplan group whose .power_domain.name carries the domain identity.
    foreach selected_obj $selected_objects {
        set pd_names {}
        catch { set pd_names [get_db $selected_obj .power_domain.name] }
        foreach pd_name $pd_names {
            if {$pd_name ne "" && ![string equal -nocase $pd_name "NULL"]} {
                lappend result $pd_name
            }
        }

        # Some GUI selections expose only the object/group .name. Confirm that
        # the name is either a power-domain name or a group associated with one.
        set selected_name ""
        catch { set selected_name [get_db $selected_obj .name] }
        if {$selected_name ne ""} {
            if {[tt_pd_get_group $selected_name] ne ""} {
                lappend result $selected_name
            } else {
                foreach group [get_db groups] {
                    set group_name ""
                    catch { set group_name [get_db $group .name] }
                    if {$group_name eq $selected_name} {
                        set group_pd_name ""
                        catch { set group_pd_name [get_db $group .power_domain.name] }
                        if {$group_pd_name ne ""} {
                            lappend result $group_pd_name
                        }
                    }
                }
            }
        }
    }

    set result [tt_pd_unique_list $result]
    if {[llength $result] == 0} {
        set msg "The selected GUI object(s) are not associated with a power domain. Select a power-domain region or its floorplan group."
        if {$strict} { error $msg }
        puts "WARNING: $msg"
        return {}
    }

    puts "INFO: Mouse-selected power domains = $result"
    return $result
}

# Resolve a normal list of power-domain names and/or the special token
# 'selected'. Multiple mouse-selected domains are supported.
proc tt_pd_resolve_power_domains {domain_spec {strict true}} {
    set result {}
    foreach item $domain_spec {
        if {[tt_pd_is_selection_token $item]} {
            foreach pd_name [tt_pd_get_selected_power_domains $strict] {
                lappend result $pd_name
            }
        } elseif {[tt_pd_is_all_token $item]} {
            foreach pd_name [tt_pd_get_all_power_domains $strict] {
                lappend result $pd_name
            }
        } elseif {$item ne ""} {
            lappend result $item
        }
    }
    return [tt_pd_unique_list $result]
}


# Return all Power Domains that have physical floorplan rectangles.
# This is used by PD_snap and PD_cut when no explicit target and no GUI
# selection are provided.
proc tt_pd_get_all_power_domains {{strict true}} {
    if {[llength [info commands get_db]] == 0} {
        set msg "Innovus command 'get_db' is unavailable."
        if {$strict} { error $msg }
        puts "WARNING: $msg"
        return {}
    }

    set groups {}
    catch { set groups [get_db groups] }

    set result {}
    foreach group $groups {
        set pd_name ""
        catch { set pd_name [get_db $group .power_domain.name] }
        if {$pd_name eq "" || [string equal -nocase $pd_name "NULL"]} {
            continue
        }

        # Only include Power Domains that have physical geometry.
        set rects {}
        catch { set rects [get_db $group .rects] }
        if {$rects eq "" || [llength $rects] == 0} {
            continue
        }
        lappend result $pd_name
    }

    set result [tt_pd_unique_list $result]
    if {[llength $result] == 0} {
        set msg "No Power Domain with physical floorplan rectangles was found."
        if {$strict} { error $msg }
        puts "WARNING: $msg"
        return {}
    }

    puts "INFO: All physical Power Domains = $result"
    return $result
}

# Default target policy for PD_snap and PD_cut:
#   1. If one or more GUI objects are selected, use the selected Power Domains.
#   2. If nothing is selected, use every physical Power Domain.
proc tt_pd_get_selected_or_all_power_domains {{strict true}} {
    if {[llength [info commands get_db]] == 0} {
        set msg "Innovus command 'get_db' is unavailable."
        if {$strict} { error $msg }
        puts "WARNING: $msg"
        return {}
    }

    set selected_objects {}
    catch { set selected_objects [get_db selected] }

    if {$selected_objects eq "" || [llength $selected_objects] == 0} {
        puts "INFO: No GUI Power Domain is selected; defaulting to all physical Power Domains."
        return [tt_pd_get_all_power_domains $strict]
    }

    # A GUI object is selected. Require it to resolve to a Power Domain rather
    # than silently modifying all domains when the wrong object was selected.
    return [tt_pd_get_selected_power_domains $strict]
}

proc tt_pd_get_bbox {pd_name {strict true}} {
    set group [tt_pd_get_group $pd_name]
    if {$group eq ""} {
        set msg "Cannot find a floorplan group for power domain '$pd_name'."
        if {$strict} { error $msg }
        puts "WARNING: $msg"
        return ""
    }

    set rects [get_db $group .rects]
    set bbox [tt_pd_bbox_from_rects $rects]
    if {$bbox eq ""} {
        set msg "Power domain '$pd_name' has no valid floorplan rectangles."
        if {$strict} { error $msg }
        puts "WARNING: $msg"
        return ""
    }

    return $bbox
}

proc tt_pd_get_core_bbox {{strict true}} {
    if {[llength [info commands get_db]] == 0} {
        set msg "Innovus command 'get_db' is unavailable."
        if {$strict} { error $msg }
        puts "WARNING: $msg"
        return ""
    }

    set raw_core_bbox [get_db current_design .core_bbox]
    if {[catch {
        set core_bbox [tt_pd_normalize_bbox $raw_core_bbox "current_design.core_bbox"]
    } err]} {
        if {$strict} { error $err }
        puts "WARNING: $err"
        return ""
    }

    return $core_bbox
}

proc tt_pd_update_bbox {pd_name bbox {strict true}} {
    if {[catch {
        set bbox [tt_pd_normalize_bbox $bbox "power domain '$pd_name'"]
    } err]} {
        if {$strict} { error $err }
        puts "WARNING: $err"
        return false
    }

    set group [tt_pd_get_group $pd_name]
    if {$group eq ""} {
        set msg "Cannot find a floorplan group for power domain '$pd_name'."
        if {$strict} { error $msg }
        puts "WARNING: $msg"
        return false
    }

    set group_name [get_db $group .name]
    puts "INFO: Updating power-domain geometry:"
    puts "INFO:   power domain = $pd_name"
    puts "INFO:   group        = $group_name"
    puts "INFO:   new bbox     = $bbox"

    set _tech_pd_update_target $pd_name
    if {[catch {update_floorplan_obj -obj $pd_name -rects $bbox} err]} {
        puts "WARNING: update by power-domain name failed: $err"
        puts "INFO: Retrying with group name '$group_name'."
        set _tech_pd_update_target $group_name
        if {[catch {update_floorplan_obj -obj $group_name -rects $bbox} group_err]} {
            set msg "Failed to update power domain '$pd_name': $group_err"
            if {$strict} { error $msg }
            puts "WARNING: $msg"
            return false
        }
    }

    if {[llength [info commands tech_mv_pd_trace]] > 0} {
        tech_mv_pd_trace "after_update_floorplan_obj_bbox_${pd_name}"             "update_floorplan_obj -obj $_tech_pd_update_target -rects <bbox>"
    }
    unset _tech_pd_update_target

    return true
}


# Update a Power Domain with an exact union of rectangles.
# Unlike tt_pd_update_bbox, this procedure intentionally accepts multiple
# rectangles and therefore preserves non-rectangular outer boundaries.
proc tt_pd_update_rects {pd_name rects {strict true}} {
    set normalized {}
    foreach rect $rects {
        if {[catch {
            set clean_rect [tt_pd_normalize_bbox \
                $rect "power domain '$pd_name' rectangle"]
        } err]} {
            if {$strict} { error $err }
            puts "WARNING: $err"
            continue
        }
        lappend normalized $clean_rect
    }

    set normalized [tt_pd_compact_rects $normalized]
    if {[llength $normalized] == 0} {
        set msg "Cannot update Power Domain '$pd_name' with an empty rectangle union."
        if {$strict} { error $msg }
        puts "WARNING: $msg"
        return false
    }

    set group [tt_pd_get_group $pd_name]
    if {$group eq ""} {
        set msg "Cannot find a floorplan group for Power Domain '$pd_name'."
        if {$strict} { error $msg }
        puts "WARNING: $msg"
        return false
    }

    set group_name [get_db $group .name]
    puts "INFO: Updating exact Power-Domain rectangle union:"
    puts "INFO:   power domain = $pd_name"
    puts "INFO:   group        = $group_name"
    puts "INFO:   rectangles   = $normalized"

    set _tech_pd_update_target $pd_name
    if {[catch {
        update_floorplan_obj -obj $pd_name -rects $normalized
    } err]} {
        puts "WARNING: update by Power-Domain name failed: $err"
        puts "INFO: Retrying with group name '$group_name'."
        set _tech_pd_update_target $group_name

        if {[catch {
            update_floorplan_obj -obj $group_name -rects $normalized
        } group_err]} {
            set msg "Failed to update Power Domain '$pd_name': $group_err"
            if {$strict} { error $msg }
            puts "WARNING: $msg"
            return false
        }
    }

    if {[llength [info commands tech_mv_pd_trace]] > 0} {
        tech_mv_pd_trace "after_update_floorplan_obj_rects_${pd_name}"             "update_floorplan_obj -obj $_tech_pd_update_target -rects <rectangle_union>"
    }
    unset _tech_pd_update_target

    return true
}

proc tt_pd_sorted_unique_coordinates {values {tol 1.0e-9}} {
    set sorted [lsort -real $values]
    set result {}

    foreach value $sorted {
        if {[llength $result] == 0 ||
            abs($value - [lindex $result end]) > $tol} {
            lappend result $value
        }
    }

    return $result
}

proc tt_pd_point_in_rect_union {x y rects {tol 1.0e-9}} {
    foreach rect $rects {
        lassign $rect llx lly urx ury
        if {$x > $llx - $tol &&
            $x < $urx + $tol &&
            $y > $lly - $tol &&
            $y < $ury + $tol} {
            return true
        }
    }
    return false
}

# Fill only enclosed holes in a rectilinear rectangle union.
#
# Empty cells connected to the bounding-box boundary are classified as
# exterior and remain untouched. Therefore outer concavities, L-shapes,
# stair-step boundaries, protrusions, and notches are preserved exactly.
proc tt_pd_fill_holes_in_rects {raw_rects {tol 1.0e-6}} {
    set rects {}
    foreach rect $raw_rects {
        lappend rects [tt_pd_normalize_bbox $rect "Power-Domain rectangle"]
    }
    set rects [tt_pd_compact_rects $rects $tol]

    if {[llength $rects] == 0} {
        error "Cannot fill holes in an empty rectangle union."
    }

    set bbox [tt_pd_bbox_from_rects $rects]
    lassign $bbox bbox_llx bbox_lly bbox_urx bbox_ury

    set x_values [list $bbox_llx $bbox_urx]
    set y_values [list $bbox_lly $bbox_ury]

    foreach rect $rects {
        lassign $rect llx lly urx ury
        lappend x_values $llx $urx
        lappend y_values $lly $ury
    }

    set xs [tt_pd_sorted_unique_coordinates $x_values]
    set ys [tt_pd_sorted_unique_coordinates $y_values]
    set nx [expr {[llength $xs] - 1}]
    set ny [expr {[llength $ys] - 1}]

    if {$nx <= 0 || $ny <= 0} {
        return [dict create \
            original_rects $rects \
            hole_rects {} \
            filled_rects $rects]
    }

    array set occupied {}
    array set exterior {}

    for {set ix 0} {$ix < $nx} {incr ix} {
        set x1 [lindex $xs $ix]
        set x2 [lindex $xs [expr {$ix + 1}]]
        set cx [expr {($x1 + $x2) / 2.0}]

        for {set iy 0} {$iy < $ny} {incr iy} {
            set y1 [lindex $ys $iy]
            set y2 [lindex $ys [expr {$iy + 1}]]
            set cy [expr {($y1 + $y2) / 2.0}]
            set key "$ix,$iy"
            set occupied($key) \
                [tt_pd_point_in_rect_union $cx $cy $rects $tol]
        }
    }

    set queue {}

    for {set ix 0} {$ix < $nx} {incr ix} {
        foreach iy [list 0 [expr {$ny - 1}]] {
            set key "$ix,$iy"
            if {!$occupied($key) && ![info exists exterior($key)]} {
                set exterior($key) true
                lappend queue [list $ix $iy]
            }
        }
    }

    for {set iy 0} {$iy < $ny} {incr iy} {
        foreach ix [list 0 [expr {$nx - 1}]] {
            set key "$ix,$iy"
            if {!$occupied($key) && ![info exists exterior($key)]} {
                set exterior($key) true
                lappend queue [list $ix $iy]
            }
        }
    }

    set queue_index 0
    while {$queue_index < [llength $queue]} {
        lassign [lindex $queue $queue_index] ix iy
        incr queue_index

        foreach delta {
            {-1 0}
            {1 0}
            {0 -1}
            {0 1}
        } {
            lassign $delta dx dy
            set next_ix [expr {$ix + $dx}]
            set next_iy [expr {$iy + $dy}]

            if {$next_ix < 0 || $next_ix >= $nx ||
                $next_iy < 0 || $next_iy >= $ny} {
                continue
            }

            set neighbor_key "$next_ix,$next_iy"
            if {$occupied($neighbor_key) ||
                [info exists exterior($neighbor_key)]} {
                continue
            }

            set exterior($neighbor_key) true
            lappend queue [list $next_ix $next_iy]
        }
    }

    set hole_rects {}
    for {set ix 0} {$ix < $nx} {incr ix} {
        set x1 [lindex $xs $ix]
        set x2 [lindex $xs [expr {$ix + 1}]]

        for {set iy 0} {$iy < $ny} {incr iy} {
            set key "$ix,$iy"

            if {$occupied($key) || [info exists exterior($key)]} {
                continue
            }

            set y1 [lindex $ys $iy]
            set y2 [lindex $ys [expr {$iy + 1}]]
            lappend hole_rects [list $x1 $y1 $x2 $y2]
        }
    }

    set hole_rects [tt_pd_compact_rects $hole_rects $tol]
    set filled_rects [tt_pd_compact_rects \
        [concat $rects $hole_rects] $tol]

    return [dict create \
        original_rects $rects \
        hole_rects $hole_rects \
        filled_rects $filled_rects]
}

proc tt_pd_fill_internal_holes {pd_name {strict true}} {
    set group [tt_pd_get_group $pd_name]
    if {$group eq ""} {
        set msg "Cannot find a floorplan group for Power Domain '$pd_name'."
        if {$strict} { error $msg }
        puts "WARNING: $msg"
        return [dict create]
    }

    set original_rects [get_db $group .rects]
    if {$original_rects eq "" || [llength $original_rects] == 0} {
        set msg "Power Domain '$pd_name' has no physical rectangles."
        if {$strict} { error $msg }
        puts "WARNING: $msg"
        return [dict create]
    }

    set result [tt_pd_fill_holes_in_rects $original_rects]
    set hole_rects [dict get $result hole_rects]
    set filled_rects [dict get $result filled_rects]

    puts "INFO: Internal-hole analysis for Power Domain '$pd_name':"
    puts "INFO:   original rects = [dict get $result original_rects]"
    puts "INFO:   enclosed holes = $hole_rects"
    puts "INFO:   filled rects   = $filled_rects"

    if {[llength $hole_rects] == 0} {
        puts "INFO: No enclosed internal hole was found; geometry is unchanged."
        return $result
    }

    if {![tt_pd_update_rects $pd_name $filled_rects $strict]} {
        if {$strict} {
            error "Failed to fill internal holes for Power Domain '$pd_name'."
        }
    }

    return $result
}

proc PD_fill_holes {{target selected} {strict true}} {
    set pd_names [PD_targets $target $strict]
    set result [dict create]

    foreach pd_name $pd_names {
        dict set result $pd_name \
            [tt_pd_fill_internal_holes $pd_name $strict]
    }

    return $result
}

proc tt_pd_reshape_to_bbox {pd_name {strict true}} {
    puts "INFO: Reshaping power domain '$pd_name' to one bounding rectangle."
    set group [tt_pd_get_group $pd_name]
    if {$group eq ""} {
        set msg "Cannot find a floorplan group for power domain '$pd_name'."
        if {$strict} { error $msg }
        puts "WARNING: $msg"
        return false
    }

    set rects [get_db $group .rects]
    set bbox [tt_pd_bbox_from_rects $rects]
    if {$bbox eq ""} {
        set msg "Power domain '$pd_name' has no valid floorplan rectangles."
        if {$strict} { error $msg }
        puts "WARNING: $msg"
        return false
    }

    puts "INFO:   original rects = $rects"
    return [tt_pd_update_bbox $pd_name $bbox $strict]
}

# -----------------------------------------------------------------------------
# Cover the core with one selected power domain, leaving an inward offset from
# each core edge.
#
# Argument order follows the requested top/bottom/left/right convention:
#   tt_pd_reshape_to_core_offsets PD_TOP <top_offset> <bottom_offset> <left_offset> <right_offset>
#
# New rectangle:
#   llx = core_llx + left_offset
#   lly = core_lly + bottom_offset
#   urx = core_urx - right_offset
#   ury = core_ury - top_offset
# -----------------------------------------------------------------------------
proc tt_pd_reshape_to_core_offsets {
    pd_name top_offset bottom_offset left_offset right_offset {strict true}
} {
    foreach {offset_name offset_value} [list \
        top $top_offset \
        bottom $bottom_offset \
        left $left_offset \
        right $right_offset] {
        if {![string is double -strict $offset_value]} {
            set msg "The $offset_name offset for '$pd_name' is not numeric: $offset_value"
            if {$strict} { error $msg }
            puts "WARNING: $msg"
            return false
        }
        if {$offset_value < 0} {
            set msg "The $offset_name offset for '$pd_name' must be non-negative: $offset_value"
            if {$strict} { error $msg }
            puts "WARNING: $msg"
            return false
        }
    }

    set core_bbox [tt_pd_get_core_bbox $strict]
    if {$core_bbox eq ""} {
        return false
    }
    lassign $core_bbox core_llx core_lly core_urx core_ury

    set new_llx [expr {$core_llx + $left_offset}]
    set new_lly [expr {$core_lly + $bottom_offset}]
    set new_urx [expr {$core_urx - $right_offset}]
    set new_ury [expr {$core_ury - $top_offset}]
    set new_bbox [list $new_llx $new_lly $new_urx $new_ury]

    if {$new_llx >= $new_urx || $new_lly >= $new_ury} {
        set msg "Core offsets collapse or invert power domain '$pd_name': core=$core_bbox offsets={top $top_offset bottom $bottom_offset left $left_offset right $right_offset}"
        if {$strict} { error $msg }
        puts "WARNING: $msg"
        return false
    }

    puts "INFO: Reshaping power domain '$pd_name' from the core boundary."
    puts "INFO:   core bbox = $core_bbox"
    puts "INFO:   offsets   = {top $top_offset bottom $bottom_offset left $left_offset right $right_offset}"
    puts "INFO:   new bbox  = $new_bbox"

    return [tt_pd_update_bbox $pd_name $new_bbox $strict]
}

proc tt_pd_bbox_for_dimensions {bbox new_width new_height {anchor center}} {
    lassign [tt_pd_normalize_bbox $bbox "resize source"] llx lly urx ury

    if {![string is double -strict $new_width] ||
        ![string is double -strict $new_height] ||
        $new_width <= 0 || $new_height <= 0} {
        error "New power-domain width and height must be positive numbers: width=$new_width height=$new_height"
    }

    set anchor [string tolower $anchor]
    switch -- $anchor {
        center {
            set cx [expr {($llx + $urx) / 2.0}]
            set cy [expr {($lly + $ury) / 2.0}]
            set new_llx [expr {$cx - $new_width  / 2.0}]
            set new_lly [expr {$cy - $new_height / 2.0}]
            set new_urx [expr {$cx + $new_width  / 2.0}]
            set new_ury [expr {$cy + $new_height / 2.0}]
        }
        lower_left {
            set new_llx $llx
            set new_lly $lly
            set new_urx [expr {$llx + $new_width}]
            set new_ury [expr {$lly + $new_height}]
        }
        lower_right {
            set new_llx [expr {$urx - $new_width}]
            set new_lly $lly
            set new_urx $urx
            set new_ury [expr {$lly + $new_height}]
        }
        upper_left {
            set new_llx $llx
            set new_lly [expr {$ury - $new_height}]
            set new_urx [expr {$llx + $new_width}]
            set new_ury $ury
        }
        upper_right {
            set new_llx [expr {$urx - $new_width}]
            set new_lly [expr {$ury - $new_height}]
            set new_urx $urx
            set new_ury $ury
        }
        default {
            error "Unsupported resize anchor '$anchor'. Use center, lower_left, lower_right, upper_left, or upper_right."
        }
    }

    return [list $new_llx $new_lly $new_urx $new_ury]
}

proc tt_pd_resize_to_dimensions {
    pd_name new_width new_height {anchor center} {strict true}
} {
    set old_bbox [tt_pd_get_bbox $pd_name $strict]
    if {$old_bbox eq ""} {
        return false
    }

    if {[catch {
        set new_bbox [tt_pd_bbox_for_dimensions $old_bbox $new_width $new_height $anchor]
    } err]} {
        if {$strict} { error $err }
        puts "WARNING: $err"
        return false
    }

    puts "INFO: Resizing power domain '$pd_name'."
    puts "INFO:   anchor   = $anchor"
    puts "INFO:   old bbox = $old_bbox"
    puts "INFO:   new size = {$new_width $new_height}"
    puts "INFO:   new bbox = $new_bbox"

    return [tt_pd_update_bbox $pd_name $new_bbox $strict]
}

# Resize width and height independently. This directly controls both size and
# aspect ratio. Example: width * width_scale, height * height_scale; center unchanged.
proc tt_pd_resize_by_scale {
    pd_name width_scale height_scale {anchor center} {strict true}
} {
    foreach {scale_name scale_value} [list width $width_scale height $height_scale] {
        if {![string is double -strict $scale_value] || $scale_value <= 0} {
            set msg "The $scale_name scale for '$pd_name' must be a positive number: $scale_value"
            if {$strict} { error $msg }
            puts "WARNING: $msg"
            return false
        }
    }

    set old_bbox [tt_pd_get_bbox $pd_name $strict]
    if {$old_bbox eq ""} {
        return false
    }
    lassign $old_bbox llx lly urx ury

    set old_width  [expr {$urx - $llx}]
    set old_height [expr {$ury - $lly}]
    set new_width  [expr {$old_width  * $width_scale}]
    set new_height [expr {$old_height * $height_scale}]

    return [tt_pd_resize_to_dimensions \
        $pd_name $new_width $new_height $anchor $strict]
}

# Set an exact width/height ratio.
# preserve values:
#   area   : preserve current area (default)
#   width  : preserve current width and change height
#   height : preserve current height and change width
proc tt_pd_set_aspect_ratio {
    pd_name width_to_height {preserve area} {anchor center} {strict true}
} {
    if {![string is double -strict $width_to_height] || $width_to_height <= 0} {
        set msg "The width/height ratio for '$pd_name' must be a positive number: $width_to_height"
        if {$strict} { error $msg }
        puts "WARNING: $msg"
        return false
    }

    set old_bbox [tt_pd_get_bbox $pd_name $strict]
    if {$old_bbox eq ""} {
        return false
    }
    lassign $old_bbox llx lly urx ury

    set old_width  [expr {$urx - $llx}]
    set old_height [expr {$ury - $lly}]
    set preserve [string tolower $preserve]

    switch -- $preserve {
        area {
            set area [expr {$old_width * $old_height}]
            set new_width  [expr {sqrt($area * $width_to_height)}]
            set new_height [expr {sqrt($area / $width_to_height)}]
        }
        width {
            set new_width  $old_width
            set new_height [expr {$old_width / $width_to_height}]
        }
        height {
            set new_height $old_height
            set new_width  [expr {$old_height * $width_to_height}]
        }
        default {
            set msg "Unsupported preserve mode '$preserve'. Use area, width, or height."
            if {$strict} { error $msg }
            puts "WARNING: $msg"
            return false
        }
    }

    puts "INFO: Setting power-domain aspect ratio:"
    puts "INFO:   power domain = $pd_name"
    puts "INFO:   ratio W/H    = $width_to_height"
    puts "INFO:   preserve     = $preserve"

    return [tt_pd_resize_to_dimensions \
        $pd_name $new_width $new_height $anchor $strict]
}

# -----------------------------------------------------------------------------
# Macro-only placement blockage along exposed Power Domain boundaries.
#
# The Power Domain may be composed of multiple rectangles. Internal rectangle
# seams are ignored; blockages are generated only on exposed union boundaries.
# The blockage is created inside the Power Domain so hard macros keep the
# requested top/bottom/left/right clearance while standard cells remain usable.
# -----------------------------------------------------------------------------
proc tt_pd_validate_boundary_widths {
    pd_name top_width bottom_width left_width right_width {strict true}
} {
    foreach {side value} [list \
        top $top_width \
        bottom $bottom_width \
        left $left_width \
        right $right_width] {
        if {![string is double -strict $value]} {
            set msg "The $side blockage width for '$pd_name' is not numeric: $value"
            if {$strict} { error $msg }
            puts "WARNING: $msg"
            return false
        }
        if {$value < 0} {
            set msg "The $side blockage width for '$pd_name' must be non-negative: $value"
            if {$strict} { error $msg }
            puts "WARNING: $msg"
            return false
        }
    }
    return true
}

# Return the portions of [base_start, base_end] that are not covered by the
# supplied intervals. Intervals are clipped, sorted, and merged first.
proc tt_pd_interval_subtract {base_start base_end covered_intervals {tol 1.0e-6}} {
    if {$base_end <= $base_start + $tol} {
        return {}
    }

    set clipped {}
    foreach interval $covered_intervals {
        if {[llength $interval] != 2} {
            continue
        }
        lassign $interval start end
        if {$start < $base_start} { set start $base_start }
        if {$end   > $base_end}   { set end   $base_end }
        if {$end > $start + $tol} {
            lappend clipped [list $start $end]
        }
    }

    if {[llength $clipped] == 0} {
        return [list [list $base_start $base_end]]
    }

    set clipped [lsort -real -index 0 $clipped]
    set merged {}
    foreach interval $clipped {
        lassign $interval start end
        if {[llength $merged] == 0} {
            lappend merged [list $start $end]
            continue
        }
        lassign [lindex $merged end] old_start old_end
        if {$start <= $old_end + $tol} {
            if {$end > $old_end} { set old_end $end }
            lset merged end [list $old_start $old_end]
        } else {
            lappend merged [list $start $end]
        }
    }

    set result {}
    set cursor $base_start
    foreach interval $merged {
        lassign $interval start end
        if {$start > $cursor + $tol} {
            lappend result [list $cursor $start]
        }
        if {$end > $cursor} {
            set cursor $end
        }
    }
    if {$cursor < $base_end - $tol} {
        lappend result [list $cursor $base_end]
    }
    return $result
}

proc tt_pd_rect_contains {outer inner {tol 1.0e-6}} {
    lassign $outer ollx olly ourx oury
    lassign $inner illx illy iurx iury
    return [expr {
        $ollx <= $illx + $tol &&
        $olly <= $illy + $tol &&
        $ourx >= $iurx - $tol &&
        $oury >= $iury - $tol
    }]
}

# Remove duplicate/contained rectangles and merge rectangles that form a
# larger rectangle without introducing area outside their union.
proc tt_pd_compact_rects {rects {tol 1.0e-6}} {
    set clean {}
    foreach rect $rects {
        if {[catch {set rect [tt_pd_normalize_bbox $rect "PD blockage rectangle"]}]} {
            continue
        }
        if {[lsearch -exact $clean $rect] < 0} {
            lappend clean $rect
        }
    }

    # Remove rectangles fully contained by another rectangle.
    set filtered {}
    for {set i 0} {$i < [llength $clean]} {incr i} {
        set rect_i [lindex $clean $i]
        set contained false
        for {set j 0} {$j < [llength $clean]} {incr j} {
            if {$i == $j} { continue }
            if {[tt_pd_rect_contains [lindex $clean $j] $rect_i $tol]} {
                set contained true
                break
            }
        }
        if {!$contained} {
            lappend filtered $rect_i
        }
    }
    set clean $filtered

    # Merge only when both rectangles share the same complete vertical or
    # horizontal span. This preserves the exact rectilinear union.
    set changed true
    while {$changed} {
        set changed false
        for {set i 0} {$i < [llength $clean] && !$changed} {incr i} {
            lassign [lindex $clean $i] a_llx a_lly a_urx a_ury
            for {set j [expr {$i + 1}]} {$j < [llength $clean]} {incr j} {
                lassign [lindex $clean $j] b_llx b_lly b_urx b_ury
                set merged ""

                # Same Y span: merge overlapping/abutting X intervals.
                if {abs($a_lly - $b_lly) <= $tol &&
                    abs($a_ury - $b_ury) <= $tol &&
                    $a_llx <= $b_urx + $tol &&
                    $b_llx <= $a_urx + $tol} {
                    set merged [list \
                        [expr {min($a_llx, $b_llx)}] $a_lly \
                        [expr {max($a_urx, $b_urx)}] $a_ury]
                # Same X span: merge overlapping/abutting Y intervals.
                } elseif {abs($a_llx - $b_llx) <= $tol &&
                          abs($a_urx - $b_urx) <= $tol &&
                          $a_lly <= $b_ury + $tol &&
                          $b_lly <= $a_ury + $tol} {
                    set merged [list \
                        $a_llx [expr {min($a_lly, $b_lly)}] \
                        $a_urx [expr {max($a_ury, $b_ury)}]]
                }

                if {$merged ne ""} {
                    set next {}
                    for {set k 0} {$k < [llength $clean]} {incr k} {
                        if {$k != $i && $k != $j} {
                            lappend next [lindex $clean $k]
                        }
                    }
                    lappend next $merged
                    set clean $next
                    set changed true
                    break
                }
            }
        }
    }
    return $clean
}

# Build inward macro-only blockage strips on the exposed boundary of the union
# of all rectangles belonging to one Power Domain.
proc tt_pd_inner_boundary_blockage_rects {
    pd_name top_width bottom_width left_width right_width {strict true}
} {
    if {![tt_pd_validate_boundary_widths \
        $pd_name $top_width $bottom_width $left_width $right_width $strict]} {
        return {}
    }

    set group [tt_pd_get_group $pd_name]
    if {$group eq ""} {
        set msg "Cannot find a floorplan group for power domain '$pd_name'."
        if {$strict} { error $msg }
        puts "WARNING: $msg"
        return {}
    }

    set raw_rects [get_db $group .rects]
    if {$raw_rects eq "" || [llength $raw_rects] == 0} {
        set msg "Power domain '$pd_name' has no physical rectangles."
        if {$strict} { error $msg }
        puts "WARNING: $msg"
        return {}
    }

    set rects {}
    foreach rect $raw_rects {
        lappend rects [tt_pd_normalize_bbox $rect "power domain '$pd_name' rectangle"]
    }

    set tol 1.0e-6
    set blockage_rects {}

    for {set i 0} {$i < [llength $rects]} {incr i} {
        lassign [lindex $rects $i] llx lly urx ury

        set top_covered {}
        set bottom_covered {}
        set left_covered {}
        set right_covered {}

        for {set j 0} {$j < [llength $rects]} {incr j} {
            if {$i == $j} { continue }
            lassign [lindex $rects $j] o_llx o_lly o_urx o_ury

            set overlap_x1 [expr {max($llx, $o_llx)}]
            set overlap_x2 [expr {min($urx, $o_urx)}]
            if {$overlap_x2 > $overlap_x1 + $tol} {
                # Probe immediately outside the top/bottom edge. A neighboring
                # rectangle covering the probe means this edge portion is an
                # internal seam, not an exposed Power Domain boundary.
                if {$o_lly <= $ury + $tol && $o_ury > $ury + $tol} {
                    lappend top_covered [list $overlap_x1 $overlap_x2]
                }
                if {$o_lly < $lly - $tol && $o_ury >= $lly - $tol} {
                    lappend bottom_covered [list $overlap_x1 $overlap_x2]
                }
            }

            set overlap_y1 [expr {max($lly, $o_lly)}]
            set overlap_y2 [expr {min($ury, $o_ury)}]
            if {$overlap_y2 > $overlap_y1 + $tol} {
                if {$o_llx < $llx - $tol && $o_urx >= $llx - $tol} {
                    lappend left_covered [list $overlap_y1 $overlap_y2]
                }
                if {$o_llx <= $urx + $tol && $o_urx > $urx + $tol} {
                    lappend right_covered [list $overlap_y1 $overlap_y2]
                }
            }
        }

        if {$top_width > $tol} {
            set strip_lly [expr {$ury - $top_width}]
            if {$strip_lly < $lly} { set strip_lly $lly }
            foreach segment [tt_pd_interval_subtract $llx $urx $top_covered $tol] {
                lassign $segment x1 x2
                lappend blockage_rects [list $x1 $strip_lly $x2 $ury]
            }
        }

        if {$bottom_width > $tol} {
            set strip_ury [expr {$lly + $bottom_width}]
            if {$strip_ury > $ury} { set strip_ury $ury }
            foreach segment [tt_pd_interval_subtract $llx $urx $bottom_covered $tol] {
                lassign $segment x1 x2
                lappend blockage_rects [list $x1 $lly $x2 $strip_ury]
            }
        }

        if {$left_width > $tol} {
            set strip_urx [expr {$llx + $left_width}]
            if {$strip_urx > $urx} { set strip_urx $urx }
            foreach segment [tt_pd_interval_subtract $lly $ury $left_covered $tol] {
                lassign $segment y1 y2
                lappend blockage_rects [list $llx $y1 $strip_urx $y2]
            }
        }

        if {$right_width > $tol} {
            set strip_llx [expr {$urx - $right_width}]
            if {$strip_llx < $llx} { set strip_llx $llx }
            foreach segment [tt_pd_interval_subtract $lly $ury $right_covered $tol] {
                lassign $segment y1 y2
                lappend blockage_rects [list $strip_llx $y1 $urx $y2]
            }
        }
    }

    return [tt_pd_compact_rects $blockage_rects $tol]
}


# Backward-compatible internal name: the original PD_blk behavior was inner.
proc tt_pd_boundary_blockage_rects {
    pd_name top_width bottom_width left_width right_width {strict true}
} {
    return [tt_pd_inner_boundary_blockage_rects \
        $pd_name $top_width $bottom_width $left_width $right_width $strict]
}

proc tt_pd_rect_intersection {rect_a rect_b {tol 1.0e-6}} {
    lassign $rect_a a_llx a_lly a_urx a_ury
    lassign $rect_b b_llx b_lly b_urx b_ury
    set llx [expr {max($a_llx, $b_llx)}]
    set lly [expr {max($a_lly, $b_lly)}]
    set urx [expr {min($a_urx, $b_urx)}]
    set ury [expr {min($a_ury, $b_ury)}]
    if {$urx <= $llx + $tol || $ury <= $lly + $tol} {
        return ""
    }
    return [list $llx $lly $urx $ury]
}

# Subtract one rectangle from another. The result contains zero to four
# non-overlapping rectangles and exactly preserves the remaining area.
proc tt_pd_subtract_one_rect {base_rect cut_rect {tol 1.0e-6}} {
    set intersection [tt_pd_rect_intersection $base_rect $cut_rect $tol]
    if {$intersection eq ""} {
        return [list $base_rect]
    }

    lassign $base_rect b_llx b_lly b_urx b_ury
    lassign $intersection i_llx i_lly i_urx i_ury
    set result {}

    if {$i_llx > $b_llx + $tol} {
        lappend result [list $b_llx $b_lly $i_llx $b_ury]
    }
    if {$i_urx < $b_urx - $tol} {
        lappend result [list $i_urx $b_lly $b_urx $b_ury]
    }
    if {$i_lly > $b_lly + $tol} {
        lappend result [list $i_llx $b_lly $i_urx $i_lly]
    }
    if {$i_ury < $b_ury - $tol} {
        lappend result [list $i_llx $i_ury $i_urx $b_ury]
    }
    return $result
}

# Subtract the complete union of cutter rectangles from one base rectangle.
proc tt_pd_subtract_rect_union {base_rect cutter_rects {tol 1.0e-6}} {
    set pieces [list $base_rect]
    foreach cutter $cutter_rects {
        set next {}
        foreach piece $pieces {
            lappend next {*}[tt_pd_subtract_one_rect $piece $cutter $tol]
        }
        set pieces $next
        if {[llength $pieces] == 0} {
            break
        }
    }
    return $pieces
}

proc tt_pd_segment_touches_start {segments start_value {tol 1.0e-6}} {
    foreach segment $segments {
        if {abs([lindex $segment 0] - $start_value) <= $tol} {
            return true
        }
    }
    return false
}

proc tt_pd_segment_touches_end {segments end_value {tol 1.0e-6}} {
    foreach segment $segments {
        if {abs([lindex $segment 1] - $end_value) <= $tol} {
            return true
        }
    }
    return false
}

# Build outward macro-only blockage strips on the exposed boundary of the
# rectangle union. Generated rectangles are clipped to the core and the PD
# union is subtracted, so the outer blockage never consumes area inside the
# target Power Domain. Corner rectangles are included to form a full halo.
proc tt_pd_outer_boundary_blockage_rects {
    pd_name top_width bottom_width left_width right_width {strict true}
} {
    if {![tt_pd_validate_boundary_widths \
        $pd_name $top_width $bottom_width $left_width $right_width $strict]} {
        return {}
    }

    set group [tt_pd_get_group $pd_name]
    if {$group eq ""} {
        set msg "Cannot find a floorplan group for power domain '$pd_name'."
        if {$strict} { error $msg }
        puts "WARNING: $msg"
        return {}
    }

    set raw_rects [get_db $group .rects]
    if {$raw_rects eq "" || [llength $raw_rects] == 0} {
        set msg "Power domain '$pd_name' has no physical rectangles."
        if {$strict} { error $msg }
        puts "WARNING: $msg"
        return {}
    }

    set rects {}
    foreach rect $raw_rects {
        lappend rects [tt_pd_normalize_bbox $rect "power domain '$pd_name' rectangle"]
    }

    set core_bbox [tt_pd_get_core_bbox $strict]
    if {$core_bbox eq ""} {
        return {}
    }

    set tol 1.0e-6
    set candidates {}

    for {set i 0} {$i < [llength $rects]} {incr i} {
        lassign [lindex $rects $i] llx lly urx ury

        set top_covered {}
        set bottom_covered {}
        set left_covered {}
        set right_covered {}

        for {set j 0} {$j < [llength $rects]} {incr j} {
            if {$i == $j} { continue }
            lassign [lindex $rects $j] o_llx o_lly o_urx o_ury

            set overlap_x1 [expr {max($llx, $o_llx)}]
            set overlap_x2 [expr {min($urx, $o_urx)}]
            if {$overlap_x2 > $overlap_x1 + $tol} {
                if {$o_lly <= $ury + $tol && $o_ury > $ury + $tol} {
                    lappend top_covered [list $overlap_x1 $overlap_x2]
                }
                if {$o_lly < $lly - $tol && $o_ury >= $lly - $tol} {
                    lappend bottom_covered [list $overlap_x1 $overlap_x2]
                }
            }

            set overlap_y1 [expr {max($lly, $o_lly)}]
            set overlap_y2 [expr {min($ury, $o_ury)}]
            if {$overlap_y2 > $overlap_y1 + $tol} {
                if {$o_llx < $llx - $tol && $o_urx >= $llx - $tol} {
                    lappend left_covered [list $overlap_y1 $overlap_y2]
                }
                if {$o_llx <= $urx + $tol && $o_urx > $urx + $tol} {
                    lappend right_covered [list $overlap_y1 $overlap_y2]
                }
            }
        }

        set top_segments [tt_pd_interval_subtract $llx $urx $top_covered $tol]
        set bottom_segments [tt_pd_interval_subtract $llx $urx $bottom_covered $tol]
        set left_segments [tt_pd_interval_subtract $lly $ury $left_covered $tol]
        set right_segments [tt_pd_interval_subtract $lly $ury $right_covered $tol]

        if {$top_width > $tol} {
            foreach segment $top_segments {
                lassign $segment x1 x2
                lappend candidates [list $x1 $ury $x2 [expr {$ury + $top_width}]]
            }
        }
        if {$bottom_width > $tol} {
            foreach segment $bottom_segments {
                lassign $segment x1 x2
                lappend candidates [list $x1 [expr {$lly - $bottom_width}] $x2 $lly]
            }
        }
        if {$left_width > $tol} {
            foreach segment $left_segments {
                lassign $segment y1 y2
                lappend candidates [list [expr {$llx - $left_width}] $y1 $llx $y2]
            }
        }
        if {$right_width > $tol} {
            foreach segment $right_segments {
                lassign $segment y1 y2
                lappend candidates [list $urx $y1 [expr {$urx + $right_width}] $y2]
            }
        }

        # Fill the four diagonal corner areas when both adjacent exposed edges
        # reach the corner. This prevents a hard macro from approaching the PD
        # diagonally through an otherwise unblocked corner square.
        if {$top_width > $tol && $left_width > $tol &&
            [tt_pd_segment_touches_start $top_segments $llx $tol] &&
            [tt_pd_segment_touches_end $left_segments $ury $tol]} {
            lappend candidates [list \
                [expr {$llx - $left_width}] $ury \
                $llx [expr {$ury + $top_width}]]
        }
        if {$top_width > $tol && $right_width > $tol &&
            [tt_pd_segment_touches_end $top_segments $urx $tol] &&
            [tt_pd_segment_touches_end $right_segments $ury $tol]} {
            lappend candidates [list \
                $urx $ury \
                [expr {$urx + $right_width}] [expr {$ury + $top_width}]]
        }
        if {$bottom_width > $tol && $left_width > $tol &&
            [tt_pd_segment_touches_start $bottom_segments $llx $tol] &&
            [tt_pd_segment_touches_start $left_segments $lly $tol]} {
            lappend candidates [list \
                [expr {$llx - $left_width}] [expr {$lly - $bottom_width}] \
                $llx $lly]
        }
        if {$bottom_width > $tol && $right_width > $tol &&
            [tt_pd_segment_touches_end $bottom_segments $urx $tol] &&
            [tt_pd_segment_touches_start $right_segments $lly $tol]} {
            lappend candidates [list \
                $urx [expr {$lly - $bottom_width}] \
                [expr {$urx + $right_width}] $lly]
        }
    }

    set blockage_rects {}
    foreach candidate $candidates {
        set clipped [tt_pd_rect_intersection $candidate $core_bbox $tol]
        if {$clipped eq ""} {
            continue
        }
        # Outer means strictly outside the target PD. This subtraction is
        # important for concave/non-rectangular unions and nearby PD islands.
        lappend blockage_rects {*}[tt_pd_subtract_rect_union $clipped $rects $tol]
    }

    return [tt_pd_compact_rects $blockage_rects $tol]
}

proc tt_pd_blockage_base_name {pd_name {mode inner}} {
    set safe_name $pd_name
    regsub -all {[^[:alnum:]_]} $safe_name {_} safe_name
    set mode [string toupper $mode]
    return "PD_BLK_${mode}_${safe_name}"
}

# Delete only blockages generated by one PD_blk mode for this Power Domain.
proc tt_pd_delete_boundary_blockages_by_mode {pd_name mode {strict true}} {
    set mode [string tolower $mode]
    if {$mode ni {inner outer all}} {
        set msg "Unsupported PD blockage mode '$mode'. Use inner, outer, or all."
        if {$strict} { error $msg }
        puts "WARNING: $msg"
        return {}
    }

    if {[llength [info commands get_db]] == 0 ||
        [llength [info commands delete_obj]] == 0} {
        set msg "Innovus get_db/delete_obj commands are unavailable."
        if {$strict} { error $msg }
        puts "WARNING: $msg"
        return {}
    }

    set base_names {}
    if {$mode in {inner all}} {
        lappend base_names [tt_pd_blockage_base_name $pd_name inner]
        # Remove the name used by the original, unsplit PD_blk implementation.
        set safe_name $pd_name
        regsub -all {[^[:alnum:]_]} $safe_name {_} safe_name
        lappend base_names "PD_BLK_${safe_name}"
    }
    if {$mode in {outer all}} {
        lappend base_names [tt_pd_blockage_base_name $pd_name outer]
    }

    # A numeric PD suffix can resemble a legacy rectangle index. Protect
    # names belonging to other physical domains before matching our suffixes.
    set other_bases {}
    set groups {}
    catch { set groups [get_db groups] }
    foreach group $groups {
        set other_pd ""
        catch { set other_pd [get_db $group .power_domain.name] }
        if {$other_pd eq "" || $other_pd eq "NULL" || $other_pd eq $pd_name} { continue }
        foreach other_mode {inner outer} {
            set other_base [tt_pd_blockage_base_name $other_pd $other_mode]
            if {[lsearch -exact $base_names $other_base] >= 0} {
                error "PD blockage name collision between '$pd_name' and '$other_pd'; existing blockages were preserved."
            }
            lappend other_bases $other_base
        }
    }
    set deleted {}
    set blockages {}
    catch { set blockages [get_db place_blockages] }
    foreach blockage $blockages {
        set name ""
        catch { set name [get_db $blockage .name] }
        set belongs_to_other_pd false
        foreach other_base $other_bases {
            set other_suffix [string range $name [expr {[string length $other_base] + 1}] end]
            if {$name eq $other_base ||
                ([string first "${other_base}_" $name] == 0 && [regexp {^[0-9]+$} $other_suffix])} {
                set belongs_to_other_pd true
                break
            }
        }
        if {$belongs_to_other_pd} { continue }
        foreach base_name $base_names {
            set legacy_suffix [string range $name [expr {[string length $base_name] + 1}] end]
            if {$name eq $base_name ||
                ([string first "${base_name}_" $name] == 0 &&
                 [regexp {^[0-9]+$} $legacy_suffix])} {
                delete_obj $blockage
                lappend deleted $name
                break
            }
        }
    }
    if {[llength $deleted] > 0} {
        puts "INFO: Removed previous PD_blk $mode blockage(s) for '$pd_name': $deleted"
    }
    return $deleted
}

# Backward-compatible internal deletion: old PD_blk meant inner.
proc tt_pd_delete_boundary_blockages {pd_name {strict true}} {
    return [tt_pd_delete_boundary_blockages_by_mode $pd_name inner $strict]
}

proc tt_pd_create_boundary_macro_blockage_by_mode {
    pd_name mode top_width bottom_width left_width right_width {strict true}
} {
    set mode [string tolower $mode]
    switch -- $mode {
        inner {
            set rects [tt_pd_inner_boundary_blockage_rects \
                $pd_name $top_width $bottom_width $left_width $right_width $strict]
        }
        outer {
            set rects [tt_pd_outer_boundary_blockage_rects \
                $pd_name $top_width $bottom_width $left_width $right_width $strict]
        }
        default {
            set msg "Unsupported PD blockage mode '$mode'. Use inner or outer."
            if {$strict} { error $msg }
            puts "WARNING: $msg"
            return [dict create mode $mode name "" rects {}]
        }
    }

    # Re-running one mode replaces only its own previous blockage. Inner and
    # outer blockages can therefore coexist for the same Power Domain.
    tt_pd_delete_boundary_blockages_by_mode $pd_name $mode $strict

    if {[llength $rects] == 0} {
        puts "INFO: No PD_blk $mode rectangle created for '$pd_name'."
        puts "INFO: All four widths are zero, or no usable exposed boundary remains."
        return [dict create mode $mode name "" rects {}]
    }

    set base_name [tt_pd_blockage_base_name $pd_name $mode]
    puts "INFO: Creating $mode macro-only placement blockage for '$pd_name'."
    puts "INFO:   widths = {top $top_width bottom $bottom_width left $left_width right $right_width}"
    puts "INFO:   rects  = $rects"

    if {[llength [info commands create_place_blockage]] > 0} {
        if {[catch {
            create_place_blockage \
                -name $base_name \
                -type macro_only \
                -rects $rects
        } err]} {
            set msg "Failed to create macro-only blockage '$base_name' for '$pd_name': $err"
            if {$strict} { error $msg }
            puts "WARNING: $msg"
            return [dict create mode $mode name "" rects $rects]
        }
        return [dict create mode $mode name $base_name rects $rects]
    }

    # Legacy Innovus fallback: one macroOnly blockage per rectangle.
    if {[llength [info commands createPlaceBlockage]] > 0} {
        set names {}
        set index 0
        foreach rect $rects {
            set name "${base_name}_${index}"
            if {[catch {
                createPlaceBlockage -name $name -type macroOnly -box $rect
            } err]} {
                set msg "Failed to create legacy macroOnly blockage '$name': $err"
                if {$strict} { error $msg }
                puts "WARNING: $msg"
                return [dict create mode $mode name $names rects $rects]
            }
            lappend names $name
            incr index
        }
        return [dict create mode $mode name $names rects $rects]
    }

    set msg "Neither create_place_blockage nor createPlaceBlockage is available."
    if {$strict} { error $msg }
    puts "WARNING: $msg"
    return [dict create mode $mode name "" rects $rects]
}

# Backward-compatible internal creation: old PD_blk meant inner.
proc tt_pd_create_boundary_macro_blockage {
    pd_name top_width bottom_width left_width right_width {strict true}
} {
    return [tt_pd_create_boundary_macro_blockage_by_mode \
        $pd_name inner \
        $top_width $bottom_width $left_width $right_width $strict]
}

# -----------------------------------------------------------------------------
# Simplified public API
# -----------------------------------------------------------------------------
# Naming convention:
#   PD_merge   Merge all rectangles of the target PD into one bbox.
#   PD_base    Rebuild the target PD from current_design.core_bbox + offsets.
#   PD_reshape Change width/height by independent scale factors.
#   PD_size    Set an exact width and height.
#   PD_ratio   Set an exact width/height ratio.
#   PD_blk     Create inner or outer hard-macro boundary clearance.
#   PD_blk_inner  Keep hard macros inside the PD away from its boundary.
#   PD_blk_outer  Keep hard macros outside the PD away from its boundary.
#   PD_snap    Snap selected PDs; if none selected, snap all physical PDs.
#   PD_cut     Cut selected PDs; if none selected, cut all physical PDs.
#
# target may be:
#   PD_TOP
#   {PD_TOP PD_CPU}
#   selected
#
# Mouse examples:
#   select a PD in GUI, then run:
#       PD_merge
#       PD_base 20 20 10 10
#       PD_reshape $width_scale $height_scale
#       PD_ratio $width_to_height
#
# Explicit-name examples:
#       PD_merge PD_TOP
#       PD_base 20 20 10 10 PD_TOP
#       PD_reshape $width_scale $height_scale PD_CPU center
# -----------------------------------------------------------------------------
proc PD_targets {{target selected} {strict true}} {
    return [tt_pd_resolve_power_domains $target $strict]
}

proc PD_select {{strict true}} {
    return [tt_pd_get_selected_power_domains $strict]
}


proc PD_all {{strict true}} {
    return [tt_pd_get_all_power_domains $strict]
}

proc PD_core {{strict true}} {
    return [tt_pd_get_core_bbox $strict]
}

proc PD_bbox {{target selected} {strict true}} {
    set result [dict create]
    foreach pd_name [PD_targets $target $strict] {
        set bbox [tt_pd_get_bbox $pd_name $strict]
        if {$bbox ne ""} {
            dict set result $pd_name $bbox
        }
    }
    return $result
}

proc PD_merge {{target selected} {strict true}} {
    set pd_names [PD_targets $target $strict]
    foreach pd_name $pd_names {
        tt_pd_reshape_to_bbox $pd_name $strict
    }
    return $pd_names
}

proc PD_base {
    top_offset bottom_offset left_offset right_offset
    {target selected} {strict true}
} {
    set pd_names [PD_targets $target $strict]
    foreach pd_name $pd_names {
        tt_pd_reshape_to_core_offsets \
            $pd_name \
            $top_offset $bottom_offset $left_offset $right_offset \
            $strict
    }
    return $pd_names
}

proc PD_reshape {
    width_scale height_scale
    {target selected} {anchor center} {strict true}
} {
    set pd_names [PD_targets $target $strict]
    foreach pd_name $pd_names {
        tt_pd_resize_by_scale \
            $pd_name $width_scale $height_scale $anchor $strict
    }
    return $pd_names
}

proc PD_size {
    new_width new_height
    {target selected} {anchor center} {strict true}
} {
    set pd_names [PD_targets $target $strict]
    foreach pd_name $pd_names {
        tt_pd_resize_to_dimensions \
            $pd_name $new_width $new_height $anchor $strict
    }
    return $pd_names
}

proc PD_ratio {
    width_to_height
    {target selected} {preserve area} {anchor center} {strict true}
} {
    set pd_names [PD_targets $target $strict]
    foreach pd_name $pd_names {
        tt_pd_set_aspect_ratio \
            $pd_name $width_to_height $preserve $anchor $strict
    }
    return $pd_names
}

proc tt_pd_public_blockage {
    mode top_width bottom_width left_width right_width
    {target selected} {strict true}
} {
    set pd_names [PD_targets $target $strict]
    set result [dict create]
    foreach pd_name $pd_names {
        dict set result $pd_name [tt_pd_create_boundary_macro_blockage_by_mode \
            $pd_name $mode \
            $top_width $bottom_width $left_width $right_width \
            $strict]
    }
    return $result
}

proc PD_blk_inner {
    top_width bottom_width left_width right_width
    {target selected} {strict true}
} {
    return [tt_pd_public_blockage inner \
        $top_width $bottom_width $left_width $right_width $target $strict]
}

proc PD_blk_outer {
    top_width bottom_width left_width right_width
    {target selected} {strict true}
} {
    return [tt_pd_public_blockage outer \
        $top_width $bottom_width $left_width $right_width $target $strict]
}

# Preferred syntax:
#   PD_blk inner 20 20 10 10 PD_TOP
#   PD_blk outer 20 20 10 10 PD_TOP
#
# Backward compatibility:
#   PD_blk 20 20 10 10 PD_TOP
# is interpreted as PD_blk inner 20 20 10 10 PD_TOP.
proc PD_blk {args} {
    set argc [llength $args]
    if {$argc == 0} {
        error "Usage: PD_blk <inner|outer> top bottom left right ?PD|selected|all? ?strict?"
    }

    set first [string tolower [lindex $args 0]]
    if {$first in {inner outer}} {
        if {$argc < 5 || $argc > 7} {
            error "Usage: PD_blk $first top bottom left right ?PD|selected|all? ?strict?"
        }
        set mode $first
        set top_width [lindex $args 1]
        set bottom_width [lindex $args 2]
        set left_width [lindex $args 3]
        set right_width [lindex $args 4]
        set target selected
        set strict true
        if {$argc >= 6} { set target [lindex $args 5] }
        if {$argc >= 7} { set strict [lindex $args 6] }
    } else {
        if {$argc < 4 || $argc > 6} {
            error "Usage: PD_blk <inner|outer> top bottom left right ?PD|selected|all? ?strict?"
        }
        set mode inner
        set top_width [lindex $args 0]
        set bottom_width [lindex $args 1]
        set left_width [lindex $args 2]
        set right_width [lindex $args 3]
        set target selected
        set strict true
        if {$argc >= 5} { set target [lindex $args 4] }
        if {$argc >= 6} { set strict [lindex $args 5] }
    }

    return [tt_pd_public_blockage $mode \
        $top_width $bottom_width $left_width $right_width $target $strict]
}

proc PD_snap {{target auto} {strict true}} {
    if {[llength [info commands snap_power_domain_rect_to_grid]] == 0} {
        set msg "Cannot load snap_power_domain_rect_to_grid from TT_proc_pd_geometry.tcl."
        if {$strict} { error $msg }
        puts "WARNING: $msg"
        return {}
    }

    if {[string equal -nocase [string trim $target] "auto"]} {
        set pd_names [tt_pd_get_selected_or_all_power_domains $strict]
    } else {
        set pd_names [PD_targets $target $strict]
    }

    foreach pd_name $pd_names {
        if {[catch {snap_power_domain_rect_to_grid $pd_name} err]} {
            if {$strict} { error $err }
            puts "WARNING: Failed to snap '$pd_name': $err"
        }
    }
    return $pd_names
}

proc PD_cut {{target auto} {strict true}} {
    if {[string equal -nocase [string trim $target] "auto"]} {
        set pd_names [tt_pd_get_selected_or_all_power_domains $strict]
    } else {
        set pd_names [PD_targets $target $strict]
    }

    foreach pd_name $pd_names {
        tt_pd_cut_overlaps $pd_name $strict
    }
    return $pd_names
}

# -----------------------------------------------------------------------------
# Convenience wrappers for GUI mouse-selected power domains.
# Select one or more power-domain regions/groups in the GUI, then call one of
# these procedures from the Innovus Command Console.
# -----------------------------------------------------------------------------
proc tt_pd_reshape_selected_to_bbox {{strict true}} {
    set pd_names [tt_pd_get_selected_power_domains $strict]
    foreach pd_name $pd_names {
        tt_pd_reshape_to_bbox $pd_name $strict
    }
    return $pd_names
}

proc tt_pd_reshape_selected_to_core_offsets {
    top_offset bottom_offset left_offset right_offset {strict true}
} {
    set pd_names [tt_pd_get_selected_power_domains $strict]
    foreach pd_name $pd_names {
        tt_pd_reshape_to_core_offsets \
            $pd_name \
            $top_offset $bottom_offset $left_offset $right_offset \
            $strict
    }
    return $pd_names
}

proc tt_pd_resize_selected_to_dimensions {
    new_width new_height {anchor center} {strict true}
} {
    set pd_names [tt_pd_get_selected_power_domains $strict]
    foreach pd_name $pd_names {
        tt_pd_resize_to_dimensions \
            $pd_name $new_width $new_height $anchor $strict
    }
    return $pd_names
}

proc tt_pd_resize_selected_by_scale {
    width_scale height_scale {anchor center} {strict true}
} {
    set pd_names [tt_pd_get_selected_power_domains $strict]
    foreach pd_name $pd_names {
        tt_pd_resize_by_scale \
            $pd_name $width_scale $height_scale $anchor $strict
    }
    return $pd_names
}

proc tt_pd_set_selected_aspect_ratio {
    width_to_height {preserve area} {anchor center} {strict true}
} {
    set pd_names [tt_pd_get_selected_power_domains $strict]
    foreach pd_name $pd_names {
        tt_pd_set_aspect_ratio \
            $pd_name $width_to_height $preserve $anchor $strict
    }
    return $pd_names
}

proc tt_pd_cut_selected_overlaps {{strict true}} {
    set pd_names [tt_pd_get_selected_power_domains $strict]
    foreach pd_name $pd_names {
        tt_pd_cut_overlaps $pd_name $strict
    }
    return $pd_names
}

proc tt_pd_cut_overlaps {pd_name {strict true}} {
    if {[llength [info commands cut_power_domain_by_overlaps]] == 0} {
        set msg "Innovus command 'cut_power_domain_by_overlaps' is unavailable."
        if {$strict} { error $msg }
        puts "WARNING: $msg"
        return false
    }
    puts "INFO: Cutting overlapping regions from power domain '$pd_name'."
    cut_power_domain_by_overlaps $pd_name
    return true
}

# -----------------------------------------------------------------------------
# User help
# -----------------------------------------------------------------------------
proc PD_help {} {
    puts ""
    puts "======================================================================"
    puts " Power Domain Commands"
    puts "======================================================================"
    puts "PD_help"
    puts "  Show this help."
    puts ""
    puts "PD_select"
    puts "  Return Power Domains selected with the mouse."
    puts ""
    puts "PD_all"
    puts "  Return all Power Domains that have physical floorplan rectangles."
    puts ""
    puts "PD_core"
    puts "  Return get_db current_design .core_bbox."
    puts ""
    puts "PD_bbox ?PD?"
    puts "  Return the bbox of a named or mouse-selected Power Domain."
    puts ""
    puts "PD_merge ?PD?"
    puts "  Merge all rectangles of a PD into one enclosing bbox."
    puts ""
    puts "PD_base top bottom left right ?PD?"
    puts "  Rebuild a PD from the core bbox with inward edge offsets."
    puts "  Example: PD_base 10 10 10 10 PD_TOP"
    puts ""
    puts "PD_reshape width_scale height_scale ?PD? ?anchor?"
    puts "  Resize width and height by independent scale factors."
    puts "  Example: PD_reshape 1.20 0.80 PD_CPU center"
    puts ""
    puts "PD_size width height ?PD? ?anchor?"
    puts "  Set an exact width and height."
    puts ""
    puts "PD_ratio W_over_H ?PD? ?preserve? ?anchor?"
    puts "  Set the width/height ratio. preserve = area, width, or height."
    puts ""
    puts "PD_blk <inner|outer> top bottom left right ?PD|selected|all?"
    puts "  Create a macro_only placement blockage along exposed PD boundaries."
    puts "  inner: blockage is inside the PD; keeps internal hard macros away."
    puts "  outer: blockage is outside the PD; keeps external hard macros away."
    puts "  Non-rectangular PD internal seams are ignored."
    puts "  Outer blockage is clipped to the core and excludes the target PD area."
    puts "  Inner and outer blockages can coexist and are replaced independently."
    puts "  Four zero widths remove only the selected inner/outer blockage."
    puts "  Examples:"
    puts "    PD_blk inner 20 20 10 10 PD_TOP"
    puts "    PD_blk outer 30 30 15 15 PD_TOP"
    puts "    PD_blk_inner 20 20 10 10 PD_TOP"
    puts "    PD_blk_outer 30 30 15 15 PD_TOP"
    puts "  Mouse example: select a PD, then run PD_blk inner 20 20 10 10"
    puts "  Legacy syntax PD_blk 20 20 10 10 PD_TOP still means inner."
    puts ""
    puts "PD_snap ?PD|selected|all?"
    puts "  Snap PD rectangles to the FinFET instance grid."
    puts "  Default behavior with no argument:"
    puts "    - GUI Power Domain selected -> operate on selected PD(s)"
    puts "    - nothing selected          -> operate on all physical PDs"
    puts "  Examples: PD_snap ; PD_snap PD_TOP ; PD_snap selected"
    puts ""
    puts "PD_cut ?PD|selected|all?"
    puts "  Run cut_power_domain_by_overlaps."
    puts "  Default behavior with no argument:"
    puts "    - GUI Power Domain selected -> operate on selected PD(s)"
    puts "    - nothing selected          -> operate on all physical PDs"
    puts "  Examples: PD_cut ; PD_cut PD_TOP ; PD_cut selected"
    puts ""
    puts "Target notes:"
    puts "  Omit PD name for mouse selection on most commands."
    puts "  For PD_snap/PD_cut only, no selection defaults to all physical PDs."
    puts "======================================================================"
    puts ""
}



# ===== FinFET-grid snap procedures (merged) =====
# ============================================================
# Snap Power Domain Group Rects to FinFET Instance Grid
# For Innovus 21.19
# ============================================================
#
# Usage:
#   source [file join $TOOL_DIR 01_floorplan geometry TT_proc_pd_geometry.tcl]
#
#   snap_power_domain_rect_to_grid PD_CPU
#   snap_power_domain_rect_to_grid PD_WDT
#   snap_power_domain_rect_to_grid PD_CPU_ALWY_ON
#
# Or snap selected power domain/group:
#   snap_selected_power_domain_rect_to_grid
#
# ============================================================


# ------------------------------------------------------------
# Snap one coordinate to grid
# value  : original coordinate
# origin : grid origin
# pitch  : grid pitch
# ------------------------------------------------------------
proc tt_pd_normalize_finfet_grid {grid} {
    # Innovus may return:
    #   llx lly urx ury
    # or:
    #   {llx lly urx ury}
    #
    # Use the existing recursive numeric parser so representation differences
    # cannot be mistaken for legal geometry.
    set values [tt_pd_bbox_numeric_tokens \
        $grid "floorplan_finfet_inst_grid"]

    if {[llength $values] != 4} {
        error "Invalid floorplan_finfet_inst_grid: $grid"
    }

    lassign $values x_origin y_origin x_pitch y_pitch

    if {$x_pitch <= 0.0 || $y_pitch <= 0.0} {
        error "Invalid FinFET instance-grid pitch: $values"
    }

    return [list $x_origin $y_origin $x_pitch $y_pitch]
}

proc tt_value_is_on_grid {value origin pitch {tol 1.0e-8}} {
    if {$pitch == 0} {
        return false
    }

    set q [expr {($value - $origin) / $pitch}]
    set nearest [expr {round($q)}]
    return [expr {abs($q - $nearest) <= $tol}]
}

proc snap_value_to_grid {value origin pitch} {
    if {$pitch == 0} {
        puts "ERROR: pitch is 0. Please check floorplan_finfet_inst_grid."
        return $value
    }

    # Preserve the exact original coordinate when it is already legal.
    # This avoids rewriting a legal value only because of formatting/rounding.
    if {[tt_value_is_on_grid $value $origin $pitch]} {
        return $value
    }

    set snapped [expr {$origin + round(($value - $origin) / $pitch) * $pitch}]
    return [format "%.6f" $snapped]
}

proc tt_bbox_same_numeric {bbox_a bbox_b {tol 1.0e-9}} {
    if {[llength $bbox_a] != 4 || [llength $bbox_b] != 4} {
        return false
    }

    for {set i 0} {$i < 4} {incr i} {
        set a [lindex $bbox_a $i]
        set b [lindex $bbox_b $i]
        if {[expr {abs($a - $b)}] > $tol} {
            return false
        }
    }
    return true
}

proc tt_bbox_is_on_finfet_grid {bbox grid} {
    set bbox [tt_pd_normalize_bbox $bbox "Power-Domain rectangle"]
    set grid [tt_pd_normalize_finfet_grid $grid]

    lassign $bbox llx lly urx ury
    lassign $grid x_origin y_origin x_pitch y_pitch

    return [expr {
        [tt_value_is_on_grid $llx $x_origin $x_pitch] &&
        [tt_value_is_on_grid $lly $y_origin $y_pitch] &&
        [tt_value_is_on_grid $urx $x_origin $x_pitch] &&
        [tt_value_is_on_grid $ury $y_origin $y_pitch]
    }]
}


# ------------------------------------------------------------
# Snap one bbox to FinFET instance grid
# bbox format: {llx lly urx ury}
# grid format: {x_origin y_origin x_pitch y_pitch}
# ------------------------------------------------------------
proc snap_bbox_to_finfet_grid {bbox} {
    set raw_grid [get_db floorplan_finfet_inst_grid]
    set grid [tt_pd_normalize_finfet_grid $raw_grid]
    lassign $grid x_origin y_origin x_pitch y_pitch

    set bbox [tt_pd_normalize_bbox $bbox "Power-Domain rectangle"]
    lassign $bbox llx lly urx ury

    set new_llx [snap_value_to_grid $llx $x_origin $x_pitch]
    set new_lly [snap_value_to_grid $lly $y_origin $y_pitch]
    set new_urx [snap_value_to_grid $urx $x_origin $x_pitch]
    set new_ury [snap_value_to_grid $ury $y_origin $y_pitch]

    return [list $new_llx $new_lly $new_urx $new_ury]
}


# ------------------------------------------------------------
# Get bbox from rect object
# rect object usually has llx/lly/urx/ury attributes
# ------------------------------------------------------------
proc get_bbox_from_rect_obj {rect_obj} {
    set llx ""
    set lly ""
    set urx ""
    set ury ""

    set llx [lindex $rect_obj 0]
    set lly [lindex $rect_obj 1]
    set urx [lindex $rect_obj 2]
    set ury [lindex $rect_obj 3]

    if {$llx eq "" || $lly eq "" || $urx eq "" || $ury eq ""} {
        puts "ERROR: Cannot get llx/lly/urx/ury from rect object: $rect_obj"
        return ""
    }

    return [list $llx $lly $urx $ury]
}


# ------------------------------------------------------------
# Find group object by power domain name
# Example:
#   PD_CPU -> group whose .power_domain.name == PD_CPU
# ------------------------------------------------------------
proc get_group_by_power_domain {pd_name} {
    set grp [get_db groups -if ".power_domain.name == $pd_name"]

    if {$grp eq ""} {
        puts "ERROR: Cannot find group for power domain: $pd_name"
        puts "Try checking:"
        puts "  get_db groups .name"
        puts "  get_db groups .power_domain.name"
        return ""
    }

    return $grp
}


# ------------------------------------------------------------
# Main function:
# Snap one power domain's group rects and update floorplan object
# ------------------------------------------------------------
proc snap_power_domain_rect_to_grid {pd_name} {
    puts "============================================================"
    puts "Processing power domain: $pd_name"

    set raw_grid [get_db floorplan_finfet_inst_grid]
    set grid [tt_pd_normalize_finfet_grid $raw_grid]
    puts "FinFET instance grid (raw)        = $raw_grid"
    puts "FinFET instance grid (normalized) = $grid"

    set grp [get_group_by_power_domain $pd_name]

    if {$grp eq ""} {
        return
    }

    puts "Group object = $grp"
    puts "Group name   = [get_db $grp .name]"

    set rects [get_db $grp .rects]

    if {$rects eq "" || [llength $rects] == 0} {
        puts "ERROR: No rects found for power domain: $pd_name"
        return
    }

    puts "Original rect objects = $rects"

    set new_rects {}
    set changed_rect_count 0
    set aligned_rect_count 0

    foreach rect_obj $rects {
        set old_bbox [get_bbox_from_rect_obj $rect_obj]

        if {$old_bbox eq ""} {
            puts "WARNING: Skip invalid rect object: $rect_obj"
            continue
        }

        if {[catch {
            set new_bbox [snap_bbox_to_finfet_grid $old_bbox]
        } snap_err]} {
            error "PD_snap failed for $pd_name bbox {$old_bbox}: $snap_err"
        }

        puts "Old bbox = $old_bbox"
        puts "New bbox = $new_bbox"

        if {[tt_bbox_same_numeric $old_bbox $new_bbox]} {
            incr aligned_rect_count
            puts "Grid status = ALIGNED; preserve exact coordinates."
        } else {
            incr changed_rect_count
            puts "Grid status = OFF-GRID; correction is required."
        }

        lappend new_rects $new_bbox
    }

    if {[llength $new_rects] == 0} {
        puts "ERROR: No valid snapped rect generated for $pd_name"
        return [dict create changed false reason no_valid_rect]
    }

    puts "Final new rects = $new_rects"
    puts "Aligned rects   = $aligned_rect_count"
    puts "Changed rects   = $changed_rect_count"

    # Hard no-op guard:
    # Do NOT call update_floorplan_obj when every rectangle is already legal.
    # Even a numerically identical update can cause Innovus to normalize the
    # group geometry, so skipping the command is intentional.
    if {$changed_rect_count == 0} {
        puts "INFO: $pd_name is already aligned to the FinFET instance grid."
        puts "INFO: NO-OP: update_floorplan_obj was not called."
        puts "Done: $pd_name (NO-OP)"
        return [dict create \
            changed false \
            reason already_aligned \
            aligned_rects $aligned_rect_count \
            changed_rects 0]
    }

    # If only one rect, pass flat bbox.
    # If multiple rects, pass list of bboxes.
    if {[llength $new_rects] == 1} {
        set rect_to_update [lindex $new_rects 0]

        puts "Running:"
        puts "  update_floorplan_obj -obj $pd_name -rects {$rect_to_update}"

        update_floorplan_obj \
            -obj $pd_name \
            -rects $rect_to_update
    } else {
        puts "Running:"
        puts "  update_floorplan_obj -obj $pd_name -rects {$new_rects}"

        update_floorplan_obj \
            -obj $pd_name \
            -rects $new_rects
    }

    # Read back the actual geometry. Never report success until every resulting
    # rectangle is verified on the FinFET instance grid.
    set verify_grp [get_group_by_power_domain $pd_name]
    if {$verify_grp eq ""} {
        error "PD_snap verification failed: cannot re-read group for $pd_name."
    }

    set verify_rects [get_db $verify_grp .rects]
    if {$verify_rects eq "" || [llength $verify_rects] == 0} {
        error "PD_snap verification failed: no rectangles found after updating $pd_name."
    }

    set verify_failures {}
    foreach verify_rect $verify_rects {
        set verify_bbox [get_bbox_from_rect_obj $verify_rect]
        if {$verify_bbox eq ""} {
            lappend verify_failures "<invalid rect: $verify_rect>"
            continue
        }
        if {![tt_bbox_is_on_finfet_grid $verify_bbox $grid]} {
            lappend verify_failures $verify_bbox
        }
    }

    if {[llength $verify_failures] > 0} {
        error "PD_snap verification failed for $pd_name. Off-grid rects remain: $verify_failures"
    }

    puts "INFO: PD_snap verification PASS: every $pd_name rectangle is on the FinFET instance grid."
    puts "Done: $pd_name (UPDATED)"
    return [dict create \
        changed true \
        reason off_grid \
        aligned_rects $aligned_rect_count \
        changed_rects $changed_rect_count \
        verified true]
}


# ------------------------------------------------------------
# Snap selected object
# If selected object is power domain/group name, use its name.
# ------------------------------------------------------------
proc snap_selected_power_domain_rect_to_grid {{strict true}} {
    set selected_names [tt_pd_get_selected_power_domains $strict]
    foreach pd_name $selected_names {
        snap_power_domain_rect_to_grid $pd_name
    }
    return $selected_names
}


# ------------------------------------------------------------
# Snap a list of power domains
# ------------------------------------------------------------
proc snap_power_domain_list_to_grid {pd_list} {
    foreach pd_name $pd_list {
        snap_power_domain_rect_to_grid $pd_name
    }
}


# ============================================================
# Example Usage
# ============================================================

# Method 1:
# Select PD_CPU / PD_WDT / PD_CPU_ALWY_ON in GUI, then run:
# snap_selected_power_domain_rect_to_grid

# Method 2:
# Manually specify one power domain:
# snap_power_domain_rect_to_grid PD_CPU

# Method 3:
# Manually specify multiple power domains:
# snap_power_domain_list_to_grid {PD_CPU PD_WDT PD_CPU_ALWY_ON}


# ===== Legacy/manual simple-bbox helpers (merged) =====
# =============================================================================
# LEGACY / MANUAL Power-Domain BBox Helper
# =============================================================================
# NOTE:
#   The historical filename "TT_proc_pd_geometry.tcl" is intentionally preserved.
#   It is not referenced by the active flow.
#   Do not rename/remove it here because existing manual source commands may
#   still depend on this path.
#
# Active Power-Domain geometry utilities live in:
#   TT_proc_pd_geometry.tcl
#   pd_reshape_flow.tcl
#   TT_proc_pd_geometry.tcl
# =============================================================================

# ============================================================
# Convert selected object's group rects into one simple bbox
# ============================================================

proc rects_to_simple_bbox {rects} {
    if {$rects eq "" || [llength $rects] == 0} {
        puts "ERROR: empty rect list"
        return ""
    }

    set first_rect [lindex $rects 0]

    set min_x [lindex $first_rect 0]
    set min_y [lindex $first_rect 1]
    set max_x [lindex $first_rect 2]
    set max_y [lindex $first_rect 3]

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

    return [list $min_x $min_y $max_x $max_y]
}


proc restore_selected_group_to_simple_rect {} {
    set sel [get_db selected]

    if {$sel eq ""} {
        puts "ERROR: No object selected."
        return
    }

    # Case 1: the selected object is an instance/object inside the group
    set group_name ""
    set rects ""

    catch {
        set group_name [get_db selected .group.name]
    }

    catch {
        set rects [get_db selected .group.rects]
    }

    # Case 2: the selected object is the group itself
    if {$group_name eq ""} {
        catch {
            set group_name [get_db selected .name]
        }
    }

    if {$rects eq ""} {
        catch {
            set rects [get_db selected .rects]
        }
    }

    if {$group_name eq ""} {
        puts "ERROR: Cannot get group name from selected object."
        return
    }

    if {$rects eq "" || [llength $rects] == 0} {
        puts "ERROR: Cannot get rects from selected object/group."
        return
    }

    set simple_rect [rects_to_simple_bbox $rects]

    if {$simple_rect eq ""} {
        puts "ERROR: Failed to create simple rect."
        return
    }

    puts "Selected group = $group_name"
    puts "Original rects = $rects"
    puts "Simple rect    = $simple_rect"

    update_floorplan_obj \
        -obj $group_name \
        -rects $simple_rect

    puts "Done: $group_name restored to simple rectangle."
}


