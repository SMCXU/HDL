#!/usr/bin/env python3
"""Single-device startup/lifecycle smoke checks. Does NOT certify human input or soak."""
import argparse,json,pathlib,re,subprocess,time
from quality import adb_base
p=argparse.ArgumentParser(description=__doc__);p.add_argument('--serial',required=True);p.add_argument('--out',type=pathlib.Path,required=True);a=p.parse_args()
a.out.mkdir(parents=True,exist_ok=True);adb=adb_base(a.serial);package='com.hdl.ironbreakout';activity=package+'/com.godot.game.GodotAppLauncher'
def run(args):return subprocess.check_output(adb+args,text=True,stderr=subprocess.STDOUT)
def wait_rendered(start):
 deadline=time.monotonic()+12
 while time.monotonic()<deadline:
  try:
   row=run(['shell','run-as',package,'tail','-n','1','files/frame-samples.csv']).strip().split(',')
   if len(row)>4 and float(row[0])>=start and float(row[1])>=.6:return
  except (subprocess.CalledProcessError,ValueError):pass
  time.sleep(.2)
 raise RuntimeError('No fresh rendered telemetry frames; startup check is incomplete')
def wait_home():
 deadline=time.monotonic()+5
 while time.monotonic()<deadline:
  focus=run(['shell','dumpsys','window'])
  match=re.search(r'mCurrentFocus=([^\n]+)',focus)
  if match and package not in match.group(1):return
  time.sleep(.2)
 raise RuntimeError('Home transition did not complete')
def shot(name):
 # Android can report resumed while the launcher transition still covers the surface.
 time.sleep(1.2)
 with (a.out/(name+'.png')).open('wb') as f:subprocess.run(adb+['exec-out','screencap','-p'],stdout=f,check=True)
results={'type':'single-device automated smoke only','cold_launches':[],'background_cycles':[]}
for i in range(3):
 run(['shell','am','force-stop',package]);started=time.time();output=run(['shell','am','start','-W','-n',activity]);wait_rendered(started);results['cold_launches'].append(output)
 shot('cold-menu-'+str(i+1))
# Current handset mapping is derived from wm size rather than silently assuming it.
size=run(['shell','wm','size']);match=re.search(r'(\d+)x(\d+)',size);w,h=map(int,match.groups());w,h=max(w,h),min(w,h)
scale=min(w/960,h/540);xoff=(w-960*scale)/2;yoff=(h-540*scale)/2
run(['shell','input','tap',str(round(xoff+480*scale)),str(round(yoff+300*scale))])
shot('playing-before-background')
for i in range(10):
 run(['shell','input','keyevent','KEYCODE_HOME']);wait_home();started=time.time();output=run(['shell','am','start','-W','-n',activity]);wait_rendered(started);results['background_cycles'].append(output)
shot('paused-after-background')
try:
 pid=run(['shell','pidof',package]).strip()
 (a.out/'process-logcat.txt').write_text(run(['logcat','-d','--pid='+pid,'-t','400']))
except subprocess.CalledProcessError as e:results['logcat_error']=str(e)
run(['shell','am','force-stop',package]);started=time.time();run(['shell','am','start','-W','-n',activity]);wait_rendered(started);shot('ready-menu')
results['note']='Timing returned by am start is launcher timing, not first-interactive frame; screenshots must be viewed. This command uses synthetic single-point taps, not real three-finger touch.'
(a.out/'results.json').write_text(json.dumps(results,indent=2));print('Recorded 3 cold starts and 10 background cycles. Visual review required:',a.out)
