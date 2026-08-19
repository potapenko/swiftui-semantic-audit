# Full-Library Migration Receipt

- Node type: leaf
- Status: Complete
- Batch ID: `001-full-library`
- Source epoch/revision: `tz-v6` / `spec-7`
- Semantic disposition: editorial reconciliation; no Contract Delta
- Read when: validating, reviewing, or resuming the full-library migration checkpoint.
- Do not read when: ordinary product work does not depend on migration provenance.
- Maximum size: 100 physical lines.

## Source hashes before migration

- `README.md` — `61d193fbedf8ab387b455ad59dcd2212180349017d0c87dab38ae51e8554bda8`
- `acceptance.md` — `0a614b0b07871677998ca835208ab110592ded3e514a0f316b7d72805946bfde`
- `analysis-config.md` — `eea0eaf68f2c5104c29c6bb31fdb5f83b8856fb2f7d89643807e3c29fdcf426d`
- `cli.md` — `a210daf675cd87dc305fc972a404053a39d297dbc5b744de101bc0c4bc68fee6`
- `evidence-map.md` — `16ea8787e20a2dc37a3a967f87243c230efe0d12b4c39df5953fb376ce57b6ee`
- `product-contract.md` — `902d53efa09d53544bfa27ecfa6d3352c82257b3018c1110e70f28e19f38f320`
- `release-baseline.md` — `713e2b6d4c31eaccc76531e480e79e355d986ad648363fa04e815bd905a66340`
- `rules.md` — `0eaed00f02195575ad2c2c870a8917bdbfdef80d3ee9d07d2517f97c2dc5ca40`
- `semantic-ir.md` — `fa7f8672cf7bed2603cdc3611b04423c15d387c1bab3113fb4105526bc544476`

## Validation

- Pre-write hashes matched the planned nine-source snapshot; no source drift.
- Coverage: 9 sources mapped exactly once; 0 missing, duplicate, or unknown.
- Markdown tree: 32 reachable nodes, 79 links, maximum 100 physical lines.
- Semantic equivalence: 48 normative sections and 386 stable-ID occurrences preserved.
- Routing state: Markdown only; no JSON files under `docs/specs`.
- Product implementation, tests, fixtures, CI, runtime, and global configuration were not inspected or changed by this migration.

## Migrated nodes

- [Specification root](../../README.md) — precedence, registry, routes, and migration link.
- [Product](../../product-contract.md), [rules](../../rules.md), [semantic IR](../../semantic-ir.md), and [CLI](../../cli.md) — bounded branch/hybrid trees.
- [Acceptance](../../acceptance.md), [evidence](../../evidence-map.md), and [release baseline](../../release-baseline.md) — bounded verification and realization trees.
- [Analysis configuration](../../analysis-config.md) — retained as one bounded leaf.

## Next work

None after terminal validation; the complete legacy corpus is in this batch.
