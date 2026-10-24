import re,csv,collections,pathlib
import json, os
verify_root = pathlib.Path(__file__).resolve().parents[3]
_verify_rules_file = pathlib.Path(os.environ.get("VERIFY_DEBUG_RULES_FILE", str(verify_root / "config/private/debug.rules.json")))
if not _verify_rules_file.is_file():
    raise RuntimeError("Required private Verify debug.rules.json is missing")
VERIFY_DEBUG_RULES = json.loads(_verify_rules_file.read_text())

root=pathlib.Path(__file__).parent
src=pathlib.Path(VERIFY_DEBUG_RULES["source_statement_file"])
rows=[]
for block in src.read_text(errors='replace').split('### statement line '):
    stmt=' '.join(line.strip().lstrip('+').strip() for line in block.splitlines()[1:])
    m=re.search(VERIFY_DEBUG_RULES["switch_master_pattern"],stmt)
    if not m: continue
    pin=dict(re.findall(VERIFY_DEBUG_RULES["switch_pin_pair_pattern"],m.group(2)))
    if VERIFY_DEBUG_RULES["switch_roles"]["input"] in pin and VERIFY_DEBUG_RULES["switch_roles"]["output"] in pin: rows.append({'spi_inst':m.group(1),'innovus_candidate':m.group(1)[1:],'en_in':pin[VERIFY_DEBUG_RULES["switch_roles"]["input"]],'en_out':pin[VERIFY_DEBUG_RULES["switch_roles"]["output"]],'tvdd':pin.get(VERIFY_DEBUG_RULES["switch_roles"]["switched_power"],''),'vdd':pin.get(VERIFY_DEBUG_RULES["switch_roles"]["primary_power"],'')})
ins=collections.defaultdict(list); outs=collections.defaultdict(list)
for r in rows: ins[r['en_in']].append(r);outs[r['en_out']].append(r)
starts=[r for r in rows if r['en_in'] not in outs]
chains=[];seen=set()
for start in starts:
    seq=[]; cur=start
    while cur and cur['spi_inst'] not in seen:
        seq.append(cur);seen.add(cur['spi_inst'])
        next_=ins.get(cur['en_out'],[])
        cur=next_[0] if len(next_)==1 else None
    chains.append(seq)
chains.sort(key=lambda ch:(-len(ch),ch[0]['spi_inst']))
with (root/'source_sw_chain.tsv').open('w') as f:
    writer=csv.DictWriter(f,fieldnames=['chain_id','step','chain_length','spi_inst','innovus_candidate','en_in','en_out','tvdd','vdd'],delimiter='\t');writer.writeheader()
    for c,ch in enumerate(chains,1):
        for i,r in enumerate(ch):writer.writerow({'chain_id':f'C{c:02d}','step':i,'chain_length':len(ch),**r})
with (root/'chain_summary.tsv').open('w') as f:
    w=csv.writer(f,delimiter='\t');w.writerow(['chain_id','length','first_inst','start_net','last_inst','end_net']);
    for c,ch in enumerate(chains,1):w.writerow([f'C{c:02d}',len(ch),ch[0]['innovus_candidate'],ch[0]['en_in'],ch[-1]['innovus_candidate'],ch[-1]['en_out']])
print('SW',len(rows),'chains',len(chains),'lengths',dict(collections.Counter(len(c) for c in chains)),'unassigned',len(rows)-len(seen))
