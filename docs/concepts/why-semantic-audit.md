# Why semantic audit

SwiftUI's view syntax is declarative. State movement inside a mature application often is not.

A screen can render through a simple `body` while several mechanisms keep its values alive:

- an input is copied into local state on appearance;
- changes are copied back through `onChange`;
- the same setter is forwarded as a closure through multiple views;
- a custom `Binding` setter performs a command;
- a leaf view reaches into a large observed model;
- lifecycle or geometry events trigger model work.

Each line may be reasonable in isolation. The architectural problem appears only when those lines are connected.

## Source text hides relationships

Consider a simplified mirror:

```swift
struct Editor: View {
    @Binding var title: String
    @State private var draft = ""

    var body: some View {
        TextField("Title", text: $draft)
            .onAppear { draft = title }
            .onChange(of: draft) { _, value in title = value }
            .onChange(of: title) { _, value in draft = value }
    }
}
```

A syntax search can count `@State`, `@Binding`, and `onChange`. It cannot explain the important part by counting them: `draft` and `title` are two mutable representations of one logical value, with identity copies in both directions.

The useful representation is a graph:

```text
external title ──copiesTo──> local draft
external title <──copiesTo── local draft
TextField ──binds──> local draft
```

That topology supports a finding. The wrapper names alone do not.

## Why a linter is not enough

A conventional linter usually maps a local pattern to a warning. SwiftUI state architecture needs more context:

- A direct `Binding` can be correct.
- Local `State` can be correct when it has an independent UI lifetime.
- Two representations can be correct when one is a transactional draft with real commit and cancel behavior.
- Bidirectional values can be transformations rather than identity copies.
- A screen-level model input can be legitimate while the same model at a leaf component is too broad.

SwiftUI Semantic Audit therefore emits both strong topology-backed findings and candidates that require adjudication. It preserves the evidence needed to distinguish these cases instead of converting every mutable path into one generic warning.

## Why a raw Git diff is not enough

A Git diff shows changed text. It does not directly answer:

- Did the number of logical ownership roots change?
- Was a new write path introduced?
- Did an external value become a local mutable copy?
- Did a Binding setter gain an effect?
- Did a model cross another component boundary?
- Did a role-aware rule run under the same project classification?

Semantic snapshots and `diff` answer those structural questions. The raw diff remains necessary afterward for implementation details and behavior not represented in the graph.

## Why a coding agent benefits

Without a semantic layer, an agent often starts by reading many Swift files and reconstructing ownership in its prompt context. That approach is expensive and easy to bias toward the first plausible pattern it sees.

The audit-first workflow changes the order:

1. extract deterministic facts;
2. group them into logical values and paths;
3. select one relevant finding or symbol;
4. produce a bounded slice;
5. inspect only the evidence locations and required declarations;
6. judge intent and remediation.

This does not make the agent infallible. It makes the facts inspectable, keeps missing evidence visible, and prevents a plausible explanation from silently changing the source topology.

## What success looks like

For an investigation, success is a precise ownership report with evidence and honest unknowns.

For a refactor, success requires more than fewer findings. The target cluster should have clearer ownership and less manual synchronization, no new high-severity finding, preserved effects and lifetime, and passing behavior tests.

For review, success is a risk-ranked account of semantic changes followed by source-level review. A semantic-clean diff is useful evidence, not proof that the application still behaves correctly.

Continue with [Functional SwiftUI](functional-swiftui.md) or the [audit workflow](../workflows/audit.md).
