// `include "./CPU/ALU.v"
// `include "./CPU/FALU.v"
// `include "./CPU/CSR.v"
`ifdef top_sim
`else
	`define test
	`define top_mem
	//`include "define_list.v"
	//`include "SRAM_wrapper.sv"
`endif

module EXE_stage (
    //from ID stage
    input clk, rst,
	input global_stall,
    output interrupt,
    input [31:0] CSR_mip,
    output [31:0] interrupt_mtvec,
    input stall_wfi,
    output EXE_detect_wfi,
    output [31:0] out_mepc,
    input [31:0] rs1_data,
    input [31:0] rs2_data,
    input [4:0] rs1, rs2, rd, frs1, frs2, frd,
    input load_I, F_load_I,
    input [6:0] opcode,
    input [31:0] PC,
    input [31:0] imm,
    input [2:0] funct3,
    input [4:0] funct5,
    input [6:0] funct7, 
    //input stall,
    // forward from MEM, WB stage 
    input [31:0] FW2_MEM_rd_data, FW2_WB_rd_data,
    input [4:0] MEM_rd, WB_rd,
    input [31:0] FW2_MEM_frd_data, 
`ifdef FALU_stall
`else
	input [31:0] FW2_WB_frd_data,
	input [4:0] WB_frd,
`endif
    input [4:0] MEM_frd,

    //test
    `ifdef test
        input [31:0] instr,
        input R_type_I, I_type_I, S_type_I, B_type_I, J_type_I, F_type_I, CSR_I,
    `endif  
    `ifdef test
        output [31:0] out_instr,
        output out_R_type_I, out_I_type_I, out_S_type_I, out_B_type_I, out_J_type_I, out_F_type_I, out_CSR_I,
        output [31:0] out_PC,
        output [4:0] out_funct5,
        output [6:0] out_funct7,
		output [6:0] out_opcode,    
    `endif  

    `ifdef cache
        output [31:0] EXE_I_result,
        output EXE_MEM_use,
    `endif
    output [31:0] out_result, out_store_data,
    output out_load_I, out_F_load_I,
    output [4:0] out_rd, out_frd,
    output [2:0] out_funct3,
    output out_WB_control, out_F_WB_control, out_store_I, out_F_operation
);

wire [31:0] I_result, F_result;
wire [31:0] I_FW2_rs1_data, I_FW2_rs2_data, F_FW2_rs1_data, F_FW2_rs2_data;
//wire [31:0] store_data = (opcode == `S_type || opcode == `F_type_2) ? rs2_data : 32'b0;
wire [31:0] store_data = (opcode == `S_type) ? I_FW2_rs2_data : (opcode == `F_type_2) ? F_FW2_rs2_data : 32'b0;
//decoder (OPT signal)
wire WB_control     = (rd != 5'd0 && (opcode == `R_type || opcode == `I_type_1 || opcode == `I_type_2 || opcode == `I_type_3 || opcode == `U_type_1 || opcode == `U_type_2 || opcode == `J_type || opcode == `CSR)) ? 1'b1 : 1'b0;
wire F_operation	= (opcode == `F_type_3) ? 1'b1 : 1'b0;
wire F_WB_control   = (F_operation || opcode == `F_type_1) ? 1'b1 : 1'b0; 
wire store_I        = (opcode == `S_type || opcode == `F_type_2) ? 1'b1 : 1'b0;
wire wfi;
assign EXE_detect_wfi = wfi;

// F_type_1, F_type_2 go ALU(FLW, FSW)
wire [31:0] CSR_result;
wire [31:0] result = (opcode == `F_type_3) ? F_result : (opcode == `CSR) ? CSR_result : I_result;
`ifdef cache
assign EXE_MEM_use = load_I | store_I | F_load_I;
`endif 
//ALU
ALU u_ALU(
    .A(I_FW2_rs1_data), .B(I_FW2_rs2_data), .opcode(opcode),
    .funct3(funct3), .funct7(funct7),
    .imm(imm), .PC(PC), 
    .result(I_result)
);
//FALU

FALU u_FALU(   
    .A(F_FW2_rs1_data), .B(F_FW2_rs2_data), 
	//.opcode(opcode),
    //.funct3(funct3), 
	.funct5(funct5),
    .F_result(F_result)
);

//CSR
CSR u_CSR(
    .clk(clk), .rst(rst), .opcode(opcode), .rs1(rs1), .rd(rd), .global_stall(global_stall), .EXE_PC(PC), .interrupt(interrupt), .CSR_mip(CSR_mip), .rs1_data(I_FW2_rs1_data),
    .out_mepc(out_mepc), .stall_wfi(stall_wfi), .interrupt_mtvec(interrupt_mtvec),
	//.nop(nop), 
	.imm(imm), .funct3(funct3), 
`ifdef CSR_virtual_space
	.rs1_data(rs1_data), 
`endif
    .out_result(CSR_result), .wfi(wfi)
);

//forward 2

// MEM forward priority > WB forward priority 
wire FW2_MEM_rs1_control  = (rs1 != 5'd0 && rs1 == MEM_rd) ? 1'b1 : 1'b0;
wire FW2_MEM_rs2_control  = (rs2 != 5'd0 && rs2 == MEM_rd) ? 1'b1 : 1'b0;
wire FW2_WB_rs1_control   = (rs1 != 5'd0 && rs1 == WB_rd) ? 1'b1 : 1'b0;
wire FW2_WB_rs2_control   = (rs2 != 5'd0 && rs2 == WB_rd) ? 1'b1 : 1'b0;

wire FW2_MEM_frs1_control  = (frs1 != 5'd0 && frs1 == MEM_frd) ? 1'b1 : 1'b0;
wire FW2_MEM_frs2_control  = (frs2 != 5'd0 && frs2 == MEM_frd) ? 1'b1 : 1'b0;
`ifdef FALU_stall
`else
	wire FW2_WB_frs1_control   = (frs1 != 5'd0 && frs1 == WB_frd) ? 1'b1 : 1'b0;
	wire FW2_WB_frs2_control   = (frs2 != 5'd0 && frs2 == WB_frd) ? 1'b1 : 1'b0;
`endif


assign I_FW2_rs1_data   = (FW2_MEM_rs1_control) ? FW2_MEM_rd_data : (FW2_WB_rs1_control) ? FW2_WB_rd_data : rs1_data;
assign I_FW2_rs2_data   = (FW2_MEM_rs2_control) ? FW2_MEM_rd_data : (FW2_WB_rs2_control) ? FW2_WB_rd_data : rs2_data;
`ifdef FALU_stall
	assign F_FW2_rs1_data   = (FW2_MEM_frs1_control) ? FW2_MEM_frd_data : rs1_data;
	assign F_FW2_rs2_data   = (FW2_MEM_frs2_control) ? FW2_MEM_frd_data : rs2_data;
`else
	assign F_FW2_rs1_data   = (FW2_MEM_frs1_control) ? FW2_MEM_frd_data : (FW2_WB_frs1_control) ? FW2_WB_frd_data : rs1_data;
	assign F_FW2_rs2_data   = (FW2_MEM_frs2_control) ? FW2_MEM_frd_data : (FW2_WB_frs2_control) ? FW2_WB_frd_data : rs2_data;
`endif

//pipeline
// ----------------------
// DFF 宣告
// ----------------------
`ifdef test
    reg [31:0] dff_instr;
    reg        dff_R_type_I, dff_I_type_I, dff_S_type_I, dff_B_type_I, dff_J_type_I, dff_F_type_I, dff_CSR_I;
    reg [31:0] dff_PC;
    reg [4:0]  dff_funct5;
    reg [6:0]  dff_funct7;
`endif

reg [6:0]  dff_opcode;
reg [31:0] dff_result, dff_store_data;
reg        dff_load_I, dff_F_load_I;
reg [4:0]  dff_rd, dff_frd;
reg [2:0]  dff_funct3;
reg dff_WB_control, dff_F_WB_control, dff_store_I;
reg dff_F_operation;
/*
`ifdef FALU_stall
	reg pre_F_type;
	always @(posedge clk or posedge rst) begin
		if(rst)begin
			pre_F_type <= 1'b0
		end
		else begin
			pre_F_type <= (opcode == `F_type_3) ? 1'b1 : 1'b0;
		end	
	end
`endif
*/
 
// ----------------------
// 輸出對應
// ----------------------
/*
`ifdef FALU_stall
	`ifdef test
		assign out_instr    = (opcode == `F_type_3) ? 0 : dff_instr;
		assign out_R_type_I = (opcode == `F_type_3) ? 0 : dff_R_type_I;
		assign out_I_type_I = (opcode == `F_type_3) ? 0 : dff_I_type_I;
		assign out_S_type_I = (opcode == `F_type_3) ? 0 : dff_S_type_I;
		assign out_B_type_I = (opcode == `F_type_3) ? 0 : dff_B_type_I;
		assign out_J_type_I = (opcode == `F_type_3) ? 0 : dff_J_type_I;
		assign out_F_type_I = (opcode == `F_type_3) ? 0 : dff_F_type_I;
		assign out_CSR_I    = (opcode == `F_type_3) ? 0 : dff_CSR_I;
		assign out_PC       = (opcode == `F_type_3) ? 0 : dff_PC;
		assign out_funct5   = (opcode == `F_type_3) ? 0 : dff_funct5;
		assign out_funct7   = (opcode == `F_type_3) ? 0 : dff_funct7;
	`endif

	assign out_result   = (opcode == `F_type_3) ? 0 : dff_result;
	assign out_load_I   = (opcode == `F_type_3) ? 0 : dff_load_I;
	assign out_F_load_I = (opcode == `F_type_3) ? 0 : dff_F_load_I;
	assign out_rd       = (opcode == `F_type_3) ? 0 : dff_rd;
	assign out_frd      = (opcode == `F_type_3) ? 0 : dff_frd;
	assign out_funct3   = (opcode == `F_type_3) ? 0 : dff_funct3;
	assign out_opcode   = (opcode == `F_type_3) ? 0 : dff_opcode;
	assign out_WB_control = (opcode == `F_type_3) ? 0 : dff_WB_control;
	assign out_F_WB_control = (opcode == `F_type_3) ? 0 : dff_F_WB_control;
	assign out_store_I   = (opcode == `F_type_3) ? 0 : dff_store_I;
	assign out_store_data = (opcode == `F_type_3) ? 0 : dff_store_data;
`else
	`ifdef test
		assign out_instr    = dff_instr;
		assign out_R_type_I = dff_R_type_I;
		assign out_I_type_I = dff_I_type_I;
		assign out_S_type_I = dff_S_type_I;
		assign out_B_type_I = dff_B_type_I;
		assign out_J_type_I = dff_J_type_I;
		assign out_F_type_I = dff_F_type_I;
		assign out_CSR_I    = dff_CSR_I;
		assign out_PC       = dff_PC;
		assign out_funct5   = dff_funct5;
		assign out_funct7   = dff_funct7;
	`endif

	assign out_result   = dff_result;
	assign out_load_I   = dff_load_I;
	assign out_F_load_I = dff_F_load_I;
	assign out_rd       = dff_rd;
	assign out_frd      = dff_frd;
	assign out_funct3   = dff_funct3;
	assign out_opcode   = dff_opcode;
	assign out_WB_control = dff_WB_control;
	assign out_F_WB_control = dff_F_WB_control;
	assign out_store_I   = dff_store_I;
	assign out_store_data = dff_store_data;
`endif
*/
	`ifdef test
		assign out_instr    = dff_instr;
		assign out_R_type_I = dff_R_type_I;
		assign out_I_type_I = dff_I_type_I;
		assign out_S_type_I = dff_S_type_I;
		assign out_B_type_I = dff_B_type_I;
		assign out_J_type_I = dff_J_type_I;
		assign out_F_type_I = dff_F_type_I;
		assign out_CSR_I    = dff_CSR_I;
		assign out_PC       = dff_PC;
		assign out_funct5   = dff_funct5;
		assign out_funct7   = dff_funct7;
		assign out_opcode   = dff_opcode;
	`endif

	assign out_result   = dff_result;
	assign out_load_I   = dff_load_I;
	assign out_F_load_I = dff_F_load_I;
	assign out_rd       = dff_rd;
	assign out_frd      = dff_frd;
	assign out_funct3   = dff_funct3;
	assign out_WB_control = dff_WB_control;
	assign out_F_WB_control = dff_F_WB_control;
	assign out_store_I   = dff_store_I;
	assign out_store_data = dff_store_data;
	assign out_F_operation = dff_F_operation;

    `ifdef cache
    assign EXE_I_result = I_result;
    `endif

// ----------------------
// 一級 DFF：rst 高清零，否則鎖住當拍組合結果
// ----------------------
always @(posedge clk or posedge rst) begin
    if (rst) begin
        `ifdef test
            dff_instr    <= 32'd0;
            dff_R_type_I <= 1'b0;
            dff_I_type_I <= 1'b0;
            dff_S_type_I <= 1'b0;
            dff_B_type_I <= 1'b0;
            dff_J_type_I <= 1'b0;
            dff_F_type_I <= 1'b0;
            dff_CSR_I    <= 1'b0;
            dff_PC       <= 32'd0;
            dff_funct5   <= 5'd0;
            dff_funct7   <= 7'd0;
			dff_opcode   <= 7'd0;
        `endif
        dff_result   <= 32'd0;
        dff_load_I   <= 1'b0;
        dff_F_load_I <= 1'b0;
        dff_rd       <= 5'd0;
        dff_frd      <= 5'd0;
        dff_WB_control <= 1'b0;
        dff_F_WB_control <= 1'b0;
        dff_store_I <= 1'b0;
        dff_store_data <= 32'b0;
		dff_F_operation <= 1'b0;
		dff_funct3   <= 3'd0;
    end
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
            dff_funct5       <= dff_funct5;
            dff_funct7       <= dff_funct7;
            dff_opcode       <= dff_opcode;
        `endif
        dff_result       <= dff_result;
        dff_load_I       <= dff_load_I;
        dff_F_load_I     <= dff_F_load_I;
        dff_rd           <= dff_rd;
        dff_frd          <= dff_frd;
        dff_funct3       <= dff_funct3;
        dff_WB_control   <= dff_WB_control;
        dff_F_WB_control <= dff_F_WB_control;
        dff_store_I      <= dff_store_I; 
        dff_store_data  <= dff_store_data;
    end
    else if (stall_wfi) begin
        `ifdef test
            dff_instr    <= 32'd0;
            dff_R_type_I <= 1'b0;
            dff_I_type_I <= 1'b0;
            dff_S_type_I <= 1'b0;
            dff_B_type_I <= 1'b0;
            dff_J_type_I <= 1'b0;
            dff_F_type_I <= 1'b0;
            dff_CSR_I    <= 1'b0;
            dff_PC       <= 32'd0;
            dff_funct5   <= 5'd0;
            dff_funct7   <= 7'd0;
			dff_opcode   <= 7'd0;
        `endif
        dff_result   <= 32'd0;
        dff_load_I   <= 1'b0;
        dff_F_load_I <= 1'b0;
        dff_rd       <= 5'd0;
        dff_frd      <= 5'd0;
        dff_WB_control <= 1'b0;
        dff_F_WB_control <= 1'b0;
        dff_store_I <= 1'b0;
        dff_store_data <= 32'b0;
		dff_F_operation <= 1'b0;
		dff_funct3   <= 3'd0;
    end
    else if (interrupt) begin
        `ifdef test
            dff_instr    <= 32'd0;
            dff_R_type_I <= 1'b0;
            dff_I_type_I <= 1'b0;
            dff_S_type_I <= 1'b0;
            dff_B_type_I <= 1'b0;
            dff_J_type_I <= 1'b0;
            dff_F_type_I <= 1'b0;
            dff_CSR_I    <= 1'b0;
            dff_PC       <= 32'd0;
            dff_funct5   <= 5'd0;
            dff_funct7   <= 7'd0;
			dff_opcode   <= 7'd0;
        `endif
        dff_result   <= 32'd0;
        dff_load_I   <= 1'b0;
        dff_F_load_I <= 1'b0;
        dff_rd       <= 5'd0;
        dff_frd      <= 5'd0;
        dff_WB_control <= 1'b0;
        dff_F_WB_control <= 1'b0;
        dff_store_I <= 1'b0;
        dff_store_data <= 32'b0;
		dff_F_operation <= 1'b0;
		dff_funct3   <= 3'd0;
    end
    else begin
        `ifdef test
            dff_instr    <= instr;
            dff_R_type_I <= R_type_I;
            dff_I_type_I <= I_type_I;
            dff_S_type_I <= S_type_I;
            dff_B_type_I <= B_type_I;
            dff_J_type_I <= J_type_I;
            dff_F_type_I <= F_type_I;
            dff_CSR_I    <= CSR_I;
            dff_PC       <= PC;
            dff_funct5   <= funct5;
            dff_funct7   <= funct7;
			dff_opcode   <= opcode;
        `endif
        dff_result   <= result;
        dff_load_I   <= load_I;
        dff_F_load_I <= F_load_I;
        dff_rd       <= rd;
        dff_frd      <= frd;
        dff_WB_control <= WB_control;
        dff_F_WB_control <= F_WB_control;
        dff_store_I <= store_I;
        dff_store_data <= store_data;
		dff_funct3   <= funct3;
		dff_F_operation <= F_operation;
    end
end

endmodule
