import SwiftUI

struct DerivedForm: View {
    @State private var username = ""
    @State private var password = ""
    @State private var canSubmit = false

    var body: some View {
        VStack {
            TextField("Username", text: $username)
            TextField("Password", text: $password)
        }
        .onChange(of: username) { _, _ in
            canSubmit = !username.isEmpty && !password.isEmpty
        }
        .onChange(of: password) { _, _ in
            canSubmit = !username.isEmpty && !password.isEmpty
        }
    }
}
