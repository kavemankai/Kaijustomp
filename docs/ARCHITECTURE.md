# Persistent world architecture — current candidate

Godot4.5 Compatibility, ARM64 Android portrait540x960. The same BeachDemo scene and touch controls remain the active runtime. World expansion does not load a replacement gameplay scene.

| Owner | Responsibility |
| --- | --- |
| WorldConfiguration / config/world.tres | Finite width, inland depth and default seed; saves retain their own seed. |
| WorldLayout | Pure district/parcel/road descriptions from generator version, seed and world coordinates. |
| WorldStreaming | Chunk queues, frustum/safety relevance, collision preparation, silhouette batches, generated slot reuse and save orchestration. Gameplay respects pause gates; static camera prefetch also runs during evolution pauses. |
| WorldState | Compact object/event/player deltas, validated versioned JSON, previous-good backup and migration/recovery. |
| WorldSaveWriter | Detached immutable snapshots, one worker and one coalesced pending job; disk I/O off gameplay, explicit pause/exit/reset flush. |
| WorldObjectives / ObjectiveHUD | Concurrent persistent goals/one-time Renown and portrait tracking/selection; objective view pauses gameplay while static streaming continues. |
| WorldLandmarks | Additive identity metadata/art on existing stable parcels; deterministic seed-based destinations. |
| WorldRouting | Hull-aware local grid routes calculated from static descriptions; no full simulation along distant approaches. |
| BeachDemo | Creature/evolution/input/HUD, damage/reward transactions and bounded local actor orchestration. Active building nodes have explicit construction/destruction helpers. |

The114 authored metadata records retain their indices for compatibility, even while their nodes are inactive. Generated slots are recycled after unloading. Every structure has a stable ID; civilian shelter IDs resolve at use rather than retaining recycled generated indices. Node/collider references may be null on inactive objects and must be checked before use. Destruction marks a tombstone and reward claim; unload saves meaningful deltas before releasing nodes. Persistent state never owns scene nodes.

Near collision regions account for physical creature dimensions, movement sweeps, growth queries, projectiles, responders and a64-unit structure-owner margin. Middle/far visuals use the same deterministic footprints and heights. Background land/ocean/ridges remain a handful of static surfaces; no distant actors or colliders are retained for that backdrop. Camera near clipping scales at giant sizes to preserve depth precision; orientation and control mapping remain unchanged.

Pause/evolution contracts and ProjectileSystem/CivilianEvacuations ownership remain as described below. Explicit collision preparation runs before physics queries; normal simulation remains gated during choice/reveal. Autosaving defers incomplete evolution transactions. RESTART starts a fresh run; application relaunch restores a valid save.

The prior architecture record below remains useful for unchanged creature, projectile, evacuation and input systems; its permanently resident world statements are superseded by this section.

---

# Kaijustomp development architecture

## Active runtime

Godot 4.5 Compatibility; Android portrait 540×960 logical viewport, canvas scaling, ARM64. `project.godot` starts `scenes/BeachDemo.tscn`. Its root constructs the scene in `_ready`; no autoload manager or second world scene is involved. Beach/suburb/shops/industry are contiguous coordinates, with 114 stable building records. The original `MainGame.tscn` auto-shooter is preserved separately; its progression, city manager and large simulation pools are historical, not beach dependencies.

| Owner | Responsibility and lifetime |
| --- | --- |
| `BeachDemo` | Gameplay orchestration, shared creature state, world layout, movement/contact damage, evolution transaction, civilian/vehicle/responder dictionaries, camera and input/HUD binding. Still intentionally substantial. |
| `ProjectileSystem` (child node) | Owns up to 72 projectile records and tracer child nodes, shared light/heavy meshes/materials, swept physics queries and expiry. Emits `target_hit(damage)`; does not mutate creature state. |
| `CivilianEvacuations` (scene-owned RefCounted) | Owns pending collapse/driver evacuation records. Drains capacity through a caller-supplied spawn callback. Active crowd is limited to 42; no occupants are thrown away to enforce the limit. At most one event per destroyed building/car. |
| `DefconDirector` | Stateless thresholds, wave composition, stats, intervals and caps. Enemy navigation/attack lifecycle remains in the scene. |
| `GrowthProgression`, `DietProgression` | Deterministic milestone/scale/form and prey/reward policy. |
| `EvolutionShedding` (child node) | Snapshot materials/geometry, reveal animation, five bounded remnants, fade and expiry. May process while selection/reveal pauses gameplay. |
| `CreatureVisual` | Loads two GLB forms, maps pivot transforms into skeletons, solves procedural stance and creates posed snapshots. Rig/art asset contract is unchanged. |
| `StylizedCreatureArt`, `MutationIcons` | Pivot rig construction, bounded cumulative mutation geometry and UI icons. |
| `CoastalArt`, `CoastalEffects` | Batched static/actor art, shared palettes, shadows and 40 reusable effect particles. Physics remains owned by gameplay. |
| `CoastalHUD`, `MobileTouchController` | HUD drawing and joystick event interpretation. Scene owns touch targets and state transitions. |

## Frame and pause contract

The scene root processes always so it can update UI/camera during paused evolution. `_physics_process` explicitly returns during game-over or choice, and only updates the camera during reveal. During vulnerable evolution it advances enemies/projectiles/debris but not player movement or ambient NPCs. Otherwise it advances movement, feeding, civilians, cars and population first, then combat/debris/camera/HUD. `ProjectileSystem` has no automatic tick: `advance` is called only through that gate. Do not enable its independent physics processing without reproducing pause tests.

Movement uses swept body collision and a slide, followed by a giant X/Z contact attack. Gait phase comes from actual distance / scaled stride; the moving pose also requires actual travel. Growing updates visuals, torso, head pose and body shapes, then searches outward for a clear physical position. The outward search is body-scaled and bounded to 64 rings × 16 directions; if no clearance exists it warns rather than deleting structures or awarding damage.

Application focus loss/pause clears joystick state, scene movement and sprint intent. This prevents stale finger state on Android resume. It does not add a new user-facing pause menu.

## Ownership invariants

- Building/car arrays retain tombstones after destruction so prior indices remain meaningful; do not access their freed node/collider references unless `destroyed` is false.
- Officer/civilian/projectile/debris arrays remove expired records. Free scene nodes with their owner; never clear an array as a substitute for releasing its nodes.
- `BeachDemo.projectiles` is a compatibility getter into `ProjectileSystem.shots`, not a second collection. Scene wrappers retain the existing test/caller contract.
- Infantry can be grabbed; emergency vehicles cannot enter human feeding. Vehicle combat and giant stomps remain available.
- New distant responders carry `arriving` until entering the retirement radius. After arriving they can retire normally when the player leaves. Ground checks use a conservative 3.5-unit APC clearance, and aircraft navigate horizontally at their spawned altitude.
- Evacuation slots are filled immediately when available; further evacuees are released in batches of five on population refresh before ambient newcomers. Gameplay balance is unchanged for small normal collapses; dense collapses are deliberately throttled.
- Shared tracer geometry/materials and static coastal palettes are immutable after construction. Shed snapshots own their colour overrides and do not recolour live creature assets.

## Next extraction boundary

Extract responder lifecycle/steering next, with explicit world-query and damage interfaces. Then move civilian spawning/panic and vehicle movement behind owned lifecycle systems. Move world authoring only after preserving all 114 positions, continuous roads and collision/reward contracts in tests. UI/camera extraction should keep portrait projections and input mapping exact. Avoid creating eleven empty managers or wrapping every helper in an abstract service; use the existing regression entry points as compatibility adapters until callers migrate.

Keep Godot-generated `.uid` sidecars tracked for stable script/shader identity across clean imports. Cache and build products remain ignored. See [BUILDING.md](BUILDING.md), [TECHNICAL_AUDIT.md](TECHNICAL_AUDIT.md) and [ROADMAP.md](ROADMAP.md).
