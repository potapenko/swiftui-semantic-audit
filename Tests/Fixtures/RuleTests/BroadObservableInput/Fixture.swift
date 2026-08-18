import SwiftUI

@Observable
final class BroadFeatureModel {
    var title = "Title"
}

struct BroadObservableLeaf: View {
    @Bindable var model: BroadFeatureModel

    var body: some View {
        Text(model.title)
    }
}
