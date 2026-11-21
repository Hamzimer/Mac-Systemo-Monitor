#!/bin/bash
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
checks_dir="$(mktemp -d "${TMPDIR:-/tmp}/hud-checks.XXXXXX")"
trap 'rm -rf "$checks_dir"' EXIT
for name in menu resize interaction localization; do
  xcrun swiftc -target arm64-apple-macos14.0 -module-cache-path "${TMPDIR:-/tmp}/hud-systemo-swift-cache" \
    "$root/Localization.swift" "$root/Metrics.swift" "$root/Monitor.swift" "$root/Panel.swift" "$root/App.swift" \
    "$root/tests/$name/main.swift" -o "$checks_dir/$name"
  "$checks_dir/$name"
done
