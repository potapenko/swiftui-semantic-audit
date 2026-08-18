import SwiftUI

@Observable
final class TunnelFeatureModel {
    var value = 0
}

struct TunnelModelLeaf: View {
    @Bindable var model: TunnelFeatureModel

    var body: some View {
        Text("Leaf")
    }
}

struct TunnelModelMiddle: View {
    @Bindable var model: TunnelFeatureModel

    var body: some View {
        TunnelModelLeaf(model: model)
    }
}

struct TunnelModelRoot: View {
    @State private var model = TunnelFeatureModel()

    var body: some View {
        TunnelModelMiddle(model: model)
    }
}
