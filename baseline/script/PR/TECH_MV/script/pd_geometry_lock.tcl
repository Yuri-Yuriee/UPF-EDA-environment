# =============================================================================
# pd_geometry_lock.tcl
# =============================================================================
# Power-Domain geometry lock/audit.
#
# There is no guessed "fixed" DB attribute applied to a Power-Domain object.
# Instead this tool:
#   1. captures the exact group rectangles after the user's manual PD snap
#   2. captures floorplan_finfet_inst_grid
#   3. verifies both at later flow boundaries
#   4. reports any movement
#   5. provides an EXPLICIT manual restore command: pd_lock_restore
#
# Verification is read-only. Restore is never automatic.
# =============================================================================

proc tt_pd_lock_report_root {{stage 90}} {
    return [tech_mv_report_dir $stage pd_geometry_lock]
}

proc tt_pd_lock_file {} {
    return [tech_mv_report_path 2 pd_geometry_lock_state tcl 90 pd_geometry_lock]
}

proc tt_pd_lock_safe_tag {tag} {
    return [string map {" " _ "/" _ ":" _ "\\" _} $tag]
}

proc tt_pd_lock_physical_groups {} {
    set result [dict create]

    foreach g [get_db groups] {
        set pd ""
        set name ""
        set rects {}

        catch {set pd [get_db $g .power_domain.name]}
        catch {set name [get_db $g .name]}
        catch {set rects [get_db $g .rects]}

        if {$pd eq "" || $name eq "" || [llength $rects] == 0} {
            continue
        }

        dict set result $name [dict create pd $pd rects $rects]
    }

    return $result
}

proc tech_mv_pd_lock_capture {{stage manual_pd_snap}} {
    set ::TT_PD_LOCK_GROUPS [tt_pd_lock_physical_groups]
    set ::TT_PD_LOCK_GRID "<UNAVAILABLE>"
    catch {set ::TT_PD_LOCK_GRID [get_db floorplan_finfet_inst_grid]}

    set state_file [tt_pd_lock_file]
    set fp [open $state_file w]
    puts $fp [list set ::TT_PD_LOCK_GROUPS $::TT_PD_LOCK_GROUPS]
    puts $fp [list set ::TT_PD_LOCK_GRID $::TT_PD_LOCK_GRID]
    puts $fp [list set ::TT_PD_LOCK_CAPTURE_STAGE $stage]
    close $fp

    set ::TT_PD_LOCK_CAPTURE_STAGE $stage

    puts "INFO: Captured Power-Domain geometry lock after '$stage'."
    puts "INFO:   groups = [dict size $::TT_PD_LOCK_GROUPS]"
    puts "INFO:   grid   = $::TT_PD_LOCK_GRID"
    puts "INFO:   state  = $state_file"

    return $state_file
}

proc tt_pd_lock_load {} {
    if {[info exists ::TT_PD_LOCK_GROUPS] && [info exists ::TT_PD_LOCK_GRID]} {
        return true
    }

    set state_file [tt_pd_lock_file]
    if {![file exists $state_file]} {
        return false
    }

    uplevel #0 [list source -quiet $state_file]
    return true
}

proc tech_mv_pd_lock_check {stage} {
    set report_stage [tech_mv_report_stage_from_tag $stage 90]
    set dir [tt_pd_lock_report_root $report_stage]
    set safe [tt_pd_lock_safe_tag $stage]
    set rpt [tech_mv_report_path 94 "pd_geometry_${safe}" rpt $report_stage pd_geometry_lock]

    if {![tt_pd_lock_load]} {
        set fp [open $rpt w]
        puts $fp "Status: NO_LOCK_CAPTURED"
        close $fp
        return [dict create ok true changed 0 grid_changed 0 report $rpt no_lock true]
    }

    set current [tt_pd_lock_physical_groups]
    set current_grid "<UNAVAILABLE>"
    catch {set current_grid [get_db floorplan_finfet_inst_grid]}

    set changed 0
    set missing 0
    set added 0
    set grid_changed [expr {$current_grid ne $::TT_PD_LOCK_GRID}]

    set fp [open $rpt w]
    puts $fp "======================================================================"
    puts $fp " POWER-DOMAIN GEOMETRY LOCK CHECK"
    puts $fp "======================================================================"
    puts $fp "Stage          : $stage"
    puts $fp "Capture stage  : $::TT_PD_LOCK_CAPTURE_STAGE"
    puts $fp "Locked grid    : $::TT_PD_LOCK_GRID"
    puts $fp "Current grid   : $current_grid"
    puts $fp "Grid changed   : $grid_changed"
    puts $fp ""

    foreach name [dict keys $::TT_PD_LOCK_GROUPS] {
        if {![dict exists $current $name]} {
            incr changed
            incr missing
            puts $fp "MISSING_GROUP name=$name locked=[dict get $::TT_PD_LOCK_GROUPS $name]"
            continue
        }

        set old [dict get $::TT_PD_LOCK_GROUPS $name]
        set new [dict get $current $name]

        if {[dict get $old rects] ne [dict get $new rects]} {
            incr changed
            puts $fp "PD_MOVED group=$name pd=[dict get $old pd]"
            puts $fp "  locked_rects  = [dict get $old rects]"
            puts $fp "  current_rects = [dict get $new rects]"
        }
    }

    foreach name [dict keys $current] {
        if {![dict exists $::TT_PD_LOCK_GROUPS $name]} {
            incr changed
            incr added
            puts $fp "ADDED_GROUP name=$name current=[dict get $current $name]"
        }
    }

    set ok [expr {$changed == 0 && !$grid_changed}]

    puts $fp ""
    puts $fp "SUMMARY"
    puts $fp "Changed groups : $changed"
    puts $fp "Missing groups : $missing"
    puts $fp "Added groups   : $added"
    puts $fp "Grid changed   : $grid_changed"
    puts $fp "Status         : [expr {$ok ? {PASS} : {FAIL}}]"
    close $fp

    puts "INFO: PD geometry lock '$stage' = [expr {$ok ? {PASS} : {FAIL}}], changed_groups=$changed grid_changed=$grid_changed"
    puts "INFO:   report = $rpt"

    return [dict create \
        ok $ok \
        changed $changed \
        grid_changed $grid_changed \
        report $rpt \
        no_lock false]
}

proc pd_lock_restore {} {
    if {![tt_pd_lock_load]} {
        error "No PD geometry lock has been captured yet."
    }

    puts "INFO: Restoring locked Power-Domain rectangles explicitly."

    foreach group_name [dict keys $::TT_PD_LOCK_GROUPS] {
        set d [dict get $::TT_PD_LOCK_GROUPS $group_name]
        set rects [dict get $d rects]

        puts "INFO:   restore group=$group_name pd=[dict get $d pd] rects=$rects"
        update_floorplan_obj -obj $group_name -rects $rects
    }

    set result [tech_mv_pd_lock_check manual_restore]
    if {![dict get $result ok]} {
        error "PD geometry restore did not return to the captured state. See [dict get $result report]"
    }

    puts "INFO: PD geometry restored to the manually captured state."
    return $result
}
