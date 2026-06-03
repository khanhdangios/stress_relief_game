fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## Android

### android build_aab

```sh
[bundle exec] fastlane android build_aab
```

Build the signed Android App Bundle

### android deploy_internal

```sh
[bundle exec] fastlane android deploy_internal
```

Upload the current release build to Google Play internal testing

### android validate_play_access

```sh
[bundle exec] fastlane android validate_play_access
```

Validate Google Play credentials and app access

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
