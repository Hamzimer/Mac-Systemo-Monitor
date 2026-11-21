import AppKit

func near(_ a: CGFloat, _ b: CGFloat) -> Bool { abs(a - b) < 0.001 }

MainActor.assumeIsolated {
    let area = NSRect(x: 0, y: 0, width: 1920, height: 1080)
    let original = NSRect(x: 200, y: 300, width: 840, height: 300)
    let start = NSPoint(x: 500, y: 500)
    for (end, expected) in [
        (NSPoint(x: 668, y: 500), 1.2),
        (NSPoint(x: 500, y: 440), 1.2),
        (NSPoint(x: 332, y: 500), 0.8),
        (NSPoint(x: 500, y: 560), 0.8),
        (start, 1.0)
    ] {
        let scale = resizeScale(from: start, to: end, size: original.size)
        precondition(near(scale, expected))
        let resized = widgetFrame(original, factor: scale, in: area)
        precondition(near(resized.width / resized.height, 2.8))
        precondition(near(resized.minX, original.minX))
        precondition(near(resized.maxY, original.maxY))
    }
    let minimum = widgetFrame(original, factor: -20, in: area)
    precondition(minimum.size == NSSize(width: 420, height: 150))
    let maximum = widgetFrame(original, factor: 50, in: area)
    precondition(near(maximum.width, 1680))
    precondition(area.contains(maximum))
    let external = NSRect(x: -1600, y: -900, width: 1600, height: 900)
    precondition(external.contains(widgetFrame(original, factor: 20, in: external)))
    let shortScreen = NSRect(x: 0, y: 0, width: 1280, height: 480)
    precondition(shortScreen.contains(widgetFrame(original, factor: 20, in: shortScreen)))

    let host = WidgetHostingView(rootView: MonitorView(monitor: Monitor()))
    host.frame = NSRect(x: 0, y: 0, width: 840, height: 300)
    let grip = host.interaction
    let point = NSPoint(x: grip.gripRect.midX, y: grip.gripRect.midY)
    precondition(host.hitTest(point) === grip)
    precondition(host.hitTest(NSPoint(x: 400, y: 150)) === grip)
    precondition(!grip.mouseDownCanMoveWindow)
    print("Input overlay hit-testing, drag growth/shrinkage, fixed anchor, aspect ratio and screen bounds verified")
}
