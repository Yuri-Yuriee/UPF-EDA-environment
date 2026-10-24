# Runtime adapter preserves the historical logical source path.
if {[info exists ::TECH_MV_RUNTIME_ROOT]} {
    info script [file join $::TECH_MV_RUNTIME_ROOT run/tool/02_powerplan/sdp/TT_sdp_sw_gap_highlight.tcl]
}
# GUI-only SW-gap locator. Source defines commands; no scan or repair on load.
# Uses the running flow's exact SW-gap checker; no new geometry rules.
proc TT_SW_GAP_highlight_bad {{target_group ""}} {
    foreach command {TT_2row_sdp__scan_switch_gap TT_2row_sdp__flat_group_records TT_2row_sdp__build_inst_lookup TT_2row_sdp__resolve_inst} {
        if {![llength [info commands ::$command]]} {error "Missing running SDP helper: $command. Do not re-run the SDP flow to load it."}
    }
    set result [TT_2row_sdp__scan_switch_gap false]
    set groups [dict get $result groups]
    if {$target_group ne ""} {
        if {$target_group ni $groups} {error "Group '$target_group' is not in the current SW-gap violation list: $groups"}
        set groups [list $target_group]
    }
    # Index 2 is separate from the existing internal-SDP index 1.
    # Do not clear other tools' GUI highlights or selections.
    if {[llength [info commands ::gui_clear_highlight]]} {
        if {[catch {gui_clear_highlight -index 2} message]} {puts "WARN: Cannot clear highlight index 2: $message"}
    }
    TT_2row_sdp__build_inst_lookup exact leaf
    set marked 0
    set failed 0
    set seen {}
    foreach record [TT_2row_sdp__flat_group_records] {
        lassign $record group left center right
        if {$group ni $groups} {continue}
        puts "SW-gap group: $group | members: $left $center $right"
        foreach name [list $left $center $right] {
            set obj [TT_2row_sdp__resolve_inst $name exact leaf]
            if {$obj eq ""} {incr failed; puts "WARN: Cannot resolve member: $name"; continue}
            if {$obj in $seen} {continue}
            lappend seen $obj
            set ok false
            if {[llength [info commands ::gui_highlight]]} {
                if {![catch {gui_highlight -index 2 $obj}]} {set ok true}
            }
            if {!$ok && [llength [info commands ::select_obj]]} {
                if {![catch {select_obj $obj}]} {set ok true}
            }
            if {$ok} {incr marked} else {incr failed; puts "WARN: Cannot highlight/select member: $name"}
        }
    }
    catch {gui_redraw}
    puts "SW-gap locator: pairs=[dict get $result violations] groups=[llength $groups] members_marked=$marked failed=$failed"
    puts "Highlight index: 2 (GUI palette color). Marked members belong to violating groups; this is not a repair."
    puts "Inspect one group: TT_SW_GAP_highlight_bad <group_name>"
    return [dict create pairs [dict get $result violations] groups $groups marked $marked failed $failed]
}

# Read-only pair evidence for the authoritative center-CELL clearance rule (Welltaps excluded).
proc TT_SW_GAP_report_pairs {} {
    foreach command {TT_2row_sdp__scan_switch_gap TT_SWKO__offending_switches TT_2row_sdp__flat_group_records TT_2row_sdp__build_inst_lookup TT_2row_sdp__resolve_inst TT_2row_sdp__rect4 TT_2row_sdp__member_switch_gap_hit} {
        if {![llength [info commands ::$command]]} {error "Missing running flow helper: $command"}
    }
    set scan [TT_2row_sdp__scan_switch_gap false]
    set gap [dict get $scan required_gap]
    set records [dict create]
    foreach rec [TT_2row_sdp__flat_group_records] {dict set records [lindex $rec 0] [lrange $rec 1 end]}
    TT_2row_sdp__build_inst_lookup exact leaf
    set pairs {}
    foreach group [dict get $scan groups] {
        if {![dict exists $records $group]} {error "Missing canonical SDP record: $group"}
        set members {}
        foreach name [dict get $records $group] {
            set obj [TT_2row_sdp__resolve_inst $name exact leaf]
            if {$obj eq ""} {error "Unresolved SDP member: $name"}
            lappend members $obj
        }
        # This helper matches the formal scanner's per-member rule.
        foreach sw [TT_SWKO__offending_switches [list $group] $gap] {
            set sb [TT_2row_sdp__rect4 $sw]
            set hits {}
            foreach obj [list [lindex $members 1]] {
                set bbox [TT_2row_sdp__rect4 $obj]
                if {[llength $bbox] != 4 || [llength $sb] != 4} {error "Invalid live bbox; diagnosis aborted"}
                if {[TT_2row_sdp__member_switch_gap_hit $bbox $sb $gap]} {lappend hits [get_db $obj .name]}
            }
            if {[llength $hits]} {set classification CELL_CLEARANCE_HIT} else {set classification ENVELOPE_ONLY}
            lappend pairs [dict create group $group switch $sw members $members member_hits $hits classification $classification]
            puts "PAIR [llength $pairs]: group=$group switch=[get_db $sw .name] classification=$classification members_hit=$hits"
        }
    }
    if {[llength $pairs] != [dict get $scan violations]} {
        error "Pair diagnostic count disagrees with live scanner; do not use these results to waive violations."
    }
    puts "Pairs: [llength $pairs]. Pair discovery and member tests must agree with the live checker."
    puts "Show one pair: TT_SW_GAP_highlight_pair <pair_number>"
    return $pairs
}

proc TT_SW_GAP_highlight_pair {pair_number} {
    if {![string is integer -strict $pair_number] || $pair_number < 1} {error "Usage: TT_SW_GAP_highlight_pair <positive_pair_number>"}
    set pairs [TT_SW_GAP_report_pairs]
    if {$pair_number > [llength $pairs]} {error "Pair number exceeds current violation pair count"}
    set pair [lindex $pairs [expr {$pair_number-1}]]
    set failed 0
    foreach index {2 3} {catch {gui_clear_highlight -index $index}}
    foreach obj [dict get $pair members] {
        if {[catch {gui_highlight -index 2 $obj} message]} {incr failed;puts "WARN: SDP highlight failed: $message"}
    }
    if {[catch {gui_highlight -index 3 [dict get $pair switch]} message]} {incr failed;puts "WARN: Switch highlight failed: $message"}
    catch {gui_redraw}
    puts "PAIR $pair_number: SDP=index 2, switch=index 3, rule=[dict get $pair classification], highlight_failures=$failed"
    puts "No design edits. GUI palette controls highlight colors."
    return $pair
}
