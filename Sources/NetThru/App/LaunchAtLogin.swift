import Foundation
import ServiceManagement

/// Registers net-thru as a login item. That needs the app bundle, so it's unavailable when the
/// bare binary runs (e.g. via `swift run`).
@MainActor
enum LaunchAtLogin {
    static var isAvailable: Bool {
        Bundle.main.bundleIdentifier != nil
    }

    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    static func toggle() throws {
        if isEnabled {
            try SMAppService.mainApp.unregister()
        } else {
            try enable()
        }
    }

    /// macOS may ask the user to approve the login item in System Settings first.
    private static func enable() throws {
        try SMAppService.mainApp.register()
        if SMAppService.mainApp.status == .requiresApproval {
            SMAppService.openSystemSettingsLoginItems()
        }
    }
}
