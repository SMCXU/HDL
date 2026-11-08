#!/usr/bin/env python3
"""Pinned, reproducible local Godot/Android workflow (Python standard library)."""
import argparse,os,pathlib,subprocess,sys,urllib.request,zipfile,shutil,re,json,hashlib,datetime,functools
ROOT=pathlib.Path(__file__).resolve().parents[1]
VERSION='4.7.2'
WORK=ROOT/'work'
WORK.mkdir(exist_ok=True)
(WORK/'.gdignore').touch()
def run(args,**kwargs):
    print('+', ' '.join(str(x) for x in args),flush=True)
    return subprocess.run([str(x) for x in args],cwd=ROOT,check=True,**kwargs)
@functools.lru_cache(maxsize=1)
def engine():
    candidate=os.environ.get('GODOT_BIN') or str(WORK/'engine/Godot.app/Contents/MacOS/Godot')
    if not pathlib.Path(candidate).exists(): raise RuntimeError('Run python3 tools/manage.py bootstrap, or set GODOT_BIN to Godot 4.7.2.')
    actual=subprocess.check_output([candidate,'--version'],text=True).strip()
    if not actual.startswith(VERSION+'.'): raise RuntimeError(f'Expected Godot {VERSION}, got {actual}')
    return candidate

def runtime_manifest():
    files=[]
    for name in ['scripts','scenes','resources','assets']:
        files.extend(p for p in (ROOT/name).rglob('*') if p.is_file() and p.suffix not in ['.import','.pyc'])
    files.extend(ROOT/n for n in ['project.godot','export_presets.cfg'])
    return {str(p.relative_to(ROOT)):hashlib.sha256(p.read_bytes()).hexdigest() for p in files}

def download(slug,destination):
    url=f'https://downloads.godotengine.org/?version={VERSION}&flavor=stable&slug={slug}'
    run(['curl','--fail','-L','--retry','3','--connect-timeout','20','-o',destination,url])
def bootstrap():
    WORK.mkdir(exist_ok=True)
    if not (WORK/'engine/Godot.app').exists():
        if sys.platform!='darwin': raise RuntimeError('Install Godot 4.7.2 for your OS and set GODOT_BIN; automatic editor download currently supports macOS only.')
        archive=WORK/'godot-stable.zip'
        if not archive.exists(): download('macos.universal.zip',archive)
        with zipfile.ZipFile(archive) as z: z.extractall(WORK/'engine')
        exe=WORK/'engine/Godot.app/Contents/MacOS/Godot';exe.chmod(0o755)
    if not (WORK/'android_debug.apk').exists():
        archive=WORK/'templates.tpz'
        if not archive.exists(): download('export_templates.tpz',archive)
        with zipfile.ZipFile(archive) as z:
            for name in ['android_debug.apk','android_release.apk']:
                (WORK/name).write_bytes(z.read('templates/'+name))
    print('Godot editor and Android templates ready.')
def environment():
    env=os.environ.copy()
    env['ANDROID_SDK_ROOT']=env.get('ANDROID_SDK_ROOT',str(pathlib.Path.home()/'Library/Android/sdk'))
    if not pathlib.Path(env['ANDROID_SDK_ROOT'],'platform-tools/adb').exists(): raise RuntimeError('Set ANDROID_SDK_ROOT to your installed Android SDK.')
    if not env.get('HDL_JAVA_PATH'):
        env['HDL_JAVA_PATH']=subprocess.check_output(['/usr/libexec/java_home','-v','17'],text=True).strip()
    return env
def build():
    env=environment(); (ROOT/'builds').mkdir(exist_ok=True);WORK.mkdir(exist_ok=True)
    before=runtime_manifest()
    if not (WORK/'android_debug.apk').exists(): bootstrap()
    key=WORK/'debug.keystore'
    if not key.exists():
        run([pathlib.Path(env['HDL_JAVA_PATH'])/'bin/keytool','-genkeypair','-keystore',key,'-storepass','android','-alias','androiddebugkey','-keypass','android','-dname','CN=Android Debug,O=HDL,C=CN','-keyalg','RSA','-keysize','2048','-validity','10000','-noprompt'])
    run([engine(),'--headless','--path',ROOT,'--editor','--import','--quit'],env=env)
    run([engine(),'--headless','--path',ROOT,'--editor','--quit-after','10','--script','tools/configure_export.gd'],env=env)
    pending=ROOT/'builds/iron-breakout-pending.apk'
    pending.unlink(missing_ok=True)
    run([engine(),'--headless','--path',ROOT,'--export-debug','Android',pending],env=env)
    if not pending.exists() or not zipfile.is_zipfile(pending): raise RuntimeError('Export did not produce a valid new APK; previous build was preserved.')
    with zipfile.ZipFile(pending) as z:
        if 'AndroidManifest.xml' not in z.namelist(): raise RuntimeError('APK manifest missing.')
    after=runtime_manifest()
    if any(after.get(path)!=digest for path,digest in before.items() if not path.endswith('.uid')):
        raise RuntimeError('Runtime sources changed during build; rebuild a consistent version.')
    pending.replace(ROOT/'builds/iron-breakout-debug.apk')
    artifact=ROOT/'builds/iron-breakout-debug.apk'
    metadata={'engine_version':subprocess.check_output([engine(),'--version'],text=True).strip(),'built_utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'apk_sha256':hashlib.sha256(artifact.read_bytes()).hexdigest(),'runtime_sources':after}
    (ROOT/'builds/iron-breakout-debug.build.json').write_text(json.dumps(metadata,indent=2))
def install(serial):
    env=environment();adb=pathlib.Path(env['ANDROID_SDK_ROOT'])/'platform-tools/adb'
    cmd=[adb]+(['-s',serial] if serial else [])
    run(cmd+['install','--no-incremental','-r',ROOT/'builds/iron-breakout-debug.apk'])
    run(cmd+['shell','am','start','-W','-n','com.hdl.ironbreakout/com.godot.game.GodotAppLauncher'])
def test():
    run([engine(),'--headless','--path',ROOT,'--editor','--import','--quit'])
    result=subprocess.run([engine(),'--headless','--path',str(ROOT),'--script','tests/run_tests.gd'],cwd=ROOT,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
    print(result.stdout)
    if result.returncode or 'SCRIPT ERROR' in result.stdout or not re.search(r'RESULT (\d+)/\1 passed',result.stdout): raise RuntimeError('Tests failed; inspect output.')
if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action',choices=['bootstrap','run','test','build','install'])
    parser.add_argument('--serial')
    args=parser.parse_args()
    try:
        if args.action=='bootstrap': bootstrap()
        elif args.action=='run': run([engine(),'--path',ROOT])
        elif args.action=='test': test()
        elif args.action=='build': build()
        else: install(args.serial)
    except (RuntimeError,subprocess.CalledProcessError) as e:
        print('ERROR:',e,file=sys.stderr);sys.exit(1)
