#!/usr/bin/env python3
"""Reproducible snapshots, desktop visual checks, and explicitly labeled telemetry reports."""
import argparse,csv,io,hashlib,json,math,os,pathlib,subprocess,tarfile,time
from manage import ROOT,WORK,engine,environment

def summarize(path,label):
    data=path.read_text()
    if not data.endswith('\n'):data=data[:data.rfind('\n')+1]
    all_rows=list(csv.DictReader(io.StringIO(data)))
    candidates=[r for r in all_rows if r['mode']=='playing']
    rows=[r for r in candidates if r.get('interval_valid','true').lower()=='true']
    if not rows: raise RuntimeError('No valid playing callback intervals; not a gameplay result.')
    def stats(items):
        frames=sorted(float(r['frame_ms']) for r in items)
        if not frames:return None
        def percentile(q):return frames[max(0,math.ceil(q*len(frames))-1)]
        return {'playing_frames':len(frames),'sampled_playing_s':sum(frames)/1000,'median_frame_ms':percentile(.5),'p95_frame_ms':percentile(.95),'p99_frame_ms':percentile(.99),'frames_ge_100ms':sum(v>=100 for v in frames),'memory_static_peak_bytes':max(int(r['memory_static_bytes']) for r in items)}
    first=float(rows[0]['elapsed_s']);last=float(rows[-1]['elapsed_s'])
    data={'validation_type':label,'source':str(path),'level_ids':sorted(set(r.get('level_id','legacy_unclassified') for r in rows)),'interaction_sources':sorted(set(r.get('interaction_source','legacy_unclassified') for r in rows)),'wall_span_s':last-first,'excluded_invalid_interval_rows':len(candidates)-len(rows),**stats(rows)}
    data['first_5min']=stats([r for r in rows if float(r['elapsed_s'])<first+300])
    data['last_5min']=stats([r for r in rows if float(r['elapsed_s'])>last-300]) if last-first>=600 else None
    data['note']='Callback intervals are not isolated GPU/presentation times. Static memory excludes Android PSS/GPU. First/last windows require documented coverage; summary never certifies human input or final 20-minute acceptance. Legacy records lack interval-valid flags.'
    out=path.with_suffix('.summary.json');out.write_text(json.dumps(data,indent=2));print(json.dumps(data,indent=2))

def snapshot(destination):
    destination.mkdir(parents=True,exist_ok=True)
    sources=[]
    for folder in ['scripts','scenes','resources','assets','source_assets','tools','tests','docs']:
        sources += [p for p in (ROOT/folder).rglob('*') if p.is_file() and not any(x in p.parts for x in ['__pycache__','.git','.godot']) and p.suffix not in ['.pyc','.import','.keystore','.jks','.pem','.key']]
    sources += [ROOT/n for n in ['project.godot','export_presets.cfg','README.md','AGENTS.md']]
    manifest={str(p.relative_to(ROOT)):hashlib.sha256(p.read_bytes()).hexdigest() for p in sources}
    with tarfile.open(destination/'source.tar.gz','w:gz') as archive:
        for p in sources:archive.add(p,arcname=p.relative_to(ROOT))
    (destination/'manifest.json').write_text(json.dumps(manifest,indent=2))
    print('Snapshot:',len(sources),'source files. No work/ or signing files.')

def adb_base(serial):
    return [str(pathlib.Path(environment()['ANDROID_SDK_ROOT'])/'platform-tools/adb'),'-s',serial]

def device_capture(serial,out):
    out.mkdir(parents=True,exist_ok=True);cmd=adb_base(serial)
    info={}
    for key,args in {'model':['shell','getprop','ro.product.model'],'android':['shell','getprop','ro.build.version.release'],'resolution':['shell','wm','size'],'battery':['shell','dumpsys','battery']}.items():
        info[key]=subprocess.check_output(cmd+args,text=True)
    info['recorded_utc']=time.strftime('%Y-%m-%dT%H:%M:%SZ',time.gmtime())
    info['validation_type']='single-device capture; interaction source must be recorded separately'
    (out/'device.json').write_text(json.dumps(info,indent=2))
    with (out/'frame-samples.csv').open('wb') as f:
        subprocess.run(cmd+['exec-out','run-as','com.hdl.ironbreakout','cat','files/frame-samples.csv'],stdout=f,check=True)
    with (out/'device.png').open('wb') as f:subprocess.run(cmd+['exec-out','screencap','-p'],stdout=f,check=True)
    for name in ['run-results-v3.csv','run-results-v2.csv','run-results.csv']:
        result=subprocess.run(cmd+['exec-out','run-as','com.hdl.ironbreakout','cat','files/'+name],capture_output=True)
        if result.returncode==0: (out/name).write_bytes(result.stdout)
    with (out/'android-meminfo.txt').open('w') as f:subprocess.run(cmd+['shell','dumpsys','meminfo','com.hdl.ironbreakout'],stdout=f,check=True)
    summarize(out/'frame-samples.csv','single-device capture; human play not automatically certified')

if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__);sub=p.add_subparsers(dest='action',required=True)
    s=sub.add_parser('snapshot');s.add_argument('--out',type=pathlib.Path,required=True)
    s=sub.add_parser('summarize');s.add_argument('csv',type=pathlib.Path);s.add_argument('--label',required=True)
    s=sub.add_parser('capture');s.add_argument('--out',default='work/polish/visual');s.add_argument('--resolution',default='1152x648');s.add_argument('--scenario',choices=['normal','dense','boss','poses','animation','sector2','sector3','settings','dead','transitions','panorama','l2river','l2climb','l2roof','l2boss','l3start','l3ferry','l3rock','l3boss','selection'],default='normal')
    s=sub.add_parser('device-capture');s.add_argument('--serial',required=True);s.add_argument('--out',type=pathlib.Path,required=True)
    a=p.parse_args()
    if a.action=='snapshot':snapshot(a.out)
    elif a.action=='summarize':summarize(a.csv,a.label)
    elif a.action=='device-capture':device_capture(a.serial,a.out)
    else:
        subprocess.run([engine(),'--resolution',a.resolution,'--path',str(ROOT),'--script','res://tools/visual_check.gd','--','--out='+a.out,'--scenario='+a.scenario],cwd=ROOT,check=True)
