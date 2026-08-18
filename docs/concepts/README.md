# Concepts

These pages explain the architectural model behind SwiftUI Semantic Audit. Read them when a finding is technically correct but its product value or remediation is not yet obvious.

## Pages

- [Why semantic audit](why-semantic-audit.md) — why state-flow topology is more useful than wrapper counts or a raw diff.
- [Functional SwiftUI](functional-swiftui.md) — the ownership, derivation, effect, lifetime, and transaction goals the project optimizes.
- [Deterministic facts and agent judgment](deterministic-facts-and-agent-judgment.md) — which conclusions belong to the CLI and which require contextual reasoning.

## The short model

A SwiftUI view can look declarative while its data flow is maintained by imperative synchronization and hidden commands. The tool normalizes source into a graph, selects suspicious topology with bounded rules, and gives a coding agent enough evidence to judge intent.

The desired result is not a particular property-wrapper count. It is an architecture with understandable ownership, focused dependencies, minimal manual synchronization, explicit effects, and correct lifetime and transaction behavior.

[Back to documentation](../README.md)
