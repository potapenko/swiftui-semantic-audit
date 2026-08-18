import SwiftUI

final class AppModel { func refresh() {} }
final class ServiceManager { func load() {} }

struct AppRoot: View {
    let model: AppModel
    var body: some View { Text("Root") }
}

struct FocusedLeaf: View {
    let value: Int
    @FocusState private var focused: Bool
    @State private var selection: TextSelection

    var body: some View {
        Button("Focus") { focused = true }
        Canvas { context, size in
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.blue))
        }
        Button("Load") { ServiceManager().load() }
    }
}

struct EmptyAdapter: NSViewRepresentable {
    func makeNSView(context: Context) -> NativeView { NativeView() }
    func updateNSView(_ nsView: NativeView, context: Context) {}
}

#Preview {
    FocusedLeaf(value: 1)
}
