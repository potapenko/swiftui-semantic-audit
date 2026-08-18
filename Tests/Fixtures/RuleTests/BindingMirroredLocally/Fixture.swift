import SwiftUI

struct BindingMirrorEditor: View {
    @Binding var profileName: String
    @State private var editableName = ""

    var body: some View {
        TextField("Name", text: $editableName)
            .onAppear {
                editableName = profileName
            }
            .onChange(of: profileName) {
                editableName = profileName
            }
            .onChange(of: editableName) {
                profileName = editableName
            }
    }
}
