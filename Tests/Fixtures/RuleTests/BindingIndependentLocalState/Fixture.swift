import SwiftUI

struct BindingWithIndependentState: View {
    @Binding var profileName: String
    @State private var isExpanded = false

    var body: some View {
        VStack {
            TextField("Name", text: $profileName)
            Toggle("Expanded", isOn: $isExpanded)
        }
    }
}
