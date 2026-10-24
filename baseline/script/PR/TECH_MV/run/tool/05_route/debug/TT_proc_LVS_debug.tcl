# Runtime adapter preserves the historical logical source path.
if {[info exists ::TECH_MV_RUNTIME_ROOT]} {
    info script [file join $::TECH_MV_RUNTIME_ROOT run/tool/05_route/debug/TT_proc_LVS_debug.tcl]
}
source [file join [file dirname [info script]] .. .. 99_debug TT_proc_LVS_debug.tcl]
