#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
task_check=$(mktemp -d "${TMPDIR:-/tmp}/bluuur-metal.XXXXXX")
trap 'rm -rf "$task_check"' EXIT
xcrun swiftc -module-cache-path "${BLUUUR_MODULE_CACHE:-$task_check/cache}" \
  Sources/MacDuo/DepthShaders.swift Sources/MacDuo/CenteredGaussianPyramid.swift \
  Checks/MetalSymmetry.swift -o "$task_check/check"
"$task_check/check"
