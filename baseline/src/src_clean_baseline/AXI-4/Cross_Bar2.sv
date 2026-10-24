//`include "../include/AXI_define.svh"

module CrossBar2 #(
    parameter int Master       = 3,
    parameter int Master_index = (Master <= 1) ? 1 : $clog2(Master)
)(
    input  logic  ACLK,
    input  logic  ARESETn,
    input  logic  invalid,

    input  logic [Master_index-1:0] index,
    input  logic RW,

    output logic out_lock,

    axi_read_if  crossbar_r_m [Master],
    axi_write_if crossbar_w_m [Master],

    axi_read_if  axi_r_s,
    axi_write_if axi_w_s
);

//********************************************************
//                define
//********************************************************

    localparam int AXI_MASTER_TAG_BITS = `AXI_IDS_BITS - `AXI_ID_BITS;

    wire [`AXI_IDS_BITS-1:0] ARID_S;
    wire [`AXI_ADDR_BITS-1:0] ARADDR_S;
    wire [`AXI_LEN_BITS-1:0] ARLEN_S;
    wire [`AXI_SIZE_BITS-1:0] ARSIZE_S;
    wire [1:0] ARBURST_S;
    wire ARVALID_S;
    wire ARREADY_S;

    wire [`AXI_IDS_BITS-1:0] RID_S;
    wire [`AXI_DATA_BITS-1:0] RDATA_S;
    wire [1:0] RRESP_S;
    wire RLAST_S;
    wire RVALID_S;
    wire RREADY_S;

    wire [`AXI_IDS_BITS-1:0] AWID_S;
    wire [`AXI_ADDR_BITS-1:0] AWADDR_S;
    wire [`AXI_LEN_BITS-1:0] AWLEN_S;
    wire [`AXI_SIZE_BITS-1:0] AWSIZE_S;
    wire [1:0] AWBURST_S;
    wire AWVALID_S;
    wire AWREADY_S;

    wire [`AXI_DATA_BITS-1:0] WDATA_S;
    wire [`AXI_STRB_BITS-1:0] WSTRB_S;
    wire WLAST_S;
    wire WVALID_S;
    wire WREADY_S;

    wire [`AXI_IDS_BITS-1:0] BID_S;
    wire [1:0] BRESP_S;
    wire BVALID_S;
    wire BREADY_S;

    wire [`AXI_ID_BITS-1:0] ARID_M [Master-1:0];
    wire [`AXI_ADDR_BITS-1:0] ARADDR_M [Master-1:0];
    wire [`AXI_LEN_BITS-1:0] ARLEN_M [Master-1:0];
    wire [`AXI_SIZE_BITS-1:0] ARSIZE_M [Master-1:0];
    wire [1:0] ARBURST_M [Master-1:0];
    wire ARVALID_M [Master-1:0];
    wire ARREADY_M [Master-1:0];

    wire [`AXI_ID_BITS-1:0] RID_M [Master-1:0];
    wire [`AXI_DATA_BITS-1:0] RDATA_M [Master-1:0];
    wire [1:0] RRESP_M [Master-1:0];
    wire RLAST_M [Master-1:0];
    wire RVALID_M [Master-1:0];
    wire RREADY_M [Master-1:0];

    wire [`AXI_ID_BITS-1:0] AWID_M [Master-1:0];
    wire [`AXI_ADDR_BITS-1:0] AWADDR_M [Master-1:0];
    wire [`AXI_LEN_BITS-1:0] AWLEN_M [Master-1:0];
    wire [`AXI_SIZE_BITS-1:0] AWSIZE_M [Master-1:0];
    wire [1:0] AWBURST_M [Master-1:0];
    wire AWVALID_M [Master-1:0];
    wire AWREADY_M [Master-1:0];

    wire [`AXI_DATA_BITS-1:0] WDATA_M [Master-1:0];
    wire [`AXI_STRB_BITS-1:0] WSTRB_M [Master-1:0];
    wire WLAST_M [Master-1:0];
    wire WVALID_M [Master-1:0];
    wire WREADY_M [Master-1:0];

    wire [`AXI_ID_BITS-1:0] BID_M [Master-1:0];
    wire [1:0] BRESP_M [Master-1:0];
    wire BVALID_M [Master-1:0];
    wire BREADY_M [Master-1:0];


//********************************************************
//                parameterized index
//********************************************************

typedef enum logic [0:0] { idle_CB, lock_CB } state_t;

state_t state, next_state;

logic [Master_index-1:0] lock_index;
logic                    lock_RW;

logic [Master_index-1:0] sel_idx;
logic [AXI_MASTER_TAG_BITS-1:0] sel_tag;

assign out_lock = (state == lock_CB);

// Master tag zero-extend
always_comb begin
    sel_tag = '0;
    sel_tag[Master_index-1:0] = sel_idx;
end


// ==================================================
// FSM
// ==================================================
always_ff @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn) state <= idle_CB;
    else          state <= next_state;
end

logic any_arvalid, any_awvalid;

always_comb begin
    any_arvalid = 1'b0;
    any_awvalid = 1'b0;

    for (int i = 0; i < Master; i++) begin
        any_arvalid |= ARVALID_M[i];
        any_awvalid |= AWVALID_M[i];
    end
end


always_comb begin
    next_state = state;

    case (state)
        idle_CB: begin
            if (any_arvalid || any_awvalid)
                next_state = lock_CB;
        end

        lock_CB: begin
            if (!lock_RW && RVALID_S && RREADY_M[lock_index] && RLAST_S)
                next_state = idle_CB;
            else if (lock_RW && BVALID_S && BREADY_M[lock_index])
                next_state = idle_CB;
        end
    endcase
end


// Record chosen master when entering lock
always_ff @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn) begin
        lock_index <= '0;
        lock_RW    <= 1'b0;
    end 
    else if (state == idle_CB && (any_arvalid || any_awvalid)) begin
        lock_index <= index;
        lock_RW    <= RW;
    end
end


// ==================================================
// Master interface flatten
// ==================================================
genvar gi;

generate
for (gi = 0; gi < Master; gi++) begin : GEN_FLATTEN

    // =====================================================
    // READ ADDRESS CHANNEL
    // =====================================================
    assign ARID_M[gi]    = crossbar_r_m[gi].ARID_m;
    assign ARADDR_M[gi]  = crossbar_r_m[gi].ARADDR_m;
    assign ARLEN_M[gi]   = crossbar_r_m[gi].ARLEN_m;
    assign ARSIZE_M[gi]  = crossbar_r_m[gi].ARSIZE_m;
    assign ARBURST_M[gi] = crossbar_r_m[gi].ARBURST_m;
    assign ARVALID_M[gi] = crossbar_r_m[gi].ARVALID_m;

    assign crossbar_r_m[gi].ARREADY_m = ARREADY_M[gi];


    // =====================================================
    // READ DATA CHANNEL
    // =====================================================
    assign RREADY_M[gi] = crossbar_r_m[gi].RREADY_m;

    assign crossbar_r_m[gi].RID_m    = RID_M[gi];
    assign crossbar_r_m[gi].RDATA_m  = RDATA_M[gi];
    assign crossbar_r_m[gi].RRESP_m  = RRESP_M[gi];
    assign crossbar_r_m[gi].RLAST_m  = RLAST_M[gi];
    assign crossbar_r_m[gi].RVALID_m = RVALID_M[gi];


    // =====================================================
    // WRITE ADDRESS CHANNEL
    // =====================================================
    assign AWID_M[gi]    = crossbar_w_m[gi].AWID_m;
    assign AWADDR_M[gi]  = crossbar_w_m[gi].AWADDR_m;
    assign AWLEN_M[gi]   = crossbar_w_m[gi].AWLEN_m;
    assign AWSIZE_M[gi]  = crossbar_w_m[gi].AWSIZE_m;
    assign AWBURST_M[gi] = crossbar_w_m[gi].AWBURST_m;
    assign AWVALID_M[gi] = crossbar_w_m[gi].AWVALID_m;

    assign crossbar_w_m[gi].AWREADY_m = AWREADY_M[gi];


    // =====================================================
    // WRITE DATA CHANNEL
    // =====================================================
    assign WDATA_M[gi]  = crossbar_w_m[gi].WDATA_m;
    assign WSTRB_M[gi]  = crossbar_w_m[gi].WSTRB_m;
    assign WLAST_M[gi]  = crossbar_w_m[gi].WLAST_m;
    assign WVALID_M[gi] = crossbar_w_m[gi].WVALID_m;

    assign crossbar_w_m[gi].WREADY_m = WREADY_M[gi];


    // =====================================================
    // WRITE RESPONSE CHANNEL
    // =====================================================
    assign BREADY_M[gi] = crossbar_w_m[gi].BREADY_m;

    assign crossbar_w_m[gi].BID_m    = BID_M[gi];
    assign crossbar_w_m[gi].BRESP_m  = BRESP_M[gi];
    assign crossbar_w_m[gi].BVALID_m = BVALID_M[gi];

end
endgenerate


// ==================================================
// CrossBar <-> Slave interface
// ==================================================

// ---- Read Address ----
assign axi_r_s.ARID_s    = ARID_S;
assign axi_r_s.ARADDR_s  = ARADDR_S;
assign axi_r_s.ARLEN_s   = ARLEN_S;
assign axi_r_s.ARSIZE_s  = ARSIZE_S;
assign axi_r_s.ARBURST_s = ARBURST_S;
assign axi_r_s.ARVALID_s = ARVALID_S;

assign ARREADY_S         = axi_r_s.ARREADY_s;


// ---- Read Data ----
assign axi_r_s.RREADY_s = RREADY_S;

assign RID_S     = axi_r_s.RID_s;
assign RDATA_S   = axi_r_s.RDATA_s;
assign RRESP_S   = axi_r_s.RRESP_s;
assign RLAST_S   = axi_r_s.RLAST_s;
assign RVALID_S  = axi_r_s.RVALID_s;


// ---- Write Address ----
assign axi_w_s.AWID_s    = AWID_S;
assign axi_w_s.AWADDR_s  = AWADDR_S;
assign axi_w_s.AWLEN_s   = AWLEN_S;
assign axi_w_s.AWSIZE_s  = AWSIZE_S;
assign axi_w_s.AWBURST_s = AWBURST_S;
assign axi_w_s.AWVALID_s = AWVALID_S;

assign AWREADY_S         = axi_w_s.AWREADY_s;


// ---- Write Data ----
assign axi_w_s.WDATA_s   = WDATA_S;
assign axi_w_s.WSTRB_s   = WSTRB_S;
assign axi_w_s.WLAST_s   = WLAST_S;
assign axi_w_s.WVALID_s  = WVALID_S;

assign WREADY_S          = axi_w_s.WREADY_s;


// ---- Write Response ----
assign axi_w_s.BREADY_s  = BREADY_S;

assign BID_S             = axi_w_s.BID_s;
assign BRESP_S           = axi_w_s.BRESP_s;
assign BVALID_S          = axi_w_s.BVALID_s;


// ==================================================
// Slave-Side Selection Logic
// ==================================================

assign sel_idx = (state == lock_CB) ? lock_index : index;


// ---------- READ: AR* ----------
assign ARID_S    = {sel_tag, ARID_M[sel_idx]};
assign ARADDR_S  = ARADDR_M [sel_idx];
assign ARLEN_S   = ARLEN_M  [sel_idx];
assign ARSIZE_S  = ARSIZE_M [sel_idx];
assign ARBURST_S = ARBURST_M[sel_idx];

assign ARVALID_S =
      (state == idle_CB && invalid) ? 1'b0 :
      (!lock_RW && state == lock_CB) ? ARVALID_M[lock_index] :
      (!RW      && state == idle_CB) ? ARVALID_M[index] :
      1'b0;

assign RREADY_S =
      (state == idle_CB && invalid) ? 1'b0 :
      (!lock_RW && state == lock_CB) ? RREADY_M[lock_index] :
      (!RW      && state == idle_CB) ? RREADY_M[index] :
      1'b0;


// ---------- WRITE: AW*/W* ----------
assign AWID_S    = {sel_tag, AWID_M[sel_idx]};
assign AWADDR_S  = AWADDR_M [sel_idx];
assign AWLEN_S   = AWLEN_M  [sel_idx];
assign AWSIZE_S  = AWSIZE_M [sel_idx];
assign AWBURST_S = AWBURST_M[sel_idx];

assign AWVALID_S =
      (state == idle_CB && invalid) ? 1'b0 :
      (lock_RW  && state == lock_CB) ? AWVALID_M[lock_index] :
      (RW       && state == idle_CB) ? AWVALID_M[index] :
      1'b0;

assign WDATA_S   = WDATA_M [sel_idx];
assign WSTRB_S   = WSTRB_M [sel_idx];
assign WLAST_S   = WLAST_M [sel_idx];

assign WVALID_S =
      (state == idle_CB && invalid) ? 1'b0 :
      (lock_RW  && state == lock_CB) ? WVALID_M[lock_index] :
      (RW       && state == idle_CB) ? WVALID_M[index] :
      1'b0;

assign BREADY_S =
      (state == idle_CB && invalid) ? 1'b0 :
      (lock_RW  && state == lock_CB) ? BREADY_M[lock_index] :
      (RW       && state == idle_CB) ? BREADY_M[index] :
      1'b0;


// ==================================================
// Master Receivers
// ==================================================
generate
for (gi = 0; gi < Master; gi++) begin : GEN_M

    localparam logic [Master_index-1:0] GI_IDX = gi[Master_index-1:0];

    assign ARREADY_M[gi] =
        (state == idle_CB && invalid) ? 1'b0 :
        (!lock_RW && state == lock_CB && lock_index == GI_IDX) ? ARREADY_S :
        (!RW      && state == idle_CB && index      == GI_IDX) ? ARREADY_S :
        1'b0;

    assign RVALID_M[gi] =
        (state == idle_CB && invalid) ? 1'b0 :
        (!lock_RW && state == lock_CB && lock_index == GI_IDX) ? RVALID_S :
        (!RW      && state == idle_CB && index      == GI_IDX) ? RVALID_S :
        1'b0;

    assign RID_M[gi] =
        (!RVALID_M[gi]) ? '0 :
        RID_S[`AXI_ID_BITS-1:0];

    assign RDATA_M[gi] = RVALID_M[gi] ? RDATA_S : '0;
    assign RRESP_M[gi] = RVALID_M[gi] ? RRESP_S : '0;
    assign RLAST_M[gi] = RVALID_M[gi] ? RLAST_S : '0;


    assign AWREADY_M[gi] =
        (state == idle_CB && invalid) ? 1'b0 :
        (lock_RW && state == lock_CB && lock_index == GI_IDX) ? AWREADY_S :
        (RW      && state == idle_CB && index      == GI_IDX) ? AWREADY_S :
        1'b0;

    assign WREADY_M[gi] =
        (state == idle_CB && invalid) ? 1'b0 :
        (lock_RW && state == lock_CB && lock_index == GI_IDX) ? WREADY_S :
        (RW      && state == idle_CB && index      == GI_IDX) ? WREADY_S :
        1'b0;

    assign BVALID_M[gi] =
        (state == idle_CB && invalid) ? 1'b0 :
        (lock_RW && state == lock_CB && lock_index == GI_IDX) ? BVALID_S :
        (RW      && state == idle_CB && index      == GI_IDX) ? BVALID_S :
        1'b0;

    assign BID_M[gi] =
        (!BVALID_M[gi]) ? '0 :
        BID_S[`AXI_ID_BITS-1:0];

    assign BRESP_M[gi] =
        BVALID_M[gi] ? BRESP_S : '0;

end
endgenerate

endmodule