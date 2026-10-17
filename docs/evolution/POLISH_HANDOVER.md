# KaijuStomp morphology polish handover

## Candidate and provenance

- Dedicated branch: `feature/morphology-traversal-polish`, based on latest fetched
  `feature/morphology-traversal-autonomous` at `1555b33`.
- Draft [PR #21](https://github.com/kavemankai/Kaijustomp/pull/21) targets that
  branch, retaining unmerged PR #20/#19 dependencies. **Do not merge or mark ready
  before owner phone acceptance.**
- **Verified exported source: `9fefce4162ce5508ffdd718a4cd37145e6d7142c`.** Subsequent
  evidence/handover-only commits are not re-exported and do not change gameplay.
- Separate Android package: `com.kavemankai.kaijustomp.morphpolishpreview`, label
  **Kaijustomp Morph Polish**. Existing releases, package IDs and private saves
  remain intact.
- **[Install APK #261](https://github.com/kavemankai/Kaijustomp/releases/download/morph-polish-261-9fefce4/Kaijustomp-261-9fefce4-debug.apk)**, [immutable prerelease](https://github.com/kavemankai/Kaijustomp/releases/tag/morph-polish-261-9fefce4).
  **28,355,494 bytes**, ARM64, version `0.1.261-debug`.
- SHA256: `9fd3085f95e06ec1ed3930b93b4c4f7cf1c4333ba58118f5abff7d544b0eea9d`.
  [Matching checksum asset](https://github.com/kavemankai/Kaijustomp/releases/download/morph-polish-261-9fefce4/Kaijustomp-261-9fefce4-debug.apk.sha256).
- [Successful export/signature/publication run #261](https://github.com/kavemankai/Kaijustomp/actions/runs/39074555544)
  and [successful draft-PR build #262](https://github.com/kavemankai/Kaijustomp/actions/runs/39074560057).
  The additional Godot smoke check is green. The source PR remains draft.
- GitHub confirms both assets uploaded; their size/digest match the locally
  downloaded APK/checksum. ZIP integrity and native ELF 16KiB checks also pass
  locally. CI checked signature v2/v3, package, ARM64, zipalign and byte-for-byte
  re-download. [Machine-readable verification](polish_evidence/release-verification.json).
- This run had **no stable debug-signing secret**. Future same-package updates
  can require uninstalling only this preview; preserve its save first if needed.
  The earlier #259 candidate remains untouched; use #261 for the final stance fix.

## Implemented

`AnatomyManifest` supplies typed sockets (transform, bounds, host, support,
operations and fractional axial addressing) and gene/rank/organ records.
`OrganicGeometry` builds connected cross-section lofts and recursively bakes
nested semantic frames, fixing source traits that the former direct-child baker
silently omitted. `CreatureMorphology` separates static cached tissue from
working limbs, wings and tendrils. `MutationExpressionLibrary` expresses nine
capped generic upgrade families through host-local tissue/covering/feeding organs.
Further purchased ranks preserve mature art. Source genes retain their existing
caps: most have one acquisition rank; ranked seeds and generics develop without
inventing illegal source ranks.

| Form | Meaningful visual/functional change |
|---|---|
| Reptile | Connected trunk, wedge muzzle and tapered tail; dorsal scutes and fitted covering/limb upgrades retain the coastal palette. |
| Biomass | Asymmetric tissue body, joined tendril roots and living poses; fitted tissue panels and corrected seated eyes. |
| Snake | Connected raised anterior, fangs/ventral banding and one continuous tapering path skin; head girth scales independently of length. |
| Bird | Avian trunk/neck/beak/crest, taloned legs and shoulder/wrist feather fans; folded/extended/flapping poses, banking, shadow separation and sized wing collision envelope. |
| Crab | Flat carapace, eight supports plus two articulated chelipeds; substantial pincers, lateral-facing travel and shell/joint expressions. |
| Spider | Separate abdomen and anterior, eight jointed supports, ocelli/fangs; wall hooks on moving feet, wall-facing pose and camera outside the facade. |
| Ape | Broad shoulder/chest, face and knuckle supports; pincer hands replace fists in Crab hybrids and Spider hybrids retain the working front arms. |
| Worm | Connected heavy anterior, radial tooth maw and ringed continuous body; length/girth growth and following subterranean body history. |
| Mole | Compact shoulder-heavy excavator, wedge snout and fore-spades; digging motion and gradual soil entry/emergence with a surface trace. |

`AxialTrail` uses one fixed-topology 97-ring mesh with shader deformation and a
bounded 220-point distance-spaced history. Sampling is linear in history + rings,
not rings times history. Very slow movement no longer collapses the tail. Up to
40 query proxies and four obstacle queries per movement tick provide bounded
world contact. Head/neck collision owns movement; an obstructed body stops head
travel and supported building contact can invoke existing demolition. This is
not a rigidbody chain or a self-collision simulation. Snake/Worm migrations keep
compatible path history. Body fractional samples persist through saves/growth.

The axial Tail Club is physically addressed at 92% of body length, follows the
sampled curve, enlarges its corresponding proxy and strikes from that real rear
organ. Additional regression coverage confirms position and actual responder
contact; the non-axial version retains its earlier damage/cooldown behaviour.

`CreatureTraversal` retains one authoritative mode. Flight has finite stamina,
controlled altitude, collision, glide exhaustion, bank/fold/flap pose, landing,
roof contact and falling recovery. Heavy bodies need Soaring; axial bodies over
24 units cannot sustain powered lift. Worm/Mole entry and emergence are gradual;
head path depth propagates along the trailing body rather than hiding it all at
once. Foundation/shore/border checks stay authoritative, underground biting and
surface aiming stop at depth, and real travel creates small seismic alerts
through existing response logistics. Spider attach closes the wall gap, supported
vertical/lateral travel probes real colliders and destroyed support safely falls.

`BeachGenetics` and `BeachDemo` use real anatomical mouth transforms for feeding
and current head collision, girth-based axial neck contact, corrected canonical
body widths and a separate flight-wing envelope. Camera framing accounts for
axial extent and stays outside climb walls. `GeneticsHUD` names movement modes,
shows blocked reasons, clears held altitude input on dialogs/pause, and separates
QA EVO from movement controls. Mutation cards show actual live-geometry forecasts
plus rank, socket, operation and runtime effect. QA selection remains debug-only
and is excluded from lineage discoveries, including after reload.

## Hybrids and coverage boundaries

Eight curated routes have captured acquisition/developing/mature stages:
Reptile/Bird, Ape/Crab, Worm/Mole, Bird/Spider, Snake/Biomass, Ape/Spider,
Reptile/Crab and Worm/Biomass. Wing/hand replacement and dorsal secondary frames
are explicit; a matrix supports heavy grasp organs on axial trunks. One primary
body plan and selective secondary systems remain the visual rule. Additional
family seeds use fitted support tissues instead of a third complete rig.

All 36 unordered pairs have deterministic legal/illegal resolver tests. This is
**not** 36 separately sculpted and artist-approved hybrids. Uncurated combinations
are labelled prototype in the resolver/LINEAGE explanation. Affinity can change
the primary body during a life; QA movement prerequisites may also shift its
final displayed affinity. Source IDs/catalogue and existing effect hooks are
preserved: **41 executable source genes + nine generic upgrades**, not 500
executable mutations. All 500 original concepts remain unchanged and indexed.

## Verification and visual evidence

- Official Godot **4.5.stable.official.876b29033** on Windows.
- Baseline: import, 60-frame launch and **all 31 existing suites passed**.
- Final runtime: import, launch and **all 34 discovered suites passed**, with no
  existing suite deleted/skipped. Reports are in `polish_evidence/` and raw logs
  are retained by Actions.
- `test_polish_anatomy`: 36 physical profiles; **243 actual mesh/colour generic
  tier cases**; all 41 source IDs across hosts, legal prerequisite selection,
  complete geometry signatures including articulated parts, save/card mapping,
  sockets/ownership, all 36 pair decisions and bounded cache/no pose rebuild.
- `test_polish_traversal`: giant slow paths, S/U/90-degree movement, delta spike,
  saved path continuity, bounded tube/proxies, real trailing obstruction, touch
  flight/ascent, exhaustion, heavy lift, gradual digging/emergence, shore refusal
  and destroyed-wall recovery.
- `test_polish_lifecycle`: flight/burrow/climb pause/input reset, active-mode
  checkpoint validity, death/new organism retaining damage, current mouth
  transforms and controls at 540x960, 540x1200 and 768x1024.
- Existing suites continue to cover combat, feeding, source mechanics, lineage,
  saves/migration/backup, destruction, missions, DEFCON/logistics and world
  streaming. Existing morphology tests now assert gradual emergence.
- [Evidence index](polish_evidence/README.md): required **565 actual-engine
  frames**: 108 gameplay + 108 inspection growth/angle frames, 243 generic tiers,
  48 hybrid views, 41 source views, 17 action/UI frames. The completed-run index
  and SHA256 manifest prevent stale PNGs from satisfying a failed capture.
  A rendered pixel-difference gate also checks all 162 I-to-II/II-to-III generic
  transitions, catching organs that change geometry but remain buried in skin.
  Contact sheets are committed; raw PNGs are Actions artifacts. These deterministic
  fixtures prove rendering/state, not natural progression or phone ergonomics.
- Same-hardware original-branch comparison uses an archive of `1555b33` with the
  same capture/profile harness. Inspection framing scales to anatomy; camera
  changes intentionally differ in live gameplay views. No concept art is used.

The release workflow gates APK publication on full regressions and completed
engine captures, then ARM64 export, ZIP integrity, manifest/package identity,
apksigner v2/v3, zipalign and native 16KiB checks.
Linux screenshot capture explicitly uses Dummy audio because the CI runner has
no audio device; engine/script errors still fail the gate. It downloads the published APK
again and compares bytes with the exported asset. Only a successful completed
run plus confirmed release assets establishes the final APK claim.

## Performance evidence and limits

The same short **45-second** rendered route ran on Windows / NVIDIA RTX 3050
Laptop GPU, Godot 4.5 Compatibility, portrait 540x960, default 60-fps cap. Phases
cover a dense district, giant Snake, flight, Worm, Spider ground stress, Mole and
Ape; fixture swaps and invulnerable health/stamina maintenance keep it repeatable.
Spider wall mechanics are tested separately. This probe does not reproduce the
full requested 15-minute phone route, DEFCON fights, five sheds or thermals.

See `desktop-baseline.json` and `desktop-polish.json` for raw p50/p95/p99 frame
intervals, process time, peak static memory/draws/nodes/proxies and sampled
process-tree RSS. RSS includes the console/game process tree, sampled every
200ms; this can miss short spikes and does not measure GPU/battery/thermals.
The matched input-script results (one run each; camera/visibility changes are
included, so this is not an isolated mesh microbenchmark) are:

| Desktop metric | Baseline 1555b33 | Final 9fefce4 |
|---|---:|---:|
| Frame p50 / p95 / p99, ms | 16.664 / 17.258 / 21.336 | 16.665 / 17.088 / 20.085 |
| Process p50 / p95 / p99, ms | 1.985 / 15.303 / 23.648 | 1.743 / 14.544 / 18.638 |
| Peak draw calls | 305 | 155 |
| Peak process-tree RSS, MiB | 259.2 | 262.6 |
| Peak axial proxies | 40 | 40 |

CPU: 13th Gen Intel Core i5-13420H. Peak RSS rises slightly; draw-call reduction
includes different framing/world visibility as well as batching. No Android,
thermal, battery or full 15-minute acceptance result is inferred from this.
Run the full-duration desktop harness with:

```text
python scripts/ci/profile_polish.py --godot <Godot4.5> --seconds 900 --output build/polish-evidence/desktop-15min.json
```

**No physical Android measurement or 30-fps phone claim has been made.**

## Residual issues

**Blocker:** no known automated build/installability blocker remains. Production
merge and art acceptance still require the owner's physical Android test; do not
merge or mark the draft ready based on CI alone.

**Device validation:** installation/signing compatibility; touch multitouch,
altitude holds and background/resume; all nine silhouettes and mutation fit at
phone zoom; roof/overhang and shore/foundation edge cases; normal progression,
combat and persistent-world multi-life feel; 15-minute frame-time/RSS, allocation
spikes, thermal/battery and five-remnant stress route on a representative phone.
The QA screenshot matrix cannot substitute for that acceptance.

**Future enhancement:** final authored skin/rig seams, continuous wing/leg
interpolation and hand artistry; arbitrary non-convex climbing/overhangs; fully
sculpted uncurated hybrids and multi-family structural recipes; self-colliding
axial locomotion and more forgiving recovery from newly spawned indestructible
body obstructions. Current tail contact is bounded proxy contact, not full
rigid-body/terrain deformation. Roof departure currently uses walk-off/fall before a new ground launch;
unsupported saved wall/roof transition states recover to legal ground. Axial
shed snapshots remain anterior-based rather than baking the full moving trail.
No permanent carved tunnels/collapse simulation,
unrestricted 6DoF aircraft simulation, 500 executable genes or 36 bespoke hybrid
sculpts were implemented. Existing source art/GLBs remain preserved.

## Android install and owner test checklist

1. Download the APK and matching SHA256 from the immutable release linked above. Allow
   installation from the browser/files app when Android prompts. Verify the
   checksum before installing. Keep earlier Kaijustomp apps installed.
2. Launch **Kaijustomp Morph Polish**, package
   `com.kavemankai.kaijustomp.morphpolishpreview`. It has its own private world.
   Debug certificates can differ when no stable signing secret is configured;
   a future update may require uninstalling **only this preview**, which erases
   its private save. Back it up first if needed; never uninstall the older apps.
3. LINEAGE -> QA PREVIEW: inspect all nine hosts at growth 0/6/12/18, add generic
   organs and compare tiers through normal selections. Test the eight curated
   hybrids. QA creatures do not earn lineage discoveries.
4. Steer a giant Snake slowly, sprint around corners and double back. Check the
   continuous body, obstacle contact, framing and saved path after restart.
5. Bird: acquire wings, take off, hold UP/DOWN, turn near buildings, exhaust lift,
   glide, land on ground/roofs and walk off edges. Heavy lift requires Soaring.
6. Worm/Mole: dig on open inland soil, move under the surface, inspect progressive
   submerge/emerge and surface trace; refuse shore/foundations. Reopen/restart.
7. Spider: face a building, CLIMB, move UP/DOWN/sideways, reach the roof, walk off,
   detach/re-attach and destroy/unload its support. Check that the camera shows
   the creature against the wall.
8. Hold movement plus altitude/sprint, open/close LINEAGE and background/resume
   Android. No control may remain pressed. Check portrait notch/safe areas.
9. In a normal non-QA life, damage structures/vehicles, advance missions, die in
   flight/dig/climb, create NEW ORGANISM, and restart. Confirm destruction,
   missions and lineage persist while the new organism is neutral.
10. Play at least 15 minutes through dense city, giant axial, aerial, subterranean,
    climbing, DEFCON fights, five sheds and hybrid swaps. Record phone/OS,
    median/p95/p99 frame times, RSS/draws/colliders, stutters, heat/battery and any
    reproduction steps. Final art and natural control feel need owner approval.
