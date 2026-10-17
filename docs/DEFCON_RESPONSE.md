# DEFCON response escalation (unmerged candidate)

User request (2026-10-17): while the diet transition APK remains untested, implement a coherent DEFCON system and more enemies, without disturbing beach, suburbs, shop destruction, batch debug evolution or the existing creature.

## DEFCON rules

Public DEFCON numbering **decreases as danger rises**. DEFCON 5 means local emergency handling; DEFCON 1 means highest military response.

| Status | Player alert | Response wave | Maximum active response units | New wave interval |
| --- | ---: | --- | ---: | ---: |
| DEFCON 5: Local Police | 0–24 | 2 patrol officers | 2 | 18 s |
| DEFCON 4: Tactical Response | 25–64 | patrol officer, SWAT officer | 4 | 16 s |
| DEFCON 3: National Guard | 65–129 | SWAT and 2 soldiers | 6 | 13 s |
| DEFCON 2: Armoured Support | 130–219 | soldiers and an armoured personnel carrier | 7 | 11 s |
| DEFCON 1: Air Support | 220+ | soldiers, APC and attack helicopter | 9 | 9 s |

*Thwarting a threat is not represented by instant difficulty spikes from debug growth alone.* Alert rises with **feeding**, wrecking vehicles, demolishing structures, and defeating emergency response units. The DEFCON tier recalculates immediately after an action. Each wave follows the creature into any developed region; rosters rotate over time. After 18 seconds without further violence, alert drains by 0.75 per second and response tiers lower naturally; no new responders spawn if alert reaches zero. This is not a separate game level.

## Enemy roster (first playable pass)

- **Police:** normal person-scale patrols, 24 HP, 10 projectile damage, 21-unit range, shots ~2s apart.
- **SWAT:** clearly armoured infantry; 55 HP, 16 damage, 29-unit range.
- **National Guard soldier:** dark-green helmet/vest and rifle kit; 85 HP, 21 damage, 42-unit range.
- **Armoured carrier:** original low-poly vehicle and physically blocking collision body; 280 HP, 35 damage, 65-unit range, heavy shots. Giant strikes can destroy its body.
- **Attack helicopter:** original airborne fuselage/skids/tail and spinning rotors; 180 HP, 27 damage, 95-unit range. A giant walking under it can damage it with a size-driven stomp interaction.

These are first-pass response combatants, not fully navigated tactical AI. Infantry use existing body animation and terrain obstruction rules, aircraft fly overhead, APCs obey local obstruction rules. All firing reuses actual moving projectiles and physical raycast cover. Destroyed response vehicles make bounded debris; defeating units further raises alert. The player can devour eligible human-sized enemies while small; at late giant scale, people no longer count as food.

## Performance and integrity

Active responders are globally limited to **9**, tracers to **72**, all old distant responders are retired behind player movement, and structures still intercept bullets. Existing mutation history, camera, mobile joystick, sprint, cars, foliage, population, hunger and diet are unchanged. Portrait HUD now displays an explicit **DEFCON 5…1 / response label** without replacing the district label.

## Testing and next validation

`scripts/ci/test_defcon_response.gd` adds a 13th Godot automated regression covering every tier/threshold, expected mixed waves, enemy stats and identities, active and projectile caps, APC collisions and defeat, rotating helicopter blades, quiet de-escalation, no police at zero alert, and batch DEBUG EVO compatibility. All twelve prior Godot tests still gate export, along with Android debug signing, apk verification and an isolated `com.kavemankai.kaijustomp.defconpreview` prerelease. Existing diet preview stays untouched.

**On-phone feedback needed:** escalation pacing with actual car/shop demolition, SWAT readability at portrait zoom, appropriate danger without swarming, relative sizes of armoured units and helicopters at E34+, whether projectiles reach large targets, and 15-minute performance at highest tier. In particular, this does not address the previously observed E120 stretching gait or missing city-sized food/world.
