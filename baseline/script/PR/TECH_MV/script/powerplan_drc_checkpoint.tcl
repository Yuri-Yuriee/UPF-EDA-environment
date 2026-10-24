# =============================================================================
# Powerplan DRC checkpoint helper
# =============================================================================
# This script keeps every original check_drc location in script/powerplan.tcl,
# but adds optional GUI suspension when violations are found.
#
# User configuration (setup/config.tcl):
#   POWERPLAN_DRC_PAUSE_ON_VIOLATION          true|false
#   POWERPLAN_DRC_REQUIRE_CLEAN_BEFORE_CONTINUE true|false
#   POWERPLAN_DRC_SAVE_DB_ON_VIOLATION        true|false
#   POWERPLAN_DRC_LIMIT                       integer
#
# When PAUSE_ON_VIOLATION is true:
#   - a report and optional DB are written;
#   - Innovus executes suspend;
#   - inspect/fix the DRC in GUI and type "resume".
#
# When REQUIRE_CLEAN_BEFORE_CONTINUE is false, resume acknowledges the current
# violations and the flow continues. When it is true, check_drc is rerun after
# resume and Innovus suspends again until the checkpoint becomes clean.

if {![info exists REPORT_DIR]} {
    set REPORT_DIR reports
}
if {![info exists DB_DIR]} {
    set DB_DIR dbs
}
if {![info exists TOP_MODULE]} {
    set TOP_MODULE current_design
}

proc powerplan_drc_safe_name {name} {
    set safe_name $name
    regsub -all {[^A-Za-z0-9_]+} $safe_name {_} safe_name
    return [string trim $safe_name _]
}

proc powerplan_drc_db_step {checkpoint} {
    switch -- $checkpoint {
        after_power_stripe {
            return 36
        }
        after_follow_pin {
            return 46
        }
        before_final_via_repair {
            return 71
        }
        after_final_via_repair {
            return 81
        }
        default {
            return 89
        }
    }
}


proc powerplan_drc_write_report {checkpoint markers report_file {native_count ""}} {
    global TOP_MODULE POWERPLAN_DRC_LIMIT

    set fp [open $report_file w]
    puts $fp "Powerplan DRC checkpoint"
    puts $fp "Design      : $TOP_MODULE"
    puts $fp "Checkpoint  : $checkpoint"
    if {$native_count eq ""} {error "Native DRC count is required; all DB markers cannot substitute for it."}
    puts $fp "DRC count   : $native_count"
    puts $fp "DB markers  : [llength $markers] (mixed origin; not native DRC count)"
    puts $fp "DRC limit   : $POWERPLAN_DRC_LIMIT"
    puts $fp ""

    puts $fp "Current DB marker inventory (may include other checks):"
    set index 0
    foreach marker $markers {
        incr index

        set subtype "UNKNOWN"
        set bbox    "UNKNOWN"
        catch {set subtype [get_db $marker .subtype]}
        catch {set bbox    [get_db $marker .bbox]}

        puts $fp [format "%6d  %-40s  %s" $index $subtype $bbox]
    }
    close $fp
}

proc powerplan_check_drc {checkpoint} {
    global POWERPLAN_DRC_PAUSE_ON_VIOLATION
    global POWERPLAN_DRC_REQUIRE_CLEAN_BEFORE_CONTINUE
    global POWERPLAN_DRC_SAVE_DB_ON_VIOLATION
    global POWERPLAN_DRC_LIMIT
    global REPORT_DIR DB_DIR TOP_MODULE

    file mkdir $REPORT_DIR
    file mkdir $DB_DIR

    set safe_checkpoint [powerplan_drc_safe_name $checkpoint]
    if {$safe_checkpoint eq ""} {
        set safe_checkpoint checkpoint
    }

    set db_step [powerplan_drc_db_step $checkpoint]
    set report_file [tech_mv_report_path $db_step "drc_violation_${safe_checkpoint}" rpt 02]
    set failure_db [file join $DB_DIR \
        [format "02_%02d_drc_violation_%s.enc" $db_step $safe_checkpoint]]

    set_db check_drc_limit $POWERPLAN_DRC_LIMIT

    while {1} {
        puts ""
        puts "======================================================================"
        puts " POWERPLAN DRC CHECKPOINT: $checkpoint"
        puts "======================================================================"
        puts "INFO: check_drc_limit = $POWERPLAN_DRC_LIMIT"

        tech_mv_check_drc
        # Native completion count belongs to this invocation; DB markers have mixed origins.
        set markers [get_db current_design .markers]
        set drc_count [dict get $::TECH_MV_LAST_DRC_RESULT count]

        powerplan_drc_write_report $checkpoint $markers $report_file $drc_count

        if {$drc_count == 0} {
            puts "INFO: $checkpoint PASSED: 0 DRC violations."
            puts "INFO: report = $report_file"
            puts "======================================================================"
            puts ""
            return 0
        }

        puts "WARNING: $checkpoint found $drc_count DRC violation(s)."
        puts "WARNING: report = $report_file"

        if {$POWERPLAN_DRC_SAVE_DB_ON_VIOLATION} {
            write_db $failure_db
            puts "WARNING: debug DB = $failure_db"
        }

        if {!$POWERPLAN_DRC_PAUSE_ON_VIOLATION} {
            puts "WARNING: POWERPLAN_DRC_PAUSE_ON_VIOLATION is false."
            puts "WARNING: Continuing the powerplan flow without suspension."
            puts "======================================================================"
            puts ""
            return $drc_count
        }

        puts ""
        puts "**********************************************************************"
        puts " ACTION REQUIRED: Powerplan DRC violations need confirmation"
        puts "**********************************************************************"
        puts "Checkpoint : $checkpoint"
        puts "DRC count  : $drc_count"
        puts "Report     : $report_file"
        if {$POWERPLAN_DRC_SAVE_DB_ON_VIOLATION} {
            puts "Debug DB   : $failure_db"
        }
        puts ""
        puts "Inspect or fix the violations in the Innovus GUI."
        puts "Type the following command when ready to continue:"
        puts ""
        puts "    resume"
        puts ""

        if {$POWERPLAN_DRC_REQUIRE_CLEAN_BEFORE_CONTINUE} {
            puts "Clean mode is enabled. check_drc will run again after resume."
            puts "The flow will suspend again while violations remain."
            puts "To acknowledge and continue without cleaning, enter this before resume:"
            puts ""
            puts "    set POWERPLAN_DRC_REQUIRE_CLEAN_BEFORE_CONTINUE false"
            puts ""
        } else {
            puts "Confirmation mode is enabled. After resume, the flow continues even"
            puts "if the current DRC markers have not been fixed."
            puts ""
        }
        puts "**********************************************************************"
        flush stdout

        if {[llength [info commands tech_mv_checkpoint_tools]]} { tech_mv_checkpoint_tools {02_powerplan} $checkpoint }
        suspend

        # The variable is intentionally checked again after resume so the user
        # can change it from the suspended Innovus console.
        if {!$POWERPLAN_DRC_REQUIRE_CLEAN_BEFORE_CONTINUE} {
            puts "INFO: DRC checkpoint '$checkpoint' acknowledged by user."
            puts "INFO: Continuing powerplan flow with $drc_count recorded violation(s)."
            puts "======================================================================"
            puts ""
            return $drc_count
        }

        puts "INFO: Rechecking DRC checkpoint '$checkpoint' after resume..."
    }
}
