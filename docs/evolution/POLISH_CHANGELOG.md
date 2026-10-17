# Autonomous polish development log

2026-10-18: Fetched latest source `1555b33`; clean dedicated branch
`feature/morphology-traversal-polish`. Read CODEX_POLISH_HANDOVER and source
handover/design/specification/integration/art direction. PR20 remains draft.
Preserve source catalogue, releases, world/save schema and existing tests.

Initial audit: legacy source traits are child Node3D frames excluded by the
direct-child mesh baker, so recipe-string checks did not prove visibility.
Static bird feathers overlap animated wing rods; ape arms overlap generic
supports. Slow axial movement exhausts the 220 per-frame history points,
shortening the body. Burrow entry/exit snaps and air travel lacks resource cost.
These are priority repairs. Original baseline and final captures use the same
in-engine capture harness; raw PNGs remain build artifacts.

Slice 1 — anatomy and movement contract:
- Godot 4.5 baseline: import/launch and all 31 discovered suites passed locally.
- Added typed semantic sockets and per-expression ownership/operation/tier;
  recursive baking repairs the previously omitted nested source traits.
- Connected lofted bodies, anatomical eyes, articulated shoulder/wrist feather
  fans, exclusive pincer/spade hands, separate crab chelipeds, tissue tendrils.
- 243 generic host/tier geometry checks and 41 source genes across hosts;
  legal/save/card mapping, 36 pairs and cache/no-frame-rebuild checks pass.
- One fixed-topology GPU-deformed axial tube; linear-time ring sampling;
  distance-spaced bounded history, tapered skin, ventral bands and worm rings.
  Body obstacles are queried in batches of four, proxies capped at 40.
- Gradual excavation/emergence; underground attacks/aiming suppressed at depth;
  movement creates bounded seismic alert through existing dispatch logic.
- Powered lift consumes stamina, heavy bodies need soaring, exhaustion glides,
  roof impacts/falls recover; wing animation follows time, not travel alone.
- Touch mode labels and errors, input clearing on dialogs, geometry forecast
  thumbnails, anatomy/rank card text, QA discovery isolation and one extra gene.
- Extended traversal tests pass: giant slow paths, S/U turns, spikes, body-wall
  contacts, save continuity, ordinary touch movement, lift exhaustion, excavation
  boundaries/emergence and destroyed-wall falling.
- Visual iteration caught detached Biomass eyes and undersized axial heads;
  repaired canonical coordinates/girth scaling. Regenerating evidence after fixes.

Limitations retained for disclosure: procedural art, no carved tunnels or
rigid-body tail/self-collision, no 36 bespoke hybrid sculpts, no physical phone.
Uncurated pairs remain explicitly described as selective-organ prototypes.

Slice 2 — visual/physics verification and shipping gate:
- Added actual geometry thumbnails to mutation cards and truthful rank/socket,
  lift-load and host-growth descriptions. QA EVO moved clear of traversal.
- Corrected canonical radial/ape/mole widths, axial head girth, missing crab
  chelipeds and buried ape eyes. Mouth collision/feeding now use the live host
  mouth, with an axial neck sweep and a separate active flight-wing envelope.
- Wall approach closes the contact gap; the model poses against the surface
  while collision remains outside it. Climb/fall cameras stay outside the wall.
- Wall hooks now grow on moving tarsi. Additional family seeds retain support
  tissue expressions; the matrix no longer hides the grasp arms it enables.
- Added pause/checkpoint/death/rebirth tests in flight, burrow and climb, with
  retained destruction and neutral new genomes. Control rectangles checked at
  540x960, 540x1200 and 768x1024. All three added polish suites pass targeted.
- Capture harness requires a completed-run index, so stale PNGs cannot satisfy
  the shipping matrix. 565 actual engine frames cover base/growth/angles,
  243 upgrades, 24 hybrid stages in two views, 41 sources, actions and 20:9 UI.
- Desktop comparison uses the same 45-second scripted route on Windows/RTX3050,
  with frame percentiles and sampled process-tree RSS. This is a short desktop
  probe, not the requested physical-phone 15-minute stress acceptance.
- CI config isolates com.kavemankai.kaijustomp.morphpolishpreview, gates export
  on full regressions and completed visual evidence, then verifies signing,
  ZIP/package/ARM64/16KiB alignment and downloads its immutable release asset
  again for a byte-for-byte comparison. No prior package/release is replaced.
