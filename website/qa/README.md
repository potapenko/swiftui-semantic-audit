# Website visual-source provenance

This directory contains design evidence only. The build allowlist excludes it
from `website/public/`.

## Selected visual target

- Repository copy: `selected-visual-target.png`
- Source: built-in ImageGen result
  `/Users/eugenepotapenko/.codex/generated_images/01a01a7d-9fa2-72a0-ad8d-6b0722108c2a/exec-07e48783-4f6b-4e64-975c-d7ec3d47ea35.png`
- Direction: Annotated X-Ray; warm editorial paper, a dark semantic-analysis
  section, compact annotated examples, a protected draft, workflow, semantic
  diff, grouped rules, limits, and a two-step installation placeholder.
- Dimensions: 863 by 1822 pixels
- SHA-256: `eef915629db0694d237af5cb28aacbe622ee1ae4ce12f5f0376f07450f6542dc`
- Treatment: copied byte-for-byte; no crop or resize.

Generated microcopy, dates, commands, and finding details in the visual target
are placeholders. The website contracts and fixture-backed repository evidence
remain authoritative. User-authorized `INSTALL-UX-001` intentionally
supersedes the target's two equal installation cards with one primary setup
prompt and one secondary Homebrew CLI row.

## Social preview

- Public asset: `../assets/social-preview.png`
- Source: built-in ImageGen result
  `/Users/eugenepotapenko/.codex/generated_images/01a01a7d-9fa2-72a0-ad8d-6b0722108c2a/exec-2ed27966-19e3-4251-a24b-94e6ab8503a9.png`
- Source dimensions: 1729 by 910 pixels
- Source SHA-256: `2f6e917d048afe3ac4a7d7ff6de57f2f3abd6d381dc3c52ed7e00ae7a0ade0ed`
- Published dimensions: 1200 by 630 pixels
- Published SHA-256: `2d6d7c5ca82aefdfe84e0d9237ea56063e80f26597b8f63a8db80422b37fed5f`
- Treatment: cropped and resampled once to the Open Graph aspect ratio; the
  final PNG was inspected at 100% and at its intended rendered size.

## Icons

The public icon set is Tabler Icons v3.46.0, vendored under
`../assets/icons/`. The upstream MIT license is retained as
`LICENSE-tabler.txt`. `site-icon.svg` is an unchanged copy of the official
`hierarchy-2.svg` asset.

## Rendered implementation

The implementation was captured from `http://127.0.0.1:4173/` on 2026-08-22
with isolated Playwright and headed Chrome. The Browser plugin was not
available. The browser window stayed at the maximum visible frame, position
`(0, 30)` and size 1920 by 1050 logical pixels, while Chrome device metrics
emulated the required responsive content widths.

The active display context was the online mirrored 4K pair reported by macOS:
physical `LG TV SSCR2` at 3840 by 2160, UI 1920 by 1080, hardware mirror on;
main `Virtual - LG TV SSCR2` at the same resolution, master mirror on. The
physical display was on. `NSScreen` reported a 1920 by 1080 logical frame, a
1920 by 1050 visible frame, and backing scale 2.0.

Each full page was captured as lossless DPR2 segments no taller than 3500 CSS
pixels. Adjacent segments overlap by 64 CSS pixels; every overlap matched
pixel-for-pixel before the duplicate rows were removed and the segments were
composited without resizing. The stitched width is exactly twice the CSS
viewport width. For the 768, 390, and 320 captures, a separate pixel check
confirmed that the rows after physical `y=16384` do not repeat the page prefix.

| File | CSS viewport | Full-page pixels | SHA-256 |
| --- | --- | --- | --- |
| `rendered-desktop-1280-hidpi.png` | 1280 by 720 | 2560 by 14744 | `9ebbeee735755a3263547e25994c19693c589878f7d0544f849fa8b71f2ea0c8` |
| `rendered-1024-hidpi.png` | 1024 by 768 | 2048 by 14662 | `d3a46501c8631cde9846c1bdec034a5635d1910dd9c604025e50eb0fbab1919a` |
| `rendered-768-hidpi.png` | 768 by 900 | 1536 by 19468 | `1a2951f05f192d5d389cf8a8971d9d149e7246998bddc3132e2873b23f937b08` |
| `rendered-390-hidpi.png` | 390 by 844 | 780 by 25752 | `ba3910320d0230cb756370e505cc6b61ef14e8d4d635296315144e8a01283040` |
| `rendered-320-hidpi.png` | 320 by 720 | 640 by 27402 | `b6ae1e36bdd6fd538f0c572dd00dd6ae3a16663a5b4f79189ec6dd10561bd456` |

The native files were inspected directly and at their intended CSS sizes.
They remain the accepted implementation evidence.

## Comparison derivatives

These PNGs place source and implementation evidence in one image for visual
analysis. They are not production assets or accepted native captures.

- `comparison-full.png`: the full 863 by 1822 target followed by the full
  desktop render reduced from 2560 by 14744 to 863 by 4970; output 863 by
  6792; SHA-256
  `9b568e27db1aa2dc5a9abe0412d7abaa27c8655bd17deaf9305c7d65e430622d`.
- `comparison-hero.png`: target crop `(0, 0, 863, 330)` followed by desktop
  crop `(0, 0, 2560, 1500)` reduced to 863 by 506; output 863 by 836;
  SHA-256
  `621372dd6812218267e5a5b2d087218a3c4f915835a116328ac7af1939afcb0e`.
- `comparison-xray.png`: target crop `(0, 300, 863, 440)` followed by desktop
  crop `(0, 1250, 2560, 2800)` reduced to 863 by 944; output 863 by 1384;
  SHA-256
  `8db73e98b769c9d81d2e80a135f03d2e3fd931eeb85da1075fc42f72d37c5a1c`.
- `comparison-install.png`: target crop `(0, 1500, 863, 300)` followed by
  desktop crop `(0, 11750, 2560, 1800)` reduced to 863 by 607; output 863 by
  907; SHA-256
  `cf78049d13bbf53f20270c41fbf78796aac6c8d8aeb3a945fb5357feb58638b8`.

All crop rectangles use `(x, y, width, height)` in source pixels. Native
source files are retained beside the derivatives.
