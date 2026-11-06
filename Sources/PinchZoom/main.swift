import AppKit

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
// Dock icon plus menu-bar icon, so it is easy to see that it is running.
app.setActivationPolicy(.regular)
app.run()
