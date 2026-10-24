module power_switch_decoder #(
    parameter integer v_stage    = 4,
    parameter integer v_sel_bits = (v_stage <= 1) ? 1 : $clog2(v_stage)
) (
    input  logic                    CPU_OFF,
    input  logic [v_sel_bits-1:0]   DVFS_v_step,

    // active-high power switch enable
    // 1 = switch ON
    // 0 = switch OFF
    output logic [v_stage-1:0]      power_switch_en
);

always_comb begin
    power_switch_en = '0;

    // CPU_OFF 最高優先權
    // 只要 CPU_OFF 舉起來，全部 power switch 都關掉
    if (!CPU_OFF) begin
        if (int'(DVFS_v_step) < v_stage) begin
            power_switch_en[DVFS_v_step] = 1'b1;
        end
    end
end

endmodule