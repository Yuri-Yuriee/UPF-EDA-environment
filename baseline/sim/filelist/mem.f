`ifdef Dual_MEM
	`include "memory/imported/86b29aa9068f/FILL_IN_LIBRARY_0052"
	`include "memory/imported/126396dfc54e/FILL_IN_LIBRARY_0053"
	`include "memory/imported/f17fe61f7c2a/FILL_IN_LIBRARY_0054"
`else 
	`include "memory/sim/SRAM/SRAM_rtl.sv"
	`include "memory/sim/data_array/data_array_rtl.sv"
	`include "memory/sim/tag_array/tag_array_rtl.sv"
`endif
	
