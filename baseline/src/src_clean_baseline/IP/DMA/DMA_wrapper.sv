`include "../include/AXI_define.svh"

// =============================================================================
// DMA_1
//   - 16-beat burst DMA，支援 Descriptor List
//   - Master 端：分開 Read / Write FSM
//   - Slave 端：CPU 只寫 DMAEN / DESC_BASE （只有write）
//   - 使用單一 16-word buffer：讀完一個 burst 後直接拿來寫
// =============================================================================

localparam logic [31:0] DMAEN_ADDR     = 32'h1002_0100;
localparam logic [31:0] DESC_BASE_ADDR = 32'h1002_0200;

module DMA_1 (
    // =========================
    // AXI Master (M3)
    // =========================
    input  logic                         ACLK,
    input  logic                         ARESETn,
    output logic                         DMA_interrupt,

`ifdef interface_En
    axi_read_if  axi_r_m,      // AR/R 
    axi_write_if axi_w_m,       // AW/W/B 
    axi_write_if  axi_w_s      // AW/W/B 
`else
    // Write address channel (Master)
    output logic [`AXI_ID_BITS-1:0]      AWID_M,
    output logic [`AXI_ADDR_BITS-1:0]    AWADDR_M,
    output logic [`AXI_LEN_BITS-1:0]     AWLEN_M,       // beats-1
    output logic [`AXI_SIZE_BITS-1:0]    AWSIZE_M,
    output logic [1:0]                   AWBURST_M,
    output logic                         AWVALID_M,
    input  logic                         AWREADY_M,

    // Write data channel (Master)
    output logic [`AXI_DATA_BITS-1:0]    WDATA_M,
    output logic [`AXI_STRB_BITS-1:0]    WSTRB_M,
    output logic                         WLAST_M,
    output logic                         WVALID_M,
    input  logic                         WREADY_M,

    // Write response (Master)
    input  logic [`AXI_ID_BITS-1:0]      BID_M,
    input  logic [1:0]                   BRESP_M,
    input  logic                         BVALID_M,
    output logic                         BREADY_M,

    // Read address channel (Master)
    output logic [`AXI_ID_BITS-1:0]      ARID_M,
    output logic [`AXI_ADDR_BITS-1:0]    ARADDR_M,
    output logic [`AXI_LEN_BITS-1:0]     ARLEN_M,       // beats-1
    output logic [`AXI_SIZE_BITS-1:0]    ARSIZE_M,
    output logic [1:0]                   ARBURST_M,
    output logic                         ARVALID_M,
    input  logic                         ARREADY_M,

    // Read data channel (Master)
    input  logic [`AXI_ID_BITS-1:0]      RID_M,
    input  logic [`AXI_DATA_BITS-1:0]    RDATA_M,
    input  logic [1:0]                   RRESP_M,
    input  logic                         RLAST_M,
    input  logic                         RVALID_M,
    output logic                         RREADY_M,

    // =========================
    // AXI Slave (CPU→DMA，僅寫)
    // =========================
    input  logic [7:0]                   AWID_S,
    input  logic [31:0]                  AWADDR_S,
    input  logic [3:0]                   AWLEN_S,       // not used (burst=1)
    input  logic [2:0]                   AWSIZE_S,      // not used
    input  logic [1:0]                   AWBURST_S,     // not used
    input  logic                         AWVALID_S,
    output logic                         AWREADY_S,

    input  logic [31:0]                  WDATA_S,
    input  logic [3:0]                   WSTRB_S,       // not used
    input  logic                         WLAST_S,
    input  logic                         WVALID_S,
    output logic                         WREADY_S,

    output logic [7:0]                   BID_S,
    output logic [1:0]                   BRESP_S,
    output logic                         BVALID_S,
    input  logic                         BREADY_S
`endif
);

    // ============================================================
    // 控制寄存器（CPU 寫進來）
    // ============================================================
    logic        DMAEN;
    logic [31:0] DESC_BASE;

    // Descriptor 欄位（DMA 讀回）
    logic [31:0] DMA_SRC;
    logic [31:0] DMA_DST;
    logic [31:0] DMA_LEN;
    logic [31:0] NEXT_DESC;
    logic        EOC;

    // Master 端讀寫位址/長度/計數器
    logic [31:0] m_raddr;
    logic [31:0] m_waddr;
    logic [3:0]  m_rlen_m1;
    logic [3:0]  m_wlen_m1;
    logic [31:0] rd_count;
    logic [31:0] wr_count;

    // 16-word buffer（同時當作 read buffer 以及 write source）
    logic [31:0] read_buffer [0:15];
    logic [3:0]  r_index;
    logic [3:0]  w_index;

    logic        read_chunk_done;
    logic        read_len_finish;
    logic        writing_inflight;

`ifdef interface_En

    //te address channel (Master)
     logic [`AXI_ID_BITS-1:0]      AWID_M;
     logic [`AXI_ADDR_BITS-1:0]    AWADDR_M;
     logic [`AXI_LEN_BITS-1:0]     AWLEN_M;      // beats-1
     logic [`AXI_SIZE_BITS-1:0]    AWSIZE_M;
     logic [1:0]                   AWBURST_M;
     logic                         AWVALID_M;
     logic                         AWREADY_M;

    //te data channel (Master)
     logic [`AXI_DATA_BITS-1:0]    WDATA_M;
     logic [`AXI_STRB_BITS-1:0]    WSTRB_M;
     logic                         WLAST_M;
     logic                         WVALID_M;
     logic                         WREADY_M;

    //te response (Master)
     logic [`AXI_ID_BITS-1:0]      BID_M;
     logic [1:0]                   BRESP_M;
     logic                         BVALID_M;
     logic                         BREADY_M;

    //d address channel (Master)
     logic [`AXI_ID_BITS-1:0]      ARID_M;
     logic [`AXI_ADDR_BITS-1:0]    ARADDR_M;
     logic [`AXI_LEN_BITS-1:0]     ARLEN_M;      // beats-1
     logic [`AXI_SIZE_BITS-1:0]    ARSIZE_M;
     logic [1:0]                   ARBURST_M;
     logic                         ARVALID_M;
     logic                         ARREADY_M;

    //d data channel (Master)
     logic [`AXI_ID_BITS-1:0]      RID_M;
     logic [`AXI_DATA_BITS-1:0]    RDATA_M;
     logic [1:0]                   RRESP_M;
     logic                         RLAST_M;
     logic                         RVALID_M;
     logic                         RREADY_M;

    //======================
    // Slave (CPU→DMA，僅寫)
    //======================
     logic [7:0]                   AWID_S;
     logic [31:0]                  AWADDR_S;
     logic [3:0]                   AWLEN_S;
     logic [2:0]                   AWSIZE_S;
     logic [1:0]                   AWBURST_S;
     logic                         AWVALID_S;
     logic                         AWREADY_S;

     logic [31:0]                  WDATA_S;
     logic [3:0]                   WSTRB_S;
     logic                         WLAST_S;
     logic                         WVALID_S;
     logic                         WREADY_S;

     logic [7:0]                   BID_S;
     logic [1:0]                   BRESP_S;
     logic                         BVALID_S;
     logic                         BREADY_S;

    assign axi_w_m.AWID_m    = AWID_M;
    assign axi_w_m.AWADDR_m  = AWADDR_M;
    assign axi_w_m.AWLEN_m   = AWLEN_M;
    assign axi_w_m.AWSIZE_m  = AWSIZE_M;
    assign axi_w_m.AWBURST_m = AWBURST_M;
    assign axi_w_m.AWVALID_m = AWVALID_M;
    assign AWREADY_M         = axi_w_m.AWREADY_m;

    assign axi_w_m.WDATA_m  = WDATA_M;
    assign axi_w_m.WSTRB_m  = WSTRB_M;
    assign axi_w_m.WLAST_m  = WLAST_M;
    assign axi_w_m.WVALID_m = WVALID_M;
    assign WREADY_M         = axi_w_m.WREADY_m;

    assign BID_M    = axi_w_m.BID_m;
    assign BRESP_M  = axi_w_m.BRESP_m;
    assign BVALID_M = axi_w_m.BVALID_m;
    assign axi_w_m.BREADY_m = BREADY_M;

    assign axi_r_m.ARID_m    = ARID_M;
    assign axi_r_m.ARADDR_m  = ARADDR_M;
    assign axi_r_m.ARLEN_m   = ARLEN_M;
    assign axi_r_m.ARSIZE_m  = ARSIZE_M;
    assign axi_r_m.ARBURST_m = ARBURST_M;
    assign axi_r_m.ARVALID_m = ARVALID_M;
    assign ARREADY_M         = axi_r_m.ARREADY_m;

    assign RID_M    = axi_r_m.RID_m;
    assign RDATA_M  = axi_r_m.RDATA_m;
    assign RRESP_M  = axi_r_m.RRESP_m;
    assign RLAST_M  = axi_r_m.RLAST_m;
    assign RVALID_M = axi_r_m.RVALID_m;
    assign axi_r_m.RREADY_m = RREADY_M;

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
`else
`endif

    // logic temp, temp1;
    //logic [1:0]temp2;

    // ============================================================
    // 狀態列舉
    // ============================================================
    typedef enum logic [1:0] {
        M_HOLD = 2'd0,
        M_ADDR = 2'd1,
        M_DATA = 2'd2,
        M_RESP = 2'd3
    } state_M;

    typedef enum logic [1:0] {
        S_HOLD = 2'd0,
        S_DATA = 2'd1,
        S_RESP = 2'd2
    } state_S;

    typedef enum logic [1:0] {
        DMA_IDLE    = 2'd0,
        DMA_STRETCH = 2'd1,
        DMA_READ    = 2'd2,
        //DMA_WRITE   = 3'd3,   
        DMA_EOC     = 2'd3
    } state_DMA;

    typedef enum logic [2:0] {
        STRETCH_SRC      = 3'd0,
        STRETCH_DST      = 3'd1,
        STRETCH_LEN      = 3'd2,
        STRETCH_NXT_DESC = 3'd3,
        STRETCH_EOC      = 3'd4
    } state_STRETCH;

    state_M       Master_RD_cs, Master_RD_ns;
    state_M       Master_WR_cs, Master_WR_ns;
    state_S       Slave_WR_cs,  Slave_WR_ns;
    state_DMA     DMA_cs,       DMA_ns;
    state_STRETCH STRETCH_cs,   STRETCH_ns;


    // 中斷輸出
    assign DMA_interrupt = (DMA_cs == DMA_EOC);

    logic AR_MASTER_handshake, READ_MASTER_handshake;
    logic AW_MASTER_handshake, WRITE_MASTER_handshake,B_MASTER_handshake;
    logic AW_SLAVE_handshake, WRITE_SLAVE_handshake,B_SLAVE_handshake;

    //hand shake
    assign AR_MASTER_handshake = (ARVALID_M && ARREADY_M);
    assign READ_MASTER_handshake = (RVALID_M && RREADY_M);
    
    assign AW_MASTER_handshake = (AWVALID_M && AWREADY_M);
    assign WRITE_MASTER_handshake = (WVALID_M && WREADY_M);
    assign B_MASTER_handshake = (BREADY_M && BVALID_M);

    assign AW_SLAVE_handshake = (AWVALID_S && AWREADY_S);
    assign WRITE_SLAVE_handshake = (WVALID_S && WREADY_S);
    assign B_SLAVE_handshake = (BREADY_S && BVALID_S);
    // ============================================================
    // DMA 高階 FSM + STRETCH 子 FSM
    // ============================================================
    always_ff @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            DMA_cs     <= DMA_IDLE;
        end else begin
            DMA_cs     <= DMA_ns;
        end
    end

    // DMA 主態
    always_comb begin
        unique case (DMA_cs)
            DMA_IDLE: begin
                DMA_ns = (DMAEN) ? DMA_STRETCH : DMA_IDLE;
            end

            DMA_STRETCH: begin
                // descriptor 最後一個 word (EOC) 被讀回後，進入 READ
                unique if ((STRETCH_cs == STRETCH_EOC) && READ_MASTER_handshake) begin
                    DMA_ns = DMA_READ;
                end else begin
                    DMA_ns = DMA_STRETCH;
                end
            end

            DMA_READ: begin
                // 全部寫完而且拿到最後一個 B response
                unique if ((wr_count == DMA_LEN) && (B_MASTER_handshake)) begin
                    DMA_ns = (EOC) ? DMA_EOC : DMA_STRETCH;
                end else begin
                    DMA_ns = DMA_READ;
                end
            end

            /*DMA_WRITE:begin
                if ((wr_count == DMA_LEN) && (BREADY_M && BVALID_M)) begin
                    DMA_ns = (EOC) ? DMA_EOC : DMA_STRETCH;
                end else begin
                    DMA_ns = DMA_READ;
                end
            end*/

            DMA_EOC: begin
                // CPU 拉低 DMAEN 後，回到 IDLE
                DMA_ns = (DMAEN) ? DMA_EOC : DMA_IDLE;
            end

            default: DMA_ns = DMA_IDLE;
        endcase
    end


    always_ff @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            STRETCH_cs <= STRETCH_SRC;
        end else begin
            STRETCH_cs <= STRETCH_ns;
        end
    end
    // STRETCH 子 FSM – descriptor 5 words 的輪替
    always_comb begin
        if ((READ_MASTER_handshake) && (DMA_cs == DMA_STRETCH)) begin
            unique case (STRETCH_cs)
                STRETCH_SRC      : STRETCH_ns = STRETCH_DST;
                STRETCH_DST      : STRETCH_ns = STRETCH_LEN;
                STRETCH_LEN      : STRETCH_ns = STRETCH_NXT_DESC;
                STRETCH_NXT_DESC : STRETCH_ns = STRETCH_EOC;
                STRETCH_EOC      : STRETCH_ns = STRETCH_SRC;
                default          : STRETCH_ns = STRETCH_SRC;
            endcase
        end else begin
            STRETCH_ns = STRETCH_cs;
        end
    end

 



    // ============================================================
    // Slave 寫入 FSM（CPU 寫 DMAEN / DESC_BASE）
    // ============================================================
    // current state
    always_ff @(posedge ACLK or negedge ARESETn) begin
        if(!ARESETn) begin
            Slave_WR_cs <= S_HOLD;
        end
        else begin
            Slave_WR_cs <= Slave_WR_ns;
        end
    end
    // next state
    always_comb begin
        unique case (Slave_WR_cs)
            S_HOLD: Slave_WR_ns = (AW_SLAVE_handshake)          ? S_DATA : S_HOLD;
            S_DATA: Slave_WR_ns = (WRITE_SLAVE_handshake && WLAST_S) ? S_RESP : S_DATA;
            S_RESP: Slave_WR_ns = (B_SLAVE_handshake)           ? S_HOLD : S_RESP;
            default: Slave_WR_ns = S_HOLD;
        endcase
    end

    logic [31:0] awaddr_s_reg;
    logic [7:0]  awid_s_reg;
    // AXI Slave output
    
    // 只有在 DMA_IDLE 或 DMA_EOC 才接受 CPU 設定
    assign  AWREADY_S = (Slave_WR_cs == S_HOLD) &&
                          ((DMA_cs == DMA_IDLE) || (DMA_cs == DMA_EOC));
    assign  WREADY_S  = (Slave_WR_cs == S_DATA);
    assign  BID_S     = awid_s_reg;
    assign  BVALID_S  = (Slave_WR_cs == S_RESP);
    assign  BRESP_S   = `AXI_RESP_OKAY;
    

    
    // 狀態暫存
    always_ff @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            awaddr_s_reg  <= 32'd0;
            awid_s_reg    <= 8'd0;
        end else begin
            unique case (Slave_WR_cs)
                S_HOLD: begin
                    if (AW_SLAVE_handshake) begin
                        awaddr_s_reg <= AWADDR_S;
                        awid_s_reg   <= AWID_S;
                    end
                end
                S_DATA: begin
                    if (WRITE_SLAVE_handshake) begin
                        awaddr_s_reg <= awaddr_s_reg + 32'd4;
                    end
                end
                default: ; // S_RESP 不更新
            endcase
        end
    end

    // 寫入控制寄存器
    always_ff @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            DMAEN     <= 1'b0;
            DESC_BASE <= 32'd0;
        end else if (Slave_WR_cs == S_DATA && WRITE_SLAVE_handshake) begin
            unique case (awaddr_s_reg)
                DMAEN_ADDR     : DMAEN     <= WDATA_S[0];
                DESC_BASE_ADDR : DESC_BASE <= WDATA_S;
                default        : ;
            endcase
        end
    end

    // ============================================================
    // Master Read FSM（AR/R）
    // ============================================================
    always_ff @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            Master_RD_cs <= M_HOLD;
        end else begin
            Master_RD_cs <= Master_RD_ns;
        end
    end

    always_comb begin
        unique case (Master_RD_cs)
            M_HOLD: begin
                // 1) STRETCH：讀 descriptor
                // 2) READ：還有 length 沒搬完，且此時沒有 write 在飛
                // *** 這裡改成只看 DMA_cs（registered），避免 combo loop 到 DMA_ns
                if ( (DMA_cs == DMA_STRETCH) ||
                     ((DMA_cs == DMA_READ) && !read_len_finish && !writing_inflight) ) begin
                    Master_RD_ns = M_ADDR;
                end else begin
                    Master_RD_ns = M_HOLD;
                end
            end

            M_ADDR: begin
                Master_RD_ns = (AR_MASTER_handshake) ? M_DATA : M_ADDR;
            end

            M_DATA: begin
                Master_RD_ns = (READ_MASTER_handshake && RLAST_M) ? M_HOLD : M_DATA;
            end

            default: Master_RD_ns = M_HOLD;
        endcase
    end

    
    assign  ARID_M    = 1'b0;
    assign  ARADDR_M  = m_raddr;
    assign  ARLEN_M   = m_rlen_m1;
    assign  ARSIZE_M  = `AXI_SIZE_WORD;
    assign  ARBURST_M = `AXI_BURST_INC;
    assign  ARVALID_M = (Master_RD_cs == M_ADDR);
    assign  RREADY_M  = 1'b1;
    
    // ============================================================
    // Master Write FSM（AW/W/B）
    // ============================================================
    always_ff @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            Master_WR_cs <= M_HOLD;
        end else begin
            Master_WR_cs <= Master_WR_ns;
        end
    end

    always_comb begin
        unique case (Master_WR_cs)
            M_HOLD: begin
                Master_WR_ns = ((DMA_cs == DMA_READ) && read_chunk_done) ? M_ADDR : M_HOLD;
            end

            M_ADDR: begin
                Master_WR_ns = (AW_MASTER_handshake) ? M_DATA : M_ADDR;
            end

            M_DATA: begin
                Master_WR_ns = (WRITE_MASTER_handshake && WLAST_M) ? M_RESP : M_DATA;
            end

            M_RESP: begin
                if (B_MASTER_handshake) begin
                    // 如果 read_buffer 又收完一個 burst，接下一個 burst 的 write
                    Master_WR_ns = (read_chunk_done) ? M_ADDR : M_HOLD;
                end else begin
                    Master_WR_ns = M_RESP;
                end
            end

            default: Master_WR_ns = M_HOLD;
        endcase
    end

    // AW
    assign  AWID_M    = '0;
    assign  AWADDR_M  = m_waddr;
    assign  AWLEN_M   = m_wlen_m1;
    assign  AWSIZE_M  = `AXI_SIZE_WORD;
    assign  AWBURST_M = `AXI_BURST_INC;
    assign  AWVALID_M = (Master_WR_cs == M_ADDR);
    // W：直接從 read_buffer 拿資料
    assign  WDATA_M   = read_buffer[w_index];
    assign  WSTRB_M   = {`AXI_STRB_BITS{1'b1}};
    assign  WLAST_M   = (w_index == m_wlen_m1);
    assign  WVALID_M  = (Master_WR_cs == M_DATA);
    // B
    assign  BREADY_M  = 1'b1;

    // 目前是否有寫在飛
    assign writing_inflight =
        (Master_WR_cs == M_ADDR) ||
        (Master_WR_cs == M_DATA) ||
        (Master_WR_cs == M_RESP && !(B_MASTER_handshake)); //這個可以省


    // ============================================================
    // Descriptor / RADDR / WADDR / LEN / buffer 控制
    // ============================================================

    // Descriptor 欄位
    always_ff @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            DMA_SRC   <= 32'd0;
            DMA_DST   <= 32'd0;
            DMA_LEN   <= 32'd0;
            NEXT_DESC <= 32'd0;
            EOC       <= 1'b0;
        end else if ((DMA_cs == DMA_STRETCH) && (READ_MASTER_handshake)) begin
            unique case (STRETCH_cs)
                STRETCH_SRC      : DMA_SRC   <= RDATA_M;
                STRETCH_DST      : DMA_DST   <= RDATA_M;
                STRETCH_LEN      : DMA_LEN   <= RDATA_M+'d16;//{RDATA_M[31:1],1'b1};
                //STRETCH_LEN      : // 在讀取 Descriptor 的狀態，把 Byte 轉成 Word
               // STRETCH_LEN : DMA_LEN <= {2'b0, RDATA_M[31:2]};
                //STRETCH_LEN      : DMA_LEN   <= {2'b0,RDATA_M[31:2]};
                STRETCH_NXT_DESC : NEXT_DESC <= RDATA_M;
                STRETCH_EOC      : EOC       <= RDATA_M[0];
                default          : ;
            endcase
        end
    end

    // *** 初始 data burst 長度（descriptor 讀完的那一刻）
    logic [3:0] init_len_m1;

    always_comb begin
        if (DMA_LEN == 32'd0) begin
            init_len_m1 = 4'd0;
        end else if (DMA_LEN > 32'd16) begin
            init_len_m1 = 4'd15;               // 16-beat burst
        end else begin
            init_len_m1 = DMA_LEN[3:0] - 4'd1; // N word → LEN = N-1
        end
    end

    // *** 下一個 burst 長度的 combinational 計算
    logic [3:0]  next_len_m1;
    logic [31:0] remaining_after_chunk;

    // rd_count 計的是「目前為止已經收了幾個 data word」
    // 在一個 burst 的最後一拍被加完後，這裡看到的是「最新的 count」
    assign remaining_after_chunk = DMA_LEN-rd_count;// - {rd_count,2'b00};

    always_comb begin
        if (remaining_after_chunk == 32'd0) begin
            next_len_m1 = 4'd0;      // 不再發 burst
        end else if (remaining_after_chunk > 32'd16) begin
            next_len_m1 = 4'd15;     // 16-beat burst
        end else begin
            next_len_m1 = remaining_after_chunk[3:0] - 4'd1; // N → N-1
        end
    end

    // RADDR / RLEN
    always_ff @(posedge ACLK or negedge ARESETn) begin
        if(!ARESETn)begin
            m_raddr   <= 32'd0;
            m_rlen_m1 <= 4'd0;
        end
        else begin
            if(DMA_cs == DMA_IDLE)begin
                m_raddr   <= DESC_BASE; // 從cpu收到的地址
                m_rlen_m1 <= 4'd4;   // 5 words descriptor
            end
            // 讀 descriptor 期間更新下一階段的 RADDR / WADDR / 第一個 burst 長度
            else if ((DMA_cs == DMA_STRETCH) && (READ_MASTER_handshake)) begin
                // RADDR
                if (STRETCH_cs == STRETCH_EOC) begin
                    m_raddr <= DMA_SRC;
                end else begin
                    m_raddr <= m_raddr + 32'd4;
                end
                if (STRETCH_cs == STRETCH_EOC) begin
                    m_rlen_m1 <= init_len_m1;
                end
                
            end
            else if (DMA_cs == DMA_READ) begin
                // READ 期間：更新 RADDR / WADDR 與下一個 burst 長度
                // RADDR：最後一個 data word 讀完時，把 addr 換成 NEXT_DESC
                if (READ_MASTER_handshake) begin
                    m_raddr <= (rd_count == DMA_LEN - 32'd1)
                               ? NEXT_DESC
                               : (m_raddr + 32'd4);
                end

                // LEN 更新邏輯：一個 burst 收完後，決定下一個 burst 長度
                if (read_chunk_done && !writing_inflight) begin
                    if(rd_count == 0) m_rlen_m1 <= 4;
                    else m_rlen_m1 <= next_len_m1;
                end
                

            end
        end
    end

    
    // WADDR /  WLEN
    always_ff @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            m_waddr   <= 32'd0;
            m_wlen_m1 <= 4'd0;
        end else begin
            // 初始化：先讀 descriptor (固定 5 words)
            if (DMA_cs == DMA_IDLE) begin
                m_wlen_m1 <= 4'd0;   // descriptor 不寫
            end
            else if ((DMA_cs == DMA_STRETCH) && (READ_MASTER_handshake)) begin
                if (STRETCH_cs == STRETCH_EOC) begin
                    m_waddr   <= DMA_DST;
                    m_wlen_m1 <= init_len_m1;
                end
            end
            else if (DMA_cs == DMA_READ) begin
                // WADDR
                if (WRITE_MASTER_handshake) begin
                    m_waddr <= m_waddr + 32'd4;
                end
                // LEN 更新邏輯：一個 burst 收完後，決定下一個 burst 長度
                if (read_chunk_done && !writing_inflight) begin
                    m_wlen_m1 <= next_len_m1;
                end

                // WADDR
                if (WRITE_MASTER_handshake) begin
                    m_waddr <= m_waddr + 32'd4;
                end
            end
        end
    end

    // ============================================================
    // buffer：read_buffer（同時當作寫出的來源）
    // ============================================================
    always_ff @(posedge ACLK or negedge ARESETn) begin : BUFFER_BLOCK
        integer i;
        if (!ARESETn) begin
            for (i = 0; i < 16; i = i + 1) begin
                read_buffer[i] <= 32'd0;
            end
        end else begin
            // Read buffer：在 DMA_READ 收到 RDATA 就塞進來
            if (READ_MASTER_handshake && (DMA_cs == DMA_READ)) begin
                read_buffer[r_index] <= RDATA_M;
            end
        end
    end
    
    assign r_index = rd_count[3:0];
    //assign w_index = wr_count[3:0];
    // ============================================================
    // counter：rd_count / wr_count / r_index / w_index
    // ============================================================
    always_ff @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            rd_count <= 32'd0;
            wr_count <= 32'd0;
            //r_index         <= 4'd0;
            w_index         <= 4'd0;
        end else if (DMA_cs == DMA_READ) begin
            // Read channel
            if (READ_MASTER_handshake) begin
                //r_index         <= (RLAST_M) ? 4'd0 : (r_index + 4'd1);
                rd_count <= (rd_count == DMA_LEN - 32'd1)
                                ? 32'd0
                                : (rd_count + 32'd1);
            end

            // Write channel
            if (WRITE_MASTER_handshake) begin
                w_index         <= (WLAST_M) ? 4'd0 : (w_index + 4'd1);
                wr_count <= wr_count + 32'd1;
                //wr_count <= (WLAST_M) ? 4'd0 : (wr_count + 4'd1);
            end else if (B_MASTER_handshake) begin
                wr_count <= (wr_count == DMA_LEN) ? 32'd0 : wr_count;
            end
        end else begin
            // 非 READ 狀態時，把 index 清零
            //r_index <= 4'd0;
            w_index <= 4'd0;
        end
    end

    // ============================================================
    // pipeline flag：read_chunk_done / read_len_finish
    // ============================================================
    always_ff @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            read_chunk_done <= 1'b0;
            read_len_finish <= 1'b0;
        end else begin
            if (DMA_cs == DMA_STRETCH) begin
                read_chunk_done <= 1'b0;
                read_len_finish <= 1'b0;
            end else if (DMA_cs == DMA_READ) begin
                if (READ_MASTER_handshake && RLAST_M) begin
                    read_chunk_done <= 1'b1;
                    read_len_finish <= (rd_count == DMA_LEN - 32'd1);
                end else begin
                    // 只要沒有寫在飛，就把 flag 清掉
                    read_chunk_done <= (writing_inflight) ? read_chunk_done : 1'b0;
                end
            end else begin
                read_chunk_done <= 1'b0;
                read_len_finish <= 1'b0;
            end
        end
    end

endmodule
