# Current diagnostic helper configuration

The existing four shell entrypoints and generate/edit image helper remain available. Shell helpers require Bash, Python 3, curl and jq. Image helper uses Python 3 standard-library HTTP.

- `CAPI_URL`: endpoint base, with optional `/v1` suffix for shell helpers. Default shell endpoint is the recorded HTTPS service; image default remains loopback.
- `CAPI_API_KEY`: process-scoped inbound key. Do not place it inline in a tool request or persist it in global shell startup files.
- `CAPI_API_KEY_FILE`: explicit owner-only inbound-key file. On loopback or the known `llm-proxy.genr8ive.ai` host only, the helper may use the existing `~/.cli-proxy-api/inbound-api-key`. Arbitrary hosts do not inherit that file.
- Without a configured key, `sk-dummy` remains a loopback-only compatibility fallback. Remote access requires HTTPS and a real configured key. A 401 still means authentication failed; no auto-login or auth weakening occurs.
- `CAPI_SERVICE_SCOPE=user` and `CAPI_SERVICE=cli-proxy-api` are destination defaults. Historical system deployments can explicitly select `CAPI_SERVICE_SCOPE=system CAPI_SERVICE=cliproxyapi`. Logs retain service/file/update/follow modes and aliases without automatic privilege elevation.
- `CAPI_TIMEOUT_SECONDS` is the shell request total deadline (60 seconds by default); connection timeout is 10 seconds. No automatic retries of billable writes.

Shell credentials are passed through curl configuration on stdin rather than in command-line arguments. Do not run with shell tracing or paste raw logs. The helper does not reconfigure servers or prove the endpoint is healthy merely by loading a key.

Examples (no secret literals):
```sh
CAPI_API_KEY_FILE="$HOME/.cli-proxy-api/inbound-api-key" bash scripts/capi-models.sh gemini
set -o pipefail
CAPI_SERVICE_SCOPE=user bash scripts/capi-logs.sh 50 service | python3 scripts/capi-log-summary.py
bash scripts/capi-test.sh MODEL_FROM_CURRENT_CATALOG 'Reply with one word'
python3 scripts/capi-gpt-image-2.py --capi-url https://llm-proxy.genr8ive.ai edit --prompt 'Requested edit' --image base.png --image reference.png --out result.png
```

Primary command syntax: https://curl.se/docs/manpage.html (`--config -`, `--max-time`, `--connect-timeout`). Local helper source is authoritative for these environment names and positional arguments. Tests with synthetic credentials and mocked transports establish helper behavior, not live service or account reliability.

Image validation requires Pillow in the selected Python runtime. On the authoring VPS, `/home/dev/.hermes/hermes-agent/venv/bin/python` already supplies it; elsewhere verify the chosen runtime. Missing Pillow fails before any API request. Responses must fully decode as an image before atomic replacement; malformed/truncated data preserves existing output.


## Separate management diagnostics
Use `python3 scripts/capi-plugins.py` for allowlisted registration status. Configure CAPI_MANAGEMENT_KEY or owner-only CAPI_MANAGEMENT_KEY_FILE; the known host/loopback default is ~/.cli-proxy-api/management-api-key. Never use the client key for management or the management key as a client credential. No redirects are followed.
The raw logs helper can contain private request metadata. In agent tools enable `set -o pipefail` and use a local pipeline such as `bash scripts/capi-logs.sh 80 service | python3 scripts/capi-log-summary.py`; the summary discards original lines and emits only counts. For deeper troubleshooting save raw material privately and extract bounded redacted facts, never paste it.
