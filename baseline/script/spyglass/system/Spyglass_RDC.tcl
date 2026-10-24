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
set_parameter  rdc_skip_resetless_flop 1

set_option stop {FILL_IN_CELL_SRAM_002 FILL_IN_CELL_SRAM_001 FILL_IN_CELL_SRAM_006}


#set_option ignoredu {tag_array data_array SRAM}
set_option incdir {../include ../src ../sim ../sim/IP ../tech ../tech/memory/sim/SRAM}



#read design
current_goal Design_Read -alltop
link_design -force

#start RDC verification
current_goal rdc/rdc_verify_struct -alltop 
set_parameter  rdc_skip_resetless_flop 1
set_goal_option addrules {Ar_resetcross01}
set_parameter report_all_reset_cross yes
set_parameter rdc_skip_resetless_flop 1
run_goal 




