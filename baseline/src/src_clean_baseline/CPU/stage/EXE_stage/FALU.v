// setting 
`ifdef top_sim
`else
	`define test
	`define top_mem
	`include "define_list.v"
	`include "SRAM_wrapper.sv"
`endif
// no rounding
// no special case 
// can opt
module FALU (   
    input [31:0] A, B,
    //input [2:0] funct3,
    input [4:0] funct5, 
	//input [6:0] opcode,
    output [31:0] F_result
);
////////////////////////////////////////
/////	define
////////////////////////////////////////
wire A_sign, B_sign, result_sign;
wire [7:0] A_Ex, B_Ex;
wire [22:0] A_S, B_S;
reg [7:0]  result_Ex;
reg [22:0] result_S;

//Ex difference
wire [8:0] Ex_D;
wire [7:0] Ex_shift; 
wire [7:0] Big_Ex;
//wire AB_gap;   
wire A_Ex_Big;

//align
wire [25:0] align_A, align_B;
wire [25:0] align_port;
wire [25:0] aligner_result;

//adder 
wire inverse = (funct5[0]) ? ~ B_sign : B_sign;
wire [27:0] adder_portA, adder_portB;
wire [27:0] adder_result_S;
wire [25:0] adder_result;
wire [27:0] adder_result_US;


////////////////////////////////////////
/////	CKT
////////////////////////////////////////
assign A_sign   = A[31];
assign B_sign   = B[31];
assign A_Ex     = A[30:23];
assign B_Ex     = B[30:23];
assign A_S      = A[22:0];
assign B_S      = B[22:0]; 
assign F_result = {result_sign, result_Ex, result_S};

//Ex difference
assign Ex_D     = {1'b0 ,A_Ex} - {1'b0, B_Ex};    //sign extend avoid overflow
assign A_Ex_Big = ~Ex_D[8];
assign Ex_shift = ({Ex_D[8]}) ? ~Ex_D + 1 : Ex_D;
//assign AB_gap   = (Ex_shift > 22);    //The gap is too big
assign Big_Ex   = (A_Ex_Big) ? A_Ex : B_Ex;

//align
assign align_port      = (A_Ex_Big) ? {1'b1, B_S, 2'b00} : {1'b1, A_S, 2'b00};
assign aligner_result   = align_port >> Ex_shift;


assign align_A          = (A_Ex_Big) ? {1'b1, A_S, 2'b00} : aligner_result;
assign align_B          = (A_Ex_Big) ? aligner_result : {1'b1, B_S, 2'b00};


//adder 
assign adder_portA = (A_sign) ? 	~{2'b00, align_A} +1: {2'b00, align_A};
assign adder_portB = (inverse) ?  	~{2'b00, align_B} +1: {2'b00, align_B};
assign adder_result_S = adder_portA + adder_portB;

assign result_sign = adder_result_S[27];
assign adder_result_US = (adder_result_S[27]) ? ~adder_result_S+1 : adder_result_S;
assign adder_result = (adder_result_US[2:0] == 3'b110 || adder_result_US[1:0] == 2'b11) ? adder_result_US[27:2] + 1 : adder_result_US[27:2];

// result sign
/*
sign = 1:
    A > B:
        A < 0
    B > A:
        B < 0 && add
        B > 0 && minus
*/

// normalize
//OPT with leading zero counter (LZC) or priority encoder
always @(*) begin   
    if (adder_result[24]) begin
        result_Ex = Big_Ex + 1;
        result_S  = adder_result[23:1];
    end
    else if (adder_result[24:23] == 2'b01) begin
        result_Ex = Big_Ex;
        result_S  = adder_result[22:0];
    end
    else if (adder_result[24:22] == 3'b001) begin
        result_Ex = Big_Ex - 1;
        result_S  = adder_result[22:0] << 1;
    end
    else if (adder_result[24:21] == 4'b0001) begin
        result_Ex = Big_Ex - 2;
        result_S  = adder_result[22:0] << 2;
    end
    else if (adder_result[24:20] == 5'b00001) begin
        result_Ex = Big_Ex - 3;
        result_S  = adder_result[22:0] << 3;
    end
    else if (adder_result[24:19] == 6'b000001) begin
        result_Ex = Big_Ex - 4;
        result_S  = adder_result[22:0] << 4;
    end
    else if (adder_result[24:18] == 7'b0000001) begin
        result_Ex = Big_Ex - 5;
        result_S  = adder_result[22:0] << 5;
    end
    else if (adder_result[24:17] == 8'b00000001) begin
        result_Ex = Big_Ex - 6;
        result_S  = adder_result[22:0] << 6;
    end
    else if (adder_result[24:16] == 9'b000000001) begin
        result_Ex = Big_Ex - 7;
        result_S  = adder_result[22:0] << 7;
    end
    else if (adder_result[24:15] == 10'b0000000001) begin
        result_Ex = Big_Ex - 8;
        result_S  = adder_result[22:0] << 8;
    end
    else if (adder_result[24:14] == 11'b00000000001) begin
        result_Ex = Big_Ex - 9;
        result_S  = adder_result[22:0] << 9;
    end
    else if (adder_result[24:13] == 12'b000000000001) begin
        result_Ex = Big_Ex - 10;
        result_S  = adder_result[22:0] << 10;
    end
    else if (adder_result[24:12] == 13'b0000000000001) begin
        result_Ex = Big_Ex - 11;
        result_S  = adder_result[22:0] << 11;
    end
    else if (adder_result[24:11] == 14'b00000000000001) begin
        result_Ex = Big_Ex - 12;
        result_S  = adder_result[22:0] << 12;
    end
    else if (adder_result[24:10] == 15'b000000000000001) begin
        result_Ex = Big_Ex - 13;
        result_S  = adder_result[22:0] << 13;
    end
    else if (adder_result[24:9] == 16'b0000000000000001) begin
        result_Ex = Big_Ex - 14;
        result_S  = adder_result[22:0] << 14;
    end
    else if (adder_result[24:8] == 17'b00000000000000001) begin
        result_Ex = Big_Ex - 15;
        result_S  = adder_result[22:0] << 15;
    end
    else if (adder_result[24:7] == 18'b000000000000000001) begin
        result_Ex = Big_Ex - 16;
        result_S  = adder_result[22:0] << 16;
    end
    else if (adder_result[24:6] == 19'b0000000000000000001) begin
        result_Ex = Big_Ex - 17;
        result_S  = adder_result[22:0] << 17;
    end
    else if (adder_result[24:5] == 20'b00000000000000000001) begin
        result_Ex = Big_Ex - 18;
        result_S  = adder_result[22:0] << 18;
    end
    else if (adder_result[24:4] == 21'b000000000000000000001) begin
        result_Ex = Big_Ex - 19;
        result_S  = adder_result[22:0] << 19;
    end
    else if (adder_result[24:3] == 22'b0000000000000000000001) begin
        result_Ex = Big_Ex - 20;
        result_S  = adder_result[22:0] << 20;
    end
    else if (adder_result[24:2] == 23'b00000000000000000000001) begin
        result_Ex = Big_Ex - 21;
        result_S  = adder_result[22:0] << 21;
    end
    else if (adder_result[24:1] == 24'b000000000000000000000001) begin
        result_Ex = Big_Ex - 22;
        result_S  = adder_result[22:0] << 22;
    end
    else if (adder_result[24:0] == 25'b0000000000000000000000001) begin
        result_Ex = Big_Ex - 23;
        result_S  = adder_result[22:0] << 23;
    end
    else begin
        result_Ex = 0;
        result_S  = 0;
    end

end
endmodule
