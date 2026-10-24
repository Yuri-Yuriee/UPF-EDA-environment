# Runtime adapter preserves the historical logical source path.
if {[info exists ::TECH_MV_RUNTIME_ROOT]} {
    info script [file join $::TECH_MV_RUNTIME_ROOT run/tool/02_powerplan/sdp/TT_sdp_post_resume.tcl]
} else {
    info script [file normalize [file join [file dirname [info script]] .. .. .. run/tool/02_powerplan/sdp/TT_sdp_post_resume.tcl]]
}
# =============================================================================
# TT_sdp_post_resume.tcl
# TECH_MV / PR7 SDP checkpoint post-resume cleanup
#
# PURPOSE
#   Run immediately AFTER the PR7 SDP suspend returns from native Innovus
#   `resume`, before the outer floorplan flow continues to its existing WellTap
#   insertion stage.
#
# POLICY
#   - Delete ONLY SDP-repair-owned temporary placement blockages.
#   - Delete patterns are TT_SDP_SWKO_* and TT_PR7_GAPBLK_* only.
#   - Never delete generic floorplan/macro/PD blockages.
#   - Never create WellTaps here.  The existing TECH_MV flow remains the owner
#     of normal WellTap insertion through add_well_taps.tcl.
#   - Never delete or move SDPWT_* / SDP members.
#
# AUTOMATION
#   TT_sdp_post_resume_arm installs a one-shot execution trace on `suspend`.
#   When the PR7 checkpoint resumes, the trace fires on suspend-leave, removes
#   the temporary SDP blockages, removes itself, and lets the original flow
#   continue normally into its existing WellTap insertion.
# =============================================================================

if {![info exists ::TT_SDP_POST_RESUME_TEMP_BLK_PATTERNS]} {
    set ::TT_SDP_POST_RESUME_TEMP_BLK_PATTERNS {TT_SDP_SWKO_* TT_PR7_GAPBLK_*}
}
if {![info exists ::TT_SDP_POST_RESUME_ARMED]} {
    set ::TT_SDP_POST_RESUME_ARMED 0
}
if {![info exists ::TT_SDP_POST_RESUME_LAST_RESULT]} {
    set ::TT_SDP_POST_RESUME_LAST_RESULT {}
}

proc TT_SDP_POST__is_owned_temp_blk_name {name} {
    foreach pat $::TT_SDP_POST_RESUME_TEMP_BLK_PATTERNS {
        if {[string match $pat $name]} { return true }
    }
    return false
}

proc TT_sdp_post_resume_preview {} {
    set names {}
    foreach b [get_db place_blockages] {
        set n ""
        catch {set n [get_db $b .name]}
        if {$n eq ""} { continue }
        if {[TT_SDP_POST__is_owned_temp_blk_name $n]} {
            lappend names $n
        }
    }
    set names [lsort -unique $names]
    puts ""
    puts "======================================================================"
    puts " TT SDP POST-RESUME TEMP BLOCKAGE PREVIEW"
    puts "======================================================================"
    puts "Owned patterns : $::TT_SDP_POST_RESUME_TEMP_BLK_PATTERNS"
    puts "Delete count   : [llength $names]"
    foreach n $names { puts "  $n" }
    puts "Other BLKs     : PRESERVED"
    puts "WellTap policy : existing add_well_taps.tcl flow remains owner"
    puts "======================================================================"
    return $names
}

proc TT_sdp_post_resume_cleanup {} {
    puts ""
    puts "======================================================================"
    puts " TT SDP POST-RESUME CLEANUP"
    puts "======================================================================"
    puts "Action #1 : remove SDP-repair-owned temporary placement blockages"
    puts "Action #2 : verify BOTH owned blockage families are fully gone"
    puts "Action #3 : only then allow outer TECH_MV flow to continue to original WellTap insertion"
    puts "Protected : all non-TT SDP BLKs / SDPWT_* / SDP members / SW / macros"

    set targets {}
    foreach b [get_db place_blockages] {
        set n ""
        catch {set n [get_db $b .name]}
        if {$n eq ""} { continue }
        if {[TT_SDP_POST__is_owned_temp_blk_name $n]} {
            lappend targets [list $n $b]
        }
    }

    set deleted 0
    set failed {}
    foreach rec $targets {
        lassign $rec n b
        if {[catch {delete_obj $b} err]} {
            lappend failed [list $n $err]
            puts "WARN: failed to delete temp SDP blockage $n: $err"
        } else {
            incr deleted
            puts "INFO: deleted temp SDP blockage: $n"
        }
    }

    set remaining {}
    foreach b [get_db place_blockages] {
        set n ""
        catch {set n [get_db $b .name]}
        if {$n ne "" && [TT_SDP_POST__is_owned_temp_blk_name $n]} {
            lappend remaining $n
        }
    }
    set remaining [lsort -unique $remaining]

    set r [dict create \
        targeted [llength $targets] \
        deleted $deleted \
        failed $failed \
        remaining $remaining \
        welltap_action "delegated_to_existing_flow_after_strict_cleanup"]
    set ::TT_SDP_POST_RESUME_LAST_RESULT $r

    puts "Target temporary BLKs : [dict get $r targeted]"
    puts "Deleted              : [dict get $r deleted]"
    puts "Delete failures       : [llength [dict get $r failed]]"
    puts "Remaining owned BLKs  : [llength [dict get $r remaining]]"
    set ok [expr {[llength [dict get $r remaining]] == 0 && [llength [dict get $r failed]] == 0}]
    dict set r ok $ok
    set ::TT_SDP_POST_RESUME_LAST_RESULT $r
    puts "WellTap insertion     : original flow, AFTER this cleanup gate"
    if {$ok} {
        puts "POST-RESUME CLEANUP   : PASS"
        puts "WELLTAP HANDOFF       : READY - outer flow may continue to add_well_taps.tcl"
    } else {
        puts "POST-RESUME CLEANUP   : FAIL - owned temp BLKs remain; WellTap handoff blocked"
    }
    puts "======================================================================"
    return $r
}

proc TT_SDP_POST__on_suspend_leave {cmd code result op} {
    # One-shot trace: invoked only after native `resume` makes the pending PR7
    # `suspend` return.  R9 keeps cleanup as a strict handoff gate: if any owned
    # temp BLK remains, raise an error from the leave trace so the outer Tcl
    # flow stops here and cannot reach normal WellTap insertion.
    catch {trace remove execution suspend leave TT_SDP_POST__on_suspend_leave}
    if {![info exists ::TT_SDP_POST_RESUME_ARMED] || !$::TT_SDP_POST_RESUME_ARMED} {
        return
    }
    set ::TT_SDP_POST_RESUME_ARMED 0
    puts "INFO: PR7 suspend resumed; strict SDP temp-BLK cleanup runs BEFORE original WellTap insertion."

    if {[catch {set r [TT_sdp_post_resume_cleanup]} err]} {
        puts "CRITICAL: TT_sdp_post_resume_cleanup raised an error: $err"
        error "R9 post-resume cleanup failed; outer flow stopped before add_well_taps.tcl"
    }
    if {![dict exists $r ok] || ![dict get $r ok]} {
        puts "CRITICAL: owned temporary SDP blockage(s) remain after cleanup."
        error "R9 cleanup gate blocked downstream WellTap insertion; inspect TT_sdp_post_resume_preview"
    }

    puts "PASS: R9 cleanup gate complete; outer flow now continues to its existing add_well_taps.tcl stage."
}

proc TT_sdp_post_resume_arm {} {
    if {[llength [info commands suspend]] == 0} {
        puts "WARN: Innovus suspend command unavailable; post-resume cleanup could not be armed."
        return false
    }
    # Avoid duplicate traces if helper is sourced more than once.
    catch {trace remove execution suspend leave TT_SDP_POST__on_suspend_leave}
    if {[catch {trace add execution suspend leave TT_SDP_POST__on_suspend_leave} err]} {
        puts "WARN: could not arm PR7 suspend-leave cleanup trace: $err"
        return false
    }
    set ::TT_SDP_POST_RESUME_ARMED 1
    puts "INFO: PR7 post-resume cleanup armed (one-shot on suspend leave)."
    puts "INFO: After resume, only TT_SDP_SWKO_* and TT_PR7_GAPBLK_* placement blockages are removed."
    puts "INFO: Cleanup PASS is a strict gate before existing downstream add_well_taps.tcl."
    return true
}

proc TT_sdp_post_resume_disarm {} {
    catch {trace remove execution suspend leave TT_SDP_POST__on_suspend_leave}
    set ::TT_SDP_POST_RESUME_ARMED 0
    puts "INFO: PR7 post-resume cleanup disarmed."
    return true
}

puts "INFO: Loaded TT_sdp_post_resume.tcl"
puts "INFO: CHECK : TT_sdp_post_resume_preview"
puts "INFO: CLEAN : TT_sdp_post_resume_cleanup"
puts "INFO: ARM   : TT_sdp_post_resume_arm"
