#!/usr/bin/tclsh

# TECH automatic HCELL generator with independently controlled LVS BOX list.
#
# HCELL:
#   Generated from macro LEFs (same historical policy as before).
#
# LVSBOX:
#   Generated ONLY from scr/lvsbox_cells.list.
#   This is intentionally NOT copied from the HCELL list.  Standard cells can
#   share well/body connectivity across cell boundaries; black-boxing every
#   HCELL can expose those physical well/body nodes as extra numeric terminals.

# Path tokens are data expanded from the existing C-shell Verify config.
proc verify_expand_resource_paths {text} {
    foreach key [array names ::env VERIFY_RESOURCE_PATH_*] {
        set text [string map [list "@$key@" $::env($key)] $text]
    }
    if {[regexp {@VERIFY_RESOURCE_PATH_[0-9]+@} $text]} {
        error "Verify resource path is not configured; source verify/config.csh first."
    }
    return $text
}

set script_dir   [file dirname [file normalize [info script]]]
set lvs_dir      [file normalize [file join $script_dir ..]]
set ::VERIFY_HCELL_POLICY [source [file join $script_dir .. .. config hcell_policy.tcl]]
if {![info exists ::env(VERIFY_HCELL_LEF_LIST)] || ![file isfile $::env(VERIFY_HCELL_LEF_LIST)]} {error "Required Verify config file is missing: VERIFY_HCELL_LEF_LIST"}
set list_file $::env(VERIFY_HCELL_LEF_LIST)
if {![info exists ::env(VERIFY_LVSBOX_CELLS_LIST)] || ![file isfile $::env(VERIFY_LVSBOX_CELLS_LIST)]} {error "Required Verify config file is missing: VERIFY_LVSBOX_CELLS_LIST"}
set box_list $::env(VERIFY_LVSBOX_CELLS_LIST)
if {![info exists ::env(VERIFY_HCELL_EXCLUDE_LIST)] || ![file isfile $::env(VERIFY_HCELL_EXCLUDE_LIST)]} {error "Required Verify config file is missing: VERIFY_HCELL_EXCLUDE_LIST"}
set exclude_list $::env(VERIFY_HCELL_EXCLUDE_LIST)
set hcell_file   [file join $lvs_dir HCELL]
set box_file     [file join $lvs_dir LVSBOX]
set rpt_dir      [file join $lvs_dir rpt]
set rpt_file     [file join $rpt_dir hcell_generation.rpt]

file mkdir $rpt_dir

proc read_noncomment_lines {path} {
    set fh [open $path r]
    set out {}
    while {[gets $fh line] >= 0} {
        set line [string trim [verify_expand_resource_paths $line]]
        if {$line eq ""} { continue }
        if {[string match "#*" $line]} { continue }
        lappend out $line
    }
    close $fh
    return $out
}

proc extract_macros {lef} {
    set fh [open $lef r]
    set cells {}
    while {[gets $fh line] >= 0} {
        if {[regexp {^[ \t]*MACRO[ \t]+([^ \t]+)} $line -> cell]} {
            lappend cells $cell
        }
    }
    close $fh
    return $cells
}

proc skip_hcell {cell} {
    # Preserve the existing TECH reference Hcell exclusions.
    if {$cell eq [lindex [dict get $::VERIFY_HCELL_POLICY exact] 0]}   { return 1 }
    if {$cell eq [lindex [dict get $::VERIFY_HCELL_POLICY exact] 1]} { return 1 }
    if {[regexp [lindex [dict get $::VERIFY_HCELL_POLICY patterns] 0] $cell]} { return 1 }
    if {[regexp [lindex [dict get $::VERIFY_HCELL_POLICY patterns] 1]      $cell]} { return 1 }
    if {[regexp [lindex [dict get $::VERIFY_HCELL_POLICY patterns] 2]     $cell]} { return 1 }
    if {[regexp [lindex [dict get $::VERIFY_HCELL_POLICY patterns] 3]       $cell]} { return 1 }
    return 0
}

if {![file exists $list_file]} {
    puts stderr "ERROR: HCELL LEF list not found: $list_file"
    exit 1
}

set lefs [read_noncomment_lines $list_file]
set all_cells {}
set missing {}

foreach lef $lefs {
    if {![file exists $lef]} {
        lappend missing $lef
        continue
    }
    foreach cell [extract_macros $lef] {
        if {![skip_hcell $cell]} {
            lappend all_cells $cell
        }
    }
}

if {[llength $missing] > 0} {
    puts stderr "ERROR: Hcell LEF files are missing:"
    foreach x $missing { puts stderr "  $x" }
    exit 1
}

set cells [lsort -unique $all_cells]

# Exact opt-out list for cells that are not self-contained HCELLs.
# These cells remain in the full-chip layout/source hierarchy so Calibre can
# resolve abutment/well/body connectivity using surrounding context.
set excluded_cells {}
if {[file exists $exclude_list]} {
    set excluded_cells [lsort -unique [read_noncomment_lines $exclude_list]]
}
set exclude_set [dict create]
foreach cell $excluded_cells { dict set exclude_set $cell 1 }
set filtered_cells {}
foreach cell $cells {
    if {![dict exists $exclude_set $cell]} {
        lappend filtered_cells $cell
    }
}
set cells $filtered_cells

# Explicit opt-in BOX cells only.  An absent list is treated as empty to keep
# the safe default: HCELL correspondence without global standard-cell boxing.
set box_cells {}
if {[file exists $box_list]} {
    set box_cells [lsort -unique [read_noncomment_lines $box_list]]
}

set hf [open $hcell_file w]
foreach cell $cells {
    puts $hf "$cell $cell"
}
close $hf

set bf [open $box_file w]
foreach cell $box_cells {
    puts $bf "LVS BOX $cell"
}
close $bf

# Report BOX names that are not in the generated HCELL set.  This is not fatal:
# a project may intentionally BOX a special macro that is not present in the
# LEF-derived HCELL list.
set hcell_set [dict create]
foreach cell $cells { dict set hcell_set $cell 1 }
set box_not_hcell {}
foreach cell $box_cells {
    if {![dict exists $hcell_set $cell]} {
        lappend box_not_hcell $cell
    }
}

set rf [open $rpt_file w]
puts $rf "TECH_MV Hcell / LVSBOX Generation"
puts $rf "================================="
puts $rf "LEF count      : [llength $lefs]"
puts $rf "HCELL count    : [llength $cells]"
puts $rf "LVSBOX count   : [llength $box_cells]"
puts $rf "LVSBOX list    : $box_list"
puts $rf "HCELL exclude  : $exclude_list"
puts $rf ""
puts $rf "Policy:"
puts $rf "  HCELL  = LEF-derived hierarchical correspondence"
puts $rf "  LVSBOX = explicit opt-in cells from lvsbox_cells.list only"
puts $rf ""
puts $rf "Exact HCELL exclusions requiring full-chip context:"
if {[llength $excluded_cells] == 0} {
    puts $rf "  <none>"
} else {
    foreach cell $excluded_cells { puts $rf "  $cell" }
}
puts $rf ""
puts $rf "Excluded physical-only HCELL patterns:"
puts $rf "  [lindex [dict get $::VERIFY_HCELL_POLICY report_labels] 0]"
puts $rf "  [lindex [dict get $::VERIFY_HCELL_POLICY report_labels] 1]"
puts $rf "  [lindex [dict get $::VERIFY_HCELL_POLICY report_labels] 2]"
puts $rf "  [lindex [dict get $::VERIFY_HCELL_POLICY report_labels] 3]"
puts $rf "  [lindex [dict get $::VERIFY_HCELL_POLICY report_labels] 4]"
puts $rf "  [lindex [dict get $::VERIFY_HCELL_POLICY report_labels] 5]"
puts $rf ""
puts $rf "Explicit LVSBOX cells:"
if {[llength $box_cells] == 0} {
    puts $rf "  <none>"
} else {
    foreach cell $box_cells { puts $rf "  $cell" }
}
puts $rf ""
puts $rf "LVSBOX cells not present in generated HCELL list:"
if {[llength $box_not_hcell] == 0} {
    puts $rf "  <none>"
} else {
    foreach cell $box_not_hcell { puts $rf "  $cell" }
}
puts $rf ""
puts $rf "LEFs:"
foreach lef $lefs { puts $rf "  $lef" }
close $rf

puts "Generated $hcell_file"
puts "Generated $box_file"
puts "HCELL count  = [llength $cells]"
puts "LVSBOX count = [llength $box_cells]"
