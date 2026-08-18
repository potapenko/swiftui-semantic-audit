# Analysis configuration contract

Revision: `spec-1`
Configuration schema: `1`
Authority: `ARCHITECTURE-001`, epoch `tz-v5`

## Purpose

**CFG-001 — Explicit roles.** Application/feature models, controllers, stores, presenters, repositories, services, players, dependency bundles, and effect sinks are product roles. The analyzer must never assign these roles from spelling alone.

**CFG-002 — File.** Role-aware analysis accepts an optional UTF-8 JSON file named `.swiftui-audit.json`, or an explicit `--config <path>`. The root object contains `schemaVersion: 1` and may contain:

```json
{
  "schemaVersion": 1,
  "compositionRoots": ["PlayphrasemeApp.ReelsRootView"],
  "typeRoles": {
    "PlayphrasemeApp.FavoritesModel": "feature-model",
    "PlayphrasemeApp.ClipSearchRepository": "repository"
  },
  "typeFeatures": {
    "PlayphrasemeApp.FavoritesModel": "favorites"
  },
  "pathFeatures": {
    "Features/Favorites/": "favorites"
  },
  "passiveEnvironmentValues": ["locale", "colorScheme"]
}
```

**CFG-003 — Roles.** Allowed role values are `application-model`, `feature-model`, `controller`, `store`, `presenter`, `repository`, `service`, `player`, `dependency-bundle`, and `effect-sink`.

**CFG-004 — Matching.** Type and composition-root entries match exact qualified names. Path-feature entries use normalized repository-relative directory prefixes. Exact type assignment takes precedence over path assignment. Unknown fields, roles, schema versions, duplicate contradictory entries, absolute paths, and traversal segments fail closed.

**CFG-005 — Discovery.** An explicit config must exist and validate. Without `--config`, live directory analysis loads only `.swiftui-audit.json` directly inside the analyzed root; live file analysis loads only the file's parent configuration. No ancestor walk or home-directory default is allowed.

**CFG-006 — Optionality.** Topology-only rules run without configuration. Rules requiring application role, feature ownership, or composition-root authority emit no role-based conclusion when the required classification is absent; they do not guess from names.

**CFG-007 — Determinism.** Canonicalize configuration by sorted keys and arrays and compute a SHA-256 digest. Schema-v2 snapshots record the digest or `none`. Diff and check reject different configuration digests.

**CFG-008 — Passive environment.** SwiftUI's bounded passive defaults are locale, color scheme, accessibility settings, and layout direction. Projects may add exact passive environment property names. A value with callable command topology is never made passive merely by a configured spelling.
