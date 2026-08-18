import Observation

@Observable
final class BadApplicationModel {
    var title = "Title"
    var selectedPage = 0

    func refresh() {}
    func load(width: Double) {}
    func selectPage(_ page: Int) { selectedPage = page }
}

@Observable
final class BadProfileModel {
    var displayName = "Name"
}

@Observable
final class BadLibraryModel {
    var selection = 0
}

final class BadSearchRepository {
    func load() {}
}

final class BadCommandRouter {
    func send() {}
}
