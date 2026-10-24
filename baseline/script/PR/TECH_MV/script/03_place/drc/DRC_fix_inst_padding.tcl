# Runtime adapter preserves the historical logical source path.
if {[info exists ::TECH_MV_RUNTIME_ROOT]} {
    info script [file join $::TECH_MV_RUNTIME_ROOT run/tool/03_place/drc/TT_DRC_fix_inst_padding.tcl]
} else {
    info script [file normalize [file join [file dirname [info script]] .. .. .. run/tool/03_place/drc/TT_DRC_fix_inst_padding.tcl]]
}
# DRC_RULE_SPECIFIC_TOOL: named/configured DRC subtype selection is technology-dependent.
# DRC_RULE_REVIEW: Rule names, filters and repair logic are retained for manual planning.
# =============================================================================
# repair_inst_padding.tcl
#
# DRC-marker-guided instance-padding repair for post-route cleanup.
#
# IMPORTANT:
#   set_inst_padding must NOT be applied to Hard Macros or IO instances.
#   Innovus reports an error for those objects and asks for addHaloToBlock.
#   This repair intentionally does not create a halo for blocks/IOs because the
#   purpose here is to spread movable Standard Cells around routing DRCs.
#
# Eligible object:
#   - base_cell.base_class == core
#   - is_pad == false
#   - place_status != fixed / unplaced
#
# Therefore corner pads such as CORNERTR/CORNERTL/CORNERBR/CORNERBL, normal
# IO pads, Hard Macros, and fixed physical-only cells are skipped.
# =============================================================================

foreach _cfg_var {INST_PADDING_ERROR_TYPES INST_PADDING_LEFT INST_PADDING_RIGHT} {
    if {![info exists ::$_cfg_var]} {
        error "Missing config variable $_cfg_var. Source init.setup first."
    }
}
unset _cfg_var


proc tt_padding_safe_get {obj attr {default ""}} {
    set value $default
    catch {set value [get_db $obj $attr]}
    return $value
}

proc tt_padding_safe_name {inst} {
    set name [tt_padding_safe_get $inst .name $inst]

    # Normalize object-like/full top names without assuming a fixed CHIP prefix.
    regsub {^inst:} $name {} name
    set name [string trimleft $name /]

    if {[info exists ::TOP_MODULE]} {
        set prefix "${::TOP_MODULE}/"
        if {[string first $prefix $name] == 0} {
            set name [string range $name [string length $prefix] end]
        }
    }

    return $name
}

proc tt_padding_safe_is_eligible {inst} {
    set base_class [tt_padding_safe_get $inst .base_cell.base_class ""]
    set is_pad     [tt_padding_safe_get $inst .is_pad false]
    set status     [string tolower [tt_padding_safe_get $inst .place_status ""]]

    if {$base_class ne "core"} {
        return false
    }
    if {$is_pad eq true || $is_pad eq "1"} {
        return false
    }
    if {$status in {fixed unplaced}} {
        return false
    }

    return true
}

puts ""
puts "======================================================================"
puts " Safe post-route Standard-Cell padding repair"
puts "======================================================================"
puts "DRC types : $INST_PADDING_ERROR_TYPES"
puts "Padding   : left=$INST_PADDING_LEFT right=$INST_PADDING_RIGHT sites"
puts "Policy    : movable core Standard Cells only; block/IO/fixed are skipped"
puts "======================================================================"

# Refresh DRC markers after the first route_design pass.
if {[info exists FINAL_DRC_LIMIT]} {
    set_db check_drc_limit $FINAL_DRC_LIMIT
}
check_drc -out_file [tech_mv_output_path report inst_padding_drc.rpt 05 drc]

set padded [dict create]
set target_marker_count 0
set skipped_nonstd_count 0
set no_inst_marker_count 0

foreach marker [get_db markers] {
    set subtype [tt_padding_safe_get $marker .subtype ""]

    if {[lsearch -exact $INST_PADDING_ERROR_TYPES $subtype] < 0} {
        continue
    }

    incr target_marker_count
    set bbox [tt_padding_safe_get $marker .bbox ""]
    if {$bbox eq ""} {
        continue
    }

    set insts {}
    if {[catch {
        set insts [get_obj_in_area \
            -area $bbox \
            -obj_type inst \
            -overlap_only]
    } err]} {
        puts "WARN: Cannot query instances for $subtype marker bbox=$bbox"
        puts "WARN: $err"
        continue
    }

    if {[llength $insts] == 0} {
        incr no_inst_marker_count
        continue
    }

    foreach inst $insts {
        set name       [tt_padding_safe_name $inst]
        set base_class [tt_padding_safe_get $inst .base_cell.base_class "UNKNOWN"]
        set is_pad     [tt_padding_safe_get $inst .is_pad "UNKNOWN"]
        set status     [tt_padding_safe_get $inst .place_status "UNKNOWN"]

        if {![tt_padding_safe_is_eligible $inst]} {
            incr skipped_nonstd_count
            puts "INFO: Skip padding: $name  subtype=$subtype class=$base_class is_pad=$is_pad status=$status"
            continue
        }

        if {[dict exists $padded $name]} {
            continue
        }

        puts "INFO: Apply padding: $name  subtype=$subtype  L=$INST_PADDING_LEFT R=$INST_PADDING_RIGHT"
        set_inst_padding \
            -inst $name \
            -left_side $INST_PADDING_LEFT \
            -right_side $INST_PADDING_RIGHT

        dict set padded $name 1
    }
}

puts "----------------------------------------------------------------------"
puts "Target DRC markers       : $target_marker_count"
puts "Padded Standard Cells    : [dict size $padded]"
puts "Skipped block/IO/fixed   : $skipped_nonstd_count"
puts "Target markers w/o inst  : $no_inst_marker_count"
puts "----------------------------------------------------------------------"
puts "INFO: Safe instance-padding repair completed; route_eco may continue."
puts ""
