"""Exercise actual documentation recipes offline; never use accounts or providers."""
import contextlib
import io
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch
from urllib.parse import quote

ROOT = Path(__file__).resolve().parents[1]
PASSWORD = 'synthetic-app-password-7f8b'
KEY = 'synthetic-inbound-key-2dd4'

def fences(relative, language='bash'):
    text = (ROOT / relative).read_text()
    return re.findall(r'^```' + language + r'\n(.*?)^```\s*$', text, re.M | re.S)

def notebook_code():
    block = next(s for s in fences('references/open-notebook-capi-oauth-integration.md') if "python3 - <<'PY'" in s)
    return block.split("python3 - <<'PY'\n", 1)[1].rsplit('\nPY', 1)[0]

class Response:
    def __init__(self, payload, status=200):
        self.status = status
        self.raw = payload if isinstance(payload, bytes) else json.dumps(payload).encode()
    def __enter__(self):
        return self
    def __exit__(self, *args):
        return False
    def read(self, limit):
        return self.raw[:limit]

class Opener:
    def __init__(self, responses):
        self.responses = responses
        self.requests = []
    def open(self, req, timeout):
        self.requests.append((req, timeout))
        value = self.responses[len(self.requests) - 1]
        if isinstance(value, Exception):
            raise value
        return value

class NotebookTests(unittest.TestCase):
    def execute(self, responses, env=None):
        opener = Opener(responses)
        variables = {'OPEN_NOTEBOOK_PASSWORD': PASSWORD, 'CAPI_API_KEY': KEY}
        variables.update(env or {})
        stdout, stderr = io.StringIO(), io.StringIO()
        namespace = {'__name__': '__main__'}
        exit_code = 0
        with patch.dict(os.environ, variables, clear=True), patch('urllib.request.build_opener', return_value=opener), patch('subprocess.Popen', side_effect=AssertionError('subprocess forbidden')), contextlib.redirect_stdout(stdout), contextlib.redirect_stderr(stderr):
            try:
                exec(compile(notebook_code(), '<documented-notebook-recipe>', 'exec'), namespace)
            except SystemExit as exc:
                exit_code = exc.code
        output = stdout.getvalue() + stderr.getvalue()
        for secret in [PASSWORD, KEY]:
            self.assertNotIn(secret, output)
            self.assertNotIn(secret, ' '.join(sys.argv))
        return opener, exit_code, output, namespace

    def good(self, cid='credential:/A ?#%ü'):
        return [Response({'id': cid}), Response({'success': True}), Response({'models': []}), Response({'id': 'model:1'})]

    def test_valid_exact_id_and_credentials_only_in_expected_headers_body(self):
        cid = 'credential:/A ?#%ü'
        op, code, output, _ = self.execute(self.good(cid))
        self.assertEqual(code, 0)
        self.assertEqual(len(op.requests), 4)
        self.assertNotIn(cid, output)
        for i, (req, timeout) in enumerate(op.requests):
            self.assertEqual(timeout, 20)
            self.assertEqual(req.get_header('Authorization'), 'Bearer ' + PASSWORD)
            self.assertNotIn(KEY, str(req.headers))
            self.assertNotIn(PASSWORD, req.full_url)
            self.assertNotIn(KEY, req.full_url)
            self.assertNotIn(PASSWORD.encode(), req.data)
            self.assertEqual(KEY.encode() in req.data, i == 0)
        self.assertTrue(op.requests[1][0].full_url.endswith('/credentials/' + quote(cid, safe='') + '/test'))
        self.assertTrue(op.requests[2][0].full_url.endswith('/credentials/' + quote(cid, safe='') + '/discover'))
        self.assertEqual(json.loads(op.requests[3][0].data)['credential'], cid)
        self.assertEqual(json.loads(op.requests[0][0].data)['api_key'], KEY)

    def test_each_http_failure_stops_without_retry_or_later_effects(self):
        for stage in range(4):
            with self.subTest(stage=stage):
                responses = self.good(); responses[stage] = Response({'error': PASSWORD + KEY}, 500)
                op, code, _, _ = self.execute(responses)
                self.assertEqual(code, 1); self.assertEqual(len(op.requests), stage + 1)

    def test_each_malformed_response_stops_without_retry(self):
        for stage in range(4):
            with self.subTest(stage=stage):
                responses = self.good(); responses[stage] = Response((PASSWORD + KEY).encode())
                op, code, _, _ = self.execute(responses)
                self.assertEqual(code, 1); self.assertEqual(len(op.requests), stage + 1)

    def test_each_timeout_stops_and_sanitizes_exception(self):
        for stage in range(4):
            with self.subTest(stage=stage):
                responses = self.good(); responses[stage] = TimeoutError(PASSWORD + KEY)
                op, code, _, _ = self.execute(responses)
                self.assertEqual(code, 1); self.assertEqual(len(op.requests), stage + 1)

    def test_redirect_statuses_stop_without_followup(self):
        for status in [301, 302, 303, 307, 308]:
            op, code, _, _ = self.execute([Response({}, status)])
            self.assertEqual(code, 1); self.assertEqual(len(op.requests), 1)

    def test_redirect_handler_refuses_target(self):
        _, _, _, namespace = self.execute(self.good())
        with self.assertRaises(namespace['RecipeStopped']):
            namespace['NoRedirects']().redirect_request(None, None, 302, '', {}, 'https://other.example/' + KEY)

    def test_missing_invalid_and_dot_ids_stop(self):
        for cid in [None, '', ' ', 123, '.', '..', 'x\ny']:
            with self.subTest(cid=cid):
                op, code, _, _ = self.execute([Response({'id': cid})])
                self.assertEqual(code, 1); self.assertEqual(len(op.requests), 1)
        responses = self.good(); responses[-1] = Response({})
        op, code, _, _ = self.execute(responses)
        self.assertEqual(code, 1); self.assertEqual(len(op.requests), 4)

    def test_oversize_stops(self):
        for stage in range(4):
            responses = self.good(); responses[stage] = Response(b'x' * (1024 * 1024 + 1))
            op, code, _, _ = self.execute(responses)
            self.assertEqual(code, 1); self.assertEqual(len(op.requests), stage + 1)

    def test_explicit_rejection_or_unknown_step_schema_stops(self):
        for stage, payload in [(0, []), (1, {}), (1, {'success': False}), (2, {}), (2, {'models': 'wrong'}), (3, {'error': KEY})]:
            responses = self.good(); responses[stage] = Response(payload)
            op, code, _, _ = self.execute(responses)
            self.assertEqual(code, 1); self.assertEqual(len(op.requests), stage + 1)

    def test_invalid_local_setup_has_no_requests(self):
        for env in [{'OPEN_NOTEBOOK_PASSWORD': ''}, {'CAPI_API_KEY': ''}, {'CAPI_MODEL': ''}, {'CAPI_API_KEY': 'sk-dummy'}, {'OPEN_NOTEBOOK_API': 'http://remote.example/api'}, {'CAPI_BASE_URL': 'http://remote.example/v1'}, {'OPEN_NOTEBOOK_API': 'https://user:password@example/api'}, {'CAPI_BASE_URL': 'https://example/v1?token=' + KEY}, {'OPEN_NOTEBOOK_API': 'https://example/\napi'}]:
            op, code, _, _ = self.execute([], env)
            self.assertEqual(code, 1); self.assertEqual(op.requests, [])

    def test_loopback_http_remains_supported(self):
        op, code, _, _ = self.execute(self.good(), {'CAPI_BASE_URL': 'http://127.0.0.1:8317/v1', 'CAPI_API_KEY': 'sk-dummy'})
        self.assertEqual(code, 0)
        self.assertEqual(json.loads(op.requests[0][0].data)['base_url'], 'http://127.0.0.1:8317/v1')

class ShellRecipeTests(unittest.TestCase):
    def shell(self, recipe, catalog=None, curl_fail=False, endpoint='https://llm-proxy.genr8ive.ai'):
        if not shutil.which('bash') or not shutil.which('jq'):
            self.skipTest('Existing bash and jq are required for CAPI shell recipes')
        with tempfile.TemporaryDirectory(prefix='capi-doc-fixture-') as directory:
            tmp = Path(directory)
            fake = tmp / 'curl'
            fake.write_text('#!' + sys.executable + '\nimport json,os,sys\nfrom pathlib import Path\nPath(os.environ["RECIPE_CAPTURE"]).open("a").write(json.dumps({"argv":sys.argv[1:],"stdin":sys.stdin.read()})+"\\n")\nif os.environ.get("RECIPE_CURL_FAIL")=="1":sys.exit(22)\nprint(os.environ["RECIPE_CATALOG"])\n')
            fake.chmod(0o755)
            env = dict(os.environ, PATH=str(tmp) + os.pathsep + os.environ.get('PATH', ''), CAPI_API_KEY=KEY, CAPI_URL=endpoint, RECIPE_CAPTURE=str(tmp/'capture.jsonl'), RECIPE_CATALOG=json.dumps(catalog or {'data': []}), RECIPE_CURL_FAIL='1' if curl_fail else '0')
            result = subprocess.run(['bash', '-c', recipe], cwd=ROOT, env=env, capture_output=True, text=True, timeout=10)
            captures = [json.loads(s) for s in (tmp/'capture.jsonl').read_text().splitlines()] if (tmp/'capture.jsonl').exists() else []
            self.assertNotIn(KEY, result.stdout + result.stderr)
            for row in captures:
                self.assertNotIn(KEY, ' '.join(row['argv']))
                self.assertIn(KEY, row['stdin'])
            return result, captures

    def test_catalog_owner_grouping_unknown_owner_and_filter(self):
        recipe = fences('cookbook/sdk-integration.md')[-1]
        catalog = {'data': [{'id': 'opus-1', 'owned_by': 'vendor-a'}, {'id': 'model-z'}, {'id': 'model-b', 'owned_by': 'vendor-a'}]}
        result, captures = self.shell(recipe, catalog)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('unknown: 1 models', result.stdout)
        self.assertIn('vendor-a: 2 models', result.stdout)
        self.assertTrue(result.stdout.endswith('opus-1\n'))
        self.assertEqual(len(captures), 3)

    def test_failed_catalog_pipeline_is_failure(self):
        for relative in ['guide.md', 'cookbook/sdk-integration.md', 'references/hermes-workspace-custom-provider.md']:
            recipes = [s for s in fences(relative) if 'scripts/capi-models.sh' in s]
            self.assertTrue(recipes)
            for recipe in recipes:
                result, _ = self.shell(recipe, curl_fail=True)
                self.assertNotEqual(result.returncode, 0)

    def test_exact_image_preflight_and_selected_endpoint(self):
        recipe = next(s for s in fences('references/gpt-image-2-reference-edits.md') if 'models=$(' in s)
        for ids, expected in [(['gpt-image-2'], 0), (['gpt-image-2.5-flare', 'prefix-gpt-image-2'], 1), ([], 1)]:
            result, captures = self.shell(recipe, {'data': [{'id': x} for x in ids]}, endpoint='https://selected.example')
            self.assertEqual(result.returncode, expected, result.stderr)
            self.assertEqual(len(captures), 1)
            self.assertIn('https://selected.example/v1/models', captures[0]['argv'])
        result, _ = self.shell(recipe, curl_fail=True)
        self.assertNotEqual(result.returncode, 0)

    def test_invalid_authentication_does_not_print_key(self):
        recipe = fences('cookbook/sdk-integration.md')[-1]
        result, captures = self.shell(recipe, endpoint='http://remote.example')
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(captures, [])

    def test_changed_bash_fences_parse_and_no_prose_inside(self):
        for relative in ['guide.md', 'cookbook/sdk-integration.md', 'references/hermes-workspace-custom-provider.md', 'references/open-notebook-capi-oauth-integration.md', 'references/gpt-image-2-reference-edits.md']:
            for i, recipe in enumerate(fences(relative)):
                self.assertFalse(any(line.startswith('> **GPT Image') for line in recipe.splitlines()))
                result = subprocess.run(['bash', '-n'], input=recipe, text=True, capture_output=True)
                self.assertEqual(result.returncode, 0, (relative, i, result.stderr))

    def test_quota_and_schema_limits_are_explicit(self):
        guide = (ROOT/'guide.md').read_text()
        self.assertIn('`scripts/capi-test.sh` sends a completion request and consumes provider quota', guide)
        notebook = (ROOT/'references/open-notebook-capi-oauth-integration.md').read_text()
        self.assertIn('not a verified contract', notebook)
        self.assertIn('schema', notebook)
        self.assertIn('Reconcile app state before another create', notebook)
        self.assertIn('provider quota', notebook)

if __name__ == '__main__':
    unittest.main()
