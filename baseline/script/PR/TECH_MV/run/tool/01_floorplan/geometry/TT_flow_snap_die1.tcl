# Runtime adapter preserves the historical logical source path.
if {[info exists ::TECH_MV_RUNTIME_ROOT]} {
    info script [file join $::TECH_MV_RUNTIME_ROOT run/tool/01_floorplan/geometry/TT_flow_snap_die1.tcl]
}
# PUBLIC_EXPORT_REVIEW_REQUIRED: residual technology candidates require manual review.
# ==============================================================================
# TT_flow_snap_die.tcl
#
# TECH_MV / Innovus Stylus Common UI + legacy floorPlan compatibility
#
# Version : 3.2
#
# PURPOSE
# -------
# Repair DIE/CORE/ROW grid legality while PRESERVING the existing absolute
# floorplan coordinate system.  v3.2 computes the same legal DIE/CORE target
# as v3.1, but APPLY uses the absolute-box legacy floorplan interface:
#
#   floorplan -noResize -noSnapToGrid -b \
#       <DIE llx lly urx ury> \
#       <IO  llx lly urx ury> \
#       <CORE llx lly urx ury>
#
# This avoids the v3.1 failure mode where floorPlan -d re-anchored the DIE at
# (0,0), reconstructed IO-derived geometry, and made existing PD fences appear
# outside the DIE.
#
# IMPORTANT CHANGES FROM v3.1
# ---------------------------
# 1. REMOVE floorPlan -d APPLY path completely.
# 2. Preserve the current DIE lower-left coordinate as a hard invariant.
#    If current DIE LL is not legal on the active DIE grid, APPLY is refused.
# 3. Preserve the current IO bbox exactly.
# 4. Preserve CORE width/height exactly; only phase-shift CORE onto its active
#    grid when the current CORE size is already an exact grid multiple.
# 5. Use absolute DIE/IO/CORE coordinates with -b and -noSnapToGrid because the
#    target coordinates are already calculated to be legal.
# 6. First try -noResize; if this Innovus build rejects that option, retry the
#    same absolute-box command without -noResize.  The absolute boxes are never
#    replaced by width/height/margin mode.
# 7. POST-APPLY hard invariants verify:
#       - DIE LL unchanged
#       - DIE bbox == computed target
#       - CORE bbox == computed target
#       - CORE size unchanged
#       - IO bbox unchanged
#       - DIE/CORE legal on the POST-APPLY active grids
# 8. On APPLY failure or invariant failure, automatically restore the pre-snap
#    DB by default when a backup exists.
# 9. Automatic backups remain under <project_root>/backup/snap_die/.
#
# INTENTIONAL NON-GOALS
# ---------------------
# This tool intentionally DOES NOT use:
#   snap_floorplan
#   resize_floorplan
#
# It DOES NOT:
#   - modify floorplan_snap_*_grid attributes
#   - touch WellTap code
#   - source/read any IO file
#   - move/reshape PD constraints
#   - repair individual IO pads / macros / standard cells
#
# APPLY is intended for Stage01 / early floorplan use. Absolute floorplan -b
# can recreate rows; post-APPLY hard invariants guard the DIE/IO/CORE geometry.
#
# CURRENT TECH_MV EXPECTED GRID POLICY
# ------------------------------------
#   DIE        -> finfet_placement
#   CORE       -> finfet_placement
#   IO         -> finfet_manufacturing
#   CONSTRAINT -> finfet_inst
#
# USAGE
# -----
#   source run/tool/01_floorplan/geometry/TT_flow_snap_die.tcl
#
#   TT_flow_snap_die
#   TT_flow_snap_die -check
#
#   TT_flow_snap_die -apply
#
# Optional:
#   TT_flow_snap_die -apply \
#       -backup_db ../backup/snap_die/manual/CHIP_before_snap.enc
#
#   TT_flow_snap_die -apply -no_check_floorplan
#   TT_flow_snap_die -apply -force
#
# ==============================================================================

namespace eval ::TT_SNAP_DIE {
    variable version "3.2"
    variable tolerance 1.0e-6
}

proc ::TT_SNAP_DIE::usage {} {
    puts ""
    puts "TT_flow_snap_die v$::TT_SNAP_DIE::version"
    puts ""
    puts "  TT_flow_snap_die -check"
    puts "  TT_flow_snap_die -apply"
    puts "  TT_flow_snap_die -apply -backup_db <path>"
    puts ""
    puts "Options:"
    puts "  -check                  Audit + exact legal target preview (default)"
    puts "  -apply                  Apply exact legal target through absolute floorplan -b"
    puts "  -backup_db <path>       Save DB before APPLY"
    puts "  -no_backup              Do not create automatic DB backup"
    puts "  -check_floorplan        Run check_floorplan after APPLY (default)"
    puts "  -no_check_floorplan     Skip post-APPLY check_floorplan"
    puts "  -force                  Allow APPLY if design is placed/routed"
    puts "  -no_auto_rollback       Do not auto-restore backup on APPLY/invariant failure"
    puts "  -help                   Show this help"
    puts ""
}

proc ::TT_SNAP_DIE::safe_get_global {name {default "<N/A>"}} {
    set v $default
    if {[catch {set v [get_db $name]}]} {
        set v $default
    }
    return $v
}

proc ::TT_SNAP_DIE::safe_get_design {attr {default "<N/A>"}} {
    set v $default
    if {[catch {set v [get_db current_design $attr]}]} {
        set v $default
    }
    return $v
}

proc ::TT_SNAP_DIE::truthy {v} {
    set s [string tolower [string trim $v]]
    return [expr {$s eq "true" || $s eq "1" || $s eq "yes" || $s eq "on"}]
}

# Stylus can return:
#   {x1 y1 x2 y2}
# or:
#   {{x1 y1 x2 y2}}
proc ::TT_SNAP_DIE::norm4 {value label} {
    set v $value
    set guard 0

    while {[llength $v] == 1 && $guard < 4} {
        set inner [lindex $v 0]
        if {$inner eq $v} {
            break
        }
        set v $inner
        incr guard
    }

    if {[llength $v] != 4} {
        error "$label must contain exactly four values; raw='$value' normalized='$v'"
    }

    set out {}
    foreach x $v {
        if {![string is double -strict $x]} {
            error "$label contains non-numeric data; raw='$value' normalized='$v'"
        }
        lappend out [expr {double($x)}]
    }

    return $out
}

proc ::TT_SNAP_DIE::policy_to_grid_attr {policy} {
    switch -- [string tolower $policy] {
        finfet_inst {
            return floorplan_finfet_inst_grid
        }
        finfet_placement {
            return floorplan_finfet_placement_grid
        }
        finfet_manufacturing {
            return floorplan_finfet_manufacturing_grid
        }
        inst {
            return floorplan_inst_grid
        }
        placement {
            return floorplan_placement_grid
        }
        manufacturing {
            return floorplan_manufacturing_grid
        }
        user_define -
        user_defined -
        user {
            return floorplan_user_define_grid
        }
        default {
            return ""
        }
    }
}

proc ::TT_SNAP_DIE::get_policy_grid {policy} {
    set attr [::TT_SNAP_DIE::policy_to_grid_attr $policy]

    if {$attr eq ""} {
        return [dict create available 0 attr "<UNKNOWN>" grid {}]
    }

    set raw [::TT_SNAP_DIE::safe_get_global $attr "<N/A>"]
    if {$raw eq "<N/A>"} {
        return [dict create available 0 attr $attr grid {}]
    }

    if {[catch {set grid [::TT_SNAP_DIE::norm4 $raw $attr]}]} {
        return [dict create available 0 attr $attr grid {}]
    }

    lassign $grid ox oy px py
    if {$px <= 0.0 || $py <= 0.0} {
        return [dict create available 0 attr $attr grid $grid]
    }

    return [dict create available 1 attr $attr grid $grid]
}

proc ::TT_SNAP_DIE::grid_info {value origin pitch} {
    if {$pitch <= 0.0} {
        return [dict create legal 0 quotient 0.0 nearest_index 0 residual 0.0]
    }

    set q [expr {(double($value) - double($origin)) / double($pitch)}]
    set n [expr {round($q)}]
    set r [expr {$q - $n}]
    set legal [expr {abs($r) <= $::TT_SNAP_DIE::tolerance}]

    return [dict create \
        legal $legal \
        quotient $q \
        nearest_index $n \
        residual $r]
}

proc ::TT_SNAP_DIE::multiple_info {value pitch} {
    if {$pitch <= 0.0} {
        return [dict create legal 0 quotient 0.0 nearest_index 0 residual 0.0]
    }

    set q [expr {double($value) / double($pitch)}]
    set n [expr {round($q)}]
    set r [expr {$q - $n}]
    set legal [expr {abs($r) <= $::TT_SNAP_DIE::tolerance}]

    return [dict create \
        legal $legal \
        quotient $q \
        nearest_index $n \
        residual $r]
}

proc ::TT_SNAP_DIE::snap_floor {value origin pitch} {
    set q [expr {(double($value) - double($origin)) / double($pitch)}]
    set n [expr {floor($q + $::TT_SNAP_DIE::tolerance)}]
    return [expr {double($origin) + double($n) * double($pitch)}]
}

proc ::TT_SNAP_DIE::snap_ceil {value origin pitch} {
    set q [expr {(double($value) - double($origin)) / double($pitch)}]
    set n [expr {ceil($q - $::TT_SNAP_DIE::tolerance)}]
    return [expr {double($origin) + double($n) * double($pitch)}]
}

proc ::TT_SNAP_DIE::snap_nearest {value origin pitch} {
    set q [expr {(double($value) - double($origin)) / double($pitch)}]
    set n [expr {round($q)}]
    return [expr {double($origin) + double($n) * double($pitch)}]
}

proc ::TT_SNAP_DIE::yn {v} {
    if {$v} {
        return "YES"
    }
    return "NO"
}

proc ::TT_SNAP_DIE::fmt {v} {
    return [format "%.6f" $v]
}

proc ::TT_SNAP_DIE::near {a b {tol ""}} {
    if {$tol eq ""} {
        set tol $::TT_SNAP_DIE::tolerance
    }
    return [expr {abs(double($a) - double($b)) <= double($tol)}]
}

proc ::TT_SNAP_DIE::bbox_equal {a b {tol ""}} {
    if {$tol eq ""} {
        set tol $::TT_SNAP_DIE::tolerance
    }
    if {[llength $a] != 4 || [llength $b] != 4} {
        return 0
    }
    for {set i 0} {$i < 4} {incr i} {
        if {![::TT_SNAP_DIE::near [lindex $a $i] [lindex $b $i] $tol]} {
            return 0
        }
    }
    return 1
}

proc ::TT_SNAP_DIE::geometry {} {
    set die [::TT_SNAP_DIE::norm4 \
        [get_db current_design .bbox] "DIE bbox"]
    set core [::TT_SNAP_DIE::norm4 \
        [get_db current_design .core_bbox] "CORE bbox"]
    set io [::TT_SNAP_DIE::norm4 \
        [get_db current_design .io_bbox] "IO bbox"]

    lassign $die dllx dlly durx dury
    lassign $core cllx clly curx cury

    set die_w [expr {$durx - $dllx}]
    set die_h [expr {$dury - $dlly}]
    set core_w [expr {$curx - $cllx}]
    set core_h [expr {$cury - $clly}]

    set margin_l [expr {$cllx - $dllx}]
    set margin_b [expr {$clly - $dlly}]
    set margin_r [expr {$durx - $curx}]
    set margin_t [expr {$dury - $cury}]

    return [dict create \
        die $die \
        core $core \
        io $io \
        die_w $die_w \
        die_h $die_h \
        core_w $core_w \
        core_h $core_h \
        margin_l $margin_l \
        margin_b $margin_b \
        margin_r $margin_r \
        margin_t $margin_t]
}

proc ::TT_SNAP_DIE::bbox_grid_legal {bbox grid} {
    lassign $bbox llx lly urx ury
    lassign $grid ox oy px py

    foreach spec [list \
        [list $llx $ox $px] \
        [list $lly $oy $py] \
        [list $urx $ox $px] \
        [list $ury $oy $py]] {
        lassign $spec v o p
        set gi [::TT_SNAP_DIE::grid_info $v $o $p]
        if {![dict get $gi legal]} {
            return 0
        }
    }
    return 1
}

proc ::TT_SNAP_DIE::bbox_contains {outer inner} {
    lassign $outer ollx olly ourx oury
    lassign $inner illx illy iurx iury
    set tol 1.0e-9
    return [expr {
        $illx >= $ollx - $tol &&
        $illy >= $olly - $tol &&
        $iurx <= $ourx + $tol &&
        $iury <= $oury + $tol
    }]
}

proc ::TT_SNAP_DIE::report_bbox {label bbox policy} {
    puts ""
    puts "$label"
    puts "  bbox        : $bbox"
    puts "  snap policy : $policy"

    set pg [::TT_SNAP_DIE::get_policy_grid $policy]
    if {![dict get $pg available]} {
        puts "  grid attr   : [dict get $pg attr]"
        puts "  grid        : <UNAVAILABLE>"
        return 0
    }

    set grid [dict get $pg grid]
    lassign $grid ox oy px py
    lassign $bbox llx lly urx ury

    puts "  grid attr   : [dict get $pg attr]"
    puts "  grid        : $grid"

    set all_legal 1
    foreach item [list \
        [list LLX $llx $ox $px] \
        [list LLY $lly $oy $py] \
        [list URX $urx $ox $px] \
        [list URY $ury $oy $py]] {

        lassign $item n v o p
        set gi [::TT_SNAP_DIE::grid_info $v $o $p]
        if {![dict get $gi legal]} {
            set all_legal 0
        }
        puts [format "  %-3s %12.6f  q=%14.6f  legal=%s" \
            $n $v [dict get $gi quotient] \
            [::TT_SNAP_DIE::yn [dict get $gi legal]]]
    }

    return $all_legal
}

proc ::TT_SNAP_DIE::build_target {g die_policy core_policy} {
    set die_pg [::TT_SNAP_DIE::get_policy_grid $die_policy]
    set core_pg [::TT_SNAP_DIE::get_policy_grid $core_policy]

    if {![dict get $die_pg available]} {
        return [dict create available 0 reason \
            "DIE snap grid '$die_policy' is unavailable."]
    }
    if {![dict get $core_pg available]} {
        return [dict create available 0 reason \
            "CORE snap grid '$core_policy' is unavailable."]
    }

    lassign [dict get $die_pg grid] dox doy dpx dpy
    lassign [dict get $core_pg grid] cox coy cpx cpy

    lassign [dict get $g die] dllx dlly durx dury
    lassign [dict get $g core] cllx clly curx cury

    set core_w [dict get $g core_w]
    set core_h [dict get $g core_h]

    # DIE v3.2 invariant: preserve the absolute lower-left origin exactly.
    # If DIE LL is itself off-grid, this tool refuses APPLY rather than moving
    # the entire coordinate system.  Only the upper-right corner is snapped
    # inward to the active DIE grid.
    set llx_info [::TT_SNAP_DIE::grid_info $dllx $dox $dpx]
    set lly_info [::TT_SNAP_DIE::grid_info $dlly $doy $dpy]
    if {![dict get $llx_info legal] || ![dict get $lly_info legal]} {
        return [dict create available 0 reason \
            "Current DIE lower-left is not legal on the active DIE grid. v3.2 refuses to move DIE origin."]
    }

    set tdllx $dllx
    set tdlly $dlly
    set tdurx [::TT_SNAP_DIE::snap_floor $durx $dox $dpx]
    set tdury [::TT_SNAP_DIE::snap_floor $dury $doy $dpy]

    if {$tdurx <= $tdllx || $tdury <= $tdlly} {
        return [dict create available 0 reason \
            "Inward DIE UR snap would create a non-positive DIE size."]
    }

    # CORE: this tool is not allowed to silently resize core capacity.
    # Therefore current width/height must already be exact pitch multiples.
    set cwm [::TT_SNAP_DIE::multiple_info $core_w $cpx]
    set chm [::TT_SNAP_DIE::multiple_info $core_h $cpy]

    if {![dict get $cwm legal] || ![dict get $chm legal]} {
        return [dict create available 0 reason \
            [format "CORE size is not an exact CORE-grid multiple (W %.6f / %.6f, H %.6f / %.6f). Refusing automatic CORE resize." \
                $core_w $cpx $core_h $cpy]]
    }

    # Shift CORE to nearest legal phase while preserving exact current size.
    set tcllx [::TT_SNAP_DIE::snap_nearest $cllx $cox $cpx]
    set tclly [::TT_SNAP_DIE::snap_nearest $clly $coy $cpy]
    set tcurx [expr {$tcllx + $core_w}]
    set tcury [expr {$tclly + $core_h}]

    set tdie  [list $tdllx $tdlly $tdurx $tdury]
    set tcore [list $tcllx $tclly $tcurx $tcury]

    if {![::TT_SNAP_DIE::bbox_grid_legal $tdie [dict get $die_pg grid]]} {
        return [dict create available 0 reason \
            "Internal error: computed DIE target is not legal on the DIE grid."]
    }
    if {![::TT_SNAP_DIE::bbox_grid_legal $tcore [dict get $core_pg grid]]} {
        return [dict create available 0 reason \
            "Internal error: computed CORE target is not legal on the CORE grid."]
    }
    if {![::TT_SNAP_DIE::bbox_contains $tdie $tcore]} {
        return [dict create available 0 reason \
            "Computed CORE target is not fully contained by computed DIE target."]
    }

    # Preserve existing IO geometry in this tool. Refuse only if DIE shrink
    # would cut through the current IO bbox.
    if {![::TT_SNAP_DIE::bbox_contains $tdie [dict get $g io]]} {
        return [dict create available 0 reason \
            "Inward DIE target would exclude part of the current IO bbox. Refusing APPLY."]
    }

    set tw [expr {$tdurx - $tdllx}]
    set th [expr {$tdury - $tdlly}]

    set ml [expr {$tcllx - $tdllx}]
    set mb [expr {$tclly - $tdlly}]
    set mr [expr {$tdurx - $tcurx}]
    set mt [expr {$tdury - $tcury}]

    foreach m [list $ml $mb $mr $mt] {
        if {$m < -1.0e-9} {
            return [dict create available 0 reason \
                "Computed floorplan margin is negative."]
        }
    }

    return [dict create \
        available 1 \
        reason "" \
        die $tdie \
        core $tcore \
        io [dict get $g io] \
        die_w $tw \
        die_h $th \
        core_w $core_w \
        core_h $core_h \
        margin_l $ml \
        margin_b $mb \
        margin_r $mr \
        margin_t $mt]
}

proc ::TT_SNAP_DIE::report_target {g target} {
    puts ""
    puts "EXACT LEGAL FLOORPLAN TARGET"

    if {![dict get $target available]} {
        puts "  available   : NO"
        puts "  reason      : [dict get $target reason]"
        return
    }

    set bdie  [dict get $g die]
    set bcore [dict get $g core]
    set tdie  [dict get $target die]
    set tcore [dict get $target core]

    lassign $bdie  bdllx bdlly bdurx bdury
    lassign $bcore bcllx bclly bcurx bcury
    lassign $tdie  tdllx tdlly tdurx tdury
    lassign $tcore tcllx tclly tcurx tcury

    puts "  available   : YES"
    puts "  DIE current : $bdie"
    puts "  DIE target  : $tdie"
    puts [format "  DIE delta   : LL(%+.6f,%+.6f) UR(%+.6f,%+.6f) um" \
        [expr {$tdllx-$bdllx}] [expr {$tdlly-$bdlly}] \
        [expr {$tdurx-$bdurx}] [expr {$tdury-$bdury}]]

    puts "  CORE current: $bcore"
    puts "  CORE target : $tcore"
    puts [format "  CORE delta  : LL(%+.6f,%+.6f) UR(%+.6f,%+.6f) um" \
        [expr {$tcllx-$bcllx}] [expr {$tclly-$bclly}] \
        [expr {$tcurx-$bcurx}] [expr {$tcury-$bcury}]]

    puts ""
    puts "  ABSOLUTE BOX APPLY REQUEST:"
    puts "    DIE : [dict get $target die]"
    puts "    IO  : [dict get $target io]   (must remain unchanged)"
    puts "    CORE: [dict get $target core]"
    puts "    mode: floorplan -noResize -noSnapToGrid -b <DIE> <IO> <CORE>"
}

proc ::TT_SNAP_DIE::report {} {
    set g [::TT_SNAP_DIE::geometry]

    set die_policy [::TT_SNAP_DIE::safe_get_global \
        floorplan_snap_die_grid "<N/A>"]
    set core_policy [::TT_SNAP_DIE::safe_get_global \
        floorplan_snap_core_grid "<N/A>"]
    set io_policy [::TT_SNAP_DIE::safe_get_global \
        floorplan_snap_io_grid "<N/A>"]
    set con_policy [::TT_SNAP_DIE::safe_get_global \
        floorplan_snap_constraint_grid "<N/A>"]

    puts ""
    puts "======================================================================"
    puts " TECH_MV TT_flow_snap_die v$::TT_SNAP_DIE::version"
    puts "======================================================================"
    puts "ACTIVE SNAP POLICY"
    puts "  DIE        : $die_policy"
    puts "  CORE       : $core_policy"
    puts "  IO         : $io_policy"
    puts "  CONSTRAINT : $con_policy"
    puts ""
    puts "GRID DEFINITIONS"
    foreach a {
        floorplan_finfet_inst_grid
        floorplan_finfet_manufacturing_grid
        floorplan_finfet_placement_grid
        floorplan_inst_grid
        floorplan_manufacturing_grid
        floorplan_placement_grid
        floorplan_user_define_grid
    } {
        puts [format "  %-38s = %s" \
            $a [::TT_SNAP_DIE::safe_get_global $a "<N/A>"]]
    }

    ::TT_SNAP_DIE::report_bbox \
        "DIE CHECK" [dict get $g die] $die_policy
    ::TT_SNAP_DIE::report_bbox \
        "CORE CHECK" [dict get $g core] $core_policy
    ::TT_SNAP_DIE::report_bbox \
        "IO CHECK (diagnostic only; not moved by this tool)" \
        [dict get $g io] $io_policy

    puts ""
    puts "CURRENT FLOORPLAN GEOMETRY"
    puts "  die width   : [::TT_SNAP_DIE::fmt [dict get $g die_w]]"
    puts "  die height  : [::TT_SNAP_DIE::fmt [dict get $g die_h]]"
    puts "  core width  : [::TT_SNAP_DIE::fmt [dict get $g core_w]]"
    puts "  core height : [::TT_SNAP_DIE::fmt [dict get $g core_h]]"
    puts "  margin left : [::TT_SNAP_DIE::fmt [dict get $g margin_l]]"
    puts "  margin bot  : [::TT_SNAP_DIE::fmt [dict get $g margin_b]]"
    puts "  margin right: [::TT_SNAP_DIE::fmt [dict get $g margin_r]]"
    puts "  margin top  : [::TT_SNAP_DIE::fmt [dict get $g margin_t]]"

    set target [::TT_SNAP_DIE::build_target $g $die_policy $core_policy]
    ::TT_SNAP_DIE::report_target $g $target

    puts "======================================================================"

    return [dict create \
        geometry $g \
        target $target \
        die_policy $die_policy \
        core_policy $core_policy \
        io_policy $io_policy \
        constraint_policy $con_policy]
}

proc ::TT_SNAP_DIE::project_root {} {
    set cwd [file normalize [pwd]]

    # Normal TECH_MV runtime: Innovus runs from build_PR / build_PR0 / ...
    set tail [file tail $cwd]
    if {[string match "build_PR*" $tail]} {
        return [file dirname $cwd]
    }

    # If launched from project root itself.
    if {[file isdirectory [file join $cwd backup]] &&
        [glob -nocomplain -directory $cwd build_PR*] ne ""} {
        return $cwd
    }

    # Conservative fallback: project root is parent of the runtime cwd.
    return [file dirname $cwd]
}

proc ::TT_SNAP_DIE::default_backup_path {design_name} {
    set root [::TT_SNAP_DIE::project_root]
    set stamp [clock format [clock seconds] -format "%Y%m%d_%H%M%S"]
    set dir [file join $root backup snap_die $stamp]
    return [file join $dir "${design_name}_before_TT_snap_die.enc"]
}

proc ::TT_SNAP_DIE::invoke_legacy_floorplan {argv} {
    # Prefer the lowercase absolute-coordinate command emitted by Innovus
    # floorplan scripts.  Fall back to floorPlan/eval_legacy only when needed.
    if {[llength [info commands floorplan]] > 0} {
        return [uplevel #0 [linsert $argv 0 floorplan]]
    }
    if {[llength [info commands floorPlan]] > 0} {
        return [uplevel #0 [linsert $argv 0 floorPlan]]
    }
    if {[llength [info commands eval_legacy]] > 0} {
        set cmd "floorplan"
        foreach x $argv {
            append cmd " [list $x]"
        }
        return [eval_legacy $cmd]
    }
    error "Neither floorplan, floorPlan, nor eval_legacy is available in this Innovus session."
}

proc ::TT_SNAP_DIE::run_floorplan {site target} {
    if {![dict get $target available]} {
        error "No legal floorplan target is available: [dict get $target reason]"
    }

    set die  [dict get $target die]
    set io   [dict get $target io]
    set core [dict get $target core]

    set boxargs [concat $die $io $core]

    puts ""
    puts "######################################################################"
    puts "# TT ABSOLUTE FLOORPLAN SNAP APPLY"
    puts "######################################################################"
    puts "# Engine : floorplan/floorPlan absolute -b mode"
    puts "# Site   : $site (current site is audited; -b mode preserves boxes)"
    puts "# DIE    : $die"
    puts "# IO     : $io"
    puts "# CORE   : $core"
    puts "#"
    puts "# Primary request:"
    puts "#   floorplan -noResize -noSnapToGrid -b <DIE> <IO> <CORE>"
    puts "#"
    puts "# HARD POLICY:"
    puts "#   - NO floorPlan -d"
    puts "#   - DIE LL must not move"
    puts "#   - IO bbox must not change"
    puts "#   - CORE width/height must not change"
    puts "######################################################################"

    # This form is intentionally modeled after Innovus-generated floorplan
    # scripts: first try -noResize, then retry the SAME absolute -b boxes
    # without -noResize if this release rejects that switch.
    set argv1 [concat [list -noResize -noSnapToGrid -b] $boxargs]
    set rc [catch {::TT_SNAP_DIE::invoke_legacy_floorplan $argv1} msg opts]
    if {!$rc} {
        puts "INFO: Absolute -b APPLY accepted with -noResize."
        return
    }

    puts "WARN: Absolute -b APPLY with -noResize was rejected:"
    puts "      $msg"
    puts "INFO: Retrying SAME absolute DIE/IO/CORE boxes without -noResize."

    set argv2 [concat [list -noSnapToGrid -b] $boxargs]
    if {[catch {::TT_SNAP_DIE::invoke_legacy_floorplan $argv2} msg2 opts2]} {
        return -options $opts2 -code error \
            "Absolute-box floorplan APPLY failed. First attempt: $msg ; retry: $msg2"
    }

    puts "INFO: Absolute -b APPLY accepted without -noResize."
}

proc ::TT_SNAP_DIE::assert_base_legal {report_dict} {
    set g [dict get $report_dict geometry]
    set die_policy [dict get $report_dict die_policy]
    set core_policy [dict get $report_dict core_policy]

    set die_pg [::TT_SNAP_DIE::get_policy_grid $die_policy]
    set core_pg [::TT_SNAP_DIE::get_policy_grid $core_policy]

    if {![dict get $die_pg available] || ![dict get $core_pg available]} {
        error "POST-APPLY legality cannot be verified because DIE/CORE grid is unavailable."
    }

    set die_ok [::TT_SNAP_DIE::bbox_grid_legal \
        [dict get $g die] [dict get $die_pg grid]]
    set core_ok [::TT_SNAP_DIE::bbox_grid_legal \
        [dict get $g core] [dict get $core_pg grid]]

    puts ""
    puts "POST-APPLY BASE LEGALITY"
    puts "  DIE  : [::TT_SNAP_DIE::yn $die_ok]"
    puts "  CORE : [::TT_SNAP_DIE::yn $core_ok]"

    if {!$die_ok || !$core_ok} {
        error "POST-APPLY base floorplan is still off the active DIE/CORE snap grid. Restore the pre-snap DB and inspect floorPlan behavior."
    }
}


proc ::TT_SNAP_DIE::assert_apply_invariants {before_g target after_rep} {
    set after_g [dict get $after_rep geometry]

    set before_die  [dict get $before_g die]
    set before_core [dict get $before_g core]
    set before_io   [dict get $before_g io]
    set after_die   [dict get $after_g die]
    set after_core  [dict get $after_g core]
    set after_io    [dict get $after_g io]
    set target_die  [dict get $target die]
    set target_core [dict get $target core]

    lassign $before_die bdllx bdlly bdurx bdury
    lassign $after_die  adllx adlly adurx adury

    set die_ll_ok [expr {
        [::TT_SNAP_DIE::near $bdllx $adllx] &&
        [::TT_SNAP_DIE::near $bdlly $adlly]
    }]
    set die_target_ok [::TT_SNAP_DIE::bbox_equal $after_die $target_die]
    set core_target_ok [::TT_SNAP_DIE::bbox_equal $after_core $target_core]
    set io_ok [::TT_SNAP_DIE::bbox_equal $after_io $before_io]

    set before_cw [dict get $before_g core_w]
    set before_ch [dict get $before_g core_h]
    set after_cw [dict get $after_g core_w]
    set after_ch [dict get $after_g core_h]
    set core_size_ok [expr {
        [::TT_SNAP_DIE::near $before_cw $after_cw] &&
        [::TT_SNAP_DIE::near $before_ch $after_ch]
    }]

    puts ""
    puts "POST-APPLY HARD INVARIANTS"
    puts "  DIE LL unchanged       : [::TT_SNAP_DIE::yn $die_ll_ok]"
    puts "  DIE == target          : [::TT_SNAP_DIE::yn $die_target_ok]"
    puts "  CORE == target         : [::TT_SNAP_DIE::yn $core_target_ok]"
    puts "  CORE size unchanged    : [::TT_SNAP_DIE::yn $core_size_ok]"
    puts "  IO bbox unchanged      : [::TT_SNAP_DIE::yn $io_ok]"

    if {!$die_ll_ok || !$die_target_ok || !$core_target_ok ||
        !$core_size_ok || !$io_ok} {
        error "POST-APPLY invariant failure. Absolute floorplan geometry was not preserved exactly."
    }

    # Grid legality is checked only after geometry invariants pass.
    ::TT_SNAP_DIE::assert_base_legal $after_rep
}

proc ::TT_SNAP_DIE::rollback_db {backup_db} {
    if {$backup_db eq ""} {
        puts stderr "ERROR: No pre-snap DB path is available for automatic rollback."
        return 0
    }
    if {[llength [info commands read_db]] == 0} {
        puts stderr "ERROR: read_db is unavailable. Restore manually:"
        puts stderr "       read_db $backup_db"
        return 0
    }
    puts stderr ""
    puts stderr "######################################################################"
    puts stderr "# AUTO ROLLBACK"
    puts stderr "# Restoring pre-snap DB because APPLY/invariant verification failed."
    puts stderr "# DB: $backup_db"
    puts stderr "######################################################################"
    if {[catch {read_db $backup_db} rerr]} {
        puts stderr "ERROR: Automatic read_db rollback failed: $rerr"
        puts stderr "Restore manually: read_db $backup_db"
        return 0
    }
    puts stderr "INFO: Pre-snap DB restored successfully."
    return 1
}

proc TT_flow_snap_die {args} {
    set action check
    set do_check 1
    set force 0
    set no_backup 0
    set backup_db ""
    set auto_rollback 1

    set i 0
    while {$i < [llength $args]} {
        set a [lindex $args $i]

        switch -- $a {
            -check {
                set action check
            }
            -apply {
                set action apply
            }
            -check_floorplan {
                set do_check 1
            }
            -no_check_floorplan {
                set do_check 0
            }
            -backup_db {
                incr i
                if {$i >= [llength $args]} {
                    error "-backup_db requires a path"
                }
                set backup_db [lindex $args $i]
            }
            -no_backup {
                set no_backup 1
            }
            -force {
                set force 1
            }
            -no_auto_rollback {
                set auto_rollback 0
            }
            -help -
            --help {
                ::TT_SNAP_DIE::usage
                return
            }
            default {
                error "Unknown option '$a'. Use TT_flow_snap_die -help"
            }
        }
        incr i
    }

    if {[catch {set design_name [get_db current_design .name]}]} {
        error "No active Innovus design."
    }

    set rep [::TT_SNAP_DIE::report]
    set g [dict get $rep geometry]
    set target [dict get $rep target]

    if {$action eq "check"} {
        puts ""
        puts "INFO: CHECK ONLY. Nothing was modified."
        if {[dict get $target available]} {
            puts "INFO: Exact legal APPLY target is available."
            puts "INFO: APPLY command: TT_flow_snap_die -apply"
        } else {
            puts "WARN: APPLY target is unavailable:"
            puts "      [dict get $target reason]"
        }
        return $rep
    }

    if {![dict get $target available]} {
        error "Refusing APPLY: [dict get $target reason]"
    }

    set is_placed [::TT_SNAP_DIE::safe_get_design .is_placed false]
    set is_routed [::TT_SNAP_DIE::safe_get_design .is_routed false]
    set is_detail_routed [::TT_SNAP_DIE::safe_get_design \
        .is_detail_routed false]

    if {!$force &&
        ([::TT_SNAP_DIE::truthy $is_placed] ||
         [::TT_SNAP_DIE::truthy $is_routed] ||
         [::TT_SNAP_DIE::truthy $is_detail_routed])} {
        error "Refusing APPLY on a placed/routed design. Use an early Floorplan checkpoint or specify -force intentionally."
    }

    set site [::TT_SNAP_DIE::safe_get_design .core_site.name ""]
    if {$site eq "" || $site eq "<N/A>"} {
        set site_obj [::TT_SNAP_DIE::safe_get_design .core_site ""]
        if {$site_obj ne "" && $site_obj ne "<N/A>"} {
            if {[catch {set site [get_db $site_obj .name]}]} {
                set site ""
            }
        }
    }

    if {$site eq ""} {
        error "Unable to determine current core site."
    }

    if {!$no_backup} {
        if {$backup_db eq ""} {
            set backup_db [::TT_SNAP_DIE::default_backup_path $design_name]
        } else {
            set backup_db [file normalize $backup_db]
        }

        if {[llength [info commands write_db]] == 0} {
            error "write_db is unavailable; use -no_backup only if another checkpoint already exists."
        }

        set parent [file dirname $backup_db]
        if {![file isdirectory $parent]} {
            file mkdir $parent
        }

        puts ""
        puts "INFO: Saving pre-snap checkpoint under project backup/:"
        puts "      $backup_db"
        write_db $backup_db
    }

    set before_die  [dict get $g die]
    set before_core [dict get $g core]
    set before_io   [dict get $g io]

    if {[catch {::TT_SNAP_DIE::run_floorplan $site $target} apply_err apply_opts]} {
        puts stderr ""
        puts stderr "ERROR: Absolute-box floorplan APPLY failed:"
        puts stderr "       $apply_err"
        if {$auto_rollback && !$no_backup} {
            ::TT_SNAP_DIE::rollback_db $backup_db
        } else {
            puts stderr "Automatic rollback not performed."
            if {!$no_backup} {
                puts stderr "Manual restore: read_db $backup_db"
            }
        }
        return -options $apply_opts -code error $apply_err
    }

    puts ""
    puts "======================================================================"
    puts " POST-APPLY GEOMETRY"
    puts "======================================================================"
    set after_rep [::TT_SNAP_DIE::report]
    set after_g [dict get $after_rep geometry]

    set after_die  [dict get $after_g die]
    set after_core [dict get $after_g core]
    set after_io   [dict get $after_g io]

    puts ""
    puts "CHANGE SUMMARY"
    puts "  DIE  : $before_die  ->  $after_die"
    puts "  CORE : $before_core ->  $after_core"
    puts "  IO   : $before_io   ->  $after_io"

    if {[catch {::TT_SNAP_DIE::assert_apply_invariants $g $target $after_rep} inv_err inv_opts]} {
        puts stderr ""
        puts stderr "ERROR: $inv_err"
        if {$auto_rollback && !$no_backup} {
            ::TT_SNAP_DIE::rollback_db $backup_db
        } else {
            puts stderr "Automatic rollback not performed."
            if {!$no_backup} {
                puts stderr "Manual restore: read_db $backup_db"
            }
        }
        return -options $inv_opts -code error $inv_err
    }

    if {$do_check} {
        if {[llength [info commands check_floorplan]] == 0} {
            puts "WARN: check_floorplan is unavailable."
        } else {
            puts ""
            puts "######################################################################"
            puts "# POST-SNAP check_floorplan"
            puts "# Base DIE/CORE legality has already been verified above."
            puts "# Remaining IO/cell/constraint messages must be classified separately."
            puts "######################################################################"
            if {[catch {check_floorplan} chkerr chkopts]} {
                puts stderr ""
                puts stderr "WARN: check_floorplan returned Tcl status/error:"
                puts stderr "      $chkerr"
                puts stderr "Review the checker output above."
            }
        }
    }

    puts ""
    puts "======================================================================"
    puts " TT_flow_snap_die APPLY COMPLETE"
    puts "======================================================================"
    if {!$no_backup} {
        puts "Pre-snap DB : $backup_db"
    }
    puts "NOTE:"
    puts "  DIE/CORE base geometry is legal on the active snap policy."
    puts "  Absolute floorplan -b mode preserved the original DIE origin."
    puts "  DIE/IO/CORE boxes passed the hard post-APPLY invariants."
    puts "  This tool does NOT intentionally move IO placement or PD constraints."
    puts "  If check_floorplan still reports IMPFP-7251, classify the remaining"
    puts "  offending block/IO/std-cell objects after this base repair."
    puts "  PD/constraint IMPFP-3966 / IMPFP-7400 must be repaired separately."
    puts "======================================================================"

    return $after_rep
}

puts "INFO: Loaded TT_flow_snap_die v$::TT_SNAP_DIE::version"
puts "INFO: Check : TT_flow_snap_die -check"
puts "INFO: Apply : TT_flow_snap_die -apply"
