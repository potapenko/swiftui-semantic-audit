import SwiftUI

struct UnaryDerivedForm: View {
    @State private var username = ""
    @State private var canSubmit = false

    var body: some View {
        TextField("Username", text: $username)
            .onChange(of: username) { _, _ in
                canSubmit = !username.isEmpty
            }
    }
}
