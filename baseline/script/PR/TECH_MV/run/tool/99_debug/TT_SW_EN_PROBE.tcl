# Runtime adapter preserves the historical logical source path.
if {[info exists ::TECH_MV_RUNTIME_ROOT]} {
    info script [file join $::TECH_MV_RUNTIME_ROOT run/tool/99_debug/TT_SW_EN_PROBE.tcl]
}
if {![llength [info commands ::tech_mv_library_value]]} {
    if {[info exists ::TOOL_DIR]} {source -quiet [file join $::TECH_MV_RUNTIME_ROOT .. script PR TECH_MV script 00_common private_parameter_config.tcl]} else {source -quiet [file join $::TECH_MV_RUNTIME_ROOT .. script PR TECH_MV script 00_common private_parameter_config.tcl]}
}
# Source in Innovus Common UI after loading DB. Read only; no DB modifications.
# Usage: source innovus_sw_en_probe.tcl
#        TT_SW_EN_PROBE  /path/to/source_sw_chain.tsv  C01  0  8
# Output: per-instance actual full name, place status, location, configured switch control-pin nets.
proc TT_SW_EN_PROBE {tsv {wanted_chain C01} {start_index 0} {max_count 8}} {
    if {![file exists $tsv]} {error "Missing $tsv"}
    set fp [open $tsv r]
    gets $fp header
    set targets {}
    while {[gets $fp line] >= 0} {
        set col [split $line "\t"]
        if {[llength $col] < 9} {continue}
        lassign $col chain step len spi cand enin enout tvdd vdd
        if {$chain ne $wanted_chain} {continue}
        if {$step < $start_index || $step >= ($start_index + $max_count)} {continue}
        lappend targets [list $step $cand $enin $enout]
    }
    close $fp
    puts "===== SW EN PROBE chain=$wanted_chain index=$start_index count=$max_count ====="
    # Index design instances once; avoid O(Ninst * Ntarget) scans.
    set by_tail [dict create]
    foreach inst [get_db insts] {
        set n [get_db $inst .name]
        set tail [lindex [split $n /] end]
        dict lappend by_tail $tail $inst
    }
    foreach item $targets {
        lassign $item step cand srcin srcout
        set matches {}
        if {[dict exists $by_tail $cand]} {set matches [dict get $by_tail $cand]}
        puts "STEP=$step SOURCE_INST=$cand SOURCE_ENIN=$srcin SOURCE_ENOUT=$srcout MATCHES=[llength $matches]"
        foreach inst $matches {
            puts "  INST=[get_db $inst .name] PLACE=[get_db $inst .place_status] LOC=[get_db $inst .location]"
            foreach p [get_db $inst .pins] {
                set pn [get_db $p .name]
                if {![regexp [::tech_mv_library_value DEBUG_SWITCH_CHAIN_PIN_PATTERN] $pn]} {continue}
                set net [get_db $p .net]
                if {[llength $net]} {set nn [get_db $net .name]} else {set nn "<NO_NET>"}
                puts "    PIN=$pn NET=$nn"
            }
        }
    }
    puts "===== END SW EN PROBE ====="
}
