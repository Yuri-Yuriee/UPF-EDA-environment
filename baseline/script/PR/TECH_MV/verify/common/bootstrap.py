#!/usr/bin/env python3
"""Create a Verify runtime from the explicit source manifest, without results."""
import json
from pathlib import Path
import shutil
import sys

source = Path(__file__).absolute().parent.parent
destination = Path(sys.argv[1]).absolute()
if destination.exists() or destination.is_symlink():
    raise RuntimeError('Destination already exists: ' + str(destination))
manifest = json.loads((source / 'common/runtime_sources.json').read_text())
for name in manifest:
    path = source / name
    if Path(name).is_absolute() or '..' in Path(name).parts:
        raise RuntimeError('Unsafe manifest entry: ' + name)
    if path.is_symlink() or not path.is_file():
        raise RuntimeError('Missing or symlink source: ' + str(path))
    parent = path.parent
    while parent != source.parent:
        if parent.is_symlink():
            raise RuntimeError('Symlink source directory: ' + str(parent))
        parent = parent.parent
# Stage beside the destination; never leave a partially built runtime.
staging = destination.with_name(destination.name + '.creating')
if staging.exists() or staging.is_symlink():
    raise RuntimeError('Staging path already exists: ' + str(staging))
staging.mkdir()
try:
    for name in manifest:
        target = staging / name
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(str(source / name), str(target))
    staging.rename(destination)
except Exception:
    shutil.rmtree(str(staging))
    raise
print('Created Verify runtime from {} source files; no generated decks/results copied.'.format(len(manifest)))
