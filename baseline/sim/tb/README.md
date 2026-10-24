# Testbenches

All existing project testbenches are grouped here with tb_ filename prefixes. Module names are unchanged.

- tb_top.sv: existing main simulation, DRAMSys and gate-level test entry.
- tb_top_WDT.sv: existing WDT/program-3 test entry.
- tb_testTD.sv: existing timing/DVFS test entry.
- tb_FIFO_top.sv: existing FIFO test entry.
- tb_DRAM.sv / tb_ROM.sv: standalone memory model unit tests.
- tb_ALU_I.v / tb_ALU_R.v / tb_FALU.v / tb_ID_stage.v / tb_IF_stage.v: preserved CPU unit tests.

Use project-root Makefile targets for the existing integrated flows. DUT implementations remain in sim/IP/ or src/. Testbench filenames changed, but waveform module hierarchy (including top_tb) did not.

Compile testbenches selectively, not as one wildcard set: main/WDT variants share module top_tb; DRAM/ROM unit tests share module test. Select an appropriate include search path for standalone compilation (the Makefile adds sim/tb). Existing unit DUTs still reference some missing historical headers such as define_list.v and predict.v; moving tests does not supply them.

The historical Retention testbench is missing; its expected new path is sim/tb/tb_testRetention.sv. No placeholder test or fabricated PASS was added. Native VCS/RTL regression was not performed.
