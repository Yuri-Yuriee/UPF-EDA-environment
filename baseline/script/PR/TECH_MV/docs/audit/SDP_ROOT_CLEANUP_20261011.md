# Root/SDP cleanup (2026-10-11)

Active source authority: build_PR. 237 selected run/setup/init/Verify source files match by SHA256; generated Runtime data and differing historical documents are excluded.

Old tools are archived in `.backup/old_tool/` in both Runtime and Mirror, with identical bytes: TT_pr6_post_unplace_route_cleanup.tcl, TT_pr6_2row_switch_guard.tcl, TT_cleanup_sdpwt_pool_pollution.tcl. No active source references were found. Archived tools are not automatically loaded. Their historical relative paths are not guaranteed for execution from the archive.

Root SDP data now lives in `build_PR/temp/02_powerplan/sdp/`. Creator and repair default paths agree. Manual write_sdp_file hints target that directory. The pre_v6_9 backup is preserved in `build_PR/.backup/old_sdp/`. New native SDP DB checkpoints target `build_PR/dbs/TT_2row_sdp_checkpoints/`. Existing 1.9 GB root checkpoint directory is deliberately retained: internal DB paths/library links require actual Innovus restore verification before moving.

Existing explicit Tcl variable overrides in an already loaded Innovus session remain intact. Reloaded scripts use the new defaults. Historical command logs and DB metadata keep their original path text.

Root CHIP.checkSdp.rpt is retained because native check_sdps and its consumers use it; CHIP.drc.rpt is retained for existing DB links. Active metal-color/SW reports and unknown root artifacts are retained pending separate producer/consumer path validation. ioPADt internals, geometry and EDA behavior are unchanged.

Mirror top-level tool compatibility entries and Runtime entries are ordinary Tcl files; history archival links and DB library links are preserved.

Backup, precise mappings, static/dependency checks and rollback: `backup/TECH_SDP_ROOT_CLEANUP_20261011/` at project root. Full Innovus/Calibre flow validation is still pending.
