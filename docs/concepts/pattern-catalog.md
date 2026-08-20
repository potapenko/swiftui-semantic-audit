# SwiftUI architecture pattern catalog

These complete Before/Evidence/Safer shape examples show the SwiftUI topology
that `swiftui-audit` can make inspectable for a coding agent. They are not
wrapper prescriptions or automatic fixes. A finding identifies bounded
evidence; the agent still has to establish ownership, lifetime, write authority,
transformations, transactions, effects, and product intent.

The [visual walkthrough](https://swiftui-audit.dev/#examples) presents a compact
selection. This catalog keeps the full code paths, including callback tunnels
and repository/lifecycle composition that belong in long-form documentation.

[Back to concepts](README.md) · [Rule reference](../reference/rules.md)

## Remove a duplicate owner

An agent adapting an editor to an external owner can keep the existing local state and add reciprocal synchronization. The result compiles, but one logical value now has two mutable representations:

```swift
struct NameEditor: View {
    @Binding var name: String
    @State private var draft = ""

    var body: some View {
        TextField("Name", text: $draft)
            .onAppear { draft = name }
            .onChange(of: name) { _, value in draft = value }
            .onChange(of: draft) { _, value in name = value }
    }
}
```

The audit reports the topology, not a wrapper preference:

```text
mirrored-state          high
manual-two-way-sync     high
logical sources         2
```

When both representations mean the same thing and share one lifetime, the focused result can be direct:

```swift
struct NameEditor: View {
    @Binding var name: String

    var body: some View {
        TextField("Name", text: $name)
    }
}
```

A screen with real **Apply** and **Discard** behavior is different. Its local draft should remain local. The tool distinguishes transaction topology from an accidental mirror instead of prescribing “Binding everywhere.”

## Narrow a model tunnel created during view extraction

When an agent breaks a large screen into smaller views, passing the existing model through every new initializer is the easiest way to keep the code compiling:

```swift
struct AccountScreen: View {
    @State private var model = AccountModel()

    var body: some View {
        AccountSection(model: model)
    }
}

struct AccountSection: View {
    @Bindable var model: AccountModel

    var body: some View {
        AccountRow(model: model)
    }
}

struct AccountRow: View {
    @Bindable var model: AccountModel

    var body: some View {
        HStack {
            Text(model.email)
            Button("Retry") { model.retrySync() }
        }
    }
}
```

The audit follows the same observable value across component boundaries and records where the leaf actually uses the broad dependency:

```text
observable-model-tunnel   medium   strong-inference   depth 2
broad-observable-input    medium   candidate
```

The focused version passes the reusable leaf only the value and action it needs:

```swift
struct AccountScreen: View {
    @State private var model = AccountModel()

    var body: some View {
        AccountSection(
            email: model.email,
            retry: model.retrySync
        )
    }
}

struct AccountSection: View {
    let email: String
    let retry: () -> Void

    var body: some View {
        AccountRow(email: email, retry: retry)
    }
}

struct AccountRow: View {
    let email: String
    let retry: () -> Void

    var body: some View {
        HStack {
            Text(email)
            Button("Retry", action: retry)
        }
    }
}
```

A screen or feature container may legitimately own or receive a broad model. The candidate becomes actionable only after the agent proves that the receiving view is a reusable leaf rather than that owner.

## Keep derived form state derived

An agent adding validation can store a convenience flag and update it from every input change:

```swift
struct SignupForm: View {
    @State private var email = ""
    @State private var password = ""
    @State private var canContinue = false

    var body: some View {
        Form {
            TextField("Email", text: $email)
            SecureField("Password", text: $password)
            Button("Continue") {}
                .disabled(!canContinue)
        }
        .onChange(of: email) { _, _ in updateValidation() }
        .onChange(of: password) { _, _ in updateValidation() }
    }

    private func updateValidation() {
        canContinue = email.contains("@") && password.count >= 8
    }
}
```

The flag is mutable, but its value is fully determined by two other representations:

```text
stored-derived-state   medium   strong-inference
```

Keeping the rule in one computed value removes the synchronization paths:

```swift
struct SignupForm: View {
    @State private var email = ""
    @State private var password = ""

    private var canContinue: Bool {
        email.contains("@") && password.count >= 8
    }

    var body: some View {
        Form {
            TextField("Email", text: $email)
            SecureField("Password", text: $password)
            Button("Continue") {}
                .disabled(!canContinue)
        }
    }
}
```

Server validation, debouncing, or another independent lifetime may justify stored state. The agent must prove that lifecycle instead of replacing every derived-looking property mechanically.

## Expose a command-shaped Binding

An agent connecting a control to an existing model method can hide a command behind a conventional-looking `Binding`:

```swift
struct PagePicker: View {
    @Bindable var model: PagerModel

    var body: some View {
        Picker(
            "Page",
            selection: Binding(
                get: { model.selectedPage },
                set: { model.selectPage($0) }
            )
        ) {
            Text("Overview").tag(0)
            Text("Activity").tag(1)
        }
    }
}
```

The setter calls a command rather than directly expressing one focused value mutation, while the reusable picker receives the whole model:

```text
command-shaped-binding    medium   strong-inference
broad-observable-input    medium   candidate
```

If `selectPage` is only an identity write, a direct focused Binding expresses the same authority without the hidden adapter:

```swift
struct PagePicker: View {
    @Binding var selectedPage: Int

    var body: some View {
        Picker("Page", selection: $selectedPage) {
            Text("Overview").tag(0)
            Text("Activity").tag(1)
        }
    }
}
```

If the method validates a transition, persists data, records analytics, or performs another effect, replacing it with a direct Binding would change behavior. In that case the agent must preserve the command as an explicit action boundary and verify its timing instead of optimizing for a lower finding count.

## Collapse a value-and-callback tunnel

An agent asked to avoid passing `Binding` can replace it with a value and setter callback, then forward both through every extracted component:

```swift
struct VolumeScreen: View {
    @State private var volume = 0.5

    var body: some View {
        VolumeSection(volume: volume) { newValue in
            volume = newValue
        }
    }
}

struct VolumeSection: View {
    let volume: Double
    let onVolumeChanged: (Double) -> Void

    var body: some View {
        VolumeRow(
            volume: volume,
            onVolumeChanged: onVolumeChanged
        )
    }
}

struct VolumeRow: View {
    let volume: Double
    let onVolumeChanged: (Double) -> Void

    var body: some View {
        VolumeSlider(
            volume: volume,
            onVolumeChanged: onVolumeChanged
        )
    }
}

struct VolumeSlider: View {
    let volume: Double
    let onVolumeChanged: (Double) -> Void
    @State private var localVolume = 0.0

    var body: some View {
        Slider(value: $localVolume)
            .onAppear { localVolume = volume }
            .onChange(of: volume) { _, newValue in
                localVolume = newValue
            }
            .onChange(of: localVolume) { _, newValue in
                onVolumeChanged(newValue)
            }
    }
}
```

When the root callback only writes the same upstream value, the audit follows the callback path through all three extracted views and sees that the leaf also created a second mutable representation:

```text
callback-binding-tunnel    medium   strong-inference   depth 3
logical sources            2
```

A focused Binding chain keeps one logical owner and removes the manual forwarding callbacks:

```swift
struct VolumeScreen: View {
    @State private var volume = 0.5

    var body: some View {
        VolumeSection(volume: $volume)
    }
}

struct VolumeSection: View {
    @Binding var volume: Double

    var body: some View {
        VolumeRow(volume: $volume)
    }
}

struct VolumeRow: View {
    @Binding var volume: Double

    var body: some View {
        VolumeSlider(volume: $volume)
    }
}

struct VolumeSlider: View {
    @Binding var volume: Double

    var body: some View {
        Slider(value: $volume)
    }
}
```

A local slider draft and callback remain appropriate when they implement throttling, a transaction, validation, or another distinct lifetime. “Callbacks instead of Binding” and “Binding everywhere” are both insufficient rules.

## Move external work out of a reusable leaf

During extraction, an agent can move a repository and its lifecycle modifier together with the visible grid:

```swift
struct RecommendationsGrid: View {
    let categoryID: String
    let repository: RecommendationsRepository
    @State private var items: [Recommendation] = []

    var body: some View {
        GridView(items: items)
            .task(id: categoryID) {
                items = await repository.load(categoryID: categoryID)
            }
    }
}
```

With exact project configuration identifying the repository role, the audit reports both the dependency boundary and the lifecycle-triggered command. Finding dominance suppresses the more generic external-effect finding for the same call:

```text
service-or-repository-in-view   high     strong-inference
hidden-command-in-lifecycle     medium   candidate
```

The reusable grid can remain a presentation component while a feature container owns the model, loading lifetime, and repository interaction:

```swift
struct RecommendationsContainer: View {
    @State private var model: RecommendationsModel

    var body: some View {
        RecommendationsGrid(items: model.items)
            .task(id: model.categoryID) {
                await model.loadCurrentCategory()
            }
    }
}

struct RecommendationsGrid: View {
    let items: [Recommendation]

    var body: some View {
        GridView(items: items)
    }
}
```

The lifecycle command may still be a candidate on the container. That is intentional: the goal is not zero findings, but a defensible owner whose lifetime matches cancellation and reload behavior. Role-aware conclusions require a validated `.swiftui-audit.json`; type names such as `Repository` or `Model` never establish authority by themselves.

## Continue

- [Functional SwiftUI](functional-swiftui.md) explains the ownership and
  transaction model behind these examples.
- [Deterministic facts and agent judgment](deterministic-facts-and-agent-judgment.md)
  separates extractor evidence from contextual conclusions.
- [Audit workflow](../workflows/audit.md) shows how to investigate one finding
  without reading broad source first.
