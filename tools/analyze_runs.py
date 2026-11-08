#!/usr/bin/env python3
"""Report full successful run timings without treating deaths/checkpoint retries as completion."""
import argparse,csv,json,pathlib,statistics
p=argparse.ArgumentParser(description=__doc__);p.add_argument('csv',type=pathlib.Path);p.add_argument('--level',choices=['iron_factory','spillway'],default='iron_factory');a=p.parse_args()
rows=list(csv.DictReader(a.csv.open()))
valid=[float(r['elapsed_s']) for r in rows if r['result']=='won' and r['checkpoint'].lower()=='false' and r.get('interaction_source')=='human_verified' and r.get('invulnerable','true').lower()=='false' and r.get('debug_run','false').lower()=='false' and r.get('level_id','iron_factory')==a.level]
report={'all_attempts':len(rows),'full_successes':len(valid),'successful_times_s':valid,'median_success_s':statistics.median(valid) if valid else None,'level_id':a.level,'target_s':[240,360] if a.level=='spillway' else [180,300],'sample_requirement_met':len(valid)>=3,'timing_target_met':len(valid)>=3 and (240 if a.level=='spillway' else 180)<=statistics.median(valid)<=(360 if a.level=='spillway' else 300),'qualification':'Result records alone do not certify that a human performed the run; interaction source must be documented.'}
print(json.dumps(report,indent=2))
