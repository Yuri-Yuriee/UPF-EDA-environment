#!/usr/bin/env python3
"""Remove known Verify outputs only; preserve scripts and project backups."""
import argparse
import shutil
from pathlib import Path
import artifacts

DIRECTORIES = ('log', 'output', 'rpt', 'svdb', 'build', '.stage')
LVS_INPUTS = ('CHIP.spi', 'CHIP_inc.spi', 'HCELL', 'LVSBOX', 'layout.spi')
DIAGNOSTICS = ('v2lvs.log', 'DCAP32_debug.txt', 'extra_pin_debug.txt', 'hcell_log_debug.txt', 'lvs_mode_debug.txt', 'hcell_lvsbox_count.txt', 'lvsbox_in_runset.txt')

def candidates():
    paths = [artifacts.ROOT / 'lvs_pack.tar.gz']
    for stage in artifacts.NAMES:
        base = artifacts.ROOT / stage
        paths.extend(base / name for name in DIRECTORIES)
        if (base / 'temp').is_dir():
            paths.extend(path for path in (base / 'temp').iterdir() if path.name != '.artifacts.lock')
        for folder in ('scr', 'temp'):
            paths.extend(base / folder / name for name in artifacts.NAMES[stage])
        for pattern in ('*.log', 'CalibreControllerLog.*', 'CalibreRRLog.*', 'CalibreHDBLog.*'):
            paths.extend(base.glob(pattern))
        if stage == 'lvs':
            paths.extend(base / name for name in LVS_INPUTS + DIAGNOSTICS)
        else:
            for pattern in ('*.gds', '*.gds.gz', '*.density'):
                paths.extend(base.glob(pattern))
    return sorted(set(paths))

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--preview', action='store_true')
    args = parser.parse_args()
    handles = []
    try:
        for stage in artifacts.NAMES:
            handles.append(artifacts.lock(stage))
        paths = candidates()
        # Check every destination and all descendants before any deletion.
        for path in paths:
            artifacts.safe(path)
            if path.is_dir():
                for child in path.rglob('*'):
                    artifacts.safe(child)
        for path in paths:
            if not path.exists():
                continue
            print(('Would remove ' if args.preview else 'Removing ') + str(path.relative_to(artifacts.ROOT)))
            if not args.preview:
                if path.is_dir():
                    shutil.rmtree(str(path))
                else:
                    path.unlink()
    finally:
        for handle in handles:
            handle.close()

if __name__ == '__main__':
    try:
        main()
    except (OSError, RuntimeError) as exc:
        raise SystemExit('Verify output cleanup refused: ' + str(exc))
