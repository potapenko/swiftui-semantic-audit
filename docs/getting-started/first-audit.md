# Run a first audit

There are two legitimate first passes. Use indexed analysis for an agent-guided architecture conclusion. Use syntax-only analysis for standalone deterministic exploration when a build is unavailable.

## 1. Check the environment

From the target repository:

```bash
swiftui-audit doctor . --format json
```

`doctor` is non-mutating. It reports Swift, Xcode, project type, SwiftSyntax compatibility, Index Store readiness, and Git state. Required Swift or Git failures produce an error. Optional Xcode or index readiness can be warnings because the standalone CLI still supports syntax-only analysis.

## 2. Build the exact source state

Use the target project's normal build command. The resulting compiler Index Store must cover the source being audited and must correspond to the current source state.

Record the raw Index Store path from the build system. SwiftPM and Xcode may place it in different build directories; do not select a directory from its name alone. An explicit `--index-store` request fails when the raw store, compiler library, helper, or project coverage is not valid.

## 3. Decide whether configuration is needed

Topology-only rules run without configuration. Role-aware rules need exact project knowledge such as composition roots, feature ownership, and service or model roles.

If the repository contains a validated `.swiftui-audit.json`, pass it explicitly:

```bash
swiftui-audit audit Sources \
  --index-store /absolute/path/to/index/store \
  --config .swiftui-audit.json \
  --format json > audit.json
```

Without role configuration:

```bash
swiftui-audit audit Sources \
  --index-store /absolute/path/to/index/store \
  --format json > audit.json
```

Confirm that the report says `"resolution": "indexed"`. When a config was supplied, retain its `configurationDigest` for later snapshots and comparisons.

## 4. Start with findings, not broad source

An audit report contains metrics, normalized semantic values, and findings. Rank findings by severity and confidence, then group overlapping findings by semantic value, nodes, edges, and evidence.

Choose one finding and request a bounded slice:

```bash
swiftui-audit slice Sources \
  --finding finding:0123456789abcdef \
  --index-store /absolute/path/to/index/store \
  --config .swiftui-audit.json \
  --format llm-json \
  --token-budget 10000 > slice.json
```

Omit `--config` only when the audit was intentionally topology-only. Follow the slice's `sourceEvidence` locations before opening unrelated source.

## 5. Ask the router for the conclusion

After installation, invoke the router in the target repository:

- Codex: `$swiftui-semantic Audit the SwiftUI state and data-flow architecture in this project.`
- Claude Code: `/swiftui-semantic Audit the SwiftUI state and data-flow architecture in this project.`

The router selects the audit specialist, checks indexed evidence, and separates deterministic facts from its judgment. A useful report names:

- the semantic value and current owner;
- mutable representations and logical source count;
- read, write, call, Binding, and synchronization paths;
- component-boundary or custom-setter topology when present;
- source evidence;
- indexed resolution and configuration digest;
- classification, risk, and conditional remediation;
- missing evidence when the answer remains `unknown`.

## Build-free standalone pass

When no compatible build is available, the standalone CLI can still extract its supported syntax topology:

```bash
swiftui-audit audit Sources --syntax-only --format json > audit.json
```

The report must say `"resolution": "syntax-only"`. Do not present it as an indexed agent-workflow result, and do not compare it with indexed snapshots.

## Common stopping conditions

Stop rather than filling gaps with guesses when:

- indexed coverage is stale or incomplete;
- output is not valid JSON or the command exits nonzero;
- a finding or symbol selector is ambiguous;
- compared inputs use different resolution or configuration digests;
- the slice cannot fit its mandatory envelope;
- ownership, lifetime, transformation, or transaction boundaries remain unproven.

Next: [Audit workflow](../workflows/audit.md) or [Why semantic audit](../concepts/why-semantic-audit.md).
