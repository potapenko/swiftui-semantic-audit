# Configuration reference

`.swiftui-audit.json` supplies exact project facts that cannot be derived safely from naming conventions. It enables role-, feature-, and composition-root-aware rules without teaching the analyzer to guess that every type ending in `Service` is a service.

Configuration is optional. Topology-only analysis still runs without it. A rule that needs an absent classification remains silent.

## Schema

The current configuration schema is `2`. Schema `1` remains accepted and
produces the same digest and classification facts as before. Schema `2` adds
exact View roles and the `component-model` type role:

```json
{
  "schemaVersion": 2,
  "compositionRoots": [
    "ExampleApp.RootView"
  ],
  "viewRoles": {
    "ExampleApp.ProfileRow": "reusable-component"
  },
  "typeRoles": {
    "ExampleApp.ProfileModel": "feature-model",
    "ExampleApp.ProfileRowModel": "component-model",
    "ExampleApp.ProfileRepository": "repository"
  },
  "typeFeatures": {
    "ExampleApp.ProfileModel": "profile"
  },
  "pathFeatures": {
    "Features/Profile/": "profile"
  },
  "passiveEnvironmentValues": [
    "calendar"
  ]
}
```

Only `schemaVersion` is structurally required. Add the other fields when they express authoritative project knowledge.

## Fields

| Field | Type | Purpose |
| --- | --- | --- |
| `schemaVersion` | integer | `2` is current; `1` remains compatible. |
| `compositionRoots` | array of strings | Exact qualified View names allowed to own application composition. |
| `viewRoles` | object | Exact qualified View name to `screen`, `container`, or `reusable-component`; schema `2` only. |
| `typeRoles` | object | Exact qualified type name to allowed product role. |
| `typeFeatures` | object | Exact qualified type name to project-defined feature identifier. |
| `pathFeatures` | object | Normalized repository-relative directory prefix to feature identifier. |
| `passiveEnvironmentValues` | array of strings | Exact custom environment property names that are passive rather than command routers. |

Exact type assignment takes precedence over path-feature assignment.

## Allowed roles

```text
application-model
feature-model
controller
store
presenter
repository
service
player
dependency-bundle
effect-sink
component-model
```

`component-model` requires schema `2`; the other type roles are also accepted in
schema `1`. View roles are exactly:

```text
screen
container
reusable-component
```

Roles should describe the real product responsibility of the exact qualified
type or View. Do not add a role merely to make a desired finding appear or
disappear. The analyzer never infers these roles from spelling.

## Discovery

An explicit config path must exist and validate:

```bash
swiftui-audit audit Sources \
  --config .swiftui-audit.json \
  --index-store /absolute/path/to/index/store \
  --format json
```

Without `--config`:

- directory analysis considers only `<analyzed-directory>/.swiftui-audit.json`;
- file analysis considers only `.swiftui-audit.json` in that file's parent;
- the CLI never walks ancestors and never reads a user-home default.

Git-revision analysis uses only a `.swiftui-audit.json` blob at the revision root.

## Validation and fail-closed behavior

The loader rejects:

- unsupported schema versions;
- unknown fields or roles;
- duplicate contradictory entries;
- absolute path prefixes;
- path traversal segments;
- malformed UTF-8 or JSON;
- an explicit path that does not exist.

The configuration is canonicalized with sorted keys and arrays, then hashed. Reports and schema-v2 snapshot manifests carry that digest or `none`. `diff` and `check` reject inputs with different digests.

## Passive environment values

The analyzer has bounded passive SwiftUI defaults for locale, color scheme, accessibility settings, and layout direction. A project may add exact passive custom property names.

A configured spelling does not make a value passive when deterministic topology shows callable commands. Configuration supplies authority; it does not erase contradictory facts.

## Choosing the boundary

Configuration should contain facts needed for the scoped analysis, not a speculative model of the entire application. A practical first file often identifies:

- actual composition roots;
- owner types involved in the target feature;
- service/repository/effect dependencies that reach views;
- the feature boundary used by the target source paths.

Version and review this file with the source it classifies. Changing it changes the analysis basis, so compare snapshots only under the same digest.

Normative detail: [`docs/specs/analysis-config.md`](../specs/analysis-config.md).
