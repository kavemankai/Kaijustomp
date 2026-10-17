# KaijuStomp — Fixed Species, Open Specialisation
## Approved design pivot and autonomous Codex implementation handover

**Decision:** The player chooses exactly one biological base species at the beginning of each life. That base species is immutable until death. Within that species, mutations produce many distinct offensive, physical, defensive, and utility builds, including Fire Snake, Poison Snake, Fast Snake, and Heavy Constrictor. The player may combine compatible *abilities*, but never combine the base body plans of different species. Death permits choosing a different base species for the next life; the persistent world survives.

**Status:** Approved gameplay direction; **not implemented** by this document. This specification is for Codex to implement end-to-end rather than stopping after planning.

**Repository:** https://github.com/kavemankai/Kaijustomp

**Starting code:** `feature/morphology-traversal-polish` / draft PR #21. Review current HEAD before starting. At planning time HEAD was `932781cc463b3c5bba6db86639b076aca6c11680`; the known exported gameplay/build source for APK #261 was `9fefce4162ce5508ffdd718a4cd37145e6d7142c`. This branch depends on draft PRs #20 and #19. Do not work from default branch `claude/new-session-xzf17f`, the older `main`, or an unrebased prototype.

**Verified baseline:** [APK #261](https://github.com/kavemankai/Kaijustomp/releases/tag/morph-polish-261-9fefce4), [CI run #261](https://github.com/kavemankai/Kaijustomp/actions/runs/39074555544). The PR reports Godot 4.5 import and launch, 34 passing regression suites, Android APK integrity and source/art captures. It does **not** establish visual acceptance or physical-phone frame rate.

## A. Non-negotiable product rules

1. **Choose a single base at birth:** Reptile, Biomass, Snake, Bird, Crab, Spider, Ape, Worm, or Mole. Birth selection is shown for a new world/new life and again after death. No default species quietly assigned when the screen opens.
2. **Immutable base species for that life:** Species is a first-class saved property. Mutation affinity and behaviour never reclassify, rename, transform, or replace it. No automatic species change at any evolution milestone.
3. **Specialise freely:** Mutation paths are *capabilities*, not fixed classes. The examples Fire Snake, Poison Snake, Speed Snake, and Heavy Constrictor describe outcomes of picks, not a mandatory four-way class menu. Fire+poison, tank+fire, or fast+poison are possible when their anatomical prerequisites and costs permit.
4. **No species hybridisation:** No mixing of snake+bird, ape+crab, worm+mole, etc.; no secondary-form selector, no hybrid classification, no extraneous wings/tusks/pincers imported from a different animal body plan. Combining elemental/effect mutations is allowed.
5. **Body-plan physics remain fixed:** Snake and Worm grow chiefly in length and girth, remain axial and follow real paths. Bird remains avian and uses actual controlled gliding/flight when appropriately evolved. Mole/Worm retain their respective digging/burrow progression. Spider retains native climbing progression. Crab stays broad and low; Ape knuckle/biped motion; etc. Growth size is player-selected, not compulsory.
6. **Evolution changes gameplay and appearance:** Every playable mutation must (a) have an actual effect, (b) be visually fitted to the chosen species using the existing anatomy manifest / organic geometry, and (c) provide an accurate preview. Repeated ranks develop one organ rather than stacking duplicate decorations.
7. **Persistent world and lineage:** Buildings, vehicles, pending response, objectives, DEFCON adaptation, sector/mission states, world seed, and previous-life record persist across death. Every new creature starts with base abilities, not the previous creature's stacked combat strength. Long-term discoveries, per-species mastery, unlocked powers and historical achievements persist.
8. **Preserve existing user data:** An older save containing a living hybrid must remain loadable, finishable and resumable through a compatibility path. New lives use the fixed-species rules. Historic hybrid achievements stay readable in the archive as *legacy*, not as live recipes. Never silently truncate archives or reset a world.
9. **Mobile-first:** Godot 4.5 Compatibility renderer, portrait Android/touch, ARM64 exports, bounded draw calls, no mandatory downloads or new engine.
10. **No monetisation change:** Maintain complete playable premium-game progression. No gacha, pay-to-win mutations, forced ads, energy timers, or manipulative progression.

## B. What the current source actually does (audit confirmed)

This pivot should modify the existing systems rather than replace the game.

| File / system | Current behaviour | Required change |
|---|---|---|
| `scripts/beach/genetics/GenomeState.gd` | Nine raw affinity tracks, `ordered_families()`, hybrid identity classification and selectable foreign family seeds; save `VERSION=1`. | Authoritative `base_species`; new birth-selection state; mutation/build tags distinct from species identity; versioned compatibility for v1 saves. |
| `MutationDraft.gd` | `strengthen / explore / adapt` lanes, explicitly selects foreign-family exploration; a chimeric matrix boosts cross-family offers. | `offense / physique / survival` lanes with species-compatible options and deterministic three-choice drafts; no foreign anatomy incentives. |
| `GeneRegistry.gd` | Nine seed source IDs `6,100,11,22,61,62,44,84,15`; nine generics; 41 current playable source adaptations; 500 indexed source concepts. | Separate **species definition** from **mutation definition**. Keep all source IDs and catalogue contents; add species compatibility, prerequisites, tradeoffs, organ expression and progression lanes. |
| `AnatomyResolver.gd` | Allows multiple active signatures, `bridge` for heavy ape arms on axial forms, forelimb ownership and hybrid status. | One host anatomy only. Slot conflicts now happen **within** species. Retain old hybrid resolution only inside legacy-load compatibility where required. |
| `CreatureMorphology.gd`, `AnatomyManifest.gd`, `MutationExpressionLibrary.gd`, `OrganicGeometry.gd` | Recently polished all nine organic silhouettes, 243 generic/rank variants, hybrid support, axial skin. | Reuse polished base models/attachment points. Never create a foreign species skeleton. Express mutation organs locally (e.g., fire throat in Snake, hot pincer in Crab). |
| `BeachGenetics.gd` | Neutral genome after `new_organism_keep_world()`, `focus` steers toward another family; death appends archive. | Newborn `birth_pending`; atomic species selection and starting loadout; remove focus-as-species choice; new-life choice checkpoint in same world; old active-run compatibility. |
| `GeneticsHUD.gd` | LINEAGE draft family picker, 9-affinity percentages, hybrid archive, QA selector with secondary species. | Birth/species screen; specialisation-focused UI; no affinity pie or secondary species; QA base+build+growth tester. |
| `LineageArchive.gd` | `hybrids` discoveries, per-family mastery from raw score, death records hybrid label. | Species-specific mastery and recognised build achievements; keep legacy hybrid strings as historical artefacts without showing them as current progression. |
| `GeneEffects.gd`, `CreatureTraversal.gd`, `AxialTrail.gd`, `BodyDimensionsPolicy.gd` | Working movement/physics and selected gene effects (41 executable sources); some traversal unlocks are bound to foreign lineage genes. | Keep technical functionality but make traversal native to body and equipment; remove cross-species controllers, maintain mutation costs and contact physics. |
| `WorldState.gd`, `WorldStreaming.gd` | Outer save `WorldState.VERSION=1`; checks nested genome version **greater than 1** as unsupported; validates with `BeachGenetics.valid`. | **Critical:** migration to genome v2 must update this gate and validation in concert, with read/convert/checkpoint/rollback tests. Do not globally bump world-generator version without cause. |
| Existing regression suites | Some assert functional hybrids, dual sockets, affinity identity, and neutral new lives. | Retire/replace those **specific expectations** with fixed-base acceptance; keep all unrelated world, combat, growth, CI, save and traversal suites passing. |

**Catalogue provenance:** `data/evolution/kaijustomp_mutation_catalog_500.json` has 500 distinct source concepts. Most are not executable. A source entry's description is design reference, **not evidence that the attack exists**. Implement hooks, visuals, balancing and tests before marking `readiness=playable`.

**Special caution:** The current Biomass seed is `gene_100` (Chimeric Flesh Matrix). Keep the existing source ID and Biomass core phenotype for save compatibility, but eliminate the cross-family bridge/explore function. Change player-facing name/description only through a versioned alias or presentation mapping; do not change source IDs inside old saves.

## C. New core life loop

1. **New world / saved neutral newborn:** Run world initialization and load durable state, then present full-screen **Choose Your Creature** using nine visually recognisable silhouette cards. This modal pauses gameplay and cannot be skipped into a neutral, unspecified species. A small *Learn more* panel explains movement, signature power, durability and progression tendencies. No secondary base.
2. **Species selection:** Player chooses one base. Check that save is writable; atomically record `base_species`, life ID, genome version and an appropriate species seed/starting physiology. Checkpoint before running time resumes. Retry on save failure with no duplicate lineage transaction.
3. **Life begins:** Spawn that creature in a safe location in the existing world; resolve realistic collisions/ground clearance. All nine are viable at their smallest size. Grant biological base locomotion and one modest signature mechanic—not a late-game ultimate.
4. **Earn an evolution:** Pause/shed using current system; show three distinct legal picks, from **Offense**, **Physique**, **Survival/Utility** where possible. Cards show actual effect, rank, visual/body change, drawbacks, prerequisite, and which playstyle they complement. The draft is deterministic and persists while the evolution is pending.
5. **Choose a mutation:** Change creature stats, world interaction, combat capabilities and model. Remain the same species; refresh controller parameters without destroying existing positional/path history. Show a before/after creature preview at a fixed camera angle.
6. **Optional physical growth:** Award growth as an explicit mutation or other chosen investment, never at every evolution. It changes dimensions according to its host policy, with measurable mobility/feeding/reach/clearance costs and benefits.
7. **Death:** Save old life, discoveries and mastery; world remains as-is. Present **New Organism → Choose Your Creature** again. The next life can be another Snake, or any other of the nine, without wiping world history.
8. **Resume:** Mid-life saves resume as the already-chosen species. If the last state is `birth_pending`, reopen selection with the same world seed and archive, rather than quietly spawning a default reptile.

The species selection is intentionally **per life**, not irreversible account-wide. Repeating a species is expected and should benefit from modest persistent knowledge/unlock biases, not overwhelming inherited combat stats.

## D. Data model and deterministic rules

Implement this contract in a new schema revision with explicit validation. The following is a conceptual *record shape*; adapt it to actual GDScript serialization and incremental migration:

```json
{
  "version": 2,
  "birth_state": "active",
  "base_species": "snake",
  "life_id": 12,
  "growth_policy": "chosen",
  "ranks": {
    "gene_011": 1,
    "gene_017": 1,
    "speed": 2,
    "physical_growth": 5
  },
  "build_tags": {"venom": 4, "mobility": 2, "mass": 1},
  "draft_seed": 79123,
  "frozen_draft": [],
  "transactions": ["life_12_species", "life_12_evo_1"],
  "legacy_run": false
}
```

**Required invariants:**

- `base_species` is one of `GeneRegistry.FORMS` for `birth_state=active` and immutable for a life. `base_species=null` (or empty) is permitted only while `birth_state=birth_pending`, where no evolutions or actions can proceed. Do not select a species merely by sorting affinity scores.
- `legacy_run=true` is permitted **only** for migrated v1 organisms until they die; it keeps the old resolver, collision and mutation state intact. Normal v2 births cannot set it.
- Old nine-affinity values, `focus`, `behaviour`, `interval_credit`, and prior `hybrids` can remain in migration/audit metadata if needed for checksum/history, but must never cause a new v2 species switch.
- `build_tags` are **derived** from equipped mutation effects, or if stored are validated against those effects; they are not selectable independent buffs. Tags include heat, venom, mobility, constriction, armour, mass, regeneration, digging, flight, webbing, acid, stealth, etc.
- Use stable catalogue/source IDs and save keys; never recycle a previous source ID for a different power. Base ownership and compatibility are independent of catalogue flavour `source_family`.
- A species foundation (old seed ID) is allocated at birth once, not repeatedly offered as another animal's anatomy. If base seeds currently have up to 5 ranks, preserve in-species **mastery upgrades** under that same ID (ranks after 1) while prohibiting other species' base seeds.
- Every selectable mutation has `allowed_species`, `slot`, `prerequisites`, `incompatible_slots`/`tradeoffs`, `max_rank`, `lane`, an actual `effect_handler`, `source_id` (where applicable), and `expression_by_species` or host-neutral appearance rule. Adapt metadata into `GeneRegistry` or separate resource files; do not multiply code paths by a hardcoded 9×500 grid.
- Derived stats recalculate from base, mutations and growth modifiers; guard against cumulative multiplication on repeated `refresh()` or save reload. Cap movement speed, resistance stacking, regenerative healing, burning/poison stacks and physical collision dimensions with testable tuning values.
- Deterministic draft RNG seed combines immutable world/life seed, evolution index, explicit reroll count (if any), and stable mutation ID ordering; save frozen options and don't reroll on reopen/reload.

**World save migration:** 

1. Preserve outer world/object record, sector state, objects, objectives, NPC/vehicle events, pending evacuations, saved path, seed, backups and save writer. Migration must operate only on nested genetics and lineage data.
2. Since `WorldState.read_save()` currently rejects nested genome versions `>1`, update the future-version guard to accept **known version 2**, reject unknown future versions, and dispatch a narrow `GenomeState.from_record()` v1→legacy adapter. Do not weaken unrelated validation.
3. Existing v1 **active organism with ranks**: load and run as legacy (including active hybrid) until death. Preserve its frozen draft, organ expressions and extra locomotion for the remaining life; after death, ask for a new single base. Do not strip the current creature or recalculate its body by guessing the largest affinity.
4. Existing v1 **newborn with empty genome**: enter birth selection immediately within the same persistent world; keep its life ID.
5. Historic `LineageArchive.hybrids` strings remain readable as legacy discoveries (with a legacy label). New v2 lives write species and build-route achievements instead; don't write new hybrid combinations.
6. Make a valid recovery copy **before** conversion. Prove a conversion is idempotent, atomic and able to resume from failure; never overwrite a known-good backup with malformed or unsupported data. Keep version `999` as a hard unsupported read that does not overwrite source data.
7. `new_organism_keep_world()` must save `birth_pending` in the **same** world document, and save-selection/selection-close flows must never create duplicated life records or reset world objects.

## E. Species definitions and initial specialisation fantasies

No preset class lock. These are examples of viable emergent combinations, not menu subclasses. All nine species have their own baseline movement signature and at least four meaningfully different builds.

| Base | Movement / body rule | Example build fantasies |
|---|---|---|
| Reptile | Ground/kaiju stance and optional grown armor; tail stays functional. | Firebreather; plated siege lizard; fast hunting raptor; acid-jawed scavenger. |
| Biomass | Asymmetric organic ground mass; tendrils are Biomass anatomy. | Regenerative mound; corrosive spreader; tendril grappler; high-mobility amorphous stalker. |
| Snake | Head-led slither with coherent continuously following long body. Length growth dominates; never grows legs or stands upright. | Fire Snake; Poison Snake; Fast Striker Snake; Heavy Constrictor. |
| Bird | Avian legs, beak, wings; wing-growth/glide/flight must actually work. | Fast dive bomber; armoured soaring fighter; incendiary glider; stealth hunter. |
| Crab | Low broad shell with claws and lateral locomotion; no arbitrary shoulders/wings. | Fortress shell; giant pincer crusher; caustic claw; rapid skitterer. |
| Spider | Eight-legged chitinous body; wall climbing with hooks, web equipment. | Venomous wall hunter; web trapper; speed crawler; armoured spider. |
| Ape | Gorilla-like mass, knuckle/grapple/throw controller; hands remain hands. | Heavy puncher; boulder thrower; adrenaline berserker; armoured grappler. |
| Worm | Heavy axial segmented body, mouth first; tunnel/breach possible, never upright. | Giant devourer; poisonous siege worm; fast burrower; reinforced mantle crusher. |
| Mole | Compact foreclaw excavator; real burrowing at relevant stages. | Subterranean ambusher; wide-clawed crusher; armoured digger; seismic disruptor. |

Keep natural animation and collider constraints; only the original chosen species' anatomy may occupy core sockets. Host-specific offensive/specialization organs such as chemical sacs, heat glands or sensory protrusions are allowed if their gene grants them and the transition visually integrates into the body.

### Snake vertical slice — mandatory acceptance build set

**Fire Snake** (first new specialization vertical slice): use existing catalogue concepts rather than claim they're already executable. Candidate source **#115 Pyretic Gland (Primitive Fire)** enables heat generation and matures into a real short-range flame/heat discharge, potentially with later higher-tier fire organs. Create an actual combat effect with cooldown/heat cost, projectile or cone collision, building/vehicle fire interactions bounded by the existing damage and alert systems, visible throat vent/glowing scale evolution and proper resistant targets. Fire must not merely tint the Snake red. Its fire path should remain available to other species only when an anatomical expression and gameplay hook exist.

**Poison Snake:** build on already playable Snake seed **#11 Fangs of the Pit Viper**, then implement source **#17 Venom Sac (Neurotoxic)** as an independent specialization: venom meter or cooldown, target-class-specific DoT/slow and visible venom sacs/fang development. Biological responders vulnerable, vehicles protected unless an explicit corrosive adaptation is selected. Keep status effects capped and auditable.

**Speed Snake:** use existing generic `speed` ranks plus a host-specific maneuver/flexibility adaptation, with head steering rate, acceleration, lunge recovery and path-follow integrity scaled together. Thin the snake's silhouette appropriately rather than adding generic Bird-style feet or protrusions. Weakness: lower raw collision/armor efficiency or stamina costs, not arbitrary “fragile because fast” with no explanation.

**Heavy Constrictor:** select `physical_growth`, `strength`, `armour` and, when genuinely implemented, source **#184 Constrictor Body Coils**. Body becomes longer, thicker and visibly more powerful, gets obstacle-blocking/wrapping/crushing interaction (bounded and supported by world collisions), lower acceleration/tighter-turn capacity and more stamina cost. Larger body cannot just be a tall capsule or a uniformly scaled short snake.

**Optional combination:** a Snake may learn both Fire and Venom. It retains one head, one throat chain and compatible organ sockets. Explain competing heat/stamina/venom resource costs, and tradeoffs rather than arbitrarily forbidding combinations. The first slice must prove at least two specializations coexist without foreign body parts.

**Source availability is not runtime readiness:** IDs #115, #17, and #184 are present in the catalogue but were **not among the existing 41 playable source adaptations** at review time. Do not advertise Fire Snake, advanced venom sac or active constriction as playable until effects + art + tests pass.

### Specialisation budgets and slot rules

- Mutations should spend **evolution picks**, **organ-space capacity** (only for genuinely competing organs), **energy/stamina**, and/or measurable defense/mobility tradeoffs. Don't require arbitrary class gates.
- Introduce a small consistent organ conflict policy: one dominant jaw/throat effect at a time if their anatomy cannot coexist; multiple glands may share a body only when supported. Fire breath + venom bite is plausible: different delivery mechanisms. If organ conflict exists, display it before the pick; no hidden invalid rolls.
- Let mobility-specialization scale turning responsiveness but not break axle trail sampling or clipped head collision. Large body mass affects damage, acceleration and clearance; growth never unilaterally unlocks extra species movement.
- Rank presentation: acquired / developed / mature for visually meaningful traits; rank stats may continue where existing caps are greater. Avoid cosmetic duplication at each extra level.

## F. Evolution card and species UI specification

**Birth selection screen:** nine large individual portrait cards. Each card: name, distinct silhouette, 1–2 sentence movement fantasy, three grounded strengths, one limitation and key traversal identity. Use existing approved soft colourful coastal low-poly art and the polished procedural models; capture from Godot where possible. Portrait touch hit regions at least 48dp, legible on narrow portrait phones. `Confirm Creature` commits current species; back/close cannot resume a species-less life. Persist pending screen if app is killed.

**Mutation draft:** exactly three choices when eligible: 

1. **OFFENSE:** damage, delivery organ, status, siege, predator ability.
2. **PHYSIQUE:** growth, agility, thickening, armor, stamina, strength, reach.
3. **SURVIVAL/UTILITY:** sensing, regeneration, camouflage, traversal, situational resistance.

If a lane is empty because of prereqs/caps, select a unique legal substitute deterministically from other lanes; never duplicate card IDs or present unusable genes. A source gene tagged `reptile` in a legacy catalogue is **not** automatically a reptile-only species part. Explicit `allowed_species` controls eligibility, while the `expression_by_species` rules control how it is rendered. However, **foundation seed IDs** remain exclusive to their own base species. All abilities in any offered card must work on that base or the card must be excluded.

**Forecast content:** real effect and activation key, cooldown, expected damage/DoT, range, resource cost, +/− stat change, phenotype development, organ-slot conflict, next rank and max rank. Screen previews must not commit actual stats, mutate the genome, advance RNG or trigger world save writes. Persist offered cards through shed/pause/background/reload.

**LINEAGE / LIFE RECORD:** display permanent base species, actual current build tags (e.g. `SNAKE · VENOM / SPEED`), equipped genes, growth rank, previously unlocked/achieved build discoveries and available movement mode. Remove affinity percentages, “hybrid discoveries” as current unlock goals, foreign-family focus picker and second-animal QA selection. Archive can still show historic hybrid runs clearly marked LEGACY.

**Death/new life:** show world impact and species mastery earned, then nine base choices. `Same species again` is a convenience button, not an irreversible selection. Newborn starts with the correct starting anatomy, even if that species is not presently unlocked in the archive.

**Debug QA:** Choose one base species + select illustrative mutation builds + optional growth rank 0–18; test all nine species. QA must not write fake achievements/lineage discoveries or affect approved releases. Add one-button test recipes for Fire Snake, Poison Snake, Speed Snake, Heavy Constrictor and an intentionally mixed Fire+Poison Snake.

## G. Functional traversal and body-plan preservation

- **Snake:** preserve polished `AxialTrail` distance-sampled 97-ring skin, 220-point bounded history, sections and query areas; speed builds still follow path, high growth doesn't collapse tail. Test slow turns, sharp direction change, dead stops, resume, world chunk boundaries, obstructed tail, grown body damage origin. Do not add an upright step or idle leg sway.
- **Worm:** preserve chunky segmented style, actual longer/girth growth and underground entrance with visible surface effects. Never instantly disappear/teleport during entry; mouth attacks originate at head, segment damage from body.
- **Bird:** preserve powered flight and glide with stamina; wings remain avian; flight unlock from #29, #121, #122 when equipped. Not given to a Snake simply for learning a “fire” adaptation; no foreign Bird skeleton.
- **Mole:** preserve burrow controller unlocked through host-native digging adaptation (#52 once prerequisites are met), avoid foundation clipping, keep world persistence.
- **Spider:** preserve wall/roof traversal from #180 and supported collision surfaces, including camera orientation, transition and falling.
- **Other hosts:** avoid accidentally granting locomotion from unrelated species because of old `focus`, affinity or hybrid ownership. Biological ability inheritance must be explicit and visually valid.

## H. Implementation sequence and acceptance checkpoints

### Phase 0 — Audit and baseline (no gameplay changes)

- Checkout latest `feature/morphology-traversal-polish`, create a new branch e.g. `feature/fixed-species-specialisation`; avoid touching `main` or approved APK tags.
- Record exact branch SHA, dependencies, current test suite results, Godot 4.5 import/smoke, APK #261 benchmark and existing save fixtures.
- Inventory mutation definition slots, actually implemented effects, original seed genes, anatomy renderer and species/hybrid selectors. Determine which existing 34 tests assert hybrid behavior.
- Maintain `docs/evolution/FIXED_SPECIES_CHANGELOG.md` and `docs/evolution/FIXED_SPECIES_HANDOVER.md` from the first commit.

### Phase 1 — Species authority and save safety (must pass before UI)

- Implement v2 `GenomeState` with immutable `base_species` and explicit `birth_pending`, preserving legacy-v1 adapter. Update `WorldState` nested-version guard and `BeachGenetics.valid` consistently.
- Preserve freeze/draft, rollback, backups, snapshots, atomic new life, version999 unsupported, corrupt-save fallback. Ensure historical hybrid life resumes in legacy mode; new births never inherit legacy hybrid rules.
- Add life-state unit tests: start pending, select once, no reselect, crash between selection and write, recover, death create pending, old hybrid lives, legacy neutral lives, archived hybrid metadata, wrong/future records.

### Phase 2 — New organism selection and identity UI

- Add nine species cards with proper art, actual body silhouette and movement descriptions. Ensure selection appears on new game/after death/resuming pending selection and blocks physics while pending.
- Grant correct exclusive base seed once at birth, preserve all nine starting-body silhouettes; remove automatic unformed run from the new rule, but retain legacy resume compatibility.
- Replace old free-form lineage focus and hybrid archive UI with species build UI. Keep a compact ability/character screen on phones.

### Phase 3 — Mutation taxonomy and legal deterministic drafts

- Refactor mutation metadata to `allowed_species` + category + organ expression. Separate source catalogue provenance from live runtime readiness. Retain IDs and existing 41 working source adaptations where compatible.
- Convert drafting to offense/physique/survival, with deterministic lane replacement, prerequisites, reasonable weighting and no unrenderable or invalid cards.
- Preserve three-choice, shedding, frozen choice checkpoint, crash/reopen, reroll rules (if any) and visual preview.
- Remove chimeric cross-family matrix bonus and resolver. Keep original Biomass seed ID #100 with a host-native Biomass function.

### Phase 4 — Snake specialisation vertical slice

- Fully implement Fire Snake (#115), Poison Snake (#11 plus #17), Speed Snake (speed and dedicated turning/flexibility effect), Heavy Constrictor (#184 when working, otherwise clearly mark it prototype and implement an equivalent validated constriction move before claiming release completion).
- Add path-compatible organic expression at three visual stages; distinguish four builds at a glance from isometric gameplay camera.
- Add Fire+Poison coexistence test and actual combat/demolition interaction under real DEFCON, projectile/collision and enemy classes.
- Carefully tune timers, damage falloff and area caps to avoid DOT/area stacking and burst runaway.

### Phase 5 — Nine-species viability and visual consistency

- Supply a minimum of three meaningful build routes in each other host and test them with curated deterministic recipes, not 36 hard-coded classes. Ensure shared stat mutations look different across species.
- Preserve all movement modes; remove any hybrid-only model/extra limbs from new-rules paths. Polish feet, claws, wings, coils, antennae and nodules without introducing many disconnected meshes or shader overdraw.
- Capture nine base silhouettes × three important builds × growth 0/6/12/18; produce phone-style grids with labels, fixed camera, repeatable seed. Track art review limits honestly.

### Phase 6 — World, combat, progression and economy QA

- Test evolving with small and colossal creatures, feeding-size transitions, world demolition and enemy pathing, persistent sector/objective state, pressure/DEFCON response and death/restart.
- Check first-run tutorials and mutation discoverability. A player should create a Poison Snake within a reasonable first session; no guaranteed specific mutation needs to roll immediately unless tutorial intentionally grants it. Improve weighted path discoverability without disabling RNG.
- Build automated 10–20-life seeded simulations for no dead-end/invalid draft, variety of builds and size/mobility viability. Instrument win/loss, damage/energy/health pacing.

### Phase 7 — Android export and delivery

- Keep stable release, Genetics APK #233, Morphology APK #253 and Morph Polish APK #261 untouched. Add a new isolated package e.g. `com.kavemankai.kaijustomp.speciespreview` with its own save namespace. Preserve signing mechanics and warn about debug-key rotations.
- Run official Godot 4.5 import/launch and **all applicable existing suites**; update hybrid-specific tests to assert retired behaviour while retaining coverage. Add new species/draft/migration/traits/FX/traversal/playthrough suites. Do not merely delete broken tests to make CI green.
- Verify ARM64, APK manifest/package name, ZIP integrity, signing v2/v3, zipalign, native 16 KiB; publish **immutable** GitHub prerelease with APK and SHA256 only after all checks pass.
- Capture in-engine screenshots and a short actual in-engine preview video if feasible; never submit concept art as proof of implemented visuals.
- Deliver commit SHA, PR, exact APK URL, SHA256, all test results, known failures, migration report, screenshot matrix, and device playtest checklist. Keep PR **draft/unmerged** until owner phone acceptance.

## I. Minimum automated acceptance tests

| Gate | Required assertion |
|---|---|
| Nine starts | All nine can be selected at birth with distinct bodies and movement; no species changes after 100 arbitrary legal mutations. |
| No hybrid | New-v2 life cannot equip another species' foundation seed, cannot load a secondary base selector and cannot produce a dual-species class; old hybrid v1 loads in legacy mode until death. |
| Builds | Four distinct working Snake loadouts plus Fire+Poison dual specialization; effects and visuals function on actual targets. |
| Draft | Exactly three unique legal options when enough are available; offense/physique/survival preference; deterministic from seed, persists frozen draft; no dead-end after caps. |
| Growth | Snake/Worm gain length, coherent tail path and sensible radius, never obligatory upright; Crab/Spider grow low/wide, Bird gains wingspan, other bodies preserve their shape. |
| Traits | Mutations attach to valid sockets, occupy supported organ slots, show positive before/after visible difference on ranks I/II/III, no invisible stats-only structural gene. |
| Travel | Flight/glide takeoff/altitude/landing; Mole/Worm burrow/emerge; Spider wall/roof/fall; unqualified host cannot activate foreign movement. |
| Persistence | Existing older hybrid v1 run resumes; death creates v2 `birth_pending` in same world with missions/structures/seed retained; same species/new species choices work; archive shows legacy achievements without enabling hybrids. |
| Safety | Version999 save is left untouched; corrupt v2 recovery uses backup; migration is idempotent; app killed during choice resumes correctly. |
| Android | All relevant Godot suites pass, native export integrity passes, preview install unique, robust layout for small/large portrait screens, no unbounded geometry/FX allocations. |

**Capture matrix:** at least 9 species × 3 build exemplars, Snake × (Fire, Poison, Speed, Heavy, Fire+Poison) at three meaningful mutation stages, and 9 × four growth ranks. Compare against APK #261 using exactly matched camera/lighting to detect silhouette regression. Automated pixel-change alone is not gameplay quality: note manual on-phone acceptance remains outstanding.

## J. Expected deliverables and autonomy contract

- One focused draft PR from a **new branch** based on latest Morph Polish PR #21 with implementation commits and clear provenance. Do not merge to upstream or rewrite history.
- New and updated GDScript systems, Godot resources, anatomical mutation expressions and real game-effects; no orphaned prototype logic affecting live data.
- A functional new species-selection UI, no species combinations in new lives, 3-category mutation draft, permanent species identity, at least four verified Snake specialisations, viable variants for all nine.
- Save-v2 migration implementation with backup/recovery, historical hybrid compatibility, frozen draft preservation and automated checks.
- `docs/evolution/FIXED_SPECIES_CHANGELOG.md`, `docs/evolution/FIXED_SPECIES_HANDOVER.md`, evidence/capture directory, and exact APK/signature/test evidence.
- Separate installable and **CI-verified** Android debug APK for owner phone playtest. All unverified issues called out clearly. No claim of complete production art or 500 executable mutations.

### Codex execution prompt (copy-paste)

> Implement the full design pivot described in `docs/evolution/FIXED_SPECIES_SPECIALISATION_HANDOVER.md` in the Kaijustomp repository. Begin from the **latest** `feature/morphology-traversal-polish` (draft PR #21), not default/main. Create a new isolated implementation branch. Replace emergent cross-species hybridisation with a **single immutable player-chosen base species per life** and free-form within-species mutation specialisation. Preserve legacy hybrid-run saves until death, world persistence, existing traversal controllers, all catalogue IDs, valid gameplay and approved Android releases. Implement the actual Fire Snake, Poison Snake, Speed Snake and Heavy Constrictor functionality (and combinations), then expand credible build routes to all nine species. Build proper species-selection/death screens, legal three-lane mutation drafts, visual organ-fitting and bounded movement/combat/size growth. Maintain an updated changelog and handover, implement and run migration/regression/scene/performance tests, capture real Godot screenshots, and publish a separately installable verified Android APK. Do not stop at planning or ask routine questions. Report verified functionality separately from unverified physical-phone performance and art approval. Keep the PR draft and do not merge until owner acceptance.

---

**This document authorises a design pivot and implementation task. It does not itself establish that the code or Android APK has been changed.**