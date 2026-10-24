# Runtime adapter preserves the historical logical source path.
if {[info exists ::TECH_MV_RUNTIME_ROOT]} {
    info script [file join $::TECH_MV_RUNTIME_ROOT run/tool/00_common/TT_import_geometry_info.tcl]
} else {
    info script [file normalize [file join [file dirname [info script]] .. .. run/tool/00_common/TT_import_geometry_info.tcl]]
}
# Definitions only. Stage-00 invokes this after the library/design is loaded.
# Keep derived geometry in session memory; do not write process data or replay a stage.
proc ::tech_mv_import_geometry_info {} {
    set result [dict create values {} sources {} unavailable {}]
    foreach key {
        welltap::fallback_site_pitch
        edge_switch::fallback_inst_grid
        run/tool/02_powerplan/TT_PR7_coordinate_guided_repair.tcl::::TT_PR7_COORD_SITE_PITCH_UM::L47
        run/tool/02_powerplan/TT_refine_internal_gap_sdps.tcl::::TT_PR7_GAPBLK_FALLBACK_W::L245
        run/tool/02_powerplan/TT_refine_internal_gap_sdps.tcl::::TT_PR7_GAPBLK_FALLBACK_H::L246
    } {
        set info [::tech_mv_live_geometry $key]
        if {$info eq ""} {
            dict lappend result unavailable $key
        } else {
            dict set result values $key [dict get $info value]
            dict set result sources $key [dict get $info source]
        }
    }
    if {[info exists ::BOND_PAD_CELL] && [llength [info commands get_db]]} {
        set cells {}
        catch {set cells [get_db base_cells $::BOND_PAD_CELL]}
        if {[llength $cells] == 1} {
            set box {}
            catch {set box [get_db [lindex $cells 0] .bbox]}
            if {[llength $box] == 1 && [llength [lindex $box 0]] == 4} { set box [lindex $box 0] }
            set valid [expr {[llength $box] == 4}]
            if {$valid} {
                foreach v $box { if {![string is double -strict $v]} { set valid 0 } }
            }
            if {$valid} {
                lassign $box x1 y1 x2 y2
                set w [expr {abs($x2-$x1)}]
                set h [expr {abs($y2-$y1)}]
                if {$w > 0 && $h > 0} {
                    dict set result values bond_pad::body_width $w
                    dict set result values bond_pad::body_height $h
                    dict set result sources bond_pad::body_width base_cell_bbox
                    dict set result sources bond_pad::body_height base_cell_bbox
                }
            }
        }
    }
    puts "INFO: Stage00 component geometry queried: [dict size [dict get $result values]] available entries."
    # Missing masters may be loaded/configured later; getters retry live queries then.
    return $result
}
