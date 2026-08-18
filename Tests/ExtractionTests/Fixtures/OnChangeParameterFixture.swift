import SwiftUI

struct OnChangeParameterEditor: View {
    @Binding var external: String
    @State private var first = ""
    @State private var transformed = ""
    @State private var oldCopy = ""

    let arbitraryCallback: (String) -> Void = { arbitrary in
        _ = arbitrary
    }

    func normalize(_ value: String) -> String {
        value.uppercased()
    }

    var body: some View {
        TextField("Value", text: $first)
            .onChange(of: external) { newValue in
                first = newValue
            }
            .onChange(of: first) { _, newValue in
                external = newValue
            }
            .onChange(of: external) { _, newValue in
                transformed = normalize(newValue)
            }
            .onChange(of: first) { oldValue, _ in
                oldCopy = oldValue
            }
    }
}
