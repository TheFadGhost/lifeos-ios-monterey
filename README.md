# LifeOS iOS Monterey

LifeOS iOS Monterey is a native SwiftUI port of the offline Android LifeOS app. It keeps the same local-first promise: no accounts, no cloud sync, no analytics, no remote config, no downloadable assets, and no network calls.

This version is packaged for macOS Monterey + MacPorts users. The Xcode project is checked in at `LifeOS/LifeOS.xcodeproj`, so the app opens directly in Xcode.

## What Is Included

- Dashboard command center with command search, quick capture, smart plan, reviews, trends, focus timer, and reminders.
- Habits, Tasks, Calendar, Money, Fitness, Level Up, Notes, and Settings modules.
- Local JSON persistence in Application Support.
- Local notification scheduling for reminders.
- Local JSON/CSV export.
- Theme presets matching the Android LifeOS theme names.
- Committed Xcode project and shared scheme.
- Monterey + MacPorts install instructions.
- Optional ad hoc `.ipa` signing/export scripts for paid Apple Developer accounts.

## Monterey + MacPorts

See [release/MONTEREY_MACPORTS_INSTALL.md](release/MONTEREY_MACPORTS_INSTALL.md).

The short version:

```bash
xcode-select --install
sudo xcodebuild -license accept
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
sudo port selfupdate
sudo port install git
```

Then open:

```text
LifeOS/LifeOS.xcodeproj
```

## Build On macOS

```bash
cd LifeOS
xcodebuild test \
  -project LifeOS.xcodeproj \
  -scheme LifeOS \
  -destination 'platform=iOS Simulator,name=iPhone 14' \
  CODE_SIGNING_ALLOWED=NO
```

Choose a simulator that exists on the Mac. Xcode 14.2 on Monterey does not include iPhone 15 Pro device support.

## iPhone 15 Pro Compatibility

An iPhone 15 Pro requires iOS 17 or later. Apple-supported iOS 17 device deployment starts with Xcode 15, and Xcode 15 requires macOS Ventura 13.5 or newer. That means a Monterey MacBook cannot install this app onto an iPhone 15 Pro using Apple-supported tools.

For iPhone 15 Pro testing, use this same repo on a Mac running Ventura 13.5 or newer with Xcode 15 or newer.

## Create A Direct Install `.ipa` With Paid Ad Hoc Signing

See [release/INSTALL_ADHOC_IPA.md](release/INSTALL_ADHOC_IPA.md).

This is not the free path. Apple ad hoc `.ipa` installs require an Apple Developer Program membership, an iOS Distribution certificate, and a provisioning profile containing the tester iPhone UDID.
