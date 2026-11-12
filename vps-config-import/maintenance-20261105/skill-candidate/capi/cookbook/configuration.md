> Compatibility archive. The YAML below is a historical shape, not a fresh installation and not proof of the live catalog. Do not treat listed model aliases as currently available. Active endpoint and key rules are in `references/current-diagnostics.md`.

# Configuration

## Config File

**Location**: `~/.cli-proxy-api/config.yaml`

```yaml
port: 8317
auth-dir: "~/.cli-proxy-api"
debug: false
logging-to-file: true
request-retry: 3
quota-exceeded:
  switch-project: true
  switch-preview-model: true
usage-statistics-enabled: true

# Z.AI GLM (API key based)
openai-compatibility:
  - name: "zai"
    base-url: "https://api.z.ai/api/anthropic"
    api-key-entries:
      - api-key: "YOUR_ZAI_API_KEY"
    models:
      - name: "glm-4.6"
        alias: "glm-4.6"
      - name: "glm-4.5-air"
        alias: "glm-4.5-air"
```

## Config Options

| Option | Default | Description |
|--------|---------|-------------|
| `port` | 8317 | Server listen port |
| `auth-dir` | ~/.cli-proxy-api | Auth token directory |
| `debug` | false | Verbose logging |
| `logging-to-file` | true | Write to log file |
| `request-retry` | 3 | Retry failed requests |
| `switch-project` | true | Auto-switch on quota exceeded |
| `switch-preview-model` | true | Fallback to preview models |

## Adding API Key Providers

Add to `openai-compatibility` section:

```yaml
openai-compatibility:
  - name: "provider-name"
    base-url: "https://api.provider.com/v1"
    api-key-entries:
      - api-key: "YOUR_API_KEY"
    models:
      - name: "model-id"
        alias: "friendly-name"
```
