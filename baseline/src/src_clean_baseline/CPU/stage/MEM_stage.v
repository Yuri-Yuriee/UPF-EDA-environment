`ifdef top_sim
`else
	`define test
	`define top_mem
	`include "define_list.v"
	`include "SRAM_wrapper.sv"
`endif

`define FUNCT3_LW   3'b010
`define FUNCT3_LB   3'b000
`define FUNCT3_LH   3'b001
`define FUNCT3_LBU  3'b100
`define FUNCT3_LHU  3'b101

module MEM_stage (
    input clk, rst,
	input global_stall,
    `ifdef test
        input [31:0] instr,
        input R_type_I, I_type_I, S_type_I, B_type_I, J_type_I, F_type_I, CSR_I,
        input [31:0] PC,
        input [4:0] funct5,
        input [6:0] funct7,
    	input [6:0] opcode,
    `endif  

    input [31:0] EXE_result,
    input load_I, F_load_I,
    input [4:0] rd, frd,
    input [2:0] funct3,
    input WB_control, F_WB_control, store_I,
    input [31:0] store_data,
    //input stall,
	//input F_operation,
    //top_mem_pin
    `ifdef top_mem
        output dcache_low_Eable,
        output dcache_WR,
        output [31:0] dcache_hidden_map,
        output [15:0] dcache_EXE_result_16,
        output [31:0] dcache_store_data,
        input   [31:0] dcache_read_data,
    `endif
    `ifdef test
        output [31:0] out_instr,
        output out_R_type_I, out_I_type_I, out_S_type_I, out_B_type_I, out_J_type_I, out_F_type_I, out_CSR_I,
        output [31:0] out_PC,
        output [2:0] out_funct3,
        output [4:0] out_funct5,
        output [6:0] out_funct7,
        output out_load_I, out_F_load_I,
        output [6:0] out_opcode,
        output out_store_I,
    `endif  
    output [4:0] out_rd, out_frd,
    output out_WB_control, out_F_WB_control,
    output [31:0] out_result,
    output [31:0] Addr32
    
);
// ---------- DFF 宣告 ----------
`ifdef test
reg [31:0] dff_instr;
reg        dff_R_type_I, dff_I_type_I, dff_S_type_I, dff_B_type_I, dff_J_type_I, dff_F_type_I, dff_CSR_I;
reg [31:0] dff_PC;
reg [4:0]  dff_funct5;
reg [6:0]  dff_funct7;
reg [6:0]  dff_opcode;
reg        dff_store_I;
`endif

reg [4:0]  dff_rd, dff_frd;
reg        dff_WB_control, dff_F_WB_control;
reg [31:0] dff_EXE_result;
reg [2:0]  dff_funct3;
reg        dff_load_I, dff_F_load_I;

//W=0 R=1 
wire WR = (store_I) ? 1'b0 : 1'b1;  //default read mode to avoid error write

//0 :active, 1 : idal
`ifdef  low_power_mode
    wire low_Eable = (load_I | F_load_I | store_I) ? 1'b0 : 1'b1;
`else
    wire low_Eable = 1'b0;
`endif 

// read_data 
wire [31:0] read_data;
wire [31:0] read_shifter = (dff_EXE_result[1:0] == 2'b01) ? read_data >> 8 : (dff_EXE_result[1:0] == 2'b10) ? read_data >> 16 : (dff_EXE_result[1:0] == 2'b11) ? read_data >> 24 : read_data;
wire [23:0] sign_Ex = ((dff_funct3 == `FUNCT3_LB && read_shifter[7] == 1) || (dff_funct3 == `FUNCT3_LH && read_shifter[15] == 1)) ? 24'hFF_FFFF : 24'b0;
wire [31:0] read_result = (dff_funct3 == `FUNCT3_LB || dff_funct3 == `FUNCT3_LBU) ? {sign_Ex, read_shifter[7:0]} : (dff_funct3 == `FUNCT3_LH || dff_funct3 == `FUNCT3_LHU) ? {sign_Ex[23:7], read_shifter[15:0]} : read_shifter;
wire [31:0] result	= (dff_load_I | dff_F_load_I) ? read_result : dff_EXE_result; 

// hidden_map
wire [31:0] hidden_map, hidden_map_inverse;
wire [15:0] EXE_result_16;
wire [31:0] store_data_shifter;
wire [31:0] hidden_map_inverse_shifter;
assign hidden_map_inverse = (funct3 == `FUNCT3_LB || funct3 == `FUNCT3_LBU) ? {24'b0, 8'hFF} : (funct3 == `FUNCT3_LH || funct3 == `FUNCT3_LHU) ? {16'b0, 16'hFFFF} : 32'hFFFF_FFFF;
assign hidden_map_inverse_shifter = (EXE_result[1:0] == 2'b01) ? hidden_map_inverse << 8 : (EXE_result[1:0] == 2'b10) ? hidden_map_inverse << 16 : (EXE_result[1:0] == 2'b11) ? hidden_map_inverse << 24 : hidden_map_inverse;
assign store_data_shifter = (EXE_result[1:0] == 2'b01) ? store_data << 8 : (EXE_result[1:0] == 2'b10) ? store_data << 16 : (EXE_result[1:0] == 2'b11) ? store_data << 24 : store_data;
assign hidden_map = ~hidden_map_inverse_shifter;

assign Addr32 = EXE_result;
`ifdef top_mem
    assign EXE_result_16 = EXE_result[15:0]; 
    assign dcache_low_Eable     = low_Eable;
    assign dcache_WR            = WR;
    assign dcache_hidden_map    = hidden_map;
    assign dcache_EXE_result_16 = EXE_result_16;
    assign dcache_store_data    = store_data_shifter;
    // dcache_read_data is input, so connect to internal signal
    assign read_data            = dcache_read_data;
`else
//dcach
SRAM_wrapper DM1(
    .CLK(clk),
    .RST(rst),
    .CEB(low_Eable),
    .WEB(WR),
    .BWEB(hidden_map),
    .A(EXE_result_16),
    .DI(store_data_shifter),
    .DO(read_data)
);
`endif

//pipeline
// ==============================
// 一級 DFF（含 rst 清零／stall 保持）
// 命名規則：dff_<port(不含 out_)>
// ==============================

// ---------- 輸出對應 ----------
`ifdef test
assign out_instr       = dff_instr;
assign out_R_type_I    = dff_R_type_I;
assign out_I_type_I    = dff_I_type_I;
assign out_S_type_I    = dff_S_type_I;
assign out_B_type_I    = dff_B_type_I;
assign out_J_type_I    = dff_J_type_I;
assign out_F_type_I    = dff_F_type_I;
assign out_CSR_I       = dff_CSR_I;
assign out_PC          = dff_PC;
assign out_funct3      = dff_funct3;
assign out_funct5      = dff_funct5;
assign out_funct7      = dff_funct7;
assign out_load_I      = dff_load_I;
assign out_F_load_I    = dff_F_load_I;
assign out_opcode      = dff_opcode;
assign out_store_I     = dff_store_I;
`endif

assign out_rd          = dff_rd;
assign out_frd         = dff_frd;
assign out_WB_control  = dff_WB_control;
assign out_F_WB_control= dff_F_WB_control;
assign out_result      = result;    //without dff

// ---------- 一級 DFF：rst 清零／stall 保持／正常更新 ----------
always @(posedge clk or posedge rst) begin
    if (rst) begin
    `ifdef test
        dff_instr        <= 32'd0;
        dff_R_type_I     <= 1'b0;
        dff_I_type_I     <= 1'b0;
        dff_S_type_I     <= 1'b0;
        dff_B_type_I     <= 1'b0;
        dff_J_type_I     <= 1'b0;
        dff_F_type_I     <= 1'b0;
        dff_CSR_I        <= 1'b0;
        dff_PC           <= 32'd0;
        dff_funct5       <= 5'd0;
        dff_funct7       <= 7'd0;
        dff_opcode       <= 7'd0;
        dff_store_I      <= 1'b0;
    `endif
		dff_funct3       <= 3'd0;
		dff_EXE_result	<= 32'b0;
        dff_rd           <= 5'd0;
        dff_frd          <= 5'd0;
        dff_WB_control   <= 1'b0;
        dff_F_WB_control <= 1'b0;
		dff_load_I       <= 1'b0;
        dff_F_load_I     <= 1'b0;
    end 
`ifdef cache
`else
    else if (global_stall) begin
    `ifdef test
        dff_instr        <= dff_instr;
        dff_R_type_I     <= dff_R_type_I;
        dff_I_type_I     <= dff_I_type_I;
        dff_S_type_I     <= dff_S_type_I;
        dff_B_type_I     <= dff_B_type_I;
        dff_J_type_I     <= dff_J_type_I;
        dff_F_type_I     <= dff_F_type_I;
        dff_CSR_I        <= dff_CSR_I;
        dff_PC           <= dff_PC;
        dff_funct3       <= dff_funct3;
        dff_funct5       <= dff_funct5;
        dff_funct7       <= dff_funct7;
        dff_load_I       <= dff_load_I;
        dff_F_load_I     <= dff_F_load_I;
        dff_opcode       <= dff_opcode;
        dff_store_I      <= dff_store_I;
    `endif
        dff_rd           <= dff_rd;
        dff_frd          <= dff_frd;
        dff_WB_control   <= dff_WB_control;
        dff_F_WB_control <= dff_F_WB_control;
    end 
`endif
    else begin
    `ifdef test
        // 這裡假設模組內已有對應的組合邏輯輸入：instr/R_type_I/.../store_I
        dff_instr        <= instr;
        dff_R_type_I     <= R_type_I;
        dff_I_type_I     <= I_type_I;
        dff_S_type_I     <= S_type_I;
        dff_B_type_I     <= B_type_I;
        dff_J_type_I     <= J_type_I;
        dff_F_type_I     <= F_type_I;
        dff_CSR_I        <= CSR_I;
        dff_PC           <= PC;
        dff_funct5       <= funct5;
        dff_funct7       <= funct7;
        dff_opcode       <= opcode;
        dff_store_I      <= store_I;
    `endif
		dff_funct3       <= funct3;
		dff_EXE_result	<= EXE_result;
        dff_rd           <= rd;
        dff_frd          <= frd;
        dff_WB_control   <= WB_control;
        dff_F_WB_control <= F_WB_control;
		dff_load_I       <= load_I;
        dff_F_load_I     <= F_load_I;
    end
end
    
endmodule
