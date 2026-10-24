# TT_proc_fill_nosw_powergate_rows.tcl — RETIRED

## Status

**Retired. Do not re-enable this helper in the main flow.**

## Why it was retired

The original helper ran **after Power-Switch insertion and SW/EndCap cleanup**.
When a logical 2-row lane ended up with zero Power Switches, it filled the lane
with fixed standard filler cells while explicitly excluding `DCAP*`.

That solved the immediate empty-row symptom, but it left the underlying
Power-Switch row-parity problem in the floorplan. In other words, the physical
row still existed but was artificially sealed by filler. This can become a
maintenance hazard for later WellTap, SDP, placement and physical-debug flows.

## Replacement

`TT_proc_trim_powergate_bottom_row.tcl`

The replacement runs **before EndCap and Power-Switch insertion**. For each
Power Domain that is configured to contain Power Switches:

1. count usable `core` physical rows inside each PD rectangle;
2. if the count is even, keep the rows unchanged;
3. if the count is odd, **always remove the bottom row segment**;
4. re-read the live rows and require an even row count before continuing.

This fixes the topology instead of masking it with fixed filler.

## Historical implementation

The Tcl file is intentionally kept in both runtime and master tool trees for
history/debug reference. Its public `TT_NOSW_ROW_FILL_apply` entry is disabled
and fails closed if called. The original implementation is retained internally
as `TT_NOSW_ROW_FILL_apply_RETIRED_IMPL` after sourcing.
