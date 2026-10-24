# Runtime adapter preserves the historical logical source path.
if {[info exists ::TECH_MV_RUNTIME_ROOT]} {
    info script [file join $::TECH_MV_RUNTIME_ROOT run/tool/02_powerplan/secondary_pg/TT_flow_restore_pre_2ndpg.tcl]
}
# =============================================================================
# TT_flow_restore_pre_2ndpg.tcl
# =============================================================================
# Restore the exact database immediately before secondary-PG routing.
#
# SIGNAL mode:
#   restore 05_05_pre_2ndpg.enc, re-enter run/05_route.tcl, and return to the
#   native PRE-2nd-PG [SUSPEND] checkpoint. Continue only with native `resume`.
#
# SROUTE mode:
#   preserve the legacy 03_20_pre_2ndpg_restore.enc read-back behavior.
# =============================================================================

source init.setup
source -quiet [file join $SCRIPT_DIR prepare_run_dirs.tcl]

set _tt_mode [string toupper $::SECONDARY_PG_ROUTE_MODE]

if {$_tt_mode eq "SIGNAL"} {
    set TT_PRE_2NDPG_RESTORE_DB [file join $DB_DIR 05_05_pre_2ndpg.enc]

    if {![file exists $TT_PRE_2NDPG_RESTORE_DB]} {
        error "Pre-2ndPG SIGNAL restore DB does not exist: $TT_PRE_2NDPG_RESTORE_DB"
    }

    puts ""
    puts "======================================================================"
    puts " RESTORE PRE-2ndPG DATABASE : SIGNAL"
    puts "======================================================================"
    puts "Restore DB : $TT_PRE_2NDPG_RESTORE_DB"
    puts "Behavior   : read_db -> re-enter 05_route -> native suspend -> resume"
    puts "======================================================================"

    read_db $TT_PRE_2NDPG_RESTORE_DB

    # read_db can reset Tcl/config state. Rebuild the normal run environment.
    source init.setup
    source -quiet [file join $SCRIPT_DIR prepare_run_dirs.tcl]

    # Force the intended manual pause when re-entering 05_route. The stage has
    # no modifying operation before this checkpoint, so normal re-entry is safe.
    set ::ENABLE_PRE_2NDPG_BREAKPOINT 1

    puts "INFO: Restored to immediately before SIGNAL 2nd-PG routing."
    puts "INFO: Re-entering run/05_route.tcl to recreate the native suspend state."

    source -quiet [file join $RUN_DIR 05_route.tcl]

} elseif {$_tt_mode eq "SROUTE"} {
    set TT_PRE_2NDPG_RESTORE_DB [file join $DB_DIR 03_20_pre_2ndpg_restore.enc]

    if {![file exists $TT_PRE_2NDPG_RESTORE_DB]} {
        error "Pre-2ndPG SROUTE restore DB does not exist: $TT_PRE_2NDPG_RESTORE_DB"
    }

    puts ""
    puts "======================================================================"
    puts " RESTORE PRE-2ndPG DATABASE : SROUTE"
    puts "======================================================================"
    puts "Restore DB : $TT_PRE_2NDPG_RESTORE_DB"
    puts "======================================================================"

    read_db $TT_PRE_2NDPG_RESTORE_DB
    source init.setup
    source -quiet [file join $SCRIPT_DIR prepare_run_dirs.tcl]

    puts "INFO: Restored legacy SROUTE pre-2ndPG DB."
    puts "INFO: SROUTE continuation behavior is unchanged by this update."
} else {
    error "SECONDARY_PG_ROUTE_MODE must be SIGNAL or SROUTE, got '$::SECONDARY_PG_ROUTE_MODE'"
}

unset _tt_mode
