# Three simultaneous sector missions

Gameplay/build source `373436337c013e46da6c15b78c4723aed948ba4f`, Godot4.5 official.

The 540x960 captures show automatic three-row tracking, the pin selector, and generated landmark contexts. `windows-regressions.json` records import/launch and all25 suites. `test_world_tracking` checks exactly three unique suggestions when available, sector/threat relevance, manual pin order and cap, unpin/autofill, completion cleanup, disk restart, single-selection migration, malformed arrays and all-complete display.

UI signals and static rendered captures do not establish physical touchscreen performance. Phone installation, scrolling/multitouch, sustained frame pacing and natural relevance/pacing remain acceptance tasks. WORLD_TEST_RESULTS.md and CODEX_HANDOVER.md record the delivered artifact. Earlier performance JSONs apply to their stated source commits, not a new measurement of this tracker.
