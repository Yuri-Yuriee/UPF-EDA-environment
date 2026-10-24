`ifndef DVFS_MODE_SETUP_REG
`define DVFS_MODE_SETUP_REG
`define DVFS_mode_setup_reg     32'h0000_0000
`define DVFS_ultra_reg          32'h0000_0004
`define DVFS_v_step_reg         32'h0000_0008
`define DVFS_f_step_reg         32'h0000_000C




`endif


// ============================================================
// Two-flop CDC synchronizer for single-bit level signals.
// The source signal must remain stable long enough to be sampled.
// For pulses shorter than one destination-clock period, use a
// request/acknowledge handshake or pulse-toggle synchronizer instead.
// ============================================================
module dvfs_cdc_sync_2ff #(
    parameter logic RESET_VALUE = 1'b0
) (
    input  logic clk,
    input  logic rst,
    input  logic d_async,
    output logic q_sync
);

    (* async_reg = "true", dont_touch = "true" *) logic sync_ff1;
    (* async_reg = "true", dont_touch = "true" *) logic sync_ff2;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            sync_ff1 <= RESET_VALUE;
            sync_ff2 <= RESET_VALUE;
        end
        else begin
            sync_ff1 <= d_async;
            sync_ff2 <= sync_ff1;
        end
    end

    assign q_sync = sync_ff2;

endmodule

// ============================================================
// DVFS_unit
//
// Clock source map when f_stage = 4. Index is slow -> fast:
//   DVFS_f_step = 0 : ROM_clk   // slowest
//   DVFS_f_step = 1 : DRAM_clk
//   DVFS_f_step = 2 : ACLK      // AXI clock
//   DVFS_f_step = 3 : cpu_clk_i // fastest
//
// Fast -> slow order is:
//   cpu_clk_i -> ACLK -> DRAM_clk -> ROM_clk
//
// Off-chip fine voltage control:
//   v_ctrl[1]     = valid pulse
//   v_ctrl[0]     = direction, 1 = fine up, 0 = fine down
//   v_ctrl_idx    = fine-control index paired with v_ctrl
//
// On-chip coarse voltage control:
//   DVFS_v_step_o = coarse voltage step index for power-switch control
//
// Define USE_FOUNDRY_DVFS_CELLS if FILL_IN_CELL_CLOCK_MUX_008 and
// FILL_IN_CELL_ICG_009 are available in your simulation/synthesis library.
// Otherwise this file uses a synthesizable behavioral mux/ICG fallback.
// ============================================================

module DVFS_unit #(
    parameter integer v_stage       = 4,
    parameter integer f_stage       = 4,
    parameter integer V_fine_stage  = 32,
    parameter integer TD_NUM        = 1
) (
    input   logic   clk,
    input   logic   rst,
    input   logic   ACLK,
    input   logic   ROM_clk,
    input   logic   cpu_clk_i,
    input   logic   DRAM_clk,

    // Resets already synchronized to their corresponding clock domains.
    input   logic   ACLK_rst,
    input   logic   ROM_rst,
    input   logic   cpu_clk_i_rst,
    input   logic   DRAM_rst,

    output  logic   cpu_clk_o,

    // to off-chip fine voltage controller
    output  logic [1:0] v_ctrl_idx,
    output  logic [1:0] v_ctrl,

    // to on-chip coarse voltage / power-switch controller
    output  logic [((v_stage <= 1) ? 1 : $clog2(v_stage))-1:0] DVFS_v_step_o,

    // AXI
    axi_read_if.slave   axi_r_s,
    axi_write_if.slave  axi_w_s,

    // from center
    input   logic   DVFS_req,
    output  logic   DVFS_resp,
    input   logic   DVFS_F_max,
    input   logic   DVFS_F_min,
    input   logic   DVFS_V_tune     // 1: fine up, 0: fine down when DVFS_req=1 and no F command
);

localparam integer f_sel_bits    = (f_stage      <= 1) ? 1 : $clog2(f_stage);
localparam integer v_sel_bits    = (v_stage      <= 1) ? 1 : $clog2(v_stage);
localparam integer vf_sel_bits   = (V_fine_stage <= 1) ? 1 : $clog2(V_fine_stage);

localparam logic [f_sel_bits-1:0]  F_MAX_SEL  = f_stage - 1;
localparam logic [v_sel_bits-1:0]  V_MAX_SEL  = v_stage - 1;
localparam logic [vf_sel_bits-1:0] VF_MAX_SEL = V_fine_stage - 1;

// ==================
//      MMIO regs
// ==================
logic [1:0]               DVFS_mode_setup;
logic                     DVFS_ultra;
logic [v_sel_bits-1:0]    DVFS_v_step;
logic [f_sel_bits-1:0]    DVFS_f_step;
logic [vf_sel_bits-1:0]   DVFS_v_fine_step;

// ==================
//      MMIO slave wires
// ==================
wire        Read_Enable;
wire        Write_Enable;
wire [31:0] Write_data;
wire [31:0] Addr;
wire [3:0]  WSTRB;

logic       miss;
logic       hit;
wire [31:0] read_data;
logic [31:0] read_data_r;

assign read_data = read_data_r;

// ==================
//      FSM typedef
// ==================
typedef enum logic [2:0] {
    ST_idle,
    ST_Freeze_clocks_on,
    ST_v_switch,
    ST_f_switch,
    ST_Freeze_clocks_off,
    ST_done,
    ST_v_tune
} ST_DVFS;

typedef enum logic [2:0] {
    F_max,
    F_min,
    mode_up,
    mode_down,
    V_fine_down,
    V_fine_up,
    F_direct
} DVFS_cmd_t;

ST_DVFS    state, next_state;
DVFS_cmd_t dvfs_cmd_now;
DVFS_cmd_t dvfs_cmd_r;
DVFS_cmd_t dvfs_cmd_work;

logic [f_sel_bits-1:0] CK_mux_sel;
logic [v_stage-1:0]    power_switch_sel;

logic [f_sel_bits-1:0]  f_step_next;
logic [v_sel_bits-1:0]  v_step_next;
logic [vf_sel_bits-1:0] vf_step_next;
logic [vf_sel_bits-1:0] v_fine_idx_step;

logic                  sw_req_pending;
logic                  sw_f_req_pending;
logic [f_sel_bits-1:0] sw_f_step_target;
logic                  dvfs_start_req;
logic                  clk_freeze;

// Center -> DVFS-unit synchronizers. These are single-bit level
// synchronizers; the source must keep command flags stable with DVFS_req.
logic DVFS_req_sync;
logic DVFS_F_max_sync;
logic DVFS_F_min_sync;
logic DVFS_V_tune_sync;

// Freeze controls synchronized into each raw clock domain.
logic rom_freeze_sync;
logic dram_freeze_sync;
logic aclk_freeze_sync;
logic cpu_freeze_sync;

// Acknowledgements are generated in each raw clock domain, then
// synchronized back into the clk domain before the FSM consumes them.
logic rom_freeze_ack_src;
logic dram_freeze_ack_src;
logic aclk_freeze_ack_src;
logic cpu_freeze_ack_src;
logic rom_freeze_ack;
logic dram_freeze_ack;
logic aclk_freeze_ack;
logic cpu_freeze_ack;
logic all_clocks_frozen;
logic all_clocks_running;

// ==================
//      CDC synchronizers
// ==================
// Incoming request/command signals are synchronized into the local clk domain.
dvfs_cdc_sync_2ff u_sync_dvfs_req (
    .clk     (clk),
    .rst     (rst),
    .d_async (DVFS_req),
    .q_sync  (DVFS_req_sync)
);

dvfs_cdc_sync_2ff u_sync_dvfs_f_max (
    .clk     (clk),
    .rst     (rst),
    .d_async (DVFS_F_max),
    .q_sync  (DVFS_F_max_sync)
);

dvfs_cdc_sync_2ff u_sync_dvfs_f_min (
    .clk     (clk),
    .rst     (rst),
    .d_async (DVFS_F_min),
    .q_sync  (DVFS_F_min_sync)
);

dvfs_cdc_sync_2ff u_sync_dvfs_v_tune (
    .clk     (clk),
    .rst     (rst),
    .d_async (DVFS_V_tune),
    .q_sync  (DVFS_V_tune_sync)
);

// clk_freeze is sent to every raw source-clock domain through a 2DFF.
// Each synchronizer uses the reset already synchronized to its own
// destination clock domain. The raw clocks remain available so the
// synchronizers can receive unfreeze even while the ICG outputs are closed.
dvfs_cdc_sync_2ff u_sync_freeze_to_rom (
    .clk     (ROM_clk),
    .rst     (ROM_rst),
    .d_async (clk_freeze),
    .q_sync  (rom_freeze_sync)
);

dvfs_cdc_sync_2ff u_sync_freeze_to_dram (
    .clk     (DRAM_clk),
    .rst     (DRAM_rst),
    .d_async (clk_freeze),
    .q_sync  (dram_freeze_sync)
);

dvfs_cdc_sync_2ff u_sync_freeze_to_aclk (
    .clk     (ACLK),
    .rst     (ACLK_rst),
    .d_async (clk_freeze),
    .q_sync  (aclk_freeze_sync)
);

dvfs_cdc_sync_2ff u_sync_freeze_to_cpu (
    .clk     (cpu_clk_i),
    .rst     (cpu_clk_i_rst),
    .d_async (clk_freeze),
    .q_sync  (cpu_freeze_sync)
);

// Delay the acknowledgement by one additional raw-clock cycle. This gives
// the ICG low-level latch time to capture its new enable before ack is sent.
always_ff @(posedge ROM_clk or posedge ROM_rst) begin
    if (ROM_rst) rom_freeze_ack_src <= 1'b0;
    else     rom_freeze_ack_src <= rom_freeze_sync;
end

always_ff @(posedge DRAM_clk or posedge DRAM_rst) begin
    if (DRAM_rst) dram_freeze_ack_src <= 1'b0;
    else     dram_freeze_ack_src <= dram_freeze_sync;
end

always_ff @(posedge ACLK or posedge ACLK_rst) begin
    if (ACLK_rst) aclk_freeze_ack_src <= 1'b0;
    else     aclk_freeze_ack_src <= aclk_freeze_sync;
end

always_ff @(posedge cpu_clk_i or posedge cpu_clk_i_rst) begin
    if (cpu_clk_i_rst) cpu_freeze_ack_src <= 1'b0;
    else     cpu_freeze_ack_src <= cpu_freeze_sync;
end

// Return path: every per-domain acknowledgement also passes through a 2DFF
dvfs_cdc_sync_2ff u_sync_rom_ack_to_clk (
    .clk     (clk),
    .rst     (rst),
    .d_async (rom_freeze_ack_src),
    .q_sync  (rom_freeze_ack)
);

dvfs_cdc_sync_2ff u_sync_dram_ack_to_clk (
    .clk     (clk),
    .rst     (rst),
    .d_async (dram_freeze_ack_src),
    .q_sync  (dram_freeze_ack)
);

dvfs_cdc_sync_2ff u_sync_aclk_ack_to_clk (
    .clk     (clk),
    .rst     (rst),
    .d_async (aclk_freeze_ack_src),
    .q_sync  (aclk_freeze_ack)
);

dvfs_cdc_sync_2ff u_sync_cpu_ack_to_clk (
    .clk     (clk),
    .rst     (rst),
    .d_async (cpu_freeze_ack_src),
    .q_sync  (cpu_freeze_ack)
);

assign all_clocks_frozen =  rom_freeze_ack &  dram_freeze_ack &
                            aclk_freeze_ack &  cpu_freeze_ack;
assign all_clocks_running = ~rom_freeze_ack & ~dram_freeze_ack &
                           ~aclk_freeze_ack & ~cpu_freeze_ack;

// ==================
//      output
// ==================
// DVFS_resp is generated in the local clk domain. If the receiver uses a
// different clock, synchronize DVFS_resp again in that destination domain.
assign DVFS_resp = (state == ST_done);

// During ST_idle, decode the command currently visible.
// During an active transaction, use the latched command so a one-cycle
// DVFS_req pulse will not corrupt the later v/f update states.
assign dvfs_cmd_work = (state == ST_idle) ? dvfs_cmd_now : dvfs_cmd_r;

assign v_ctrl = (state == ST_v_tune) ? ((dvfs_cmd_work == V_fine_up) ? 2'b11 : 2'b10) : 2'b00;

// DVFS_v_step is the on-chip coarse voltage step for power-switch control.
assign DVFS_v_step_o = DVFS_v_step;

// v_ctrl_idx belongs to the off-chip fine-tune command.
// When v_ctrl is valid, output the target fine-step index for that command.
assign v_fine_idx_step = (state == ST_v_tune) ? vf_step_next : DVFS_v_fine_step;

generate
    if (vf_sel_bits == 1) begin : GEN_FINE_VIDX_1B
        assign v_ctrl_idx = {1'b0, v_fine_idx_step[0]};
    end
    else begin : GEN_FINE_VIDX_NB
        assign v_ctrl_idx = v_fine_idx_step[1:0];
    end
endgenerate

// One-hot voltage switch select, kept internally for extension/debug.
always_comb begin
    power_switch_sel = '0;
    if (DVFS_v_step < v_stage) begin
        power_switch_sel[DVFS_v_step] = 1'b1;
    end
end

// ==================
//      command decode
// ==================
always_comb begin
    dvfs_cmd_now = mode_down;

    // Synchronized hardware request has highest priority.
    if (DVFS_req_sync) begin
        if (DVFS_F_max_sync) begin
            dvfs_cmd_now = F_max;
        end
        else if (DVFS_F_min_sync) begin
            dvfs_cmd_now = F_min;
        end
        else if (DVFS_V_tune_sync) begin
            dvfs_cmd_now = V_fine_up;
        end
        else begin
            dvfs_cmd_now = V_fine_down;
        end
    end
    else if (sw_f_req_pending) begin
        // Direct MMIO frequency writes also use the safe freeze sequence.
        dvfs_cmd_now = F_direct;
    end
    else begin
        if (DVFS_ultra) begin
            dvfs_cmd_now = F_max;
        end
        else begin
            case (DVFS_mode_setup)
                2'd0:    dvfs_cmd_now = mode_down;
                2'd1:    dvfs_cmd_now = mode_up;
                default: dvfs_cmd_now = mode_down;
            endcase
        end
    end
end

assign dvfs_start_req = DVFS_req_sync | sw_req_pending | sw_f_req_pending;

// ==================
//      FSM
// ==================
always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        state <= ST_idle;
    end
    else begin
        state <= next_state;
    end
end

always_comb begin
    next_state = state;

    case (state)
        ST_idle: begin
            next_state = dvfs_start_req ? ST_Freeze_clocks_on : ST_idle;
        end

        ST_Freeze_clocks_on: begin
            // Do not change voltage or mux select until every source domain
            // has acknowledged that its pre-mux ICG is closed.
            if (all_clocks_frozen) begin
                case (dvfs_cmd_work)
                    mode_up:     next_state = ST_v_switch;  // raise V first, then raise F
                    mode_down:   next_state = ST_f_switch;  // lower F first, then lower V
                    V_fine_up,
                    V_fine_down: next_state = ST_v_tune;
                    default:     next_state = ST_f_switch;  // F_max / F_min / F_direct
                endcase
            end
        end

        ST_v_switch: begin
            next_state = (dvfs_cmd_work == mode_up) ? ST_f_switch : ST_Freeze_clocks_off;
        end

        ST_f_switch: begin
            next_state = (dvfs_cmd_work == mode_down) ? ST_v_switch : ST_Freeze_clocks_off;
        end

        ST_v_tune: begin
            next_state = ST_Freeze_clocks_off;
        end

        ST_Freeze_clocks_off: begin
            // Wait until every source domain has observed unfreeze before
            // reporting completion to the requester.
            next_state = all_clocks_running ? ST_done : ST_Freeze_clocks_off;
        end

        ST_done: begin
            next_state = ST_idle;
        end

        default: begin
            next_state = ST_idle;
        end
    endcase
end

// Latch command at transaction start.
always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        dvfs_cmd_r <= mode_down;
    end
    else if ((state == ST_idle) && dvfs_start_req) begin
        dvfs_cmd_r <= dvfs_cmd_now;
    end
end

// Software request is generated by writing mode_setup or ultra.
// It is cleared when one DVFS transaction finishes.
always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        sw_req_pending <= 1'b0;
    end
    else begin
        if (state == ST_done) begin
            sw_req_pending <= 1'b0;
        end
        else if (Write_Enable && ((Addr == `DVFS_mode_setup_reg) || (Addr == `DVFS_ultra_reg))) begin
            sw_req_pending <= 1'b1;
        end
    end
end

// A direct frequency-step write is converted into a normal DVFS transaction.
// The target is captured first; CK_mux_sel is updated only in ST_f_switch
// after all four pre-mux ICGs have acknowledged freeze.
always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        sw_f_req_pending <= 1'b0;
        sw_f_step_target <= '0;
    end
    else begin
        if (state == ST_done) begin
            sw_f_req_pending <= 1'b0;
        end
        else if (Write_Enable && (Addr == `DVFS_f_step_reg)) begin
            sw_f_req_pending <= 1'b1;
            sw_f_step_target <= Write_data[f_sel_bits-1:0];
        end
    end
end

// Freeze gated CPU clock while changing voltage/frequency.
always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        clk_freeze <= 1'b0;
    end
    else begin
        case (state)
            ST_Freeze_clocks_on:  clk_freeze <= 1'b1;
            ST_Freeze_clocks_off: clk_freeze <= 1'b0;
            default:              clk_freeze <= clk_freeze;
        endcase
    end
end

// ==================
//      next step calculation
// ==================
always_comb begin
    f_step_next = DVFS_f_step;

    case (dvfs_cmd_work)
        F_max: begin
            f_step_next = F_MAX_SEL;
        end

        F_min: begin
            f_step_next = '0;
        end

        F_direct: begin
            f_step_next = sw_f_step_target;
        end

        mode_up: begin
            f_step_next = (DVFS_f_step >= F_MAX_SEL) ? DVFS_f_step : (DVFS_f_step + 1'b1);
        end

        mode_down: begin
            f_step_next = (DVFS_f_step == '0) ? DVFS_f_step : (DVFS_f_step - 1'b1);
        end

        default: begin
            f_step_next = DVFS_f_step;
        end
    endcase
end

always_comb begin
    v_step_next = DVFS_v_step;

    case (dvfs_cmd_work)
        mode_up: begin
            v_step_next = (DVFS_v_step >= V_MAX_SEL) ? DVFS_v_step : (DVFS_v_step + 1'b1);
        end

        mode_down: begin
            v_step_next = (DVFS_v_step == '0) ? DVFS_v_step : (DVFS_v_step - 1'b1);
        end

        default: begin
            v_step_next = DVFS_v_step;
        end
    endcase
end

always_comb begin
    vf_step_next = DVFS_v_fine_step;

    case (dvfs_cmd_work)
        V_fine_up: begin
            vf_step_next = (DVFS_v_fine_step >= VF_MAX_SEL) ? DVFS_v_fine_step : (DVFS_v_fine_step + 1'b1);
        end

        V_fine_down: begin
            vf_step_next = (DVFS_v_fine_step == '0) ? DVFS_v_fine_step : (DVFS_v_fine_step - 1'b1);
        end

        default: begin
            vf_step_next = DVFS_v_fine_step;
        end
    endcase
end

// ==================
//      CK mux step
// ==================
always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        DVFS_f_step <= '0;
        CK_mux_sel  <= '0;
    end
    else if (state == ST_f_switch) begin
        DVFS_f_step <= f_step_next;
        CK_mux_sel  <= f_step_next;
    end
end

// ==================
//      v stage select
// ==================
always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        DVFS_v_step      <= 2'd3;
        DVFS_v_fine_step <= '0;
    end
    else begin
        if (state == ST_v_switch) begin
            DVFS_v_step <= v_step_next;
        end
        else if (state == ST_v_tune) begin
            DVFS_v_fine_step <= vf_step_next;
        end
        else if (Write_Enable && (Addr == `DVFS_v_step_reg)) begin
            DVFS_v_step <= Write_data[v_sel_bits-1:0];
        end
    end
end

// ==================
//      MMIO write
// ==================
always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        DVFS_mode_setup <= '0;
        DVFS_ultra      <= 1'b0;
    end
    else if (Write_Enable) begin
        case (Addr)
            `DVFS_mode_setup_reg: begin
                DVFS_mode_setup <= Write_data[1:0];
            end

            `DVFS_ultra_reg: begin
                DVFS_ultra <= Write_data[0];
            end

            // DVFS_v_step_reg is handled in its own sequential block.
            // DVFS_f_step_reg is captured as a safe pending transaction.
            `DVFS_v_step_reg,
            `DVFS_f_step_reg: begin
                // handled above
            end

            default: begin
                // no operation
            end
        endcase
    end
end

// ==================
//      MMIO hit / miss
// ==================
always_comb begin
    hit  = 1'b0;
    miss = 1'b0;

    if (Write_Enable || Read_Enable) begin
        case (Addr)
            `DVFS_mode_setup_reg,
            `DVFS_ultra_reg,
            `DVFS_v_step_reg,
            `DVFS_f_step_reg: begin
                hit  = 1'b1;
                miss = 1'b0;
            end

            default: begin
                hit  = 1'b0;
                miss = 1'b1;
            end
        endcase
    end
end

// ==================
//      MMIO read
// ==================
always_comb begin
    read_data_r = 32'd0;

    case (Addr)
        `DVFS_mode_setup_reg: read_data_r = {30'd0, DVFS_mode_setup};
        `DVFS_ultra_reg     : read_data_r = {31'd0, DVFS_ultra};
        `DVFS_v_step_reg    : read_data_r = {{(32-v_sel_bits){1'b0}}, DVFS_v_step};
        `DVFS_f_step_reg    : read_data_r = {{(32-f_sel_bits){1'b0}}, DVFS_f_step};
        default             : read_data_r = 32'd0;
    endcase
end

// ==================
//      Pre-mux ICGs + CPU clock mux
// ==================
logic ROM_clk_g;
logic DRAM_clk_g;
logic ACLK_g;
logic cpu_clk_i_g;
logic cpu_clk_mux_l0_0;
logic cpu_clk_mux_l0_1;
logic cpu_clk_muxed;

`ifdef USE_FOUNDRY_DVFS_CELLS

    // Each asynchronous clock source is gated in its own raw clock domain.
    // The synchronized freeze signal drives the ICG enable; no unsynchronized
    // control signal reaches an ICG E pin.
    (* dont_touch = "true" *)
    FILL_IN_CELL_ICG_009 u_dvfs_rom_icg (
        .TE (1'b0),
        .E  (~rom_freeze_sync),
        .CP (ROM_clk),
        .Q  (ROM_clk_g)
    );

    (* dont_touch = "true" *)
    FILL_IN_CELL_ICG_009 u_dvfs_dram_icg (
        .TE (1'b0),
        .E  (~dram_freeze_sync),
        .CP (DRAM_clk),
        .Q  (DRAM_clk_g)
    );

    (* dont_touch = "true" *)
    FILL_IN_CELL_ICG_009 u_dvfs_aclk_icg (
        .TE (1'b0),
        .E  (~aclk_freeze_sync),
        .CP (ACLK),
        .Q  (ACLK_g)
    );

    (* dont_touch = "true" *)
    FILL_IN_CELL_ICG_009 u_dvfs_cpu_src_icg (
        .TE (1'b0),
        .E  (~cpu_freeze_sync),
        .CP (cpu_clk_i),
        .Q  (cpu_clk_i_g)
    );

    // 4:1 clock mux built from 2:1 clock mux cells.
    // Mapping:
    //   CK_mux_sel = 2'd0 : ROM_clk_g   // slowest
    //   CK_mux_sel = 2'd1 : DRAM_clk_g
    //   CK_mux_sel = 2'd2 : ACLK_g      // AXI clock
    //   CK_mux_sel = 2'd3 : cpu_clk_i_g // fastest
    // CK_mux_sel changes only while all four gated clocks are stopped.
    (* dont_touch = "true" *)
    FILL_IN_CELL_CLOCK_MUX_008 u_dvfs_ckmux_l0_0 (
        .I0 (ROM_clk_g),
        .I1 (DRAM_clk_g),
        .S  (CK_mux_sel[0]),
        .Z  (cpu_clk_mux_l0_0)
    );

    (* dont_touch = "true" *)
    FILL_IN_CELL_CLOCK_MUX_008 u_dvfs_ckmux_l0_1 (
        .I0 (ACLK_g),
        .I1 (cpu_clk_i_g),
        .S  (CK_mux_sel[0]),
        .Z  (cpu_clk_mux_l0_1)
    );

    (* dont_touch = "true" *)
    FILL_IN_CELL_CLOCK_MUX_008 u_dvfs_ckmux_l1 (
        .I0 (cpu_clk_mux_l0_0),
        .I1 (cpu_clk_mux_l0_1),
        .S  (CK_mux_sel[1]),
        .Z  (cpu_clk_muxed)
    );

    assign cpu_clk_o = cpu_clk_muxed;

`else

    // Synthesizable behavioral ICG fallback. Each gate captures its enable
    // only while its own raw clock is low, matching an integrated clock gate.
    logic rom_clk_en_latched;
    logic dram_clk_en_latched;
    logic aclk_en_latched;
    logic cpu_src_en_latched;

    always_latch begin
        if (ROM_rst) begin
            rom_clk_en_latched <= 1'b1;
        end
        else if (ROM_clk == 1'b0) begin
            rom_clk_en_latched <= ~rom_freeze_sync;
        end
    end

    always_latch begin
        if (DRAM_rst) begin
            dram_clk_en_latched <= 1'b1;
        end
        else if (DRAM_clk == 1'b0) begin
            dram_clk_en_latched <= ~dram_freeze_sync;
        end
    end

    always_latch begin
        if (ACLK_rst) begin
            aclk_en_latched <= 1'b1;
        end
        else if (ACLK == 1'b0) begin
            aclk_en_latched <= ~aclk_freeze_sync;
        end
    end

    always_latch begin
        if (cpu_clk_i_rst) begin
            cpu_src_en_latched <= 1'b1;
        end
        else if (cpu_clk_i == 1'b0) begin
            cpu_src_en_latched <= ~cpu_freeze_sync;
        end
    end

    assign ROM_clk_g   = ROM_clk   & rom_clk_en_latched;
    assign DRAM_clk_g  = DRAM_clk  & dram_clk_en_latched;
    assign ACLK_g      = ACLK      & aclk_en_latched;
    assign cpu_clk_i_g = cpu_clk_i & cpu_src_en_latched;

    // For f_stage=4, index is slow -> fast:
    // 00: ROM_clk_g, 01: DRAM_clk_g, 10: ACLK_g, 11: cpu_clk_i_g
    always_comb begin
        case (CK_mux_sel[1:0])
            2'd0:    cpu_clk_muxed = ROM_clk_g;
            2'd1:    cpu_clk_muxed = DRAM_clk_g;
            2'd2:    cpu_clk_muxed = ACLK_g;
            2'd3:    cpu_clk_muxed = cpu_clk_i_g;
            default: cpu_clk_muxed = ROM_clk_g;
        endcase
    end

    assign cpu_clk_o = cpu_clk_muxed;

`endif

// ==================
//      MMIO slave
// ==================
slave_simple u_slave_simple (
    .ACLK           (clk),
    .ARESETn        (~rst),
    .axi_r_s        (axi_r_s),
    .axi_w_s        (axi_w_s),

    // req
    .Read_Enable    (Read_Enable),
    .Write_Enable   (Write_Enable),
    .Write_data     (Write_data),
    .Addr           (Addr),
    .out_WSTRB      (WSTRB),

    // resp
    .in_miss        (miss),
    .in_hit         (hit),
    .read_data      (read_data),
    .stall_R        ('0),
    .stall_W        ('0)
);

endmodule
