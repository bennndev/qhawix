---
name: research-routing
description: Decides which CLI and which model to use for research, given what the user has installed (Claude Code, Cursor CLI, AGY, Codex), and how to combine them with the research and web-search skills. Use when the user asks which model or agent is best for researching, which CLI to use for a research task, how to set up a research run, or how a teammate with Codex should research.
when_to_use: User asks "what should I use to research X", "which model is best for research", "who investigates this", or wants to launch a research run on a specific CLI/model. Skip for the research itself (use the research skill) and for plain web lookups (use web-search).
user-invocable: true
argument-hint: "[topic] [available CLIs]"
---

# Research Routing

Picks the CLI + model for a research task. The research itself always goes through the `research` skill (which calls `web-search` and stores findings in `.research/`); this skill only chooses who runs it.

Evidence as of 2026-10-17. Rankings come from third-party leaderboards and vendor-reported numbers, not from a bake-off on this repo; treat them as a starting point and re-check with the "Refresh" section when they age.

## Recommended models (best first)

| # | Model | Where to run it | Why | Evidence |
| --- | --- | --- | --- | --- |
| 1 | **GPT-5.6 Sol, extra-high effort** | Codex; Cursor CLI (`gpt-5.6-sol-xhigh`) | Top group on web-research benchmarks (BrowseComp) | ~92% on BenchLM and the Steel leaderboard; both are third-party trackers of mostly vendor-reported scores |
| 2 | **Claude Fable 5 / Opus 5, thinking high** | Claude Code (`--model fable` or `opus`); Cursor CLI (`claude-fable-5-thinking-high`, `claude-opus-5-thinking-high`) | Strong long-context synthesis; Claude Code has the native Agent tool the `research` skill spawns investigation subagents with (other hosts run the same phases inline, per that skill) | Opus 5 ~90.8% on BrowseComp (BenchLM); no research benchmark found for Fable 5, so it is ranked by tier, not by a measured score |
| 3 | **Gemini 3.8 Flash, high** | AGY (`gemini-3.8-flash-high`) | About 1M context and low cost per task; good for the bulk read and as an independent second opinion | Listed by `agy models`; Artificial Analysis data cited by a comparison page puts Opus 5.5 at ~4.8x its cost per task for 17 more intelligence points |

Ties and gaps are real: the top two differ by about 1 point on one tracker, which is within noise. Do not present #1 versus #2 as a proven difference.

## Routing by what the user has

1. **Has Codex** (teammates): primary researcher = GPT-5.6 Sol at extra-high effort; contrarian pass = Claude Code or Cursor on a Claude model.
2. **No Codex, has Claude Code + Cursor CLI** (the current setup): primary = Claude Code on Fable 5 or Opus 5 thinking, or Cursor CLI on `gpt-5.6-sol-xhigh` when the topic is web-heavy and fact-dense; contrarian pass = the other family.
3. **Only AGY**: Gemini 3.8 Flash high is the best listed there; say that coverage is weaker and require the contrarian pass to be done by hand.

Use a different model family for the contrarian pass than for the main investigation; two runs of the same model share blind spots.

## Launch commands

Run from the repo root so the project skills load.

| CLI | Command | Status |
| --- | --- | --- |
| Claude Code | `claude --model fable` (or `opus`) | flag confirmed in `claude --help` |
| Cursor CLI | `cursor-agent --model gpt-5.6-sol-xhigh` | flag confirmed in `--help`; on Windows the binary is `cursor-agent`, and `agent` may resolve to another tool (Grok) |
| AGY | `agy --model gemini-3.8-flash-high` | flag confirmed in `agy --help` |
| Codex | `codex -m gpt-5.6-sol -c model_reasoning_effort=xhigh` | NOT verified: Codex is not installed on the author's machine; check `codex --help` |

Then prompt: `/research <topic>` (Claude Code) or "use the research skill to investigate <topic>" elsewhere. Do not change a CLI's permission settings to make a run work.

## Workflow

1. Ask which CLIs the user has if unknown (one question), then pick the row above.
2. State the choice and its evidence level in one or two lines, including that the ranking is third-party.
3. Run the investigation with the research skill on the primary model.
4. Run the contrarian pass on a different family and compare conclusions; report disagreements instead of smoothing them over.
5. Confirm the findings landed in `.research/` before calling it done.

## Refresh

Model lists and rankings go stale. Before relying on this table, run:

- `cursor-agent --list-models`
- `agy models`
- `claude --help` (model aliases)

and check the BrowseComp trackers: https://benchlm.ai/benchmarks/browsecomp and https://leaderboard.steel.dev/leaderboards/browsecomp/. If a listed model no longer exists, say so and propose the closest replacement instead of using the stale name.
