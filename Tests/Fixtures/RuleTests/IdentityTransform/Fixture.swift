import SwiftUI

struct IdentityTransformEditor: View {
    @State private var primary = 0.0
    @State private var secondary = 0.0

    var body: some View {
        VStack {
            Slider(value: $primary)
            Slider(value: $secondary)
        }
        .onChange(of: primary) { _, _ in
            secondary = primary + 0
        }
        .onChange(of: secondary) { _, _ in
            primary = secondary - 0
        }
    }
}
