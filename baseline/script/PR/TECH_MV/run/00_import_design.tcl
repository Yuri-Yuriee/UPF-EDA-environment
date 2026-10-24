# Runtime adapter preserves the historical logical source path.
if {[info exists ::TECH_MV_RUNTIME_ROOT]} {
    info script [file join $::TECH_MV_RUNTIME_ROOT run/00_import_design.tcl]
}
# Stage00 is an import entry, not a request to replace an existing design.
# Keep the current DB/config untouched when this entry is sourced again.
# Query failure before initialization leaves the original import/error path intact.
if {[llength [info commands get_db]]} {
    set _tech_stage00_db_status [catch {get_db current_design} _tech_stage00_db]
    if {!$_tech_stage00_db_status && $_tech_stage00_db ni {{} 0 0x0 NULL null}} {
        unset _tech_stage00_db_status _tech_stage00_db
        puts "WARNING: Stage00 SKIPPED: a design is already loaded in this session."
        puts "INFO: The current DB and configuration were retained; Stage00 import/checks were not rerun."
        puts "INFO: Use a fresh Innovus session for a full design import."
        return
    }
    unset _tech_stage00_db_status _tech_stage00_db
}

# Always reload the complete TECH_MV user setup for every run invocation.
# init.setup reloads the categorized setup/config/*.config.tcl files.
# Always reload the complete TECH_MV runtime/configuration for this run entry.
# Resolve build_PR/init.setup from this file; do not depend on script_search_path.
set _tech_run_file [file normalize [info script]]
set ::TECH_MV_RUNTIME_ROOT [file dirname [file dirname $_tech_run_file]]
set _tech_init_setup [file normalize [file join [file dirname $_tech_run_file] .. init.setup]]
if {![file isfile $_tech_init_setup]} {
    error "TECH_MV runtime init.setup not found: $_tech_init_setup"
}
# Refresh definition-only access before evaluating init.setup configuration.
source [file join $::TECH_MV_RUNTIME_ROOT .. script PR TECH_MV script 00_common private_parameter_config.tcl]
source $_tech_init_setup
unset _tech_run_file
unset _tech_init_setup
set ::TECH_MV_REPORT_STAGE 00
source -quiet [file join $SCRIPT_DIR prepare_run_dirs.tcl]

source -quiet [file join $SCRIPT_DIR design_import.tcl]
# Optional read-only config comparison; no query runs automatically.
source -quiet [file join $TOOL_DIR 00_common TT_config_probe.tcl]
source -quiet [file join $SCRIPT_DIR commit_msv.tcl]
source -quiet [file join $SCRIPT_DIR apply_design_config.tcl]
# Read loaded component geometry here; no routing or placement is performed.
source -quiet [file join $::TECH_MV_RUNTIME_ROOT .. script PR TECH_MV script 00_common import_geometry_info.tcl]
set ::TECH_MV_IMPORTED_GEOMETRY_INFO [tech_mv_import_geometry_info]
source -quiet [file join $SCRIPT_DIR create_pg_pad.tcl]
# Optional segmented IO-pad ring model: use the same user-facing TT tool
# for both Stage00 automation and manual Innovus operation.
source -quiet [file join $TOOL_DIR 01_floorplan TT_flow_iopad_ring_model.tcl]
if {$ENABLE_IOPAD_RING_MODEL} {
    TT_IOPAD_RING build
} else {
    set ::IOPAD_RING_MODEL_ACTIVE false
    puts "INFO: IO-pad ring model is inactive because IOPAD_RING_DOMAIN_CONFIG is empty."
}
if {$ENABLE_AUTO_GENERATE_IO} {
    source -quiet [file join $SCRIPT_DIR generate_io_file.tcl]
}

# -----------------------------------------------------------------------------
# Mandatory Stage00 IOPAD GUI interface.
# Global Net is intentionally NOT applied during import; it may still be edited
# through the IOPAD GUI and is applied only by the explicit Global Net action.
# -----------------------------------------------------------------------------
set _tech_iopad_gui_tcl [file join $TOOL_DIR 01_floorplan TT_flow_iopad_interface_start.tcl]
if {![file isfile $_tech_iopad_gui_tcl]} {
    error "Required Stage00 IOPAD GUI interface Tcl not found: $_tech_iopad_gui_tcl"
}
source -quiet $_tech_iopad_gui_tcl
puts "INFO: Stage00 IOPAD GUI interface sourced. Launch GUI manually with: TT_IOPAD_GUI_START"
unset _tech_iopad_gui_tcl

source -quiet [file join $SCRIPT_DIR config_cts.tcl]

# End-of-import IO / RTE / optional IO-domain-ring consistency gate.
# If the first check fails, regenerate IO_FILE exactly once and re-check once.
# Never loop until PASS.  The second failure is reported to the user.
source -quiet [file join $TOOL_DIR 01_floorplan TT_proc_iopad_iofile_check.tcl]
set _tech_iochk_strict $IMPORT_IOPAD_VALIDATION_STRICT
set IMPORT_IOPAD_VALIDATION_STRICT false
set _tech_iochk_ok [TT_check_iopad_iofile]
if {!$_tech_iochk_ok && $ENABLE_AUTO_GENERATE_IO} {
    puts "WARNING: Stage00 IO-file check failed. Regenerating IO_FILE once, then checking once more."
    source -quiet [file join $SCRIPT_DIR generate_io_file.tcl]
    set _tech_iochk_ok [TT_check_iopad_iofile]
}
set IMPORT_IOPAD_VALIDATION_STRICT $_tech_iochk_strict
unset _tech_iochk_strict
if {!$_tech_iochk_ok && $IMPORT_IOPAD_VALIDATION_STRICT} {
    unset _tech_iochk_ok
    error "Stage00 IOPAD / IO-file validation still fails after the single allowed regenerate/recheck."
}
unset _tech_iochk_ok

# -----------------------------------------------------------------------------
# Read-only 2nd-PG readiness check at import stage.
# This does not route/fix anything and does not stop import on a FAIL.
# -----------------------------------------------------------------------------
source -quiet [file join $TOOL_DIR 02_powerplan secondary_pg TT_check_lp_2ndpg.tcl]
set TT2ND_IMPORT_CHECK [TT_check_lp_2ndpg import]

source -quiet [file join $SCRIPT_DIR track_pd_endcaps.tcl]
TT_track_pd_endcaps "00_import"

write_db [file join $DB_DIR 00_99_import.enc]
