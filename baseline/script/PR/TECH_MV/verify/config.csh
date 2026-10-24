# =============================================================================
# TECH_MV Verify Configuration
# =============================================================================
# Source this file from verify/{lvs,drc,add_dummy}/.
#
# It is intentionally runtime-derived so the same verify tree works from the
# master TECH_MV tree and can also point to a separate build_PR output.
# Environment variables may override any path before the scripts are run.
# =============================================================================

if (! $?VERIFY_ROOT) then
    setenv VERIFY_ROOT `cd ..; pwd`
endif

# Normal execution uses build_PR/verify. The project-root Makefile passes the
# master flow and project root explicitly. Direct execution from the master
# verify directory remains supported through the fallback paths below.
if (! $?TECH_MV_ROOT) then
    if ($?VERIFY_FLOW_SOURCE_DIR) then
        setenv TECH_MV_ROOT "$VERIFY_FLOW_SOURCE_DIR"
    else
        setenv TECH_MV_ROOT `cd "$VERIFY_ROOT/.."; pwd`
    endif
endif

if (! $?PROJECT_ROOT) then
    if ($?VERIFY_PROJECT_ROOT) then
        setenv PROJECT_ROOT "$VERIFY_PROJECT_ROOT"
    else
        setenv PROJECT_ROOT `cd "$TECH_MV_ROOT/../../.."; pwd`
    endif
endif

if (! $?VERIFY_TOP) then
    setenv VERIFY_TOP CHIP
endif

# C-shell syntax; all resource/output paths are configured here.
source "$VERIFY_ROOT/config/verify_path.cfg"

# Optional local scratch override for Calibre LVS.
# Default selection in run_lvs.csh:
#   VERIFY_LVS_SCRATCH_ROOT -> TMPDIR -> /tmp/$USER
# Example:
#   setenv VERIFY_LVS_SCRATCH_ROOT /local_scratch/$USER
#
# Set to 1 only when you want successful local scratch kept for debug.
if (! $?VERIFY_KEEP_LVS_SCRATCH) then
    setenv VERIFY_KEEP_LVS_SCRATCH 0
endif

# LVS Hcell mode:
#   ON  = generate/use HCELL + LVSBOX (default)
#   OFF = run LVS without explicit HCELL and without auto-generated LVSBOX
# Can be overridden before make/run, for example:
#   setenv VERIFY_HCELL_MODE OFF
if (! $?VERIFY_HCELL_MODE) then
    setenv VERIFY_HCELL_MODE ON
endif

if (! $?VERIFY_CPU_LVS) then
    setenv VERIFY_CPU_LVS 32
endif
if (! $?VERIFY_CPU_DRC) then
    setenv VERIFY_CPU_DRC 128
endif
if (! $?VERIFY_CPU_ANTENNA) then
    setenv VERIFY_CPU_ANTENNA 64
endif
if (! $?VERIFY_CPU_DUMMY) then
    setenv VERIFY_CPU_DUMMY 64
endif

# VERIFY_DUMMY_GDS is defined in verify_path.cfg.

# Optional extracted layout netlist copy for explicit debug requests only.
if (! $?VERIFY_COPY_LVS_LAYOUT_SPICE) then
    setenv VERIFY_COPY_LVS_LAYOUT_SPICE 0
endif

# Centralized Verify list/spec configuration; environment overrides remain supported.
if (! $?VERIFY_HCELL_EXCLUDE_LIST) then
    setenv VERIFY_HCELL_EXCLUDE_LIST "$VERIFY_ROOT/config/private/hcell_exclude.list"
endif
if (! $?VERIFY_HCELL_LEF_LIST) then
    setenv VERIFY_HCELL_LEF_LIST "$VERIFY_ROOT/config/private/hcell_lef.list"
endif
if (! $?VERIFY_LVSBOX_CELLS_LIST) then
    setenv VERIFY_LVSBOX_CELLS_LIST "$VERIFY_ROOT/config/private/lvsbox_cells.list"
endif
if (! $?VERIFY_SOURCE_SPICE_SPEC) then
    setenv VERIFY_SOURCE_SPICE_SPEC "$VERIFY_ROOT/config/private/source_spice.spec"
endif

if (! $?VERIFY_DEBUG_RULES_FILE) then
    setenv VERIFY_DEBUG_RULES_FILE "$VERIFY_ROOT/config/private/debug.rules.json"
endif
