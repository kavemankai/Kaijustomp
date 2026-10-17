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
