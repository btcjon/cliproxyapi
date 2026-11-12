# GPT-image-2 reference edits through CAPI

Use when a task needs image generation or reference-image editing without direct provider API keys, especially preserving a base mockup while changing subject identity, facial expression, attire, or hero imagery.

> November 2026: the live catalog includes Image 2, 2.5 and 2.6 variants. Catalog presence does not verify image execution. Keep the user's exact selected model; the helper now accepts generate/edit --model EXACT_ID. Its legacy default remains gpt-image-2. Select an ID from the live endpoint and check that exact ID before a batch.

## Endpoint shape

Local CAPI exposes OpenAI-compatible image endpoints:

```bash
# text-to-image
curl -sS http://127.0.0.1:8317/v1/images/generations \
  -H 'Authorization: Bearer sk-dummy' \
  -H 'Content-Type: application/json' \
  -d '{"model":"gpt-image-2","prompt":"premium editorial website mockup","size":"1024x1536","n":1}'

# reference/multi-image edit
curl -sS http://127.0.0.1:8317/v1/images/edits \
  -H 'Authorization: Bearer sk-dummy' \
  -F model='gpt-image-2' \
  -F size='1024x1536' \
  -F quality='medium' \
  -F prompt='Preserve the first image layout and use the second image as identity/style reference.' \
  -F image=@base-mockup.png \
  -F image=@reference.png
```

## Important details

- `Authorization: Bearer sk-dummy` is loopback-only compatibility. Public endpoints require the configured inbound key; provider authentication comes from CAPI’s OAuth-backed account pool.
- Preflight before batches with the selected endpoint and exact model ID. Absence means investigate the selected catalog/auth lane; it does not authorize account login or service changes. A catalog match alone does not prove an image request will succeed.

```bash
set -euo pipefail
# Run from the selected CAPI package root; load a private inbound key for HTTPS.
CAPI_URL="${CAPI_URL:-http://127.0.0.1:8317}"
export CAPI_URL
models=$(bash scripts/capi-models.sh)
printf '%s\n' "$models" | grep -Fqx -- 'gpt-image-2'
```

Generation/edit requests below consume provider quota; the catalog preflight is read-only.
- `auth_unavailable: no auth available (providers=codex, model=gpt-image-2)` means CAPI has no usable image-provider auth for that model at that moment. With JB approval, run the appropriate OAuth repair such as `cli-proxy-api --codex-login`, then restart/recheck CAPI. Do not treat this as proof that `gpt-image-2` edits are unsupported.
- Repeated multipart `image` fields work for base image + one or more references. Prefer `-F image=@file.png` for CAPI; reserve `image[]` only for direct APIs/docs that explicitly require bracketed field names.
- Responses return `data[0].b64_json`; decode to a PNG locally.
- The hashed Cloudflare-like/generated response URL is not needed; persist decoded local files.
- Use `quality=medium` for draft/presentation work unless the user explicitly asks for higher cost/quality.

## Prompt pattern for preserving a website mockup

```text
Use the first image as the exact website mockup/layout to preserve.
Use the second image as the identity/reference image.
Edit only the hero subject/portrait: <specific expression, attire, identity traits>.
Preserve page composition, typography blocks, labels, navigation, CTA framing, and premium editorial tone.
Do not turn this into a chatbot dashboard. Do not re-layout the page.
```

## Verification

1. Decode the b64 output and run `identify`:
   ```bash
   identify -format '%w x %h, %m, %b\n' output.png
   ```
2. Run vision review for:
   - reference likeness / subject identity
   - requested expression or attire
   - base layout preservation
   - artifacts in small text, hands, icons, or generated UI copy
3. If the edit preserved the page poorly, lower scope: ask it to edit only the hero portrait/attire/expression and explicitly preserve all UI text/layout.

## Known pitfalls

- Hermes built-in `image_generate` with OpenAI Codex auth now supports source/reference images (PR #57017) through `image_url` + `reference_image_urls` and should be tried for scratch/preview/fallback when its controls are sufficient. Use CAPI `/v1/images/edits` when you need raw multipart fields, batch/gallery scripting, local proxy routing, or model/API flags not exposed by the built-in tool.
- Direct OpenAI API keys or OpenAI Codex OAuth tokens may lack image scope even when text/model calls work. Do not assume `/v1/images/edits` will work directly.
- Generated website mockups often contain small-text artifacts. Treat them as build references, not production text.
- If a generated portrait repeats the same wardrobe too often, prompt explicit alternate attire while preserving face/hair/eyes/skin identity.
