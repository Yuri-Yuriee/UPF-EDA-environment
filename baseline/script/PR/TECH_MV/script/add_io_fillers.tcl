# Load definitions only; no APR action or setup reload is performed here.
if {![llength [info commands ::tech_mv_library_value]]} {
    if {[info exists ::TOOL_DIR]} {
        source -quiet [file join $::TECH_MV_RUNTIME_ROOT .. script PR TECH_MV script 00_common private_parameter_config.tcl]
    } else {
        source -quiet [file join $::TECH_MV_RUNTIME_ROOT .. script PR TECH_MV script 00_common private_parameter_config.tcl]
    }
}
# TECH IO fillers are physical-only.
# Do NOT derive or create logical connectivity/assignments for IOFILLER*.
add_io_fillers -cells [::tech_mv_library_value LIB_CELL_006] -prefix IOFILLER
add_io_fillers -cells [::tech_mv_library_value LIB_CELL_007] -prefix IOFILLER
add_io_fillers -cells [::tech_mv_library_value LIB_CELL_008] -prefix IOFILLER
add_io_fillers -cells [::tech_mv_library_value LIB_CELL_009] -prefix IOFILLER -fill_any_gap
