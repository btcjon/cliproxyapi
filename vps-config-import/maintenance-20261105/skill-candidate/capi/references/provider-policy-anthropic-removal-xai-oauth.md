> Scope clarification (November 2026): the user separately authorized the Cursor provider. Its cursor/claude routes do not restore direct Anthropic subscription OAuth. Do not apply the historical zero-Claude-model check below to Cursor routes. Check direct provider ownership instead. The Hermes xAI OAuth lane remains separate; do not change it as incidental CAPI repair.

> Recorded procedure, not a fresh host install. The SSH target `dev@5.161.192.198` and `sudo systemctl restart cliproxyapi` are historical examples. Verify the owning host and unit before use. Destination default is user service `cli-proxy-api`. Do not treat this note as current host authority or a live health claim.

# CAPI provider policy: Anthropic removal + xAI OAuth

Session-derived operational note for JB's CAPI host.

## Anthropic removal means more than editing `config.yaml`

When JB says to totally remove Anthropic from CAPI, treat it as an active runtime cleanup:

1. Back up `${HOME}/.cli-proxy-api/config.yaml` with a timestamp.
2. Remove active Anthropic/Claude routing from config:
   - `claude-api-key:` blocks, including Anthropic-compatible upstream hacks.
   - `oauth-model-alias.claude` aliases such as `sonnet`, `opus`, `haiku`.
   - `payload.override` entries whose model protocol is `claude`.
3. If Z.AI/GLM was routed through an Anthropic-compatible endpoint, move it to `openai-compatibility` using `https://api.z.ai/api/coding/paas/v4` instead of `https://api.z.ai/api/anthropic`.
4. Move Claude/Anthropic credential files out of the CAPI auth-dir, not just into `disabled-auth`, because CAPI may still scan nearby auth entries depending on version. Archive under `/Users/jon/Library/CloudStorage/Dropbox/archive/...`.
5. Move old CAPI config backups that contain Claude/Anthropic references out of `${HOME}/.cli-proxy-api` if the user wants the directory clean.
6. Restart the verified owning unit; recorded deployment: `systemctl --user restart cli-proxy-api`.
7. Verify both:
   - `grep -nEi 'anthropic|claude|sonnet|opus|haiku' ${HOME}/.cli-proxy-api/config.yaml` returns no matches.
   - `/v1/models` has `claude-ish=0` by counting IDs matching `claude|sonnet|opus|haiku`.

## xAI OAuth support in CAPI

CAPI v7.1.68 exposes xAI OAuth through:

```bash
cli-proxy-api -config ${HOME}/.cli-proxy-api/config.yaml -xai-login -no-browser -oauth-callback-port 8085
```

For remote VPS login, run the command in a PTY so the OAuth URL and callback prompt are visible. Non-PTY/background execution can sit silently while still listening on `127.0.0.1:8085`.

Local machine tunnel:

```bash
ssh -L 8085:127.0.0.1:8085 dev@5.161.192.198 -p 22
```

Then open the emitted `https://auth.x.ai/oauth2/authorize?...redirect_uri=http%3A%2F%2F127.0.0.1%3A8085%2Fcallback...` URL locally. If the browser returns a callback token instead of redirecting cleanly, paste/feed it into the waiting CLI prompt.

After callback succeeds, restart or let CAPI reload, then verify `/v1/models` for `xai|grok` model IDs and run a minimal smoke test before claiming xAI is wired.
