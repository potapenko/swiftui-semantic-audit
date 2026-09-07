import SwiftUI
struct LiveRename: View {
    @Binding var title: String
    var body: some View { TextField("Title", text: $title) }
}
