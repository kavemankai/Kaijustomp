# Technical audit — 17 October 2026

## Source and method

Integration begins at `a4fb5fde47bcc6b1d5561e4d6dfa28ba5e7e02a7`, PR #16's actual head, on `integration/stable-baseline`. PR #16 targets DEFCON commit `4bb80213bfbb4296a14e9a0d219ab42887608f2e` (approved build 189); outer-world build 214 has no phone approval. `main` and its merge base are `b7ff79d`, the original auto-shooter. The remote default is another old branch. Open drafts form the chain #1 → #3 → #5 → #6 → #7 → #8 → #9 → #10 → #11 → #12 → #13 → #14 → #15 → #16. Do not merge these branches independently as if they were unrelated features. All original refs, tags and release assets are preserved.

Inspected the tracked scene, gameplay, art, input, legacy simulation, regression, export and workflow sources. Godot **4.5.stable** on Windows imports and launches the unchanged candidate; **14/14** original gameplay suites pass (logs in ignored `build/baseline`). These tests establish reproducible behaviour, not Android acceptance. No AGENTS.md exists in this checkout.

## Findings

| Priority | Finding and evidence | Disposition |
| --- | --- | --- |
| High | `_update_police` pursues a ground point with a 3D vector, lowering helicopter altitude every approach frame; tests only check initial altitude and rotor rotation. | Reproduce over sustained pursuit; fix horizontal navigation. |
| High | `_update_biting` treats every officer dictionary as human prey, including APCs and aircraft, ignoring type and height. A hatchling can swallow an APC at human reach. | Add real responder feeding regression; restrict to infantry. |
| High | Building collapse spawns all `hidden` occupants synchronously, bypassing `MAX_ACTIVE_CIVILIANS`. Sheltering can accumulate occupants over a long run. Each civilian allocates art and updates/scans buildings. | Bound active actors, retain overflow evacuations for later release. |
| High | New branch names fall through Android export to the approved package identifier. Publishing is branch-gated, but a locally installed integration artifact could replace the approved application. | Give integration a distinct checked package in preset and workflow. |
| High | `_resolve_growth_clearance` searches only 16 world units even at E120; warehouses and creature radius can exceed that distance. | Add representative-scale physical overlap tests; expand search using actual body/world scale. |
| Medium | Offscreen spawn rings extend to 1460 units, but `_update_police` retires units beyond `max(175, scale*100)` before they approach. | Protect camera-safe arriving units from retirement; test persistent deployment. |
| Medium | Locomotion uses intended input for the moving pose while phase uses actual travel. Pushing a wall or boundary leaves moving foot planting active at a frozen phase. | Gate locomotion on actual displacement; preserve movement speed and earlier rig. |
| Medium | `BeachDemo.gd` is 1947 lines: world authoring, state, input, evolution, collision, damage, actor lifecycle, combat and UI. Arrays of dictionaries form implicit contracts with tests. | Incremental owned subsystem extraction, retaining compatibility entry points. |
| Medium | Android and smoke workflows duplicate explicit lists of 14 tests; new suites can silently be omitted. Import detection is separate and suite timeouts differ. | Shared discovery runner with version, timeouts, logs, error checks and JSON report. |
| Medium | Static coast road markings allocate independent meshes/materials; 114 buildings construct all three crack stages on startup. Far structures remain resident. | Measure scene counts/timing; batch homogeneous static road markings. Keep collision until measurements justify activation/unloading. |
| Medium | Ground responder spawn/navigation checks only a point with 0.7 margin, although APC hull is 3.3×6.0. Side-step steering can oscillate behind large industrial footprints. | Remains a navigation/clearance risk; no claim of complete pathfinding. |
| Medium | `_build_camera` sets far=4000 but `_update_camera` overwrites it with 230×scale. Current test checks startup only. | Document intended distance culling versus whole-world visibility; do not enlarge far plane blindly. |
| Medium | Touch input resets for evolution/debug but lacks application focus-loss reset. Lost release events can leave movement held after Android resume. | Add focus loss reset and input-event regression. |
| Low | Handover/APK docs lead with obsolete art/build-85 instructions despite PR #16; `project.godot` advertises 4.2, export comment says 4.3. | Replace current handover, preserve old history as historical references, declare matching engine. |

No verified critical crash is present in the initial import, launch or 14-suite baseline. High-priority defects are interaction/lifecycle failures that existing snapshots and count tests miss.

## Existing ownership and preserved behaviour

`BeachDemo.tscn` has one scripted root; most nodes are runtime-authored. `MainGame.tscn`/`scripts/core`, `player`, `world` implement the older auto-shooter and are not active beach systems. Reusing those managers would combine incompatible progression/combat models. Keep the legacy scene available without routing production beach gameplay through it.

Movement uses camera-relative touch/keys, swept `move_and_collide`, slide, sparse scaled body/head shapes, contact attacks and proximity giant stomps. Feeding uses a forward cone, scaled grab/tongue range, one held prey node and size-driven diet policy. `GrowthProgression`/`DietProgression` already separate policy; `EvolutionShedding` owns snapshots, paused reveal and five expiring remnants. DEBUG EVO duplicates mutation application logic; it is debug-gated and bounded to E120. Existing tests cover both paths. Retain their balance.

`CoastalArt` batches building/chunk geometry, shares vertex-colour materials and keeps art separate from collision. Both GLB forms remain loaded, with one shown; resource loads are engine-cached. `CreatureVisual` transfers pivot transforms into skeletons and procedurally plants feet; no authored root motion or terrain IK exists. Hip/knee placement remains approximate, particularly when giant limbs bend and the fixed world movement speed implies very slow stride cycles. Do not replace rig/art without review.

Buildings keep stable indices and destroyed tombstones; rewards are awarded once, then their scene nodes queue-free. Cars stop far from player; civilians refill locally; responders, shots, effects, debris and shed meshes already have partial caps/lifetimes. Projectiles use swept rays with building/vehicle cover. Paused selection/reveal is manually gated by the always-processing root. New subsystems must remain under that gate.

## Verification limits

Headless rendering counters cannot measure GPU performance. No Android device is connected and no on-phone FPS, memory, thermal, multi-touch or art approval is claimed. Desktop profiling, regression evidence, CI export evidence and remaining phone acceptance are recorded separately in the handover and performance report. Extreme giant animation still needs sustained phone and artistic review.

## Implementation disposition

All high-priority rows above are addressed in the integration candidate. The new stability suite reproduced sustained altitude loss, APC swallowing and a200-occupant allocation burst before fixes. It now also checks evacuation conservation/refill, arrival lifetime, focus reset and projectile pause/cleanup. `test_representative_scales.gd` fails the original industrial clearance stress case at all nine requested sizes and passes after the search correction; it also checks skin-foot stance/travel, physical size and portrait framing. All14 original suites remain unchanged and pass alongside these two new suites.

Projectile ownership and evacuation scheduling are extracted; the rest of the controller remains a documented incremental refactoring target. Distant arrivals now survive retirement checks, and APC spawn/steering margins cover a conservatively rotated hull. Full pathfinding remains deferred: a side-step heuristic may stall, occupying a responder slot. Ground/camera coverage and no-spawn fallbacks still need phone review.

Road markings are batched into bounded chunks and tracer resources shared. Final startup node count is2076 versus2196, with identical industrial-view rendered draw/primitive counts at all sizes; no Android performance claim is made. Both workflows use a single16-suite discovery runner, retain logs, and the integration export defaults to its separate install ID. See [ARCHITECTURE.md](ARCHITECTURE.md), [BUILDING.md](BUILDING.md), [PERFORMANCE.md](PERFORMANCE.md), [ROADMAP.md](ROADMAP.md) and the current handover for exact evidence and remaining work.
