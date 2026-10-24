/*
 * Header-less version.
 * Do not include comp.h / test_wrapper.h / stdint.h.
 * Keep the real function bodies in comp.o and test_wrapper.o during link.
 */
typedef unsigned int uint32_t;

typedef struct {
    uint32_t result;
    uint32_t diff_offset;
    uint32_t mem0_value;
    uint32_t mem1_value;
} mem_cmp_result_t;

extern int compare_mem32(uint32_t mem0_base,
                         uint32_t mem1_base,
                         uint32_t byte_size,
                         mem_cmp_result_t *result);

extern void run_testProg_with_test_stack(uint32_t output_base,
                                         uint32_t stack_end);

/* ============================================================
 * Very simple bare-metal PMU TD/DVFS test code
 *
 * Style:
 *   - no printf
 *   - no stdio
 *   - no malloc
 *   - direct MMIO address access
 *
 * Note:
 *   Your new MMIO map does not include TD_center state_raw register.
 *   Therefore this version uses delay instead of wait_center_state().
 * ============================================================ */

#define REG32(addr) (*(volatile unsigned int *)(addr))

/* ============================================================
 * TD state value
 * ============================================================ */
#define STD_off                         0x0000
#define STD_S0_set                      0x000A
#define STD_S1_init                     0x0001
#define STD_S2_load                     0x0002
#define STD_S3_FTest                    0x0003
#define STD_S4_RF                       0x0004
#define STD_S5_STest                    0x0005
#define STD_S6_noError                  0x0006
#define STD_S7_yesError                 0x0007
#define STD_S8_marginSet                0x0008
#define STD_idal                        0xFFFF

/* ============================================================
 * S7 PMU TD_center MMIO
 * range: 0x3000_0000 ~ 0x3000_0034
 * ============================================================ */
#define sysA_cause_reg                  0x30000000
#define sysA_TD_DVFS_start_reg          0x30000004
#define sysA_TD_calib_start_reg         0x30000008
#define sysA_TD_valid                   0x3000000C
#define sysA_TD_error_margin_reg        0x30000010
#define sysA_TD_warning_margin_reg      0x30000014
#define sysA_TD_warning_interrupt_En    0x30000018
#define sysA_testProg_srcA              0x3000001C
#define sysA_testProg_trgA              0x30000020
#define sysA_testProg_len               0x30000024
#define sysA_TD_calib_done_mask_reg     0x30000028
#define sysA_TD_voltage_only_mask_reg   0x3000002C
#define sysA_TD_calib_idx_reg           0x30000030
#define sysA_TD_broad_reg               0x30000034

/* ============================================================
 * S8 PMU DVFS MMIO
 * range: 0x3001_0000 ~ 0x3001_000C
 * ============================================================ */
#define DVFS_mode_setup_reg             0x30010000
#define DVFS_ultra_reg                  0x30010004
#define DVFS_v_step_reg                 0x30010008
#define DVFS_f_step_reg                 0x3001000C

/* ============================================================
 * Debug variables
 * You can watch these in waveform / debugger / memory dump.
 * ============================================================ */
volatile unsigned int test_result = 0;
volatile unsigned int error_code  = 0;

#define TEST_RUNNING                    0x11111111
#define TEST_PASS                       0x5555AAAA
#define TEST_FAIL                       0xDEAD0000


/* ============================================================
 * Compare result log in DM
 *
 * Put this object into section ".cmp_log".
 * Linker script should map ".cmp_log" to dmem.
 * ============================================================ */
#define CMP_LOG_MAGIC                   0xC0A60001
#define CMP_LOG_ENTRY_NUM               64

#define CMP_PHASE_NOERROR_LOOP          0x00000001
#define CMP_PHASE_ERROR_LOOP            0x00000002
#define CMP_PHASE_REAL_TEST_LOOP        0x00000003

typedef struct {
    uint32_t seq;
    uint32_t phase;
    uint32_t loop_id;
    uint32_t iter;
    uint32_t result;
    uint32_t diff_offset;
    uint32_t mem0_value;
    uint32_t mem1_value;
} cmp_log_entry_t;

typedef struct {
    uint32_t magic;
    uint32_t total_count;
    uint32_t write_idx;

    uint32_t last_phase;
    uint32_t last_loop_id;
    uint32_t last_iter;
    uint32_t last_result;
    uint32_t last_diff_offset;
    uint32_t last_mem0_value;
    uint32_t last_mem1_value;

    cmp_log_entry_t entry[CMP_LOG_ENTRY_NUM];
} cmp_log_t;

volatile cmp_log_t cmp_log __attribute__((section(".cmp_log"), used));



static mem_cmp_result_t cmp_result;

extern char _test_start[];
extern char _golden_test_start[];

extern char _test_stack0_end[];
extern char _test_stack1_end[];

extern char _STACK_SIZE[];
extern char _TEST_SIZE[];


/* ============================================================
 * Compare log helpers
 * ============================================================ */
void cmp_log_init(void)
{
    unsigned int i;

    cmp_log.magic       = CMP_LOG_MAGIC;
    cmp_log.total_count = 0;
    cmp_log.write_idx   = 0;

    cmp_log.last_phase       = 0;
    cmp_log.last_loop_id     = 0;
    cmp_log.last_iter        = 0;
    cmp_log.last_result      = 0;
    cmp_log.last_diff_offset = 0;
    cmp_log.last_mem0_value  = 0;
    cmp_log.last_mem1_value  = 0;

    for (i = 0; i < CMP_LOG_ENTRY_NUM; i++) {
        cmp_log.entry[i].seq         = 0;
        cmp_log.entry[i].phase       = 0;
        cmp_log.entry[i].loop_id     = 0;
        cmp_log.entry[i].iter        = 0;
        cmp_log.entry[i].result      = 0;
        cmp_log.entry[i].diff_offset = 0;
        cmp_log.entry[i].mem0_value  = 0;
        cmp_log.entry[i].mem1_value  = 0;
    }
}

void cmp_log_record(uint32_t phase,
                    uint32_t loop_id,
                    uint32_t iter,
                    int cmp_ret)
{
    uint32_t idx;
    uint32_t result;

    if (cmp_ret == 0) {
        result = TEST_PASS;
    } else {
        result = TEST_FAIL;
    }

    idx = cmp_log.write_idx;
    if (idx >= CMP_LOG_ENTRY_NUM) {
        idx = 0;
    }

    
    cmp_log.write_idx   = idx + 1;

    cmp_log.last_phase       = phase;
    cmp_log.last_loop_id     = loop_id;
    cmp_log.last_iter        = iter;
    cmp_log.last_result      = result;
    cmp_log.last_diff_offset = cmp_result.diff_offset;
    cmp_log.last_mem0_value  = cmp_result.mem0_value;
    cmp_log.last_mem1_value  = cmp_result.mem1_value;

    cmp_log.entry[idx].seq         = cmp_log.total_count;
    cmp_log.entry[idx].phase       = phase;
    cmp_log.entry[idx].loop_id     = loop_id;
    cmp_log.entry[idx].iter        = iter;
    cmp_log.entry[idx].result      = result;
    cmp_log.entry[idx].diff_offset = cmp_result.diff_offset;
    cmp_log.entry[idx].mem0_value  = cmp_result.mem0_value;
    cmp_log.entry[idx].mem1_value  = cmp_result.mem1_value;
    cmp_log.total_count = cmp_log.total_count + 1;          // 加在最後 告訴 tb 有更新
}

/* ============================================================
 * Simple delay
 * ============================================================ */
void delay(unsigned int n)
{
    volatile unsigned int i;

    for (i = 0; i < n; i++) {
        asm volatile("nop");
    }
}

/* ============================================================
 * Write TD cause register
 *
 * Original SV:
 *   center_mmio_write(sysA_cause_reg, {STD_xxx, 16'h0000});
 * ============================================================ */
void write_cause(unsigned int state)
{
    REG32(sysA_cause_reg) = (state << 16);
}

/* ============================================================
 * STEP 0 ~ STEP 3
 *
 * Original SV task:
 *   tb_init_flow()
 * ============================================================ */
void tb_init_flow(void)
{
    volatile unsigned int rd_tmp;


    /* STEP 0:
     * DVFS default mode = mode_up
     */
    REG32(DVFS_mode_setup_reg) = 1;

    delay(1000);


    /* STEP 1:
     * setup TD center MMIO registers
     */
    REG32(sysA_TD_DVFS_start_reg)        = 1;
    REG32(sysA_TD_calib_start_reg)       = 1;
    REG32(sysA_TD_error_margin_reg)      = 2;
    REG32(sysA_TD_warning_margin_reg)    = 1;
    REG32(sysA_TD_warning_interrupt_En)  = 1;
    REG32(sysA_TD_voltage_only_mask_reg) = 0;
    REG32(sysA_TD_calib_idx_reg)         = 0;

    delay(1000);


    /* STEP 2:
     * load test program from Flash to memory
     */
    REG32(sysA_testProg_srcA) = 0x20100000;
    REG32(sysA_testProg_trgA) = 0x0002FF00;
    REG32(sysA_testProg_len)  = 16;

    /* Original TB reads back TD_DVFS_start once */
    rd_tmp = REG32(sysA_TD_DVFS_start_reg);
    (void)rd_tmp;

    delay(1000);


    /* STEP 3:
     * kick TD center FSM
     */
    write_cause(STD_S0_set);
}

/* ============================================================
 * One no-error loop
 *
 * Original SV task:
 *   run_noerror_test_loop()
 *
 * Because new MMIO map has no state_raw register, this version
 * cannot poll STD_S1/S2/S3/S5/S6. It uses delay instead.
 * ============================================================ */
void run_noerror_test_loop(unsigned int loop_id)
{
    int cmp_ret;
    /* Wait center enter S1_init / S2_load / S3_FTest */
    delay(50);

    delay(50);


    // S3_FTest 
    run_testProg_with_test_stack(
        (uint32_t)_test_start,
        (uint32_t)_test_stack0_end
    );

    /* FTest PASS, update state to STD_S4_RF */
    write_cause(STD_S4_RF);

    delay(50);

    /* Wait STD_S4_RF reduce voltage and enter STD_S5_STest */
    // STD_S5_STest
    run_testProg_with_test_stack(
        (uint32_t)_golden_test_start,
        (uint32_t)_test_stack1_end
    );
    
    cmp_ret = compare_mem32(
        (uint32_t)_test_start,
        (uint32_t)_golden_test_start,
        (uint32_t)_TEST_SIZE,
        &cmp_result
    );

    cmp_log_record(CMP_PHASE_NOERROR_LOOP, loop_id, 0, cmp_ret);

    /* STest PASS, update state to STD_S6_noError */
    write_cause(STD_S6_noError);

    delay(50);

}

/* ============================================================
 * Final error loop
 *
 * Original SV:
 *   LOOP 4 - final error round
 * ============================================================ */
void run_error_test_loop(void)
{
    int cmp_ret;
    /* Wait center enter S1_init / S2_load / S3_FTest */
    // F_TEST
    run_testProg_with_test_stack(
        (uint32_t)_test_start,
        (uint32_t)_test_stack0_end
    );

    // F_TEST_done
    write_cause(STD_S4_RF);

    // S_TEST
    run_testProg_with_test_stack(
        (uint32_t)_golden_test_start,
        (uint32_t)_test_stack1_end
    );

    // comp
    cmp_ret = compare_mem32(
        (uint32_t)_test_start,
        (uint32_t)_golden_test_start,
        (uint32_t)_TEST_SIZE,
        &cmp_result
    );

    cmp_log_record(CMP_PHASE_ERROR_LOOP, 4, 0, 1);

    write_cause(STD_S7_yesError);
}

void run_test_loop(unsigned int loop_id)
{
    unsigned int iter = 0;
    int cmp_ret;

    while (1) {
        /*
         * 每跑一輪 iter + 1
         * 方便 waveform 看現在 stress 幾次
         */
        iter++;

        /* Wait center enter S1_init / S2_load / S3_FTest */
        delay(50);

        delay(50);

        /*
         * S3_FTest
         */
        run_testProg_with_test_stack(
            (uint32_t)_test_start,
            (uint32_t)_test_stack0_end
        );

        /*
         * FTest PASS, update state to STD_S4_RF
         */
        write_cause(STD_S4_RF);

        delay(50);

        /*
         * S5_STest
         */
        run_testProg_with_test_stack(
            (uint32_t)_golden_test_start,
            (uint32_t)_test_stack1_end
        );

        /*
         * Compare FTest and STest result
         *
         * PASS:
         *   write STD_S6_noError and continue next round.
         *
         * FAIL:
         *   write STD_S7_yesError and leave run_test_loop().
         */
        cmp_ret = compare_mem32(
            (uint32_t)_test_start,
            (uint32_t)_golden_test_start,
            (uint32_t)_TEST_SIZE,
            &cmp_result
        );

        cmp_log_record(CMP_PHASE_REAL_TEST_LOOP, loop_id, iter, cmp_ret);

        if (cmp_ret != 0) {
            test_result = TEST_FAIL;
            error_code  = cmp_result.diff_offset;

            write_cause(STD_S7_yesError);

            return;
        }

        /*
         * STest PASS, update state to STD_S6_noError
         */
        write_cause(STD_S6_noError);
        /*
         * This round PASS.
         * Then continue while(1), waiting for next lower-voltage round.
         */
    }
}


/* ============================================================
 * SSBL
 * ============================================================ */
__attribute__((used))
void SSBL(void)
{
    test_result = TEST_RUNNING;
    error_code  = 0;

    cmp_log_init();

    tb_init_flow();

    run_noerror_test_loop(1);
    run_noerror_test_loop(2);
    run_noerror_test_loop(3);

    run_error_test_loop();

    //run_test_loop()

    test_result = TEST_PASS;


    return;
}


