import AppKit

MainActor.assumeIsolated {
    _ = NSApplication.shared
    let defaults = UserDefaults.standard
    let previous = defaults.object(forKey: "displayLanguage")
    defer {
        if let previous { defaults.set(previous, forKey: "displayLanguage") }
        else { defaults.removeObject(forKey: "displayLanguage") }
    }
    let owner = AppDelegate()
    for language in [AppLanguage.japanese, .english, .traditionalChinese, .system] {
        let menu = owner.makeWidgetMenu()
        let submenu = menu.items.compactMap(\.submenu).first { $0.items.contains { ($0.representedObject as? String) == "zh-Hant" } }!
        let choice = submenu.items.first { ($0.representedObject as? String) == language.rawValue }!
        precondition(NSApp.sendAction(choice.action!, to: choice.target, from: choice))
        precondition(AppLanguage.selection == language)
        let updated = owner.makeWidgetMenu()
        precondition(updated.items.first?.title == L("style"))
        precondition(NSApp.mainMenu?.items.last?.submenu?.title == L("view"))
        for (key, values) in interfaceStrings {
            precondition(values.count == 3 && values.allSatisfy { !$0.isEmpty })
            precondition(L(key, language: language) != key, "Untranslated key: \(key)")
        }
        if language == .english { precondition(L("details") == "Show Details") }
        if language == .traditionalChinese { precondition(L("details") == "顯示詳細資訊") }
    }
    precondition(AppLanguage.resolved(.system, preferred: ["ja-JP"]) == .japanese)
    precondition(AppLanguage.resolved(.system, preferred: ["zh-TW"]) == .traditionalChinese)
    precondition(AppLanguage.resolved(.system, preferred: ["en-US"]) == .english)
    precondition(AppLanguage.resolved(.system, preferred: ["fr-FR"]) == .english)
    print("Language menu actions, persistence, immediate native menu refresh, translation completeness and system fallback verified")
}
