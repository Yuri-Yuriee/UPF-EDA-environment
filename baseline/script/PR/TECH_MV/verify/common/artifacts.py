#!/usr/bin/env python3
"""Clean only named disposable local deck/runset copies, never source collateral."""
import argparse
import fcntl
import os
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).absolute().parent.parent
NAMES = {
    'drc': ['LOGIC_TopMu_DRC', 'ANTENNA_DRC', 'runset_DRC.generated.cmd', 'runset_ANTENNA.generated.cmd'],
    'add_dummy': ['Dummy_FEOL_CalibreYE', 'Dummy_BEOL_CalibreYE', 'COD_AutoGen'] + ['runset_' + s + '.generated.cmd' for s in ('FE', 'BE', 'COD', 'merge')],
    'lvs': ['LVS_Calibre.modified', 'runset.generated.cmd'],
}

def safe(path):
    relative = path.relative_to(ROOT)
    current = ROOT
    if current.is_symlink():
        raise RuntimeError('Refusing symlink Verify root: ' + str(current))
    for part in relative.parts:
        current = current / part
        if current.is_symlink():
            raise RuntimeError('Refusing symlink artifact path: ' + str(current))
    return path

def clean(stage, preview=False, layout=False):
    candidates = [ROOT / stage / directory / name for directory in ('scr', 'temp') for name in NAMES[stage]]
    if stage in ('drc', 'add_dummy'):
        candidates += [ROOT / stage / 'build' / 'current' / name for name in NAMES[stage]]
    for path in candidates:
        safe(path)
    for path in candidates:
        if path.exists():
            if not path.is_file():
                raise RuntimeError('Refusing non-file artifact: ' + str(path))
            print(('Would remove ' if preview else 'Removing ') + str(path))
            if not preview:
                path.unlink()

def organize_native_logs(stage):
    """Archive only standalone Calibre execution logs; keep result dependencies in place."""
    if stage not in ('drc', 'add_dummy'):
        return
    import hashlib
    import json
    import time
    directory = safe(ROOT / stage / 'log' / 'calibre_native')
    directory.mkdir(parents=True, exist_ok=True)
    moves = []
    for prefix in ('CalibreControllerLog.', 'CalibreRRLog.', 'CalibreHDBLog.'):
        for path in sorted(list((ROOT / stage).glob(prefix + '*')) + list((ROOT / stage / 'build' / 'current').glob(prefix + '*'))):
            safe(path)
            if not path.is_file():
                raise RuntimeError('Refusing non-file Calibre log: ' + str(path))
            digest = hashlib.sha256(path.read_bytes()).hexdigest()
            target = safe(directory / path.name)
            if target.exists():
                target = safe(directory / (path.name + '.legacy_' + str(time.time_ns() if hasattr(time, 'time_ns') else int(time.time() * 1000000))))
            if target.exists():
                raise RuntimeError('Calibre log destination collision: ' + str(target))
            path.rename(target)
            if hashlib.sha256(target.read_bytes()).hexdigest() != digest:
                raise RuntimeError('Calibre log checksum changed: ' + str(target))
            moves.append({'old': str(path.relative_to(ROOT)), 'new': str(target.relative_to(ROOT)), 'sha256': digest})
    if moves:
        record = safe(directory / ('moves_' + str(int(time.time() * 1000000)) + '.json'))
        with open(str(record), 'x') as handle:
            json.dump(moves, handle, indent=2)
        print('Archived ' + str(len(moves)) + ' Calibre execution logs.')

def organize_lvs_diagnostics(stage):
    """Classify only known standalone legacy diagnostics, preserving collisions."""
    if stage != 'lvs':
        return
    import time
    import hashlib
    import json
    targets = {
        'v2lvs.log': 'log/legacy/v2lvs.log',
        'DCAP32_debug.txt': 'log/debug/DCAP32_debug.txt',
        'extra_pin_debug.txt': 'log/debug/extra_pin_debug.txt',
        'hcell_log_debug.txt': 'log/debug/hcell_log_debug.txt',
        'lvs_mode_debug.txt': 'rpt/debug/lvs_mode_debug.txt',
        'hcell_lvsbox_count.txt': 'rpt/debug/hcell_lvsbox_count.txt',
        'lvsbox_in_runset.txt': 'rpt/debug/lvsbox_in_runset.txt',
    }
    moved = []
    for name, relative in targets.items():
        source = safe(ROOT / stage / name)
        if not source.exists():
            continue
        if not source.is_file():
            raise RuntimeError('Refusing non-file diagnostic: ' + str(source))
        target = safe(ROOT / stage / relative)
        target.parent.mkdir(parents=True, exist_ok=True)
        if target.exists():
            target = safe(target.with_name(target.name + '.legacy_' + str(int(time.time() * 1000000))))
        if target.exists():
            raise RuntimeError('Diagnostic destination collision: ' + str(target))
        digest = hashlib.sha256(source.read_bytes()).hexdigest()
        source.rename(target)
        if hashlib.sha256(target.read_bytes()).hexdigest() != digest:
            raise RuntimeError('Diagnostic checksum changed: ' + str(target))
        moved.append({'old': str(source.relative_to(ROOT)), 'new': str(target.relative_to(ROOT)), 'sha256': digest})
    if moved:
        record = safe(ROOT / stage / 'log' / ('diagnostic_moves_' + str(int(time.time() * 1000000)) + '.json'))
        record.parent.mkdir(parents=True, exist_ok=True)
        with open(str(record), 'x') as handle:
            json.dump(moved, handle, indent=2)

def lock(stage):
    directory = safe(ROOT / stage / 'temp')
    directory.mkdir(exist_ok=True)
    path = safe(directory / '.artifacts.lock')
    handle = open(str(path), 'a')
    fcntl.flock(handle, fcntl.LOCK_EX | fcntl.LOCK_NB)
    return handle

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=('run', 'clean', 'preview'))
    parser.add_argument('stage', nargs='?', choices=tuple(NAMES))
    parser.add_argument('command', nargs=argparse.REMAINDER)
    args = parser.parse_args()
    stages = [args.stage] if args.stage else list(NAMES)
    if args.action == 'run':
        if not args.stage or not args.command:
            parser.error('run requires stage and command')
        command = args.command[1:] if args.command[0] == '--' else args.command
        with lock(args.stage):
            try:
                return subprocess.call(command, cwd=str(ROOT / args.stage))
            finally:
                if args.stage != 'lvs' or os.environ.get('VERIFY_KEEP_LVS_STAGING') != '1':
                    clean(args.stage)
                organize_native_logs(args.stage)
                organize_lvs_diagnostics(args.stage)
    handles = []
    try:
        for stage in stages:
            handles.append(lock(stage))
        for stage in stages:
            clean(stage, args.action == 'preview', layout=True)
    finally:
        for handle in handles:
            handle.close()
    return 0

if __name__ == '__main__':
    try:
        sys.exit(main())
    except (OSError, RuntimeError) as exc:
        print('ERROR: ' + str(exc), file=sys.stderr)
        sys.exit(2)
