# Specification Evidence Ownership

- Node type: leaf
- Status: Active
- Contract revision: `spec-15`
- Authority: [Specification coverage and evidence map](../evidence-map.md)
- Read when: identifying the owner of facts, findings, persistence, comparison, judgment, or acceptance.
- Do not read when: only clause coverage or evidence precedence is needed.
- Maximum size: 100 physical lines.

## Ownership map

- Product authority: user-approved base epoch `tz-v1` plus semantic and release addenda through `RELEASE-0.6.0-001`, combined as `tz-v20`; `REALISTIC-FIXTURES-001` remains acceptance/restore evidence without its own semantic epoch.
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
- Public narrative owner: product and website contracts; the landing sells the accepted capability surface with the twin as the unifying explanation, README proves it, documentation operates it, skills consume it, and release-version facts remain gated by the terminal publication receipt.
- Acceptance owner: fixtures/tests, canonical baseline, dogfood commands, and CI.
- Release-distribution owner: immutable upstream tag/archive plus the independently versioned `potapenko/homebrew-tap` formula, local CLI and tagged-skill installation, hosted source test, public-site verification, and the terminal receipt that alone advances 0.6.0 from authorized candidate to public release.
