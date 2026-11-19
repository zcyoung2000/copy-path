#!/bin/bash
set -euo pipefail
task_root="$(cd "$(dirname "$0")/.." && pwd)"
task_source="$task_root/build/Copy Path.app"
task_destination="${1:-/Applications/Copy Path.app}"
if [[ ! -d "$task_source" ]]; then
    bash "$task_root/scripts/build.sh"
fi
if [[ -e "$task_destination" ]]; then
    task_bundle_id=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$task_destination/Contents/Info.plist" 2>/dev/null || true)
    if [[ "$task_bundle_id" != 'com.henry.copypath' ]]; then
        printf 'Destination belongs to another app: %s\n' "$task_destination" >&2
        exit 1
    fi
    if pgrep -x CopyPath >/dev/null; then
        printf 'Close Copy Path before updating the installed app.\n' >&2
        exit 1
    fi
fi
mkdir -p "$(dirname "$task_destination")"
ditto "$task_source" "$task_destination"
swift "$task_root/scripts/register.swift" "$task_destination"
printf 'Installed: %s\n' "$task_destination"
