import io, urllib.request, zipfile, json, struct, pathlib
ROOT=pathlib.Path(__file__).resolve().parents[1]/'exports'
req=urllib.request.Request('https://api.github.com/repos/godotengine/godot-builds/releases/tags/4.7.2-stable',headers={'User-Agent':'midnight-shift-build'})
release=json.load(urllib.request.urlopen(req))
asset=next(a for a in release['assets'] if a['name']=='Godot_v4.7.2-stable_export_templates.tpz')
class RemoteZip(io.RawIOBase):
 def __init__(self,url,size):self.url=url;self.size=size;self.pos=0
 def seekable(self):return True
 def seek(self,offset,whence=0):
  self.pos=offset if whence==0 else self.pos+offset if whence==1 else self.size+offset
  return self.pos
 def tell(self):return self.pos
 def read(self,size=-1):
  if size<0:size=self.size-self.pos
  if not size:return b''
  request=urllib.request.Request(self.url,headers={'Range':f'bytes={self.pos}-{self.pos+size-1}','User-Agent':'midnight-shift-build'})
  with urllib.request.urlopen(request,timeout=180) as response:
   if response.status!=206:raise RuntimeError(f'Server did not support range: {response.status}')
   data=response.read()
  self.pos+=len(data)
  return data
with zipfile.ZipFile(RemoteZip(asset['browser_download_url'],asset['size'])) as archive:
 for name in archive.namelist():
  if name.endswith(('/android_debug.apk','/android_release.apk','/version.txt')):
   data=archive.read(name)
   target=ROOT/'templates'/pathlib.Path(name).name
   target.write_bytes(data)
   print(target.name,len(data),flush=True)
