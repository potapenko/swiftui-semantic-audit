import SwiftUI

final class BindingFactoryModel {
    var value = 0

    func valueBinding() -> Binding<Int> {
        Binding(
            get: { self.value },
            set: { next in self.value = next }
        )
    }
}
