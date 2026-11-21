import AppKit

func near(_ a: CGFloat, _ b: CGFloat) -> Bool { abs(a - b) < 1 }

MainActor.assumeIsolated {
    _ = NSApplication.shared
    let w = WidgetWindow(contentRect: NSRect(x: 150, y: 200, width: 840, height: 300),
                         styleMask: [.borderless], backing: .buffered, defer: false)
    w.isReleasedWhenClosed = false
    w.isMovableByWindowBackground = false
    let monitor = Monitor()
    let host = WidgetHostingView(rootView: MonitorView(monitor: monitor))
    w.contentView = host
    w.makeKeyAndOrderFront(nil)
    defer { w.orderOut(nil) }
    w.contentView?.layoutSubtreeIfNeeded()
    let original = w.frame
    let overlay = host.interaction
    precondition(overlay.frame.size == original.size)
    precondition(host.subviews.last === overlay)
    precondition(overlay.acceptsFirstMouse(for: nil))

    @MainActor func send(_ type: NSEvent.EventType, screen: NSPoint) {
        let event = NSEvent.mouseEvent(with: type, location: w.convertPoint(fromScreen: screen),
            modifierFlags: [], timestamp: ProcessInfo.processInfo.systemUptime,
            windowNumber: w.windowNumber, context: nil, eventNumber: 0, clickCount: 1, pressure: 1)!
        w.sendEvent(event)
    }
    @MainActor func drag(from start: NSPoint, to end: NSPoint) {
        send(.leftMouseDown, screen: start)
        // Live SwiftUI updates must not replace or consume the input target.
        monitor.refresh()
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))
        send(.leftMouseDragged, screen: end)
        send(.leftMouseUp, screen: end)
    }
    for point in [NSPoint(x: 140, y: 150), NSPoint(x: 420, y: 150), NSPoint(x: 700, y: 150)] {
        w.setFrame(original, display: true)
        let start = w.convertPoint(toScreen: point)
        drag(from: start, to: NSPoint(x: start.x + 50, y: start.y + 30))
        precondition(near(w.frame.minX, original.minX + 50), "Window body did not move through NSWindow.sendEvent")
        precondition(near(w.frame.minY, original.minY + 30))
        precondition(w.frame.size == original.size)
    }
    w.setFrame(original, display: true)
    w.contentView?.layoutSubtreeIfNeeded()
    let gripStart = w.convertPoint(toScreen: NSPoint(x: overlay.gripRect.midX, y: overlay.gripRect.midY))
    drag(from: gripStart, to: NSPoint(x: gripStart.x + 84, y: gripStart.y - 30))
    precondition(near(w.frame.width, original.width * 1.1), "Grip did not resize through NSWindow.sendEvent")
    precondition(near(w.frame.maxY, original.maxY))
    precondition(near(w.frame.minX, original.minX))
    w.contentView?.layoutSubtreeIfNeeded()
    precondition(near(overlay.frame.width, w.frame.width))
    let grown = w.frame
    let nextStart = w.convertPoint(toScreen: NSPoint(x: overlay.gripRect.midX, y: overlay.gripRect.midY))
    drag(from: nextStart, to: NSPoint(x: nextStart.x - 100, y: nextStart.y + 10))
    precondition(w.frame.width < grown.width, "Grip failed after a previous resize")
    precondition(near(w.frame.width / w.frame.height, 2.8))
    let final = w.frame
    send(.leftMouseDragged, screen: NSPoint(x: nextStart.x + 200, y: nextStart.y))
    precondition(w.frame == final, "Mouse-up did not end drag")
    print("NSWindow event delivery: CPU/GPU/MEM body movement, grip grow/shrink after layout, live refresh, mouse-up verified")
}
