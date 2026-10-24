//////////////////////////////////////////////////////////////////////
//          ██╗       ██████╗   ██╗  ██╗    ██████╗            		//
//          ██║       ██╔══█║   ██║  ██║    ██╔══█║            		//
//          ██║       ██████║   ███████║    ██████║            		//
//          ██║       ██╔═══╝   ██╔══██║    ██╔═══╝            		//
//          ███████╗  ██║  	    ██║  ██║    ██║  	           		//
//          ╚══════╝  ╚═╝  	    ╚═╝  ╚═╝    ╚═╝  	           		//
//                                                             		//
// 	2025 Advanced VLSI System Design, advisor: Lih-Yih, Chiou		//
//                                                             		//
//////////////////////////////////////////////////////////////////////
//                                                             		//
// 	Autor: 			TZUNG-JIN, TSAI (Leo)				  	   		//
//	Filename:		 AXI.sv			                            	//
//	Description:	Top module of AXI	 							//
// 	Version:		1.0	    								   		//
//////////////////////////////////////////////////////////////////////
`include "../include/AXI_define.svh"
//`include "../include/AXI.svh"

// ============================
//  Address Range Table
// ============================

import AXI_addr_map_pkg::*;

module AXI #(
    parameter Master = 4,
    parameter Slave  = 9,
    parameter Master_index = $clog2(Master),
	parameter ADDER_W = $clog2(2*Master+1)

)(
    input  logic ACLK,
    input  logic ARESETn,

    // Master side (M0~M2)
    axi_read_if  axi_r_m [Master],   // AR/R 通道
    axi_write_if axi_w_m [Master],   // AW/W/B 通道

    // Slave side (S0~S5)
    axi_read_if  axi_r_s [Slave],    // AR/R
    axi_write_if axi_w_s [Slave]     // AW/W/B
);
// localparam logic [31:0] SLAVE_ADDR_MIN [Slave] = '{
//     32'h0001_0000,   // S0
//     32'h0002_0000,   // S1
//     32'h0000_0000,   // S2 (ROM)
//     32'h2000_0000,   // S3 (DRAM)
//     32'h1002_0000,   // S4 (DMA)
//     32'h1001_0000    // S5 (DWT)
// };

// localparam logic [31:0] SLAVE_ADDR_MAX [Slave] = '{
//     32'h0001_FFFF,   // S0
//     32'h0002_FFFF,   // S1
//     32'h0000_1FFF,   // S2 (ROM)
//     32'h201F_FFFF,   // S3 (DRAM)
//     32'h1002_0200,   // S4 (DMA)
//     32'h1001_03FF    // S5 (DWT)
// };

    //---------- you should put your design here ----------//

// race / lock / RW / invalid
wire [Slave-1:0] Master_race_s;
wire [Slave-1:0] out_lock_s;
wire [Slave-1:0] race_RW_s;
wire [Slave-1:0] invalid_s;

// race index
wire [Master_index-1:0] race_index_s [Slave-1:0];

// AR/AW request bitmap (Slave x Master)
reg  [Master-1:0] ARVALID_s_req [Slave-1:0];
reg  [Master-1:0] AWVALID_s_req [Slave-1:0];

// adder array (Slave 個)
wire [ADDER_W-1:0] s_adder [Slave];

//read only
//assign axi_w_m[0].AWVALID_m = 1'b0;
//assign axi_w_m[0].AWADDR_m  = 32'd0;


genvar M, S;
integer Mi, Si;
generate
    for (S = 0; S < Slave; S = S + 1) begin : SLAVE_BLOCK
        reg [ADDER_W-1:0] ar_sum, aw_sum;

        always @(*) begin
            ar_sum = 0;
            aw_sum = 0;
            for (Mi = 0; Mi < Master; Mi = Mi + 1) begin
                ar_sum = ar_sum + ARVALID_s_req[S][Mi];
                aw_sum = aw_sum + AWVALID_s_req[S][Mi];
            end
        end

        assign s_adder[S]       = ar_sum + aw_sum;
        assign Master_race_s[S] = (s_adder[S] > 1 && !out_lock_s[S]);
        assign invalid_s[S]     = (s_adder[S] == 0);
    end
endgenerate


integer Sj;

generate
for (M = 0; M < Master; M++) begin : GEN_AW_DECODE

    always @(*) begin
        // 預設都 0
        for (Sj = 0; Sj < Slave; Sj++)
            AWVALID_s_req[Sj][M] = 1'b0;

        // 若此 Master 有 valid
        if (axi_w_m[M].AWVALID_m) begin
            // 檢查每個 slave 的 address range
            for (Si = 0; Si < Slave; Si++) begin
                if ((axi_w_m[M].AWADDR_m >= SLAVE_ADDR_MIN[Si]) &&
                    (axi_w_m[M].AWADDR_m <= SLAVE_ADDR_MAX[Si])) begin
                    AWVALID_s_req[Si][M] = 1'b1;
                end
            end
        end
    end

end
endgenerate


generate
for (M = 0; M < Master; M++) begin : GEN_AR_DECODE

    always @(*) begin
        // 預設都 0
        for (Sj = 0; Sj < Slave; Sj++)
            ARVALID_s_req[Sj][M] = 1'b0;

        // 若此 Master 有 valid
        if (axi_r_m[M].ARVALID_m) begin
            // 檢查每個 slave 的 address range
            for (Si = 0; Si < Slave; Si++) begin
                if ((axi_r_m[M].ARADDR_m >= SLAVE_ADDR_MIN[Si]) &&
                    (axi_r_m[M].ARADDR_m <= SLAVE_ADDR_MAX[Si])) begin
                    ARVALID_s_req[Si][M] = 1'b1;
                end
            end
        end
    end

end
endgenerate




generate
for (S = 0; S < Slave; S++) begin : GEN_ARB

    arbitrator #(
        .Master(Master)
    ) arb (
        .ACLK       (ACLK),
        .ARESETn    (ARESETn),

        .race       (Master_race_s[S] && !out_lock_s[S]),

        .ARVALID_req(ARVALID_s_req[S]),   // ← S-th slave 的 req
        .AWVALID_req(AWVALID_s_req[S]),

        .index      (race_index_s[S]),
        .RW         (race_RW_s[S])
    );

end
endgenerate

//------------------------------------------------------
// Slave to Master Connections (Read Data Channel)
//------------------------------------------------------
logic        ARREADY_MS [Master][Slave];
logic [31:0] RDATA_MS   [Master][Slave];
logic [3:0]  RID_MS     [Master][Slave];
logic [1:0]  RRESP_MS   [Master][Slave];
logic        RVALID_MS  [Master][Slave];
logic        RLAST_MS   [Master][Slave];

logic        AWREADY_MS [Master][Slave];
logic        WREADY_MS  [Master][Slave];

logic        BVALID_MS  [Master][Slave];
logic [1:0]  BRESP_MS   [Master][Slave];
logic [3:0]  BID_MS     [Master][Slave];



integer S_arready;
integer S_rvalid;
integer S_rdata;
integer S_rresp;
integer S_rlast;
integer S_awready;
integer S_rid;
integer S_wready;
integer S_bvalid;
integer S_bresp;
integer S_bid;
logic                    tmp_arready  [Master-1:0];
logic                    tmp_rvalid   [Master-1:0];
logic [`AXI_ID_BITS-1:0]   tmp_rid     [Master-1:0];
logic [`AXI_DATA_BITS-1:0] tmp_rdata   [Master-1:0];
logic [1:0]              tmp_rresp    [Master-1:0];
logic                    tmp_rlast    [Master-1:0];

logic                    tmp_awready  [Master-1:0];
logic                    tmp_wready   [Master-1:0];
logic                    tmp_bvalid   [Master-1:0];
logic [1:0]              tmp_bresp    [Master-1:0];
logic [`AXI_ID_BITS-1:0]   tmp_bid     [Master-1:0];

// ====================================================
// Return Path per Master
// ====================================================
generate
for (genvar M = 0; M < Master; M++) begin : GEN_Master_RETURN

    // ---------- ARREADY ----------
    always @(*) begin
        tmp_arready[M] = 1'b0;
        for (S_arready = 0; S_arready < Slave; S_arready++)
            tmp_arready[M] |= ARREADY_MS[M][S_arready];
    end
    assign axi_r_m[M].ARREADY_m = tmp_arready[M];

    // ---------- RVALID ----------
    always @(*) begin
        tmp_rvalid[M] = 1'b0;
        for (S_rvalid = 0; S_rvalid < Slave; S_rvalid++)
            tmp_rvalid[M] |= RVALID_MS[M][S_rvalid];
    end
    assign axi_r_m[M].RVALID_m = tmp_rvalid[M];

    // ---------- RID ----------
    always @(*) begin
        tmp_rid[M] = '0;
        for (S_rid = 0; S_rid < Slave; S_rid++)
            tmp_rid[M] |= RID_MS[M][S_rid];
    end
    assign axi_r_m[M].RID_m = tmp_rid[M];

    // ---------- RDATA ----------
    always @(*) begin
        tmp_rdata[M] = '0;
        for (S_rdata = 0; S_rdata < Slave; S_rdata++)
            tmp_rdata[M] |= RDATA_MS[M][S_rdata];
    end
    assign axi_r_m[M].RDATA_m = tmp_rdata[M];

    // ---------- RRESP ----------
    always @(*) begin
        tmp_rresp[M] = '0;
        for (S_rresp = 0; S_rresp < Slave; S_rresp++)
            tmp_rresp[M] |= RRESP_MS[M][S_rresp];
    end
    assign axi_r_m[M].RRESP_m = tmp_rresp[M];

    // ---------- RLAST ----------
    always @(*) begin
        tmp_rlast[M] = 1'b0;
        for (S_rlast = 0; S_rlast < Slave; S_rlast++)
            tmp_rlast[M] |= RLAST_MS[M][S_rlast];
    end
    assign axi_r_m[M].RLAST_m = tmp_rlast[M];


    // ====================================================
    // Write Path
    // ====================================================

    // ---------- AWREADY ----------
    always @(*) begin
        tmp_awready[M] = 1'b0;
        for (S_awready = 0; S_awready < Slave; S_awready++)
            tmp_awready[M] |= AWREADY_MS[M][S_awready];
    end
    assign axi_w_m[M].AWREADY_m = tmp_awready[M];

    // ---------- WREADY ----------
    always @(*) begin
        tmp_wready[M] = 1'b0;
        for (S_wready = 0; S_wready < Slave; S_wready++)
            tmp_wready[M] |= WREADY_MS[M][S_wready];
    end
    assign axi_w_m[M].WREADY_m = tmp_wready[M];

    // ---------- BVALID ----------
    always @(*) begin
        tmp_bvalid[M] = 1'b0;
        for (S_bvalid = 0; S_bvalid < Slave; S_bvalid++)
            tmp_bvalid[M] |= BVALID_MS[M][S_bvalid];
    end
    assign axi_w_m[M].BVALID_m = tmp_bvalid[M];

    // ---------- BRESP ----------
    always @(*) begin
        tmp_bresp[M] = '0;
        for (S_bresp = 0; S_bresp < Slave; S_bresp++)
            tmp_bresp[M] |= BRESP_MS[M][S_bresp];
    end
    assign axi_w_m[M].BRESP_m = tmp_bresp[M];

    // ---------- BID ----------
    always @(*) begin
        tmp_bid[M] = '0;
        for (S_bid = 0; S_bid < Slave; S_bid++)
            tmp_bid[M] |= BID_MS[M][S_bid];
    end
    assign axi_w_m[M].BID_m = tmp_bid[M];

end
endgenerate



//-----------------------------------------
// Interface arrays (Master / Slave)
//-----------------------------------------

generate
for (S = 0; S < Slave; S++) begin : GEN_XBAR

    axi_read_if  crossbar_r_m   [Master] ();
    axi_write_if crossbar_w_m   [Master] ();

    CrossBar2 #(
        .Master(Master)
    ) xbar (
        .ACLK     (ACLK),
        .ARESETn  (ARESETn),

        .index    (race_index_s[S]),
        .RW       (race_RW_s[S]),
        .invalid  (invalid_s[S]),
        .out_lock (out_lock_s[S]),

        .crossbar_r_m  (crossbar_r_m),
        .crossbar_w_m  (crossbar_w_m),

        .axi_r_s  (axi_r_s[S]),
        .axi_w_s  (axi_w_s[S])
    );

    //===========================================================
    //  Master → Slave assign
    //===========================================================
    for (M = 0; M < Master; M++) begin : GEN_MS

        // ----------- READ ADDRESS (AR) -----------
        assign crossbar_r_m[M].ARID_m    = axi_r_m[M].ARID_m;
        assign crossbar_r_m[M].ARADDR_m  = axi_r_m[M].ARADDR_m;
        assign crossbar_r_m[M].ARLEN_m   = axi_r_m[M].ARLEN_m;
        assign crossbar_r_m[M].ARSIZE_m  = axi_r_m[M].ARSIZE_m;
        assign crossbar_r_m[M].ARBURST_m = axi_r_m[M].ARBURST_m;
        assign crossbar_r_m[M].ARVALID_m = ARVALID_s_req[S][M];
        assign crossbar_r_m[M].RREADY_m  = axi_r_m[M].RREADY_m;

        // ----------- WRITE ADDRESS (AW) ----------
        assign crossbar_w_m[M].AWID_m    = axi_w_m[M].AWID_m;
        assign crossbar_w_m[M].AWADDR_m  = axi_w_m[M].AWADDR_m;
        assign crossbar_w_m[M].AWLEN_m   = axi_w_m[M].AWLEN_m;
        assign crossbar_w_m[M].AWSIZE_m  = axi_w_m[M].AWSIZE_m;
        assign crossbar_w_m[M].AWBURST_m = axi_w_m[M].AWBURST_m;
        assign crossbar_w_m[M].AWVALID_m = AWVALID_s_req[S][M];

        // ----------- WRITE DATA (W) --------------
        assign crossbar_w_m[M].WDATA_m   = axi_w_m[M].WDATA_m;
        assign crossbar_w_m[M].WSTRB_m   = axi_w_m[M].WSTRB_m;
        assign crossbar_w_m[M].WLAST_m   = axi_w_m[M].WLAST_m;
        assign crossbar_w_m[M].WVALID_m  = axi_w_m[M].WVALID_m;

        // ----------- WRITE RESPONSE READY (BREADY) ----
        assign crossbar_w_m[M].BREADY_m  = axi_w_m[M].BREADY_m;

        //===========================================================
        //  Slave → Master 回傳（合法寫法）
        //===========================================================

        // READ channel
        assign ARREADY_MS[M][S] = crossbar_r_m[M].ARREADY_m;
        assign RDATA_MS[M][S]   = crossbar_r_m[M].RDATA_m;
        assign RID_MS[M][S]     = crossbar_r_m[M].RID_m;
        assign RRESP_MS[M][S]   = crossbar_r_m[M].RRESP_m;
        assign RLAST_MS[M][S]   = crossbar_r_m[M].RLAST_m;
        assign RVALID_MS[M][S]  = crossbar_r_m[M].RVALID_m;

        // WRITE channel
        assign AWREADY_MS[M][S] = crossbar_w_m[M].AWREADY_m;
        assign WREADY_MS[M][S]  = crossbar_w_m[M].WREADY_m;
        assign BVALID_MS[M][S]  = crossbar_w_m[M].BVALID_m;
        assign BRESP_MS[M][S]   = crossbar_w_m[M].BRESP_m;
        assign BID_MS[M][S]     = crossbar_w_m[M].BID_m;

    end // for M

end // for S
endgenerate






endmodule
