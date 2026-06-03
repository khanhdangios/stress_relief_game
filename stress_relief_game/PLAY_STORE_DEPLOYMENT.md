# Google Play Deployment

This project is configured to upload the signed Android App Bundle to Google Play with Fastlane.

## Prerequisites

1. Create the app in Google Play Console with package name:
   `com.khanhdangios.stressreliefgame`
2. Create or link a Google Cloud service account for Play Console API access.
3. Grant the service account access in Play Console.
4. Download the service account JSON key and save it locally as:
   `android/fastlane/play-store-service-account.json`

The JSON key is ignored by Git and must not be committed.

## Install Fastlane

```sh
brew install fastlane
```

## Validate Play Console Access

```sh
cd android
fastlane validate_play_access
```

## Upload Internal Testing Build

```sh
cd android
fastlane deploy_internal
```

The `deploy_internal` lane builds:

```sh
flutter build appbundle --release
```

Then uploads:

```text
build/app/outputs/bundle/release/app-release.aab
```

The release is uploaded to the `internal` track as a draft.
