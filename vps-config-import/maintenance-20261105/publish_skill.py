from pathlib import Path
import sys,json,hashlib,difflib,os
from notion_transport import Transport
from jev_skill_advisor.notion_sync import freeze_inventory,plan_sync,fidelity_preflight,execute_sync
from jev_skill_advisor.notion_import import NotionExportClient
ROOT=Path(__file__).resolve().parent
PAGE="3e145e44-58bf-816b-88b2-e41473b1ee1b"
t=Transport()
baseline=ROOT/"notion-predecessor.json"
if not baseline.exists():
 observed=t.observe_skill(PAGE)
 page=t.request("v1/pages/"+PAGE)
 export=NotionExportClient(runner=lambda path:t.request(path)).fetch("skill",PAGE)
 if export.version_id!=observed["version"]:raise RuntimeError("source changed before backup")
 (ROOT/"notion-predecessor.zip").write_bytes(export.archive)
 parent=page["parent"]
 observed["parent"]={k:parent[k] for k in ["database_id","data_source_id"]}
 baseline.write_text(json.dumps(observed,indent=2)+"\n")
else:observed=json.loads(baseline.read_text())
inventory=freeze_inventory(ROOT/"skill-candidate")
if inventory["exclusions"]:raise RuntimeError(inventory["exclusions"])
pre=fidelity_preflight(inventory)
if pre["failed"]:raise RuntimeError(pre["failed"])
remote=[{"stable_id":"warehouse:capi","page_id":PAGE,"remote_hash":observed["version"],"last_synced_hash":observed["version"]}]
plan=plan_sync(inventory,remote,database_id=observed["parent"]["database_id"],data_source_id=observed["parent"]["data_source_id"])
(ROOT/"skill-inventory.json").write_text(json.dumps(inventory,indent=2)+"\n")
(ROOT/"skill-plan.json").write_text(json.dumps(plan,indent=2)+"\n")
print(json.dumps({"files":len(inventory["skills"][0]["files"]),"preflight":pre["counts"],"actions":plan["counts"]}),flush=True)
if "--apply" in sys.argv:
 result=execute_sync(inventory,plan,ledger_path=ROOT/"publication-ledger.sqlite",run_id="capi-maintenance-20261105-v2",transport=t,only_ids=["warehouse:capi"])
 (ROOT/"publication-result.json").write_text(json.dumps(result,indent=2)+"\n")
 print(json.dumps(result),flush=True)
