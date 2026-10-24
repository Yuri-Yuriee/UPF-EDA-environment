typedef enum logic[15:0] {
    STD_off          = 16'h0000,
    STD_S0_set       = 16'h000a,
    STD_S1_init      = 16'h0001,
    STD_S2_load      = 16'h0002,
    STD_S3_FTest     = 16'h0003,
    STD_S4_RF        = 16'h0004,
    STD_S5_STest     = 16'h0005,
    STD_S6_noError   = 16'h0006,
    STD_S7_yesError  = 16'h0007,
    STD_S8_marginSet = 16'h0008,
    STD_idal         = 16'hFFFF
} TD_ST;

// =====================================================
// S7 PMU TD_center MMIO
// range: 0x3000_0000 ~ 0x3000_0034
// =====================================================
`define sysA_cause_reg                  32'h3000_0000
`define sysA_TD_DVFS_start_reg          32'h3000_0004
`define sysA_TD_calib_start_reg         32'h3000_0008
`define sysA_TD_valid                   32'h3000_000C
`define sysA_TD_error_margin_reg        32'h3000_0010
`define sysA_TD_warning_margin_reg      32'h3000_0014
`define sysA_TD_warning_interrupt_En    32'h3000_0018
`define sysA_testProg_srcA              32'h3000_001C
`define sysA_testProg_trgA              32'h3000_0020
`define sysA_testProg_len               32'h3000_0024
`define sysA_TD_calib_done_mask_reg     32'h3000_0028
`define sysA_TD_voltage_only_mask_reg   32'h3000_002C
`define sysA_TD_calib_idx_reg           32'h3000_0030
`define sysA_TD_broad_reg               32'h3000_0034
`define sysA_TD_calib_claim             32'h3000_0038


// =====================================================
// S8 PMU DVFS MMIO
// range: 0x3001_0000 ~ 0x3001_000C
// =====================================================
`define DVFS_mode_setup_reg             32'h3001_0000
`define DVFS_ultra_reg                  32'h3001_0004
`define DVFS_v_step_reg                 32'h3001_0008
`define DVFS_f_step_reg                 32'h3001_000C