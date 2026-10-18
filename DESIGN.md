---
version: alpha
name: QHAWIX Quiet
description: A calm, airy, offline-first Android system for a security suite, with one restrained accent, a muted semantic risk set that never relies on color alone, and a discreet appearance for moments of danger.
colors:
  primary: "#11141A"
  on-primary: "#FBF9FC"
  secondary: "#444A58"
  tertiary: "#E5E7EB"
  neutral: "#FBF9FC"
  surface: "#FFFFFF"
  surface-sunken: "#F3F1F5"
  on-surface: "#444A58"
  on-surface-strong: "#11141A"
  on-surface-muted: "#5B6170"
  border: "#E5E7EB"
  border-strong: "#7C8190"
  accent: "#0B5D6B"
  accent-tint: "#E3F0F2"
  accent-deep: "#084550"
  error: "#B42318"
  error-tint: "#FDEAE7"
  on-error: "#FFFFFF"
  risk-not-assessed-fg: "#4B5160"
  risk-not-assessed-bg: "#ECEEF1"
  risk-none-detected-fg: "#2F4A6B"
  risk-none-detected-bg: "#E8EEF6"
  risk-caution-fg: "#7A4A00"
  risk-caution-bg: "#FFF1D6"
  risk-high-fg: "#8F1D14"
  risk-high-bg: "#FDE8E5"
  risk-abstain-fg: "#4F4A7A"
  risk-abstain-bg: "#EEECF7"
  dark-neutral: "#0F1115"
  dark-surface: "#171A21"
  dark-surface-raised: "#1E222B"
  dark-primary: "#F2F3F7"
  dark-on-primary: "#0F1115"
  dark-on-surface: "#E6E8EE"
  dark-on-surface-muted: "#A9AFBD"
  dark-border: "#2A2F3A"
  dark-border-strong: "#8B91A0"
  dark-accent: "#6CC3D0"
  dark-error: "#FFB4AB"
  dark-risk-not-assessed-fg: "#C4C9D4"
  dark-risk-not-assessed-bg: "#262A33"
  dark-risk-none-detected-fg: "#B8CCE8"
  dark-risk-none-detected-bg: "#1E2B3F"
  dark-risk-caution-fg: "#F2C879"
  dark-risk-caution-bg: "#3A2C12"
  dark-risk-high-fg: "#FFB4AB"
  dark-risk-high-bg: "#46201C"
  dark-risk-abstain-fg: "#CCC6F2"
  dark-risk-abstain-bg: "#2C2A45"
typography:
  headline-display:
    fontFamily: "DM Sans"
    fontSize: "36px"
    fontWeight: 700
    lineHeight: 1.1
    letterSpacing: "-0.02em"
  headline-lg:
    fontFamily: "DM Sans"
    fontSize: "28px"
    fontWeight: 700
    lineHeight: 1.2
    letterSpacing: "0px"
  headline-md:
    fontFamily: "DM Sans"
    fontSize: "22px"
    fontWeight: 700
    lineHeight: 1.25
    letterSpacing: "0px"
  headline-sm:
    fontFamily: "DM Sans"
    fontSize: "18px"
    fontWeight: 700
    lineHeight: 1.3
    letterSpacing: "0px"
  body-lg:
    fontFamily: "Inter"
    fontSize: "18px"
    fontWeight: 400
    lineHeight: 1.5
    letterSpacing: "0px"
  body-md:
    fontFamily: "Inter"
    fontSize: "16px"
    fontWeight: 400
    lineHeight: 1.5
    letterSpacing: "0px"
  body-sm:
    fontFamily: "Inter"
    fontSize: "14px"
    fontWeight: 400
    lineHeight: 1.45
    letterSpacing: "0px"
  body-emphasis:
    fontFamily: "Inter"
    fontSize: "16px"
    fontWeight: 500
    lineHeight: 1.5
    letterSpacing: "0px"
  label-lg:
    fontFamily: "DM Sans"
    fontSize: "16px"
    fontWeight: 500
    lineHeight: 1.25
    letterSpacing: "0px"
  label-md:
    fontFamily: "DM Sans"
    fontSize: "14px"
    fontWeight: 500
    lineHeight: 1.25
    letterSpacing: "0px"
  label-sm:
    fontFamily: "DM Sans"
    fontSize: "13px"
    fontWeight: 500
    lineHeight: 1.25
    letterSpacing: "0px"
rounded:
  none: 0px
  sm: 8px
  md: 12px
  lg: 16px
  xl: 28px
  full: 9999px
spacing:
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 32px
  xxl: 48px
  gutter: 20px
  touch-min: 48px
  section: 32px
components:
  button-primary:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.on-primary}"
    typography: "{typography.label-lg}"
    rounded: "{rounded.full}"
    padding: "12px 24px"
    height: "48px"
  button-primary-pressed:
    backgroundColor: "{colors.secondary}"
    textColor: "{colors.on-primary}"
    rounded: "{rounded.full}"
  button-primary-disabled:
    backgroundColor: "{colors.surface-sunken}"
    textColor: "{colors.on-surface-muted}"
    rounded: "{rounded.full}"
  button-secondary:
    backgroundColor: "transparent"
    textColor: "{colors.on-surface-strong}"
    typography: "{typography.label-lg}"
    rounded: "{rounded.full}"
    padding: "12px 24px"
    height: "48px"
  button-tertiary:
    backgroundColor: "transparent"
    textColor: "{colors.accent}"
    typography: "{typography.label-lg}"
    rounded: "{rounded.full}"
    padding: "12px 16px"
    height: "48px"
  button-destructive:
    backgroundColor: "{colors.error}"
    textColor: "{colors.on-error}"
    typography: "{typography.label-lg}"
    rounded: "{rounded.full}"
    padding: "12px 24px"
    height: "48px"
  card:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.on-surface}"
    rounded: "{rounded.lg}"
    padding: "16px"
  card-module:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.on-surface}"
    typography: "{typography.body-sm}"
    rounded: "{rounded.lg}"
    padding: "16px"
    height: "96px"
  input:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.on-surface-strong}"
    typography: "{typography.body-md}"
    rounded: "{rounded.md}"
    padding: "12px 16px"
    height: "56px"
  input-multiline:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.on-surface-strong}"
    typography: "{typography.body-md}"
    rounded: "{rounded.md}"
    padding: "16px"
    height: "160px"
  chip:
    backgroundColor: "{colors.tertiary}"
    textColor: "{colors.on-surface-strong}"
    typography: "{typography.label-md}"
    rounded: "{rounded.full}"
    padding: "8px 16px"
    height: "48px"
  chip-selected:
    backgroundColor: "{colors.accent-tint}"
    textColor: "{colors.accent-deep}"
    typography: "{typography.label-md}"
    rounded: "{rounded.full}"
    padding: "8px 16px"
    height: "48px"
  risk-badge-not-assessed:
    backgroundColor: "{colors.risk-not-assessed-bg}"
    textColor: "{colors.risk-not-assessed-fg}"
    typography: "{typography.label-sm}"
    rounded: "{rounded.full}"
    padding: "4px 12px"
  risk-badge-none-detected:
    backgroundColor: "{colors.risk-none-detected-bg}"
    textColor: "{colors.risk-none-detected-fg}"
    typography: "{typography.label-sm}"
    rounded: "{rounded.full}"
    padding: "4px 12px"
  risk-badge-caution:
    backgroundColor: "{colors.risk-caution-bg}"
    textColor: "{colors.risk-caution-fg}"
    typography: "{typography.label-sm}"
    rounded: "{rounded.full}"
    padding: "4px 12px"
  risk-badge-high:
    backgroundColor: "{colors.risk-high-bg}"
    textColor: "{colors.risk-high-fg}"
    typography: "{typography.label-sm}"
    rounded: "{rounded.full}"
    padding: "4px 12px"
  risk-badge-abstain:
    backgroundColor: "{colors.risk-abstain-bg}"
    textColor: "{colors.risk-abstain-fg}"
    typography: "{typography.label-sm}"
    rounded: "{rounded.full}"
    padding: "4px 12px"
  voice-light-human:
    backgroundColor: "{colors.risk-none-detected-bg}"
    textColor: "{colors.risk-none-detected-fg}"
    typography: "{typography.headline-sm}"
    rounded: "{rounded.lg}"
    padding: "16px"
  voice-light-doubtful:
    backgroundColor: "{colors.risk-caution-bg}"
    textColor: "{colors.risk-caution-fg}"
    typography: "{typography.headline-sm}"
    rounded: "{rounded.lg}"
    padding: "16px"
  voice-light-cloned:
    backgroundColor: "{colors.risk-high-bg}"
    textColor: "{colors.risk-high-fg}"
    typography: "{typography.headline-sm}"
    rounded: "{rounded.lg}"
    padding: "16px"
  voice-light-inconclusive:
    backgroundColor: "{colors.risk-abstain-bg}"
    textColor: "{colors.risk-abstain-fg}"
    typography: "{typography.headline-sm}"
    rounded: "{rounded.lg}"
    padding: "16px"
  banner-status:
    backgroundColor: "{colors.surface-sunken}"
    textColor: "{colors.on-surface-strong}"
    typography: "{typography.body-sm}"
    rounded: "{rounded.md}"
    padding: "12px 16px"
  banner-example-data:
    backgroundColor: "{colors.accent-tint}"
    textColor: "{colors.accent-deep}"
    typography: "{typography.label-md}"
    rounded: "{rounded.md}"
    padding: "8px 16px"
  bottom-nav:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.on-surface-muted}"
    typography: "{typography.label-sm}"
    rounded: "{rounded.none}"
    height: "80px"
  bottom-nav-item-selected:
    backgroundColor: "{colors.accent-tint}"
    textColor: "{colors.accent-deep}"
    typography: "{typography.label-sm}"
    rounded: "{rounded.full}"
    height: "48px"
  app-bar:
    backgroundColor: "{colors.neutral}"
    textColor: "{colors.on-surface-strong}"
    typography: "{typography.headline-sm}"
    rounded: "{rounded.none}"
    height: "56px"
  list-row:
    backgroundColor: "transparent"
    textColor: "{colors.on-surface-strong}"
    typography: "{typography.body-md}"
    rounded: "{rounded.none}"
    padding: "12px 0px"
    height: "56px"
  bottom-sheet:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.on-surface}"
    rounded: "{rounded.xl}"
    padding: "24px"
  dialog-confirm:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.on-surface}"
    typography: "{typography.body-md}"
    rounded: "{rounded.xl}"
    padding: "24px"
  empty-state:
    backgroundColor: "transparent"
    textColor: "{colors.on-surface-muted}"
    typography: "{typography.body-md}"
    padding: "32px 24px"
  state-unverifiable:
    backgroundColor: "{colors.risk-abstain-bg}"
    textColor: "{colors.risk-abstain-fg}"
    typography: "{typography.body-md}"
    rounded: "{rounded.lg}"
    padding: "16px"
  skeleton:
    backgroundColor: "{colors.surface-sunken}"
    rounded: "{rounded.sm}"
  permission-rationale:
    backgroundColor: "{colors.neutral}"
    textColor: "{colors.on-surface}"
    typography: "{typography.body-lg}"
    padding: "24px"
  gate-screen:
    backgroundColor: "{colors.neutral}"
    textColor: "{colors.on-surface-strong}"
    typography: "{typography.headline-md}"
    padding: "32px 24px"
---

# QHAWIX Quiet

## Overview

**Creative North Star: "The Quiet Lookout."** *Qhawix* means "lookout" in Quechua. A good lookout does not shout; it stays still, sees clearly, and speaks once, plainly, when it matters. The interface follows that posture: pale, spacious, almost empty, with one deep teal accent and black used only where a decision is made. Everything that could alarm is held back until there is a reason, and even then it is stated in words and shapes before color.

The surface is a phone app in **Operate** mode (a person completing a task, often while worried). Scanability, consistency and platform expectations outrank expression. Brand lives in precise details: the pill controls, the DM Sans headlines, the teal focus ring, the honest wording. The landing page is a separate **Persuade** surface and is out of scope here.

This system adapts a minimal landing-page reference (DM Sans plus Inter, pill buttons, off-white canvas, one black accent). The earlier prototype under `docs/Mobile Banking MVP Design/` (violet, indigo and cyan gradients, an "Ultra Secure" purple theme) is treated as evidence of a discarded direction, not as a source of tokens.

**Key Characteristics:**
- Off-white canvas, white cards, light borders; hierarchy from scale and spacing, not decoration.
- Black pill for the single primary action per screen; teal only for focus, selection and links.
- A five-state risk set and a four-state voice light, each with its own icon and Spanish label. Fill color is the third cue, never the only one.
- "No signals detected" is a neutral blue-gray with a magnifier-off icon. It is never green and never a check mark.
- Every number, state and mock value is honest: example data is always labeled, unverifiable is its own state.
- A dark theme and a discreet appearance that look like an ordinary quiet app.

## Colors

The palette is cool, low-chroma and light. Teal is the only hue with identity; the semantic set sits at the same low saturation so no state shouts.

### Primary
- **Ink (#11141A):** Headlines, the filled primary button and the strongest text. Used on a small fraction of any screen; its rarity marks "this is the decision".
- **On-primary (#FBF9FC):** Text and icons on ink.

### Secondary
- **Slate (#444A58):** Body text, secondary actions, icons. Softens contrast while staying well above AA.
- **Muted slate (#5B6170):** Captions, helper text, inactive navigation, disabled labels. Lightest text color allowed; do not go lighter.

### Tertiary
- **Mist (#E5E7EB):** Decorative dividers and card borders. It is a separator, not a boundary a person must perceive; any control edge uses Strong border instead.

### Accent
- **Vigía teal (#0B5D6B):** Focus ring, selected navigation, links, tertiary buttons, the example-data banner. Dark enough for text on the canvas (7.18:1).
- **Teal tint (#E3F0F2)** and **Deep teal (#084550):** Selected chip and navigation fill, and the example-data banner, with deep teal as the text on the tint.

### Neutral
- **Canvas (#FBF9FC):** Screen background. Soft off-white, never pure white.
- **Surface (#FFFFFF):** Cards, inputs, sheets and the bottom navigation. Rare; the contrast with canvas is the elevation.
- **Sunken (#F3F1F5):** Disabled fills, skeletons, quiet status banners.
- **Strong border (#7C8190):** Input outlines and any edge that identifies a control (3.7:1 or more).

### Semantic: errors
- **Error (#B42318)** with **Error tint (#FDEAE7):** Form validation and destructive actions only. Deeper than the reference's #D92D20 so it passes AA on its own tint. Not used for risk levels.

### Semantic: risk and voice
Five muted pairs, one per `RiskLevel`. Each is a foreground and a background that pass 4.5:1 together, and each ships with a fixed icon and Spanish label (see Components).

| Token pair | `RiskLevel` | Label | Icon | Character |
| --- | --- | --- | --- | --- |
| `risk-not-assessed` | `notAssessed` | Sin evaluar | `radio_button_unchecked` | Neutral gray; nothing was analyzed yet |
| `risk-none-detected` | `noneDetected` | Sin señales detectadas | `search_off` | Calm blue-gray; looked, found no signal |
| `risk-caution` | `caution` | Precaución | `warning_amber_rounded` | Warm amber |
| `risk-high` | `high` | Riesgo alto | `report_outlined` | Clay red, not alarm red |
| `risk-abstain` | `abstain` | Sin base suficiente | `help_outline` | Muted violet-gray; evidence too thin to judge |

The voice light reuses the same pairs: human uses `risk-none-detected`, doubtful uses `risk-caution`, cloned uses `risk-high`, inconclusive uses `risk-abstain`. Unverifiable (QR, reputation, detector offline) also uses `risk-abstain`, with its own label.

### Dark theme
Same roles, different values (prefixed `dark-` in the front matter). Dark inverts the primary pair (a light pill with dark text) and moves risk fills to deep tints with light foregrounds.

### Named Rules
**The One Black Rule.** One ink-filled button per screen. If two actions compete, one of them is secondary.

**The Never-Green Rule.** There is no success green in the risk system. A screen with no detected signals must not look like a screen that has been verified safe. A positive operation result (saved, sent) is stated in words and a neutral check, not colored as safety.

**The Three-Cues Rule.** Every state carries an icon, a text label and a color. Remove the color and the meaning must survive; remove the icon and it must survive.

**The Quiet Fill Rule.** Risk fills are tints that sit about 1.1:1 against the canvas on purpose. They calm; they do not carry meaning. A 1px outline in the foreground color at 40% opacity and the icon keep the shape visible.

### Contrast results

Computed with the WCAG relative-luminance formula by a script kept outside the repository. Text needs 4.5:1; large text, icons and control edges need 3:1. Nothing below is accepted as a pass at a lower ratio.

| Pair | FG | BG | Ratio | Min | Result |
|---|---|---|---|---|---|
| L ink on canvas | #11141A | #FBF9FC | 17.61 | 4.5 | pass |
| L canvas on ink (primary btn) | #FBF9FC | #11141A | 17.61 | 4.5 | pass |
| L slate on canvas | #444A58 | #FBF9FC | 8.48 | 4.5 | pass |
| L slate on surface | #444A58 | #FFFFFF | 8.87 | 4.5 | pass |
| L muted on canvas | #5B6170 | #FBF9FC | 5.92 | 4.5 | pass |
| L muted on sunken | #5B6170 | #F3F1F5 | 5.52 | 4.5 | pass |
| L ink on sunken | #11141A | #F3F1F5 | 16.43 | 4.5 | pass |
| L accent on canvas (link/selected) | #0B5D6B | #FBF9FC | 7.18 | 4.5 | pass |
| L accent on surface | #0B5D6B | #FFFFFF | 7.52 | 4.5 | pass |
| L accent focus ring vs canvas | #0B5D6B | #FBF9FC | 7.18 | 3 | pass |
| L input border vs surface | #7C8190 | #FFFFFF | 3.89 | 3 | pass |
| L input border vs canvas | #7C8190 | #FBF9FC | 3.71 | 3 | pass |
| L accentDeep on accentTint (example banner) | #084550 | #E3F0F2 | 9.11 | 4.5 | pass |
| L error on canvas | #B42318 | #FBF9FC | 6.28 | 4.5 | pass |
| L error on errorTint | #B42318 | #FDEAE7 | 5.67 | 4.5 | pass |
| L white on error (destructive btn) | #FFFFFF | #B42318 | 6.57 | 4.5 | pass |
| L risk ni fg/bg | #4B5160 | #ECEEF1 | 6.83 | 4.5 | pass |
| L risk nd fg/bg | #2F4A6B | #E8EEF6 | 7.78 | 4.5 | pass |
| L risk ca fg/bg | #7A4A00 | #FFF1D6 | 6.70 | 4.5 | pass |
| L risk hi fg/bg | #8F1D14 | #FDE8E5 | 7.58 | 4.5 | pass |
| L risk ab fg/bg | #4F4A7A | #EEECF7 | 6.93 | 4.5 | pass |
| D text on canvas | #E6E8EE | #0F1115 | 15.42 | 4.5 | pass |
| D text on surface | #E6E8EE | #171A21 | 14.21 | 4.5 | pass |
| D muted on canvas | #A9AFBD | #0F1115 | 8.60 | 4.5 | pass |
| D muted on surface | #A9AFBD | #171A21 | 7.92 | 4.5 | pass |
| D muted on raised | #A9AFBD | #1E222B | 7.24 | 4.5 | pass |
| D canvas on ink (primary btn) | #0F1115 | #F2F3F7 | 17.04 | 4.5 | pass |
| D accent on canvas | #6CC3D0 | #0F1115 | 9.32 | 4.5 | pass |
| D accent on surface | #6CC3D0 | #171A21 | 8.58 | 4.5 | pass |
| D error on canvas | #FFB4AB | #0F1115 | 11.13 | 4.5 | pass |
| D border vs surface | #8B91A0 | #171A21 | 5.52 | 3 | pass |
| D risk ni fg/bg | #C4C9D4 | #262A33 | 8.66 | 4.5 | pass |
| D risk ni fg on surface | #C4C9D4 | #171A21 | 10.49 | 4.5 | pass |
| D risk nd fg/bg | #B8CCE8 | #1E2B3F | 8.72 | 4.5 | pass |
| D risk nd fg on surface | #B8CCE8 | #171A21 | 10.65 | 4.5 | pass |
| D risk ca fg/bg | #F2C879 | #3A2C12 | 8.60 | 4.5 | pass |
| D risk ca fg on surface | #F2C879 | #171A21 | 11.04 | 4.5 | pass |
| D risk hi fg/bg | #FFB4AB | #46201C | 8.34 | 4.5 | pass |
| D risk hi fg on surface | #FFB4AB | #171A21 | 10.25 | 4.5 | pass |
| D risk ab fg/bg | #CCC6F2 | #2C2A45 | 8.48 | 4.5 | pass |
| D risk ab fg on surface | #CCC6F2 | #171A21 | 10.72 | 4.5 | pass |
| L pressed primary (on-primary on secondary) | #FBF9FC | #444A58 | 8.48 | 4.5 | pass |
| L chip text on tertiary | #11141A | #E5E7EB | 14.89 | 4.5 | pass |
| L bottom-nav muted on surface | #5B6170 | #FFFFFF | 6.20 | 4.5 | pass |
| L mascot body vs canvas | #0B5D6B | #FBF9FC | 7.18 | 3 | pass |
| L mascot white lines on body | #FFFFFF | #0B5D6B | 7.52 | 3 | pass |
| D mascot lines on body | #0F1115 | #6CC3D0 | 9.32 | 3 | pass |

Risk fills against the canvas measure 1.07 to 1.12:1 by design; they are decorative (see The Quiet Fill Rule), and the badge edge, icon and label carry the meaning at 3:1 or better.

## Typography

**Display and UI font:** DM Sans (fallback `Roboto`, `sans-serif`)
**Reading font:** Inter (fallback `Roboto`, `sans-serif`)

**Character:** DM Sans gives headlines and controls a geometric, friendly shape; Inter carries paragraphs, quoted message text and explanations with neutral legibility. The pairing is inherited from the reference, rescaled for a phone.

### Hierarchy
- **Display** (DM Sans 700, 36, 1.1, -0.02em): One per onboarding or gate screen at most.
- **Headline large** (DM Sans 700, 28, 1.2): Screen titles in large-title position.
- **Headline medium** (DM Sans 700, 22, 1.25): Section titles and dialog titles.
- **Headline small** (DM Sans 700, 18, 1.3): App bar title, card titles, voice-light verdict.
- **Body large** (Inter 400, 18, 1.5): Permission rationale and gate screen explanations.
- **Body medium** (Inter 400, 16, 1.5): Default text. Never smaller for anything the person must read to decide.
- **Body small** (Inter 400, 14, 1.45): Helper text and secondary lines.
- **Body emphasis** (Inter 500, 16, 1.5): Inline emphasis; replaces bold.
- **Label large / medium / small** (DM Sans 500, 16 / 14 / 13): Buttons, chips, navigation, badges. Sentence case, no tracking.

Sizes are logical pixels (dp). Text is always laid out with the system text scale applied.

### Bundling
The app works offline, so fonts are bundled as Flutter assets, never fetched at runtime (do not use runtime font downloading). Both families are SIL OFL 1.1; keep the license files beside the fonts.
- **DM Sans: 3 static weights**, 400, 500, 700 (Latin and Latin Extended, which cover Spanish).
- **Inter: 2 static weights**, 400, 500.
- Five font files in total, declared in `ui/pubspec.yaml` with explicit `weight` entries. There is no 600 or 300; if a design needs it, change the design.
- The owner approved (2026-10-17) bundling the five font files and the `fonts:` entry in `ui/pubspec.yaml`.

### Named Rules
**The Sentence Case Rule.** No uppercase, no letter-spacing, no small-caps. Weight and size make hierarchy.

**The 200% Rule.** Every text container is sized by its content with a minimum height, never a fixed height. At 200% text scale nothing is clipped, truncated without a way to read it, or hidden.

## Layout

Phone first, portrait first, single column. The grid is a 4 dp base with the steps 4, 8, 16, 24, 32, 48. Screen gutters are 20 dp. Vertical rhythm between groups is 24 dp, inside a group 8 to 16 dp, and between major sections 32 dp. The reference's 64 px section gap is too large for a phone and is reduced.

- **Safe areas:** respect insets on all edges. Primary actions sit in the lower third (one-handed reach) and above the system gesture area.
- **Touch targets:** at least 48 x 48 dp for anything tappable, with at least 8 dp between adjacent targets. A visually smaller control (badge, icon) is wrapped in a 48 dp hit area.
- **Width classes** (decided by `LayoutBuilder` or `MediaQuery.sizeOf`, never by device type or orientation): compact under 600 dp is the target layout; medium 600 to 840 dp keeps one column with content capped at 560 dp and centered; expanded over 840 dp swaps the bottom navigation for a navigation rail. The app does not lock orientation; landscape and large windows are supported but not the design focus.
- **Reading width:** body text lines stay under about 70 characters; wrap long content in a `ConstrainedBox` (max 560 dp).
- **Density:** one primary idea per screen. Lists use 56 dp rows; modules never show more than one risk badge per card.
- **Text scale:** the layout reflows at 200%: rows grow, the bottom navigation grows in height and its labels wrap to two lines (labels are never dropped), button text wraps and the button grows.
- **Emergency-adjacent screens** (Refugio, SOS): one-handed, large targets, the main action reachable by thumb, no gesture that is visible to a watcher.

## Elevation & Depth

Flat by default. Depth comes from tonal layering (white surface over off-white canvas), a 1 dp Mist border and spacing, not shadows. Tonal elevation is used where Material would add shadow (`surfaceTintColor` transparent, `elevation` 0).

- **Resting cards and sheets:** no shadow, 1 dp Mist border on cards.
- **Bottom sheet and dialog:** a scrim of ink at 40% opacity separates them from content; they stay shadowless.
- **Bottom navigation and app bar:** a 1 dp Mist top or bottom edge appears only after content scrolls under them.
- **Dark theme:** layers step lighter (canvas, surface, raised) instead of casting shadow.

**The Flat-By-Default Rule.** Surfaces are flat at rest. State, scrim and a border may separate layers; a drop shadow may not.

## Shapes

Soft but not bubbly. Controls and chips are full pills (9999); cards and the module entry card use 16 dp; inputs use 12 dp; sheets and dialogs use 28 dp on the open corners. Icons are the Material Symbols outlined set at 24 dp, 2 dp stroke weight, monochrome in the text color of their component. Risk and voice states add a distinct silhouette in the icon (magnifier, triangle, octagon, question mark, empty circle) so shape alone separates them.

The reference's 4 dp radius is removed: it is too sharp next to 48 dp pills on a touch screen.

## Components

Every interactive component defines **default, pressed, focused, disabled** states. There is no hover. Pressed uses the Secondary or tint color for 100 ms (and a Material ink ripple in the matching tint when motion is allowed); focused uses a 2 dp Vigía teal ring offset 2 dp (dark: `dark-accent`); disabled uses the Sunken fill with Muted text and never relies on opacity alone. Minimum height is 48 dp for every control.

### Buttons
- **Primary:** Ink pill, 48 dp minimum height, 12 x 24 padding, DM Sans 500 16. One per screen. Pressed shifts to Slate. Loading replaces the label with a 20 dp progress indicator and keeps the width.
- **Secondary:** Transparent pill with a 1 dp Strong border and Ink text. Use for the alternate path ("Pegar texto" next to "Escanear").
- **Tertiary:** Text button in Vigía teal, 48 dp hit area, no border. Links and low-priority actions.
- **Destructive:** Error-filled pill, white text, used only inside a confirmation dialog, never as a screen's resting button.

### Cards and the module entry card
- **Card:** Surface fill, 16 dp radius, 1 dp Mist border, 16 dp padding, no shadow.
- **Module entry card:** A whole-card tap target at least 96 dp tall: a 24 dp icon in Vigía teal, DM Sans 700 18 module name (for example "Escudo QR"), one Inter 14 line of purpose, and optionally one risk badge. A feasibility state the platform limits (for example Refugio nivel A pending) shows a neutral line ("Requiere permiso de superposición"), never a locked padlock illustration. Cards stack in one column on compact width.

### Inputs
- **Field:** Surface fill, 12 dp radius, 1 dp Strong border, 56 dp minimum height, persistent label above (Label medium), helper text below (Body small). Focus: 2 dp teal border. Error: 2 dp Error border plus an `error_outline` icon and message below; never red text alone.
- **Multiline paste field (Sentinel):** 160 dp minimum, grows to 8 lines then scrolls. Includes a "Pegar" tertiary button, a character counter, and a one-line privacy note ("El texto se analiza en tu teléfono"). Sensitive data is redacted before it is stored.

### Chips
- Pill, 48 dp touch height (visual chip may be 32 dp inside the hit area), Mist fill with Ink text. Selected: teal tint fill, Deep teal text, a leading `check` icon. Used for channel selection (SMS, correo, WhatsApp) and filters.

### Risk badge
A pill with a leading 16 dp icon, then the label, DM Sans 500 13, 1 dp outline in the foreground color at 40% opacity. It never shows a number alone. The label is the verdict wording ("Precaución", not "Peligro"); the badge says nothing stronger than the rules support.

| State | Label | Notes |
| --- | --- | --- |
| notAssessed | Sin evaluar | Shown before any analysis |
| noneDetected | Sin señales detectadas | Never reads "seguro" or "legítimo"; always followed by "Esto no garantiza que sea seguro." in the detail view |
| caution | Precaución | One or more reliable signals |
| high | Riesgo alto | Strong signal; still "sospechoso", not a certainty |
| abstain | Sin base suficiente | Evidence too thin to judge |

### Voice light (EchoTrap)
A horizontal card, not a traffic light of three colored circles. A 40 dp circular glyph on the left, a DM Sans 700 18 verdict, a one-line score ("Puntuación 0,62") and a "Cómo se calcula" tertiary link. States: **Voz probablemente humana** (`risk-none-detected`, `person_outline`), **Voz dudosa** (`risk-caution`), **Posible voz clonada** (`risk-high`), **Sin resultado concluyente** (`risk-abstain`). While the microphone is active, a persistent "Escuchando" status row sits above it. The score is always shown because the threshold is calibrated, not certain.

### Status banner
A full-width rounded row with an icon, one sentence and an optional tertiary action. Variants: information (Sunken), caution, error (Error tint), unverifiable. It states what is true and what the app cannot do, in plain words ("Android no permite acceder al audio de la llamada. Usa el altavoz.").

### Example-data banner
Every screen that reads mock or fixture data shows this banner at the top, above the content, with the `science_outlined` icon on teal tint and deep teal text: **Datos de ejemplo**. It cannot be dismissed on that screen and it is absent from any screen that shows real data. It exists only in developer builds and tests; it is never a user-facing feature (see AGENTS.md).

### Bottom navigation
Five tabs: **Inicio, Analizar, Refugio, Red, Bitácora**. Surface fill, 80 dp minimum (grows with text scale), 24 dp icon above a Label small, selected tab shows a teal-tint pill behind the icon, Deep teal label and a filled icon variant; unselected uses Muted slate and the outlined icon. Labels are always visible. Analizar groups Sentinel, Escudo QR and EchoTrap entry points; Red groups Red de Confianza; AURA is reached from Inicio and from the Analizar and Refugio help links, not from a tab.

### App bar
56 dp, Canvas fill (no tint), Headline small title left-aligned, a 48 dp back button, at most two 48 dp action icons with tooltips and semantic labels. Large-title screens collapse Headline large into this bar on scroll.

### List row
56 dp minimum, a 24 dp leading icon, Body medium title, optional Body small subtitle in Muted slate, trailing chevron or badge, a 1 dp Mist divider inset 16 dp. The whole row is the tap target. Used in Bitácora and Privacidad.

### Bottom sheet
28 dp top corners, Surface fill, a 32 x 4 dp drag handle that is not the only way to close (a visible "Cerrar" tertiary button is always provided), 24 dp padding, scrim at 40%. Used for module details, evidence and source lists.

### Confirmation dialog (destructive or irreversible)
Used for deleting a case, removing a trusted contact, restoring wallets, disabling a protection. Surface fill, 28 dp radius, Headline medium title that names the action ("¿Eliminar este caso?"), a Body medium consequence line stating what is lost and that it cannot be undone, then two buttons: a secondary "Cancelar" (default focus) and a destructive confirm. For restoring wallets the confirm is Primary and followed by the person's biometric or PIN verification. The destructive confirm never has initial focus and is never the only button.

### Empty state
Centered, 32 dp padding, a 48 dp outlined icon in Muted slate, Headline small, one Body medium sentence saying what will appear here and how to start, and one Primary or Tertiary action. No illustration and no mascot required.

### Error and unverifiable state
Two different things. **Error** (a request failed): Error tint card, `error_outline`, what failed, a "Reintentar" button. **Unverifiable** (a check could not complete, for example offline, timeout, 429, 5xx, invalid JSON): `risk-abstain` card, `help_outline`, **No se pudo verificar**, the reason in one sentence ("Sin conexión con el servicio de reputación."), and what the person can do. It never says "sin coincidencias" and never uses the noneDetected style. See "Unverifiable is not safe" in AGENTS.md.

### Loading and skeleton
Prefer skeleton blocks (Sunken fill, 8 dp radius, same footprint as the loaded content) over spinners for lists and results; use a 20 dp indeterminate progress only inside a button or for a bounded wait. A shimmer sweep is allowed only when motion is allowed; with reduce motion the skeleton is static. After 8 seconds without a result, replace the skeleton with the unverifiable state, not an endless wait.

### Permission rationale screen
Shown before the system prompt, never on app start. Body large explanation, a Headline medium title that names the one permission and the one module ("Cámara para el Escudo QR"), three short bullets: what it is used for, what stays on the device, what happens if you refuse. Primary "Continuar" opens the system prompt; Secondary "Ahora no" returns with the manual alternative visible (paste a URL instead of scanning). It states only what the platform guarantees.

### Wallet gate screen (Refugio and Guardian Pago)
A full-screen, minimal surface that covers a wallet app: Canvas background, centered Headline medium ("Pausa antes de continuar"), one Body large sentence, a calm countdown for the cooldown (text plus a thin progress line, with a second "Faltan 4 minutos" text so time is not only visual), a Primary "Verificar con huella o PIN" button and a tertiary "Pedir aprobación a un contacto" link. It uses no red, no alarm wording and no padlock imagery, so it does not announce why it appeared. It states honestly that it cannot block a payment inside another app. In discreet appearance it uses the neutral palette and no QHAWIX wordmark.

### Concealment state
**Discreet appearance** is a presentation mode, not a third theme. It applies the active light or dark theme with these changes:
- No risk colors anywhere; every risk or voice state renders in the neutral `risk-not-assessed` style until the person verifies.
- No banners, badges or titles that name Refugio, concealment or active protection; "Refugio" in the navigation uses an ordinary-looking label while discreet (see Open questions).
- No pulsing, shaking, flashing or mascot animation. No notification content that names concealment.
- The tier indicator (A, B or C) and the restore path live inside Refugio and appear only after biometric or PIN verification.
- Switching into and out of this appearance is instant and silent: no transition animation.

## Motion

Motion is feedback, not decoration. All motion is transform and opacity.

| Token | Duration | Curve | Use |
| --- | --- | --- | --- |
| press | 100 ms | linear | Pressed state and ripple |
| standard | 200 ms | `Curves.easeOutCubic` | State changes, chip select, banner enter |
| emphasized | 300 ms | `Curves.easeOutCubic` in, `Curves.easeInCubic` out | Bottom sheet, dialog, route transition |
| skeleton | 1400 ms loop | `Curves.easeInOut` | Shimmer sweep |

Nothing exceeds 300 ms except the skeleton loop and the countdown line. **Reduce motion:** read `MediaQuery.of(context).disableAnimations` (and `MediaQuery.maybeDisableAnimationsOf`) once per screen. When true: all durations become zero, route and sheet transitions become an instant swap or a 100 ms opacity change, the skeleton is static, the countdown shows text only, and the mascot freezes (see Mascot). Never convey information by motion alone. No parallax, no confetti, no flashing. The mascot's state loops are the only looping motion allowed, and none may be faster than `working` (a 520 ms bounce). The mascot targets the "Grok Bot style" (squash and stretch, anticipation, overshoot, secondary motion, gaze) inside this calm budget: overshoot is small, one-shots stay at or under 2.8 s, and nothing about it competes with the text that carries the meaning. Discreet appearance uses the reduce-motion behavior regardless of the system setting.

## Mascot

The mascot is the **Guardian de Comportamiento** (code name `GuardianMascot`), a flat single-color owl with white lines and eyes. The branch `feature/animated-mascot` (merged into `main`) ships a framework-free SVG rig and a JSON animation spec with four states; the Flutter widget is built from that rig (see Implementation). The visual rules below are design decisions; the rig facts come from the earlier mascot report.

- **Role:** the product's quiet "behavioral guardian" and a companion on Inicio and the AURA assistant screen. It reacts to what the app is doing; it never decides, authorizes or implies authority. It does not speak with a simulated voice. Brand mark only; it is not required for any task, and no information is ever carried by the mascot alone.
- **States (eight):** `idle`, `thinking`, `working` and `success` come from the existing rig; `listening`, `scanning`, `alert` and `stealth` are new and must be authored in the same style.

| State | Source | Motion | Loop |
| --- | --- | --- | --- |
| `idle` | rig, overridden by the owner | Asleep and listening: eyes closed, head slightly drooped, slow breathing (5.6 s). About every 8 s it turns its head a few degrees toward one side, alternating sides, with one tuft perking up (under 10 degrees), then settles back without waking. Faint, calm "z" marks. Reduce motion freezes it asleep. This replaces the rig's breathing-and-blink idle (owner request, 2026-10-17); `thinking`, `working` and `success` still match the Node spec. | Loop (16.8 s) |
| `thinking` | rig | Head tilt, glancing eyes, three pulsing dots | Loop |
| `working` | rig | Quick bounce, two gears turning, squinted scan | Loop; **fastest loop allowed (520 ms bounce)** |
| `success` | rig | Squash, hop, check mark drawn, four sparks, back to `idle` (2.8 s) | One-shot |
| `listening` | new | Attentive: eyes widen slightly, two soft concentric rings expand and fade, a tiny lean | Loop |
| `scanning` | new | Inspecting: eyes sweep left and right, a thin ring rotates around the owl | Loop |
| `alert` | new | Attention without alarm: one anticipatory squash, a quick small head shake with overshoot, then a held pose with raised tufts and a small "!" mark | One-shot, then held until the host changes state |
| `stealth` | new | Discreet: the owl settles into a still, faint silhouette (opacity about 0.1 to 0.2), almost no motion | Settle one-shot, then static |

- **Product moments:**

| Product moment | State | Notes |
| --- | --- | --- |
| Idle on Inicio or the AURA screen | `idle` | Default |
| AURA composing an answer | `thinking` | Text appears in the chat, not in the mascot |
| Voice detector listening (EchoTrap) | `listening` | The persistent "Escuchando" row stays the source of truth |
| QR, link or message being checked | `scanning` | Bounded wait; after 8 s the unverifiable state appears (see Loading) |
| Bounded analysis running | `working` | |
| Analysis finished, nothing to flag, or an operation completed | `success` | Confirms completion only; it does not mean "safe" (see The Never-Green Rule) |
| Risk result of `caution` or `high` | `alert`, only if the mascot is on that screen | Risk results do not host the mascot (see Placement); danger is always stated by text and the risk badge |
| Protection running quietly | `stealth` | Inicio only, normal appearance only (see below) |

- **`alert` is not an alarm.** No red, no flashing, no repeated shaking, no sound. It shows that the app wants attention; the sentence and the risk badge say why. If the mascot is removed, nothing is lost.
- **`stealth` placement and contrast.** `stealth` never appears on discreet-appearance screens or on gate screens, so it cannot reveal concealment there. The one honest placement is a nearly invisible presence on the Inicio header in normal appearance while protection runs quietly. It is decorative and intentionally low contrast (about 1.1:1 at the target opacity), is excluded from the semantics tree and never carries information; it must not be used to indicate that Refugio is active. Whether even this placement could hint at active protection is an open question.
- **Proposal (not decided): relation to `behavioralDeviation`.** The product's `behavioralDeviation` dimension has the values `not_enrolled`, `insufficient_data`, `within_range`, `deviation` and `disabled`. A possible mapping, shown only on Inicio and never replacing the dimension's own label, badge or text: `not_enrolled` and `insufficient_data` to `idle`, `within_range` to `stealth` (quiet, nothing to say), `deviation` to `alert` (the sentence and badge explain), `disabled` to `idle` with no ring. It would stay one of four independent trust dimensions and must not be read as a combined "safe" indicator.
- **Animation style:** the target is the "Grok Bot style" named in `pet/animated/docs/EVALUATION.md`: squash and stretch, anticipation, overshoot, secondary motion and gaze, kept inside the calm budget of the Motion section. No loop is faster than `working`; one-shots stay at or under 2.8 s; tuft rotation stays under 10 degrees.
- **Color:** the rig's default body `#00BBA6` is 2.3:1 on the canvas and white lines on it are 2.4:1; they fail the 3:1 graphic threshold. Use the accent instead: body `#0B5D6B` with white lines in light theme (7.5:1), and body `#6CC3D0` with lines `#0F1115` in dark theme (9.3:1). One mascot color only, from the accent; the other five rig themes (orange, purple, red, blue, pink) are not used, since they would compete with the semantic set. No gradient, no glow, no drop shadow, no red in any state (the `alert` "!" mark uses the line color). Rings in `listening` and `scanning` use the line color at reduced opacity.
- **Placement and size:** 96 dp on the Inicio header, 120 dp on the AURA screen, 64 dp in an AURA chat row. Not a floating button over content, not on gate screens, not on risk results, not on error or unverifiable states, and not on any screen in discreet appearance. The existing `aura_fab.dart` (a `visibility_outlined` icon) remains the entry point to the AURA assistant until the owner decides otherwise.
- **Motion:** the mascot respects the Motion section. With `disableAnimations` true it freezes at the spec's static pose (0 for loops, 0.6 for `success`) and, for `success`, shows the pose for about 1.8 s before returning to `idle`. `listening` and `scanning` freeze with rings at rest; `alert` goes straight to its held pose (raised tufts and "!") with no shake; `stealth` goes straight to the faint silhouette. It pauses when the screen is off or the app is backgrounded (the rig has no such handling today; unverified on Android devices). Tuft rotation stays under 10 degrees.
- **Accessibility:** decorative by default, excluded from the semantics tree, with the meaning carried by adjacent text. When tapped as an entry to the AURA assistant it exposes a Spanish `Semantics` label supplied by the caller ("Abrir AURA, tu asistente"); the mascot's own name in labels is "Guardian de Comportamiento" only where a name is needed. The rig's built-in label is English and must not be used. State changes are announced through the adjacent text, not by the mascot.
- **Coexistence with the minimal palette:** one teal body, white lines, no gradient, no glow, no drop shadow. It is the only illustration in the app; empty states and errors use icons only.
- **Implementation (decided by the owner, 2026-10-17):** a pure-Dart `CustomPainter` driven by an `AnimationController`, with the rig converted to Dart data, no new dependency (no `flutter_svg`, Lottie, Rive or animation package), in `ui/lib/core/widgets/guardian_mascot/`, with a standalone demo at `ui/lib/dev/guardian_mascot_demo_main.dart`. The demo is a developer build and must show the example-data banner wherever it displays simulated state.

## Flutter mapping

Names only; implementation lives in code, not here. Tokens live in `ui/lib/core/theme/` (`tokens.dart` for raw values, `app_theme.dart` for assembly). Widgets read everything from the theme and never hard-code a color, size, radius, duration or font.

| Token group | Flutter target |
| --- | --- |
| `colors` core roles | `ColorScheme` (`primary`, `onPrimary`, `secondary`, `surface`, `onSurface`, `outline`, `outlineVariant`, `error`, `onError`, `tertiary`) built for `Brightness.light` and `Brightness.dark` |
| `colors.accent*` | `ColorScheme.tertiary` family or a `QhawixColors` `ThemeExtension` (`accent`, `accentTint`, `accentDeep`, `onSurfaceMuted`, `borderStrong`, `surfaceSunken`) |
| `colors.risk-*`, voice | `RiskPalette` `ThemeExtension` (one `RiskStyle` per `RiskLevel`: `foreground`, `background`, `icon`, `label`), with a lookup by `RiskLevel` and a voice mapping to it |
| `typography` | `TextTheme` (`displayLarge`, `headlineLarge`, `headlineMedium`, `titleMedium`, `bodyLarge`, `bodyMedium`, `bodySmall`, `labelLarge`, `labelMedium`, `labelSmall`) with `fontFamily` set per role |
| `rounded` | `QhawixShapes` `ThemeExtension` and component themes' `shape` (`StadiumBorder`, `RoundedRectangleBorder`) |
| `spacing` | `QhawixSpacing` constants or `ThemeExtension`; `touchMin` 48 feeds `minimumSize` and `materialTapTargetSize` |
| `components` | `FilledButtonTheme`, `OutlinedButtonTheme`, `TextButtonTheme`, `CardTheme`, `InputDecorationTheme`, `ChipTheme`, `NavigationBarTheme`, `AppBarTheme`, `ListTileTheme`, `BottomSheetTheme`, `DialogTheme`, `ProgressIndicatorTheme`, `SnackBarTheme` |
| Motion | `QhawixMotion` `ThemeExtension` (`press`, `standard`, `emphasized`, `skeleton`, curves) plus a helper that returns `Duration.zero` when `MediaQuery.disableAnimations` is true |
| Discreet appearance | A `DiscreetAppearance` flag in app state that selects a `RiskPalette` with all entries set to `notAssessed`; not a separate `ThemeData` |
| Fonts | `fonts:` in `pubspec.yaml`: DM Sans 400, 500, 700; Inter 400, 500 |

Rules:
- `ThemeData(useMaterial3: true)` with `colorScheme` set explicitly; do not use `ColorScheme.fromSeed` output as the final palette.
- `themeMode` follows the system by default; Refugio may force the discreet appearance.
- `RiskLevel` and the voice enum map to `RiskStyle` in the `view/` layer through the theme extension; `domain/` stays free of Flutter and color.
- Text always scales with `MediaQuery.textScalerOf`; never clamp it below 200%.
- A lint or review check forbids `Color(0x...)`, `TextStyle(fontSize: ...)` and numeric `Duration` literals outside `core/theme/`.

## Do's and Don'ts

### Do:
- **Do** keep one ink button per screen and let spacing and scale carry hierarchy.
- **Do** pair every state with an icon, a Spanish label and a color; test by viewing the screen in grayscale.
- **Do** say "no se pudo verificar" when a check fails, and use `risk-abstain`, not `noneDetected`.
- **Do** keep 48 dp targets, 8 dp gaps and layouts that survive 200% text scale and a screen reader.
- **Do** label every screen that reads mock data with the example-data banner.
- **Do** state platform limits plainly when Android blocks something, and give the alternative.
- **Do** use the Quechua name and Spanish copy in sentence case ("Escudo QR", "Red de Confianza"), neutral Spanish for the whole UI.
- **Do** ask for the person's verification before restoring wallets and before any irreversible action.

### Don't:
- **Don't** use green anywhere in the risk system, or a check mark as a verdict. "Sin señales detectadas" is not "seguro".
- **Don't** use red, flashing, shaking or sirens to announce danger; one clay-red badge and a sentence are enough.
- **Don't** reintroduce the old violet, indigo and cyan gradients, glows or the "Ultra Secure" purple theme.
- **Don't** show a mascot on gate, risk, error, unverifiable or discreet screens.
- **Don't** put shadows, nested cards or decorative illustration on resting surfaces.
- **Don't** use color, opacity or motion alone to convey meaning.
- **Don't** reveal concealment on screen when discreet appearance is on: no banner, no badge, no animated change.
- **Don't** use uppercase text, runtime font downloads, or text below 13 dp for anything the person must read to decide.
- **Don't** hard-code a color, size or duration in a widget; read it from the theme.

## Departures from the reference

| Change | Reason |
| --- | --- |
| Web landing page replaced by a Flutter Android app (Operate mode) | The product surface is a phone app; hover becomes pressed, focused and disabled states |
| Button height 40 px raised to 48 dp, chips to a 48 dp hit area | `AGENTS.md` requires 48 dp touch targets |
| Display 64 px reduced to 36 dp, headings and spacing rescaled | The reference scale is for a wide hero; phones need a compact hierarchy |
| Section gap 64 px reduced to 32 dp; 6 px spacing step replaced by a 4 dp grid | Phone rhythm and a regular base unit |
| Radius 4 dp removed; card 16 dp, input 12 dp, sheet 28 dp | Sharper corners clash with pills on touch screens |
| Single accent plus one error color replaced by a teal accent and a five-state muted risk set | The product must express `RiskLevel` and the voice light without alarming and without color alone |
| Error color deepened from #D92D20 to #B42318, with a tint pair | Passes AA as text on its own tint |
| Body weight 500 changed to 400 (500 for emphasis); DM Sans 600 removed | Fewer font files to bundle offline; 3 plus 2 weights total |
| Black remains the primary action but teal is added for focus, selection and links | Focus and selection need a visible, non-black cue (3:1) |
| Added dark theme and discreet appearance | Refugio may need an ordinary-looking, calm state; dark helps at night |
| Added motion rules, a mascot section and a Flutter mapping | Not present in the reference; required by the nine-module app |
| Added example-data banner, unverifiable state, wallet gate screen and permission rationale screen | Product principles: nothing simulated, honest limits, unverifiable is not safe |

## Decisions by the owner

Recorded 2026-10-17.

1. **Name:** the mascot is the **Guardian de Comportamiento** (code name `GuardianMascot`). The AURA assistant module still exists; whether AURA is renamed is open (see Open questions).
2. **Eight states:** `idle`, `thinking`, `working`, `success` plus `listening`, `scanning`, `alert`, `stealth`. The earlier recommendation against `alert` and `stealth` is withdrawn.
3. **Animation style:** the "Grok Bot style" from `pet/animated/docs/EVALUATION.md`, inside the calm Motion budget; no loop faster than `working`.
4. **Implementation:** pure-Dart `CustomPainter` with an `AnimationController`, no new dependency, in `ui/lib/core/widgets/guardian_mascot/`, demo at `ui/lib/dev/guardian_mascot_demo_main.dart`.
5. **Fonts:** bundling the five font files and the `fonts:` entry in `ui/pubspec.yaml` is approved.
6. **Resting state:** at rest the mascot is asleep and listening (`idle`: closed eyes, slow breathing, an occasional head turn toward an imagined sound). Decided after seeing the demo on a phone.

## Open questions

Where implementers are already using a default, it is stated after "Default".

1. **Discreet navigation label.** While discreet appearance is on, should the "Refugio" tab show a different, ordinary label (and which), or keep its name? A visible "Refugio" may reveal concealment to a watcher; a renamed tab may confuse the person. Default: keep "Refugio" until decided.
2. **Tier indicator.** `AGENTS.md` asks for a clear indicator of the active concealment tier but also forbids revealing concealment. Default: the indicator lives inside Refugio, behind biometric or PIN verification.
3. **Mascot on Refugio.** Allowed at all? Default: no mascot on gate screens or discreet-appearance screens, and none on Refugio screens.
4. **AURA naming.** Is the AURA module name kept, with the mascot as the Guardian de Comportamiento, or is AURA renamed? Default: the module stays "AURA" and the mascot is "Guardian de Comportamiento".
5. **`stealth` on Inicio.** Is a nearly invisible mascot on Inicio in normal appearance acceptable, or could it hint that protection is active? Default: shown on Inicio only, normal appearance only, decorative, excluded from semantics; if rejected, `stealth` stays defined but is not placed anywhere.
6. **`behavioralDeviation` mapping.** Should the mascot states relate to `not_enrolled`, `insufficient_data`, `within_range`, `deviation`, `disabled` as proposed in the Mascot section? Default: no mapping; states follow product moments only.
7. **Accent.** Is deep teal (#0B5D6B) the right brand accent, or should the owner pick another hue (the contrast table must be rerun for any change)? Default: deep teal.
8. **Dark theme default.** Follow the system setting, or default to dark for Refugio? Default: follow the system.
9. **Landing page.** A separate Persuade-mode visual direction is needed for the Lovable landing; this file does not define it. Default: none.
