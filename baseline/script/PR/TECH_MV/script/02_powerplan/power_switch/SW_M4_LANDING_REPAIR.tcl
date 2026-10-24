# Runtime adapter preserves the historical logical source path.
if {[info exists ::TECH_MV_RUNTIME_ROOT]} {
    info script [file join $::TECH_MV_RUNTIME_ROOT run/tool/02_powerplan/power_switch/TT_SW_M4_LANDING_REPAIR.tcl]
} else {
    info script [file normalize [file join [file dirname [info script]] .. .. .. run/tool/02_powerplan/power_switch/TT_SW_M4_LANDING_REPAIR.tcl]]
}
# Load definitions only; no APR action or setup reload is performed here.
if {![llength [info commands ::tech_mv_library_value]]} {
    if {[info exists ::TOOL_DIR]} {
        source -quiet [file join $::TECH_MV_RUNTIME_ROOT .. script PR TECH_MV script 00_common private_parameter_config.tcl]
    } else {
        source -quiet [file join $::TECH_MV_RUNTIME_ROOT .. script PR TECH_MV script 00_common private_parameter_config.tcl]
    }
}
# PUBLIC_EXPORT_REVIEW_REQUIRED: residual technology candidates require manual review.
# TECH V09 - Both SW configured switch supply pin landing sites must have M4->M5 VIA4.
# No manual coordinates, no create_shape, NO M5 PATCH and no SW movement.
# A repair may add legal vias ONLY; ViaGen refusal is a real FAIL, not PASS.
namespace eval ::TT_SW_M4 {
 variable target_inst [::tech_mv_library_value SW_LANDING_TARGET_INSTANCE]
 variable net [::tech_mv_library_value SW_LANDING_TARGET_NET]
 variable sites {}
 variable last_instance {}
 variable margin [::tech_mv_private_value {sw_m4_landing::search_margin}]
}
proc ::TT_SW_M4::att {o a} {if {[catch {get_db $o $a} v]} {return {}}; return $v}
proc ::TT_SW_M4::numbers {v n} {
 set v [string trim $v " {}"]
 if {[llength $v] != $n} {return {}}
 foreach x $v {if {![string is double -strict $x]} {return {}}}
 return $v
}
proc ::TT_SW_M4::rect {v} {
 set v [::TT_SW_M4::numbers $v 4]
 if {$v eq ""} {return {}}
 lassign $v a b c d
 if {$a >= $c || $b >= $d} {return {}}
 return $v
}
proc ::TT_SW_M4::expand {r m} {
 lassign $r a b c d
 return [list [expr {$a-$m}] [expr {$b-$m}] [expr {$c+$m}] [expr {$d+$m}]]
}
proc ::TT_SW_M4::touches {a b} {
 lassign $a x1 y1 x2 y2; lassign $b u1 v1 u2 v2
 expr {min($x2,$u2)>max($x1,$u1) && min($y2,$v2)>max($y1,$v1)}
}
proc ::TT_SW_M4::objects {area kind} {
 if {[catch {get_obj_in_area -area $area -obj_type $kind} v]} {error "QUERY $kind failed: $v"}
 return $v
}
proc ::TT_SW_M4::via45_at {point area} {
 set found {}
 foreach v [::TT_SW_M4::objects $area special_via] {
  if {[::TT_SW_M4::att $v .net.name] ne $::TT_SW_M4::net} {continue}
  set master [::TT_SW_M4::att $v .via_def.name]
  # Tool-generated via names are VIAGEN45_* in this Innovus DB.
  if {![regexp {(^|[^0-9])45([^0-9]|$)} $master] && ![string match *45* $master]} {continue}
  set p [::TT_SW_M4::numbers [::TT_SW_M4::att $v .point] 2]
  if {$p eq ""} {continue}
  lassign $p x y; lassign $point px py
  if {abs($x-$px)<0.0005 && abs($y-$py)<0.0005} {lappend found $master}
 }
 return $found
}
proc ::TT_SW_M4::discover {{instance {}}} {
 variable target_inst; variable net; variable sites; variable last_instance; variable margin
 set sites {}; set last_instance {}
 if {$instance eq ""} {set instance $target_inst}
 set insts [get_db insts $instance]
 if {[llength $insts] != 1} {error "Expected exactly one SW instance, got [llength $insts]"}
 set inst [lindex $insts 0]
 set swbox [::TT_SW_M4::rect [::TT_SW_M4::att $inst .bbox]]
 if {$swbox eq ""} {error "SW bbox unavailable"}
 set ok 0
 foreach p [::TT_SW_M4::att $inst .pg_pins] {
  if {[string match [::tech_mv_library_value SW_LANDING_PG_PIN_PATTERN] [::TT_SW_M4::att $p .name]] && [::TT_SW_M4::att $p .net.name] eq $net} {set ok 1}
 }
 if {!$ok} {error "SW [::tech_mv_library_value SW_LANDING_POWER_PIN] net mismatch: expected $net"}
 set area [::TT_SW_M4::expand $swbox [::tech_mv_private_value {sw_m4_landing::scan_area_margin}]]
 set m5 {}
 foreach w [::TT_SW_M4::objects $area special_wire] {
  if {[::TT_SW_M4::att $w .net.name] eq $net && [::TT_SW_M4::att $w .layer.name] eq "M5"} {
   set b [::TT_SW_M4::rect [::TT_SW_M4::att $w .rect]]
   if {$b ne "" && [::TT_SW_M4::touches $b $swbox]} {lappend m5 $b}
  }
 }
 if {[llength $m5]!=1} {error "Expected exactly one [::tech_mv_library_value SW_LANDING_TARGET_NET] M5 stripe over SW; got [llength $m5]. Fail closed."}
 set candidates {}
 foreach v [::TT_SW_M4::objects $area special_via] {
  if {[::TT_SW_M4::att $v .net.name] ne $net} {continue}
  if {![string match *34* [::TT_SW_M4::att $v .via_def.name]]} {continue}
  set p [::TT_SW_M4::numbers [::TT_SW_M4::att $v .point] 2]
  set top [::TT_SW_M4::rect [::TT_SW_M4::att $v .top_rects]]
  if {$p eq "" || $top eq "" || ![::TT_SW_M4::touches $top $swbox]} {continue}
  lappend candidates [dict create point $p m4_via3_top $top via3_master [::TT_SW_M4::att $v .via_def.name]]
 }
 if {[llength $candidates]!=2} {error "Expected exactly two [::tech_mv_library_value SW_LANDING_POWER_PIN] VIA3 sites, got [llength $candidates]. Fail closed."}
 set candidates [lsort -real -index 0 [lmap s $candidates {list [lindex [dict get $s point] 1] $s}]]
 set sorted {}; foreach item $candidates {lappend sorted [lindex $item 1]}
 set names {LOWER UPPER}; set idx 0
 foreach s $sorted {
  set name [lindex $names $idx]; incr idx
  set p [dict get $s point]; set b [dict get $s m4_via3_top]
  set found 0
  foreach stripe $m5 {if {[::TT_SW_M4::touches $stripe $b]} {set found 1}}
  if {!$found} {error "$name: VIA3 M4 enclosure does not overlap M5 [::tech_mv_library_value SW_LANDING_TARGET_NET]; no safe via-only repair"}
  set region [::TT_SW_M4::expand $b $margin]
  dict set s label $name; dict set s region $region
  lappend sites $s
 }
 set last_instance $instance
 return $sites
}
proc ::TT_SW_M4::probe {{instance {}}} {
 variable sites; variable net
 ::TT_SW_M4::discover $instance
 puts "=== TT SW VIA4 BOTH-SITE PROBE V09 (READ ONLY) ==="
 puts "SW=$::TT_SW_M4::last_instance NET=$net NO_M5_PATCH=1 NO_NEW_METAL=1"
 foreach s $sites {
  set p [dict get $s point]; set a [dict get $s region]
  set hits [::TT_SW_M4::via45_at $p $a]
  set result [expr {[llength $hits] ? "PRESENT" : "MISSING"}]
  puts "SITE=[dict get $s label] POINT=$p VIA3_M4_FOOTPRINT=[dict get $s m4_via3_top] VIA4=$result MASTERS=$hits"
 }
 puts "No geometry changed. Repair is VIA-ONLY. Existing M5 will not be modified."
 return $sites
}

# V09 is deliberately read-only. Previously attempted via-only insertion failed in
# both sites; do not automatically repeat an ineffective write operation.
proc ::TT_SW_M4::intersection {a b} {
 lassign $a x1 y1 x2 y2; lassign $b u1 v1 u2 v2
 set z [list [expr {max($x1,$u1)}] [expr {max($y1,$v1)}] [expr {min($x2,$u2)}] [expr {min($y2,$v2)}]]
 return [::TT_SW_M4::rect $z]
}
proc ::TT_SW_M4::inspect_objects {area kind} {
 if {[catch {get_obj_in_area -area $area -obj_type $kind} found err]} {
  puts "QUERY_UNSUPPORTED type=$kind reason=$found"; return
 }
 set total [llength $found]; set printed 0
 foreach o $found {
  if {$printed>=12} {break}
  set nt [::TT_SW_M4::att $o .net.name]
  set ln [::TT_SW_M4::att $o .layer.name]
  set geom {}
  foreach prop {.rect .bbox} {
   if {![catch {get_db $o $prop} val] && $val ne {}} {set geom $val; break}
  }
  puts "NEARBY type=$kind net=$nt layer=$ln geometry=$geom"
  incr printed
 }
 puts "NEARBY_SUMMARY type=$kind count=$total shown=$printed"
}
proc ::TT_SW_M4::diagnose {{instance {}}} {
 variable net
 set ss [::TT_SW_M4::probe $instance]
 puts "=== V09 GEOMETRY AND VIABILITY DIAGNOSIS (READ-ONLY) ==="
 set sw [lindex [get_db insts $::TT_SW_M4::last_instance] 0]
 set swbox [::TT_SW_M4::rect [::TT_SW_M4::att $sw .bbox]]
 set area [::TT_SW_M4::expand $swbox [::tech_mv_private_value {sw_m4_landing::verify_area_margin}]]
 set stripes {}
 foreach w [::TT_SW_M4::objects $area special_wire] {
  if {[::TT_SW_M4::att $w .net.name] ne $net} {continue}
  if {[::TT_SW_M4::att $w .layer.name] ne "M5"} {continue}
  set r [::TT_SW_M4::rect [::TT_SW_M4::att $w .rect]]
  if {$r ne {}} {lappend stripes $r}
 }
 if {[llength $stripes]!=1} {error "Expected one same-net M5 stripe; found [llength $stripes]; cannot assess"}
 set m5 [lindex $stripes 0]
 puts "M5_STRIPE_NET=$net RECT=$m5"
 foreach site $ss {
  set name [dict get $site label]
  set via3 [dict get $site m4_via3_top]
  set overlap [::TT_SW_M4::intersection $m5 $via3]
  set xw 0; set yw 0
  if {$overlap ne {}} {lassign $overlap x1 y1 x2 y2; set xw [expr {$x2-$x1}]; set yw [expr {$y2-$y1}]}
  puts [format "SITE=%s M4_FROM_VIA3=%s M5_OVERLAP=%s WIDTH_UM=%.6f HEIGHT_UM=%.6f VIA4=MISSING" $name $via3 $overlap $xw $yw]
  puts "SITE=$name INFERENCE=DRC_LEGAL_VIA_NOT_PROVEN; VIA45_RULE_AND_FULL_M4_SHAPES_REQUIRED"
 }
 puts "=== NEARBY NON-SPECIAL GEOMETRY ==="
 foreach kind {wire patch_wire route_blockage inst_obs_shape} {::TT_SW_M4::inspect_objects $area $kind}
 puts "=== VIA45 DEFINITION DISCOVERY ==="
 if {[catch {get_db via_defs} defs]} {
  puts "VIA_DEF_DISCOVERY_UNSUPPORTED reason=$defs"
 } else {
  set cnt 0
  foreach def $defs {
   set name [::TT_SW_M4::att $def .name]
   if {![string match *45* $name] && ![string match *VIA4* $name]} {continue}
   puts "VIA45_CANDIDATE=$name"
   incr cnt
   if {$cnt>=20} {break}
  }
  puts "VIA45_CANDIDATES_SHOWN=$cnt"
 }
 puts "AUTO_STATUS=NO_WRITE; NO_M5_PATCH=1; NO_MANUAL_COORDINATES=1"
 puts "NEXT=Review layer M4/M5 and via45 rules before considering M4-only or via-only repair"
 return $ss
}
proc ::TT_SW_M4::repair {args} {
 error "V09 REPAIR DISABLED: V07/V08 ViaGen created zero vias at BOTH sites. Use ::TT_SW_M4::diagnose; no M5 patch will be added."
}
puts "TT_SW_M4_LANDING_REPAIR V09 loaded. Run ::TT_SW_M4::diagnose (READ-ONLY)."

# V10: tightly scoped, M4-ONLY landing experiment. NEVER touches M5.
# Target rectangles derived from the actual VIA3 M4 footprint and existing M5 stripe.
# No attempt to infer design-wide policy from one SW.
proc ::TT_SW_M4::v10_via45_site {site m5} {
 variable net
 set r [dict get $site region]
 set landing [dict get $site landing]
 set via3 [dict get $site m4_via3_top]
 set hits {}
 foreach v [::TT_SW_M4::objects $r special_via] {
  if {[::TT_SW_M4::att $v .net.name] ne $net} {continue}
  set master [::TT_SW_M4::att $v .via_def.name]
  if {![string match *45* $master]} {continue}
  set bottom [::TT_SW_M4::rect [::TT_SW_M4::att $v .bottom_rects]]
  set top [::TT_SW_M4::rect [::TT_SW_M4::att $v .top_rects]]
  if {$bottom eq {} || $top eq {}} {continue}
  if {![::TT_SW_M4::touches $bottom $landing]} {continue}
  if {![::TT_SW_M4::touches $top $m5]} {continue}
  # Need continuous M4 bridge between new VIA45 and VIA3 M4 top.
  if {![::TT_SW_M4::touches $landing $via3]} {continue}
  lappend hits $master
 }
 return $hits
}
proc ::TT_SW_M4::v10_plan {{instance {}}} {
 variable net
 set sites [::TT_SW_M4::discover $instance]
 set sw [lindex [get_db insts $::TT_SW_M4::last_instance] 0]
 set swbox [::TT_SW_M4::rect [::TT_SW_M4::att $sw .bbox]]
 set m5s {}
 foreach w [::TT_SW_M4::objects [::TT_SW_M4::expand $swbox [::tech_mv_private_value {sw_m4_landing::patch_wire_scan_margin}]] special_wire] {
  if {[::TT_SW_M4::att $w .net.name] eq $net && [::TT_SW_M4::att $w .layer.name] eq "M5"} {
   set b [::TT_SW_M4::rect [::TT_SW_M4::att $w .rect]]
   if {$b ne {} && [::TT_SW_M4::touches $b $swbox]} {lappend m5s $b}
  }
 }
 if {[llength $m5s] != 1} {error "V10: required unique M5 stripe missing"}
 set m5 [lindex $m5s 0]
 set planned {}
 foreach site $sites {
  set footprint [dict get $site m4_via3_top]
  lassign $footprint fx1 fy1 fx2 fy2
  lassign $m5 mx1 my1 mx2 my2
  # Match the VIA3 M4 vertical span; extend M4 LEFT to the left boundary of existing M5.
  # This creates continuous M4 joining the existing VIA3 M4 enclosure.
  if {!($mx1 < $fx1 && $mx2 > $fx1 && $fx2 > $mx2)} {
   error "V10: unexpected stripe/footprint geometry; no automatic M4 patch"
  }
  set landing [::TT_SW_M4::rect [list $mx1 $fy1 $fx2 $fy2]]
  if {$landing eq {}} {error "V10: empty landing"}
  if {[expr {[lindex $landing 2]-[lindex $landing 0]}] > [::tech_mv_private_value {sw_m4_landing::max_patch_width}]} {error "V10: patch too wide"}
  if {[expr {[lindex $landing 3]-[lindex $landing 1]}] > [::tech_mv_private_value {sw_m4_landing::max_patch_height}]} {error "V10: patch too high"}
  # Inspect existing routed and special M4. Unsupported geometry is not silently ignored.
  set area [::TT_SW_M4::expand $landing [::tech_mv_private_value {sw_m4_landing::landing_area_margin}]]
  foreach kind {special_wire wire patch_wire} {
   foreach obj [::TT_SW_M4::objects $area $kind] {
    set lay [::TT_SW_M4::att $obj .layer.name]
    if {$lay ne "M4"} {continue}
    set other [::TT_SW_M4::att $obj .net.name]
    set geom {}
    foreach prop {.rect .bbox} {
     if {![catch {get_db $obj $prop} r]} {set geom [::TT_SW_M4::rect $r]; if {$geom ne {}} {break}}
    }
    if {$geom eq {}} {error "V10: unknown M4 geometry kind=$kind net=$other; STOP"}
    if {$other ne $net && [::TT_SW_M4::touches $geom $landing]} {
     error "V10: foreign net $other on M4 intersects planned landing; STOP"
    }
   }
  }
  dict set site landing $landing
  lappend planned $site
 }
 puts "=== V10 M4-ONLY LANDING PLAN (no DB edits) ==="
 puts "SW=$::TT_SW_M4::last_instance NET=$net EXISTING_M5=$m5 NO_M5_PATCH=1"
 foreach s $planned {
  puts "SITE=[dict get $s label] VIA3=[dict get $s point] M4_PATCH=[dict get $s landing]"
 }
 puts "PREFLIGHT=PASS_FOR_EXPERIMENT; physical DRC NOT proven. checkpoint required before apply."
 return [dict create sites $planned m5 $m5]
}
proc ::TT_SW_M4::repair {authorization} {
 if {$authorization ne "I_HAVE_RESTORABLE_DB_CHECKPOINT"} {
  error "Refusing DB writes without I_HAVE_RESTORABLE_DB_CHECKPOINT"
 }
 set plan [::TT_SW_M4::v10_plan]
 set sites [dict get $plan sites]
 set m5 [dict get $plan m5]
 puts "=== V10 WRITE: TWO M4 PATCHES ONLY; NO M5 CHANGES ==="
 foreach site $sites {
  set label [dict get $site label]
  set landing [dict get $site landing]
  puts "SITE=$label CREATE_M4=$landing"
  # create_shape is an Innovus-supported, user-verified command.
  create_shape -layer [::tech_mv_library_value LIB_TECH_003] -net $::TT_SW_M4::net -shape stripe -status fixed -rect $landing
 }
 foreach site $sites {
  set label [dict get $site label]
  set region [dict get $site region]
  puts "SITE=$label VIA45_ATTEMPT_REGION=$region"
  update_power_vias -add_vias 1 -nets $::TT_SW_M4::net -bottom_layer [::tech_mv_library_value LIB_TECH_003] -top_layer [::tech_mv_library_value LIB_TECH_004] -area [list $region] -orthogonal_only 0
 }
 set failures {}
 foreach site $sites {
  set label [dict get $site label]
  set hits [::TT_SW_M4::v10_via45_site $site $m5]
  puts "SITE=$label VIA45_MASTERS=$hits"
  set rep [tech_mv_output_path report "TT_SW_V10_${label}_via45_after.rpt" 02 sw_m4]
  check_power_vias -nets $::TT_SW_M4::net -layer_range {M4 M5} -area [dict get $site region] -non_orthogonal_check -check_wire_pin_overlap -report $rep
  puts "SITE=$label REPORT=$rep"
  if {[llength $hits] == 0} {lappend failures $label}
 }
 if {[llength $failures]} {
  puts "RESULT=FAIL SITES=$failures M4_PATCHES_ALREADY_CREATED=1 PLEASE_RESTORE_DB_CHECKPOINT_IF_NEEDED"
  error "V10: missing VIA45 after M4 patch. Do not treat as connected; rollback Innovus DB checkpoint."
 }
 puts "RESULT=VIA45_PRESENT_BOTH_SITES; RUN_PHYSICAL_DRC_AND_LVS_BEFORE_ACCEPTANCE"
}
puts "TT_SW_M4_LANDING_REPAIR V10 loaded. Run ::TT_SW_M4::v10_plan first, then ::TT_SW_M4::repair I_HAVE_RESTORABLE_DB_CHECKPOINT."

# V11 BATCH extension: explicit preflight and resumable per-switch repair.
# Reuses successful V10 geometry, requires unique configured switch supply pin=configured secondary supply + two VIA3 + one M5.
namespace eval ::TT_SW_M4 {
 variable batch_plan {}
 variable batch_report "TT_SW_M4_V11_preflight.tsv"
}
proc ::TT_SW_M4::v11_targets {} {
 set matches [get_db insts [::tech_mv_library_value SW_LANDING_INSTANCE_PATTERN]]
 set out {}
 foreach inst $matches {
  set name [::TT_SW_M4::att $inst .name]
  if {$name eq {}} {continue}
  set good 0
  foreach pin [::TT_SW_M4::att $inst .pg_pins] {
   if {[string match [::tech_mv_library_value SW_LANDING_PG_PIN_PATTERN] [::TT_SW_M4::att $pin .name]] && [::TT_SW_M4::att $pin .net.name] eq "[::tech_mv_library_value SW_LANDING_TARGET_NET]"} {set good 1; break}
  }
  if {$good} {lappend out $name}
 }
 return [lsort -unique $out]
}
proc ::TT_SW_M4::v11_missing {plan} {
 set missing {}
 set m5 [dict get $plan m5]
 foreach s [dict get $plan sites] {
  if {![llength [::TT_SW_M4::v10_via45_site $s $m5]]} {lappend missing $s}
 }
 return $missing
}
proc ::TT_SW_M4::v11_preflight {{report ""}} {
 if {$report eq ""} { set report [tech_mv_output_path report TT_SW_M4_V11_preflight.tsv 02 sw_m4] }
 variable batch_plan
 set batch_plan {}
 set names [::TT_SW_M4::v11_targets]
 set fd [open $report w]
 puts $fd "instance\tstatus\tmissing_sites\tdetails"
 set total 0; set candidate 0; set complete 0; set reject 0
 foreach name $names {
  incr total
  if {[catch {::TT_SW_M4::v10_plan $name} p]} {
   incr reject
   puts $fd "$name\tSKIP_UNSAFE\t-\t[string map [list \t " " \n " "] $p]"
   continue
  }
  set missing [::TT_SW_M4::v11_missing $p]
  if {![llength $missing]} {
   incr complete
   puts $fd "$name\tALREADY_COMPLETE\t0\tBoth VIA45 present"
   continue
  }
  set labels [lmap s $missing {dict get $s label}]
  lappend batch_plan $name
  incr candidate
  puts $fd "$name\tCANDIDATE\t[join $labels ,]\tM4-only, M5 unchanged"
 }
 close $fd
 puts "V11_PREFLIGHT total_[::tech_mv_library_value SW_LANDING_POWER_PIN]_SW=$total candidates=$candidate already_complete=$complete skipped_unsafe=$reject report=$report"
 puts "V11_NO_DB_WRITES=1; REVIEW_REPORT_AND_SAVE_INNOVUS_DB_BEFORE_APPLY=1"
 return [dict create total $total candidates $candidate already_complete $complete skipped_unsafe $reject report $report]
}
proc ::TT_SW_M4::v11_apply {authorization {max_count 0}} {
 variable batch_plan
 if {$authorization ne "I_HAVE_RESTORABLE_DB_CHECKPOINT"} {error "DB checkpoint authorization required"}
 if {![llength $batch_plan]} {error "No prepared candidates. Run ::TT_SW_M4::v11_preflight first in this session"}
 if {![string is integer -strict $max_count] || $max_count < 0} {error "max_count must be nonnegative integer (0 = all)"}
 set log [tech_mv_output_path log "TT_SW_M4_V11_apply_[clock format [clock seconds] -format %Y%m%d_%H%M%S]_[clock clicks -microseconds].tsv" 02 sw_m4]
 set f [open $log w]
 puts $f "instance\tstatus\tvia45_added_targets\tdetail"
 set done 0; set fail 0; set skip 0
 foreach name $batch_plan {
  if {$max_count > 0 && $done >= $max_count} {break}
  if {[catch {::TT_SW_M4::v10_plan $name} p]} {
   incr skip
   puts $f "$name\tRECHECK_UNSAFE\t0\t[string map [list \t " " \n " "] $p]"
   flush $f
   continue
  }
  set missing [::TT_SW_M4::v11_missing $p]
  if {![llength $missing]} {incr skip; puts $f "$name\tALREADY_COMPLETE\t0\tNo change"; flush $f; continue}
  set m5 [dict get $p m5]
  set expected [llength $missing]
  set err {}
  foreach s $missing {
   set label [dict get $s label]
   set landing [dict get $s landing]
   if {[catch {create_shape -layer [::tech_mv_library_value LIB_TECH_003] -net [::tech_mv_library_value SW_LANDING_TARGET_NET] -shape stripe -status fixed -rect $landing} e]} {
    set err "CREATE_M4_${label}:$e"; break
   }
   if {[catch {update_power_vias -add_vias 1 -nets [::tech_mv_library_value SW_LANDING_TARGET_NET] -bottom_layer [::tech_mv_library_value LIB_TECH_003] -top_layer [::tech_mv_library_value LIB_TECH_004] -area [list [dict get $s region]] -orthogonal_only 0} e]} {
    set err "VIA_GEN_${label}:$e"; break
   }
  }
  set count 0
  foreach s $missing {
   if {[llength [::TT_SW_M4::v10_via45_site $s $m5]]} {incr count}
  }
  if {$err eq {} && $count == $expected} {
   incr done
   puts $f "$name\tVIA45_PRESENT\t$count\tPhysical DRC/LVS not checked"
   puts "V11_SW_PASS=$name repaired_sites=$count"
  } else {
   incr fail
   puts $f "$name\tFAILED_PARTIAL_DB_POSSIBLE\t$count\t[string map [list \t " " \n " "] $err]"
   puts "V11_HALT_FAILURE=$name expected=$expected confirmed=$count error=$err; RESTORE_DB_CHECKPOINT"
   flush $f; close $f
   error "V11 stopped on partial/failed repair; report=$log. Restore Innovus DB checkpoint before retry."
  }
  flush $f
 }
 close $f
 puts "V11_APPLY_DONE repaired_instances=$done skipped=$skip failed=$fail report=$log; RUN DRC, PG connectivity, LVS"
 return $log
}
puts "TT_SW_M4_LANDING_REPAIR V11 batch extension loaded. Run ::TT_SW_M4::v11_preflight then ::TT_SW_M4::v11_apply I_HAVE_RESTORABLE_DB_CHECKPOINT (0=all)."
