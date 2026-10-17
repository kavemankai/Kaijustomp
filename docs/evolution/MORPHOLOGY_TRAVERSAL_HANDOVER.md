# Morphology and traversal engineering handover

**Development branch:** `feature/morphology-traversal-autonomous`, based directly on unmerged PR #19 (`feature/nine-form-genetics-preview`). Preserve PR #18, PR #19, the approved Android releases, the original genus/save contracts and the existing stable Android package. This is an **isolated experimental implementation**, not a production art-approval claim.

## Final verified candidate — 17 October 2026

**Install [Morphology & Traversal APK #253](https://github.com/kavemankai/Kaijustomp/releases/download/morph-traversal-253-27cb2e1/Kaijustomp-253-27cb2e1-debug.apk)**. Exact gameplay/export SHA **`27cb2e1f298b154fed6bf577aa00263a16dd817d`**, [immutable release](https://github.com/kavemankai/Kaijustomp/releases/tag/morph-traversal-253-27cb2e1), [successful Android run #253](https://github.com/kavemankai/Kaijustomp/actions/runs/39040926932), [draft PR #20](https://github.com/kavemankai/Kaijustomp/pull/20). Only this and earlier explicitly named sources were exported; subsequent handover-only commits do not change game content.

CI successfully imported Godot4.5, launched the beach scene, passed all **31 discovered regression suites**, and verified Android debug APK package, signature and native alignment before publishing the prerelease. Preview package `com.kavemankai.kaijustomp.morphtraversepreview`, Android ARM64, **28,300,878 bytes**. The preview installs alongside approved/Genetics/World packages, subject to signing compatibility for repeated updates of this experimental package. **No physical phone test, sustained frame-rate/temperature measurement or final art approval has been performed.**

The final patch also adds separate selectable **Glide** mode, mixed-lineage traversal selection in LINEAGE, safe roof landing, and resetting held altitude input when Android focus is lost. The debug-only QA selector deliberately enables quick direct experiments; ordinary progression still acquires the mutations through legal drafts. All six traversal gene IDs are real in-game upgrades, not just visuals.

## Source progression

- First independent package, **Morphology & Traversal Preview #249**: `2fe3c41ed344ecefd7e537ca2f39233ee40a8f75`, successful [Android run #249](https://github.com/kavemankai/Kaijustomp/actions/runs/39040110949) and [release](https://github.com/kavemankai/Kaijustomp/releases/tag/morph-traversal-249-2fe3c41). All 31 current test suites, Godot 4.5 import and main-scene launch, and APK signing/native packaging passed at that source.
- Later development commits add a debug-only form/hybrid/growth preview selector, true wall-top/rooftop interaction, stepped foundation checks, surface burrow cue, an actual sampled world-space axial collision proxy and restored Snake/Worm body history. Re-run CI and retain a separate immutable APK for the final source; do not treat run #249 as evidence for later commits.

## Active runtime and implementation

- `AnatomyManifest.gd`: named host-specific attachment frames and required anatomical sockets.
- `MutationExpressionLibrary.gd`: host-specific expression for all nine generic mutation families, with three increasing visible tiers. Early source-gene cues are moved to the active host's head, wings, flanks, dorsal surface or other suitable attachments.
- `CreatureMorphology.gd`: nine biological hosts, increasingly developed signature structures, animated Bird wings, deterministic recipe caching, active genotype/hybrid expressions. GLB fallback remains for untouched legacy saves.
- `BodyDimensionsPolicy.gd`: independent chosen length, width, height, radius, wingspan and scale metric. The Snake is about 5–80 world units long across 0–18 growth ranks; Worm is about 6–84. They remain horizontal, not mandatory bipeds.
- `AxialTrail.gd`: Nokia-Snake-style head-led sampled path. Reused visible sections and queryable `Area3D` collision proxies follow the actual head route. Saves and validates a bounded path history with the active genome.
- `CreatureTraversal.gd`: single active movement mode. Bird flight has actual altitude control, banking-oriented wing animation, obstacle sweeps and staged landing. Mole/Worm underground locomotion moves at depth through sampled foundation-safe waypoints, with a surface disturbance trace. Spider hooks permit contact-limited wall adhesion and genuine vertical movement; a roof probe can transition to a supported rooftop and unsupported edges fall to ground.
- `BeachDemo.gd`, `BeachGenetics.gd`, `GeneticsHUD.gd`: unchanged normal ground/input/combat ownership with contextual mode delegation; stitched save, cache, camera and streaming responsibilities.
- Six newly executable traversal source IDs: **29** (Gliding Patagium), **52** (Burrowing Fore-Claws), **119** (Sub-Terra Burrowing Shovel Head), **121** (True Flight Patagium), **122** (Soaring Thermal Wings), **180** (Arachnid Wall-Climbing Hooks). All 500 original catalog IDs remain retained, while the 35 original executable source mutations and nine generic upgrades still exist.

## Verification

Automated regression discovery is `python scripts/ci/run_regressions.py --godot <official Godot4.5>`; main scene `scenes/BeachDemo.tscn`. `scripts/ci/test_morphology_traversal.gd` exercises all nine host families, source/generic visible ranks, Snake/Worm body length and path following, powered flight and controlled landing, underground travel, physical-wall climbing and rooftop transitions (after the later roof additions). Other suites verify the original creature, save, lineage, world streaming, mission tracker, feeding, DEFCON and mobile inputs.

The new workflow creates a **separate Android test app**, `com.kavemankai.kaijustomp.morphtraversepreview`, and publishes a unique `morph-traversal-<run>-<sha>` prerelease only after Godot regressions, Android signature, package, ZIP and 16 KiB native verification pass. No existing APK is overwritten.

## How to test on Android

1. Install the latest *Morphology/Traversal Preview*, not an older Genetics Preview. Keep older packages installed for comparison. It has its own local save.
2. Open **LINEAGE** and the debug-only **QA PREVIEW** selector. Choose a primary form, optional secondary lineage and size rank (0–18). This replaces the preview's current creature and retains its world.
3. Test each of the nine at growth ranks 0, 6, 12 and 18; verify head, dorsal, forelimb, wing, shell, tail, segment and gland upgrades truly fit and visibly develop with ranks. Inspect across screen widths and camera headings.
4. Choose Snake: steer tight paths between structures and watch the full trail follow rather than pivoting as one capsule. At E18 verify the 80-unit body does not unload or pop when the head travels.
5. Choose Worm: its thick body should stay low and long. Tap **TRAVERSE** to burrow; travel below the surface, look for the disturbance trace, reject structural foundations and emerge where clear.
6. Choose Mole: burrow without going through buildings. Verify suspended autosave/resume, especially while buried.
7. Choose Bird: tap **TRAVERSE**, use **UP/DOWN** while flying, fly around roofs, then **LAND/EXIT**; confirm collisions and ground landing.
8. Choose Spider: approach a solid building wall, face it, tap **TRAVERSE**, climb up with **UP**, traverse supported rooftop areas and walk off to descend. Verify wall destruction causes a safe fall.
9. Test Reptile+Bird, Ape+Crab and Worm+Mole plus other selected mixed pairs. Make sure the body plan remains coherent; no duplicate hands/pincers or wing bones through shell.
10. Die after damaging buildings and completing objectives, press **NEW ORGANISM**, check that the world, missions and lineage history persist. Check app relaunch from a saved axial body and world/mission UI with touch.
11. Play 15+ minutes through dense structures, DEFCON response, giant growth, burrowing, flight and five shed remains. Record frame-time percentiles, memory, thermals, multi-touch and app background/resume on a physical phone.

## Known limitations requiring device/playtest feedback

- **Not final authored creature art.** The system now places upgrade parts on body-specific sockets and uses more distinct host silhouettes, but advanced organic seams, skin texture, full deformation and individually sculpted production-quality meshes are still an art pass.
- Air flight is bounded powered/glide motion, not a six-degree-of-freedom aircraft simulator. No streaming above 70 world units or physics-based aerodynamic stall model.
- Underground travel honours tracked structure footprints and a simple ground depth; it does **not** sculpt permanent tunnels, model variable rock strata or fully simulate subterranean structural collapse.
- Axial body sections are queryable physics areas following the head's sampled path; they are not a fully joint-simulated rigid-body chain or a self-collision-based Snake arcade failure condition.
- Rooftop ascent uses wall/top collider probes; arbitrary overhangs, non-convex surfaces, unusual geometry and all hybrid movement transitions need manual acceptance.
- The existing 500-source catalogue still contains concepts without a working execution hook. No claim of 500 playable genes.
- CI, scene scripts and desktop rendering do not establish physical Android controls, sustained FPS, thermal response, collision feel or final art approval.

## Next acceptance

Do not merge upstream before user device testing. Preserve this branch and the immutable preview release. Any issues found on phone should be reproduced with a short focused Godot test before another release.
