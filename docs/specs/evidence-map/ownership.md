# Specification Evidence Ownership

- Node type: leaf
- Status: Active
- Contract revision: `spec-7`
- Authority: [Specification coverage and evidence map](../evidence-map.md)
- Read when: identifying the owner of facts, findings, persistence, comparison, judgment, or acceptance.
- Do not read when: only clause coverage or evidence precedence is needed.
- Maximum size: 100 physical lines.

## Ownership map

- Product authority: user-approved base epoch `tz-v1` plus explicit semantic addenda through `INCREMENTAL-CACHE-001`, combined as `tz-v6`; `REALISTIC-FIXTURES-001` adds acceptance evidence and a restore of existing indexed semantics without advancing the product epoch.
- Semantic schema owner: `AuditCore` plus SnapshotStore transport.
- Syntax fact owner: SwiftSyntaxFrontend and SwiftUISemantics vocabulary.
- Compiler fact owner: SymbolResolution/IndexStoreDB on macOS.
- Incremental fact-cache owner: AnalysisCache, with frontend dependency metadata and compiler-unit fingerprints supplied by their fact owners.
- Finding owner: AuditRules over normalized graph.
- Persistence/slice owner: SnapshotStore and ContextSlicer.
- Comparison/policy/doctor owner: SemanticDiff and CLI commands.
- Agent judgment owner: surrounding agent skills, limited by the immutable fact boundary.
- Acceptance owner: fixtures/tests, canonical baseline, dogfood commands, and CI.
