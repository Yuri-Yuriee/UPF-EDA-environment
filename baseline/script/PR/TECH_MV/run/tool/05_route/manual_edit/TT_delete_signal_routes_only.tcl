# Runtime adapter preserves the historical logical source path.
if {[info exists ::TECH_MV_RUNTIME_ROOT]} {
    info script [file join $::TECH_MV_RUNTIME_ROOT run/tool/05_route/manual_edit/TT_delete_signal_routes_only.tcl]
}
# =============================================================================
# TT_delete_regular_signal_geometry_v1_3.tcl
# VERSION: V1.3_HARD_TYPE_GUARD
#
# Verified against this Innovus DB schema:
#   wire        : .layer, .net
#   via         : .via_def, .net
#   via_def     : .bottom_layer, .cut_layer, .top_layer
#   patch_wire  : optional (current design count may be 0)
#   special_wire / special_via : separate object classes, NEVER selected here
#
# PURPOSE
#   Delete REGULAR signal-routing geometry only:
#       wire / patch_wire / via
#
#   Preserve:
#       special_wire / special_via
#       PG nets and any regular geometry owned by PG nets
#       net objects
#       SDP objects
#       instances / placement
#
# SOURCE POLICY
#   source this file => definitions only; database untouched.
#
# USAGE
#   source run/tool/TT_delete_regular_signal_geometry_v1_3.tcl
#   TT_SIGROUTE_PREVIEW
#   TT_SIGROUTE_APPLY YES
# =============================================================================

set ::TT_SIGROUTE_VERSION "V1.3_HARD_TYPE_GUARD"
set ::TT_SIGROUTE_BATCH_SIZE 1000
set ::TT_SIGROUTE_SAMPLE_MAX 20

proc TT_SIGROUTE__banner {title} {
    puts ""
    puts "======================================================================"
    puts " $title"
    puts "======================================================================"
}

proc TT_SIGROUTE__bool {v} {
    set s [string tolower [string trim $v]]
    return [expr {$s in {1 true yes on}}]
}

proc TT_SIGROUTE__snapshot {} {
    set sdp_count -1
    set inst_count -1
    set net_count -1

    catch {set sdp_count [llength [get_db top_sdps]]}
    catch {set inst_count [llength [get_db insts]]}
    catch {set net_count [llength [get_db nets]]}

    return [dict create \
        sdp_count $sdp_count \
        inst_count $inst_count \
        net_count $net_count]
}

proc TT_SIGROUTE__pg_name_set {} {
    set pg_names {}

    # Logical PG API.
    if {[llength [info commands get_pg_nets]] > 0} {
        if {![catch {set c [get_pg_nets *]}]} {
            if {[llength [info commands foreach_in_collection]] > 0} {
                catch {
                    foreach_in_collection n $c {
                        set name ""
                        catch {set name [get_object_name $n]}
                        if {$name ne ""} {
                            dict set pg_names $name 1
                        }
                    }
                }
            }
        }
    }

    # DB attributes are the second source of truth.
    foreach n [get_db nets] {
        set name ""
        if {[catch {set name [get_db $n .name]}]} {
            continue
        }

        set is_power 0
        set is_ground 0
        catch {set is_power [TT_SIGROUTE__bool [get_db $n .is_power]]}
        catch {set is_ground [TT_SIGROUTE__bool [get_db $n .is_ground]]}

        if {$is_power || $is_ground} {
            dict set pg_names $name 1
        }
    }

    return $pg_names
}

proc TT_SIGROUTE__discover {} {
    # IMPORTANT:
    # We traverse net objects only to reach REGULAR route geometry.
    # Net objects themselves are never selected/deleted.
    #
    # HARD GUARD:
    #   .wires       must contain obj_type == wire
    #   .patch_wires must contain obj_type == patch_wire
    #   .vias        must contain obj_type == via
    #
    # Any special_wire / special_via contamination causes an immediate STOP.

    set pg_names [TT_SIGROUTE__pg_name_set]

    set del_wires {}
    set del_patches {}
    set del_vias {}

    set keep_wires 0
    set keep_patches 0
    set keep_vias 0

    set bad_type_count 0
    set special_contamination_count 0
    set bad_type_samples {}

    foreach n [get_db nets] {
        set name ""
        if {[catch {set name [get_db $n .name]}]} {
            continue
        }

        set is_pg [dict exists $pg_names $name]

        set ws {}
        set ps {}
        set vs {}

        catch {set ws [get_db $n .wires]}
        catch {set ps [get_db $n .patch_wires]}
        catch {set vs [get_db $n .vias]}

        foreach o $ws {
            if {$o eq "" || $o eq "0x0"} { continue }

            set typ ""
            catch {set typ [get_db $o .obj_type]}

            if {$typ ne "wire"} {
                incr bad_type_count
                if {$typ eq "special_wire" || $typ eq "special_via"} {
                    incr special_contamination_count
                }
                if {[llength $bad_type_samples] < 20} {
                    lappend bad_type_samples "wires:$o:type=$typ"
                }
                continue
            }

            if {$is_pg} {
                incr keep_wires
            } else {
                lappend del_wires $o
            }
        }

        foreach o $ps {
            if {$o eq "" || $o eq "0x0"} { continue }

            set typ ""
            catch {set typ [get_db $o .obj_type]}

            if {$typ ne "patch_wire"} {
                incr bad_type_count
                if {$typ eq "special_wire" || $typ eq "special_via"} {
                    incr special_contamination_count
                }
                if {[llength $bad_type_samples] < 20} {
                    lappend bad_type_samples "patch_wires:$o:type=$typ"
                }
                continue
            }

            if {$is_pg} {
                incr keep_patches
            } else {
                lappend del_patches $o
            }
        }

        foreach o $vs {
            if {$o eq "" || $o eq "0x0"} { continue }

            set typ ""
            catch {set typ [get_db $o .obj_type]}

            if {$typ ne "via"} {
                incr bad_type_count
                if {$typ eq "special_wire" || $typ eq "special_via"} {
                    incr special_contamination_count
                }
                if {[llength $bad_type_samples] < 20} {
                    lappend bad_type_samples "vias:$o:type=$typ"
                }
                continue
            }

            # Schema guard for regular via:
            # via must point to a via_def, whose physical layers are defined there.
            set vd ""
            if {[catch {set vd [get_db $o .via_def]}] || $vd eq "" || $vd eq "0x0"} {
                incr bad_type_count
                if {[llength $bad_type_samples] < 20} {
                    lappend bad_type_samples "via_without_via_def:$o"
                }
                continue
            }

            set b ""
            set c ""
            set t ""
            catch {set b [get_db $vd .bottom_layer]}
            catch {set c [get_db $vd .cut_layer]}
            catch {set t [get_db $vd .top_layer]}

            if {$b eq "" || $b eq "0x0" ||
                $c eq "" || $c eq "0x0" ||
                $t eq "" || $t eq "0x0"} {
                incr bad_type_count
                if {[llength $bad_type_samples] < 20} {
                    lappend bad_type_samples "via_bad_layers:$o:via_def=$vd"
                }
                continue
            }

            if {$is_pg} {
                incr keep_vias
            } else {
                lappend del_vias $o
            }
        }
    }

    if {$bad_type_count > 0} {
        puts ""
        puts "ERROR: REGULAR ROUTE OBJECT-TYPE GUARD FAILED"
        puts "  bad/unknown objects          : $bad_type_count"
        puts "  special contamination        : $special_contamination_count"
        foreach s $bad_type_samples {
            puts "  BAD : $s"
        }
        error "TT_SIGROUTE safety stop: candidate set is not pure regular routing geometry."
    }

    set delete_objs [concat $del_wires $del_patches $del_vias]

    return [dict create \
        pg_name_dict $pg_names \
        del_wires $del_wires \
        del_patches $del_patches \
        del_vias $del_vias \
        keep_wires $keep_wires \
        keep_patches $keep_patches \
        keep_vias $keep_vias \
        bad_type_count $bad_type_count \
        special_contamination_count $special_contamination_count \
        delete_objs $delete_objs]
}

proc TT_SIGROUTE__wire_layer_summary {wires} {
    set counts [dict create]

    foreach w $wires {
        set lname "UNKNOWN"
        catch {set lname [get_db $w .layer.name]}
        if {$lname eq "" || $lname eq "0x0"} {
            set lname "UNKNOWN"
        }
        dict incr counts $lname
    }

    return $counts
}

proc TT_SIGROUTE__via_transition_sample {vias} {
    set counts [dict create]
    set seen 0

    foreach v $vias {
        if {$seen >= 5000} {
            break
        }

        set vd ""
        if {[catch {set vd [get_db $v .via_def]}]} {
            continue
        }
        if {$vd eq "" || $vd eq "0x0"} {
            continue
        }

        set b "?"
        set c "?"
        set t "?"

        catch {set b [get_db $vd .bottom_layer.name]}
        catch {set c [get_db $vd .cut_layer.name]}
        catch {set t [get_db $vd .top_layer.name]}

        dict incr counts "$b->$c->$t"
        incr seen
    }

    return [dict create sampled $seen counts $counts]
}

proc TT_SIGROUTE_HELP {} {
    TT_SIGROUTE__banner "TT REGULAR SIGNAL ROUTE GEOMETRY DELETE - HELP"

    puts "Version : $::TT_SIGROUTE_VERSION"
    puts ""
    puts "READ-ONLY:"
    puts "  TT_SIGROUTE_PREVIEW"
    puts ""
    puts "DESTRUCTIVE:"
    puts "  TT_SIGROUTE_APPLY YES"
    puts ""
    puts "DELETE OBJECT TYPES:"
    puts "  wire"
    puts "  patch_wire"
    puts "  via"
    puts ""
    puts "NEVER SELECTED:"
    puts "  special_wire"
    puts "  special_via"
    puts "  net"
    puts "  sdp"
    puts "  inst"
    puts "======================================================================"
}

proc TT_SIGROUTE_PREVIEW {} {
    TT_SIGROUTE__banner "TT REGULAR SIGNAL ROUTE GEOMETRY - PREVIEW"

    set snap [TT_SIGROUTE__snapshot]
    set d [TT_SIGROUTE__discover]

    set wires [dict get $d del_wires]
    set patches [dict get $d del_patches]
    set vias [dict get $d del_vias]

    puts "Version                         : $::TT_SIGROUTE_VERSION"
    puts "SDP objects                     : [dict get $snap sdp_count]"
    puts "Instances                       : [dict get $snap inst_count]"
    puts "Net objects                     : [dict get $snap net_count]"
    puts "Protected PG nets               : [dict size [dict get $d pg_name_dict]]"
    puts "Special-route contamination     : [dict get $d special_contamination_count]  (MUST BE 0)"
    puts ""
    puts "REGULAR SIGNAL GEOMETRY TO DELETE"
    puts "  wire                          : [llength $wires]"
    puts "  patch_wire                    : [llength $patches]"
    puts "  via                           : [llength $vias]"
    puts "  TOTAL                         : [llength [dict get $d delete_objs]]"
    puts ""
    puts "REGULAR GEOMETRY PROTECTED BECAUSE OWNER IS PG"
    puts "  wire                          : [dict get $d keep_wires]"
    puts "  patch_wire                    : [dict get $d keep_patches]"
    puts "  via                           : [dict get $d keep_vias]"

    puts ""
    puts "WIRE COUNT BY PHYSICAL LAYER:"
    set wc [TT_SIGROUTE__wire_layer_summary $wires]
    foreach layer [lsort [dict keys $wc]] {
        puts [format "  %-20s : %d" $layer [dict get $wc $layer]]
    }

    puts ""
    puts "VIA TRANSITION SAMPLE (first <=5000 regular signal vias):"
    set vs [TT_SIGROUTE__via_transition_sample $vias]
    puts "  sampled = [dict get $vs sampled]"
    foreach key [lsort [dict keys [dict get $vs counts]]] {
        puts [format "  %-24s : %d" $key [dict get [dict get $vs counts] $key]]
    }

    puts ""
    puts "GUARANTEE:"
    puts "  candidate obj_type is hard-checked: wire / patch_wire / via only."
    puts "  special_wire / special_via contamination => immediate FAIL."
    puts "  net objects are not selected."
    puts "  SDP / instance / placement are not modified."
    puts ""
    puts "RESULT : PREVIEW PASS"
    puts "NEXT   : TT_SIGROUTE_APPLY YES"
    puts "======================================================================"
    return 1
}

proc TT_SIGROUTE_APPLY {{confirm ""}} {
    if {$confirm ne "YES"} {
        error "Destructive command. Run exactly: TT_SIGROUTE_APPLY YES"
    }

    TT_SIGROUTE__banner "TT REGULAR SIGNAL ROUTE GEOMETRY - APPLY"

    set before [TT_SIGROUTE__snapshot]
    set d [TT_SIGROUTE__discover]
    set objs [dict get $d delete_objs]

    puts "Version                         : $::TT_SIGROUTE_VERSION"
    puts "Regular signal route objects    : [llength $objs]"
    puts "Special-route contamination     : [dict get $d special_contamination_count]  (MUST BE 0)"
    puts "SDP before                      : [dict get $before sdp_count]"
    puts "Instances before                : [dict get $before inst_count]"
    puts "Net objects before              : [dict get $before net_count]"
    puts "Batch size                      : $::TT_SIGROUTE_BATCH_SIZE"
    puts ""

    if {[llength $objs] == 0} {
        puts "RESULT : PASS (nothing to delete)"
        puts "======================================================================"
        return 1
    }

    set total [llength $objs]
    set batch_id 0
    set selected_total 0

    for {set i 0} {$i < $total} {incr i $::TT_SIGROUTE_BATCH_SIZE} {
        set j [expr {min($i + $::TT_SIGROUTE_BATCH_SIZE - 1, $total - 1)}]
        set batch [lrange $objs $i $j]
        incr batch_id

        catch {deselect_obj -all}

        if {[catch {select_obj $batch} err]} {
            catch {deselect_obj -all}
            error "TT_SIGROUTE select_obj failed at batch $batch_id: $err"
        }

        set sel_count 0
        catch {set sel_count [llength [get_db selected]]}
        incr selected_total $sel_count

        if {$sel_count > 0} {
            if {[catch {delete_routes -selected} err]} {
                catch {deselect_obj -all}
                error "TT_SIGROUTE delete_routes -selected failed at batch $batch_id: $err"
            }
        }

        catch {deselect_obj -all}

        if {$batch_id == 1 || ($batch_id % 50) == 0 || $j == ($total - 1)} {
            puts [format \
                "  batch %-5d object_index=%d..%d selected=%d" \
                $batch_id $i $j $sel_count]
        }
    }

    catch {deselect_obj -all}

    set after [TT_SIGROUTE__snapshot]

    set sdp_same [expr {[dict get $before sdp_count] == [dict get $after sdp_count]}]
    set inst_same [expr {[dict get $before inst_count] == [dict get $after inst_count]}]
    set net_same [expr {[dict get $before net_count] == [dict get $after net_count]}]

    puts ""
    puts "----------------------------------------------------------------------"
    puts " APPLY SUMMARY"
    puts "----------------------------------------------------------------------"
    puts "Targeted regular route objects  : $total"
    puts "Selected route objects          : $selected_total"
    puts "SDP before/after                : [dict get $before sdp_count] / [dict get $after sdp_count]"
    puts "Instances before/after          : [dict get $before inst_count] / [dict get $after inst_count]"
    puts "Net objects before/after        : [dict get $before net_count] / [dict get $after net_count]"
    puts "SDP count unchanged             : $sdp_same"
    puts "Instance count unchanged        : $inst_same"
    puts "Net-object count unchanged      : $net_same"

    if {!$sdp_same || !$inst_same || !$net_same} {
        puts "RESULT : FAIL"
        puts "======================================================================"
        error "TT_SIGROUTE guard failed: non-routing object count changed."
    }

    puts "RESULT : PASS"
    puts "SPECIAL routing was never selected."
    puts "======================================================================"
    return 1
}

puts "INFO: Loaded TT_delete_regular_signal_geometry_v1_3.tcl"
puts "INFO: VERSION = $::TT_SIGROUTE_VERSION"
puts "INFO: SOURCE-SAFE: DB untouched."
puts "INFO: PREVIEW = TT_SIGROUTE_PREVIEW"
puts "INFO: APPLY   = TT_SIGROUTE_APPLY YES"
