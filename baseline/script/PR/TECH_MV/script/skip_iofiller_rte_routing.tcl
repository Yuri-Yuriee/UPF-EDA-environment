# =============================================================================
# skip_iofiller_rte_routing.tcl
# =============================================================================
# Prevent automatic signal routing of nets connected to an instance pin whose
# leaf pin name is exactly "configured IO pin".
#
# Why pin-first discovery:
#   The IO filler master names in the loaded design are not guaranteed to
#   contain the literal string "IOFILLER". Therefore master-name matching can
#   return zero even when the relevant IO filler cells exist.
#
# This helper intentionally does NOT depend on:
#   - a hard-coded signal net name such as "io_rte"
#   - an IOFILLER master-name pattern
#
# Instead:
#   design instance pin */configured IO pin -> actual connected net object -> skip_routing
#
# Only exact leaf pin name "configured IO pin" is accepted. nonmatching pin names / nonmatching pin names are not accepted.
# =============================================================================

proc tech_mv_skip_iofiller_rte_routing {} {
    set report_file [tech_mv_report_path 15 iofiller_rte_skip_routing rpt 05]

    file mkdir [file dirname $report_file]
    set fp [open $report_file w]

    puts $fp "IOFILLER ${::RTE_PAD_PIN} routing exclusion"
    puts $fp "Selection method : exact instance leaf pin ${::RTE_PAD_PIN} -> connected net object"
    puts $fp "Master-name match: NONE"
    puts $fp "Net-name match   : NONE"
    puts $fp ""

    # -------------------------------------------------------------------------
    # 1. Discover candidate pins efficiently by wildcard first.
    #    If the current DB wildcard behavior returns nothing, fall back to
    #    enumerating all pins and checking the leaf pin name exactly.
    # -------------------------------------------------------------------------
    set candidate_pins {}

    foreach pattern [list "*/$::RTE_PAD_PIN" "*$::RTE_PAD_PIN"] {
        set found {}
        catch {set found [get_db pins $pattern]}
        foreach pin $found {
            if {[lsearch -exact $candidate_pins $pin] < 0} {
                lappend candidate_pins $pin
            }
        }
    }

    set used_full_scan 0
    if {[llength $candidate_pins] == 0} {
        set used_full_scan 1
        catch {set candidate_pins [get_db pins]}
    }

    # -------------------------------------------------------------------------
    # 2. Keep only INSTANCE pins whose leaf name is exactly configured IO pin.
    #    A hierarchical instance pin must contain "/" in its DB name.
    # -------------------------------------------------------------------------
    set rte_pins {}
    set rte_inst_names {}
    set seen_pins [dict create]
    set seen_insts [dict create]

    foreach pin $candidate_pins {
        set pin_name ""
        catch {set pin_name [get_db $pin .name]}
        if {$pin_name eq ""} {
            continue
        }

        set parts [split $pin_name "/"]
        set leaf [lindex $parts end]

        if {$leaf ne $::RTE_PAD_PIN} {
            continue
        }

        # Exclude a possible top-level port/pin named simply configured IO pin.
        if {[llength $parts] < 2} {
            continue
        }

        if {[dict exists $seen_pins $pin]} {
            continue
        }
        dict set seen_pins $pin 1
        lappend rte_pins $pin

        set inst_name [join [lrange $parts 0 end-1] "/"]
        if {![dict exists $seen_insts $inst_name]} {
            dict set seen_insts $inst_name 1
            lappend rte_inst_names $inst_name
        }
    }

    # -------------------------------------------------------------------------
    # 3. Follow each configured IO pin pin to the ACTUAL connected net object.
    # -------------------------------------------------------------------------
    set unconn_count 0
    set unique_nets {}
    set seen_nets [dict create]

    foreach pin $rte_pins {
        set pin_name ""
        catch {set pin_name [get_db $pin .name]}

        set net_obj {}
        catch {set net_obj [get_db $pin .net]}

        if {[llength $net_obj] == 0} {
            incr unconn_count
            puts $fp "INFO unconnected_RTE pin=$pin_name object=$pin"
            continue
        }

        foreach net $net_obj {
            if {[dict exists $seen_nets $net]} {
                continue
            }
            dict set seen_nets $net 1
            lappend unique_nets $net
        }
    }

    # -------------------------------------------------------------------------
    # 4. Apply skip_routing to the actual connected net objects.
    # -------------------------------------------------------------------------
    set applied_count 0
    set failed_count 0

    foreach net $unique_nets {
        set net_name ""
        catch {set net_name [get_db $net .name]}

        if {[catch {set_db $net .skip_routing true} err]} {
            incr failed_count
            puts $fp "FAIL net=$net_name object=$net error={$err}"
            continue
        }

        incr applied_count
        puts $fp "SKIP_ROUTING net=$net_name object=$net"
    }

    # -------------------------------------------------------------------------
    # 5. Detailed configured IO pin-pin report.
    # -------------------------------------------------------------------------
    puts $fp ""
    puts $fp "${::RTE_PAD_PIN} instance pins:"
    foreach pin $rte_pins {
        set pin_name ""
        set net_name ""
        catch {set pin_name [get_db $pin .name]}
        set net_obj {}
        catch {set net_obj [get_db $pin .net]}
        if {[llength $net_obj] > 0} {
            catch {set net_name [get_db [lindex $net_obj 0] .name]}
        }
        puts $fp "  pin=$pin_name  net=$net_name  pin_obj=$pin"
    }

    puts $fp ""
    puts $fp "======================================================================"
    puts $fp "Summary"
    puts $fp "======================================================================"
    puts $fp "Candidate pins scanned  : [llength $candidate_pins]"
    puts $fp "Fallback full pin scan  : $used_full_scan"
    puts $fp "${::RTE_PAD_PIN}-bearing instances   : [llength $rte_inst_names]"
    puts $fp "Exact ${::RTE_PAD_PIN} pins found    : [llength $rte_pins]"
    puts $fp "Unconnected ${::RTE_PAD_PIN} pins    : $unconn_count"
    puts $fp "Unique connected nets   : [llength $unique_nets]"
    puts $fp "skip_routing applied    : $applied_count"
    puts $fp "Failures                : $failed_count"
    puts $fp "Report                  : $report_file"
    close $fp

    puts ""
    puts "======================================================================"
    puts " IOFILLER ${::RTE_PAD_PIN} Routing Exclusion (Pin-Driven)"
    puts "======================================================================"
    puts "Candidate pins scanned  : [llength $candidate_pins]"
    puts "Fallback full pin scan  : $used_full_scan"
    puts "${::RTE_PAD_PIN}-bearing instances   : [llength $rte_inst_names]"
    puts "Exact ${::RTE_PAD_PIN} pins found    : [llength $rte_pins]"
    puts "Unconnected ${::RTE_PAD_PIN} pins    : $unconn_count"
    puts "Unique connected nets   : [llength $unique_nets]"
    puts "skip_routing applied    : $applied_count"
    puts "Failures                : $failed_count"
    puts "Report                  : $report_file"
    puts "======================================================================"

    if {[llength $rte_pins] == 0} {
        error "No exact instance ${::RTE_PAD_PIN} pins were found. Refusing to continue with an unverified routing exclusion."
    }
    if {[llength $unique_nets] == 0} {
        error "${::RTE_PAD_PIN} pins were found, but none is connected to a net. Refusing to continue."
    }
    if {$failed_count > 0} {
        error "Failed to set skip_routing on $failed_count ${::RTE_PAD_PIN}-connected net(s). See $report_file"
    }

    return $applied_count
}
