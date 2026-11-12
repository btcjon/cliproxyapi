#!/usr/bin/env python3
"""Two quota-consuming calls per explicit model; report cache usage, never credentials."""
import argparse,json,os,sys,time,urllib.request,urllib.error,uuid
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parent))
from capi_auth import auth_header
class NoRedirects(urllib.request.HTTPRedirectHandler):
 def redirect_request(self,req,fp,code,msg,headers,newurl): return None
_HTTP=urllib.request.build_opener(NoRedirects())
def main():
 p=argparse.ArgumentParser(description=__doc__)
 p.add_argument("--model",action="append",required=True)
 p.add_argument("--prefix-words",type=int,default=1800)
 p.add_argument("--output")
 a=p.parse_args()
 if not 100<=a.prefix_words<=8000:p.error("prefix-words must be between 100 and 8000")
 url=os.environ.get("CAPI_URL","https://llm-proxy.genr8ive.ai").rstrip("/").removesuffix("/v1")
 authorization=auth_header(url)
 prefix="This is a synthetic prompt-cache diagnostic. Ignore the reference data and reply only CACHE_OK. Reference data:\n"+" ".join("record"+str(i) for i in range(a.prefix_words))
 records=[]
 for model in a.model:
  key="capi-cache-probe-"+str(uuid.uuid4())
  for turn in (1,2):
   body={"model":model,"messages":[{"role":"system","content":prefix},{"role":"user","content":"Reply only CACHE_OK. Diagnostic conversation."}],"prompt_cache_key":key,"max_tokens":128}
   if model.startswith("gpt-"):body["reasoning_effort"]="low"
   req=urllib.request.Request(url+"/v1/chat/completions",data=json.dumps(body).encode(),headers={"Authorization":authorization,"Content-Type":"application/json","X-Session-Id":key})
   start=time.monotonic();record={"model":model,"turn":turn}
   try:
    with _HTTP.open(req,timeout=90) as r:response=json.load(r);record["http_status"]=r.status
    usage=response.get("usage",{})
    record["usage"]={k:v for k,v in usage.items() if k in ["prompt_tokens","completion_tokens","total_tokens","prompt_tokens_details","cache_read_input_tokens","cache_creation_input_tokens","cursor_usage_estimated"]}
    content=response.get("choices",[{}])[0].get("message",{}).get("content")
    record["content_present"]=bool(content)
   except urllib.error.HTTPError as e:
    record["http_status"]=e.code
   except Exception as e:record["error_type"]=type(e).__name__
   record["seconds"]=round(time.monotonic()-start,3);records.append(record);print(json.dumps(record),flush=True)
   if record.get("http_status")!=200:break
 if a.output:Path(a.output).write_text(json.dumps(records,indent=2)+"\n")
 return 0 if all(r.get("http_status")==200 for r in records) else 1
if __name__=="__main__":raise SystemExit(main())
