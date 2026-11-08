#!/usr/bin/env python3
"""Single-point Android navigation checks. Does not certify physical multi-touch."""
import argparse,json,pathlib,re,subprocess,time
from quality import adb_base
p=argparse.ArgumentParser(description=__doc__);p.add_argument('--serial',required=True);p.add_argument('--out',type=pathlib.Path,required=True);a=p.parse_args();a.out.mkdir(parents=True,exist_ok=True)
cmd=adb_base(a.serial);package='com.hdl.ironbreakout';activity=package+'/com.godot.game.GodotAppLauncher';checks=[]
def run(args,**kw):return subprocess.run(cmd+args,check=True,**kw)
def read(name):return subprocess.run(cmd+['exec-out','run-as',package,'cat','files/'+name],capture_output=True)
settings=read('settings.cfg');had_flag=subprocess.run(cmd+['shell','run-as',package,'test','-f','files/telemetry.flag']).returncode==0
size=subprocess.check_output(cmd+['shell','wm','size'],text=True);w,h=map(int,re.search(r'(\d+)x(\d+)',size).groups());w,h=max(w,h),min(w,h);scale=min(w/960,h/540);ox=(w-960*scale)/2;oy=(h-540*scale)/2
def tap(x,y):run(['shell','input','tap',str(round(ox+x*scale)),str(round(oy+y*scale))])
def wait_mode(mode,since):
 deadline=time.monotonic()+12
 while time.monotonic()<deadline:
  result=read('frame-samples.csv')
  if result.returncode==0:
   lines=result.stdout.decode().strip().splitlines()
   if len(lines)>1:
    row=lines[-1].split(',')
    if len(row)>=5 and row[0].replace('.','',1).isdigit() and float(row[0])>=since and row[4]==mode:
     focus=subprocess.check_output(cmd+['shell','dumpsys','window'],text=True)
     current=re.search(r'mCurrentFocus=([^\n]+)',focus)
     if current and package in current.group(1):return
  time.sleep(.2)
 raise RuntimeError('No fresh mode evidence for '+mode)
def verify(name,mode,action):
 started=time.time();action();wait_mode(mode,started);time.sleep(1.2)
 with (a.out/(name+'.png')).open('wb') as f:run(['exec-out','screencap','-p'],stdout=f)
 checks.append({'name':name,'mode':mode,'result':'fresh telemetry observed; screenshot review required'})
def launch():
 run(['shell','am','force-stop',package]);run(['shell','am','start','-W','-n',activity],stdout=subprocess.DEVNULL)
def back():run(['shell','input','keyevent','KEYCODE_BACK'])
try:
 run(['shell','run-as',package,'touch','files/telemetry.flag'])
 verify('01-menu','menu',launch)
 verify('02-background-tap','menu',lambda:tap(50,300))
 verify('03-settings','settings',lambda:tap(480,375))
 verify('04-settings-back','menu',back)
 verify('05-playing','playing',lambda:tap(480,300))
 verify('06-back-paused','paused',back)
 verify('07-paused-settings','settings',lambda:tap(480,375))
 verify('08-settings-back-paused','paused',back)
 verify('09-back-resumed','playing',back)
 # Isolate persistence from idle combat damage after resume evidence.
 verify('10-isolated-menu','menu',launch)
 verify('11-low-effects-settings','settings',lambda:tap(480,375))
 tap(650,415);time.sleep(.4) # low effects row; settings save immediately
 changed=read('settings.cfg')
 if changed.returncode:raise RuntimeError('Cannot read saved settings')
 (a.out/'changed-settings.cfg').write_bytes(changed.stdout)
 verify('12-restart-menu','menu',launch)
 if read('settings.cfg').stdout!=changed.stdout:raise RuntimeError('Settings changed across restart')
 verify('13-restored-settings-screen','settings',lambda:tap(480,375))
 checks.append({'name':'settings survive process restart','result':'exact saved bytes preserved; screenshot review required'})
finally:
 run(['shell','am','force-stop',package])
 if settings.returncode==0:run(['shell','run-as',package,'tee','files/settings.cfg'],input=settings.stdout,stdout=subprocess.DEVNULL)
 if not had_flag:run(['shell','run-as',package,'rm','-f','files/telemetry.flag'])
 run(['shell','am','start','-W','-n',activity],stdout=subprocess.DEVNULL)
 (a.out/'results.json').write_text(json.dumps({'validation_type':'single-device synthetic navigation, not human touch acceptance','checks':checks,'settings_restored':settings.returncode==0},indent=2))
print('Navigation checks completed; original settings restored; visual review required.',flush=True)
