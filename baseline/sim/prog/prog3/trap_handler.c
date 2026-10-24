#include <stdint.h>

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
// PLIC init
// main 裡面要先呼叫一次
// =====================================================
void plic_init(void) {
    // source ID 1 = DMA
    PLIC_PRIORITY(PLIC_SRC_DMA) = 1;

    // source ID 2 = TD / PMU
    PLIC_PRIORITY(PLIC_SRC_TD) = 1;

    // enable source ID 1 and source ID 2
    // bit 0 不用
    // bit 1 = DMA
    // bit 2 = TD
    PLIC_ENABLE = (1 << PLIC_SRC_DMA) | (1 << PLIC_SRC_TD);

    // priority > threshold 才會觸發
    PLIC_THRESHOLD = 0;
}

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
void external_interrupt_handler(void) {
    volatile unsigned int *dma_addr_boot = (volatile unsigned int *) DMA_BASE;

    asm("csrsi mstatus, 0x0"); // MIE of mstatus

    unsigned int id;

    // claim：讀 PLIC_CLAIM，取得 interrupt source ID
    id = PLIC_CLAIM;

    if (id == PLIC_SRC_DMA) {
        // source ID 1 = DMA interrupt

        dma_addr_boot[0x40] = 0; // disable DMA
    }
    else if (id == PLIC_SRC_TD) {
        // source ID 2 = TD / PMU interrupt

        // 這裡先用 sysA_cause_reg 清掉
        // 如果你的 PMU RTL 是其他 clear 方法，這行再改
        sysA_cause_reg = 0;

        // 如果你想直接關掉 TD warning interrupt，也可以打開這行
        // sysA_TD_warning_interrupt_En = 0;
    }

    // complete：寫回剛剛 claim 到的 ID
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