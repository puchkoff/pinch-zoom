import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var enabledItem: NSMenuItem!
    private let engine = PinchZoomEngine()

    func applicationDidFinishLaunching(_ notification: Notification) {
        setUpStatusItem()
        requestAccessibilityIfNeeded()
        engine.start()
    }

    private func setUpStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            let image = NSImage(systemSymbolName: "plus.magnifyingglass", accessibilityDescription: "PinchZoom")
            image?.isTemplate = true
            button.image = image
        }

        let menu = NSMenu()
        enabledItem = NSMenuItem(title: "Pinch to Zoom",
                                  action: #selector(toggleEnabled),
                                  keyEquivalent: "")
        enabledItem.target = self
        enabledItem.state = .on
        menu.addItem(enabledItem)
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit PinchZoom",
                                 action: #selector(NSApplication.terminate(_:)),
                                 keyEquivalent: "q"))
        statusItem.menu = menu
    }

    @objc private func toggleEnabled() {
        engine.isEnabled.toggle()
        enabledItem.state = engine.isEnabled ? .on : .off
    }

    /// The event tap and the synthetic key presses both need Accessibility
    /// permission, so prompt for it on first launch.
    private func requestAccessibilityIfNeeded() {
        guard !AXIsProcessTrusted() else { return }
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
}
