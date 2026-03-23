#!/usr/bin/env bash
# After `flutter test --coverage`, checks line coverage on core pitch + scheduler
# Dart (excludes tuner_audio_controller.dart). Requires bc or awk for percentage.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
INFO="$ROOT/coverage/lcov.info"
if [[ ! -f "$INFO" ]]; then
  echo "Run: flutter test --coverage" >&2
  exit 1
fi

TARGETS=(
  "lib/core/pitch/note_math.dart"
  "lib/core/pitch/pitch_yin.dart"
  "lib/core/pitch/pitch_detector.dart"
  "lib/core/pitch/pitch_types.dart"
  "lib/core/metronome/metronome_scheduler.dart"
)

total_lf=0
total_lh=0
for rel in "${TARGETS[@]}"; do
  # Sum LF/LH for this SF block (first match only)
  block=$(awk -v sf="$rel" '
    $0 ~ /^SF:/ { cur = substr($0, 4); inblock = (cur == sf) }
    inblock && /^LF:/ { lf = substr($0, 4) }
    inblock && /^LH:/ { lh = substr($0, 4); print lf, lh; exit }
  ' "$INFO")
  if [[ -z "$block" ]]; then
    echo "Missing coverage block for $rel" >&2
    exit 1
  fi
  read -r lf lh <<<"$block"
  total_lf=$((total_lf + lf))
  total_lh=$((total_lh + lh))
done

pct=$((100 * total_lh / total_lf))
echo "Core logic line coverage: $total_lh / $total_lf ($pct%)"
if (( total_lh * 100 < 80 * total_lf )); then
  echo "FAIL: expected >= 80% on core logic (see CONTRIBUTING.md)" >&2
  exit 1
fi
