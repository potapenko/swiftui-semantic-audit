import SwiftUI

@Observable
final class LocalFeatureModel {
    var title = "Title"
}

struct LocalModelOwnerView: View {
    @State private var model = LocalFeatureModel()

    var body: some View {
        Text(model.title)
    }
}
