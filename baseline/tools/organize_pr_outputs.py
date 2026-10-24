#!/usr/bin/env python3
"""Classify explicitly known, closed Innovus outputs; never alter DB/source data."""
import argparse
import datetime
import hashlib
import json
import os
from pathlib import Path
import re
import time

DEFAULT_ROOT = Path(__file__).absolute().parent.parent / 'build_PR'
MAPPING = {
    'temp': '.temp',
    'innovus2joules_work': '.temp/91_analysis/innovus2joules_work',
    'client_log': 'logs/05_route/client_log',
    'checkNetlist': 'reports/03_place/checkNetlist',
    'timingReports': 'reports/90_misc/timingReports',
    'TT_SW_M4_CONN_V12': 'reports/02_powerplan/sw_m4/TT_SW_M4_CONN_V12',
    'TT_SW_M4_V11_preflight.tsv': 'reports/02_powerplan/sw_m4/TT_SW_M4_V11_preflight.tsv',
    'TT_METAL_COLOR_V17.tsv': 'reports/05_route/metal_color/TT_METAL_COLOR_V17.tsv',
    'CHIP_init_shield.rpt': 'reports/05_route/shield/CHIP_init_shield.rpt',
    'CHIP.checkSdp.rpt': 'reports/02_powerplan/sdp/CHIP.checkSdp.rpt',
}

def safe(root, path):
    current = root
    if current.is_symlink():
        raise RuntimeError('Symlink runtime root')
    for part in path.relative_to(root).parts:
        current = current / part
        if current.is_symlink():
            raise RuntimeError('Refusing symlink path: ' + str(current))

def active_sessions(root):
    found = []
    for process in Path('/proc').iterdir():
        if not process.name.isdigit():
            continue
        try:
            comm = (process / 'comm').read_text().strip().lower()
            if any(tool in comm for tool in ('innovus', 'joules', 'nanoroute')):
                cwd = Path(os.readlink(str(process / 'cwd')))
                if cwd == root or root in cwd.parents:
                    found.append(process.name)
        except OSError:
            continue
    return found

def inventory(path):
    result = {}
    paths = [path] if path.is_file() else sorted(path.rglob('*'))
    for item in paths:
        label = '.' if item == path else str(item.relative_to(path))
        if item.is_symlink():
            result[label] = {'symlink': os.readlink(str(item))}
        elif item.is_file():
            h = hashlib.sha256()
            with item.open('rb') as f:
                for chunk in iter(lambda: f.read(1024 * 1024), b''):
                    h.update(chunk)
            result[label] = {'sha256': h.hexdigest(), 'size': item.stat().st_size}
        elif item.is_dir():
            result[label] = {'directory': True}
    return result

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, default=DEFAULT_ROOT)
    parser.add_argument('--apply', action='store_true')
    parser.add_argument('--record', type=Path)
    parser.add_argument('--after-innovus', action='store_true', help='Makefile has waited for its Innovus process to return')
    args = parser.parse_args()
    root = args.root.absolute()
    if not root.is_dir():
        raise RuntimeError('Missing runtime: ' + str(root))
    sessions = active_sessions(root)
    if args.apply and sessions:
        raise RuntimeError('Active EDA session(s); close before organizing: ' + ','.join(sessions))
    mapping = dict(MAPPING)
    for path in root.iterdir():
        if re.fullmatch(r'mp_data[0-9]+', path.name) and path.is_dir():
            mapping[path.name] = '.temp/90_misc/innovus_native/' + path.name
    token = datetime.datetime.now().strftime('%Y%m%d_%H%M%S_%f')
    plan = []
    for old, new in mapping.items():
        source = root / old
        if not source.exists() and not source.is_symlink():
            continue
        destination = root / new
        safe(root, source)
        safe(root, destination)
        if destination.exists():
            if old == 'temp':
                # Existing opaque scratch cannot be merged safely; preserve its identity.
                destination = root / '.temp/legacy_temp' / token
            else:
                destination = destination.with_name(destination.name + '_legacy_' + token)
        plan.append((source, destination))
    if args.apply and not args.after_innovus:
        # Visible /proc cannot detect remote sessions on shared storage.
        # Recent native artifacts are evidence that manual relocation is unsafe.
        fresh = []
        for source, destination in plan:
            if source.name == 'client_log' or source.name == 'innovus2joules_work' or re.fullmatch(r'mp_data[0-9]+', source.name):
                candidates = [source] + list(source.rglob('*'))
                if any(time.time() - path.stat().st_mtime < 300 for path in candidates if not path.is_symlink()):
                    fresh.append(source.name)
        if fresh:
            raise RuntimeError('Recent native output writes; leave active data in place: ' + ','.join(fresh))
    # Validate complete plan before the first mutation.
    for source, destination in plan:
        safe(root, destination)
        if destination.exists():
            raise RuntimeError('Destination conflict: ' + str(destination))
    records = []
    for source, destination in plan:
        print(('Move: ' if args.apply else 'Would move: ') + str(source.relative_to(root)) + ' -> ' + str(destination.relative_to(root)))
        if args.apply:
            before = inventory(source)
            destination.parent.mkdir(parents=True, exist_ok=True)
            source.rename(destination)
            after = inventory(destination)
            if after != before:
                raise RuntimeError('Moved content changed: ' + str(destination))
            records.append({'old': str(source.relative_to(root)), 'new': str(destination.relative_to(root)), 'inventory': before})
    if args.record:
        args.record.write_text(json.dumps(records, ensure_ascii=False, indent=2))
    elif args.apply and records:
        log = root / 'logs/00_common/output_organization'
        log.mkdir(parents=True, exist_ok=True)
        (log / (token + '.json')).write_text(json.dumps(records, ensure_ascii=False, indent=2))

if __name__ == '__main__':
    main()
