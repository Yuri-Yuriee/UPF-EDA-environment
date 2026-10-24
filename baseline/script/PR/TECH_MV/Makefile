DBS_DIR := dbs
OUTPUT_DIR := outputs
REPORT_DIR := reports
LOG_DIR := logs
TEMP_DIR := temp
VERIFY_DIR := verify
INNOVUS_CPUS ?= 8

.PHONY: \
	pr \
	verify signoff verify_check verify_hcell verify_status \
	dummy lvs drc antenna \
	clean_pr clean_verify

pr:
	@mkdir -p $(DBS_DIR) $(OUTPUT_DIR) $(REPORT_DIR) $(LOG_DIR) $(TEMP_DIR)
	innovus -stylus -cpus $(INNOVUS_CPUS) -files script/runset.tcl

verify:
	$(MAKE) -C $(VERIFY_DIR) signoff

signoff:
	$(MAKE) -C $(VERIFY_DIR) signoff

verify_check:
	$(MAKE) -C $(VERIFY_DIR) check

verify_hcell:
	$(MAKE) -C $(VERIFY_DIR) hcell

verify_status:
	$(MAKE) -C $(VERIFY_DIR) status

dummy:
	$(MAKE) -C $(VERIFY_DIR) dummy

lvs:
	$(MAKE) -C $(VERIFY_DIR) lvs

drc:
	$(MAKE) -C $(VERIFY_DIR) drc

antenna:
	$(MAKE) -C $(VERIFY_DIR) antenna

clean_pr:
	rm -rf $(REPORT_DIR) $(LOG_DIR) $(TEMP_DIR)

clean_verify:
	$(MAKE) -C $(VERIFY_DIR) clean

# Clean this standalone flow runtime, leaving formal tool sources intact.
.PHONY: clean clean_iopad_build clean_iopad_build_preview
clean: clean_temp
clean_iopad_build:
	@python3 "$(CURDIR)/../../../tools/clean_iopad_build.py" --runtime "$(CURDIR)" --apply
clean_iopad_build_preview:
	@python3 "$(CURDIR)/../../../tools/clean_iopad_build.py" --runtime "$(CURDIR)"

.PHONY: clean_temp clean_temp_preview
clean_temp:
	@python3 "$(CURDIR)/../../../tools/clean_runtime_temp.py" --runtime "$(CURDIR)" --apply
clean_temp_preview:
	@python3 "$(CURDIR)/../../../tools/clean_runtime_temp.py" --runtime "$(CURDIR)"
