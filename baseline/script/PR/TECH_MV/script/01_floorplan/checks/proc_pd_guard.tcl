# Runtime adapter preserves the historical logical source path.
if {[info exists ::TECH_MV_RUNTIME_ROOT]} {
    info script [file join $::TECH_MV_RUNTIME_ROOT run/tool/01_floorplan/checks/TT_proc_pd_guard.tcl]
} else {
    info script [file normalize [file join [file dirname [info script]] .. .. .. run/tool/01_floorplan/checks/TT_proc_pd_guard.tcl]]
}
# =============================================================================
# TT_proc_pd_guard.tcl
# =============================================================================
# Power-Domain boundary guard utilities.
# Uses the exposed-boundary rectangle engine in TT_proc_pd_geometry.tcl.
# =============================================================================

proc tt_pd_guard_safe_name {name} {
    set safe $name
    regsub -all {[^A-Za-z0-9_]} $safe {_} safe
    return $safe
}

proc tt_pd_guard_domains {} {
    if {[llength [info commands tt_pd_outer_boundary_blockage_rects]] == 0} {
        source -quiet [file join $::TOOL_DIR 01_floorplan geometry TT_proc_pd_geometry.tcl]
    }

    set result {}
    if {$::PD_BOUNDARY_GUARD_DOMAINS eq "auto"} {
        foreach group [get_db groups] {
            set pd_name ""
            set rects {}
            catch { set pd_name [get_db $group .power_domain.name] }
            catch { set rects [get_db $group .rects] }
            if {$pd_name eq "" || [llength $rects] == 0} { continue }
            if {[lsearch -exact $::PD_BOUNDARY_GUARD_EXCLUDE_DOMAINS $pd_name] >= 0} { continue }
            if {[lsearch -exact $result $pd_name] < 0} { lappend result $pd_name }
        }
    } else {
        foreach pd_name $::PD_BOUNDARY_GUARD_DOMAINS {
            if {[lsearch -exact $::PD_BOUNDARY_GUARD_EXCLUDE_DOMAINS $pd_name] >= 0} { continue }
            lappend result $pd_name
        }
    }
    return $result
}

proc tt_pd_guard_widths {} {
    set w $::PD_BOUNDARY_GUARD_WIDTH
    if {[llength $w] == 1} {
        return [list $w $w $w $w]
    }
    if {[llength $w] != 4} {
        error "PD_BOUNDARY_GUARD_WIDTH must be one value or {left bottom right top}; got '$w'"
    }
    # MACRO_PLACE_HALO convention is left bottom right top.
    lassign $w left bottom right top
    return [list $top $bottom $left $right]
}

proc tt_pd_guard_delete {phase} {
    set prefix "PD_GUARD_[string toupper $phase]_"
    foreach blk [get_db place_blockages] {
        set n ""
        catch { set n [get_db $blk .name] }
        if {[string match "${prefix}*" $n]} { delete_obj $blk }
    }
}

proc tt_pd_guard_apply {phase} {
    if {!$::ENABLE_PD_BOUNDARY_GUARD} {
        puts "INFO: Power-Domain boundary guard is disabled."
        return {}
    }
    if {[llength [info commands tt_pd_outer_boundary_blockage_rects]] == 0} {
        source -quiet [file join $::TOOL_DIR 01_floorplan geometry TT_proc_pd_geometry.tcl]
    }

    set phase [string tolower $phase]
    switch -- $phase {
        macro { set blockage_type macro_only }
        hard  { set blockage_type hard }
        default { error "Unknown PD guard phase '$phase'; use macro or hard" }
    }

    tt_pd_guard_delete $phase
    lassign [tt_pd_guard_widths] top bottom left right
    set made {}

    foreach pd_name [tt_pd_guard_domains] {
        set rects [tt_pd_outer_boundary_blockage_rects \
            $pd_name $top $bottom $left $right $::PD_BOUNDARY_GUARD_STRICT]
        if {[llength $rects] == 0} {
            puts "INFO: PD guard has no exposed rectangle for $pd_name"
            continue
        }
        set name "PD_GUARD_[string toupper $phase]_[tt_pd_guard_safe_name $pd_name]"
        puts "INFO: Create $blockage_type PD guard: $pd_name rects=[llength $rects]"
        if {[llength [info commands create_place_blockage]] > 0} {
            create_place_blockage -name $name -type $blockage_type -rects $rects
        } else {
            set idx 0
            foreach r $rects {
                createPlaceBlockage -name "${name}_${idx}" \
                    -type [expr {$blockage_type eq "macro_only" ? "macroOnly" : "hard"}] \
                    -box $r
                incr idx
            }
        }
        lappend made $name
    }

    puts "INFO: PD boundary guard phase=$phase created for [llength $made] domain(s): $made"
    return $made
}
