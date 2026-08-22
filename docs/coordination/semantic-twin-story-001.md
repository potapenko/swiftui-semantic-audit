# SEMANTIC-TWIN-STORY-001 Contract Change Envelope

- Change ID: `SEMANTIC-TWIN-STORY-001`
- Mode: Evolve
- Authorized by: user approval on 2026-08-22 of the cross-surface semantic-twin content and design brief, followed by an explicit instruction to implement it.
- Outcome: make the deterministic semantic twin the primary product story across the landing page, README, operational documentation, and router-skill framing.
- Authorized domains: product positioning, website information architecture and copy, README structure, public documentation taxonomy, router-skill consumer language, metadata artwork, and local website QA.
- Protected domains: released 0.5.0 artifacts and commands; unreleased 0.6.0 watcher status; graph, cache, configuration, snapshot, and project-manifest schemas; thirty rules; Homebrew and skill-installation ownership; provider independence; no automatic rewriting.
- Previous behavior: the website and README led with `swiftui-semantic` as the product interface, while the deterministic graph, snapshots, and watcher state appeared as subordinate implementation details.
- New behavior: the product is explained first as a deterministic, simplified semantic twin of supported Swift/SwiftUI program facts. The CLI builds it; skills consume bounded evidence from it; the surrounding agent judges intent and remediation.
- Release split: public 0.5.0 builds an exact-state semantic twin on demand. The watcher remains an unreleased 0.6.0 candidate and may be described only as a separate preview. No `always-fresh` public-release claim is authorized before a terminal 0.6.0 publication receipt.
- Freshness language after 0.6.0: a live twin is agent-usable only with a matching fresh indexed status receipt, current workspace digests, indexed resolution, and matching configuration identity. Stale or failed state is diagnostics, never current evidence.
- Storage boundary: cache is a non-authoritative execution optimization; watcher live state is external; a snapshot is the canonical exact five-file serialization; a Git baseline is optional and deliberately promoted.
- Compatibility: narrative and documentation evolution only. It does not release the watcher, change analysis semantics, add commands, modify source code, or publish the website.
- Forbidden expansion: deployment, push, tag/release creation, Homebrew updates, released-skill mutation, automatic source edits, LLM-generated program facts, runtime-simulation claims, or guaranteed-correctness claims.
- Required QA: specification traversal, release-claim tests, deterministic site build, documentation/skill validation, copy lint, responsive and no-JavaScript checks, visual comparison to the accepted editorial X-Ray system, and a scoped checkpoint commit.
- Task-owned paths: the named product/website/evidence contracts, this envelope, root README, website content/styles/tests/social metadata asset, selected public docs, router skill/reference/metadata, and refreshed local website QA evidence only.

## Contract Delta

Previous public priority: one routing skill was presented as the product, and visitors learned the deterministic evidence model through examples beneath that interface.

New public priority: visitors first learn what the semantic twin preserves, why agents need it, how an exact-state agent loop consumes it, and which tasks it supports. Skills remain the recommended agent entry point, but they are consumers and workflow routers rather than the semantic product object.

Publication state: implementation candidate only. The canonical website, GitHub release, Homebrew formula, and released skills remain at 0.5.0 until separately published and verified.
