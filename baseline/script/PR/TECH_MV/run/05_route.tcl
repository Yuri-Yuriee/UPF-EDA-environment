# Runtime adapter preserves the historical logical source path.
if {[info exists ::TECH_MV_RUNTIME_ROOT]} {
    info script [file join $::TECH_MV_RUNTIME_ROOT run/05_route.tcl]
}
# PUBLIC_EXPORT_REVIEW_REQUIRED: residual technology candidates require manual review.
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
set ::TECH_MV_REPORT_STAGE 05
source -quiet [file join $SCRIPT_DIR prepare_run_dirs.tcl]
source -quiet [file join $SCRIPT_DIR terminal_report_footer.tcl]
source -quiet [file join $SCRIPT_DIR place_checkpoint.tcl]
source -quiet [file join $SCRIPT_DIR checkpoint_guard.tcl]
source -quiet [file join $TOOL_DIR 02_powerplan secondary_pg TT_check_lp_2ndpg.tcl]

tech_mv_stage_start_guard 05_route


# -----------------------------------------------------------------------------
# SIGNAL-mode secondary PG completion.
#
# Placement/CTS is already complete at this point.  Route only LS/ISO/RET/AON
# secondary PG pins before normal signal route_design.
# -----------------------------------------------------------------------------
set TT_2NDPG_MODE [string toupper $::SECONDARY_PG_ROUTE_MODE]

if {$TT_2NDPG_MODE eq "SIGNAL"} {
    puts ""
    puts "======================================================================"
    puts " PRE-ROUTE SECONDARY PG"
    puts "======================================================================"
    puts "Mode  : SIGNAL"
    puts "Stage : 05_route, after CTS / before route_design"
    puts "======================================================================"

    # Re-check the actual post-CTS state immediately before growing 2nd-PG.
    set TT2ND_PRE_ROUTE_CHECK [TT_check_lp_2ndpg pre_route]

    # This is the exact crash-recovery database immediately before any SIGNAL
    # secondary-PG routing changes are made.
    set TT_PRE_ROUTE_2NDPG_DB [file join $DB_DIR 05_05_pre_2ndpg.enc]
    write_db $TT_PRE_ROUTE_2NDPG_DB

    if {!$::ENABLE_PRE_2NDPG_BREAKPOINT &&
        ![dict get $TT2ND_PRE_ROUTE_CHECK ok]} {
        error "Pre-route 2nd-PG readiness FAIL with breakpoint disabled. See [dict get $TT2ND_PRE_ROUTE_CHECK report]"
    }

    # Keep the reports at the very bottom immediately before the pause.
    puts ""
    puts "======================================================================"
    puts " PRE-2nd-PG MANUAL CHECKPOINT"
    puts "======================================================================"
    puts "2nd-PG readiness : [expr {[dict get $TT2ND_PRE_ROUTE_CHECK ok] ? {PASS} : {FAIL}}]"
    puts "Check report     : [dict get $TT2ND_PRE_ROUTE_CHECK report]"
    puts "Problem cells    : [dict get $TT2ND_PRE_ROUTE_CHECK problem_report]"
    puts "Restore DB       : $TT_PRE_ROUTE_2NDPG_DB"
    puts "Next operation   : grow SIGNAL 2nd-PG"
    puts "======================================================================"

    if {$::ENABLE_PRE_2NDPG_BREAKPOINT} {
        if {[llength [info commands suspend]] == 0} {
            error "Pre-2ndPG checkpoint requires native Innovus suspend, but it is unavailable."
        }
        puts "Inspect/fix the post-CTS design now."
        puts "When it is acceptable and you are ready to grow 2nd-PG, type:"
        puts "  resume"
        puts "======================================================================"
        if {[llength [info commands tech_mv_checkpoint_tools]]} { tech_mv_checkpoint_tools {05_route} {pre_2ndpg} }
        suspend
        puts "INFO: Pre-2ndPG checkpoint accepted by resume."
    }

    source -quiet [file join $::TECH_MV_RUNTIME_ROOT .. script PR TECH_MV script 02_powerplan secondary_pg flow_post_place_lp_2ndpg.tcl]

    # The database changed because secondary PG was just routed.  This is a
    # meaningful new checkpoint, so one check_place + one check_floorplan is
    # allowed here.  If suspended, resume accepts the result; no re-check.
    set TT_POST_2NDPG_CHECKPOINT \
        [tech_mv_checkpoint \
            "05_after_2ndpg_pre_route" \
            $::ENABLE_POST_2NDPG_INSPECTION_BREAKPOINT]

    write_db [file join $DB_DIR 05_10_after_2ndpg_pre_route.enc]

    puts "INFO: SIGNAL secondary PG completed."
    puts "INFO: DB: [file join $DB_DIR 05_10_after_2ndpg_pre_route.enc]"
} elseif {$TT_2NDPG_MODE eq "SROUTE"} {
    puts "INFO: SROUTE mode: secondary PG was already completed in 03_place."
} else {
    error "SECONDARY_PG_ROUTE_MODE must be SIGNAL or SROUTE, got '$::SECONDARY_PG_ROUTE_MODE'"
}

# Prevent routing of IOFILLER/RTE connections without relying on a net name.
if {[info exists ENABLE_SKIP_IOFILLER_RTE_ROUTING] && $ENABLE_SKIP_IOFILLER_RTE_ROUTING} {
    source -quiet [file join $SCRIPT_DIR skip_iofiller_rte_routing.tcl]
    tech_mv_skip_iofiller_rte_routing
} else {
    puts "INFO: IOFILLER RTE routing exclusion is disabled."
}

tech_mv_place_checkpoint "05_before_route" "05_20_before_route.enc"

switch -- [string tolower $ROUTE_MODE] {
    advanced {
        set_db route_design_antenna_diode_insertion $ROUTE_ANTENNA_DIODE_INSERTION
        set_db route_design_with_timing_driven $ROUTE_TIMING_DRIVEN
        set_db route_design_with_eco $ROUTE_ECO_ENABLE
        set_db route_design_with_si_driven $ROUTE_SI_DRIVEN
        set_db route_design_top_routing_layer $ROUTE_TOP_ROUTING_LAYER
        set_db route_design_bottom_routing_layer $ROUTE_BOTTOM_ROUTING_LAYER
        set_db route_design_detail_end_iteration $ROUTE_DETAIL_END_ITERATION
        route_design -global_detail -via_opt -wire_opt
        tech_mv_place_checkpoint "05_after_route_design" "05_30_after_route_design.enc"

        if {$ENABLE_INST_PADDING_REPAIR} {
            source -quiet [file join $::TECH_MV_RUNTIME_ROOT .. script PR TECH_MV script 03_place drc DRC_fix_inst_padding.tcl]
        } else {
            puts "INFO: Post-route instance-padding repair is disabled."
        }
        tech_mv_place_checkpoint "05_after_inst_padding" "05_40_after_inst_padding.enc"

        route_eco
        tech_mv_place_checkpoint "05_after_padding_route_eco" "05_50_after_padding_route_eco.enc"

        source -quiet [file join $::TECH_MV_RUNTIME_ROOT .. script PR TECH_MV script 05_route drc DRC_fix_metal_same_mask.tcl]
        tech_mv_place_checkpoint "05_after_same_mask_fix" "05_60_after_same_mask_fix.enc"

        route_eco
        tech_mv_place_checkpoint "05_after_same_mask_route_eco" "05_70_after_same_mask_route_eco.enc"
    }
    basic {
        route_design
        tech_mv_place_checkpoint "05_after_route_design" "05_30_after_route_design.enc"
    }
    default { error "Unsupported ROUTE_MODE '$ROUTE_MODE'" }
}
set_db delaycal_enable_si $ROUTE_DELAYCAL_ENABLE_SI
if {$ENABLE_POST_ROUTE_OPT} {
    opt_design -post_route -setup -hold -report_dir [tech_mv_report_dir 05 timing]
    opt_design -post_route -hold -report_dir [tech_mv_report_dir 05 timing]
}
if {$ENABLE_SIGNOFF_OPT} { opt_signoff -all }

tech_mv_place_checkpoint "05_after_post_route_opt" "05_80_after_post_route_opt.enc"

# Real TECH cleanup: remove temporary bond-pad protection and other
# temporary route/place blockages before the final DRC/fix_via pass.
foreach blockage_name $ROUTE_CLEANUP_ROUTE_BLOCKAGES {
    set objs [get_db route_blockages $blockage_name]
    if {[llength $objs] > 0} { delete_obj $objs }
}
if {$ROUTE_CLEANUP_DELETE_SOFT_BLOCKAGES} {
    set soft_blockages [get_db place_blockages -if {.type == soft}]
    if {[llength $soft_blockages] > 0} { delete_obj $soft_blockages }
}

if {$ENABLE_FINAL_DRC_REPAIR} {
    set_db check_drc_limit $FINAL_DRC_LIMIT
    tech_mv_check_drc
    tech_mv_native_report_command 05 via_repair [list fix_via -min_step]
    tech_mv_native_report_command 05 via_repair [list fix_via -short]
    tech_mv_native_report_command 05 via_repair [list fix_via -min_cut]
    tech_mv_check_drc
}

# Signal-only antenna pass after all native routing/cleanup operations.
source -quiet [file join $TOOL_DIR 05_route antenna TT_ANTENNA_REPAIR.tcl]
antenna_stage05

tech_mv_place_checkpoint "05_after_final_drc_repair" "05_90_after_final_drc_repair.enc"

# Post-route metal-density diagnostic.  M9 is checked by default so the report
# can be compared directly with the Stage02 PowerPlan density report.
if {$::CHECK_ALL_ENABLE && $::CHECK_STAGE05_METAL_DENSITY_ENABLE} {
    set _md_tool [file join $::TOOL_DIR 05_route reports TT_tool_report_metal_density.tcl]
    if {![file isfile $_md_tool]} { error "Metal-density tool not found: $_md_tool" }
    source -quiet $_md_tool
    TT_tool_report_metal_density \
        -layers $::CHECK_STAGE05_METAL_DENSITY_LAYERS \
        -report [file join $::REPORT_DIR 05_route_metal_density.rpt] \
        -check_min [expr {$::CHECK_STAGE05_METAL_DENSITY_MIN_ENABLE ? 1 : 0}] \
        -check_max [expr {$::CHECK_STAGE05_METAL_DENSITY_MAX_ENABLE ? 1 : 0}] \
        -fatal [expr {$::CHECK_STAGE05_METAL_DENSITY_FATAL ? 1 : 0}]
    unset _md_tool
} else {
    puts "INFO: CHECK SKIPPED: Stage05 metal density (config disabled)."
}

tech_mv_place_checkpoint "05_route_final" ""
write_db [file join $DB_DIR 05_99_route.enc]

tech_mv_stage_end_guard 05_route 06_finish

puts ""
puts "======================================================================"
puts " FINAL ROUTE REPORT SUMMARY"
puts "======================================================================"
if {[info exists TT2ND_PRE_ROUTE_CHECK]} {
    puts "Pre-2ndPG readiness : [expr {[dict get $TT2ND_PRE_ROUTE_CHECK ok] ? {PASS} : {FAIL}}]"
    puts "Pre-2ndPG report    : [dict get $TT2ND_PRE_ROUTE_CHECK report]"
    puts "Problem cells       : [dict get $TT2ND_PRE_ROUTE_CHECK problem_report]"
}
puts "Route DB            : [file join $DB_DIR 05_99_route.enc]"
puts "======================================================================"

set _stage05_extra_reports {}
if {[info exists TT2ND_PRE_ROUTE_CHECK]} {
    lappend _stage05_extra_reports [dict get $TT2ND_PRE_ROUTE_CHECK report]
    lappend _stage05_extra_reports [dict get $TT2ND_PRE_ROUTE_CHECK problem_report]
}
tech_mv_terminal_report_footer 05 $_stage05_extra_reports
unset _stage05_extra_reports
