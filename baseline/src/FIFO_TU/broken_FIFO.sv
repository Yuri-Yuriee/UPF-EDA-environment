module asyc_FIFO #(
    parameter integer width       = 34,
    parameter integer depath      = 2,
    parameter integer pointer_bit = $clog2(depath) + 1,
    parameter integer SYNC_FF_NUM = 2
)(
    input  logic                 w_clk,
    input  logic                 w_rst,

    input  logic                 r_clk,
    input  logic                 r_rst,

    input  logic [width-1:0]     wdata,
    input  logic                 winc,
    input  logic                 rinc,

    output logic [width-1:0]     rdata,
    output logic                 rempty,
    output logic                 wfull
);

    logic [width-1:0] fifo_queue [$];

    logic [width-1:0] removed_data;

    always @(posedge w_clk or posedge w_rst) begin
        if (w_rst) begin
            fifo_queue.delete();
        end
        else if (winc && !wfull) begin
            fifo_queue.push_back(wdata);

            $display(
                "[%0t] WRITE data=%h size=%0d",
                $time,
                wdata,
                fifo_queue.size()
            );
        end
    end

    always @(posedge r_clk or posedge r_rst) begin
        if (r_rst) begin
            removed_data <= '0;
        end
        else if (rinc && !rempty) begin
            /*
             * Intentional functional bug:
             * pop_back() creates LIFO behavior.
             */
            removed_data = fifo_queue.pop_back();

            $display(
                "[%0t] BROKEN READ data=%h size=%0d",
                $time,
                removed_data,
                fifo_queue.size()
            );
        end
    end

    /*
     * Intentional functional bug:
     * Present the newest queue element instead of the oldest one.
     */
    always_comb begin
        if (fifo_queue.size() > 0) begin
            rdata = fifo_queue[$];
        end
        else begin
            rdata = '0;
        end
    end

    always_comb begin
        rempty = (fifo_queue.size() == 0);
        wfull  = (fifo_queue.size() >= depath);
    end

endmodule