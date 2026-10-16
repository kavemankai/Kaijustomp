# Long beach / renewable population candidate

Branch: `feature/extended-coast-population`, based on sculpted-art draft PR #8. This is an isolated **unmerged** gameplay preview. The approved artwork, 540×960 portrait presentation, camera angle, movement, sprint, growth, bite, shedding and evolution stay unchanged.

## Player problem

The approved art prototype has an approximately 140-unit-wide playable coastline and 22 starting beachgoers. A natural playthrough soon exhausts prey and hits the horizontal wall.

## Implemented

- **Eightfold coastline:** 1,120 units of continuous beach scenery and sand, with horizontal playable bounds of ±548 units rather than ±70. The entire original six-building starting district is unchanged.
- **Coastal destinations:** six additional districts, three to each side, spaced 150 units apart. Five destructible buildings per additional district (kiosk, rescue shed, café, shop, apartments) use the existing collision, strength, cracks, civilian occupants, debris and projectile interception systems. Total: 36 buildings.
- **Sustainable prey:** 26 initial people plus small incoming batches (up to five every 1.7 seconds, targeting 34 nearby active people). New arrivals appear some distance from the creature, within the playable shoreline, and outside buildings. People far behind the creature are retired, preventing accumulated world-length NPC cost. New shelter choices resolve nearby intact buildings instead of always referring back to the central kiosk/shed.
- **Response follows exploration:** police and SWAT officers arrive relative to the player's current district, and patrols too far behind are retired rather than blocking future response waves.
- **Coherent scenery:** promenade clusters, beach fences, swimming flags, trees, headlands and shoreline bands extend along the whole map. Decoration placement uses the existing deterministic art seed.
- **Preserved performance budgets:** existing limit of 40 pooled impacts, capped projectiles, 48 debris pieces and five old skins remains. No new textures or NPC rigs. Frustum culling works on building art; distant building geometry/collision remains loaded. The active beach population has a **target** of 34 and is bounded by ordinary waves, but demolition can temporarily create larger crowds by releasing occupants.

## Coverage and remaining checks

`test_long_beach.gd` checks extended horizontal traversal, far-left and far-right destinations, intact starting buildings, spawned people after depletion and near map edges, local shelter selection, and district-relative police. All prior six Godot tests, including building collision, evolution/sprint and coastal art, remain Android export gates. Test is included in smoke and APK workflows. Android build on `feature/extended-coast-population` is separately named `Kaijustomp Long Beach Preview` and uses `com.kavemankai.kaijustomp.longbeachpreview` so it does not overwrite the liked coastal-art build.

**Phone acceptance:** verify the extended level actually feels continuous, no obvious asset repetition, newcomer arrival feels natural, people do not appear in view or buildings, police remain a credible threat and neither FPS nor thermal behaviour regresses after 15 minutes and five discarded skins. Dynamic architecture/chunk streaming and larger-city regions are future work; this is a substantially longer **finite** beach rather than an infinite procedural world.
