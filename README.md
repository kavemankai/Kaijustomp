# Kaijustomp integration candidate

Current branch: integration/stable-baseline, based on unmerged PR #16. Start with [handover](docs/CODEX_HANDOVER.md), [technical audit](docs/TECHNICAL_AUDIT.md), [architecture](docs/ARCHITECTURE.md) and [reproducible builds](docs/BUILDING.md). Godot 4.5 import, launch and all 16 gameplay suites gate the isolated Android integration preview. Existing releases and draft branches are preserved.

# Kaijustomp

Current playable game: **Godot 4.5 Compatibility, Android portrait beach/evolution prototype**. Begin with [takeover status](docs/CODEX_HANDOVER.md), [growth contract](docs/EVOLUTION_PROGRESSION.md), [development log](docs/DEVELOPMENT_LOG.md) and [beach controls](docs/BEACH_DEMO.md). Run `project.godot` / `scenes/BeachDemo.tscn`. WASD/arrows or left touch joystick move; Shift/right SPRINT toggles sprint; E/EVOLVE starts a vulnerable evolution when enough biomass is available. Feeding and structure attacks are automatic. Mutation selection and the shedding reveal pause gameplay.

The original auto-shooter below is preserved in `MainGame.tscn`; it is a historical system, not the current beach design.

## Original auto-shooter reference

Retro low-poly kaiju reverse auto-shooter for Godot 4 (mobile first). You are the kaiju. Tanks, mechs and helicopters converge on you, you auto-fire a bullet spiral, and you crush buildings by walking through them. Killed enemies drop G-cells. Collect them to level up and pick a mutation. When you die, spend banked G-cells on permanent upgrades in the lab.

The project has no binary assets. Meshes, the 256x256 texture atlas and all sound effects are generated in code at startup.

## Run

1. Install Godot 4.2 or newer (developed against 4.3).
2. Import `project.godot` and press F5.
3. Controls: WASD or arrows to move. Drag on the left half of a touch screen to move. Tap the right half for the Atomic Nova ring (5 second cooldown). On the level-up screen press 1, 2 or 3, or click a card. In the lab press Enter to start the next run. Mouse input emulates touch.

## Layout

| Path | Purpose |
| --- | --- |
| `scripts/core/SimulationManager.gd` | Flat-array pools for bullets, enemies, pickups and debris, drawn through `MultiMeshInstance3D`. Spatial hash collision. Three enemy types (tank, mech, flying helicopter), DEFCON escalation, G-cell pickups with magnet pull. Ground units ask the navmesh for a waypoint once every 16 frames. |
| `scripts/core/RetroMeshFactory.gd` | Vertex-coloured `ArrayMesh` builders for every model. UVs point into the shared atlas. |
| `scripts/core/RetroTextureAtlas.gd` | Generates the 256x256 pixel-art atlas (scales, windows, armour, plasma). |
| `scripts/core/RetroAudioBank.gd` | Synthesizes 22,050 Hz 16-bit sound effects and plays them from an 8-voice pool. |
| `scripts/core/ProgressionManager.gd` | G-cells, best score and lab ranks, saved to `user://kaiju_save.cfg`. |
| `scripts/core/SpatialHash3D.gd` | Uniform grid on the X/Z plane. |
| `scripts/world/DynamicCityManager.gd` | `GridMap` city with three building types, destruction, async navmesh rebake, reset on restart. |
| `scripts/player/KaijuPlayer.gd` | Movement, HP, XP and mutations, 10 degree FOV diorama camera, auto-fire, Atomic Nova, revive. |
| `scripts/ui/MutationAndLabUI.gd` | Level-up draft (pauses the game) and the post-run lab. |
| `scripts/ui/MobileTouchController.gd` | Virtual joystick and tap detection. |
| `shaders/ps1_retro_model.gdshader` | Vertex snapping, affine texture mapping, vertex lighting. |
| `shaders/ps1_postprocess.gdshader` | 15-bit colour, Bayer dithering, CRT curve and scanlines. |

## Settings that matter

The renderer is `gl_compatibility` for both desktop and mobile. ETC2/ASTC import is on. `run/max_fps` is 60. The navigation map cell size is 0.25, and the navmesh in `DynamicCityManager` has to match it or region updates are rejected. The first navmesh bake waits a process frame and a physics frame, because `GridMap` builds its colliders late.

G-cells are held in memory during a run. They are written to disk on death, on a lab purchase, when the app is paused and when the window closes.

## Known gaps

- Balance is untuned. In a 150 second run with the player circling and auto-picking mutations, the player took no damage at DEFCON 1 and killed about 4,700 enemies. Bullets travel about 48 units, so tanks die near their spawn ring before they reach you.
- Not profiled on a device. The simulation took 4.3 ms per frame headless on a desktop CPU. Pool sizes (2,500 bullets, 500 enemies per type bucket, 400 pickups, 400 debris) and about 31 `map_get_path` calls per frame are untested on phone hardware.
- Sound effects are checked only for building and playing without errors. Nobody has listened to them.
- `apex_pass_unlocked` doubles G-cell income but nothing sets it. The save file is a plain text `ConfigFile` that a player can edit.
- Bullets pass through buildings. Helicopters are hit by ground bullets because collision ignores height.
