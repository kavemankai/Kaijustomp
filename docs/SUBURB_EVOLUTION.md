# Cocoon mutation and Banksia Heights neighbourhood candidate

Branch: `feature/cocoon-evolution-coastal-suburb`, stacked on `feature/extended-coast-population`. Draft/unmerged, separate preview; the accepted extended beach and sculpted art remain unchanged.

## Two new evolution families

- **Reinforced Cocoon** — unlocks after the first successful evolution and can be selected repeatedly. Each rank multiplies received damage **only while physically evolving** by 0.82, in addition to normal permanent armour. Each rank also raises the accumulated damage interruption limit by 12 (35 base, 47 at rank 1, 59 at rank 2). Death still interrupts; failures still erase saved biomass but retain learned mutations.
- **Rapid Metamorphosis** — unlocks after first evolution; each rank multiplies the vulnerable evolution countdown by 0.78, down to a minimum of 3.0 seconds. Base countdown remains `6.0 + 1.5 × successful evolutions`. Choices and final skin reveal stay paused/safe and are **not** sped up.
- Both appear in ordered history, the mutation selection pool, anatomical SVG icons, and bounded 3-tier cumulative creature plates/ridges. Cosmetic geometry caps after rank 3 while rank/stat acquisition remains permanent. Original 3 choices plus excess biomass remains, and portrait screen offers at most seven cards to prevent overflow. First evolution still uses the six original choices.

## First inland neighbourhood

The new **Banksia Heights** neighbourhood begins beyond the promenade at approximately z = -82, continuously connected to the existing long beach. A central access road and two cross streets lead among **18 destructible coastal homes** in three rows and six columns, bringing the world from 36 to 54 physical buildings. The beach start is unchanged. Houses have original batched suburban art (pitched roofs, porches, doors, windows, material variation) and existing physically blocking walls, progressive destruction, occupant release, police-projectile cover and debris.

Inland walking boundary extends to z = -232; x bounds and existing camera/joystick remain unchanged. NPC replenishment spawns among neighbourhood streets when the player is inland, avoiding solid structures. Police/SWAT spawn relative to current location. The HUD identifies the new zone. Homes have modest 2–3 strength requirement and 4–6 concealed occupants; they do not introduce a new mechanic.

This is a **first playable section**, not a complete town/city level or new world-streaming architecture. Real residential animations, cars, larger-city sectors, traffic and escalation remain later milestones.

## Test and phone checklist

`test_suburb_evolution.gd` exercises both perks (stat/history/art, damage and interruption, shorter timer), the capped portrait choice pool, 18 solid homes, inland traversal and local prey replenishment. Existing evolution, combat, art, staged growth and extended beach tests remain mandatory; workflows gate isolated Android APK export on all eight suites.

Install the `Kaijustomp Suburb Preview` package alongside the long-beach preview. Natural-play acceptance: evolve to obtain each new mutation, check meaningful differences under police fire, travel inland from promenade and see continuous streets and houses, verify local people and police, demolish a home and assess sustained Android frame pacing for 15 minutes. Do not merge without player confirmation.
