import AppKit

/// Turns trackpad pinches into whole-screen zoom by sending the built-in
/// Accessibility Zoom shortcuts (Cmd+Option+= / Cmd+Option+-).
///
/// Requires Accessibility permission and
/// System Settings → Accessibility → Zoom → "Use keyboard shortcuts to zoom".
final class PinchZoomEngine {
    var isEnabled = true

    /// How much pinch (summed magnification) equals one zoom step.
    /// Smaller = more sensitive. Override with PINCHZOOM_STEP.
    private let step: CGFloat = {
        if let raw = ProcessInfo.processInfo.environment["PINCHZOOM_STEP"],
           let value = Double(raw), value > 0 {
            return CGFloat(value)
        }
        return 0.08
    }()

    private var tap: CFMachPort?
    private var pending: CGFloat = 0

    /// NSEvent's global .magnify monitor never fires on current macOS, so we
    /// listen with a CGEvent tap for the raw gesture event types instead
    /// (29 = gesture, 30 = magnify) and let NSEvent decode them.
    func start() {
        let mask = CGEventMask(1 << 29) | CGEventMask(1 << 30)
        let callback: CGEventTapCallBack = { _, type, cgEvent, refcon in
            let engine = Unmanaged<PinchZoomEngine>.fromOpaque(refcon!).takeUnretainedValue()
            if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
                if let tap = engine.tap { CGEvent.tapEnable(tap: tap, enable: true) }
            } else if let event = NSEvent(cgEvent: cgEvent), event.type == .magnify {
                engine.handle(event)
            }
            return Unmanaged.passUnretained(cgEvent)
        }
        guard let tap = CGEvent.tapCreate(tap: .cgSessionEventTap,
                                          place: .headInsertEventTap,
                                          options: .listenOnly,
                                          eventsOfInterest: mask,
                                          callback: callback,
                                          userInfo: Unmanaged.passUnretained(self).toOpaque()) else {
            Log.write("event tap creation FAILED (Accessibility not granted?)")
            return
        }
        self.tap = tap
        let source = CFMachPortCreateRunLoopSource(nil, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        Log.write("event tap started")
    }

    private func handle(_ event: NSEvent) {
        guard isEnabled else { return }
        if event.phase == .began { pending = 0 }
        pending += event.magnification
        while abs(pending) >= step {
            let zoomIn = pending > 0
            sendZoomShortcut(zoomIn: zoomIn)
            pending -= zoomIn ? step : -step
        }
        if event.phase == .ended || event.phase == .cancelled { pending = 0 }
    }

    private func sendZoomShortcut(zoomIn: Bool) {
        let key: CGKeyCode = zoomIn ? 24 : 27 // "=" and "-" on the US layout
        for down in [true, false] {
            guard let e = CGEvent(keyboardEventSource: nil, virtualKey: key, keyDown: down) else { continue }
            e.flags = [.maskCommand, .maskAlternate]
            e.post(tap: .cghidEventTap)
        }
        Log.write("zoom \(zoomIn ? "in" : "out")")
    }
}
