# Script directory

- DC/: active synthesis flow and constraints.
- DC/standalone/: preserved alternative synthesis/setup version; not merged with active DC files.
- PT/: PrimeTime script and separate preserved standalone constraint file.
- formal/: JasperGold Superlint entry.
- MV/: UPF, multi-voltage constraints and DVFS synthesis setup.
- VCS_NLP/: low-power simulation configuration.
- spyglass/: CDC/RDC/power/library-conversion environment.
- PR/: APR/Verify flow sources and Innovus startup.
- .backup/archives/: private historical archives, retained unchanged.

Use the project-root Makefile. Tool working directories remain unchanged; source commands still resolve from their original execution directory. PrimeTime continues to consume build/ptpx.sdc copied by the Makefile from DC/DC.sdc. PT/ptpx.sdc is a separate preserved file, not a new replacement input.

Some historical entries already reference missing scripts or external resources. See the local layout report. No EDA algorithms or options were changed.
