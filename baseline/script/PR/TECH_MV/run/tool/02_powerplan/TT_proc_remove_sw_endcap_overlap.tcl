# Runtime adapter preserves the historical logical source path.
if {[info exists ::TECH_MV_RUNTIME_ROOT]} {
    info script [file join $::TECH_MV_RUNTIME_ROOT run/tool/02_powerplan/TT_proc_remove_sw_endcap_overlap.tcl]
}
# ============================================================================
# TT_proc_remove_sw_endcap_overlap.tcl
#
# Remove overlapping Power Switch instances reported by Innovus check_place.
#
# Delete condition:
#   marker.type       == place
#   marker.subtype    == SPOverlapViolation
#   marker.originator == check_place
#   marker.objects.is_power_switch == true
#
# Deletion policy (V2.1):
#   Power Switches MUST be deleted through Innovus PSO-native
#   delete_power_switches -instance_list. Do not use delete_inst here.
#   This keeps add_power_switches/delete_power_switches bookkeeping coherent.
#
# # All report fields are cached before deletion.
# ============================================================================

if {![info exists ::POWER_SWITCH_ENDCAP_OVERLAP_CHECK_ENABLE]} {
    set ::POWER_SWITCH_ENDCAP_OVERLAP_CHECK_ENABLE true
}
if {![info exists ::POWER_SWITCH_ENDCAP_OVERLAP_AUTO_DELETE]} {
    set ::POWER_SWITCH_ENDCAP_OVERLAP_AUTO_DELETE true
}
if {![info exists ::POWER_SWITCH_ENDCAP_OVERLAP_SAVE_DB]} {
    set ::POWER_SWITCH_ENDCAP_OVERLAP_SAVE_DB false
}

set ::TT_SWEC_VERSION "V2.1_CHECKPLACE_NATIVE_DELETE_20261009"

proc TT_SWEC_get {obj attr {default ""}} {
    if {[catch {set value [get_db $obj $attr]}]} {
        return $default
    }
    if {$value eq ""} {
        return $default
    }
    return $value
}

proc TT_SWEC_true {value} {
    set v [string tolower [string trim $value]]
    return [expr {$v eq "true" || $v eq "1" || $v eq "yes"}]
}

proc TT_SWEC_is_target_marker {marker} {
    return [expr {
        [TT_SWEC_get $marker .type ""] eq "place" &&
        [TT_SWEC_get $marker .subtype ""] eq "SPOverlapViolation" &&
        [TT_SWEC_get $marker .originator ""] eq "check_place"
    }]
}

proc TT_SWEC_report_path {} {
    if {[info exists ::REPORT_DIR] && $::REPORT_DIR ne ""} {
        set dir [file join $::REPORT_DIR 01_floorplan floorplan]
    } else {
        set dir [pwd]
    }
    file mkdir $dir
    return [file join $dir 01_79_sw_overlap_cleanup.rpt]
}

proc TT_SWEC_run_check_place {} {
    puts "INFO: TT_SWEC running Innovus check_place."

    if {[llength [info commands check_place]] > 0} {
        check_place
    } elseif {[llength [info commands checkPlace]] > 0} {
        checkPlace
    } else {
        error "TT_SWEC: check_place/checkPlace is unavailable."
    }

    set ::TT_SWEC_MARKERS [get_db markers]
    puts "INFO: TT_SWEC post-check_place marker count: [llength $::TT_SWEC_MARKERS]"
}

proc TT_SWEC_collect {} {
    if {![info exists ::TT_SWEC_MARKERS]} {
        error "TT_SWEC: marker snapshot is unavailable."
    }

    set exact_marker_count 0
    set sw_marker_count 0
    set candidates [dict create]

    foreach marker $::TT_SWEC_MARKERS {
        if {![TT_SWEC_is_target_marker $marker]} {
            continue
        }

        incr exact_marker_count
        set objects [TT_SWEC_get $marker .objects {}]

        foreach obj $objects {
            if {![TT_SWEC_true [TT_SWEC_get $obj .is_power_switch false]]} {
                continue
            }

            incr sw_marker_count

            set name [TT_SWEC_get $obj .name ""]
            if {$name eq ""} {
                error "TT_SWEC: Power Switch marker object has no .name."
            }

            set status [TT_SWEC_get $obj .place_status "<unknown>"]
            set bbox   [TT_SWEC_get $marker .bbox {}]
            set msg    [TT_SWEC_get $marker .message ""]

            if {![dict exists $candidates $name]} {
                dict set candidates $name [dict create \
                    object $obj \
                    place_status_before $status \
                    markers {}]
            }

            set marker_list [dict get $candidates $name markers]
            lappend marker_list [dict create bbox $bbox message $msg]
            dict set candidates $name markers $marker_list
        }
    }

    return [dict create \
        exact_marker_count $exact_marker_count \
        sw_marker_count $sw_marker_count \
        candidates $candidates]
}

proc TT_SWEC_write_report {data action deleted_names} {
    set path [TT_SWEC_report_path]
    set fp [open $path w]

    puts $fp "======================================================================"
    puts $fp " TT_SWEC POWER-SWITCH OVERLAP CLEANUP"
    puts $fp "======================================================================"
    puts $fp "Marker type       : place"
    puts $fp "Marker subtype    : SPOverlapViolation"
    puts $fp "Marker originator : check_place"
    puts $fp "SW condition      : marker.objects.is_power_switch == true"
    puts $fp "Action            : $action"
    puts $fp ""
    puts $fp "SPOverlapViolation : [dict get $data exact_marker_count]"
    puts $fp "SW-owned markers   : [dict get $data sw_marker_count]"
    puts $fp "Candidate SW       : [dict size [dict get $data candidates]]"
    puts $fp ""

    foreach name [lsort [dict keys [dict get $data candidates]]] {
        set entry [dict get $data candidates $name]
        puts $fp "SW: $name"
        puts $fp "  place_status(before delete): [dict get $entry place_status_before]"
        foreach marker_info [dict get $entry markers] {
            puts $fp "  marker bbox   : [dict get $marker_info bbox]"
            puts $fp "  marker message: [dict get $marker_info message]"
        }
    }

    if {[llength $deleted_names] > 0} {
        puts $fp ""
        puts $fp "DELETED:"
        foreach name $deleted_names {
            puts $fp "  $name"
        }
    }

    close $fp
    puts "INFO: TT_SWEC report: $path"
    return $path
}

proc TT_SWEC_native_delete_candidates {candidates} {
    if {[dict size $candidates] == 0} {
        return {}
    }

    if {[llength [info commands delete_power_switches]] == 0} {
        error "TT_SWEC: delete_power_switches is unavailable; refusing delete_inst fallback because it can desynchronize PSO bookkeeping."
    }

    set names {}
    foreach name [lsort [dict keys $candidates]] {
        lappend names $name
    }

    puts "INFO: TT_SWEC native PSO delete count = [llength $names]"
    puts "INFO: TT_SWEC command = delete_power_switches -instance_list {$names}"

    set cmd [list delete_power_switches -instance_list $names]
    if {[catch {uplevel #0 $cmd} err opts]} {
        error "TT_SWEC: native delete_power_switches failed: $err"
    }

    # Verify candidates really disappeared from the live DB.
    # Never fall back to delete_inst: partial/native failure must stay visible.
    set remain {}
    set name_set [dict create]
    foreach name $names {
        dict set name_set $name 1
    }

    foreach inst [get_db insts] {
        set live_name [TT_SWEC_get $inst .name ""]
        if {$live_name ne "" && [dict exists $name_set $live_name]} {
            lappend remain $live_name
        }
    }

    if {[llength $remain] > 0} {
        error "TT_SWEC: native delete_power_switches returned but [llength $remain] candidate(s) remain live: $remain"
    }

    foreach name $names {
        puts "NATIVE_DELETE: $name"
    }

    return $names
}

proc TT_SWEC_report {} {
    TT_SWEC_run_check_place
    set data [TT_SWEC_collect]

    puts "======================================================================"
    puts " TT_SWEC REPORT"
    puts "======================================================================"
    puts "SPOverlapViolation : [dict get $data exact_marker_count]"
    puts "SW-owned markers   : [dict get $data sw_marker_count]"
    puts "Candidate SW       : [dict size [dict get $data candidates]]"
    puts "======================================================================"

    TT_SWEC_write_report $data REPORT_ONLY {}
    return $data
}

proc TT_SWEC_apply {} {
    if {![TT_SWEC_true $::POWER_SWITCH_ENDCAP_OVERLAP_CHECK_ENABLE]} {
        puts "INFO: TT_SWEC disabled."
        return 0
    }

    TT_SWEC_run_check_place
    set data [TT_SWEC_collect]
    set candidates [dict get $data candidates]

    puts "======================================================================"
    puts " TT_SWEC APPLY"
    puts "======================================================================"
    puts "SPOverlapViolation : [dict get $data exact_marker_count]"
    puts "SW-owned markers   : [dict get $data sw_marker_count]"
    puts "Candidate SW       : [dict size $candidates]"
    puts "======================================================================"

    if {[dict size $candidates] == 0} {
        TT_SWEC_write_report $data NO_POWER_SWITCH_OVERLAP {}
        puts "PASS: No SPOverlapViolation marker object has .is_power_switch == true."
        return 0
    }

    if {![TT_SWEC_true $::POWER_SWITCH_ENDCAP_OVERLAP_AUTO_DELETE]} {
        TT_SWEC_write_report $data AUTO_DELETE_DISABLED {}
        puts "INFO: Candidates found, auto-delete disabled."
        return [dict size $candidates]
    }

    if {[TT_SWEC_true $::POWER_SWITCH_ENDCAP_OVERLAP_SAVE_DB]} {
        if {[info exists ::DBS_DIR] && $::DBS_DIR ne "" &&
            [llength [info commands write_db]] > 0} {
            set save_path [file join $::DBS_DIR 01_79_before_sw_overlap_cleanup.enc]
            puts "INFO: TT_SWEC rollback DB: $save_path"
            write_db $save_path
        }
    }

    set deleted [TT_SWEC_native_delete_candidates $candidates]

    TT_SWEC_write_report $data NATIVE_DELETE_POWER_SWITCHES $deleted

    puts "PASS: Native-deleted [llength $deleted] overlapping Power Switch instance(s) through delete_power_switches."
    return [llength $deleted]
}

puts "INFO: Loaded TT_proc_remove_sw_endcap_overlap.tcl - $::TT_SWEC_VERSION"
puts "INFO: Commands: TT_SWEC_report | TT_SWEC_apply"
