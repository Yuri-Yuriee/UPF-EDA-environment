# Runtime adapter preserves the historical logical source path.
if {[info exists ::TECH_MV_RUNTIME_ROOT]} {
    info script [file join $::TECH_MV_RUNTIME_ROOT run/tool/00_common/TT_config_probe.tcl]
}
# Definitions only. No design changes, configuration assignments or stage replay.
namespace eval ::TT_CFG_PROBE {
    variable root [file normalize [file join [file dirname [info script]] .. .. ..]]
    variable geometry_keys {
        site_pitch {welltap::fallback_site_pitch}
        instance_grid {edge_switch::fallback_inst_grid}
        sdp_site_pitch {run/tool/02_powerplan/TT_PR7_coordinate_guided_repair.tcl::::TT_PR7_COORD_SITE_PITCH_UM::L47}
        welltap_width {run/tool/02_powerplan/TT_refine_internal_gap_sdps.tcl::::TT_PR7_GAPBLK_FALLBACK_W::L245}
        welltap_height {run/tool/02_powerplan/TT_refine_internal_gap_sdps.tcl::::TT_PR7_GAPBLK_FALLBACK_H::L246}
    }
}

proc ::TT_CFG_PROBE::write_data {path data} {
    if {[file exists $path]} {error "Refusing to overwrite an existing comparison file."}
    file mkdir [file dirname $path]
    set f [open $path {WRONLY CREAT EXCL} 0600]
    set code [catch {puts $f [list $data]} message options]
    set close_code [catch {close $f} close_message close_options]
    if {$code} {return -options $options $message}
    if {$close_code} {return -options $close_options $close_message}
    return $path
}

proc ::TT_CFG_PROBE::read_data {path} {
    set f [open $path r]
    set code [catch {read $f} text options]
    close $f
    if {$code} {return -options $options $text}
    if {[llength $text] != 1} {error "Invalid comparison data; expected one Tcl list item."}
    set data [lindex $text 0]
    if {![dict exists $data schema] || [dict get $data schema] ne "config_probe_v1"} {
        error "Unsupported comparison data schema."
    }
    return $data
}

proc ::TT_CFG_PROBE::golden_path {} {
    variable root
    return [file join $root setup config config_probe.golden.list]
}

proc ::TT_CFG_PROBE::configured {} {
    variable geometry_keys
    set d [dict create schema config_probe_v1 geometry {} masters {} pins {}]
    # Capture explicit config data only; do not let current DB queries redefine golden.
    variable root
    set configured_geometry [dict create]
    set private_path [file join $root setup config private geometry_values.tcl]
    if {[info exists ::env(TECH_MV_PRIVATE_CONFIG_FILE)] && $::env(TECH_MV_PRIVATE_CONFIG_FILE) ne ""} {
        set private_path [file normalize $::env(TECH_MV_PRIVATE_CONFIG_FILE)]
        if {![file isfile $private_path]} {error "Private geometry override is missing."}
    }
    set review_path [file join $root setup config geometry_review.config.tcl]
    if {[file isfile $review_path]} {set configured_geometry [source $review_path]}
    if {[file isfile $private_path]} {set configured_geometry [dict merge $configured_geometry [source $private_path]]}
    dict for {label key} $geometry_keys {
        if {![dict exists $configured_geometry $key]} {
            dict set d geometry $label [dict create available 0]
        } else {
            dict set d geometry $label [dict create available 1 value [dict get $configured_geometry $key]]
        }
    }
    foreach name {
        BOND_PAD_CELL ENDCAP_LEFT_EDGE_CELLS ENDCAP_RIGHT_EDGE_CELLS
        ENDCAP_LEFT_TOP_CORNER_CELLS ENDCAP_LEFT_BOTTOM_CORNER_CELLS
        ENDCAP_TOP_EDGE_CELLS ENDCAP_BOTTOM_EDGE_CELLS FILLER_CELLS
        TECH_CTS_BUFFER_MASTER_LIST TECH_CTS_INVERTER_MASTER_LIST
    } {
        if {[info exists ::$name]} {dict set d masters $name [set ::$name]}
    }
    if {![catch {::tech_mv_library_value LIB_CELL_002} tap]} {
        dict set d masters WELLTAP_MASTER $tap
    }
    foreach name {BOND_PAD_DEFAULT_PIN RTE_PAD_PIN} {
        if {[info exists ::$name]} {dict set d pins $name [set ::$name]}
    }
    foreach name {RTE_PAD_TEMPLATE_INSTANCE CORE_SITE GACORE_SITE_NAME} {
        if {[info exists ::$name]} {dict set d context $name [set ::$name]}
    }
    return $d
}

proc TT_config_golden {} {
    set path [::TT_CFG_PROBE::golden_path]
    # Golden is immutable. Capture it in a fresh Tcl shell before Innovus import.
    if {[llength [info commands get_db]]} {
        error "Golden must be captured before live geometry queries are available; preserve the supplied baseline."
    }
    ::TT_CFG_PROBE::write_data $path [::TT_CFG_PROBE::configured]
    puts "Config golden saved locally; values are not printed."
    return $path
}

proc ::TT_CFG_PROBE::row {rows_var id status {expected {}} {actual {}} {origin {}}} {
    upvar 1 $rows_var rows
    lappend rows [dict create item $id status $status expected $expected actual $actual source $origin]
}

proc ::TT_CFG_PROBE::geometry {golden rows_var} {
    upvar 1 $rows_var rows
    variable geometry_keys
    # Reuse the exact attribute mapping already used by the existing getters.
    # No grid, wire width or rule is inferred from a different physical quantity.
    dict for {label key} $geometry_keys {
        set live [::tech_mv_live_geometry $key]
        if {$live eq ""} {
            row rows $label UNAVAILABLE
            continue
        }
        set actual [dict get $live value]
        if {![dict exists $golden geometry $label available] || ![dict get $golden geometry $label available]} {
            row rows $label NO_GOLDEN {} $actual [dict get $live source]
            continue
        }
        set expected [dict get $golden geometry $label value]
        # Exact numerical equality; no tolerance that could hide a parameter change.
        set same [expr {[string is double -strict $expected] && [string is double -strict $actual] && double($expected) == double($actual)}]
        row rows $label [expr {$same ? "MATCH" : "DIFFERENT"}] $expected $actual [dict get $live source]
    }
}

proc ::TT_CFG_PROBE::one_master {name} {
    # Master selectors may contain patterns. Never silently select the first hit.
    set objects [get_db base_cells $name]
    if {[llength $objects] != 1} {error "Master selector is missing or ambiguous."}
    set obj [lindex $objects 0]
    set resolved [get_db $obj .name]
    if {$resolved ne $name} {error "Master selector does not resolve to its exact configured name."}
    return $obj
}

proc ::TT_CFG_PROBE::masters {golden rows_var} {
    upvar 1 $rows_var rows
    set seen [dict create]
    dict for {role names} [dict get $golden masters] {
        set index 0
        foreach name $names {
            incr index
            set id "${role}:$index"
            if {[dict exists $seen $name]} {
                lassign [dict get $seen $name] status actual
                row rows $id $status $name $actual base_cell_name
                continue
            }
            if {[catch {one_master $name} obj]} {
                set status UNAVAILABLE; set actual {}
            } else {
                set status MATCH; set actual [get_db $obj .name]
            }
            dict set seen $name [list $status $actual]
            row rows $id $status $name $actual base_cell_name
        }
    }
}

proc ::TT_CFG_PROBE::pin_inventory {master} {
    set names {}; set successful 0
    foreach attribute {.pg_pins .pins} {
        if {[catch {get_db $master $attribute} pins]} {continue}
        incr successful
        foreach pin $pins {
            if {[catch {get_db $pin .name} name]} {continue}
            lappend names [lindex [split $name /] end]
        }
    }
    if {!$successful} {error "Pin attributes unavailable on this database object."}
    return [dict create names [lsort -unique $names] complete [expr {$successful == 2}]]
}

proc ::TT_CFG_PROBE::pins {golden rows_var} {
    upvar 1 $rows_var rows
    foreach role {BOND_PAD_DEFAULT_PIN RTE_PAD_PIN} {
        if {![dict exists $golden pins $role]} {continue}
        set expected [dict get $golden pins $role]
        if {$role eq "BOND_PAD_DEFAULT_PIN"} {
            set failed [catch {
                if {![dict exists $golden masters BOND_PAD_CELL]} {error "Bond-pad master not configured."}
                set names [pin_inventory [one_master [dict get $golden masters BOND_PAD_CELL]]]
            }]
        } else {
            set failed [catch {
                if {![dict exists $golden context RTE_PAD_TEMPLATE_INSTANCE]} {error "RTE instance not configured."}
                set insts [get_db insts [dict get $golden context RTE_PAD_TEMPLATE_INSTANCE]]
                if {[llength $insts] != 1} {error "RTE instance missing or ambiguous."}
                set master [get_db [lindex $insts 0] .base_cell]
                set names [pin_inventory $master]
            }]
        }
        if {$failed} {
            row rows $role UNAVAILABLE $expected
        } elseif {[lsearch -exact [dict get $names names] $expected] >= 0} {
            row rows $role MATCH $expected $expected selected_master_pin_inventory
        } elseif {![dict get $names complete]} {
            row rows $role UNAVAILABLE $expected [dict get $names names] partial_pin_inventory
        } else {
            row rows $role NOT_FOUND $expected [dict get $names names] selected_master_pin_inventory
        }
    }
    # Pin presence does not establish secondary/AON roles. Those mappings stay config.
}

proc TT_config_probe {{section all}} {
    if {$section eq "help"} {
        puts "TT_config_probe ?geometry|masters|pins|all?"
        puts "Read-only; compare selected loaded library data with the saved config golden."
        puts "Run after design import. Values stay in local private report files."
        puts "MATCH confirms a value/presence comparison, not automatic replacement safety."
        return
    }
    if {$section ni {geometry masters pins all}} {error "Use geometry, masters, pins, all, or help."}
    if {![llength [info commands get_db]]} {error "Run this probe inside Innovus after LEF/design import."}
    set golden [::TT_CFG_PROBE::read_data [::TT_CFG_PROBE::golden_path]]
    set current [::TT_CFG_PROBE::configured]
    set rows {}
    # Detect config edits since baseline rather than silently accepting a new selection.
    foreach part {geometry masters pins context} {
        if {[dict exists $golden $part] && [dict exists $current $part] && [dict get $golden $part] ne [dict get $current $part]} {
            ::TT_CFG_PROBE::row rows "config_$part" CONFIG_CHANGED
        }
    }
    foreach part {geometry masters pins} {
        if {$section eq "all" || $section eq $part} {::TT_CFG_PROBE::$part $golden rows}
    }
    set counts [dict create]
    foreach r $rows {
        dict incr counts [dict get $r status]
        puts [format "%-36s %s" [dict get $r item] [dict get $r status]]
    }
    variable ::TT_CFG_PROBE::root
    set directory [file join $root .temp config_probe private]
    file mkdir $directory
    file attributes $directory -permissions 0700
    set stem "probe_[clock microseconds]_[pid]"
    set data [dict create schema config_probe_v1 section $section counts $counts rows $rows]
    ::TT_CFG_PROBE::write_data [file join $directory ${stem}.list] $data
    set report [open [file join $directory ${stem}.rpt] {WRONLY CREAT EXCL} 0600]
    set code [catch {
        puts $report "PRIVATE CONFIG QUERY COMPARISON"
        puts $report "Section: $section"
        puts $report "Golden: saved configuration before live import queries"
        puts $report "MATCH verifies a value or presence, not replacement safety."
        foreach r $rows {
            puts $report ""
            puts $report "[dict get $r item] | [dict get $r status]"
            puts $report "  Config golden: [dict get $r expected]"
            puts $report "  Live query   : [dict get $r actual]"
            puts $report "  Source       : [dict get $r source]"
        }
    } message options]
    set close_code [catch {close $report} close_message close_options]
    if {$code} {return -options $options $message}
    if {$close_code} {return -options $close_options $close_message}
    puts "Read-only comparison complete. Private details saved under .temp/config_probe/private/."
    puts "No configuration or design data was changed. UNAVAILABLE is not a pass."
    # Do not return protected values to the terminal via Innovus command echo.
    return $counts
}
