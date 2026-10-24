//`include "../src/AXI/slave_simple.sv"
//`include "../src/AXI/SRAM_plug.sv"
//`define spyglass
//`include "../tech/memory/sim/SRAM/SRAM_rtl.sv"
//`include "../tech/memory/sim/SRAM/FILL_IN_CELL_SRAM_012.sv"

module WDT_wrapper (
    input           ACLK,
    input           ARESETn,
    input           clk2,
    input           rst2,
    output          WDT_interrupt,

    axi_write_if.slave axi_w_s
);

//============================================================
//  Declaration for WDT_plug ports
//============================================================
    wire           rst;
    wire           miss, hit;
    wire   [31:0]  read_data;
    wire           Read_Enable;
    wire   [31:0]  Addr;
    wire   [31:0]  Write_data;
    wire           Write_Enable;
    wire   [3:0]   WSTRB;
    wire           CEB;
    wire           WEB;
    wire   [13:0]  A;
    wire   [31:0]  DI;
    wire   [31:0]  BWEB;
    wire   [31:0]  DO;

    //========================================================
    // WDT signals
    //========================================================
    wire           WDEN;
    wire           WDLIVE;
    wire   [31:0]  WTOCNT;
    wire           WTO;

    //========================================================
    // WDT interrupt synchronization
    //
    // Source domain:
    //   clk2 / rst2
    //
    // Destination domain:
    //   ACLK / ARESETn
    //========================================================
    reg            WTO_src_ff;

    (* ASYNC_REG = "TRUE" *) reg WDT_interrupt_sync_ff1;
    (* ASYNC_REG = "TRUE" *) reg WDT_interrupt_sync_ff2;

`ifdef WDT_PG
    wire           WDT_CG;
`endif


//============================================================
//  Source-domain register
//
//  Register WTO once in clk2 domain before CDC crossing.
//  rst2 is assumed to be active high.
//============================================================
always @(posedge clk2 or posedge rst2) begin
    if (rst2) begin
        WTO_src_ff <= 1'b0;
    end
    else begin
        WTO_src_ff <= WTO;
    end
end


//============================================================
//  Destination-domain two-stage synchronizer
//
//  Synchronize WTO_src_ff into ACLK domain.
//  ARESETn is active low.
//============================================================
always @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn) begin
        WDT_interrupt_sync_ff1 <= 1'b0;
        WDT_interrupt_sync_ff2 <= 1'b0;
    end
    else begin
        WDT_interrupt_sync_ff1 <= WTO_src_ff;
        WDT_interrupt_sync_ff2 <= WDT_interrupt_sync_ff1;
    end
end


//============================================================
//  Synchronized WDT interrupt output
//============================================================
assign WDT_interrupt = WDT_interrupt_sync_ff2;


//============================================================
//  Dummy read interface
//  WDT only uses AXI write channel, so read channel is tied off.
//============================================================
axi_read_if axi_r_dummy();

assign axi_r_dummy.ARID_s     = '0;
assign axi_r_dummy.ARADDR_s   = '0;
assign axi_r_dummy.ARLEN_s    = '0;
assign axi_r_dummy.ARSIZE_s   = '0;
assign axi_r_dummy.ARBURST_s  = '0;
assign axi_r_dummy.ARVALID_s  = 1'b0;

assign axi_r_dummy.RREADY_s   = 1'b0;


//******************************
//          slave
//******************************
slave_simple u_slave_simple (
    //******************************
    //      from wrapper port
    //******************************
    .ACLK           (ACLK),
    .ARESETn        (ARESETn),

    .axi_r_s        (axi_r_dummy),
    .axi_w_s        (axi_w_s),

    //******************************
    //      to plug
    //******************************
    // req
    .Write_Enable   (Write_Enable),
    .Write_data     (Write_data),
    .Read_Enable    (Read_Enable),
    .out_WSTRB      (WSTRB),
    .Addr           (Addr),

    // resp
    .in_miss        (miss),
    .in_hit         (hit),
    .read_data      (read_data),
    .stall_R        ('0),
    .stall_W        ('0)
);


//******************************
//          plug
//******************************
WDT_plug u_plug (
    //******************************
    //          from slave
    //******************************
    .clk            (ACLK),
    .rst            (~ARESETn),
    .miss           (miss),
    .hit            (hit),
    .read_data      (read_data),
    .Read_Enable    (Read_Enable),
    .Addr           (Addr),
    .Write_data     (Write_data),
    .Write_Enable   (Write_Enable),
    .WSTRB          (WSTRB),

    //******************************
    //          to WDT
    //******************************
    .clk2           (clk2),
    .rst2           (rst2),
    .WDEN           (WDEN),
    .WDLIVE         (WDLIVE),
    .WTOCNT         (WTOCNT)

`ifdef WDT_PG
    ,
    .WDT_CG         (WDT_CG)
`endif
);


//******************************
//          WDT
//******************************
WDT u_WDT (
    .clk            (clk2),
    .rst            (rst2),
    .WDEN           (WDEN),
    .WDLIVE         (WDLIVE),
    .WTOCNT         (WTOCNT),
    .WTO            (WTO)

`ifdef WDT_PG
    ,
    .WDT_CG         (WDT_CG)
`endif
);

endmodule