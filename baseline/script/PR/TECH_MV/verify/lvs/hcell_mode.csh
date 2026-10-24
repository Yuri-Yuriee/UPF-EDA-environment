#!/bin/tcsh
# =============================================================================
# TECH_MV LVS hierarchical compare controls
# =============================================================================
# Core hierarchy policy
#   VERIFY_HCELL_MODE          ON  : use Calibre -hier -hcell ./HCELL
#                              OFF : do not pass an explicit HCELL file
#   VERIFY_LVSBOX_MODE         ON  : append explicit LVS BOX statements
#                              OFF : do not append LVS BOX statements
#
# Well/body hierarchy fix policy
#   VERIFY_WELL_TEXT_MODE      ON  : define WELL_TEXT before foundry deck include
#                                    -> enables nxwell_text / psub_text + PORT LAYER TEXT
#                              OFF : keep foundry default (well text disabled)
#
# Full-chip name-connect policy
#   VERIFY_VCONNECT_COLON_MODE ON  : force VIRTUAL CONNECT COLON YES
#                              OFF : force VIRTUAL CONNECT COLON NO
#   Foundry deck explicitly recommends NO for full-chip checking.
#
# Adaptive HCELL expansion policy
#   VERIFY_EXPAND_SEED_PROMOTIONS_MODE
#                              ON  : LVS EXPAND SEED PROMOTIONS YES
#   VERIFY_EXPAND_HIGH_SHORT_HCELLS_MODE
#                              ON  : LVS EXPAND AMBIGUOUSLY HIGH SHORTED HCELLS YES
#   VERIFY_SHOW_SEED_PROMOTIONS_MODE
#                              ON  : report seed promotions for debug
#   VERIFY_SHOW_SEED_PROMOTIONS_MAX
#                              max reported promotion polygons (default 2000)
#
# Production default after 2026-09-14 A/B debug:
#   HCELL=ON, LVSBOX=OFF, WELL_TEXT=ON.
#   Preserve the pre-WELL_TEXT hierarchy behavior for the other controls:
#   VIRTUAL CONNECT COLON=YES, seed-promotion expansion=OFF,
#   ambiguous high-short HCELL expansion=OFF.
#
# Reason: WELL_TEXT fixed the numeric well/body HCELL ports (7/10/12...),
# while enabling several unrelated hierarchy overrides in the same run caused
# large new top-level VPP/VBB/local-net mismatches. Keep the proven fix and
# remove the extra variables.
#
# IMPORTANT:
# - LVS SOFT SUBSTRATE PINS remains at foundry default (NO).
# - LVS IGNORE PORTS remains NO.
# - Foundry rule deck itself is NOT edited; run_lvs.csh injects controlled
#   pre-include/post-include settings into runset.generated.cmd.
# =============================================================================

if (! $?VERIFY_HCELL_MODE) then
    setenv VERIFY_HCELL_MODE ON
endif

if (! $?VERIFY_LVSBOX_MODE) then
    setenv VERIFY_LVSBOX_MODE OFF
endif

if (! $?VERIFY_WELL_TEXT_MODE) then
    setenv VERIFY_WELL_TEXT_MODE ON
endif

if (! $?VERIFY_VCONNECT_COLON_MODE) then
    setenv VERIFY_VCONNECT_COLON_MODE ON
endif

if (! $?VERIFY_EXPAND_SEED_PROMOTIONS_MODE) then
    setenv VERIFY_EXPAND_SEED_PROMOTIONS_MODE OFF
endif

if (! $?VERIFY_EXPAND_HIGH_SHORT_HCELLS_MODE) then
    setenv VERIFY_EXPAND_HIGH_SHORT_HCELLS_MODE OFF
endif

if (! $?VERIFY_SHOW_SEED_PROMOTIONS_MODE) then
    setenv VERIFY_SHOW_SEED_PROMOTIONS_MODE OFF
endif

if (! $?VERIFY_SHOW_SEED_PROMOTIONS_MAX) then
    setenv VERIFY_SHOW_SEED_PROMOTIONS_MAX 2000
endif
