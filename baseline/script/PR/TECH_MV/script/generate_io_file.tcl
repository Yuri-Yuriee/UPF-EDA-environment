# =============================================================================
# Automatically generate the Innovus IO assignment file
#
# This script must be sourced after create_pg_pad.tcl.
#
# Distribution policy:
#   1. Record all PG PAD instances.
#   2. Query all PAD instances with: get_db insts -if {.is_pad == true}
#   3. Use one RTE PAD for every configured RTE_PAD_SUPPLY_NETS entry.
#   4. Keep the total IO-file PAD count on the four sides as balanced as possible.
#   5. Keep all supply RTE pads on the top/N side.
#   6. Place each RTE pad immediately counter-clockwise from its configured IO family anchor.
#   7. Place the PG PAD group near the center of every side.
#   8. Preserve the signal PAD database order.
#
# Top-side RTE/CUT rule for {BASE SUPPLY2 ... SUPPLYN}:
#
#   ... RAILCUT_SUPPLY2_TOP1 RTE_SUPPLY2 CORE_SUPPLY2 RAILCUT_SUPPLY2_TOP2 ...
#   ... RAILCUT_SUPPLYN_TOP1 RTE_SUPPLYN CORE_SUPPLYN RAILCUT_SUPPLYN_TOP2
#       RTE_BASE ...
#
# Therefore exactly one RTE pad exists per supply type.
#
# PG suffix-to-side mapping:
#   *_PG1 -> top
#   *_PG2 -> right
#   *_PG3 -> bottom
#   *_PG4 -> left
# =============================================================================

puts "User script [info script]"

if {[info exists ::ENABLE_IOPAD_RING_MODEL] && $::ENABLE_IOPAD_RING_MODEL} {
    if {![info exists ::IOPAD_RING_MODEL_ACTIVE] || !$::IOPAD_RING_MODEL_ACTIVE} {
        source -quiet [file join $SCRIPT_DIR build_iopad_ring_model.tcl]
    }
    source -quiet [file join $SCRIPT_DIR generate_io_file_ring_model.tcl]
    if {[info exists ::BOND_PAD_PARITY_FILE] && [file isfile $::BOND_PAD_PARITY_FILE]} {
        file delete -force $::BOND_PAD_PARITY_FILE
        puts "INFO: Removed stale bond-pad parity because IO_FILE was regenerated."
    }
    return
}

# Convert an Innovus instance object/name into the local instance name expected
# by a write_io_file-style file.
proc auto_io_local_inst_name {inst_obj} {
    set inst_name [get_db $inst_obj .name]

    # get_db may return CHIP/u_inst, /CHIP/u_inst, or inst:CHIP/u_inst.
    regsub {^inst:} $inst_name {} inst_name
    set inst_name [string trimleft $inst_name /]

    if {[info exists ::TOP_MODULE]} {
        set top_prefix "${::TOP_MODULE}/"
        if {[string first $top_prefix $inst_name] == 0} {
            set inst_name [string range $inst_name [string length $top_prefix] end]
        }
    }

    return $inst_name
}

# Find one instance by local name. pad_RTE is required by the io_rte supply
# connection, but it may not be marked with .is_pad == true.
proc auto_io_find_inst_by_local_name {local_name} {
    set patterns [list $local_name "*/$local_name"]
    if {[info exists ::TOP_MODULE]} {
        set patterns [linsert $patterns 1 "${::TOP_MODULE}/$local_name"]
    }

    foreach pattern $patterns {
        if {![catch {set matches [get_db insts $pattern]}] && [llength $matches] > 0} {
            return [lindex $matches 0]
        }
    }

    return ""
}

# Remove every exact occurrence of one value from a list.
proc auto_io_remove_exact {values target} {
    set result {}
    foreach value $values {
        if {$value ne $target} {
            lappend result $value
        }
    }
    return $result
}

# Return the side associated with a PG pad suffix.
proc auto_io_pg_side {inst_name} {
    if {[regexp {_PG1$} $inst_name]} { return top }
    if {[regexp {_PG2$} $inst_name]} { return right }
    if {[regexp {_PG3$} $inst_name]} { return bottom }
    if {[regexp {_PG4$} $inst_name]} { return left }
    return ""
}

# Return the PG suffix number used by a side.
proc auto_io_side_pg_index {side} {
    switch -- $side {
        top    { return 1 }
        right  { return 2 }
        bottom { return 3 }
        left   { return 4 }
        default { error "Unknown IO side: $side" }
    }
}

# Return the configured IO family side token used by create_pg_pad.tcl.
proc auto_io_railcut_side_token {side} {
    switch -- $side {
        top    { return TOP }
        right  { return RIGHT }
        bottom { return BOTTOM }
        left   { return LEFT }
        default { error "Unknown IO side: $side" }
    }
}

# Write one instance entry using the Innovus IO file syntax.
proc auto_io_write_inst {fp inst_name {orientation ""} {offset ""}} {
    set fields [list "name=\"$inst_name\""]
    if {$orientation ne ""} { lappend fields "orientation=$orientation" }
    if {$offset ne ""} { lappend fields "offset=$offset" }
    puts $fp "\t(inst [join $fields { }])"
}

proc auto_io_side_length {side} {
    if {![info exists ::FLOORPLAN_BOX_SIZE] || [llength $::FLOORPLAN_BOX_SIZE] < 4} {
        error "FLOORPLAN_BOX_SIZE is unavailable for IO corner-offset calculation"
    }
    lassign [lrange $::FLOORPLAN_BOX_SIZE 0 3] llx lly urx ury
    if {$side eq "top" || $side eq "bottom"} { return [expr {$urx - $llx}] }
    return [expr {$ury - $lly}]
}

proc auto_io_inst_tangent_size {inst_name side} {
    set inst [auto_io_find_inst_by_local_name $inst_name]
    if {$inst eq ""} { error "Cannot calculate IO offset: instance '$inst_name' was not found" }
    set bc [get_db $inst .base_cell]

    # floorplan.tcl swaps side pads after read_io_file: top/bottom -> *_V,
    # left/right -> *_H.  Use that final base-cell geometry when available so
    # the last-pad offset reserves the requested corner clearance after swap.
    if {[info exists ::ENABLE_IO_SWAP] && $::ENABLE_IO_SWAP} {
        set bc_name [get_db $bc .name]
        set target_hv [expr {$side eq "top" || $side eq "bottom" ? "V" : "H"}]
        if {[regexp {^(.*)_[HV]$} $bc_name -> stem]} {
            set target_name "${stem}_${target_hv}"
            set target_bc [get_db base_cells $target_name]
            if {[llength $target_bc] > 0} { set bc [lindex $target_bc 0] }
        }
    }

    set llx [get_db $bc .bbox.ll.x]
    set lly [get_db $bc .bbox.ll.y]
    set urx [get_db $bc .bbox.ur.x]
    set ury [get_db $bc .bbox.ur.y]
    if {$side eq "top" || $side eq "bottom"} { return [expr {$urx - $llx}] }
    return [expr {$ury - $lly}]
}

proc auto_io_write_side_entries {fp side entries} {
    set n [llength $entries]
    if {$n == 0} { return }
    set use_corner_offset [expr {[info exists ::ENABLE_IO_CORNER_OFFSET] && $::ENABLE_IO_CORNER_OFFSET}]
    set edge_len [auto_io_side_length $side]
    for {set i 0} {$i < $n} {incr i} {
        set inst_name [lindex $entries $i]
        set offset ""
        if {$use_corner_offset && $i == 0} {
            set offset [format %.3f $::IO_CORNER_PAD_OFFSET]
        } elseif {$use_corner_offset && $i == ($n - 1)} {
            set tangent [auto_io_inst_tangent_size $inst_name $side]
            set last_offset [expr {$edge_len - $::IO_CORNER_PAD_OFFSET - $tangent}]
            if {$last_offset <= $::IO_CORNER_PAD_OFFSET} {
                error "IO_CORNER_PAD_OFFSET=$::IO_CORNER_PAD_OFFSET is too large for side '$side'"
            }
            set offset [format %.3f $last_offset]
        }
        auto_io_write_inst $fp $inst_name "" $offset
    }
}

# Split a list according to per-side counts.
proc auto_io_take {list_var count} {
    upvar 1 $list_var values

    if {$count <= 0} {
        return {}
    }

    set taken [lrange $values 0 [expr {$count - 1}]]
    set values [lrange $values $count end]
    return $taken
}

# Build the centered PG/configured IO family group for one side. The order matches the
# existing TECH_MV convention as closely as possible:
#   first core supply -> IO supply -> remaining core supplies wrapped by configured IO family.

# Add supply RTE pads to the TOP PG/CUT group.
#
# IO-file side lists are emitted in the same counter-clockwise traversal used by
# this generator:
#   top-right -> top -> top-left -> left -> bottom-left -> bottom -> ...
#
# "counter-clockwise from CUT" therefore means immediately AFTER the CUT entry
# in the top-side list.
proc auto_io_insert_top_rte_ccw {pg_group} {
    if {![info exists ::AUTO_IO_RTE_PAD_BY_SUPPLY]} {
        error "AUTO_IO_RTE_PAD_BY_SUPPLY is undefined; create_rte_pad.tcl must run first"
    }

    set supplies $::RTE_PAD_SUPPLY_NETS
    if {[llength $supplies] == 0} {
        return $pg_group
    }

    # With only one supply there is no configured IO family boundary. Put the single RTE after
    # the existing top PG group instead of inventing a cut.
    if {[llength $supplies] == 1} {
        set base_supply [lindex $supplies 0]
        return [concat $pg_group [list [dict get $::AUTO_IO_RTE_PAD_BY_SUPPLY $base_supply]]]
    }

    set result $pg_group

    # Secondary supplies: CUT1 -> RTE -> CORE_PG -> CUT2.
    foreach supply [lrange $supplies 1 end] {
        set cut_name "RAILCUT_${supply}_TOP1"
        set rte_name [dict get $::AUTO_IO_RTE_PAD_BY_SUPPLY $supply]

        set pos [lsearch -exact $result $cut_name]
        if {$pos < 0} {
            error "Cannot place RTE '$rte_name': top-side CUT '$cut_name' was not found"
        }

        set result [linsert $result [expr {$pos + 1}] $rte_name]
    }

    # Base/first supply: the final CUT2 returns into the base-supply region.
    # Put its RTE immediately CCW from that final cut.
    set base_supply [lindex $supplies 0]
    set last_secondary [lindex $supplies end]
    set final_cut "RAILCUT_${last_secondary}_TOP2"
    set base_rte [dict get $::AUTO_IO_RTE_PAD_BY_SUPPLY $base_supply]

    set pos [lsearch -exact $result $final_cut]
    if {$pos < 0} {
        error "Cannot place base-supply RTE '$base_rte': final top-side CUT '$final_cut' was not found"
    }

    set result [linsert $result [expr {$pos + 1}] $base_rte]
    return $result
}

proc auto_io_build_pg_group {side side_pg_names} {
    set group {}
    set pg_index [auto_io_side_pg_index $side]
    set side_token [auto_io_railcut_side_token $side]
    set used [dict create]

    # First core supply in power_port, normally VDD_core.
    if {[info exists ::POWER_PORT_NETS] && [llength $::POWER_PORT_NETS] > 0} {
        set first_power [lindex $::POWER_PORT_NETS 0]
        set first_pg "CORE_${first_power}_PG${pg_index}"
        if {[lsearch -exact $side_pg_names $first_pg] >= 0} {
            lappend group $first_pg
            dict set used $first_pg 1
        }
    }

    # IO supply pad.
    set io_pg "IO_PG${pg_index}"
    if {[lsearch -exact $side_pg_names $io_pg] >= 0} {
        lappend group $io_pg
        dict set used $io_pg 1
    }

    # Other core supplies, with the configured IO family pair generated by create_pg_pad.tcl.
    if {[info exists ::POWER_PORT_NETS]} {
        foreach power_name [lrange $::POWER_PORT_NETS 1 end] {
            set core_pg "CORE_${power_name}_PG${pg_index}"
            if {[lsearch -exact $side_pg_names $core_pg] >= 0} {
                lappend group "RAILCUT_${power_name}_${side_token}1"
                lappend group $core_pg
                lappend group "RAILCUT_${power_name}_${side_token}2"
                dict set used $core_pg 1
            }
        }
    }

    # Preserve any additional PG pad not covered by the known naming scheme.
    foreach pg_name $side_pg_names {
        if {![dict exists $used $pg_name]} {
            lappend group $pg_name
        }
    }

    return $group
}

# -----------------------------------------------------------------------------
# 1. Query every PAD and record the PG PAD instances/count.
# -----------------------------------------------------------------------------
set all_pad_objs [get_db insts -if {.is_pad == true}]
set all_pad_names {}
set pg_pad_names {}
set signal_pad_names {}

foreach pad_obj $all_pad_objs {
    set pad_name [auto_io_local_inst_name $pad_obj]
    lappend all_pad_names $pad_name

    if {[regexp {^(IO_PG[0-9]+|CORE_.+_PG[0-9]+)$} $pad_name]} {
        lappend pg_pad_names $pad_name
    } else {
        lappend signal_pad_names $pad_name
    }
}

# create_rte_pad.tcl must have created/registered exactly one RTE pad per
# configured supply type before this IO file is generated.
if {![info exists ::AUTO_IO_RTE_PAD_NAMES] ||
    ![info exists ::AUTO_IO_RTE_PAD_BY_SUPPLY]} {
    error "Supply RTE-pad information is missing. create_rte_pad.tcl must run before generate_io_file.tcl"
}

set rte_pad_names $::AUTO_IO_RTE_PAD_NAMES
set expected_rte_count [llength $::RTE_PAD_SUPPLY_NETS]
set rte_pad_count [llength $rte_pad_names]

if {$rte_pad_count != $expected_rte_count} {
    error "RTE pad count mismatch: supplies=$expected_rte_count RTE_pads=$rte_pad_count"
}

# RTE pad cells may or may not be returned by .is_pad depending on the library.
# Remove every RTE instance from the normal signal-pad pool so it is written
# exactly once at its CUT-relative location.
foreach rte_pad_name $rte_pad_names {
    if {[auto_io_find_inst_by_local_name $rte_pad_name] eq ""} {
        error "Configured RTE PAD instance '$rte_pad_name' was not found"
    }
    set signal_pad_names [auto_io_remove_exact $signal_pad_names $rte_pad_name]
}

set queried_pad_count [llength $all_pad_names]
set pg_pad_count      [llength $pg_pad_names]
set signal_pad_count  [llength $signal_pad_names]
set io_file_pad_count [expr {$pg_pad_count + $signal_pad_count + $rte_pad_count}]

# Keep the recorded values available for later scripts/debugging.
set ::AUTO_IO_ALL_PAD_NAMES     $all_pad_names
set ::AUTO_IO_PG_PAD_NAMES      $pg_pad_names
set ::AUTO_IO_RTE_PAD_NAMES     $rte_pad_names
set ::AUTO_IO_QUERIED_PAD_COUNT $queried_pad_count
set ::AUTO_IO_TOTAL_PAD_COUNT   $io_file_pad_count
set ::AUTO_IO_PG_PAD_COUNT      $pg_pad_count

puts "INFO: Queried .is_pad count = $queried_pad_count"
puts "INFO: RTE supply types       = $RTE_PAD_SUPPLY_NETS"
puts "INFO: RTE PAD count          = $rte_pad_count"
puts "INFO: RTE PAD instances      = $rte_pad_names"
puts "INFO: IO-file PAD count      = $io_file_pad_count"
puts "INFO: PG PAD count           = $pg_pad_count"
puts "INFO: Signal PAD count       = $signal_pad_count"
puts "INFO: PG PAD instances       = $pg_pad_names"

if {$queried_pad_count == 0} {
    error "No PAD instance was found by get_db insts -if {.is_pad == true}"
}

# -----------------------------------------------------------------------------
# 2. Assign PG PADs to sides using the PG1/2/3/4 naming convention.
# -----------------------------------------------------------------------------
set side_order {top right bottom left}
array set side_pg {
    top    {}
    right  {}
    bottom {}
    left   {}
}
set unmapped_pg {}

foreach pg_name $pg_pad_names {
    set side [auto_io_pg_side $pg_name]
    if {$side eq ""} {
        lappend unmapped_pg $pg_name
    } else {
        lappend side_pg($side) $pg_name
    }
}

# If a future PG pad does not use PG1..PG4, assign it to the side currently
# containing the fewest PG pads.
foreach pg_name $unmapped_pg {
    set selected_side [lindex $side_order 0]
    set selected_count [llength $side_pg($selected_side)]

    foreach side [lrange $side_order 1 end] {
        set side_count [llength $side_pg($side)]
        if {$side_count < $selected_count} {
            set selected_side $side
            set selected_count $side_count
        }
    }

    lappend side_pg($selected_side) $pg_name
}

# -----------------------------------------------------------------------------
# 3. Calculate balanced total PAD targets and signal PAD targets.
# -----------------------------------------------------------------------------
set base_side_count [expr {$io_file_pad_count / 4}]
set side_remainder  [expr {$io_file_pad_count % 4}]

array set side_total_target {}
array set side_signal_target {}
array set side_fixed_count {
    top    0
    right  0
    bottom 0
    left   0
}
set side_fixed_count(top) $rte_pad_count

for {set i 0} {$i < 4} {incr i} {
    set side [lindex $side_order $i]
    set target [expr {$base_side_count + ($i < $side_remainder ? 1 : 0)}]
    set pg_count_on_side [llength $side_pg($side)]
    set fixed_count_on_side $side_fixed_count($side)

    set side_total_target($side) $target
    set side_signal_target($side) \
        [expr {$target - $pg_count_on_side - $fixed_count_on_side}]

    if {$side_signal_target($side) < 0} {
        error "Side $side has $pg_count_on_side PG pads and $fixed_count_on_side fixed pads but only $target total-pad slots"
    }
}

# Distribute the signal PADs in their database order.
set remaining_signal_pads $signal_pad_names
array set side_signal {}

foreach side $side_order {
    set side_signal($side) \
        [auto_io_take remaining_signal_pads $side_signal_target($side)]
}

if {[llength $remaining_signal_pads] != 0} {
    error "Internal IO distribution error: [llength $remaining_signal_pads] signal pads remain"
}

# -----------------------------------------------------------------------------
# 4. Build each side and insert its PG group at the center.
# -----------------------------------------------------------------------------
array set side_entries {}

foreach side $side_order {
    set signals $side_signal($side)
    set split_index [expr {([llength $signals] + 1) / 2}]

    set first_half  [lrange $signals 0 [expr {$split_index - 1}]]
    set second_half [lrange $signals $split_index end]
    set pg_group    [auto_io_build_pg_group $side $side_pg($side)]

    if {$side eq "top" && $ENABLE_SUPPLY_RTE_PADS} {
        set pg_group [auto_io_insert_top_rte_ccw $pg_group]
    }

    set side_entries($side) [concat $first_half $pg_group $second_half]

    puts [format \
        "INFO: %-6s total=%3d signal=%3d PG=%2d fixed=%1d" \
        $side \
        $side_total_target($side) \
        [llength $side_signal($side)] \
        [llength $side_pg($side)] \
        $side_fixed_count($side)]
}

# -----------------------------------------------------------------------------
# 5. Write CHIP.io (or ${TOP_MODULE}.io through IO_FILE).
# -----------------------------------------------------------------------------
set io_output_file $IO_FILE
set io_output_dir [file dirname $io_output_file]
if {$io_output_dir ne "." && ![file isdirectory $io_output_dir]} {
    file mkdir $io_output_dir
}

set fp [open $io_output_file w]

puts $fp "###############################################################"
puts $fp "#  Generated automatically by: [info script]"
puts $fp "#  Design:                     $TOP_MODULE"
puts $fp "#  Queried .is_pad count:      $queried_pad_count"
puts $fp "#  IO-file PAD count:          $io_file_pad_count"
puts $fp "#  RTE PAD count:              $rte_pad_count"
puts $fp "#  RTE PADs:                   $rte_pad_names"
puts $fp "#  PG PAD count:               $pg_pad_count"
puts $fp "#  Signal PAD count:           $signal_pad_count"
puts $fp "###############################################################"
puts $fp ""
puts $fp "(globals"
puts $fp "    version = 3"
puts $fp "    io_order = default"
puts $fp ")"
puts $fp "(iopad"

puts $fp "    (topright"
auto_io_write_inst $fp CORNERTR
puts $fp "    )"

puts $fp "    (top"
auto_io_write_side_entries $fp top $side_entries(top)
puts $fp "    )"

puts $fp "    (topleft"
auto_io_write_inst $fp CORNERTL MX
puts $fp "    )"

puts $fp "    (left"
auto_io_write_side_entries $fp left $side_entries(left)
puts $fp "    )"

puts $fp "    (bottomleft"
auto_io_write_inst $fp CORNERBL
puts $fp "    )"

puts $fp "    (bottom"
auto_io_write_side_entries $fp bottom $side_entries(bottom)
puts $fp "    )"

puts $fp "    (bottomright"
auto_io_write_inst $fp CORNERBR MY
puts $fp "    )"

puts $fp "    (right"
auto_io_write_side_entries $fp right $side_entries(right)
puts $fp "    )"

puts $fp ")"
close $fp

puts "INFO: Generated IO file: $io_output_file"
if {[info exists ::BOND_PAD_PARITY_FILE] && [file isfile $::BOND_PAD_PARITY_FILE]} {
    file delete -force $::BOND_PAD_PARITY_FILE
    puts "INFO: Removed stale bond-pad parity because IO_FILE was regenerated."
}
