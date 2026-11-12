#!/usr/bin/env python3
"""Route-only adapter for the capi workflow contract.

execute is an explicit boolean for the caller. This module never runs templates.
"""

from __future__ import annotations

ROUTE_SUMMARY = "Contract-first route resolver for capi."
TARGET_PATHS = [
    "SKILL.md",
    "scripts/capi-logs.sh",
    "scripts/capi-models.sh",
    "scripts/capi-status.sh",
    "scripts/capi-test.sh",
    "cookbook/authentication.md",
    "cookbook/configuration.md",
    "cookbook/sdk-integration.md",
    "cookbook/service-management.md",
]
COOKBOOK_REFS = [
    "cookbook/authentication.md",
    "cookbook/configuration.md",
    "cookbook/sdk-integration.md",
    "cookbook/service-management.md",
]
COMMAND_TEMPLATES = [
    "bash scripts/capi-logs.sh <args>",
    "bash scripts/capi-models.sh <args>",
    "bash scripts/capi-status.sh <args>",
    "bash scripts/capi-test.sh <args>",
]
GUIDANCE = (
    "Route only. Do not execute templates. Use package scripts for diagnostics, "
    "then contained cookbook compatibility docs. There is no sibling cliproxyapi package in this snapshot."
)


def _parse_execute(value: object) -> bool:
    """Accept only real booleans and explicit true/false strings.

    Missing or empty means false. Other shapes are rejected so the string
    "false" cannot become true through truthiness.
    """
    if value is None or value == "":
        return False
    if isinstance(value, bool):
        return value
    if isinstance(value, str):
        token = value.strip().lower()
        if token == "true":
            return True
        if token == "false":
            return False
    raise ValueError("execute must be a boolean or explicit true/false string")


def _capi__resolve_route(args: dict) -> dict:
    delegated_input = {
        "request": args.get("request"),
        "mode": args.get("mode"),
        "action": args.get("action"),
        "scope": args.get("scope"),
        "path": args.get("path"),
        "query": args.get("query"),
        "file_path": args.get("file_path"),
        "execute": _parse_execute(args.get("execute")),
    }
    delegated_input = {k: v for k, v in delegated_input.items() if v not in (None, "")}
    return {
        "route_summary": ROUTE_SUMMARY,
        "target_paths": TARGET_PATHS,
        "cookbook_refs": COOKBOOK_REFS,
        "command_templates": COMMAND_TEMPLATES,
        "guidance": GUIDANCE,
        "delegated_input": delegated_input,
    }


TOOL_REGISTRY = {
    "capi__resolve_route": _capi__resolve_route,
}
