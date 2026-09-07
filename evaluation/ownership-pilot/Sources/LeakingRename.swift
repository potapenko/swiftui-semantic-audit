import SwiftUI
struct LeakingRename: View {
    @Binding var title: String
    @State private var pending = ""
    func save() { title = pending }
    func cancel() { pending = title }
    var body: some View {
        VStack {
            TextField("Title", text: $pending)
            Button("Save") { save() }
            Button("Cancel") { cancel() }
        }
        .onAppear { pending = title }
        .onChange(of: pending) { _, _ in save() }
    }
}
