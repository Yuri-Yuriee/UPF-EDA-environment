#include <stdint.h>
#include <stddef.h>

// =====================================================
// MMIO base address
// =====================================================
#define DMAEN_ADDR      0x10020100UL
#define DESC_BASE_ADDR  0x10020200UL
#define DMA_DESC_LIST   0x0002FF00UL

#define PLIC_BASE       0x3C000000UL

// =====================================================
// PLIC register
// source ID 1 = DMA interrupt
// source ID 2 = TD interrupt
// =====================================================
#define PLIC_PRIORITY(id) (*(volatile uint32_t *)(PLIC_BASE + 0x00000000UL + 4UL * (id)))
#define PLIC_ENABLE       (*(volatile uint32_t *)(PLIC_BASE + 0x00002000UL))
#define PLIC_THRESHOLD    (*(volatile uint32_t *)(PLIC_BASE + 0x00200000UL))

#define PLIC_SRC_DMA 1
#define PLIC_SRC_TD  2

// =====================================================
// linker symbols
// 這些 symbol 要來自 linker script
// =====================================================
extern uint32_t _dram_i_start;
extern uint32_t _dram_i_end;
extern uint32_t _imem_start;

extern uint32_t __data_paddr_start;
extern uint32_t __data_start;
extern uint32_t __data_end;

extern uint32_t __sdata_paddr_start;
extern uint32_t __sdata_start;
extern uint32_t __sdata_end;


// =====================================================
// CSR helper
// =====================================================
static inline void enable_m_mode_interrupts(void)
{
    // mie = MSIE | MTIE | MEIE = bit3 | bit7 | bit11 = 0x888
    asm volatile("csrw mie, %0" :: "r"(0x888));

    // mstatus.MIE = bit 3
    asm volatile("csrs mstatus, %0" :: "r"(1 << 3));
}

static inline void wait_for_interrupt(void)
{
    asm volatile("wfi");
}


// =====================================================
// PLIC init
// =====================================================
static inline void plic_init(void)
{
    // source ID 1 = DMA interrupt
    PLIC_PRIORITY(PLIC_SRC_DMA) = 1;

    // source ID 2 = TD interrupt
    PLIC_PRIORITY(PLIC_SRC_TD) = 1;

    // boot 這裡只等 DMA interrupt，所以只 enable DMA
    // bit 1 = source ID 1
    PLIC_ENABLE = (1 << PLIC_SRC_DMA);

    // priority > threshold 才會進 CPU
    PLIC_THRESHOLD = 0;
}


// =====================================================
// boot function
// =====================================================
void boot(void)
{
    volatile uint32_t *DMAEN          = (volatile uint32_t *)DMAEN_ADDR;
    volatile uint32_t *DESC_BASE      = (volatile uint32_t *)DESC_BASE_ADDR;
    volatile uint32_t *dma_desc_list  = (volatile uint32_t *)DMA_DESC_LIST;

    uint32_t len;

    // =====================================================
    // PLIC init
    // 要放在開 CPU interrupt 之前
    // =====================================================
    plic_init();

    // =====================================================
    // Enable M-mode interrupts
    // =====================================================
    enable_m_mode_interrupts();


    // =====================================================
    // DMA Descriptor 1: Copy instruction segment
    //
    // dma_desc_list[0] = &_dram_i_start
    // dma_desc_list[1] = &_imem_start
    // dma_desc_list[2] = &_dram_i_end - &_dram_i_start + 1
    // dma_desc_list[3] = next descriptor address
    // dma_desc_list[4] = 0
    // =====================================================
    dma_desc_list[0] = (uint32_t)(uintptr_t)&_dram_i_start;
    dma_desc_list[1] = (uint32_t)(uintptr_t)&_imem_start;

    len = (uint32_t)((uintptr_t)&_dram_i_end - (uintptr_t)&_dram_i_start);
    len = (len >> 2) + 1;
    dma_desc_list[2] = len;

    dma_desc_list[3] = (uint32_t)(uintptr_t)&dma_desc_list[5];
    dma_desc_list[4] = 0;


    // =====================================================
    // DMA Descriptor 2: Copy .data segment
    //
    // dma_desc_list[5] = &__data_paddr_start
    // dma_desc_list[6] = &__data_start
    // dma_desc_list[7] = length
    // dma_desc_list[8] = next descriptor address
    // dma_desc_list[9] = 0
    // =====================================================
    dma_desc_list[5] = (uint32_t)(uintptr_t)&__data_paddr_start;
    dma_desc_list[6] = (uint32_t)(uintptr_t)&__data_start;

    len = (uint32_t)((uintptr_t)&__data_end - (uintptr_t)&__data_start);
    len = (len >> 2) + 1;
    dma_desc_list[7] = len;

    dma_desc_list[8] = (uint32_t)(uintptr_t)&dma_desc_list[10];
    dma_desc_list[9] = 0;


    // =====================================================
    // DMA Descriptor 3: Copy .sdata segment
    //
    // dma_desc_list[10] = &__sdata_paddr_start
    // dma_desc_list[11] = &__sdata_start
    // dma_desc_list[12] = length
    // dma_desc_list[13] = 0
    // dma_desc_list[14] = 1
    // =====================================================
    dma_desc_list[10] = (uint32_t)(uintptr_t)&__sdata_paddr_start;
    dma_desc_list[11] = (uint32_t)(uintptr_t)&__sdata_start;

    len = (uint32_t)((uintptr_t)&__sdata_end - (uintptr_t)&__sdata_start);
    len = (len >> 2) + 1;
    dma_desc_list[12] = len;

    dma_desc_list[13] = 0;
    dma_desc_list[14] = 1;


    // =====================================================
    // Launch DMA
    // DESC_BASE[0] = &dma_desc_list
    // DMAEN[0] = 1
    // =====================================================
    DESC_BASE[0] = (uint32_t)(uintptr_t)dma_desc_list;

    DMAEN[0] = 1;

    // Wait for DMA interrupt
    wait_for_interrupt();

    // Disable DMA controller
    DMAEN[0] = 0;
}