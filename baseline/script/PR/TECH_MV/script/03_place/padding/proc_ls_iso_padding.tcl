# Runtime adapter preserves the historical logical source path.
if {[info exists ::TECH_MV_RUNTIME_ROOT]} {
    info script [file join $::TECH_MV_RUNTIME_ROOT run/tool/03_place/padding/TT_proc_ls_iso_padding.tcl]
} else {
    info script [file normalize [file join [file dirname [info script]] .. .. .. run/tool/03_place/padding/TT_proc_ls_iso_padding.tcl]]
}
# =============================================================================
# TT_proc_ls_iso_padding.tcl
# =============================================================================
# TECH_MV / Innovus 21.19 Common UI
#
# Apply instance placement padding to LS / ISO cells before initial placement.
# Existing LS padding is extended to ISO using the configured LS_ISO_PADDING_SITES span.
# policy to Isolation cells.  ISO discovery uses the supported DB attribute
# .is_isolation first, with name-pattern fallback for older databases.
#
# Defaults:
#   ENABLE_LS_ISO_PADDING = true
#   LS_ISO_PADDING_SITES = <configured_site_count>
#
# This is intentionally instance padding only: no placement-status, location,
# orientation, power-domain, supply, or connectivity changes are performed.
# =============================================================================

if {![info exists ::ENABLE_LS_ISO_PADDING]} { set ::ENABLE_LS_ISO_PADDING true }
if {![info exists ::LS_ISO_PADDING_SITES]} { set ::LS_ISO_PADDING_SITES 2 }
if {![info exists ::LS_ISO_ISO_NAME_PATTERNS]} {
    set ::LS_ISO_ISO_NAME_PATTERNS { *_UPF_ISO* *_UPF_LS* }
}

proc TT_ls_iso_pad__validate_sites {v} {
    if {![string is integer -strict $v] || $v < 0} {
        error "LS_ISO_PADDING_SITES must be a non-negative integer, got '$v'"
    }
}

proc TT_ls_iso_pad__name {inst} {
    set n ""
    catch {set n [get_db $inst .name]}
    return $n
}

proc TT_ls_iso_pad__append_unique {var_name value} {
    upvar 1 $var_name L
    if {$value ne "" && [lsearch -exact $L $value] < 0} {
        lappend L $value
    }
}

proc TT_ls_iso_pad__query {filter} {
    set objs {}
    if {[catch {set objs [get_db insts -if $filter]} err]} {
        return [list {} $err]
    }
    return [list $objs ""]
}

proc TT_proc_apply_ls_iso_padding {} {
    puts ""
    puts "======================================================================"
    puts " LS / ISO INSTANCE PADDING"
    puts "======================================================================"

    if {!$::ENABLE_LS_ISO_PADDING} {
        puts "INFO: LS/ISO instance padding disabled."
        puts "======================================================================"
        return [dict create enabled false applied 0 ls 0 iso 0 failed 0]
    }

    TT_ls_iso_pad__validate_sites $::LS_ISO_PADDING_SITES
    if {[llength [info commands set_inst_padding]] == 0} {
        error "Required Innovus command set_inst_padding is unavailable."
    }

    set ls_names {}
    set iso_names {}
    set target_names {}

    lassign [TT_ls_iso_pad__query {.is_level_shifter == true}] ls_objs ls_err
    if {$ls_err ne ""} {
        puts "WARNING: LS DB query failed: $ls_err"
        set ls_objs {}
    }
    foreach inst $ls_objs {
        set n [TT_ls_iso_pad__name $inst]
        TT_ls_iso_pad__append_unique ls_names $n
        TT_ls_iso_pad__append_unique target_names $n
    }

    # Current TECH_MV / Innovus 21.19 supports .is_isolation and the PR6 SDP
    # creator already relies on it.  Use it as the authoritative ISO classifier.
    lassign [TT_ls_iso_pad__query {.is_isolation == true}] iso_objs iso_err
    if {$iso_err eq ""} {
        foreach inst $iso_objs {
            set n [TT_ls_iso_pad__name $inst]
            TT_ls_iso_pad__append_unique iso_names $n
            TT_ls_iso_pad__append_unique target_names $n
        }
    } else {
        puts "WARNING: ISO attribute query failed; using configured name patterns."
    }

    # Fallback only when the native ISO attribute is unavailable / empty.
    if {[llength $iso_names] == 0} {
        foreach pattern $::LS_ISO_ISO_NAME_PATTERNS {
            lassign [TT_ls_iso_pad__query ".name == $pattern"] matches err
            if {$err ne ""} {
                puts "WARNING: ISO name-pattern query failed for '$pattern': $err"
                continue
            }
            foreach inst $matches {
                set n [TT_ls_iso_pad__name $inst]
                TT_ls_iso_pad__append_unique iso_names $n
                TT_ls_iso_pad__append_unique target_names $n
            }
        }
    }

    set applied 0
    set failed 0
    foreach name $target_names {
        set insts [get_db insts $name]
        if {[llength $insts] == 0} {
            puts "WARNING: Instance disappeared / not found: $name"
            incr failed
            continue
        }
        foreach inst $insts {
            if {[catch {
                set_inst_padding -inst [get_db $inst .name] \
                    -left_side $::LS_ISO_PADDING_SITES \
                    -right_side $::LS_ISO_PADDING_SITES
            } err]} {
                puts "WARNING: Failed LS/ISO padding: $name"
                puts "         $err"
                incr failed
                continue
            }
            incr applied
        }
    }

    puts "LS instances found  : [llength $ls_names]"
    puts "ISO instances found : [llength $iso_names]"
    puts "Unique targets      : [llength $target_names]"
    puts "Padding             : L=$::LS_ISO_PADDING_SITES R=$::LS_ISO_PADDING_SITES sites"
    puts "Applied             : $applied"
    puts "Failed              : $failed"
    if {[llength [info commands report_inst_padding]] > 0} {
        puts "INFO: report_inst_padding is available for post-placement inspection."
    }
    puts "======================================================================"

    if {$failed != 0} {
        error "LS/ISO instance padding incomplete: $failed instance(s) failed."
    }
    return [dict create enabled true applied $applied ls [llength $ls_names] iso [llength $iso_names] failed $failed]
}

puts "INFO: Loaded TT_proc_ls_iso_padding.tcl"
puts "INFO: Default LS/ISO padding = 2/2 placement sites"
puts "INFO: Run: TT_proc_apply_ls_iso_padding"
