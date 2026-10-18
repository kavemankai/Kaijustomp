# KaijuStomp — launch splash and title menu handover

## Completed source and verified build

- Working branch: `feature/launch-splash-title-menu`, based on `feature/morphology-traversal-polish` (draft PR #21). New draft [PR #22](https://github.com/kavemankai/Kaijustomp/pull/22).
- First reviewed runtime source: `f891869b9a7e8dffe251e7bef634294fac23609e`.
- [Verified Android APK #270](https://github.com/kavemankai/Kaijustomp/releases/download/launch-title-270-f891869/Kaijustomp-270-f891869-debug.apk), [immutable release](https://github.com/kavemankai/Kaijustomp/releases/tag/launch-title-270-f891869), [successful CI run #270](https://github.com/kavemankai/Kaijustomp/actions/runs/39111215613).
- Android debug package: `com.kavemankai.kaijustomp.launchpreview`; 28,376,691 bytes; independently installable alongside previous test apps. Build and automated suite passed; physical Android acceptance is **not** claimed.
- Documentation-only commits after the exported SHA do not alter the above APK.

## Files

- `project.godot`: launches `scenes/LaunchMenu.tscn`; coordinated Godot native boot colour and no stock engine splash.
- `scenes/LaunchMenu.tscn`: first-run Godot scene, no eager world loading.
- `scripts/ui/LaunchBackdrop.gd`: original procedural low-poly village, shoreline, skyline and serpent composition; bounded CanvasItem drawing at mobile portrait/landscape resolutions.
- `scripts/ui/LaunchMenu.gd`: skippable logo splash, responsive title, Continue/New World/Settings/Credits/desktop Exit, world state validation, independent settings persistence and an archiving safety guard before world replacement.
- `scripts/ci/test_launch_menu.gd`: verifies startup, splash skipping, valid/missing saves, new-world confirmation and layout.
- `.github/workflows/android-apk.yml`: branch-specific separate Android package, verified signed export and immutable release.

## Player flow

1. Open app: a branded intro appears briefly, then the main menu. Touch/click can skip the intro.
2. If a valid current world or backup can load, **CONTINUE** enters the original BeachDemo and resumes through its existing WorldStreaming recovery path. Corrupt or unsupported saves disable Continue, leaving data untouched.
3. **NEW WORLD** asks for confirmation when any old save/backup exists. It first archive-copies available files as `persistent-world-v1.json.archive-<timestamp>` (+ `.bak` copy), then clears the active primary/backup slots and enters a new world. If an archive copy fails, no save is removed.
4. **SETTINGS** adjusts and persists Master volume via `user://launch_settings.cfg`.
5. **CREDITS** shows project information. The mobile build omits redundant EXIT; desktop supports EXIT.

## Scope limits and next step

The approved [single immutable species per life](FIXED_SPECIES_SPECIALISATION_HANDOVER.md) design is the NEXT milestone, **not part of this build**. `NEW WORLD` currently begins the existing creature genetics gameplay; it does not secretly implement or fake the nine-species birth selection, specialisation tree or removal of hybrid mechanics. Preserve PR #21 and previous APKs. Next integration should replace New World's direct gameplay transition with the real nine-species birth-choice flow and safe old-save migration.

There is presently no in-game title-return/pause shortcut; a future menu/settings integration can add one using the existing WorldStreaming save guard. Existing game input and player movement remain unchanged. Manual phone checks should cover load delay, splash skip, large-button usability, Android audio level persistence, saved-world continue, creating new world after confirmation, and portrait/landscape responsiveness.

Do not mark the PR as ready to merge without user visual/touch acceptance and the next birth-selection integration.
