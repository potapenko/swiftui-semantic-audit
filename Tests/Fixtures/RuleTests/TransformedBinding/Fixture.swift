import SwiftUI

struct TransformedBindingEditor: View {
    @Binding var value: Int

    func clamp(_ value: Int) -> Int {
        min(max(value, 0), 10)
    }

    var body: some View {
        Picker(
            "Value",
            selection: Binding(
                get: { value },
                set: { next in value = clamp(next) }
            )
        ) {
            Text("Zero").tag(0)
        }
    }
}
