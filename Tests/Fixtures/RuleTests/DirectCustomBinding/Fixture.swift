import SwiftUI

struct DirectCustomBindingEditor: View {
    @Binding var value: Int

    var body: some View {
        Picker(
            "Value",
            selection: Binding(
                get: { value },
                set: { next in value = next }
            )
        ) {
            Text("Zero").tag(0)
        }
    }
}
