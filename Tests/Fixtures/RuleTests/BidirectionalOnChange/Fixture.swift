import SwiftUI

struct BidirectionalEditor: View {
    var externalValue: String
    @State private var localValue = ""

    var body: some View {
        TextField("Value", text: $localValue)
            .onChange(of: externalValue) { _, newValue in
                localValue = externalValue
            }
            .onChange(of: localValue) { _, newValue in
                externalValue = localValue
            }
    }
}
