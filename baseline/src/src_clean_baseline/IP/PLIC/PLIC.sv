module simple_plic #(
    parameter int SRC_NUM             = 1,
    parameter int PRIO_W              = 3,
    parameter int DEFAULT_PRIORITY    = 1,
    parameter logic [31:0] BASE_ADDR  = 32'h0C00_0000
)(
    // PLIC / AXI clock domain
    input  logic                 clk,
    input  logic                 rst_n,

    // CPU clock domain
    input  logic                 cpu_clk,
    input  logic                 cpu_rst_n,

    input  logic [SRC_NUM-1:0]   irq_i,

    output logic                 irq_o,
    output logic [$clog2(SRC_NUM+1)-1:0] irq_id_o,

    axi_read_if.slave            axi_r,
    axi_write_if.slave           axi_w
);

    localparam int ID_W =
        (SRC_NUM <= 1) ? 1 : $clog2(SRC_NUM + 1);

    localparam int WORD_NUM =
        (SRC_NUM + 31) / 32;

    // 簡化版 RISC-V PLIC register map
    localparam logic [31:0] PRIORITY_BASE  = 32'h0000_0000;
    localparam logic [31:0] PENDING_BASE   = 32'h0000_1000;
    localparam logic [31:0] ENABLE_BASE    = 32'h0000_2000;
    localparam logic [31:0] THRESHOLD_ADDR = 32'h0020_0000;
    localparam logic [31:0] CLAIM_ADDR     = 32'h0020_0004;

    // source ID 0 不使用
    logic [PRIO_W-1:0] priority_q [0:SRC_NUM];
    logic [SRC_NUM:0]  pending_q;
    logic [SRC_NUM:0]  enable_q;
    logic [SRC_NUM:0]  claimed_q;
    logic [PRIO_W-1:0] threshold_q;

    logic [ID_W-1:0]   best_id_comb;
    logic [PRIO_W-1:0] best_prio_comb;

    // ============================================================
    // Interrupt output synchronization
    //
    // Source domain:
    //   clk / rst_n
    //
    // Destination domain:
    //   cpu_clk / cpu_rst_n
    // ============================================================
    logic irq_raw;
    logic irq_src_ff;

    (* ASYNC_REG = "TRUE" *) logic irq_sync_ff1;
    (* ASYNC_REG = "TRUE" *) logic irq_sync_ff2;

    // ============================================================
    // Pick highest priority pending interrupt
    // Tie-break: smaller source ID wins
    // ============================================================
    always_comb begin
        best_id_comb   = '0;
        best_prio_comb = '0;

        for (int i = 1; i <= SRC_NUM; i++) begin
            if (pending_q[i] &&
                enable_q[i]  &&
                (priority_q[i] > threshold_q) &&
                (priority_q[i] > best_prio_comb)) begin

                best_id_comb   = ID_W'(i);
                best_prio_comb = priority_q[i];
            end
        end
    end

    assign irq_raw  = (best_id_comb != '0);
    assign irq_id_o = best_id_comb;

    // ============================================================
    // Source-domain register
    // 先使用 PLIC source clock 擋一級 DFF
    // ============================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            irq_src_ff <= 1'b0;
        end
        else begin
            irq_src_ff <= irq_raw;
        end
    end

    // ============================================================
    // CPU-domain two-stage synchronizer
    // ============================================================
    always_ff @(posedge cpu_clk or negedge cpu_rst_n) begin
        if (!cpu_rst_n) begin
            irq_sync_ff1 <= 1'b0;
            irq_sync_ff2 <= 1'b0;
        end
        else begin
            irq_sync_ff1 <= irq_src_ff;
            irq_sync_ff2 <= irq_sync_ff1;
        end
    end

    assign irq_o = irq_sync_ff2;

    // ============================================================
    // AXI READ channel
    // ============================================================
    logic                      rvalid_q;
    logic [`AXI_IDS_BITS-1:0]  rid_q;
    logic [`AXI_DATA_BITS-1:0] rdata_q;
    logic [1:0]                rresp_q;

    assign axi_r.ARREADY_s = !rvalid_q;

    assign axi_r.RID_s     = rid_q;
    assign axi_r.RDATA_s   = rdata_q;
    assign axi_r.RRESP_s   = rresp_q;
    assign axi_r.RLAST_s   = 1'b1;
    assign axi_r.RVALID_s  = rvalid_q;

    wire r_ar_fire =
        axi_r.ARVALID_s && axi_r.ARREADY_s;

    wire r_done =
        axi_r.RVALID_s && axi_r.RREADY_s;

    function automatic logic [`AXI_DATA_BITS-1:0] make_rdata;
        input logic [`AXI_ADDR_BITS-1:0] addr;

        logic [31:0] off;
        logic [31:0] data32;
        int unsigned sid;
        int unsigned word;

        begin
            off    = addr[31:0] - BASE_ADDR;
            data32 = 32'd0;

            // priority[source_id]
            if ((off >= PRIORITY_BASE) &&
                (off < (PRIORITY_BASE +
                        ((SRC_NUM + 1) * 4))) &&
                (off[1:0] == 2'b00)) begin

                sid = (off - PRIORITY_BASE) >> 2;

                if (sid <= SRC_NUM) begin
                    data32[PRIO_W-1:0] =
                        priority_q[sid];
                end
            end

            // pending bit array
            else if ((off >= PENDING_BASE) &&
                     (off < (PENDING_BASE +
                             (WORD_NUM * 4))) &&
                     (off[1:0] == 2'b00)) begin

                word = (off - PENDING_BASE) >> 2;

                for (int i = 1; i <= SRC_NUM; i++) begin
                    if ((i >> 5) == word) begin
                        data32[i % 32] = pending_q[i];
                    end
                end
            end

            // enable bit array
            else if ((off >= ENABLE_BASE) &&
                     (off < (ENABLE_BASE +
                             (WORD_NUM * 4))) &&
                     (off[1:0] == 2'b00)) begin

                word = (off - ENABLE_BASE) >> 2;

                for (int i = 1; i <= SRC_NUM; i++) begin
                    if ((i >> 5) == word) begin
                        data32[i % 32] = enable_q[i];
                    end
                end
            end

            // threshold
            else if (off == THRESHOLD_ADDR) begin
                data32[PRIO_W-1:0] = threshold_q;
            end

            // claim
            else if (off == CLAIM_ADDR) begin
                data32[ID_W-1:0] = best_id_comb;
            end

            make_rdata       = '0;
            make_rdata[31:0] = data32;
        end
    endfunction

    // ============================================================
    // AXI WRITE channel
    // AW / W 可以不同 cycle 進來
    // ============================================================
    logic aw_hold_q;
    logic w_hold_q;
    logic bvalid_q;

    logic [`AXI_ADDR_BITS-1:0] awaddr_q;
    logic [`AXI_IDS_BITS-1:0]  awid_q;

    logic [`AXI_DATA_BITS-1:0] wdata_q;
    logic [`AXI_STRB_BITS-1:0] wstrb_q;

    logic [`AXI_IDS_BITS-1:0]  bid_q;
    logic [1:0]                bresp_q;

    assign axi_w.AWREADY_s =
        !aw_hold_q && !bvalid_q;

    assign axi_w.WREADY_s =
        !w_hold_q && !bvalid_q;

    assign axi_w.BID_s    = bid_q;
    assign axi_w.BRESP_s  = bresp_q;
    assign axi_w.BVALID_s = bvalid_q;

    wire w_aw_fire =
        axi_w.AWVALID_s && axi_w.AWREADY_s;

    wire w_w_fire =
        axi_w.WVALID_s && axi_w.WREADY_s;

    wire b_done =
        axi_w.BVALID_s && axi_w.BREADY_s;

    wire write_exec =
        !bvalid_q                   &&
        (aw_hold_q || w_aw_fire)    &&
        (w_hold_q  || w_w_fire);

    wire [`AXI_ADDR_BITS-1:0] wr_addr_eff =
        w_aw_fire ? axi_w.AWADDR_s : awaddr_q;

    wire [`AXI_IDS_BITS-1:0] wr_id_eff =
        w_aw_fire ? axi_w.AWID_s : awid_q;

    wire [`AXI_DATA_BITS-1:0] wr_data_eff =
        w_w_fire ? axi_w.WDATA_s : wdata_q;

    wire [31:0] wr_off =
        wr_addr_eff[31:0] - BASE_ADDR;

    wire [31:0] wr_data32 =
        wr_data_eff[31:0];

    // ============================================================
    // Main sequential logic
    // ============================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pending_q   <= '0;
            enable_q    <= '0;
            claimed_q   <= '0;
            threshold_q <= '0;

            priority_q[0] <= '0;

            for (int i = 1; i <= SRC_NUM; i++) begin
                priority_q[i] <= DEFAULT_PRIORITY;
            end

            rvalid_q <= 1'b0;
            rid_q    <= '0;
            rdata_q  <= '0;
            rresp_q  <= 2'b00;

            aw_hold_q <= 1'b0;
            w_hold_q  <= 1'b0;
            bvalid_q  <= 1'b0;

            awaddr_q <= '0;
            awid_q   <= '0;
            wdata_q  <= '0;
            wstrb_q  <= '0;

            bid_q   <= '0;
            bresp_q <= 2'b00;
        end
        else begin
            // ----------------------------------------------------
            // External IRQ source update
            // level-style pending
            //
            // claimed 中的 source 不會重複 pending。
            // complete 後如果 irq_i 還是 1，
            // 下一個 cycle 會再次 pending。
            // ----------------------------------------------------
            for (int i = 1; i <= SRC_NUM; i++) begin
                if (irq_i[i-1] && !claimed_q[i]) begin
                    pending_q[i] <= 1'b1;
                end
            end

            priority_q[0] <= '0;
            pending_q[0]  <= 1'b0;
            enable_q[0]   <= 1'b0;
            claimed_q[0]  <= 1'b0;

            // ----------------------------------------------------
            // READ response
            // ----------------------------------------------------
            if (r_done) begin
                rvalid_q <= 1'b0;
            end

            if (r_ar_fire) begin
                rid_q    <= axi_r.ARID_s;
                rdata_q  <= make_rdata(axi_r.ARADDR_s);
                rresp_q  <= 2'b00;
                rvalid_q <= 1'b1;

                // claim read side-effect
                // CPU 讀 CLAIM_ADDR 時：
                // 1. 回傳最高優先權 ID
                // 2. 清除 pending
                // 3. 設定 claimed
                if (((axi_r.ARADDR_s[31:0] -
                      BASE_ADDR) == CLAIM_ADDR) &&
                    (best_id_comb != '0)) begin

                    pending_q[best_id_comb] <= 1'b0;
                    claimed_q[best_id_comb] <= 1'b1;
                end
            end

            // ----------------------------------------------------
            // WRITE address/data capture
            // ----------------------------------------------------
            if (w_aw_fire) begin
                aw_hold_q <= 1'b1;
                awaddr_q  <= axi_w.AWADDR_s;
                awid_q    <= axi_w.AWID_s;
            end

            if (w_w_fire) begin
                w_hold_q <= 1'b1;
                wdata_q  <= axi_w.WDATA_s;
                wstrb_q  <= axi_w.WSTRB_s;
            end

            if (b_done) begin
                bvalid_q <= 1'b0;
            end

            // ----------------------------------------------------
            // WRITE execute
            // ----------------------------------------------------
            if (write_exec) begin
                // priority[source_id]
                if ((wr_off >= PRIORITY_BASE) &&
                    (wr_off <
                     (PRIORITY_BASE +
                      ((SRC_NUM + 1) * 4))) &&
                    (wr_off[1:0] == 2'b00)) begin

                    for (int i = 1; i <= SRC_NUM; i++) begin
                        if (wr_off ==
                            (PRIORITY_BASE + (i * 4))) begin

                            priority_q[i] <=
                                wr_data32[PRIO_W-1:0];
                        end
                    end
                end

                // enable[source_id]
                else if ((wr_off >= ENABLE_BASE) &&
                         (wr_off <
                          (ENABLE_BASE +
                           (WORD_NUM * 4))) &&
                         (wr_off[1:0] == 2'b00)) begin

                    for (int i = 1; i <= SRC_NUM; i++) begin
                        if (((wr_off - ENABLE_BASE) >> 2) ==
                            (i >> 5)) begin

                            enable_q[i] <=
                                wr_data32[i % 32];
                        end
                    end
                end

                // threshold
                else if (wr_off == THRESHOLD_ADDR) begin
                    threshold_q <=
                        wr_data32[PRIO_W-1:0];
                end

                // complete
                // CPU 寫回 claim ID，
                // 代表 interrupt service 完成
                else if (wr_off == CLAIM_ADDR) begin
                    for (int i = 1; i <= SRC_NUM; i++) begin
                        if (wr_data32 == i) begin
                            claimed_q[i] <= 1'b0;
                        end
                    end
                end

                aw_hold_q <= 1'b0;
                w_hold_q  <= 1'b0;

                bid_q    <= wr_id_eff;
                bresp_q  <= 2'b00;
                bvalid_q <= 1'b1;
            end
        end
    end

endmodule