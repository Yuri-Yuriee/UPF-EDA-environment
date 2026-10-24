if {![info exists ::TECH_MV_RUNTIME_ROOT]} {
    set ::TECH_MV_RUNTIME_ROOT [file normalize [pwd]]
}
# Runtime adapter preserves the historical logical source path.
if {[info exists ::TECH_MV_RUNTIME_ROOT]} {
    info script [file join $::TECH_MV_RUNTIME_ROOT run/check_setup.tcl]
}
# =============================================================================
# Check TECH MV setup paths
# =============================================================================
# Always reload the complete TECH_MV runtime/configuration for this run entry.
# Resolve build_PR/init.setup from this file; do not depend on script_search_path.
set _tech_run_file [file normalize [info script]]
set _tech_init_setup [file normalize [file join [file dirname $_tech_run_file] .. init.setup]]
if {![file isfile $_tech_init_setup]} {
    error "TECH_MV runtime init.setup not found: $_tech_init_setup"
}
source $_tech_init_setup
unset _tech_run_file
unset _tech_init_setup

set error_count 0

set required_mmmc_vars {
    MMMC_LVL_LEVEL_01_H2L_LEVEL_02_LIB_WC_FILES
    MMMC_LVL_LEVEL_02_L2H_LEVEL_01_LIB_WC_FILES
    MMMC_LVL_LEVEL_01_H2L_LEVEL_02_LIB_BC_FILES
    MMMC_LVL_LEVEL_02_L2H_LEVEL_01_LIB_BC_FILES
}
foreach var_name $required_mmmc_vars {
    if {![info exists ::$var_name]} {
        puts "ERROR missing MMMC variable: $var_name"
        incr error_count
    } else {
        puts "PASS  MMMC variable              $var_name"
    }
}

proc check_path {label path expected_type} {
    upvar error_count error_count
    if {$expected_type eq "dir"} {
        set ok [file isdirectory $path]
    } else {
        set ok [file isfile $path]
    }
    if {$ok} {
        puts [format "PASS  %-30s %s" $label $path]
    } else {
        puts [format "ERROR %-30s %s" $label $path]
        incr error_count
    }
}

check_path SETUP_DIR              $SETUP_DIR dir
check_path RUN_DIR                $RUN_DIR dir
check_path TOOL_DIR               $TOOL_DIR dir
check_path SCRIPT_DIR             $SCRIPT_DIR dir
check_path CONFIG_FILE            $CONFIG_FILE file
check_path CONFIG_DIR             $CONFIG_DIR dir
foreach cfg $CONFIG_COMPONENT_FILES { check_path CONFIG_COMPONENT $cfg file }
check_path GLOBAL_NET_FILE        $GLOBAL_NET_FILE file
check_path MMMC_FILE              $MMMC_FILE file
check_path NETLIST_FILE           $NETLIST_FILE file
check_path SDC_FILE               $SDC_FILE file
check_path IO_FILE                $IO_FILE file

foreach upf $UPF_SOURCE_FILES {
    check_path UPF_SOURCE $upf file
}
foreach lef $LEF_FILES {
    check_path LEF $lef file
}
foreach lib_list [list \
    $MMMC_CORE_LEVEL_01_LIB_WC_FILES \
    $MMMC_CORE_LEVEL_02_LIB_WC_FILES \
    $MMMC_IO_LIB_WC_FILES \
    $MMMC_LVL_LEVEL_01_H2L_LEVEL_02_LIB_WC_FILES \
    $MMMC_LVL_LEVEL_02_L2H_LEVEL_01_LIB_WC_FILES \
    $MMMC_PM_LEVEL_01_LIB_WC_FILES \
    $MMMC_PM_LEVEL_02_LIB_WC_FILES \
    $MMMC_MEM_LIB_WC_FILES \
    $MMMC_CORE_LEVEL_01_LIB_BC_FILES \
    $MMMC_CORE_LEVEL_02_LIB_BC_FILES \
    $MMMC_IO_LIB_BC_FILES \
    $MMMC_LVL_LEVEL_01_H2L_LEVEL_02_LIB_BC_FILES \
    $MMMC_LVL_LEVEL_02_L2H_LEVEL_01_LIB_BC_FILES \
    $MMMC_PM_LEVEL_01_LIB_BC_FILES \
    $MMMC_PM_LEVEL_02_LIB_BC_FILES \
    $MMMC_MEM_LIB_BC_FILES \
] {
    foreach lib $lib_list {
        check_path LIB $lib file
    }
}
check_path MMMC_QRC_BEST_FILE  $MMMC_QRC_BEST_FILE file
check_path MMMC_QRC_WORST_FILE $MMMC_QRC_WORST_FILE file
check_path PG_LIBRARY_QRC_FILE $PG_LIBRARY_QRC_FILE file
check_path STREAM_OUT_MAP_SOURCE $STREAM_OUT_MAP_SOURCE file
foreach gds $STREAM_MERGE_GDS_FILES {
    check_path STREAM_MERGE_GDS $gds file
}

if {$error_count > 0} {
    error "$error_count setup path check(s) failed"
}
puts "All setup path checks passed."
