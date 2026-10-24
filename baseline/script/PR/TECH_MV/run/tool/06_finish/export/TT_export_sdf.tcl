# Runtime adapter preserves the historical logical source path.
if {[info exists ::TECH_MV_RUNTIME_ROOT]} {
    info script [file join $::TECH_MV_RUNTIME_ROOT run/tool/06_finish/export/TT_export_sdf.tcl]
}

write_sdf [file join $OUTPUT_DIR ${TOP_MODULE}_min.sdf] \
    -max_view $::MMMC_HOLD_VIEW \
    -typical_view $::MMMC_HOLD_VIEW \
    -min_view $::MMMC_HOLD_VIEW \
    -map_removal \
    -recompute_delaycal

write_sdf [file join $OUTPUT_DIR ${TOP_MODULE}_max.sdf] \
    -max_view $::MMMC_SETUP_VIEW \
    -typical_view $::MMMC_SETUP_VIEW \
    -min_view $::MMMC_SETUP_VIEW \
    -map_removal \
    -recompute_delaycal
