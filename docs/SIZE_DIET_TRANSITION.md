# Size-driven diet transition (candidate)

Branch `feature/scale-driven-diet-transition`, stacked on `feature/debug-batch-evolution` (draft, unmerged). The user approved batch debug but the E55–E120 video showed the creature completely outgrowing the tiny residential world and wondered where to stop animating upright arms grabbing individual people. **Gameplay rule: make that change at the actual body-to-person visual scale where it stops reading naturally, not at an arbitrary evolution number.**

## Current first-pass cutoff

`scripts/beach/DietProgression.gd` holds the explicit calibration value `HUMAN_GRAB_SCALE_LIMIT = 3.35`. It is measured in **multiples of initial creature size**. With the approved sparse physical growth curve this happens **after E28 (3.11×) and by E34 (3.74×)**, but if evolution milestones or growth multipliers change, the feeding change will track physical size automatically. This is an initial judgement for phone testing, not a claim of validated animation quality.

**Behaviour:**
- Small form and early upright form: auto-capture people/police, play approved quadruped bite or upright paired-arm grab and tongue pull, gain existing 12/16 biomass.
- From physical scale 2.45×: vehicles also give **75 biomass on destruction**, without making the creature play a tiny-person chewing animation. Drivers still flee.
- Beyond physical scale 3.35×: people stop being captured/removed by auto-eating. They continue fleeing and sheltering, as part of the atmosphere and emergency response. The giant's tongue/arm grab is not triggered for tiny targets.
- At that same size, destroying intact buildings now grants biomass **once on full collapse**, proportional to footprint, with a higher yield for hotels, apartments, supermarkets and the hardware store. Chip hits and already destroyed structures do not pay. Smash/crack/occupant-release/police-alert systems remain. Cars keep yielding biomass too.
- The HUD reflects source changes: people → people + cars → buildings + cars.

**Not yet a finished giant economy:** the existing map contains finite buildings and 16 cars; at extreme debug sizes (e.g. E120), these are no longer sufficient for repeat evolution. The next major zone will need bigger/renewable targets, a world that matches giant scale, and reviewed heavy-footfall locomotion. The current creature walk/foot stretch and E120 camera/world disproportion are separate unresolved animation/environment tasks.

## Acceptance

Use the separate Android candidate: E22 to confirm vehicle and person feeding, E28 to inspect arm reach, E34 to confirm people aren't eaten and demolition grants biomass. Evaluate whether arms look too awkward before or after E28. Update `HUMAN_GRAB_SCALE_LIMIT` from real phone evidence, then design large food/industrial district after agreeing on target size. Eleven prior tests plus `test_scale_diet.gd` guard old mechanics and the new food transition.
