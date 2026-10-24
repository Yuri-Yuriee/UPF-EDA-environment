ELF_NAME := main

export CROSS_PREFIX ?= riscv64-unknown-elf-
export RISCV_GCC ?= $(CROSS_PREFIX)gcc
export RISCV_OBJDUMP ?= $(CROSS_PREFIX)objdump
export RISCV_OBJCOPY ?= $(CROSS_PREFIX)objcopy

LDFILE := link.ld

ARCH_ABI := -march=rv32im -mabi=ilp32

CFLAGS  := $(ARCH_ABI) -ffreestanding -nostdlib -nostartfiles
LDFLAGS := $(ARCH_ABI) -static -nostdlib -nostartfiles -T$(LDFILE) -lgcc

SRC_C := $(wildcard *.c)
OBJ_C := $(patsubst %.c,%.o,$(SRC_C))

SRC_S := $(wildcard *.S)
OBJ_S := $(patsubst %.S,%.o,$(SRC_S))

SRC := $(SRC_C) $(SRC_S)
OBJ := $(OBJ_C) $(OBJ_S)

.PHONY: all build_elf build_log build_hex clean

all: build_elf build_log build_hex

build_elf: $(ELF_NAME)

$(ELF_NAME): $(OBJ) $(LDFILE)
	$(RISCV_GCC) $(OBJ) $(LDFLAGS) -o $@

build_log: $(ELF_NAME)
	$(RISCV_OBJDUMP) -xsd $< > $(ELF_NAME).log

# build_hex: $(ELF_NAME)
# 	$(RISCV_OBJCOPY) -O verilog $< -i 4 -b 0 -j .text0 --change-addresses 0 rom0.hex
# 	$(RISCV_OBJCOPY) -O verilog $< -i 4 -b 1 -j .text0 --change-addresses 0 rom1.hex
# 	$(RISCV_OBJCOPY) -O verilog $< -i 4 -b 2 -j .text0 --change-addresses 0 rom2.hex
# 	$(RISCV_OBJCOPY) -O verilog $< -i 4 -b 3 -j .text0 --change-addresses 0 rom3.hex
# 	$(RISCV_OBJCOPY) -O verilog $< -i 4 -b 0 -R .text0 --change-addresses -0x20000000 dram0.hex
# 	$(RISCV_OBJCOPY) -O verilog $< -i 4 -b 1 -R .text0 --change-addresses -0x20000000 dram1.hex
# 	$(RISCV_OBJCOPY) -O verilog $< -i 4 -b 2 -R .text0 --change-addresses -0x20000000 dram2.hex
# 	$(RISCV_OBJCOPY) -O verilog $< -i 4 -b 3 -R .text0 --change-addresses -0x20000000 dram3.hex

build_hex: $(ELF_NAME)
	$(RISCV_OBJCOPY) -O verilog $< -i 4 -b 0 -j .fsbl --change-addresses 0 rom0.hex
	$(RISCV_OBJCOPY) -O verilog $< -i 4 -b 1 -j .fsbl --change-addresses 0 rom1.hex
	$(RISCV_OBJCOPY) -O verilog $< -i 4 -b 2 -j .fsbl --change-addresses 0 rom2.hex
	$(RISCV_OBJCOPY) -O verilog $< -i 4 -b 3 -j .fsbl --change-addresses 0 rom3.hex
	$(RISCV_OBJCOPY) -O verilog $< -i 4 -b 0 -R .fsbl --change-addresses -0x20000000 dram0.hex
	$(RISCV_OBJCOPY) -O verilog $< -i 4 -b 1 -R .fsbl --change-addresses -0x20000000 dram1.hex
	$(RISCV_OBJCOPY) -O verilog $< -i 4 -b 2 -R .fsbl --change-addresses -0x20000000 dram2.hex
	$(RISCV_OBJCOPY) -O verilog $< -i 4 -b 3 -R .fsbl --change-addresses -0x20000000 dram3.hex

%.o: %.S
	$(RISCV_GCC) -c $(CFLAGS) $< -o $@

%.o: %.c
	$(RISCV_GCC) -c $(CFLAGS) $< -o $@

clean:
	rm -rf $(ELF_NAME) $(ELF_NAME).log rom*.hex dram*.hex *.o