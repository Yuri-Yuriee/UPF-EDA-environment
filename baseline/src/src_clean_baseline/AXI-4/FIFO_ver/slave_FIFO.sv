// 使用者原始 asyc_FIFO 請放在另一個檔案中編譯。
// 本檔只修改 slave_simple，不重新定義或修改 asyc_FIFO。

// ============================================================
// AXI slave with optional asynchronous-FIFO bridge
// ------------------------------------------------------------
// ENABLE_FIFO = 1:
//   ACLK domain and MCLK domain may be asynchronous.
//   Three asynchronous FIFOs are instantiated.
//
// ENABLE_FIFO = 0:
//   No FIFO is instantiated. All memory-side behavior is driven
//   directly by ACLK-domain logic. MCLK/MRESETn are unused, so the
//   memory/peripheral side must belong to the ACLK/ARESETn domain.
//
// FIFO_DEPTH is retained as a common/default depth for backward
// compatibility. Each FIFO depth can also be overridden separately.
// All enabled FIFO depths must be powers of two and >= 2.
// ============================================================
module slave_simple #(
    parameter integer outstanding          = 4,
    parameter bit     ENABLE_FIFO          = 1'b1,
    parameter integer FIFO_DEPTH           = 4,
    parameter integer REQ_FIFO_DEPTH       = FIFO_DEPTH,
    parameter integer READ_RSP_FIFO_DEPTH  = FIFO_DEPTH,
    parameter integer WRITE_RSP_FIFO_DEPTH = FIFO_DEPTH
)(
    input  logic         ACLK,
    input  logic         ARESETn,

    // Used only when ENABLE_FIFO=1.
    input  logic         MCLK,
    input  logic         MRESETn,

    axi_read_if.slave    axi_r_s,
    axi_write_if.slave   axi_w_s,

    input  logic         stall_W,
    input  logic         stall_R,

    input  logic         in_miss,
    input  logic         in_hit,
    input  logic [31:0]  read_data,
    output logic         Read_Enable,
    output logic [31:0]  Addr,
    output logic [31:0]  Write_data,
    output logic         Write_Enable,
    output logic [3:0]   out_WSTRB
);

    localparam logic [1:0] RESP_OKAY = 2'b00;

    typedef enum logic [1:0] {
        IDLE_ST,
        READ_ST,
        WRITE_ST
    } state_st;

    // ========================================================
    // AXI interface aliases
    // ========================================================
    wire [7:0]  AWID_S    = axi_w_s.AWID_s;
    wire [31:0] AWADDR_S  = axi_w_s.AWADDR_s;
    wire [3:0]  AWLEN_S   = axi_w_s.AWLEN_s;
    wire [2:0]  AWSIZE_S  = axi_w_s.AWSIZE_s;
    wire [1:0]  AWBURST_S = axi_w_s.AWBURST_s;
    wire        AWVALID_S = axi_w_s.AWVALID_s;
    logic       AWREADY_S;

    wire [31:0] WDATA_S   = axi_w_s.WDATA_s;
    wire [3:0]  WSTRB_S   = axi_w_s.WSTRB_s;
    wire        WLAST_S   = axi_w_s.WLAST_s;
    wire        WVALID_S  = axi_w_s.WVALID_s;
    logic       WREADY_S;

    logic [7:0] BID_S;
    logic [1:0] BRESP_S;
    logic       BVALID_S;
    wire        BREADY_S = axi_w_s.BREADY_s;

    wire [7:0]  ARID_S    = axi_r_s.ARID_s;
    wire [31:0] ARADDR_S  = axi_r_s.ARADDR_s;
    wire [3:0]  ARLEN_S   = axi_r_s.ARLEN_s;
    wire [2:0]  ARSIZE_S  = axi_r_s.ARSIZE_s;
    wire [1:0]  ARBURST_S = axi_r_s.ARBURST_s;
    wire        ARVALID_S = axi_r_s.ARVALID_s;
    logic       ARREADY_S;

    logic [7:0]  RID_S;
    logic [31:0] RDATA_S;
    logic [1:0]  RRESP_S;
    logic        RLAST_S;
    logic        RVALID_S;
    wire         RREADY_S = axi_r_s.RREADY_s;

    assign axi_w_s.AWREADY_s = AWREADY_S;
    assign axi_w_s.WREADY_s  = WREADY_S;
    assign axi_w_s.BID_s     = BID_S;
    assign axi_w_s.BRESP_s   = BRESP_S;
    assign axi_w_s.BVALID_s  = BVALID_S;

    assign axi_r_s.ARREADY_s = ARREADY_S;
    assign axi_r_s.RID_s     = RID_S;
    assign axi_r_s.RDATA_s   = RDATA_S;
    assign axi_r_s.RRESP_s   = RRESP_S;
    assign axi_r_s.RLAST_s   = RLAST_S;
    assign axi_r_s.RVALID_s  = RVALID_S;

    wire AR_shake = ARVALID_S && ARREADY_S;
    wire AW_shake = AWVALID_S && AWREADY_S;
    wire W_shake  = WVALID_S  && WREADY_S;
    wire R_shake  = RVALID_S  && RREADY_S;
    wire B_shake  = BVALID_S  && BREADY_S;

    generate
        if (ENABLE_FIFO) begin : g_fifo_mode
            // =================================================
            // FIFO mode: ACLK <-> MCLK
            // =================================================

            // Request FIFO: ACLK -> MCLK
            // {is_write, is_last, address, write_data, write_strobe}
            localparam integer REQ_WIDTH = 1 + 1 + 32 + 32 + 4;

            logic [REQ_WIDTH-1:0] req_wdata;
            logic [REQ_WIDTH-1:0] req_rdata;
            logic                 req_winc;
            logic                 req_rinc;
            logic                 req_wfull;
            logic                 req_rempty;

            logic        req_is_write;
            logic        req_is_last;
            logic [31:0] req_addr;
            logic [31:0] req_write_data;
            logic [3:0]  req_wstrb;

            assign {
                req_is_write,
                req_is_last,
                req_addr,
                req_write_data,
                req_wstrb
            } = req_rdata;

            asyc_FIFO #(
                .width  (REQ_WIDTH),
                .depath (REQ_FIFO_DEPTH)
            ) u_req_fifo (
                .w_clk  (ACLK),
                .w_rst  (~ARESETn),
                .r_clk  (MCLK),
                .r_rst  (~MRESETn),
                .wdata  (req_wdata),
                .winc   (req_winc),
                .rinc   (req_rinc),
                .rdata  (req_rdata),
                .rempty (req_rempty),
                .wfull  (req_wfull)
            );

            // Read-response FIFO: MCLK -> ACLK
            logic [31:0] read_rsp_rdata;
            logic        read_rsp_winc;
            logic        read_rsp_rinc;
            logic        read_rsp_wfull;
            logic        read_rsp_rempty;

            asyc_FIFO #(
                .width  (32),
                .depath (READ_RSP_FIFO_DEPTH)
            ) u_read_rsp_fifo (
                .w_clk  (MCLK),
                .w_rst  (~MRESETn),
                .r_clk  (ACLK),
                .r_rst  (~ARESETn),
                .wdata  (read_data),
                .winc   (read_rsp_winc),
                .rinc   (read_rsp_rinc),
                .rdata  (read_rsp_rdata),
                .rempty (read_rsp_rempty),
                .wfull  (read_rsp_wfull)
            );

            // Write-completion FIFO: MCLK -> ACLK
            logic write_rsp_rdata;
            logic write_rsp_winc;
            logic write_rsp_rinc;
            logic write_rsp_wfull;
            logic write_rsp_rempty;

            asyc_FIFO #(
                .width  (1),
                .depath (WRITE_RSP_FIFO_DEPTH)
            ) u_write_rsp_fifo (
                .w_clk  (MCLK),
                .w_rst  (~MRESETn),
                .r_clk  (ACLK),
                .r_rst  (~ARESETn),
                .wdata  (1'b1),
                .winc   (write_rsp_winc),
                .rinc   (write_rsp_rinc),
                .rdata  (write_rsp_rdata),
                .rempty (write_rsp_rempty),
                .wfull  (write_rsp_wfull)
            );

            // -----------------------------------------------
            // ACLK-domain transaction state
            // -----------------------------------------------
            state_st     state;
            logic [7:0]  id_current;
            logic [31:0] read_next_addr;
            logic [4:0]  read_beats_left;
            logic [31:0] write_addr;
            logic [4:0]  write_beats_left;
            logic        write_wait_b;

            // Read has priority when ARVALID and AWVALID arrive together.
            always_comb begin
                ARREADY_S = 1'b0;
                AWREADY_S = 1'b0;
                WREADY_S  = 1'b0;

                if (state == IDLE_ST) begin
                    ARREADY_S = !stall_R && !req_wfull;
                    AWREADY_S = !stall_W && !ARVALID_S;
                end
                else if (state == WRITE_ST) begin
                    WREADY_S = !stall_W && !write_wait_b && !req_wfull;
                end
            end

            // Read data remains in the response FIFO until accepted.
            // A non-last beat can handshake only if the next read command
            // can also be inserted into the request FIFO.
            always_comb begin
                RID_S    = id_current;
                RDATA_S  = read_rsp_rdata;
                RRESP_S  = RESP_OKAY;
                RLAST_S  = (read_beats_left == 5'd1);
                RVALID_S = 1'b0;

                if (state == READ_ST && !stall_R && !read_rsp_rempty) begin
                    if (read_beats_left == 5'd1)
                        RVALID_S = 1'b1;
                    else
                        RVALID_S = !req_wfull;
                end
            end

            always_comb begin
                BID_S    = id_current;
                BRESP_S  = RESP_OKAY;
                BVALID_S = (state == WRITE_ST) &&
                           write_wait_b &&
                           !stall_W &&
                           !write_rsp_rempty;
            end

            // Request FIFO write multiplexer.
            always_comb begin
                req_winc  = 1'b0;
                req_wdata = '0;

                if (AR_shake) begin
                    req_winc  = 1'b1;
                    req_wdata = {
                        1'b0,
                        (ARLEN_S == 4'd0),
                        ARADDR_S,
                        32'd0,
                        4'd0
                    };
                end
                else if (R_shake && read_beats_left != 5'd1) begin
                    req_winc  = 1'b1;
                    req_wdata = {
                        1'b0,
                        (read_beats_left == 5'd2),
                        read_next_addr,
                        32'd0,
                        4'd0
                    };
                end
                else if (W_shake) begin
                    req_winc  = 1'b1;
                    req_wdata = {
                        1'b1,
                        (write_beats_left == 5'd1),
                        write_addr,
                        WDATA_S,
                        WSTRB_S
                    };
                end
            end

            assign read_rsp_rinc  = R_shake;
            assign write_rsp_rinc = B_shake;

            always_ff @(posedge ACLK or negedge ARESETn) begin
                if (!ARESETn) begin
                    state            <= IDLE_ST;
                    id_current       <= 8'd0;
                    read_next_addr   <= 32'd0;
                    read_beats_left  <= 5'd0;
                    write_addr       <= 32'd0;
                    write_beats_left <= 5'd0;
                    write_wait_b     <= 1'b0;
                end
                else begin
                    case (state)
                        IDLE_ST: begin
                            write_wait_b <= 1'b0;

                            if (AR_shake) begin
                                state           <= READ_ST;
                                id_current      <= ARID_S;
                                read_next_addr  <= ARADDR_S + 32'd4;
                                read_beats_left <= {1'b0, ARLEN_S} + 5'd1;
                            end
                            else if (AW_shake) begin
                                state            <= WRITE_ST;
                                id_current       <= AWID_S;
                                write_addr       <= AWADDR_S;
                                write_beats_left <= {1'b0, AWLEN_S} + 5'd1;
                            end
                        end

                        READ_ST: begin
                            if (R_shake) begin
                                if (read_beats_left == 5'd1) begin
                                    state           <= IDLE_ST;
                                    read_beats_left <= 5'd0;
                                end
                                else begin
                                    read_beats_left <= read_beats_left - 5'd1;
                                    read_next_addr  <= read_next_addr + 32'd4;
                                end
                            end
                        end

                        WRITE_ST: begin
                            if (W_shake) begin
                                write_addr <= write_addr + 32'd4;

                                if (write_beats_left == 5'd1) begin
                                    write_beats_left <= 5'd0;
                                    write_wait_b     <= 1'b1;
                                end
                                else begin
                                    write_beats_left <= write_beats_left - 5'd1;
                                end
                            end

                            if (B_shake) begin
                                state        <= IDLE_ST;
                                write_wait_b <= 1'b0;
                            end
                        end

                        default: begin
                            state <= IDLE_ST;
                        end
                    endcase
                end
            end

            // -----------------------------------------------
            // MCLK-domain request execution
            // -----------------------------------------------
            logic request_can_execute;

            always_comb begin
                request_can_execute = 1'b0;

                if (!req_rempty) begin
                    if (req_is_write) begin
                        // The final write needs room for its B-response token.
                        request_can_execute = !req_is_last || !write_rsp_wfull;
                    end
                    else begin
                        // Every read needs room for returned read data.
                        request_can_execute = !read_rsp_wfull;
                    end
                end
            end

            assign req_rinc = request_can_execute;

            always_comb begin
                Addr         = req_addr;
                Write_data   = req_write_data;
                out_WSTRB    = req_wstrb;
                Read_Enable  = request_can_execute && !req_is_write;
                Write_Enable = request_can_execute &&  req_is_write;

                read_rsp_winc  = Read_Enable;
                write_rsp_winc = Write_Enable && req_is_last;
            end

        end
        else begin : g_direct_mode
            // =================================================
            // Direct mode: no FIFO, all logic belongs to ACLK
            // =================================================
            state_st     state;
            logic [7:0]  id_current;

            logic [31:0] read_data_buffer;
            logic        read_valid_buffer;
            logic [31:0] read_next_addr;
            logic [4:0]  read_beats_left;

            logic [31:0] write_addr;
            logic [4:0]  write_beats_left;
            logic        write_wait_b;

            // Read has priority when ARVALID and AWVALID arrive together.
            always_comb begin
                ARREADY_S = 1'b0;
                AWREADY_S = 1'b0;
                WREADY_S  = 1'b0;

                if (state == IDLE_ST) begin
                    ARREADY_S = !stall_R;
                    AWREADY_S = !stall_W && !ARVALID_S;
                end
                else if (state == WRITE_ST) begin
                    WREADY_S = !stall_W && !write_wait_b;
                end
            end

            always_comb begin
                RID_S    = id_current;
                RDATA_S  = read_data_buffer;
                RRESP_S  = RESP_OKAY;
                RLAST_S  = (read_beats_left == 5'd1);
                RVALID_S = (state == READ_ST) &&
                           read_valid_buffer &&
                           !stall_R;
            end

            always_comb begin
                BID_S    = id_current;
                BRESP_S  = RESP_OKAY;
                BVALID_S = (state == WRITE_ST) &&
                           write_wait_b &&
                           !stall_W;
            end

            // The direct path assumes read_data is combinationally valid
            // from Addr in the same ACLK cycle as Read_Enable.
            always_comb begin
                Read_Enable  = 1'b0;
                Write_Enable = 1'b0;
                Addr         = 32'd0;
                Write_data   = WDATA_S;
                out_WSTRB    = WSTRB_S;

                if (AR_shake) begin
                    Read_Enable = 1'b1;
                    Addr        = ARADDR_S;
                end
                else if (R_shake && read_beats_left != 5'd1) begin
                    Read_Enable = 1'b1;
                    Addr        = read_next_addr;
                end
                else if (W_shake) begin
                    Write_Enable = 1'b1;
                    Addr         = write_addr;
                end
            end

            always_ff @(posedge ACLK or negedge ARESETn) begin
                if (!ARESETn) begin
                    state              <= IDLE_ST;
                    id_current         <= 8'd0;
                    read_data_buffer   <= 32'd0;
                    read_valid_buffer  <= 1'b0;
                    read_next_addr     <= 32'd0;
                    read_beats_left    <= 5'd0;
                    write_addr         <= 32'd0;
                    write_beats_left   <= 5'd0;
                    write_wait_b       <= 1'b0;
                end
                else begin
                    case (state)
                        IDLE_ST: begin
                            read_valid_buffer <= 1'b0;
                            write_wait_b      <= 1'b0;

                            if (AR_shake) begin
                                state             <= READ_ST;
                                id_current        <= ARID_S;
                                read_data_buffer  <= read_data;
                                read_valid_buffer <= 1'b1;
                                read_next_addr    <= ARADDR_S + 32'd4;
                                read_beats_left   <= {1'b0, ARLEN_S} + 5'd1;
                            end
                            else if (AW_shake) begin
                                state            <= WRITE_ST;
                                id_current       <= AWID_S;
                                write_addr       <= AWADDR_S;
                                write_beats_left <= {1'b0, AWLEN_S} + 5'd1;
                            end
                        end

                        READ_ST: begin
                            if (R_shake) begin
                                if (read_beats_left == 5'd1) begin
                                    state             <= IDLE_ST;
                                    read_valid_buffer <= 1'b0;
                                    read_beats_left   <= 5'd0;
                                end
                                else begin
                                    read_data_buffer  <= read_data;
                                    read_valid_buffer <= 1'b1;
                                    read_beats_left   <= read_beats_left - 5'd1;
                                    read_next_addr    <= read_next_addr + 32'd4;
                                end
                            end
                        end

                        WRITE_ST: begin
                            if (W_shake) begin
                                write_addr <= write_addr + 32'd4;

                                if (write_beats_left == 5'd1) begin
                                    write_beats_left <= 5'd0;
                                    write_wait_b     <= 1'b1;
                                end
                                else begin
                                    write_beats_left <= write_beats_left - 5'd1;
                                end
                            end

                            if (B_shake) begin
                                state        <= IDLE_ST;
                                write_wait_b <= 1'b0;
                            end
                        end

                        default: begin
                            state <= IDLE_ST;
                        end
                    endcase
                end
            end

        end
    endgenerate

    // Intentionally unused by the current fixed-INCR, 32-bit implementation:
    // outstanding, AWSIZE_S, AWBURST_S, ARSIZE_S, ARBURST_S, WLAST_S,
    // in_miss and in_hit.

endmodule
