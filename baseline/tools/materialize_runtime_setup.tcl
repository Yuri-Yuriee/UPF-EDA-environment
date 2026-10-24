# Expand only a newly copied Runtime setup using its own authorized local data.
# Run with tclsh; no EDA command, native design or template write is involved.
if {[llength $argv] != 1} {error "Usage: tclsh materialize_runtime_setup.tcl <build_PR>"}
set materialize_root [file normalize [lindex $argv 0]]
if {[file tail $materialize_root] ne "build_PR"} {error "Expected a build_PR runtime directory."}
set materialize_marker [file join $materialize_root setup .runtime_config_materialized]
if {[file exists $materialize_marker]} {
    puts "Existing materialized Runtime setup retained; no files changed."
    exit 0
}
set materialize_bundle [file join $materialize_root setup config private setup_commands.tcl]
if {![file isfile $materialize_bundle] || [file type $materialize_bundle] eq "link"} {error "Install authorized Runtime private setup first."}
source [file join $materialize_root init.setup]
set materialize_data [source $materialize_bundle]
set materialize_changes [dict create]
foreach materialize_file [lsort [glob -directory [file join $materialize_root setup config] *.config.tcl]] {
    if {[file type $materialize_file] eq "link"} {error "Refusing a symlink configuration."}
    set materialize_f [open $materialize_file r]
    set materialize_text [read $materialize_f];close $materialize_f
    set materialize_lines {}
    foreach materialize_line [split $materialize_text \n] {
        if {[regexp {^(\s*)tech_mv_setup_command\s+(.+)$} $materialize_line -> indent argument]} {
            if {[regexp {^\$::TECH_MV_LIBRARY_CONFIG\((\w+)\)$} $argument -> index]} {
                set materialize_key $::TECH_MV_LIBRARY_CONFIG($index)
            } else {
                if {[llength $argument] != 1} {error "Unsupported setup key expression."}
                set materialize_key [lindex $argument 0]
            }
            if {![dict exists $materialize_data $materialize_key]} {error "Required Runtime setup key missing."}
            set materialize_line "$indent[dict get $materialize_data $materialize_key]"
        }
        # Replace only a whole RHS, never a substring inside a formula or quoted text.
        # An expanded setup entry can contain more than one original line.
        set expanded_lines {}
        foreach expanded_line [split $materialize_line \n] {
            if {[regexp {^(\s*set\s+)(\S+)(\s+)\[::?tech_mv_private_value\s+\{[^{}]+\}\](\s*)$} $expanded_line -> prefix variable space suffix]} {
                if {![info exists $variable] || [array exists $variable]} {error "Cannot materialize unresolved Runtime assignment."}
                set expanded_line "$prefix$variable$space[list [set $variable]]$suffix"
            }
            if {[regexp {^(\s*set\s+)(\S+)(\s+)\[::tech_mv_library_value\s+\w+\](\s*)$} $expanded_line -> prefix variable space suffix]} {
                if {![info exists $variable] || [array exists $variable]} {error "Cannot materialize unresolved Library assignment."}
                set expanded_line "$prefix$variable$space[list [set $variable]]$suffix"
            }
            lappend expanded_lines $expanded_line
        }
        lappend materialize_lines [join $expanded_lines \n]
    }
    set materialize_new [join $materialize_lines \n]
    if {[file tail $materialize_file] eq "00_library.config.tcl" && ![regexp {(?m)^array set ::TECH_MV_LIBRARY_VALUES } $materialize_new]} {
        set materialize_header "# PRIVATE RUNTIME Library values; edit locally, never publish.\narray unset ::TECH_MV_LIBRARY_VALUES\narray set ::TECH_MV_LIBRARY_VALUES \{\n"
        dict for {key value} $materialize_data {
            if {[string match library_value::* $key]} {
                append materialize_header "    [list [string range $key 15 end] $value]\n"
            }
        }
        append materialize_header "\}\n\n"
        set materialize_new "$materialize_header$materialize_new"
    }
    if {[file tail $materialize_file] eq "00_design.config.tcl" && ![string match {*Preserve the existing reviewed-geometry provenance warning.*} $materialize_new]} {
        set materialize_new "# Preserve the existing reviewed-geometry provenance warning.\nsource \[file join \[file dirname \[info script\]\] geometry_review.config.tcl\]\n\n$materialize_new"
    }
    if {![info complete $materialize_new]} {error "Incomplete materialized Tcl; no files written."}
    if {$materialize_new ne $materialize_text} {dict set materialize_changes $materialize_file $materialize_new}
}
# Reviewed geometry is installed directly in setup/config; preserve local edits.
# Keep all original newly copied files for restoration; never touch an existing backup.
set materialize_backup [file join $materialize_root .backup setup_materialized_[clock clicks]_[pid]]
dict for {path text} $materialize_changes {
    set saved [file join $materialize_backup [file tail $path]]
    file mkdir $materialize_backup
    file copy $path $saved
}
dict for {path text} $materialize_changes {
    set materialize_f [open $path w];puts -nonewline $materialize_f $text;close $materialize_f
    file attributes $path -permissions 0600
}
# Capture each new design's own configured baseline before native queries exist.
set materialize_probe [file join $materialize_root run tool 00_common TT_config_probe.tcl]
set materialize_golden [file join $materialize_root setup config config_probe.golden.list]
if {[file isfile $materialize_probe] && ![file exists $materialize_golden]} {
    source [file join $materialize_root init.setup]
    source $materialize_probe
    TT_config_golden
}
set materialize_f [open $materialize_marker {WRONLY CREAT EXCL} 0600]
puts $materialize_f "Runtime config materialized; subsequent user edits must be retained."
close $materialize_f
puts "New Runtime setup materialized locally; [dict size $materialize_changes] files, originals retained."
