# Runtime-authoritative synchronization — 2026-10-11

129 selected files were promoted from build_PR; one Runtime Tcl symlink is represented as a regular source wrapper in Mirror to preserve the no-soft-link execution policy. Its stage implementation is copied byte-for-byte. Runtime itself was not changed.

This is source selection, not an exact mirror of all Runtime artifacts. There was no deletion, history overwrite, executable algorithm edit, or full rsync --delete. Full selection/exclusions: project-root backup/TECH_MV_FROM_BUILD_PR_20261011/plan.json.

## Mapping

| Runtime | Mirror | Policy |
|---|---|---|
| init.setup | init.setup | exact source bytes |
| run/*.tcl | run/*.tcl | exact source bytes |
| run/tool Stage implementations/entries | same paths | exact source bytes; Runtime symlink becomes regular source entry |
| run/tool/ioPADt matching source/docs | same paths | update matching files; do not restructure ioPADt |
| setup/config + configured root inputs | same paths | exact source bytes; runtime exports/reports/installers excluded |
| verify existing formal sources | same paths | existing source allowlist refreshed; selected new support code added |
| shared script/ | script/ | unchanged; Runtime already sources this directory |
| Runtime dbs/logs/reports/temp/session/cache | no promotion | remain in Runtime |

## Preserved differences

Mirror-only legacy tools (not auto-enabled or merged):
- `run/tool/TT_pr6_post_unplace_route_cleanup.tcl`
- `run/tool/TT_pr6_2row_switch_guard.tcl`

Runtime encoded-name IOPAD legacy documents are not used to overwrite Mirror Unicode-named documents. backup/history/.nfs/marker data is retained independently; source archives do not overwrite different historical snapshots. `history` remains the existing archival link; no current Tcl execution depends on it.

The Mirror Makefile has no build_PR/Makefile counterpart and was retained. Runtime-only setup IO exports and repair patches are not assumed to be active configured inputs. Verify root scratch helpers, generated debug compare output, generated runsets, HCELL/netlists and Calibre products are excluded.

## Validation

Per group hashes compared after promotion; prepared clone and final promoted source tree matched. Selected implementation/config/Stage scripts were copied exactly. Runtime run/setup/init and shared script tree were checked unchanged. All 78 Runtime-derived top-level Mirror Tcl entries are regular source wrappers with existing real Stage targets.

A clean isolated build_PR was constructed using this Mirror; tclsh loaded init.setup, all 9 configuration files and FP_save/tech_mv_check_drc, and established the intended cwd. This does not run an EDA stage. Python AST, Shell syntax and Tcl completeness results are retained in the backup validation records.

Innovus is unavailable in the current environment; no full PR/Verify/GUI run was performed. Dynamic EDA/PDK dependencies are not proven by these static checks.

## Rollback

From the project root:

```bash
python3 backup/TECH_MV_FROM_BUILD_PR_20261011/rollback.py
```

Rollback validates archive/current hashes first, then restores only synchronization changes and metadata. It refuses to overwrite subsequent edits or remove nonempty new directories. Runtime and shared script remain untouched.
