# Runtime adapter preserves the historical logical source path.
if {[info exists ::TECH_MV_RUNTIME_ROOT]} {
    info script [file join $::TECH_MV_RUNTIME_ROOT run/tool/01_floorplan/geometry/TT_flow_snap_die.tcl]
}
# PUBLIC_EXPORT_REVIEW_REQUIRED: residual technology candidates require manual review.
# =============================================================================
# TT_flow_snap_die.tcl
# =============================================================================
# TT_flow_* : executable flow script. No proc is defined.
#
# Purpose:
#   Verify the current core upper Y against the FinFET instance grid before
#   IO-pad placement. If correction is required, use Stylus create_floorplan
#   -box_size while preserving die box, IO box, and core LLX/LLY/URX.
#
# Controls:
#   TT_FLOW_SNAP_DIE_ACTION    = preview | apply
#   TT_FLOW_SNAP_DIE_DIRECTION = down | up | nearest
#
# Default: preview / down
#
# Hard NO-OP:
#   If core top Y is already legal, create_floorplan is not called.
#
# This script does NOT use legacy floorPlan.
# =============================================================================

if {![info exists TT_FLOW_SNAP_DIE_ACTION]} {
    set TT_FLOW_SNAP_DIE_ACTION preview
}
if {![info exists TT_FLOW_SNAP_DIE_DIRECTION]} {
    set TT_FLOW_SNAP_DIE_DIRECTION down
}

set _tt_action [string tolower $TT_FLOW_SNAP_DIE_ACTION]
set _tt_direction [string tolower $TT_FLOW_SNAP_DIE_DIRECTION]

if {$_tt_action ni {preview apply}} {
    error "TT_FLOW_SNAP_DIE_ACTION must be preview or apply. Current value: $_tt_action"
}
if {$_tt_direction ni {down up nearest}} {
    error "TT_FLOW_SNAP_DIE_DIRECTION must be down, up, or nearest. Current value: $_tt_direction"
}

set _tt_grid [get_db floorplan_finfet_inst_grid]
set _tt_core [get_db current_design .core_bbox]
set _tt_die  [get_db current_design .bbox]
set _tt_io   [get_db current_design .io_bbox]

# Normalize exactly one wrapper level for Innovus geometry returns such as:
#   {llx lly urx ury}
foreach _tt_geom_var {_tt_grid _tt_core _tt_die _tt_io} {
    set _tt_geom_value [set $_tt_geom_var]
    if {[llength $_tt_geom_value] == 1} {
        set _tt_inner [lindex $_tt_geom_value 0]
        if {[llength $_tt_inner] == 4} {
            set $_tt_geom_var $_tt_inner
        }
    }
}
catch {unset _tt_geom_value}
catch {unset _tt_inner}
unset _tt_geom_var

if {[llength $_tt_grid] != 4} {
    error "Unexpected FinFET instance-grid format after normalization: $_tt_grid"
}
if {[llength $_tt_core] != 4} {
    error "Unexpected core bbox format after normalization: $_tt_core"
}
if {[llength $_tt_die] != 4} {
    error "Unexpected die bbox format after normalization: $_tt_die"
}
if {[llength $_tt_io] != 4} {
    error "Unexpected IO bbox format after normalization: $_tt_io"
}

lassign $_tt_grid _tt_grid_x0 _tt_grid_y0 _tt_grid_dx _tt_grid_dy
lassign $_tt_core _tt_core_llx _tt_core_lly _tt_core_urx _tt_core_ury
lassign $_tt_die  _tt_die_llx _tt_die_lly _tt_die_urx _tt_die_ury
lassign $_tt_io   _tt_io_llx _tt_io_lly _tt_io_urx _tt_io_ury

if {$_tt_grid_dy <= 0.0} {
    error "FinFET grid Y pitch must be greater than zero."
}

set _tt_q [expr {($_tt_core_ury - $_tt_grid_y0) / $_tt_grid_dy}]
set _tt_q_round [expr {round($_tt_q)}]
set _tt_grid_error [expr {abs($_tt_q - $_tt_q_round)}]
set _tt_already_legal [expr {$_tt_grid_error <= 1.0e-8}]

if {$_tt_already_legal} {
    set _tt_new_ury $_tt_core_ury
} else {
    switch -- $_tt_direction {
        down {
            set _tt_k [expr {floor($_tt_q + 1.0e-10)}]
        }
        up {
            set _tt_k [expr {ceil($_tt_q - 1.0e-10)}]
        }
        nearest {
            set _tt_k [expr {round($_tt_q)}]
        }
    }
    set _tt_new_ury [expr {$_tt_grid_y0 + $_tt_k * $_tt_grid_dy}]
}

set _tt_delta [expr {$_tt_new_ury - $_tt_core_ury}]
set _tt_target_core [list \
    $_tt_core_llx $_tt_core_lly $_tt_core_urx $_tt_new_ury]

puts "======================================================================"
puts " TECH_MV TT_flow_snap_die"
puts "======================================================================"
puts "Action           : $_tt_action"
puts "Direction        : $_tt_direction"
puts "FinFET grid      : $_tt_grid"
puts "Die bbox         : $_tt_die"
puts "IO bbox          : $_tt_io"
puts "Current core bbox: $_tt_core"
puts "Current top Y    : [format %.6f $_tt_core_ury]"
puts "Grid quotient    : [format %.6f $_tt_q]"
puts "Grid legal       : $_tt_already_legal"
puts "Target top Y     : [format %.6f $_tt_new_ury]"
puts "Top-Y delta      : [format %+.6f $_tt_delta] um"
puts "Target core bbox : $_tt_target_core"
puts "======================================================================"

if {$_tt_already_legal} {
    puts "INFO: Core top Y is already on the FinFET instance grid."
    puts "INFO: NO-OP: create_floorplan was not called; the current floorplan is preserved."

    foreach _tt_var {
        _tt_action _tt_direction _tt_grid _tt_core _tt_die _tt_io
        _tt_grid_x0 _tt_grid_y0 _tt_grid_dx _tt_grid_dy
        _tt_core_llx _tt_core_lly _tt_core_urx _tt_core_ury
        _tt_die_llx _tt_die_lly _tt_die_urx _tt_die_ury
        _tt_io_llx _tt_io_lly _tt_io_urx _tt_io_ury
        _tt_q _tt_q_round _tt_grid_error _tt_already_legal
        _tt_new_ury _tt_delta _tt_target_core
    } {
        catch {unset $_tt_var}
    }
    unset _tt_var
    return
}

if {$_tt_action eq "preview"} {
    puts "INFO: Preview only. No database object was changed."
    puts "INFO: To apply:"
    puts "INFO:   set TT_FLOW_SNAP_DIE_ACTION apply"
    puts "INFO:   set TT_FLOW_SNAP_DIE_DIRECTION $_tt_direction"
    puts "INFO:   source run/tool/01_floorplan/geometry/TT_flow_snap_die.tcl"

    foreach _tt_var {
        _tt_action _tt_direction _tt_grid _tt_core _tt_die _tt_io
        _tt_grid_x0 _tt_grid_y0 _tt_grid_dx _tt_grid_dy
        _tt_core_llx _tt_core_lly _tt_core_urx _tt_core_ury
        _tt_die_llx _tt_die_lly _tt_die_urx _tt_die_ury
        _tt_io_llx _tt_io_lly _tt_io_urx _tt_io_ury
        _tt_q _tt_q_round _tt_grid_error _tt_already_legal
        _tt_new_ury _tt_delta _tt_target_core
    } {
        catch {unset $_tt_var}
    }
    unset _tt_var
    return
}

set _tt_is_placed [get_db current_design .is_placed]
if {$_tt_is_placed} {
    error "Refusing floorplan correction: design is already placed. Use an early Stage-01 database."
}

if {![info exists CORE_SITE]} {
    error "CORE_SITE is not defined. Source init.setup/config first."
}

set _tt_box_size [concat \
    $_tt_die \
    $_tt_io \
    [list $_tt_core_llx $_tt_core_lly $_tt_core_urx $_tt_new_ury]]

puts "INFO: Applying Stylus create_floorplan correction before IO-pad placement."
puts "INFO: Only core URY changes."
puts "INFO: Box size = $_tt_box_size"

create_floorplan -site $CORE_SITE -box_size $_tt_box_size

set _tt_after_core [get_db current_design .core_bbox]
if {[llength $_tt_after_core] == 1 &&
    [llength [lindex $_tt_after_core 0]] == 4} {
    set _tt_after_core [lindex $_tt_after_core 0]
}

if {[llength $_tt_after_core] != 4} {
    error "Unexpected core bbox after create_floorplan: $_tt_after_core"
}

lassign $_tt_after_core _tt_a_llx _tt_a_lly _tt_a_urx _tt_a_ury

if {[expr {abs($_tt_a_llx - $_tt_core_llx)}] > 1.0e-6 ||
    [expr {abs($_tt_a_lly - $_tt_core_lly)}] > 1.0e-6 ||
    [expr {abs($_tt_a_urx - $_tt_core_urx)}] > 1.0e-6} {
    error "Unexpected core-edge change after create_floorplan. LLX/LLY/URX must remain unchanged."
}

if {[expr {abs($_tt_a_ury - $_tt_new_ury)}] > 1.0e-6} {
    error "Core top Y did not reach requested coordinate. Requested=$_tt_new_ury actual=$_tt_a_ury"
}

set _tt_verify_q [expr {($_tt_a_ury - $_tt_grid_y0) / $_tt_grid_dy}]
set _tt_verify_error [expr {abs($_tt_verify_q - round($_tt_verify_q))}]
if {$_tt_verify_error > 1.0e-8} {
    error "Core top Y is still not on the FinFET instance grid."
}

puts "======================================================================"
puts " TT_flow_snap_die: PASS"
puts "======================================================================"
puts "Before : $_tt_core"
puts "After  : $_tt_after_core"
puts "Delta Y: [format %+.6f $_tt_delta] um"
puts "======================================================================"

foreach _tt_var {
    _tt_action _tt_direction _tt_grid _tt_core _tt_die _tt_io
    _tt_grid_x0 _tt_grid_y0 _tt_grid_dx _tt_grid_dy
    _tt_core_llx _tt_core_lly _tt_core_urx _tt_core_ury
    _tt_die_llx _tt_die_lly _tt_die_urx _tt_die_ury
    _tt_io_llx _tt_io_lly _tt_io_urx _tt_io_ury
    _tt_q _tt_q_round _tt_grid_error _tt_already_legal
    _tt_k _tt_new_ury _tt_delta _tt_target_core
    _tt_is_placed _tt_box_size _tt_after_core
    _tt_a_llx _tt_a_lly _tt_a_urx _tt_a_ury
    _tt_verify_q _tt_verify_error
} {
    catch {unset $_tt_var}
}
unset _tt_var
