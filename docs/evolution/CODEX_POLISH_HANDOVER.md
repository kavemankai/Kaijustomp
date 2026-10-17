# KaijuStomp — Codex Autonomous Polish Handover

**Purpose:** Turn the working nine-form genetics and traversal preview into a visually cohesive, responsive, robust Android gameplay candidate. **This is an implementation assignment, not another design exercise.** Do the work autonomously, commit it, test it, and publish a separate Android test APK. Do not ask the owner for interim decisions; preserve a decision log and disclose anything that cannot be verified.

**Date / review baseline:** 18 October 2026.

**Repository:** https://github.com/kavemankai/Kaijustomp

**Starting branch:** `feature/morphology-traversal-autonomous` (draft [PR #20](https://github.com/kavemankai/Kaijustomp/pull/20), targeting `feature/nine-form-genetics-preview`, itself an unmerged genetics preview). **At review, branch head:** `1595377cdf746e6d47b0c470ee889341993fb374` (post-build documentation). Do not assume this SHA is still HEAD: fetch the latest state first.

**Known-good gameplay/export baseline:** commit `27cb2e1f298b154fed6bf577aa00263a16dd817d`, [Morphology & Traversal APK #253](https://github.com/kavemankai/Kaijustomp/releases/tag/morph-traversal-253-27cb2e1), [successful Android workflow #253](https://github.com/kavemankai/Kaijustomp/actions/runs/39040926932). At that commit, Godot 4.5 import/launch, all **31 discovered regression suites**, and Android signature/package/native-alignment checks passed. This proves a build/test baseline, **not** visual approval, convincing motion, correct control feel, or measured performance on a phone.

**Read first, in this order:**

1. `docs/evolution/MORPHOLOGY_TRAVERSAL_HANDOVER.md`
2. `docs/evolution/NINE_FORM_DESIGN.md`
3. `docs/evolution/source/IMPLEMENTATION_SPEC.md` and `docs/evolution/source/INTEGRATION_PLAN.md` (older design guidance; where references disagree, use live branch code as implementation truth)
4. `data/evolution/kaijustomp_mutation_catalog_500.json`
5. `docs/ART_DIRECTION.md` and source creature art references where available
6. `scripts/ci/test_morphology_traversal.gd`, `scripts/ci/run_regressions.py`, `.github/workflows/android-apk.yml`

## 0. Locked game direction — do not reinterpret

- Nine **gradually evolved**, hybridisable biological destinations: **Reptile, Biomass, Snake, Bird, Crab, Spider, Ape, Worm, Mole**. No compulsory starter class.
- Genes are physical and functional. A selected mutation must fit the creature's body and visibly develop with rank. No generic reptile spikes, paws, armour or glands glued to every body at the same coordinates.
- **Size is independent from genetic identity.** Snake and Worm grow mainly longer (with controlled thickness and segment count), **never automatically stand upright**. A large Snake should visibly navigate a long following body around streets, recalling the readable head-driven path of Nokia Snake, without teleporting its tail.
- **Flight, gliding, underground travel and climbing must be real controllable traversal**, not decorative assets or uncollidable teleport shortcuts. Traversal requires correctly unlocked anatomical support.
- Pure forms and meaningful hybrids both work. One primary body plan plus selective, integrated secondary organ systems; no disconnected accessory piles.
- Player death creates a new organism **in the existing damaged/persistent world**. Preserve lineage discoveries, world deltas, mission state, civilian/DEFCON systems, and original controls.
- Preserve all **500 source concepts/IDs**. The current prototype has **41 executable source genes** (the earlier 35 plus six traversal IDs 29, 52, 119, 121, 122 and 180), plus nine generic upgrades. Do not falsely mark concepts playable or expand all 500 during polish.
- Android portrait, mobile-first, original soft low-poly/coastal creature-feature aesthetic. No major game-loop, pricing, lore, mission, or monetisation redesign.

## 1. Autonomy and source-control rules

1. `git status`, fetch remote, inspect open PRs and latest branch head, then choose **one dedicated polish branch** off the latest `feature/morphology-traversal-autonomous` commit (suggested `feature/morphology-traversal-polish`). Never reset, overwrite, or force-push PR #19 or PR #20. If another agent has changed the source, reconcile that work rather than reverting it.
2. Commit in reviewable functional slices, not one giant untestable patch. Each stage must have tests and a short record of what was changed.
3. Use Godot **4.5** and existing project conventions. Continue the approved art pipeline where appropriate: authored low-poly/GLB components can be created or upgraded, but preserve compatibility with procedural and existing art, rig/bone contracts, and Android renderer constraints.
4. The runtime must be the sole gameplay authority: movement, physical collision, size, damage, targeting, saves. Visual systems follow that state and cannot grant non-existent gameplay powers.
5. Work without requesting artistic micro-decisions. Select reasonable defaults, capture comparative screenshots, and leave the player to approve the final look after the APK test.
6. Keep original app IDs/releases installed side by side. New polish builds use a **new, separately installable preview package** (`com.kavemankai.kaijustomp.morphpolishpreview` suggested) and immutable release tags, never rewrite an existing release asset.
7. Preserve a current `docs/evolution/POLISH_HANDOVER.md` and `docs/evolution/POLISH_CHANGELOG.md` as you proceed. Update coverage status with evidence rather than assumptions.
8. **Do not merge** upstream or mark any draft PR ready until the owner has played the APK and accepted it.

## 2. Source map — inspect before editing

| Existing component | Existing responsibility | Polish task |
|---|---|---|
| `scripts/beach/genetics/AnatomyManifest.gd` | Form-specific anatomical anchor dictionary | Turn static offsets into canonical typed sockets with correct local transforms, semantic ownership, valid support types and replacement rules |
| `scripts/beach/genetics/CreatureMorphology.gd` | Nine procedural low-poly forms, signatures, wing supports, shared mesh cache | Improve coherent geometry, deformable/animatable organs, silhouettes and material palette; enforce valid hybrid recipes |
| `scripts/beach/genetics/MutationExpressionLibrary.gd` | Generic upgrades and displaced early-gene visual cues | Replace crude one-size-fits-all decoration with host-specific, stage-specific expressions driven by actual anatomy and effects |
| `scripts/beach/genetics/BodyDimensionsPolicy.gd` | Per-form length/width/height/radius/wingspan/size metric | Synchronise mesh, camera, physical collision, attack traces and locomotion to anatomical dimensions rather than a single scalar |
| `scripts/beach/genetics/AxialTrail.gd` | Arc-length head path, visual/body samples, save/restore | Continuous tapering Snake/Worm body, meaningful obstacle contact, no gaps/snaps, stable long-creature turns, efficient runtime updates |
| `scripts/beach/genetics/CreatureTraversal.gd` | Ground/flight/glide/burrow/climb/roof/fall transitions | Make starts, stops, resource costs, physics, constraints, visuals, camera and responses feel production-plausible; fix edge cases |
| `scripts/beach/genetics/BeachGenetics.gd` | Genome, movement and morphology integration | Keep stats, mutation ranks, scene refresh, traversal availability and save/reload consistent |
| `scripts/beach/genetics/GenomeState.gd`, `GeneRegistry.gd`, `GeneEffects.gd` | Mutation semantics, legal picks, source IDs | Data consistency, legal previews, accurate descriptions, actual gameplay/visual mapping; no ID changes |
| `scripts/beach/genetics/GeneticsHUD.gd` | LINEAGE, debug QA selector, movement touch buttons | Cohesive small-screen UI; unambiguous inputs, actionable mutation forecasts, inspectable anatomy |
| `scripts/beach/BeachDemo.gd` | Authoritative physics, enemy and world interaction | Integration, camera, world streaming, attack/reach/hitboxes, touch responsiveness, pause and death lifecycle |
| `scripts/beach/CreatureVisual.gd`, `StylizedCreatureArt.gd` | Legacy authored quadruped/upright art and rig | Preserve fallback visuals and compatibility; avoid hidden-mesh mutation parts and double-rendered limbs |
| `scripts/beach/WorldStreaming.gd`, `WorldState.gd` | Large streamed persistent world and saves | Stream tail/altitude/roof/underground correctly and maintain world state across lives |

### Architectural concerns to investigate, **not assumed validated defects**

- `AnatomyManifest.signature()` currently provides many **translated Vector3 points**, rather than orientation-aware sockets and attached skin/bones. `MutationExpressionLibrary.trait_frame()` translates legacy geometry relative to approximate reference positions; that cannot guarantee correct fit for a Snake head, wing, crab pincer or a stretched axial body. Diagnose visibly and replace where needed.
- `MutationExpressionLibrary.render()` currently relies on simple oval/bone primitives; selected upgrades can still look like beads, bumps or sticks rather than grown organs. Improve shape grammar, attachment seams, taper, material regions and dynamic posing.
- `CreatureMorphology._signature()` overlays secondary family accessories on a primary core. Audit actual **slot exclusion, true forelimb replacement, dual limb support, material transitions and hybrid silhouettes**; don't claim the existence of an affinity label proves real hybrid anatomy.
- `AxialTrail` uses a bounded point history, discrete oval sample meshes and `Area3D` body regions. These are a good prototype but not a real articulated tunnel/bone/obstacle solution. Audit segment gaps, long-tail collisions, physics layers, persistence and sampling when movement delta spikes or the player doubles back.
- `CreatureTraversal` has simple height targets, foundation footprint checks and wall/roof physics probes. Test roofs, air/ground altitude, falling, underwater/coast, unloaded sectors and safe save/load; distinguish features that remain intentionally simplified.
- `BeachDemo` still owns an older primary capsule collider, jaw/pivot animation, targeting and camera assumptions; verify host anatomy and upgraded size are consistently respected by live hit detection, contact and gameplay. If visual scales far beyond collider, it is **not polished**.
- Existing regression suites are mostly functional/headless proofs. Add deterministic screenshot and physics/interaction coverage, not only successful script execution.

## 3. Priority P0 — nine convincing base bodies and mutation fitting

**This is the highest-priority gate. Fix it before spending time on additional special effects.**

### 3.1 New attachment/morphology contract

Create a typed, data-driven organ/attachment model. Suggested semantics:

```text
BodyRecipe
  body_plan (biped, quadruped, axial_slither, axial_crawler, avian, lateral, arachnid, knuckle, digger)
  family_primary + family_secondary
  growth_dimensions (length, width, radius, height, wingspan, mass)
  sockets[semantic_name] -> local Transform3D, source bone/segment, supported modes, bounds
  coverage zones, support anatomy and replaceable occupancy
  equipped_gene_expressions (source_id, rank, organ id, socket, operation, visual state)
  traversal constraints, gameplay hitboxes and camera framing properties
```

Each mutation declares **add / alter / replace / remove / overlay**. Exclusive organs (forelimb hands versus pincer versus wing; radial maw versus ordinary jaw; primary posture) cannot occupy the same body region without an explicit structural solution. Accessories follow skeletal or procedural moving anchors. Axial creatures use `anterior`, `neck`, `segment_index`, `segment_fraction`, `mid_body`, `rear` and `tail_tip` attachment zones rather than fixed Z positions.

Do not create 9 × 41 bespoke models. Implement semantic upgrade families plus **nine form-specific expressions**, with authored differences only where the body plan needs them. Preserve gameplay statistics and mutation effects.

### 3.2 Silhouette and quality reference by lineage

| Lineage | Essential readable silhouette | Proper progression / fitting |
|---|---|---|
| Reptile | Solid low reptile, tapered muscular tail, wedge jaw, dorsal ridge | Plates grown from spine, believable scaled armour and talons; older reptile look maintained, no random extra limbs |
| Biomass | Lopsided soft body mass, regenerating tissue, sacs and tendrils | Tendrils share tissue bases and animated roots; mutations reshape mass and asymmetry rather than appearing as beads |
| Snake | Readable continuous head, hood/neck, long tapering body, small/no limbs | Neck and fang growth, coils, ventral scale bands, armour along curve; growth is length and radius, not height |
| Bird | Long-legged avian torso, distinctive beak, crest, leg talons and functional wing arms | Actual jointed wings, span changes and feather groups reacting to glide/flight; no arms/legs poking through wings |
| Crab | Wide flat carapace, side legs, substantial pincers | Pincers **replace** or transform forelimbs; strength affects claw structure, defence modifies shell, gait stays lateral |
| Spider | Eight coherent supports, abdomen, eye clusters and fangs | Leg segments with plausible joints; webbing/spinnerets and hooks grow where a spider can use them; climb pose visibly different |
| Ape | Upright/knuckle mass, shoulders, giant fists, readable face | Arm/fist/grapple upgrades attach to working skeletal pivots; shell hybrid should cover shoulders/back, not obscure arms |
| Worm | Thick low segmented axial form, radial mouth, ringed skin | Actual continuous segmented body, expanding maw/plates, body length and width; never turns into a standing reptile |
| Mole | Compact excavator, enormous foreclaws, wedge snout, heavy shoulder frame | Digging claws change forearm/shoulder architecture, dirt/rock accents attach consistently, ground-first movement |

Use the established coastal soft low-poly / stylised creature aesthetic. Prefer coherent primary colour masses, large silhouette cues and clean animation over dense detail or random added spheres. Create controlled highlights, smooth/tapered joining and tasteful FX where gameplay communicates it. Keep hero readable against suburbs/industry at typical mobile camera zoom.

### 3.3 Mutation visual tiers

For each of the existing **nine generic upgrade families** (`armour`, `speed`, `stamina`, `jaw`, `strength`, `health`, `regen`, `cocoon`, `metamorphosis`) and each of the **41 executable source genes** that can legally appear on a form:

- Rank I: a clearly visible anatomical acquisition.
- Rank II: the **same** organ develops or changes proportion/colour/animation; do not spawn a disconnected second copy.
- Rank III: a visibly mature structure with strong silhouette or FX cue, still consistent with the original body plan.
- Additional purchased ranks, if game rules allow them, should honestly preserve the mature model rather than resetting or stacking visual garbage.
- Runtime mutation cards must state actual mechanical effect, body slot added/replaced, traversal impact and any loss/conflict. Do not show fantasy functionality where only a visual cue exists.

Create a data-backed coverage table automatically enumerating legal host × gene × rank combinations. Non-applicable genes need explicit illegality, substitution, or integration. **No invisible gameplay upgrade where the design requires a visible organ; no visible nonfunctional ability.**

**Acceptance P0:** At size ranks 0/6/12/18, all nine forms remain clearly distinguishable from three in-game camera angles; no unanchored pieces, duplicate limbs, floating signs, detached eyes, sideways wings, or major mesh intersections. Compare baseline screenshots with after shots. Every legally equipped generic upgrade has a visibly host-specific I/II/III progression; all executable source genes have verified host-specific representation or an explained compatibility restriction.

## 4. Priority P1 — locomotion and body growth that feel like different animals

### 4.1 Snake — head-led world-spanning body

- Preserve **steer the head, path-follow the whole body**, with constant/arc-length sampling or equivalent stable interpolation at fast sprint and variable frame rates. Worldspace points follow actual curved head trajectory, not merely a mesh rotated as one rigid stick.
- The body forms a **continuous tapering silhouette**, with appropriate head/neck/body/tail material transitions, joint/skin deformation and no obvious disconnected spheres. Optimise geometry batching rather than drawing dozens of identical detached ovals.
- Larger lengths change actual path occupancy, obstacle navigation, turning arc, bite/constriction reach and camera presentation. Turning must be controllable at E18 without instant rotation, tail teleport, self-intersecting visual mess, or offscreen physics disappearing.
- Decide and document the design rule for walls and the trailing body: meaningful world contact and damage where supported; head cannot drag a physical body through indestructible obstacles unnoticed. Use bounded query/proxy collisions; do not make the snake fully simulated rigidbodies just to approximate the feel.
- Body attachments distribute along fractional segment addresses and survive length/segment-count changes.

### 4.2 Worm — siege crawler / genuine earth traversal

- Long, thick, segmented, maw-first locomotion. Distinct from Snake: lower manoeuvrability, different undulation timing, visibly heavy ground response, compact/tapered rings, believable breach/emergence.
- Dig is a deliberate transition; body should disappear **progressively** into the ground, rather than hiding the head while 80 world units of visible body remain outside. Exit should draw the entire following body out over time.
- Soil/foundation/shoreline rules must be consistent and transparent. Block or route around protected foundations, unloaded boundaries, indestructible structures, sea/ocean incompatibilities and invalid emergence. No under-building teleports.
- Expose seismic disturbance/breach markers above ground; make human counter-response possible, with existing DEFCON travel logic rather than instant squads.

### 4.3 Bird — avian ground movement, glide and powered flight

- Dedicated avian movement/animation contract: wing development at relevant gene ranks, takeoff motion, banking into heading changes, flight altitude, responsive pitch/height controls, readable shadow separation from ground, controlled glide sink and landing.
- Wings grow with wingspan and physically follow animated shoulder/wrist pivots, with folded/extended/flapping poses instead of detached stiff rods. Heavy hybrids may glide but do not gain infinite powered lift unless support/size rules allow it.
- Roofs, tall buildings, projectiles, anti-air units, bounds, camera, terrain streaming and save/load must operate correctly when elevated. No landing *inside* a roof or leaving player stuck above the playable world.
- Mobile UP/DOWN and TRAVERSE controls must remain usable with joystick and attack controls in portrait without accidental activation or finger occlusion.

### 4.4 Mole burrowing / Spider wall traversal

- Mole should have controlled soil entry and exit, gradual transition, believable digging forelimb animation and surface indication. Do not represent permanent tunnel geometry or collapse damage unless actually implemented and tested.
- Spider needs eight properly posed legs, predictable facing/approach contact, wall attach with valid collider/surface normal, vertical and lateral traversal, roof transition, edge fall, detachment and reattachment. Destruction/unloading underfoot must transition safely; do not create accidental flight.
- Hybrid traversal uses an explicit priority or player selection. When a hybrid can climb and glide, switching modes must be deterministic and recoverable, not a set of overlapping input systems.

### 4.5 Other movement archetypes

- Crab: visible lateral movement / eight support gait, turn and pincer reach.
- Ape: convincing knuckle walk/upright/grapple posture as appropriate; arms and hands align with actual pickup hit traces.
- Reptile: weighty controlled sprint, tail follow-through and mass-driven stomps.
- Biomass: slightly asymmetric animated gait/tendrils and legible regeneration growth.

**Acceptance P1:** Locomotion, camera, collision, attacks, world streaming and equipped anatomy remain coherent at small and giant growth levels. Flight/burrow/climb succeed through normal touch input, not debug teleports or forced test-mode relocation. Tests must include buildings of different heights, destructible foundations, inland/shore borders, app pause/resume and death while a traversal mode is active.

## 5. Priority P1 — hybrid identity and slot resolution

Start with three existing acceptance combinations:

1. **Reptile + Bird:** reptilian torso with physically anchored wings/feathers, no duplicated shoulder appendage; can glide/flight **only when** the necessary genes/mass rules permit.
2. **Ape + Crab:** articulated ape torso / arms, **actual pincer hands** replacing fists with carapace integration; grab/crush rules align to real pincer ends.
3. **Worm + Mole:** long body with a reinforced digging anterior section and integrated fore-spades; underground body follows rather than instantly disappearing or standing up.

Then cover the additional curated hybrid routes **Bird + Spider**, **Snake + Biomass**, **Ape + Spider**, **Reptile + Crab**, **Worm + Biomass**. Validate all **36 unordered pairs** through at least a legal/illegal recipe test, even if not all have bespoke final art. A supported pair gets readable primary/secondary identity and no duplicate organs; an unsupported pair is explicitly blocked or honestly labelled prototype, never silently rendered as a shapeless heap.

- Anatomy occupancy is authoritative, not only percentage affinity. A hybrid must express at least one real visible/functional part from each of two families; an affinity percentage alone is not completion.
- Hybrid cohesion/compatibility affects viable support structures, not random invisible movement disablement. Respect legal genes and provide explanations before the choice.
- If a primary family changes during a lifetime, migrate compatible organs without popping to a generic reptile rig, losing mutation ranks or discarding the body history.
- Preserve body-plan-specific size growth: a worm hybrid remains long unless an explicit validated metamorphosis completely changes locomotion.

**Acceptance:** Deterministic snapshots for 8 curated pairings × key growth ranks, explicit socket conflict tests, save/load and damage traces. Where the art cannot deliver a convincing true hybrid, improve the attachment system or honestly restrict the pairing; do not imply all 36 are fully polished.

## 6. Priority P1 — touch UI, mutation feedback and accessibility

- **Mutations:** Three-choice draft UI must visibly explain what changes on the current animal, with small anatomy thumbnail/diagram, rank, affinity arrows, visual preview (or deterministic before/after), active ability and any part replacement, cost/limitations. Every card's claimed gameplay effect must be sourced from live gene data.
- **On-body changes:** Evolution reveal should show the changed organ or silhouette instead of generic camera shake only. Allow a short comparison/inspect panel; preserve fast skipping for repeat runs.
- **Movement mode:** TRAVERSE should show the name of the currently available mode and a clear valid/blocked reason; supported hybrid movement switch via LINEAGE. UP/DOWN should only appear in relevant modes and must never remain stuck pressed after UI closes or Android background/resume.
- **Camera:** Keep moving head/flight target, tail length and vertical world in frame without extreme zoom or losing civilians/buildings. Dynamic framing should scale for portrait and still permit precise touch movement.
- **Performance/readability:** Safe areas/notches, small/large Android phone aspect ratios, 20:9 portrait and tablet portrait checks, touch target sizes, colour-independent button states, legible labels at playable zoom.
- **QA selector:** Keep a clearly debug-only route to pick all nine forms, hybrid pairs and growth rank 0/6/12/18, plus equip each legally playable gene and select movement. It must not contaminate persistent discovery progress or be available in an eventual production release.

## 7. Priority P2 — production-oriented visuals, audio/FX and performance

- Maintain the soft sunny Australian coastal colour/shape grammar and clear creature silhouettes. Creature construction should look intentional rather than a collection of spheres and rods. Preserve existing GLBs/blend masters and source licences/attribution; original assets preferred.
- Add economical visual feedback where it improves readability: wing flap, takeoff landing dust, snake slither ground marks, worm earth wave, mole excavation, spider wall contact, hybrid activation and controlled mutation growth. Avoid dense particle spam and colour that overwhelms the UI.
- Reuse meshes/materials; batch static geometry and atlases or vertex colours appropriately; animate only dynamic parts; avoid reallocating full anatomy every frame. Enforce bounded trail samples, active colliders and transform updates. Prevent unlimited caches or leaking old `Area3D`/Mesh nodes after repeated evolutions/deaths.
- **Performance evidence:** Establish a baseline on the existing Android preview first, then compare test build on the same hardware using a scripted 15-minute route: dense city, giant axial creature, aerial scene, subterranean movement, climbing, DEFCON fights, five shed remains and hybrid swaps. Capture median/p95/p99 frame times, process RSS, draw calls, peak active collision count, allocation spikes and battery/thermal notes where supported. Target a stable 30 fps on a representative mid-range Android phone without severe stutters; report measured deviations. CI/desktop evidence must not be represented as phone FPS.
- Gameplay feedback should be concise and tactile: state change cues, enemy response visibility, model-material transition. Do not divert into music/licensing or unrequested monetisation work.

## 8. Mandatory automation and CI

### 8.1 Preserve and extend automated suites

Before changes, run `python3 scripts/ci/run_regressions.py --godot <Godot-4.5 executable>` (use existing local/CI setup). No previously passing suites may be deleted or bypassed to make green CI. After each slice, run targeted suites and final discovery; resolve parse errors and regression failures instead of classifying them as tool noise.

Add test coverage for:

- Nine families × physical growth ranks 0, 6, 12, 18 (36 configurations), with stable bounds and no automatic axial upright switch.
- Nine generic upgrades × nine hosts × three visual ranks (**243 legal expression cases**, or explicit exclusions), verifying organ owner/sockets, tiers, no duplicate nodes and a changed visible recipe.
- Every one of the 41 executable source IDs: legal selection path, gameplay hook, model representation, save/reload and player-facing card truth. Additional traversal gene prerequisites remain enforced.
- Eight curated hybrid routes plus 36-pair resolver legality (including conflicting forelimbs and support-matrix requirements).
- Snake/Worm: 90-degree turn, S-turn, U-turn, long slow path, fast motion/delta spike, blocked wall, giant body and save/reload path continuity; no tail jump or runaway collider count.
- Bird: takeoff, powered ascent/descent, glide, roofs, airport/AA-style response where current content supports it, roof landing/falling, damage, stamina or ability limitations.
- Worm/Mole: legal soil entry, foundation and border refusal, progressive submerge/emerge, underground path ownership, save/restart, world response.
- Spider: wall approach, attach, sideways/up/down movement, roof support and destroyed-wall safe fall, detach and reload.
- Android input state machine: UI blocking, multitouch, pause/background/resume, held UP/DOWN reset, death/rebirth while traversing.
- Persistent world: destroyed structures/missions/lineage preserved across death and organism change; old save versions still load.
- Bounded performance invariants: no per-frame mesh rebuild, bounded colliders, stable memory across repeated draft selections and transformations, no hidden active legacy mutation geometry.

### 8.2 Visual proof required

Capture actual Godot engine frames (not concept art) from a deterministic camera/setup, including:

- Nine base forms at sizes 0, 6, 12, 18 (minimum 36 images).
- Each generic upgrade I→II→III on representative anatomies, with comparison frames for at least Snake, Bird, Crab, Spider, Ape and Worm.
- Every curated hybrid at start/intermediate/mature stage (minimum eight × three), where implemented.
- Action proof: long Snake curving around street corners, Worm burrowing/emerging, Bird airborne beside a multi-level building, Spider on a wall and roof, Mole digging, and each relevant hybrid in motion.
- Portrait UI mutation cards and movement controls at 20:9 Android resolution, with legible body and environment in one screen.

Where exact screenshot automation isn't available, add a deterministic in-engine capture scene/script and store an index page/contact sheet under `docs/evolution/polish_evidence/` or an attached CI artifact; avoid committing hundreds of huge raw PNGs unnecessarily. Compare against a capture from APK #253 at the same poses.

### 8.3 APK shipping gate

Only after green CI and inspected visual proof:

1. Configure a separate Android debug package and name for the polish preview. Preserve original Android package, app signatures and save directories.
2. Run Godot 4.5 import, launch, full automated regression, Android ARM64 export, ZIP/manifest, `apksigner` v2/v3, `zipalign`, native 16 KiB alignment and release asset/hash checks through existing workflow.
3. Publish a new immutable GitHub prerelease containing the actual installable `.apk` and `.sha256`; link its source SHA and Actions run. Do not claim release was published until GitHub confirms assets.
4. Create or update a **draft** polish PR against `feature/morphology-traversal-autonomous`, not against `main` or `integration/stable-baseline`. Reference PR #19/#20 dependencies and keep original releases intact.
5. Finish with one explicit Android test checklist that the user can execute after installation.

## 9. Definition of done / stop criteria

The work is considered ready for **owner phone testing** only when:

1. All nine forms are visually recognisable; mutation modules grow from correct body parts at ranked I/II/III states, without universal reptile decorations.
2. Snake and Worm stay horizontal, become substantially longer, follow real steering paths with continuous body silhouette and credible body contact, and survive save/load without teleporting their tail.
3. Bird can actually glide/fly/land; Mole/Worm can safely traverse underground; Spider can climb actual supported geometry and access roofs, using real touch controls and gameplay constraints.
4. Existing and curated hybrids have coherent legal anatomy, no double limbs or obvious geometry conflicts, and compatible traversal inheritance; impossible combinations are explicitly explained.
5. Persistent world, DEFCON, missions, bite/grab and destruction remain functional, including across death and fresh organisms.
6. Full CI passes with no skipped existing tests, actual engine screenshots demonstrate improvements, and a verified separately installable APK is available.
7. A precise handover identifies what remains a simplified prototype and what is still **unverified on an Android device**, with no inflated success claim.

**Do not stop merely because automated tests are green if the screenshots still show visually poor creatures. Conversely, don't redesign the entire game or rebuild all 500 genes to chase perfection.** Iterate within this scope until the evidence is coherent; where art quality requires human judgement, provide the tested APK and images for the owner's final decision.

## 10. Completion report format

In `docs/evolution/POLISH_HANDOVER.md` and the final Codex message include:

- Branch, PR link, exact source HEAD SHA and verified APK release/link/size/hash.
- Modules changed, meaningful visual/functional upgrades per family and playable-gene coverage.
- All test suites and results, build/artifact evidence, screenshot/contact-sheet locations, performance measurements and their hardware/limitations.
- Ranked residual issues split into **blocker / device validation / future enhancement**.
- Safe Android install/update steps, especially debug signing caveats, isolated package ID and old saves.
- What was intentionally **not implemented** (e.g., mesh-carved underground tunnels, unrestricted 6DoF aerial simulation, 500 executable genes, all 36 bespoke fully sculpted hybrid designs).

---

## Copy-paste execution prompt for Codex

> Work autonomously on **KaijuStomp**, repository `kavemankai/Kaijustomp`. Read `docs/evolution/CODEX_POLISH_HANDOVER.md` from `feature/morphology-traversal-autonomous` and inspect the current live source and PR #20. Create a separate polish branch based on the newest source and execute **all P0, P1 and feasible P2 polish stages** without asking me routine questions. The primary objective is **convincing biology and mutations physically fitted to each of the nine creatures**, followed by distinct snake/worm length-based movement, real flight, real burrow and real wall climbing, integrated hybrids, touch UI and performance. Preserve genetics, all 500 source entries, persistent world/death lineage/DEFCON, 31 baseline regression suites and earlier APK releases. Build deterministic in-engine screenshot evidence, add missing mechanical and save tests, run full Godot 4.5 CI, fix failures, publish a unique separately installable signed Android debug APK and SHA256 under an immutable GitHub prerelease, and open a draft PR. Keep `POLISH_CHANGELOG.md` and `POLISH_HANDOVER.md` current. Do not merge upstream. Report verified work separately from anything awaiting physical-phone testing or final art approval. Continue implementation until a tested APK is available; do not stop at another plan or a list of suggestions.