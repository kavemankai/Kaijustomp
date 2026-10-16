# Android APK builds — Kaijustomp

## Current isolated creature/evolution candidate

[Build 85 APK](https://github.com/kavemankai/Kaijustomp/releases/download/creature-evolution-85-afb0c7e/Kaijustomp-85-afb0c7e-debug.apk), source `afb0c7ee8508f5331b5220fa6868679355f58672`. [Verified Actions run](https://github.com/kavemankai/Kaijustomp/actions/runs/38907095501). See [handover](CODEX_HANDOVER.md) for full validation and remaining phone checks. Package `com.kavemankai.kaijustomp.creaturepreview` installs beside the approved beach package. Immutable candidate tags include build and short SHA; stable beach and earlier preview assets are preserved. The workflow runs all five regressions before exporting and verifying the package/signature/native alignment. Debug signing may change between candidates, so updating an older **preview** may require uninstalling that preview; the separately installed approved app is unaffected.

The beach prototype has a **Godot 4.5 Android debug APK** workflow for regular phone tests. It preserves the 9:16 portrait gameplay, camera, touch controls, and evolution work on the feature branch.

## Direct installation from your phone

**Important:** The original `mobile-preview` release contains an older Godot 4.3 APK with ARM64 native libraries aligned to 4 KiB. Do not install that build on an Android device requiring 16 KiB pages. The new `mobile-preview-godot45` link below remains unavailable until a successfully verified Godot 4.5 workflow run publishes it.

**One-link download:** [Kaijustomp latest Android APK](https://github.com/kavemankai/Kaijustomp/releases/download/mobile-preview-godot45/Kaijustomp-latest.apk)

This static URL downloads the latest successfully published APK **once the GitHub Actions build has completed successfully**. It is an APK file (not a ZIP). Tap the link on an Android phone, open the downloaded APK and confirm **Install**. The first time, Android may prompt you to allow installation from your browser or Files app under *Install unknown apps*. No webpage can bypass that Android security confirmation.

If the link currently reports 404, the first preview release has not been published successfully yet. Open [Android debug APK Actions](https://github.com/kavemankai/Kaijustomp/actions/workflows/android-apk.yml), inspect the newest run and resolve its failure. The permanent release URL is not evidence that the APK already exists.

**Updates:** The test APK uses per-run generated debug signing certificates until the optional stable test-signing key is configured below. Without the stable key, new versions can require uninstalling the old one, which may remove local saves. A shared test key is recommended if you want repeatable install-over-install updates.

## If the downloaded APK is tiny or won't install

**Do not try installing a file that is only a few KB.** It may be an error page or failed download saved with an `.apk` filename rather than an Android application. Godot's native runtime ordinarily makes a real installable APK many megabytes.

1. Check Android **Files → Downloads → file details**. An APK from this pipeline must now be at least **12 MB** or the build is rejected automatically.
2. In GitHub Actions, open the latest **successful** `Android debug APK` workflow run. If there is no green successful run, the permanent release URL should not be trusted yet.
3. If the run is red, expand its failed step (import, export, signing, verification or publishing) and report the first error. A missing `mobile-preview-godot45` release means no verified direct APK has been published.
4. If the APK is larger than 12 MB but Android says **App not installed**, an older APK signed with a different debug key may already be installed. Back up any save data before uninstalling the old build. Then retry.
5. If Android refuses to open the package, try opening it from **Files**, and allow **Install unknown apps** for Files or your browser if prompted. Do not turn off Play Protect or other device security.

The workflow now refuses to publish exports smaller than 12 MB, checks the ZIP contents (Android manifest, DEX and ARM64 engine library), checks all ARM64 engine libraries for **16 KiB memory-page alignment**, verifies the Android signature and launcher package, and confirms that GitHub saved the complete asset. These checks do not replace a real-device install test.

## Download the latest APK from build history

1. Open [Android debug APK Actions](https://github.com/kavemankai/Kaijustomp/actions/workflows/android-apk.yml).
2. Select the newest **successful (green)** workflow run for the branch `feature/beach-demo-elevated-camera`. A workflow run can take several minutes because it downloads Godot and Android tooling.
3. Scroll to **Artifacts** and download `Kaijustomp-Android-debug-<run number>`. You may need to sign in to GitHub to download artifacts.
4. Extract the ZIP; inside is the `Kaijustomp-<run>-<commit>-debug.apk`.
5. Transfer the APK to your Android phone, open it, and allow installs from that source when prompted. The icon should appear in the app drawer.

If the workflow is **red**, open the failed job's logs; there is no verified APK for that run. Do not download an older artifact assuming it contains the latest changes.

## When it builds again

The workflow automatically runs on **every branch that contains this workflow**, including `feature/beach-demo-elevated-camera` and future branches, and on tags beginning with `v` (e.g. `v0.1.1`). After an APK passes export and signature checks, builds from the approved beach demo branch (and later main/master) update the permanent `mobile-preview-godot45` GitHub release asset. Builds from other feature branches retain their separate CI artifacts. Tagged builds still generate dated CI artifacts; the permanent link is for branch previews. Failed builds do not replace the last successful APK; see Actions logs for the cause.

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

- GitHub Actions uses Ubuntu, JDK 17 and Android SDK platform/build tools 35.
- It downloads the official Godot **4.5-stable** editor and **matching export templates**.
- It imports the project headlessly, checks for GDScript parse errors, runs the headless **evolution/shedding regression** (snapshot, paused choice, tap reveal, history and failure), exports the `Android` debug preset from `export_presets.cfg`, verifies **16 KiB ELF alignment** of every ARM64 native library, and verifies the resulting APK with `apksigner` and Android package tools.
- An APK is uploaded as a build artifact only if export and verification succeed.
- Branch builds then publish the APK unchanged under the reusable name `Kaijustomp-latest.apk` at the `mobile-preview-godot45` GitHub prerelease. `GH_TOKEN` comes from the workflow's built-in GitHub token, using `contents: write` permission. No third-party storage account is needed.

Source files:
- `export_presets.cfg` — shared Android export options, kept in Git.
- `.github/workflows/android-apk.yml` — repeated automated builds.
- `.github/workflows/beach-demo-smoke.yml` — existing Godot script/scene smoke tests.
- `project.godot` — portrait orientation and rendering settings.

## Before distributing a finished game

Create a separate production release process using a dedicated private release signing key and an **Android App Bundle (AAB)** for Google Play. Do not treat these debug APKs as production releases.

## Android 16 / 16 KiB compatibility diagnosis (2026-10-16)

The uploaded phone-test file `Kaijustomp-latest (1).apk` was inspected directly. Its ZIP archive was intact, **24,221,281 bytes** (23.10 MiB), contained an Android manifest, DEX bytecode, Godot 4.3 engine libraries and debug signing. The manifest showed package `com.kavemankai.kaijustomp`, version `0.1.8-debug`, `minSdkVersion=21`, `targetSdkVersion=34`, portrait orientation and the ARM64 architecture. No corruption was detected.

**Confirmed defect:** both `lib/arm64-v8a/libgodot_android.so` and `lib/arm64-v8a/libc++_shared.so` contain ELF `PT_LOAD` segments aligned at `0x1000` (4 KiB). This does **not** satisfy 16 KiB native page alignment required on 16 KiB page-size Android devices, and can prevent installation or launch on those devices. This is a known Godot 4.3 Android-export limitation resolved in Godot 4.5.

**Pipeline change:** use Godot 4.5 editor **and matching Android export templates**, SDK 35, and the pure-Python `scripts/ci/verify_android_16k.py` check before publishing the APK. The existing 24.2 MB file is **not** repaired; it must be rebuilt using the new workflow. A successful pipeline proves build structure and native alignment but is not equivalent to an on-device installation test.

**Another possible installer issue:** CI makes a fresh debug signing certificate per run unless `KAIJUSTOMP_DEBUG_KEYSTORE_BASE64` is configured. Android refuses an in-place update to an APK with the same package name but a different signing certificate. Preserve save data before uninstalling an older build, and set the stable test-signing secret for future updates.

If installation still fails, record Android's **exact error message** (e.g. `App not installed`, `Package appears invalid`, or a permissions/installer prompt), whether an older Kaijustomp app is already present, and whether the device is in 16 KiB page-size mode.
