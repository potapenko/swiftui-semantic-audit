import SwiftUI
struct ComputedFlag: View {
    @State private var message = ""
    private var hasMessage: Bool { !message.isEmpty }
    var body: some View {
        VStack {
            TextField("Message", text: $message)
            Text(hasMessage ? "Ready" : "Empty")
        }
    }
}
