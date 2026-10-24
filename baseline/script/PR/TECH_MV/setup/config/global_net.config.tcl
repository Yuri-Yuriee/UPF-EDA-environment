# >>> TECH_MV IOPAD GUI MANAGED GLOBAL NET PATCH BEGIN
# Auto-generated Global Net DB prerequisites bound to THIS source file.
# Idempotent by construction: every object creation is guarded.
# VDDPST*=POWER; VSSPST*/ESD*/POCCTRL*=GROUND.
# Re-sourcing global_net.tcl must not create the same net twice.
# ESD_D1: polarity=GROUND
set _tt_iopad_gn_net_1 [get_db nets ESD_D1]
if {[llength $_tt_iopad_gn_net_1] == 0} {
    create_net -name ESD_D1 -ground
    set _tt_iopad_gn_net_1 [get_db nets ESD_D1]
}
if {[llength $_tt_iopad_gn_net_1] != 1} {
    error "TECH_MV IOPAD Global Net patch expected exactly one net ESD_D1; found [llength $_tt_iopad_gn_net_1]"
}
set_db net:ESD_D1 .skip_routing true
unset -nocomplain _tt_iopad_gn_net_1

# ESD_D2: polarity=GROUND
set _tt_iopad_gn_net_2 [get_db nets ESD_D2]
if {[llength $_tt_iopad_gn_net_2] == 0} {
    create_net -name ESD_D2 -ground
    set _tt_iopad_gn_net_2 [get_db nets ESD_D2]
}
if {[llength $_tt_iopad_gn_net_2] != 1} {
    error "TECH_MV IOPAD Global Net patch expected exactly one net ESD_D2; found [llength $_tt_iopad_gn_net_2]"
}
set_db net:ESD_D2 .skip_routing true
unset -nocomplain _tt_iopad_gn_net_2

# ESD_D3: polarity=GROUND
set _tt_iopad_gn_net_3 [get_db nets ESD_D3]
if {[llength $_tt_iopad_gn_net_3] == 0} {
    create_net -name ESD_D3 -ground
    set _tt_iopad_gn_net_3 [get_db nets ESD_D3]
}
if {[llength $_tt_iopad_gn_net_3] != 1} {
    error "TECH_MV IOPAD Global Net patch expected exactly one net ESD_D3; found [llength $_tt_iopad_gn_net_3]"
}
set_db net:ESD_D3 .skip_routing true
unset -nocomplain _tt_iopad_gn_net_3

# ESD_D4: polarity=GROUND
set _tt_iopad_gn_net_4 [get_db nets ESD_D4]
if {[llength $_tt_iopad_gn_net_4] == 0} {
    create_net -name ESD_D4 -ground
    set _tt_iopad_gn_net_4 [get_db nets ESD_D4]
}
if {[llength $_tt_iopad_gn_net_4] != 1} {
    error "TECH_MV IOPAD Global Net patch expected exactly one net ESD_D4; found [llength $_tt_iopad_gn_net_4]"
}
set_db net:ESD_D4 .skip_routing true
unset -nocomplain _tt_iopad_gn_net_4

# ESD_D5: polarity=GROUND
set _tt_iopad_gn_net_5 [get_db nets ESD_D5]
if {[llength $_tt_iopad_gn_net_5] == 0} {
    create_net -name ESD_D5 -ground
    set _tt_iopad_gn_net_5 [get_db nets ESD_D5]
}
if {[llength $_tt_iopad_gn_net_5] != 1} {
    error "TECH_MV IOPAD Global Net patch expected exactly one net ESD_D5; found [llength $_tt_iopad_gn_net_5]"
}
set_db net:ESD_D5 .skip_routing true
unset -nocomplain _tt_iopad_gn_net_5

# ESD_D6: polarity=GROUND
set _tt_iopad_gn_net_6 [get_db nets ESD_D6]
if {[llength $_tt_iopad_gn_net_6] == 0} {
    create_net -name ESD_D6 -ground
    set _tt_iopad_gn_net_6 [get_db nets ESD_D6]
}
if {[llength $_tt_iopad_gn_net_6] != 1} {
    error "TECH_MV IOPAD Global Net patch expected exactly one net ESD_D6; found [llength $_tt_iopad_gn_net_6]"
}
set_db net:ESD_D6 .skip_routing true
unset -nocomplain _tt_iopad_gn_net_6

# ESD_D7: polarity=GROUND
set _tt_iopad_gn_net_7 [get_db nets ESD_D7]
if {[llength $_tt_iopad_gn_net_7] == 0} {
    create_net -name ESD_D7 -ground
    set _tt_iopad_gn_net_7 [get_db nets ESD_D7]
}
if {[llength $_tt_iopad_gn_net_7] != 1} {
    error "TECH_MV IOPAD Global Net patch expected exactly one net ESD_D7; found [llength $_tt_iopad_gn_net_7]"
}
set_db net:ESD_D7 .skip_routing true
unset -nocomplain _tt_iopad_gn_net_7

# ESD_D8: polarity=GROUND
set _tt_iopad_gn_net_8 [get_db nets ESD_D8]
if {[llength $_tt_iopad_gn_net_8] == 0} {
    create_net -name ESD_D8 -ground
    set _tt_iopad_gn_net_8 [get_db nets ESD_D8]
}
if {[llength $_tt_iopad_gn_net_8] != 1} {
    error "TECH_MV IOPAD Global Net patch expected exactly one net ESD_D8; found [llength $_tt_iopad_gn_net_8]"
}
set_db net:ESD_D8 .skip_routing true
unset -nocomplain _tt_iopad_gn_net_8

# POCCTRL_D1: polarity=GROUND
set _tt_iopad_gn_net_9 [get_db nets POCCTRL_D1]
if {[llength $_tt_iopad_gn_net_9] == 0} {
    create_net -name POCCTRL_D1 -ground
    set _tt_iopad_gn_net_9 [get_db nets POCCTRL_D1]
}
if {[llength $_tt_iopad_gn_net_9] != 1} {
    error "TECH_MV IOPAD Global Net patch expected exactly one net POCCTRL_D1; found [llength $_tt_iopad_gn_net_9]"
}
set_db net:POCCTRL_D1 .skip_routing true
unset -nocomplain _tt_iopad_gn_net_9

# POCCTRL_D2: polarity=GROUND
set _tt_iopad_gn_net_10 [get_db nets POCCTRL_D2]
if {[llength $_tt_iopad_gn_net_10] == 0} {
    create_net -name POCCTRL_D2 -ground
    set _tt_iopad_gn_net_10 [get_db nets POCCTRL_D2]
}
if {[llength $_tt_iopad_gn_net_10] != 1} {
    error "TECH_MV IOPAD Global Net patch expected exactly one net POCCTRL_D2; found [llength $_tt_iopad_gn_net_10]"
}
set_db net:POCCTRL_D2 .skip_routing true
unset -nocomplain _tt_iopad_gn_net_10

# POCCTRL_D3: polarity=GROUND
set _tt_iopad_gn_net_11 [get_db nets POCCTRL_D3]
if {[llength $_tt_iopad_gn_net_11] == 0} {
    create_net -name POCCTRL_D3 -ground
    set _tt_iopad_gn_net_11 [get_db nets POCCTRL_D3]
}
if {[llength $_tt_iopad_gn_net_11] != 1} {
    error "TECH_MV IOPAD Global Net patch expected exactly one net POCCTRL_D3; found [llength $_tt_iopad_gn_net_11]"
}
set_db net:POCCTRL_D3 .skip_routing true
unset -nocomplain _tt_iopad_gn_net_11

# POCCTRL_D4: polarity=GROUND
set _tt_iopad_gn_net_12 [get_db nets POCCTRL_D4]
if {[llength $_tt_iopad_gn_net_12] == 0} {
    create_net -name POCCTRL_D4 -ground
    set _tt_iopad_gn_net_12 [get_db nets POCCTRL_D4]
}
if {[llength $_tt_iopad_gn_net_12] != 1} {
    error "TECH_MV IOPAD Global Net patch expected exactly one net POCCTRL_D4; found [llength $_tt_iopad_gn_net_12]"
}
set_db net:POCCTRL_D4 .skip_routing true
unset -nocomplain _tt_iopad_gn_net_12

# POCCTRL_D5: polarity=GROUND
set _tt_iopad_gn_net_13 [get_db nets POCCTRL_D5]
if {[llength $_tt_iopad_gn_net_13] == 0} {
    create_net -name POCCTRL_D5 -ground
    set _tt_iopad_gn_net_13 [get_db nets POCCTRL_D5]
}
if {[llength $_tt_iopad_gn_net_13] != 1} {
    error "TECH_MV IOPAD Global Net patch expected exactly one net POCCTRL_D5; found [llength $_tt_iopad_gn_net_13]"
}
set_db net:POCCTRL_D5 .skip_routing true
unset -nocomplain _tt_iopad_gn_net_13

# POCCTRL_D6: polarity=GROUND
set _tt_iopad_gn_net_14 [get_db nets POCCTRL_D6]
if {[llength $_tt_iopad_gn_net_14] == 0} {
    create_net -name POCCTRL_D6 -ground
    set _tt_iopad_gn_net_14 [get_db nets POCCTRL_D6]
}
if {[llength $_tt_iopad_gn_net_14] != 1} {
    error "TECH_MV IOPAD Global Net patch expected exactly one net POCCTRL_D6; found [llength $_tt_iopad_gn_net_14]"
}
set_db net:POCCTRL_D6 .skip_routing true
unset -nocomplain _tt_iopad_gn_net_14

# POCCTRL_D7: polarity=GROUND
set _tt_iopad_gn_net_15 [get_db nets POCCTRL_D7]
if {[llength $_tt_iopad_gn_net_15] == 0} {
    create_net -name POCCTRL_D7 -ground
    set _tt_iopad_gn_net_15 [get_db nets POCCTRL_D7]
}
if {[llength $_tt_iopad_gn_net_15] != 1} {
    error "TECH_MV IOPAD Global Net patch expected exactly one net POCCTRL_D7; found [llength $_tt_iopad_gn_net_15]"
}
set_db net:POCCTRL_D7 .skip_routing true
unset -nocomplain _tt_iopad_gn_net_15

# POCCTRL_D8: polarity=GROUND
set _tt_iopad_gn_net_16 [get_db nets POCCTRL_D8]
if {[llength $_tt_iopad_gn_net_16] == 0} {
    create_net -name POCCTRL_D8 -ground
    set _tt_iopad_gn_net_16 [get_db nets POCCTRL_D8]
}
if {[llength $_tt_iopad_gn_net_16] != 1} {
    error "TECH_MV IOPAD Global Net patch expected exactly one net POCCTRL_D8; found [llength $_tt_iopad_gn_net_16]"
}
set_db net:POCCTRL_D8 .skip_routing true
unset -nocomplain _tt_iopad_gn_net_16

# VDDPST_D1: polarity=POWER
set _tt_iopad_gn_net_17 [get_db nets VDDPST_D1]
if {[llength $_tt_iopad_gn_net_17] == 0} {
    create_net -name VDDPST_D1 -power
    set _tt_iopad_gn_net_17 [get_db nets VDDPST_D1]
}
if {[llength $_tt_iopad_gn_net_17] != 1} {
    error "TECH_MV IOPAD Global Net patch expected exactly one net VDDPST_D1; found [llength $_tt_iopad_gn_net_17]"
}
set_db net:VDDPST_D1 .skip_routing true
unset -nocomplain _tt_iopad_gn_net_17

# VDDPST_D2: polarity=POWER
set _tt_iopad_gn_net_18 [get_db nets VDDPST_D2]
if {[llength $_tt_iopad_gn_net_18] == 0} {
    create_net -name VDDPST_D2 -power
    set _tt_iopad_gn_net_18 [get_db nets VDDPST_D2]
}
if {[llength $_tt_iopad_gn_net_18] != 1} {
    error "TECH_MV IOPAD Global Net patch expected exactly one net VDDPST_D2; found [llength $_tt_iopad_gn_net_18]"
}
set_db net:VDDPST_D2 .skip_routing true
unset -nocomplain _tt_iopad_gn_net_18

# VDDPST_D3: polarity=POWER
set _tt_iopad_gn_net_19 [get_db nets VDDPST_D3]
if {[llength $_tt_iopad_gn_net_19] == 0} {
    create_net -name VDDPST_D3 -power
    set _tt_iopad_gn_net_19 [get_db nets VDDPST_D3]
}
if {[llength $_tt_iopad_gn_net_19] != 1} {
    error "TECH_MV IOPAD Global Net patch expected exactly one net VDDPST_D3; found [llength $_tt_iopad_gn_net_19]"
}
set_db net:VDDPST_D3 .skip_routing true
unset -nocomplain _tt_iopad_gn_net_19

# VDDPST_D4: polarity=POWER
set _tt_iopad_gn_net_20 [get_db nets VDDPST_D4]
if {[llength $_tt_iopad_gn_net_20] == 0} {
    create_net -name VDDPST_D4 -power
    set _tt_iopad_gn_net_20 [get_db nets VDDPST_D4]
}
if {[llength $_tt_iopad_gn_net_20] != 1} {
    error "TECH_MV IOPAD Global Net patch expected exactly one net VDDPST_D4; found [llength $_tt_iopad_gn_net_20]"
}
set_db net:VDDPST_D4 .skip_routing true
unset -nocomplain _tt_iopad_gn_net_20

# VDDPST_D5: polarity=POWER
set _tt_iopad_gn_net_21 [get_db nets VDDPST_D5]
if {[llength $_tt_iopad_gn_net_21] == 0} {
    create_net -name VDDPST_D5 -power
    set _tt_iopad_gn_net_21 [get_db nets VDDPST_D5]
}
if {[llength $_tt_iopad_gn_net_21] != 1} {
    error "TECH_MV IOPAD Global Net patch expected exactly one net VDDPST_D5; found [llength $_tt_iopad_gn_net_21]"
}
set_db net:VDDPST_D5 .skip_routing true
unset -nocomplain _tt_iopad_gn_net_21

# VDDPST_D6: polarity=POWER
set _tt_iopad_gn_net_22 [get_db nets VDDPST_D6]
if {[llength $_tt_iopad_gn_net_22] == 0} {
    create_net -name VDDPST_D6 -power
    set _tt_iopad_gn_net_22 [get_db nets VDDPST_D6]
}
if {[llength $_tt_iopad_gn_net_22] != 1} {
    error "TECH_MV IOPAD Global Net patch expected exactly one net VDDPST_D6; found [llength $_tt_iopad_gn_net_22]"
}
set_db net:VDDPST_D6 .skip_routing true
unset -nocomplain _tt_iopad_gn_net_22

# VDDPST_D7: polarity=POWER
set _tt_iopad_gn_net_23 [get_db nets VDDPST_D7]
if {[llength $_tt_iopad_gn_net_23] == 0} {
    create_net -name VDDPST_D7 -power
    set _tt_iopad_gn_net_23 [get_db nets VDDPST_D7]
}
if {[llength $_tt_iopad_gn_net_23] != 1} {
    error "TECH_MV IOPAD Global Net patch expected exactly one net VDDPST_D7; found [llength $_tt_iopad_gn_net_23]"
}
set_db net:VDDPST_D7 .skip_routing true
unset -nocomplain _tt_iopad_gn_net_23

# VDDPST_D8: polarity=POWER
set _tt_iopad_gn_net_24 [get_db nets VDDPST_D8]
if {[llength $_tt_iopad_gn_net_24] == 0} {
    create_net -name VDDPST_D8 -power
    set _tt_iopad_gn_net_24 [get_db nets VDDPST_D8]
}
if {[llength $_tt_iopad_gn_net_24] != 1} {
    error "TECH_MV IOPAD Global Net patch expected exactly one net VDDPST_D8; found [llength $_tt_iopad_gn_net_24]"
}
set_db net:VDDPST_D8 .skip_routing true
unset -nocomplain _tt_iopad_gn_net_24

# VSSPST_D1: polarity=GROUND
set _tt_iopad_gn_net_25 [get_db nets VSSPST_D1]
if {[llength $_tt_iopad_gn_net_25] == 0} {
    create_net -name VSSPST_D1 -ground
    set _tt_iopad_gn_net_25 [get_db nets VSSPST_D1]
}
if {[llength $_tt_iopad_gn_net_25] != 1} {
    error "TECH_MV IOPAD Global Net patch expected exactly one net VSSPST_D1; found [llength $_tt_iopad_gn_net_25]"
}
set_db net:VSSPST_D1 .skip_routing true
unset -nocomplain _tt_iopad_gn_net_25

# VSSPST_D2: polarity=GROUND
set _tt_iopad_gn_net_26 [get_db nets VSSPST_D2]
if {[llength $_tt_iopad_gn_net_26] == 0} {
    create_net -name VSSPST_D2 -ground
    set _tt_iopad_gn_net_26 [get_db nets VSSPST_D2]
}
if {[llength $_tt_iopad_gn_net_26] != 1} {
    error "TECH_MV IOPAD Global Net patch expected exactly one net VSSPST_D2; found [llength $_tt_iopad_gn_net_26]"
}
set_db net:VSSPST_D2 .skip_routing true
unset -nocomplain _tt_iopad_gn_net_26

# VSSPST_D3: polarity=GROUND
set _tt_iopad_gn_net_27 [get_db nets VSSPST_D3]
if {[llength $_tt_iopad_gn_net_27] == 0} {
    create_net -name VSSPST_D3 -ground
    set _tt_iopad_gn_net_27 [get_db nets VSSPST_D3]
}
if {[llength $_tt_iopad_gn_net_27] != 1} {
    error "TECH_MV IOPAD Global Net patch expected exactly one net VSSPST_D3; found [llength $_tt_iopad_gn_net_27]"
}
set_db net:VSSPST_D3 .skip_routing true
unset -nocomplain _tt_iopad_gn_net_27

# VSSPST_D4: polarity=GROUND
set _tt_iopad_gn_net_28 [get_db nets VSSPST_D4]
if {[llength $_tt_iopad_gn_net_28] == 0} {
    create_net -name VSSPST_D4 -ground
    set _tt_iopad_gn_net_28 [get_db nets VSSPST_D4]
}
if {[llength $_tt_iopad_gn_net_28] != 1} {
    error "TECH_MV IOPAD Global Net patch expected exactly one net VSSPST_D4; found [llength $_tt_iopad_gn_net_28]"
}
set_db net:VSSPST_D4 .skip_routing true
unset -nocomplain _tt_iopad_gn_net_28

# VSSPST_D5: polarity=GROUND
set _tt_iopad_gn_net_29 [get_db nets VSSPST_D5]
if {[llength $_tt_iopad_gn_net_29] == 0} {
    create_net -name VSSPST_D5 -ground
    set _tt_iopad_gn_net_29 [get_db nets VSSPST_D5]
}
if {[llength $_tt_iopad_gn_net_29] != 1} {
    error "TECH_MV IOPAD Global Net patch expected exactly one net VSSPST_D5; found [llength $_tt_iopad_gn_net_29]"
}
set_db net:VSSPST_D5 .skip_routing true
unset -nocomplain _tt_iopad_gn_net_29

# VSSPST_D6: polarity=GROUND
set _tt_iopad_gn_net_30 [get_db nets VSSPST_D6]
if {[llength $_tt_iopad_gn_net_30] == 0} {
    create_net -name VSSPST_D6 -ground
    set _tt_iopad_gn_net_30 [get_db nets VSSPST_D6]
}
if {[llength $_tt_iopad_gn_net_30] != 1} {
    error "TECH_MV IOPAD Global Net patch expected exactly one net VSSPST_D6; found [llength $_tt_iopad_gn_net_30]"
}
set_db net:VSSPST_D6 .skip_routing true
unset -nocomplain _tt_iopad_gn_net_30

# VSSPST_D7: polarity=GROUND
set _tt_iopad_gn_net_31 [get_db nets VSSPST_D7]
if {[llength $_tt_iopad_gn_net_31] == 0} {
    create_net -name VSSPST_D7 -ground
    set _tt_iopad_gn_net_31 [get_db nets VSSPST_D7]
}
if {[llength $_tt_iopad_gn_net_31] != 1} {
    error "TECH_MV IOPAD Global Net patch expected exactly one net VSSPST_D7; found [llength $_tt_iopad_gn_net_31]"
}
set_db net:VSSPST_D7 .skip_routing true
unset -nocomplain _tt_iopad_gn_net_31

# VSSPST_D8: polarity=GROUND
set _tt_iopad_gn_net_32 [get_db nets VSSPST_D8]
if {[llength $_tt_iopad_gn_net_32] == 0} {
    create_net -name VSSPST_D8 -ground
    set _tt_iopad_gn_net_32 [get_db nets VSSPST_D8]
}
if {[llength $_tt_iopad_gn_net_32] != 1} {
    error "TECH_MV IOPAD Global Net patch expected exactly one net VSSPST_D8; found [llength $_tt_iopad_gn_net_32]"
}
set_db net:VSSPST_D8 .skip_routing true
unset -nocomplain _tt_iopad_gn_net_32

# <<< TECH_MV IOPAD GUI MANAGED GLOBAL NET PATCH END

eval_legacy "clearGlobalNets"
puts "User script [info script]"
###########################################
#       PD1
###########################################
connect_global_net VDD_LEVEL_01      -power_domain PD_core -type pg_pin -pin_base_name VDD -inst_base_name *
connect_global_net VSS          -power_domain PD_core -type pg_pin -pin_base_name VSS -inst_base_name *
connect_global_net VDD_LEVEL_01      -power_domain PD_core -type pg_pin -pin_base_name VPP -inst_base_name *
connect_global_net VSS          -power_domain PD_core -type pg_pin -pin_base_name VBB -inst_base_name *
connect_global_net VDDPST       -power_domain PD_core -type pg_pin -pin_base_name VDDPST -inst_base_name *
connect_global_net VDD_LEVEL_01      -power_domain PD_core -type tie_hi -inst_base_name *
connect_global_net VSS          -power_domain PD_core -type tie_lo -inst_base_name *


###########################################
#       PD2
###########################################
connect_global_net VDD_LEVEL_02     -power_domain PD_TOP -type pg_pin -pin_base_name VDD -inst_base_name *
connect_global_net VSS          -power_domain PD_TOP -type pg_pin -pin_base_name VSS -inst_base_name *
connect_global_net VDD_LEVEL_02     -power_domain PD_TOP -type pg_pin -pin_base_name VPP -inst_base_name *
connect_global_net VSS          -power_domain PD_TOP -type pg_pin -pin_base_name VBB -inst_base_name *
connect_global_net VDD_LEVEL_02     -power_domain PD_TOP -type tie_hi -inst_base_name *
connect_global_net VSS          -power_domain PD_TOP -type tie_lo -inst_base_name *

connect_global_net VDD_LEVEL_01      -power_domain PD_TOP -type pg_pin -pin_base_name VDDM -inst_base_name *SRAM* -override
connect_global_net VDD_LEVEL_01      -power_domain PD_TOP -type pg_pin -pin_base_name VDDM -inst_base_name *sram* -override



###########################################
#       PD3
###########################################
connect_global_net CPU_prim_PG.power    -power_domain PD_CPU -type pg_pin -pin_base_name VDD -inst_base_name *
connect_global_net VSS                  -power_domain PD_CPU -type pg_pin -pin_base_name VSS -inst_base_name *

connect_global_net VSS                  -power_domain PD_CPU -type pg_pin -pin_base_name VBB -inst_base_name *
connect_global_net CPU_prim_PG.power    -power_domain PD_CPU -type tie_hi -inst_base_name *
connect_global_net VSS                  -power_domain PD_CPU -type tie_lo -inst_base_name *
connect_global_net VDD_LEVEL_01              -power_domain PD_CPU -type pg_pin -pin_base_name TVDD   -inst_base_name PD_CPU_SW* -override
connect_global_net CPU_prim_PG.power    -power_domain PD_CPU -type pg_pin -pin_base_name VDD    -inst_base_name PD_CPU_SW* -override
connect_global_net VDD_LEVEL_01              -power_domain PD_CPU -type pg_pin -pin_base_name VPP -inst_base_name * -override

###########################################
#       PD3
###########################################
connect_global_net VDD_LEVEL_01         -power_domain PD_CPU_ALWY_ON -type pg_pin -pin_base_name VDD -inst_base_name *
connect_global_net VSS             -power_domain PD_CPU_ALWY_ON -type pg_pin -pin_base_name VSS -inst_base_name *
connect_global_net VDD_LEVEL_01         -power_domain PD_CPU_ALWY_ON -type pg_pin -pin_base_name VPP -inst_base_name *
connect_global_net VSS             -power_domain PD_CPU_ALWY_ON -type pg_pin -pin_base_name VBB -inst_base_name *
connect_global_net VDD_LEVEL_01         -power_domain PD_CPU_ALWY_ON -type tie_hi -inst_base_name *
connect_global_net VSS             -power_domain PD_CPU_ALWY_ON -type tie_lo -inst_base_name *


###########################################
#       PD4
###########################################
connect_global_net WDT_prim_PG.power    -power_domain PD_WDT -type pg_pin -pin_base_name VDD -inst_base_name *
connect_global_net VSS                  -power_domain PD_WDT -type pg_pin -pin_base_name VSS -inst_base_name *

connect_global_net VSS                  -power_domain PD_WDT -type pg_pin -pin_base_name VBB -inst_base_name *
connect_global_net WDT_prim_PG.power    -power_domain PD_WDT -type tie_hi -inst_base_name *
connect_global_net VSS                  -power_domain PD_WDT -type tie_lo -inst_base_name *
connect_global_net VDD_LEVEL_02             -power_domain PD_WDT -type pg_pin -pin_base_name TVDD -inst_base_name PD_WDT_SW* -override
connect_global_net WDT_prim_PG.power    -power_domain PD_WDT -type pg_pin -pin_base_name VDD  -inst_base_name PD_WDT_SW* -override
connect_global_net VDD_LEVEL_02             -power_domain PD_WDT -type pg_pin -pin_base_name VPP -inst_base_name * -override

###########################################
#       power port
###########################################
connect_global_net VDD_LEVEL_02     -type pg_pin   -pin_base_name VDD -inst_base_name *CORE_VDD_TOP_PG*  -override
connect_global_net VDD_LEVEL_01      -type pg_pin   -pin_base_name VDD -inst_base_name *CORE_VDD_core_PG*   -override

# connect_global_net VDD -type pg_pin -pin_base_name VDDPE -inst_base_name *
# connect_global_net VDD -type pg_pin -pin_base_name VDDCE -inst_base_name *
# connect_global_net VSSPST -type pg_pin -pin_base_name VSSPST -inst_base_name *
# connect_global_net VSS -type pg_pin -pin_base_name VSSE -inst_base_name *
# if {[llength [get_db nets ESD]] == 0} {
#     create_net -physical -ground -name ESD
# }
# if {[llength [get_db nets POCCTRL]] == 0} {
#     create_net -physical -ground -name POCCTRL
# }
# connect_global_net ESD -type pg_pin -pin_base_name ESD -inst_base_name *
# connect_global_net POCCTRL -type pg_pin -pin_base_name POCCTRL -inst_base_name *

# set_db net:ESD .skip_routing true
# set_db net:POCCTRL .skip_routing true

# =============================================================================
# EDIT BY TOOL
# =============================================================================
connect_global_net VDDPST_D2 -netlist_override -override -pin_base_name VDDPST -single_inst CORE_VDD_LEVEL_02_PG1 -type pg_pin
connect_global_net VDDPST_D2 -netlist_override -override -pin_base_name VDDPST -single_inst pad_RTE_VDD_LEVEL_02 -type pg_pin
connect_global_net VDDPST_D2 -netlist_override -override -pin_base_name VDDPST -single_inst AUTO_IO_POWER_D2 -type pg_pin
connect_global_net VDDPST_D3 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_DRAM_Q_13__ipad_DRAM_Q -type pg_pin
connect_global_net VDDPST_D3 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_DRAM_Q_14__ipad_DRAM_Q -type pg_pin
connect_global_net VDDPST_D3 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_DRAM_Q_15__ipad_DRAM_Q -type pg_pin
connect_global_net VDDPST_D3 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_DRAM_Q_16__ipad_DRAM_Q -type pg_pin
connect_global_net VDDPST_D3 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_DRAM_Q_17__ipad_DRAM_Q -type pg_pin
connect_global_net VDDPST_D3 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_DRAM_Q_18__ipad_DRAM_Q -type pg_pin
connect_global_net VDDPST_D3 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_DRAM_Q_19__ipad_DRAM_Q -type pg_pin
connect_global_net VDDPST_D3 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_DRAM_Q_20__ipad_DRAM_Q -type pg_pin
connect_global_net VDDPST_D3 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_DRAM_Q_21__ipad_DRAM_Q -type pg_pin
connect_global_net VDDPST_D3 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_DRAM_Q_22__ipad_DRAM_Q -type pg_pin
connect_global_net VDDPST_D3 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_DRAM_Q_23__ipad_DRAM_Q -type pg_pin
connect_global_net VDDPST_D3 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_DRAM_Q_24__ipad_DRAM_Q -type pg_pin
connect_global_net VDDPST_D3 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_DRAM_Q_25__ipad_DRAM_Q -type pg_pin
connect_global_net VDDPST_D3 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_DRAM_Q_26__ipad_DRAM_Q -type pg_pin
connect_global_net VDDPST_D3 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_DRAM_Q_27__ipad_DRAM_Q -type pg_pin
connect_global_net VDDPST_D3 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_DRAM_Q_28__ipad_DRAM_Q -type pg_pin
connect_global_net VDDPST_D3 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_ROM_OUT_31__ipad_ROM_out -type pg_pin
connect_global_net VDDPST_D3 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_ROM_OUT_30__ipad_ROM_out -type pg_pin
connect_global_net VDDPST_D3 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_ROM_OUT_29__ipad_ROM_out -type pg_pin
connect_global_net VDDPST_D3 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_ROM_OUT_28__ipad_ROM_out -type pg_pin
connect_global_net VDDPST_D3 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_ROM_OUT_27__ipad_ROM_out -type pg_pin
connect_global_net VDDPST_D3 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_ROM_OUT_26__ipad_ROM_out -type pg_pin
connect_global_net VDDPST_D3 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_ROM_OUT_25__ipad_ROM_out -type pg_pin
connect_global_net VDDPST_D3 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_ROM_OUT_24__ipad_ROM_out -type pg_pin
connect_global_net VDDPST_D3 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_ROM_OUT_23__ipad_ROM_out -type pg_pin
connect_global_net VDDPST_D3 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_ROM_OUT_22__ipad_ROM_out -type pg_pin
connect_global_net VDDPST_D3 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_ROM_OUT_21__ipad_ROM_out -type pg_pin
connect_global_net VDDPST_D3 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_ROM_OUT_20__ipad_ROM_out -type pg_pin
connect_global_net VDDPST_D3 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_ROM_OUT_19__ipad_ROM_out -type pg_pin
connect_global_net VDDPST_D3 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_ROM_OUT_18__ipad_ROM_out -type pg_pin
connect_global_net VDDPST_D3 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_ROM_OUT_17__ipad_ROM_out -type pg_pin
connect_global_net VDDPST_D3 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_ROM_OUT_16__ipad_ROM_out -type pg_pin
connect_global_net VDDPST_D3 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_ROM_OUT_15__ipad_ROM_out -type pg_pin
connect_global_net VDDPST_D3 -netlist_override -override -pin_base_name VDDPST -single_inst AUTO_IO_POWER_D3 -type pg_pin
connect_global_net VDDPST_D3 -netlist_override -override -pin_base_name VDDPST -single_inst pad_RTE -type pg_pin
connect_global_net VDDPST_D3 -netlist_override -override -pin_base_name VDDPST -single_inst AUTO_CORE_POWER_D3 -type pg_pin
connect_global_net VDDPST_D4 -netlist_override -override -pin_base_name VDDPST -single_inst CORE_VDD_LEVEL_02_PG2 -type pg_pin
connect_global_net VDDPST_D4 -netlist_override -override -pin_base_name VDDPST -single_inst AUTO_RTE_D4 -type pg_pin
connect_global_net VDDPST_D4 -netlist_override -override -pin_base_name VDDPST -single_inst AUTO_IO_POWER_D4 -type pg_pin
connect_global_net VDDPST_D5 -netlist_override -override -pin_base_name VDDPST -single_inst IO_PG2 -type pg_pin
connect_global_net VDDPST_D5 -netlist_override -override -pin_base_name VDDPST -single_inst AUTO_RTE_D5 -type pg_pin
connect_global_net VDDPST_D5 -netlist_override -override -pin_base_name VDDPST -single_inst CORE_VDD_LEVEL_01_PG2 -type pg_pin
connect_global_net VDDPST_D5 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_ROM_OUT_14__ipad_ROM_out -type pg_pin
connect_global_net VDDPST_D5 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_ROM_OUT_13__ipad_ROM_out -type pg_pin
connect_global_net VDDPST_D5 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_ROM_OUT_12__ipad_ROM_out -type pg_pin
connect_global_net VDDPST_D5 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_ROM_OUT_11__ipad_ROM_out -type pg_pin
connect_global_net VDDPST_D5 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_ROM_OUT_10__ipad_ROM_out -type pg_pin
connect_global_net VDDPST_D5 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_ROM_OUT_9__ipad_ROM_out -type pg_pin
connect_global_net VDDPST_D5 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_ROM_OUT_8__ipad_ROM_out -type pg_pin
connect_global_net VDDPST_D5 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_ROM_OUT_7__ipad_ROM_out -type pg_pin
connect_global_net VDDPST_D5 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_ROM_OUT_6__ipad_ROM_out -type pg_pin
connect_global_net VDDPST_D5 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_ROM_OUT_5__ipad_ROM_out -type pg_pin
connect_global_net VDDPST_D5 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_ROM_OUT_4__ipad_ROM_out -type pg_pin
connect_global_net VDDPST_D5 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_ROM_OUT_3__ipad_ROM_out -type pg_pin
connect_global_net VDDPST_D5 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_ROM_OUT_2__ipad_ROM_out -type pg_pin
connect_global_net VDDPST_D5 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_ROM_OUT_1__ipad_ROM_out -type pg_pin
connect_global_net VDDPST_D5 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_ROM_OUT_0__ipad_ROM_out -type pg_pin
connect_global_net VDDPST_D5 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_DRAM_Q_31__ipad_DRAM_Q -type pg_pin
connect_global_net VDDPST_D5 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_DRAM_Q_30__ipad_DRAM_Q -type pg_pin
connect_global_net VDDPST_D5 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_DRAM_Q_29__ipad_DRAM_Q -type pg_pin
connect_global_net VDDPST_D5 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_DRAM_A_2__opad_DRAM_A -type pg_pin
connect_global_net VDDPST_D5 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_DRAM_A_1__opad_DRAM_A -type pg_pin
connect_global_net VDDPST_D5 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_DRAM_A_0__opad_DRAM_A -type pg_pin
connect_global_net VDDPST_D5 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_DRAM_D_31__opad_DRAM_D -type pg_pin
connect_global_net VDDPST_D5 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_DRAM_D_30__opad_DRAM_D -type pg_pin
connect_global_net VDDPST_D5 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_DRAM_D_29__opad_DRAM_D -type pg_pin
connect_global_net VDDPST_D5 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_DRAM_D_28__opad_DRAM_D -type pg_pin
connect_global_net VDDPST_D5 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_DRAM_D_27__opad_DRAM_D -type pg_pin
connect_global_net VDDPST_D5 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_DRAM_D_26__opad_DRAM_D -type pg_pin
connect_global_net VDDPST_D5 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_DRAM_D_25__opad_DRAM_D -type pg_pin
connect_global_net VDDPST_D5 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_DRAM_D_24__opad_DRAM_D -type pg_pin
connect_global_net VDDPST_D5 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_DRAM_D_23__opad_DRAM_D -type pg_pin
connect_global_net VDDPST_D5 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_DRAM_D_22__opad_DRAM_D -type pg_pin
connect_global_net VDDPST_D5 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_DRAM_D_21__opad_DRAM_D -type pg_pin
connect_global_net VDDPST_D5 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_DRAM_D_20__opad_DRAM_D -type pg_pin
connect_global_net VDDPST_D5 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_DRAM_D_19__opad_DRAM_D -type pg_pin
connect_global_net VDDPST_D5 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_DRAM_D_18__opad_DRAM_D -type pg_pin
connect_global_net VDDPST_D6 -netlist_override -override -pin_base_name VDDPST -single_inst CORE_VDD_LEVEL_02_PG3 -type pg_pin
connect_global_net VDDPST_D6 -netlist_override -override -pin_base_name VDDPST -single_inst AUTO_RTE_D6 -type pg_pin
connect_global_net VDDPST_D6 -netlist_override -override -pin_base_name VDDPST -single_inst AUTO_IO_POWER_D6 -type pg_pin
connect_global_net VDDPST_D7 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_DRAM_D_17__opad_DRAM_D -type pg_pin
connect_global_net VDDPST_D7 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_DRAM_D_16__opad_DRAM_D -type pg_pin
connect_global_net VDDPST_D7 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_DRAM_D_15__opad_DRAM_D -type pg_pin
connect_global_net VDDPST_D7 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_DRAM_D_14__opad_DRAM_D -type pg_pin
connect_global_net VDDPST_D7 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_DRAM_D_13__opad_DRAM_D -type pg_pin
connect_global_net VDDPST_D7 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_DRAM_D_12__opad_DRAM_D -type pg_pin
connect_global_net VDDPST_D7 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_DRAM_D_11__opad_DRAM_D -type pg_pin
connect_global_net VDDPST_D7 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_DRAM_D_10__opad_DRAM_D -type pg_pin
connect_global_net VDDPST_D7 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_DRAM_D_9__opad_DRAM_D -type pg_pin
connect_global_net VDDPST_D7 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_DRAM_D_8__opad_DRAM_D -type pg_pin
connect_global_net VDDPST_D7 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_DRAM_D_7__opad_DRAM_D -type pg_pin
connect_global_net VDDPST_D7 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_DRAM_D_6__opad_DRAM_D -type pg_pin
connect_global_net VDDPST_D7 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_DRAM_D_5__opad_DRAM_D -type pg_pin
connect_global_net VDDPST_D7 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_DRAM_D_4__opad_DRAM_D -type pg_pin
connect_global_net VDDPST_D7 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_DRAM_D_3__opad_DRAM_D -type pg_pin
connect_global_net VDDPST_D7 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_DRAM_D_2__opad_DRAM_D -type pg_pin
connect_global_net VDDPST_D7 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_DRAM_D_1__opad_DRAM_D -type pg_pin
connect_global_net VDDPST_D7 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_DRAM_D_0__opad_DRAM_D -type pg_pin
connect_global_net VDDPST_D7 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_DRAM_A_3__opad_DRAM_A -type pg_pin
connect_global_net VDDPST_D7 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_DRAM_A_4__opad_DRAM_A -type pg_pin
connect_global_net VDDPST_D7 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_DRAM_A_5__opad_DRAM_A -type pg_pin
connect_global_net VDDPST_D7 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_DRAM_A_6__opad_DRAM_A -type pg_pin
connect_global_net VDDPST_D7 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_DRAM_A_7__opad_DRAM_A -type pg_pin
connect_global_net VDDPST_D7 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_DRAM_A_8__opad_DRAM_A -type pg_pin
connect_global_net VDDPST_D7 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_DRAM_A_9__opad_DRAM_A -type pg_pin
connect_global_net VDDPST_D7 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_DRAM_A_10__opad_DRAM_A -type pg_pin
connect_global_net VDDPST_D7 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_ROM_ADDR_0__opad_ROM_address -type pg_pin
connect_global_net VDDPST_D7 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_ROM_ADDR_1__opad_ROM_address -type pg_pin
connect_global_net VDDPST_D7 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_ROM_ADDR_2__opad_ROM_address -type pg_pin
connect_global_net VDDPST_D7 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_ROM_ADDR_3__opad_ROM_address -type pg_pin
connect_global_net VDDPST_D7 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_ROM_ADDR_4__opad_ROM_address -type pg_pin
connect_global_net VDDPST_D7 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_ROM_ADDR_5__opad_ROM_address -type pg_pin
connect_global_net VDDPST_D7 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_ROM_ADDR_6__opad_ROM_address -type pg_pin
connect_global_net VDDPST_D7 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_ROM_ADDR_7__opad_ROM_address -type pg_pin
connect_global_net VDDPST_D7 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_ROM_ADDR_8__opad_ROM_address -type pg_pin
connect_global_net VDDPST_D7 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_ROM_ADDR_9__opad_ROM_address -type pg_pin
connect_global_net VDDPST_D7 -netlist_override -override -pin_base_name VDDPST -single_inst CORE_VDD_LEVEL_01_PG4 -type pg_pin
connect_global_net VDDPST_D7 -netlist_override -override -pin_base_name VDDPST -single_inst AUTO_RTE_D7 -type pg_pin
connect_global_net VDDPST_D7 -netlist_override -override -pin_base_name VDDPST -single_inst IO_PG4 -type pg_pin
connect_global_net VDDPST_D8 -netlist_override -override -pin_base_name VDDPST -single_inst CORE_VDD_LEVEL_02_PG4 -type pg_pin
connect_global_net VDDPST_D8 -netlist_override -override -pin_base_name VDDPST -single_inst AUTO_RTE_D8 -type pg_pin
connect_global_net VDDPST_D8 -netlist_override -override -pin_base_name VDDPST -single_inst AUTO_IO_POWER_D8 -type pg_pin
connect_global_net VSSPST_D1 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_v_ctrl_idx_0__opad_v_ctrl_idx -type pg_pin
connect_global_net VSSPST_D1 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_v_ctrl_idx_1__opad_v_ctrl_idx -type pg_pin
connect_global_net VSSPST_D1 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_v_ctrl_0__opad_v_ctrl -type pg_pin
connect_global_net VSSPST_D1 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_v_ctrl_1__opad_v_ctrl -type pg_pin
connect_global_net VSSPST_D1 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_DRAM_Q_0__ipad_DRAM_Q -type pg_pin
connect_global_net VSSPST_D1 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_DRAM_Q_1__ipad_DRAM_Q -type pg_pin
connect_global_net VSSPST_D1 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_DRAM_Q_2__ipad_DRAM_Q -type pg_pin
connect_global_net VSSPST_D1 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_DRAM_Q_3__ipad_DRAM_Q -type pg_pin
connect_global_net VSSPST_D1 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_DRAM_Q_4__ipad_DRAM_Q -type pg_pin
connect_global_net VSSPST_D1 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_DRAM_Q_5__ipad_DRAM_Q -type pg_pin
connect_global_net VSSPST_D1 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_DRAM_Q_6__ipad_DRAM_Q -type pg_pin
connect_global_net VSSPST_D1 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_DRAM_Q_7__ipad_DRAM_Q -type pg_pin
connect_global_net VSSPST_D1 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_DRAM_Q_8__ipad_DRAM_Q -type pg_pin
connect_global_net VSSPST_D1 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_DRAM_Q_9__ipad_DRAM_Q -type pg_pin
connect_global_net VSSPST_D1 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_DRAM_Q_10__ipad_DRAM_Q -type pg_pin
connect_global_net VSSPST_D1 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_DRAM_Q_11__ipad_DRAM_Q -type pg_pin
connect_global_net VSSPST_D1 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_DRAM_Q_12__ipad_DRAM_Q -type pg_pin
connect_global_net VSSPST_D1 -netlist_override -override -pin_base_name VSSPST -single_inst CORE_VDD_LEVEL_01_PG1 -type pg_pin
connect_global_net VSSPST_D1 -netlist_override -override -pin_base_name VSSPST -single_inst AUTO_RTE_D1 -type pg_pin
connect_global_net VSSPST_D1 -netlist_override -override -pin_base_name VSSPST -single_inst IO_PG1 -type pg_pin
connect_global_net VSSPST_D1 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_ROM_ADDR_10__opad_ROM_address -type pg_pin
connect_global_net VSSPST_D1 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_ROM_ADDR_11__opad_ROM_address -type pg_pin
connect_global_net VSSPST_D1 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_DRAM_WEN_0__opad_DRAM_WEn -type pg_pin
connect_global_net VSSPST_D1 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_DRAM_WEN_1__opad_DRAM_WEn -type pg_pin
connect_global_net VSSPST_D1 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_DRAM_WEN_2__opad_DRAM_WEn -type pg_pin
connect_global_net VSSPST_D1 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_DRAM_WEN_3__opad_DRAM_WEn -type pg_pin
connect_global_net VSSPST_D1 -netlist_override -override -pin_base_name VSSPST -single_inst opad_ROM_read -type pg_pin
connect_global_net VSSPST_D1 -netlist_override -override -pin_base_name VSSPST -single_inst opad_ROM_enable -type pg_pin
connect_global_net VSSPST_D1 -netlist_override -override -pin_base_name VSSPST -single_inst opad_DRAM_CSn -type pg_pin
connect_global_net VSSPST_D1 -netlist_override -override -pin_base_name VSSPST -single_inst opad_DRAM_RASn -type pg_pin
connect_global_net VSSPST_D1 -netlist_override -override -pin_base_name VSSPST -single_inst opad_DRAM_CASn -type pg_pin
connect_global_net VSSPST_D1 -netlist_override -override -pin_base_name VSSPST -single_inst ipad_DRAM_valid -type pg_pin
connect_global_net VSSPST_D1 -netlist_override -override -pin_base_name VSSPST -single_inst ipad_cpu_clk -type pg_pin
connect_global_net VSSPST_D1 -netlist_override -override -pin_base_name VSSPST -single_inst ipad_axi_clk -type pg_pin
connect_global_net VSSPST_D1 -netlist_override -override -pin_base_name VSSPST -single_inst ipad_rom_clk -type pg_pin
connect_global_net VSSPST_D1 -netlist_override -override -pin_base_name VSSPST -single_inst ipad_dram_clk -type pg_pin
connect_global_net VSSPST_D1 -netlist_override -override -pin_base_name VSSPST -single_inst ipad_rom_rst -type pg_pin
connect_global_net VSSPST_D2 -netlist_override -override -pin_base_name VSSPST -single_inst CORE_VDD_LEVEL_02_PG1 -type pg_pin
connect_global_net VSSPST_D2 -netlist_override -override -pin_base_name VSSPST -single_inst pad_RTE_VDD_LEVEL_02 -type pg_pin
connect_global_net VSSPST_D2 -netlist_override -override -pin_base_name VSSPST -single_inst AUTO_IO_POWER_D2 -type pg_pin
connect_global_net VSSPST_D3 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_DRAM_Q_13__ipad_DRAM_Q -type pg_pin
connect_global_net VSSPST_D3 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_DRAM_Q_14__ipad_DRAM_Q -type pg_pin
connect_global_net VSSPST_D3 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_DRAM_Q_15__ipad_DRAM_Q -type pg_pin
connect_global_net VSSPST_D3 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_DRAM_Q_16__ipad_DRAM_Q -type pg_pin
connect_global_net VSSPST_D3 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_DRAM_Q_17__ipad_DRAM_Q -type pg_pin
connect_global_net VSSPST_D3 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_DRAM_Q_18__ipad_DRAM_Q -type pg_pin
connect_global_net VSSPST_D3 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_DRAM_Q_19__ipad_DRAM_Q -type pg_pin
connect_global_net VSSPST_D3 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_DRAM_Q_20__ipad_DRAM_Q -type pg_pin
connect_global_net VSSPST_D3 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_DRAM_Q_21__ipad_DRAM_Q -type pg_pin
connect_global_net VSSPST_D3 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_DRAM_Q_22__ipad_DRAM_Q -type pg_pin
connect_global_net VSSPST_D3 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_DRAM_Q_23__ipad_DRAM_Q -type pg_pin
connect_global_net VSSPST_D3 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_DRAM_Q_24__ipad_DRAM_Q -type pg_pin
connect_global_net VSSPST_D3 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_DRAM_Q_25__ipad_DRAM_Q -type pg_pin
connect_global_net VSSPST_D3 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_DRAM_Q_26__ipad_DRAM_Q -type pg_pin
connect_global_net VSSPST_D3 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_DRAM_Q_27__ipad_DRAM_Q -type pg_pin
connect_global_net VSSPST_D3 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_DRAM_Q_28__ipad_DRAM_Q -type pg_pin
connect_global_net VSSPST_D3 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_ROM_OUT_31__ipad_ROM_out -type pg_pin
connect_global_net VSSPST_D3 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_ROM_OUT_30__ipad_ROM_out -type pg_pin
connect_global_net VSSPST_D3 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_ROM_OUT_29__ipad_ROM_out -type pg_pin
connect_global_net VSSPST_D3 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_ROM_OUT_28__ipad_ROM_out -type pg_pin
connect_global_net VSSPST_D3 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_ROM_OUT_27__ipad_ROM_out -type pg_pin
connect_global_net VSSPST_D3 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_ROM_OUT_26__ipad_ROM_out -type pg_pin
connect_global_net VSSPST_D3 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_ROM_OUT_25__ipad_ROM_out -type pg_pin
connect_global_net VSSPST_D3 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_ROM_OUT_24__ipad_ROM_out -type pg_pin
connect_global_net VSSPST_D3 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_ROM_OUT_23__ipad_ROM_out -type pg_pin
connect_global_net VSSPST_D3 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_ROM_OUT_22__ipad_ROM_out -type pg_pin
connect_global_net VSSPST_D3 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_ROM_OUT_21__ipad_ROM_out -type pg_pin
connect_global_net VSSPST_D3 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_ROM_OUT_20__ipad_ROM_out -type pg_pin
connect_global_net VSSPST_D3 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_ROM_OUT_19__ipad_ROM_out -type pg_pin
connect_global_net VSSPST_D3 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_ROM_OUT_18__ipad_ROM_out -type pg_pin
connect_global_net VSSPST_D3 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_ROM_OUT_17__ipad_ROM_out -type pg_pin
connect_global_net VSSPST_D3 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_ROM_OUT_16__ipad_ROM_out -type pg_pin
connect_global_net VSSPST_D3 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_ROM_OUT_15__ipad_ROM_out -type pg_pin
connect_global_net VSSPST_D3 -netlist_override -override -pin_base_name VSSPST -single_inst AUTO_IO_POWER_D3 -type pg_pin
connect_global_net VSSPST_D3 -netlist_override -override -pin_base_name VSSPST -single_inst pad_RTE -type pg_pin
connect_global_net VSSPST_D3 -netlist_override -override -pin_base_name VSSPST -single_inst AUTO_CORE_POWER_D3 -type pg_pin
connect_global_net VSSPST_D4 -netlist_override -override -pin_base_name VSSPST -single_inst CORE_VDD_LEVEL_02_PG2 -type pg_pin
connect_global_net VSSPST_D4 -netlist_override -override -pin_base_name VSSPST -single_inst AUTO_RTE_D4 -type pg_pin
connect_global_net VSSPST_D4 -netlist_override -override -pin_base_name VSSPST -single_inst AUTO_IO_POWER_D4 -type pg_pin
connect_global_net VSSPST_D5 -netlist_override -override -pin_base_name VSSPST -single_inst IO_PG2 -type pg_pin
connect_global_net VSSPST_D5 -netlist_override -override -pin_base_name VSSPST -single_inst AUTO_RTE_D5 -type pg_pin
connect_global_net VSSPST_D5 -netlist_override -override -pin_base_name VSSPST -single_inst CORE_VDD_LEVEL_01_PG2 -type pg_pin
connect_global_net VSSPST_D5 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_ROM_OUT_14__ipad_ROM_out -type pg_pin
connect_global_net VSSPST_D5 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_ROM_OUT_13__ipad_ROM_out -type pg_pin
connect_global_net VSSPST_D5 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_ROM_OUT_12__ipad_ROM_out -type pg_pin
connect_global_net VSSPST_D5 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_ROM_OUT_11__ipad_ROM_out -type pg_pin
connect_global_net VSSPST_D5 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_ROM_OUT_10__ipad_ROM_out -type pg_pin
connect_global_net VSSPST_D5 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_ROM_OUT_9__ipad_ROM_out -type pg_pin
connect_global_net VSSPST_D5 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_ROM_OUT_8__ipad_ROM_out -type pg_pin
connect_global_net VSSPST_D5 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_ROM_OUT_7__ipad_ROM_out -type pg_pin
connect_global_net VSSPST_D5 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_ROM_OUT_6__ipad_ROM_out -type pg_pin
connect_global_net VSSPST_D5 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_ROM_OUT_5__ipad_ROM_out -type pg_pin
connect_global_net VSSPST_D5 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_ROM_OUT_4__ipad_ROM_out -type pg_pin
connect_global_net VSSPST_D5 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_ROM_OUT_3__ipad_ROM_out -type pg_pin
connect_global_net VSSPST_D5 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_ROM_OUT_2__ipad_ROM_out -type pg_pin
connect_global_net VSSPST_D5 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_ROM_OUT_1__ipad_ROM_out -type pg_pin
connect_global_net VSSPST_D5 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_ROM_OUT_0__ipad_ROM_out -type pg_pin
connect_global_net VSSPST_D5 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_DRAM_Q_31__ipad_DRAM_Q -type pg_pin
connect_global_net VSSPST_D5 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_DRAM_Q_30__ipad_DRAM_Q -type pg_pin
connect_global_net VSSPST_D5 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_DRAM_Q_29__ipad_DRAM_Q -type pg_pin
connect_global_net VSSPST_D5 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_DRAM_A_2__opad_DRAM_A -type pg_pin
connect_global_net VSSPST_D5 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_DRAM_A_1__opad_DRAM_A -type pg_pin
connect_global_net VSSPST_D5 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_DRAM_A_0__opad_DRAM_A -type pg_pin
connect_global_net VSSPST_D5 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_DRAM_D_31__opad_DRAM_D -type pg_pin
connect_global_net VSSPST_D5 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_DRAM_D_30__opad_DRAM_D -type pg_pin
connect_global_net VSSPST_D5 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_DRAM_D_29__opad_DRAM_D -type pg_pin
connect_global_net VSSPST_D5 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_DRAM_D_28__opad_DRAM_D -type pg_pin
connect_global_net VSSPST_D5 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_DRAM_D_27__opad_DRAM_D -type pg_pin
connect_global_net VSSPST_D5 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_DRAM_D_26__opad_DRAM_D -type pg_pin
connect_global_net VSSPST_D5 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_DRAM_D_25__opad_DRAM_D -type pg_pin
connect_global_net VSSPST_D5 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_DRAM_D_24__opad_DRAM_D -type pg_pin
connect_global_net VSSPST_D5 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_DRAM_D_23__opad_DRAM_D -type pg_pin
connect_global_net VSSPST_D5 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_DRAM_D_22__opad_DRAM_D -type pg_pin
connect_global_net VSSPST_D5 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_DRAM_D_21__opad_DRAM_D -type pg_pin
connect_global_net VSSPST_D5 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_DRAM_D_20__opad_DRAM_D -type pg_pin
connect_global_net VSSPST_D5 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_DRAM_D_19__opad_DRAM_D -type pg_pin
connect_global_net VSSPST_D5 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_DRAM_D_18__opad_DRAM_D -type pg_pin
connect_global_net VSSPST_D6 -netlist_override -override -pin_base_name VSSPST -single_inst CORE_VDD_LEVEL_02_PG3 -type pg_pin
connect_global_net VSSPST_D6 -netlist_override -override -pin_base_name VSSPST -single_inst AUTO_RTE_D6 -type pg_pin
connect_global_net VSSPST_D6 -netlist_override -override -pin_base_name VSSPST -single_inst AUTO_IO_POWER_D6 -type pg_pin
connect_global_net VSSPST_D7 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_DRAM_D_17__opad_DRAM_D -type pg_pin
connect_global_net VSSPST_D7 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_DRAM_D_16__opad_DRAM_D -type pg_pin
connect_global_net VSSPST_D7 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_DRAM_D_15__opad_DRAM_D -type pg_pin
connect_global_net VSSPST_D7 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_DRAM_D_14__opad_DRAM_D -type pg_pin
connect_global_net VSSPST_D7 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_DRAM_D_13__opad_DRAM_D -type pg_pin
connect_global_net VSSPST_D7 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_DRAM_D_12__opad_DRAM_D -type pg_pin
connect_global_net VSSPST_D7 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_DRAM_D_11__opad_DRAM_D -type pg_pin
connect_global_net VSSPST_D7 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_DRAM_D_10__opad_DRAM_D -type pg_pin
connect_global_net VSSPST_D7 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_DRAM_D_9__opad_DRAM_D -type pg_pin
connect_global_net VSSPST_D7 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_DRAM_D_8__opad_DRAM_D -type pg_pin
connect_global_net VSSPST_D7 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_DRAM_D_7__opad_DRAM_D -type pg_pin
connect_global_net VSSPST_D7 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_DRAM_D_6__opad_DRAM_D -type pg_pin
connect_global_net VSSPST_D7 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_DRAM_D_5__opad_DRAM_D -type pg_pin
connect_global_net VSSPST_D7 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_DRAM_D_4__opad_DRAM_D -type pg_pin
connect_global_net VSSPST_D7 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_DRAM_D_3__opad_DRAM_D -type pg_pin
connect_global_net VSSPST_D7 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_DRAM_D_2__opad_DRAM_D -type pg_pin
connect_global_net VSSPST_D7 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_DRAM_D_1__opad_DRAM_D -type pg_pin
connect_global_net VSSPST_D7 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_DRAM_D_0__opad_DRAM_D -type pg_pin
connect_global_net VSSPST_D7 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_DRAM_A_3__opad_DRAM_A -type pg_pin
connect_global_net VSSPST_D7 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_DRAM_A_4__opad_DRAM_A -type pg_pin
connect_global_net VSSPST_D7 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_DRAM_A_5__opad_DRAM_A -type pg_pin
connect_global_net VSSPST_D7 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_DRAM_A_6__opad_DRAM_A -type pg_pin
connect_global_net VSSPST_D7 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_DRAM_A_7__opad_DRAM_A -type pg_pin
connect_global_net VSSPST_D7 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_DRAM_A_8__opad_DRAM_A -type pg_pin
connect_global_net VSSPST_D7 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_DRAM_A_9__opad_DRAM_A -type pg_pin
connect_global_net VSSPST_D7 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_DRAM_A_10__opad_DRAM_A -type pg_pin
connect_global_net VSSPST_D7 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_ROM_ADDR_0__opad_ROM_address -type pg_pin
connect_global_net VSSPST_D7 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_ROM_ADDR_1__opad_ROM_address -type pg_pin
connect_global_net VSSPST_D7 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_ROM_ADDR_2__opad_ROM_address -type pg_pin
connect_global_net VSSPST_D7 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_ROM_ADDR_3__opad_ROM_address -type pg_pin
connect_global_net VSSPST_D7 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_ROM_ADDR_4__opad_ROM_address -type pg_pin
connect_global_net VSSPST_D7 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_ROM_ADDR_5__opad_ROM_address -type pg_pin
connect_global_net VSSPST_D7 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_ROM_ADDR_6__opad_ROM_address -type pg_pin
connect_global_net VSSPST_D7 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_ROM_ADDR_7__opad_ROM_address -type pg_pin
connect_global_net VSSPST_D7 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_ROM_ADDR_8__opad_ROM_address -type pg_pin
connect_global_net VSSPST_D7 -netlist_override -override -pin_base_name VSSPST -single_inst GEN_ROM_ADDR_9__opad_ROM_address -type pg_pin
connect_global_net VSSPST_D7 -netlist_override -override -pin_base_name VSSPST -single_inst CORE_VDD_LEVEL_01_PG4 -type pg_pin
connect_global_net VSSPST_D7 -netlist_override -override -pin_base_name VSSPST -single_inst AUTO_RTE_D7 -type pg_pin
connect_global_net VSSPST_D7 -netlist_override -override -pin_base_name VSSPST -single_inst IO_PG4 -type pg_pin
connect_global_net VSSPST_D8 -netlist_override -override -pin_base_name VSSPST -single_inst CORE_VDD_LEVEL_02_PG4 -type pg_pin
connect_global_net VSSPST_D8 -netlist_override -override -pin_base_name VSSPST -single_inst AUTO_RTE_D8 -type pg_pin
connect_global_net VSSPST_D8 -netlist_override -override -pin_base_name VSSPST -single_inst AUTO_IO_POWER_D8 -type pg_pin
connect_global_net ESD_D1 -netlist_override -override -pin_base_name ESD -single_inst GEN_v_ctrl_idx_0__opad_v_ctrl_idx -type pg_pin
connect_global_net ESD_D1 -netlist_override -override -pin_base_name ESD -single_inst GEN_v_ctrl_idx_1__opad_v_ctrl_idx -type pg_pin
connect_global_net ESD_D1 -netlist_override -override -pin_base_name ESD -single_inst GEN_v_ctrl_0__opad_v_ctrl -type pg_pin
connect_global_net ESD_D1 -netlist_override -override -pin_base_name ESD -single_inst GEN_v_ctrl_1__opad_v_ctrl -type pg_pin
connect_global_net ESD_D1 -netlist_override -override -pin_base_name ESD -single_inst GEN_DRAM_Q_0__ipad_DRAM_Q -type pg_pin
connect_global_net ESD_D1 -netlist_override -override -pin_base_name ESD -single_inst GEN_DRAM_Q_1__ipad_DRAM_Q -type pg_pin
connect_global_net ESD_D1 -netlist_override -override -pin_base_name ESD -single_inst GEN_DRAM_Q_2__ipad_DRAM_Q -type pg_pin
connect_global_net ESD_D1 -netlist_override -override -pin_base_name ESD -single_inst GEN_DRAM_Q_3__ipad_DRAM_Q -type pg_pin
connect_global_net ESD_D1 -netlist_override -override -pin_base_name ESD -single_inst GEN_DRAM_Q_4__ipad_DRAM_Q -type pg_pin
connect_global_net ESD_D1 -netlist_override -override -pin_base_name ESD -single_inst GEN_DRAM_Q_5__ipad_DRAM_Q -type pg_pin
connect_global_net ESD_D1 -netlist_override -override -pin_base_name ESD -single_inst GEN_DRAM_Q_6__ipad_DRAM_Q -type pg_pin
connect_global_net ESD_D1 -netlist_override -override -pin_base_name ESD -single_inst GEN_DRAM_Q_7__ipad_DRAM_Q -type pg_pin
connect_global_net ESD_D1 -netlist_override -override -pin_base_name ESD -single_inst GEN_DRAM_Q_8__ipad_DRAM_Q -type pg_pin
connect_global_net ESD_D1 -netlist_override -override -pin_base_name ESD -single_inst GEN_DRAM_Q_9__ipad_DRAM_Q -type pg_pin
connect_global_net ESD_D1 -netlist_override -override -pin_base_name ESD -single_inst GEN_DRAM_Q_10__ipad_DRAM_Q -type pg_pin
connect_global_net ESD_D1 -netlist_override -override -pin_base_name ESD -single_inst GEN_DRAM_Q_11__ipad_DRAM_Q -type pg_pin
connect_global_net ESD_D1 -netlist_override -override -pin_base_name ESD -single_inst GEN_DRAM_Q_12__ipad_DRAM_Q -type pg_pin
connect_global_net ESD_D1 -netlist_override -override -pin_base_name ESD -single_inst CORE_VDD_LEVEL_01_PG1 -type pg_pin
connect_global_net ESD_D1 -netlist_override -override -pin_base_name ESD -single_inst AUTO_RTE_D1 -type pg_pin
connect_global_net ESD_D1 -netlist_override -override -pin_base_name ESD -single_inst IO_PG1 -type pg_pin
connect_global_net ESD_D1 -netlist_override -override -pin_base_name ESD -single_inst GEN_ROM_ADDR_10__opad_ROM_address -type pg_pin
connect_global_net ESD_D1 -netlist_override -override -pin_base_name ESD -single_inst GEN_ROM_ADDR_11__opad_ROM_address -type pg_pin
connect_global_net ESD_D1 -netlist_override -override -pin_base_name ESD -single_inst GEN_DRAM_WEN_0__opad_DRAM_WEn -type pg_pin
connect_global_net ESD_D1 -netlist_override -override -pin_base_name ESD -single_inst GEN_DRAM_WEN_1__opad_DRAM_WEn -type pg_pin
connect_global_net ESD_D1 -netlist_override -override -pin_base_name ESD -single_inst GEN_DRAM_WEN_2__opad_DRAM_WEn -type pg_pin
connect_global_net ESD_D1 -netlist_override -override -pin_base_name ESD -single_inst GEN_DRAM_WEN_3__opad_DRAM_WEn -type pg_pin
connect_global_net ESD_D1 -netlist_override -override -pin_base_name ESD -single_inst opad_ROM_read -type pg_pin
connect_global_net ESD_D1 -netlist_override -override -pin_base_name ESD -single_inst opad_ROM_enable -type pg_pin
connect_global_net ESD_D1 -netlist_override -override -pin_base_name ESD -single_inst opad_DRAM_CSn -type pg_pin
connect_global_net ESD_D1 -netlist_override -override -pin_base_name ESD -single_inst opad_DRAM_RASn -type pg_pin
connect_global_net ESD_D1 -netlist_override -override -pin_base_name ESD -single_inst opad_DRAM_CASn -type pg_pin
connect_global_net ESD_D1 -netlist_override -override -pin_base_name ESD -single_inst ipad_DRAM_valid -type pg_pin
connect_global_net ESD_D1 -netlist_override -override -pin_base_name ESD -single_inst ipad_cpu_clk -type pg_pin
connect_global_net ESD_D1 -netlist_override -override -pin_base_name ESD -single_inst ipad_axi_clk -type pg_pin
connect_global_net ESD_D1 -netlist_override -override -pin_base_name ESD -single_inst ipad_rom_clk -type pg_pin
connect_global_net ESD_D1 -netlist_override -override -pin_base_name ESD -single_inst ipad_dram_clk -type pg_pin
connect_global_net ESD_D1 -netlist_override -override -pin_base_name ESD -single_inst ipad_rom_rst -type pg_pin
connect_global_net ESD_D2 -netlist_override -override -pin_base_name ESD -single_inst CORE_VDD_LEVEL_02_PG1 -type pg_pin
connect_global_net ESD_D2 -netlist_override -override -pin_base_name ESD -single_inst pad_RTE_VDD_LEVEL_02 -type pg_pin
connect_global_net ESD_D2 -netlist_override -override -pin_base_name ESD -single_inst AUTO_IO_POWER_D2 -type pg_pin
connect_global_net ESD_D3 -netlist_override -override -pin_base_name ESD -single_inst GEN_DRAM_Q_13__ipad_DRAM_Q -type pg_pin
connect_global_net ESD_D3 -netlist_override -override -pin_base_name ESD -single_inst GEN_DRAM_Q_14__ipad_DRAM_Q -type pg_pin
connect_global_net ESD_D3 -netlist_override -override -pin_base_name ESD -single_inst GEN_DRAM_Q_15__ipad_DRAM_Q -type pg_pin
connect_global_net ESD_D3 -netlist_override -override -pin_base_name ESD -single_inst GEN_DRAM_Q_16__ipad_DRAM_Q -type pg_pin
connect_global_net ESD_D3 -netlist_override -override -pin_base_name ESD -single_inst GEN_DRAM_Q_17__ipad_DRAM_Q -type pg_pin
connect_global_net ESD_D3 -netlist_override -override -pin_base_name ESD -single_inst GEN_DRAM_Q_18__ipad_DRAM_Q -type pg_pin
connect_global_net ESD_D3 -netlist_override -override -pin_base_name ESD -single_inst GEN_DRAM_Q_19__ipad_DRAM_Q -type pg_pin
connect_global_net ESD_D3 -netlist_override -override -pin_base_name ESD -single_inst GEN_DRAM_Q_20__ipad_DRAM_Q -type pg_pin
connect_global_net ESD_D3 -netlist_override -override -pin_base_name ESD -single_inst GEN_DRAM_Q_21__ipad_DRAM_Q -type pg_pin
connect_global_net ESD_D3 -netlist_override -override -pin_base_name ESD -single_inst GEN_DRAM_Q_22__ipad_DRAM_Q -type pg_pin
connect_global_net ESD_D3 -netlist_override -override -pin_base_name ESD -single_inst GEN_DRAM_Q_23__ipad_DRAM_Q -type pg_pin
connect_global_net ESD_D3 -netlist_override -override -pin_base_name ESD -single_inst GEN_DRAM_Q_24__ipad_DRAM_Q -type pg_pin
connect_global_net ESD_D3 -netlist_override -override -pin_base_name ESD -single_inst GEN_DRAM_Q_25__ipad_DRAM_Q -type pg_pin
connect_global_net ESD_D3 -netlist_override -override -pin_base_name ESD -single_inst GEN_DRAM_Q_26__ipad_DRAM_Q -type pg_pin
connect_global_net ESD_D3 -netlist_override -override -pin_base_name ESD -single_inst GEN_DRAM_Q_27__ipad_DRAM_Q -type pg_pin
connect_global_net ESD_D3 -netlist_override -override -pin_base_name ESD -single_inst GEN_DRAM_Q_28__ipad_DRAM_Q -type pg_pin
connect_global_net ESD_D3 -netlist_override -override -pin_base_name ESD -single_inst GEN_ROM_OUT_31__ipad_ROM_out -type pg_pin
connect_global_net ESD_D3 -netlist_override -override -pin_base_name ESD -single_inst GEN_ROM_OUT_30__ipad_ROM_out -type pg_pin
connect_global_net ESD_D3 -netlist_override -override -pin_base_name ESD -single_inst GEN_ROM_OUT_29__ipad_ROM_out -type pg_pin
connect_global_net ESD_D3 -netlist_override -override -pin_base_name ESD -single_inst GEN_ROM_OUT_28__ipad_ROM_out -type pg_pin
connect_global_net ESD_D3 -netlist_override -override -pin_base_name ESD -single_inst GEN_ROM_OUT_27__ipad_ROM_out -type pg_pin
connect_global_net ESD_D3 -netlist_override -override -pin_base_name ESD -single_inst GEN_ROM_OUT_26__ipad_ROM_out -type pg_pin
connect_global_net ESD_D3 -netlist_override -override -pin_base_name ESD -single_inst GEN_ROM_OUT_25__ipad_ROM_out -type pg_pin
connect_global_net ESD_D3 -netlist_override -override -pin_base_name ESD -single_inst GEN_ROM_OUT_24__ipad_ROM_out -type pg_pin
connect_global_net ESD_D3 -netlist_override -override -pin_base_name ESD -single_inst GEN_ROM_OUT_23__ipad_ROM_out -type pg_pin
connect_global_net ESD_D3 -netlist_override -override -pin_base_name ESD -single_inst GEN_ROM_OUT_22__ipad_ROM_out -type pg_pin
connect_global_net ESD_D3 -netlist_override -override -pin_base_name ESD -single_inst GEN_ROM_OUT_21__ipad_ROM_out -type pg_pin
connect_global_net ESD_D3 -netlist_override -override -pin_base_name ESD -single_inst GEN_ROM_OUT_20__ipad_ROM_out -type pg_pin
connect_global_net ESD_D3 -netlist_override -override -pin_base_name ESD -single_inst GEN_ROM_OUT_19__ipad_ROM_out -type pg_pin
connect_global_net ESD_D3 -netlist_override -override -pin_base_name ESD -single_inst GEN_ROM_OUT_18__ipad_ROM_out -type pg_pin
connect_global_net ESD_D3 -netlist_override -override -pin_base_name ESD -single_inst GEN_ROM_OUT_17__ipad_ROM_out -type pg_pin
connect_global_net ESD_D3 -netlist_override -override -pin_base_name ESD -single_inst GEN_ROM_OUT_16__ipad_ROM_out -type pg_pin
connect_global_net ESD_D3 -netlist_override -override -pin_base_name ESD -single_inst GEN_ROM_OUT_15__ipad_ROM_out -type pg_pin
connect_global_net ESD_D3 -netlist_override -override -pin_base_name ESD -single_inst AUTO_IO_POWER_D3 -type pg_pin
connect_global_net ESD_D3 -netlist_override -override -pin_base_name ESD -single_inst pad_RTE -type pg_pin
connect_global_net ESD_D3 -netlist_override -override -pin_base_name ESD -single_inst AUTO_CORE_POWER_D3 -type pg_pin
connect_global_net ESD_D4 -netlist_override -override -pin_base_name ESD -single_inst CORE_VDD_LEVEL_02_PG2 -type pg_pin
connect_global_net ESD_D4 -netlist_override -override -pin_base_name ESD -single_inst AUTO_RTE_D4 -type pg_pin
connect_global_net ESD_D4 -netlist_override -override -pin_base_name ESD -single_inst AUTO_IO_POWER_D4 -type pg_pin
connect_global_net ESD_D5 -netlist_override -override -pin_base_name ESD -single_inst IO_PG2 -type pg_pin
connect_global_net ESD_D5 -netlist_override -override -pin_base_name ESD -single_inst AUTO_RTE_D5 -type pg_pin
connect_global_net ESD_D5 -netlist_override -override -pin_base_name ESD -single_inst CORE_VDD_LEVEL_01_PG2 -type pg_pin
connect_global_net ESD_D5 -netlist_override -override -pin_base_name ESD -single_inst GEN_ROM_OUT_14__ipad_ROM_out -type pg_pin
connect_global_net ESD_D5 -netlist_override -override -pin_base_name ESD -single_inst GEN_ROM_OUT_13__ipad_ROM_out -type pg_pin
connect_global_net ESD_D5 -netlist_override -override -pin_base_name ESD -single_inst GEN_ROM_OUT_12__ipad_ROM_out -type pg_pin
connect_global_net ESD_D5 -netlist_override -override -pin_base_name ESD -single_inst GEN_ROM_OUT_11__ipad_ROM_out -type pg_pin
connect_global_net ESD_D5 -netlist_override -override -pin_base_name ESD -single_inst GEN_ROM_OUT_10__ipad_ROM_out -type pg_pin
connect_global_net ESD_D5 -netlist_override -override -pin_base_name ESD -single_inst GEN_ROM_OUT_9__ipad_ROM_out -type pg_pin
connect_global_net ESD_D5 -netlist_override -override -pin_base_name ESD -single_inst GEN_ROM_OUT_8__ipad_ROM_out -type pg_pin
connect_global_net ESD_D5 -netlist_override -override -pin_base_name ESD -single_inst GEN_ROM_OUT_7__ipad_ROM_out -type pg_pin
connect_global_net ESD_D5 -netlist_override -override -pin_base_name ESD -single_inst GEN_ROM_OUT_6__ipad_ROM_out -type pg_pin
connect_global_net ESD_D5 -netlist_override -override -pin_base_name ESD -single_inst GEN_ROM_OUT_5__ipad_ROM_out -type pg_pin
connect_global_net ESD_D5 -netlist_override -override -pin_base_name ESD -single_inst GEN_ROM_OUT_4__ipad_ROM_out -type pg_pin
connect_global_net ESD_D5 -netlist_override -override -pin_base_name ESD -single_inst GEN_ROM_OUT_3__ipad_ROM_out -type pg_pin
connect_global_net ESD_D5 -netlist_override -override -pin_base_name ESD -single_inst GEN_ROM_OUT_2__ipad_ROM_out -type pg_pin
connect_global_net ESD_D5 -netlist_override -override -pin_base_name ESD -single_inst GEN_ROM_OUT_1__ipad_ROM_out -type pg_pin
connect_global_net ESD_D5 -netlist_override -override -pin_base_name ESD -single_inst GEN_ROM_OUT_0__ipad_ROM_out -type pg_pin
connect_global_net ESD_D5 -netlist_override -override -pin_base_name ESD -single_inst GEN_DRAM_Q_31__ipad_DRAM_Q -type pg_pin
connect_global_net ESD_D5 -netlist_override -override -pin_base_name ESD -single_inst GEN_DRAM_Q_30__ipad_DRAM_Q -type pg_pin
connect_global_net ESD_D5 -netlist_override -override -pin_base_name ESD -single_inst GEN_DRAM_Q_29__ipad_DRAM_Q -type pg_pin
connect_global_net ESD_D5 -netlist_override -override -pin_base_name ESD -single_inst GEN_DRAM_A_2__opad_DRAM_A -type pg_pin
connect_global_net ESD_D5 -netlist_override -override -pin_base_name ESD -single_inst GEN_DRAM_A_1__opad_DRAM_A -type pg_pin
connect_global_net ESD_D5 -netlist_override -override -pin_base_name ESD -single_inst GEN_DRAM_A_0__opad_DRAM_A -type pg_pin
connect_global_net ESD_D5 -netlist_override -override -pin_base_name ESD -single_inst GEN_DRAM_D_31__opad_DRAM_D -type pg_pin
connect_global_net ESD_D5 -netlist_override -override -pin_base_name ESD -single_inst GEN_DRAM_D_30__opad_DRAM_D -type pg_pin
connect_global_net ESD_D5 -netlist_override -override -pin_base_name ESD -single_inst GEN_DRAM_D_29__opad_DRAM_D -type pg_pin
connect_global_net ESD_D5 -netlist_override -override -pin_base_name ESD -single_inst GEN_DRAM_D_28__opad_DRAM_D -type pg_pin
connect_global_net ESD_D5 -netlist_override -override -pin_base_name ESD -single_inst GEN_DRAM_D_27__opad_DRAM_D -type pg_pin
connect_global_net ESD_D5 -netlist_override -override -pin_base_name ESD -single_inst GEN_DRAM_D_26__opad_DRAM_D -type pg_pin
connect_global_net ESD_D5 -netlist_override -override -pin_base_name ESD -single_inst GEN_DRAM_D_25__opad_DRAM_D -type pg_pin
connect_global_net ESD_D5 -netlist_override -override -pin_base_name ESD -single_inst GEN_DRAM_D_24__opad_DRAM_D -type pg_pin
connect_global_net ESD_D5 -netlist_override -override -pin_base_name ESD -single_inst GEN_DRAM_D_23__opad_DRAM_D -type pg_pin
connect_global_net ESD_D5 -netlist_override -override -pin_base_name ESD -single_inst GEN_DRAM_D_22__opad_DRAM_D -type pg_pin
connect_global_net ESD_D5 -netlist_override -override -pin_base_name ESD -single_inst GEN_DRAM_D_21__opad_DRAM_D -type pg_pin
connect_global_net ESD_D5 -netlist_override -override -pin_base_name ESD -single_inst GEN_DRAM_D_20__opad_DRAM_D -type pg_pin
connect_global_net ESD_D5 -netlist_override -override -pin_base_name ESD -single_inst GEN_DRAM_D_19__opad_DRAM_D -type pg_pin
connect_global_net ESD_D5 -netlist_override -override -pin_base_name ESD -single_inst GEN_DRAM_D_18__opad_DRAM_D -type pg_pin
connect_global_net ESD_D6 -netlist_override -override -pin_base_name ESD -single_inst CORE_VDD_LEVEL_02_PG3 -type pg_pin
connect_global_net ESD_D6 -netlist_override -override -pin_base_name ESD -single_inst AUTO_RTE_D6 -type pg_pin
connect_global_net ESD_D6 -netlist_override -override -pin_base_name ESD -single_inst AUTO_IO_POWER_D6 -type pg_pin
connect_global_net ESD_D7 -netlist_override -override -pin_base_name ESD -single_inst GEN_DRAM_D_17__opad_DRAM_D -type pg_pin
connect_global_net ESD_D7 -netlist_override -override -pin_base_name ESD -single_inst GEN_DRAM_D_16__opad_DRAM_D -type pg_pin
connect_global_net ESD_D7 -netlist_override -override -pin_base_name ESD -single_inst GEN_DRAM_D_15__opad_DRAM_D -type pg_pin
connect_global_net ESD_D7 -netlist_override -override -pin_base_name ESD -single_inst GEN_DRAM_D_14__opad_DRAM_D -type pg_pin
connect_global_net ESD_D7 -netlist_override -override -pin_base_name ESD -single_inst GEN_DRAM_D_13__opad_DRAM_D -type pg_pin
connect_global_net ESD_D7 -netlist_override -override -pin_base_name ESD -single_inst GEN_DRAM_D_12__opad_DRAM_D -type pg_pin
connect_global_net ESD_D7 -netlist_override -override -pin_base_name ESD -single_inst GEN_DRAM_D_11__opad_DRAM_D -type pg_pin
connect_global_net ESD_D7 -netlist_override -override -pin_base_name ESD -single_inst GEN_DRAM_D_10__opad_DRAM_D -type pg_pin
connect_global_net ESD_D7 -netlist_override -override -pin_base_name ESD -single_inst GEN_DRAM_D_9__opad_DRAM_D -type pg_pin
connect_global_net ESD_D7 -netlist_override -override -pin_base_name ESD -single_inst GEN_DRAM_D_8__opad_DRAM_D -type pg_pin
connect_global_net ESD_D7 -netlist_override -override -pin_base_name ESD -single_inst GEN_DRAM_D_7__opad_DRAM_D -type pg_pin
connect_global_net ESD_D7 -netlist_override -override -pin_base_name ESD -single_inst GEN_DRAM_D_6__opad_DRAM_D -type pg_pin
connect_global_net ESD_D7 -netlist_override -override -pin_base_name ESD -single_inst GEN_DRAM_D_5__opad_DRAM_D -type pg_pin
connect_global_net ESD_D7 -netlist_override -override -pin_base_name ESD -single_inst GEN_DRAM_D_4__opad_DRAM_D -type pg_pin
connect_global_net ESD_D7 -netlist_override -override -pin_base_name ESD -single_inst GEN_DRAM_D_3__opad_DRAM_D -type pg_pin
connect_global_net ESD_D7 -netlist_override -override -pin_base_name ESD -single_inst GEN_DRAM_D_2__opad_DRAM_D -type pg_pin
connect_global_net ESD_D7 -netlist_override -override -pin_base_name ESD -single_inst GEN_DRAM_D_1__opad_DRAM_D -type pg_pin
connect_global_net ESD_D7 -netlist_override -override -pin_base_name ESD -single_inst GEN_DRAM_D_0__opad_DRAM_D -type pg_pin
connect_global_net ESD_D7 -netlist_override -override -pin_base_name ESD -single_inst GEN_DRAM_A_3__opad_DRAM_A -type pg_pin
connect_global_net ESD_D7 -netlist_override -override -pin_base_name ESD -single_inst GEN_DRAM_A_4__opad_DRAM_A -type pg_pin
connect_global_net ESD_D7 -netlist_override -override -pin_base_name ESD -single_inst GEN_DRAM_A_5__opad_DRAM_A -type pg_pin
connect_global_net ESD_D7 -netlist_override -override -pin_base_name ESD -single_inst GEN_DRAM_A_6__opad_DRAM_A -type pg_pin
connect_global_net ESD_D7 -netlist_override -override -pin_base_name ESD -single_inst GEN_DRAM_A_7__opad_DRAM_A -type pg_pin
connect_global_net ESD_D7 -netlist_override -override -pin_base_name ESD -single_inst GEN_DRAM_A_8__opad_DRAM_A -type pg_pin
connect_global_net ESD_D7 -netlist_override -override -pin_base_name ESD -single_inst GEN_DRAM_A_9__opad_DRAM_A -type pg_pin
connect_global_net ESD_D7 -netlist_override -override -pin_base_name ESD -single_inst GEN_DRAM_A_10__opad_DRAM_A -type pg_pin
connect_global_net ESD_D7 -netlist_override -override -pin_base_name ESD -single_inst GEN_ROM_ADDR_0__opad_ROM_address -type pg_pin
connect_global_net ESD_D7 -netlist_override -override -pin_base_name ESD -single_inst GEN_ROM_ADDR_1__opad_ROM_address -type pg_pin
connect_global_net ESD_D7 -netlist_override -override -pin_base_name ESD -single_inst GEN_ROM_ADDR_2__opad_ROM_address -type pg_pin
connect_global_net ESD_D7 -netlist_override -override -pin_base_name ESD -single_inst GEN_ROM_ADDR_3__opad_ROM_address -type pg_pin
connect_global_net ESD_D7 -netlist_override -override -pin_base_name ESD -single_inst GEN_ROM_ADDR_4__opad_ROM_address -type pg_pin
connect_global_net ESD_D7 -netlist_override -override -pin_base_name ESD -single_inst GEN_ROM_ADDR_5__opad_ROM_address -type pg_pin
connect_global_net ESD_D7 -netlist_override -override -pin_base_name ESD -single_inst GEN_ROM_ADDR_6__opad_ROM_address -type pg_pin
connect_global_net ESD_D7 -netlist_override -override -pin_base_name ESD -single_inst GEN_ROM_ADDR_7__opad_ROM_address -type pg_pin
connect_global_net ESD_D7 -netlist_override -override -pin_base_name ESD -single_inst GEN_ROM_ADDR_8__opad_ROM_address -type pg_pin
connect_global_net ESD_D7 -netlist_override -override -pin_base_name ESD -single_inst GEN_ROM_ADDR_9__opad_ROM_address -type pg_pin
connect_global_net ESD_D7 -netlist_override -override -pin_base_name ESD -single_inst CORE_VDD_LEVEL_01_PG4 -type pg_pin
connect_global_net ESD_D7 -netlist_override -override -pin_base_name ESD -single_inst AUTO_RTE_D7 -type pg_pin
connect_global_net ESD_D7 -netlist_override -override -pin_base_name ESD -single_inst IO_PG4 -type pg_pin
connect_global_net ESD_D8 -netlist_override -override -pin_base_name ESD -single_inst CORE_VDD_LEVEL_02_PG4 -type pg_pin
connect_global_net ESD_D8 -netlist_override -override -pin_base_name ESD -single_inst AUTO_RTE_D8 -type pg_pin
connect_global_net ESD_D8 -netlist_override -override -pin_base_name ESD -single_inst AUTO_IO_POWER_D8 -type pg_pin
connect_global_net VSSPST_D1 -netlist_override -override -pin_base_name VSSPST1 -single_inst RAILCUT_VDD_LEVEL_02_TOP1 -type pg_pin
connect_global_net VSSPST_D2 -netlist_override -override -pin_base_name VSSPST2 -single_inst RAILCUT_VDD_LEVEL_02_TOP1 -type pg_pin
connect_global_net VSSPST_D8 -netlist_override -override -pin_base_name VSSPST1 -single_inst RAILCUT_VDD_LEVEL_02_LEFT2 -type pg_pin
connect_global_net VSSPST_D1 -netlist_override -override -pin_base_name VSSPST2 -single_inst RAILCUT_VDD_LEVEL_02_LEFT2 -type pg_pin
connect_global_net VSSPST_D2 -netlist_override -override -pin_base_name VSSPST1 -single_inst RAILCUT_VDD_LEVEL_02_TOP2 -type pg_pin
connect_global_net VSSPST_D3 -netlist_override -override -pin_base_name VSSPST2 -single_inst RAILCUT_VDD_LEVEL_02_TOP2 -type pg_pin
connect_global_net VSSPST_D3 -netlist_override -override -pin_base_name VSSPST1 -single_inst RAILCUT_VDD_LEVEL_02_RIGHT2 -type pg_pin
connect_global_net VSSPST_D4 -netlist_override -override -pin_base_name VSSPST2 -single_inst RAILCUT_VDD_LEVEL_02_RIGHT2 -type pg_pin
connect_global_net VSSPST_D4 -netlist_override -override -pin_base_name VSSPST1 -single_inst RAILCUT_VDD_LEVEL_02_RIGHT1 -type pg_pin
connect_global_net VSSPST_D5 -netlist_override -override -pin_base_name VSSPST2 -single_inst RAILCUT_VDD_LEVEL_02_RIGHT1 -type pg_pin
connect_global_net VSSPST_D5 -netlist_override -override -pin_base_name VSSPST1 -single_inst RAILCUT_VDD_LEVEL_02_BOTTOM2 -type pg_pin
connect_global_net VSSPST_D6 -netlist_override -override -pin_base_name VSSPST2 -single_inst RAILCUT_VDD_LEVEL_02_BOTTOM2 -type pg_pin
connect_global_net VSSPST_D6 -netlist_override -override -pin_base_name VSSPST1 -single_inst RAILCUT_VDD_LEVEL_02_BOTTOM1 -type pg_pin
connect_global_net VSSPST_D7 -netlist_override -override -pin_base_name VSSPST2 -single_inst RAILCUT_VDD_LEVEL_02_BOTTOM1 -type pg_pin
connect_global_net VSSPST_D7 -netlist_override -override -pin_base_name VSSPST1 -single_inst RAILCUT_VDD_LEVEL_02_LEFT1 -type pg_pin
connect_global_net VSSPST_D8 -netlist_override -override -pin_base_name VSSPST2 -single_inst RAILCUT_VDD_LEVEL_02_LEFT1 -type pg_pin
connect_global_net POCCTRL_D1 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_v_ctrl_idx_0__opad_v_ctrl_idx -type pg_pin
connect_global_net POCCTRL_D1 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_v_ctrl_idx_1__opad_v_ctrl_idx -type pg_pin
connect_global_net POCCTRL_D1 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_v_ctrl_0__opad_v_ctrl -type pg_pin
connect_global_net POCCTRL_D1 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_v_ctrl_1__opad_v_ctrl -type pg_pin
connect_global_net POCCTRL_D1 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_DRAM_Q_0__ipad_DRAM_Q -type pg_pin
connect_global_net POCCTRL_D1 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_DRAM_Q_1__ipad_DRAM_Q -type pg_pin
connect_global_net POCCTRL_D1 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_DRAM_Q_2__ipad_DRAM_Q -type pg_pin
connect_global_net POCCTRL_D1 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_DRAM_Q_3__ipad_DRAM_Q -type pg_pin
connect_global_net POCCTRL_D1 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_DRAM_Q_4__ipad_DRAM_Q -type pg_pin
connect_global_net POCCTRL_D1 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_DRAM_Q_5__ipad_DRAM_Q -type pg_pin
connect_global_net POCCTRL_D1 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_DRAM_Q_6__ipad_DRAM_Q -type pg_pin
connect_global_net POCCTRL_D1 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_DRAM_Q_7__ipad_DRAM_Q -type pg_pin
connect_global_net POCCTRL_D1 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_DRAM_Q_8__ipad_DRAM_Q -type pg_pin
connect_global_net POCCTRL_D1 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_DRAM_Q_9__ipad_DRAM_Q -type pg_pin
connect_global_net POCCTRL_D1 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_DRAM_Q_10__ipad_DRAM_Q -type pg_pin
connect_global_net POCCTRL_D1 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_DRAM_Q_11__ipad_DRAM_Q -type pg_pin
connect_global_net POCCTRL_D1 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_DRAM_Q_12__ipad_DRAM_Q -type pg_pin
connect_global_net POCCTRL_D1 -netlist_override -override -pin_base_name POCCTRL -single_inst CORE_VDD_LEVEL_01_PG1 -type pg_pin
connect_global_net POCCTRL_D1 -netlist_override -override -pin_base_name POCCTRL -single_inst AUTO_RTE_D1 -type pg_pin
connect_global_net POCCTRL_D1 -netlist_override -override -pin_base_name POCCTRL -single_inst IO_PG1 -type pg_pin
connect_global_net POCCTRL_D1 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_ROM_ADDR_10__opad_ROM_address -type pg_pin
connect_global_net POCCTRL_D1 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_ROM_ADDR_11__opad_ROM_address -type pg_pin
connect_global_net POCCTRL_D1 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_DRAM_WEN_0__opad_DRAM_WEn -type pg_pin
connect_global_net POCCTRL_D1 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_DRAM_WEN_1__opad_DRAM_WEn -type pg_pin
connect_global_net POCCTRL_D1 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_DRAM_WEN_2__opad_DRAM_WEn -type pg_pin
connect_global_net POCCTRL_D1 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_DRAM_WEN_3__opad_DRAM_WEn -type pg_pin
connect_global_net POCCTRL_D1 -netlist_override -override -pin_base_name POCCTRL -single_inst opad_ROM_read -type pg_pin
connect_global_net POCCTRL_D1 -netlist_override -override -pin_base_name POCCTRL -single_inst opad_ROM_enable -type pg_pin
connect_global_net POCCTRL_D1 -netlist_override -override -pin_base_name POCCTRL -single_inst opad_DRAM_CSn -type pg_pin
connect_global_net POCCTRL_D1 -netlist_override -override -pin_base_name POCCTRL -single_inst opad_DRAM_RASn -type pg_pin
connect_global_net POCCTRL_D1 -netlist_override -override -pin_base_name POCCTRL -single_inst opad_DRAM_CASn -type pg_pin
connect_global_net POCCTRL_D1 -netlist_override -override -pin_base_name POCCTRL -single_inst ipad_DRAM_valid -type pg_pin
connect_global_net POCCTRL_D1 -netlist_override -override -pin_base_name POCCTRL -single_inst ipad_cpu_clk -type pg_pin
connect_global_net POCCTRL_D1 -netlist_override -override -pin_base_name POCCTRL -single_inst ipad_axi_clk -type pg_pin
connect_global_net POCCTRL_D1 -netlist_override -override -pin_base_name POCCTRL -single_inst ipad_rom_clk -type pg_pin
connect_global_net POCCTRL_D1 -netlist_override -override -pin_base_name POCCTRL -single_inst ipad_dram_clk -type pg_pin
connect_global_net POCCTRL_D1 -netlist_override -override -pin_base_name POCCTRL -single_inst ipad_rom_rst -type pg_pin
connect_global_net POCCTRL_D2 -netlist_override -override -pin_base_name POCCTRL -single_inst CORE_VDD_LEVEL_02_PG1 -type pg_pin
connect_global_net POCCTRL_D2 -netlist_override -override -pin_base_name POCCTRL -single_inst pad_RTE_VDD_LEVEL_02 -type pg_pin
connect_global_net POCCTRL_D2 -netlist_override -override -pin_base_name POCCTRL -single_inst AUTO_IO_POWER_D2 -type pg_pin
connect_global_net POCCTRL_D3 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_DRAM_Q_13__ipad_DRAM_Q -type pg_pin
connect_global_net POCCTRL_D3 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_DRAM_Q_14__ipad_DRAM_Q -type pg_pin
connect_global_net POCCTRL_D3 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_DRAM_Q_15__ipad_DRAM_Q -type pg_pin
connect_global_net POCCTRL_D3 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_DRAM_Q_16__ipad_DRAM_Q -type pg_pin
connect_global_net POCCTRL_D3 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_DRAM_Q_17__ipad_DRAM_Q -type pg_pin
connect_global_net POCCTRL_D3 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_DRAM_Q_18__ipad_DRAM_Q -type pg_pin
connect_global_net POCCTRL_D3 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_DRAM_Q_19__ipad_DRAM_Q -type pg_pin
connect_global_net POCCTRL_D3 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_DRAM_Q_20__ipad_DRAM_Q -type pg_pin
connect_global_net POCCTRL_D3 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_DRAM_Q_21__ipad_DRAM_Q -type pg_pin
connect_global_net POCCTRL_D3 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_DRAM_Q_22__ipad_DRAM_Q -type pg_pin
connect_global_net POCCTRL_D3 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_DRAM_Q_23__ipad_DRAM_Q -type pg_pin
connect_global_net POCCTRL_D3 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_DRAM_Q_24__ipad_DRAM_Q -type pg_pin
connect_global_net POCCTRL_D3 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_DRAM_Q_25__ipad_DRAM_Q -type pg_pin
connect_global_net POCCTRL_D3 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_DRAM_Q_26__ipad_DRAM_Q -type pg_pin
connect_global_net POCCTRL_D3 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_DRAM_Q_27__ipad_DRAM_Q -type pg_pin
connect_global_net POCCTRL_D3 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_DRAM_Q_28__ipad_DRAM_Q -type pg_pin
connect_global_net POCCTRL_D3 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_ROM_OUT_31__ipad_ROM_out -type pg_pin
connect_global_net POCCTRL_D3 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_ROM_OUT_30__ipad_ROM_out -type pg_pin
connect_global_net POCCTRL_D3 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_ROM_OUT_29__ipad_ROM_out -type pg_pin
connect_global_net POCCTRL_D3 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_ROM_OUT_28__ipad_ROM_out -type pg_pin
connect_global_net POCCTRL_D3 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_ROM_OUT_27__ipad_ROM_out -type pg_pin
connect_global_net POCCTRL_D3 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_ROM_OUT_26__ipad_ROM_out -type pg_pin
connect_global_net POCCTRL_D3 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_ROM_OUT_25__ipad_ROM_out -type pg_pin
connect_global_net POCCTRL_D3 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_ROM_OUT_24__ipad_ROM_out -type pg_pin
connect_global_net POCCTRL_D3 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_ROM_OUT_23__ipad_ROM_out -type pg_pin
connect_global_net POCCTRL_D3 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_ROM_OUT_22__ipad_ROM_out -type pg_pin
connect_global_net POCCTRL_D3 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_ROM_OUT_21__ipad_ROM_out -type pg_pin
connect_global_net POCCTRL_D3 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_ROM_OUT_20__ipad_ROM_out -type pg_pin
connect_global_net POCCTRL_D3 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_ROM_OUT_19__ipad_ROM_out -type pg_pin
connect_global_net POCCTRL_D3 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_ROM_OUT_18__ipad_ROM_out -type pg_pin
connect_global_net POCCTRL_D3 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_ROM_OUT_17__ipad_ROM_out -type pg_pin
connect_global_net POCCTRL_D3 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_ROM_OUT_16__ipad_ROM_out -type pg_pin
connect_global_net POCCTRL_D3 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_ROM_OUT_15__ipad_ROM_out -type pg_pin
connect_global_net POCCTRL_D3 -netlist_override -override -pin_base_name POCCTRL -single_inst AUTO_IO_POWER_D3 -type pg_pin
connect_global_net POCCTRL_D3 -netlist_override -override -pin_base_name POCCTRL -single_inst pad_RTE -type pg_pin
connect_global_net POCCTRL_D3 -netlist_override -override -pin_base_name POCCTRL -single_inst AUTO_CORE_POWER_D3 -type pg_pin
connect_global_net POCCTRL_D4 -netlist_override -override -pin_base_name POCCTRL -single_inst CORE_VDD_LEVEL_02_PG2 -type pg_pin
connect_global_net POCCTRL_D4 -netlist_override -override -pin_base_name POCCTRL -single_inst AUTO_RTE_D4 -type pg_pin
connect_global_net POCCTRL_D4 -netlist_override -override -pin_base_name POCCTRL -single_inst AUTO_IO_POWER_D4 -type pg_pin
connect_global_net POCCTRL_D5 -netlist_override -override -pin_base_name POCCTRL -single_inst IO_PG2 -type pg_pin
connect_global_net POCCTRL_D5 -netlist_override -override -pin_base_name POCCTRL -single_inst AUTO_RTE_D5 -type pg_pin
connect_global_net POCCTRL_D5 -netlist_override -override -pin_base_name POCCTRL -single_inst CORE_VDD_LEVEL_01_PG2 -type pg_pin
connect_global_net POCCTRL_D5 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_ROM_OUT_14__ipad_ROM_out -type pg_pin
connect_global_net POCCTRL_D5 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_ROM_OUT_13__ipad_ROM_out -type pg_pin
connect_global_net POCCTRL_D5 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_ROM_OUT_12__ipad_ROM_out -type pg_pin
connect_global_net POCCTRL_D5 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_ROM_OUT_11__ipad_ROM_out -type pg_pin
connect_global_net POCCTRL_D5 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_ROM_OUT_10__ipad_ROM_out -type pg_pin
connect_global_net POCCTRL_D5 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_ROM_OUT_9__ipad_ROM_out -type pg_pin
connect_global_net POCCTRL_D5 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_ROM_OUT_8__ipad_ROM_out -type pg_pin
connect_global_net POCCTRL_D5 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_ROM_OUT_7__ipad_ROM_out -type pg_pin
connect_global_net POCCTRL_D5 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_ROM_OUT_6__ipad_ROM_out -type pg_pin
connect_global_net POCCTRL_D5 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_ROM_OUT_5__ipad_ROM_out -type pg_pin
connect_global_net POCCTRL_D5 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_ROM_OUT_4__ipad_ROM_out -type pg_pin
connect_global_net POCCTRL_D5 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_ROM_OUT_3__ipad_ROM_out -type pg_pin
connect_global_net POCCTRL_D5 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_ROM_OUT_2__ipad_ROM_out -type pg_pin
connect_global_net POCCTRL_D5 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_ROM_OUT_1__ipad_ROM_out -type pg_pin
connect_global_net POCCTRL_D5 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_ROM_OUT_0__ipad_ROM_out -type pg_pin
connect_global_net POCCTRL_D5 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_DRAM_Q_31__ipad_DRAM_Q -type pg_pin
connect_global_net POCCTRL_D5 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_DRAM_Q_30__ipad_DRAM_Q -type pg_pin
connect_global_net POCCTRL_D5 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_DRAM_Q_29__ipad_DRAM_Q -type pg_pin
connect_global_net POCCTRL_D5 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_DRAM_A_2__opad_DRAM_A -type pg_pin
connect_global_net POCCTRL_D5 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_DRAM_A_1__opad_DRAM_A -type pg_pin
connect_global_net POCCTRL_D5 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_DRAM_A_0__opad_DRAM_A -type pg_pin
connect_global_net POCCTRL_D5 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_DRAM_D_31__opad_DRAM_D -type pg_pin
connect_global_net POCCTRL_D5 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_DRAM_D_30__opad_DRAM_D -type pg_pin
connect_global_net POCCTRL_D5 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_DRAM_D_29__opad_DRAM_D -type pg_pin
connect_global_net POCCTRL_D5 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_DRAM_D_28__opad_DRAM_D -type pg_pin
connect_global_net POCCTRL_D5 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_DRAM_D_27__opad_DRAM_D -type pg_pin
connect_global_net POCCTRL_D5 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_DRAM_D_26__opad_DRAM_D -type pg_pin
connect_global_net POCCTRL_D5 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_DRAM_D_25__opad_DRAM_D -type pg_pin
connect_global_net POCCTRL_D5 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_DRAM_D_24__opad_DRAM_D -type pg_pin
connect_global_net POCCTRL_D5 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_DRAM_D_23__opad_DRAM_D -type pg_pin
connect_global_net POCCTRL_D5 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_DRAM_D_22__opad_DRAM_D -type pg_pin
connect_global_net POCCTRL_D5 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_DRAM_D_21__opad_DRAM_D -type pg_pin
connect_global_net POCCTRL_D5 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_DRAM_D_20__opad_DRAM_D -type pg_pin
connect_global_net POCCTRL_D5 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_DRAM_D_19__opad_DRAM_D -type pg_pin
connect_global_net POCCTRL_D5 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_DRAM_D_18__opad_DRAM_D -type pg_pin
connect_global_net POCCTRL_D6 -netlist_override -override -pin_base_name POCCTRL -single_inst CORE_VDD_LEVEL_02_PG3 -type pg_pin
connect_global_net POCCTRL_D6 -netlist_override -override -pin_base_name POCCTRL -single_inst AUTO_RTE_D6 -type pg_pin
connect_global_net POCCTRL_D6 -netlist_override -override -pin_base_name POCCTRL -single_inst AUTO_IO_POWER_D6 -type pg_pin
connect_global_net POCCTRL_D7 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_DRAM_D_17__opad_DRAM_D -type pg_pin
connect_global_net POCCTRL_D7 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_DRAM_D_16__opad_DRAM_D -type pg_pin
connect_global_net POCCTRL_D7 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_DRAM_D_15__opad_DRAM_D -type pg_pin
connect_global_net POCCTRL_D7 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_DRAM_D_14__opad_DRAM_D -type pg_pin
connect_global_net POCCTRL_D7 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_DRAM_D_13__opad_DRAM_D -type pg_pin
connect_global_net POCCTRL_D7 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_DRAM_D_12__opad_DRAM_D -type pg_pin
connect_global_net POCCTRL_D7 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_DRAM_D_11__opad_DRAM_D -type pg_pin
connect_global_net POCCTRL_D7 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_DRAM_D_10__opad_DRAM_D -type pg_pin
connect_global_net POCCTRL_D7 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_DRAM_D_9__opad_DRAM_D -type pg_pin
connect_global_net POCCTRL_D7 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_DRAM_D_8__opad_DRAM_D -type pg_pin
connect_global_net POCCTRL_D7 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_DRAM_D_7__opad_DRAM_D -type pg_pin
connect_global_net POCCTRL_D7 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_DRAM_D_6__opad_DRAM_D -type pg_pin
connect_global_net POCCTRL_D7 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_DRAM_D_5__opad_DRAM_D -type pg_pin
connect_global_net POCCTRL_D7 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_DRAM_D_4__opad_DRAM_D -type pg_pin
connect_global_net POCCTRL_D7 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_DRAM_D_3__opad_DRAM_D -type pg_pin
connect_global_net POCCTRL_D7 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_DRAM_D_2__opad_DRAM_D -type pg_pin
connect_global_net POCCTRL_D7 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_DRAM_D_1__opad_DRAM_D -type pg_pin
connect_global_net POCCTRL_D7 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_DRAM_D_0__opad_DRAM_D -type pg_pin
connect_global_net POCCTRL_D7 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_DRAM_A_3__opad_DRAM_A -type pg_pin
connect_global_net POCCTRL_D7 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_DRAM_A_4__opad_DRAM_A -type pg_pin
connect_global_net POCCTRL_D7 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_DRAM_A_5__opad_DRAM_A -type pg_pin
connect_global_net POCCTRL_D7 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_DRAM_A_6__opad_DRAM_A -type pg_pin
connect_global_net POCCTRL_D7 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_DRAM_A_7__opad_DRAM_A -type pg_pin
connect_global_net POCCTRL_D7 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_DRAM_A_8__opad_DRAM_A -type pg_pin
connect_global_net POCCTRL_D7 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_DRAM_A_9__opad_DRAM_A -type pg_pin
connect_global_net POCCTRL_D7 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_DRAM_A_10__opad_DRAM_A -type pg_pin
connect_global_net POCCTRL_D7 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_ROM_ADDR_0__opad_ROM_address -type pg_pin
connect_global_net POCCTRL_D7 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_ROM_ADDR_1__opad_ROM_address -type pg_pin
connect_global_net POCCTRL_D7 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_ROM_ADDR_2__opad_ROM_address -type pg_pin
connect_global_net POCCTRL_D7 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_ROM_ADDR_3__opad_ROM_address -type pg_pin
connect_global_net POCCTRL_D7 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_ROM_ADDR_4__opad_ROM_address -type pg_pin
connect_global_net POCCTRL_D7 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_ROM_ADDR_5__opad_ROM_address -type pg_pin
connect_global_net POCCTRL_D7 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_ROM_ADDR_6__opad_ROM_address -type pg_pin
connect_global_net POCCTRL_D7 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_ROM_ADDR_7__opad_ROM_address -type pg_pin
connect_global_net POCCTRL_D7 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_ROM_ADDR_8__opad_ROM_address -type pg_pin
connect_global_net POCCTRL_D7 -netlist_override -override -pin_base_name POCCTRL -single_inst GEN_ROM_ADDR_9__opad_ROM_address -type pg_pin
connect_global_net POCCTRL_D7 -netlist_override -override -pin_base_name POCCTRL -single_inst CORE_VDD_LEVEL_01_PG4 -type pg_pin
connect_global_net POCCTRL_D7 -netlist_override -override -pin_base_name POCCTRL -single_inst AUTO_RTE_D7 -type pg_pin
connect_global_net POCCTRL_D7 -netlist_override -override -pin_base_name POCCTRL -single_inst IO_PG4 -type pg_pin
connect_global_net POCCTRL_D8 -netlist_override -override -pin_base_name POCCTRL -single_inst CORE_VDD_LEVEL_02_PG4 -type pg_pin
connect_global_net POCCTRL_D8 -netlist_override -override -pin_base_name POCCTRL -single_inst AUTO_RTE_D8 -type pg_pin
connect_global_net POCCTRL_D8 -netlist_override -override -pin_base_name POCCTRL -single_inst AUTO_IO_POWER_D8 -type pg_pin
connect_global_net VDD_LEVEL_02 -override -pin_base_name VDD -single_inst CORE_VDD_LEVEL_02_PG1 -type pg_pin
connect_global_net VDD_LEVEL_02 -override -pin_base_name VDD -single_inst CORE_VDD_LEVEL_02_PG1 -type pg_pin
connect_global_net VDD_LEVEL_02 -override -pin_base_name VDD -single_inst CORE_VDD_LEVEL_02_PG4 -type pg_pin
connect_global_net VDD_LEVEL_02 -override -pin_base_name VDD -single_inst CORE_VDD_LEVEL_02_PG4 -type pg_pin
connect_global_net VDD_LEVEL_02 -override -pin_base_name VDD -single_inst CORE_VDD_LEVEL_02_PG4 -type pg_pin
connect_global_net VDD_LEVEL_02 -override -pin_base_name VDD -single_inst CORE_VDD_LEVEL_02_PG3 -type pg_pin
connect_global_net VDD_LEVEL_02 -override -pin_base_name VDD -single_inst CORE_VDD_LEVEL_02_PG3 -type pg_pin
connect_global_net VDD_LEVEL_02 -override -pin_base_name VDD -single_inst CORE_VDD_LEVEL_02_PG3 -type pg_pin
connect_global_net VDD_LEVEL_02 -override -pin_base_name VDD -single_inst CORE_VDD_LEVEL_02_PG2 -type pg_pin
connect_global_net VDD_LEVEL_02 -override -pin_base_name VDD -single_inst CORE_VDD_LEVEL_02_PG2 -type pg_pin
connect_global_net VDD_LEVEL_02 -override -pin_base_name VDD -single_inst CORE_VDD_LEVEL_02_PG2 -type pg_pin
connect_global_net VDD_LEVEL_02 -override -pin_base_name VDD -single_inst AUTO_IO_POWER_D4 -type pg_pin
connect_global_net VDD_LEVEL_02 -override -pin_base_name VDD -single_inst AUTO_IO_POWER_D4 -type pg_pin
connect_global_net VDD_LEVEL_02 -override -pin_base_name VDD -single_inst AUTO_IO_POWER_D4 -type pg_pin
connect_global_net VDD_LEVEL_02 -override -pin_base_name VDD -single_inst AUTO_IO_POWER_D4 -type pg_pin
connect_global_net VDD_LEVEL_02 -override -pin_base_name VDD -single_inst AUTO_IO_POWER_D2 -type pg_pin
connect_global_net VDD_LEVEL_02 -override -pin_base_name VDD -single_inst AUTO_IO_POWER_D2 -type pg_pin
connect_global_net VDD_LEVEL_02 -override -pin_base_name VDD -single_inst AUTO_IO_POWER_D2 -type pg_pin
connect_global_net VDD_LEVEL_02 -override -pin_base_name VDD -single_inst AUTO_RTE_D4 -type pg_pin
connect_global_net VDD_LEVEL_02 -override -pin_base_name VDD -single_inst AUTO_RTE_D4 -type pg_pin
connect_global_net VDD_LEVEL_02 -override -pin_base_name VDD -single_inst AUTO_RTE_D4 -type pg_pin
connect_global_net VDD_LEVEL_02 -override -pin_base_name VDD -single_inst AUTO_RTE_D4 -type pg_pin
connect_global_net VDD_LEVEL_02 -override -pin_base_name VDD -single_inst AUTO_RTE_D4 -type pg_pin
connect_global_net VDD_LEVEL_02 -override -pin_base_name VDD -single_inst AUTO_RTE_D4 -type pg_pin
connect_global_net VDD_LEVEL_02 -override -pin_base_name VDD -single_inst AUTO_RTE_D4 -type pg_pin
connect_global_net VDD_LEVEL_02 -override -pin_base_name VDD -single_inst AUTO_RTE_D4 -type pg_pin
connect_global_net VDD_LEVEL_02 -override -pin_base_name VDD -single_inst AUTO_RTE_D4 -type pg_pin
connect_global_net VDD_LEVEL_02 -override -pin_base_name VDD -single_inst AUTO_RTE_D4 -type pg_pin
connect_global_net VDD_LEVEL_02 -override -pin_base_name VDD -single_inst AUTO_RTE_D4 -type pg_pin
connect_global_net VDD_LEVEL_02 -override -pin_base_name VDD -single_inst AUTO_RTE_D4 -type pg_pin
connect_global_net VDD_LEVEL_02 -override -pin_base_name VDD -single_inst AUTO_RTE_D4 -type pg_pin
connect_global_net VDD_LEVEL_02 -override -pin_base_name VDD -single_inst AUTO_RTE_D4 -type pg_pin
connect_global_net VDD_LEVEL_02 -override -pin_base_name VDD -single_inst AUTO_RTE_D4 -type pg_pin
connect_global_net VDD_LEVEL_02 -override -pin_base_name VDD -single_inst AUTO_RTE_D4 -type pg_pin
connect_global_net VDD_LEVEL_02 -override -pin_base_name VDD -single_inst pad_RTE_VDD_LEVEL_02 -type pg_pin
connect_global_net VDD_LEVEL_02 -override -pin_base_name VDD -single_inst AUTO_RTE_D8 -type pg_pin
connect_global_net VDD_LEVEL_02 -override -pin_base_name VDD -single_inst AUTO_IO_POWER_D8 -type pg_pin
connect_global_net VDD_LEVEL_02 -override -pin_base_name VDD -single_inst AUTO_IO_POWER_D6 -type pg_pin
connect_global_net VDD_LEVEL_02 -override -pin_base_name VDD -single_inst AUTO_RTE_D6 -type pg_pin
connect_global_net VDDPST_D1 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_v_ctrl_idx_0__opad_v_ctrl_idx -type pg_pin
connect_global_net VDDPST_D1 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_v_ctrl_idx_1__opad_v_ctrl_idx -type pg_pin
connect_global_net VDDPST_D1 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_v_ctrl_0__opad_v_ctrl -type pg_pin
connect_global_net VDDPST_D1 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_v_ctrl_1__opad_v_ctrl -type pg_pin
connect_global_net VDDPST_D1 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_DRAM_Q_0__ipad_DRAM_Q -type pg_pin
connect_global_net VDDPST_D1 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_DRAM_Q_1__ipad_DRAM_Q -type pg_pin
connect_global_net VDDPST_D1 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_DRAM_Q_2__ipad_DRAM_Q -type pg_pin
connect_global_net VDDPST_D1 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_DRAM_Q_3__ipad_DRAM_Q -type pg_pin
connect_global_net VDDPST_D1 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_DRAM_Q_4__ipad_DRAM_Q -type pg_pin
connect_global_net VDDPST_D1 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_DRAM_Q_5__ipad_DRAM_Q -type pg_pin
connect_global_net VDDPST_D1 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_DRAM_Q_6__ipad_DRAM_Q -type pg_pin
connect_global_net VDDPST_D1 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_DRAM_Q_7__ipad_DRAM_Q -type pg_pin
connect_global_net VDDPST_D1 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_DRAM_Q_8__ipad_DRAM_Q -type pg_pin
connect_global_net VDDPST_D1 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_DRAM_Q_9__ipad_DRAM_Q -type pg_pin
connect_global_net VDDPST_D1 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_DRAM_Q_10__ipad_DRAM_Q -type pg_pin
connect_global_net VDDPST_D1 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_DRAM_Q_11__ipad_DRAM_Q -type pg_pin
connect_global_net VDDPST_D1 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_DRAM_Q_12__ipad_DRAM_Q -type pg_pin
connect_global_net VDDPST_D1 -netlist_override -override -pin_base_name VDDPST -single_inst CORE_VDD_LEVEL_01_PG1 -type pg_pin
connect_global_net VDDPST_D1 -netlist_override -override -pin_base_name VDDPST -single_inst AUTO_RTE_D1 -type pg_pin
connect_global_net VDDPST_D1 -netlist_override -override -pin_base_name VDDPST -single_inst IO_PG1 -type pg_pin
connect_global_net VDDPST_D1 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_ROM_ADDR_10__opad_ROM_address -type pg_pin
connect_global_net VDDPST_D1 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_ROM_ADDR_11__opad_ROM_address -type pg_pin
connect_global_net VDDPST_D1 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_DRAM_WEN_0__opad_DRAM_WEn -type pg_pin
connect_global_net VDDPST_D1 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_DRAM_WEN_1__opad_DRAM_WEn -type pg_pin
connect_global_net VDDPST_D1 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_DRAM_WEN_2__opad_DRAM_WEn -type pg_pin
connect_global_net VDDPST_D1 -netlist_override -override -pin_base_name VDDPST -single_inst GEN_DRAM_WEN_3__opad_DRAM_WEn -type pg_pin
connect_global_net VDDPST_D1 -netlist_override -override -pin_base_name VDDPST -single_inst opad_ROM_read -type pg_pin
connect_global_net VDDPST_D1 -netlist_override -override -pin_base_name VDDPST -single_inst opad_ROM_enable -type pg_pin
connect_global_net VDDPST_D1 -netlist_override -override -pin_base_name VDDPST -single_inst opad_DRAM_CSn -type pg_pin
connect_global_net VDDPST_D1 -netlist_override -override -pin_base_name VDDPST -single_inst opad_DRAM_RASn -type pg_pin
connect_global_net VDDPST_D1 -netlist_override -override -pin_base_name VDDPST -single_inst opad_DRAM_CASn -type pg_pin
connect_global_net VDDPST_D1 -netlist_override -override -pin_base_name VDDPST -single_inst ipad_DRAM_valid -type pg_pin
connect_global_net VDDPST_D1 -netlist_override -override -pin_base_name VDDPST -single_inst ipad_cpu_clk -type pg_pin
connect_global_net VDDPST_D1 -netlist_override -override -pin_base_name VDDPST -single_inst ipad_axi_clk -type pg_pin
connect_global_net VDDPST_D1 -netlist_override -override -pin_base_name VDDPST -single_inst ipad_rom_clk -type pg_pin
connect_global_net VDDPST_D1 -netlist_override -override -pin_base_name VDDPST -single_inst ipad_dram_clk -type pg_pin
connect_global_net VDDPST_D1 -netlist_override -override -pin_base_name VDDPST -single_inst ipad_rom_rst -type pg_pin
connect_global_net VSSPST_D2 -netlist_override -override -pin_base_name VSSPST1 -single_inst RAILCUT_VDD_LEVEL_02_TOP1 -type pg_pin
connect_global_net VSSPST_D1 -netlist_override -override -pin_base_name VSSPST2 -single_inst RAILCUT_VDD_LEVEL_02_TOP1 -type pg_pin
connect_global_net VSSPST_D1 -netlist_override -override -pin_base_name VSSPST1 -single_inst RAILCUT_VDD_LEVEL_02_LEFT2 -type pg_pin
connect_global_net VSSPST_D8 -netlist_override -override -pin_base_name VSSPST2 -single_inst RAILCUT_VDD_LEVEL_02_LEFT2 -type pg_pin
connect_global_net VSSPST_D3 -netlist_override -override -pin_base_name VSSPST1 -single_inst RAILCUT_VDD_LEVEL_02_TOP2 -type pg_pin
connect_global_net VSSPST_D2 -netlist_override -override -pin_base_name VSSPST2 -single_inst RAILCUT_VDD_LEVEL_02_TOP2 -type pg_pin
connect_global_net VSSPST_D4 -netlist_override -override -pin_base_name VSSPST1 -single_inst RAILCUT_VDD_LEVEL_02_RIGHT2 -type pg_pin
connect_global_net VSSPST_D3 -netlist_override -override -pin_base_name VSSPST2 -single_inst RAILCUT_VDD_LEVEL_02_RIGHT2 -type pg_pin
connect_global_net VSSPST_D5 -netlist_override -override -pin_base_name VSSPST1 -single_inst RAILCUT_VDD_LEVEL_02_RIGHT1 -type pg_pin
connect_global_net VSSPST_D4 -netlist_override -override -pin_base_name VSSPST2 -single_inst RAILCUT_VDD_LEVEL_02_RIGHT1 -type pg_pin
connect_global_net VSSPST_D6 -netlist_override -override -pin_base_name VSSPST1 -single_inst RAILCUT_VDD_LEVEL_02_BOTTOM2 -type pg_pin
connect_global_net VSSPST_D5 -netlist_override -override -pin_base_name VSSPST2 -single_inst RAILCUT_VDD_LEVEL_02_BOTTOM2 -type pg_pin
connect_global_net VSSPST_D7 -netlist_override -override -pin_base_name VSSPST1 -single_inst RAILCUT_VDD_LEVEL_02_BOTTOM1 -type pg_pin
connect_global_net VSSPST_D6 -netlist_override -override -pin_base_name VSSPST2 -single_inst RAILCUT_VDD_LEVEL_02_BOTTOM1 -type pg_pin
connect_global_net VSSPST_D8 -netlist_override -override -pin_base_name VSSPST1 -single_inst RAILCUT_VDD_LEVEL_02_LEFT1 -type pg_pin
connect_global_net VSSPST_D7 -netlist_override -override -pin_base_name VSSPST2 -single_inst RAILCUT_VDD_LEVEL_02_LEFT1 -type pg_pin
# =============================================================================
# END EDIT BY TOOL
# =============================================================================
# >>> TECH_MV IOPAD GUI RTE PENDING TARGETS BEGIN (informational only, not executed - see connect_pin block generated fresh at Apply Global Net time)
# D1=RTE=RTE_D1
# D2=RTE=RTE_D2
# D3=RTE=RTE_D3
# D4=RTE=RTE_D4
# D5=RTE=RTE_D5
# D6=RTE=RTE_D6
# D7=RTE=RTE_D7
# D8=RTE=RTE_D8
# <<< TECH_MV IOPAD GUI RTE PENDING TARGETS END

# >>> TECH_MV IOPAD GUI MANAGED RTE CONNECTIVITY BEGIN
# Auto-generated by ioPADt V128.25.
# RTE is a SIGNAL pin: create_net/connect_pin, not connect_global_net.
# =============================================================
# V129 MANAGED RTE SIGNAL PATCH (connect_pin, not connect_global_net)
# V128.25: connectivity-only canonical-source form.
# dont_touch is emitted by its separate managed source block.
# =============================================================
if {[llength [get_db nets {RTE_D1}]] == 0} {
    create_net -name {RTE_D1}
    puts "INFO: RTE D1 created net RTE_D1"
}
connect_pin -inst {GEN_v_ctrl_idx_0__opad_v_ctrl_idx} -pin RTE -net {RTE_D1}
puts "INFO: RTE D1 GEN_v_ctrl_idx_0__opad_v_ctrl_idx.RTE -> RTE_D1 (connect_pin)"
connect_pin -inst {GEN_v_ctrl_idx_1__opad_v_ctrl_idx} -pin RTE -net {RTE_D1}
puts "INFO: RTE D1 GEN_v_ctrl_idx_1__opad_v_ctrl_idx.RTE -> RTE_D1 (connect_pin)"
connect_pin -inst {GEN_v_ctrl_0__opad_v_ctrl} -pin RTE -net {RTE_D1}
puts "INFO: RTE D1 GEN_v_ctrl_0__opad_v_ctrl.RTE -> RTE_D1 (connect_pin)"
connect_pin -inst {GEN_v_ctrl_1__opad_v_ctrl} -pin RTE -net {RTE_D1}
puts "INFO: RTE D1 GEN_v_ctrl_1__opad_v_ctrl.RTE -> RTE_D1 (connect_pin)"
connect_pin -inst {GEN_DRAM_Q_0__ipad_DRAM_Q} -pin RTE -net {RTE_D1}
puts "INFO: RTE D1 GEN_DRAM_Q_0__ipad_DRAM_Q.RTE -> RTE_D1 (connect_pin)"
connect_pin -inst {GEN_DRAM_Q_1__ipad_DRAM_Q} -pin RTE -net {RTE_D1}
puts "INFO: RTE D1 GEN_DRAM_Q_1__ipad_DRAM_Q.RTE -> RTE_D1 (connect_pin)"
connect_pin -inst {GEN_DRAM_Q_2__ipad_DRAM_Q} -pin RTE -net {RTE_D1}
puts "INFO: RTE D1 GEN_DRAM_Q_2__ipad_DRAM_Q.RTE -> RTE_D1 (connect_pin)"
connect_pin -inst {GEN_DRAM_Q_3__ipad_DRAM_Q} -pin RTE -net {RTE_D1}
puts "INFO: RTE D1 GEN_DRAM_Q_3__ipad_DRAM_Q.RTE -> RTE_D1 (connect_pin)"
connect_pin -inst {GEN_DRAM_Q_4__ipad_DRAM_Q} -pin RTE -net {RTE_D1}
puts "INFO: RTE D1 GEN_DRAM_Q_4__ipad_DRAM_Q.RTE -> RTE_D1 (connect_pin)"
connect_pin -inst {GEN_DRAM_Q_5__ipad_DRAM_Q} -pin RTE -net {RTE_D1}
puts "INFO: RTE D1 GEN_DRAM_Q_5__ipad_DRAM_Q.RTE -> RTE_D1 (connect_pin)"
connect_pin -inst {GEN_DRAM_Q_6__ipad_DRAM_Q} -pin RTE -net {RTE_D1}
puts "INFO: RTE D1 GEN_DRAM_Q_6__ipad_DRAM_Q.RTE -> RTE_D1 (connect_pin)"
connect_pin -inst {GEN_DRAM_Q_7__ipad_DRAM_Q} -pin RTE -net {RTE_D1}
puts "INFO: RTE D1 GEN_DRAM_Q_7__ipad_DRAM_Q.RTE -> RTE_D1 (connect_pin)"
connect_pin -inst {GEN_DRAM_Q_8__ipad_DRAM_Q} -pin RTE -net {RTE_D1}
puts "INFO: RTE D1 GEN_DRAM_Q_8__ipad_DRAM_Q.RTE -> RTE_D1 (connect_pin)"
connect_pin -inst {GEN_DRAM_Q_9__ipad_DRAM_Q} -pin RTE -net {RTE_D1}
puts "INFO: RTE D1 GEN_DRAM_Q_9__ipad_DRAM_Q.RTE -> RTE_D1 (connect_pin)"
connect_pin -inst {GEN_DRAM_Q_10__ipad_DRAM_Q} -pin RTE -net {RTE_D1}
puts "INFO: RTE D1 GEN_DRAM_Q_10__ipad_DRAM_Q.RTE -> RTE_D1 (connect_pin)"
connect_pin -inst {GEN_DRAM_Q_11__ipad_DRAM_Q} -pin RTE -net {RTE_D1}
puts "INFO: RTE D1 GEN_DRAM_Q_11__ipad_DRAM_Q.RTE -> RTE_D1 (connect_pin)"
connect_pin -inst {GEN_DRAM_Q_12__ipad_DRAM_Q} -pin RTE -net {RTE_D1}
puts "INFO: RTE D1 GEN_DRAM_Q_12__ipad_DRAM_Q.RTE -> RTE_D1 (connect_pin)"
connect_pin -inst {CORE_VDD_LEVEL_01_PG1} -pin RTE -net {RTE_D1}
puts "INFO: RTE D1 CORE_VDD_LEVEL_01_PG1.RTE -> RTE_D1 (connect_pin)"
connect_pin -inst {AUTO_RTE_D1} -pin RTE -net {RTE_D1}
puts "INFO: RTE D1 AUTO_RTE_D1.RTE -> RTE_D1 (connect_pin)"
connect_pin -inst {IO_PG1} -pin RTE -net {RTE_D1}
puts "INFO: RTE D1 IO_PG1.RTE -> RTE_D1 (connect_pin)"
connect_pin -inst {GEN_ROM_ADDR_10__opad_ROM_address} -pin RTE -net {RTE_D1}
puts "INFO: RTE D1 GEN_ROM_ADDR_10__opad_ROM_address.RTE -> RTE_D1 (connect_pin)"
connect_pin -inst {GEN_ROM_ADDR_11__opad_ROM_address} -pin RTE -net {RTE_D1}
puts "INFO: RTE D1 GEN_ROM_ADDR_11__opad_ROM_address.RTE -> RTE_D1 (connect_pin)"
connect_pin -inst {GEN_DRAM_WEN_0__opad_DRAM_WEn} -pin RTE -net {RTE_D1}
puts "INFO: RTE D1 GEN_DRAM_WEN_0__opad_DRAM_WEn.RTE -> RTE_D1 (connect_pin)"
connect_pin -inst {GEN_DRAM_WEN_1__opad_DRAM_WEn} -pin RTE -net {RTE_D1}
puts "INFO: RTE D1 GEN_DRAM_WEN_1__opad_DRAM_WEn.RTE -> RTE_D1 (connect_pin)"
connect_pin -inst {GEN_DRAM_WEN_2__opad_DRAM_WEn} -pin RTE -net {RTE_D1}
puts "INFO: RTE D1 GEN_DRAM_WEN_2__opad_DRAM_WEn.RTE -> RTE_D1 (connect_pin)"
connect_pin -inst {GEN_DRAM_WEN_3__opad_DRAM_WEn} -pin RTE -net {RTE_D1}
puts "INFO: RTE D1 GEN_DRAM_WEN_3__opad_DRAM_WEn.RTE -> RTE_D1 (connect_pin)"
connect_pin -inst {opad_ROM_read} -pin RTE -net {RTE_D1}
puts "INFO: RTE D1 opad_ROM_read.RTE -> RTE_D1 (connect_pin)"
connect_pin -inst {opad_ROM_enable} -pin RTE -net {RTE_D1}
puts "INFO: RTE D1 opad_ROM_enable.RTE -> RTE_D1 (connect_pin)"
connect_pin -inst {opad_DRAM_CSn} -pin RTE -net {RTE_D1}
puts "INFO: RTE D1 opad_DRAM_CSn.RTE -> RTE_D1 (connect_pin)"
connect_pin -inst {opad_DRAM_RASn} -pin RTE -net {RTE_D1}
puts "INFO: RTE D1 opad_DRAM_RASn.RTE -> RTE_D1 (connect_pin)"
connect_pin -inst {opad_DRAM_CASn} -pin RTE -net {RTE_D1}
puts "INFO: RTE D1 opad_DRAM_CASn.RTE -> RTE_D1 (connect_pin)"
connect_pin -inst {ipad_DRAM_valid} -pin RTE -net {RTE_D1}
puts "INFO: RTE D1 ipad_DRAM_valid.RTE -> RTE_D1 (connect_pin)"
connect_pin -inst {ipad_cpu_clk} -pin RTE -net {RTE_D1}
puts "INFO: RTE D1 ipad_cpu_clk.RTE -> RTE_D1 (connect_pin)"
connect_pin -inst {ipad_axi_clk} -pin RTE -net {RTE_D1}
puts "INFO: RTE D1 ipad_axi_clk.RTE -> RTE_D1 (connect_pin)"
connect_pin -inst {ipad_rom_clk} -pin RTE -net {RTE_D1}
puts "INFO: RTE D1 ipad_rom_clk.RTE -> RTE_D1 (connect_pin)"
connect_pin -inst {ipad_dram_clk} -pin RTE -net {RTE_D1}
puts "INFO: RTE D1 ipad_dram_clk.RTE -> RTE_D1 (connect_pin)"
connect_pin -inst {ipad_rom_rst} -pin RTE -net {RTE_D1}
puts "INFO: RTE D1 ipad_rom_rst.RTE -> RTE_D1 (connect_pin)"
if {[llength [get_db nets {RTE_D2}]] == 0} {
    create_net -name {RTE_D2}
    puts "INFO: RTE D2 created net RTE_D2"
}
connect_pin -inst {CORE_VDD_LEVEL_02_PG1} -pin RTE -net {RTE_D2}
puts "INFO: RTE D2 CORE_VDD_LEVEL_02_PG1.RTE -> RTE_D2 (connect_pin)"
connect_pin -inst {pad_RTE_VDD_LEVEL_02} -pin RTE -net {RTE_D2}
puts "INFO: RTE D2 pad_RTE_VDD_LEVEL_02.RTE -> RTE_D2 (connect_pin)"
connect_pin -inst {AUTO_IO_POWER_D2} -pin RTE -net {RTE_D2}
puts "INFO: RTE D2 AUTO_IO_POWER_D2.RTE -> RTE_D2 (connect_pin)"
if {[llength [get_db nets {RTE_D3}]] == 0} {
    create_net -name {RTE_D3}
    puts "INFO: RTE D3 created net RTE_D3"
}
connect_pin -inst {GEN_DRAM_Q_13__ipad_DRAM_Q} -pin RTE -net {RTE_D3}
puts "INFO: RTE D3 GEN_DRAM_Q_13__ipad_DRAM_Q.RTE -> RTE_D3 (connect_pin)"
connect_pin -inst {GEN_DRAM_Q_14__ipad_DRAM_Q} -pin RTE -net {RTE_D3}
puts "INFO: RTE D3 GEN_DRAM_Q_14__ipad_DRAM_Q.RTE -> RTE_D3 (connect_pin)"
connect_pin -inst {GEN_DRAM_Q_15__ipad_DRAM_Q} -pin RTE -net {RTE_D3}
puts "INFO: RTE D3 GEN_DRAM_Q_15__ipad_DRAM_Q.RTE -> RTE_D3 (connect_pin)"
connect_pin -inst {GEN_DRAM_Q_16__ipad_DRAM_Q} -pin RTE -net {RTE_D3}
puts "INFO: RTE D3 GEN_DRAM_Q_16__ipad_DRAM_Q.RTE -> RTE_D3 (connect_pin)"
connect_pin -inst {GEN_DRAM_Q_17__ipad_DRAM_Q} -pin RTE -net {RTE_D3}
puts "INFO: RTE D3 GEN_DRAM_Q_17__ipad_DRAM_Q.RTE -> RTE_D3 (connect_pin)"
connect_pin -inst {GEN_DRAM_Q_18__ipad_DRAM_Q} -pin RTE -net {RTE_D3}
puts "INFO: RTE D3 GEN_DRAM_Q_18__ipad_DRAM_Q.RTE -> RTE_D3 (connect_pin)"
connect_pin -inst {GEN_DRAM_Q_19__ipad_DRAM_Q} -pin RTE -net {RTE_D3}
puts "INFO: RTE D3 GEN_DRAM_Q_19__ipad_DRAM_Q.RTE -> RTE_D3 (connect_pin)"
connect_pin -inst {GEN_DRAM_Q_20__ipad_DRAM_Q} -pin RTE -net {RTE_D3}
puts "INFO: RTE D3 GEN_DRAM_Q_20__ipad_DRAM_Q.RTE -> RTE_D3 (connect_pin)"
connect_pin -inst {GEN_DRAM_Q_21__ipad_DRAM_Q} -pin RTE -net {RTE_D3}
puts "INFO: RTE D3 GEN_DRAM_Q_21__ipad_DRAM_Q.RTE -> RTE_D3 (connect_pin)"
connect_pin -inst {GEN_DRAM_Q_22__ipad_DRAM_Q} -pin RTE -net {RTE_D3}
puts "INFO: RTE D3 GEN_DRAM_Q_22__ipad_DRAM_Q.RTE -> RTE_D3 (connect_pin)"
connect_pin -inst {GEN_DRAM_Q_23__ipad_DRAM_Q} -pin RTE -net {RTE_D3}
puts "INFO: RTE D3 GEN_DRAM_Q_23__ipad_DRAM_Q.RTE -> RTE_D3 (connect_pin)"
connect_pin -inst {GEN_DRAM_Q_24__ipad_DRAM_Q} -pin RTE -net {RTE_D3}
puts "INFO: RTE D3 GEN_DRAM_Q_24__ipad_DRAM_Q.RTE -> RTE_D3 (connect_pin)"
connect_pin -inst {GEN_DRAM_Q_25__ipad_DRAM_Q} -pin RTE -net {RTE_D3}
puts "INFO: RTE D3 GEN_DRAM_Q_25__ipad_DRAM_Q.RTE -> RTE_D3 (connect_pin)"
connect_pin -inst {GEN_DRAM_Q_26__ipad_DRAM_Q} -pin RTE -net {RTE_D3}
puts "INFO: RTE D3 GEN_DRAM_Q_26__ipad_DRAM_Q.RTE -> RTE_D3 (connect_pin)"
connect_pin -inst {GEN_DRAM_Q_27__ipad_DRAM_Q} -pin RTE -net {RTE_D3}
puts "INFO: RTE D3 GEN_DRAM_Q_27__ipad_DRAM_Q.RTE -> RTE_D3 (connect_pin)"
connect_pin -inst {GEN_DRAM_Q_28__ipad_DRAM_Q} -pin RTE -net {RTE_D3}
puts "INFO: RTE D3 GEN_DRAM_Q_28__ipad_DRAM_Q.RTE -> RTE_D3 (connect_pin)"
connect_pin -inst {GEN_ROM_OUT_31__ipad_ROM_out} -pin RTE -net {RTE_D3}
puts "INFO: RTE D3 GEN_ROM_OUT_31__ipad_ROM_out.RTE -> RTE_D3 (connect_pin)"
connect_pin -inst {GEN_ROM_OUT_30__ipad_ROM_out} -pin RTE -net {RTE_D3}
puts "INFO: RTE D3 GEN_ROM_OUT_30__ipad_ROM_out.RTE -> RTE_D3 (connect_pin)"
connect_pin -inst {GEN_ROM_OUT_29__ipad_ROM_out} -pin RTE -net {RTE_D3}
puts "INFO: RTE D3 GEN_ROM_OUT_29__ipad_ROM_out.RTE -> RTE_D3 (connect_pin)"
connect_pin -inst {GEN_ROM_OUT_28__ipad_ROM_out} -pin RTE -net {RTE_D3}
puts "INFO: RTE D3 GEN_ROM_OUT_28__ipad_ROM_out.RTE -> RTE_D3 (connect_pin)"
connect_pin -inst {GEN_ROM_OUT_27__ipad_ROM_out} -pin RTE -net {RTE_D3}
puts "INFO: RTE D3 GEN_ROM_OUT_27__ipad_ROM_out.RTE -> RTE_D3 (connect_pin)"
connect_pin -inst {GEN_ROM_OUT_26__ipad_ROM_out} -pin RTE -net {RTE_D3}
puts "INFO: RTE D3 GEN_ROM_OUT_26__ipad_ROM_out.RTE -> RTE_D3 (connect_pin)"
connect_pin -inst {GEN_ROM_OUT_25__ipad_ROM_out} -pin RTE -net {RTE_D3}
puts "INFO: RTE D3 GEN_ROM_OUT_25__ipad_ROM_out.RTE -> RTE_D3 (connect_pin)"
connect_pin -inst {GEN_ROM_OUT_24__ipad_ROM_out} -pin RTE -net {RTE_D3}
puts "INFO: RTE D3 GEN_ROM_OUT_24__ipad_ROM_out.RTE -> RTE_D3 (connect_pin)"
connect_pin -inst {GEN_ROM_OUT_23__ipad_ROM_out} -pin RTE -net {RTE_D3}
puts "INFO: RTE D3 GEN_ROM_OUT_23__ipad_ROM_out.RTE -> RTE_D3 (connect_pin)"
connect_pin -inst {GEN_ROM_OUT_22__ipad_ROM_out} -pin RTE -net {RTE_D3}
puts "INFO: RTE D3 GEN_ROM_OUT_22__ipad_ROM_out.RTE -> RTE_D3 (connect_pin)"
connect_pin -inst {GEN_ROM_OUT_21__ipad_ROM_out} -pin RTE -net {RTE_D3}
puts "INFO: RTE D3 GEN_ROM_OUT_21__ipad_ROM_out.RTE -> RTE_D3 (connect_pin)"
connect_pin -inst {GEN_ROM_OUT_20__ipad_ROM_out} -pin RTE -net {RTE_D3}
puts "INFO: RTE D3 GEN_ROM_OUT_20__ipad_ROM_out.RTE -> RTE_D3 (connect_pin)"
connect_pin -inst {GEN_ROM_OUT_19__ipad_ROM_out} -pin RTE -net {RTE_D3}
puts "INFO: RTE D3 GEN_ROM_OUT_19__ipad_ROM_out.RTE -> RTE_D3 (connect_pin)"
connect_pin -inst {GEN_ROM_OUT_18__ipad_ROM_out} -pin RTE -net {RTE_D3}
puts "INFO: RTE D3 GEN_ROM_OUT_18__ipad_ROM_out.RTE -> RTE_D3 (connect_pin)"
connect_pin -inst {GEN_ROM_OUT_17__ipad_ROM_out} -pin RTE -net {RTE_D3}
puts "INFO: RTE D3 GEN_ROM_OUT_17__ipad_ROM_out.RTE -> RTE_D3 (connect_pin)"
connect_pin -inst {GEN_ROM_OUT_16__ipad_ROM_out} -pin RTE -net {RTE_D3}
puts "INFO: RTE D3 GEN_ROM_OUT_16__ipad_ROM_out.RTE -> RTE_D3 (connect_pin)"
connect_pin -inst {GEN_ROM_OUT_15__ipad_ROM_out} -pin RTE -net {RTE_D3}
puts "INFO: RTE D3 GEN_ROM_OUT_15__ipad_ROM_out.RTE -> RTE_D3 (connect_pin)"
connect_pin -inst {AUTO_IO_POWER_D3} -pin RTE -net {RTE_D3}
puts "INFO: RTE D3 AUTO_IO_POWER_D3.RTE -> RTE_D3 (connect_pin)"
connect_pin -inst {pad_RTE} -pin RTE -net {RTE_D3}
puts "INFO: RTE D3 pad_RTE.RTE -> RTE_D3 (connect_pin)"
connect_pin -inst {AUTO_CORE_POWER_D3} -pin RTE -net {RTE_D3}
puts "INFO: RTE D3 AUTO_CORE_POWER_D3.RTE -> RTE_D3 (connect_pin)"
if {[llength [get_db nets {RTE_D4}]] == 0} {
    create_net -name {RTE_D4}
    puts "INFO: RTE D4 created net RTE_D4"
}
connect_pin -inst {CORE_VDD_LEVEL_02_PG2} -pin RTE -net {RTE_D4}
puts "INFO: RTE D4 CORE_VDD_LEVEL_02_PG2.RTE -> RTE_D4 (connect_pin)"
connect_pin -inst {AUTO_RTE_D4} -pin RTE -net {RTE_D4}
puts "INFO: RTE D4 AUTO_RTE_D4.RTE -> RTE_D4 (connect_pin)"
connect_pin -inst {AUTO_IO_POWER_D4} -pin RTE -net {RTE_D4}
puts "INFO: RTE D4 AUTO_IO_POWER_D4.RTE -> RTE_D4 (connect_pin)"
if {[llength [get_db nets {RTE_D5}]] == 0} {
    create_net -name {RTE_D5}
    puts "INFO: RTE D5 created net RTE_D5"
}
connect_pin -inst {IO_PG2} -pin RTE -net {RTE_D5}
puts "INFO: RTE D5 IO_PG2.RTE -> RTE_D5 (connect_pin)"
connect_pin -inst {AUTO_RTE_D5} -pin RTE -net {RTE_D5}
puts "INFO: RTE D5 AUTO_RTE_D5.RTE -> RTE_D5 (connect_pin)"
connect_pin -inst {CORE_VDD_LEVEL_01_PG2} -pin RTE -net {RTE_D5}
puts "INFO: RTE D5 CORE_VDD_LEVEL_01_PG2.RTE -> RTE_D5 (connect_pin)"
connect_pin -inst {GEN_ROM_OUT_14__ipad_ROM_out} -pin RTE -net {RTE_D5}
puts "INFO: RTE D5 GEN_ROM_OUT_14__ipad_ROM_out.RTE -> RTE_D5 (connect_pin)"
connect_pin -inst {GEN_ROM_OUT_13__ipad_ROM_out} -pin RTE -net {RTE_D5}
puts "INFO: RTE D5 GEN_ROM_OUT_13__ipad_ROM_out.RTE -> RTE_D5 (connect_pin)"
connect_pin -inst {GEN_ROM_OUT_12__ipad_ROM_out} -pin RTE -net {RTE_D5}
puts "INFO: RTE D5 GEN_ROM_OUT_12__ipad_ROM_out.RTE -> RTE_D5 (connect_pin)"
connect_pin -inst {GEN_ROM_OUT_11__ipad_ROM_out} -pin RTE -net {RTE_D5}
puts "INFO: RTE D5 GEN_ROM_OUT_11__ipad_ROM_out.RTE -> RTE_D5 (connect_pin)"
connect_pin -inst {GEN_ROM_OUT_10__ipad_ROM_out} -pin RTE -net {RTE_D5}
puts "INFO: RTE D5 GEN_ROM_OUT_10__ipad_ROM_out.RTE -> RTE_D5 (connect_pin)"
connect_pin -inst {GEN_ROM_OUT_9__ipad_ROM_out} -pin RTE -net {RTE_D5}
puts "INFO: RTE D5 GEN_ROM_OUT_9__ipad_ROM_out.RTE -> RTE_D5 (connect_pin)"
connect_pin -inst {GEN_ROM_OUT_8__ipad_ROM_out} -pin RTE -net {RTE_D5}
puts "INFO: RTE D5 GEN_ROM_OUT_8__ipad_ROM_out.RTE -> RTE_D5 (connect_pin)"
connect_pin -inst {GEN_ROM_OUT_7__ipad_ROM_out} -pin RTE -net {RTE_D5}
puts "INFO: RTE D5 GEN_ROM_OUT_7__ipad_ROM_out.RTE -> RTE_D5 (connect_pin)"
connect_pin -inst {GEN_ROM_OUT_6__ipad_ROM_out} -pin RTE -net {RTE_D5}
puts "INFO: RTE D5 GEN_ROM_OUT_6__ipad_ROM_out.RTE -> RTE_D5 (connect_pin)"
connect_pin -inst {GEN_ROM_OUT_5__ipad_ROM_out} -pin RTE -net {RTE_D5}
puts "INFO: RTE D5 GEN_ROM_OUT_5__ipad_ROM_out.RTE -> RTE_D5 (connect_pin)"
connect_pin -inst {GEN_ROM_OUT_4__ipad_ROM_out} -pin RTE -net {RTE_D5}
puts "INFO: RTE D5 GEN_ROM_OUT_4__ipad_ROM_out.RTE -> RTE_D5 (connect_pin)"
connect_pin -inst {GEN_ROM_OUT_3__ipad_ROM_out} -pin RTE -net {RTE_D5}
puts "INFO: RTE D5 GEN_ROM_OUT_3__ipad_ROM_out.RTE -> RTE_D5 (connect_pin)"
connect_pin -inst {GEN_ROM_OUT_2__ipad_ROM_out} -pin RTE -net {RTE_D5}
puts "INFO: RTE D5 GEN_ROM_OUT_2__ipad_ROM_out.RTE -> RTE_D5 (connect_pin)"
connect_pin -inst {GEN_ROM_OUT_1__ipad_ROM_out} -pin RTE -net {RTE_D5}
puts "INFO: RTE D5 GEN_ROM_OUT_1__ipad_ROM_out.RTE -> RTE_D5 (connect_pin)"
connect_pin -inst {GEN_ROM_OUT_0__ipad_ROM_out} -pin RTE -net {RTE_D5}
puts "INFO: RTE D5 GEN_ROM_OUT_0__ipad_ROM_out.RTE -> RTE_D5 (connect_pin)"
connect_pin -inst {GEN_DRAM_Q_31__ipad_DRAM_Q} -pin RTE -net {RTE_D5}
puts "INFO: RTE D5 GEN_DRAM_Q_31__ipad_DRAM_Q.RTE -> RTE_D5 (connect_pin)"
connect_pin -inst {GEN_DRAM_Q_30__ipad_DRAM_Q} -pin RTE -net {RTE_D5}
puts "INFO: RTE D5 GEN_DRAM_Q_30__ipad_DRAM_Q.RTE -> RTE_D5 (connect_pin)"
connect_pin -inst {GEN_DRAM_Q_29__ipad_DRAM_Q} -pin RTE -net {RTE_D5}
puts "INFO: RTE D5 GEN_DRAM_Q_29__ipad_DRAM_Q.RTE -> RTE_D5 (connect_pin)"
connect_pin -inst {GEN_DRAM_A_2__opad_DRAM_A} -pin RTE -net {RTE_D5}
puts "INFO: RTE D5 GEN_DRAM_A_2__opad_DRAM_A.RTE -> RTE_D5 (connect_pin)"
connect_pin -inst {GEN_DRAM_A_1__opad_DRAM_A} -pin RTE -net {RTE_D5}
puts "INFO: RTE D5 GEN_DRAM_A_1__opad_DRAM_A.RTE -> RTE_D5 (connect_pin)"
connect_pin -inst {GEN_DRAM_A_0__opad_DRAM_A} -pin RTE -net {RTE_D5}
puts "INFO: RTE D5 GEN_DRAM_A_0__opad_DRAM_A.RTE -> RTE_D5 (connect_pin)"
connect_pin -inst {GEN_DRAM_D_31__opad_DRAM_D} -pin RTE -net {RTE_D5}
puts "INFO: RTE D5 GEN_DRAM_D_31__opad_DRAM_D.RTE -> RTE_D5 (connect_pin)"
connect_pin -inst {GEN_DRAM_D_30__opad_DRAM_D} -pin RTE -net {RTE_D5}
puts "INFO: RTE D5 GEN_DRAM_D_30__opad_DRAM_D.RTE -> RTE_D5 (connect_pin)"
connect_pin -inst {GEN_DRAM_D_29__opad_DRAM_D} -pin RTE -net {RTE_D5}
puts "INFO: RTE D5 GEN_DRAM_D_29__opad_DRAM_D.RTE -> RTE_D5 (connect_pin)"
connect_pin -inst {GEN_DRAM_D_28__opad_DRAM_D} -pin RTE -net {RTE_D5}
puts "INFO: RTE D5 GEN_DRAM_D_28__opad_DRAM_D.RTE -> RTE_D5 (connect_pin)"
connect_pin -inst {GEN_DRAM_D_27__opad_DRAM_D} -pin RTE -net {RTE_D5}
puts "INFO: RTE D5 GEN_DRAM_D_27__opad_DRAM_D.RTE -> RTE_D5 (connect_pin)"
connect_pin -inst {GEN_DRAM_D_26__opad_DRAM_D} -pin RTE -net {RTE_D5}
puts "INFO: RTE D5 GEN_DRAM_D_26__opad_DRAM_D.RTE -> RTE_D5 (connect_pin)"
connect_pin -inst {GEN_DRAM_D_25__opad_DRAM_D} -pin RTE -net {RTE_D5}
puts "INFO: RTE D5 GEN_DRAM_D_25__opad_DRAM_D.RTE -> RTE_D5 (connect_pin)"
connect_pin -inst {GEN_DRAM_D_24__opad_DRAM_D} -pin RTE -net {RTE_D5}
puts "INFO: RTE D5 GEN_DRAM_D_24__opad_DRAM_D.RTE -> RTE_D5 (connect_pin)"
connect_pin -inst {GEN_DRAM_D_23__opad_DRAM_D} -pin RTE -net {RTE_D5}
puts "INFO: RTE D5 GEN_DRAM_D_23__opad_DRAM_D.RTE -> RTE_D5 (connect_pin)"
connect_pin -inst {GEN_DRAM_D_22__opad_DRAM_D} -pin RTE -net {RTE_D5}
puts "INFO: RTE D5 GEN_DRAM_D_22__opad_DRAM_D.RTE -> RTE_D5 (connect_pin)"
connect_pin -inst {GEN_DRAM_D_21__opad_DRAM_D} -pin RTE -net {RTE_D5}
puts "INFO: RTE D5 GEN_DRAM_D_21__opad_DRAM_D.RTE -> RTE_D5 (connect_pin)"
connect_pin -inst {GEN_DRAM_D_20__opad_DRAM_D} -pin RTE -net {RTE_D5}
puts "INFO: RTE D5 GEN_DRAM_D_20__opad_DRAM_D.RTE -> RTE_D5 (connect_pin)"
connect_pin -inst {GEN_DRAM_D_19__opad_DRAM_D} -pin RTE -net {RTE_D5}
puts "INFO: RTE D5 GEN_DRAM_D_19__opad_DRAM_D.RTE -> RTE_D5 (connect_pin)"
connect_pin -inst {GEN_DRAM_D_18__opad_DRAM_D} -pin RTE -net {RTE_D5}
puts "INFO: RTE D5 GEN_DRAM_D_18__opad_DRAM_D.RTE -> RTE_D5 (connect_pin)"
if {[llength [get_db nets {RTE_D6}]] == 0} {
    create_net -name {RTE_D6}
    puts "INFO: RTE D6 created net RTE_D6"
}
connect_pin -inst {CORE_VDD_LEVEL_02_PG3} -pin RTE -net {RTE_D6}
puts "INFO: RTE D6 CORE_VDD_LEVEL_02_PG3.RTE -> RTE_D6 (connect_pin)"
connect_pin -inst {AUTO_RTE_D6} -pin RTE -net {RTE_D6}
puts "INFO: RTE D6 AUTO_RTE_D6.RTE -> RTE_D6 (connect_pin)"
connect_pin -inst {AUTO_IO_POWER_D6} -pin RTE -net {RTE_D6}
puts "INFO: RTE D6 AUTO_IO_POWER_D6.RTE -> RTE_D6 (connect_pin)"
if {[llength [get_db nets {RTE_D7}]] == 0} {
    create_net -name {RTE_D7}
    puts "INFO: RTE D7 created net RTE_D7"
}
connect_pin -inst {GEN_DRAM_D_17__opad_DRAM_D} -pin RTE -net {RTE_D7}
puts "INFO: RTE D7 GEN_DRAM_D_17__opad_DRAM_D.RTE -> RTE_D7 (connect_pin)"
connect_pin -inst {GEN_DRAM_D_16__opad_DRAM_D} -pin RTE -net {RTE_D7}
puts "INFO: RTE D7 GEN_DRAM_D_16__opad_DRAM_D.RTE -> RTE_D7 (connect_pin)"
connect_pin -inst {GEN_DRAM_D_15__opad_DRAM_D} -pin RTE -net {RTE_D7}
puts "INFO: RTE D7 GEN_DRAM_D_15__opad_DRAM_D.RTE -> RTE_D7 (connect_pin)"
connect_pin -inst {GEN_DRAM_D_14__opad_DRAM_D} -pin RTE -net {RTE_D7}
puts "INFO: RTE D7 GEN_DRAM_D_14__opad_DRAM_D.RTE -> RTE_D7 (connect_pin)"
connect_pin -inst {GEN_DRAM_D_13__opad_DRAM_D} -pin RTE -net {RTE_D7}
puts "INFO: RTE D7 GEN_DRAM_D_13__opad_DRAM_D.RTE -> RTE_D7 (connect_pin)"
connect_pin -inst {GEN_DRAM_D_12__opad_DRAM_D} -pin RTE -net {RTE_D7}
puts "INFO: RTE D7 GEN_DRAM_D_12__opad_DRAM_D.RTE -> RTE_D7 (connect_pin)"
connect_pin -inst {GEN_DRAM_D_11__opad_DRAM_D} -pin RTE -net {RTE_D7}
puts "INFO: RTE D7 GEN_DRAM_D_11__opad_DRAM_D.RTE -> RTE_D7 (connect_pin)"
connect_pin -inst {GEN_DRAM_D_10__opad_DRAM_D} -pin RTE -net {RTE_D7}
puts "INFO: RTE D7 GEN_DRAM_D_10__opad_DRAM_D.RTE -> RTE_D7 (connect_pin)"
connect_pin -inst {GEN_DRAM_D_9__opad_DRAM_D} -pin RTE -net {RTE_D7}
puts "INFO: RTE D7 GEN_DRAM_D_9__opad_DRAM_D.RTE -> RTE_D7 (connect_pin)"
connect_pin -inst {GEN_DRAM_D_8__opad_DRAM_D} -pin RTE -net {RTE_D7}
puts "INFO: RTE D7 GEN_DRAM_D_8__opad_DRAM_D.RTE -> RTE_D7 (connect_pin)"
connect_pin -inst {GEN_DRAM_D_7__opad_DRAM_D} -pin RTE -net {RTE_D7}
puts "INFO: RTE D7 GEN_DRAM_D_7__opad_DRAM_D.RTE -> RTE_D7 (connect_pin)"
connect_pin -inst {GEN_DRAM_D_6__opad_DRAM_D} -pin RTE -net {RTE_D7}
puts "INFO: RTE D7 GEN_DRAM_D_6__opad_DRAM_D.RTE -> RTE_D7 (connect_pin)"
connect_pin -inst {GEN_DRAM_D_5__opad_DRAM_D} -pin RTE -net {RTE_D7}
puts "INFO: RTE D7 GEN_DRAM_D_5__opad_DRAM_D.RTE -> RTE_D7 (connect_pin)"
connect_pin -inst {GEN_DRAM_D_4__opad_DRAM_D} -pin RTE -net {RTE_D7}
puts "INFO: RTE D7 GEN_DRAM_D_4__opad_DRAM_D.RTE -> RTE_D7 (connect_pin)"
connect_pin -inst {GEN_DRAM_D_3__opad_DRAM_D} -pin RTE -net {RTE_D7}
puts "INFO: RTE D7 GEN_DRAM_D_3__opad_DRAM_D.RTE -> RTE_D7 (connect_pin)"
connect_pin -inst {GEN_DRAM_D_2__opad_DRAM_D} -pin RTE -net {RTE_D7}
puts "INFO: RTE D7 GEN_DRAM_D_2__opad_DRAM_D.RTE -> RTE_D7 (connect_pin)"
connect_pin -inst {GEN_DRAM_D_1__opad_DRAM_D} -pin RTE -net {RTE_D7}
puts "INFO: RTE D7 GEN_DRAM_D_1__opad_DRAM_D.RTE -> RTE_D7 (connect_pin)"
connect_pin -inst {GEN_DRAM_D_0__opad_DRAM_D} -pin RTE -net {RTE_D7}
puts "INFO: RTE D7 GEN_DRAM_D_0__opad_DRAM_D.RTE -> RTE_D7 (connect_pin)"
connect_pin -inst {GEN_DRAM_A_3__opad_DRAM_A} -pin RTE -net {RTE_D7}
puts "INFO: RTE D7 GEN_DRAM_A_3__opad_DRAM_A.RTE -> RTE_D7 (connect_pin)"
connect_pin -inst {GEN_DRAM_A_4__opad_DRAM_A} -pin RTE -net {RTE_D7}
puts "INFO: RTE D7 GEN_DRAM_A_4__opad_DRAM_A.RTE -> RTE_D7 (connect_pin)"
connect_pin -inst {GEN_DRAM_A_5__opad_DRAM_A} -pin RTE -net {RTE_D7}
puts "INFO: RTE D7 GEN_DRAM_A_5__opad_DRAM_A.RTE -> RTE_D7 (connect_pin)"
connect_pin -inst {GEN_DRAM_A_6__opad_DRAM_A} -pin RTE -net {RTE_D7}
puts "INFO: RTE D7 GEN_DRAM_A_6__opad_DRAM_A.RTE -> RTE_D7 (connect_pin)"
connect_pin -inst {GEN_DRAM_A_7__opad_DRAM_A} -pin RTE -net {RTE_D7}
puts "INFO: RTE D7 GEN_DRAM_A_7__opad_DRAM_A.RTE -> RTE_D7 (connect_pin)"
connect_pin -inst {GEN_DRAM_A_8__opad_DRAM_A} -pin RTE -net {RTE_D7}
puts "INFO: RTE D7 GEN_DRAM_A_8__opad_DRAM_A.RTE -> RTE_D7 (connect_pin)"
connect_pin -inst {GEN_DRAM_A_9__opad_DRAM_A} -pin RTE -net {RTE_D7}
puts "INFO: RTE D7 GEN_DRAM_A_9__opad_DRAM_A.RTE -> RTE_D7 (connect_pin)"
connect_pin -inst {GEN_DRAM_A_10__opad_DRAM_A} -pin RTE -net {RTE_D7}
puts "INFO: RTE D7 GEN_DRAM_A_10__opad_DRAM_A.RTE -> RTE_D7 (connect_pin)"
connect_pin -inst {GEN_ROM_ADDR_0__opad_ROM_address} -pin RTE -net {RTE_D7}
puts "INFO: RTE D7 GEN_ROM_ADDR_0__opad_ROM_address.RTE -> RTE_D7 (connect_pin)"
connect_pin -inst {GEN_ROM_ADDR_1__opad_ROM_address} -pin RTE -net {RTE_D7}
puts "INFO: RTE D7 GEN_ROM_ADDR_1__opad_ROM_address.RTE -> RTE_D7 (connect_pin)"
connect_pin -inst {GEN_ROM_ADDR_2__opad_ROM_address} -pin RTE -net {RTE_D7}
puts "INFO: RTE D7 GEN_ROM_ADDR_2__opad_ROM_address.RTE -> RTE_D7 (connect_pin)"
connect_pin -inst {GEN_ROM_ADDR_3__opad_ROM_address} -pin RTE -net {RTE_D7}
puts "INFO: RTE D7 GEN_ROM_ADDR_3__opad_ROM_address.RTE -> RTE_D7 (connect_pin)"
connect_pin -inst {GEN_ROM_ADDR_4__opad_ROM_address} -pin RTE -net {RTE_D7}
puts "INFO: RTE D7 GEN_ROM_ADDR_4__opad_ROM_address.RTE -> RTE_D7 (connect_pin)"
connect_pin -inst {GEN_ROM_ADDR_5__opad_ROM_address} -pin RTE -net {RTE_D7}
puts "INFO: RTE D7 GEN_ROM_ADDR_5__opad_ROM_address.RTE -> RTE_D7 (connect_pin)"
connect_pin -inst {GEN_ROM_ADDR_6__opad_ROM_address} -pin RTE -net {RTE_D7}
puts "INFO: RTE D7 GEN_ROM_ADDR_6__opad_ROM_address.RTE -> RTE_D7 (connect_pin)"
connect_pin -inst {GEN_ROM_ADDR_7__opad_ROM_address} -pin RTE -net {RTE_D7}
puts "INFO: RTE D7 GEN_ROM_ADDR_7__opad_ROM_address.RTE -> RTE_D7 (connect_pin)"
connect_pin -inst {GEN_ROM_ADDR_8__opad_ROM_address} -pin RTE -net {RTE_D7}
puts "INFO: RTE D7 GEN_ROM_ADDR_8__opad_ROM_address.RTE -> RTE_D7 (connect_pin)"
connect_pin -inst {GEN_ROM_ADDR_9__opad_ROM_address} -pin RTE -net {RTE_D7}
puts "INFO: RTE D7 GEN_ROM_ADDR_9__opad_ROM_address.RTE -> RTE_D7 (connect_pin)"
connect_pin -inst {CORE_VDD_LEVEL_01_PG4} -pin RTE -net {RTE_D7}
puts "INFO: RTE D7 CORE_VDD_LEVEL_01_PG4.RTE -> RTE_D7 (connect_pin)"
connect_pin -inst {AUTO_RTE_D7} -pin RTE -net {RTE_D7}
puts "INFO: RTE D7 AUTO_RTE_D7.RTE -> RTE_D7 (connect_pin)"
connect_pin -inst {IO_PG4} -pin RTE -net {RTE_D7}
puts "INFO: RTE D7 IO_PG4.RTE -> RTE_D7 (connect_pin)"
if {[llength [get_db nets {RTE_D8}]] == 0} {
    create_net -name {RTE_D8}
    puts "INFO: RTE D8 created net RTE_D8"
}
connect_pin -inst {CORE_VDD_LEVEL_02_PG4} -pin RTE -net {RTE_D8}
puts "INFO: RTE D8 CORE_VDD_LEVEL_02_PG4.RTE -> RTE_D8 (connect_pin)"
connect_pin -inst {AUTO_RTE_D8} -pin RTE -net {RTE_D8}
puts "INFO: RTE D8 AUTO_RTE_D8.RTE -> RTE_D8 (connect_pin)"
connect_pin -inst {AUTO_IO_POWER_D8} -pin RTE -net {RTE_D8}
puts "INFO: RTE D8 AUTO_IO_POWER_D8.RTE -> RTE_D8 (connect_pin)"
# <<< TECH_MV IOPAD GUI MANAGED RTE CONNECTIVITY END

# >>> TECH_MV IOPAD GUI MANAGED RTE DONT_TOUCH BEGIN
# Auto-generated by ioPADt V128.24.
# RTE is an IO-ring SIGNAL network, not a PG global net.
# Preserve known RTE targets plus a live-DB RTE_D* fallback.
if {[llength [get_db nets {RTE_D1}]] == 1} {
    set_dont_touch [get_nets {RTE_D1}] true
    puts "INFO: global_net.tcl RTE ring net RTE_D1 dont_touch=true"
} else {
    puts "**WARN: global_net.tcl RTE ring net RTE_D1 missing/ambiguous; explicit dont_touch skipped"
}
if {[llength [get_db nets {RTE_D2}]] == 1} {
    set_dont_touch [get_nets {RTE_D2}] true
    puts "INFO: global_net.tcl RTE ring net RTE_D2 dont_touch=true"
} else {
    puts "**WARN: global_net.tcl RTE ring net RTE_D2 missing/ambiguous; explicit dont_touch skipped"
}
if {[llength [get_db nets {RTE_D3}]] == 1} {
    set_dont_touch [get_nets {RTE_D3}] true
    puts "INFO: global_net.tcl RTE ring net RTE_D3 dont_touch=true"
} else {
    puts "**WARN: global_net.tcl RTE ring net RTE_D3 missing/ambiguous; explicit dont_touch skipped"
}
if {[llength [get_db nets {RTE_D4}]] == 1} {
    set_dont_touch [get_nets {RTE_D4}] true
    puts "INFO: global_net.tcl RTE ring net RTE_D4 dont_touch=true"
} else {
    puts "**WARN: global_net.tcl RTE ring net RTE_D4 missing/ambiguous; explicit dont_touch skipped"
}
if {[llength [get_db nets {RTE_D5}]] == 1} {
    set_dont_touch [get_nets {RTE_D5}] true
    puts "INFO: global_net.tcl RTE ring net RTE_D5 dont_touch=true"
} else {
    puts "**WARN: global_net.tcl RTE ring net RTE_D5 missing/ambiguous; explicit dont_touch skipped"
}
if {[llength [get_db nets {RTE_D6}]] == 1} {
    set_dont_touch [get_nets {RTE_D6}] true
    puts "INFO: global_net.tcl RTE ring net RTE_D6 dont_touch=true"
} else {
    puts "**WARN: global_net.tcl RTE ring net RTE_D6 missing/ambiguous; explicit dont_touch skipped"
}
if {[llength [get_db nets {RTE_D7}]] == 1} {
    set_dont_touch [get_nets {RTE_D7}] true
    puts "INFO: global_net.tcl RTE ring net RTE_D7 dont_touch=true"
} else {
    puts "**WARN: global_net.tcl RTE ring net RTE_D7 missing/ambiguous; explicit dont_touch skipped"
}
if {[llength [get_db nets {RTE_D8}]] == 1} {
    set_dont_touch [get_nets {RTE_D8}] true
    puts "INFO: global_net.tcl RTE ring net RTE_D8 dont_touch=true"
} else {
    puts "**WARN: global_net.tcl RTE ring net RTE_D8 missing/ambiguous; explicit dont_touch skipped"
}
# V128.24 runtime RTE dont_touch fallback (live Innovus DB)
set TT_IOPAD_RTE_DONT_TOUCH_COUNT 0
foreach TT_IOPAD_RTE_NET_OBJ [get_db nets RTE_D*] {
    set TT_IOPAD_RTE_NET_NAME [get_db $TT_IOPAD_RTE_NET_OBJ .name]
    if {[llength [get_nets $TT_IOPAD_RTE_NET_NAME]] == 1} {
        set_dont_touch [get_nets $TT_IOPAD_RTE_NET_NAME] true
        incr TT_IOPAD_RTE_DONT_TOUCH_COUNT
        puts "INFO: ioPADt RTE dont_touch applied: $TT_IOPAD_RTE_NET_NAME"
    }
}
puts "INFO: ioPADt RTE dont_touch total=$TT_IOPAD_RTE_DONT_TOUCH_COUNT"
unset -nocomplain TT_IOPAD_RTE_NET_OBJ TT_IOPAD_RTE_NET_NAME TT_IOPAD_RTE_DONT_TOUCH_COUNT
# <<< TECH_MV IOPAD GUI MANAGED RTE DONT_TOUCH END

