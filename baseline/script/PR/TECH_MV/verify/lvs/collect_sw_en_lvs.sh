#!/usr/bin/env bash
# Read-only targeted SW LVS follow-up. Run from verify/lvs; no EDA tools invoked.
set -euo pipefail
umask 077
ROOT=$(pwd -P)
TS=$(date +%Y%m%d_%H%M%S)
OUT="$ROOT/rpt/sw_en/SW_EN_LVS_STAGE2_$TS"
mkdir -p "$OUT"/{meta,source,layout,discrepancies}
trap 'echo "Collection interrupted: $OUT" >&2' ERR
export OUT ROOT
python3 - <<'PY'
import os,re,hashlib,pathlib,datetime,json
root=pathlib.Path(os.environ['ROOT']); out=pathlib.Path(os.environ['OUT'])
patterns=re.compile(r'(?:psoPSI_PD_(?:CPU|WDT)_EnNet|CPU_SW_OUT|WDT_SW_OUT|NSLEEPIN|NSLEEPOUT|CPU_ON|WDT_ON)',re.I)
report=root/'output/lvs.rep'
if not report.is_file():
    report=root/'lvs.rep'
if not report.is_file():
    raise SystemExit('ERROR: LVS report missing; expected output/lvs.rep or lvs.rep')
# Preserve first few discrepant net blocks; avoids enormous VDD block.
blocks=[]; in_section=False; current=[]; seen=0; hit=[]
with report.open(errors='replace') as f:
    for line in f:
        if 'INCORRECT NETS' in line: in_section=True
        if not in_section: continue
        if re.match(r'^\s*\d+\s+Net\s+\S+\s+',line):
            if current: blocks.append(current)
            seen+=1; current=[line]
            if seen>=31: break
        elif current and len(current)<160:
            current.append(line)
if current: blocks.append(current)
with (out/'discrepancies/first_30_nets.txt').open('w') as f:
    for b in blocks: f.writelines(b); f.write('\n'+'-'*80+'\n')
# Focus on first 30 SW enable source nets in LVS report; exclude huge main PG net.
names=[]
for b in blocks:
    h=b[0]; tokens=h.split()
    if len(tokens)>=4 and 'EnNet' in h:
        names.append(tokens[-1])
names=list(dict.fromkeys(names))[:30]
(out/'meta/target_nets.txt').write_text('\n'.join(names)+'\n')
# Search named nets and HDR instances within netlist, bounded by per-file lines.
# SPICE is line-oriented; keep 1 statement + continuations for matching records.
files=[('source','CHIP.spi',root/'CHIP.spi'),('layout','layout.spi',(root/'temp/layout.spi' if (root/'temp/layout.spi').is_file() else (root/'layout.spi' if (root/'layout.spi').is_file() else root/'build/extracted/layout.spi')))]
summary=[]
for side,label,path in files:
    if not path.is_file():
        summary.append({'side':side,'path':str(path),'missing':True});continue
    h=hashlib.sha256(); count=0; selected=0; nbytes=0
    target_re=re.compile('|'.join(map(re.escape,names)),re.I) if names else None
    dest=out/side/(label+'.target_statements.txt')
    with path.open('rb') as binary, dest.open('w') as dst:
        current=[]; matching=False
        def flush():
            global selected
            if not current:return
            joined=''.join(current)
            if patterns.search(joined) or (target_re and target_re.search(joined)):
                # Cap extracted text at 3500 statements / file; matching lines are not entire netlist.
                if selected<3500:
                    dst.write(f'### statement line {current_start}\n')
                    dst.write(joined[:3000]+'\n')
                    selected+=1
        current_start=1
        for lineno,raw in enumerate(binary,1):
            h.update(raw); nbytes+=len(raw);count=lineno
            line=raw.decode('utf-8','replace')
            if line.lstrip().startswith('+') and current:
                if len(current)<15:current.append(line)
            else:
                flush(); current=[line];current_start=lineno
        flush()
    st=path.stat()
    summary.append({'side':side,'path':str(path),'bytes':nbytes,'lines':count,'sha256':h.hexdigest(), 'mtime':datetime.datetime.fromtimestamp(st.st_mtime).isoformat(),'selected_statements':selected,'truncated_to_first':3500})
(out/'meta/netlist_metadata.json').write_text(json.dumps(summary,indent=2))
# Collect concise SW discrepancy observations from entire report (bounded lines).
with report.open(errors='replace') as src,(out/'discrepancies/sw_matches.txt').open('w') as dest:
    total=0
    for i,line in enumerate(src,1):
        if re.search(r'psoPSI_PD_(CPU|WDT)_EnNet|NSLEEPIN|NSLEEPOUT|arbitrarily|Different numbers of nets|Connectivity errors',line,re.I):
            dest.write(f'{i}: {line[:500]}');total+=1
            if total>=2500:break
(out/'meta/README.txt').write_text('Read-only SW EN LVS stage 2. No PDK, GDS, databases, or full netlists copied.\n'
  +'Inspect output before upload: sensitive instance names, coordinates and circuit connectivity may be present.\n'
  +'Report: '+str(report)+'\n'
  +f'Target nets: {len(names)}\n')
PY
mkdir -p "$ROOT/build/packages"
ARCHIVE="$ROOT/build/packages/$(basename "$OUT").tar.gz"
tar -czf "$ARCHIVE" -C "$(dirname "$OUT")" "$(basename "$OUT")"
chmod 600 "$ARCHIVE"
echo "Created: $ARCHIVE"
du -h "$ARCHIVE"
