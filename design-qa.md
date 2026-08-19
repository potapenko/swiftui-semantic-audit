# Landing page design QA

**Findings**

- No actionable P0, P1, or P2 findings remain. The selected Annotated X-Ray
  direction is recognizable across desktop, tablet, and mobile, while the
  longer implementation preserves the approved evidence and installation
  content.

**Comparison target**

- Source visual truth:
  `website/qa/selected-visual-target.png`
- Implementation:
  `website/qa/rendered-desktop-1280-hidpi.png`
- Route and state: `http://127.0.0.1:4173/`, English, single art-directed
  theme, default navigation and FAQ state.
- Desktop viewport: 1280 by 720 CSS pixels at device-pixel ratio 2; full-page
  implementation capture 2560 by 15122 pixels.
- Full-view comparison: `website/qa/comparison-full.png`.
- Focused comparisons: `website/qa/comparison-hero.png` and
  `website/qa/comparison-xray.png`. These make headline, typography, code,
  evidence annotations, borders, and section transitions readable at review
  scale.

**Accepted deviations**

- The production page is longer than the generated target because it uses
  complete fixture-backed examples, exact installation boundaries, the full
  grouped rule map, and product limits. The target's compressed pseudo-copy
  was design evidence, not product authority.
- The desktop hero wraps to three lines instead of two. It retains the same
  editorial emphasis and gives the factual product boundary enough space.
- The workflow has the three released specialist phases: Audit, Refactor, and
  Review. The target's five placeholder steps were not copied.
- The implementation removes fake fix controls and replaces target dates,
  commands, and finding labels with verified 0.4.0 content.

**Required fidelity surfaces**

- Fonts and typography: the implementation uses a local system sans stack and
  local monospace stack, as required by the no-runtime-font contract. Display,
  body, annotation, and code weights remain distinct; no clipping or broken
  wrapping appears from 1280 down to 320 CSS pixels.
- Spacing and layout rhythm: warm paper, dark analysis, cool evidence, and
  mint protected-case sections preserve the target's editorial sequence.
  The expanded vertical rhythm is intentional and keeps code readable.
- Colors and visual tokens: paper, ink, blue, dark analysis, green, and amber
  map closely to the source direction. Checked foreground/background ratios
  range from 4.70:1 to 17.36:1 for the sampled normal-text pairs.
- Image quality and assets: all accepted captures are lossless DPR2 PNGs.
  The 1200 by 630 social preview is sharp at intended size. Visible icons use
  one local Tabler Icons v3.46 family; there are no emoji, CSS illustrations,
  inline SVG substitutes, stock images, or placeholder imagery.
- Copy and content: English copy is factual, bounded, and consistent with the
  release contracts. The `de-ai-writing` landing pass found only informational
  rule-of-three and extraction-length heuristics; no blocking rhetorical,
  manipulative, generic, or unsupported claims remain.

**Responsive, interaction, and accessibility evidence**

- Lossless DPR2 renders were inspected at CSS widths 1280, 1024, 768, 390,
  and 320. DOM checks report no document-level horizontal overflow at any
  width; code and the semantic ledger keep their own usable overflow boundary.
- At 390 CSS pixels the menu opens, reports `aria-expanded="true"`, and closes
  with Escape. The first FAQ item expands through its native `details` control.
- The CLI copy control wrote the exact two-line command to the clipboard and
  announced `Copied to the clipboard.` through its live status.
- With JavaScript disabled, the main text and both install steps remain
  visible, navigation remains available, and enhancement-only copy controls
  are hidden.
- With reduced motion enabled, transitions and animations resolve to
  `0.00001s` and smooth scrolling resolves to `auto`.
- The first focus target is the skip link to `#main-content`. Focus inspection
  confirms a visible 3-pixel amber outline and an on-canvas transform. Links,
  buttons, summaries, scrollable code, and the ledger use native focusable
  elements with labels.
- Browser console warnings and errors: none.

**Patches made since the previous QA pass**

- Completed canonical, Open Graph, X, JSON-LD, icon, theme-color, robots, and
  social-image metadata required by the deterministic builder.
- Marked editorial model and transactional examples as representative rather
  than exact composites, and replaced a rhetorical proof heading with a
  factual semantic-diff heading.
- Added production-page contract coverage for internal links, duplicate IDs,
  copy hooks, no-JavaScript installation content, the 29-rule surface, and
  forbidden claims.
- Added focused hero and X-Ray comparison evidence plus full capture
  provenance and hashes.

**Implementation checklist**

- [x] Source and implementation opened and compared together.
- [x] Five required fidelity surfaces reviewed.
- [x] Responsive, interaction, no-JavaScript, focus, reduced-motion, and
  contrast states checked.
- [x] P0/P1/P2 mismatch list is empty.

**Follow-up polish**

- No required P3 work remains before local handoff. A later public-domain pass
  should recapture metadata and deployment evidence against the authorized
  canonical URL without changing the visual system.

final result: passed
