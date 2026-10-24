# =============================================================================
# place_checkpoint.tcl
# Debug snapshot helper.
#
# IMPORTANT CHECKPOINT SEMANTICS:
#   This helper does NOT run check_place, check_floorplan, or suspend.
#   Formal legality checks belong only to tech_mv_checkpoint / stage-end guards.
#
# Purpose:
#   - save optional DB snapshots
#   - record EndCap movement/history
#   - provide debug boundaries without creating duplicate formal checks
# =============================================================================


if {[llength [info commands TT_track_pd_endcaps]] == 0 &&
    [info exists ::TOOL_DIR]} {
    set tt_ec_tracker [file join $::SCRIPT_DIR track_pd_endcaps.tcl]
    if {[file exists $tt_ec_tracker]} {
        source -quiet $tt_ec_tracker
    }
}

proc tech_mv_place_checkpoint {tag {db_file ""}} {
    if {!$::DEBUG_PLACE_CHECKPOINT_ENABLE} {
        return
    }

    puts ""
    puts "======================================================================"
    puts " DEBUG SNAPSHOT : $tag"
    puts "======================================================================"
    puts "INFO: No check_place/check_floorplan is run at debug snapshots."

    if {[llength [info commands TT_track_pd_endcaps]] > 0} {
        TT_track_pd_endcaps $tag
    }

    if {$::DEBUG_PLACE_CHECKPOINT_SAVE_DB && $db_file ne ""} {
        set db_path [file join $::DB_DIR $db_file]
        puts "INFO: Saving debug database = $db_path"
        write_db $db_path
    }

    puts "======================================================================"
    puts " END DEBUG SNAPSHOT : $tag"
    puts "======================================================================"
    puts ""
}
