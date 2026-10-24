# =============================================================================
# remove_unused_site_rows.tcl
# Remove alternate-site rows only when no placed/logical instance uses that site.
# Default use in TECH_MV: remove unused GACORE rows before EndCap insertion.
# =============================================================================

proc tt_normalize_rect4 {value} {
    set v $value
    while {[llength $v] == 1 && [llength [lindex $v 0]] > 1} {
        set v [lindex $v 0]
    }
    return $v
}

proc tt_count_instances_for_site {site_name} {
    set count 0
    foreach inst [get_db insts] {
        set inst_site ""
        if {[catch {set inst_site [get_db $inst .base_cell.site.name]}]} {
            continue
        }
        if {$inst_site eq $site_name} {
            incr count
        }
    }
    return $count
}

proc tt_get_rows_for_site {site_name} {
    set rows {}
    foreach row [get_db rows] {
        set row_site ""
        if {[catch {set row_site [get_db $row .site.name]}]} {
            continue
        }
        if {$row_site eq $site_name} {
            lappend rows $row
        }
    }
    return $rows
}

proc tech_mv_remove_unused_site_rows {site_name} {
    set inst_count [tt_count_instances_for_site $site_name]
    set site_rows  [tt_get_rows_for_site $site_name]

    puts "INFO: Alternate-site row cleanup: site=$site_name instances=$inst_count rows=[llength $site_rows]"

    if {$inst_count > 0} {
        puts "WARNING: Keep site '$site_name' rows because $inst_count instance(s) use this site."
        return 0
    }

    if {[llength $site_rows] == 0} {
        puts "INFO: No '$site_name' rows exist; nothing to remove."
        return 0
    }

    set report_dir [tech_mv_report_dir 01]
    set rpt [tech_mv_report_path 10 "removed_${site_name}_rows" rpt 01]
    if {$rpt ne ""} {
        set fp [open $rpt w]
        puts $fp "site=$site_name"
        puts $fp "instance_count=$inst_count"
        puts $fp "row_count=[llength $site_rows]"
        foreach row $site_rows {
            set row_name [get_db $row .name]
            set row_rect ""
            catch {set row_rect [tt_normalize_rect4 [get_db $row .rect]]}
            puts $fp "$row_name rect=$row_rect"
        }
        close $fp
        puts "INFO: Wrote alternate-site row report: $rpt"
    }

    delete_obj $site_rows

    set remain [llength [tt_get_rows_for_site $site_name]]
    if {$remain != 0} {
        error "Failed to remove all unused '$site_name' rows; $remain row(s) remain."
    }

    puts "INFO: Removed [llength $site_rows] unused '$site_name' rows."
    return [llength $site_rows]
}
