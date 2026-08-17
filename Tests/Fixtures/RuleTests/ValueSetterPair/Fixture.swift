import SwiftUI

@Observable
final class PairModel {
    var value = 0.0
}

struct ValueEditor: View {
    let value: Double
    let onValueChanged: (Double) -> Void

    var body: some View {
        Text("\(value)")
            .onChange(of: value) { _, newValue in
                onValueChanged(newValue)
            }
    }
}

struct PairRoot: View {
    @State private var model = PairModel()

    var body: some View {
        ValueEditor(value: model.value) { newValue in
            model.value = newValue
        }
    }
}
