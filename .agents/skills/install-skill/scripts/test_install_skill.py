import json
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).with_name("install_skill.py")
SKILL = "---\nname: demo-skill\ndescription: A demo skill\n---\n\n# Demo\n"


def run(cwd, home, *args):
    env = {**os.environ, "HOME": str(home), "USERPROFILE": str(home)}
    proc = subprocess.run([sys.executable, str(SCRIPT), *args], cwd=cwd, env=env, capture_output=True, text=True)
    return proc.returncode, json.loads(proc.stdout)


class InstallSkillTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        root = Path(self.tmp.name)
        self.repo, self.home, self.src = root / "repo", root / "home", root / "src" / "demo-skill"
        for d in (self.repo, self.home, self.src):
            d.mkdir(parents=True)
        subprocess.run(["git", "init", "-q"], cwd=self.repo, check=True)
        (self.src / "SKILL.md").write_text(SKILL, encoding="utf-8")
        (self.src / "extra.txt").write_text("asset", encoding="utf-8")

    def tearDown(self):
        self.tmp.cleanup()

    def test_project_install_writes_both_targets(self):
        code, _ = run(self.repo, self.home, "install", str(self.src))
        self.assertEqual(code, 0)
        for t in (".agents/skills", ".claude/skills"):
            self.assertEqual((self.repo / t / "demo-skill" / "SKILL.md").read_text(encoding="utf-8"), SKILL)
            self.assertTrue((self.repo / t / "demo-skill" / "extra.txt").is_file())
        self.assertFalse((self.home / ".agents").exists())

    def test_global_install_writes_core_targets_only(self):
        code, _ = run(self.repo, self.home, "install", str(self.src), "--scope", "global")
        self.assertEqual(code, 0)
        for t in (".agents/skills", ".claude/skills", ".cursor/skills", ".gemini/antigravity-cli/skills"):
            self.assertTrue((self.home / t / "demo-skill" / "SKILL.md").is_file(), t)
        self.assertFalse((self.home / ".copilot").exists())
        self.assertFalse((self.repo / ".agents").exists())

    def test_dry_run_writes_nothing(self):
        code, out = run(self.repo, self.home, "install", str(self.src), "--dry-run")
        self.assertEqual(code, 0)
        self.assertTrue(out["dry_run"])
        self.assertFalse((self.repo / ".agents").exists())

    def test_differing_target_is_not_overwritten_without_force(self):
        run(self.repo, self.home, "install", str(self.src))
        edited = self.repo / ".claude/skills/demo-skill/extra.txt"
        edited.write_text("local edit", encoding="utf-8")
        code, out = run(self.repo, self.home, "install", str(self.src))
        self.assertEqual(code, 1)
        self.assertFalse(out["ok"])
        self.assertEqual(edited.read_text(encoding="utf-8"), "local edit")
        code, _ = run(self.repo, self.home, "install", str(self.src), "--force")
        self.assertEqual(code, 0)
        self.assertEqual(edited.read_text(encoding="utf-8"), "asset")

    def test_rejects_invalid_name_and_missing_frontmatter(self):
        (self.src / "SKILL.md").write_text("---\nname: ../evil\ndescription: x\n---\n", encoding="utf-8")
        code, out = run(self.repo, self.home, "install", str(self.src))
        self.assertEqual(code, 2)
        self.assertFalse(out["ok"])
        (self.src / "SKILL.md").write_text("# no frontmatter", encoding="utf-8")
        code, _ = run(self.repo, self.home, "install", str(self.src))
        self.assertEqual(code, 2)
        self.assertFalse((self.repo / ".agents").exists())

    def test_sync_copies_missing_skill_between_targets(self):
        agents = self.repo / ".agents/skills/demo-skill"
        agents.mkdir(parents=True)
        (agents / "SKILL.md").write_text(SKILL, encoding="utf-8")
        code, _ = run(self.repo, self.home, "sync")
        self.assertEqual(code, 0)
        self.assertEqual((self.repo / ".claude/skills/demo-skill/SKILL.md").read_text(encoding="utf-8"), SKILL)

    def test_multi_skill_source_requires_skill_flag(self):
        multi = self.src.parent / "multi"
        for n in ("one", "two"):
            (multi / n).mkdir(parents=True)
            (multi / n / "SKILL.md").write_text(SKILL.replace("demo-skill", n), encoding="utf-8")
        code, _ = run(self.repo, self.home, "install", str(multi))
        self.assertEqual(code, 2)
        code, out = run(self.repo, self.home, "install", str(multi), "--skill", "two")
        self.assertEqual(code, 0)
        self.assertEqual(out["skill"], "two")


if __name__ == "__main__":
    unittest.main()
