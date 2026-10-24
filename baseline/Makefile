# =============================================================================
# Project Makefile
#
# This file is organized by flow stage. Existing paths, variables, options,
# targets, dependencies, and command lines are preserved without modification.
# =============================================================================

# -----------------------------------------------------------------------------
# Project directories and library paths
# -----------------------------------------------------------------------------
root_dir := $(CURDIR)
src_dir := ./src
syn_dir := ./syn
# pr_dir := ./pr/icc2_REFERENCE_PLATFORM_provider/run
pr_dir := "./APR_new/innovus_stylus/APR"
inc_dir := ./include
sim_dir := ./sim
vip_dir := $(PWD)/vip
bld_dir := ./build
bld_pr_dir := ./build_PR


# -----------------------------------------------------------------------------
# DRAMSys RTL co-simulation
# -----------------------------------------------------------------------------
# PULP RTL-to-DRAMSys bridge repository. This is separate from the standalone
# DRAMSys 5.6 tree because the RTL bridge builds its own patched simulator
# library (libDRAMSys_Simulator.so).
# Use := instead of ?= so an empty environment variable cannot erase the
# project defaults. Command-line assignments still override these values.
DRAM_RTL_SIM_ROOT := /FILL_IN/FILL_IN_RESOURCE_0001
DRAMSYS_ROOT       := $(DRAM_RTL_SIM_ROOT)/dramsys_lib/DRAMSys
DRAMSYS_LIB_DIR    := $(DRAMSYS_ROOT)/build/lib
DRAMSYS_RES_DIR    := $(DRAMSYS_ROOT)/configs
SOC_DRAMSYS_DIR    := $(root_dir)/src/src_clean_baseline/IP/MEM

# GCC used to build the PULP DRAMSys/SystemC shared libraries.
DRAMSYS_CC          ?= /opt/gcc-11.2/bin/gcc
DRAMSYS_CXX         ?= /opt/gcc-11.2/bin/g++
DRAMSYS_GCC_LIB_DIR ?= /opt/gcc-11.2/lib64
DRAMSYS_JOBS        ?= 8

# Slave 3 DRAM AXI base address. Override on the command line when required:
# Address map S3: 0x2000_0000 through 0x201F_FFFF (2 MiB).
# Override only when the SoC address map changes.
DRAMSYS_AXI_BASE ?= 20000000
DRAMSYS_AXI_MAX  ?= 201FFFFF
DRAMSYS_PROG     ?= 0

# The custom wrapper directly uses this project's axi_read_if/axi_write_if, so
# PULP axi_dram_sim.sv and its additional AXI dependencies are not compiled.
DRAMSYS_SV_SOURCES := \
	$(DRAM_RTL_SIM_ROOT)/src/sim_dram.sv \
	$(DRAM_RTL_SIM_ROOT)/src/dram_sim_engine.sv \
	$(SOC_DRAMSYS_DIR)/DRAMSys_wrap.sv

# Optional runtime additions, for example:
#   make rtl0_dramsys DRAMSYS_RUN_ARGS='+DRAMSYS_SKIP_HEX_PRELOAD +ONE_DRAM_PRELOAD=/path/program.elf'
DRAMSYS_VCS_OPTS ?=
DRAMSYS_RUN_ARGS ?=

# -----------------------------------------------------------------------------
# Process / APR flow selection
# -----------------------------------------------------------------------------
# Usage:
#   make innovus PROCESS=REFERENCE_PLATFORM
#   make innovus PROCESS=TECH_MV
PROCESS ?= TECH_MV

# Each process flow must contain:
#   script/PR/<PROCESS>/init.setup
#   script/PR/<PROCESS>/setup/
#   script/PR/<PROCESS>/run/
PR_FLOW_DIR       := $(root_dir)/script/PR/$(PROCESS)
PR_SETUP_SRC      := $(PR_FLOW_DIR)/setup
PR_RUN_SRC        := $(PR_FLOW_DIR)/run
PR_INIT_SETUP_SRC := $(PR_FLOW_DIR)/init.setup

# >>> TECH_MV_FULL_INSTALLER:VERIFY_VARIABLES >>>
# -----------------------------------------------------------------------------
# Physical verification flow selection
# -----------------------------------------------------------------------------
# Physical Verify is intentionally independent from APR PROCESS.
#
# APR:
#   make innovus PROCESS=TECH_MV
#
# TECH Verify:
#   make verify_check
#   make verify_lvs
#   make verify_signoff
#
# Override only if another process has its own compatible verify tree.
VERIFY_PROCESS      ?= TECH_MV
VERIFY_PROCESS_DIR  := $(root_dir)/script/PR/$(VERIFY_PROCESS)
VERIFY_FLOW_SRC     := $(VERIFY_PROCESS_DIR)/verify
VERIFY_BUILD_DIR    := $(bld_pr_dir)/verify
VERIFY_OUTPUT_DIR   ?= $(root_dir)/build_PR/outputs
VERIFY_TOP          ?= $(TOP_MODULE)
# <<< TECH_MV_FULL_INSTALLER:VERIFY_VARIABLES <<<












































# Common Innovus startup script.
INNOVUS_STARTUP ?= $(root_dir)/script/PR/innovus_startup.tcl
INNOVUS_CPUS    ?= 8
TOP_MODULE      ?= CHIP

lib_dir := /FILL_IN/FILL_IN_RESOURCE_0002
lib_dir_io ?= /FILL_IN/FILL_IN_RESOURCE_0003

# Gate-level simulation model. Override this for another process when needed.
STD_CELL_VERILOG ?= /FILL_IN/FILL_IN_RESOURCE_0004


# SpyGlass library-conversion inputs and outputs
LIB_F := /FILL_IN/FILL_IN_RESOURCE_0005
OUT_SGLIB := /FILL_IN/FILL_IN_RESOURCE_0006
opt := 


# -----------------------------------------------------------------------------
# Runtime option mapping
# -----------------------------------------------------------------------------
# FSDB=1 enables normal FSDB dumping; FSDB=2 enables full FSDB dumping.
FSDB_DEF :=
ifeq ($(FSDB),1)
FSDB_DEF := +FSDB
else ifeq ($(FSDB),2)
FSDB_DEF := +FSDB_ALL
endif

# Map the external pend option to the exported maxpend value.
maxpend :=
ifeq ($(pend),1)
	maxpend := 1
else ifeq ($(pend),2) 
	maxpend := 2
else
	maxpend := 0
endif
$(info maxpend=$(maxpend))


# -----------------------------------------------------------------------------
# Exported variables for sub-make processes and external tools
# -----------------------------------------------------------------------------
export vip_dir
export maxpend


# -----------------------------------------------------------------------------
# Generated-directory targets
# -----------------------------------------------------------------------------
$(bld_dir):
	mkdir -p $(bld_dir)

$(bld_pr_dir):
	mkdir -p $(bld_pr_dir)

$(syn_dir):
	mkdir -p $(syn_dir)

$(pr_dir):
	mkdir -p $(pr_dir)

# AXI simulation

# -----------------------------------------------------------------------------
# AXI bridge and grading entry points
# -----------------------------------------------------------------------------
# Launch the JasperGold AXI bridge environment.
vip_b: clean | $(bld_dir)
	cd $(bld_dir); \
	jg ../script/jg_bridge.tcl &

# TA use this to check result

# Reserved entry point used by the teaching assistant.
TA_run: 
  
# RTL simulation

# -----------------------------------------------------------------------------
# RTL simulation
# -----------------------------------------------------------------------------
# Run all four RTL programs.
rtl_all: rtl0 rtl1 rtl2 rtl3


# Program 0 RTL simulation.
rtl0: | clean $(bld_dir)
	make -C $(sim_dir)/prog/prog0/; \
	cd $(bld_dir); \
	vcs -R -sverilog $(root_dir)/$(sim_dir)/tb/tb_top.sv -debug_access+all -full64 -debug_region+cell +memcbk \
	+incdir+$(root_dir)/$(src_dir)+$(root_dir)/$(src_dir)/AXI+$(root_dir)/$(inc_dir)+$(root_dir)/$(sim_dir)+$(root_dir)/$(sim_dir)/IP+$(root_dir)/tech+$(root_dir)/$(sim_dir)/tb \
	-f $(root_dir)/$(src_dir)/src_clean_baseline/file_list/rtl_sim.f \
	+define+prog0$(FSDB_DEF) \
	+prog_path=$(root_dir)/$(sim_dir)/prog/prog0 \
  	+rdcycle=1 \
	+lint=TFIPC-L \
	+notimingcheck | tee ../log/vcs.log

rtl0_dram: | clean $(bld_dir)
	make -C $(sim_dir)/prog/prog0/; \
	cd $(bld_dir); \
	vcs -R -sverilog $(root_dir)/$(sim_dir)/tb/tb_top.sv -debug_access+all -full64 -debug_region+cell +memcbk \
	+incdir+$(root_dir)/$(src_dir)+$(root_dir)/$(src_dir)/AXI+$(root_dir)/$(inc_dir)+$(root_dir)/$(sim_dir)+$(root_dir)/$(sim_dir)/IP+$(root_dir)/tech+$(root_dir)/$(sim_dir)/tb \
	-f $(root_dir)/$(src_dir)/src_clean_baseline/file_list/rtl_dram.f \
	+define+prog0$(FSDB_DEF) \
	+prog_path=$(root_dir)/$(sim_dir)/prog/prog0 \
  	+rdcycle=1 \
	+lint=TFIPC-L \
	+notimingcheck | tee ../log/vcs.log



# -----------------------------------------------------------------------------
# DRAMSys RTL co-simulation targets
# -----------------------------------------------------------------------------
# Build the patched DRAMSys/SystemC libraries supplied by PULP. CMake >= 3.28.1
# must be visible in PATH before running this target.
dramsys_lib:
	@test -d "$(DRAM_RTL_SIM_ROOT)" || { \
		echo "ERROR: dram_rtl_sim is not found: $(DRAM_RTL_SIM_ROOT)"; \
		exit 1; \
	}
	cd "$(DRAM_RTL_SIM_ROOT)" && \
	CC="$(DRAMSYS_CC)" CXX="$(DRAMSYS_CXX)" \
	$(MAKE) -j$(DRAMSYS_JOBS) dramsys

# Validate all files needed by the RTL co-simulation before invoking VCS.
check_dramsys:
	@echo "DRAM_RTL_SIM_ROOT = $(DRAM_RTL_SIM_ROOT)"
	@echo "DRAMSYS_ROOT      = $(DRAMSYS_ROOT)"
	@echo "DRAMSYS_LIB_DIR   = $(DRAMSYS_LIB_DIR)"
	@echo "DRAMSYS_RES_DIR   = $(DRAMSYS_RES_DIR)"
	@echo "SOC_DRAMSYS_DIR   = $(SOC_DRAMSYS_DIR)"
	@test -x "$(DRAMSYS_CC)" || { echo "ERROR: GCC not found: $(DRAMSYS_CC)"; exit 1; }
	@test -x "$(DRAMSYS_CXX)" || { echo "ERROR: G++ not found: $(DRAMSYS_CXX)"; exit 1; }
	@test -f "$(DRAM_RTL_SIM_ROOT)/src/sim_dram.sv" || { echo "ERROR: sim_dram.sv not found: $(DRAM_RTL_SIM_ROOT)/src/sim_dram.sv"; exit 1; }
	@test -f "$(DRAM_RTL_SIM_ROOT)/src/dram_sim_engine.sv" || { echo "ERROR: dram_sim_engine.sv not found: $(DRAM_RTL_SIM_ROOT)/src/dram_sim_engine.sv"; exit 1; }
	@test -f "$(SOC_DRAMSYS_DIR)/DRAMSys_wrap.sv" || { echo "ERROR: DRAMSys_wrap.sv not found: $(SOC_DRAMSYS_DIR)/DRAMSys_wrap.sv"; exit 1; }
	@test -f "$(DRAMSYS_RES_DIR)/ddr4-example.json" || { echo "ERROR: DDR4 configuration not found: $(DRAMSYS_RES_DIR)/ddr4-example.json"; exit 1; }
	@test -f "$(DRAMSYS_LIB_DIR)/libsystemc.so" || { echo "ERROR: libsystemc.so not found: $(DRAMSYS_LIB_DIR)/libsystemc.so"; echo "Run: make dramsys_lib"; exit 1; }
	@test -f "$(DRAMSYS_LIB_DIR)/libDRAMSys_Simulator.so" || { echo "ERROR: libDRAMSys_Simulator.so not found: $(DRAMSYS_LIB_DIR)/libDRAMSys_Simulator.so"; echo "Run: make dramsys_lib"; exit 1; }
	@echo "DRAMSys co-simulation files are ready."
	@echo "  AXI range: 0x$(DRAMSYS_AXI_BASE) - 0x$(DRAMSYS_AXI_MAX)"

# Generic target. DRAMSYS_PROG may be 0, 1, or 2.
# The VCS compile and simv execution are intentionally separated: GCC 11's
# libstdc++ is exposed only to simv, not to the VCS compiler executable.
rtl_dramsys: check_dramsys | clean $(bld_dir)
	@test "$(DRAMSYS_PROG)" = "0" -o "$(DRAMSYS_PROG)" = "1" -o "$(DRAMSYS_PROG)" = "2" || { \
		echo "ERROR: DRAMSYS_PROG must be 0, 1, or 2"; \
		exit 1; \
	}
	make -C $(sim_dir)/prog/prog$(DRAMSYS_PROG)/; \
	mkdir -p $(root_dir)/log; \
	cd $(bld_dir); \
	vcs -sverilog $(root_dir)/$(sim_dir)/tb/tb_top.sv \
		-debug_access+all -full64 -debug_region+cell +memcbk \
		+incdir+$(root_dir)/$(src_dir)+$(root_dir)/$(src_dir)/AXI+$(root_dir)/$(inc_dir)+$(root_dir)/$(sim_dir)+$(root_dir)/$(sim_dir)/IP+$(root_dir)/tech+$(root_dir)/$(sim_dir)/tb \
		-f $(root_dir)/$(src_dir)/src_clean_baseline/file_list/rtl_dram.f \
		$(DRAMSYS_SV_SOURCES) \
		+define+prog$(DRAMSYS_PROG)+DRAMSYS$(FSDB_DEF) \
		+lint=TFIPC-L \
		$(DRAMSYS_VCS_OPTS) \
		-o simv \
		-l ../log/vcs_dramsys_compile.log && \
	LD_LIBRARY_PATH="$(DRAMSYS_GCC_LIB_DIR):$(DRAMSYS_LIB_DIR):$${LD_LIBRARY_PATH:-}" \
	./simv \
		-sv_lib $(DRAMSYS_LIB_DIR)/libsystemc \
		-sv_lib $(DRAMSYS_LIB_DIR)/libDRAMSys_Simulator \
		+DRAMSYS_RES=$(DRAMSYS_RES_DIR) \
		+DRAMSYS_BASE_ADDR=$(DRAMSYS_AXI_BASE) \
		+prog_path=$(root_dir)/$(sim_dir)/prog/prog$(DRAMSYS_PROG) \
		+rdcycle=1 \
		+notimingcheck \
		$(DRAMSYS_RUN_ARGS) \
		-l ../log/vcs_dramsys_run.log

rtl0_dramsys:
	$(MAKE) rtl_dramsys DRAMSYS_PROG=0

rtl1_dramsys:
	$(MAKE) rtl_dramsys DRAMSYS_PROG=1

rtl2_dramsys:
	$(MAKE) rtl_dramsys DRAMSYS_PROG=2

# Program 0 RTL simulation with UPF power intent.
rtl0_UPF: | clean $(bld_dir)
	make -C $(sim_dir)/prog/prog0/; \
	cd $(bld_dir); \
	vcs -R -sverilog $(root_dir)/$(sim_dir)/tb/tb_top.sv -debug_access+all -full64 -debug_region+cell +memcbk \
	+incdir+$(root_dir)/$(src_dir)+$(root_dir)/$(src_dir)/AXI+$(root_dir)/$(inc_dir)+$(root_dir)/$(sim_dir)+$(root_dir)/$(sim_dir)/IP+$(root_dir)/tech+$(root_dir)/$(sim_dir)/tb \
	-f $(root_dir)/$(src_dir)/src_clean_baseline/file_list/rtl_sim.f \
	+define+prog0$(FSDB_DEF) \
	+prog_path=$(root_dir)/$(sim_dir)/prog/prog0 \
  	+rdcycle=1 \
	-upf "../script/MV/UPF/MSV.upf" \
	-lca \
	+lint=TFIPC-L \
	+notimingcheck | tee ../log/vcs.log


# Program 1 RTL simulation.
rtl1: | clean $(bld_dir)
	make -C $(sim_dir)/prog/prog1/; \
	cd $(bld_dir); \
	vcs -R -sverilog $(root_dir)/$(sim_dir)/tb/tb_top.sv -debug_access+all -full64 -debug_region+cell +memcbk \
	+incdir+$(root_dir)/$(src_dir)+$(root_dir)/$(src_dir)/AXI+$(root_dir)/$(inc_dir)+$(root_dir)/$(sim_dir)+$(root_dir)/$(sim_dir)/IP+$(root_dir)/tech+$(root_dir)/$(sim_dir)/tb \
	-f $(root_dir)/$(src_dir)/src_clean_baseline/file_list/rtl_sim.f \
	+define+prog1$(FSDB_DEF) \
	+prog_path=$(root_dir)/$(sim_dir)/prog/prog1 \
	+rdcycle=1 \
	+notimingcheck | tee ../log/vcs.log


# Program 1 RTL simulation with UPF power intent.
rtl1_UPF: | clean $(bld_dir)
	make -C $(sim_dir)/prog/prog1/; \
	cd $(bld_dir); \
	vcs -R -sverilog $(root_dir)/$(sim_dir)/tb/tb_top.sv -debug_access+all -full64 -debug_region+cell +memcbk \
	+incdir+$(root_dir)/$(src_dir)+$(root_dir)/$(src_dir)/AXI+$(root_dir)/$(inc_dir)+$(root_dir)/$(sim_dir)+$(root_dir)/$(sim_dir)/IP+$(root_dir)/tech+$(root_dir)/$(sim_dir)/tb \
	-f $(root_dir)/$(src_dir)/src_clean_baseline/file_list/rtl_sim.f \
	+define+prog1$(FSDB_DEF) \
	+prog_path=$(root_dir)/$(sim_dir)/prog/prog1 \
	-upf "../script/MV/UPF/MSV.upf" \
	-lca \
	+lint=TFIPC-L \
	+rdcycle=1 \
	+notimingcheck | tee ../log/vcs.log


# Program 2 RTL simulation.
rtl2: | clean $(bld_dir)
	make -C $(sim_dir)/prog/prog2/; \
	cd $(bld_dir); \
	vcs -R -sverilog $(root_dir)/$(sim_dir)/tb/tb_top.sv -debug_access+all -full64 -debug_region+cell +memcbk \
	+incdir+$(root_dir)/$(src_dir)+$(root_dir)/$(src_dir)/AXI+$(root_dir)/$(inc_dir)+$(root_dir)/$(sim_dir)+$(root_dir)/$(sim_dir)/IP+$(root_dir)/tech+$(root_dir)/$(sim_dir)/tb \
	-f $(root_dir)/$(src_dir)/src_clean_baseline/file_list/rtl_sim.f \
	+define+prog2$(FSDB_DEF) \
	+prog_path=$(root_dir)/$(sim_dir)/prog/prog2 \
	+rdcycle=1 \
	+notimingcheck | tee ../log/vcs.log


# Program 2 RTL simulation with UPF power intent.
rtl2_UPF: | clean $(bld_dir)
	make -C $(sim_dir)/prog/prog2/; \
	cd $(bld_dir); \
	vcs -R -sverilog $(root_dir)/$(sim_dir)/tb/tb_top.sv -debug_access+all -full64 -debug_region+cell +memcbk \
	+incdir+$(root_dir)/$(src_dir)+$(root_dir)/$(src_dir)/AXI+$(root_dir)/$(inc_dir)+$(root_dir)/$(sim_dir)+$(root_dir)/$(sim_dir)/IP+$(root_dir)/tech+$(root_dir)/$(sim_dir)/tb \
	-f $(root_dir)/$(src_dir)/src_clean_baseline/file_list/rtl_sim.f \
	+define+prog2$(FSDB_DEF) \
	+prog_path=$(root_dir)/$(sim_dir)/prog/prog2 \
	-upf "../script/MV/UPF/MSV.upf" \
	-lca \
	+lint=TFIPC-L \
	+rdcycle=1 \
	+notimingcheck | tee ../log/vcs.log



# Program 3 WDT RTL simulation.
rtl3: | clean $(bld_dir)
	make -C $(sim_dir)/prog/prog3/; \
	cd $(bld_dir); \
	vcs -R -sverilog $(root_dir)/$(sim_dir)/tb/tb_top_WDT.sv -debug_access+all -full64 -debug_region+cell +memcbk \
	+incdir+$(root_dir)/$(src_dir)+$(root_dir)/$(src_dir)/AXI+$(root_dir)/$(inc_dir)+$(root_dir)/$(sim_dir)+$(root_dir)/$(sim_dir)/IP+$(root_dir)/tech+$(root_dir)/$(sim_dir)/tb \
	-f $(root_dir)/$(src_dir)/src_clean_baseline/file_list/rtl_sim.f \
	+define+prog3$(FSDB_DEF) \
	+prog_path=$(root_dir)/$(sim_dir)/prog/prog3 \
	+rdcycle=1 \
	+notimingcheck | tee ../log/vcs.log


# Program 3 WDT RTL simulation with UPF power intent.
rtl3_UPF: | clean $(bld_dir)
	make -C $(sim_dir)/prog/prog3/; \
	cd $(bld_dir); \
	vcs -R -sverilog $(root_dir)/$(sim_dir)/tb/tb_top_WDT.sv -debug_access+all -full64 -debug_region+cell +memcbk \
	+incdir+$(root_dir)/$(src_dir)+$(root_dir)/$(src_dir)/AXI+$(root_dir)/$(inc_dir)+$(root_dir)/$(sim_dir)+$(root_dir)/$(sim_dir)/IP+$(root_dir)/tech+$(root_dir)/$(sim_dir)/tb \
	-f $(root_dir)/$(src_dir)/src_clean_baseline/file_list/rtl_sim.f \
	+define+prog3$(FSDB_DEF) \
	+prog_path=$(root_dir)/$(sim_dir)/prog/prog3 \
	-upf "../script/MV/UPF/MSV.upf" \
	-lca \
	+lint=TFIPC-L \
	+rdcycle=1 \
	+notimingcheck | tee ../log/vcs.log


# -----------------------------------------------------------------------------
# Standalone RTL feature tests
# -----------------------------------------------------------------------------
# TD-specific RTL testbench.
rtl_testTD: | clean $(bld_dir)
	cd $(bld_dir); \
	vcs -R -sverilog $(root_dir)/$(sim_dir)/tb/tb_testTD.sv -debug_access+all -full64 -debug_region+cell +memcbk \
	+incdir+$(root_dir)/$(src_dir)+$(root_dir)/$(src_dir)/AXI+$(root_dir)/$(inc_dir)+$(root_dir)/$(sim_dir)+$(root_dir)/$(sim_dir)/IP+$(root_dir)/tech+$(root_dir)/$(sim_dir)/tb \
	-f $(root_dir)/$(src_dir)/src_clean_baseline/file_list/rtl_TD.f \
	+rdcycle=1 \
	+notimingcheck | tee ../log/vcs.log


# Retention-cell simulation without UPF.
test_Retention: | clean $(bld_dir)
	cd $(bld_dir); \
	vcs -R -sverilog $(root_dir)/$(sim_dir)/tb/tb_testRetention.sv -debug_access+all -full64 -debug_region+cell +memcbk \
	+lint=TFIPC-L \
	+rdcycle=1 \
	+nospecify | tee ../log/vcs.log


# Retention-cell simulation with UPF and power configuration.
test_Retention_UPF: | clean $(bld_dir)
	cd $(bld_dir); \
	vcs -R -sverilog $(root_dir)/$(sim_dir)/tb/tb_testRetention.sv -debug_access+all -full64 -debug_region+cell +memcbk \
	+lint=TFIPC-L \
	+rdcycle=1 \
	-power "/FILL_IN/FILL_IN_RESOURCE_0007" \
	-power_config ../script/VCS_NLP/lib.cfg \
	-upf "/FILL_IN/FILL_IN_RESOURCE_0008"
	+nospecify | tee ../log/vcs.log

#-power_config ../script/VCS_NLP/lib.cfg \
# Post-Synthesis simulation


test_FIFO: | clean $(bld_dir)
	cd $(bld_dir); \
	vcs -R -sverilog $(root_dir)/$(sim_dir)/tb/tb_FIFO_top.sv -debug_access+all -full64 -debug_region+cell +memcbk \
	-f $(root_dir)/$(src_dir)/FIFO_TU/file_list/rtl.f \
	+rdcycle=1 \
	+nospecify | tee ../log/vcs.log


# -----------------------------------------------------------------------------
# Post-synthesis gate-level simulation
# -----------------------------------------------------------------------------
# Run all four post-synthesis programs.
syn_all: syn0 syn1 syn2 syn3



# Program 0 post-synthesis simulation.
syn0: | clean $(bld_dir)
	make -C $(sim_dir)/prog/prog0/; \
	cd $(bld_dir); \
	vcs -R -sverilog +neg_tchk -negdelay -v $(STD_CELL_VERILOG)  $(root_dir)/$(sim_dir)/tb/tb_top.sv -debug_access+all -full64 -diag=sdf:verbose -debug_region+cell \
	+incdir+$(root_dir)/$(syn_dir)+$(root_dir)/$(inc_dir)+$(root_dir)/$(sim_dir)+$(root_dir)/$(sim_dir)/IP+$(root_dir)/tech+$(root_dir)/$(sim_dir)/tb \
	+define+SYN+prog0$(FSDB_DEF) \
	+no_notifier \
	+prog_path=$(root_dir)/$(sim_dir)/prog/prog0 \
  	+rdcycle=1 \
	+notimingcheck \
  	+nospecify | tee ../log/vcs.log

	# +nospecify \
	# +notimingcheck
	# +delay_mode_zero \


# Program 0 post-synthesis simulation with UPF.
syn0_UPF: | clean $(bld_dir)
	make -C $(sim_dir)/prog/prog0/; \
	cd $(bld_dir); \
	vcs -R -sverilog +neg_tchk -negdelay -v $(STD_CELL_VERILOG)  $(root_dir)/$(sim_dir)/tb/tb_top.sv -debug_access+all -full64 -diag=sdf:verbose \
	+incdir+$(root_dir)/$(syn_dir)+$(root_dir)/$(inc_dir)+$(root_dir)/$(sim_dir)+$(root_dir)/$(sim_dir)/IP+$(root_dir)/tech+$(root_dir)/$(sim_dir)/tb \
	+define+SYN+prog0$(FSDB_DEF) \
	+no_notifier \
	+prog_path=$(root_dir)/$(sim_dir)/prog/prog0 \
  	+rdcycle=1 \
	-lca \
	-power=verbosel \
	-power_config ../script/VCS_NLP/lib.cfg \
	-upf ../script/MV/UPF/MSV.upf \
	-power=unconnected_bias_pins_on \
  	+nospecify | tee ../log/vcs.log

#
#"../syn/DC_out.upf"



# Program 1 post-synthesis simulation.
syn1: | clean $(bld_dir)
	make -C $(sim_dir)/prog/prog1/; \
	cd $(bld_dir); \
	vcs -R -sverilog +neg_tchk -negdelay -v $(STD_CELL_VERILOG)  $(root_dir)/$(sim_dir)/tb/tb_top.sv -debug_access+all -full64 -diag=sdf:verbose \
	+incdir+$(root_dir)/$(syn_dir)+$(root_dir)/$(inc_dir)+$(root_dir)/$(sim_dir)+$(root_dir)/$(sim_dir)/IP+$(root_dir)/tech+$(root_dir)/$(sim_dir)/tb \
	+define+SYN+prog1$(FSDB_DEF) \
	+no_notifier \
	+prog_path=$(root_dir)/$(sim_dir)/prog/prog1 \
  	+rdcycle=1 \
  	+nospecify | tee ../log/vcs.log


# Program 1 post-synthesis simulation with UPF.
syn1_UPF: | clean $(bld_dir)
	make -C $(sim_dir)/prog/prog1/; \
	cd $(bld_dir); \
	vcs -R -sverilog +neg_tchk -negdelay -v $(STD_CELL_VERILOG)  $(root_dir)/$(sim_dir)/tb/tb_top.sv -debug_access+all -full64 -diag=sdf:verbose \
	+incdir+$(root_dir)/$(syn_dir)+$(root_dir)/$(inc_dir)+$(root_dir)/$(sim_dir)+$(root_dir)/$(sim_dir)/IP+$(root_dir)/tech+$(root_dir)/$(sim_dir)/tb \
	+define+SYN+prog1$(FSDB_DEF) \
	+no_notifier \
	+prog_path=$(root_dir)/$(sim_dir)/prog/prog1 \
  	+rdcycle=1 \
	-lca \
	-power_config ../script/VCS_NLP/lib.cfg \
	-upf "../script/MV/UPF/MSV.upf" \
  	+nospecify | tee ../log/vcs.log


# Program 2 post-synthesis simulation.
syn2: | clean $(bld_dir)
	make -C $(sim_dir)/prog/prog2/; \
	cd $(bld_dir); \
	vcs -R -sverilog +neg_tchk -negdelay -v $(STD_CELL_VERILOG)  $(root_dir)/$(sim_dir)/tb/tb_top.sv -debug_access+all -full64 -diag=sdf:verbose \
	+incdir+$(root_dir)/$(syn_dir)+$(root_dir)/$(inc_dir)+$(root_dir)/$(sim_dir)+$(root_dir)/$(sim_dir)/IP+$(root_dir)/tech+$(root_dir)/$(sim_dir)/tb \
	+define+SYN+prog2$(FSDB_DEF) \
	+no_notifier \
	+prog_path=$(root_dir)/$(sim_dir)/prog/prog2 \
	+nospecify | tee ../log/vcs.log


# Program 2 post-synthesis simulation with UPF.
syn2_UPF: | clean $(bld_dir)
	make -C $(sim_dir)/prog/prog2/; \
	cd $(bld_dir); \
	vcs -R -sverilog +neg_tchk -negdelay -v $(STD_CELL_VERILOG)  $(root_dir)/$(sim_dir)/tb/tb_top.sv -debug_access+all -full64 -diag=sdf:verbose \
	+incdir+$(root_dir)/$(syn_dir)+$(root_dir)/$(inc_dir)+$(root_dir)/$(sim_dir)+$(root_dir)/$(sim_dir)/IP+$(root_dir)/tech+$(root_dir)/$(sim_dir)/tb \
	+define+SYN+prog2$(FSDB_DEF) \
	+no_notifier \
	+prog_path=$(root_dir)/$(sim_dir)/prog/prog2 \
	-lca \
	-power_config ../script/VCS_NLP/lib.cfg \
	-upf "../script/MV/UPF/MSV.upf" \
	+nospecify | tee ../log/vcs.log




# Program 3 WDT post-synthesis simulation.
syn3: | clean $(bld_dir)
	make -C $(sim_dir)/prog/prog3/; \
	cd $(bld_dir); \
	vcs -R -sverilog +neg_tchk -negdelay -v $(STD_CELL_VERILOG)  $(root_dir)/$(sim_dir)/tb/tb_top_WDT.sv -debug_access+all -full64 -diag=sdf:verbose \
	+incdir+$(root_dir)/$(syn_dir)+$(root_dir)/$(inc_dir)+$(root_dir)/$(sim_dir)+$(root_dir)/$(sim_dir)/IP+$(root_dir)/tech+$(root_dir)/$(sim_dir)/tb \
	+define+SYN+prog3$(FSDB_DEF) \
	+no_notifier \
	+prog_path=$(root_dir)/$(sim_dir)/prog/prog3 \
	+nospecify | tee ../log/vcs.log


# Program 3 WDT post-synthesis simulation with UPF.
syn3_UPF: | clean $(bld_dir)
	make -C $(sim_dir)/prog/prog3/; \
	cd $(bld_dir); \
	vcs -R -sverilog +neg_tchk -negdelay -v $(STD_CELL_VERILOG)  $(root_dir)/$(sim_dir)/tb/tb_top_WDT.sv -debug_access+all -full64 -diag=sdf:verbose -debug_region+cell +memcbk \
	+incdir+$(root_dir)/$(syn_dir)+$(root_dir)/$(inc_dir)+$(root_dir)/$(sim_dir)+$(root_dir)/$(sim_dir)/IP+$(root_dir)/tech+$(root_dir)/$(sim_dir)/tb \
	+define+SYN+prog3$(FSDB_DEF) \
	+no_notifier \
	-lca \
	-power_config ../script/VCS_NLP/lib.cfg \
	-upf "../script/MV/UPF/MSV.upf" \
	+prog_path=$(root_dir)/$(sim_dir)/prog/prog3 \
	+nospecify \
	+delay_mode_zero | tee ../log/vcs.log

#-debug_region+cell +memcbk
#-power_config ../script/VCS_NLP/lib.cfg \
# Post-Layout simulation


# -----------------------------------------------------------------------------
# Post-layout gate-level simulation
# -----------------------------------------------------------------------------
# Run all four post-layout programs.
pr_all: pr0 pr1 pr2 pr3


# Program 0 post-layout simulation.
pr0: | clean $(bld_dir)
	make -C $(sim_dir)/prog/prog0/; \
	cd $(bld_dir); \
	vcs -R -sverilog +neg_tchk -negdelay +nospecify +notimingcheck +delay_mode_zero -v $(STD_CELL_VERILOG)  $(root_dir)/$(sim_dir)/tb/tb_top.sv -debug_access+all -full64 -diag=sdf:verbose \
	+incdir+$(root_dir)/$(pr_dir)+$(root_dir)/$(inc_dir)+$(root_dir)/$(sim_dir)+$(root_dir)/$(sim_dir)/IP+$(root_dir)/tech+$(root_dir)/$(sim_dir)/tb \
	+define+PR+prog0$(FSDB_DEF) \
	+no_notifier \
	+maxdelays \
	+prog_path=$(root_dir)/$(sim_dir)/prog/prog0 \


# Program 1 post-layout simulation.
pr1: | clean $(bld_dir)
	make -C $(sim_dir)/prog/prog1/; \
	cd $(bld_dir); \
	vcs -R -sverilog +neg_tchk -negdelay +nospecify +notimingcheck +delay_mode_zero -v $(STD_CELL_VERILOG)  $(root_dir)/$(sim_dir)/tb/tb_top.sv -debug_access+all -full64 -diag=sdf:verbose \
	+incdir+$(root_dir)/$(pr_dir)+$(root_dir)/$(inc_dir)+$(root_dir)/$(sim_dir)+$(root_dir)/$(sim_dir)/IP+$(root_dir)/tech+$(root_dir)/$(sim_dir)/tb \
	+define+PR+prog1$(FSDB_DEF) \
	+no_notifier \
	+maxdelays \
	+prog_path=$(root_dir)/$(sim_dir)/prog/prog1 \


# Program 2 post-layout simulation.
pr2: | clean $(bld_dir)
	make -C $(sim_dir)/prog/prog2/; \
	cd $(bld_dir); \
	vcs -R -sverilog +neg_tchk -negdelay +nospecify +notimingcheck +delay_mode_zero -v $(STD_CELL_VERILOG)  $(root_dir)/$(sim_dir)/tb/tb_top.sv -debug_access+all -full64 -diag=sdf:verbose \
	+incdir+$(root_dir)/$(pr_dir)+$(root_dir)/$(inc_dir)+$(root_dir)/$(sim_dir)+$(root_dir)/$(sim_dir)/IP+$(root_dir)/tech+$(root_dir)/$(sim_dir)/tb \
	+define+PR+prog2$(FSDB_DEF) \
	+no_notifier \
	+maxdelays \
	+prog_path=$(root_dir)/$(sim_dir)/prog/prog2 \


# Program 3 WDT post-layout simulation.
pr3: | clean $(bld_dir)
	make -C $(sim_dir)/prog/prog3/; \
	cd $(bld_dir); \
	vcs -R -sverilog +neg_tchk -negdelay +nospecify +notimingcheck +delay_mode_zero -v $(STD_CELL_VERILOG)  $(root_dir)/$(sim_dir)/tb/tb_top_WDT.sv -debug_access+all -full64 -diag=sdf:verbose \
	+incdir+$(root_dir)/$(pr_dir)+$(root_dir)/$(inc_dir)+$(root_dir)/$(sim_dir)+$(root_dir)/$(sim_dir)/IP+$(root_dir)/tech+$(root_dir)/$(sim_dir)/tb \
	+define+PR+prog3$(FSDB_DEF) \
	+no_notifier \
	+maxdelays \
	+prog_path=$(root_dir)/$(sim_dir)/prog/prog3 \


# Utilities

# -----------------------------------------------------------------------------
# Waveform viewers and lint utilities
# -----------------------------------------------------------------------------
# Open the generated FSDB waveform in nWave.
nWave: | $(bld_dir)
	cd $(bld_dir); \
	nWave chip.fsdb &


# Open the generated FSDB waveform in Verdi.
verdi: | $(bld_dir)
	cd $(bld_dir); \
	verdi -ssf top.fsdb &


# Launch JasperGold Superlint.
superlint: | $(bld_dir)
	cd $(bld_dir); \
	jg -superlint ../script/formal/superlint.tcl &


# -----------------------------------------------------------------------------
# Synthesis and physical implementation
# -----------------------------------------------------------------------------
# Launch Design Compiler in GUI mode.
dv: | $(bld_dir) $(syn_dir)
	cp script/DC/standalone/synopsys_dc.setup $(bld_dir)/.synopsys_dc.setup; \
	cd $(bld_dir); \
	dc_shell -gui -no_home_init &


# Run the standard Design Compiler synthesis flow.
synthesize: | $(bld_dir) $(syn_dir)
	cp script/DC/synopsys_dc.setup $(bld_dir)/.synopsys_dc.setup; \
	cd $(bld_dir); \
	sed -i '1i set PT_option 0' .synopsys_dc.setup; \
	sed -i '2i set topo_option 0' .synopsys_dc.setup; \
	dc_shell -no_home_init -f ../script/DC/synthesis.tcl | tee ../log/syn_compile.log


# Run the topographical MMMC synthesis flow.
synthesize_mmmc: | $(bld_dir) $(syn_dir)
	cp script/MV/DVFS/synopsys_dc.setup $(bld_dir)/.synopsys_dc.setup; \
	cd $(bld_dir); \
	sed -i '1i set PT_option 0' .synopsys_dc.setup; \
	sed -i '2i set topo_option 1' .synopsys_dc.setup; \
	dcnxt_shell -topo -no_home_init -f ../script/DC/synthesis.tcl | tee ../log/syn_compile.log



# innovus
# Select APR process with PROCESS=<flow-directory-name>.
# Existing setup/run/init.setup files are preserved and are not overwritten.
.PHONY: pr_build
# Reproduce the source-defined Runtime without launching an EDA tool.
pr_build: | $(bld_pr_dir)
	@if [ "$(PROCESS)" = "TECH_MV" ]; then \
		sh "$(root_dir)/tools/sh/build_tech_runtime.sh" "$(PR_FLOW_DIR)" "$(abspath $(bld_pr_dir))" all; \
	else \
		test -d "$(PR_SETUP_SRC)" && test -d "$(PR_RUN_SRC)" && test -f "$(PR_INIT_SETUP_SRC)" || exit 1; \
		if [ ! -d "$(bld_pr_dir)/setup" ]; then cp -pR "$(PR_SETUP_SRC)" "$(bld_pr_dir)/setup" || exit $$?; fi; \
		if [ ! -d "$(bld_pr_dir)/run" ]; then cp -pR "$(PR_RUN_SRC)" "$(bld_pr_dir)/run" || exit $$?; fi; \
		if [ ! -f "$(bld_pr_dir)/init.setup" ]; then cp -p "$(PR_INIT_SETUP_SRC)" "$(bld_pr_dir)/init.setup" || exit $$?; fi; \
	fi

innovus: pr_build | $(bld_pr_dir) $(syn_dir)
	@test -d "$(PR_SETUP_SRC)" || { \
		echo "ERROR: Process setup directory not found: $(PR_SETUP_SRC)"; \
		exit 1; \
	}
	@test -d "$(PR_RUN_SRC)" || { \
		echo "ERROR: Process run directory not found: $(PR_RUN_SRC)"; \
		exit 1; \
	}
	@test -f "$(PR_INIT_SETUP_SRC)" || { \
		echo "ERROR: Process init.setup not found: $(PR_INIT_SETUP_SRC)"; \
		exit 1; \
	}
	@test -f "$(INNOVUS_STARTUP)" || { \
		echo "ERROR: Innovus startup script not found: $(INNOVUS_STARTUP)"; \
		exit 1; \
	}
	cd $(bld_pr_dir); \
	echo "[INNOVUS PRE-CLEAN] Cleaning .trash (best effort) ..."; \
	if [ -L .trash ]; then \
		echo "WARNING: build_PR/.trash is a symlink; not cleaning it. Continuing."; \
	elif [ -d .trash ]; then \
		rm -rf -- .trash/* .trash/.[!.]* .trash/..?* 2>/dev/null || \
			echo "WARNING: build_PR/.trash cleanup failed; continuing."; \
	fi; \
	if [ -e .cadence/innovus ] || [ -L .cadence/innovus ]; then \
		echo "[INNOVUS PRE-CLEAN] Removing .cadence/innovus ..."; \
		rm -rf -- .cadence/innovus 2>/dev/null || true; \
		if [ -e .cadence/innovus ] || [ -L .cadence/innovus ]; then \
			echo "WARNING: Cannot delete .cadence/innovus; moving it to .trash."; \
			if [ -L .trash ]; then \
				echo "ERROR: build_PR/.trash is a symlink; refusing to move stale Innovus state outside the project."; \
				exit 1; \
			fi; \
			mkdir -p .trash 2>/dev/null || { \
				echo "ERROR: Cannot create build_PR/.trash."; \
				exit 1; \
			}; \
			trash_name=".trash/innovus_$$(date +%Y%m%d_%H%M%S)_$$$$"; \
			mv -- .cadence/innovus "$$trash_name" 2>/dev/null || { \
				echo "ERROR: Cannot delete or move build_PR/.cadence/innovus."; \
				exit 1; \
			}; \
			echo "[INNOVUS PRE-CLEAN] Moved stale Innovus state to $$trash_name"; \
		else \
			echo "[INNOVUS PRE-CLEAN] Removed .cadence/innovus."; \
		fi; \
	else \
		echo "[INNOVUS PRE-CLEAN] No .cadence/innovus found."; \
	fi; \
	mkdir -p PR_log PR_cmd; \
	if [ -f .innovus_process ] && [ "$$(cat .innovus_process)" != "$(PROCESS)" ]; then \
		echo "ERROR: build_PR currently contains process '$$(cat .innovus_process)', not '$(PROCESS)'."; \
		echo "Run 'make reset_innovus_flow' before switching process."; \
		exit 1; \
	fi; \
	printf '%s\n' "$(PROCESS)" > .innovus_process; \
	if [ "$(PROCESS)" = "TECH_MV" ]; then \
		mkdir -p .temp/00_common/eda_tmp; \
		export TMPDIR="$$(pwd)/.temp/00_common/eda_tmp"; \
	fi; \
	innovus -stylus -cpus $(INNOVUS_CPUS) \
		-files "$(INNOVUS_STARTUP)" \
		-log "PR_log/$(TOP_MODULE).log PR_cmd/$(TOP_MODULE).cmd PR_log/$(TOP_MODULE).logv"; \
	TECH_INNOVUS_RC=$$?; \
	if [ "$(PROCESS)" = "TECH_MV" ]; then \
		python3 "$(root_dir)/tools/organize_pr_outputs.py" --root "$$(pwd)" --apply --after-innovus || \
			echo "WARNING: output organization incomplete; run make organize_pr_outputs_preview"; \
	fi; \
	exit $$TECH_INNOVUS_RC


# Clean generated Innovus data while preserving the copied runtime environment.
# Preserved:
#   build_PR/setup/
#   build_PR/run/
#   build_PR/init.setup
#   build_PR/.innovus_process
#
# Everything else under build_PR is treated as generated/runtime data.
clean_innovus:
	@if [ -d "$(bld_pr_dir)" ]; then \
		echo "Cleaning Innovus runtime data under $(bld_pr_dir) ..."; \
		find "$(bld_pr_dir)" -mindepth 1 -maxdepth 1 \
			! -name setup \
			! -name run \
			! -name init.setup \
			! -name .innovus_process \
			-exec rm -rf {} +; \
		echo "Preserved Innovus environment:"; \
		echo "  $(bld_pr_dir)/setup"; \
		echo "  $(bld_pr_dir)/run"; \
		echo "  $(bld_pr_dir)/init.setup"; \
		echo "  $(bld_pr_dir)/.innovus_process"; \
	fi

# Fully remove the copied Innovus process environment.
# Use this only when switching PROCESS or when a completely fresh copy is needed.
reset_innovus_flow:
	rm -rf $(bld_pr_dir)/setup \
	       $(bld_pr_dir)/run \
	       $(bld_pr_dir)/init.setup \
	       $(bld_pr_dir)/.innovus_process
	@$(MAKE) clean_innovus

# Backward-compatible name for a full process reset.
clean_innovus_flow: reset_innovus_flow
























# >>> TECH_MV_FULL_INSTALLER:VERIFY_TARGETS >>>
# -----------------------------------------------------------------------------
# Physical verification
# -----------------------------------------------------------------------------
# The project already owns "check" for submission validation, so all physical
# verification entry points use a verify_ prefix.
.PHONY: \
	verify verify_guard verify_build \
	verify_check verify_hcell verify_source_inc verify_v2lvs verify_lvs \
	verify_dummy verify_drc verify_antenna verify_status verify_signoff \
	verify_clean verify_reset_flow clean_innovus_keep_results clean_pr_keep_results

verify_guard:
	@test -d "$(VERIFY_FLOW_SRC)" || { \
		echo "ERROR: Verify source directory not found: $(VERIFY_FLOW_SRC)"; \
		exit 1; \
	}
	@if [ -f "$(bld_pr_dir)/.innovus_process" ]; then \
		ACTIVE_PROCESS="$$(cat "$(bld_pr_dir)/.innovus_process")"; \
		if [ "$$ACTIVE_PROCESS" != "$(VERIFY_PROCESS)" ]; then \
			echo "ERROR: build_PR contains APR process '$$ACTIVE_PROCESS', but VERIFY_PROCESS='$(VERIFY_PROCESS)'."; \
			echo "Run 'make reset_innovus_flow' and rerun Innovus with PROCESS=$(VERIFY_PROCESS)."; \
			exit 1; \
		fi; \
	else \
		echo "WARN: $(bld_pr_dir)/.innovus_process does not exist."; \
	fi
	@echo "VERIFY_PROCESS    = $(VERIFY_PROCESS)"
	@echo "VERIFY_FLOW_SRC   = $(VERIFY_FLOW_SRC)"
	@echo "VERIFY_BUILD_DIR  = $(VERIFY_BUILD_DIR)"
	@echo "VERIFY_OUTPUT_DIR = $(VERIFY_OUTPUT_DIR)"
	@echo "VERIFY_TOP        = $(VERIFY_TOP)"

# Create the copied Verify runtime only when it does not exist, mirroring the
# existing Innovus setup/run/init.setup copy policy.
verify_build: verify_guard | $(bld_pr_dir)
	@if [ -f "$(bld_pr_dir)/.verify_process" ] && \
	    [ "$$(cat "$(bld_pr_dir)/.verify_process")" != "$(VERIFY_PROCESS)" ]; then \
		echo "ERROR: build_PR Verify runtime belongs to '$$(cat "$(bld_pr_dir)/.verify_process")', not '$(VERIFY_PROCESS)'."; \
		echo "Run 'make verify_reset_flow' before switching Verify process."; \
		exit 1; \
	fi
	@if [ "$(VERIFY_PROCESS)" = "TECH_MV" ] && [ "$(abspath $(VERIFY_BUILD_DIR))" = "$(abspath $(bld_pr_dir))/verify" ]; then \
		sh "$(root_dir)/tools/sh/build_tech_runtime.sh" "$(VERIFY_PROCESS_DIR)" "$(abspath $(bld_pr_dir))" verify || exit $$?; \
	elif [ ! -d "$(VERIFY_BUILD_DIR)" ]; then \
		echo "Creating Verify runtime: $(VERIFY_BUILD_DIR)"; \
		if [ -f "$(VERIFY_FLOW_SRC)/common/bootstrap.py" ]; then \
			python3 "$(VERIFY_FLOW_SRC)/common/bootstrap.py" "$(VERIFY_BUILD_DIR)" || exit $$?; \
		else \
			cp -r "$(VERIFY_FLOW_SRC)" "$(VERIFY_BUILD_DIR)" || exit $$?; \
		fi; \
	fi
	@printf '%s\n' "$(VERIFY_PROCESS)" > "$(bld_pr_dir)/.verify_process"



verify_check: verify_build
	@VERIFY_OUTPUT_DIR="$(abspath $(VERIFY_OUTPUT_DIR))" VERIFY_TOP="$(VERIFY_TOP)" \
	 VERIFY_PROJECT_ROOT="$(root_dir)" VERIFY_FLOW_SOURCE_DIR="$(VERIFY_PROCESS_DIR)" \
	 $(MAKE) -C "$(VERIFY_BUILD_DIR)" verify_check

verify_hcell: verify_build
	@VERIFY_OUTPUT_DIR="$(abspath $(VERIFY_OUTPUT_DIR))" VERIFY_TOP="$(VERIFY_TOP)" \
	 VERIFY_PROJECT_ROOT="$(root_dir)" VERIFY_FLOW_SOURCE_DIR="$(VERIFY_PROCESS_DIR)" \
	 $(MAKE) -C "$(VERIFY_BUILD_DIR)" verify_hcell

verify_source_inc: verify_build
	@VERIFY_OUTPUT_DIR="$(abspath $(VERIFY_OUTPUT_DIR))" VERIFY_TOP="$(VERIFY_TOP)" \
	 VERIFY_PROJECT_ROOT="$(root_dir)" VERIFY_FLOW_SOURCE_DIR="$(VERIFY_PROCESS_DIR)" \
	 $(MAKE) -C "$(VERIFY_BUILD_DIR)" verify_source_inc

verify_v2lvs: verify_build
	@VERIFY_OUTPUT_DIR="$(abspath $(VERIFY_OUTPUT_DIR))" VERIFY_TOP="$(VERIFY_TOP)" \
	 VERIFY_PROJECT_ROOT="$(root_dir)" VERIFY_FLOW_SOURCE_DIR="$(VERIFY_PROCESS_DIR)" \
	 $(MAKE) -C "$(VERIFY_BUILD_DIR)" verify_v2lvs

verify_lvs: verify_build
	@VERIFY_OUTPUT_DIR="$(abspath $(VERIFY_OUTPUT_DIR))" VERIFY_TOP="$(VERIFY_TOP)" \
	 VERIFY_PROJECT_ROOT="$(root_dir)" VERIFY_FLOW_SOURCE_DIR="$(VERIFY_PROCESS_DIR)" \
	 $(MAKE) -C "$(VERIFY_BUILD_DIR)" verify_lvs

verify_dummy: verify_build
	@VERIFY_OUTPUT_DIR="$(abspath $(VERIFY_OUTPUT_DIR))" VERIFY_TOP="$(VERIFY_TOP)" \
	 VERIFY_PROJECT_ROOT="$(root_dir)" VERIFY_FLOW_SOURCE_DIR="$(VERIFY_PROCESS_DIR)" \
	 $(MAKE) -C "$(VERIFY_BUILD_DIR)" verify_dummy

verify_drc: verify_build
	@VERIFY_OUTPUT_DIR="$(abspath $(VERIFY_OUTPUT_DIR))" VERIFY_TOP="$(VERIFY_TOP)" \
	 VERIFY_PROJECT_ROOT="$(root_dir)" VERIFY_FLOW_SOURCE_DIR="$(VERIFY_PROCESS_DIR)" \
	 $(MAKE) -C "$(VERIFY_BUILD_DIR)" verify_drc

verify_antenna: verify_build
	@VERIFY_OUTPUT_DIR="$(abspath $(VERIFY_OUTPUT_DIR))" VERIFY_TOP="$(VERIFY_TOP)" \
	 VERIFY_PROJECT_ROOT="$(root_dir)" VERIFY_FLOW_SOURCE_DIR="$(VERIFY_PROCESS_DIR)" \
	 $(MAKE) -C "$(VERIFY_BUILD_DIR)" verify_antenna

verify_status: verify_build
	@VERIFY_OUTPUT_DIR="$(abspath $(VERIFY_OUTPUT_DIR))" VERIFY_TOP="$(VERIFY_TOP)" \
	 VERIFY_PROJECT_ROOT="$(root_dir)" VERIFY_FLOW_SOURCE_DIR="$(VERIFY_PROCESS_DIR)" \
	 $(MAKE) -C "$(VERIFY_BUILD_DIR)" verify_status

verify_signoff: verify_build
	@VERIFY_OUTPUT_DIR="$(abspath $(VERIFY_OUTPUT_DIR))" VERIFY_TOP="$(VERIFY_TOP)" \
	 VERIFY_PROJECT_ROOT="$(root_dir)" VERIFY_FLOW_SOURCE_DIR="$(VERIFY_PROCESS_DIR)" \
	 $(MAKE) -C "$(VERIFY_BUILD_DIR)" verify_signoff

verify: verify_signoff

# Remove generated LVS/Dummy/DRC/Antenna results but keep build_PR/verify scripts.
verify_clean:
	@if [ -d "$(VERIFY_BUILD_DIR)" ]; then \
		echo "Cleaning generated Verify results under $(VERIFY_BUILD_DIR) ..."; \
		$(MAKE) -C "$(VERIFY_BUILD_DIR)" verify_clean; \
	else \
		echo "Verify runtime does not exist: $(VERIFY_BUILD_DIR)"; \
	fi

# Remove the complete copied Verify runtime. Master source is untouched.
verify_reset_flow:
	rm -rf "$(VERIFY_BUILD_DIR)" "$(bld_pr_dir)/.verify_process"

# Clean build_PR generated/runtime data but preserve the APR deliverables and
# copied Innovus environment.
# Preserved: setup, run, init.setup, .innovus_process, outputs, dbs
clean_innovus_keep_results:
	@if [ -d "$(bld_pr_dir)" ]; then \
		echo "Cleaning build_PR while preserving outputs and dbs ..."; \
		find "$(bld_pr_dir)" -mindepth 1 -maxdepth 1 \
			! -name setup \
			! -name run \
			! -name init.setup \
			! -name .innovus_process \
			! -name outputs \
			! -name dbs \
			-exec rm -rf {} +; \
		echo "Preserved:"; \
		echo "  $(bld_pr_dir)/setup"; \
		echo "  $(bld_pr_dir)/run"; \
		echo "  $(bld_pr_dir)/init.setup"; \
		echo "  $(bld_pr_dir)/.innovus_process"; \
		echo "  $(bld_pr_dir)/outputs"; \
		echo "  $(bld_pr_dir)/dbs"; \
	fi

clean_pr_keep_results: clean_innovus_keep_results
# <<< TECH_MV_FULL_INSTALLER:VERIFY_TARGETS <<<

# Run the ICC2 implementation script.
icc2: | $(pr_dir)
	make clean_pr; \
	cd $(pr_dir); \
	icc2_shell -file ../scripts/00_run.tcl


# Launch ICC2 in GUI mode.
icc2_gui: | $(pr_dir)
	cd $(pr_dir); \
	icc2_shell -gui;

#spyglass

# -----------------------------------------------------------------------------
# SpyGlass CDC, RDC, constraint, library, and power flows
# -----------------------------------------------------------------------------
# Run SpyGlass CDC analysis.
spyCDC: | $(bld_dir)
	cd $(bld_dir); \
	spyglass -tcl ../script/spyglass/system/Spyglass_CDC.tcl &


# Run SpyGlass RDC analysis.
spyRDC: | $(bld_dir)
	cd $(bld_dir); \
	spyglass -tcl ../script/spyglass/system/Spyglass_RDC.tcl &


# Run VC SpyGlass structural RDC verification.
spyvcRDC: | $(bld_dir)
	cd $(bld_dir) && \
	VC_STATIC_HOME=/FILL_IN/FILL_IN_RESOURCE_0009 \
	/FILL_IN/FILL_IN_RESOURCE_0010 \
	-project ../script/spyglass/system/Spyglass_RDC.tcl \
	-goal rdc/rdc_verify_struct &

# Convert SDC constraints into SGDC format.
sdc2sgdc: | $(bld_dir)
	cd $(bld_dir); \
	spyglass -project ../script/spyglass/SDC2SGDC/sdc2sgdc.prj -designread $(opt)

	
#spyglass -batch -project ../script/spyglass/SDC2SGDC/sdc2sgdc.prj -designread


spyFIFO-CDC: | $(bld_dir)
	cd $(bld_dir); \
	spyglass -tcl ../script/spyglass/FIFO/Spyglass_CDC.tcl &

spyFIFO-RDC: | $(bld_dir)
	cd $(bld_dir); \
	spyglass -tcl ../script/spyglass/FIFO/Spyglass_RDC.tcl &

# Convert Liberty files listed in LIB_F into a SpyGlass library.
lib2sglib: | $(bld_dir)
	@mkdir -p "$(dir $(OUT_SGLIB))"
	@cd "$(bld_dir)"; \
	LIB_LIST="$$( \
		grep -v '^[[:space:]]*#' "$(LIB_F)" | \
		grep '\.lib' | \
		sed 's/\r$$//' | \
		sed 's/[[:space:]]*\\[[:space:]]*$$//' | \
		tr '\n' ' ' \
	)"; \
	spyglass_lc \
		-gateslib "$$LIB_LIST" \
		-include_opt_data \
		-outsglib "$(OUT_SGLIB)"
	

# Run SpyGlass power analysis.
spyPWR: | $(bld_dir)
	cd $(bld_dir); \
	spyglass -tcl ../script/spyglass/system/Spyglass_Power.tcl &


# -----------------------------------------------------------------------------
# PrimeTime PX power analysis
# -----------------------------------------------------------------------------
ptpx: | $(bld_dir) $(syn_dir)
	cp script/DC/synopsys_dc.setup $(bld_dir)/.synopsys_pt.setup; \
	cp ./script/DC/DC.sdc $(bld_dir)/ptpx.sdc; \
	cd $(bld_dir); \
	sed -i '1i set PT_option 1' .synopsys_pt.setup; \
	pt_shell -f ../script/PT/pt.tcl | tee ../log/pt.log

# Check file structure

# -----------------------------------------------------------------------------
# Submission validation and packaging
# -----------------------------------------------------------------------------
# Terminal colors used by the validation messages.
BLUE=\033[1;34m
RED=\033[1;31m
NORMAL=\033[0m


# Validate student IDs, report naming, and project-directory naming.
check: clean
	@if [ -f StudentID ]; then \
		STUDENTID=$$(grep -v '^$$' StudentID); \
		if [ -z "$$STUDENTID" ]; then \
			echo -e "$(RED)Student ID number is not provided$(NORMAL)"; \
			exit 1; \
		else \
			ID_LEN=$$(expr length $$STUDENTID); \
			if [ $$ID_LEN -eq 9 ]; then \
				if [[ $$STUDENTID =~ ^[A-Z][A-Z0-9][0-9]+$$ ]]; then \
					echo -e "$(BLUE)Student ID number pass$(NORMAL)"; \
				else \
					echo -e "$(RED)Student ID number should be one capital letter and 8 numbers (or 2 capital letters and 7 numbers)$(NORMAL)"; \
					exit 1; \
				fi \
			else \
				echo -e "$(RED)Student ID number length isn't 9$(NORMAL)"; \
				exit 1; \
			fi \
		fi \
	else \
		echo -e "$(RED)StudentID file is not found$(NORMAL)"; \
		exit 1; \
	fi; \
	if [ -f StudentID2 ]; then \
		STUDENTID2=$$(grep -v '^$$' StudentID2); \
		if [ -z "$$STUDENTID2" ]; then \
			echo -e "$(RED)Second student ID number is not provided$(NORMAL)"; \
			exit 1; \
		else \
			ID2_LEN=$$(expr length $$STUDENTID2); \
			if [ $$ID2_LEN -eq 9 ]; then \
				if [[ $$STUDENTID2 =~ ^[A-Z][A-Z0-9][0-9]+$$ ]]; then \
					echo -e "$(BLUE)Second student ID number pass$(NORMAL)"; \
				else \
					echo -e "$(RED)Second student ID number should be one capital letter and 8 numbers (or 2 capital letters and 7 numbers)$(NORMAL)"; \
					exit 1; \
				fi \
			else \
				echo -e "$(RED)Second student ID number length isn't 9$(NORMAL)"; \
				exit 1; \
			fi \
		fi \
	fi; \
	if [ $$(ls -1 *.docx 2>/dev/null | wc -l) -eq 0 ]; then \
		echo -e "$(RED)Report file is not found$(NORMAL)"; \
		exit 1; \
	elif [ $$(ls -1 *.docx 2>/dev/null | wc -l) -gt 1 ]; then \
		echo -e "$(RED)More than one docx file is found, please delete redundant file(s)$(NORMAL)"; \
		exit 1; \
	elif [ ! -f $${STUDENTID}.docx ]; then \
		echo -e "$(RED)Report file name should be $$STUDENTID.docx$(NORMAL)"; \
		exit 1; \
	else \
		echo -e "$(BLUE)Report file name pass$(NORMAL)"; \
	fi; \
	if [ $$(basename $(PWD)) != $$STUDENTID ]; then \
		echo -e "$(RED)Main folder name should be \"$$STUDENTID\"$(NORMAL)"; \
		exit 1; \
	else \
		echo -e "$(BLUE)Main folder name pass$(NORMAL)"; \
	fi


# Package the validated project directory.
tar: check
	STUDENTID=$$(basename $(PWD)); \
	cd ..; \
	tar cvf $$STUDENTID.tar $$STUDENTID


# -----------------------------------------------------------------------------
# Cleanup targets
# -----------------------------------------------------------------------------
.PHONY: clean clean_innovus reset_innovus_flow clean_innovus_flow dramsys_lib check_dramsys rtl_dramsys rtl0_dramsys rtl1_dramsys rtl2_dramsys



# Reserved physical-design cleanup target.
clean_pr:
# 	rm -rf ./pr/icc2_REFERENCE_PLATFORM_provider/run; \
# 	mkdir ./pr/icc2_REFERENCE_PLATFORM_provider/run;
# 	rm -rf ./APR_new/innovus_stylus/APR/dbs; \
# 	mkdir ./APR_new/innovus_stylus/APR/dbs;
	

# Remove generated simulation files and clean all program directories.
clean: clean_temp
	rm -rf $(bld_dir); \
	rm -rf $(sim_dir)/prog/prog*/result*.txt; \
	make -C $(sim_dir)/prog/prog0/ clean; \
	make -C $(sim_dir)/prog/prog1/ clean; \
	make -C $(sim_dir)/prog/prog2/ clean; \
	make -C $(sim_dir)/prog/prog3/ clean; \




# Remove only disposable Verify deck/runset copies; preserve results and history.
.PHONY: verify_clean_sensitive verify_clean_sensitive_preview
verify_clean_sensitive:
	@if [ -d "$(VERIFY_BUILD_DIR)" ]; then $(MAKE) -C "$(VERIFY_BUILD_DIR)" verify_clean_sensitive; fi
verify_clean_sensitive_preview:
	@if [ -d "$(VERIFY_BUILD_DIR)" ]; then $(MAKE) -C "$(VERIFY_BUILD_DIR)" verify_clean_sensitive_preview; fi

# Explicit root debug exports only; never traverse PDK, backups or libraries.
.PHONY: clean_root_debug clean_root_debug_preview
clean_root_debug:
	@python3 temp_doc/clean_root_debug.py --apply
clean_root_debug_preview:
	@python3 temp_doc/clean_root_debug.py

.PHONY: organize_pr_outputs organize_pr_outputs_preview
organize_pr_outputs:
	@python3 tools/organize_pr_outputs.py --apply
organize_pr_outputs_preview:
	@python3 tools/organize_pr_outputs.py

.PHONY: verify_clean_output verify_clean_output_preview install_private_config
verify_clean_output:
	@if [ -d "$(VERIFY_BUILD_DIR)" ]; then $(MAKE) -C "$(VERIFY_BUILD_DIR)" verify_clean_output; fi
verify_clean_output_preview:
	@if [ -d "$(VERIFY_BUILD_DIR)" ]; then $(MAKE) -C "$(VERIFY_BUILD_DIR)" verify_clean_output_preview; fi

# Local configuration is generated at installation, never copied from formal sources.
TECH_PRIVATE_CONFIG_SEED ?= $(root_dir)/.private_config/TECH_MV/geometry_values.tcl
install_private_config:
	@python3 "$(root_dir)/tools/install_private_config.py" --runtime "$(bld_pr_dir)" --seed "$(TECH_PRIVATE_CONFIG_SEED)"

# Compatibility with existing automation.
clean_verify: verify_clean
reset_verify_flow: verify_reset_flow
clean_verify_sensitive: verify_clean_sensitive
clean_verify_sensitive_preview: verify_clean_sensitive_preview

.PHONY: verify_help
verify_help: verify_build
	@VERIFY_OUTPUT_DIR="$(abspath $(bld_pr_dir))/outputs" VERIFY_TOP="$(TOP_MODULE)" VERIFY_PROJECT_ROOT="$(abspath .)" VERIFY_FLOW_SOURCE_DIR="$(abspath $(VERIFY_PROCESS_DIR))" $(MAKE) -C "$(VERIFY_BUILD_DIR)" verify_help

.PHONY: verify_pack
verify_pack: verify_build
	@VERIFY_OUTPUT_DIR="$(abspath $(bld_pr_dir))/outputs" VERIFY_TOP="$(TOP_MODULE)" VERIFY_PROJECT_ROOT="$(abspath .)" VERIFY_FLOW_SOURCE_DIR="$(abspath $(VERIFY_PROCESS_DIR))" $(MAKE) -C "$(VERIFY_BUILD_DIR)" verify_pack

.PHONY: verify_lvs_hcell
verify_lvs_hcell: verify_build
	@VERIFY_OUTPUT_DIR="$(abspath $(bld_pr_dir))/outputs" VERIFY_TOP="$(TOP_MODULE)" VERIFY_PROJECT_ROOT="$(abspath .)" VERIFY_FLOW_SOURCE_DIR="$(abspath $(VERIFY_PROCESS_DIR))" $(MAKE) -C "$(VERIFY_BUILD_DIR)" verify_lvs_hcell

.PHONY: verify_lvs_nohcell
verify_lvs_nohcell: verify_build
	@VERIFY_OUTPUT_DIR="$(abspath $(bld_pr_dir))/outputs" VERIFY_TOP="$(TOP_MODULE)" VERIFY_PROJECT_ROOT="$(abspath .)" VERIFY_FLOW_SOURCE_DIR="$(abspath $(VERIFY_PROCESS_DIR))" $(MAKE) -C "$(VERIFY_BUILD_DIR)" verify_lvs_nohcell

.PHONY: verify_lvs_debug_nobody
verify_lvs_debug_nobody: verify_build
	@VERIFY_OUTPUT_DIR="$(abspath $(bld_pr_dir))/outputs" VERIFY_TOP="$(TOP_MODULE)" VERIFY_PROJECT_ROOT="$(abspath .)" VERIFY_FLOW_SOURCE_DIR="$(abspath $(VERIFY_PROCESS_DIR))" $(MAKE) -C "$(VERIFY_BUILD_DIR)" verify_lvs_debug_nobody

.PHONY: verify_dummy_fe
verify_dummy_fe: verify_build
	@VERIFY_OUTPUT_DIR="$(abspath $(bld_pr_dir))/outputs" VERIFY_TOP="$(TOP_MODULE)" VERIFY_PROJECT_ROOT="$(abspath .)" VERIFY_FLOW_SOURCE_DIR="$(abspath $(VERIFY_PROCESS_DIR))" $(MAKE) -C "$(VERIFY_BUILD_DIR)" verify_dummy_fe

.PHONY: verify_dummy_be
verify_dummy_be: verify_build
	@VERIFY_OUTPUT_DIR="$(abspath $(bld_pr_dir))/outputs" VERIFY_TOP="$(TOP_MODULE)" VERIFY_PROJECT_ROOT="$(abspath .)" VERIFY_FLOW_SOURCE_DIR="$(abspath $(VERIFY_PROCESS_DIR))" $(MAKE) -C "$(VERIFY_BUILD_DIR)" verify_dummy_be

.PHONY: verify_dummy_cod
verify_dummy_cod: verify_build
	@VERIFY_OUTPUT_DIR="$(abspath $(bld_pr_dir))/outputs" VERIFY_TOP="$(TOP_MODULE)" VERIFY_PROJECT_ROOT="$(abspath .)" VERIFY_FLOW_SOURCE_DIR="$(abspath $(VERIFY_PROCESS_DIR))" $(MAKE) -C "$(VERIFY_BUILD_DIR)" verify_dummy_cod

.PHONY: verify_dummy_merge
verify_dummy_merge: verify_build
	@VERIFY_OUTPUT_DIR="$(abspath $(bld_pr_dir))/outputs" VERIFY_TOP="$(TOP_MODULE)" VERIFY_PROJECT_ROOT="$(abspath .)" VERIFY_FLOW_SOURCE_DIR="$(abspath $(VERIFY_PROCESS_DIR))" $(MAKE) -C "$(VERIFY_BUILD_DIR)" verify_dummy_merge

.PHONY: verify_clean_lvs
verify_clean_lvs:
	@if [ -d "$(VERIFY_BUILD_DIR)" ]; then $(MAKE) -C "$(VERIFY_BUILD_DIR)" verify_clean_lvs; fi

.PHONY: verify_clean_dummy
verify_clean_dummy:
	@if [ -d "$(VERIFY_BUILD_DIR)" ]; then $(MAKE) -C "$(VERIFY_BUILD_DIR)" verify_clean_dummy; fi

.PHONY: verify_clean_drc
verify_clean_drc:
	@if [ -d "$(VERIFY_BUILD_DIR)" ]; then $(MAKE) -C "$(VERIFY_BUILD_DIR)" verify_clean_drc; fi

.PHONY: verify_clean_generated
verify_clean_generated:
	@if [ -d "$(VERIFY_BUILD_DIR)" ]; then $(MAKE) -C "$(VERIFY_BUILD_DIR)" verify_clean_generated; fi

# Disposable ioPADt runtime outputs only.
.PHONY: clean_iopad_build clean_iopad_build_preview
clean_iopad_build:
	@python3 "$(root_dir)/tools/clean_iopad_build.py" --runtime "$(bld_pr_dir)" --apply
clean_iopad_build_preview:
	@python3 "$(root_dir)/tools/clean_iopad_build.py" --runtime "$(bld_pr_dir)"

.PHONY: clean_temp clean_temp_preview
clean_temp:
	@python3 "$(root_dir)/tools/clean_runtime_temp.py" --runtime "$(bld_pr_dir)" --project "$(root_dir)" --apply
clean_temp_preview:
	@python3 "$(root_dir)/tools/clean_runtime_temp.py" --runtime "$(bld_pr_dir)" --project "$(root_dir)"
