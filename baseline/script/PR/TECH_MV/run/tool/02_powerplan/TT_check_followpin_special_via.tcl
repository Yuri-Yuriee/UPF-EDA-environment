# Runtime adapter preserves the historical logical source path.
if {[info exists ::TECH_MV_RUNTIME_ROOT]} {
    info script [file join $::TECH_MV_RUNTIME_ROOT run/tool/02_powerplan/TT_check_followpin_special_via.tcl]
}
# =============================================================================
# TT_check_followpin_special_via.tcl
# VERSION: V1.0
#
# PURPOSE
#   Check every special_wire whose .shape == followpin.
#   A followpin wire PASSES only when at least one special_via:
#     1) is physically on the followpin wire rectangle,
#     2) belongs to the same net,
#     3) has .shape == followpin.
#
#   If any followpin has no such special_via:
#     - print violation information,
#     - write a report,
#     - select/highlight the violating followpin special_wire objects in GUI,
#     - suspend for inspection; native resume accepts the recorded checkpoint.
#
# SOURCE POLICY
#   source this file => definitions only. No DB modification.
#
# USAGE
#   source run/tool/02_powerplan/TT_check_followpin_special_via.tcl
#   TT_FOLLOWPIN_VIA_CHECK
#   TT_FOLLOWPIN_VIA_CHECK -nets {WDT_prim_PG.power VSS}
# =============================================================================

namespace eval ::TT_FPVIA {
    variable VERSION "V1.0"
    variable POINT_TOL 0.001
    variable REPORT_FILE "reports/TT_followpin_without_special_via.rpt"
    variable MAX_CONSOLE_VIOLATIONS 50
}

proc ::TT_FPVIA::bool {v} {
    set x [string tolower [string trim $v]]
    return [expr {$x in {1 true yes on}}]
}

proc ::TT_FPVIA::get_attr {obj attr {default ""}} {
    set v $default
    catch {set v [get_db $obj $attr]}
    return $v
}

proc ::TT_FPVIA::normalize_rect {raw} {
    if {[llength $raw] == 1 && [llength [lindex $raw 0]] == 4} {
        set raw [lindex $raw 0]
    }
    if {[llength $raw] != 4} { return {} }
    lassign $raw x1 y1 x2 y2
    return [list [expr {double($x1)}] [expr {double($y1)}] \
                 [expr {double($x2)}] [expr {double($y2)}]]
}

proc ::TT_FPVIA::normalize_point {raw} {
    if {[llength $raw] == 1 && [llength [lindex $raw 0]] == 2} {
        set raw [lindex $raw 0]
    }
    if {[llength $raw] != 2} { return {} }
    lassign $raw x y
    return [list [expr {double($x)}] [expr {double($y)}]]
}

proc ::TT_FPVIA::point_in_rect {point rect} {
    variable POINT_TOL
    if {[llength $point] != 2 || [llength $rect] != 4} { return false }
    lassign $point px py
    lassign $rect x1 y1 x2 y2
    set llx [expr {min($x1,$x2) - $POINT_TOL}]
    set lly [expr {min($y1,$y2) - $POINT_TOL}]
    set urx [expr {max($x1,$x2) + $POINT_TOL}]
    set ury [expr {max($y1,$y2) + $POINT_TOL}]
    return [expr {$px >= $llx && $px <= $urx && $py >= $lly && $py <= $ury}]
}

proc ::TT_FPVIA::shape_is_followpin {shape} {
    return [string equal -nocase [string trim $shape] "followpin"]
}

proc ::TT_FPVIA::net_selected {net_name filter_nets} {
    if {[llength $filter_nets] == 0} { return true }
    return [expr {[lsearch -exact $filter_nets $net_name] >= 0}]
}

proc ::TT_FPVIA::find_followpin_wires {filter_nets} {
    set die [get_db current_design .bbox]
    if {$die eq ""} { error "TT_FPVIA: current_design .bbox is empty." }

    set all_sw {}
    if {[catch {
        set all_sw [get_obj_in_area -area $die -obj_type special_wire]
    } err]} {
        error "TT_FPVIA: cannot query special_wire: $err"
    }

    set result {}
    foreach sw $all_sw {
        if {[::TT_FPVIA::get_attr $sw .obj_type] ne "special_wire"} { continue }
        if {![::TT_FPVIA::shape_is_followpin [::TT_FPVIA::get_attr $sw .shape]]} { continue }

        set net_name [::TT_FPVIA::get_attr $sw .net.name]
        if {![::TT_FPVIA::net_selected $net_name $filter_nets]} { continue }
        lappend result $sw
    }
    return $result
}

proc ::TT_FPVIA::wire_has_special_via {sw} {
    set wire_rect [::TT_FPVIA::normalize_rect [::TT_FPVIA::get_attr $sw .rect]]
    if {[llength $wire_rect] != 4} {
        return [dict create pass false reason BAD_WIRE_RECT via "" candidates 0]
    }

    set wire_net [::TT_FPVIA::get_attr $sw .net.name]

    set local_vias {}
    if {[catch {
        set local_vias [get_obj_in_area -area $wire_rect -obj_type special_via]
    } err]} {
        return [dict create pass false reason AREA_QUERY_FAILED error $err via "" candidates 0]
    }

    set checked 0
    foreach via $local_vias {
        if {[::TT_FPVIA::get_attr $via .obj_type] ne "special_via"} { continue }
        incr checked

        if {[::TT_FPVIA::get_attr $via .net.name] ne $wire_net} { continue }
        if {![::TT_FPVIA::shape_is_followpin [::TT_FPVIA::get_attr $via .shape]]} { continue }

        set via_point [::TT_FPVIA::normalize_point [::TT_FPVIA::get_attr $via .point]]
        if {![::TT_FPVIA::point_in_rect $via_point $wire_rect]} { continue }

        return [dict create pass true reason PASS via $via candidates $checked]
    }

    return [dict create pass false reason NO_FOLLOWPIN_SPECIAL_VIA via "" candidates $checked]
}

proc TT_FOLLOWPIN_VIA_CHECK {args} {
    set filter_nets {}
    set highlight true
    set report_file $::TT_FPVIA::REPORT_FILE

    set i 0
    while {$i < [llength $args]} {
        set opt [lindex $args $i]
        switch -- $opt {
            -nets {
                incr i
                if {$i >= [llength $args]} { error "-nets requires a Tcl list." }
                set filter_nets [lindex $args $i]
            }
            -highlight {
                incr i
                if {$i >= [llength $args]} { error "-highlight requires 0/1." }
                set highlight [::TT_FPVIA::bool [lindex $args $i]]
            }
            -report {
                incr i
                if {$i >= [llength $args]} { error "-report requires a filename." }
                set report_file [lindex $args $i]
            }
            -help {
                puts "TT_FOLLOWPIN_VIA_CHECK"
                puts "  TT_FOLLOWPIN_VIA_CHECK"
                puts "  TT_FOLLOWPIN_VIA_CHECK -nets {WDT_prim_PG.power VSS}"
                puts "  TT_FOLLOWPIN_VIA_CHECK -highlight 0"
                puts "  TT_FOLLOWPIN_VIA_CHECK -report reports/my_followpin_check.rpt"
                return 0
            }
            default { error "Unknown option '$opt'. Use -help." }
        }
        incr i
    }

    puts ""
    puts "======================================================================"
    puts " TT FOLLOWPIN SPECIAL-VIA CHECK"
    puts "======================================================================"
    puts "Version              : $::TT_FPVIA::VERSION"
    puts "Net filter           : [expr {[llength $filter_nets] ? $filter_nets : "ALL"}]"
    puts "Required wire shape  : followpin"
    puts "Required via type    : special_via"
    puts "Required via shape   : followpin"
    puts "Same-net check       : ENABLED"
    puts "Physical check       : via .point inside wire .rect"
    puts "Highlight on failure : $highlight"
    puts "Report               : $report_file"
    puts "----------------------------------------------------------------------"

    set followpins [::TT_FPVIA::find_followpin_wires $filter_nets]
    set total [llength $followpins]
    puts "Followpin wires found: $total"

    if {$total == 0} {
        error "TT_FPVIA: no followpin special_wire found for requested scope."
    }

    set report_dir [file dirname $report_file]
    if {$report_dir ne "." && ![file exists $report_dir]} {
        catch {file mkdir $report_dir}
    }

    set fp [open $report_file w]
    puts $fp "TT FOLLOWPIN SPECIAL-VIA CHECK"
    puts $fp "Version: $::TT_FPVIA::VERSION"
    puts $fp "Filter nets: $filter_nets"
    puts $fp ""

    set violations {}
    set pass_count 0
    set query_fail_count 0
    set bad_rect_count 0
    set console_vio 0

    foreach sw $followpins {
        set result [::TT_FPVIA::wire_has_special_via $sw]
        if {[dict get $result pass]} {
            incr pass_count
            continue
        }

        lappend violations $sw
        set reason [dict get $result reason]
        if {$reason eq "AREA_QUERY_FAILED"} { incr query_fail_count }
        if {$reason eq "BAD_WIRE_RECT"} { incr bad_rect_count }

        set net   [::TT_FPVIA::get_attr $sw .net.name]
        set layer [::TT_FPVIA::get_attr $sw .layer.name]
        set rect  [::TT_FPVIA::get_attr $sw .rect]
        set path  [::TT_FPVIA::get_attr $sw .path]
        set ncan  [dict get $result candidates]

        puts $fp "VIOLATION"
        puts $fp "  object     : $sw"
        puts $fp "  net        : $net"
        puts $fp "  layer      : $layer"
        puts $fp "  rect       : $rect"
        puts $fp "  path       : $path"
        puts $fp "  reason     : $reason"
        puts $fp "  via_query_candidates : $ncan"
        puts $fp ""

        if {$console_vio < $::TT_FPVIA::MAX_CONSOLE_VIOLATIONS} {
            puts "VIOLATION: $sw"
            puts "  NET    = $net"
            puts "  LAYER  = $layer"
            puts "  RECT   = $rect"
            puts "  REASON = $reason"
            incr console_vio
        }
    }

    set vio_count [llength $violations]

    puts $fp "SUMMARY"
    puts $fp "  followpin_total = $total"
    puts $fp "  pass            = $pass_count"
    puts $fp "  violations      = $vio_count"
    puts $fp "  bad_rect        = $bad_rect_count"
    puts $fp "  area_query_fail = $query_fail_count"
    close $fp

    puts ""
    puts "----------------------------------------------------------------------"
    puts " SUMMARY"
    puts "----------------------------------------------------------------------"
    puts "Followpin total       : $total"
    puts "PASS with special via : $pass_count"
    puts "VIOLATIONS            : $vio_count"
    puts "Bad wire rect         : $bad_rect_count"
    puts "Area query failures   : $query_fail_count"
    puts "Report                : $report_file"

    if {$vio_count > 0} {
        if {$highlight} {
            catch {deselect_obj -all}
            if {[catch {select_obj $violations} sel_err]} {
                puts "WARN: GUI selection/highlight failed: $sel_err"
            } else {
                puts "GUI                    : violating followpins SELECTED/HIGHLIGHTED"
            }
        }

        puts "RESULT                 : FAIL"
        puts "======================================================================"
        if {![llength [info commands suspend]]} {
            error "Followpin confirmation requires native Innovus suspend; report: $report_file"
        }
        puts "ACTION REQUIRED: Followpin special-via violations need confirmation."
        puts "Report: $report_file"
        puts "Inspect/fix the highlighted wires, then type resume to accept and continue."
        puts "Resume does not rerun this check; unresolved violations are not marked PASS."
        if {[llength [info commands tech_mv_checkpoint_tools]]} {
            tech_mv_checkpoint_tools 02 after_followpin_special_via
        }
        suspend
        puts "WARNING: Followpin checkpoint accepted; $vio_count violations were recorded before suspend."
        return $vio_count
    }

    puts "RESULT                 : PASS"
    puts "======================================================================"
    return 0
}

puts "INFO: Loaded TT_check_followpin_special_via.tcl"
puts "INFO: VERSION = $::TT_FPVIA::VERSION"
puts "INFO: SOURCE-SAFE: no check is run until TT_FOLLOWPIN_VIA_CHECK is called."
puts "INFO: Run: TT_FOLLOWPIN_VIA_CHECK"
