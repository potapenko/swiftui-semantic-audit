import SwiftUI
struct SummaryFlag: View {
    @State private var message = ""
    @State private var hasMessage = false
    var body: some View {
        VStack {
            TextField("Message", text: $message)
            Text(hasMessage ? "Ready" : "Empty")
        }.onChange(of: message) { _, _ in hasMessage = !message.isEmpty }
    }
}
