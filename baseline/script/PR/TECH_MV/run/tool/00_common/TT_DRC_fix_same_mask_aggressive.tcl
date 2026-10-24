# Runtime adapter preserves the historical logical source path.
if {[info exists ::TECH_MV_RUNTIME_ROOT]} {
    info script [file join $::TECH_MV_RUNTIME_ROOT run/tool/00_common/TT_DRC_fix_same_mask_aggressive.tcl]
}
source [file join $::TECH_MV_RUNTIME_ROOT .. script PR TECH_MV script 00_common drc DRC_fix_same_mask_aggressive.tcl]
