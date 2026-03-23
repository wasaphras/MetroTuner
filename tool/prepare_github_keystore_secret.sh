#!/usr/bin/env bash
# Encode a keystore for the ANDROID_KEYSTORE_BASE64 GitHub repository secret.
# Usage: ./tool/prepare_github_keystore_secret.sh path/to/upload-keystore.jks
# Copy the single line of output into GitHub → Settings → Secrets → New secret.
set -euo pipefail
if [[ $# -ne 1 ]]; then
  echo "Usage: $0 path/to/upload-keystore.jks" >&2
  exit 1
fi
if [[ ! -f "$1" ]]; then
  echo "Not a file: $1" >&2
  exit 1
fi
# One line, portable (macOS base64 has no -w0)
base64 <"$1" | tr -d '\n'
echo
