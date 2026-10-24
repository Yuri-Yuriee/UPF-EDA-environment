# Runtime adapter preserves the historical logical source path.
if {[info exists ::TECH_MV_RUNTIME_ROOT]} {
    info script [file join $::TECH_MV_RUNTIME_ROOT run/tool/06_finish/antenna/TT_ANTENNA_FINAL_CHECK.tcl]
}
# Final verification only. Sourcing defines commands; no routing is performed.
if {![llength [info commands ::tt_antenna::check]]} {
    source -quiet [file join $::TOOL_DIR 05_route antenna TT_ANTENNA_REPAIR.tcl]
}
proc antenna_final_check {args} {
    if {$args ni {{} -power}} {error "Usage: antenna_final_check ?-power?"}
    set start [clock milliseconds]
    set results [dict create power [dict create status NOT_RUN]]
    set uses {signal clock}
    if {$args eq "-power"} {lappend uses power}
    foreach use $uses {
        set rc [catch {::tt_antenna::check $use 06 final} result opts]
        if {$rc} {
            dict set results $use [dict create status ERROR error $result]
        } else {
            dict set result status [expr {[dict get $result count] == 0 ? "PASS" : "FAIL"}]
            dict set results $use $result
            dict for {name count} [dict get $result violations] {puts "$use net: $name | Violations: $count"}
        }
    }
    set rc [catch {::tt_antenna::connectivity {} 06 final} result opts]
    if {$rc} {set result [dict create status ERROR error $result]}
    dict set results connectivity $result
    set overall PASS
    foreach use [concat $uses connectivity] {
        if {[dict get $results $use status] eq "ERROR"} {set overall FAIL; break}
        if {[dict get $results $use status] ne "PASS"} {set overall WARNING}
    }
    dict set results overall $overall
    dict set results elapsed_ms [expr {[clock milliseconds]-$start}]
    set summary [file join [::tt_antenna::directory 06] final_summary_[::tt_antenna::token].txt]
    dict set results summary $summary
    set f [open $summary {WRONLY CREAT EXCL}]
    dict for {key value} $results {puts $f "$key: $value"}
    close $f
    set ::tt_antenna::final $results
    puts "=================================================="
    puts " FINAL ANTENNA VERIFICATION"
    foreach use {signal clock power connectivity} {
        set item [dict get $results $use]
        set count {}; if {[dict exists $item count]} {set count " ([dict get $item count] violations)"}
        puts "[string totitle $use]: [dict get $item status]$count"
        if {[dict exists $item details] && [dict get $item details] eq "SUMMARY_ONLY"} {puts "  Details: SUMMARY_ONLY; report declares [dict get $item reported_net_count] violated nets without names."}
        if {[dict exists $item report]} {puts "  Report: [dict get $item report]"}
        if {[dict exists $item elapsed_ms]} {puts "  Elapsed ms: [dict get $item elapsed_ms]"}
        if {[dict exists $item error]} {puts "  Error: [dict get $item error]"}
    }
    puts "Overall: $overall | Elapsed ms: [dict get $results elapsed_ms]"
    puts "Summary: $summary"
    puts "=================================================="
    return $results
}
proc antenna_stage06 {} {
    if {![::tt_antenna::setting ANTENNA_FINISH_ENABLE true]} {puts "ANTENNA: Stage06 disabled."; return}
    set key [list 06 [get_db current_design]]
    if {[dict exists $::tt_antenna::hooks $key]} {puts "ANTENNA: Stage06 hook already attempted; use antenna_final_check for a fresh explicit check."; return}
    dict set ::tt_antenna::hooks $key attempted
    set args {}; if {[::tt_antenna::setting ANTENNA_FINISH_POWER_ENABLE false]} {set args -power}
    set code [catch {antenna_final_check {*}$args} result opts]
    if {$code || [dict get $result overall] ne "PASS"} {
        puts "WARNING: STAGE06 ANTENNA requires review."
        if {[::tt_antenna::setting ANTENNA_FINISH_FATAL false]} {
            if {$code} {return -options $opts $result}
            error "Final antenna verification did not pass."
        }
    }
}
