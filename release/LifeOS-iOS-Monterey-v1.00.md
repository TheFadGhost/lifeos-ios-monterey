# LifeOS iOS Monterey v1.00

This public release contains the native SwiftUI LifeOS iOS port packaged for macOS Monterey and MacPorts users. It includes a committed Xcode project, so no project generator is needed.

## Included

- Native SwiftUI LifeOS app.
- Checked-in `LifeOS/LifeOS.xcodeproj`.
- Offline-only local JSON persistence.
- Dashboard, Habits, Tasks, Calendar, Money, Fitness, Level Up, Notes, and Settings.
- Local notification support.
- JSON/CSV export.
- XCTest coverage for core Android-equivalent logic.
- Monterey + MacPorts install guide.
- Xcode 14.2 / Swift 5.7-friendly command search implementation.
- Optional paid ad hoc `.ipa` archive/export script.
- OTA manifest template and install guide.

## Download

Download `LifeOS-iOS-Monterey-v1.00-release-kit.zip` from GitHub.

For Monterey/MacPorts, follow `release/MONTEREY_MACPORTS_INSTALL.md`.

For direct `.ipa` export, follow `release/INSTALL_ADHOC_IPA.md`. A pre-signed `.ipa` is not included because iPhone-installable ad hoc `.ipa` files require your Apple Developer certificate and a provisioning profile containing the tester's iPhone UDID.

## Compatibility

Monterey can build with Xcode 14.2, but it cannot deploy to an iPhone 15 Pro on iOS 17 or later. Apple-supported iPhone 15 Pro deployment requires Ventura 13.5 or newer with Xcode 15 or newer.
