SW EN source graph -> Innovus probe
source_sw_chain.tsv is extracted from CHIP.spi target statements in uploaded Stage2 bundle; these statements cover HDR10 SWs. It is NOT verified against the original CHIP_pg.v (not provided).
Usage:
  1) Upload source_sw_chain.tsv and innovus_sw_en_probe.tcl to your workstation.
  2) In an already-open Innovus Common UI session:
       source /path/to/innovus_sw_en_probe.tcl
       TT_SW_EN_PROBE /path/to/source_sw_chain.tsv C01 0 8
  3) Compare source EN_IN/OUT to Innovus pin net, examine placement and any missing instance.
Notes: Source names are v2lvs SPICE names minus initial X; they may differ from Innovus hierarchical names. No automatic editing performed. Script loops over all insts per target and may be slow on a large chip; use few steps initially.
