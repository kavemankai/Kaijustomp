# Expanded outer world and camera-safe DEFCON arrivals

**Branch:** `feature/outer-district-offscreen-defcon`, stacked on unmerged DEFCON PR #15. Isolated candidate; player approved the DEFCON system and asked for more world and reinforcements to originate outside their point of view. The previously working DEFCON Android build remains intact.

## Bigger, continuous landmass

- Coastal world widened from **1,120 to 1,560 units of authored shoreline**. Player horizontal bounds expand to ±768 from ±548. New beach building clusters are appended after the **original 80** building indices, so existing quests/tests do not shift.
- Banksia Heights and shopping preserve their existing positions. A new connected **outer suburb** takes the central road further inland, with 12 additional coastal homes.
- A **large industrial estate** follows with 12 new factories, warehouses, distribution depots, power/water facilities and container yards. The largest are 88 × 75 footprint, 23 units high; they have real colliders, staged cracking and destruction, occupants, mobile-batched architectural meshes, loading doors and rooftop equipment.
- Together with ten additional coast buildings, the world has **114 destructible structures** (was 80). The inland walkable boundary now reaches z=-1520 (was -512), with road markings, cross streets and parking/hardstands connecting the entire route without loading another level. Large factory demolition is a more useful one-time biomass source for gigantic forms.
- Increase camera far plane so large-scale distant sections do not disappear behind the prior 230-unit draw distance. This is still a *finite authored world*, not procedural streaming or an infinite city.

## Off-screen DEFCON staging

Original responder spawning used x offsets ±12/±32 and a fixed short distance around the beast. At large zoom or on portrait screens it produced visible pop-in.

- Before deploying a police officer, SWAT team, soldier, armoured unit or helicopter, **sample candidate spawn coordinates on radial rings around the player**.
- Project candidate body/vehicle top and bottom against the actual `Camera3D` and current portrait viewport using `unproject_position` and `is_position_behind`. Reject any candidate inside the screen plus a **55-pixel safety margin**.
- Reject out-of-bounds land and building interiors, and avoid stacking with other responders. Use larger rings when growth/camera zoom increases. Return a non-finite sentinel when there is no valid outside-view staging point rather than rendering an enemy on screen.
- Units advance toward the player from farther away (old distance <125 cap removed). They slide around building footprints, and their movement speed scales with the creature at giant scales so the reinforcements remain relevant.
- The existing 5-tier DEFCON escalation, cooldown, projectile raycast cover, **9-unit** enemy cap and **72 projectile** cap remain intact.

## Regression and device acceptance

`scripts/ci/test_outer_world_offscreen.gd` extends the existing suite to **14 tests**, covering original stable world indices and counts, physically collidable large industrial structures, connected traversal, giant-scale biomass, camera-based ground and air spawning in the extended district, camera rotation, E34 zoom and optional E120 constraints. Every current Android CI gate remains mandatory before a uniquely named, separately installable prerelease.

**Phone review:** walk from the old shops past the outer suburbs into the big industrial estate; test large-building demolition at E34–E60, DEFCON waves entering from outside the visible screen, their time to reach the giant, and performance/frame pacing after 15 minutes. In E120 cases where almost the entire finite world fits on screen, a wave is allowed to **wait** rather than pop into view. Existing E120 leg-stretch/foot-placement work is not claimed to be fixed by this change.
