# TECH Dummy Flow

This follows the supplied `TECH_verify` execution order:

```text
BEOL
COD
FEOL
MERGE
```

Run:

```bash
make -C verify dummy
```

or individually:

```bash
make -C verify dummy_be
make -C verify dummy_cod
make -C verify dummy_fe
make -C verify dummy_merge
```

The merged file retains the validated TECH filename:

```text
verify/add_dummy/output/CHIP_adddummmy.gds.gz
```

DRC and Antenna use this merged GDS.

Calibre and calibredrv execute in `build/current/`. Intermediate GDS and result databases stay there; summaries use `rpt/` and logs use `log/`. Generated rule-deck/runset copies are removed by the existing wrapper. `.stage/` completion markers remain in the stage directory.
