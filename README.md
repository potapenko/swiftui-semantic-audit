# SwiftUI Semantic Audit

**Give coding agents a map of SwiftUI state before they edit it.**

SwiftUI Semantic Audit is an architecture guardrail for coding agents. It turns state ownership, writes, bindings, effects, synchronization, and component boundaries into deterministic evidence before an agent changes code. Afterward, a semantic diff between compatible snapshots shows what the refactor actually changed.

The tool is built for SwiftUI work that crosses file boundaries: auditing an unfamiliar project, removing manual synchronization, narrowing component inputs, or reviewing an agent-authored change. It does not rewrite source by itself or ask a model to invent compiler facts.

> **Current release:** 0.4.0 for macOS 13 or later.
>
> **Development:** 0.5.0 adds opt-in config-schema-2 component roles and one candidate reusable-owner finding. Release 0.4.0 remains unchanged.

[Install](#install-the-cli-and-agent-skills) · [Copy a task prompt](#copy-a-task-prompt) · [Run the first audit](docs/getting-started/first-audit.md) · [Read the docs](docs/README.md)

## Give the agent architecture evidence

SwiftUI code can compile while hiding an imperative data-flow system underneath `body`:

- local state mirrors a value that already has an owner;
- reciprocal `onChange` handlers keep two mutable representations synchronized;
- a custom `Binding` setter performs commands unrelated to value mutation;
- leaf views receive whole models or services for one value or action;
- lifecycle, focus, geometry, or platform bridges quietly drive product behavior.

Compiler diagnostics and style linters catch different problems; a general prompt can still ask an agent to follow good SwiftUI practices. None gives the agent stable cross-file identities, evidence-backed read and write paths within the supported topology, a compatible semantic baseline, and repeatable evidence for a later review.

SwiftUI Semantic Audit extracts that bounded evidence first. The agent then decides whether a candidate is an accidental mirror, a real transactional draft, legitimate local UI state, an intentional transformation, or something that still lacks evidence.

## See the patterns an agent can introduce

The examples below are not wrapper prescriptions. Each starts with code a coding agent can plausibly introduce during extraction, cleanup, or feature work. The audit reports the topology; the agent still has to establish ownership, lifetime, transaction boundaries, and product intent before changing code.

### Remove a duplicate owner

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

### Narrow a model tunnel created during view extraction

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

### Keep derived form state derived

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

### Expose a command-shaped Binding

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

### Collapse a value-and-callback tunnel

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

### Move external work out of a reusable leaf

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

## Install the CLI and agent skills

Install the released CLI from the upstream Homebrew tap:

```bash
brew install potapenko/tap/swiftui-semantic-audit
swiftui-audit --version
```

Homebrew installs `swiftui-audit`; it does not modify an agent host. The normal workflow also installs one router and three specialist skills from the same immutable release tag.

Give a local Codex or Claude Code session this prompt:

```text
Install exactly the four SwiftUI Semantic Audit agent skills for release 0.4.0.
The CLI is already managed by Homebrew; verify `swiftui-audit --version` first.
Read and follow the tagged installation guide:
https://github.com/potapenko/swiftui-semantic-audit/blob/0.4.0/docs/getting-started/installation.md
Clone only tag 0.4.0 from
https://github.com/potapenko/swiftui-semantic-audit.git into a stable user-owned
path. Before linking anything, verify the origin, tag, and exact commit
189dc44c928f7f61b393f6e4ca7d8f6f5d183a48. Detect this agent host and link all
four sibling skill directories into its documented personal skill directory.
Do not overwrite, delete, move, or repoint an existing path. Finish with the
tag, commit, CLI version, installed paths, host, and verification receipt.
```

See [Installation](docs/getting-started/installation.md) for the complete safe procedure and source-build fallback.

## Copy a task prompt

The prompts below use Codex syntax: `$swiftui-semantic`. In Claude Code, replace it with `/swiftui-semantic`. The staged migration prompt also starts with Codex `/goal`; in Claude Code, remove that prefix and submit the rest as a project task.

### Audit a project without editing it

```text
Use $swiftui-semantic to audit this repository's SwiftUI state and data-flow
architecture. Do not edit product code or configuration. Build the exact
current source, validate a fresh project-covering compiler Index Store, and
accept only indexed evidence. Audit before reading broad source, group
overlapping findings by semantic value, and slice the highest-risk clusters.
Return canonical owners, duplicated representations, synchronization and
effect paths, legitimate exceptions, prioritized candidate refactors, and
the exact missing evidence behind every unknown.
```

### Add the guardrail to a project

```text
Preserve the repository's existing agent instructions and add one bounded
project rule: route SwiftUI tasks that change state ownership, data flow,
Bindings, effects, lifetime, or component boundaries through
$swiftui-semantic. Require its semantic review for existing changes in those
areas. Do not apply the rule to unrelated styling, layout-only, performance,
concurrency, or security work. Show the exact instruction diff before making
any other project change.
```

### Run a staged migration

```text
/goal Migrate this project's SwiftUI state and data-flow architecture with
$swiftui-semantic while preserving product behavior. Start with a read-only
indexed audit and create a restart-safe registry with one row per overlapping
finding cluster, including evidence IDs, owner, invariants, tests, risk, and
status. Process one approved cluster per checkpoint through baseline, slice,
focused edit, build, behavior tests, refreshed indexed snapshot, semantic
diff, check, and independent review. Never hide a finding by weakening scope,
configuration, thresholds, or by moving the same mechanism into another
wrapper. Finish only when every in-scope row has an evidence-backed terminal
disposition and the final configured audit matches the approved scope.
```

This prompt coordinates the existing audit, refactor, and review workflows. It is not a new CLI mode or a one-pass rewrite command.

The [prompt library](docs/getting-started/agent-prompts.md) also includes focused-refactor and existing-change review recipes with their stop conditions.

## Follow one evidence boundary

```text
Swift source + fresh compiler index
    → deterministic ownership and data-flow facts
    → evidence-backed findings and bounded slices
    → agent judgment
    → focused edit + behavior tests + semantic diff
```

The CLI owns syntax, symbols, topology, confidence, and source locations. The agent may classify intent, explain risk, and choose a conditional remediation. It must return `unknown` when ownership, lifetime, transformation, or transaction evidence is missing.

One router selects the smallest workflow:

| Requested result | Workflow |
| --- | --- |
| Explain ownership, synchronization, effects, or component boundaries | [Semantic audit](docs/workflows/audit.md) |
| Change one established state/data-flow cluster | [Data-flow refactor](docs/workflows/refactor.md) |
| Evaluate pre-existing SwiftUI changes | [Change review](docs/workflows/change-review.md) |

## Know the boundary

- Agent workflows require a fresh project-covering compiler Index Store and stop when indexed evidence is unavailable.
- Role-aware findings require exact project configuration; schema 2 can classify `screen`, `container`, `reusable-component`, and `component-model` without inferring from names.
- The 30 rules cover bounded SwiftUI topology, not every runtime, concurrency, security, or performance defect. The reusable-owner rule is a candidate for instance/lifetime review, not a ban on models in Views.
- A clean semantic diff does not prove behavior. Relevant builds and behavior tests remain required.
- The CLI does not call a model-provider API, rewrite source automatically, or install an IDE/Xcode extension.

## Go deeper

- [Getting started](docs/getting-started/README.md)
- [Why semantic audit](docs/concepts/why-semantic-audit.md)
- [Functional SwiftUI](docs/concepts/functional-swiftui.md)
- [Rules](docs/reference/rules.md)
- [CLI](docs/reference/cli.md)
- [Snapshots and semantic diff](docs/reference/outputs-snapshots-and-diff.md)
- [Development](docs/development/README.md)
- [Product specifications](docs/specs/README.md)

## License

Licensed under the repository [LICENSE](LICENSE).
