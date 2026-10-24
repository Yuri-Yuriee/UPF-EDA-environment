# Runtime adapter preserves the historical logical source path.
if {[info exists ::TECH_MV_RUNTIME_ROOT]} {
    info script [file join $::TECH_MV_RUNTIME_ROOT run/tool/02_powerplan/TT_2row_sdp_welltap_after_endcap_v6.tcl]
}
# Load definitions only; no APR action or setup reload is performed here.
if {![llength [info commands ::tech_mv_library_value]]} {
    if {[info exists ::TOOL_DIR]} {
        source -quiet [file join $::TECH_MV_RUNTIME_ROOT .. script PR TECH_MV script 00_common private_parameter_config.tcl]
    } else {
        source -quiet [file join $::TECH_MV_RUNTIME_ROOT .. script PR TECH_MV script 00_common private_parameter_config.tcl]
    }
}
# PUBLIC_EXPORT_REVIEW_REQUIRED: residual technology candidates require manual review.
# Load private values before evaluating original parameter defaults.
if {![llength [info commands ::tech_mv_private_value]]} { source [file join $::TECH_MV_RUNTIME_ROOT .. script PR TECH_MV script 00_common private_parameter_config.tcl] }
# Capture this tool directory while source is active; proc calls may have another info script.
set ::TECH_MV_SDP_TOOL_SOURCE_DIR [file dirname [file normalize [info script]]]
# =============================================================================
# TT_2row_sdp_welltap_after_endcap_v7_18_background_unplace.tcl
# TECH_MV / Innovus 21.19 Stylus / Common UI
#
# SOURCE-AND-RUN flow (run AFTER EndCap insertion):
#   1) discover exactly 2-row LS/ISO by DB attributes
#   2) snapshot instances that are UNPLACED before temporary placement
#   3) run temporary plain place_design while SDPWT count is zero
#   4) create PD-specific side WellTap pools and load [WT_L][CELL][WT_R] SDP
#   5) reserve >= one TAPCELL-width from fixed CPU/WDT Power Switches
#   6) BEFORE place_sdps/refine, restore every originally-unplaced NON-SDP
#      instance back to UNPLACED so background standard cells cannot obstruct SDP
#   7) explicitly keep every NON-CANONICAL low-power LS/ISO/RET cell UNPLACED;
#      only canonical 2-row SDP members may be fixed by this tool
#   8) place_sdps with 2G/SW/high + no-interleaving; run check_sdps
#   9) FIX all canonical [WT_L][CELL][WT_R] members, then selectively unfix/refine
#      only violating canonical SDP groups and re-FIX them after every pass
#  10) keep full [WT_L][CELL][WT_R] SDP membership during ALL repair/check
#      stages; only after final native/SW-gap/PGROW validation, delete the
#      temporary SDP constraint shells with -keep_cell_placement
#  11) general background remains UNPLACED; NEVER delete functional standard cells
#  12) final check_sdps must be 0 after targeted refine; fixed/gap checks pass
#
# IMPORTANT:
#   - Common UI only. No dbGet/dbSet/dbDelete* and no legacy SDP placement APIs.
#   - Keep full SDP membership while placement/repair/checking is active.
#     At the final Stage-02 handoff, delete ONLY the SDP constraint shells with
#     delete_sdp_rows_blockages -keep_cell_placement. All physical members stay
#     at their validated coordinates/orientations and remain FIXED.
#   - This prevents write_db IMPFP-3763 when a center LP cell is constrained by
#     a fence/region/guide but its physical-only side WellTaps do not belong to
#     that same floorplan constraint.
#   - The Power-Switch spacing default is AUTO: reserve at least one full
#     configured library cell width, derived from the configured live Welltap geometry.
#     Required sites = ceil(tap_width / site_width); padding is cleared only after SDP is FIXED;
#     the following general-WellTap stage can then fill the remaining legal area.
#   - Temporary global placement is only a coordinate-discovery prepass. Before
#     any SDP legalization/refine, all originally-unplaced NON-SDP instances are
#     restored to UNPLACED. This removes ordinary standard-cell interference.
#   - Non-canonical low-power LS/ISO/RET cells are also forced UNPLACED in the
#     SDP-repair window. This SDP tool never fixes them; only canonical 2-row
#     [WT_L][CELL][WT_R] members may become FIXED here.
#   - A nonzero check_sdps result is FIXED first by design. If violations are
#     present, TT_refine_violating_sdps.tcl releases only the mapped violating
#     canonical SDP rows, runs a targeted place_sdps refine, and re-FIXes those
#     canonical members after every pass. Clean rows remain fixed.
#   - V7.10+ destructive temporary-placement purge stays disabled.  Missing
#     exact snapshot instances are reported only; no same-leaf substitution.
#   - The legacy all-taps-missing recovery helpers remain for previously damaged
#     checkpoints, but are not used by a fresh V7.14 run.
#   - Partial/foreign SDP membership or unexpected topology remains fatal.
#
# Usage:
#   source TT_2row_sdp_welltap_after_endcap_v6.tcl
#
# No second command is required.
# =============================================================================

# V7.27: detect a manual re-source before redefining the creator proc.
# A re-source is definition reload only; it must never rerun the destructive
# source-and-run path on a DB that already contains dedicated SDP WellTaps.
set ::TT_2ROW_SDP_RELOAD_ONLY_THIS_SOURCE \
    [expr {[llength [info commands TT_proc_create_2row_sdp_welltap]] > 0}]

set ::TT_2ROW_SDP_VERSION "V7.28_STAGE8F_SEQUENTIAL_DELETE_REFIX"

if {![info exists ::TT_2ROW_SDP_WELLTAP_MASTER]} { set ::TT_2ROW_SDP_WELLTAP_MASTER [::tech_mv_library_value LIB_CELL_002] }
if {![info exists ::TT_2ROW_SDP_SITE]} { set ::TT_2ROW_SDP_SITE core }
if {![info exists ::TT_2ROW_SDP_TAPS_PER_CELL]} { set ::TT_2ROW_SDP_TAPS_PER_CELL [::tech_mv_private_value {run/tool/02_powerplan/TT_2row_sdp_welltap_after_endcap_v6.tcl::::TT_2ROW_SDP_TAPS_PER_CELL::L71}] }
if {![info exists ::TT_2ROW_SDP_TRIAL_INTERVAL]} { set ::TT_2ROW_SDP_TRIAL_INTERVAL 200.0 }
if {![info exists ::TT_2ROW_SDP_POOL_MARGIN]} { set ::TT_2ROW_SDP_POOL_MARGIN [::tech_mv_private_value {run/tool/02_powerplan/TT_2row_sdp_welltap_after_endcap_v6.tcl::::TT_2ROW_SDP_POOL_MARGIN::L73}] }
if {![info exists ::TT_2ROW_SDP_MAX_POOL_RETRY]} { set ::TT_2ROW_SDP_MAX_POOL_RETRY 4 }
if {![info exists ::TT_2ROW_SDP_WT_PREFIX]} { set ::TT_2ROW_SDP_WT_PREFIX SDPWT }
if {![info exists ::TT_2ROW_SDP_GROUP_PREFIX]} { set ::TT_2ROW_SDP_GROUP_PREFIX SDP2R }
if {![info exists ::TT_2ROW_SDP_FILE]} {
    set ::TT_2ROW_SDP_FILE [tech_mv_output_path temp TT_2row_ls_iso_welltap_generated.sdp 02 sdp]
}
if {![info exists ::TT_2ROW_SDP_RUN_CHECK]} { set ::TT_2ROW_SDP_RUN_CHECK true }
if {![info exists ::TT_2ROW_SDP_RUN_CHECK_PLACE]} { set ::TT_2ROW_SDP_RUN_CHECK_PLACE true }
if {![info exists ::TT_2ROW_SDP_FIX_AFTER_PLACE]} { set ::TT_2ROW_SDP_FIX_AFTER_PLACE true }
if {![info exists ::TT_2ROW_SDP_AUTO_REPAIR_MISSING_TAPS]} { set ::TT_2ROW_SDP_AUTO_REPAIR_MISSING_TAPS true }
if {![info exists ::TT_2ROW_SDP_UPDATE_INSERT_MODE]} { set ::TT_2ROW_SDP_UPDATE_INSERT_MODE AUTO }

# V7.9: Native SDP 2G box-padding / non-interleaving guard.
# Physical padding = configured padding site count * live core-site width.
# Keep this as site counts so the flow remains technology/site portable.
if {![info exists ::TT_2ROW_SDP_PADDING_X_SITES]} { set ::TT_2ROW_SDP_PADDING_X_SITES 2 }
if {![info exists ::TT_2ROW_SDP_PADDING_Y_SITES]} { set ::TT_2ROW_SDP_PADDING_Y_SITES 0 }
if {![info exists ::TT_2ROW_SDP_ENFORCE_NO_INTERLEAVING]} { set ::TT_2ROW_SDP_ENFORCE_NO_INTERLEAVING true }
if {![info exists ::TT_2ROW_SDP_HONOR_USER_ASSIGN_ORIGIN]} { set ::TT_2ROW_SDP_HONOR_USER_ASSIGN_ORIGIN false }

# V7.14: keep the SDP constraint after placement.  The side SDP WellTaps are
# detached only after a clean SDP placement and immediately restored/fixed at
# the exact legalized coordinates.  The center 2-row CELL remains in SDP, so
# the DB no longer contains a mixed PD-group SDP while SDP itself is preserved.
# AUTO reserves at least one full TAPCELL width as horizontal switch clearance.
# The current SW-gap checker applies that clearance to the center CELL only;
# required placement sites = ceil(live Welltap width / live core-site width).
if {![info exists ::TT_2ROW_SDP_SW_PADDING_SITES]} { set ::TT_2ROW_SDP_SW_PADDING_SITES AUTO }
if {![info exists ::TT_2ROW_SDP_CLEAN_RETRY]} { set ::TT_2ROW_SDP_CLEAN_RETRY 2 }
if {![info exists ::TT_2ROW_SDP_REQUIRE_ZERO_VIOLATIONS]} { set ::TT_2ROW_SDP_REQUIRE_ZERO_VIOLATIONS true }
if {![info exists ::TT_2ROW_SDP_AUTO_TARGET_REFINE]} { set ::TT_2ROW_SDP_AUTO_TARGET_REFINE true }
if {![info exists ::TT_2ROW_SDP_TARGET_REFINE_MAX_ITER]} { set ::TT_2ROW_SDP_TARGET_REFINE_MAX_ITER 3 }

# V6.9: Always save a native Innovus/Stylus DB before this source-and-run flow
# can mutate SDP ownership, WellTap instances, or placement.  The checkpoint is
# intentionally outside the generated SDP file so a failed repair cannot
# overwrite the recovery point.
if {![info exists ::TT_2ROW_SDP_AUTO_CHECKPOINT]} { set ::TT_2ROW_SDP_AUTO_CHECKPOINT true }
if {![info exists ::TT_2ROW_SDP_CHECKPOINT_ROOT]} { set ::TT_2ROW_SDP_CHECKPOINT_ROOT ./dbs/TT_2row_sdp_checkpoints }

# V7.4 diagnostic reporting.  Keep diagnostics observational only: no SDP
# mutation, no control-flow catch around placement/repair, and every record is
# opened/appended/closed immediately so the last completed stage survives Tcl
# errors or a later Innovus crash.
if {![info exists ::TT_2ROW_SDP_DIAG_ENABLE]} { set ::TT_2ROW_SDP_DIAG_ENABLE true }
if {![info exists ::TT_2ROW_SDP_DIAG_ROOT]} { set ::TT_2ROW_SDP_DIAG_ROOT ./reports }
if {![info exists ::TT_2ROW_SDP_STRICT_RESTORE_MISSING]} { set ::TT_2ROW_SDP_STRICT_RESTORE_MISSING false }
if {![info exists ::TT_2ROW_SDP_PURGE_NON_SDP_STD]} { set ::TT_2ROW_SDP_PURGE_NON_SDP_STD false }
if {![info exists ::TT_2ROW_SDP_PURGE_BATCH_SIZE]} { set ::TT_2ROW_SDP_PURGE_BATCH_SIZE 500 }
if {![info exists ::TT_2ROW_SDP_PURGE_REPORT]} { set ::TT_2ROW_SDP_PURGE_REPORT ./reports/TT_2row_sdp_purge_candidates.txt }
if {![info exists ::TT_2ROW_SDP_PURGE_STRICT]} { set ::TT_2ROW_SDP_PURGE_STRICT true }

proc TT_2row_sdp__diag_write {text} {
    if {![info exists ::TT_2ROW_SDP_DIAG_ENABLE] || ![TT_2row_sdp__bool $::TT_2ROW_SDP_DIAG_ENABLE]} { return }
    foreach var {TT_2ROW_SDP_DIAG_FILE TT_2ROW_SDP_DIAG_LATEST} {
        if {![info exists ::$var]} { continue }
        set p [set ::$var]
        set fp [open $p a]
        puts $fp $text
        close $fp
    }
}

proc TT_2row_sdp__diag_init {} {
    if {![TT_2row_sdp__bool $::TT_2ROW_SDP_DIAG_ENABLE]} { return "" }
    set root [file normalize $::TT_2ROW_SDP_DIAG_ROOT]
    file mkdir $root
    set stamp [clock format [clock seconds] -format "%Y%m%d_%H%M%S"]
    set ::TT_2ROW_SDP_DIAG_FILE [file join $root "TT_2row_sdp_diag_${stamp}.txt"]
    set ::TT_2ROW_SDP_DIAG_LATEST [file join $root "TT_2row_sdp_latest_report.txt"]
    foreach p [list $::TT_2ROW_SDP_DIAG_FILE $::TT_2ROW_SDP_DIAG_LATEST] {
        set fp [open $p w]
        puts $fp "TT 2-ROW SDP DIAGNOSTIC REPORT"
        puts $fp "VERSION=$::TT_2ROW_SDP_VERSION"
        puts $fp "START=[clock format [clock seconds] -format {%Y-%m-%d %H:%M:%S}]"
        puts $fp "PWD=[pwd]"
        puts $fp "SDP_FILE=$::TT_2ROW_SDP_FILE"
        puts $fp "WELLTAP_MASTER=$::TT_2ROW_SDP_WELLTAP_MASTER"
        puts $fp "WELLTAP_PREFIX=$::TT_2ROW_SDP_WT_PREFIX"
        puts $fp "---------------------------------------------------------------------"
        close $fp
    }
    puts "INFO: V7.4 SDP diagnostic report: $::TT_2ROW_SDP_DIAG_LATEST"
    puts "INFO: V7.4 timestamp report      : $::TT_2ROW_SDP_DIAG_FILE"
    return $::TT_2ROW_SDP_DIAG_LATEST
}

proc TT_2row_sdp__diag_mark {stage {note ""}} {
    if {![info exists ::TT_2ROW_SDP_DIAG_ENABLE] || ![TT_2row_sdp__bool $::TT_2ROW_SDP_DIAG_ENABLE]} { return }
    set ::TT_2ROW_SDP_DIAG_STAGE $stage
    set master_count "ERR"
    set prefix_count "ERR"
    set fixed_count "ERR"
    set placed_count "ERR"
    set unplaced_count "ERR"
    set sample ""
    if {![catch {set taps [TT_2row_sdp__tap_objects]}]} {
        set master_count [llength $taps]
    }
    if {![catch {set pref [TT_2row_sdp__prefix_insts $::TT_2ROW_SDP_WT_PREFIX]}]} {
        set prefix_count [llength $pref]
        set fixed_count 0
        set placed_count 0
        set unplaced_count 0
        set names {}
        foreach inst $pref {
            set st ""
            catch {set st [get_db $inst .place_status]}
            if {$st eq "fixed"} { incr fixed_count }
            if {$st eq "placed"} { incr placed_count }
            if {$st eq "unplaced"} { incr unplaced_count }
            if {[llength $names] < 4} {
                set n ""
                catch {set n [get_db $inst .name]}
                if {$n ne ""} { lappend names $n }
            }
        }
        set sample [join $names {, }]
    }
    set now [clock format [clock seconds] -format {%Y-%m-%d %H:%M:%S}]
    set line "MARK stage={$stage} time={$now} level=[info level] master_taps=$master_count prefix_taps=$prefix_count fixed=$fixed_count placed=$placed_count unplaced=$unplaced_count"
    if {$note ne ""} { append line " note={$note}" }
    TT_2row_sdp__diag_write $line
    if {$sample ne ""} { TT_2row_sdp__diag_write "  sample={$sample}" }
}

proc TT_2row_sdp__diag_validation {group_count expected_cells existing_cells expected_taps existing_taps alias_resolved live_master live_prefix missing_cells missing_taps bad_master bad_pd} {
    if {![info exists ::TT_2ROW_SDP_DIAG_ENABLE] || ![TT_2row_sdp__bool $::TT_2ROW_SDP_DIAG_ENABLE]} { return }
    set stage "UNKNOWN"
    if {[info exists ::TT_2ROW_SDP_DIAG_STAGE]} { set stage $::TT_2ROW_SDP_DIAG_STAGE }
    TT_2row_sdp__diag_write "VALIDATION stage={$stage} groups=$group_count expected_cells=$expected_cells existing_cells=$existing_cells expected_taps=$expected_taps existing_taps=$existing_taps alias=$alias_resolved live_master=$live_master live_prefix=$live_prefix missing_cells=$missing_cells missing_taps=$missing_taps bad_master=$bad_master bad_pd=$bad_pd"
}

proc TT_2row_sdp__bool {v} {
    set s [string tolower [string trim $v]]
    return [expr {$s eq "true" || $s eq "1" || $s eq "yes"}]
}

# -----------------------------------------------------------------------------
# V6.9 pre-run native DB checkpoint.
#
# Stylus Common UI uses write_db/read_db for native design checkpoints.  This is
# deliberately executed from the source-and-run entry BEFORE the main proc, so
# even a later detach/read_sdp_file/placement failure has a clean restore point.
# Any save failure is fatal and prevents all subsequent SDP mutation.
# -----------------------------------------------------------------------------
proc TT_2row_sdp__save_pre_run_checkpoint {} {
    if {![TT_2row_sdp__bool $::TT_2ROW_SDP_AUTO_CHECKPOINT]} {
        puts "WARN: V6.9 automatic pre-run checkpoint is disabled by TT_2ROW_SDP_AUTO_CHECKPOINT."
        return ""
    }

    if {[llength [info commands write_db]] == 0} {
        error "V6.9 safety checkpoint refused: Stylus command 'write_db' is unavailable. No SDP operation was started."
    }

    set root [file normalize $::TT_2ROW_SDP_CHECKPOINT_ROOT]
    if {[catch {file mkdir $root} mkdir_err]} {
        error "V6.9 safety checkpoint refused: cannot create checkpoint root '$root': $mkdir_err"
    }

    set stamp [clock format [clock seconds] -format "%Y%m%d_%H%M%S"]
    set base [file join $root "pre_2row_sdp_${stamp}"]
    set ckpt $base
    set suffix 0
    while {[file exists $ckpt]} {
        incr suffix
        set ckpt "${base}_${suffix}"
    }

    puts ""
    puts "======================================================================"
    puts " V6.9 PRE-RUN INNOVUS CHECKPOINT"
    puts "======================================================================"
    puts "Checkpoint root : $root"
    puts "Checkpoint path : $ckpt"
    puts "Command         : write_db $ckpt"
    puts "Policy          : checkpoint failure is FATAL; no SDP mutation follows"
    puts "======================================================================"

    if {[catch {write_db $ckpt} save_err save_opts]} {
        return -options $save_opts "V6.9 safety checkpoint FAILED at '$ckpt': $save_err. No SDP operation was started."
    }

    # Do not merely trust command return: Stylus native checkpoints are
    # directory-backed.  Require the target to exist before proceeding.
    if {![file exists $ckpt]} {
        error "V6.9 safety checkpoint command returned without error, but '$ckpt' does not exist. No SDP operation was started."
    }

    set ::TT_2ROW_SDP_LAST_CHECKPOINT $ckpt

    puts ""
    puts "PASS: Pre-run Innovus checkpoint saved successfully."
    puts "RESTORE COMMAND: read_db $ckpt"
    puts "INFO: This checkpoint is from BEFORE any V6.8 SDP/WellTap mutation."
    puts ""

    return $ckpt
}

proc TT_2row_sdp__bbox4 {v} {
    if {[llength $v] == 1} { set v [lindex $v 0] }
    if {[llength $v] != 4} { return "" }
    return $v
}

proc TT_2row_sdp__size2 {v} {
    if {[llength $v] == 1} { set v [lindex $v 0] }
    if {[llength $v] != 2} { return "" }
    return $v
}

proc TT_2row_sdp__name {obj} {
    set v ""
    catch {set v [get_db $obj .name]}
    return $v
}

proc TT_2row_sdp__pd {obj} {
    set v ""
    catch {set v [get_db $obj .power_domain.name]}
    return $v
}

proc TT_2row_sdp__master {obj} {
    set v ""
    catch {set v [get_db $obj .base_cell.name]}
    return $v
}


# -----------------------------------------------------------------------------
# Robust instance-name resolver.
#
# The generated SDP file can retain a hierarchical physical-only WellTap name
# such as:
#
#   u_TOP/SDPWT_PD_TOP_PD_TOP_128
#
# while a later Innovus DB/session may expose or resolve that same instance by
# a canonical/leaf name.  Direct `get_db insts $name` can therefore return an
# empty collection even though the instance still exists.
#
# Resolution policy:
#   1) native exact get_db lookup
#   2) exact match against the live .name attribute
#   3) unique leaf-name match only
#
# Ambiguous leaf matches are fatal: never guess which physical instance is the
# SDP member.
# -----------------------------------------------------------------------------
proc TT_2row_sdp__inst_aliases {inst} {
    # .name is already used throughout this flow and is therefore the only DB
    # attribute relied on here.  Do not probe speculative hierarchical-name
    # attributes: on Innovus they may print IMPDBTCL diagnostics even inside
    # catch.  If .name is a leaf while the SDP file stores u_TOP/<leaf>, the
    # resolver below handles it through a uniqueness-checked leaf fallback.
    set n [TT_2row_sdp__name $inst]
    if {$n eq "" || $n eq "0x0"} { return {} }

    set aliases [list $n]
    set trimmed [string trimleft $n /]
    if {$trimmed ne $n} { lappend aliases $trimmed }
    return [lsort -unique $aliases]
}

proc TT_2row_sdp__build_inst_lookup {exact_name leaf_name} {
    upvar 1 $exact_name exact
    upvar 1 $leaf_name leaf

    catch {array unset exact}
    catch {array unset leaf}

    foreach inst [get_db insts] {
        set aliases [TT_2row_sdp__inst_aliases $inst]
        foreach a $aliases {
            if {![info exists exact($a)] ||
                [lsearch -exact $exact($a) $inst] < 0} {
                lappend exact($a) $inst
            }

            set tail [lindex [split $a /] end]
            if {$tail ne "" &&
                (![info exists leaf($tail)] ||
                 [lsearch -exact $leaf($tail) $inst] < 0)} {
                lappend leaf($tail) $inst
            }
        }
    }
}

proc TT_2row_sdp__resolve_inst {target exact_name leaf_name} {
    upvar 1 $exact_name exact
    upvar 1 $leaf_name leaf

    # First let Innovus resolve the name natively.
    set direct {}
    catch {set direct [get_db insts $target]}
    if {[llength $direct] == 1} {
        return [lindex $direct 0]
    } elseif {[llength $direct] > 1} {
        error "Ambiguous direct instance lookup for '$target': [llength $direct] matches."
    }

    set norm [string trimleft $target /]
    foreach key [lsort -unique [list $target $norm]] {
        if {$key eq "" || ![info exists exact($key)]} { continue }
        set hits [lsort -unique $exact($key)]
        if {[llength $hits] == 1} {
            return [lindex $hits 0]
        } elseif {[llength $hits] > 1} {
            error "Ambiguous exact alias for '$target' via '$key': [llength $hits] matches."
        }
    }

    set tail [lindex [split $norm /] end]
    if {$tail ne "" && [info exists leaf($tail)]} {
        set hits [lsort -unique $leaf($tail)]
        if {[llength $hits] == 1} {
            return [lindex $hits 0]
        } elseif {[llength $hits] > 1} {
            set names {}
            foreach inst $hits {
                set n [TT_2row_sdp__name $inst]
                if {$n eq ""} { set n $inst }
                lappend names $n
            }
            error "Ambiguous leaf instance lookup for '$target' (leaf '$tail'): [join $names {, }]"
        }
    }

    return ""
}

# V7.5: exact-only resolver for names captured directly from the live DB.
# Snapshot names are NOT SDP-file aliases.  Never fall back to leaf names here:
# a missing u_TOP/u_cpu/U192 must not resolve to some other */U192 instance.
proc TT_2row_sdp__resolve_snapshot_inst_exact {target exact_name} {
    upvar 1 $exact_name exact

    set direct {}
    catch {set direct [get_db insts $target]}
    if {[llength $direct] == 1} {
        return [lindex $direct 0]
    } elseif {[llength $direct] > 1} {
        error "Ambiguous direct snapshot instance lookup for '$target': [llength $direct] matches."
    }

    set norm [string trimleft $target /]
    foreach key [lsort -unique [list $target $norm]] {
        if {$key eq "" || ![info exists exact($key)]} { continue }
        set hits [lsort -unique $exact($key)]
        if {[llength $hits] == 1} {
            return [lindex $hits 0]
        } elseif {[llength $hits] > 1} {
            error "Ambiguous exact snapshot alias for '$target' via '$key': [llength $hits] matches."
        }
    }

    return ""
}

proc TT_2row_sdp__live_name {inst} {
    return [TT_2row_sdp__name $inst]
}

proc TT_2row_sdp__sanitize {v} {
    regsub -all {[^A-Za-z0-9_]} $v "_" out
    return $out
}

proc TT_2row_sdp__site_geometry {} {
    set v [TT_2row_sdp__size2 [get_db site:$::TT_2ROW_SDP_SITE .size]]
    if {$v eq ""} { error "Cannot read site '$::TT_2ROW_SDP_SITE' size." }
    return $v
}

proc TT_2row_sdp__padding_geometry {} {
    lassign [TT_2row_sdp__site_geometry] site_w site_h
    if {![string is integer -strict $::TT_2ROW_SDP_PADDING_X_SITES] ||
        $::TT_2ROW_SDP_PADDING_X_SITES < 0} {
        error "TT_2ROW_SDP_PADDING_X_SITES must be a non-negative integer."
    }
    if {![string is integer -strict $::TT_2ROW_SDP_PADDING_Y_SITES] ||
        $::TT_2ROW_SDP_PADDING_Y_SITES < 0} {
        error "TT_2ROW_SDP_PADDING_Y_SITES must be a non-negative integer."
    }
    return [list \
        [expr {double($site_w) * $::TT_2ROW_SDP_PADDING_X_SITES}] \
        [expr {double($site_h) * $::TT_2ROW_SDP_PADDING_Y_SITES}]]
}

proc TT_2row_sdp__tap_geometry {} {
    set v [TT_2row_sdp__bbox4 [get_db base_cell:$::TT_2ROW_SDP_WELLTAP_MASTER .bbox]]
    if {$v eq ""} { error "Cannot read WellTap master '$::TT_2ROW_SDP_WELLTAP_MASTER' bbox." }
    lassign $v x1 y1 x2 y2
    return [list [expr {$x2-$x1}] [expr {$y2-$y1}]]
}

proc TT_2row_sdp__master_rows {inst site_h} {
    set master [TT_2row_sdp__master $inst]
    if {$master eq ""} { return -1 }
    set b [TT_2row_sdp__bbox4 [get_db base_cell:$master .bbox]]
    if {$b eq ""} { return -1 }
    lassign $b x1 y1 x2 y2
    return [expr {int(round(($y2-$y1)/$site_h))}]
}

proc TT_2row_sdp__check_commands {} {
    set missing {}
    foreach cmd {add_well_taps read_sdp_file} {
        if {[llength [info commands $cmd]] == 0} { lappend missing $cmd }
    }
    if {[llength $missing] != 0} { error "Missing required Common UI command(s): $missing" }
}

proc TT_2row_sdp__collect {kind_name pd_cells_name} {
    upvar 1 $kind_name kind
    upvar 1 $pd_cells_name pd_cells
    catch {array unset kind}
    catch {array unset pd_cells}

    lassign [TT_2row_sdp__site_geometry] site_w site_h
    set ls_total 0
    set iso_total 0
    set two_total 0
    set no_pd 0

    foreach inst [get_db insts] {
        set is_ls false
        set is_iso false
        catch {set is_ls  [get_db $inst .is_level_shifter]}
        catch {set is_iso [get_db $inst .is_isolation]}

        if {![TT_2row_sdp__bool $is_ls] && ![TT_2row_sdp__bool $is_iso]} { continue }

        if {[TT_2row_sdp__bool $is_ls]} {
            set kind_value LS
            incr ls_total
        } else {
            set kind_value ISO
            incr iso_total
        }

        if {[TT_2row_sdp__master_rows $inst $site_h] != 2} { continue }
        incr two_total

        set inst_name [TT_2row_sdp__name $inst]
        set pd [TT_2row_sdp__pd $inst]
        if {$pd eq ""} {
            puts "WARNING: 2-row $kind_value has no Power Domain: $inst_name"
            incr no_pd
            continue
        }

        set kind($inst_name) $kind_value
        lappend pd_cells($pd) $inst
    }

    puts ""
    puts "======================================================================"
    puts " 2-ROW LS / ISO DISCOVERY"
    puts "======================================================================"
    puts "All Level Shifters : $ls_total"
    puts "All Isolation Cells: $iso_total"
    puts "2-row LS/ISO       : $two_total"
    puts "2-row without PD   : $no_pd"
    foreach pd [lsort -dictionary [array names pd_cells]] {
        set count [llength $pd_cells($pd)]
        set need [expr {$count * $::TT_2ROW_SDP_TAPS_PER_CELL}]
        puts [format "PD %-20s : %4d cell(s), %4d SDP WellTap(s) required" $pd $count $need]
    }
    puts "======================================================================"

    if {$no_pd != 0} { error "Cannot continue: $no_pd 2-row LS/ISO cell(s) have no Power Domain." }
    return $two_total
}

proc TT_2row_sdp__pool_prefix {pd} {
    return "${::TT_2ROW_SDP_WT_PREFIX}_[TT_2row_sdp__sanitize $pd]"
}

proc TT_2row_sdp__prefix_insts {prefix} {
    set result {}
    foreach inst [get_db insts] {
        set n [TT_2row_sdp__name $inst]
        if {$n ne "" && [string match "*${prefix}*" $n]} {
            lappend result $inst
        }
    }
    return $result
}

proc TT_2row_sdp__tap_objects {} {
    set result {}
    set master $::TT_2ROW_SDP_WELLTAP_MASTER
    foreach inst [get_db insts] {
        if {[TT_2row_sdp__master $inst] eq $master} {
            lappend result $inst
        }
    }
    return $result
}

proc TT_2row_sdp__snapshot_taps {array_name} {
    upvar 1 $array_name snap
    catch {array unset snap}
    foreach inst [TT_2row_sdp__tap_objects] {
        set snap("$inst") 1
    }
}

proc TT_2row_sdp__new_taps_since {array_name} {
    upvar 1 $array_name before
    set result {}
    foreach inst [TT_2row_sdp__tap_objects] {
        if {![info exists before("$inst")]} {
            lappend result $inst
        }
    }
    return $result
}

proc TT_2row_sdp__delete_objects {objects} {
    set failed 0
    foreach inst $objects {
        set n [TT_2row_sdp__name $inst]
        if {$n eq ""} { continue }
        if {[catch {delete_inst -inst $n -verbose} err]} {
            puts "WARNING: Failed deleting temporary SDP WellTap '$n':"
            puts "         $err"
            incr failed
        }
    }
    if {$failed != 0} {
        error "Failed deleting $failed temporary SDP WellTap(s)."
    }
}

proc TT_2row_sdp__delete_prefix {prefix} {
    set names {}

    foreach inst [TT_2row_sdp__prefix_insts $prefix] {
        set n [TT_2row_sdp__name $inst]
        if {$n eq ""} {
            continue
        }

        # NEVER delete a WellTap that already belongs to an SDP.
        set sdp_obj ""
        set sdp_name ""
        catch {set sdp_obj  [get_db $inst .sdp]}
        catch {set sdp_name [get_db $inst .sdp.name]}

        if {($sdp_obj ne "" && $sdp_obj ne "0x0") ||
            ($sdp_name ne "" && $sdp_name ne "0x0")} {
            error "Refusing to delete stale-prefix WellTap '$n' because it already belongs to SDP '$sdp_name'. Restore/inspect the DB instead."
        }

        lappend names $n
    }

    foreach n $names {
        if {[catch {delete_inst -inst $n -verbose} err]} {
            error "Failed deleting stale SDP WellTap '$n': $err"
        }
    }

    return [llength $names]
}

proc TT_2row_sdp__create_pool {pd required} {
    set master $::TT_2ROW_SDP_WELLTAP_MASTER
    set prefix [TT_2row_sdp__pool_prefix $pd]
    lassign [TT_2row_sdp__tap_geometry] tap_w tap_h

    set stale [TT_2row_sdp__delete_prefix $prefix]
    if {$stale > 0} {
        puts "INFO: Deleted $stale stale SDP pool WellTap(s) for PD=$pd."
    }

    # Sparse calibration trial.
    set trial_interval $::TT_2ROW_SDP_TRIAL_INTERVAL
    set trial_count 0

    for {set trial 0} {$trial < 6} {incr trial} {
        catch {array unset before_trial}
        TT_2row_sdp__snapshot_taps before_trial

        puts [format \
            "INFO: Calibrate pool PD=%s required=%d trial_interval=%0.3f" \
            $pd $required $trial_interval]

        if {[catch {
            add_well_taps \
                -cell $master \
                -cell_interval $trial_interval \
                -power_domain $pd \
                -prefix $prefix
        } err]} {
            error "Calibration add_well_taps failed for PD=$pd: $err"
        }

        set trial_objs [TT_2row_sdp__new_taps_since before_trial]
        set trial_count [llength $trial_objs]

        puts "INFO: PD=$pd calibration created $trial_count new WellTap(s)."

        TT_2row_sdp__delete_objects $trial_objs

        if {$trial_count > 0} {
            break
        }

        set trial_interval [expr {$trial_interval / 2.0}]
        if {$trial_interval < $tap_w} {
            set trial_interval $tap_w
        }
    }

    if {$trial_count <= 0} {
        error "PD=$pd calibration could not create any WellTap."
    }

    set interval [expr {
        $trial_interval *
        double($trial_count) /
        (double($required) * $::TT_2ROW_SDP_POOL_MARGIN)
    }]

    if {$interval < $tap_w} {
        set interval $tap_w
    }

    set final_objs {}
    set selected_interval ""

    for {set attempt 0} \
        {$attempt < $::TT_2ROW_SDP_MAX_POOL_RETRY} \
        {incr attempt} {

        catch {array unset before_final}
        TT_2row_sdp__snapshot_taps before_final

        puts [format \
            "INFO: Build pool PD=%s required=%d interval=%0.3f attempt=%d" \
            $pd $required $interval [expr {$attempt+1}]]

        if {[catch {
            add_well_taps \
                -cell $master \
                -cell_interval $interval \
                -power_domain $pd \
                -prefix $prefix
        } err]} {
            error "Final add_well_taps failed for PD=$pd: $err"
        }

        set final_objs [TT_2row_sdp__new_taps_since before_final]
        set got [llength $final_objs]

        puts "INFO: PD=$pd final attempt created $got new WellTap(s)."

        if {$got >= $required} {
            set selected_interval $interval
            break
        }

        TT_2row_sdp__delete_objects $final_objs
        set final_objs {}

        if {$got <= 0} {
            set interval [expr {$interval / 2.0}]
        } else {
            set interval [expr {
                $interval *
                double($got) /
                (double($required) * $::TT_2ROW_SDP_POOL_MARGIN)
            }]
        }

        if {$interval < $tap_w} {
            set interval $tap_w
        }
    }

    if {[llength $final_objs] < $required} {
        error "PD=$pd requires $required WellTap(s), final pool has only [llength $final_objs]."
    }

    set named {}
    foreach inst $final_objs {
        set n [TT_2row_sdp__name $inst]
        if {$n ne ""} {
            lappend named [list $n $inst]
        }
    }
    set named [lsort -dictionary -index 0 $named]

    set keep  [lrange $named 0 [expr {$required-1}]]
    set extra [lrange $named $required end]

    foreach item $extra {
        lassign $item n inst
        delete_inst -inst $n -verbose
    }

    set result {}
    foreach item $keep {
        lassign $item n inst

        set before_pd [TT_2row_sdp__pd $inst]
        if {$before_pd ne $pd} {
            error "Pool WellTap '$n' PD mismatch: expected=$pd actual=$before_pd"
        }

        # IMPORTANT:
        # add_well_taps creates physical-only / preplaced taps.  The previous
        # flow changed the selected taps to "unplaced"; place_opt_design could
        # then remove those physical-only instances.  Keep them in the DB as
        # ordinary movable PLACED instances so SDP placement can move them
        # without exposing them to the unplaced physical-only cleanup path.
        if {[catch {set_db $inst .place_status placed} err]} {
            error "Cannot set SDP WellTap '$n' to placed: $err"
        }

        set after_pd [TT_2row_sdp__pd $inst]
        if {$after_pd ne $pd} {
            error "Pool WellTap '$n' lost PD after status update: expected=$pd actual=$after_pd"
        }

        lappend result $n
    }

    puts [format \
        "PASS: calibrated pool PD=%s kept=%d interval=%0.3f prefix=%s" \
        $pd [llength $result] $selected_interval $prefix]

    return $result
}

proc TT_2row_sdp__build_pools {pd_cells_name pools_name} {
    upvar 1 $pd_cells_name pd_cells
    upvar 1 $pools_name pools
    catch {array unset pools}

    foreach pd [lsort -dictionary [array names pd_cells]] {
        set required [expr {[llength $pd_cells($pd)] * $::TT_2ROW_SDP_TAPS_PER_CELL}]
        set pools($pd) [TT_2row_sdp__create_pool $pd $required]
    }
}

proc TT_2row_sdp__prepare_cell {inst} {
    set n [TT_2row_sdp__name $inst]
    set existing ""
    if {![catch {set existing [get_db $inst .sdp]}]} {
        if {$existing ne "" && $existing ne "0x0"} {
            error "Instance '$n' already belongs to an SDP: $existing"
        }
    }

    # V5 intentionally does NOT unplace the 2-row LS/ISO cell.
    # Dedicated SDP placement will move the group as needed.
}

proc TT_2row_sdp__emit_group {fp seq cell owned_taps} {
    if {[llength $owned_taps] != 2} {
        error "Exactly two SDP WellTaps are required per 2-row cell."
    }

    lassign $owned_taps wt_l wt_r

    set cell_name [TT_2row_sdp__name $cell]

    set root [format "%s_%05d" \
        $::TT_2ROW_SDP_GROUP_PREFIX $seq]

    set row_name "${root}_ROW"

    # Flat SDP row:
    #
    #   [ WT_L ][ 2-row LS/ISO ][ WT_R ]
    #
    # `justifyBy S` aligns the south edge of the 1-row WellTaps to the south
    # edge of the 2-row special cell.  The 2-row special cell therefore
    # determines the SDP row height instead of nested 2-tap columns.
    puts $fp "datapath $root {"
    lassign [TT_2row_sdp__padding_geometry] pad_x pad_y

    puts $fp "  row $row_name {"
    puts $fp "    justifyBy S"
    puts $fp [format "    padding %.6f %.6f" $pad_x $pad_y]
    puts $fp "    inst $wt_l"
    puts $fp "    inst $cell_name"
    puts $fp "    inst $wt_r"
    puts $fp "  }"
    puts $fp "}"
    puts $fp ""

    return $root
}

proc TT_2row_sdp__write_file {kind_name pd_cells_name pools_name} {
    upvar 1 $kind_name kind
    upvar 1 $pd_cells_name pd_cells
    upvar 1 $pools_name pools

    set fp [open $::TT_2ROW_SDP_FILE w]
    puts $fp "# Auto-generated by TT_2row_sdp_welltap_after_endcap_v6_6_detach_reload_repair.tcl"
    puts $fp "# Version: $::TT_2ROW_SDP_VERSION"
    puts $fp ""

    set seq 0
    set group_count 0

    foreach pd [lsort -dictionary [array names pd_cells]] {
        set taps $pools($pd)
        set tap_idx 0

        foreach cell $pd_cells($pd) {
            set cell_name [TT_2row_sdp__name $cell]
            TT_2row_sdp__prepare_cell $cell

            set owned [lrange $taps $tap_idx [expr {$tap_idx+1}]]
            if {[llength $owned] != 2} {
                close $fp
                error "SDP WellTap pool underflow: PD=$pd cell=$cell_name"
            }
            incr tap_idx 2

            foreach wt_name $owned {
                set wt [get_db insts $wt_name]
                if {[llength $wt] == 0} {
                    close $fp
                    error "Missing SDP WellTap: $wt_name"
                }
                set wt_obj [lindex $wt 0]
                set wt_pd [TT_2row_sdp__pd $wt_obj]
                if {$wt_pd ne $pd} {
                    close $fp
                    error "SDP WellTap '$wt_name' PD=$wt_pd expected=$pd"
                }
            }

            set g [TT_2row_sdp__emit_group $fp $seq $cell $owned]
            puts [format "SDP %-12s PD=%-16s %-3s %-50s taps={%s}" $g $pd $kind($cell_name) $cell_name [join $owned " "]]
            incr seq
            incr group_count
        }
    }

    close $fp
    return $group_count
}


# -----------------------------------------------------------------------------
# Preflight: detect existing SDP membership BEFORE touching any WellTap pool.
# -----------------------------------------------------------------------------
proc TT_2row_sdp__preflight_existing_sdp {pd_cells_name} {
    upvar 1 $pd_cells_name pd_cells

    set total 0
    set existing 0
    set ours 0
    set foreign 0
    set examples {}

    foreach pd [array names pd_cells] {
        foreach inst $pd_cells($pd) {
            incr total

            set cell_name [TT_2row_sdp__name $inst]
            set sdp_name ""
            catch {set sdp_name [get_db $inst .sdp.name]}

            if {$sdp_name eq "" || $sdp_name eq "0x0"} {
                continue
            }

            incr existing

            if {[string match "${::TT_2ROW_SDP_GROUP_PREFIX}_*" $sdp_name]} {
                incr ours
            } else {
                incr foreign
            }

            if {[llength $examples] < 8} {
                lappend examples [list $cell_name $sdp_name]
            }
        }
    }

    puts ""
    puts "======================================================================"
    puts " SDP PREFLIGHT"
    puts "======================================================================"
    puts "2-row special cells : $total"
    puts "Already in any SDP  : $existing"
    puts "Already in SDP2R_*   : $ours"
    puts "Foreign SDP members  : $foreign"

    foreach x $examples {
        lassign $x cell_name sdp_name
        puts "EXISTING SDP: $cell_name -> $sdp_name"
    }

    puts "======================================================================"

    if {$existing == 0} {
        return FRESH
    }

    if {$existing == $total && $foreign == 0} {
        return COMPLETE
    }

    return PARTIAL
}


# -----------------------------------------------------------------------------
# Flat-SDP file helpers.
#
# The generated SDP file is the membership authority for WellTaps.
# Physical-only WellTaps do not reliably expose .sdp/.sdp.name as a usable
# back-reference, so never require a WellTap .sdp attribute here.
# -----------------------------------------------------------------------------
proc TT_2row_sdp__flat_file_members {} {
    if {![file exists $::TT_2ROW_SDP_FILE]} {
        error "SDP file not found: $::TT_2ROW_SDP_FILE"
    }

    set fp [open $::TT_2ROW_SDP_FILE r]
    set members {}
    set group ""
    set pos 0

    while {[gets $fp line] >= 0} {
        set line [string trim $line]

        if {[regexp {^datapath[ \t]+([^ \t\{]+)} $line -> g]} {
            set group $g
            set pos 0
            continue
        }

        if {![regexp {^inst[ \t]+(.+)$} $line -> inst_name]} {
            continue
        }

        set inst_name [string trim $inst_name]

        if {$pos == 0} {
            set role WT_L
        } elseif {$pos == 1} {
            set role CELL
        } elseif {$pos == 2} {
            set role WT_R
        } else {
            set role EXTRA
        }

        lappend members [list $group $role $inst_name]
        incr pos
    }

    close $fp
    return $members
}

proc TT_2row_sdp__flat_member_names {} {
    set result {}
    foreach item [TT_2row_sdp__flat_file_members] {
        lassign $item group role inst_name
        if {$role eq "WT_L" || $role eq "CELL" || $role eq "WT_R"} {
            lappend result $inst_name
        }
    }
    return [lsort -unique $result]
}


# -----------------------------------------------------------------------------
# V7.18 background isolation policy.
# Temporary place_design is used only to obtain provisional coordinates for the
# canonical 2-row LS/ISO cells.  Before place_sdps or any targeted refine, all
# originally-unplaced NON-SDP instances are restored to UNPLACED so they cannot
# act as placement obstacles.  In addition, every low-power LS/ISO/RET cell that
# is NOT a canonical center CELL is forced UNPLACED during the SDP-repair window.
# This tool must never FIX non-canonical low-power cells.
# -----------------------------------------------------------------------------
proc TT_2row_sdp__canonical_center_objects {} {
    catch {array unset inst_exact}
    catch {array unset inst_leaf}
    TT_2row_sdp__build_inst_lookup inst_exact inst_leaf

    set result {}
    foreach rec [TT_2row_sdp__flat_group_records] {
        lassign $rec group wt_l_name cell_name wt_r_name
        set cell [TT_2row_sdp__resolve_inst $cell_name inst_exact inst_leaf]
        if {$cell eq ""} {
            error "V7.18 cannot resolve canonical 2-row center CELL '$cell_name' for group '$group'."
        }
        lappend result $cell
    }
    return [lsort -unique $result]
}

proc TT_2row_sdp__collect_lowpower_objects {} {
    if {[llength [info commands get_cells]] == 0 ||
        [llength [info commands get_object_name]] == 0} {
        error "V7.18 low-power status guard requires get_cells/get_object_name."
    }

    set result {}
    catch {array unset seen}
    foreach spec {
        {LS  {is_level_shifter == true}}
        {ISO {is_isolation_cell == true}}
        {RET {is_retention == true}}
    } {
        lassign $spec cls filter_expr
        set logical_cells {}
        if {[catch {set logical_cells [get_cells -hierarchical -filter $filter_expr]} err]} {
            error "V7.18 cannot query $cls low-power cells with '$filter_expr': $err"
        }
        set names {}
        if {[llength $logical_cells] > 0} {
            set names [get_object_name $logical_cells]
        }
        foreach n $names {
            set objs {}
            catch {set objs [get_db insts $n]}
            foreach obj $objs {
                if {![info exists seen($obj)]} {
                    set seen($obj) 1
                    lappend result $obj
                }
            }
        }
    }
    return $result
}

proc TT_2row_sdp__force_noncanonical_lp_unplaced {{phase "SDP_REPAIR"}} {
    catch {array unset canonical}
    foreach obj [TT_2row_sdp__canonical_center_objects] {
        set canonical($obj) 1
    }

    set lp_total 0
    set canonical_skip 0
    set changed 0
    set already_unplaced 0
    set fixed_released 0
    set placed_released 0

    foreach obj [TT_2row_sdp__collect_lowpower_objects] {
        incr lp_total
        if {[info exists canonical($obj)]} {
            incr canonical_skip
            continue
        }

        set st ""
        catch {set st [get_db $obj .place_status]}
        if {$st eq "unplaced"} {
            incr already_unplaced
            continue
        }
        if {$st eq "fixed"} { incr fixed_released }
        if {$st eq "placed" || $st eq "soft_fixed"} { incr placed_released }

        set n [TT_2row_sdp__name $obj]
        if {[catch {set_db $obj .place_status unplaced} err]} {
            error "V7.18 cannot unplace non-canonical low-power cell '$n' during $phase: $err"
        }
        incr changed
    }

    puts ""
    puts "======================================================================"
    puts " V7.18 NON-CANONICAL LOW-POWER UNPLACE GUARD"
    puts "======================================================================"
    puts "Phase                       : $phase"
    puts "All LS/ISO/RET cells        : $lp_total"
    puts "Canonical 2-row centers     : $canonical_skip"
    puts "Other LP forced UNPLACED    : $changed"
    puts "  released from FIXED       : $fixed_released"
    puts "  released from PLACED      : $placed_released"
    puts "Other LP already UNPLACED   : $already_unplaced"
    puts "Policy                      : only canonical 2-row SDP members may be FIXED"
    puts "======================================================================"
    TT_2row_sdp__diag_write "LP_UNPLACE phase={$phase} total=$lp_total canonical=$canonical_skip changed=$changed fixed_released=$fixed_released placed_released=$placed_released already_unplaced=$already_unplaced"
    return $changed
}

proc TT_2row_sdp__prepare_background_for_repair {snapshot_names {phase "SDP_REPAIR"}} {
    # Store the authoritative pre-global-placement snapshot for integrated and
    # manual targeted-refine helpers in this Innovus session.
    set ::TT_2ROW_SDP_PRE_UNPLACED_SNAPSHOT $snapshot_names

    puts ""
    puts "======================================================================"
    puts " V7.18 PREPARE EMPTY BACKGROUND FOR SDP REPAIR"
    puts "======================================================================"
    puts "Phase                    : $phase"
    puts "Snapshot originally-unplaced: [llength $snapshot_names]"
    puts "Action                   : restore NON-SDP background to UNPLACED"
    puts "LP policy                : non-canonical LS/ISO/RET -> UNPLACED"
    puts "======================================================================"

    set restored [TT_2row_sdp__restore_preexisting_unplaced $snapshot_names]
    set lp_changed [TT_2row_sdp__force_noncanonical_lp_unplaced $phase]

    # Verify that no surviving exact snapshot instance outside the canonical SDP
    # remains placed/fixed.  This is the core 'empty background' invariant.
    catch {array unset inst_exact}
    catch {array unset inst_leaf}
    TT_2row_sdp__build_inst_lookup inst_exact inst_leaf
    catch {array unset protected}
    foreach n [TT_2row_sdp__flat_member_names] {
        set obj [TT_2row_sdp__resolve_inst $n inst_exact inst_leaf]
        if {$obj ne ""} { set protected($obj) 1 }
    }

    set interfering 0
    set first_bad ""
    foreach n $snapshot_names {
        set obj [TT_2row_sdp__resolve_snapshot_inst_exact $n inst_exact]
        if {$obj eq ""} { continue }
        if {[info exists protected($obj)]} { continue }
        set st ""
        catch {set st [get_db $obj .place_status]}
        if {$st ne "unplaced"} {
            incr interfering
            if {$first_bad eq ""} { set first_bad "$n:$st" }
        }
    }
    if {$interfering != 0} {
        error "V7.18 background-unplace invariant failed during $phase: $interfering originally-unplaced NON-SDP instance(s) remain placed/fixed; first=$first_bad."
    }

    puts "PASS: V7.18 background is clear for SDP repair; surviving originally-unplaced NON-SDP cells are UNPLACED."
    TT_2row_sdp__diag_write "BACKGROUND_CLEAR phase={$phase} restored=$restored lp_changed=$lp_changed interfering=$interfering"
    return [dict create restored $restored lp_unplaced $lp_changed interfering $interfering]
}


# -----------------------------------------------------------------------------
# V6.6 missing-WellTap recovery helpers.
#
# This is intentionally a narrow repair path.  It is legal only when:
#   * preflight is COMPLETE for every discovered 2-row LS/ISO cell;
#   * the generated flat SDP file has exactly one WT_L/CELL/WT_R record/group;
#   * every old WT_L/WT_R from that file is absent from the live DB;
#   * every live SDP row contains exactly the expected CELL and nothing else.
#
# We then create fresh PD-aware WellTaps and use update_sdp to insert them before
# and after the already-attached CELL.  Innovus 21.19 can expose an empty
# SDP-row .local_list even when instance -> .sdp membership is valid, so V6.6
# verifies mutations by exporting the live SDP database with write_sdp_file and
# parsing that file.  We never continue after an unverified edit.
# -----------------------------------------------------------------------------
proc TT_2row_sdp__flat_group_records {} {
    set members [TT_2row_sdp__flat_file_members]
    set order {}
    catch {array unset seen_group}
    catch {array unset role_value}
    catch {array unset role_count}

    foreach item $members {
        lassign $item group role inst_name
        if {$group eq ""} {
            error "Malformed SDP file: inst '$inst_name' appears outside a datapath group."
        }
        if {$role eq "EXTRA"} {
            error "Malformed flat SDP group '$group': more than 3 inst entries."
        }
        if {![info exists seen_group($group)]} {
            set seen_group($group) 1
            lappend order $group
        }
        incr role_count($group,$role)
        if {$role_count($group,$role) > 1} {
            error "Malformed flat SDP group '$group': duplicate role $role."
        }
        set role_value($group,$role) $inst_name
    }

    set result {}
    foreach group $order {
        foreach role {WT_L CELL WT_R} {
            if {![info exists role_value($group,$role)]} {
                error "Malformed flat SDP group '$group': missing role $role."
            }
        }
        lappend result [list $group \
            $role_value($group,WT_L) \
            $role_value($group,CELL) \
            $role_value($group,WT_R)]
    }
    return $result
}

proc TT_2row_sdp__same_obj {a b} {
    if {$a eq "" || $b eq ""} { return false }
    if {$a eq $b} { return true }
    # As a fallback, compare the live .name strings.  This is safe only after
    # each input is already a concrete DB object.
    set an [TT_2row_sdp__name $a]
    set bn [TT_2row_sdp__name $b]
    return [expr {$an ne "" && $bn ne "" && $an eq $bn}]
}

# Parse the ordered inst list of one datapath from any SDP file.  This is used
# for live-DB verification after write_sdp_file and intentionally does not
# depend on internal SDP row attributes such as .local_list.
proc TT_2row_sdp__group_inst_names_from_file {path target_group} {
    if {![file exists $path]} {
        error "SDP snapshot not found: $path"
    }

    set fp [open $path r]
    set in_group false
    set result {}

    while {[gets $fp line] >= 0} {
        set line [string trim $line]

        if {[regexp {^datapath[ \t]+([^ \t\{]+)} $line -> g]} {
            set in_group [expr {$g eq $target_group}]
            continue
        }

        if {!$in_group} { continue }

        # A new datapath is handled above.  Closing braces do not need special
        # handling because only inst lines inside the selected datapath matter.
        if {[regexp {^inst[ \t]+(.+)$} $line -> inst_name]} {
            set inst_name [string trim $inst_name]
            if {$inst_name ne ""} { lappend result $inst_name }
        }
    }
    close $fp
    return $result
}

# V7.23_STAGE02_SAFE_LIVE_SNAPSHOT_SUFFIX_FIX
# V7.24_COMPACT_CHECKPOINT_UI
# V7.25_STAGE02_DB_NATIVE_FINALIZE
# Innovus write_sdp_file treats a filename without a terminal .sdp extension as
# a prefix and may create only <prefix>_inst.  The old live probe used
#   ...generated.sdp.live_probe_<tag>
# and then incorrectly required that exact path to exist.  Always use a real
# .sdp filename for the probe and clean its companion _inst file as well.
proc TT_2row_sdp__write_live_snapshot {} {
    if {[llength [info commands write_sdp_file]] == 0} {
        error "write_sdp_file is unavailable; V7.23 cannot safely verify live SDP topology."
    }

    set tag [format "%d_%d" [pid] [clock clicks]]
    set tmp "${::TT_2ROW_SDP_FILE}.live_probe_${tag}.sdp"
    set tmp_inst "${tmp}_inst"
    catch {file delete -force $tmp}
    catch {file delete -force $tmp_inst}

    if {[catch {write_sdp_file $tmp} err opts]} {
        catch {file delete -force $tmp}
        catch {file delete -force $tmp_inst}
        return -options $opts "write_sdp_file live-topology probe failed: $err"
    }

    if {![file exists $tmp]} {
        set made [glob -nocomplain -- "${tmp}*"]
        catch {file delete -force $tmp_inst}
        error "write_sdp_file returned without creating main live SDP snapshot '$tmp'; generated={$made}."
    }
    return $tmp
}

proc TT_2row_sdp__live_group_member_names {group} {
    set tmp [TT_2row_sdp__write_live_snapshot]
    set tmp_inst "${tmp}_inst"
    set rc [catch {
        set names [TT_2row_sdp__group_inst_names_from_file $tmp $group]
    } err opts]
    catch {file delete -force $tmp}
    catch {file delete -force $tmp_inst}
    if {$rc != 0} { return -options $opts $err }
    return $names
}

proc TT_2row_sdp__names_match_objects {names expected_objs} {
    if {[llength $names] != [llength $expected_objs]} { return false }

    catch {array unset inst_exact}
    catch {array unset inst_leaf}
    TT_2row_sdp__build_inst_lookup inst_exact inst_leaf

    for {set i 0} {$i < [llength $names]} {incr i} {
        set n [lindex $names $i]
        set obj [TT_2row_sdp__resolve_inst $n inst_exact inst_leaf]
        if {$obj eq ""} { return false }
        if {![TT_2row_sdp__same_obj $obj [lindex $expected_objs $i]]} {
            return false
        }
    }
    return true
}

proc TT_2row_sdp__assert_live_group_matches {group expected_objs context} {
    set actual_names [TT_2row_sdp__live_group_member_names $group]
    if {[TT_2row_sdp__names_match_objects $actual_names $expected_objs]} { return }
    error "$context: live exported SDP '$group' mismatch. expected={[join [TT_2row_sdp__member_names $expected_objs] { }]} actual={[join $actual_names { }]}"
}

# Verify the *exact* all-taps-missing state.  This procedure does not mutate DB.
# Returns the parsed group records if repair is safe.
proc TT_2row_sdp__preflight_missing_tap_repair {pd_cells_name} {
    upvar 1 $pd_cells_name pd_cells

    set expected_cells 0
    foreach pd [array names pd_cells] {
        incr expected_cells [llength $pd_cells($pd)]
    }

    set records [TT_2row_sdp__flat_group_records]
    if {[llength $records] != $expected_cells} {
        error "Missing-tap repair refused: SDP file has [llength $records] groups, expected $expected_cells."
    }

    catch {array unset inst_exact}
    catch {array unset inst_leaf}
    TT_2row_sdp__build_inst_lookup inst_exact inst_leaf

    # Build the current discovered-cell set by object identity/name.
    catch {array unset current_cell}
    foreach pd [array names pd_cells] {
        foreach cell $pd_cells($pd) {
            set current_cell([TT_2row_sdp__name $cell]) $cell
        }
    }

    set missing_old_taps 0
    set rows_checked 0
    set seen_cells {}

    foreach rec $records {
        lassign $rec group old_l cell_name old_r

        foreach old_name [list $old_l $old_r] {
            set old_obj [TT_2row_sdp__resolve_inst $old_name inst_exact inst_leaf]
            if {$old_obj ne ""} {
                error "Missing-tap repair refused: old tap still exists: $old_name"
            }
            incr missing_old_taps
        }

        set cell [TT_2row_sdp__resolve_inst $cell_name inst_exact inst_leaf]
        if {$cell eq ""} {
            error "Missing-tap repair refused: expected CELL is missing: $cell_name"
        }
        set live_cell_name [TT_2row_sdp__name $cell]
        if {![info exists current_cell($live_cell_name)]} {
            error "Missing-tap repair refused: file CELL '$cell_name' is not in the current 2-row LS/ISO discovery set."
        }
        if {[lsearch -exact $seen_cells $live_cell_name] >= 0} {
            error "Missing-tap repair refused: CELL '$live_cell_name' appears in more than one flat SDP group."
        }
        lappend seen_cells $live_cell_name

        set row ""
        catch {set row [get_db $cell .sdp]}
        if {$row eq "" || $row eq "0x0"} {
            error "Missing-tap repair refused: CELL '$live_cell_name' lost its SDP row."
        }
        set row_name [TT_2row_sdp__name $row]
        set expected_row "${group}_ROW"
        if {$row_name ne $expected_row} {
            error "Missing-tap repair refused: CELL '$live_cell_name' belongs to '$row_name', expected '$expected_row'."
        }

        # V6.6 safety gate: CELL -> .sdp.name is the authoritative surviving
        # ownership signal. Innovus 21.19 may return an empty row .local_list
        # here even though this association is valid, so do not reject the DB
        # based on .local_list. A live write_sdp_file snapshot is inspected
        # below as a second, non-mutating sanity check.
        incr rows_checked
    }

    set expected_taps [expr {$expected_cells * $::TT_2ROW_SDP_TAPS_PER_CELL}]
    if {$missing_old_taps != $expected_taps} {
        error "Missing-tap repair refused: missing old taps=$missing_old_taps expected=$expected_taps."
    }

    set live_named [TT_2row_sdp__prefix_insts $::TT_2ROW_SDP_WT_PREFIX]
    if {[llength $live_named] != 0} {
        error "Missing-tap repair refused: [llength $live_named] live '$::TT_2ROW_SDP_WT_PREFIX*' instance(s) already exist."
    }

    # Secondary non-mutating sanity check from the live SDP exporter.  In the
    # degraded all-taps-missing state Innovus may export each datapath as empty,
    # CELL-only, or with stale names for the vanished old taps.  We tolerate
    # only those known forms.  Any additional *live* instance is foreign state.
    if {[llength [info commands write_sdp_file]] == 0} {
        error "Missing-tap repair refused: write_sdp_file is unavailable."
    }
    set snap [TT_2row_sdp__write_live_snapshot]
    set export_nonempty 0
    set export_empty 0
    set sanity_rc [catch {
        foreach rec $records {
            lassign $rec group old_l cell_name old_r
            set names [TT_2row_sdp__group_inst_names_from_file $snap $group]
            if {[llength $names] == 0} {
                incr export_empty
                continue
            }
            incr export_nonempty

            set cell [TT_2row_sdp__resolve_inst $cell_name inst_exact inst_leaf]
            foreach n $names {
                set obj [TT_2row_sdp__resolve_inst $n inst_exact inst_leaf]
                if {$obj ne ""} {
                    if {![TT_2row_sdp__same_obj $obj $cell]} {
                        error "Missing-tap repair refused: live exported SDP '$group' contains unexpected live member '$n'."
                    }
                    continue
                }

                # Unresolved names are tolerated only when they are the two old
                # WellTap names recorded in the stale generated SDP metadata.
                set nt [lindex [split [string trimleft $n /] /] end]
                set lt [lindex [split [string trimleft $old_l /] /] end]
                set rt [lindex [split [string trimleft $old_r /] /] end]
                if {$nt ne $lt && $nt ne $rt} {
                    error "Missing-tap repair refused: live exported SDP '$group' contains unknown unresolved member '$n'."
                }
            }
        }
    } sanity_err sanity_opts]
    catch {file delete -force $snap}
    if {$sanity_rc != 0} { return -options $sanity_opts $sanity_err }

    puts ""
    puts "======================================================================"
    puts " V6.6 MISSING-TAP REPAIR PREFLIGHT"
    puts "======================================================================"
    puts "Flat SDP groups checked : [llength $records]"
    puts "CELL->SDP rows verified : $rows_checked"
    puts "Export nonempty groups   : $export_nonempty"
    puts "Export empty groups      : $export_empty"
    puts "Old taps confirmed gone : $missing_old_taps"
    puts "Live SDPWT-prefix taps  : [llength $live_named]"
    puts "Repair state            : SAFE / EXACT ALL-TAPS-MISSING"
    puts "======================================================================"

    return $records
}

# -----------------------------------------------------------------------------
# V6.6 SDP edit API probing
# -----------------------------------------------------------------------------
# Cadence's modern SDP flow documents update_sdp as an operation that adds a
# member relative to a reference object with -before/-after.  Older Common UI
# releases also expose add_sdp_objs.  Innovus 21.19 sits close to this command
# transition, so do not hard-code one guessed option spelling.
#
# Safety rule:
#   * every candidate command is bracketed by write_sdp_file snapshots;
#   * a candidate is accepted ONLY when the target datapath becomes exactly the
#     expected ordered member list;
#   * error/no-op + unchanged topology is safe and the next candidate is tried;
#   * ANY unexpected topology mutation is fatal immediately.
#
# TT_2ROW_SDP_UPDATE_INSERT_MODE remains an optional override.  AUTO probes the
# current Innovus command set once and caches the exact successful family/mode.

proc TT_2row_sdp__capture_help {cmd} {
    if {[llength [info commands $cmd]] == 0} { return "" }

    set txt ""
    if {[llength [info commands redirect]] != 0 && [llength [info commands help]] != 0} {
        # Cadence redirect supports redirect -variable var "command".  Keep this
        # diagnostic-only: failure must never affect the repair itself.
        catch {redirect -variable txt "help $cmd"}
    }
    return $txt
}

proc TT_2row_sdp__dump_edit_api_info {} {
    puts ""
    puts "======================================================================"
    puts " SDP EDIT API DETECTION"
    puts "======================================================================"
    foreach cmd {update_sdp add_sdp_objs update_sdp_group write_sdp_file read_sdp_file} {
        puts [format "%-20s : %s" $cmd [expr {[llength [info commands $cmd]] != 0 ? "AVAILABLE" : "absent"}]]
    }

    # Save the local tool's own syntax help when redirect is supported.  This
    # makes a future failure self-diagnosing without asking the user to rerun
    # manual help commands.
    set diag [tech_mv_output_path report TT_2row_sdp_api_help.txt 02 sdp]
    set fp ""
    if {![catch {set fp [open $diag w]}]} {
        puts $fp "# Innovus-local SDP edit API help captured by $::TT_2ROW_SDP_VERSION"
        foreach cmd {update_sdp add_sdp_objs update_sdp_group read_sdp_file write_sdp_file} {
            if {[llength [info commands $cmd]] == 0} { continue }
            puts $fp "\n===== help $cmd ====="
            set txt [TT_2row_sdp__capture_help $cmd]
            if {$txt ne ""} {
                puts $fp $txt
            } else {
                puts $fp "<help capture unavailable; see Innovus console if probing fails>"
            }
        }
        close $fp
        puts "INFO: Local SDP API help snapshot: $diag"
    }
    puts "======================================================================"
}

# Build one guarded edit command.  The first modes are intentionally the
# reference-driven forms that the previous version did not try.  They match the documented
# semantics: insert NEW relative to REF; REF already belongs to the target row,
# so the parent SDP can be inferred by the tool.
proc TT_2row_sdp__edit_insert_cmd {mode row row_name new_obj new_name ref_obj ref_name side} {
    switch -- $mode {
        UPDATE_SIDE_REF_NEW_OBJ {
            set cmd [list update_sdp $side $ref_obj $new_obj]
        }
        UPDATE_SIDE_REF_NEW_NAME {
            set cmd [list update_sdp $side $ref_name $new_name]
        }
        UPDATE_NEW_OBJ_SIDE_REF {
            set cmd [list update_sdp $new_obj $side $ref_obj]
        }
        UPDATE_NEW_NAME_SIDE_REF {
            set cmd [list update_sdp $new_name $side $ref_name]
        }
        UPDATE_OBJS_OBJ_SIDE_REF {
            set cmd [list update_sdp -objs $new_obj $side $ref_obj]
        }
        UPDATE_OBJS_NAME_SIDE_REF {
            set cmd [list update_sdp -objs $new_name $side $ref_name]
        }
        UPDATE_INSTS_OBJ_SIDE_REF {
            set cmd [list update_sdp -insts $new_obj $side $ref_obj]
        }
        UPDATE_INSTS_NAME_SIDE_REF {
            set cmd [list update_sdp -insts $new_name $side $ref_name]
        }
        UPDATE_NAME_OBJS_NAMES {
            set cmd [list update_sdp -name $row_name -objs $new_name $side $ref_name]
        }
        UPDATE_NAME_INSTS_NAMES {
            set cmd [list update_sdp -name $row_name -insts $new_name $side $ref_name]
        }
        UPDATE_ROW_OBJS_OBJECTS {
            set cmd [list update_sdp $row -objs $new_obj $side $ref_obj]
        }
        UPDATE_ROW_INSTS_OBJECTS {
            set cmd [list update_sdp $row -insts $new_obj $side $ref_obj]
        }
        UPDATE_NAME_ADD_OBJS_NAMES {
            set cmd [list update_sdp -name $row_name -add -objs $new_name $side $ref_name]
        }
        UPDATE_NAME_ADD_NAMES {
            set cmd [list update_sdp -name $row_name -add $new_name $side $ref_name]
        }
        UPDATE_ROW_ADD_OBJS_OBJECTS {
            set cmd [list update_sdp $row -add -objs $new_obj $side $ref_obj]
        }
        UPDATE_ROW_ADD_NAMES {
            set cmd [list update_sdp $row_name -add $new_name $side $ref_name]
        }
        UPDATE_INFER_ADD_OBJS {
            set cmd [list update_sdp -add -objs $new_name $side $ref_name]
        }

        ADD_SIDE_REF_NEW_OBJ {
            set cmd [list add_sdp_objs $side $ref_obj $new_obj]
        }
        ADD_SIDE_REF_NEW_NAME {
            set cmd [list add_sdp_objs $side $ref_name $new_name]
        }
        ADD_ROW_NEW_OBJ_SIDE_REF {
            set cmd [list add_sdp_objs $row $new_obj $side $ref_obj]
        }
        ADD_ROWNAME_NEWNAME_SIDE_REF {
            set cmd [list add_sdp_objs $row_name $new_name $side $ref_name]
        }
        ADD_ROW_OBJS_SIDE_REF {
            set cmd [list add_sdp_objs $row -objs $new_obj $side $ref_obj]
        }
        ADD_ROWNAME_OBJS_SIDE_REF {
            set cmd [list add_sdp_objs $row_name -objs $new_name $side $ref_name]
        }
        ADD_NAME_OBJS_SIDE_REF {
            set cmd [list add_sdp_objs -name $row_name -objs $new_name $side $ref_name]
        }
        ADD_SDP_OBJS_SIDE_REF {
            set cmd [list add_sdp_objs -sdp $row_name -objs $new_name $side $ref_name]
        }
        ADD_GROUP_OBJS_SIDE_REF {
            set cmd [list add_sdp_objs -sdp_group $row_name -objs $new_name $side $ref_name]
        }
        default {
            error "Unknown TT_2ROW_SDP_UPDATE_INSERT_MODE '$mode'."
        }
    }
    return [uplevel #0 $cmd]
}

proc TT_2row_sdp__candidate_insert_modes {} {
    set modes {}

    if {[llength [info commands update_sdp]] != 0} {
        # Most likely modern syntax first: NEW is inserted relative to REF and
        # REF already identifies the parent row.
        lappend modes \
            UPDATE_SIDE_REF_NEW_OBJ \
            UPDATE_SIDE_REF_NEW_NAME \
            UPDATE_NEW_OBJ_SIDE_REF \
            UPDATE_NEW_NAME_SIDE_REF \
            UPDATE_OBJS_OBJ_SIDE_REF \
            UPDATE_OBJS_NAME_SIDE_REF \
            UPDATE_INSTS_OBJ_SIDE_REF \
            UPDATE_INSTS_NAME_SIDE_REF \
            UPDATE_NAME_OBJS_NAMES \
            UPDATE_NAME_INSTS_NAMES \
            UPDATE_ROW_OBJS_OBJECTS \
            UPDATE_ROW_INSTS_OBJECTS \
            UPDATE_NAME_ADD_OBJS_NAMES \
            UPDATE_NAME_ADD_NAMES \
            UPDATE_ROW_ADD_OBJS_OBJECTS \
            UPDATE_ROW_ADD_NAMES \
            UPDATE_INFER_ADD_OBJS
    }

    if {[llength [info commands add_sdp_objs]] != 0} {
        lappend modes \
            ADD_SIDE_REF_NEW_OBJ \
            ADD_SIDE_REF_NEW_NAME \
            ADD_ROW_NEW_OBJ_SIDE_REF \
            ADD_ROWNAME_NEWNAME_SIDE_REF \
            ADD_ROW_OBJS_SIDE_REF \
            ADD_ROWNAME_OBJS_SIDE_REF \
            ADD_NAME_OBJS_SIDE_REF \
            ADD_SDP_OBJS_SIDE_REF \
            ADD_GROUP_OBJS_SIDE_REF
    }

    return $modes
}

proc TT_2row_sdp__mode_family_available {mode} {
    if {[string match "UPDATE_*" $mode]} {
        return [expr {[llength [info commands update_sdp]] != 0}]
    }
    if {[string match "ADD_*" $mode]} {
        return [expr {[llength [info commands add_sdp_objs]] != 0}]
    }
    return false
}

proc TT_2row_sdp__update_insert {row new_obj ref_obj side expected_after} {
    if {[llength [info commands write_sdp_file]] == 0} {
        error "write_sdp_file is unavailable; cannot verify SDP edit safely."
    }
    if {[llength [info commands update_sdp]] == 0 && [llength [info commands add_sdp_objs]] == 0} {
        error "Neither update_sdp nor add_sdp_objs is available; cannot safely repair an existing SDP row in-place."
    }
    if {$side ne "-before" && $side ne "-after"} {
        error "Internal error: SDP insertion side must be -before or -after."
    }

    set row_name [TT_2row_sdp__name $row]
    set group $row_name
    regsub {_ROW$} $group {} group
    set new_name [TT_2row_sdp__name $new_obj]
    set ref_name [TT_2row_sdp__name $ref_obj]

    set configured $::TT_2ROW_SDP_UPDATE_INSERT_MODE
    if {$configured ne "AUTO"} {
        if {![TT_2row_sdp__mode_family_available $configured]} {
            error "Configured SDP insertion mode '$configured' requires an API that is not available in this Innovus build."
        }
        set modes [list $configured]
    } else {
        set modes [TT_2row_sdp__candidate_insert_modes]
    }
    if {[llength $modes] == 0} {
        error "No supported SDP edit command family is available."
    }

    set failures {}
    foreach mode $modes {
        # Use the exported live SDP as the before/after mutation authority.
        set before_names [TT_2row_sdp__live_group_member_names $group]

        set rc [catch {
            TT_2row_sdp__edit_insert_cmd $mode $row $row_name $new_obj $new_name $ref_obj $ref_name $side
        } err opts]

        set after_names [TT_2row_sdp__live_group_member_names $group]

        if {$rc != 0} {
            # Parameter probing is allowed only when the exported topology did
            # not change at all.
            if {$after_names ne $before_names} {
                error "SDP edit mode '$mode' returned an error but changed exported SDP '$group'. before={$before_names} after={$after_names}. Restore the pre-repair DB checkpoint. Error: $err"
            }
            lappend failures "$mode => $err"
            continue
        }

        if {[TT_2row_sdp__names_match_objects $after_names $expected_after]} {
            if {$configured eq "AUTO"} {
                set ::TT_2ROW_SDP_UPDATE_INSERT_MODE $mode
                puts "INFO: SDP insertion API resolved and cached: $mode"
            }
            return $mode
        }

        # A command that returns success but does absolutely nothing is still a
        # safe probe miss.  Continue probing instead of treating it as damage.
        if {$after_names eq $before_names} {
            lappend failures "$mode => returned success but made no topology change"
            continue
        }

        # Any other successful mutation is unsafe because we cannot prove how
        # to roll it back without a checkpoint.
        set expected_names {}
        foreach x $expected_after { lappend expected_names [TT_2row_sdp__name $x] }
        error "SDP edit mode '$mode' returned success but changed '$group' to an unexpected topology. before={$before_names} after={$after_names} expected={$expected_names}. Restore the pre-repair DB checkpoint."
    }

    puts "ERROR: No supported SDP member-insertion form succeeded."
    foreach f $failures { puts "  $f" }
    puts "INFO: Innovus-local command syntax follows:"
    if {[llength [info commands help]] != 0} {
        if {[llength [info commands update_sdp]] != 0} {
            catch {help update_sdp}
        }
        if {[llength [info commands add_sdp_objs]] != 0} {
            catch {help add_sdp_objs}
        }
    } else {
        if {[llength [info commands update_sdp]] != 0} { catch {update_sdp -help} }
        if {[llength [info commands add_sdp_objs]] != 0} { catch {add_sdp_objs -help} }
    }
    error "Unable to add '$new_name' $side '$ref_name' in SDP row '$row_name'."
}

proc TT_2row_sdp__write_repaired_file {records tap_pair_name} {
    upvar 1 $tap_pair_name tap_pair

    set tmp "${::TT_2ROW_SDP_FILE}.v6_5_tmp"
    set fp [open $tmp w]
    puts $fp "# Auto-repaired by TT_2row_sdp_welltap_after_endcap_v6_6_detach_reload_repair.tcl"
    puts $fp "# Version: $::TT_2ROW_SDP_VERSION"
    puts $fp ""

    foreach rec $records {
        lassign $rec group old_l cell_name old_r
        if {![info exists tap_pair($group)] || [llength $tap_pair($group)] != 2} {
            close $fp
            catch {file delete -force $tmp}
            error "Internal repair error: no two-tap assignment for '$group'."
        }
        lassign $tap_pair($group) wt_l wt_r
        puts $fp "datapath $group {"
        lassign [TT_2row_sdp__padding_geometry] pad_x pad_y
        puts $fp "  row ${group}_ROW {"
        puts $fp "    justifyBy S"
        puts $fp [format "    padding %.6f %.6f" $pad_x $pad_y]
        puts $fp "    inst $wt_l"
        puts $fp "    inst $cell_name"
        puts $fp "    inst $wt_r"
        puts $fp "  }"
        puts $fp "}"
        puts $fp ""
    }
    close $fp

    set backup "${::TT_2ROW_SDP_FILE}.pre_v6_5_api_probe_repair"
    if {[file exists $::TT_2ROW_SDP_FILE] && ![file exists $backup]} {
        file copy -force $::TT_2ROW_SDP_FILE $backup
        puts "INFO: Backed up stale SDP file: $backup"
    }
    file rename -force $tmp $::TT_2ROW_SDP_FILE
    puts "INFO: Rewrote repaired SDP file: $::TT_2ROW_SDP_FILE"
}

proc TT_2row_sdp__validate_live_flat_rows {} {
    set records [TT_2row_sdp__flat_group_records]
    catch {array unset inst_exact}
    catch {array unset inst_leaf}
    TT_2row_sdp__build_inst_lookup inst_exact inst_leaf

    set snap [TT_2row_sdp__write_live_snapshot]
    set checked 0
    set full_rows 0
    set center_only_rows 0
    set rc [catch {
        foreach rec $records {
            lassign $rec group wt_l_name cell_name wt_r_name
            set wt_l [TT_2row_sdp__resolve_inst $wt_l_name inst_exact inst_leaf]
            set cell [TT_2row_sdp__resolve_inst $cell_name inst_exact inst_leaf]
            set wt_r [TT_2row_sdp__resolve_inst $wt_r_name inst_exact inst_leaf]
            if {$wt_l eq "" || $cell eq "" || $wt_r eq ""} {
                error "Live topology validation failed for '$group': unresolved WT_L/CELL/WT_R."
            }

            set row ""
            catch {set row [get_db $cell .sdp]}
            if {$row eq "" || $row eq "0x0"} {
                error "Live topology validation failed for '$group': CELL has no SDP row."
            }
            if {[TT_2row_sdp__name $row] ne "${group}_ROW"} {
                error "Live topology validation failed for '$group': CELL row='[TT_2row_sdp__name $row]'."
            }

            set actual_names [TT_2row_sdp__group_inst_names_from_file $snap $group]
            if {[TT_2row_sdp__names_match_objects $actual_names [list $wt_l $cell $wt_r]]} {
                incr full_rows
            } elseif {[TT_2row_sdp__names_match_objects $actual_names [list $cell]]} {
                # V7.14 finalized form: keep the center low-power CELL in SDP,
                # while the two physical-only taps stay at their legalized
                # coordinates but are no longer SDP members.  This prevents a
                # mixed Power-Domain-group SDP from tripping IMPFP-3763 at DB
                # save time without deleting the SDP constraint itself.
                foreach tap [list $wt_l $wt_r] {
                    set tap_sdp ""
                    set tap_st ""
                    catch {set tap_sdp [get_db $tap .sdp.name]}
                    catch {set tap_st [get_db $tap .place_status]}
                    if {$tap_sdp ne "" && $tap_sdp ne "0x0"} {
                        error "Finalized live topology validation failed for '$group': side tap '[TT_2row_sdp__name $tap]' still belongs to SDP '$tap_sdp'."
                    }
                    if {$tap_st ne "fixed"} {
                        error "Finalized live topology validation failed for '$group': side tap '[TT_2row_sdp__name $tap]' status='$tap_st', expected fixed."
                    }
                }
                incr center_only_rows
            } else {
                error "Live SDP '$group' has unsupported membership. expected pre-final={[join [list [TT_2row_sdp__name $wt_l] [TT_2row_sdp__name $cell] [TT_2row_sdp__name $wt_r]] { }]} or finalized={[TT_2row_sdp__name $cell]} actual={[join $actual_names { }]}"
            }
            incr checked
        }
    } err opts]
    catch {file delete -force $snap}
    if {$rc != 0} { return -options $opts $err }

    puts "PASS: Live SDP topology validated: groups=$checked full_WT_CELL_WT=$full_rows finalized_CELL_only=$center_only_rows."
    return $checked
}

proc TT_2row_sdp__detach_cmd {mode cell cell_name} {
    switch -- $mode {
        DETACH_OPT_OBJ  { return [list update_sdp -detach $cell] }
        DETACH_OPT_NAME { return [list update_sdp -detach $cell_name] }
        DETACH_OBJ_OPT  { return [list update_sdp $cell -detach] }
        DETACH_NAME_OPT { return [list update_sdp $cell_name -detach] }
        default { error "Unknown SDP detach mode '$mode'." }
    }
}

proc TT_2row_sdp__detach_modes {} {
    return {DETACH_OPT_OBJ DETACH_OPT_NAME DETACH_OBJ_OPT DETACH_NAME_OPT}
}

proc TT_2row_sdp__detach_cell {cell} {
    if {[llength [info commands update_sdp]] == 0} {
        error "update_sdp is unavailable; cannot detach surviving CELL from stale SDP shell."
    }

    set cell_name [TT_2row_sdp__name $cell]
    set before ""
    catch {set before [get_db $cell .sdp.name]}
    if {$before eq "" || $before eq "0x0"} { return "ALREADY_DETACHED" }

    set modes [TT_2row_sdp__detach_modes]
    if {[info exists ::TT_2ROW_SDP_DETACH_MODE] &&
        $::TT_2ROW_SDP_DETACH_MODE ne "" &&
        $::TT_2ROW_SDP_DETACH_MODE ne "AUTO"} {
        set modes [list $::TT_2ROW_SDP_DETACH_MODE]
    }

    set last_errors {}
    foreach mode $modes {
        set cmd [TT_2row_sdp__detach_cmd $mode $cell $cell_name]
        set rc [catch {uplevel #0 $cmd} err opts]

        set after ""
        catch {set after [get_db $cell .sdp.name]}
        if {$after eq "" || $after eq "0x0"} {
            set ::TT_2ROW_SDP_DETACH_MODE $mode
            puts "INFO: SDP detach API resolved and cached: $mode"
            return $mode
        }

        if {$rc != 0} {
            lappend last_errors "$mode => $err"
            continue
        }
        lappend last_errors "$mode => command returned success but CELL remained in SDP '$after'"
    }

    error "Unable to detach CELL '$cell_name' from stale SDP '$before'. Tried: [join $last_errors { ; }]"
}

# V7.1 replacement SDP writer reuses the canonical/original SDP2R_* names only
# after the corresponding stale empty SDP shells have been explicitly deleted.
proc TT_2row_sdp__write_reload_repair_file {records tap_pair_name path} {
    upvar 1 $tap_pair_name tap_pair

    set fp [open $path w]
    puts $fp "# Auto-repaired by TT_2row_sdp_welltap_after_endcap_v7_1_stale_sdp_purge.tcl"
    puts $fp "# Version: $::TT_2ROW_SDP_VERSION"
    puts $fp "# Strategy: detach surviving CELLs from stale SDP shells, then read a new flat SDP file"
    puts $fp ""

    set seq 0
    foreach rec $records {
        lassign $rec old_group old_l cell_name old_r
        if {![info exists tap_pair($old_group)] || [llength $tap_pair($old_group)] != 2} {
            close $fp
            error "Internal V6.7 repair error: no two-tap assignment for '$old_group'."
        }
        lassign $tap_pair($old_group) wt_l wt_r
        # V7.1: stale SDP shells are explicitly deleted before reload, so the
        # replacement can safely reuse the canonical/original SDP2R_* name.
        set new_group $old_group

        puts $fp "datapath $new_group {"
        puts $fp "  row ${new_group}_ROW {"
        puts $fp "    justifyBy S"
        puts $fp "    inst $wt_l"
        puts $fp "    inst $cell_name"
        puts $fp "    inst $wt_r"
        puts $fp "  }"
        puts $fp "}"
        puts $fp ""
        incr seq
    }
    close $fp
    return $seq
}


# -----------------------------------------------------------------------------
# V7.1 stale-SDP-shell purge.
#
# After update_sdp -detach, Innovus can leave the old SDP2R_* datapath/row
# objects alive as empty shells.  place_design -sdp scans the global SDP DB and
# can then fail on a stale child such as SDP2R_00000_ROW.  Cadence's documented
# SDP reset flow uses deleteSdpObject -object ... before readSdpFile.  V7.1 does
# the same thing, but only for the exact SDP2R_* groups parsed from our generated
# flat SDP file; foreign SDP groups are never touched.
# -----------------------------------------------------------------------------
proc TT_2row_sdp__file_has_datapath {path group} {
    if {![file exists $path]} { return false }
    set fp [open $path r]
    set found false
    while {[gets $fp line] >= 0} {
        set line [string trim $line]
        if {[regexp {^datapath[ \t]+([^ \t\{]+)} $line -> g] && $g eq $group} {
            set found true
            break
        }
    }
    close $fp
    return $found
}

proc TT_2row_sdp__delete_one_stale_group {group mode} {
    switch -- $mode {
        CUI_ROWS_BLOCKAGES_KEEP {
            return [list delete_sdp_rows_blockages -sdps [list $group] -keep_cell_placement]
        }
        LEGACY_OBJECT_OPT { return [list deleteSdpObject -object $group] }
        default { error "Unknown stale-SDP delete mode '$mode'." }
    }
}

proc TT_2row_sdp__stale_delete_modes {} {
    set modes {}
    # Innovus 21.19 reports delete_sdp_rows_blockages as the supported Common-UI
    # replacement for obsolete delete_sdp_obj.  Keep cell placement because the
    # [WT_L][CELL][WT_R] members are deliberately FIXED before SDP finalization.
    if {[llength [info commands delete_sdp_rows_blockages]] != 0} {
        lappend modes CUI_ROWS_BLOCKAGES_KEEP
    }
    # Retain the documented legacy API only as a compatibility fallback for
    # older databases/installs that do not expose the Common-UI replacement.
    if {[llength [info commands deleteSdpObject]] != 0} {
        lappend modes LEGACY_OBJECT_OPT
    }
    return $modes
}

proc TT_2row_sdp__purge_stale_groups {records} {
    set modes [TT_2row_sdp__stale_delete_modes]
    if {[llength $modes] == 0} {
        error "V7.11 stale-SDP purge requires delete_sdp_rows_blockages or legacy deleteSdpObject, but neither command is available. No replacement SDP was loaded."
    }

    # Confirm all intended stale groups are visible in a live SDP export before
    # deleting anything. This protects unrelated/foreign SDP objects.
    set before_snap [TT_2row_sdp__write_live_snapshot]
    set expected 0
    set rc [catch {
        foreach rec $records {
            lassign $rec group old_l cell_name old_r
            if {![TT_2row_sdp__file_has_datapath $before_snap $group]} {
                error "Stale-SDP purge refused: expected old datapath '$group' is absent from live write_sdp_file snapshot."
            }
            incr expected
        }
    } err opts]
    catch {file delete -force $before_snap}
    if {$rc != 0} { return -options $opts $err }

    if {$expected == 0} { return 0 }

    # Resolve the working delete syntax on the first stale group only. Once the
    # first deletion is proven through write_sdp_file, reuse that exact syntax for
    # the remaining groups without 233 extra full SDP exports.
    set first_rec [lindex $records 0]
    lassign $first_rec first_group first_l first_cell first_r
    set selected_mode ""
    set failures {}

    foreach mode $modes {
        set cmd [TT_2row_sdp__delete_one_stale_group $first_group $mode]
        set cmd_rc [catch {uplevel #0 $cmd} cmd_err cmd_opts]

        set probe [TT_2row_sdp__write_live_snapshot]
        set still_there [TT_2row_sdp__file_has_datapath $probe $first_group]
        catch {file delete -force $probe}

        if {!$still_there} {
            set selected_mode $mode
            puts "INFO: Stale SDP deletion API resolved and cached: $mode"
            break
        }

        if {$cmd_rc != 0} {
            lappend failures "$mode => $cmd_err"
        } else {
            lappend failures "$mode => returned success but '$first_group' remained in live SDP export"
        }
    }

    if {$selected_mode eq ""} {
        error "Unable to delete first stale SDP datapath '$first_group'. Tried: [join $failures { ; }]"
    }

    set deleted 1
    foreach rec [lrange $records 1 end] {
        lassign $rec group old_l cell_name old_r
        set cmd [TT_2row_sdp__delete_one_stale_group $group $selected_mode]
        if {[catch {uplevel #0 $cmd} cmd_err cmd_opts]} {
            return -options $cmd_opts "Stale SDP deletion failed for '$group' using cached mode '$selected_mode': $cmd_err"
        }
        incr deleted
    }

    # One final whole-database verification. No old SDP2R_* shell may survive
    # into place_design -sdp, otherwise Innovus 21.19 can hit IMPDBTCL-206 on
    # stale row objects such as SDP2R_00000_ROW.
    set after_snap [TT_2row_sdp__write_live_snapshot]
    set remaining {}
    foreach rec $records {
        lassign $rec group old_l cell_name old_r
        if {[TT_2row_sdp__file_has_datapath $after_snap $group]} {
            lappend remaining $group
        }
    }
    catch {file delete -force $after_snap}

    if {[llength $remaining] != 0} {
        error "V7.2 stale-SDP purge incomplete: [llength $remaining] old group(s) remain, first=[lindex $remaining 0]."
    }
    if {$deleted != $expected} {
        error "V7.2 stale-SDP purge count mismatch: deleted=$deleted expected=$expected."
    }

    puts "PASS: Deleted $deleted stale SDP2R_* datapath shell(s) before replacement reload."
    return $deleted
}

proc TT_2row_sdp__repair_all_missing_taps {pd_cells_name} {
    upvar 1 $pd_cells_name pd_cells

    if {![TT_2row_sdp__bool $::TT_2ROW_SDP_AUTO_REPAIR_MISSING_TAPS]} {
        error "All dedicated SDP WellTaps are missing, and TT_2ROW_SDP_AUTO_REPAIR_MISSING_TAPS=false."
    }
    foreach cmd {update_sdp read_sdp_file write_sdp_file} {
        if {[llength [info commands $cmd]] == 0} {
            error "All dedicated SDP WellTaps are missing, but required command '$cmd' is unavailable."
        }
    }
    if {[llength [TT_2row_sdp__stale_delete_modes]] == 0} {
        error "All dedicated SDP WellTaps are missing, but neither delete_sdp_rows_blockages nor legacy deleteSdpObject is available for safe stale-SDP-shell cleanup."
    }

    set records [TT_2row_sdp__preflight_missing_tap_repair pd_cells]
    TT_2row_sdp__diag_mark "R10_REPAIR_PREFLIGHT_PASS" "records=[llength $records]"

    # Fresh PD-aware taps are created only after the non-mutating preflight has
    # proven the exact known failure mode: all 234 CELL memberships survived,
    # while every dedicated tap disappeared.
    catch {array unset pools}
    TT_2row_sdp__build_pools pd_cells pools
    TT_2row_sdp__diag_mark "R20_POOL_CREATED" "expected_taps=[expr {[llength $records] * 2}]"

    catch {array unset inst_exact}
    catch {array unset inst_leaf}
    TT_2row_sdp__build_inst_lookup inst_exact inst_leaf

    catch {array unset pool_idx}
    catch {array unset tap_pair}
    catch {array unset cell_obj}
    set assigned 0

    # First assign two newly-created taps to every old record without mutating
    # SDP ownership.  This lets us generate the complete replacement file before
    # the first detach.
    foreach rec $records {
        lassign $rec old_group old_l cell_name old_r
        set cell [TT_2row_sdp__resolve_inst $cell_name inst_exact inst_leaf]
        if {$cell eq ""} { error "Repair internal error: CELL disappeared: $cell_name" }
        set pd [TT_2row_sdp__pd $cell]
        if {![info exists pools($pd)]} { error "No repair WellTap pool for CELL '$cell_name' PD='$pd'." }
        if {![info exists pool_idx($pd)]} { set pool_idx($pd) 0 }
        set i $pool_idx($pd)
        set wt_l_name [lindex $pools($pd) $i]
        set wt_r_name [lindex $pools($pd) [expr {$i+1}]]
        if {$wt_l_name eq "" || $wt_r_name eq ""} {
            error "Repair WellTap pool underflow: PD=$pd old_group=$old_group index=$i"
        }
        incr pool_idx($pd) 2
        set tap_pair($old_group) [list $wt_l_name $wt_r_name]
        set cell_obj($old_group) $cell
        incr assigned
    }

    if {$assigned != [llength $records]} {
        error "Repair tap assignment incomplete: assigned=$assigned expected=[llength $records]."
    }

    set repair_tmp "${::TT_2ROW_SDP_FILE}.v7_1_reload_tmp"
    catch {file delete -force $repair_tmp}
    set written [TT_2row_sdp__write_reload_repair_file $records tap_pair $repair_tmp]
    if {$written != [llength $records]} {
        error "Repair SDP generation incomplete: groups=$written expected=[llength $records]."
    }

    puts ""
    puts "======================================================================"
    puts " V7.2 DETACH + PURGE + RELOAD + IN-SCOPE PLACE/FIX REPAIR"
    puts "======================================================================"
    puts "Surviving CELLs to detach : [llength $records]"
    puts "Fresh WellTaps created     : [expr {[llength $records] * 2}]"
    puts "Replacement SDP groups     : $written"
    puts "Replacement SDP file       : $repair_tmp"
    puts "Strategy                   : detach CELLs + delete stale SDP shells + reload canonical groups"
    puts "======================================================================"

    set detached 0
    set loaded false
    TT_2row_sdp__diag_mark "R30_BEFORE_REPAIR_CATCH"
    set repair_rc [catch {
        TT_2row_sdp__diag_mark "R31_INSIDE_REPAIR_CATCH_ENTRY"
        # The documented SDP API explicitly supports update_sdp -detach for
        # removing an SDP object from its parent.  Resolve the exact 21.19
        # argument ordering on the first CELL, then cache it for all others.
        foreach rec $records {
            lassign $rec old_group old_l cell_name old_r
            set cell $cell_obj($old_group)
            set old_row ""
            catch {set old_row [get_db $cell .sdp.name]}
            if {$old_row eq "" || $old_row eq "0x0"} {
                error "CELL '$cell_name' unexpectedly lost SDP ownership before detach."
            }
            TT_2row_sdp__detach_cell $cell
            set now ""
            catch {set now [get_db $cell .sdp.name]}
            if {$now ne "" && $now ne "0x0"} {
                error "Detach verification failed: CELL '$cell_name' still belongs to '$now'."
            }
            incr detached
        }

        TT_2row_sdp__diag_mark "R40_AFTER_DETACH" "detached=$detached"
        puts "INFO: Detached $detached surviving 2-row CELLs from stale SDP shells."

        # V7.1/V7.2 STALE-SHELL FIX FOR IMPDBTCL-206 AFTER place_design -sdp:
        # detach removes CELL ownership but can leave empty SDP2R_* / *_ROW DB
        # objects behind.  Purge those stale shells before loading the repaired
        # topology, then reuse the canonical/original group names.
        set purged [TT_2row_sdp__purge_stale_groups $records]
        TT_2row_sdp__diag_mark "R50_AFTER_STALE_PURGE" "purged=$purged"
        puts "INFO: Purged $purged stale SDP2R_* datapath shell(s)."
        puts "INFO: Loading replacement flat SDP file with canonical/original group names."
        TT_2row_sdp__diag_mark "R60_BEFORE_READ_SDP_FILE" "file=$repair_tmp"
        if {[catch {read_sdp_file $repair_tmp} load_err load_opts]} {
            return -options $load_opts "read_sdp_file replacement repair failed: $load_err"
        }
        set loaded true
        TT_2row_sdp__diag_mark "R61_AFTER_READ_SDP_FILE" "loaded=true"

        # V6.9 IMPORTANT: read_sdp_file has just mutated the live SDP database.
        # Never keep using pre-reload DPO handles as verification authority.
        # Rebuild the live instance lookup from scratch, re-resolve every CELL
        # and both freshly-created WellTaps by name, then verify the exported
        # live SDP topology before committing the generated SDP file.
        catch {array unset verify_exact}
        catch {array unset verify_leaf}
        TT_2row_sdp__build_inst_lookup verify_exact verify_leaf

        set verify_snap [TT_2row_sdp__write_live_snapshot]
        set verify_seq 0
        set verify_rc [catch {
            foreach rec $records {
                lassign $rec old_group old_l cell_name old_r
                if {![info exists tap_pair($old_group)] || [llength $tap_pair($old_group)] != 2} {
                    error "Replacement SDP verification lost two-tap assignment for '$old_group'."
                }
                lassign $tap_pair($old_group) wt_l_name wt_r_name

                set cell [TT_2row_sdp__resolve_inst $cell_name verify_exact verify_leaf]
                set wt_l [TT_2row_sdp__resolve_inst $wt_l_name verify_exact verify_leaf]
                set wt_r [TT_2row_sdp__resolve_inst $wt_r_name verify_exact verify_leaf]
                if {$cell eq "" || $wt_l eq "" || $wt_r eq ""} {
                    error "Replacement SDP verification unresolved member(s): group='$old_group' WT_L='$wt_l_name' CELL='$cell_name' WT_R='$wt_r_name'."
                }

                # V7.2 reload reuses the original canonical group name after
                # deleting its stale empty shell.
                set expected_group $old_group
                set expected_row "${expected_group}_ROW"
                set actual_row ""
                catch {set actual_row [get_db $cell .sdp.name]}
                if {$actual_row ne $expected_row} {
                    error "Replacement SDP ownership mismatch after fresh re-resolve: CELL '$cell_name' row='$actual_row' expected='$expected_row'."
                }

                set actual_names [TT_2row_sdp__group_inst_names_from_file $verify_snap $expected_group]
                if {![TT_2row_sdp__names_match_objects $actual_names [list $wt_l $cell $wt_r]]} {
                    error "Replacement SDP strict topology mismatch: group='$expected_group' expected={[join [list [TT_2row_sdp__name $wt_l] [TT_2row_sdp__name $cell] [TT_2row_sdp__name $wt_r]] { }]} actual={[join $actual_names { }]}"
                }
                incr verify_seq
            }
        } verify_err verify_opts]
        catch {file delete -force $verify_snap}
        if {$verify_rc != 0} {
            return -options $verify_opts $verify_err
        }
        if {$verify_seq != $written} {
            error "Replacement SDP ownership/topology verification count mismatch: checked=$verify_seq expected=$written."
        }
        TT_2row_sdp__diag_mark "R70_AFTER_STRICT_RELOAD_VERIFY" "groups=$verify_seq"
        puts "PASS: Replacement SDP reload verified with fresh live DB handles: $verify_seq x WT_L -> CELL -> WT_R."

        # V7.2 ROOT-CAUSE FIX:
        # The latest failure showed that all 468 physical-only taps can vanish
        # after this repair scope completes, before the creator's later placement
        # handoff.  Therefore do not exit this catch while the repaired taps are
        # merely PLACED.  Temporarily point the authoritative SDP-file variable at
        # the replacement file, run the complete placement/fix transaction NOW,
        # then restore the canonical path.  TT_flow_place_2row_sdp validates every
        # member again after place_design and place_sdps and FIXes only SDP members.
        set saved_sdp_file $::TT_2ROW_SDP_FILE
        set ::TT_2ROW_SDP_FILE $repair_tmp
        TT_2row_sdp__diag_mark "R80_BEFORE_INNER_PLACE_FLOW"
        puts "INFO: V7.2 repair-scope handoff: placing/fixing repaired SDP BEFORE repair scope exits."
        puts "INFO: V7.2 temporary placement authority: $::TT_2ROW_SDP_FILE"
        set inner_live_master_before [llength [TT_2row_sdp__tap_objects]]
        set inner_live_prefix_before [llength [TT_2row_sdp__prefix_insts $::TT_2ROW_SDP_WT_PREFIX]]
        puts "INFO: V7.2 repair-scope pre-place live WellTap master count = $inner_live_master_before"
        puts "INFO: V7.2 repair-scope pre-place live SDPWT prefix count    = $inner_live_prefix_before"
        if {$inner_live_master_before != [expr {$written * 2}] || $inner_live_prefix_before != [expr {$written * 2}]} {
            error "V7.2 repair-scope pre-place live-tap count mismatch: master=$inner_live_master_before prefix=$inner_live_prefix_before expected=[expr {$written * 2}]."
        }
        set inner_place_rc [catch {
            TT_flow_place_2row_sdp
        } inner_place_err inner_place_opts]
        set ::TT_2ROW_SDP_FILE $saved_sdp_file
        if {$inner_place_rc != 0} {
            TT_2row_sdp__diag_mark "R81_INNER_PLACE_FLOW_ERROR" $inner_place_err
            error "V7.2 in-repair-scope placement/fix failed: $inner_place_err"
        }
        TT_2row_sdp__diag_mark "R82_AFTER_INNER_PLACE_FLOW"
        set inner_live_master_after [llength [TT_2row_sdp__tap_objects]]
        set inner_live_prefix_after [llength [TT_2row_sdp__prefix_insts $::TT_2ROW_SDP_WT_PREFIX]]
        puts "INFO: V7.2 repair-scope post-fix live WellTap master count = $inner_live_master_after"
        puts "INFO: V7.2 repair-scope post-fix live SDPWT prefix count    = $inner_live_prefix_after"
        if {$inner_live_master_after != [expr {$written * 2}] || $inner_live_prefix_after != [expr {$written * 2}]} {
            error "V7.2 repair-scope post-fix live-tap count mismatch: master=$inner_live_master_after prefix=$inner_live_prefix_after expected=[expr {$written * 2}]."
        }
        puts "PASS: V7.2 repaired SDP members were placed/fixed before repair scope exit."
        TT_2row_sdp__diag_mark "R90_JUST_BEFORE_REPAIR_CATCH_EXIT"
    } repair_err repair_opts]

    TT_2row_sdp__diag_mark "R91_IMMEDIATELY_AFTER_REPAIR_CATCH" "repair_rc=$repair_rc"

    if {$repair_rc != 0} {
        puts ""
        puts "======================================================================"
        puts " V7.2 REPAIR ABORTED"
        puts "======================================================================"
        puts "Detached CELLs            : $detached"
        puts "Replacement SDP loaded    : $loaded"
        puts "Reason                    : $repair_err"
        if {$detached == 0} {
            puts "INFO: No SDP ownership was changed. Cleaning up fresh repair WellTaps."
            set cleanup_objs {}
            foreach pd [array names pools] {
                foreach n $pools($pd) {
                    set obj [TT_2row_sdp__resolve_inst $n inst_exact inst_leaf]
                    if {$obj ne ""} { lappend cleanup_objs $obj }
                }
            }
            if {[llength $cleanup_objs] != 0} { TT_2row_sdp__delete_objects $cleanup_objs }
            puts "INFO: Repair pool cleanup complete; live SDP ownership is unchanged."
        } else {
            puts "ERROR: SDP ownership has been mutated by the detach/reload attempt."
            puts "ERROR: Restore the checkpoint from before V7.2 before retrying. Do not source this Tcl again on this partially-mutated DB."
        }
        puts "======================================================================"
        catch {file delete -force $repair_tmp}
        return -options $repair_opts $repair_err
    }

    # The replacement file is now the authoritative generated SDP description.
    # Preserve the stale file once, then atomically replace it.
    set backup "${::TT_2ROW_SDP_FILE}.pre_v7_2_repair_scope_place_fix"
    if {[file exists $::TT_2ROW_SDP_FILE] && ![file exists $backup]} {
        file copy -force $::TT_2ROW_SDP_FILE $backup
        puts "INFO: Backed up stale SDP file: $backup"
    }
    TT_2row_sdp__diag_mark "R100_BEFORE_CANONICAL_FILE_COMMIT"
    file rename -force $repair_tmp $::TT_2ROW_SDP_FILE
    puts "INFO: Replacement SDP is now authoritative: $::TT_2ROW_SDP_FILE"
    TT_2row_sdp__diag_mark "R101_AFTER_CANONICAL_FILE_COMMIT"

    # Rebuild lookup because the repair instances and SDP ownership are now live.
    catch {array unset inst_exact}
    catch {array unset inst_leaf}
    TT_2row_sdp__build_inst_lookup inst_exact inst_leaf

    TT_2row_sdp__diag_mark "R110_BEFORE_POST_CATCH_VALIDATION"
    TT_2row_sdp__validate_flat_file pd_cells
    TT_2row_sdp__diag_mark "R111_AFTER_POST_CATCH_VALIDATION"
    TT_2row_sdp__validate_live_flat_rows

    if {$::TT_2ROW_SDP_RUN_CHECK && [llength [info commands check_sdps]] > 0} {
        puts "INFO: check_sdps after V7.2 detach-purge-reload + in-scope placement repair"
        check_sdps -out_file [tech_mv_native_sdp_report_path]
    }

    puts ""
    puts "======================================================================"
    puts " V7.2 MISSING-TAP REPAIR COMPLETE"
    puts "======================================================================"
    puts "Detached stale CELL links : $detached"
    puts "Recreated WellTaps        : [expr {[llength $records] * 2}]"
    puts "New SDP groups            : $written"
    puts "Topology                  : WT_L -> CELL -> WT_R"
    puts "Method                    : detach + purge stale SDP shells + canonical read_sdp_file"
    puts "======================================================================"
    return [llength $records]
}

proc TT_2row_sdp__validate_flat_file {pd_cells_name} {
    upvar 1 $pd_cells_name pd_cells

    set expected_cells 0
    foreach pd [array names pd_cells] {
        incr expected_cells [llength $pd_cells($pd)]
    }
    set expected_taps [expr {$expected_cells * $::TT_2ROW_SDP_TAPS_PER_CELL}]

    set groups {}
    set existing_cells 0
    set existing_taps 0
    set missing_cells 0
    set missing_taps 0
    set bad_master 0
    set bad_pd 0
    set alias_resolved 0

    # Local validation maps.  Do NOT use bare `set var` here: in Tcl that
    # reads an existing variable instead of declaring/initializing it.
    # A fresh proc frame does not need a scalar initializer; array unset is
    # sufficient and remains safe if this proc is changed/re-entered later.
    catch {array unset group_cell_pd}
    catch {array unset group_left_pd}
    catch {array unset group_left_name}

    # Build one live-DB lookup table for this validation pass.  This avoids
    # repeatedly scanning the whole design and makes old hierarchical names in
    # the generated SDP file resolvable after DB reload/re-entry.
    catch {array unset inst_exact}
    catch {array unset inst_leaf}
    TT_2row_sdp__build_inst_lookup inst_exact inst_leaf

    foreach item [TT_2row_sdp__flat_file_members] {
        lassign $item group role inst_name

        if {[lsearch -exact $groups $group] < 0} {
            lappend groups $group
        }

        set direct_probe {}
        catch {set direct_probe [get_db insts $inst_name]}
        set inst [TT_2row_sdp__resolve_inst $inst_name inst_exact inst_leaf]
        if {$inst ne "" && [llength $direct_probe] == 0} {
            incr alias_resolved
        }

        if {$role eq "WT_L" || $role eq "WT_R"} {
            if {$inst eq ""} {
                incr missing_taps
                puts "MISSING TAP  $group  $role  $inst_name"
                continue
            }

            set master [TT_2row_sdp__master $inst]
            set tap_pd [TT_2row_sdp__pd $inst]

            if {$master ne $::TT_2ROW_SDP_WELLTAP_MASTER} {
                incr bad_master
                puts "BAD TAP MASTER  $group  $role  $inst_name  master=$master"
            }

            if {$role eq "WT_L"} {
                set group_left_pd($group) $tap_pd
                set group_left_name($group) $inst_name
            } elseif {[info exists group_cell_pd($group)] &&
                      $group_cell_pd($group) ne "" &&
                      $tap_pd ne $group_cell_pd($group)} {
                incr bad_pd
                puts "BAD TAP PD  $group  WT_R  $inst_name  tap_pd=$tap_pd cell_pd=$group_cell_pd($group)"
            }

            incr existing_taps
            continue
        }

        if {$role eq "CELL"} {
            if {$inst eq ""} {
                incr missing_cells
                puts "MISSING CELL $group  $inst_name"
                continue
            }

            set cell_pd [TT_2row_sdp__pd $inst]
            set group_cell_pd($group) $cell_pd

            if {[info exists group_left_pd($group)] &&
                $group_left_pd($group) ne "" &&
                $cell_pd ne "" &&
                $group_left_pd($group) ne $cell_pd} {
                incr bad_pd
                puts "BAD TAP PD  $group  WT_L  $group_left_name($group)  tap_pd=$group_left_pd($group) cell_pd=$cell_pd"
            }

            incr existing_cells
        }
    }

    set group_count [llength $groups]
    set live_tap_master_count [llength [TT_2row_sdp__tap_objects]]
    set live_sdpwt_name_count [llength [TT_2row_sdp__prefix_insts $::TT_2ROW_SDP_WT_PREFIX]]

    TT_2row_sdp__diag_validation $group_count $expected_cells $existing_cells $expected_taps $existing_taps $alias_resolved $live_tap_master_count $live_sdpwt_name_count $missing_cells $missing_taps $bad_master $bad_pd

    puts ""
    puts "======================================================================"
    puts " FLAT SDP FILE / DB VALIDATION"
    puts "======================================================================"
    puts "SDP groups in file      : $group_count"
    puts "Expected 2-row cells    : $expected_cells"
    puts "Existing 2-row cells    : $existing_cells"
    puts "Expected SDP WellTaps   : $expected_taps"
    puts "Existing SDP WellTaps   : $existing_taps"
    puts "Alias-resolved members  : $alias_resolved"
    puts "Live WellTap master inst: $live_tap_master_count"
    puts "Live SDPWT-name insts   : $live_sdpwt_name_count"
    puts "Missing cells           : $missing_cells"
    puts "Missing WellTaps        : $missing_taps"
    puts "Wrong WellTap master    : $bad_master"
    puts "Power-Domain mismatches : $bad_pd"
    puts "======================================================================"

    if {$group_count != $expected_cells ||
        $existing_cells != $expected_cells ||
        $existing_taps != $expected_taps ||
        $missing_cells != 0 ||
        $missing_taps != 0 ||
        $bad_master != 0 ||
        $bad_pd != 0} {
        if {$missing_taps != 0} {
            if {$live_sdpwt_name_count == 0} {
                puts "DIAG: No live instance name contains '$::TT_2ROW_SDP_WT_PREFIX'."
                puts "DIAG: If this is a COMPLETE preflight rerun, the SDP cell groups survived but their dedicated physical-only WellTaps are no longer present in the live DB."
            } else {
                puts "DIAG: Dedicated SDPWT-like instances do exist in the live DB, but some file members could not be resolved uniquely."
                puts "DIAG: Check the printed MISSING TAP names for a true rename or duplicate leaf-name condition."
            }
        }
        TT_2row_sdp__diag_mark "VALIDATION_FAIL" "existing_taps=$existing_taps expected_taps=$expected_taps missing_taps=$missing_taps"
        error "Flat SDP file/DB validation failed."
    }

    TT_2row_sdp__diag_mark "VALIDATION_PASS" "existing_taps=$existing_taps expected_taps=$expected_taps"
    puts {PASS: Every [WT_L][2-row CELL][WT_R] member exists in the live DB.}
    return $existing_taps
}

proc TT_2row_sdp__snapshot_unplaced {} {
    set result {}

    foreach inst [get_db insts] {
        set st ""
        if {[catch {set st [get_db $inst .place_status]}]} {
            continue
        }

        if {$st eq "unplaced"} {
            set n [TT_2row_sdp__name $inst]
            if {$n ne ""} {
                lappend result $n
            }
        }
    }

    puts "INFO: Pre-SDP temporary-placement snapshot: [llength $result] instance(s) were unplaced."
    return $result
}

proc TT_2row_sdp__set_flat_members_fixed {} {
    set names [TT_2row_sdp__flat_member_names]
    set changed 0

    catch {array unset inst_exact}
    catch {array unset inst_leaf}
    TT_2row_sdp__build_inst_lookup inst_exact inst_leaf

    foreach n $names {
        set inst [TT_2row_sdp__resolve_inst $n inst_exact inst_leaf]
        if {$inst eq ""} {
            error "Cannot fix missing SDP member: $n"
        }

        if {[catch {set_db $inst .place_status fixed} err]} {
            error "Cannot set SDP member '$n' to fixed: $err"
        }
        incr changed
    }

    puts "INFO: Fixed canonical 2-row SDP members only: $changed (non-SDP low-power cells are not fixed by this proc)"
    return $changed
}


# -----------------------------------------------------------------------------
# V7.10 fixed-member finalization helpers.
# SDP is used only to legalize [WT_L][CELL][WT_R].  Once all members are FIXED,
# remove the temporary SDP constraint objects so a physical-only WellTap is not
# required to become a logical member of a power-domain floorplan group.
# -----------------------------------------------------------------------------
proc TT_2row_sdp__live_inst_count {} {
    return [llength [get_db insts]]
}

proc TT_2row_sdp__assert_flat_members_fixed {} {
    catch {array unset inst_exact}
    catch {array unset inst_leaf}
    TT_2row_sdp__build_inst_lookup inst_exact inst_leaf

    set checked 0
    foreach n [TT_2row_sdp__flat_member_names] {
        set inst [TT_2row_sdp__resolve_inst $n inst_exact inst_leaf]
        if {$inst eq ""} {
            error "V7.10 fixed-member verification failed: missing SDP member '$n'."
        }
        set st ""
        catch {set st [get_db $inst .place_status]}
        if {$st ne "fixed"} {
            error "V7.10 fixed-member verification failed: '$n' place_status='$st', expected fixed."
        }
        incr checked
    }
    puts "PASS: V7.10 fixed-member verification = $checked member(s)."
    return $checked
}

# =============================================================================
# V7.26 Stage-8F DB-native finalization helpers
#
# IMPORTANT:
#   * self-contained in THIS main Tcl file
#   * no dependency on TT_SDP_V2_8_* hotfix Tcl
#   * no write_sdp_file probe
#   * live Innovus get_db *_ROW objects are the authority
# =============================================================================
proc TT_2row_sdp__stage8f_obj_name {obj} {
    set n ""
    catch {set n [get_db $obj .name]}
    return $n
}

proc TT_2row_sdp__stage8f_same_member_set {expected live} {
    if {[llength $expected] != [llength $live]} { return false }
    set a {}
    set b {}
    foreach o $expected { lappend a [TT_2row_sdp__stage8f_obj_name $o] }
    foreach o $live     { lappend b [TT_2row_sdp__stage8f_obj_name $o] }
    return [expr {[lsort -dictionary $a] eq [lsort -dictionary $b]}]
}

proc TT_2row_sdp__stage8f_precheck {} {
    if {[llength [info commands get_db]] == 0} {
        error "V7.26 Stage-8F requires Innovus get_db."
    }

    set records [TT_2row_sdp__flat_group_records]
    if {[llength $records] == 0} {
        error "V7.26 Stage-8F precheck found no canonical flat SDP groups."
    }

    catch {array unset inst_exact}
    catch {array unset inst_leaf}
    TT_2row_sdp__build_inst_lookup inst_exact inst_leaf

    set groups 0
    set live_rows 0
    set member_match_rows 0
    set resolved_members 0
    set fixed_members 0
    set bad_location_members 0
    set first_issue ""

    foreach rec $records {
        lassign $rec group wt_l_name cell_name wt_r_name
        incr groups

        set expected_objs {}
        foreach n [list $wt_l_name $cell_name $wt_r_name] {
            set inst [TT_2row_sdp__resolve_inst $n inst_exact inst_leaf]
            if {$inst eq ""} {
                if {$first_issue eq ""} { set first_issue "missing canonical member '$n'" }
                continue
            }
            lappend expected_objs $inst
            incr resolved_members

            set st ""
            catch {set st [get_db $inst .place_status]}
            if {$st eq "fixed"} { incr fixed_members }

            set raw {}
            catch {set raw [get_db $inst .location]}
            set loc [TT_2row_sdp__normalize_xy_point $raw]
            if {[llength $loc] != 2} {
                incr bad_location_members
                if {$first_issue eq ""} { set first_issue "unreadable location for '$n': '$raw'" }
            }
        }

        set row_name "${group}_ROW"
        set hits {}
        catch {set hits [get_db top_sdps -if [format {.name == "%s"} $row_name]]}
        if {[llength $hits] != 1} {
            if {$first_issue eq ""} {
                set first_issue "live SDP row '$row_name' count=[llength $hits], expected=1"
            }
            continue
        }
        incr live_rows

        set live_members {}
        catch {set live_members [get_db [lindex $hits 0] .insts]}
        if {[llength $expected_objs] == 3 &&
            [llength $live_members] == 3 &&
            [TT_2row_sdp__stage8f_same_member_set $expected_objs $live_members]} {
            incr member_match_rows
        } elseif {$first_issue eq ""} {
            set first_issue "member mismatch in live SDP row '$row_name'"
        }
    }

    set expected_members [expr {$groups * 3}]
    set ok [expr {
        $live_rows == $groups &&
        $member_match_rows == $groups &&
        $resolved_members == $expected_members &&
        $fixed_members == $expected_members &&
        $bad_location_members == 0
    }]

    return [dict create \
        ok $ok \
        groups $groups \
        live_rows $live_rows \
        member_match_rows $member_match_rows \
        expected_members $expected_members \
        resolved_members $resolved_members \
        fixed_members $fixed_members \
        bad_location_members $bad_location_members \
        first_issue $first_issue]
}

proc TT_2row_sdp__stage8f_print_precheck {r} {
    puts ""
    puts "======================================================================"
    puts " STAGE-8F PRECHECK"
    puts "======================================================================"
    puts [format "%-10s %-30s : %d/%d" {[TOOL]} {live *_ROW shells} [dict get $r live_rows] [dict get $r groups]]
    puts [format "%-10s %-30s : %d/%d" {[CUSTOM]} {3-member row matches} [dict get $r member_match_rows] [dict get $r groups]]
    puts [format "%-10s %-30s : %d/%d" {[CUSTOM]} {fixed canonical members} [dict get $r fixed_members] [dict get $r expected_members]]
    if {[dict get $r ok]} {
        puts "RESULT    : PASS"
        puts "NEXT      : automatic Stage-8F finalization"
    } else {
        puts "RESULT    : FAIL"
        puts "FIRST     : [dict get $r first_issue]"
        puts "NEXT      : stop; do not delete SDP shells"
    }
    puts "======================================================================"
    return ""
}

# Public read-only Stage-8F probe for operator testing after a definition reload.
# It does not move/fix/delete anything and intentionally returns an empty string
# so Innovus does not echo the full result dict at the interactive prompt.
proc TT_SDP_STAGE8F_TEST {} {
    set r [TT_2row_sdp__stage8f_precheck]
    TT_2row_sdp__stage8f_print_precheck $r
    return ""
}

proc TT_2row_sdp__dissolve_flat_constraints_preserve_members {} {
    if {[llength [info commands delete_sdp_rows_blockages]] == 0} {
        error "V7.28 SDP finalization requires delete_sdp_rows_blockages."
    }

    set pre [TT_2row_sdp__stage8f_precheck]
    TT_2row_sdp__stage8f_print_precheck $pre
    if {![dict get $pre ok]} {
        error "V7.28 SDP finalization precheck FAIL: [dict get $pre first_issue]"
    }

    set records [TT_2row_sdp__flat_group_records]
    catch {array unset inst_exact}
    catch {array unset inst_leaf}
    TT_2row_sdp__build_inst_lookup inst_exact inst_leaf

    catch {array unset member_loc}
    catch {array unset member_orient}
    catch {array unset member_bbox}
    catch {array unset member_obj}
    set member_names {}
    set live_delete_names {}

    # Snapshot the exact legalized geometry before deleting any SDP shell.
    foreach rec $records {
        lassign $rec group wt_l_name cell_name wt_r_name
        set row_name "${group}_ROW"
        lappend live_delete_names $row_name

        foreach n [list $wt_l_name $cell_name $wt_r_name] {
            set inst [TT_2row_sdp__resolve_inst $n inst_exact inst_leaf]
            if {$inst eq ""} {
                error "V7.28 SDP finalization lost member '$n' after precheck."
            }
            if {[lsearch -exact $member_names $n] >= 0} { continue }

            set raw {}
            catch {set raw [get_db $inst .location]}
            set loc [TT_2row_sdp__normalize_xy_point $raw]
            if {[llength $loc] != 2} {
                error "V7.28 SDP finalization cannot normalize location for '$n': '$raw'."
            }
            set orient ""
            catch {set orient [get_db $inst .orient]}
            set bbox {}
            catch {set bbox [TT_2row_sdp__bbox4 [get_db $inst .bbox]]}
            if {[llength $bbox] != 4} {
                error "V7.28 SDP finalization cannot normalize bbox for '$n'."
            }

            set member_loc($n) $loc
            set member_orient($n) $orient
            set member_bbox($n) $bbox
            set member_obj($n) $inst
            lappend member_names $n
        }
    }

    set inst_count_before [TT_2row_sdp__live_inst_count]
    set deleted 0
    set refixed 0
    set restored 0

    # V7.28 IMPORTANT:
    # Do NOT delete all 234 rows in one command.  Innovus 21.19 can downgrade
    # all members to PLACED at once, then legally re-snap later members while
    # processing the batch.  Delete exactly ONE *_ROW at a time and immediately
    # restore/refix its three members before touching the next row.
    foreach rec $records {
        lassign $rec group wt_l_name cell_name wt_r_name
        set row_name "${group}_ROW"

        set delete_cmd [list delete_sdp_rows_blockages -sdps [list $row_name] -keep_cell_placement]
        if {[catch {uplevel #0 $delete_cmd} delete_err delete_opts]} {
            return -options $delete_opts "V7.28 sequential SDP delete failed for '$row_name': $delete_err"
        }

        set hits {}
        catch {set hits [get_db top_sdps -if [format {.name == "%s"} $row_name]]}
        if {[llength $hits] != 0} {
            error "V7.28 SDP finalization incomplete: '$row_name' still exists after delete."
        }
        incr deleted

        # -keep_cell_placement is not sufficient in a bulk delete on this DB.
        # For the just-deleted row only, immediately verify exact geometry and
        # restore it if Innovus normalized the placement origin/site.  The three
        # members are FIXED again before the next SDP row is deleted.
        foreach n [list $wt_l_name $cell_name $wt_r_name] {
            set inst $member_obj($n)

            set st ""
            catch {set st [get_db $inst .place_status]}
            if {$st eq "unplaced" || $st eq ""} {
                error "V7.28 SDP finalization unplaced member '$n' while deleting '$row_name'."
            }

            set raw {}
            catch {set raw [get_db $inst .location]}
            set loc [TT_2row_sdp__normalize_xy_point $raw]
            set orient ""
            catch {set orient [get_db $inst .orient]}
            set bbox {}
            catch {set bbox [TT_2row_sdp__bbox4 [get_db $inst .bbox]]}

            set geom_changed [expr {$loc ne $member_loc($n) ||
                                    $orient ne $member_orient($n) ||
                                    $bbox ne $member_bbox($n)}]

            if {$geom_changed} {
                # Restore exact legalized placement.  .location/.orient are
                # settable Common-UI placement attributes in this flow.
                if {[catch {
                    set_db $inst .place_status placed
                    set_db $inst .location $member_loc($n)
                    if {$member_orient($n) ne ""} {
                        set_db $inst .orient $member_orient($n)
                    }
                    set_db $inst .place_status fixed
                } restore_err]} {
                    error "V7.28 could not restore '$n' after deleting '$row_name': $restore_err"
                }
                incr restored
            } elseif {$st ne "fixed"} {
                if {[catch {set_db $inst .place_status fixed} fix_err]} {
                    error "V7.28 could not re-fix '$n' after deleting '$row_name' (status='$st'): $fix_err"
                }
                incr refixed
            }

            # Hard verification after restore/refix, before the next row delete.
            set now_st ""
            catch {set now_st [get_db $inst .place_status]}
            set now_raw {}
            catch {set now_raw [get_db $inst .location]}
            set now_loc [TT_2row_sdp__normalize_xy_point $now_raw]
            set now_orient ""
            catch {set now_orient [get_db $inst .orient]}
            set now_bbox {}
            catch {set now_bbox [TT_2row_sdp__bbox4 [get_db $inst .bbox]]}

            if {$now_st ne "fixed" ||
                $now_loc ne $member_loc($n) ||
                $now_orient ne $member_orient($n) ||
                $now_bbox ne $member_bbox($n)} {
                error "V7.28 exact-placement verify failed for '$n' after deleting '$row_name': status=$now_st loc={$now_loc} expected_loc={$member_loc($n)} orient=$now_orient expected_orient=$member_orient($n) bbox={$now_bbox} expected_bbox={$member_bbox($n)}"
            }
        }
    }

    if {$deleted != [llength $records]} {
        error "V7.28 SDP finalization count mismatch: deleted=$deleted expected=[llength $records]."
    }

    # Whole-database shell verification after all sequential deletes.
    set remaining {}
    foreach row_name $live_delete_names {
        set hits {}
        catch {set hits [get_db top_sdps -if [format {.name == "%s"} $row_name]]}
        if {[llength $hits] != 0} { lappend remaining $row_name }
    }
    if {[llength $remaining] != 0} {
        error "V7.28 SDP finalization incomplete: [llength $remaining] live *_ROW shell(s) remain, first=[lindex $remaining 0]."
    }

    set inst_count_after [TT_2row_sdp__live_inst_count]
    if {$inst_count_after != $inst_count_before} {
        error "V7.28 SDP finalization changed live instance count: before=$inst_count_before after=$inst_count_after."
    }

    puts ""
    puts "======================================================================"
    puts " STAGE-8F FINALIZATION"
    puts "======================================================================"
    puts [format "%-10s %-30s : %d" {[TOOL]} {SDP shells deleted} $deleted]
    puts [format "%-10s %-30s : %d" {[CUSTOM]} {members preserved} [llength $member_names]]
    puts [format "%-10s %-30s : %d" {[CUSTOM]} {members immediately re-fixed} $refixed]
    puts [format "%-10s %-30s : %d" {[CUSTOM]} {geometry restores} $restored]
    puts "RESULT    : PASS"
    puts "======================================================================"

    catch {
        TT_2row_sdp__diag_write "FINALIZE_SDP_V7_28_SEQUENTIAL groups=$deleted members=[llength $member_names] refixed=$refixed restored=$restored inst_before=$inst_count_before inst_after=$inst_count_after"
    }
    return $deleted
}

proc TT_2row_sdp__restore_preexisting_unplaced {snapshot_names} {
    # SDP-file members may legitimately need alias resolution, so keep the
    # robust SDP resolver only for building the protected SDP-member set.
    catch {array unset inst_exact}
    catch {array unset inst_leaf}
    TT_2row_sdp__build_inst_lookup inst_exact inst_leaf

    catch {array unset is_sdp_obj}
    foreach n [TT_2row_sdp__flat_member_names] {
        set inst [TT_2row_sdp__resolve_inst $n inst_exact inst_leaf]
        if {$inst eq ""} {
            error "Cannot protect missing SDP member during restore: $n"
        }
        set is_sdp_obj($inst) 1
    }

    set restored 0
    set already_unplaced 0
    set missing 0
    set protected_sdp 0
    set missing_names {}

    foreach n $snapshot_names {
        # V7.5 IMPORTANT: snapshot names came from live get_db .name before
        # temporary global placement.  Use exact/canonical matching only.
        # NEVER fall back to leaf-name lookup (U192, U42, ...), because the
        # design contains many repeated leaf names in different hierarchies.
        set inst [TT_2row_sdp__resolve_snapshot_inst_exact $n inst_exact]
        if {$inst eq ""} {
            incr missing
            lappend missing_names $n
            puts "WARNING: Pre-placement NON-SDP instance disappeared during temporary global placement; exact instance will not be guessed/restored: $n"
            continue
        }

        if {[info exists is_sdp_obj($inst)]} {
            incr protected_sdp
            continue
        }

        set st ""
        catch {set st [get_db $inst .place_status]}

        if {$st eq "unplaced"} {
            incr already_unplaced
            continue
        }

        if {[catch {set_db $inst .place_status unplaced} err]} {
            error "Cannot restore temporary-placed non-SDP instance '$n' to unplaced: $err"
        }

        incr restored
    }

    puts ""
    puts "======================================================================"
    puts " RESTORE TEMPORARY NON-SDP PLACEMENT"
    puts "======================================================================"
    puts "Snapshot unplaced       : [llength $snapshot_names]"
    puts "Protected SDP members   : $protected_sdp"
    puts "Restored to unplaced    : $restored"
    puts "Already unplaced        : $already_unplaced"
    puts "Missing after placement : $missing"
    puts "Resolver policy         : exact/canonical only; NO leaf fallback"
    puts "======================================================================"

    set ::TT_2ROW_SDP_LAST_RESTORE_MISSING $missing_names
    TT_2row_sdp__diag_write "RESTORE_NONSDP summary snapshot=[llength $snapshot_names] protected_sdp=$protected_sdp restored=$restored already_unplaced=$already_unplaced missing=$missing exact_only=1"
    set report_limit 50
    set report_i 0
    foreach n $missing_names {
        if {$report_i >= $report_limit} { break }
        TT_2row_sdp__diag_write "RESTORE_MISSING exact_name={$n}"
        incr report_i
    }
    if {[llength $missing_names] > $report_limit} {
        TT_2row_sdp__diag_write "RESTORE_MISSING truncated=[expr {[llength $missing_names] - $report_limit}]"
    }

    if {$missing != 0} {
        puts "WARNING: $missing originally-unplaced NON-SDP instance(s) no longer exist after temporary global placement."
        puts "WARNING: They are NOT substituted with same-leaf instances; restore continues with surviving exact instances only."
        if {[TT_2row_sdp__bool $::TT_2ROW_SDP_STRICT_RESTORE_MISSING]} {
            error "Strict restore policy: temporary global placement removed $missing originally-unplaced non-SDP instance(s)."
        }
    }

    return $restored
}

# -----------------------------------------------------------------------------
# V7.8: purge temporary-placement non-SDP standard cells.
#
# Candidate authority is the PRE-global-place UNPLACED snapshot, not library-name
# heuristics.  This means cells/macros/infrastructure that were already placed or
# fixed before the temporary place_design are never candidates in the first place.
# Additional hard protections:
#   * every SDP-file member is protected by live object identity;
#   * any base_cell.class matching block* is preserved as a hard macro;
#   * only base_cell.class matching core* is deleted (ordinary/core std-cell class);
#   * missing exact snapshot names are treated as already removed by optimization.
#
# No leaf-name fallback is allowed for snapshot instances.
# -----------------------------------------------------------------------------
proc TT_2row_sdp__purge_preexisting_unplaced_non_sdp_std {snapshot_names pd_cells_name} {
    error "V7.10 safety: destructive non-SDP standard-cell purge is disabled. Use TT_2row_sdp__restore_preexisting_unplaced instead."
}

proc TT_2row_sdp__all_flat_members_fixed {} {
    catch {array unset inst_exact}
    catch {array unset inst_leaf}
    TT_2row_sdp__build_inst_lookup inst_exact inst_leaf

    foreach n [TT_2row_sdp__flat_member_names] {
        set inst [TT_2row_sdp__resolve_inst $n inst_exact inst_leaf]
        if {$inst eq ""} {
            return false
        }

        set st ""
        catch {set st [get_db $inst .place_status]}
        if {$st ne "fixed"} {
            return false
        }
    }

    return true
}

proc TT_proc_create_2row_sdp_welltap {} {
    TT_2row_sdp__check_commands

    set master $::TT_2ROW_SDP_WELLTAP_MASTER
    if {[llength [get_db base_cells $master]] == 0} { error "WellTap master not found: $master" }

    puts ""
    puts "======================================================================"
    puts " CREATE 2-ROW LS / ISO SDP WELLTAP"
    puts "======================================================================"
    puts "Version          : $::TT_2ROW_SDP_VERSION"
    puts "Common UI load   : read_sdp_file"
    puts "WellTap master   : $master"
    puts "Taps / cell      : $::TT_2ROW_SDP_TAPS_PER_CELL"
    puts "Generated SDP    : $::TT_2ROW_SDP_FILE"
    puts "======================================================================"

    catch {array unset kind}
    catch {array unset pd_cells}
    catch {array unset pools}

    set total [TT_2row_sdp__collect kind pd_cells]
    TT_2row_sdp__diag_mark "C10_AFTER_COLLECT" "total_2row=$total"
    if {$total == 0} {
        puts "INFO: No 2-row LS/ISO cells found."
        return 0
    }

    # CRITICAL: preflight happens BEFORE deleting/creating any SDP WellTap pool.
    set preflight [TT_2row_sdp__preflight_existing_sdp pd_cells]
    TT_2row_sdp__diag_mark "C20_AFTER_PREFLIGHT" "preflight=$preflight"

    if {$preflight eq "COMPLETE"} {
        puts "INFO: All $total 2-row LS/ISO cells already belong to SDP2R_* groups."

        # Classify the known V6.6 recovery state BEFORE the normal validator so
        # an all-taps-missing rerun does not print 468 redundant MISSING TAP
        # lines.  Zero WellTap-master instances + zero SDPWT-prefix instances is
        # only a candidate; the strict non-mutating repair preflight below must
        # still prove expected CELL->SDP ownership and absence of foreign live members.
        set live_tap_master_count [llength [TT_2row_sdp__tap_objects]]
        set live_sdpwt_name_count [llength [TT_2row_sdp__prefix_insts $::TT_2ROW_SDP_WT_PREFIX]]
        TT_2row_sdp__diag_mark "C30_COMPLETE_CLASSIFY" "live_master=$live_tap_master_count live_prefix=$live_sdpwt_name_count"

        if {$live_tap_master_count == 0 && $live_sdpwt_name_count == 0} {
            puts "WARN: COMPLETE SDP membership survived, but all dedicated SDP WellTaps are absent."
            puts "WARN: Entering V6.9 detach-and-reload missing-tap repair preflight."
            TT_2row_sdp__diag_mark "C40_BEFORE_REPAIR_CALL"
            TT_2row_sdp__repair_all_missing_taps pd_cells
            TT_2row_sdp__diag_mark "C41_AFTER_REPAIR_CALL"

            # V7.2: repair_all_missing_taps now performs placement + FIX inside
            # the repair scope itself, before the physical-only tap lifetime can
            # cross the observed cleanup boundary.  Do NOT run placement a second
            # time here.
            puts "INFO: V7.2 repair returned only after repaired SDP members were placed/fixed."
            return $total
        }

        puts "INFO: Verifying the existing flat topology from the generated SDP file."
        TT_2row_sdp__validate_flat_file pd_cells
        TT_2row_sdp__validate_live_flat_rows
        puts "INFO: Existing flat SDP is complete; no WellTap pool was touched."

        # Keep source-and-run placement inside the creator invocation as well.
        # If members are already fixed, TT_flow_place_2row_sdp exits without
        # rerunning placement.
        puts "INFO: V7.0 in-proc handoff: checking/placing existing SDP before creator returns."
        TT_flow_place_2row_sdp
        return $total
    }

    if {$preflight eq "PARTIAL"} {
        error "Existing SDP membership is partial/mixed. Refusing to touch WellTap pools. Restore a clean pre-SDP DB or the previously confirmed complete SDP checkpoint."
    }

    # V7.4 ROOT-CAUSE FIX FROM V7.3 DIAGNOSTIC REPORT:
    #   P20_BEFORE_PLACE_DESIGN : 468 live SDP taps
    #   P21_AFTER_PLACE_DESIGN  :   0 live SDP taps
    # Therefore NEVER run global placement while the dedicated physical-only
    # SDPWT pool exists.  First perform temporary ordinary global placement
    # with zero SDPWT instances and no new SDP topology loaded.  Only after
    # global placement returns do we create/read/place the [WT_L CELL WT_R]
    # groups with place_sdps.
    if {[llength [info commands place_design]] == 0} {
        error "Required Common UI command 'place_design' is unavailable."
    }

    # V2.1 PRE-LS placement constraints.
    #
    # Only the unambiguous Power-Switch keep-outs are created before provisional
    # LS/ISO placement. The old whole-row no-SW PGROW blockage policy is RETIRED:
    # checkerboard SW placement means a 2-row ISO may straddle two SW parities,
    # so a rectangular whole-row custom blockage can incorrectly consume legal
    # space. All user PGROW rules are deferred until native check_sdps is clean.
    puts ""
    puts "======================================================================"
    puts " PRE-LS/ISO PLACEMENT KNOWN-BLOCKAGE PRELOAD"
    puts "======================================================================"
    puts "Policy : only domains with >=1 recognized Power Switch participate in PGROW"
    puts "Order  : SW four-side keep-outs BEFORE temporary LS/ISO place_design; custom PGROW BLKs deferred until native clean"

    set _tt_prels_constraints [TT_SDP_PGROW_prepare_known_blockages]
    puts "SW 4-side HARD keep-outs : [dict get $_tt_prels_constraints swko_count]"
    puts "SW-bearing PG domains    : {[dict get $_tt_prels_constraints domains]}"
    puts "Whole-row PGROW BLKs     : RETIRED (count=[dict get $_tt_prels_constraints no_sw_blk_count])"
    puts "Switch discovery         : shared session cache"
    puts "======================================================================"
    unset _tt_prels_constraints

    # V7.9: arm the existing LS/ISO instance-padding tool BEFORE the temporary
    # global placement.  This is the correct point for the padding to influence
    # the provisional location of the 2-row LS/ISO cells; applying it later,
    # after the SDP members are FIXED, cannot move the group.
    set _tt_ls_iso_pad_file [file join $::TECH_MV_RUNTIME_ROOT .. script PR TECH_MV script 03_place padding proc_ls_iso_padding.tcl]
    if {[file isfile $_tt_ls_iso_pad_file]} {
        source -quiet $_tt_ls_iso_pad_file
        set ::TT_2ROW_LS_ISO_PADDING_RESULT [TT_proc_apply_ls_iso_padding]
        TT_2row_sdp__diag_mark "G05_AFTER_LS_ISO_PADDING" \
            "enabled=[dict get $::TT_2ROW_LS_ISO_PADDING_RESULT enabled] applied=[dict get $::TT_2ROW_LS_ISO_PADDING_RESULT applied] iso=[dict get $::TT_2ROW_LS_ISO_PADDING_RESULT iso]"
    } else {
        puts "WARN: LS/ISO padding tool not found; continuing without V7.9 pre-global padding: $_tt_ls_iso_pad_file"
    }
    unset _tt_ls_iso_pad_file

    set pre_sdp_unplaced [TT_2row_sdp__snapshot_unplaced]
    TT_2row_sdp__diag_mark "G10_BEFORE_GLOBAL_PLACE_NO_TAPS" "snapshot_unplaced=[llength $pre_sdp_unplaced]"
    set pre_master [llength [TT_2row_sdp__tap_objects]]
    set pre_prefix [llength [TT_2row_sdp__prefix_insts $::TT_2ROW_SDP_WT_PREFIX]]
    if {$pre_master != 0 || $pre_prefix != 0} {
        error "V7.4 safety: global placement prepass requires zero dedicated SDP WellTaps, got master=$pre_master prefix=$pre_prefix."
    }
    puts ""
    puts "======================================================================"
    puts " V7.4 TEMPORARY GLOBAL PLACE BEFORE SDP WELLTAP CREATION"
    puts "======================================================================"
    puts "INFO: Running plain place_design while SDPWT count is exactly zero."
    puts "INFO: Dedicated SDP WellTaps will be created only AFTER global placement."
    puts "======================================================================"
    place_design
    TT_2row_sdp__diag_mark "G11_AFTER_GLOBAL_PLACE_NO_TAPS"
    set post_master [llength [TT_2row_sdp__tap_objects]]
    set post_prefix [llength [TT_2row_sdp__prefix_insts $::TT_2ROW_SDP_WT_PREFIX]]
    if {$post_master != 0 || $post_prefix != 0} {
        error "V7.4 unexpected dedicated SDP WellTap(s) appeared during zero-tap global placement: master=$post_master prefix=$post_prefix."
    }

    TT_2row_sdp__build_pools pd_cells pools
    TT_2row_sdp__diag_mark "C50_NEW_CREATE_POOL_CREATED"

    puts ""
    puts "======================================================================"
    puts " GENERATE SDP RELATIVE-PLACEMENT FILE"
    puts "======================================================================"

    set group_count [TT_2row_sdp__write_file kind pd_cells pools]
    puts "INFO: Wrote SDP file: $::TT_2ROW_SDP_FILE"
    puts "INFO: SDP groups in file: $group_count"

    if {![file exists $::TT_2ROW_SDP_FILE]} { error "Generated SDP file does not exist: $::TT_2ROW_SDP_FILE" }

    puts ""
    puts "======================================================================"
    puts " LOAD SDP INTO INNOVUS"
    puts "======================================================================"
    puts "INFO: read_sdp_file $::TT_2ROW_SDP_FILE"

    TT_2row_sdp__diag_mark "C60_BEFORE_NEW_CREATE_READ_SDP"
    if {[catch {read_sdp_file $::TT_2ROW_SDP_FILE} err]} { error "read_sdp_file failed: $err" }
    TT_2row_sdp__diag_mark "C61_AFTER_NEW_CREATE_READ_SDP"

    # Validate exact WT_L / CELL / WT_R names from the generated SDP file.
    # Do not require physical-only WellTap .sdp back-references.
    TT_2row_sdp__validate_flat_file pd_cells
    TT_2row_sdp__diag_mark "C62_AFTER_NEW_CREATE_VALIDATION"

    if {$::TT_2ROW_SDP_RUN_CHECK && [llength [info commands check_sdps]] > 0} {
        puts "INFO: check_sdps"
        check_sdps -out_file [tech_mv_native_sdp_report_path]
    }

    puts ""
    puts "======================================================================"
    puts " 2-ROW SDP CREATION COMPLETE"
    puts "======================================================================"
    puts "2-row LS/ISO discovered : $total"
    puts "SDP groups loaded       : $group_count"
    puts "WellTaps assigned       : [expr {$group_count*2}]"
    puts "SDP file                : $::TT_2ROW_SDP_FILE"
    puts "======================================================================"
    puts "INFO: SDP creation/load completed."
    puts "INFO: V7.2 will perform temporary SDP placement before any unsafe repair/create handoff returns."

    # V7.0/V7.1 ROOT-CAUSE FIX:
    # The generated physical-only WellTaps are confirmed alive immediately after
    # read_sdp_file, but Innovus 21.19 can discard them when this creator proc
    # returns while they are only PLACED.  Therefore placement + final FIX must
    # happen here, before returning to the caller/top-level Tcl command loop.
    set live_master_before_handoff [llength [TT_2row_sdp__tap_objects]]
    set live_prefix_before_handoff [llength [TT_2row_sdp__prefix_insts $::TT_2ROW_SDP_WT_PREFIX]]
    puts "INFO: V7.2 pre-handoff live WellTap master count = $live_master_before_handoff"
    puts "INFO: V7.2 pre-handoff live SDPWT prefix count    = $live_prefix_before_handoff"
    if {$live_master_before_handoff == 0 || $live_prefix_before_handoff == 0} {
        error "V7.2 refuses placement handoff because dedicated SDP WellTaps disappeared before placement started."
    }

    TT_2row_sdp__diag_mark "C70_BEFORE_NEW_CREATE_PLACE_FLOW"
    TT_flow_place_2row_sdp $pre_sdp_unplaced
    TT_2row_sdp__diag_mark "C71_AFTER_NEW_CREATE_PLACE_FLOW"

    return $group_count
}


# -----------------------------------------------------------------------------
# V7.6: Set an explicit lower-left origin for every flat SDP row.
#
# The temporary global placement gives the middle 2-row CELL a legal provisional
# location.  The flat SDP structure is [WT_L][CELL][WT_R], so the lower-left of
# the entire row is one WellTap width to the left of the CELL location.
# -----------------------------------------------------------------------------
# Normalize a Common UI point value into a flat {x y} Tcl list.
# Innovus 21.19 may expose .location as either {x y} or {{x y}} depending
# on the DB object/value representation.  Accept both without changing the
# underlying coordinate values.
proc TT_2row_sdp__normalize_xy_point {raw} {
    set work $raw
    for {set depth 0} {$depth < 4} {incr depth} {
        if {[catch {set n [llength $work]}]} {
            return {}
        }

        if {$n == 2} {
            set x [lindex $work 0]
            set y [lindex $work 1]
            if {[string is double -strict $x] && [string is double -strict $y]} {
                return [list $x $y]
            }
            return {}
        }

        if {$n != 1} {
            return {}
        }

        set next [lindex $work 0]
        if {$next eq $work} {
            return {}
        }
        set work $next
    }
    return {}
}

proc TT_2row_sdp__set_flat_origins_from_cells {} {
    if {[llength [info commands set_sdp_origin]] == 0} {
        error "Required Common UI command 'set_sdp_origin' is unavailable."
    }

    set records [TT_2row_sdp__flat_group_records]
    if {[llength $records] == 0} {
        error "Cannot set SDP origins: no flat SDP groups were parsed from '$::TT_2ROW_SDP_FILE'."
    }

    lassign [TT_2row_sdp__tap_geometry] tap_w tap_h
    if {$tap_w <= 0.0} {
        error "Cannot set SDP origins: invalid WellTap width '$tap_w'."
    }

    catch {array unset inst_exact}
    catch {array unset inst_leaf}
    TT_2row_sdp__build_inst_lookup inst_exact inst_leaf

    set count 0
    foreach rec $records {
        lassign $rec group wt_l_name cell_name wt_r_name
        set cell [TT_2row_sdp__resolve_inst $cell_name inst_exact inst_leaf]
        if {$cell eq ""} {
            error "Cannot set SDP origin for '$group': middle CELL '$cell_name' is missing."
        }

        set loc_raw {}
        catch {set loc_raw [get_db $cell .location]}
        set loc [TT_2row_sdp__normalize_xy_point $loc_raw]
        if {[llength $loc] != 2} {
            error "Cannot set SDP origin for '$group': CELL '$cell_name' has invalid location '$loc_raw'."
        }
        lassign $loc cell_x cell_y

        set origin_x [expr {double($cell_x) - double($tap_w)}]
        set origin_y [expr {double($cell_y)}]
        set row_name "${group}_ROW"

        set_sdp_origin -sdp $row_name -location $origin_x $origin_y
        incr count

        if {$count <= 8} {
            puts [format "SDP ORIGIN %-18s CELL=%-48s cell={%.3f %.3f} origin={%.3f %.3f}" \
                $row_name $cell_name $cell_x $cell_y $origin_x $origin_y]
        }
    }

    puts "INFO: V7.6 set explicit lower-left origin for $count SDP row group(s)."
    puts "INFO: Origin formula: CELL.x - WellTap.width, CELL.y (WellTap width=$tap_w)."
    TT_2row_sdp__diag_mark "O11_AFTER_SET_SDP_ORIGINS" "groups=$count tap_width=$tap_w"
    return $count
}

proc TT_2row_sdp__configure_2g_legalizer {} {
    TT_2row_sdp__diag_mark "L10_BEFORE_2G_CONFIG"
    set_db place_sdp_flow 2G
    set_db place_sdp_legalization SW
    set_db place_sdp_legalization_effort high
    set_db place_sdp_pre_fixed_cells_blockage_direction Y

    # V7.9: do not force the temporary-global-placement origin.  The origin is
    # only a starting point; the legalizer must be free to move the SDP group.
    if {[catch {set_db place_sdp_honor_user_assign_origin $::TT_2ROW_SDP_HONOR_USER_ASSIGN_ORIGIN} err]} {
        puts "WARN: Cannot set place_sdp_honor_user_assign_origin=$::TT_2ROW_SDP_HONOR_USER_ASSIGN_ORIGIN: $err"
    }

    # V7.9: prevent different SDP bounding boxes from interleaving.  This is
    # specifically intended to avoid post-detail overlap between adjacent
    # [WT_L][CELL][WT_R] groups.
    if {$::TT_2ROW_SDP_ENFORCE_NO_INTERLEAVING} {
        if {[catch {set_db place_sdp_enforce_no_interleaving_sdp true} err]} {
            puts "WARN: place_sdp_enforce_no_interleaving_sdp is unavailable in this Innovus build: $err"
        } else {
            puts "INFO: V7.9 no-interleaving-SDP enforcement = true"
        }
    }

    lassign [TT_2row_sdp__padding_geometry] pad_x pad_y
    TT_2row_sdp__diag_mark "L11_AFTER_2G_CONFIG" \
        "flow=2G legalization=SW effort=high pre_fixed_blockage=Y honor_origin=$::TT_2ROW_SDP_HONOR_USER_ASSIGN_ORIGIN no_interleaving=$::TT_2ROW_SDP_ENFORCE_NO_INTERLEAVING padding_um=${pad_x}x${pad_y}"
    puts "INFO: V7.9 SDP 2G legalizer configured: flow=2G legalization=SW effort=high pre-fixed-blockage=Y honor-origin=$::TT_2ROW_SDP_HONOR_USER_ASSIGN_ORIGIN no-interleaving=$::TT_2ROW_SDP_ENFORCE_NO_INTERLEAVING padding=${pad_x}x${pad_y}um"
}


# =============================================================================
# V7.14 finalization helpers
# =============================================================================
proc TT_2row_sdp__switch_padding_sites {} {
    set cfg $::TT_2ROW_SDP_SW_PADDING_SITES
    if {[string equal -nocase $cfg "AUTO"]} {
        lassign [TT_2row_sdp__site_geometry] site_w site_h
        lassign [TT_2row_sdp__tap_geometry] tap_w tap_h
        if {$site_w <= 0.0 || $tap_w <= 0.0} {
            error "V7.14 cannot derive Power-Switch gap from site/tap geometry."
        }
        return [expr {int(ceil(double($tap_w)/double($site_w)))}]
    }
    if {![string is integer -strict $cfg] || $cfg < 0} {
        error "TT_2ROW_SDP_SW_PADDING_SITES must be AUTO or a non-negative integer."
    }
    return $cfg
}

# V1.8: Power Switches are fixed and are never created/deleted by the SDP flow.
# Discover them once per restored Innovus session and share the object list with
# SWKO / PGROW / SW-gap checks.  A new pp_restore/source starts a fresh Tcl
# session state, so stale DB objects are never carried across restored DBs.
if {![info exists ::TT_2ROW_SDP_POWER_SWITCH_CACHE_READY]} {
    set ::TT_2ROW_SDP_POWER_SWITCH_CACHE_READY 0
    set ::TT_2ROW_SDP_POWER_SWITCH_CACHE {}
}

proc TT_2row_sdp__power_switches {{force_refresh 0}} {
    if {!$force_refresh && $::TT_2ROW_SDP_POWER_SWITCH_CACHE_READY} {
        return $::TT_2ROW_SDP_POWER_SWITCH_CACHE
    }

    set out {}
    foreach inst [get_db insts] {
        set name ""
        set master ""
        catch {set name [get_db $inst .name]}
        catch {set master [get_db $inst .base_cell.name]}
        if {$name eq "" || $master eq ""} { continue }
        if {![string match "PD_CPU_SW*" $name] && ![string match "PD_WDT_SW*" $name]} { continue }
        if {![string match [::tech_mv_library_value LIB_MATCH_001] $master]} { continue }
        lappend out $inst
    }

    set ::TT_2ROW_SDP_POWER_SWITCH_CACHE $out
    set ::TT_2ROW_SDP_POWER_SWITCH_CACHE_READY 1
    puts "INFO: V1.8 shared Power-Switch cache populated once: [llength $out] switch(es)."
    return $out
}

proc TT_2row_sdp__apply_power_switch_padding {} {
    set sites [TT_2row_sdp__switch_padding_sites]
    if {$sites <= 0} {
        puts "INFO: V7.14 Power-Switch spacing padding disabled."
        return 0
    }
    if {[llength [info commands set_inst_padding]] == 0} {
        error "V7.14 requires set_inst_padding for Power-Switch spacing."
    }
    lassign [TT_2row_sdp__site_geometry] site_w site_h
    set gap [expr {double($site_w)*$sites}]
    set switches [TT_2row_sdp__power_switches]
    foreach inst $switches {
        set name [get_db $inst .name]
        set_inst_padding -inst $name -left_side $sites -right_side $sites
    }
    puts "INFO: V7.14 Power-Switch padding applied: [llength $switches] switch(es), L/R=$sites site(s) (${gap}um >= one TAPCELL width in AUTO mode)."
    return [llength $switches]
}

proc TT_2row_sdp__clear_power_switch_padding {} {
    # Innovus 21.19 rejects zero-valued set_inst_padding arguments.
    # Clear only the temporary L/R switch padding with positional
    # delete_inst_padding <inst>, then restore any positive top/bottom padding.
    if {[llength [info commands delete_inst_padding]] == 0} {
        error "V7.14 requires delete_inst_padding to clear temporary Power-Switch padding safely."
    }

    set sites [TT_2row_sdp__switch_padding_sites]
    set switches [TT_2row_sdp__power_switches]
    set cleared 0
    set already_clear 0

    foreach inst $switches {
        set name [get_db $inst .name]

        foreach {var attr} {
            left   .left_padding
            right  .right_padding
            top    .top_padding
            bottom .bottom_padding
        } {
            set $var 0
            catch {set $var [get_db $inst $attr]}
            if {[set $var] eq ""} { set $var 0 }
            if {![string is integer -strict [set $var]] || [set $var] < 0} {
                error "V7.14 invalid live padding on Power Switch '$name': $var=[set $var]."
            }
        }

        if {$left == 0 && $right == 0} {
            incr already_clear
            continue
        }

        # This cleanup owns only the temporary L/R padding applied by this flow.
        # Refuse to guess if the live L/R state is not the expected temporary value.
        if {$left != $sites || $right != $sites} {
            error "V7.14 refuses to clear unexpected Power-Switch padding on '$name': live L/R=$left/$right expected temporary=$sites/$sites."
        }

        if {[catch {delete_inst_padding $name} derr]} {
            error "V7.14 delete_inst_padding failed for Power Switch '$name': $derr"
        }

        # Preserve any pre-existing positive vertical padding. Never pass zero.
        set cmd [list set_inst_padding -inst $name]
        set positive 0
        if {$top > 0} {
            lappend cmd -top_side $top
            incr positive
        }
        if {$bottom > 0} {
            lappend cmd -bottom_side $bottom
            incr positive
        }
        if {$positive > 0} {
            if {[catch {uplevel #0 $cmd} serr]} {
                error "V7.14 failed to restore positive vertical padding on '$name': $serr"
            }
        }

        set left_after 0
        set right_after 0
        set top_after 0
        set bottom_after 0
        catch {set left_after [get_db $inst .left_padding]}
        catch {set right_after [get_db $inst .right_padding]}
        catch {set top_after [get_db $inst .top_padding]}
        catch {set bottom_after [get_db $inst .bottom_padding]}
        foreach v {left_after right_after top_after bottom_after} {
            if {[set $v] eq ""} { set $v 0 }
        }
        if {$left_after != 0 || $right_after != 0 ||
            $top_after != $top || $bottom_after != $bottom} {
            error "V7.14 Power-Switch padding cleanup verify failed for '$name': after L/R/T/B=$left_after/$right_after/$top_after/$bottom_after expected 0/0/$top/$bottom."
        }
        incr cleared
    }

    puts "INFO: V7.14 temporary Power-Switch L/R padding cleared safely: cleared=$cleared already_clear=$already_clear; zero-valued set_inst_padding was not used."
    return $cleared
}

proc TT_2row_sdp__check_sdps_total {} {
    if {[llength [info commands check_sdps]] == 0} {
        error "V7.14 requires check_sdps."
    }
    check_sdps -out_file [tech_mv_native_sdp_report_path]
    set design "CHIP"
    catch {set design [get_db current_design .name]}
    if {$design eq ""} { set design "CHIP" }
    set rpt [tech_mv_output_path report "${design}.checkSdp.rpt" 02 sdp]
    if {![file isfile $rpt]} {
        error "V7.14 cannot find check_sdps report '$rpt'."
    }
    set fp [open $rpt r]
    set total -1
    set detail [dict create]
    while {[gets $fp line] >= 0} {
        if {[regexp {^([A-Za-z]+(?:[A-Za-z]+)?) violations:[ \t]*([0-9]+)} $line -> key val]} {
            dict set detail $key $val
        }
        if {[regexp {^Total violations:[ \t]*([0-9]+)} $line -> val]} {
            set total $val
        }
    }
    close $fp
    if {$total < 0} {
        error "V7.14 could not parse Total violations from '$rpt'."
    }
    puts "INFO: V7.14 check_sdps total violations = $total"
    return $total
}

proc TT_2row_sdp__same_point {a b {tol 0.0005}} {
    if {[llength $a] != 2 || [llength $b] != 2} { return false }
    return [expr {abs(double([lindex $a 0])-double([lindex $b 0])) <= $tol && \
                  abs(double([lindex $a 1])-double([lindex $b 1])) <= $tol}]
}

proc TT_2row_sdp__detach_side_taps_keep_cell_sdp {} {
    # R9.6 late-flow rollback:
    # PRE-FINALIZE check_sdps has already proven the canonical 3-member SDP
    # topology legal.  Do NOT detach either side WellTap.  Innovus 21.19 can
    # perturb the remaining SDP geometry when a member is detached, which turns
    # a clean [WT_L][CELL][WT_R] row into overlap/place-legality violations.
    #
    # Keep this legacy proc name only for call-site compatibility; its behavior
    # is now read-only verification of the already-legalized full triplet.
    set records [TT_2row_sdp__flat_group_records]
    catch {array unset inst_exact}
    catch {array unset inst_leaf}
    TT_2row_sdp__build_inst_lookup inst_exact inst_leaf

    set groups 0
    set taps 0
    foreach rec $records {
        lassign $rec group wt_l_name cell_name wt_r_name
        set cell [TT_2row_sdp__resolve_inst $cell_name inst_exact inst_leaf]
        set wt_l [TT_2row_sdp__resolve_inst $wt_l_name inst_exact inst_leaf]
        set wt_r [TT_2row_sdp__resolve_inst $wt_r_name inst_exact inst_leaf]
        if {$cell eq "" || $wt_l eq "" || $wt_r eq ""} {
            error "V7.14 finalization unresolved member: group=$group."
        }

        set expected "${group}_ROW"
        foreach member [list $wt_l $cell $wt_r] {
            set member_name [TT_2row_sdp__name $member]
            set member_row ""
            catch {set member_row [get_db $member .sdp.name]}
            if {$member_row ne $expected} {
                error "V7.14 canonical member '$member_name' SDP='$member_row', expected='$expected'; refusing late-flow mutation."
            }
            set st ""
            catch {set st [get_db $member .place_status]}
            if {$st ne "fixed"} {
                error "V7.14 canonical member '$member_name' status='$st', expected='fixed'; refusing late-flow mutation."
            }
        }
        incr groups
        incr taps 2
    }

    puts ""
    puts "======================================================================"
    puts " V7.14 KEEP-SDP FINALIZATION - FULL TRIPLET PRESERVED"
    puts "======================================================================"
    puts "SDP 3-member groups retained : $groups"
    puts "Side SDP WellTaps retained   : $taps"
    puts "Physical movement            : NONE"
    puts "SDP detach                   : NONE"
    puts {Policy                       : preserve legal [WT_L][CELL][WT_R] exactly}
    puts "======================================================================"
    return [dict create groups $groups detached_taps 0 retained_taps $taps]
}

proc TT_2row_sdp__rect4 {obj} {
    return [TT_2row_sdp__bbox4 [get_db $obj .bbox]]
}

proc TT_2row_sdp__rect_overlap {a b} {
    if {[llength $a] != 4 || [llength $b] != 4} { return false }
    lassign $a ax1 ay1 ax2 ay2
    lassign $b bx1 by1 bx2 by2
    return [expr {$ax1 < $bx2 && $ax2 > $bx1 && $ay1 < $by2 && $ay2 > $by1}]
}

# Per-member horizontal clearance. Numerical tolerance is scaled machine
# precision, not a technology length or a configurable clearance relaxation.
proc TT_2row_sdp__member_switch_gap_hit {member switch gap} {
    if {[llength $member] != 4 || [llength $switch] != 4} {return false}
    lassign $member x1 y1 x2 y2
    lassign $switch sx1 sy1 sx2 sy2
    if {$y1 >= $sy2 || $y2 <= $sy1} {return false}
    set separation [expr {max(double($x1)-$sx2, double($sx1)-$x2)}]
    set scale [expr {max(1.0,abs($x1),abs($x2),abs($sx1),abs($sx2),abs($gap))}]
    set roundoff [expr {16.0 * 2.220446049250313e-16 * $scale}]
    return [expr {$separation < double($gap)-$roundoff}]
}

proc TT_2row_sdp__scan_switch_gap {{verbose true}} {
    set sites [TT_2row_sdp__switch_padding_sites]
    if {$sites <= 0} {
        return [dict create violations 0 groups {} switches 0 required_gap 0.0]
    }
    lassign [TT_2row_sdp__site_geometry] site_w site_h
    set gap [expr {double($site_w) * $sites}]
    set switches [TT_2row_sdp__power_switches]

    set records [TT_2row_sdp__flat_group_records]
    catch {array unset inst_exact}
    catch {array unset inst_leaf}
    TT_2row_sdp__build_inst_lookup inst_exact inst_leaf
    set vio 0
    set groups {}
    foreach rec $records {
        lassign $rec group wt_l_name cell_name wt_r_name
        set wt_l [TT_2row_sdp__resolve_inst $wt_l_name inst_exact inst_leaf]
        set cell [TT_2row_sdp__resolve_inst $cell_name inst_exact inst_leaf]
        set wt_r [TT_2row_sdp__resolve_inst $wt_r_name inst_exact inst_leaf]
        if {$wt_l eq "" || $cell eq "" || $wt_r eq ""} { continue }
        set lb [TT_2row_sdp__rect4 $wt_l]
        set cb [TT_2row_sdp__rect4 $cell]
        set rb [TT_2row_sdp__rect4 $wt_r]
        if {[llength $lb] != 4 || [llength $cb] != 4 || [llength $rb] != 4} { continue }
        set group_hit false
        foreach sw $switches {
            set sb [TT_2row_sdp__rect4 $sw]
            if {[TT_2row_sdp__member_switch_gap_hit $cb $sb $gap]} {
                incr vio
                set group_hit true
                if {$verbose && $vio <= 20} {
                    puts "WARN: V7.17 SW-GAP violation group=$group cell=$cell_name switch=[get_db $sw .name] required_gap=${gap}um"
                }
            }
        }
        if {$group_hit && [lsearch -exact $groups $group] < 0} {
            lappend groups $group
        }
    }
    set groups [lsort -unique $groups]
    if {$verbose} {
        puts "INFO: V7.17 switch-gap validation: switches=[llength $switches] violations=$vio groups=[llength $groups] required_gap=${gap}um"
        if {$vio > 20} {
            puts "INFO: V7.17 switch-gap console detail capped at first 20 pair violations; all violating group names remain available to the repair flow."
        }
    }
    set ::TT_2ROW_SDP_LAST_SW_GAP_GROUPS $groups
    set ::TT_2ROW_SDP_LAST_SW_GAP_VIOLATIONS $vio
    return [dict create violations $vio groups $groups switches [llength $switches] required_gap $gap]
}

proc TT_2row_sdp__validate_switch_gap {} {
    set result [TT_2row_sdp__scan_switch_gap true]
    return [dict get $result violations]
}

proc TT_2row_sdp__set_selected_group_status {groups status} {
    set records [TT_2row_sdp__flat_group_records]
    catch {array unset wanted}
    foreach g $groups { set wanted($g) 1 }
    catch {array unset inst_exact}
    catch {array unset inst_leaf}
    TT_2row_sdp__build_inst_lookup inst_exact inst_leaf
    set changed 0
    foreach rec $records {
        lassign $rec group wt_l_name cell_name wt_r_name
        if {![info exists wanted($group)]} { continue }
        foreach n [list $wt_l_name $cell_name $wt_r_name] {
            set obj [TT_2row_sdp__resolve_inst $n inst_exact inst_leaf]
            if {$obj eq ""} {
                error "V7.17 cannot resolve canonical member '$n' while changing status for '$group'."
            }
            if {$status ne "fixed"} {
                set row ""
                catch {set row [get_db $obj .sdp.name]}
                if {$row ne "${group}_ROW"} {
                    error "V7.17 switch-gap refine requires full SDP membership: '$n' SDP='$row', expected='${group}_ROW'."
                }
            }
            set_db $obj .place_status $status
            incr changed
        }
    }
    return $changed
}

proc TT_refine_switch_gap_sdps {{max_iter 3}} {
    if {![string is integer -strict $max_iter] || $max_iter < 1} {
        error "TT_refine_switch_gap_sdps max_iter must be an integer >= 1."
    }
    if {[llength [info commands place_sdps]] == 0} {
        error "place_sdps is unavailable."
    }

    set pass 0
    set final_native "__UNCHANGED__"
    set initial [TT_2row_sdp__scan_switch_gap true]
    set result $initial
    while {[dict get $result violations] != 0 && $pass < $max_iter} {
        incr pass
        set groups [dict get $result groups]
        if {[info exists ::TT_2ROW_SDP_PRE_UNPLACED_SNAPSHOT]} {
            TT_2row_sdp__prepare_background_for_repair $::TT_2ROW_SDP_PRE_UNPLACED_SNAPSHOT "SW_GAP_REFINE_PASS_$pass"
        } else {
            TT_2row_sdp__force_noncanonical_lp_unplaced "SW_GAP_REFINE_PASS_$pass"
        }
        TT_2row_sdp__set_flat_members_fixed
        TT_2row_sdp__assert_flat_members_fixed
        set released [TT_2row_sdp__set_selected_group_status $groups placed]
        puts "INFO: V7.17 SW-gap refine pass $pass/$max_iter: released $released canonical member(s) from [llength $groups] SDP group(s)."
        place_sdps
        TT_2row_sdp__set_flat_members_fixed
        TT_2row_sdp__assert_flat_members_fixed
        set _native [TT_2row_sdp__check_sdps_total]
        set final_native $_native
        set result [TT_2row_sdp__scan_switch_gap true]
        puts "INFO: V7.17 SW-gap refine pass $pass result: gap_violations=[dict get $result violations] gap_groups=[llength [dict get $result groups]] check_sdps=$_native."
        unset _native
    }
    TT_2row_sdp__set_flat_members_fixed
    TT_2row_sdp__assert_flat_members_fixed
    return [dict create \
        initial_violations [dict get $initial violations] \
        final_violations [dict get $result violations] \
        final_groups [dict get $result groups] \
        passes $pass \
        final_native $final_native]
}

# V7.20: place_sdps does not reliably honor set_inst_padding around fixed
# Power Switches.  Use HARD LEFT/RIGHT placement keep-outs for EVERY switch,
# and keep the complete set persistent across all refine/suspend passes.
set _tt_swko_helper [file join $::TECH_MV_SDP_TOOL_SOURCE_DIR TT_repair_switch_gap_hard_keepout.tcl]
if {![file isfile $_tt_swko_helper]} {
    error "V7.20 required switch-gap persistent all-switch keepout helper is missing: $_tt_swko_helper"
}
source -quiet $_tt_swko_helper
unset _tt_swko_helper

# ADDITIVE Power-Gated row-rule helper. Definition-only at source time.
# It does not replace native SDP/SW-gap checks or their repair ordering.
set _tt_pgrow_helper [file join $::TECH_MV_SDP_TOOL_SOURCE_DIR TT_sdp_powergate_row_rules.tcl]
if {![file isfile $_tt_pgrow_helper]} {
    error "Required additive Power-Gated SDP row-rule helper is missing: $_tt_pgrow_helper"
}
source -quiet $_tt_pgrow_helper
unset _tt_pgrow_helper


# PR7 observational/targeted internal-geometry helper.  This does NOT replace
# any existing native SDP or Power-Switch repair/check stage; it runs only at
# an already-triggered operator checkpoint, immediately before suspend.
set _tt_pr7_internal_helper [file join $::TECH_MV_SDP_TOOL_SOURCE_DIR TT_refine_internal_gap_sdps.tcl]
if {![file isfile $_tt_pr7_internal_helper]} {
    error "Required PR7 checkpoint helper is missing: $_tt_pr7_internal_helper"
}
source -quiet $_tt_pr7_internal_helper
unset _tt_pr7_internal_helper

proc TT_2row_sdp__suspend_until_switch_gap_clean {phase {allow_refine true}} {
    set result [TT_2row_sdp__scan_switch_gap false]
    set vio [dict get $result violations]
    set groups [dict get $result groups]
    if {$vio == 0} {
        set _native_now [TT_2row_sdp__check_sdps_total]
        if {$_native_now == 0 && [llength [info commands TT_SWKO_finalize_if_clean]] > 0} {
            TT_SWKO_finalize_if_clean
        }
        unset _native_now
        puts "PASS: $phase Power-Switch / SDP spacing is clean."
        return 0
    }

    if {$allow_refine && [llength [info commands TT_SWKO_ensure_all_switch_keepouts]] > 0} {
        TT_SWKO_ensure_all_switch_keepouts [dict get $result required_gap]
    }
    TT_2row_sdp__set_flat_members_fixed
    TT_2row_sdp__assert_flat_members_fixed

    set _pr7_result [TT_PR7_pre_checkpoint $phase $allow_refine]
    set result [TT_2row_sdp__scan_switch_gap false]
    set vio [dict get $result violations]
    set groups [dict get $result groups]
    set _pr7_vio [dict get $_pr7_result violations]

    puts ""
    puts "======================================================================"
    puts " SDP CHECKPOINT"
    puts "======================================================================"
    puts "Phase     : $phase"
    puts "Tags      : TOOL=Innovus native rule, CUSTOM=flow/user-defined rule"
    puts [format "%-10s %-28s : %d" {[CUSTOM]} {SW-gap pair violations} $vio]
    puts [format "%-10s %-28s : %d" {[CUSTOM]} {internal SDP violations} $_pr7_vio]
    puts "GUI       : CUSTOM internal-rule cells are highlighted RED when present"
    if {$allow_refine} {
        if {$vio > 0} {
            puts "NEXT      : TT_refine_switch_gap_sdps 5"
        }
        if {$_pr7_vio > 0} {
            puts "NEXT      : TT_refine_internal_gap_sdps"
        }
        puts "THEN      : when CUSTOM violations are 0, type resume"
    } else {
        puts "NEXT      : inspect/fix the reported CUSTOM-rule violations, then type resume"
    }
    puts "======================================================================"
    flush stdout
    if {[llength [info commands tech_mv_checkpoint_tools]]} { tech_mv_checkpoint_tools {02_powerplan} {TT_2row_sdp_welltap_after_endcap_v6} }
    suspend

    puts "INFO: Native resume received for SDP / Power-Switch checkpoint '$phase'."
    if {$allow_refine && [info exists ::TT_2ROW_SDP_PRE_UNPLACED_SNAPSHOT]} {
        TT_2row_sdp__prepare_background_for_repair $::TT_2ROW_SDP_PRE_UNPLACED_SNAPSHOT "POST_RESUME_SW_GAP_$phase"
    }
    set result [TT_2row_sdp__scan_switch_gap false]
    set vio [dict get $result violations]
    if {$allow_refine} {
        set _pr7_after [TT_PR7_scan_internal_sdp_structure false false]
        set _pr7_after_vio [dict get $_pr7_after violations]
        unset _pr7_after
    } else {
        TT_PR7__clear_highlight
        set _pr7_after_vio 0
    }
    if {$vio == 0} {
        set _native_now [TT_2row_sdp__check_sdps_total]
        if {$_native_now == 0 && [llength [info commands TT_SWKO_finalize_if_clean]] > 0} {
            TT_SWKO_finalize_if_clean
        }
        unset _native_now
        puts "PASS: $phase SW-gap custom rule is clean after resume."
    } else {
        puts [format {WARN: [CUSTOM] SW-gap violations after resume: %d} $vio]
    }
    if {$_pr7_after_vio != 0} {
        puts [format {WARN: [CUSTOM] internal SDP violations after resume: %d} $_pr7_after_vio]
    }
    unset _pr7_after_vio
    unset _pr7_vio
    unset _pr7_result
    return $vio
}


# Nonzero SDP violations are an operator checkpoint, not a fatal Tcl error.
# The checkpoint is single-shot: PR7 targeted geometry repair/check runs once
# before suspend; resume re-checks once and then continues the source stack.
proc TT_2row_sdp__suspend_until_clean {phase {allow_target_refine true}} {
    set vio [TT_2row_sdp__check_sdps_total]
    if {$vio == 0} {
        puts "PASS: $phase check_sdps is clean."
        return 0
    }

    TT_2row_sdp__set_flat_members_fixed
    TT_2row_sdp__assert_flat_members_fixed

    set _pr7_result [TT_PR7_pre_checkpoint $phase $allow_target_refine]
    set vio [TT_2row_sdp__check_sdps_total]
    set _pr7_vio [dict get $_pr7_result violations]

    puts ""
    puts "======================================================================"
    puts " SDP CHECKPOINT"
    puts "======================================================================"
    puts "Phase     : $phase"
    puts "Tags      : TOOL=Innovus native rule, CUSTOM=flow/user-defined rule"
    puts [format "%-10s %-28s : %d" {[TOOL]} {Innovus check_sdps} $vio]
    puts [format "%-10s %-28s : %d" {[CUSTOM]} {internal SDP violations} $_pr7_vio]
    puts "Report    : ./reports/02_powerplan/sdp/CHIP.checkSdp.rpt"
    puts "GUI       : CUSTOM internal-rule cells are highlighted RED when present"
    if {$allow_target_refine} {
        if {$vio > 0} {
            puts "NEXT      : source run/tool/02_powerplan/TT_refine_violating_sdps.tcl ; TT_refine_violating_sdps -apply -max_iter $::TT_2ROW_SDP_TARGET_REFINE_MAX_ITER"
        }
        if {$_pr7_vio > 0} {
            puts "NEXT      : TT_refine_internal_gap_sdps"
        }
        puts "THEN      : when TOOL/CUSTOM violations are 0, type resume"
    } else {
        puts "NEXT      : inspect ./reports/02_powerplan/sdp/CHIP.checkSdp.rpt and highlighted CUSTOM cells; repair manually, then type resume"
    }
    puts "======================================================================"
    flush stdout
    if {[llength [info commands tech_mv_checkpoint_tools]]} { tech_mv_checkpoint_tools {02_powerplan} {TT_2row_sdp_welltap_after_endcap_v6} }
    suspend

    puts "INFO: Native resume received for SDP checkpoint '$phase'."
    if {$allow_target_refine && [info exists ::TT_2ROW_SDP_PRE_UNPLACED_SNAPSHOT]} {
        TT_2row_sdp__prepare_background_for_repair $::TT_2ROW_SDP_PRE_UNPLACED_SNAPSHOT "POST_RESUME_$phase"
    }
    set vio [TT_2row_sdp__check_sdps_total]
    if {$allow_target_refine} {
        set _pr7_after [TT_PR7_scan_internal_sdp_structure false false]
        set _pr7_after_vio [dict get $_pr7_after violations]
        unset _pr7_after
    } else {
        TT_PR7__clear_highlight
        set _pr7_after_vio 0
    }
    if {$vio == 0} {
        puts "PASS: $phase Innovus native check_sdps is clean after resume."
    } else {
        puts [format {WARN: [TOOL] Innovus check_sdps violations after resume: %d} $vio]
    }
    if {$_pr7_after_vio != 0} {
        puts [format {WARN: [CUSTOM] internal SDP violations after resume: %d} $_pr7_after_vio]
    }
    unset _pr7_after_vio
    unset _pr7_vio
    unset _pr7_result
    return $vio
}


proc TT_flow_place_2row_sdp {{pre_unplaced_override "__AUTO__"}} {
    TT_2row_sdp__diag_mark "P00_PLACE_FLOW_ENTRY"
    foreach cmd {place_sdps set_sdp_origin} {
        if {[llength [info commands $cmd]] == 0} {
            error "Required Common UI command '$cmd' is unavailable."
        }
    }

    catch {array unset kind}
    catch {array unset pd_cells}
    set total [TT_2row_sdp__collect kind pd_cells]
    if {$total == 0} {
        puts "INFO: No 2-row LS/ISO cells found; SDP placement skipped."
        return 0
    }

    TT_2row_sdp__validate_flat_file pd_cells

    if {[TT_2row_sdp__all_flat_members_fixed]} {
        puts "INFO: All canonical SDP physical members are already fixed."
        set v [TT_2row_sdp__check_sdps_total]
        if {$::TT_2ROW_SDP_REQUIRE_ZERO_VIOLATIONS && $v != 0} {
            puts "WARN: Existing SDP is fixed but check_sdps reports $v violation(s); entering native repair suspend."
            set v [TT_2row_sdp__suspend_until_clean "EXISTING FIXED SDP" true]
        }
        set _gap [TT_2row_sdp__validate_switch_gap]
        if {$_gap != 0} {
            set _gap [TT_2row_sdp__suspend_until_switch_gap_clean "EXISTING FIXED SDP" true]
        }
        unset _gap
        return $total
    }

    if {$pre_unplaced_override eq "__AUTO__"} {
        set pre_unplaced [TT_2row_sdp__snapshot_unplaced]
    } else {
        set pre_unplaced $pre_unplaced_override
    }

    # Power switches are already fixed before this flow.  Give them explicit
    # horizontal placement padding BEFORE place_sdps so a 2-row SDP group cannot
    # abut a switch column.
    TT_2row_sdp__apply_power_switch_padding

    set ::TT_2ROW_SDP_PRE_UNPLACED_SNAPSHOT $pre_unplaced

    set live_before_sdps [llength [TT_2row_sdp__tap_objects]]
    if {$live_before_sdps == 0} {
        error "V7.18 refuses place_sdps because no dedicated SDP WellTaps are live."
    }

    puts "INFO: Stage 1/8 - temporary global placement already completed; capture canonical SDP origins"
    set origin_count [TT_2row_sdp__set_flat_origins_from_cells]
    if {$origin_count != $total} {
        error "V7.18 SDP origin count mismatch: set=$origin_count expected=$total."
    }

    # Critical V7.18 policy: ordinary cells were temporarily placed only to give
    # the 2-row centers provisional coordinates.  Remove that background BEFORE
    # the first place_sdps so it cannot obstruct legalization/refine.
    puts "INFO: Stage 1B/8 - UNPLACE temporary NON-SDP background before SDP legalization"
    TT_2row_sdp__prepare_background_for_repair $pre_unplaced "PRE_PLACE_SDPS"

    puts "INFO: Stage 1C/8 - PRE-PLACE native-first constraint gate: SW keep-outs only"
    set _tt_preplace_constraints [TT_SDP_PGROW_prepare_pre_place_constraints]
    puts "INFO: PRE-PLACE SWKO live            = [dict get $_tt_preplace_constraints swko_count]"
    puts "INFO: PRE-PLACE whole-row PGROW BLKs = RETIRED"
    puts "INFO: PRE-PLACE PGROW reservations   = DEFERRED until native check_sdps=0"
    puts "INFO: stale custom BLKs deleted      = [dict get $_tt_preplace_constraints stale_custom_deleted]"
    unset _tt_preplace_constraints

    puts "INFO: Stage 2/8 - place_sdps with 2G/high/SW legalization on cleared background and persistent all-switch keep-outs"
    TT_2row_sdp__configure_2g_legalizer
    place_sdps
    TT_2row_sdp__validate_flat_file pd_cells

    puts "INFO: Stage 3/8 - check SDP violations before FIX (diagnostic only)"
    set vio [TT_2row_sdp__check_sdps_total]
    if {$vio != 0} {
        puts "WARN: check_sdps reports $vio violation(s). V7.15 will FIX first, then selectively unfix/refine only violating SDP groups."
    }

    # Do NOT terminate on Power-Switch spacing before FIX.  The requested policy
    # is FIX-first; gap repair happens only after every canonical SDP member has
    # reached a fixed stage boundary.
    puts {INFO: Stage 4/8 - FIX ALL [WT][CELL][WT] physical topology, even when check_sdps is nonzero}
    TT_2row_sdp__set_flat_members_fixed
    TT_2row_sdp__assert_flat_members_fixed

    puts "INFO: Stage 5/8 - targeted unfix/refine of violating SDP groups"
    TT_2row_sdp__prepare_background_for_repair $pre_unplaced "PRE_NATIVE_SDP_REFINE"
    if {$vio != 0 && [TT_2row_sdp__bool $::TT_2ROW_SDP_AUTO_TARGET_REFINE]} {
        set _tt_refine_tool [file join $::TECH_MV_SDP_TOOL_SOURCE_DIR TT_refine_violating_sdps.tcl]
        if {![file isfile $_tt_refine_tool]} {
            error "V7.15 targeted-refine tool is missing: $_tt_refine_tool. All canonical SDP members remain FIXED."
        }
        source -quiet $_tt_refine_tool
        if {[llength [info commands TT_refine_violating_sdps]] == 0} {
            error "V7.15 targeted-refine tool did not define TT_refine_violating_sdps. All canonical SDP members remain FIXED."
        }
        if {[catch {
            set _tt_refine_result [TT_refine_violating_sdps -apply -max_iter $::TT_2ROW_SDP_TARGET_REFINE_MAX_ITER]
        } _tt_refine_err]} {
            # A report-mapping/legalization failure is recoverable interactively:
            # keep the canonical topology fixed and fall through to native
            # suspend instead of unwinding the Stage-02 Tcl source stack.
            puts "WARN: Automatic targeted refine returned an error: $_tt_refine_err"
            puts "WARN: Canonical SDP members will be re-FIXED and the flow will suspend for operator repair."
            TT_2row_sdp__set_flat_members_fixed
            TT_2row_sdp__assert_flat_members_fixed
            set vio [TT_2row_sdp__check_sdps_total]
            catch {unset _tt_refine_result}
            unset _tt_refine_err
        } else {
            set vio [dict get $_tt_refine_result total_after]
            unset _tt_refine_result
        }
        unset _tt_refine_tool
    } elseif {$vio != 0} {
        puts "WARN: Automatic targeted refine is disabled; $vio violation(s) remain FIXED for manual repair."
        puts "WARN: Manual command: source run/tool/02_powerplan/TT_refine_violating_sdps.tcl ; TT_refine_violating_sdps -apply -max_iter $::TT_2ROW_SDP_TARGET_REFINE_MAX_ITER"
    }

    # Requirement: never leave the canonical SDP topology unfixed at a stage
    # boundary, even when targeted refine cannot converge.
    TT_2row_sdp__set_flat_members_fixed
    TT_2row_sdp__assert_flat_members_fixed
    set _tt_post_refine_vio [TT_2row_sdp__check_sdps_total]
    set vio $_tt_post_refine_vio
    unset _tt_post_refine_vio

    # ------------------------------------------------------------------
    # V2.1 STRICT ORDER:
    #   1) NATIVE check_sdps must be clean first.
    #   2) custom internal GAP-only repair.
    #   3) Power-Switch clearance repair.
    #   4) user's PGROW slot/boundary rule LAST.
    # ------------------------------------------------------------------

    set _tt_custom_allowed true

    puts "INFO: Stage 5A/8 - NATIVE-FIRST gate before any custom repair"
    if {$::TT_2ROW_SDP_REQUIRE_ZERO_VIOLATIONS && $vio != 0} {
        puts "WARN: native check_sdps=$vio; custom GAP/SW-gap/PGROW movement is LOCKED."
        set vio [TT_2row_sdp__suspend_until_clean "PRE-CUSTOM NATIVE SDP VALIDATION" true]
    }
    if {$vio != 0} {
        set _tt_custom_allowed false
        puts "WARN: Native SDP legality is still nonzero after checkpoint: $vio."
        puts "WARN: Skipping ALL automatic custom movement so custom rules cannot hide/worsen native Overlap/PlaceLegality/Interleaving issues."
    }

    # GAP-only custom rule.
    set _tt_gap_only_vio 0
    if {$_tt_custom_allowed} {
        puts "INFO: Stage 5B/8 - GAP-ONLY custom repair after native check_sdps=0"
        TT_2row_sdp__prepare_background_for_repair $pre_unplaced "PRE_GAP_ONLY_REFINE"
        set _tt_gap_only_result [TT_refine_internal_gap_sdps]
        set _tt_gap_only_vio [dict get $_tt_gap_only_result violations]
        unset _tt_gap_only_result

        # GAP repair moves/re-anchors cells; native legality must be re-proven.
        set vio [TT_2row_sdp__check_sdps_total]
        if {$::TT_2ROW_SDP_REQUIRE_ZERO_VIOLATIONS && $vio != 0} {
            puts "WARN: GAP-only repair introduced/left native check_sdps=$vio; custom pipeline stops here."
            set vio [TT_2row_sdp__suspend_until_clean "POST-GAP NATIVE SDP VALIDATION" true]
        }
        if {$vio != 0} {
            set _tt_custom_allowed false
            puts "WARN: native check_sdps remains $vio; SW-gap and PGROW auto movement are skipped."
        }
    } else {
        puts "INFO: Stage 5B/8 - SKIP GAP-only custom repair because native gate is not clean."
    }

    # Existing Power-Switch clearance rule next.
    set _tt_gap_vio 0
    if {$_tt_custom_allowed} {
        puts "INFO: Stage 5C/8 - targeted Power-Switch gap refine after native+GAP clean"
        TT_2row_sdp__prepare_background_for_repair $pre_unplaced "PRE_SW_GAP_REFINE"
        set _tt_gap_result [TT_refine_switch_gap_sdps $::TT_2ROW_SDP_TARGET_REFINE_MAX_ITER]
        set _tt_gap_vio [dict get $_tt_gap_result final_violations]
        set _tt_gap_passes [dict get $_tt_gap_result passes]

        # V2.1.2 runtime contract compatibility:
        # TT_repair_switch_gap_hard_keepout.tcl overrides
        # TT_refine_switch_gap_sdps and returns final_check_sdps.
        # The local/main implementation returns final_native.
        # Accept either contract; do NOT change SWKO lifecycle.
        if {[dict exists $_tt_gap_result final_native]} {
            set _tt_gap_native [dict get $_tt_gap_result final_native]
        } elseif {[dict exists $_tt_gap_result final_check_sdps]} {
            set _tt_gap_native [dict get $_tt_gap_result final_check_sdps]
        } else {
            error "TT_refine_switch_gap_sdps result missing both final_native and final_check_sdps: $_tt_gap_result"
        }

        if {$_tt_gap_passes > 0 && $_tt_gap_native ne "__UNCHANGED__"} {
            set vio $_tt_gap_native
            puts "INFO: Stage 5C reuses native result from final SW-gap refine pass: check_sdps=$vio"
        }

        if {$_tt_gap_vio != 0} {
            puts "WARN: Power-Switch spacing still has $_tt_gap_vio pair violation(s)."
            set _tt_gap_vio [TT_2row_sdp__suspend_until_switch_gap_clean "PRE-PGROW SW-GAP VALIDATION" true]
            set vio [TT_2row_sdp__check_sdps_total]
        }

        if {$::TT_2ROW_SDP_REQUIRE_ZERO_VIOLATIONS && $vio != 0} {
            set vio [TT_2row_sdp__suspend_until_clean "POST-SW-GAP NATIVE SDP VALIDATION" true]
        }
        if {$vio != 0} {
            set _tt_custom_allowed false
            puts "WARN: native check_sdps remains $vio after SW-gap stage; PGROW auto movement is skipped."
        }

        unset _tt_gap_result
        unset _tt_gap_passes
        unset _tt_gap_native
    } else {
        puts "INFO: Stage 5C/8 - SKIP SW-gap custom repair because native gate is not clean."
    }

    # User PGROW rule is intentionally LAST.
    if {$_tt_custom_allowed} {
        puts "INFO: Stage 5D/8 - user PGROW direct 2-row boundary rule LAST"
        set _tt_pgrow_last [TT_SDP_PGROW_suspend_until_clean "POST-NATIVE/GAP/SW PGROW RULES" true]

        # PGROW may move cells. Reuse its global native result if available,
        # otherwise perform exactly one native refresh.
        if {[dict exists $_tt_pgrow_last native_total]} {
            set vio [dict get $_tt_pgrow_last native_total]
            puts "INFO: Stage 5D reuses PGISO global native result: check_sdps=$vio"
        } elseif {[dict exists $_tt_pgrow_last repair_rounds] &&
                  [dict get $_tt_pgrow_last repair_rounds] > 0} {
            set vio [TT_2row_sdp__check_sdps_total]
        }

        if {$::TT_2ROW_SDP_REQUIRE_ZERO_VIOLATIONS && $vio != 0} {
            set vio [TT_2row_sdp__suspend_until_clean "POST-PGROW NATIVE SDP VALIDATION" true]
        }
    } else {
        puts "INFO: Stage 5D/8 - SKIP PGROW because native legality was not clean."
        set _tt_pgrow_last [dict create \
            violations 0 checked_iso 0 \
            no_switch_row_groups {} keeper_groups {} mover_groups {} \
            multi_iso_groups {} multi_iso_intervals {} occupied_intervals {} \
            unreserved_intervals {} repair_groups {} domains {} \
            mapping_failure false skipped_due_native true \
            repair_rounds 0 checkpoint_resumed false]
    }

    unset _tt_custom_allowed
    unset _tt_gap_only_vio
    unset _tt_gap_vio

    # PRE-FINALIZE native/custom checks are already clean here. Preserve the
    # full canonical 3-member SDP through every remaining validation. Do NOT
    # detach individual taps: individual detach can perturb legal geometry.
    # Constraint shells are deleted only once, after ALL final validations,
    # with -keep_cell_placement.
    puts {INFO: Stage 6/8 - preserve full [WT_L][CELL][WT_R] SDP through FINAL validation; NO member detach / NO move}
    TT_2row_sdp__detach_side_taps_keep_cell_sdp

    puts "INFO: Stage 7/8 - verify temporary NON-SDP background remains UNPLACED"
    set inst_count_before_restore [TT_2row_sdp__live_inst_count]
    TT_2row_sdp__prepare_background_for_repair $pre_unplaced "POST_SDP_FINALIZE"
    set inst_count_after_restore [TT_2row_sdp__live_inst_count]
    if {$inst_count_after_restore != $inst_count_before_restore} {
        error "V7.18 background verification changed live instance count: before=$inst_count_before_restore after=$inst_count_after_restore."
    }

    puts "INFO: Stage 8/8 - ONE final validation gate (native + SW-gap + conditional PGROW)"
    set _tt_final_geometry_may_have_changed 0

    set final_vio [TT_2row_sdp__check_sdps_total]
    if {$::TT_2ROW_SDP_REQUIRE_ZERO_VIOLATIONS && $final_vio != 0} {
        puts "WARN: V7.16 final SDP validation reports $final_vio violation(s)."
        puts "WARN: Flow will suspend for operator repair instead of terminating."
        set _tt_final_geometry_may_have_changed 1
        set final_vio [TT_2row_sdp__suspend_until_clean "POST-FINALIZE SDP VALIDATION" false]
    }

    set _tt_final_gap_vio [TT_2row_sdp__validate_switch_gap]
    if {$_tt_final_gap_vio != 0} {
        set _tt_final_geometry_may_have_changed 1
        set _tt_final_gap_vio [TT_2row_sdp__suspend_until_switch_gap_clean "POST-FINALIZE SW-GAP VALIDATION" false]
        # A manual gap repair may also change native legality; keep final values authoritative.
        set final_vio [TT_2row_sdp__check_sdps_total]
        set _tt_final_gap_vio [TT_2row_sdp__validate_switch_gap]
    }

    # One final fixed-state assertion, after every possible final checkpoint.
    TT_2row_sdp__assert_flat_members_fixed

    # Stage 6 is read-only and Stage 7 touches only NON-SDP background.  Therefore
    # the last PGROW result remains valid unless a final operator checkpoint may
    # have changed canonical geometry.
    if {$_tt_final_geometry_may_have_changed} {
        puts "INFO: Final PGROW re-check required because a final operator checkpoint occurred."
        set _tt_pgrow_final [TT_SDP_PGROW_suspend_until_clean "POST-FINALIZE PG-ROW VALIDATION" false]
    } else {
        puts "INFO: Final PGROW reuses the last authoritative Stage-5 result; no canonical geometry changed afterward."
        set _tt_pgrow_final $_tt_pgrow_last
    }

    # Final SWKO lifecycle uses the native / SW-gap results we JUST computed;
    # no duplicate global native or switch-gap scan is performed here.
    set _tt_swko_finalized true
    if {[llength [info commands TT_SWKO_finalize_if_clean]] > 0} {
        if {![TT_SWKO_finalize_if_clean $_tt_final_gap_vio $final_vio]} {
            set _tt_swko_finalized false
            puts "WARN: Persistent all-switch HARD keep-outs are still required by an uncleared repair gate; keeping them active and continuing flow by checkpoint policy."
        }
    }

    # User-requested lifetime: the PGROW-R2 no-SW-row BLKs exist only while
    # growing/repairing/checking SDP.  Delete ONLY this helper's owned prefix.
    set _tt_pgrow_cleanup [TT_SDP_PGROW_cleanup]
    if {![dict get $_tt_pgrow_cleanup ok]} {
        error "Final TT_SDP_PGROW cleanup failed; refusing to leave temporary no-SW-row BLKs in the design."
    }

    # V7.21 Stage-02 handoff:
    # All logic that requires live SDP constraints is complete. Innovus write_db
    # reports IMPFP-3763 when a full 3-member SDP crosses a fence/region/guide
    # boundary (center LP cell constrained, physical-only side taps outside).
    # Finalize explicitly instead of letting write_db implicitly dissolve 234
    # groups: delete ONLY SDP constraint shells and preserve member placement.
    puts "INFO: Stage 8F/8 - finalize temporary SDP constraints before Stage-02 write_db handoff"
    set _tt_finalized_sdp_count [TT_2row_sdp__dissolve_flat_constraints_preserve_members]
    if {$_tt_finalized_sdp_count != $total} {
        error "V7.21 final SDP constraint cleanup count mismatch: deleted=$_tt_finalized_sdp_count expected=$total"
    }
    puts "PASS: V7.21 removed $_tt_finalized_sdp_count SDP constraint shell(s); physical members remain FIXED in place."

    if {$::TT_2ROW_SDP_RUN_CHECK_PLACE && [llength [info commands check_place]] > 0} {
        check_place
    }

    # ======================================================================
    # PR10_POST_SDP_ROUTE_CLEANUP_HOOK
    #
    # Policy:
    #   - SDP finalization/check_place is complete before this point.
    #   - Clean REGULAR signal routing before the caller reaches check_drc.
    #   - Use the existing validated cleanup tool; do not duplicate its logic.
    #   - Do not reload/restore the design database.
    # ======================================================================
    puts ""
    puts "======================================================================"
    puts " POST-SDP SIGNAL ROUTE CLEANUP"
    puts "======================================================================"

    set _tt_route_cleanup_tool ""
    if {[info exists ::TOOL_DIR] && $::TOOL_DIR ne ""} {
        set _tt_route_cleanup_tool \
            [file join $::TOOL_DIR 05_route manual_edit TT_delete_signal_routes_only.tcl]
    }

    # Resolve the original classified tool from the captured source directory.
    if {$_tt_route_cleanup_tool eq "" || ![file exists $_tt_route_cleanup_tool]} {
        set _tt_route_cleanup_tool \
            [file normalize [file join $::TECH_MV_SDP_TOOL_SOURCE_DIR .. 05_route manual_edit TT_delete_signal_routes_only.tcl]]
    }

    if {![file exists $_tt_route_cleanup_tool]} {
        error "POST-SDP cleanup tool not found: $_tt_route_cleanup_tool"
    }

    set _tt_cleanup_sdp_before  [llength [get_db top_sdps]]
    set _tt_cleanup_inst_before [llength [get_db insts]]
    set _tt_cleanup_net_before  [llength [get_db nets]]

    puts "INFO: cleanup tool = $_tt_route_cleanup_tool"
    puts "INFO: SDP before   = $_tt_cleanup_sdp_before"
    puts "INFO: INST before  = $_tt_cleanup_inst_before"
    puts "INFO: NET before   = $_tt_cleanup_net_before"

    source $_tt_route_cleanup_tool

    # Support both the newer geometry-based interface and the older tool name.
    if {[llength [info commands TT_SIGROUTE_APPLY]] > 0} {
        puts "INFO: invoking TT_SIGROUTE_APPLY YES"
        set _tt_cleanup_rc [TT_SIGROUTE_APPLY YES]
    } elseif {[llength [info commands TT_ROUTEDEL_APPLY]] > 0} {
        puts "INFO: invoking TT_ROUTEDEL_APPLY YES"
        set _tt_cleanup_rc [TT_ROUTEDEL_APPLY YES]
    } else {
        error "POST-SDP cleanup tool loaded, but no supported APPLY proc exists."
    }

    if {![string is boolean -strict $_tt_cleanup_rc] || !$_tt_cleanup_rc} {
        error "POST-SDP cleanup returned non-PASS result: $_tt_cleanup_rc"
    }

    set _tt_cleanup_sdp_after  [llength [get_db top_sdps]]
    set _tt_cleanup_inst_after [llength [get_db insts]]
    set _tt_cleanup_net_after  [llength [get_db nets]]

    if {$_tt_cleanup_sdp_before != $_tt_cleanup_sdp_after} {
        error "POST-SDP cleanup changed SDP count: $_tt_cleanup_sdp_before -> $_tt_cleanup_sdp_after"
    }
    if {$_tt_cleanup_inst_before != $_tt_cleanup_inst_after} {
        error "POST-SDP cleanup changed instance count: $_tt_cleanup_inst_before -> $_tt_cleanup_inst_after"
    }
    if {$_tt_cleanup_net_before != $_tt_cleanup_net_after} {
        error "POST-SDP cleanup changed net-object count: $_tt_cleanup_net_before -> $_tt_cleanup_net_after"
    }

    puts "INFO: POST-SDP signal route cleanup PASS."
    puts "INFO: SDP/instance/net-object counts unchanged."
    puts "INFO: Flow may now continue to the existing caller-side check_drc."
    puts "======================================================================"

    unset _tt_route_cleanup_tool
    unset _tt_cleanup_rc
    unset _tt_cleanup_sdp_before _tt_cleanup_sdp_after
    unset _tt_cleanup_inst_before _tt_cleanup_inst_after
    unset _tt_cleanup_net_before _tt_cleanup_net_after

    puts ""
    puts "======================================================================"
    puts " 2-ROW SDP CLEAN / KEEP / FIX COMPLETE"
    puts "======================================================================"
    puts "SDP constraint shells    : $_tt_finalized_sdp_count deleted before Stage-02 DB handoff"
    puts "Physical SDP members     : [expr {$total*3}] retained/fixed at validated locations"
    puts "check_sdps violations    : $final_vio"
    puts "Power-Switch gap         : PASS"
    puts "PGROW excess slot groups : [llength [dict get $_tt_pgrow_final multi_iso_groups]]"
    puts "PGROW missing-boundary groups: [llength [dict get $_tt_pgrow_final no_switch_row_groups]]"
    puts "PGROW retired row BLKs   : removed=[dict get $_tt_pgrow_cleanup deleted] remaining=[dict get $_tt_pgrow_cleanup remaining]"
    if {$_tt_swko_finalized} {
        puts "All-SW hard keep-outs    : removed after clean native/SW-gap gates"
    } else {
        puts "All-SW hard keep-outs    : RETAINED (operator resumed with remaining repair gate)"
    }
    puts "Temporary other cells    : restored to pre-SDP UNPLACED state"
    unset _tt_swko_finalized
    unset _tt_pgrow_final
    unset _tt_pgrow_cleanup
    unset _tt_finalized_sdp_count
    puts "======================================================================"
    return $total
}

# =============================================================================
# SOURCE-AND-RUN ENTRY
# =============================================================================
puts ""
puts "INFO: TT_2row_sdp_welltap_after_endcap_v7_18_background_unplace.tcl"
puts "INFO: VERSION = $::TT_2ROW_SDP_VERSION"
puts "INFO: V7.28 Stage-8F deletes one *_ROW at a time and immediately restores/refixes its three members; manual re-source reloads definitions only."
puts "INFO: Intended insertion point: AFTER EndCap insertion."
puts "INFO: Source-and-run mode enabled."

if {$::TT_2ROW_SDP_RELOAD_ONLY_THIS_SOURCE} {
    # Manual/operator re-source in an existing Innovus session.  Reload proc
    # definitions only.  Re-entering TT_proc_create_2row_sdp_welltap here is
    # unsafe because the current DB may already own the canonical 468 SDP taps.
    set ::TT_2ROW_SDP_SOURCE_RUN_RESULT "RELOAD_ONLY"
    puts ""
    puts "======================================================================"
    puts " SDP TOOL DEFINITIONS RELOADED"
    puts "======================================================================"
    puts "Mode      : RELOAD_ONLY (database untouched)"
    puts "Reason    : TT_proc_create_2row_sdp_welltap was already loaded"
    puts "Stage-8F  : TT_SDP_STAGE8F_TEST  (read-only)"
    puts "Auto-run  : SKIPPED intentionally on re-source"
    puts "======================================================================"
} else {
    TT_2row_sdp__diag_init
    TT_2row_sdp__diag_mark "S00_SOURCE_ENTRY"

    # V6.9 SAFETY BARRIER: save the complete Innovus DB before anything in the
    # source-and-run flow can change SDP ownership, WellTap instances, or placement.
    set ::TT_2ROW_SDP_PRE_RUN_CHECKPOINT [TT_2row_sdp__save_pre_run_checkpoint]
    TT_2row_sdp__diag_mark "S01_AFTER_PRE_RUN_CHECKPOINT" "checkpoint=$::TT_2ROW_SDP_PRE_RUN_CHECKPOINT"

    # V7.0/V7.2: TT_proc_create_2row_sdp_welltap performs the source-and-run
    # placement/fix phase internally BEFORE it returns.  Do not split creation and
    # placement into separate top-level Tcl commands; that boundary is the confirmed
    # point at which Innovus 21.19 can garbage-collect the physical-only taps.
    TT_2row_sdp__diag_mark "S10_BEFORE_CREATOR"
    set ::TT_2ROW_SDP_SOURCE_RUN_RESULT [TT_proc_create_2row_sdp_welltap]
    TT_2row_sdp__diag_mark "S11_AFTER_CREATOR" "result=$::TT_2ROW_SDP_SOURCE_RUN_RESULT"
}

puts ""
puts "======================================================================"
puts " SOURCE-AND-RUN 2-ROW SDP FLOW COMPLETE"
puts "======================================================================"
puts "INFO: No manual proc call is required."
puts "INFO: Dedicated SDP WellTaps were never changed to UNPLACED."
puts "INFO: Temporary-placement non-SDP standard cells were restored to UNPLACED before SDP legalization/refine and remain UNPLACED afterward."
puts "======================================================================"
