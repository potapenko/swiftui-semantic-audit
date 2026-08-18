# Audit workflow

Use an audit to answer a question about ownership, synchronization, derived state, Binding effects, model boundaries, lifecycle work, focus, selection, geometry, or platform commands. The outcome is a report, not an automatic edit.

## Entry point

Invoke the router with the project and question in scope:

- Codex: `$swiftui-semantic Audit the state ownership in the profile editor.`
- Claude Code: `/swiftui-semantic Audit the state ownership in the profile editor.`

The router should select `swiftui-semantic-audit` unless the request already authorizes a change or asks to review an existing one.

## 1. Establish indexed evidence

Build the exact source state and record the compiler Index Store that covers it. Then check the environment:

```bash
swiftui-audit doctor . --format json
```

Every live-source audit and slice command must receive the Index Store explicitly. Require `resolution: "indexed"`; do not rely on automatic discovery or silently accept syntax-only fallback.

## 2. Establish project classification

If the question depends on application roles, feature boundaries, services, repositories, composition roots, or passive environment values, validate `.swiftui-audit.json` and pass it explicitly.

Without authoritative classification, topology-only rules still run. The report must state that role-aware conclusions are unavailable rather than infer roles from type names.

## 3. Audit before reading broad source

```bash
swiftui-audit audit Sources \
  --index-store /absolute/path/to/index/store \
  --config .swiftui-audit.json \
  --format json > audit.json
```

Keep stderr and exit status separate from JSON stdout. Validate:

- schema and tool version;
- `resolution: "indexed"`;
- configuration digest, or the explicit topology-only state;
- findings, semantic values, and referenced node/edge IDs.

Group overlapping findings by semantic value and evidence instead of treating every finding as an independent defect.

## 4. Slice one relevant cluster

```bash
swiftui-audit slice Sources \
  --finding finding:0123456789abcdef \
  --index-store /absolute/path/to/index/store \
  --config .swiftui-audit.json \
  --format llm-json \
  --token-budget 10000 > slice.json
```

A symbol can be selected instead of a finding when its stable ID or qualified name is unambiguous. The slice should retain the mandatory finding/value/topology/evidence envelope.

Open source at `sourceEvidence` locations first. Expand only to a named dependency required to resolve owner, lifetime, behavior, or transaction semantics.

## 5. Classify without changing facts

The agent may classify the cluster as:

- accidental mirror;
- transactional draft;
- derived or transformed state;
- legitimate local UI state;
- command-shaped mutation or Binding factory boundary;
- observable-model tunnel or over-broad component input;
- legitimate screen/container ownership;
- unknown.

The classification must follow evidence about ownership, identity copies, reads, writes, calls, lifetime, commit/cancel actions, transformations, and component role. A wrapper name or lower wrapper count is not enough.

## 6. Report the result

A complete audit report includes:

- question and source scope;
- indexed resolution and exact Index Store path;
- configuration digest or topology-only limitation;
- semantic value and canonical owner, if established;
- representations and logical source count;
- read, write, call, Binding, synchronization, and boundary paths;
- deterministic evidence locations;
- finding severity and confidence;
- agent classification and risk;
- conditional remediation;
- exact missing evidence for every `unknown`.

Do not edit merely because a candidate exists. If the user later authorizes a change, continue with the [refactor workflow](refactor.md) and preserve all evidence identities and invariants across the handoff.

## Stop conditions

Stop and report the exact command, status, stderr, and missing evidence when indexed coverage is unavailable, JSON is invalid, a selector is ambiguous, configuration differs or is required but absent, the slice is too small, or ownership and transaction behavior remain unresolved.

An empty result after a failed command is not a clean audit.
