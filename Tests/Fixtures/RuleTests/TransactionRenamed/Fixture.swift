import SwiftUI

struct RenamedActionEditor: View {
    var committedPayload: String
    @State private var workingCopy = ""

    func applyEdits() {
        committedPayload = workingCopy
    }

    func abandonEdits() {
        workingCopy = committedPayload
    }

    var body: some View {
        VStack {
            TextField("Value", text: $workingCopy)
            Button("Primary") { applyEdits() }
            Button("Secondary") { abandonEdits() }
        }
        .onAppear { workingCopy = committedPayload }
    }
}
