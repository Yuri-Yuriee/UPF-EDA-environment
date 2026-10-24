#spyglass shell source tcl code
#In the Spyglass shell type "source ../script/Spyglass_CDC.tcl" to execute script

#import design
read_file -type sgdc "../script/spyglass/SDC2SGDC/output/GEN.sgdc ../script/spyglass/system/setup.sgdc"
read_file -type sourcelist ../src/src_clean_baseline/file_list/rtl_spyglass.f

# read_file -type verilog { \
# /FILL_IN/FILL_IN_RESOURCE_0196 \
# /FILL_IN/FILL_IN_RESOURCE_0197 \
# /FILL_IN/FILL_IN_RESOURCE_0198 \
# }
read_file -type sglib ../script/spyglass/sglib/design.sglib

set_option enableSV09 yes
set_option enableSV yes
set_option mthresh 8192
#set_option stop {FILL_IN_CELL_SRAM_002 FILL_IN_CELL_SRAM_001 FILL_IN_CELL_SRAM_006 FILL_IN_CELL_ICG_009 FILL_IN_CELL_CLOCK_MUX_008 FILL_IN_CELL_RTE_BOUNDARY_PAD_013 FILL_IN_CELL_IO_POWER_PAD_014 FILL_IN_CELL_DIGITAL_IO_PAD_015 FILL_IN_CELL_DIGITAL_IO_PAD_016 FILL_IN_CELL_DFF_ASYNC_SET_RESET_010 FILL_IN_CELL_DELAY_011}


#set_option ignoredu {tag_array data_array SRAM}
set_option incdir {../include ../src ../sim ../sim/IP ../tech ../tech/memory/sim/SRAM}



#read design
current_goal Design_Read -alltop
link_design -force

#start CDC verification
current_goal cdc/cdc_setup_check -alltop
run_goal

current_goal cdc/clock_reset_integrity -alltop
run_goal

current_goal cdc/cdc_verify_struct -alltop
run_goal

current_goal cdc/cdc_verify -alltop
run_goal

current_goal cdc/cdc_abstrast -alltop
run_goal