# Landing page design QA

## Audit follow-through copy and evidence (2026-09-07)

- Authority: `AUDIT-FOLLOWTHROUGH-001`, epoch `tz-v30`. The existing visual system and capability sections remain; copy now follows consistent component names and distinguishes external write access from ownership. The new disclosure shows selected fields from a real indexed finding with its source link.
- Flow: landing → mirrored-state example → open JSON evidence → inspect the source link → installation/update copy. Secondary flow: mobile navigation → Examples → menu closes.
- Environment: generated local artifact at `http://127.0.0.1:4177/`, Chromium through Playwright. Browser skill absent; no dependency installation. Local QA is not a deployment receipt.
- Page identity, meaningful initial content, no error overlay, and console health passed; no console errors or warnings. All 21 website/build/publisher tests passed, as did deterministic artifact building and JavaScript syntax checking.
- Responsive checks passed at 1280, 1024, 768, 390 and 320 CSS pixels with 2x device scale. Page scroll width equals viewport width. A 640 × 450 CSS / 4x layout reproduces the effective viewport of a 1280 × 900 / 2x page at 200% zoom without overflow. A native browser zoom shortcut was not tested; an earlier CSS `zoom` probe was not used as browser-zoom proof.
- Visual inspection covered the hero, before/after code, the open evidence disclosure and mobile reading order. Lossless PNG captures used verified 2x device scale (desktop 2560 × 1800 and mobile 640 × 1800), with no resizing of source captures. Run-owned captures were temporary and removed after acceptance; no screenshot asset was published.
- An actual clipping defect in the new disclosure was fixed: its inherited grid layout let the open JSON exceed the panel. The disclosure now uses block layout and a bounded horizontal scroll area. At 320 px the code viewport is 231 px, content is 351 px, and scrolling reaches the remaining 119.5 px; surrounding prose stays within its panel.
- Keyboard Enter toggles the disclosure with visible 3 px focus. Native details work with JavaScript disabled; install/update content stays visible and enhancement-only copy buttons are hidden. Reduced-motion context preserves readable content. Mobile navigation opens/closes correctly. Update copy exactly matches visible text and announces success.
- Existing assets, navigation targets, six copy controls, public release metadata, installation commands and separate CLI/skills ownership remain intact. Prose lint was reviewed: its remaining flags are navigation/table fragments, technical enumerations and intentional user instructions/FAQ wording, not unsupported claims.
- Limits: no screen-reader session, cross-browser comparison, native zoom shortcut, hosted CI or public deployment was performed. The same-browser rendered and interaction checks required for this local copy change passed.

## Install and update prompts

- Contract epoch: `tz-v26`, user-authorized `UPDATE-UX-001`.
- Target flow: `/` loads → a visitor reaches `Install or update` → the
  existing-installation copy control copies the exact update request → the
  icon changes to a check and the live region announces success.
- The existing install prompt remains first. The update prompt follows it
  vertically at every viewport width; the two prompts never form columns.
- The CLI-only row remains secondary and unchanged in meaning.

**Visual evidence**

- Browser plugin classification: absent. The frontend QA fallback used an
  isolated headed Playwright CLI session against the generated local artifact
  at `http://127.0.0.1:4173/`.
- Desktop installation section: 1280 by 755 pixels, SHA-256
  `b9dfef983c12631baaa3959936d8b4a1c2e4ab65691040a260ba5a7af3c29a19`.
- Mobile evidence: 390 by 1400 pixels, SHA-256
  `89dacc585f895aed5352a64b15cf1364f3abbeed3183e816a8a8c2a77f14d27e`.
- Both renders preserve the existing paper, ruled alignment, dark prompt
  surfaces, compact upper-right copy controls, and mobile reading order. The
  screenshots remain in the task-scoped `/tmp` directory until handoff; no
  generated browser artifact is committed.

**Responsive, interaction, and accessibility evidence**

- At 1280, 1024, 768, 390, and 320 CSS pixels, client width equals scroll
  width. Both prompts resolve as two vertical rows and one full-width column.
- The update control copied the exact visible 228-character prompt, displayed
  `Copied`, and announced `Copied to the clipboard.` Console errors and
  warnings: none.
- With JavaScript disabled at 390 CSS pixels, both prompts remain visible, the
  enhancement-only update copy control is hidden, and the document has no
  horizontal overflow.
- The update copy passes the `de-ai-writing` landing heuristic with score 0,
  verdict `clean`, and no reported issues.
- Static website and publisher acceptance: 21 tests passed. JavaScript syntax,
  deterministic build, and diff hygiene passed. No deployment or public-site
  mutation was performed.

## Compact actionable copy controls

- Contract epoch: `tz-v22`, user-authorized `COPY-CONTROLS-001` with placement
  correction `COPY-CONTROLS-RIGHT-001`.
- Target flow: `/` loads → a visitor reaches a use-case prompt or installation
  command → the compact upper-right icon copies the exact visible text → the
  icon changes to a check and the live region announces success.
- Scope: the three task prompts, setup prompt, and CLI-only command. Explanatory
  SwiftUI samples and inline terminology remain unchanged.
- The former large `Copy setup prompt` header action is absent. `Full guide`,
  prompt text, command text, installation ownership, and release facts remain
  unchanged.

**Visual evidence**

- Browser plugin classification: absent. The frontend QA fallback used an
  isolated headed Playwright CLI session against the generated local artifact
  at `http://127.0.0.1:4173/`.
- A 1280 by 720 CSS-pixel full-page capture was inspected against the selected
  Annotated X-Ray direction and the previously accepted capability-preserving
  implementation. It is 1280 by 7643 pixels with SHA-256
  `4556e39e812a09c24ea38368241e59ff6002f6833787f3484d6bca7a37b56e36`.
- Focused desktop evidence: use cases, 1280 by 758,
  `28a6492253e194d11d09da04049f7af2ed5ff2ed0dd1fa7ac65750d25d532005`;
  installation, 1280 by 527,
  `0c0b77c252572686bb11d8c1e36fb8c868f5ad319147a636865bbfba695e127c`.
- Focused 390-pixel evidence: use cases, 390 by 1307,
  `6310c21d59768de9b1046abb772966501557262e6378c169bce360491ce104dd`;
  installation, 390 by 778,
  `32d150b0d7737aa368d8e51d94c8787cd1b81fdda1fd253c74ccfc328e642cab`.
- The screenshots remain in the task-scoped `/tmp` QA directory only until
  handoff; no generated browser artifact is committed.

**Responsive, interaction, and accessibility evidence**

- At 1280, 1024, 768, 390, and 320 CSS pixels, client width equals scroll
  width. All five controls remain fully contained at the upper-right of their
  copy surfaces with a computed 7.2-pixel right inset.
- Every control copied text byte-for-byte from its target. Each displayed the
  check icon through the existing icon swap and announced
  `Copied to the clipboard.`
- Keyboard activation copied the CLI command. Keyboard modality produced the
  existing 3-pixel amber focus ring.
- Reduced motion resolved transition and animation duration to `0.00001s` and
  document scrolling to `auto`.
- With JavaScript disabled at 390 CSS pixels, the setup prompt and CLI command
  remain visible, no copy controls are exposed, the document has no horizontal
  overflow, and the main content remains complete.
- Page identity, meaningful DOM, framework-overlay absence, screenshot
  evidence, copy interaction, focus, responsive layout, no-JavaScript content,
  and console health passed. Console errors and warnings: none.

## Current capability-preserving semantic-twin candidate

- Contract epoch: `tz-v19`, `SEMANTIC-TWIN-STORY-001` corrected by
  `SEMANTIC-TWIN-CAPABILITIES-001`.
- The prior accepted marketing surface is restored: hero, annotated X-Ray,
  three detailed code cases, protected draft, audit/refactor/review prompts,
  semantic diff, six rule groups, trust, one-prompt installation, and FAQ.
- Semantic twin is concise connective copy in the hero, evidence labels, and
  task explanation. Version `0.5.0` remains a small header/release fact and is
  absent from the hero promise, CTA, and section narrative.
- Publication state: local implementation candidate only. No push, deployment,
  release, or public-site mutation was performed.

**Target flow**

`/` loads → a visitor sees the product outcome and concrete SwiftUI use cases
→ mobile navigation and copy feedback respond → all setup content remains
available without JavaScript.

**Current visual comparison**

- Source visual truth: `website/qa/selected-visual-target.png`, 863 by 1822.
- Latest implementation: generated local artifact at 1280 by 720 CSS pixels,
  DPR2, with a 2560 by 15376 lossless full-page PNG. SHA-256:
  `20f60ba74ba0392c3c5055325d45d88edaf16bbaffd0107f6ca494d650dd0c30`.
- Same-width check: 863 by 900 CSS pixels, DPR2, 1726 by 14892 output.
  SHA-256:
  `96940e5212072036a3c112e1cc26f7e9164f9103eba33db57ea59dcea15f96a1`.
- The target and both current renders were opened together in one visual QA
  pass. Temporary Playwright evidence remains outside the repository.

**Fidelity ledger**

- Hero: the accepted outcome-led headline remains exact. The authorized change
  names the deterministic semantic twin in supporting copy without adding a
  pipeline lecture or replacing the use-case CTA.
- Information architecture: the accepted X-Ray, three detailed patterns,
  protected transaction, task prompts, diff ledger, grouped rules, trust,
  install, and FAQ order is restored. No capability block is missing.
- Typography and palette: the warm paper, dark navy evidence canvas, blue
  action color, green/amber semantic accents, editorial sans hierarchy, and
  monospace evidence treatment match the selected X-Ray direction.
- Container model: ruled open sections and code-led evidence remain; no card
  wall, generic SaaS gradient, fake dashboard, or new visual system was added.
- Desktop anatomy: the 1280 render keeps the three-part X-Ray and three-column
  detailed examples. At the target raster's 863 CSS-pixel width, the existing
  accepted breakpoint moves X-Ray evidence below the code pair while preserving
  content and reading order.
- Responsive behavior: 768, 390, and 320 stack the same evidence vertically;
  code remains readable and no section clips or creates document overflow.
- Authorized target deviations remain the accepted product history: one skill
  is the agent entry point, one-prompt installation replaces the target's two
  equal setup cards, and the rule count is thirty rather than the target's old
  twenty-nine placeholder.
- Above-the-fold copy diff: no unapproved block, label, badge, or section was
  added. H1 and CTA roles match the accepted landing; only the user-authorized
  semantic-twin lede and fact-boundary copy changed.

**Responsive, interaction, and accessibility evidence**

- Headed Chrome used the `Desktop Chrome HiDPI` profile at DPR2. Required CSS
  widths 1280, 1024, 768, 390, and 320 all had equal client/scroll widths,
  no broken images, no console warnings, and no page errors.
- At 390 CSS pixels the menu opens with `aria-expanded="true"`, closes with
  Escape, hides again, and returns focus to its toggle.
- The install control copied the exact visible 263-character prompt, changed
  its label to `Copied`, and announced `Copied to the clipboard.`
- Without JavaScript, the main content, full setup prompt, link, CLI-only row,
  and navigation remain visible; the enhancement-only copy control is hidden.
- The first Tab target is `#main-content` with a visible 3-pixel amber outline.
  Reduced motion resolves transitions and animations to `0.00001s` and smooth
  scrolling to `auto`.
- A 640 CSS-pixel reflow check, equivalent to 200% zoom on a 1280-pixel
  viewport, had no document overflow.

**Verification**

- Browser plugin classification: absent. The user explicitly authorized an
  isolated Playwright fallback against the local generated artifact.
- Page identity, meaningful DOM, framework-overlay absence, screenshot
  evidence, mobile navigation, copy interaction, no-JavaScript behavior,
  focus, reduced motion, responsive layout, and console health: passed.
- Static website/publisher tests, deterministic build, documentation and skill
  validation, copy lint, JavaScript syntax, and diff hygiene are recorded by
  the final task verification.

## Historical `INSTALL-UX-001` evidence

**Findings at the prior epoch**

- No actionable P0, P1, or P2 findings remain. The installation area now has
  one dominant agent prompt and one compact, clearly secondary CLI-only row.

**Comparison target**

- Source visual truth: `website/qa/selected-visual-target.png`.
- Implementation: `website/qa/rendered-desktop-1280-hidpi.png`.
- Route and state: `http://127.0.0.1:4173/`, English, default navigation and
  FAQ state, local build marker `install-ux-local-final`.
- Desktop viewport: 1280 by 720 CSS pixels at device-pixel ratio 2; full-page
  implementation capture 2560 by 14744 pixels.
- Full-view comparison: `website/qa/comparison-full.png`.
- Focused comparisons: `website/qa/comparison-hero.png`,
  `website/qa/comparison-xray.png`, and `website/qa/comparison-install.png`.

**Authorized installation deviation**

- The selected target's two equal installation steps are stale design
  evidence. User-authorized `INSTALL-UX-001` replaces them with one short
  setup prompt that delegates the complete GitHub procedure to the agent.
- Homebrew remains a separate ownership boundary and appears only as a compact
  `CLI only` row. It installs `swiftui-audit`; the agent installs all four
  tagged skills.
- The installation section is 550 CSS pixels high at 1280, down from 958 in
  the first implementation pass. The full page is 7372 CSS pixels high, 189
  pixels shorter than the previous accepted 7561-pixel desktop capture.
- Detailed verification, conflicts, updates, manual setup, and removal stay in
  the GitHub guide rather than on the landing page. The guide pins installed
  artifacts to the immutable `0.5.0` release.

**Required fidelity surfaces**

- Typography and hierarchy: the local system sans and monospace stacks remain
  unchanged. The prompt is the sole primary installation object; the Brew
  command reads as supporting information rather than a second setup path.
- Spacing and layout: warm paper, dark code, cool evidence rows, ruled
  alignment, restrained radii, and the existing section order are preserved.
  The compact install composition removes repeated explanations and the
  separate post-install CTA.
- Colors and assets: existing paper, ink, blue, analysis, green, and amber
  tokens are unchanged. Visible icons remain from the local Tabler Icons
  v3.46 family; no new asset, dependency, or visual language was added.
- Copy: the setup prompt is 229 characters, names the GitHub guide, preserves
  Homebrew-first ordering, and includes the CLI plus all four agent skills.
  The focused `de-ai-writing` landing pass is clean with one informational
  long-sentence notice caused by the full GitHub URL.
- Reference fit: `comparison-install.png` records the intentional move from
  two equal steps to one prompt plus one secondary Brew row. Hero, X-Ray,
  examples, trust, FAQ, footer, and the 30-rule story remain unchanged.

**Responsive, interaction, and accessibility evidence**

- Lossless DPR2 PNGs were inspected at CSS widths 1280, 1024, 768, 390, and
  320. Every viewport reports zero document-level horizontal overflow. Full
  pages were captured in overlapping 3500-CSS-pixel segments and stitched
  without resizing; every 64-pixel overlap matched byte-for-byte. Captures
  taller than Chrome's 16384-physical-pixel boundary were checked for and do
  not contain the former duplicated prefix.
- The headed Chrome window stayed maximized at 1920 by 1050 logical pixels on
  the active 2x mirrored 4K display while responsive widths were emulated.
  Every accepted PNG is exactly twice its CSS viewport width and was not
  upscaled.
- At 390 CSS pixels the menu opens with `aria-expanded="true"`, renders the
  navigation, closes with Escape, and returns focus to the toggle.
- The single copy control writes the exact 229-character prompt, changes its
  label to `Copied`, and announces `Copied to the clipboard.`
- With JavaScript disabled, the prompt, full-guide link, CLI-only row, and
  navigation remain exposed; the enhancement-only copy button is absent.
- Reduced motion resolves transitions and animations to `0.00001s` and smooth
  scrolling to `auto`.
- The first Tab target is the `#main-content` skip link with a visible 3-pixel
  amber outline. Browser console errors and warnings: none.

**Verification**

- Automated site and publisher tests: 20 passed.
- JavaScript syntax, documentation links/anchors, deterministic site build,
  and `git diff --check`: passed.
- Page identity, meaningful DOM, framework-overlay absence, responsive layout,
  copy feedback, mobile navigation, no-JavaScript content, focus, reduced
  motion, and console health: passed.
- Browser plugin was not available in this session; the recorded fallback was
  isolated Playwright CLI with headed Chrome.
- Local QA only. No deployment or public-site mutation was performed.

**Patches made after independent review**

- Replaced invalid long Chrome screenshots with seam-validated segmented DPR2
  captures and regenerated every comparison derivative.
- Added a clone-only release-source step to the GitHub guide so the Homebrew
  path creates the source required by all four skill symlinks without building
  or installing a second CLI.
- Reduced the root README installation copy to the prompt, one CLI-only line,
  and one detailed-guide link.

final result: passed
