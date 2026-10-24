interface axi_read_if;

    // ---------------------------------------------
    // Slave Port Signals (Your first block)
    // ---------------------------------------------
    logic [`AXI_ID_BITS-1:0]   ARID_s;
    logic [`AXI_ADDR_BITS-1:0] ARADDR_s;
    logic [`AXI_LEN_BITS-1:0]  ARLEN_s;
    logic [`AXI_SIZE_BITS-1:0] ARSIZE_s;
    logic [1:0]               ARBURST_s;
    logic                     ARVALID_s;
    logic                     ARREADY_s;

    logic [`AXI_ID_BITS-1:0]   RID_s;
    logic [`AXI_DATA_BITS-1:0] RDATA_s;
    logic [1:0]               RRESP_s;
    logic                     RLAST_s;
    logic                     RVALID_s;
    logic                     RREADY_s;

    // ---------------------------------------------
    // Master Port Signals (Your second block)
    // ---------------------------------------------
    logic [`AXI_IDS_BITS-1:0]   ARID_m;
    logic [`AXI_ADDR_BITS-1:0]  ARADDR_m;
    logic [`AXI_LEN_BITS-1:0]   ARLEN_m;
    logic [`AXI_SIZE_BITS-1:0]  ARSIZE_m;
    logic [1:0]                ARBURST_m;
    logic                      ARVALID_m;
    logic                      ARREADY_m;

    logic [`AXI_IDS_BITS-1:0]   RID_m;
    logic [`AXI_DATA_BITS-1:0]  RDATA_m;
    logic [1:0]                RRESP_m;
    logic                      RLAST_m;
    logic                      RVALID_m;
    logic                      RREADY_m;

    // ======================
    // READ channel tie-off
    // ======================
    // generate
    //     if (!READ_ENABLE) begin
    //         // Master side tie-off
    //         assign ARID_m    = '0;
    //         assign ARADDR_m  = '0;
    //         assign ARLEN_m   = '0;
    //         assign ARSIZE_m  = '0;
    //         assign ARBURST_m = '0;
    //         assign ARVALID_m = 1'b0;
    //         assign RREADY_m  = 1'b0;

    //         // Slave side tie-off (避免 driver conflict)
    //         assign ARREADY_s = 1'b0;
    //         assign RID_s     = '0;
    //         assign RDATA_s   = '0;
    //         assign RRESP_s   = '0;
    //         assign RLAST_s   = 1'b0;
    //         assign RVALID_s  = 1'b0;
    //     end
    // endgenerate



    // ---------------------------------------------
    // modport definitions
    // ---------------------------------------------
    // Slave device receives address, returns data
    modport slave (
        // Address
        input  ARID_s, ARADDR_s, ARLEN_s, ARSIZE_s, ARBURST_s, ARVALID_s,
        output ARREADY_s,

        // Data return
        output RID_s, RDATA_s, RRESP_s, RLAST_s, RVALID_s,
        input  RREADY_s
    );

    modport bus_slave (
        // Address
        output ARID_s, ARADDR_s, ARLEN_s, ARSIZE_s, ARBURST_s, ARVALID_s,
        input ARREADY_s,

        // Data return
        input RID_s, RDATA_s, RRESP_s, RLAST_s, RVALID_s,
        output  RREADY_s
    );

    // Master generates address, receives data
    modport master (
        // Address
        output ARID_m, ARADDR_m, ARLEN_m, ARSIZE_m, ARBURST_m, ARVALID_m,
        input  ARREADY_m,

        // Data
        input  RID_m, RDATA_m, RRESP_m, RLAST_m, RVALID_m,
        output RREADY_m
    );

    modport bus_master (
        // Address
        input ARID_m, ARADDR_m, ARLEN_m, ARSIZE_m, ARBURST_m, ARVALID_m,
        output  ARREADY_m,

        // Data
        output  RID_m, RDATA_m, RRESP_m, RLAST_m, RVALID_m,
        input RREADY_m
    );

endinterface

interface axi_write_if;

    // ---------------------------------------------
    // Slave Port Signals
    // ---------------------------------------------
    logic [`AXI_ID_BITS-1:0]   AWID_s;
    logic [`AXI_ADDR_BITS-1:0] AWADDR_s;
    logic [`AXI_LEN_BITS-1:0]  AWLEN_s;
    logic [`AXI_SIZE_BITS-1:0] AWSIZE_s;
    logic [1:0]               AWBURST_s;
    logic                     AWVALID_s;
    logic                     AWREADY_s;

    logic [`AXI_DATA_BITS-1:0] WDATA_s;
    logic [`AXI_STRB_BITS-1:0] WSTRB_s;
    logic                     WLAST_s;
    logic                     WVALID_s;
    logic                     WREADY_s;

    logic [`AXI_ID_BITS-1:0]   BID_s;
    logic [1:0]               BRESP_s;
    logic                     BVALID_s;
    logic                     BREADY_s;

    // ---------------------------------------------
    // Master Port Signals
    // ---------------------------------------------
    logic [`AXI_IDS_BITS-1:0]   AWID_m;
    logic [`AXI_ADDR_BITS-1:0]  AWADDR_m;
    logic [`AXI_LEN_BITS-1:0]   AWLEN_m;
    logic [`AXI_SIZE_BITS-1:0]  AWSIZE_m;
    logic [1:0]                 AWBURST_m;
    logic                       AWVALID_m;
    logic                       AWREADY_m;

    logic [`AXI_DATA_BITS-1:0]  WDATA_m;
    logic [`AXI_STRB_BITS-1:0]  WSTRB_m;
    logic                      WLAST_m;
    logic                      WVALID_m;
    logic                      WREADY_m;

    logic [`AXI_IDS_BITS-1:0]   BID_m;
    logic [1:0]                BRESP_m;
    logic                      BVALID_m;
    logic                      BREADY_m;

    // ---------------------------------------------
    // modport definitions
    // ---------------------------------------------
    modport slave (
        // Write address
        input  AWID_s, AWADDR_s, AWLEN_s, AWSIZE_s, AWBURST_s, AWVALID_s,
        output AWREADY_s,

        // Write data
        input  WDATA_s, WSTRB_s, WLAST_s, WVALID_s,
        output WREADY_s,

        // Write response
        output BID_s, BRESP_s, BVALID_s,
        input  BREADY_s
    );

    modport bus_slave (
        // Write address
        output  AWID_s, AWADDR_s, AWLEN_s, AWSIZE_s, AWBURST_s, AWVALID_s,
        input AWREADY_s,

        // Write data
        output  WDATA_s, WSTRB_s, WLAST_s, WVALID_s,
        input WREADY_s,

        // Write response
        input BID_s, BRESP_s, BVALID_s,
        output  BREADY_s
    );


    modport master (
        // Write address
        output AWID_m, AWADDR_m, AWLEN_m, AWSIZE_m, AWBURST_m, AWVALID_m,
        input  AWREADY_m,

        // Write data
        output WDATA_m, WSTRB_m, WLAST_m, WVALID_m,
        input  WREADY_m,

        // Write response
        input  BID_m, BRESP_m, BVALID_m,
        output BREADY_m
    );

    modport bus_master (
        // Write address
        input AWID_m, AWADDR_m, AWLEN_m, AWSIZE_m, AWBURST_m, AWVALID_m,
        output  AWREADY_m,

        // Write data
        input WDATA_m, WSTRB_m, WLAST_m, WVALID_m,
        output  WREADY_m,

        // Write response
        output  BID_m, BRESP_m, BVALID_m,
        input BREADY_m
    );
    // ======================
    // WRITE channel tie-off
    // ======================
    // generate
    //     if (!WRITE_ENABLE) begin
    //         // Master side
    //         assign AWID_m    = '0;
    //         assign AWADDR_m  = '0;
    //         assign AWLEN_m   = '0;
    //         assign AWSIZE_m  = '0;
    //         assign AWBURST_m = '0;
    //         assign AWVALID_m = 1'b0;

    //         assign WDATA_m   = '0;
    //         assign WSTRB_m   = '0;
    //         assign WLAST_m   = 1'b0;
    //         assign WVALID_m  = 1'b0;

    //         assign BREADY_m  = 1'b0;

    //         // Slave side
    //         assign AWREADY_s = 1'b0;
    //         assign WREADY_s  = 1'b0;

    //         assign BID_s     = '0;
    //         assign BRESP_s   = '0;
    //         assign BVALID_s  = 1'b0;
    //     end
    // endgenerate


endinterface

