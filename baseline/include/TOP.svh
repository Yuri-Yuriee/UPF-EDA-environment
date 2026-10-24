//`define spyglass
//`define syn
`define multi_clk
`define USE_FOUNDRY_DVFS_CELLS // DVFS
//`define test
`define Dual_MEM
`define interface_test
`define interface_En
`define cache
//`define test
`define WDT_PG
`define CPU_PG
`define UPF
`define single_reset
`define I_cache

`ifdef multi_clk
    `define CPU_CDC
`endif

`ifdef I_cache
`else
`define ibuf
`endif

`include "../include/AXI_define.svh"
`include "../include/CPU_define.svh"

// `ifdef interface_test
//     `ifdef interface_En
//         `include "../src/AXI/AXI_v2/AXI.sv"
//         `include "../src/AXI/AXI_v2/interface_define.sv"
//         `include "../src/AXI/arbitrator.sv"
//         `include "../src/AXI/AXI_v2/Cross_Bar2.sv"
//     `else
//         `include "../src/AXI/AXI_interface.sv"
//     `endif
// `else
//     `include "../src/AXI/AXI.sv"
// `endif

// `include "../src/CPU_wrapper.sv"
// `include "../src/SRAM_wrapper.sv"

// `ifdef spyglass
//     `include "../include/IP.svh"
//     `include "../include/CDC.svh"
//     `include "../include/AXI_define.svh"
// `elsif syn
//     `include "../include/IP.svh"
//     `include "../include/CDC.svh"
//     `include "../include/AXI_define.svh"
// `else
//     `include "./IP.svh"
//     `include "./CDC.svh"
//     `include "./AXI_define.svh"
// `endif

