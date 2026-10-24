# Runtime adapter preserves the historical logical source path.
if {[info exists ::TECH_MV_RUNTIME_ROOT]} {
    info script [file join $::TECH_MV_RUNTIME_ROOT run/tool/05_route/drc/TT_DRC_fix_jog_to_jog.tcl]
}
# DRC_RULE_SPECIFIC_TOOL: named/configured DRC subtype selection is technology-dependent.
# DRC_RULE_REVIEW: Rule names, filters and repair logic are retained for manual planning.
# =============================================================================
# TT_DRC_fix_jog_to_jog.tcl
# =============================================================================
# Marker-driven temporary route-blockage repair for JogToJog spacing DRC.
#
# Design:
#   1. Read the CURRENT Innovus marker database.
#   2. Select markers whose .type or .subtype contains "JogToJog".
#   3. Resolve the marker routing layer.
#   4. Use EXACTLY the marker bbox (no margin / no expansion).
#   5. In apply mode, create a temporary route blockage on that layer.
#   6. Run route_eco ONCE for all created blockages.
#   7. Delete ONLY the temporary route blockages created by this invocation.
#
# Source safety:
#   - Sourcing this file only defines procedures and prints help.
#   - No database mutation occurs until:
#         TT_fix_jog_to_jog apply
#
# Commands:
#   TT_fix_jog_to_jog preview
#   TT_fix_jog_to_jog apply
#   TT_J2J_stats
#   TT_J2J_version
#
# Notes:
#   - preview is the default.
#   - PG routing is excluded from the temporary blockage with -except_pg_nets.
#   - No bbox padding is added. This is intentional for pin-access-sensitive DRC.
#   - apply does NOT automatically run check_drc after route_eco.
#   - If route-blockage creation fails, route_eco is NOT run.
#   - If route_eco fails, this tool still attempts to remove its temporary
#     route blockages before propagating the error.
# =============================================================================

set ::TT_J2J_VERSION "V1_0_EXACT_MARKER_BLK_ROUTE_ECO"
set ::TT_J2J_PREFIX  "TT_J2J_TMP"

# -----------------------------------------------------------------------------
# Safe DB helper
# -----------------------------------------------------------------------------
proc tt_j2j_get {obj attr {default ""}} {
    set value ""
    if {[catch {set value [get_db $obj $attr]}]} {
        return $default
    }
    if {$value eq ""} {
        return $default
    }
    return $value
}

# -----------------------------------------------------------------------------
# Normalize bbox to: {llx lly urx ury}
# Supports:
#   {llx lly urx ury}
#   {{llx lly} {urx ury}}
#   one extra list wrapper
# -----------------------------------------------------------------------------
proc tt_j2j_normalize_bbox {bbox} {
    set b $bbox

    # Strip harmless single-element wrappers.
    for {set i 0} {$i < 3} {incr i} {
        if {[catch {set n [llength $b]}]} {
            return ""
        }
        if {$n != 1} {
            break
        }
        set next [lindex $b 0]
        if {$next eq $b} {
            break
        }
        set b $next
    }

    if {[catch {set n [llength $b]}]} {
        return ""
    }

    if {$n == 2} {
        set p0 [lindex $b 0]
        set p1 [lindex $b 1]
        if {![catch {llength $p0}] && ![catch {llength $p1}] &&
            [llength $p0] == 2 && [llength $p1] == 2} {
            set b [concat $p0 $p1]
            set n 4
        }
    }

    if {$n != 4} {
        return ""
    }

    foreach v $b {
        if {![string is double -strict $v]} {
            return ""
        }
    }

    lassign $b llx lly urx ury
    if {$llx >= $urx || $lly >= $ury} {
        return ""
    }

    return [list $llx $lly $urx $ury]
}

# -----------------------------------------------------------------------------
# Normalize DRC type/subtype text for robust JogToJog matching.
# Example:
#   "JogToJog Spacing"     -> "jogtojogspacing"
#   "Metal_JogToJog..."    -> "metaljogtojog..."
# -----------------------------------------------------------------------------
proc tt_j2j_norm_text {s} {
    set s [string tolower [string trim $s]]
    return [string map {" " "" "_" "" "-" "" ":" "" "/" ""} $s]
}

proc tt_j2j_marker_is_target {marker} {
    set type    [tt_j2j_get $marker .type ""]
    set subtype [tt_j2j_get $marker .subtype ""]

    foreach text [list $type $subtype "$type $subtype"] {
        if {[string first "jogtojog" [tt_j2j_norm_text $text]] >= 0} {
            return 1
        }
    }
    return 0
}

# -----------------------------------------------------------------------------
# Resolve marker routing layer.
# First prefer marker.layer, then inspect marker.objects.
# Returns "" when no unambiguous routing layer can be determined.
# -----------------------------------------------------------------------------
proc tt_j2j_marker_layer {marker} {
    set layer [tt_j2j_get $marker .layer.name ""]
    if {$layer ne ""} {
        return $layer
    }

    set layer_obj [tt_j2j_get $marker .layer ""]
    if {$layer_obj ne ""} {
        set layer [tt_j2j_get $layer_obj .name ""]
        if {$layer ne ""} {
            return $layer
        }
    }

    set layers {}
    set objs [tt_j2j_get $marker .objects {}]

    foreach obj $objs {
        set olayer [tt_j2j_get $obj .layer.name ""]
        if {$olayer eq ""} {
            set o_layer_obj [tt_j2j_get $obj .layer ""]
            if {$o_layer_obj ne ""} {
                set olayer [tt_j2j_get $o_layer_obj .name ""]
            }
        }

        if {$olayer ne "" && [lsearch -exact $layers $olayer] < 0} {
            lappend layers $olayer
        }
    }

    if {[llength $layers] == 1} {
        return [lindex $layers 0]
    }

    return ""
}

proc tt_j2j_report_path {mode} {
    if {[info exists ::REPORT_DIR] && $::REPORT_DIR ne ""} {
        file mkdir $::REPORT_DIR
        return [file join $::REPORT_DIR "fix_jog_to_jog_${mode}.rpt"]
    }
    return "fix_jog_to_jog_${mode}.rpt"
}

# -----------------------------------------------------------------------------
# Find a route-blockage name that does not collide with an existing object.
# -----------------------------------------------------------------------------
proc tt_j2j_unique_blk_name {serial} {
    set base [format "%s_%04d" $::TT_J2J_PREFIX $serial]
    set name $base
    set suffix 0

    while {1} {
        set existing {}
        catch {set existing [get_db route_blockages $name]}
        if {[llength $existing] == 0} {
            return $name
        }
        incr suffix
        set name "${base}_${suffix}"
    }
}

# -----------------------------------------------------------------------------
# Create one exact marker-bbox route blockage.
# -----------------------------------------------------------------------------
proc tt_j2j_create_route_blk {layer bbox name} {
    set bbox [tt_j2j_normalize_bbox $bbox]
    if {$bbox eq ""} {
        error "TT_J2J: invalid bbox."
    }
    if {$layer eq ""} {
        error "TT_J2J: empty routing layer."
    }
    if {[llength [info commands create_route_blockage]] == 0} {
        error "TT_J2J: create_route_blockage is unavailable."
    }

    puts "TT JOG-TO-JOG TEMP ROUTE BLOCKAGE:"
    puts "  name  = $name"
    puts "  layer = $layer"
    puts "  bbox  = $bbox"

    return [create_route_blockage \
        -name $name \
        -layers [list $layer] \
        -rects [list $bbox] \
        -except_pg_nets]
}

# -----------------------------------------------------------------------------
# Remove only temporary blockages created by this invocation.
# -----------------------------------------------------------------------------
proc tt_j2j_delete_temp_route_blks {names} {
    set deleted 0
    set failed {}

    foreach name $names {
        set objs {}
        if {[catch {set objs [get_db route_blockages $name]} err]} {
            lappend failed [list $name "QUERY_FAIL: $err"]
            continue
        }

        if {[llength $objs] == 0} {
            puts "INFO: temp route blockage already absent: $name"
            continue
        }

        if {[catch {delete_obj $objs} err]} {
            lappend failed [list $name "DELETE_FAIL: $err"]
            continue
        }

        incr deleted
        puts "INFO: deleted temp route blockage: $name"
    }

    return [dict create deleted $deleted failed $failed]
}

# -----------------------------------------------------------------------------
# Marker statistics: useful when preview finds zero candidates.
# -----------------------------------------------------------------------------
proc TT_J2J_stats {} {
    set counts [dict create]
    set target 0

    foreach marker [get_db markers] {
        set type    [tt_j2j_get $marker .type "<none>"]
        set subtype [tt_j2j_get $marker .subtype "<none>"]
        set key "$type / $subtype"

        if {![dict exists $counts $key]} {
            dict set counts $key 0
        }
        dict incr counts $key

        if {[tt_j2j_marker_is_target $marker]} {
            incr target
        }
    }

    puts ""
    puts "======================================================================"
    puts " DRC MARKER STATISTICS"
    puts "======================================================================"

    foreach key [lsort [dict keys $counts]] {
        set tag ""
        if {[string first "jogtojog" [tt_j2j_norm_text $key]] >= 0} {
            set tag "  <-- TARGET"
        }
        puts [format "%-60s %6d%s" $key [dict get $counts $key] $tag]
    }

    puts "----------------------------------------------------------------------"
    puts "JogToJog target markers : $target"
    puts "======================================================================"
    puts ""

    return $target
}

# -----------------------------------------------------------------------------
# Main repair
# -----------------------------------------------------------------------------
proc TT_fix_jog_to_jog {{mode preview}} {
    set mode [string tolower [string trim $mode]]

    if {$mode ni {preview apply}} {
        error "Usage: TT_fix_jog_to_jog ?preview|apply?"
    }

    set report_file [tt_j2j_report_path $mode]
    set fp [open $report_file w]

    puts $fp "JogToJog Exact-Marker Temporary Route Blockage Repair"
    puts $fp "Version : $::TT_J2J_VERSION"
    puts $fp "Mode    : $mode"
    puts $fp ""

    set all_markers       0
    set target_markers    0
    set invalid_bbox      0
    set unresolved_layer  0
    set candidates        0
    set created           0
    set create_failures   0
    set temp_blk_names    {}
    set seen              [dict create]
    set serial            0

    foreach marker [get_db markers] {
        incr all_markers

        if {![tt_j2j_marker_is_target $marker]} {
            continue
        }
        incr target_markers

        set type    [tt_j2j_get $marker .type ""]
        set subtype [tt_j2j_get $marker .subtype ""]
        set bbox    [tt_j2j_normalize_bbox [tt_j2j_get $marker .bbox ""]]

        if {$bbox eq ""} {
            incr invalid_bbox
            puts $fp "SKIP invalid_bbox marker=$marker type={$type} subtype={$subtype}"
            continue
        }

        set layer [tt_j2j_marker_layer $marker]
        if {$layer eq ""} {
            incr unresolved_layer
            puts $fp "SKIP unresolved_layer marker=$marker type={$type} subtype={$subtype} bbox={$bbox}"
            continue
        }

        # Deduplicate identical DRC geometry on the same layer.
        set key "$layer|$bbox"
        if {[dict exists $seen $key]} {
            puts $fp "SKIP duplicate layer=$layer bbox={$bbox}"
            continue
        }
        dict set seen $key 1

        incr candidates

        puts $fp "CANDIDATE marker=$marker"
        puts $fp "  type    = $type"
        puts $fp "  subtype = $subtype"
        puts $fp "  layer   = $layer"
        puts $fp "  bbox    = $bbox"

        if {$mode eq "preview"} {
            continue
        }

        incr serial
        set blk_name [tt_j2j_unique_blk_name $serial]

        if {[catch {
            tt_j2j_create_route_blk $layer $bbox $blk_name
        } err]} {
            incr create_failures
            puts $fp "  CREATE_FAIL name=$blk_name error={$err}"
            puts "ERROR: failed to create $blk_name: $err"
            continue
        }

        lappend temp_blk_names $blk_name
        incr created
        puts $fp "  CREATED = $blk_name"
    }

    puts $fp ""
    puts $fp "======================================================================"
    puts $fp "SUMMARY"
    puts $fp "======================================================================"
    puts $fp "All markers             : $all_markers"
    puts $fp "JogToJog target markers : $target_markers"
    puts $fp "Invalid bbox             : $invalid_bbox"
    puts $fp "Unresolved layer         : $unresolved_layer"
    puts $fp "Route-blk candidates     : $candidates"
    puts $fp "Created route blockages  : $created"
    puts $fp "Create failures          : $create_failures"
    puts $fp "======================================================================"
    close $fp

    puts ""
    puts "======================================================================"
    puts " FIX JOG-TO-JOG - EXACT TEMP ROUTE BLOCKAGE"
    puts "======================================================================"
    puts "Version                    : $::TT_J2J_VERSION"
    puts "Mode                       : $mode"
    puts "All markers                : $all_markers"
    puts "JogToJog target markers    : $target_markers"
    puts "Invalid bbox markers       : $invalid_bbox"
    puts "Unresolved-layer markers   : $unresolved_layer"
    puts "Route blockage candidates  : $candidates"
    puts "Created route blockages    : $created"
    puts "Create failures            : $create_failures"
    puts "Report                     : $report_file"
    puts "======================================================================"

    if {$mode eq "preview"} {
        puts "PREVIEW ONLY: no database mutation."
        puts "Next: TT_fix_jog_to_jog apply"
        return $candidates
    }

    # Never run route_eco on an incomplete temporary-blockage set.
    if {$create_failures > 0} {
        puts "ERROR: route-blockage creation had failure(s); route_eco will NOT run."
        puts "INFO: cleaning up temporary route blockages created by this invocation."
        set cleanup [tt_j2j_delete_temp_route_blks $temp_blk_names]
        puts "Cleanup deleted = [dict get $cleanup deleted]"
        if {[llength [dict get $cleanup failed]] > 0} {
            puts "WARNING: cleanup failures = [dict get $cleanup failed]"
        }
        error "TT_fix_jog_to_jog: $create_failures route-blockage creation failure(s)."
    }

    if {$created == 0} {
        puts "INFO: no JogToJog route-blockage candidate was created; route_eco skipped."
        return 0
    }

    if {[llength [info commands route_eco]] == 0} {
        puts "ERROR: route_eco command is unavailable."
        set cleanup [tt_j2j_delete_temp_route_blks $temp_blk_names]
        puts "Cleanup deleted = [dict get $cleanup deleted]"
        error "TT_fix_jog_to_jog: route_eco unavailable."
    }

    puts ""
    puts "======================================================================"
    puts " AUTO ROUTE_ECO"
    puts "======================================================================"
    puts "Temporary route blockages : $created"
    puts "Command                    : route_eco"
    puts "======================================================================"

    set route_failed 0
    set route_err ""
    set route_opts ""

    if {[catch {route_eco} route_err route_opts]} {
        set route_failed 1
        puts "ERROR: route_eco failed: $route_err"
    } else {
        puts "INFO: route_eco completed."
    }

    puts ""
    puts "======================================================================"
    puts " TEMP ROUTE BLOCKAGE CLEANUP"
    puts "======================================================================"

    set cleanup [tt_j2j_delete_temp_route_blks $temp_blk_names]
    puts "Deleted : [dict get $cleanup deleted]"

    set cleanup_failed [dict get $cleanup failed]
    if {[llength $cleanup_failed] > 0} {
        puts "WARNING: cleanup failures:"
        foreach item $cleanup_failed {
            puts "  $item"
        }
    } else {
        puts "Cleanup : PASS"
    }

    puts "======================================================================"

    if {$route_failed} {
        return -options $route_opts $route_err
    }

    if {[llength $cleanup_failed] > 0} {
        error "TT_fix_jog_to_jog: route_eco succeeded but temporary blockage cleanup had failure(s)."
    }

    puts ""
    puts "INFO: JogToJog repair pass completed."
    puts "INFO: Run check_drc to verify whether the target marker(s) disappeared."
    puts ""

    return $created
}

proc TT_J2J_version {} {
    puts ""
    puts "======================================================================"
    puts " TT_fix_jog_to_jog VERSION"
    puts "======================================================================"
    puts "Version : $::TT_J2J_VERSION"
    puts "Target  : marker type/subtype containing JogToJog"
    puts "Repair  : exact marker bbox -> temp route blockage -> route_eco -> cleanup"
    puts "Margin  : NONE"
    puts "PG nets : excluded from temp blockage"
    puts "======================================================================"
    puts ""
}

proc TT_J2J_help {} {
    puts ""
    puts "======================================================================"
    puts " TT_DRC_fix_jog_to_jog.tcl"
    puts "======================================================================"
    puts "Preview:"
    puts "  TT_fix_jog_to_jog"
    puts "  TT_fix_jog_to_jog preview"
    puts ""
    puts "Apply:"
    puts "  TT_fix_jog_to_jog apply"
    puts ""
    puts "Marker stats:"
    puts "  TT_J2J_stats"
    puts ""
    puts "Version:"
    puts "  TT_J2J_version"
    puts ""
    puts "After apply:"
    puts "  check_drc"
    puts "======================================================================"
    puts ""
}

puts ""
puts "======================================================================"
puts " LOADED TT_DRC_fix_jog_to_jog.tcl"
puts "======================================================================"
puts "Version : $::TT_J2J_VERSION"
puts "Source  : SAFE - no database mutation on source"
puts "Preview : TT_fix_jog_to_jog preview"
puts "Apply   : TT_fix_jog_to_jog apply"
puts "Stats   : TT_J2J_stats"
puts "======================================================================"
puts ""
