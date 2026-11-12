> Archived alias text. This fresh snapshot has no sibling `cliproxyapi` package and no `warehouse:cliproxyapi` identity in the captured inventory. Absolute skill paths below are historical, not delivery targets. Contained cookbooks and `workflow.yaml` are the compatibility resources.

# Archived source skill: cliproxyapi

Original directory: `/Users/jon/.hermes/skills/openclaw-imports/cliproxyapi`
Archived by curator into `capi` on 2026-04-30T16:43:45.

---

---

archived-skill-name: cliproxyapi
canonical-skill: capi
description: "Alias skill for CLIProxyAPI operations. Merged into `capi`."
disable-model-invocation: true
version: 2.1.0
---
# CLIProxyAPI (Merged Alias)

This skill is now an alias for the canonical CLIProxyAPI skill:
- `/Users/jon/.agents/skills/capi/SKILL.md`

## Required Behavior

When this alias is invoked:
1. Load `capi`.
2. Use canonical CAPI endpoints, scripts, and model routing guidance.
3. Preserve legacy compatibility for `cliproxyapi` task wording and endpoint references.
4. Treat this alias as redirect-only.

## Legacy Cookbook Paths

Canonicalized under `capi`:
- `cookbook/authentication.md`
- `cookbook/configuration.md`
- `cookbook/sdk-integration.md`
- `cookbook/service-management.md`

## Contract-First Runtime

- Canonical workflow: `workflow.yaml`
- Generic adapter: `adapters/generic_tool_loop.py`
- Contract tests: `tests/test_contract.py`
- Runtime entrypoint: `python3 ~/.agents/tools/skill_runtime/run_contract.py --contract ~/.agents/skills/cliproxyapi/workflow.yaml --tool-module-path ~/.agents/skills/cliproxyapi/adapters/generic_tool_loop.py --input-json '{"request":"route this task","alias_skill":"cliproxyapi"}'`

