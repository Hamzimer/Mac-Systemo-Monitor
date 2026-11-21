import Foundation

enum AppLanguage: String, CaseIterable {
    case system, japanese = "ja", english = "en", traditionalChinese = "zh-Hant"

    static var selection: Self {
        Self(rawValue: UserDefaults.standard.string(forKey: "displayLanguage") ?? "system") ?? .system
    }

    static func resolved(_ selection: Self, preferred: [String] = Locale.preferredLanguages) -> Self {
        guard selection == .system else { return selection }
        let language = preferred.first?.lowercased() ?? "en"
        if language.hasPrefix("ja") { return .japanese }
        if language.hasPrefix("zh") { return .traditionalChinese }
        return .english
    }

    var name: String {
        switch self {
        case .system: return L("system")
        case .japanese: return "日本語"
        case .english: return "English"
        case .traditionalChinese: return "繁體中文"
        }
    }
}

// All app-owned interface text lives here; metric and style identifiers stay stable.
let interfaceStrings: [String: [String]] = [
    "system": ["システム設定に従う", "Follow System", "跟隨系統設定"],
    "language": ["表示言語", "Language", "顯示語言"],
    "view": ["表示", "View", "顯示"],
    "quitApp": ["HUD Systemo Monitorを終了", "Quit HUD Systemo Monitor", "結束 HUD Systemo Monitor"],
    "quit": ["終了", "Quit", "結束"],
    "show": ["モニターを表示", "Show Monitor", "顯示監測儀表"],
    "minimize": ["メニューバーへ最小化", "Minimize to Menu Bar", "縮小至選單列"],
    "details": ["詳細を表示", "Show Details", "顯示詳細資訊"],
    "detailsTitle": ["詳細", "Details", "詳細資訊"],
    "smaller": ["小さくする", "Make Smaller", "縮小"],
    "larger": ["大きくする", "Make Larger", "放大"],
    "floating": ["常に手前に表示", "Always on Top", "置於最上層"],
    "style": ["スタイル", "Style", "外觀風格"],
    "interactionHint": ["本体をドラッグして移動。MEM右下の斜線ハンドルでサイズ変更。右クリックで設定。", "Drag the body to move. Drag the striped handle at the lower-right of MEM to resize. Right-click for settings.", "拖曳儀表本體以移動。拖曳 MEM 右下方的斜線握柄以調整大小。按右鍵開啟設定。"],
    "renderer": ["描画", "Renderer", "算繪"],
    "tiler": ["タイル", "Tiler", "分塊處理"],
    "memory": ["メモリ", "Memory", "記憶體"],
    "compressed": ["圧縮", "Compressed", "已壓縮"],
    "wired": ["固定", "Wired", "固定記憶體"],
    "cached": ["キャッシュ", "Cached", "快取"],
    "swap": ["スワップ", "Swap", "交換空間"],
    "usage": ["使用率", "Usage", "使用率"],
    "cpuHelp": ["CPUコア別の現在の使用率", "Current usage of each logical CPU core", "各邏輯 CPU 核心目前的使用率"],
    "gpuHistory": ["GPU全体の直近16サンプル", "Last 16 samples of overall GPU usage", "GPU 整體使用率最近 16 筆資料"],
    "memoryHistory": ["メモリ使用率の直近16サンプル", "Last 16 samples of memory usage", "記憶體使用率最近 16 筆資料"],
    "gpuHelp": ["GPU全体の実測値。物理コア別の使用率は取得できません。", "Measured overall GPU usage. Physical per-core GPU utilization is unavailable.", "GPU 整體使用率實測值。無法取得各實體 GPU 核心使用率。"],
    "statusHelp": ["クリックして表示メニュー", "Click for the monitor menu", "按一下開啟儀表選單"]
]

func L(_ key: String, language: AppLanguage = .selection) -> String {
    guard let values = interfaceStrings[key] else { return key }
    let index: Int
    switch AppLanguage.resolved(language) {
    case .japanese: index = 0
    case .traditionalChinese: index = 2
    default: index = 1
    }
    return values[index]
}
