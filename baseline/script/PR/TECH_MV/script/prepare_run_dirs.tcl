# Runtime output directories.
foreach dir [list $DB_DIR $OUTPUT_DIR $REPORT_DIR $LOG_DIR $TEMP_DIR] {
    file mkdir $dir
}

# Standard report hierarchy.
foreach report_stage {00 01 02 03 04 05 06 90 91} {
    tech_mv_report_dir $report_stage
}
