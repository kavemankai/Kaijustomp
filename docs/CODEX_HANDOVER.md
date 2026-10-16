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
