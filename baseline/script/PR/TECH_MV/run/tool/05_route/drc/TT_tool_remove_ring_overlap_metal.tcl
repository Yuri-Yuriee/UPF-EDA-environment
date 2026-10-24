# Runtime adapter preserves the historical logical source path.
if {[info exists ::TECH_MV_RUNTIME_ROOT]} {
    info script [file join $::TECH_MV_RUNTIME_ROOT run/tool/05_route/drc/TT_tool_remove_ring_overlap_metal.tcl]
}
# DRC_RULE_REVIEW_REQUIRED: technology selectors retained; not cleared for public release.
# Load definitions only; no APR action or setup reload is performed here.
if {![llength [info commands ::tech_mv_library_value]]} {
    if {[info exists ::TOOL_DIR]} {
        source -quiet [file join $::TECH_MV_RUNTIME_ROOT .. script PR TECH_MV script 00_common private_parameter_config.tcl]
    } else {
        source -quiet [file join $::TECH_MV_RUNTIME_ROOT .. script PR TECH_MV script 00_common private_parameter_config.tcl]
    }
}
# PUBLIC_EXPORT_REVIEW_REQUIRED: residual technology candidates require manual review.
# ==============================================================================
# TT_tool_remove_ring_overlap_metal_M7L6.tcl
#
# Stylus Common UI
#
# Target DRC:
#   M7.L.6.1
#   M7.L.6.2
#
# Purpose:
#   Use every special_wire whose .shape is RING or BLOCKRING as an anchor.
#   Delete OTHER special_wire metal which satisfies ALL:
#     - same .layer.name
#     - same .layer.direction   (requested direction criterion)
#     - positive-area rectangle overlap with the ring
#     - candidate is NOT ring/blockring
#     - candidate is NOT a via (search type is special_wire only)
#
# Notes:
#   - Entire current_design .bbox is searched.
#   - Default is DRY-RUN.
#   - Ring geometry is read from special_wire .rect.
#   - Handles either flat rect {x1 y1 x2 y2} or nested {{x1 y1 x2 y2}}.
#
# Usage:
#   source run/tool/05_route/drc/TT_tool_remove_ring_overlap_metal.tcl
#
#   # report only, all layers
#   TT_tool_remove_ring_overlap_metal
#
#   # only M8
#   TT_tool_remove_ring_overlap_metal -layers {M8}
#
#   # M8 + M9 and select candidates in GUI
#   TT_tool_remove_ring_overlap_metal -layers {M8 M9} -select 1
#
#   # delete on selected layers
#   TT_tool_remove_ring_overlap_metal -layers {M8 M9} -dry_run 0
# ==============================================================================

namespace eval ::TT_RING_CLEAN {
    variable version "2.4"
}

proc ::TT_RING_CLEAN::get_attr {obj attr} {
    if {[catch {get_db $obj $attr} v]} {
        return ""
    }
    return $v
}

proc ::TT_RING_CLEAN::is_ring_shape {shape} {
    return [expr {
        [string equal -nocase $shape "ring"] ||
        [string equal -nocase $shape "blockring"]
    }]
}

# Normalize:
#   {x1 y1 x2 y2}
# or
#   {{x1 y1 x2 y2}}
# into:
#   {x1 y1 x2 y2}
proc ::TT_RING_CLEAN::normalize_rect {r} {
    if {$r eq ""} {
        return {}
    }

    # Already flat.
    if {[llength $r] == 4} {
        return $r
    }

    # One outer list element containing the rect.
    if {[llength $r] == 1} {
        set r0 [lindex $r 0]
        if {[llength $r0] == 4} {
            return $r0
        }
    }

    return {}
}

# Positive-area overlap only.
# Edge-touch / abut does not count.
proc ::TT_RING_CLEAN::rect_overlap_positive {a b} {
    set a [::TT_RING_CLEAN::normalize_rect $a]
    set b [::TT_RING_CLEAN::normalize_rect $b]

    if {[llength $a] != 4 || [llength $b] != 4} {
        return 0
    }

    lassign $a ax1 ay1 ax2 ay2
    lassign $b bx1 by1 bx2 by2

    set ox [expr {min($ax2,$bx2) - max($ax1,$bx1)}]
    set oy [expr {min($ay2,$by2) - max($ay1,$by1)}]

    return [expr {$ox > 0.0 && $oy > 0.0}]
}

proc TT_tool_remove_ring_overlap_metal {args} {
    set dry_run 1
    set verbose 0
    set select_enable 0
    set layers {}

    # --------------------------------------------------------------------------
    # Parse options
    # --------------------------------------------------------------------------
    set i 0
    while {$i < [llength $args]} {
        set opt [lindex $args $i]

        switch -- $opt {
            -layers {
                incr i
                if {$i >= [llength $args]} {
                    error "-layers requires a Tcl list, e.g. {M8 M9}"
                }
                set layers [lindex $args $i]
            }

            -dry_run {
                incr i
                if {$i >= [llength $args]} {
                    error "-dry_run requires 0 or 1"
                }
                set dry_run [lindex $args $i]
                if {$dry_run ni {0 1}} {
                    error "-dry_run must be 0 or 1"
                }
            }

            -select {
                incr i
                if {$i >= [llength $args]} {
                    error "-select requires 0 or 1"
                }
                set select_enable [lindex $args $i]
                if {$select_enable ni {0 1}} {
                    error "-select must be 0 or 1"
                }
            }

            -verbose {
                incr i
                if {$i >= [llength $args]} {
                    error "-verbose requires 0 or 1"
                }
                set verbose [lindex $args $i]
                if {$verbose ni {0 1}} {
                    error "-verbose must be 0 or 1"
                }
            }

            -help -
            --help {
                puts ""
                puts "TT_tool_remove_ring_overlap_metal"
                puts ""
                puts "Options:"
                puts "  -layers <list>    restrict processing to these routing layers"
                puts "                    example: -layers [::tech_mv_library_value LIB_TECH_006]"
                puts "                    default: all layers"
                puts "  -dry_run <0|1>    default 1"
                puts "  -select <0|1>     select candidate metals in GUI"
                puts "                    default: 0"
                puts "  -verbose <0|1>    default 0"
                puts ""
                return
            }

            default {
                error "Unknown option: $opt ; use -help"
            }
        }

        incr i
    }

    puts ""
    puts "======================================================================"
    puts " TT ALL-RING OVERLAP METAL CLEAN  v$::TT_RING_CLEAN::version"
    puts " Target DRC        : M7.L.6.1 / M7.L.6.2"
    puts "======================================================================"
    puts " Ring shapes       : ring, blockring"
    if {[llength $layers] == 0} {
        puts " Layers            : ALL"
    } else {
        puts " Layers            : $layers"
    }
    puts " Search region     : current_design .bbox"
    puts " Direction source  : get_db <special_wire> .layer.direction"
    puts " Geometry source   : get_db <special_wire> .rect"
    puts " VIA handling      : excluded (special_wire only)"
    puts " Ring protection   : RING/BLOCKRING are never deleted"
    puts " Select candidates : $select_enable"
    puts " Dry run           : $dry_run"
    puts "----------------------------------------------------------------------"

    set die_box [get_db current_design .bbox]

    if {[catch {
        set all_sw [get_obj_in_area \
            -area $die_box \
            -obj_type special_wire]
    } err]} {
        error "Failed to query special_wire inside die: $err"
    }

    puts [format " All special_wire objects : %d" [llength $all_sw]]

    # --------------------------------------------------------------------------
    # Collect all ring/blockring special-wire segments.
    # --------------------------------------------------------------------------
    set rings {}
    foreach sw $all_sw {
        set shape [::TT_RING_CLEAN::get_attr $sw .shape]
        if {![::TT_RING_CLEAN::is_ring_shape $shape]} {
            continue
        }

        # Optional layer restriction.
        # When -layers is empty, accept all layers.
        if {[llength $layers] > 0} {
            set sw_layer [::TT_RING_CLEAN::get_attr $sw .layer.name]
            if {[lsearch -exact $layers $sw_layer] < 0} {
                continue
            }
        }

        lappend rings $sw
    }

    puts [format " Ring segments             : %d" [llength $rings]]

    if {[llength $rings] == 0} {
        puts "WARNING: No ring/blockring special_wire found."
        return {}
    }

    # --------------------------------------------------------------------------
    # Diagnostic counters.
    # --------------------------------------------------------------------------
    set valid_ring_count 0
    set miss_rect 0
    set miss_layer 0
    set miss_dir 0
    set area_query_fail 0

    set candidates [dict create]
    set ring_index 0

    foreach ring $rings {
        incr ring_index

        set ring_net       [::TT_RING_CLEAN::get_attr $ring .net.name]
        set ring_shape     [::TT_RING_CLEAN::get_attr $ring .shape]
        set ring_layer     [::TT_RING_CLEAN::get_attr $ring .layer.name]
        set ring_dir       [::TT_RING_CLEAN::get_attr $ring .layer.direction]
        set ring_rect_raw  [::TT_RING_CLEAN::get_attr $ring .rect]
        set ring_rect      [::TT_RING_CLEAN::normalize_rect $ring_rect_raw]

        set bad 0

        if {$ring_layer eq ""} {
            incr miss_layer
            set bad 1
        }

        if {$ring_dir eq ""} {
            incr miss_dir
            set bad 1
        }

        if {[llength $ring_rect] != 4} {
            incr miss_rect
            set bad 1
        }

        if {$bad} {
            puts "WARNING: Skip ring: $ring"
            puts "         NET       = $ring_net"
            puts "         SHAPE     = $ring_shape"
            puts "         LAYER     = <$ring_layer>"
            puts "         DIRECTION = <$ring_dir>"
            puts "         RECT_RAW  = <$ring_rect_raw>"
            continue
        }

        incr valid_ring_count

        if {$verbose} {
            puts ""
            puts "RING[$ring_index]"
            puts "  OBJ       : $ring"
            puts "  NET       : $ring_net"
            puts "  SHAPE     : $ring_shape"
            puts "  LAYER     : $ring_layer"
            puts "  DIRECTION : $ring_dir"
            puts "  RECT      : $ring_rect"
        }

        # ----------------------------------------------------------------------
        # Query only special_wire intersecting/overlapping the ring area.
        #
        # -overlap_only is intentionally used here.
        # Do not use -bbox_overlap.
        # ----------------------------------------------------------------------
        if {[catch {
            set local_sw [get_obj_in_area \
                -area $ring_rect \
                -obj_type special_wire \
                -overlap_only]
        } err]} {
            incr area_query_fail
            puts "WARNING: get_obj_in_area failed for $ring"
            puts "         $err"
            continue
        }

        foreach cand $local_sw {
            # Protect current ring segment.
            if {$cand eq $ring} {
                continue
            }

            set cand_shape [::TT_RING_CLEAN::get_attr $cand .shape]

            # Protect every other ring/blockring too.
            if {[::TT_RING_CLEAN::is_ring_shape $cand_shape]} {
                continue
            }

            # Same layer.
            set cand_layer [::TT_RING_CLEAN::get_attr $cand .layer.name]
            if {$cand_layer ne $ring_layer} {
                continue
            }

            # Same direction using the exact attribute requested by user.
            set cand_dir [::TT_RING_CLEAN::get_attr $cand .layer.direction]
            if {![string equal -nocase $cand_dir $ring_dir]} {
                continue
            }

            # Real geometry overlap.
            set cand_rect_raw [::TT_RING_CLEAN::get_attr $cand .rect]
            set cand_rect [::TT_RING_CLEAN::normalize_rect $cand_rect_raw]
            if {[llength $cand_rect] != 4} {
                continue
            }

            if {![::TT_RING_CLEAN::rect_overlap_positive \
                    $ring_rect $cand_rect]} {
                continue
            }

            # Deduplicate candidate object.
            if {![dict exists $candidates $cand]} {
                set cand_net [::TT_RING_CLEAN::get_attr $cand .net.name]

                dict set candidates $cand [list \
                    cand_net    $cand_net \
                    cand_shape  $cand_shape \
                    cand_layer  $cand_layer \
                    cand_dir    $cand_dir \
                    cand_rect   $cand_rect \
                    ring_obj    $ring \
                    ring_net    $ring_net \
                    ring_shape  $ring_shape \
                    ring_rect   $ring_rect]
            }
        }
    }

    set delete_list [dict keys $candidates]

    puts ""
    puts "----------------------------------------------------------------------"
    puts " RING GEOMETRY SUMMARY"
    puts "----------------------------------------------------------------------"
    puts [format " Total ring segments       : %d" [llength $rings]]
    puts [format " Valid ring segments       : %d" $valid_ring_count]
    puts [format " Missing .rect             : %d" $miss_rect]
    puts [format " Missing .layer.name       : %d" $miss_layer]
    puts [format " Missing .layer.direction  : %d" $miss_dir]
    puts [format " Area query failures       : %d" $area_query_fail]
    puts ""

    puts "----------------------------------------------------------------------"
    puts [format " DELETE CANDIDATES          : %d" [llength $delete_list]]
    puts "----------------------------------------------------------------------"

    set idx 0
    foreach cand $delete_list {
        incr idx
        array unset info
        array set info [dict get $candidates $cand]

        puts "CANDIDATE[$idx]"
        puts "  OBJ        : $cand"
        puts "  NET        : $info(cand_net)"
        puts "  SHAPE      : $info(cand_shape)"
        puts "  LAYER      : $info(cand_layer)"
        puts "  DIRECTION  : $info(cand_dir)"
        puts "  RECT       : $info(cand_rect)"
        puts "  RING_NET   : $info(ring_net)"
        puts "  RING_SHAPE : $info(ring_shape)"
        puts "  RING_RECT  : $info(ring_rect)"
    }

    # --------------------------------------------------------------------------
    # Optional GUI selection.
    # Select candidates before deletion so user can inspect them.
    # --------------------------------------------------------------------------
    if {$select_enable} {
        if {[llength $delete_list] > 0} {
            if {[catch {select_obj $delete_list} sel_err]} {
                puts ""
                puts "WARNING: Failed to select candidate objects:"
                puts "         $sel_err"
            } else {
                puts ""
                puts "SELECT: [llength $delete_list] candidate metal object(s) selected."
            }
        } else {
            puts ""
            puts "SELECT: no candidate metal to select."
        }
    }

    # --------------------------------------------------------------------------
    # Dry run.
    # --------------------------------------------------------------------------
    if {$dry_run} {
        puts ""
        puts "======================================================================"
        puts " DRY-RUN ONLY: nothing deleted."
        puts " Target DRC: M7.L.6.1 / M7.L.6.2"
        puts " To select candidates:"
        if {[llength $layers] == 0} {
            puts "   TT_tool_remove_ring_overlap_metal -select 1"
        } else {
            puts "   TT_tool_remove_ring_overlap_metal -layers {$layers} -select 1"
        }
        puts ""
        puts " To delete:"
        if {[llength $layers] == 0} {
            puts "   TT_tool_remove_ring_overlap_metal -dry_run 0"
        } else {
            puts "   TT_tool_remove_ring_overlap_metal -layers {$layers} -dry_run 0"
        }
        puts "======================================================================"
        return $delete_list
    }

    # --------------------------------------------------------------------------
    # Delete after collection, so DB pointer mutation cannot affect traversal.
    # --------------------------------------------------------------------------
    puts ""
    puts "----------------------------------------------------------------------"
    puts " DELETE"
    puts "----------------------------------------------------------------------"

    set deleted 0
    set failed 0

    foreach cand $delete_list {
        if {[catch {delete_obj $cand} err]} {
            incr failed
            puts "ERROR: failed to delete $cand"
            puts "       $err"
        } else {
            incr deleted
            puts "DELETE: $cand"
        }
    }

    puts ""
    puts "======================================================================"
    puts " DONE - M7.L.6.1 / M7.L.6.2 CLEAN"
    puts "======================================================================"
    puts " Valid ring segments : $valid_ring_count"
    puts " Candidates          : [llength $delete_list]"
    puts " Deleted             : $deleted"
    puts " Failed              : $failed"
    puts "======================================================================"

    return $delete_list
}
