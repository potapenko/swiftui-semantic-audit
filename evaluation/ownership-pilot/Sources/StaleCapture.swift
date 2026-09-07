import SwiftUI
struct StaleCapture: View {
    let selectedTitle: String
    @State private var displayedTitle: String
    init(selectedTitle: String) {
        self.selectedTitle = selectedTitle
        _displayedTitle = State(initialValue: selectedTitle)
    }
    var body: some View { Text(displayedTitle) }
}
