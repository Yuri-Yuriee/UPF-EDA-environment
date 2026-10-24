# Runtime adapter preserves the historical logical source path.
if {[info exists ::TECH_MV_RUNTIME_ROOT]} {
    info script [file join $::TECH_MV_RUNTIME_ROOT run/tool/06_finish/export/TT_export_streamout.tcl]
}
# =============================================================================
# TECH_MV stream-out
# =============================================================================
if {![file isfile $STREAM_OUT_MAP_SOURCE]} {
    error "FILL_IN_PROCESS_VARIANT stream-out map does not exist: $STREAM_OUT_MAP_SOURCE"
}
foreach gds $STREAM_MERGE_GDS_FILES {
    if {[regexp -nocase {REFERENCE_PLATFORM} $gds]} {
        error "REFERENCE_PLATFORM merge GDS is forbidden in TECH_MV: $gds"
    }
    if {![file isfile $gds]} {
        error "Stream merge GDS does not exist: $gds"
    }
}

file mkdir [file dirname $STREAM_OUT_MAP_FILE]
file copy -force $STREAM_OUT_MAP_SOURCE $STREAM_OUT_MAP_FILE
set outfile [open $STREAM_OUT_MAP_FILE a]
foreach line $STREAM_OUT_CUSTOM_MAP_LINES {
    puts $outfile $line
}
close $outfile

set_db write_stream_text_size $STREAM_OUT_TEXT_SIZE
write_stream [file join $OUTPUT_DIR ${TOP_MODULE}.gds] \
    -map_file $STREAM_OUT_MAP_FILE \
    -lib_name $STREAM_OUT_LIB_NAME \
    -merge $STREAM_MERGE_GDS_FILES \
    -uniquify_cell_names \
    -unit $STREAM_OUT_UNIT \
    -mode $STREAM_OUT_MODE \
    -report_file [tech_mv_report_path 50 write_stream rpt 06]
