# KaijuStomp — 500-Mutation Integration Plan

**Status:** Design proposal / implementation hand-off, 17 October 2026. **Not a claim that the repository has been modified or that any mutation is already playable.**

**Inputs:** `kaijustomp_evolution_tree.md` (500 numbered mutations, source stat proposals, source visual descriptions); previously agreed KaijuStomp direction (persistent connected coastal world, new creature after death, deliberate DEFCON escalation, sector-origin responders, realistic starting creature, choice-driven growth, mobile-first controls and premium full-game objective).

**Linked data:** `kaijustomp_mutation_catalog_500.json` preserves all 500 mutation names, original descriptions, stat and visual notes, and proposed delivery lanes. It is a planning catalogue, not production-balanced gameplay data.

## 1. The design decision

Implement **500 catalogue entries** supported by a tractable set of shared systems—not 500 individually coded, separately animated powers. A single creature never needs all 500. The game is about developing one striking, coherent organism at a time, leaving traces in an evolving world, dying, and bringing forward discoveries into the next organism.

### Locked project constraints

1. **Persistent world, new creature upon death** (Option B). No clean map reset or automatic respawn as the identical monster.
2. **Grounded start:** ocean spawn, quiet Australian beach, reptile-sized creature, gradual escalation from local policing to organised armed response.
3. **Responses originate in the world:** foot police from beach/local station, squad cars and SWAT from suburbs, heavier units farther inland or bases; dispatches have genuine travel time.
4. **Three simultaneous rolling objectives:** hunt, destroy, explore. Completing one replaces it with another of the same type.
5. **One connected world:** detailed beach first, then streamed 2×2 km test, ultimately a broad fictional Australian coastal metropolitan region (~14×10 km direction).
6. **Physical growth is a choice:** small, lethal, stealthy creatures remain legitimate; no mandatory biped, quadruped, octopod, or oversized transition.
7. **Mobile game, premium standalone philosophy:** full game with a real progression arc; no paid rerolls, gacha or exploitative power purchases.

## 2. What the source tree really represents

| Source section | Mutation IDs | Document framing | Practical handling |
|---|---|---|---|
| Hatchling | 1–100 | E0–E4 | Potential *pool* of starter traits; not 100 mandatory levels |
| Predator | 101–200 | E5–E21 | Physical fighting, vehicles and specialised mobility |
| Monster | 201–300 | E22–E39 | Large kaiju powers, city disruption and new body plans |
| Cataclysm | 301–400 | E40+ | Endgame fantasy, represented at city/regional scale first |
| Cosmic/Apex | 401–500 | Interdimensional/star-eater | Split into truly postgame traits **and** ordinary mutations that should be retiered |

**Retier examples:** IDs 421–430 (hybrid anatomy) are much more useful once hybrid bodies are possible, rather than after the apocalypse. IDs 441–450 (tactics, stealth, momentum) are ordinary midgame abilities. IDs 461–480 include low/midgame naturalistic traits, e.g. #461 Glass-Cannon Hyper-Claws, #471 Tardigrade Cryptobiosis State, #475 Caterpillar Silk Cocooning. #500 The Genesis Seed is an unusually good long-term lineage / prestige mechanic.

**Source contradictions requiring explicit design fixes:**
- The file calls the tree '500-step' but E0–E4 cannot accommodate 100 individually chosen mutation levels. Convert numbered entries into **catalogue IDs**, not level requirements.
- The original says cars become edible above **2.45× scale**, yet some E5–E16 entries describe vehicle eating well before that threshold. Treat car attacks and damage as available earlier; **biomass consumption** is gated by actual physical capacity and digestion traits, not by the tier label alone.
- It says full building consumption begins at **3.35×**, while the E34 milestone is about **3.74×**. Let damaging structures, bringing them down, and digesting structural material be separate gates.
- E22 upright transformation is described as universal. Instead, treat it as an **upright branch opportunity**; an insect, reptile, sea-creature or compact monstrosity need not become bipedal.
- Global annihilation, instant immunity, infinite stamina, FTL travel and similar effects conflict with meaningful combat and a geographically continuous world. Scale these effects to credible area-of-effect, cooldowns or *future expansion* rather than literal planet simulation.
- Source values such as `0.78` damage multiplier and `+1.6` speed per Fleet Limbs stack are **source baselines**, not automatically safe for endless stacking.

## 3. Core lifetime loop

**Spawn -> hunt/explore/destroy -> absorb biomass -> choose evolution -> visibly transform -> alter your territory -> attract reaction forces -> survive or die -> leave a world history -> begin new organism.**

1. **Choose one mutation** at each evolution event from three contextual choices (normal pick, affinity pick, wildcard); no forced cross-family class lock.
2. **Mutation rarity and prerequisites** depend on physical stage, prior organs, available environment, discovered gene knowledge and compatibility.
3. **Physical growth** occurs only when the creature accepts a body-growth metamorphosis or invests biomass in size. The original size track remains an accessible *default*, not a hard requirement.
4. **Mutation slots:** anatomy (skin/armour, head/jaw, front limbs, rear limbs, tail, dorsal, core/organs) plus passive physiology and a limited number of equipped active attacks. Incompatible anatomical configurations have readable alternatives, e.g. forelimb scythes *replace* paws, not both simultaneously.
5. **Controls:** existing movement + sprint + primary contextual contact attack. Reserve at most one immediately accessible special-action control in the first milestone; later unlock a second slot if touch ergonomics permit. Passives auto-trigger; evolution choice can pause solo play.
6. **Major power preparation** should be visible and respondable: charged breath, leap, telegraphed stomp, tail windup. Give damage, cooldown and energy tradeoffs.
7. **Hunt, destroy and explore tasks** respond to current body size and accessible regions, never issuing unreachable objectives.

### Visible evolution principle

Each equipped mutation needs an on-body sign: silhouette, attached mesh, colour/material layer, particles, sound, or an animation. Some subtle sensory/gland mutations can use a visible idle cue; large anatomical mutations need clear silhouettes. Avoid 500 manually modelled full-body creatures. Build a *modular creature construction system* and a smaller library of body recipes/attachments.

## 4. Growth and capability gates

Carry forward the list's baseline growth references, but reinterpret them as **optional morphology milestones**:

| Evolution reference | Default scale in source | Example transition | Play-world capability |
|---|---:|---|---|
| E0–E4 | starts ~1.0× | Hatchling, body primitives | People/small prey, shrubs and fragile objects; pistols mostly survivable, concentrated fire still dangerous |
| E5 | 1.20× | Larger grounded predator | Fence/door damage, stronger feeding, limited vehicle damage |
| E10 | 1.49× | Larger quadruped or chosen alternative | Stronger pounce and damage; more breakables |
| E16 | 1.90× | Heavy quadruped or alternative | Cars become practical combat targets; increasing anti-vehicle pressure |
| near E21–E22 | 2.45× consumption threshold; E22 ~2.51× | Upright **if chosen** | Digest car biomass if suitable jaws/gut; more prominent target |
| E28 | 3.12× | Large kaiju option | Heavy vehicles, advanced special attacks and major structures |
| near E31–E34 | 3.35× building digestion; E34 ~3.74× | Giant form **if chosen** | Collapse and digest substantial structures if adapted |
| E40+ | Source: +1.16× growth every six evolutions | Postgame growth route | Increasing regional transformations and prestige progression |

**Small-form parity:** A creature that declines size investment accumulates opportunities in stealth, speed, toxin, regenerative survival, armour penetration and environmental traversal. Its *threat* can grow without its collision footprint growing. It may infiltrate bases or disable command systems rather than stomp skyscrapers. Every build must have credible objectives and an endgame path.

## 5. Creature specialisations — affinities, not mutually exclusive classes

| Build identity | Sample source mutation IDs | Strengths / constraints |
|---|---|---|
| Fast stalker | #22 Hollow Bone Struts, #20 Camouflage Chromatophores, #47 Adrenal Gland Hyper-Drive, #441 Ambush Predator Patience, #447 Juggernaut Momentum | Speed, ambush, escape; lower armour and structural force |
| Armoured tank | #6 Sub-dermal Osteoderms, #61 Chitinous Exoskeleton, #105 Thickened Scute Armor, #161 Chitinous Exoskeleton Tier 2, #202 Tectonic Plate Armor | Projectile resistance, frontal survivability; less agility, bigger profile |
| Acid/venom destroyer | #7 Acidic Saliva Gland, #17 Venom Sac, #99 Degenerative Acid Slime, #168 Acid-Spray Gland, #218 Acid-Spitting Throat Gland | Status damage, corrosion, area denial; competing gland capacity, resource cost |
| Heavy bruiser | #19 Tail Club Node, #101 Titan Jaw Extension, #143 Rhino-Class Nasal Horn, #148 Crushing Great-Ape Fists, #206 Seismic Stomp | Charge, impact, destruction; slow windups and noisy approach |
| Mobile glider | #29 Gliding Patagium, #39 Pneumatic Air Sacs, #121 True Flight Patagium, #203 Draconic Wings | Traversal / aerial strike; requires real aerial camera, collisions and counterplay before powered flight ships |
| Hybrid anomaly | #100 Chimeric Flesh Matrix, #200 Chimeric Flesh Re-alignment, #421 Draconic-Arachnid Hybridization, #428 Arachnid-Mammalian Web-Tusker | Cross-branch synergies; rig/animation complexity. Unlock after modular body systems work |

### Example synergies

- **Osteoderms + tail club:** body hits take less damage; tail strikes hit harder; loss of top-end acceleration.
- **Hollow bones + gliding skin + adrenaline:** long-leap predator; high damage vulnerability on direct impact.
- **Acidic saliva + scavenger jaw:** corrosion cracks vehicle armour earlier, but it is still not digestible before physical/digestion gate.
- **Camouflage + silent gait + thermal pits:** avoid local patrols, identify prey, cross sectors without raising automatic alert.
- **Heavy shell + slime coating:** grapples/slow resist, excellent escape from entanglement, but costly movement and reduced stamina recovery.

## 6. Reusable runtime systems

Implement these generic handlers before pursuing 500 bespoke features:

1. **Stats/resistances:** health, mass, speed, acceleration, turn rate, stamina, bite/impact/acid/ranged power, armour classes, sight/scent/hearing.
2. **Tags and prerequisites:** gene branches, slot requirements, conflicts, prerequisite and synergy rules.
3. **Status effects:** venom, corrosion, stun, fear, slow, bleeding, fire, regeneration, detection; common duration/resistance logic.
4. **Active attacks:** contact hit, cone, projectile, charged beam, leap, stomp, roar, trap, summon; a small common projectile/cooldown/telegraph framework.
5. **Movement modes:** ground, swim, climb, glide, burrow, flight; ship only as separate tested features. Modes need independent input, collision, streaming, and AI response support.
6. **Sensor and stealth model:** sight, heat, scent, sound, line-of-sight, noise from movement; patrol detection and loss of contact.
7. **Feeding and digestion:** damage/break objects, devour biomass if eligible, absorb environmental resources, recover/stored biomass.
8. **Anatomical composer:** rig profiles / locomotion families, sockets, material layers, constrained morph targets, mutation attachment visuals.
9. **World alteration:** persistent destruction states, local flora effects, rubble, hazards, repair/recovery, local resources and landmarks.
10. **Lineage/meta-progression:** codex discovery, carried-forward mutation *availability*, limited inherited affinities, history, selected NG+ anomalies.
11. **AI response integration:** species observations influence threat knowledge; local alarms and regional dispatches cannot spawn instantly around player.
12. **Telemetry and validation:** data-driven tests for all catalog entries, balance events, FPS and memory budgets on Android.

### Stat stacking rules

- Preserve the source's Hardened Scales `0.78× incoming damage per stack` and Fleet Limbs `+1.6` speed per upgrade **only as legacy baselines until tuning**. An unlimited `0.78^n` tends toward zero damage; unlimited linear speed defeats small-scale world traversal, AI chase and mobile controls.
- Proposed remedy: diminishing returns and caps on *generic* stacked modifiers, plus distinct damage categories (`small_arms`, `high_power`, `explosive`, `energy`, `crush`, `status`).
- Late-stage creatures can be functionally immune to low-calibre pistols. They must not automatically ignore anti-armour munitions, heavy kinetic impacts or the wrong environmental hazard.
- Small forms gain **penetration and evasion**, not the same raw armour/size scaling as tank builds.
- For every mutation, compute both an **effective gameplay effect** and a **visible/mobility tradeoff**. Prohibit infinite, unbounded or global free-effect descriptions from shipping literally.

## 7. World persistence and death

Separate **World Save** from **Current Organism Save** and **Species Archive**.

**World Save (persists):** destroyed landmarks/districts, damaged infrastructures, corpse/remains, biomass scars, evolving ecosystem, responder availability, faction pressure, discovered regions, known lairs, restoration clocks. Save district deltas rather than rebuilding an entire streaming map from a huge full snapshot.

**Current Organism Save (lost upon death):** body plan, chosen mutations, biomass, current size, energy, temporary injuries, equipped powers and local heat.

**Species Archive (persists):** collected discoveries, branch mastery/unlock availability, noteworthy achievements, prior creature lineage, cosmetic heredity, limited genetic memory boons. **Do not carry an already maxed-out monster's full combat stats** into a newborn. That would eliminate early-game challenge.

**Death procedure:** resolve cause, log final location and impact, update historical sites, close current creature, generate a new organism and choose a viable quiet spawn in a region reflecting current world state. Optional corpse can be visited, scavenged or exploited by future creatures. Death never erases prior destruction just to simplify spawning.

**Late-game prestige:** #500 **The Genesis Seed** can become a deliberate lineage restart / new-world scenario with codex and rare starting predispositions. Keep it distinct from ordinary death. An entirely new playable planet and literal interplanetary physics are not required to ship this prestige system.

## 8. DEFCON, regions and mutation compatibility

Maintain two different signals:
- **Local alert:** immediate witnesses, noise, destroyed vehicles, visible monster, active police radio traffic, pursuit or last-seen location. Can calm when no contact remains.
- **Strategic response pressure:** long-run damage and military learning across districts; authorises tiers of response and persists as institutional knowledge (with decay and reorganisations), not instant beam SWAT units at the next hatchling.

The previously proposed thresholds **5=0 / 4=35 / 3=100 / 2=225 / 1=425** are **initial tuning candidates**, not shipped balance values. Dispatch must occur from sector-specific locations and take time: beach beat cops -> suburban squad cars/SWAT -> inland military and specialist anti-kaiju response. Heavy laser teams must never appear immediately before meaningful encounters simply because a hidden counter crossed a threshold.

**Mutation interactions:** roar/fire/visible beaming increase detection, stealth/camouflage reduce spotting, burrowing breaks ground line-of-sight but produces seismic reports, flight creates anti-air tracking, enormous scale raises detection radius. Growth and mutation picks **do not themselves award DEFCON points**; real observed incidents do. Persisted response pressure never implies forces magically recognise an unrelated newborn.

## 9. First-shipping mutation slice (curated 30)

These 30 form a **recommended first implementable gene pool**, mixing existing-style stat changes with a limited number of new generic powers. IDs/names come from the source. *Nothing here is claimed already built.*

| ID | Mutation | Core gameplay hook | Visible signal | Delivery |
|---|---|---|---|---|
| 1 | Splittongue Organ | Passive prey/resource tracking | Flicking tongue | First |
| 2 | Ecdysial Shedding | Timed armour window / recovery | Peeling scutes | First |
| 6 | Sub-dermal Osteoderms | Damage reduction | Back bumps | First |
| 7 | Acidic Saliva Gland | Corrosion on bite | Dripping jaw | First |
| 9 | Spike-Row Ridge | Contact retaliation | Back spikes | First |
| 12 | Scavenger Jaw | More biomass from eligible food | Broader jaw | First |
| 14 | Thermal Pits | Target indicator through low-light cover | Snout pits | First |
| 19 | Tail Club Node | Tail impact and stagger | Tail club | First |
| 20 | Camouflage Chromatophores | Concealment while still/slow | Reactive pigment | First |
| 22 | Hollow Bone Struts | Movement/acceleration with defence tradeoff | Slim limbs | First |
| 30 | Raptor Vision | Wider/longer target acquisition | Eye details | First |
| 36 | Wing-Spur Knuckles | Contact damage on dash | Elbow spurs | First |
| 39 | Pneumatic Air Sacs | Stamina and sprint endurance | Barrel chest | First |
| 42 | Dense Guard Hair | Resistance/thermal passive | Guard-hair overlay | First |
| 43 | Canine Hyper-Tusks | Bite penetration | Visible tusks | First |
| 47 | Adrenal Gland Hyper-Drive | Conditional low-health speed burst | Vein/emissive pulse | First |
| 49 | Sub-Cutaneous Fat Layer | Impact resistance with agility cost | Body morph | First |
| 57 | Nocturnal Tapetum Lucidum | Night perception | Eyeshine | First |
| 58 | Hibernation Torpor Node | Deliberate vulnerable healing stance | Curled/rest animation | First |
| 61 | Chitinous Exoskeleton (Tier 1) | Alternative armour identity | Chitin material/plates | First |
| 72 | Carapace Spikes | Contact damage / projectile deflect chance | Shell spines | First |
| 73 | Hydraulic Joint Fluid | Burst acceleration | Joint pulse | First |
| 81 | Mucus Slime Coating | Reduced slows/grabs | Gloss/slime | First |
| 85 | Shell Mantle (Conical) | Defensive shell stance, big mobility cost | Shell add-on | First |
| 88 | Bioluminescent Lure | Nearby prey attraction | Glow stalk | First |
| 90 | Toxin-Secreting Skin Glands | Punish melee contact | Warning colour | First |
| 95 | Electro-Reception Pores | Hidden nearby target reveal | Snout sensory sparks | First |
| 99 | Degenerative Acid Slime | Low damage to metal surfaces over time | Acid trail | First |
| 100 | Chimeric Flesh Matrix | Early cross-family mutation flexibility | Pattern patchwork | First |
| 441 | Ambush Predator Patience | First-strike bonus | Prowl anticipation | Retier / First |

**Deferred from first-slice despite being in the first 100:** hexapod/octopod rigs (#68–69), excavation (#15/#52/#75), functional wings/gliding (#29), persistent web ropes (#65), aquatic jet movement, swarm allies. They need gameplay/system foundations rather than simply a new stat line. These remain catalogue mutations, not cuts.

### Second wave — visible combat and Predator epoch

Prioritise **#101 Titan Jaw Extension**, **#105 Thickened Scute Armor**, **#106 Venomous Spit Gland**, **#109 Apex Predator Roar**, **#112 Mandible Crushers**, **#116 Crushing Tail Flail**, **#143 Rhino-Class Nasal Horn**, **#145 Thickened Hide**, **#148 Crushing Great-Ape Fists**, **#150 Gluttonous Metabolism**, **#161 Chitinous Exoskeleton Tier 2**, **#168 Acid-Spray Gland**, **#173 Hydraulic Leg Pistons**, **#176 Chitin Regeneration Nodes**, **#190 Electro-Shock Organ**. This wave proves attack families, damage classes, crowd reactions, special cooldowns and car-feeding eligibility. Don't declare full 101–200 playable just because a few reference components exist.

### Third wave — Monster epoch

Prove city-scale interaction using **#201 Atomic Breath Core**, **#202 Tectonic Plate Armor**, **#206 Seismic Stomp**, **#208 Regenerative Nuclear Core**, **#218 Acid-Spitting Throat Gland**, **#242 Seismic Ground Pound**, **#300 Chimeric Titan Apex Matrix**. Powered flying forms (#203, #221) require a separate camera/performance/collision milestone, not just a wing sprite.

### Late wave — Cataclysm and Cosmic/Apex

Convert global-scale descriptions into bounded world-region events and environmental simulations where possible. Remap useful everyday traits from IDs 421–480 to sensible earlier stages. Keep truly interdimensional features (#401–420) and Omega (#481–490) as optional post-launch content **unless** a small, self-contained capstone can be built inside current mechanics. Preserve #500 as the long-term prestige endpoint.

## 10. Proposed mutation data contract

A production mutation should eventually contain at least:

```json
{
  "id": 7,
  "key": "007_acidic_saliva_gland",
  "name": "Acidic Saliva Gland",
  "availability": {"min_evolution": 0, "affinity": ["reptilian", "chemical"]},
  "compatibility": {"socket": "jaw_gland", "exclusive_with": []},
  "effects": [{"kind": "apply_status_on_bite", "status": "corrosion", "rank": 1}],
  "visual": {"socket": "jaw", "overlay": "acidic_drool", "vfx": "acid_drip"},
  "balance": {"energy_cost": 0, "cooldown_seconds": 0},
  "status": "design_not_implemented"
}
```

The entry above is an **illustrative proposed definition**, not an extraction of existing source code. Every mutation must then pass validation: unique ID, valid tag and compatible socket, no impossible prerequisites, a supported engine hook, visible feedback, mobile-friendly controls (if active), balance constraints, save/load round-trip, no frame spikes in crowded combat.

**Catalogue workflow:** retain source descriptions in `kaijustomp_mutation_catalog_500.json` read-only; add a **separate** `mutations_runtime.json` for playable tuned definitions. Do not silently rewrite original mutation source when balancing. Track implementation coverage separately: designed / defined / integrated / visually represented / tested / playable.

## 11. Delivery milestones and gates

**M0 — Protect current game and baseline.** Audit actual repo before coding. Branch off baseline; run existing Android build, unit tests and on-device combat/feeding/size checks. Preserve head collision, building cracks, eventual object destruction and sprint control.

**M1 — Data foundation.** Import all 500 IDs into read-only codex/catalogue, fix ID/key constraints, build prerequisite/compatibility schema and validation; expose only implemented entries as selections. Add unlock reasons to codex rather than false claims that all content is available.

**M2 — 30-mutation vertical slice.** Implement first wave generic handlers, passive/on-hit/conditional mutations and exact visual cues; persist full mutation state; test mutually exclusive body sockets and speed/armour scaling.

**M3 — Persistent life cycle.** Save region deltas, corpse, genealogy, player codex, world restoration and strategic response knowledge. Start fresh balanced hatchling after death, preserving *knowledge rather than maxed stats*. Ensure objectives remain viable in damaged zones.

**M4 — Sector response and progression.** Implement local alert separate from strategic DEFCON, journey-based dispatch and fatigue/logistics. Tune time-to-first-cop, time-to-first-car, time-to-SWAT and the inability of a new hatchling to be instantly target-locked by old military responses.

**M5 — Predator combat and vehicle feeding.** Implement second-wave attacks and physical vehicle destruction, separate biomass eligibility from damage. Test vehicle thresholds and stealth alternative path.

**M6 — Streamed city/Monster phase.** Prove 2×2 km streamed test; gradual extension beyond beach; meaningful buildings, infrastructure, landmark history, high-tier abilities and performance on a midrange Android device.

**M7 — Endgame content.** Add catastrophe and prestige transformations. Apply region-scale bounds or mark huge-scale concepts as future expansion. Test creature lineage continuity through multi-life play.

### Release criteria, not just code completion

- 30 genuinely different, balanced and *visibly legible* first-slice mutations, with no fake descriptions.
- At least three distinct successful build routes: small fast, heavy durable, chemical/control.
- A player who does nothing cannot summon beach SWAT through passive elapsed time; dispatched units move from real locations.
- A complete death -> new creature -> retained world -> retained codex loop works through app restart.
- Three rolling objectives continuously generate accessible hunt/destroy/explore opportunities.
- Small, compact, powerful build completes meaningful objectives alongside giant build.
- All 500 entries are searchable in a game-data/codex index with **truthful design/availability status**, not inaccurately advertised as playable.
- No APK release until Android build, smoke tests, save migration and device performance checks pass.

## 12. Recommended decision for this round

**Approve the catalogue-as-gene-pool architecture.** Lock a 30-mutation first slice, build the reusable mutation runtime, connect it to persistence/DEFCON, then expand in waves. Do **not** start modelling 500 full body assets or offer all 500 as pickable cards in the next build.

This route preserves the entire source list, the existing game feel and the aspirational kaiju endgame while making the next playable milestone achievable.
