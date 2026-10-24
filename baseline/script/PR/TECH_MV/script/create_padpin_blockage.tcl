# =============================================================================
# Pad-pin PG route blockage
# User-adjustable geometry lives in setup/config/02_powerplan.config.tcl.
# =============================================================================

foreach powerpad [get_db insts -if [format {.base_cell.name == %s} $POWERPLAN_PAD_CELL_PATTERN]] {
    set llx [get_db $powerpad .bbox.ll.x]
    set lly [get_db $powerpad .bbox.ll.y]
    set urx [get_db $powerpad .bbox.ur.x]
    set ury [get_db $powerpad .bbox.ur.y]
    set orient [get_db $powerpad .orient]

    set inner $POWERPLAN_PAD_PIN_BLOCKAGE_INNER_OFFSET
    set outer $POWERPLAN_PAD_PIN_BLOCKAGE_OUTER_OFFSET
    set gap   $POWERPLAN_PAD_PIN_BLOCKAGE_CORE_GAP

    puts "$powerpad $llx $lly $urx $ury $orient"

    if {$orient eq "r0"} {
        set core_lly [get_db designs .core_bbox.ll.y]
        set rect [list [expr {$llx+$inner}] $ury [expr {$urx-$outer}] [expr {$core_lly-$gap}]]
    } elseif {$orient eq "my"} {
        set core_lly [get_db designs .core_bbox.ll.y]
        set rect [list [expr {$llx+$outer}] $ury [expr {$urx-$inner}] [expr {$core_lly-$gap}]]
    } elseif {$orient eq "r90"} {
        set core_urx [get_db designs .core_bbox.ur.x]
        set rect [list [expr {$core_urx+$gap}] [expr {$lly+$inner}] $llx [expr {$ury-$outer}]]
    } elseif {$orient eq "my90"} {
        set core_urx [get_db designs .core_bbox.ur.x]
        set rect [list [expr {$core_urx+$gap}] [expr {$lly+$outer}] $llx [expr {$ury-$inner}]]
    } elseif {$orient eq "r180"} {
        set core_ury [get_db designs .core_bbox.ur.y]
        set rect [list [expr {$llx+$outer}] [expr {$core_ury+$gap}] [expr {$urx-$inner}] $lly]
    } elseif {$orient eq "mx"} {
        set core_ury [get_db designs .core_bbox.ur.y]
        set rect [list [expr {$llx+$inner}] [expr {$core_ury+$gap}] [expr {$urx-$outer}] $lly]
    } elseif {$orient eq "r270"} {
        set core_llx [get_db designs .core_bbox.ll.x]
        set rect [list $urx [expr {$lly+$outer}] [expr {$core_llx-$gap}] [expr {$ury-$inner}]]
    } elseif {$orient eq "mx90"} {
        set core_llx [get_db designs .core_bbox.ll.x]
        set rect [list $urx [expr {$lly+$inner}] [expr {$core_llx-$gap}] [expr {$ury-$outer}]]
    } else {
        puts "WARNING: Unsupported power-pad orientation '$orient' for $powerpad; skip blockage."
        continue
    }

    create_route_blockage \
        -name $POWERPLAN_PAD_PIN_BLOCKAGE_NAME \
        -pg_nets \
        -rects $rect \
        -layer $POWERPLAN_PAD_PIN_BLOCKAGE_LAYERS
}
