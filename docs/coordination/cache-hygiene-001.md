# Cache Hygiene Addendum

- Change ID: `CACHE-HYGIENE-001`
- Mode: Evolve
- Status: Authorized
- Authority: user approval on 2026-09-02
- Contract epoch: `tz-v28`
- Read when: implementing or verifying analysis-cache layout, retention, maintenance, or migration.
- Maximum size: 100 physical lines.

## Authorized outcome

Replace the unbounded cache-schema-1 layout with cache schema 2 without changing
semantic graph schema 2, findings, resolution, snapshots, machine output, or the
seven existing one-shot command contracts.

Cache schema 2 separates analysis-scope facts from compiler database identity:

```text
v2/
  shared/indexstoredb/<store-and-toolchain-identity>/
  scopes/<analyzed-path-identity>/
```

The analysis scope remains the canonical analyzed file or directory. Frontend
state, whole indexed results, and per-file indexed facts stay isolated by that
scope. The persistent IndexStoreDB database is shared across scopes only when
the canonical Index Store and selected index library identity match exactly.

## Bounded retention and migration

- Retain at most the two most recently used whole indexed results in each scope.
- Active v2 storage has a 2 GiB high watermark and a 1.5 GiB target; retained
  legacy v1 data is temporarily exempt during its rollback grace.
- Best-effort maintenance runs after successful indexed use, at most daily,
  removes least-recently-used inactive artifacts, and skips a database whose
  existing interprocess lock cannot be acquired.
- Maintenance failure never changes analysis output, resolution, or exit status.
- Cache schema 1 is never decoded as schema 2. After the first successful v2
  indexed result, preserve v1 for at least seven days and while any v1 artifact
  has been used within that period; only then may best-effort maintenance remove
  the non-authoritative legacy tree.
- Explicit `--cache-directory` roots use the same versioned layout and retention
  guarantees so tests and operator-selected caches do not diverge semantically.

## Protected behavior

Cold, warm, pruned, migrated, and `--no-cache` runs must remain byte-equivalent
for the same complete semantic inputs. A cache miss may cost time but cannot
weaken indexed resolution or fabricate facts. Existing public releases and the
active local 0.6.1 binary remain unchanged; this addendum authorizes current
source implementation only and does not authorize publication or installation.

## Required acceptance

Focused tests prove v2 scope layout, shared database identity, two-result
retention, high/target-watermark eviction, busy-database preservation,
seven-day legacy grace, corruption-as-miss behavior, and cached/uncached byte
equivalence. The locked full suite, build, deterministic baselines, and diff
whitespace checks must remain terminal before the implementation is accepted.
