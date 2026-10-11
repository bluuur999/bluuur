#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
# Run original assertions without Swift Testing's runtime (absent in some CLTs).
task_check=$(mktemp -d "${TMPDIR:-/tmp}/bluuur-check.XXXXXX")
trap 'rm -rf "$task_check"' EXIT
python3 Checks/portable.py "$task_check"
xcrun swiftc -swift-version 5 -module-cache-path "${BLUUUR_MODULE_CACHE:-$task_check/cache}" \
  Sources/MacDuo/LidEffectPolicy.swift Sources/MacDuo/SettingsLanguage.swift \
  Sources/MacDuo/MouseInteraction.swift Sources/MacDuo/CriticallyDampedSpring.swift \
  "$task_check"/*.swift -o "$task_check/check"
"$task_check/check"
