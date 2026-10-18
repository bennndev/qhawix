# Guardian mascot generator

Turns the Node rig and the spec into the Dart data used by `GuardianMascot`. Deterministic: same
inputs, same output.

| Input (`source/`) | Origin |
| --- | --- |
| `mascot.svg` | Copy of `pet/animated/assets/mascot.svg` |
| `mascot.spec.json` | Copy of `pet/animated/src/mascot.spec.json` (idle, thinking, working, success) |
| `guardian_states.spec.json` | This project: listening, scanning, alert, stealth, their extra parts and shapes |
| `idle_sleep.spec.json` | Intentional override of `idle` (owner request: a sleeping light sleeper) plus its "z" parts. Applied over the base state; the Node copy is never edited |

| Output (`lib/core/widgets/guardian_mascot/generated/`) | Content |
| --- | --- |
| `guardian_mascot_rig_data.dart` | The artwork as absolute path commands, clips, mask and part bounds |
| `guardian_mascot_spec_data.dart` | The spec of all 8 states as `const` Dart data |

## Rerun

From `ui/`:

```bash
dart run tool/guardian_mascot/generate.dart
```

Then `flutter test test/core/widgets/guardian_mascot`: a test compares the committed output with
what the generator produces and fails when it is stale.

## Updating the sources

- If `pet/animated` changes, copy the new `mascot.svg` and `mascot.spec.json` into `source/`
  unchanged and regenerate. The spec test checks the four Node states stay equal to the copy.
- To change the sleeping `idle`, edit `idle_sleep.spec.json` (offsets are milliseconds / 16800).
- To change or add a state, edit `guardian_states.spec.json` (never the Node copy), regenerate,
  and add the state to `GuardianMascotState` (the enum must match the spec keys one to one).
- The SVG path parser in `generate.dart` supports M L H V C S Q T Z (absolute and relative). Arcs
  are rejected on purpose; convert them before adding them to the SVG.
- Colours are never read from the SVG: `var(--mascot-body, ...)` becomes `RigColor.body` and
  `var(--mascot-line, ...)` becomes `RigColor.line`; anything else fails the generator.
