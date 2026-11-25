import Foundation

/// New menu bar items start out furthest left, the first place macOS hides items when the bar
/// is crowded. Until the user ⌘-drags net-thru elsewhere (which macOS then remembers), it sits
/// right next to the system items instead.
enum MenuBarPosition {
    /// Distance from the right edge of the screen, in points; macOS orders the items by it.
    private static let nextToSystemItems = 290

    static func preferNextToSystemItems(autosaveName: String) {
        let key = "NSStatusItem Preferred Position \(autosaveName)"
        UserDefaults.standard.register(defaults: [key: nextToSystemItems])
    }
}
