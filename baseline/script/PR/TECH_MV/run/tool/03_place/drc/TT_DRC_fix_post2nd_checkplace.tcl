# Runtime adapter preserves the historical logical source path.
if {[info exists ::TECH_MV_RUNTIME_ROOT]} {
    info script [file join $::TECH_MV_RUNTIME_ROOT run/tool/03_place/drc/TT_DRC_fix_post2nd_checkplace.tcl]
}
# Library pin settings only; no APR actions are performed by this loader.
if {![llength [info commands ::tech_mv_library_value]]} {
    if {[info exists ::TOOL_DIR]} {
        source -quiet [file join $::TECH_MV_RUNTIME_ROOT .. script PR TECH_MV script 00_common private_parameter_config.tcl]
    } else {
        source -quiet [file join $::TECH_MV_RUNTIME_ROOT .. script PR TECH_MV script 00_common private_parameter_config.tcl]
    }
}
# DRC_RULE_SPECIFIC_TOOL: named/configured DRC subtype selection is technology-dependent.
# DRC_RULE_REVIEW: Rule names, filters and repair logic are retained for manual planning.
# Load the output-path helper if this stage is sourced by an older live session.
if {![llength [info commands ::tech_mv_native_report_command]]} {
    source -quiet [file join $::TOOL_DIR 00_common TT_runtime_output_helpers.tcl]
}
# =============================================================================
# TT_DRC_fix_post2nd_checkplace.tcl
# =============================================================================
# Manual fallback repair for check_place violations after 2nd-PG routing.
#
# Default scope is intentionally narrow:
#   - SIGNAL: placed/fixed LP cells; SROUTE: fixed LP cells (LS / ISO / RET)
#   - prefer cells directly associated with current check_place markers
#   - fallback to cells overlapping marker bbox when marker has no inst object
#   - ENDCAP_PD excluded
#   - macros / IO / non-core cells excluded
#
# Repair:
#   add_power_mesh_colors
#   -> reuse existing check_place markers, or run check_place ONCE if needed
#   -> save rollback DB
#   -> fixed violation LP cells -> placed
#   -> place_detail
#   -> if moved, reconnect their actual secondary PG PD+net groups
#   -> re-fix exactly the cells released by this tool
#   -> NO immediate post-repair check_place
#   -> validation is deferred to the next formal checkpoint
#
# Sourcing this file does NOT modify the design.
#
# Commands:
#   TT_CP2_preview
#   TT_CP2_repair
#   TT_CP2_restore
# =============================================================================

# User-adjustable values are centralized in setup/config/.
foreach _cfg_var {
    SECONDARY_PG_ROUTE_MODE
    TT_CP2_REPAIR_SCOPE
    TT_CP2_REPAIR_INCLUDE_ENDCAP
    TT_CP2_REPAIR_REROUTE_2NDPG
    TT_CP2_REPAIR_MAX_CELLS
    SECONDARY_PG_RAIL_LAYER
    SECONDARY_PG_BOTTOM_LAYER
    SECONDARY_PG_TOP_LAYER
} {
    if {![info exists ::$_cfg_var]} {
        error "Missing config variable $_cfg_var. Source init.setup first."
    }
}
unset _cfg_var


proc TT_CP2_rpt_dir {} {
    return [tech_mv_report_dir 90 2ndpg_repair]
}

proc TT_CP2_db_dir {} {
    if {[info exists ::DB_DIR] && $::DB_DIR ne ""} {
        set d $::DB_DIR
    } else {
        set d [file normalize dbs]
    }
    file mkdir $d
    return $d
}

proc TT_CP2_repair_db_names {} {
    set mode [string toupper $::SECONDARY_PG_ROUTE_MODE]

    if {$mode eq "SROUTE"} {
        return [list \
            03_81_before_2ndpg_repair.enc \
            03_82_after_2ndpg_repair.enc]
    }

    # SIGNAL secondary-PG routing belongs to Stage 05.
    return [list \
        05_11_before_2ndpg_repair.enc \
        05_12_after_2ndpg_repair.enc]
}


proc TT_CP2_get {obj attr {default ""}} {
    set v $default
    catch {set v [get_db $obj $attr]}
    return $v
}

proc TT_CP2_point {raw} {
    set p $raw
    if {[llength $p] == 1 && [llength [lindex $p 0]] == 2} {
        set p [lindex $p 0]
    }
    if {[llength $p] != 2} {
        return [list "" ""]
    }
    return $p
}

proc TT_CP2_moved {a b {tol 0.000001}} {
    lassign $a ax ay
    lassign $b bx by
    if {$ax eq "" || $ay eq "" || $bx eq "" || $by eq ""} {
        return [expr {$a ne $b}]
    }
    if {![string is double -strict $ax] ||
        ![string is double -strict $ay] ||
        ![string is double -strict $bx] ||
        ![string is double -strict $by]} {
        return [expr {$a ne $b}]
    }
    return [expr {
        abs(double($ax)-double($bx)) > $tol ||
        abs(double($ay)-double($by)) > $tol
    }]
}


# Innovus does not print these summary lines when the count is zero.
proc TT_CP2_parse_check_place {s} {
    set pre 0
    set pin 0

    regexp -nocase \
        {Pre-route[ \t]+DRC[ \t]+Violation:[ \t]*([0-9]+)} \
        $s -> pre

    regexp -nocase \
        {Pin[ \t]+Access[ \t]+Violation:[ \t]*([0-9]+)} \
        $s -> pin

    return [dict create pre_route $pre pin_access $pin]
}

proc TT_CP2_run_check_place {tag} {
    # Stylus/Common UI equivalent of legacy colorizePowerMesh.
    # Innovus requires PG mesh coloring before placement-related commands.
    tech_mv_native_report_command 03 power_color [list add_power_mesh_colors]

    set s ""
    set rc [catch {
        redirect s {check_place} -variable -tee
    } err]

    set rpt [tech_mv_report_path 70 "${tag}_check_place" rpt 90 2ndpg_repair]
    set fp [open $rpt w]
    puts -nonewline $fp $s
    close $fp

    set d [TT_CP2_parse_check_place $s]
    dict set d rc $rc
    dict set d error $err
    dict set d report $rpt
    dict set d ok [expr {
        $rc == 0 &&
        [dict get $d pre_route] == 0 &&
        [dict get $d pin_access] == 0
    }]
    return $d
}


# Build {inst_name -> LS/ISO/RET}.
proc TT_CP2_lp_dict {} {
    set result [dict create]

    foreach spec {
        {{is_level_shifter == true} LS}
        {{is_isolation_cell == true} ISO}
        {{is_retention == true} RET}
    } {
        lassign $spec filter class
        set cells {}
        if {[catch {
            set cells [get_cells -hierarchical -filter $filter]
        } err]} {
            error "TT_CP2: cannot query $class cells: $err"
        }

        if {[llength $cells] == 0} {
            continue
        }

        foreach n [get_object_name $cells] {
            dict set result $n $class
        }
    }

    return $result
}


# Current check_place markers -> associated eligible LP candidate cells.
#
# Preferred discovery:
#   marker.objects -> inst
#
# This is important for SPPinAccessViolation.  Its marker bbox is the
# violation region, and get_obj_in_area -overlap_only can miss the actual
# offending instance even though the marker already records it in .objects.
#
# Fallback:
#   marker bbox -> get_obj_in_area
#
# This keeps compatibility with marker types that do not carry an inst object.
proc TT_CP2_candidates {} {
    set lp [TT_CP2_lp_dict]
    set result [dict create]

    set marker_count 0
    set marker_object_hits 0
    set marker_bbox_fallbacks 0
    set skipped_endcap 0
    set skipped_noncore 0
    set skipped_nonfixed 0
    set skipped_scope 0

    foreach m [get_db markers] {
        if {[TT_CP2_get $m .originator ""] ne "check_place"} {
            continue
        }
        incr marker_count

        set box [TT_CP2_get $m .bbox ""]
        set type [TT_CP2_get $m .type ""]
        set subtype [TT_CP2_get $m .subtype ""]

        # -------------------------------------------------------------
        # Preferred path: use the DB objects associated with the marker.
        # -------------------------------------------------------------
        set insts {}
        set marker_objs [TT_CP2_get $m .objects {}]

        foreach obj $marker_objs {
            if {[TT_CP2_get $obj .obj_type ""] eq "inst"} {
                lappend insts $obj
            }
        }

        if {[llength $insts] > 0} {
            incr marker_object_hits
        }

        # -------------------------------------------------------------
        # Fallback for markers without associated instance objects.
        # -------------------------------------------------------------
        if {[llength $insts] == 0 && $box ne ""} {
            incr marker_bbox_fallbacks

            if {[catch {
                set insts [get_obj_in_area \
                    -area $box \
                    -obj_type inst \
                    -overlap_only]
            } err]} {
                puts "WARNING: marker area query failed: $err"
                continue
            }
        }

        foreach inst $insts {
            set name [TT_CP2_get $inst .name ""]
            if {$name eq ""} {
                continue
            }

            if {!$::TT_CP2_REPAIR_INCLUDE_ENDCAP &&
                [string match "*ENDCAP_PD*" $name]} {
                incr skipped_endcap
                continue
            }

            set base_class [TT_CP2_get $inst .base_cell.base_class ""]
            set is_pad [TT_CP2_get $inst .is_pad 0]
            if {$base_class ne "core" || $is_pad eq "1" || $is_pad eq "true"} {
                incr skipped_noncore
                continue
            }

            set status [TT_CP2_get $inst .place_status ""]

            set route_mode [string toupper $::SECONDARY_PG_ROUTE_MODE]

            if {$route_mode eq "SIGNAL"} {
                # SIGNAL mode does not force LP cells fixed.  A marker-driven
                # repair may therefore operate on either placed or fixed LP
                # instances.  Other placement states remain ineligible.
                if {$status ni {placed fixed}} {
                    incr skipped_nonfixed
                    continue
                }
            } else {
                # Preserve original SROUTE safety policy.
                if {$status ne "fixed"} {
                    incr skipped_nonfixed
                    continue
                }
            }

            set class ""
            if {[dict exists $lp $name]} {
                set class [dict get $lp $name]
            }

            switch -- $::TT_CP2_REPAIR_SCOPE {
                LP_ONLY {
                    if {$class eq ""} {
                        incr skipped_scope
                        continue
                    }
                }
                ALL_FIXED_CORE {
                    # allowed
                }
                default {
                    error "TT_CP2_REPAIR_SCOPE must be LP_ONLY or ALL_FIXED_CORE"
                }
            }

            if {![dict exists $result $name]} {
                dict set result $name [dict create \
                    inst $inst \
                    class $class \
                    status $status \
                    old_loc [TT_CP2_point [TT_CP2_get $inst .location {}]] \
                    markers {}]
            }

            set tags [dict get $result $name markers]
            set tag "${type}/${subtype}"
            if {[lsearch -exact $tags $tag] < 0} {
                lappend tags $tag
                dict set result $name markers $tags
            }
        }
    }

    return [dict create \
        cells $result \
        marker_count $marker_count \
        marker_object_hits $marker_object_hits \
        marker_bbox_fallbacks $marker_bbox_fallbacks \
        skipped_endcap $skipped_endcap \
        skipped_noncore $skipped_noncore \
        skipped_nonfixed $skipped_nonfixed \
        skipped_scope $skipped_scope]
}


proc TT_CP2_find_pg_pin {inst leaf} {
    set found {}
    foreach p [get_db $inst .pg_pins] {
        set pname [TT_CP2_get $p .name ""]
        if {[lindex [split $pname "/"] end] eq $leaf} {
            lappend found $p
        }
    }
    if {[llength $found] == 0} {
        return {}
    }
    if {[llength $found] != 1} {
        error "TT_CP2: [get_db $inst .name] has multiple PG pins '$leaf'"
    }
    return [lindex $found 0]
}

proc TT_CP2_pg_net {p} {
    if {[llength $p] == 0} {
        return {}
    }
    set n [TT_CP2_get $p .net {}]
    if {[llength $n] == 0} {
        return {}
    }
    return [lindex $n 0]
}

proc TT_CP2_pd_name {inst} {
    set pd [TT_CP2_get $inst .power_domain {}]
    if {[llength $pd] > 0} {
        set pd [lindex $pd 0]

        set n ""
        if {![catch {set n [get_db $pd .name]}] && $n ne ""} {
            return $n
        }

        set raw [string trim $pd]
        if {[string match "power_domain:*" $raw]} {
            return [string range $raw [string length "power_domain:"] end]
        }
        if {$raw ne ""} {
            return $raw
        }
    }
    return [TT_CP2_get $inst .power_domain_name ""]
}


# {} means single-supply / no secondary route required.
# Otherwise returns {PD NET ROLE}.
proc TT_CP2_sec_info {inst class} {
    set name [get_db $inst .name]

    switch -- $class {
        LS {
            set p1 [TT_CP2_find_pg_pin $inst [::tech_mv_library_value LP_PIN_SECONDARY_A]]
            set p2 [TT_CP2_find_pg_pin $inst [::tech_mv_library_value LP_PIN_SECONDARY_B]]

            if {[llength $p1] == 0 && [llength $p2] == 0} {
                return {}
            }

            set n1 [TT_CP2_pg_net $p1]
            set n2 [TT_CP2_pg_net $p2]
            set connected {}

            if {[llength $n1] > 0} { lappend connected [list [::tech_mv_library_value LP_PIN_SECONDARY_A] $n1] }
            if {[llength $n2] > 0} { lappend connected [list [::tech_mv_library_value LP_PIN_SECONDARY_B] $n2] }

            if {[llength $connected] == 0} {
                error "TT_CP2: LS '$name' secondary PG pin exists but is unconnected"
            }
            if {[llength $connected] > 1} {
                error "TT_CP2: LS '$name' has both [::tech_mv_library_value LP_PIN_SECONDARY_A] and [::tech_mv_library_value LP_PIN_SECONDARY_B] connected"
            }

            lassign [lindex $connected 0] role net
        }

        ISO {
            set p [TT_CP2_find_pg_pin $inst [::tech_mv_library_value LP_PIN_SECONDARY_A]]
            if {[llength $p] == 0} {
                return {}
            }
            set net [TT_CP2_pg_net $p]
            if {[llength $net] == 0} {
                error "TT_CP2: ISO '$name' [::tech_mv_library_value LP_PIN_SECONDARY_A] is unconnected"
            }
            set role [::tech_mv_library_value LP_PIN_SECONDARY_A]
        }

        RET {
            set p [TT_CP2_find_pg_pin $inst [::tech_mv_library_value LP_PIN_RETENTION_AON]]
            if {[llength $p] == 0} {
                error "TT_CP2: RET '$name' has no [::tech_mv_library_value LP_PIN_RETENTION_AON]"
            }
            set net [TT_CP2_pg_net $p]
            if {[llength $net] == 0} {
                error "TT_CP2: RET '$name' [::tech_mv_library_value LP_PIN_RETENTION_AON] is unconnected"
            }
            set role [::tech_mv_library_value LP_PIN_RETENTION_AON]
        }

        default {
            return {}
        }
    }

    set pd [TT_CP2_pd_name $inst]
    if {$pd eq ""} {
        error "TT_CP2: cannot determine PD for '$name'"
    }

    return [list $pd [get_db $net .name] $role]
}


# Re-run the same secondary-PG route mode only for PD+net groups containing
# moved LP candidate cells.
proc TT_CP2_reroute_moved {moved candidates fp} {
    if {!$::TT_CP2_REPAIR_REROUTE_2NDPG} {
        puts $fp "2NDPG_REROUTE disabled"
        return 0
    }


    set mode [string toupper $::SECONDARY_PG_ROUTE_MODE]
    if {$mode ni {SIGNAL SROUTE}} {
        error "TT_CP2: SECONDARY_PG_ROUTE_MODE must be SIGNAL or SROUTE"
    }

    set pairs {}
    set nets {}
    set groups [dict create]

    foreach name $moved {
        set d [dict get $candidates $name]
        set class [dict get $d class]
        if {$class eq ""} {
            continue
        }

        set objs [get_db insts $name]
        if {[llength $objs] != 1} {
            error "TT_CP2: cannot resolve moved cell '$name'"
        }

        set inst [lindex $objs 0]
        set info [TT_CP2_sec_info $inst $class]

        if {[llength $info] == 0} {
            puts $fp "2NDPG_SINGLE_SUPPLY cell=$name class=$class"
            continue
        }

        lassign $info pd net role

        set cell_name [TT_CP2_get $inst .base_cell.name ""]
        if {$cell_name eq ""} {
            error "TT_CP2: cannot resolve base cell for '$name'"
        }

        set pair "${cell_name}:${role}"

        if {[lsearch -exact $pairs $pair] < 0} {
            lappend pairs $pair
        }
        if {[lsearch -exact $nets $net] < 0} {
            lappend nets $net
        }

        dict set groups "${pd}|${net}" [list $pd $net]

        puts $fp \
            "2NDPG_MOVED mode=$mode cell=$name class=$class pd=$pd net=$net pin=$role pair=$pair"
    }

    if {[llength $nets] == 0} {
        return 0
    }

    switch -- $mode {
        SIGNAL {
            set bottom_idx ""
            set top_idx ""

            if {![regexp {\(([0-9]+)\)$} \
                $::SECONDARY_PG_BOTTOM_LAYER -> bottom_idx]} {
                set bottom_idx $::SECONDARY_PG_BOTTOM_LAYER
            }

            if {![regexp {\(([0-9]+)\)$} \
                $::SECONDARY_PG_TOP_LAYER -> top_idx]} {
                set top_idx $::SECONDARY_PG_TOP_LAYER
            }

            set layer_range "${bottom_idx}:${top_idx}"

            puts "INFO: TT_CP2 2nd-PG reroute mode = SIGNAL"
            puts $fp \
                "2NDPG_SIGNAL layer_range=$layer_range pairs={$pairs} nets={$nets}"

            foreach pair $pairs {
                if {[catch {
                    eval_legacy "setPGPinUseSignalRoute $pair"
                } err]} {
                    error \
                        "TT_CP2: setPGPinUseSignalRoute failed for '$pair': $err"
                }
            }

            if {[catch {
                eval_legacy \
                    "setNanoRouteMode -routeStripeLayerRange $layer_range"
            } err]} {
                error \
                    "TT_CP2: cannot set routeStripeLayerRange '$layer_range': $err"
            }

            set count 0

            foreach net $nets {
                puts "INFO: routePGPinUseSignalRoute NET=$net"

                if {[catch {
                    eval_legacy \
                        "routePGPinUseSignalRoute -nets {$net}"
                } err]} {
                    catch {
                        eval_legacy \
                            {setNanoRouteMode -routeStripeLayerRange ""}
                    }

                    error \
                        "TT_CP2: SIGNAL secondary-PG reroute failed NET=$net: $err"
                }

                incr count
            }

            catch {
                eval_legacy \
                    {setNanoRouteMode -routeStripeLayerRange ""}
            }

            return $count
        }

        SROUTE {
            set layer_range [list \
                $::SECONDARY_PG_BOTTOM_LAYER \
                $::SECONDARY_PG_TOP_LAYER]

            set vgrid [list \
                $::SECONDARY_PG_TOP_LAYER \
                0 \
                0]

            puts "INFO: TT_CP2 2nd-PG reroute mode = SROUTE"
            puts $fp "2NDPG_SROUTE layer_range={$layer_range}"

            catch {
                eval_legacy "setSrouteMode -reset"
            }

            set_db route_special_via_connect_to_shape {stripe}

            set count 0

            foreach key [lsort [dict keys $groups]] {
                lassign [dict get $groups $key] pd net

                puts "INFO: route_special PD=$pd NET=$net"

                if {[catch {
                    route_special \
                        -connect secondary_power_pin \
                        -layer_change_range $layer_range \
                        -secondary_pin_rail_vertical_stripe_grid $vgrid \
                        -allow_jogging 1 \
                        -power_domains $pd \
                        -crossover_via_layer_range $layer_range \
                        -secondary_pin_rail_layer \
                            $::SECONDARY_PG_RAIL_LAYER \
                        -nets $net \
                        -allow_layer_change 1 \
                        -secondary_pin_net $net \
                        -target_via_layer_range $layer_range
                } err]} {
                    error \
                        "TT_CP2: SROUTE secondary-PG reroute failed PD=$pd NET=$net: $err"
                }

                incr count
            }

            return $count
        }
    }
}



proc TT_CP2_preview {} {
    puts ""
    puts "======================================================================"
    puts " POST-2ndPG CHECK_PLACE REPAIR PREVIEW"
    puts "======================================================================"

    set cp [TT_CP2_run_check_place preview_before]
    set discovery [TT_CP2_candidates]
    set cells [dict get $discovery cells]

    set rpt [tech_mv_report_path 71 preview_candidates rpt 90 2ndpg_repair]
    set fp [open $rpt w]

    puts $fp "Scope                 : $::TT_CP2_REPAIR_SCOPE"
    puts $fp "Include ENDCAP_PD     : $::TT_CP2_REPAIR_INCLUDE_ENDCAP"
    puts $fp "Reroute moved 2ndPG   : $::TT_CP2_REPAIR_REROUTE_2NDPG"
    puts $fp "Pre-route DRC         : [dict get $cp pre_route]"
    puts $fp "Pin Access            : [dict get $cp pin_access]"
    puts $fp "check_place markers   : [dict get $discovery marker_count]"
    puts $fp "marker object hits    : [dict get $discovery marker_object_hits]"
    puts $fp "marker bbox fallbacks : [dict get $discovery marker_bbox_fallbacks]"
    puts $fp "Candidate cells       : [dict size $cells]"
    puts $fp "Skipped EndCap        : [dict get $discovery skipped_endcap]"
    puts $fp "Skipped non-core      : [dict get $discovery skipped_noncore]"
    puts $fp "Skipped non-fixed     : [dict get $discovery skipped_nonfixed]"
    puts $fp "Skipped by scope      : [dict get $discovery skipped_scope]"
    puts $fp ""

    foreach name [lsort [dict keys $cells]] {
        set d [dict get $cells $name]
        puts $fp "cell=$name class=[dict get $d class] loc={[dict get $d old_loc]} markers={[dict get $d markers]}"
    }

    close $fp

    puts "Pre-route DRC Violation : [dict get $cp pre_route]"
    puts "Pin Access Violation    : [dict get $cp pin_access]"
    puts "Candidate cells         : [dict size $cells]"
    puts "Marker object hits      : [dict get $discovery marker_object_hits]"
    puts "Marker bbox fallbacks   : [dict get $discovery marker_bbox_fallbacks]"
    puts "Report                  : $rpt"
    puts "======================================================================"

    return [dict create check $cp discovery $discovery report $rpt]
}


proc TT_CP2_repair {} {
    puts ""
    puts "======================================================================"
    puts " POST-2ndPG CHECK_PLACE REPAIR"
    puts "======================================================================"

    # Marker-driven exception to the normal checkpoint policy:
    #   - If a formal checkpoint already produced check_place markers, reuse
    #     them directly and run ZERO extra check_place commands here.
    #   - If no check_place marker exists, run check_place ONCE to create the
    #     markers required by this repair tool.
    #   - Do NOT run a second check_place after repair.  Validation belongs to
    #     the next formal checkpoint.
    set existing_marker_count 0
    foreach m [get_db markers] {
        if {[TT_CP2_get $m .originator ""] eq "check_place"} {
            incr existing_marker_count
        }
    }

    set marker_source EXISTING_CHECKPOINT
    set local_check {}

    if {$existing_marker_count == 0} {
        puts "INFO: No existing check_place marker; generating markers once."
        set local_check [TT_CP2_run_check_place repair_marker_generation]
        set marker_source LOCAL_SINGLE_CHECK

        if {[dict get $local_check pre_route] == 0 &&
            [dict get $local_check pin_access] == 0} {
            puts "INFO: Local check_place is clean. No repair required."
            return [dict create \
                status NO_ACTION \
                marker_source $marker_source \
                check $local_check]
        }
    } else {
        puts "INFO: Reusing $existing_marker_count existing check_place marker(s)."
        puts "INFO: No additional pre-repair check_place is run."
    }

    set discovery [TT_CP2_candidates]
    set candidates [dict get $discovery cells]
    set names [lsort [dict keys $candidates]]
    set n [llength $names]

    if {$n == 0} {
        error "TT_CP2: check_place markers exist but no eligible fixed candidate cells were found. Run TT_CP2_preview only if you intentionally want a fresh marker-generation check."
    }
    if {$n > $::TT_CP2_REPAIR_MAX_CELLS} {
        error "TT_CP2: $n candidates exceeds safety limit $::TT_CP2_REPAIR_MAX_CELLS"
    }

    lassign [TT_CP2_repair_db_names] rollback_name repaired_name
    set rollback [file join [TT_CP2_db_dir] $rollback_name]
    set repaired [file join [TT_CP2_db_dir] $repaired_name]
    set rpt [tech_mv_report_path 72 repair rpt 90 2ndpg_repair]
    set fp [open $rpt w]

    puts $fp "Marker source       : $marker_source"
    puts $fp "Existing markers    : $existing_marker_count"
    puts $fp "Candidate count     : $n"
    puts $fp "Rollback DB         : $rollback"
    puts $fp "Validation policy   : deferred to next formal checkpoint"
    if {$marker_source eq "LOCAL_SINGLE_CHECK"} {
        puts $fp "Local Pre-route DRC : [dict get $local_check pre_route]"
        puts $fp "Local Pin Access    : [dict get $local_check pin_access]"
        puts $fp "Local check report  : [dict get $local_check report]"
    }
    puts $fp ""

    # MUST be before any placement-status change.
    puts "INFO: Saving rollback DB: $rollback"
    write_db $rollback

    set released 0
    foreach name $names {
        set objs [get_db insts $name]
        if {[llength $objs] != 1} {
            close $fp
            error "TT_CP2: cannot resolve '$name'"
        }
        set inst [lindex $objs 0]

        if {[get_db $inst .place_status] eq "fixed"} {
            set_db $inst .place_status placed
            incr released
            puts $fp "RELEASE cell=$name fixed->placed"
        }
    }

    puts "INFO: Released fixed cells = $released"
    puts "INFO: Running place_detail ..."
    puts $fp "RUN place_detail"
    place_detail

    set moved {}
    foreach name $names {
        set inst [lindex [get_db insts $name] 0]
        set old [dict get $candidates $name old_loc]
        set new [TT_CP2_point [get_db $inst .location]]

        if {[TT_CP2_moved $old $new]} {
            lappend moved $name
            puts $fp "MOVED cell=$name old={$old} new={$new}"
        } else {
            puts $fp "UNCHANGED cell=$name loc={$new}"
        }
    }

    puts "INFO: Candidate cells moved = [llength $moved]"

    # Moving an LP cell after 2nd-PG routing can disconnect its old secondary
    # pin route. Reconnect using the existing flow policy.
    set rerouted [TT_CP2_reroute_moved $moved $candidates $fp]

    set refixed 0
    foreach name $names {
        set inst [lindex [get_db insts $name] 0]
        if {[dict get $candidates $name status] eq "fixed"} {
            set_db $inst .place_status fixed
            incr refixed
            puts $fp "REFIX cell=$name"
        }
    }

    puts $fp ""
    puts $fp "Released       : $released"
    puts $fp "Moved          : [llength $moved]"
    puts $fp "Rerouted groups: $rerouted"
    puts $fp "Refixed        : $refixed"
    puts $fp "STATUS         : REPAIRED_PENDING_NEXT_CHECKPOINT"
    close $fp

    # Save the repaired state without running another checker here.
    write_db $repaired

    puts "INFO: Repair completed."
    puts "INFO: No post-repair check_place was run."
    puts "INFO: Validation is deferred to the next formal checkpoint."
    puts "INFO: Repaired DB = $repaired"

    return [dict create \
        status REPAIRED_PENDING_NEXT_CHECKPOINT \
        marker_source $marker_source \
        moved $moved \
        rerouted_groups $rerouted \
        rollback_db $rollback \
        repaired_db $repaired \
        report $rpt]
}


proc TT_CP2_restore {} {
    lassign [TT_CP2_repair_db_names] rollback_name repaired_name
    set db [file join [TT_CP2_db_dir] $rollback_name]
    if {![file exists $db]} {
        error "TT_CP2 restore DB does not exist: $db"
    }

    puts "INFO: Restoring $db"
    read_db $db

    if {[file exists init.setup]} {
        source init.setup
    }
    if {[info exists ::SCRIPT_DIR]} {
        set prep [file join $::SCRIPT_DIR prepare_run_dirs.tcl]
        if {[file exists $prep]} {
            source -quiet $prep
        }
    }

    puts "INFO: TT_CP2 restore complete."
}


puts "INFO: Loaded TT_DRC_fix_post2nd_checkplace.tcl"
puts "INFO: TT_CP2_preview"
puts "INFO: TT_CP2_repair"
puts "INFO: TT_CP2_restore"
