import SwiftUI

struct BindingSelfCopyField: View {
    @Binding var name: String

    var body: some View {
        TextField("Name", text: $name)
            .onChange(of: name) {
                name = name
            }
    }
}
