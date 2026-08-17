import SwiftUI

struct TemperatureEditor: View {
    @State private var primary = 0.0
    @State private var converted = 32.0

    var body: some View {
        VStack {
            Slider(value: $primary)
            Slider(value: $converted)
        }
        .onChange(of: primary) { _, _ in
            converted = primary * 9 / 5 + 32
        }
        .onChange(of: converted) { _, _ in
            primary = (converted - 32) * 5 / 9
        }
    }
}
