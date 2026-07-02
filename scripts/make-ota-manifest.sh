#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IPA_URL="${IPA_URL:-}"
DISPLAY_IMAGE_URL="${DISPLAY_IMAGE_URL:-}"
FULL_SIZE_IMAGE_URL="${FULL_SIZE_IMAGE_URL:-}"
OUT="$ROOT_DIR/release/ota-manifest.generated.plist"

if [[ -z "$IPA_URL" || -z "$DISPLAY_IMAGE_URL" || -z "$FULL_SIZE_IMAGE_URL" ]]; then
  echo "IPA_URL, DISPLAY_IMAGE_URL, and FULL_SIZE_IMAGE_URL are required."
  exit 2
fi

sed \
  -e "s|__IPA_HTTPS_URL__|$IPA_URL|g" \
  -e "s|__DISPLAY_IMAGE_HTTPS_URL__|$DISPLAY_IMAGE_URL|g" \
  -e "s|__FULL_SIZE_IMAGE_HTTPS_URL__|$FULL_SIZE_IMAGE_URL|g" \
  "$ROOT_DIR/release/ota-manifest-template.plist" > "$OUT"

echo "Manifest written to: $OUT"
echo "Install link:"
echo "itms-services://?action=download-manifest&url=$OUT"
