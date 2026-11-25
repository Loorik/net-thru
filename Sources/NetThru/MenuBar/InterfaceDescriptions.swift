import SystemConfiguration

/// Describes interfaces for the menu, e.g. "Wi-Fi (en0), Thunderbolt Ethernet (en5)".
enum InterfaceDescriptions {
    static func describe(_ bsdNames: [String]) -> String {
        guard !bsdNames.isEmpty else { return "No connection" }
        let displayNames = displayNamesByBSDName()
        return bsdNames.map { describe($0, displayName: displayNames[$0]) }.joined(separator: ", ")
    }

    private static func describe(_ bsdName: String, displayName: String?) -> String {
        guard let displayName else { return bsdName }
        return "\(displayName) (\(bsdName))"
    }

    /// "Wi-Fi", "Thunderbolt Ethernet", ... keyed by BSD name ("en0", ...).
    private static func displayNamesByBSDName() -> [String: String] {
        let interfaces = SCNetworkInterfaceCopyAll() as? [SCNetworkInterface] ?? []
        return Dictionary(interfaces.compactMap(bsdAndDisplayName), uniquingKeysWith: { _, latest in latest })
    }

    private static func bsdAndDisplayName(of interface: SCNetworkInterface) -> (String, String)? {
        guard let bsdName = SCNetworkInterfaceGetBSDName(interface) as String?,
              let displayName = SCNetworkInterfaceGetLocalizedDisplayName(interface) as String?
        else { return nil }
        return (bsdName, displayName)
    }
}
