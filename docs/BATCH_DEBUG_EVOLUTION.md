# Debug batch evolution preview

Branch: `feature/debug-batch-evolution`, stacked on the tested E34 demolition + upright feeding branch. Draft/unmerged and separately installable; the approved Shopping, Suburb, Long Beach and Giant preview builds are not replaced.

## Player request

Replace the repeated one-level DEBUG EVO flow with **a selector for how many evolution levels to add and apply them all at once**. This is a testing workflow, not a live gameplay shortcut.

## Debug Android interface

- Tap the existing **DEBUG EVO** right-hand button (or F6 on desktop) to open a compact portrait selector.
- Choose a numeric number of levels to add (default 5, valid **1–60 per action**), or tap presets **1 / 5 / 10 / 20 / 34 / 50**.
- The selector previews `E[current] → E[result]` and projected physical size. Tap **EVOLVE ALL** to apply the whole batch immediately, or **CANCEL** with no changes.
- Example: fresh E0, select 34, confirm → **E34**, upright form and 3.74× starting size immediately. Subsequent +6 → E40 with the correct next growth stage. The selector adds levels, it does not set an absolute target.
- A testing safety limit of E120 avoids accidental huge collision meshes from indefinite growth; per-click maximum 60 is dynamically adjusted near the ceiling.

## Technical contract

One evolution is recorded for every level added, with ordered history entries including milestone/form flags. An automatic deterministic rotation across the nine existing mutation families grants one real stat mutation per debug level, and preserves the existing cosmetic geometry cap of three ranks per family. Unlike normal evolution, debug batching deliberately generates **no dozens of individual shed skins**, waits, vulnerability windows, mutation menus or skin-reveal pauses; it applies the final body scale, collision rig, form, health/stamina and follow camera immediately. Past shed remnants are left as-is. Normal hunting, biomass costs, one-at-a-time mutation choice, cocoon and metamorphosis flow remain entirely unchanged and continue working after a debug batch.

UI and batch execution are guarded by `OS.has_feature("debug")`; release/non-debug builds get neither the selector nor a cheat command. Prevent execution during active transformation, game-over, mutation modal or reveal. The old one-level debug shortcut test was updated and a separate eleventh suite `test_batch_debug_evolution.gd` checks preset selection/cancel, E0→E34 and E34→E40, growth math and collision, stats/visual history, invalid inputs, guarded flow and normal evolution compatibility.

## Phone acceptance

Open preview → DEBUG EVO → choose 34 → EVOLVE ALL. Expect E34 and upright view instantly, no people eaten, one dialog only. Test +6 for E40 and +10/20 increments thereafter, including camera framing, size/physics and absence of lag during an E50 batch. Check small-phone dialog height, preset tap sizes, numeric entry and confirm/cancel. These aspects remain unverified by headless CI.
