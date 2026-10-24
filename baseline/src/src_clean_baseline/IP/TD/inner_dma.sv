module inner_dma #(
    parameter integer MAX_BURST_BEATS = 16,
    parameter integer FIFO_DEPTH      = 4
) (
    input  logic                         ACLK,
    input  logic                         ARESETn,

    input  logic                         DMA_start,
    input  logic [`AXI_ADDR_BITS-1:0]    src_baseA,
    input  logic [`AXI_ADDR_BITS-1:0]    trg_baseA,
    input  logic [31:0]                  DMA_len,      // unit: AXI data beat

    output logic                         DMA_busy,
    output logic                         DMA_done,
    output logic                         DMA_interrupt,
    output logic                         DMA_error,

    axi_read_if.master                   axi_r_m,      // AR/R
    axi_write_if.master                  axi_w_m       // AW/W/B
);

localparam integer DATA_BYTES = `AXI_DATA_BITS / 8;
localparam integer AXI_SIZE_VALUE = $clog2(DATA_BYTES);
localparam logic [1:0] AXI_BURST_INCR = 2'b01;

localparam integer FIFO_AW = $clog2(FIFO_DEPTH);

// ============================================================
// FSM
// ============================================================
typedef enum logic [2:0] {
    ST_IDLE,
    ST_SETUP,
    ST_ADDR,
    ST_TRANSFER,
    ST_WAIT_B,
    ST_DONE
} dma_state_t;

dma_state_t state, next_state;

// ============================================================
// Registers
// ============================================================
logic [`AXI_ADDR_BITS-1:0] src_addr;
logic [`AXI_ADDR_BITS-1:0] trg_addr;

logic [31:0] remain_beats;
logic [31:0] cur_burst_beats;

logic ar_sent;
logic aw_sent;

logic [31:0] read_beat_cnt;

// ============================================================
// FIFO for read data -> write data
// ============================================================
logic [`AXI_DATA_BITS-1:0] fifo_data [FIFO_DEPTH-1:0];
logic                      fifo_last [FIFO_DEPTH-1:0];

logic [FIFO_AW-1:0] fifo_wptr;
logic [FIFO_AW-1:0] fifo_rptr;
logic [FIFO_AW:0]   fifo_count;

wire fifo_empty = (fifo_count == 0);
wire fifo_full  = (fifo_count == FIFO_DEPTH);

function automatic [FIFO_AW-1:0] ptr_inc(input [FIFO_AW-1:0] ptr);
    if (ptr == FIFO_DEPTH-1)
        ptr_inc = '0;
    else
        ptr_inc = ptr + 1'b1;
endfunction

// ============================================================
// Handshake
// ============================================================
wire ar_fire = axi_r_m.ARVALID_m & axi_r_m.ARREADY_m;
wire r_fire  = axi_r_m.RVALID_m  & axi_r_m.RREADY_m;

wire aw_fire = axi_w_m.AWVALID_m & axi_w_m.AWREADY_m;
wire w_fire  = axi_w_m.WVALID_m  & axi_w_m.WREADY_m;
wire b_fire  = axi_w_m.BVALID_m  & axi_w_m.BREADY_m;

wire fifo_push = r_fire;
wire fifo_pop  = w_fire;

wire last_read_beat  = (read_beat_cnt == cur_burst_beats - 1);
wire last_write_beat = axi_w_m.WLAST_m & w_fire;

// ============================================================
// Output
// ============================================================
assign DMA_busy = (state != ST_IDLE) && (state != ST_DONE);

// --------------------
// AXI Read Address
// --------------------
assign axi_r_m.ARID_m    = '0;
assign axi_r_m.ARADDR_m  = src_addr;
assign axi_r_m.ARLEN_m   = cur_burst_beats[`AXI_LEN_BITS-1:0] - 1'b1;
assign axi_r_m.ARSIZE_m  = AXI_SIZE_VALUE[`AXI_SIZE_BITS-1:0];
assign axi_r_m.ARBURST_m = AXI_BURST_INCR;
assign axi_r_m.ARVALID_m = (state == ST_ADDR) && !ar_sent;

// --------------------
// AXI Read Data
// --------------------
assign axi_r_m.RREADY_m  = (state == ST_TRANSFER) && !fifo_full;

// --------------------
// AXI Write Address
// --------------------
assign axi_w_m.AWID_m    = '0;
assign axi_w_m.AWADDR_m  = trg_addr;
assign axi_w_m.AWLEN_m   = cur_burst_beats[`AXI_LEN_BITS-1:0] - 1'b1;
assign axi_w_m.AWSIZE_m  = AXI_SIZE_VALUE[`AXI_SIZE_BITS-1:0];
assign axi_w_m.AWBURST_m = AXI_BURST_INCR;
assign axi_w_m.AWVALID_m = (state == ST_ADDR) && !aw_sent;

// --------------------
// AXI Write Data
// --------------------
assign axi_w_m.WDATA_m   = fifo_data[fifo_rptr];
assign axi_w_m.WSTRB_m   = {`AXI_STRB_BITS{1'b1}};
assign axi_w_m.WLAST_m   = fifo_last[fifo_rptr];
assign axi_w_m.WVALID_m  = (state == ST_TRANSFER) && !fifo_empty;

// --------------------
// AXI Write Response
// --------------------
assign axi_w_m.BREADY_m  = (state == ST_WAIT_B);

// ============================================================
// FSM sequential
// ============================================================
always_ff @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn) begin
        state <= ST_IDLE;
    end
    else begin
        state <= next_state;
    end
end

// ============================================================
// FSM combinational
// ============================================================
always_comb begin
    next_state = state;

    case (state)

        ST_IDLE: begin
            if (DMA_start && DMA_len != 0)
                next_state = ST_SETUP;
            else if (DMA_start && DMA_len == 0)
                next_state = ST_DONE;
        end

        ST_SETUP: begin
            next_state = ST_ADDR;
        end

        ST_ADDR: begin
            if ((ar_sent || ar_fire) && (aw_sent || aw_fire))
                next_state = ST_TRANSFER;
        end

        ST_TRANSFER: begin
            if (last_write_beat)
                next_state = ST_WAIT_B;
        end

        ST_WAIT_B: begin
            if (b_fire) begin
                if (remain_beats == 0)
                    next_state = ST_DONE;
                else
                    next_state = ST_SETUP;
            end
        end

        ST_DONE: begin
            if (!DMA_start)
                next_state = ST_IDLE;
        end

        default: begin
            next_state = ST_IDLE;
        end

    endcase
end

// ============================================================
// Main control registers
// ============================================================
always_ff @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn) begin
        src_addr        <= '0;
        trg_addr        <= '0;
        remain_beats    <= '0;
        cur_burst_beats <= '0;

        ar_sent         <= 1'b0;
        aw_sent         <= 1'b0;
        read_beat_cnt   <= '0;

        DMA_done        <= 1'b0;
        DMA_interrupt   <= 1'b0;
        DMA_error       <= 1'b0;
    end
    else begin
        DMA_done <= 1'b0;

        case (state)

            ST_IDLE: begin
                DMA_interrupt <= 1'b0;
                DMA_error     <= 1'b0;

                if (DMA_start) begin
                    src_addr     <= src_baseA;
                    trg_addr     <= trg_baseA;
                    remain_beats <= DMA_len;
                end
            end

            ST_SETUP: begin
                ar_sent       <= 1'b0;
                aw_sent       <= 1'b0;
                read_beat_cnt <= '0;

                if (remain_beats >= MAX_BURST_BEATS)
                    cur_burst_beats <= MAX_BURST_BEATS;
                else
                    cur_burst_beats <= remain_beats;
            end

            ST_ADDR: begin
                if (ar_fire)
                    ar_sent <= 1'b1;

                if (aw_fire)
                    aw_sent <= 1'b1;
            end

            ST_TRANSFER: begin
                if (r_fire) begin
                    read_beat_cnt <= read_beat_cnt + 1'b1;

                    if (axi_r_m.RRESP_m != 2'b00)
                        DMA_error <= 1'b1;
                end

                if (w_fire) begin
                    remain_beats <= remain_beats - 1'b1;
                end
            end

            ST_WAIT_B: begin
                if (b_fire) begin
                    if (axi_w_m.BRESP_m != 2'b00)
                        DMA_error <= 1'b1;

                    src_addr <= src_addr + cur_burst_beats * DATA_BYTES;
                    trg_addr <= trg_addr + cur_burst_beats * DATA_BYTES;
                end
            end

            ST_DONE: begin
                DMA_done      <= 1'b1;
                DMA_interrupt <= 1'b1;
            end

            default: begin
            end

        endcase
    end
end

// ============================================================
// FIFO control
// ============================================================
always_ff @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn) begin
        fifo_wptr  <= '0;
        fifo_rptr  <= '0;
        fifo_count <= '0;
    end
    else begin
        if (state == ST_SETUP) begin
            fifo_wptr  <= '0;
            fifo_rptr  <= '0;
            fifo_count <= '0;
        end
        else begin
            if (fifo_push) begin
                fifo_data[fifo_wptr] <= axi_r_m.RDATA_m;
                fifo_last[fifo_wptr] <= last_read_beat;
                fifo_wptr            <= ptr_inc(fifo_wptr);
            end

            if (fifo_pop) begin
                fifo_rptr <= ptr_inc(fifo_rptr);
            end

            case ({fifo_push, fifo_pop})
                2'b10: fifo_count <= fifo_count + 1'b1;
                2'b01: fifo_count <= fifo_count - 1'b1;
                default: fifo_count <= fifo_count;
            endcase
        end
    end
end

endmodule