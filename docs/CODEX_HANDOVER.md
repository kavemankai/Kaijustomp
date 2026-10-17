# Kaijustomp integration handover — 17 October 2026

## Candidate to review

**[Draft PR #17](https://github.com/kavemankai/Kaijustomp/pull/17)**, branch **`integration/stable-baseline`**, targets `feature/outer-district-offscreen-defcon`. Gameplay/build source: **[`317743c00894de06150c0e7eef65db298206d8a2`](https://github.com/kavemankai/Kaijustomp/commit/317743c00894de06150c0e7eef65db298206d8a2)**. A subsequent documentation-only commit records these results; the APK source remains that exact SHA.

**[Download integration APK #217](https://github.com/kavemankai/Kaijustomp/releases/download/integration-217-317743c/Kaijustomp-217-317743c-debug.apk)** · [immutable prerelease](https://github.com/kavemankai/Kaijustomp/releases/tag/integration-217-317743c) · [successful build/publishing run](https://github.com/kavemankai/Kaijustomp/actions/runs/38997344851).

Package **`com.kavemankai.kaijustomp.integrationpreview`**, label **Kaijustomp Integration Preview**, version **`0.1.217-debug`**, ARM64, **27,997,583 bytes**. SHA-256: `f8a73cbb053306fb28e4bb4e563d7ad7ce2b6d6e7f5e590b11dca88efdc97578`. Downloaded release bytes match the published digest; local ZIP CRC and native alignment checks pass. CI verifies one signer with APK v2/v3 signatures, launcher, package and architecture. This is a debug candidate, awaiting phone acceptance.

## What changed and why

- Fixed sustained helicopter descent by keeping pursuit horizontal, and prevented hatchlings swallowing APCs/aircraft through the human feeding path.
- Kept distant offscreen reinforcements alive until they approach; retained normal retirement after arrival. Ground spawns/steering now account for a rotated APC hull.
- Capped all active civilian spawning at 42, preserving surplus building/driver evacuees in compact pending records. Available slots release evacuees before ambient refill, without dropping occupants or altering one-time demolition biomass.
- Extended physical growth-clearance search with creature scale and world bounds; the old 16-unit search failed the warehouse stress case. Moving animation now requires actual travel. Focus loss/background notifications clear held joystick/sprint intent.
- Extracted `ProjectileSystem` ownership (records, visuals, shared meshes/materials, swept hits and expiry) and `CivilianEvacuations` scheduling. Scene adapters preserve tests and explicit pause/evolution gates. The remaining controller is still 1,936 lines; this is an incremental extraction, not a finished rewrite.
- Batched 141 coast markings into ten spatial chunks. Startup nodes fall from 2,196 to 2,076; industrial-view draw/primitive counts remain identical at all nine sizes. Startup timing did not improve in the sample. No Android FPS claim.
- Unified local/CI test discovery, timeouts, error detection, logs and JSON results. Tracked Godot script/shader UID sidecars, declared 4.5, isolated the default Android export ID and added immutable integration prereleases.

See [technical audit](TECHNICAL_AUDIT.md), [architecture](ARCHITECTURE.md), [build instructions](BUILDING.md), [performance/animation evidence](PERFORMANCE.md), [development log](DEVELOPMENT_LOG.md) and [ranked roadmap](ROADMAP.md).

## What was verified

The unchanged PR #16 head `a4fb5fde47bcc6b1d5561e4d6dfa28ba5e7e02a7` passed **14 original suites** under official Godot **4.5.stable.official.876b29033**. New tests reproduced three missing lifecycle/diet defects before fixes and the old industrial clearance failure at all nine sizes.

The integration passes **16/16 suites**, import and 60-frame main-scene launch on Windows and Linux. The original 14 test scripts are unchanged. New tests cover sustained flight, vehicle prey exclusion, conserved/bounded evacuation/refill, arrival/retirement, real joystick events and focus notification, projectile pause/expiry/node cleanup, and E0/E5/E16/E22/E28/E34/E55/E80/E120 body scale, industrial clearance, planted skin feet, stance travel and two portrait ratios. Existing tests still cover evolution/reveal, movement/collision, feeding transitions, vehicle/building destruction and one-time rewards, DEFCON waves/projectiles/cover, DEBUG EVO and connected traversal.

All source workflows are green: [push smoke #143](https://github.com/kavemankai/Kaijustomp/actions/runs/38997344868), [PR smoke #144](https://github.com/kavemankai/Kaijustomp/actions/runs/38997364487), [push Android #217](https://github.com/kavemankai/Kaijustomp/actions/runs/38997344851), [PR Android #218](https://github.com/kavemankai/Kaijustomp/actions/runs/38997364693). The PR export is an artifact; #217 is the linked immutable phone candidate. Original `MainGame.tscn` also launches for 60 frames locally without errors.

[Committed validation evidence](validation/) contains Windows baseline/final JSON, Linux CI results and export evidence, desktop probes and original clearance reproduction. Local `build/final/` retains full logs and `build/integration-captures/` contains nine actual desktop renders. E22/E120 images were visually inspected. Desktop results do not establish phone performance or artistic approval.

## What remains unverified on Android

No physical phone is connected. Verify this APK beside approved DEFCON #189, preserving its installation. Test simultaneous joystick/sprint, background/resume and finger release, natural feeding and evolution interruption/choice/reveal, continuous travel through industry, offscreen arrivals and combat. Use DEBUG EVO for all nine representative sizes, especially E28→E34 diet transition and E55/E80/E120 collision, turns and stride presentation. Run 15 minutes with maximum response, heavy demolition and five skin remnants; record device/OS, frame-time percentiles, memory and thermals. Detailed static captures cannot approve walking motion.

The local machine lacks Android SDK and matching 4.5 Android templates, so **CI performed the actual export**, using JDK17/SDK35/matching Godot4.5 templates. This blocker did not prevent APK delivery. [BUILDING.md](BUILDING.md) gives exact local provisioning/export and CI recovery commands. No missing repository credentials remain; Git transport and the connected GitHub app worked, although the standalone `gh` CLI is not signed in locally.

## Remaining bugs and risks

No known critical crash remains in verified paths; all high-priority audit findings are addressed. Remaining medium risks:

- Responder side-step steering is heuristic, not full pathfinding. A distant arrival may stall behind a warehouse and occupy the nine-unit cap. Pursuit routing/lifecycle extraction is the next technical step after acceptance.
- E80/E120 hip/knee interpolation has no rigid reach constraint or planted-turn solver. Stance travel is tested, but swing stretch, sliding in turns, weight transfer and very slow giant cadence still require motion/art review. Early rig, proportions, speeds and camera angle are preserved.
- All 114 structures and static colliders remain resident. Evidence does not yet justify region unloading/collision deactivation; such a change risks seams, lost cover and duplicate rewards. Collect device traces first.
- Growth relocation uses a bounded radial search and can visibly reposition a giant. Impossible clearance still warns. Dense evacuation deliberately changes pacing through throttled release. E120 camera coverage exposes map edges and empty backdrop; no new world expansion was added.
- The scene still owns many dictionary contracts, input/evolution/world/combat responsibilities. Further extraction should remain small, behaviour-tested changes; do not import incompatible legacy managers.

## Preserved baseline and next milestone

PR #16 stays draft and unmerged. `main` is still `b7ff79d0efcbc4edff8890ba7e9016e34f6f3c97`; it is not this game. All earlier draft refs, tags, approved release assets and original art remain preserved. No new districts or enemy types, approved APK replacement or automatic merge was performed.

Local backups in ignored `build/preserved/` match the published digests:

- [Approved DEFCON #189](https://github.com/kavemankai/Kaijustomp/releases/tag/defcon-189-4bb8021), source `4bb80213bfbb4296a14e9a0d219ab42887608f2e`, 27,967,356 bytes, SHA-256 `b5e76128afd4fae74bea108d10395ea6e81d68937fe2bf9178527d4a499cb8c7`.
- [Outer-world #214](https://github.com/kavemankai/Kaijustomp/releases/tag/outer-world-214-a4fb5fd), source `a4fb5fde47bcc6b1d5561e4d6dfa28ba5e7e02a7`, 27,979,837 bytes, SHA-256 `4a23f99dfe3275c94da89520af89d792336222baac1b9bc4a22e7203e4fc60aa`.

**Next milestone: phone acceptance and measured performance of this consolidation candidate**, followed by reliable responder routing/owned enemy lifecycle. Then target measured Android bottlenecks and giant gait quality before combat feedback, progression or content. [ROADMAP.md](ROADMAP.md) ranks player value, dependencies, implementation risk and acceptance conditions. Continue on this integration branch; do not merge it or the existing stack automatically.

---

# Historical handover records (superseded by integration status above)

# Current art candidate - 2026-10-17

Work continues on `feature/sculpted-coastal-art`, based on the takeover branch below. Read [ART_DIRECTION.md](ART_DIRECTION.md) first for the current assets, runtime adapter, mutation appearance rules, test coverage and phone acceptance limits. Both `.blend` masters and exported `.glb` assets are tracked. Do not switch back to the primitive assembly or use renderer-count minimums as an art test. The stable release is not an art candidate and must remain unchanged.

# Kaijustomp takeover — 16 October 2026

## Current verified candidate

**Android build 85**, gameplay/export source **`afb0c7ee8508f5331b5220fa6868679355f58672`**, branch `feature/creature-growth-takeover`, draft [PR #7](https://github.com/kavemankai/Kaijustomp/pull/7) based on draft #6. [Direct APK](https://github.com/kavemankai/Kaijustomp/releases/download/creature-evolution-85-afb0c7e/Kaijustomp-85-afb0c7e-debug.apk), [release](https://github.com/kavemankai/Kaijustomp/releases/tag/creature-evolution-85-afb0c7e), [successful publishing run](https://github.com/kavemankai/Kaijustomp/actions/runs/38907095501). Package `com.kavemankai.kaijustomp.creaturepreview`, version `0.1.85-debug`, ARM64, 27,759,053 bytes. Separate application label: **Kaijustomp Creature Preview**. Approved app remains installed separately.

SHA256: `139fda738b4b16e81ace7dfb37447de304fb475dc9f8585dce739291fc8702ab`. Downloaded published APK independently matches GitHub asset digest and CI checksum, passes every ZIP CRC and ARM64 ELF 16 KiB check. CI `apksigner` verifies v2 and v3 signatures, one signer; `aapt` confirms package/version/launcher/ARM64. Local Android export was not attempted without SDK; CI performed the actual export using matched Godot 4.5 and SDK35.

Both push and PR workflows are green for this source: Android publishing run 85, PR Android run 86, push smoke 73 and PR smoke 74. All five regressions pass on Windows and Linux; 60-frame beach and original-scene launches pass locally. Full rendered portrait checks include actual mutation selections advanced to L0/6/16/22/46; vulnerability wait is skipped by the QA harness, so these images do not establish levelling speed. Camera/frustum tests cover 9:16 and 20:9. Phone installation, actual visual approval, sustained frame pacing/memory and thermal behaviour remain **unverified**.

Final verification documentation is a later documentation-only commit; APK source remains the exact SHA above. No draft merged. Stable assets were not replaced; approved run-56 APK has a separate preserved copy with SHA256 `0daadb9d78134d1174cf35239a42be253f9b730c79782bc0f5bf456a820dcedf`.

Next: install build 85 alongside the approved app and play naturally through L6; compare movement/steering while feeding, sprint full-recharge lock, wall/snout collision, police projectile damage, evolution interruption and one growth event. Review L22 posture and ground-prey presentation, especially repeated mutation details crowding the silhouette. Profile five skins on Android before asserting performance parity. Upright rig is still a procedural foundation; it needs final authored motion and phone judgement.

## Assessment before implementation

Repository fully cloned with all six remote branches and history. No AGENTS.md present. The remote default is the old `claude/new-session-xzf17f` branch; it is not the current beach game. Work starts from PR #6 head `457d228d85bdba0d7200d81bab755855a4643036`, which includes PR #5. Both remain drafts. PR #4 is closed and rejected; none of its creature code is being adopted.

Approved gameplay baseline: `feature/beach-demo-elevated-camera` at `0f82ff94fd6caebb04dee94bc9d1996a0494afd4`, per owner feedback. The preserved `mobile-preview-godot45` release identifies that commit and Android run 56. Its APK has been downloaded separately for preservation. The release tag itself is not reliable evidence of the asset's source commit; use its release notes. Latest inspected growth Android run 82 and PR smoke run 70 succeeded for `457d228`; colour preview run 75 succeeded for `916a7bf`. Other open drafts are #1 and #3. Workflows are Android APK and beach smoke. Do not merge drafts or replace stable assets.

All existing tests pass locally with official Godot 4.5, plus import and 60-frame beach launch. Actual Compatibility/OpenGL renders at 540×960 exposed gaps: L22 head forward vector points ~60 degrees upward, head collision is sampled before final head rotations, feeding range stays 2.85 at every size, and L46 camera distance ~269 exceeds fixed far=230. Growth also enlarges shapes without checking wall overlap. Existing growth tests assert torso pitch and parent names, not usable feeding, clearance or projection. Early cadence itself is correct: exactly one increase by L6.

## Prioritised implementation plan

1. Preserve early movement/sprint/combat contract; add behavioural regressions for growth, feeding, collision and camera failures.
2. Correct independent head/forelimb orientation and add articulated lower limbs for an expandable upright stance. Keep the quadruped rest layout intact.
3. Synchronise pose/colliders during the paused reveal, scale feeding reach and handle growth clearance. Preserve the established camera angle and support larger clipping distances.
4. Run full Godot suite and rendered portrait checks; build a uniquely identified experimental APK through GitHub Actions with signature/package/alignment verification.
5. Record exact source/build, evidence, limitations and phone checklist. No city expansion or new mechanics.

## Architecture and limitations

`BeachDemo.gd` owns gameplay/input/physics/UI; `StylizedCreatureArt.gd` owns procedural art; `GrowthProgression.gd` owns sparse milestone policy; `EvolutionShedding.gd` snapshots and reveals the old form. Original auto-shooter remains separate in MainGame.tscn. Beach script is large and should be extracted incrementally after regressions, not rewritten. Per-part geometry and duplicated shed meshes need real Android draw-call/memory profiling. Desktop GPU measurements cannot establish phone performance. The upright rig remains a procedural prototype, not final production animation. Art acceptance, installation and sustained phone play remain human/device gates.

Finished skins now bake their original geometry into one pale surface after the reveal, retaining cracks/fragments separately. Desktop five-skin draw calls fell from ~708 to ~286; phone costs and one-time baking spikes still require measurement. The active reveal retains original articulated snapshots and private materials. The full evolution regression checks geometry count, colour isolation and remnant fade/expiry.
