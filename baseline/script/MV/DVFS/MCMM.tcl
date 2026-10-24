############################################################
# dvfs_mcmm.tcl
############################################################
# Only for DVFS 4-state MCMM scenario setup
#
# DVFS states:
#   state0 : CPU 0.9V
#   state1 : CPU 0.72V
#   state2 : CPU 0.675V
#   state3 : CPU 0.5V
#
# Library setup is already done in setup.tcl.
############################################################


############################################################
# 1. Scenario / State Names
############################################################

set DVFS_STATE0 s_cpu_LEVEL_03
set DVFS_STATE1 s_cpu_LEVEL_04
set DVFS_STATE2 s_cpu_LEVEL_05
set DVFS_STATE3 s_cpu_LEVEL_06


############################################################
# 2. SDC Files
############################################################

set SDC_STATE0 s_cpu_LEVEL_03.sdc
set SDC_STATE1 s_cpu_LEVEL_04.sdc
set SDC_STATE2 s_cpu_LEVEL_05.sdc
set SDC_STATE3 s_cpu_LEVEL_06.sdc


############################################################
# 3. TLU+ / RC Setup
############################################################

if {![info exists MAX_TLU]} {
    set MAX_TLU "design.tlup"
}

if {![info exists MIN_TLU]} {
    set MIN_TLU "design.tlup"
}


############################################################
# 4. Operating Condition Names
############################################################

set OC_LEVEL_03    ssgnp0p9vm40c
set OC_LEVEL_04   ssgnp0p72vm40c
set OC_LEVEL_05  ssgnp0p675vm40c
set OC_LEVEL_06    ssgnp0p5vm40c

set OC_IO_LEVEL_04  ssgnp0p72v1p62vm40c
set OC_MEM_LEVEL_04 ssgnp0p72v0p72vm40c

set OC_LVL_LEVEL_06_TO_LEVEL_04 ssgnp0p5v0p72vm40c
set OC_LVL_LEVEL_04_TO_LEVEL_06 ssgnp0p72v0p5vm40c

set OC_PM_LEVEL_04 ssgnp0p72vm40c
set OC_PM_LEVEL_06  ssgnp0p5vm40c

set SYS_OC [set OC_$SYS_VOLTAGE]


############################################################
# DVFS STATE0 : CPU 0.9V
############################################################

create_scenario $DVFS_STATE0

# CPU 0.9V
set_operating_conditions $OC_LEVEL_03 \
    -library $LIB_SVT_LEVEL_03:[file rootname $LIB_SVT_LEVEL_03]

set_operating_conditions $OC_LEVEL_03 \
    -library $LIB_LVT_LEVEL_03:[file rootname $LIB_LVT_LEVEL_03]

set_operating_conditions $OC_LEVEL_03 \
    -library $LIB_ULVT_LEVEL_03:[file rootname $LIB_ULVT_LEVEL_03]

# SYS fixed by setup.tcl option
foreach lib $SYS_CORE_LIB_SELECTED {
    set_operating_conditions $SYS_OC \
        -library $lib:[file rootname $lib]
}

# IO / SRAM
set_operating_conditions $OC_IO_LEVEL_04 \
    -library $LIB_IO_LEVEL_04:[file rootname $LIB_IO_LEVEL_04]

foreach lib $LIB_MEM_LEVEL_04 {
    set_operating_conditions $OC_MEM_LEVEL_04 \
        -library $lib:[file rootname $lib]
}

# Level shifter / Power switch
set_operating_conditions $OC_LVL_LEVEL_06_TO_LEVEL_04 \
    -library $LIB_LVL_LEVEL_06_TO_LEVEL_04:[file rootname $LIB_LVL_LEVEL_06_TO_LEVEL_04]

set_operating_conditions $OC_LVL_LEVEL_04_TO_LEVEL_06 \
    -library $LIB_LVL_LEVEL_04_TO_LEVEL_06:[file rootname $LIB_LVL_LEVEL_04_TO_LEVEL_06]

set_operating_conditions $OC_PM_LEVEL_04 \
    -library $LIB_PM_LEVEL_04:[file rootname $LIB_PM_LEVEL_04]

set_operating_conditions $OC_PM_LEVEL_06 \
    -library $LIB_PM_LEVEL_06:[file rootname $LIB_PM_LEVEL_06]

set_tlu_plus_files \
    -max_tluplus $MAX_TLU \
    -min_tluplus $MIN_TLU \
    -tech2itf_map $MAP_FILE

read_sdc $SDC_STATE0

set_scenario_options \
    -scenarios $DVFS_STATE0 \
    -setup true \
    -hold true \
    -leakage_power true


############################################################
# DVFS STATE1 : CPU 0.72V
############################################################

create_scenario $DVFS_STATE1

# CPU 0.72V
set_operating_conditions $OC_LEVEL_04 \
    -library $LIB_SVT_LEVEL_04:[file rootname $LIB_SVT_LEVEL_04]

set_operating_conditions $OC_LEVEL_04 \
    -library $LIB_LVT_LEVEL_04:[file rootname $LIB_LVT_LEVEL_04]

set_operating_conditions $OC_LEVEL_04 \
    -library $LIB_ULVT_LEVEL_04:[file rootname $LIB_ULVT_LEVEL_04]

# SYS fixed by setup.tcl option
foreach lib $SYS_CORE_LIB_SELECTED {
    set_operating_conditions $SYS_OC \
        -library $lib:[file rootname $lib]
}

# IO / SRAM
set_operating_conditions $OC_IO_LEVEL_04 \
    -library $LIB_IO_LEVEL_04:[file rootname $LIB_IO_LEVEL_04]

foreach lib $LIB_MEM_LEVEL_04 {
    set_operating_conditions $OC_MEM_LEVEL_04 \
        -library $lib:[file rootname $lib]
}

# Level shifter / Power switch
set_operating_conditions $OC_LVL_LEVEL_06_TO_LEVEL_04 \
    -library $LIB_LVL_LEVEL_06_TO_LEVEL_04:[file rootname $LIB_LVL_LEVEL_06_TO_LEVEL_04]

set_operating_conditions $OC_LVL_LEVEL_04_TO_LEVEL_06 \
    -library $LIB_LVL_LEVEL_04_TO_LEVEL_06:[file rootname $LIB_LVL_LEVEL_04_TO_LEVEL_06]

set_operating_conditions $OC_PM_LEVEL_04 \
    -library $LIB_PM_LEVEL_04:[file rootname $LIB_PM_LEVEL_04]

set_operating_conditions $OC_PM_LEVEL_06 \
    -library $LIB_PM_LEVEL_06:[file rootname $LIB_PM_LEVEL_06]

set_tlu_plus_files \
    -max_tluplus $MAX_TLU \
    -min_tluplus $MIN_TLU \
    -tech2itf_map $MAP_FILE

read_sdc $SDC_STATE1

set_scenario_options \
    -scenarios $DVFS_STATE1 \
    -setup true \
    -hold true \
    -leakage_power true


############################################################
# DVFS STATE2 : CPU 0.675V
############################################################

create_scenario $DVFS_STATE2

# CPU 0.675V
set_operating_conditions $OC_LEVEL_05 \
    -library $LIB_SVT_LEVEL_05:[file rootname $LIB_SVT_LEVEL_05]

set_operating_conditions $OC_LEVEL_05 \
    -library $LIB_LVT_LEVEL_05:[file rootname $LIB_LVT_LEVEL_05]

set_operating_conditions $OC_LEVEL_05 \
    -library $LIB_ULVT_LEVEL_05:[file rootname $LIB_ULVT_LEVEL_05]

# SYS fixed by setup.tcl option
foreach lib $SYS_CORE_LIB_SELECTED {
    set_operating_conditions $SYS_OC \
        -library $lib:[file rootname $lib]
}

# IO / SRAM
set_operating_conditions $OC_IO_LEVEL_04 \
    -library $LIB_IO_LEVEL_04:[file rootname $LIB_IO_LEVEL_04]

foreach lib $LIB_MEM_LEVEL_04 {
    set_operating_conditions $OC_MEM_LEVEL_04 \
        -library $lib:[file rootname $lib]
}

# Level shifter / Power switch
set_operating_conditions $OC_LVL_LEVEL_06_TO_LEVEL_04 \
    -library $LIB_LVL_LEVEL_06_TO_LEVEL_04:[file rootname $LIB_LVL_LEVEL_06_TO_LEVEL_04]

set_operating_conditions $OC_LVL_LEVEL_04_TO_LEVEL_06 \
    -library $LIB_LVL_LEVEL_04_TO_LEVEL_06:[file rootname $LIB_LVL_LEVEL_04_TO_LEVEL_06]

set_operating_conditions $OC_PM_LEVEL_04 \
    -library $LIB_PM_LEVEL_04:[file rootname $LIB_PM_LEVEL_04]

set_operating_conditions $OC_PM_LEVEL_06 \
    -library $LIB_PM_LEVEL_06:[file rootname $LIB_PM_LEVEL_06]

set_tlu_plus_files \
    -max_tluplus $MAX_TLU \
    -min_tluplus $MIN_TLU \
    -tech2itf_map $MAP_FILE

read_sdc $SDC_STATE2

set_scenario_options \
    -scenarios $DVFS_STATE2 \
    -setup true \
    -hold true \
    -leakage_power true


############################################################
# DVFS STATE3 : CPU 0.5V
############################################################

create_scenario $DVFS_STATE3

# CPU 0.5V
set_operating_conditions $OC_LEVEL_06 \
    -library $LIB_SVT_LEVEL_06:[file rootname $LIB_SVT_LEVEL_06]

set_operating_conditions $OC_LEVEL_06 \
    -library $LIB_LVT_LEVEL_06:[file rootname $LIB_LVT_LEVEL_06]

set_operating_conditions $OC_LEVEL_06 \
    -library $LIB_ULVT_LEVEL_06:[file rootname $LIB_ULVT_LEVEL_06]

# SYS fixed by setup.tcl option
foreach lib $SYS_CORE_LIB_SELECTED {
    set_operating_conditions $SYS_OC \
        -library $lib:[file rootname $lib]
}

# IO / SRAM
set_operating_conditions $OC_IO_LEVEL_04 \
    -library $LIB_IO_LEVEL_04:[file rootname $LIB_IO_LEVEL_04]

foreach lib $LIB_MEM_LEVEL_04 {
    set_operating_conditions $OC_MEM_LEVEL_04 \
        -library $lib:[file rootname $lib]
}

# Level shifter / Power switch
set_operating_conditions $OC_LVL_LEVEL_06_TO_LEVEL_04 \
    -library $LIB_LVL_LEVEL_06_TO_LEVEL_04:[file rootname $LIB_LVL_LEVEL_06_TO_LEVEL_04]

set_operating_conditions $OC_LVL_LEVEL_04_TO_LEVEL_06 \
    -library $LIB_LVL_LEVEL_04_TO_LEVEL_06:[file rootname $LIB_LVL_LEVEL_04_TO_LEVEL_06]

set_operating_conditions $OC_PM_LEVEL_04 \
    -library $LIB_PM_LEVEL_04:[file rootname $LIB_PM_LEVEL_04]

set_operating_conditions $OC_PM_LEVEL_06 \
    -library $LIB_PM_LEVEL_06:[file rootname $LIB_PM_LEVEL_06]

set_tlu_plus_files \
    -max_tluplus $MAX_TLU \
    -min_tluplus $MIN_TLU \
    -tech2itf_map $MAP_FILE

read_sdc $SDC_STATE3

set_scenario_options \
    -scenarios $DVFS_STATE3 \
    -setup true \
    -hold true \
    -leakage_power true


############################################################
# Active Scenarios
############################################################

set_active_scenarios [list \
    $DVFS_STATE0 \
    $DVFS_STATE1 \
    $DVFS_STATE2 \
    $DVFS_STATE3 \
]

report_scenarios