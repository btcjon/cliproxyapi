#!/usr/bin/env python3
"""Contract tests for capi workflow."""

from __future__ import annotations

from pathlib import Path
import sys
import unittest

SAI_ROOT = Path.home() / ".agents"
if str(SAI_ROOT) not in sys.path:
    sys.path.insert(0, str(SAI_ROOT))

try:
    from tools.skill_runtime.contract import load_contract
    from tools.skill_runtime.engine import GenericToolAdapter, SkillRuntime
except ModuleNotFoundError:
    raise unittest.SkipTest("Optional legacy tools.skill_runtime is not installed")


class ContractValidationTests(unittest.TestCase):
    def _contract(self) -> dict:
        contract_path = Path(__file__).resolve().parents[1] / "workflow.yaml"
        return load_contract(contract_path)

    def test_contract_loads(self) -> None:
        contract = self._contract()
        self.assertEqual(contract["name"], "capi")

    def test_runtime_resolves_route(self) -> None:
        contract = self._contract()

        def resolver(_args: dict) -> dict:
            return {
                "route_summary": "Contract-first route resolver for capi.",
                "target_paths": ["SKILL.md"],
                "cookbook_refs": [],
                "command_templates": [],
                "guidance": "Use SKILL.md as primary source.",
                "delegated_input": {"request": "sample"},
            }

        runtime = SkillRuntime(
            GenericToolAdapter({'capi__resolve_route': resolver}),
            sleep_fn=lambda _seconds: None,
            max_steps=10,
        )

        result = runtime.run(contract, {"request": "sample"})
        self.assertEqual(result.status, "success")
        self.assertEqual(result.output["skill"], "capi")


if __name__ == "__main__":
    unittest.main()
