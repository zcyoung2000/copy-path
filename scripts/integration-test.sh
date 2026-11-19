#!/bin/bash
set -euo pipefail
task_root="$(cd "$(dirname "$0")/.." && pwd)"
task_app="${1:-$task_root/build/Copy Path.app}"
task_receiver="$task_root/build/Test Receiver.app"
swift "$task_root/scripts/register.swift" "$task_app"
mkdir -p "$task_receiver/Contents/MacOS" "$task_root/build/Fixtures"
swiftc -O "$task_root/Tests/Receiver.swift" -o "$task_receiver/Contents/MacOS/TestReceiver"
TASK_ROOT="$task_root" python3 - <<'PY'
import os, plistlib
from pathlib import Path
root = Path(os.environ['TASK_ROOT'])
info = {
    'CFBundleIdentifier': 'com.henry.copypath.testreceiver',
    'CFBundleName': 'Copy Path Test Receiver',
    'CFBundleExecutable': 'TestReceiver',
    'CFBundlePackageType': 'APPL',
    'LSUIElement': True,
    'CopyPathTestOutput': str(root / 'build/Fixtures/forwarded.json'),
    'CFBundleDocumentTypes': [{'CFBundleTypeName': 'Test Files',
                             'CFBundleTypeRole': 'Viewer',
                             'LSHandlerRank': 'None',
                             'LSItemContentTypes': ['public.item']}],
}
with (root / 'build/Test Receiver.app/Contents/Info.plist').open('wb') as stream:
    plistlib.dump(info, stream)
PY
codesign --force --sign - "$task_receiver"
cp "$task_root/Tests/Integration.swift" "$task_root/build/main.swift"
swiftc "$task_root/Sources/PathFormatter.swift" "$task_root/build/main.swift" -o "$task_root/build/IntegrationTests"
"$task_root/build/IntegrationTests" "$task_app" "$task_root/build/Fixtures" "$task_receiver"
