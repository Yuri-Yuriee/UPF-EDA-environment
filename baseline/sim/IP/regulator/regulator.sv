`resetall
`timescale 1ps/1ps
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
    // function automatic real calc_cell_delay_ps (
    //     input real  cur_cell_delay_ps,
    //     input logic voltage_up,
    //     input logic voltage_down
    // );
    //     real next_cell_delay_ps;
    //     begin
    //         if (voltage_up && !voltage_down) begin
    //             next_cell_delay_ps = cur_cell_delay_ps / VOLTAGE_DELAY_SCALE;
    //             $display("\n\n[%0t] [REGULATOR CELL DELAY] mode=UP   old_delay_ps=%0.3f new_delay_ps=%0.3f scale=%0.3f\n\n",
    //                     $time, cur_cell_delay_ps, next_cell_delay_ps, VOLTAGE_DELAY_SCALE);
    //         end
    //         else if (voltage_down && !voltage_up) begin
    //             next_cell_delay_ps = cur_cell_delay_ps * VOLTAGE_DELAY_SCALE;
    //             $display("\n\n[%0t] [REGULATOR CELL DELAY] mode=DOWN old_delay_ps=%0.3f new_delay_ps=%0.3f scale=%0.3f\n\n",
    //                     $time, cur_cell_delay_ps, next_cell_delay_ps, VOLTAGE_DELAY_SCALE);
    //         end
    //         else begin
    //             next_cell_delay_ps = cur_cell_delay_ps;
    //         end

    //         calc_cell_delay_ps = next_cell_delay_ps;
    //     end
    // endfunction


    function automatic real calc_cell_delay_ps (
        input real  cur_cell_delay_ps,
        input logic voltage_up,
        input logic voltage_down
    );
        real next_cell_delay_ps;

        begin
            if (voltage_up && !voltage_down) begin
                next_cell_delay_ps = cur_cell_delay_ps / VOLTAGE_DELAY_SCALE;

                $display("");
                $display("============================================================");
                $display("[REGULATOR CELL DELAY] @ %0t", $time);
                $display("  Mode          : UP");
                $display("  Old Delay     : %0.3f ps", cur_cell_delay_ps);
                $display("  New Delay     : %0.3f ps", next_cell_delay_ps);
                $display("  Scale Factor  : %0.3f", VOLTAGE_DELAY_SCALE);
                $display("============================================================");
                $display("");
            end
            else if (voltage_down && !voltage_up) begin
                next_cell_delay_ps = cur_cell_delay_ps * VOLTAGE_DELAY_SCALE;

                $display("");
                $display("============================================================");
                $display("[REGULATOR CELL DELAY] @ %0t", $time);
                $display("  Mode          : DOWN");
                $display("  Old Delay     : %0.3f ps", cur_cell_delay_ps);
                $display("  New Delay     : %0.3f ps", next_cell_delay_ps);
                $display("  Scale Factor  : %0.3f", VOLTAGE_DELAY_SCALE);
                $display("============================================================");
                $display("");
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
