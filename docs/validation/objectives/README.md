# Mission and landmark evidence

Gameplay/build source `c9776a3b7370ce04986a8916d2a90a9e811be20d`, Godot4.5 official. WORLD_OBJECTIVES.md defines behavior and WORLD_TEST_RESULTS.md records the artifact and acceptance limits.

- `windows-regressions.json`: final source import, launch and 24 suites, including the original 16.
- `rendered.json`: existing 360-frame traversal probe per E0/34/55/80/120, mission logic active, objective menu closed. Desktop Compatibility/OpenGL3.3 RTX3050 Laptop, driver610.78. Single run; process-tree sampled RSS is not GPU accounting or Android FPS evidence.
- `tracker.png` / `missions.png`: 540x960 selected objective and scrollable selection panel; gameplay controls hide during reading.
- `harbour.png` / `command.png`: generated parcel identities and target guidance at E34. Existing structure IDs/collision/rewards remain.
- `android-ci.txt` and `apk-verification.json`: successful CI tests/signature/package and independent downloaded-byte checks.
- `captures.txt`: clean rendered launch/capture log.

Synthetic UI signals and pause tests do not establish physical touchscreen behavior. Sustained Android performance, natural play/mission pacing and Renown presentation require device acceptance.
