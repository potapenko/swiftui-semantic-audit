import AuditCore

public enum SwiftUIVocabulary {
    public static let controls: Set<String> = ["TextField", "Toggle", "Slider", "Picker"]
    public static let containers: Set<String> = ["VStack"]
    public static let actions: Set<String> = ["Button"]
    public static let modifiers: Set<String> = ["onChange", "onAppear", "task"]

    public static func nodeKind(forPropertyWrapper wrapper: String?, isCallback: Bool) -> NodeKind {
        switch wrapper {
        case "State": .state
        case "Binding": .binding
        case "Bindable": .observableState
        case "Environment": .input
        default: isCallback ? .callback : .property
        }
    }

    public static func ownershipEdge(forPropertyWrapper wrapper: String?) -> EdgeKind {
        switch wrapper {
        case "Binding": .binds
        case "Bindable": .observes
        case "Environment": .injects
        default: .owns
        }
    }
}
