// setting 
`ifdef top_sim
`else
	`define test
	`define top_mem
	`include "define_list.v"
`endif

module ALU (
    input [31:0] A, B,
    input [6:0] opcode,
    input [2:0] funct3,
    input [6:0] funct7,
    input [31:0] imm, 
    input [31:0] PC,
    output reg [31:0] result
);
////////////////////////////////////////
/////	define
////////////////////////////////////////

//type hard wire 
wire R_type_I =     (opcode == `R_type);
wire I_type_I =     (opcode == `I_type_1 || opcode == `I_type_2 || opcode == `I_type_3);
wire S_type_I =     (opcode == `S_type);
//wire B_type_I =     (opcode == `B_type);
wire U_type_I =     (opcode == `U_type_1 || opcode == `U_type_2);
wire J_type_I =     (opcode == `J_type);
wire F_type_I =     (opcode == `F_type_1 || opcode == `F_type_2 || opcode == `F_type_3);
//wire CSR_I =        (opcode == `CSR);

//comparator
wire [32:0] com_A, com_B; 
wire [31:0] com_result;
wire [32:0] R_type_com_A, R_type_com_B, I_type_com;

//logic
wire [31:0] logic_A, logic_B;
reg [31:0] logic_result;

//MUDIV
wire [65:0] MD_result;
wire [32:0] M_A, M_B;

//adder
wire [31:0] adder_A, adder_B, adder_result, R_type_B;

//shifter
wire [4:0]   shamt;
wire [31:0]  shi_A;
wire [31:0]  shift_result;
wire [6:0]   shift_control7;
wire [31:0]  Ex_sign;
wire [63:0]  Ex_shift;


////////////////////////////////////////
/////	CKT
////////////////////////////////////////

//adder
assign adder_result = adder_A + adder_B;
assign adder_A = (U_type_I || opcode == `I_type_3 || J_type_I) ? PC : A;	//opt
assign adder_B = (R_type_I) ? R_type_B : (opcode == `I_type_3 || J_type_I) ? 32'd4 : imm; //opt
assign R_type_B = ({funct7, funct3} == `SUB) ? ~B + 1 : B;

//comparator
assign com_result = ($signed(com_A) < $signed(com_B)); 


assign com_A = ({funct7, funct3} == `SLT || {funct3, opcode} == `SLTI) ? {A[31] ,A} : {1'b0, A};
assign com_B = (R_type_I) ? R_type_com_B : I_type_com;

assign R_type_com_B = ({funct7, funct3} == `SLT) ? {B[31] ,B} : {1'b0, B};
assign I_type_com   = ({funct3, opcode} == `SLTI) ? {imm[31] ,imm} : {1'b0, imm};

//logic
assign logic_B = (R_type_I) ? B : imm;
assign logic_A = A;
always @(*) begin
    if({funct7, funct3} == `XOR || {funct3, opcode} == `XORI)begin
        logic_result = logic_A ^ logic_B;
    end
    else if({funct7, funct3} == `OR || {funct3, opcode} == `ORI)begin
        logic_result = logic_A | logic_B;
    end
    else begin
        logic_result = logic_A & logic_B;
    end
end


assign M_A = ({funct7, funct3} == `MULH || {funct7, funct3} == `MULHSU) ? {A[31], A} : {1'b0, A};
assign M_B = ({funct7, funct3} == `MULH) ?  {B[31], B} : {1'b0, B};
MuDiv MuDiv(
    .MD_result(MD_result), .A(M_A), .B(M_B)
);

//shifter
assign shamt = (R_type_I) ? B[4:0] : imm[4:0];
assign shi_A = A;
assign shift_control7 = (R_type_I) ? funct7 : imm[11:5];
assign Ex_sign = (shift_control7 == 7'b0100000 && A[31] == 1) ? 32'hFFFF_FFFF : 32'b0; 
assign Ex_shift = {Ex_sign, shi_A} >>> shamt;
assign shift_result = (funct3 == 4'b001) ? shi_A << shamt : Ex_shift[31:0]; 

always @(*) begin
    if(R_type_I)begin
        case ({funct7, funct3})
            `ADD:   result = adder_result;
            `SUB:   result = adder_result;
            `SLL:   result = shift_result;
            `SLT:   result = com_result;    
            `SLTU:  result = com_result;
            `XOR:   result = logic_result;
            `SRL:   result = shift_result;
            `SRA:   result = shift_result;
            `OR:    result = logic_result;
            `AND:   result = logic_result;
            `MUL:   result = MD_result[31:0];
            `MULH:  result = MD_result[63:32];
            `MULHSU:result = MD_result[63:32];
            `MULHU: result = MD_result[63:32];
            default: result = 32'b0;    
        endcase
    end
    else if(I_type_I) begin
        case ({funct3, opcode})
            `LW:    result = adder_result;
            `ADDI:  result = adder_result;
            `SLTI:  result = com_result;
            `SLTIU: result = com_result;
            `XORI:  result = logic_result;
            `ORI:   result = logic_result;
            `ANDI:  result = logic_result;
            `LB:    result = adder_result;
            `JALR:  result = adder_result;
            `LH:    result = adder_result;
            `LBU:   result = adder_result;
            `LHU:   result = adder_result;
			{3'b101, 7'b0010011} : result = shift_result;
			{3'b001, 7'b0010011} : result = shift_result;
            default: result = 32'b0;
        endcase
    end
    else if(S_type_I)begin
        result = adder_result;
    end
    else if(U_type_I)begin
        case (opcode)
            `AUIPC: result = adder_result;
            default: result = imm;  //`LUI
        endcase
    end
    else if(J_type_I)begin
        result = adder_result;  //OPT
    end
    else if(F_type_I) begin
        result = adder_result;
    end
    else begin
        result = 32'b0;
    end
end 
endmodule


module MuDiv (  //can use accumulator OPT
    input  [32:0] A, B,
    output [65:0] MD_result
);
    assign MD_result = $signed(A) * $signed(B);
endmodule


