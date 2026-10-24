`timescale 1ns/1ps

// ============================================================================
// DRAMSys wrapper using the project's original slave_simple AXI behavior.
//
// AXI frontend:
//   slave_simple_dramsys
//     - Derived from the project's slave_simple.
//     - Keeps the original AXI sequencing and burst handling.
//     - Only fixes behavior required by a variable-latency DRAM backend.
//
// Memory backend:
//   32-bit AXI beat -> one aligned 512-bit (64-byte) sim_dram request.
//   Only one DRAMSys request is active at a time.
// ============================================================================
module DRAMSys_wrap #(
    parameter logic [31:0] BASE_ADDR      = 32'h2000_0000,
    parameter              DRAM_TYPE      = "DDR4",
    parameter              CUSTOMER_DRAM  = "none"
)(
    input  logic       ACLK,
    input  logic       ARESETn,

    axi_read_if.slave  axi_r_s,
    axi_write_if.slave axi_w_s
);

    localparam int unsigned DRAMSYS_DATA_WIDTH = 512;
    localparam int unsigned DRAMSYS_LINE_BYTES = DRAMSYS_DATA_WIDTH / 8;
    localparam int unsigned DRAMSYS_LINE_LSB   = $clog2(DRAMSYS_LINE_BYTES);

    typedef enum logic [2:0] {
        MEM_IDLE,
        MEM_READ_REQ,
        MEM_READ_WAIT,
        MEM_READ_RELEASE,
        MEM_WRITE_REQ,
        MEM_WRITE_WAIT,
        MEM_WRITE_RELEASE
    } mem_state_t;

    mem_state_t mem_state;

    // ------------------------------------------------------------------------
    // Original AXI slave frontend signals
    // ------------------------------------------------------------------------
    logic        stall_W;
    logic        stall_R;
    logic [31:0] read_data;
    logic        Read_Enable;
    logic [31:0] Addr;
    logic [31:0] Write_data;
    logic        Write_Enable;
    logic [3:0]  out_WSTRB;

    slave_simple_dramsys u_axi_frontend (
        .ACLK         (ACLK),
        .ARESETn      (ARESETn),
        .axi_r_s      (axi_r_s),
        .axi_w_s      (axi_w_s),
        .stall_W      (stall_W),
        .stall_R      (stall_R),
        .in_miss      (1'b0),
        .in_hit       (1'b0),
        .read_data    (read_data),
        .Read_Enable  (Read_Enable),
        .Addr         (Addr),
        .Write_data   (Write_data),
        .Write_Enable (Write_Enable),
        .out_WSTRB    (out_WSTRB)
    );

    // The frontend may expose the AXI response only after DRAMSys completes.
    assign stall_R = (mem_state == MEM_READ_REQ) ||
                     (mem_state == MEM_READ_WAIT);

    assign stall_W = (mem_state == MEM_WRITE_REQ) ||
                     (mem_state == MEM_WRITE_WAIT);

    wire axi_r_shake = axi_r_s.RVALID_s && axi_r_s.RREADY_s;
    wire axi_b_shake = axi_w_s.BVALID_s && axi_w_s.BREADY_s;

    // ------------------------------------------------------------------------
    // Captured 32-bit beat
    // ------------------------------------------------------------------------
    logic [31:0] request_addr_q;
    logic [31:0] write_data_q;
    logic [3:0]  write_strb_q;
    logic [DRAMSYS_LINE_LSB-1:0] byte_offset_q;
    // AXI WDATA/RDATA are 32-bit bus words.  Align the address offset down
    // to the beginning of the corresponding 4-byte AXI data lane group.
    // Example: byte_offset=63 -> word_byte_offset=60; WSTRB=4'b1000 then
    // selects byte 63 without creating an out-of-range 64-byte line select.
    logic [DRAMSYS_LINE_LSB-1:0] word_byte_offset_q;
    logic [31:0] read_data_q;

    assign word_byte_offset_q = {
        byte_offset_q[DRAMSYS_LINE_LSB-1:2],
        2'b00
    };

    assign read_data = read_data_q;

    function automatic logic [31:0] dram_local_addr(
        input logic [31:0] axi_addr
    );
        begin
            if (axi_addr >= BASE_ADDR)
                dram_local_addr = axi_addr - BASE_ADDR;
            else
                dram_local_addr = axi_addr;
        end
    endfunction

    function automatic logic [31:0] aligned_line_addr(
        input logic [31:0] axi_addr
    );
        logic [31:0] local_addr;
        begin
            local_addr = dram_local_addr(axi_addr);
            aligned_line_addr = {
                local_addr[31:DRAMSYS_LINE_LSB],
                {DRAMSYS_LINE_LSB{1'b0}}
            };
        end
    endfunction

    function automatic logic [DRAMSYS_LINE_LSB-1:0] line_byte_offset(
        input logic [31:0] axi_addr
    );
        logic [31:0] local_addr;
        begin
            local_addr = dram_local_addr(axi_addr);
            line_byte_offset = local_addr[DRAMSYS_LINE_LSB-1:0];
        end
    endfunction

    // ------------------------------------------------------------------------
    // sim_dram interface
    // ------------------------------------------------------------------------
    logic                          dramsys_req_valid;
    logic                          dramsys_req_ready;
    logic                          dramsys_we;
    logic [31:0]                   dramsys_addr;
    logic [DRAMSYS_DATA_WIDTH-1:0] dramsys_wdata;
    logic [DRAMSYS_LINE_BYTES-1:0] dramsys_wstrb;

    logic                          dramsys_rsp_valid;
    logic                          dramsys_rsp_ready;
    logic [DRAMSYS_DATA_WIDTH-1:0] dramsys_rdata;

    logic                          dramsys_b_valid;
    logic                          dramsys_b_ready;

    assign dramsys_req_valid = (mem_state == MEM_READ_REQ) ||
                               (mem_state == MEM_WRITE_REQ);
    assign dramsys_we        = (mem_state == MEM_WRITE_REQ);
    assign dramsys_addr      = aligned_line_addr(request_addr_q);

    assign dramsys_rsp_ready = (mem_state == MEM_READ_WAIT);
    assign dramsys_b_ready   = (mem_state == MEM_WRITE_WAIT);

    integer write_lane;
    always_comb begin
        dramsys_wdata = '0;
        dramsys_wstrb = '0;

        if (mem_state == MEM_WRITE_REQ) begin
            // Map each AXI byte lane into the aligned 64-byte DRAMSys line.
            // Do not start a 32-bit part-select at byte_offset_q directly:
            // byte offsets 61..63 would extend beyond the 512-bit line.
            for (write_lane = 0; write_lane < 4; write_lane = write_lane + 1) begin
                if (write_strb_q[write_lane]) begin
                    dramsys_wdata[
                        ((word_byte_offset_q + write_lane) * 8) +: 8
                    ] = write_data_q[(write_lane * 8) +: 8];

                    dramsys_wstrb[word_byte_offset_q + write_lane] = 1'b1;
                end
            end
        end
    end

    sim_dram #(
        .DataWidth    (DRAMSYS_DATA_WIDTH),
        .AddrWidth    (32),
        .BASE         (BASE_ADDR),
        .DRAMType     (DRAM_TYPE),
        .CustomerDRAM (CUSTOMER_DRAM)
    ) u_sim_dram (
        .clk_i       (ACLK),
        .rst_ni      (ARESETn),

        .req_valid_i (dramsys_req_valid),
        .req_ready_o (dramsys_req_ready),
        .we_i        (dramsys_we),
        .addr_i      (dramsys_addr),
        .wdata_i     (dramsys_wdata),
        .wstrb_i     (dramsys_wstrb),

        .rsp_valid_o (dramsys_rsp_valid),
        .rsp_ready_i (dramsys_rsp_ready),
        .rdata_o     (dramsys_rdata),

        .b_valid_o   (dramsys_b_valid),
        .b_ready_i   (dramsys_b_ready)
    );

    // ------------------------------------------------------------------------
    // Serialized DRAMSys backend
    // ------------------------------------------------------------------------
    always_ff @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            mem_state     <= MEM_IDLE;
            request_addr_q <= 32'd0;
            write_data_q   <= 32'd0;
            write_strb_q   <= 4'd0;
            byte_offset_q  <= '0;
            read_data_q    <= 32'd0;
        end
        else begin
            case (mem_state)
                MEM_IDLE: begin
                    if (Read_Enable) begin
                        request_addr_q <= Addr;
                        byte_offset_q  <= line_byte_offset(Addr);
                        mem_state      <= MEM_READ_REQ;
                    end
                    else if (Write_Enable) begin
                        request_addr_q <= Addr;
                        write_data_q   <= Write_data;
                        write_strb_q   <= out_WSTRB;
                        byte_offset_q  <= line_byte_offset(Addr);
                        mem_state      <= MEM_WRITE_REQ;
                    end
                end

                MEM_READ_REQ: begin
                    if (dramsys_req_valid && dramsys_req_ready)
                        mem_state <= MEM_READ_WAIT;
                end

                MEM_READ_WAIT: begin
                    if (dramsys_rsp_valid) begin
                        // Return the aligned 32-bit AXI bus word.  For a
                        // narrow/byte access the AXI master uses ARADDR[1:0]
                        // and the corresponding byte lane from this word.
                        read_data_q <= dramsys_rdata[
                            (word_byte_offset_q * 8) +: 32
                        ];
                        mem_state <= MEM_READ_RELEASE;
                    end
                end

                // stall_R is low here. slave_simple presents RVALID/RDATA.
                MEM_READ_RELEASE: begin
                    // For a non-last beat, slave_simple raises Read_Enable on
                    // the same cycle as the AXI R handshake.
                    if (Read_Enable) begin
                        request_addr_q <= Addr;
                        byte_offset_q  <= line_byte_offset(Addr);
                        mem_state      <= MEM_READ_REQ;
                    end
                    else if (axi_r_shake) begin
                        mem_state <= MEM_IDLE;
                    end
                end

                MEM_WRITE_REQ: begin
                    if (dramsys_req_valid && dramsys_req_ready)
                        mem_state <= MEM_WRITE_WAIT;
                end

                MEM_WRITE_WAIT: begin
                    if (dramsys_b_valid)
                        mem_state <= MEM_WRITE_RELEASE;
                end

                // stall_W is low here. slave_simple either accepts the next
                // W beat or presents the final B response.
                MEM_WRITE_RELEASE: begin
                    if (Write_Enable) begin
                        request_addr_q <= Addr;
                        write_data_q   <= Write_data;
                        write_strb_q   <= out_WSTRB;
                        byte_offset_q  <= line_byte_offset(Addr);
                        mem_state      <= MEM_WRITE_REQ;
                    end
                    else if (axi_b_shake) begin
                        mem_state <= MEM_IDLE;
                    end
                end

                default: mem_state <= MEM_IDLE;
            endcase
        end
    end

`ifndef SYNTHESIS
    initial begin
        $display("[DRAMSys_wrap] Using slave_simple AXI frontend");
        $display("[DRAMSys_wrap] AXI base address = 0x%08h", BASE_ADDR);
    end

`ifdef DRAMSYS_DEBUG
    always_ff @(posedge ACLK) begin
        if (ARESETn) begin
            if (Read_Enable)
                $display("[%0t] [DRAMSys AXI] READ beat addr=0x%08h", $time, Addr);
            if (Write_Enable)
                $display("[%0t] [DRAMSys AXI] WRITE beat addr=0x%08h data=0x%08h strb=0x%h", $time, Addr, Write_data, out_WSTRB);
            if (dramsys_req_valid && dramsys_req_ready)
                $display(
                    "[%0t] [DRAMSys TLM] REQ we=%0b line_addr=0x%08h byte_offset=%0d word_offset=%0d wdata=0x%08h wstrb=0x%h",
                    $time, dramsys_we, dramsys_addr, byte_offset_q,
                    word_byte_offset_q, write_data_q, write_strb_q
                );
            if (dramsys_rsp_valid && dramsys_rsp_ready)
                $display("[%0t] [DRAMSys TLM] READ response", $time);
            if (dramsys_b_valid && dramsys_b_ready)
                $display("[%0t] [DRAMSys TLM] WRITE response", $time);
        end
    end
`endif
`endif

    // ------------------------------------------------------------------------
    // Testbench preload/read-back accessors
    // Addresses are DRAM-local byte offsets.
    // ------------------------------------------------------------------------
    task automatic load_a_byte_to_dram(
        input longint dram_addr_ofst,
        input int     data_byte
    );
        u_sim_dram.load_a_byte_to_dram(dram_addr_ofst, data_byte);
    endtask

    task automatic check_a_byte_in_dram(
        input  longint    dram_addr_ofst,
        output logic [7:0] data_byte
    );
        u_sim_dram.check_a_byte_in_dram(dram_addr_ofst, data_byte);
    endtask

    task automatic preload_elf_binary(input string elf_binary);
        u_sim_dram.preload_elf_binary(elf_binary);
    endtask

endmodule


// ============================================================================
// Project slave_simple adapted only for a variable-latency DRAMSys backend.
//
// Intentional fixes compared with the provided source:
//   1. address_counter holds while the backend is stalled.
//   2. single-beat AW+W in the same cycle correctly sets mem_last.
//   3. read has priority when ARVALID and AWVALID arrive together.
// ============================================================================
module slave_simple_dramsys #(
    parameter outstanding = 4
)(
    input               ACLK,
    input               ARESETn,

    axi_read_if.slave   axi_r_s,
    axi_write_if.slave  axi_w_s,

    input               stall_W,
    input               stall_R,

    input               in_miss,
    input               in_hit,
    input  logic [31:0] read_data,
    output logic        Read_Enable,
    output logic [31:0] Addr,
    output logic [31:0] Write_data,
    output logic        Write_Enable,
    output logic [3:0]  out_WSTRB
);

    typedef enum logic [1:0] {
        AXI_IDLE,
        AXI_READ,
        AXI_WRITE
    } axi_state_t;

    axi_state_t state;
    axi_state_t next_state;

    wire [7:0]  AWID_S    = axi_w_s.AWID_s;
    wire [31:0] AWADDR_S  = axi_w_s.AWADDR_s;
    wire [3:0]  AWLEN_S   = axi_w_s.AWLEN_s;
    wire [2:0]  AWSIZE_S  = axi_w_s.AWSIZE_s;
    wire [1:0]  AWBURST_S = axi_w_s.AWBURST_s;
    wire        AWVALID_S = axi_w_s.AWVALID_s;
    logic       AWREADY_S;

    wire [31:0] WDATA_S   = axi_w_s.WDATA_s;
    wire [3:0]  WSTRB_S   = axi_w_s.WSTRB_s;
    wire        WLAST_S   = axi_w_s.WLAST_s;
    wire        WVALID_S  = axi_w_s.WVALID_s;
    logic       WREADY_S;

    logic [7:0] BID_S;
    logic [1:0] BRESP_S;
    logic       BVALID_S;
    wire        BREADY_S = axi_w_s.BREADY_s;

    wire [7:0]  ARID_S    = axi_r_s.ARID_s;
    wire [31:0] ARADDR_S  = axi_r_s.ARADDR_s;
    wire [3:0]  ARLEN_S   = axi_r_s.ARLEN_s;
    wire [2:0]  ARSIZE_S  = axi_r_s.ARSIZE_s;
    wire [1:0]  ARBURST_S = axi_r_s.ARBURST_s;
    wire        ARVALID_S = axi_r_s.ARVALID_s;
    logic       ARREADY_S;

    logic [7:0]  RID_S;
    logic [31:0] RDATA_S;
    logic [1:0]  RRESP_S;
    logic        RLAST_S;
    logic        RVALID_S;
    wire         RREADY_S = axi_r_s.RREADY_s;

    assign axi_w_s.AWREADY_s = AWREADY_S;
    assign axi_w_s.WREADY_s  = WREADY_S;
    assign axi_w_s.BID_s     = BID_S;
    assign axi_w_s.BRESP_s   = BRESP_S;
    assign axi_w_s.BVALID_s  = BVALID_S;

    assign axi_r_s.ARREADY_s = ARREADY_S;
    assign axi_r_s.RID_s     = RID_S;
    assign axi_r_s.RDATA_s   = RDATA_S;
    assign axi_r_s.RRESP_s   = RRESP_S;
    assign axi_r_s.RLAST_s   = RLAST_S;
    assign axi_r_s.RVALID_s  = RVALID_S;

    logic        mem_last;
    logic [3:0]  burst_counter;
    logic [31:0] address_counter;
    logic [7:0]  ID_current;
    logic        WLAST_current;

    logic        RVALID_buffer;
    logic [31:0] RDATA_buffer;

    wire AR_shake = ARREADY_S && ARVALID_S;
    wire AW_shake = AWREADY_S && AWVALID_S;
    wire W_shake  = WREADY_S  && WVALID_S;
    wire B_shake  = BREADY_S  && BVALID_S;
    wire R_shake  = RREADY_S  && RVALID_S;

    wire single_write_first_beat = AW_shake && W_shake && (AWLEN_S == 4'd0);

    wire in_last = (AR_shake && (ARLEN_S == 4'd0)) ? 1'b1 :
                   single_write_first_beat          ? 1'b1 :
                   ((state == AXI_READ)  && (burst_counter == 4'd0)) ? 1'b1 :
                   ((state == AXI_WRITE) && (burst_counter == 4'd0)) ? 1'b1 :
                   1'b0;

    wire burst_done = ((state == AXI_READ)  && mem_last && R_shake) ||
                      ((state == AXI_WRITE) && mem_last && B_shake);

    always_ff @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn)
            state <= AXI_IDLE;
        else
            state <= next_state;
    end

    always_comb begin
        case (state)
            AXI_IDLE: begin
                if (AR_shake)
                    next_state = AXI_READ;
                else if (AW_shake)
                    next_state = AXI_WRITE;
                else
                    next_state = AXI_IDLE;
            end

            AXI_READ:
                next_state = burst_done ? AXI_IDLE : AXI_READ;

            AXI_WRITE:
                next_state = burst_done ? AXI_IDLE : AXI_WRITE;

            default:
                next_state = AXI_IDLE;
        endcase
    end

    always_ff @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            burst_counter  <= 4'd0;
            address_counter <= 32'd0;
        end
        else if (AR_shake) begin
            burst_counter  <= (ARLEN_S == 4'd0) ? 4'd0 : ARLEN_S - 4'd1;
            address_counter <= ARADDR_S + 32'd4;
        end
        else if (AW_shake && W_shake) begin
            burst_counter  <= (AWLEN_S == 4'd0) ? 4'd0 : AWLEN_S - 4'd1;
            address_counter <= AWADDR_S + 32'd4;
        end
        else if (AW_shake) begin
            burst_counter  <= AWLEN_S;
            address_counter <= AWADDR_S;
        end
        else if ((state == AXI_READ) && R_shake && !mem_last) begin
            burst_counter  <= burst_counter - 4'd1;
            address_counter <= address_counter + 32'd4;
        end
        else if ((state == AXI_WRITE) && W_shake && !mem_last) begin
            burst_counter  <= burst_counter - 4'd1;
            address_counter <= address_counter + 32'd4;
        end
        else begin
            // Important for DRAMSys: hold while memory latency stalls AXI.
            burst_counter  <= burst_counter;
            address_counter <= address_counter;
        end
    end

    always_ff @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            mem_last <= 1'b0;
        end
        else if (!R_shake && (state == AXI_READ) && mem_last) begin
            mem_last <= 1'b1;
        end
        else if (!B_shake && (state == AXI_WRITE) && mem_last) begin
            mem_last <= 1'b1;
        end
        else if (Write_Enable || Read_Enable) begin
            mem_last <= in_last;
        end
        else if (R_shake || B_shake) begin
            mem_last <= 1'b0;
        end
    end

    assign Read_Enable = AR_shake ||
                         ((state == AXI_READ) && R_shake && !mem_last);

    assign Addr = AR_shake ? ARADDR_S :
                  AW_shake ? AWADDR_S :
                  address_counter;

    assign Write_data   = WDATA_S;
    assign Write_Enable = (AW_shake && W_shake) ||
                          ((state == AXI_WRITE) && W_shake && !mem_last);
    assign out_WSTRB    = WSTRB_S;

    // Read wins if read and write addresses are both presented in AXI_IDLE.
    assign ARREADY_S = !stall_R && (state == AXI_IDLE);
    assign AWREADY_S = !stall_W && (state == AXI_IDLE) && !ARVALID_S;

    assign RVALID_S = (!stall_R && RVALID_buffer) ? 1'b1 :
                      (!stall_R && (state == AXI_READ)) ? 1'b1 :
                      1'b0;

    assign RID_S   = ID_current;
    assign RDATA_S = RVALID_buffer ? RDATA_buffer :
                     ((state == AXI_READ) ? read_data : 32'd0);
    assign RRESP_S = 2'b00;
    assign RLAST_S = mem_last;

    assign BVALID_S = !stall_W && mem_last && (state == AXI_WRITE);
    assign BID_S    = ID_current;
    assign BRESP_S  = 2'b00;

    assign WREADY_S = (!stall_W && (state == AXI_WRITE) && !WLAST_current) ||
                      (!stall_W && (state == AXI_IDLE) && AW_shake);

    always_ff @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            RVALID_buffer <= 1'b0;
            RDATA_buffer  <= 32'd0;
        end
        else if ((state == AXI_READ) && !R_shake && !RVALID_buffer) begin
            RVALID_buffer <= RVALID_S;
            RDATA_buffer  <= RDATA_S;
        end
        else if (RVALID_buffer && R_shake) begin
            RVALID_buffer <= 1'b0;
        end
    end

    always_ff @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn)
            WLAST_current <= 1'b0;
        else if (W_shake)
            WLAST_current <= WLAST_S;
        else if (state == AXI_IDLE)
            WLAST_current <= 1'b0;
    end

    always_ff @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn)
            ID_current <= 8'd0;
        else if (AR_shake)
            ID_current <= ARID_S;
        else if (AW_shake)
            ID_current <= AWID_S;
    end

    // These are retained for interface compatibility with the original module.

endmodule
