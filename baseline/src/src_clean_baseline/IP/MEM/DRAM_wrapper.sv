`include "../include/AXI_define.svh"
//`define old_CDC

module DRAM_wrap_my (
    // ==========================================================
    // Clock & Reset Domains
    // ==========================================================
    // Source Domain (AXI Bus Side)
    input  logic                     ACLK,
    input  logic                     ARESETn,

    // Destination Domain (DRAM Side)
    input  logic                     dram_clk,
    input  logic                     dram_rst,

    // ==========================================================
    // AXI Interface (Preserving your ifdef structure)
    // ==========================================================
`ifdef interface_En
    axi_read_if  axi_r_s,      // AR/R
    axi_write_if axi_w_s,      // AW/W/B
`else
    // ---------------- AXI Slave Side (Source Domain Inputs/Outputs) ----------------
    // AR Channel
    input  logic [`AXI_IDS_BITS-1:0]  ARID,
    input  logic [`AXI_ADDR_BITS-1:0] ARADDR,
    input  logic [`AXI_LEN_BITS-1:0]  ARLEN,
    input  logic [`AXI_SIZE_BITS-1:0] ARSIZE,
    input  logic [1:0]                ARBURST,
    input  logic                      ARVALID,
    output logic                      ARREADY,

    // R Channel
    output logic [`AXI_IDS_BITS-1:0]  RID,
    output logic [`AXI_DATA_BITS-1:0] RDATA,
    output logic [1:0]                RRESP,
    output logic                      RLAST,
    output logic                      RVALID,
    input  logic                      RREADY,

    // AW Channel
    input  logic [`AXI_IDS_BITS-1:0]  AWID,
    input  logic [`AXI_ADDR_BITS-1:0] AWADDR,
    input  logic [`AXI_LEN_BITS-1:0]  AWLEN,
    input  logic [`AXI_SIZE_BITS-1:0] AWSIZE,
    input  logic [1:0]                AWBURST,
    input  logic                      AWVALID,
    output logic                      AWREADY,

    // W Channel
    input  logic [`AXI_DATA_BITS-1:0] WDATA,
    input  logic [`AXI_STRB_BITS-1:0] WSTRB,
    input  logic                      WLAST,
    input  logic                      WVALID,
    output logic                      WREADY,

    // B Channel
    output logic [`AXI_IDS_BITS-1:0]  BID,
    output logic [1:0]                BRESP,
    output logic                      BVALID,
    input  logic                      BREADY,
`endif

    // ==========================================================
    // DRAM Physical Ports (Destination Domain)
    // ==========================================================
    input  logic [31:0]               Q,       // DRAM data out
    input  logic                      VALID,   // DRAM data valid

    output logic                      CSn,     // DRAM_CSn
    output logic [3:0]                WEn,     // DRAM_WEn
    output logic                      RASn,    // DRAM_RASn
    output logic                      CASn,    // DRAM_CASn
    output logic [10:0]               A,       // DRAM_A
    output logic [31:0]               D        // DRAM_D
);

    // ==========================================================
    // AXI internal signals (use *_S only)
    // ==========================================================
    // AR   READ ADDRESS
    logic [`AXI_IDS_BITS-1:0]  ARID_S;
    logic [`AXI_ADDR_BITS-1:0] ARADDR_S;
    logic [`AXI_LEN_BITS-1:0]  ARLEN_S;
    logic [`AXI_SIZE_BITS-1:0] ARSIZE_S;
    logic [1:0]                ARBURST_S;
    logic                      ARVALID_S;
    logic                      ARREADY_S;

    // R    READ DATA
    logic [`AXI_IDS_BITS-1:0]  RID_S;
    logic [`AXI_DATA_BITS-1:0] RDATA_S;
    logic [1:0]                RRESP_S;
    logic                      RLAST_S;
    logic                      RVALID_S;
    logic                      RREADY_S;

    // AW   WRITE ADDRESS
    logic [`AXI_IDS_BITS-1:0]  AWID_S;
    logic [`AXI_ADDR_BITS-1:0] AWADDR_S;
    logic [`AXI_LEN_BITS-1:0]  AWLEN_S;
    logic [`AXI_SIZE_BITS-1:0] AWSIZE_S;
    logic [1:0]                AWBURST_S;
    logic                      AWVALID_S;
    logic                      AWREADY_S;

    // W    WRITE DATA
    logic [`AXI_DATA_BITS-1:0] WDATA_S;
    logic [`AXI_STRB_BITS-1:0] WSTRB_S;
    logic                      WLAST_S;
    logic                      WVALID_S;
    logic                      WREADY_S;

    // B    WRITE RESPONSE
    logic [`AXI_IDS_BITS-1:0]  BID_S;
    logic [1:0]                BRESP_S;
    logic                      BVALID_S;
    logic                      BREADY_S;

    // Response fixed to OKAY (no CDC needed)
    assign RRESP_S  = `AXI_RESP_OKAY;
    assign BRESP_S  = `AXI_RESP_OKAY;

`ifdef interface_En
    // ==========================================================
    // interface_En mapping: axi_*_s <-> *_S
    // ==========================================================
    // write channel
    assign AWID_S    = axi_w_s.AWID_s;
    assign AWADDR_S  = axi_w_s.AWADDR_s;
    assign AWLEN_S   = axi_w_s.AWLEN_s;
    assign AWSIZE_S  = axi_w_s.AWSIZE_s;
    assign AWBURST_S = axi_w_s.AWBURST_s;
    assign AWVALID_S = axi_w_s.AWVALID_s;
    assign axi_w_s.AWREADY_s = AWREADY_S;

    assign WDATA_S   = axi_w_s.WDATA_s;
    assign WSTRB_S   = axi_w_s.WSTRB_s;
    assign WLAST_S   = axi_w_s.WLAST_s;
    assign WVALID_S  = axi_w_s.WVALID_s;
    assign axi_w_s.WREADY_s = WREADY_S;

    assign axi_w_s.BID_s    = BID_S;
    assign axi_w_s.BRESP_s  = BRESP_S;
    assign axi_w_s.BVALID_s = BVALID_S;
    assign BREADY_S         = axi_w_s.BREADY_s;

    // read channel
    assign ARID_S    = axi_r_s.ARID_s;
    assign ARADDR_S  = axi_r_s.ARADDR_s;
    assign ARLEN_S   = axi_r_s.ARLEN_s;
    assign ARSIZE_S  = axi_r_s.ARSIZE_s;
    assign ARBURST_S = axi_r_s.ARBURST_s;
    assign ARVALID_S = axi_r_s.ARVALID_s;
    assign axi_r_s.ARREADY_s = ARREADY_S;

    assign axi_r_s.RID_s    = RID_S;
    assign axi_r_s.RDATA_s  = RDATA_S;
    assign axi_r_s.RRESP_s  = RRESP_S;
    assign axi_r_s.RLAST_s  = RLAST_S;
    assign axi_r_s.RVALID_s = RVALID_S;
    assign RREADY_S         = axi_r_s.RREADY_s;

`else

`endif

    // ==========================================================
    // 2. FIFO Definitions (CDC) - strip unused AXI fields
    //   Keep only what DRAM logic uses: ID/ADDR/LEN + WDATA/WSTRB/WLAST
    // ==========================================================
    localparam int FIFO_DEPTH_AW    = 2;
    localparam int FIFO_DEPTH_W    = 2;
    localparam int FIFO_DEPTH_B    = 2;
    localparam int FIFO_DEPTH_AR    = 2;
    localparam int FIFO_DEPTH_R    = 2;


    //localparam int FIFO_PTR_BITS = $clog2(FIFO_DEPTH) + 1;

    localparam int AW_FIFO_width = `AXI_ADDR_BITS + `AXI_LEN_BITS; // ID+ADDR+LEN
    localparam int W_FIFO_width  = `AXI_DATA_BITS + `AXI_STRB_BITS + 1;           // WDATA+WSTRB+WLAST
    localparam int B_FIFO_width  = 1;                                  // BID only
    localparam int AR_FIFO_width = `AXI_ADDR_BITS + `AXI_LEN_BITS; // ID+ADDR+LEN
    localparam int R_FIFO_width  = `AXI_DATA_BITS + 1;             // RID+RDATA+RLAST

 
    // ==========================================================
    // 3. DRAM-side AXI signals (after CDC FIFO) : dram_*
    // ==========================================================
    logic [`AXI_IDS_BITS-1:0]  dram_arid;
    logic [`AXI_ADDR_BITS-1:0] dram_araddr;
    logic [`AXI_LEN_BITS-1:0]  dram_arlen;
    logic                      dram_arvalid;
    logic                      dram_arready;

    logic [`AXI_IDS_BITS-1:0]  dram_rid;
    logic [`AXI_DATA_BITS-1:0] dram_rdata;
    logic                      dram_rlast;
    logic                      dram_rvalid;
    logic                      dram_rready;

    logic [`AXI_IDS_BITS-1:0]  dram_awid;
    logic [`AXI_ADDR_BITS-1:0] dram_awaddr;
    logic [`AXI_LEN_BITS-1:0]  dram_awlen;
    logic                      dram_awvalid;
    logic                      dram_awready;

    logic [`AXI_DATA_BITS-1:0] dram_wdata;
    logic [`AXI_STRB_BITS-1:0] dram_wstrb;
    logic                      dram_wlast;
    logic                      dram_wvalid;
    logic                      dram_wready;

    logic [`AXI_IDS_BITS-1:0]  dram_bid;
    logic                      dram_bvalid;
    logic                      dram_bready;

    // ==========================================================
    // 4. FIFO Instances
    // ==========================================================
`ifdef old_CDC
    // --- AW Channel
    logic [AW_FIFO_width-1:0] aw_wdata, aw_rdata;
    logic                aw_full, aw_empty;
    logic                aw_winc, aw_rinc;

    assign aw_wdata   = {AWADDR_S, AWLEN_S};
    assign AWREADY_S  = ~aw_full;
    assign aw_winc    = AWVALID_S && AWREADY_S;

    assign dram_awvalid = ~aw_empty;
    assign aw_rinc      = dram_awvalid && dram_awready;
    assign {dram_awaddr, dram_awlen} = aw_rdata;

    // --- W Channel
    logic [W_FIFO_width-1:0] w_wdata, w_rdata;
    logic               w_full, w_empty;
    logic               w_winc, w_rinc;

    assign w_wdata   = {WDATA_S, WSTRB_S, WLAST_S};
    assign WREADY_S  = ~w_full;
    assign w_winc    = WVALID_S && WREADY_S;

    assign dram_wvalid = ~w_empty;
    assign w_rinc      = dram_wvalid && dram_wready;
    assign {dram_wdata, dram_wstrb, dram_wlast} = w_rdata;

    // --- B Channel
    logic [B_FIFO_width-1:0] b_wdata, b_rdata;
    logic               b_full, b_empty;
    logic               b_winc, b_rinc;

    assign b_wdata     = 1'b0;
    assign dram_bready = ~b_full;
    assign b_winc      = dram_bvalid && dram_bready;

    assign BVALID_S    = ~b_empty;
    assign b_rinc      = BVALID_S && BREADY_S;

    // --- AR Channel
    logic [AR_FIFO_width-1:0] ar_wdata, ar_rdata;
    logic                ar_full, ar_empty;
    logic                ar_winc, ar_rinc;

    assign ar_wdata   = {ARADDR_S, ARLEN_S};
    assign ARREADY_S  = ~ar_full;
    assign ar_winc    = ARVALID_S && ARREADY_S;

    assign dram_arvalid = ~ar_empty;
    assign ar_rinc      = dram_arvalid && dram_arready;
    assign {dram_araddr, dram_arlen} = ar_rdata;

    // --- R Channel
    logic [R_FIFO_width-1:0] r_wdata, r_rdata;
    logic               r_full, r_empty;
    logic               r_winc, r_rinc;

    assign r_wdata     = {dram_rdata, dram_rlast};
    assign dram_rready = ~r_full;
    assign r_winc      = dram_rvalid && dram_rready;

    assign RVALID_S    = ~r_empty;
    assign r_rinc      = RVALID_S && RREADY_S;
    assign {RDATA_S, RLAST_S} = r_rdata;
`else
    // --- AW Channel

    logic [AW_FIFO_width-1:0] aw_wdata, aw_rdata;
    logic                aw_full, aw_empty;
    logic                aw_winc, aw_rinc;

    assign aw_wdata   = {AWADDR_S, AWLEN_S};
    assign AWREADY_S  = ~aw_full;
    assign aw_winc    = AWVALID_S && AWREADY_S;

    assign dram_awvalid = ~aw_empty;
    assign aw_rinc      = dram_awvalid && dram_awready;
    assign {dram_awaddr, dram_awlen} = (!aw_empty) ? aw_rdata : 32'd0;

    // --- W Channel
    logic [W_FIFO_width-1:0] w_wdata, w_rdata;
    logic               w_full, w_empty;
    logic               w_winc, w_rinc;

    assign w_wdata   = {WDATA_S, WSTRB_S, WLAST_S};
    assign WREADY_S  = ~w_full;
    assign w_winc    = WVALID_S && WREADY_S;

    assign dram_wvalid = ~w_empty;
    assign w_rinc      = dram_wvalid && dram_wready;
    assign {dram_wdata, dram_wstrb, dram_wlast} = (!w_empty) ? w_rdata : 32'd0;

    // --- B Channel
    logic [B_FIFO_width-1:0] b_wdata, b_rdata;
    logic               b_full, b_empty;
    logic               b_winc, b_rinc;

    assign b_wdata     = 1'b0;
    assign dram_bready = ~b_full;
    assign b_winc      = dram_bvalid && dram_bready;

    assign BVALID_S    = ~b_empty;
    assign b_rinc      = BVALID_S && BREADY_S;

    // --- AR Channel
    logic [AR_FIFO_width-1:0] ar_wdata, ar_rdata;
    logic                ar_full, ar_empty;
    logic                ar_winc, ar_rinc;

    assign ar_wdata   = {ARADDR_S, ARLEN_S};
    assign ARREADY_S  = ~ar_full;
    assign ar_winc    = ARVALID_S && ARREADY_S;

    assign dram_arvalid = ~ar_empty;
    assign ar_rinc      = dram_arvalid && dram_arready;
    assign {dram_araddr, dram_arlen} = (!ar_empty) ? ar_rdata : 32'd0;

    // --- R Channel
    logic [R_FIFO_width-1:0] r_wdata, r_rdata;
    logic               r_full, r_empty;
    logic               r_winc, r_rinc;

    assign r_wdata     = {dram_rdata, dram_rlast};
    assign dram_rready = ~r_full;
    assign r_winc      = dram_rvalid && dram_rready;

    assign RVALID_S    = ~r_empty;
    assign r_rinc      = RVALID_S && RREADY_S;
    assign {RDATA_S, RLAST_S} = (!r_empty) ? r_rdata : 32'd0;
`endif

    asyc_FIFO #(.width(AW_FIFO_width), .depath(FIFO_DEPTH_AW)) u_aw_fifo (
        .w_clk(ACLK), .w_rst(~ARESETn),
        .r_clk(dram_clk), .r_rst(dram_rst),
        .wdata(aw_wdata), .winc(aw_winc), .rinc(aw_rinc),
        .rdata(aw_rdata), .rempty(aw_empty), .wfull(aw_full)
    );

    

    asyc_FIFO #(.width(W_FIFO_width), .depath(FIFO_DEPTH_W)) u_w_fifo (
        .w_clk(ACLK), .w_rst(~ARESETn),
        .r_clk(dram_clk), .r_rst(dram_rst),
        .wdata(w_wdata), .winc(w_winc), .rinc(w_rinc),
        .rdata(w_rdata), .rempty(w_empty), .wfull(w_full)
    );

    

    asyc_FIFO #(.width(B_FIFO_width), .depath(FIFO_DEPTH_B)) u_b_fifo (
        .w_clk(dram_clk), .w_rst(dram_rst),
        .r_clk(ACLK), .r_rst(~ARESETn),
        .wdata(b_wdata), .winc(b_winc), .rinc(b_rinc),
        .rdata(b_rdata), .rempty(b_empty), .wfull(b_full)
    );

    

    asyc_FIFO #(.width(AR_FIFO_width), .depath(FIFO_DEPTH_AR)) u_ar_fifo (
        .w_clk(ACLK), .w_rst(~ARESETn),
        .r_clk(dram_clk), .r_rst(dram_rst),
        .wdata(ar_wdata), .winc(ar_winc), .rinc(ar_rinc),
        .rdata(ar_rdata), .rempty(ar_empty), .wfull(ar_full)
    );

    

    asyc_FIFO #(.width(R_FIFO_width), .depath(FIFO_DEPTH_R)) u_r_fifo (
        .w_clk(dram_clk), .w_rst(dram_rst),
        .r_clk(ACLK), .r_rst(~ARESETn),
        .wdata(r_wdata), .winc(r_winc), .rinc(r_rinc),
        .rdata(r_rdata), .rempty(r_empty), .wfull(r_full)
    );

    // ================================================================
    //  DRAM CONTROL LOGIC (Operating in dram_clk Domain)
    // ================================================================

    // Internal Reset for Logic (Active Low for consistency with original code style)
    logic dram_rst_n;
    assign dram_rst_n = ~dram_rst;

    // Read / Write channel FSM States
    typedef enum logic [0:0] { R_HOLD , R_READ } state_RD_e;
    typedef enum logic [1:0] { W_HOLD, W_DATA, W_RESP } state_WR_cDRAM_e;

    state_RD_e       state_RD_cs,  state_RD_ns;
    state_WR_cDRAM_e state_WR_cs,  state_WR_ns;

    // DRAM FSM States
    typedef enum logic [2:0] {
        IDLE,
        ACT,
        WAIT_TRCD,
        READ_CMD,
        WRITE_CMD,
        WAIT_CL,
        PRECHARGE,
        WAIT_TRP
    } state_DRAM_cDRAM_e;
    state_DRAM_cDRAM_e state_DRAM_cs, state_DRAM_ns;

    // AXI shadow registers
    logic [`AXI_LEN_BITS-1:0]  LEN_reg;
    logic [`AXI_IDS_BITS-1:0]  ID_reg;
    logic [`AXI_ADDR_BITS-1:0] ADDR_base;
    logic [`AXI_LEN_BITS-1:0]  beat_cnt;

    logic read_reg;
    logic write_reg;

    // DRAM datapath
    logic [31:0]               DRAM_RDATA;
    logic                      DRAM_RVALID;
    logic                      DRAM_VALID_reg;
    logic                      DRAM_WREADY;

    // Address, row-hit
    logic [`AXI_ADDR_BITS-1:0] DRAM_ADDR;
    logic [`AXI_ADDR_BITS-1:0] beat_offset;
    logic [10:0]               current_row_addr;
    logic                      row_open;
    logic                      row_hit;

    // Counters
    logic [2:0]                count_hold;

    // Timing parameters
    localparam logic [2:0] tRP  = 3'd4;
    localparam logic [2:0] tRCD = 3'd4;
    localparam logic [2:0] CL   = 3'd3;

    // ---------------- handshake ----------------
    logic AR_SLAVE_handshake, READ_SLAVE_handshake;
    logic AW_SLAVE_handshake, WRITE_SLAVE_handshake, B_SLAVE_handshake;

    assign AR_SLAVE_handshake    = (dram_arvalid && dram_arready);
    assign READ_SLAVE_handshake  = (dram_rvalid  && dram_rready);
    assign AW_SLAVE_handshake    = (dram_awvalid && dram_awready);
    assign WRITE_SLAVE_handshake = (dram_wvalid  && dram_wready);
    assign B_SLAVE_handshake     = (dram_bready  && dram_bvalid);

    // ================================================================
    //  Read channel FSM (dram_clk)
    // ================================================================
    always_ff @(posedge dram_clk or negedge dram_rst_n) begin
        if (!dram_rst_n)
            state_RD_cs <= R_HOLD;
        else
            state_RD_cs <= state_RD_ns;
    end

    always_comb begin
        unique case (state_RD_cs)
            R_HOLD: state_RD_ns = (AR_SLAVE_handshake)                 ? R_READ : R_HOLD;
            R_READ: state_RD_ns = (READ_SLAVE_handshake && dram_rlast) ? R_HOLD : R_READ;
            default: state_RD_ns = R_HOLD;
        endcase
    end

    assign read_reg = (state_RD_cs != R_HOLD);

    // ================================================================
    //  Write channel FSM (dram_clk)
    // ================================================================
    always_ff @(posedge dram_clk or negedge dram_rst_n) begin
        if (!dram_rst_n)
            state_WR_cs <= W_HOLD;
        else
            state_WR_cs <= state_WR_ns;
    end

    always_comb begin
        unique case (state_WR_cs)
            W_HOLD: state_WR_ns = (AW_SLAVE_handshake)                   ? W_DATA : W_HOLD;
            W_DATA: state_WR_ns = (WRITE_SLAVE_handshake && dram_wlast)  ? W_RESP : W_DATA;
            W_RESP: state_WR_ns = (B_SLAVE_handshake)                    ? W_HOLD : W_RESP;
            default: state_WR_ns = W_HOLD;
        endcase
    end

    assign write_reg = (state_WR_cs != W_HOLD);

    // ================================================================
    //  Burst Control Logic
    // ================================================================
    always_ff @(posedge dram_clk or negedge dram_rst_n) begin
        if (!dram_rst_n) begin
            LEN_reg   <= '0;
            ID_reg    <= '0;
            ADDR_base <= '0;
            beat_cnt  <= '0;
        end
        else begin
            if (AR_SLAVE_handshake) begin
                LEN_reg   <= dram_arlen;
                ID_reg    <= dram_arid;
                ADDR_base <= dram_araddr;
                beat_cnt  <= '0;
            end
            else if (AW_SLAVE_handshake) begin
                LEN_reg   <= dram_awlen;
                ID_reg    <= dram_awid;
                ADDR_base <= dram_awaddr;
                beat_cnt  <= '0;
            end
            else begin
                if (READ_SLAVE_handshake)
                    LEN_reg <= LEN_reg - {{(`AXI_LEN_BITS-1){1'b0}}, 1'b1};
                else if (WRITE_SLAVE_handshake)
                    LEN_reg <= LEN_reg - {{(`AXI_LEN_BITS-1){1'b0}}, 1'b1};

                if ( (state_DRAM_cs == READ_CMD  && read_reg) ||
                     (state_DRAM_cs == WRITE_CMD && write_reg) ) begin
                    beat_cnt <= beat_cnt + {{(`AXI_LEN_BITS-1){1'b0}}, 1'b1};
                end
            end
        end
    end

    // ================================================================
    //  READ / WRITE Logic Interfacing with DRAM-side signals (dram_*)
    // ================================================================
    always_comb begin
        // READ address ready
        dram_arready = (state_RD_cs   == R_HOLD) &&
                       (state_DRAM_cs == IDLE) &&
                       (!write_reg);

        // READ data output
        dram_rid    = ID_reg;
        dram_rdata  = DRAM_RDATA;
        dram_rlast  = (LEN_reg == {`AXI_LEN_BITS{1'b0}});
        dram_rvalid = DRAM_RVALID;

        // WRITE address ready
        dram_awready = (state_WR_cs   == W_HOLD) &&
                       (!read_reg) &&
                       (!dram_arvalid) &&
                       (state_DRAM_cs == IDLE);

        // WRITE data ready / B response
        dram_wready = DRAM_WREADY;
        dram_bid    = ID_reg;
        dram_bvalid = (state_WR_cs == W_RESP);
    end

    // ================================================================
    //  DRAM Address Calc
    // ================================================================
    assign beat_offset = {{(`AXI_ADDR_BITS-`AXI_LEN_BITS){1'b0}}, beat_cnt} << 2;
    assign DRAM_ADDR   = ADDR_base + beat_offset;
    assign row_hit     = row_open && (DRAM_ADDR[22:12] == current_row_addr);

    // ================================================================
    //  Data Path
    // ================================================================
    always_ff @(posedge dram_clk or negedge dram_rst_n) begin
        if (!dram_rst_n) begin
            DRAM_RDATA     <= 32'd0;
            DRAM_VALID_reg <= 1'b0;
        end
        else begin
            if (VALID) begin
                DRAM_RDATA     <= Q;
                DRAM_VALID_reg <= 1'b1;
            end
            else if (READ_SLAVE_handshake) begin
                DRAM_RDATA     <= 32'd0;
                DRAM_VALID_reg <= 1'b0;
            end
        end
    end

    assign DRAM_RVALID = (state_RD_cs == R_READ) && DRAM_VALID_reg;

    assign DRAM_WREADY = ((state_WR_cs   == W_DATA) && (state_DRAM_cs == WAIT_CL) && (count_hold    == CL)) ;
    //? 1'd1 : (state_DRAM_cs == WRITE_CMD) ? 1'd1 : 1'd0;

    // ================================================================
    //  Main DRAM FSM (dram_clk)
    // ================================================================
    always_ff @(posedge dram_clk or negedge dram_rst_n) begin
        if (!dram_rst_n)
            state_DRAM_cs <= IDLE;
        else
            state_DRAM_cs <= state_DRAM_ns;
    end

    always_comb begin
        state_DRAM_ns = state_DRAM_cs;

        unique case (state_DRAM_cs)
            IDLE: begin
                if (AR_SLAVE_handshake) begin
                    if (row_open) begin
                        if (dram_araddr[22:12] == current_row_addr)
                            state_DRAM_ns = READ_CMD;
                        else
                            state_DRAM_ns = PRECHARGE;
                    end
                    else begin
                        state_DRAM_ns = ACT;
                    end
                end
                else if (AW_SLAVE_handshake) begin
                    if (row_open) begin
                        if (dram_awaddr[22:12] == current_row_addr)
                            state_DRAM_ns = WRITE_CMD;
                        else
                            state_DRAM_ns = PRECHARGE;
                    end
                    else begin
                        state_DRAM_ns = ACT;
                    end
                end
            end

            ACT:       state_DRAM_ns = WAIT_TRCD;

            WAIT_TRCD: begin
                if (count_hold == tRCD) begin
                    if (read_reg)
                        state_DRAM_ns = READ_CMD;
                    else if (write_reg && dram_wvalid)
                        state_DRAM_ns = WRITE_CMD;
                end
            end

            READ_CMD, WRITE_CMD: state_DRAM_ns = WAIT_CL;

            WAIT_CL: begin
                if (count_hold == CL) begin
                    if (read_reg) begin
                        if (DRAM_VALID_reg)
                            state_DRAM_ns = WAIT_CL;
                        else begin
                            if (dram_rlast) state_DRAM_ns = IDLE;
                            else begin
                                if (!row_hit) state_DRAM_ns = PRECHARGE;
                                else          state_DRAM_ns = READ_CMD;
                            end
                        end
                    end
                    else if (write_reg) begin
                        if (WRITE_SLAVE_handshake) begin
                            if (dram_wlast) state_DRAM_ns = IDLE;
                            else begin
                                if (!row_hit) state_DRAM_ns = PRECHARGE;
                                else          state_DRAM_ns = WRITE_CMD;
                            end
                        end
                    end
                    else begin
                        state_DRAM_ns = IDLE;
                    end
                end
            end

            PRECHARGE: state_DRAM_ns = WAIT_TRP;

            WAIT_TRP: begin
                if (count_hold == tRP) begin
                    if (read_reg || write_reg) state_DRAM_ns = ACT;
                    else                       state_DRAM_ns = IDLE;
                end
            end

            default: state_DRAM_ns = IDLE;
        endcase
    end

    // ================================================================
    //  Tracking Logic
    // ================================================================
    always_ff @(posedge dram_clk or negedge dram_rst_n) begin
        if (!dram_rst_n) begin
            current_row_addr <= 11'd0;
            row_open         <= 1'b0;
            count_hold       <= 3'd0;
        end
        else begin
            if (state_DRAM_cs == ACT) begin
                current_row_addr <= DRAM_ADDR[22:12];
                row_open         <= 1'b1;
            end

            if (state_DRAM_cs == PRECHARGE) begin
                row_open <= 1'b0;
            end

            if (state_DRAM_cs == WAIT_TRCD) begin
                if (count_hold != tRCD) count_hold <= count_hold + 3'd1;
            end
            else if (state_DRAM_cs == WAIT_CL) begin
                if (count_hold != CL) count_hold <= count_hold + 3'd1;
            end
            else if (state_DRAM_cs == WAIT_TRP) begin
                if (count_hold != tRP) count_hold <= count_hold + 3'd1;
            end
            else begin
                count_hold <= 3'd0;
            end
        end
    end

    // ================================================================
    //  Physical Output
    // ================================================================
    always_comb begin
        CSn  = 1'b0;
        WEn  = 4'd15;
        RASn = 1'b1;
        CASn = 1'b1;

        D    = dram_wdata;
        A    = 11'd0;

        unique case (state_DRAM_cs)
            ACT: begin
                RASn = 1'b0; CASn = 1'b1; WEn = 4'd15;
                A    = DRAM_ADDR[22:12];
            end
            READ_CMD: begin
                RASn = 1'b1; CASn = 1'b0; WEn = 4'd15;
                A    = DRAM_ADDR[11:2];
            end
            WRITE_CMD: begin
                RASn = 1'b1; CASn = 1'b0; WEn = ~dram_wstrb;
                A    = DRAM_ADDR[11:2];
            end
            PRECHARGE: begin
                RASn = 1'b0; CASn = 1'b1; WEn = 4'd0;
                A    = current_row_addr;
            end
            default: ;
        endcase
    end

endmodule
