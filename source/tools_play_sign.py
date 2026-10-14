"""Local upload-key signing. Secrets never enter source, command output or Git."""
from pathlib import Path
import secrets
import subprocess
import sys

root=Path('C:/Users/User/GardenOfLightBuild') if Path('C:/Users/User/GardenOfLightBuild/project.godot').exists() else Path(__file__).parent
java=root/'.tools/java/jdk-17.0.20.1+1/bin'
private=root/'.tools/play-signing'
private.mkdir(exist_ok=True)
password=private/'upload-password.txt'
key=private/'upload.keystore'
if key.exists() != password.exists():
    raise SystemExit('Incomplete signing material: restore the existing key/password pair. No key was replaced.')
if not key.exists():
    password.write_text(secrets.token_urlsafe(36),encoding='ascii')
    subprocess.run([str(java/'keytool.exe'),'-genkeypair','-keystore',str(key),'-storetype','JKS',
        '-alias','upload','-keyalg','RSA','-keysize','3072','-validity','10000',
        '-dname','CN=Jack Garden Upload', '-storepass:file',str(password),'-keypass:file',str(password)],check=True,capture_output=True)
if len(sys.argv)>1 and sys.argv[1]=='apk':
    sdk=root/'.tools/android-sdk/build-tools/36.1.0'
    tool=root/'.tools/bundletool/bundletool.jar'
    archive=root/'artifacts/jacks-garden-test.apks'
    final=root/'artifacts/jacks-garden-android.apk'
    subprocess.run([str(java/'java.exe'),'-jar',str(tool),'build-apks',
        '--bundle='+str(root/'artifacts/jacks-garden-play.aab'),'--output='+str(archive),
        '--mode=universal','--overwrite','--ks='+str(key),'--ks-key-alias=upload',
        '--ks-pass=file:'+str(password),'--key-pass=file:'+str(password)],check=True,capture_output=True)
    import zipfile
    with zipfile.ZipFile(archive) as package: final.write_bytes(package.read('universal.apk'))
    env=__import__('os').environ.copy(); env['JAVA_HOME']=str(java.parent)
    subprocess.run([str(sdk/'apksigner.bat'),'verify','--verbose',str(final)],check=True,env=env)
    subprocess.run([str(sdk/'zipalign.exe'),'-c','-P','16','4',str(final)],check=True)
else:
    final=root/'artifacts/jacks-garden-play.aab'
    subprocess.run([str(java/'jarsigner.exe'),'-keystore',str(key),'-storepass:file',str(password),
        '-keypass:file',str(password),'-sigalg','SHA256withRSA','-digestalg','SHA-256',str(final),'upload'],check=True,capture_output=True)
    result=subprocess.run([str(java/'jarsigner.exe'),'-verify',str(final)],check=True,capture_output=True,text=True)
    print(result.stdout.strip())
subprocess.run([str(java/'keytool.exe'),'-exportcert','-rfc','-keystore',str(key),'-storepass:file',str(password),
    '-alias','upload','-file',str(root/'artifacts/play-upload-certificate.pem')],check=True,capture_output=True)
print('Signed:',final)
print('Private signing material remains in .tools/play-signing. Back up the pair securely; never publish it.')
