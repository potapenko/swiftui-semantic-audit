import AppKit
import SwiftUI

final class BadNativeView: NSView {
    var title = ""
}

final class BadCommandTarget: NSObject {
    @objc func run() {}
}

struct BadNativeAdapter: NSViewRepresentable {
    let title: String

    func makeNSView(context: Context) -> BadNativeView { BadNativeView() }

    func updateNSView(_ nsView: BadNativeView, context: Context) {
        nsView.title = title
    }
}

struct BadPlatformCommandLeaf: View {
    var body: some View {
        Button("Send") {
            NSApp.sendAction(#selector(BadCommandTarget.run), to: nil, from: nil)
        }
    }
}

#Preview {
    BadAppRoot()
}
