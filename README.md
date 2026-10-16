# Kaijustomp

Retro low-poly kaiju reverse auto-shooter for Godot 4 (mobile first). You are the kaiju. Horde enemies converge on you, you auto-fire bullet patterns, and you crush buildings by walking through them.

The project needs no external assets. `MainGame.gd` builds the camera, lights, city, bullet and horde pools, post-processing and touch UI in code.

## Run

1. Install Godot 4.2 or newer (developed against 4.3).
2. Import `project.godot` and press F5.
3. Controls: WASD or arrows to move. Drag on the left half of a touch screen to move. Tap the right half for the Atomic Nova ring. Mouse input emulates touch.

## Layout

| Path | Purpose |
| --- | --- |
| `scripts/core/SimulationManager.gd` | Flat-array pools for bullets, enemies and debris, rendered through `MultiMeshInstance3D`. Spatial hash collision. Off-screen enemies tick 1 in 16 frames. |
| `scripts/core/SpatialHash3D.gd` | Uniform grid on the X/Z plane. |
| `scripts/world/DynamicCityManager.gd` | `GridMap` city, building destruction, async navmesh rebake. |
| `scripts/player/KaijuPlayer.gd` | Movement, 10 degree FOV diorama camera, auto-fire. |
| `scripts/ui/MobileTouchController.gd` | Virtual joystick and tap detection. |
| `shaders/ps1_retro_model.gdshader` | Vertex snapping, affine texture mapping, vertex lighting. |
| `shaders/ps1_postprocess.gdshader` | 15-bit colour, Bayer dithering, CRT curve and scanlines. |

## Settings that matter

The renderer is `gl_compatibility` for both desktop and mobile. ETC2/ASTC import is on. `run/max_fps` is 60. The navigation map cell size is 0.25, and the navmesh in `DynamicCityManager` has to match it or region updates are rejected.

## Known gaps

- Enemies chase the player in a straight line. The navmesh is built and rebaked but nothing reads it yet.
- Enemies do not damage the player, and there is no game-over state.
- All meshes are boxes. There are no textures, so the PS1 shader samples a default white texture.
- Not profiled on a device. The 4,000 bullet and 600 enemy caps are guesses.
