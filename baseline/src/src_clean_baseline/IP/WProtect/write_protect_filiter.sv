`define sysA_allow_write_sysA_start     32'h0000_0000
`define sysA_allow_write_sysA_end       32'h0000_0004
`define sysA_filiter_valid              32'h0000_0008

module write_protect_filiter (
    input   clk,
    input   rst,
    
    axi_write_if.bus_master axi_w_m_i,
    axi_write_if.master     axi_w_m_o,

    axi_read_if.bus_slave   axi_r_m_o,
    axi_read_if.slave       axi_r_m_i,

    output                  sys_error
);

localparam logic [1:0] AXI_RESP_OKAY   = 2'b00;
localparam logic [1:0] AXI_RESP_DECERR = 2'b11;

//============================================================
//      address decode function
//============================================================
function automatic logic is_filter_mmio_addr;
    input logic [31:0] addr;
    begin
        case (addr)
            `sysA_allow_write_sysA_start,
            `sysA_allow_write_sysA_end,
            `sysA_filiter_valid: begin
                is_filter_mmio_addr = 1'b1;
            end

            default: begin
                is_filter_mmio_addr = 1'b0;
            end
        endcase
    end
endfunction


function automatic logic is_hw_allow_write_addr;
    input logic [31:0] addr;
    begin
        case (addr)

            //================================================
            // 這邊放你硬體寫死要允許 write 的 MMIO address
            //================================================
            32'h1000_0000,
            32'h1000_0004,
            32'h1000_0008: begin
                is_hw_allow_write_addr = 1'b1;
            end

            default: begin
                // //================================================
                // // 如果有一段 range 永遠允許，也可以寫這裡
                // // 不需要的話，把這段改成 1'b0
                // //================================================
                // is_hw_allow_write_addr =
                //     ((addr >= 32'h2000_0000) &&
                //      (addr <= 32'h2000_00FF));
                is_hw_allow_write_addr = 1'b0;

            end
        endcase
    end
endfunction

//============================================================
//      FSM define
//============================================================
typedef enum logic {  
    ST_idal,
    ST_local_use
} ST_Filiter;

typedef enum logic {
    RD_idal,
    RD_wait
} RD_Filter;

ST_Filiter state, next_state;
RD_Filter rd_state, rd_next_state;

//============================================================
//      AXI reg
//============================================================
reg         filter_valid;
reg [31:0]  allow_write_sysA_start;
reg [31:0]  allow_write_sysA_end;

//============================================================
//      write control
//============================================================
wire        pass;
wire        block;
reg         localwrite;
wire        B_shk;
wire        AW_shk;
wire        local_use;

wire [31:0] awaddr;
wire        range_allow;
wire        hw_allow_write;

reg         block_use_q;
reg         block_bvalid_q;
reg [AXI_IDS_BITS-1:0] block_bid_q;


assign sys_error = block;

assign local_use = (state == ST_local_use);

assign awaddr = axi_w_m_i.AWADDR_m[31:0];

// system unprotect
assign range_allow =
    (awaddr >= allow_write_sysA_start) &&
    (awaddr <= allow_write_sysA_end);

// MMIO allow
assign hw_allow_write =
    is_hw_allow_write_addr(awaddr);

// filiter
always @(*) begin
    localwrite = 1'b0;
    if (axi_w_m_i.AWVALID_m) begin
        localwrite = is_filter_mmio_addr(awaddr);
    end
end

assign pass =
    (!localwrite) &&
    (
        (!filter_valid) ||
        hw_allow_write  ||
        range_allow
    );

assign block = filter_valid & !pass & !localwrite;


//shk
assign AW_shk = axi_w_m_i.AWVALID_m & axi_w_m_i.AWREADY_m;
assign B_shk  = axi_w_m_i.BREADY_m  & axi_w_m_i.BVALID_m;

//============================================================
//      read control
//============================================================
reg         read_local_q;
wire        localread;
wire        AR_shk;
wire        R_shk;

assign localread =
    axi_r_m_i.ARVALID_s &&
    is_filter_mmio_addr(axi_r_m_i.ARADDR_s[31:0]);

assign AR_shk = axi_r_m_i.ARVALID_s & axi_r_m_i.ARREADY_s;
assign R_shk  = axi_r_m_i.RVALID_s  & axi_r_m_i.RREADY_s & axi_r_m_i.RLAST_s;

//============================================================
//      local AXI interface
//============================================================
axi_write_if axi_w_local();
axi_read_if  axi_r_local();

//============================================================
//      slave_simple req / resp
//============================================================
wire                        Read_Enable;
wire                        Write_Enable;
wire [AXI_DATA_BITS-1:0]    Write_data;
wire [AXI_ADDR_BITS-1:0]    Addr;
wire [AXI_STRB_BITS-1:0]    WSTRB;

reg                         miss;
reg                         hit;
reg  [AXI_DATA_BITS-1:0]    read_data;

//============================================================
//      upstream -> local slave_simple write
//============================================================

//-----------------------
// local AW channel
//-----------------------
assign axi_w_local.AWID_s    = axi_w_m_i.AWID_m;
assign axi_w_local.AWADDR_s  = axi_w_m_i.AWADDR_m;
assign axi_w_local.AWLEN_s   = axi_w_m_i.AWLEN_m;
assign axi_w_local.AWSIZE_s  = axi_w_m_i.AWSIZE_m;
assign axi_w_local.AWBURST_s = axi_w_m_i.AWBURST_m;


assign axi_w_local.AWVALID_s =
    ((state == ST_idal) && localwrite) ? axi_w_m_i.AWVALID_m : 1'b0;

//-----------------------
// local W channel
//-----------------------
assign axi_w_local.WDATA_s  = axi_w_m_i.WDATA_m;
assign axi_w_local.WSTRB_s  = axi_w_m_i.WSTRB_m;
assign axi_w_local.WLAST_s  = axi_w_m_i.WLAST_m;

assign axi_w_local.WVALID_s =
    (local_use && !block_use_q) ? axi_w_m_i.WVALID_m : 1'b0;

//-----------------------
// local B channel
//-----------------------
assign axi_w_local.BREADY_s =
    (local_use && !block_use_q) ? axi_w_m_i.BREADY_m : 1'b0;

//============================================================
//      AXI write pass-through / local / block
//============================================================

//-----------------------
// AW channel
//-----------------------
assign axi_w_m_o.AWID_m    = axi_w_m_i.AWID_m;
assign axi_w_m_o.AWADDR_m  = axi_w_m_i.AWADDR_m;
assign axi_w_m_o.AWLEN_m   = axi_w_m_i.AWLEN_m;
assign axi_w_m_o.AWSIZE_m  = axi_w_m_i.AWSIZE_m;
assign axi_w_m_o.AWBURST_m = axi_w_m_i.AWBURST_m;

assign axi_w_m_o.AWVALID_m =
    (localwrite) ? 1'b0 :
    (block)      ? 1'b0 :
    (local_use)  ? 1'b0 :
    (pass)       ? axi_w_m_i.AWVALID_m :
                   1'b0;

assign axi_w_m_i.AWREADY_m =
    (localwrite) ? axi_w_local.AWREADY_s :
    (block)      ? 1'b1 :
    (local_use)  ? 1'b0 :
    (pass)       ? axi_w_m_o.AWREADY_m :
                   1'b0;

//-----------------------
// W channel
//-----------------------
assign axi_w_m_o.WDATA_m  = axi_w_m_i.WDATA_m;
assign axi_w_m_o.WSTRB_m  = axi_w_m_i.WSTRB_m;
assign axi_w_m_o.WLAST_m  = axi_w_m_i.WLAST_m;

assign axi_w_m_o.WVALID_m =
    (local_use) ? 1'b0 :
    (pass)      ? axi_w_m_i.WVALID_m :
                  1'b0;

assign axi_w_m_i.WREADY_m =
    (local_use && block_use_q)  ? !block_bvalid_q :
    (local_use && !block_use_q) ? axi_w_local.WREADY_s :
    (pass)                      ? axi_w_m_o.WREADY_m :
                                  1'b0;

//-----------------------
// B channel
//-----------------------
assign axi_w_m_i.BID_m =
    (local_use && block_use_q)  ? block_bid_q :
    (local_use && !block_use_q) ? axi_w_local.BID_s :
                                  axi_w_m_o.BID_m;

assign axi_w_m_i.BRESP_m =
    (local_use && block_use_q)  ? AXI_RESP_DECERR :
    (local_use && !block_use_q) ? axi_w_local.BRESP_s :
                                  axi_w_m_o.BRESP_m;

assign axi_w_m_i.BVALID_m =
    (local_use && block_use_q)  ? block_bvalid_q :
    (local_use && !block_use_q) ? axi_w_local.BVALID_s :
                                  axi_w_m_o.BVALID_m;

assign axi_w_m_o.BREADY_m =
    (local_use) ? 1'b0 :
                  axi_w_m_i.BREADY_m;

//============================================================
//      upstream -> local slave_simple read
//============================================================

//-----------------------
// local AR channel
//-----------------------
assign axi_r_local.ARID_s    = axi_r_m_i.ARID_s;
assign axi_r_local.ARADDR_s  = axi_r_m_i.ARADDR_s;
assign axi_r_local.ARLEN_s   = axi_r_m_i.ARLEN_s;
assign axi_r_local.ARSIZE_s  = axi_r_m_i.ARSIZE_s;
assign axi_r_local.ARBURST_s = axi_r_m_i.ARBURST_s;


assign axi_r_local.ARVALID_s =
    ((rd_state == RD_idal) && localread) ? axi_r_m_i.ARVALID_s : 1'b0;

//-----------------------
// local R channel
//-----------------------
assign axi_r_local.RREADY_s =
    ((rd_state == RD_wait) && read_local_q) ? axi_r_m_i.RREADY_s : 1'b0;

//============================================================
//      AXI read pass-through
//============================================================

//-----------------------
// AR channel to downstream
//-----------------------
assign axi_r_m_o.ARID_s    = axi_r_m_i.ARID_s;
assign axi_r_m_o.ARADDR_s  = axi_r_m_i.ARADDR_s;
assign axi_r_m_o.ARLEN_s   = axi_r_m_i.ARLEN_s;
assign axi_r_m_o.ARSIZE_s  = axi_r_m_i.ARSIZE_s;
assign axi_r_m_o.ARBURST_s = axi_r_m_i.ARBURST_s;

assign axi_r_m_o.ARVALID_s =
    ((rd_state == RD_idal) && !localread) ? axi_r_m_i.ARVALID_s : 1'b0;

//-----------------------
// ARREADY back to upstream
//-----------------------
assign axi_r_m_i.ARREADY_s =
    (rd_state == RD_idal) ?
        (localread ? axi_r_local.ARREADY_s : axi_r_m_o.ARREADY_s) :
        1'b0;

//-----------------------
// R channel back to upstream
//-----------------------
assign axi_r_m_i.RID_s =
    (read_local_q) ? axi_r_local.RID_s :
                     axi_r_m_o.RID_s;

assign axi_r_m_i.RDATA_s =
    (read_local_q) ? axi_r_local.RDATA_s :
                     axi_r_m_o.RDATA_s;

assign axi_r_m_i.RRESP_s =
    (read_local_q) ? axi_r_local.RRESP_s :
                     axi_r_m_o.RRESP_s;

assign axi_r_m_i.RLAST_s =
    (read_local_q) ? axi_r_local.RLAST_s :
                     axi_r_m_o.RLAST_s;

assign axi_r_m_i.RVALID_s =
    (rd_state == RD_wait) ?
        ((read_local_q) ? axi_r_local.RVALID_s : axi_r_m_o.RVALID_s) :
        1'b0;

//-----------------------
// RREADY to downstream
//-----------------------
assign axi_r_m_o.RREADY_s =
    ((rd_state == RD_wait) && !read_local_q) ? axi_r_m_i.RREADY_s : 1'b0;

//============================================================
//      MMIO read data / hit miss
//============================================================
always @(*) begin
    hit       = 1'b0;
    miss      = 1'b0;
    read_data = '0;

    case (Addr[31:0])
        `sysA_allow_write_sysA_start: begin
            hit       = 1'b1;
            read_data = {{(AXI_DATA_BITS-32){1'b0}}, allow_write_sysA_start};
        end

        `sysA_allow_write_sysA_end: begin
            hit       = 1'b1;
            read_data = {{(AXI_DATA_BITS-32){1'b0}}, allow_write_sysA_end};
        end

        `sysA_filiter_valid: begin
            hit       = 1'b1;
            read_data = {{(AXI_DATA_BITS-1){1'b0}}, filter_valid};
        end

        default: begin
            miss      = 1'b1;
            read_data = '0;
        end
    endcase
end

//============================================================
//      MMIO reg write + block response control
//============================================================
always @(posedge clk or posedge rst) begin
    if (rst) begin
        filter_valid            <= 1'b0;
        allow_write_sysA_start  <= 32'd0;
        allow_write_sysA_end    <= 32'd0;

        block_use_q             <= 1'b0;
        block_bvalid_q          <= 1'b0;
        block_bid_q             <= '0;
    end
    else begin
        //====================================================
        // block write：吃掉 AW，記住 ID，等 WLAST 後回 DECERR
        //====================================================
        if ((state == ST_idal) && block && AW_shk) begin
            block_use_q    <= 1'b1;
            block_bvalid_q <= 1'b0;
            block_bid_q    <= axi_w_m_i.AWID_m;
        end
        else if ((state == ST_idal) && localwrite && AW_shk) begin
            block_use_q    <= 1'b0;
            block_bvalid_q <= 1'b0;
            block_bid_q    <= '0;
        end

        if (local_use &&
            block_use_q &&
            axi_w_m_i.WVALID_m &&
            axi_w_m_i.WREADY_m &&
            axi_w_m_i.WLAST_m) begin
            block_bvalid_q <= 1'b1;
        end

        if (local_use && block_use_q && B_shk) begin
            block_use_q    <= 1'b0;
            block_bvalid_q <= 1'b0;
            block_bid_q    <= '0;
        end

        //====================================================
        // local MMIO write
        //====================================================
        if (Write_Enable && hit) begin
            case (Addr[31:0])
                `sysA_allow_write_sysA_start: begin
                    if (WSTRB[0]) allow_write_sysA_start[7:0]    <= Write_data[7:0];
                    if (WSTRB[1]) allow_write_sysA_start[15:8]   <= Write_data[15:8];
                    if (WSTRB[2]) allow_write_sysA_start[23:16]  <= Write_data[23:16];
                    if (WSTRB[3]) allow_write_sysA_start[31:24]  <= Write_data[31:24];
                end

                `sysA_allow_write_sysA_end: begin
                    if (WSTRB[0]) allow_write_sysA_end[7:0]      <= Write_data[7:0];
                    if (WSTRB[1]) allow_write_sysA_end[15:8]     <= Write_data[15:8];
                    if (WSTRB[2]) allow_write_sysA_end[23:16]    <= Write_data[23:16];
                    if (WSTRB[3]) allow_write_sysA_end[31:24]    <= Write_data[31:24];
                end

                `sysA_filiter_valid: begin
                    if (WSTRB[0]) filter_valid <= Write_data[0];
                end

                default: begin
                end
            endcase
        end
    end
end

//============================================================
//      write FSM
//============================================================
always @(posedge clk or posedge rst) begin
    if (rst) begin
        state <= ST_idal;
    end
    else begin
        state <= next_state;
    end
end

always @(*) begin
    case (state)
        ST_idal: begin
            next_state = (AW_shk && (localwrite || block)) ? ST_local_use : ST_idal;
        end

        ST_local_use: begin
            next_state = (B_shk) ? ST_idal : ST_local_use;
        end

        default: begin
            next_state = ST_idal;
        end
    endcase
end

//============================================================
//      read FSM
//============================================================
always @(posedge clk or posedge rst) begin
    if (rst) begin
        rd_state     <= RD_idal;
        read_local_q <= 1'b0;
    end
    else begin
        rd_state <= rd_next_state;

        if ((rd_state == RD_idal) && AR_shk) begin
            read_local_q <= localread;
        end
        else if ((rd_state == RD_wait) && R_shk) begin
            read_local_q <= 1'b0;
        end
    end
end

always @(*) begin
    case (rd_state)
        RD_idal: begin
            rd_next_state = (AR_shk) ? RD_wait : RD_idal;
        end

        RD_wait: begin
            rd_next_state = (R_shk) ? RD_idal : RD_wait;
        end

        default: begin
            rd_next_state = RD_idal;
        end
    endcase
end

//============================================================
//      local MMIO slave
//============================================================
slave_simple u_slave_simple (
    .ACLK           (clk),
    .ARESETn        (~rst),

    .axi_r_s        (axi_r_local),
    .axi_w_s        (axi_w_local),

    // req
    .Read_Enable    (Read_Enable),
    .Write_Enable   (Write_Enable),
    .Write_data     (Write_data),
    .Addr           (Addr),
    .out_WSTRB      (WSTRB),

    // resp
    .in_miss        (miss),
    .in_hit         (hit),
    .read_data      (read_data)
);

endmodule