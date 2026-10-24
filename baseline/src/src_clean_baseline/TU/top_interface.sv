module top #(
    localparam integer AXI_MASTER_NUM = 4,
    localparam integer AXI_SLAVE_NUM  = 9,
    localparam integer PLIC_SRC_NUM = 2,
    parameter integer TD_NUM  = 1,
    parameter integer TD_BITS = 1,

    parameter integer FIXED_STAGES      = 20,
    parameter integer CONFIG_STAGES     = 32,
    parameter integer MODE_W            = 6,
    parameter integer CALIB_INIT_VALUE  = 16,

    parameter integer V_STAGE      = 4,
    parameter integer F_STAGE      = 4,
    parameter integer V_FINE_STAGE = 32,

    // DRAMSys simulation parameters. DRAMSYS_BASE_ADDR can also be
    // overridden at runtime with +DRAMSYS_BASE_ADDR=<hex>.
    parameter logic [31:0] DRAMSYS_BASE_ADDR = 32'h2000_0000,
    parameter              DRAMSYS_TYPE      = "DDR4",
    parameter              DRAMSYS_CONFIG    = "none"
)(
    input  logic           cpu_clk,
    input  logic           axi_clk,
    input  logic           rom_clk,
    input  logic           dram_clk,
    input  logic           cpu_rst,
    input  logic           axi_rst,
    input  logic           rom_rst,
    input  logic           dram_rst,


    input  logic [31:0] ROM_out,
    input  logic        DRAM_valid,
    input  logic [31:0] DRAM_Q,

    output logic        ROM_read,
    output logic        ROM_enable,
    output logic [11:0] ROM_address,

    output logic        DRAM_CSn,
    output logic [3:0]  DRAM_WEn,
    output logic        DRAM_RASn,
    output logic        DRAM_CASn,
    output logic [10:0] DRAM_A,
    output logic [31:0] DRAM_D,

    output logic [1:0] v_ctrl_idx,
    output logic [1:0] v_ctrl

);

// =====================================================
// AXI Interfaces (Master side)  <-- 改成 array (合法！)
// =====================================================
axi_read_if  axi_r_m[AXI_MASTER_NUM] ();
axi_write_if axi_w_m[AXI_MASTER_NUM] ();


// =====================================================
// AXI Interfaces (Slave side)  <-- 改成 array
// =====================================================
axi_read_if  axi_r_s[AXI_SLAVE_NUM] ();
axi_write_if axi_w_s[AXI_SLAVE_NUM] ();


// =====================================================
// AXI Interconnect
// =====================================================
logic        pmu_cpu_clk_o;

logic        axi_rst_sync;
logic        cclk_rst_sync;
logic        dram_rst_sync;
logic        rom_rst_sync;
logic        cpu_rst_sync;

wire ACLK, ARST;
wire CCLK, CRST;
wire clk, WDT_clk;
wire rst, WDT_rst;
assign clk = axi_clk;
assign rst = axi_rst;
assign WDT_clk = rom_clk;
assign WDT_rst = rom_rst;
`ifdef multi_clk
    assign ACLK = axi_clk;
    assign ARST = axi_rst;
    assign CCLK = cpu_clk;
    assign CRST = cpu_rst;
`else
    //wire ACLK, CCLK;
    assign CCLK = clk;
    assign ACLK = clk;
    assign CRST = rst;
    assign ARST = rst;
`endif


// =====================================================
// Reset Synchronizers
// Async assertion / synchronous deassertion
// =====================================================
reset_sync u_axi_reset_sync (
    .clk_i  (ACLK),
    .arst_i (ARST),
    .rst_o  (axi_rst_sync)
);

reset_sync u_cclk_reset_sync (
    .clk_i  (CCLK),
    .arst_i (CRST),
    .rst_o  (cclk_rst_sync)
);

reset_sync u_dram_reset_sync (
    .clk_i  (dram_clk),
    .arst_i (dram_rst),
    .rst_o  (dram_rst_sync)
);

reset_sync u_rom_reset_sync (
    .clk_i  (rom_clk),
    .arst_i (rom_rst),
    .rst_o  (rom_rst_sync)
);

reset_sync u_cpu_reset_sync (
    .clk_i  (pmu_cpu_clk_o),
    .arst_i (CRST),
    .rst_o  (cpu_rst_sync)
);


logic DMA_interrupt, WDT_interrupt;
logic WDT_interrupt_src_ff;
(* ASYNC_REG = "TRUE" *) logic WDT_interrupt_sync_ff1;
(* ASYNC_REG = "TRUE" *) logic WDT_interrupt_sync_ff2;
logic WDT_interrupt_cpu;
logic TD_interrupt;
logic PLIC_interrupt;
logic [$clog2(PLIC_SRC_NUM+1)-1:0] PLIC_irq_id;



logic [((V_STAGE <= 1) ? 1 : $clog2(V_STAGE))-1:0] DVFS_v_step;


AXI #(
    .Master(AXI_MASTER_NUM),
    .Slave(AXI_SLAVE_NUM)
) AXI (
    .ACLK     (ACLK),
    .ARESETn  (~axi_rst_sync),

    .axi_r_m  (axi_r_m),   // <-- 此處直接接 array，不用 '{}
    .axi_w_m  (axi_w_m),   // M0 read-only → axi_w_m[0] 不使用即可

    .axi_r_s  (axi_r_s),
    .axi_w_s  (axi_w_s)
);

assign  axi_w_m[0].AWID_m    = '0;
assign  axi_w_m[0].AWADDR_m  = '0;
assign  axi_w_m[0].AWLEN_m   = '0;
assign  axi_w_m[0].AWSIZE_m  = '0;
assign  axi_w_m[0].AWBURST_m = '0;
assign  axi_w_m[0].AWVALID_m = 1'b0;

assign  axi_w_m[0].WDATA_m   = '0;
assign  axi_w_m[0].WSTRB_m   = '0;
assign  axi_w_m[0].WLAST_m   = 1'b0;
assign  axi_w_m[0].WVALID_m  = 1'b0;

assign  axi_w_m[0].BREADY_m  = 1'b0;

// Slave side
assign  axi_w_s[2].AWREADY_s = 1'b0;
assign  axi_w_s[2].WREADY_s  = 1'b0;
assign  axi_w_s[2].BID_s     = '0;
assign  axi_w_s[2].BRESP_s   = '0;
assign  axi_w_s[2].BVALID_s  = 1'b0;

assign  axi_r_s[4].ARREADY_s = 1'b0;
assign  axi_r_s[4].RID_s     = '0;
assign  axi_r_s[4].RDATA_s   = '0;
assign  axi_r_s[4].RRESP_s   = '0;
assign  axi_r_s[4].RLAST_s   = 1'b0;
assign  axi_r_s[4].RVALID_s  = 1'b0;

assign  axi_r_s[5].ARREADY_s = 1'b0;
assign  axi_r_s[5].RID_s     = '0;
assign  axi_r_s[5].RDATA_s   = '0;
assign  axi_r_s[5].RRESP_s   = '0;
assign  axi_r_s[5].RLAST_s   = 1'b0;
assign  axi_r_s[5].RVALID_s  = 1'b0;


// =====================================================
// WDT interrupt synchronizer
// =====================================================
always_ff @(posedge ACLK or posedge axi_rst_sync) begin
    if (axi_rst_sync) begin
        WDT_interrupt_src_ff <= 1'b0;
    end
    else begin
        WDT_interrupt_src_ff <= WDT_interrupt;
    end
end

always_ff @(posedge pmu_cpu_clk_o or posedge cpu_rst_sync) begin
    if (cpu_rst_sync) begin
        WDT_interrupt_sync_ff1 <= 1'b0;
        WDT_interrupt_sync_ff2 <= 1'b0;
    end
    else begin
        WDT_interrupt_sync_ff1 <= WDT_interrupt_src_ff;
        WDT_interrupt_sync_ff2 <= WDT_interrupt_sync_ff1;
    end
end

assign WDT_interrupt_cpu = WDT_interrupt_sync_ff2;


// =====================================================
// CPU wrapper
// =====================================================


CPU_wrapper u_cpu (
    .MEIP(PLIC_interrupt),
    .MTIP(WDT_interrupt_cpu),

    .axi_r_m0 (axi_r_m[0].master),
    .axi_r_m1 (axi_r_m[1].master),
    .axi_w_m1 (axi_w_m[1].master),

    .CCLK(pmu_cpu_clk_o),
    .CRST(cpu_rst_sync),
    .ACLK(ACLK),
    .ARESETn(~axi_rst_sync),
    .DVFS_v_step(DVFS_v_step)
);


// =====================================================
// DMA master + DMA config slave
// =====================================================
DMA_1 u_dma (
    .axi_r_m (axi_r_m[2].master),
    .axi_w_m (axi_w_m[2].master),

    .axi_w_s (axi_w_s[4].slave),   // DMA config registers

    .DMA_interrupt(DMA_interrupt),

    .ACLK(ACLK),
    .ARESETn(~axi_rst_sync)
);


// =====================================================
// ROM (read-only slave)
// =====================================================
ROM_1 u_rom (

    .rom_clk(rom_clk),
    .rom_rst(rom_rst_sync),

    .axi_r_s (axi_r_s[2].slave),

    .ROM_out(ROM_out),
    .ROM_read(ROM_read),
    .ROM_enable(ROM_enable),
    .ROM_address(ROM_address),

    .ACLK(ACLK),
    .ARESETn(~axi_rst_sync)
);


// =====================================================
// DRAM controller / DRAMSys simulation model
// =====================================================
`ifdef DRAMSYS

// DRAMSys works at AXI transaction level, so the original pin-level DRAM
// controller is bypassed only in this simulation mode.
DRAMSys_wrap #(
    .BASE_ADDR     (DRAMSYS_BASE_ADDR),
    .DRAM_TYPE     (DRAMSYS_TYPE),
    .CUSTOMER_DRAM (DRAMSYS_CONFIG)
) u_dram (
    .ACLK     (ACLK),
    .ARESETn  (~axi_rst_sync),
    .axi_r_s  (axi_r_s[3].slave),
    .axi_w_s  (axi_w_s[3].slave)
);

// Keep the unchanged CHIP I/O quiet while the pin-level interface is bypassed.
assign DRAM_CSn  = 1'b1;
assign DRAM_WEn  = 4'hF;
assign DRAM_RASn = 1'b1;
assign DRAM_CASn = 1'b1;
assign DRAM_A    = '0;
assign DRAM_D    = '0;

`else

DRAM_wrap_my u_dram (
    .ACLK(ACLK),
    .ARESETn(~axi_rst_sync),
    .dram_clk(dram_clk),
    .dram_rst(dram_rst_sync),

    .axi_r_s(axi_r_s[3].slave),
    .axi_w_s(axi_w_s[3].slave),

    .Q(DRAM_Q),
    .VALID(DRAM_valid),

    .CSn(DRAM_CSn),
    .WEn(DRAM_WEn),
    .RASn(DRAM_RASn),
    .CASn(DRAM_CASn),
    .A(DRAM_A),
    .D(DRAM_D)
);

`endif


// =====================================================
// WDT (write-only slave)
// =====================================================
WDT_wrapper u_WDT_wrapper (
    .axi_w_s (axi_w_s[5].slave),

    .clk2(WDT_clk),
    .rst2(rom_rst_sync),

    .WDT_interrupt(WDT_interrupt),

    .ACLK(ACLK),
    .ARESETn(~axi_rst_sync)
);


// =====================================================
// Instruction Memory
// =====================================================
SRAM_wrapper IM1 (
    .axi_r_s (axi_r_s[0].slave),
    .axi_w_s (axi_w_s[0].slave),

    .ACLK(ACLK),
    .ARESETn(~axi_rst_sync)
);


// =====================================================
// Data Memory
// =====================================================
SRAM_wrapper DM1 (
    .axi_r_s (axi_r_s[1].slave),
    .axi_w_s (axi_w_s[1].slave),

    .ACLK(ACLK),
    .ARESETn(~axi_rst_sync)
);




// =====================================================
// PMU internal signals
// =====================================================
localparam integer PMU_TD_NUM  = 1;
localparam integer PMU_TD_BITS = 1;


`ifndef SYNTHESIS
real pmu_sim_cell_delay_ps;

initial begin
    pmu_sim_cell_delay_ps = 200.0;
end
`endif
// =====================================================
// PMU
// S7 = TD_center MMIO
// S8 = DVFS MMIO
// M3 = PMU DMA master
// =====================================================
PMU #(
    .TD_NUM             (PMU_TD_NUM),
    .TD_BITS            (PMU_TD_BITS),

    .FIXED_STAGES       (20),
    .CONFIG_STAGES      (32),
    .MODE_W             (6),
`ifndef SYNTHESIS
    .SIM_CELL_DELAY_PS  (200.0),
`endif
    .CALIB_INIT_VALUE   (16),

    .V_STAGE            (4),
    .F_STAGE            (4),
    .V_FINE_STAGE       (32)
) u_pmu (
    .clk                (ACLK),
    .rst                (axi_rst_sync),

    .ACLK_rst           (axi_rst_sync),
    .ROM_rst            (rom_rst_sync),
    .cpu_clk_i_rst      (cclk_rst_sync),
    .DRAM_rst           (dram_rst_sync),

    .local_clk          (CCLK),
    .local_rst          (cclk_rst_sync),

    .ACLK               (ACLK),
    .ROM_clk            (rom_clk),
    .cpu_clk_i          (CCLK),
    .DRAM_clk           (dram_clk),

    .cpu_clk_o          (pmu_cpu_clk_o),
    .v_ctrl_idx         (v_ctrl_idx),
    .v_ctrl             (v_ctrl),

    // PMU TD_center MMIO slave
    .center_axi_r_s     (axi_r_s[7].slave),
    .center_axi_w_s     (axi_w_s[7].slave),

    // PMU DVFS MMIO slave
    .dvfs_axi_r_s       (axi_r_s[8].slave),
    .dvfs_axi_w_s       (axi_w_s[8].slave),

    // PMU DMA master
    .dma_axi_r_m        (axi_r_m[3].master),
    .dma_axi_w_m        (axi_w_m[3].master),

    // 目前 top 沒有 sys_error source，先 tie 0
    .sys_error          (1'b0),
    .TD_interrupt       (TD_interrupt),

    // top 不用 TB force warning
    .use_force_warning  (1'b0),
    .TD_warning_force   ('0),

    .DVFS_v_step        (DVFS_v_step),

`ifndef SYNTHESIS
    .sim_cell_delay_ps  (pmu_sim_cell_delay_ps),
`endif

    // debug ports，不用就 open
    .TD_warning_from_local     (),
    .TD_warning_to_center      (),

    .calibration_valid_req     (),
    .calibration_ready_req     (),
    .calibration_valid_resp    (),
    .calibration_ready_resp    (),
    .calibration_updown        (),

    .DVFS_req           (),
    .DVFS_resp          (),
    .DVFS_F_max         (),
    .DVFS_F_min         (),
    .DVFS_V_tune        ()
);

// =====================================================
// PLIC
// =====================================================
simple_plic #(
    .SRC_NUM(PLIC_SRC_NUM),
    .PRIO_W(3),
    .DEFAULT_PRIORITY(1),
    .BASE_ADDR(32'h3C00_0000)
) u_plic (
    .clk      (ACLK),
    .rst_n    (~axi_rst_sync),
    .cpu_clk  (pmu_cpu_clk_o),
    .cpu_rst_n(~cpu_rst_sync),

    // irq_i[0] = source ID 1 = DMA interrupt
    // irq_i[1] = source ID 2 = PMU TD interrupt
    .irq_i    ({TD_interrupt, DMA_interrupt}),

    .irq_o    (PLIC_interrupt),
    .irq_id_o (PLIC_irq_id),

    .axi_r    (axi_r_s[6].slave),
    .axi_w    (axi_w_s[6].slave)
);


endmodule
