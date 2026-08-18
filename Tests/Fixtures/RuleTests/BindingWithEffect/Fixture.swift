import SwiftUI

struct BindingWithEffectEditor: View {
    @Binding var value: Int
    let onCommit: () -> Void

    var body: some View {
        Picker(
            "Value",
            selection: Binding(
                get: { value },
                set: { newValue in
                    value = newValue
                    onCommit()
                }
            )
        ) {
            Text("Zero").tag(0)
        }
    }
}
