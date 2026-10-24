# Runtime adapter preserves the historical logical source path.
if {[info exists ::TECH_MV_RUNTIME_ROOT]} {
    info script [file join $::TECH_MV_RUNTIME_ROOT run/tool/06_finish/export/TT_export_netlist.tcl]
}

delete_empty_hinsts

update_names -verilog
update_names -hport -map {{/ _}}
update_names -net -map {{/ _}}

write_netlist [file join $OUTPUT_DIR ${TOP_MODULE}_pr.v]

set DECAP_CELL_LIST   [get_db [get_db base_cells $::TECH_EXPORT_DECAP_MASTER_PATTERN] .name]
set POWERPAD_CELL_LIST    [get_db [get_db base_cells $::TECH_EXPORT_POWERPAD_MASTER_PATTERN] .name]
set FILLER_CELL_LIST  [get_db [get_db base_cells $::TECH_EXPORT_FILLER_MASTER_PATTERN] .name]
set PFILLER_CELL_LIST [get_db [get_db base_cells $::TECH_EXPORT_PFILLER_MASTER_PATTERN] .name]
set PCORNER_CELL_LIST [get_db [get_db base_cells $::TECH_EXPORT_PCORNER_MASTER_PATTERN] .name]

write_netlist \
    -include_pg_ports \
    -include_phys_cells "$DECAP_CELL_LIST $POWERPAD_CELL_LIST" \
    -exclude_insts_of_cells "$FILLER_CELL_LIST $PFILLER_CELL_LIST $PCORNER_CELL_LIST" \
    -exclude_leaf_cells \
    [file join $OUTPUT_DIR ${TOP_MODULE}_pg.v]
