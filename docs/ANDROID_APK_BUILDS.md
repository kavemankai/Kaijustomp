# Android APK builds — Kaijustomp

The beach prototype has a **Godot 4.3 Android debug APK** workflow for regular phone tests. It preserves the 9:16 portrait gameplay, camera, touch controls, and evolution work on the feature branch.

## Download the latest APK

1. Open [Android debug APK Actions](https://github.com/kavemankai/Kaijustomp/actions/workflows/android-apk.yml).
2. Select the newest **successful (green)** workflow run for the branch `feature/beach-demo-elevated-camera`. A workflow run can take several minutes because it downloads Godot and Android tooling.
3. Scroll to **Artifacts** and download `Kaijustomp-Android-debug-<run number>`. You may need to sign in to GitHub to download artifacts.
4. Extract the ZIP; inside is the `Kaijustomp-<run>-<commit>-debug.apk`.
5. Transfer the APK to your Android phone, open it, and allow installs from that source when prompted. The icon should appear in the app drawer.

If the workflow is **red**, open the failed job's logs; there is no verified APK for that run. Do not download an older artifact assuming it contains the latest changes.

## When it builds again

The workflow automatically runs on **every branch that contains this workflow**, including `feature/beach-demo-elevated-camera` and future branches, and on tags beginning with `v` (e.g. `v0.1.1`). Failed game builds do not upload an APK; see their Actions logs for the cause.

It can also be started manually using GitHub Actions → **Android debug APK** → **Run workflow** when GitHub exposes manual dispatch for the branch. Artifacts are retained for **30 days**, after which they can be regenerated from the source by starting another run.

APK metadata: Android ARM64, ID `com.kavemankai.kaijustomp`, app name `Kaijustomp`, debug-signed; version code increases each build. This is intended for direct installation/testing, **not** Google Play publication.

## Stable signing across builds (optional but recommended)

The workflow signs APKs without needing secrets. By default it generates a new debug signing certificate per run. Because Android requires the *same* signing certificate for an in-place update, you will need to **uninstall the old debug APK before installing another** unless a stable signing key is configured. Uninstalling may erase local game data.

To enable install-over-install updates without requiring a release signing key:

1. Privately generate one dedicated **test-only** keystore (alias `androiddebugkey`, store and key password both `android`) and store it somewhere safe. Do **not** reuse a production key.
2. Base64-encode that keystore file.
3. Go to GitHub repository **Settings → Secrets and variables → Actions → New repository secret**. Add `KAIJUSTOMP_DEBUG_KEYSTORE_BASE64` containing the one-line base64 value.
4. Future workflow runs automatically use that same certificate. Existing APKs signed using another key will still need a one-time uninstall.

Do not commit a keystore, signing passwords, or Android credentials. The project's `.gitignore` excludes APKs and keystore files.

## How builds work

- GitHub Actions uses Ubuntu, JDK 17 and Android SDK platform/build tools 34.
- It downloads the official Godot **4.3-stable** editor and **matching export templates**.
- It imports the project headlessly, checks for GDScript parse errors, exports the `Android` debug preset from `export_presets.cfg`, and verifies the resulting APK with `apksigner` and Android package tools.
- An APK is uploaded as a build artifact only if export and verification succeed.

Source files:
- `export_presets.cfg` — shared Android export options, kept in Git.
- `.github/workflows/android-apk.yml` — repeated automated builds.
- `.github/workflows/beach-demo-smoke.yml` — existing Godot script/scene smoke tests.
- `project.godot` — portrait orientation and rendering settings.

## Before distributing a finished game

Create a separate production release process using a dedicated private release signing key and an **Android App Bundle (AAB)** for Google Play. Do not treat these debug APKs as production releases.
