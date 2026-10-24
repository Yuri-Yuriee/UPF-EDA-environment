# Runtime adapter preserves the historical logical source path.
if {[info exists ::TECH_MV_RUNTIME_ROOT]} {
    info script [file join $::TECH_MV_RUNTIME_ROOT run/tool/01_floorplan/TT_floorplan_restore_native_driver.tcl]
} else {
    info script [file normalize [file join [file dirname [info script]] .. .. run/tool/01_floorplan/TT_floorplan_restore_native_driver.tcl]]
}
# =============================================================================
# TT_floorplan_restore_native_driver.tcl
# TECH_MV Floorplan restore native-resume driver V1.7.1
#
# This file MUST be sourced at global scope.  It owns the native suspend
# boundary so restore behaves like the normal Stage-01 sourced flow.
# =============================================================================

if {![info exists ::FP_NATIVE_RESTORE_POINT] || $::FP_NATIVE_RESTORE_POINT eq ""} {
    error "Floorplan native restore driver was sourced without FP_NATIVE_RESTORE_POINT."
}
set _fp_native_point $::FP_NATIVE_RESTORE_POINT
set _fp_native_info [fp_checkpoint_info $_fp_native_point]
set _fp_native_type [dict get $_fp_native_info type]
set _fp_native_continuation [dict get $_fp_native_info continuation]

switch -- $_fp_native_type {
    NORMAL {
        puts ""
        puts "======================================================================"
        puts " RESTORED CHECKPOINT : READY TO RESUME"
        puts "======================================================================"
        puts "Point : $_fp_native_point"
        puts "DB    : $::FP_RESTORED_DB"
        puts "State : restored exactly at this durable phase boundary"
        puts ""
        puts "Inspect the restored DB if needed, then type native Innovus:"
        puts "  resume"
        puts ""
        puts "Only after resume will the Tcl AFTER this checkpoint execute."
        puts "======================================================================"
        flush stdout

        set ::FP_RESTORE_STATE suspended
        if {[llength [info commands tech_mv_checkpoint_tools]]} { tech_mv_checkpoint_tools {01_floorplan} {TT_floorplan_restore_native_driver} }
        suspend

        puts "INFO: Native resume received for restored checkpoint '$_fp_native_point'."
        set ::FP_RESTORE_STATE continuing
        fp_dispatch_normal_continuation $_fp_native_point $_fp_native_continuation
        fp_clear_restore_state
    }
    SUSPEND {
        set ::FP_RESTORE_STATE suspended
        fp_dispatch_suspend_continuation $_fp_native_point $_fp_native_continuation
        fp_clear_restore_state
    }
    default {
        set ::FP_RESTORE_STATE error
        error "Unsupported Floorplan restore type '$_fp_native_type' for '$_fp_native_point'."
    }
}

unset -nocomplain ::FP_NATIVE_RESTORE_POINT ::FP_NATIVE_RESTORE_DRIVER
unset -nocomplain _fp_native_point _fp_native_info _fp_native_type _fp_native_continuation
