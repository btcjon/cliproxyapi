# cliproxy-vps-config → cliproxyapi import manifest (LAUN-44)
Source: `~/Dropbox/Projects/cliproxy-vps-config` on dest. Dropbox folder was not modified.
Compared against this worktree (btcjon/cliproxyapi @ 861ba2a).
Ignored: `.git`, `.git.broken-*`, `node_modules`, `__pycache__`, sync-conflict / conflicted copies, Dropbox cache, `.osgrep/`, `.tldr/`, `.tmp/`, `.factory/`, `logs/`, and `maintenance-20261105/upstream/` (vendor dump).

## Classification counts
- Identical (same path+content): 25
- Differing (same path, different content): 11
- Dropbox-only (classic unique, excl. caches/vendor): 17
- Repo-only: 4

## Identical
- `.claude/CLAUDE.md`
- `.cleanup-summary.md`
- `.cursor/rules/manage-claude.mdc`
- `EXPERT-AGENT-SETUP.md`
- `EXPERT-AGENT.md`
- `FILES-CREATED.txt`
- `bun.lock`
- `cliproxy-expert.service`
- `docs/CURSOR-AGENT-INTEGRATION.md`
- `docs/FACTORY-CLI-SETUP.md`
- `expert-agent-server.ts`
- `install-service.sh`
- `scripts/build.sh`
- `scripts/cursor-agent-mcp-server.js`
- `scripts/deploy.sh`
- `scripts/fix-claude-config.sh`
- `scripts/import-claude-agents-to-factory.sh`
- `scripts/setup-cursor-mac.sh`
- `scripts/setup-gemini-oauth.sh`
- `scripts/test-all-models.sh`
- `scripts/test-external-api.sh`
- `scripts/verify-config.sh`
- `start-agent.sh`
- `systemd/cli-proxy-api.service`
- `test-agent.sh`

## Differing (repo kept; Dropbox copy under `vps-config-import/differs/`)
Repo file mtimes are checkout-fresh (2026-11-12); use Dropbox mtime + content size vs last git commit for “which looks newer”. Repo last substantive commits are mostly 2025-11-25 initial (auto-update 2026-01-06). Dropbox versions are often shorter/older docs; `config.yaml` and `oauth-renew.sh` Dropbox copies are larger/newer in content.

- .gitignore | drop_mtime=2026-01-20 23:14:32 | repo_mtime=2026-11-12 15:59:50 | src_mtime=2026-11-12 14:10:10 | +1/-0 | newer_mtime=repo
- AGENTS.md | drop_mtime=2026-11-05 19:04:06 | repo_mtime=2026-11-12 15:59:50 | src_mtime=2026-11-12 14:10:10 | +9/-175 | newer_mtime=repo
- CLAUDE.md | drop_mtime=2026-03-28 11:42:25 | repo_mtime=2026-11-12 15:59:50 | src_mtime=2026-11-12 14:10:10 | +28/-22 | newer_mtime=repo
- README.md | drop_mtime=2026-11-05 19:04:06 | repo_mtime=2026-11-12 15:59:50 | src_mtime=2026-11-12 14:10:10 | +6/-193 | newer_mtime=repo
- config/config.yaml | drop_mtime=2026-09-11 14:54:48 | repo_mtime=2026-11-12 15:59:50 | src_mtime=2026-11-12 14:10:10 | +92/-20 | newer_mtime=repo
- docs/API-REFERENCE.md | drop_mtime=2026-03-28 11:40:51 | repo_mtime=2026-11-12 15:59:50 | src_mtime=2026-11-12 14:10:10 | +98/-868 | newer_mtime=repo
- docs/CURSOR-SETUP.md | drop_mtime=2026-09-11 14:55:42 | repo_mtime=2026-11-12 15:59:50 | src_mtime=2026-11-12 14:10:10 | +21/-17 | newer_mtime=repo
- docs/MODEL-DISCOVERY.md | drop_mtime=2026-03-28 11:40:51 | repo_mtime=2026-11-12 15:59:50 | src_mtime=2026-11-12 14:10:10 | +52/-283 | newer_mtime=repo
- docs/OAUTH.md | drop_mtime=2026-03-28 11:40:51 | repo_mtime=2026-11-12 15:59:50 | src_mtime=2026-11-12 14:10:10 | +47/-86 | newer_mtime=repo
- scripts/auto-update-cliproxy.sh | drop_mtime=2026-11-05 18:54:13 | repo_mtime=2026-11-12 15:59:50 | src_mtime=2026-11-12 14:10:10 | +3/-208 | newer_mtime=repo
- scripts/oauth-renew.sh | drop_mtime=2026-03-05 14:54:18 | repo_mtime=2026-11-12 15:59:50 | src_mtime=2026-11-12 14:10:10 | +24/-4 | newer_mtime=repo

Notes:
- `config/config.yaml`: **not** imported raw (secrets). Sanitized → `vps-config-import/differs/config/config.yaml.example`.
- Dropbox `AGENTS.md`/`README.md` are shorter post-maintenance stubs (2026-11-05); repo versions are the fuller docs.
- Dropbox `scripts/auto-update-cliproxy.sh` is a stub (144B); repo has the full 2026-01-06 script.
- Dropbox docs (API-REFERENCE, MODEL-DISCOVERY, OAUTH) are shorter; repo docs are expanded.

## Repo-only (unchanged)
- `.genkit/traces_idx/genkit.metadata`
- `CONFIGURATION-FIXED.md`
- `GEMINI-OAUTH-FIX.md`
- `TEST-RESULTS.md`

## Dropbox-only handling
### Imported (mapped onto existing paths)
- `docs/OPERATIONS.md`
- `docs/archive/CONFIGURATION-FIXED.md`
- `docs/archive/GEMINI-OAUTH-FIX.md`
- `docs/archive/TEST-RESULTS.md`
- `scripts/update-capi.py`

### Imported under `vps-config-import/`
- `package.json`, `factory-cli-config.json` (api_key values are `sk-dummy` placeholders), `.tldrignore`
- `reports/2026-10-05-memory-provider-header/*`
- `maintenance-20261105/**` unique non-cache files (skill-candidate, go executor snapshots, notion transport scripts, verification JSON, previous docs/scripts)
- sanitized `maintenance-20261105/config.example.yaml`

### Skipped (secrets) — paths only
- `config/config.yaml (Dropbox differ)`
- `config/config.yaml.bak-basic-auth-20260722T195528Z`
- `config/config.yaml.bak-dashboard-20260722T195149Z`
- `config/config.yaml.pre-oauth-only.20260305-135700`

### Skipped (regenerable / vendor / binary noise)
- `.osgrep/**`, `.tldr/**`, `.tmp/**`, `.factory/**`, `logs/**`
- `maintenance-20261105/upstream/**` (full upstream CLIProxyAPI source dump)
- `maintenance-20261105/source-readback-cache/**`
- `*.sqlite`, `*.lock`, `notion-predecessor.zip`

## Secret scan
- Tool: **gitleaks** (`/home/dev/bin/gitleaks`) + documented regex scan (API keys, bearer, private key headers, OAuth JSON token fields, cli-proxy-api auth paths).
- Pre-import: gitleaks reported live `generic-api-key` hits in the four Dropbox config YAML files (skipped / sanitized).
- Post-stage: 1 remaining gitleaks hit in `test_recipe_boundaries.py` (`synthetic-inbound-key-…` test fixture) — kept as intentional synthetic, not a live credential.
- Sanitized `.example` files use `REPLACE_ME` placeholders only.
