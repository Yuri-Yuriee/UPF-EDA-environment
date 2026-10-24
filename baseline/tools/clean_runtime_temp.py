#!/usr/bin/env python3
"""Clean explicitly classified scratch paths, preserving results and lock inodes."""
import argparse
import fcntl
import os
from pathlib import Path
import re
import shutil


def safe(path):
    for part in [path] + list(path.parents):
        if part.is_symlink():
            raise RuntimeError('Refusing symlink cleanup path: ' + str(part))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--runtime', type=Path, required=True)
    parser.add_argument('--project', type=Path)
    parser.add_argument('--apply', action='store_true')
    args = parser.parse_args()
    root = Path(os.path.abspath(str(args.runtime)))
    safe(root)
    paths = [root / name for name in ('.temp', 'temp', '.tt_iopad_bridge', 'innovus2joules_work', 'run/tool/ioPADt/build')]
    handles = []
    try:
        if args.apply:
            for proc in Path('/proc').iterdir():
                if not proc.name.isdigit():
                    continue
                try:
                    cmd = (proc / 'cmdline').read_bytes()
                    comm = (proc / 'comm').read_text().lower()
                    cwd = Path(os.readlink(str(proc / 'cwd')))
                except OSError:
                    continue
                tool = any(n in comm for n in ('innovus', 'joules', 'nanoroute', 'calibre', 'v2lvs')) or b'TT_tool_iopad_gui.py' in cmd
                if tool and (cwd == root or root in cwd.parents or str(root).encode() in cmd):
                    raise RuntimeError('Active EDA/ioPADt process; close before cleaning, PID ' + proc.name)
        if root.is_dir():
            paths += [p for p in root.iterdir() if re.fullmatch(r'mp_data[0-9]+', p.name)]
        for stage in ('lvs', 'drc', 'add_dummy'):
            base = root / 'verify' / stage
            temp = base / 'temp'
            safe(temp)
            if temp.is_dir():
                lock = temp / '.artifacts.lock'
                safe(lock)
                if args.apply:
                    h = open(str(lock), 'a'); handles.append(h)
                    fcntl.flock(h, fcntl.LOCK_EX | fcntl.LOCK_NB)
                paths += [p for p in temp.iterdir() if p.name != '.artifacts.lock']
            paths += [base / 'build', base / '.stage']
            generated = {
                'lvs': ('LVS_Calibre.modified', 'runset.generated.cmd'),
                'drc': ('LOGIC_TopMu_DRC', 'ANTENNA_DRC', 'runset_DRC.generated.cmd', 'runset_ANTENNA.generated.cmd'),
                'add_dummy': ('Dummy_FEOL_CalibreYE', 'Dummy_BEOL_CalibreYE', 'COD_AutoGen', 'runset_FE.generated.cmd', 'runset_BE.generated.cmd', 'runset_COD.generated.cmd', 'runset_merge.generated.cmd'),
            }
            paths += [base / 'scr' / name for name in generated[stage]]
        # Python bytecode is regenerated; scope excludes results, backups and private config.
        for base in (root / 'run/tool', root / 'verify/common'):
            if base.is_dir():
                paths += list(base.rglob('__pycache__'))
        if args.project:
            project = Path(os.path.abspath(str(args.project))); safe(project)
            paths += [project / 'temp', project / '.temp']
            if (project / 'tools').is_dir():
                paths += list((project / 'tools').rglob('__pycache__'))
        paths = sorted(set(p for p in paths if p.exists() or p.is_symlink()))
        # Preflight the entire plan before the first deletion.
        for p in paths:
            safe(p)
            if p.is_dir():
                for child in p.rglob('*'):
                    safe(child)
        selected = []
        for p in paths:
            if not any(parent in selected for parent in p.parents):
                selected.append(p)
        for p in selected:
            print(('Removing: ' if args.apply else 'Would remove: ') + str(p))
            if args.apply:
                if p.is_dir():
                    shutil.rmtree(str(p))
                else:
                    p.unlink()
        if not selected:
            print('Runtime scratch: already clean')
    finally:
        for h in handles:
            h.close()


if __name__ == '__main__':
    try:
        main()
    except (OSError, RuntimeError) as exc:
        raise SystemExit('Runtime scratch cleanup refused: ' + str(exc))
