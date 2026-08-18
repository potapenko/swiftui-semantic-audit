import SwiftUI

struct FocusedActionLeaf: View {
    let value: String
    let submit: (String) -> Void

    var body: some View {
        Button("Submit") {
            submit(value)
        }
    }
}
