if {![info exists ::TECH_MV_RUNTIME_ROOT]} {
    set ::TECH_MV_RUNTIME_ROOT [file normalize [pwd]]
}
# Runtime adapter preserves the historical logical source path.
if {[info exists ::TECH_MV_RUNTIME_ROOT]} {
    info script [file join $::TECH_MV_RUNTIME_ROOT run/early_rail_analysis.tcl]
}
source [file join $::TECH_MV_RUNTIME_ROOT run tool 02_powerplan reports TT_early_rail_analysis.tcl]
