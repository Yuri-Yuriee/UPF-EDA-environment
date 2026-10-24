# Runtime adapter preserves the historical logical source path.
if {[info exists ::TECH_MV_RUNTIME_ROOT]} {
    info script [file join $::TECH_MV_RUNTIME_ROOT run/tool/01_floorplan/TT_proc_floorplan_resume.tcl]
}
# Load definitions only; no APR action or setup reload is performed here.
if {![llength [info commands ::tech_mv_library_value]]} {
    if {[info exists ::TOOL_DIR]} {
        source -quiet [file join $::TECH_MV_RUNTIME_ROOT .. script PR TECH_MV script 00_common private_parameter_config.tcl]
    } else {
        source -quiet [file join $::TECH_MV_RUNTIME_ROOT .. script PR TECH_MV script 00_common private_parameter_config.tcl]
    }
}
# =============================================================================
# TT_proc_floorplan_resume.tcl
# =============================================================================
# Stage-01 Floorplan checkpoint restore/resume framework.
# Level-0 read_db Native-Resume V2.4.0 (known-good no-pre-read-bubble).
#
# Every recoverable MID-FLOW checkpoint uses the same operator sequence:
#
#   fp_restore <point>
#     -> schedule a level-0 restore entry and RETURN
#     -> event loop sources TT_floorplan_restore_level0_driver.tcl at Tcl level 0
#     -> raw read_db (no proc/catch/uplevel around read_db)
#     -> rebuild the required helper state
#     -> reconstruct a native Innovus suspend call stack
#     -> [SUSPEND]innovus>
#
#   resume
#     -> execute the Tcl continuation AFTER that checkpoint
#
# If the original save point was itself immediately followed by suspend, restore
# reconstructs that original interactive suspend state (FILL_IN_CELL_BOND_PAD_041/manual PD/manual
# macro/EndCap debug) rather than a generic pause.
#
# fp_restore_hold / fp_continue remain only for backward compatibility.  Normal
# crash recovery should use fp_restore + native Innovus resume.
# =============================================================================

# Resolve build_PR/init.setup from this tool path.
set _fp_restore_tool [file normalize [info script]]
set _fp_restore_root [file normalize [file join [file dirname $_fp_restore_tool] .. .. ..]]
set _fp_restore_init [file join $_fp_restore_root init.setup]
if {![file isfile $_fp_restore_init]} {
    error "Floorplan restore cannot locate init.setup: $_fp_restore_init"
}
source $_fp_restore_init
unset _fp_restore_tool
unset _fp_restore_root
unset _fp_restore_init

# -----------------------------------------------------------------------------
# Formal Stage-01 checkpoint catalog
# -----------------------------------------------------------------------------
# Every durable write_db phase boundary is represented here.  Pre-suspend DBs
# are separate SUSPEND entries and never share a filename with their NORMAL
# accepted/durable checkpoint.
set ::FP_CHECKPOINTS [dict create \
    suspend_bond_pad_preview [dict create \
        type SUSPEND \
        db $::IO_BOND_PAD_PREVIEW_DB_NAME \
        continuation bond_pad_preview] \
    after_bond_pad_preview [dict create \
        type NORMAL \
        db $::IO_BOND_PAD_PREVIEW_AFTER_DB_NAME \
        continuation after_bond_pad_preview] \
    after_io [dict create \
        type NORMAL \
        db 01_10_place_io.enc \
        continuation after_io] \
    suspend_manual_power_domain [dict create \
        type SUSPEND \
        db 01_20_before_manual_power_domain.enc \
        continuation manual_power_domain] \
    suspend_manual_macro [dict create \
        type SUSPEND \
        db 01_30_before_manual_macro.enc \
        continuation manual_macro] \
    after_pd_row_guard [dict create \
        type NORMAL \
        db $::PD_BOUNDARY_ROW_GUARD_DB_NAME \
        continuation boundary_phase] \
    before_boundary_cells [dict create \
        type NORMAL \
        db 01_70_before_boundary_cells.enc \
        continuation boundary_phase] \
    after_endcap_power_switch_before_welltap [dict create \
        type NORMAL \
        db 01_80_after_endcap_power_switch_before_welltap.enc \
        continuation welltap_phase] \
    suspend_after_endcap_power_switch_before_welltap [dict create \
        type SUSPEND \
        db 01_81_suspend_after_endcap_power_switch_before_welltap.enc \
        continuation endcap_power_switch_suspend] \
    after_boundary_cells [dict create \
        type NORMAL \
        db 01_90_boundary_cells.enc \
        continuation post_boundary] \
    stage01_complete [dict create \
        type NORMAL \
        db 01_99_floorplan.enc \
        continuation run01_tail] \
]

if {![info exists ::FP_RESTORED_POINT]} { set ::FP_RESTORED_POINT "" }
if {![info exists ::FP_RESTORED_DB]}    { set ::FP_RESTORED_DB "" }
if {![info exists ::FP_RESTORE_STATE]} { set ::FP_RESTORE_STATE idle }

proc fp_checkpoint_info {point} {
    if {![dict exists $::FP_CHECKPOINTS $point]} {
        puts "ERROR: Unknown Floorplan checkpoint '$point'."
        fp_points
        error "Invalid Floorplan checkpoint."
    }
    return [dict get $::FP_CHECKPOINTS $point]
}

proc fp_points {} {
    puts ""
    puts "======================================================================"
    puts " Floorplan Restore / Resume Points"
    puts "======================================================================"
    puts [format "%-52s %-9s %s" "POINT" "TYPE" "DB"]
    puts "----------------------------------------------------------------------"
    foreach point [dict keys $::FP_CHECKPOINTS] {
        set info [dict get $::FP_CHECKPOINTS $point]
        puts [format "%-52s %-9s %s" \
            $point \
            [dict get $info type] \
            [dict get $info db]]
    }
    puts "======================================================================"
    puts ""
}

proc fp_status {} {
    puts ""
    puts "======================================================================"
    puts " FLOORPLAN RESTORE STATUS"
    puts "======================================================================"
    puts "State : $::FP_RESTORE_STATE"
    if {$::FP_RESTORED_POINT eq ""} {
        puts "Point : <none>"
        puts "DB    : <none>"
    } else {
        puts "Point : $::FP_RESTORED_POINT"
        puts "DB    : $::FP_RESTORED_DB"
        set info [fp_checkpoint_info $::FP_RESTORED_POINT]
        puts "Type  : [dict get $info type]"
        if {$::FP_RESTORE_STATE eq "suspended"} {
            puts "Next  : native Innovus resume"
        } elseif {$::FP_RESTORE_STATE eq "held"} {
            puts "Next  : fp_continue (legacy compatibility; this will arm native resume)"
        }
    }
    puts "======================================================================"
    puts ""
}

# floorplan.tcl defines all re-entrant continuation procedures before the first
# physical create_floorplan command.  Restore executes only that helper prefix.
proc fp_load_floorplan_helpers {} {
    set floorplan_file [file join $::SCRIPT_DIR floorplan.tcl]
    if {![file isfile $floorplan_file]} {
        error "Floorplan script does not exist: $floorplan_file"
    }

    set fp [open $floorplan_file r]
    set data [read $fp]
    close $fp

    set physical_marker "# Establish the final die/IO/core boxes before IO-pad placement."
    set idx [string first $physical_marker $data]
    if {$idx < 0} {
        error "Cannot find helper/physical boundary marker in $floorplan_file"
    }

    set helper_text [string range $data 0 [expr {$idx - 1}]]
    uplevel #0 $helper_text
    set ::TECH_MV_REPORT_STAGE 01
}

proc fp_finish_run01 {} {
    uplevel #0 [list source -quiet [file join $::SCRIPT_DIR checkpoint_guard.tcl]]

    if {$::ENABLE_MANUAL_PD_SNAP_BREAKPOINT} {
        uplevel #0 [list tech_mv_manual_pd_snap_breakpoint]
    } else {
        puts "INFO: Final duplicate PD pause disabled; recording completed geometry."
        if {[llength [info commands tech_mv_pd_lock_capture]]} { tech_mv_pd_lock_capture floorplan_completed }
        if {[llength [info commands TT_track_pd_endcaps]]} { TT_track_pd_endcaps floorplan_completed }
    }

    puts "INFO: Stage 01 Floorplan continuation completed."
}

proc fp_clear_restore_state {} {
    set ::FP_RESTORE_STATE completed
    set ::FP_RESTORED_POINT ""
    set ::FP_RESTORED_DB ""
}

# -----------------------------------------------------------------------------
# NORMAL continuation dispatch
# -----------------------------------------------------------------------------
proc fp_dispatch_normal_continuation {point continuation} {
    fp_load_floorplan_helpers

    switch -- $continuation {
        after_bond_pad_preview {
            fp_run_after_bond_pad_preview
            fp_finish_run01
        }
        after_io {
            fp_run_after_io
            fp_finish_run01
        }
        boundary_phase {
            fp_run_boundary_phase
            fp_finish_run01
        }
        welltap_phase {
            fp_run_welltap_from_post_switch_checkpoint
            fp_finish_run01
        }
        post_boundary {
            fp_run_post_boundary_tail
            fp_finish_run01
        }
        run01_tail {
            fp_finish_run01
        }
        default {
            error "Unsupported NORMAL Floorplan continuation '$continuation' for point '$point'."
        }
    }
}

# Rebuild a native suspend boundary for an ordinary durable checkpoint.
# The continuation does not execute until the user types native Innovus resume.
proc fp_restore_normal_suspend {point continuation} {
    puts ""
    puts "======================================================================"
    puts " RESTORED CHECKPOINT : READY TO RESUME"
    puts "======================================================================"
    puts "Point : $point"
    puts "DB    : $::FP_RESTORED_DB"
    puts "State : restored exactly at this durable phase boundary"
    puts ""
    puts "Inspect the restored DB if needed, then type native Innovus:"
    puts "  resume"
    puts ""
    puts "Only after resume will the Tcl AFTER this checkpoint execute."
    puts "======================================================================"
    flush stdout

    set ::FP_RESTORE_STATE suspended
    if {[llength [info commands tech_mv_checkpoint_tools]]} { tech_mv_checkpoint_tools {01_floorplan} {TT_proc_floorplan_resume} }
    suspend

    puts "INFO: Native resume received for restored Floorplan checkpoint '$point'."
    set ::FP_RESTORE_STATE continuing
    fp_dispatch_normal_continuation $point $continuation
}

# -----------------------------------------------------------------------------
# SUSPEND checkpoint reconstruction
# -----------------------------------------------------------------------------
proc fp_restore_suspend_bond_pad_preview {} {
    fp_load_floorplan_helpers
    uplevel #0 [list source -quiet [file join $::TOOL_DIR 01_floorplan TT_proc_bond_pad_preview.tcl]]

    TT_bond_pad_restore_preview_suspend \
        "final pre-IO-filler geometry gate" \
        $::IO_BOND_PAD_PREVIEW_DB_NAME \
        $::IO_BOND_PAD_PREVIEW_AFTER_DB_NAME \
        $::BOND_PAD_PREVIEW_SEARCH_PARITY \
        true

    # Native resume accepted FILL_IN_CELL_BOND_PAD_041 and the helper wrote the accepted 01_16 DB.
    fp_run_after_bond_pad_preview
    fp_finish_run01
}

proc fp_restore_suspend_manual_power_domain {} {
    fp_load_floorplan_helpers
    uplevel #0 [list source -quiet [file join $::SCRIPT_DIR manual_place_power_domain.tcl]]

    set display_domains $::MANUAL_POWER_DOMAIN_NAMES
    if {![fp_pd_uses_mouse_selection $::MANUAL_POWER_DOMAIN_NAMES]} {
        set resolved [fp_pd_resolve_manual_domains $::MANUAL_POWER_DOMAIN_NAMES]
        if {[llength $resolved] > 0} { set display_domains $resolved }
    }

    fp_prompt_resume \
        "Manual Power-Domain Placement (RESTORED)" \
        [list \
            "Power-domain target specification: $display_domains" \
            "This is the restored 01_20 pre-suspend checkpoint." \
            "Place/reshape the intended Power-Domain regions in the GUI." \
            "Do not place or fix hard macros during this stage." \
        ]

    if {[llength [info commands tech_mv_checkpoint_tools]]} { tech_mv_checkpoint_tools {01_floorplan} {TT_proc_floorplan_resume} }
    suspend
    puts "INFO: Restored manual Power-Domain checkpoint accepted by native resume."

    fp_continue_after_manual_power_domain
    fp_finish_run01
}

proc fp_restore_suspend_manual_macro {} {
    fp_load_floorplan_helpers
    uplevel #0 [list source -quiet [file join $::SCRIPT_DIR manual_place_power_domain.tcl]]

    fp_prompt_resume \
        "Manual GUI Hard-Macro Placement (RESTORED)" \
        [list \
            "This is the restored 01_30 pre-suspend checkpoint." \
            "Power-domain placement is already complete." \
            "Place all non-pad hard macros in the GUI." \
            "Do not fix the hard macros manually; the flow will check them first." \
        ]

    if {[llength [info commands tech_mv_checkpoint_tools]]} { tech_mv_checkpoint_tools {01_floorplan} {TT_proc_floorplan_resume} }
    suspend
    puts "INFO: Restored manual hard-macro checkpoint accepted by native resume."
    FP_save restored_manual_macro 31

    fp_run_post_macro_floorplan
    fp_finish_run01
}

proc fp_restore_suspend_endcap_power_switch {} {
    fp_load_floorplan_helpers

    puts ""
    puts "======================================================================"
    puts " RESTORED SUSPEND : ENDCAP + POWER SWITCH BEFORE WELLTAP"
    puts "======================================================================"
    puts "DB state already contains EndCaps and Power Switches."
    puts "WellTaps have NOT been inserted at this suspend snapshot."
    puts "Inspect EndCap / Power-Switch placement and check_place markers."
    puts "When acceptable, type native Innovus:"
    puts "  resume"
    puts "======================================================================"
    flush stdout

    if {[llength [info commands tech_mv_checkpoint_tools]]} { tech_mv_checkpoint_tools {01_floorplan} {TT_proc_floorplan_resume} }
    suspend
    puts "INFO: Restored EndCap/Power-Switch checkpoint accepted by native resume."

    fp_run_welltap_from_post_switch_checkpoint
    fp_finish_run01
}

proc fp_dispatch_suspend_continuation {point continuation} {
    switch -- $continuation {
        bond_pad_preview {
            fp_restore_suspend_bond_pad_preview
        }
        manual_power_domain {
            fp_restore_suspend_manual_power_domain
        }
        manual_macro {
            fp_restore_suspend_manual_macro
        }
        endcap_power_switch_suspend {
            fp_restore_suspend_endcap_power_switch
        }
        default {
            error "Unsupported SUSPEND Floorplan continuation '$continuation' for point '$point'."
        }
    }
}

# Internal continuation against a checkpoint DB already in memory.
# User-facing normal recovery is fp_restore + native resume.
proc fp_resume {point} {
    set info [fp_checkpoint_info $point]

    set design_name ""
    catch {set design_name [get_db current_design .name]}
    if {$design_name eq ""} {
        error "No design is in memory. Use 'fp_restore $point' first."
    }

    if {$::FP_RESTORED_POINT ne "" && $point ne $::FP_RESTORED_POINT} {
        error "Loaded checkpoint is '$::FP_RESTORED_POINT', but fp_resume requested '$point'."
    }

    set type [dict get $info type]
    set continuation [dict get $info continuation]

    if {$type eq "NORMAL"} {
        fp_restore_normal_suspend $point $continuation
    } else {
        set ::FP_RESTORE_STATE suspended
        fp_dispatch_suspend_continuation $point $continuation
    }
}

# -----------------------------------------------------------------------------
# V2.1 level-0 read_db restore scheduler
# -----------------------------------------------------------------------------
# Root cause isolated on Innovus 21.19:
#   - raw read_db from a Tcl file sourced at level 0 works for Stage-01 DBs
#   - read_db executed inside fp_restore/fp_restore_impl proc frames can SEGV
#
# Therefore fp_restore NEVER calls read_db.  It records the request and schedules
# a top-level source callback.  Tcl 'after idle' callbacks are evaluated at the
# global level; the driver additionally checks [info level] == 0 before the raw
# read_db statement.  If the callback is not level 0, it aborts BEFORE read_db.
#
# IMPORTANT: do not wrap the driver's read_db in catch/eval/uplevel/proc.

if {![info exists ::FP_LEVEL0_RESTORE_PENDING]}  { set ::FP_LEVEL0_RESTORE_PENDING 0 }
if {![info exists ::FP_LEVEL0_RESTORE_EVENT]}    { set ::FP_LEVEL0_RESTORE_EVENT "" }
if {![info exists ::FP_LEVEL0_RESTORE_POINT]}    { set ::FP_LEVEL0_RESTORE_POINT "" }
if {![info exists ::FP_LEVEL0_RESTORE_DB]}       { set ::FP_LEVEL0_RESTORE_DB "" }
if {![info exists ::FP_LEVEL0_RESTORE_HOLD]}     { set ::FP_LEVEL0_RESTORE_HOLD 0 }

proc fp_restore_impl {point hold_normal} {
    set info [fp_checkpoint_info $point]
    set db_name [dict get $info db]
    set db_file [file join $::DB_DIR $db_name]
    set type [dict get $info type]

    if {![file exists $db_file]} {
        error "Floorplan checkpoint DB does not exist: $db_file"
    }
    if {$hold_normal && $type ne "NORMAL"} {
        error "fp_restore_hold is only valid for NORMAL checkpoints; '$point' is $type."
    }
    if {$::FP_LEVEL0_RESTORE_PENDING} {
        error "A Floorplan level-0 restore is already pending for '$::FP_LEVEL0_RESTORE_POINT'."
    }
    if {$::FP_RESTORE_STATE eq "loading" || $::FP_RESTORE_STATE eq "scheduled"} {
        error "Floorplan restore is already active (state=$::FP_RESTORE_STATE)."
    }

    set driver [file join $::TECH_MV_RUNTIME_ROOT .. script PR TECH_MV script 01_floorplan floorplan_restore_level0_driver.tcl]
    if {![file isfile $driver]} {
        error "Floorplan level-0 restore driver does not exist: $driver"
    }

    puts ""
    puts "======================================================================"
    puts " FLOORPLAN RESTORE"
    puts "======================================================================"
    puts "Point : $point"
    puts "Type  : $type"
    puts "DB    : $db_file"
    puts "Mode  : level-0 raw read_db (scheduled after fp_restore returns)"
    puts "======================================================================"
    puts ""

    set ::FP_RESTORED_POINT ""
    set ::FP_RESTORED_DB ""
    set ::FP_RESTORE_STATE scheduled
    set ::FP_LEVEL0_RESTORE_PENDING 1
    set ::FP_LEVEL0_RESTORE_POINT $point
    set ::FP_LEVEL0_RESTORE_DB [file normalize $db_file]
    set ::FP_LEVEL0_RESTORE_HOLD [expr {$hold_normal ? 1 : 0}]

    # Do not source the driver here.  The current fp_restore proc frame must
    # unwind completely before the level-0 source callback runs.
    set ::FP_LEVEL0_RESTORE_EVENT [after idle [list source -quiet $driver]]

    puts "INFO: Level-0 Floorplan restore scheduled: $::FP_LEVEL0_RESTORE_EVENT"
    puts "INFO: fp_restore will return before read_db executes."
    puts "INFO: The restore driver will refuse to call read_db unless Tcl level == 0."
    flush stdout
    return $point
}

proc fp_restore {point} {
    return [fp_restore_impl $point false]
}

proc fp_restore_hold {point} {
    return [fp_restore_impl $point true]
}

# Backward compatibility only.  It now reconstructs a native suspend and still
# requires standard Innovus `resume`; it no longer directly runs the flow.
proc fp_continue {} {
    if {$::FP_RESTORED_POINT eq "" || $::FP_RESTORE_STATE ne "held"} {
        error "No held NORMAL Floorplan checkpoint. Use fp_restore <point> for normal recovery."
    }

    set point $::FP_RESTORED_POINT
    set info [fp_checkpoint_info $point]
    if {[dict get $info type] ne "NORMAL"} {
        error "fp_continue compatibility mode supports NORMAL checkpoints only."
    }

    puts "WARNING: fp_continue is legacy compatibility only."
    puts "WARNING: A native suspend will be created now; type `resume` to continue."
    set ::FP_NATIVE_RESTORE_POINT $point
    set ::FP_NATIVE_RESTORE_DRIVER [file join $::TECH_MV_RUNTIME_ROOT .. script PR TECH_MV script 01_floorplan floorplan_restore_native_driver.tcl]
    if {![file isfile $::FP_NATIVE_RESTORE_DRIVER]} {
        error "Floorplan native-restore driver does not exist: $::FP_NATIVE_RESTORE_DRIVER"
    }
    uplevel #0 [list source -quiet $::FP_NATIVE_RESTORE_DRIVER]
}

proc fp_restore_resume {point} {
    return [fp_restore $point]
}

puts ""
puts "INFO: Loaded TT_proc_floorplan_resume.tcl - Level-0 read_db Native-Resume V2.4.0 (known-good no-pre-read-bubble)"
puts {INFO: MID-FLOW: fp_restore <point> -> level-0 raw read_db -> [SUSPEND]innovus> -> native resume}
puts {INFO: ORIGINAL SUSPEND checkpoints are reconstructed as their original [SUSPEND] state.}
puts "INFO: fp_continue is legacy compatibility only; normal recovery uses native resume."
puts [::tech_mv_library_value LIB_TEXT_015]
puts "INFO: Available points:"
fp_points
