import SwiftUI

struct BindingTransactionalEditor: View {
    @Binding var profileName: String
    @State private var editableName = ""

    func applyEdits() {
        profileName = editableName
    }

    func abandonEdits() {
        editableName = profileName
    }

    var body: some View {
        VStack {
            TextField("Name", text: $editableName)
            Button("Primary") { applyEdits() }
            Button("Secondary") { abandonEdits() }
        }
        .onAppear { editableName = profileName }
    }
}
