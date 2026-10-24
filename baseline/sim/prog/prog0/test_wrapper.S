.section .text
.align 2
.globl run_testProg_with_test_stack
.type run_testProg_with_test_stack, @function

.extern testProg

/*
 * C function prototype:
 *
 * void run_testProg_with_test_stack(uint32_t output_base,
 *                                  uint32_t stack_end);
 *
 * a0 = output_base
 * a1 = stack_end
 */
run_testProg_with_test_stack:
    /*
     * 保存 wrapper 自己要恢復的東西
     */
    addi sp, sp, -32

    sw   ra, 28(sp)
    sw   s1, 24(sp)

    /*
     * testProg 會測 CSR，所以先備份 CSR
     */
    csrr t0, mstatus
    sw   t0, 20(sp)

    csrr t0, mie
    sw   t0, 16(sp)

    csrr t0, mtvec
    sw   t0, 12(sp)

    csrr t0, mepc
    sw   t0, 8(sp)

    /*
     * s1 保存原本 wrapper stack frame
     */
    mv   s1, sp

    /*
     * a1 是 C 傳進來的 test stack end
     * stack 往低位址長
     * 目前先只做 4-byte alignment
     */
    mv   sp, a1
    andi sp, sp, -4

    /*
     * a0 不要動
     * a0 會直接傳給 testProg 當 output base
     */
    call testProg

    /*
     * 回到原本 stack
     */
    mv   sp, s1

    /*
     * 恢復 CSR
     */
    lw   t0, 8(sp)
    csrw mepc, t0

    lw   t0, 12(sp)
    csrw mtvec, t0

    lw   t0, 16(sp)
    csrw mie, t0

    lw   t0, 20(sp)
    csrw mstatus, t0

    /*
     * 恢復 wrapper register
     */
    lw   s1, 24(sp)
    lw   ra, 28(sp)

    addi sp, sp, 32
    ret