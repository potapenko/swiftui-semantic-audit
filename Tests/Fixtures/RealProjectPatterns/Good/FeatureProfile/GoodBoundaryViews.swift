import SwiftUI

struct GoodAppRoot: View {
    @State private var model = GoodApplicationModel()
    private let repository = GoodSearchRepository()

    var body: some View {
        GoodFocusedLeaf(
            title: model.title,
            reload: { repository.load() }
        )
    }
}

struct GoodFocusedLeaf: View {
    let title: String
    let reload: () -> Void

    var body: some View {
        VStack {
            Text(title)
            Button("Reload", action: reload)
        }
    }
}
