# Monterey + MacPorts Install Guide

This package is for a MacBook running macOS Monterey with MacPorts. It does not need a project generator. The Xcode project is already checked in at `LifeOS/LifeOS.xcodeproj`.

## Important iPhone 15 Pro Limit

Apple's Xcode support table says Xcode 14.2 is the last Xcode line that runs on macOS Monterey 12.5 or later, and its device support stops at iOS 16.2. Apple's same table says Xcode 15.0.x is the first line with iOS 17 device support, and it requires macOS Ventura 13.5 or later.

An iPhone 15 Pro ships with iOS 17 or later. That means a Monterey MacBook cannot install or debug this app on an iPhone 15 Pro with Apple-supported tools. For that phone, use a Mac on Ventura 13.5 or newer with Xcode 15 or newer.

The Monterey path below is still useful for opening the project, building, running tests, and using an older iPhone or simulator supported by Xcode 14.2.

## Set Up Monterey

1. Install Xcode 14.2 from Apple's Developer downloads page.
2. Open Xcode once and accept the license.
3. Open Terminal.
4. Run:

```bash
xcode-select --install
sudo xcodebuild -license accept
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

5. Install the Monterey MacPorts package from `https://www.macports.org/install.php`.
6. Add MacPorts to the shell path if it is not already there:

```bash
export PATH=/opt/local/bin:/opt/local/sbin:$PATH
```

7. Update MacPorts and install Git:

```bash
sudo port selfupdate
sudo port install git
```

## Download And Open LifeOS

1. Open the GitHub release page.
2. Download `LifeOS-iOS-Monterey-v1.00-release-kit.zip`.
3. Open the zip.
4. Move the folder to Desktop.
5. Open the folder.
6. Open `scripts`.
7. Double-click `open-lifeos-in-xcode.command`.
8. If macOS blocks it, right-click it, click Open, then click Open again.

Xcode should open `LifeOS/LifeOS.xcodeproj`.

## Build On Monterey

In Xcode:

1. Select the `LifeOS` scheme.
2. Select an iPhone simulator available in Xcode 14.2.
3. Click the Run button.

From Terminal:

```bash
cd LifeOS
xcodebuild test \
  -project LifeOS.xcodeproj \
  -scheme LifeOS \
  -destination 'platform=iOS Simulator,name=iPhone 14' \
  CODE_SIGNING_ALLOWED=NO
```

If Xcode 14.2 does not have the exact simulator named above, open Xcode's device selector and choose one that exists on that Mac.

## Free Device Install On Supported Older iPhones

For an older iPhone on iOS 16.2 or lower:

1. Connect the iPhone to the MacBook.
2. Trust the Mac on the iPhone.
3. In Xcode, select the connected iPhone.
4. Open Signing & Capabilities for the `LifeOS` target.
5. Enable automatic signing.
6. Choose the free Personal Team.
7. Change the bundle identifier if Xcode says it is already taken.
8. Click Run.

Apple free signing expires after 7 days. To keep using it for free, reconnect the phone and press Run again before or after it expires. Do not delete the app when refreshing, because deleting it removes local app data.

## iPhone 15 Pro Path

For an iPhone 15 Pro:

1. Upgrade the Mac to Ventura 13.5 or newer, or use another Mac already on Ventura/Sonoma/newer.
2. Install Xcode 15 or newer.
3. Open this same checked-in project.
4. Use the same free Personal Team signing flow.

No MacPorts command can add iOS 17 device support to Xcode 14.2 on Monterey.
