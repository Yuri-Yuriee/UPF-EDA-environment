# Load definitions only; no APR action or setup reload is performed here.
if {![llength [info commands ::tech_mv_library_value]]} {
    if {[info exists ::TOOL_DIR]} {
        source -quiet [file join $::TECH_MV_RUNTIME_ROOT .. script PR TECH_MV script 00_common private_parameter_config.tcl]
    } else {
        source -quiet [file join $::TECH_MV_RUNTIME_ROOT .. script PR TECH_MV script 00_common private_parameter_config.tcl]
    }
}
# PUBLIC_EXPORT_REVIEW_REQUIRED: residual technology candidates require manual review.
# =============================================================================
# EndCap / boundary-tap insertion
# =============================================================================
# Run only after final Power-Domain geometry, fixed Hard Macros and
# finish_floorplan.
#
# EndCap insertion uses two passes:
#   1. Global pass without -power_domain.
#   2. One pass for every physical Power Domain using
#        add_endcaps -power_domain <PD_NAME>
#
# IMPORTANT:
# The original TECH_MV script named BOUNDARY_PROW*/BOUNDARY_NROW* cells.
# Some TECH library deliveries do not load those cells. This version checks
# the actual Innovus base-cell database before setting every cell attribute, so
# nonexistent cells are never passed to add_endcaps.

puts "User script [info script]"

# -----------------------------------------------------------------------------
# Remove unused GACORE alternate rows before EndCap insertion.
# configured library cell EndCaps use site=core, while this library has no
# site=gacore EndCap master.  The helper removes GACORE rows only when the
# design contains zero GACORE-site instances.
# -----------------------------------------------------------------------------
if {[info exists REMOVE_UNUSED_GACORE_ROWS] && $REMOVE_UNUSED_GACORE_ROWS} {
    source -quiet [file join $SCRIPT_DIR remove_unused_site_rows.tcl]
    set gacore_site gacore
    if {[info exists GACORE_SITE_NAME] && $GACORE_SITE_NAME ne ""} {
        set gacore_site $GACORE_SITE_NAME
    }
    tech_mv_remove_unused_site_rows $gacore_site
}

# =============================================================================
# TT_PRE_SW_BOTTOM_ROW_TRIM_HOOK_V1_0
#
# Power Switch is a 2-row cell.  Before EndCaps/SWs exist, make every
# switch-bearing PD rectangle contain an even number of usable core rows.
# Explicit project policy: if one row must be removed, ALWAYS remove BOTTOM.
# =============================================================================
set _tt_swrow_tool [file join $::TECH_MV_RUNTIME_ROOT .. script PR TECH_MV script 01_floorplan endcap_welltap proc_trim_powergate_bottom_row.tcl]
if {![file isfile $_tt_swrow_tool]} {
    error "Missing pre-SW bottom-row trim tool: $_tt_swrow_tool"
}
source -quiet $_tt_swrow_tool
set _tt_swrow_trimmed [TT_SWROW_trim_bottom apply]
puts "INFO: Pre-SW bottom-row topology trim removed $_tt_swrow_trimmed row segment set(s)."
unset _tt_swrow_trimmed
unset _tt_swrow_tool

# -----------------------------------------------------------------------------
# Pre-EndCap recovery checkpoint
# -----------------------------------------------------------------------------
# Save the design immediately before any EndCap / boundary-tap insertion.
# This gives the flow a clean restart point for EndCap debugging without
# repeating import/floorplan/macro placement.  Never overwrite the checkpoint
# from a DB that already contains EndCaps.
if {[info exists DB_DIR] && $DB_DIR ne ""} {
    set ec_preexisting_endcaps [get_db insts ENDCAP*]
    if {[llength $ec_preexisting_endcaps] == 0} {
        set ec_pre_endcap_db [file join $DB_DIR 01_70_before_boundary_cells.enc]
        puts "INFO: Saving pre-EndCap checkpoint: $ec_pre_endcap_db"
        write_db $ec_pre_endcap_db
    } else {
        puts "WARNING: Found [llength $ec_preexisting_endcaps] existing ENDCAP* instances."
        puts "WARNING: Skip writing 01_70_before_boundary_cells.enc to avoid overwriting a clean pre-EndCap checkpoint."
    }
} else {
    puts "WARNING: DB_DIR is unavailable; pre-EndCap checkpoint was not saved."
}

# -----------------------------------------------------------------------------
# Loaded-cell validation helpers
# -----------------------------------------------------------------------------
proc ec_get_loaded_base_cell_names {} {
    set names {}

    foreach cell [get_db base_cells] {
        set name [get_db $cell .name]

        if {$name ne "" && [lsearch -exact $names $name] < 0} {
            lappend names $name
        }
    }

    return $names
}

proc ec_available_cells {loaded_names candidates label} {
    set available {}
    set missing {}

    foreach cell_name $candidates {
        if {[lsearch -exact $loaded_names $cell_name] >= 0} {
            lappend available $cell_name
        } else {
            lappend missing $cell_name
        }
    }

    if {[llength $missing] > 0} {
        puts "WARNING: $label cell(s) are not loaded and will be skipped:"

        foreach cell_name $missing {
            puts "WARNING:   $cell_name"
        }
    }

    return $available
}

proc ec_set_cell_attribute {attribute candidates loaded_names {required false}} {
    set available [ec_available_cells $loaded_names $candidates $attribute]

    if {[llength $available] == 0} {
        if {$required} {
            error "No valid loaded cell is available for $attribute. Candidates: $candidates"
        }

        puts "INFO: $attribute is not set because none of its candidates are loaded."
        return {}
    }

    set_db $attribute $available
    puts "INFO: $attribute = $available"

    return $available
}

set ec_loaded_cells [ec_get_loaded_base_cell_names]

if {[llength $ec_loaded_cells] == 0} {
    error "No base cells are loaded; EndCap insertion cannot continue."
}

set ec_loaded_boundary_cells {}

foreach cell_name $ec_loaded_cells {
    if {[string match [::tech_mv_library_value LIB_MATCH_003] $cell_name]} {
        lappend ec_loaded_boundary_cells $cell_name
    }
}

puts [::tech_mv_library_value LIB_TEXT_005]
foreach cell_name [lsort $ec_loaded_boundary_cells] {
    puts "INFO:   $cell_name"
}

# -----------------------------------------------------------------------------
# Original TECH_MV candidate names
# -----------------------------------------------------------------------------
# Left/right cells are essential for row-end termination.
ec_set_cell_attribute add_endcaps_left_edge \
    $ENDCAP_LEFT_EDGE_CELLS $ec_loaded_cells true

ec_set_cell_attribute add_endcaps_right_edge \
    $ENDCAP_RIGHT_EDGE_CELLS $ec_loaded_cells true

# Corner cells are used only when present in this library delivery.
ec_set_cell_attribute add_endcaps_left_top_corner \
    $ENDCAP_LEFT_TOP_CORNER_CELLS $ec_loaded_cells false

ec_set_cell_attribute add_endcaps_left_bottom_corner \
    $ENDCAP_LEFT_BOTTOM_CORNER_CELLS $ec_loaded_cells false

# These PROW/NROW names existed in the original script. Do not send them to
# Innovus unless they are actually loaded.
set ec_top_edge_cells [ec_set_cell_attribute add_endcaps_top_edge $ENDCAP_TOP_EDGE_CELLS $ec_loaded_cells false]

set ec_bottom_edge_cells [ec_set_cell_attribute add_endcaps_bottom_edge $ENDCAP_BOTTOM_EDGE_CELLS $ec_loaded_cells false]

# Small corner-fill cells are optional.
ec_set_cell_attribute add_endcaps_left_top_edge \
    $ENDCAP_CORNER_FILL_CELLS $ec_loaded_cells false

ec_set_cell_attribute add_endcaps_right_top_edge \
    $ENDCAP_CORNER_FILL_CELLS $ec_loaded_cells false

ec_set_cell_attribute add_endcaps_left_bottom_edge \
    $ENDCAP_CORNER_FILL_CELLS $ec_loaded_cells false

ec_set_cell_attribute add_endcaps_right_bottom_edge \
    $ENDCAP_CORNER_FILL_CELLS $ec_loaded_cells false

# Boundary-tap cells can cover legal top/bottom row boundaries when the
# dedicated PROW/NROW family is absent.
set ec_top_tap_cells [ec_available_cells \
    $ec_loaded_cells \
    $ENDCAP_TOP_TAP_CELLS \
    add_well_taps_top_tap_cell]

set ec_bottom_tap_cells [ec_available_cells \
    $ec_loaded_cells \
    $ENDCAP_BOTTOM_TAP_CELLS \
    add_well_taps_bottom_tap_cell]

set_db add_well_taps_rule $ENDCAP_WELL_TAP_RULE

if {[llength $ec_top_tap_cells] > 0} {
    set_db add_well_taps_top_tap_cell [lindex $ec_top_tap_cells 0]
    puts "INFO: add_well_taps_top_tap_cell = [lindex $ec_top_tap_cells 0]"
}

if {[llength $ec_bottom_tap_cells] > 0} {
    set_db add_well_taps_bottom_tap_cell [lindex $ec_bottom_tap_cells 0]
    puts "INFO: add_well_taps_bottom_tap_cell = [lindex $ec_bottom_tap_cells 0]"
}

if {
    [llength $ec_top_tap_cells] > 0 &&
    [llength $ec_bottom_tap_cells] > 0
} {
    set_db add_endcaps_boundary_tap true
    puts "INFO: add_endcaps_boundary_tap = true"
} else {
    set_db add_endcaps_boundary_tap false
    puts "WARNING: Boundary-tap insertion is disabled because a top or bottom tap cell is missing."
}

if {[llength $ec_top_edge_cells] == 0} {
    puts "INFO: Dedicated top-edge PROW cells are unavailable."
    puts "INFO: Top row boundaries will rely on the loaded boundary-tap cells."
}

if {[llength $ec_bottom_edge_cells] == 0} {
    puts "INFO: Dedicated bottom-edge NROW cells are unavailable."
    puts "INFO: Bottom row boundaries will rely on the loaded boundary-tap cells."
}

# -----------------------------------------------------------------------------
# Configuration defaults
# -----------------------------------------------------------------------------

# Convert a Power Domain name into a legal, stable instance-name prefix.
# A different prefix is used for every invocation so the per-PD pass does not
# replace or reclassify EndCaps inserted by the global pass.
proc ec_make_prefix {base pd_name} {
    set clean_name $pd_name
    regsub -all {[^[:alnum:]]+} $clean_name {_} clean_name
    set clean_name [string trim $clean_name {_}]
    if {$clean_name eq ""} {
        set clean_name PD
    }
    return "${base}_${clean_name}"
}

proc ec_pd_should_skip {pd_name} {
    if {[info exists ::ENDCAP_DEFAULT_POWER_DOMAIN] &&
        $pd_name eq $::ENDCAP_DEFAULT_POWER_DOMAIN} {
        return true
    }

    if {[info exists ::ENDCAP_EXCLUDE_POWER_DOMAIN_PATTERNS]} {
        foreach pattern $::ENDCAP_EXCLUDE_POWER_DOMAIN_PATTERNS {
            if {[string match $pattern $pd_name]} {
                return true
            }
        }
    }
    return false
}

# Return NON-DEFAULT physical Power Domains that must receive an EndCap pass.
# The default domain is handled by the global add_endcaps pass.
#
# IMPORTANT:
# A default domain such as PD_core may not own a separate physical group/rect.
# Filtering only on group.rects therefore drops the default domain even though
# `add_endcaps -power_domain PD_core` is required by check_endcaps.
#
# Selection policy:
#   * Explicit ENDCAP_POWER_DOMAIN_LIST: use it exactly (deduplicated).
#   * Auto mode: start from PD_CFG (includes logical/default domains), then
#     append any additional PDs discovered from physical groups.
proc ec_get_power_domains_for_endcaps {} {
    # Explicit list is authoritative.  Do not reject a default domain merely
    # because it has no dedicated group rectangle.
    if {[info exists ::ENDCAP_POWER_DOMAIN_LIST] &&
        $::ENDCAP_POWER_DOMAIN_LIST ne "" &&
        $::ENDCAP_POWER_DOMAIN_LIST ne "auto"} {
        set ordered {}
        foreach pd_name $::ENDCAP_POWER_DOMAIN_LIST {
            if {$pd_name eq "" || [ec_pd_should_skip $pd_name]} {
                continue
            }
            if {[lsearch -exact $ordered $pd_name] < 0} {
                lappend ordered $pd_name
            }
        }
        return $ordered
    }

    set ordered {}

    # PD_CFG is the primary source because it also contains the default domain
    # (for example PD_core), which may have no standalone physical rectangle.
    if {[info exists ::PD_CFG]} {
        foreach pd_name [dict keys $::PD_CFG] {
            if {$pd_name eq "" || [ec_pd_should_skip $pd_name]} {
                continue
            }
            if {[lsearch -exact $ordered $pd_name] < 0} {
                lappend ordered $pd_name
            }
        }
    }

    # Append PDs found through physical groups so the flow still catches any
    # domain not listed in PD_CFG.
    foreach group [get_db groups] {
        set pd_name ""
        catch { set pd_name [get_db $group .power_domain.name] }
        if {$pd_name eq "" || [ec_pd_should_skip $pd_name]} {
            continue
        }

        if {[lsearch -exact $ordered $pd_name] < 0} {
            lappend ordered $pd_name
        }
    }

    return $ordered
}

# -----------------------------------------------------------------------------
# Pass 1: no Power Domain specified
# -----------------------------------------------------------------------------
if {$ENDCAP_GLOBAL_PASS_ENABLE} {
    puts "INFO: EndCap global pass: add_endcaps -prefix $ENDCAP_GLOBAL_PREFIX"
    add_endcaps -prefix $ENDCAP_GLOBAL_PREFIX
} else {
    puts "INFO: EndCap global pass is disabled."
}

# -----------------------------------------------------------------------------
# Pass 2: repeat for each physical Power Domain
# -----------------------------------------------------------------------------
if {$ENDCAP_POWER_DOMAIN_PASS_ENABLE} {
    set endcap_pd_names [ec_get_power_domains_for_endcaps]
    if {[llength $endcap_pd_names] == 0} {
        error "EndCap per-Power-Domain pass is enabled, but no Power Domain was found from ENDCAP_POWER_DOMAIN_LIST/PD_CFG/groups."
    }

    puts "INFO: EndCap per-Power-Domain passes = $endcap_pd_names"
    foreach pd_name $endcap_pd_names {
        set pd_prefix [ec_make_prefix $ENDCAP_POWER_DOMAIN_PREFIX $pd_name]
        puts "INFO: EndCap Power Domain pass: add_endcaps -power_domain $pd_name -prefix $pd_prefix"
        add_endcaps -power_domain $pd_name -prefix $pd_prefix

        # Immediate sanity count.  This catches a skipped/empty default-domain
        # insertion before the flow reaches check_endcaps.
        set pd_endcap_count [llength [get_db insts ${pd_prefix}*]]
        puts "INFO: EndCap count for $pd_name ($pd_prefix*) = $pd_endcap_count"
    }
} else {
    puts "INFO: EndCap per-Power-Domain pass is disabled."
}

# -----------------------------------------------------------------------------
# Marker-driven legalization of per-PD LEFT/RIGHT EndCaps
# -----------------------------------------------------------------------------
# Do NOT move EndCaps merely because their row endpoint looks different.
# check_place is run first so TT_proc_legalize_pd_endcaps.tcl only touches EndCaps
# that have an actual placement-violation marker.  The V3 helper then uses the
# EndCap center-Y to locate the real site=core row, which also covers the
# top-most / bottom-most LEFT/RIGHT EndCaps.
puts "INFO: Running pre-legalize check_place to create EndCap placement markers."
if {[llength [info commands check_place]] > 0} {
    check_place
} elseif {[llength [info commands checkPlace]] > 0} {
    checkPlace
} else {
    error "check_place/checkPlace is unavailable; marker-driven EndCap legalization cannot run safely."
}

source -quiet [file join $::TECH_MV_RUNTIME_ROOT .. script PR TECH_MV script 01_floorplan endcap_welltap proc_legalize_pd_endcaps.tcl]
set ec_pd_legalize_moved [tech_mv_legalize_pd_endcaps]
puts "INFO: Marker-driven PD EndCap legalization moved $ec_pd_legalize_moved instance(s)."

# Re-run the authoritative placement check immediately after legalization so
# stale pre-move markers are replaced/updated before Power-Switch insertion.
puts "INFO: Re-running check_place after PD EndCap legalization."
if {[llength [info commands check_place]] > 0} {
    check_place
} else {
    checkPlace
}

# Repair any minimum-step via issue created around newly inserted boundary cells.
set_db check_drc_limit 100000
tech_mv_native_report_command 02 via_repair [list fix_via -min_step]

# -----------------------------------------------------------------------------
# Stage-01 Power-Switch insertion
# -----------------------------------------------------------------------------
# EndCaps are intentionally inserted first. The switch columns are then created
# with independently configurable edge offsets.
if {[info exists ENABLE_POWER_SWITCH_INSERTION] && $ENABLE_POWER_SWITCH_INSERTION} {
    source -quiet [file join $SCRIPT_DIR floorplan_power_switch.tcl]
    tech_mv_floorplan_insert_power_switches
}

# -----------------------------------------------------------------------------
# Power-Switch / EndCap placement check
# -----------------------------------------------------------------------------
# Do not perform a Tcl pairwise bbox scan here. The Stage-01 power-switch helper
# already runs the placement checkpoint after switch insertion, and Innovus
# check_place is the authoritative overlap/legal-placement checker.
set ec_sw_overlap_count 0
puts "INFO: Power-Switch/EndCap overlap is checked by Innovus check_place."

# -----------------------------------------------------------------------------
# Debug breakpoint: EndCaps and Power Switches are now fully inserted, but
# normal 01_floorplan has not yet returned to insert WellTaps. This is the
# earliest point where switch/endcap overlap on any edge can be inspected.
#
# IMPORTANT:
# check_endcaps validates the inserted cells against the CURRENT
# set_db add_endcaps_* settings.  Core-boundary EndCaps and Power-Domain
# EndCaps are therefore checked separately here.
# -----------------------------------------------------------------------------
if {$ENDCAP_POST_INSERT_BREAKPOINT_ENABLE} {
    puts ""
    puts "======================================================================"
    puts " ENDCAP POST-INSERT DEBUG BREAKPOINT"
    puts "======================================================================"
    puts "INFO: EndCap insertion is complete."
    puts "INFO: Power Switches and EndCaps are inserted; WellTaps have NOT been inserted yet."

    # Put all EndCap debug reports in one place.
    set ec_report_dir [tech_mv_report_dir 01 endcap]
    puts "INFO: EndCap debug reports: $ec_report_dir"

    if {$ENDCAP_POST_INSERT_RUN_CHECKS} {
        # ---------------------------------------------------------------------
        # 1. Dump the checker reference settings.  If these are empty/wrong,
        #    check_endcaps can report a missing EndCap even when the instance
        #    is visibly present in the layout.
        # ---------------------------------------------------------------------
        puts ""
        puts "================ ENDCAP DB SETTINGS ================"
        set ec_checker_attrs {
            add_endcaps_left_edge
            add_endcaps_right_edge
            add_endcaps_left_top_corner
            add_endcaps_right_top_corner
            add_endcaps_left_bottom_corner
            add_endcaps_right_bottom_corner
            add_endcaps_top_edge
            add_endcaps_bottom_edge
            add_endcaps_left_top_edge
            add_endcaps_right_top_edge
            add_endcaps_left_bottom_edge
            add_endcaps_right_bottom_edge
            add_endcaps_boundary_tap
        }

        set ec_settings_rpt [tech_mv_report_path 70 endcap_db_settings rpt 01 endcap]
        set ec_settings_fp [open $ec_settings_rpt w]
        foreach attr $ec_checker_attrs {
            set value "<UNAVAILABLE>"
            if {![catch {set value [get_db $attr]}]} {
                # value already captured
            }
            puts [format "%-38s = %s" $attr $value]
            puts $ec_settings_fp [format "%-38s = %s" $attr $value]
        }
        close $ec_settings_fp
        puts "INFO: Wrote $ec_settings_rpt"

        # ---------------------------------------------------------------------
        # 2. Dump actual inserted EndCap instances for direct comparison with
        #    the set_db reference masters above.
        # ---------------------------------------------------------------------
        puts ""
        puts "================ ACTUAL ENDCAP INSTANCES ================"
        set ec_inst_rpt [tech_mv_report_path 71 endcap_instances rpt 01 endcap]
        set ec_inst_fp [open $ec_inst_rpt w]
        set ec_endcap_insts [get_db insts ENDCAP*]
        puts "INFO: Found [llength $ec_endcap_insts] ENDCAP* instances."
        puts $ec_inst_fp "ENDCAP instance count = [llength $ec_endcap_insts]"

        foreach inst $ec_endcap_insts {
            set inst_name [get_db $inst .name]
            set master_name ""
            set place_status ""
            set bbox ""
            catch {set master_name [get_db $inst .base_cell.name]}
            catch {set place_status [get_db $inst .place_status]}
            catch {set bbox [get_db $inst .bbox]}
            set line "${inst_name}  master=${master_name}  status=${place_status}  bbox=${bbox}"
            puts $line
            puts $ec_inst_fp $line
        }
        close $ec_inst_fp
        puts "INFO: Wrote $ec_inst_rpt"

        # ---------------------------------------------------------------------
        # 3. check_endcaps: core boundary and each physical Power Domain are
        #    intentionally checked separately.  -wrong_location also catches
        #    EndCaps that exist but are inserted at an illegal/wrong location.
        # ---------------------------------------------------------------------
        if {[llength [info commands check_endcaps]] > 0} {
            if {$ENDCAP_GLOBAL_PASS_ENABLE} {
                puts ""
                puts "================ CHECK CORE ENDCAP ================"
                set ec_core_rpt [tech_mv_report_path 72 check_endcaps_core rpt 01 endcap]
                check_endcaps \
                    -core_boundary_only \
                    -wrong_location \
                    -error 10000 \
                    -out_file $ec_core_rpt
                puts "INFO: Wrote $ec_core_rpt"
            }

            if {$ENDCAP_POWER_DOMAIN_PASS_ENABLE} {
                puts ""
                puts "================ CHECK POWER-DOMAIN ENDCAP ================"
                foreach pd_name $endcap_pd_names {
                    puts ""
                    puts "------------------------------------------------------------"
                    puts " Power Domain : $pd_name"
                    puts "------------------------------------------------------------"
                    set safe_pd $pd_name
                    regsub -all {[^[:alnum:]_.-]+} $safe_pd {_} safe_pd
                    set ec_pd_rpt [tech_mv_report_path 73 "check_endcaps_${safe_pd}" rpt 01 endcap]
                    check_endcaps \
                        -power_domains $pd_name \
                        -wrong_location \
                        -error 10000 \
                        -out_file $ec_pd_rpt
                    puts "INFO: Wrote $ec_pd_rpt"
                }
            }
        } else {
            puts "WARNING: check_endcaps command is unavailable in this Innovus release."
        }

        # ---------------------------------------------------------------------
        # 4. Placement / floorplan legality.  These checks are independent of
        #    check_endcaps and are needed for Off Placement Grid / Region-Fence
        #    violations.
        # ---------------------------------------------------------------------
        puts ""
        puts "================ CHECK PLACE ================"
        if {[llength [info commands check_place]] > 0} {
            check_place
        } elseif {[llength [info commands checkPlace]] > 0} {
            checkPlace
        } else {
            puts "WARNING: check_place/checkPlace command is unavailable."
        }

        puts ""
        puts "================ CHECK FLOORPLAN ================"
        if {[llength [info commands check_floorplan]] > 0} {
            check_floorplan
        } elseif {[llength [info commands checkFPlan]] > 0} {
            checkFPlan -reportUtil
        } else {
            puts "WARNING: check_floorplan/checkFPlan command is unavailable."
        }
    }

    if {$ENDCAP_POST_INSERT_SAVE_DB} {
        if {[info exists DB_DIR] && [info exists TOP_MODULE]} {
            set ec_debug_db [file join $DB_DIR "01_81_suspend_after_endcap_power_switch_before_welltap.enc"]
            write_db $ec_debug_db
            puts "INFO: EndCap pre-suspend DB saved: $ec_debug_db"
        } else {
            puts "WARNING: DB_DIR/TOP_MODULE is unavailable; EndCap debug DB was not saved."
        }
    }

    puts ""
    puts "======================================================================"
    puts " BREAKPOINT READY"
    puts "======================================================================"
    puts "INFO: Check reports under: $ec_report_dir"
    puts "INFO: First inspect the EndCap reports and check_place markers."
    puts "INFO: Then inspect check_place markers for Off Placement Grid / Region-Fence."
    puts "INFO: Power Switches are already inserted; use check_place for overlap/legal-placement checks."
    puts "INFO: Type 'resume' only after the EndCap state has been inspected."
    if {[llength [info commands tech_mv_checkpoint_tools]]} { tech_mv_checkpoint_tools {02_powerplan} {add_endcaps} }
    suspend
    puts "INFO: Resumed after EndCap post-insert debug breakpoint."
}

# DRC is checked by the stage checkpoint flow.
