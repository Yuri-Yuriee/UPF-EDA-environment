# Runtime adapter preserves the historical logical source path.
if {[info exists ::TECH_MV_RUNTIME_ROOT]} {
    info script [file join $::TECH_MV_RUNTIME_ROOT run/tool/02_powerplan/TT_SW_M4_tools.tcl]
}
# PUBLIC_EXPORT_REVIEW_REQUIRED: residual technology candidates require manual review.
# TT SW M4 Simple Commands V13
# Thin public wrappers only. V11/V12 core logic unchanged.
# Load near the installed V11 and V12 files.
namespace eval ::TT_SW_M4_SIMPLE {
    variable tool_dir [file dirname [file normalize [info script]]]
}
proc sw_m4_load {} {
    set d $::TT_SW_M4_SIMPLE::tool_dir
    if {![llength [info commands ::TT_SW_M4::v11_preflight]]} {
        set f [file join $::TECH_MV_RUNTIME_ROOT .. script PR TECH_MV script 02_powerplan power_switch SW_M4_LANDING_REPAIR.tcl]
        if {![file isfile $f]} {error "Missing V11 core: $f"}
        source $f
    }
    if {![llength [info commands ::TT_SW_M4_CONN::check]]} {
        set f [file join $::TECH_MV_RUNTIME_ROOT .. script PR TECH_MV script 02_powerplan power_switch SW_M4_CONNECTIVITY_GATE.tcl]
        if {![file isfile $f]} {error "Missing V12 connectivity gate: $f"}
        source $f
    }
}
proc sw_m4_check {} {
    sw_m4_load
    return [::TT_SW_M4::v11_preflight]
}
proc sw_m4_repair {{limit 0}} {
    if {![string is integer -strict $limit] || $limit < 0} {
        error "Usage: sw_m4_repair ?limit?  (0=all); save a restorable DB checkpoint first"
    }
    sw_m4_load
    return [::TT_SW_M4::v11_apply I_HAVE_RESTORABLE_DB_CHECKPOINT $limit]
}
proc sw_m4_connectivity {} {
    sw_m4_load
    return [::TT_SW_M4_CONN::check]
}
proc sw_m4_gate {} {
    sw_m4_load
    return [::TT_SW_M4_CONN::post_rail_gate]
}
puts "SW M4 V13 commands: sw_m4_check | sw_m4_repair ?limit? | sw_m4_connectivity | sw_m4_gate"
