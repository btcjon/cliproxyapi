Proceed with two separate deliverables: update the existing Grok Build installations, and repair the proxy’s version headers. The explicit update request authorizes the former; the existing repair scope supports the latter.

Grok Build: Verify runtime versions and resolved executable paths on Mac and dest. Update older installations through the official distribution to verified stable, preserving configuration/credentials. Already-current installation needs no replacement. Record before/after versions and retain binary rollback.

Proxy: Keep CLIProxyAPI7.2.158. Official source applies custom headers after pinned identity headers. Also confirm how auth-file headers become runtime attributes before editing. Add only x-grok-client-version1.0.46 and User-Agent xai-grok-workspace/1.0.46.

Risks: concurrent credential refresh, unproven reload, version override does not prove complete protocol compatibility. Fresh host-local snapshot, abort on concurrent changes, preserve permissions, compare every non-header field immediately. Rollback restores only these values in current file.

Acceptance: runtime versions, effective proxy headers, unchanged routing/models/budgets, completion of existing provider operation tied to approved payload/canonical memory, native readback and duplicate-document check. No retain resubmission/another approval. Checker stays paused. Report CLI update and publication separately.
