# CAPI VPS deployment

Current deployment and recovery instructions: [docs/OPERATIONS.md](docs/OPERATIONS.md).

The service runs on dest as the user unit cli-proxy-api, behind https://llm-proxy.genr8ive.ai. The dashboard is https://llm-proxy.genr8ive.ai/management.html. Client API and management keys are separate.

Use scripts/update-capi.py --check for version comparison. Authorized updates use the same script without --check; the installed user updater is ~/.local/libexec/capi-update.py and capi-update.timer runs weekly. It verifies checksums, preserves live configuration and dynamic plugins, and rolls back a failed binary update.

Older deployment/authentication documents and scripts may describe a former system service, public plain HTTP or dummy authentication. They are historical references. Follow AGENTS.md and docs/OPERATIONS.md for current operations. Never commit or print credentials or auth JSON.

Canonical CAPI Global Skill: https://www.notion.so/3e145e4458bf816b88b2e41473b1ee1b .
