# Runtime adapter preserves the historical logical source path.
if {[info exists ::TECH_MV_RUNTIME_ROOT]} {
    info script [file join $::TECH_MV_RUNTIME_ROOT run/tool/01_floorplan/TT_proc_read_gnetpkg.tcl]
}
# =============================================================================
# TT_proc_read_gnetpkg.tcl
# =============================================================================
# V129: user-facing command that applies a Global Net Tcl payload, either a
# plain *.tcl file or a *.GnetPKG.tar package (see TT_proc_pkg_exchange.tcl
# for the container/manifest format).
#
#   read_GnetPKG /path/to/global_net.tcl
#   read_GnetPKG /path/to/global_net.GnetPKG.tar
#
# SAFETY / SCOPE (mirrors the ioPADt GUI's own Global-Net-only invariant,
# TT_tool_iopad_gui.py _global_net_apply_wrapper_from_canonical_source):
#   This proc must NEVER call redo_IO or read_io_file, and never touches
#   floorplan/IO placement or FILL_IN_CELL_BOND_PAD_041 preview state. Global Net edits are
#   independent of IO geometry by design - the payload is scanned for those
#   two command names before sourcing, and refused if found, exactly like
#   the GUI already refuses to generate such a payload in the first place.
#
# Unlike redo_IO, this command does NOT require the FILL_IN_CELL_BOND_PAD_041 preview suspend
# checkpoint: Global Net changes can be applied any time after Stage00
# import, so this file is sourced unconditionally (not gated behind
# ENABLE_IO_BOND_PAD_PREVIEW) - see TT_flow_iopad_interface_start.tcl.
#
# APPLY-ONCE GUARD: same sha256-keyed guard as redo_IO's bundled DB patch
# (::TT_PKG_APPLIED_PATCH_SHA256 via tt_pkg_source_once). The GnetPKG.tar
# payload's inline managed create_net block is individually idempotent
# (each create_net is itself existence-guarded), but full command edits
# (global_net_full_cmd_edits in the GUI) are free-form Tcl the tool does not
# fully control, so replaying the exact same payload verbatim is still
# gated defensively rather than assumed always-safe.
# =============================================================================

if {[llength [info commands tt_pkg_is_package]] == 0} {
    if {![info exists ::TOOL_DIR] || $::TOOL_DIR eq ""} {
        error "TT_proc_read_gnetpkg.tcl requires TOOL_DIR to locate TT_proc_pkg_exchange.tcl."
    }
    uplevel #0 [list source -quiet [file join $::TOOL_DIR 01_floorplan TT_proc_pkg_exchange.tcl]]
}

# Refuse to source a Global Net payload that reaches into IO/floorplan
# territory. Returns nothing; errors on violation.
proc tt_gnetpkg_safety_scan {tcl_path} {
    set fh [open $tcl_path r]
    set body [read $fh]
    close $fh
    if {[regexp {(?m)^\s*(?:redo_IO|read_io_file)\b} $body]} {
        error "Safety violation: Global Net payload $tcl_path contains redo_IO/read_io_file. read_GnetPKG refuses to source it."
    }
}

proc read_GnetPKG {args} {
    if {[llength $args] != 1} {
        error "Usage: read_GnetPKG <global_net.tcl_or_GnetPKG.tar>"
    }

    set requested [lindex $args 0]
    set requested_norm [file normalize $requested]
    if {![file exists $requested_norm]} {
        error "read_GnetPKG input does not exist: $requested_norm"
    }

    # patch_path is only ever an AUDIT COPY here (see file header): the
    # payload is self-contained, so this is sourced only if it is present
    # and distinct content the guard has not already seen - it is harmless
    # either way because every create_net inside it is existence-guarded,
    # but we still route it through the same apply-once guard for symmetry
    # and to avoid noisy duplicate log output on repeat loads.
    set gnet_tcl ""
    set patch_path ""

    if {[tt_pkg_is_package $requested_norm]} {
        set pkg [tt_pkg_extract $requested_norm "GNET_PKG"]
        set gnet_tcl [dict get $pkg payload_path]
        set patch_path [dict get $pkg patch_path]
        puts "INFO: read_GnetPKG received GnetPKG.tar: $requested_norm"
        puts "INFO: read_GnetPKG package payload (global_net.tcl) = $gnet_tcl"
        puts "INFO: read_GnetPKG package patch (audit copy)       = $patch_path"
    } else {
        set gnet_tcl $requested_norm
        if {![file isfile $gnet_tcl]} {
            error "read_GnetPKG global_net.tcl does not exist: $gnet_tcl"
        }
    }

    tt_gnetpkg_safety_scan $gnet_tcl

    puts ""
    puts "======================================================================"
    puts " READ GLOBAL NET PACKAGE"
    puts "======================================================================"
    puts "global_net.tcl : $gnet_tcl"
    if {$patch_path ne ""} {
        puts "managed_patch  : $patch_path (audit copy; already inline in payload above)"
    }
    puts "Policy         : Global-Net-only. Never calls redo_IO/read_io_file."
    puts "======================================================================"

    tt_pkg_source_once $gnet_tcl "Global Net payload"

    if {[llength [info commands commit_global_net_rules]] > 0} {
        puts "INFO: read_GnetPKG commit_global_net_rules"
        commit_global_net_rules
    } else {
        puts "**WARN: commit_global_net_rules is unavailable; relying on connect_global_net immediate connectivity."
    }

    puts "INFO: read_GnetPKG completed successfully."

    return [dict create \
        global_net_tcl $gnet_tcl \
        managed_patch_audit_copy $patch_path]
}
