# Runtime adapter preserves the historical logical source path.
if {[info exists ::TECH_MV_RUNTIME_ROOT]} {
    info script [file join $::TECH_MV_RUNTIME_ROOT run/tool/01_floorplan/TT_tool_iopad_innovus_local_bridge.tcl]
}
# Load definitions only; no APR action or setup reload is performed here.
if {![llength [info commands ::tech_mv_library_value]]} {
    if {[info exists ::TOOL_DIR]} {
        source -quiet [file join $::TECH_MV_RUNTIME_ROOT .. script PR TECH_MV script 00_common private_parameter_config.tcl]
    } else {
        source -quiet [file join $::TECH_MV_RUNTIME_ROOT .. script PR TECH_MV script 00_common private_parameter_config.tcl]
    }
}
# =============================================================================
# TECH_MV IO PAD TOOL - LINUX LOCAL INNOVUS BRIDGE V128
# =============================================================================
# Same-host filesystem mailbox. No TCP / host / port / token.
#
# Normal flow hook:
#   source run/tool/01_floorplan/TT_flow_iopad_interface_start.tcl
#
# Manual:
#   source run/tool/01_floorplan/TT_tool_iopad_innovus_local_bridge.tcl
#   TT_IOPAD_LOCAL_BRIDGE_START
#
# Stop:
#   TT_IOPAD_LOCAL_BRIDGE_STOP
#
# Operations:
#   PING
#   QUERY_IOPAD
#   QUERY_GLOBAL_NET
#   DISCOVER_IOPAD
#   APPLY_DB_PATCH
#   APPLY_DB_AND_IO_FILE
#   APPLY_GLOBAL_NET
#
# APPLY_DB_AND_IO_FILE delegates IO import to the project-owned redo_IO command.
# APPLY_GLOBAL_NET is Global-Net-only and explicitly rejects redo_IO/read_io_file.
# =============================================================================

namespace eval ::TTIOPAD_LOCAL {
    variable bridge_dir ""
    variable poll_ms 100
    variable after_id ""
    variable running 0
}

proc ::TTIOPAD_LOCAL::b64_encode {text} {
    set raw [binary encode base64 $text]
    return [string map [list "\n" "" "\r" ""] $raw]
}

proc ::TTIOPAD_LOCAL::b64_decode {text} {
    if {$text eq ""} {
        return ""
    }
    return [binary decode base64 $text]
}

proc ::TTIOPAD_LOCAL::tsv_escape {value} {
    return [string map [list "\\" "\\\\" "\t" "\\t" "\n" "\\n" "\r" "\\r"] $value]
}

proc ::TTIOPAD_LOCAL::tsv_line {fields} {
    set out {}
    foreach f $fields {
        lappend out [::TTIOPAD_LOCAL::tsv_escape $f]
    }
    return "[join $out \t]\n"
}


# =============================================================================
# V128.20 MERGED BRIDGE: NO-IO_FILE DISCOVERY + GLOBAL NET VERIFY + MASTER CATALOG
# Built from the user-provided original bridge. Existing QUERY/APPLY mutation
# protections remain; V128 adds fresh PAD-pin/domain connectivity query, Global-Net-only apply, and preloaded base-cell geometry metadata.
# =============================================================================
proc ::TTIOPAD_LOCAL::bbox4 {bbox} {
    set flat [string map [list "{" " " "}" " "] $bbox]
    set nums {}
    foreach tok [split $flat] {
        if {[string is double -strict $tok]} {
            lappend nums $tok
        }
    }
    if {[llength $nums] < 4} {
        return {}
    }
    return [lrange $nums 0 3]
}

proc ::TTIOPAD_LOCAL::nums {value} {
    set flat [string map [list "{" " " "}" " " "," " "] $value]
    set nums {}
    foreach tok [split $flat] {
        if {[string is double -strict $tok]} { lappend nums $tok }
    }
    return $nums
}

proc ::TTIOPAD_LOCAL::exact_base_cell {master} {
    set matches {}
    catch { set matches [get_db base_cells $master] }
    foreach B $matches {
        set n {}
        if {![catch {set n [get_db $B .name]}] && $n eq $master} {
            return $B
        }
    }
    return {}
}

proc ::TTIOPAD_LOCAL::master_geometry {master} {
    # Return {bbox size source}. All probes are optional/caught so a library
    # release without a specific base-cell attribute cannot break QUERY_IOPAD.
    set B [::TTIOPAD_LOCAL::exact_base_cell $master]
    if {$B eq {}} { return [list {} {} BASE_CELL_NOT_FOUND] }

    set bbox {}
    if {![catch {set bbox [get_db $B .bbox]}]} {
        set b [::TTIOPAD_LOCAL::bbox4 $bbox]
        if {[llength $b] == 4} {
            lassign $b x1 y1 x2 y2
            set w [expr {abs(double($x2)-double($x1))}]
            set h [expr {abs(double($y2)-double($y1))}]
            if {$w > 0.0 && $h > 0.0} {
                return [list $bbox [list $w $h] BASE_CELL_BBOX]
            }
        }
    }

    set size {}
    if {![catch {set size [get_db $B .size]}]} {
        set n [::TTIOPAD_LOCAL::nums $size]
        if {[llength $n] >= 2} {
            set w [expr {abs(double([lindex $n 0]))}]
            set h [expr {abs(double([lindex $n 1]))}]
            if {$w > 0.0 && $h > 0.0} {
                return [list {} [list $w $h] BASE_CELL_SIZE]
            }
        }
    }

    foreach attrs {{.size_x .size_y} {.width .height}} {
        lassign $attrs ax ay
        set x {}; set y {}
        if {![catch {set x [get_db $B $ax]}] && ![catch {set y [get_db $B $ay]}]
            && [string is double -strict $x] && [string is double -strict $y]} {
            set w [expr {abs(double($x))}]
            set h [expr {abs(double($y))}]
            if {$w > 0.0 && $h > 0.0} {
                return [list {} [list $w $h] BASE_CELL_ATTRS]
            }
        }
    }
    return [list {} {} BASE_CELL_GEOMETRY_UNAVAILABLE]
}

proc ::TTIOPAD_LOCAL::obj_name {obj} {
    if {$obj eq {}} { return {} }
    set n {}
    if {![catch {set n [get_db $obj .name]}] && $n ne {}} { return $n }
    return $obj
}

proc ::TTIOPAD_LOCAL::pin_net_names {P} {
    set nets {}
    set ok 0
    if {![catch {set nets [get_db $P .net.name]}]} { set ok 1 }
    if {!$ok} {
        set N {}
        if {![catch {set N [get_db $P .net]}]} {
            set out {}
            foreach n $N {
                set name [::TTIOPAD_LOCAL::obj_name $n]
                if {$name ne {}} { lappend out $name }
            }
            set nets $out
            set ok 1
        }
    }
    return [list $nets $ok]
}

proc ::TTIOPAD_LOCAL::inst_power_domain {I} {
    foreach attr {.power_domain.name .power_domain} {
        set value {}
        if {![catch {set value [get_db $I $attr]}]} {
            if {$value eq {}} { return [list {} 1 $attr] }
            if {$attr eq ".power_domain"} { set value [::TTIOPAD_LOCAL::obj_name $value] }
            return [list $value 1 $attr]
        }
    }
    return [list {} 0 UNAVAILABLE]
}

proc ::TTIOPAD_LOCAL::first_attr {obj attrs} {
    foreach attr $attrs {
        set value {}
        if {![catch {set value [get_db $obj $attr]}] && $value ne {}} {
            return [list $value 1 $attr]
        }
    }
    return [list {} 0 UNAVAILABLE]
}

proc ::TTIOPAD_LOCAL::emit_power_domains {} {
    set out ""
    set pds {}
    catch {set pds [get_db power_domains]}
    set names {}
    foreach PD $pds {
        set name [::TTIOPAD_LOCAL::obj_name $PD]
        if {$name eq {}} { continue }
        lappend names $name
        lassign [::TTIOPAD_LOCAL::first_attr $PD {.primary_power_net.name .primary_power_net}] pp ppok ppsrc
        lassign [::TTIOPAD_LOCAL::first_attr $PD {.primary_ground_net.name .primary_ground_net}] pg pgok pgsrc
        lassign [::TTIOPAD_LOCAL::first_attr $PD {.available_supply_nets.name .available_supply_nets}] av avok avsrc
        append out [::TTIOPAD_LOCAL::tsv_line [list META power_domain::${name}::primary_power $pp]]
        append out [::TTIOPAD_LOCAL::tsv_line [list META power_domain::${name}::primary_ground $pg]]
        append out [::TTIOPAD_LOCAL::tsv_line [list META power_domain::${name}::available_supply_nets $av]]
        append out [::TTIOPAD_LOCAL::tsv_line [list META power_domain::${name}::query_sources "$ppsrc;$pgsrc;$avsrc"]]
    }
    append out [::TTIOPAD_LOCAL::tsv_line [list META power_domain_names $names]]
    append out [::TTIOPAD_LOCAL::tsv_line [list META power_domain_count [llength $names]]]
    return $out
}

proc ::TTIOPAD_LOCAL::emit_pg_net_polarities {} {
    # V128.20: report actual PG-net polarity from fresh Innovus DB so the GUI
    # can avoid reusing stale auto-net names created with the wrong type.
    set out ""
    set count 0
    set qok 1
    set qerr {}
    set pgs {}
    if {[catch {set pgs [get_pg_nets *]} qerr]} {
        set qok 0
        set pgs {}
    }
    if {$qok} {
        foreach_in_collection PG $pgs {
            set name {}
            set isp 0
            set isg 0
            catch {set name [get_property $PG hierarchical_name]}
            if {$name eq {}} { catch {set name [get_property $PG name]} }
            if {$name eq {}} { continue }
            catch {set isp [get_property $PG is_power]}
            catch {set isg [get_property $PG is_ground]}
            set pol UNKNOWN
            if {$isp eq {true} || $isp eq {1}} { set pol POWER }
            if {$isg eq {true} || $isg eq {1}} {
                if {$pol eq {POWER}} { set pol AMBIGUOUS } else { set pol GROUND }
            }
            append out [::TTIOPAD_LOCAL::tsv_line [list META pg_net_polarity::${name} $pol]]
            incr count
        }
    }
    append out [::TTIOPAD_LOCAL::tsv_line [list META pg_net_polarity_query_ok $qok]]
    append out [::TTIOPAD_LOCAL::tsv_line [list META pg_net_polarity_count $count]]
    if {!$qok} {
        append out [::TTIOPAD_LOCAL::tsv_line [list META pg_net_polarity_query_error $qerr]]
    }
    return $out
}

proc ::TTIOPAD_LOCAL::preload_pad_master_candidates {master_candidates_var} {
    upvar 1 $master_candidates_var master_candidates
    foreach family [::tech_mv_library_value LIB_CELL_004] {
        foreach master [list $family ${family}_H ${family}_V] {
            if {[::TTIOPAD_LOCAL::exact_base_cell $master] ne {}} {
                dict set master_candidates $master 1
            }
        }
    }
}

proc ::TTIOPAD_LOCAL::point_box_distance {px py b} {
    lassign $b x1 y1 x2 y2
    if {$x1 > $x2} {
        set t $x1
        set x1 $x2
        set x2 $t
    }
    if {$y1 > $y2} {
        set t $y1
        set y1 $y2
        set y2 $t
    }

    set dx 0.0
    set dy 0.0
    if {$px < $x1} {
        set dx [expr {$x1 - $px}]
    } elseif {$px > $x2} {
        set dx [expr {$px - $x2}]
    }
    if {$py < $y1} {
        set dy [expr {$y1 - $py}]
    } elseif {$py > $y2} {
        set dy [expr {$py - $y2}]
    }
    return [expr {$dx + $dy}]
}


proc ::TTIOPAD_LOCAL::emit_master_pg_types {out_var master} {
    # V128.17: preload exact library PG-pin pg_type once per exact master.
    upvar 1 $out_var out
    set emitted 0
    set cells {}
    if {![catch {set cells [get_lib_cells $master]}] && [llength $cells] > 0} {
        foreach C $cells {
            set pgpins {}
            if {[catch {set pgpins [get_lib_pg_pins -of_objects $C]}]} { continue }
            foreach LP $pgpins {
                set pname {}
                set ptype {}
                catch {set pname [get_property $LP name]}
                catch {set ptype [get_property $LP pg_type]}
                if {$pname eq {} || $ptype eq {}} { continue }
                append out [::TTIOPAD_LOCAL::tsv_line [list META master_pg_type::${master}::${pname} $ptype]]
                incr emitted
            }
        }
    }
    if {$emitted == 0} {
        # Common-UI fallback for environments where get_lib_* is not exposed.
        set bcs {}
        catch {set bcs [get_db base_cells $master]}
        foreach C $bcs {
            set pgpins {}
            catch {set pgpins [get_db $C .pg_pins]}
            foreach LP $pgpins {
                set pname {}
                set ptype {}
                catch {set pname [get_db $LP .name]}
                catch {set ptype [get_db $LP .pg_type]}
                set pname [lindex [split $pname /] end]
                if {$pname eq {} || $ptype eq {}} { continue }
                append out [::TTIOPAD_LOCAL::tsv_line [list META master_pg_type::${master}::${pname} $ptype]]
                incr emitted
            }
        }
    }
    return $emitted
}

proc ::TTIOPAD_LOCAL::discover_iopad_names {} {
    set all_insts [get_db insts]

    # Confirmed TECH_MV ring families. _H/_V variants are normalized back to
    # their base family. Corners are selected only from the configured corner master.
    set confirmed [::tech_mv_library_value IOPAD_DISCOVERY_MASTER_FAMILIES]
    set corner_master [::tech_mv_library_value IOPAD_DISCOVERY_CORNER_MASTER]
    set names {}
    set seen [dict create]
    set corner_objs {}
    set min_x {}
    set min_y {}
    set max_x {}
    set max_y {}

    foreach I $all_insts {
        set master [get_db $I .base_cell.name]
        set family $master
        regexp {^(.*)_([HV])$} $master _ family _variant

        if {$family eq $corner_master} {
            lappend corner_objs $I
            continue
        }
        if {[lsearch -exact $confirmed $family] < 0} {
            continue
        }

        set name [get_db $I .name]
        if {![dict exists $seen $name]} {
            dict set seen $name 1
            lappend names $name
        }

        set b [::TTIOPAD_LOCAL::bbox4 [get_db $I .bbox]]
        if {[llength $b] != 4} {
            continue
        }
        lassign $b x1 y1 x2 y2
        set lx [expr {min(double($x1), double($x2))}]
        set ly [expr {min(double($y1), double($y2))}]
        set hx [expr {max(double($x1), double($x2))}]
        set hy [expr {max(double($y1), double($y2))}]

        if {$min_x eq {} || $lx < $min_x} { set min_x $lx }
        if {$min_y eq {} || $ly < $min_y} { set min_y $ly }
        if {$max_x eq {} || $hx > $max_x} { set max_x $hx }
        if {$max_y eq {} || $hy > $max_y} { set max_y $hy }
    }

    if {[llength $names] < 4 || $min_x eq {}} {
        error "DB bootstrap discovery found too few confirmed IO instances"
    }

    set targets [dict create \
        topright    [list $max_x $max_y] \
        topleft     [list $min_x $max_y] \
        bottomleft  [list $min_x $min_y] \
        bottomright [list $max_x $min_y]]

    set corner_meta [dict create]
    set chosen [dict create]

    foreach key {topright topleft bottomleft bottomright} {
        lassign [dict get $targets $key] px py
        set have 0
        set best_d 0.0
        set best_area 0.0
        set best_name ""

        foreach I $corner_objs {
            set name [get_db $I .name]
            if {[dict exists $seen $name] || [dict exists $chosen $name]} {
                continue
            }

            set b [::TTIOPAD_LOCAL::bbox4 [get_db $I .bbox]]
            if {[llength $b] != 4} {
                continue
            }
            lassign $b x1 y1 x2 y2
            set area [expr {abs((double($x2) - double($x1)) * (double($y2) - double($y1)))}]
            set d [::TTIOPAD_LOCAL::point_box_distance $px $py $b]

            if {!$have || $d < $best_d || ($d == $best_d && $area > $best_area)} {
                set have 1
                set best_d $d
                set best_area $area
                set best_name $name
            }
        }

        if {!$have || $best_name eq ""} {
            error "Unable to discover corner $key"
        }

        dict set chosen $best_name 1
        dict set seen $best_name 1
        dict set corner_meta bootstrap_corner_$key $best_name
        lappend names $best_name
    }

    dict set corner_meta discovery_mode ALL_DB_IOPAD
    dict set corner_meta bootstrap_ring_candidate_count [expr {[llength $names] - 4}]
    return [list $names $corner_meta]
}

proc ::TTIOPAD_LOCAL::discover_iopad {} {
    lassign [::TTIOPAD_LOCAL::discover_iopad_names] requested_list extra_meta

    # Reuse the original QUERY_IOPAD implementation verbatim so all existing
    # query semantics stay intact. Discovery metadata is appended to the same
    # TSV result; the GUI accepts META records anywhere in the TSV stream.
    set out [::TTIOPAD_LOCAL::query_iopad [join $requested_list "\n"]]
    foreach key [dict keys $extra_meta] {
        append out [::TTIOPAD_LOCAL::tsv_line \
            [list META $key [dict get $extra_meta $key]]]
    }
    return $out
}

proc ::TTIOPAD_LOCAL::query_iopad {payload} {
    set requested_list {}

    foreach requested [split $payload "\n"] {
        set requested [string trim $requested]
        if {$requested eq ""} {
            continue
        }
        lappend requested_list $requested
    }

    set out ""
    append out [::TTIOPAD_LOCAL::tsv_line [list META schema TECH_MV_IOPAD_QUERY_RESULT_V10]]
    append out [::TTIOPAD_LOCAL::tsv_line [list META producer ioPADt_V128_20_live_bridge]]
    append out [::TTIOPAD_LOCAL::tsv_line [list META connectivity_queried 1]]
    append out [::TTIOPAD_LOCAL::tsv_line [list META role_inferred_from_instance_name 0]]
    append out [::TTIOPAD_LOCAL::tsv_line [list META requested_instance_count [llength $requested_list]]]

    # V120: keep live QUERY_IOPAD metadata identical to generated Query Tcl.
    set design_area {}
    set design_area_query_ok 1
    set design_area_query_error {}
    if {[catch {set design_area [get_db current_design .area]} design_area_query_error]} {
        set design_area {}
        set design_area_query_ok 0
    }
    append out [::TTIOPAD_LOCAL::tsv_line [list META current_design_area $design_area]]
    append out [::TTIOPAD_LOCAL::tsv_line [list META current_design_area_query_ok $design_area_query_ok]]
    append out [::TTIOPAD_LOCAL::tsv_line [list META current_design_area_source {get_db current_design .area}]]
    if {!$design_area_query_ok} {
        append out [::TTIOPAD_LOCAL::tsv_line [list META current_design_area_query_error $design_area_query_error]]
    }

    append out [::TTIOPAD_LOCAL::emit_power_domains]
    append out [::TTIOPAD_LOCAL::emit_pg_net_polarities]

    set found_count 0
    set missing_count 0
    set pin_connectivity_query_count 0
    set pin_connectivity_query_fail_count 0
    set power_domain_query_count 0
    set power_domain_query_fail_count 0
    set master_candidates [dict create]
    ::TTIOPAD_LOCAL::preload_pad_master_candidates master_candidates

    foreach requested $requested_list {
        set matches {}
        catch {
            set matches [get_db insts $requested]
        }

        set I {}

        foreach cand $matches {
            if {[get_db $cand .name] eq $requested} {
                set I $cand
                break
            }
        }

        if {[llength $I] == 0} {
            incr missing_count
            append out [::TTIOPAD_LOCAL::tsv_line [list MISSING $requested]]
            continue
        }

        incr found_count

        set actual_name [get_db $I .name]
        set master [get_db $I .base_cell.name]
        dict set master_candidates $master 1
        if {[regexp {^(.*)_([HV])$} $master _ mfam mvar]} {
            dict set master_candidates ${mfam}_H 1
            dict set master_candidates ${mfam}_V 1
        }
        set is_pad [get_db $I .is_pad]
        set place_status [get_db $I .place_status]
        set orient [get_db $I .orient]
        set location [get_db $I .location]
        set bbox [get_db $I .bbox]
        set pg_objs [get_db $I .pg_pins]
        set pin_objs [get_db $I .pins]
        set pg_names {}
        foreach P $pg_objs { catch {lappend pg_names [get_db $P .name]} }
        set pin_names {}
        foreach P $pin_objs { catch {lappend pin_names [get_db $P .name]} }

        append out [::TTIOPAD_LOCAL::tsv_line [list INST \
            $requested $actual_name $master $is_pad $place_status $orient \
            $location $bbox $pg_names $pin_names]]

        lassign [::TTIOPAD_LOCAL::inst_power_domain $I] inst_pd inst_pd_ok inst_pd_source
        incr power_domain_query_count
        if {!$inst_pd_ok} { incr power_domain_query_fail_count }
        append out [::TTIOPAD_LOCAL::tsv_line [list PDINST \
            $requested $actual_name $inst_pd $inst_pd_ok $inst_pd_source]]

        set emitted_pin [dict create]
        foreach P $pg_objs {
            set pname [get_db $P .name]
            set pname [lindex [split $pname /] end]
            if {$pname eq {} || [dict exists $emitted_pin $pname]} { continue }
            dict set emitted_pin $pname 1
            lassign [::TTIOPAD_LOCAL::pin_net_names $P] pnets pok
            incr pin_connectivity_query_count
            if {!$pok} { incr pin_connectivity_query_fail_count }
            append out [::TTIOPAD_LOCAL::tsv_line [list PIN \
                $requested $actual_name $pname PG $pnets $pok]]
        }
        foreach P $pin_objs {
            set pname [get_db $P .name]
            set pname [lindex [split $pname /] end]
            if {$pname eq {} || [dict exists $emitted_pin $pname]} { continue }
            dict set emitted_pin $pname 1
            lassign [::TTIOPAD_LOCAL::pin_net_names $P] pnets pok
            incr pin_connectivity_query_count
            if {!$pok} { incr pin_connectivity_query_fail_count }
            append out [::TTIOPAD_LOCAL::tsv_line [list PIN \
                $requested $actual_name $pname SIGNAL $pnets $pok]]
        }
    }

    # V128: preloaded exact base-cell geometry makes planned/simulated H/V variants
    # measurable even when no instance of that exact variant is placed yet.
    set master_geom_found 0
    set master_geom_missing 0
    foreach master [lsort [dict keys $master_candidates]] {
        lassign [::TTIOPAD_LOCAL::master_geometry $master] mbbox msize msource
        if {$msize ne {}} {
            append out [::TTIOPAD_LOCAL::tsv_line [list META master_size::$master $msize]]
            if {$mbbox ne {}} {
                append out [::TTIOPAD_LOCAL::tsv_line [list META master_bbox::$master $mbbox]]
            }
            append out [::TTIOPAD_LOCAL::tsv_line [list META master_geometry_source::$master $msource]]
            incr master_geom_found
        } else {
            incr master_geom_missing
        }
        ::TTIOPAD_LOCAL::emit_master_pg_types out $master
    }
    append out [::TTIOPAD_LOCAL::tsv_line [list META master_geometry_found_count $master_geom_found]]
    append out [::TTIOPAD_LOCAL::tsv_line [list META master_geometry_missing_count $master_geom_missing]]
    append out [::TTIOPAD_LOCAL::tsv_line [list META pin_connectivity_query_count $pin_connectivity_query_count]]
    append out [::TTIOPAD_LOCAL::tsv_line [list META pin_connectivity_query_fail_count $pin_connectivity_query_fail_count]]
    append out [::TTIOPAD_LOCAL::tsv_line [list META power_domain_query_count $power_domain_query_count]]
    append out [::TTIOPAD_LOCAL::tsv_line [list META power_domain_query_fail_count $power_domain_query_fail_count]]
    append out [::TTIOPAD_LOCAL::tsv_line [list META global_net_mapping_source PAD_PIN_NET]]
    append out [::TTIOPAD_LOCAL::tsv_line [list META global_net_mapping_count $pin_connectivity_query_count]]

    append out [::TTIOPAD_LOCAL::tsv_line [list META found_instance_count $found_count]]
    append out [::TTIOPAD_LOCAL::tsv_line [list META missing_instance_count $missing_count]]

    return $out
}

proc ::TTIOPAD_LOCAL::apply_script {kind script} {
    if {$kind eq "APPLY_DB_PATCH"} {
        if {[string first "TECH_MV IO PAD GUI - INNOVUS DB PATCH" $script] < 0 && [string first "ioPADt PAD GUI - INNOVUS DB PATCH" $script] < 0} {
            error "Rejected APPLY_DB_PATCH: generated DB PATCH marker is missing."
        }
    } elseif {$kind eq "APPLY_DB_AND_IO_FILE"} {
        if {[string first "TECH_MV IOPAD GUI - APPLY DB + IO_FILE" $script] < 0 && [string first "ioPADt GUI - APPLY DB + IO_FILE" $script] < 0} {
            error "Rejected APPLY_DB_AND_IO_FILE: combined apply marker is missing."
        }
        if {[string first "TECH_MV IO PAD GUI - INNOVUS DB PATCH" $script] < 0 && [string first "ioPADt PAD GUI - INNOVUS DB PATCH" $script] < 0} {
            error "Rejected APPLY_DB_AND_IO_FILE: embedded DB PATCH marker is missing."
        }
        if {[string first {redo_IO $::TT_IOPAD_APPLY_IO_FILE} $script] < 0} {
            error "Rejected APPLY_DB_AND_IO_FILE: project redo_IO call is missing."
        }
        if {[regexp -line {^[ \t]*read_io_file([ \t]|$)} $script]} {
            error "Rejected APPLY_DB_AND_IO_FILE: direct read_io_file is forbidden; use project redo_IO."
        }
    } elseif {$kind eq "APPLY_GLOBAL_NET"} {
        if {[string first "TECH_MV IOPAD GUI - INNOVUS GLOBAL NET APPLY" $script] < 0 && [string first "ioPADt GUI - INNOVUS GLOBAL NET APPLY" $script] < 0} {
            error "Rejected APPLY_GLOBAL_NET: generated GLOBAL NET APPLY marker is missing."
        }
        if {[regexp -line {^[ \t]*(redo_IO|read_io_file)([ \t]|$)} $script]} {
            error "Rejected APPLY_GLOBAL_NET: Global Net apply must not call redo_IO/read_io_file."
        }
    } else {
        error "Unsupported mutation operation: $kind"
    }

    set rc [catch {
        uplevel #0 $script
    } result opts]

    if {$rc} {
        set detail $result
        if {[dict exists $opts -errorinfo]} {
            append detail "\n" [dict get $opts -errorinfo]
        }
        error $detail
    }

    return $result
}

proc ::TTIOPAD_LOCAL::dispatch {op payload} {
    switch -- $op {
        PING {
            return "BRIDGE_OK pid=[pid] Tcl=[info patchlevel]"
        }

        QUERY_IOPAD {
            return [::TTIOPAD_LOCAL::query_iopad $payload]
        }

        QUERY_GLOBAL_NET {
            return [::TTIOPAD_LOCAL::query_iopad $payload]
        }

        DISCOVER_IOPAD {
            return [::TTIOPAD_LOCAL::discover_iopad]
        }

        APPLY_DB_PATCH -
        APPLY_DB_AND_IO_FILE -
        APPLY_GLOBAL_NET {
            return [::TTIOPAD_LOCAL::apply_script $op $payload]
        }

        default {
            error "Unsupported local bridge operation: $op"
        }
    }
}

proc ::TTIOPAD_LOCAL::write_response {request_id status response} {
    variable bridge_dir

    set tmp [file join $bridge_dir "response_${request_id}.rsp.tmp"]
    set dst [file join $bridge_dir "response_${request_id}.rsp"]

    set fp [open $tmp w]
    fconfigure $fp -translation lf -encoding ascii
    puts $fp "TTIOPAD_LOCAL1\t$request_id\t$status\t[::TTIOPAD_LOCAL::b64_encode $response]"
    close $fp

    file rename -force $tmp $dst
}

proc ::TTIOPAD_LOCAL::process_request {path} {
    set fp [open $path r]
    fconfigure $fp -translation lf -encoding ascii
    set line [gets $fp]
    close $fp

    set fields [split $line "\t"]

    if {[llength $fields] != 4 || [lindex $fields 0] ne "TTIOPAD_LOCAL1"} {
        catch {
            file delete -force $path
        }
        return
    }

    set request_id [lindex $fields 1]
    set op [lindex $fields 2]

    set rc [catch {
        set payload [::TTIOPAD_LOCAL::b64_decode [lindex $fields 3]]
        ::TTIOPAD_LOCAL::dispatch $op $payload
    } result opts]

    if {$rc} {
        set detail $result

        if {[dict exists $opts -errorinfo]} {
            append detail "\n" [dict get $opts -errorinfo]
        }

        ::TTIOPAD_LOCAL::write_response $request_id ERR $detail
    } else {
        ::TTIOPAD_LOCAL::write_response $request_id OK $result
    }

    catch {
        file delete -force $path
    }
}

proc ::TTIOPAD_LOCAL::poll {} {
    variable bridge_dir
    variable poll_ms
    variable after_id
    variable running

    if {!$running} {
        return
    }

    foreach path [lsort [glob -nocomplain -directory $bridge_dir request_*.req]] {
        set work "${path}.work"

        if {[catch {
            file rename $path $work
        }]} {
            continue
        }

        set rc [catch {
            ::TTIOPAD_LOCAL::process_request $work
        } err opts]

        catch {
            file delete -force $work
        }

        if {$rc} {
            puts "**ERROR: TT_IOPAD_LOCAL_BRIDGE request failed: $err"
        }
    }

    set after_id [after $poll_ms ::TTIOPAD_LOCAL::poll]
}

proc TT_IOPAD_LOCAL_BRIDGE_START {{bridge_dir ""} {poll_ms 100}} {
    if {$::TTIOPAD_LOCAL::running} {
        puts "TT_IOPAD_LOCAL_BRIDGE already running."
        return $::TTIOPAD_LOCAL::bridge_dir
    }

    if {$bridge_dir eq ""} {
        if {[info exists ::env(INNOVUS_WORK_DIR)] && $::env(INNOVUS_WORK_DIR) ne ""} {
            set bridge_dir [file join $::env(INNOVUS_WORK_DIR) .tt_iopad_bridge]
        } else {
            set bridge_dir [file join [pwd] .tt_iopad_bridge]
        }
    }

    set bridge_dir [file normalize $bridge_dir]
    file mkdir $bridge_dir

    set ::TTIOPAD_LOCAL::bridge_dir $bridge_dir
    set ::TTIOPAD_LOCAL::poll_ms $poll_ms
    set ::TTIOPAD_LOCAL::running 1

    foreach stale [glob -nocomplain -directory $bridge_dir request_*.req request_*.req.work response_*.rsp response_*.rsp.tmp] {
        catch {
            file delete -force $stale
        }
    }

    set ready_tmp [file join $bridge_dir bridge.ready.tmp]
    set ready [file join $bridge_dir bridge.ready]

    set fp [open $ready_tmp w]
    fconfigure $fp -translation lf -encoding utf-8
    puts $fp "pid=[pid] poll_ms=$poll_ms cwd=[pwd]"
    close $fp

    file rename -force $ready_tmp $ready

    set ::TTIOPAD_LOCAL::after_id [after 0 ::TTIOPAD_LOCAL::poll]

    puts ""
    puts "======================================================================"
    puts " TECH_MV IO PAD LOCAL INNOVUS BRIDGE"
    puts "======================================================================"
    puts "Bridge dir   : $bridge_dir"
    puts "Poll interval: ${poll_ms}ms"
    puts "Operations   : PING QUERY_IOPAD QUERY_GLOBAL_NET DISCOVER_IOPAD APPLY_DB_PATCH APPLY_DB_AND_IO_FILE APPLY_GLOBAL_NET"
    puts "Network      : NONE"
    puts "IO reload      : APPLY_DB_AND_IO_FILE -> project redo_IO only"
    puts "======================================================================"

    return $bridge_dir
}

proc TT_IOPAD_LOCAL_BRIDGE_STOP {} {
    set ::TTIOPAD_LOCAL::running 0

    if {$::TTIOPAD_LOCAL::after_id ne ""} {
        catch {
            after cancel $::TTIOPAD_LOCAL::after_id
        }
    }

    set ::TTIOPAD_LOCAL::after_id ""

    if {$::TTIOPAD_LOCAL::bridge_dir ne ""} {
        catch {
            file delete -force [file join $::TTIOPAD_LOCAL::bridge_dir bridge.ready]
        }
    }

    puts "TT_IOPAD_LOCAL_BRIDGE stopped."
}
