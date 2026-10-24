#spyglass shell source tcl code
#In the Spyglass shell type "source ../script/Spyglass_CDC.tcl" to execute script

#import design
read_file -type sgdc "../script/spyglass/FIFO/Spyglass.sgdc"
read_file -type sourcelist ../src/FIFO_TU/file_list/rtl.f

set_option enableSV09 yes
set_option enableSV yes
set_option mthresh 8192
set_option incdir {../include ../src ../sim ../sim/IP ../tech ../tech/memory/sim/SRAM}
set_parameter  rdc_skip_resetless_flop 1
set_parameter report_all_reset_cross yes


#read design
current_goal Design_Read -alltop
link_design -force

#start RDC verification
current_goal rdc/rdc_verify_struct -alltop 
run_goal 

