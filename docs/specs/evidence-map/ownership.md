# Specification Evidence Ownership

- Node type: leaf
- Status: Active
- Contract revision: `spec-13`
- Authority: [Specification coverage and evidence map](../evidence-map.md)
- Read when: identifying the owner of facts, findings, persistence, comparison, judgment, or acceptance.
- Do not read when: only clause coverage or evidence precedence is needed.
- Maximum size: 100 physical lines.

## Ownership map

- Product authority: user-approved base epoch `tz-v1` plus semantic addenda through `SEMANTIC-TWIN-STORY-001`, combined as `tz-v18`; `REALISTIC-FIXTURES-001` remains acceptance/restore evidence without its own semantic epoch.
- Semantic schema owner: `AuditCore` plus SnapshotStore transport.
- Syntax fact owner: SwiftSyntaxFrontend and SwiftUISemantics vocabulary.
- Compiler fact owner: SymbolResolution/IndexStoreDB on macOS.
- Incremental fact-cache owner: AnalysisCache, with frontend dependency metadata and compiler-unit fingerprints supplied by their fact owners.
- Finding owner: AuditRules over normalized graph.
- Component-role authority owner: validated config schema 2; AuditCore applies exact View/type/passive roles and AuditRules consumes them without name inference.
- Persistence/slice owner: SnapshotStore and ContextSlicer.
- Comparison/policy/doctor owner: SemanticDiff and CLI commands.
- Project setup/runtime owner: ProjectWorkspace for manifest/setup identity and WatcherRuntime for freshness, typed builds, service lifecycle, live snapshots, and baseline promotion.
- Agent judgment owner: surrounding agent skills, limited by the immutable fact boundary.
- Public narrative owner: product and website contracts; the landing sells the twin, README proves it, documentation operates it, and skills consume it.
- Acceptance owner: fixtures/tests, canonical baseline, dogfood commands, and CI.
- Release-distribution owner: immutable upstream tag/archive plus the independently versioned `potapenko/homebrew-tap` formula and its brew test receipt.
