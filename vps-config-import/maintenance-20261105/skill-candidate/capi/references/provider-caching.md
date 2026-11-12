# Provider caching

Cache processed prompt prefixes, not generated answers. CAPI cannot force every upstream to retain a prefix, share it across accounts, or report cache counters. Keep stable instructions, tools, documents and examples at the beginning; append changing user input. Avoid timestamps, random IDs, reordered tools and changing model settings in the reusable prefix. Preserve full ordered tool history. Do not add dummy content to production requests to reach cache thresholds.

## Deployed routing

The November 2026 tuning retains fill-first selection and enables:
```yaml
routing:
  strategy: fill-first
  session-affinity: true
  session-affinity-ttl: 1h
  session-affinity-subagents: true
  session-affinity-rebind-on: quota
```
Affinity keeps related calls on one eligible provider credential. Transient failures may use another credential for that request, while the original binding is retained; quota/auth/model-eligibility failures can rebind. This improves locality without disabling failover. The one-hour value is a proxy binding lifetime, not a provider cache-retention promise. Parent/child affinity can trade some parallel pool distribution for shared-prefix reuse; measure concurrency before changing it.

Use the same caller-provided conversation ID or `prompt_cache_key` on each turn and preserve distinct conversation boundaries. Native Codex/xAI executors derive provider session identities from recognized metadata; native xAI sends the corresponding conversation header. Do not install a global constant cache key or randomize it on every request. No changes to Hermes' separate direct xAI lane are implied.

## Provider-specific controls

| Route | Supported approach | Limits |
|---|---|---|
| Codex OAuth / GPT | Preserve session/cache key and prefix; native executor supplies continuity handling. | Direct OpenAI API options are not automatically supported by the Codex subscription backend. Do not globally inject 24h retention or new cache options. |
| Gemini CLI / Antigravity | Preserve history/prefix and account affinity; allow upstream implicit caching. | Direct Gemini API cachedContent objects are a separate paid/API facility and are not verified for these OAuth routes. Missing cache counters mean unknown. |
| Cursor, including Auto/Claude/Grok | Stable prompt_cache_key/session and original first user message; preserve tool history. | Plugin/account owns model selection, cache lifetime and usage reporting. No native Anthropic cache_control injection into Cursor. Auto can change model and cache locality. |
| Native xAI | Keep a per-conversation key and upstream x-grok-conv-id; native CAPI executor handles translation. | Account credits/quota still apply; proxy affinity cannot fix a 402. |
| Z.AI/GLM coding plan | Automatic repeated-context caching; stable ordered prefix/history. | No extra cache-key/TTL switch is required. Inspect usage.prompt_tokens_details.cached_tokens. |
| Venice | Automatic model-dependent caching; enable openai-compatibility[].support-prompt-cache-key for the Venice entry to derive keys across input protocols. Explicit supplied keys are preserved. | This capability is verified for Venice, not an instruction to enable it for every OpenAI-compatible endpoint. |
| Nous / Baseten | Preserve supplied content and provider-reported usage; leave unsupported cache controls unset. | Verify current model IDs, authentication and provider-specific support. Never invent caching guarantees from OpenAI compatibility alone. |

Official OpenAI docs distinguish newer GPT implicit/explicit options from legacy retention controls; only use controls accepted by the actual endpoint/model. Extended caches can change storage/cost characteristics and are not automatically preferable. Direct Anthropic subscriptions stay excluded; Cursor-provided Claude follows Cursor's protocol.

## Verify behavior

Run `scripts/capi-cache-probe.py --model EXACT_ID` only within authorized quota scope. It sends two calls with a shared synthetic prefix and per-model stable conversation key, printing HTTP status, timings and allowlisted usage. Never retry failed requests automatically. Use --output for a credential-free receipt. Optional --prefix-words controls synthetic test size; do not use it to alter client production prompts.

Compare the second call's provider-reported cached/read tokens with its input tokens. Nonzero reads demonstrate reuse for that route then. A successful response with missing counters is not a cache proof; estimated values must be labeled. Failure to observe a hit in two calls does not prove caching is disabled. Do not loop indefinitely warming a cache. Report authentication/model/credit failures separately.

## Sources

- [CAPI routing/config](https://github.com/router-for-me/CLIProxyAPI/blob/main/config.example.yaml)
- [OpenAI prompt caching](https://developers.openai.com/api/docs/guides/prompt-caching)
- [Gemini caching](https://ai.google.dev/gemini-api/docs/caching)
- [xAI caching](https://docs.x.ai/developers/advanced-api-usage/prompt-caching/how-it-works)
- [Z.AI context caching](https://docs.z.ai/guides/capabilities/cache)
- [Venice caching](https://docs.venice.ai/guides/features/prompt-caching)
- [Cursor plugin](https://github.com/spancerxing/cliproxyapi-cursor-plugin)
