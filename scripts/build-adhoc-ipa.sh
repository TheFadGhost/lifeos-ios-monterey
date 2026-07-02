#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_DIR="$ROOT_DIR/LifeOS"
BUILD_DIR="$ROOT_DIR/build"
ARCHIVE_PATH="$BUILD_DIR/archive/LifeOS.xcarchive"
EXPORT_DIR="$BUILD_DIR/export"
EXPORT_OPTIONS="$BUILD_DIR/ExportOptions.generated.plist"

TEAM_ID="${TEAM_ID:-}"
PROFILE_NAME="${PROFILE_NAME:-}"
BUNDLE_ID="${BUNDLE_ID:-app.lifeos.ios}"
CONFIGURATION="${CONFIGURATION:-Release}"
SCHEME="${SCHEME:-LifeOS}"

if [[ -z "$TEAM_ID" || -z "$PROFILE_NAME" ]]; then
  echo "TEAM_ID and PROFILE_NAME are required."
  echo "Example: TEAM_ID=ABCDE12345 PROFILE_NAME=\"LifeOS Ad Hoc\" ./scripts/build-adhoc-ipa.sh"
  exit 2
fi

if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "xcodebuild is required. Install Xcode from Apple."
  exit 2
fi

mkdir -p "$BUILD_DIR" "$EXPORT_DIR"

pushd "$PROJECT_DIR" >/dev/null
xcodebuild \
  -project LifeOS.xcodeproj \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -archivePath "$ARCHIVE_PATH" \
  DEVELOPMENT_TEAM="$TEAM_ID" \
  PRODUCT_BUNDLE_IDENTIFIER="$BUNDLE_ID" \
  CODE_SIGN_STYLE=Manual \
  PROVISIONING_PROFILE_SPECIFIER="$PROFILE_NAME" \
  clean archive
popd >/dev/null

sed \
  -e "s/__TEAM_ID__/$TEAM_ID/g" \
  -e "s/__BUNDLE_ID__/$BUNDLE_ID/g" \
  -e "s/__PROFILE_NAME__/$PROFILE_NAME/g" \
  "$ROOT_DIR/release/ExportOptions-AdHoc.plist" > "$EXPORT_OPTIONS"

xcodebuild -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_DIR" \
  -exportOptionsPlist "$EXPORT_OPTIONS"

echo "Signed IPA exported to: $EXPORT_DIR/LifeOS.ipa"
