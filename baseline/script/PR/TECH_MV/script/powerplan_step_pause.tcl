# =============================================================================
# Interactive Powerplan step checkpoint
# =============================================================================
# When POWERPLAN_STEP_PAUSE_ENABLE is true, every explicit checkpoint prints
# its result, optionally saves a database, and suspends Innovus.  Enter:
#
#     resume
#
# to continue to the next powerplan operation.
#
# To disable the remaining pauses from a suspended console:
#
#     set POWERPLAN_STEP_PAUSE_ENABLE false
#     resume
#
# This helper does not change any PG geometry or routing attribute.

if {![info exists ::POWERPLAN_STEP_INDEX]} {
    set ::POWERPLAN_STEP_INDEX 0
}

proc powerplan_step_safe_name {name} {
    set safe [string tolower $name]
    set safe [string map {
        " " "_"
        "/" "_"
        "\\" "_"
        ":" "_"
        ";" "_"
        "," "_"
        "{" "_"
        "}" "_"
        "[" "_"
        "]" "_"
        "(" "_"
        ")" "_"
    } $safe]

    regsub -all {[^a-z0-9_.-]} $safe "_" safe
    regsub -all {_+} $safe "_" safe
    return [string trim $safe "_"]
}

proc powerplan_step_reset {} {
    set ::POWERPLAN_STEP_INDEX 0
}

proc powerplan_step_pause {checkpoint {description ""}} {
    # Always capture a read-only PD geometry trace at this operation boundary.
    # This executes even when interactive PowerPlan pauses are disabled.
    if {[llength [info commands tech_mv_pd_trace]] > 0} {
        tech_mv_pd_trace "powerplan_${checkpoint}"             "completed PowerPlan operation: $checkpoint"
    }

    if {![info exists ::POWERPLAN_STEP_PAUSE_ENABLE] ||
        !$::POWERPLAN_STEP_PAUSE_ENABLE} {
        return
    }

    incr ::POWERPLAN_STEP_INDEX
    set index $::POWERPLAN_STEP_INDEX
    set index_text [format "%03d" $index]
    set safe_name [powerplan_step_safe_name $checkpoint]

    puts ""
    puts "================================================================"
    puts "POWERPLAN STEP CHECKPOINT $index_text"
    puts "Checkpoint : $checkpoint"

    if {$description ne ""} {
        puts "Description: $description"
    }

    if {
        [info exists ::POWERPLAN_STEP_SAVE_DB_ENABLE] &&
        $::POWERPLAN_STEP_SAVE_DB_ENABLE
    } {
        if {
            [info exists ::DB_DIR] &&
            [info exists ::TOP_MODULE]
        } {
            set db_file [file join $::DB_DIR \
                "${::POWERPLAN_STEP_DB_PREFIX}_${index_text}_${safe_name}.enc"]

            puts "Saving DB : $db_file"
            write_db $db_file
        } else {
            puts "WARNING: Skip step DB save because DB_DIR or TOP_MODULE is undefined."
        }
    }

    puts ""
    puts "ACTION REQUIRED:"
    puts "  Inspect this powerplan result in the Innovus GUI."
    puts "  Enter 'resume' to execute the next powerplan step."
    puts ""
    puts "  Disable all remaining step pauses with:"
    puts "    set POWERPLAN_STEP_PAUSE_ENABLE false"
    puts "    resume"
    puts "================================================================"
    flush stdout

    if {[llength [info commands tech_mv_checkpoint_tools]]} { tech_mv_checkpoint_tools {02_powerplan} $checkpoint }
    suspend

    puts "INFO: Resume after powerplan checkpoint $index_text: $checkpoint"
    flush stdout
}
