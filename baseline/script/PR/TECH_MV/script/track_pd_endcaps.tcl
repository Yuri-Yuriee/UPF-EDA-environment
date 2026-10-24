# =============================================================================
# track_pd_endcaps.tcl
# =============================================================================
# READ-ONLY tracker for Power-Domain EndCaps.
#
# Report directory:
#   $REPORT_DIR/endcap_tracking/
#
# Each call writes:
#   TT_pd_endcaps_<stage>.rpt
#   TT_pd_endcaps_<stage>_changes.rpt
# and appends:
#   TT_pd_endcaps_history.rpt
#
# No instance or Power-Domain geometry is modified by this file.
# =============================================================================

proc tt_ec_report_root {{stage 90}} {
    return [tech_mv_report_dir $stage endcap_tracking]
}

proc tt_ec_safe_tag {tag} {
    return [string map {" " _ "/" _ ":" _ "\\" _} $tag]
}

proc tt_ec_pd_name {inst} {
    set pd {}
    if {![catch {set pd [get_db $inst .power_domain]}] && [llength $pd] > 0} {
        set pd [lindex $pd 0]
        set name ""
        if {![catch {set name [get_db $pd .name]}] && $name ne ""} {
            return $name
        }
        set raw [string trim $pd]
        if {[string match "power_domain:*" $raw]} {
            return [string range $raw [string length "power_domain:"] end]
        }
        if {$raw ne ""} {
            return $raw
        }
    }

    set name ""
    if {![catch {set name [get_db $inst .power_domain_name]}] && $name ne ""} {
        return $name
    }
    return "<NO_POWER_DOMAIN>"
}

proc tt_ec_snapshot {} {
    if {[info exists ::ENDCAP_POWER_DOMAIN_PREFIX] &&
        $::ENDCAP_POWER_DOMAIN_PREFIX ne ""} {
        set prefix $::ENDCAP_POWER_DOMAIN_PREFIX
    } else {
        set prefix ENDCAP_PD
    }

    set snap [dict create]

    foreach inst [get_db insts] {
        set name ""
        catch {set name [get_db $inst .name]}
        if {$name eq "" || ![string match "*${prefix}*" $name]} {
            continue
        }

        set master "<UNKNOWN>"
        set status "<UNKNOWN>"
        set location {}
        set bbox {}

        catch {set master [get_db $inst .base_cell.name]}
        catch {set status [get_db $inst .place_status]}
        catch {set location [get_db $inst .location]}
        catch {set bbox [get_db $inst .bbox]}

        dict set snap $name [dict create \
            pd [tt_ec_pd_name $inst] \
            master $master \
            status $status \
            location $location \
            bbox $bbox]
    }

    return $snap
}

proc TT_track_pd_endcaps {stage} {
    set report_stage [tech_mv_report_stage_from_tag $stage 90]
    set dir [tt_ec_report_root $report_stage]
    set safe [tt_ec_safe_tag $stage]

    set snapshot_rpt [tech_mv_report_path 92 "endcap_tracking_${safe}" rpt $report_stage endcap_tracking]
    set change_rpt   [tech_mv_report_path 93 "endcap_tracking_${safe}_changes" rpt $report_stage endcap_tracking]
    set history_rpt  [tech_mv_report_path 1 endcap_tracking_history rpt 90 endcap_tracking]

    set snap [tt_ec_snapshot]
    set names [lsort [dict keys $snap]]

    set grid "<UNAVAILABLE>"
    catch {set grid [get_db floorplan_finfet_inst_grid]}

    set pd_count [dict create]

    set fp [open $snapshot_rpt w]
    puts $fp "======================================================================"
    puts $fp " PD ENDCAP POSITION SNAPSHOT"
    puts $fp "======================================================================"
    puts $fp "Stage                    : $stage"
    puts $fp "EndCap count             : [llength $names]"
    puts $fp "floorplan_finfet_inst_grid: $grid"
    puts $fp ""
    puts $fp "INSTANCE | POWER_DOMAIN | MASTER | STATUS | LOCATION | BBOX"

    foreach name $names {
        set d [dict get $snap $name]
        set pd [dict get $d pd]
        dict incr pd_count $pd
        puts $fp "$name | $pd | [dict get $d master] | [dict get $d status] | [dict get $d location] | [dict get $d bbox]"
    }

    puts $fp ""
    puts $fp "POWER DOMAIN COUNTS"
    foreach pd [lsort [dict keys $pd_count]] {
        puts $fp "$pd : [dict get $pd_count $pd]"
    }
    close $fp

    set moved 0
    set status_changed 0
    set pd_changed 0
    set added 0
    set removed 0

    set cfp [open $change_rpt w]
    puts $cfp "======================================================================"
    puts $cfp " PD ENDCAP CHANGES"
    puts $cfp "======================================================================"
    puts $cfp "Current stage : $stage"

    if {[info exists ::TT_EC_PREV_SNAPSHOT]} {
        puts $cfp "Previous stage: $::TT_EC_PREV_STAGE"
        puts $cfp ""

        set prev $::TT_EC_PREV_SNAPSHOT

        foreach name $names {
            if {![dict exists $prev $name]} {
                incr added
                puts $cfp "ADDED cell=$name current=[dict get $snap $name]"
                continue
            }

            set old [dict get $prev $name]
            set cur [dict get $snap $name]

            if {[dict get $old location] ne [dict get $cur location] ||
                [dict get $old bbox] ne [dict get $cur bbox]} {
                incr moved
                puts $cfp "MOVED cell=$name pd=[dict get $cur pd] old_location={[dict get $old location]} new_location={[dict get $cur location]} old_bbox={[dict get $old bbox]} new_bbox={[dict get $cur bbox]}"
            }

            if {[dict get $old status] ne [dict get $cur status]} {
                incr status_changed
                puts $cfp "STATUS_CHANGED cell=$name old=[dict get $old status] new=[dict get $cur status]"
            }

            if {[dict get $old pd] ne [dict get $cur pd]} {
                incr pd_changed
                puts $cfp "POWER_DOMAIN_CHANGED cell=$name old=[dict get $old pd] new=[dict get $cur pd]"
            }
        }

        foreach name [dict keys $prev] {
            if {![dict exists $snap $name]} {
                incr removed
                puts $cfp "REMOVED cell=$name old=[dict get $prev $name]"
            }
        }
    } else {
        puts $cfp "Previous stage: <NONE>"
        puts $cfp ""
        puts $cfp "BASELINE_ONLY"
    }

    puts $cfp ""
    puts $cfp "SUMMARY"
    puts $cfp "Total current  : [llength $names]"
    puts $cfp "Moved          : $moved"
    puts $cfp "Status changed : $status_changed"
    puts $cfp "PD changed     : $pd_changed"
    puts $cfp "Added          : $added"
    puts $cfp "Removed        : $removed"
    close $cfp

    set hfp [open $history_rpt a]
    puts $hfp "stage=$stage total=[llength $names] moved=$moved status_changed=$status_changed pd_changed=$pd_changed added=$added removed=$removed grid={$grid}"
    foreach pd [lsort [dict keys $pd_count]] {
        puts $hfp "  pd=$pd count=[dict get $pd_count $pd]"
    }
    close $hfp

    set ::TT_EC_PREV_SNAPSHOT $snap
    set ::TT_EC_PREV_STAGE $stage

    puts "INFO: PD EndCap tracking '$stage': total=[llength $names] moved=$moved"
    puts "INFO:   snapshot = $snapshot_rpt"
    puts "INFO:   changes  = $change_rpt"

    return [dict create \
        stage $stage \
        count [llength $names] \
        moved $moved \
        snapshot_report $snapshot_rpt \
        change_report $change_rpt \
        history_report $history_rpt]
}
