typedef enum logic [2:0] { 
    power_on,
    power_off,
    idle,
    read,
    write,
    wait_req_R,
    wait_req_W
 } state_t;

module master_simple(
//******************************
//		to wrapper port (Master version)
//******************************
	input           ACLK,
	input           ARESETn,

	axi_read_if.master   axi_r_m,
	axi_write_if.master  axi_w_m,

//******************************
//		to plug (master interface)
//******************************

    //req
	input           req_En,
    input           RW,
    input    [31:0] Addr,
    input     [2:0] Size,
    input    [2:0]  Signalize,
    input    [3:0]  Len,
    input    [3:0]  WSTRB,
    input    [1:0]  BURST,
	input 	 [3:0]	ID,
    output   response,

    //data
    output [31:0]   read_data,
	output          Read_Enable,
	output [3:0]	out_ID,
	input  [31:0]   Write_data,
	input           Write_Enable,
    output          WB,  
    input           stall
);
//******************************
//		    define
//******************************  
state_t state;
state_t next_state;
reg [7:0] ID_current;
reg [3:0] LEN_current;
reg [31:0] Addr_current;
reg [3:0] SIZE_current;
reg [3:0] BURST_current;
reg [3:0] WSTRB_current;
reg [31:0]WDATA_current;
reg WLAST_current;
reg W_done;

// reg [31:0] pre_read_data;

// always @(posedge ACLK or posedge ARESETn) begin
//     if(!ARESETn)begin
//         pre_read_data <= '0;
//     end
//     else begin
//         pre_read_data <= read_data;
//     end
// end

// always @(posedge ACLK or posedge ARESETn) begin
//     if(!ARESETn)begin
//         pre_stall;
//     end
//     else begin
//         pre_stall <= stall;
//     end
// end

// channel shake
    wire AR_shake   = (axi_r_m.ARREADY_m && axi_r_m.ARVALID_m) ? 1'b1 : 1'b0; 
    wire AW_shake   = (axi_w_m.AWREADY_m && axi_w_m.AWVALID_m) ? 1'b1 : 1'b0;
    wire W_shake    = (axi_w_m.WREADY_m && axi_w_m.WVALID_m) ? 1'b1 : 1'b0;
    wire B_shake    = (axi_w_m.BREADY_m && axi_w_m.BVALID_m) ? 1'b1 : 1'b0;
    wire R_shake    = (axi_r_m.RREADY_m && axi_r_m.RVALID_m) ? 1'b1 : 1'b0;

//******************************
//		  FSM
//****************************** 
    //req
    assign response = (AR_shake || AW_shake) ? 1'd1 : 1'd0;

    //data
    assign read_data = axi_r_m.RDATA_m;
	assign Read_Enable = (R_shake) ? 1'd1 : 1'd0;
	assign out_ID = ID_current;
    assign WB = B_shake;




//******************************
//		  FSM
//****************************** 
always @(posedge ACLK or negedge ARESETn) begin
    if(!ARESETn)begin
        state <= power_on;
    end
    else begin
        state <= next_state;
    end
end

always @(*) begin
    case (state)
        idle : begin
            if(req_En && !RW && AR_shake)begin
                next_state = read;
            end
            else if(req_En && RW && AW_shake)begin
                next_state = write;
            end
            else if(req_En && !RW && !AR_shake)begin
                next_state = wait_req_R;
            end
            else if(req_En && RW && !AW_shake)begin
                next_state = wait_req_W;
            end
            else begin
                next_state = idle;
            end
        end 
        read : begin
            if(R_shake && axi_r_m.RLAST_m)begin
                next_state = idle;
            end
            else begin
                next_state = read;
            end
        end 
        write : begin
            if(B_shake)begin
                next_state = idle;
            end
            else begin
                next_state = write;
            end
        end
        wait_req_R : begin
            if(AR_shake)begin
                next_state = read;
            end
            else begin
                next_state = wait_req_R;
            end
        end
        wait_req_W : begin
            if(AW_shake)begin
                next_state = write;
            end
            else begin
                next_state = wait_req_W;
            end
        end
        power_off : begin
            next_state = power_off;
        end
        power_on : begin
            next_state = idle;
        end
        default: next_state = power_off;
    endcase
end
//******************************
//		  channel arbitrator
//****************************** 


always @(posedge ACLK or negedge ARESETn) begin
    if(!ARESETn)begin
        ID_current <= 8'd0;
        LEN_current <= 4'd0;
        Addr_current <= 32'd0;
        SIZE_current <= 4'd0;
        BURST_current <= 4'd0;
    end
    else if(state == idle && next_state!=idle )begin
        ID_current <= ID;
        LEN_current <= Len;
        Addr_current <= Addr;
        SIZE_current <= Size;
        BURST_current <= BURST;
    end
    else begin
        ID_current <= ID_current;
        LEN_current <= LEN_current;
        Addr_current <= Addr_current;
        SIZE_current <= SIZE_current;
        BURST_current <= BURST_current;
    end
end


reg W_valid;
always @(posedge ACLK or negedge ARESETn) begin
    if(!ARESETn)begin
        WDATA_current <= 32'd0;
        WSTRB_current <= 4'd0;
        WLAST_current <= 1'd0;
        W_valid <= 1'd0;
        W_done <= 1'd0;
    end
    else if(B_shake)begin
        WDATA_current <= WDATA_current;
        WSTRB_current <= WSTRB_current;
        WLAST_current <= 1'd0;
        W_valid <= 1'd0;
        W_done <= 1'd0;
    end
    else if(Write_Enable & !W_valid && W_shake)begin
       WDATA_current <= Write_data;
       WSTRB_current <= WSTRB;
       WLAST_current <= 1'd1;
       W_valid <= 1'd1;
       W_done <= 1'd1;
    end
    else if(Write_Enable & !W_valid && !(state == idle && !req_En))begin
       WDATA_current <= Write_data;
       WSTRB_current <= WSTRB;
       WLAST_current <= 1'd1;
       W_valid <= 1'd1;
       W_done <= 1'd0;
    end
    else if(state == write && W_shake)begin
        WDATA_current <= WDATA_current;
        WSTRB_current <= WSTRB_current;
        WLAST_current <= WLAST_current;
        W_valid <= W_valid;
        W_done <= 1'd1;
    end
    else begin
        WDATA_current <= WDATA_current;
        WSTRB_current <= WSTRB_current;
        WLAST_current <= WLAST_current;
        W_valid <= W_valid;
        W_done <= W_done;
    end
end




assign axi_w_m.AWID_m     = (state == idle ) ? ID : ID_current;
assign axi_w_m.AWADDR_m   = (state == idle) ? Addr : Addr_current;
assign axi_w_m.AWLEN_m    = (state == idle) ? Len : LEN_current;
assign axi_w_m.AWSIZE_m   = (state == idle) ? Size : SIZE_current;
assign axi_w_m.AWBURST_m  = (state == idle) ? BURST : BURST_current;
assign axi_w_m.AWVALID_m  = (stall) ? 1'd0 : (state == idle && req_En && RW && ARESETn) ? 1'b1 : (state == wait_req_W) ? 1'b1 : 1'b0;

assign axi_w_m.WDATA_m    = (state == write && W_valid) ? WDATA_current : (state == write && !W_valid && Write_Enable) ? Write_data : 32'd0;
assign axi_w_m.WSTRB_m    = (state == write && W_valid) ? WSTRB_current : (state == write && !W_valid && Write_Enable) ? WSTRB : 4'd0;
assign axi_w_m.WLAST_m    = (state == write)  ? WLAST_current  : 1'b0;
assign axi_w_m.WVALID_m   = (stall) ? 1'd0 : (state == write && !W_done && W_valid)  ? 1'b1 : 1'b0;


// assign axi_w_m.WDATA_m    = (state == idle && next_state == write && Write_Enable) ? Write_data : (state == write && W_valid) ? WDATA_current : (state == write && !W_valid && Write_Enable) ? Write_data : 32'd0;
// assign axi_w_m.WSTRB_m    = (state == idle && next_state == write && Write_Enable) ? WSTRB : (state == write && W_valid) ? WSTRB_current : (state == write && !W_valid && Write_Enable) ? WSTRB : 4'd0;
// assign axi_w_m.WLAST_m    = (state == idle && next_state == write && Write_Enable) ? 1'b1 : (state == write)  ? WLAST_current  : 1'b0;
// assign axi_w_m.WVALID_m   = (state == idle && next_state == write && Write_Enable) ? 1'b1 : (state == write && !W_done && W_valid)  ? 1'b1 : 1'b0;



assign axi_r_m.ARID_m     = (state == idle) ? ID : ID_current;
assign axi_r_m.ARADDR_m   = (state == idle) ? Addr : Addr_current;
assign axi_r_m.ARLEN_m    = (state == idle) ? Len : LEN_current;
assign axi_r_m.ARSIZE_m   = (state == idle) ? Size : SIZE_current;
assign axi_r_m.ARBURST_m  = (state == idle) ? BURST : BURST_current;
assign axi_r_m.ARVALID_m  = (stall) ? 1'd0 : (state == idle && req_En && !RW && ARESETn) ? 1'b1 : (state == wait_req_R) ? 1'b1 : 1'b0;



assign axi_w_m.BREADY_m   = (stall) ? 1'd0 : (state == write && W_done) ? 1'd1 : 1'd0;

assign axi_r_m.RREADY_m   = (stall) ? 1'd0 : (state == read) ? 1'd1 : 1'd0; 


endmodule