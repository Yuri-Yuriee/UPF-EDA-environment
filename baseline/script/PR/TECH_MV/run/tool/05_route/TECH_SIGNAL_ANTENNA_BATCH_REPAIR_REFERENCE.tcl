# TECH_MV Signal Antenna Batch Repair — reference script
# SOURCE: the script previously supplied in this conversation and executed by user.
# OBSERVED: check_antenna -use signal => 0 violations; selected-net connectivity => 0.
# NOT PRODUCTION-READY: Codex must audit parsing, exclusions, selection, routing side effects,
# diagnostics, checkpoint policy, report naming, hooks and power-domain protections.

puts "=================================================="
puts " TECH SIGNAL ANTENNA BATCH REPAIR"
puts "=================================================="

# 1. Output directories
set work_dir [pwd]
set db_dir [file join $work_dir dbs]
set rpt_dir [file join $work_dir reports antenna]

if {![file isdirectory $db_dir]} {
    error "STOP: dbs/ not found"
}
file mkdir $rpt_dir

# 2. Fresh signal-only antenna check
set before_rpt [file join $rpt_dir signal_before.rpt]

puts "===== SIGNAL ANTENNA BEFORE ====="
check_antenna -use signal -out_file $before_rpt

# 3. Parse violating nets and exclude IO PAD nets
set fd [open $before_rpt r]
set content [read $fd]
close $fd

set candidate_nets {}
set pad_nets {}
set current_net ""
set is_pad 0

foreach line [split $content "\n"] {

    if {[regexp {^Net (.+)$} [string trim $line] -> net_name]} {

        if {$current_net ne ""} {
            if {$is_pad} {
                lappend pad_nets $current_net
            } else {
                lappend candidate_nets $current_net
            }
        }

        set current_net $net_name
        set is_pad 0
        continue
    }

    if {[regexp {\bPAD\b} $line]} {
        set is_pad 1
    }
}

if {$current_net ne ""} {
    if {$is_pad} {
        lappend pad_nets $current_net
    } else {
        lappend candidate_nets $current_net
    }
}

set candidate_nets [lsort -unique $candidate_nets]
set pad_nets [lsort -unique $pad_nets]

puts "STANDARD_SIGNAL_NETS=[llength $candidate_nets]"
puts "SKIPPED_IO_PAD_NETS=[llength $pad_nets]"

foreach net $candidate_nets {
    puts "REPAIR_CANDIDATE=$net"
}

if {[llength $candidate_nets] == 0} {
    puts "NO STANDARD SIGNAL CANDIDATES. STOP."
} elseif {[llength $candidate_nets] > 200} {
    error "STOP: Too many candidates; inspect report first"
} else {

    # 4. Resolve all nets before any modification
    set target_objs {}

    foreach net $candidate_nets {
        set obj [get_db nets $net]
        if {[llength $obj] != 1} {
            error "STOP: Cannot resolve net $net"
        }
        lappend target_objs $obj
    }

    # 5. Save checkpoint in dbs/
    set stamp [clock format [clock seconds] -format "%Y%m%d_%H%M%S"]
    set checkpoint [file join $db_dir "TT_SIGNAL_ANT_BEFORE_${stamp}.enc"]

    if {[file exists $checkpoint]} {
        error "STOP: Checkpoint already exists"
    }

    puts "CHECKPOINT=$checkpoint"
    write_db $checkpoint

    if {![file exists $checkpoint]} {
        error "STOP: Checkpoint save failed"
    }

    # 6. Configure routing-only antenna repair
    set_db route_design_detail_fix_antenna true
    set_db route_design_antenna_diode_insertion false
    set_db route_design_detail_fix_antenna_on_secondary_pg_nets false
    set_db route_design_diode_insertion_for_clock_nets false

    # 7. Select violating standard signal nets
    deselect_obj -all

    foreach obj $target_objs {
        select_obj $obj
    }

    puts "===== START SIGNAL ANTENNA REPAIR ====="
    puts "SELECTED_NETS=[llength $target_objs]"

    # 8. Routing
    if {[catch {route_design -selected} route_err]} {
        puts "ROUTING_FAILED=$route_err"
        puts "RESTORE_CHECKPOINT=$checkpoint"
        error "STOP: Selected routing failed"
    }

    deselect_obj -all

    # 9. Signal-only post-check
    puts "===== SIGNAL ANTENNA AFTER ====="

    set after_rpt [file join $rpt_dir signal_after.rpt]
    check_antenna -use signal -out_file $after_rpt

    # 10. Connectivity verification for repaired nets
    puts "===== SIGNAL CONNECTIVITY ====="

    set conn_rpt [file join $rpt_dir signal_connectivity.rpt]

    check_connectivity \
        -type regular \
        -nets $candidate_nets \
        -out_file $conn_rpt

    puts "=================================================="
    puts " SIGNAL ANTENNA BATCH REPAIR ATTEMPT FINISHED"
    puts " BEFORE=$before_rpt"
    puts " AFTER=$after_rpt"
    puts " CONNECTIVITY=$conn_rpt"
    puts " CHECKPOINT=$checkpoint"
    puts "=================================================="
}
