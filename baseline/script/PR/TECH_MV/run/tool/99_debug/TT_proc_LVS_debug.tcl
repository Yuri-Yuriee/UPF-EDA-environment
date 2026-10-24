# Runtime adapter preserves the historical logical source path.
if {[info exists ::TECH_MV_RUNTIME_ROOT]} {
    info script [file join $::TECH_MV_RUNTIME_ROOT run/tool/99_debug/TT_proc_LVS_debug.tcl]
}
# =============================================================================
# TT_proc_LVS_debug.tcl
# TECH_MV / Innovus LVS connectivity debug helper
#
# Main functions:
#   1. TT_LVS_check_selected / TT_LVS_check_selected_full
#      Check connectivity and optional physical state of selected instance(s)
#   2. TT_LVS_find_floating_pins
#      Find all floating PG/signal pins in the design
#   3. TT_PHY_check_inst / TT_PHY_find_unplaced / TT_PHY_summary
#      Physical placement/check_place diagnostics
#
# Debug tool: does not modify design connectivity or placement geometry.
# Optional -run_check_place refreshes Innovus check markers.
# =============================================================================

proc TT_LVS__net_name {pin} {
    set net_obj ""
    catch { set net_obj [get_db $pin .net] }
    if {[llength $net_obj] == 0} {
        return "FLOATING"
    }

    set net_name ""
    catch { set net_name [get_db $net_obj .base_name] }
    if {$net_name eq ""} {
        catch { set net_name [get_db $net_obj .name] }
    }
    if {$net_name eq ""} {
        return "FLOATING"
    }
    return $net_name
}

proc TT_LVS__resolve_inst {inst_or_name} {
    set obj_type ""
    catch { set obj_type [get_db $inst_or_name .obj_type] }
    if {$obj_type eq "inst"} {
        return $inst_or_name
    }

    set inst ""
    catch { set inst [get_db insts $inst_or_name] }
    if {[llength $inst] == 0} {
        return ""
    }
    return [lindex $inst 0]
}

proc TT_LVS_check_inst {inst_or_name} {
    set inst [TT_LVS__resolve_inst $inst_or_name]
    if {$inst eq ""} {
        puts "ERROR: Instance not found: $inst_or_name"
        return 0
    }

    set inst_name [get_db $inst .name]
    set master    [get_db $inst .base_cell.name]
    set status    [get_db $inst .place_status]
    set location  [get_db $inst .location]

    puts ""
    puts "======================================================================"
    puts " TT LVS INSTANCE CONNECTIVITY"
    puts "======================================================================"
    puts "Instance : $inst_name"
    puts "Master   : $master"
    puts "Status   : $status"
    puts "Location : $location"

    set total_count 0
    set floating_count 0

    puts ""
    puts "----------------------------------------------------------------------"
    puts " PG PINS"
    puts "----------------------------------------------------------------------"

    set pg_pins [get_db $inst .pg_pins]
    if {[llength $pg_pins] == 0} {
        puts "  <none>"
    } else {
        foreach pin $pg_pins {
            incr total_count
            set pin_name [get_db $pin .base_name]
            set net_name [TT_LVS__net_name $pin]
            if {$net_name eq "FLOATING"} { incr floating_count }
            puts [format "  %-8s %-22s -> %s" "PG" $pin_name $net_name]
        }
    }

    puts ""
    puts "----------------------------------------------------------------------"
    puts " SIGNAL PINS"
    puts "----------------------------------------------------------------------"

    set signal_pins [get_db $inst .pins]
    if {[llength $signal_pins] == 0} {
        puts "  <none>"
    } else {
        foreach pin $signal_pins {
            incr total_count
            set pin_name [get_db $pin .base_name]
            set net_name [TT_LVS__net_name $pin]
            if {$net_name eq "FLOATING"} { incr floating_count }
            puts [format "  %-8s %-22s -> %s" "SIGNAL" $pin_name $net_name]
        }
    }

    puts ""
    puts "----------------------------------------------------------------------"
    puts "Total pins    : $total_count"
    puts "Floating pins : $floating_count"
    if {$floating_count == 0} {
        puts "RESULT        : PASS"
    } else {
        puts "RESULT        : FLOATING PIN FOUND"
    }
    puts "======================================================================"

    return $floating_count
}

proc TT_LVS_check_selected {} {
    set selected ""
    catch { set selected [get_db selected] }

    if {[llength $selected] == 0} {
        puts "ERROR: Nothing is selected."
        puts "Select one or more instances in Innovus GUI, then run:"
        puts "  TT_LVS_check_selected"
        return 0
    }

    set insts {}
    foreach obj $selected {
        set obj_type ""
        catch { set obj_type [get_db $obj .obj_type] }
        if {$obj_type eq "inst"} {
            lappend insts $obj
        }
    }

    if {[llength $insts] == 0} {
        puts "ERROR: Selected object(s) contain no instances."
        return 0
    }

    puts ""
    puts "======================================================================"
    puts " TT LVS SELECTED INSTANCE CHECK"
    puts "======================================================================"
    puts "Selected instance count : [llength $insts]"
    puts "======================================================================"

    set total_floating 0
    foreach inst $insts {
        incr total_floating [TT_LVS_check_inst $inst]
    }

    puts ""
    puts "======================================================================"
    puts " SELECTED CHECK SUMMARY"
    puts "======================================================================"
    puts "Instances checked : [llength $insts]"
    puts "Floating pins     : $total_floating"
    if {$total_floating == 0} {
        puts "RESULT            : PASS"
    } else {
        puts "RESULT            : FLOATING PIN FOUND"
    }
    puts "======================================================================"

    return $total_floating
}

proc TT_LVS_find_floating_pins {args} {
    set skip_iofiller 0
    set scan_pg 1
    set scan_signal 1

    foreach arg $args {
        switch -- $arg {
            "-skip_iofiller" {
                set skip_iofiller 1
            }
            "-pg_only" {
                set scan_pg 1
                set scan_signal 0
            }
            "-signal_only" {
                set scan_pg 0
                set scan_signal 1
            }
            default {
                error "Unknown option: $arg"
            }
        }
    }

    puts ""
    puts "======================================================================"
    puts " TT LVS FLOATING PIN SCAN"
    puts "======================================================================"
    puts "Skip IOFILLER : $skip_iofiller"
    puts "Scan PG pins  : $scan_pg"
    puts "Scan signals  : $scan_signal"
    puts "======================================================================"

    set total_instances 0
    set total_pins 0
    set floating_total 0
    set floating_pg 0
    set floating_signal 0

    array unset float_master_count
    array unset float_pin_count

    foreach inst [get_db insts] {
        set inst_name [get_db $inst .name]
        set master    [get_db $inst .base_cell.name]
        set status    [get_db $inst .place_status]

        if {$skip_iofiller && [string match "IOFILLER*" $inst_name]} {
            continue
        }

        incr total_instances

        if {$scan_pg} {
            foreach pin [get_db $inst .pg_pins] {
                incr total_pins
                set net_obj [get_db $pin .net]
                if {[llength $net_obj] != 0} { continue }

                set pin_name [get_db $pin .base_name]
                incr floating_total
                incr floating_pg

                if {![info exists float_master_count($master)]} {
                    set float_master_count($master) 0
                }
                incr float_master_count($master)

                set key "$master/$pin_name"
                if {![info exists float_pin_count($key)]} {
                    set float_pin_count($key) 0
                }
                incr float_pin_count($key)

                puts [format "FLOAT PG     %-45s %-30s %-12s %-18s" \
                    $inst_name $master $status $pin_name]
            }
        }

        if {$scan_signal} {
            foreach pin [get_db $inst .pins] {
                incr total_pins
                set net_obj [get_db $pin .net]
                if {[llength $net_obj] != 0} { continue }

                set pin_name [get_db $pin .base_name]
                incr floating_total
                incr floating_signal

                if {![info exists float_master_count($master)]} {
                    set float_master_count($master) 0
                }
                incr float_master_count($master)

                set key "$master/$pin_name"
                if {![info exists float_pin_count($key)]} {
                    set float_pin_count($key) 0
                }
                incr float_pin_count($key)

                puts [format "FLOAT SIGNAL %-45s %-30s %-12s %-18s" \
                    $inst_name $master $status $pin_name]
            }
        }
    }

    puts ""
    puts "======================================================================"
    puts " FLOATING PIN SUMMARY"
    puts "======================================================================"
    puts "Instances scanned : $total_instances"
    puts "Pins scanned      : $total_pins"
    puts "Floating PG       : $floating_pg"
    puts "Floating SIGNAL   : $floating_signal"
    puts "Floating TOTAL    : $floating_total"

    puts ""
    puts "----------------------------------------------------------------------"
    puts " FLOATING COUNT BY MASTER"
    puts "----------------------------------------------------------------------"
    if {[array size float_master_count] == 0} {
        puts "  <none>"
    } else {
        foreach master [lsort [array names float_master_count]] {
            puts [format "  %-40s %8d" $master $float_master_count($master)]
        }
    }

    puts ""
    puts "----------------------------------------------------------------------"
    puts " FLOATING COUNT BY MASTER/PIN"
    puts "----------------------------------------------------------------------"
    if {[array size float_pin_count] == 0} {
        puts "  <none>"
    } else {
        foreach key [lsort [array names float_pin_count]] {
            puts [format "  %-55s %8d" $key $float_pin_count($key)]
        }
    }

    puts "======================================================================"
    if {$floating_total == 0} {
        puts "RESULT : PASS"
    } else {
        puts "RESULT : FLOATING PIN FOUND"
    }
    puts "======================================================================"

    return $floating_total
}



# =============================================================================
# PHYSICAL DEBUG HELPERS
# =============================================================================

proc TT_PHY__safe_get {obj attr {default ""}} {
    set value $default
    if {[catch {set value [get_db $obj $attr]}]} {
        return $default
    }
    return $value
}

proc TT_PHY__flatten_list {value} {
    set out {}
    foreach item $value {
        if {[llength $item] > 1} {
            foreach x [TT_PHY__flatten_list $item] {
                lappend out $x
            }
        } else {
            lappend out $item
        }
    }
    return $out
}

proc TT_PHY__bbox4 {bbox} {
    if {$bbox eq ""} {
        return ""
    }

    set flat [TT_PHY__flatten_list $bbox]
    if {[llength $flat] != 4} {
        return ""
    }

    foreach v $flat {
        if {![string is double -strict $v]} {
            return ""
        }
    }

    return $flat
}

proc TT_PHY__bbox_inside {inner outer} {
    set a [TT_PHY__bbox4 $inner]
    set b [TT_PHY__bbox4 $outer]

    if {$a eq "" || $b eq ""} {
        return -1
    }

    lassign $a allx ally aurx aury
    lassign $b bllx blly burx bury

    return [expr {
        $allx >= $bllx &&
        $ally >= $blly &&
        $aurx <= $burx &&
        $aury <= $bury
    }]
}

proc TT_PHY__bbox_intersects {bbox_a bbox_b} {
    set a [TT_PHY__bbox4 $bbox_a]
    set b [TT_PHY__bbox4 $bbox_b]

    if {$a eq "" || $b eq ""} {
        return 0
    }

    lassign $a allx ally aurx aury
    lassign $b bllx blly burx bury

    return [expr {
        !($aurx <= $bllx || $burx <= $allx ||
          $aury <= $blly || $bury <= $ally)
    }]
}

proc TT_PHY__check_place_markers_for_inst {inst} {
    set inst_bbox [TT_PHY__safe_get $inst .bbox ""]
    if {[TT_PHY__bbox4 $inst_bbox] eq ""} {
        return 0
    }

    set count 0
    set markers ""
    catch {set markers [get_db markers]}

    foreach marker $markers {
        set originator [TT_PHY__safe_get $marker .originator ""]
        if {$originator ne "check_place"} {
            continue
        }

        set marker_bbox [TT_PHY__safe_get $marker .bbox ""]
        if {![TT_PHY__bbox_intersects $inst_bbox $marker_bbox]} {
            continue
        }

        incr count
        set type    [TT_PHY__safe_get $marker .type ""]
        set subtype [TT_PHY__safe_get $marker .subtype ""]

        puts [format "  MARKER %-16s %-28s bbox=%s" \
            $type $subtype $marker_bbox]
    }

    return $count
}

# -----------------------------------------------------------------------------
# Public: physical inspection of one instance
# -----------------------------------------------------------------------------
proc TT_PHY_check_inst {inst_or_name {show_markers 1}} {
    set inst [TT_LVS__resolve_inst $inst_or_name]
    if {$inst eq ""} {
        puts "ERROR: Instance not found: $inst_or_name"
        return 1
    }

    set inst_name  [TT_PHY__safe_get $inst .name ""]
    set master     [TT_PHY__safe_get $inst .base_cell.name ""]
    set base_class [TT_PHY__safe_get $inst .base_cell.base_class ""]
    set status     [TT_PHY__safe_get $inst .place_status ""]
    set orient     [TT_PHY__safe_get $inst .orient ""]
    set location   [TT_PHY__safe_get $inst .location ""]
    set bbox       [TT_PHY__safe_get $inst .bbox ""]

    puts ""
    puts "======================================================================"
    puts " TT PHYSICAL INSTANCE CHECK"
    puts "======================================================================"
    puts "Instance   : $inst_name"
    puts "Master     : $master"
    puts "Base class : $base_class"
    puts "Status     : $status"
    puts "Orient     : $orient"
    puts "Location   : $location"
    puts "BBox       : $bbox"

    set issue_count 0

    if {$status eq "" || $status eq "unplaced"} {
        puts "PHYSICAL   : ERROR - instance is not placed"
        incr issue_count
    } else {
        puts "PHYSICAL   : placement status OK"
    }

    set die_bbox [TT_PHY__safe_get current_design .bbox ""]
    if {[TT_PHY__bbox4 $die_bbox] ne "" && [TT_PHY__bbox4 $bbox] ne ""} {
        set inside_die [TT_PHY__bbox_inside $bbox $die_bbox]
        if {$inside_die == 0} {
            puts "DIE CHECK  : ERROR - instance bbox extends outside design bbox"
            puts "Design bbox: $die_bbox"
            incr issue_count
        } elseif {$inside_die == 1} {
            puts "DIE CHECK  : PASS"
        }
    }

    # core_bbox is version/library dependent; use only if available.
    set core_bbox [TT_PHY__safe_get current_design .core_bbox ""]
    if {[TT_PHY__bbox4 $core_bbox] ne "" && [TT_PHY__bbox4 $bbox] ne ""} {
        set inside_core [TT_PHY__bbox_inside $bbox $core_bbox]
        puts "Core bbox  : $core_bbox"
        if {$inside_core == 1} {
            puts "CORE CHECK : inside core bbox"
        } else {
            puts "CORE CHECK : outside/partially outside core bbox"
        }
    }

    if {$show_markers} {
        puts ""
        puts "----------------------------------------------------------------------"
        puts " CHECK_PLACE MARKERS TOUCHING THIS INSTANCE"
        puts "----------------------------------------------------------------------"

        set marker_count [TT_PHY__check_place_markers_for_inst $inst]
        if {$marker_count == 0} {
            puts "  <none from current check_place marker database>"
        } else {
            puts "Marker count : $marker_count"
            incr issue_count $marker_count
        }
    }

    puts "----------------------------------------------------------------------"
    puts "Physical issues : $issue_count"
    if {$issue_count == 0} {
        puts "RESULT          : PASS"
    } else {
        puts "RESULT          : PHYSICAL ISSUE FOUND"
    }
    puts "======================================================================"

    return $issue_count
}

# -----------------------------------------------------------------------------
# Public: selected instance connectivity + physical check
#
# Option:
#   -run_check_place
#       Run Innovus check_place first, then report markers touching selection.
# -----------------------------------------------------------------------------
proc TT_LVS_check_selected_full {args} {
    set run_check_place 0

    foreach arg $args {
        switch -- $arg {
            "-run_check_place" {
                set run_check_place 1
            }
            default {
                error "Unknown option: $arg"
            }
        }
    }

    if {$run_check_place} {
        puts "INFO: Running check_place before selected physical debug."
        check_place
    }

    set selected ""
    catch {set selected [get_db selected]}

    if {[llength $selected] == 0} {
        puts "ERROR: Nothing is selected."
        puts "Select one or more instances in Innovus GUI, then run:"
        puts "  TT_LVS_check_selected_full"
        return 0
    }

    set insts {}
    foreach obj $selected {
        set obj_type [TT_PHY__safe_get $obj .obj_type ""]
        if {$obj_type eq "inst"} {
            lappend insts $obj
        }
    }

    if {[llength $insts] == 0} {
        puts "ERROR: Selected object(s) contain no instances."
        return 0
    }

    set conn_issues 0
    set phy_issues 0

    foreach inst $insts {
        incr conn_issues [TT_LVS_check_inst $inst]
        incr phy_issues  [TT_PHY_check_inst $inst 1]
    }

    puts ""
    puts "======================================================================"
    puts " TT LVS + PHYSICAL SELECTED SUMMARY"
    puts "======================================================================"
    puts "Instances checked   : [llength $insts]"
    puts "Floating pins       : $conn_issues"
    puts "Physical issues     : $phy_issues"
    puts "Total debug issues  : [expr {$conn_issues + $phy_issues}]"
    puts "======================================================================"

    return [expr {$conn_issues + $phy_issues}]
}

# -----------------------------------------------------------------------------
# Public: list all unplaced instances
# -----------------------------------------------------------------------------
proc TT_PHY_find_unplaced {args} {
    set skip_iofiller 0

    foreach arg $args {
        switch -- $arg {
            "-skip_iofiller" {
                set skip_iofiller 1
            }
            default {
                error "Unknown option: $arg"
            }
        }
    }

    puts ""
    puts "======================================================================"
    puts " TT PHYSICAL UNPLACED INSTANCE SCAN"
    puts "======================================================================"

    set count 0
    array unset master_count

    foreach inst [get_db insts] {
        set name   [TT_PHY__safe_get $inst .name ""]
        set master [TT_PHY__safe_get $inst .base_cell.name ""]
        set status [TT_PHY__safe_get $inst .place_status ""]

        if {$skip_iofiller && [string match "IOFILLER*" $name]} {
            continue
        }

        if {$status ne "unplaced" && $status ne ""} {
            continue
        }

        incr count
        if {![info exists master_count($master)]} {
            set master_count($master) 0
        }
        incr master_count($master)

        puts [format "UNPLACED %-48s %-32s" $name $master]
    }

    puts "----------------------------------------------------------------------"
    puts "UNPLACED TOTAL : $count"
    puts ""
    puts "UNPLACED BY MASTER:"

    if {[array size master_count] == 0} {
        puts "  <none>"
    } else {
        foreach master [lsort [array names master_count]] {
            puts [format "  %-40s %8d" $master $master_count($master)]
        }
    }

    puts "======================================================================"
    return $count
}

# -----------------------------------------------------------------------------
# Public: design-wide physical summary
#
# Option:
#   -run_check_place
#   -skip_iofiller
# -----------------------------------------------------------------------------
proc TT_PHY_summary {args} {
    set run_check_place 0
    set skip_iofiller 0

    foreach arg $args {
        switch -- $arg {
            "-run_check_place" {
                set run_check_place 1
            }
            "-skip_iofiller" {
                set skip_iofiller 1
            }
            default {
                error "Unknown option: $arg"
            }
        }
    }

    if {$run_check_place} {
        puts "INFO: Running check_place for physical summary."
        check_place
    }

    array unset status_count
    set total 0

    foreach inst [get_db insts] {
        set name [TT_PHY__safe_get $inst .name ""]
        if {$skip_iofiller && [string match "IOFILLER*" $name]} {
            continue
        }

        set status [TT_PHY__safe_get $inst .place_status "UNKNOWN"]
        if {$status eq ""} {
            set status "UNKNOWN"
        }

        incr total
        if {![info exists status_count($status)]} {
            set status_count($status) 0
        }
        incr status_count($status)
    }

    puts ""
    puts "======================================================================"
    puts " TT PHYSICAL DESIGN SUMMARY"
    puts "======================================================================"
    puts "Instances scanned : $total"
    puts ""
    puts "PLACE STATUS:"
    foreach status [lsort [array names status_count]] {
        puts [format "  %-20s %8d" $status $status_count($status)]
    }

    set marker_total 0
    array unset marker_count

    set markers ""
    catch {set markers [get_db markers]}
    foreach marker $markers {
        set originator [TT_PHY__safe_get $marker .originator ""]
        if {$originator ne "check_place"} {
            continue
        }

        set type    [TT_PHY__safe_get $marker .type ""]
        set subtype [TT_PHY__safe_get $marker .subtype ""]
        set key "$type/$subtype"

        if {![info exists marker_count($key)]} {
            set marker_count($key) 0
        }
        incr marker_count($key)
        incr marker_total
    }

    puts ""
    puts "CHECK_PLACE MARKERS:"
    if {$marker_total == 0} {
        puts "  <none in current marker database>"
    } else {
        foreach key [lsort [array names marker_count]] {
            puts [format "  %-48s %8d" $key $marker_count($key)]
        }
    }

    puts "----------------------------------------------------------------------"
    puts "check_place marker total : $marker_total"
    puts "======================================================================"

    return $marker_total
}

proc TT_LVS_help {} {
    puts ""
    puts "======================================================================"
    puts " TT_proc_LVS_debug.tcl"
    puts "======================================================================"
    puts "CONNECTIVITY"
    puts "  Selected instance connectivity:"
    puts "    TT_LVS_check_selected"
    puts ""
    puts "  Named instance connectivity:"
    puts "    TT_LVS_check_inst pad_RTE_VDD_LEVEL_02"
    puts ""
    puts "  Find all floating pins:"
    puts "    TT_LVS_find_floating_pins"
    puts "    TT_LVS_find_floating_pins -skip_iofiller"
    puts "    TT_LVS_find_floating_pins -pg_only"
    puts "    TT_LVS_find_floating_pins -signal_only"
    puts ""
    puts "PHYSICAL"
    puts "  Selected instance connectivity + physical check:"
    puts "    TT_LVS_check_selected_full"
    puts ""
    puts "  Run check_place first, then inspect selection:"
    puts "    TT_LVS_check_selected_full -run_check_place"
    puts ""
    puts "  Physical check for one instance:"
    puts "    TT_PHY_check_inst pad_RTE_VDD_LEVEL_02"
    puts ""
    puts "  Find all unplaced instances:"
    puts "    TT_PHY_find_unplaced"
    puts "    TT_PHY_find_unplaced -skip_iofiller"
    puts ""
    puts "  Design-wide physical summary using current markers:"
    puts "    TT_PHY_summary"
    puts ""
    puts "  Run check_place and summarize physical violations:"
    puts "    TT_PHY_summary -run_check_place"
    puts ""
    puts "This tool is debug/read-only with respect to design connectivity and"
    puts "placement geometry.  -run_check_place refreshes Innovus check markers."
    puts "======================================================================"
}

puts "INFO: TT_proc_LVS_debug.tcl loaded."
puts "INFO: Run TT_LVS_help for available commands."


# =============================================================================
# PHYSICAL CONNECTIVITY DEBUG
# =============================================================================

proc TT_PCONN__get_first_attr {obj attrs} {
    foreach attr $attrs {
        set value ""
        if {![catch {set value [get_db $obj $attr]}] && [llength $value] > 0} {
            return $value
        }
    }
    return ""
}

proc TT_PCONN__obj_bbox {obj} {
    set bbox [TT_PCONN__get_first_attr $obj {.bbox .rect .box}]
    return [TT_PHY__bbox4 $bbox]
}

proc TT_PCONN__obj_layer_name {obj} {
    foreach attr {.layer.name .layer.base_name .layer .layer_name} {
        set layer ""
        if {![catch {set layer [get_db $obj $attr]}] && $layer ne ""} {
            if {[string match "layer:*" $layer]} {
                set tmp ""
                if {![catch {set tmp [get_db $layer .name]}] && $tmp ne ""} {
                    set layer $tmp
                }
            }
            return $layer
        }
    }
    return ""
}

proc TT_PCONN__pin_shapes {pin} {
    foreach attr {
        .layer_shapes
        .shapes
        .physical_pins.layer_shapes
        .physical_pins.shapes
        .base_pin.layer_shapes
        .base_pin.shapes
    } {
        set objs ""
        if {![catch {set objs [get_db $pin $attr]}] && [llength $objs] > 0} {
            return $objs
        }
    }
    return ""
}

proc TT_PCONN__net_route_objects {net_obj} {
    set result {}

    foreach attr {
        .wires
        .wire_segments
        .route_wires
        .routes
        .special_wires
        .special_wire_segments
        .sroute_wires
        .pg_wires
        .vias
        .special_vias
        .route_vias
        .pg_vias
    } {
        set objs ""
        if {![catch {set objs [get_db $net_obj $attr]}] && [llength $objs] > 0} {
            foreach o $objs {
                if {[lsearch -exact $result $o] < 0} {
                    lappend result $o
                }
            }
        }
    }

    return $result
}

proc TT_PCONN__bbox_touches {a b {eps 0.001}} {
    set aa [TT_PHY__bbox4 $a]
    set bb [TT_PHY__bbox4 $b]

    if {$aa eq "" || $bb eq ""} {
        return 0
    }

    lassign $aa ax1 ay1 ax2 ay2
    lassign $bb bx1 by1 bx2 by2

    return [expr {
        !($ax2 < ($bx1 - $eps) ||
          $bx2 < ($ax1 - $eps) ||
          $ay2 < ($by1 - $eps) ||
          $by2 < ($ay1 - $eps))
    }]
}

proc TT_PCONN__pin_physical_status {pin {verbose 0}} {
    set result [dict create \
        logical_net "" \
        pin_shapes 0 \
        route_objects 0 \
        touch_count 0 \
        status "UNKNOWN"]

    set net_obj ""
    catch {set net_obj [get_db $pin .net]}

    if {[llength $net_obj] == 0} {
        dict set result status "LOGICAL_FLOATING"
        return $result
    }

    set net_obj [lindex $net_obj 0]

    set net_name ""
    catch {set net_name [get_db $net_obj .base_name]}
    if {$net_name eq ""} {
        catch {set net_name [get_db $net_obj .name]}
    }
    dict set result logical_net $net_name

    set pin_shapes [TT_PCONN__pin_shapes $pin]
    set route_objs [TT_PCONN__net_route_objects $net_obj]

    dict set result pin_shapes [llength $pin_shapes]
    dict set result route_objects [llength $route_objs]

    if {[llength $pin_shapes] == 0} {
        set pb [TT_PCONN__obj_bbox $pin]
        if {$pb ne ""} {
            set pin_shapes [list $pin]
            dict set result pin_shapes 1
        }
    }

    if {[llength $pin_shapes] == 0} {
        dict set result status "NO_PIN_GEOMETRY"
        return $result
    }

    if {[llength $route_objs] == 0} {
        dict set result status "NO_ROUTE_GEOMETRY"
        return $result
    }

    set touches 0

    foreach ps $pin_shapes {
        set pb [TT_PCONN__obj_bbox $ps]
        if {$pb eq ""} {
            continue
        }

        set pl [TT_PCONN__obj_layer_name $ps]

        foreach ro $route_objs {
            set rb [TT_PCONN__obj_bbox $ro]
            if {$rb eq ""} {
                continue
            }

            set rl [TT_PCONN__obj_layer_name $ro]

            if {$pl ne "" && $rl ne "" && $pl ne $rl} {
                continue
            }

            if {[TT_PCONN__bbox_touches $pb $rb]} {
                incr touches

                if {$verbose} {
                    puts "      TOUCH pin_layer=$pl pin_bbox=$pb route_layer=$rl route_bbox=$rb"
                }
            }
        }
    }

    dict set result touch_count $touches

    if {$touches > 0} {
        dict set result status "PHYSICAL_CONNECTED"
    } else {
        dict set result status "PHYSICAL_OPEN"
    }

    return $result
}

proc TT_PCONN__print_pin {pin pin_kind {verbose 0}} {
    set pin_name ""
    catch {set pin_name [get_db $pin .base_name]}

    set r [TT_PCONN__pin_physical_status $pin $verbose]

    puts [format \
        "  %-7s %-20s logical=%-24s physical=%-20s shapes=%-4d route_objs=%-6d touches=%d" \
        $pin_kind \
        $pin_name \
        [dict get $r logical_net] \
        [dict get $r status] \
        [dict get $r pin_shapes] \
        [dict get $r route_objects] \
        [dict get $r touch_count]]

    return $r
}

# -----------------------------------------------------------------------------
# Check one instance's physical connectivity
# -----------------------------------------------------------------------------
proc TT_LVS_check_inst_physical {inst_or_name args} {
    set verbose 0

    foreach arg $args {
        switch -- $arg {
            "-verbose" { set verbose 1 }
            default { error "Unknown option: $arg" }
        }
    }

    set inst [TT_LVS__resolve_inst $inst_or_name]

    if {$inst eq ""} {
        error "Instance not found: $inst_or_name"
    }

    set inst_name [get_db $inst .name]
    set master    [get_db $inst .base_cell.name]

    puts ""
    puts "======================================================================"
    puts " TT LVS PHYSICAL CONNECTIVITY CHECK"
    puts "======================================================================"
    puts "Instance : $inst_name"
    puts "Master   : $master"
    puts "======================================================================"

    set total 0
    set logical_float 0
    set physical_open 0
    set no_pin_geometry 0
    set no_route_geometry 0
    set connected 0

    puts ""
    puts "----------------------------------------------------------------------"
    puts " PG PINS"
    puts "----------------------------------------------------------------------"

    foreach pin [get_db $inst .pg_pins] {
        incr total
        set r [TT_PCONN__print_pin $pin "PG" $verbose]

        switch -- [dict get $r status] {
            "PHYSICAL_CONNECTED" { incr connected }
            "LOGICAL_FLOATING" { incr logical_float }
            "PHYSICAL_OPEN" { incr physical_open }
            "NO_PIN_GEOMETRY" { incr no_pin_geometry }
            "NO_ROUTE_GEOMETRY" { incr no_route_geometry }
        }
    }

    puts ""
    puts "----------------------------------------------------------------------"
    puts " SIGNAL PINS"
    puts "----------------------------------------------------------------------"

    foreach pin [get_db $inst .pins] {
        incr total
        set r [TT_PCONN__print_pin $pin "SIGNAL" $verbose]

        switch -- [dict get $r status] {
            "PHYSICAL_CONNECTED" { incr connected }
            "LOGICAL_FLOATING" { incr logical_float }
            "PHYSICAL_OPEN" { incr physical_open }
            "NO_PIN_GEOMETRY" { incr no_pin_geometry }
            "NO_ROUTE_GEOMETRY" { incr no_route_geometry }
        }
    }

    puts ""
    puts "----------------------------------------------------------------------"
    puts "Pins checked       : $total"
    puts "Physical connected : $connected"
    puts "Logical floating   : $logical_float"
    puts "Physical open      : $physical_open"
    puts "No pin geometry    : $no_pin_geometry"
    puts "No route geometry  : $no_route_geometry"

    if {$logical_float == 0 &&
        $physical_open == 0 &&
        $no_pin_geometry == 0 &&
        $no_route_geometry == 0} {
        puts "RESULT             : PASS"
    } else {
        puts "RESULT             : CONNECTIVITY ISSUE FOUND"
    }

    puts "======================================================================"

    return [expr {
        $logical_float +
        $physical_open +
        $no_pin_geometry +
        $no_route_geometry
    }]
}

# -----------------------------------------------------------------------------
# Check currently selected instance(s)
# -----------------------------------------------------------------------------
proc TT_LVS_check_selected_physical {args} {
    set selected ""
    catch {set selected [get_db selected]}

    set insts {}

    foreach obj $selected {
        set obj_type ""
        catch {set obj_type [get_db $obj .obj_type]}

        if {$obj_type eq "inst"} {
            lappend insts $obj
        }
    }

    if {[llength $insts] == 0} {
        error "No instance is selected."
    }

    set total_issue 0

    foreach inst $insts {
        incr total_issue [TT_LVS_check_inst_physical $inst {*}$args]
    }

    return $total_issue
}

# -----------------------------------------------------------------------------
# Scan all design pins for physical opens
#
# Usage:
#   TT_LVS_find_physical_opens -skip_iofiller
#   TT_LVS_find_physical_opens -pg_only -skip_iofiller
#   TT_LVS_find_physical_opens -signal_only
# -----------------------------------------------------------------------------
proc TT_LVS_find_physical_opens {args} {
    set skip_iofiller 0
    set scan_pg 1
    set scan_signal 1

    foreach arg $args {
        switch -- $arg {
            "-skip_iofiller" { set skip_iofiller 1 }
            "-pg_only" {
                set scan_pg 1
                set scan_signal 0
            }
            "-signal_only" {
                set scan_pg 0
                set scan_signal 1
            }
            default { error "Unknown option: $arg" }
        }
    }

    puts ""
    puts "======================================================================"
    puts " TT LVS PHYSICAL OPEN SCAN"
    puts "======================================================================"

    set checked 0
    set connected 0
    set logical_float 0
    set physical_open 0
    set no_pin_geometry 0
    set no_route_geometry 0

    array unset open_master_count

    foreach inst [get_db insts] {
        set inst_name [get_db $inst .name]
        set master    [get_db $inst .base_cell.name]

        if {$skip_iofiller && [string match "IOFILLER*" $inst_name]} {
            continue
        }

        set groups {}

        if {$scan_pg} {
            lappend groups [list "PG" [get_db $inst .pg_pins]]
        }

        if {$scan_signal} {
            lappend groups [list "SIGNAL" [get_db $inst .pins]]
        }

        foreach grp $groups {
            lassign $grp kind pins

            foreach pin $pins {
                incr checked

                set pin_name [get_db $pin .base_name]
                set r [TT_PCONN__pin_physical_status $pin 0]
                set status [dict get $r status]

                switch -- $status {
                    "PHYSICAL_CONNECTED" {
                        incr connected
                    }

                    "LOGICAL_FLOATING" {
                        incr logical_float
                        puts [format \
                            "LOGICAL_FLOAT %-7s %-45s %-30s %-18s" \
                            $kind $inst_name $master $pin_name]
                    }

                    "NO_PIN_GEOMETRY" {
                        incr no_pin_geometry
                        puts [format \
                            "NO_PIN_GEOM   %-7s %-45s %-30s %-18s net=%s" \
                            $kind \
                            $inst_name \
                            $master \
                            $pin_name \
                            [dict get $r logical_net]]
                    }

                    "NO_ROUTE_GEOMETRY" {
                        incr no_route_geometry
                        puts [format \
                            "NO_ROUTE_GEOM %-7s %-45s %-30s %-18s net=%s" \
                            $kind \
                            $inst_name \
                            $master \
                            $pin_name \
                            [dict get $r logical_net]]
                    }

                    "PHYSICAL_OPEN" {
                        incr physical_open

                        if {![info exists open_master_count($master)]} {
                            set open_master_count($master) 0
                        }
                        incr open_master_count($master)

                        puts [format \
                            "PHYSICAL_OPEN %-7s %-45s %-30s %-18s net=%-24s shapes=%d route_objs=%d" \
                            $kind \
                            $inst_name \
                            $master \
                            $pin_name \
                            [dict get $r logical_net] \
                            [dict get $r pin_shapes] \
                            [dict get $r route_objects]]
                    }
                }
            }
        }
    }

    puts ""
    puts "======================================================================"
    puts " PHYSICAL CONNECTIVITY SUMMARY"
    puts "======================================================================"
    puts "Pins checked       : $checked"
    puts "Physical connected : $connected"
    puts "Logical floating   : $logical_float"
    puts "Physical open      : $physical_open"
    puts "No pin geometry    : $no_pin_geometry"
    puts "No route geometry  : $no_route_geometry"

    puts ""
    puts "----------------------------------------------------------------------"
    puts " PHYSICAL OPEN COUNT BY MASTER"
    puts "----------------------------------------------------------------------"

    if {[array size open_master_count] == 0} {
        puts "  <none>"
    } else {
        foreach master [lsort [array names open_master_count]] {
            puts [format "  %-40s %8d" $master $open_master_count($master)]
        }
    }

    puts "======================================================================"

    return $physical_open
}

# -----------------------------------------------------------------------------
# Optional independent Innovus full-chip physical connectivity verification.
# -----------------------------------------------------------------------------
proc TT_LVS_verify_connectivity {} {
    if {[llength [info commands verifyConnectivity]]} {
        puts "INFO: Running Innovus verifyConnectivity."
        if {![catch {uplevel #0 [list verifyConnectivity -type all]} err]} {
            return
        }

        puts "WARNING: verifyConnectivity -type all failed: $err"
        puts "INFO: Retrying verifyConnectivity with default arguments."
        return [uplevel #0 [list verifyConnectivity]]
    }

    if {[llength [info commands verify_connectivity]]} {
        puts "INFO: Running Innovus verify_connectivity."
        return [uplevel #0 [list verify_connectivity]]
    }

    puts "WARNING: No verifyConnectivity/verify_connectivity command is available."
}

# Extend help.
rename TT_LVS_help TT_LVS_help__placement_version

proc TT_LVS_help {} {
    TT_LVS_help__placement_version

    puts ""
    puts "======================================================================"
    puts " PHYSICAL CONNECTIVITY COMMANDS"
    puts "======================================================================"
    puts "Selected instance(s):"
    puts "  TT_LVS_check_selected_physical"
    puts "  TT_LVS_check_selected_physical -verbose"
    puts ""
    puts "Named instance:"
    puts "  TT_LVS_check_inst_physical pad_RTE_VDD_LEVEL_02"
    puts "  TT_LVS_check_inst_physical pad_RTE_VDD_LEVEL_02 -verbose"
    puts ""
    puts "Full-design physical open scan:"
    puts "  TT_LVS_find_physical_opens -skip_iofiller"
    puts "  TT_LVS_find_physical_opens -pg_only -skip_iofiller"
    puts "  TT_LVS_find_physical_opens -signal_only"
    puts ""
    puts "Innovus built-in cross-check:"
    puts "  TT_LVS_verify_connectivity"
    puts ""
    puts "Status meaning:"
    puts "  PHYSICAL_CONNECTED : logical net route physically touches pin geometry"
    puts "  PHYSICAL_OPEN      : logical net exists but no route touch is found"
    puts "  LOGICAL_FLOATING   : pin has no logical net"
    puts "  NO_PIN_GEOMETRY    : pin geometry could not be obtained"
    puts "  NO_ROUTE_GEOMETRY  : logical net has no routed geometry"
    puts "======================================================================"
}

puts "INFO: TT_proc_LVS_debug physical-connectivity extension loaded."
