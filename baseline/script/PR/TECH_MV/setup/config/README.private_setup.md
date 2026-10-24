# Editable Runtime setup

This setup belongs to the current design. It contains actual authorized settings and must not be published. The template under script/PR/TECH_MV is copied when Runtime setup is first created. Later edits here are retained.

## What to edit

- Inputs and design/power mapping: 00_input.config.tcl and 00_design.config.tcl.
- Floorplan choices and geometry: 01_floorplan.config.tcl.
- Powerplan, placement, CTS, routing and export: the corresponding stage config.
- Literal Library selectors and Pin identities: TECH_MV_LIBRARY_VALUES in 00_library.config.tcl. Keep list types, wildcard and regular-expression semantics unchanged.
- ioPADt rules: private/ioPADt.rules.json.
- Reviewed geometry fallback data: geometry_review.config.tcl. Existing private overrides used by legacy geometry getters retain their original priority.

Stage parameters are direct Tcl assignments. Shared tool code reads the Runtime Library array first. A missing required array key fails explicitly; it does not silently revert to a seed value. Private setup_commands.tcl remains an installation/legacy bundle. Editing that bundle does not override materialized stage assignments or the Runtime Library array.

The existing init.setup -> setup/config.tcl -> nine stage components load order remains. Helper code may be shared; parameter data is Runtime-local.

## First creation

The project-root `make pr_build` creates the Runtime environment from the explicit `script/PR/TECH_MV/runtime_sources.list`. Stage and Library settings are already readable assignments in the source defaults and are copied without evaluating or rematerializing them. Runtime Tcl entries are generated as references to the canonical implementation. Verify scripts/configuration use the same source manifest.

Existing Runtime files are retained, including local edits. Missing manifest files can be supplied without resetting existing settings. A deliberate update of source defaults must be reviewed and backed up separately; ordinary builds never propagate Runtime changes back automatically. The historical materialization marker and legacy private data remain for compatibility, but the normal Makefile creation path no longer expands seed settings.

## Check candidates after import

Stage00 loads the optional probe definitions after design_import. It does not run the new probe automatically. To use it in an imported Innovus DB:

```tcl
source -quiet [file join $TOOL_DIR 00_common TT_config_probe.tcl]
TT_config_probe geometry
TT_config_probe masters
TT_config_probe pins
```

Use all for all groups, or help for usage. Console output lists status only. Read detailed values locally in .temp/config_probe/private/probe_*.rpt. Golden is setup/config/config_probe.golden.list and must remain private and immutable.

MATCH confirms exact numeric equality or configured identity/pin presence. It does not establish safe replacement of a user setting. DIFFERENT, CONFIG_CHANGED, NOT_FOUND and UNAVAILABLE require review. Secondary/AON pin meanings and user routing choices remain explicit settings. Native Innovus query validation and full APR regression are still pending.

## Direct config locations

Reviewed geometry is `setup/config/geometry_review.config.tcl`, a readable data file, not a forwarding loader. Its authorized seed is installed into `setup/config/` only when absent; local edits are retained. The immutable comparison baseline is `setup/config/config_probe.golden.list`; moving it does not regenerate or alter the snapshot. These actual geometry/golden data remain non-public even though their paths are outside `private/`.
