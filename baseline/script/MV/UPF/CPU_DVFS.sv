####################### Frontend RTL design stage ######################
#######################################
#           Virtual Power Setting
#######################################
#upf_version 2.0

############################################################
# Supply Sets
############################################################
create_supply_set CPU_source_power
create_supply_set CPU_source_power_080
create_supply_set CPU_source_power_075
create_supply_set CPU_source_power_055

create_supply_set CPU_prim_PG
create_supply_set CPU_retention
create_supply_set CPU_isolation


############################################################
# Power Domain Setting
############################################################
create_power_domain PD_CPU \
    -elements {u_TOP/u_cpu/u_cpu} \
    -exclude_elements {u_TOP/u_cpu/u_cpu/u_exe/u_CSR} \
    -supply {extra_supplies_0 CPU_prim_PG} \
    -supply {default_retention CPU_retention} \
    -supply {default_isolation CPU_isolation}

create_power_domain PD_CPU_ALWY_ON \
    -elements {u_TOP/u_cpu/u_cpu/u_exe/u_CSR}


############################################################
# Domain Supply Net
############################################################
set_domain_supply_net PD_CPU \
    -primary_power_net CPU_prim_PG.power \
    -primary_ground_net CPU_prim_PG.ground

set_domain_supply_net PD_CPU_ALWY_ON \
    -primary_power_net VDD_CPU \
    -primary_ground_net VSS


############################################################
# Shared Ground
############################################################
create_supply_set CPU_retention \
    -function {ground CPU_source_power.ground} \
    -update

create_supply_set CPU_isolation \
    -function {ground CPU_source_power.ground} \
    -update

create_supply_set CPU_prim_PG \
    -function {ground CPU_source_power.ground} \
    -update

create_supply_set CPU_source_power_080 \
    -function {ground CPU_source_power.ground} \
    -update

create_supply_set CPU_source_power_075 \
    -function {ground CPU_source_power.ground} \
    -update

create_supply_set CPU_source_power_055 \
    -function {ground CPU_source_power.ground} \
    -update

associate_supply_set {CPU_source_power CPU_source_power_080 CPU_source_power_075 CPU_source_power_055 CPU_retention CPU_isolation}


############################################################
# Virtual DVFS Power Switch Definition
#
# power_switch_en[3] : 1.0V
# power_switch_en[2] : 0.8V
# power_switch_en[1] : 0.75V
# power_switch_en[0] : 0.55V
# all 0              : OFF / 0V
############################################################
create_power_switch CPU_SW \
    -domain PD_CPU \
    -input_supply_port  {TVDD100 CPU_source_power.power} \
    -input_supply_port  {TVDD080 CPU_source_power_080.power} \
    -input_supply_port  {TVDD075 CPU_source_power_075.power} \
    -input_supply_port  {TVDD055 CPU_source_power_055.power} \
    -output_supply_port {VDD CPU_prim_PG.power} \
    -control_port {PSW100 u_TOP/u_cpu/u_WFI/power_switch_en[3]} \
    -control_port {PSW080 u_TOP/u_cpu/u_WFI/power_switch_en[2]} \
    -control_port {PSW075 u_TOP/u_cpu/u_WFI/power_switch_en[1]} \
    -control_port {PSW055 u_TOP/u_cpu/u_WFI/power_switch_en[0]} \
    -on_state  {ON_100 TVDD100 {PSW100 && !PSW080 && !PSW075 && !PSW055}} \
    -on_state  {ON_080 TVDD080 {!PSW100 && PSW080 && !PSW075 && !PSW055}} \
    -on_state  {ON_075 TVDD075 {!PSW100 && !PSW080 && PSW075 && !PSW055}} \
    -on_state  {ON_055 TVDD055 {!PSW100 && !PSW080 && !PSW075 && PSW055}} \
    -off_state {OFF_state {!PSW100 && !PSW080 && !PSW075 && !PSW055}}


####################### When synthesizing ######################

#######################################
#           Update Virtual Power
#######################################
create_supply_set CPU_source_power \
    -function {power VDD_CPU} \
    -function {ground VSS} \
    -update

create_supply_set CPU_source_power_080 \
    -function {power VDD_CPU_080} \
    -function {ground VSS} \
    -update

create_supply_set CPU_source_power_075 \
    -function {power VDD_CPU_075} \
    -function {ground VSS} \
    -update

create_supply_set CPU_source_power_055 \
    -function {power VDD_CPU_055} \
    -function {ground VSS} \
    -update

create_supply_set CPU_retention \
    -function {power VDD_CPU} \
    -update

create_supply_set CPU_isolation \
    -function {power VDD_CPU} \
    -update


############################################################
# Source Supply Power State
############################################################
add_power_state CPU_source_power -supply \
    -state V100 { -supply_expr { power == `{FULL_ON, 0.95, 1.05}}} \
    -state GND  { -supply_expr { ground == `{FULL_ON, 0.0}}}

add_power_state CPU_source_power_080 -supply \
    -state V080 { -supply_expr { power == `{FULL_ON, 0.72, 0.88}}} \
    -state GND  { -supply_expr { ground == `{FULL_ON, 0.0}}}

add_power_state CPU_source_power_075 -supply \
    -state V075 { -supply_expr { power == `{FULL_ON, 0.70, 0.80}}} \
    -state GND  { -supply_expr { ground == `{FULL_ON, 0.0}}}

add_power_state CPU_source_power_055 -supply \
    -state V055 { -supply_expr { power == `{FULL_ON, 0.50, 0.60}}} \
    -state GND  { -supply_expr { ground == `{FULL_ON, 0.0}}}


############################################################
# Retention / Isolation Power State
############################################################
add_power_state CPU_retention -supply \
    -state V100 { -supply_expr { power == `{FULL_ON, 0.95, 1.05}}} \
    -state GND  { -supply_expr { ground == `{FULL_ON, 0.0}}}

add_power_state CPU_isolation -supply \
    -state V100 { -supply_expr { power == `{FULL_ON, 0.95, 1.05}}} \
    -state GND  { -supply_expr { ground == `{FULL_ON, 0.0}}}


############################################################
# CPU Primary PG Power State
############################################################
add_power_state CPU_prim_PG -supply \
    -state V100 { -supply_expr { power == `{FULL_ON, 0.95, 1.05}}} \
    -state V080 { -supply_expr { power == `{FULL_ON, 0.72, 0.88}}} \
    -state V075 { -supply_expr { power == `{FULL_ON, 0.70, 0.80}}} \
    -state V055 { -supply_expr { power == `{FULL_ON, 0.50, 0.60}}} \
    -state OFF  { -supply_expr { power == `{OFF}}} \
    -state GND  { -supply_expr { ground == `{FULL_ON, 0.0}}}


############################################################
# Power State Table
############################################################
create_pst CPU_PST -supplies { \
    CPU_source_power.power \
    CPU_source_power_080.power \
    CPU_source_power_075.power \
    CPU_source_power_055.power \
    CPU_prim_PG.power \
    CPU_source_power.ground \
}

add_pst_state CPU_DVFS_100 -pst CPU_PST \
    -state {V100 V080 V075 V055 V100 GND}

add_pst_state CPU_DVFS_080 -pst CPU_PST \
    -state {V100 V080 V075 V055 V080 GND}

add_pst_state CPU_DVFS_075 -pst CPU_PST \
    -state {V100 V080 V075 V055 V075 GND}

add_pst_state CPU_DVFS_055 -pst CPU_PST \
    -state {V100 V080 V075 V055 V055 GND}

add_pst_state CPU_OFF -pst CPU_PST \
    -state {V100 V080 V075 V055 OFF GND}


############################################################
# Isolation / Retention / Mapping
############################################################
if {$syn_sim_option == 0} {

set_isolation IS_CPU_1 -domain PD_CPU \
    -isolation_supply CPU_isolation \
    -clamp_value 1 \
    -applies_to outputs \
    -location self \
    -isolation_signal u_TOP/u_cpu/u_WFI/CPU_ISO \
    -isolation_sense high \
    -elements {u_TOP/u_cpu/u_cpu/CEB u_TOP/u_cpu/u_cpu/u_exe/u_CSR/stall_wfi}

set_isolation IS_CPU_0 -domain PD_CPU \
    -isolation_supply CPU_isolation \
    -clamp_value 0 \
    -applies_to outputs \
    -location self \
    -isolation_signal u_TOP/u_cpu/u_WFI/CPU_ISO \
    -isolation_sense high \
    -exclude_elements {u_TOP/u_cpu/u_cpu/u_exe/u_CSR/CSR_mip* u_TOP/u_cpu/u_cpu/interrupt u_TOP/u_cpu/u_cpu/CEB u_TOP/u_cpu/u_cpu/u_exe/u_CSR/clk u_TOP/u_cpu/u_cpu/CEB u_TOP/u_cpu/u_cpu/u_exe/u_CSR/stall_wfi}

set_retention RT_CPU -domain PD_CPU \
    -retention_supply CPU_retention \
    -applies_to any \
    -save_signal    {u_TOP/u_cpu/u_WFI/CPU_save_pulse high} \
    -restore_signal {u_TOP/u_cpu/u_WFI/CPU_restore_pulse high} \
    -elements {u_TOP/u_cpu/u_cpu/u_if/invalid u_TOP/u_cpu/u_cpu/u_if/power_on_valid* u_TOP/u_cpu/u_cpu/u_id/RF* u_TOP/u_cpu/u_cpu/u_id/F_RF*}

map_retention_cell RT_CPU -domain PD_CPU \
    -lib_cells { \
        FILL_IN_CELL_RETENTION_DFF_017 \
        FILL_IN_CELL_RETENTION_DFF_018 \
        FILL_IN_CELL_RETENTION_DFF_019 \
        FILL_IN_CELL_RETENTION_DFF_020 \
        FILL_IN_CELL_RETENTION_DFF_021 \
        FILL_IN_CELL_RETENTION_DFF_022 \
        FILL_IN_CELL_RETENTION_DFF_023 \
        FILL_IN_CELL_RETENTION_DFF_024 \
        FILL_IN_CELL_RETENTION_DFF_025 \
        FILL_IN_CELL_RETENTION_DFF_026 \
        FILL_IN_CELL_RETENTION_DFF_027 \
        FILL_IN_CELL_RETENTION_DFF_028 \
    }

map_power_switch CPU_SW \
    -domain PD_CPU \
    -lib_cells { \
        FILL_IN_CELL_POWER_SWITCH_029 \
        FILL_IN_CELL_POWER_SWITCH_030 \
        FILL_IN_CELL_POWER_SWITCH_031 \
        FILL_IN_CELL_POWER_SWITCH_032 \
        FILL_IN_CELL_POWER_SWITCH_033 \
        FILL_IN_CELL_POWER_SWITCH_034 \
        FILL_IN_CELL_POWER_SWITCH_035 \
        FILL_IN_CELL_POWER_SWITCH_036 \
        FILL_IN_CELL_POWER_SWITCH_037 \
        FILL_IN_CELL_POWER_SWITCH_038 \
        FILL_IN_CELL_POWER_SWITCH_039 \
        FILL_IN_CELL_POWER_SWITCH_040 \
    }
}

# Retention cells must be mapped, otherwise insertion will fail
# map_isolation_cell
# map_level_shifter_cell
# map_power_switch
# 找不到 CELL 可能是加到 TARGET 或 LINK 沒加好
# Power Switch 不會 implement 在 Design Compiler
# Both {} and `{} syntaxes are acceptable
# `{} is the standard syntax