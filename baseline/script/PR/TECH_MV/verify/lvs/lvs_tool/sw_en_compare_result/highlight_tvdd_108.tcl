# Innovus Stylus Common UI, read-only database; GUI highlighting only.
# Usage: source /path/to/highlight_tvdd_108.tcl
#        TT_HIGHLIGHT_TVDD_108 /path/to/sw_tvdd_108_innovus_candidates.csv
# Names are cross-matched from extracted layout SW chain C18 and source SW chain C18;
# verify placement coordinate and expected TVDD net on live DB before marking.
proc TT_HIGHLIGHT_TVDD_108 {csv_path} {
    if {![file exists $csv_path]} {error "Missing CSV: $csv_path"}
    set fp [open $csv_path r]
    set head [split [gets $fp] ","]
    set ni [lsearch -exact $head source_inst]
    set xi [lsearch -exact $head source_x]
    set yi [lsearch -exact $head source_y]
    if {$ni < 0 || $xi < 0 || $yi < 0} {close $fp; error "CSV header mismatch"}
    set wants {}
    while {[gets $fp l] >= 0} {
        if {[string trim $l] eq ""} {continue}
        set cols [split $l ","]
        lappend wants [list [lindex $cols $ni] [lindex $cols $xi] [lindex $cols $yi]]
    }
    close $fp
    set lookup [dict create]
    foreach inst [get_db insts] {
        set n [get_db $inst .name]
        dict lappend lookup [lindex [split $n /] end] $inst
    }
    set approved {}; set rejects {}; set missing 0
    foreach w $wants {
        lassign $w name sx sy
        if {![dict exists $lookup $name]} {incr missing; lappend rejects "NOT_FOUND $name"; continue}
        set hits [dict get $lookup $name]
        if {[llength $hits] != 1} {lappend rejects "AMBIGUOUS $name"; continue}
        set inst [lindex $hits 0]
        # Innovus may return an outer-braced coordinate object: {{x y}}.
        # Convert using a numeric-only parser rather than Tcl list length.
        set raw_xy [get_db $inst .location]
        set nums [regexp -all -inline {[-+]?[0-9]+(?:\.[0-9]+)?(?:[eE][-+]?[0-9]+)?} $raw_xy]
        if {[llength $nums] != 2} {
            lappend rejects "NO_LOCATION $name raw=<$raw_xy>"
            continue
        }
        set ax [lindex $nums 0]
        set ay [lindex $nums 1]
        set dist [expr {hypot(double($ax)-double($sx),double($ay)-double($sy))}]
        # The source names contain rounded placement coordinates. Allow up to [請填入本地確認的尺寸];
        # this is only a sanity gate, not a proof of equal layout/source instances.
        if {$dist > 3.0} {lappend rejects "POSITION_MISMATCH $name delta=$dist"; continue}
        set tvdd "<NOT_FOUND>"
        foreach p [get_db $inst .pins] {
            if {[regexp {(^|/)TVDD$} [get_db $p .name]]} {
                set net [get_db $p .net]
                if {[llength $net]} {set tvdd [get_db $net .name]} else {set tvdd "<NO_NET>"}
            }
        }
        lappend approved [list $inst $name $dist $tvdd]
    }
    puts "============================================================"
    puts "TVDD LAYOUT DISCONNECT CANDIDATES: expected [llength $wants]"
    puts "DB name+location matched: [llength $approved]"
    puts "Rejected: [llength $rejects] (not found $missing)"
    foreach r $rejects {puts "WARN: $r"}
    puts "============================================================"
    # Do not highlight a partial set, preventing misleading visual conclusions.
    if {[llength $approved] != [llength $wants]} {
        puts "STOP: incomplete mapping; NO highlight applied."
        return
    }
    set method ""
    set done 0
    foreach row $approved {
        lassign $row inst name dist tvdd
        if {$method eq ""} {
            if {![catch {gui_highlight -index 1 $inst} err]} {
                set method "gui_highlight"; incr done
            } elseif {![catch {select_obj $inst} err2]} {
                set method "select_obj"; incr done
                puts "WARN: gui_highlight -index not supported; falling back to GUI selection."
            } else {puts "ERROR: Neither gui_highlight nor select_obj worked: $err | $err2";return}
        } elseif {$method eq "gui_highlight"} {
            if {[catch {gui_highlight -index 1 $inst} err]} {puts "ERROR: $name : $err"} else {incr done}
        } else {
            if {[catch {select_obj $inst} err]} {puts "ERROR: $name : $err"} else {incr done}
        }
        puts "TARGET $name  location_delta_um=[format %.3f $dist]  Innovus_TVDD=$tvdd"
    }
    puts "DONE: marked $done / [llength $wants] using $method"
    puts "NOTE: Source/DB TVDD may say VDD_LEVEL_01 even though extracted GDS TVDD is disconnected."
}
