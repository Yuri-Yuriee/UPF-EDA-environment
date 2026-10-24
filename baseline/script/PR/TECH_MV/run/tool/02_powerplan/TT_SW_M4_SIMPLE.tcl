# Runtime adapter preserves the historical logical source path.
if {[info exists ::TECH_MV_RUNTIME_ROOT]} {
    info script [file join $::TECH_MV_RUNTIME_ROOT run/tool/02_powerplan/TT_SW_M4_SIMPLE.tcl]
}
source [file join [file dirname [info script]] TT_SW_M4_tools.tcl]
