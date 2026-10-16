# Kaijustomp takeover — 16 October 2026

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
