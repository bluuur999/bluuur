#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
task_check=$(mktemp -d "${TMPDIR:-/tmp}/bluuur-stream.XXXXXX")
trap 'rm -rf "$task_check"' EXIT
xcrun swiftc -swift-version 5 -module-cache-path "${BLUUUR_MODULE_CACHE:-$task_check/cache}" \
  Sources/MacDuo/ScreenStreamer.swift Sources/MacDuo/ScreenSnapshotter.swift \
  Sources/MacDuo/CapturedFrame.swift Sources/MacDuo/Diagnostics.swift \
  Checks/StreamRecovery.swift -o "$task_check/check"
"$task_check/check"
