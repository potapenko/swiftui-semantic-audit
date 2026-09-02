# Specification Evidence Ownership

- Node type: leaf
- Status: Active
- Contract revision: `spec-23`
- Authority: [Specification coverage and evidence map](../evidence-map.md)
- Read when: identifying the owner of facts, findings, persistence, comparison, judgment, or acceptance.
- Do not read when: only clause coverage or evidence precedence is needed.
- Maximum size: 100 physical lines.

## Ownership map

- Product authority: user-approved base epoch `tz-v1` plus semantic, release, local-activation, website, cache-hygiene, and skill-invocation addenda through `SKILL-BALANCED-INVOCATION-001`, combined as `tz-v29`; `REALISTIC-FIXTURES-001` remains acceptance/restore evidence without its own semantic epoch.
- Semantic schema owner: `AuditCore` plus SnapshotStore transport.
- Syntax fact owner: SwiftSyntaxFrontend and SwiftUISemantics vocabulary.
- Compiler fact owner: SymbolResolution/IndexStoreDB on macOS.
- Incremental fact-cache owner: AnalysisCache, with frontend dependency metadata and compiler-unit fingerprints supplied by their fact owners.
- Finding owner: AuditRules over normalized graph.
- Component-role authority owner: validated config schema 2; AuditCore applies exact View/type/passive roles and AuditRules consumes them without name inference.
- Persistence/slice owner: SnapshotStore and ContextSlicer.
- Comparison/policy/doctor owner: SemanticDiff and CLI commands.
- Project setup/runtime owner: ProjectWorkspace for manifest/setup identity, timeout/config precedence, and WatcherRuntime for freshness, typed builds, service lifecycle, live snapshots, and baseline promotion.
- Agent judgment owner: the surrounding agent, optionally supported by the implicitly discoverable router in bounded assist mode or by explicitly invoked strict workflows, always limited by the immutable fact boundary. Specialists never activate directly from ordinary work.
- Public narrative owner: product and website contracts; 0.6.0 release/site and public-installation facts remain pinned by `BASE-REL-015`, while README/reference candidate notes may record the locally active unpublished 0.6.1 and local `UPDATE-UX-001` candidate without changing public website or release claims.
- Acceptance owner: fixtures/tests, canonical baseline, dogfood commands, and CI.
- Release-distribution owner: immutable upstream tag/archive plus the independently versioned `potapenko/homebrew-tap` formula, local CLI and tagged-skill installation, hosted source test, public-site verification, and `BASE-REL-015` for public 0.6.0. `BASE-REL-017` owns the pinned local candidate CLI archive/tap/keg; `BASE-REL-018` records the prior explicit-only skill activation and `BASE-REL-019` owns the current balanced local skill checkout, active links, and rollback receipt. No public 0.6.1 distribution owner or receipt exists.
