# Landing page design QA

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
