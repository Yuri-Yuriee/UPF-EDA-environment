#include <stdint.h>
unsigned int *copy_addr; // = &_test_start;



#define MIP_MEIP (1 << 11) // External interrupt pending
#define MIP_MTIP (1 << 7)  // Timer interrupt pending
#define MIP 0x344




int main(void) {
  extern unsigned int _test_start;
  copy_addr = &_test_start;
  volatile unsigned int *WDT_addr = (int *) 0x10010000;
  *(copy_addr) = 0;
  *(copy_addr) = -1;
  // Enable Global Interrupt
  asm("csrsi mstatus, 0x8"); // MIE of mstatus

  // Enable Local Interrupt
  asm("li t6, 0x80");
  asm("csrs mie, t6"); // MEIE of mie 
 
  WDT_addr[0xc0] = 10000; // tonet
  WDT_addr[0x40] = 1; // WDT_en
  
  int a = 1;
  int b = 2;
  int c = 0;
  
	  for(int i = 0; i < 100; i++){
		for(int j = 0; j < 100; j++){ 
		  c = c + j;
		}
		  WDT_addr[0x80] = 1; // live_en
          WDT_addr[0x80] = 0; // live_en 
	  }
	  *(copy_addr + 1) = c;

  return 0;
}
