#!/usr/bin/env python3
"""Conservative source/metadata audit; never read binary technology inputs."""
import argparse
import hashlib
import json
import re
import subprocess
from pathlib import Path

FORBIDDEN_SUFFIXES = {'.db', '.lef', '.lib', '.gds', '.gdsii', '.oas', '.enc',
                      '.spi', '.spice', '.spef', '.sdf', '.map', '.qrc', '.tch',
                      '.tf', '.io', '.upf', '.sdc', '.rule', '.rul', '.deck', '.bin'}
PRIVATE_PARTS = {'private', '.private_config', 'backup', '.backup', 'history',
                 'dbs', 'outputs', 'reports', 'logs', 'PR_log', 'PR_cmd', '.temp',
                 'temp', 'temp_doc', 'client_log', '__pycache__', '.git', 'github_export', 'verify', 'build'}
TEXT_SUFFIXES = {'.tcl', '.py', '.sh', '.csh', '.mk', '.md', '.txt', '.json',
                 '.yaml', '.yml', '.cfg', '.conf', '.ini', '.view', '.setup'}
PATTERNS = {
    'manual_review_required': re.compile(r'PUBLIC_EXPORT_REVIEW_REQUIRED'),
    'library_or_pattern_candidate': re.compile(r'\b\w*CELL_FAMILY\w*\b|\bHDR\w+\b'),
    'private_resource_path': re.compile(r'/FILL_IN/FILL_IN_RESOURCE_0199|/FILL_IN/FILL_IN_RESOURCE_0200|/proj/|/net/|/nfs/|/pdk/', re.I),
    'geometry_candidate': re.compile(r'(width|spacing|pitch|offset|halo|grid|jog|keep.?out|gap).*?(\d+\.\d+|\.\d+)', re.I),
    'technology_selector_candidate': re.compile(r'(?<![\w])(?:M[1-9]\d*|VIA[1-9]\d*)(?![\w])'),
}


def audit(root, paths):
    findings = []
    scanned = 0
    for relative in paths:
        path = root / relative
        reasons = []
        # These are metadata checks; no process input or private file is read.
        if path.is_symlink():
            reasons.append('symlink_requires_review')
        elif (set(relative.parts) & PRIVATE_PARTS or
              path.suffix.lower() in FORBIDDEN_SUFFIXES or
              re.search(r'\.(db|lef|lib|gds|oas|enc|spi|spice|spef|sdf|map|qrc|tch|tf|bin)(\.|$)', path.name, re.I) or
              re.search(r'\.bin_|\.nfs|\.rpt|\.log|\.cmd|\.jou|DB_PATCH|IOPAD_EDITED', path.name) or
              any(part.startswith('mp_data') for part in relative.parts) or
              'sram' in path.name.lower() and path.suffix.lower() in {'.v', '.sv', '.vh'}):
            reasons.append('private_or_generated_file_in_release')
        elif path.is_file() and (path.suffix.lower() in TEXT_SUFFIXES or
                                path.name in {'Makefile', 'init.setup', '.gitignore'}):
            data = path.read_bytes()
            if b'\0' in data:
                reasons.append('opaque_binary_requires_review')
            else:
                scanned += 1
                for line_number, line in enumerate(data.decode(errors='replace').splitlines(), 1):
                    for name, expression in PATTERNS.items():
                        if expression.search(line):
                            reasons.append({'line': line_number, 'reason': name})
        elif path.is_file():
            reasons.append('unclassified_file_requires_review')
        if reasons:
            findings.append({'file_id': hashlib.sha256(str(relative).encode()).hexdigest()[:16],
                             'reasons': reasons})
    return {'scanned_text_files': scanned, 'candidate_files': len(findings),
            'findings': findings,
            'notice': 'Candidates require review; this tool does not provide legal or NDA clearance.'}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, default=Path.cwd())
    parser.add_argument('--tree', action='store_true', help='Audit an explicit staging tree rather than Git tracked files')
    args = parser.parse_args()
    root = args.root.resolve()
    if args.tree:
        paths = [p.relative_to(root) for p in root.rglob('*') if p.is_file() or p.is_symlink()]
    else:
        result = subprocess.run(['git', '-C', str(root), 'ls-files', '-z'],
                                stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        if result.returncode:
            print(json.dumps({'git_tracking_check': 'unavailable',
                              'release_ready': False,
                              'notice': 'Use a valid Git repository to inspect tracked files; ignore rules alone are insufficient.'}))
            return 2
        paths = [Path(item.decode(errors='surrogateescape')) for item in result.stdout.split(b'\0') if item]
    report = audit(root, paths)
    print(json.dumps(report, indent=2))
    return 1 if report['candidate_files'] else 0


if __name__ == '__main__':
    raise SystemExit(main())
