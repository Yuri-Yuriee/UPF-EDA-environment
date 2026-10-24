# Runtime adapter preserves the historical logical source path.
if {[info exists ::TECH_MV_RUNTIME_ROOT]} {
    info script [file join $::TECH_MV_RUNTIME_ROOT run/tool/01_floorplan/TT_floorplan_restore_level0_driver.tcl]
} else {
    info script [file normalize [file join [file dirname [info script]] .. .. run/tool/01_floorplan/TT_floorplan_restore_level0_driver.tcl]]
}
# =============================================================================
# TT_floorplan_restore_level0_driver.tcl
# TECH_MV Floorplan restore level-0 read_db driver V2.6.0
# Relative-path experiment: raw read_db ./dbs/<checkpoint>.enc
#
# CRITICAL SAFETY RULE:
#   read_db below must execute at Tcl level 0 and must NOT be wrapped by
#   proc/catch/eval/uplevel/suspend. Stage-01 DBs were observed to SEGV
#   Innovus 21.19 when invoked through unsafe interactive/proc contexts.
# =============================================================================

puts ""
puts "======================================================================"
puts " FLOORPLAN LEVEL-0 READ_DB ENTRY"
puts "======================================================================"
puts "Tcl level : [info level]"
puts "Point     : [expr {[info exists ::FP_LEVEL0_RESTORE_POINT] ? $::FP_LEVEL0_RESTORE_POINT : "<unset>"}]"
puts "DB        : [expr {[info exists ::FP_LEVEL0_RESTORE_DB] ? $::FP_LEVEL0_RESTORE_DB : "<unset>"}]"
puts "Policy    : raw level-0 read_db using a relative ./dbs/... path"
puts "======================================================================"
flush stdout

# Refuse before read_db if the callback did not enter global Tcl scope.
if {[info level] != 0} {
    set ::FP_RESTORE_STATE error
    set ::FP_LEVEL0_RESTORE_PENDING 0
    error "REFUSED before read_db: Floorplan level-0 driver must run at Tcl level 0; current level=[info level]."
}
if {![info exists ::FP_LEVEL0_RESTORE_PENDING] || !$::FP_LEVEL0_RESTORE_PENDING} {
    set ::FP_RESTORE_STATE error
    error "Floorplan level-0 driver was sourced without a pending fp_restore request."
}
if {![info exists ::FP_LEVEL0_RESTORE_POINT] || $::FP_LEVEL0_RESTORE_POINT eq ""} {
    set ::FP_RESTORE_STATE error
    set ::FP_LEVEL0_RESTORE_PENDING 0
    error "Floorplan level-0 restore point is not set."
}
if {![info exists ::FP_LEVEL0_RESTORE_DB] || $::FP_LEVEL0_RESTORE_DB eq ""} {
    set ::FP_RESTORE_STATE error
    set ::FP_LEVEL0_RESTORE_PENDING 0
    error "Floorplan level-0 restore DB is not set."
}
if {![file exists $::FP_LEVEL0_RESTORE_DB]} {
    set ::FP_RESTORE_STATE error
    set ::FP_LEVEL0_RESTORE_PENDING 0
    error "Floorplan checkpoint DB does not exist: $::FP_LEVEL0_RESTORE_DB"
}

set _fp_level0_point $::FP_LEVEL0_RESTORE_POINT
set _fp_level0_db $::FP_LEVEL0_RESTORE_DB
set _fp_level0_hold $::FP_LEVEL0_RESTORE_HOLD
set ::FP_RESTORE_STATE loading
set ::FP_LEVEL0_RESTORE_EVENT ""

# -----------------------------------------------------------------------------
# RELATIVE PATH PREPARATION
# -----------------------------------------------------------------------------
# The runtime root is build_PR.  TT_proc_floorplan_resume.tcl sources init.setup,
# which defines TOOL_DIR as build_PR/run/tool.  Derive build_PR from TOOL_DIR and
# temporarily set cwd there so Innovus receives exactly ./dbs/<checkpoint>.enc.
if {![info exists ::TOOL_DIR] || $::TOOL_DIR eq ""} {
    set ::FP_RESTORE_STATE error
    set ::FP_LEVEL0_RESTORE_PENDING 0
    error "REFUSED before read_db: TOOL_DIR is not defined."
}

set _fp_saved_pwd [pwd]
set _fp_runtime_root [file normalize [file join $::TOOL_DIR .. ..]]
set _fp_db_tail [file tail $_fp_level0_db]
set _fp_relative_db [file join . dbs $_fp_db_tail]
set _fp_expected_abs [file normalize $_fp_level0_db]
set _fp_relative_abs [file normalize [file join $_fp_runtime_root $_fp_relative_db]]

# Safety gate: the relative spelling must resolve to exactly the catalog DB.
if {$_fp_relative_abs ne $_fp_expected_abs} {
    set ::FP_RESTORE_STATE error
    set ::FP_LEVEL0_RESTORE_PENDING 0
    error "REFUSED before read_db: relative checkpoint resolves to a different DB. expected='$_fp_expected_abs' relative='$_fp_relative_abs'"
}
if {![file isdirectory $_fp_runtime_root]} {
    set ::FP_RESTORE_STATE error
    set ::FP_LEVEL0_RESTORE_PENDING 0
    error "REFUSED before read_db: runtime root does not exist: $_fp_runtime_root"
}

# Intentionally make the read_db argument relative.  No normalization is applied
# to _fp_relative_db after this point.
cd $_fp_runtime_root
if {![file exists $_fp_relative_db]} {
    cd $_fp_saved_pwd
    set ::FP_RESTORE_STATE error
    set ::FP_LEVEL0_RESTORE_PENDING 0
    error "REFUSED before read_db: relative checkpoint does not exist from runtime root: $_fp_relative_db"
}

puts "INFO: FP read_db original DB : $_fp_expected_abs"
puts "INFO: FP read_db runtime cwd : [pwd]"
puts "INFO: FP read_db relative arg: $_fp_relative_db"
puts "INFO: FP read_db relative chk: PASS"
flush stdout

# -----------------------------------------------------------------------------
# THE KEY STATEMENT
# -----------------------------------------------------------------------------
# Do not move this into a proc/catch/eval/uplevel/suspend wrapper.
# The argument below remains RELATIVE exactly as shown in the diagnostic above.
read_db $_fp_relative_db
# -----------------------------------------------------------------------------

# read_db returned successfully; restore the caller's working directory before
# any continuation/setup logic executes.
cd $_fp_saved_pwd

set _fp_level0_design ""
catch {set _fp_level0_design [get_db current_design .name]}
if {$_fp_level0_design eq ""} {
    set ::FP_RESTORE_STATE error
    set ::FP_LEVEL0_RESTORE_PENDING 0
    error "Level-0 relative-path read_db returned without a current design: $_fp_level0_db"
}

set ::FP_RESTORED_POINT $_fp_level0_point
set ::FP_RESTORED_DB [file normalize $_fp_level0_db]
set ::FP_LEVEL0_RESTORE_PENDING 0

puts ""
puts "======================================================================"
puts " FLOORPLAN LEVEL-0 RELATIVE READ_DB : PASS"
puts "======================================================================"
puts "Design    : $_fp_level0_design"
puts "Point     : $::FP_RESTORED_POINT"
puts "DB        : $::FP_RESTORED_DB"
puts "Tcl level : [info level]"
puts "======================================================================"
puts ""
flush stdout

if {$_fp_level0_hold} {
    set ::FP_RESTORE_STATE held
    puts "======================================================================"
    puts " FLOORPLAN CHECKPOINT HELD (LEGACY DEBUG MODE)"
    puts "======================================================================"
    puts "Design : $_fp_level0_design"
    puts "Point  : $_fp_level0_point"
    puts "No continuation has executed."
    puts "Use fp_continue to arm the native suspend/resume continuation."
    puts "======================================================================"
    puts ""
} else {
    set ::FP_NATIVE_RESTORE_POINT $_fp_level0_point
    set ::FP_NATIVE_RESTORE_DRIVER [file join $::TECH_MV_RUNTIME_ROOT .. script PR TECH_MV script 01_floorplan floorplan_restore_native_driver.tcl]
    if {![file isfile $::FP_NATIVE_RESTORE_DRIVER]} {
        set ::FP_RESTORE_STATE error
        error "Floorplan native-restore driver does not exist: $::FP_NATIVE_RESTORE_DRIVER"
    }
    # read_db has already completed at level 0. Native continuation may now use
    # the existing post-read global-scope suspend/resume framework.
    source -quiet $::FP_NATIVE_RESTORE_DRIVER
}

unset -nocomplain _fp_level0_point _fp_level0_db _fp_level0_hold _fp_level0_design \
    _fp_saved_pwd _fp_runtime_root _fp_db_tail _fp_relative_db \
    _fp_expected_abs _fp_relative_abs
