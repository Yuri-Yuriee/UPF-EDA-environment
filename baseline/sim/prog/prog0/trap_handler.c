#include <stdint.h>
#define REG32(addr) (*(volatile unsigned int *)(addr))


#define sysA_cause_reg                  0x30000000u
#define sysA_TD_DVFS_start_reg          0x30000004u
#define sysA_TD_calib_start_reg         0x30000008u
#define sysA_TD_valid                   0x3000000Cu
#define sysA_TD_error_margin_reg        0x30000010u
#define sysA_TD_warning_margin_reg      0x30000014u
#define sysA_TD_warning_interrupt_En    0x30000018u
#define sysA_testProg_srcA              0x3000001Cu
#define sysA_testProg_trgA              0x30000020u
#define sysA_testProg_len               0x30000024u
#define sysA_TD_calib_done_mask_reg     0x30000028u
#define sysA_TD_voltage_only_mask_reg   0x3000002Cu
#define sysA_TD_calib_idx_reg           0x30000030u
#define sysA_TD_broad_reg               0x30000034u
#define sysA_TD_calib_claim             0x30000038u

#define STD_off                         0x0000u
#define STD_S0_set                      0x000Au
#define STD_S1_init                     0x0001u
#define STD_S2_load                     0x0002u
#define STD_S3_FTest                    0x0003u
#define STD_S4_RF                       0x0004u
#define STD_S5_STest                    0x0005u
#define STD_S6_noError                  0x0006u
#define STD_S7_yesError                 0x0007u
#define STD_S8_marginSet                0x0008u
#define STD_idal                        0xFFFFu


#define MIP_MEIP (1 << 11) // External interrupt pending
#define MIP_MTIP (1 << 7)  // Timer interrupt pending
#define MIP      0x344

// =====================================================
// MMIO base
// =====================================================
#define WDT_BASE   0x10010000UL
#define DMA_BASE   0x10020000UL
#define PLIC_BASE  0x3C000000UL
#define PMU_BASE   0x30000000UL

volatile unsigned int *WDT_addr = (volatile unsigned int *) WDT_BASE;
volatile unsigned int *dma_addr_boot = (volatile unsigned int *) DMA_BASE;

// =====================================================
// PLIC register
// source ID 1 = DMA interrupt
// source ID 2 = TD / PMU interrupt
// =====================================================
#define PLIC_PRIORITY(id) (*(volatile unsigned int *)(PLIC_BASE + 0x00000000 + 4 * (id)))
#define PLIC_PENDING      (*(volatile unsigned int *)(PLIC_BASE + 0x00001000))
#define PLIC_ENABLE       (*(volatile unsigned int *)(PLIC_BASE + 0x00002000))
#define PLIC_THRESHOLD    (*(volatile unsigned int *)(PLIC_BASE + 0x00200000))
#define PLIC_CLAIM        (*(volatile unsigned int *)(PLIC_BASE + 0x00200004))

#define PLIC_SRC_DMA 1
#define PLIC_SRC_TD  2

// =====================================================
// PMU / TD register
// =====================================================
#define sysA_cause_reg               (*(volatile unsigned int *)(PMU_BASE + 0x00000000))
#define sysA_TD_warning_interrupt_En (*(volatile unsigned int *)(PMU_BASE + 0x00000018))



// =====================================================
// Timer interrupt handler
// MTIP / WDT
// =====================================================
void timer_interrupt_handler(void) {
    asm("csrsi mstatus, 0x0"); // MIE of mstatus

    WDT_addr[0x40] = 0; // WDT_en

    asm("j _start");
}

// =====================================================
// External interrupt handler
// MEIP / PLIC
// =====================================================
void external_interrupt_handler(void)
{
    volatile unsigned int *dma_addr_boot = (volatile unsigned int *)DMA_BASE;

    unsigned int id;
    unsigned int cause_raw;
    unsigned int td_state;

    /*
     * claim PLIC interrupt source ID
     */
     
    asm("csrsi mstatus, 0x0"); // MIE of mstatus
    id = PLIC_CLAIM;

    if (id == PLIC_SRC_DMA) {
        /*
         * source ID 1 = DMA interrupt
         */
        dma_addr_boot[0x40] = 0;   // disable DMA
    }
    else if (id == PLIC_SRC_TD) {
        /*
         * source ID 2 = TD / PMU interrupt
         *
         * 先讀 sysA_cause_reg 檢查狀態
         */
        cause_raw = REG32(sysA_cause_reg);

        /*
         * 如果你的 C code 寫 cause 是：
         * REG32(sysA_cause_reg) = state << 16;
         *
         * 那這裡就用 high 16 bits 解析 state。
         */
        td_state = (cause_raw >> 16) & 0xFFFFu;

        /*
         * 目前先不要做任何狀態處理
         * 只是把 state 讀出來，方便之後 debug / breakpoint
         */
        switch (td_state) {
            case STD_off:
            case STD_S0_set:
            case STD_S1_init:
            case STD_S2_load:
            case STD_S3_FTest:
            case STD_S4_RF:
            case STD_S5_STest:
            case STD_S6_noError:
            case STD_S7_yesError:
            case STD_S8_marginSet:
            case STD_idal:
            default:
                break;
        }

        /*
         * TD interrupt ack / claim clear
         * 直接對 0x3000_0038 寫 1
         */
        REG32(sysA_TD_calib_claim) = 1u;
    }

    /*
     * complete PLIC interrupt
     */
    if (id != 0) {
        PLIC_CLAIM = id;
    }
}
// =====================================================
// Trap handler
// =====================================================
void trap_handler(void) {
    uint32_t mip;

    asm volatile("csrr %0, %1" : "=r"(mip) : "i"(MIP));

    if ((mip & MIP_MTIP) >> 7) {
        timer_interrupt_handler();
    }

    if ((mip & MIP_MEIP) >> 11) {
        external_interrupt_handler();
    }
}




// #include <stdint.h>

// #define MIP_MEIP (1 << 11) // External interrupt pending
// #define MIP_MTIP (1 << 7)  // Timer interrupt pending
// #define MIP 0x344

// volatile unsigned int *WDT_addr = (int *) 0x10010000;
// volatile unsigned int *dma_addr_boot = (int *) 0x10020000;

// void timer_interrupt_handler(void) {
//   asm("csrsi mstatus, 0x0"); // MIE of mstatus
//   WDT_addr[0x40] = 0; // WDT_en
//   asm("j _start");
// }

// void external_interrupt_handler(void) {
// 	volatile unsigned int *dma_addr_boot = (int *) 0x10020000;
// 	asm("csrsi mstatus, 0x0"); // MIE of mstatus
// 	dma_addr_boot[0x40] = 0; // disable DMA
// }

// void trap_handler(void) {
//     uint32_t mip;
//     asm volatile("csrr %0, %1" : "=r"(mip) : "i"(MIP));
	
//     if ((mip & MIP_MTIP) >> 7) {
//         timer_interrupt_handler();
//     }

//     if ((mip & MIP_MEIP) >> 11) {
//         external_interrupt_handler();
//     }

// }