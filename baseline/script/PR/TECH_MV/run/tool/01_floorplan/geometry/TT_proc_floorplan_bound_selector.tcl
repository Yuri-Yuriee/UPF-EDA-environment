# Runtime adapter preserves the historical logical source path.
if {[info exists ::TECH_MV_RUNTIME_ROOT]} {
    info script [file join $::TECH_MV_RUNTIME_ROOT run/tool/01_floorplan/geometry/TT_proc_floorplan_bound_selector.tcl]
}
# PUBLIC_EXPORT_REVIEW_REQUIRED: residual technology candidates require manual review.
# Load private values before evaluating original parameter defaults.
if {![llength [info commands ::tech_mv_private_value]]} { source [file join $::TECH_MV_RUNTIME_ROOT .. script PR TECH_MV script 00_common private_parameter_config.tcl] }
# =============================================================================
# TT_proc_floorplan_bound_selector.tcl
# TECH_MV Floorplan IO-bound / Core-cell-bound selector
#
# Policy:
#   design_area     = get_db current_design .area
#   pad_area        = physical pad-ring area (all .is_pad plus IO_FILE entries)
#   core_cell_area  = design_area - pad_area
#
#   IO minimum W/H are derived from IO_FILE order, explicit offsets, each
#   PAD's final side-aware H/V master WIDTH, and the configured minimum gap
#   between every adjacent IO-ring element. DB .location is never used.
#
#   IO-defined usable core area =
#       (io_min_die_w - 2*margin) * (io_min_die_h - 2*margin)
#
#   ratio = core_cell_area / io_defined_usable_core_area
#       ratio > threshold => CORE_CELL_BOUND
#       otherwise         => IO_BOUND
# =============================================================================

namespace eval ::TT_FP_BOUND {
    variable version "1.1"
    variable tolerance 1.0e-6
}

proc ::TT_FP_BOUND::num {value label} {
    set v $value
    set guard 0
    while {[llength $v] == 1 && $guard < 4} {
        set inner [lindex $v 0]
        if {$inner eq $v} { break }
        set v $inner
        incr guard
    }
    if {![string is double -strict $v]} {
        error "$label is not numeric: raw='$value' normalized='$v'"
    }
    return [expr {double($v)}]
}

proc ::TT_FP_BOUND::bbox_area {bbox} {
    set v $bbox
    set guard 0
    while {[llength $v] == 1 && $guard < 4} {
        set inner [lindex $v 0]
        if {$inner eq $v} { break }
        set v $inner
        incr guard
    }
    if {[llength $v] != 4} { return 0.0 }
    foreach x $v {
        if {![string is double -strict $x]} { return 0.0 }
    }
    lassign $v llx lly urx ury
    return [expr {abs(double($urx)-double($llx)) * abs(double($ury)-double($lly))}]
}

proc ::TT_FP_BOUND::find_inst {local_name} {
    set patterns [list $local_name "*/$local_name"]
    if {[info exists ::TOP_MODULE]} {
        set patterns [linsert $patterns 1 "${::TOP_MODULE}/$local_name"]
    }
    foreach pattern $patterns {
        set matches {}
        catch { set matches [get_db insts $pattern] }
        foreach I $matches {
            set n ""
            catch { set n [get_db $I .name] }
            regsub {^inst:} $n {} n
            set n [string trimleft $n /]
            if {[info exists ::TOP_MODULE]} {
                set p "${::TOP_MODULE}/"
                if {[string first $p $n] == 0} {
                    set n [string range $n [string length $p] end]
                }
            }
            if {$n eq $local_name} { return $I }
        }
    }
    return ""
}

proc ::TT_FP_BOUND::final_base_cell {inst side} {
    set bc [get_db $inst .base_cell]
    if {![info exists ::ENABLE_IO_SWAP] || !$::ENABLE_IO_SWAP} {
        return $bc
    }

    set bc_name [get_db $bc .name]
    set target_hv [expr {$side eq "top" || $side eq "bottom" ? "V" : "H"}]
    if {[regexp {^(.*)_[HV]$} $bc_name -> stem]} {
        set target_name "${stem}_${target_hv}"
        set target_bc [get_db base_cells $target_name]
        if {[llength $target_bc] > 0} {
            return [lindex $target_bc 0]
        }
    }
    return $bc
}

proc ::TT_FP_BOUND::base_cell_width {bc} {
    set llx [get_db $bc .bbox.ll.x]
    set urx [get_db $bc .bbox.ur.x]
    return [expr {abs(double($urx)-double($llx))}]
}

proc ::TT_FP_BOUND::base_cell_area {bc} {
    set llx [get_db $bc .bbox.ll.x]
    set lly [get_db $bc .bbox.ll.y]
    set urx [get_db $bc .bbox.ur.x]
    set ury [get_db $bc .bbox.ur.y]
    return [expr {abs(double($urx)-double($llx))*abs(double($ury)-double($lly))}]
}

proc ::TT_FP_BOUND::parse_io_file {io_file} {
    set path [file normalize $io_file]
    if {![file isfile $path]} {
        error "IO_FILE does not exist: $path"
    }
    set fp [open $path r]
    set text [read $fp]
    close $fp

    set side ""
    set by_side [dict create top {} right {} bottom {} left {}]
    foreach line [split $text "\n"] {
        set t [string trim $line]
        if {[regexp {^\((top|right|bottom|left)\s*$} $t -> new_side]} {
            set side $new_side
            continue
        }
        if {$side ne "" && $t eq ")"} {
            set side ""
            continue
        }
        if {$side eq ""} { continue }
        if {![regexp {\(inst\s+name="([^"]+)"([^\)]*)\)} $t -> name rest]} {
            continue
        }
        set offset ""
        if {[regexp {offset\s*=\s*([-+0-9.eE]+)} $rest -> off]} {
            set offset $off
        }
        dict lappend by_side $side [dict create name $name offset $offset]
    }
    return $by_side
}

proc ::TT_FP_BOUND::side_min_length {side entries} {
    set cursor 0.0
    set leading_clearance 0.0
    set complete true
    set explicit_conflicts {}
    set detail {}

    if {![info exists ::FLOORPLAN_IO_PAD_MIN_GAP]} {
        set ::FLOORPLAN_IO_PAD_MIN_GAP [::tech_mv_private_value {run/tool/01_floorplan/TT_proc_floorplan_bound_selector.tcl::::FLOORPLAN_IO_PAD_MIN_GAP::L158}]
    }
    set min_gap [expr {double($::FLOORPLAN_IO_PAD_MIN_GAP)}]
    if {$min_gap < 0.0} {
        error "FLOORPLAN_IO_PAD_MIN_GAP must be >= 0; current=$min_gap"
    }

    set idx 0
    set valid_count 0
    foreach e $entries {
        incr idx
        set name [dict get $e name]
        set raw_off [dict get $e offset]
        set I [::TT_FP_BOUND::find_inst $name]
        if {$I eq ""} {
            puts "WARNING: Floorplan bound selector cannot find IO_FILE instance '$name'"
            set complete false
            continue
        }
        set bc [::TT_FP_BOUND::final_base_cell $I $side]
        set width [::TT_FP_BOUND::base_cell_width $bc]

        # Every adjacent pair must retain at least min_gap edge-to-edge.
        # The first valid element has no predecessor on this side.
        set required_start $cursor
        if {$valid_count > 0} {
            set required_start [expr {$cursor + $min_gap}]
        }
        set start $required_start

        if {$raw_off ne ""} {
            if {![string is double -strict $raw_off]} {
                puts "WARNING: Non-numeric offset '$raw_off' on $name"
                set complete false
            } else {
                set off [expr {double($raw_off)}]
                if {$valid_count == 0} { set leading_clearance $off }
                if {$off + $::TT_FP_BOUND::tolerance < $required_start} {
                    # The explicit anchor is too close to the previous element.
                    # Keep a conservative legal packed coordinate for DIE sizing.
                    lappend explicit_conflicts [list $name $off $required_start]
                    set start $required_start
                } else {
                    set start $off
                }
            }
        }

        set end [expr {$start + $width}]
        lappend detail [dict create \
            name $name \
            width $width \
            offset $raw_off \
            required_start $required_start \
            start $start \
            end $end \
            min_gap_before [expr {$valid_count > 0 ? $min_gap : 0.0}]]
        set cursor $end
        incr valid_count
    }

    # Preserve symmetric corner clearance. The current TECH_MV IO generator
    # uses the same corner offset at the leading and trailing corner.
    set min_total [expr {$cursor + $leading_clearance}]
    set gap_count [expr {$valid_count > 0 ? $valid_count - 1 : 0}]
    set gap_budget [expr {$gap_count * $min_gap}]

    return [dict create \
        side $side \
        complete $complete \
        min_length $min_total \
        packed_end $cursor \
        corner_clearance $leading_clearance \
        min_gap $min_gap \
        gap_count $gap_count \
        gap_budget $gap_budget \
        conflicts $explicit_conflicts \
        detail $detail]
}

proc ::TT_FP_BOUND::area_metrics {io_names} {
    set design_area [::TT_FP_BOUND::num [get_db current_design .area] "current_design .area"]

    # Deduplicate by actual instance name. Include all Innovus .is_pad objects
    # plus every IO_FILE instance so RTE / cut-style ring elements that are not
    # flagged .is_pad still count as package-interface area.
    set objects [dict create]
    set pads {}
    catch { set pads [get_db insts -if {.is_pad == true}] }
    foreach I $pads {
        set n [get_db $I .name]
        dict set objects $n $I
    }
    foreach name $io_names {
        set I [::TT_FP_BOUND::find_inst $name]
        if {$I eq ""} { continue }
        set n [get_db $I .name]
        dict set objects $n $I
    }

    set pad_area 0.0
    set pad_count 0
    dict for {n I} $objects {
        set bc [get_db $I .base_cell]
        set a 0.0
        catch { set a [::TT_FP_BOUND::base_cell_area $bc] }
        set pad_area [expr {$pad_area + $a}]
        incr pad_count
    }

    set core_cell_area [expr {$design_area - $pad_area}]
    if {$core_cell_area < 0.0 && abs($core_cell_area) <= 1.0e-3} {
        set core_cell_area 0.0
    }
    if {$core_cell_area < 0.0} {
        error "Computed core-cell area is negative: design_area=$design_area pad_area=$pad_area"
    }

    return [dict create \
        design_area $design_area \
        pad_area $pad_area \
        pad_count $pad_count \
        core_cell_area $core_cell_area]
}

proc ::TT_FP_BOUND::analyze {{io_file ""}} {
    if {$io_file eq ""} {
        if {![info exists ::IO_FILE] || $::IO_FILE eq ""} {
            error "IO_FILE is not configured."
        }
        set io_file $::IO_FILE
    }
    if {![info exists ::FLOORPLAN_BOUND_MARGIN]} { set ::FLOORPLAN_BOUND_MARGIN [::tech_mv_private_value {run/tool/01_floorplan/TT_proc_floorplan_bound_selector.tcl::::FLOORPLAN_BOUND_MARGIN::L290}] }
    if {![info exists ::FLOORPLAN_BOUND_THRESHOLD]} { set ::FLOORPLAN_BOUND_THRESHOLD 0.70 }
    if {![info exists ::FLOORPLAN_IO_PAD_MIN_GAP]} { set ::FLOORPLAN_IO_PAD_MIN_GAP [::tech_mv_private_value {run/tool/01_floorplan/TT_proc_floorplan_bound_selector.tcl::::FLOORPLAN_IO_PAD_MIN_GAP::L292}] }

    set by_side [::TT_FP_BOUND::parse_io_file $io_file]
    set side_results [dict create]
    set all_names {}
    foreach side {top right bottom left} {
        set entries [dict get $by_side $side]
        dict set side_results $side [::TT_FP_BOUND::side_min_length $side $entries]
        foreach e $entries { lappend all_names [dict get $e name] }
    }

    set top_len [dict get $side_results top min_length]
    set bottom_len [dict get $side_results bottom min_length]
    set right_len [dict get $side_results right min_length]
    set left_len [dict get $side_results left min_length]

    set io_w [expr {max($top_len, $bottom_len)}]
    set io_h [expr {max($right_len, $left_len)}]

    set m [expr {double($::FLOORPLAN_BOUND_MARGIN)}]
    set usable_w [expr {$io_w - 2.0*$m}]
    set usable_h [expr {$io_h - 2.0*$m}]
    if {$usable_w <= 0.0 || $usable_h <= 0.0} {
        error "IO-defined die is too small for ${m}um margins: W=$io_w H=$io_h"
    }
    set io_core_area [expr {$usable_w * $usable_h}]

    set am [::TT_FP_BOUND::area_metrics $all_names]
    set core_cell_area [dict get $am core_cell_area]
    set ratio [expr {$core_cell_area / $io_core_area}]
    set mode [expr {$ratio > double($::FLOORPLAN_BOUND_THRESHOLD) ? "CORE_CELL_BOUND" : "IO_BOUND"}]

    set result [dict merge $am [dict create \
        io_file [file normalize $io_file] \
        side_results $side_results \
        io_min_die_w $io_w \
        io_min_die_h $io_h \
        margin $m \
        io_pad_min_gap [expr {double($::FLOORPLAN_IO_PAD_MIN_GAP)}] \
        io_usable_core_w $usable_w \
        io_usable_core_h $usable_h \
        io_floorplan_area $io_core_area \
        ratio $ratio \
        threshold [expr {double($::FLOORPLAN_BOUND_THRESHOLD)}] \
        mode $mode]]

    return $result
}

proc ::TT_FP_BOUND::report {r} {
    puts ""
    puts "======================================================================"
    puts " TECH_MV FLOORPLAN BOUND SELECTOR v$::TT_FP_BOUND::version"
    puts "======================================================================"
    puts "IO_FILE              : [dict get $r io_file]"
    puts [format "Design cell area      : %.3f" [dict get $r design_area]]
    puts [format "PAD/ring area         : %.3f (%d objects)" [dict get $r pad_area] [dict get $r pad_count]]
    puts [format "Core-cell total area  : %.3f" [dict get $r core_cell_area]]
    puts ""
    foreach side {top right bottom left} {
        set sr [dict get $r side_results $side]
        puts [format "%-6s minimum length   : %.3f  corner_clearance=%.3f  min_gap=%.3f  gap_budget=%.3f" \
            [string toupper $side] [dict get $sr min_length] [dict get $sr corner_clearance] \
            [dict get $sr min_gap] [dict get $sr gap_budget]]
        foreach c [dict get $sr conflicts] {
            lassign $c name off cursor
            puts [format "  WARNING spacing/offset conflict: %s offset=%.3f required_start=%.3f" $name $off $cursor]
        }
    }
    puts ""
    puts [format "IO minimum DIE W/H    : %.3f x %.3f" [dict get $r io_min_die_w] [dict get $r io_min_die_h]]
    puts [format "Margin per side       : %.3f" [dict get $r margin]]
    puts [format "Minimum PAD gap       : %.3f" [dict get $r io_pad_min_gap]]
    puts [format "IO usable core W/H    : %.3f x %.3f" [dict get $r io_usable_core_w] [dict get $r io_usable_core_h]]
    puts [format "IO floorplan area     : %.3f" [dict get $r io_floorplan_area]]
    puts [format "Core/IO area ratio    : %.4f (%.2f%%)" [dict get $r ratio] [expr {100.0*[dict get $r ratio]}]]
    puts [format "Threshold             : %.4f (%.2f%%)" [dict get $r threshold] [expr {100.0*[dict get $r threshold]}]]
    puts "BOUND MODE            : [dict get $r mode]"
    if {[dict get $r mode] eq "IO_BOUND"} {
        puts [format "Suggested DIE size    : %.3f x %.3f" [dict get $r io_min_die_w] [dict get $r io_min_die_h]]
    }
    puts "======================================================================"
}

proc TT_floorplan_bound_analyze {{io_file ""}} {
    set r [::TT_FP_BOUND::analyze $io_file]
    ::TT_FP_BOUND::report $r
    set ::TECH_MV_FLOORPLAN_BOUND_RESULT $r
    return $r
}

proc TT_floorplan_bound_create {{io_file ""}} {
    set r [TT_floorplan_bound_analyze $io_file]
    set mode [dict get $r mode]
    if {[info exists ::FLOORPLAN_BOUND_MODE]} {
        switch -- [string tolower $::FLOORPLAN_BOUND_MODE] {
            auto { }
            io_bound - io { set mode IO_BOUND }
            core_cell_bound - core { set mode CORE_CELL_BOUND }
            default { error "Unsupported FLOORPLAN_BOUND_MODE '$::FLOORPLAN_BOUND_MODE'. Use auto, io_bound, or core_cell_bound." }
        }
    }
    dict set r selected_mode $mode
    set ::TECH_MV_FLOORPLAN_BOUND_RESULT $r
    set m [dict get $r margin]

    if {[llength [info commands set_io_flow_flag]] == 0} {
        error "Required Innovus command set_io_flow_flag is unavailable."
    }
    set_io_flow_flag 0

    if {$mode eq "IO_BOUND"} {
        set w [dict get $r io_min_die_w]
        set h [dict get $r io_min_die_h]
        puts "INFO: Creating IO-bound floorplan."
        puts "INFO: create_floorplan -core_margins_by die -site $::CORE_SITE -die_size $w $h $m $m $m $m"
        create_floorplan -core_margins_by die -site $::CORE_SITE \
            -die_size $w $h $m $m $m $m
    } else {
        if {![info exists ::FLOORPLAN_CORE_DENSITY_ASPECT_RATIO]} { set ::FLOORPLAN_CORE_DENSITY_ASPECT_RATIO 1.0 }
        if {![info exists ::FLOORPLAN_CORE_DENSITY_TARGET]} { set ::FLOORPLAN_CORE_DENSITY_TARGET 0.70 }
        set ar $::FLOORPLAN_CORE_DENSITY_ASPECT_RATIO
        set util $::FLOORPLAN_CORE_DENSITY_TARGET
        puts "INFO: Creating core-cell-bound floorplan."
        puts "INFO: create_floorplan -site $::CORE_SITE -core_density_size $ar $util $m $m $m $m"
        create_floorplan -site $::CORE_SITE \
            -core_density_size $ar $util $m $m $m $m
    }

    return $r
}

puts "INFO: Loaded TT_proc_floorplan_bound_selector.tcl v$::TT_FP_BOUND::version"
