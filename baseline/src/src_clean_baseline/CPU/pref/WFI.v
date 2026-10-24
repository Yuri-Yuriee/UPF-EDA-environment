module WFI_unit #(
    parameter integer v_stage      = 4
)(
    input clk, rst,
    input wfi,
    input interrupt,
    input mstatus_mie,
    output stall_wfi,
    input [((v_stage <= 1) ? 1 : $clog2(v_stage))-1:0] DVFS_v_step
`ifdef CPU_PG
,   output CPU_ISO, CPU_ON, CPU_OFF, CPU_restore_pulse, CPU_save_pulse, CPU_CG,
    input stall_D,
    input stall_I
`endif
);
 
`ifdef CPU_PG
//******************************
//          FSM
//******************************
typedef enum logic[3:0] {
    ST_ON,
    ST_EXE,
    ST_MEM,
    ST_WB,
    ST_SAVE_ON,
    ST_SAVE,
    ST_SAVE_OFF,
    ST_OFF,
    ST_RESTORE_ON,
    ST_RESTORE,
    ST_RESTORE_OFF,
    ST_RESET
} ST_W;
ST_W state;
ST_W next_state;
always @(posedge clk or posedge rst) begin
    if(rst)begin
        state <= ST_ON;
    end
    else begin
        state <= next_state;
    end
end
always @(*) begin
    case (state)
        ST_ON : begin
            if(wfi)begin
                next_state = ST_EXE;
            end
            else begin
                next_state = ST_ON;
            end
        end
        ST_EXE : begin
            if(!stall_D && !stall_I)begin       // 沒有判斷stall_I 會導致 MEM 的 Write back 被卡住並消失 //TODO TODO
                next_state = ST_MEM;
            end
            else begin
                next_state = ST_EXE;
            end
        end
        ST_MEM : begin
            if(!stall_D)begin
                next_state = ST_WB;
            end
            else begin
                next_state = ST_MEM;
            end
        end
        ST_WB : begin
            if(!stall_D)begin
                next_state = ST_SAVE_ON;
            end
            else begin
                next_state = ST_WB;
            end
        end
        ST_SAVE_ON      : next_state = ST_SAVE;
        ST_SAVE         : next_state = ST_SAVE_OFF;
        ST_SAVE_OFF     : next_state = ST_OFF;
        ST_OFF : begin
            if(interrupt)begin
                next_state = ST_RESTORE_ON;
            end
            else begin
                next_state = ST_OFF;
            end
        end
        ST_RESTORE_ON   : next_state = ST_RESTORE;
        ST_RESTORE      : next_state = ST_RESTORE_OFF;
        ST_RESTORE_OFF  : next_state = ST_RESET;
        ST_RESET : next_state = ST_ON;
        default: next_state = ST_ON;
    endcase
end
//******************************
//          output siganl      
//******************************ß
assign stall_wfi          = (state != ST_ON) ? 1'd1 : 1'd0;
assign CPU_restore_pulse  = (state == ST_RESTORE) ? 1'b1 : 1'b0;
assign CPU_save_pulse     = (state == ST_SAVE) ? 1'b1 : 1'b0;
assign CPU_ON             = (state != ST_OFF) ? 1'b1 : 1'b0;
assign CPU_OFF            = (state == ST_OFF) ? 1'b1 : 1'b0;
assign CPU_ISO            =  CPU_CG | CPU_OFF | CPU_save_pulse | CPU_restore_pulse ;
assign CPU_CG             = (state == ST_RESTORE_ON || state == ST_RESTORE || state == ST_RESTORE_OFF || state == ST_SAVE_ON || state == ST_SAVE || state == ST_SAVE_OFF ) ? 1'b1 : 1'b0;
//assign CPU_ISO            = CPU_OFF | CPU_save_pulse;
`else
 
typedef enum logic[1:0] {
    ST_work,
    ST_wfi,
    ST_power_off,
    ST_power_on
} ST_W;
ST_W state;
ST_W next_state;
always @(posedge clk or posedge rst) begin
    if(rst)begin
        state <= ST_work;
    end
    else begin
        state <= next_state;
    end
end
always @(*) begin
    case (state)
        ST_work : begin
            if(wfi)begin
                next_state = ST_wfi;
            end
            else begin
                next_state = ST_work;
            end
        end
        ST_wfi : begin
            if(interrupt)begin
                next_state = ST_work;
            end
            else begin
                next_state = ST_wfi;
            end
        end
        default: next_state = ST_work;
    endcase
end
//******************************
//          output siganl      
//******************************
 
assign stall_wfi = (state == ST_wfi) ? 1'd1 : 1'd0;
`endif

logic [v_stage-1:0] power_switch_en;

power_switch_decoder #(
    .v_stage(v_stage)
) u_power_switch_decoder (
    .CPU_OFF         (CPU_OFF),
    .DVFS_v_step     (DVFS_v_step),
    .power_switch_en (power_switch_en)
);

endmodule
 