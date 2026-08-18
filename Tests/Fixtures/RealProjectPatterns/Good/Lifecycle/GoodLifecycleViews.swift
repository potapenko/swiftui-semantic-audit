import SwiftUI

struct GoodUserFocusLeaf: View {
    @FocusState private var focused: Bool

    var body: some View {
        Button("Focus") { focused = true }
    }
}

struct GoodLocalAnimationLeaf: View {
    @State private var expanded = false

    var body: some View {
        Button("Toggle") {
            withAnimation { expanded.toggle() }
        }
        .offset(x: expanded ? 8 : 0)
    }
}
