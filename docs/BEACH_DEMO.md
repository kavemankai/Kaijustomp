# Beach demo — first playable vertical slice

Branch: feature/beach-demo-elevated-camera. This is a **separate scene** from the original auto-shooter and does not delete its systems.

## Play

Open in Godot 4.3 (4.2+ should be compatible) and run the project. The branch changes `run/main_scene` to `res://scenes/BeachDemo.tscn`. The original scene remains at `res://MainGame.tscn`.

- Desktop: WASD / arrow keys to move, **tap Shift** to toggle sprint on/off, press E to evolve, R to restart after death.
- Mobile: drag the left half of the screen to steer; **tap SPRINT** to toggle on/off; press EVOLVE once sufficient biomass is collected.
- When the stamina meter empties, sprint automatically turns off and its button is greyed out until stamina **fully recharges**. Toggling off early does not lock the button.

## Intended feel and rules

- Elevated three-quarter camera, with follow smoothing and movement relative to the camera.
- Great-white-sized quadrupedal creature with responsive directional turning, alternating four-leg gait, animated tail/body sway, stamina-limited toggle sprint and a 0.55 s feeding slowdown.
- Guaranteed one-at-a-time auto-bite inside a forward cone, with an obvious forward head lunge, jaw opening, prey pulled into the mouth and a short swallow/shrink animation.
- Civilians have varied reaction times and running speeds; some seek shelter inside buildings.
- Feeding gives +12 biomass and +15 health. Police bites give +16 biomass.
- First evolution costs 55 biomass. Extra biomass increases the number of mutation choices, but grants only one mutation. The rest carries forward.
- Evolutions lock movement for 6 s initially; each successful pop adds 1.5 s. Cumulative damage of 35 during the process cancels the evolution and loses the entire saved biomass; death ends the run. A successful evolution heals fully.
- Base creature has 100 HP and an officer's **landed** pistol shot deals 10 damage. Armour progressively reduces this damage.
- Level 0 cannot damage buildings. First strength upgrade enables a 3-hit attack; later strength upgrades enable breakthrough on contact.
- Civilians inside destroyed buildings are exposed; debris disappears.

## Scope / limitations

This is a **prototype implementation and has not been run or profiled in Godot on Android yet**. Generated geometry, *prototype procedural* quadruped and swallowing animations, simple steering, hit probability, placeholder structures and HUD are used to validate feel. Civilians and officers do not have full navmesh avoidance. Police are a lightweight response prototype, not a finished law-enforcement system. The current building-destruction mapping is temporary. Electrical feeding, rival monsters, proper animations, advanced evolution selection, persisted progress, ocean emergence animation, and audio polish are **not implemented**.

## First playtest checklist

1. Confirm the demo opens without parse errors on Godot 4.3 and an Android test build.
2. Verify that left-stick controls match screen direction with the angled camera.
3. Try abrupt joystick direction changes (including 180-degree reversals): controls should change travel direction immediately and the lizard should visibly turn and animate its four limbs.
4. Tap sprint on, run until stamina reaches zero and confirm the button greys out, cannot be retriggered during partial recharge, and re-enables at 100%; tap sprint off early and verify manual stop still works.
5. Test that biting in the forward cone never whiffs, pulls one victim into the mouth, and visibly opens/closes the jaws. Verify the slowdown feels fair.
6. Stand still for ten landed police hits: unmodified 100 HP creature should die.
7. Collect 55+ biomass, evolve, then confirm mutation selection, full heal and carry-over.
8. Take 35 damage while evolving: reserve should reset to zero; existing mutations should persist.
9. Pick Brutal Strength, break a café wall in three hits; confirm civilians emerge and debris despawns.
10. Profile frame pacing and HUD layout in Android portrait and landscape.

## Architectural next steps

Split the single scene script into player, civilian, response, world, evolution and HUD systems **after** the playtest confirms the mechanical direction. Reuse the existing procedural texture/audio framework and spatial hash as needed rather than porting the old shooting simulator. Preserve the original scene for regression/reference.

## Playtest feedback / iteration 2 (2026-10-16)

- **Keep:** elevated three-quarter follow camera; no camera changes in this iteration.
- **Problem:** the lizard felt like a tank. **Change:** faster heading response with immediate screen-relative movement, procedural diagonal leg gait, body bob and articulated tail.
- **Problem:** holding sprint is unsuitable for mobile. **Change:** tap-to-toggle with button highlighting, automatic stop at zero stamina, disabled/grey button until fully recharged.
- **Problem:** feeding felt functionally okay but had no readable visual. **Change:** head lunge, jaw rotation, target retained briefly as it moves into the mouth and shrinks on swallow.
- **Status:** changes committed; Android feel and Godot startup **not yet verified** from this environment. Test on device before refining art.
