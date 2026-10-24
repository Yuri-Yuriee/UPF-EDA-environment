#include <stdint.h>
unsigned int *copy_addr; // = &_test_start;


#define MIP_MEIP (1 << 11) // External interrupt pending
#define MIP_MTIP (1 << 7)  // Timer interrupt pending
#define MIP 0x344

int main() {
	extern float add1;  // 32-bit float
    extern float add2;  // 32-bit float
    extern float sub1;  // 32-bit float
    extern float sub2;  // 32-bit float

    // result address
    extern float _test_start;

    *(&_test_start) = add1 + add2;
    *(&_test_start + 1) = sub1 - sub2;

	return 0;
}



