# World milestone evidence

Source `9c4d94e328a1fcde517441aef2a73751fd0c42e9`, Godot4.5 official, 17 October 2026. [Test interpretation and limitations](../../WORLD_TEST_RESULTS.md).

- `windows-regressions.json`: final import/launch and 23 suites. `baseline-regressions.json`: original 16-suite baseline.
- `headless.json` / `rendered.json`: final 360-frame accelerated traversal probes per E0/34/55/80/120; process-tree sampled RSS, not GPU accounting.
- `save.json`: checkpoint stress through 10,000 modified objects; synchronous write versus worker snapshot enqueue and explicit flush.
- `android-ci.txt`: selected successful Linux test and package/signature checks from Android run227.
- `captures.txt` and six PNGs: final 540x960 portrait rendered views, captured with `scripts/ci/capture_world.gd`. Settled static views verify presentation, not motion/pop-in or touchscreen response.

Captures show original beach/Banksia, new city at E34, inland facilities at E55 and world/boundary at E120. Global roads and silhouettes remain regular/coarse first-pass content. All data are single-run observations; Android device validation remains outstanding.
