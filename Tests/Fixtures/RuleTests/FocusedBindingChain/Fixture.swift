import SwiftUI

struct FocusedBindingLeaf: View {
    @Binding var query: String

    var body: some View {
        TextField("Query", text: $query)
    }
}

struct FocusedBindingMiddle: View {
    @Binding var query: String

    var body: some View {
        FocusedBindingLeaf(query: $query)
    }
}

struct FocusedBindingRoot: View {
    @State private var query = ""

    var body: some View {
        FocusedBindingMiddle(query: $query)
    }
}
