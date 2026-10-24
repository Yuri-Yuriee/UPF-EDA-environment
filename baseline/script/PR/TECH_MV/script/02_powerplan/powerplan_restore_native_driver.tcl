# Runtime adapter preserves the historical logical source path.
if {[info exists ::TECH_MV_RUNTIME_ROOT]} {
    info script [file join $::TECH_MV_RUNTIME_ROOT run/tool/02_powerplan/TT_powerplan_restore_native_driver.tcl]
} else {
    info script [file normalize [file join [file dirname [info script]] .. .. run/tool/02_powerplan/TT_powerplan_restore_native_driver.tcl]]
}
# =============================================================================
# TT_powerplan_restore_native_driver.tcl
# TECH_MV PowerPlan restore native-resume driver V1.7.1
#
# This file MUST be sourced at global scope.  It intentionally owns the native
# suspend boundary so restore behaves like a normal sourced flow:
#   read_db -> source driver -> suspend -> resume -> continuation.
# =============================================================================

if {![info exists ::PP_NATIVE_RESTORE_POINT] || $::PP_NATIVE_RESTORE_POINT eq ""} {
    error "PowerPlan native restore driver was sourced without PP_NATIVE_RESTORE_POINT."
}
set _pp_native_point $::PP_NATIVE_RESTORE_POINT
set _pp_native_info [pp_checkpoint_info $_pp_native_point]
set _pp_native_type [dict get $_pp_native_info type]
set _pp_native_continuation [dict get $_pp_native_info continuation]

switch -- $_pp_native_type {
    NORMAL {
        puts ""
        puts "======================================================================"
        puts " RESTORED CHECKPOINT : READY TO RESUME"
        puts "======================================================================"
        puts "Point : $_pp_native_point"
        puts "DB    : $::PP_RESTORED_DB"
        puts "State : restored exactly at this durable phase boundary"
        puts ""
        puts "Inspect the restored DB if needed, then type native Innovus:"
        puts "  resume"
        puts ""
        puts "Only after resume will the Tcl AFTER this checkpoint execute."
        puts "======================================================================"
        flush stdout

        set ::PP_RESTORE_STATE suspended
        if {[llength [info commands tech_mv_checkpoint_tools]]} { tech_mv_checkpoint_tools {02_powerplan} {TT_powerplan_restore_native_driver} }
        suspend

        puts "INFO: Native resume received for restored checkpoint '$_pp_native_point'."
        set ::PP_RESTORE_STATE continuing
        pp_dispatch_normal_continuation $_pp_native_point $_pp_native_continuation
        pp_clear_restore_state
    }
    SUSPEND {
        set ::PP_RESTORE_STATE suspended
        pp_dispatch_suspend_continuation $_pp_native_point $_pp_native_continuation
        pp_clear_restore_state
    }
    DRC_SUSPEND {
        set ::PP_RESTORE_STATE suspended
        pp_restore_drc_suspend $_pp_native_point $_pp_native_info
        pp_clear_restore_state
    }
    TERMINAL {
        set ::PP_RESTORE_STATE terminal
        puts "INFO: '$_pp_native_point' is the Stage-02 flow tail; no continuation remains."
    }
    default {
        set ::PP_RESTORE_STATE error
        error "Unsupported PowerPlan restore type '$_pp_native_type' for '$_pp_native_point'."
    }
}

unset -nocomplain ::PP_NATIVE_RESTORE_POINT ::PP_NATIVE_RESTORE_DRIVER
unset -nocomplain _pp_native_point _pp_native_info _pp_native_type _pp_native_continuation
