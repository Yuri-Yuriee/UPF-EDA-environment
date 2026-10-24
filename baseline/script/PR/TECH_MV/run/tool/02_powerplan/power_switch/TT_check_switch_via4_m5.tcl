# Runtime adapter preserves the historical logical source path.
if {[info exists ::TECH_MV_RUNTIME_ROOT]} {
    info script [file join $::TECH_MV_RUNTIME_ROOT run/tool/02_powerplan/power_switch/TT_check_switch_via4_m5.tcl]
}
# Read-only geometric check. No routing/deletion/repair or automatic Flow hook.
namespace eval ::TT_SW_VIA_M5 {}
# Explicit layer identities requested by the user; no physical dimensions.
# May be set by the existing Library config before this definitions-only load.
if {![info exists ::TT_SW_VIA_LAYER_MAP]} {
    set ::TT_SW_VIA_LAYER_MAP {VIA1 M2 VIA2 M3 VIA3 M4 VIA4 M5}
}
proc ::TT_SW_VIA_M5::rects {value} {
    if {[llength $value] == 4} {
        set numeric true
        foreach v $value {if {![string is double -strict $v]} {set numeric false;break}}
        if {$numeric} {
            lassign $value x1 y1 x2 y2
            if {$x1 < $x2 && $y1 < $y2} {return [list $value]}
            return {}
        }
    }
    set result {}
    foreach child $value {
        if {$child eq $value} {return {}}
        lappend result {*}[::TT_SW_VIA_M5::rects $child]
    }
    return $result
}
# Subtract one metal rectangle from a remaining via-top rectangle.
proc ::TT_SW_VIA_M5::subtract {a b} {
    lassign $a x1 y1 x2 y2;lassign $b u1 v1 u2 v2
    set lx [expr {max($x1,$u1)}];set ly [expr {max($y1,$v1)}]
    set ux [expr {min($x2,$u2)}];set uy [expr {min($y2,$v2)}]
    if {$lx >= $ux || $ly >= $uy} {return [list $a]}
    set out {}
    if {$x1 < $lx} {lappend out [list $x1 $y1 $lx $y2]}
    if {$ux < $x2} {lappend out [list $ux $y1 $x2 $y2]}
    if {$y1 < $ly} {lappend out [list $lx $y1 $ux $ly]}
    if {$uy < $y2} {lappend out [list $lx $uy $ux $y2]}
    return $out
}
proc ::TT_SW_VIA_M5::classify {tops metal} {
    if {![llength $tops]} {return UNKNOWN}
    set remaining $tops;set touched false
    foreach m $metal {
        set next {}
        foreach r $remaining {
            set parts [::TT_SW_VIA_M5::subtract $r $m]
            if {$parts ne [list $r]} {set touched true}
            lappend next {*}$parts
        }
        set remaining $next
    }
    if {![llength $remaining]} {return COVERED}
    if {$touched} {return PARTIAL}
    return NO_CONTACT
}
# Known adjacent cut-layer identities; configurable without fixed dimensions.
if {![info exists ::TT_SW_VIA_BOTTOM_LAYER_MAP]} {
    set ::TT_SW_VIA_BOTTOM_LAYER_MAP {VIA2 M2 VIA3 M3 VIA4 M4 VIA5 M5}
}
proc ::TT_SW_VIA_M5::stack_metal {area net metal_layer} {
    set rects {};set hits {};set incomplete false
    dict for {cut bottom_metal} $::TT_SW_VIA_BOTTOM_LAYER_MAP {
        if {$bottom_metal ne $metal_layer} continue
        if {[catch {get_obj_in_area -area $area -obj_type special_via -layers [list $cut]} vias]} {
            set incomplete true;continue
        }
        foreach via $vias {
            if {[catch {get_db $via .via_def.cut_layer.name} actual] || $actual eq {}} {set incomplete true;continue}
            if {$actual ne $cut} continue
            if {[catch {get_db $via .net.name} actual_net] || $actual_net eq {}} {set incomplete true;continue}
            if {$actual_net ne $net} continue
            if {[catch {get_db $via .bottom_rects} raw]} {set incomplete true;continue}
            set pieces [::TT_SW_VIA_M5::rects $raw]
            if {![llength $pieces]} {set incomplete true;continue}
            lappend rects {*}$pieces;lappend hits $via
        }
    }
    return [dict create rects $rects objects $hits incomplete $incomplete]
}
proc TT_SW_VIA_M5_check {{instances {}} {via_layer VIA4} {metal_layer M5}} {
    if {$via_layer eq "VIA3" && $metal_layer eq "M4"} {::TT_SW_VIA_M5::reset_m4_path_cache}
    set instances [::TT_SW_VIA_M5::resolve_switches $instances]
    set vias [dict create]
    foreach inst $instances {
        set name [get_db $inst .name]
        set boxes [::TT_SW_VIA_M5::rects [get_db $inst .bbox]]
        if {![llength $boxes]} {error "Power switch has no usable bbox: $name"}
        foreach box $boxes {
            foreach via [get_obj_in_area -area $box -obj_type special_via -layers [list $via_layer]] {
                dict lappend vias $via $name
            }
        }
    }
    set basename TT_switch_via_metal_check.tsv
    if {$via_layer ne "VIA4" || $metal_layer ne "M5"} {
        regsub -all {[^[:alnum:]_]} "${via_layer}_${metal_layer}" _ suffix
        set basename "TT_switch_${suffix}_check.tsv"
    }
    set report [tech_mv_output_path report $basename 02 sw_m4]
    set counts [dict create COVERED 0 PARTIAL 0 NO_CONTACT 0 UNKNOWN 0]
    set rows {};set missing_tops 0
    set layer_issues [dict create PARTIAL {} NO_CONTACT {} UNKNOWN {} PATH_NO_ROUTE {}]
    set m4_paths [dict create CONNECTED 0 NO_PATH_FOUND 0 UNKNOWN 0]
    set path_index 0;set path_started [clock milliseconds]
    if {$via_layer eq "VIA3" && $metal_layer eq "M4"} {puts "INFO: Tracing [dict size $vias] VIA3-to-M5 paths; direct exits are checked first."}
    dict for {via owners} $vias {
        set net [get_db $via .net.name]
        set tops {}
        catch {set tops [::TT_SW_VIA_M5::rects [get_db $via .top_rects]]}
        set status UNKNOWN;set metal {};set query_failed false
        if {[llength $tops] && $net ne {} && $net ni {NULL null 0x0}} {
            foreach top $tops {
                foreach kind {special_wire wire patch_wire} {
                    if {[catch {get_obj_in_area -area $top -obj_type $kind -layers [list $metal_layer]} objects]} {
                        set query_failed true;continue
                    }
                    foreach obj $objects {
                        if {[catch {get_db $obj .net.name} objnet] || $objnet eq {}} {set query_failed true;continue}
                        if {$objnet ne $net} continue
                        if {[catch {get_db $obj .rect} raw]} {set query_failed true;continue}
                        set rects [::TT_SW_VIA_M5::rects $raw]
                        if {![llength $rects]} {set query_failed true;continue}
                        lappend metal {*}$rects
                    }
                }
            }
            if {[::TT_SW_VIA_M5::classify $tops $metal] ne "COVERED"} {
                foreach top $tops {
                    set extra [::TT_SW_VIA_M5::stack_metal $top $net $metal_layer]
                    lappend metal {*}[dict get $extra rects]
                    if {[dict get $extra incomplete]} {set query_failed true}
                }
            }
            set status [::TT_SW_VIA_M5::classify $tops $metal]
            if {$status ne "COVERED" && $query_failed} {set status UNKNOWN}
        } else {incr missing_tops}
        set m4_path NOT_APPLICABLE;set exit_via {}
        set issue $status
        if {$via_layer eq "VIA3" && $metal_layer eq "M4"} {
            set traced [::TT_SW_VIA_M5::m4_to_m5 $tops $net]
            set m4_path [dict get $traced status];set exit_via [dict get $traced exit_via]
            dict incr m4_paths $m4_path
            incr path_index
            if {$path_index % 100 == 0 || $path_index == [dict size $vias]} {
                puts "INFO: M4 path progress $path_index/[dict size $vias]; elapsed_ms=[expr {[clock milliseconds]-$path_started}]; $m4_paths"
            }
            set issue COVERED
            if {$m4_path eq "NO_PATH_FOUND"} {set issue PATH_NO_ROUTE}
            if {$m4_path eq "UNKNOWN"} {set issue UNKNOWN}
        }
        dict incr counts $status
        if {$issue ne "COVERED"} {
            foreach owner [lsort -unique $owners] {dict lappend layer_issues $issue $owner}
        }
        lappend rows [list $status $via [lsort -unique $owners] $net $query_failed $m4_path $exit_via]
    }
    if {$via_layer eq "VIA3" && $metal_layer eq "M4"} {puts "INFO: M4 path native-query/cache statistics: $::TT_SW_VIA_M5::path_stats"}
    set ::TT_SW_VIA_M5::layer_issues($via_layer) $layer_issues
    set f [open $report w]
    puts $f "status\tvia\tswitches\tnet\tquery_incomplete\tm4_path_to_m5\texit_via"
    foreach row $rows {puts $f [join $row \t]}
    close $f
    puts "SW VIA/METAL CHECK: switches=[llength $instances] vias=[dict size $vias] via_layer=$via_layer metal_layer=$metal_layer"
    puts "Counts: $counts"
    puts "Report: $report"
    puts "COVERED means same-net metal covers the via top rectangles; it is not full PG connectivity/DRC signoff."
    puts "PARTIAL means some contact exists but full coverage is unproven; UNKNOWN is not PASS."
    if {![dict size $vias]} {puts "WARNING: No target vias found; this is not a PASS."}
    return [dict create switches [llength $instances] vias [dict size $vias] counts $counts m4_path_counts $m4_paths report $report]
}

# Native attributes are optional across Innovus versions. A negative area-query
# result is not proof that a GUI-selected via is on another layer.
proc ::TT_SW_VIA_M5::selected_layer {via expected tops} {
    set evidence [dict create];set known {}
    # Confirmed on the user's Innovus version. Do not probe unsupported
    # special_via .cut_layer/.layer attributes: catch does not silence them.
    if {![catch {get_db $via .via_def.cut_layer.name} value] && $value ne {}} {
        dict set evidence .via_def.cut_layer.name $value
        lappend known {*}$value
    }
    if {[llength $known]} {
        foreach layer $known {
            if {[string equal -nocase $layer $expected]} {return [dict create state MATCH evidence $evidence]}
        }
        return [dict create state MISMATCH evidence $evidence]
    }
    set areas $tops
    catch {set areas [concat [::TT_SW_VIA_M5::rects [get_db $via .cut_rects]] $areas]}
    foreach area $areas {
        if {![catch {get_obj_in_area -area $area -obj_type special_via -layers [list $expected]} objects] &&
            [lsearch -exact $objects $via] >= 0} {
            return [dict create state MATCH evidence $evidence]
        }
    }
    return [dict create state UNKNOWN evidence $evidence]
}

# Inspect selected special vias only. Reports geometric evidence, not PG signoff.
proc TT_SW_VIA_M5_selected {{via_layer AUTO} {metal_layer AUTO}} {
    ::TT_SW_VIA_M5::reset_m4_path_cache
    set requested_via $via_layer;set requested_metal $metal_layer
    set rows {};set examined 0
    foreach via [lsort -unique [get_db selected]] {
        if {[catch {get_db $via .obj_type} kind] || $kind ne "special_via"} {continue}
        set net {};set tops {};set incomplete false
        catch {set net [get_db $via .net.name]}
        catch {set tops [::TT_SW_VIA_M5::rects [get_db $via .top_rects]]}
        set via_layer $requested_via;set metal_layer $requested_metal
        if {$via_layer eq "AUTO"} {
            set native_cut {}
            catch {set native_cut [get_db $via .via_def.cut_layer.name]}
            if {[llength $native_cut] == 1 && [dict exists $::TT_SW_VIA_LAYER_MAP $native_cut]} {
                set via_layer $native_cut
            }
        }
        if {$metal_layer eq "AUTO" && [dict exists $::TT_SW_VIA_LAYER_MAP $via_layer]} {
            set metal_layer [dict get $::TT_SW_VIA_LAYER_MAP $via_layer]
        }
        set metal {};set hits {}
        if {$via_layer eq "AUTO" || $metal_layer eq "AUTO"} {
            set layer_result [dict create state UNKNOWN evidence {}]
        } else {
            set layer_result [::TT_SW_VIA_M5::selected_layer $via $via_layer $tops]
        }
        set layer_state [dict get $layer_result state]
        set target [expr {$layer_state eq "MATCH"}]
        incr examined
        set contact UNKNOWN;set coverage UNKNOWN
        if {$target && $net ne {} && $net ni {NULL null 0x0}} {
            foreach top $tops {
                foreach objtype {special_wire wire patch_wire} {
                    if {[catch {get_obj_in_area -area $top -obj_type $objtype -layers [list $metal_layer]} objects]} {
                        set incomplete true;continue
                    }
                    foreach obj $objects {
                        if {[catch {get_db $obj .net.name} objnet] || $objnet eq {}} {set incomplete true;continue}
                        if {$objnet ne $net} continue
                        if {[catch {get_db $obj .rect} raw]} {set incomplete true;continue}
                        set rects [::TT_SW_VIA_M5::rects $raw]
                        if {![llength $rects]} {set incomplete true;continue}
                        if {[::TT_SW_VIA_M5::classify $tops $rects] ne "NO_CONTACT"} {lappend hits $obj}
                        lappend metal {*}$rects
                    }
                }
            }
            if {[::TT_SW_VIA_M5::classify $tops $metal] ne "COVERED"} {
                foreach top $tops {
                    set extra [::TT_SW_VIA_M5::stack_metal $top $net $metal_layer]
                    lappend metal {*}[dict get $extra rects]
                    lappend hits {*}[dict get $extra objects]
                    if {[dict get $extra incomplete]} {set incomplete true}
                }
            }
            set coverage [::TT_SW_VIA_M5::classify $tops $metal]
            if {$coverage in {COVERED PARTIAL}} {set contact YES}
            if {$coverage eq "NO_CONTACT" && !$incomplete} {set contact NO}
            if {$coverage ne "COVERED" && $incomplete} {set coverage UNKNOWN}
        } elseif {$layer_state eq "MISMATCH"} {
            set contact NOT_APPLICABLE
            set coverage NOT_APPLICABLE
        } else {set incomplete true}
        set m4_path NOT_APPLICABLE;set exit_via {}
        if {$via_layer eq "VIA3" && $metal_layer eq "M4" && $target} {
            set traced [::TT_SW_VIA_M5::m4_to_m5 $tops $net]
            set m4_path [dict get $traced status];set exit_via [dict get $traced exit_via]
        }
        puts "VIA: $via"
        if {$m4_path ne "NOT_APPLICABLE"} {puts "Same-net M4 route -> VIA4 -> M5: $m4_path; exit via: $exit_via"}
        puts "Requested cut layer: $via_layer; layer validation: $layer_state"
        puts "Native layer attributes: [dict get $layer_result evidence]"
        if {$layer_state eq "UNKNOWN"} {puts "WARNING: Selection was read, but the cut layer could not be confirmed. This is not a missing selection."}
        if {$layer_state eq "MISMATCH"} {puts "WARNING: Native cut-layer data identifies a different layer; Requested upper-metal contact is not asserted."}
        puts "Same-net $metal_layer positive-area contact: $contact"
        puts "Via-top coverage: $coverage"
        puts "Query incomplete: $incomplete"
        puts "Matching metal objects: [lsort -unique $hits]"
        lappend rows [dict create via $via net $net contact $contact coverage $coverage query_incomplete $incomplete via_layer $via_layer metal_layer $metal_layer m4_path $m4_path exit_via $exit_via layer_state $layer_state layer_evidence [dict get $layer_result evidence] metal_objects [lsort -unique $hits]]
    }
    if {!$examined} {
        puts "WARNING: Select a special_via in the GUI, then run TT_SW_VIA_check_selected. No result is PASS."
        return [dict create status NO_TARGET selected_vias 0 results {}]
    }
    set report [tech_mv_output_path report TT_selected_via_metal_check.tsv 02 sw_m4]
    set f [open $report w]
    puts $f "via\tnet\tpositive_area_contact\tcoverage\tquery_incomplete\tmetal_objects\tlayer_state\tlayer_evidence\tcut_layer\tupper_metal\tm4_path_to_m5\texit_via"
    foreach row $rows {
        puts $f [join [list [dict get $row via] [dict get $row net] [dict get $row contact] [dict get $row coverage] [dict get $row query_incomplete] [dict get $row metal_objects] [dict get $row layer_state] [dict get $row layer_evidence] [dict get $row via_layer] [dict get $row metal_layer] [dict get $row m4_path] [dict get $row exit_via]] \t]
    }
    close $f
    set selected_counts [dict create COVERED 0 PARTIAL 0 NO_CONTACT 0 UNKNOWN 0 NOT_APPLICABLE 0]
    foreach row $rows {dict incr selected_counts [dict get $row coverage]}
    puts "SELECTED VIA SUMMARY: selected=$examined $selected_counts"
    puts "Report: $report"
    puts "YES proves local same-net overlap only; PARTIAL is not full enclosure. NO means no positive-area contact found, not full rail-disconnect signoff."
    return [dict create status INSPECTED selected_vias $examined results $rows report $report]
}

# Generic entry points; legacy VIA4/M5 command names remain callable.
proc TT_SW_VIA_check_selected {} {
    return [TT_SW_VIA_M5_selected AUTO AUTO]
}
# Each public highlight batch clears previous GUI highlights once.
proc ::TT_SW_VIA_M5::clear_highlights {} {
    gui_clear_highlight -all
}
proc ::TT_SW_VIA_M5::highlight_switches {names index} {
    set marked 0;set failed 0
    foreach name [lsort -unique $names] {
        if {[catch {get_db insts $name} objects] || [llength $objects] != 1} {incr failed;continue}
        set ok false
        if {[llength [info commands gui_highlight]]} {
            if {![catch {gui_highlight -index $index [lindex $objects 0]}]} {set ok true}
        }
        if {!$ok && [llength [info commands select_obj]]} {
            if {![catch {select_obj [lindex $objects 0]}]} {set ok true}
        }
        if {$ok} {incr marked} else {incr failed}
    }
    return [dict create marked $marked failed $failed]
}
proc TT_SW_VIA_check {{instances {}}} {
    ::TT_SW_VIA_M5::clear_highlights
    unset -nocomplain ::TT_SW_VIA_LAST_SUMMARY
    set results [dict create];set by_status [dict create PARTIAL {} NO_CONTACT {} UNKNOWN {} PATH_NO_ROUTE {}]
    set counts [dict create COVERED 0 PARTIAL 0 NO_CONTACT 0 UNKNOWN 0]
    set missing_layers {};set switches 0
    dict for {cut metal} $::TT_SW_VIA_LAYER_MAP {
        set result [TT_SW_VIA_M5_check $instances $cut $metal]
        dict set results $cut $result
        set switches [dict get $result switches]
        if {![dict get $result vias]} {lappend missing_layers $cut}
        dict for {status number} [dict get $result counts] {dict incr counts $status $number}
        dict for {status owners} $::TT_SW_VIA_M5::layer_issues($cut) {
            dict set by_status $status [lsort -unique [concat [dict get $by_status $status] $owners]]
        }
    }
    set issues [lsort -unique [concat [dict get $by_status PARTIAL] [dict get $by_status NO_CONTACT] [dict get $by_status PATH_NO_ROUTE]]]
    set unknown [dict get $by_status UNKNOWN];set unknown_only {}
    foreach name $unknown {if {[lsearch -exact $issues $name] < 0} {lappend unknown_only $name}}
    set bad_gui [::TT_SW_VIA_M5::highlight_switches $issues 1]
    set unknown_gui [::TT_SW_VIA_M5::highlight_switches $unknown_only 2]
    set summary_file [tech_mv_output_path report TT_switch_via_stack_summary.rpt 02 sw_m4]
    set sw_file [tech_mv_output_path report TT_switch_via_problem_switches.tsv 02 sw_m4]
    set f [open $sw_file w];puts $f "status\tswitch"
    dict for {status owners} $by_status {foreach name $owners {puts $f "$status\t$name"}}
    close $f
    set text "SW VIA STACK SUMMARY\n"
    append text "Switches checked: $switches\n"
    append text [format "%-8s %-8s %10s %10s %10s %10s\n" CUT METAL COVERED PARTIAL NO_CONTACT UNKNOWN]
    dict for {cut result} $results {
        set c [dict get $result counts];set metal [dict get $::TT_SW_VIA_LAYER_MAP $cut]
        append text [format "%-8s %-8s %10d %10d %10d %10d\n" $cut $metal [dict get $c COVERED] [dict get $c PARTIAL] [dict get $c NO_CONTACT] [dict get $c UNKNOWN]]
    }
    if {[dict exists $results VIA3 m4_path_counts]} {
        append text "VIA3 -> same-net M4 routing -> VIA4 -> M5: [dict get $results VIA3 m4_path_counts]\n"
    }
    append text "VIA3/M4 local coverage is advisory when an M4-to-M5 path is proven.\n"
    append text "Via totals (local coverage): $counts\n"
    append text "Issue SW (non-M4 coverage issues or M4 path not found, unique): [llength $issues]\n"
    append text "Unknown SW (unique, may overlap issues): [llength $unknown]\n"
    append text "Issue highlight index 1: $bad_gui\nUnknown-only highlight index 2: $unknown_gui\n"
    append text "Layers without target vias (not PASS): $missing_layers\n"
    append text "Previous GUI highlights cleared; this summary reflects the current run.\n"
    append text "Local coverage only; PARTIAL is not proven floating, UNKNOWN is not PASS.\n"
    append text "Switch list: $sw_file\nSummary report: $summary_file\n"
    set f [open $summary_file w];puts -nonewline $f $text;close $f
    set ::TT_SW_VIA_LAST_SUMMARY [dict create switches $switches counts $counts issue_switches $issues unknown_switches $unknown highlight $bad_gui unknown_highlight $unknown_gui missing_layers $missing_layers report $summary_file switch_report $sw_file]
    puts "\n======================================================================"
    puts -nonewline $text
    puts "======================================================================"
    set ::TT_SW_VIA_LAST_RESULTS $results
    return $results
}

# Manual diagnostic graph walk; no geometry/routing edits.
if {![info exists ::TT_SW_M4_PATH_MAX_RECTS]} {set ::TT_SW_M4_PATH_MAX_RECTS 10000}
proc ::TT_SW_VIA_M5::connected_rect {a b} {
    lassign $a x1 y1 x2 y2;lassign $b u1 v1 u2 v2
    set dx [expr {min($x2,$u2)-max($x1,$u1)}]
    set dy [expr {min($y2,$v2)-max($y1,$v1)}]
    return [expr {($dx > 0 && $dy >= 0) || ($dx >= 0 && $dy > 0)}]
}
proc ::TT_SW_VIA_M5::m5_exit {via net} {
    variable m5_exit_cache
    if {[info exists m5_exit_cache($via)]} {return $m5_exit_cache($via)}
    set tops {};set metal {};set incomplete false
    catch {set tops [::TT_SW_VIA_M5::rects [::TT_SW_VIA_M5::cached_db $via .top_rects]]}
    if {[llength $tops] != 1} {return UNKNOWN}
    foreach top $tops {
        foreach kind {special_wire wire patch_wire} {
            if {[catch {::TT_SW_VIA_M5::cached_area $top $kind M5} objects]} {set incomplete true;continue}
            foreach obj $objects {
                if {[catch {::TT_SW_VIA_M5::cached_db $obj .net.name} n] || $n eq {}} {set incomplete true;continue}
                if {$n ne $net} continue
                if {[catch {::TT_SW_VIA_M5::cached_db $obj .rect} raw]} {set incomplete true;continue}
                set r [::TT_SW_VIA_M5::rects $raw]
                if {![llength $r]} {set incomplete true;continue}
                lappend metal {*}$r
            }
        }
        set extra [::TT_SW_VIA_M5::stack_metal $top $net M5]
        lappend metal {*}[dict get $extra rects]
        if {[dict get $extra incomplete]} {set incomplete true}
    }
    set coverage [::TT_SW_VIA_M5::classify $tops $metal]
    if {$coverage in {COVERED PARTIAL}} {
        set result CONNECTED
    } else {
        set result NO_PATH_FOUND
        foreach a $tops {foreach b $metal {if {[::TT_SW_VIA_M5::connected_rect $a $b]} {set incomplete true}}}
        if {$incomplete} {set result UNKNOWN}
    }
    set m5_exit_cache($via) $result
    return $result
}
# Cache native reads only during one bounded diagnostic run.
proc ::TT_SW_VIA_M5::cached_db {obj attr} {
    variable path_db_cache;variable path_stats
    set key [list $obj $attr]
    if {![info exists path_db_cache($key)]} {
        dict incr path_stats db_reads
        set code [catch {get_db $obj $attr} value options]
        set path_db_cache($key) [list $code $value $options]
    } else {dict incr path_stats db_cache_hits}
    lassign $path_db_cache($key) code value options
    return -options $options $value
}
proc ::TT_SW_VIA_M5::cached_area {area kind layer} {
    variable path_area_cache;variable path_stats
    set key [list $area $kind $layer]
    if {![info exists path_area_cache($key)]} {
        dict incr path_stats area_queries
        set code [catch {get_obj_in_area -area $area -obj_type $kind -layers $layer} value options]
        set path_area_cache($key) [list $code $value $options]
    } else {dict incr path_stats area_cache_hits}
    lassign $path_area_cache($key) code value options
    return -options $options $value
}
proc ::TT_SW_VIA_M5::m4_component {seed net} {
    variable m4_rect_results;variable path_stats
    set seedkey [list $net $seed]
    if {[info exists m4_rect_results($seedkey)]} {
        dict incr path_stats rect_cache_hits
        return $m4_rect_results($seedkey)
    }
    set queue [list $seed];set seen [dict create $seed 1];set cursor 0
    set incomplete false;set exit {};set status NO_PATH_FOUND
    while {$cursor < [llength $queue]} {
        if {[llength $queue] > $::TT_SW_M4_PATH_MAX_RECTS} {set incomplete true;break}
        set area [lindex $queue $cursor];incr cursor
        dict incr path_stats rectangles
        set key [list $net $area]
        if {[info exists m4_rect_results($key)]} {
            dict incr path_stats rect_cache_hits
            set cached $m4_rect_results($key)
            if {[dict get $cached status] eq "CONNECTED"} {
                set status CONNECTED;set exit [dict get $cached exit_via];break
            }
        }
        if {$cursor % 500 == 0} {puts "INFO: M4 route search expanded=$cursor queued=[llength $queue] (bounded search)."}
        # Check nearby exits first. Most switches have a direct via stack.
        foreach cut {VIA4 VIA3} {
            if {[catch {::TT_SW_VIA_M5::cached_area $area special_via $cut} objects]} {set incomplete true;continue}
            foreach obj $objects {
                if {[catch {::TT_SW_VIA_M5::cached_db $obj .net.name} n] || $n eq {}} {set incomplete true;continue}
                if {$n ne $net} continue
                if {[catch {::TT_SW_VIA_M5::cached_db $obj .via_def.cut_layer.name} actual] || $actual ne $cut} {set incomplete true;continue}
                set attr .top_rects
                if {$cut eq "VIA4"} {set attr .bottom_rects}
                if {[catch {::TT_SW_VIA_M5::cached_db $obj $attr} raw]} {set incomplete true;continue}
                set pieces [::TT_SW_VIA_M5::rects $raw]
                if {![llength $pieces]} {set incomplete true;continue}
                foreach r $pieces {
                    if {![::TT_SW_VIA_M5::connected_rect $area $r]} continue
                    if {![dict exists $seen $r]} {dict set seen $r 1;lappend queue $r}
                    if {$cut eq "VIA4"} {
                        if {[llength $pieces] != 1} {set incomplete true;continue}
                        set upper [::TT_SW_VIA_M5::m5_exit $obj $net]
                        if {$upper eq "CONNECTED"} {set exit $obj;set status CONNECTED;break}
                        if {$upper eq "UNKNOWN"} {set incomplete true}
                    }
                }
                if {$status eq "CONNECTED"} break
            }
            if {$status eq "CONNECTED"} break
        }
        if {$status eq "CONNECTED"} break
        foreach kind {special_wire wire patch_wire} {
            if {[catch {::TT_SW_VIA_M5::cached_area $area $kind M4} objects]} {set incomplete true;continue}
            foreach obj $objects {
                if {[catch {::TT_SW_VIA_M5::cached_db $obj .net.name} n] || $n eq {}} {set incomplete true;continue}
                if {$n ne $net} continue
                if {[catch {::TT_SW_VIA_M5::cached_db $obj .rect} raw]} {set incomplete true;continue}
                set pieces [::TT_SW_VIA_M5::rects $raw]
                if {![llength $pieces]} {set incomplete true;continue}
                foreach r $pieces {
                    if {![::TT_SW_VIA_M5::connected_rect $area $r]} continue
                    set rkey [list $net $r]
                    if {[info exists m4_rect_results($rkey)] && [dict get $m4_rect_results($rkey) status] eq "CONNECTED"} {
                        dict incr path_stats rect_cache_hits
                        set status CONNECTED;set exit [dict get $m4_rect_results($rkey) exit_via];break
                    }
                    if {![dict exists $seen $r]} {dict set seen $r 1;lappend queue $r}
                }
                if {$status eq "CONNECTED"} break
            }
            if {$status eq "CONNECTED"} break
        }
        if {$status eq "CONNECTED"} break
    }
    if {$status ne "CONNECTED" && $incomplete} {set status UNKNOWN}
    set result [dict create status $status exit_via $exit boxes $queue]
    # Exact-seed cache is conservative even for incomplete searches. Only
    # definitive connected/closed searches propagate to visited rectangles.
    set m4_rect_results($seedkey) $result
    if {$status ne "UNKNOWN"} {
        foreach area $queue {set m4_rect_results([list $net $area]) $result}
    }
    return $result
}
proc ::TT_SW_VIA_M5::m4_to_m5 {tops net} {
    if {![llength $tops] || $net eq {} || $net in {NULL null 0x0}} {
        return [dict create status UNKNOWN exit_via {}]
    }
    set status CONNECTED;set exits {}
    foreach top $tops {
        set result [::TT_SW_VIA_M5::m4_component $top $net]
        if {[dict get $result status] eq "NO_PATH_FOUND"} {set status NO_PATH_FOUND}
        if {[dict get $result status] eq "UNKNOWN" && $status ne "NO_PATH_FOUND"} {set status UNKNOWN}
        if {[dict get $result exit_via] ne {}} {lappend exits [dict get $result exit_via]}
    }
    return [dict create status $status exit_via [lsort -unique $exits]]
}
proc ::TT_SW_VIA_M5::reset_m4_path_cache {} {
    variable m4_components;variable m5_exit_cache
    variable m4_rect_results;variable path_db_cache;variable path_area_cache;variable path_stats
    unset -nocomplain m4_components m5_exit_cache m4_rect_results path_db_cache path_area_cache
    set path_stats [dict create db_reads 0 db_cache_hits 0 area_queries 0 area_cache_hits 0 rectangles 0 rect_cache_hits 0]
}

# Native whole-net check: lateral rail routing must not be clipped by a bbox.
# Native diagnostic limit is explicitly raised using the installed command option.
proc TT_SW_power_vias_check {{layer_range {M1 M5}} {instances {}}} {
    if {[llength $layer_range] != 2} {error "Usage: TT_SW_power_vias_check ?{bottom_layer top_layer}? ?switch_names?"}
    if {![llength [info commands check_power_vias]]} {error "check_power_vias is unavailable."}
    set switches [::TT_SW_VIA_M5::resolve_switches $instances]
    if {![llength $switches]} {
        puts "WARNING: No power switches found. No check was performed."
        return [dict create status NO_TARGET switches 0]
    }
    # Resolve and deduplicate full PG nets before invoking native checks.
    set net_switches [dict create];set unconnected 0
    foreach sw $switches {
        set pins [get_db $sw .pg_pins]
        if {![llength $pins]} {error "Power switch has no PG pins; discovery is incomplete."}
        set nets {}
        foreach pin $pins {
            set valid 0
            foreach name [get_db $pin .net.name] {
                if {$name in {{} 0x0 NULL null}} continue
                lappend nets $name;set valid 1
            }
            if {!$valid} {incr unconnected}
        }
        set nets [lsort -unique $nets]
        if {![llength $nets]} {error "Power switch has no connected PG net; check was not performed."}
        foreach net $nets {dict lappend net_switches $net [get_db $sw .name]}
    }
    set base [tech_mv_output_path report TT_switch_native_power_vias.rpt 02 sw_m4]
    set dir [file join [file dirname $base] native_power_vias [clock microseconds]]
    while {[file exists $dir]} {append dir _}
    file mkdir $dir
    set manifest [file join $dir scopes.list]
    set out [open $manifest w]
    set completed 0
    set net_count [dict size $net_switches]
    puts "SW FULL-NET POWER-VIA CHECK: switches=[llength $switches] nets=$net_count layers=$layer_range"
    puts "Scope: complete SW PG nets, including lateral rails and other loads on shared nets; no area filter."
    puts "Native error reporting limit: 1000000 per net (finite, not unlimited)."
    puts "Reports: $dir"
    if {$unconnected} {puts "WARNING: $unconnected PG pins have no connected net and are not checked."}
    try {
        foreach net [lsort [dict keys $net_switches]] {
            set report [file join $dir [format "net_%06d.rpt" [expr {$completed+1}]]]
            puts $out [list START net $net switches [lsort -unique [dict get $net_switches $net]] report $report]
            flush $out
            check_power_vias -nets [list $net] -layer_range $layer_range -check_wire_pin_overlap -error 1000000 -report $report
            if {![file exists $report] || [file size $report] == 0} {
                error "Native check did not produce a non-empty report; no PASS is asserted."
            }
            incr completed
            puts $out [list REPORT_READY report $report]
            flush $out
            puts "SW full-net check progress: $completed/$net_count nets"
        }
    } finally {
        close $out
    }
    puts "SW FULL-NET CHECK SUMMARY: switches=[llength $switches] nets_checked=$completed unconnected_pg_pins=$unconnected"
    puts "Inspect reports for violations and native truncation messages. Completion is not PASS."
    return [dict create status REPORT_READY switches [llength $switches] nets_checked $completed nets [lsort [dict keys $net_switches]] unconnected_pg_pins $unconnected report_dir $dir manifest $manifest]
}

# Manual SW-local seed discovery followed by unrestricted M1-M5 geometry tracing.
namespace eval ::TT_SW_PG {}
proc ::TT_SW_PG::rects {value} {
    if {[llength $value] == 4} {
        set numeric 1
        foreach v $value {if {![string is double -strict $v]} {set numeric 0;break}}
        if {$numeric} {
            lassign $value x1 y1 x2 y2
            if {$x2 <= $x1 || $y2 <= $y1} {error "Invalid rectangle"}
            return [list $value]
        }
    }
    set result {}
    foreach v $value {
        if {$v eq $value} {error "Unsupported rectangle data"}
        lappend result {*}[::TT_SW_PG::rects $v]
    }
    return $result
}
proc ::TT_SW_PG::touch {a b} {
    lassign $a x1 y1 x2 y2
    lassign $b u1 v1 u2 v2
    set dx [expr {min($x2,$u2)-max($x1,$u1)}]
    set dy [expr {min($y2,$v2)-max($y1,$v1)}]
    # Positive area or shared edge with positive length; no corner-only links.
    return [expr {$dx>=0 && $dy>=0 && ($dx>0 || $dy>0)}]
}
proc ::TT_SW_PG::overlap {a b} {
    lassign $a x1 y1 x2 y2
    lassign $b u1 v1 u2 v2
    return [expr {min($x2,$u2)>max($x1,$u1) && min($y2,$v2)>max($y1,$v1)}]
}
proc ::TT_SW_PG::wire_rects {obj} {
    set kind [::TT_SW_PG::native_db $obj .obj_type]
    if {$kind eq "wire"} {
        # Regular wire has no .polygon. Confirm orthogonal centerline first;
        # .rect includes the native begin/end extensions.
        set points [::TT_SW_PG::native_db $obj .points]
        if {[llength $points]==2 && [llength [lindex $points 0]]==2 && [llength [lindex $points 1]]==2} {
            set points [concat {*}$points]
        }
        if {[llength $points]!=4} {error "Unsupported regular-wire centerline"}
        foreach coordinate $points {
            if {![string is double -strict $coordinate]} {error "Non-numeric regular-wire centerline"}
        }
        lassign $points x1 y1 x2 y2
        if {$x1!=$x2 && $y1!=$y2} {error "Non-orthogonal regular wire requires exact polygon geometry"}
        set rects [::TT_SW_PG::rects [::TT_SW_PG::native_db $obj .rect]]
        if {![llength $rects]} {error "Regular-wire rectangle unavailable"}
        return $rects
    }
    if {$kind eq "patch_wire"} {
        set rects [::TT_SW_PG::rects [::TT_SW_PG::native_db $obj .rect]]
        if {![llength $rects]} {error "Patch-wire rectangle unavailable"}
        return $rects
    }
    if {$kind ne "special_wire"} {error "Expected a routing wire object"}
    set polygon [::TT_SW_PG::native_db $obj .polygon]
    if {$polygon eq {}} {error "Wire polygon unavailable"}
    set rects [::TT_SW_PG::rects [get_computed_shapes -output rect $polygon]]
    if {![llength $rects]} {error "Empty decomposition"}
    # Refuse a lossy decomposition, including unsupported non-orthogonal shapes.
    if {[get_computed_shapes -output area $polygon XOR $rects] != 0} {
        error "Wire decomposition does not preserve geometry"
    }
    return $rects
}
proc ::TT_SW_PG::via_geometry {via} {
    set bottom_layer [::TT_SW_PG::native_db $via .via_def.bottom_layer.name]
    set top_layer [::TT_SW_PG::native_db $via .via_def.top_layer.name]
    set bottom [::TT_SW_PG::rects [::TT_SW_PG::native_db $via .bottom_rects]]
    set top [::TT_SW_PG::rects [::TT_SW_PG::native_db $via .top_rects]]
    if {$bottom_layer eq {} || $top_layer eq {} || ![llength $bottom] || ![llength $top]} {
        error "Incomplete via geometry"
    }
    return [dict create bottom_layer $bottom_layer top_layer $top_layer bottom $bottom top $top]
}
proc ::TT_SW_PG::trace {net seed max_rects} {
    set queue [list $seed];set seen [dict create $seed 1];set parent [dict create]
    set cache [dict create];set failures 0;set capped 0;set target {};set i 0;set suffix {}
    for {} {$i<[llength $queue]} {incr i} {
        if {$i >= $max_rects} {set capped 1;break}
        set current [lindex $queue $i];lassign $current layer area
        if {[info exists ::TT_SW_PG::cache_active] && $::TT_SW_PG::cache_active &&
            [info exists ::TT_SW_PG::proof_cache([list $net $current])]} {
            set suffix $::TT_SW_PG::proof_cache([list $net $current])
            dict incr ::TT_SW_PG::cache_stats proof_hits
            set target $current;break
        }
        if {$layer eq "M5"} {set target $current;break}
        set next_nodes {}
        foreach kind {special_wire wire patch_wire special_via via} {
            if {[catch {::TT_SW_PG::native_area -areas $area -obj_type $kind -layers [list $layer]} objects]} {incr failures;continue}
            foreach candidate $objects {
                if {[catch {
                    if {![dict exists $cache $candidate]} {
                        set cn [::TT_SW_PG::native_db $candidate .net.name]
                        if {$cn ne $net} {
                            dict set cache $candidate [dict create net $cn]
                        } elseif {$kind in {special_via via}} {
                            dict set cache $candidate [dict merge [dict create net $cn] [::TT_SW_PG::via_geometry $candidate]]
                        } else {
                            dict set cache $candidate [dict create net $cn layer [::TT_SW_PG::native_db $candidate .layer.name] rects [::TT_SW_PG::wire_rects $candidate]]
                        }
                    }
                    set data [dict get $cache $candidate]
                    if {[dict get $data net] eq $net} {
                        if {$kind in {special_via via}} {
                            foreach side {bottom top} other {top bottom} {
                                if {[dict get $data ${side}_layer] ne $layer} continue
                                set touched 0
                                foreach rect [dict get $data $side] {
                                    if {[::TT_SW_PG::touch $area $rect]} {
                                        lappend next_nodes [list [list $layer $rect] $candidate];set touched 1
                                    }
                                }
                                # Conservative: do not assume disconnected via
                                # enclosure islands all connect internally.
                                if {$touched} {
                                    if {[llength [dict get $data bottom]]!=1 || [llength [dict get $data top]]!=1} {
                                        incr failures
                                    } else {
                                        set other_layer [dict get $data ${other}_layer]
                                        if {$other_layer in {M1 M2 M3 M4 M5}} {
                                            lappend next_nodes [list [list $other_layer [lindex [dict get $data $other] 0]] $candidate]
                                        }
                                    }
                                }
                            }
                        } elseif {[dict get $data layer] eq $layer} {
                            foreach rect [dict get $data rects] {
                                if {[::TT_SW_PG::touch $area $rect]} {lappend next_nodes [list [list $layer $rect] $candidate]}
                            }
                        }
                    }
                }]} {incr failures}
            }
        }
        foreach item $next_nodes {
            lassign $item node evidence
            if {![dict exists $seen $node]} {
                dict set seen $node 1;dict set parent $node [list $current $evidence];lappend queue $node
            }
        }
    }
    set path {};set status NO_PATH_FOUND
    if {$target ne {}} {
        set status CONNECTED;set node $target
        while {$node ne $seed} {
            lassign [dict get $parent $node] previous evidence
            set path [linsert $path 0 [dict create from $previous to $node object $evidence]]
            set node $previous
        }
    } elseif {$failures || $capped} {set status UNKNOWN}
    if {$status eq "CONNECTED"} {
        if {[llength $suffix]} {set path [concat $path $suffix]}
        if {[llength $path]} {set target [dict get [lindex $path end] to]}
        if {[info exists ::TT_SW_PG::cache_active] && $::TT_SW_PG::cache_active} {
            set tail $path
            foreach step $path {
                set ::TT_SW_PG::proof_cache([list $net [dict get $step from]]) $tail
                set tail [lrange $tail 1 end]
            }
            set ::TT_SW_PG::proof_cache([list $net $target]) {}
        }
    }
    set result [dict create status $status net $net seed $seed target $target path $path \
        nodes_processed $i query_failures $failures search_capped $capped]
    return $result
}
# No routing modification. Bbox is used ONLY to discover SW-associated seeds;
# traversal is not clipped to it. Association is spatial, not pin ownership proof.
proc TT_SW_PG_check {{instances {}} {max_rects 10000}} {
    if {![string is integer -strict $max_rects] || $max_rects<1} {error "max_rects must be positive"}
    set switches [::TT_SW_VIA_M5::resolve_switches $instances]
    ::TT_SW_VIA_M5::clear_highlights
    if {![llength $switches]} {puts "WARNING: No SW found; no check performed.";return [dict create status NO_TARGET]}
    set base [tech_mv_output_path report TT_SW_PG_summary.rpt 02 sw_m4]
    set dir [file join [file dirname $base] sw_pg_stack [clock microseconds]]
    while {[file exists $dir]} {append dir _}
    file mkdir $dir
    set output [open [file join $dir switches.list] w]
    set details [open [file join $dir paths.list] w]
    set counts [dict create FOUND_M5 0 NO_PATH_FOUND 0 UNKNOWN 0 NO_TARGET 0]
    set highlight [dict create marked 0 failed 0]
    set cache [dict create];set index 0;set seed_count 0;set bad {};set uncertain {}
    ::TT_SW_PG::cache_begin
    puts "SW PG STACK CHECK: switches=[llength $switches] node_limit_per_seed=$max_rects"
    puts "Seed: same-PG-net VIA1 bottom metal intersecting SW bbox. Trace: M1-M5, including via enclosures, without bbox clipping."
    puts "Reports: $dir"
    try {
        foreach sw $switches {
            incr index
            set name [get_db $sw .name]
            set failures 0;set seeds [dict create];set nets {};set missing_pins 0
            if {[catch {
                set pins [get_db $sw .pg_pins]
                if {![llength $pins]} {error "No PG pins"}
                foreach pin $pins {
                    set connected 0
                    foreach n [get_db $pin .net.name] {
                        if {$n in {{} NULL null 0x0}} continue
                        lappend nets $n;set connected 1
                    }
                    if {!$connected} {incr missing_pins}
                }
                set nets [lsort -unique $nets]
                if {![llength $nets]} {error "No connected PG nets"}
                set boxes [::TT_SW_PG::rects [get_db $sw .bbox]]
                if {![llength $boxes]} {error "No switch bbox"}
            }]} {incr failures;set boxes {}}
            foreach box $boxes {
                foreach kind {special_via via} {
                    if {[catch {get_obj_in_area -areas $box -obj_type $kind -layers {VIA1}} vias]} {incr failures;continue}
                    foreach via $vias {
                        if {[catch {
                            set cut [get_db $via .via_def.cut_layer.name]
                            set net [get_db $via .net.name]
                            if {$cut eq "VIA1" && $net in $nets} {
                                set bottoms [::TT_SW_PG::rects [get_db $via .bottom_rects]]
                                if {![llength $bottoms]} {error "No VIA1 bottom geometry"}
                                foreach bottom $bottoms {
                                    if {[::TT_SW_PG::overlap $box $bottom]} {dict set seeds [list $net $bottom] $via}
                                }
                            }
                        }]} {incr failures}
                    }
                }
            }
            set local [dict create CONNECTED 0 NO_PATH_FOUND 0 UNKNOWN 0]
            dict for {key via} $seeds {
                lassign $key net bottom
                incr seed_count
                if {![dict exists $cache $key]} {
                    if {[catch {::TT_SW_PG::trace $net [list M1 $bottom] $max_rects} result]} {
                        set result [dict create status UNKNOWN reason NATIVE_QUERY_ERROR]
                    }
                    dict set cache $key $result
                }
                set result [dict get $cache $key]
                dict incr local [dict get $result status]
                puts $details [list switch $name via $via result $result]
            }
            set status FOUND_M5
            if {[dict get $local UNKNOWN] || $failures || $missing_pins} {set status UNKNOWN}
            if {![dict size $seeds] && $status ne "UNKNOWN"} {set status NO_TARGET}
            if {[dict get $local NO_PATH_FOUND]} {set status NO_PATH_FOUND}
            dict incr counts $status
            if {$status eq "NO_PATH_FOUND"} {lappend bad $name}
            if {$status in {UNKNOWN NO_TARGET}} {lappend uncertain $name}
            if {$status ne "FOUND_M5"} {
                set color 2
                if {$status eq "NO_PATH_FOUND"} {set color 1}
                if {[catch {gui_highlight -index $color $sw}]} {dict incr highlight failed} else {dict incr highlight marked}
            }
            puts $output [list switch $name status $status seed_counts $local discovery_failures $failures unconnected_pg_pins $missing_pins]
            flush $output;flush $details
            if {$index%25==0 || $index==[llength $switches]} {puts "SW PG progress: $index/[llength $switches] | $counts"}
        }
    } finally {
        close $output;close $details
        set performance [::TT_SW_PG::cache_end]
    }
    set summary [dict create status COMPLETED switches $index seeds $seed_count seed_cut VIA1 seed_side bottom seed_layer M1 counts $counts performance $performance highlights $highlight target_filter $::TT_SW_VIA_M5::LAST_TARGET_FILTER \
        no_path_switches $bad uncertain_switches $uncertain report_dir $dir]
    set pf [open [file join $dir performance.list] w];puts $pf $performance;close $pf
    set f [open [file join $dir summary.rpt] w]
    puts $f $summary
    puts $f "FOUND_M5 means all discovered VIA1 M1 seed components reached M5 metal (including VIA4 top enclosure)."
    puts $f "Seeds are associated spatially and by SW PG net; switch-pin attachment is not proven. Missing seeds/pins are not PASS."
    puts $f "M5 stripe/source attachment, PG-pin internal metal, routes outside M1-M5 and DRC legality are not checked."
    close $f
    set ::TT_SW_PG_LAST_RESULT $summary
    puts "SW PG SUMMARY: switches=$index seeds=$seed_count | $counts"
    puts "Highlight index 1: NO_PATH_FOUND; index 2: UNKNOWN/NO_TARGET. Highlights reset for this run."
    puts "Highlight result: $highlight"
    puts "FOUND_M5 is geometry evidence for discovered seeds, not full SW PG connectivity signoff."
    puts "Summary: [file join $dir summary.rpt]"
    return $summary
}
proc TT_SW_PG_selected {{max_rects 10000}} {
    set names {}
    foreach obj [get_db selected] {
        if {[get_db $obj .obj_type] ne "inst"} {
            error "Select power-switch instances, not wires or vias"
        }
        lappend names [get_db $obj .name]
    }
    if {![llength $names]} {error "Select at least one power-switch instance"}
    return [TT_SW_PG_check $names $max_rects]
}
# Diagnose missing seeds in a previous batch. Does not alter its classifications.
proc TT_SW_PG_diagnose_no_target {{report_dir {}}} {
    if {$report_dir eq {}} {
        if {![info exists ::TT_SW_PG_LAST_RESULT] || ![dict exists $::TT_SW_PG_LAST_RESULT report_dir]} {
            error "Pass the previous sw_pg_stack run directory or run TT_SW_PG_check first"
        }
        set report_dir [dict get $::TT_SW_PG_LAST_RESULT report_dir]
    }
    set seed_cut VIA3;set seed_side top
    set sf [open [file join $report_dir summary.rpt]]
    try {gets $sf metadata} finally {close $sf}
    if {[dict exists $metadata seed_cut]} {set seed_cut [dict get $metadata seed_cut]}
    if {[dict exists $metadata seed_side]} {set seed_side [dict get $metadata seed_side]}
    if {$seed_cut ni {VIA1 VIA3} || $seed_side ni {bottom top}} {error "Unsupported seed policy in prior report"}
    set f [open [file join $report_dir switches.list]];set names {}
    try {
        while {[gets $f line]>=0} {
            if {[dict get $line status] eq "NO_TARGET"} {lappend names [dict get $line switch]}
        }
    } finally {close $f}
    if {![llength $names]} {puts "No NO_TARGET switches in this report.";return [dict create switches 0]}
    set dir [file join $report_dir no_target_diagnosis_[clock microseconds]]
    while {[file exists $dir]} {append dir _}
    file mkdir $dir
    set f [open [file join $dir details.list] w];set counts {};set index 0
    try {
        foreach name $names {
            set failures 0;set nets {};set geometry {};set boxes {};set missing 0;set excluded_reason {}
            set stats [dict create];set seen [dict create];set candidates [dict create]
            set seed_overlaps 0
            if {[catch {
                set sw [get_db insts $name]
                if {[llength $sw]!=1} {error "Instance no longer resolves uniquely"}
                set excluded_reason [::TT_SW_VIA_M5::target_exclusion $sw [::TT_SW_VIA_M5::switch_prefixes]]
                set boxes [::TT_SW_PG::rects [get_db $sw .bbox]]
                if {![llength $boxes]} {error "No bbox"}
                set pins [get_db $sw .pg_pins]
                if {![llength $pins]} {error "No PG pins"}
                foreach pin $pins {
                    set ns [get_db $pin .net.name];set good 0
                    foreach n $ns {if {$n ni {{} NULL null 0x0}} {lappend nets $n;set good 1}}
                    if {!$good} {incr missing}
                }
                set nets [lsort -unique $nets]
                if {![llength $nets]} {error "No PG nets"}
            }]} {incr failures;set boxes {}}
            if {$excluded_reason ne {}} {set boxes {}}
            foreach box $boxes {
                lassign $box x1 y1 x2 y2
                set width [expr {$x2-$x1}];set height [expr {$y2-$y1}]
                lappend geometry [dict create bbox $box width $width height $height]
                # Diagnostic window grows by one SW width/height, not a process rule.
                set expanded [list [expr {$x1-$width}] [expr {$y1-$height}] [expr {$x2+$width}] [expr {$y2+$height}]]
                foreach scope {local nearby} area [list $box $expanded] {
                    foreach cut {VIA1 VIA2 VIA3 VIA4} {
                        foreach kind {special_via via} {
                            if {[catch {get_obj_in_area -areas $area -obj_type $kind -layers [list $cut]} vias]} {incr failures;continue}
                            foreach via $vias {
                                if {[dict exists $seen [list $scope $cut $via]]} continue
                                dict set seen [list $scope $cut $via] 1
                                if {[catch {
                                    set actual [get_db $via .via_def.cut_layer.name]
                                    set net [get_db $via .net.name]
                                    if {$actual eq $cut} {
                                        dict incr stats ${scope}_${cut}_all
                                        if {$net in $nets} {
                                            dict incr stats ${scope}_${cut}_pg_net
                                            if {$cut eq $seed_cut} {
                                                set metals [::TT_SW_PG::rects [get_db $via .${seed_side}_rects]]
                                                if {![llength $metals]} {error "Missing seed metal"}
                                                dict set candidates $via [dict create net $net side $seed_side metal $metals]
                                                if {$scope eq "local"} {
                                                    foreach metal $metals {
                                                        if {[::TT_SW_PG::overlap $box $metal]} {incr seed_overlaps;break}
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }]} {incr failures}
                            }
                        }
                    }
                }
            }
            foreach key [list local_${seed_cut}_all local_${seed_cut}_pg_net nearby_${seed_cut}_pg_net] {
                if {![dict exists $stats $key]} {dict set stats $key 0}
            }
            set reason NO_${seed_cut}_IN_DIAGNOSTIC_WINDOW
            if {[dict get $stats nearby_${seed_cut}_pg_net]>0} {set reason SAME_NET_${seed_cut}_NEARBY_ONLY}
            if {[dict get $stats local_${seed_cut}_all]>0 && [dict get $stats local_${seed_cut}_pg_net]==0} {set reason LOCAL_${seed_cut}_NET_MISMATCH}
            if {[dict get $stats local_${seed_cut}_pg_net]>0} {set reason ${seed_cut}_${seed_side}_OUTSIDE_SWITCH}
            if {$seed_overlaps>0} {set reason NOW_HAS_${seed_cut}_SEED}
            if {$excluded_reason ne {}} {set reason NOT_A_SWITCH_${excluded_reason}}
            if {$failures || $missing} {set reason QUERY_INCOMPLETE}
            dict incr counts $reason
            puts $f [list switch $name reason $reason geometry $geometry pg_nets $nets counts $stats seed_cut $seed_cut seed_side $seed_side seed_candidates $candidates seed_overlaps $seed_overlaps failures $failures unconnected_pg_pins $missing]
            flush $f;incr index
        }
    } finally {close $f}
    set result [dict create switches $index reasons $counts report_dir $dir]
    set f [open [file join $dir summary.rpt] w];puts $f $result;close $f
    puts "SW NO-TARGET DIAGNOSIS: switches=$index | $counts"
    puts "Nearby window extends by one switch width/height; absence there does not prove no $seed_cut anywhere."
    puts "Report: [file join $dir details.list]"
    return $result
}
proc ::TT_SW_PG::canonical_rects {rectangles} {
    set result {}
    foreach rect [::TT_SW_PG::rects $rectangles] {
        set normalized {}
        foreach coordinate $rect {lappend normalized [format %.17g $coordinate]}
        lappend result $normalized
    }
    return [lsort -unique $result]
}
proc ::TT_SW_PG::via_signature {via} {
    return [list [get_db $via .via_def.cut_layer.name] [get_db $via .net.name] \
        [::TT_SW_PG::canonical_rects [get_db $via .bottom_rects]] \
        [::TT_SW_PG::canonical_rects [get_db $via .top_rects]] \
        [::TT_SW_PG::canonical_rects [get_db $via .cut_rects]]]
}
# Selected-object evidence only. No selection/highlight/routing changes.
proc TT_SW_PG_diagnose_selected_via {{report_dir {}}} {
    set selection [get_db selected]
    if {[llength $selection]!=1} {error "Keep exactly one VIA1 selected"}
    set via [lindex $selection 0];set kind [get_db $via .obj_type]
    if {$kind ni {special_via via shape_via}} {error "Selected object is not a supported via object"}
    set cut [get_db $via .via_def.cut_layer.name]
    set bottom [::TT_SW_PG::rects [get_db $via .bottom_rects]]
    set top [::TT_SW_PG::rects [get_db $via .top_rects]]
    set cuts [::TT_SW_PG::rects [get_db $via .cut_rects]]
    set net {};set net_known 0;set signature {};set signature_cache [dict create]
    # shape_via has no documented .net: never probe an unsupported attribute.
    if {$kind in {special_via via}} {set net [get_db $via .net.name];set net_known 1;set signature [::TT_SW_PG::via_signature $via]}
    if {$report_dir eq {} && [info exists ::TT_SW_PG_LAST_RESULT] && [dict exists $::TT_SW_PG_LAST_RESULT report_dir]} {
        set report_dir [dict get $::TT_SW_PG_LAST_RESULT report_dir]
    }
    set prior [dict create]
    if {$report_dir ne {}} {
        set f [open [file join $report_dir switches.list]]
        try {while {[gets $f l]>=0} {dict set prior [dict get $l switch] [dict get $l status]}} finally {close $f}
    }
    set base [tech_mv_output_path report TT_SW_PG_selected_via.rpt 02 sw_m4]
    set dir [file join [file dirname $base] selected_via_diagnosis [clock microseconds]]
    while {[file exists $dir]} {append dir _}
    file mkdir $dir
    set f [open [file join $dir details.list] w]
    set rows {};set reasons {};set nearest {};set nearest_distance {};set failures 0
    puts "SELECTED VIA DIAGNOSIS: type=$kind cut=$cut"
    puts "Bottom layer: [get_db $via .via_def.bottom_layer.name]; top layer: [get_db $via .via_def.top_layer.name]"
    puts "Bottom metal: $bottom"
    puts "Top metal: $top"
    if {!$net_known} {puts "No .net query for shape_via; routing-via search does not include this object type."}
    try {
        puts $f [list selected $via type $kind cut $cut bottom $bottom top $top cut_rects $cuts net_known $net_known net $net prior_report $report_dir]
        foreach sw [::TT_SW_VIA_M5::resolve_switches] {
            if {[catch {
                set name [get_db $sw .name]
                set boxes [::TT_SW_PG::rects [get_db $sw .bbox]]
                if {![llength $boxes]} {error "Missing bbox"}
            }]} {incr failures;continue}
            set bottom_overlap 0;set top_overlap 0;set cut_overlap 0;set distance {}
            foreach box $boxes {
                lassign $box x1 y1 x2 y2
                foreach r $bottom {
                    if {[::TT_SW_PG::overlap $box $r]} {set bottom_overlap 1}
                    lassign $r u1 v1 u2 v2
                    set dx [expr {max($x1-$u2,$u1-$x2,0)}];set dy [expr {max($y1-$v2,$v1-$y2,0)}]
                    set d [expr {hypot($dx,$dy)}]
                    if {$distance eq {} || $d<$distance} {set distance $d}
                }
                foreach r $top {if {[::TT_SW_PG::overlap $box $r]} {set top_overlap 1}}
                foreach r $cuts {if {[::TT_SW_PG::overlap $box $r]} {set cut_overlap 1}}
            }
            if {$distance ne {} && ($nearest_distance eq {} || $distance<$nearest_distance)} {set nearest $name;set nearest_distance $distance}
            set old NOT_IN_PRIOR_REPORT
            if {[dict exists $prior $name]} {set old [dict get $prior $name]}
            # Include all prior NO_TARGET SWs and every geometrically associated SW.
            if {!$bottom_overlap && !$top_overlap && !$cut_overlap && $old ne "NO_TARGET"} continue
            set pg_nets {};set query_failures 0;set filtered 0;set unfiltered 0
            set equivalent_filtered {};set equivalent_unfiltered {}
            if {[catch {
                foreach pin [get_db $sw .pg_pins] {lappend pg_nets {*}[get_db $pin .net.name]}
                set pg_nets [lsort -unique $pg_nets]
            }]} {incr query_failures}
            if {$kind in {special_via via}} {
                foreach box $boxes {
                    foreach mode {filtered unfiltered} {
                        set command [list get_obj_in_area -areas $box -obj_type $kind]
                        if {$mode eq "filtered"} {lappend command -layers VIA1}
                        if {[catch {{*}$command} objects]} {incr query_failures;continue}
                        if {[lsearch -exact $objects $via]>=0} {set $mode 1}
                        foreach candidate $objects {
                            if {[catch {
                                if {![dict exists $signature_cache $candidate]} {
                                    if {[get_db $candidate .via_def.cut_layer.name] eq $cut && [get_db $candidate .net.name] eq $net} {
                                        dict set signature_cache $candidate [::TT_SW_PG::via_signature $candidate]
                                    } else {dict set signature_cache $candidate {}}
                                }
                            }]} {incr query_failures;continue}
                            if {[dict get $signature_cache $candidate] eq $signature} {
                                lappend equivalent_${mode} $candidate
                            }
                        }
                    }
                }
            }
            set match [expr {$net_known && $net ni {{} NULL null 0x0} && $net in $pg_nets}]
            set reason SHOULD_BE_SEED_IN_CURRENT_DB
            if {!$filtered} {set reason SPATIAL_QUERY_DID_NOT_RETURN_SELECTED}
            if {!$filtered && ($unfiltered || [llength $equivalent_unfiltered])} {set reason LAYER_FILTER_EXCLUDED_SELECTED}
            if {!$filtered && [llength $equivalent_filtered]} {set reason EQUIVALENT_GEOMETRY_RETURNED}
            if {!$match} {set reason NET_NOT_IN_SWITCH_PG_NETS}
            if {!$bottom_overlap} {set reason M1_ENCLOSURE_OUTSIDE_SWITCH}
            if {$cut ne "VIA1"} {set reason SELECTED_CUT_IS_NOT_VIA1}
            if {$kind eq "shape_via"} {set reason SHAPE_VIA_NOT_IN_ROUTING_QUERY}
            if {$query_failures} {set reason QUERY_INCOMPLETE}
            dict incr reasons $reason
            set row [dict create switch $name prior_status $old bbox $boxes bottom_overlap $bottom_overlap top_overlap $top_overlap cut_overlap $cut_overlap \
                distance_to_bottom $distance net_match $match pg_nets $pg_nets returned_with_layer $filtered returned_without_layer $unfiltered equivalent_with_layer [lsort -unique $equivalent_filtered] equivalent_without_layer [lsort -unique $equivalent_unfiltered] query_failures $query_failures reason $reason]
            lappend rows $row;puts $f $row
            puts "SW selected-via evidence: prior=$old bottom_overlap=$bottom_overlap net_match=$match filtered=$filtered unfiltered=$unfiltered reason=$reason"
        }
    } finally {close $f}
    set result [dict create selected $via type $kind cut $cut reasons $reasons switches_compared [llength $rows] query_failures $failures \
        nearest_switch $nearest nearest_distance $nearest_distance rows $rows report_dir $dir]
    set sf [open [file join $dir summary.rpt] w];puts $sf $result;close $sf
    puts "SELECTED VIA SUMMARY: switches_compared=[llength $rows] | $reasons"
    puts "Nearest SW is a geometric observation, not ownership proof. shape_via coordinates require instance-context validation."
    puts "Report: [file join $dir details.list]"
    set ::TT_SW_PG_SELECTED_VIA_DIAGNOSIS $result
    return $result
}

# Positive target identity comes from the existing insertion config, never
# technology-specific master names embedded in this checker.
proc ::TT_SW_VIA_M5::switch_prefixes {} {
    set prefixes {}
    if {[info exists ::POWER_SWITCH_DESIGN_MAP] && [llength $::POWER_SWITCH_DESIGN_MAP]} {
        foreach entry $::POWER_SWITCH_DESIGN_MAP {
            if {![dict exists $entry prefix] || [dict get $entry prefix] eq {}} {
                error "POWER_SWITCH_DESIGN_MAP contains an empty/missing prefix"
            }
            lappend prefixes [dict get $entry prefix]
        }
    } elseif {[info exists ::POWER_SWITCH_INSTANCE_PREFIXES]} {
        foreach prefix $::POWER_SWITCH_INSTANCE_PREFIXES {if {$prefix ne {}} {lappend prefixes $prefix}}
    }
    if {![llength $prefixes]} {error "SW target identity is not configured; load Runtime setup with POWER_SWITCH_DESIGN_MAP or POWER_SWITCH_INSTANCE_PREFIXES"}
    return [lsort -unique $prefixes]
}
proc ::TT_SW_VIA_M5::target_exclusion {obj prefixes} {
    # is_power_switch alone has admitted SRAMs in the user's native DB.
    set memory [get_db $obj .is_memory]
    if {![string is boolean -strict $memory]} {error "Cannot determine instance memory classification"}
    if {$memory} {return MEMORY}
    set leaf [lindex [split [get_db $obj .name] /] end]
    set matched 0
    foreach prefix $prefixes {
        if {[string match "${prefix}*" $leaf]} {set matched 1;break}
    }
    if {!$matched} {return PREFIX_MISMATCH}
    if {[get_db $obj .is_power_switch] ni {true 1}} {return NATIVE_SWITCH_FLAG_FALSE}
    return {}
}
proc ::TT_SW_VIA_M5::resolve_switches {{names {}}} {
    set prefixes [::TT_SW_VIA_M5::switch_prefixes]
    set explicit [expr {[llength $names]>0}]
    set candidates {}
    if {$explicit} {
        foreach name $names {
            set objects [get_db insts $name]
            if {[llength $objects]!=1} {error "Expected exactly one instance per requested switch name"}
            lappend candidates [lindex $objects 0]
        }
    } else {set candidates [get_db insts -if {.is_power_switch == true}]}
    set accepted {};set excluded [dict create]
    foreach obj [lsort -unique $candidates] {
        set reason [::TT_SW_VIA_M5::target_exclusion $obj $prefixes]
        if {$reason ne {}} {
            dict incr excluded $reason
            if {$explicit} {error "Requested instance is not an eligible configured SW: $reason"}
            continue
        }
        lappend accepted $obj
    }
    set ::TT_SW_VIA_M5::LAST_TARGET_FILTER [dict create candidates [llength $candidates] accepted [llength $accepted] excluded $excluded]
    if {[dict size $excluded]} {puts "SW target filter: accepted=[llength $accepted] excluded=$excluded"}
    return $accepted
}

# Explicit manual repair wrapper. Existing V10/V11 write algorithm is unchanged.
namespace eval ::TT_SW_PG_REPAIR {variable plans;variable serial 0}
proc ::TT_SW_PG_REPAIR::load_core {} {
    if {![llength [info commands ::TT_SW_M4::v10_plan]] || ![llength [info commands ::TT_SW_M4::v11_apply]]} {
        set core [file join $::SCRIPT_DIR 02_powerplan power_switch SW_M4_LANDING_REPAIR.tcl]
        if {![file isfile $core]} {error "Existing M4 landing repair core is missing"}
        uplevel #0 [list source -quiet $core]
    }
}
proc ::TT_SW_PG_REPAIR::read_statuses {run_dir wanted} {
    set f [open [file join $run_dir switches.list]];set names {}
    try {
        while {[gets $f line]>=0} {if {[dict get $line status] eq $wanted} {lappend names [dict get $line switch]}}
    } finally {close $f}
    return [lsort -unique $names]
}
proc TT_SW_PG_repair_preview {{report_dir {}}} {
    ::TT_SW_PG_REPAIR::load_core
    if {$report_dir eq {}} {
        if {![info exists ::TT_SW_PG_LAST_RESULT] || ![dict exists $::TT_SW_PG_LAST_RESULT report_dir]} {
            error "Pass the full SW check run directory or run TT_SW_PG_check first"
        }
        set report_dir [dict get $::TT_SW_PG_LAST_RESULT report_dir]
    }
    set names [::TT_SW_PG_REPAIR::read_statuses $report_dir NO_PATH_FOUND]
    if {![llength $names]} {error "No NO_PATH_FOUND SWs in that report; no repair plan created"}
    # Current SW identity and geometry take precedence over historical reports.
    ::TT_SW_VIA_M5::resolve_switches $names
    set fresh [TT_SW_PG_check $names]
    set current [::TT_SW_PG_REPAIR::read_statuses [dict get $fresh report_dir] NO_PATH_FOUND]
    set id "PG_[clock microseconds]_[incr ::TT_SW_PG_REPAIR::serial]"
    set dir [file join [dict get $fresh report_dir] repair_$id]
    file mkdir $dir
    set f [open [file join $dir preview.list] w]
    set ready {};set blocked {};set entries [dict create]
    # Use the actual failed seed net; never overwrite Library config defaults.
    set fpaths [open [file join [dict get $fresh report_dir] paths.list]];set failing_nets [dict create]
    try {
        while {[gets $fpaths l]>=0} {
            set r [dict get $l result]
            if {[dict get $r status] eq "NO_PATH_FOUND"} {dict lappend failing_nets [dict get $l switch] [dict get $r net]}
        }
    } finally {close $fpaths}
    try {
        foreach name $current {
            if {[catch {
                set observed [lsort -unique [dict get $failing_nets $name]]
                if {[llength $observed]!=1} {error "Multiple failed PG nets on one SW require separate review"}
                set entry [::TT_SW_PG_REPAIR::plan_for $name [lindex $observed 0]]
                if {![llength [dict get $entry missing]]} {error "No missing V10/V11 sites; this failure needs another repair method"}
            } message]} {
                lappend blocked $name
                puts $f [list switch $name status BLOCKED reason $message]
                continue
            }
            lappend ready $name;dict set entries $name $entry
            puts $f [list switch $name status READY entry $entry]
        }
    } finally {close $f}
    set state [dict create id $id state PREVIEW report_dir $dir original_report $report_dir targets $names \
        ready $ready blocked $blocked entries $entries]
    set ::TT_SW_PG_REPAIR::plans($id) $state
    set f [open [file join $dir plan.list] w];puts $f $state;close $f
    puts "SW REPAIR PREVIEW: plan=$id requested=[llength $names] still_no_path=[llength $current] ready=[llength $ready] blocked=[llength $blocked]"
    puts "No routing edits. READY reuses the existing V10/V11 M4-landing/VIA4 method; it is not DRC certification."
    puts "Report: [file join $dir preview.list]"
    puts "Trial one SW: TT_SW_PG_repair_apply $id 1"
    return $state
}
proc ::TT_SW_PG_REPAIR::native_verify {dir phase nets} {
    set result [dict create];file mkdir [file join $dir $phase]
    set jobs [dict create \
        connectivity [list check_connectivity -nets $nets -type special -error 1000000 -warning 1000000 -out_file [file join $dir $phase connectivity.rpt]] \
        power_vias [list check_power_vias -nets $nets -layer_range {M1 M5} -non_orthogonal_check -check_wire_pin_overlap -error 1000000 -report [file join $dir $phase power_vias.rpt]] \
        drc [list tech_mv_check_drc -out_file [file join $dir $phase drc.rpt]] \
        metal_color [list tech_mv_check_drc -check_uncolored -out_file [file join $dir $phase metal_color.rpt]]]
    dict for {label command} $jobs {
        set report [file join $dir $phase ${label}.rpt]
        if {[catch {uplevel #0 $command} message]} {
            dict set result $label [dict create status ERROR message $message report $report]
            continue
        }
        if {![file isfile $report] || [file size $report]==0} {
            dict set result $label [dict create status ERROR message MISSING_REPORT report $report]
            continue
        }
        set count UNKNOWN;set problem_counts {};set details_complete 0
        if {$label in {drc metal_color} && [info exists ::TECH_MV_LAST_DRC_RESULT]} {
            set count [dict get $::TECH_MV_LAST_DRC_RESULT count]
        } else {
            set f [open $report];set text [read $f];close $f
            if {[regexp -nocase {Found no problems or warnings} $text]} {set count 0}
            if {$label in {connectivity power_vias} && [regexp {([0-9]+) total info\(s\) created} $text -> n]} {set count $n}
            if {$label eq "connectivity"} {
                set total 0
                foreach {whole n kind code} [regexp -all -inline -line {^[ \t]*([0-9]+)[ \t]+(Problem|Warning)\(s\)[ \t]+\(([^)]+)\):} $text] {
                    dict incr problem_counts "${kind}:$code" $n
                    incr total $n
                }
                if {[string is integer -strict $count] && $total==$count} {set details_complete 1}
            }
        }
        dict set result $label [dict create status REPORT_READY count $count report $report]
        if {$label eq "connectivity"} {
            dict set result $label problem_counts $problem_counts
            dict set result $label details_complete $details_complete
        }
    }
    return $result
}
proc TT_SW_PG_repair_apply {plan_id {limit 1}} {
    if {![info exists ::TT_SW_PG_REPAIR::plans($plan_id)]} {error "No in-session preview for this plan ID"}
    if {![string is integer -strict $limit] || $limit<1} {error "limit must be positive; default is a one-SW trial"}
    set saved $::TT_SW_PG_REPAIR::plans($plan_id)
    if {[dict get $saved state] ne "PREVIEW"} {error "Plan already consumed; create a fresh preview before another APPLY"}
    set targets [lrange [dict get $saved ready] 0 [expr {$limit-1}]]
    if {![llength $targets]} {error "No READY candidates; inspect preview's BLOCKED reasons"}
    ::TT_SW_VIA_M5::resolve_switches $targets
    # Re-run the exact existing preflight, before any DB write.
    foreach name $targets {
        set now [::TT_SW_PG_REPAIR::plan_for $name [dict get $saved entries $name net]]
        if {$now ne [dict get $saved entries $name]} {error "Repair plan is stale; rerun preview (no routing edits performed)"}
    }
    foreach command {write_db check_connectivity check_power_vias tech_mv_check_drc create_shape update_power_vias} {
        if {![llength [info commands $command]]} {error "Required command unavailable: $command"}
    }
    set dir [dict get $saved report_dir]
    set checkpoint [file join $::DB_DIR "02_sw_pg_before_${plan_id}.enc"]
    if {[file exists $checkpoint]} {error "Checkpoint already exists; use a fresh preview"}
    write_db $checkpoint
    if {![file exists $checkpoint]} {error "Pre-repair checkpoint was not created; APPLY aborted"}
    dict set ::TT_SW_PG_REPAIR::plans($plan_id) state CONSUMED
    dict set ::TT_SW_PG_REPAIR::plans($plan_id) checkpoint $checkpoint
    set nets [lsort -unique [lmap name $targets {dict get $saved entries $name net}]]
    set baseline [::TT_SW_PG_REPAIR::native_verify $dir before $nets]
    dict for {label check} $baseline {
        if {[dict get $check status] eq "ERROR"} {
            set result [dict create status BASELINE_ERROR_NO_ROUTING_EDITS checkpoint $checkpoint baseline $baseline report_dir $dir]
            set f [open [file join $dir apply_summary.list] w];puts $f $result;close $f
            puts "SW REPAIR STOP: baseline check failed; routing was not edited. Report: $dir"
            return $result
        }
    }
    # Native baseline checks may update markers, so revalidate geometry once more.
    foreach name $targets {
        if {[::TT_SW_PG_REPAIR::plan_for $name [dict get $saved entries $name net]] ne [dict get $saved entries $name]} {
            error "Plan changed during baseline; no routing edits were made"
        }
    }
    set write_error {}
    set f [open [file join $dir operations.list] w]
    try {
        foreach name $targets {
            puts $f [list START switch $name net [dict get $saved entries $name net]];flush $f
            if {[catch {::TT_SW_PG_REPAIR::write_candidate $name [dict get $saved entries $name]} message]} {
                set write_error $message
                puts $f [list FAILED_PARTIAL_DB_POSSIBLE switch $name message $message];flush $f
                break
            }
            puts $f [list VIA4_PRESENT switch $name];flush $f
        }
    } finally {close $f}
    set checks [::TT_SW_PG_REPAIR::native_verify $dir after $nets]
    # Refresh highlights for the full requested cohort, including unrepaired SWs.
    set verified_targets {}
    if {[catch {
        set graph [TT_SW_PG_check [dict get $saved targets]]
        set found [::TT_SW_PG_REPAIR::read_statuses [dict get $graph report_dir] FOUND_M5]
        foreach name $targets {if {$name in $found} {lappend verified_targets $name}}
    } message]} {set graph [dict create status CHECK_ERROR message $message]}
    set status GEOMETRY_REPAIRED_NATIVE_REVIEW_REQUIRED
    if {$write_error ne {} || ![dict exists $graph counts] || [llength $verified_targets]!=[llength $targets]} {
        set status FAILED_OR_PARTIAL_DB_POSSIBLE
    }
    set regression [dict create]
    dict for {label after} $checks {
        set before [dict get $baseline $label]
        if {[dict get $after status] eq "ERROR" && $status eq "GEOMETRY_REPAIRED_NATIVE_REVIEW_REQUIRED"} {
            set status POSTCHECK_ERROR_REVIEW_REQUIRED
        }
        set comparison REVIEW_REQUIRED
        if {[dict get $after status] eq "REPORT_READY" && [dict exists $after count] && [dict exists $before count]} {
            set a [dict get $after count];set b [dict get $before count]
            if {[string is integer -strict $a] && [string is integer -strict $b]} {
                set comparison NOT_INCREASED
                if {$a>$b} {set comparison INCREASED;set status NATIVE_REGRESSION_RESTORE_RECOMMENDED}
            }
        }
        if {$label eq "connectivity" && [dict get $after status] eq "REPORT_READY"} {
            if {![dict get $after details_complete] || ![dict get $before details_complete]} {
                if {$comparison ne "INCREASED"} {set comparison REVIEW_REQUIRED}
            } else {
                dict for {category count} [dict get $after problem_counts] {
                    set old 0
                    if {[dict exists $before problem_counts $category]} {set old [dict get $before problem_counts $category]}
                    if {$count>$old} {set comparison INCREASED;set status NATIVE_REGRESSION_RESTORE_RECOMMENDED}
                }
            }
        }
        dict set regression $label $comparison
    }
    set result [dict create status $status checkpoint $checkpoint targets $targets verified_targets $verified_targets write_error $write_error \
        graph $graph baseline $baseline after $checks regression $regression report_dir $dir]
    set f [open [file join $dir apply_summary.list] w];puts $f $result;close $f
    set ::TT_SW_PG_REPAIR_LAST_RESULT $result
    puts "SW REPAIR SUMMARY: attempted=[llength $targets] status=$status"
    puts "Native report comparison: $regression"
    puts "Rollback DB: $checkpoint"
    puts "Report: [file join $dir apply_summary.list]"
    puts "Existing repair adds M4 landing and generates VIA4; no M5 patch or SW movement. Review native reports before acceptance."
    return $result
}

# Per-read-only-batch native query cache. Never retained across APPLY/DB edits.
proc ::TT_SW_PG::cache_begin {} {
    unset -nocomplain ::TT_SW_PG::db_cache ::TT_SW_PG::area_cache ::TT_SW_PG::proof_cache
    set ::TT_SW_PG::cache_stats [dict create db_reads 0 db_hits 0 area_queries 0 area_hits 0 proof_hits 0]
    set ::TT_SW_PG::cache_started [clock milliseconds]
    set ::TT_SW_PG::cache_active 1
}
proc ::TT_SW_PG::cache_end {} {
    dict set ::TT_SW_PG::cache_stats elapsed_ms [expr {[clock milliseconds]-$::TT_SW_PG::cache_started}]
    set ::TT_SW_PG_LAST_PERFORMANCE $::TT_SW_PG::cache_stats
    set ::TT_SW_PG::cache_active 0
    unset -nocomplain ::TT_SW_PG::db_cache ::TT_SW_PG::area_cache ::TT_SW_PG::proof_cache
    return $::TT_SW_PG_LAST_PERFORMANCE
}
proc ::TT_SW_PG::native_db {args} {
    if {![info exists ::TT_SW_PG::cache_active] || !$::TT_SW_PG::cache_active} {return [get_db {*}$args]}
    if {[info exists ::TT_SW_PG::db_cache($args)]} {
        dict incr ::TT_SW_PG::cache_stats db_hits
        return $::TT_SW_PG::db_cache($args)
    }
    dict incr ::TT_SW_PG::cache_stats db_reads
    set value [get_db {*}$args]
    set ::TT_SW_PG::db_cache($args) $value
    return $value
}
proc ::TT_SW_PG::native_area {args} {
    if {![info exists ::TT_SW_PG::cache_active] || !$::TT_SW_PG::cache_active} {return [get_obj_in_area {*}$args]}
    if {[info exists ::TT_SW_PG::area_cache($args)]} {
        dict incr ::TT_SW_PG::cache_stats area_hits
        return $::TT_SW_PG::area_cache($args)
    }
    dict incr ::TT_SW_PG::cache_stats area_queries
    set value [get_obj_in_area {*}$args]
    set ::TT_SW_PG::area_cache($args) $value
    return $value
}

# Reuse legacy V10 geometry in an explicit temporary supply context. Config and
# the legacy default supply are restored even if a query or native write fails.
proc ::TT_SW_PG_REPAIR::with_net {net command} {
    if {$net in {{} NULL null 0x0}} {error "No valid repair net"}
    set old $::TT_SW_M4::net
    set ::TT_SW_M4::net $net
    try {uplevel 1 $command} finally {set ::TT_SW_M4::net $old}
}
proc ::TT_SW_PG_REPAIR::plan_body {name net} {
    if {[catch {::TT_SW_M4::v10_plan $name} plan options]} {
        if {$plan ne "V10: unexpected stripe/footprint geometry; no automatic M4 patch"} {
            return -options $options $plan
        }
        set plan [::TT_SW_PG_REPAIR::right_extension_plan $name $net]
    }
    set missing [::TT_SW_M4::v11_missing $plan]
    return [dict create plan $plan missing $missing net $net]
}
proc ::TT_SW_PG_REPAIR::plan_for {name net} {
    return [::TT_SW_PG_REPAIR::with_net $net [list ::TT_SW_PG_REPAIR::plan_body $name $net]]
}
proc ::TT_SW_PG_REPAIR::write_body {name entry} {
    set net [dict get $entry net]
    set current [::TT_SW_PG_REPAIR::plan_body $name $net]
    if {$current ne $entry} {error "Candidate geometry changed immediately before write"}
    set m4 [::tech_mv_library_value LIB_TECH_003]
    set m5 [::tech_mv_library_value LIB_TECH_004]
    set missing [dict get $entry missing]
    # Same local operations and geometry as V11; explicit actual target net
    # replaces V11's fixed SW_LANDING_TARGET_NET lookup.
    foreach site $missing {
        create_shape -layer $m4 -net $net -shape stripe -status fixed -rect [dict get $site landing]
        update_power_vias -add_vias 1 -nets [list $net] -bottom_layer $m4 -top_layer $m5 -area [list [dict get $site region]] -orthogonal_only 0
    }
    foreach site $missing {
        if {![llength [::TT_SW_M4::v10_via45_site $site [dict get $entry plan m5]]]} {
            error "VIA4 remains missing after local generation; partial DB edits possible"
        }
    }
}
proc ::TT_SW_PG_REPAIR::write_candidate {name entry} {
    return [::TT_SW_PG_REPAIR::with_net [dict get $entry net] [list ::TT_SW_PG_REPAIR::write_body $name $entry]]
}
# Capture unsupported legacy landing geometry before designing another write mode.
proc ::TT_SW_PG_REPAIR::geometry_body {name net} {
    set sites [::TT_SW_M4::discover $name]
    set sw [get_db insts $name]
    set box [::TT_SW_M4::rect [get_db $sw .bbox]]
    set area [::TT_SW_M4::expand $box [::tech_mv_private_value {sw_m4_landing::patch_wire_scan_margin}]]
    set m5s {}
    foreach wire [::TT_SW_M4::objects $area special_wire] {
        if {[get_db $wire .net.name] ne $net || [get_db $wire .layer.name] ne [::tech_mv_library_value LIB_TECH_004]} continue
        set rects [::TT_SW_PG::wire_rects $wire]
        set overlap 0
        foreach rect $rects {if {[::TT_SW_PG::overlap $rect $box]} {set overlap 1}}
        if {$overlap} {lappend m5s [dict create object $wire rectangles $rects]}
    }
    set rows {}
    foreach site $sites {
        set footprint [dict get $site m4_via3_top]
        set category NON_UNIQUE_M5_GEOMETRY
        if {[llength $m5s]==1 && [llength [dict get [lindex $m5s 0] rectangles]]==1} {
            set m5 [lindex [dict get [lindex $m5s 0] rectangles] 0]
            lassign $footprint fx1 fy1 fx2 fy2
            lassign $m5 mx1 my1 mx2 my2
            set category OTHER_OVERLAP
            if {![::TT_SW_PG::overlap $footprint $m5]} {
                set category NO_ACTUAL_METAL_OVERLAP
            } elseif {$mx1<=$fx1 && $mx2>=$fx2 && $my1<=$fy1 && $my2>=$fy2} {
                set category M5_CONTAINS_FOOTPRINT
            } elseif {$mx1<$fx1 && $mx2>$fx1 && $fx2>$mx2} {
                set category LEGACY_LEFT_EXTENSION_CASE
            } elseif {$fx1<$mx1 && $mx1<$fx2 && $fx2<$mx2} {
                set category RIGHT_EXTENSION_CASE
            } elseif {$mx1==$fx1 && $mx2==$fx2} {
                set category SAME_X_SPAN
            }
        }
        lappend rows [dict create site $site category $category]
    }
    return [dict create switch $name net $net bbox $box m5_objects $m5s sites $rows]
}
proc TT_SW_PG_repair_explain {plan_id} {
    if {![info exists ::TT_SW_PG_REPAIR::plans($plan_id)]} {error "No in-session preview with that plan ID"}
    ::TT_SW_PG_REPAIR::load_core
    set state $::TT_SW_PG_REPAIR::plans($plan_id)
    set dir [dict get $state report_dir]
    set f [open [file join [file dirname $dir] paths.list]];set nets {}
    try {
        while {[gets $f line]>=0} {
            set r [dict get $line result]
            if {[dict get $r status] eq "NO_PATH_FOUND"} {dict lappend nets [dict get $line switch] [dict get $r net]}
        }
    } finally {close $f}
    set path [file join $dir geometry_[clock microseconds].list]
    set f [open $path w];set counts {};set failures 0;set switches 0
    try {
        foreach name [dict get $state targets] {
            if {![dict exists $nets $name]} continue
            incr switches
            if {[catch {
                ::TT_SW_VIA_M5::resolve_switches [list $name]
                set ns [lsort -unique [dict get $nets $name]]
                if {[llength $ns]!=1} {error "Multiple failed nets need separate review"}
                set net [lindex $ns 0]
                set result [::TT_SW_PG_REPAIR::with_net $net [list ::TT_SW_PG_REPAIR::geometry_body $name $net]]
            } message]} {
                incr failures;puts $f [list switch $name status QUERY_ERROR reason $message];continue
            }
            puts $f $result
            foreach site [dict get $result sites] {dict incr counts [dict get $site category]}
        }
    } finally {close $f}
    puts "SW REPAIR GEOMETRY: switches=$switches site_categories=$counts query_failures=$failures"
    puts "Read-only explanation; no repair or safety threshold was changed."
    puts "Report: $path"
    return [dict create switches $switches site_categories $counts query_failures $failures report $path]
}

# Mirror the legacy LEFT landing construction only for exact RIGHT cases.
proc ::TT_SW_PG_REPAIR::right_extension_plan {name net} {
    set geometry [::TT_SW_PG_REPAIR::geometry_body $name $net]
    set m5s [dict get $geometry m5_objects]
    if {[llength $m5s]!=1 || [llength [dict get [lindex $m5s 0] rectangles]]!=1} {
        error "RIGHT repair requires one exact rectangular same-net M5 stripe"
    }
    set m5 [lindex [dict get [lindex $m5s 0] rectangles] 0]
    lassign $m5 mx1 my1 mx2 my2
    set planned {}
    foreach record [dict get $geometry sites] {
        if {[dict get $record category] ne "RIGHT_EXTENSION_CASE"} {error "Mixed/non-right footprint geometry requires separate review"}
        set site [dict get $record site]
        lassign [dict get $site m4_via3_top] fx1 fy1 fx2 fy2
        if {!($fx1<$mx1 && $mx1<$fx2 && $fx2<$mx2 && $my1<=$fy1 && $my2>=$fy2)} {
            error "RIGHT stripe/footprint containment changed"
        }
        # Mirror of legacy {mx1 fy1 fx2 fy2}; no M5 edits.
        set landing [list $fx1 $fy1 $mx2 $fy2]
        if {$mx2-$fx1>[::tech_mv_private_value {sw_m4_landing::max_patch_width}]} {error "RIGHT patch exceeds existing max_patch_width"}
        if {$fy2-$fy1>[::tech_mv_private_value {sw_m4_landing::max_patch_height}]} {error "RIGHT patch exceeds existing max_patch_height"}
        set area [::TT_SW_M4::expand $landing [::tech_mv_private_value {sw_m4_landing::landing_area_margin}]]
        foreach kind {special_wire wire patch_wire} {
            foreach obj [::TT_SW_M4::objects $area $kind] {
                if {[get_db $obj .layer.name] ne [::tech_mv_library_value LIB_TECH_003]} continue
                set other_net [get_db $obj .net.name]
                if {$other_net in {{} NULL null 0x0}} {error "Cannot resolve neighboring M4 net"}
                if {$other_net eq $net} continue
                foreach rect [::TT_SW_PG::wire_rects $obj] {
                    if {[::TT_SW_PG::touch $rect $landing]} {error "Foreign-net M4 touches RIGHT landing"}
                }
            }
        }
        foreach kind {special_via via} {
            foreach obj [::TT_SW_M4::objects $area $kind] {
                set other_net [get_db $obj .net.name]
                if {$other_net in {{} NULL null 0x0}} {error "Cannot resolve neighboring via net"}
                if {$other_net eq $net} continue
                set via [::TT_SW_PG::via_geometry $obj]
                foreach side {bottom top} {
                    if {[dict get $via ${side}_layer] ne [::tech_mv_library_value LIB_TECH_003]} continue
                    foreach rect [dict get $via $side] {
                        if {[::TT_SW_PG::touch $rect $landing]} {error "Foreign-net via M4 enclosure touches RIGHT landing"}
                    }
                }
            }
        }
        dict set site landing $landing
        # The old footprint-centered region misses all 38 right landings.
        # Bound ViaGen around the actual local patch using the existing margin.
        dict set site region [::TT_SW_M4::expand $landing [::tech_mv_private_value {sw_m4_landing::search_margin}]]
        lappend planned $site
    }
    if {![llength $planned]} {error "No RIGHT extension sites"}
    puts "RIGHT M4 LANDING PREVIEW: sites=[llength $planned] no_M5_patch=1"
    return [dict create method RIGHT_EXTENSION sites $planned m5 $m5]
}
