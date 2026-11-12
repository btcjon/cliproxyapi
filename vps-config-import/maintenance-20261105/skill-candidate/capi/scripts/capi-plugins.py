#!/usr/bin/env python3
"""Read only allowlisted plugin registration metadata using the separate management key."""
import json,os,sys,urllib.request,urllib.error
from pathlib import Path
from urllib.parse import urlsplit
from capi_auth import validate_endpoint
class NoRedirects(urllib.request.HTTPRedirectHandler):
 def redirect_request(self,*args):return None
def main():
 url=os.environ.get("CAPI_URL","https://llm-proxy.genr8ive.ai").rstrip("/").removesuffix("/v1")
 local=validate_endpoint(url)
 key=os.environ.get("CAPI_MANAGEMENT_KEY","")
 file=os.environ.get("CAPI_MANAGEMENT_KEY_FILE")
 if not file and (local or urlsplit(url).hostname=="llm-proxy.genr8ive.ai"):
  file=str(Path.home()/".cli-proxy-api/management-api-key")
 if not key and file:
  p=Path(file).expanduser()
  if p.stat().st_mode&0o077:raise ValueError("Management key file must be owner-only")
  key=p.read_text().strip()
 if not key or key=="sk-dummy" or any(ord(c)<32 or ord(c)==127 for c in key):raise ValueError("Configure a valid separate management key")
 req=urllib.request.Request(url+"/v8/management/plugins",headers={"Authorization":"Bearer "+key})
 with urllib.request.build_opener(NoRedirects()).open(req,timeout=20) as response:x=json.load(response)
 allowed=["id","registered","enabled","effective_enabled","supports_oauth","oauth_provider"]
 print(json.dumps({"plugins_enabled":x.get("plugins_enabled"),"plugins":[{**{k:p.get(k) for k in allowed},"version":p.get("metadata",{}).get("version")} for p in x.get("plugins",[])]},indent=2))
if __name__=="__main__":
 try:main()
 except urllib.error.HTTPError as e:print("Management request failed: HTTP "+str(e.code),file=sys.stderr);sys.exit(1)
 except (ValueError,OSError) as e:print("Management diagnostic failed: "+type(e).__name__,file=sys.stderr);sys.exit(2)
