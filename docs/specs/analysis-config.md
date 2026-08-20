# Analysis configuration contract

- Node type: leaf
- Status: Active
- Contract revision: `spec-2`
- Authority: `ARCHITECTURE-001` plus `COMPONENT-SURFACE-001`, epoch `tz-v13`
- Read when: role-aware project analysis needs configuration schema, matching, discovery, optionality, digest, or passive-environment rules.
- Do not read when: the task uses topology-only analysis without role, feature, composition-root, or passive-environment authority.
- Maximum size: 100 physical lines.

Revision: `spec-2`
Configuration schema: `2`; schema `1` remains accepted
Authority: `COMPONENT-SURFACE-001`, epoch `tz-v13`

## Purpose

**CFG-001 — Explicit roles.** Application/feature models, controllers, stores, presenters, repositories, services, players, dependency bundles, and effect sinks are product roles. The analyzer must never assign these roles from spelling alone.

**CFG-002 — File.** Role-aware analysis accepts an optional UTF-8 JSON file named `.swiftui-audit.json`, or an explicit `--config <path>`. Schema 1 retains its original fields and canonical digest. Schema 2 adds `viewRoles`:

```json
{
  "schemaVersion": 2,
  "compositionRoots": ["PlayphrasemeApp.ReelsRootView"],
  "viewRoles": {
    "PlayphrasemeApp.ReelRow": "reusable-component"
  },
  "typeRoles": {
    "PlayphrasemeApp.FavoritesModel": "feature-model",
    "PlayphrasemeApp.ReelRowModel": "component-model",
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

**CFG-003 — Roles.** Type roles are the schema-1 owner/effect roles plus schema-2 `component-model`. View roles are exactly `screen`, `container`, and `reusable-component`. A View or type receives a role only from an exact qualified-name entry.

**CFG-004 — Matching.** Type, View, and composition-root entries match exact qualified names. Path-feature entries use normalized repository-relative directory prefixes. Exact type assignment takes precedence over path assignment. Unknown fields, roles, schema versions, duplicate contradictory entries, absolute paths, and traversal segments fail closed. `viewRoles` and `component-model` require schema 2.

**CFG-005 — Discovery.** An explicit config must exist and validate. Without `--config`, live directory analysis loads only `.swiftui-audit.json` directly inside the analyzed root; live file analysis loads only the file's parent configuration. No ancestor walk or home-directory default is allowed.

**CFG-006 — Optionality.** Topology-only rules run without configuration. Rules requiring application role, feature ownership, or composition-root authority emit no role-based conclusion when the required classification is absent; they do not guess from names.

**CFG-007 — Determinism.** Canonicalize configuration by sorted keys and arrays and compute a SHA-256 digest. Schema-v2 snapshots record the digest or `none`. Diff and check reject different configuration digests.

**CFG-008 — Passive environment.** SwiftUI's bounded passive defaults are locale, color scheme, accessibility settings, and layout direction. Projects may add exact passive environment property names. A value with callable command topology is never made passive merely by a configured spelling.

**CFG-009 — Compatibility.** Loading and applying a schema-1 file produces the same canonical configuration digest and role/feature facts as before. Schema 2 changes only exact configured facts and remains within graph schema 2 by using sorted node `roles`.
