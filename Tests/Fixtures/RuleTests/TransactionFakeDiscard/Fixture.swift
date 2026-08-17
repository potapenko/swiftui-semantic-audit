import SwiftUI

struct FakeDiscardEditor: View {
    var sourceValue: String
    @State private var editingValue = ""

    func applyEdits() {
        sourceValue = editingValue
    }

    func unrelatedEmptyAction() {}

    var body: some View {
        VStack {
            TextField("Value", text: $editingValue)
            Button("Primary") { applyEdits() }
            Button("Secondary") { unrelatedEmptyAction() }
        }
        .onAppear { editingValue = sourceValue }
    }
}
