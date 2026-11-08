#!/usr/bin/env python3
"""Opt-in debug input replay: single-device rendering evidence, never human acceptance."""
import argparse,json,pathlib,subprocess,time,uuid
from quality import adb_base,device_capture
p=argparse.ArgumentParser(description=__doc__)
p.add_argument('--serial',required=True);p.add_argument('--seconds',type=int,default=180);p.add_argument('--out',type=pathlib.Path,required=True)
p.add_argument('--mode',choices=['route','retries','switches'],default='route');p.add_argument('--retry-count',type=int,default=23)
p.add_argument('--level',choices=['iron_factory','spillway','redrock'],default='iron_factory')
p.add_argument("--weapon",choices=["rifle","machine","spread","laser","fireball","cycle"]);p.add_argument("--rapid",action="store_true")
a=p.parse_args();a.out.mkdir(parents=True,exist_ok=True)
if not 10<=a.seconds<=1200: p.error('seconds must be 10..1200')
cmd=adb_base(a.serial);package='com.hdl.ironbreakout'
def run(args,**kw):return subprocess.run(cmd+args,check=True,**kw)
from manage import ROOT
metadata=ROOT/'builds/iron-breakout-debug.build.json'
if metadata.exists():(a.out/'build-identity.json').write_bytes(metadata.read_bytes())
config={'duration_s':a.seconds,'invulnerable':True,'run_id':uuid.uuid4().hex,'mode':a.mode,'retry_count':a.retry_count,'level_id':a.level}
if a.weapon:config['weapon_id']=a.weapon;config['rapid']=a.rapid
(a.out/'replay-config.json').write_text(json.dumps(config,indent=2))
# Backup an existing opt-in configuration and restore it on every exit.
old=subprocess.run(cmd+['exec-out','run-as',package,'cat','files/qa-replay.json'],capture_output=True)
try:
 valid_old_config=old.returncode==0 and isinstance(json.loads(old.stdout),dict)
except (ValueError,UnicodeDecodeError):valid_old_config=False
had_flag=subprocess.run(cmd+['shell','run-as',package,'test','-f','files/telemetry.flag']).returncode==0
metrics=[];next_metric=0
try:
 run(['shell','am','force-stop',package])
 run(['shell','run-as',package,'tee','files/qa-replay.json'],input=json.dumps(config).encode(),stdout=subprocess.DEVNULL)
 run(['shell','run-as',package,'touch','files/telemetry.flag'])
 run(['shell','am','start','-W','-n',package+'/com.godot.game.GodotAppLauncher'],stdout=subprocess.DEVNULL)
 deadline=time.monotonic()+a.seconds*2+90
 while time.monotonic()<deadline:
  time.sleep(5)
  result=subprocess.run(cmd+['exec-out','run-as',package,'cat','files/qa-replay-status.json'],capture_output=True)
  if result.returncode:continue
  try:status=json.loads(result.stdout)
  except (ValueError,UnicodeDecodeError):continue
  if not isinstance(status,dict):continue
  if status.get('run_id')!=config['run_id']:continue
  (a.out/'replay-status.json').write_text(json.dumps(status,indent=2))
  if time.monotonic()>=next_metric:
   metric={'elapsed_s':status['elapsed_s'],'wall_monotonic_s':time.monotonic()}
   for key,args in {'meminfo':['shell','dumpsys','meminfo',package],'battery':['shell','dumpsys','battery'],'thermal':['shell','dumpsys','thermalservice']}.items():
    metric[key]=subprocess.run(cmd+args,capture_output=True,text=True).stdout
   metrics.append(metric);(a.out/'device-metrics.json').write_text(json.dumps(metrics,indent=2));next_metric=time.monotonic()+15
  print(json.dumps({k:v for k,v in status.items() if k!='retry_samples'}),flush=True)
  if status['result'] in ['completed','cancelled_by_human_input','cancelled_by_pause']:break
 else:raise RuntimeError('Replay timed out, possibly device locked or game paused; no acceptance claimed.')
 device_capture(a.serial,a.out)
finally:
 if not had_flag:run(['shell','run-as',package,'rm','-f','files/telemetry.flag'])
 if valid_old_config:run(['shell','run-as',package,'tee','files/qa-replay.json'],input=old.stdout,stdout=subprocess.DEVNULL)
 else:run(['shell','run-as',package,'rm','-f','files/qa-replay.json'])
