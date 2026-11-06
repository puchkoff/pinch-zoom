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
        let aboutItem = NSMenuItem(title: "About PinchZoom",
                                   action: #selector(showAbout),
                                   keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)
        menu.addItem(NSMenuItem(title: "Quit PinchZoom",
                                 action: #selector(NSApplication.terminate(_:)),
                                 keyEquivalent: "q"))
        statusItem.menu = menu
    }

    @objc private func showAbout() {
        let credits = NSMutableAttributedString(string: """
            Pinch on the trackpad to zoom the whole screen, in any app.

            Hold Shift while pinching to zoom only inside the app \
            (Safari, Preview, Maps), without zooming the screen.

            Needs Accessibility permission, and "Use keyboard shortcuts \
            to zoom" in System Settings → Accessibility → Zoom.

            github.com/puchkoff/pinch-zoom
            """, attributes: [.font: NSFont.systemFont(ofSize: 14)])
        let link = (credits.string as NSString).range(of: "github.com/puchkoff/pinch-zoom")
        credits.addAttribute(.link, value: "https://github.com/puchkoff/pinch-zoom", range: link)
        NSApp.activate(ignoringOtherApps: true)
        NSApp.orderFrontStandardAboutPanel(options: [.credits: credits])
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
