# Runtime adapter preserves the historical logical source path.
if {[info exists ::TECH_MV_RUNTIME_ROOT]} {
    info script [file join $::TECH_MV_RUNTIME_ROOT run/tool/05_route/drc/TT_DRC_fix_metal_color.tcl]
}
# DRC_RULE_SPECIFIC_TOOL: named/configured DRC subtype selection is technology-dependent.
# DRC_RULE_REVIEW: Rule names, filters and repair logic are retained for manual planning.
# PUBLIC_EXPORT_REVIEW_REQUIRED: residual technology candidates require manual review.
# Marker-guided localized signal-wire color repair. Cadence Innovus Common UI.
# Not a color-rule waiver. Run in saved checkpoint and validate with fresh signoff DRC.
namespace eval ::ttmc {
    variable targets {}
    variable prefix TT_MC_V21
}
proc ::ttmc::flatbox {b} {
    set a [concat {*}$b]
    if {[llength $a] != 4} {error "not a 4-value bbox: $b"}
    return $a
}
proc ::ttmc::same_box {a b} {
    set a [flatbox $a]; set b [flatbox $b]
    for {set i 0} {$i < 4} {incr i} {
        if {abs([lindex $a $i]-[lindex $b $i]) > $::METAL_COLOR_REPAIR_BBOX_TOLERANCE} {return 0}
    }
    return 1
}
proc ::ttmc::lookup {id} {
    variable targets
    if {![string is integer -strict $id] || $id < 1 || $id > [llength $targets]} {
        error "target id must be within the configured target list"
    }
    return [lindex $targets [expr {$id-1}]]
}
proc ::ttmc::find_wire {t} {
    set net [dict get $t net]
    set matches {}
    foreach w [get_obj_in_area -areas [dict get $t bbox] -layers [list [::ttmc::target_layer $t]] -obj_type wire] {
        if {[get_db $w .net.name] eq $net && [same_box [get_db $w .rect] [dict get $t wire]]} {
            lappend matches $w
        }
    }
    if {[llength $matches] != 1} {error "STOP: expected unique unchanged target wire, got [llength $matches]"}
    set w [lindex $matches 0]
    if {[get_db $w .status] ne "routed"} {error "STOP: target is not routed"}
    if {[get_db $w .mask] ne [::ttmc::target_mask $t]} {error "STOP: unexpected mask; re-evaluate pin coloring"}
    return $w
}
proc ::ttmc::target_layer {t} {
    if {[dict exists $t layer]} {return [dict get $t layer]}
    return M3
}
proc ::ttmc::target_mask {t} {
    if {[dict exists $t mask]} {return [dict get $t mask]}
    return 1
}
proc ::ttmc::object_net {object} {
    if {[get_db $object .obj_type] eq "net"} {return [get_db $object .name]}
    if {![catch {get_db $object .net.name} name]} {return $name}
    return ""
}
proc ::ttmc::find_marker {t} {
    set found 0
    foreach marker [get_obj_in_area -areas [dict get $t bbox] -obj_type marker] {
        if {![same_box [get_db $marker .bbox] [dict get $t bbox]]} {continue}
        if {[get_db $marker .layer.name] ne [target_layer $t]} {continue}
        if {[get_db $marker .subtype] ni $::METAL_COLOR_REPAIR_MARKER_SUBTYPES} {continue}
        foreach object [get_db $marker .objects] {
            if {[object_net $object] eq [dict get $t net]} {incr found;break}
        }
    }
    if {!$found} {error "STOP: no exact current marker linked to target net"}
}
proc ::ttmc::block_box {t} {
    return [dict get $t block_bbox]
}
proc metal_color_version {} {return "V21_1_DBS_CHECKPOINT"}
proc metal_color_check {} {
    if {$::METAL_COLOR_REPAIR_TARGET_MODE eq "markers"} {metal_color_scan}
    for {set id 1} {$id <= [llength $::ttmc::targets]} {incr id} {
        set t [::ttmc::lookup $id]
        puts "TARGET=$id NET=[dict get $t net] BBOX=[dict get $t bbox]"
        if {[catch {::ttmc::find_marker $t; set w [::ttmc::find_wire $t]; ::ttmc::preflight_area $t [::ttmc::block_box $t]} e]} {
            puts "  STATUS=STOP REASON=$e"
        } else {
            puts "  STATUS=READY MASK=[get_db $w .mask] WIRE=[get_db $w .rect]"
        }
    }
}
proc metal_color_plan {{id 1}} {
    if {$::METAL_COLOR_REPAIR_TARGET_MODE eq "markers" && ![llength $::ttmc::targets]} {metal_color_scan}
    set t [::ttmc::lookup $id]
    ::ttmc::find_marker $t
    set w [::ttmc::find_wire $t]
    set blk [::ttmc::block_box $t]
    ::ttmc::preflight_area $t $blk
    puts "TARGET=$id NET=[dict get $t net] WIRE=[get_db $w .rect] MASK=[get_db $w .mask]"
    puts "PROPOSED_SIGNAL_ONLY_BLOCKAGE=$blk"
    puts "METHOD=preflight -> save_db -> select ONLY target net -> create signal-only layer BLK -> local net-only ripup -> route_design -selected -> manual fresh DRC"
    puts "WARNING: deletion may remove an entire intersecting stub; route_design -selected may alter additional portions of the target net. Fresh DRC mandatory."
    return $blk
}
proc ::ttmc::preflight_area {t area} {
    if {[dict exists $t pin_related] && [dict get $t pin_related]} {
        error "STOP: pin-related marker needs a reviewed pin-safe repair plan; no automatic pin blockage"
    }
    set net [dict get $t net]
    set layer [target_layer $t]
    foreach wire [get_obj_in_area -areas $area -layers [list $layer] -obj_type wire] {
        if {[get_db $wire .net.name] ne $net || ![same_box [get_db $wire .rect] [dict get $t wire]]} {
            error "STOP: marker area includes another net/wire; explicit repair choice required"
        }
    }
    foreach type {via route_blockage} {
        if {[llength [get_obj_in_area -areas $area -layers [list $layer] -obj_type $type]]} {
            error "STOP: marker area contains $type; no automatic local ripup"
        }
    }
}
proc ::ttmc::selected_only {n} {
    # Fail closed if the tool release cannot prove selection identity.
    if {[llength [info commands deselect_obj]] != 1 || [llength [info commands select_obj]] != 1} {
        error "STOP: selected-net API unavailable"
    }
    # Clear any pre-existing GUI selection: never route an unrelated selected net.
    if {[catch {deselect_obj -all} e]} {
        error "STOP: deselect_obj -all unsupported: $e; no routes modified"
    }
    if {[catch {select_obj $n} e]} {
        error "STOP: select_obj failed: $e; no routes modified"
    }
    if {[catch {get_db selected} selection]} {
        catch {deselect_obj -all}
        error "STOP: cannot validate selected objects via get_db selected: $selection"
    }
    if {[llength $selection] != 1 || [lindex $selection 0] ne $n} {
        catch {deselect_obj -all}
        error "STOP: selection is not exactly target net: $selection (expected $n)"
    }
    puts "SELECTED_NET_VERIFIED=$selection"
}
proc metal_color_repair {{id 1} {confirm ""}} {
    if {$confirm ne "APPLY"} {error "SAFETY: run metal_color_repair $id APPLY only in disposable Innovus session"}
    if {$::METAL_COLOR_REPAIR_TARGET_MODE eq "markers" && ![llength $::ttmc::targets]} {metal_color_scan}
    set t [::ttmc::lookup $id]
    set bb [metal_color_plan $id]
    set net [dict get $t net]
    set w [::ttmc::find_wire $t]
    set n [get_db nets $net]
    if {[llength $n] != 1} {error "STOP: cannot uniquely resolve net=$net"}
    # Optional reviewed legacy cell-boundary guard; marker targets do not require a cell.
    if {[dict exists $t macro]} {
    set macro [get_db insts [dict get $t macro]]
    if {[llength $macro] != 1} {error "STOP: SRAM instance changed"}
    set macrobb [::ttmc::flatbox [get_db $macro .bbox]]
    switch -- [dict get $t keepout_side] {
        right {set outside [expr {[lindex $bb 0] > [lindex $macrobb 2]}]}
        left {set outside [expr {[lindex $bb 2] < [lindex $macrobb 0]}]}
        top {set outside [expr {[lindex $bb 1] > [lindex $macrobb 3]}]}
        bottom {set outside [expr {[lindex $bb 3] < [lindex $macrobb 1]}]}
        default {error "STOP: invalid macro keepout side"}
    }
    if {!$outside} {error "STOP: BLK touches macro bbox"}
    }
    set wire_count 0
    foreach other [get_obj_in_area -areas $bb -layers [list [::ttmc::target_layer $t]] -obj_type wire] {
        set owner [get_db $other .net.name]
        if {$owner ne $net} {error "STOP: foreign regular wire=$owner"}
        if {![::ttmc::same_box [get_db $other .rect] [dict get $t wire]]} {
            error "STOP: more than horizontal target wire intersects BLK; $other [get_db $other .rect]"
        }
        incr wire_count
    }
    if {$wire_count != 1} {error "STOP: expected one exact wire in BLK; got $wire_count"}
    foreach v [get_obj_in_area -areas $bb -layers [list [::ttmc::target_layer $t]] -obj_type via] {
        error "STOP: via intersects blockage $v; cannot safely local ripup"
    }
    if {[llength [get_obj_in_area -areas $bb -layers [list [::ttmc::target_layer $t]] -obj_type route_blockage]]} {
        error "STOP: existing route blockage intersects planned BLK"
    }
    set stamp [clock format [clock seconds] -format %Y%m%d_%H%M%S]
    # Checkpoints must stay under baseline/build_PR/dbs, never build_PR root.
    if {![info exists ::DB_DIR]} {error "STOP: DB_DIR is not configured"}
    set dbdir $::DB_DIR
    if {![file isdirectory $dbdir]} {
        error "STOP: checkpoint directory does not exist: $dbdir (create it intentionally before APPLY)"
    }
    set checkpoint [file join $dbdir "TT_MC_V21_before_${id}_${stamp}.enc"]
    if {[file exists $checkpoint]} {
        error "STOP: checkpoint already exists, refusing overwrite: $checkpoint"
    }
    puts "CHECKPOINT=$checkpoint"
    if {[catch {write_db $checkpoint} err]} {error "STOP: write_db failed before modification: $err"}
    # Verify selected-net isolation BEFORE any geometry mutation.
    ::ttmc::selected_only $n
    set name "TT_MC_V21_${id}"
    puts "CREATE_BLK=$name BBOX=$bb"
    if {[catch {create_route_blockage -name $name -layers [list [::ttmc::target_layer $t]] -rects [list $bb] -except_pg_nets} err]} {
        catch {deselect_obj -all}
        error "STOP: BLK creation failed; restore checkpoint if any changes; $err"
    }
    puts "RIPUP_SELECTED_NET net=$net layer=[::ttmc::target_layer $t] area=$bb"
    # delete_routes -area can remove a WHOLE touching wire, not just the portion inside area.
    if {[catch {delete_routes -net $n -layer [::ttmc::target_layer $t] -area $bb -type regular -use signal -status routed} err]} {
        catch {deselect_obj -all}
        error "STOP: ripup failed. REOPEN checkpoint=$checkpoint: $err"
    }
    # Selection can be invalidated by rip-up. Reassert identity before invoking route_design.
    if {[catch {::ttmc::selected_only $n} err]} {
        error "STOP: unable to re-select exact net AFTER rip-up. REOPEN checkpoint=$checkpoint: $err"
    }
    puts "ROUTE_SELECTED_NET=$net"
    set rc [catch {route_design -selected} err]
    catch {deselect_obj -all}
    if {$rc} {error "STOP: route_design -selected failed. REOPEN checkpoint=$checkpoint: $err"}
    puts "ROUTER_RETURNED checkpoint=$checkpoint; inspect connectivity, selected-net topology, all DRC, re-run external signoff DRC. No automatic PASS claim."
    return $checkpoint
}
proc metal_color_verify {} {
    puts "V21 verification: inspect CURRENT wiring and run check_connectivity with an out_file, then RE-RUN external signoff DRC and reimport markers. Old markers are stale."
    metal_color_check
}
proc metal_color_set_targets {records} {
    if {![info exists ::METAL_COLOR_REPAIR_BBOX_TOLERANCE] || ![string is double -strict $::METAL_COLOR_REPAIR_BBOX_TOLERANCE] || $::METAL_COLOR_REPAIR_BBOX_TOLERANCE <= 0} {
        error "Configure a positive METAL_COLOR_REPAIR_BBOX_TOLERANCE first"
    }
    foreach t $records {
        foreach key {net bbox wire block_bbox} {
            if {![dict exists $t $key] || [dict get $t $key] eq ""} {error "Missing reviewed repair target field: $key"}
        }
        foreach key {bbox wire block_bbox} {
            set b [::ttmc::flatbox [dict get $t $key]]
            foreach coordinate $b {if {![string is double -strict $coordinate]} {error "Non-numeric repair geometry"}}
            if {[lindex $b 0] >= [lindex $b 2] || [lindex $b 1] >= [lindex $b 3]} {error "Invalid repair rectangle"}
        }
        if {[dict exists $t macro] && (![dict exists $t keepout_side] || [dict get $t keepout_side] ni {left right top bottom})} {error "Invalid macro keepout side"}
    }
    set ::ttmc::targets $records
    return [llength $records]
}

# Query current DRC markers and associated objects; never mutate the DB here.
proc ::ttmc::marker_targets {marker} {
    if {[get_db $marker .subtype] ni $::METAL_COLOR_REPAIR_MARKER_SUBTYPES} {error "unsupported marker subtype"}
    set layer [get_db $marker .layer.name]
    if {$layer eq ""} {error "marker routing layer unavailable"}
    set bbox [flatbox [get_db $marker .bbox]]
    set linked {}
    set pin_related false
    if {![catch {get_db $marker .message} message] && [regexp -nocase {(^|[^[:alpha:]])pin([^[:alpha:]]|$)} $message]} {set pin_related true}
    foreach object [get_db $marker .objects] {
        set net [object_net $object]
        if {$net ne ""} {lappend linked $net}
        if {[get_db $object .obj_type] in {pin pg_pin}} {set pin_related true}
    }
    set linked [lsort -unique $linked]
    if {![llength $linked]} {error "marker has no provable net association"}
    set targets {}
    foreach wire [get_obj_in_area -areas $bbox -layers [list $layer] -obj_type wire] {
        set net [get_db $wire .net.name]
        if {$net ni $linked || [get_db $wire .status] ne "routed"} {continue}
        set rectangle [flatbox [get_db $wire .rect]]
        set mask [get_db $wire .mask]
        if {$mask eq ""} {continue}
        # Exact marker area; do not infer a macro, stub, fixed net or location.
        lappend targets [dict create net $net bbox $bbox wire $rectangle block_bbox $bbox \
            layer $layer mask $mask pin_related $pin_related]
    }
    if {![llength $targets]} {error "no routed wire linked to marker on its layer"}
    return $targets
}
# Retain the original single-target entry for callers requiring uniqueness.
proc ::ttmc::marker_target {marker} {
    set targets [marker_targets $marker]
    if {[llength $targets] != 1} {error "marker has multiple wire candidates; choose a reported target"}
    return [lindex $targets 0]
}

proc metal_color_scan {} {
    if {![info exists ::METAL_COLOR_REPAIR_MARKER_SUBTYPES]} {error "Configure METAL_COLOR_REPAIR_MARKER_SUBTYPES first"}
    set ::ttmc::targets {}
    set candidates {}
    set skipped {}
    set seen {}
    set count 0
    foreach marker [get_db markers] {
        if {[get_db $marker .subtype] ni $::METAL_COLOR_REPAIR_MARKER_SUBTYPES} {continue}
        incr count
        if {[catch {::ttmc::marker_targets $marker} target]} {
            lappend skipped [dict create marker $marker reason $target]
            puts "SKIP marker=$marker reason=$target"
            continue
        }
        foreach record $target {
            set identity [list [dict get $record layer] [dict get $record net] [dict get $record bbox] [dict get $record wire]]
            if {$identity in $seen} {continue}
            lappend seen $identity
            lappend candidates $record
        }
    }
    metal_color_set_targets $candidates
    set ::ttmc::scan_skipped $skipped
    puts "METAL_COLOR_SCAN markers=$count candidates=[llength $candidates] skipped=[llength $skipped]"
    puts "No geometry changed. Targets come from CURRENT markers; refresh DRC before scanning."
    return [llength $candidates]
}
if {![info exists ::METAL_COLOR_REPAIR_TARGETS]} {error "Source init.setup or configure METAL_COLOR_REPAIR_TARGETS first"}
if {![info exists ::METAL_COLOR_REPAIR_TARGET_MODE] || $::METAL_COLOR_REPAIR_TARGET_MODE ni {markers configured}} {error "Configure repair mode as markers or configured"}
metal_color_set_targets $::METAL_COLOR_REPAIR_TARGETS
puts "TT Metal Color V21 loaded: metal_color_scan | metal_color_check | metal_color_plan id | metal_color_repair id APPLY | metal_color_verify"
