module simple_clint #(
    parameter logic [31:0] BASE_ADDR = 32'h0200_0000
)(
    // AXI / CLINT clock domain
    input  logic                 clk,
    input  logic                 rst_n,

    // CPU clock domain
    input  logic                 cpu_clk,
    input  logic                 cpu_rst_n,

    // CPU interrupt outputs
    output logic                 msip_o,
    output logic                 mtip_o,

    axi_read_if.slave            axi_r,
    axi_write_if.slave           axi_w
);

    // ============================================================
    // CLINT register map
    //
    // BASE_ADDR + 0x0000 : MSIP
    // BASE_ADDR + 0x4000 : MTIMECMP low
    // BASE_ADDR + 0x4004 : MTIMECMP high
    // BASE_ADDR + 0xBFF8 : MTIME low
    // BASE_ADDR + 0xBFFC : MTIME high
    // ============================================================
    localparam logic [31:0] MSIP_ADDR         = 32'h0000_0000;
    localparam logic [31:0] MTIMECMP_LO_ADDR  = 32'h0000_4000;
    localparam logic [31:0] MTIMECMP_HI_ADDR  = 32'h0000_4004;
    localparam logic [31:0] MTIME_LO_ADDR     = 32'h0000_BFF8;
    localparam logic [31:0] MTIME_HI_ADDR     = 32'h0000_BFFC;

    // ============================================================
    // CLINT registers
    // ============================================================
    logic        msip_q;
    logic [63:0] mtimecmp_q;
    logic [63:0] mtime_q;

    // ============================================================
    // Interrupt generation in AXI clock domain
    // ============================================================
    logic msip_raw;
    logic mtip_raw;

    assign msip_raw = msip_q;

    assign mtip_raw = (mtime_q >= mtimecmp_q);

    // ============================================================
    // Interrupt synchronizers
    //
    // Source domain:
    //     clk / rst_n
    //
    // Destination domain:
    //     cpu_clk / cpu_rst_n
    // ============================================================
    logic msip_src_ff;
    logic mtip_src_ff;

    (* ASYNC_REG = "TRUE" *) logic msip_sync_ff1;
    (* ASYNC_REG = "TRUE" *) logic msip_sync_ff2;

    (* ASYNC_REG = "TRUE" *) logic mtip_sync_ff1;
    (* ASYNC_REG = "TRUE" *) logic mtip_sync_ff2;

    // ============================================================
    // AXI READ channel declarations
    // ============================================================
    logic                          rvalid_q;
    logic [`AXI_IDS_BITS-1:0]      rid_q;
    logic [`AXI_DATA_BITS-1:0]     rdata_q;
    logic [1:0]                    rresp_q;

    wire r_ar_fire;
    wire r_done;

    // ============================================================
    // AXI WRITE channel declarations
    // ============================================================
    logic                          aw_hold_q;
    logic                          w_hold_q;
    logic                          bvalid_q;

    logic [`AXI_ADDR_BITS-1:0]     awaddr_q;
    logic [`AXI_IDS_BITS-1:0]      awid_q;

    logic [`AXI_DATA_BITS-1:0]     wdata_q;
    logic [`AXI_STRB_BITS-1:0]     wstrb_q;

    logic [`AXI_IDS_BITS-1:0]      bid_q;
    logic [1:0]                    bresp_q;

    wire w_aw_fire;
    wire w_w_fire;
    wire b_done;
    wire write_exec;

    wire [`AXI_ADDR_BITS-1:0]      wr_addr_eff;
    wire [`AXI_IDS_BITS-1:0]       wr_id_eff;
    wire [`AXI_DATA_BITS-1:0]      wr_data_eff;
    wire [`AXI_STRB_BITS-1:0]      wr_strb_eff;

    wire [31:0]                    wr_off;
    wire [31:0]                    wr_data32;

    // ============================================================
    // Write strobe helper
    // ============================================================
    function automatic logic [31:0] merge_wstrb32;
        input logic [31:0] old_data;
        input logic [31:0] new_data;
        input logic [3:0]  strb;

        logic [31:0] result;

        begin
            result = old_data;

            for (int i = 0; i < 4; i++) begin
                if (strb[i]) begin
                    result[(i * 8) +: 8] =
                        new_data[(i * 8) +: 8];
                end
            end

            merge_wstrb32 = result;
        end
    endfunction

    // ============================================================
    // AXI READ interface
    // ============================================================
    assign axi_r.ARREADY_s = !rvalid_q;

    assign axi_r.RID_s     = rid_q;
    assign axi_r.RDATA_s   = rdata_q;
    assign axi_r.RRESP_s   = rresp_q;
    assign axi_r.RLAST_s   = 1'b1;
    assign axi_r.RVALID_s  = rvalid_q;

    assign r_ar_fire =
        axi_r.ARVALID_s && axi_r.ARREADY_s;

    assign r_done =
        axi_r.RVALID_s && axi_r.RREADY_s;

    // ============================================================
    // CLINT read data
    // ============================================================
    function automatic logic [`AXI_DATA_BITS-1:0] make_rdata;
        input logic [`AXI_ADDR_BITS-1:0] addr;

        logic [31:0] off;
        logic [31:0] data32;

        begin
            off    = addr[31:0] - BASE_ADDR;
            data32 = 32'd0;

            case (off)
                MSIP_ADDR: begin
                    data32[0] = msip_q;
                end

                MTIMECMP_LO_ADDR: begin
                    data32 = mtimecmp_q[31:0];
                end

                MTIMECMP_HI_ADDR: begin
                    data32 = mtimecmp_q[63:32];
                end

                MTIME_LO_ADDR: begin
                    data32 = mtime_q[31:0];
                end

                MTIME_HI_ADDR: begin
                    data32 = mtime_q[63:32];
                end

                default: begin
                    data32 = 32'd0;
                end
            endcase

            make_rdata       = '0;
            make_rdata[31:0] = data32;
        end
    endfunction

    // ============================================================
    // AXI READ sequential logic
    // ============================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rvalid_q <= 1'b0;
            rid_q    <= '0;
            rdata_q  <= '0;
            rresp_q  <= 2'b00;
        end
        else begin
            if (r_done) begin
                rvalid_q <= 1'b0;
            end

            if (r_ar_fire) begin
                rid_q    <= axi_r.ARID_s;
                rdata_q  <= make_rdata(axi_r.ARADDR_s);
                rresp_q  <= 2'b00;
                rvalid_q <= 1'b1;
            end
        end
    end

    // ============================================================
    // AXI WRITE interface
    // AW and W may arrive in different cycles
    // ============================================================
    assign axi_w.AWREADY_s =
        !aw_hold_q && !bvalid_q;

    assign axi_w.WREADY_s =
        !w_hold_q && !bvalid_q;

    assign axi_w.BID_s     = bid_q;
    assign axi_w.BRESP_s   = bresp_q;
    assign axi_w.BVALID_s  = bvalid_q;

    assign w_aw_fire =
        axi_w.AWVALID_s && axi_w.AWREADY_s;

    assign w_w_fire =
        axi_w.WVALID_s && axi_w.WREADY_s;

    assign b_done =
        axi_w.BVALID_s && axi_w.BREADY_s;

    assign write_exec =
        !bvalid_q                &&
        (aw_hold_q || w_aw_fire) &&
        (w_hold_q  || w_w_fire);

    assign wr_addr_eff =
        w_aw_fire ? axi_w.AWADDR_s : awaddr_q;

    assign wr_id_eff =
        w_aw_fire ? axi_w.AWID_s : awid_q;

    assign wr_data_eff =
        w_w_fire ? axi_w.WDATA_s : wdata_q;

    assign wr_strb_eff =
        w_w_fire ? axi_w.WSTRB_s : wstrb_q;

    assign wr_off =
        wr_addr_eff[31:0] - BASE_ADDR;

    assign wr_data32 =
        wr_data_eff[31:0];

    // ============================================================
    // AXI WRITE sequential logic
    // ============================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            aw_hold_q <= 1'b0;
            w_hold_q  <= 1'b0;
            bvalid_q  <= 1'b0;

            awaddr_q  <= '0;
            awid_q    <= '0;

            wdata_q   <= '0;
            wstrb_q   <= '0;

            bid_q     <= '0;
            bresp_q   <= 2'b00;
        end
        else begin
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

            if (write_exec) begin
                aw_hold_q <= 1'b0;
                w_hold_q  <= 1'b0;

                bid_q     <= wr_id_eff;
                bresp_q   <= 2'b00;
                bvalid_q  <= 1'b1;
            end
        end
    end

    // ============================================================
    // CLINT register logic
    // ============================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            msip_q     <= 1'b0;
            mtime_q    <= 64'd0;

            // Reset to maximum value to avoid timer interrupt
            // being asserted immediately after reset.
            mtimecmp_q <= 64'hFFFF_FFFF_FFFF_FFFF;
        end
        else begin
            // ----------------------------------------------------
            // MTIME counter
            // ----------------------------------------------------
            if (write_exec &&
                ((wr_off == MTIME_LO_ADDR) ||
                 (wr_off == MTIME_HI_ADDR))) begin

                if (wr_off == MTIME_LO_ADDR) begin
                    mtime_q[31:0] <= merge_wstrb32(
                        mtime_q[31:0],
                        wr_data32,
                        wr_strb_eff[3:0]
                    );
                end

                if (wr_off == MTIME_HI_ADDR) begin
                    mtime_q[63:32] <= merge_wstrb32(
                        mtime_q[63:32],
                        wr_data32,
                        wr_strb_eff[3:0]
                    );
                end
            end
            else begin
                mtime_q <= mtime_q + 64'd1;
            end

            // ----------------------------------------------------
            // CLINT register writes
            // ----------------------------------------------------
            if (write_exec) begin
                case (wr_off)
                    MSIP_ADDR: begin
                        if (wr_strb_eff[0]) begin
                            msip_q <= wr_data32[0];
                        end
                    end

                    MTIMECMP_LO_ADDR: begin
                        mtimecmp_q[31:0] <= merge_wstrb32(
                            mtimecmp_q[31:0],
                            wr_data32,
                            wr_strb_eff[3:0]
                        );
                    end

                    MTIMECMP_HI_ADDR: begin
                        mtimecmp_q[63:32] <= merge_wstrb32(
                            mtimecmp_q[63:32],
                            wr_data32,
                            wr_strb_eff[3:0]
                        );
                    end

                    default: begin
                    end
                endcase
            end
        end
    end

    // ============================================================
    // Source-domain DFF
    //
    // Interrupt先在AXI clock domain擋一級。
    // 避免combinational interrupt直接進CDC synchronizer。
    // ============================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            msip_src_ff <= 1'b0;
            mtip_src_ff <= 1'b0;
        end
        else begin
            msip_src_ff <= msip_raw;
            mtip_src_ff <= mtip_raw;
        end
    end

    // ============================================================
    // CPU-domain two-stage synchronizers
    // ============================================================
    always_ff @(posedge cpu_clk or negedge cpu_rst_n) begin
        if (!cpu_rst_n) begin
            msip_sync_ff1 <= 1'b0;
            msip_sync_ff2 <= 1'b0;

            mtip_sync_ff1 <= 1'b0;
            mtip_sync_ff2 <= 1'b0;
        end
        else begin
            msip_sync_ff1 <= msip_src_ff;
            msip_sync_ff2 <= msip_sync_ff1;

            mtip_sync_ff1 <= mtip_src_ff;
            mtip_sync_ff2 <= mtip_sync_ff1;
        end
    end

    // ============================================================
    // CPU-domain interrupt outputs
    // ============================================================
    assign msip_o = msip_sync_ff2;
    assign mtip_o = mtip_sync_ff2;

endmodule