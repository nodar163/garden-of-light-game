"""Inspect bundle contents and 16 KB ELF alignment without external packages."""
from pathlib import Path
import json
import struct
import zipfile
import xml.etree.ElementTree as ET

root=Path(__file__).parent
bundle=root/'artifacts/jacks-garden-play.aab'
report={'bundle':bundle.name,'native_libraries':[],'checks':[]}
with zipfile.ZipFile(bundle) as z:
    names=z.namelist()
    assert 'base/manifest/AndroidManifest.xml' in names
    assert any(n.startswith('META-INF/') and n.endswith('.RSA') for n in names),'Missing upload signature'
    assert not any('keystore' in n.lower() or 'password' in n.lower() for n in names)
    for name in names:
        if not name.endswith('.so'): continue
        data=z.read(name)
        assert data[:4]==b'\x7fELF' and data[4]==2 and data[5]==1, 'Expected 64-bit little-endian ELF'
        header=struct.unpack_from('<HHIQQQIHHHHHH',data,16)
        phoff,phsize,phcount=header[4],header[8],header[9]
        alignment=[]
        for i in range(phcount):
            kind,flags,offset,vaddr,paddr,filesz,memsz,align=struct.unpack_from('<IIQQQQQQ',data,phoff+i*phsize)
            if kind==1:
                assert align>=16384 and offset%16384==vaddr%16384, 'Native library lacks 16 KB LOAD alignment'
                alignment.append(align)
        report['native_libraries'].append({'name':name,'load_alignment':alignment})
    assert report['native_libraries'],'Missing native engine'
    assert not any('yandex_bridge.js' in n or 'yandex_mock' in n for n in names)
    asset_prefix=next(n.rsplit('/levels/01.json',1)[0] for n in names if n.endswith('/assets/levels/01.json'))
    assert len([n for n in names if n.startswith(asset_prefix+'/levels/') and n.endswith('.json')])==1000
    assert len(json.loads(z.read(asset_prefix+'/match_levels/levels.json')))==1000
    assert asset_prefix+'/scripts/privacy_ui.gdc' in names
    report['checks']=['AAB structure','upload signature present','64-bit libraries','16 KB ELF LOAD alignment','no signing secrets','no Yandex SDK scripts']
manifest=ET.parse(root/'artifacts/google-play-manifest.xml').getroot()
android='{http://schemas.android.com/apk/res/android}'
assert manifest.get('package')=='com.nodar163.jacksgarden'
assert manifest.find('uses-sdk').get(android+'targetSdkVersion')=='36'
assert manifest.find('uses-sdk').get(android+'minSdkVersion')=='26'
assert manifest.find('application').get(android+'isGame')=='true'
assert not manifest.findall('uses-permission')
report['checks']+=['2000 bundled levels','offline privacy included','package identity','target 36 / min 26','game category','no requested permissions']
with zipfile.ZipFile(root/'artifacts/jacks-garden-android.apk') as apk:
    assert len([n for n in apk.namelist() if n.startswith('assets/levels/') and n.endswith('.json')])==1000
    assert 'assets/scripts/privacy_ui.gdc' in apk.namelist()
report['checks'].append('test APK includes install-time game assets')
(root/'artifacts/google-play-audit.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(report,ensure_ascii=False,indent=2))
