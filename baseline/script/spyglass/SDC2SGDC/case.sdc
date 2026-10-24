###############################################################################
# CLK_CONFIG
#   0 : ROM_clk
#   1 : DRAM_clk
#   2 : ACLK
#   3 : cpu_clk_i
###############################################################################
# 請填入本地設計／製程的設定值，保持原資料型別
set config_option {FILL_IN_config_option}

###############################################################################
# DVFS Clock MUX Case Analysis
###############################################################################

switch -- $config_option {
    0 {
        # CK_mux_sel[1:0] = 2'b00 -> ROM_clk
# 請填入本地設計／製程的設定值，保持原資料型別
        set CK_MUX_SEL_0 {FILL_IN_CK_MUX_SEL_0}
# 請填入本地設計／製程的設定值，保持原資料型別
        set CK_MUX_SEL_1 {FILL_IN_CK_MUX_SEL_1}
    }

    1 {
        # CK_mux_sel[1:0] = 2'b01 -> DRAM_clk
# 請填入本地設計／製程的設定值，保持原資料型別
        set CK_MUX_SEL_0 {FILL_IN_CK_MUX_SEL_0}
# 請填入本地設計／製程的設定值，保持原資料型別
        set CK_MUX_SEL_1 {FILL_IN_CK_MUX_SEL_1}
    }

    2 {
        # CK_mux_sel[1:0] = 2'b10 -> ACLK
# 請填入本地設計／製程的設定值，保持原資料型別
        set CK_MUX_SEL_0 {FILL_IN_CK_MUX_SEL_0}
# 請填入本地設計／製程的設定值，保持原資料型別
        set CK_MUX_SEL_1 {FILL_IN_CK_MUX_SEL_1}
    }

    3 {
        # CK_mux_sel[1:0] = 2'b11 -> cpu_clk_i
# 請填入本地設計／製程的設定值，保持原資料型別
        set CK_MUX_SEL_0 {FILL_IN_CK_MUX_SEL_0}
# 請填入本地設計／製程的設定值，保持原資料型別
        set CK_MUX_SEL_1 {FILL_IN_CK_MUX_SEL_1}
    }

    default {
        error "Invalid CLK_CONFIG=$config_option, valid values: 0 1 2 3"
    }
}

set_case_analysis $CK_MUX_SEL_0 \
    [get_pins -hierarchical {
        *u_dvfs_ckmux_l0_0/S
        *u_dvfs_ckmux_l0_1/S
    }]

set_case_analysis $CK_MUX_SEL_1 \
    [get_pins -hierarchical {
        *u_dvfs_ckmux_l1/S
    }]
