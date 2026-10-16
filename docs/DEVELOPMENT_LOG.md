# Development log

## 2026-10-16 — creature/evolution takeover candidate

Source: PR #6 `457d228`, including draft stylised PR #5. Approved baseline retained at `0f82ff9` (Godot 4.5 Android run 56 / mobile-preview-godot45). PR #4 remains rejected. Repository branches, all PRs, workflows, releases, source/tests and development history inspected through Git and GitHub API. Both current drafts had green CI before this work; no drafts merged.

### Implemented

- Scale automatic feeding reach with body size; support horizontal reach of raised jaws without changing hatchling cone/rewards/slowdown.
- Counter-rotate the neck after torso posture; sample the upright snout collider after head rotations. Preserve neck posture during later evolution vulnerability/selection/reveal.
- Add knee/ankle pivots without moving quadruped rest meshes. Level-22 shoulders articulate independently; hind knees and ankles support a level-paw stance. Strength claws stay attached to the articulated paw.
- Set new form before the paused reveal; ease only the camera while the game remains paused.
- Test new body/head shapes after a growth milestone and relocate out of new wall overlaps using a bounded local clearance search. Preserve swept movement/building damage logic.
- Preserve camera view direction through shared vertical framing, extend far plane with size, retaining FOV/control mapping.
- Reuse immutable palette materials instead of allocating one material per coloured part. Shed materials remain private overrides. Draw-call reduction and phone performance are not claimed.
- Add behavioural growth integration regression, run the full suite in beach CI and gate APK export on it. Publish immutable candidate tags with SHA256, exact commit/run and a separate installable preview package. Stable release paths are untouched.
- Document current game in README, add current handover and progression contract; preserve original game/history.

### Validation before candidate publication

Official Godot `4.5.stable.official.876b29033` on Windows. Approved baseline imports, launches for 60 physics frames and passes its evolution and combat tests. Unmodified PR #6 imports/launches and passes its four original tests. New integration regression fails on unmodified PR #6: larger quadruped cannot feed at scaled snout.

Candidate imports and passes five tests: evolution, combat, stylised composition, growth milestones and growth gameplay. Actual OpenGL Compatibility renders inspected at levels 0, 6, 16, 22 and 46 at 540×960. Before fix, L22 snout forward had y≈0.86 (skyward) and L46 distance≈269 exceeded far=230. After fix, L22 forward is nearly horizontal and L46 fits an expanded far plane. Desktop screenshot checks are not phone visual approval.

Android build/signature/package/alignment and exact source/run will be recorded after GitHub Actions completes. Local editor reports Android SDK build-tools unavailable; Android export uses the repository's matched Godot 4.5/SDK35 GitHub runner instead of the locally installed Godot 4.6. No connected phone has been tested.

### Measured shed-rendering follow-up

The first published candidate (Android build 83, source `e0a07ae`) passed both push and PR workflows, including signature/package/native alignment. A subsequent desktop stress probe found ~163 scene draw calls without skins versus 708 with five skins. Finished remnants now bake the complete old geometry into one pale surface while cracks/fragments remain separate. On the same RTX 3050 Compatibility setup the resulting five-skin scene used ~286 draw calls (roughly 60% fewer than 708) and static engine memory ~43.96 MiB versus ~48.35 MiB before baking. These small desktop probes are not Android FPS, GPU memory or sustained frame-time measurements; procedural world randomness can change base counts slightly. Construction still has a one-off cost and must be profiled on device.

`test_evolution.gd` now checks that the baked mesh retains the old form's complete vertex count, live palette colours remain unchanged, and the static remnant fades and expires. Reproduce draw-call/memory inspection using `godot --path . --script res://scripts/ci/profile_shed_rendering.gd` with a real renderer; headless results are not useful for this probe. A new candidate rebuild follows this measured optimisation.

### Next actions

1. Complete candidate Actions run; inspect every required check and download/verify the published APK against its checksum.
2. Phone install and natural L0–6 playtest beside the preserved approved app; judge responsiveness, visible mutations and one growth event.
3. Judge L22 silhouette/stance/feeding from the actual portrait camera. Refine production gait only with feedback; no automatic draft merge.
4. Profile Android frame pacing, memory and five-shed stress before claiming performance parity. Extreme size and finite beach boundaries remain a known limit.
