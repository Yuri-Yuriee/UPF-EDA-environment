# Runtime adapter preserves the historical logical source path.
if {[info exists ::TECH_MV_RUNTIME_ROOT]} {
    info script [file join $::TECH_MV_RUNTIME_ROOT run/tool/01_floorplan/TT_flow_iopad_interface_start.tcl]
}
# =============================================================================
# TECH_MV IOPAD LOCAL INTERFACE START
# Flow-owned startup hook: sourcing this file intentionally (re)starts bridge.
#
# Based on the user's original startup Tcl.
# V125 integration keeps the original GUI helpers and adds only safe bridge
# reload behavior required when the bridge Tcl itself is updated.
# =============================================================================

# If this Innovus session already loaded an older bridge, stop its poll loop
# BEFORE sourcing/redefining the bridge namespace.  This avoids duplicate
# after-poll callbacks after a re-source.
if {[llength [info commands TT_IOPAD_LOCAL_BRIDGE_STOP]] > 0} {
    catch { TT_IOPAD_LOCAL_BRIDGE_STOP }
}

set _tt_iopad_tool_dir [file dirname [file dirname [file normalize [info script]]]]
set _tt_iopad_bridge_tcl \
    [file join $_tt_iopad_tool_dir 01_floorplan TT_tool_iopad_innovus_local_bridge.tcl]

if {![file exists $_tt_iopad_bridge_tcl]} {
    error "Missing IOPAD local bridge Tcl: $_tt_iopad_bridge_tcl"
}

source $_tt_iopad_bridge_tcl

# V129: package-exchange support. Sourced here (Stage00, unconditional) so
# read_GnetPKG is available any time after import - unlike redo_IO, Global
# Net edits are not gated behind the Stage-01 FILL_IN_CELL_BOND_PAD_041 preview suspend
# checkpoint. TT_proc_bond_pad_preview.tcl also sources
# TT_proc_pkg_exchange.tcl defensively on its own, so sourcing it here too
# is redundant-but-harmless if this file is re-sourced later.
source -quiet [file join $_tt_iopad_tool_dir 01_floorplan TT_proc_pkg_exchange.tcl]
source -quiet [file join $_tt_iopad_tool_dir 01_floorplan TT_proc_read_gnetpkg.tcl]
puts "INFO: read_GnetPKG is available (accepts *.tcl or *.GnetPKG.tar)."

if {[info exists ::env(INNOVUS_WORK_DIR)] && $::env(INNOVUS_WORK_DIR) ne ""} {
    set _tt_iopad_bridge_dir \
        [file join $::env(INNOVUS_WORK_DIR) .tt_iopad_bridge]
} else {
    set _tt_iopad_bridge_dir \
        [file join [pwd] .tt_iopad_bridge]
}

TT_IOPAD_LOCAL_BRIDGE_START $_tt_iopad_bridge_dir 100


# =============================================================================
# GUI PROCESS HELPERS
# =============================================================================
# IMPORTANT:
# Do not synchronously execute:
#   ./run/tool/ioPADt/TT_run_iopad_gui.sh
# at the Innovus prompt.
#
# A synchronous child can block the Innovus Tcl event loop, preventing the
# local bridge `after` poll from servicing GUI requests.
#
# Use:
#   TT_IOPAD_GUI_START
# =============================================================================

set ::TTIOPAD_LOCAL::tool_dir $_tt_iopad_tool_dir

# Preserve a GUI PID across a startup Tcl re-source if one was already recorded.
if {![info exists ::TTIOPAD_LOCAL::gui_pid]} {
    set ::TTIOPAD_LOCAL::gui_pid ""
}

proc TT_IOPAD_GUI_START {} {
    set launcher \
        [file join $::TTIOPAD_LOCAL::tool_dir ioPADt TT_run_iopad_gui.sh]

    if {![file exists $launcher]} {
        error "Missing IOPAD GUI launcher: $launcher"
    }

    if {![file readable $launcher]} {
        error "IOPAD GUI launcher is not readable: $launcher"
    }

    # We invoke the launcher explicitly through /bin/bash below, therefore an
    # executable bit is not required.  Do not reject a valid launcher merely
    # because archive/install permissions changed.
    if {![file executable $launcher]} {
        puts "**WARNING: IOPAD GUI launcher is not executable; using /bin/bash explicitly: $launcher"
    }

    set bridge_dir $::TTIOPAD_LOCAL::bridge_dir

    if {$bridge_dir eq "" || !$::TTIOPAD_LOCAL::running} {
        error "IOPAD local bridge is not running. Re-source run/tool/01_floorplan/TT_flow_iopad_interface_start.tcl first."
    }

    set log_path \
        [file join $bridge_dir TT_iopad_gui_launcher.log]

    # Detached background child: Innovus prompt returns immediately and the
    # Tcl event loop remains free to service TTIOPAD_LOCAL::poll.
    set pids [exec /bin/bash $launcher > $log_path 2>@1 &]

    set ::TTIOPAD_LOCAL::gui_pid [lindex $pids 0]

    puts ""
    puts "======================================================================"
    puts " TECH_MV IOPAD GUI START"
    puts "======================================================================"
    puts "PID          : $::TTIOPAD_LOCAL::gui_pid"
    puts "Launcher     : $launcher"
    puts "Bridge dir   : $bridge_dir"
    puts "Launcher log : $log_path"
    puts "Mode         : DETACHED"
    puts "======================================================================"

    return $::TTIOPAD_LOCAL::gui_pid
}

proc TT_IOPAD_GUI_STATUS {} {
    set pid $::TTIOPAD_LOCAL::gui_pid

    if {$pid eq ""} {
        puts "TT_IOPAD_GUI: no PID recorded in this Innovus session."
        return 0
    }

    if {[catch {
        exec /bin/kill -0 $pid
    }]} {
        puts "TT_IOPAD_GUI: NOT RUNNING pid=$pid"
        return 0
    }

    puts "TT_IOPAD_GUI: RUNNING pid=$pid"
    return 1
}

proc TT_IOPAD_GUI_STOP {} {
    set pid $::TTIOPAD_LOCAL::gui_pid

    if {$pid eq ""} {
        puts "TT_IOPAD_GUI: no PID recorded."
        return
    }

    if {[catch {
        exec /bin/kill $pid
    } msg]} {
        puts "**WARNING: cannot stop TT_IOPAD_GUI pid=$pid : $msg"
    } else {
        puts "TT_IOPAD_GUI stopped pid=$pid"
    }

    set ::TTIOPAD_LOCAL::gui_pid ""
}


unset _tt_iopad_tool_dir
unset _tt_iopad_bridge_tcl
unset _tt_iopad_bridge_dir
