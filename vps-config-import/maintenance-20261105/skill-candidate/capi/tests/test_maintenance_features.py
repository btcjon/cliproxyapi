"""Offline checks for explicit model selection and cache-probe request continuity."""
import contextlib,importlib.util,io,json,sys,types,unittest,subprocess
from pathlib import Path
from unittest.mock import patch
ROOT=Path(__file__).resolve().parents[1]
def module(name,file):
 spec=importlib.util.spec_from_file_location(name,ROOT/"scripts"/file)
 m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m);return m
class Features(unittest.TestCase):
 def test_cache_probe_keeps_key_and_prefix_and_reports_estimated_usage(self):
  m=module("cache_probe","capi-cache-probe.py");requests=[]
  class Response:
   status=200
   def __enter__(self):return self
   def __exit__(self,*args):return False
   def read(self):return json.dumps({"choices":[{"message":{"content":"CACHE_OK"}}],"usage":{"prompt_tokens":1600,"prompt_tokens_details":{"cached_tokens":1536},"cursor_usage_estimated":True}}).encode()
  def open_(req,timeout):
   requests.append(json.loads(req.data));return Response()
  output=io.StringIO()
  with patch.object(m,"auth_header",return_value="Bearer synthetic-secret"),patch.object(m._HTTP,"open",side_effect=open_),patch.object(sys,"argv",["probe","--model","cursor/auto","--prefix-words","100"]),contextlib.redirect_stdout(output):
   self.assertEqual(m.main(),0)
  self.assertEqual(len(requests),2)
  self.assertEqual(requests[0]["prompt_cache_key"],requests[1]["prompt_cache_key"])
  self.assertEqual(requests[0]["messages"][0],requests[1]["messages"][0])
  self.assertEqual(requests[0]["messages"][1],requests[1]["messages"][1])
  self.assertIn('"cursor_usage_estimated": true',output.getvalue())
  self.assertNotIn("synthetic-secret",output.getvalue())
 def test_image_explicit_model_reaches_generate_payload(self):
  m=module("image_model","capi-gpt-image-2.py");calls=[]
  fake=types.ModuleType("PIL");fake.Image=object()
  with patch.dict(sys.modules,{"PIL":fake}),patch.object(sys,"argv",["image","generate","--model","gpt-image-2.6-flare","--prompt","synthetic","--out","unused.png"]),patch.object(m,"_http_json",side_effect=lambda url,body:calls.append(body) or {}),patch.object(m,"_write_image"):
   m.main()
  self.assertEqual(calls[0]["model"],"gpt-image-2.6-flare")

 def test_log_summary_never_emits_original_lines(self):
  raw='[2026-11-05] [error] [gin_logger.go:10] 401 | token=synthetic-secret email=private@example.test\n'
  result=subprocess.run([sys.executable,str(ROOT/"scripts/capi-log-summary.py")],input=raw,text=True,capture_output=True,check=True)
  value=json.loads(result.stdout)
  self.assertEqual(value["http_statuses"],{"401":1})
  self.assertNotIn("synthetic-secret",result.stdout)
  self.assertNotIn("private@example.test",result.stdout)
