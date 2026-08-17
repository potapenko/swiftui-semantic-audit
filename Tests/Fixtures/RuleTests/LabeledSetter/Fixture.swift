import SwiftUI

@Observable
final class LabeledModel {
    var value = 0.0
}

struct LabeledValueEditor: View {
    let value: Double
    let onValueChanged: (Double) -> Void

    var body: some View {
        Text("\(value)")
            .onChange(of: value) { _, newValue in
                onValueChanged(newValue)
            }
    }
}

struct LabeledRoot: View {
    @State private var model = LabeledModel()

    var body: some View {
        LabeledValueEditor(
            value: model.value,
            onValueChanged: { newValue in
                model.value = newValue
            }
        )
    }
}
