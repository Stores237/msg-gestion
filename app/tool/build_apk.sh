#!/usr/bin/env bash
# Builds the release APK pointed at a server, and refuses to finish if the
# address isn't inside it (builds 27 and 28 shipped pointing at the
# emulator's 10.0.2.2: "can't connect" on every phone, 2026-10-30).
# Usage: tool/build_apk.sh [API base URL]   (default: staging)
set -euo pipefail
cd "$(dirname "$0")/.."
URL="${1:-https://msg-staging.onrender.com/api}"
FLUTTER="${FLUTTER:-flutter}"
"$FLUTTER" build apk --release --dart-define=API_BASE_URL="$URL"
APK=build/app/outputs/flutter-apk/app-release.apk
found=$(unzip -p "$APK" lib/arm64-v8a/libapp.so | strings | grep -cF "$URL" || true)
if [ "${found:-0}" -eq 0 ]; then
  echo "ERROR: $URL is not in the APK; do not publish it." >&2
  exit 1
fi
echo "OK: $APK talks to $URL"
