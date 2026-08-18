import SwiftUI

struct BadMeasuredChild: View {
    let width: Double

    var body: some View { Text("\(width)") }
}

struct BadGeometryLeaf: View {
    @Bindable var model: BadApplicationModel

    var body: some View {
        GeometryReader { proxy in
            BadMeasuredChild(width: proxy.size.width)
                .offset(x: proxy.size.width)
                .coordinateSpace(name: proxy.size.height)
                .onAppear {
                    model.load(width: proxy.size.width)
                }
        }
    }
}

struct BadGestureLeaf: View {
    var body: some View {
        Text("Tap")
            .onTapGesture {}
            .accessibilityAddTraits(.isButton)
    }
}
