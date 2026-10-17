# Missions and landmarks verification - 17 October 2026

[World Preview APK #229](https://github.com/kavemankai/Kaijustomp/releases/download/persistent-world-229-c9776a3/Kaijustomp-229-c9776a3-debug.apk), source `c9776a3b7370ce04986a8916d2a90a9e811be20d`, [Android run229](https://github.com/kavemankai/Kaijustomp/actions/runs/39017558000). 28,104,076 bytes, package `com.kavemankai.kaijustomp.worldpreview`, version `0.1.229-debug`, ARM64. SHA-256 `2532a6bd9e970e79540a3183fef685cb45485889750069944499ab5991acec93`.

All **24 suites**, import and launch pass on Windows and Linux CI for the exact source. Android push/PR runs [229](https://github.com/kavemankai/Kaijustomp/actions/runs/39017558000) / [230](https://github.com/kavemankai/Kaijustomp/actions/runs/39017560533) and smoke [155](https://github.com/kavemankai/Kaijustomp/actions/runs/39017557974) / [156](https://github.com/kavemankai/Kaijustomp/actions/runs/39017560557) pass. CI confirms APK v2/v3 signatures, package/launcher, ZIP CRC and both ARM64 libraries' native 16 KiB alignment. Downloaded release bytes independently match the published SHA-256 and byte count; ZIP CRC and both native libraries' 16 KiB alignment pass locally. See validation/objectives/apk-verification.json.

`test_world_objectives` adds actual discovery/travel, all six destinations and distinctive art, landmark damage/tombstones through unload, duplicate reward prevention, responder combat, alive DEFCON cooldown, E22/E34 credit, objective UI pause/selection/control reset, disk progress/track restoration, legacy destruction credit, malformed records and future-format preservation. All original gameplay and streamed-world suites remain intact. Renown is derived from completion flags and does not award biomass.

[Raw results and captures](validation/objectives/README.md) include final Windows JSON and 540x960 tracker/list/harbour/command images. The rendered RTX3050 Laptop/OpenGL3.3 traversal probe records startup **661.438 ms / 1,118 nodes / 40.37 MiB static**, sampled peak process-tree RSS **240.78 MiB**, CPU update p95 **7.855-9.007 ms**, p99 **9.257-12.120 ms**, maximum **13.131 ms**, and generation max **5.616 ms**. E120 retains **149 chunks / 1,580 nodes / 231 registry slots** in this route. The objective menu is closed during traversal; its rows allocate only when opened, and remain bounded by 13 goals. Different workloads and scheduling preclude claims of measured improvement over APK227.

Phone installation, portrait multitouch/scrolling, sustained FPS/memory/thermals and natural mission/progression pacing remain unverified. Synthetic UI signals and settled screenshots do not substitute for those checks. Smaller custom world extents may omit default landmark destinations. See WORLD_OBJECTIVES.md for scope and save compatibility.

The historical results below apply to APK227, not the new mission build.

---

# Persistent world verification - 17 October 2026

Delivered gameplay/build source: `9c4d94e328a1fcde517441aef2a73751fd0c42e9`, branch `feature/persistent-streamed-world`. [Draft PR #18](https://github.com/kavemankai/Kaijustomp/pull/18) targets `integration/stable-baseline`. No merge or approved-release replacement occurred. Later documentation commits do not change this APK source.

## Android artifact

[Download World Preview APK #227](https://github.com/kavemankai/Kaijustomp/releases/download/persistent-world-227-9c4d94e/Kaijustomp-227-9c4d94e-debug.apk) | [immutable prerelease](https://github.com/kavemankai/Kaijustomp/releases/tag/persistent-world-227-9c4d94e) | [successful Android build](https://github.com/kavemankai/Kaijustomp/actions/runs/39014951239).

Package `com.kavemankai.kaijustomp.worldpreview`, label **Kaijustomp World Preview**, version `0.1.227-debug` (code 227), ARM64. **28,083,168 bytes**. SHA-256:

```text
f1912a6568635d352be9dccf0160fbb49e84e298c588addd5c5214353c436585
```

Downloaded bytes match the published digest. Local ZIP CRC and both libraries' ELF 16 KiB alignment pass. CI additionally verifies APK v2/v3 signatures, package, launcher and architecture before publication. This debug package installs separately from the approved/integration packages. Physical Android installation and play have **not** been performed in this environment.

## Regression evidence

Baseline `00eb61e` / APK217 gameplay source `317743c`: official Godot `4.5.stable.official.876b29033`, Windows import, 60-frame launch and all 16 original suites pass before modification.

Final source: import, launch and **all 23 suites pass on Windows and Linux CI**. The original 16 remain; tests requiring distant buildings activate their region instead of assuming permanent residency. The authored fixture compares all 114 original structures' positions, dimensions, names, strength, occupants and hit/reward inputs.

| Added suite | Contracts exercised |
| --- | --- |
| `test_authored_world` | Source-captured starting-region preservation. |
| `test_world_generation` | Seed/order determinism, negative chunks, stable IDs, seven district families, shared road edges and parcel setbacks. |
| `test_world_streaming` | Approximately 25,000 units accumulated coastal swept movement plus 5,500 inland; bounded ownership; unload/reload; damage, destruction and claimed rewards; E34/55/80/120 frusta and giant boundary collision; same-frame LOD projectile cover; static prefetch during evolution pauses. |
| `test_world_persistence` | Atomic save, backup recovery, version-0 migration, malformed nested records and unsupported future-version preservation. |
| `test_world_resume` | Disk restart restores player/evolution/history/position, DEFCON, unique vehicles, damage/rewards and pending evacuations. |
| `test_world_response` | Ground/air approaches in authored and expanded areas; actual projected offscreen materialisation, APC hull clearance, caps and actor cleanup. |
| `test_world_async_save` | Detached immutable snapshots, bounded/coalesced jobs, flush and reset ownership despite live mutations. |

Travel uses existing swept movement with accelerated timesteps; it is not a real-time endurance or phone test. Static assertions do not prove absence of perceptible pop-in in every motion. No evolution gating, core diet/progression or control redesign was introduced.

Push/PR Android runs [227](https://github.com/kavemankai/Kaijustomp/actions/runs/39014951239) / [228](https://github.com/kavemankai/Kaijustomp/actions/runs/39014955072) and smoke runs [153](https://github.com/kavemankai/Kaijustomp/actions/runs/39014951233) / [154](https://github.com/kavemankai/Kaijustomp/actions/runs/39014955172) all succeed for this exact source. Raw Windows results, probes, package evidence and portrait captures are in [validation/world](validation/world/README.md).

## Desktop measurements

Reproduce with `python scripts/ci/profile_runtime.py --godot <Godot4.5>` and optionally `--rendered`; run `profile_world_save.gd` separately. Single-run desktop observations are not Android FPS certification. The traversal probe advances 360 accelerated frames at each of E0/34/55/80/120, recording CPU updates, generation, frame intervals, nodes and process-tree RSS. It excludes live autosave disk work; saving has its own benchmark.

| Final source probe | Headless | Rendered |
| --- | --- | --- |
| Startup | 550.655 ms / 1,101 nodes | 629.304 ms / 1,101 nodes |
| Startup static allocation | 36.44 MiB | 39.72 MiB |
| Sampled peak process-tree RSS | 123.46 MiB | 239.81 MiB |
| CPU update p95 across sizes | 6.319-8.308 ms | 7.532-9.195 ms |
| CPU update p99 across sizes | 7.943-12.691 ms | 9.395-11.946 ms |
| Maximum CPU update | 14.455 ms | 15.625 ms |
| Maximum individual generation | 6.256 ms | 5.405 ms |
| E120 peak chunks / nodes / registry slots | 125 / 1,624 / 247 | 149 / 1,554 / 231 |

Rendered Windows Compatibility/OpenGL 3.3 used an NVIDIA RTX3050 Laptop GPU, driver 610.78. Frame p95 was 16.690-16.741 ms under desktop pacing. Different view/scheduling can retain different chunk counts. Static allocation, process RSS and GPU memory are different quantities. Baseline idle measurements are not comparable to moving traversal. The nominal 2 ms cooperative scheduler is **not a hard latency cap**; indivisible construction and collision safety work exceed it.

At 10,000 modified objects (768,999-byte JSON), synchronous atomic write p50/p95 was 87.690/97.030 ms. The delivered worker instead enqueues detached snapshots in 2.588/3.615 ms, with serialization and disk I/O off the gameplay thread. Pause/exit/reset flush took 156.743 ms. At 1,000 records enqueue p95 was 0.397 ms. Snapshot cost remains O(modified objects); long saves need phone measurements.

## Outstanding acceptance

- Install APK227 on a real phone; verify portrait multitouch/sprint, evolution interruptions, background/resume and fresh restart.
- Record sustained traversal, E120 combat/demolition, frame-time percentiles, process/GPU memory and thermals. The 60 FPS goal / practical 30 FPS target remain unvalidated.
- Review visible LOD transitions, giant gait, district identity, road regularity and travel pacing. Seven functional district families use reused kits, with coarse distant silhouettes and regular global roads remaining first-pass content.
- Exercise natural progression and biomass balance on device. Reward persistence prevents duplicate claims but does not establish full-map economic balance.
