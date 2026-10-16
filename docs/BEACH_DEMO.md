# Beach demo — first playable vertical slice

Branch: feature/beach-demo-elevated-camera. This is a **separate scene** from the original auto-shooter and does not delete its systems.

## Play

Open in Godot 4.3 (4.2+ should be compatible) and run the project. The branch changes \`run/main_scene\` to \`res://scenes/BeachDemo.tscn\`. The original scene remains at \`res://MainGame.tscn\`.

- Desktop: WASD / arrow keys to move, hold Shift to sprint, press E to evolve, R to restart after death.
- Mobile: drag the left half of the screen to steer; hold the right-side SPRINT button; press EVOLVE once sufficient biomass is collected.

## Intended feel and rules

- Elevated three-quarter camera, with follow smoothing and movement relative to the camera.
- Great-white-sized quadrupedal creature with a quick run, stamina-limited sprint and a 0.55 s feeding slowdown.
- Guaranteed one-at-a-time auto-bite inside a forward cone.
- Civilians have varied reaction times and running speeds; some seek shelter inside buildings.
- Feeding gives +12 biomass and +15 health. Police bites give +16 biomass.
- First evolution costs 55 biomass. Extra biomass increases the number of mutation choices, but grants only one mutation. The rest carries forward.
- Evolutions lock movement for 6 s initially; each successful pop adds 1.5 s. Cumulative damage of 35 during the process cancels the evolution and loses the entire saved biomass; death ends the run. A successful evolution heals fully.
- Base creature has 100 HP and an officer's **landed** pistol shot deals 10 damage. Armour progressively reduces this damage.
- Level 0 cannot damage buildings. First strength upgrade enables a 3-hit attack; later strength upgrades enable breakthrough on contact.
- Civilians inside destroyed buildings are exposed; debris disappears.

## Scope / limitations

This is a **prototype implementation and has not been run or profiled in Godot on Android yet**. Generated geometry, basic procedural animation, simple steering, hit probability, placeholder structures and HUD are used to validate feel. Civilians and officers do not have full navmesh avoidance. Police are a lightweight response prototype, not a finished law-enforcement system. The current building-destruction mapping is temporary. Electrical feeding, rival monsters, proper animations, advanced evolution selection, persisted progress, ocean emergence animation, and audio polish are **not implemented**.

## First playtest checklist

1. Confirm the demo opens without parse errors on Godot 4.3 and an Android test build.
2. Verify that left-stick controls match screen direction with the angled camera.
3. Test that biting in the forward cone never whiffs and consumes one target at a time.
4. Check sprint exhaustion/recovery and whether the bite pause feels fair.
5. Stand still for ten landed police hits: unmodified 100 HP creature should die.
6. Collect 55+ biomass, evolve, then confirm mutation selection, full heal and carry-over.
7. Take 35 damage while evolving: reserve should reset to zero; existing mutations should persist.
8. Pick Brutal Strength, break a café wall in three hits; confirm civilians emerge and debris despawns.
9. Profile frame pacing and HUD layout in Android portrait and landscape.

## Architectural next steps

Split the single scene script into player, civilian, response, world, evolution and HUD systems **after** the playtest confirms the mechanical direction. Reuse the existing procedural texture/audio framework and spatial hash as needed rather than porting the old shooting simulator. Preserve the original scene for regression/reference.
