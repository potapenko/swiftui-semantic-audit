import SwiftUI

struct MismatchLevelThree: View {
    let value: Double
    let onValueChanged: (Double) -> Void

    var body: some View {
        Text("\(value)")
            .onChange(of: value) { _, newValue in
                onValueChanged(newValue)
            }
    }
}

struct MismatchLevelTwo: View {
    let value: Double
    let onValueChanged: (Double) -> Void

    var body: some View {
        MismatchLevelThree(value: value, onValueChanged: onValueChanged)
    }
}

struct MismatchLevelOne: View {
    let value: Double
    let unrelatedValue: Double
    let onValueChanged: (Double) -> Void

    var body: some View {
        MismatchLevelTwo(value: unrelatedValue, onValueChanged: onValueChanged)
    }
}

struct MismatchRoot: View {
    @State private var value = 0.0
    @State private var unrelatedValue = 10.0

    var body: some View {
        MismatchLevelOne(value: value, unrelatedValue: unrelatedValue) { newValue in
            value = newValue
        }
    }
}
