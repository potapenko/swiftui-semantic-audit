import SwiftUI

@Observable
final class PlayerModel {
    var volume = 0.0
}

struct ObservableEditor: View {
    @Environment(PlayerModel.self) private var model
    @State private var localVolume = 0.0

    var body: some View {
        Slider(value: $localVolume)
            .onAppear {
                localVolume = model.volume
            }
            .onChange(of: localVolume) { _, _ in
                model.volume = localVolume
            }
    }
}
