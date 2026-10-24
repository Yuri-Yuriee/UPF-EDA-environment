`timescale 1ps/1ps
module configurable_delay_chain_FIXED_STAGES20_CONFIG_STAGES32_MODE_W6 #(
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
