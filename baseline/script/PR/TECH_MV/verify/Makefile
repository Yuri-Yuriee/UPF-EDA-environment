SHELL := /bin/tcsh

TOP ?= CHIP
PACK_FILE ?= lvs_pack.tar.gz

.PHONY: \
	help all signoff  check status pack \
	hcell source_inc v2lvs lvs lvs_hcell lvs_nohcell lvs_debug_nobody \
	dummy dummy_fe dummy_be dummy_cod dummy_merge \
	drc antenna \
	clean clean_lvs clean_dummy clean_drc clean_generated

verify_help:
	@echo ""
	@echo "TECH_MV Verify"
	@echo "=================================================================="
	@echo "make verify_check       : check GDS/netlist/TECH decks and environment"
	@echo "make verify_hcell       : generate HCELL + LVSBOX from current TECH LEFs"
	@echo "make verify_source_inc  : generate LVS CHIP_inc.spi source include file"
	@echo "make verify_v2lvs       : convert outputs/CHIP_pg.v -> lvs/CHIP.spi"
	@echo "make verify_lvs         : LVS using VERIFY_HCELL_MODE (default: ON)"
	@echo "make verify_lvs_hcell   : force HCELL/LVSBOX mode ON"
	@echo "make verify_lvs_nohcell : force HCELL/LVSBOX mode OFF"
	@echo "make verify_lvs_debug_nobody : compare existing netlists with body connections normalized (debug only)"
	@echo "make verify_dummy       : FEOL + BEOL + COD + merge"
	@echo "make verify_drc         : DRC on dummy-merged GDS"
	@echo "make verify_antenna     : antenna check on dummy-merged GDS"
	@echo "make verify_signoff     : LVS -> Dummy -> DRC -> Antenna"
	@echo "make verify_status      : summarize available verify results"
	@echo "make verify_pack        : pack LVS scripts/configs and readable logs/reports"
	@echo "                   override archive: make verify_pack PACK_FILE=/path/lvs.tar.gz"
	@echo "make verify_clean       : remove generated verify results/deck copies"
	@echo ""
	@echo "Useful overrides:"
	@echo "  setenv VERIFY_OUTPUT_DIR /path/to/build_PR/outputs"
	@echo "  setenv TECH_LIBRARY_ROOT /path/to/library/1_PROVIDER"
	@echo "  setenv VERIFY_HCELL_MODE ON   # or OFF"
	@echo "=================================================================="
	@echo ""

verify_all: verify_signoff

verify_pack:
	@bash common/pack_lvs.sh "$(PACK_FILE)"


verify_check:
	@cd common; ./check_env.csh

verify_hcell:
	@python3 common/artifacts.py run lvs -- /bin/tcsh -c './run_hcell.csh'

verify_source_inc:
	@python3 common/artifacts.py run lvs -- /bin/tcsh -c './run_source_inc.csh'

verify_v2lvs:
	@python3 common/artifacts.py run lvs -- /bin/tcsh -c './run_v2lvs.csh'

verify_lvs:
	@python3 common/artifacts.py run lvs -- /bin/tcsh -c './run_all_lvs.csh'
	@cd common; ./status.csh lvs

verify_lvs_hcell:
	@python3 common/artifacts.py run lvs -- /bin/tcsh -c 'setenv VERIFY_HCELL_MODE ON; ./run_all_lvs.csh'
	@cd common; ./status.csh lvs

verify_lvs_nohcell:
	@python3 common/artifacts.py run lvs -- /bin/tcsh -c 'setenv VERIFY_HCELL_MODE OFF; ./run_all_lvs.csh'
	@cd common; ./status.csh lvs

verify_lvs_debug_nobody:
	@python3 common/artifacts.py run lvs -- /bin/tcsh -c 'tcsh run_debug_nobody.csh'

verify_dummy_fe:
	@python3 common/artifacts.py run add_dummy -- /bin/tcsh -c './run_FE.csh'

verify_dummy_be:
	@python3 common/artifacts.py run add_dummy -- /bin/tcsh -c './run_BE.csh'

verify_dummy_cod:
	@python3 common/artifacts.py run add_dummy -- /bin/tcsh -c './run_COD.csh'

verify_dummy_merge:
	@python3 common/artifacts.py run add_dummy -- /bin/tcsh -c './run_merge.csh'

verify_dummy:
	@python3 common/artifacts.py run add_dummy -- /bin/tcsh -c './run_all.csh'
	@cd common; ./status.csh all

verify_drc:
	@python3 common/artifacts.py run drc -- /bin/tcsh -c './run_DRC.csh'
	@cd common; ./status.csh all

verify_antenna:
	@python3 common/artifacts.py run drc -- /bin/tcsh -c './run_ANTENNA.csh'
	@cd common; ./status.csh all

verify_signoff:
	@$(MAKE) verify_check
	@$(MAKE) verify_lvs
	@$(MAKE) verify_dummy
	@$(MAKE) verify_drc
	@$(MAKE) verify_antenna
	@$(MAKE) verify_status

verify_status:
	@cd common; ./status.csh

verify_clean_lvs:
	@python3 common/artifacts.py clean lvs
	@set nonomatch; cd lvs; rm -rf log output rpt svdb *.log CHIP.spi CHIP_inc.spi HCELL LVSBOX scr/LVS_Calibre.modified scr/runset.generated.cmd

verify_clean_dummy:
	@python3 common/artifacts.py clean add_dummy
	@set nonomatch; cd add_dummy; rm -rf log output rpt .stage build/current *.gds *.gds.gz scr/Dummy_FEOL_CalibreYE scr/Dummy_BEOL_CalibreYE scr/COD_AutoGen scr/runset_*.generated.cmd

verify_clean_drc:
	@python3 common/artifacts.py clean drc
	@set nonomatch; cd drc; rm -rf log output rpt build/current *.density scr/LOGIC_TopMu_DRC scr/ANTENNA_DRC scr/runset_*.generated.cmd

verify_clean_generated: verify_clean_lvs verify_clean_dummy verify_clean_drc

verify_clean: verify_clean_generated

.PHONY: clean_sensitive clean_sensitive_preview
verify_clean_sensitive:
	@python3 common/artifacts.py clean
verify_clean_sensitive_preview:
	@python3 common/artifacts.py preview

.PHONY: verify_help verify_all verify_pack verify_check verify_hcell verify_source_inc verify_lvs verify_lvs_hcell verify_lvs_nohcell verify_lvs_debug_nobody verify_dummy_fe verify_dummy_be verify_dummy_cod verify_dummy_merge verify_dummy verify_drc verify_antenna verify_signoff verify_status verify_clean_lvs verify_clean_dummy verify_clean_drc verify_clean_generated verify_clean verify_clean_sensitive verify_clean_sensitive_preview verify_clean_output verify_clean_output_preview

verify_clean_output:
	@python3 common/clean_outputs.py

verify_clean_output_preview:
	@python3 common/clean_outputs.py --preview

# Legacy compatibility entries; use verify_* for new calls.
help: verify_help
all: verify_all
pack: verify_pack
check: verify_check
hcell: verify_hcell
source_inc: verify_source_inc
lvs: verify_lvs
lvs_hcell: verify_lvs_hcell
lvs_nohcell: verify_lvs_nohcell
lvs_debug_nobody: verify_lvs_debug_nobody
dummy_fe: verify_dummy_fe
dummy_be: verify_dummy_be
dummy_cod: verify_dummy_cod
dummy_merge: verify_dummy_merge
dummy: verify_dummy
drc: verify_drc
antenna: verify_antenna
signoff: verify_signoff
status: verify_status
clean_lvs: verify_clean_lvs
clean_dummy: verify_clean_dummy
clean_drc: verify_clean_drc
clean_generated: verify_clean_generated
clean: verify_clean
clean_sensitive: verify_clean_sensitive
clean_sensitive_preview: verify_clean_sensitive_preview

.PHONY: verify_v2lvs
v2lvs: verify_v2lvs
