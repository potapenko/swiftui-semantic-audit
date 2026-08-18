import SwiftUI

struct BadMirroredEditor: View {
    @Binding var canonicalName: String
    @State private var editableName = ""

    var body: some View {
        TextField("Name", text: $editableName)
            .onAppear {
                editableName = canonicalName
            }
            .onChange(of: canonicalName) { _, newValue in
                editableName = newValue
            }
            .onChange(of: editableName) { _, newValue in
                canonicalName = newValue
            }
    }
}
