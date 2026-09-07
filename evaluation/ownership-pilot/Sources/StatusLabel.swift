import AppKit
import SwiftUI
struct StatusLabel: NSViewRepresentable {
    let caption: String
    func makeNSView(context: Context) -> NSTextField { NSTextField(labelWithString: caption) }
    func updateNSView(_ view: NSTextField, context: Context) { view.stringValue = caption }
}
