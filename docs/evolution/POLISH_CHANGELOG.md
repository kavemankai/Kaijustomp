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

Slice 3 — rendered visibility gate and final evidence:
- Pixel comparisons exposed buried Biomass/Crab health/stamina/regen panels and
  weak Worm muscle tiers despite valid geometry. Fitted their roots to actual
  skin, strengthened Worm myomeres and gave metamorphosis a developed dorsal
  seam. All 162 tier transitions now visibly differ (minimum 63 changed pixels
  locally at the >8 luminance threshold); shipping requires at least 12.
- Camera capture now orbits a consistent axial pose instead of rotating the
  head against a stationary tail. Head inspections focus on the anterior and
  allow room for full hybrid support arrays.
- First Linux capture produced every frame but the strict error gate rejected
  audio-driver initialization on the audio-less runner. Configured Dummy audio
  for screenshot CI; no engine/script-error filter was relaxed. No APK was
  published from that failed run.
- Added complete handover, owner checklist, coverage CSV, before/after and
  565-frame manifest/contact sheets, plus baseline/final regression reports and
  matched short desktop profiling evidence. Final Android job remains pending
  until publication and byte/hash verification are confirmed.

Slice 4 — fractional rear organ contact:
- Moved Snake/Worm Tail Club onto the real 92%-of-length path sample, with a
  matching enlarged local body proxy and contact/damage origin. It no longer
  sits beside the anterior while its statistics hit behind an invisible head.
- Tests verify a rear club more than 20 units from the head, following the saved
  curve and actually damaging/slowing a responder beside that organ. Existing
  non-axial source-19 behaviour and cooldown/damage values stay unchanged.
- Corrected lure/prowl socket semantics to neck/head. All source geometry,
  curated mechanics and extended traversal tests pass after this integration.

Final stance correction:
- Static bounds inspection found avian toes and ape knuckles above their intended
  contact plane. Lowered avian support roots, restored ape knuckle reach, kept
  hind feet distinct from fists and seated matrix-supported axial grasp arms.
- Added explicit planted-support bounds checks for Bird/Ape. This is a small
  visual correction after the successful #259 candidate; a new immutable APK
  will be exported and verified from the corrected source. #259 remains intact.

Verified final candidate:
- Source 9fefce4162ce5508ffdd718a4cd37145e6d7142c; immutable release
  morph-polish-261-9fefce4. APK 28,355,494 bytes, SHA256
  9fd3085f95e06ec1ed3930b93b4c4f7cf1c4333ba58118f5abff7d544b0eea9d.
- Local import/launch + all 34 suites pass. Export run #261, PR run #262 and
  Godot smoke are green; Linux captured 565 frames and passed visible-tier gates.
- Published APK downloaded and checked against checksum, GitHub digest/size,
  ZIP contents and native 16KiB alignment; CI also verifies v2/v3, zipalign and
  the exact isolated package, then compares its published bytes again.
- Repeated the 45-second desktop probe after the stance correction. Stored final
  raw metrics and source provenance. This does not establish phone performance.
- PR #21 remains draft; no upstream merge. Physical Android installation,
  rendering, touch/feel, sustained performance and final art approval remain open.
