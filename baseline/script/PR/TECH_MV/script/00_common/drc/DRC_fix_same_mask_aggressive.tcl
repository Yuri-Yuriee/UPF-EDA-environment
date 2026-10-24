# Runtime adapter preserves the historical logical source path.
if {[info exists ::TECH_MV_RUNTIME_ROOT]} {
    info script [file join $::TECH_MV_RUNTIME_ROOT run/tool/00_common/drc/TT_DRC_fix_same_mask_aggressive.tcl]
} else {
    info script [file normalize [file join [file dirname [info script]] .. .. .. run/tool/00_common/drc/TT_DRC_fix_same_mask_aggressive.tcl]]
}
# DRC_RULE_REVIEW_REQUIRED: technology selectors retained; not cleared for public release.
# DRC_RULE_SPECIFIC_TOOL: named/configured DRC subtype selection is technology-dependent.
# DRC_RULE_REVIEW: Rule names, filters and repair logic are retained for manual planning.
# Load definitions only; no APR action or setup reload is performed here.
if {![llength [info commands ::tech_mv_library_value]]} {
    if {[info exists ::TOOL_DIR]} {
        source -quiet [file join $::TECH_MV_RUNTIME_ROOT .. script PR TECH_MV script 00_common private_parameter_config.tcl]
    } else {
        source -quiet [file join $::TECH_MV_RUNTIME_ROOT .. script PR TECH_MV script 00_common private_parameter_config.tcl]
    }
}
# PUBLIC_EXPORT_REVIEW_REQUIRED: residual technology candidates require manual review.
# =============================================================================
# TT_DRC_fix_same_mask_aggressive.tcl
# =============================================================================
# Aggressive marker-driven M2 route-blockage tool for Metal_SameMask_Spacing.
#
# Target condition (ALL must be true):
#   1. marker.subtype == Metal_SameMask_Spacing
#   2. marker.layer.name == M2
#   3. marker.objects contains an inst object
#   4. that inst has .is_buffer == true
#
# Repair:
#   Create one M2 route blockage using EXACTLY the marker bbox.
#
# Commands:
#   TT_fix_same_mask_aggressive preview
#   TT_fix_same_mask_aggressive apply
#
# Notes:
#   - preview is the default.
#   - apply automatically runs route_eco once when at least one blockage is created.
#   - after successful route_eco, ONLY route blockages created by this invocation are deleted.
#   - apply does NOT automatically run check_drc.
#   - route blockage is M2 only.
#   - PG nets are excluded from the blockage when Common UI
#     create_route_blockage supports -except_pg_nets.
#   - duplicate marker bboxes are created at most once per invocation.
# =============================================================================

set ::TT_SMA_SUBTYPE "Metal_SameMask_Spacing"
set ::TT_SMA_LAYER   [::tech_mv_library_value LIB_TECH_001]
set ::TT_SMA_VERSION "V10_TMP_BLK_ROUTE_ECO_CLEANUP"

proc tt_sma_get {obj attr {default ""}} {
    if {[catch {set value [get_db $obj $attr]}]} {
        return $default
    }
    if {$value eq ""} {
        return $default
    }
    return $value
}

proc tt_sma_true {value} {
    set v [string tolower [string trim $value]]
    return [expr {$v eq "true" || $v eq "1" || $v eq "yes"}]
}

proc tt_sma_normalize_bbox {bbox} {
    if {[catch {set n [llength $bbox]}]} {
        return ""
    }

    if {$n == 1} {
        set bbox [lindex $bbox 0]
        if {[catch {set n [llength $bbox]}]} {
            return ""
        }
    }

    if {$n != 4} {
        return ""
    }

    lassign $bbox llx lly urx ury

    foreach v [list $llx $lly $urx $ury] {
        if {![string is double -strict $v]} {
            return ""
        }
    }

    if {$llx > $urx} {
        set t $llx
        set llx $urx
        set urx $t
    }
    if {$lly > $ury} {
        set t $lly
        set lly $ury
        set ury $t
    }

    if {$llx >= $urx || $lly >= $ury} {
        return ""
    }

    return [list $llx $lly $urx $ury]
}

proc tt_sma_report_path {mode} {
    if {[info exists ::REPORT_DIR] && $::REPORT_DIR ne ""} {
        file mkdir $::REPORT_DIR
        return [file join $::REPORT_DIR "fix_same_mask_aggressive_${mode}.rpt"]
    }
    return "fix_same_mask_aggressive_${mode}.rpt"
}

proc tt_sma_obj_name {obj} {
    foreach attr {.name .base_name} {
        set n ""
        if {![catch {set n [get_db $obj $attr]}] && $n ne ""} {
            return $n
        }
    }

    set s [string trim $obj]
    regsub {^[^:]+:} $s {} s
    return $s
}

proc tt_sma_marker_is_target {marker} {
    set subtype [tt_sma_get $marker .subtype ""]
    if {$subtype ne $::TT_SMA_SUBTYPE} {
        return false
    }

    set layer [tt_sma_get $marker .layer.name ""]
    if {$layer eq ""} {
        set layer_obj [tt_sma_get $marker .layer ""]
        if {$layer_obj ne ""} {
            set layer [tt_sma_get $layer_obj .name ""]
        }
    }

    return [expr {$layer eq $::TT_SMA_LAYER}]
}

# Common-UI DPO type:
#   inst:<...>
#   net:<...>
#   pin:<...>
#   wire:<...>
proc tt_sma_dpo_type {obj} {
    set s [string trim "$obj"]
    set pos [string first ":" $s]
    if {$pos <= 0} {
        return ""
    }
    return [string range $s 0 [expr {$pos - 1}]]
}

# First inspect marker.objects object type.
# Only inst objects may query the instance-only .is_buffer attribute.
proc tt_sma_marker_buffers {marker} {
    set result {}

    set objects [get_db $marker .objects]

    foreach obj $objects {
        set obj_type [tt_sma_dpo_type $obj]

        if {$obj_type ne "inst"} {
            continue
        }

        set is_buffer false
        if {[catch {set is_buffer [get_db $obj .is_buffer]} err]} {
            puts "WARNING: cannot query .is_buffer on $obj : $err"
            continue
        }

        if {![tt_sma_true $is_buffer]} {
            continue
        }

        set name [tt_sma_obj_name $obj]
        if {$name eq ""} {
            set name $obj
        }

        if {[lsearch -exact $result $name] < 0} {
            lappend result $name
        }
    }

    return $result
}

# Create an M2 route blockage at exactly the marker bbox.
#
# Preferred: Innovus Common UI
#   create_route_blockage -layers M2 -rects {{llx lly urx ury}} -except_pg_nets
#
# Compatibility fallback:
#   createRouteBlk -layer M2 -boxList {llx lly urx ury}
proc tt_sma_create_route_blk {bbox name} {
    set bbox [tt_sma_normalize_bbox $bbox]
    if {$bbox eq ""} {
        error "TT_SMA: invalid route blockage bbox '$bbox'."
    }

    if {[llength [info commands create_route_blockage]] == 0} {
        error "TT_SMA: create_route_blockage is unavailable."
    }

    puts "TT SAME_MASK AGGRESSIVE TEMP ROUTE BLOCKAGE:"
    puts "  name  = $name"
    puts "  layer = $::TT_SMA_LAYER"
    puts "  bbox  = $bbox"

    # Common UI. Keep PG routing unaffected.
    return [create_route_blockage \
        -name $name \
        -layers [list $::TT_SMA_LAYER] \
        -rects [list $bbox] \
        -except_pg_nets]
}

proc tt_sma_delete_temp_route_blks {names} {
    set deleted 0
    set failed {}

    foreach name $names {
        set objs {}
        if {[catch {set objs [get_db route_blockages $name]} err]} {
            lappend failed [list $name "QUERY_FAIL: $err"]
            continue
        }

        if {[llength $objs] == 0} {
            # It may already have disappeared as a side effect of routing.
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

proc TT_fix_same_mask_aggressive {{mode preview}} {
    set mode [string tolower [string trim $mode]]

    if {$mode ni {preview apply}} {
        error "Usage: TT_fix_same_mask_aggressive ?preview|apply?"
    }

    set report_file [tt_sma_report_path $mode]
    set fp [open $report_file w]

    puts $fp "Aggressive Same-Mask Buffer M2 Route Blockage"
    puts $fp "Version        : $::TT_SMA_VERSION"
    puts $fp "Mode           : $mode"
    puts $fp "Target subtype : $::TT_SMA_SUBTYPE"
    puts $fp "Target layer   : $::TT_SMA_LAYER"
    puts $fp ""

    set all_same_mask 0
    set m2_same_mask 0
    set buffer_markers 0
    set invalid_bbox_markers 0
    set route_blk_candidates 0
    set created 0
    set failed 0
    set temp_blk_names {}

    # Deduplicate identical marker geometry during this invocation.
    set seen_bbox [dict create]

    foreach marker [get_db markers] {
        set subtype [tt_sma_get $marker .subtype ""]
        if {$subtype ne $::TT_SMA_SUBTYPE} {
            continue
        }
        incr all_same_mask

        if {![tt_sma_marker_is_target $marker]} {
            continue
        }
        incr m2_same_mask

        set bbox [tt_sma_normalize_bbox [tt_sma_get $marker .bbox ""]]
        if {$bbox eq ""} {
            incr invalid_bbox_markers
            puts $fp "SKIP invalid_bbox marker=$marker"
            continue
        }

        set buffers [tt_sma_marker_buffers $marker]
        if {[llength $buffers] == 0} {
            puts $fp "SKIP no_buffer marker=$marker bbox={$bbox}"
            continue
        }
        incr buffer_markers

        set key [join $bbox ,]
        if {[dict exists $seen_bbox $key]} {
            puts $fp "SKIP duplicate_bbox marker=$marker bbox={$bbox} buffers={$buffers}"
            continue
        }

        dict set seen_bbox $key 1
        incr route_blk_candidates

        puts $fp "CANDIDATE marker=$marker"
        puts $fp "  subtype = $subtype"
        puts $fp "  layer   = $::TT_SMA_LAYER"
        puts $fp "  bbox    = {$bbox}"
        puts $fp "  buffers = {$buffers}"

        if {$mode eq "preview"} {
            puts $fp "  action  = PREVIEW_ONLY"
            puts $fp ""
            continue
        }

        set blk_name [format "TT_SMA_TMP_%04d" [expr {$created + $failed + 1}]]

        if {[catch {tt_sma_create_route_blk $bbox $blk_name} route_blk err_opts]} {
            incr failed
            puts $fp "  action  = CREATE_ROUTE_BLK_FAIL"
            puts $fp "  name    = $blk_name"
            puts $fp "  error   = {$route_blk}"
        } else {
            incr created
            lappend temp_blk_names $blk_name
            puts $fp "  action  = ROUTE_BLK_CREATED"
            puts $fp "  name    = $blk_name"
            puts $fp "  object  = $route_blk"
        }
        puts $fp ""
    }

    puts $fp "===================================================================="
    puts $fp "Summary"
    puts $fp "===================================================================="
    puts $fp "All same-mask markers       : $all_same_mask"
    puts $fp "Same-mask markers on M2     : $m2_same_mask"
    puts $fp "M2 markers with buffer obj  : $buffer_markers"
    puts $fp "Invalid bbox markers        : $invalid_bbox_markers"
    puts $fp "Route blockage candidates   : $route_blk_candidates"
    puts $fp "Created route blockages     : $created"
    puts $fp "Create failures             : $failed"
    puts $fp "Mode                        : $mode"
    puts $fp "Report                      : $report_file"
    close $fp

    puts ""
    puts "======================================================================"
    puts " FIX SAME MASK AGGRESSIVE - ROUTE BLOCKAGE"
    puts "======================================================================"
    puts "Version                    : $::TT_SMA_VERSION"
    puts "Mode                       : $mode"
    puts "All same-mask markers      : $all_same_mask"
    puts "Same-mask M2 markers       : $m2_same_mask"
    puts "M2 markers with buffer     : $buffer_markers"
    puts "Invalid bbox markers       : $invalid_bbox_markers"
    puts "Route blockage candidates  : $route_blk_candidates"
    puts "Created route blockages    : $created"
    puts "Create failures            : $failed"
    puts "Report                     : $report_file"
    puts "======================================================================"

    if {$mode eq "preview"} {
        puts "PREVIEW ONLY: no route blockage was created."
        puts "Run: TT_fix_same_mask_aggressive apply"
    } else {
        puts "APPLY complete."

        if {$failed > 0} {
            puts "WARNING: route_eco is skipped because route-blockage creation had failure(s)."
        } elseif {$created > 0} {
            if {[llength [info commands route_eco]] == 0} {
                error "TT_fix_same_mask_aggressive: route_eco command is unavailable."
            }

            puts ""
            puts "======================================================================"
            puts " AUTO ROUTE_ECO"
            puts "======================================================================"
            puts "Created route blockages : $created"
            puts "Command                  : route_eco"
            puts "======================================================================"

            if {[catch {route_eco} route_eco_err route_eco_opts]} {
                puts "ERROR: route_eco failed: $route_eco_err"
                return -options $route_eco_opts $route_eco_err
            }

            puts "INFO: route_eco completed."

            puts ""
            puts "======================================================================"
            puts " TEMP ROUTE BLOCKAGE CLEANUP"
            puts "======================================================================"
            puts "Temporary blockages created : [llength $temp_blk_names]"

            set cleanup_result [tt_sma_delete_temp_route_blks $temp_blk_names]
            set cleanup_deleted [dict get $cleanup_result deleted]
            set cleanup_failed  [dict get $cleanup_result failed]

            puts "Temporary blockages deleted : $cleanup_deleted"
            puts "Cleanup failures             : [llength $cleanup_failed]"
            if {[llength $cleanup_failed] > 0} {
                foreach item $cleanup_failed {
                    puts "ERROR: cleanup [lindex $item 0] -> [lindex $item 1]"
                }
                error "TT_fix_same_mask_aggressive: temporary route blockage cleanup failed."
            }
            puts "======================================================================"
        } else {
            puts "INFO: No route blockage was created; route_eco is skipped."
        }

        puts "Next: run check_drc and compare Metal_SameMask_Spacing markers."
    }
    puts ""

    if {$failed > 0} {
        error "TT_fix_same_mask_aggressive: $failed route-blockage creation failure(s). See $report_file"
    }

    return $created
}

proc TT_SMA_version {} {
    puts "======================================================================"
    puts " TT_fix_same_mask_aggressive VERSION"
    puts "======================================================================"
    puts "Version : $::TT_SMA_VERSION"
    puts "Action  : TEMP M2 ROUTE BLOCKAGE + route_eco + DELETE TEMP BLK"
    puts "Rule    : marker.objects -> DPO type -> inst only -> .is_buffer"
    puts "Repair  : marker bbox -> temp M2 route blockage -> route_eco -> delete temp blockage"
    puts "======================================================================"
}

puts ""
puts "======================================================================"
puts " LOADED TT_DRC_fix_same_mask_aggressive.tcl"
puts "======================================================================"
puts "Version : $::TT_SMA_VERSION"
puts "SHA12   : 858eb6fa0172"
puts "Action  : TEMP M2 ROUTE BLOCKAGE + route_eco + DELETE TEMP BLK"
puts "Rule    : marker.objects -> DPO type -> inst only -> .is_buffer"
puts "Repair  : marker bbox -> temp M2 route blockage -> route_eco -> delete temp blockage"
puts "Command : TT_SMA_version"
puts "======================================================================"
puts ""
