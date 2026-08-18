import SwiftUI

final class AppModel {
    var count = 0
    func refresh() {}
    func load(width: Double) {}
}

final class FeatureModel {
    var value = 0
}

final class OtherModel {
    var value = 0
}

final class SearchRepository {
    func load() {}
}

final class CommandRouter {
    func send() {}
}

struct AppRoot: View {
    let model: AppModel
    let repository: SearchRepository
    var body: some View { ModelLeaf(model: model) }
}

struct ModelLeaf: View {
    let model: AppModel
    var body: some View { Text("\(model.count)") }
}

struct MultiOwnerLeaf: View {
    let model: AppModel
    let feature: FeatureModel
    var body: some View { Text("owners") }
}

struct ServiceLeaf: View {
    let repository: SearchRepository
    var body: some View { Button("Load") { repository.load() } }
}

struct EnvironmentRouterLeaf: View {
    @Environment var router: CommandRouter
    var body: some View { Button("Send") { router.send() } }
}

struct BindingLifecycleLeaf: View {
    let model: AppModel
    let feature: FeatureModel
    @State private var local = 0

    var body: some View {
        Text("\(local)")
            .onAppear {
                local = model.count
            }
            .onChange(of: model.count) {
                local = model.count
            }
            .task {
                model.refresh()
            }
        Slider(value: Binding(
            get: { Double(model.count + feature.value) },
            set: { value in
                model.count = Int(value)
                feature.value = Int(value)
            }
        ))
    }
}

struct FocusSelectionLeaf: View {
    @FocusState private var focused: Bool
    @State private var first: TextSelection
    @State private var second: TextSelection

    var body: some View {
        TextField("Name", text: .constant(""))
            .task { focused = true }
            .onChange(of: first) { second = first }
            .onChange(of: second) { first = second }
    }
}

struct Child: View {
    let width: Double
    var body: some View { Text("\(width)") }
}

struct GeometryLeaf: View {
    let model: AppModel

    var body: some View {
        GeometryReader { proxy in
            Child(width: proxy.size.width)
                .offset(x: proxy.size.width)
                .coordinateSpace(name: proxy.size.height)
                .onAppear {
                    model.load(width: proxy.size.width)
                }
        }
    }
}

struct GestureLeaf: View {
    var body: some View {
        Text("Tap")
            .onTapGesture {}
            .accessibilityAddTraits(.isButton)
    }
}

struct PlatformCommandLeaf: View {
    var body: some View {
        Button("Send") {
            NSApp.sendAction(#selector(run), to: nil, from: nil)
        }
    }
}

struct NativeAdapter: NSViewRepresentable {
    let title: String
    func makeNSView(context: Context) -> NativeView { NativeView() }
    func updateNSView(_ nsView: NativeView, context: Context) {
        nsView.title = title
    }
}

#Preview {
    AppRoot(model: AppModel(), repository: SearchRepository())
}
