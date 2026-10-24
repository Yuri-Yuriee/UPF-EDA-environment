// `define sysA_cause_reg                  32'h0000_0000
// `define sysA_TD_DVFS_start_reg          32'h0000_0004
// `define sysA_TD_calib_start_reg         32'h0000_0008
// `define sysA_TD_valid                   32'h0000_000C
// `define sysA_TD_error_margin_reg        32'h0000_0010
// `define sysA_TD_warning_margin_reg      32'h0000_0014
// `define sysA_TD_warning_interrupt_En    32'h0000_0018
// `define sysA_testProg_srcA              32'h0000_001C
// `define sysA_testProg_trgA              32'h0000_0020
// `define sysA_testProg_len               32'h0000_0024
// `define sysA_TD_calib_done_mask_reg     32'h0000_0028
// `define sysA_TD_voltage_only_mask_reg   32'h0000_002C
// `define sysA_TD_calib_idx_reg           32'h0000_0030
// `define sysA_TD_broad_reg               32'h0000_0034
// `define sysA_TD_claim                   32'h0000_0038 

// typedef enum logic[15:0] { 
//     STD_off         = 16'h0000,
//     STD_S0_set      = 16'h000a,
//     STD_S1_init     = 16'h0001,
//     STD_S2_load     = 16'h0002,
//     STD_S3_FTest    = 16'h0003,
//     STD_S4_RF       = 16'h0004,
//     STD_S5_STest    = 16'h0005,
//     STD_S6_noError  = 16'h0006,
//     STD_S7_yesError = 16'h0007,
//     STD_S8_marginSet= 16'h0008,
//     STD_idal        = 16'hFFFF
// } TD_ST;



module TD_center_unit #(
    parameter integer TD_NUM    = 1,
    parameter integer TD_BITS = (TD_NUM <= 1) ? 1 : $clog2(TD_NUM)
) (
    // To TD
    input                   clk,
    input                   rst,
    input   [TD_NUM-1:0]    TD_warning,

    output  [TD_NUM-1:0]    calibration_valid_req,
    input   [TD_NUM-1:0]    calibration_ready_req,
    input   [TD_NUM-1:0]    calibration_valid_resp,
    output  [TD_NUM-1:0]    calibration_ready_resp,
    output  [TD_NUM-1:0]    calibration_updown,
    
    // To DVFS unit
    output                  DVFS_req,
    input                   DVFS_resp,

    // output                  DVFS_F_updown,
    // output                  DVFS_V_updown,
    output                  DVFS_F_max,
    output                  DVFS_F_min,
    output                  DVFS_V_tune,    //for TD


    //AXI
    //DMA
    axi_read_if.master      axi_r_m,
    axi_write_if.master     axi_w_m,

    //MMIO
    axi_read_if.slave       axi_r_s,
    axi_write_if.slave      axi_w_s,
    input                   sys_error,      //TODOTODO

    output                  TD_interrupt
    
);

TD_ST state, next_state;
//======================
//      AXI reg
//======================
//TD reg
reg [31:0]  cause_reg;

reg [3:0]   TD_DVFS_start_reg;
reg [3:0]   TD_calib_start_reg; 

reg         TD_valid;
reg [3:0]   TD_error_margin_reg;
reg [3:0]   TD_warning_margin_reg; 
reg         TD_warning_interrupt_En;
reg [TD_NUM-1:0] TD_calib_done_mask_reg;
reg [TD_NUM-1:0] TD_voltage_only_mask_reg;
reg [TD_BITS-1:0] calib_idx;

reg         TD_calib_claim;

// DMA
reg [31:0]  testProg_srcA;
reg [31:0]  testProg_trgA;
reg [31:0]  testProg_len;




//======================
//      control
//======================
wire        calibration_done;
wire        cause_write;
wire [31:0] cause_write_data;
wire [15:0] TD_warning_encode;
wire        state_change;
wire [31:0] next_cause_reg;
wire        DVFS_shk;
wire        calib_shk;
wire        calib_req_active;
wire        calib_req_shk;
wire        calib_resp_shk;
reg         calib_wait_resp;
wire        load_done;
reg  [31:0] read_data_r;

reg [3:0] TD_error_margin_cnt;
reg [3:0] TD_warning_margin_cnt;

reg  [TD_NUM-1:0] TD_warning_hold;
reg  [TD_NUM-1:0] TD_warning_dvfs_shk_seen;
reg  [TD_NUM-1:0] TD_warning_calib_shk_seen;
wire [TD_NUM-1:0] TD_warning_keep;
wire [TD_NUM-1:0] TD_warning_dvfs_shk_next;
wire [TD_NUM-1:0] TD_warning_calib_shk_next;
wire [TD_NUM-1:0] TD_warning_clear;


wire [TD_NUM-1:0] calib_sel;
wire        voltage_only_cur;

// DMA
wire        dma_start;
wire        dma_busy;
reg         miss;
reg         hit;
wire [31:0] read_data;
wire        Read_Enable;
wire        Write_Enable;
wire [31:0] Write_data;
wire [31:0] Addr;
wire [3:0]  WSTRB;
wire        stall_W;


wire [TD_NUM-1:0] broad_clear;
reg [31:0] TD_broad;
wire calib_s_change;

typedef enum logic { 
    ST_noShk,
    ST_doneShk
} ST_shk;

ST_shk ST_shk_DVFS, ST_shk_calib;


typedef enum logic[2:0] {  
    ST_idle, 
    ST_start_noWarn,
    ST_start_Warn,
    ST_switch_2_Warn,
    ST_switch_2_noWarn,
    ST_done
} ST_calib;

ST_calib calib_cs, calib_ns;
wire calib_warn;
//========================
//      output signal
//========================
// assign DVFS_req             =   (state inside {STD_S6_noError, STD_S8_marginSet, STD_S0_set, STD_S1_init, STD_S4_RF}) && (ST_shk_DVFS inside {ST_noShk}) ? 1'b1 :
//                                 ((state inside {STD_idal}) && TD_valid && TD_broad[0]) ? 1'b1 : 1'b0;
assign DVFS_req             =   (state inside {STD_S8_marginSet, STD_S0_set, STD_S1_init, STD_S4_RF}) && (ST_shk_DVFS inside {ST_noShk}) ? 1'b1 :
                                ((state inside {STD_idal}) && TD_valid && TD_broad[0]) ? 1'b1 : 1'b0;
assign DVFS_F_max           =   (state inside {STD_S0_set});
assign DVFS_F_min           =   (state inside {STD_S4_RF});
assign DVFS_V_tune          =   (state inside {STD_S8_marginSet, STD_idal});

//DVFS_req need fix when multi TD

//assign calibration_valid[0]    =   (state inside {STD_S6_noError, STD_S8_marginSet}) && (ST_shk_calib inside {ST_noShk});
//assign calibration_updown[0]   =   (state inside {STD_S6_noError}) ? 1'b1 : 1'b0;

assign calib_sel            =   ({{(TD_NUM-1){1'b0}}, 1'b1} << calib_idx);
assign voltage_only_cur     =   TD_voltage_only_mask_reg[calib_idx];

assign calib_req_active     =   (!voltage_only_cur) && (ST_shk_calib == ST_noShk) &&
                                (
                                    (state inside {STD_S8_marginSet}) ||
                                    ((state inside {STD_S7_yesError}) &&
                                     (calib_cs inside {ST_start_noWarn, ST_start_Warn, ST_switch_2_noWarn}))
                                );

assign calibration_valid_req =  (!calib_wait_resp && calib_req_active) ? calib_sel : '0;

assign calibration_ready_resp = (calib_wait_resp) ? calib_sel : '0;

assign calibration_updown   =   ((state inside {STD_S8_marginSet}) ||
                                 (calib_cs inside {ST_start_noWarn, ST_switch_2_noWarn})) ? calib_sel : '0;

assign calibration_done     =   (state inside {STD_S8_marginSet}) && state_change;
assign TD_interrupt         =   (state inside {STD_S3_FTest, STD_S5_STest} && !TD_calib_claim) ? 1'b1 : 
                                (|TD_warning_keep && TD_warning_interrupt_En && state inside {STD_idal}) ? 1'b1 : 1'b0;

//========================
//      ctrl signal
//========================
assign state_change         =   (state != next_state);
logic [15:0] state_raw;

assign state_raw = cause_reg[31:16];

always_comb begin
    state = TD_ST'(state_raw);
end

assign next_cause_reg       =   {next_state, TD_warning_encode};

// shk
assign DVFS_shk             =   DVFS_resp & DVFS_req;
assign calib_req_shk        =   calibration_valid_req[calib_idx] & calibration_ready_req[calib_idx];
assign calib_resp_shk       =   calibration_valid_resp[calib_idx] & calibration_ready_resp[calib_idx];
assign calib_shk            =   calib_resp_shk;

//DMA
assign dma_start            =   (state inside {STD_S2_load} && !dma_busy);

//TODOTODO
assign TD_warning_encode    = {{(16-TD_NUM){1'b0}}, TD_warning_keep};

assign broad_clear          = {TD_NUM{DVFS_resp && DVFS_req && (state inside {STD_idal})}};

assign stall_W              = (state inside {STD_S0_set ,STD_S2_load, STD_S4_RF, STD_S6_noError, STD_S7_yesError, STD_S8_marginSet});

// TD_warning keep
// TD_warning may be only one-cycle pulse. Keep it until the selected warning
// has completed both DVFS handshake and calibration response handshake.
assign TD_warning_keep           = TD_warning_hold | TD_warning;
assign TD_warning_dvfs_shk_next  = TD_warning_dvfs_shk_seen  | ({TD_NUM{DVFS_shk}}  & TD_warning_keep);
assign TD_warning_calib_shk_next = TD_warning_calib_shk_seen | ({TD_NUM{calib_shk}} & TD_warning_keep & calib_sel);
assign TD_warning_clear          = TD_warning_dvfs_shk_next | TD_warning_calib_shk_next;

always @(posedge clk or posedge rst) begin
    if(rst)begin
        TD_warning_hold           <= '0;
        TD_warning_dvfs_shk_seen  <= '0;
        TD_warning_calib_shk_seen <= '0;
    end
    else if(state inside {STD_off})begin
        TD_warning_hold           <= '0;
        TD_warning_dvfs_shk_seen  <= '0;
        TD_warning_calib_shk_seen <= '0;
    end
    else begin
        TD_warning_hold           <= TD_warning_keep & ~TD_warning_clear;
        TD_warning_dvfs_shk_seen  <= TD_warning_dvfs_shk_next & ~TD_warning_clear;
        TD_warning_calib_shk_seen <= TD_warning_calib_shk_next & ~TD_warning_clear;
    end
end

// calib_idx
always @(posedge clk or posedge rst) begin
    if(rst)begin
        calib_idx <= '0;
    end
    else if(Write_Enable && Addr == `sysA_TD_calib_idx_reg)begin
        if(Write_data[TD_BITS-1:0] < TD_NUM)begin
            calib_idx <= Write_data[TD_BITS-1:0];
        end
        else begin
            calib_idx <= '0;
        end
    end
    else if(state == STD_S8_marginSet && next_state == STD_idal)begin
        if(calib_idx == TD_NUM-1)begin
            calib_idx <= '0;
        end
        else begin
            calib_idx <= calib_idx + 1'b1;
        end
    end
end

// calib done mask
always @(posedge clk or posedge rst) begin
    if(rst)begin
        TD_calib_done_mask_reg <= '0;
    end
    else if(Write_Enable && Addr == `sysA_TD_calib_done_mask_reg)begin
        TD_calib_done_mask_reg <= Write_data[TD_NUM-1:0];
    end
    else if(state == STD_S8_marginSet && next_state == STD_idal)begin
        TD_calib_done_mask_reg[calib_idx] <= 1'b1;
    end
end


// TD_valid
always @(posedge clk or posedge rst) begin
    if(rst)begin
        TD_valid <= '0;
    end
    else if(state == STD_off)begin
        TD_valid <= 1'b0;
    end
    else if(calibration_done)begin
        TD_valid <= 1'b1;
    end
    else if(Write_Enable && Addr == `sysA_TD_valid) begin
        TD_valid <= Write_data[0];
    end
end

//========================
//      TD_scord Broad
//========================
always @(posedge clk or posedge rst) begin
    if(rst)begin
       TD_broad <= '0;
    end
    else if(TD_valid && DVFS_resp && (state inside {STD_idal}))begin
        TD_broad[TD_NUM-1:0] <= (TD_broad[TD_NUM-1:0] & ~broad_clear) | TD_warning_keep;
    end
    else if(Write_Enable && Addr == `sysA_TD_broad_reg)begin
        TD_broad <= Write_data;
    end
end

always @(posedge clk or posedge rst) begin
    if(rst)begin
        TD_calib_claim <= '0;
    end
    else if(Write_Enable && Addr == `sysA_TD_calib_claim) begin
        TD_calib_claim           <= Write_data[0];
    end
    else if(state_change)begin
        TD_calib_claim <= '0;
    end
end


//========================
//      MMIO
//========================
// cause_reg
assign cause_write      = Write_Enable && (Addr == `sysA_cause_reg);
assign cause_write_data = Write_data;
always @(posedge clk or posedge rst) begin
    if(rst)begin
        cause_reg <= '0;
    end
    else if(cause_write)begin
        cause_reg <= cause_write_data;
    end
    else begin
        cause_reg <= next_cause_reg;
    end
end

always @(posedge clk or posedge rst) begin
    if(rst)begin
        TD_DVFS_start_reg       <= '0; 
        TD_calib_start_reg      <= '0; 
        TD_error_margin_reg     <= '0; 
        TD_warning_margin_reg   <= '0; 
        TD_warning_interrupt_En <= '0; 
        TD_voltage_only_mask_reg <= '0;
        testProg_srcA           <= '0; 
        testProg_trgA           <= '0; 
        testProg_len            <= '0;
    end
    else if(Write_Enable)begin  
        case (Addr) 
            `sysA_TD_DVFS_start_reg      : TD_DVFS_start_reg        <= Write_data[3:0];       
            `sysA_TD_calib_start_reg     : TD_calib_start_reg       <= Write_data[3:0];  
            `sysA_TD_error_margin_reg    : TD_error_margin_reg      <= Write_data[3:0]; 
            `sysA_TD_warning_margin_reg  : TD_warning_margin_reg    <= Write_data[3:0];
            `sysA_TD_warning_interrupt_En: TD_warning_interrupt_En  <= Write_data[0];
            `sysA_TD_voltage_only_mask_reg: TD_voltage_only_mask_reg <= Write_data[TD_NUM-1:0];
            `sysA_testProg_srcA          : testProg_srcA            <= Write_data[31:0];
            `sysA_testProg_trgA          : testProg_trgA            <= Write_data[31:0];
            `sysA_testProg_len           : testProg_len             <= Write_data[31:0];

        endcase
    end
end

always @(*) begin
    hit  = 1'b0;
    miss = 1'b0;
    if (Write_Enable || Read_Enable) begin
        case (Addr)
            `sysA_cause_reg                  : begin hit = 1'b1; miss = 1'b0; end
            `sysA_TD_DVFS_start_reg          : begin hit = 1'b1; miss = 1'b0; end
            `sysA_TD_calib_start_reg         : begin hit = 1'b1; miss = 1'b0; end
            `sysA_TD_valid                   : begin hit = 1'b1; miss = 1'b0; end
            `sysA_TD_error_margin_reg        : begin hit = 1'b1; miss = 1'b0; end
            `sysA_TD_warning_margin_reg      : begin hit = 1'b1; miss = 1'b0; end
            `sysA_TD_warning_interrupt_En    : begin hit = 1'b1; miss = 1'b0; end
            `sysA_TD_calib_done_mask_reg     : begin hit = 1'b1; miss = 1'b0; end
            `sysA_TD_voltage_only_mask_reg   : begin hit = 1'b1; miss = 1'b0; end
            `sysA_TD_calib_idx_reg           : begin hit = 1'b1; miss = 1'b0; end
            `sysA_testProg_srcA              : begin hit = 1'b1; miss = 1'b0; end
            `sysA_testProg_trgA              : begin hit = 1'b1; miss = 1'b0; end
            `sysA_testProg_len               : begin hit = 1'b1; miss = 1'b0; end
            `sysA_TD_broad_reg               : begin hit = 1'b1; miss = 1'b0; end
            `sysA_TD_calib_claim             : begin hit = 1'b1; miss = 1'b0; end
            default                          : begin hit = 1'b0; miss = 1'b1; end
        endcase
    end
end


assign read_data = read_data_r;
always @(*) begin
    read_data_r = 32'd0;
    case (Addr)
        `sysA_cause_reg              : read_data_r = cause_reg;
        `sysA_TD_DVFS_start_reg      : read_data_r = {28'd0, TD_DVFS_start_reg};
        `sysA_TD_calib_start_reg     : read_data_r = {28'd0, TD_calib_start_reg};
        `sysA_TD_valid               : read_data_r = {31'd0, TD_valid};
        `sysA_TD_error_margin_reg    : read_data_r = {28'd0, TD_error_margin_reg};
        `sysA_TD_warning_margin_reg  : read_data_r = {28'd0, TD_warning_margin_reg};
        `sysA_TD_warning_interrupt_En: read_data_r = {31'd0, TD_warning_interrupt_En};
        `sysA_TD_calib_done_mask_reg : read_data_r = {{(32-TD_NUM){1'b0}}, TD_calib_done_mask_reg};
        `sysA_TD_voltage_only_mask_reg: read_data_r = {{(32-TD_NUM){1'b0}}, TD_voltage_only_mask_reg};
        `sysA_TD_calib_idx_reg       : read_data_r = {{(32-TD_BITS){1'b0}}, calib_idx};
        `sysA_testProg_srcA          : read_data_r = testProg_srcA;
        `sysA_testProg_trgA          : read_data_r = testProg_trgA;
        `sysA_testProg_len           : read_data_r = testProg_len;
        `sysA_TD_broad_reg           : read_data_r = TD_broad;
        `sysA_TD_calib_claim         : read_data_r = {31'd0, TD_calib_claim};
        default                      : read_data_r = 32'd0;
    endcase
end

//========================
//      shk board
//========================
//shk board
always @(posedge clk or posedge rst) begin
    if(rst)begin
        ST_shk_DVFS <= ST_noShk;
    end
    else begin
        case (ST_shk_DVFS)
            ST_noShk :      ST_shk_DVFS <= (!state_change && DVFS_shk && TD_error_margin_cnt == 0) ? ST_doneShk : ST_noShk;
            ST_doneShk :    ST_shk_DVFS <= (state_change) ? ST_noShk : ST_doneShk;
            default:        ST_shk_DVFS <= ST_noShk;
        endcase
    end
end


assign calib_s_change = (calib_cs != calib_ns);

always @(posedge clk or posedge rst) begin
    if(rst)begin
        calib_wait_resp <= 1'b0;
    end
    else if(state_change || voltage_only_cur)begin
        calib_wait_resp <= 1'b0;
    end
    else if(calib_resp_shk)begin
        calib_wait_resp <= 1'b0;
    end
    else if(calib_req_shk)begin
        calib_wait_resp <= 1'b1;
    end
end

always @(posedge clk or posedge rst) begin
    if(rst)begin
        ST_shk_calib <= ST_noShk;
    end
    else begin
        case (ST_shk_calib)
            ST_noShk :      ST_shk_calib <= (!state_change && calib_shk && (state inside {STD_S7_yesError})) ? ST_doneShk :
                                            (!state_change && (voltage_only_cur || (calib_shk && TD_warning_margin_cnt == 0))) ? ST_doneShk : ST_noShk;
            ST_doneShk :    ST_shk_calib <= (state_change) ? ST_noShk : 
                                            ((calib_cs inside {ST_start_noWarn, ST_start_Warn})) ? ST_noShk : ST_doneShk;
            default:        ST_shk_calib <= ST_noShk;
        endcase
    end
end

//margin shk counter
always @(posedge clk or posedge rst) begin
    if(rst)begin
        TD_warning_margin_cnt <= '0;
    end
    else if((state inside {STD_S7_yesError}))begin
        TD_warning_margin_cnt <= TD_warning_margin_reg;
    end
    else if((state inside {STD_S8_marginSet}) && calib_shk && |TD_warning_margin_cnt)begin
        TD_warning_margin_cnt <= TD_warning_margin_cnt - 1;
    end
    else if(state inside {STD_idal}) begin
        TD_warning_margin_cnt <= '0;
    end
end

//margin shk counter
always @(posedge clk or posedge rst) begin
    if(rst)begin
        TD_error_margin_cnt <= '0;
    end
    else if((state inside {STD_S7_yesError}))begin
        TD_error_margin_cnt <= TD_error_margin_reg;
    end
    else if((state inside {STD_S8_marginSet}) && DVFS_shk && |TD_error_margin_cnt)begin
        TD_error_margin_cnt <= TD_error_margin_cnt - 1;
    end
    else if(state inside {STD_idal}) begin
        TD_error_margin_cnt <= '0;
    end
end


//delay chain calibration


assign calib_warn = TD_warning_keep[calib_idx];


always @(posedge clk or posedge rst) begin
    if(rst)begin
        calib_cs <= ST_idle;
    end
    else begin
        calib_cs <= calib_ns;
    end
end

always @(*) begin
    case (calib_cs)
        ST_idle             :   calib_ns =  (voltage_only_cur && (state inside {STD_S7_yesError})) ? ST_done :
                                            ((state inside {STD_S7_yesError}) && calib_warn) ? ST_start_Warn : 
                                            ((state inside {STD_S7_yesError}) && !calib_warn) ? ST_start_noWarn : ST_idle;
        ST_start_noWarn     :   calib_ns =  (calib_warn && (ST_shk_calib inside {ST_doneShk})) ? ST_switch_2_Warn : ST_start_noWarn;
        ST_start_Warn       :   calib_ns =  (!calib_warn && (ST_shk_calib inside {ST_doneShk})) ? ST_switch_2_noWarn : ST_start_Warn;
        ST_switch_2_Warn    :   calib_ns =  ST_done;
        ST_switch_2_noWarn  :   calib_ns =  ((ST_shk_calib inside {ST_doneShk})) ? ST_done : ST_switch_2_noWarn;
        ST_done             :   calib_ns =  (state inside {STD_S8_marginSet}) ? ST_idle : ST_done;
        default             :   calib_ns =  ST_idle;
    endcase
end

//========================
//      FSM
//========================
// next state
always @(*)begin
    case (state)
        STD_idal :          next_state =    STD_idal;
        STD_off :           next_state =    STD_off; 
        STD_S0_set :        next_state =    (DVFS_resp && !voltage_only_cur) ? STD_S1_init : 
                                            (DVFS_resp && voltage_only_cur) ? STD_S6_noError : STD_S0_set;
        STD_S1_init :       next_state =    (ST_shk_DVFS == ST_doneShk) ? STD_S2_load : STD_S1_init;
        STD_S2_load :       next_state =    (load_done) ? STD_S3_FTest : STD_S2_load;
        STD_S3_FTest :      next_state =    (sys_error) ? STD_S7_yesError : STD_S3_FTest;
        STD_S4_RF   :       next_state =    (DVFS_resp) ? STD_S5_STest : STD_S4_RF;
        STD_S5_STest :      next_state =    STD_S5_STest;
        // STD_S6_noError :    next_state =    (ST_shk_DVFS == ST_doneShk && voltage_only_cur && calib_warn) ? STD_S7_yesError : 
        //                                     (ST_shk_DVFS == ST_doneShk) ? STD_S0_set : STD_S6_noError;
        STD_S6_noError :    next_state =    (voltage_only_cur && calib_warn) ? STD_S7_yesError : STD_S0_set;
        STD_S7_yesError :   next_state =    (calib_cs inside {ST_done}) ? STD_S8_marginSet : STD_S7_yesError;
        STD_S8_marginSet :  next_state =    (ST_shk_calib == ST_doneShk && ST_shk_DVFS == ST_doneShk) ? STD_idal : STD_S8_marginSet;
        default :           next_state =    STD_off;
    endcase
end

// DMA
inner_dma #(
    .MAX_BURST_BEATS (16),
    .FIFO_DEPTH      (4)
) u_dma (
    .ACLK          (clk),
    .ARESETn       (~rst),

    .DMA_start     (dma_start),
    .src_baseA     (testProg_srcA),
    .trg_baseA     (testProg_trgA),
    .DMA_len       (testProg_len),

    .DMA_busy      (dma_busy),
    .DMA_done      (load_done),
    .DMA_interrupt (),
    .DMA_error     (),

    .axi_r_m       (axi_r_m),
    .axi_w_m       (axi_w_m)
);



slave_simple u_slave_simple (
    .ACLK           (clk),
    .ARESETn        (~rst),
    .axi_r_s        (axi_r_s),
    .axi_w_s        (axi_w_s),

    //req
    .Read_Enable    (Read_Enable),
    .Write_Enable   (Write_Enable),
    .Write_data     (Write_data),
    .Addr           (Addr),
    .out_WSTRB      (WSTRB),

    //resp
    .in_miss        (miss),
    .in_hit         (hit),
    .read_data      (read_data),
    .stall_W        (stall_W),
    .stall_R        (1'b0)
);

endmodule