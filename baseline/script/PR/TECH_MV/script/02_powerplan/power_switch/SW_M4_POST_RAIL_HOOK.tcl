# Runtime adapter preserves the historical logical source path.
if {[info exists ::TECH_MV_RUNTIME_ROOT]} {
    info script [file join $::TECH_MV_RUNTIME_ROOT run/tool/02_powerplan/power_switch/TT_SW_M4_POST_RAIL_HOOK.tcl]
} else {
    info script [file normalize [file join [file dirname [info script]] .. .. .. run/tool/02_powerplan/power_switch/TT_SW_M4_POST_RAIL_HOOK.tcl]]
}
# Source this ONLY after 2nd rail generation and V11 repair are complete.
# Requires script sourcing from build_PR root, matching existing run/tool convention.
source ../script/PR/TECH_MV/script/02_powerplan/power_switch/SW_M4_LANDING_REPAIR.tcl
source ../script/PR/TECH_MV/script/02_powerplan/power_switch/SW_M4_CONNECTIVITY_GATE.tcl
::TT_SW_M4_CONN::post_rail_gate
