# Implicit assist mode

Read this reference whenever `swiftui-semantic` was selected automatically and
the user did not invoke `$swiftui-semantic` or directly ask to run or perform a
strict semantic workflow. Merely mentioning semantic evidence, a snapshot, or
an Index Store does not cross that boundary.

## Keep the user's task primary

Use semantic evidence as supporting context for the requested implementation,
diagnosis, refactor, or review. Limit it to the affected SwiftUI ownership or
data-flow question. Do not turn the task into a separate audit or produce a
full semantic report unless the user asks for one.

Do not use this mode for layout, styling, animation, generic framework usage,
performance, concurrency, security, or other work without a material ownership
or data-flow question.

Before emitting command output, read and apply [run artifact
hygiene](artifact-hygiene.md). Before forming a CLI command, read the [CLI
invocation matrix](cli-invocation-matrix.md).

## Reuse evidence that is already ready

Prefer the narrowest available evidence in this order:

1. A compatible indexed snapshot already supplied by the user or the current
   task, with its source scope and configuration identity known.
2. A configured project whose non-waiting status already reports a fresh
   indexed live snapshot covering the affected source.
3. An already-known, fresh, project-covering Index Store path produced by the
   project's normal build. Run at most one bounded audit over the affected
   source and, only when it is needed to decide the task, one focused slice.

Accept semantic evidence only when it reports `resolution: "indexed"` and its
source scope and configuration match the task. Treat deterministic nodes,
edges, findings, identities, and locations as facts; use agent judgment only
for intent, risk, and remediation.

## Never create a semantic detour

In implicit assist mode, do not:

- configure or start a watcher;
- run project setup or change watcher lifecycle;
- build the project solely to produce an Index Store;
- create, replace, or promote a baseline or snapshot;
- load a specialist workflow or reproduce its full gate sequence;
- block source inspection, implementation, tests, or review while semantic
  evidence is unavailable;
- present lower-resolution output as equivalent semantic evidence.

If ready indexed evidence is absent, stale, incompatible, or fails the bounded
query, continue the user's task using the normal source and test evidence. Note
the missing semantic verification only when it limits a conclusion that matters
to the result. Do not ask the user to set up semantic infrastructure unless they
explicitly request the strict workflow.

## Report proportionally

Mention the semantic evidence briefly where it supports a decision or exposes a
material risk. Otherwise finish the requested task without a separate semantic
section. An assist-mode limitation is never a failure of the user's main task.
