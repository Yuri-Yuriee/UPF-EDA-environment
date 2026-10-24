module SRAM_wrapper (
    input           ACLK,
    input           ARESETn,

    axi_read_if.slave   axi_r_s,   // AR/R
    axi_write_if.slave  axi_w_s    // AW/W/B
);

//============================================================
//  Declaration for SRAM_plug ports
//============================================================
    wire           clk, rst;
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


//******************************
//          slave
//******************************
slave_simple u_slave_simple (
    //******************************
    //      from wrapper port
    //******************************
    .ACLK           (ACLK),
    .ARESETn        (ARESETn),

    .axi_r_s        (axi_r_s),
    .axi_w_s        (axi_w_s),

    //******************************
    //      to plug
    //******************************
    .in_miss        (miss),
    .in_hit         (hit),
    .read_data      (read_data),
    .Read_Enable    (Read_Enable),
    .Write_data     (Write_data),
    .Write_Enable   (Write_Enable),
    .Addr           (Addr),
    .out_WSTRB      (WSTRB),
    .stall_R        ('0),
    .stall_W        ('0)
);


//******************************
//          plug
//******************************
SRAM_plug u_plug (
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
    //          to SRAM
    //******************************
    .CEB            (CEB),
    .WEB            (WEB),
    .A              (A),
    .DI             (DI),
    .BWEB           (BWEB),
    .DO             (DO)
);


//******************************
//          SRAM
//******************************
`ifdef spyglass

`elsif Dual_MEM

FILL_IN_CELL_SRAM_006 i_SRAM (
    .SLP            (1'b0),
    .DSLP           (1'b0),
    .SD             (1'b0),
    .PUDELAY        (),
    .CLK            (ACLK),
    .CEB            (CEB),
    .WEB            (WEB),
    .A              (A),
    .D              (DI),
    .BWEB           (BWEB),
    .RTSEL          (2'b01),
    .WTSEL          (2'b00),
    .Q              (DO),
    .BIST           (1'b0)
);

`else

FILL_IN_CELL_SRAM_007 i_SRAM (
    .SLP            (1'b0),
    .DSLP           (1'b0),
    .SD             (1'b0),
    .PUDELAY        (),
    .CLK            (ACLK),
    .CEB            (CEB),
    .WEB            (WEB),
    .A              (A),
    .D              (DI),
    .BWEB           (BWEB),
    .RTSEL          (2'b01),
    .WTSEL          (2'b00),
    .Q              (DO)
);

`endif

endmodule