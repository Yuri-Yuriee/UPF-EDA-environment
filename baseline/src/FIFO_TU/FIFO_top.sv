module FIFO_TOP #(
    parameter integer width       = 34,
    parameter integer depath      = 32,
    parameter integer pointer_bit = $clog2(depath) + 1,
    parameter integer SYNC_FF_NUM = 2
)(
    input  logic                 clk_in,
    input  logic                 clk_out,
    input  logic                 rst_n,

    input  logic [width-1:0]     data_in,
    input  logic                 data_in_valid,
    output logic                 data_in_ready,

    output logic [width-1:0]     data_out,
    output logic                 data_out_valid,
    input  logic                 data_out_ready
);
    logic w_rst;
    logic r_rst;

    logic fifo_winc;
    logic fifo_rinc;

    logic [width-1:0] fifo_rdata;
    logic             fifo_rempty;
    logic             fifo_wfull;

    //***************************
    //      your reset Synchronizer
    //***************************

    reset_sync u_w_reset_sync (
        .clk_i  (clk_in),
        .arst_i (~rst_n),
        .rst_o  (w_rst)
    );

    reset_sync u_r_reset_sync (
        .clk_i  (clk_out),
        .arst_i (~rst_n),
        .rst_o  (r_rst)
    );

    assign data_in_ready  = (~w_rst) && (~fifo_wfull);
    assign fifo_winc      = data_in_valid && data_in_ready;

    assign data_out       = fifo_rdata;
    assign data_out_valid = (~r_rst) && (~fifo_rempty);
    assign fifo_rinc      = data_out_valid && data_out_ready;

    //***************************
    //      your FIFO
    //***************************
    asyc_FIFO #(
        .width       (width),
        .depath      (depath),
        .pointer_bit (pointer_bit),
        .SYNC_FF_NUM (SYNC_FF_NUM)
    ) u_fifo (
        .w_clk  (clk_in),
        .w_rst  (w_rst),

        .r_clk  (clk_out),
        .r_rst  (r_rst),

        .wdata  (data_in),
        .winc   (fifo_winc),
        .rinc   (fifo_rinc),

        .rdata  (fifo_rdata),
        .rempty (fifo_rempty),
        .wfull  (fifo_wfull)
    );

endmodule