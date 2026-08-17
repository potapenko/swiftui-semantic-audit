import SwiftUI

struct MissingDiscardEditor: View {
    var sourceValue: String
    @State private var editingValue = ""

    func applyEdits() {
        sourceValue = editingValue
    }

    var body: some View {
        VStack {
            TextField("Value", text: $editingValue)
            Button("Primary") { applyEdits() }
        }
        .onAppear { editingValue = sourceValue }
    }
}
