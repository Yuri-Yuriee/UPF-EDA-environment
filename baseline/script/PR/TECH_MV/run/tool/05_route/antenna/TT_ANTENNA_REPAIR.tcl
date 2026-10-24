# Runtime adapter preserves the historical logical source path.
if {[info exists ::TECH_MV_RUNTIME_ROOT]} {
    info script [file join $::TECH_MV_RUNTIME_ROOT run/tool/05_route/antenna/TT_ANTENNA_REPAIR.tcl]
}
# Signal-only native layer-hopping repair. Sourcing defines commands only.
namespace eval ::tt_antenna {
    variable last
    if {![info exists last]} {set last [dict create status NOT_RUN]}
    variable hooks
    if {![info exists hooks]} {set hooks [dict create]}
    proc setting {key fallback} {
        if {[info exists ::$key]} {return [set ::$key]}
        return $fallback
    }
    proc token {} {return "[clock clicks -microseconds]_[pid]"}
    proc directory {stage} {
        if {![info exists ::REPORT_DIR]} {error "REPORT_DIR is required."}
        set dir [file normalize [file join $::REPORT_DIR antenna]]
        file mkdir $dir
        return $dir
    }
    proc read_file {path} {
        set f [open $path r]; set text [read $f]; close $f; return $text
    }
    proc completion {text} {
        set result -1
        foreach line [split $text \n] {
            if {[regexp -nocase {Verification\s+Complete\s*:\s*([0-9]+)\s+(?:Violations|Viols)\.?} $line -> count]} {scan $count %d result}
        }
        return $result
    }
    proc parse {text native {allow_summary false}} {
        set report_count -1; set report_nets -1
        foreach line [split $text \n] {
            if {[regexp -nocase {Total\s+number\s+of\s+process\s+antenna\s+violations\s*:\s*([0-9]+)\s+Viols\.?\s+Number\s+of\s+nets\s+violated\s*:\s*([0-9]+)\.?} $line -> total nets]} {
                scan $total %d report_count; scan $nets %d report_nets
            }
        }
        set count [completion "$text\n$native"]
        if {$report_count >= 0} {
            if {$count >= 0 && $count != $report_count} {error "Fresh native/report antenna totals disagree; routing is prohibited."}
            set count $report_count
        }
        set current {}; set vio [dict create]; set pins [dict create]
        foreach line [split $text \n] {
            if {[regexp -nocase {^\s*Net\s*(?::\s*|\s+)(.*?)\s*$} $line -> rest]} {
                if {[regexp {^"([^"]+)"\s*$} $rest -> name] ||
                    [regexp {^\{([^{}]+)\}\s*$} $rest -> name] ||
                    [regexp {^(\S+)$} $rest -> name]} {
                    set current $name
                } else {error "Unrecognized Net header; routing is prohibited."}
            }
            if {[regexp -nocase {PIN\s*:\s*(.*)} $line -> pin]} {
                if {$current eq ""} {error "PIN record without a Net header."}
                dict lappend pins $current [string trim $pin]
            }
            set occurrences [regexp -all -nocase {\mVIO\s*:} $line]
            if {$occurrences} {
                if {$current eq ""} {error "VIO record without a Net header; routing is prohibited."}
                dict incr vio $current $occurrences
            }
        }
        set records 0; dict for {net n} $vio {incr records $n}
        if {$count < 0} {error "No fresh antenna completion count; routing is prohibited."}
        set details COMPLETE
        if {$count != $records} {
            if {$allow_summary && $count > 0 && $records == 0 && $report_count >= 0 && ![dict size $pins]} {
                set details SUMMARY_ONLY
            } else {error "Antenna completion/VIO record count mismatch; routing is prohibited."}
        }
        if {$report_nets >= 0 && $details eq "COMPLETE" && $report_nets != [dict size $vio]} {error "Antenna violated-net total differs from VIO blocks; routing is prohibited."}
        return [dict create count $count nets [dict keys $vio] violations $vio pins $pins details $details reported_net_count $report_nets]
    }
    proc check {use stage label} {
        set stamp [token]; set dir [directory $stage]
        set report [file join $dir ${label}_${use}_${stamp}.rpt]
        if {[llength [info commands tech_mv_output_path]]} {
            set console [tech_mv_output_path log ${label}_${use}_${stamp}.native.log $stage antenna]
        } else {set console [file join $dir ${label}_${use}_${stamp}.native.txt]}
        if {[file exists $report] || [file exists $console]} {error "Antenna output collision."}
        set text {}; set start [clock milliseconds]
        set code [catch {redirect text [list check_antenna -use $use -out_file $report] -variable -tee} msg opts]
        set f [open $console {WRONLY CREAT EXCL}]; puts -nonewline $f $text; close $f
        if {$code} {return -options $opts $msg}
        if {![file isfile $report]} {error "Fresh antenna report was not generated: $report"}
        set code [catch {parse [read_file $report] $text [expr {$label eq "final"}]} parsed opts]
        if {$code} {return -options $opts "Cannot parse fresh antenna report $report (native log $console): $parsed"}
        dict set parsed report $report
        dict set parsed native_log $console
        dict set parsed elapsed_ms [expr {[clock milliseconds]-$start}]
        return $parsed
    }
    proc boolean {obj attr} {
        set v [get_db $obj $attr]
        if {![string is boolean -strict $v]} {error "Cannot validate $attr; routing is prohibited."}
        return [expr {$v ? 1 : 0}]
    }
    proc resolve {name} {
        set matches [get_db nets $name]; set exact {}
        foreach obj $matches {if {[get_db $obj .name] eq $name} {lappend exact $obj}}
        if {[llength $matches] != 1 || [llength $exact] != 1} {error "Antenna net cannot be resolved uniquely: $name"}
        return [lindex $exact 0]
    }
    proc classify {obj report_pins} {
        if {[boolean $obj .is_power] || [boolean $obj .is_ground]} {return POWER}
        if {[boolean $obj .is_clock]} {return CLOCK}
        if {[llength [get_db $obj .special_wires]] || [llength [get_db $obj .special_vias]]} {return SPECIAL}
        set constant [get_db $obj .constant]
        if {$constant eq "0" || $constant eq "1"} {return TIE}
        if {$constant ne "no_constant"} {error "Unknown net constant classification."}
        if {[llength [get_db $obj .driver_ports]] || [llength [get_db $obj .load_ports]]} {return IO_PAD}
        set pins [lsort -unique [concat [get_db $obj .driver_pins] [get_db $obj .load_pins]]]
        if {![llength $pins]} {return UNKNOWN}
        # Use PIN records as additional PAD evidence; DB endpoints remain authoritative.
        foreach entry $report_pins {
            if {[regexp {^(\S+)\s+\([^)]*\)\s+(\S+)\s*$} $entry -> instance pin_name]} {
                set instances [get_db insts $instance]
                foreach i $instances {
                    if {[get_db $i .name] ne $instance} {continue}
                    set class [get_db $i .base_cell.class]
                    if {[boolean $i .is_pad] || [string match pad* $class]} {return IO_PAD}
                }
            } else {
                set pin_name [lindex $entry 0]
                foreach p [get_db pins $pin_name] {
                    set i [get_db $p .inst]
                    if {[llength $i] && [boolean $i .is_pad]} {return IO_PAD}
                }
            }
        }
        foreach p $pins {
            set inst [get_db $p .inst]
            if {[llength $inst] != 1} {return UNKNOWN}
            if {[boolean $inst .is_pad]} {return IO_PAD}
            if {[boolean $p .is_special]} {return SPECIAL}
            set base [get_db $inst .base_cell]
            set class [get_db $base .class]
            if {[string match pad* $class]} {return IO_PAD}
            if {$class in {core_tie_high core_tie_low}} {return TIE}
            if {[boolean $inst .is_macro] || [boolean $inst .is_power_switch] || $class ne "core"} {return NON_STANDARD}
        }
        return STANDARD_SIGNAL
    }
    proc candidates {result} {
        set objects {}; set names {}; set groups [dict create]
        foreach name [dict get $result nets] {
            set obj [resolve $name]; set pins {}
            if {[dict exists $result pins $name]} {set pins [dict get $result pins $name]}
            set class [classify $obj $pins]
            dict lappend groups $class $name
            if {$class eq "STANDARD_SIGNAL"} {lappend objects $obj; lappend names $name}
        }
        dict set result objects $objects; dict set result candidates $names; dict set result classes $groups
        return $result
    }
    proc selection {objects} {
        set actual [get_db selected]
        foreach obj $actual {if {[get_db $obj .obj_type] ne "net"} {error "Selected non-net object; routing is prohibited."}}
        if {[lsort -unique $actual] ne [lsort -unique $objects] || [llength $actual] != [llength $objects]} {
            error "Selected objects differ from validated candidate nets; routing is prohibited."
        }
    }
    proc connectivity {names stage label} {
        set report [file join [directory $stage] ${label}_connectivity_[token].rpt]
        set text {}
        set command [list check_connectivity -type regular -out_file $report]
        if {[llength $names]} {lappend command -nets $names}
        redirect text $command -variable -tee
        set joined "$text\n[read_file $report]"
        if {![regexp -nocase {Verification\s+Complete\s*:\s*([0-9]+)\s+Viols\.?\s+([0-9]+)\s+Wrngs\.?} $joined -> errors warnings]} {
            error "Cannot parse fresh connectivity completion: $report"
        }
        return [dict create status [expr {$errors == 0 && $warnings == 0 ? "PASS" : "FAIL"}] errors $errors warnings $warnings report $report]
    }
    proc routing_snapshot {} {
        set snapshot [dict create]
        foreach net [get_db nets] {
            set geometry {}
            foreach attr {.wires .special_wires} {
                foreach w [get_db $net $attr] {
                    set points {}; if {$attr eq ".wires"} {set points [get_db $w .points]}
                    lappend geometry [list $attr [get_db $w .layer.name] [get_db $w .rect] [get_db $w .width] [get_db $w .mask] $points]
                }
            }
            foreach attr {.vias .special_vias} {
                foreach v [get_db $net $attr] {
                    set position .location; if {$attr eq ".special_vias"} {set position .point}
                    lappend geometry [list $attr [get_db $v .via_def.name] [get_db $v $position] [get_db $v .bottom_mask] [get_db $v .cut_mask] [get_db $v .top_mask]]
                }
            }
            dict set snapshot [get_db $net .name] [lsort $geometry]
        }
        return $snapshot
    }
    proc changes {before after targets} {
        set changed {}; set protected {}
        foreach name [lsort -unique [concat [dict keys $before] [dict keys $after]]] {
            if {![dict exists $before $name] || ![dict exists $after $name] || [dict get $before $name] ne [dict get $after $name]} {
                lappend changed $name
                if {$name ni $targets} {lappend protected $name}
            }
        }
        return [dict create affected_nets $changed unexpected_nets $protected]
    }
    # Call the existing marker-guided checker; never invoke its repair commands.
    proc color_check {} {
        if {![llength [info commands metal_color_check]]} {
            if {![info exists ::TOOL_DIR]} {error "TOOL_DIR is required for the existing Metal Color checker."}
            source -quiet [file join $::TOOL_DIR 05_route drc TT_DRC_fix_metal_color.tcl]
        }
        if {![info exists ::METAL_COLOR_REPAIR_MARKER_SUBTYPES]} {error "Existing Metal Color subtype settings are required."}
        set count 0
        foreach marker [get_db markers] {
            if {[get_db $marker .subtype] in $::METAL_COLOR_REPAIR_MARKER_SUBTYPES} {incr count}
        }
        set text {}
        set report [file join [directory 05] metal_color_[token].rpt]
        set code [catch {redirect text {metal_color_check} -variable -tee} result opts]
        set f [open $report {WRONLY CREAT EXCL}];puts -nonewline $f $text;close $f
        if {$code} {return -options $opts $result}
        return [dict create status [expr {$count == 0 ? "PASS" : "FAIL"}] configured_markers $count report $report]
    }
    proc save_status {} {
        variable last
        set report [file join [directory 05] status_[token].txt]
        dict set last status_report $report
        set f [open $report {WRONLY CREAT EXCL}]
        dict for {k v} $last {puts $f "$k: $v"}
        close $f
    }
}
proc antenna_check {} {
    set ::tt_antenna::last [dict create status CHECKING connectivity NOT_RUN checkpoint NOT_RUN]
    set rc [catch {::tt_antenna::candidates [::tt_antenna::check signal 05 check]} result opts]
    if {$rc} {dict set ::tt_antenna::last status ERROR; dict set ::tt_antenna::last error $result; return -options $opts $result}
    dict set ::tt_antenna::last check $result
    dict set ::tt_antenna::last before [dict get $result count]
    dict set ::tt_antenna::last candidate_count [llength [dict get $result candidates]]
    set io 0; if {[dict exists $result classes IO_PAD]} {set io [llength [dict get $result classes IO_PAD]]}
    dict set ::tt_antenna::last skipped_io_pad $io
    dict set ::tt_antenna::last report [dict get $result report]
    dict set ::tt_antenna::last status [expr {[dict get $result count] == 0 ? "PASS" : "FAIL"}]
    puts "SIGNAL ANTENNA: [dict get $result count] violations; [llength [dict get $result candidates]] repair candidates; $io IO/PAD nets skipped"
    puts "Report: [dict get $result report]"
    return $result
}
proc antenna_verify {} {
    dict set ::tt_antenna::last status ERROR
    dict set ::tt_antenna::last report NOT_RUN
    set result [::tt_antenna::check signal 05 verify]
    dict set ::tt_antenna::last status [expr {[dict get $result count] == 0 ? "PASS" : "FAIL"}]
    dict set ::tt_antenna::last after [dict get $result count]
    dict set ::tt_antenna::last report [dict get $result report]
    puts [expr {[dict get $result count] == 0 ? "SIGNAL_ANTENNA_PASS" : "SIGNAL_ANTENNA_FAIL"}]
    dict for {net count} [dict get $result violations] {puts "Net: $net | Violations: $count"}
    puts "Report: [dict get $result report]"
    return $result
}
proc antenna_status {} {
    dict for {key value} $::tt_antenna::last {
        if {$key ne "check"} {puts "$key: $value"}
    }
    return $::tt_antenna::last
}
proc antenna_repair {} {
    set before [antenna_check]
    set names [dict get $before candidates]; set objects [dict get $before objects]
    if {![llength $names]} {
        dict set ::tt_antenna::last after [dict get $before count]
        puts "NO_REPAIR_NEEDED"
        if {[dict get $before count] > 0} {
            dict set ::tt_antenna::last status PARTIAL
            if {[dict size [dict get $before classes]] == 1 && [dict exists $before classes IO_PAD]} {puts "IO_PAD_ANTENNA_REVIEW_REQUIRED"}
        }
        ::tt_antenna::save_status
        return [antenna_status]
    }
    dict set ::tt_antenna::last status ERROR
    set limit [::tt_antenna::setting ANTENNA_ROUTE_MAX_CANDIDATE_NETS 200]
    if {![string is integer -strict $limit] || $limit < 1 || [llength $names] > $limit} {error "Candidate count exceeds the configured safety limit; no routing performed."}
    if {![info exists ::DB_DIR]} {error "DB_DIR is required."}
    if {![llength [info commands tech_mv_check_drc]]} {error "Existing tech_mv_check_drc verification is required before routing."}
    if {[info exists ::TOOL_DIR] && [file normalize $::DB_DIR] ne [file normalize [file join $::TOOL_DIR .. .. dbs]]} {error "DB_DIR must be the active runtime dbs directory."}
    set checkpoint [file normalize [file join $::DB_DIR 05_antenna_before_[::tt_antenna::token].enc]]
    if {[file exists $checkpoint]} {error "Checkpoint collision; routing is prohibited."}
    file mkdir $::DB_DIR
    dict set ::tt_antenna::last checkpoint $checkpoint
    set saved [dict create]; set cleanup {}; set started 0
    set code [catch {
        # Capture every regular/PG route before invoking the native router.
        set geometry [::tt_antenna::routing_snapshot]
        tech_mv_check_drc
        set drc_before $::TECH_MV_LAST_DRC_RESULT
        write_db $checkpoint
        if {![file exists $checkpoint]} {error "Checkpoint save did not create its DB path; no routing performed."}
        dict set ::tt_antenna::last checkpoint_written true
        foreach {attr value} {
            route_design_detail_fix_antenna true
            route_design_antenna_diode_insertion false
            route_design_detail_fix_antenna_on_secondary_pg_nets false
            route_design_diode_insertion_for_clock_nets false
        } {
            dict set saved $attr [get_db $attr]
            set_db $attr $value
        }
        deselect_obj -all
        foreach object $objects {select_obj $object}
        ::tt_antenna::selection $objects
        set started 1
        route_design -selected
    } message options]
    if {[catch {deselect_obj -all} e]} {lappend cleanup "Cannot clear selection: $e"}
    dict for {attr value} $saved {if {[catch {set_db $attr $value} e]} {lappend cleanup "Cannot restore $attr: $e"}}
    if {$code || [llength $cleanup]} {
        dict set ::tt_antenna::last status ERROR
        dict set ::tt_antenna::last error [list $message $cleanup]
        puts "ANTENNA ERROR: $message $cleanup"
        if {[dict exists $::tt_antenna::last checkpoint_written]} {
            puts "No automatic rollback was performed. Restore the saved DB manually: $checkpoint"
        } else {puts "No completed checkpoint was recorded; routing was not started."}
        ::tt_antenna::save_status
        error "Antenna repair stopped; inspect antenna_status."
    }
    set code [catch {
        set delta [::tt_antenna::changes $geometry [::tt_antenna::routing_snapshot] $names]
        dict for {k v} $delta {dict set ::tt_antenna::last $k $v}
        set after [antenna_verify]
        set conn [::tt_antenna::connectivity $names 05 after]
        dict set ::tt_antenna::last connectivity $conn
        tech_mv_check_drc
        set drc_after $::TECH_MV_LAST_DRC_RESULT
        set color [::tt_antenna::color_check]
        dict set ::tt_antenna::last metal_color $color
        dict set ::tt_antenna::last drc_before $drc_before
        dict set ::tt_antenna::last drc_after $drc_after
        set count [dict get $after count]
        set status PASS
        if {$count > 0} {set status PARTIAL}
        if {$count >= [dict get $before count]} {set status FAIL}
        if {[dict get $color status] ne "PASS" || [dict get $conn status] ne "PASS" || [dict get $drc_after count] > [dict get $drc_before count] || [llength [dict get $delta unexpected_nets]]} {set status FAIL}
        dict set ::tt_antenna::last status $status
        if {$count > 0} {
            set classified [::tt_antenna::candidates $after]
            if {[dict size [dict get $classified classes]] == 1 && [dict exists $classified classes IO_PAD]} {puts "IO_PAD_ANTENNA_REVIEW_REQUIRED"}
        }
    } message options]
    if {$code} {
        dict set ::tt_antenna::last status ERROR
        dict set ::tt_antenna::last error $message
        puts "Post-repair verification ERROR: $message"
        puts "No automatic rollback was performed. Restore manually: $checkpoint"
    }
    ::tt_antenna::save_status
    antenna_status
    if {$code} {return -options $options $message}
    return $::tt_antenna::last
}
proc antenna_stage05 {} {
    if {![::tt_antenna::setting ANTENNA_ROUTE_ENABLE true]} {puts "ANTENNA: Stage05 disabled."; return}
    set key [list 05 [get_db current_design]]
    if {[dict exists $::tt_antenna::hooks $key]} {puts "ANTENNA: Stage05 hook already attempted; use antenna_repair for an explicit new run."; return}
    dict set ::tt_antenna::hooks $key attempted
    set code [catch {
        if {[::tt_antenna::setting ANTENNA_ROUTE_AUTO_REPAIR true]} {antenna_repair} else {antenna_check}
    } result opts]
    if {$code} {dict set ::tt_antenna::last status ERROR; dict set ::tt_antenna::last error $result}
    if {$code || [dict get $::tt_antenna::last status] ne "PASS"} {
        puts "WARNING: STAGE05 ANTENNA [dict get $::tt_antenna::last status]; inspect antenna_status and reports."
        if {[::tt_antenna::setting ANTENNA_ROUTE_FATAL false]} {
            if {$code} {return -options $opts $result}
            error "Stage05 antenna verification did not pass."
        }
    }
}
