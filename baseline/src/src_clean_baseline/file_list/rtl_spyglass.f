//include
../include/TOP.svh

//pkg
../src/src_clean_baseline/AXI-4/AXI.pkg

//TU
../src/src_clean_baseline/TU/CHIP.v
../src/src_clean_baseline/TU/top_interface.sv

//AXI
../src/src_clean_baseline/AXI-4/interface_define.sv
../src/src_clean_baseline/AXI-4/AXI.sv
../src/src_clean_baseline/AXI-4/slave_simple.sv
../src/src_clean_baseline/AXI-4/master_simple.sv
../src/src_clean_baseline/AXI-4/Cross_Bar2.sv
../src/src_clean_baseline/AXI-4/arbitrator.sv

//CDC
../src/src_clean_baseline/CDC/G_converter.sv
../src/src_clean_baseline/CDC/FIFO.sv
../src/src_clean_baseline/CDC/reset_sync.sv

//CPU
../src/src_clean_baseline/CPU/CPU_wrapper.sv
../src/src_clean_baseline/CPU/CPU_plug.sv
../src/src_clean_baseline/CPU/CPU.sv
../src/src_clean_baseline/CPU/stage/IF_stage.v
../src/src_clean_baseline/CPU/stage/ID_stage.v
../src/src_clean_baseline/CPU/stage/EXE_stage.v
../src/src_clean_baseline/CPU/stage/EXE_stage/ALU.v
../src/src_clean_baseline/CPU/stage/EXE_stage/FALU.v
../src/src_clean_baseline/CPU/stage/EXE_stage/CSR.v
../src/src_clean_baseline/CPU/stage/MEM_stage.v
../src/src_clean_baseline/CPU/stage/WB_stage.v

../src/src_clean_baseline/CPU/pref/WFI.v
../src/src_clean_baseline/CPU/pref/I_Cache.sv
../src/src_clean_baseline/CPU/pref/D_Cache.sv
//../src/src_clean_baseline/CPU/pref/ibuf.sv
../src/src_clean_baseline/CPU/pref/PDC.sv

//IP
//WDT
../src/src_clean_baseline/IP/WDT/WDT_wrapper.sv
../src/src_clean_baseline/IP/WDT/WDT_plug.sv
../src/src_clean_baseline/IP/WDT/WDT.sv

//MEM
../src/src_clean_baseline/IP/MEM/SRAM_wrapper.sv
../src/src_clean_baseline/IP/MEM/SRAM_plug.sv
../src/src_clean_baseline/IP/MEM/ROM_wrapper.sv
../src/src_clean_baseline/IP/MEM/DRAM_wrapper.sv

//DMA
../src/src_clean_baseline/IP/DMA/DMA_wrapper.sv

//PMU
../src/src_clean_baseline/IP/TD/PMU.sv
../src/src_clean_baseline/IP/TD/TD_MAP.svh
../src/src_clean_baseline/IP/TD/TD_loacal_unit.sv
../src/src_clean_baseline/IP/TD/TD_center_unit.sv
../src/src_clean_baseline/IP/TD/DVFS_unit.sv
../src/src_clean_baseline/IP/TD/inner_dma.sv

//PLIC
../src/src_clean_baseline/IP/PLIC/PLIC.sv
