import AppKit
import SwiftUI

struct GoodDrawingLeaf: View {
    var body: some View {
        Canvas { context, size in
            context.fill(
                Path(CGRect(origin: .zero, size: size)),
                with: .color(.blue)
            )
        }
    }
}

final class GoodNativeView: NSView {}

struct GoodNativeAdapter: NSViewRepresentable {
    func makeNSView(context: Context) -> GoodNativeView { GoodNativeView() }
    func updateNSView(_ nsView: GoodNativeView, context: Context) {}
}

struct GoodButtonLeaf: View {
    var body: some View {
        Button("Activate") {}
    }
}

#Preview {
    GoodFocusedLeaf(title: "Preview", reload: {})
}
