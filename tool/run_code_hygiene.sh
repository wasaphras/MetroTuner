#!/usr/bin/env bash
# Local sweep: pub get, dart fix preview, analyze, tests, optional core coverage check.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

flutter pub get
dart fix --dry-run
flutter analyze
flutter test

INFO="$ROOT/coverage/lcov.info"
if [[ -f "$INFO" ]]; then
  bash "$ROOT/tool/verify_core_coverage.sh"
else
  echo "Skipping core coverage gate (no $INFO — run: flutter test --coverage)"
fi
