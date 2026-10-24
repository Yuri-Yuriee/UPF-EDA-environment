`timescale 1ps/1ps

module PMU #(
    parameter integer TD_NUM  = 1,
    parameter integer TD_BITS = 1,

    parameter integer FIXED_STAGES      = 20,
    parameter integer CONFIG_STAGES     = 32,
    parameter integer MODE_W            = 6,
`ifndef SYNTHESIS
    parameter real    SIM_CELL_DELAY_PS = 200.0,
`endif
    parameter integer CALIB_INIT_VALUE  = 16,

    parameter integer V_STAGE      = 4,
    parameter integer F_STAGE      = 4,
    parameter integer V_FINE_STAGE = 32
)(
    input  logic clk,
    input  logic rst,

    input logic ACLK_rst,
    input logic ROM_rst,
    input logic cpu_clk_i_rst,
    input logic DRAM_rst,

    input  logic local_clk,
    input  logic local_rst,

    input  logic ACLK,
    input  logic ROM_clk,
    input  logic cpu_clk_i,
    input  logic DRAM_clk,

    output logic cpu_clk_o,
    output logic [1:0] v_ctrl_idx,
    output logic [1:0] v_ctrl,

    output logic [((V_STAGE <= 1) ? 1 : $clog2(V_STAGE))-1:0] DVFS_v_step,

    // TD_center MMIO slave
    axi_read_if.slave   center_axi_r_s,
    axi_write_if.slave  center_axi_w_s,

    // DVFS MMIO slave
    axi_read_if.slave   dvfs_axi_r_s,
    axi_write_if.slave  dvfs_axi_w_s,

    // TD_center DMA master
    axi_read_if.master  dma_axi_r_m,
    axi_write_if.master dma_axi_w_m,
    
    // ============================================================
    // System / test result signal
    // TB 原本有直接控制 sys_error，所以這裡做成 input
    // ============================================================
    input  logic sys_error,
    output logic TD_interrupt,

    // ============================================================
    // TB debug / force warning 用
    // 如果不想用 force warning：
    // use_force_warning = 1'b0
    // TD_warning_force  = '0
    // ============================================================
    input  logic              use_force_warning,
    input  logic [TD_NUM-1:0] TD_warning_force,

`ifndef SYNTHESIS
    input  real sim_cell_delay_ps,
`endif

    // ============================================================
    // Debug output
    // 讓原本 TB 的 monitor 可以繼續看這些訊號
    // ============================================================
    output logic [TD_NUM-1:0] TD_warning_from_local,
    output logic [TD_NUM-1:0] TD_warning_to_center,

    output logic [TD_NUM-1:0] calibration_valid_req,
    output logic [TD_NUM-1:0] calibration_ready_req,
    output logic [TD_NUM-1:0] calibration_valid_resp,
    output logic [TD_NUM-1:0] calibration_ready_resp,
    output logic [TD_NUM-1:0] calibration_updown,

    output logic DVFS_req,
    output logic DVFS_resp,
    output logic DVFS_F_max,
    output logic DVFS_F_min,
    output logic DVFS_V_tune
);

    assign TD_warning_to_center = use_force_warning
                                ? TD_warning_force
                                : TD_warning_from_local;

    // ============================================================
    // TD center
    // ============================================================
    TD_center_unit #(
        .TD_NUM  (TD_NUM),
        .TD_BITS (TD_BITS)
    ) u_center (
        .clk                    (clk),
        .rst                    (rst),

        .TD_warning             (TD_warning_to_center),

        .calibration_valid_req  (calibration_valid_req),
        .calibration_ready_req  (calibration_ready_req),
        .calibration_valid_resp (calibration_valid_resp),
        .calibration_ready_resp (calibration_ready_resp),
        .calibration_updown     (calibration_updown),

        .DVFS_req               (DVFS_req),
        .DVFS_resp              (DVFS_resp),
        .DVFS_F_max             (DVFS_F_max),
        .DVFS_F_min             (DVFS_F_min),
        .DVFS_V_tune            (DVFS_V_tune),

        .axi_r_m                (dma_axi_r_m),
        .axi_w_m                (dma_axi_w_m),

        .axi_r_s                (center_axi_r_s),
        .axi_w_s                (center_axi_w_s),

        .sys_error              (sys_error),
        .TD_interrupt           (TD_interrupt)
    );

    // ============================================================
    // TD local units
    // 現在支援 TD_NUM 個 local unit
    // TD_NUM = 1 時就等同你原本的 u_td_local0
    // ============================================================
    genvar td_i;

    generate
        for (td_i = 0; td_i < TD_NUM; td_i = td_i + 1) begin : gen_td_local

            TD_loacl_unit #(
                .FIXED_STAGES      (FIXED_STAGES),
                .CONFIG_STAGES     (CONFIG_STAGES),
                .MODE_W            (MODE_W),
            `ifndef SYNTHESIS
                .SIM_CELL_DELAY_PS (SIM_CELL_DELAY_PS),
            `endif
                .CALIB_INIT_VALUE  (CALIB_INIT_VALUE)
            ) u_td_local (
                .local_clk              (local_clk),
                .local_rst              (local_rst),

                .center_clk             (clk),
                .center_rst             (rst),

                .calibration_valid_req  (calibration_valid_req[td_i]),
                .calibration_ready_req  (calibration_ready_req[td_i]),
                .calibration_valid_resp (calibration_valid_resp[td_i]),
                .calibration_ready_resp (calibration_ready_resp[td_i]),

                .calibration_updown     (calibration_updown[td_i]),

`ifndef SYNTHESIS
                .sim_cell_delay_ps      (sim_cell_delay_ps),
`endif

                .TD_warning             (TD_warning_from_local[td_i])
            );

        end
    endgenerate

    // ============================================================
    // DVFS unit
    // ============================================================
    DVFS_unit #(
        .v_stage       (V_STAGE),
        .f_stage       (F_STAGE),
        .V_fine_stage  (V_FINE_STAGE),
        .TD_NUM        (TD_NUM)
    ) u_dvfs (
        .clk           (clk),
        .rst           (rst),
        .ACLK_rst      (ACLK_rst),
        .ROM_rst       (ROM_rst),
        .cpu_clk_i_rst (cpu_clk_i_rst),
        .DRAM_rst      (DRAM_rst),

        .ACLK          (ACLK),
        .ROM_clk       (ROM_clk),
        .cpu_clk_i     (cpu_clk_i),
        .DRAM_clk      (DRAM_clk),

        .cpu_clk_o     (cpu_clk_o),
        .v_ctrl_idx    (v_ctrl_idx),
        .v_ctrl        (v_ctrl),

        .DVFS_v_step_o (DVFS_v_step),

        .axi_r_s       (dvfs_axi_r_s),
        .axi_w_s       (dvfs_axi_w_s),

        .DVFS_req      (DVFS_req),
        .DVFS_resp     (DVFS_resp),
        .DVFS_F_max    (DVFS_F_max),
        .DVFS_F_min    (DVFS_F_min),
        .DVFS_V_tune   (DVFS_V_tune)
    );

endmodule