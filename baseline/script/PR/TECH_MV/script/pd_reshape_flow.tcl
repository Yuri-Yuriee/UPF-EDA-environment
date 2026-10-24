# =============================================================================
# Configurable TECH_MV Power-Domain Reshape Flow
# =============================================================================
source -quiet [file join $TOOL_DIR 01_floorplan geometry TT_proc_pd_geometry.tcl]

# Power-Domain user configuration is loaded from setup/config/01_floorplan.config.tcl.

# Find a per-domain config entry. An exact power-domain key has priority;
# 'selected' is a convenient fallback when the target came from GUI selection;
# 'default' is the final fallback.
proc tt_pd_flow_get_target_config {config pd_name} {
    if {[dict exists $config $pd_name]} {
        return [list true [dict get $config $pd_name]]
    }
    foreach fallback_key {selected @selected <selected> default} {
        if {[dict exists $config $fallback_key]} {
            return [list true [dict get $config $fallback_key]]
        }
    }
    return [list false {}]
}

# Expand dictionary keys such as 'selected' into the actual mouse-selected
# power-domain names. Used by scale/aspect-ratio post-processing.
proc tt_pd_flow_expand_target_config {config strict} {
    set expanded {}
    foreach target_spec [dict keys $config] {
        if {$target_spec eq "default"} {
            # 'default' is meaningful only as a fallback for a known base target.
            continue
        }
        set target_domains [tt_pd_resolve_power_domains [list $target_spec] $strict]
        foreach pd_name $target_domains {
            if {[dict exists $expanded $pd_name]} {
                error "Power domain '$pd_name' is configured more than once after resolving GUI selection."
            }
            dict set expanded $pd_name [dict get $config $target_spec]
        }
    }
    return $expanded
}

set pd_mode [string tolower $POWER_DOMAIN_RESHAPE_MODE]
set pd_targets [tt_pd_resolve_power_domains \
    $POWER_DOMAIN_RESHAPE_DOMAINS \
    $POWER_DOMAIN_RESHAPE_STRICT]

puts "INFO: POWER_DOMAIN_RESHAPE_MODE = $pd_mode"
puts "INFO: POWER_DOMAIN_RESHAPE_DOMAINS = $POWER_DOMAIN_RESHAPE_DOMAINS"
puts "INFO: Resolved power-domain targets = $pd_targets"

switch -- $pd_mode {
    none {
        puts "INFO: Base power-domain reshape is disabled."
    }
    bbox - legacy - bbox_snap {
        foreach pd_name $pd_targets {
            PD_merge $pd_name $POWER_DOMAIN_RESHAPE_STRICT
        }
    }
    snap {
        # Keep the existing geometry; snapping is performed below.
    }
    core_offset - core_offset_snap {
        foreach pd_name $pd_targets {
            lassign [tt_pd_flow_get_target_config \
                $POWER_DOMAIN_CORE_OFFSET_CONFIG $pd_name] found offset_cfg
            if {!$found} {
                set msg "No POWER_DOMAIN_CORE_OFFSET_CONFIG entry for '$pd_name', 'selected', or 'default'."
                if {$POWER_DOMAIN_RESHAPE_STRICT} { error $msg }
                puts "WARNING: $msg"
                continue
            }

            foreach key {top bottom left right} {
                if {![dict exists $offset_cfg $key]} {
                    error "POWER_DOMAIN_CORE_OFFSET_CONFIG/$pd_name is missing '$key'."
                }
            }

            PD_base \
                [dict get $offset_cfg top] \
                [dict get $offset_cfg bottom] \
                [dict get $offset_cfg left] \
                [dict get $offset_cfg right] \
                $pd_name \
                $POWER_DOMAIN_RESHAPE_STRICT
        }
    }
    default {
        error "Unsupported POWER_DOMAIN_RESHAPE_MODE '$POWER_DOMAIN_RESHAPE_MODE'. Use none, bbox, snap, bbox_snap, core_offset, core_offset_snap, or legacy."
    }
}

set scale_config [tt_pd_flow_expand_target_config \
    $POWER_DOMAIN_SCALE_CONFIG $POWER_DOMAIN_RESHAPE_STRICT]
set aspect_config [tt_pd_flow_expand_target_config \
    $POWER_DOMAIN_ASPECT_RATIO_CONFIG $POWER_DOMAIN_RESHAPE_STRICT]

# Optional independent width/height scaling.
foreach pd_name [dict keys $scale_config] {
    if {[dict exists $aspect_config $pd_name]} {
        error "Power domain '$pd_name' is present in both POWER_DOMAIN_SCALE_CONFIG and POWER_DOMAIN_ASPECT_RATIO_CONFIG after resolving GUI selection. Choose one resize method."
    }

    set resize_cfg [dict get $scale_config $pd_name]
    foreach key {width_scale height_scale} {
        if {![dict exists $resize_cfg $key]} {
            error "POWER_DOMAIN_SCALE_CONFIG/$pd_name is missing '$key'."
        }
    }
    set anchor center
    if {[dict exists $resize_cfg anchor]} {
        set anchor [dict get $resize_cfg anchor]
    }

    PD_reshape \
        [dict get $resize_cfg width_scale] \
        [dict get $resize_cfg height_scale] \
        $pd_name \
        $anchor \
        $POWER_DOMAIN_RESHAPE_STRICT
}

# Optional exact width/height-ratio adjustment.
foreach pd_name [dict keys $aspect_config] {
    set resize_cfg [dict get $aspect_config $pd_name]
    if {![dict exists $resize_cfg ratio]} {
        error "POWER_DOMAIN_ASPECT_RATIO_CONFIG/$pd_name is missing 'ratio'."
    }

    set preserve area
    set anchor center
    if {[dict exists $resize_cfg preserve]} {
        set preserve [dict get $resize_cfg preserve]
    }
    if {[dict exists $resize_cfg anchor]} {
        set anchor [dict get $resize_cfg anchor]
    }

    PD_ratio \
        [dict get $resize_cfg ratio] \
        $pd_name \
        $preserve \
        $anchor \
        $POWER_DOMAIN_RESHAPE_STRICT
}

if {$pd_mode eq "snap" ||
    $pd_mode eq "bbox_snap" ||
    $pd_mode eq "core_offset_snap"} {
    foreach pd_name $pd_targets {
        PD_snap $pd_name $POWER_DOMAIN_RESHAPE_STRICT
    }
}

if {$pd_mode ne "none" && $POWER_DOMAIN_CUT_OVERLAPS} {
    set cut_targets [tt_pd_resolve_power_domains \
        $POWER_DOMAIN_CUT_OVERLAP_DOMAINS \
        $POWER_DOMAIN_RESHAPE_STRICT]

    # First cut using the final reshaped/snapped power-domain geometry.
    foreach pd_name $cut_targets {
        PD_cut $pd_name $POWER_DOMAIN_RESHAPE_STRICT
    }

    # Re-cut once more after reshape to refresh the final PD overlap boundary.
    # This avoids stale/overlapping region geometry that can later make
    # boundary EndCaps fail check_place with Region/Fence violations.
    foreach pd_name $cut_targets {
        PD_cut $pd_name $POWER_DOMAIN_RESHAPE_STRICT
    }
}

puts "INFO: Power-domain reshape flow completed."
