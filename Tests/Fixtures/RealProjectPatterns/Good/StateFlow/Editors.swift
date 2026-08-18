import SwiftUI

struct GoodDirectEditor: View {
    @Binding var name: String

    var body: some View {
        TextField("Name", text: $name)
    }
}

struct GoodTransactionalEditor: View {
    @Binding var name: String
    @State private var draft = ""

    func applyEdits() {
        name = draft
    }

    func abandonEdits() {
        draft = name
    }

    var body: some View {
        VStack {
            TextField("Name", text: $draft)
            Button("Apply") { applyEdits() }
            Button("Discard") { abandonEdits() }
        }
        .onAppear { draft = name }
    }
}

struct GoodFocusedActionLeaf: View {
    let value: String
    let submit: (String) -> Void

    var body: some View {
        Button("Submit") { submit(value) }
    }
}
