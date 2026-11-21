#!/bin/bash
set -euo pipefail
source_dir="$(cd "$(dirname "$0")" && pwd)"
destination="${1:-$source_dir}"
app="$destination/HUD Systemo Monitor.app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp "$source_dir/Info.plist" "$app/Contents/"
cp "$source_dir/Resources/AppIcon.icns" "$app/Contents/Resources/"
xcrun swiftc -O -target arm64-apple-macos14.0 -module-cache-path "${TMPDIR:-/tmp}/hud-systemo-swift-cache" \
  "$source_dir/Localization.swift" "$source_dir/main.swift" "$source_dir/Metrics.swift" "$source_dir/Monitor.swift" \
  "$source_dir/Panel.swift" "$source_dir/App.swift" -o "$app/Contents/MacOS/HUDSystemoMonitor"
codesign --force --sign - "$app"
