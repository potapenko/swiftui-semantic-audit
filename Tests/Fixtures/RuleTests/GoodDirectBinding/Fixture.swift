import SwiftUI

struct DirectBindingField: View {
    @Binding var name: String

    var body: some View {
        TextField("Name", text: $name)
    }
}
