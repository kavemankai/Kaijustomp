# Kaijustomp

Retro low-poly kaiju reverse auto-shooter for Godot 4 (mobile first). You are the kaiju. A horde of tanks paths through the city toward you, you auto-fire bullet patterns, and you crush buildings by walking through them. Tanks drain your HP on contact; at zero HP the game ends and a right tap or Enter restarts it.

The project needs no external assets. `MainGame.gd` builds the camera, lights, city, bullet and horde pools, post-processing and touch UI in code, and `RetroMeshFactory.gd` generates the low-poly meshes.

## Run

1. Install Godot 4.2 or newer (developed against 4.3).
2. Import `project.godot` and press F5.
3. Controls: WASD or arrows to move. Drag on the left half of a touch screen to move. Tap the right half for the Atomic Nova ring. Mouse input emulates touch.

## Layout

| Path | Purpose |
| --- | --- |
| `scripts/core/SimulationManager.gd` | Flat-array pools for bullets, enemies and debris, rendered through `MultiMeshInstance3D`. Spatial hash collision. Each enemy asks the navmesh for its next waypoint once every 16 frames. Off-screen enemies move 1 frame in 16. |
| `scripts/core/RetroMeshFactory.gd` | Vertex-coloured `ArrayMesh` builders for the tank, bullet, debris, skyscraper and kaiju. |
| `scripts/core/SpatialHash3D.gd` | Uniform grid on the X/Z plane. |
| `scripts/world/DynamicCityManager.gd` | `GridMap` city, building destruction, async navmesh rebake, reset on restart. |
| `scripts/player/KaijuPlayer.gd` | Movement, HP and damage, 10 degree FOV diorama camera, auto-fire. |
| `scripts/ui/MobileTouchController.gd` | Virtual joystick and tap detection. |
| `shaders/ps1_retro_model.gdshader` | Vertex snapping, affine texture mapping, vertex lighting. |
| `shaders/ps1_postprocess.gdshader` | 15-bit colour, Bayer dithering, CRT curve and scanlines. |

## Settings that matter

The renderer is `gl_compatibility` for both desktop and mobile. ETC2/ASTC import is on. `run/max_fps` is 60. The navigation map cell size is 0.25, and the navmesh in `DynamicCityManager` has to match it or region updates are rejected.

## Known gaps

- Not profiled on a device. Pool sizes (2,500 bullets, 500 enemies, 400 debris) and the 31 or so `map_get_path` calls per frame are untested on phone hardware.
- One enemy type, one weapon, no upgrades or progression.
- No textures and no audio. The PS1 shader samples a default white texture.
- Bullets pass through buildings.
