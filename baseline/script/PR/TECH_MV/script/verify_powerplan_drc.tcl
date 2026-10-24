# =============================================================================
# Final 02_powerplan DRC checkpoint
# =============================================================================
# Intermediate DRC checkpoints are executed inside script/powerplan.tcl.
# This final checkpoint also covers changes made afterward, including power
# switch insertion and secondary PG routing.

if {$POWERPLAN_FINAL_DRC_CHECK_ENABLE} {
    source -quiet [file join $SCRIPT_DIR powerplan_drc_checkpoint.tcl]
    powerplan_check_drc stage_final_after_switch_and_secondary_pg
} else {
    puts "INFO: Skip final powerplan DRC checkpoint because POWERPLAN_FINAL_DRC_CHECK_ENABLE is false."
}
