# 00_common tool index

Existing Tcl commands and filenames are retained. Sources may execute stage actions; follow the existing checkpoint menu prerequisites. ioPADt internals and independent references are not automatically executed by this index.

| Tool | Function group | Existing commands | Location note |
|---|---|---|---|
| [TT_DRC_fix_same_mask_aggressive.tcl](drc/TT_DRC_fix_same_mask_aggressive.tcl) | Stable stage entry / shared helper | `tt_sma_get`, `tt_sma_true`, `tt_sma_normalize_bbox`, `tt_sma_report_path`, `tt_sma_obj_name` | Stable shared setup/output/menu bootstrap location. |
| [TT_checkpoint_tool_menu.tcl](TT_checkpoint_tool_menu.tcl) | Stable stage entry / shared helper | `tech_checkpoint_command_usage`, `tech_checkpoint_phase`, `tech_checkpoint_row_allowed`, `checkpoint_tools`, `tech_mv_checkpoint_tools` | Stable shared setup/output/menu bootstrap location. |
| [TT_import_geometry_info.tcl](TT_import_geometry_info.tcl) | Stable stage entry / shared helper | `::tech_mv_import_geometry_info` | Stable shared setup/output/menu bootstrap location. |
| [TT_pr6_verify_loaded_version.tcl](TT_pr6_verify_loaded_version.tcl) | Stable stage entry / shared helper |  | Stable shared setup/output/menu bootstrap location. |
| [TT_private_parameter_config.tcl](TT_private_parameter_config.tcl) | Stable stage entry / shared helper | `::tech_mv_live_geometry`, `::tech_mv_private_value`, `::tech_mv_setup_command` | Stable shared setup/output/menu bootstrap location. |
| [TT_runtime_output_helpers.tcl](TT_runtime_output_helpers.tcl) | Stable stage entry / shared helper | `tech_mv_output_path`, `FP_save`, `tech_mv_check_drc`, `tech_mv_native_sdp_report_path`, `tech_mv_native_report_command` | Stable shared setup/output/menu bootstrap location. |
