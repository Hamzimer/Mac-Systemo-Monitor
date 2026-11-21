import AppKit
import SwiftUI

MainActor.assumeIsolated {
    let owner = AppDelegate()
    let menu = owner.makeWidgetMenu()
    guard let styles = menu.items.first?.submenu else { fatalError("Style menu missing") }
    precondition(styles.items.count == 12)
    precondition(styles.items.map(\.title) == MonitorStyle.allCases.map(\.name))
    precondition(styles.items.compactMap { $0.representedObject as? String } == MonitorStyle.allCases.map(\.rawValue))
    precondition(styles.items.allSatisfy { $0.target as? AppDelegate === owner && $0.action != nil })
    let identities = styles.items.map(ObjectIdentifier.init)
    let monitor = Monitor()
    var updates = 0
    let timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
        MainActor.assumeIsolated {
            monitor.refresh()
            updates += 1
        }
    }
    RunLoop.main.run(until: Date().addingTimeInterval(2.5))
    timer.invalidate()
    precondition(updates >= 20)
    precondition(identities == styles.items.map(ObjectIdentifier.init))
    precondition(styles.items.count == 12)
    print("Native menu retained 12 identical items across \(updates) live updates")
    print("Style names, selection actions and saved identifiers verified")
}
