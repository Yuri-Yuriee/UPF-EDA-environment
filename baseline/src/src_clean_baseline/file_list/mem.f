`ifdef Dual_MEM
	`include "/FILL_IN/FILL_IN_RESOURCE_0038"
	`include "/FILL_IN/FILL_IN_RESOURCE_0039"
	`include "/FILL_IN/FILL_IN_RESOURCE_0040"
`else 
	`include "SRAM/SRAM_rtl.sv"
	`include "data_array/data_array_rtl.sv"
	`include "tag_array/tag_array_rtl.sv"
`endif
	
