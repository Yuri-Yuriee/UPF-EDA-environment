module ibuf #(
    parameter int deep = 8,
    parameter int deep_bit = 3
) (
    input clk, rst,
    input [29:0] PC,
    input in_Enable,
    input [31:0]in_instr,
    output [31:0]out_instr,
    output hit,
    output miss,
    input [29:0]in_PC
);
reg [31:0] ibuf [deep-1:0] ;
reg [29:0] ibuf_PC [deep-1:0];
reg [deep_bit-1:0] W_index, R_index;
reg [deep-1:0] ibuf_valid;
reg hit_gen;
integer i;
//reg [31:0] dff_instr;
assign out_instr = ibuf[R_index];


always @(posedge clk or posedge rst) begin
    if(rst)begin
        for(i=0;i<deep;i=i+1)begin
            ibuf_PC[i]  <= 30'd0;
            ibuf[i]     <= 32'd0;
            ibuf_valid  <= '0;
        end
    end
    else if(in_Enable)begin
        ibuf_PC[W_index]  <= in_PC;
        ibuf[W_index]     <= in_instr;
        ibuf_valid[W_index] <= 1'd1;
    end
    else begin
        for(i=0;i<deep;i=i+1)begin
            ibuf_PC[i]  <= ibuf_PC[i] ;
            ibuf[i]     <= ibuf[i]  ;
            ibuf_valid[i] <= ibuf_valid[i];
        end
    end
end

/*
always @(*) begin
    for(i=0;i<deep;i=i+1)begin
        if(ibuf_PC[i] == PC && ibuf_valid[i])begin
            hit_gen = 1'd1;
            R_index = i;
        end
        else begin
           hit_gen = 1'd0;
           R_index = '0;
        end
    end
end
*/

always @(*) begin
    if (ibuf_PC[0] == PC && ibuf_valid[0]) begin
        hit_gen = 1'd1;
        R_index = 3'd0;
    end
    else if (ibuf_PC[1] == PC && ibuf_valid[1]) begin
        hit_gen = 1'd1;
        R_index = 3'd1;
    end
    else if (ibuf_PC[2] == PC && ibuf_valid[2]) begin
        hit_gen = 1'd1;
        R_index = 3'd2;
    end
    else if (ibuf_PC[3] == PC && ibuf_valid[3]) begin
        hit_gen = 1'd1;
        R_index = 3'd3;
    end
    else if (ibuf_PC[4] == PC && ibuf_valid[4]) begin
        hit_gen = 1'd1;
        R_index = 3'd4;
    end
    else if (ibuf_PC[5] == PC && ibuf_valid[5]) begin
        hit_gen = 1'd1;
        R_index = 3'd5;
    end
    else if (ibuf_PC[6] == PC && ibuf_valid[6]) begin
        hit_gen = 1'd1;
        R_index = 3'd6;
    end
    else if (ibuf_PC[7] == PC && ibuf_valid[7]) begin
        hit_gen = 1'd1;
        R_index = 3'd7;
    end
    else begin
        hit_gen = 1'd0;
        R_index = 3'd0;
    end
end

assign hit = hit_gen;
assign miss = (!hit) ? 1'd1 : 1'd0;

always @(posedge clk or posedge rst) begin
    if(rst)begin
        W_index <= '0;
        //$display("initial");
    end
    else if(in_Enable)begin
        W_index <= W_index + 1;
        //$display("%h : push", PC);

    end
    else begin
        W_index <= W_index;
        //$display("%h : state", PC);
    end
end

endmodule