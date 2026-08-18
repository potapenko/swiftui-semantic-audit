import Observation

@Observable
final class GoodApplicationModel {
    var title = "Title"
}

@Observable
final class GoodProfileModel {
    var displayName = "Name"
}

final class GoodSearchRepository {
    func load() {}
}
