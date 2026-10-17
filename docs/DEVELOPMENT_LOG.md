# 2026-10-17 - genetics preview baseline

Created a separate local genetics branch from the exact current-world handoff base, verified PR #18 head, reproduced official Godot 4.5 import/launch and 25/25 suites, and independently checked APK231 bytes, ZIP and native alignment. Recorded raw results and missing specification inputs in GENETICS_PREVIEW_STATUS.md. No genetics implementation, CI export, installation or release change has occurred.

---

# 2026-10-17 - three relevant missions per sector

Expanded the HUD to three simultaneous unfinished goals, with sector heading, progress/guidance per row and manual-pin indicators. Automatic suggestions rank nearby destinations, geography, existing progression and current threat; up to three ordered pins override suggestions. Completed pins are released, empty slots refill, and all-complete state is explicit. Optional validated pin arrays migrate old primary selection while retaining save format1. Added a dedicated regression covering relevance, limits, unique suggestions, disk migration and UI state. Delivered as APK231 from3734363. All25 Windows/Linux suites and Android packaging checks pass; artifact, checksum, screenshots and device limitations are recorded in the current handover.

---

# 2026-10-17 - missions and landmark implementation

Added concurrent exploration, discovery, demolition, existing evolution milestones, responder victories and alive DEFCON escape objectives. Five generated landmark identities decorate stable existing parcels; Banksia remains unchanged. A compact portrait tracker and scrollable selection panel clear touch state and pause gameplay while open. Completions award one-time Renown badges rather than biomass. Optional validated objective records migrate old world saves, preserve future formats, and use existing bounded async checkpoints. New regression and rendered capture helpers cover objectives/persistence/UI/identity; Delivered as APK229 from c9776a3; all 24 Windows/Linux suites and Android packaging checks pass. Artifact, digest and remaining device acceptance are in the current handover.

---

# 2026-10-17 - persistent world delivery

Published isolated World Preview APK227 from `9c4d94e`; draft PR18 targets integration/stable-baseline without merging. All 23 Windows and Linux regression suites, import/launch, smoke and Android workflows pass. Downloaded digest, CRC and native alignment match; CI validates package, launcher, ARM64 and v2/v3 signature. Exact artifact and evidence are in WORLD_TEST_RESULTS.md.

Rendered review corrected terrain winding, giant-camera depth precision and block-like finite boundary art. Stable collision ownership fixes same-frame LOD cover; a 64-unit owner margin and 120-pixel camera prefetch cover chunk seams and evolution reveals. Natural hilly boundaries keep backdrop land visible at E120. Expanded aircraft clear towers and ground units use hull-aware descriptor routes. Corrupt nested save records are validated. Measured 10,000-object synchronous saves near 100 ms motivated immutable detached snapshots with a bounded worker; enqueue p95 measured 3.615 ms. Final desktop probes record spikes and RSS rather than asserting Android FPS. Phone touch/thermal/performance and natural progression acceptance remain outstanding. Approved builds and prior gameplay are preserved.

---

# 2026-10-17 — finite persistent world implementation

Verified the remote PR17 head00eb61e and APK217 source317743c; cloned into an empty workspace and created feature/persistent-streamed-world. Official Godot4.5 import/launch and all16 baseline suites pass. Preserved the authored114-structure layout in descriptors and a source-captured fixture. Added configurable20000x6000 extent,256-unit deterministic chunks, spatially coherent district anchors, connected roads, shared simple meshes, bounded art/collision lifetimes, reusable generated slots and camera-driven silhouettes. Added versioned delta saves with backup recovery/migration, player/evolution/DEFCON state, important cars and evacuation conservation. Streamed traffic and descriptor-only responder routing keep caps and offscreen arrivals. New regression scenarios exercise long real swept travel, memory ownership, persistence and warehouse approaches. This implementation was subsequently delivered as APK227; see the current handover.

---

# Development log

## 2026-10-17 — autonomous consolidation candidate

Verified release: [integration APK #217](https://github.com/kavemankai/Kaijustomp/releases/tag/integration-217-317743c), source `317743c00894de06150c0e7eef65db298206d8a2`, [draft PR #17](https://github.com/kavemankai/Kaijustomp/pull/17). Windows and Linux import/launch plus all 16 suites pass; push/PR smoke and Android workflows are green. APK signature, separate package, CRC and both ARM64 libraries' 16 KiB alignment pass; downloaded digest matches publication. Preserve locally backed-up approved #189 and outer-world #214. Phone/thermal/motion approval is still pending; exact hashes and remaining risks are in the handover.

Create integration/stable-baseline from PR16 head a4fb5fd after inspecting the complete unmerged stack. Verify the original 14 suites under Godot4.5; reproduce helicopter descent, hatchling APC feeding and uncapped collapse crowds. Fix those defects, conserve queued evacuees under the42-actor cap, protect arriving reinforcements, add conservative APC clearance and focus-loss input reset, use actual travel for moving poses, and extend physical growth-clearance search. Extract ProjectileSystem and CivilianEvacuations with owned state and pause-preserving adapters. Add two gameplay suites covering lifecycle interactions and all nine representative sizes; all16 pass with clean import and launch. Consolidate CI discovery/evidence, isolate the default Android package, batch coast markings in bounded chunks and share tracer resources. Track Godot UID sidecars. Add current audit, architecture, build process, measured desktop performance and ranked roadmap. Android results and exact source/release links follow in CODEX_HANDOVER.md. No draft merge or new world/enemy content.

## 2026-10-17 — world enlargement and hidden DEFCON wave staging

Player confirmed DEFCON success, requested expanding the world and spawning DEFCON reinforcements well beyond the player camera POV. Draft `feature/outer-district-offscreen-defcon` extends the original coastline to 1,560 units, builds 12 connected outer-suburban homes and 12 giant-scale industrial facilities beyond Banksia Heights, adding ten coast-side buildings. Original 80 indices remain stable and total rises to 114 physical structures; inland boundary moves to -1520. A true camera-projected off-screen DEFCON staging search rejects visible spots (with 55px margin), roofs, other responders and map bounds; waves may wait at extreme E120 zoom rather than pop into shot. Allow distant forces to close on the player, improve large-structure food rewards and preserve all prior DEFCON caps/evolution/controls. Add a fourteenth regression and isolated Android APK workflow. See [OUTER_WORLD_OFFSCREEN.md](OUTER_WORLD_OFFSCREEN.md). Phone performance, environment pacing and no-pop-in acceptance are still pending.


## 2026-10-17 — player request: DEFCON response and more enemies

Before phone testing the new scale-based diet preview, player asked to begin a full DEFCON system with additional enemy types. Candidate `feature/defcon-response-escalation` stacks on the unmerged diet branch; no merge or change to approved installs. Adds a five-stage alert-driven escalation (DEFCON 5 peaceful/local patrol to DEFCON 1 military air support), cooldown/de-escalation, local mixed response waves, mobile cap of nine active responders and 72 tracers. Retains police/SWAT and adds distinguishable National Guard infantry, destructible armoured vehicles and animated airborne helicopters using authored low-poly mobile art. Keeps projectile collision and building cover, and reports active DEFCON on compact portrait HUD. New `test_defcon_response.gd` is the thirteenth Godot regression, with isolated Android apk/test release. Phone balancing/visual acceptance remains pending. See [DEFCON_RESPONSE.md](DEFCON_RESPONSE.md).


## 2026-10-17 — size-driven diet / stop giant human grabbing

Player confirms batch evolution worked to E120, asks to transition food sources where individual human arm grabs become visually janky, instead of locking an arbitrary evolution. This isolated `feature/scale-driven-diet-transition` trial uses a configurable scale ratio (3.35× initial creature size; currently between E28 and E34). Once too large, people and officers still flee/act but no longer feed the giant. Demolishing vehicles begins to provide biomass during earlier upright growth, and structures become nutritious on collapse when human feeding stops. One-time rewards are footprint/type-sensitive, not per-hit; HUD shows the current food sources. Eleven prior tests remain, plus `test_scale_diet.gd`; dedicated preview APK. Does not claim to resolve E120 walk/stretch or map scale yet. See [SIZE_DIET_TRANSITION.md](SIZE_DIET_TRANSITION.md).


## 2026-10-17 — selectable multi-level DEBUG EVO

Player requested choosing how many levels to evolve in one batch. On isolated `feature/debug-batch-evolution`, replace DEBUG EVO's single forced mutation menu with a portrait numeric/preset selector (1/5/10/20/34/50, editable 1–60) and apply all levels in one operation. Record one automatic real mutation and ordered history entry per step, compute all sparse growth milestones, and update the correct final anatomy, collision and camera without repeated 34 skin reveals. Keep normal progression intact, debug-build-only gating, input guards and sensible E120 test limit. Add 11th CI regression and distinct APK package; verify on phone before merging. See [BATCH_DEBUG_EVOLUTION.md](BATCH_DEBUG_EVOLUTION.md).


## 2026-10-17 — E34 collision destruction and feeding feedback

Phone playtest screenshot at evolution 34 shows the giant above houses. Player reports giant cannot destroy buildings or cars and requests upright feeding with arms grabbing, plus an extendable tongue for greater reach. Branch `feature/giant-demolition-upright-feeding`: fix growth-stage mass demolition via X/Z contact on movement, scale vehicle/structure impact power without requiring Strength mutations. Animate paired forelimb grip instead of diving head, hand-to-mouth prey pull and visible tongue for upright targets beyond ordinary arm reach. Preserve four-legged controls/camera, mutations and free DEBUG EVO. Add a tenth headless regression and separate Android package; await physical phone test and visual acceptance. See [GIANT_FEEDING.md](GIANT_FEEDING.md).


## 2026-10-17 — extend suburbs, shopping districts, cars and free debug evolution

Player confirmed the first suburb works. This experimental stacked branch `feature/expanded-suburb-shops-cars-debug` extends the same world with two extra residential rows, 12 small shops and two large stores, connected streets and vehicle parking. Adds capped moving and parked physical cars with smash/driver-release, local people and police. A debug-build-only right-hand **DEBUG EVO** button and F6 keyboard equivalent allow fast mutation selection without feeding, with original history, skin reveal and growth milestones preserved. Isolates a separate APK package and immutable release from the approved build; nine mandatory Godot tests plus Android packaging checks. See [SHOPPING_CARS_DEBUG.md](SHOPPING_CARS_DEBUG.md). Android play feel, visual approval and device performance remain acceptance gates.


## 2026-10-17 — player-approved long beach, cocoon and neighbourhood preview

Player confirmed the extended beach works and requested a stronger cocoon, faster evolution, and the next section. On isolated `feature/cocoon-evolution-coastal-suburb`, add Reinforced Cocoon and Rapid Metamorphosis as evolution mutations with tiered art, capped seven-card portrait selection, stronger damage interruption tolerance and reduced vulnerable evolution timer. Preserve original pause, reveal, bite, movement and camera. Build Banksia Heights directly inland, 18 solid destructible homes, connecting streets, local food replenishment and police response. Add full regression + isolated Android publishing gates, leave long beach preview intact. Details and physical-phone acceptance in [SUBURB_EVOLUTION.md](SUBURB_EVOLUTION.md).


## 2026-10-17 — longer beach and sustainable prey candidate

Player approved the coastal art preview but ran out of people and room. On isolated `feature/extended-coast-population`, extend the horizontal game space from approximately 140 to 1,096 playable units within a continuous 1,120-unit coastline; preserve the six original buildings and add 30 destructible destinations across six new districts. Add bounded nearby crowd replenishment, local shelters and police response so exploration no longer strands prey or threats in the original centre. Preserve camera, touch controls, sprint and mutation/gameplay baseline. Introduce a new long-beach headless regression, full CI gate, and independently installable Android package and immutable preview release. See [LONG_BEACH.md](LONG_BEACH.md). This entry documents the candidate, not physical-device acceptance; the CI outcome must be checked before shipping.


## 2026-10-16 — creature/evolution takeover candidate

Source: PR #6 `457d228`, including draft stylised PR #5. Approved baseline retained at `0f82ff9` (Godot 4.5 Android run 56 / mobile-preview-godot45). PR #4 remains rejected. Repository branches, all PRs, workflows, releases, source/tests and development history inspected through Git and GitHub API. Both current drafts had green CI before this work; no drafts merged.

### Implemented

- Scale automatic feeding reach with body size; support horizontal reach of raised jaws without changing hatchling cone/rewards/slowdown.
- Counter-rotate the neck after torso posture; sample the upright snout collider after head rotations. Preserve neck posture during later evolution vulnerability/selection/reveal.
- Add knee/ankle pivots without moving quadruped rest meshes. Level-22 shoulders articulate independently; hind knees and ankles support a level-paw stance. Strength claws stay attached to the articulated paw.
- Set new form before the paused reveal; ease only the camera while the game remains paused.
- Test new body/head shapes after a growth milestone and relocate out of new wall overlaps using a bounded local clearance search. Preserve swept movement/building damage logic.
- Preserve camera view direction through shared vertical framing, extend far plane with size, retaining FOV/control mapping.
- Reuse immutable palette materials instead of allocating one material per coloured part. Shed materials remain private overrides. Draw-call reduction and phone performance are not claimed.
- Add behavioural growth integration regression, run the full suite in beach CI and gate APK export on it. Publish immutable candidate tags with SHA256, exact commit/run and a separate installable preview package. Stable release paths are untouched.
- Document current game in README, add current handover and progression contract; preserve original game/history.

### Validation before candidate publication

Official Godot `4.5.stable.official.876b29033` on Windows. Approved baseline imports, launches for 60 physics frames and passes its evolution and combat tests. Unmodified PR #6 imports/launches and passes its four original tests. New integration regression fails on unmodified PR #6: larger quadruped cannot feed at scaled snout.

Candidate imports and passes five tests: evolution, combat, stylised composition, growth milestones and growth gameplay. Actual OpenGL Compatibility renders inspected at levels 0, 6, 16, 22 and 46 at 540×960. Before fix, L22 snout forward had y≈0.86 (skyward) and L46 distance≈269 exceeded far=230. After fix, L22 forward is nearly horizontal and L46 fits an expanded far plane. Desktop screenshot checks are not phone visual approval.

Local editor reports Android SDK build-tools unavailable; Android export uses the repository's matched Godot 4.5/SDK35 GitHub runner instead of the locally installed Godot 4.6. No connected phone has been tested.

### Measured shed-rendering follow-up

The first published candidate (Android build 83, source `e0a07ae`) passed both push and PR workflows, including signature/package/native alignment. A subsequent desktop stress probe found ~163 scene draw calls without skins versus 708 with five skins. Finished remnants now bake the complete old geometry into one pale surface while cracks/fragments remain separate. On the same RTX 3050 Compatibility setup the resulting five-skin scene used ~286 draw calls (roughly 60% fewer than 708) and static engine memory ~43.96 MiB versus ~48.35 MiB before baking. These small desktop probes are not Android FPS, GPU memory or sustained frame-time measurements; procedural world randomness can change base counts slightly. Construction still has a one-off cost and must be profiled on device.

`test_evolution.gd` now checks that the baked mesh retains the old form's complete vertex count, live palette colours remain unchanged, and the static remnant fades and expires. Reproduce draw-call/memory inspection using `godot --path . --script res://scripts/ci/profile_shed_rendering.gd` with a real renderer; headless results are not useful for this probe. A new candidate rebuild follows this measured optimisation.

### Final candidate verification

Published Android **85**, source `afb0c7ee8508f5331b5220fa6868679355f58672`, [Actions success](https://github.com/kavemankai/Kaijustomp/actions/runs/38907095501), [immutable release](https://github.com/kavemankai/Kaijustomp/releases/tag/creature-evolution-85-afb0c7e). PR Android run 86 and both full smoke runs 73/74 also pass. Signed v2/v3 ARM64 APK, package `com.kavemankai.kaijustomp.creaturepreview`, version code 85, 27,759,053 bytes. Published download independently passes ZIP CRC, required game-resource and native ELF alignment checks; SHA256 matches CI/GitHub asset digest: `139fda738b4b16e81ace7dfb37447de304fb475dc9f8585dce739291fc8702ab`.

All implementation changes are committed and pushed. PR #7 stays draft; #5/#6 stay draft and unmerged. Stable release digest remains preserved. Final handover/test report and downloaded APK are copied to the user-facing outputs directory. Subsequent final verification documentation changes do not alter APK code. No Android installation/performance or player visual approval is claimed.

### Next actions

1. Completed: inspected green candidate Actions checks and independently verified published APK/checksum.
2. Phone install and natural L0–6 playtest beside the preserved approved app; judge responsiveness, visible mutations and one growth event.
3. Judge L22 silhouette/stance/feeding from the actual portrait camera. Refine production gait only with feedback; no automatic draft merge.
4. Profile Android frame pacing, memory and five-shed stress before claiming performance parity. Extreme size and finite beach boundaries remain a known limit.


## 2026-10-17 - Sculpted coastal art candidate

Implemented the accepted art direction on `feature/sculpted-coastal-art`, based on the creature/growth takeover candidate. Added editable Blender masters, GLB export source, two skinned forms, visual adapter with planted stride and downward feeding, bounded cumulative mutation appearances, coastal architecture/props/shoreline, ground shadows, quality choices, compact HUD and anatomical cards. Added pooled dust/impact effects and consolidated completed skin fragments.

Updated the old mesh-count tests to validate real asset/rig contracts, appearance bounds, deformed snapshots and foot planting. Added coastal-art regression coverage and repeatable engine capture/showcase scripts. Android CI consumes exported GLBs and publishes only an isolated `com.kavemankai.kaijustomp.artpreview` prerelease. Stable release and previous draft branches remain untouched. See ART_DIRECTION.md for pipeline, rendering budgets and outstanding physical Android/player acceptance.
