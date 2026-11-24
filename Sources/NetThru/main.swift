import AppKit

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
// No Dock icon or app menu. The bundle's Info.plist says the same (LSUIElement); this also
// covers running the bare binary.
app.setActivationPolicy(.accessory)
app.run()
