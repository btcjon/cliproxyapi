import sys,json,time,urllib.request,urllib.error,hashlib,uuid
from pathlib import Path
sys.dont_write_bytecode=True
sys.path.insert(0,"/home/dev/.local/state/jev-skill-advisor/maintenance/lib")
from jev_skill_advisor.notion_sync import NtnSyncTransport,SyncError
from jev_skill_advisor.retirement import read_env_value
class Transport(NtnSyncTransport):
 def __init__(self):
  super().__init__();self.token=read_env_value("/home/dev/Dropbox/AI-Control-Plane/secrets/secrets.common.env","NOTION_PAT")
 def raw(self,path,method="GET",data=None,ctype="application/json"):
  wait=.8-(time.monotonic()-self.last_request)
  if wait>0:time.sleep(wait)
  req=urllib.request.Request("https://api.notion.com/"+path.lstrip("/"),data=data,method=method,headers={"Authorization":"Bearer "+self.token,"Notion-Version":"2025-09-03","Content-Type":ctype})
  self.last_request=time.monotonic()
  try:
   with urllib.request.urlopen(req,timeout=45) as r:return json.load(r)
  except urllib.error.HTTPError as e:raise SyncError("Notion HTTP "+str(e.code)) from None
 def request(self,path,*,method="GET",body=None,mutation=False):
  return self.raw(path,method,None if body is None else json.dumps(body).encode())
 def upload_bytes(self,data,name):
  filename="payload-"+hashlib.sha256(data).hexdigest()[:20]+".txt"
  created=self.request("v1/file_uploads",method="POST",body={"mode":"single_part","filename":filename,"content_type":"text/plain"},mutation=True)
  identity=created["id"];boundary="capi"+uuid.uuid4().hex
  payload=("--"+boundary+'\r\nContent-Disposition: form-data; name="file"; filename="'+filename+'"\r\nContent-Type: text/plain\r\n\r\n').encode()+data+("\r\n--"+boundary+"--\r\n").encode()
  result=self.raw("v1/file_uploads/"+identity+"/send","POST",payload,"multipart/form-data; boundary="+boundary)
  if result.get("status")!="uploaded":raise SyncError("file upload not complete")
  return result
