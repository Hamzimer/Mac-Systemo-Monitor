import AppKit
import SwiftUI

final class WidgetWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

final class WidgetHostingView: NSHostingView<MonitorView> {
    var menuProvider: (() -> NSMenu)?
    private let resizeGrip = ResizeGripView(frame: .zero)

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if resizeGrip.superview == nil {
            resizeGrip.toolTip = "ここをドラッグしてサイズ変更"
            addSubview(resizeGrip)
        }
        needsLayout = true
    }

    override func layout() {
        super.layout()
        let y = bounds.height * (isFlipped ? 0.75 : 0.25)
        resizeGrip.frame = NSRect(x: bounds.width * 0.90 - 11, y: y - 11, width: 22, height: 22)
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        let local = convert(point, from: superview)
        if resizeGrip.superview != nil && resizeGrip.frame.contains(local) { return resizeGrip }
        return super.hitTest(point)
    }

    override func menu(for event: NSEvent) -> NSMenu? { menuProvider?() }

    override func rightMouseDown(with event: NSEvent) {
        guard let menu = menu(for: event) else { return }
        NSMenu.popUpContextMenu(menu, with: event, for: self)
    }

    override var isOpaque: Bool { false }
    override var mouseDownCanMoveWindow: Bool { true }

    override func scrollWheel(with event: NSEvent) {
        guard event.modifierFlags.contains(.option), let window else {
            super.scrollWheel(with: event)
            return
        }
        resizeWidget(window, by: exp(Double(event.scrollingDeltaY) * 0.015))
    }
}

final class ResizeGripView: NSView {
    override var mouseDownCanMoveWindow: Bool { false }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .crosshair)
    }

    override func draw(_ dirtyRect: NSRect) {
        let marks = NSBezierPath()
        for offset in stride(from: 0.0, through: 10.0, by: 5.0) {
            marks.move(to: NSPoint(x: 5 + offset, y: 2))
            marks.line(to: NSPoint(x: 20, y: 17 - offset))
        }
        NSColor.black.withAlphaComponent(0.5).setStroke()
        marks.lineWidth = 3
        marks.stroke()
        NSColor.white.withAlphaComponent(0.9).setStroke()
        marks.lineWidth = 1
        marks.stroke()
    }

    override func mouseDown(with event: NSEvent) {
        guard let window else { return }
        let original = window.frame
        let start = window.convertPoint(toScreen: event.locationInWindow)
        let area = window.screen?.visibleFrame ?? original
        NSCursor.crosshair.push()
        defer { NSCursor.pop() }
        while let next = NSApp.nextEvent(matching: [.leftMouseDragged, .leftMouseUp],
                                          until: .distantFuture, inMode: .eventTracking, dequeue: true) {
            let location = NSEvent.mouseLocation
            let change = resizeScale(from: start, to: location, size: original.size)
            window.setFrame(widgetFrame(original, factor: change, in: area), display: true)
            if next.type == .leftMouseUp { break }
        }
    }
}

func resizeScale(from start: NSPoint, to end: NSPoint, size: NSSize) -> Double {
    let horizontal = (end.x - start.x) / size.width
    let vertical = (start.y - end.y) / size.height
    return 1 + (abs(horizontal) >= abs(vertical) ? horizontal : vertical)
}

func widgetFrame(_ frame: NSRect, factor: Double, in area: NSRect) -> NSRect {
    let maximum = min(1680, area.width, area.height * 840 / 300)
    let width = min(maximum, max(420, frame.width * factor))
    let height = width * 300 / 840
    let x = min(max(frame.minX, area.minX), area.maxX - width)
    let y = min(max(frame.maxY - height, area.minY), area.maxY - height)
    return NSRect(x: x, y: y, width: width, height: height)
}

@MainActor
func resizeWidget(_ window: NSWindow, by factor: Double) {
    let area = window.screen?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1680, height: 1050)
    window.setFrame(widgetFrame(window.frame, factor: factor, in: area), display: true)
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate, NSMenuItemValidation {
    private let monitor = Monitor()
    private var window: NSWindow?
    private var detailsWindow: NSWindow?
    private var timer: Timer?
    private var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        MonitorStyle.migrateSelection()
        buildMenu()
        showHUD()
        monitor.refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                let animation: Animation? = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion ? nil : .easeOut(duration: 0.35)
                withAnimation(animation) { self.monitor.refresh() }
                self.updateStatus()
            }
        }
        if let timer { RunLoop.main.add(timer, forMode: .common) }
    }

    private func buildMenu() {
        let bar = NSMenu()
        let app = NSMenuItem()
        bar.addItem(app)
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "HUD Systemo Monitorを終了", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        app.submenu = appMenu
        let display = NSMenuItem()
        bar.addItem(display)
        let menu = NSMenu(title: "表示")
        for (title, selector, key) in [
            ("モニターを表示", #selector(showHUD), "1"),
            ("メニューバーへ最小化", #selector(minimizeHUD), "m"),
            ("詳細を表示", #selector(showDetails), "d"),
            ("小さくする", #selector(shrinkHUD), "-"),
            ("大きくする", #selector(enlargeHUD), "+"),
            ("常に手前に表示", #selector(toggleFloating(_:)), "f")
        ] {
            let item = menu.addItem(withTitle: title, action: selector, keyEquivalent: key)
            item.target = self
        }
        display.submenu = menu
        NSApp.mainMenu = bar
    }

    func makeWidgetMenu() -> NSMenu {
        let menu = NSMenu(title: "Mac System Monitor")
        let styles = NSMenu(title: "スタイル")
        let selected = UserDefaults.standard.string(forKey: "monitorStyle") ?? MonitorStyle.pureGlass.rawValue
        for style in MonitorStyle.allCases {
            let item = styles.addItem(withTitle: style.name, action: #selector(selectStyle(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = style.rawValue
            item.state = selected == style.rawValue ? .on : .off
        }
        let styleItem = menu.addItem(withTitle: "スタイル", action: nil, keyEquivalent: "")
        styleItem.submenu = styles
        menu.addItem(.separator())
        for (title, action) in [
            ("詳細を表示", #selector(showDetails)),
            ("小さくする", #selector(shrinkHUD)),
            ("大きくする", #selector(enlargeHUD)),
            ("常に手前に表示", #selector(toggleFloating(_:))),
            ("メニューバーへ最小化", #selector(minimizeHUD))
        ] {
            let item = menu.addItem(withTitle: title, action: action, keyEquivalent: "")
            item.target = self
        }
        menu.addItem(.separator())
        menu.addItem(withTitle: "終了", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "")
        return menu
    }

    @objc private func selectStyle(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String,
              let style = MonitorStyle(rawValue: raw) else { return }
        UserDefaults.standard.set(style.rawValue, forKey: "monitorStyle")
    }

    func validateMenuItem(_ item: NSMenuItem) -> Bool {
        if item.action == #selector(toggleFloating(_:)) {
            item.state = window?.level == .floating ? .on : .off
        }
        return true
    }

    @objc func showHUD() {
        if window == nil {
            let w = WidgetWindow(contentRect: NSRect(x: 0, y: 0, width: 840, height: 300),
                                 styleMask: [.borderless, .resizable], backing: .buffered, defer: false)
            w.title = "Mac System Monitor"
            w.isOpaque = false
            w.backgroundColor = .clear
            w.hasShadow = false
            w.isMovableByWindowBackground = true
            w.isReleasedWhenClosed = false
            w.contentMinSize = NSSize(width: 420, height: 150)
            w.contentAspectRatio = NSSize(width: 840, height: 300)
            let content = WidgetHostingView(rootView: MonitorView(monitor: monitor))
            content.menuProvider = { [weak self] in self?.makeWidgetMenu() ?? NSMenu() }
            content.sizingOptions = []
            w.contentView = content
            w.delegate = self
            w.center()
            w.setFrameAutosaveName("SystemoFloatingWidget")
            window = w
        }
        if window?.isMiniaturized == true { window?.deminiaturize(nil) }
        monitor.visible = true
        window?.makeKeyAndOrderFront(nil)
        removeStatus()
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func minimizeHUD() {
        window?.orderOut(nil)
        monitor.visible = false
        installStatus()
    }

    @objc private func shrinkHUD() {
        if let window { resizeWidget(window, by: 0.85) }
    }

    @objc private func enlargeHUD() {
        if let window { resizeWidget(window, by: 1.15) }
    }

    @objc private func showDetails() {
        if detailsWindow == nil {
            let content = MonitorDetails(monitor: monitor).padding(20).frame(minWidth: 600)
            let details = NSWindow(contentViewController: NSHostingController(rootView: content))
            details.title = "Mac System Monitor — 詳細"
            details.isReleasedWhenClosed = false
            details.delegate = self
            details.center()
            detailsWindow = details
        }
        detailsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func windowWillClose(_ notification: Notification) {
        if notification.object as? NSWindow === detailsWindow { detailsWindow = nil }
    }

    func windowDidMiniaturize(_ notification: Notification) {
        monitor.visible = false
        installStatus()
    }

    func windowDidDeminiaturize(_ notification: Notification) {
        monitor.visible = true
        removeStatus()
    }

    func applicationDidHide(_ notification: Notification) { monitor.visible = false }
    func applicationDidUnhide(_ notification: Notification) {
        monitor.visible = window?.isVisible == true
    }
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        if sender === window {
            sender.orderOut(nil)
            monitor.visible = false
            installStatus()
            return false
        }
        return true
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showHUD()
        return true
    }

    private func installStatus() {
        guard statusItem == nil else { return }
        let item = NSStatusBar.system.statusItem(withLength: 270)
        let menu = NSMenu()
        let restore = menu.addItem(withTitle: "モニターを表示", action: #selector(showHUD), keyEquivalent: "")
        restore.target = self
        menu.addItem(.separator())
        menu.addItem(withTitle: "終了", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        item.menu = menu
        statusItem = item
        updateStatus()
    }

    private func removeStatus() {
        if let statusItem { NSStatusBar.system.removeStatusItem(statusItem) }
        statusItem = nil
    }

    private func updateStatus() {
        guard let button = statusItem?.button else { return }
        let data = monitor.data
        let image = makeStatusImage(data: data, history: monitor.history)
        image.isTemplate = false
        button.image = image
        button.toolTip = "CPU \(percent(data.cpu)) · GPU \(percent(data.gpu)) · メモリ \(percent(data.ram)) — クリックして表示メニュー"
        button.setAccessibilityLabel(button.toolTip)
    }

    @objc private func toggleFloating(_ sender: NSMenuItem) {
        let floating = window?.level != .floating
        window?.level = floating ? .floating : .normal
        sender.state = floating ? .on : .off
    }

    func applicationWillTerminate(_ notification: Notification) { timer?.invalidate() }
}

@MainActor
func runMonitorApp() {
    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.setActivationPolicy(.regular)
    app.delegate = delegate
    withExtendedLifetime(delegate) { app.run() }
}

@MainActor
func makeStatusImage(data: Readings, history: [[Double?]]) -> NSImage {
    let image = NSImage(size: NSSize(width: 270, height: 20), flipped: true) { _ in
        for (index, metric) in Metric.primary.enumerated() {
            let origin = CGFloat(index) * 90
            let text = "\(metric.title) \(percent(metric.value(in: data)))"
            let attributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.monospacedDigitSystemFont(ofSize: 10, weight: .medium),
                .foregroundColor: NSColor.labelColor
            ]
            (text as NSString).draw(at: NSPoint(x: origin + 1, y: 3), withAttributes: attributes)
            let samples = Array(history[metric.rawValue].suffix(20))
            let line = NSBezierPath()
            var drawing = false
            for (sample, value) in samples.enumerated() {
                guard let value else { drawing = false; continue }
                let point = NSPoint(x: origin + 62 + CGFloat(sample) * 26 / 19,
                                    y: 18 - value / 100 * 16)
                if drawing {
                    line.line(to: point)
                } else {
                    line.move(to: point)
                    drawing = true
                }
            }
            NSColor(metric.color).setStroke()
            line.lineWidth = 1.3
            line.stroke()
        }
        return true
    }
    image.isTemplate = false
    return image
}
