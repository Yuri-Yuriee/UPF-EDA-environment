`ifdef top_sim
`else
	`define test
	`define top_mem
	`include "define_list.v"
	`include "SRAM_wrapper.sv"
`endif

module WB_stage (
    input clk, rst,
    input global_stall,
    `ifdef test
        input [31:0] instr,
        input R_type_I, I_type_I, S_type_I, B_type_I, J_type_I, F_type_I, CSR_I,
        input [31:0] PC,
        input [2:0] funct3,
        input [4:0] funct5,
        input [6:0] funct7,
        input load_I, F_load_I,
        input [6:0] opcode,
        input store_I,
    `endif  
    input [4:0] rd, frd,
    input WB_control, F_WB_control,
    input [31:0] result, 

    output [4:0] out_rd, out_frd,
    output out_WB_control, out_F_WB_control,
    output [31:0] out_result
`ifdef cache
    ,
    output [4:0] FW_PWB_rd, FW_PWB_frd,
    output FW_PWB_WB_control, FW_PWB_F_WB_control,
    output [31:0] FW_PWB_result
`endif
);
`ifdef cache  
reg [4:0] dff_rd, dff_frd;
reg dff_WB_control, dff_F_WB_control;
reg [31:0] dff_result;
reg pre_stall;
`endif
assign out_rd =     rd;
assign out_frd =    frd;
assign out_WB_control = WB_control;
assign out_F_WB_control = F_WB_control;
assign out_result = result;
`ifdef cache  
assign FW_PWB_rd =             (pre_stall) ? dff_rd            : rd;
assign FW_PWB_frd =            (pre_stall) ? dff_frd           : frd;
assign FW_PWB_WB_control =     (pre_stall) ? dff_WB_control    : WB_control;
assign FW_PWB_F_WB_control =   (pre_stall) ? dff_F_WB_control  : F_WB_control;
assign FW_PWB_result =         (pre_stall) ? dff_result        : result;

// assign FW_PWB_rd =             rd;
// assign FW_PWB_frd =            frd;
// assign FW_PWB_WB_control =     WB_control;
// assign FW_PWB_F_WB_control =   F_WB_control;
// assign FW_PWB_result =         result;
//can opt  MEM stage with mux
always @(posedge clk or posedge rst) begin
    if (rst) begin
        pre_stall <= 1'd0;
    end 
    else begin
        pre_stall <= global_stall;
    end
end
always @(posedge clk or posedge rst) begin
    if (rst) begin
        dff_rd           <= 5'd0;
        dff_frd          <= 5'd0;
        dff_WB_control   <= 1'b0;
        dff_F_WB_control <= 1'b0;
        dff_result       <= 32'd0;  
    end 
    else if (pre_stall) begin
        dff_rd           <= dff_rd;
        dff_frd          <= dff_frd;
        dff_WB_control   <= dff_WB_control;
        dff_F_WB_control <= dff_F_WB_control;
        dff_result       <= dff_result;
    end 
    else begin
        dff_rd           <= rd;
        dff_frd          <= frd;
        dff_WB_control   <= WB_control;
        dff_F_WB_control <= F_WB_control;
        dff_result       <= result; 
    end
end
`endif


endmodule
