# Runtime adapter preserves the historical logical source path.
if {[info exists ::TECH_MV_RUNTIME_ROOT]} {
    info script [file join $::TECH_MV_RUNTIME_ROOT run/tool/03_place/padding/TT_clear_ls_iso_instance_padding.tcl]
}
# =============================================================================
# TT_clear_ls_iso_instance_padding.tcl
# TECH_MV / Innovus 21.19 Stylus / Common UI
# V1.1 - remove Level-Shifter / Isolation instance padding
#
# Policy:
#   - Discover Level Shifter instances by .is_level_shifter == true.
#   - Discover Isolation instances by .is_isolation == true.
#   - Remove instance-padding constraints with delete_inst_padding; do not call set_inst_padding with zero.
#   - Verify live instance padding attributes are zero after the update.
#   - Do not change placement status, location, orientation, SDP ownership,
#     connectivity, power-domain assignment, or any SDP file padding.
#
# Public command:
#   TT_clear_ls_iso_instance_padding
# =============================================================================

set ::TT_CLEAR_LS_ISO_PADDING_VERSION "V1.1_DELETE_INSTANCE_PADDING"

proc TT_CLEAR_LS_ISO_PAD__append_unique {var_name obj} {
    upvar 1 $var_name L
    if {$obj ne "" && [lsearch -exact $L $obj] < 0} {
        lappend L $obj
    }
}

proc TT_CLEAR_LS_ISO_PAD__collect {} {
    set targets {}

    foreach filter {
        {.is_level_shifter == true}
        {.is_isolation == true}
    } {
        set objs {}
        if {[catch {set objs [get_db insts -if $filter]} err]} {
            error "Cannot query LS/ISO instances with filter '$filter': $err"
        }
        foreach obj $objs {
            TT_CLEAR_LS_ISO_PAD__append_unique targets $obj
        }
    }

    return $targets
}

proc TT_clear_ls_iso_instance_padding {} {
    puts ""
    puts "======================================================================"
    puts " CLEAR LS / ISO INSTANCE PADDING"
    puts "======================================================================"

    if {[llength [info commands delete_inst_padding]] == 0} {
        error "Required Innovus command delete_inst_padding is unavailable."
    }

    set targets [TT_CLEAR_LS_ISO_PAD__collect]
    set already_zero 0
    set removed 0
    set failed 0

    foreach inst $targets {
        set name [get_db $inst .name]

        set left ""
        set right ""
        catch {set left [get_db $inst .left_padding]}
        catch {set right [get_db $inst .right_padding]}

        if {[string is integer -strict $left] && [string is integer -strict $right] &&
            $left == 0 && $right == 0} {
            incr already_zero
            continue
        }

        # Innovus set_inst_padding requires a strictly positive padding value;
        # zero is invalid.  Remove an existing instance-padding constraint with
        # delete_inst_padding instead of trying set_inst_padding ... 0.
        if {[catch {
            delete_inst_padding -inst $name
        } err]} {
            puts "WARN: Failed to delete instance padding: $name"
            puts "      $err"
            incr failed
            continue
        }

        set left_after ""
        set right_after ""
        catch {set left_after [get_db $inst .left_padding]}
        catch {set right_after [get_db $inst .right_padding]}

        if {![string is integer -strict $left_after] ||
            ![string is integer -strict $right_after] ||
            $left_after != 0 || $right_after != 0} {
            puts "WARN: Padding verification failed after delete_inst_padding: $name left=$left_after right=$right_after"
            incr failed
            continue
        }
        incr removed
    }

    puts "LS/ISO instances found : [llength $targets]"
    puts "Padding policy         : no instance padding"
    puts "Already zero           : $already_zero"
    puts "Removed/verified       : $removed"
    puts "Failed                 : $failed"
    puts "======================================================================"

    if {$failed != 0} {
        puts "WARN: LS/ISO instance-padding removal incomplete for $failed instance(s)."
        puts "WARN: Flow will continue; inspect with: get_db <inst> .*padding*"
    }

    # Compatibility/result contract:
    #   verified_zero = instances confirmed at 0/0 after this helper
    #   cleared       = compatibility alias used by the surrounding flow
    #                  (already-zero + successfully removed)
    set verified_zero [expr {$already_zero + $removed}]
    return [dict create \
        targets [llength $targets] \
        already_zero $already_zero \
        removed $removed \
        verified_zero $verified_zero \
        cleared $verified_zero \
        failed $failed]
}

puts "INFO: Loaded TT_clear_ls_iso_instance_padding.tcl - $::TT_CLEAR_LS_ISO_PADDING_VERSION"
