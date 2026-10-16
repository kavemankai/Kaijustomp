# Banksia Heights shopping, cars and debug evolution

Candidate branch: `feature/expanded-suburb-shops-cars-debug`, stacked on `feature/cocoon-evolution-coastal-suburb`. This branch is a separately installable Android preview; the approved long beach, first residential section, camera and growth/evolution mechanics are retained.

## World expansion

- Extends the connected inland terrain and main street to approximately z=-512; no teleport or scene change.
- Adds **12 homes** (two more residential rows), then **12 named small shops**, a **supermarket** and a **hardware store**. The original 54 physical buildings keep their order and positions: new total **80**.
- Shops have their own original low-poly, vertex-colour art kit: storefronts, readable labels, glass, awnings, roof lines and contact shadows. The shopping area includes cross streets and parking aprons. Artwork and collision remain separate; shops and homes use the existing strength-gated automatic attacks, cracks, occupants, police projectile cover and debris.
- Neighbourhood pedestrians replenish near the player's current inland position rather than near the first houses. Police also spawn relative to the player's local district. The HUD labels the new **SHOPPING DISTRICT**.

## Cars

- Adds **16 visible physical cars**: four moving along the main street and twelve parked near shopping. A fixed count of at most 20 vehicles prevents unbounded growth.
- Each uses a merged, original low-poly vehicle body with colour variants and an AnimatableBody3D physics blocker.
- Contact with the creature automatically damages a car with the same movement input as buildings. Baseline attacks take three hits; stronger attacks need fewer and Strength 2 sprint impacts destroy them instantly.
- Destroyed cars become debris, increase police alert and release a fleeing driver for feeding. Moving traffic stops when the creature blocks the road and turns around at the ends of its inland route. Cars do not contain real traffic AI, engine sounds, or pedestrian crossing rules in this first pass.

## Debug-only free evolution

- **DEBUG EVO** is visible on the right-hand side of **debug builds only**, in the restart slot while alive; keyboard shortcut **F6**. It does not overwrite the approved sprint or normal EVOLVE button.
- Tapping grants just enough biomass for the current evolution, starts it, then skips the vulnerable countdown directly into the safe paused mutation choice. A selection still consumes the standard cost; normal mutation history, level counting, skin reveal and level 5/10/16/22/... physical size milestones remain unchanged. Debug tapping cannot stack evolutions during a paused modal or reveal.
- Release/non-debug builds ignore the shortcut and hide the control. This is a QA helper, not an intended progression mechanic.

## Test / acceptance

`test_shopping_cars_debug.gd` checks 80 buildings, 14 shopping stores, solid physical vehicles, moving traffic, contact destruction, debris and fleeing drivers, inland pedestrian replenishment and police, and repeated debug evolution through the level-five growth milestone without feeding. All eight earlier regressions are still required before Android export; the ninth test gates its unique prerelease/APK.

On Android, check whether the larger road and shopping area looks cohesive from the portrait camera, whether vehicles obstruct routes too much, whether attack collisions behave correctly, and the crowd/police density around the supermarket. Profile 15-minute performance with multiple skins. The parked/moving car population is deliberately modest; true traffic/pathfinding, destructible street props and city-wide streaming remain future work.
