import SwiftUI
struct CallbackEffect: View {
    @Binding var enabled: Bool
    let notify: () -> Void
    var body: some View {
        Toggle("Enabled", isOn: Binding(
            get: { enabled },
            set: { next in enabled = next; notify() }
        ))
    }
}
