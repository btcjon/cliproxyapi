#!/usr/bin/env python3
"""Offline execute-flag regression for the capi adapter.

No real tools, network, or config writes. Subprocess is patched.
"""

from __future__ import annotations

import importlib.util
import sys
import unittest
from pathlib import Path
from unittest.mock import patch

PACKAGE = Path(__file__).resolve().parents[1]
ADAPTER_PATH = PACKAGE / "adapters" / "generic_tool_loop.py"
RESULT_KEYS = (
    "route_summary",
    "target_paths",
    "cookbook_refs",
    "command_templates",
    "guidance",
    "delegated_input",
)


def load_adapter():
    spec = importlib.util.spec_from_file_location("capi_adapter", ADAPTER_PATH)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"cannot load {ADAPTER_PATH}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class ExecuteRegressionTests(unittest.TestCase):
    def setUp(self) -> None:
        self.adapter = load_adapter()
        self.calls = []

        def fake_run(command, check=False, **kwargs):
            self.calls.append({"command": list(command), "check": check, "kwargs": kwargs})
            return None

        self.patcher = patch("subprocess.run", fake_run)
        self.popen = patch("subprocess.Popen", side_effect=AssertionError("subprocess"))
        self.patcher.start()
        self.popen.start()
        self.original_templates = list(self.adapter.COMMAND_TEMPLATES)

    def tearDown(self) -> None:
        self.adapter.COMMAND_TEMPLATES = self.original_templates
        self.popen.stop()
        self.patcher.stop()

    def route(self, execute_present=True, execute=None, **extra):
        args = {"request": "route capi"}
        args.update(extra)
        if execute_present:
            args["execute"] = execute
        return self.adapter.TOOL_REGISTRY["capi__resolve_route"](args)

    def test_target_paths_exist_and_stay_route_only(self) -> None:
        result = self.route(False)
        self.assertEqual(tuple(result), RESULT_KEYS)
        self.assertIn("Route only", result["guidance"])
        self.assertNotIn("/Users/jon/.hermes", "\n".join(result["command_templates"]))
        for rel in result["target_paths"] + result["cookbook_refs"]:
            self.assertTrue((PACKAGE / rel).is_file(), rel)
        for template in result["command_templates"]:
            script = template.split()[1]
            self.assertTrue((PACKAGE / script).is_file(), script)
        self.assertEqual(self.calls, [])

    def test_false_shapes_never_run_and_keep_result_keys(self) -> None:
        self.adapter.COMMAND_TEMPLATES = ["bash scripts/capi-test.sh literal; rm"]
        cases = [
            ("actual false", True, False),
            ("string false", True, "false"),
            ("string False", True, "False"),
            ("padded false", True, " false "),
            ("omitted", False, None),
            ("empty string", True, ""),
        ]
        for name, present, value in cases:
            with self.subTest(name=name):
                self.calls.clear()
                result = self.route(present, value)
                self.assertEqual(tuple(result), RESULT_KEYS)
                self.assertIs(result["delegated_input"]["execute"], False)
                self.assertEqual(self.calls, [])

    def test_explicit_true_remains_route_only(self) -> None:
        self.adapter.COMMAND_TEMPLATES = ["bash scripts/capi-test.sh nope --limit"]
        for value in (True, "true", "TRUE", " true "):
            with self.subTest(value=value):
                self.calls.clear()
                result = self.route(True, value)
                self.assertIs(result["delegated_input"]["execute"], True)
                self.assertEqual(tuple(result), RESULT_KEYS)
                self.assertEqual(self.calls, [])

    def test_malformed_values_reject_without_subprocess(self) -> None:
        self.adapter.COMMAND_TEMPLATES = ["bash scripts/capi-test.sh should-not-run"]
        for value in (0, 1, "yes", "no", "1", "0", [], {}, "truefalse", "  "):
            with self.subTest(value=value):
                self.calls.clear()
                with self.assertRaises(ValueError):
                    self.route(True, value)
                self.assertEqual(self.calls, [])

    def test_workflow_preserves_status_and_failure_keys(self) -> None:
        sai_root = Path.home() / ".agents"
        if str(sai_root) not in sys.path:
            sys.path.insert(0, str(sai_root))
        try:
            from tools.skill_runtime.contract import load_contract
            from tools.skill_runtime.engine import GenericToolAdapter, SkillRuntime
        except ModuleNotFoundError:
            self.skipTest("Optional legacy tools.skill_runtime is not installed")

        contract = load_contract(PACKAGE / "workflow.yaml")
        self.assertEqual(contract["name"], "capi")
        self.assertEqual(contract["steps"]["resolve_route"]["tool"], "capi__resolve_route")
        runtime = SkillRuntime(
            GenericToolAdapter(self.adapter.TOOL_REGISTRY),
            sleep_fn=lambda _seconds: None,
            max_steps=10,
        )
        disabled = runtime.run(contract, {"request": "sample", "execute": "false"})
        self.assertEqual(disabled.status, "success")
        self.assertEqual(disabled.output["skill"], "capi")
        self.assertIs(disabled.output["delegated_input"]["execute"], False)
        self.assertEqual(
            set(disabled.output),
            {
                "skill",
                "request",
                "route_summary",
                "target_paths",
                "cookbook_refs",
                "command_templates",
                "guidance",
                "delegated_input",
            },
        )
        self.assertEqual(self.calls, [])

        rejected = runtime.run(contract, {"request": "sample", "execute": "no"})
        self.assertEqual(rejected.status, "failed")
        self.assertEqual(set(rejected.output), {"skill", "request", "error"})
        self.assertEqual(rejected.output["error"], "route resolution failed")
        self.assertEqual(self.calls, [])


if __name__ == "__main__":
    unittest.main()
