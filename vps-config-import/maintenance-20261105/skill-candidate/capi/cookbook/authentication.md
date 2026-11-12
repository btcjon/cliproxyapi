> Compatibility archive, not the active default. Current policy keeps Anthropic/Claude off CAPI unless JB explicitly reverses it in this session. `--claude-login` below is historical compatibility, not an authorized repair. The SSH host is a recorded callback example, not current host authority. Active diagnostics live in `scripts/` and `references/current-diagnostics.md`. Account changes still need explicit approval.

# Authentication

Use this only after JB explicitly approves an account-bound auth action for the current session. OAuth/login flows mutate CAPI account pools and may require a browser callback.

## Login Commands

```bash
cd ~/.cli-proxy-api
cli-proxy-api --login          # Gemini / Google OAuth
cli-proxy-api --codex-login    # OpenAI/Codex OAuth
cli-proxy-api --claude-login   # Anthropic/Claude auth
```

## Multi-Account Load Balancing

Repeat a login only when the user explicitly wants to add another account. CLIProxyAPI auto-balances across authenticated accounts.

```bash
cli-proxy-api --login  # approved account 1
cli-proxy-api --login  # approved account 2
```

## VPS OAuth Callback

OAuth callbacks usually target `localhost:8085`. From a laptop, open a tunnel before starting the VPS login:

```bash
ssh -L 8085:127.0.0.1:8085 dev@5.161.192.198 -p 22
```

Then run the approved login command on the VPS and open the printed authorization URL in the laptop browser.

## Provider Auth Methods

| Provider | Auth Type |
|----------|-----------|
| Google / Gemini (`gemini-*`) | OAuth |
| OpenAI / Codex / image (`gpt-*`, `gpt-image-*`) | OAuth-backed CAPI pool |
| Anthropic / Claude (`claude-*`) | Claude auth/API-key flow supported by CAPI |
| Z.AI / GLM (`glm-*`, `zai/*`) | API key in CAPI config |
| Other API-key providers | API key in CAPI config |

## Token Expiry

When a caller gets `403 Forbidden`, first verify which provider/model failed from logs or response metadata, then request approval for the matching re-authentication. Do not rotate credentials or paste token files into chat.

## Auth Files

Located in `~/.cli-proxy-api/`:
- OAuth tokens: `*.json`
- API keys: stored in `config.yaml`

Never display raw token/API-key file contents.
