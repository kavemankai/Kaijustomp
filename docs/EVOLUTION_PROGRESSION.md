# Evolution progression

Current art candidate: the imported 19-bone quad/upright meshes and bounded mutation tiers are documented in [ART_DIRECTION.md](ART_DIRECTION.md). The adapter preserves the progression policy below. Supporting feet use a distance-driven stance/swing solve; upright feeding now reaches down with collision sampled from the final head pose. Previous references to a procedural rig describe the gameplay pivots, which now drive the skinned assets.

Godot 4.5 beach prototype. Mutation level counts completed evolution choices, starting at zero. Costs remain `55 + 25 * completed_evolutions`. One mutation per completed choice; surplus biomass carries over. Health, armour, speed, stamina, jaw, strength and regeneration remain cumulative. Damage interruptions never remove prior mutations.

| Level | Relative growth | Cumulative size | Form |
| --- | --- | --- | --- |
| 0–4 | none | 1.000000 | Quadruped |
| 5–9 | ×1.20 at 5 | 1.200000 | Quadruped |
| 10–15 | ×1.24 at 10 | 1.488000 | Quadruped |
| 16–21 | ×1.28 at 16 | 1.904640 | Heavy quadruped |
| 22–27 | ×1.32 at 22 | 2.514125 | Upright prototype |
| 28–33 | ×1.24 at 28 | 3.117515 | Upright prototype |
| 34–39 | ×1.20 at 34 | 3.741018 | Upright prototype |
| 40, 46, 52… | ×1.16 every six | previous ×1.16 | Upright prototype |

At L6 there is exactly **one** physical increase. `GrowthProgression.gd` is the policy source; `_apply_growth_milestone` applies size separately from mutation stats. Default growth remains automatic. Optional growth/NG+ is intentionally not exposed yet; a future policy can decide whether to apply a milestone without removing stat progression. Stored history currently describes default policy, not a future optional-growth decision.

## Physical and visual integration

- Uniform visual size and world-space body/head shapes scale together. Head collider is sampled after the complete upright head/bite transform. Hatchling collision dimensions and movement/sprint/feeding slowdown constants remain as approved.
- Feeding keeps the original horizontal forward cone. Quadruped reach scales from 2.85; upright reach also accommodates the raised muzzle's horizontal footprint. Ground prey is drawn into the articulated jaw as before. This is a prototype grab presentation; a fully authored downward attack remains future animation work.
- The L22 torso raises around the pelvis, neck counter-rotates to face forward, shoulders compensate independently, and articulated hind knees/ankles keep supporting paws level. Hind legs alternate; forelimbs use a reduced swing. This is an expandable procedural rig, **not** final production biped animation or a substitute for player approval.
- Growth settles the new posture before the paused reveal. The camera may ease during reveal; AI, damage and player motion remain stopped. Later non-growth evolution preserves neck compensation.
- Growth runs a bounded shape-clearance query at the current position and, only if overlapping, searches nearby space in half-unit rings up to 16 units. It excludes the player, respects beach movement bounds and never destroys buildings to make room. The old shell remains at the original evolution position. A warning records failure to find space. Extreme future sizes can outgrow this finite beach; unlimited-scale world streaming/clearance is not implemented.
- Camera offset and look target share the same height translation, preserving the approved angle. Far distance expands with size. This prevents the L46 self-clipping defect; it does not provide a large streamed world.

## Required validation

Run import, 60-frame launch and all five `scripts/ci/test_*.gd` scripts with Godot 4.5. `test_growth_gameplay.gd` covers actual choices through L6, cumulative stats, shed cap, scaled feeding, paused L22 pose, current-frame head geometry, later non-growth reveal, cafe clearance and swept collision, L46 portrait framing at 9:16 and 20:9, hind stance, sprint recharge and fresh scene state. The new test fails on unmodified PR #6 at scaled feeding.

Phone acceptance: play naturally through six choices, compare responsive movement and exhaustion to approved APK, inspect each mutation and shed, push against buildings while feeding/evolving, and inspect L22 posture, ground prey pickup and attack readability. Record Android model/OS/page size, sustained FPS/frame-time distribution, memory, thermal behaviour and five-shed stress. Automated level injection/rendering does not validate real levelling pace or device performance.
