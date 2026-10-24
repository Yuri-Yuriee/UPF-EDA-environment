#!/bin/sh
# Reproduce the declared Runtime environment without executing Tcl or EDA commands.
set -eu
if [ "$#" -lt 2 ] || [ "$#" -gt 3 ]; then
    echo 'Usage: sh build_tech_runtime.sh SOURCE_DIR BUILD_PR [all|apr|verify]' >&2
    exit 2
fi
source_dir=$1
runtime=$2
scope=${3:-all}
case "$scope" in all|apr|verify) ;; *) echo 'Invalid build scope.' >&2; exit 2 ;; esac
case "$source_dir" in /*) ;; *) source_dir=$(pwd)/$source_dir ;; esac
case "$runtime" in /*) ;; *) runtime=$(pwd)/$runtime ;; esac
check_path() {
    checked=$1
    while [ "$checked" != / ] && [ "$checked" != . ]; do
        if [ -L "$checked" ]; then echo "Refusing symlink path: $1" >&2; return 1; fi
        checked=$(dirname -- "$checked")
    done
}
check_path "$source_dir"
check_path "$runtime"
source_dir=$(CDPATH= cd -- "$source_dir" && pwd -P)
[ "$(basename -- "$runtime")" = build_PR ] || { echo 'Expected a build_PR destination.' >&2; exit 2; }
manifest=$source_dir/runtime_sources.list
[ -f "$manifest" ] || { echo 'Missing Runtime source manifest.' >&2; exit 1; }
mkdir -p -- "$runtime"
runtime=$(CDPATH= cd -- "$runtime" && pwd -P)
check_path "$runtime/.tech_runtime_build.lock"
exec 9>"$runtime/.tech_runtime_build.lock"
flock -n 9 || { echo 'Another Runtime build is active.' >&2; exit 1; }
for marker in .innovus_process .verify_process; do
    check_path "$runtime/$marker"
    if [ -f "$runtime/$marker" ] && [ "$(cat "$runtime/$marker")" != TECH_MV ]; then
        echo "Runtime belongs to another process: $marker" >&2
        exit 1
    fi
done
staging=$(mktemp -d "$runtime/.runtime-build.XXXXXX")
trap 'rm -rf -- "$staging"' EXIT HUP INT TERM
selected=$staging/.selected
: >"$selected"
tab=$(printf '\t')
# Validate the entire selected set and stage it before adding any Runtime file.
while IFS="$tab" read -r kind name; do
    case "$kind" in ''|\#*) continue ;; esac
    case "$kind" in copy|adapter) ;; *) echo 'Invalid manifest kind.' >&2; exit 1 ;; esac
    case "$name" in ''|/*|../*|*/../*|*/..|./*|*//*) echo 'Unsafe Runtime manifest path.' >&2; exit 1 ;; esac
    case "$scope:$name" in apr:verify/*) continue ;; verify:verify/*) ;; verify:*) continue ;; esac
    check_path "$source_dir/$name"
    check_path "$runtime/$name"
    [ -f "$source_dir/$name" ] || { echo "Missing source: $name" >&2; exit 1; }
    if [ -e "$runtime/$name" ] && [ ! -f "$runtime/$name" ]; then
        echo "Refusing non-file Runtime entry: $name" >&2
        exit 1
    fi
    destination=$staging/$name
    mkdir -p -- "$(dirname -- "$destination")"
    cp -p -- "$source_dir/$name" "$destination"
    if [ "$kind" = adapter ]; then
        case "$name" in run/*.tcl) ;; *) echo 'Adapter must be a Runtime Tcl entry.' >&2; exit 1 ;; esac
        first_line=$(head -n 1 "$source_dir/$name")
        [ "$first_line" = '# Runtime adapter preserves the historical logical source path.' ] || {
            echo "Canonical Tcl is not an implementation: $name" >&2
            exit 1
        }
        parent=$name
        up=''
        while [ "${parent%/*}" != "$parent" ]; do
            up="$up .."
            parent=${parent%/*}
        done
        {
            printf '# Single implementation: script/PR/TECH_MV/%s\n' "$name"
            printf 'set ::TECH_MV_RUNTIME_ROOT [file normalize [file join [file dirname [info script]]%s]]\n' "$up"
            printf 'source [file normalize [file join $::TECH_MV_RUNTIME_ROOT .. script PR TECH_MV %s]]\n' "$name"
        } >"$destination"
    fi
    printf '%s\n' "$name" >>"$selected"
done <"$manifest"
[ -s "$selected" ] || { echo 'Empty Runtime selection.' >&2; exit 1; }
created=0
retained=0
while IFS= read -r name; do
    if [ -e "$runtime/$name" ]; then
        retained=$((retained + 1))
        continue
    fi
    mkdir -p -- "$(dirname -- "$runtime/$name")"
    # mkdir + copying a regular staged file never creates a link or overwrites local edits.
    cp -p -- "$staging/$name" "$runtime/$name"
    created=$((created + 1))
done <"$selected"
for private_dir in setup/config/private verify/config/private run/tool/ioPADt/private; do
    if [ -d "$runtime/$private_dir" ]; then chmod 700 "$runtime/$private_dir"; fi
done
if [ "$scope" != verify ] && [ ! -e "$runtime/.innovus_process" ]; then
    printf 'TECH_MV\n' >"$runtime/.innovus_process"
fi
if [ "$scope" != apr ] && [ ! -e "$runtime/.verify_process" ]; then
    printf 'TECH_MV\n' >"$runtime/.verify_process"
fi
printf 'TECH_MV Runtime environment: %s new files; %s existing files retained (%s).\n' "$created" "$retained" "$scope"
