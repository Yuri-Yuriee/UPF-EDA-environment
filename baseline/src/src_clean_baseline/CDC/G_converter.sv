module b_2_gray #(
    parameter bits = 4
) (
    input  [bits-1:0] index,
    output [bits-1:0] G_index
);

genvar gi;
generate
    for (gi = 0; gi < (bits-1); gi = gi + 1) begin
        assign G_index[gi] = index[gi] ^ index[gi+1];
    end
endgenerate

assign G_index[bits-1] = index[bits-1];

endmodule


module gray_2_b #(
    parameter bits = 4
) (
    output  [bits-1:0] index,
    input [bits-1:0] G_index
);
reg [bits-1:0] index_gen;

integer i;
always @(*) begin
    index_gen[bits-1] = 1'd0 - G_index[bits-1]; 
    for(i=(bits-2);i>=0;i=i-1)begin
        index_gen[i] = index_gen[i+1] - G_index[i];
    end
end
assign index = index_gen;


endmodule