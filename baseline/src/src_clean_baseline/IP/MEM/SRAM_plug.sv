module SRAM_plug (
  //******************************
  //			from slave
  //******************************	
    input           clk, rst,
    output  [31:0]  read_data,
    input 	        Read_Enable,
    input   [31:0]  Addr,
    input   [31:0]  Write_data,
    input 	        Write_Enable,
    input   [3:0]   WSTRB,
  //******************************
  //			to SRAM
  //******************************	
    output CEB,
    output WEB,
    output  [13:0] A,
    output  [31:0] DI,
    output  [31:0] BWEB,
    output           miss, hit,
    input   [31:0] DO 

);
wire [7:0] BWEB0, BWEB1, BWEB2, BWEB3;
  //******************************
  //			Signal Define
  //******************************	
    reg out_valid;
    always @(posedge clk or posedge rst) begin
      if(rst)begin
        out_valid <= 1'b0;
      end
      else if(Read_Enable || Write_Enable)begin
        out_valid <= 1'b1;
      end
      else begin
        out_valid <= 1'b0;
      end
    end 
  //******************************
  //			Out Signal
  //******************************	
    assign miss = 1'b0;
    assign hit = (out_valid) ? 1'b1 : 1'b0;
    assign read_data = DO;
    //assign CEB = ~(Read_Enable | Write_Enable);
    assign CEB = 1'd0;
    assign WEB = (Write_Enable) ? 1'd0 : 1'd1;
    assign A = Addr[15:2];
    assign DI = Write_data;
    assign BWEB = {BWEB3, BWEB2, BWEB1, BWEB0};
    assign BWEB3 = (WSTRB[3]) ? 8'd0 : 8'hFF; 
    assign BWEB2 = (WSTRB[2]) ? 8'd0 : 8'hFF;  
    assign BWEB1 = (WSTRB[1]) ? 8'd0 : 8'hFF;  
    assign BWEB0 = (WSTRB[0]) ? 8'd0 : 8'hFF;   
endmodule