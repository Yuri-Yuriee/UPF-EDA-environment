# Runtime adapter preserves the historical logical source path.
if {[info exists ::TECH_MV_RUNTIME_ROOT]} {
    info script [file join $::TECH_MV_RUNTIME_ROOT run/tool/03_place/padding/TT_proc_ls_padding.tcl]
} else {
    info script [file normalize [file join [file dirname [info script]] .. .. .. run/tool/03_place/padding/TT_proc_ls_padding.tcl]]
}
# =============================================================================
# TT_proc_ls_padding.tcl
# =============================================================================
# Pre-placement Level-Shifter instance padding for TECH_MV.
#
# Policy:
#   - Discover LS instances from the logical low-power classification:
#       is_level_shifter == true
#   - Apply instance-specific left/right padding before placement.
#   - Padding unit is placement-site count.
#   - Do not change placement status, orientation, location, or connectivity.
#
# Public command:
#   TT_apply_ls_padding
# =============================================================================

foreach _cfg_var {
    ENABLE_LS_PADDING
    LS_PADDING_LEFT
    LS_PADDING_RIGHT
    LS_PADDING_REPORT_LIMIT
} {
    if {![info exists ::$_cfg_var]} {
        error "Missing config variable $_cfg_var. Source init.setup first."
    }
}
unset _cfg_var

proc TT_LS_PAD__validate_site_count {name value} {
    if {![string is integer -strict $value] || $value < 0} {
        error "$name must be a non-negative integer placement-site count, got '$value'"
    }
}

proc TT_LS_PAD__get_names {} {
    set cells {}
    if {[catch {
        set cells [get_cells -hierarchical -filter {is_level_shifter == true}]
    } err]} {
        error "Cannot query Level Shifter cells with is_level_shifter == true: $err"
    }

    if {[llength $cells] == 0} {
        return {}
    }

    return [get_object_name $cells]
}

proc TT_apply_ls_padding {} {
    puts ""
    puts "======================================================================"
    puts " LEVEL-SHIFTER PLACEMENT PADDING"
    puts "======================================================================"

    if {!$::ENABLE_LS_PADDING} {
        puts "INFO: LS padding is disabled by ENABLE_LS_PADDING=false."
        puts "======================================================================"
        return [dict create enabled false ls_count 0 applied_count 0 missing_count 0]
    }

    TT_LS_PAD__validate_site_count LS_PADDING_LEFT  $::LS_PADDING_LEFT
    TT_LS_PAD__validate_site_count LS_PADDING_RIGHT $::LS_PADDING_RIGHT

    if {[llength [info commands set_inst_padding]] == 0} {
        error "Required Innovus command set_inst_padding is unavailable."
    }

    set ls_names [TT_LS_PAD__get_names]
    set ls_count [llength $ls_names]

    puts "LS instances : $ls_count"
    puts "Padding      : left=$::LS_PADDING_LEFT right=$::LS_PADDING_RIGHT placement sites"
    puts "Classification: is_level_shifter == true"

    if {$ls_count == 0} {
        puts "INFO: No Level Shifter instances found; nothing to pad."
        puts "======================================================================"
        return [dict create enabled true ls_count 0 applied_count 0 missing_count 0]
    }

    set applied_count 0
    set missing_count 0
    set sample_printed 0
    set masters [dict create]

    foreach name $ls_names {
        set insts {}
        catch { set insts [get_db insts $name] }

        if {[llength $insts] == 0} {
            incr missing_count
            puts "WARNING: LS logical cell has no matching Innovus instance: $name"
            continue
        }

        foreach inst $insts {
            set inst_name [get_db $inst .name]
            set master    [get_db $inst .base_cell.name]
            dict set masters $master 1

            set_inst_padding \
                -inst $inst_name \
                -left_side  $::LS_PADDING_LEFT \
                -right_side $::LS_PADDING_RIGHT

            incr applied_count

            if {$sample_printed < $::LS_PADDING_REPORT_LIMIT} {
                puts "INFO: LS padding: $inst_name  master=$master  L=$::LS_PADDING_LEFT R=$::LS_PADDING_RIGHT"
                incr sample_printed
            }
        }
    }

    if {$applied_count > $sample_printed} {
        puts "INFO: ... [expr {$applied_count - $sample_printed}] additional LS instance(s) padded."
    }

    puts "----------------------------------------------------------------------"
    puts "LS logical cells        : $ls_count"
    puts "LS instances padded     : $applied_count"
    puts "LS missing from DB      : $missing_count"
    puts "Unique LS masters       : [dict size $masters]"
    puts "----------------------------------------------------------------------"

    if {[llength [info commands report_inst_padding]] > 0} {
        puts "INFO: Innovus padding report command is available: report_inst_padding -all"
    }

    if {$missing_count != 0} {
        error "LS padding incomplete: $missing_count logical LS cell(s) were not found in the Innovus instance DB."
    }

    puts "INFO: Level-Shifter padding applied before placement."
    puts "======================================================================"

    return [dict create \
        enabled true \
        ls_count $ls_count \
        applied_count $applied_count \
        missing_count $missing_count \
        unique_master_count [dict size $masters]]
}

puts "INFO: Loaded TT_proc_ls_padding.tcl"
