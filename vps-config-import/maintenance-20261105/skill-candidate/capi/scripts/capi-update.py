#!/usr/bin/env python3
"""Update the owning CAPI user service without replacing its configuration."""
import argparse, fcntl, hashlib, io, json, os, platform, shutil, subprocess, sys, tarfile, tempfile, time, urllib.request
from pathlib import Path

ROOT = Path.home()/".cli-proxy-api"
BINARY = Path.home()/".local/lib/capi/cli-proxy-api"
REPO = "router-for-me/CLIProxyAPI"

def run(*args):
    return subprocess.run(args, check=True, capture_output=True, text=True).stdout.strip()

def get(url):
    req=urllib.request.Request(url,headers={"User-Agent":"capi-maintenance","Accept":"application/vnd.github+json"})
    with urllib.request.urlopen(req,timeout=45) as r: return r.read()

def catalog():
    key=(ROOT/"inbound-api-key").read_text().strip()
    req=urllib.request.Request("http://127.0.0.1:8317/v1/models",headers={"Authorization":"Bearer "+key})
    with urllib.request.urlopen(req,timeout=15) as r:
        return {m["id"] for m in json.load(r)["data"]}

def healthy(expected):
    for attempt in range(15):
        try:
            models=catalog()
            if not models: raise RuntimeError("empty catalog")
            if any(m.startswith("cursor/") for m in expected) and not any(m.startswith("cursor/") for m in models):
                raise RuntimeError("Cursor models missing")
            return models
        except Exception:
            if attempt==14: raise
            time.sleep(2)

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument("--check",action="store_true")
    parser.add_argument("--version",help="explicit upstream tag, otherwise latest stable")
    args=parser.parse_args()
    ROOT.mkdir(mode=0o700,exist_ok=True)
    with (ROOT/"update.lock").open("a") as lock:
        os.chmod(ROOT/"update.lock",0o600)
        fcntl.flock(lock,fcntl.LOCK_EX|fcntl.LOCK_NB)
        suffix="/tags/"+args.version if args.version else "/latest"
        release=json.loads(get("https://api.github.com/repos/"+REPO+"/releases"+suffix))
        tag=release["tag_name"]; version=tag.removeprefix("v")
        import re
        if not re.fullmatch(r"[0-9]+\.[0-9]+\.[0-9]+",version): raise RuntimeError("not a stable release")
        output=run(str(BINARY),"--help")
        current=re.search(r"CLIProxyAPI Version:\s*([0-9.]+)",output).group(1)
        print(json.dumps({"current":current,"target":version,"check_only":args.check}),flush=True)
        if current==version or args.check: return
        if tuple(map(int,version.split(".")))<tuple(map(int,current.split("."))):
            raise RuntimeError("refusing downgrade")
        arch={"x86_64":"amd64","aarch64":"arm64"}[platform.machine()]
        asset_name=f"CLIProxyAPI_{version}_linux_{arch}.tar.gz"
        assets={a["name"]:a["browser_download_url"] for a in release["assets"]}
        checksum_name=next((n for n in assets if "checksum" in n.lower() and n.endswith(".txt")),None)
        if not checksum_name or asset_name not in assets: raise RuntimeError("release assets missing")
        checksums=get(assets[checksum_name]).decode()
        expected=next((l.split()[0] for l in checksums.splitlines() if l.split()[-1].lstrip("*")==asset_name),None)
        payload=get(assets[asset_name])
        if not expected or hashlib.sha256(payload).hexdigest()!=expected: raise RuntimeError("checksum mismatch")
        before=catalog()
        stamp=time.strftime("%Y%m%d-%H%M%S")
        backup=ROOT/"backups"/("update-"+stamp)
        backup.mkdir(parents=True,mode=0o700)
        shutil.copy2(BINARY,backup/"cli-proxy-api")
        shutil.copy2(ROOT/"config.yaml",backup/"config.yaml")
        os.chmod(backup/"config.yaml",0o600)
        (backup/"metadata.json").write_text(json.dumps({"from":current,"to":version,"asset_sha256":expected,"models_before":len(before)},indent=2))
        with tarfile.open(fileobj=io.BytesIO(payload),mode="r:gz") as tar:
            member=next((m for m in tar.getmembers() if m.isfile() and Path(m.name).name=="cli-proxy-api"),None)
            if member is None: raise RuntimeError("binary absent")
            candidate=BINARY.with_name("cli-proxy-api.update")
            with candidate.open("wb") as f: shutil.copyfileobj(tar.extractfile(member),f)
        os.chmod(candidate,0o755)
        if "Version: "+version not in run(str(candidate),"--help"): raise RuntimeError("binary version mismatch")
        if b"cliproxy_plugin_init" not in candidate.read_bytes(): raise RuntimeError("plugin support absent")
        try:
            run("systemctl","--user","stop","cli-proxy-api")
            os.replace(candidate,BINARY)
            run("systemctl","--user","start","cli-proxy-api")
            after=healthy(before)
        except Exception:
            restore=BINARY.with_name("cli-proxy-api.restore")
            shutil.copy2(backup/"cli-proxy-api",restore);os.replace(restore,BINARY)
            run("systemctl","--user","restart","cli-proxy-api")
            healthy(before)
            raise RuntimeError("update failed; previous binary restored") from None
        print(json.dumps({"updated":version,"models":len(after),"cursor_models":sum(m.startswith("cursor/") for m in after),"backup":str(backup)}))

if __name__=="__main__":
    try: main()
    except Exception as exc:
        print("CAPI update failed: "+str(exc),file=sys.stderr)
        sys.exit(1)
