# Missions, landmarks and progression objectives

This additive feature builds on World Preview APK227 without changing world dimensions, generator version, building IDs/footprints/rewards, core evolution or DEFCON escalation. Three-mission tracking delivered as World Preview APK231, source `3734363`, following initial mission APK229; final artifact and verification are recorded in CODEX_HANDOVER.md and WORLD_TEST_RESULTS.md.

## Playing

The sector tracker below the status HUD displays up to **three unfinished objectives at once**, each with progress and world-relative guidance where applicable. Unpinned slots automatically suggest relevant missions from nearby landmarks/current chunk, coast versus inland location, evolution progress, demolition accessibility and active DEFCON threat. Tap **OBJECTIVES** to pin or unpin a goal; up to three manual pins retain their order and take priority over suggestions. A fourth pin is disabled until one is removed. **RETURN TO WORLD** resumes. Completed goals leave their slot and a relevant suggestion replaces them; fewer than three remaining goals shows only those still unfinished. The heading identifies the current sector/district, and an asterisk marks manual pins. Opening the panel clears held movement and pauses gameplay actors, damage and timers; static streaming and save completion continue. Gameplay action buttons hide while reading. Selection/reveal/game-over gates prevent opening it during conflicting flows.

All 13 goals are concurrently active and optional. Nothing locks exploration or evolution. Completion automatically grants a single **10 Renown** badge; 130 is the complete set. Renown is a displayed achievement score, not spendable currency, biomass, health or mutation credit. There is no claim button or renewable mission-reward farm. Normal structure biomass remains unchanged.

| Objective | Requirement |
| --- | --- |
| Beyond the beach | Discover Banksia Heights. |
| Coastal wanderer | Reach 2,500 units east or west of the starting beach. |
| Into the interior | Reach 2,200 units inland. |
| Know your territory | Discover any three named sites. |
| Stand tall / City-sized appetite / Titan of the coast | Reach existing E22 / E34 / E80 milestones. |
| Leave your mark | Destroy twelve different structures. |
| Close the harbour | Destroy Seabrook Freight Terminal. |
| Power down | Destroy Ironbark Grid Station. |
| Challenge the command | Destroy Highland Command. |
| Break the response | Defeat five responders by combat damage or grabbing infantry; retirement/unloading gives no credit. |
| Lose the heat | Reach DEFCON2 or1, then return alive to DEFCON5. Paused time does not cool the threat. |

## Landmarks

Banksia Heights reuses the unchanged authored neighbourhood. Five named generated structures reuse existing generator parcels, with additive visual identity (freight gantry, civic crown/clock, electrical fittings or command radar). Destruction removes that identity with the building; distant batches respect the saved tombstone. No extra distant actor simulation is added.

| Destination | Permanent structure ID |
| --- | --- |
| Banksia Heights | Authored neighbourhood at (0,-150), discovery only. |
| Seabrook Freight Terminal | `g1:-14:-2:0` |
| Civic Spire | `g1:12:-12:0` |
| Ironbark Grid Station | `g1:-8:-13:0` |
| Highland Command | `g1:22:-19:0` |
| Westhaven Observatory | `g1:-24:-7:0` |

Positions come from the saved world's seed, not hard-coded random offsets. Landmarks decorate existing descriptors without consuming gameplay RNG or changing generation. Discovery radius is 100 units initially and grows with creature size up to 320. Guidance uses world east/west/inland/coastward and world units, not screen direction or real metres. All destinations are known through objectives; this is not a fog-of-war/map system. Default world extent is tested; substantially smaller custom extents can omit sites and cannot complete this default objective set.

## Ownership and persistence

`WorldObjectives` owns only compact progress and destination metadata; `ObjectiveHUD` owns UI. Optional version-1 `events.objectives` records store discovered IDs, completed IDs, bounded counters and legacy primary selection plus an optional ordered `pins` array (zero to three unique valid unfinished goal IDs). WorldState validation checks nested keys/types/ranges before restoration; unsupported future objective versions preserve the file without backup fallback/overwrite. The existing atomic save, detached worker, backup and fresh RESTART contracts apply. Renown is derived from unique completion flags, never incremented independently.

Existing single-selection objective saves remain version1-compatible: a non-default selected unfinished goal migrates to the first pin; default selection uses automatic suggestions. Arrays over three, duplicates and unknown saved pins are rejected. Old v1 saves without objectives gain the default record on load; saved destroyed structures are credited toward demolition, landmark tombstones satisfy destruction goals, and evolution is observed at the next live tick. Past responder kills and unrecorded visits cannot be reconstructed and begin at zero. Counters/discovery update at most four times per second; combat/demolition callbacks update immediately. Completed objectives do not reissue rewards on reload. Autosave/pause/exit checkpoint progress using the existing policy; RESTART clears it with the run.

## Verification and limits

`test_world_objectives.gd` covers discovery, travel, all six destinations, generated metadata/art, demolition and unload tombstones, one-time rewards, actual responder combat, alive de-escalation, E22/E34 credit, panel pause/selection/input reset, disk restart, malformed progress, future-version preservation and old-save credit. All existing regressions remain in CI. `test_world_tracking.gd` additionally checks three unique suggestions, sector/threat relevance, ordered pins and cap/unpin/autofill, completed cleanup, disk restoration, single-selection migration, invalid pins and finished-game HUD. `capture_objectives.gd` captures 540x960 tracker/list and landmark views. This first mission set has no narrative quest chain, mission-specific enemy spawns, unique civilian tasks, minimap or spendable Renown shop. Physical Android touch, pacing and sustained performance remain device acceptance work.
