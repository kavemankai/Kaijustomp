# KaijuStomp — Nine-Form Gradual Evolution
## Player-facing Game Design Document (GDD v1.0)

**Status:** Approved direction and proposed detailed rules; not a statement that these features are implemented. 17 October 2026.

**Design sources:** The nine EVO 1 concept directions developed together; `kaijustomp_evolution_tree.md` (500 mutation concepts); `KaijuStomp_500_Mutation_Integration_Plan.md`; earlier agreements on a persistent world, new organism after death, mobile-first action, sector-origin police response and premium standalone progression. Current connected GitHub default-branch implementation is a Godot 4 prototype; the code may lag the gameplay video or another active branch. Changes proposed in this document require integration and testing.

---

## 1. One-sentence vision

**Begin as an adaptable coastal hatchling; grow into a reptile, biomass horror, snake, bird, crab, spider, ape, worm or mole—or deliberately hybridise them—while every life physically reshapes both your creature and a world that remembers your actions.**

### Experience pillars

1. **Evolution is an action, not a class menu.** Players never choose a permanent species at birth. Genes, habits and anatomy form an identity over time.
2. **The creature is the build.** Mutations alter silhouettes, movement, attacks, feeding and survival—not merely abstract statistics.
3. **Pure and hybrid forms are both worth playing.** Pure forms are coherent and efficient; hybrids offer unusual toolsets and tradeoffs.
4. **Small is not failed.** Growth in physical scale is optional. A fast, poisonous or stealthy small creature can reach meaningful goals.
5. **Every lifetime matters.** The organism is mortal, while biological discoveries, altered places and humanity's strategic learning persist.
6. **The response is grounded.** Defences respond to witnessed events and travel from world locations. Selecting a mutation is not an automatic DEFCON increase.
7. **Complete premium mobile game.** The campaign should provide goals, mastery and an ending—not paid rerolls, gacha, forced advertising or progression manipulation.

### Primary player loop

```
Quiet coast / new hatchling
    -> Hunt, destroy and explore
    -> Acquire G-cells / biomass and meet an evolution opportunity
    -> Choose one of three eligible mutations
    -> Genome, ability and physical body change
    -> Evolve the world encounter and military response
    -> Survive, adapt and deepen a pure form or hybrid
    -> Die (or attain an apex / campaign milestone)
    -> Archive discoveries, persist world consequences
    -> New creature, new genetic possibilities
```

Existing auto-shooter and Atomic Nova mechanics should remain playable while this develops. A later design may widen combat, but must not silently replace the core controls or kill the current game feel.

---

## 2. The nine biological destinations

| Lineage | Visual signature | Gameplay specialty | Primary locomotion | Essential EVO 1 read |
|---|---|---|---|---|
| **Reptile** | Scales, tail, dorsal plates, snout | Generalist predator, defence, bite and breath precursors | Quadruped, later optional biped | Teal coastal reptile, cream belly, orange back ridges |
| **Biomass** | Flesh sacs, tendrils, irregular growth | Regeneration, assimilation, organic hazards | Crawler / quadruped | Lean creature with small fleshy protrusions, not a huge blob |
| **Snake** | Elongated trunk, coil, hood, fangs | Constrict, venom, flexibility and narrow traversal | Slither | Small red/cream serpent with raised head |
| **Bird** | Beak, feathered wings, crest, talons | Speed, leap/glide, aerial positioning | Biped, glide later | Proto-raptor bird, not automatically fully airborne |
| **Crab** | Carapace, pincers, broad silhouette, side legs | Defensive armour, block/grapple, aquatic efficiency | Multi-leg lateral | Compact hard-shelled coastal crab |
| **Spider** | Eight-leg cues, eyes, fangs, spinnerets | Webs, climbing, control and ambush | Arachnid | Low, distinct eight-legged silhouette |
| **Ape** | Long strong arms, fists, broad chest | Striking, lifting, throws, climbing | Knuckle/biped | Small muscular furred primate |
| **Worm** | Segments, radial mouth, no fixed limbs | Burrow, devour, breach and terrain denial | Undulate / burrow | Short segmented earthworm/monster breaking soil |
| **Mole** | Huge digging claws, fur, compact snout | Digging, collapse, ambush, defensive earthworks | Low crawler / burrow | Small brown digger with standout foreclaws |

**The 3×3 EVO 1 roster art is the visual direction, not an implementation-ready sprite sheet or rig.** The nine silhouettes should remain recognizable even when a player changes colour, mutation grade or size.

### No character-select trap

A hatchling has a familiar low-poly coastal-game silhouette, but **no permanent genetic Reptile lock**. An early environmental or cosmetic reptilian lean is acceptable, provided the other eight forms remain honestly attainable. On later lives, the player can select a small inherited *predisposition* from previously discovered genes; that is not a full-form selection.

---

## 3. Three genetic layers and one world layer

### A. Active genome — this one creature

- Nine nonnegative raw affinity scores, a history of gene choices, expressed body-plan and anatomical slots.
- Ability loadout, equipped and passive mutations, mutation ranks, current morphology, physical scale, cohesion.
- Evolution stage and queued evolution choices. Cleared at final death.

### B. Lineage archive — across creatures

- Discovered genes and parts, codex, successful pure/hybrid records, best achieved mastery, cosmetic variations and limited unlocked predispositions.
- Carries **access and knowledge**, not the dead creature's complete genome, armour or maximum stats.
- Prefer guaranteed discoverability / broader build options to permanent flat combat inflation.

### C. Epigenetic context — short-term environmental bias

- The creature's current biome, damage types faced, feeding history, combat behaviour and style of movement.
- Makes different relevant gene choices *more likely*. It is explicitly shown as a draft bias where useful and normally resets on death.

### D. World and military knowledge — external persistence

- District destruction, recovered areas, notable landmarks, travel routes, logistics, region discoveries, regional alerts and strategic countermeasure research.
- Personal/individual contact tracking should not magically transfer to a newborn as if the military already knows its location.

---

## 4. How genetic affinities change

### 4.1 Raw scores versus displayed percentages

Each creature has nine raw scores, initially zero. A mutation adds raw affinity in one or more tracks. **Displayed affinity percentage** is `100 × affinity[form] / max(1, sum(all 9 affinities))`, rounded for presentation only. A creature with no points is displayed as *Unformed*; the UI should show all nine at zero rather than assigning a false 100% identity.

**Proposed starting tuning** (design values, not extracted from the 500-mutation catalogue):

| Cause | Affinity effect | Safeguard |
|---|---|---|
| Clear primary-family mutation | +4 primary | Show it on the choice card |
| Secondary-family anatomy | +1 or +2 secondary | Explicit tagging, no secret grant |
| Cross-form bridge/stabiliser | +1/+1 to specified forms, or none | Does not force an unwanted identity |
| Repeated relevant behaviour | Up to +2 to one family **per evolution interval** | Diminishing returns; no idle/farming loops |
| Biome / local events | Alters offer weights, **not** permanent raw points | Biomes are opportunities, not penalties |
| Inherited predisposition | Slight draft-weight bias, not free live combat affinity | Bounded, visible and optional |

**Example:** Chitinous Exoskeleton +4 Crab, +1 Spider; Feather Array +4 Bird; Constrictor Spine +4 Snake, +1 Worm. These affinity mappings are a *new nine-form design layer* and must be authored in runtime data; the source list did not define numeric nine-way affinity values.

Players must be able to preview affinity changes before choosing. Scores cannot become negative. Behavioural credit is awarded only for verified game events (successful burrow, real climb, genuinely detected prey etc.), not repeated button taps or idling.

### 4.2 Form detection — candidate thresholds

Determine classifications *after* anatomy is resolved. At low totals, avoid volatile labels.

| State | Suggested requirement | Presentation |
|---|---|---|
| **Unformed** | Total raw affinity < 12 | Common hatchling, mixed primitive traits |
| **Emerging [form]** | Total ≥12, leading form ≥35% | Primary traits start becoming recognisable |
| **Consolidated [form]** | Total ≥20, top family ≥50%, ≥1 signature functional part | A readable single-form identity |
| **Hybrid candidate** | Total ≥20, top two each ≥25%, combined ≥65% | Show “hybrid forming” forecast, even if parts incomplete |
| **Expressed hybrid** | Hybrid candidate plus one distinct functional/visible part from each lineage | Mixed form name and dual icon |
| **True hybrid / mastery** | Expressed hybrid plus paired synergy and growth/complexity gate | Strong hybrid bonus/tradeoff, not a free double upgrade |
| **Tri-form chimera** | Three each ≥18%, late mastery unlock and anatomy support | **Deferred**; not required in initial implementation |

If top-form and dual-form thresholds overlap, prioritise a valid **expressed hybrid** over a pure label. If the requisite anatomy is missing, use *candidate* wording, not a misleading completed-hybrid title. Store identity as **derived state**, not a hand-edited mutable flag. The numbers above are starting tuning parameters and should be stress-tested rather than treated as immutable lore.

### 4.3 Player control of the draft

At each evolution opportunity offer three **distinct, legal** options when the eligible pool permits:

- **Strengthen:** reinforces one of the top expressed families.
- **Explore:** introduces or reinforces another family, enabling hybrid routes.
- **Adapt:** utility, stabilisation or mobility/feeding response to recent play.

There is no guaranteed rare pull and no paid reroll. If pools overlap, deduplicate; if a lane has no legal choices, substitute another legal option. Never offer a gene whose mechanics do not exist. The UI may provide a normal non-monetised *limited reroll* later only if balanced and earned in game.

### 4.4 Unlock versus expression

**Discovered** means the gene is in the archive; **offered** means the organism can legitimately choose it now; **equipped** means it occupies a slot or passive system; **expressed** means it has a visible/functional effect. These are separate.

---

## 5. Mutations, rarity and the source 500

The original source numbers **1–500 are permanent catalogue IDs, not 500 mandatory level-ups**. Use the existing catalogue and separate runtime implementations:

- Source catalogue: description and artist reference, immutable by balance work.
- Runtime gene definition: affinity, prerequisites, exclusions, anatomy, effects, cost, rank and availability.
- Coverage record: concept-only / defined / integrated / visualised / tested / playable.

Rarity is a *frequency / conditions concept*, not a cash economy. Starter expressions such as fur, scales, small pincer buds or early tendrils should be available fairly often; specialised advanced powers require anatomy chains and environmental or maturity gates.

### Example prerequisite chains (source catalogue IDs preserved)

| Destination | Suggested source-gene route | What changes physically | Gameplay result |
|---|---|---|---|
| Reptile | #6 Osteoderms → #9 Spike-Row Ridge → #105 Thickened Scute Armor | Bumps → back spines → overlapping plates | Damage absorption and retaliation |
| Biomass | #81 Mucus Coating → #100 Chimeric Flesh Matrix → #185 Regenerative Limb Matrix | Gloss → patchwork tissues → regenerative buds | Recovery and hybrid flexibility |
| Snake | #11 Pit Viper Fangs → #56 Prehensile Tail → #184 Constrictor Body Coils | Fangs → flexible tail → muscular trunk | Venom and hold/crush control |
| Bird | #21 Proto-Feathers → #22 Hollow Bone Struts → #29 Gliding Patagium → #121 True Flight Patagium | Fuzz → lighter frame → membrane/wings | Leap, glide, later tested flight |
| Crab | #61 Chitin Exoskeleton → #72 Carapace Spikes → #161 Plated Exoskeleton | Shell → spikes → interlocking armour | Tank/control, movement tradeoff |
| Spider | #62 Compound Ocelli → #65 Silk Spinneret → #69 Octopod Legs → #163 Web Launcher | Eyes → spinnerets → legs → launcher | Detection, webs, traversal |
| Ape | #44 Shoulder Girdle Rotator → #48 Brachiating Forelimbs → #141 Gorilla Shoulder Vault → #148 Great-Ape Fists | Broad joints → long arms → shoulders → fists | Grab, climb, melee smash |
| Worm | #84 Muscular Foot → #86 Radula → #164 Segment Proliferation | Crawling sole → radial rasp → longer segments | Crawl, feed and breach |
| Mole | #15 Clawed Digging Spades → #52 Burrowing Fore-Claws → #75 Burrowing Rostrum → #169 Drill Rostrum | Spades → huge claws → shovel/drill snout | Burrow and sabotage |

**Important:** The arrows describe *proposed unlock chains*, not existing prerequisites in the original list. Mobility modes such as burrow and flight require collision, navigation and AI work; showing a feather or claw model is not enough to claim those abilities are playable.

---

## 6. Physical body and visual anatomy

### 6.1 Anatomy hierarchy

```
Creature
  Body plan (quadruped / biped / serpentine / crawler / arachnid / lateral / burrower)
    Core mesh proportions, physical collider(s), primary movement
  Head + mouth/jaw + neck
  Torso/core + surface covering
  Forelimbs + hindlimbs + extra limbs
  Dorsal + tail/rear
  Organ attachments and effects
  Pose/movement animation profile + optional secondary move mode
```

Each equipped mutation declares **which sockets it uses** and whether it adds, modifies or replaces an occupied part. One slot cannot silently hold incompatible full replacements. A feather covering can coexist with a scaly patch, but a forelimb cannot simultaneously be an uncompromised fist, fully operational pincer and fully operational wing unless a late special hybrid anatomy provides a viable split or secondary limb.

### 6.2 Body plan is a separate choice

- The player may grow in scale or stay smaller; scale changes collider, camera constraints, damage, food eligibility, visibility and movement costs.
- Morphology transitions are **earned opportunities**, not mandatory E5 quadruped / E22 biped events.
- Secondary movement is a specific acquired capability: e.g. ground + glide, crawler + burrow or multi-leg + wall climb.
- Any new body plan must keep the current touch movement usable and feel responsive.

### 6.3 Rendering rules for the actual game style

Use KaijuStomp's existing **procedural low-poly creature meshes and flat vertex colours / shared atlas**. Maintain clean readable silhouettes at gameplay camera zoom, affordable geometry, modest particle counts and clear colour separation. The promotional 3×3 illustration is inspiration, not a requirement for 2D sprites in a 3D Godot game.

Visual-read priorities:

1. **Silhouette first:** distinctive wing, coil, claw, limb array, shell, arm/torso mass.
2. **Surface second:** feather, scute, fur, chitin, veiny biomass or segmentation.
3. **Attack tell third:** glowing venom gland, throat inflation, spinning claws, raised webspinner.
4. **Colour last:** recolours cannot stand in for fundamentally different anatomy.

For a genuine hybrid, use one legible *primary body plan* plus one or two expressive secondary anatomy modules. Avoid stacking nine random decorations onto one unreadable blob.

### 6.4 Collision and gameplay truth

Art is not physics. If a tail visually grows, it only deals damage where an actual hitbox or attack trace exists. Extra legs don't imply climbing until a controller, surfaces and camera support it. Shells that make the creature larger must respect door clearance and object destruction. Burrowing must not pass through indestructible map borders or skip responses without leaving observable seismic evidence.

---

## 7. Hybridisation

### 7.1 A hybrid has three requirements

1. Two distinct affinities pass a threshold.
2. At least one *expressed, legible, functional* signature from both forms is present.
3. The body plan and sockets form a legal anatomy or have a supporting bridge gene.

A numeric affinity split alone is **not** a true hybrid. Hybrids are not automatic double-stat classes.

### 7.2 Cohesion, compatibility and tradeoffs

**Genetic Cohesion (0–100)** represents anatomical reliability. It must be player-visible and predictable; not a random punishment meter.

Proposed demonstration scoring: begin at 100; subtract fixed penalties for unresolved slot conflict (candidate -12), unsupported secondary motion (-8), unsuitable body mass vs lift (-6); add explicit stabiliser/bridge recovery up to +6 per relevant gene, clamped to 0–100. **No gene may ship with an unavoidable unresolved conflict.** The offer system must indicate what it replaces, what mobility is lost and whether a supporting bridge is required.

| Cohesion | Gameplay interpretation |
|---|---|
| 80–100 | Stable, normal efficiency |
| 60–79 | Specialized tradeoff: increased stamina/cooldown cost, shown directly |
| 40–59 | Large incompatibility: block *new* contradictory mutations, present stabiliser opportunities |
| Below 40 | Should only be reachable through explicit late-risk experiments; never surprise-disable touch controls |

Most stable hybrids should live at 75–95 cohesion. Avoid forcing every hybrid to be objectively worse than a pure build; pair-specific synergies reward well-engineered mixtures. All penalties and bonuses are subject to playtesting.

### 7.3 Featured hybrid routes

| Hybrid | Visual composition | Capability | Weakness / counterplay |
|---|---|---|---|
| **Reptile + Bird** (Sky Drake) | Scaled torso, proto-wings, beak/snouted variant | Dash and glide into bite/tail strike | Low lifting capacity if heavily armoured |
| **Ape + Crab** (Shellback Titan) | Ape posture, arm-pincers, dorsal shell | Grasp vehicles, block and crush | Slow turning, exposed legs |
| **Spider + Bird** (Talon Weaver) | Eight-legged crawler with feathered winglets | Rooftop drop and web trap | Fragile under concentrated ranged fire |
| **Worm + Mole** (Burrow Colossus) | Segmented body, huge tunnelling claws | Tunnel then erupt beneath defences | Seismic detection and restricted hard ground |
| **Snake + Biomass** (Tendril Serpent) | Coiled serpent with organic grasp tendrils | Constrict plus regeneration/status pressure | Vulnerable to AoE, heat/chemical counters |
| **Reptile + Crab** (Fortress Drake) | Reptile frame and carapace/pincer | Armour with close-range impact | Slower acceleration |
| **Ape + Spider** (Wallbreaker) | Broad ape core with auxiliary spider legs | Climbing + heavy shove | High endurance use when vertical |
| **Worm + Biomass** (Assimilator) | Ringed digestive crawler with sacs | Feed on organic detritus and heal | Vulnerable when exposed above ground |

Other combinations are **possible design targets**, not promises that all 36 pairings will be fully animated in the first release. The nine destinations produce exactly **36 unordered two-family pairs**. Three-way fusions are a later milestone.

### 7.4 All pair combinations as long-term discovery slots

| Primary | Other possible partner families |
|---|---|
| Reptile | Biomass, Snake, Bird, Crab, Spider, Ape, Worm, Mole |
| Biomass | Snake, Bird, Crab, Spider, Ape, Worm, Mole |
| Snake | Bird, Crab, Spider, Ape, Worm, Mole |
| Bird | Crab, Spider, Ape, Worm, Mole |
| Crab | Spider, Ape, Worm, Mole |
| Spider | Ape, Worm, Mole |
| Ape | Worm, Mole |
| Worm | Mole |

Rather than assign arbitrary 'can't mix' rules, treat compatibility as a function of locomotion, body-support, competing sockets, mass and bridge genes. An unusual Bird + Mole body should be challenging to engineer, **not forbidden**. This preserves the fantasy of player invention.

---

## 8. Progression: identity, scale and complexity are separate

| Evolution reference | New player-facing milestone | Illustrative major changes | Size policy |
|---|---|---|---|
| **E0–E4** | Primitive hatchling | First covering, small claws, glands, eyes and slight outline changes | Stay compact |
| **E5–E10** | Juvenile divergence | First clear silhouette/motion cues; candidate family emerges | Growth optional |
| **E11–E21** | Predator consolidation | First powerful signature ability; early accent hybrids | Small builds viable |
| **E22–E34** | Kaiju awakening | True hybrid milestones, complex replacement parts, advanced traversal | Buildings/vehicle interactions depend on real size and digestion |
| **E35–E39** | Apex expression | Mastery of coherent pure/dual-family builds | Can remain smaller by investing elsewhere |
| **E40+** | Cataclysm / later prestige | Late form-specific threats and world events; tri-form tech in expansion | Avoid unconstrained planetary powers in city game |

Source references for optional physical size **1.20× (E5), 1.49× (E10), 1.90× (E16), 2.51× (E22), 3.12× (E28), 3.74× (E34)** remain inspiration / tuning checkpoints. E numbers track *mutation opportunities*, **not guaranteed growth**. Legacy consumption thresholds ~2.45× for vehicles and ~3.35× for buildings are tentative size/organ gates to test, not guarantees all things are edible at those evolution counts. Damage, demolition and nutrient digestion are three distinct capabilities.

### Small-form parity

A small-form player invests otherwise-spent growth choices into mobility, senses, specialisation, stealth, status effects or precision. They can reach meaningful objectives and survive for a full run using skill, even though they cannot trample skyscrapers. Objectives adapt to reachable targets rather than offering impossible demolition goals.

### Mastery goals

- **Nine first forms:** express each of nine family identities at least once.
- **Nine apex records:** reach each form's high-mastery build without a required giant size.
- **Hybrid discoveries:** record meaningful expressed pairings, starting with eight featured designs.
- **Genome journal:** show mutations, body changes, notable defeats, surviving world scars and human counters.
- **Prestige idea:** source mutation **#500 The Genesis Seed** supports a deliberate next-world lineage cycle, not a forced restart on ordinary death; full extra planets are beyond initial release scope.

---

## 9. Mobile user interface and screens

### 9.1 Mutation choice (portrait-first, pauses solo combat)

```text
┌──────────────────────────────────────┐
│ EVOLUTION 12          [Genome ▸]     │
│ Emerging CRAB / SPIDER               │
│ Crab 38% · Spider 31% · Other 31%    │
│ Cohesion 88 · Body: lateral crawler  │
├──────────────────────────────────────┤
│ 1  CARAPACE SPIKES     [STRENGTHEN]  │
│ +4 Crab  · Shell / dorsal            │
│ Retaliation on contact               │
│ Preview: dorsal spikes              │
├──────────────────────────────────────┤
│ 2  SILK SPINNERET      [EXPLORE]     │
│ +4 Spider  · Rear organ              │
│ Enables basic sticky trap           │
│ Preview: spinneret tail             │
├──────────────────────────────────────┤
│ 3  CHIMERIC MATRIX     [ADAPT]       │
│ Cross-family compatibility           │
│ Preview: mixed surface pattern      │
├──────────────────────────────────────┤
│           [ VIEW BODY ]              │
└──────────────────────────────────────┘
```

**Illustrative UI only:** exact card effects, labels and unlocked state come from live runtime data, not the source 500 descriptions alone. Each card gives: named change, affinity arrows, actual gameplay effect, occupied/replaced slot, estimated cohesion delta, silhouette preview and affordability. No hidden penalties.

### 9.2 Genome / body page

A stylised current creature model remains in the centre. Touch a body region to inspect its gene origin, equipped ability and replacement tradeoff. Show nine simple horizontal affinity bars on a secondary tab rather than an unreadable nine-axis radar on a small phone. Put the current primary/secondary family name and form-stage marker above. Use visual emphasis for the highest two families, never hide remaining affinity scores.

### 9.3 Lab / after death

```text
CREATURE 07 — DEAD, NOT RESET
Form: Sky Drake (Reptile / Bird)
Last sector: Seafront Shops
Cause: suburban anti-air patrol

NEW GENES FOUND  +3
HYBRIDS DISCOVERED +1
WORLD EFFECTS       Waterfront damaged
HUMAN ADAPTATION    Radar coverage increased

[ SPECIES ARCHIVE ] [ WORLD HISTORY ]
          [ SPAWN NEXT HATCHLING ]
```

The “Defibrillator revive same dead creature” legacy prototype flow needs a design migration. A last-chance *pre-death survival mutation* could remain, but **once the creature is declared finally dead, next play is a new organism**. Never erase the world merely to display this screen.

### 9.4 On-screen play

Maintain the thumb-friendly left-side movement and existing right-side special-action placement. Show a concise current form label only when it changes or in an optional details page; don't crowd combat with nine bars. Control tutorials appear for *new* movement modes, especially glide, burrow and wall climb. If a new mode is not genuinely implemented, it cannot be selected as a playable mutation.

---

## 10. A sample three-life experience

**Life 1:** Reptile-style hatchling picks Osteoderms then Spike Ridge, survives pistol patrols, investigates the harbour and becomes a compact armored predator. A spectacular death leaves a damaged pier and gene discoveries.

**Life 2:** A new common hatchling develops Mole traits from digging claws and a burrowing gene. The player avoids surface patrols, reaches a new district and eventually suffers from newly deployed seismic monitoring. The old pier remains damaged or under repair.

**Life 3:** A new hatchling blends Bird mobility and Spider control. It reaches an expressed hybrid with winglets and spinnerets; human defenders now have local knowledge of prior aerial and subterranean incursions, **but not instantaneous certainty about the newborn's identity or position**.

These are different solutions to the same persistent world, not nine separate level campaigns.

---

## 11. Combat, economy and world balance

**Never make nine forms into strict rock-paper-scissors.** Each should have at least one strong tool, one fair weakness, and a viable route through the early 20–30 minutes. Suggested asymmetries:

| Family | Strength | Counterpressure |
|---|---|---|
| Reptile | Reliable contact damage and moderate armour | Prolonged ranged siege |
| Biomass | Sustain and adaptability | Burst damage/attrition denial |
| Snake | Control and narrow spaces | Large open areas and concentrated fire |
| Bird | Repositioning and evasion | Radar / anti-air when genuinely observed |
| Crab | Frontal durability, guard | Rear/flank pressure and speed |
| Spider | Environment control | Open terrain and disruption of traps |
| Ape | Throws and structure abuse | Kiting and stamina drain |
| Worm | Unusual routes / devour | Hard substrates, seismic defence |
| Mole | Rapid breach and excavation | Sensors and above-ground exposure |

A mutation pick can increase attack visibility/noise. **It does not directly add DEFCON.** Dispatch follows actual observation and travel from beach foot patrols through suburban cars/SWAT to distant military bases. The existing prototype's auto-shooter and health pacing must be balanced with new survivability; adding permanent armour or fast movement indiscriminately would break both challenge and enemy pathing.

---

## 12. Recommended release sequence

| Release gate | Player-visible delivery | Not yet promised |
|---|---|---|
| **A — Playable genetic foundation** | Nine affinity tracks, honest three-card drafts, current creature identity, at least 9 clear visible family cues, saves and codex | Nine distinct locomotion rigs or all 500 genes |
| **B — Nine first forms** | Nine readable EVO 1 body plans and one practical signature behaviour per form | Every environment/motion combination |
| **C — Hybrid proof** | At least 3 tested pairing transformations, slot replacements and cohesion UI | All 36 fully unique hybrid assets |
| **D — Content expansion** | Curated first 30 actual mutations, 8 featured hybrid routes and responsive encounters | All 500 playable |
| **E — Campaign quality** | Persistent district changes, meaningful multi-life progression, regional countermeasures, broad traversal, completion objectives | Endless global / space simulation |

The first milestone should make a player say, **“My choices are changing what my creature is,”** even with only a handful of genes. Every later milestone must preserve that causal relationship.

### Acceptance from the player perspective

- I can intentionally steer toward any of nine identities without selecting a starting class.
- My most recent choice changes something I can see or do.
- I can make a small, effective build without mandatory giant/bipedal growth.
- An intended two-form build works only after both bodies have real expression, and the UI explains the requirement.
- The three options are understandable, usable and never fake abilities.
- A dead kaiju does not respawn as itself; the species archive and changed world remain.
- The military has a plausible response origin, travel delay and counterplay.
- The nine family roster fits the established pastel/low-poly, slightly isometric KaijuStomp style.

---

## 13. Locked, adjustable and deferred

**Locked:** nine families; gradual evolution; hybrid design; physical change; optional size growth; new organism after final death; persistent world; source 500 preserved; mobile-first; premium standalone philosophy.

**Adjustable:** numeric affinity gains, thresholds, chance curves, cohesion deductions, number of equipped organs, growth multiplier values, the exact identities of first playable genes, input layout details and postgame difficulty.

**Deferred:** guaranteed full flight for every bird variant, unconstrained procedural rigging, all 36 custom hybrid meshes, triple hybrids, literal planetary destruction and star-eating, thousands of active unit AI, a fully modelled new planet on prestige.

**Document change rule:** If the Codex implementation diverges from this GDD due to real project constraints, record the exact deviation, player consequence and proposed alternative before marking that feature complete.
