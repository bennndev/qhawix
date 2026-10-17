# GuardianMascot ("Guardian de Comportamiento")

The animated owl. A pure-Dart port of the Node rig in `pet/animated` (same art, same four states,
same keyframe, blend, one-shot and reduced-motion semantics) plus four added states. No new
dependency: a `CustomPainter` driven by an `AnimationController`.

```dart
GuardianMascot(
  state: GuardianMascotState.thinking,
  size: 120,                                  // default
  bodyColor: null,                            // default: colorScheme.primary
  lineColor: null,                            // default: colorScheme.onPrimary
  semanticLabel: 'Abrir AURA, tu asistente',  // optional, Spanish; omit for decorative use
  onTap: () {},                               // optional; with a label it is a button (48 dp target)
  onStateEnd: (state) {},                     // a one-shot finished; `state` is what plays now
)
```

## States

| State | Intent | Motion | Trigger |
| --- | --- | --- | --- |
| `idle` | Quiet companion | Loop: breathe 4.2 s, glance and blink 6 s | Default; after `success` |
| `thinking` | Composing | Loop: head tilt 3.6 s, three pulsing dots 1.5 s | A response is being composed |
| `working` | Bounded analysis | Loop: bounce 0.52 s, scanning eyes, two gears | A bounded task runs |
| `success` | Done | One-shot 2.8 s: hop, check, sparks, then `idle` | A task finished |
| `listening` | Attentive | Loop: breathe 3 s with a slight lean, wider eyes, two rings expanding and fading 2.6 s | The voice detector listens |
| `scanning` | Inspecting | Loop: eyes sweep 2.8 s, sway 4 s, dashed halo turning 9 s | A QR, link or message is checked |
| `alert` | Attention, not alarm | One-shot 1.7 s: squash, small head shake, then holds tufts up, wide eyes and a "!" | Something needs attention. Never the only signal: text and the risk badge carry the danger |
| `stealth` | Discreet | Loop 6 s, body opacity 0.14, 0.7 s blend in and out | Discreet appearance |

The first four equal `pet/animated/src/mascot.spec.json` value for value (tested). The last four
live in `ui/tool/guardian_mascot/source/guardian_states.spec.json`, which documents each intent.
Extra spec fields beyond the Node format: `hold` (a one-shot that stays on its last pose),
`blendMs` and `exitBlendMs` (per-state blend). Rings, halo and "!" use the body colour only (the
line colour is invisible on the canvas) and sit behind or in front of the owl.

## Behaviour

- **Reduced motion:** `MediaQuery.disableAnimations` freezes each state on its static pose (0 for
  loops, 0.6 for `success`, 1 for `alert`) with no blend. `success` holds about 1.8 s, then moves
  on. No ticker runs for frozen loops.
- **Background:** the clock stops when the app is hidden or paused and when `TickerMode` is
  disabled; it resumes without a time jump. A held `alert` also stops its clock.
- **Semantics:** excluded by default. A `semanticLabel` makes it a labelled image, a button when
  `onTap` is set. There is no built-in label.
- **Colours:** both are parameters. No colour literal exists in this folder (tested). No
  gradient, glow or shadow. Only transform and opacity animate; tuft rotation stays under 10 deg.

## Files

| File | Role |
| --- | --- |
| `guardian_mascot.dart` | The widget, lifecycle, reduced motion, semantics |
| `guardian_mascot_state.dart` | `GuardianMascotState`, one value per spec state |
| `mascot_engine.dart` | Pure-Dart engine: tracks, easing, blend, one-shots, `advance`/`seek`/`pause`/`play` |
| `mascot_spec.dart`, `mascot_easing.dart` | Spec model with validation, CSS easing |
| `mascot_rig.dart`, `mascot_painter.dart` | Artwork model and the painter |
| `generated/` | Rig paths and the spec of all 8 states. Generated, do not edit |

## Regenerating

From `ui/`: `dart run tool/guardian_mascot/generate.dart`. See
`ui/tool/guardian_mascot/README.md`. A test fails if the committed output is stale.

## Demo

From `ui/`: `flutter run -t lib/dev/guardian_mascot_demo_main.dart` (the equivalent of
`npm start` in `pet/animated`): buttons for the 8 states, reduced-motion and dark-theme switches.

## Known limits

- Rendering parity with the Node rig was checked by eye on a desktop test render; nothing was run
  on an Android device (unverified).
- The visible art is one merged path: only the eyes, tufts and whole body move; the beak and
  cheeks are static (as in the Node rig).
- `onStateEnd` fires for one-shots only; the parent keeps `state` in sync by using it.
