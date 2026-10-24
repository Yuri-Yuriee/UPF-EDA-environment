# TECH_MV authoritative flow source

This directory is the source of new build_PR environments. The root Makefile uses `make pr_build` to create the declared Tcl entries, tools, setup and Verify environment without starting an EDA tool. `make innovus` uses that same preparation step. Existing Runtime settings are independent copies and are never overwritten by an ordinary build.

`runtime_sources.list` explicitly classifies copied environment files and generated Tcl source adapters. Shared implementations live in this source tree; Runtime adapters point here without symlinks. Setup and Verify config defaults are actual readable private settings, not opaque seed expansions. Keep all actual configuration private. User-modified Runtime defaults are promoted only by a deliberate reviewed synchronization, not by routine builds.

Generated databases, physical collateral, execution reports/logs, scratch and backups are not source inputs. Existing auxiliary reference/debug Tcl that the user retained in Runtime is reproduced at its declared location. Original alternate documentation filenames remain in the source but are not silently injected into new Runtime trees.

See tools/sh/build_tech_runtime.sh and tools/check_tech_sync.py for creation and validation. Native APR/Verify regression remains separate from environment reproduction.
