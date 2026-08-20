# CLI Audit, Snapshot, and Slice

- Node type: leaf
- Status: Active
- Contract revision: `spec-5`
- Authority: [CLI contract](../cli.md)
- Read when: selecting command syntax, flags, output, status, resolution, cache, failure, or timeout behavior.
- Do not read when: the task does not invoke, document, or integrate the CLI.
- Maximum size: 100 physical lines.


## `audit`

**CLI-AUDIT-001.** Syntax:

```text
swiftui-audit audit <path> [--format json]
                      [--index-store <path> | --syntax-only] [--config <path>]
```

Evaluate exactly the thirty current rules. Human output reports total and per-rule counts; JSON emits the complete audit report.

## `snapshot`

**CLI-SNAP-001.** Syntax:

```text
swiftui-audit snapshot [<path>] [--output <directory>] [--format json]
                         [--index-store <path> | --syntax-only] [--config <path>]
```

Defaults: source `.`, output `.semantic`. Persist exactly the five files in [IR-SNAP-001](../semantic-ir/findings-snapshots-and-cache.md#persistent-snapshot). Optional JSON stdout is a manifest+summary receipt.

**CLI-SNAP-002.** Reject `/`, an empty target, source/output identity, output that is an ancestor of source, unsafe canonicalization, or replacement of a nonempty invalid directory. Absolute evidence and `generatedFrom` paths are invalid.

**CLI-SNAP-003.** Determinism checks within one revision compare all five files byte for byte. Cross-commit committed-baseline checks compare the four semantic files byte for byte and may normalize only manifest `repositoryRevision`; all other manifest fields must match exactly, and a fresh snapshot must record the checked-out `HEAD`.

## `slice`

**CLI-SLICE-001.** Syntax:

```text
swiftui-audit slice [<input>] (--finding <id> | --symbol <selector>)
                      [--format llm-json] [--token-budget <positive-int>]
                      [--index-store <path> | --syntax-only] [--config <path>]
```

Require exactly one selector. Input resolution order is an explicit input, then `.semantic`, then live source. `--index-store` applies only to live source.

**CLI-SLICE-002.** Symbol selectors accept exact stable ID, qualified name, or an unambiguous suffix. Reject unknown and ambiguous selectors. Reject nonpositive or too-small budgets.
