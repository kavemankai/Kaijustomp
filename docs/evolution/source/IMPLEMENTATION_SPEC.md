# CODEX EXECUTION SPECIFICATION — KAIJUSTOMP NINE-FORM GENETIC EVOLUTION

**Revision:** 1.0 — 17 October 2026  
**Intent:** Implement the approved nine-form gradual evolution design in the **existing** KaijuStomp game. Work through design, code, test, Android build, and documented handover; do not stop after a planning pass.  
**Paired design authority:** `KaijuStomp_Nine_Form_Evolution_GDD.md`  
**Other sources:** `kaijustomp_evolution_tree.md`, `kaijustomp_mutation_catalog_500.json`, `KaijuStomp_500_Mutation_Integration_Plan.md`, `KaijuStomp_Codex_Mutation_Engine_Prompt.md`, existing repository docs/code and the EVO 1 roster image.

> **Important:** This is an instruction for future Codex implementation, **not** a claim that this feature has been implemented. Continue from current checkout state; respect work completed since the snapshot inspected for this specification.

## 0. Non-negotiable mission

1. Deliver **nine genetic destinations**: Reptile, Biomass, Snake, Bird, Crab, Spider, Ape, Worm, Mole.
2. **No fixed starter class.** Start as an adaptable hatchling. Genes + bounded real behaviour change affinity and the visible/functional body.
3. Deliver viable **pure forms and dual-family hybrids**, supported by explicit anatomy and legal locomotion, not just percentages, recolours or names.
4. **Do not force body size growth** with evolution count, a mandatory E5 quadruped, or an E22 biped. Existing stage/size thresholds are design baselines and must be preserved as optional gates until retuned.
5. **Do not break the existing game:** mobile movement, current shooting/attacks, Atomic Nova, mutation cards, G-cell economy, destroying objects, sound, PS1/retro stylisation, Android launch, saves, objectives and DEFCON must be protected or migrated with tests.
6. On **final death**, persist world and species discoveries, then start a **new organism**, not a resurrection of the exact dead build.
7. Preserve **all 500 source mutation IDs**, but only offer runtime entries whose effects, visuals and tests work. Do not claim 500 playable mutations.
8. Use **actual code inspection** before architecture changes. Do not invent an implementation. Never delete pre-existing work without checking ownership / history.
9. Make the result **autonomously testable**, balanceable and expandable. Provide actual working files, test evidence and a technical handover, not mocks or unsubstantiated completion claims.

## 1. Verified repository snapshot / integration constraints

The connected repository found during specification preparation was **`kavemankai/Kaijustomp`**, default branch **`claude/new-session-xzf17f`**. At the time of inspection:

| Repo item | Observed responsibility / technical constraint |
|---|---|
| `project.godot` | Godot 4.x; compatibility renderer, mobile portrait-oriented initial viewport (540×960), main scene `scenes/BeachDemo.tscn` |
| `scripts/player/KaijuPlayer.gd` | `Node3D`; player stats, movement, spiral auto-fire, level/XP, Atomic Nova, five `match`-based mutation effects, procedural kaiju mesh |
| `scripts/ui/MutationAndLabUI.gd` | 3-card choice and old lab/revive flow; five-item `MUTATION_POOL`; queues multiple level-ups; pauses tree for mutation choice |
| `scripts/core/RetroMeshFactory.gd` | Runtime `SurfaceTool` / `ArrayMesh` model construction, texture atlas mapping |
| `scripts/core/RetroTextureAtlas.gd` | Procedural 256×256 art atlas |
| `scripts/core/RetroAudioBank.gd` | Code-generated sound FX |
| `scripts/core/ProgressionManager.gd` | `ConfigFile` save at `user://kaiju_save.cfg`; G-cells, stats/lab, best kills |
| `scripts/core/SimulationManager.gd` | Many-unit simulation, enemy projectiles, DEFCON, pickups, spatial-hash/crowd performance |
| `scripts/world/DynamicCityManager.gd` | GridMap destruction and navmesh updates, README describes reset on restart |
| `scripts/ui/MobileTouchController.gd` | Mobile movement and action interaction |

The older branch README describes **five hardcoded mutations** (`dorsal_overcharge`, `isotope_core`, `regenerative_cells`, `seismic_stomp`, `bio_magnet`), G-cell lab ranks, a revive mechanism, a city that resets on restart, and untuned DEFCON/combat. **These observations are a baseline snapshot, not a statement about every Codex branch or the newest APK.**

First actions in the actual checkout: `git status`, branch/HEAD, recently merged work, scene/script tree, test tooling, actual newest mutation module(s), save format, app controls, current Android export and the pre-existing DEFCON/world-save work. If current code differs from the snapshot, update the architecture map and **use current code as source of truth**.

### Files to inspect (if present)

```
project.godot
scenes/BeachDemo.tscn
scripts/player/KaijuPlayer.gd
scripts/ui/MutationAndLabUI.gd
scripts/ui/MobileTouchController.gd
scripts/core/ProgressionManager.gd
scripts/core/RetroMeshFactory.gd
scripts/core/RetroTextureAtlas.gd
scripts/core/SimulationManager.gd
scripts/world/DynamicCityManager.gd
addons/   tests/   docs/   export_presets.cfg
```

**Compatibility requirement:** Never rip out the five legacy upgrades to replace them with a new taxonomy. Either retain them as legal generic non-family upgrades with a compatibility wrapper, or migrate them into stable new gene keys while retaining their existing mechanics, saves and player expectations. The old lab ranks require the same care.

## 2. What should be built now versus later

**Implement in reviewable vertical slices, leaving the game runnable after every slice.**

| Gate | Required functional proof | Explicitly outside gate |
|---|---|---|
| **M0 — Baseline** | Tests/build baseline, source-of-truth audit, architecture map, branch safety | Feature work before understanding checkout |
| **M1 — Genetic backbone** | Nine raw affinities; deterministic attribution; identity calculation; 3-card legal gene draft; UI preview; persist/load active genetics; 9 lineage descriptions | Complex procedural rigging |
| **M2 — Nine EVO 1 expressions** | Nine recognisable family silhouettes or substantial on-body modules; signature interaction for each; debug reproducible seed/build; no unsupported abilities selectable | Full flight, unrestricted burrow/world tunnelling or 36 bespoke hybrid rigs |
| **M3 — Three hybrid proofs** | Reptile+Bird, Ape+Crab, and Worm+Mole **or** substitute an equally well-tested legal pair if existing controllers dictate; expressed identity, anatomy conflict resolution, cohesion, readable preview | Every pair polished |
| **M4 — Broader mutation coverage** | Keep and verify the curated **30** source-gene target from prior brief; also implement **up to five additional family-seeding source genes** needed for nine-first-form coverage (see §6), without removing earlier choices | 500 live abilities |
| **M5 — Multi-life / world integration** | Species archive survives death; new creature replaces dead one; preserve affected sectors as world deltas; response contact remains event-driven | Whole 14×10 km world unless already implemented |
| **M6 — Android + handover** | Test/evidence, performance, save migration, APK debug build if toolchain available, handover with gaps | Unsupported success claims |

If the current checkout already completed pieces of M1–M5, **verify with evidence and skip duplicate implementation**. If resources are limited, favour a fully playable M1+M2+one hybrid over half-built giant scope, and record exact next steps.

## 3. Data architecture — preserve source, author runtime

### 3.1 Immutable source catalogue

`kaijustomp_mutation_catalog_500.json` contains all 500 numbered source entries (fields such as `id`, `key`, `name`, `source_effect`, `source_epoch`, `source_family`, `source_stat_integration`, `source_visual_change`, `proposed_unlock_epoch`). It is a **research/design index**; source statistics and family labels are **not** prebalanced runtime effects or the new nine-form genetic taxonomy.

Validate exactly IDs 1..500, unique stable IDs, names and effects. Do not mutate the source file as a side effect of runtime balancing. Status semantics must distinguish catalogued, defined, integrated, visualised, tested and playable.

### 3.2 Recommended runtime components (adapt to repo patterns)

These are suggested Godot 4 GDScript responsibilities, not mandatory file locations or parallel duplicate managers:

```
scripts/evolution/GeneRegistry.gd
    parse + validate executable gene definitions; source-ID mapping; safe fallbacks
scripts/evolution/GenomeRuntime.gd
    nine raw scores, expressed genes, stability, derived identity, mutation history
scripts/evolution/MutationDraftService.gd
    seeded eligible 3-card draft and reason reporting; staged pending choices
scripts/evolution/AnatomyResolver.gd
    slots, replacements, body-plan compatibility, functional expression rules
scripts/evolution/MorphologyComposer.gd
    low-poly modular creature mesh parts, surfaces, pose/VFX, attachment pooling
scripts/evolution/LocomotionRouter.gd
    one primary movement mode + well-supported secondary abilities
scripts/evolution/GeneEffectRuntime.gd
    effect hooks/stat modifiers/status application and lifecycle cleanup
scripts/evolution/LineageArchive.gd
    long-term codex, unlocks and bounded predispositions
scripts/evolution/EvolutionDiagnostics.gd
    validation, snapshots, coverage and reproducible test seeds
```

Extend `KaijuPlayer`, existing UI, progression/save and simulation/world managers by composition or small adapters. **Do not** introduce broad inheritance hierarchies of hundreds of distinct Godot scenes or one script per gene.

### 3.3 Proposed runtime gene schema

`res://data/evolution/genes_runtime.json` is one option. Use Godot Dictionaries/Resources if stronger for current code; validate against equivalent semantics. Example uses **existing source ID #65** and proposed new tuning:

```json
{
  "schema_version": 1,
  "source_id": 65,
  "key": "065_silk_spinneret_gland_1",
  "display_name": "Silk Spinneret",
  "readiness": "playable",
  "tags": ["spider", "silk", "trap", "rear_organ"],
  "affinity_delta": {"spider": 4, "biomass": 1},
  "availability": {"min_evo": 5, "max_evo": null, "min_size": null, "required_keys": [], "excluded_keys": []},
  "presentation": {"rarity": "common", "draft_lane": "explore", "ui_effect_text": "Spit a short sticky trap that slows a target"},
  "anatomy": {"socket": "rear_organ", "operation": "add", "part_id": "spinneret_small", "required_support_tags": [], "replaces": []},
  "effects": [{"hook": "active_special", "type": "sticky_trap", "duration_s": 2.5, "cooldown_s": 7.0}],
  "stats": {},
  "visual": {"mesh_part": "spinneret_small", "palette": "spider_dark", "vfx": "sticky_thread"},
  "technical": {"touch_control": "context_special", "implemented": true, "visualized": true, "tested": true}
}
```

This is a **shape sample**, not a claim that a projectile/web system exists. `readiness: playable` is only valid **after** the effect works, visual evidence exists, save round-trip passes and automated checks pass. If web traps are not yet integrated, set `readiness: designed` and omit from live drafts.

All JSON-compatible runtime definitions need: `source_id` or explicitly named original legacy key; unique key; family affinities; rarity/weight; effect hooks + parameters; prerequisites and reasons; anatomy part and operation; replacements/exclusions; level/size gating; visibility; balance + cooldown; explicit implementation readiness; and schema version.

### 3.4 Genetic data model

```text
GenomeRuntime:
  genome_version: int
  raw_affinity: { reptile, biomass, snake, bird, crab, spider, ape, worm, mole }: nonnegative int
  selected_source_ids: ordered array[int]
  selected_legacy_keys: array[String]
  mutation_rank_by_key: dictionary
  expressed_slot_parts: map[slot] -> part(s)
  dominant_body_plan: StringName
  secondary_mode: optional StringName
  current_evolution_count: int
  physical_scale: float
  cohesion: int (0..100)
  behavioural_affinity_credit_this_interval: map[form] -> int
  instability_reasons: array[String]
  draft_seed: integer
  active_draft_option_keys: array[String]
```

**Explicitly derived values** (normalized percentages, pure/hybrid label, stat totals, visual recipe) must be recomputed from the saved genes/slots on load and never diverge from the underlying state.

## 4. Deterministic affinity and identity rules

Use the paired GDD's starting proposal; centralize thresholds in a named tuning file rather than hardcode them across scripts.

- Raw scores start at zero for each new life; no automatic Reptile affinity merely because the old mesh is lizard-shaped.
- Source-gene runtime data adds explicit nonnegative deltas (normal primary +4, relevant secondary +1/+2); duplicate offers never reapply twice accidentally.
- Award **at most +2 behaviour affinity per family per evolution interval** from verified gameplay events. Reset counters at the next legitimate evolution. Prevent time-based/idle/button-spam farming. Environmental effects bias choice weight, **not** hidden permanent scores.
- Normalized view only: `percent_i = 100.0 * raw_i / total` when `total > 0`, else 0.
- Unformed if total < 12. Emerging if total >= 12 and top percentage >= 35. Consolidated when total >= 20, top >= 50 and at least one valid signature part. Hybrid candidate when total >= 20, top two each >= 25 and sum >= 65. Expressed hybrid requires at least one visible **and functional** signature from both and compatible anatomy. True-hybrid mastery requires synergy + sufficient stage/complexity. Late tri-form postponed.
- Resolve classifications after anatomy has resolved. Candidate is never displayed as completed if one family's functional expression is missing.
- Numeric ties resolve deterministically by canonical family order **only for sorting**, not as a genetic class selection.

### Reference pseudocode

```gdscript
const FORMS := ["reptile", "biomass", "snake", "bird", "crab", "spider", "ape", "worm", "mole"]

func percentages(raw: Dictionary) -> Dictionary:
    var total: int = 0
    for form in FORMS:
        total += maxi(0, int(raw.get(form, 0)))
    var result: Dictionary = {}
    for form in FORMS:
        result[form] = (100.0 * float(maxi(0, int(raw.get(form, 0)))) / float(total)) if total > 0 else 0.0
    return result

# Determine top two in stable order; then check expression and socket legality.
# Never classify as a true hybrid based on affinity alone.
```

**Important:** Avoid random, unannounced effectiveness failures or touch controls being disabled at low cohesion. Cohesion is a transparent economy/compatibility system. If a gene is illegal due to unresolved slots or no movement support, it is not draftable until a bridge or replacement route is available.

## 5. Mutation draft implementation

`MutationAndLabUI.gd` currently (as observed in default-branch snapshot) shuffles a five-entry hardcoded pool and displays three. Replace the source-of-options mechanism with `MutationDraftService`, preserving the panel, queue and pause semantics, old choices where still legal, keyboard 1–3 and touch/card input.

### Required deterministic sequence

1. Take active genome snapshot, current evolution count, biome/epigenetics and persistence unlocks.
2. Enumerate *implemented+playable* runtime genes and legacy adapters.
3. Filter prerequisites, unlocks, rank/stack caps, stage/size, body plan, sockets, and runtime-feature flags.
4. Classify: strengthen / explore / adapt. Assign bounded weights from affinity, behaviour, biome and archive predisposition.
5. Select 3 unique choices with seeded `RandomNumberGenerator` weighted sampling without replacement. If a lane is empty, legally backfill from the full eligible pool; if fewer than three exist, show honest 1–2 cards or a tested generic option rather than out-of-bounds access.
6. **Persist the actual drafted keys and RNG seed/state** so interrupted or resumed choices do not reroll for free.
7. Preview raw affinity changes, resulting identity forecast, slot add/replace, locomotion impact, cohesion cost, real attack/cooldown and visual cue. No preview can promise unavailable movement.
8. On selection, apply exactly once transactionally (validate first; commit genome and visual composition; update current save); only then resume combat.
9. If multiple level-ups queue in one tick, consume the queued draft in deterministic order and keep the pause/combat semantics correct.

### Testable acceptance

- Same exact seed/genome/world inputs produce same ordered 3-card choices.
- No duplicate cards in one draft, unavailable abilities, dead-end gene choice or missing descriptive reason.
- Crash / pause at draft: active options return unchanged on reopen.
- Select one card: state changes once, not twice; preview corresponds to final body and stats.
- A player can steer toward all nine forms within a reasonable series of eligible picks, independent of random lucky pulls.

## 6. Nine-form proof genes and the old curated 30

The previous `KaijuStomp_Codex_Mutation_Engine_Prompt.md` requested **exactly 30** source IDs. **Do not discard that implementation work.** For nine immediately legible biological families, five extra source genes may be needed if no equivalent working hooks have already been built.

| Form | First proof source gene | What must visibly change | Minimum actual interactive result |
|---|---|---|---|
| Reptile | **#6** Sub-dermal Osteoderms | Pebbled dorsal plating | Measurable damage mitigation |
| Biomass | **#100** Chimeric Flesh Matrix | Mixed patchwork/tendrils | Cross-family draft weighting or resolved socket support |
| Snake | **#11** Fangs of the Pit Viper | Serpentine snout + venom teeth | Bite/status effect with real target handling |
| Bird | **#22** Hollow Bone Struts | Feather or light bird-frame cue with slim limbs | Speed/acceleration gain and impact tradeoff |
| Crab | **#61** Chitinous Exoskeleton | Shell segments and pincer silhouette cue | Armour effect with mobility tradeoff |
| Spider | **#62** Compound Ocelli | Multi-eye + arachnid cue | Better motion tracking/target read |
| Ape | **#44** Shoulder Girdle Rotator | Long powerful grasp/arm silhouette | Larger contact cone or supported throw interaction |
| Worm | **#84** Muscular Foot | Segmented low crawler and obvious ventral surface | Distinct crawling movement/terrain response |
| Mole | **#15** Clawed Digging Spades | Expanded foreclaws and broad snout | Verified short dig/breach behaviour *only if implemented*; otherwise lower-tier soil clearing not full tunnel teleport |

IDs #6, #100, #22 and #61 are among the earlier curated 30. **#11, #62, #44, #84 and #15 are five additive lineage-seed genes.** Thus **a complete implementation of both the old curated 30 and these five has 35 distinct source-gene IDs**, not 30. If prior work already implements equivalent mechanisms, reuse it; do not write duplicates. The GDD's shorthand “first 30” means the legacy target, with these up-to-five necessary additions for nine-family coverage.

### Prior curated-30 target (unchanged; verify actual readiness)

`1, 2, 6, 7, 9, 12, 14, 19, 20, 22, 30, 36, 39, 42, 43, 47, 49, 57, 58, 61, 72, 73, 81, 85, 88, 90, 95, 99, 100, 441`

Existing prototype legacy IDs also remain usable or safely migrated. Do not mislabel an old feature as one of the 500 if the behaviour/name don't match the source concept.

### Readiness truth

A gene is *playable* only if: engine hook present; effect alters live encounters; prerequisite and slot validation pass; on-creature visual feedback exists; the state survives save/load; automated unit/integration tests pass; mobile action works if relevant. A representation as a card, codex record or colored model is insufficient.

## 7. Procedural visual anatomy system — Godot 4 specific

**Respect existing renderer.** The reference repository uses `RetroMeshFactory`, `SurfaceTool`, shared atlas materials and a `KaijuPlayer.visual_root`. Build a **low-overhead modular mesh assembler** in that style rather than loading complex high-poly Blender rigs into every tiny mobile encounter.

### Required anatomical sockets

`head`, `jaw`, `neck`, `torso`, `forelimbs`, `hindlimbs`, `extra_limbs`, `dorsal`, `tail`, `surface`, `organ`, `effect_attachment`.

A socket operation is one of `add`, `modify`, `replace`, `remove`, `overlay`, each declared with legal support tags. A part has: `part_id`, `socket`, `family_origin`, low-poly mesh builder/reference, palette, bind transform, collision contribution where applicable, animation cue, bounds, visible scale range and a fallback if unsupported.

### Mandatory resolution order

1. Determine body plan and legal current locomotion (not just primary affinity).
2. Validate required core/support structures for acquired appendages.
3. Resolve exclusive/replaceable sockets and explicit bridge genes; report user-facing consequences.
4. Build core/limb silhouette using procedural mesh modules.
5. Attach coverings, dorsal/tail, glands and effects; do not allow clipping to hide all secondary lineage cues.
6. Refresh appropriate collision bounds, attack traces, movement parameters and camera scale.
7. Recompute stats from base + genes + bonuses **from scratch**, not repeated multiplied values.
8. Cache mesh recipe by hash and reuse until a mutation or size change; do not rebuild each frame.

Nine-form visual tests must use **same camera angle, comparable scale, lighting and environment** and generate one screenshot each for proof. Keep a debug `spawn_genome_recipe(form, seed)` or test fixture independent of difficult live RNG grinding. One hybrid must be visibly identifiable by observers at gameplay zoom.

**Do not misrepresent asset concept sheets as reusable model components.** They are references. Any images imported need explicit license/origin recording and truthful native assets. Procedurally generated meshes should satisfy the first working milestone.

## 8. Locomotion and physics compatibility

A creature has **one primary controller** with optional tested secondary action. Initially share simple ground movement while differing in animation/appearance, then progressively enable new locomotion controllers. Implementing a mesh is not implementing a working body plan.

| Family | Initial proof | Follow-on controller |
|---|---|---|
| Reptile | existing ground move + tail cue | quadruped/biped combat transitions |
| Biomass | crawler-like cadence + regenerative/organic cue | deformable/low crawler, tendril reach |
| Snake | forward slither impression with reliable collision | spline/ring-driven serpentine pathing |
| Bird | light biped movement, short boosted leap *if collision supports it* | glide, eventually full tested flight |
| Crab | wider low body, lateral movement adaptation | true lateral multi-leg plus amphibious handling |
| Spider | eight-leg visual/feet cue | wall climb + web anchors |
| Ape | heavy knuckle stride, contact reach | grab/throw and structure climb |
| Worm | axial low crawler, surface breach animation | burrow with terrain constraints |
| Mole | clawed low crawler, dig attack / soil disruption | underground route + seismic response |

Keep collisions and terrain legal. If a feature like free flight or underground pathfinding requires a larger dedicated slice, gate the corresponding gene as `defined` not `playable` until it exists. Never simulate “flight” by simply making a visual body float through impassable buildings.

## 9. Hybrid implementation — anatomy first

### Eligible hybrid resolver

A hybrid classification is only complete if all conditions hold:

```
affinity_total >= 20
AND highest_share >= 25%
AND second_share >= 25%
AND highest_share + second_share >= 65%
AND signature_part_present[family_A]
AND signature_part_present[family_B]
AND both_signature_parts_have_effect_hooks
AND AnatomyResolver reports LEGAL
```

A **candidate** can exist without functional dual anatomy; it is not displayed as complete. True-hybrid mastery additionally requires a valid paired synergy, enough complexity/age and manageable cohesion. Evaluate classification and visual recipe after every mutation and on load, not after arbitrary periodic timers.

### Compatibility is structural, not arbitrary pair blocking

- Socket conflict: two full forelimb replacements → reject or show explicit replacement; a bridge may support extra arms in a safe late stage.
- Motion conflict: wing + heavy shell → offer winglets/glide only until mass/lift support exists.
- Support conflict: snake trunk + giant crab pincers → require appendage-support frame or translate to small grasping accessory.
- Collision conflict: arachnid leg array + narrow indoor passage → size/collision rule, not wall clipping.
- Expression conflict: mixed coat is fine, but low-poly patterns alone can't count as two signature functional families.

Cohesion begins at 100 with visible sources. Sample tuning: -12 unresolved-slot candidate, -8 secondary mode without support, -6 mass/lift mismatch, +6 bridge stabiliser (subject to test). Illegal runtime configurations must not be committed. Never use random loss of player input or unpredictable total paralysis as a difficulty mechanic.

### Three minimum prototype hybrids

| Hybrid fixture | Required visible shape | Required observable mechanic | Counterbalance |
|---|---|---|---|
| Reptile/Bird | Tail + scales/dorsal cues **and** functional feathered winglets | Sprint-to-short-glide **only if** real leap/glide path is tested; otherwise a valid aerodynamic jump boost | Lightweight skin is weaker against heavy rounds |
| Ape/Crab | Broad ape torso + clearly functional pincer forearm / shell | Crush/grapple or guarded impact in existing hit system | Slow turning or stamina cost |
| Worm/Mole | Ringed trunk + huge dig foreclaws | Surface breach/soil disruption and short burrow where world supports | Seismic detection / hard ground limitation |

The first **three** may be different if current controllers make another trio easier. If changed, explain why in handover and keep at least one radically incompatible pair represented through a tested, *visible* stabiliser/bridge choice.

## 10. Stats, combat, and balance safety

Implement generic effects, not bespoke 500-way scripts:

- Recompute `effective_stats = base + additive_modifiers`, then apply ordered multipliers and caps; remove/reset/reload is idempotent.
- Support damage categories and status rules (impact, small arms, heavy kinetic, explosive, corrosion, venom, slow, regeneration, etc.).
- Source `Hardened Scales = 0.78× remaining damage per stack` and `Fleet Limbs = +1.6 speed per level` are **legacy references, not unbounded stacking permission**. Add tunable caps/diminishing returns and tests.
- Protect screen-space readability and early difficulty; do not silently increase bullet damage or firing rate by order of magnitude.
- Preserve the original five auto-shooter upgrades until migrated with equivalent feel and save compatibility.
- Small fast/venom/stealth creature must be able to meet age-appropriate objectives without walking through buildings.
- Huge shell and full flight are not free together: explain mass, mobility and cooldown consequences visibly.
- Every active ability obeys touch-control allocation; use contextual action or mode shift rather than eight new on-screen buttons.

## 11. Persistent life, save migration, and DEFCON

### Save domains

- **World**: sector/district IDs, persistent building delta lists, repair/cooldown state, notable corpses/remains, infrastructure, response origins, long-term military knowledge.
- **Current organism**: genome, mutations, physical scale, HP/energy, active status, world position, pending draft, organism ID, current local contact (ephemeral, not archive).
- **Species archive**: discovered genes, nine mastery tracks, hybrid discoveries, cosmetics, bounded draft predispositions, achievements and lineage history.

Use stable IDs, schema versions and atomic writes / backups. In Godot, `ConfigFile`, `FileAccess` JSON and a rename-based save protocol can work; follow current patterns and don't corrupt `user://kaiju_save.cfg`. New save/load must preserve the existing G-cell economy and lab data, either in the existing file with namespaced sections or safely versioned associated files.

### Lifecycle

```
lethal event
  -> process any explicitly allowed pre-death safeguard
  -> if truly dead: finalise organism + archive discoveries
  -> write world / species / death record
  -> release ephemeral combat/contact state
  -> game-over/lineage screen
  -> create new organism with neutral active raw affinities
  -> load retained world deltas and archive, select quiet legal spawn
  -> begin new life
```

The old **Atomic Defibrillator post-death revive** conflicts with final-death permanence. Treat it as an existing legacy mechanic pending careful migration: either reinterpret it as an **in-combat last-chance survival trigger before death finalisation**, or remove it only with a documented save/UI migration and explicit testing. Never silently restore a finalised dead monster and claim it is a new life.

### DEFCON and dispatch

- Split **local observed alert** from **persistent strategic knowledge** if current code doesn't already.
- `mutation_chosen` changes anatomy; it does **not** dispatch SWAT or increase DEFCON.
- Observed noise, witnesses, destructive incidents, radar contact, obvious size and seismic signatures contribute according to real events.
- Ground units arrive from actual beach/suburb/inland origins with travel time; do not spawn late-tier squads beside the hatchling.
- Archive learned counters may predispose a region to prepared tools, not omniscient live targeting of new unrelated creatures.
- Create automated scenario: spawn E0 on quiet beach, walk/idle without attacking, confirm no laser/SWAT tier arrival merely due to time/evolution counter.

If sector-based AI exists on the working branch, **integrate with it** rather than overwriting it with these examples. World streaming and region deltas are separate performance milestones; do not fake full persistence by taking one giant snapshot of the entire map.

## 12. Test plan — automated and human-readable evidence

### A. Data validation

- `source_catalog_count == 500`, unique IDs exactly 1..500; all runtime `source_id` references valid.
- Nine canonical family IDs; no misspelled family names; every readiness=playable has a supported effect and visible part.
- No broken prerequisites, cycles, unknown slots or missing meshes; legit rank caps and exclusions.
- The nine family seed genes exist and are testable.

### B. Deterministic genetics / draft

- New organism all nine affinity values zero; same seed gives same offers and identity.
- Numeric and percent math with zero total, ties, caps and behavioural spam cases.
- Convergence cases: nine pure steering paths; at least 3 hybrid eligibility cases; candidate versus expressed identity; replacement case.
- Growth remains opt-in; mutation count cannot silently enlarge or change the base movement type.
- Applying/replaying a mutation or reopening a draft does not duplicate its stat or archive reward.

### C. Gameplay and visuals

- Measurable mitigation, speed or status for each demo gene in live simulation.
- Visual mesh/collider attached correctly; before/after screenshots in consistent lighting; no missing parts/NaN transforms.
- Hybrid combined anatomy and effect actually work; unsupported mode never advertised as active.
- No uncontrolled recurring mesh build, VFX leak, or input regression on portrait phone.
- Existing auto-shooter, Nova, objectives, world destruction and upgrade slots still function as appropriate.

### D. Multi-life / migration / AI

- Pre-feature save loads; existing G-cell totals/lab ranks maintained.
- Save/load mid-life reconstructs genome and pending draft; switching/closing app doesn't reroll options.
- Final death creates new genome and records prior organism; world state and archive survive restart.
- Defence logistics and DEFCON: no idle/SWAT beach spawn; correct distance/time and detection transitions.
- Broken/incomplete save restores previous safe version without duplicating lineage rewards.

### E. Android and performance

- Godot headless project import and launch; run repository test suite and new test runner.
- Release/export preset presence; debug APK export with actual SDK and Godot export templates **only when available**, otherwise document precise missing toolchain.
- Smoke test phone/touch if device is accessible; screenshot current action/menu; monitor `frame_time_ms`, memory, draw calls, procedural-mesh builds and AI during high enemy counts.
- Device performance targets are **candidates**, not asserted results: 60 FPS target on test handset, no recurring >50ms build spike on draft closure, low one-time mesh allocation per mutation change.

Suggested project commands (adjust executable/version/path to real environment):

```sh
godot --headless --editor --path . --quit
godot --headless --path . --quit-after 300
# If project uses a SceneTree test runner:
godot --headless --path . --script res://tests/run_genetics_tests.gd
# Only if a valid Android export preset / Android toolchain are confirmed:
godot --headless --path . --export-debug "Android" build/KaijuStomp-genetics-debug.apk
```

Keep raw output/exit codes or reproducible scripts under the project handover. These are commands to **run**, not claims that they have run.

## 13. Code quality / safety rules

- Reuse the actual engine/version and project scene design. Avoid adding Godot 4.4/4.5-only APIs unless explicitly verified and supported by export templates.
- Prefer signal-based interfaces; use stable `StringName`/IDs; no dynamic `eval`, uncontrolled reflection, or script-per-mutation explosion.
- Data contracts and high-level state are versioned. `KaijuPlayer` can own creature runtime but should not own parsing 500 records or world persistence.
- Don't generate meshes every `_process`/`_physics_process` call. Cache merged model recipes/material instances where possible.
- Distinguish *mutation source family* (old catalogue sections) and *nine new affinity forms* (runtime taxonomy). Source names never need to be rewritten to match new taxonomy.
- Preserve repository structure, uncommitted work and licence metadata. Do not overwrite graphics or sound without checking provenance.
- Do not add ads, gacha, subscription systems or paid rerolls; do not add external network services for core combat.
- Feature flags may control staged systems, but user-facing cards must accurately reflect what is enabled.
- Every branch of this task must be left buildable; checkpoint commits and update test logs.

## 14. Work order and deliverables

### Step-by-step execution order

1. **Inspect checkout / read docs.** Record branch, commit, source conflicts, test results and actual current systems in `docs/evolution/GENETICS_HANDOVER.md` (or existing equivalent).
2. **Write validation tests first** for data, affinity math, nine family catalogues, seed reproducibility, migration and pure/hybrid detection.
3. **Add runtime registry and genome** with nine tracks, transparent weighting, classification and saved versioned state.
4. **Integrate the live mutation draft** without regressing existing legacy upgrades, queues, pause behaviour, keyboard or touch.
5. **Implement nine EVO 1 anatomy expressions** with real functional genes as far as the current movement/terrain systems allow; use honest status and build gates for advanced features.
6. **Prove the anatomy resolver and at least three hybrids**, including useful visuals, capacity/collision checking and real synergy/tradeoff.
7. **Verify existing curated 30 and five added family gaps**, marking readiness per entry. Never claim completeness without functional tests.
8. **Integrate archival persistence and final death/new life**, preserving current saves and world deltas. Retune DEFCON only insofar as required to prevent unjustified escalation.
9. **Run tests, playtest scenarios and Android build** if toolchain available; repair regressions; save screenshots/logs; update documentation.
10. **Deliver short handover** with a table `planned / implemented / visualized / tested / playable`, named files changed, test/build commands and results, all known defects, save compatibility, device performance evidence and next three priorities.

### Must-produce repository artifacts

- `docs/evolution/NINE_FORM_DESIGN.md` — checked-in/cross-linked copy or accurate summary of paired GDD.
- `docs/evolution/GENETICS_HANDOVER.md` — state, branch, baseline, implementation, tests, gaps.
- `docs/evolution/GENE_COVERAGE.md` or `.csv` — 500 original IDs and honest status.
- Runtime gene definitions with schema validation and gene ID mapping.
- Genome/selection/anatomy/visual modules and existing game integrations.
- Nine EVO 1 fixture recipes and at least three hybrid fixture recipes (code/data).
- Automated tests (headless if available) and report of exact pass/fail counts.
- Working Android debug APK **if and only if actually exported and verified**; provide real path/build notes.
- Screenshot evidence of nine forms and three hybrids in actual engine viewport, not merely promotional concept art.

### Completion report format

```
Checked branch / commit:
Baseline tests and build:
Implemented systems:
Nine family demos (9 rows; gameplay + visual status):
Hybrid demos (at least 3):
Mutation coverage (prior 30 + five possible additions):
Migration and final-death evidence:
DEFCON and sector response evidence:
Android APK exact path / unable + reason:
Known regressions / performance limitations:
Files and commits:
Next 3 tasks:
```

**Execution instruction:** Start with repo inspection and implementation. Do not ask the user to select species, re-explain what gradual evolution means or produce only a roadmap. Make reasonable reversible choices and document them. Stop only for a genuine external blocker (missing credentials/toolchain, destructive decision, unavailable assets), and then report the blocker precisely while completing unaffected work.
