`ifdef top_sim
`else
	`define test
	`define top_mem
	`include "define_list.v"
	`include "SRAM_wrapper.sv"
	`define CSR_virtual_space
`endif
`define CSR_ALL_SET
`define CSR_LPHP
//`define mie_Read_Only

typedef enum logic[1:0] { 
    CSR_User        = 2'd2,
    CSR_Supervisor  = 2'd1,
    CSR_Hypervisor  = 2'd3,
    CSR_Machine     = 2'd0
} CSR_mode;

typedef enum logic[1:0] { 
    CSR_RW         = 2'd0,
    CSR_Reserved   = 2'd1,
    CSR_RO         = 2'd2,
    CSR_custom     = 2'd3
} CSR_type;

typedef enum logic[1:0] {
    ST_machine,
    ST_supervise,
    ST_user
} ST_priv;

`define FUNCT3_CSRRW    3'b001
`define FUNCT3_CSRRS    3'b010
`define FUNCT3_CSRRC    3'b011
`define FUNCT3_CSRRWI   3'b101
`define FUNCT3_CSRRSI   3'b110
`define FUNCT3_CSRRCI   3'b111
module CSR (
    input clk, rst,
	input global_stall,
    input [31:0] CSR_mip,
    output interrupt,
    output [31:0] interrupt_mtvec,
    output [31:0] out_mepc,
    input  stall_wfi,
    input [31:0] EXE_PC,
    input [6:0] opcode, 
    input [4:0] rs1,
    input [4:0] rd,
    //input nop,	//can use nop to OPT
    input [31:0] imm,
    input [2:0] funct3,
    input [31:0] rs1_data,
    output [31:0] out_result,
    output wfi
);
reg [63:0] instr_counter;
reg [63:0] cycle_counter;
wire [31:0] CSR_VS_out_data;
wire [63:0] counter_result = (imm[1]) ? instr_counter : cycle_counter; 
wire Enable =   ((opcode==7'b111_0011) && (funct3 == 3'b001 || funct3 == 3'b101)) ? 1'd1 :
                ((opcode==7'b111_0011) && (rs1 != 5'd0)) ? 1'b1 : 1'd0; //fix
wire wfi;


assign wfi = ((opcode==7'b111_0011) && (imm[11:0] == {7'b0001000, 5'b00101} && (rs1 == 0) && (funct3 == 0) && (rd == 0))) ? 1'd1 : 1'd0;

//******************************
//          CSR Counter
//******************************
always @(posedge clk or posedge rst) begin
   if(rst)begin
        instr_counter <= 64'd0;
        cycle_counter <= 64'd0;
   end
	else if(global_stall)begin
		instr_counter <= instr_counter;
        cycle_counter <= cycle_counter + 1;
	end 
   else if(opcode != 7'd0) begin
        instr_counter <= instr_counter + 1;
        cycle_counter <= cycle_counter + 1;
   end
   else begin
        instr_counter <= instr_counter;
        cycle_counter <= cycle_counter + 1;
   end 
end


//******************************
//           CSR_virtual_spac
//******************************
CSR_virtual_space CSR_VS (
    .A(imm[11:0]), .rs1_data(rs1_data), .opcode(opcode), .funct3(funct3), .Enable(Enable), 
    .rst(rst), .clk(clk), 
    .CSR_mip(CSR_mip),
    .out_result(CSR_VS_out_data), .EXE_PC(EXE_PC), .interrupt(interrupt), 
    .rs1(rs1), .rd(rd),
    .out_mepc(out_mepc),
    .wfi(wfi), .global_stall(global_stall), .stall_wfi(stall_wfi),
    .interrupt_mtvec(interrupt_mtvec)
);

assign out_result = (funct3 == 3'b010 && imm[7] && (imm[11:0] == 12'b1100_1000_0010 || imm[11:0] == 12'b1100_1000_0000)) ? counter_result[63:32] : 
                    (funct3 == 3'b010 && !imm[7] && (imm[11:0] == 12'b1100_0000_0010 || imm[11:0] == 12'b1100_0000_0000)) ? counter_result[31:0] : CSR_VS_out_data;
endmodule


module CSR_virtual_space (
    input rst, clk,
    input wfi, global_stall,
    input [6:0] opcode,
    input [4:0] rs1, rd, 
    input [11:0] A,
    input [31:0] rs1_data,
    input Enable,
    input [2:0] funct3,
    input [31:0] CSR_mip,
    input [31:0] EXE_PC,       //exe PC 
    output interrupt,
    output [31:0] out_result,
    output [31:0] interrupt_mtvec,
    output [31:0] interrupt_mepc,
    input stall_wfi,
    output [31:0] out_mepc
);
//reg [31:0] CSR_VS [0:8192];
reg interrupt_gen;
reg pre_interrupt_gen;

//*********************
//      define 
//*********************
reg [31:0] mstatus, mie, mtvec, mepc;
wire [31:0] mip;
reg [3:0] mip_reg;
wire [31:0] in_data;
reg [31:0] CSR_VS;
wire MRET;
ST_priv priv;
ST_priv next_priv;
assign in_data =  (funct3 == `FUNCT3_CSRRW) ? rs1_data : 
                (funct3 == `FUNCT3_CSRRS) ? rs1_data | CSR_VS : 
                (funct3 == `FUNCT3_CSRRC) ? ~rs1_data & CSR_VS :  
                (funct3 == `FUNCT3_CSRRWI) ? {27'd0, rs1} : 
                (funct3 == `FUNCT3_CSRRSI) ? {27'd0, rs1} | CSR_VS : 
                (funct3 == `FUNCT3_CSRRCI) ? (~{27'd0, rs1}) & CSR_VS : rs1_data;

assign out_result = CSR_VS;
//*********************
//      output signal
//*********************
assign interrupt_mtvec = mtvec;
assign interrupt_mepc = mepc;
assign mip = {20'b0, CSR_mip[11:4], (CSR_mip[3] | mip_reg[3]), 1'd0, (CSR_mip[1] | mip_reg[1]), (CSR_mip[0] | mip_reg[0])};
assign out_mepc = mepc;
//assign out_MRET = MRET;
assign interrupt = interrupt_gen;
assign MRET = ((opcode==7'b1110011) && (rd ==0) && (funct3 == 0) && (rs1 == 0) && (A == 12'b0011_0000_0010)) ? 1'd1 : 1'd0;


//*********************
//      CSR reg file Read
//*********************`
always @(*) begin
     case (A)
        12'h300 : CSR_VS = mstatus;
        12'h304 : CSR_VS =  mie;
        12'h305 : CSR_VS = mtvec;
        12'h341 : CSR_VS = mepc;
        12'h344 : CSR_VS = mip;
        default: CSR_VS = 32'd0;
    endcase
end


//*********************
//      CSR interrupt reg file
//*********************
// always @(posedge clk) begin     //asyc
always @(posedge clk or posedge rst) begin     //asyc
    if(rst)begin
        `ifdef CSR_ALL_SET
        mstatus[2] <= '0;
        mstatus[6] <= '0;
        mstatus[10:9] <= '0;
        mstatus[31:22] <= '0;
        mie[2] <= '0;
        mie[6] <= '0;
        mie[10] <= '0;
        mie[31:12] <= '0;
        `endif
        mstatus[1:0] <= '0;
        mstatus[5:3] <= '0;
        mstatus[8:7] <= '0;
        mstatus[21:11] <= '0;
        `ifdef CSR_bootSet
        `else
            mstatus[3] <= 1'd1;
            mtvec <= {28'h000_1000, 2'b0, 2'b0};
            `ifdef CSR_LPHP
                mie[11] <= 1'd1;
                mie[9:7] <= 3'b001;
                mie[5:3] <= 3'b000;
                mie[1:0] <= 2'b00;
            `else
                mie[11] <= 1'd1;
                mie[9:7] <= 3'b111;
                mie[5:3] <= 3'b111;
                mie[1:0] <= 2'b11;
            `endif
        `endif
        mepc <= '0;
        mip_reg[3] <= 1'd0;
        mip_reg[1] <= 1'd0;
        mip_reg[0] <= 1'd0;
    end
    else if(wfi)begin
            mepc <= EXE_PC + 4;
    end
    else if(!global_stall)begin
        if(interrupt_gen)begin
            if(!stall_wfi && !pre_interrupt_gen)begin
                mepc <= EXE_PC;                //mepc <= EXE PC
            end
            else begin
            end
            if(priv == ST_machine && !stall_wfi)begin
                mstatus[12:11] <= ST_machine;   //mstatus.MPP
                mstatus[3] <= 1'd0;             //mstatus.MIE
                mstatus[7] <= mstatus[3];       //mstatus.MPIE
            end
            else begin
                //only M mode 
            end
        end
        else if(MRET)begin //fix
                mstatus[12:11] <= ST_machine;   //mstatus.MPP
                mstatus[3] <= mstatus[7];        //mstatus.MIE
        end
        else if(Enable)begin
            case (A)
            12'h300 : begin
                `ifdef CSR_LPHP
                    mstatus[5:3] <= in_data[5:3];
                    mstatus[8:7] <= in_data[8:7];
                    mstatus[15:9] <= in_data[15:9];
                `else
                    mstatus[1:0] <= in_data[1:0];
                    mstatus[5:3] <= in_data[5:3];
                    mstatus[8:7] <= in_data[8:7];
                `endif
            end
            12'h304 : begin
                `ifdef CSR_LPHP
                    mie[11] <= in_data[11];
                    mie[7] <= in_data[7];
                `else
                    mie[11] <= in_data[11];
                    mie[9:7] <= in_data[9:7];
                    mie[5:3] <= in_data[5:3];
                    mie[1:0] <= in_data[1:0];
                `endif
            end
            12'h305 : begin
                `ifdef CSR_LPHP
                `else
                    mtvec <= in_data;
                `endif
            end
            12'h341 : mepc <= in_data;
            12'h344 : begin
                `ifdef CSR_LPHP
                `else
                    mip_reg[3] <= in_data[3];
                    mip_reg[1] <= in_data[1];
                    mip_reg[0] <= in_data[0];
                `endif 
            end
                default: begin
                end
            endcase
        end
        else begin
        end
    end
    else begin
    end
end

`ifdef test
CSR_mode CSR_mode;
CSR_type CSR_type;
always_comb begin
    CSR_mode = A[11:10];
    CSR_type = A[9:8];
end
`endif

//******************************
//     CSR Privileged Unit
//******************************


//mstatus
wire [15:0]     mstatus_Reserved_31_2_15 = mstatus[31:15];
wire [1:0]      mstatus_FS = mstatus[14:13];
wire [12:11]    mstatus_MMP = mstatus[12:11];
wire [2:0]      mstatus_Reserved_10_2_8 = mstatus[10:8];
wire            mstatus_MPIE = mstatus[7];
wire [2:0]      mstatus_Reserved_6_2_4 = mstatus[6:4];
wire            mstatus_MIE = mstatus[3];
wire [2:0]      mstatus_Reserved_2_2_0 = mstatus[2:0];




/*
MEIP = {mode(M,S,U), interrupt_type(E,T,S), interrupt(I), CSR_type(E,P)}
mode :
    M : mechine
    S : supervise 
    U : user
interrupt_type : 
    E : Extaernal
    T : Timer
    S : Software

CSR_type : 
    E : Enable (mask)
    P : Pending (req)
*/
//mie
wire mie_MEIE = mie[11];

wire mie_SEIE = mie[9];
wire mie_UEIE = mie[8];
wire mie_MTIE = mie[7];

wire mie_STIE = mie[5];
wire mie_UTIE = mie[4];
wire mie_MSIE = mie[3];

wire mie_SSIE = mie[1];
wire mie_USIE = mie[0];

//mtvec
wire [29:0] mtvec_Base = mtvec[31:2];
wire [1:0] mtvec_Mode = mtvec[1:0];   //only Direct
/*
mtvec_Mode 
00 Direct
01 Vecotor
*/

//mip 
wire mip_MEIP = mip[11];

wire mip_SEIP = mip[9];
wire mip_UEIP = mip[8];
wire mip_MTIP = mip[7];

wire mip_STIP = mip[5];
wire mip_UTIP = mip[4];
wire mip_MSIP = mip[3];

wire mip_SSIP = mip[1];
wire mip_USIP = mip[0];

always @(posedge clk or posedge rst)begin
    if(rst)begin
        priv <= ST_machine;
    end
    else begin
        priv <= ST_machine; //only m mode
    end
end
// only m mode
always @(*)begin
    next_priv = ST_machine;
end



//interrupt_gen
always @(*) begin
    if(mstatus_MIE && (priv == ST_machine))begin
        if(mip_MEIP & mie_MEIE)begin
            interrupt_gen = 1'd1;
        end
        else if (mip_MSIP & mie_MSIE) begin
            interrupt_gen = 1'd1;
        end
        else if (mip_MTIP & mip_MTIP) begin
            interrupt_gen = 1'd1;
        end
        else if(mip_SEIP & mie_SEIE)begin    //mideleg
            interrupt_gen = 1'd1;
        end
        else if(mip_SSIP & mie_SSIE) begin
            interrupt_gen = 1'd1;
        end
        else if(mip_STIP && mip_SEIP)begin
            interrupt_gen = 1'd1;
        end
        else if(mip_UEIP & mie_UEIE)begin
            interrupt_gen = 1'd1;
        end
        else if(mip_USIP & mie_USIE)begin
            interrupt_gen = 1'd1;
        end
        else if(mip_UTIP & mie_UTIE)begin
            interrupt_gen = 1'd1;
        end
        else begin
            interrupt_gen = 1'd0;
        end
    end
    else begin
        interrupt_gen = 1'b0;
    end
end

always @(posedge clk or posedge rst) begin
    if(rst)begin
        pre_interrupt_gen <= '0;
    end
    else begin
        pre_interrupt_gen <= interrupt_gen;
    end
end

//******************************
//     WFI unit
//******************************
// WFI_unit u_WFI (
//     .clk(clk), .rst(rst),
//     .wfi(wfi),
//     .interrupt(interrupt),
//     .stall_wfi(stall_wfi)
// );
endmodule

