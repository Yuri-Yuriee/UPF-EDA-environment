OUTPUT_ARCH( "riscv" )

_STACK_SIZE = DEFINED(_STACK_SIZE) ? _STACK_SIZE : 0x1000;
_TEST_SIZE = DEFINED(_TEST_SIZE) ? _TEST_SIZE : 0x1000;

/*****************************************************************************
 * Define memory layout
 ****************************************************************************/
MEMORY {
  rom         : ORIGIN = 0x00000000, LENGTH = 0x00002000
  imem        : ORIGIN = 0x00010000, LENGTH = 0x00010000

  dmem        : ORIGIN = 0x00020000, LENGTH = 0x0000E000
  cmp_log_mem : ORIGIN = 0x0002E000, LENGTH = 0x00001000
  tb_reserved : ORIGIN = 0x0002F000, LENGTH = 0x00001000

  dram_i      : ORIGIN = 0x20000000, LENGTH = 0x00100000
  dram_d      : ORIGIN = 0x20100000, LENGTH = 0x00100000
}

/* Specify the default entry point to the program */

ENTRY(_start)

/*****************************************************************************
 * Define the sections, and where they are mapped in memory 
 ****************************************************************************/
SECTIONS {
  .fsbl : {
    setup.o(.text);
    boot.o(.text);
  } > rom

  .text1 : {
      _imem_start = .;
      isr.o(.text .text.*);
      trap_handler.o(.text .text.*);
      ssbl.o(.text .text.*);
      *(.text);
      *(.text.*);
  } > imem AT > dram_i

  .init : {
    KEEP (*(.init))
  } > imem AT > dram_i

  .fini : {
    KEEP (*(.fini))
  } > imem AT > dram_i

  .rodata : {
    __rodata_start = .;
    *(.rodata)
    *(.rodata.*)
    *(.gnu.linkonce.r.*)
    __rodata_end = .;
  } > imem AT > dram_i

  _dram_i_start = ORIGIN(dram_i);
  _dram_i_end = ORIGIN(dram_i) + . - ORIGIN(imem);

_test : {
  . = ALIGN(4);
  _test_start = .;
  . += _TEST_SIZE;
  _test_end = .;

  . = ALIGN(4);
  _test_stack0_start = .;
  . += _STACK_SIZE;
  _test_stack0_end = .;

  . = ALIGN(4);
  _golden_test_start = .;
  . += _TEST_SIZE;
  _golden_test_end = .;

  . = ALIGN(4);
  _test_stack1_start = .;
  . += _STACK_SIZE;
  _test_stack1_end = .;
} > dram_d

  .sbss : {
    __sbss_start = .;
    *(.sbss)
    *(.sbss.*)
    *(.gnu.linkonce.sb.*)
    __sbss_end = .;
  } > dmem

  .sdata : {
    __sdata_paddr_start = LOADADDR(.sdata);
    __sdata_start = .;
    _gp = . + 0x800;
    *(.srodata.cst16) *(.srodata.cst8) *(.srodata.cst4) *(.srodata.cst2) *(.srodata*)
    *(.sdata .sdata.* .gnu.linkonce.s.*)
    __sdata_end = .;
  } > dmem AT > dram_d

  .data : {
    . = ALIGN(4);
    __data_paddr_start = LOADADDR(.data);
    __data_start = .;
    *(.data)
    *(.data.*)
    *(.gnu.linkonce.d.*)
    __data_end = .;
  } > dmem AT > dram_d

  .bss : {
    . = ALIGN(4);
    __bss_start = .;
    *(.bss)
    *(.bss.*)
    *(.gnu.linkonce.b.*)
    *(COMMON)
    . = ALIGN(4);
    __bss_end = .;
  } > dmem

  .cmp_log (NOLOAD) : {
    . = ALIGN(4);
    _cmp_log_start = .;
    KEEP(*(.cmp_log))
    . = ALIGN(4);
    _cmp_log_end = .;
  } > cmp_log_mem

  .stack : {
    . = ALIGN(4);
    _stack_end = .;
    . += _STACK_SIZE;
    _stack = .;
    __stack = _stack;
  } > dmem

  . = ORIGIN(tb_reserved) + LENGTH(tb_reserved) - 4;
  _sim_end = .;
  . += 4;
  _end = .;
}
