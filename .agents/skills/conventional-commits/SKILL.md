---
name: conventional-commits
description: Write commit messages in Conventional Commits format. Use when the user asks to commit, write a commit message, or review commit history.
---

# Conventional Commits

## Format

```
<type>(<optional scope>): <short summary>

<optional body: what and why, not how>
```

## Rules

- Types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`.
- Summary: imperative mood, lowercase, no trailing period, 72 characters or fewer.
- Breaking changes: add `!` after the type or scope and a `BREAKING CHANGE:` footer.
- One logical change per commit. Keep tests and docs with the code they cover.
- Never add AI attribution or `Co-Authored-By` lines unless the project says otherwise.

## Examples

- `feat(auth): add password reset flow`
- `fix(api): handle empty response from payment provider`
- `docs: update setup instructions`
