# Runtime adapter preserves the historical logical source path.
if {[info exists ::TECH_MV_RUNTIME_ROOT]} {
    info script [file join $::TECH_MV_RUNTIME_ROOT run/06_finish.tcl]
}
# Always reload the complete TECH_MV user setup for every run invocation.
# init.setup reloads the categorized setup/config/*.config.tcl files.
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
set ::TECH_MV_REPORT_STAGE 06
source -quiet [file join $SCRIPT_DIR prepare_run_dirs.tcl]
source -quiet [file join $SCRIPT_DIR terminal_report_footer.tcl]
source -quiet [file join $SCRIPT_DIR checkpoint_guard.tcl]

tech_mv_stage_start_guard 06_finish

source -quiet [file join $SCRIPT_DIR add_fillers.tcl]

# Re-apply the authoritative Global Net mapping after filler insertion so the
# newly added filler instances are connected to their PG/global nets before
# the post-filler checkpoint is written.
if {![info exists ::GLOBAL_NET_FILE] || $::GLOBAL_NET_FILE eq ""} {
    error "GLOBAL_NET_FILE is not defined after init.setup/config reload."
}
if {![file isfile $::GLOBAL_NET_FILE]} {
    error "Global Net Tcl not found: $::GLOBAL_NET_FILE"
}
puts "INFO: Re-applying Global Net mapping after filler insertion: $::GLOBAL_NET_FILE"
source -quiet $::GLOBAL_NET_FILE
puts "INFO: Post-filler Global Net reconnect completed."

write_db [file join $DB_DIR 06_10_add_filler.enc]

if {$ENABLE_DELETE_UNPLACED} {
    set unplaced [get_db insts -if {.place_status == unplaced}]
    if {[llength $unplaced] > 0} { delete_obj $unplaced }
}
write_db [file join $DB_DIR 06_20_pre_bonding.enc]
TT_track_pd_endcaps "06_before_bonding"

# Real TECH Step 11: final FILL_IN_CELL_BOND_PAD_041 bond pads + AP RDL + CUSTOM_CB boundary.
if {$ENABLE_BOND_PAD_FLOW} {
    source -quiet [file join $SCRIPT_DIR create_bond_pad_stylus.tcl]
    create_bond_pad_and_route
    create_chip_boundary
    write_db [file join $DB_DIR 06_30_bond_pad.enc]
}

# Real TECH performs via/DRC cleanup after the final bonding geometry is added.
if {$ENABLE_FINAL_DRC_REPAIR || $BOND_PAD_FINAL_DRC_ENABLE} {
    set_db check_drc_limit $FINAL_DRC_LIMIT
    tech_mv_check_drc
    tech_mv_native_report_command 06 via_repair [list fix_via -min_step]
    tech_mv_native_report_command 06 via_repair [list fix_via -short]
    tech_mv_native_report_command 06 via_repair [list fix_via -min_cut]
    tech_mv_check_drc
}

# Final APR metal-density gate after final FILL_IN_CELL_BOND_PAD_041/AP geometry is present.
# Minimum-density enforcement is disabled by default because the external
# dummy/fill signoff flow remains authoritative for minimum-density closure.
if {$::CHECK_ALL_ENABLE && $::CHECK_STAGE06_METAL_DENSITY_ENABLE} {
    set _md_tool [file join $::TOOL_DIR 05_route reports TT_tool_report_metal_density.tcl]
    if {![file isfile $_md_tool]} { error "Metal-density tool not found: $_md_tool" }
    source -quiet $_md_tool
    TT_tool_report_metal_density \
        -layers $::CHECK_STAGE06_METAL_DENSITY_LAYERS \
        -report [file join $::REPORT_DIR 06_finish_metal_density.rpt] \
        -check_min [expr {$::CHECK_STAGE06_METAL_DENSITY_MIN_ENABLE ? 1 : 0}] \
        -check_max [expr {$::CHECK_STAGE06_METAL_DENSITY_MAX_ENABLE ? 1 : 0}] \
        -fatal [expr {$::CHECK_STAGE06_METAL_DENSITY_FATAL ? 1 : 0}]
    unset _md_tool
} else {
    puts "INFO: CHECK SKIPPED: Stage06 metal density (config disabled)."
}

write_db [file join $DB_DIR 06_40_finish_drc.enc]
TT_track_pd_endcaps "06_after_finish_drc"

delete_empty_hinsts
delete_route_halos -all_blocks
delete_place_halo -all_blocks
if {$ENABLE_CONNECTIVITY_CHECK} {
    check_connectivity -out_file [tech_mv_output_path report connectivity.rpt 06 connectivity] -type regular -error $FINISH_CONNECTIVITY_ERROR_LIMIT -warning $FINISH_CONNECTIVITY_WARNING_LIMIT
}
# Fresh final verification only; power checking remains opt-in.
source -quiet [file join $TOOL_DIR 06_finish antenna TT_ANTENNA_FINAL_CHECK.tcl]
antenna_stage06

write_db [file join $DB_DIR 06_99_finish.enc]
TT_track_pd_endcaps "06_finish_db"

if {$ENABLE_FINAL_OUTPUTS} {
    source -quiet [file join $SCRIPT_DIR report_die_area.tcl]
    source -quiet [file join $TOOL_DIR 06_finish export TT_export_streamout.tcl]
    source -quiet [file join $TOOL_DIR 06_finish export TT_export_netlist.tcl]
    source -quiet [file join $TOOL_DIR 06_finish export TT_export_sdf.tcl]
}

tech_mv_stage_end_guard 06_finish done

tech_mv_terminal_report_footer 06
