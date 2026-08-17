import SwiftUI

struct DepthTwoLeaf: View {
    let value: Double
    let onValueChanged: (Double) -> Void

    var body: some View {
        Text("\(value)")
            .onChange(of: value) { _, newValue in onValueChanged(newValue) }
    }
}

struct DepthTwoMiddle: View {
    let value: Double
    let onValueChanged: (Double) -> Void

    var body: some View {
        DepthTwoLeaf(value: value, onValueChanged: onValueChanged)
    }
}

struct DepthTwoRoot: View {
    @State private var value = 0.0

    var body: some View {
        DepthTwoMiddle(value: value) { newValue in value = newValue }
    }
}
