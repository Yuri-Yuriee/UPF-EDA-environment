# Load definitions only; no APR action or setup reload is performed here.
if {![llength [info commands ::tech_mv_library_value]]} {
    if {[info exists ::TOOL_DIR]} {
        source -quiet [file join $::TECH_MV_RUNTIME_ROOT .. script PR TECH_MV script 00_common private_parameter_config.tcl]
    } else {
        source -quiet [file join $::TECH_MV_RUNTIME_ROOT .. script PR TECH_MV script 00_common private_parameter_config.tcl]
    }
}
puts "User script [info script]"
# Method 1: foreach; preferred implementation
create_inst -name IO_PG1    -base_cell [::tech_mv_library_value IOPAD_PG_PLACEMENT_MASTER_07]
create_inst -name IO_PG2    -base_cell [::tech_mv_library_value IOPAD_PG_PLACEMENT_MASTER_06]
create_inst -name IO_PG3    -base_cell [::tech_mv_library_value IOPAD_PG_PLACEMENT_MASTER_07]
create_inst -name IO_PG4    -base_cell [::tech_mv_library_value IOPAD_PG_PLACEMENT_MASTER_06]
create_inst -name CORNERTL  -base_cell [::tech_mv_library_value IOPAD_PG_PLACEMENT_MASTER_01]
create_inst -name CORNERTR  -base_cell [::tech_mv_library_value IOPAD_PG_PLACEMENT_MASTER_01]
create_inst -name CORNERBL  -base_cell [::tech_mv_library_value IOPAD_PG_PLACEMENT_MASTER_01]
create_inst -name CORNERBR  -base_cell [::tech_mv_library_value IOPAD_PG_PLACEMENT_MASTER_01]
connect_pin -inst IO_PG1   -pin [::tech_mv_library_value LIB_PIN_003] -net io_rte
connect_pin -inst IO_PG2   -pin [::tech_mv_library_value LIB_PIN_003] -net io_rte
connect_pin -inst IO_PG3   -pin [::tech_mv_library_value LIB_PIN_003] -net io_rte
connect_pin -inst IO_PG4   -pin [::tech_mv_library_value LIB_PIN_003] -net io_rte
connect_pin -inst CORNERTL -pin [::tech_mv_library_value LIB_PIN_003] -net io_rte
connect_pin -inst CORNERTR -pin [::tech_mv_library_value LIB_PIN_003] -net io_rte
connect_pin -inst CORNERBL -pin [::tech_mv_library_value LIB_PIN_003] -net io_rte
connect_pin -inst CORNERBR -pin [::tech_mv_library_value LIB_PIN_003] -net io_rte

foreach pp $POWER_PORT_NETS {
    puts "Current power domain = $pp"
    create_inst -name CORE_${pp}_PG1  -base_cell [::tech_mv_library_value IOPAD_PG_PLACEMENT_MASTER_05]
    create_inst -name CORE_${pp}_PG2  -base_cell [::tech_mv_library_value IOPAD_PG_PLACEMENT_MASTER_04]
    create_inst -name CORE_${pp}_PG3  -base_cell [::tech_mv_library_value IOPAD_PG_PLACEMENT_MASTER_05]
    create_inst -name CORE_${pp}_PG4  -base_cell [::tech_mv_library_value IOPAD_PG_PLACEMENT_MASTER_04]

    connect_pin -inst CORE_${pp}_PG1 -pin [::tech_mv_library_value LIB_PIN_003] -net io_rte
    connect_pin -inst CORE_${pp}_PG2 -pin [::tech_mv_library_value LIB_PIN_003] -net io_rte
    connect_pin -inst CORE_${pp}_PG3 -pin [::tech_mv_library_value LIB_PIN_003] -net io_rte
    connect_pin -inst CORE_${pp}_PG4 -pin [::tech_mv_library_value LIB_PIN_003] -net io_rte
}

foreach pp [lrange $POWER_PORT_NETS 1 end] {
    create_inst -name RAILCUT_${pp}_TOP1        -base_cell [::tech_mv_library_value IOPAD_PG_PLACEMENT_MASTER_03]
    create_inst -name RAILCUT_${pp}_LEFT1       -base_cell [::tech_mv_library_value IOPAD_PG_PLACEMENT_MASTER_02]
    create_inst -name RAILCUT_${pp}_BOTTOM1     -base_cell [::tech_mv_library_value IOPAD_PG_PLACEMENT_MASTER_03]
    create_inst -name RAILCUT_${pp}_RIGHT1      -base_cell [::tech_mv_library_value IOPAD_PG_PLACEMENT_MASTER_02]

    create_inst -name RAILCUT_${pp}_TOP2        -base_cell [::tech_mv_library_value IOPAD_PG_PLACEMENT_MASTER_03]
    create_inst -name RAILCUT_${pp}_LEFT2       -base_cell [::tech_mv_library_value IOPAD_PG_PLACEMENT_MASTER_02]
    create_inst -name RAILCUT_${pp}_BOTTOM2     -base_cell [::tech_mv_library_value IOPAD_PG_PLACEMENT_MASTER_03]
    create_inst -name RAILCUT_${pp}_RIGHT2      -base_cell [::tech_mv_library_value IOPAD_PG_PLACEMENT_MASTER_02]
}
source -quiet [file join $SCRIPT_DIR create_rte_pad.tcl]
