# Runtime adapter preserves the historical logical source path.
if {[info exists ::TECH_MV_RUNTIME_ROOT]} {
    info script [file join $::TECH_MV_RUNTIME_ROOT run/tool/01_floorplan/TT_flow_check_bond_pad.tcl]
}
# =============================================================================
# TT_flow_check_bond_pad.tcl
# Read-only executable TECH bond-pad collateral/result check.
# =============================================================================

# Cadence DB root `bumps` is used by the real TECH reference to query
# FILL_IN_CELL_BOND_PAD_041 bond-pad objects. This does not imply an REFERENCE_PLATFORM bump-array flow.
proc TT_flow_check_bond_pad {} {
    puts ""
    puts "======================================================================"
    puts " TECH BOND PAD CHECK"
    puts "======================================================================"

    set errors 0
    set warnings 0

    if {[llength [get_db base_cells $::BOND_PAD_CELL]] == 0} {
        puts "ERROR: '$::BOND_PAD_CELL' is not loaded."
        puts "       Check FILL_IN_LIBRARY_0174."
        incr errors
    } else {
        puts "PASS : bond-pad cell $::BOND_PAD_CELL loaded."
    }

    if {[llength [get_db layers $::BOND_PAD_TOP_LAYER]] == 0} {
        puts "ERROR: top layer $::BOND_PAD_TOP_LAYER not loaded."
        incr errors
    } else {
        puts "PASS : top layer $::BOND_PAD_TOP_LAYER loaded."
    }

    foreach layer {CTM CBM} {
        if {[llength [get_db layers $layer]] == 0} {
            puts "WARN : layer $layer is not present in current DB."
            incr warnings
        } else {
            puts "PASS : layer $layer present."
        }
    }

    puts "INFO : current Innovus bond-pad object count = [llength [get_db bumps]]"

    set cb_count 0
    catch {
        set cb_count [llength [get_db gui_rects -if \
            [format {.gui_layer_name == "%s"} $::BOND_PAD_CHIP_BOUNDARY_LAYER]]]
    }
    puts "INFO : $::BOND_PAD_CHIP_BOUNDARY_LAYER shape count = $cb_count"

    puts "----------------------------------------------------------------------"
    puts "Result: errors=$errors warnings=$warnings"
    puts "======================================================================"
    puts ""

    if {$errors > 0} {
        return -code error "TECH bond-pad check failed."
    }
}

# Compatibility alias for older console usage.
proc TT_check_bond_pad {} {
    puts "WARNING: TT_check_bond_pad is deprecated; use TT_flow_check_bond_pad."
    return [TT_flow_check_bond_pad]
}

TT_flow_check_bond_pad
