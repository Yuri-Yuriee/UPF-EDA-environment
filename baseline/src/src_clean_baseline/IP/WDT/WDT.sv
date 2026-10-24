module WDT(
    input rst, clk,
    input WDEN,
    input WDLIVE,
    input [31:0] WTOCNT,
    `ifdef WDT_PG
        input WDT_CG,
    `endif 
    output WTO

);
//****************************************
//          Power Gate 
//power gate Control: WDEN (0:off, 1:on)
//
//****************************************
reg [31:0] cycle_cnt;
wire [31:0] next_cycle_cnt;
`ifdef test
    reg [63:0] test_reg;
`endif
wire time_out; 
assign time_out = (WDEN && (cycle_cnt >= WTOCNT)) ? 1'd1 : 1'd0;
assign WTO = time_out;

assign next_cycle_cnt = cycle_cnt + 1;
// counter
always @(posedge clk or posedge rst) begin
    if(rst)begin
        cycle_cnt <= '0;
    end
    `ifdef WDT_PG
    else if(WDT_CG)begin
        cycle_cnt <= cycle_cnt;
    end
    `endif
    else if(!WDEN || WDLIVE)begin
        cycle_cnt <= '0;
    end
    else if(WDEN && !time_out)begin
        cycle_cnt <= next_cycle_cnt;
    end
    else begin
        cycle_cnt <= cycle_cnt;
    end
end

//test REG
`ifdef test
`ifndef SYNTHESIS
always @(posedge clk or posedge rst) begin
    test_reg <= cycle_cnt;
end
`endif
`endif

// reg rerestore_pulse;
// always @(posedge clk or posedge rst) begin
//     if()begin
//         rerestore_pulse = WDEN
//     end
//     else begin
        
//     end
// end



endmodule