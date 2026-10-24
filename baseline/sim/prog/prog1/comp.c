#include <stdint.h>

#define MEM_CMP_PASS  0x00000000u
#define MEM_CMP_FAIL  0xFFFFFFFFu

typedef struct {
    uint32_t result;       // 0 = same, 0xFFFFFFFF = different
    uint32_t diff_offset;  // byte offset of first mismatch
    uint32_t mem0_value;   // value from mem0
    uint32_t mem1_value;   // value from mem1
} mem_cmp_result_t;


/*
 * Compare two memory blocks word by word.
 *
 * mem0_base : first memory base address
 * mem1_base : second memory base address
 * byte_size : compare size in bytes, must be multiple of 4
 * result    : where to store compare result
 *
 * return:
 *   0 : same
 *   1 : different
 */
int compare_mem32(uint32_t mem0_base,
                  uint32_t mem1_base,
                  uint32_t byte_size,
                  mem_cmp_result_t *result)
{
    volatile uint32_t *mem0 = (volatile uint32_t *)mem0_base;
    volatile uint32_t *mem1 = (volatile uint32_t *)mem1_base;

    uint32_t word_size = byte_size >> 2;

    result->result      = MEM_CMP_PASS;
    result->diff_offset = 0;
    result->mem0_value  = 0;
    result->mem1_value  = 0;

    for (uint32_t i = 0; i < word_size; i++) {
        uint32_t v0 = mem0[i];
        uint32_t v1 = mem1[i];

        if (v0 != v1) {
            result->result      = MEM_CMP_FAIL;
            result->diff_offset = i << 2;
            result->mem0_value  = v0;
            result->mem1_value  = v1;
            return 1; //error
        }
    }

    return 0;
}