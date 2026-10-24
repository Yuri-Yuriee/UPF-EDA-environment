# Runtime adapter preserves the historical logical source path.
if {[info exists ::TECH_MV_RUNTIME_ROOT]} {
    info script [file join $::TECH_MV_RUNTIME_ROOT run/tool/02_powerplan/power_switch/TT_SW_M4_CONNECTIVITY_GATE.tcl]
} else {
    info script [file normalize [file join [file dirname [info script]] .. .. .. run/tool/02_powerplan/power_switch/TT_SW_M4_CONNECTIVITY_GATE.tcl]]
}
# Load Library setting definitions only; no APR action or config reload.
if {![llength [info commands ::tech_mv_library_value]]} {
    if {[info exists ::TOOL_DIR]} {
        source -quiet [file join $::TECH_MV_RUNTIME_ROOT .. script PR TECH_MV script 00_common private_parameter_config.tcl]
    } else {
        source -quiet [file join $::TECH_MV_RUNTIME_ROOT .. script PR TECH_MV script 00_common private_parameter_config.tcl]
    }
}
# PUBLIC_EXPORT_REVIEW_REQUIRED: residual technology candidates require manual review.
# TT_SW_M4_CONNECTIVITY_GATE V12 (Common UI)
# Read-only verification. No global-net or DB shape modifications.
namespace eval ::TT_SW_M4_CONN { variable version V12 }
proc ::TT_SW_M4_CONN::check {{outdir "./reports/02_powerplan/sw_m4/TT_SW_M4_CONN_V12"}} {
    if {![llength [info commands check_connectivity]]} {
        error "check_connectivity is unavailable; run 'info commands *connectiv*' and provide command help"
    }
    file mkdir $outdir
    set net [::tech_mv_library_value SW_LANDING_TARGET_NET]
    set report [file join $outdir [::tech_mv_library_value SW_LANDING_TARGET_NET]_special_connectivity.rpt]
    puts "TT_SW_M4_CONN_V12 START net=$net type=special report=$report"
    if {[catch {check_connectivity -nets [list $net] -type special -out_file $report -error 100000 -warning 100000} msg opt]} {
        puts "CONNECTIVITY=ERROR reason=$msg"
        return -options $opt $msg
    }
    if {![file exists $report]} {
        error "CONNECTIVITY=UNKNOWN: no report generated at $report; cannot claim PASS"
    }
    set f [open $report r]; set body [read $f]; close $f
    set issues {}
    foreach line [split $body "\n"] {
        if {[regexp -nocase {^[ \t]*([1-9][0-9]*)[ \t]+Problem\(s\)} $line]} {lappend issues $line}
        if {[regexp -nocase [::tech_mv_library_value SW_GATE_NET_ISSUE_PATTERN] $line]} {lappend issues $line}
    }
    set explicit_zero [regexp -nocase {Found no problems or warnings|0[ \t]+Problem\(s\)} "$body\n$msg"]
    if {[llength $issues]} {
        puts "CONNECTIVITY=FAIL issue_lines=[llength $issues] report=$report"
        return -code error "[::tech_mv_library_value SW_LANDING_TARGET_NET] connectivity violations; inspect $report"
    }
    if {!$explicit_zero} {
        puts "CONNECTIVITY=REVIEW_REQUIRED: report has no recognized zero-problem summary; inspect $report"
        return -code error "Cannot certify connectivity from report format"
    }
    puts "CONNECTIVITY=SPECIAL_CHECK_PASS net=$net report=$report"
    puts "NOTE: special connectivity is not full PG signoff; verify SW [::tech_mv_library_value SW_CONNECTIVITY_DIAGNOSTIC_PIN], shorts, DRC and LVS separately."
    return $report
}
proc ::TT_SW_M4_CONN::post_rail_gate {{outdir "./reports/02_powerplan/sw_m4/TT_SW_M4_CONN_V12"}} {
    if {![llength [info commands ::TT_SW_M4::v11_preflight]]} {
        error "V11 SW M4 repair not sourced; source ../script/PR/TECH_MV/script/02_powerplan/power_switch/SW_M4_LANDING_REPAIR.tcl first"
    }
    file mkdir $outdir
    set pre [::TT_SW_M4::v11_preflight [file join [file normalize $outdir] preflight_after_rail.tsv]]
    foreach key {candidates skipped_unsafe} {
        if {[dict get $pre $key] != 0} {error "V11 INCOMPLETE: $key=[dict get $pre $key]; stop flow before connectivity acceptance"}
    }
    return [::TT_SW_M4_CONN::check $outdir]
}
puts "TT_SW_M4_CONNECTIVITY_GATE V12 loaded. Use ::TT_SW_M4_CONN::check or ::TT_SW_M4_CONN::post_rail_gate"
