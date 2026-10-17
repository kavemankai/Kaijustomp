# Performance and giant-scale review — 17 October 2026

## Measurement scope

Godot4.5.stable official `876b29033`, Windows desktop, Compatibility/OpenGL3.3, NVIDIA RTX3050 Laptop GPU (driver610.78). `profile_world.gd` records scene construction, scene-node counts, engine static allocation and 120 explicit idle gameplay updates per representative size. This is a lightweight CPU probe, not a complete profiler capture: it excludes renderer/driver time, draw submission overhead, frame pacing and Android thermal behaviour. Population randomness and concurrent desktop work can affect timing, so single-run deltas do not establish a speedup. `capture_integration.gd` separately samples real rendered 540×960 views at z=-900; it does not report FPS.

Original startup: 871.919ms, 2196 nodes, 48.94MiB engine static allocation. Original update medians across E0–E120 ranged 0.881–1.429ms, p95 1.493–2.545ms in this particular idle probe. Raw original and final probes and test summaries are retained in `docs/validation/`. Do not interpret static allocation as total process RAM or GPU memory.

Final startup: 894.150ms, 2076 nodes, 47.99MiB static allocation. Final update medians ranged0.671–1.006ms, p95 1.372–1.786ms. Scene node count falls by120; startup time did **not** improve in this sample. The CPU timings are indicative single-run observations and are not a controlled benchmark.

## Implemented changes and verification

- 141 standalone coast road markings become ten bounded spatial mesh chunks sharing the coastal palette. Node/resource overhead falls while preserving individual building collision and uninterrupted world travel. A trial whole-coast batch submitted otherwise invisible geometry at E120; the final bounded chunks preserve the original industrial-view rendering count.
- Light/heavy tracers share two immutable meshes/materials rather than allocating geometry/materials per shot. Visual nodes still allocate under the existing72-shot cap; a full node pool is not justified by this idle probe.
- Evacuations retain people in compact records and limit active civilian art/AI to42, including mass destruction. Subsequent refresh releases at most five evacuees before ambient spawns. This addresses a verified unbounded allocation burst; it does not erase rewards or occupants.
- Existing caps remain: nine responders,72 shots,48 short-lived debris,40 effects,five shed remnants. Projectiles and debris expire; new tests exercise projectile node cleanup and scene pause.

Rendered industrial views had identical before/final draw calls and primitives at all nine sizes: E0 27/10954, E5 36/12410, E16 41/13018, E22 43/13572, E28 45/13618, E34 45/13782, E55 48/14032, E80 61/15058, E120 161/25186. E120 static allocation in those render runs was49.48MiB before and47.83MiB after. This is a resource/scene overhead improvement, **not a measured Android FPS improvement**. Images were generated at every size; E22/E120 were visually inspected for portrait framing and world/creature presentation.

## Deferred optimisations

Do not unload districts or deactivate static collision solely on distance yet. Physics broadphase already handles sleeping static bodies; unloaded collision can introduce tunnelling, missing projectile cover or duplicate rewards on reload, especially with an E120 body/camera. Static mesh batching already exists per building/chunk, and the measured industrial scenes do not establish a GPU bottleneck. Far-plane changes also alter visual coverage and offscreen reinforcement availability. Profile those costs on-device before changing them.

Follow-up Android captures must include rapid district travel, high-density industrial collapse, maximum response/projectiles, vulnerable evolution/reveal and five remnants. Collect frame time percentiles, actual RSS/PSS/GPU memory where available, physics time, draw calls, loading spikes and device thermals over15 minutes. Report device model, OS, resolution, rendering mode and exact APK SHA.

## Locomotion and giant interactions

Representative sizes E0/E5/E16/E22/E28/E34/E55/E80/E120 have scale1.000/1.200/1.905/2.514/3.118/3.741/5.839/10.573/29.881. Tests now drive the real DEBUG EVO path, verify physical body scale and industrial overlap clearance, and verify skin-bone feet stay at0.03×scale and cancel body travel through planted stance. Tests run both9:16 and20:9 camera framing. The original16-unit clearance radius failed the industrial stress case at all nine sizes; the bounded scale-aware search succeeds.

The moving pose now requires actual displacement, eliminating the frozen moving stance when pushing a boundary/wall. Stride phase already follows distance divided by2.5×scale, so multiplying gait frequency alone would introduce foot sliding. Movement speed still grows only through selected speed mutations; at E120 a stride spans about74.7 world units. The approximate hip/knee interpolation has no rigid bone-length constraint, weight transfer or planted turning solver. Thus a correct stance trajectory alone does not prove convincing giant motion; swing transitions, skin stretch, turning slip, torso momentum and long apparent weightlessness remain artistic/phone-review risks. The approved early rig, speed, camera angle and proportions are preserved.

The industrial E120 view exposes map edges/empty background because the camera covers so much ground. This candidate does not enlarge the world or change camera composition without phone review. E34+ destruction/diet and one-time biomass still pass existing physical gameplay tests.
