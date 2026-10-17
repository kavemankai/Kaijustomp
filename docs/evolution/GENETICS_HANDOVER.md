# Genetics ground-controller preview

Implemented on `feature/nine-form-genetics-preview`, based on `feature/persistent-streamed-world` at `35dc25b95d05322459e70e39ea046dc6a3f9085d`. PR #18 remains draft and unmerged. The current-repository handoff overrides the old auto-shooter assumptions in the supplied [specification](source/IMPLEMENTATION_SPEC.md), [GDD](NINE_FORM_DESIGN.md) and [integration plan](source/INTEGRATION_PLAN.md).

Android publication status: awaiting this branch's verified CI export. No Genetics Preview download is claimed until signature/package/ZIP/ARM64 checks and publication complete. Default local export now uses **com.kavemankai.kaijustomp.geneticpreview**, **Kaijustomp Genetics Preview**; existing named branch mappings are preserved.

## Implemented runtime

- Immutable source catalogue: all 500 original IDs, keys, names and descriptions retained byte-for-byte. SHA-256 `4d3b6b9e2ec7bf91995513dde10e4f54ac16da7f6a9514b8c212fcfb3afe79d5`.
- **35 source prototypes**, the exact curated 30 plus #11/#62/#44/#84/#15. Nine generic upgrades and a separate optional growth choice remain. Other 465 source concepts are searchable but locked. [Coverage CSV](GENE_COVERAGE.csv) gives every ID and its actual bounded runtime effect.
- Nine zero-initialized raw affinity tracks; display-only percentages; anatomy-derived unformed/emerging/consolidated/candidate/hybrid identities. No birth class. Real feeding/breach events can award at most two behaviour points per family per evolution interval; event IDs prevent replay. Idle time and mutation UI do not award behaviour points.
- Seeded weighted strengthen/explore/adapt drafts with unique legal backfill, bounded affinity/terrain weights and a player-selected draft direction. Matrix adds cross-family exploration. Actual offers and seed are checkpointed; a loaded pending choice resumes with the same cards. Selection is guarded and transactional; pause/vulnerability/shedding/reveal remain.
- Small procedural low-poly ground bodies and bounded accessory recipes. Merged core meshes cache at most 24 recipes; movement animates existing support nodes. No per-frame mesh construction. Authored 19-bone creatures remain the neutral/legacy fallback. Existing collision, streaming, destruction, feeding, objectives and response systems remain owners of their domains.
- Independent growth: new genetics lives use a chosen x1.20 size gene (18-rank cap; +5% sprint drain/rank), independent of identity and evolution count. No forced E22 biped. Old saves retain original automatic milestone numbers and posture, with explicit opt-in genetics retaining that legacy policy. New generic mutation ranks are capped; old upgrade records/statistics remain intact.
- Active genome/effect timers live under versioned `player.genetics`; persistent knowledge under `events.lineage_archive`; world deltas remain in existing objects/events. The existing single save writer owns all writes. Malformed feature data recovers from backup; future feature versions are protected.
- Final death archives the life once. **NEW ORGANISM** writes a neutral next organism into the same world document before scene reload; retains seed, destruction/reward tombstones, vehicle states, pending evacuations, objectives, pins and Renown. Personal alert/contacts/stat build clear. Up to 128 detailed life records are retained; discoveries/mastery/hybrid knowledge remain. Strategic peak response knowledge persists without identifying the newborn.
- **NEW WORLD / FULL RESET** is separate, confirmed, and makes a timestamped recovery copy before clearing the world/archive. Legacy RESTART retains its full-reset meaning through that confirmation. No installation or approved release was replaced.

## Nine family proofs

All rows have a live gene hook, procedural geometry, round-trip and movement/effect tests. These are ground-controller prototypes, not final animation/art acceptance.

| Family / source | Visible anatomy | Working interaction |
|---|---|---|
| Reptile #6 | Teal tail, orange dorsal osteoderms | Capped multiplicative damage mitigation |
| Biomass #100 | Patchwork flesh sacs/tendrils | Explicit heavy-arm support bridge and cross-family draft route |
| Snake #11 | Raised serpentine head, fangs, segmented slither tail | Contact venom ticks on living responders; vehicles excluded |
| Bird #22 | Light frame, two supports, feathered winglets | Faster grounded travel with incoming-damage cost |
| Crab #61 | Broad shell, side legs, pincers | Damage reduction with movement cost |
| Spider #62 | Low eight-legged frame and multiple ocelli | Visible nearest-prey marker and wider capture cone |
| Ape #44 | Broad chest, long grasp arms | Larger actual feeding reach and capture cone |
| Worm #84 | Low ringed trunk, ventral sole/radial mouth | Cheaper sprint on coastal sand; inland speed cost |
| Mole #15 | Compact snout, large spade foreclaws | Cooldown-limited surface breach damage; no underground teleport |

## Hybrids and support

| Fixture | Expression and mechanics | Restriction |
|---|---|---|
| Reptile + Bird | Dorsal plates/tail plus feathered winglets; mitigation plus speed/vulnerability | Grounded aerodynamic proof; no leap/glide claim |
| Ape + Crab | Broad torso/long support arms with **pincer hands replacing fists**, shell; reach plus armour/mobility cost | One resolved forelimb recipe, no overlapping full fist/pincer replacements |
| Worm + Mole | Ringed crawler/ventral foot plus digging spades; coastal stamina plus surface breach | Surface only |

The additional Worm/Ape crossover is illegal without #100's visible support matrix. Tests cover rejection, bridge selection, expressed hybrid and legal ground collision. Candidate percentages alone never count as an expressed hybrid. Full hybrid mastery/synergy tiers and tri-form classification remain deferred.

## Evidence

Baseline source above passes Godot `4.5.stable.official.876b29033` import, 60-frame launch and all **25 original suites**. The implementation adds five discovered suites: core, curated, gameplay, lives and physics. The latest complete local run passes **30/30**, import and launch; final CI re-verifies the committed source on Linux. [Windows results](../validation/genetics/windows-regressions.json) and [baseline](../validation/genetics-baseline/windows-regressions.json).

- Core: exact source IDs, nine neutral tracks, seeded legal drafts, nine pure paths, candidate versus expression, three hybrids, support legality, idempotent selection, behaviour caps/replay and genome validation.
- Curated: every source prototype equips, round-trips and creates geometry; concrete effects, categories, cooldowns, tradeoffs and caps.
- Gameplay: live damage, venom, sensors, feeding reach, surface breach, pause/reveal, unsupported/duplicate choice rejection, searchable index and no mutation-driven SWAT.
- Lives: frozen draft checkpoint, death/archive idempotence, neutral new life, retained world/objective/vehicle/evacuation/seed, old-save migration, future protection and backup recovery.
- Physics: nine forms/three hybrids swept into a warehouse at 1x and six chosen growths; complete body remains outside wall within 1cm per scale contact tolerance. Radical support crossover, maximum chosen growth clearance without demolition and E120 debug/reload/caps.

[Nine-form capture sheet](../validation/genetics/nine-forms.png), [three hybrids](../validation/genetics/three-hybrids.png), [35 source trait sheet](../validation/genetics/35-source-traits.png), [portrait draft](../validation/genetics/draft.png), [lineage/index](../validation/genetics/lineage.png). These are actual Windows Godot 4.5 Compatibility viewport crops from the same angle/light/scale, inspected visually; no promotional images substituted. Full portrait hybrid captures are alongside the sheets. RTX3050 Laptop/OpenGL3.3 sample captures reported 93–99 draw calls and roughly 52 MiB Godot static allocations; this is neither process RSS nor sustained Android performance.

Reproduce:

```text
python scripts/ci/run_regressions.py --godot <official-4.5-console> --output build/genetics-final
godot --path . --script res://scripts/ci/capture_genetics.gd
python scripts/ci/compose_genetics_captures.py
godot --headless --path . --script res://scripts/ci/generate_gene_coverage.gd
```

The compositor needs Pillow. Capture scripts isolate their save under build; tests explicitly choose isolated paths or remain in memory. The first capture revision wrote an empty E0/frozen-draft desktop fixture into the default desktop save path; its primary/backup were retained for recovery, and this path is now guarded in the checkpoint owner. No Android installation was accessed.

## Known limits and next three priorities

1. Physical Android portrait multitouch/background/resume, installation, sustained frame-time/memory/thermal profiling and natural balance acceptance. No handset is available locally; no device performance claim.
2. Improve nine rigs/stance/feeding animation, tiny trait readability and collision fit. The shared conservative ground envelope is deliberately larger than some small bodies. Flight, wall climbing, narrow-pass snake motion and underground traversal remain locked. Text art direction was available; the original 3x3 concept image was not supplied. This is a proof-art pass.
3. Broader anatomy replacement/support, real damage-category telemetry and hybrid mastery/synergy balance. The 35 concepts have bounded prototype adaptations: #57 is a perception/eyeshine proof because no night system exists; #72 deterministically deflects every fourth small hit rather than random deflection. Generic and prototype balance needs playtesting. The remaining 465 entries are catalogue-only.

Legacy auto-shooter files, original Nova/lab data and approved releases remain untouched. There is no claim of 500 executable genes, full advanced locomotion, final art, a finished campaign or phone-tested performance.
