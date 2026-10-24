module CPU_wrapper #(
    parameter integer v_stage      = 4
)(

    //******************************
    //  Global signals
    //******************************
    input           ACLK,
    input           CCLK,
    input           CRST,
    input           ARESETn,
    input           MTIP,
    input           MEIP,

    input           [((v_stage <= 1) ? 1 : $clog2(v_stage))-1:0] DVFS_v_step,

    axi_read_if.master   axi_r_m0,
    axi_read_if.master   axi_r_m1,
    axi_write_if.master  axi_w_m1
);

wire           ARST = ~ARESETn;
wire           clk = CCLK;

wire           response_P1_ACLK;
wire           Read_Enable_P1_ACLK;
wire [31:0]    read_data_P1_ACLK;
wire           WB_P1_ACLK;
wire           response_P0_ACLK;
wire           Read_Enable_P0_ACLK;
wire [31:0]    read_data_P0_ACLK;
wire           WB_P0_ACLK;
wire           RLAST_shacke0_ACLK;
wire           RLAST_shacke1_ACLK;
wire           B_shacke1_ACLK;

wire           response_P1_CCLK;
wire           Read_Enable_P1_CCLK;
wire [31:0]    read_data_P1_CCLK;
wire           WB_P1_CCLK;
wire           response_P0_CCLK;
wire           Read_Enable_P0_CCLK;
wire [31:0]    read_data_P0_CCLK;
wire           WB_P0_CCLK;
wire           RLAST_shacke1_CCLK;
wire           RLAST_shacke0_CCLK;
wire           B_shacke1_CCLK;

wire            req_En_P1_ACLK,          req_En_P1_CCLK;
wire            RW_P1_ACLK,              RW_P1_CCLK;
wire [31:0]     Addr_P1_ACLK,            Addr_P1_CCLK;
wire [2:0]      size_P1_ACLK,            size_P1_CCLK;
wire [3:0]      len_P1_ACLK,             len_P1_CCLK;
wire [3:0]      WSTRB_P1_ACLK,           WSTRB_P1_CCLK;
wire [1:0]      BURST_P1_ACLK,           BURST_P1_CCLK;
wire [31:0]     Write_data_P1_ACLK,      Write_data_P1_CCLK;
wire            Write_Enable_P1_ACLK,    Write_Enable_P1_CCLK;

wire            req_En_P0_ACLK,          req_En_P0_CCLK;
wire            RW_P0_ACLK,              RW_P0_CCLK;
wire [31:0]     Addr_P0_ACLK,            Addr_P0_CCLK;
wire [2:0]      size_P0_ACLK,            size_P0_CCLK;
wire [3:0]      len_P0_ACLK,             len_P0_CCLK;
wire [3:0]      WSTRB_P0_ACLK,           WSTRB_P0_CCLK;
wire [1:0]      BURST_P0_ACLK,           BURST_P0_CCLK;
wire [31:0]     Write_data_P0_ACLK,      Write_data_P0_CCLK;
wire            Write_Enable_P0_ACLK,    Write_Enable_P0_CCLK;

wire axi2cpu_wfull;

wire CPU_CG;

// CPU-side wires
wire [31:0] PC_I;
wire        stall_I;
wire [31:0] Addr_D;
wire [31:0] BWEB_D;
wire        WEB_D;
wire [31:0] store_data_D;
wire [31:0] read_data_D;
wire        CEB_D;
wire        stall_D;
wire [31:0] instr;
wire        stall_wfi;
wire [31:0] EXE_I_result;
wire        EXE_MEM_use;
wire        EXE_detect_wfi;
wire        interrupt;
wire        CPU_restore_pulse;


//******************************
// AXI handshake observe
//******************************
assign RLAST_shacke0_ACLK = axi_r_m0.RLAST_m & axi_r_m0.RVALID_m;
assign RLAST_shacke1_ACLK = axi_r_m1.RLAST_m & axi_r_m1.RVALID_m;
assign B_shacke1_ACLK     = axi_w_m1.BVALID_m & axi_w_m1.BREADY_m;

//******************************
// master0 write dummy interface
//******************************
axi_write_if axi_w_m0_dummy();

assign axi_w_m0_dummy.AWREADY_m = 1'b0;
assign axi_w_m0_dummy.WREADY_m  = 1'b0;

assign axi_w_m0_dummy.BID_m     = 4'd0;
assign axi_w_m0_dummy.BRESP_m   = 2'd0;
assign axi_w_m0_dummy.BVALID_m  = 1'b0;

//******************************
//             master
//******************************
master_simple u_master0 (
    .ACLK           (ACLK),
    .ARESETn        (ARESETn),

    .axi_r_m        (axi_r_m0),
    .axi_w_m        (axi_w_m0_dummy.master),

    .req_En         (req_En_P0_ACLK),
    .RW             (RW_P0_ACLK),
    .Addr           (Addr_P0_ACLK),
    .Size           (size_P0_ACLK),
    .Signalize      (3'd0),
    .Len            (len_P0_ACLK),
    .WSTRB          (WSTRB_P0_ACLK),
    .BURST          (BURST_P0_ACLK),
    .ID             (4'd0),
    .response       (response_P0_ACLK),

    .read_data      (read_data_P0_ACLK),
    .Read_Enable    (Read_Enable_P0_ACLK),
    .out_ID         (),
    .Write_data     (Write_data_P0_ACLK),
    .Write_Enable   (Write_Enable_P0_ACLK),
    .WB             (WB_P0_ACLK),
    .stall          (axi2cpu_wfull)
);

master_simple u_master1 (
    .ACLK           (ACLK),
    .ARESETn        (ARESETn),

    .axi_r_m        (axi_r_m1),
    .axi_w_m        (axi_w_m1),

    .req_En         (req_En_P1_ACLK),
    .RW             (RW_P1_ACLK),
    .Addr           (Addr_P1_ACLK),
    .Size           (size_P1_ACLK),
    .Signalize      (3'd0),
    .Len            (len_P1_ACLK),
    .WSTRB          (WSTRB_P1_ACLK),
    .BURST          (BURST_P1_ACLK),
    .ID             (4'd1),
    .response       (response_P1_ACLK),

    .read_data      (read_data_P1_ACLK),
    .Read_Enable    (Read_Enable_P1_ACLK),
    .out_ID         (),
    .Write_data     (Write_data_P1_ACLK),
    .Write_Enable   (Write_Enable_P1_ACLK),
    .WB             (WB_P1_ACLK),
    .stall          (axi2cpu_wfull)
);

//******************************
//             CDC
//******************************
`ifdef CPU_CDC
typedef struct packed {
    logic           response_P1;
    logic           Read_Enable_P1;
    logic [31:0]    read_data_P1;
    logic           WB_P1;
    logic           response_P0;
    logic           Read_Enable_P0;
    logic [31:0]    read_data_P0;
    logic           WB_P0;
    logic           RLAST_shacke0;
    logic           B_shacke1;
    logic           RLAST_shacke1;
} axi2cpu_data;

typedef struct packed {
    logic            req_En_P1;
    logic            RW_P1;
    logic [31:0]     Addr_P1;
    logic [2:0]      size_P1;
    logic [3:0]      len_P1;
    logic [3:0]      WSTRB_P1;
    logic [1:0]      BURST_P1;
    logic [31:0]     Write_data_P1;
    logic            Write_Enable_P1;
    logic            req_En_P0;
    logic            RW_P0;
    logic [31:0]     Addr_P0;
    logic [2:0]      size_P0;
    logic [3:0]      len_P0;
    logic [3:0]      WSTRB_P0;
    logic [1:0]      BURST_P0;
    logic [31:0]     Write_data_P0;
    logic            Write_Enable_P0;
} cpu2axi_data;

wire axi2cpu_wen;
wire [72:0] axi2cpu_wdata;
wire axi2cpu_ren;
wire [72:0] axi2cpu_rdata, axi2cpu_rdata_gate;
wire axi2cpu_rempty;
axi2cpu_data axi2cpu_RDATA;

wire cpu2axi_wen;
wire [159:0] cpu2axi_wdata;
wire cpu2axi_wfull;
wire cpu2axi_ren;
wire [159:0] cpu2axi_rdata, cpu2axi_rdata_gate;
wire cpu2axi_rempty;
cpu2axi_data cpu2axi_RDATA;

// req_En from CPU_plug is a single-cycle pulse, so keep it unchanged.
// Write_Enable may stay high while waiting for write response.
// Convert Write_Enable level to one-shot before enqueueing into cpu2axi FIFO.
reg  cpu2axi_write_hold_P1;
reg  cpu2axi_write_hold_P0;
wire Write_Enable_P1_CCLK_fifo;
wire Write_Enable_P0_CCLK_fifo;

assign axi2cpu_wdata = {
    RLAST_shacke0_ACLK,
    B_shacke1_ACLK,
    RLAST_shacke1_ACLK,
    response_P1_ACLK,
    Read_Enable_P1_ACLK,
    read_data_P1_ACLK,
    WB_P1_ACLK,
    response_P0_ACLK,
    Read_Enable_P0_ACLK,
    read_data_P0_ACLK,
    WB_P0_ACLK
};

assign axi2cpu_RDATA.RLAST_shacke0  = axi2cpu_rdata_gate[72];
assign axi2cpu_RDATA.B_shacke1      = axi2cpu_rdata_gate[71];
assign axi2cpu_RDATA.RLAST_shacke1  = axi2cpu_rdata_gate[70];
assign axi2cpu_RDATA.response_P1    = axi2cpu_rdata_gate[69];
assign axi2cpu_RDATA.Read_Enable_P1 = axi2cpu_rdata_gate[68];
assign axi2cpu_RDATA.read_data_P1   = axi2cpu_rdata_gate[67:36];
assign axi2cpu_RDATA.WB_P1          = axi2cpu_rdata_gate[35];
assign axi2cpu_RDATA.response_P0    = axi2cpu_rdata_gate[34];
assign axi2cpu_RDATA.Read_Enable_P0 = axi2cpu_rdata_gate[33];
assign axi2cpu_RDATA.read_data_P0   = axi2cpu_rdata_gate[32:1];
assign axi2cpu_RDATA.WB_P0          = axi2cpu_rdata_gate[0];

assign RLAST_shacke0_CCLK   = axi2cpu_RDATA.RLAST_shacke0;
assign B_shacke1_CCLK       = axi2cpu_RDATA.B_shacke1;
assign RLAST_shacke1_CCLK   = axi2cpu_RDATA.RLAST_shacke1;
assign response_P1_CCLK     = axi2cpu_RDATA.response_P1;
assign Read_Enable_P1_CCLK  = axi2cpu_RDATA.Read_Enable_P1;
assign read_data_P1_CCLK    = axi2cpu_RDATA.read_data_P1;
assign WB_P1_CCLK           = axi2cpu_RDATA.WB_P1;
assign response_P0_CCLK     = axi2cpu_RDATA.response_P0;
assign Read_Enable_P0_CCLK  = axi2cpu_RDATA.Read_Enable_P0;
assign read_data_P0_CCLK    = axi2cpu_RDATA.read_data_P0;
assign WB_P0_CCLK           = axi2cpu_RDATA.WB_P0;

assign axi2cpu_wen = response_P1_ACLK | Read_Enable_P1_ACLK | WB_P1_ACLK |
                     response_P0_ACLK | Read_Enable_P0_ACLK | WB_P0_ACLK;
assign axi2cpu_ren = !axi2cpu_rempty;
//assign axi2cpu_ren = !axi2cpu_rempty && cpu2axi_wfull;
assign axi2cpu_rdata_gate = (axi2cpu_ren) ? axi2cpu_rdata : '0;



assign cpu2axi_wdata = {
    req_En_P1_CCLK,
    RW_P1_CCLK,
    Addr_P1_CCLK,
    size_P1_CCLK,
    len_P1_CCLK,
    WSTRB_P1_CCLK,
    BURST_P1_CCLK,
    Write_data_P1_CCLK,
    Write_Enable_P1_CCLK_fifo,
    req_En_P0_CCLK,
    RW_P0_CCLK,
    Addr_P0_CCLK,
    size_P0_CCLK,
    len_P0_CCLK,
    WSTRB_P0_CCLK,
    BURST_P0_CCLK,
    Write_data_P0_CCLK,
    Write_Enable_P0_CCLK_fifo
};

assign cpu2axi_RDATA.req_En_P1       = cpu2axi_rdata_gate[159];
assign cpu2axi_RDATA.RW_P1           = cpu2axi_rdata_gate[158];
assign cpu2axi_RDATA.Addr_P1         = cpu2axi_rdata_gate[157:126];
assign cpu2axi_RDATA.size_P1         = cpu2axi_rdata_gate[125:123];
assign cpu2axi_RDATA.len_P1          = cpu2axi_rdata_gate[122:119];
assign cpu2axi_RDATA.WSTRB_P1        = cpu2axi_rdata_gate[118:115];
assign cpu2axi_RDATA.BURST_P1        = cpu2axi_rdata_gate[114:113];
assign cpu2axi_RDATA.Write_data_P1   = cpu2axi_rdata_gate[112:81];
assign cpu2axi_RDATA.Write_Enable_P1 = cpu2axi_rdata_gate[80];
assign cpu2axi_RDATA.req_En_P0       = cpu2axi_rdata_gate[79];
assign cpu2axi_RDATA.RW_P0           = cpu2axi_rdata_gate[78];
assign cpu2axi_RDATA.Addr_P0         = cpu2axi_rdata_gate[77:46];
assign cpu2axi_RDATA.size_P0         = cpu2axi_rdata_gate[45:43];
assign cpu2axi_RDATA.len_P0          = cpu2axi_rdata_gate[42:39];
assign cpu2axi_RDATA.WSTRB_P0        = cpu2axi_rdata_gate[38:35];
assign cpu2axi_RDATA.BURST_P0        = cpu2axi_rdata_gate[34:33];
assign cpu2axi_RDATA.Write_data_P0   = cpu2axi_rdata_gate[32:1];
assign cpu2axi_RDATA.Write_Enable_P0 = cpu2axi_rdata_gate[0];

assign req_En_P1_ACLK       = cpu2axi_RDATA.req_En_P1;
assign RW_P1_ACLK           = cpu2axi_RDATA.RW_P1;
assign Addr_P1_ACLK         = cpu2axi_RDATA.Addr_P1;
assign size_P1_ACLK         = cpu2axi_RDATA.size_P1;
assign len_P1_ACLK          = cpu2axi_RDATA.len_P1;
assign WSTRB_P1_ACLK        = cpu2axi_RDATA.WSTRB_P1;
assign BURST_P1_ACLK        = cpu2axi_RDATA.BURST_P1;
assign Write_data_P1_ACLK   = cpu2axi_RDATA.Write_data_P1;
assign Write_Enable_P1_ACLK = cpu2axi_RDATA.Write_Enable_P1;
assign req_En_P0_ACLK       = cpu2axi_RDATA.req_En_P0;
assign RW_P0_ACLK           = cpu2axi_RDATA.RW_P0;
assign Addr_P0_ACLK         = cpu2axi_RDATA.Addr_P0;
assign size_P0_ACLK         = cpu2axi_RDATA.size_P0;
assign len_P0_ACLK          = cpu2axi_RDATA.len_P0;
assign WSTRB_P0_ACLK        = cpu2axi_RDATA.WSTRB_P0;
assign BURST_P0_ACLK        = cpu2axi_RDATA.BURST_P0;
assign Write_data_P0_ACLK   = cpu2axi_RDATA.Write_data_P0;
assign Write_Enable_P0_ACLK = cpu2axi_RDATA.Write_Enable_P0;

assign Write_Enable_P1_CCLK_fifo = Write_Enable_P1_CCLK & !cpu2axi_write_hold_P1;
assign Write_Enable_P0_CCLK_fifo = Write_Enable_P0_CCLK & !cpu2axi_write_hold_P0;

always @(posedge CCLK or posedge CRST) begin
    if(CRST)begin
        cpu2axi_write_hold_P1 <= 1'b0;
    end
    else if(!Write_Enable_P1_CCLK)begin
        cpu2axi_write_hold_P1 <= 1'b0;
    end
    else if(Write_Enable_P1_CCLK_fifo)begin
        cpu2axi_write_hold_P1 <= 1'b1;
    end
    else begin
        cpu2axi_write_hold_P1 <= cpu2axi_write_hold_P1;
    end
end

always @(posedge CCLK or posedge CRST) begin
    if(CRST)begin
        cpu2axi_write_hold_P0 <= 1'b0;
    end
    else if(!Write_Enable_P0_CCLK)begin
        cpu2axi_write_hold_P0 <= 1'b0;
    end
    else if(Write_Enable_P0_CCLK_fifo)begin
        cpu2axi_write_hold_P0 <= 1'b1;
    end
    else begin
        cpu2axi_write_hold_P0 <= cpu2axi_write_hold_P0;
    end
end

assign cpu2axi_wen = req_En_P1_CCLK | Write_Enable_P1_CCLK_fifo |
                     req_En_P0_CCLK | Write_Enable_P0_CCLK_fifo;
assign cpu2axi_ren = !cpu2axi_rempty && !axi2cpu_wfull;
assign cpu2axi_rdata_gate = (cpu2axi_ren) ? cpu2axi_rdata : '0;

asyc_FIFO #(.depath(16), .width(73), .SYNC_FF_NUM(3)) axi2cpu (
    .r_clk  (CCLK),
    .r_rst  (CRST),
    .w_clk  (ACLK),
    .w_rst  (ARST),
    .winc   (axi2cpu_wen),
    .wdata  (axi2cpu_wdata),
    .wfull  (axi2cpu_wfull),
    .rinc   (axi2cpu_ren),
    .rdata  (axi2cpu_rdata),
    .rempty (axi2cpu_rempty)
);

asyc_FIFO #(.depath(16), .width(160), .SYNC_FF_NUM(3)) cpu2axi (
    .r_clk  (ACLK),
    .r_rst  (ARST),
    .w_clk  (CCLK),
    .w_rst  (CRST),
    .winc   (cpu2axi_wen),
    .wdata  (cpu2axi_wdata),
    .wfull  (cpu2axi_wfull),
    .rinc   (cpu2axi_ren),
    .rdata  (cpu2axi_rdata),
    .rempty (cpu2axi_rempty)
);

`else

assign axi2cpu_wfull = '0;

assign req_En_P1_ACLK       = req_En_P1_CCLK;
assign RW_P1_ACLK           = RW_P1_CCLK;
assign Addr_P1_ACLK         = Addr_P1_CCLK;
assign size_P1_ACLK         = size_P1_CCLK;
assign len_P1_ACLK          = len_P1_CCLK;
assign WSTRB_P1_ACLK        = WSTRB_P1_CCLK;
assign BURST_P1_ACLK        = BURST_P1_CCLK;
assign Write_data_P1_ACLK   = Write_data_P1_CCLK;
assign Write_Enable_P1_ACLK = Write_Enable_P1_CCLK;

assign req_En_P0_ACLK       = req_En_P0_CCLK;
assign RW_P0_ACLK           = RW_P0_CCLK;
assign Addr_P0_ACLK         = Addr_P0_CCLK;
assign size_P0_ACLK         = size_P0_CCLK;
assign len_P0_ACLK          = len_P0_CCLK;
assign WSTRB_P0_ACLK        = WSTRB_P0_CCLK;
assign BURST_P0_ACLK        = BURST_P0_CCLK;
assign Write_data_P0_ACLK   = Write_data_P0_CCLK;
assign Write_Enable_P0_ACLK = Write_Enable_P0_CCLK;

assign RLAST_shacke0_CCLK   = RLAST_shacke0_ACLK;
assign B_shacke1_CCLK       = B_shacke1_ACLK;
assign RLAST_shacke1_CCLK   = RLAST_shacke1_ACLK;
assign response_P1_CCLK     = response_P1_ACLK;
assign Read_Enable_P1_CCLK  = Read_Enable_P1_ACLK;
assign read_data_P1_CCLK    = read_data_P1_ACLK;
assign WB_P1_CCLK           = WB_P1_ACLK;
assign response_P0_CCLK     = response_P0_ACLK;
assign Read_Enable_P0_CCLK  = Read_Enable_P0_ACLK;
assign read_data_P0_CCLK    = read_data_P0_ACLK;
assign WB_P0_CCLK           = WB_P0_ACLK;

`endif

//******************************
//             Plug
//******************************
CPU_plug u_cpu_plug (
    .ACLK            (CCLK),
    .ARESETn         (~CRST),

    .req_En_P0       (req_En_P0_CCLK),
    .RW_P0           (RW_P0_CCLK),
    .Addr_P0         (Addr_P0_CCLK),
    .Size_P0         (size_P0_CCLK),
    .Len_P0          (len_P0_CCLK),
    .WSTRB_P0        (WSTRB_P0_CCLK),
    .BURST_P0        (BURST_P0_CCLK),
    .response_P0     (response_P0_CCLK),

    .read_data_P0    (read_data_P0_CCLK),
    .Read_Enable_P0  (Read_Enable_P0_CCLK),
    .Write_data_P0   (Write_data_P0_CCLK),
    .Write_Enable_P0 (Write_Enable_P0_CCLK),
`ifdef cache
    .RLAST_M0        (RLAST_shacke0_CCLK),
`endif

    .req_En_P1       (req_En_P1_CCLK),
    .RW_P1           (RW_P1_CCLK),
    .Addr_P1         (Addr_P1_CCLK),
    .Size_P1         (size_P1_CCLK),
    .Len_P1          (len_P1_CCLK),
    .WSTRB_P1        (WSTRB_P1_CCLK),
    .BURST_P1        (BURST_P1_CCLK),
    .response_P1     (response_P1_CCLK),

    .read_data_P1    (read_data_P1_CCLK),
    .Read_Enable_P1  (Read_Enable_P1_CCLK),
    .Write_data_P1   (Write_data_P1_CCLK),
    .Write_Enable_P1 (Write_Enable_P1_CCLK),
    .WB_P1           (WB_P1_CCLK),
`ifdef cache
    .EXE_I_result    (EXE_I_result),
    .EXE_MEM_use     (EXE_MEM_use),
    .RLAST_M1        (RLAST_shacke1_CCLK),
    .BVALID_M1       (B_shacke1_CCLK),
`endif

    .PC_I            (PC_I),
    .stall_I         (stall_I),
    .instr           (instr),

    .Addr_D          (Addr_D),
    .BWEB_D          (BWEB_D),
    .WEB_D           (WEB_D),
    .read_data_D     (read_data_D),
    .store_data_D    (store_data_D),
    .CEB_D           (CEB_D),
    .stall_D         (stall_D),
    .stall_wfi       (stall_wfi)
);

CPU u_cpu (
    .clk               (CCLK),
    .rst               (CRST),

    .MEIP              (MEIP),
    .MTIP              (MTIP),
    .stall_wfi         (stall_wfi),
    .EXE_detect_wfi    (EXE_detect_wfi),
    .interrupt         (interrupt),
    .CPU_restore_pulse (CPU_restore_pulse),

    .PC                (PC_I),
    .stall_IM          (stall_I),
    .instr             (instr),

`ifdef cache
    .EXE_I_result      (EXE_I_result),
    .EXE_MEM_use       (EXE_MEM_use),
`endif
`ifdef CPU_PG
    .CPU_CG            (CPU_CG),
`endif

    .store_data        (store_data_D),
    .Addr              (Addr_D),
    .BWEB              (BWEB_D),
    .stall_DM          (stall_D),
    .read_data         (read_data_D),
    .CEB               (CEB_D),
    .WEB               (WEB_D),

    .MSIP              (1'b0),
    .SEIP              (1'b0),
    .STIP              (1'b0),
    .SSIP              (1'b0),
    .UEIP              (1'b0),
    .UTIP              (1'b0),
    .USIP              (1'b0)
);

//******************************
//     WFI unit
//******************************
WFI_unit u_WFI (
    .clk               (CCLK),
    .rst               (CRST),
    .wfi               (EXE_detect_wfi),
    .DVFS_v_step       (DVFS_v_step),
`ifdef CPU_PG
    .stall_D           (stall_D),
    .stall_I           (stall_I),
    .CPU_restore_pulse (CPU_restore_pulse),
    .CPU_CG            (CPU_CG),
`endif
    .interrupt         (interrupt),
    .stall_wfi         (stall_wfi)
);

endmodule