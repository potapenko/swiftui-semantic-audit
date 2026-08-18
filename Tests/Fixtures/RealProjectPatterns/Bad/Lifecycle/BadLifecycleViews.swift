import SwiftUI

struct BadLifecycleLeaf: View {
    @Bindable var model: BadApplicationModel
    @State private var localTitle = ""

    var body: some View {
        Text(localTitle)
            .onAppear {
                localTitle = model.title
            }
            .onChange(of: model.title) { _, newValue in
                localTitle = newValue
            }
            .task {
                model.refresh()
            }
    }
}

struct BadFocusSelectionLeaf: View {
    @FocusState private var focused: Bool
    @State private var primarySelection: TextSelection
    @State private var restoredSelection: TextSelection

    var body: some View {
        TextField("Name", text: .constant(""))
            .task { focused = true }
            .onChange(of: primarySelection) { _, value in
                restoredSelection = value
            }
            .onChange(of: restoredSelection) { _, value in
                primarySelection = value
            }
    }
}
