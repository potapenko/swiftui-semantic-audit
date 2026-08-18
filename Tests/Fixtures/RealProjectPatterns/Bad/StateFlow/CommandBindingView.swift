import SwiftUI

struct BadCommandBindingView: View {
    @Bindable var model: BadApplicationModel
    @Bindable var profile: BadProfileModel

    var body: some View {
        Picker(
            "Page",
            selection: Binding(
                get: { model.selectedPage + profile.displayName.count },
                set: { newValue in
                    model.selectedPage = newValue
                    profile.displayName = String(newValue)
                    model.refresh()
                }
            )
        ) {
            Text("Zero").tag(0)
        }
    }
}
