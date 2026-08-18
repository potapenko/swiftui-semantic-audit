import SwiftUI

@Observable
final class CommandPagerModel {
    var page = 0

    func selectPage(_ page: Int) {
        self.page = page
    }
}

struct CommandBindingPager: View {
    @Bindable var model: CommandPagerModel

    var body: some View {
        Picker(
            "Page",
            selection: Binding(
                get: { model.page },
                set: { model.selectPage($0) }
            )
        ) {
            Text("Zero").tag(0)
        }
    }
}
