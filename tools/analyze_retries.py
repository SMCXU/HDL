#!/usr/bin/env python3
"""Analyze separately labeled automated on-device death/retry stability samples."""
import argparse,json,pathlib
p=argparse.ArgumentParser(description=__doc__);p.add_argument('status',type=pathlib.Path);p.add_argument('--warmup',type=int,default=3);a=p.parse_args()
status=json.loads(a.status.read_text());rows=status.get('retry_samples',[])[a.warmup:]
groups=[]
for level_id,checkpoint in sorted(set((r.get('level_id','legacy'),r['checkpoint']) for r in rows)):
 samples=[r for r in rows if r['checkpoint']==checkpoint and r.get('level_id','legacy')==level_id]
 if not samples:continue
 baseline=samples[0]['memory_static_bytes'];last=samples[-1]['memory_static_bytes'];peak=max(r['memory_static_bytes'] for r in samples)
 groups.append({'level_id':level_id,'checkpoint':checkpoint,'samples':len(samples),'baseline_bytes':baseline,'last_bytes':last,'peak_bytes':peak,'last_growth_bytes':last-baseline,'budget_bytes':max(baseline*.1,20*1024*1024),'within_static_growth_budget':peak-baseline<=max(baseline*.1,20*1024*1024),'monotonically_increasing':len(samples)>1 and all(b['memory_static_bytes']>a['memory_static_bytes'] for a,b in zip(samples,samples[1:]))})
report={'validation_type':'single-device automated '+status.get('test_mode','retries')+'; not manual input or long soak','test_mode':status.get('test_mode','retries'),'result':status['result'],'completed_cycles':status.get('retry_count',0),'warmup_samples_excluded':a.warmup,'stable_samples':len(rows),'groups':groups,'child_node_counts':sorted(set(r['children'] for r in rows)),'audio_voice_node_counts':sorted(set(r['audio_voice_nodes'] for r in rows)),'requirement_20_stable_samples_observed':status['result']=='completed' and status.get('retry_count',0)>=20 and len(rows)>=20,'note':'Static-memory bounds alone do not establish Android PSS/GPU stability or absence of leaks. Compare device-metrics.json separately.'}
out=a.status.with_name('retry-summary.json');out.write_text(json.dumps(report,indent=2));print(json.dumps(report,indent=2))
