import SwiftUI

struct TransactionalEditor: View {
    var sourceValue: String
    @State private var editingValue = ""

    func save() {
        sourceValue = editingValue
    }

    func cancel() {
        editingValue = sourceValue
    }

    var body: some View {
        VStack {
            TextField("Value", text: $editingValue)
            Button("Save") { save() }
            Button("Cancel") { cancel() }
        }
        .onAppear {
            editingValue = sourceValue
        }
    }
}
