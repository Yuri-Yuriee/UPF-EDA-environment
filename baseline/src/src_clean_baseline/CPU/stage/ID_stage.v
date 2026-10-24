`ifdef top_sim
`else
	`define test
	`define top_mem
    `define predict
	`include "define_list.v"
	`include "SRAM_wrapper.sv"
`endif

module ID_stage (
    input clk, rst,
	input global_stall,	//AXI
    output out_MRET,
    input [31:0] in_mepc,
    input stall_wfi,
    input interrupt, 

    //from IF
    input [31:0] in_instr,
    input [31:0] PC,
	input invalid,
    //from WB
    input [31:0] WB_data,
    input [4:0] WB_rd,
    input WB_control,
    input [31:0] F_WB_data,
    input [4:0] WB_frd,
    input F_WB_control,
    //forward data
    input [31:0] FW1_MEM_rd_data,
    //hazard input
    input [4:0] EXE_rd, MEM_rd, EXE_frd,
    input [6:0] EXE_opcode, 
    input EXE_load_I, MEM_load_I, EXE_F_load_I, MEM_F_operation, MEM_F_load_I,
    //test
    `ifdef test
		input [6:0] MEM_opcode,
        output [31:0] out_instr,
        output out_R_type_I, out_I_type_I, out_S_type_I, out_B_type_I, out_J_type_I, out_F_type_I, out_CSR_I,
    `endif
    //output
    output [31:0] out_rs1_data, out_rs2_data,
    output out_load_I, out_F_load_I,
    output [4:0] out_rs1, out_rs2, out_rd, out_frs1, out_frs2, out_frd,
    output [6:0] out_opcode,
    output [31:0] out_PC,
    output [31:0] out_imm,
    output [2:0] out_funct3,
    output [4:0] out_funct5,
    output [6:0] out_funct7, 
    output out_stall,
    output [31:0]out_BJ_target
    `ifdef predict
    ,
        output ID_J_type,
        output ID_B_result,
        input ID_predict_error
    `else
    ,
        output out_BJ_control //floating 
    `endif
    `ifdef CPU_PG
        ,
        input CPU_CG
    `endif 

);
////////////////////////////////////////
/////	define
////////////////////////////////////////
//ID
wire [4:0] rd, rs1, rs2, frs1, frs2, frd;
wire [2:0] funct3;
wire [4:0] funct5;
wire [6:0] funct7;
wire [6:0] opcode;
wire load_I_gen, F_load_I_gen;
wire load_I = load_I_gen;
wire F_load_I = F_load_I_gen;
wire [31:0] instr;

//type hard wire 
wire R_type_I =     (opcode == `R_type);
wire I_type_I =     (opcode == `I_type_1 || opcode == `I_type_2 || opcode == `I_type_3);
wire S_type_I =     (opcode == `S_type);
wire B_type_I =     (opcode == `B_type);
wire U_type_I =     (opcode == `U_type_1 || opcode == `U_type_2);
wire J_type_I =     (opcode == `J_type);
wire F_type_I =     (opcode == `F_type_1 || opcode == `F_type_2 || opcode == `F_type_3);
wire CSR_I =        (opcode == `CSR);

//IMMGEN
reg [31:0] imm_gen;
wire [31:0] imm = imm_gen;
wire [19:0] imm_sign_Ex;
assign imm_sign_Ex = (instr[31]) ? 20'hF_FFFF : 20'd0;

//RF
integer i;
reg [31:0] RF [0:31];
wire [31:0] rs1_data_gen, rs2_data_gen;


//F RF

reg [31:0] F_RF [0:31];
wire [31:0] F_rs1_data_gen, F_rs2_data_gen;
wire [31:0] rs1_data = (opcode == `F_type_3) ? F_rs1_data_gen : rs1_data_gen;
wire [31:0] rs2_data = (opcode == `F_type_2 || opcode == `F_type_3) ? F_rs2_data_gen : rs2_data_gen;


//forword unit1
wire FW1_MEM_rs1_control = (rs1 != 5'd0 && rs1 == MEM_rd) ? 1'b1 : 1'b0; 
wire FW1_MEM_rs2_control = (rs2 != 5'd0 && rs2 == MEM_rd) ? 1'b1 : 1'b0; 


//branch detector //can OPT
wire [31:0] BJ_rs1_data = (FW1_MEM_rs1_control) ? FW1_MEM_rd_data : rs1_data;       //handle forward
wire [31:0] BJ_rs2_data = (FW1_MEM_rs2_control) ? FW1_MEM_rd_data : rs2_data;      //handle forward
wire com_small = (BJ_rs1_data < BJ_rs2_data);
wire com_equal = (BJ_rs1_data == BJ_rs2_data);
wire S_com_small = ($signed(BJ_rs1_data) < $signed(BJ_rs2_data));

reg BJ_control_gen; // when branch taken flush IF
reg [31:0] BJ_target_gen;


//hazard detector
/*
    branch hazard
        load, branch        : stall 2 cycle     case1
        load, X, branch     : stall 1 cycle     case2
        X, branch           : stall 1 cycle     case3
    lw hazard
        load, X             : stall 1 cycle     case4
    F-type load
        FW, FX              : stall 1 cycle     case5
    I hazard
        load, JALR          : stall 2 cycle     case6
        load, X, JALR       : stall 1 cycle     case7
        X, JALR             : stall 1 cycle     case8
*/

wire H_case13   = ((opcode == `I_type_3 || B_type_I) && (EXE_opcode != `NOP) && ((EXE_rd == rs1 && rs1 != 5'd0) || (EXE_rd == rs2 && rs2 != 5'd0))) ? 1'b1 : 1'b0; 
wire H_case2    = ((opcode == `I_type_3 || B_type_I) && MEM_load_I && ((MEM_rd == rs1 && rs1 != 5'd0) || (MEM_rd == rs2 && rs2 != 5'd0))) ? 1'b1 : 1'b0;
wire H_case4    = (EXE_load_I && ((EXE_rd == rs1 && rs1 != 5'd0) || (EXE_rd == rs2 && rs2 != 5'd0))) ? 1'b1 : 1'b0;
wire H_case5    = (EXE_F_load_I && F_type_I && ((EXE_frd == frs1 && EXE_frd != 5'd0) || (EXE_frd == frs2 && frs2 != 5'd0))) ? 1'b1 : 1'b0;
wire H_case68   = ({funct3, opcode} == `JALR && (EXE_opcode != `NOP) && (EXE_rd == rs1 && rs1 != 5'd0)) ? 1'b1 : 1'b0; 
wire H_case7    = ({funct3, opcode} == `JALR && MEM_load_I && (MEM_rd == rs1 && rs1 != 5'd0)) ? 1'b1 : 1'b0;
`ifdef FALU_stall
/*
	wire H_case9	= (EXE_opcode == `F_type_3) ? 1'b1 : 1'b0;
	wire stall_gen = H_case13 | H_case2 | H_case4 | H_case5 | H_case68 | H_case7 | H_case9;
*/
	wire H_case9	= (F_type_I && (MEM_F_operation || MEM_F_load_I)) ? 1'b1 : 1'b0; //can OPT
	wire stall_gen = H_case13 | H_case2 | H_case4 | H_case5 | H_case68 | H_case7 | H_case9;
`else
	wire stall_gen = H_case13 | H_case2 | H_case4 | H_case5 | H_case68 | H_case7;
`endif

//pipeline
reg [31:0]  dff_rs1_data, dff_rs2_data;
reg         dff_load_I, dff_F_load_I;
reg [4:0]   dff_rs1, dff_rs2, dff_rd, dff_frs1, dff_frs2, dff_frd;
reg [6:0]   dff_opcode;
reg [31:0]  dff_PC;
reg [31:0]  dff_imm;
reg [2:0]   dff_funct3;
reg [4:0]   dff_funct5;
reg [6:0]   dff_funct7;
`ifdef test 
    reg [31:0] dff_instr;
    reg dff_R_type_I, dff_I_type_I, dff_S_type_I, dff_B_type_I, dff_J_type_I, dff_F_type_I, dff_CSR_I;
`endif 

// stall
reg pre_stall;
reg [31:0] pre_instr;
wire MRET;
////////////////////////////////////////
/////	CKT
////////////////////////////////////////
assign instr = (pre_stall || global_stall) ? pre_instr : in_instr;
assign opcode = (invalid) ? 7'd0 : instr[6:0];
assign rs1  = (R_type_I || I_type_I || S_type_I || B_type_I || CSR_I || opcode == `F_type_1 || opcode == `F_type_2) ? instr[19:15] : 32'd0;
assign rs2  = (R_type_I || S_type_I || B_type_I) ? instr[24:20] : 32'd0; 
assign rd   = (R_type_I || I_type_I || U_type_I || J_type_I || CSR_I) ? instr[11:7] : 32'd0;
assign load_I_gen   = (opcode == `I_type_1) ? 1'b1 : 1'b0;
assign F_load_I_gen = (opcode == `F_type_1) ? 1'b1 : 1'b0; 

// frs1, frs2 ,frd can OPT
assign frs1 = (opcode == `F_type_3) ? instr[19:15] : 32'd0; 
assign frs2 = (opcode == `F_type_2 || opcode == `F_type_3) ? instr[24:20] : 5'd0;
assign frd  = (opcode == `F_type_1 || opcode == `F_type_3) ? instr[11:7] : 5'd0; 
assign funct3 = instr[14:12];
assign funct5 = instr[31:27];
assign funct7 = instr[31:25];


//MRET
assign MRET = ((opcode==7'b1110011) && (rd ==0) && (funct3 == 0) && (rs1 == 0) && (imm[11:0] == 12'b0011_0000_0010)) ? 1'd1 : 1'd0;
assign out_MRET = MRET;

//IMMGEN
always @(*) begin   //can reduce if level to OPT
    if(I_type_I)begin
        imm_gen = {imm_sign_Ex, instr[31:20]};
    end
    else if (S_type_I) begin
        imm_gen = {imm_sign_Ex, instr[31:25], instr[11:7]};
    end
    else if(B_type_I) begin
        imm_gen = {imm_sign_Ex[18:0], instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
    end
    else if(U_type_I)begin
        imm_gen = {instr[31:12], 12'b0};
    end
    else if (J_type_I) begin
        imm_gen = {imm_sign_Ex[10:0], instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};
    end
    else if(opcode == `F_type_1)begin
        imm_gen = {imm_sign_Ex, instr[31:20]};
    end
    else if (opcode == `F_type_2) begin
        imm_gen = {imm_sign_Ex, instr[31:25], instr[11:7]};
    end
    else if(CSR_I)begin
        imm_gen = {imm_sign_Ex, instr[31:20]};
    end
    else begin
       imm_gen = 32'b0; 
    end
end 

//RF
always @(posedge clk) begin
    if(CPU_CG)begin
    end
    else if(WB_control && WB_rd != 0 && !rst)begin  //TODO TODO
        RF[WB_rd] <= WB_data;
        RF[0] <= 32'b0;
    end
    else begin
        RF[0] <= 32'b0;
    end
end
assign rs1_data_gen = (rs1 == WB_rd && WB_control) ? WB_data : RF[rs1];
assign rs2_data_gen = (rs2 == WB_rd && WB_control) ? WB_data : RF[rs2];

// F RF
always @(posedge clk) begin
    if(CPU_CG)begin
    end
    else if(F_WB_control && WB_frd != 0 && !rst)begin   //TODO TODO
        F_RF[WB_frd] <= F_WB_data;
        F_RF[0] <= 32'b0;
    end
    else begin
        F_RF[0] <= 32'b0;
    end
end
assign F_rs1_data_gen = (frs1 == WB_frd && F_WB_control) ? F_WB_data : F_RF[frs1];
assign F_rs2_data_gen = (frs2 == WB_frd && F_WB_control) ? F_WB_data : F_RF[frs2];





//branch detector //can OPT
always @(*) begin
    if(B_type_I)begin
        BJ_target_gen = imm_gen + PC;
        case (funct3)
            `BEQ: BJ_control_gen = (com_equal) ? 1'b1 : 1'b0;
            `BNE: BJ_control_gen = (!com_equal) ? 1'b1 : 1'b0;
            `BLT: BJ_control_gen = (S_com_small) ? 1'b1 : 1'b0;
            `BGE: BJ_control_gen = (!S_com_small) ? 1'b1 : 1'b0;
            `BLTU:BJ_control_gen = (com_small) ? 1'b1 : 1'b0;
            `BGEU:BJ_control_gen = (!com_small) ? 1'b1 : 1'b0;
            default : BJ_control_gen = 1'b0;
        endcase
    end
    else if({funct3, opcode} == `JALR)begin
        BJ_control_gen = 1'b1;
        BJ_target_gen = BJ_rs1_data + imm_gen;
    end
    else if(J_type_I) begin
        BJ_control_gen = 1'b1;
        BJ_target_gen = PC + imm_gen;
    end
    else if(MRET)begin  //CSR jump
        BJ_control_gen = 1'b1;
        BJ_target_gen = in_mepc;
    end
    else begin
       BJ_control_gen = 1'b0; 
       BJ_target_gen = 32'b0;
    end
end

//pipeline
always @(posedge clk or posedge rst) begin
    if(rst)begin
        dff_rs1_data   <= 32'd0;
        dff_rs2_data   <= 32'd0;
        dff_load_I     <= 1'b0;
        dff_F_load_I   <= 1'b0;
        dff_rs1        <= 5'd0;
        dff_rs2        <= 5'd0;
        dff_rd         <= 5'd0;
        dff_frs1       <= 5'd0;
        dff_frs2       <= 5'd0;
        dff_frd        <= 5'd0;
        dff_opcode     <= 7'd0;
        dff_PC         <= 32'd0;
        dff_imm        <= 32'd0;
        dff_funct3     <= 3'd0;
        dff_funct5     <= 5'd0;
        dff_funct7     <= 7'd0;
        `ifdef test
            dff_instr    <= 32'd0;
            dff_R_type_I <= 1'b0;
            dff_I_type_I <= 1'b0;
            dff_S_type_I <= 1'b0;
            dff_B_type_I <= 1'b0;
            dff_J_type_I <= 1'b0;
            dff_F_type_I <= 1'b0;
            dff_CSR_I    <= 1'b0;
        `endif
    end
    else if(global_stall)begin
		dff_rs1_data   <= dff_rs1_data;
        dff_rs2_data   <= dff_rs2_data;
        dff_load_I     <= dff_load_I;
        dff_F_load_I   <= dff_F_load_I;
        dff_rs1        <= dff_rs1;
        dff_rs2        <= dff_rs2;
        dff_rd         <= dff_rd;
        dff_frs1       <= dff_frs1;
        dff_frs2       <= dff_frs2;
        dff_frd        <= dff_frd;
        dff_opcode     <= dff_opcode;
        dff_PC         <= dff_PC;
        dff_imm        <= dff_imm;
        dff_funct3     <= dff_funct3;
        dff_funct5     <= dff_funct5;
        dff_funct7     <= dff_funct7;
        `ifdef test
            dff_instr    <= dff_instr;
            dff_R_type_I <= dff_R_type_I;
            dff_I_type_I <= dff_I_type_I;
            dff_S_type_I <= dff_S_type_I;
            dff_B_type_I <= dff_B_type_I;
            dff_J_type_I <= dff_J_type_I;
            dff_F_type_I <= dff_F_type_I;
            dff_CSR_I    <= dff_CSR_I;
        `endif
	end
    else if (stall_gen || invalid || interrupt || stall_wfi) begin
        dff_rs1_data   <= 32'd0;
        dff_rs2_data   <= 32'd0;
        dff_load_I     <= 1'b0;
        dff_F_load_I   <= 1'b0;
        dff_rs1        <= 5'd0;
        dff_rs2        <= 5'd0;
        dff_rd         <= 5'd0;
        dff_frs1       <= 5'd0;
        dff_frs2       <= 5'd0;
        dff_frd        <= 5'd0;
        dff_opcode     <= 7'd0;
        dff_PC         <= 32'd0;
        dff_imm        <= 32'd0;
        dff_funct3     <= 3'd0;
        dff_funct5     <= 5'd0;
        dff_funct7     <= 7'd0;
        `ifdef test
            dff_instr    <= 32'd0;
            dff_R_type_I <= 1'b0;
            dff_I_type_I <= 1'b0;
            dff_S_type_I <= 1'b0;
            dff_B_type_I <= 1'b0;
            dff_J_type_I <= 1'b0;
            dff_F_type_I <= 1'b0;
            dff_CSR_I    <= 1'b0;
        `endif
    end
    else begin
        dff_rs1_data   <= rs1_data;
        dff_rs2_data   <= rs2_data;
        dff_load_I     <= load_I;
        dff_F_load_I   <= F_load_I;
        dff_rs1        <= rs1;
        dff_rs2        <= rs2;
        dff_rd         <= rd;
        dff_frs1       <= frs1;
        dff_frs2       <= frs2;
        dff_frd        <= frd;
        dff_opcode     <= opcode;
        dff_PC         <= PC;
        dff_imm        <= imm;
        dff_funct3     <= funct3;
        dff_funct5     <= funct5;
        dff_funct7     <= funct7;
        `ifdef test
            dff_instr    <= instr;
            dff_R_type_I <= R_type_I;
            dff_I_type_I <= I_type_I;
            dff_S_type_I <= S_type_I;
            dff_B_type_I <= B_type_I;
            dff_J_type_I <= J_type_I;
            dff_F_type_I <= F_type_I;
            dff_CSR_I    <= CSR_I;
        `endif
    end
end
assign out_rs1_data   = dff_rs1_data;
assign out_rs2_data   = dff_rs2_data;
assign out_load_I     = dff_load_I;
assign out_F_load_I   = dff_F_load_I;
assign out_rs1        = dff_rs1;
assign out_rs2        = dff_rs2;
assign out_rd         = dff_rd;
assign out_frs1       = dff_frs1;
assign out_frs2       = dff_frs2;
assign out_frd        = dff_frd;
assign out_opcode     = dff_opcode;
assign out_PC         = dff_PC;
assign out_imm        = dff_imm;
assign out_funct3     = dff_funct3;
assign out_funct5     = dff_funct5;
assign out_funct7     = dff_funct7;
`ifdef test
    assign out_instr    = dff_instr;
    assign out_R_type_I = dff_R_type_I;
    assign out_I_type_I = dff_I_type_I;
    assign out_S_type_I = dff_S_type_I;
    assign out_B_type_I = dff_B_type_I;
    assign out_J_type_I = dff_J_type_I;
    assign out_F_type_I = dff_F_type_I;
    assign out_CSR_I    = dff_CSR_I;
`endif

assign out_BJ_control = (!stall_gen && !global_stall) ? BJ_control_gen : 32'b0;
assign out_BJ_target = (!stall_gen && !global_stall) ? BJ_target_gen : 32'b0;
assign out_stall = stall_gen;

// stall
always @(posedge clk or posedge rst)begin
	if(rst)begin
		pre_stall <= 1'b0;
		pre_instr <= 32'b0;
	end
	else if(global_stall)begin
		pre_stall <= pre_stall;
		pre_instr <= pre_instr;	
	end
	else if(stall_gen & pre_stall)begin
		pre_stall <= 1'b1;
		pre_instr <= pre_instr;
	end
	else begin
		pre_stall <= stall_gen;
		pre_instr <= in_instr;	
	end
end

//brach predict
`ifdef predict
    assign ID_J_type = (I_type_I || opcode == `I_type_3) ? 1'b1 : 1'b0;
    assign ID_B_result = (B_type_I && BJ_control_gen) ? 1'b1 : 1'b0; 
`endif

endmodule
