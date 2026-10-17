# Reproducing the integration candidate

## Clean gameplay verification

Use official **Godot 4.5-stable**, not the installed editor's default version. Python 3.10+ is sufficient; the runner uses only the standard library.

```powershell
git clone https://github.com/kavemankai/Kaijustomp.git
Set-Location Kaijustomp
git switch integration/stable-baseline
python scripts/ci/run_regressions.py --godot C:/tools/Godot_v4.5-stable_win64_console.exe
```

On Linux substitute the Godot Linux executable path. Run from a clean checkout for release verification. The runner rejects other engine versions, imports once, launches the actual main scene for 60 frames, discovers every `scripts/ci/test_*.gd` suite (currently **16**), captures complete logs and `results.json` in ignored `build/regressions/`, and fails on timeout/nonzero exit/engine errors/missing success marker. CI uses this same command in both workflows and retains evidence for 30 days. `--output build/baseline` permits separate comparisons. Suite timeout defaults to 120 seconds per process.

## Android debug export

The existing `.github/workflows/android-apk.yml` provisions JDK 17, Android platform/build-tools 35, official Godot 4.5 and matching 4.5 Android templates. It imports, launches, runs every suite, prepares debug signing, exports ARM64 and verifies:

- APK exists, is at least 12 MB and passes ZIP CRC checks;
- manifest/DEX/ARM64 engine entries exist;
- every ARM64 library passes `python3 scripts/ci/verify_android_16k.py <apk>`;
- `apksigner verify --verbose` succeeds;
- `aapt dump badging` matches the expected package, launcher and ARM64 architecture;
- checksum and uploaded prerelease asset size match.

Push the integration branch to trigger CI. Integration pushes publish an immutable `integration-<run>-<short-sha>` **prerelease**, after verification, without replacing stable or earlier preview assets. Pull requests build artifacts but do not publish this release. The checked-in export preset defaults to **`com.kavemankai.kaijustomp.integrationpreview`**, label **Kaijustomp Integration Preview**, so local exports also install beside the approved app. CI still selects separate existing IDs for named feature previews. Approved stable branches explicitly select the original ID.

For a local export, configure Godot's Android SDK and Java paths, install matching 4.5 templates and a debug keystore in editor settings, then run:

```powershell
New-Item -ItemType Directory -Force build/android
& C:/tools/Godot_v4.5-stable_win64_console.exe --headless --path . --export-debug Android build/android/Kaijustomp-integration-debug.apk
python scripts/ci/verify_android_16k.py build/android/Kaijustomp-integration-debug.apk
```

Use Android build-tools 35 `apksigner` and `aapt` checks as CI does; a file existing is not proof of a usable export. Never commit a keystore or use a production signing key for these tests. Without the optional stable test signing secret, a different preview certificate may require reinstalling **only the integration preview**. Exact release/build links and remaining device checks are in [CODEX_HANDOVER.md](CODEX_HANDOVER.md).

## Investigation commands

```powershell
& C:/tools/Godot_v4.5-stable_win64_console.exe --headless --path . --script res://scripts/ci/profile_world.gd
& C:/tools/Godot_v4.5-stable_win64_console.exe --path . --script res://scripts/ci/capture_integration.gd
```

The second command requires a graphics device/window and writes nine portrait images to `build/integration-captures/` plus desktop rendering counters to stdout. The first samples idle scripted CPU update time, not total frame time. Neither measures Android FPS. See [PERFORMANCE.md](PERFORMANCE.md).
