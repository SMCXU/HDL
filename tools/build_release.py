#!/usr/bin/env python3
"""Non-debug Android release, signed with the existing internal-test certificate.
Does not generate a publishing key, replace debug artifacts, or install anything.
"""
import datetime,hashlib,json,os,pathlib,re,subprocess,zipfile
from manage import ROOT,WORK,engine,environment,runtime_manifest

def run(args,env=None):
    print('+',' '.join(map(str,args)),flush=True)
    subprocess.run(list(map(str,args)),cwd=ROOT,env=env,check=True)

def main():
    env=environment();out=ROOT/'builds';out.mkdir(exist_ok=True)
    presets=ROOT/'export_presets.cfg';original=presets.read_bytes();source=original.decode()
    version=re.search(r'^version/name="([\w.\-]+)"',source,re.M).group(1)
    job=WORK/('release-'+version);job.mkdir(exist_ok=True)
    before=runtime_manifest()
    debug=out/'iron-breakout-debug.apk'
    debug_hash=hashlib.sha256(debug.read_bytes()).hexdigest() if debug.exists() else None
    def setting(name):
        match=re.search(r'^'+re.escape(name)+r'=(.*)$',source,re.M)
        if not match:raise RuntimeError('Missing configured '+name)
        return json.loads(match.group(1))
    key=setting('keystore/debug').replace('res://',str(ROOT)+'/')
    if not pathlib.Path(key).is_file():raise RuntimeError('Existing internal signing certificate not found')
    if not (WORK/'android_release.apk').is_file():raise RuntimeError('Pinned Android release template missing; run bootstrap')
    unsigned=job/'unsigned.apk';pending=job/'signed.apk'
    sdk=pathlib.Path(env['ANDROID_SDK_ROOT'])/'build-tools'
    versions=[p for p in sdk.iterdir() if re.fullmatch(r'\d+\.\d+\.\d+',p.name)]
    build_tools=max(versions,key=lambda p:tuple(map(int,p.name.split('.'))))
    signer=build_tools/'apksigner';aapt=build_tools/'aapt2'
    (job/'export_presets.original.cfg').write_bytes(original)
    try:
        temporary=source.replace('package/signed=true','package/signed=false')
        if temporary==source:raise RuntimeError('Expected signed export preset')
        presets.write_text(temporary)
        run([engine(),'--headless','--path',ROOT,'--editor','--import','--quit'],env)
        run([engine(),'--headless','--path',ROOT,'--editor','--quit-after','10','--script','tools/configure_export.gd'],env)
        run([engine(),'--headless','--path',ROOT,'--export-release','Android',unsigned],env)
    finally:
        presets.write_bytes(original)
    sign_env=env.copy()
    sign_env['HDL_INTERNAL_STORE_PASS']=setting('keystore/debug_password')
    sign_env['HDL_INTERNAL_KEY_PASS']=setting('keystore/debug_password')
    run([signer,'sign','--ks',key,'--ks-key-alias',setting('keystore/debug_user'),'--ks-pass','env:HDL_INTERNAL_STORE_PASS','--key-pass','env:HDL_INTERNAL_KEY_PASS','--out',pending,unsigned],sign_env)
    verified=subprocess.check_output([str(signer),'verify','--verbose','--print-certs',str(pending)],text=True,env=env)
    (job/'signature.txt').write_text(verified)
    manifest=subprocess.check_output([str(aapt),'dump','xmltree','--file','AndroidManifest.xml',str(pending)],text=True,env=env)
    (job/'manifest.txt').write_text(manifest)
    debug_lines=[l.strip() for l in manifest.splitlines() if 'android:debuggable' in l]
    if any(not l.endswith('0x0') for l in debug_lines):raise RuntimeError('Release manifest is debuggable')
    def digest_cert(apk):
        text=subprocess.check_output([str(signer),'verify','--print-certs',str(apk)],text=True,env=env)
        return re.search(r'Signer #1 certificate SHA-256 digest: (\w+)',text).group(1)
    certificate=digest_cert(pending)
    same_cert=debug.exists() and certificate==digest_cert(debug)
    lib='lib/arm64-v8a/libgodot_android.so'
    with zipfile.ZipFile(pending) as z,zipfile.ZipFile(WORK/'android_release.apk') as release,zipfile.ZipFile(WORK/'android_debug.apk') as debug_template:
        lib_hash=hashlib.sha256(z.read(lib)).hexdigest()
        template_hash=hashlib.sha256(release.read(lib)).hexdigest()
        if lib_hash!=template_hash or lib_hash==hashlib.sha256(debug_template.read(lib)).hexdigest():raise RuntimeError('Output native runtime is not the pinned release template')
    after=runtime_manifest()
    if before!=after:raise RuntimeError('Runtime sources changed during release export')
    if debug.exists() and hashlib.sha256(debug.read_bytes()).hexdigest()!=debug_hash:raise RuntimeError('Existing debug APK changed')
    artifact=out/'iron-breakout-release.apk';pending.replace(artifact)
    metadata={'kind':'Android non-debug release; internal-test signing, not store publishing certificate','version_name':setting('version/name'),'version_code':int(re.search(r'^version/code=(\d+)',source,re.M).group(1)),'built_utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'engine_version':subprocess.check_output([engine(),'--version'],text=True).strip(),'apk_sha256':hashlib.sha256(artifact.read_bytes()).hexdigest(),'apk_bytes':artifact.stat().st_size,'debuggable':False,'manifest_debuggable_lines':debug_lines,'signing':'existing internal Android debug certificate; release build remains non-debug','certificate_sha256':certificate,'same_certificate_as_current_debug_apk':same_cert,'native_library_sha256':lib_hash,'matches_pinned_release_template':True,'debug_artifact_preserved':True,'export_presets_restored':presets.read_bytes()==original,'runtime_sources':after,'validation':'APK signature/manifest/native release runtime and source identity only; not installed or device-tested this turn','rebuild':'python3 tools/build_release.py'}
    (out/'iron-breakout-release.build.json').write_text(json.dumps(metadata,indent=2))
    print(json.dumps({k:v for k,v in metadata.items() if k!='runtime_sources'},indent=2))

if __name__=='__main__':main()
