# =============================================================================
# report_utils.tcl
# =============================================================================
# Central report naming policy.
#
# Every generated APR report/result directory lives below $REPORT_DIR.
#
# reports/
#   00_import/ 01_floorplan/ 02_powerplan/ 03_place/
#   04_cts/    05_route/     06_finish/
#   90_debug/  91_analysis/
#
# File naming: <stage>_<step>_<name>.<ext>
# =============================================================================

proc tech_mv_report_safe_name {name} {
    set safe $name
    regsub -all {[^A-Za-z0-9_.-]+} $safe {_} safe
    return [string trim $safe _]
}

proc tech_mv_report_stage_name {stage} {
    switch -- $stage {
        00 { return 00_import }
        01 { return 01_floorplan }
        02 { return 02_powerplan }
        03 { return 03_place }
        04 { return 04_cts }
        05 { return 05_route }
        06 { return 06_finish }
        90 { return 90_debug }
        91 { return 91_analysis }
        default { error "Unknown report stage '$stage'. Expected 00-06, 90, or 91." }
    }
}

proc tech_mv_report_stage_from_tag {tag {fallback 90}} {
    if {[regexp {^([0-9][0-9])(?:_|$)} $tag -> stage]} {
        if {$stage in {00 01 02 03 04 05 06 90 91}} { return $stage }
    }
    return $fallback
}

proc tech_mv_report_dir {{stage ""} {category ""}} {
    if {$stage eq ""} {
        if {[info exists ::TECH_MV_REPORT_STAGE] && $::TECH_MV_REPORT_STAGE ne ""} {
            set stage $::TECH_MV_REPORT_STAGE
        } else { set stage 90 }
    }
    if {[info exists ::REPORT_DIR] && $::REPORT_DIR ne ""} {
        set root $::REPORT_DIR
    } else { set root [file normalize reports] }
    set dir [file join $root [tech_mv_report_stage_name $stage]]
    if {$category ne ""} { set dir [file join $dir [tech_mv_report_safe_name $category]] }
    file mkdir $dir
    return $dir
}

proc tech_mv_report_path {step name {ext rpt} {stage ""} {category ""}} {
    if {$stage eq ""} {
        if {[info exists ::TECH_MV_REPORT_STAGE] && $::TECH_MV_REPORT_STAGE ne ""} {
            set stage $::TECH_MV_REPORT_STAGE
        } else { set stage 90 }
    }
    set step_text [format "%02d" $step]
    set safe_name [tech_mv_report_safe_name $name]
    set safe_ext [string trimleft $ext .]
    set dir [tech_mv_report_dir $stage $category]
    return [file join $dir "${stage}_${step_text}_${safe_name}.${safe_ext}"]
}
