# Classified APR tools

Physical subfolders group tools by their actual operation. Existing command/procedure names are kept stable. Implementations live in the canonical source tree; Runtime uses small source adapters without symlinks. The stage indexes list existing commands and retained-entry reasons. Source paths must use the classified locations below.

Future filename convention: TT_check_*, TT_report_*, TT_export_*, TT_flow_* and TT_DRC_fix_* for new tools according to operation. Existing verified commands/files are not broadly renamed just to match style. DRC tools remain flagged as technology-rule-specific; naming is not a public-release approval.

- [00_common](00_common/README.tools.md)
- [01_floorplan](01_floorplan/README.tools.md)
- [02_powerplan](02_powerplan/README.tools.md)
- [03_place](03_place/README.tools.md)
- [04_cts](04_cts/README.tools.md)
- [05_route](05_route/README.tools.md)
- [06_finish](06_finish/README.tools.md)
- [99_debug](99_debug/README.tools.md)

ioPADt remains in its existing physical directory. Its core rule config and reviewed embedded name atoms are isolated. Native/GUI runtime regression and remaining geometry/schema provenance still require review. Stage-local retained anchors are documented individually. Historical installers/backups are left unchanged and may reference the old layout; do not reinstall old payloads over this layout. Their source-hash preflight must be checked before use. The old bulk synchronization script is guarded against overwriting canonical implementations with Runtime adapters.
