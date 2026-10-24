#spyglass shell source tcl code
#In the Spyglass shell type "source ../script/Spyglass_CDC.tcl" to execute script

#import design
read_file -type sgdc "../script/spyglass/FIFO/Spyglass.sgdc"
read_file -type sourcelist ../src/FIFO_TU/file_list/rtl.f

set_option enableSV09 yes
set_option enableSV yes
set_option mthresh 8192
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

