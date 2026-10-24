#!/usr/bin/env python3
"""Remove only disposable ioPADt build outputs; preview by default."""
import argparse
import os
from pathlib import Path
import shutil


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--runtime', type=Path, required=True)
    parser.add_argument('--apply', action='store_true')
    args = parser.parse_args()
    root = Path(os.path.abspath(str(args.runtime)))
    target = root / 'run/tool/ioPADt/build'
    for part in [root] + list(root.parents):
        if part.is_symlink():
            raise RuntimeError('Refusing symlink runtime')
    current = root
    for part in target.relative_to(root).parts:
        current = current / part
        if current.is_symlink():
            raise RuntimeError('Refusing symlink cleanup path')
    if not target.exists():
        print('ioPADt build outputs: already clean')
        return
    if not target.is_dir():
        raise RuntimeError('Expected ioPADt build directory')
    if args.apply:
        active = []
        for proc in Path('/proc').iterdir():
            if not proc.name.isdigit():
                continue
            try:
                cmd = (proc / 'cmdline').read_bytes()
                comm = (proc / 'comm').read_text().lower()
                cwd = Path(os.readlink(str(proc / 'cwd')))
                eda = any(name in comm for name in ('innovus', 'joules', 'nanoroute'))
                gui = b'TT_tool_iopad_gui.py' in cmd
                if (eda or gui) and (cwd == root or root in cwd.parents or str(root).encode() in cmd):
                    active.append(proc.name)
            except OSError:
                continue
        if active:
            raise RuntimeError('Close active Innovus/ioPADt before cleanup; PID: ' + ','.join(active))
        shutil.rmtree(str(target))
        print('Removed: ' + str(target))
    else:
        print('Would remove: ' + str(target))


if __name__ == '__main__':
    main()
