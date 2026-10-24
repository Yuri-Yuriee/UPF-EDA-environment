# Runtime adapter preserves the historical logical source path.
if {[info exists ::TECH_MV_RUNTIME_ROOT]} {
    info script [file join $::TECH_MV_RUNTIME_ROOT run/tool/02_powerplan/TT_proc_powerplan_resume.tcl]
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
# TT_proc_powerplan_resume.tcl
#
# TECH_MV Stage-02 deterministic restore / resume framework.
# Version: Unified Native-Resume V1.7.1
#
# Policy
# ------
# All recoverable MID-FLOW checkpoints use the same operator sequence:
#
#   pp_restore <point>
#     -> read_db
#     -> rebuild the required Tcl/helper state
#     -> reconstruct a native Innovus suspend call stack
#     -> [SUSPEND]innovus>
#
#   resume
#     -> execute the Tcl continuation AFTER that checkpoint
#
# If the original checkpoint was itself "write_db -> suspend", restore rebuilds
# that original suspended interaction (FILL_IN_CELL_BOND_PAD_041 or DRC confirmation) rather than a
# generic pause.  Thus the restored session has the same operator contract:
# inspect/fix in GUI, then type native Innovus `resume`.
#
# stage02_exit is the flow tail.  It may be restored for inspection, but there
# is no remaining Stage-02 Tcl to execute after it.
#
# pp_restore_hold / pp_continue are retained only for backward compatibility.
# Normal recovery should use pp_restore + native resume.
#
# Interactive powerplan_step_pause debug DB saving remains disabled by default.
# Formal/static Stage-02 DBs and default DRC-violation DBs are cataloged here.
# =============================================================================

# Resolve build_PR/init.setup from this tool path.  Do not depend on cwd.
set _pp_restore_tool [file normalize [info script]]
set _pp_restore_root [file normalize [file join [file dirname $_pp_restore_tool] .. .. ..]]
set _pp_restore_init [file join $_pp_restore_root init.setup]
if {![file isfile $_pp_restore_init]} {
    error "PowerPlan restore cannot locate init.setup: $_pp_restore_init"
}
source $_pp_restore_init
unset _pp_restore_tool
unset _pp_restore_root
unset _pp_restore_init

# -----------------------------------------------------------------------------
# Formal Stage-02 checkpoint catalog
# -----------------------------------------------------------------------------
set ::PP_CHECKPOINTS [dict create \
    after_bond_pad_blockage [dict create \
        type NORMAL db 02_05_bond_pad_blockage.enc continuation after_bond_pad_blockage] \
    after_core_ring [dict create \
        type NORMAL db 02_10_core_ring.enc continuation after_core_ring] \
    after_pad_pin [dict create \
        type NORMAL db 02_20_connect_pad_pin.enc continuation after_pad_pin] \
    after_block_rings [dict create \
        type NORMAL db 02_25_after_block_rings.enc continuation after_block_rings] \
    after_all_stripes [dict create \
        type NORMAL db 02_27_after_all_stripes.enc continuation after_all_stripes] \
    after_floating_sroute [dict create \
        type NORMAL db 02_33_after_floating_sroute.enc continuation after_floating_sroute] \
    before_power_stripe_drc [dict create \
        type NORMAL db 02_34_before_power_stripe_drc.enc continuation before_power_stripe_drc] \
    suspend_drc_after_power_stripe [dict create \
        type DRC_SUSPEND db 02_36_drc_violation_after_power_stripe.enc drc after_power_stripe continuation after_power_stripe_post_check] \
    after_power_stripe_drc [dict create \
        type NORMAL db 02_35_after_power_stripe_drc.enc continuation after_power_stripe_drc] \
    after_power_stripe_legacy [dict create \
        type NORMAL db 02_30_power_stripe.enc continuation after_power_stripe_legacy] \
    suspend_drc_after_follow_pin [dict create \
        type DRC_SUSPEND db 02_46_drc_violation_after_follow_pin.enc drc after_follow_pin continuation after_follow_pin_post_check] \
    after_follow_pin_drc [dict create \
        type NORMAL db 02_45_after_follow_pin_drc.enc continuation after_follow_pin_drc] \
    after_follow_pin_legacy [dict create \
        type NORMAL db 02_40_connect_follow_pin.enc continuation after_follow_pin_legacy] \
    suspend_drc_before_final_via_repair [dict create \
        type DRC_SUSPEND db 02_71_drc_violation_before_final_via_repair.enc drc before_final_via_repair continuation before_final_via_repair_post_check] \
    before_final_via_repair_drc [dict create \
        type NORMAL db 02_70_before_final_via_repair_drc.enc continuation before_final_via_repair_drc] \
    suspend_drc_after_final_via_repair [dict create \
        type DRC_SUSPEND db 02_81_drc_violation_after_final_via_repair.enc drc after_final_via_repair continuation after_final_via_repair_post_check] \
    after_final_via_repair_drc [dict create \
        type NORMAL db 02_80_after_final_via_repair_drc.enc continuation after_final_via_repair_drc] \
    after_powerplan_mesh [dict create \
        type NORMAL db 02_90_powerplan_mesh.enc continuation after_powerplan_mesh] \
    after_switch_verify [dict create \
        type NORMAL db 02_91_after_switch_verify.enc continuation after_switch_verify] \
    after_secondary_pg [dict create \
        type NORMAL db 02_92_after_secondary_pg.enc continuation after_secondary_pg] \
    after_final_mesh_color [dict create \
        type NORMAL db 02_93_after_final_mesh_color.enc continuation after_final_mesh_color] \
    after_final_check [dict create \
        type NORMAL db 02_95_after_final_check.enc continuation after_final_check] \
    suspend_bond_pad_preview [dict create \
        type SUSPEND db $::POWERPLAN_BOND_PAD_PREVIEW_DB_NAME continuation bond_pad_preview] \
    after_bond_pad_preview [dict create \
        type NORMAL db $::POWERPLAN_BOND_PAD_PREVIEW_AFTER_DB_NAME continuation after_bond_pad_preview] \
    stage02_complete [dict create \
        type NORMAL db 02_99_powerplan.enc continuation stage02_complete] \
    stage02_exit [dict create \
        type TERMINAL db 02_100_stage02_exit.enc continuation stage02_exit] \
]
set ::PP_RESUME_MARKER_MAP [dict create \
    after_bond_pad_blockage "# RESUME_POINT: after_bond_pad_blockage" \
    after_core_ring "# RESUME_POINT: after_core_ring" \
    after_pad_pin "# RESUME_POINT: after_pad_pin" \
    after_block_rings "# RESUME_POINT: after_block_rings" \
    after_all_stripes "# RESUME_POINT: after_all_stripes" \
    after_floating_sroute "# RESUME_POINT: after_floating_sroute" \
    before_power_stripe_drc "# RESUME_POINT: before_power_stripe_drc" \
    after_power_stripe_post_check "# RESUME_POINT_DRC: after_power_stripe_post_check" \
    after_power_stripe_drc "# RESUME_POINT: after_power_stripe_drc" \
    after_power_stripe_legacy "# RESUME_POINT: after_power_stripe_legacy" \
    after_follow_pin_post_check "# RESUME_POINT_DRC: after_follow_pin_post_check" \
    after_follow_pin_drc "# RESUME_POINT: after_follow_pin_drc" \
    after_follow_pin_legacy "# RESUME_POINT: after_follow_pin_legacy" \
    before_final_via_repair_post_check "# RESUME_POINT_DRC: before_final_via_repair_post_check" \
    before_final_via_repair_drc "# RESUME_POINT: before_final_via_repair_drc" \
    after_final_via_repair_post_check "# RESUME_POINT_DRC: after_final_via_repair_post_check" \
    after_final_via_repair_drc "# RESUME_POINT: after_final_via_repair_drc" \
    after_powerplan_mesh "# RESUME_POINT: after_powerplan_mesh" \
]
# Points in the common Stage-02 tail are resumed by phase, not by slicing
# script/powerplan.tcl.  This prevents completed late operations from repeating.
set ::PP_LATE_RESUME_MAP [dict create \
    after_switch_verify    after_switch_verify \
    after_secondary_pg     after_secondary_pg \
    after_final_mesh_color after_final_mesh_color \
    after_final_check      after_final_check \
    after_bond_pad_preview after_bond_pad_preview \
    stage02_complete       stage02_complete \
    stage02_exit           stage02_exit \
]

if {![info exists ::PP_RESTORED_POINT]} { set ::PP_RESTORED_POINT "" }
if {![info exists ::PP_RESTORED_DB]}    { set ::PP_RESTORED_DB "" }
if {![info exists ::PP_RESTORE_STATE]} { set ::PP_RESTORE_STATE idle }

proc pp_checkpoint_info {point} {
    if {![dict exists $::PP_CHECKPOINTS $point]} {
        puts "ERROR: Unknown PowerPlan checkpoint '$point'."
        pp_points
        error "Invalid PowerPlan checkpoint."
    }
    return [dict get $::PP_CHECKPOINTS $point]
}

proc pp_points {} {
    puts ""
    puts "======================================================================"
    puts " PowerPlan Restore / Resume Points"
    puts "======================================================================"
    puts [format "%-32s %-9s %s" "POINT" "TYPE" "DB"]
    puts "----------------------------------------------------------------------"
    foreach point [dict keys $::PP_CHECKPOINTS] {
        set info [dict get $::PP_CHECKPOINTS $point]
        puts [format "%-32s %-9s %s" \
            $point [dict get $info type] [dict get $info db]]
    }
    puts "======================================================================"
    puts ""
}

proc pp_status {} {
    puts ""
    puts "======================================================================"
    puts " POWERPLAN RESTORE STATUS"
    puts "======================================================================"
    puts "State : $::PP_RESTORE_STATE"
    if {$::PP_RESTORED_POINT eq ""} {
        puts "Point : <none>"
        puts "DB    : <none>"
    } else {
        puts "Point : $::PP_RESTORED_POINT"
        puts "DB    : $::PP_RESTORED_DB"
        set info [pp_checkpoint_info $::PP_RESTORED_POINT]
        puts "Type  : [dict get $info type]"
        if {$::PP_RESTORE_STATE eq "suspended"} {
            puts "Next  : native Innovus resume"
        } elseif {$::PP_RESTORE_STATE eq "held"} {
            puts "Next  : pp_continue (legacy compatibility; this will arm native resume)"
        } elseif {[dict get $info type] eq "TERMINAL"} {
            puts "Next  : <none; flow tail>"
        }
    }
    puts "======================================================================"
    puts ""
}

proc pp_clear_restore_state {} {
    set ::PP_RESTORE_STATE completed
    set ::PP_RESTORED_POINT ""
    set ::PP_RESTORED_DB ""
}

proc pp_load_helpers {} {
    uplevel #0 [list source -quiet [file join $::SCRIPT_DIR power_proc.tcl]]
    uplevel #0 [list source -quiet [file join $::TOOL_DIR 01_floorplan geometry TT_proc_pd_geometry.tcl]]
    uplevel #0 [list source -quiet [file join $::SCRIPT_DIR powerplan_drc_checkpoint.tcl]]
    uplevel #0 [list source -quiet [file join $::SCRIPT_DIR powerplan_step_pause.tcl]]
    uplevel #0 [list source -quiet [file join $::SCRIPT_DIR powerplan_stage_tail.tcl]]
    uplevel #0 [list source -quiet [file join $::SCRIPT_DIR checkpoint_guard.tcl]]
    set ::TECH_MV_REPORT_STAGE 02

    # The earliest marker-based restore still needs this wrapper, which is
    # normally defined before the first supported marker in powerplan.tcl.
    if {[llength [info commands ::powerplan_stripe_from_cfg]] == 0} {
        proc ::powerplan_stripe_from_cfg {nets cfg} {
            createPowerStripe \
                [dict get $cfg direction] \
                [dict get $cfg layer] \
                $nets \
                [dict get $cfg offset] \
                [dict get $cfg width] \
                [dict get $cfg spacing] \
                [dict get $cfg pitch] \
                [dict get $cfg snap]
        }
    }
    if {[llength [info commands ::powerplan_ring_from_cfg]] == 0} {
        proc ::powerplan_ring_from_cfg {nets cfg} {
            createPowerRing $nets \
                [dict get $cfg h_layer] \
                [dict get $cfg v_layer] \
                [dict get $cfg width] \
                [dict get $cfg spacing] \
                [dict get $cfg offset] \
                [dict get $cfg wire_group]
        }
    }
}

# Rebuild runtime variables that normally exist before the first resume marker.
proc pp_init_powerplan_runtime {} {
    if {![info exists ::PD_CFG]} {
        error "PD_CFG is not defined. Re-source init.setup before PowerPlan resume."
    }

    set physical_pd_list {}
    foreach pd_name [dict keys $::PD_CFG] {
        set pd_groups [get_db groups -if \
            [format {.power_domain.name == "%s"} $pd_name]]
        set has_rects false
        foreach pd_group $pd_groups {
            set rects {}
            catch {set rects [get_db $pd_group .rects]}
            if {$rects ne "" && [llength $rects] > 0} {
                set has_rects true
                break
            }
        }
        if {!$has_rects} {
            puts "WARNING: Configured Power Domain '$pd_name' has no physical rectangles; skipping it during resumed physical PG operations."
            continue
        }
        lappend physical_pd_list $pd_name
    }

    if {[llength $physical_pd_list] == 0} {
        error "No configured Power Domain with physical rectangles was found during PowerPlan resume."
    }

    set ::powerplan_physical_pd_list $physical_pd_list
    puts "INFO: Rebuilt PowerPlan runtime variables for resume."
    puts "INFO: powerplan_physical_pd_list = $::powerplan_physical_pd_list"
}

proc pp_finish_stage02_guard {} {
    puts "INFO: Running the formal Stage-02 end guard after PowerPlan resume."
    tech_mv_stage_end_guard 02_powerplan 03_place

    set exit_db [file join $::DB_DIR 02_100_stage02_exit.enc]
    write_db $exit_db
    puts "INFO: PowerPlan final exit restore DB = $exit_db"
    puts "INFO: Stage 02 resume completed through the formal stage-end guard."
}

# Execute the continuation for a NORMAL checkpoint already loaded in memory.
proc pp_dispatch_normal_continuation {point continuation} {
    pp_load_helpers

    # Late common-tail checkpoints are resumed by phase rank.
    if {[dict exists $::PP_LATE_RESUME_MAP $continuation]} {
        set tail_point [dict get $::PP_LATE_RESUME_MAP $continuation]

        if {$tail_point eq "stage02_exit"} {
            puts "INFO: stage02_exit is already after the formal Stage-02 end guard."
            puts "INFO: No PowerPlan command is re-executed."
            return
        }

        if {$tail_point eq "stage02_complete"} {
            puts "INFO: Stage-02 tail is already complete; running only the formal stage-end guard."
            pp_finish_stage02_guard
            return
        }

        tech_mv_powerplan_stage_tail $tail_point
        pp_finish_stage02_guard
        return
    }

    # Earlier points continue from the line AFTER the durable resume marker.
    if {![dict exists $::PP_RESUME_MARKER_MAP $continuation]} {
        error "PowerPlan continuation '$continuation' has no marker strategy."
    }

    pp_init_powerplan_runtime

    set powerplan_file [file join $::SCRIPT_DIR powerplan.tcl]
    if {![file isfile $powerplan_file]} {
        error "PowerPlan script does not exist: $powerplan_file"
    }

    set fp [open $powerplan_file r]
    set data [read $fp]
    close $fp

    set marker [dict get $::PP_RESUME_MARKER_MAP $continuation]
    set marker_index [string first $marker $data]
    if {$marker_index < 0} {
        error "Cannot find resume marker '$marker' in $powerplan_file"
    }

    set marker_eol [string first "\n" $data $marker_index]
    if {$marker_eol < 0} {
        error "Malformed resume marker '$marker' in $powerplan_file"
    }

    set resume_text [string range $data [expr {$marker_eol + 1}] end]

    puts ""
    puts "======================================================================"
    puts " POWERPLAN CONTINUE"
    puts "======================================================================"
    puts "Point  : $point"
    puts "Marker : $marker"
    puts "File   : $powerplan_file"
    puts "Policy : begin AFTER marker; checkpoint itself is NOT repeated"
    puts "======================================================================"
    puts ""

    uplevel #0 $resume_text

    puts "INFO: Base powerplan continuation completed."
    puts "INFO: Continuing the common Stage-02 tail exactly once."
    tech_mv_powerplan_stage_tail
    pp_finish_stage02_guard
}

# Rebuild a native suspend boundary for an ordinary durable checkpoint.
# The DB is already loaded.  Nothing after the checkpoint runs until the user
# types native Innovus `resume`.
proc pp_restore_normal_suspend {point continuation} {
    puts ""
    puts "======================================================================"
    puts " RESTORED CHECKPOINT : READY TO RESUME"
    puts "======================================================================"
    puts "Point : $point"
    puts "DB    : $::PP_RESTORED_DB"
    puts "State : restored exactly at this durable phase boundary"
    puts ""
    puts "Inspect the restored DB if needed, then type native Innovus:"
    puts "  resume"
    puts ""
    puts "Only after resume will the Tcl AFTER this checkpoint execute."
    puts "======================================================================"
    flush stdout

    set ::PP_RESTORE_STATE suspended
    if {[llength [info commands tech_mv_checkpoint_tools]]} { tech_mv_checkpoint_tools {02_powerplan} {TT_proc_powerplan_resume} }
    suspend

    puts "INFO: Native resume received for restored checkpoint '$point'."
    set ::PP_RESTORE_STATE continuing
    pp_dispatch_normal_continuation $point $continuation
}

# Restore a DRC-violation DB that was originally written immediately before a
# native suspend.  Recreate that exact suspended operator state first.  In
# clean-required mode, DRC is rechecked after resume just like the original
# powerplan_check_drc loop; in confirmation mode, resume acknowledges it.
proc pp_restore_drc_suspend {point info} {
    pp_load_helpers

    set checkpoint [dict get $info drc]
    set continuation [dict get $info continuation]

    puts ""
    puts "======================================================================"
    puts " RESTORED SUSPEND : POWERPLAN DRC"
    puts "======================================================================"
    puts "Point      : $point"
    puts "DRC stage  : $checkpoint"
    puts "DB         : $::PP_RESTORED_DB"
    puts ""
    puts "This DB was saved immediately before the original DRC suspend."
    puts "Inspect/fix the restored DRC state, then type native Innovus:"
    puts "  resume"
    puts "======================================================================"
    flush stdout

    set ::PP_RESTORE_STATE suspended
    if {[llength [info commands tech_mv_checkpoint_tools]]} { tech_mv_checkpoint_tools {02_powerplan} {TT_proc_powerplan_resume} }
    suspend

    puts "INFO: Native resume received for restored DRC checkpoint '$checkpoint'."
    set ::PP_RESTORE_STATE continuing

    if {$::POWERPLAN_DRC_REQUIRE_CLEAN_BEFORE_CONTINUE} {
        puts "INFO: Clean-required mode is enabled; re-running DRC after restore/resume."
        powerplan_check_drc $checkpoint
    } else {
        puts "INFO: Confirmation mode: restored DRC checkpoint acknowledged by resume."
    }

    # Continue at the statement immediately after the original check block.
    pp_dispatch_normal_continuation $point $continuation
}

# Rebuild the native Stage-02 FILL_IN_CELL_BOND_PAD_041 suspend from 02_97.
proc pp_restore_suspend_bond_pad_preview {} {
    pp_load_helpers
    source -quiet [file join $::TOOL_DIR 01_floorplan TT_proc_bond_pad_preview.tcl]

    puts ""
    puts "======================================================================"
    puts [::tech_mv_library_value LIB_TEXT_016]
    puts "======================================================================"
    puts [::tech_mv_library_value LIB_TEXT_017]
    puts "Inspect the package geometry, then type native Innovus:"
    puts "  resume"
    puts "======================================================================"

    TT_bond_pad_restore_preview_suspend \
        "after complete PowerPlan" \
        $::POWERPLAN_BOND_PAD_PREVIEW_DB_NAME \
        $::POWERPLAN_BOND_PAD_PREVIEW_AFTER_DB_NAME \
        false \
        false

    # Native resume accepted/rechecked FILL_IN_CELL_BOND_PAD_041 and wrote 02_98. Continue from the
    # next Stage-02 tail phase; do not rerun the FILL_IN_CELL_BOND_PAD_041 preview itself.
    tech_mv_powerplan_stage_tail after_bond_pad_preview
    pp_finish_stage02_guard
}

proc pp_dispatch_suspend_continuation {point continuation} {
    switch -- $continuation {
        bond_pad_preview {
            pp_restore_suspend_bond_pad_preview
        }
        default {
            error "Unsupported SUSPEND PowerPlan continuation '$continuation' for '$point'."
        }
    }
}

# Internal continuation against a checkpoint DB already in memory.
# User-facing normal recovery is pp_restore + native resume.
proc pp_resume {point} {
    set info [pp_checkpoint_info $point]

    set design_name ""
    catch {set design_name [get_db current_design .name]}
    if {$design_name eq ""} {
        error "No design is in memory. Use 'pp_restore $point' first."
    }

    if {$::PP_RESTORED_POINT ne "" && $point ne $::PP_RESTORED_POINT} {
        error "Loaded checkpoint is '$::PP_RESTORED_POINT', but pp_resume requested '$point'."
    }

    set type [dict get $info type]
    set continuation [dict get $info continuation]

    switch -- $type {
        NORMAL {
            pp_restore_normal_suspend $point $continuation
        }
        SUSPEND {
            set ::PP_RESTORE_STATE suspended
            pp_dispatch_suspend_continuation $point $continuation
        }
        DRC_SUSPEND {
            pp_restore_drc_suspend $point $info
        }
        TERMINAL {
            set ::PP_RESTORE_STATE terminal
            puts "INFO: '$point' is the Stage-02 flow tail; DB restored with no remaining Tcl to resume."
        }
        default {
            error "Unsupported checkpoint type '$type' for '$point'."
        }
    }
}

# Restore implementation.
#   NORMAL      -> read_db -> [SUSPEND] -> native resume -> continuation.
#   SUSPEND     -> read_db -> rebuild original native suspend interaction.
#   DRC_SUSPEND -> read_db -> rebuild original DRC native suspend interaction.
#   TERMINAL    -> read_db only; no remaining Stage-02 Tcl exists.
#   hold=true   -> compatibility/debug mode: read_db only.
proc pp_restore_impl {point hold_normal} {
    set info [pp_checkpoint_info $point]
    set db_name [dict get $info db]
    set db_file [file join $::DB_DIR $db_name]

    if {![file exists $db_file]} {
        error "PowerPlan checkpoint DB does not exist: $db_file"
    }

    set type [dict get $info type]

    puts ""
    puts "======================================================================"
    puts " POWERPLAN RESTORE"
    puts "======================================================================"
    puts "Point : $point"
    puts "Type  : $type"
    puts "DB    : $db_file"
    puts "======================================================================"
    puts ""

    set ::PP_RESTORE_STATE loading
    set ::PP_RESTORED_POINT ""
    set ::PP_RESTORED_DB ""

    read_db $db_file

    set design_name ""
    catch {set design_name [get_db current_design .name]}
    if {$design_name eq ""} {
        set ::PP_RESTORE_STATE error
        error "read_db returned without a current design: $db_file"
    }

    set ::PP_RESTORED_POINT $point
    set ::PP_RESTORED_DB [file normalize $db_file]

    if {$type eq "TERMINAL"} {
        set ::PP_RESTORE_STATE terminal
        puts "INFO: Stage-02 tail DB restored. No remaining Stage-02 Tcl exists after '$point'."
        return $point
    }

    if {$hold_normal} {
        if {$type ne "NORMAL"} {
            error "pp_restore_hold is only valid for NORMAL checkpoints; '$point' is $type."
        }
        set ::PP_RESTORE_STATE held
        puts ""
        puts "======================================================================"
        puts " POWERPLAN CHECKPOINT HELD (LEGACY DEBUG MODE)"
        puts "======================================================================"
        puts "Design : $design_name"
        puts "Point  : $point"
        puts "No continuation has executed."
        puts "Legacy pp_continue is available, but it will only ARM a native suspend;"
        puts "you still continue the flow with native Innovus `resume`."
        puts "======================================================================"
        puts ""
        return $point
    }

    # Arm the restore point, then hand control to a GLOBAL-SCOPE driver Tcl.
    # Do not execute native suspend directly inside the interactive pp_restore
    # proc call stack: after Innovus resume that nesting can return through the
    # interactive command parser incorrectly.  The driver recreates the same
    # source-file -> suspend -> resume -> next Tcl execution shape as the normal
    # Stage-02 flow.
    set ::PP_NATIVE_RESTORE_POINT $point
    set ::PP_NATIVE_RESTORE_DRIVER [file join $::TECH_MV_RUNTIME_ROOT .. script PR TECH_MV script 02_powerplan powerplan_restore_native_driver.tcl]
    if {![file isfile $::PP_NATIVE_RESTORE_DRIVER]} {
        set ::PP_RESTORE_STATE error
        error "PowerPlan native-restore driver does not exist: $::PP_NATIVE_RESTORE_DRIVER"
    }
    uplevel #0 [list source -quiet $::PP_NATIVE_RESTORE_DRIVER]
    return $point
}

proc pp_restore {point} {
    return [pp_restore_impl $point false]
}

# Compatibility/debug entry point. Normal crash recovery should not need this.
proc pp_restore_hold {point} {
    return [pp_restore_impl $point true]
}

# Backward compatibility only.  Unlike old V1.6, this does NOT directly run the
# continuation: it reconstructs a native suspend so the actual continue command
# remains the standard Innovus `resume`.
proc pp_continue {} {
    if {$::PP_RESTORED_POINT eq "" || $::PP_RESTORE_STATE ne "held"} {
        error "No held NORMAL PowerPlan checkpoint. Use pp_restore <point> for normal recovery."
    }

    set point $::PP_RESTORED_POINT
    set info [pp_checkpoint_info $point]
    if {[dict get $info type] ne "NORMAL"} {
        error "pp_continue compatibility mode supports NORMAL checkpoints only."
    }

    puts "WARNING: pp_continue is legacy compatibility only."
    puts "WARNING: A native suspend will be created now; type `resume` to continue."
    set ::PP_NATIVE_RESTORE_POINT $point
    set ::PP_NATIVE_RESTORE_DRIVER [file join $::TECH_MV_RUNTIME_ROOT .. script PR TECH_MV script 02_powerplan powerplan_restore_native_driver.tcl]
    if {![file isfile $::PP_NATIVE_RESTORE_DRIVER]} {
        error "PowerPlan native-restore driver does not exist: $::PP_NATIVE_RESTORE_DRIVER"
    }
    uplevel #0 [list source -quiet $::PP_NATIVE_RESTORE_DRIVER]
}

# Compatibility alias.  It now has the same native-resume semantics as pp_restore.
proc pp_restore_resume {point} {
    return [pp_restore $point]
}

puts ""
puts "INFO: Loaded TT_proc_powerplan_resume.tcl - Unified Native-Resume V1.7.1"
puts {INFO: MID-FLOW: pp_restore <point> -> read_db -> [SUSPEND]innovus> -> native resume}
puts {INFO: ORIGINAL SUSPEND checkpoints are reconstructed as their original [SUSPEND] state.}
puts "INFO: FLOW TAIL: stage02_exit restores DB only; no continuation remains."
puts "INFO: pp_continue is legacy compatibility only; normal recovery uses native resume."
puts "INFO: Available points:"
pp_points


# =============================================================================
# TT_proc_powerplan_resume async handoff override
# Version: Unified Native-Resume V1.7.2 ASYNC_SOURCE_STACK_BREAK
#
# Appended by PR9 V2.3 installer.
#
# V1.7.1 still synchronously sources the native restore driver from inside the
# pp_restore call stack. When pp_restore itself is called by "source back.tcl",
# the outer source parser remains alive across suspend/resume.
#
# V1.7.2 keeps read_db synchronous, schedules the driver with "after idle", and
# RETURNS. The outer source finishes before the driver enters native suspend.
# =============================================================================

set ::TT_PP_NATIVE_RESUME_PATCH_VERSION "V1.7.2_ASYNC_SOURCE_STACK_BREAK"

proc pp_schedule_native_restore_driver {point} {
    set driver [file join $::TECH_MV_RUNTIME_ROOT .. script PR TECH_MV script 02_powerplan powerplan_restore_native_driver.tcl]

    if {![file isfile $driver]} {
        set ::PP_RESTORE_STATE error
        error "PowerPlan native-restore driver does not exist: $driver"
    }

    set ::PP_NATIVE_RESTORE_POINT $point
    set ::PP_NATIVE_RESTORE_DRIVER $driver
    set ::PP_RESTORE_STATE armed

    if {[info exists ::PP_NATIVE_RESTORE_AFTER_ID] &&
        $::PP_NATIVE_RESTORE_AFTER_ID ne ""} {
        catch {after cancel $::PP_NATIVE_RESTORE_AFTER_ID}
    }

    # Intentionally use plain Tcl 'source', not Innovus '-quiet' syntax, so the
    # deferred callback is a simple single Tcl command at global event-loop time.
    set ::PP_NATIVE_RESTORE_AFTER_ID \
        [after idle [list source $::PP_NATIVE_RESTORE_DRIVER]]

    puts "INFO: PowerPlan native restore '$point' ARMED asynchronously."
    puts "INFO: The current source/proc stack will return before Innovus enters suspend."
    puts "INFO: Driver = $::PP_NATIVE_RESTORE_DRIVER"
    return $point
}

proc pp_restore_impl {point hold_normal} {
    set info [pp_checkpoint_info $point]
    set db_name [dict get $info db]
    set db_file [file join $::DB_DIR $db_name]

    if {![file exists $db_file]} {
        error "PowerPlan checkpoint DB does not exist: $db_file"
    }

    set type [dict get $info type]

    puts ""
    puts "======================================================================"
    puts " POWERPLAN RESTORE"
    puts "======================================================================"
    puts "Point : $point"
    puts "Type  : $type"
    puts "DB    : $db_file"
    puts "======================================================================"
    puts ""

    set ::PP_RESTORE_STATE loading
    set ::PP_RESTORED_POINT ""
    set ::PP_RESTORED_DB ""

    read_db $db_file

    set design_name ""
    catch {set design_name [get_db current_design .name]}
    if {$design_name eq ""} {
        set ::PP_RESTORE_STATE error
        error "read_db returned without a current design: $db_file"
    }

    set ::PP_RESTORED_POINT $point
    set ::PP_RESTORED_DB [file normalize $db_file]

    if {$type eq "TERMINAL"} {
        set ::PP_RESTORE_STATE terminal
        puts "INFO: Stage-02 tail DB restored. No remaining Stage-02 Tcl exists after '$point'."
        return $point
    }

    if {$hold_normal} {
        if {$type ne "NORMAL"} {
            error "pp_restore_hold is only valid for NORMAL checkpoints; '$point' is $type."
        }

        set ::PP_RESTORE_STATE held
        puts ""
        puts "======================================================================"
        puts " POWERPLAN CHECKPOINT HELD (LEGACY DEBUG MODE)"
        puts "======================================================================"
        puts "Design : $design_name"
        puts "Point  : $point"
        puts "No continuation has executed."
        puts "Legacy pp_continue is available; it will asynchronously arm native resume."
        puts "======================================================================"
        puts ""
        return $point
    }

    return [pp_schedule_native_restore_driver $point]
}

proc pp_continue {} {
    if {$::PP_RESTORED_POINT eq "" || $::PP_RESTORE_STATE ne "held"} {
        error "No held NORMAL PowerPlan checkpoint. Use pp_restore <point> for normal recovery."
    }

    set point $::PP_RESTORED_POINT
    set info [pp_checkpoint_info $point]
    if {[dict get $info type] ne "NORMAL"} {
        error "pp_continue compatibility mode supports NORMAL checkpoints only."
    }

    puts "WARNING: pp_continue is legacy compatibility only."
    puts "WARNING: Native restore driver will be scheduled asynchronously."
    return [pp_schedule_native_restore_driver $point]
}

puts "INFO: TT_proc_powerplan_resume async handoff override active - $::TT_PP_NATIVE_RESUME_PATCH_VERSION"
puts "INFO: pp_restore now returns its outer source stack BEFORE the native driver enters suspend."

# =============================================================================
# TT_PP_SOURCE_FINAL_POINTS_V1_0
#
# Keep the restore/resume catalog as the LAST visible output produced when
# TT_proc_powerplan_resume.tcl is sourced.
# =============================================================================
puts ""
puts "INFO: Final PowerPlan restore/resume point list:"
pp_points

