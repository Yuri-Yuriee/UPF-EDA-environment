`ifdef UPF
    `ifdef SYN
    `include "CHIP_syn.v"
    `timescale 1ns/10ps
    //SVT
    `include "/FILL_IN/FILL_IN_RESOURCE_0043"
    //LVT
    `include "/FILL_IN/FILL_IN_RESOURCE_0044"
    //ULVT
    `include "/FILL_IN/FILL_IN_RESOURCE_0045"
    //IO
    `include "/FILL_IN/FILL_IN_RESOURCE_0046"
    //PM
    `include "/FILL_IN/FILL_IN_RESOURCE_0047"
    //LVL
    `include "/FILL_IN/FILL_IN_RESOURCE_0048"
    
    `elsif PR
    `include "../APR_new/innovus_stylus/APR/outputs/CHIP_pr.v"
    // `include "../pr/CHIP_pr.v"
    `timescale 1ns/10ps
    //`include "/FILL_IN/FILL_IN_RESOURCE_0049"
    //`include "/FILL_IN/FILL_IN_RESOURCE_0050"
    `include "/FILL_IN/FILL_IN_RESOURCE_0043"
    `include "/FILL_IN/FILL_IN_RESOURCE_0046"


    `else
        `include "/FILL_IN/FILL_IN_RESOURCE_0046"
        `ifdef USE_FOUNDRY_DVFS_CELLS
                `include "/FILL_IN/FILL_IN_RESOURCE_0043"
        `endif
    `endif
`else
    `ifdef SYN
    `timescale 1ns/10ps
    `include "/FILL_IN/FILL_IN_RESOURCE_0043"
    `include "/FILL_IN/FILL_IN_RESOURCE_0046"

    `elsif PR
    // `include "../pr/CHIP_pr.v"
    `timescale 1ns/10ps
    //`include "/FILL_IN/FILL_IN_RESOURCE_0004"
    //`include "/FILL_IN/FILL_IN_RESOURCE_0051"
    `include "/FILL_IN/FILL_IN_RESOURCE_0043"
    `include "/FILL_IN/FILL_IN_RESOURCE_0046"
    `else
    `include "CHIP.v"
    `include "/FILL_IN/FILL_IN_RESOURCE_0046"
        `ifdef USE_FOUNDRY_DVFS_CELLS
            `include "/FILL_IN/FILL_IN_RESOURCE_0043"
        `endif
    `endif
`endif