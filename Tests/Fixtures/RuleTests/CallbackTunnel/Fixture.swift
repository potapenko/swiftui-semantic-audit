import SwiftUI

struct LevelThree: View {
    let value: Double
    let onValueChanged: (Double) -> Void

    var body: some View {
        Text("\(value)")
            .onChange(of: value) { _, newValue in
                onValueChanged(newValue)
            }
    }
}

struct LevelTwo: View {
    let value: Double
    let onValueChanged: (Double) -> Void

    var body: some View {
        LevelThree(value: value, onValueChanged: onValueChanged)
    }
}

struct LevelOne: View {
    let value: Double
    let onValueChanged: (Double) -> Void

    var body: some View {
        LevelTwo(value: value, onValueChanged: onValueChanged)
    }
}

struct TunnelRoot: View {
    @State private var value = 0.0

    var body: some View {
        LevelOne(value: value) { newValue in
            value = newValue
        }
    }
}
