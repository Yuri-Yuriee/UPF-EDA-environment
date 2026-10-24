# 05_route tool index

Existing Tcl commands and filenames are retained. Sources may execute stage actions; follow the existing checkpoint menu prerequisites. ioPADt internals and independent references are not automatically executed by this index.

| Tool | Function group | Existing commands | Location note |
|---|---|---|---|
| `TECH_SIGNAL_ANTENNA_BATCH_REPAIR_REFERENCE.tcl` (Runtime-only reference) | Stable stage entry / shared helper |  | Independent manual reference; never an automatic stage hook. |
| [TT_ANTENNA_REPAIR.tcl](antenna/TT_ANTENNA_REPAIR.tcl) | Antenna check / selected repair / final verification | `setting`, `token`, `directory`, `read_file`, `completion` | Physical implementation in subfolder; callers updated. |
| [TT_DRC_fix_jog_to_jog.tcl](drc/TT_DRC_fix_jog_to_jog.tcl) | DRC-specific repair / cleanup | `tt_j2j_get`, `tt_j2j_normalize_bbox`, `tt_j2j_norm_text`, `tt_j2j_marker_is_target`, `tt_j2j_marker_layer` | Physical implementation in subfolder; callers updated. |
| [TT_DRC_fix_metal_color.tcl](drc/TT_DRC_fix_metal_color.tcl) | DRC-specific repair / cleanup | `metal_color_version`, `metal_color_check`, `metal_color_plan`, `metal_color_repair`, `metal_color_verify` | Physical implementation in subfolder; callers updated. |
| [TT_DRC_fix_metal_same_mask.tcl](drc/TT_DRC_fix_metal_same_mask.tcl) | DRC-specific repair / cleanup |  | Physical implementation in subfolder; callers updated. |
| [TT_DRC_fix_via.tcl](drc/TT_DRC_fix_via.tcl) | DRC-specific repair / cleanup | `tt_via_drc_normalize_rect`, `tt_via_drc_rect_area`, `tt_via_drc_rect_intersection_area`, `tt_via_drc_cut_rects`, `tt_via_drc_total_cut_area` | Physical implementation in subfolder; callers updated. |
| [TT_DRC_fix_via8_after_m9.tcl](drc/TT_DRC_fix_via8_after_m9.tcl) | DRC-specific repair / cleanup | `tt_via8_normalize_rect`, `tt_via8_rect_area`, `tt_via8_rect_intersection_area`, `tt_via8_cut_rects`, `tt_via8_total_cut_area` | Physical implementation in subfolder; callers updated. |
| [TT_delete_VIA8_by_DRC.tcl](drc/TT_delete_VIA8_by_DRC.tcl) | DRC-specific repair / cleanup | `normalize_rect`, `rect_overlap`, `via_cut_rects`, `via_overlaps_marker`, `delete_via` | Physical implementation in subfolder; callers updated. |
| [TT_delete_signal_routes_only.tcl](manual_edit/TT_delete_signal_routes_only.tcl) | Explicit routing geometry edits | `TT_SIGROUTE__banner`, `TT_SIGROUTE__bool`, `TT_SIGROUTE__snapshot`, `TT_SIGROUTE__pg_name_set`, `TT_SIGROUTE__discover` | Physical implementation in subfolder; callers updated. |
| [TT_tool_remove_ring_overlap_metal.tcl](drc/TT_tool_remove_ring_overlap_metal.tcl) | Explicit routing geometry edits | `TT_tool_remove_ring_overlap_metal` | Physical implementation in subfolder; callers updated. |
| [TT_tool_report_metal_density.tcl](reports/TT_tool_report_metal_density.tcl) | Physical diagnostics | `TT_tool_report_metal_density` | Physical implementation in subfolder; callers updated. |
