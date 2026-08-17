import SwiftUI

@Observable
final class AppModel {
    var query = ""
    var volume = 0.5
    var mode = 0

    func reload() {}
}

struct Controls: View {
    @State private var query = ""
    @Binding var isEnabled: Bool
    @Bindable var model: AppModel
    @Environment(AppModel.self) private var environmentModel
    let onCommit: (Bool) -> Void

    var body: some View {
        VStack {
            TextField("Query", text: $query)
            Toggle("Enabled", isOn: $isEnabled)
            Slider(value: $model.volume)
            Picker("Mode", selection: $model.mode) {
                Text("One").tag(1)
            }
        }
        .onChange(of: query) { _, newValue in
            model.query = newValue
            onCommit(isEnabled)
        }
        .onAppear {
            environmentModel.query = query
        }
        .task(id: query) {
            model.reload()
        }
    }
}

struct Parent: View {
    @State private var enabled = false
    @State private var model = AppModel()

    var body: some View {
        Controls(isEnabled: $enabled, model: model) { value in
            enabled = value
        }
    }
}
