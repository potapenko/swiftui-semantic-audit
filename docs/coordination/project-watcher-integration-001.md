# PROJECT-WATCHER-INTEGRATION-001 Contract Change Envelope

- Change ID: `PROJECT-WATCHER-INTEGRATION-001`
- Mode: Evolve, with Restore coverage for setup configuration discovery.
- Authorized by: user request on 2026-08-23 to repair two observed 0.6.0 consumer integrations.
- Outcome: let tracked project configuration select a bounded managed-watcher build/analysis timeout, and let setup preserve an authoritative analysis configuration directly inside the explicitly selected source root.
- Authorized domains: project manifest schema 1, setup preview/apply, watcher timeout resolution, managed service registration, project CLI help, focused tests, and watcher documentation.
- Protected domains: immutable 0.6.0 tag/archive/formula; graph, analysis-config, cache, status, and snapshot schemas; thirty rules; seven one-shot command semantics; freshness; typed build adapters; role authority; runtime-state isolation; and no-overwrite setup.
- Shared owners: `ProjectManifest`, `ProjectSetupPlanner`, `WatcherCoordinator`, `ProjectServiceController`, and the `project` CLI namespace.
- Compatibility: schema 1 gains one additive `watch.buildAndAnalysisTimeoutSeconds` member. A schema-1 manifest without it retains the released 300-second behavior. An explicit foreground `project watch --timeout` remains the highest-precedence override.
- Setup precedence: an existing manifest is authoritative and is never rewritten. For a new manifest, a regular repository-root `.swiftui-audit.json` wins; only when it is absent may setup select the regular `.swiftui-audit.json` directly inside the explicit or resolved source root. Setup never searches deeper or infers roles.
- Service behavior: `project start` resolves the manifest value and records it explicitly in the managed `project watch --timeout` arguments. Changing an already registered service requires stop/start so launchd receives the new value.
- Forbidden expansion: recursive config discovery, ancestor search, role inference, manifest migration or rewrite, arbitrary commands, service hot reload, release republication, website changes, or changes to the consumer project.
- Required evidence: legacy decode/default and canonical encoding, positive/invalid timeout validation, setup preview/apply propagation, root/source precedence, existing-manifest preservation, managed plist arguments, watcher override precedence, CLI help, focused package tests, and full `swift test`.
- Release state: source-level compatible remediation only. Public 0.6.0 artifacts and `BASE-REL-015` remain immutable; publication of another artifact requires separate authority.

## Contract Delta

Previous behavior: managed services invoked `project watch` without an override, so every build and analysis attempt used a hard-coded 300 seconds; setup looked only for a repository-root `.swiftui-audit.json` and could produce a topology-only manifest for a configured nested source root.

New behavior: new manifests canonically carry a positive build/analysis timeout, legacy manifests resolve to 300 seconds, foreground overrides remain explicit, and managed services register the manifest value. Setup uses deterministic root-then-selected-source configuration precedence while preserving every existing manifest byte-for-byte.
