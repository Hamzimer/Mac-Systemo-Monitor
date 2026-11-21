#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
repo="Hamzimer/Mac-Systemo-Monitor"
(cd release-assets && shasum -a 256 -c SHA256SUMS.txt)
if gh release view v5.1.3 --repo "$repo" >/dev/null 2>&1; then
  echo "Release already exists; assets were left unchanged."
  exit 0
fi
gh release create v5.1.3 release-assets/HUD-Systemo-Monitor.dmg release-assets/SHA256SUMS.txt --repo "$repo" --target "$(git rev-parse HEAD)" --latest --title "HUD Systemo Monitor 5.1.3 · 12 styles for your Mac" --notes-file RELEASE-NOTES.md
