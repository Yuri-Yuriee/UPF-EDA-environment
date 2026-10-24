# Runtime adapter preserves the historical logical source path.
if {[info exists ::TECH_MV_RUNTIME_ROOT]} {
    info script [file join $::TECH_MV_RUNTIME_ROOT run/tool/00_common/TT_runtime_output_helpers.tcl]
}
# Runtime output policy; no EDA commands execute when this file is sourced.
proc tech_mv_output_path {kind name {stage 90} {category generated}} {
    if {[file tail $name] ne $name || $name in {. ..} || $name eq ""} {
        error "Output name must be a filename, not a path: $name"
    }
    switch -- $kind {
        report { set dir [tech_mv_report_dir $stage $category] }
        log {
            if {[info exists ::LOG_DIR]} { set root $::LOG_DIR } else { set root [file normalize logs] }
            set dir [file join $root [tech_mv_report_stage_name $stage] [tech_mv_report_safe_name $category]]
        }
        temp {
            if {[info exists ::TEMP_DIR]} { set root $::TEMP_DIR } else { set root [file normalize .temp] }
            set dir [file join $root [tech_mv_report_stage_name $stage] [tech_mv_report_safe_name $category]]
        }
        default { error "Unknown output kind '$kind'." }
    }
    file mkdir $dir
    return [file normalize [file join $dir $name]]
}

# Manual saves never overwrite a formal restore checkpoint or an earlier save.
proc FP_save {{label manual_edit} {step 98}} {
    if {![string is integer -strict $step] || $step < 0} { error "Invalid FP step '$step'." }
    if {![info exists ::DB_DIR]} { error "FP_save requires runtime init.setup." }
    if {[llength [info commands write_db]] == 0} { error "write_db is unavailable." }
    set label [tech_mv_report_safe_name $label]
    if {$label eq ""} { error "FP save label is empty." }
    file mkdir $::DB_DIR
    set stem [format "01_%02d_%s_%s_%s" $step $label [clock format [clock seconds] -format %Y%m%d_%H%M%S] [clock clicks -microseconds]]
    set path [file join $::DB_DIR ${stem}.enc]
    set suffix 0
    while {[file exists $path]} { incr suffix; set path [file join $::DB_DIR ${stem}_${suffix}.enc] }
    write_db $path
    set ::FP_LAST_MANUAL_DB [file normalize $path]
    puts "INFO: Floorplan snapshot saved: $::FP_LAST_MANUAL_DB"
    return $::FP_LAST_MANUAL_DB
}

# Run the existing check exactly once and capture its own output, never an old
# report selected by glob/mtime. EDA errors still propagate to the caller.
proc tech_mv_check_drc {args} {
    set stage 90
    if {[info exists ::TECH_MV_REPORT_STAGE]} { set stage $::TECH_MV_REPORT_STAGE }
    unset -nocomplain ::TECH_MV_LATEST_DRC_SUMMARY($stage)
    unset -nocomplain ::TECH_MV_LAST_DRC_RESULT
    set text ""
    set token "[clock clicks -microseconds]_[pid]"
    set raw [tech_mv_output_path report "${stage}_99_drc_${token}.rpt" $stage drc]
    set summary [tech_mv_output_path report "${stage}_99_drc_${token}.summary" $stage drc]
    # Current flow calls have no file inputs; confine native reports to this check directory.
    # Preserve the original cwd for explicit argument calls, whose input paths may be relative.
    set saved_pwd [pwd]
    if {[llength $args] == 0} { cd [file dirname $raw] }
    set rc [catch {redirect text [linsert $args 0 check_drc] -variable -tee} result opts]
    cd $saved_pwd
    set f [open $raw w]; puts -nonewline $f $text; close $f
    if {$rc} { return -options $opts $result }
    # Only the current captured native completion line determines this run's count.
    # DB markers can include other originators and must never substitute for it.
    set native_count ""
    foreach line [split $text "\n"] {
        if {[regexp -nocase {Verification\s+Complete\s*:\s*([0-9]+)\s+Viols\.?} $line -> count]} {
            scan $count %d native_count
        }
    }
    set markers [get_db current_design .markers]
    set counts [dict create]
    foreach marker $markers {
        set subtype UNKNOWN
        catch { set subtype [get_db $marker .subtype] }
        dict incr counts $subtype
    }
    set f [open $summary w]
    puts $f "LATEST COMPLETED CHECK_DRC : STAGE $stage"
    puts $f "Captured at : [clock format [clock seconds] -format {%Y-%m-%d %H:%M:%S}]"
    puts $f "Raw output  : $raw"
    puts $f "Native check_drc violations : $native_count"
    puts $f "Live design markers after check : [llength $markers]"
    puts $f "Marker counts include all current marker originators; see raw check_drc for native DRC totals."
    dict for {type count} $counts { puts $f "$type : $count" }
    set native_lines {}
    foreach line [split $text "\n"] {
        if {[regexp -nocase {total|violation|error|warning|drc|finished} $line]} { lappend native_lines $line }
    }
    puts $f "\nNative output (last matching summary lines):"
    foreach line [lrange $native_lines end-39 end] { puts $f $line }
    close $f
    set ::TECH_MV_LATEST_DRC_SUMMARY($stage) $summary
    if {$native_count eq ""} {
        error "Cannot parse this check_drc native completion count; see $raw. DB marker count is not a DRC result."
    }
    set ::TECH_MV_LAST_DRC_RESULT [dict create count $native_count raw $raw summary $summary marker_count [llength $markers]]
    return $result
}

# Native SDP report path only; preserves the existing design-name convention.
proc tech_mv_native_sdp_report_path {} {
    set design "CHIP"
    catch {set design [get_db current_design .name]}
    if {$design eq ""} { set design "CHIP" }
    return [tech_mv_output_path report "${design}.checkSdp.rpt" 02 sdp]
}

# Confine native side reports for known commands without file inputs.
# Only the invocation runs in this directory; caller cwd and Tcl scope survive.
proc tech_mv_native_report_command {stage category command_list} {
    if {[lindex $command_list 0] ni {add_power_mesh_colors check_netlist fix_via}} {
        error "Unsupported scoped report command: [lindex $command_list 0]"
    }
    set dir [file dirname [tech_mv_output_path report .native_output_anchor $stage $category]]
    set saved_pwd [pwd]
    cd $dir
    set rc [catch {uplevel 1 $command_list} result options]
    cd $saved_pwd
    if {$rc} {return -options $options $result}
    return $result
}
