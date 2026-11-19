#!/bin/bash
set -euo pipefail
task_root="$(cd "$(dirname "$0")/.." && pwd)"
task_app="$task_root/build/Copy Path.app"
mkdir -p "$task_app/Contents/MacOS" "$task_app/Contents/Resources"
for task_arch in arm64 x86_64; do
swiftc -O -target "$task_arch-apple-macosx13.0" \
    "$task_root/Sources/PathFormatter.swift" \
    "$task_root/Sources/Settings.swift" \
    "$task_root/Sources/SettingsView.swift" \
    "$task_root/Sources/main.swift" \
    -o "$task_root/build/CopyPath-$task_arch"
done
lipo -create "$task_root/build/CopyPath-arm64" "$task_root/build/CopyPath-x86_64" \
    -output "$task_app/Contents/MacOS/CopyPath"
swift "$task_root/scripts/prepare-info.swift" "$task_root/Resources/Info.plist" \
    "$task_root/Resources/file-extensions.txt" "$task_app/Contents/Info.plist"
swift "$task_root/scripts/make-icon.swift" "$task_root/build"
iconutil -c icns "$task_root/build/AppIcon.iconset" -o "$task_app/Contents/Resources/AppIcon.icns"
codesign --force --sign - "$task_app"
codesign --verify --strict "$task_app"
printf 'Built: %s\n' "$task_app"
