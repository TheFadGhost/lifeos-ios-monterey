#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_PATH="$ROOT_DIR/LifeOS/LifeOS.xcodeproj"

if ! command -v xcodebuild >/dev/null 2>&1; then
  cat <<'MESSAGE'
Xcode command line tools are not available yet.

Install Xcode, then run:
  xcode-select --install
  sudo xcodebuild -license accept
  sudo xcode-select -s /Applications/Xcode.app/Contents/Developer

Then double-click this file again.
MESSAGE
  exit 2
fi

if [[ ! -d "$PROJECT_PATH" ]]; then
  echo "Missing Xcode project: $PROJECT_PATH"
  exit 2
fi

if ! command -v port >/dev/null 2>&1; then
  echo "MacPorts was not found at /opt/local/bin/port."
  echo "That is OK for opening the app, but follow release/MONTEREY_MACPORTS_INSTALL.md if this MacBook is a Monterey/MacPorts setup."
fi

open "$PROJECT_PATH"
