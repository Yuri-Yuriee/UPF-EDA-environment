//`define dff2_rdata;
module asyc_FIFO #(
    parameter width       = 34,
    parameter depath      = 2,
    parameter pointer_bit = $clog2(depath)+1,            // 必須等於 $clog2(depath)
    parameter SYNC_FF_NUM = 2                            // dff1/dff2 的同步級數，必須 >= 1
)(
    input w_clk, w_rst,
    input r_clk, r_rst,
    input [width-1:0] wdata,
    input winc,
    input rinc,
    output [width-1:0] rdata,
    output rempty,
    output wfull
);
 
 
reg  [pointer_bit-1:0]  waddr;
reg  [pointer_bit-1:0]  raddr;
logic [pointer_bit-1:0] waddr_counter;
logic [pointer_bit-1:0] raddr_counter;
 
wire [pointer_bit-1:0] wptr, rptr;
reg  [pointer_bit-1:0] dff0_wptr;
reg  [pointer_bit-1:0] dff0_rptr;

// 可調整級數的 destination-domain synchronizer
reg [pointer_bit-1:0] sync_wptr_ff [0:SYNC_FF_NUM-1];
reg [pointer_bit-1:0] sync_rptr_ff [0:SYNC_FF_NUM-1];

integer w_sync_i;
integer r_sync_i;
 
reg  [width-1:0] queue [depath-1:0];
 
wire wclken;
wire ren;
 
//對面指標轉回binary的結果
wire [pointer_bit-1:0] wq2_raddr;
wire [pointer_bit-1:0] rq2_waddr;
 
assign waddr = waddr_counter;
assign raddr = raddr_counter;
 
 
b_2_gray #(.bits(pointer_bit)) u_wptr (.index(waddr), .G_index(wptr));
b_2_gray #(.bits(pointer_bit)) u_rptr (.index(raddr), .G_index(rptr));
 
gray_2_b #(.bits(pointer_bit)) u_wq2_rptr (
    .G_index(sync_rptr_ff[SYNC_FF_NUM-1][pointer_bit-1:0]),
    .index(wq2_raddr)
);
 
gray_2_b #(.bits(pointer_bit)) u_rq2_wptr (
    .G_index(sync_wptr_ff[SYNC_FF_NUM-1][pointer_bit-1:0]),
    .index(rq2_waddr)
);
 
/*
assign wfull = ((pre_w_Adiff && !w_Adiff && pre_wclken) || dff2_rptr[pointer_bit]) ? 1'd1 : 1'd0;
assign rfull =  (rinc) ? 1'b0 :
                (!rinc && dff2_rptr[pointer_bit]) ? 1'b1 : 1'b0;
assign rempty = ((pre_r_Adiff && !r_Adiff && pre_ren && !dff2_wptr[pointer_bit]) || (!r_Adiff && pre_rempty)) ? 1'd1 : 1'd0;
assign ren = (!rempty && rinc) ? 1'd1 : 1'd0;
*/
 
 
assign wfull =
       ( (waddr[pointer_bit-2:0] == wq2_raddr[pointer_bit-2:0]) &&
         (waddr[pointer_bit-1] != wq2_raddr[pointer_bit-1]) );
assign rempty = (raddr == rq2_waddr);
assign ren = rinc & ~rempty;
assign wclken = winc & ~wfull;
 
// ------------------------------------------------------------
// write pointer
// ------------------------------------------------------------
always @(posedge w_clk or posedge w_rst) begin
    if (w_rst)
        waddr_counter <= '0;
    else if (wclken)
        waddr_counter <= waddr_counter + 1;
end
 
// ------------------------------------------------------------
// read pointer
// ------------------------------------------------------------
always @(posedge r_clk or posedge r_rst) begin
    if (r_rst)
        raddr_counter <= '0;
    else if (ren)
        raddr_counter <= raddr_counter + 1;
end
 
// ------------------------------------------------------------
// 寫入 FIFO
// ------------------------------------------------------------
always @(posedge w_clk) begin
    if (wclken)
        queue[waddr[pointer_bit-2:0]] <= wdata;
end
 
// ------------------------------------------------------------
// ★ pointer sync (正確 Gray 同步)
// ------------------------------------------------------------
//sync dff
always @(posedge w_clk or posedge w_rst)begin
    if(w_rst)begin
        dff0_wptr <= '0;
    end
    else begin
        dff0_wptr <=  { wptr};
    end
end
 
always @(posedge r_clk or posedge r_rst) begin
    if(r_rst)begin
        dff0_rptr <= '0;
    end
    else begin
        dff0_rptr <= {rptr};
    end
end
 
//async sync dff：wptr 同步到 r_clk domain
always @(posedge r_clk or posedge r_rst) begin
    if(r_rst)begin
        for (w_sync_i = 0; w_sync_i < SYNC_FF_NUM; w_sync_i = w_sync_i + 1) begin
            sync_wptr_ff[w_sync_i] <= '0;
        end
    end
    else begin
        sync_wptr_ff[0] <= dff0_wptr;
        for (w_sync_i = 1; w_sync_i < SYNC_FF_NUM; w_sync_i = w_sync_i + 1) begin
            sync_wptr_ff[w_sync_i] <= sync_wptr_ff[w_sync_i-1];
        end
    end
end
 
//async sync dff：rptr 同步到 w_clk domain
always @(posedge w_clk or posedge w_rst) begin
    if(w_rst)begin
        for (r_sync_i = 0; r_sync_i < SYNC_FF_NUM; r_sync_i = r_sync_i + 1) begin
            sync_rptr_ff[r_sync_i] <= '0;
        end
    end
    else begin
        sync_rptr_ff[0] <= dff0_rptr;
        for (r_sync_i = 1; r_sync_i < SYNC_FF_NUM; r_sync_i = r_sync_i + 1) begin
            sync_rptr_ff[r_sync_i] <= sync_rptr_ff[r_sync_i-1];
        end
    end
end
 
// ------------------------------------------------------------
// read data output
// ------------------------------------------------------------
assign rdata = queue[raddr[pointer_bit-2:0]];
 
endmodule
