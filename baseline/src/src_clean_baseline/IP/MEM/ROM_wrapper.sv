`include "../include/AXI_define.svh"



// ============================================================================
// ROM_wrapper (Modified for Burst Support)
//   - Read-only AXI Slave
//   - 支援 burst：使用 ARLEN_S
//   - timing：AR (第 N 拍握手) -> 第 N+1 拍給第 1 筆 R data
// ============================================================================
 
module ROM_1 (
    // ---------------- AXI clock domain ----------------
    input  logic                     ACLK,
    input  logic                     ARESETn,
 
`ifdef interface_En
    axi_read_if  axi_r_s,      // AR/R
`else
    // AR   READ ADDRESS
    input  logic [`AXI_IDS_BITS-1:0]  ARID_S,
    input  logic [`AXI_ADDR_BITS-1:0] ARADDR_S,
    input  logic [`AXI_LEN_BITS-1:0]  ARLEN_S,   // used: burst length-1
    input  logic [`AXI_SIZE_BITS-1:0] ARSIZE_S,  // not used
    input  logic [1:0]                ARBURST_S, // not used (assume INCR)
    input  logic                      ARVALID_S,
    output logic                      ARREADY_S,
 
    // R    READ DATA
    output logic [`AXI_IDS_BITS-1:0]  RID_S,
    output logic [`AXI_DATA_BITS-1:0] RDATA_S,
    output logic [1:0]                RRESP_S,
    output logic                      RLAST_S,
    output logic                      RVALID_S,
    input  logic                      RREADY_S,
`endif
 
    // ---------------- ROM clock domain ----------------
    input  wire                       rom_clk,
    input  wire                       rom_rst,     // active high
 
    input  logic [`AXI_DATA_BITS-1:0] ROM_out,     // DO from ROM (CK = rom_clk)
    output logic                      ROM_read,    // OE  (active high)
    output logic                      ROM_enable,  // CS  (active high)
    output logic [11:0]               ROM_address  // A[11:0]
);
 
 
    // =========================================================================
    //  Interface Mapping (Internal Wires)
    //  當 interface_En 開啟時，我們需要定義內部的 wire 來接 interface 的訊號
    // =========================================================================
`ifdef interface_En
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
 

`else
    // 用外面的 AR*/R* port
`endif
    
    // =========================================================================
    //  FSM Definition
    // =========================================================================
    typedef enum logic [0:0] {
        R_IDLE,
        R_DATA
    } state_RD_e;
 
    state_RD_e state_cs, state_ns;
 
    // =========================================================================
    //  Internal Registers
    // =========================================================================
    logic [`AXI_IDS_BITS-1:0]  id_reg;
    logic [`AXI_LEN_BITS-1:0]  len_reg;     // 儲存 Burst Length
    logic [`AXI_LEN_BITS-1:0]  len_cnt;     // 目前傳輸計數
    logic [11:0]               addr_reg;    // 遞增地址暫存
 
    // =========================================================================
    //  ROM Signals
    // =========================================================================
    localparam int ROM_ADDR_BITS = 12;
    logic [ROM_ADDR_BITS-1:0] rom_addr;
    logic                     rom_oe;
 
    //assign ROM_address = rom_addr;
    
    assign ROM_enable  = 1'b1;       // CS always high
 
    // =========================================================================
    //  Handshake & Burst Logic
    // =========================================================================
    logic AR_SLAVE_handshake;
    logic R_SLAVE_handshake;
    logic r_last_beat;
 
    assign AR_SLAVE_handshake = ARVALID_S && ARREADY_S;
    assign R_SLAVE_handshake  = RVALID_S  && RREADY_S;
   
    // 判斷最後一筆：計數器等於長度
    assign r_last_beat = (len_cnt == len_reg);
 
    //CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC
    //CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC 
    //CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC 
    //CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC 
    //CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC 

    //localparam int ROM_ADDR_BITS = 12;
    localparam int CMD_WIDTH     = ROM_ADDR_BITS; 
    localparam int CMD_DEPTH     = 4;
    localparam int DATA_DEPTH    = 4; 


    // =========================================================================
    //  Command FIFO (AXI → ROM)
    // =========================================================================
    logic [CMD_WIDTH-1:0] cmd_wdata, cmd_rdata;
    logic                 cmd_winc,  cmd_rinc, cmd_winc_reg;
    logic                 cmd_wfull, cmd_rempty;



    asyc_FIFO #(
        .width (CMD_WIDTH),
        .depath (CMD_DEPTH)
    ) u_cmd_fifo (
        .w_clk  (ACLK),
        .w_rst  (~ARESETn),
        .r_clk  (rom_clk),
        .r_rst  (rom_rst),
        .wdata  (cmd_wdata),
        .winc   (cmd_winc),
        .rdata  (cmd_rdata),
        .rinc   (cmd_rinc),
        .rempty (cmd_rempty),
        .wfull  (cmd_wfull)
    );


    logic                      data_wfull, data_rempty;

    assign cmd_wdata = (AR_SLAVE_handshake)?ARADDR_S[13:2]:addr_reg;
    //assign cmd_winc = cmd_winc_reg;
    assign cmd_winc = AR_SLAVE_handshake || 
                  ((state_cs == R_DATA) && (!r_last_beat) && (!cmd_wfull));
    
    assign ROM_address=(!cmd_rempty && !data_wfull)?cmd_rdata:'d0; //絕對不會滿出來所以我不管wire過去
    assign cmd_rinc=(!cmd_rempty&& !data_wfull); //這個同理應該都要擋一級

    logic cmd_rinc_reg;
    assign ROM_read    = cmd_rinc_reg;
    //assign ROM_read    = rom_oe;
    //assign ROM_enable  = 1'b1;

    always_ff @(posedge rom_clk or posedge rom_rst)begin
        if(rom_rst) begin
            cmd_rinc_reg<='d0;
        end
        else begin
            cmd_rinc_reg<=cmd_rinc;
        end
    
    end


    // =========================================================================
    //  Data FIFO (ROM → AXI)
    // =========================================================================
    logic [`AXI_DATA_BITS-1:0] data_wdata, data_rdata;
    logic                      data_winc,  data_rinc;
    

    

    asyc_FIFO #(
        .width (`AXI_DATA_BITS),
        .depath (DATA_DEPTH)
    ) u_data_fifo (
        .w_clk  (rom_clk),
        .w_rst  (rom_rst),
        .r_clk  (ACLK),
        .r_rst  (~ARESETn),
        .wdata  (data_wdata),
        .winc   (data_winc),
        .rdata  (data_rdata),
        .rinc   (data_rinc),
        .rempty (data_rempty),
        .wfull  (data_wfull)
    );


    assign data_wdata = ROM_out;
    assign data_winc = ROM_read;
    assign data_rinc = !data_rempty;


    assign RVALID_S = (/*(state_cs == R_DATA)&&*/!data_rempty);

    assign RDATA_S  = (data_rinc && !data_rempty) ? data_rdata:'d0;     // data_rdata : '0;
    

    //CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC
    //CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC 
    //CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC 
    //CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC 
    //CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC CDC 
    // END
    
    //counter 偷偷來
    logic [1:0] eheehe;
    logic gogo;
    assign gogo = (!data_rempty)&&(len_reg==eheehe);

    assign RLAST_S = gogo;
    always_ff @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin 
            eheehe <= 'b0;
            //gogo <='d0;
        end
        else if ((!data_rempty)&&(len_reg==eheehe)) begin
            eheehe <= 'd0;
            //gogo <='d1;
        end
        else if (!data_rempty)  begin
            eheehe <= eheehe+1'b1;
            //gogo <='d0;
        end
        else begin
            eheehe <= eheehe;
            //gogo <='d0;
        
        end
    end
    

    // =========================================================================
    //  ROM Address Mux
    // =========================================================================
    always_comb begin
        if (AR_SLAVE_handshake) begin
            // 剛握手時，直接送入 AR 地址
            rom_addr = ARADDR_S[ROM_ADDR_BITS+1 : 2];
        end
        else begin
            // 其餘時間(Bursting)，送入累加的地址
            //if(!)
            rom_addr = addr_reg;
        end
    end
 
    // =========================================================================
    //  FSM
    // =========================================================================
    always_ff @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) state_cs <= R_IDLE;
        else          state_cs <= state_ns;
    end
 
    always_comb begin
        state_ns = state_cs;
        unique case (state_cs)
            R_IDLE: begin
                if (AR_SLAVE_handshake)
                    state_ns = R_DATA;
            end
            R_DATA: begin
                // 必須是 Last Beat 且 Handshake 成功才離開
                if (R_SLAVE_handshake && r_last_beat)
                    state_ns = R_IDLE;
            end
            default: state_ns = R_IDLE;
        endcase
    end

    // Control signals
    logic cmd_rinc_next;
    logic data_winc_next;

/*
     // ROM Sequential Logic
    always_ff @(posedge rom_clk or posedge rom_rst) begin
        if (rom_rst) begin
            cmd_rinc     <= 1'b0;
            data_winc    <= 1'b0;
            rom_addr_reg <= '0;
            rom_oe_reg   <= 1'b0;
        end else begin
            cmd_rinc  <= cmd_rinc_next;
            data_winc <= 1'b0; // Pulse default

            unique case (rom_state_cs)
                ROM_IDLE: begin
                    // 如果決定要讀取 (條件同 Next State)
                    if (!cmd_rempty && !data_wfull) begin
                        // [FWFT Key]: 直接使用 cmd_rdata，不需等待
                        rom_addr_reg <= cmd_rdata; 
                        rom_oe_reg   <= 1'b1;
                    end else begin
                        rom_oe_reg   <= 1'b0;
                    end
                end

                ROM_READ: begin
                    if (data_winc_next) begin
                        data_winc <= 1'b1; // Write ROM_out to FIFO
                    end
                    // 保持 OE high (若連續讀取，會在 IDLE 無縫接軌)
                    rom_oe_reg <= 1'b1; 
                end
            endcase
        end
    end*/
    //assign cmd_winc_reg = (AR_SLAVE_handshake||(!r_last_beat));

    always_ff @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            id_reg   <= '0;
            len_reg  <= '0;
            len_cnt  <= '0;
            addr_reg <= '0;
            //rom_oe   <= 1'b0;
            //cmd_winc_reg <=1'b0;
        end
        else begin
            // --- IDLE State / AR Handshake ---
            if (AR_SLAVE_handshake) begin
                id_reg   <= ARID_S;
                len_reg  <= ARLEN_S;
                len_cnt  <= '0;
                // 下一拍 ROM 要讀的地址是 Base + 1
                addr_reg <= ARADDR_S[ROM_ADDR_BITS+1 : 2] + 1'b1;
                //rom_oe   <= 1'b1;
                //cmd_winc_reg <=1'b1;
            end
            // --- DATA State ---
            else if (state_cs == R_DATA) begin
                //rom_oe <= 1'b1;
               if ((!r_last_beat)&&(!cmd_wfull)) begin
                        len_cnt  <= len_cnt + 1'b1;
                        addr_reg <= addr_reg + 1'b1;
                        //cmd_winc_reg <=1'b1;
                    end
                /*if (R_SLAVE_handshake) begin
                    // 如果這筆傳完了，且還不是最後一筆 -> 準備下個地址
                    
                    // 如果是最後一筆傳完了 -> 關閉 OE
                    else begin
                        //rom_oe <= 1'b0;
                    end
                end*/
            end
            else begin
                //rom_oe <= 1'b0;
            end
        end
    end
 
    // =========================================================================
    //  Output Assignments
    // =========================================================================
    always_comb begin
        ARREADY_S = (state_cs == R_IDLE);
    end
    assign RREADY_S = axi_r_s.RREADY_s;
    assign RRESP_S = '0;
    assign RID_S = id_reg;
/*
    reg [31:0] dff_RDATA;
    reg pre_R_no_shacke;
    always @(posedge ACLK or negedge ARESETn) begin
        if(!ARESETn)begin
            dff_RDATA <= '0;
        end
        else if(!R_SLAVE_handshake && !pre_R_no_shacke)begin
            dff_RDATA <= ROM_out;
        end
        else begin
            dff_RDATA <= dff_RDATA;
        end
    end

    always @(posedge ACLK or negedge ARESETn) begin
        if(!ARESETn)begin
            pre_R_no_shacke <= '0;
        end
        else if(!R_SLAVE_handshake && state_cs==R_DATA)begin
            pre_R_no_shacke <= 1'b1;
        end
        else begin
            pre_R_no_shacke <= 1'b0;
        end
    end
    
    assign RID_S    = id_reg;
    assign RDATA_S  = (data_rinc && !data_rempty) ?((pre_R_no_shacke) ? dff_RDATA : ROM_out):'d0;     // data_rdata : '0;
    assign RRESP_S  = `AXI_RESP_OKAY;
    assign RVALID_S = !data_rempty; //(state_cs == R_DATA);
    assign RLAST_S  = (state_cs == R_DATA) && r_last_beat;
 
 */
endmodule