// 使用者原始 asyc_FIFO 請放在另一個檔案中編譯。
// 本檔只修改 master_simple，不重新定義或修改 asyc_FIFO。
//
// ENABLE_FIFO = 1:
//   PCLK/PRESETn 為 plug-side clock/reset。
//   Plug side 與 AXI ACLK domain 之間透過使用者原始 asyc_FIFO 跨時域。
//
// ENABLE_FIFO = 0:
//   不例化 FIFO，保留原本 master_simple 的直接連接行為。
//   此時 req/data/response 等 plug-side signals 必須屬於 ACLK domain；
//   PCLK/PRESETn 不使用。
//
// 注意：沿用原始 master 行為，目前 write channel 為 single-beat；
//       WLAST 固定於該筆 write data，Len 建議設為 0。

module master_simple #(
    parameter bit     ENABLE_FIFO           = 1'b1,
    parameter integer FIFO_DEPTH            = 4,
    parameter integer REQ_FIFO_DEPTH        = FIFO_DEPTH,
    parameter integer WDATA_FIFO_DEPTH      = FIFO_DEPTH,
    parameter integer RESPONSE_FIFO_DEPTH   = FIFO_DEPTH,
    parameter integer READ_RSP_FIFO_DEPTH   = FIFO_DEPTH,
    parameter integer WRITE_RSP_FIFO_DEPTH  = FIFO_DEPTH
)(
//******************************
//      AXI clock domain
//******************************
    input                   ACLK,
    input                   ARESETn,

    axi_read_if.master      axi_r_m,
    axi_write_if.master     axi_w_m,

//******************************
//      plug clock domain
//******************************
    // ENABLE_FIFO=1 時，以下 plug-side signals 屬於 PCLK domain。
    // ENABLE_FIFO=0 時，PCLK/PRESETn 不使用，plug-side signals 必須屬於 ACLK domain。
    input                   PCLK,
    input                   PRESETn,

//******************************
//      to plug (master interface)
//******************************
    // request
    input                   req_En,
    input                   RW,
    input        [31:0]     Addr,
    input        [2:0]      Size,
    input        [2:0]      Signalize,
    input        [3:0]      Len,
    input        [3:0]      WSTRB,
    input        [1:0]      BURST,
    input        [3:0]      ID,
    output logic            response,

    // data
    output logic [31:0]     read_data,
    output logic            Read_Enable,
    output logic [3:0]      out_ID,
    input        [31:0]     Write_data,
    input                   Write_Enable,
    output logic            WB,
    input                   stall
);

    typedef enum logic [2:0] {
        power_on,
        power_off,
        idle,
        read,
        write,
        wait_req_R,
        wait_req_W
    } state_t;

    // channel handshake
    wire AR_shake = axi_r_m.ARREADY_m && axi_r_m.ARVALID_m;
    wire AW_shake = axi_w_m.AWREADY_m && axi_w_m.AWVALID_m;
    wire W_shake  = axi_w_m.WREADY_m  && axi_w_m.WVALID_m;
    wire B_shake  = axi_w_m.BREADY_m  && axi_w_m.BVALID_m;
    wire R_shake  = axi_r_m.RREADY_m  && axi_r_m.RVALID_m;

    generate
        if (ENABLE_FIFO) begin : g_fifo_mode
            // ============================================================
            // FIFO mode
            //   request/write data : PCLK -> ACLK
            //   response/read/WB   : ACLK -> PCLK
            // ============================================================

            // ------------------------------------------------------------
            // Request FIFO: PCLK -> ACLK
            // {RW, Addr, Size, Signalize, Len, BURST, ID}
            // Signalize is preserved across the FIFO although the original
            // master does not currently consume it.
            // ------------------------------------------------------------
            localparam integer REQ_WIDTH = 1 + 32 + 3 + 3 + 4 + 2 + 4;

            logic [REQ_WIDTH-1:0] req_fifo_wdata;
            logic [REQ_WIDTH-1:0] req_fifo_rdata;
            logic                 req_fifo_winc;
            logic                 req_fifo_rinc;
            logic                 req_fifo_wfull;
            logic                 req_fifo_rempty;

            logic                 req_pending;
            logic                 req_armed;
            logic [REQ_WIDTH-1:0] req_pending_data;
            logic                 req_capture;

            wire req_head_rw;
            wire [31:0] req_head_addr;
            wire [2:0]  req_head_size;
            wire [2:0]  req_head_signalize;
            wire [3:0]  req_head_len;
            wire [1:0]  req_head_burst;
            wire [3:0]  req_head_id;

            assign {
                req_head_rw,
                req_head_addr,
                req_head_size,
                req_head_signalize,
                req_head_len,
                req_head_burst,
                req_head_id
            } = req_fifo_rdata;

            assign req_fifo_wdata = req_pending_data;
            assign req_fifo_winc  = req_pending && !req_fifo_wfull;

            // One request is captured for each assertion of req_En.
            // This also prevents a level-held req_En from being inserted
            // repeatedly while waiting for the AXI address handshake.
            assign req_capture = req_En && req_armed &&
                                 (!req_pending || req_fifo_winc);

            always_ff @(posedge PCLK or negedge PRESETn) begin
                if (!PRESETn) begin
                    req_pending      <= 1'b0;
                    req_armed        <= 1'b1;
                    req_pending_data <= '0;
                end
                else begin
                    if (!req_En)
                        req_armed <= 1'b1;
                    else if (req_capture)
                        req_armed <= 1'b0;

                    case ({req_capture, req_fifo_winc})
                        2'b10: begin
                            req_pending <= 1'b1;
                            req_pending_data <= {
                                RW,
                                Addr,
                                Size,
                                Signalize,
                                Len,
                                BURST,
                                ID
                            };
                        end

                        2'b01: begin
                            req_pending <= 1'b0;
                        end

                        2'b11: begin
                            // Current pending request enters the FIFO while
                            // a new request is captured into the local slot.
                            req_pending <= 1'b1;
                            req_pending_data <= {
                                RW,
                                Addr,
                                Size,
                                Signalize,
                                Len,
                                BURST,
                                ID
                            };
                        end

                        default: begin
                            req_pending <= req_pending;
                        end
                    endcase
                end
            end

            asyc_FIFO #(
                .width  (REQ_WIDTH),
                .depath (REQ_FIFO_DEPTH)
            ) u_req_fifo (
                .w_clk  (PCLK),
                .w_rst  (~PRESETn),
                .r_clk  (ACLK),
                .r_rst  (~ARESETn),
                .wdata  (req_fifo_wdata),
                .winc   (req_fifo_winc),
                .rinc   (req_fifo_rinc),
                .rdata  (req_fifo_rdata),
                .rempty (req_fifo_rempty),
                .wfull  (req_fifo_wfull)
            );

            // ------------------------------------------------------------
            // Write-data FIFO: PCLK -> ACLK
            // {Write_data, WSTRB}
            // ------------------------------------------------------------
            localparam integer WDATA_WIDTH = 32 + 4;

            logic [WDATA_WIDTH-1:0] wdata_fifo_wdata;
            logic [WDATA_WIDTH-1:0] wdata_fifo_rdata;
            logic                   wdata_fifo_winc;
            logic                   wdata_fifo_rinc;
            logic                   wdata_fifo_wfull;
            logic                   wdata_fifo_rempty;

            logic                   wdata_pending;
            logic                   wdata_armed;
            logic [WDATA_WIDTH-1:0] wdata_pending_data;
            logic                   wdata_capture;

            wire [31:0] wdata_head_data;
            wire [3:0]  wdata_head_strb;

            assign {wdata_head_data, wdata_head_strb} = wdata_fifo_rdata;
            assign wdata_fifo_wdata = wdata_pending_data;
            assign wdata_fifo_winc  = wdata_pending && !wdata_fifo_wfull;

            // 沿用原始 master 的使用方式：Write_Enable 每次有效期間只擷取一次。
            assign wdata_capture = Write_Enable && wdata_armed &&
                                   (!wdata_pending || wdata_fifo_winc);

            always_ff @(posedge PCLK or negedge PRESETn) begin
                if (!PRESETn) begin
                    wdata_pending      <= 1'b0;
                    wdata_armed        <= 1'b1;
                    wdata_pending_data <= '0;
                end
                else begin
                    if (!Write_Enable)
                        wdata_armed <= 1'b1;
                    else if (wdata_capture)
                        wdata_armed <= 1'b0;

                    case ({wdata_capture, wdata_fifo_winc})
                        2'b10: begin
                            wdata_pending      <= 1'b1;
                            wdata_pending_data <= {Write_data, WSTRB};
                        end

                        2'b01: begin
                            wdata_pending <= 1'b0;
                        end

                        2'b11: begin
                            wdata_pending      <= 1'b1;
                            wdata_pending_data <= {Write_data, WSTRB};
                        end

                        default: begin
                            wdata_pending <= wdata_pending;
                        end
                    endcase
                end
            end

            asyc_FIFO #(
                .width  (WDATA_WIDTH),
                .depath (WDATA_FIFO_DEPTH)
            ) u_wdata_fifo (
                .w_clk  (PCLK),
                .w_rst  (~PRESETn),
                .r_clk  (ACLK),
                .r_rst  (~ARESETn),
                .wdata  (wdata_fifo_wdata),
                .winc   (wdata_fifo_winc),
                .rinc   (wdata_fifo_rinc),
                .rdata  (wdata_fifo_rdata),
                .rempty (wdata_fifo_rempty),
                .wfull  (wdata_fifo_wfull)
            );

            // ------------------------------------------------------------
            // Address-request response FIFO: ACLK -> PCLK
            // response is generated when AR/AW actually handshakes.
            // ------------------------------------------------------------
            logic response_fifo_rdata;
            logic response_fifo_winc;
            logic response_fifo_rinc;
            logic response_fifo_wfull;
            logic response_fifo_rempty;

            asyc_FIFO #(
                .width  (1),
                .depath (RESPONSE_FIFO_DEPTH)
            ) u_response_fifo (
                .w_clk  (ACLK),
                .w_rst  (~ARESETn),
                .r_clk  (PCLK),
                .r_rst  (~PRESETn),
                .wdata  (1'b1),
                .winc   (response_fifo_winc),
                .rinc   (response_fifo_rinc),
                .rdata  (response_fifo_rdata),
                .rempty (response_fifo_rempty),
                .wfull  (response_fifo_wfull)
            );

            assign response          = !response_fifo_rempty;
            assign response_fifo_rinc = !response_fifo_rempty;

            // ------------------------------------------------------------
            // Read-response FIFO: ACLK -> PCLK
            // {read_data, transaction ID}
            // ------------------------------------------------------------
            localparam integer READ_RSP_WIDTH = 32 + 4;

            logic [READ_RSP_WIDTH-1:0] read_rsp_fifo_wdata;
            logic [READ_RSP_WIDTH-1:0] read_rsp_fifo_rdata;
            logic                      read_rsp_fifo_winc;
            logic                      read_rsp_fifo_rinc;
            logic                      read_rsp_fifo_wfull;
            logic                      read_rsp_fifo_rempty;

            asyc_FIFO #(
                .width  (READ_RSP_WIDTH),
                .depath (READ_RSP_FIFO_DEPTH)
            ) u_read_rsp_fifo (
                .w_clk  (ACLK),
                .w_rst  (~ARESETn),
                .r_clk  (PCLK),
                .r_rst  (~PRESETn),
                .wdata  (read_rsp_fifo_wdata),
                .winc   (read_rsp_fifo_winc),
                .rinc   (read_rsp_fifo_rinc),
                .rdata  (read_rsp_fifo_rdata),
                .rempty (read_rsp_fifo_rempty),
                .wfull  (read_rsp_fifo_wfull)
            );

            assign {read_data, out_ID} = read_rsp_fifo_rdata;
            assign Read_Enable         = !read_rsp_fifo_rempty;
            assign read_rsp_fifo_rinc  = !read_rsp_fifo_rempty;

            // ------------------------------------------------------------
            // Write-response FIFO: ACLK -> PCLK
            // WB is generated when AXI B channel actually handshakes.
            // ------------------------------------------------------------
            logic write_rsp_fifo_rdata;
            logic write_rsp_fifo_winc;
            logic write_rsp_fifo_rinc;
            logic write_rsp_fifo_wfull;
            logic write_rsp_fifo_rempty;

            asyc_FIFO #(
                .width  (1),
                .depath (WRITE_RSP_FIFO_DEPTH)
            ) u_write_rsp_fifo (
                .w_clk  (ACLK),
                .w_rst  (~ARESETn),
                .r_clk  (PCLK),
                .r_rst  (~PRESETn),
                .wdata  (1'b1),
                .winc   (write_rsp_fifo_winc),
                .rinc   (write_rsp_fifo_rinc),
                .rdata  (write_rsp_fifo_rdata),
                .rempty (write_rsp_fifo_rempty),
                .wfull  (write_rsp_fifo_wfull)
            );

            assign WB                   = !write_rsp_fifo_rempty;
            assign write_rsp_fifo_rinc  = !write_rsp_fifo_rempty;

            // ------------------------------------------------------------
            // ACLK-domain AXI master FSM
            // ------------------------------------------------------------
            state_t state;
            state_t next_state;

            logic [7:0]  ID_current;
            logic [3:0]  LEN_current;
            logic [31:0] Addr_current;
            logic [3:0]  SIZE_current;
            logic [3:0]  BURST_current;
            logic        W_done;

            // Request FIFO is consumed only after the AXI address channel
            // handshakes. The response FIFO must have room before allowing
            // that handshake, otherwise the response pulse could be lost.
            assign req_fifo_rinc       = AR_shake || AW_shake;
            assign response_fifo_winc  = AR_shake || AW_shake;

            always_ff @(posedge ACLK or negedge ARESETn) begin
                if (!ARESETn)
                    state <= power_on;
                else
                    state <= next_state;
            end

            always_comb begin
                case (state)
                    idle: begin
                        if (AR_shake)
                            next_state = read;
                        else if (AW_shake)
                            next_state = write;
                        else
                            next_state = idle;
                    end

                    read: begin
                        if (R_shake && axi_r_m.RLAST_m)
                            next_state = idle;
                        else
                            next_state = read;
                    end

                    write: begin
                        if (B_shake)
                            next_state = idle;
                        else
                            next_state = write;
                    end

                    power_off: next_state = power_off;
                    power_on : next_state = idle;
                    default  : next_state = power_off;
                endcase
            end

            always_ff @(posedge ACLK or negedge ARESETn) begin
                if (!ARESETn) begin
                    ID_current    <= 8'd0;
                    LEN_current   <= 4'd0;
                    Addr_current  <= 32'd0;
                    SIZE_current  <= 4'd0;
                    BURST_current <= 4'd0;
                end
                else if (AR_shake || AW_shake) begin
                    ID_current    <= {4'd0, req_head_id};
                    LEN_current   <= req_head_len;
                    Addr_current  <= req_head_addr;
                    SIZE_current  <= {1'b0, req_head_size};
                    BURST_current <= {2'b00, req_head_burst};
                end
            end

            always_ff @(posedge ACLK or negedge ARESETn) begin
                if (!ARESETn)
                    W_done <= 1'b0;
                else if (B_shake)
                    W_done <= 1'b0;
                else if (W_shake)
                    W_done <= 1'b1;
            end

            // AXI write address channel
            assign axi_w_m.AWID_m     = {4'd0, req_head_id};
            assign axi_w_m.AWADDR_m   = req_head_addr;
            assign axi_w_m.AWLEN_m    = req_head_len;
            assign axi_w_m.AWSIZE_m   = req_head_size;
            assign axi_w_m.AWBURST_m  = req_head_burst;
            assign axi_w_m.AWVALID_m  = (!stall &&
                                         state == idle &&
                                         !req_fifo_rempty &&
                                         req_head_rw &&
                                         !response_fifo_wfull);

            // AXI write data channel
            assign axi_w_m.WDATA_m    = wdata_head_data;
            assign axi_w_m.WSTRB_m    = wdata_head_strb;
            assign axi_w_m.WLAST_m    = (state == write && !wdata_fifo_rempty);
            assign axi_w_m.WVALID_m   = (!stall &&
                                         state == write &&
                                         !W_done &&
                                         !wdata_fifo_rempty);
            assign wdata_fifo_rinc    = W_shake;

            // AXI write response channel
            assign axi_w_m.BREADY_m   = (!stall &&
                                         state == write &&
                                         W_done &&
                                         !write_rsp_fifo_wfull);
            assign write_rsp_fifo_winc = B_shake;

            // AXI read address channel
            assign axi_r_m.ARID_m     = {4'd0, req_head_id};
            assign axi_r_m.ARADDR_m   = req_head_addr;
            assign axi_r_m.ARLEN_m    = req_head_len;
            assign axi_r_m.ARSIZE_m   = req_head_size;
            assign axi_r_m.ARBURST_m  = req_head_burst;
            assign axi_r_m.ARVALID_m  = (!stall &&
                                         state == idle &&
                                         !req_fifo_rempty &&
                                         !req_head_rw &&
                                         !response_fifo_wfull);

            // AXI read data channel
            assign axi_r_m.RREADY_m   = (!stall &&
                                         state == read &&
                                         !read_rsp_fifo_wfull);
            assign read_rsp_fifo_wdata = {
                axi_r_m.RDATA_m,
                ID_current[3:0]
            };
            assign read_rsp_fifo_winc = R_shake;

            // req_head_signalize is intentionally preserved but unused,
            // matching the behavior of the original master_simple.

        end
        else begin : g_direct_mode
            // ============================================================
            // Direct mode: original master_simple behavior
            // No FIFO is instantiated in this generate branch.
            // ============================================================
            state_t state;
            state_t next_state;

            reg [7:0]  ID_current;
            reg [3:0]  LEN_current;
            reg [31:0] Addr_current;
            reg [3:0]  SIZE_current;
            reg [3:0]  BURST_current;
            reg [3:0]  WSTRB_current;
            reg [31:0] WDATA_current;
            reg         WLAST_current;
            reg         W_done;
            reg         W_valid;

            // request/data response outputs
            assign response    = AR_shake || AW_shake;
            assign read_data   = axi_r_m.RDATA_m;
            assign Read_Enable = R_shake;
            assign out_ID      = ID_current[3:0];
            assign WB          = B_shake;

            always @(posedge ACLK or negedge ARESETn) begin
                if (!ARESETn)
                    state <= power_on;
                else
                    state <= next_state;
            end

            always @(*) begin
                case (state)
                    idle: begin
                        if (req_En && !RW && AR_shake)
                            next_state = read;
                        else if (req_En && RW && AW_shake)
                            next_state = write;
                        else if (req_En && !RW && !AR_shake)
                            next_state = wait_req_R;
                        else if (req_En && RW && !AW_shake)
                            next_state = wait_req_W;
                        else
                            next_state = idle;
                    end

                    read: begin
                        if (R_shake && axi_r_m.RLAST_m)
                            next_state = idle;
                        else
                            next_state = read;
                    end

                    write: begin
                        if (B_shake)
                            next_state = idle;
                        else
                            next_state = write;
                    end

                    wait_req_R: begin
                        if (AR_shake)
                            next_state = read;
                        else
                            next_state = wait_req_R;
                    end

                    wait_req_W: begin
                        if (AW_shake)
                            next_state = write;
                        else
                            next_state = wait_req_W;
                    end

                    power_off: next_state = power_off;
                    power_on : next_state = idle;
                    default  : next_state = power_off;
                endcase
            end

            always @(posedge ACLK or negedge ARESETn) begin
                if (!ARESETn) begin
                    ID_current    <= 8'd0;
                    LEN_current   <= 4'd0;
                    Addr_current  <= 32'd0;
                    SIZE_current  <= 4'd0;
                    BURST_current <= 4'd0;
                end
                else if (state == idle && next_state != idle) begin
                    ID_current    <= ID;
                    LEN_current   <= Len;
                    Addr_current  <= Addr;
                    SIZE_current  <= Size;
                    BURST_current <= BURST;
                end
            end

            always @(posedge ACLK or negedge ARESETn) begin
                if (!ARESETn) begin
                    WDATA_current <= 32'd0;
                    WSTRB_current <= 4'd0;
                    WLAST_current <= 1'd0;
                    W_valid       <= 1'd0;
                    W_done        <= 1'd0;
                end
                else if (B_shake) begin
                    WLAST_current <= 1'd0;
                    W_valid       <= 1'd0;
                    W_done        <= 1'd0;
                end
                else if (Write_Enable && !W_valid && W_shake) begin
                    WDATA_current <= Write_data;
                    WSTRB_current <= WSTRB;
                    WLAST_current <= 1'd1;
                    W_valid       <= 1'd1;
                    W_done        <= 1'd1;
                end
                else if (Write_Enable && !W_valid &&
                         !(state == idle && !req_En)) begin
                    WDATA_current <= Write_data;
                    WSTRB_current <= WSTRB;
                    WLAST_current <= 1'd1;
                    W_valid       <= 1'd1;
                    W_done        <= 1'd0;
                end
                else if (state == write && W_shake) begin
                    W_done <= 1'd1;
                end
            end

            assign axi_w_m.AWID_m     = (state == idle) ? ID : ID_current;
            assign axi_w_m.AWADDR_m   = (state == idle) ? Addr : Addr_current;
            assign axi_w_m.AWLEN_m    = (state == idle) ? Len : LEN_current;
            assign axi_w_m.AWSIZE_m   = (state == idle) ? Size : SIZE_current[2:0];
            assign axi_w_m.AWBURST_m  = (state == idle) ? BURST : BURST_current[1:0];
            assign axi_w_m.AWVALID_m  = (stall) ? 1'b0 :
                                         (state == idle && req_En && RW && ARESETn) ? 1'b1 :
                                         (state == wait_req_W) ? 1'b1 : 1'b0;

            assign axi_w_m.WDATA_m    = (state == write && W_valid) ? WDATA_current :
                                         (state == write && !W_valid && Write_Enable) ? Write_data : 32'd0;
            assign axi_w_m.WSTRB_m    = (state == write && W_valid) ? WSTRB_current :
                                         (state == write && !W_valid && Write_Enable) ? WSTRB : 4'd0;
            assign axi_w_m.WLAST_m    = (state == write) ? WLAST_current : 1'b0;
            assign axi_w_m.WVALID_m   = (stall) ? 1'b0 :
                                         (state == write && !W_done && W_valid) ? 1'b1 : 1'b0;

            assign axi_r_m.ARID_m     = (state == idle) ? ID : ID_current;
            assign axi_r_m.ARADDR_m   = (state == idle) ? Addr : Addr_current;
            assign axi_r_m.ARLEN_m    = (state == idle) ? Len : LEN_current;
            assign axi_r_m.ARSIZE_m   = (state == idle) ? Size : SIZE_current[2:0];
            assign axi_r_m.ARBURST_m  = (state == idle) ? BURST : BURST_current[1:0];
            assign axi_r_m.ARVALID_m  = (stall) ? 1'b0 :
                                         (state == idle && req_En && !RW && ARESETn) ? 1'b1 :
                                         (state == wait_req_R) ? 1'b1 : 1'b0;

            assign axi_w_m.BREADY_m   = (stall) ? 1'b0 :
                                         (state == write && W_done) ? 1'b1 : 1'b0;

            assign axi_r_m.RREADY_m   = (stall) ? 1'b0 :
                                         (state == read) ? 1'b1 : 1'b0;

            // Signalize and PCLK/PRESETn are intentionally unused in direct mode,
            // matching the original master behavior.
        end
    endgenerate

endmodule
