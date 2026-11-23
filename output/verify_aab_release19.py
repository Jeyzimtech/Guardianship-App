from pathlib import Path
import hashlib,json,re,struct,subprocess,zipfile,xml.etree.ElementTree as ET
root=Path(__file__).resolve().parents[1]
bundle=root/'mobile/build/app/outputs/bundle/release/app-release.aab'
tool=root/'output/tools/bundletool-all-1.18.3.jar'
assert hashlib.sha256(tool.read_bytes()).hexdigest()=='a099cfa1543f55593bc2ed16a70a7c67fe54b1747bb7301f37fdfd6d91028e29'
def run(*args):
 p=subprocess.run(list(args),capture_output=True,text=True,check=True);return p.stdout+p.stderr
validation=run('java','-jar',str(tool),'validate','--bundle='+str(bundle))
xml=run('java','-jar',str(tool),'dump','manifest','--bundle='+str(bundle),'--module=base')
manifest=ET.fromstring(xml);android='{http://schemas.android.com/apk/res/android}'
assert manifest.attrib['package']=='educonnect.com'
assert manifest.attrib[android+'versionCode']=='19'
assert manifest.attrib[android+'versionName']=='1.0.18'
sdk=manifest.find('uses-sdk');assert int(sdk.attrib[android+'targetSdkVersion'])>=36
app=manifest.find('application');assert app.attrib.get(android+'debuggable','false')=='false'
assert app.attrib[android+'usesCleartextTraffic']=='false'
permissions=[p.attrib[android+'name'] for p in manifest.findall('uses-permission')]
assert not any(x in ' '.join(permissions) for x in ['READ_SMS','READ_CONTACTS','ACCESS_FINE_LOCATION','READ_MEDIA_IMAGES','MANAGE_EXTERNAL_STORAGE','AD_ID'])
config=run('java','-jar',str(tool),'dump','config','--bundle='+str(bundle));assert 'PAGE_ALIGNMENT_16K' in config
signature=run('jarsigner','-verify',str(bundle));assert 'jar verified.' in signature
cert=run('keytool','-printcert','-jarfile',str(bundle));assert 'CN=Android Debug' not in cert
fingerprint=re.search(r'SHA256:\s*([0-9A-F:]+)',cert).group(1)
# The existing store bundle's public signing certificate is retained locally for comparison.
oldcert=root/'output/release18-upload-certificate.txt'
if oldcert.exists():assert re.search(r'SHA256:\s*([0-9A-F:]+)',oldcert.read_text(encoding='utf-8')).group(1)==fingerprint
previous_apk=root/'output/EduConnect-before-feature-release.apk'
if previous_apk.exists():
 import os
 sdk_tools=Path(os.environ['LOCALAPPDATA'])/'Android/sdk/build-tools'
 signer=next(p/'apksigner.bat' for p in sorted(sdk_tools.iterdir(),reverse=True) if (p/'apksigner.bat').exists())
 previous=run(str(signer),'verify','--print-certs',str(previous_apk))
 prior_hash=re.search(r'SHA-256 digest:\s*([0-9a-fA-F]+)',previous).group(1)
 assert prior_hash.lower()==fingerprint.replace(':','').lower(),'Upload certificate differs from existing release APK'
libraries=[];production=False
with zipfile.ZipFile(bundle) as z:
 for name in z.namelist():
  if not name.startswith('base/lib/') or not name.endswith('.so'):continue
  data=z.read(name);bits=data[4];endian='<' if data[5]==1 else '>'
  if name.endswith('/libapp.so') and b'https://admin.chewetechnologies.co.zw/api' in data:production=True
  if bits==2:
   offset=struct.unpack_from(endian+'Q',data,32)[0];size,count=struct.unpack_from(endian+'HH',data,54)
   alignments=[]
   for i in range(count):
    ph=offset+i*size;kind=struct.unpack_from(endian+'I',data,ph)[0]
    if kind==1:
     fileoff,vaddr=struct.unpack_from(endian+'QQ',data,ph+8);align=struct.unpack_from(endian+'Q',data,ph+48)[0]
     assert align>=16384 and fileoff%16384==vaddr%16384,(name,align)
     alignments.append(align)
   libraries.append({'path':name,'load_alignments':alignments})
assert production,'Production URL not found in compiled app'
report={'package':'educonnect.com','version':'1.0.18','version_code':19,'target_sdk':int(sdk.attrib[android+'targetSdkVersion']),'min_sdk':int(sdk.attrib[android+'minSdkVersion']),'debuggable':False,'cleartext_allowed':False,'signed':True,'upload_certificate_sha256':fingerprint,'matches_previous_upload_certificate':oldcert.exists(),'bundletool_validation':'passed','zip_page_alignment':'16 KB','native_64_bit_libraries':libraries,'production_api_compiled':production,'permissions':permissions,'sha256':hashlib.sha256(bundle.read_bytes()).hexdigest(),'size_bytes':bundle.stat().st_size}
(root/'output/release19-aab-verification.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
(root/'output/release19-bundle-manifest.xml').write_text(xml,encoding='utf-8')
print(json.dumps(report,indent=2))
