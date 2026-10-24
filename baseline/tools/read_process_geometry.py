#!/usr/bin/env python3
"""Read configured LEF paths and write local geometry metadata; never change flow settings."""
import argparse
import gzip
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys

def tcl_word(value):
    return '"' + ''.join(('\\' + c) if c in '\\$[]"' else ('\\n' if c == '\n' else c) for c in str(value)) + '"'

def configured_files(runtime):
    init = runtime / 'init.setup'
    if not init.is_file():
        raise ValueError('Missing runtime init.setup')
    # Existing init.setup only loads the project's setup/configuration/helpers.
    script = 'source ' + tcl_word(init) + '''
if {![info exists LEF_FILES]} { error "LEF_FILES is not configured" }
foreach name $LEF_FILES {
    binary scan [encoding convertto utf-8 $name] H* encoded
    puts "GEOMETRY_LEF_HEX:$encoded"
}
if {[info exists CORE_SITE]} {
    binary scan [encoding convertto utf-8 $CORE_SITE] H* encoded
    puts "GEOMETRY_SITE_HEX:$encoded"
}
'''
    result = subprocess.run(['tclsh'], input=script, stdout=subprocess.PIPE, stderr=subprocess.PIPE, universal_newlines=True, cwd=str(runtime))
    if result.returncode or result.stderr.strip():
        raise ValueError('Configuration evaluation failed; inspect local configuration without publishing it')
    paths = []; site = None
    for line in result.stdout.splitlines():
        if line.startswith('GEOMETRY_LEF_HEX:'):
            value = bytes.fromhex(line.split(':', 1)[1]).decode('utf-8')
            p = Path(value); paths.append(p if p.is_absolute() else runtime / p)
        elif line.startswith('GEOMETRY_SITE_HEX:'):
            site = bytes.fromhex(line.split(':', 1)[1]).decode('utf-8')
    if not paths:
        raise ValueError('No configured LEF files resolved')
    return paths, site

NUMBER = r'[-+]?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][-+]?\d+)?'

def parse_lef(path):
    raw = path.read_bytes()
    text = (gzip.decompress(raw) if path.name.endswith('.gz') else raw).decode('utf-8', 'strict')
    text = re.sub(r'#[^\n]*', '', text)
    objects = []
    for start in re.finditer(r'^\s*(SITE|MACRO|LAYER)\s+(\S+)\s*$', text, re.M):
        kind, name = start.groups()
        end = re.search(r'^\s*END\s+' + re.escape(name) + r'\s*$', text[start.end():], re.M)
        if not end:
            raise ValueError('Unclosed LEF object; refusing partial geometry output')
        body = text[start.end():start.end() + end.start()]
        values = {}
        size = re.search(r'\bSIZE\s+(' + NUMBER + r')\s+BY\s+(' + NUMBER + r')\s*;', body)
        if kind in ('SITE', 'MACRO') and size:
            values.update(size_x=size.group(1), size_y=size.group(2))
        if kind == 'LAYER':
            # Extract only top-level layer lines; do not guess complex spacing-table semantics.
            for prop in ('WIDTH', 'PITCH', 'SPACING'):
                matches = re.findall(r'^\s*' + prop + r'\s+(' + NUMBER + r')(?:\s+(' + NUMBER + r'))?\s*;\s*$', body, re.M)
                if matches:
                    values[prop.lower()] = [list(filter(None, pair)) for pair in matches]
        if values:
            objects.append({'kind': kind, 'name': name, 'values': values})
    if not objects:
        raise ValueError('No supported LEF geometry found; encrypted/unsupported files need another reader')
    return {'path': str(path), 'sha256': hashlib.sha256(raw).hexdigest(), 'objects': objects}

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--runtime', type=Path, help='Resolve LEF_FILES and CORE_SITE from runtime init.setup')
    parser.add_argument('--lef', type=Path, action='append', default=[], help='Explicit authorized LEF path; repeatable')
    parser.add_argument('--output', type=Path, required=True, help='PRIVATE JSON destination; existing files are never overwritten')
    args = parser.parse_args()
    paths = list(args.lef); site = None
    if args.runtime:
        configured, site = configured_files(args.runtime.absolute()); paths += configured
    paths = list(dict.fromkeys(p.absolute() for p in paths))
    if not paths:
        parser.error('Specify --runtime or --lef')
    if args.output.exists() or args.output.is_symlink():
        raise ValueError('Output already exists; choose a new private filename')
    records = [parse_lef(p) for p in paths]
    candidates = [dict(source=record['path'], **obj) for record in records for obj in record['objects'] if obj['kind'] == 'SITE' and obj['name'] == site] if site else []
    data = {'private_data_do_not_publish': True, 'configured_core_site': site, 'core_site_candidates': candidates, 'files': records,
            'limitations': ['Textual LEF geometry only; values are preserved without unit conversion.', 'No derivation of user margins, tolerances, offsets, design policies or voltage.', 'Complex spacing tables, encrypted decks, conditional/expanded rules and QRC are not interpreted.', 'No flow parameter is overridden. Matching a number does not establish its provenance or disclosure rights.']}
    args.output.parent.mkdir(parents=True, exist_ok=True)
    fd = os.open(str(args.output), os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    with os.fdopen(fd, 'w') as stream:
        json.dump(data, stream, indent=2)
    print('Read {} LEF files; wrote PRIVATE geometry metadata. Flow parameters unchanged.'.format(len(records)))

if __name__ == '__main__':
    try:
        main()
    except (ValueError, OSError, UnicodeError) as exc:
        print('ERROR: ' + str(exc), file=sys.stderr)
        sys.exit(2)
