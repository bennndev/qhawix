# Animation tooling evaluation

Goal: expressive animation (Grok Bot style: squash and stretch, anticipation, overshoot,
secondary motion, gaze) for the owl SVG, with logic decoupled from the app so it can move to a
PWA or Kotlin Multiplatform later.

## What the project looks like

The repository has no application code yet (only agent configuration and skills; `AGENTS.md`
is a placeholder), so there is no existing stack to be compatible with. Portability was therefore
the main selection criterion. No animation authoring tool or skill is installed for Claude Code or
Codex here: `.mcp.json` only declares the GitHub MCP (which also failed to connect in this session),
and the repo skills (`install-skill`, `research`, `research-routing`, `web-search`) are not animation tools.

## What the SVG allows

`behav.svg` is an Illustrator export, 2000x2000. The visible layer `Capa_1` is one merged compound
path (frame, sockets, cheeks and beak are cut-outs of the same path) plus two eye rings. The hidden
layer `Capa_2` holds the same drawing as separate stroked parts: two brow pieces (tuft + socket),
beak, two eyes, body outline, forehead arc, two cheeks and spine. That layer is what gets rigged:
eyes (gaze, blink), brows (raise/furrow), beak, the whole body (breathing, squash and stretch, tilt)
and overlays (thought dots, gears, check mark, sparks).

## Options compared

| Option | Fit for this SVG | Animation quality | Agent automation | Portability | Verdict |
| --- | --- | --- | --- | --- | --- |
| **Rive + official MCP** | The art must be rebuilt or imported in the Rive editor (SVG import is not mentioned in the MCP docs). | Highest ceiling: state machines, blending, runtime inputs. | Partial: the MCP edits state machines, keyframes and transitions, but only while the **desktop Editor (Windows/macOS) is open**; output is a binary `.riv`. | Official runtimes for web, Android and iOS; no official Kotlin Multiplatform runtime found (the community `rive-cmp` wraps Android and iOS only, v0.0.6 from Jul 2025). | Strong for a polished final asset; heavy for a prototype and not CI-friendly. |
| Rive community MCP (`rivemcp`, npm) | Same as above. | Same output format. | Does not need the Editor; advertises 139 tools. Third-party, not reviewed. | Same as Rive. | Not trusted without review. |
| Lottie / dotLottie (+ Compottie on KMP) | Needs an SVG to After Effects/Bodymovin conversion; no path found that keeps the rig structure. | Good, but state logic lives outside the file. | Weak: authoring is GUI-based and hand-editing the JSON is impractical. | Good: Compottie renders Lottie on Compose Multiplatform with its own engine. | Good player, poor authoring path for us. |
| **Web Animations API over the SVG (chosen)** | Direct: parts are SVG elements, no conversion. | Enough for squash/stretch, anticipation, overshoot, secondary motion and cross-state blending. | Best: motion is a JSON file that an agent or a person can edit and diff; tests and screenshots run headless. | Web/PWA native. KMP needs a port of a small interpreter; the data is language-neutral. | Chosen for the prototype. |

Not evaluated in depth: GSAP, Motion, anime.js, SMIL, Theatre.js, SVGator. They would add a
dependency for what the platform API already does here; revisit if timelines get much more complex.

## Why the Web Animations API + JSON spec

1. Preserves identity: it animates the original geometry, with no redraw or conversion.
2. Decoupled by construction: the engine takes an element and a spec, nothing else.
3. Agent-friendly and testable: text spec, deterministic `seek`, headless verification.
4. No dependencies, and no editor license or GUI in the loop.

Trade-off accepted: no visual timeline editor, and KMP needs its own small player. If the mascot
later needs interactive, input-driven blending that outgrows this, Rive is the natural upgrade; the
part names in the spec map directly to Rive objects.

## What was and was not verified

- Verified here: the rig renders like the original (visual comparison), all four states animate
  (contact sheet), and the engine passes 7 tests (spec contract, rig freshness, and 16 real-browser
  checks including real-time auto-return, events and reduced motion). The browser test fails when
  auto-return is deliberately broken (mutation check).
- Not verified: Rive and Lottie were assessed from their documentation and package listings, not by
  building the mascot in them. Rive's MCP was not installed or run. Firefox, Safari and real devices
  were not tested.

## Sources

- Rive MCP docs: https://rive.app/docs/editor/ai/mcp
- Community RiveMCP listing: https://mcpservers.org/servers/rive-mcp
- `rive-cmp` community wrapper: https://mvnrepository.com/artifact/dev.muazkadan/rive-cmp/0.0.6/changes
- Compottie (Lottie for Compose Multiplatform): https://klibs.io/package/io.github.alexzhirkevich/compottie
- `transform-box` (MDN): https://developer.mozilla.org/en-US/docs/Web/CSS/transform-box
