# Runtime adapter preserves the historical logical source path.
if {[info exists ::TECH_MV_RUNTIME_ROOT]} {
    info script [file join $::TECH_MV_RUNTIME_ROOT run/tool/01_floorplan/TT_flow_iopad_ring_model.tcl]
}
# =============================================================================
# TT_flow_iopad_ring_model.tcl
# =============================================================================
# Purpose:
#   User-facing TT tool for the optional segmented IO-pad ring model.
#
# Usage in Innovus:
#   source run/tool/01_floorplan/TT_flow_iopad_ring_model.tcl
#   TT_IOPAD_RING help
#   TT_IOPAD_RING status
#   TT_IOPAD_RING reload
#   TT_IOPAD_RING build
#   TT_IOPAD_RING report
#   TT_IOPAD_RING generate
#   TT_IOPAD_RING check
#   TT_IOPAD_RING apply
#
# Notes:
#   - Design configuration remains in setup/config/01_floorplan.config.tcl.
#   - This tool does NOT silently read the generated IO file back into Innovus.
#   - 'apply' means build model -> generate IO file -> validate IO file.
# =============================================================================

proc tt_iopad_tool_require_runtime {} {
    foreach v {TOOL_DIR SCRIPT_DIR IO_FILE} {
        if {![info exists ::$v] || [set ::$v] eq ""} {
            error "TECH_MV runtime variable '$v' is not initialized. Source build_PR/init.setup first."
        }
    }
}

proc tt_iopad_tool_source_global {path} {
    if {![file isfile $path]} {
        error "Required TECH_MV file not found: $path"
    }
    uplevel #0 [list source -quiet $path]
}

proc tt_iopad_tool_build {} {
    tt_iopad_tool_require_runtime
    set f [file join $::SCRIPT_DIR build_iopad_ring_model.tcl]
    tt_iopad_tool_source_global $f
    if {![info exists ::IOPAD_RING_MODEL_ACTIVE] || !$::IOPAD_RING_MODEL_ACTIVE} {
        error "IO-pad ring model is inactive. Populate IOPAD_RING_DOMAIN_CONFIG in setup/config/01_floorplan.config.tcl first."
    }
    return $::IOPAD_RING_MODEL
}

proc tt_iopad_tool_report {} {
    tt_iopad_tool_require_runtime
    if {![info exists ::IOPAD_RING_MODEL_ACTIVE] || !$::IOPAD_RING_MODEL_ACTIVE || ![info exists ::IOPAD_RING_MODEL]} {
        tt_iopad_tool_build
    }
    if {[llength [info commands tt_iopad_ring_report]] == 0} {
        tt_iopad_tool_source_global [file join $::TECH_MV_RUNTIME_ROOT .. script PR TECH_MV script 01_floorplan proc_iopad_ring_model.tcl]
    }
    tt_iopad_ring_report $::IOPAD_RING_MODEL
    return $::IOPAD_RING_MODEL
}

proc tt_iopad_tool_generate {} {
    tt_iopad_tool_build
    tt_iopad_tool_source_global [file join $::SCRIPT_DIR generate_io_file_ring_model.tcl]
    puts "INFO: TT IOPAD ring model generated IO file: $::IO_FILE"
    return $::IO_FILE
}

proc tt_iopad_tool_check {} {
    tt_iopad_tool_require_runtime
    if {[llength [info commands TT_check_iopad_iofile]] == 0} {
        tt_iopad_tool_source_global [file join $::TOOL_DIR 01_floorplan TT_proc_iopad_iofile_check.tcl]
    }

    # The checker can validate the active model in addition to the IO file.
    # Build it first when configured but not yet active.
    if {[info exists ::ENABLE_IOPAD_RING_MODEL] && $::ENABLE_IOPAD_RING_MODEL} {
        if {![info exists ::IOPAD_RING_MODEL_ACTIVE] || !$::IOPAD_RING_MODEL_ACTIVE} {
            tt_iopad_tool_build
        }
    }

    return [TT_check_iopad_iofile]
}

proc tt_iopad_tool_reload {} {
    tt_iopad_tool_require_runtime
    set flow_root [file dirname [file dirname $::TOOL_DIR]]
    set init_file [file join $flow_root init.setup]
    if {![file isfile $init_file]} {
        error "TECH_MV init.setup not found: $init_file"
    }
    puts "INFO: Reloading TECH_MV configuration: $init_file"
    uplevel #0 [list source $init_file]
    return [tt_iopad_tool_build]
}

proc tt_iopad_tool_status {} {
    puts "======================================================================"
    puts " TT IOPAD RING MODEL STATUS"
    puts "======================================================================"

    if {[info exists ::IOPAD_RING_NAME]} {
        puts "Ring name      : $::IOPAD_RING_NAME"
    } else {
        puts "Ring name      : <config not loaded>"
    }

    if {[info exists ::IOPAD_RING_COMMON_GROUND]} {
        puts "Common ground  : $::IOPAD_RING_COMMON_GROUND"
    }

    if {[info exists ::IOPAD_RING_DOMAIN_CONFIG]} {
        puts "Domain entries : [llength $::IOPAD_RING_DOMAIN_CONFIG]"
    } else {
        puts "Domain entries : <config not loaded>"
    }

    if {[info exists ::ENABLE_IOPAD_RING_MODEL]} {
        puts "Config enabled : $::ENABLE_IOPAD_RING_MODEL"
    } else {
        puts "Config enabled : <unknown>"
    }

    if {[info exists ::IOPAD_RING_MODEL_ACTIVE]} {
        puts "Model active   : $::IOPAD_RING_MODEL_ACTIVE"
    } else {
        puts "Model active   : false (not built in this session)"
    }

    if {[info exists ::IO_FILE]} {
        puts "IO file        : $::IO_FILE"
    }

    if {[info exists ::ENABLE_IO_CORNER_OFFSET]} {
        puts "Corner offset  : enable=$::ENABLE_IO_CORNER_OFFSET value=$::IO_CORNER_PAD_OFFSET"
    }

    puts "======================================================================"
}

proc tt_iopad_tool_help {} {
    puts "======================================================================"
    puts " TT_IOPAD_RING <action>"
    puts "======================================================================"
    puts "  help      : show this help"
    puts "  status    : show config/model status; no DB modification"
    puts "  reload    : reload TECH_MV init.setup, then rebuild model"
    puts "  build     : build/validate model and create configured missing IO/RTE/boundary cell insts"
    puts "  report    : print ring/domain/boundary cell topology"
    puts "  generate  : build model and regenerate IO_FILE from the ring model"
    puts "  check     : validate current IO_FILE against the configured model"
    puts "  apply     : build -> generate -> check; does NOT read_io_file"
    puts ""
    puts "Configuration file:"
    puts "  setup/config/01_floorplan.config.tcl"
    puts ""
    puts "Typical edit flow:"
    puts "  1. Edit IOPAD_RING_DOMAIN_CONFIG / corner offset in floorplan config"
    puts "  2. TT_IOPAD_RING reload"
    puts "  3. TT_IOPAD_RING report"
    puts "  4. TT_IOPAD_RING generate"
    puts "  5. TT_IOPAD_RING check"
    puts "  6. read_io_file \$IO_FILE -no_die_size_adjust   ;# only when YOU want DB update"
    puts "======================================================================"
}

proc TT_IOPAD_RING {{action status}} {
    set action [string tolower $action]
    switch -- $action {
        help {
            tt_iopad_tool_help
            return
        }
        status {
            tt_iopad_tool_status
            return
        }
        reload {
            return [tt_iopad_tool_reload]
        }
        build {
            return [tt_iopad_tool_build]
        }
        report {
            return [tt_iopad_tool_report]
        }
        generate {
            return [tt_iopad_tool_generate]
        }
        check {
            return [tt_iopad_tool_check]
        }
        apply {
            tt_iopad_tool_generate
            return [tt_iopad_tool_check]
        }
        default {
            error "Unknown TT_IOPAD_RING action '$action'. Use: TT_IOPAD_RING help"
        }
    }
}

# Lower-case convenience alias for users who prefer Tcl-style names.
proc TT_iopad_ring_model {{action status}} {
    return [TT_IOPAD_RING $action]
}

puts "INFO: Loaded TT IOPAD ring-model tool.  Use: TT_IOPAD_RING help"
