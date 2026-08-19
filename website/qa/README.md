# Website visual-source provenance

This directory contains design evidence only. The build allowlist excludes it
from `website/public/`.

## Selected visual target

- Repository copy: `selected-visual-target.png`
- Source: built-in ImageGen result
  `/Users/eugenepotapenko/.codex/generated_images/01a01a7d-9fa2-72a0-ad8d-6b0722108c2a/exec-07e48783-4f6b-4e64-975c-d7ec3d47ea35.png`
- Direction: Annotated X-Ray; warm editorial paper, a dark semantic-analysis
  section, compact annotated examples, a protected draft, workflow, semantic
  diff, grouped rules, limits, and two-step installation.
- Dimensions: 863 by 1822 pixels
- SHA-256: `eef915629db0694d237af5cb28aacbe622ee1ae4ce12f5f0376f07450f6542dc`
- Treatment: copied byte-for-byte; no crop or resize.

Generated microcopy, dates, commands, and finding details in the visual target
are placeholders. The website contracts and fixture-backed repository evidence
remain authoritative.

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

The implementation was captured from `http://127.0.0.1:4173/` with the
in-app browser's Chrome DevTools Protocol `Page.captureScreenshot` path. Each
capture is a lossless full-page PNG made at device-pixel ratio 2. The physical
width is exactly twice the CSS viewport width; no accepted render was resized
or upscaled.

| File | CSS viewport | Full-page pixels | SHA-256 |
| --- | --- | --- | --- |
| `rendered-desktop-1280-hidpi.png` | 1280 by 720 | 2560 by 15122 | `41c59e26f90a0ac6f6271ed57b78d8a738e83b18098b0aa25942a62061c1b2ff` |
| `rendered-1024-hidpi.png` | 1024 by 768 | 2048 by 15054 | `f20048e2f171d41055421cce5adc8922068686107cb84314e2e90e1497d2a4fe` |
| `rendered-768-hidpi.png` | 768 by 900 | 1536 by 20346 | `faed1f7e91f66fdf9d2a1226bbe40138b19a4880ae123d4fb164ed8b237e8fdf` |
| `rendered-390-hidpi.png` | 390 by 844 | 780 by 26504 | `4e86cda2b2684068a07260e2e042d664537f1700ded5a78fcbc615456366358a` |
| `rendered-320-hidpi.png` | 320 by 720 | 640 by 27804 | `c49a39abc007fc8535acc23f713fb55958776bd21558460cb712f4e41f9fe90d` |

The native files were inspected directly and at their intended CSS sizes.
They remain the accepted implementation evidence.

## Comparison derivatives

These PNGs place source and implementation evidence in one image for visual
analysis. They are not production assets or accepted native captures.

- `comparison-full.png`: the full 863 by 1822 target followed by the full
  desktop render reduced from 2560 by 15122 to 863 by 5098; output 863 by
  6920; SHA-256
  `4467e0fef539ff38f22aac01a260f8db4e9b4969ea73cf4538209b2fa8614bdc`.
- `comparison-hero.png`: target crop `(0, 0, 863, 330)` followed by desktop
  crop `(0, 0, 2560, 1500)` reduced to 863 by 506; output 863 by 836;
  SHA-256
  `9af9c02a5670210656a842c5346e142913a5a2c9a619042a9e167fb147cecc4e`.
- `comparison-xray.png`: target crop `(0, 300, 863, 440)` followed by desktop
  crop `(0, 1250, 2560, 2800)` reduced to 863 by 944; output 863 by 1384;
  SHA-256
  `b3a007d1606eba02b372f4ff1d203f7caba062a53206b7c1b9c24c0d7ecc6bf4`.

All crop rectangles use `(x, y, width, height)` in source pixels. Native
source files are retained beside the derivatives.
