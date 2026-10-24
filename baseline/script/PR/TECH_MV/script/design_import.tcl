puts "User script [info script]"

read_mmmc $MMMC_FILE
read_physical -lef $LEF_FILES
read_netlist -top $TOP_MODULE $NETLIST_FILE
read_power_intent -1801 $UPF_FILE
init_design
