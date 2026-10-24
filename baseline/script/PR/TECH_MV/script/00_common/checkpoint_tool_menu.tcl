# Runtime adapter preserves the historical logical source path.
if {[info exists ::TECH_MV_RUNTIME_ROOT]} {
    info script [file join $::TECH_MV_RUNTIME_ROOT run/tool/00_common/TT_checkpoint_tool_menu.tcl]
} else {
    info script [file normalize [file join [file dirname [info script]] .. .. run/tool/00_common/TT_checkpoint_tool_menu.tcl]]
}
# PUBLIC_EXPORT_REVIEW_REQUIRED: residual technology candidates require manual review.
# Display-only checkpoint menu. Never loads tools or executes listed commands.
namespace eval ::tech_checkpoint_menu {
    variable stage
    if {![info exists stage]} {set stage ""}
    variable checkpoint
    if {![info exists checkpoint]} {set checkpoint ""}
    variable rows {
        {common inspect check_place {Check placement}}
        {common inspect check_floorplan {Check floorplan}}
        {common inspect check_drc {Check DRC}}
        {01 save FP_save {Save edited floorplan DB}}
        {01 inspect fp_points {List floorplan checkpoints}}
        {01 inspect fp_status {Show floorplan restore status}}
        {02 inspect pp_points {List powerplan checkpoints}}
        {02 inspect pp_status {Show powerplan restore status}}
        {02 inspect TT_sdp_check_all {Check SDP / SWKO / PGROW}}
        {02 inspect TT_sdp_tools {Show SDP tool help}}
        {02 inspect TT_SDP_RESCUE_blk_report {Report SDP blockages}}
        {02 inspect TT_SDP_RESCUE_endcap_report {Report SDP endcaps}}
        {02 inspect sw_m4_check {Check M4 landing}}
        {02 inspect sw_m4_connectivity {Check M4 connectivity}}
        {05 inspect TT_tool_report_metal_density {Report metal density}}
        {06 inspect TT_tool_report_metal_density {Report metal density}}
        {01 pd_read PD_help {Show PD commands and target rules}}
        {01 pd_read PD_targets {Resolve target power domains}}
        {01 pd_read PD_select {List selected power domains}}
        {01 pd_read PD_all {List all power domains}}
        {01 pd_read PD_core {Show core geometry}}
        {01 pd_read PD_bbox {Show target PD bounding boxes}}
        {01 pd_change PD_base {Rebuild PD from core and offsets}}
        {01 pd_change PD_cut {Cut overlapping PD geometry}}
        {01 pd_change PD_snap {Snap power domains}}
        {01 pd_change PD_merge {Merge target PD rectangles}}
        {01 pd_change PD_fill_holes {Fill holes in target PD geometry}}
        {01 pd_change PD_reshape {Scale target PD dimensions}}
        {01 pd_change PD_size {Set target PD dimensions}}
        {01 pd_change PD_ratio {Set target PD aspect ratio}}
        {01 pd_change PD_blk_inner {Create inner PD blockages}}
        {01 pd_change PD_blk_outer {Create outer PD blockages}}
        {01 pd_change PD_blk {Create inner or outer PD blockages}}
        {02 change TT_SDP_PGROW_repair {Repair PGROW}}
        {02 change TT_refine_violating_sdps {Repair SDP violations}}
        {02 change sw_m4_repair {Repair M4 landing}}
        {02 change TT_SDP_RESCUE_native_first {Run SDP rescue}}
    }
}

proc tech_checkpoint_command_usage {command} {
    if {$command eq "PD_blk"} {return "PD_blk <inner|outer> <top> <bottom> <left> <right> ?target? ?strict?"}
    set usage $command
    if {[llength [info procs ::$command]]} {
        foreach argument [info args ::$command] {
            if {$argument eq "args"} { append usage " ?options?"; continue }
            if {![info default ::$command $argument default]} {
                append usage " <$argument>"
            } else {
                append usage " ?$argument?"
            }
        }
    }
    return $usage
}


# Context is derived from the actual flow gate, never from loaded commands.
proc tech_checkpoint_phase {stage checkpoint} {
    if {$stage eq "01"} {
        if {$checkpoint eq "TT_proc_bond_pad_preview"} {
            if {[info exists ::TECH_BOND_PAD_PREVIEW_RELOAD_IO_ACTIVE] && $::TECH_BOND_PAD_PREVIEW_RELOAD_IO_ACTIVE} {return io_edit}
            return io_fixed
        }
        if {$checkpoint in {manual_place_power_domain floorplan manual_pd_snap}} {return pd_edit}
        return floorplan_inspect
    }
    if {$stage eq "02"} {
        if {$checkpoint eq "add_endcaps"} {return endcap}
        if {[info exists ::TECH_MV_ENDCAP_CHECKPOINT_COMPAT_NAMES] &&
            [lsearch -exact $::TECH_MV_ENDCAP_CHECKPOINT_COMPAT_NAMES $checkpoint] >= 0} {return endcap}
        if {[regexp -nocase {sdp|swko|pgrow|endcap|welltap} $checkpoint]} {return sdp}
        if {[regexp -nocase {2nd|rail|stage_switch_verify|stage_final|stage_02_database|final_power_mesh} $checkpoint]} {return rail}
        if {[regexp {follow_pin|followpin|before_final|after_final|legacy_powerplan_database|power_mesh_colorization|macro_place_pg} $checkpoint]} {return followpin}
        if {[regexp {stripe|M9|via8|floating} $checkpoint]} {return stripe}
        if {[regexp {ring|pad_pin_connection} $checkpoint]} {return ring}
        return powerplan_inspect
    }
    if {$stage eq "03"} {
        if {[regexp -nocase {2nd|rail|post2nd} $checkpoint]} {return rail}
        return place
    }
    if {$stage in {05 06}} {
        if {[regexp -nocase {pre.?2nd} $checkpoint]} {return pre_rail}
        if {[regexp -nocase {2nd|rail} $checkpoint]} {return rail}
        return route
    }
    return inspect
}

proc tech_checkpoint_row_allowed {row phase} {
    lassign $row row_stage kind command label
    if {$row_stage eq "common"} {return true}
    if {$command in {fp_points fp_status FP_save pp_points pp_status}} {return true}
    if {[string match PD_* $command]} {return [expr {$phase eq "pd_edit"}]}
    if {[string match sw_m4_* $command]} {return [expr {$phase eq "rail"}]}
    if {$row_stage eq "02"} {return [expr {$phase eq "sdp"}]}
    return [expr {$phase eq "route"}]
}

# Additional public entries reviewed against object type and flow prerequisites.
# Entries contain phase list, group, invocation, description, direct module path.
set ::tech_checkpoint_menu::context_rows {
    {{stripe followpin rail route} inspect {TT_via_drc_stats} {Count special-via cut DRC markers} {05_route/drc/TT_DRC_fix_via.tcl}}
    {{stripe followpin rail route} change {TT_via_drc_fix preview} {Preview overlapping special-via cleanup; apply is explicit} {05_route/drc/TT_DRC_fix_via.tcl}}
    {{stripe followpin rail route} inspect {TT_via8_drc_stats} {Count VIA8 cut DRC markers after M9 stripes} {05_route/drc/TT_DRC_fix_via8_after_m9.tcl}}
    {{stripe followpin rail route} change {TT_via8_drc_cleanup preview} {Preview VIA8 cleanup; apply is explicit} {05_route/drc/TT_DRC_fix_via8_after_m9.tcl}}
    {{ring stripe followpin rail route} change {TT_tool_remove_ring_overlap_metal -dry_run 1} {Preview overlapping ring metal; review layers first} {05_route/drc/TT_tool_remove_ring_overlap_metal.tcl}}
    {{followpin rail} inspect {TT_FOLLOWPIN_VIA_CHECK} {Check followpin vias; highlights failures and may raise error} {02_powerplan/TT_check_followpin_special_via.tcl}}
    {{sdp} inspect {TT_SDP_PGROW_scan} {Inspect powergate row rules} {02_powerplan/TT_sdp_powergate_row_rules.tcl}}
    {{sdp} inspect {TT_PR7_scan_internal_sdp_structure} {[HIGHLIGHT] Inspect internal SDP; refreshes index 1 (clears prior marks)} {02_powerplan/TT_refine_internal_gap_sdps.tcl}}
    {{sdp} inspect {TT_PR7_scan_sdp_origin_delta} {Inspect SDP origin mismatch} {02_powerplan/TT_refine_internal_gap_sdps.tcl}}
    {{sdp} change {TT_refine_switch_gap_sdps} {Repair switch keepout gaps; requires existing SDP groups} {02_powerplan/TT_repair_switch_gap_hard_keepout.tcl}}
    {{sdp} change {TT_refine_internal_gap_sdps} {Repair SDP internal gaps; save DB first} {02_powerplan/TT_refine_internal_gap_sdps.tcl}}
    {{sdp} change {TT_PR7_manual_sync_selected} {Sync origins of selected SDP groups; check targets first} {02_powerplan/sdp/TT_PR7_manual_sdp_origin.tcl}}
    {{rail} inspect {sw_m4_check} {Check switch M4 landing after rails exist} {02_powerplan/TT_SW_M4_tools.tcl}}
    {{rail} inspect {sw_m4_connectivity} {Check switch M4 connectivity after rails exist} {02_powerplan/TT_SW_M4_tools.tcl}}
    {{rail} change {sw_m4_repair} {Repair switch M4 landing; restorable DB required} {02_powerplan/TT_SW_M4_tools.tcl}}
    {{route} inspect {antenna_check} {Fresh signal antenna check and safe candidate classification} {05_route/antenna/TT_ANTENNA_REPAIR.tcl}}
    {{route} inspect {antenna_verify} {Fresh signal antenna verification} {05_route/antenna/TT_ANTENNA_REPAIR.tcl}}
    {{route} inspect {antenna_status} {Show last repair/checkpoint/verification status} {05_route/antenna/TT_ANTENNA_REPAIR.tcl}}
    {{route} change {antenna_repair} {One signal-only layer-hopping pass; saves DB first; no diodes} {05_route/antenna/TT_ANTENNA_REPAIR.tcl}}
    {{route} inspect {antenna_final_check} {Fresh signal/clock/connectivity verification; power is opt-in} {06_finish/antenna/TT_ANTENNA_FINAL_CHECK.tcl}}
    {{route} inspect {metal_color_scan} {Locate wire candidates from current DRC markers} {05_route/drc/TT_DRC_fix_metal_color.tcl}}
    {{route} inspect {metal_color_check} {Check discovered wire candidates and safety guards} {05_route/drc/TT_DRC_fix_metal_color.tcl}}
    {{route} change {metal_color_plan} {Preview a metal-color repair plan; requires routed wires} {05_route/drc/TT_DRC_fix_metal_color.tcl}}
    {{route} inspect {TT_J2J_stats} {Inspect jog-to-jog DRC markers} {05_route/drc/TT_DRC_fix_jog_to_jog.tcl}}
    {{route} change {TT_fix_jog_to_jog preview} {Preview jog-to-jog repair; apply is explicit} {05_route/drc/TT_DRC_fix_jog_to_jog.tcl}}
    {{sdp} inspect {TT_PR7_coordinate_guided_preview} {Preview custom SDP candidates; native SDP legality must be clean} {02_powerplan/sdp/TT_PR7_coordinate_guided_repair.tcl}}
    {{sdp} inspect {TT_SDP_REPAIR_preview} {Preview three-member SDP repair; validate members first} {02_powerplan/sdp/TT_proc_repair_2row_sdp.tcl}}
    {{sdp} inspect {TT_SDP_RESCUE_help} {Show native-first rescue prerequisites and commands} {02_powerplan/TT_sdp_live_rescue_native_first.tcl}}
    {{sdp} inspect {TT_sdp_tools} {Show SDP / PGROW / SWKO repair commands and gates} {02_powerplan/sdp/TT_sdp_toolbox.tcl}}
    {{endcap sdp} inspect {TT_SWEC_report} {Report switch / endcap overlap; check target instances first} {02_powerplan/TT_proc_remove_sw_endcap_overlap.tcl}}
    {{rail} inspect {TT_SW_VIA_check_selected} {Inspect selected VIA1..VIA4 against its same-net upper metal; read-only} {02_powerplan/power_switch/TT_check_switch_via4_m5.tcl}}
    {{rail} inspect {TT_SW_PG_check} {Check all configured SW VIA1-to-M5 geometry paths; clears old highlights} {02_powerplan/power_switch/TT_check_switch_via4_m5.tcl}}
    {{rail} inspect {TT_SW_PG_repair_preview} {Preview existing M4-landing/VIA4 repair for reported no-path SWs; no routing writes} {02_powerplan/power_switch/TT_check_switch_via4_m5.tcl}}
    {{rail} change {TT_SW_PG_repair_apply} {Apply reviewed plan; automatic pre-repair DB, default one SW, native postchecks} {02_powerplan/power_switch/TT_check_switch_via4_m5.tcl}}
    {{rail} inspect {TT_SW_PG_selected} {Check selected SW instances through VIA enclosures; read-only} {02_powerplan/power_switch/TT_check_switch_via4_m5.tcl}}
    {{rail} inspect {TT_SW_PG_diagnose_no_target} {Explain missing seeds in the last SW report} {02_powerplan/power_switch/TT_check_switch_via4_m5.tcl}}
    {{rail} inspect {TT_SW_PG_diagnose_selected_via} {Explain why the selected VIA is excluded from SW seeds} {02_powerplan/power_switch/TT_check_switch_via4_m5.tcl}}
    {{rail} inspect {TT_SW_VIA_check} {Inspect switch VIA1..VIA4 coverage up to M5; read-only} {02_powerplan/power_switch/TT_check_switch_via4_m5.tcl}}
    {{rail} inspect {TT_check_lp_2ndpg} {Inspect secondary PG pin/net mapping (not physical rail connectivity)} {02_powerplan/secondary_pg/TT_check_lp_2ndpg.tcl}}
    {{rail} inspect {TT_CP2_preview} {Preview LP placement violations after secondary PG routing} {03_place/drc/TT_DRC_fix_post2nd_checkplace.tcl}}
    {{rail} change {TT_CP2_repair} {Repair eligible LP placement and reconnect secondary PG; saves rollback DB} {03_place/drc/TT_DRC_fix_post2nd_checkplace.tcl}}
    {{route} inspect {TT_LVS_help} {Show logical / physical connectivity debug commands} {99_debug/TT_proc_LVS_debug.tcl}}

    {{sdp} inspect {TT_SW_GAP_highlight_bad} {[HIGHLIGHT] Locate SW-gap violating SDP members (index 2)} {02_powerplan/sdp/TT_sdp_sw_gap_highlight.tcl}}
    {{sdp} inspect {TT_SDP_PGROW_highlight_bad} {[HIGHLIGHT] Locate PGROW bad cells (clears prior GUI marks)} {02_powerplan/TT_sdp_powergate_row_rules.tcl}}

    {{sdp} inspect {TT_SW_GAP_report_pairs} {Explain each SW-gap pair: member hit vs envelope-only} {02_powerplan/sdp/TT_sdp_sw_gap_highlight.tcl}}
    {{sdp} inspect {TT_SW_GAP_highlight_pair} {[HIGHLIGHT] Show one SDP / switch pair at indexes 2 / 3} {02_powerplan/sdp/TT_sdp_sw_gap_highlight.tcl}}

}

proc checkpoint_tools {{detail ""}} {
    if {$detail ni {"" all}} {
        puts "Usage: checkpoint_tools ?all?"
        return
    }
    variable ::tech_checkpoint_menu::stage
    variable ::tech_checkpoint_menu::checkpoint
    variable ::tech_checkpoint_menu::rows
    puts ""
    set phase [tech_checkpoint_phase [string range $stage 0 1] $checkpoint]
    puts "-- Tools | $stage | $checkpoint --"
    puts "Context: $phase"
    if {$phase in {io_edit pd_edit} && [llength [info commands ::TT_IOPAD_GUI_START]]} {
        puts "ioPADt GUI"
        puts "  TT_IOPAD_GUI_START                   Open ioPADt (detached)"
        if {[llength [info commands ::TT_IOPAD_GUI_STATUS]]} {puts "  TT_IOPAD_GUI_STATUS                  Show GUI process status"}
    }
    set displayed 0
    foreach kind {inspect pd_read save pd_change change} {
        set heading false
        set count 0
        foreach row $rows {
            lassign $row row_stage row_kind command label
            if {$row_kind ne $kind || ($row_stage ne "common" && $row_stage ne [string range $stage 0 1])} {continue}
            if {![tech_checkpoint_row_allowed $row $phase]} {continue}
            if {![llength [info commands ::$command]]} {continue}

            if {!$heading} {
                if {$kind eq "inspect"} {puts "Inspect / report"} elseif {$kind eq "pd_read"} {puts "PD inspect"} elseif {$kind eq "save"} {puts "Save DB"} elseif {$kind eq "pd_change"} {puts "PD geometry (modifies design; confirm targets first)"} else {puts "Modify design (check prerequisites first)"}
                set heading true
            }
            puts [format "  %-28s %s" $command $label]
            set usage [tech_checkpoint_command_usage $command]
            if {$usage ne $command} {puts "    Usage: $usage"}
            incr count
            incr displayed
        }
    }
    set modules {}
    puts "Context tools (preview / inspect first)"
    foreach row $::tech_checkpoint_menu::context_rows {
        lassign $row phases kind invocation label module
        if {$phase ni $phases} {continue}
        if {$module eq "02_powerplan/TT_sdp_live_rescue_native_first.tcl" && ![llength [info commands ::TT_SDP_RESCUE_help]]} {continue}
        set command [lindex $invocation 0]
        set loaded [expr {[llength [info commands ::$command]] > 0}]
        if {$loaded} {set status "ready"} else {set status "load"}
        puts [format "  %-38s %s (%s)" $invocation $label $status]
        if {$loaded && $invocation eq $command} {
            set usage [tech_checkpoint_command_usage $command]
            if {$usage ne $command} {puts "    Usage: $usage"}
        }
        if {!$loaded && $module ni $modules} {lappend modules $module}
        incr displayed
    }
    if {[llength $modules]} {
        puts "Manual load (definitions only; configured init.setup required):"
        foreach module $modules {
            puts [format {  source -quiet [file join $TOOL_DIR %s %s]} [file dirname $module] [file tail $module]]
        }
        puts "Then run checkpoint_tools again. Nothing is loaded or executed by this menu."
    }
    if {!$displayed} {puts "  No registered tools loaded. Inspect the current result in the GUI."}
    if {[llength [info commands ::write_db]]} {puts "Save DB: write_db <full_db_path> (choose your filename)"}
    puts "Continue: resume | Menu: checkpoint_tools | More: checkpoint_tools all"
    puts "Inspect / preview before APPLY. Save DB before repairs. Original resume rules still apply."
    puts "--------------------------------------------------------------------"
}

proc tech_mv_checkpoint_tools {stage checkpoint} {
    if {[regexp {(0[0-6])} $stage number]} {set stage $number}
    set ::tech_checkpoint_menu::stage $stage
    set ::tech_checkpoint_menu::checkpoint $checkpoint
    # A display failure must not interfere with the original suspend behavior.
    if {[catch {checkpoint_tools} message]} {puts "Tool menu unavailable; follow the original checkpoint instructions."}
}
