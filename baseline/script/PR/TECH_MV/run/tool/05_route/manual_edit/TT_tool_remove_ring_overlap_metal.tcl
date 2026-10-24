# Runtime adapter preserves the historical logical source path.
if {[info exists ::TECH_MV_RUNTIME_ROOT]} {
    info script [file join $::TECH_MV_RUNTIME_ROOT run/tool/05_route/manual_edit/TT_tool_remove_ring_overlap_metal.tcl]
}
source [file join [file dirname [info script]] .. drc TT_tool_remove_ring_overlap_metal.tcl]
