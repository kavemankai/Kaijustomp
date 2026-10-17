# Giant contact fixes, upright arm-grab feeding and tongue preview

Branch: `feature/giant-demolition-upright-feeding`, stacked on `feature/expanded-suburb-shops-cars-debug`. Draft preview only. The player supplied an Android screenshot at **E34** showing a large upright creature above suburban rooftops, reported that buildings and cars could not be destroyed, and requested an upright hand-grab animation and a long tongue for improved reach.

## Cause and changes

### Giant building/car demolition
Original destruction required `CharacterBody3D.move_and_collide()` against a low building/car side collider. As growth increased, the creature could be above the target, so no wall collision callback fired. Without Strength mutation choices, size alone gave no stronger attacks.

At growth stage 3+, a new movement-triggered local footprint test checks the closest overlapping building or car horizontally without requiring vertical wall contact. The check selects **at most one** object at a time; it does not run when the player is idle. It uses existing physics contact attack methods so cracked buildings, destroyed colliders, building occupants, debris, fleeing vehicle drivers and police alert still function. `_effective_demolition_strength()` uses the maximum of selected Strength and `growth_stage - 2`; physical size also contributes extra ordinary hit damage. At E34 (stage 6), a sprint impact destroys structurally weaker buildings and shops, and cars can be crushed in the same way. Early-stage combat retains existing chip-damage and gating.

### Upright feeding
Existing E22+ bite had a large head-down movement into the pavement and prey parented directly to the jaw. That is replaced with a **two-arm reach-and-grab**: both front limbs rotate forward, both elbows bend and hands curl on the feeding beat. The upright head remains comparatively stable while the prey is visually pulled through a hand-held position up toward the jaw. The four-legged animation, original bite cone, feeding reward, slow-down and movement remain unchanged. Works with the existing 19-bone imported creature rig; no new creature assets required.

### Tongue range prototype
An upright creature's effective feeding range becomes **1.45× its normal scaled arm/neck reach**, without widening the original forward feeding cone. People within arm reach use only the arm-grab. More distant people cause a reusable stylised coral tongue mesh to extend from the mouth to the target and retract as the target is pulled into the hands/mouth. It is hidden outside that capture animation and the original small quadruped retains exactly the same bite range. This is a baseline upright innate reach improvement, not an extra purchasable mutation at this stage.

## Testing and acceptance

A new tenth Godot 4.5 headless suite `test_giant_demolition_feeding.gd` tests stage-0 preservation, E34 growth and demolition above a shop roof, E34 parked car crushing, two-arm reach and elbow articulation, avoidance of head faceplant, true 45% tongue feeding-range increase, tongue draw/pull/reset and close-by hand-grab fallback. Original `test_stylized_creature.gd` has its obsolete head-faceplant expectation replaced by a grab pose assertion. All earlier nine regressions remain mandatory in both smoke and Android workflows.

The dedicated Android debug candidate has a separate `com.kavemankai.kaijustomp.giantpreview` package and an immutable `giant-feeding-*` pre-release, leaving the accepted Shopping & Cars APK unchanged.

**On-phone review:** use DEBUG EVO to get to E34 without Strength mutations, walk/sprint into a building and parked car, then compare regular upright hand-grab on a close person and tongue lash on a more distant person. Check FPS, roof/collision clearance and whether the rig motion is readable at the 3/4 portrait camera angle. Long-term final sculpted rig/animation polish remains to be approved by the player before merging.
