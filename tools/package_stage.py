#!/usr/bin/env python3
"""Package a labeled stage build with reproducible source; never claim final acceptance."""
import argparse,hashlib,json,pathlib,shutil,tarfile,zipfile,re
from quality import snapshot
from manage import ROOT
p=argparse.ArgumentParser();p.add_argument('--out',type=pathlib.Path,required=True);a=p.parse_args();a.out.mkdir(parents=True,exist_ok=True)
apk=ROOT/'builds/iron-breakout-debug.apk'
if not apk.exists() or not zipfile.is_zipfile(apk):raise RuntimeError('A valid built APK is required')
metadata_path=ROOT/'builds/iron-breakout-debug.build.json'
if not metadata_path.exists(): raise RuntimeError('Rebuild with tools/manage.py to record runtime source identity first')
metadata=json.loads(metadata_path.read_text())
if hashlib.sha256(apk.read_bytes()).hexdigest()!=metadata['apk_sha256']: raise RuntimeError('APK differs from build metadata')
for name,digest in metadata['runtime_sources'].items():
    if not (ROOT/name).is_file() or hashlib.sha256((ROOT/name).read_bytes()).hexdigest()!=digest: raise RuntimeError('Runtime source differs from APK: '+name)
snapshot(a.out/'source')
shutil.copyfile(apk,a.out/apk.name)
shutil.copyfile(metadata_path,a.out/metadata_path.name)
version=re.search(r'version/name="([^"]+)"',(ROOT/'export_presets.cfg').read_text()).group(1)
manifest={'stage':version+'; final acceptance incomplete','apk_sha256':hashlib.sha256(apk.read_bytes()).hexdigest(),'source_sha256':hashlib.sha256((a.out/'source/source.tar.gz').read_bytes()).hexdigest(),'exclusions':['work','signing keys','.godot','build caches'],'rebuild':'python3 tools/manage.py test && python3 tools/manage.py build','note':'Source archive includes project files and original artwork. Engine/templates/SDK/JDK and signing conditions are not distributed. Configure local debug signing; never distribute work/debug.keystore.'}
(a.out/'manifest.json').write_text(json.dumps(manifest,indent=2));print(a.out/'manifest.json')
