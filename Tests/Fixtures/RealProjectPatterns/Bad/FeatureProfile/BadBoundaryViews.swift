import SwiftUI

struct BadAppRoot: View {
    @State private var applicationModel = BadApplicationModel()
    private let repository = BadSearchRepository()

    var body: some View {
        BadModelContainer(model: applicationModel, repository: repository)
    }
}

struct BadModelContainer: View {
    @Bindable var model: BadApplicationModel
    let repository: BadSearchRepository

    var body: some View {
        BadModelLeaf(model: model, repository: repository)
    }
}

struct BadModelLeaf: View {
    @Bindable var model: BadApplicationModel
    let repository: BadSearchRepository

    var body: some View {
        VStack {
            Text(model.title)
            Button("Load") { repository.load() }
        }
    }
}

struct BadCrossFeatureLeaf: View {
    @Bindable var library: BadLibraryModel

    var body: some View {
        Text("\(library.selection)")
    }
}

struct BadEnvironmentCommandLeaf: View {
    @Environment var router: BadCommandRouter

    var body: some View {
        Button("Send") { router.send() }
    }
}
