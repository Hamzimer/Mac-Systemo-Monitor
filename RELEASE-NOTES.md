# HUD Systemo Monitor 5.1.4

## English

- Fix widget dragging and mouse resizing: a dedicated AppKit input view now sits above SwiftUI. Drag any gauge body to move; drag the striped handle at the lower-right of MEM to resize.
- Add Japanese, English and Traditional Chinese UI. Right-click → Language, or View → Language. Switch immediately and remember the choice across launches; Follow System is available.
- Translate menus, detail labels, tooltips and accessibility hints.
- Add regression checks that deliver mouse events through NSWindow during metric updates, plus language-menu and persistence checks.

Quit the older app with ⌘Q, open **HUD-Systemo-Monitor.dmg**, replace the app in Applications and launch the replacement. Apple Silicon, macOS 14+. Ad-hoc signed; not Developer ID signed or notarized. Synthetic mouse-event checks pass; physical desktop mouse verification remains outstanding.

## 日本語

- 本体のドラッグ移動とマウスによるサイズ変更を修正。SwiftUIの上に専用のAppKit入力ビューを配置しました。本体をドラッグして移動、MEM右下の斜線ハンドルをドラッグしてサイズ変更できます。
- 日本語・英語・繁体中国語UIを追加。右クリック→「表示言語」、または「表示」→「表示言語」で選択。再起動なしで切り替え、次回起動にも保存します。システム言語への追従にも対応。
- メニュー、詳細表示、ヒント、アクセシビリティの案内を翻訳。
- 計測更新中にNSWindowへマウスイベントを送る移動・拡縮テストと、言語選択・保存の検証を追加。

旧版を⌘Qで終了し、**HUD-Systemo-Monitor.dmg**を開いてApplications内のアプリを置き換え、コピー先を起動してください。Apple Silicon・macOS 14以降。アドホック署名で、Developer ID署名・公証は未対応です。疑似マウスイベントの検証は通過していますが、物理マウスによるデスクトップ操作確認は未完了です。

## 繁體中文

- 修正拖曳移動與滑鼠調整大小：在 SwiftUI 上方配置獨立的 AppKit 輸入介面。拖曳儀表本體可移動，拖曳 MEM 右下方的斜線握柄可縮放。
- 新增日文、英文與繁體中文介面。按右鍵→「顯示語言」，或「顯示」→「顯示語言」。立即切換、記住設定，並支援跟隨系統語言。
- 翻譯選單、詳細資訊、提示及輔助使用說明。
- 新增資料更新期間透過 NSWindow 傳送滑鼠事件的移動與縮放測試，以及語言選取與設定保存檢查。

以 ⌘Q 結束舊版，開啟 **HUD-Systemo-Monitor.dmg**，取代 Applications 中的應用程式，再開啟新版本。需要 Apple Silicon 與 macOS 14 以上。採用臨時簽章，尚未取得 Developer ID 簽章或公證。模擬滑鼠事件檢查已通過，實體滑鼠桌面操作仍待手動驗證。
