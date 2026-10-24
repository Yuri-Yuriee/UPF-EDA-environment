#!/usr/bin/env python3
"""Validate reproducible Runtime entries and shared code; local config edits are explicit."""
import argparse
import json
from pathlib import Path
import re
import stat
import sys

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--root', type=Path, default=Path(__file__).absolute().parent.parent)
parser.add_argument('--strict-defaults', action='store_true', help='Require Runtime settings to match the source defaults too')
args = parser.parse_args()
root = args.root.absolute()
source = root / 'script/PR/TECH_MV'
runtime = root / 'build_PR'
manifest = source / 'runtime_sources.list'
failures = []
customized = []
entries = {}
for line in manifest.read_text().splitlines():
    if not line or line.startswith('#'):
        continue
    kind, name = line.split('\t', 1)
    if kind not in ('copy', 'adapter') or Path(name).is_absolute() or '..' in Path(name).parts or name in entries:
        failures.append('Invalid Runtime manifest entry: ' + name)
    entries[name] = kind
adapters = set(json.loads((root / 'tools/tech_runtime_sources.json').read_text()))
if adapters != {n for n, kind in entries.items() if kind == 'adapter'}:
    failures.append('Runtime adapter registry and source manifest differ')

def is_runtime_config(name):
    return (name.startswith('setup/') or name == 'init.setup' or
            name.startswith('verify/config/') or
            name in ('verify/config.csh', 'verify/verify_path.cfg', 'verify/verify_path.template.cfg'))

def regular(path):
    current = path
    while current != root.parent:
        if current.is_symlink():
            return False
        if current == root:
            break
        current = current.parent
    return path.is_file()

for name, kind in sorted(entries.items()):
    a = runtime / name
    b = source / name
    if not regular(a) or not regular(b):
        failures.append('Missing/non-regular Runtime or source entry: ' + name)
        continue
    if kind == 'adapter':
        depth = len(Path(name).parts) - 1
        expected = ('# Single implementation: script/PR/TECH_MV/' + name + '\n'
                    'set ::TECH_MV_RUNTIME_ROOT [file normalize [file join [file dirname [info script]] ' + ' '.join(['..'] * depth) + ']]\n'
                    'source [file normalize [file join $::TECH_MV_RUNTIME_ROOT .. script PR TECH_MV ' + name + ']]\n')
        prefix = ('# Runtime adapter preserves the historical logical source path.\n'
                  'if {[info exists ::TECH_MV_RUNTIME_ROOT]} {\n'
                  '    info script [file join $::TECH_MV_RUNTIME_ROOT ' + name + ']\n}\n')
        if a.read_text() != expected or not b.read_text().startswith(prefix):
            failures.append('Invalid source adapter: ' + name)
    elif a.read_bytes() != b.read_bytes():
        if is_runtime_config(name):
            customized.append(name)
            if args.strict_defaults:
                failures.append('Runtime config differs from source defaults: ' + name)
        else:
            failures.append('Runtime implementation differs from source: ' + name)
    if stat.S_IMODE(a.stat().st_mode) != stat.S_IMODE(b.stat().st_mode):
        failures.append('Runtime/source mode differs: ' + name)

for base in (runtime, source):
    tool = base / 'run/tool'
    for path in [tool] + list(tool.rglob('*')):
        if path.is_symlink():
            failures.append('Forbidden tool symlink: ' + str(path.relative_to(root)))
    for path in tool.glob('*.tcl'):
        failures.append('Unexpected top-level tool Tcl: ' + str(path.relative_to(root)))
    for path in (base / 'run').iterdir():
        if path.name != 'tool' and not re.match(r'^0[0-6]_[A-Za-z_]+\.tcl$', path.name):
            failures.append('Unexpected run entry: ' + str(path.relative_to(root)))

flow_sources = json.loads((root / 'tools/tech_flow_sources.json').read_text())
for item in flow_sources:
    if not regular(root / item['source']):
        failures.append('Missing/non-regular canonical flow source: ' + item['source'])
    for base in (runtime, source):
        if (base / item['old']).exists() or (base / item['old']).is_symlink():
            failures.append('Flow-only source still in active tool tree: ' + str(base / item['old']))
for path in (source / 'script').rglob('TT_*.tcl'):
    if not any(part in ('backup', '.backup', 'history', 'private') for part in path.parts):
        failures.append('Unexpected TT-prefixed flow filename: ' + str(path.relative_to(root)))

# Diagnose newly added manual code instead of silently certifying an incomplete allowlist.
skip = {'.backup', 'backup', 'history', 'build', '__pycache__', '.temp', 'temp',
        'logs', 'log', 'outputs', 'output', 'reports', 'rpt', 'dbs', 'svdb', '.stage'}
unlisted = []
for component in ('run', 'setup', 'verify'):
    for path in (runtime / component).rglob('*'):
        name = str(path.relative_to(runtime))
        ignored = set(Path(name).parts) & skip
        if name.startswith('run/tool/'):
            # A functional tool category named reports is source, not a result directory.
            ignored -= {'reports', 'rpt'}
        if path.is_file() and path.suffix in {'.tcl', '.py', '.sh', '.csh'} and not ignored and name not in entries:
            unlisted.append(name)
            failures.append('Runtime source absent from reproduction manifest: ' + name)

if failures:
    print('FAIL: {} environment/source checks'.format(len(failures)))
    for name in failures:
        print(name)
    sys.exit(1)
print('PASS: {} declared Runtime files; {} source adapters; {} canonical flow modules; {} local config differences{}; no tool symlinks.'.format(
    len(entries), len(adapters), len(flow_sources), len(customized), ' (strict defaults)' if args.strict_defaults else ' (retained, not silently treated as equal)'))
for name in customized:
    print('LOCAL CONFIG: ' + name)
