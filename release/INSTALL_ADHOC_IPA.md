# Install LifeOS iOS Without TestFlight

This is the direct `.ipa` path. The tester does not need TestFlight, but the app must be signed for their exact iPhone.

This is not the free route. For Monterey setup, use [MONTEREY_MACPORTS_INSTALL.md](MONTEREY_MACPORTS_INSTALL.md). Apple's free Xcode Personal Team signing needs a weekly refresh and cannot produce a forever-signed `.ipa`.

## What You Need

1. Apple Developer Program membership.
2. Your iOS Distribution certificate installed in Keychain on a Mac.
3. App ID: `app.lifeos.ios`.
4. Your friend's iPhone UDID registered in Apple Developer.
5. An ad hoc provisioning profile for `app.lifeos.ios` that includes that UDID.
6. Xcode installed on the Mac.

Apple references:

- [Distributing your app to registered devices](https://developer.apple.com/documentation/xcode/distributing-your-app-to-registered-devices)
- [Create an ad hoc provisioning profile](https://developer.apple.com/help/account/provisioning-profiles/create-an-ad-hoc-provisioning-profile/)

## Get The Friend's UDID

On your friend's iPhone:

1. Connect the iPhone to a Mac with a cable.
2. Open Finder, select the iPhone, click the serial number until the UDID appears.
3. Copy the UDID.
4. In Apple Developer, open Certificates, Identifiers & Profiles, then Devices, then add the UDID.

## Build The Signed IPA

From this repo on a Mac:

```bash
TEAM_ID=YOURTEAMID \
PROFILE_NAME="LifeOS Ad Hoc" \
BUNDLE_ID=app.lifeos.ios \
./scripts/build-adhoc-ipa.sh
```

The output is:

```text
build/export/LifeOS.ipa
```

## Install Option A: Mac Cable Install

1. Connect the tester iPhone to the Mac.
2. Open Apple Configurator or Xcode Devices and Simulators.
3. Drag `LifeOS.ipa` onto the connected iPhone.
4. Wait for install to finish.
5. Open LifeOS on the iPhone.

## Install Option B: HTTPS Over-The-Air Link

1. Upload `LifeOS.ipa`, a 57x57 display icon, a 512x512 full icon, and a filled OTA manifest plist to HTTPS hosting.
2. Generate the link:

```text
itms-services://?action=download-manifest&url=https://your-domain.example/lifeos/manifest.plist
```

3. Send the link to the tester.
4. The tester opens it in Safari and confirms install.

GitHub release asset URLs can redirect; if Safari refuses the install, host the `.ipa` and manifest on a simple HTTPS file host you control.

## Common Failures

- "Unable to Install": the UDID is missing from the ad hoc profile or the profile is not embedded.
- "App integrity could not be verified": wrong certificate/profile pair or expired signing asset.
- App installs but notifications do not appear: open Settings in LifeOS and grant notification permission.
