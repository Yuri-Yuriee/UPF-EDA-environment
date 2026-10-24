# Runtime adapter preserves the historical logical source path.
if {[info exists ::TECH_MV_RUNTIME_ROOT]} {
    info script [file join $::TECH_MV_RUNTIME_ROOT run/tool/00_common/TT_pr6_verify_loaded_version.tcl]
} else {
    info script [file normalize [file join [file dirname [info script]] .. .. run/tool/00_common/TT_pr6_verify_loaded_version.tcl]]
}
# Read-only PR6 runtime-memory verifier. Safe to source at any Innovus prompt.
puts "======================================================================"
puts " PR6 LOADED-VERSION CHECK"
puts "======================================================================"
set _want "PR6_V4_4_HARDMACRO_STYLE_DETACH"
set _main_want "V7.11_PR6_V5_SDP_DETAIL_LEGALIZE"
set _have "<missing>"
set _main_have "<missing>"
if {[info exists ::TT_2ROW_SDP_VERSION]} {
    set _main_have $::TT_2ROW_SDP_VERSION
}
puts "2-row flow version      : $_main_have"
puts "Expected 2-row version  : $_main_want"
if {[info exists ::TT_LS_ISO_PADDING_IMPL_VERSION]} {
    set _have $::TT_LS_ISO_PADDING_IMPL_VERSION
}
puts "Padding helper marker : $_have"
puts "Expected marker       : $_want"
set _proc_ok 0
if {[llength [info commands TT_proc_clear_ls_iso_padding_to_names]] > 0 &&
    [llength [info commands TT_proc_pr6_stage01_delete_all_padding]] > 0} {
    set _clear_body  [info body TT_proc_clear_ls_iso_padding_to_names]
    set _delete_body [info body TT_proc_pr6_stage01_delete_all_padding]
    set _has_all [regexp {delete_inst_padding\s+-all} $_delete_body]
    set _has_zero [expr {
        [regexp {set_inst_padding[^\n]*(?:-left_side|-right_side)[^\n]*0} $_clear_body] ||
        [regexp {set_inst_padding[^\n]*(?:-left_side|-right_side)[^\n]*0} $_delete_body]
    }]
    set _has_inst_delete [expr {
        [regexp {delete_inst_padding[^\n]*-inst} $_clear_body] ||
        [regexp {delete_inst_padding[^\n]*-inst} $_delete_body]
    }]
    puts "delete_inst_padding -all loaded : $_has_all"
    puts "zero set_inst_padding loaded    : $_has_zero"
    puts "delete_inst_padding -inst loaded: $_has_inst_delete"
    set _main_proc_ok [expr {[llength [info commands TT_2row_sdp__pr6_detail_legalize]] > 0}]
    puts "V5 detail helper loaded     : $_main_proc_ok"
    if {$_have eq $_want && $_main_have eq $_main_want && $_has_all && !$_has_zero && !$_has_inst_delete && $_main_proc_ok} {
        set _proc_ok 1
    }
} else {
    puts "Required V4.4 cleanup proc(s): NOT LOADED"
}
if {$_proc_ok} {
    puts "PASS: current Innovus memory contains PR6 V4.4 Stage-01 delete-all padding cleanup."
} else {
    puts "FAIL: current Innovus memory is stale or incomplete. Do NOT resume the dirty PR6 flow."
    puts "ACTION: restart/reload from a clean Stage-01 checkpoint so the updated Tcl files are sourced again."
}
puts "======================================================================"
unset -nocomplain _want _main_want _have _main_have _proc_ok _main_proc_ok _clear_body _delete_body _has_all _has_zero _has_inst_delete
