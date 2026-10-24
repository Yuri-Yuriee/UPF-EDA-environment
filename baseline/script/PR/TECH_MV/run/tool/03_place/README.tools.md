# 03_place tool index

Existing Tcl commands and filenames are retained. Sources may execute stage actions; follow the existing checkpoint menu prerequisites. ioPADt internals and independent references are not automatically executed by this index.

| Tool | Function group | Existing commands | Location note |
|---|---|---|---|
| [TT_DRC_fix_inst_padding.tcl](drc/TT_DRC_fix_inst_padding.tcl) | DRC-specific repair / cleanup | `tt_padding_safe_get`, `tt_padding_safe_name`, `tt_padding_safe_is_eligible` | Physical implementation in subfolder; callers updated. |
| [TT_DRC_fix_post2nd_checkplace.tcl](drc/TT_DRC_fix_post2nd_checkplace.tcl) | DRC-specific repair / cleanup | `TT_CP2_rpt_dir`, `TT_CP2_db_dir`, `TT_CP2_repair_db_names`, `TT_CP2_get`, `TT_CP2_point` | Physical implementation in subfolder; callers updated. |
| [TT_proc_bypass_level_shifter.tcl](netlist/TT_proc_bypass_level_shifter.tcl) | Low-power netlist modification | `TT_LS3_report_path`, `TT_LS3_get_names`, `TT_LS3_get_inst`, `TT_LS3_pin_net_name`, `TT_LS3_signal_io` | Physical implementation in subfolder; callers updated. |
| [TT_clear_ls_iso_instance_padding.tcl](padding/TT_clear_ls_iso_instance_padding.tcl) | LS / ISO padding controls | `TT_CLEAR_LS_ISO_PAD__append_unique`, `TT_CLEAR_LS_ISO_PAD__collect`, `TT_clear_ls_iso_instance_padding` | Physical implementation in subfolder; callers updated. |
| [TT_proc_ls_iso_padding.tcl](padding/TT_proc_ls_iso_padding.tcl) | LS / ISO padding controls | `TT_ls_iso_pad__validate_sites`, `TT_ls_iso_pad__name`, `TT_ls_iso_pad__append_unique`, `TT_ls_iso_pad__query`, `TT_proc_apply_ls_iso_padding` | Physical implementation in subfolder; callers updated. |
| [TT_proc_ls_padding.tcl](padding/TT_proc_ls_padding.tcl) | LS / ISO padding controls | `TT_LS_PAD__validate_site_count`, `TT_LS_PAD__get_names`, `TT_apply_ls_padding` | Physical implementation in subfolder; callers updated. |

`drc/set_inst_padding.tcl` retains the legacy named-marker padding action; sourcing executes it immediately. It is non-public DRC code. The old shared-script entry remains compatible.
