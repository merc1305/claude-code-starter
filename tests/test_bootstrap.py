"""Exercise the real bootstrap with local Git and a non-network GitHub double."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
REAL_GIT = shutil.which('git')


class BootstrapTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.tmp = tempfile.TemporaryDirectory()
        cls.addClassCleanup(cls.tmp.cleanup)
        cls.base = Path(cls.tmp.name)
        cls.source = cls.base / 'source'
        shutil.copytree(ROOT, cls.source, ignore=shutil.ignore_patterns('.git', '__pycache__', '*.pyc'))
        cls.env = dict(os.environ, GIT_CONFIG_GLOBAL=os.devnull, GIT_CONFIG_NOSYSTEM='1',
                       GIT_AUTHOR_NAME='Starter Test', GIT_AUTHOR_EMAIL='starter@example.invalid',
                       GIT_COMMITTER_NAME='Starter Test', GIT_COMMITTER_EMAIL='starter@example.invalid')
        for args in (['init', '-q', '-b', 'main'], ['add', '-A'], ['commit', '-qm', 'Test fixture']):
            subprocess.run([REAL_GIT, *args], cwd=cls.source, env=cls.env, check=True,
                           capture_output=True)
        cls.sha = subprocess.check_output([REAL_GIT, 'rev-parse', 'HEAD'], cwd=cls.source).decode().strip()
        cls.bin = cls.base / 'bin'
        cls.bin.mkdir()
        shim = '''#!PYTHON
import json, os, subprocess, sys
from pathlib import Path
kind = Path(sys.argv[0]).name
args = sys.argv[1:]
with open(os.environ['TEST_EVENTS'], 'a') as log:
    log.write(json.dumps([kind, *args]) + '\\n')
mode = os.environ.get('TEST_FAILURE', '')
if kind == 'git':
    if args and args[0] == 'clone':
        expected = 'git@github.com:merc1305/claude-code-starter.git'
        if expected not in args: sys.exit(90)
        args[args.index(expected)] = Path(os.environ['TEST_SOURCE']).as_uri()
    if args and args[0] == 'push': sys.exit(1 if mode == 'push' else 0)
    sys.exit(subprocess.call([os.environ['TEST_REAL_GIT'], *args]))
if args[:2] == ['auth', 'status']: sys.exit(1 if mode == 'auth' else 0)
if args[:2] == ['api', 'user']: print('test-owner'); sys.exit(0)
if args[:2] == ['repo', 'create']: sys.exit(1 if mode == 'create' else 0)
if args[:2] == ['repo', 'view']:
    if '--json' in args:
        print('PUBLIC' if mode == 'public' else 'PRIVATE'); sys.exit(0)
    sys.exit(1)
sys.exit(91)
'''.replace('PYTHON', sys.executable)
        for name in ('git', 'gh'):
            p = cls.bin / name
            p.write_text(shim)
            p.chmod(0o755)

    def setUp(self):
        self.case = Path(tempfile.mkdtemp(dir=self.base))
        self.target = self.case / 'company with spaces'
        self.log = self.case / 'events.jsonl'

    def run_bootstrap(self, *args, failure=''):
        env = dict(self.env, PATH=str(self.bin) + os.pathsep + os.environ['PATH'],
                   TEST_EVENTS=str(self.log), TEST_SOURCE=str(self.source),
                   TEST_REAL_GIT=REAL_GIT, TEST_FAILURE=failure)
        return subprocess.run(['bash', str(ROOT / 'scripts/bootstrap-new-project.sh'),
                               str(self.target), 'sample-company', *args],
                              env=env, capture_output=True, text=True)

    def events(self):
        return [json.loads(line) for line in self.log.read_text().splitlines()] if self.log.exists() else []

    def test_local_bootstrap_preserves_company_contract(self):
        result = self.run_bootstrap('--no-remote')
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertFalse(any(e[0] == 'gh' or e[:2] == ['git', 'push'] for e in self.events()))
        for name in ('LICENSE', 'AGENTS.md', 'CLAUDE.md', 'docs/workflow.md',
                     'scripts/check_secrets.py', '.claude/commands/plan.md', '.business/INDEX.md'):
            self.assertTrue((self.target / name).is_file(), name)
        self.assertFalse((self.target / 'scripts/bootstrap-new-project.sh').exists())
        self.assertFalse((self.target / 'tests/test_bootstrap.py').exists())
        provenance = json.loads((self.target / '.starter/provenance.json').read_text())
        self.assertEqual(provenance, {'repository': 'merc1305/claude-code-starter', 'commit': self.sha})
        self.assertEqual(subprocess.check_output([REAL_GIT, 'rev-list', '--count', 'HEAD'], cwd=self.target).strip(), b'2')
        self.assertEqual(subprocess.check_output([REAL_GIT, 'status', '--porcelain'], cwd=self.target), b'')
        self.assertTrue(subprocess.check_output([REAL_GIT, 'ls-files', '--', '.business/INDEX.md'], cwd=self.target))
        self.assertEqual(subprocess.run([REAL_GIT, 'check-ignore', '--no-index', '-q', '.business/INDEX.md'], cwd=self.target).returncode, 1)
        scan = subprocess.run([sys.executable, 'scripts/check_secrets.py', '--tracked'], cwd=self.target, capture_output=True)
        self.assertEqual(scan.returncode, 0, scan.stdout)

    def test_remote_creation_verifies_private_before_push(self):
        result = self.run_bootstrap()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        events = self.events()
        create = next(i for i,e in enumerate(events) if e[:3] == ['gh', 'repo', 'create'])
        verify = next(i for i,e in enumerate(events) if e[:3] == ['gh', 'repo', 'view'] and '--json' in e)
        push = next(i for i,e in enumerate(events) if e[:2] == ['git', 'push'])
        self.assertIn('--private', events[create])
        self.assertNotIn('--push', events[create])
        self.assertLess(create, verify)
        self.assertLess(verify, push)

    def test_public_or_failed_create_never_pushes(self):
        for failure in ('public', 'create'):
            with self.subTest(failure=failure):
                self.target = self.case / failure
                self.log = self.case / (failure + '.jsonl')
                result = self.run_bootstrap(failure=failure)
                self.assertNotEqual(result.returncode, 0)
                self.assertNotIn('Готово:', result.stdout)
                self.assertFalse(any(e[:2] == ['git', 'push'] for e in self.events()))

    def test_auth_failure_has_no_project_side_effects(self):
        result = self.run_bootstrap(failure='auth')
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(self.target.exists())
        self.assertFalse(any(e[:2] == ['git', 'clone'] for e in self.events()))

    def test_push_failure_is_not_success(self):
        result = self.run_bootstrap(failure='push')
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn('Готово:', result.stdout)

    def test_existing_destination_is_untouched(self):
        self.target.mkdir()
        (self.target / 'keep.txt').write_text('existing work')
        result = self.run_bootstrap('--no-remote')
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(list(self.target.iterdir()), [self.target / 'keep.txt'])
        self.assertEqual((self.target / 'keep.txt').read_text(), 'existing work')


if __name__ == '__main__':
    unittest.main()
