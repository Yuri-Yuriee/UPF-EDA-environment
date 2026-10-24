//`include "../include/AXI_define.svh"
//`include "../include/AXI_interface.svh"
//`define vip_trick
`ifdef PB_tree
    `include "/Users/zhuangzhengye/Desktop/AVSD/HW2/PB_tree.sv"
`endif

`define outstanding 4
`define time_out_valid
`define miss_hit_valid

`define OKEY    2'd0
`define EXOKAY  2'd1
`define SLVERR  2'd2
`define DECERR  2'd3

`define idle_ST  2'd0
`define read_ST  2'd1
`define write_ST 2'd2

typedef enum logic [1:0] { 
    idle_ST,
    read_ST,
    write_ST
} state_st;

module slave_simple #(
    parameter outstanding = 4
) (
    input           ACLK,
    input           ARESETn,

    axi_read_if.slave   axi_r_s,
    axi_write_if.slave  axi_w_s,

    input               stall_W,
    input               stall_R,

    input               in_miss,
    input               in_hit,
    input  [31:0]       read_data,
    output              Read_Enable,
    output [31:0]       Addr,
    output [31:0]       Write_data,
    output              Write_Enable,
    output [3:0]        out_WSTRB
);

// ============================================================
//      interface alias
// ============================================================

wire [7:0]    AWID_S;
wire [31:0]   AWADDR_S;
wire [3:0]    AWLEN_S;
wire [2:0]    AWSIZE_S;
wire [1:0]    AWBURST_S;
wire          AWVALID_S;
wire          AWREADY_S;

assign AWID_S             = axi_w_s.AWID_s;
assign AWADDR_S           = axi_w_s.AWADDR_s;
assign AWLEN_S            = axi_w_s.AWLEN_s;
assign AWSIZE_S           = axi_w_s.AWSIZE_s;
assign AWBURST_S          = axi_w_s.AWBURST_s;
assign AWVALID_S          = axi_w_s.AWVALID_s;
assign axi_w_s.AWREADY_s  = AWREADY_S;

wire [31:0]   WDATA_S;
wire [3:0]    WSTRB_S;
wire          WLAST_S;
wire          WVALID_S;
wire          WREADY_S;

assign WDATA_S            = axi_w_s.WDATA_s;
assign WSTRB_S            = axi_w_s.WSTRB_s;
assign WLAST_S            = axi_w_s.WLAST_s;
assign WVALID_S           = axi_w_s.WVALID_s;
assign axi_w_s.WREADY_s   = WREADY_S;

wire [7:0]    BID_S;
wire [1:0]    BRESP_S;
wire          BVALID_S;
wire          BREADY_S;

assign axi_w_s.BID_s      = BID_S;
assign axi_w_s.BRESP_s    = BRESP_S;
assign axi_w_s.BVALID_s   = BVALID_S;
assign BREADY_S           = axi_w_s.BREADY_s;

wire [7:0]    ARID_S;
wire [31:0]   ARADDR_S;
wire [3:0]    ARLEN_S;
wire [2:0]    ARSIZE_S;
wire [1:0]    ARBURST_S;
wire          ARVALID_S;
wire          ARREADY_S;

assign ARID_S             = axi_r_s.ARID_s;
assign ARADDR_S           = axi_r_s.ARADDR_s;
assign ARLEN_S            = axi_r_s.ARLEN_s;
assign ARSIZE_S           = axi_r_s.ARSIZE_s;
assign ARBURST_S          = axi_r_s.ARBURST_s;
assign ARVALID_S          = axi_r_s.ARVALID_s;
assign axi_r_s.ARREADY_s  = ARREADY_S;

wire [7:0]    RID_S;
wire [31:0]   RDATA_S;
wire [1:0]    RRESP_S;
wire          RLAST_S;
wire          RVALID_S;
wire          RREADY_S;

assign axi_r_s.RID_s      = RID_S;
assign axi_r_s.RDATA_s    = RDATA_S;
assign axi_r_s.RRESP_s    = RRESP_S;
assign axi_r_s.RLAST_s    = RLAST_S;
assign axi_r_s.RVALID_s   = RVALID_S;
assign RREADY_S           = axi_r_s.RREADY_s;

//******************************
//          define
//****************************** 
state_st state;
state_st next_state;
reg mem_last;
wire in_last;
wire burst_done;
reg [3:0] burst_counter;
reg [31:0] address_counter;
reg [7:0] ID_current;
wire Wdata_done;
reg WLAST_current;

reg         RVALID_buffer;
reg [31:0]  RDATA_buffer;

reg         BVALID_buffer;
reg [3:0]   BID_buffer;
reg [1:0]   BRESP_buffer;

//******************************
//          FSM
//****************************** 

wire AR_shake = (ARREADY_S && ARVALID_S) ? 1'b1 : 1'b0; 
wire AW_shake = (AWREADY_S && AWVALID_S) ? 1'b1 : 1'b0;
wire W_shake  = (WREADY_S  && WVALID_S)  ? 1'b1 : 1'b0;
wire B_shake  = (BREADY_S  && BVALID_S)  ? 1'b1 : 1'b0;
wire R_shake  = (RREADY_S  && RVALID_S)  ? 1'b1 : 1'b0;

always @(posedge ACLK or negedge ARESETn) begin
    if(!ARESETn) begin
        state <= idle_ST;
    end
    else begin
        state <= next_state; 
    end
end

always @(*) begin
    case (state)
        idle_ST : begin
            if(AR_shake) begin
                next_state = read_ST;
            end
            else if(AW_shake) begin
                next_state = write_ST;
            end
            else begin
                next_state = idle_ST;
            end
        end
        read_ST : begin
            if(burst_done) begin
                next_state = idle_ST;
            end
            else begin
                next_state = read_ST;
            end
        end
        write_ST : begin
            if(burst_done) begin
                next_state = idle_ST;
            end
            else begin
                next_state = write_ST;
            end
        end
        default: next_state = idle_ST;
    endcase
end

//******************************
//          counter
//****************************** 

always @(posedge ACLK or negedge ARESETn) begin
    if(!ARESETn) begin
        burst_counter <= 4'd0;
        address_counter <= 32'd0;
    end
    else if(AR_shake) begin
        burst_counter <= ARLEN_S-1;
        address_counter <= ARADDR_S+32'd4;
    end
    else if(AW_shake && W_shake) begin
        burst_counter <= AWLEN_S-1;
        address_counter <= AWADDR_S+32'd4;
    end
    else if(AW_shake) begin
        burst_counter <= AWLEN_S;
        address_counter <= AWADDR_S;
    end
    else if(state == read_ST && R_shake) begin
        burst_counter <= burst_counter-1;
        address_counter <= address_counter+32'd4;
    end
    else if(state == write_ST && W_shake) begin
        burst_counter <= burst_counter-1;
        address_counter <= address_counter+32'd4;
    end
    else begin
        burst_counter <= burst_counter;
        address_counter <= address_counter+32'd4;
    end
end

`ifdef vip_trick
assign in_last = (AR_shake & ARLEN_S == 0) ? 1'b1 : 
                 (AW_shake & ARLEN_S == 0) ? 1'b1 :
                 (state == read_ST && burst_counter==0) ? 1'b1 :
                 (state == write_ST && burst_counter==0) ? 1'b1 : 1'b0;
`else
assign in_last = (AR_shake & ARLEN_S == 0) ? 1'b1 : 
                 (state == read_ST && burst_counter==0) ? 1'b1 :
                 (state == write_ST && burst_counter==0) ? 1'b1 : 1'b0;
`endif 

always @(posedge ACLK or negedge ARESETn) begin
    if(!ARESETn) begin
        mem_last <= 1'b0;
    end
    else if(!R_shake && state == read_ST && mem_last) begin
        mem_last <= 1'b1;
    end
    else if(!B_shake && state == write_ST && mem_last) begin
        mem_last <= 1'b1;
    end
    else if(Write_Enable || Read_Enable) begin
        mem_last <= in_last;
    end
    else if(R_shake || B_shake) begin
        mem_last <= 1'b0;
    end
    else begin
        mem_last <= mem_last;
    end
end

assign burst_done = (state == read_ST  && mem_last && R_shake) ? 1'b1 :
                    (state == write_ST && mem_last && B_shake) ? 1'b1 : 1'b0;

//******************************
//       plug interface output Signal
//******************************

assign Read_Enable  = (AR_shake) ? 1'b1 : 
                      (state==read_ST && R_shake && !mem_last) ? 1'b1 : 1'b0;

assign Addr         = (AR_shake) ? ARADDR_S : 
                      (AW_shake) ? AWADDR_S : address_counter;

assign Write_data   = WDATA_S;

assign Write_Enable = (AW_shake && W_shake) ? 1'b1 : 
                      (state == write_ST && W_shake && !mem_last) ? 1'b1 : 1'b0;

assign out_WSTRB    = WSTRB_S;

//******************************
//       channel arbitrator
//******************************

// stall_R 擋 ARREADY / RVALID
assign ARREADY_S = (!stall_R && state == idle_ST) ? 1'b1 : 1'b0;

// stall_W 擋 AWREADY / WREADY / BVALID
assign AWREADY_S = (!stall_W && state == idle_ST) ? 1'b1 : 1'b0;

assign RVALID_S = (!stall_R && RVALID_buffer) ? 1'b1 : 
                  (!stall_R && state == read_ST) ? 1'b1 : 1'b0;

assign RID_S    = ID_current;

assign RDATA_S  = (RVALID_buffer) ? RDATA_buffer : 
                  (state == read_ST) ? read_data : 1'b0;

assign RRESP_S  = 2'b0;
assign RLAST_S  = mem_last;

assign BVALID_S = (!stall_W && mem_last && state == write_ST) ? 1'b1 : 1'b0;

`ifdef vip_trick
reg pre_AW_W_shake;
assign BID_S = (!pre_AW_W_shake) ? ID_current : 8'd0;
`else
assign BID_S = ID_current;
`endif 

assign BRESP_S = 2'b00;

assign WREADY_S = (!stall_W && state == write_ST && !Wdata_done) ? 1'b1 :
                  (!stall_W && state == idle_ST && AW_shake) ? 1'b1 : 1'b0;

//R Buffer
always @(posedge ACLK or negedge ARESETn) begin
    if(!ARESETn) begin
        RVALID_buffer <= 1'b0;
        RDATA_buffer  <= 32'd0;
    end
    else begin
        if(state==read_ST && !R_shake && !RVALID_buffer) begin
            RVALID_buffer <= RVALID_S;
            RDATA_buffer  <= RDATA_S;
        end
        else if(RVALID_buffer & R_shake) begin
            RVALID_buffer <= 1'b0;
            RDATA_buffer <= RDATA_buffer;
        end
        else begin
            RVALID_buffer <= RVALID_buffer;
            RDATA_buffer <= RDATA_buffer;
        end
    end
end

assign Wdata_done = WLAST_current;

always @(posedge ACLK or negedge ARESETn) begin
    if(!ARESETn) begin
        WLAST_current <= 1'd0;
    end
    else if(W_shake) begin
        WLAST_current <= WLAST_S;
    end
    else if(state == idle_ST) begin
        WLAST_current <= 1'd0;
    end
    else begin
        WLAST_current <= WLAST_current;
    end
end

always @(posedge ACLK or negedge ARESETn) begin
    if(!ARESETn) begin
        ID_current <= 8'd0;
    end
    else if(AR_shake) begin
        ID_current <= ARID_S;
    end
    else if(AW_shake) begin
        ID_current <= AWID_S;
    end
    else begin
        ID_current <= ID_current;
    end
end

`ifdef vip_trick
always @(posedge ACLK or negedge ARESETn) begin
    if(!ARESETn) begin
        pre_AW_W_shake <= 1'd0;
    end 
    else if(AW_shake && W_shake) begin
        pre_AW_W_shake <= 1'd1;
    end
    else if(B_shake) begin
        pre_AW_W_shake <= 1'd0;
    end
    else begin
        pre_AW_W_shake <= pre_AW_W_shake;
    end
end
`endif 

endmodule