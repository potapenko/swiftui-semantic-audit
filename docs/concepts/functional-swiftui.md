# Functional SwiftUI

In this project, “functional SwiftUI” describes a direction for data flow, not a ban on mutable state.

SwiftUI applications still need state, effects, platform adapters, and transactions. The goal is to place them where their ownership and timing are explicit, while keeping derived values and component inputs as simple as their semantics allow.

## The six questions

Before selecting `State`, `Binding`, `Bindable`, `Environment`, a value/action pair, or a draft, establish:

1. **Owner:** Which object or view owns the canonical value?
2. **Representations:** Which properties describe the same logical value?
3. **Write authority:** Which components may change it?
4. **Lifetime:** Does it live for a control, view, screen, feature, or application?
5. **Transformation:** Is another representation identical, derived, or reversibly transformed?
6. **Transaction:** Must edits be committed or discarded as a unit?

Wrapper selection comes after these answers.

## One canonical source where appropriate

If a child edits its parent's value immediately, a focused Binding can express that authority directly:

```swift
struct NameField: View {
    @Binding var name: String

    var body: some View {
        TextField("Name", text: $name)
    }
}
```

Creating another `State` solely to copy the same value back and forth adds a second mutable representation without adding product meaning.

“One source” is not an absolute rule. A local draft is valid when it has a different transaction boundary:

```swift
struct NameEditor: View {
    let original: String
    let commit: (String) -> Void
    @State private var draft: String

    // Save commits draft. Cancel discards it.
}
```

The draft is not an accidental mirror when commit and cancel are real behavior. Collapsing it into a direct Binding would change semantics.

## Derived data stays derived

When a value follows entirely from current inputs, compute it:

```swift
var visibleItems: [Item] {
    items.filter(matchesSearch)
}
```

Storing `visibleItems` as mutable state and updating it from several triggers creates synchronization work. Store it only when it has independent identity, lifetime, or transaction behavior that the derivation does not express.

Intentional transformations also deserve protection. Celsius and Fahrenheit may be two views of one measurement, but their copy paths are not identity synchronization. A refactor must preserve the conversion rather than replacing it with a direct Binding to the wrong representation.

## Focused inputs instead of owner graphs

A reusable leaf component usually needs a small interface:

```swift
struct FavoriteButton: View {
    let isFavorite: Bool
    let toggle: () -> Void
}
```

Passing an entire feature model may expose unrelated reads, writes, commands, and lifetime. Focused values, bindings, and actions make the boundary easier to preview, test, and reuse.

This is not a command to remove every model input. A screen or composition root may legitimately own or receive a model. The analyzer treats broad observable input as a candidate and uses exact project configuration for stronger role-aware conclusions.

## Effects remain explicit

A custom Binding can hide more than value mutation:

```swift
Binding(
    get: { model.isEnabled },
    set: { value in
        model.isEnabled = value
        model.persistPreference()
    }
)
```

The setter combines a write with a command. That may be intentional, but it should be visible in architectural review. A focused value mutation plus an explicit action can make ordering and failure behavior clearer when product semantics allow it.

The same principle applies to lifecycle callbacks, focus correction, selection restoration, geometry-triggered work, and platform commands. Effects are not forbidden. Hidden ownership and timing are the concern.

## Local UI state remains local

Presentation state such as expansion, hover, animation progress, or an editor selection can belong to a view. It should not be removed merely to reduce `@State` count.

The relevant tests are:

- Does it duplicate an external canonical product value?
- Does it have its own UI lifetime?
- Are its writes local and understandable?
- Would moving it outward broaden an interface or lifetime without benefit?

If the state is genuinely local, keeping it local is the more disciplined design.

## Architecture as explicit data movement

The target is a system where:

- owners and lifetimes can be named;
- values flow through focused inputs;
- derived values do not require manual repair;
- effects have visible initiation points;
- transaction and transformation boundaries survive refactoring;
- previews and tests can construct components without unrelated application state;
- semantic change can be compared before and after an edit.

That is the sense in which the project encourages a more functional style: make state transitions and dependencies explicit, keep pure relationships derived, and isolate the places where mutation or effects are required.

Next: [Deterministic facts and agent judgment](deterministic-facts-and-agent-judgment.md) or [Refactor workflow](../workflows/refactor.md).
