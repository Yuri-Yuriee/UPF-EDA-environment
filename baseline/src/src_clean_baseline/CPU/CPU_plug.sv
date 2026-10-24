`ifdef I_cache
`define power_on_cycles 1
`else
`define power_on_cycles 1
`endif
//`define spyglass
//`define store_boost
//`define test
typedef enum logic[2:0] { 
    P_idle,
    wait_bothR,
    wait_bothW,
    wait_instr,
    wait_Rdata,
    wait_Wdata,
    power_off_M
} P_state;

module CPU_plug (
    input           ACLK,
	input           ARESETn,
    //******************************
    //			Plug 0 interface (to slave_nRWP or SRAM_plug)
    //******************************
        output           req_En_P0,
        output           RW_P0,
        output  [31:0]   Addr_P0,
        output  [2:0]    Size_P0,
        output  [3:0]    Len_P0,
        output  [3:0]    WSTRB_P0,
        output  [1:0]    BURST_P0,
        input          response_P0,
        output  [31:0]   Write_data_P0,
        output           Write_Enable_P0,

        input [31:0]   read_data_P0,
        input          Read_Enable_P0,
        input          WB_P0,

    //******************************
    //			Plug 1 interface
    //******************************
        output           req_En_P1,
        output           RW_P1,
        output  [31:0]   Addr_P1,
        output  [2:0]    Size_P1,
        output  [3:0]    Len_P1,
        output  [3:0]    WSTRB_P1,
        output  [1:0]    BURST_P1,
        input            response_P1,
        output  [31:0]   Write_data_P1,
        output           Write_Enable_P1,

        input [31:0]   read_data_P1,
        input          Read_Enable_P1,
        input           WB_P1,
    //******************************
    //			CPU interface
    //******************************
        input  [31:0]   PC_I,              // Instruction fetch address
        output stall_I,           // I-cache stall
        output [31:0] instr,

        input  [31:0]   Addr_D,        // D-cache address
        input  [31:0]   BWEB_D,
        input           WEB_D,
        input  [31:0]   store_data_D,
        input           CEB_D,
        output [31:0]   read_data_D,
        output    stall_D,            // D-cache stall
        input stall_wfi,
        //cache
        input [31:0]    EXE_I_result,
        input           EXE_MEM_use,
        //cache
        input           RLAST_M0,
        input           RLAST_M1,
        input           BVALID_M1

);

P_state state;
P_state next_state;
reg  [7:0]power_on_counter;
wire power_on_valid;
wire instr_req;
wire CE;
wire RW;
reg [31:0] dff_PC;
reg [31:0] dff_RW;
reg [31:0] dff_CE;
reg [31:0] dff_store_data;
reg [31:0] dff_Addr;
reg [31:0] dff_BWEB;
reg [31:0] dff_instr;
reg [31:0] dff_read_data;
wire Rdata_done;
wire Wdata_done;
wire instr_done;
wire global_stall;
wire [31:0] ibuf_instr;
wire ibuf_hit, ibuf_miss;
wire data_write, dcache_hit, dcache_miss;
reg pre_dcache_hit;
wire [31:0] D_cache_Q;
reg  [1:0] BD_Addr_counter;
reg pre_dcache_miss;
`ifdef I_cache
reg [1:0] PC_Addr_counter;
reg pre_icache_hit;
wire icache_hit;
wire icache_miss;
wire [31:0] icache_instr;
reg pre_stall_I;
reg pre_icache_miss;
reg pre_stall;
assign instr = (icache_hit && !global_stall && !pre_stall) ? icache_instr : dff_instr;
assign instr_req = (icache_miss && power_on_valid && !stall_wfi) ? 1'd1 : 1'd0;
`else
assign instr = (ibuf_hit) ? ibuf_instr : (instr_done) ? read_data_P0 : (state == wait_instr && state == wait_bothR) ? read_data_P0 : dff_instr;
assign instr_req = (ibuf_miss && power_on_valid && !stall_wfi) ? 1'd1 : 1'd0;
`endif
wire data_req;
wire mmio_D;
wire dff_mmio_D;
wire mmio_EXE_I_result;
reg  p1_mmio_q;
reg  p1_rw_q;
reg  [31:0] p1_addr_q;
reg  [31:0] p1_wdata_q;
reg  [31:0] p1_bweb_q;
assign mmio_D = ((Addr_D >= 32'h1001_0000) && (Addr_D <= 32'h1001_03FF)) ||
                ((Addr_D >= 32'h1002_0000) && (Addr_D <= 32'h1002_0200)) ||
                ((Addr_D >= 32'h3000_0000) && (Addr_D <= 32'h3000_0034)) ||
                ((Addr_D >= 32'h3001_0000) && (Addr_D <= 32'h3001_000C)) ||
                ((Addr_D >= 32'h3C00_0000) && (Addr_D <= 32'h3C20_0008));
assign dff_mmio_D = ((dff_Addr >= 32'h1001_0000) && (dff_Addr <= 32'h1001_03FF)) ||
                    ((dff_Addr >= 32'h1002_0000) && (dff_Addr <= 32'h1002_0200)) ||
                    ((dff_Addr >= 32'h3000_0000) && (dff_Addr <= 32'h3000_0034)) ||
                    ((dff_Addr >= 32'h3001_0000) && (dff_Addr <= 32'h3001_000C)) ||
                    ((dff_Addr >= 32'h3C00_0000) && (dff_Addr <= 32'h3C20_0008));
assign mmio_EXE_I_result = ((EXE_I_result >= 32'h1001_0000) && (EXE_I_result <= 32'h1001_03FF)) ||
                           ((EXE_I_result >= 32'h1002_0000) && (EXE_I_result <= 32'h1002_0200)) ||
                           ((EXE_I_result >= 32'h3000_0000) && (EXE_I_result <= 32'h3000_0034)) ||
                           ((EXE_I_result >= 32'h3001_0000) && (EXE_I_result <= 32'h3001_000C)) ||
                           ((EXE_I_result >= 32'h3C00_0000) && (EXE_I_result <= 32'h3C20_0008));
assign data_req  = ((mmio_D || dcache_miss || data_write) && power_on_valid && CE) ? 1'd1 : 1'd0;
assign data_write = (CE && RW) ? 1'b1 : 1'b0;

`ifdef I_cache
assign stall_I =(!power_on_valid) ? 1'd1 :
                (icache_hit) ? 1'd0 : 
                (next_state == P_idle) ? 1'd0 : 
                (state == wait_instr) ? 1'd1 :
                (state == wait_bothR) ? 1'd1 :
                (state == wait_bothW) ? 1'd1 : 
                (state == P_idle && next_state == wait_instr) ? 1'd1 : 
                (state == P_idle && next_state == wait_bothR) ? 1'd1 : 
                (state == P_idle && next_state == wait_bothW) ? 1'd1 : 1'd0;
`else
assign stall_I =(!power_on_valid) ? 1'd1 :
                (ibuf_hit) ? 1'd0 : 
                (next_state == P_idle) ? 1'd0 : 
                (state == wait_instr) ? 1'd1 :
                (state == wait_bothR) ? 1'd1 :
                (state == wait_bothW) ? 1'd1 : 
                (state == P_idle && next_state == wait_instr) ? 1'd1 : 
                (state == P_idle && next_state == wait_bothR) ? 1'd1 : 
                (state == P_idle && next_state == wait_bothW) ? 1'd1 : 1'd0;
`endif
                
assign stall_D =(!power_on_valid) ? 1'd1 : 
                (next_state == P_idle) ? 1'd0 :
                (state == wait_Rdata) ? 1'd1 : 
                (state == wait_Wdata) ? 1'd1 :
                (state == wait_bothR) ? 1'd1 : 
                (state == wait_bothW) ? 1'd1 : 
                (state == P_idle && next_state == wait_Rdata) ? 1'd1 : 
                (state == P_idle && next_state == wait_Wdata) ? 1'd1 :
                (state == P_idle && next_state == wait_bothR) ? 1'd1 :
                (state == P_idle && next_state == wait_bothW) ? 1'd1 : 1'd0;
assign power_on_valid = (power_on_counter>=`power_on_cycles) ? 1'd1 : 1'd0;
 

assign read_data_D =    (p1_mmio_q && Rdata_done && !p1_rw_q) ? read_data_P1 :
                        (!mmio_D && pre_dcache_hit && !RW && state == P_idle) ? D_cache_Q :
                        (!p1_mmio_q && BD_Addr_counter == Addr_D[3:2] && Rdata_done && !RW) ? read_data_P1 : dff_read_data;
assign CE = ~CEB_D;
assign RW = ~WEB_D;
`ifdef I_cache
reg pre_RLAST_M0, pre2_RLAST_M0;
assign instr_done = pre_RLAST_M0;
`else
assign instr_done = Read_Enable_P0;
`endif
//assign Rdata_done = Read_Enable_P1;
assign Rdata_done = RLAST_M1;
assign Wdata_done = WB_P1;
//globle stall
assign global_stall = stall_D | stall_I;
//******************************
//			output signal
//******************************
assign req_En_P0 = (state == P_idle && instr_req) ? 1'd1 : 1'd0;
assign req_En_P1 = (state == P_idle && data_req) ? 1'd1 : 1'd0;


always @(posedge ACLK or negedge ARESETn) begin
    if(!ARESETn)begin
        pre_dcache_miss <= '0;
    end
    else begin
        pre_dcache_miss <= dcache_miss;
    end
end
//master 0
//fix
`ifdef I_cache
assign RW_P0 = 1'd0;
assign Addr_P0 = {dff_PC[31:4], 4'd0};
assign Size_P0 = 3'b010;
assign Len_P0 = 4'd3;
assign WSTRB_P0 = '0;
assign BURST_P0 = 2'd1;

assign Write_data_P0 = '0;
assign Write_Enable_P0 ='0;
`else
assign RW_P0 = 1'd0;
assign Addr_P0 = dff_PC;
assign Size_P0 = 3'b010;
assign Len_P0 = 4'd0;
assign WSTRB_P0 = '0;
assign BURST_P0 = 2'd1;

assign Write_data_P0 = '0;
assign Write_Enable_P0 ='0;
`endif 

//master 1 
//fix

assign RW_P1 = (state == P_idle) ? RW : p1_rw_q;
assign Addr_P1 = (state == P_idle) ? ((RW || mmio_D) ? Addr_D : {Addr_D[31:4], 4'b0}) : ((p1_rw_q || p1_mmio_q) ? p1_addr_q : {p1_addr_q[31:4], 4'b0});
assign Size_P1 = 3'b010;
assign Len_P1 = (state == P_idle) ? ((!RW && CE && !mmio_D) ? 4'd3 : 4'd0) : ((!p1_rw_q && !p1_mmio_q) ? 4'd3 : 4'd0);
assign WSTRB_P1 = (state == P_idle) ? {~BWEB_D[31], ~BWEB_D[23], ~BWEB_D[15], ~BWEB_D[7]} : {~p1_bweb_q[31], ~p1_bweb_q[23], ~p1_bweb_q[15], ~p1_bweb_q[7]};
assign BURST_P1 = 2'd1;

assign Write_Enable_P1 = (state == P_idle && RW) ? 1'd1 :
                         (p1_mmio_q && p1_rw_q && (state == wait_Wdata || state == wait_bothW) && !Wdata_done) ? 1'd1 : 1'd0;
assign Write_data_P1 = (state == P_idle) ? store_data_D : p1_wdata_q;


always @(posedge ACLK or negedge ARESETn) begin
    if(!ARESETn)begin
        p1_mmio_q <= 1'b0;
        p1_rw_q <= 1'b0;
        p1_addr_q <= 32'd0;
        p1_wdata_q <= 32'd0;
        p1_bweb_q <= 32'd0;
    end
    else if(state == P_idle && data_req)begin
        p1_mmio_q <= mmio_D;
        p1_rw_q <= RW;
        p1_addr_q <= Addr_D;
        p1_wdata_q <= store_data_D;
        p1_bweb_q <= BWEB_D;
    end
    else if(next_state == P_idle)begin
        p1_mmio_q <= 1'b0;
        p1_rw_q <= 1'b0;
        p1_addr_q <= p1_addr_q;
        p1_wdata_q <= p1_wdata_q;
        p1_bweb_q <= p1_bweb_q;
    end
    else begin
        p1_mmio_q <= p1_mmio_q;
        p1_rw_q <= p1_rw_q;
        p1_addr_q <= p1_addr_q;
        p1_wdata_q <= p1_wdata_q;
        p1_bweb_q <= p1_bweb_q;
    end
end


always @(posedge ACLK or negedge ARESETn) begin
    if(!ARESETn)begin
        state <= P_idle;
    end
    else begin
        state <= next_state;
    end
end

always @(*) begin
    case (state)
        P_idle : begin
            if(instr_req && data_req && !RW)begin
                next_state = wait_bothR; 
            end
            else if(instr_req && data_req && RW)begin
                `ifdef store_boost
                    next_state = wait_instr;
                `else
                    next_state = wait_bothW;
                `endif
            end
            else if(instr_req && !data_req)begin
                next_state = wait_instr;
            end
            else if(data_req && !RW && !instr_req)begin
            next_state = wait_Rdata; 
            end
            else if(data_req && RW && !instr_req)begin
                `ifdef store_boost
                    next_state = P_idle;
                `else 
                    next_state = wait_Wdata;
                `endif
            end
            else begin
                next_state = P_idle;
            end
        end
        wait_bothR : begin
            if(instr_done && Rdata_done)begin
                next_state = P_idle;
            end
            else if(Rdata_done)begin
                next_state = wait_instr;
            end
            else if(instr_done)begin
                next_state = wait_Rdata;
            end
            else begin
                next_state = wait_bothR;        
            end
        end
        wait_bothW : begin
            if(instr_done && Wdata_done)begin
                next_state = P_idle;
            end
            else if(Wdata_done)begin
                next_state = wait_instr;    
            end
            else if(instr_done)begin
                next_state = wait_Wdata;
            end
            else begin
                next_state = wait_bothW;
            end
        end
        wait_instr : begin
            if(instr_done)begin
               next_state =  P_idle;
            end
            else begin
                next_state = wait_instr;
            end
        end
        wait_Rdata : begin
            if(Rdata_done)begin
               next_state = P_idle;
            end
            else begin
                next_state = wait_Rdata;
            end
        end
        wait_Wdata : begin
            if(Wdata_done)begin
                next_state = P_idle;
            end
            else begin
                next_state = wait_Wdata;
            end
        end
        power_off_M : begin
            next_state = power_off_M;
        end
        default: next_state = power_off_M;
    endcase
end



`ifdef I_cache
I_Cache u_I_Cache (
    .clk            (ACLK),
    .rst            (~ARESETn),
    .global_stall   (global_stall),

    // tag
    .tag_A          (PC_I),
    .tag_En         ((~global_stall || power_on_counter == 1 || pre_RLAST_M0)),
    .hit            (icache_hit),
    .miss           (icache_miss),

    // data
    .data_A         (PC_I),
    .data_RW        (1'd0),
    .data_En        (1'd1),
    .data_BWEB      (32'd0),
    .data_D         (),
    .data_BD        (read_data_P0),
    .backdata_last  (RLAST_M0),
    .backdata_A     ({dff_PC[31:4] ,PC_Addr_counter, 2'd00}),
    .backdata_En    (Read_Enable_P0),
    .data_Q         (icache_instr)
);
// I_cache PC_A counter
always @(posedge ACLK or negedge ARESETn) begin
    if(!ARESETn)begin
        PC_Addr_counter <= 2'b0;
    end
    else if((state == wait_bothR || state == wait_bothW || state == wait_instr) && Read_Enable_P0)begin
        PC_Addr_counter <= PC_Addr_counter + 1;
    end
    else begin
        PC_Addr_counter <= PC_Addr_counter;
    end
end
`else
// ibuf u_ibuf(
//     .clk(ACLK), .rst(~ARESETn),
//     .in_instr(read_data_P0),
//     .PC(dff_PC[31:2]), .in_Enable(instr_done),
//     .out_instr(ibuf_instr), .hit(ibuf_hit), .miss(ibuf_miss),
//     .in_PC(dff_PC[31:2])
// );
`endif

D_Cache u_D_Cache (
    .clk            (ACLK),
    .rst            (~ARESETn),
    .global_stall   (global_stall),

    // tag
    .tag_A          (EXE_I_result),
    .tag_En         (EXE_MEM_use && !mmio_EXE_I_result),
    .hit            (dcache_hit),
    .miss           (dcache_miss),

    // data
    .data_A         (Addr_D),
    .data_RW        (RW),
    .data_En        (!CEB_D && !mmio_D),
    .data_BWEB      (BWEB_D),
    .data_D         (store_data_D),
    .data_BD        (read_data_P1),
    .backdata_last  (RLAST_M1),
    .backdata_A     ({dff_Addr[31:4] ,BD_Addr_counter, 2'd00}),
    .backdata_En    (Read_Enable_P1 && !p1_mmio_q),
    .data_Q         (D_cache_Q)
);
// D_cache BD_A counter
always @(posedge ACLK or negedge ARESETn) begin
    if(!ARESETn)begin
        BD_Addr_counter <= 2'b0;
    end
    else if((state == wait_bothR || state == wait_Rdata) && Read_Enable_P1 && !p1_mmio_q)begin
        BD_Addr_counter <= BD_Addr_counter + 1;
    end
    else begin
        BD_Addr_counter <= BD_Addr_counter;
    end
end

always @(posedge ACLK or negedge ARESETn) begin
    if(!ARESETn)begin
        power_on_counter <= 8'd0;
    end
    else if(power_on_counter == 7'd2)begin
        power_on_counter <= power_on_counter;
    end
    else begin
        power_on_counter <= power_on_counter+1;
    end
end


always @(posedge ACLK or negedge ARESETn) begin
    if(!ARESETn)begin
        pre_dcache_hit <= 1'b0;
        `ifdef I_cache
        pre_icache_miss <= 1'b0;
        pre_icache_hit <= 1'b0;
        `endif 
    end
    else if(state == P_idle)begin
        pre_dcache_hit <= dcache_hit && !mmio_EXE_I_result;
        `ifdef I_cache
        pre_icache_miss <= icache_miss;
        pre_icache_hit <= icache_hit;
        `endif
    end
    else begin
        pre_dcache_hit <= 1'b0;
        `ifdef I_cache
        pre_icache_miss <= 1'b0;
        pre_icache_hit <= 1'b0;
        `endif 
    end
end



reg dff_EXE_I_result;
reg dff_EXE_MEM_use;

//keep input dff
always @(posedge ACLK or negedge ARESETn) begin
    if(!ARESETn)begin
        dff_PC <= 32'd0;
        dff_RW <= 1'd0;
        dff_CE <= 1'd0;
        dff_store_data <= 32'd0;
        dff_Addr <= 32'd0;
        dff_BWEB <= 32'd0;
        dff_EXE_I_result <= 32'b0;
        dff_EXE_MEM_use <= 1'b0;
        
    end
    else if(!global_stall)begin
        dff_PC <= PC_I;
        dff_RW <= ~WEB_D;
        dff_CE <= ~CEB_D;
        dff_store_data <= store_data_D;
        dff_Addr <= Addr_D;
        dff_BWEB <= BWEB_D;
    end
    else begin
        dff_PC <= dff_PC;
        dff_RW <= dff_RW;
        dff_CE <= dff_CE;
        dff_store_data <= dff_store_data;
        dff_Addr <= dff_Addr;
        dff_BWEB <= dff_BWEB;
    end
end
`ifdef I_cache
always @(posedge ACLK or negedge ARESETn) begin
    if(!ARESETn)begin
        dff_instr <= 32'd0;
    end
    else if(icache_hit && !pre_stall && global_stall)begin
        dff_instr <= icache_instr;
    end
    else if(PC_Addr_counter == dff_PC[3:2] && icache_miss && (state == wait_bothR || state == wait_bothW || state == wait_instr) && !pre_RLAST_M0)begin
        dff_instr <= read_data_P0;
    end
    else begin
        dff_instr <= dff_instr;
    end
end
always @(posedge ACLK or negedge ARESETn) begin
    if(!ARESETn)begin
        pre_stall_I <= '0;
        pre_RLAST_M0 <= '0;
        pre2_RLAST_M0 <= '0;
        pre_stall <= '0;
    end
    else begin
        pre_stall <= global_stall;
        pre_stall_I <= stall_I;
        pre_RLAST_M0 <= RLAST_M0;
        pre2_RLAST_M0 <= pre_RLAST_M0;
    end
end
`endif

always @(posedge ACLK or negedge ARESETn) begin
    if(!ARESETn)begin
        dff_read_data <= 32'd0;
    end
    else if(p1_mmio_q && Rdata_done && !p1_rw_q)begin
        dff_read_data <= read_data_P1;
    end
    else if(!mmio_D && pre_dcache_hit && !RW)begin
        dff_read_data <= D_cache_Q;
    end
    else if(!p1_mmio_q && BD_Addr_counter == Addr_D[3:2] && dcache_miss && !RW && (state == wait_bothR || state == wait_Rdata))begin
        dff_read_data <= read_data_P1;
    end
    else begin
        dff_read_data <= dff_read_data;
    end
end


`ifdef test
reg [31:0] MEM_miss_counter;
reg [31:0] MEM_use_counter;
reg [31:0] IF_use_counter;
reg [31:0] IF_miss_counter;

always @(posedge ACLK or negedge ARESETn) begin
    if(!ARESETn)begin
        MEM_miss_counter <= 31'd0;
        MEM_use_counter <= 31'd0;
        IF_miss_counter <= 31'd0;
        IF_use_counter <= 31'd0;
    end
    else if(global_stall)begin
        MEM_miss_counter <= MEM_miss_counter;
        MEM_use_counter <= MEM_use_counter;
        IF_miss_counter <= IF_miss_counter;
        IF_use_counter <= IF_use_counter;
    end
    else begin
        MEM_miss_counter <= MEM_miss_counter    + ((dcache_miss && CE) ? 1'd1 : 1'd0);
        MEM_use_counter <= MEM_use_counter      + ((CE) ? 1'd1 : 1'd0);
        IF_miss_counter <= IF_miss_counter      + ((icache_miss && CE) ? 1'd1 : 1'd0);
        IF_use_counter <= IF_use_counter        + 1;
    end
end
`endif
endmodule


