// ============================================================
// Reset Synchronizer
// ------------------------------------------------------------
// Function:
//   - Asynchronous reset assertion
//   - Synchronous reset deassertion
//
// arst_i : asynchronous active-high reset input
// rst_o  : active-high reset synchronized to clk_i
// ============================================================

module reset_sync (
    input  logic clk_i,
    input  logic arst_i,
    output logic rst_o
);

    (* async_reg = "true" *) logic rst_sync_ff1;
    (* async_reg = "true" *) logic rst_sync_ff2;

    always_ff @(posedge clk_i or posedge arst_i) begin
        if (arst_i) begin
            rst_sync_ff1 <= 1'b1;
            rst_sync_ff2 <= 1'b1;
        end
        else begin
            rst_sync_ff1 <= 1'b0;
            rst_sync_ff2 <= rst_sync_ff1;
        end
    end

    assign rst_o = rst_sync_ff2;

endmodule