#!/usr/bin/env python3
"""Explicitly install a local private Tcl configuration; no technology defaults."""
import argparse
import os
from pathlib import Path
import tempfile

def install_setup_bundle(runtime, seed_directory):
    """Install optional authorized setup companions without replacing local edits."""
    private_directory = runtime / 'setup/config/private'
    names = ('setup_commands.tcl', 'geometry_review.config.tcl')
    present = [(seed_directory / name).exists() for name in names]
    if any(present) and not all(present):
        raise ValueError('Private setup companions must be supplied together')
    # Validate all companions before installing any file.
    for name in names:
        source = seed_directory / name
        destination_directory = runtime / 'setup/config' if name == 'geometry_review.config.tcl' else private_directory
        destination = destination_directory / name
        if source.is_symlink() or destination.is_symlink():
            raise ValueError('Refusing symlink private setup bundle file')
        if source.exists() and not source.is_file():
            raise ValueError('Private setup input is not a regular file')
        if destination.exists() and not destination.is_file():
            raise ValueError('Private setup destination is not a regular file')
    for name in names:
        source = seed_directory / name
        if not source.exists():
            continue
        destination_directory = runtime / 'setup/config' if name == 'geometry_review.config.tcl' else private_directory
        destination = destination_directory / name
        if source.is_symlink() or not source.is_file() or destination.is_symlink():
            raise ValueError('Refusing non-regular private setup bundle file')
        if destination.exists():
            if not destination.is_file():
                raise ValueError('Private setup destination is not a regular file')
            print('Existing private setup companion retained: ' + name)
            continue
        if not (runtime / 'setup/config').is_dir():
            raise ValueError('Install the flow setup directory first')
        destination_directory.mkdir(mode=0o700, exist_ok=True)
        if destination_directory == private_directory:
            destination_directory.chmod(0o700)
        fd, temporary = tempfile.mkstemp(prefix='.install_', dir=str(destination_directory))
        try:
            with os.fdopen(fd, 'wb') as handle:
                handle.write(source.read_bytes())
            os.link(temporary, str(destination))
        finally:
            os.unlink(temporary)
        if destination_directory == private_directory:
            (destination_directory / '.gitignore').write_text('*\n!.gitignore\n')
        print('Private setup companion installed: ' + name)

def install(runtime, seed):
    runtime = Path(runtime).absolute()
    seed = Path(seed).absolute()
    destination = runtime / 'setup/config/private/geometry_values.tcl'
    for path in (runtime, runtime / 'setup', runtime / 'setup/config', destination.parent, destination):
        if path.is_symlink():
            raise ValueError('Refusing symlink installation path')
    if not destination.exists():
        if seed.is_symlink() or not seed.is_file():
            raise ValueError('Provide a local authorized configuration with --seed')
        if not seed.read_bytes().strip():
            raise ValueError('Private configuration is empty')
    install_setup_bundle(runtime, seed.parent)
    if destination.exists():
        if not destination.is_file():
            raise ValueError('Private configuration is not a regular file')
        print('Private configuration already installed; retained.')
        return
    if seed.is_symlink() or not seed.is_file():
        raise ValueError('Provide a local authorized configuration with --seed; no fixed geometry defaults are supplied')
    data = seed.read_bytes()
    if not data.strip():
        raise ValueError('Private configuration is empty')
    if not (runtime / 'setup/config').is_dir():
        raise ValueError('Install the flow setup directory first')
    destination.parent.mkdir(mode=0o700, exist_ok=True)
    destination.parent.chmod(0o700)
    fd, name = tempfile.mkstemp(prefix='.install_', dir=str(destination.parent))
    try:
        with os.fdopen(fd, 'wb') as handle:
            handle.write(data)
        # Exclusive creation also protects another concurrent installer.
        os.link(name, str(destination))
    finally:
        os.unlink(name)
    (destination.parent / '.gitignore').write_text('*\n!.gitignore\n')
    print('Private configuration installed from local input.')

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--runtime', required=True)
    parser.add_argument('--seed', required=True)
    args = parser.parse_args()
    try:
        install(args.runtime, args.seed)
    except (OSError, ValueError) as exc:
        parser.exit(2, str(exc) + '\n')
