`timescale 1ps/1ps

// ============================================================
// TB for TD_center_unit + TD_loacl_unit + DVFS_unit
// MMIO is driven by master_simple, not hierarchical force.
//
// Compile example:
//   vcs -sverilog \
//       AXI_interface.svh master_simple.sv slave_simple.sv simple_axi_dma.sv \
//       TD_center_unit.sv TD_loacal_unit.sv DVFS_unit.sv \
//       tb_TD_DVFS_connect_master_simple.sv
//
// If you only want to compile this TB without your AXI interface file,
// define TB_AXI_IF_STUB. Do NOT define it when using your real AXI interface.
// ============================================================
`resetall
`include "/FILL_IN/FILL_IN_RESOURCE_0043"

`resetall
`timescale 1ps/1ps
`include "../src/src_clean_baseline/IP/TD/TD_MAP.svh"

module axi_read_connect (
    axi_read_if  from_master,
    axi_read_if  to_slave
);
    assign to_slave.ARID_s     = from_master.ARID_m;
    assign to_slave.ARADDR_s   = from_master.ARADDR_m;
    assign to_slave.ARLEN_s    = from_master.ARLEN_m;
    assign to_slave.ARSIZE_s   = from_master.ARSIZE_m;
    assign to_slave.ARBURST_s  = from_master.ARBURST_m;
    assign to_slave.ARVALID_s  = from_master.ARVALID_m;
    assign from_master.ARREADY_m = to_slave.ARREADY_s;

    assign from_master.RID_m     = to_slave.RID_s;
    assign from_master.RDATA_m   = to_slave.RDATA_s;
    assign from_master.RRESP_m   = to_slave.RRESP_s;
    assign from_master.RLAST_m   = to_slave.RLAST_s;
    assign from_master.RVALID_m  = to_slave.RVALID_s;
    assign to_slave.RREADY_s     = from_master.RREADY_m;
endmodule


module axi_write_connect (
    axi_write_if from_master,
    axi_write_if to_slave
);
    assign to_slave.AWID_s      = from_master.AWID_m;
    assign to_slave.AWADDR_s    = from_master.AWADDR_m;
    assign to_slave.AWLEN_s     = from_master.AWLEN_m;
    assign to_slave.AWSIZE_s    = from_master.AWSIZE_m;
    assign to_slave.AWBURST_s   = from_master.AWBURST_m;
    assign to_slave.AWVALID_s   = from_master.AWVALID_m;
    assign from_master.AWREADY_m = to_slave.AWREADY_s;

    assign to_slave.WDATA_s     = from_master.WDATA_m;
    assign to_slave.WSTRB_s     = from_master.WSTRB_m;
    assign to_slave.WLAST_s     = from_master.WLAST_m;
    assign to_slave.WVALID_s    = from_master.WVALID_m;
    assign from_master.WREADY_m = to_slave.WREADY_s;

    assign from_master.BID_m    = to_slave.BID_s;
    assign from_master.BRESP_m  = to_slave.BRESP_s;
    assign from_master.BVALID_m = to_slave.BVALID_s;
    assign to_slave.BREADY_s    = from_master.BREADY_m;
endmodule



module regulator #(
    parameter real INIT_CELL_DELAY_PS   = 200.0,
    parameter real VOLTAGE_DELAY_SCALE = 1.05
) (
    input  logic       clk,
    input  logic       rst,
    input  logic [1:0] v_ctrl,
    output real        cell_delay_ps
);

    logic [1:0] v_ctrl_d;

    wire        v_ctrl_changed;

    assign v_ctrl_changed = (v_ctrl != v_ctrl_d);

    // ============================================================
    // Behavioral regulator model
    // v_ctrl = 2'b00 : keep
    // v_ctrl = 2'b10 : voltage down, cell delay = previous delay * scale
    // v_ctrl = 2'b11 : voltage up,   cell delay = previous delay / scale
    // ============================================================
    function automatic real calc_cell_delay_ps (
        input real  cur_cell_delay_ps,
        input logic voltage_up,
        input logic voltage_down
    );
        real next_cell_delay_ps;
        begin
            if (voltage_up && !voltage_down) begin
                next_cell_delay_ps = cur_cell_delay_ps / VOLTAGE_DELAY_SCALE;
                $display("\n\n[%0t] [REGULATOR CELL DELAY] mode=UP   old_delay_ps=%0.3f new_delay_ps=%0.3f scale=%0.3f\n\n",
                        $time, cur_cell_delay_ps, next_cell_delay_ps, VOLTAGE_DELAY_SCALE);
            end
            else if (voltage_down && !voltage_up) begin
                next_cell_delay_ps = cur_cell_delay_ps * VOLTAGE_DELAY_SCALE;
                $display("\n\n[%0t] [REGULATOR CELL DELAY] mode=DOWN old_delay_ps=%0.3f new_delay_ps=%0.3f scale=%0.3f\n\n",
                        $time, cur_cell_delay_ps, next_cell_delay_ps, VOLTAGE_DELAY_SCALE);
            end
            else begin
                next_cell_delay_ps = cur_cell_delay_ps;
            end

            calc_cell_delay_ps = next_cell_delay_ps;
        end
    endfunction

    // Track voltage-control command and update the modeled delay-cell delay.
    // Do not check DVFS handshake here; only decode v_ctrl directly.
    // To avoid applying the same command every clock while v_ctrl is held,
    // update once when v_ctrl changes into a command value.
    always @(posedge clk or posedge rst) begin
        real next_cell_delay_ps;

        if(rst)begin
            cell_delay_ps = INIT_CELL_DELAY_PS;
            v_ctrl_d      <= 2'b00;
        end
        else if(!$isunknown(v_ctrl))begin
            if(v_ctrl_changed)begin
                case (v_ctrl)
                    2'b00: begin
                        next_cell_delay_ps = calc_cell_delay_ps(cell_delay_ps, 1'b0, 1'b0);
                    end

                    2'b10: begin
                        next_cell_delay_ps = calc_cell_delay_ps(cell_delay_ps, 1'b0, 1'b1);
                    end

                    2'b11: begin
                        next_cell_delay_ps = calc_cell_delay_ps(cell_delay_ps, 1'b1, 1'b0);
                    end

                    default: begin
                        next_cell_delay_ps = calc_cell_delay_ps(cell_delay_ps, 1'b0, 1'b0);
                    end
                endcase
                cell_delay_ps = next_cell_delay_ps;
            end

            v_ctrl_d <= v_ctrl;
        end
    end

endmodule


module tb_TD_DVFS_connect_master_simple;

    localparam integer TD_NUM  = 1;
    localparam integer TD_BITS = 1;

    logic clk;
    logic rst;
    logic local_clk;
    logic local_rst;
    logic ACLK;
    logic ROM_clk;
    logic cpu_clk_i;
    logic DRAM_clk;

    logic cpu_clk_o;
    logic [1:0] v_ctrl_idx;
    logic [1:0] v_ctrl;

    localparam real TB_INIT_CELL_DELAY_PS    = 100.0;
    localparam real TB_VOLTAGE_DELAY_SCALE  = 1.05;

    real        tb_cell_delay_ps;




    logic [TD_NUM-1:0] TD_warning_from_local;
    logic [TD_NUM-1:0] TD_warning_force;
    logic              use_force_warning;
    logic [TD_NUM-1:0] TD_warning_to_center;

    logic [TD_NUM-1:0] calibration_valid_req;
    logic [TD_NUM-1:0] calibration_ready_req;
    logic [TD_NUM-1:0] calibration_valid_resp;
    logic [TD_NUM-1:0] calibration_ready_resp;
    logic [TD_NUM-1:0] calibration_updown;

    logic DVFS_req;
    logic DVFS_resp;
    logic DVFS_F_max;
    logic DVFS_F_min;
    logic DVFS_V_tune;

    logic sys_error;
    logic TD_interrupt;

    // AXI interfaces
axi_read_if  center_mmio_axi_r_m_if();
axi_write_if center_mmio_axi_w_m_if();
axi_read_if  center_mmio_axi_r_s_if();
axi_write_if center_mmio_axi_w_s_if();

axi_read_if  center_axi_r_m();     // TD_center DMA master -> dummy memory slave
axi_write_if center_axi_w_m();

axi_read_if  dvfs_axi_r_m_if();
axi_write_if dvfs_axi_w_m_if();
axi_read_if  dvfs_axi_r_s_if();
axi_write_if dvfs_axi_w_s_if();




assign ACLK      = clk;
assign ROM_clk   = clk;
assign DRAM_clk  = clk;
assign cpu_clk_i = clk;

assign TD_warning_to_center = use_force_warning ? TD_warning_force : TD_warning_from_local;

// ============================================================
// Behavioral voltage regulator: v_ctrl -> modeled delay-cell delay
// ============================================================
regulator #(
    .INIT_CELL_DELAY_PS  (TB_INIT_CELL_DELAY_PS),
    .VOLTAGE_DELAY_SCALE (TB_VOLTAGE_DELAY_SCALE)
) u_regulator (
    .clk           (clk),
    .rst           (rst),
    .v_ctrl        (v_ctrl),
    .cell_delay_ps (tb_cell_delay_ps)
);

initial clk = 1'b0;
always #2000 clk = ~clk;

initial local_clk = 1'b0;
always #2000 local_clk = ~local_clk;


// ============================================================
// AXI connect: center MMIO master -> TD_center slave
// ============================================================
axi_read_connect u_center_mmio_r_connect (
    .from_master (center_mmio_axi_r_m_if),
    .to_slave    (center_mmio_axi_r_s_if)
);

axi_write_connect u_center_mmio_w_connect (
    .from_master (center_mmio_axi_w_m_if),
    .to_slave    (center_mmio_axi_w_s_if)
);



// ============================================================
// AXI connect: DVFS MMIO master -> DVFS slave
// ============================================================
axi_read_connect u_dvfs_mmio_r_connect (
    .from_master (dvfs_axi_r_m_if),
    .to_slave    (dvfs_axi_r_s_if)
);

axi_write_connect u_dvfs_mmio_w_connect (
    .from_master (dvfs_axi_w_m_if),
    .to_slave    (dvfs_axi_w_s_if)
);


// ============================================================
// MMIO master_simple for TD_center_unit
// ============================================================
logic        c_req_En;
logic        c_RW;
logic [31:0] c_Addr;
logic [2:0]  c_Size;
logic [2:0]  c_Signalize;
logic [3:0]  c_Len;
logic [3:0]  c_WSTRB;
logic [1:0]  c_BURST;
logic [3:0]  c_ID;
logic        c_response;
logic [31:0] c_read_data;
logic        c_Read_Enable;
logic [3:0]  c_out_ID;
logic [31:0] c_Write_data;
logic        c_Write_Enable;
logic        c_WB;
logic        c_stall;

master_simple u_center_mmio_master (
    .ACLK          (clk),
    .ARESETn       (~rst),
    .axi_r_m       (center_mmio_axi_r_m_if),
    .axi_w_m       (center_mmio_axi_w_m_if),
    .req_En        (c_req_En),
    .RW            (c_RW),
    .Addr          (c_Addr),
    .Size          (c_Size),
    .Signalize     (c_Signalize),
    .Len           (c_Len),
    .WSTRB         (c_WSTRB),
    .BURST         (c_BURST),
    .ID            (c_ID),
    .response      (c_response),
    .read_data     (c_read_data),
    .Read_Enable   (c_Read_Enable),
    .out_ID        (c_out_ID),
    .Write_data    (c_Write_data),
    .Write_Enable  (c_Write_Enable),
    .WB            (c_WB),
    .stall         (c_stall)
);


// ============================================================
// MMIO master_simple for DVFS_unit
// ============================================================
logic        d_req_En;
logic        d_RW;
logic [31:0] d_Addr;
logic [2:0]  d_Size;
logic [2:0]  d_Signalize;
logic [3:0]  d_Len;
logic [3:0]  d_WSTRB;
logic [1:0]  d_BURST;
logic [3:0]  d_ID;
logic        d_response;
logic [31:0] d_read_data;
logic        d_Read_Enable;
logic [3:0]  d_out_ID;
logic [31:0] d_Write_data;
logic        d_Write_Enable;
logic        d_WB;
logic        d_stall;
logic [31:0] rd_tmp;

master_simple u_dvfs_mmio_master (
    .ACLK          (clk),
    .ARESETn       (~rst),
    .axi_r_m       (dvfs_axi_r_m_if),
    .axi_w_m       (dvfs_axi_w_m_if),
    .req_En        (d_req_En),
    .RW            (d_RW),
    .Addr          (d_Addr),
    .Size          (d_Size),
    .Signalize     (d_Signalize),
    .Len           (d_Len),
    .WSTRB         (d_WSTRB),
    .BURST         (d_BURST),
    .ID            (d_ID),
    .response      (d_response),
    .read_data     (d_read_data),
    .Read_Enable   (d_Read_Enable),
    .out_ID        (d_out_ID),
    .Write_data    (d_Write_data),
    .Write_Enable  (d_Write_Enable),
    .WB            (d_WB),
    .stall         (d_stall)
);


// ============================================================
// DUTs
// ============================================================
TD_center_unit #(
    .TD_NUM  (TD_NUM),
    .TD_BITS (TD_BITS)
) u_center (
    .clk                 (clk),
    .rst                 (rst),
    .TD_warning              (TD_warning_to_center),
    .calibration_valid_req   (calibration_valid_req),
    .calibration_ready_req   (calibration_ready_req),
    .calibration_valid_resp  (calibration_valid_resp),
    .calibration_ready_resp  (calibration_ready_resp),
    .calibration_updown      (calibration_updown),
    .DVFS_req            (DVFS_req),
    .DVFS_resp           (DVFS_resp),
    .DVFS_F_max          (DVFS_F_max),
    .DVFS_F_min          (DVFS_F_min),
    .DVFS_V_tune         (DVFS_V_tune),

    .axi_r_m             (center_axi_r_m),
    .axi_w_m             (center_axi_w_m),

    .axi_r_s             (center_mmio_axi_r_s_if),
    .axi_w_s             (center_mmio_axi_w_s_if),

    .sys_error           (sys_error),
    .TD_interrupt        (TD_interrupt)
);

TD_loacl_unit #(
    .FIXED_STAGES      (20),
    .CONFIG_STAGES     (32),
    .MODE_W            (6),
    .SIM_CELL_DELAY_PS (TB_INIT_CELL_DELAY_PS),
    .CALIB_INIT_VALUE  (16)
) u_td_local0 (
    .local_clk              (local_clk),
    .local_rst              (local_rst),
    .center_clk             (clk),
    .center_rst             (rst),

    .calibration_valid_req  (calibration_valid_req[0]),
    .calibration_ready_req  (calibration_ready_req[0]),
    .calibration_valid_resp (calibration_valid_resp[0]),
    .calibration_ready_resp (calibration_ready_resp[0]),

    .calibration_updown     (calibration_updown[0]),

`ifndef SYNTHESIS
    .sim_cell_delay_ps      (tb_cell_delay_ps),
`endif

    .TD_warning             (TD_warning_from_local[0])
);

DVFS_unit #(
    .v_stage       (4),
    .f_stage       (4),
    .V_fine_stage  (32),
    .TD_NUM        (TD_NUM)
) u_dvfs (
    .clk           (clk),
    .rst           (rst),
    .ACLK          (ACLK),
    .ROM_clk       (ROM_clk),
    .cpu_clk_i     (cpu_clk_i),
    .DRAM_clk      (DRAM_clk),
    .cpu_clk_o     (cpu_clk_o),
    .v_ctrl_idx    (v_ctrl_idx),
    .v_ctrl        (v_ctrl),

    .axi_r_s       (dvfs_axi_r_s_if),
    .axi_w_s       (dvfs_axi_w_s_if),

    .DVFS_req      (DVFS_req),
    .DVFS_resp     (DVFS_resp),
    .DVFS_F_max    (DVFS_F_max),
    .DVFS_F_min    (DVFS_F_min),
    .DVFS_V_tune   (DVFS_V_tune)
);


// ============================================================
// DMA source memory A: only handles AXI read from DMA
// ============================================================
axi_read_if  dma_src_axi_r_s_if();
axi_write_if dma_src_dummy_w_if();

axi_read_connect u_dma_src_r_connect (
    .from_master (center_axi_r_m),
    .to_slave    (dma_src_axi_r_s_if)
);

logic        src_mem_Read_Enable;
logic [31:0] src_mem_Addr;
logic [31:0] src_mem_Write_data;
logic        src_mem_Write_Enable;
logic [3:0]  src_mem_WSTRB;
logic [31:0] src_mem_read_data;

assign src_mem_read_data = 32'hA000_0000 ^ src_mem_Addr;

slave_simple u_dma_src_mem (
    .ACLK           (clk),
    .ARESETn        (~rst),
    .axi_r_s        (dma_src_axi_r_s_if),
    .axi_w_s        (dma_src_dummy_w_if),
    .stall_W        (1'b1),   // source memory 不收 write
    .stall_R        (1'b0),
    .in_miss        (1'b0),
    .in_hit         (1'b1),
    .read_data      (src_mem_read_data),
    .Read_Enable    (src_mem_Read_Enable),
    .Addr           (src_mem_Addr),
    .Write_data     (src_mem_Write_data),
    .Write_Enable   (src_mem_Write_Enable),
    .out_WSTRB      (src_mem_WSTRB)
);


// ============================================================
// DMA target memory B: only handles AXI write from DMA
// ============================================================
axi_read_if  dma_dst_dummy_r_if();
axi_write_if dma_dst_axi_w_s_if();

axi_write_connect u_dma_dst_w_connect (
    .from_master (center_axi_w_m),
    .to_slave    (dma_dst_axi_w_s_if)
);

logic        dst_mem_Read_Enable;
logic [31:0] dst_mem_Addr;
logic [31:0] dst_mem_Write_data;
logic        dst_mem_Write_Enable;
logic [3:0]  dst_mem_WSTRB;
logic [31:0] dst_mem_read_data;

assign dst_mem_read_data = 32'hB000_0000 ^ dst_mem_Addr;

slave_simple u_dma_dst_mem (
    .ACLK           (clk),
    .ARESETn        (~rst),
    .axi_r_s        (dma_dst_dummy_r_if),
    .axi_w_s        (dma_dst_axi_w_s_if),
    .stall_W        (1'b0),
    .stall_R        (1'b1),   // target memory 不收 read
    .in_miss        (1'b0),
    .in_hit         (1'b1),
    .read_data      (dst_mem_read_data),
    .Read_Enable    (dst_mem_Read_Enable),
    .Addr           (dst_mem_Addr),
    .Write_data     (dst_mem_Write_data),
    .Write_Enable   (dst_mem_Write_Enable),
    .out_WSTRB      (dst_mem_WSTRB)
);


task automatic flow_msg(input string msg);
    begin
        $display("");
        $display("============================================================");
        $display("[%0t] FLOW: %s", $time, msg);
        $display("============================================================");
    end
endtask
    // ============================================================
    // AXI MMIO tasks through master_simple
    // ============================================================
task automatic center_mmio_write(input logic [31:0] addr, input logic [31:0] data);
    begin
        $display("[%0t] TASK center_mmio_write START addr=0x%08h data=0x%08h", $time, addr, data);

        @(negedge clk);
        c_Addr         = addr;
        c_Write_data   = data;
        c_RW           = 1'b1;
        c_req_En       = 1'b1;
        c_Write_Enable = 1'b1;

        wait (c_response === 1'b1);
        @(posedge clk);
        @(negedge clk);
        c_req_En = 1'b0;

        wait (c_WB === 1'b1);
        @(posedge clk);
        @(negedge clk);
        c_Write_Enable = 1'b0;
        c_RW           = 1'b0;
        c_Addr         = 32'd0;
        c_Write_data   = 32'd0;

        $display("[%0t] TASK center_mmio_write DONE  addr=0x%08h data=0x%08h", $time, addr, data);
    end
endtask

task automatic dvfs_mmio_write(input logic [31:0] addr, input logic [31:0] data);
    begin
        $display("[%0t] TASK dvfs_mmio_write START addr=0x%08h data=0x%08h", $time, addr, data);

        @(negedge clk);
        d_Addr         = addr;
        d_Write_data   = data;
        d_RW           = 1'b1;
        d_req_En       = 1'b1;
        d_Write_Enable = 1'b1;

        wait (d_response === 1'b1);
        @(posedge clk);
        @(negedge clk);
        d_req_En = 1'b0;

        wait (d_WB === 1'b1);
        @(posedge clk);
        @(negedge clk);
        d_Write_Enable = 1'b0;
        d_RW           = 1'b0;
        d_Addr         = 32'd0;
        d_Write_data   = 32'd0;

        $display("[%0t] TASK dvfs_mmio_write DONE  addr=0x%08h data=0x%08h", $time, addr, data);
    end
endtask

task automatic center_mmio_read(input logic [31:0] addr, output logic [31:0] data);
    begin
        $display("[%0t] TASK center_mmio_read START addr=0x%08h", $time, addr);

        @(negedge clk);
        c_Addr         = addr;
        c_RW           = 1'b0;
        c_req_En       = 1'b1;
        c_Write_Enable = 1'b0;

        wait (c_response === 1'b1);
        @(posedge clk);
        @(negedge clk);
        c_req_En = 1'b0;

        wait (c_Read_Enable === 1'b1);
        data = c_read_data;
        @(posedge clk);
        @(negedge clk);
        c_Addr = 32'd0;

        $display("[%0t] TASK center_mmio_read DONE  addr=0x%08h data=0x%08h", $time, addr, data);
    end
endtask

    task automatic wait_center_state(input logic [15:0] target_state, input integer timeout_cycle);
        integer i;
        begin
            for (i = 0; i < timeout_cycle; i = i + 1) begin
                @(posedge clk);
                if (u_center.state_raw == target_state) begin
                    $display("[%0t] PASS wait center state = 0x%04h", $time, target_state);
                    return;
                end
            end
            $fatal(1, "[%0t] TIMEOUT waiting center state 0x%04h, now = 0x%04h", $time, target_state, u_center.state_raw);
        end
    endtask

    task automatic tb_init_flow();
        begin
            logic [31:0] rd_tmp;
            flow_msg("STEP 0 - boot at first-stage base frequency");

            // DVFS default mode 先設 mode_up，讓 power-on / init 可以往高頻走
            dvfs_mmio_write(`DVFS_mode_setup_reg, 32'd1);

            flow_msg("STEP 1 - read previous calibration point and setup TD center MMIO registers");

            center_mmio_write(`sysA_TD_DVFS_start_reg,        32'd1);
            center_mmio_write(`sysA_TD_calib_start_reg,       32'd1);
            center_mmio_write(`sysA_TD_error_margin_reg,      32'd2);
            center_mmio_write(`sysA_TD_warning_margin_reg,    32'd1);
            center_mmio_write(`sysA_TD_warning_interrupt_En,  32'd1);
            center_mmio_write(`sysA_TD_voltage_only_mask_reg, 32'd0);
            center_mmio_write(`sysA_TD_calib_idx_reg,         32'd0);

            flow_msg("STEP 2 - load test program from Flash to memory");

            center_mmio_write(`sysA_testProg_srcA, 32'h1000_0000);
            center_mmio_write(`sysA_testProg_trgA, 32'h2000_0000);
            center_mmio_write(`sysA_testProg_len,  32'd16);

            center_mmio_read(`sysA_TD_DVFS_start_reg, rd_tmp);
            $display("[%0t] READ TD_DVFS_start = 0x%08h", $time, rd_tmp);

            flow_msg("STEP 3 - kick TD center FSM");

            center_mmio_write(`sysA_cause_reg, {STD_S0_set, 16'h0000});
        end
    endtask

        task automatic run_noerror_test_loop(input string loop_name);
        begin
            wait_center_state(STD_S1_init, 100);
            flow_msg({loop_name, " - STEP 4: increase frequency to maximum frequency"});

            wait_center_state(STD_S2_load, 300);
            flow_msg({loop_name, " - STEP 5: loading test program"});

            wait_center_state(STD_S3_FTest, 300);
            flow_msg({loop_name, " - STEP 6: test program load done, enter frequency test"});

            flow_msg({loop_name, " - STEP 7: FTest PASS, update state to STD_S4_RF"});

            repeat (20) @(posedge clk);

            TD_warning_force = 1'b0;
            sys_error        = 1'b0;

            center_mmio_write(`sysA_cause_reg, {STD_S4_RF, 16'h0000});
            wait_center_state(STD_S4_RF, 300);

            flow_msg({loop_name, " - STEP 8: STD_S4_RF reduce voltage"});

            wait_center_state(STD_S5_STest, 500);

            flow_msg({loop_name, " - STEP 9: STD_S5_STest PASS, update state to STD_S6_noError"});

            center_mmio_write(`sysA_cause_reg, {STD_S6_noError, 16'h0000});
            //wait_center_state(STD_S6_noError, 300);
        end
    endtask
    // ============================================================
    // Test sequence
    // ============================================================
    


initial begin
    rst               = 1'b1;
    local_rst         = 1'b1;
    sys_error         = 1'b0;
    use_force_warning = 1'b0;
    TD_warning_force  = '0;

    c_req_En          = 1'b0;
    c_RW              = 1'b0;
    c_Addr            = 32'd0;
    c_Size            = 3'd2;
    c_Signalize       = 3'd0;
    c_Len             = 4'd0;
    c_WSTRB           = 4'hF;
    c_BURST           = 2'b01;
    c_ID              = 4'h1;
    c_Write_data      = 32'd0;
    c_Write_Enable    = 1'b0;
    c_stall           = 1'b0;

    d_req_En          = 1'b0;
    d_RW              = 1'b0;
    d_Addr            = 32'd0;
    d_Size            = 3'd2;
    d_Signalize       = 3'd0;
    d_Len             = 4'd0;
    d_WSTRB           = 4'hF;
    d_BURST           = 2'b01;
    d_ID              = 4'h2;
    d_Write_data      = 32'd0;
    d_Write_Enable    = 1'b0;
    d_stall           = 1'b0;

    repeat (8) @(posedge clk);
    rst       = 1'b0;
    local_rst = 1'b0;
    repeat (5) @(posedge clk);

    tb_init_flow();

    for (int i = 1; i <= 3; i++) begin
        run_noerror_test_loop($sformatf("LOOP %0d", i));
    end

    flow_msg("LOOP 4 - wait next FTest for final error round");

    wait_center_state(STD_S1_init, 300);
    flow_msg("LOOP 4 - STEP 4: increase frequency to maximum frequency");

    wait_center_state(STD_S2_load, 500);
    flow_msg("LOOP 4 - STEP 5: loading test program");

    wait_center_state(STD_S3_FTest, 500);
    flow_msg("LOOP 4 - STEP 6: load done, enter FTest");

    flow_msg("LOOP 4 - FTest FAIL, update state to STD_S7_yesError");

    repeat (20) @(posedge clk);

    TD_warning_force = 1'b0;
    sys_error        = 1'b0;

    center_mmio_write(`sysA_cause_reg, {STD_S7_yesError, 16'h0000});
    wait_center_state(STD_S7_yesError, 300);

    repeat (3) @(posedge clk);
    sys_error = 1'b0;

    flow_msg("LOOP 4 - recover safe voltage / set timing margin");

    repeat (8) @(posedge clk);
    TD_warning_force = 1'b0;

    wait_center_state(STD_S8_marginSet, 500);

    flow_msg("DONE - finish calibration and return idle");

    wait_center_state(STD_idal, 500);

    flow_msg("DONE - boot complete");

    $display("[%0t] TEST PASS", $time);
    $finish;
end

      initial begin
        $fsdbDumpfile("TD.fsdb");
        $fsdbDumpMDA();
        $fsdbDumpvars();
      end
      initial begin
        $monitor("[%0t] center_state=%04h dvfs_state=%0d DVFS_req=%0b DVFS_resp=%0b c_req=%0b c_resp=%0b c_WB=%0b d_req=%0b d_resp=%0b d_WB=%0b cal_vreq=%0b cal_rreq=%0b cal_vresp=%0b cal_rresp=%0b cal_updown=%0b TD_warn=%0b sys_error=%0b cell_delay_ps=%0.3f v_ctrl=%b",
                $time,
                u_center.state_raw,
                u_dvfs.state,
                DVFS_req,
                DVFS_resp,
                c_req_En,
                c_response,
                c_WB,
                d_req_En,
                d_response,
                d_WB,
                calibration_valid_req,
                calibration_ready_req,
                calibration_valid_resp,
                calibration_ready_resp,
                calibration_updown,
                TD_warning_to_center,
                sys_error,
                tb_cell_delay_ps,
                v_ctrl);
        end
endmodule




// `timescale 1ps/1ps

// // ============================================================
// // TB for TD_center_unit + TD_loacl_unit + DVFS_unit
// // MMIO is driven by master_simple, not hierarchical force.
// //
// // Compile example:
// //   vcs -sverilog \
// //       AXI_interface.svh master_simple.sv slave_simple.sv simple_axi_dma.sv \
// //       TD_center_unit.sv TD_loacal_unit.sv DVFS_unit.sv \
// //       tb_TD_DVFS_connect_master_simple.sv
// //
// // If you only want to compile this TB without your AXI interface file,
// // define TB_AXI_IF_STUB. Do NOT define it when using your real AXI interface.
// // ============================================================



// `include "../src/src_clean_baseline/IP/TD/TD_MAP.svh"

// module axi_read_connect (
//     axi_read_if  from_master,
//     axi_read_if  to_slave
// );
//     assign to_slave.ARID_s     = from_master.ARID_m;
//     assign to_slave.ARADDR_s   = from_master.ARADDR_m;
//     assign to_slave.ARLEN_s    = from_master.ARLEN_m;
//     assign to_slave.ARSIZE_s   = from_master.ARSIZE_m;
//     assign to_slave.ARBURST_s  = from_master.ARBURST_m;
//     assign to_slave.ARVALID_s  = from_master.ARVALID_m;
//     assign from_master.ARREADY_m = to_slave.ARREADY_s;

//     assign from_master.RID_m     = to_slave.RID_s;
//     assign from_master.RDATA_m   = to_slave.RDATA_s;
//     assign from_master.RRESP_m   = to_slave.RRESP_s;
//     assign from_master.RLAST_m   = to_slave.RLAST_s;
//     assign from_master.RVALID_m  = to_slave.RVALID_s;
//     assign to_slave.RREADY_s     = from_master.RREADY_m;
// endmodule


// module axi_write_connect (
//     axi_write_if from_master,
//     axi_write_if to_slave
// );
//     assign to_slave.AWID_s      = from_master.AWID_m;
//     assign to_slave.AWADDR_s    = from_master.AWADDR_m;
//     assign to_slave.AWLEN_s     = from_master.AWLEN_m;
//     assign to_slave.AWSIZE_s    = from_master.AWSIZE_m;
//     assign to_slave.AWBURST_s   = from_master.AWBURST_m;
//     assign to_slave.AWVALID_s   = from_master.AWVALID_m;
//     assign from_master.AWREADY_m = to_slave.AWREADY_s;

//     assign to_slave.WDATA_s     = from_master.WDATA_m;
//     assign to_slave.WSTRB_s     = from_master.WSTRB_m;
//     assign to_slave.WLAST_s     = from_master.WLAST_m;
//     assign to_slave.WVALID_s    = from_master.WVALID_m;
//     assign from_master.WREADY_m = to_slave.WREADY_s;

//     assign from_master.BID_m    = to_slave.BID_s;
//     assign from_master.BRESP_m  = to_slave.BRESP_s;
//     assign from_master.BVALID_m = to_slave.BVALID_s;
//     assign to_slave.BREADY_s    = from_master.BREADY_m;
// endmodule


// module tb_TD_DVFS_connect_master_simple;

//     localparam integer TD_NUM  = 1;
//     localparam integer TD_BITS = 1;

//     logic clk;
//     logic rst;
//     logic local_clk;
//     logic local_rst;
//     logic ACLK;
//     logic ROM_clk;
//     logic cpu_clk_i;
//     logic DRAM_clk;

//     logic cpu_clk_o;
//     logic [1:0] v_ctrl_idx;
//     logic [1:0] v_ctrl;

//     localparam real TB_INIT_CELL_DELAY_PS    = 200.0;
//     localparam real TB_VOLTAGE_DELAY_SCALE  = 1.05;

//     real        tb_cell_delay_ps;
//     logic [1:0] v_ctrl_d;

//     wire        v_ctrl_changed;

//     assign v_ctrl_changed = (v_ctrl != v_ctrl_d);

//     // ============================================================
//     // Delay-cell model helper for TB
//     // v_ctrl = 2'b00 : keep
//     // v_ctrl = 2'b10 : voltage down, cell delay = previous delay / 1.05
//     // v_ctrl = 2'b11 : voltage up,   cell delay = previous delay * 1.05
//     // ============================================================
//     function automatic real calc_cell_delay_ps (
//         input real  cur_cell_delay_ps,
//         input logic voltage_up,
//         input logic voltage_down
//     );
//         real next_cell_delay_ps;
//         begin
//             if (voltage_up && !voltage_down) begin
//                 next_cell_delay_ps = cur_cell_delay_ps / TB_VOLTAGE_DELAY_SCALE;
//                 $display("\n\n[%0t] [TB CELL DELAY] mode=UP   old_delay_ps=%0.3f new_delay_ps=%0.3f scale=%0.3f\n\n",
//                         $time, cur_cell_delay_ps, next_cell_delay_ps, TB_VOLTAGE_DELAY_SCALE);
//             end
//             else if (voltage_down && !voltage_up) begin
//                 next_cell_delay_ps = cur_cell_delay_ps * TB_VOLTAGE_DELAY_SCALE;
//                 $display("\n\n[%0t] [TB CELL DELAY] mode=DOWN old_delay_ps=%0.3f new_delay_ps=%0.3f scale=%0.3f\n\n",
//                         $time, cur_cell_delay_ps, next_cell_delay_ps, TB_VOLTAGE_DELAY_SCALE);
//             end
//             else begin
//                 next_cell_delay_ps = cur_cell_delay_ps;

//             end

//             calc_cell_delay_ps = next_cell_delay_ps;
//         end
//     endfunction




//     logic [TD_NUM-1:0] TD_warning_from_local;
//     logic [TD_NUM-1:0] TD_warning_force;
//     logic              use_force_warning;
//     logic [TD_NUM-1:0] TD_warning_to_center;

//     logic [TD_NUM-1:0] calibration_valid_req;
//     logic [TD_NUM-1:0] calibration_ready_req;
//     logic [TD_NUM-1:0] calibration_valid_resp;
//     logic [TD_NUM-1:0] calibration_ready_resp;
//     logic [TD_NUM-1:0] calibration_updown;

//     logic DVFS_req;
//     logic DVFS_resp;
//     logic DVFS_F_max;
//     logic DVFS_F_min;
//     logic DVFS_V_tune;

//     logic sys_error;
//     logic TD_interrupt;

//     // AXI interfaces
// axi_read_if  center_mmio_axi_r_m_if();
// axi_write_if center_mmio_axi_w_m_if();
// axi_read_if  center_mmio_axi_r_s_if();
// axi_write_if center_mmio_axi_w_s_if();

// axi_read_if  center_axi_r_m();     // TD_center DMA master -> dummy memory slave
// axi_write_if center_axi_w_m();

// axi_read_if  dvfs_axi_r_m_if();
// axi_write_if dvfs_axi_w_m_if();
// axi_read_if  dvfs_axi_r_s_if();
// axi_write_if dvfs_axi_w_s_if();




// assign ACLK      = clk;
// assign ROM_clk   = clk;
// assign DRAM_clk  = clk;
// assign cpu_clk_i = clk;

// assign TD_warning_to_center = use_force_warning ? TD_warning_force : TD_warning_from_local;

// // Track voltage-control command in TB and update the modeled delay-cell delay.
// // Do not check DVFS handshake here; only decode v_ctrl directly.
// // To avoid applying the same command every clock while v_ctrl is held,
// // update once when v_ctrl changes into a command value.
// //   2'b00 : keep
// //   2'b10 : voltage down one step
// //   2'b11 : voltage up one step
// always @(posedge clk or posedge rst) begin
//     real next_cell_delay_ps;

//     if(rst)begin
//         tb_cell_delay_ps = TB_INIT_CELL_DELAY_PS;
//         v_ctrl_d         <= 2'b00;
//     end
//     else if(!$isunknown(v_ctrl))begin
//         if(v_ctrl_changed)begin
//             case (v_ctrl)
//                 2'b00: begin
//                     next_cell_delay_ps = calc_cell_delay_ps(tb_cell_delay_ps, 1'b0, 1'b0);
//                 end

//                 2'b10: begin
//                     next_cell_delay_ps = calc_cell_delay_ps(tb_cell_delay_ps, 1'b0, 1'b1);
//                 end

//                 2'b11: begin
//                     next_cell_delay_ps = calc_cell_delay_ps(tb_cell_delay_ps, 1'b1, 1'b0);
//                 end

//                 default: begin
//                     next_cell_delay_ps = calc_cell_delay_ps(tb_cell_delay_ps, 1'b0, 1'b0);
//                 end
//             endcase
//             tb_cell_delay_ps = next_cell_delay_ps;
//         end

//         v_ctrl_d <= v_ctrl;
//     end
// end

// initial clk = 1'b0;
// always #5000 clk = ~clk;

// initial local_clk = 1'b0;
// always #3500 local_clk = ~local_clk;


// // ============================================================
// // AXI connect: center MMIO master -> TD_center slave
// // ============================================================
// axi_read_connect u_center_mmio_r_connect (
//     .from_master (center_mmio_axi_r_m_if),
//     .to_slave    (center_mmio_axi_r_s_if)
// );

// axi_write_connect u_center_mmio_w_connect (
//     .from_master (center_mmio_axi_w_m_if),
//     .to_slave    (center_mmio_axi_w_s_if)
// );



// // ============================================================
// // AXI connect: DVFS MMIO master -> DVFS slave
// // ============================================================
// axi_read_connect u_dvfs_mmio_r_connect (
//     .from_master (dvfs_axi_r_m_if),
//     .to_slave    (dvfs_axi_r_s_if)
// );

// axi_write_connect u_dvfs_mmio_w_connect (
//     .from_master (dvfs_axi_w_m_if),
//     .to_slave    (dvfs_axi_w_s_if)
// );


// // ============================================================
// // MMIO master_simple for TD_center_unit
// // ============================================================
// logic        c_req_En;
// logic        c_RW;
// logic [31:0] c_Addr;
// logic [2:0]  c_Size;
// logic [2:0]  c_Signalize;
// logic [3:0]  c_Len;
// logic [3:0]  c_WSTRB;
// logic [1:0]  c_BURST;
// logic [3:0]  c_ID;
// logic        c_response;
// logic [31:0] c_read_data;
// logic        c_Read_Enable;
// logic [3:0]  c_out_ID;
// logic [31:0] c_Write_data;
// logic        c_Write_Enable;
// logic        c_WB;
// logic        c_stall;

// master_simple u_center_mmio_master (
//     .ACLK          (clk),
//     .ARESETn       (~rst),
//     .axi_r_m       (center_mmio_axi_r_m_if),
//     .axi_w_m       (center_mmio_axi_w_m_if),
//     .req_En        (c_req_En),
//     .RW            (c_RW),
//     .Addr          (c_Addr),
//     .Size          (c_Size),
//     .Signalize     (c_Signalize),
//     .Len           (c_Len),
//     .WSTRB         (c_WSTRB),
//     .BURST         (c_BURST),
//     .ID            (c_ID),
//     .response      (c_response),
//     .read_data     (c_read_data),
//     .Read_Enable   (c_Read_Enable),
//     .out_ID        (c_out_ID),
//     .Write_data    (c_Write_data),
//     .Write_Enable  (c_Write_Enable),
//     .WB            (c_WB),
//     .stall         (c_stall)
// );


// // ============================================================
// // MMIO master_simple for DVFS_unit
// // ============================================================
// logic        d_req_En;
// logic        d_RW;
// logic [31:0] d_Addr;
// logic [2:0]  d_Size;
// logic [2:0]  d_Signalize;
// logic [3:0]  d_Len;
// logic [3:0]  d_WSTRB;
// logic [1:0]  d_BURST;
// logic [3:0]  d_ID;
// logic        d_response;
// logic [31:0] d_read_data;
// logic        d_Read_Enable;
// logic [3:0]  d_out_ID;
// logic [31:0] d_Write_data;
// logic        d_Write_Enable;
// logic        d_WB;
// logic        d_stall;
// logic [31:0] rd_tmp;

// master_simple u_dvfs_mmio_master (
//     .ACLK          (clk),
//     .ARESETn       (~rst),
//     .axi_r_m       (dvfs_axi_r_m_if),
//     .axi_w_m       (dvfs_axi_w_m_if),
//     .req_En        (d_req_En),
//     .RW            (d_RW),
//     .Addr          (d_Addr),
//     .Size          (d_Size),
//     .Signalize     (d_Signalize),
//     .Len           (d_Len),
//     .WSTRB         (d_WSTRB),
//     .BURST         (d_BURST),
//     .ID            (d_ID),
//     .response      (d_response),
//     .read_data     (d_read_data),
//     .Read_Enable   (d_Read_Enable),
//     .out_ID        (d_out_ID),
//     .Write_data    (d_Write_data),
//     .Write_Enable  (d_Write_Enable),
//     .WB            (d_WB),
//     .stall         (d_stall)
// );


// // ============================================================
// // DUTs
// // ============================================================
// TD_center_unit #(
//     .TD_NUM  (TD_NUM),
//     .TD_BITS (TD_BITS)
// ) u_center (
//     .clk                 (clk),
//     .rst                 (rst),
//     .TD_warning              (TD_warning_to_center),
//     .calibration_valid_req   (calibration_valid_req),
//     .calibration_ready_req   (calibration_ready_req),
//     .calibration_valid_resp  (calibration_valid_resp),
//     .calibration_ready_resp  (calibration_ready_resp),
//     .calibration_updown      (calibration_updown),
//     .DVFS_req            (DVFS_req),
//     .DVFS_resp           (DVFS_resp),
//     .DVFS_F_max          (DVFS_F_max),
//     .DVFS_F_min          (DVFS_F_min),
//     .DVFS_V_tune         (DVFS_V_tune),

//     .axi_r_m             (center_axi_r_m),
//     .axi_w_m             (center_axi_w_m),

//     .axi_r_s             (center_mmio_axi_r_s_if),
//     .axi_w_s             (center_mmio_axi_w_s_if),

//     .sys_error           (sys_error),
//     .TD_interrupt        (TD_interrupt)
// );

// TD_loacl_unit #(
//     .FIXED_STAGES      (20),
//     .CONFIG_STAGES     (32),
//     .MODE_W            (6),
//     .SIM_CELL_DELAY_PS (TB_INIT_CELL_DELAY_PS),
//     .CALIB_INIT_VALUE  (16)
// ) u_td_local0 (
//     .local_clk              (local_clk),
//     .local_rst              (local_rst),
//     .center_clk             (clk),
//     .center_rst             (rst),

//     .calibration_valid_req  (calibration_valid_req[0]),
//     .calibration_ready_req  (calibration_ready_req[0]),
//     .calibration_valid_resp (calibration_valid_resp[0]),
//     .calibration_ready_resp (calibration_ready_resp[0]),

//     .calibration_updown     (calibration_updown[0]),

// `ifndef SYNTHESIS
//     .sim_cell_delay_ps      (tb_cell_delay_ps),
// `endif

//     .TD_warning             (TD_warning_from_local[0])
// );

// DVFS_unit #(
//     .v_stage       (4),
//     .f_stage       (4),
//     .V_fine_stage  (32),
//     .TD_NUM        (TD_NUM)
// ) u_dvfs (
//     .clk           (clk),
//     .rst           (rst),
//     .ACLK          (ACLK),
//     .ROM_clk       (ROM_clk),
//     .cpu_clk_i     (cpu_clk_i),
//     .DRAM_clk      (DRAM_clk),
//     .cpu_clk_o     (cpu_clk_o),
//     .v_ctrl_idx    (v_ctrl_idx),
//     .v_ctrl        (v_ctrl),

//     .axi_r_s       (dvfs_axi_r_s_if),
//     .axi_w_s       (dvfs_axi_w_s_if),

//     .DVFS_req      (DVFS_req),
//     .DVFS_resp     (DVFS_resp),
//     .DVFS_F_max    (DVFS_F_max),
//     .DVFS_F_min    (DVFS_F_min),
//     .DVFS_V_tune   (DVFS_V_tune)
// );


// // ============================================================
// // DMA source memory A: only handles AXI read from DMA
// // ============================================================
// axi_read_if  dma_src_axi_r_s_if();
// axi_write_if dma_src_dummy_w_if();

// axi_read_connect u_dma_src_r_connect (
//     .from_master (center_axi_r_m),
//     .to_slave    (dma_src_axi_r_s_if)
// );

// logic        src_mem_Read_Enable;
// logic [31:0] src_mem_Addr;
// logic [31:0] src_mem_Write_data;
// logic        src_mem_Write_Enable;
// logic [3:0]  src_mem_WSTRB;
// logic [31:0] src_mem_read_data;

// assign src_mem_read_data = 32'hA000_0000 ^ src_mem_Addr;

// slave_simple u_dma_src_mem (
//     .ACLK           (clk),
//     .ARESETn        (~rst),
//     .axi_r_s        (dma_src_axi_r_s_if),
//     .axi_w_s        (dma_src_dummy_w_if),
//     .stall_W        (1'b1),   // source memory 不收 write
//     .stall_R        (1'b0),
//     .in_miss        (1'b0),
//     .in_hit         (1'b1),
//     .read_data      (src_mem_read_data),
//     .Read_Enable    (src_mem_Read_Enable),
//     .Addr           (src_mem_Addr),
//     .Write_data     (src_mem_Write_data),
//     .Write_Enable   (src_mem_Write_Enable),
//     .out_WSTRB      (src_mem_WSTRB)
// );


// // ============================================================
// // DMA target memory B: only handles AXI write from DMA
// // ============================================================
// axi_read_if  dma_dst_dummy_r_if();
// axi_write_if dma_dst_axi_w_s_if();

// axi_write_connect u_dma_dst_w_connect (
//     .from_master (center_axi_w_m),
//     .to_slave    (dma_dst_axi_w_s_if)
// );

// logic        dst_mem_Read_Enable;
// logic [31:0] dst_mem_Addr;
// logic [31:0] dst_mem_Write_data;
// logic        dst_mem_Write_Enable;
// logic [3:0]  dst_mem_WSTRB;
// logic [31:0] dst_mem_read_data;

// assign dst_mem_read_data = 32'hB000_0000 ^ dst_mem_Addr;

// slave_simple u_dma_dst_mem (
//     .ACLK           (clk),
//     .ARESETn        (~rst),
//     .axi_r_s        (dma_dst_dummy_r_if),
//     .axi_w_s        (dma_dst_axi_w_s_if),
//     .stall_W        (1'b0),
//     .stall_R        (1'b1),   // target memory 不收 read
//     .in_miss        (1'b0),
//     .in_hit         (1'b1),
//     .read_data      (dst_mem_read_data),
//     .Read_Enable    (dst_mem_Read_Enable),
//     .Addr           (dst_mem_Addr),
//     .Write_data     (dst_mem_Write_data),
//     .Write_Enable   (dst_mem_Write_Enable),
//     .out_WSTRB      (dst_mem_WSTRB)
// );


// task automatic flow_msg(input string msg);
//     begin
//         $display("");
//         $display("============================================================");
//         $display("[%0t] FLOW: %s", $time, msg);
//         $display("============================================================");
//     end
// endtask
//     // ============================================================
//     // AXI MMIO tasks through master_simple
//     // ============================================================
// task automatic center_mmio_write(input logic [31:0] addr, input logic [31:0] data);
//     begin
//         $display("[%0t] TASK center_mmio_write START addr=0x%08h data=0x%08h", $time, addr, data);

//         @(negedge clk);
//         c_Addr         = addr;
//         c_Write_data   = data;
//         c_RW           = 1'b1;
//         c_req_En       = 1'b1;
//         c_Write_Enable = 1'b1;

//         wait (c_response === 1'b1);
//         @(posedge clk);
//         @(negedge clk);
//         c_req_En = 1'b0;

//         wait (c_WB === 1'b1);
//         @(posedge clk);
//         @(negedge clk);
//         c_Write_Enable = 1'b0;
//         c_RW           = 1'b0;
//         c_Addr         = 32'd0;
//         c_Write_data   = 32'd0;

//         $display("[%0t] TASK center_mmio_write DONE  addr=0x%08h data=0x%08h", $time, addr, data);
//     end
// endtask

// task automatic dvfs_mmio_write(input logic [31:0] addr, input logic [31:0] data);
//     begin
//         $display("[%0t] TASK dvfs_mmio_write START addr=0x%08h data=0x%08h", $time, addr, data);

//         @(negedge clk);
//         d_Addr         = addr;
//         d_Write_data   = data;
//         d_RW           = 1'b1;
//         d_req_En       = 1'b1;
//         d_Write_Enable = 1'b1;

//         wait (d_response === 1'b1);
//         @(posedge clk);
//         @(negedge clk);
//         d_req_En = 1'b0;

//         wait (d_WB === 1'b1);
//         @(posedge clk);
//         @(negedge clk);
//         d_Write_Enable = 1'b0;
//         d_RW           = 1'b0;
//         d_Addr         = 32'd0;
//         d_Write_data   = 32'd0;

//         $display("[%0t] TASK dvfs_mmio_write DONE  addr=0x%08h data=0x%08h", $time, addr, data);
//     end
// endtask

// task automatic center_mmio_read(input logic [31:0] addr, output logic [31:0] data);
//     begin
//         $display("[%0t] TASK center_mmio_read START addr=0x%08h", $time, addr);

//         @(negedge clk);
//         c_Addr         = addr;
//         c_RW           = 1'b0;
//         c_req_En       = 1'b1;
//         c_Write_Enable = 1'b0;

//         wait (c_response === 1'b1);
//         @(posedge clk);
//         @(negedge clk);
//         c_req_En = 1'b0;

//         wait (c_Read_Enable === 1'b1);
//         data = c_read_data;
//         @(posedge clk);
//         @(negedge clk);
//         c_Addr = 32'd0;

//         $display("[%0t] TASK center_mmio_read DONE  addr=0x%08h data=0x%08h", $time, addr, data);
//     end
// endtask

//     task automatic wait_center_state(input logic [15:0] target_state, input integer timeout_cycle);
//         integer i;
//         begin
//             for (i = 0; i < timeout_cycle; i = i + 1) begin
//                 @(posedge clk);
//                 if (u_center.state_raw == target_state) begin
//                     $display("[%0t] PASS wait center state = 0x%04h", $time, target_state);
//                     return;
//                 end
//             end
//             $fatal(1, "[%0t] TIMEOUT waiting center state 0x%04h, now = 0x%04h", $time, target_state, u_center.state_raw);
//         end
//     endtask

//     task automatic tb_init_flow();
//         begin
//             logic [31:0] rd_tmp;
//             flow_msg("STEP 0 - boot at first-stage base frequency");

//             // DVFS default mode 先設 mode_up，讓 power-on / init 可以往高頻走
//             dvfs_mmio_write(`DVFS_mode_setup_reg, 32'd1);

//             flow_msg("STEP 1 - read previous calibration point and setup TD center MMIO registers");

//             center_mmio_write(`sysA_TD_DVFS_start_reg,        32'd1);
//             center_mmio_write(`sysA_TD_calib_start_reg,       32'd1);
//             center_mmio_write(`sysA_TD_error_margin_reg,      32'd4);
//             center_mmio_write(`sysA_TD_warning_margin_reg,    32'd2);
//             center_mmio_write(`sysA_TD_warning_interrupt_En,  32'd1);
//             center_mmio_write(`sysA_TD_voltage_only_mask_reg, 32'd0);
//             center_mmio_write(`sysA_TD_calib_idx_reg,         32'd0);

//             flow_msg("STEP 2 - load test program from Flash to memory");

//             center_mmio_write(`sysA_testProg_srcA, 32'h1000_0000);
//             center_mmio_write(`sysA_testProg_trgA, 32'h2000_0000);
//             center_mmio_write(`sysA_testProg_len,  32'd16);

//             center_mmio_read(`sysA_TD_DVFS_start_reg, rd_tmp);
//             $display("[%0t] READ TD_DVFS_start = 0x%08h", $time, rd_tmp);

//             flow_msg("STEP 3 - kick TD center FSM");

//             center_mmio_write(`sysA_cause_reg, {STD_S0_set, 16'h0000});
//         end
//     endtask

//         task automatic run_noerror_test_loop(input string loop_name);
//         begin
//             wait_center_state(STD_S1_init, 100);
//             flow_msg({loop_name, " - STEP 4: increase frequency to maximum frequency"});

//             wait_center_state(STD_S2_load, 300);
//             flow_msg({loop_name, " - STEP 5: loading test program"});

//             wait_center_state(STD_S3_FTest, 300);
//             flow_msg({loop_name, " - STEP 6: test program load done, enter frequency test"});

//             flow_msg({loop_name, " - STEP 7: FTest PASS, update state to STD_S4_RF"});

//             repeat (20) @(posedge clk);

//             TD_warning_force = 1'b0;
//             sys_error        = 1'b0;

//             center_mmio_write(`sysA_cause_reg, {STD_S4_RF, 16'h0000});
//             wait_center_state(STD_S4_RF, 300);

//             flow_msg({loop_name, " - STEP 8: STD_S4_RF reduce voltage"});

//             wait_center_state(STD_S5_STest, 500);

//             flow_msg({loop_name, " - STEP 9: STD_S5_STest PASS, update state to STD_S6_noError"});

//             center_mmio_write(`sysA_cause_reg, {STD_S6_noError, 16'h0000});
//             wait_center_state(STD_S6_noError, 300);
//         end
//     endtask
//     // ============================================================
//     // Test sequence
//     // ============================================================
    


// initial begin
//     rst               = 1'b1;
//     local_rst         = 1'b1;
//     sys_error         = 1'b0;
//     use_force_warning = 1'b0;
//     TD_warning_force  = '0;

//     c_req_En          = 1'b0;
//     c_RW              = 1'b0;
//     c_Addr            = 32'd0;
//     c_Size            = 3'd2;
//     c_Signalize       = 3'd0;
//     c_Len             = 4'd0;
//     c_WSTRB           = 4'hF;
//     c_BURST           = 2'b01;
//     c_ID              = 4'h1;
//     c_Write_data      = 32'd0;
//     c_Write_Enable    = 1'b0;
//     c_stall           = 1'b0;

//     d_req_En          = 1'b0;
//     d_RW              = 1'b0;
//     d_Addr            = 32'd0;
//     d_Size            = 3'd2;
//     d_Signalize       = 3'd0;
//     d_Len             = 4'd0;
//     d_WSTRB           = 4'hF;
//     d_BURST           = 2'b01;
//     d_ID              = 4'h2;
//     d_Write_data      = 32'd0;
//     d_Write_Enable    = 1'b0;
//     d_stall           = 1'b0;

//     repeat (8) @(posedge clk);
//     rst       = 1'b0;
//     local_rst = 1'b0;
//     repeat (5) @(posedge clk);

//     tb_init_flow();

//     for (int i = 1; i <= 3; i++) begin
//         run_noerror_test_loop($sformatf("LOOP %0d", i));
//     end

//     flow_msg("LOOP 4 - wait next FTest for final error round");

//     wait_center_state(STD_S1_init, 300);
//     flow_msg("LOOP 4 - STEP 4: increase frequency to maximum frequency");

//     wait_center_state(STD_S2_load, 500);
//     flow_msg("LOOP 4 - STEP 5: loading test program");

//     wait_center_state(STD_S3_FTest, 500);
//     flow_msg("LOOP 4 - STEP 6: load done, enter FTest");

//     flow_msg("LOOP 4 - FTest FAIL, update state to STD_S7_yesError");

//     repeat (20) @(posedge clk);

//     TD_warning_force = 1'b0;
//     sys_error        = 1'b0;

//     center_mmio_write(`sysA_cause_reg, {STD_S7_yesError, 16'h0000});
//     wait_center_state(STD_S7_yesError, 300);

//     repeat (3) @(posedge clk);
//     sys_error = 1'b0;

//     flow_msg("LOOP 4 - recover safe voltage / set timing margin");

//     repeat (8) @(posedge clk);
//     TD_warning_force = 1'b0;

//     wait_center_state(STD_S8_marginSet, 500);

//     flow_msg("DONE - finish calibration and return idle");

//     wait_center_state(STD_idal, 500);

//     flow_msg("DONE - boot complete");

//     $display("[%0t] TEST PASS", $time);
//     $finish;
// end

//       initial begin
//         $fsdbDumpfile("TD.fsdb");
//         $fsdbDumpMDA();
//         $fsdbDumpvars();
//       end
//       initial begin
//         $monitor("[%0t] center_state=%04h dvfs_state=%0d DVFS_req=%0b DVFS_resp=%0b c_req=%0b c_resp=%0b c_WB=%0b d_req=%0b d_resp=%0b d_WB=%0b cal_vreq=%0b cal_rreq=%0b cal_vresp=%0b cal_rresp=%0b cal_updown=%0b TD_warn=%0b sys_error=%0b cell_delay_ps=%0.3f v_ctrl=%b",
//                 $time,
//                 u_center.state_raw,
//                 u_dvfs.state,
//                 DVFS_req,
//                 DVFS_resp,
//                 c_req_En,
//                 c_response,
//                 c_WB,
//                 d_req_En,
//                 d_response,
//                 d_WB,
//                 calibration_valid_req,
//                 calibration_ready_req,
//                 calibration_valid_resp,
//                 calibration_ready_resp,
//                 calibration_updown,
//                 TD_warning_to_center,
//                 sys_error,
//                 tb_cell_delay_ps,
//                 v_ctrl);
//         end
// endmodule
