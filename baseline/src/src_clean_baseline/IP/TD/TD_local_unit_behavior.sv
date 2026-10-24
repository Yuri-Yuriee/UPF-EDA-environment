  `resetall
  `timescale 1ps/1ps

module TD_loacl_unit_FIXED_STAGES20_CONFIG_STAGES32_MODE_W6_CALIB_INIT_VALUE16 #(
    parameter integer FIXED_STAGES       = 20,
    parameter integer CONFIG_STAGES      = 32,
    parameter integer MODE_W             = 6,
`ifndef SYNTHESIS
    parameter real    SIM_CELL_DELAY_PS  = 200,
`endif
    parameter integer CALIB_INIT_VALUE   = 0
) (
    input  wire                  local_clk,
    input  wire                  local_rst,
    input  wire                  center_clk,
    input  wire                  center_rst,

    // center -> local request handshake
    input  wire                  calibration_valid_req,
    output wire                  calibration_ready_req,

    // local -> center response handshake
    output wire                  calibration_valid_resp,
    input  wire                  calibration_ready_resp,

    input  wire                  calibration_updown,

`ifndef SYNTHESIS
    // Simulation only: runtime variable cell delay from TB.
    // If sim_cell_delay_ps <= 0.0, SIM_CELL_DELAY_PS is used as fallback.
    input  real                  sim_cell_delay_ps,
`endif

    output wire                  TD_warning
);

    localparam integer TOTAL_STAGES = FIXED_STAGES + CONFIG_STAGES;
    localparam [MODE_W-1:0] CFG_MAX = CONFIG_STAGES[MODE_W-1:0];

    // Calibration initial point.
    // Clamp CALIB_INIT_VALUE into legal range: 0 ~ CONFIG_STAGES.
    localparam integer CFG_INIT_INT = (CALIB_INIT_VALUE < 0) ? 0 :
                                      (CALIB_INIT_VALUE > CONFIG_STAGES) ? CONFIG_STAGES :
                                                                           CALIB_INIT_VALUE;
    localparam [MODE_W-1:0] CFG_INIT = CFG_INIT_INT[MODE_W-1:0];

    reg [MODE_W-1:0] cnfg_p;

    wire toggle_q;
    wire toggle_qb;

    wire td_ref;
    assign td_ref = toggle_q;

    wire td_delay_out;

    wire warning_comb;
    wire TD_warning_local;

    wire l2c_winc;
    wire l2c_rinc;
    wire l2c_rempty;
    wire l2c_wfull;

    wire c2l_winc;
    wire c2l_rinc;
    wire c2l_rempty;
    wire c2l_wfull;

    wire resp_winc;
    wire resp_rinc;
    wire resp_rempty;
    wire resp_wfull;
    wire resp_rdata;

    wire calibration_valid_local;
    wire calibration_updown_local;

    wire l2c_rdata;

`ifndef SYNTHESIS
    real td_cell_delay_ps_eff_dbg;
    real td_total_delay_ps_dbg;

    always @(*) begin
        if (sim_cell_delay_ps > 0.0) begin
            td_cell_delay_ps_eff_dbg = sim_cell_delay_ps;
        end
        else begin
            td_cell_delay_ps_eff_dbg = SIM_CELL_DELAY_PS;
        end

        td_total_delay_ps_dbg = td_cell_delay_ps_eff_dbg * $itor(FIXED_STAGES + cnfg_p);
    end
`endif

    assign calibration_ready_req = ~c2l_wfull;

    // ============================================================
    // Toggle DFF
    // std cell: FILL_IN_CELL_DFF_ASYNC_SET_RESET_010
    // D = ~Q, so Q toggles every local_clk cycle
    // CDN is active low reset, local_rst is active high
    // ============================================================

    assign toggle_qb = ~toggle_q;
    (* dont_touch = "true" *)
    FILL_IN_CELL_DFF_ASYNC_SET_RESET_010 u_toggle_DFF (
        .D   (toggle_qb),
        .CP  (local_clk),
        .CDN (~local_rst),
        .SDN (1'b1),
        .Q   (toggle_q)
    );

    // ============================================================
    // Configurable delay chain
    //
    // SYNTHESIS:
    //   delay_cell uses the real FILL_IN_CELL_DELAY_011 cell.
    //
    // SIMULATION:
    //   delay_cell uses runtime variable per-cell delay from
    //   sim_cell_delay_ps. The mux/chain structure is still preserved;
    //   we do not replace the whole chain with one total-delay assignment.
    // ============================================================

    configurable_delay_chain #(
        .FIXED_STAGES      (FIXED_STAGES),
        .CONFIG_STAGES     (CONFIG_STAGES),
        .MODE_W            (MODE_W)
`ifndef SYNTHESIS
        ,
        .SIM_CELL_DELAY_PS (SIM_CELL_DELAY_PS)
`endif
    ) u_delay (
        .din            (td_ref),
        .cfg_delay_mode (cnfg_p),
`ifndef SYNTHESIS
        .sim_cell_delay_ps (sim_cell_delay_ps),
`endif
        .dout           (td_delay_out)
    );

    assign warning_comb = td_ref ^ td_delay_out;

    // ============================================================
    // Warning DFF
    // ============================================================
    (* dont_touch = "true" *)
    FILL_IN_CELL_DFF_ASYNC_SET_RESET_010 u_warning_DFF (
        .D   (warning_comb),
        .CP  (local_clk),
        .CDN (~local_rst),
        .SDN (1'b1),
        .Q   (TD_warning_local)
    );

    // ============================================================
    // FIFO local -> center
    // ============================================================

    assign l2c_winc = TD_warning_local & ~l2c_wfull;
    assign l2c_rinc = ~l2c_rempty;
    assign TD_warning = (l2c_rempty) ? '0 : l2c_rdata;

    asyc_FIFO #(
        .width  (1),
        .depath (8)
    ) u_l2c_fifo (
        .w_clk   (local_clk),
        .w_rst   (local_rst),
        .r_clk   (center_clk),
        .r_rst   (center_rst),

        .wdata   (TD_warning_local),
        .winc    (l2c_winc),

        .rinc    (l2c_rinc),
        .rdata   (l2c_rdata),

        .rempty  (l2c_rempty),
        .wfull   (l2c_wfull)
    );

    // ============================================================
    // FIFO center -> local request
    //
    // Request handshake:
    //   center domain:
    //      calibration_valid_req && calibration_ready_req
    //
    // Local domain:
    //      one request is consumed only when the response FIFO has space,
    //      so every accepted calibration update can return one response.
    // ============================================================

    assign c2l_winc = calibration_valid_req & calibration_ready_req;
    assign c2l_rinc = (~c2l_rempty) & (~resp_wfull);

    assign calibration_valid_local = c2l_rinc;

    asyc_FIFO #(
        .width  (1),
        .depath (4)
    ) u_c2l_req_fifo (
        .w_clk   (center_clk),
        .w_rst   (center_rst),
        .r_clk   (local_clk),
        .r_rst   (local_rst),

        .wdata   (calibration_updown),
        .winc    (c2l_winc),

        .rinc    (c2l_rinc),
        .rdata   (calibration_updown_local),

        .rempty  (c2l_rempty),
        .wfull   (c2l_wfull)
    );

    // ============================================================
    // FIFO local -> center response
    //
    // Response handshake:
    //   center domain:
    //      calibration_valid_resp && calibration_ready_resp
    //
    // A response means the local unit has consumed one request and
    // updated cnfg_p once.
    // ============================================================

    assign resp_winc = calibration_valid_local;

    assign calibration_valid_resp = ~resp_rempty;
    assign resp_rinc              = calibration_valid_resp & calibration_ready_resp;

    asyc_FIFO #(
        .width  (1),
        .depath (4)
    ) u_l2c_resp_fifo (
        .w_clk   (local_clk),
        .w_rst   (local_rst),
        .r_clk   (center_clk),
        .r_rst   (center_rst),

        .wdata   (1'b1),
        .winc    (resp_winc),

        .rinc    (resp_rinc),
        .rdata   (resp_rdata),

        .rempty  (resp_rempty),
        .wfull   (resp_wfull)
    );

    // ============================================================
    // Local config update
    // calibration_updown_local = 1 -> increase delay
    // calibration_updown_local = 0 -> decrease delay
    // ============================================================

    always @(posedge local_clk or posedge local_rst) begin
        if (local_rst) begin
            cnfg_p <= CFG_INIT;
        end
        else if (calibration_valid_local) begin
            if (calibration_updown_local) begin
                if (cnfg_p < CFG_MAX) begin
                    cnfg_p <= cnfg_p + {{(MODE_W-1){1'b0}}, 1'b1};
                end
                else begin
                    cnfg_p <= cnfg_p;
                end
            end
            else begin
                if (cnfg_p != {MODE_W{1'b0}}) begin
                    cnfg_p <= cnfg_p - {{(MODE_W-1){1'b0}}, 1'b1};
                end
                else begin
                    cnfg_p <= cnfg_p;
                end
            end
        end
    end

`ifndef SYNTHESIS

    reg TD_warning_local_d;

    always @(posedge local_clk or posedge local_rst) begin
        if (local_rst) begin
            TD_warning_local_d <= 1'b0;
        end
        else begin
            TD_warning_local_d <= TD_warning_local;
        end
    end

    /*always @(posedge local_clk) begin
        if (!local_rst) begin
            if (TD_warning_local && !TD_warning_local_d) begin
                $display("[%0t ps] [TD_LOCAL WARNING] cnfg_p=%0d, delay_cells=%0d, fixed=%0d, configurable=%0d, total_max=%0d, cell_delay_ps=%0.3f, total_delay_ps=%0.3f",
                         $time,
                         cnfg_p,
                         FIXED_STAGES + cnfg_p,
                         FIXED_STAGES,
                         cnfg_p,
                         TOTAL_STAGES,
                         td_cell_delay_ps_eff_dbg,
                         td_total_delay_ps_dbg);
            end

            if (calibration_valid_local) begin
                if (calibration_updown_local) begin
                    $display("[%0t ps] [TD_LOCAL CALIBRA] UP   old_cnfg=%0d, new_cnfg=%0d, old_delay_cells=%0d, new_delay_cells=%0d, cell_delay_ps=%0.3f",
                             $time,
                             cnfg_p,
                             (cnfg_p < CFG_MAX) ? cnfg_p + 1'b1 : cnfg_p,
                             FIXED_STAGES + cnfg_p,
                             (cnfg_p < CFG_MAX) ? FIXED_STAGES + cnfg_p + 1'b1 : FIXED_STAGES + cnfg_p,
                             td_cell_delay_ps_eff_dbg);
                end
                else begin
                    $display("[%0t ps] [TD_LOCAL CALIBRA] DOWN old_cnfg=%0d, new_cnfg=%0d, old_delay_cells=%0d, new_delay_cells=%0d, cell_delay_ps=%0.3f",
                             $time,
                             cnfg_p,
                             (cnfg_p != {MODE_W{1'b0}}) ? cnfg_p - 1'b1 : cnfg_p,
                             FIXED_STAGES + cnfg_p,
                             (cnfg_p != {MODE_W{1'b0}}) ? FIXED_STAGES + cnfg_p - 1'b1 : FIXED_STAGES + cnfg_p,
                             td_cell_delay_ps_eff_dbg);
                end
            end
        end
    end*/

`endif

endmodule


`timescale 1ps/1ps
module configurable_delay_chain #(
    parameter integer FIXED_STAGES      = 4,   // 固定一定會經過的 delay cell 數量
    parameter integer CONFIG_STAGES     = 32,  // 可調整的 delay cell 數量
    parameter integer MODE_W            = 6,
    parameter integer SIM_CELL_DELAY_PS = 200
)(
    input  wire                          din,
    input  wire [MODE_W-1:0]             cfg_delay_mode,
`ifndef SYNTHESIS
    input  real                          sim_cell_delay_ps,
`endif
    output wire                          dout
);

    localparam integer TOTAL_STAGES = FIXED_STAGES + CONFIG_STAGES;

    (* keep = "true", dont_touch = "true" *)
    wire [TOTAL_STAGES:0] chain;

    assign chain[0] = din;

    genvar i;
    generate
        for (i = 0; i < TOTAL_STAGES; i = i + 1) begin : GEN_DELAY_CHAIN
            (* keep = "true", dont_touch = "true" *)
            delay_cell #(
`ifndef SYNTHESIS
                .SIM_CELL_DELAY_PS(SIM_CELL_DELAY_PS)
`endif
            ) u_delay_cell (
                .din  (chain[i]),
`ifndef SYNTHESIS
                .sim_cell_delay_ps (sim_cell_delay_ps),
`endif
                .dout (chain[i+1])
            );
        end
    endgenerate

    reg dout_mux;
    integer m;

    always @(*) begin
        dout_mux = chain[TOTAL_STAGES];

        for (m = 0; m <= CONFIG_STAGES; m = m + 1) begin
            if (cfg_delay_mode == m[MODE_W-1:0]) begin
                dout_mux = chain[FIXED_STAGES + cfg_delay_mode];
            end
        end
    end

    assign dout = dout_mux;

endmodule


module delay_cell #(
`ifndef SYNTHESIS
    parameter integer SIM_CELL_DELAY_PS = 200
`endif
) (
    input  wire din,
`ifndef SYNTHESIS
    input  real sim_cell_delay_ps,
`endif
    output wire dout
);

`ifdef SYNTHESIS
(* dont_touch = "true" *)
    FILL_IN_CELL_DELAY_011 u_delay (
        .I (din),
        .Z (dout)
    );
`else
    reg  dout_sim;
    real cell_delay_ps_eff;

    always @(*) begin
        if (sim_cell_delay_ps > 0.0) begin
            cell_delay_ps_eff = sim_cell_delay_ps;
        end
        else begin
            cell_delay_ps_eff = SIM_CELL_DELAY_PS;
        end
    end

    always @(din or cell_delay_ps_eff) begin
        dout_sim <= #(cell_delay_ps_eff) din;
    end

    assign dout = dout_sim;
`endif

endmodule
