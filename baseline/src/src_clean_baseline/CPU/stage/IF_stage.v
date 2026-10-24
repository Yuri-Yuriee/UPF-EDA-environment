//design set
`ifdef top_sim
`else
	`define test
	`define top_mem
	//`include "define_list.v"
	//`define predict
	//`include "SRAM_wrapper.sv"
        `ifdef predict
        `include "predict.v"
    `endif 
`endif
module IF_stage (
    input [31:0] BJ_target,
	input global_stall,
    input interrupt,
    input stall,
    input [31:0] interrupt_mtvec,
    input clk, rst,
    output out_invalid,
    output [31:0] out_instr,
    output [31:0] out_PC,
    input  stall_wfi

    `ifdef CPU_PG
        ,
        input CPU_CG
    `endif 
    `ifdef top_mem
    ,
    output [15:0] icache_PC_counter_16,
    output [31:0] icache_PC_counter,
    input [31:0] icache_instr
    `endif
    `ifdef predict
    ,
        input ID_J_type,
        input ID_B_result,
        output ID_predict_error
    `else
	,
         input BJ_control
    `endif

);
reg  [31:0] dff_PC;
reg  [31:0] PC_counter;
wire [31:0] PC_next; 
wire [31:0] instr;
reg power_on_valid;
reg invalid;
reg power_on_valid_init;
reg power_on_valid_1_beat;
//reg pre_globlal_stall;
reg [31:0] ID_PC;
wire [31:0 ]mcause = 32'd0; 


//TODO TODO
reg pre_interrupt;


//*******************
//    output signal
//*******************
/*
always @(posedge clk or posedge rst) begin
    if(rst)begin
        pre_globlal_stall <= 1'b0;     
    end
    else begin
        pre_globlal_stall <= global_stall;
    end
end*/

`ifdef predict
    wire opcode = instr[6:0];
    wire [31:0] IF_predict_target;
    wire IF_predict_taken;
    wire IF_B_type = (opcode == `B_type) ? 1'b1 : 1'b0;
    wire IF_J_type = (opcode == `J_type || opcode == `I_type_3) ? 1'b1 : 1'b0;
    assign PC_next = (ID_J_type) ? BJ_target : (IF_predict_taken) ? IF_predict_target : PC_counter+4; 
`else
	`ifdef BJ_forward
		wire [31:0] PC_adder;
		wire [31:0] adder_port;
		assign PC_adder = adder_port + 32'd4;
		assign adder_port = (BJ_control) ?  BJ_target : PC_counter;
		assign PC_next = PC_adder;
	`else
		assign PC_next = (BJ_control) ? BJ_target : PC_counter+4;
	`endif
`endif
//assign out_PC = (!global_stall & pre_globlal_stall) ? PC_counter : dff_PC;
assign out_PC = (global_stall) ? ID_PC : dff_PC;


//TODO TODO

// assign out_invalid = (!power_on_valid) ? 1'b1 : 
//                      (interrupt) ? 1'd1 : invalid;

assign out_invalid = (!power_on_valid) ? 1'b1 : 
                     (interrupt) ? 1'd1 : 
                     (pre_interrupt) ? 1'd1 : invalid;



//PC
always @(posedge clk or posedge rst) begin
    if(rst)begin
        PC_counter <= 32'h0000_0000;
    end
    else if(interrupt)begin
        if(interrupt_mtvec[1:0] == 2'd1)begin
            PC_counter <= {interrupt_mtvec[31:2], 2'b00} + (mcause) + 4; // vector
        end
        else begin
            //PC_counter <= {interrupt_mtvec[31:2], 2'b00} + 4; //only direct
            PC_counter <= {interrupt_mtvec[31:2], 2'b00}; //only direct
        end
    end
    else if(stall || global_stall)begin
        PC_counter <= PC_counter;
    end
    else begin
        PC_counter <=  PC_next;
    end
end

//invalid
`ifdef predict
    always @(posedge clk or posedge rst)begin
        if(rst)begin
            invalid <= 1'b0;
        end
        else if(CPU_CG)begin
            invalid <= invalid;
        end
        else if(ID_J_type)begin //re assign
            invalid <= 1'b1;
        end
        else begin
            invalid <= 1'b0;
        end
    end
`else
    always @(posedge clk or posedge rst)begin
        if(rst)begin
            invalid <= 1'b0;
        end
        else if(CPU_CG)begin
            invalid <= invalid;
        end
        else if(stall_wfi)begin
            invalid <= 1'b1;
        end
		else if(global_stall)begin
			invalid <= invalid;
		end
        else if(BJ_control)begin
			`ifdef BJ_forward
				invalid <= 1'b0;
			`else
				invalid <= 1'b1;
			`endif
        end
        else begin
            invalid <= 1'b0;
        end
    end
`endif


// TODOTODO
always @(posedge clk or posedge rst) begin
    if(rst)begin
        pre_interrupt <= 1'b0;
    end
    else begin
        pre_interrupt <= interrupt;
    end
end


//power_on_valid
always @(posedge clk or posedge rst)begin
    if(rst)begin
        power_on_valid_init <= 1'b0;
        power_on_valid <= 1'b0;
        power_on_valid_1_beat <= 1'b0;
    end
    else if(CPU_CG)begin
        power_on_valid_init     <= power_on_valid_init;
        power_on_valid_1_beat   <= power_on_valid_1_beat;
        power_on_valid          <= power_on_valid;
    end
    else begin
        power_on_valid_init <= 1'b1;
        power_on_valid_1_beat <= power_on_valid_init;
        power_on_valid <= power_on_valid_1_beat;
    end
end


//pipeline

always @(posedge clk or posedge rst) begin
    if(rst)begin
        dff_PC <= 32'h0000_0000;
        ID_PC <= 32'h0000_0000;
    end
    // else if(interrupt)begin
    //     dff_PC <= interrupt_mtvec;
    //     ID_PC <= interrupt_mtvec;
    // end
    else if(stall || global_stall)begin
        dff_PC <= dff_PC;
        ID_PC <= ID_PC;
    end
`ifdef BJ_forward
	else if(BJ_control)begin //target forward
		dff_PC <= BJ_target;
        ID_PC <= dff_PC;
	end
`endif
    else begin
        dff_PC <= PC_counter;
        ID_PC <= dff_PC;
    end
end
/*
//suck design : stall mode instr keeper
reg [31:0] pre_instr;
always @(posedge clk or posedge rst)begin
    if(rst)begin
        pre_instr <= 32'b0;
    end
    else begin
        pre_instr <= instr;
    end
end
assign out_instr = (stall) ? pre_instr : instr;
*/
assign out_instr = instr;
//icach
`ifdef top_mem
    assign icache_PC_counter_16 = (BJ_control) ? BJ_target[15:0] : PC_counter[15:0];
    assign icache_PC_counter = (interrupt) ? interrupt_mtvec : (BJ_control) ? BJ_target : PC_counter;
    assign instr = icache_instr;
`else
SRAM_wrapper IM1(
.CLK(clk),
.RST(rst),
.CEB(1'b0),
.WEB(1'b1),
.BWEB(32'b0),
.A(PC_counter[15:0]),
.DI(32'b0),
.DO(instr)
);
`endif  
endmodule
