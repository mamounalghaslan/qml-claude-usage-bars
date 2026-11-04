import importlib.machinery
import importlib.util
import os
import unittest

SCRIPT = os.path.join(os.path.dirname(__file__), "..", "scripts", "claude-usage-fetch")
loader = importlib.machinery.SourceFileLoader("claude_usage_fetch", SCRIPT)
spec = importlib.util.spec_from_loader("claude_usage_fetch", loader)
fetch = importlib.util.module_from_spec(spec)
loader.exec_module(fetch)

RESET = "2026-11-06T09:59:59+00:00"


def limit(kind, percent, model=None):
    scope = {"model": {"id": None, "display_name": model}} if model else None
    return {"kind": kind, "percent": percent, "resets_at": RESET, "scope": scope}


class ParseUsage(unittest.TestCase):
    def test_weekly_and_fable(self):
        payload = {"limits": [limit("weekly_all", 55), limit("weekly_scoped", 52, "Fable")]}
        parsed = fetch.parse_usage(payload)
        self.assertEqual(parsed["weekly"], {"percent": 55, "resets_at": RESET})
        self.assertEqual(parsed["fable"], {"percent": 52, "resets_at": RESET})

    def test_other_scoped_models_are_ignored(self):
        payload = {"limits": [limit("weekly_all", 10), limit("weekly_scoped", 90, "Sonnet")]}
        self.assertIsNone(fetch.parse_usage(payload)["fable"])

    def test_weekly_falls_back_to_seven_day(self):
        payload = {"seven_day": {"utilization": 40.0, "resets_at": RESET}, "limits": []}
        self.assertEqual(fetch.parse_usage(payload)["weekly"], {"percent": 40.0, "resets_at": RESET})

    def test_empty_payload(self):
        self.assertEqual(fetch.parse_usage({}), {"weekly": None, "fable": None})


if __name__ == "__main__":
    unittest.main()
