# Runtime adapter preserves the historical logical source path.
if {[info exists ::TECH_MV_RUNTIME_ROOT]} {
    info script [file join $::TECH_MV_RUNTIME_ROOT run/tool/01_floorplan/TT_proc_iopad_iofile_check.tcl]
}
# =============================================================================
# TT_proc_iopad_iofile_check.tcl
# =============================================================================
# Stage00 end-of-import consistency check for:
#   - generated/imported IO file
#   - supply RTE pads
#   - optional segmented IO-pad ring model / domain ownership / PR_CUT closure
#   - prohibition of RTE -> FILL_IN_CELL_BOND_PAD_041 assignment
# =============================================================================

proc tt_iochk_local_name {obj} {
    set name ""
    catch { set name [get_db $obj .name] }
    regsub {^inst:} $name {} name
    set name [string trimleft $name /]
    if {[info exists ::TOP_MODULE]} {
        set p "${::TOP_MODULE}/"
        if {[string first $p $name] == 0} {
            set name [string range $name [string length $p] end]
        }
    }
    return $name
}

proc tt_iochk_file_instances {io_file} {
    if {![file isfile $io_file]} {
        error "IO file does not exist: $io_file"
    }
    set fp [open $io_file r]
    set data [read $fp]
    close $fp

    set result {}
    foreach line [split $data "\n"] {
        if {[regexp {\(inst[[:space:]]+name="([^"]+)"} $line -> n]} {
            lappend result $n
        }
    }
    return $result
}

proc tt_iochk_count_exact {values target} {
    set n 0
    foreach v $values { if {$v eq $target} { incr n } }
    return $n
}

proc tt_iochk_find_inst {local_name} {
    foreach obj [get_db insts] {
        if {[tt_iochk_local_name $obj] eq $local_name} { return $obj }
    }
    return ""
}

proc tt_iochk_phys_cut_name {domain next_domain} {
    set safe "${domain}__${next_domain}"
    regsub -all {[^A-Za-z0-9_]} $safe {_} safe
    return "${::IOPAD_RING_CUT_PREFIX}_${safe}"
}

proc TT_check_iopad_iofile {} {
    if {!$::ENABLE_IMPORT_IOPAD_VALIDATION} {
        puts "INFO: Stage00 IO/model validation is disabled."
        return true
    }

    set report_dir [file join $::REPORT_DIR 00_import]
    file mkdir $report_dir
    set report [file join $report_dir $::IMPORT_IOPAD_VALIDATION_REPORT]
    set rf [open $report w]

    set errors {}
    set warnings {}
    set io_names [tt_iochk_file_instances $::IO_FILE]

    puts $rf "======================================================================"
    puts $rf " TECH_MV STAGE00 IOPAD / IO-FILE VALIDATION"
    puts $rf "======================================================================"
    puts $rf "IO file      : $::IO_FILE"
    puts $rf "IO entries   : [llength $io_names]"
    puts $rf "Model active : [expr {[info exists ::IOPAD_RING_MODEL_ACTIVE] && $::IOPAD_RING_MODEL_ACTIVE}]"

    # Every IO-file instance must be unique and exist in the design DB.
    foreach n [lsort -unique $io_names] {
        set count [tt_iochk_count_exact $io_names $n]
        if {$count != 1} { lappend errors "IO file instance '$n' appears $count times." }
        if {[tt_iochk_find_inst $n] eq ""} { lappend errors "IO file instance '$n' is absent from Innovus DB." }
    }

    # RTE pads are required but never receive FILL_IN_CELL_BOND_PAD_041.
    if {$::RTE_PAD_BOND_ASSIGN_ENABLE} {
        lappend errors "RTE_PAD_BOND_ASSIGN_ENABLE must be false; RTE pads do not receive FILL_IN_CELL_BOND_PAD_041."
    }
    if {[llength $::RTE_PAD_BOND_ASSIGN_SUPPLIES] != 0} {
        lappend errors "RTE_PAD_BOND_ASSIGN_SUPPLIES must be empty; got '$::RTE_PAD_BOND_ASSIGN_SUPPLIES'."
    }

    if {[info exists ::AUTO_IO_RTE_PAD_NAMES]} {
        set rte_names $::AUTO_IO_RTE_PAD_NAMES
    } elseif {[info exists ::AUTO_RTE_PAD_NAMES]} {
        set rte_names $::AUTO_RTE_PAD_NAMES
    } else {
        set rte_names {}
    }

    set expected_rte [llength $::RTE_PAD_SUPPLY_NETS]
    if {![info exists ::IOPAD_RING_MODEL_ACTIVE] || !$::IOPAD_RING_MODEL_ACTIVE} {
        if {[llength $rte_names] != $expected_rte} {
            lappend errors "Legacy RTE pad count mismatch: expected=$expected_rte actual=[llength $rte_names]."
        }
        foreach rte $rte_names {
            if {[tt_iochk_count_exact $io_names $rte] != 1} {
                lappend errors "RTE pad '$rte' must appear exactly once in IO file."
            }
            if {[tt_iochk_find_inst $rte] eq ""} {
                lappend errors "RTE pad '$rte' does not exist in Innovus DB."
            }
        }
        if {$::IMPORT_IOPAD_REQUIRE_MODEL} {
            lappend errors "IOPAD ring model is required but IOPAD_RING_DOMAIN_CONFIG is inactive/empty."
        } else {
            lappend warnings "IOPAD ring model is inactive; legacy IO/RTE consistency was checked."
        }
    } else {
        if {![info exists ::IOPAD_RING_MODEL]} {
            lappend errors "IOPAD_RING_MODEL_ACTIVE is true but IOPAD_RING_MODEL is missing."
        } else {
            if {[llength [info commands tt_iopad_ring_validate]] == 0} {
                source -quiet [file join $::TECH_MV_RUNTIME_ROOT .. script PR TECH_MV script 01_floorplan proc_iopad_ring_model.tcl]
            }
            if {![tt_iopad_ring_validate $::IOPAD_RING_MODEL]} {
                lappend errors "IOPAD ring data-model validation failed."
            }

            set order [dict get $::IOPAD_RING_MODEL order]
            set common_ground [dict get $::IOPAD_RING_MODEL common_ground_net]
            set domain_count [llength $order]
            puts $rf "Domains      : [join $order { -> }] -> [lindex $order 0]"
            puts $rf "Common GND   : $common_ground"

            for {set i 0} {$i < $domain_count} {incr i} {
                set dname [lindex $order $i]
                set next [lindex $order [expr {($i+1)%$domain_count}]]
                set prev [lindex $order [expr {($i-1+$domain_count)%$domain_count}]]
                set d [dict get $::IOPAD_RING_MODEL domains $dname]

                if {[dict get $d next_domain] ne $next} {
                    lappend errors "Domain '$dname' next_domain mismatch: expected=$next got=[dict get $d next_domain]."
                }
                if {[dict get $d prev_domain] ne $prev} {
                    lappend errors "Domain '$dname' prev_domain mismatch: expected=$prev got=[dict get $d prev_domain]."
                }
                if {[dict get $d ground_net] ne $common_ground} {
                    lappend errors "Domain '$dname' ground must be shared '$common_ground'."
                }
                if {[llength [dict get $d io_power_pads]] < 1} {
                    lappend errors "Domain '$dname' has no IO_POWER pad."
                }
                if {[llength [dict get $d rte_pads]] < 1} {
                    lappend errors "Domain '$dname' has no RTE pad."
                }

                foreach field {io_power_pads rte_pads ground_pads signal_pads} {
                    foreach pad [dict get $d $field] {
                        set inst [dict get $pad instance]
                        if {[tt_iochk_count_exact $io_names $inst] != 1} {
                            lappend errors "Domain '$dname' pad '$inst' must appear exactly once in IO file."
                        }
                        if {[tt_iochk_find_inst $inst] eq ""} {
                            lappend errors "Domain '$dname' pad '$inst' is absent from Innovus DB."
                        }
                    }
                }

                set cut [tt_iochk_phys_cut_name $dname $next]
                if {[tt_iochk_count_exact $io_names $cut] != 1} {
                    lappend errors "PR_CUT '$cut' for $dname -> $next must appear exactly once in IO file."
                }
                if {[tt_iochk_find_inst $cut] eq ""} {
                    lappend errors "PR_CUT '$cut' for $dname -> $next is absent from Innovus DB."
                }
            }
        }
    }

    puts $rf ""
    if {[llength $warnings] > 0} {
        puts $rf "WARNINGS"
        foreach w $warnings { puts $rf "WARNING: $w" }
    }
    puts $rf ""

    if {[llength $errors] > 0} {
        puts $rf "RESULT: FAIL"
        foreach e $errors { puts $rf "ERROR: $e" }
        close $rf
        puts "======================================================================"
        puts " STAGE00 IOPAD / IO-FILE CHECK: FAIL"
        puts "======================================================================"
        foreach e $errors { puts "ERROR: $e" }
        puts "Report: $report"
        puts "======================================================================"
        if {$::IMPORT_IOPAD_VALIDATION_STRICT} {
            error "Stage00 IOPAD / IO-file validation failed with [llength $errors] error(s)."
        }
        return false
    }

    puts $rf "RESULT: PASS"
    close $rf
    puts "======================================================================"
    puts " STAGE00 IOPAD / IO-FILE CHECK: PASS"
    puts "======================================================================"
    if {[info exists ::IOPAD_RING_MODEL_ACTIVE] && $::IOPAD_RING_MODEL_ACTIVE} {
        puts "Mode   : IOPAD ring model"
    } else {
        puts "Mode   : legacy IO file + supply RTE validation"
    }
    puts "Report : $report"
    puts "======================================================================"
    return true
}
