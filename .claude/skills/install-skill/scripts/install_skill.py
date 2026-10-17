#!/usr/bin/env python3
"""Install an Agent Skill into every CLI skill directory at once (stdlib only).

Commands:
  install <source>   copy a skill (local dir, owner/repo[/subpath], or git URL)
  sync               mirror skills that exist in one target but not in another
  list               show the skills found in each target

Project scope targets (default): .agents/skills, .claude/skills
Global scope targets:            ~/.agents/skills, ~/.claude/skills, ~/.cursor/skills,
                                 ~/.gemini/antigravity-cli/skills, plus the optional
                                 directories below when they already exist.
"""
import argparse
import hashlib
import json
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

NAME_RE = re.compile(r"^[a-z0-9][a-z0-9-]{0,63}$")
REPO_RE = re.compile(r"^[\w.-]+/[\w.-]+(/[\w./-]+)?$")
PROJECT_TARGETS = [".agents/skills", ".claude/skills"]
GLOBAL_CORE = [".agents/skills", ".claude/skills", ".cursor/skills", ".gemini/antigravity-cli/skills"]
GLOBAL_OPTIONAL = [".config/opencode/skills", ".gemini/skills", ".gemini/antigravity/skills", ".copilot/skills"]


def project_root() -> Path:
    try:
        out = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True, text=True, check=True)
        return Path(out.stdout.strip())
    except (OSError, subprocess.CalledProcessError):
        return Path.cwd()


def targets(scope: str) -> list[Path]:
    found = []
    if scope in ("project", "all"):
        root = project_root()
        found += [root / t for t in PROJECT_TARGETS]
    if scope in ("global", "all"):
        home = Path.home()
        found += [home / t for t in GLOBAL_CORE]
        found += [home / t for t in GLOBAL_OPTIONAL if (home / t).is_dir()]
    return found


def frontmatter(skill_md: Path) -> dict:
    text = skill_md.read_text(encoding="utf-8")
    if not text.startswith("---"):
        raise ValueError(f"{skill_md}: missing YAML frontmatter")
    block = text.split("---", 2)
    if len(block) < 3:
        raise ValueError(f"{skill_md}: unterminated frontmatter")
    data = {}
    for line in block[1].splitlines():
        m = re.match(r"^([A-Za-z_-]+):\s*(.*)$", line)
        if m:
            data[m.group(1)] = m.group(2).strip().strip("\"'")
    return data


def validate(skill_dir: Path) -> dict:
    skill_md = skill_dir / "SKILL.md"
    if not skill_md.is_file():
        raise ValueError(f"{skill_dir}: no SKILL.md")
    meta = frontmatter(skill_md)
    for key in ("name", "description"):
        if not meta.get(key):
            raise ValueError(f"{skill_md}: frontmatter lacks '{key}'")
    if not NAME_RE.match(meta["name"]):
        raise ValueError(f"invalid skill name '{meta['name']}' (use lowercase letters, digits, hyphens)")
    return meta


def tree_hash(path: Path) -> str:
    digest = hashlib.sha256()
    for f in sorted(p for p in path.rglob("*") if p.is_file() and ".git" not in p.relative_to(path).parts):
        digest.update(str(f.relative_to(path).as_posix()).encode())
        digest.update(f.read_bytes())
    return digest.hexdigest()


def copy_skill(src: Path, dest: Path, force: bool, dry_run: bool) -> str:
    if dest.exists():
        if tree_hash(src) == tree_hash(dest):
            return "unchanged"
        if not force:
            return "differs (use --force to overwrite)"
        action = "replaced"
    else:
        action = "installed"
    if not dry_run:
        if dest.exists():
            shutil.rmtree(dest)
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.copytree(src, dest, ignore=lambda d, names: [n for n in names if n == ".git" or (Path(d) / n).is_symlink()])
    return ("would be " + action) if dry_run else action


def resolve_source(source: str, subpath: str | None, workdir: Path) -> Path:
    local = Path(source).expanduser()
    if local.exists():
        base = local.resolve()
    elif source.startswith(("http://", "https://", "git@")) or REPO_RE.match(source):
        repo, inner = source, None
        if REPO_RE.match(source) and not source.startswith(("http", "git@")):
            parts = source.split("/")
            repo, inner = "/".join(parts[:2]), "/".join(parts[2:]) or None
            repo = f"https://github.com/{repo}.git"
        dest = workdir / "clone"
        subprocess.run(["git", "clone", "--depth", "1", repo, str(dest)], check=True, capture_output=True, text=True)
        base = dest / inner if inner else dest
        if subpath:
            base = base / subpath
    else:
        raise ValueError(f"source not found and not a git reference: {source}")
    if local.exists() and subpath:
        base = base / subpath
    return base


def pick_skill(base: Path, name: str | None) -> Path:
    if (base / "SKILL.md").is_file():
        return base
    candidates = sorted(p.parent for p in base.rglob("SKILL.md") if ".git" not in p.parts)
    if name:
        match = [c for c in candidates if c.name == name]
        if len(match) == 1:
            return match[0]
        raise ValueError(f"skill '{name}' not found under {base}")
    if len(candidates) == 1:
        return candidates[0]
    names = ", ".join(c.name for c in candidates) or "none"
    raise ValueError(f"{base} holds several skills ({names}); pass --skill NAME")


def cmd_install(args) -> int:
    tgts = targets(args.scope)
    with tempfile.TemporaryDirectory() as tmp:
        try:
            skill_dir = pick_skill(resolve_source(args.source, args.subpath, Path(tmp)), args.skill)
            meta = validate(skill_dir)
        except (ValueError, subprocess.CalledProcessError) as exc:
            detail = exc.stderr.strip() if isinstance(exc, subprocess.CalledProcessError) and exc.stderr else exc
            print(json.dumps({"ok": False, "error": str(detail)}))
            return 2
        results = {str(t / meta["name"]): copy_skill(skill_dir, t / meta["name"], args.force, args.dry_run) for t in tgts}
    blocked = [k for k, v in results.items() if v.startswith("differs")]
    print(json.dumps({"ok": not blocked, "skill": meta["name"], "description": meta["description"], "dry_run": args.dry_run, "targets": results}, indent=2))
    return 1 if blocked else 0


def skills_in(target: Path) -> dict[str, Path]:
    if not target.is_dir():
        return {}
    return {p.name: p for p in sorted(target.iterdir()) if (p / "SKILL.md").is_file()}


def cmd_sync(args) -> int:
    tgts = targets(args.scope)
    inventory = {t: skills_in(t) for t in tgts}
    names = sorted({n for found in inventory.values() for n in found})
    report, conflict = {}, False
    for name in names:
        owners = [(t, found[name]) for t, found in inventory.items() if name in found]
        source = owners[0][1]
        for t in tgts:
            dest = t / name
            if dest == source:
                continue
            outcome = copy_skill(source, dest, args.force, args.dry_run)
            conflict |= outcome.startswith("differs")
            if outcome != "unchanged":
                report[str(dest)] = outcome
    print(json.dumps({"ok": not conflict, "dry_run": args.dry_run, "changes": report}, indent=2))
    return 1 if conflict else 0


def cmd_list(args) -> int:
    print(json.dumps({str(t): sorted(skills_in(t)) for t in targets(args.scope)}, indent=2))
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest="command", required=True)
    for name in ("install", "sync", "list"):
        p = sub.add_parser(name)
        p.add_argument("--scope", choices=["project", "global", "all"], default="project")
        if name != "list":
            p.add_argument("--force", action="store_true", help="overwrite a target whose content differs")
            p.add_argument("--dry-run", action="store_true", help="report what would change without writing")
        if name == "install":
            p.add_argument("source", help="local dir, owner/repo[/subpath], or git URL")
            p.add_argument("--skill", help="skill folder name when the source holds several")
            p.add_argument("--subpath", help="folder inside the source that holds the skill")
    args = parser.parse_args()
    return {"install": cmd_install, "sync": cmd_sync, "list": cmd_list}[args.command](args)


if __name__ == "__main__":
    sys.exit(main())
