#!/bin/bash
set -euo pipefail
task_root="$(cd "$(dirname "$0")/.." && pwd)"
task_app="$task_root/build/Copy Path.app"
codesign --verify --strict "$task_app"
task_version=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$task_app/Contents/Info.plist")
task_name="Copy-Path-$task_version-macOS.zip"
ditto -c -k --sequesterRsrc --keepParent "$task_app" "$task_root/build/$task_name"
(cd "$task_root/build" && shasum -a 256 "$task_name" > "${task_name%.zip}.sha256")
printf 'Packaged: %s\n' "$task_root/build/$task_name"
