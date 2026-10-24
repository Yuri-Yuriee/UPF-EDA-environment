`define reset_count_bit 4
module I_Cache(
    input clk, rst, global_stall,
    // tag
    input   [31:0] tag_A,
    input   tag_En,
    output  hit,
    output  miss,
    // data
    input   [31:0] data_A,
    input   data_RW,
    input   data_En,
    input   [31:0] data_BWEB,
    input   [31:0] data_D,
    input   [31:0] data_BD,
    input   backdata_last,
    input   [31:0] backdata_A,
    input   backdata_En,
    output  [31:0] data_Q

);
wire [31:0]     tag_in, tag_out0, tag_out1;
reg  [63:0]     BWEB_up, BWEB_down; 
wire [63:0]     data_in;
wire [31:0]     data_out_array  [1:0][3:0];
wire            tag_RW;
wire            tag_En0, tag_En1;
wire            data_En_H0, data_En_L0;
wire            data_En_H1, data_En_L1;
wire [4:0]      data_index, tag_index;
//======//
//  keep
//======//

// input

reg            pre_tag_En;
reg   [31:0]   pre_data_A;
//output
reg  [31:0] pre_data_Q;
reg         pre_hit;
reg         pre_miss;


typedef enum logic[1:0] { 
    CT_idle,
    CT_miss,
    CT_done
} Cache_state;
typedef struct packed {
    logic            valid;
    logic            dirty;
    logic [6:0]      use_cnt;
    logic [22:0]     tag;
} tag_data;

typedef struct packed {
    logic [4:0]     index;
    logic [22:0]    tag;
    logic [1:0]     block_offset;
    logic [1:0]     B_offset;
} C_Addr;

tag_data tag_data_out0, tag_data_out1, tag_data_in;
C_Addr T_Addr, D_Addr, BD_Addr;

Cache_state state, next_state;

//control
reg hit_set_index_gen;
reg hit_gen;
reg pre_stall;
wire local_stall;
wire stall;
wire data_RW_HL;
wire [1:0] block_offset_select;

//indata
wire [31:0] data_select;
logic [31:0] data_mix_gen;
reg [63:0] data_in_gen;


//valid array
reg [31:0] valid_array [1:0];
reg tag_valid_out1;
reg tag_valid_out0;

//RLU
integer i;
reg [`reset_count_bit:0] reset_counter;
reg [31:0] used_array [1:0];
reg push_index_gen;
reg pre_push_index;
wire push_index = (pre_stall) ? pre_push_index : push_index_gen;
reg [31:0]  data_Q_gen;



/*
wire [22:0]     tag0, tag1;
wire            valid0, valid1;
wire            dirty0, dirty1;
wire            use0, use1;
wire            use_cnt0, use_cnt1;
*/
//*********************************************
//                  structure
//*********************************************

    //outside
    assign D_Addr.tag             = data_A[31:9];
    assign D_Addr.B_offset        = data_A[1:0];
    assign D_Addr.block_offset    = data_A[3:2];
    assign D_Addr.index           = data_A[8:4];

    assign BD_Addr.block_offset    = backdata_A[3:2];
    assign BD_Addr.index           = backdata_A[8:4];
    assign BD_Addr.tag             = backdata_A[31:9];
    //tag data
    assign tag_data_out0.valid = tag_valid_out0;
    assign tag_data_out1.valid = tag_valid_out1;

    assign tag_data_out0.dirty = tag_out0[30];
    assign tag_data_out1.dirty = tag_out1[30];

    assign tag_data_out0.use_cnt = tag_out0[29:23];
    assign tag_data_out1.use_cnt = tag_out1[29:23];

    assign tag_data_out0.tag = tag_out0[22:0];
    assign tag_data_out1.tag = tag_out1[22:0];

    assign tag_in[31]       = tag_data_in.valid;
    assign tag_in[30]       = tag_data_in.dirty;
    assign tag_in[29:23]    = tag_data_in.use_cnt;
    assign tag_in[22:0]     = tag_data_in.tag;

    assign tag_data_in.valid    = 1;
    assign tag_data_in.tag      = D_Addr.tag;
    assign tag_data_in.dirty    = data_RW; 
    assign tag_data_in.use_cnt  = '0; 
    
    //tag
    assign T_Addr.tag             = tag_A[31:9];
    assign T_Addr.B_offset        = tag_A[1:0];
    assign T_Addr.block_offset    = tag_A[3:2];
    assign T_Addr.index           = tag_A[8:4];

//*********************************************
//                  output
//*********************************************   
wire [1:0] pre_D_Addr_block_offset = pre_data_A[3:2];
wire [22:0] pre_D_Addr_tag = pre_data_A[31:9];
assign data_Q           = data_out_array[hit_set_index_gen][pre_D_Addr_block_offset];

//*********************************************
//                  FSM
//*********************************************
always @(posedge clk or posedge rst)begin
    if(rst)begin
        state <= CT_idle;
    end
    else begin
        state <= next_state;
    end
end
always @(*) begin
    case (state)
        CT_idle : if(miss && !data_RW && (global_stall && !pre_stall))begin     //write no allocate
            next_state = CT_miss;
        end
        else begin
            next_state = CT_idle;
        end
        CT_miss : if(backdata_last)begin
            next_state = CT_idle;
        end
        else begin
            next_state = CT_miss;
        end
        CT_done : next_state = CT_idle;
        default : next_state = CT_idle;
    endcase
end

always @(posedge clk or posedge rst) begin
    if(rst)begin
        pre_stall <= 1'b0;
    end
    else begin
        pre_stall <= stall;
    end
end

//======//
//  LRU
//======//
//used_array reset counter 
always @(posedge clk or posedge rst) begin
    if(rst)begin
        reset_counter <= '0;
    end
    else if(stall)begin
        reset_counter <= reset_counter;
    end
    else begin
        reset_counter <= reset_counter + 1;
    end
end

//used_array
always @(posedge clk or posedge rst) begin
    if(rst)begin
        used_array[0] <= '0;
        used_array[1] <= '0;
    end
    else if(&reset_counter == 1)begin
        used_array[0] <= '0;
        used_array[1] <= '0;
    end
    else if(hit_gen)begin
        used_array[hit_set_index_gen][D_Addr.index] <= 1'b1;
    end
    else begin 
        used_array[0] <= used_array[0];
        used_array[1] <= used_array[1];
    end
end

//push_index;
always @(*)begin
    if(tag_data_out0.valid == 0)begin
        push_index_gen = '0; 
    end
    else if(tag_data_out1.valid == 0)begin
        push_index_gen = 1'b1; 
    end
    else if( used_array[0][D_Addr.index] ^ used_array[1][D_Addr.index] == 1)begin
        push_index_gen = pre_push_index + 1;    //next index
    end
    else begin
        if(used_array[0][D_Addr.index] == 0)begin
            push_index_gen = '0;
        end
        else begin
            push_index_gen = 1'b1;
        end
    end
end

//pre_push_index
always @(posedge clk or posedge rst) begin
    if(rst)begin
        pre_push_index <= '0;
    end
    else if(state == CT_idle && miss && !data_RW)begin
        pre_push_index <= push_index_gen;
    end
    else begin
        pre_push_index <= pre_push_index;
    end
end


//tag valid out

//used_array
always @(posedge clk or posedge rst) begin
    if(rst)begin
        valid_array[0] <= '0;
        valid_array[1] <= '0;
    end
    else if(tag_En0 && tag_RW)begin
        valid_array[0][tag_index] <= 1'b1;
    end
    else if(tag_En1 && tag_RW)begin
       valid_array[1][tag_index] <= 1'b1; 
    end
    else begin 
        valid_array[0] <= valid_array[0];
        valid_array[1] <= valid_array[1];
    end
end

always @(posedge clk or posedge rst) begin
    if(rst)begin
        tag_valid_out0 <= '0;
    end
    else if(!tag_RW && tag_En0)begin
        tag_valid_out0 <= valid_array[0][tag_index];
    end
    else begin
        tag_valid_out0 <= '0;
    end
end

always @(posedge clk or posedge rst) begin
    if(rst)begin
        tag_valid_out1 <= '0;
    end
    else if(!tag_RW && tag_En1)begin
        tag_valid_out1 <= valid_array[1][tag_index];
    end
    else begin
        tag_valid_out1 <= '0;
    end
end

//*********************************************
//             globla control signal          
//*********************************************


assign miss = (data_En && !hit && pre_tag_En) ? 1'b1 : 1'b0;
assign stall = global_stall;


//comparator
always @(*) begin
    if(tag_data_out0.valid && (tag_data_out0.tag == pre_D_Addr_tag) && data_En)begin
        hit_set_index_gen = 1'b0;
        hit_gen = 1'b1;
    end
    else if(tag_data_out1.valid && (tag_data_out1.tag == pre_D_Addr_tag) && data_En)begin
        hit_set_index_gen = 1'b1;
        hit_gen = 1'b1;
    end
    else begin
        hit_set_index_gen = 1'b0;
        hit_gen = 1'b0;
    end
end



//*********************************************
//                  hard Macro control
//*********************************************
//Data cache control
assign data_En_H0 =     ((state == CT_done)) ? 1'd1 : 
                        ((state == CT_idle) && (data_En)) ? 1'b1 :    //hit
                        ((state == CT_miss) && (BD_Addr.block_offset[1] == 1'b1) && (backdata_En & push_index==1'b0)) ? 1'b1 : 1'b0;                //load cache


assign data_En_L0 =     ((state == CT_done)) ? 1'd1 :
                        ((state == CT_idle) && ( data_En)) ? 1'b1 :    //hit
                        ((state == CT_miss) && (BD_Addr.block_offset[1] == 1'b0) && (backdata_En & push_index==1'b0)) ? 1'b1 : 1'b0;                //load cache


assign data_En_H1 =     ((state == CT_done)) ? 1'd1 :
                        ((state == CT_idle) && ( data_En)) ? 1'b1 :    //hit
                        ((state == CT_miss) && (BD_Addr.block_offset[1] == 1'b1) && (backdata_En & push_index==1'b1)) ? 1'b1 : 1'b0;                //load cache


assign data_En_L1 =     ((state == CT_done)) ? 1'd1 :
                        ((state == CT_idle) && (data_En)) ? 1'b1 :    //hit
                        ((state == CT_miss) && (BD_Addr.block_offset[1] == 1'b0) && (backdata_En & push_index==1'b1)) ? 1'b1 : 1'b0;                //load cache


assign data_RW_HL =     ((state == CT_idle) && (hit_gen & data_En)) ? data_RW :                     //hit
                        ((state == CT_miss) && (backdata_En)) ? 1'b1 : 1'b0;     //load cache

assign data_in =        data_in_gen;

assign data_select =    (state == CT_idle) ? data_D : 
                        (state == CT_miss && data_RW && D_Addr.block_offset == BD_Addr.block_offset) ? data_mix_gen : data_BD;




assign block_offset_select  = ((state == CT_idle && miss) || state == CT_miss) ? BD_Addr.block_offset : D_Addr.block_offset;
// back data mix with write data
integer gi;

always_comb begin
    for(gi=0;gi<4;gi=gi+1)begin
        if(data_BWEB[gi*8+1]==0)begin
            data_mix_gen[gi*8 +: 8] = data_D[gi*8 +: 8];
        end
        else begin
            data_mix_gen[gi*8 +: 8] = data_BD[gi*8 +: 8];
        end
    end
end



//data_in_gen
always @(*)begin
    case (block_offset_select)
        /*2'b00 : begin
            data_in_gen  = {32'h0, BD_data};
        end*/
        2'b01 : begin
            data_in_gen     = {data_select, 32'h0};
        end
        2'b10 : begin
            data_in_gen     = {32'h0, data_select};
        end
        2'b11 : begin
            data_in_gen     = {data_select, 32'h0};
        end
        default: begin
            data_in_gen     = {32'h0, data_select};
        end  
    endcase
end

wire [31:0] data_BWEB_select;
assign data_BWEB_select = (data_RW) ? data_BWEB : 32'b0;

//BWEB
always @(*) begin
    case (block_offset_select)
        /*2'b00 : begin
            BWEB_down  = {32'hFFFF_FFFF, data_BWEB};
            BWEB_up    = 64'hFFFF_FFFF_FFFF_FFFF;
        end*/
        2'b01 : begin
            BWEB_down  = {data_BWEB_select, 32'hFFFF_FFFF};
            BWEB_up    = 64'hFFFF_FFFF_FFFF_FFFF;
        end
        2'b10 : begin
            BWEB_down  = 64'hFFFF_FFFF_FFFF_FFFF;
            BWEB_up    = {32'hFFFF_FFFF, data_BWEB_select};
        end
        2'b11 : begin
            BWEB_down  = 64'hFFFF_FFFF_FFFF_FFFF;
            BWEB_up    = {data_BWEB_select, 32'hFFFF_FFFF};
        end
        default: begin
            BWEB_down  = {32'hFFFF_FFFF, data_BWEB_select};
            BWEB_up    = 64'hFFFF_FFFF_FFFF_FFFF;
        end 
    endcase
end



//Tag cache control
assign tag_En0 =        ((!global_stall)) ? 1'd1 :
                        (pre_stall) ? 1'b0 : 
                        (state == CT_idle && !miss && tag_En && !global_stall) ? 1'b1 : 
                        (state == CT_idle && miss && (push_index==0 || data_RW)) ? 1'b1 : 1'b0;

assign tag_En1 =        ((!global_stall)) ? 1'd1 : 
                        (pre_stall) ? 1'b0 : 
                        (state == CT_idle && !miss && tag_En && !global_stall) ? 1'b1 : 
                        (state == CT_idle && miss && (push_index==1 || data_RW)) ? 1'b1 : 1'd0;
                    

assign tag_RW =         (!global_stall) ? 1'd0 : (state == CT_idle && !miss) ? 1'b0 : (state == CT_idle && miss && !data_RW) ? 1'b1 : 1'b0;

assign tag_index =      (state == CT_idle && miss && !data_RW && !pre_stall) ? BD_Addr.index : T_Addr.index;

assign data_index =     ((state == CT_idle && miss && !data_RW && !pre_stall) || state == CT_miss) ? BD_Addr.index : D_Addr.index;



//*********************************************
//                 Keep data
//*********************************************
//input keep
always @(posedge clk or posedge rst) begin
    if(rst)begin
        pre_tag_En <= '0;
        pre_data_A <= '0;
    end
    else if(stall)begin       
        pre_tag_En        <=  pre_tag_En;          
        pre_data_A        <=  pre_data_A;                                       
    end
    else begin      
        pre_tag_En        <=  tag_En;          
        pre_data_A        <=  data_A;                                 
    end
end


//output keep
always @(posedge clk or posedge rst) begin
    if(rst)begin
        pre_data_Q <= '0;
        pre_miss <= '0;
    end
    else if(stall)begin
        pre_data_Q  <= pre_data_Q ;
        pre_miss    <= pre_miss   ;
    end
    else begin
        pre_data_Q  <= data_Q ;
        pre_miss    <= miss   ;
    end
end


always @(posedge clk or posedge rst) begin
    if(rst)begin
        pre_hit <= 1'b0;
    end
    else if(pre_stall)begin
        pre_hit <= pre_hit;
    end
    else begin
        pre_hit <= hit_gen;
    end
end
assign hit = (pre_stall) ? pre_hit : hit_gen;

//*********************************************
//                 hard macro
//*********************************************
`ifdef Dual_MEM 
    //set 0
    //EXE stage
    FILL_IN_CELL_SRAM_001 tag_sram0(
        .CLK(clk), .A(tag_index), .CEB(!tag_En0), .WEB(!tag_RW), .BWEB(32'b0), .D(tag_in), .Q(tag_out0),
        .SLP(1'b0),
        .DSLP(1'b0),
        .SD(1'b0),
        .RTSEL(2'b01),
        .WTSEL(2'b00),
        .BIST(1'b0)
    );
    //MEM stage
    FILL_IN_CELL_SRAM_002 data_sram_H0 (
        .CLK(clk), .A(data_index), .CEB(!data_En_H0), .WEB(!data_RW_HL), .BWEB(BWEB_up), .D(data_in), .Q({data_out_array[0][3], data_out_array[0][2]}),
        .SLP(1'b0),
        .DSLP(1'b0),
        .SD(1'b0),
        .RTSEL(2'b01),
        .WTSEL(2'b00),
        .BIST(1'b0)
    );

    FILL_IN_CELL_SRAM_002 data_sram_L0 (
        .CLK(clk), .A(data_index), .CEB(!data_En_L0), .WEB(!data_RW_HL), .BWEB(BWEB_down), .D(data_in), .Q({data_out_array[0][1], data_out_array[0][0]}),
        .SLP(1'b0),
        .DSLP(1'b0),
        .SD(1'b0),
        .RTSEL(2'b01),
        .WTSEL(2'b00),
        .BIST(1'b0)
    );
    //set0
    //EXE stage
    FILL_IN_CELL_SRAM_001 tag_sram1(
        .CLK(clk), .A(tag_index), .CEB(!tag_En1), .WEB(!tag_RW), .BWEB(32'b0), .D(tag_in), .Q(tag_out1),
        .SLP(1'b0),
        .DSLP(1'b0),
        .SD(1'b0),
        .RTSEL(2'b01),
        .WTSEL(2'b00),
        .BIST(1'b0)
    );

    //MEM stage
    FILL_IN_CELL_SRAM_002 data_sram_H1 (
        .CLK(clk), .A(data_index), .CEB(!data_En_H1), .WEB(!data_RW_HL), .BWEB(BWEB_up), .D(data_in), .Q({data_out_array[1][3], data_out_array[1][2]}),
        .SLP(1'b0),
        .DSLP(1'b0),
        .SD(1'b0),
        .RTSEL(2'b01),
        .WTSEL(2'b00),
        .BIST(1'b0)
    );

    FILL_IN_CELL_SRAM_002 data_sram_L1 (
        .CLK(clk), .A(data_index), .CEB(!data_En_L1), .WEB(!data_RW_HL), .BWEB(BWEB_down), .D(data_in), .Q({data_out_array[1][1], data_out_array[1][0]}),
        .SLP(1'b0),
        .DSLP(1'b0),
        .SD(1'b0),
        .RTSEL(2'b01),
        .WTSEL(2'b00),
        .BIST(1'b0)
    );
`else
    //set 0
    //EXE stage
    FILL_IN_CELL_SRAM_004 tag_sram0(
        .CLK(clk), .A(tag_index), .CEB(!tag_En0), .WEB(!tag_RW), .BWEB(32'b0), .D(tag_in), .Q(tag_out0),
        .SLP(1'b0),
        .DSLP(1'b0),
        .SD(1'b0),
        .RTSEL(2'b01),
        .WTSEL(2'b01),
    );
    //MEM stage
    FILL_IN_CELL_SRAM_005 data_sram_H0 (
        .CLK(clk), .A(data_index), .CEB(!data_En_H0), .WEB(!data_RW_HL), .BWEB(BWEB_up), .D(data_in), .Q({data_out_array[0][3], data_out_array[0][2]}),
        .SLP(1'b0),
        .DSLP(1'b0),
        .SD(1'b0),
        .RTSEL(2'b01),
        .WTSEL(2'b01),
    );

    FILL_IN_CELL_SRAM_005 data_sram_L0 (
        .CLK(clk), .A(data_index), .CEB(!data_En_L0), .WEB(!data_RW_HL), .BWEB(BWEB_down), .D(data_in), .Q({data_out_array[0][1], data_out_array[0][0]}),
        .SLP(1'b0),
        .DSLP(1'b0),
        .SD(1'b0),
        .RTSEL(2'b01),
    );
    //set0
    //EXE stage
    FILL_IN_CELL_SRAM_004 tag_sram1(
        .CLK(clk), .A(tag_index), .CEB(!tag_En1), .WEB(!tag_RW), .BWEB(32'b0), .D(tag_in), .Q(tag_out1),
        .SLP(1'b0),
        .DSLP(1'b0),
        .SD(1'b0),
        .RTSEL(2'b01),
        .WTSEL(2'b01)
    );

    //MEM stage
    FILL_IN_CELL_SRAM_005 data_sram_H1 (
        .CLK(clk), .A(data_index), .CEB(!data_En_H1), .WEB(!data_RW_HL), .BWEB(BWEB_up), .D(data_in), .Q({data_out_array[1][3], data_out_array[1][2]}),
        .SLP(1'b0),
        .DSLP(1'b0),
        .SD(1'b0),
        .RTSEL(2'b01),
        .WTSEL(2'b01)
    );

    FILL_IN_CELL_SRAM_005 data_sram_L1 (
        .CLK(clk), .A(data_index), .CEB(!data_En_L1), .WEB(!data_RW_HL), .BWEB(BWEB_down), .D(data_in), .Q({data_out_array[1][1], data_out_array[1][0]}),
        .SLP(1'b0),
        .DSLP(1'b0),
        .SD(1'b0),
        .RTSEL(2'b01),
        .WTSEL(2'b01)
    );
`endif

endmodule
