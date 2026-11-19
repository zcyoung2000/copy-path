#!/bin/bash
set -euo pipefail
task_root="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$task_root/build"
swiftc "$task_root/Sources/PathFormatter.swift" "$task_root/Tests/main.swift" -o "$task_root/build/PathFormatterTests"
"$task_root/build/PathFormatterTests"
