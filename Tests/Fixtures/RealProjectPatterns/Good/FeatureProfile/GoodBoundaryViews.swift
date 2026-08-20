import SwiftUI
import Observation

@Observable
final class GoodItemModel: Identifiable {
    let id: Int
    var title: String

    init(id: Int, title: String) {
        self.id = id
        self.title = title
    }
}

struct GoodAppRoot: View {
    @State private var model = GoodApplicationModel()
    @State private var items = [
        GoodItemModel(id: 1, title: "First"),
        GoodItemModel(id: 2, title: "Second"),
    ]
    private let repository = GoodSearchRepository()

    var body: some View {
        VStack {
            GoodFocusedLeaf(
                title: model.title,
                reload: { repository.load() }
            )
            ForEach(items) { item in
                GoodItemRow(model: item)
            }
        }
    }
}

struct GoodItemRow: View {
    let model: GoodItemModel

    var body: some View {
        Text(model.title)
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
